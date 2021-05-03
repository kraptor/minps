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
    BIOS_MAX_SIZE = 1024 * 1024 * 2 # 2MB max BIOS

    # device regions (in kuseg1 when possible)
    BIOS_START* = (Address 0xBFC00000).toKUSEG()
    BIOS_END* = BIOS_START + BIOS_MAX_SIZE

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


proc Read8*(self: Bios, address: Address): uint8 {.inline.} = Read[uint8](self, address)
proc Read16*(self: Bios, address: Address): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: Bios, address: Address): uint32 {.inline.} = Read[uint32](self, address)


proc Read*[T: uint8|uint16|uint32](self: Bios, address: Address): T =
    if T is uint32:
        NOT_IMPLEMENTED "Bios read not implemented:*** " & $type(T)
    else:
        NOT_IMPLEMENTED "Bios read not implemented: " & $type(T)
