# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import cligen

include inc/profiler # NOTE: should be an include for it to work
include inc/concept_check # NOTE: we want to check concepts asap

import core/log
import core/config
import core/version


from ui/cli import nil
from ui/gui import nil

logChannels {LogChannel.main}


type
    RunMode = enum
        Console
        Gui


proc main(run_mode: RunMode) =
    logEcho "minps - a wannabe PlayStation 1 emulator"
    logEcho "version: " & VersionString

    logInitialize  "minps.log"
    logSetLogLevel LogLevel.Trace
    logSetEnabledChannels {LogChannel.cli}

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
        proc cmd_cli = main(Runmode.Console)
        proc cmd_gui = main(Runmode.Gui)

        dispatchMulti(
            [cmd_cli, cmd_name="cli", doc="start in command-line mode"],
            [cmd_gui, cmd_name="gui", doc="start in GUI mode"]
        )
    finally:
        logFinalize()
