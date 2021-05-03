# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../core/[util, log]
import address
import bios

logChannels ["mmu"]


type
    Mmu* = ref object
        bios: Bios


proc New*(T: type Mmu, bios: Bios):
    Mmu = Mmu(bios: bios)


proc Reset*(self: Mmu) =
    NOT_IMPLEMENTED "MMU Reset not implemented"

proc Read8*(self: Mmu, address: Address): uint8 {.inline.} = Read[uint8](self, address)
proc Read16*(self: Mmu, address: Address): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: Mmu, address: Address): uint32 {.inline.} = Read[uint32](self, address)
proc Read*[T: uint32|uint16|uint8](self: Mmu, address: Address): T =
    trace fmt"Read ({$type(T)}) @ {address}"
    logIndent:
        let ka = address.toKUSEG()

        if ka < BIOS_START: NOT_IMPLEMENTED "No device found before BIOS"
        if ka < BIOS_END: return Read[T](self.bios, ka)

        NOT_IMPLEMENTED "No device found: " & $address


proc Write8*(self: Mmu, address: Address, value: uint8) {.inline.} = Write(self, address, value)
proc Write16*(self: Mmu, address: Address, value: uint16) {.inline.} = Write(self, address, value)
proc Write32*(self: Mmu, address: Address, value: uint32) {.inline.} = Write(self, address, value)
proc Write*[T: uint32|uint16|uint8](self: Mmu, address: Address, value: T) =
    NOT_IMPLEMENTED
