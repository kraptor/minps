# Copyright (c) 2021 kraptor
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# {.experimental: "codeReordering".}

import strformat
import macros

import ../core/[util, log]
import address
import bios/bios
import mc
import ram
import spu
import er1
import er2
import irq
import timers
import dma

logChannels ["mmu"]


type
    MmuError = enum
        None          = "No error"
        Before_ER1    = "No device found before Expansion Region 1"
        Before_MC1    = "No device found before MemoryControl 1"
        Before_IC     = "No device found before Interrupt Control"
        Before_DMA    = "No device found before DMA registers"
        Before_TIMERS = "No device found before Timers"
        Before_SPU    = "No device found before SPU"
        Before_ER2    = "No device found before Expansion Region 2"
        Before_BIOS   = "No device found before BIOS"
        # other errors
        BIOS_NotWritable = "BIOS is not writable!"

    Mmu* = ref object
        bios*: Bios
        mc: MemoryControl
        ram: Ram
        er1: ExpansionRegion1
        spu: Spu
        er2: ExpansionRegion2
        ic : InterruptControl
        timers: Timers  
        dma: DmaDevice     

        error: MmuError


proc New*(T: type Mmu, bios: Bios): Mmu =
    result = Mmu(
        bios  : bios,
        mc    : MemoryControl.New(),
        ram   : Ram.New(),
        er1   : ExpansionRegion1.New(),
        spu   : Spu.New(),
        er2   : ExpansionRegion2.New(),
        ic    : InterruptControl.New(),
        timers: Timers.New(),
        dma   : DmaDevice.New(),

        error: MmuError.None
    )


proc Reset*(self: Mmu) =
    # self.bios.Reset() # BIOS should not be resetted
    Reset self.mc
    Reset self.ram
    Reset self.er1
    Reset self.spu
    Reset self.er2
    Reset self.ic
    Reset self.timers
    Reset self.dma
    self.error = MmuError.None

    # TODO: implement full MMU reset
    warn "MMU Reset not fully implemented!"


proc ReadImpl[T: uint32|uint16|uint8](self: Mmu, address: Address): T =
    block CheckKSEG2Addresses:
        # KSEG2 addresses are NOT mapped to KUSEG, so we have to test for them first
        if unlikely(address.inKSEG2()):
            return ReadMc3[T](self.mc, address)

    self.error = MmuError.None

    block CheckOtherAddresses:
        let ka = address.toKUSEG()
        trace fmt"read[{$T}] ka={ka}"

        if   ka <= RAM_END     : return Read[T](self.ram, ka)
        elif ka <  ER1_START   : self.error = Before_ER1
        elif ka <= ER1_END     : return Read[T](self.er1, ka)
        elif ka <  MC1_START   : self.error = Before_MC1
        elif ka <= MC1_END     : return Read[T](self.mc, ka)
        elif ka <  IC_START    : self.error = Before_IC
        elif ka <= IC_END      : return Read[T](self.ic, ka)
        elif ka <  DMA_MAP_START: self.error = Before_DMA
        elif ka <= DMA_MAP_END  : return Read[T](self.dma, ka)
        elif ka <  TIMERS_START: self.error = Before_TIMERS
        elif ka <= TIMERS_END  : return Read[T](self.timers, ka)
        elif ka <  SPU_START   : self.error = Before_SPU
        elif ka <= SPU_END     : return Read[T](self.spu, ka)
        elif ka <  ER2_START   : self.error = Before_ER2
        elif ka <= ER2_END     : return Read[T](self.er2, ka)
        elif ka <  BIOS_START  : self.error = Before_BIOS
        elif ka <= BIOS_END    : return Read[T](self.bios, ka)


proc WriteImpl*[T: uint32|uint16|uint8](self: Mmu, address: Address, value: T) =
    block CheckKSEG2Addresses:
        # KSEG2 addresses are NOT mapped to KUSEG, so we have to test for them first
        if unlikely(address.inKSEG2()):
            WriteMc3[T](self.mc, address, value)
            return

    block CheckOtherAddresses:
        let ka = address.toKUSEG()
        trace fmt"write[{$T}] ka={ka} value={value:08x}"

        if   ka <= RAM_END     : Write(self.ram, ka, value); return
        elif ka <  ER1_START   : self.error = Before_ER1
        elif ka <= ER1_END     : Write(self.er1, ka, value); return
        elif ka <  MC1_START   : self.error = Before_MC1
        elif ka <= MC1_END     : Write(self.mc, ka, value); return
        elif ka <  IC_START    : self.error = Before_IC
        elif ka <= IC_END      : Write(self.ic, ka, value); return
        elif ka <  DMA_MAP_START: self.error = Before_DMA
        elif ka <= DMA_MAP_END  : Write[T](self.dma, ka, value); return
        elif ka <  TIMERS_START: self.error = Before_TIMERS
        elif ka <= TIMERS_END  : Write[T](self.timers, ka, value); return
        elif ka <  SPU_START   : self.error = Before_SPU
        elif ka <= SPU_END     : Write(self.spu, ka, value); return
        elif ka <  ER2_START   : self.error = Before_ER2
        elif ka <= ER2_END     : Write(self.er2, ka, value); return
        elif ka <  BIOS_START  : self.error = Before_BIOS
        elif ka <= BIOS_END    : self.error = BIOS_NotWritable

proc Read*[T: uint32|uint16|uint8](self: Mmu, address: Address): T {.inline.} =
    trace fmt"read[{$T}] address={address}"
    result = ReadImpl[T](self, address)

    if self.error != MmuError.None:
        error $self.error
        # TODO: raise here Bus Error instead of NOT IMPLEMENTED (on devices not found)
        NOT_IMPLEMENTED fmt"MMU Read[{$T}]: No device found at address: {address}"

proc ReadDebug*[T: uint32|uint16|uint8](self: Mmu, address: Address): T = ReadImpl[T](self, address)
proc ReadDebug32*(self: Mmu, address: Address): uint32 = ReadDebug[uint32](self, address)

proc Read8* (self: Mmu, address: Address): uint8  {.inline.} = Read[uint8 ](self, address)
proc Read16*(self: Mmu, address: Address): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: Mmu, address: Address): uint32 {.inline.} = Read[uint32](self, address)

proc Write*[T: uint32|uint16|uint8](self: Mmu, address: Address, value: T) {.inline.} =
    trace fmt"write[{$T}] address={address}"
    WriteImpl[T](self, address, value)

    if self.error != MmuError.None:
        error $self.error
        # TODO: raise here Bus Error instead of NOT IMPLEMENTED (on devices not found)
        NOT_IMPLEMENTED fmt"MMU Write[{$T}]: No device found at address: {address}"

proc WriteDebug*[T: uint32|uint16|uint8](self: Mmu, address: Address, value: T) {.inline.} = WriteImpl[T](self, address, value)
proc Write8* (self: Mmu, address: Address, value: uint8 ) {.inline.} = Write(self, address, value)
proc Write16*(self: Mmu, address: Address, value: uint16) {.inline.} = Write(self, address, value)
proc Write32*(self: Mmu, address: Address, value: uint32) {.inline.} = Write(self, address, value)


