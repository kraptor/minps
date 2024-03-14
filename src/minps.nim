# Copyright (c) 2024 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

##[
  .. importdoc:: minps/api

  MinPS entry point.

  When loaded as a module, it exposes the [MinPS API] directly.
]##

# profiler should be enabled asap
when defined(MINPS_PROFILER):
  import nimprof

when isMainModule:
  import minps/main
  minps_main()

when not isMainModule:
  ##[
    When minps is imported as a module, we export the API instead.
  ]##
  import minps/api
  export api
