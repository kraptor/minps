# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../core/log
import ../core/config
import ../emulator/platform
import ../emulator/bios/bios

logChannels ["cli", "main"]


proc main*(config: var Config) =
    notice "minps started"
    
    var platform = Platform.New(
        Bios.FromFile(config.bios_file)
    )
    platform.Run()
    notice "minps stopped"