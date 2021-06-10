# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import sim
import ../core/log

logChannels ["config"]


type
    GuiConfig* = object 
        window_width  *{.defaultValue: 1024.} : int32
        window_height *{.defaultValue:  400.} : int32

    Config* = object
        bios_file *{.defaultValue: "bios.bin".}: string
        gui *: GuiConfig


proc New*(T: type Config, ini_file: string): Config =
    notice "Loading configuration from: " & ini_file
    logIndent:
        try:
            result = loadObject[Config](ini_file)
        except IOError as e:
            logEcho "Can't open config file: " & ini_file
            raise e
        except KeyError as e:
            # TODO: update this when https://github.com/ba0f3/sim.nim/pull/2 is merged
            logEcho "Invalid INI file contents: " & ini_file
            logEcho "Reason: " & e.msg
            raise e