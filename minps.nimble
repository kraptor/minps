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
requires "cligen >= 1.7.0"

# Utility functions

proc postfixBinaries(name: string) =
  withDir binDir:
    for binary in bin:
      mvFile binary.toExe, (binary & name).toExe

# Build tasks
import distros
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
  exec "nimble -d:danger --opt:speed -d:flto --stackTrace:on -d:MINPS_MODE:release_stacktrace " &
    common_options & " build"
  postfixBinaries "_release_stacktrace"

task build_callgrind, "Build release version (for callgrind)":
  echo ">>>>>>>>>> Building: RELEASE (callgrind) <<<<<<<<<<"
  exec "nimble -d:danger --opt:speed -d:flto -d:MINPS_MODE:release_callgrind --linedir:on --debuginfo " & common_options &
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
  exec "nimble build_docs"
  echo ".. done."

task build_docs, "Generate documentation":
  echo ">>>>>>>>>> BUILD DOCUMENTATION <<<<<<<<<<"
  exec "nimble " & common_options &
    " -d:MINPS_MODE:release doc --project --index:on --showNonExports --docInternal --git.commit:ng --git.devel:ng --git.url:https://github.com/kraptor/minps " &
    srcDir & "/minps.nim --out:htmldocs"
  echo ".. done."

task build_dist, "Generate distribution tarballs":
  block: # build everything fresh
    exec "nimble wipe"
    exec "nimble build_release"
    exec "nimble build_docs"
  block: # generate tarball in dist
    echo ">>>>>>>>>> GENERATING TARBALL <<<<<<<<<<"
    mkDir "dist"
    let
      bin_paths = "bin htmldocs README.md LICENSE"
      src_paths = "src tests build.sh minps.nimble README.md LICENSE"
    if detectOs(Windows):
      exec "tar.exe -cf dist/minps." & $version & ".zip " & bin_paths
      exec "tar.exe -cf dist/minps." & $version & ".src.zip " & src_paths
      exec "dir dist/*"
    else:
      exec "tar -cJf dist/minps." & $version & ".tar.xz " & bin_paths
      exec "tar -cJf dist/minps." & $version & ".src.tar.xz " & src_paths
      exec "ls dist/* -alh"
    echo ".. done."

task wipe, "Clear all build files":
  echo ">>>>>>>>>> WIPE BUILD FILES <<<<<<<<<<"
  rmDir "__nimcache"
  rmDir "htmldocs"
  rmDir "dist"
  rmDir binDir
  rmFile "profile_results.txt"
  exec "rm -f callgrind.out*"
  echo ".. done."

task run_callgrind, "Run with callgrind (valgrind), fix symbols and run kcachegrind":
  exec "rm -f callgrind.out*"
  exec "nimble build_callgrind"
  # resources: https://web.stanford.edu/class/cs107/resources/callgrind
  # extra possible params: --dump-instr=yes --collect-jumps=yes --simulate-cache=yes --passC:-Wa,--gstabs --passC:-save-temps
  exec "valgrind --tool=callgrind bin/minps_callgrind > /dev/null"
  # TODO: improve/update nim_callgrind and integrate it here
  # exec "nim_callgrind/nim_callgrind.py `ls callgrind.out.*` callgrind.out"
  exec "kcachegrind"
