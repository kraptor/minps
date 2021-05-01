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

# Dependencies

requires "nim >= 1.4.6"
requires "sim >= 0.1.3"
requires "nimgl >= 1.1.10"

# Utilities

proc appendBinaries(postfix: string) =
    withDir binDir:
        for binary in bin:
            mvFile(toExe(binary), toExe(binary & postfix))

proc stripFile(path: string, filename: string) =
    let strip_bin = findExe "strip"
    if strip_bin != "":
        echo "Running strip on: " & filename
        withDir path:
            exec strip_bin & " " & filename
    else:
        echo "******* WARNING: Missing 'strip' command. Skipped."

# Tasks

task build_debug, "Build debug version":
    exec "nimble --silent -d:debug --gc:orc --debugger:native --debuginfo --linedir:on --threads:on -d:MINPS_DEBUG -d:Version:" & version & " build"
    appendBinaries "_debug"

task build_release, "Build release version":
    exec "nimble --silent -d:danger --gc:orc --opt:speed --passC:-flto --passC:-O3 --threads:on -d:MINPS_RELEASE -d:Version:" & version & " build"
    appendBinaries "_release"
    stripFile binDir, toExe("minps_release")

task build_release_stacktrace, "Build release version (with stacktraces)":
    exec "nimble --silent -d:danger --gc:orc --stackTrace:on --opt:speed --passC:-flto --passC:-O3 --threads:on -d:MINPS_RELEASE -d:Version:" & version & " build"
    appendBinaries "_release_stacktrace"

task build_profiler, "Build with profiler":
    exec "nimble --silent -d:danger --gc:orc --profiler:on --stackTrace:on -d:MINPS_PROFILER --threads:on -d:Version:" & version & " build"
    appendBinaries "_profiler"

task build_profiler_memory, "Build with memory profiler":
    exec "nimble --silent -d:danger --gc:orc --profiler:off -d:memProfiler --stackTrace:on --threads:on -d:MINPS_PROFILER_MEMORY -d:Version:" & version & " build"
    appendBinaries "_profiler_memory"

task build_all, "Build all minps versions":
    exec "nimble build_debug"
    exec "nimble build_release"
    exec "nimble build_release_stacktrace"
    exec "nimble build_profiler"
    exec "nimble build_profiler_memory"

task clean, "Clean all build files":
    rmDir "__nimcache"
    rmDir binDir
    rmFile "profile_results.txt"
