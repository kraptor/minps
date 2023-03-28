# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat

import ../core/log
import ../core/config
import ../emulator/platform
import ../emulator/bios/bios

logChannels {LogChannel.cli, Logchannel.main}


proc main*(config: var Config) =
    notice "minps started"
    
    var platform = Platform.New(
        Bios.FromFile(config.bios.file)
    )

    proc log_context_callback(): string = 
        $platform.cpu.stats.instruction_count
        
    logSetContextCallback log_context_callback
    
    try:
        platform.Run()
    except Exception as e:
        echo fmt"Cycle count: {platform.cpu.stats.cycle_count}"
        raise e

    notice "minps stopped"