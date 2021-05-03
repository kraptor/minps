# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import sets
import times
import macros
import terminal
import strutils
import strformat


const
    loglevel_channels {.strdefine.} = "*"
    loglevel {.strdefine.} = "Trace"

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
    inc current_indentation, 2

proc decreaseLogIndentation =
    current_indentation = max(0, current_indentation - 2)


proc getLevelColor(level: LogLevel): ForegroundColor =
    when defined(LOG_NO_COLORS):
        return fgDefault
    else:
        return case level:
            of Trace: fgMagenta
            of Critical: fgMagenta
            of LogLevel.Exception: fgMagenta
            of Error: fgRed
            of Debug: fgCyan
            of Warning: fgYellow
            of Notice: fgGreen
            of None: fgDefault

proc getLevelString(level: LogLevel): string =
    result = case level:
        of Trace: "TRC"
        of Critical: "CRI"
        of LogLevel.Exception: "EXC"
        of Error: "ERR"
        of Debug: "DBG"
        of Warning: "WRN"
        of Notice: "NOT"
        of None: "   "


macro doLog(level: static LogLevel, message: string, channels: static openArray[
        string], sourceinfo: static[SourceInfo]): untyped =

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

    let level_color = getLevelColor(level)
    let level_name = get_level_string(level)

    result = quote do:
        block:
            let
                l {.inject.} = LogLevel(`level`)
                m {.inject.} = `message`
                s {.inject.} = `sourceinfo`
                c {.inject.} = align(`channels`.join(","), 12)
                t {.inject.} = now().format("yyyy-MM-dd HH:mm:ss'.'ffffff")
                i {.inject.} = current_indentation
                f {.inject.} = logfile_handle

            if defined(LOG_NO_COLORS):
                write f, t, " ", `level_name`, c, " ", spaces(i), alignLeft(m, 67 - i), s[0], ":", s[1], "\n"
            else:
                styledWrite f, fgDefault, styleDim, t, " ", resetStyle,
                    ForegroundColor(`level_color`), `level_name`,
                    fgDefault, c, " ",
                    ForegroundColor(`level_color`), styleBright, spaces(i), alignLeft(m, 67 - i),
                    fgDefault, styleDim, fmt"{s[0]}:{s[1]}",
                    resetStyle, "\n"
            flushFile f


template logChannels*(channels: static openArray[string]) =
    # logChannels ["channel"]
    template exception*(msg: string) = doLog LogLevel.Exception, msg, channels, instantiationInfo()
    template notice*(msg: string) = doLog LogLevel.Notice, msg, channels, instantiationInfo()
    template warn*(msg: string) = doLog LogLevel.Warning, msg, channels, instantiationinfo()
    template trace*(msg: string) = doLog LogLevel.Trace, msg, channels, instantiationInfo()
    template error*(msg: string) = doLog LogLevel.Error, msg, channels, instantiationInfo()
    template debug*(msg: string) = doLog LogLevel.Debug, msg, channels, instantiationInfo()
    template log*(msg: string) = doLog LogLevel.None, msg, channels, instantiationInfo()
    template logEcho*(msg: string) = echo msg; log msg

    # aliases
    template warning(msg: string) = warn msg


template logChannels*(channels: static openArray[string], body: untyped) =
    # logChannels ["channel"]:
    #   (...)
    logChannels channels
    body


template logIndent*(body) =
    # logIndent:
    #   (...)
    increaseLogIndentation()
    body
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
