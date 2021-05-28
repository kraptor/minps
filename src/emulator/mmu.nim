# Copyright (c) 2021 kraptor
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# {.experimental: "codeReordering".}

import strformat

import ../core/[util, log]
import address
import bios
import mc
import ram
import spu
import post

logChannels ["mmu"]


type
    Mmu* = ref object
        bios*: Bios
        mc: MemoryControl
        ram: Ram
        spu: Spu
        post: Post

        cache_control: CacheControlRegister


proc New*(T: type Mmu, bios: Bios): Mmu =
    result = Mmu(
        bios: bios,
        mc: MemoryControl.New(),
        ram: Ram.New(),
        spu: Spu.New(),
        post: Post.New()
    )


proc Reset*(self: Mmu) =
    # self.bios.Reset() # BIOS should not be resetted
    Reset self.mc
    Reset self.ram
    Reset self.spu
    Reset self.post
    # TODO: implement full MMU reset
    warn "MMU Reset not fully implemented!"


proc ReadImpl[T: uint32|uint16|uint8](self: Mmu, address: Address): T =
    block CheckKSEG2Addresses:
        # KSEG2 addresses are NOT mapped to KUSEG, so we have to test for them first
        if unlikely(address.inKSEG2()):
            return ReadMc3[T](self.mc, address)

    block CheckOtherAddresses:
        let ka = address.toKUSEG()
        trace fmt"read[{$T}] ka={ka}"

        if   ka <= RAM_END   : return Read[T](self.ram, ka)
        elif ka <  BIOS_START: error "No device found before BIOS"
        elif ka <= BIOS_END  : return Read[T](self.bios, ka)

        NOT_IMPLEMENTED fmt"MMU Read: No device found at address: {address}"


proc WriteImpl*[T: uint32|uint16|uint8](self: Mmu, address: Address, value: T) =
    block CheckKSEG2Addresses:
        # KSEG2 addresses are NOT mapped to KUSEG, so we have to test for them first
        if unlikely(address.inKSEG2()):
            WriteMc3[T](self.mc, address, value)
            return

    block CheckOtherAddresses:
        let ka = address.toKUSEG()
        trace fmt"write[{$T}] ka={ka} value={value:08x}"

        if   ka <= RAM_END   : Write(self.ram, ka, value); return
        elif ka <  MC1_START : error "No device found before MemoryControl 1"
        elif ka <= MC1_END   : Write(self.mc, ka, value); return
        elif ka <  SPU_START : error "No device found before SPU"
        elif ka <= SPU_END   : Write(self.spu, ka, value); return
        elif ka <  POST_START: error "No device found before POST"
        elif ka <= POST_END  : Write(self.post, ka, value); return
        elif ka <  BIOS_START: error "No device found before BIOS"
        elif ka <= BIOS_END  : error "BIOS is not writable!"

        NOT_IMPLEMENTED fmt"MMU Write: No device found at address: {address}"


proc Read*[T: uint32|uint16|uint8](self: Mmu, address: Address): T {.inline.} =
    trace fmt"read[{$T}] address={address}"
    ReadImpl[T](self, address)

proc ReadDebug*[T: uint32|uint16|uint8](self: Mmu, address: Address): uint32 {.inline.} = ReadImpl[T](self, address)
proc Read8*(self: Mmu, address: Address): uint8 {.inline.} = Read[uint8](self, address)
proc Read16*(self: Mmu, address: Address): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: Mmu, address: Address): uint32 {.inline.} = Read[uint32](self, address)

proc Write*[T: uint32|uint16|uint8](self: Mmu, address: Address, value: T) {.inline.} =
    trace fmt"write[{$T}] address={address}"
    WriteImpl[T](self, address, value)

proc WriteDebug*[T: uint32|uint16|uint8](self: Mmu, address: Address, value: T) {.inline.} = WriteImpl[T](self, address, value)
proc Write8*(self: Mmu, address: Address, value: uint8) {.inline.} = Write(self, address, value)
proc Write16*(self: Mmu, address: Address, value: uint16) {.inline.} = Write(self, address, value)
proc Write32*(self: Mmu, address: Address, value: uint32) {.inline.} = Write(self, address, value)


