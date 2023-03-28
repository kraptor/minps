# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../core/[log, util]
import address

logChannels {LogChannel.er1}


const
    ER1_MAX_SIZE = 8192 * 1024

    # device regions (in kuseg when possible)
    ER1_START* = (Address 0x1F00_0000).toKUSEG()
    ER1_END* = KusegAddress ER1_START.uint32 + ER1_MAX_SIZE

type
    ExpansionRegion1* = ref object


proc New*(T: type ExpansionRegion1): ExpansionRegion1 =
    debug "Creating ExpansionRegion1..."
    result = ExpansionRegion1()
    debug "ExpansionRegion1 created!"


proc Reset*(self: ExpansionRegion1) =
    debug "Resetting ExpansionRegion1..."
    # TODO: reset Expansion 1 devices here if it's ever implemented
    debug("ExpansionRegion1 Resetted.")


proc Read8 *(self: ExpansionRegion1, address: KusegAddress): uint8  {.inline.} = Read[uint8 ](self, address)
proc Read16*(self: ExpansionRegion1, address: KusegAddress): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: ExpansionRegion1, address: KusegAddress): uint32 {.inline.} = Read[uint32](self, address)

proc Read*[T: uint8|uint16|uint32](self: ExpansionRegion1, address: KusegAddress): T =
    # TODO: We don't support devices in the Expansion Region 1, which is the parallel port.

    warn fmt"ExpansionRegion1 Read[{$T}]: address={address}."
    warn fmt"- Ignored: Expansion Region 1 is not supported."
    const value_no_expansion_present = 0xFF
    return value_no_expansion_present 

    # assert is_aligned[T](address)
    # NOT_IMPLEMENTED fmt"ExpansionRegion1 Read[{$T}]: address={address}"


proc Write8 *(self: ExpansionRegion1, address: KusegAddress, value: uint8 ) {.inline.} = Write[uint8 ](self, address, value)
proc Write16*(self: ExpansionRegion1, address: KusegAddress, value: uint16) {.inline.} = Write[uint16](self, address, value)
proc Write32*(self: ExpansionRegion1, address: KusegAddress, value: uint32) {.inline.} = Write[uint32](self, address, value)

proc Write*[T: uint8|uint16|uint32](self: ExpansionRegion1, address: KusegAddress, value: T) =
    #assert is_aligned[T](address)
    NOT_IMPLEMENTED fmt"ExpansionRegion1 Write[{$T}]: address={address} value={value:08x}h"