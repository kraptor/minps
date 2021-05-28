# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../core/[log, util]
import address

logChannels ["irq"]


const
    IC_MAX_SIZE = 4

    # device regions (in kuseg when possible)
    IC_START* = (Address 0x1F80_1070).toKUSEG()
    IC_END* = KusegAddress IC_START.uint32 + IC_MAX_SIZE

type
    InterruptControl* = ref object


proc New*(T: type InterruptControl): InterruptControl =
    debug "Creating InterruptControl..."
    logIndent:
        result = InterruptControl()
        debug "InterruptControl created!"


proc Reset*(self: InterruptControl) =
    debug "Resetting InterruptControl..."
    logIndent:
        # TODO: reset Expansion 1 devices here if it's ever implemented
        debug("InterruptControl Resetted.")


# proc Read8 *(self: InterruptControl, address: KusegAddress): uint8  {.inline.} = Read[uint8 ](self, address)
# proc Read16*(self: InterruptControl, address: KusegAddress): uint16 {.inline.} = Read[uint16](self, address)
# proc Read32*(self: InterruptControl, address: KusegAddress): uint32 {.inline.} = Read[uint32](self, address)

proc Read*[T: uint8|uint16|uint32](self: InterruptControl, address: KusegAddress): T =
    assert is_aligned[T](address)
    NOT_IMPLEMENTED fmt"InterruptControl Read[{$T}]: address={address}"


# proc Write8 *(self: InterruptControl, address: KusegAddress, value: uint8 ) {.inline.} = Write[uint8 ](self, address, value)
# proc Write16*(self: InterruptControl, address: KusegAddress, value: uint16) {.inline.} = Write[uint16](self, address, value)
# proc Write32*(self: InterruptControl, address: KusegAddress, value: uint32) {.inline.} = Write[uint32](self, address, value)

proc Write*[T: uint8|uint16|uint32](self: InterruptControl, address: KusegAddress, value: T) =
    #assert is_aligned[T](address)
    NOT_IMPLEMENTED fmt"InterruptControl Write[{$T}]: address={address} value={value:08x}h"