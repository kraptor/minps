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
    BIOS_MAX_SIZE = 1024 * 1024 * 4 # 4MB max BIOS

    # device regions (in kuseg1 when possible)
    BIOS_START* = (Address 0xBFC00000).toKUSEG()
    BIOS_END* = KusegAddress BIOS_START.uint32 + BIOS_MAX_SIZE

type
    BiosData {.union.} = object
        u8: array[BIOS_MAX_SIZE, uint8]
        u16: array[BIOS_MAX_SIZE div 2, uint16]
        u32: array[BIOS_MAX_SIZE div 4, uint32]

    Bios* = ref object
        data*: BiosData #array[BIOS_MAX_SIZE, uint8]
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
    result.size_loaded = readData(stream, result.data.u8.addr, result.data.u8.len)
    assert result.size_loaded > 0


proc FromFile*(T: type Bios, filename: string): Bios =
    debug fmt"Loading BIOS from file: {filename}"
    logIndent:
        result = Bios.FromStream(openFileStream(filename))
        result.filename = filename
        debug fmt"BIOS Loaded. Size: {result.size_loaded} bytes"


proc Read8*(self: Bios, address: KusegAddress): uint8 {.inline.} = Read[uint8](self, address)
proc Read16*(self: Bios, address: KusegAddress): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: Bios, address: KusegAddress): uint32 {.inline.} = Read[uint32](self, address)


proc Read*[T: uint8|uint16|uint32](self: Bios, address: KusegAddress): T =
    let offset = address - BIOS_START
    assert offset <= BIOS_MAX_SIZE.KusegAddress
    if T is uint32:
        let offset_u32 = offset.uint32 shr 2
        result = cast[T](self.data.u32[offset_u32])
        trace fmt"read[{$typeof(T)}] offset={offset} value={result:08x}h"
        return result
    else:
        NOT_IMPLEMENTED "Bios read not implemented: " & $type(T)

    debug "BIOS READ VALUE: " & $(result)
