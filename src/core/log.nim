# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import sets
import times
import streams
import strutils
import terminal


type
    LogContextProc = proc(): string {.nimcall, closure.}
    LogFilterProc = proc(msg: string, channels: set[LogChannel]): bool {.nimcall.}

    LogChannel* {.size: sizeof(uint32), pure.} = enum
        cli
        main
        cpu
        config
        gui
        app
        bios
        mc
        ram
        spu
        er1
        er2
        irq
        timers
        dma
        mmu
        cop0
        syscall
        disasm
        ops
        platform
        END = 32

    LogLevel* {.pure.} = enum
        Exception = "EXC"
        Critical  = "CRI"
        Error     = "ERR"
        Warning   = "WRN"
        Notice    = "NOT"
        None      = "   "
        Debug     = "DBG"
        Trace     = "TRC"

    SourceInfo = tuple[filename: string, line: int, column: int]

    LogRecord = tuple
        level: LogLevel
        channels: set[LogChannel]
        context: string
        message: string

const
    LOG_MESSAGE_WIDTH = 80
    ALL_CHANNELS*: set[LogChannel] = {LogChannel(0) .. LogChannel.platform}

var
    log_initialized: bool = false
    log_enabled: bool = true
    log_level: LogLevel = LogLevel.Trace
    log_channels_enabled: set[LogChannel] = {}
    log_context_callback: LogContextProc = nil
    log_stream: Stream = newFileStream(io.stdout)
    log_filters: seq[LogFilterProc]
    log_current_indentation: int = 0
    log_indentation_width: int = 2


proc logIncIndent = log_current_indentation += log_indentation_width
proc logDecIndent = log_current_indentation = max(0, log_current_indentation - log_indentation_width)


proc logSetEnabled*(enabled: bool) = 
    log_enabled = enabled

proc logSetLogLevel*(level: LogLevel) =
    log_level = level

proc logGetLogLevelColor(level: LogLevel): ForegroundColor =
    when defined(LOG_NO_COLORS):
        return fgDefault
    else:
        return case level:
            of LogLevel.Trace    : fgMagenta
            of LogLevel.Critical : fgMagenta
            of LogLevel.Exception: fgMagenta
            of LogLevel.Error    : fgRed
            of LogLevel.Debug    : fgCyan
            of LogLevel.Warning  : fgYellow
            of LogLevel.Notice   : fgGreen
            of LogLevel.None     : fgDefault


proc logInitializeImpl(stream: Stream) =
    if log_initialized:
        raise newException(Exception, "Log is already initialized!")
    log_initialized = true
    log_stream = stream


proc logInitialize*(file: File) =
    var stream = newFileStream(file)
    logInitializeImpl(stream)


proc logInitialize*(filename: string, buffer_size = 50*1024*1024) =
    var stream = newFileStream(filename, FileMode.fmWrite, buffer_size)
    logInitializeImpl(stream)


proc logSetContextCallback*(callback: LogContextProc) =
    log_context_callback = callback


proc logSetFilters*(filters: seq[LogFilterProc]) =
    log_filters = filters 

proc logSetEnabledChannels*(channels: set[LogChannel]) =
    log_channels_enabled = channels
    echo "Channels enabled: " & $log_channels_enabled

macro logScope*(body) = discard # TODO: remove

proc doLogImpl(level: LogLevel, channels: set[LogChannel], msg: string) = 
    for filter_proc in log_filters:
        if not filter_proc(msg, channels):
            return

    let context =
        if log_context_callback != nil:
            log_context_callback()
        else:
            ""

    log_stream.write:
        now().format("yyyy-MM-dd HH:mm:ss'.'ffffff") &
        context & " " & 
        align($level   ,  3) & " " &
        align($channels, 12) & " " &
        alignLeft(spaces(log_indentation_width) & msg, LOG_MESSAGE_WIDTH) &
        "\p"


template doLog(level: LogLevel, channels: set[LogChannel], msg: string) =
    if log_enabled and level <= log_level:
        block check_channels:
            for c in channels:
                if c in log_channels_enabled:
                    doLogImpl level, channels, msg
                    break check_channels
    else:
        discard
    

proc logFlush*() = 
    log_stream.flush()

template logFinalize*() = discard

const
    NoChannels: set[LogChannel] = {}

# template logEcho*(msg: string) = echo msg
# template trace* (msg: string) = doLog Trace  , NoChannels, msg
# template error* (msg: string) = doLog Error  , NoChannels, msg
# template warn  *(msg: string) = doLog Warning, NoChannels, msg
# template notice*(msg: string) = doLog Notice , NoChannels, msg
# template debug *(msg: string) = doLog Debug  , NoChannels, msg


template logChannels*(channels: static set[LogChannel]) =
    template logEcho*(msg: string) = echo msg
    template trace  *(msg: string) = doLog Trace  , channels, msg
    template error  *(msg: string) = doLog Error  , channels, msg
    template warn   *(msg: string) = doLog Warning, channels, msg
    template notice *(msg: string) = doLog Notice , channels, msg
    template debug  *(msg: string) = doLog Debug  , channels, msg
