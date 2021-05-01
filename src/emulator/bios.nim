# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import streams
import strformat
import ../core/[log, util]
import address

logChannels ["bios"]


const
    # device regions (in kuseg1 when possible)
    BIOS_START* = (Address 0xBFC00000).toKUSEG()
    BIOS_MAX_SIZE = 1024 * 1024 * 2 # 2MB


type
    Bios* = ref object
        data*: array[BIOS_MAX_SIZE, uint8]
        filename: string
        size_loaded: int


proc New*(T: type Bios): Bios =
    debug "Creating BIOS..."
    logIndent:
        result = Bios()
        debug "BIOS created!"


proc Reset*(self: Bios) =
    debug "Resetting BIOS..."
    logIndent:
        self.data.reset()
        debug("BIOS Resetted.")


proc FromStream*(T: type Bios, stream: Stream): Bios =
    if isNil stream:
        NOT_IMPLEMENTED "Error loading BIOS from stream"

    result = Bios()
    result.size_loaded = readData(stream, result.data.addr, result.data.len)
    assert result.size_loaded > 0


proc FromFile*(T: type Bios, filename: string): Bios =
    debug fmt"Loading BIOS from file: {filename}"
    logIndent:
        result = Bios.FromStream(openFileStream(filename))
        result.filename = filename
        debug fmt"BIOS Loaded. Size: {result.size_loaded} bytes"
