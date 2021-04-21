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

requires "nim >= 1.5.1"
requires "chronicles >= 0.10.1"
requires "nimgl >= 1.1.10"

# Utilities

proc appendBinaries(postfix: string) =
    withDir binDir:
        for b in bin:
            mvFile(b, b & postfix)

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
    exec "nimble -d:debug --debugger:native --debuginfo --linedir:on -d:MINPS_DEBUG -d:Version:" & version & " build"
    appendBinaries "_debug"

task build_release, "Build release version":
    exec "nimble -d:danger --opt:speed --passC:-flto --passC:-O3 -d:MINPS_RELEASE -d:Version:" & version & " build"
    appendBinaries "_release"
    stripFile binDir, "minps_release"

task build_profiler, "Build with profiler":
    exec "nimble --profiler:on --stackTrace:on -d:MINPS_PROFILER -d:Version:" & version & " build"
    appendBinaries "_profiler"

task build_all, "Build all minps versions":
    exec "nimble build_debug"
    exec "nimble build_release"
    exec "nimble build_profiler"

task clean, "Clean all build files":
    rmDir "__nimcache"
    rmDir binDir
