# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../core/[log, util]
import address

logChannels {LogChannel.er2}


const
    ER2_MAX_SIZE = 0x72

    # device regions (in kuseg when possible)
    ER2_START* = (Address 0x1F802000).toKUSEG()
    ER2_END* = KusegAddress ER2_START.uint32 + ER2_MAX_SIZE

type
    PostLed {.packed.} = object
        status       {.bitsize: 4.}: uint8
        UNUSED_04_07 {.bitsize: 4.}: uint8

    ExpansionRegion2* = ref object
        post_led: PostLed


proc New*(T: type ExpansionRegion2): ExpansionRegion2 =
    debug "Creating ExpansionRegion2..."
    result = ExpansionRegion2()
    debug "ExpansionRegion2 created!"


proc Reset*(self: ExpansionRegion2) =
    debug "Resetting ExpansionRegion2..."
    self.post_led.reset()
    debug("ExpansionRegion2 Resetted.")


proc Read8 *(self: ExpansionRegion2, address: KusegAddress): uint8  {.inline.} = Read[uint8 ](self, address)
proc Read16*(self: ExpansionRegion2, address: KusegAddress): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: ExpansionRegion2, address: KusegAddress): uint32 {.inline.} = Read[uint32](self, address)

proc Read*[T: uint8|uint16|uint32](self: ExpansionRegion2, address: KusegAddress): T =
    assert is_aligned[T](address)

    NOT_IMPLEMENTED fmt"ExpansionRegion2 Read[{$T}]: address={address}"


proc Write8 *(self: ExpansionRegion2, address: KusegAddress, value: uint8 ) {.inline.} = Write[uint8 ](self, address, value)
proc Write16*(self: ExpansionRegion2, address: KusegAddress, value: uint16) {.inline.} = Write[uint16](self, address, value)
proc Write32*(self: ExpansionRegion2, address: KusegAddress, value: uint32) {.inline.} = Write[uint32](self, address, value)

proc Write*[T: uint8|uint16|uint32](self: ExpansionRegion2, address: KusegAddress, value: T) =
    assert is_aligned[T](address)

    when T is uint8:
        case cast[uint32](address):
        of 0x1F802041:
            self.post_led.status = value
            logEcho fmt"POST/LED set to: {self.post_led.status:x}h." 
            return
        else:
            discard
    
    NOT_IMPLEMENTED fmt"ExpansionRegion2 Write[{$T}]: address={address} value={value:08x}h"