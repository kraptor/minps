# Package

version = "0.1.0"
author = "kraptor"
description = "A wannabe PlayStation 1 emulator"
license = "MIT"
srcDir = "src"
binDir = "bin"
backend = "cpp"
bin = @["minps"]

# Dependencies

requires "nim >= 2.0.2"
requires "jsony >= 1.1.5"

# Utility functions

proc postfixBinaries(name: string) =
  withDir binDir:
    for binary in bin:
      mvFile binary.toExe, (binary & name).toExe

# Build tasks

let common_options = "--mm:orc -d:MINPS_VERSION:" & version

task build_debug, "Build debug version":
  echo ">>>>>>>>>> Building: DEBUG <<<<<<<<<<"
  exec "nimble -d:debug -d:nimDebugDlOpen --debugger:native --debuginfo -d:nimTypeNames --linedir:on -d:MINPS_MODE:debug " &
    common_options & " build"
  postfixBinaries "_debug"

task build_release, "Build release version":
  echo ">>>>>>>>>> Building: RELEASE <<<<<<<<<<"
  exec "nimble -d:danger --opt:speed -d:flto -d:strip -d:MINPS_MODE:release " &
    common_options & " build"
  postfixBinaries "_release"

task build_release_stacktrace, "Build release version (with stacktraces)":
  echo ">>>>>>>>>> Building: RELEASE (stacktrace) <<<<<<<<<<"
  exec "nimble -d:danger --stackTrace:on --opt:speed -d:MINPS_MODE:release_stacktrace " &
    common_options & " build"
  postfixBinaries "_release_stacktrace"

task build_callgrind, "Build callgrind version (callgrind)":
  echo ">>>>>>>>>> Building: RELEASE (callgrind) <<<<<<<<<<"
  exec "nimble -d:danger --opt:speed -d:MINPS_MODE:release_callgrind " & common_options &
    " build"
  postfixBinaries "_callgrind"

task build_profiler, "Build with profiler":
  echo ">>>>>>>>>> Building: RELEASE (profiler) <<<<<<<<<<"
  exec "nimble -d:danger --profiler:on --stackTrace:on -d:MINPS_PROFILER  -d:MINPS_MODE:release_profiler " &
    common_options & " build"
  postfixBinaries "_profiler"

task build_profiler_memory, "Build with memory profiler":
  echo ">>>>>>>>>> Building: RELEASE (memory profiler) <<<<<<<<<<"
  exec "nimble -d:danger --profiler:off -d:memProfiler --stackTrace:on -d:MINPS_PROFILER -d:MINPS_MODE:release_profiler_memory " &
    common_options & " build"
  postfixBinaries "_profiler_memory"

task build_all, "Build all minps versions":
  exec "nimble build_debug"
  exec "nimble build_release"
  exec "nimble build_callgrind"
  exec "nimble build_release_stacktrace"
  exec "nimble build_profiler"
  exec "nimble build_profiler_memory"

task wipe, "Clear all build files":
  echo ">>>>>>>>>> WIPE BUILD FILES <<<<<<<<<<"
  rmDir "__nimcache"
  rmDir "htmldocs"
  rmDir binDir
  rmFile "profile_results.txt"
  exec "rm -f callgrind.out*"

task build_docs, "Generate documentation":
  echo ">>>>>>>>>> DOCUMENTATION <<<<<<<<<<"
  exec "nimble doc --project --index:on --showNonExports --docInternal " & srcDir &
    "/minps.nim --out:htmldocs"

task release, "Generate a release tarball":
  exec "nimble wipe"
  exec "nimble build_release"
  