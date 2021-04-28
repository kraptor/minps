# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

include inc/profiler # NOTE: should be an include for it to work
import core/[log, version]


#logFile ":stdout"
logChannels ["main"]


proc main() =
    logEcho "minps - a wannabe PlayStation 1 emulator"
    logEcho "version: " & VersionString

    notice "minps started"
    notice "minps stopped"


when isMainModule:
    main()
