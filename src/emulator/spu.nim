# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../core/[log, util]
import address

logChannels ["spu"]


const
    SPU_MAX_SIZE = 1024

    # device regions (in kuseg when possible)
    SPU_START* = (Address 0x1F801C08).toKUSEG()
    SPU_END* = KusegAddress SPU_START.uint32 + SPU_MAX_SIZE

type
    SpuData {.union.} = object
        u8 : array[SPU_MAX_SIZE, uint8]
        u16: array[SPU_MAX_SIZE div 2, uint16]
        u32: array[SPU_MAX_SIZE div 4, uint32]

    Spu* = ref object
        data*: SpuData


proc New*(T: type Spu): Spu =
    debug "Creating Spu..."
    logIndent:
        result = Spu()
        debug "Spu created!"


proc Reset*(self: Spu) =
    debug "Resetting Spu..."
    logIndent:
        self.data.reset()
        debug("Spu Resetted.")


proc Read8 *(self: Spu, address: KusegAddress): uint8  {.inline.} = Read[uint8 ](self, address)
proc Read16*(self: Spu, address: KusegAddress): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: Spu, address: KusegAddress): uint32 {.inline.} = Read[uint32](self, address)

proc Read*[T: uint8|uint16|uint32](self: Spu, address: KusegAddress): T =
    let
        offset {.used.} = cast[uint32](address)

    # when T is uint32:
    #     return self.data.u32[offset]
    
    NOT_IMPLEMENTED fmt"SPU Read[{$T}]: address={address}"


proc Write8 *(self: Spu, address: KusegAddress, value: uint8 ) {.inline.} = Write[uint8 ](self, address, value)
proc Write16*(self: Spu, address: KusegAddress, value: uint16) {.inline.} = Write[uint16](self, address, value)
proc Write32*(self: Spu, address: KusegAddress, value: uint32) {.inline.} = Write[uint32](self, address, value)

proc Write*[T: uint8|uint16|uint32](self: Spu, address: KusegAddress, value: T) =
    let
        offset {.used.} = cast[uint32](address)

    # when T is uint32:
    #     self.data.u32[offset] = value
    #     return

    NOT_IMPLEMENTED fmt"SPU Write[{$T}]: address={address} value={value:08x}h"