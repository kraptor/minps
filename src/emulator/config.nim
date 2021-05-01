# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import sim
import ../core/log

logChannels ["config"]


type
    Config* = object
        bios_file* {.defaultValue: "bios.bin".}: string


proc New*(T: type Config, ini_file: string): Config =
    notice "Loading configuration from: " & ini_file
    logIndent:
        try:
            result = to[Config](ini_file)
        except IOError as e:
            error "Can't open config file: " & ini_file
            raise e
        except KeyError as e:
            # TODO: update this when https://github.com/ba0f3/sim.nim/pull/2 is merged
            error "Invalid INI file contents: " & ini_file
            raise e
