# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import times
import macros
import terminal
import strutils
import strformat


const
    loglevel_channels {.strdefine.} = "*"
    loglevel {.strdefine.} = "Trace"
    log_indentation_width {.intdefine.} = 2

    MESSAGE_WIDTH = 80

var
    logfile_handle = stdout
    current_indentation = 0


type
    LogLevel {.pure.} = enum
        Exception = 0,
        Critical = 1,
        Error = 2
        Warning = 3
        Notice = 4
        None = 5
        Debug = 6
        Trace = 7

    SourceInfo = tuple[filename: string, line: int, column: int]


proc increaseLogIndentation =
    inc current_indentation, log_indentation_width

proc decreaseLogIndentation =
    current_indentation = max(0, current_indentation - log_indentation_width)


proc getLevelColor(level: LogLevel): ForegroundColor =
    when defined(LOG_NO_COLORS):
        return fgDefault
    else:
        return case level:
            of LogLevel.Trace: fgMagenta
            of LogLevel.Critical: fgMagenta
            of LogLevel.Exception: fgMagenta
            of LogLevel.Error: fgRed
            of LogLevel.Debug: fgCyan
            of LogLevel.Warning: fgYellow
            of LogLevel.Notice: fgGreen
            of LogLevel.None: fgDefault

proc getLevelString(level: LogLevel): string =
    result = case level:
        of LogLevel.Trace: "TRC"
        of LogLevel.Critical: "CRI"
        of LogLevel.Exception: "EXC"
        of LogLevel.Error: "ERR"
        of LogLevel.Debug: "DBG"
        of LogLevel.Warning: "WRN"
        of LogLevel.Notice: "NOT"
        of LogLevel.None: "   "


proc doLogImplNoColors*(level: int, channels: openArray[string], message: string, sourceinfo: SourceInfo) =
    write(
        logfile_handle, 
        now().format("yyyy-MM-dd HH:mm:ss'.'ffffff"),
        " ", getLevelString(level.LogLevel),
        align(channels.join(","), 12), 
        spaces(current_indentation + 1),
        alignLeft(message, MESSAGE_WIDTH - current_indentation), 
        sourceinfo[0], ":", sourceinfo[1], 
        "\n"
    )
    flushFile logfile_handle


proc doLogImpl*(level: int, channels: openArray[string], message: string, sourceinfo: SourceInfo) =
    styledWrite(
        logfile_handle, 
        fgDefault,
        styleDim, now().format("yyyy-MM-dd HH:mm:ss'.'ffffff"),
        resetStyle, getLevelColor(level.LogLevel), " ", getLevelString(level.LogLevel),
        align(channels.join(","), 12), 
        styleBright, spaces(current_indentation + 1), alignLeft(message, MESSAGE_WIDTH - current_indentation), 
        resetStyle, styleDim, fmt"{sourceinfo[0]}::{sourceinfo[1]}",
        "\n"
    )
    flushFile logfile_handle


macro doLog(level: static LogLevel, message: string, channels: static openArray[string], sourceinfo: static SourceInfo): untyped =
    block check_enabled_channels:
        # do not generate code for disabled channels
        let enabled_channels = loglevel_channels.split(",")
        if "*" notin enabled_channels:
            # wildcard enables everything
            for enabled in enabled_channels:
                if enabled notin channels:
                    return

    block:
        # do not generate code for loglevels over the minimum allowed
        let min_level = parseEnum[LogLevel](loglevel)
        if level.ord > min_level.ord:
            return
    
    if defined(LOG_NO_COLORS):
        result = quote do:
            block:
                doLogImplNoColors `level`, `channels`, `message`, `sourceinfo`
    else:
        result = quote do:
            block:
                doLogImpl `level`, `channels`, `message`, `sourceinfo`


template logChannels*(channels: static openArray[string]) =    
    # logChannels ["channel"]
    template exception*(msg: string) = doLog LogLevel.Exception, msg, channels, instantiationInfo()
    template notice   *(msg: string) = doLog LogLevel.Notice,    msg, channels, instantiationInfo()
    template warn     *(msg: string) = doLog LogLevel.Warning,   msg, channels, instantiationinfo()
    template trace    *(msg: string) = doLog LogLevel.Trace,     msg, channels, instantiationInfo()
    template error    *(msg: string) = doLog LogLevel.Error,     msg, channels, instantiationInfo()
    template debug    *(msg: string) = doLog LogLevel.Debug,     msg, channels, instantiationInfo()
    template log      *(msg: string) = doLog LogLevel.None,      msg, channels, instantiationInfo()
    template logEcho  *(msg: string) = echo msg; log msg

    # aliases
    template warning  *(msg: string) = warn msg


template logChannels*(channels: static openArray[string], body: untyped) =
    # logChannels ["channel"]:
    #   (...)
    logChannels channels
    body


template logIndent*(body) =
    # logIndent:
    #   (...)
    increaseLogIndentation()
    try:
        body
    finally:
        decreaseLogIndentation()


template logFile*(filename: string = ":stdout") =
    #[ Specify the log file to be used.]#
    if logfile_handle != stdout and logfile_handle != stderr:
        close(logfile_handle)

    case filename:
    of ":stdout": logfile_handle = stdout
    of ":stderr": logfile_handle = stderr
    else:
        if not open(logfile_handle, filename, fmWrite):
            echo "Cannot open file: " & filename
            quit QuitFailure


# define default log channel if nothing specified
logChannels [""]
