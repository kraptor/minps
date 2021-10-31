# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

include inc/profiler # NOTE: should be an include for it to work
include inc/concept_check # NOTE: we want to check concepts asap

import core/log
import core/config
import core/version


from ui/cli import nil
from ui/gui import nil


logFile "minps.log"
logChannels ["main"]


type
    RunMode = enum
        Console
        Gui


proc main(run_mode: RunMode) =
    logEcho "minps - a wannabe PlayStation 1 emulator"
    logEcho "version: " & VersionString

    var 
        config = Config.New("minps.cfg")
        
    case run_mode:
        of Console:
            notice "Using command-line interface."
            cli.main(config)
        of Gui:
            notice "Using GUI interface."
            gui.main(config)

    config.save("minps.cfg")


when isMainModule:
    try:
        # TODO: add switch to use cli/gui mode
        main(Gui)
    finally:
        logFinalize()
