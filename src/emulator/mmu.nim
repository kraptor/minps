# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# {.experimental: "codeReordering".}

import strformat

import ../core/[util, log]
import address
import bios
import mc1

logChannels ["mmu"]


type
    Mmu* = ref object
        bios: Bios
        mc1: Mc1


proc New*(T: type Mmu, bios: Bios): Mmu =
    result = Mmu(
        bios: bios,
        mc1: Mc1.New()
    )


proc Reset*(self: Mmu) =
    # self.bios.Reset() # BIOS should not be resetted
    self.mc1.Reset()
    NOT_IMPLEMENTED "MMU Reset not implemented"


proc ReadImpl[T: uint32|uint16|uint8](self: Mmu, address: Address): T =
    let ka = address.toKUSEG()
    
    if ka < BIOS_START: NOT_IMPLEMENTED "No device found before BIOS"
    elif ka <= BIOS_END: return Read[T](self.bios, ka)

    NOT_IMPLEMENTED fmt"MMU Read: No device found at address: {address}"



proc Write*[T: uint32|uint16|uint8](self: Mmu, address: Address, value: T) =
    let ka = address.toKUSEG()
    trace fmt"write[{$type(T)}] address={address} ({ka}) value={value:08x}h"

    if ka < MC1_START: NOT_IMPLEMENTED "No device found before MC1"
    elif ka <= MC1_END: 
        Write self.mc1, ka, value
        return
    elif ka < BIOS_START: NOT_IMPLEMENTED "No device found before BIOS"
    elif ka <= BIOS_END: NOT_IMPLEMENTED fmt"BIOS is not writable!"

    NOT_IMPLEMENTED fmt"MMU Write: No device found at address: {address}"


proc Read*[T: uint32|uint16|uint8](self: Mmu, address: Address): T = 
    trace fmt"read[{$type(T)}] address={address}"
    ReadImpl[T](self, address)

proc ReadDebug*[T: uint32|uint16|uint8](self: Mmu, address: Address): uint32 {.inline.} = 
    ReadImpl[uint32](self, address)

proc Read8*(self: Mmu, address: Address): uint8 {.inline.} = Read[uint8](self, address)
proc Read16*(self: Mmu, address: Address): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: Mmu, address: Address): uint32 {.inline.} = Read[uint32](self, address)
proc Write8*(self: Mmu, address: Address, value: uint8) {.inline.} = Write(self, address, value)
proc Write16*(self: Mmu, address: Address, value: uint16) {.inline.} = Write(self, address, value)
proc Write32*(self: Mmu, address: Address, value: uint32) {.inline.} = Write(self, address, value)