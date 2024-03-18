# Copyright (c) 2024 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strutils

type BuildMode* {.pure.} = enum
  Release = "release"
  ReleaseWithStacktrace = "release_stacktrace"
  ReleaseForCallgrind = "release_callgrind"
  ReleaseProfiler = "release_profiler"
  ReleaseMemoryProfiler = "release_profiler_memory"
  Debug = "debug"
  Unknown = "unknown"

const
  MINPS_MODE {.strdefine.} = "unknown"
  Build* = parseEnum[BuildMode](MINPS_MODE)
