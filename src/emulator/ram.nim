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

logChannels ["ram"]


const
    RAM_MAX_SIZE = 1024 * 1024 * 8 # 8MB max Ram

    # device regions (in kuseg when possible)
    RAM_START* = (Address 0x0).toKUSEG()
    RAM_END* = KusegAddress RAM_START.uint32 + RAM_MAX_SIZE

type
    RamData {.union.} = object
        u8: array[Ram_MAX_SIZE, uint8]
        u16: array[Ram_MAX_SIZE div 2, uint16]
        u32: array[Ram_MAX_SIZE div 4, uint32]

    Ram* = ref object
        data*: RamData


proc New*(T: type Ram): Ram =
    debug "Creating Ram..."
    logIndent:
        result = Ram()
        debug "Ram created!"


proc Reset*(self: Ram) =
    debug "Resetting Ram..."
    logIndent:
        self.data.reset()
        debug("Ram Resetted.")


proc Read8*(self: Ram, address: KusegAddress): uint8 {.inline.}   = Read[uint8](self, address)
proc Read16*(self: Ram, address: KusegAddress): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: Ram, address: KusegAddress): uint32 {.inline.} = Read[uint32](self, address)

proc Read*[T: uint8|uint16|uint32](self: Ram, address: KusegAddress): T =
    let
        offset = cast[uint32](address)

    when T is uint32:
        return self.data.u32[offset]
    
    NOT_IMPLEMENTED fmt"RAM Read[{$T}]: address={address}"


proc Write8*(self: Ram, address: KusegAddress, value: uint8) {.inline.}   = Write[uint8](self, address, value)
proc Write16*(self: Ram, address: KusegAddress, value: uint16) {.inline.} = Write[uint16](self, address, value)
proc Write32*(self: Ram, address: KusegAddress, value: uint32) {.inline.} = Write[uint32](self, address, value)

proc Write*[T: uint8|uint16|uint32](self: Ram, address: KusegAddress, value: T) =
    NOT_IMPLEMENTED fmt"RAM Write[{$T}]: address={address} value={value:08x}h"