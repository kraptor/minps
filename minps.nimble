# Package

version       = "0.0.1"
author        = "kraptor"
description   = "A wannabe PlayStation 1 emulator"
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
backend       = "cpp"
bin           = @[
    "minps"
]

# Library dependencies
const cimgui_version = "1.82"

# Dependencies

requires "nim   >= 1.6.0"
requires "jsony >= 1.0.5"
requires "nimgl >= 1.3.2"

# Utilities

proc appendBinaries(postfix: string) =
    withDir binDir:
        for binary in bin:
            mvFile(toExe(binary), toExe(binary & postfix))

# Tasks

task build_debug, "Build debug version":
    exec "nimble -d:debug --debugger:native --debuginfo --linedir:on -d:MINPS_DEBUG -d:Version:" & version & " build"
    appendBinaries "_debug"

task build_release, "Build release version":
    exec "nimble -d:danger --opt:speed -d:lto -d:strip -d:MINPS_RELEASE -d:Version:" & version & "-l:cimgui build"
    appendBinaries "_release"

task build_callgrind, "Build callgrind version (callgrind)":
    exec "nimble -d:danger --opt:speed -d:MINPS_RELEASE -d:MINPS_CALLGRIND -d:Version:" & version & " build"
    appendBinaries "_callgrind"

task build_release_stacktrace, "Build release version (with stacktraces)":
    exec "nimble -d:danger --stackTrace:on --opt:speed -d:MINPS_RELEASE -d:Version:" & version & " build"
    appendBinaries "_release_stacktrace"

task build_profiler, "Build with profiler":
    exec "nimble -d:danger --profiler:on --stackTrace:on -d:MINPS_PROFILER -d:Version:" & version & " build"
    appendBinaries "_profiler"

task build_profiler_memory, "Build with memory profiler":
    exec "nimble -d:danger --profiler:off -d:memProfiler --stackTrace:on -d:MINPS_PROFILER_MEMORY -d:Version:" & version & " build"
    appendBinaries "_profiler_memory"

task build_all, "Build all minps versions":
    exec "nimble build_debug"
    exec "nimble build_release"
    exec "nimble build_callgrind"
    exec "nimble build_release_stacktrace"
    exec "nimble build_profiler"
    exec "nimble build_profiler_memory"

task clean, "Clean all build files":
    rmDir "__nimcache"
    rmDir binDir
    rmFile "profile_results.txt"
    exec "rm -f callgrind.out*"


task build_cimgui, "Build cimgui dll":
    let tmpdir = "__build_cimgui"

    if dirExists(tmp_dir):
        rmDir(tmp_dir)

    exec("git clone --recursive https://github.com/cimgui/cimgui " & tmp_dir)
        
    withDir tmpdir:
        exec("git pull")
        exec("git checkout tags/" & cimgui_version)
        exec("git submodule update")        
        exec("make")
        cpFile("cimgui.so", "../bin/cimgui.so")

    # rmDir(tmp_dir)