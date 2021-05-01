# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

include inc/profiler # NOTE: should be an include for it to work
include inc/concept_check # NOTE: we want to check concepts asap

import core/[log, version]
import emulator/[config, bios, platform]

#logFile ":stdout"
logChannels ["main"]


proc main() =
    logEcho "minps - a wannabe PlayStation 1 emulator"
    logEcho "version: " & VersionString

    notice "minps started"
    let config = Config.New("minps.ini")
    var platform = Platform.New(
        Bios.FromFile(config.bios_file)
    )
    platform.Run()
    notice "minps stopped"


when isMainModule:
    main()
