# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strutils
import strformat

import ../core/[log, util]
import address

logChannels ["mc1"]


const
    MC1_MAX_SIZE = 0x64

    # device regions (in kuseg when possible)
    MC1_START* = (Address 0x1F801000).toKUSEG()
    MC1_END* = KusegAddress MC1_START.uint32 + MC1_MAX_SIZE

type
    Mc1* = ref object
        bios_rom_delay_size: DelaySizeRegister
        ram_size: RamSizeRegister
        com_delay: ComDelayRegister

type
    DataBusWidth = enum
        Use8Bits = 0
        Use16Bits = 1

    DmaTimingSelect = enum
        NormalTimings = 0
        OverrideTimings = 1 # use bits 24-27

    WideDma = enum
        UseBit12 = 0
        UseFull32Bits = 1

    DelaySizeRegisterParts* {.packed.} = object
        write_delay          {.bitsize:4.}: uint8
        read_delay           {.bitsize:4.}: uint8
        recovery_period      {.bitsize:1.}: bool
        hold_period          {.bitsize:1.}: bool
        floating_period      {.bitsize:1.}: bool
        pre_strobe_period    {.bitsize:1.}: bool
        data_bus_width       {.bitsize:1.}: DataBusWidth
        auto_increment       {.bitsize:1.}: bool
        UNKNOWN_14_15        {.bitsize:2.}: uint8
        memory_window_size   {.bitsize:5.}: uint8
        UNKNOWN_21_23        {.bitsize:3.}: uint8 # always ZERO
        dma_timing_override  {.bitsize:4.}: uint8
        address_error_flag   {.bitsize:1.}: bool  # write 1 to clear it
        dma_timing_select    {.bitsize:1.}: DmaTimingSelect
        wide_dma             {.bitsize:1.}: WideDma
        wait_external_device {.bitsize:1.}: bool # wait on external device before being ready

    DelaySizeRegister* {.union.} = object
        value: uint32
        parts: DelaySizeRegisterParts

    MemoryWindow = enum
        Memory_1MB_Locked_7MB = 0
        Memory_4MB_Locked_4MB = 1
        Memory_1MB_HighZ_1MB_Locked_6MB = 2
        Memory_4MB_HighZ_4MB = 3
        Memory_2MB_Locked_6MB = 4
        Memory_8MB = 5
        Memory_2MB_HighZ_2MB_Locked_4MB = 6
        Memory_8MB_EXT = 7

    RamSizeRegisterParts* {.packed.} = object
        UNKNOWN_00_02      {.bitsize:3.}: uint8
        UNKNOWN_03_03      {.bitsize:1.}: bool # crashes when zero (see docs)
        UNKNOWN_04_06      {.bitsize:3.}: uint8
        delay_fetch_cycles {.bitsize:1.}: uint8
        UNKNOWN_08_08      {.bitsize:1.}: bool
        memory_window_8mb  {.bitsize:3.}: MemoryWindow
        UNKNOWN_12_15      {.bitsize:4.}: uint8
        UNKNOWN_16_31      {.bitsize:16.}: uint16

    RamSizeRegister* {.union.} = object
        value: uint32
        parts: RamSizeRegisterParts

    ComDelayRegisterParts* {.packed.} = object
        COM0          {.bitsize:4.}: uint8
        COM1          {.bitsize:4.}: uint8
        COM2          {.bitsize:4.}: uint8
        COM3          {.bitsize:4.}: uint8
        UNKNOWN_16_31 {.bitsize:16}: uint16

    ComDelayRegister* {.union.} = object
        value: uint32
        parts: ComDelayRegisterParts


proc New*(T: type Mc1): Mc1 =
    debug "Creating MC1..."
    logIndent:
        result = Mc1()
        debug "MC1 created!"


proc Reset*(self: Mc1) =
    debug "Resetting MC1..."
    logIndent:
        NOT_IMPLEMENTED
        debug("MC1 Resetted.")


proc Read8* (self: Mc1, address: KusegAddress): uint8  {.inline.} = Read[uint8 ](self, address)
proc Read16*(self: Mc1, address: KusegAddress): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: Mc1, address: KusegAddress): uint32 {.inline.} = Read[uint32](self, address)

proc Read*[T: uint8|uint16|uint32](self: Mc1, address: KusegAddress): T =
    trace fmt"read[{$typeof(T)}] address={address:08x}h"
    NOT_IMPLEMENTED "MC1 read not implemented: " & $type(T)


proc Write8* (self: Mc1, address: KusegAddress, value: uint8 ): uint8  {.inline.} = Write[uint8 ](self, address, value)
proc Write16*(self: Mc1, address: KusegAddress, value: uint16): uint16 {.inline.} = Write[uint16](self, address, value)
proc Write32*(self: Mc1, address: KusegAddress, value: uint32): uint32 {.inline.} = Write[uint32](self, address, value)

proc Write*[T: uint8|uint16|uint32](self: Mc1, address: KusegAddress, value: T) =
    trace fmt"write[{$typeof(T)}] address={address} value={value:08x}h"

    when T is uint32:
        case address.uint32:
        of 0x1F801010: self.SetBiosRomDelaySize32(value); return
        of 0x1F801020: self.SetComDelayCommonDelay32(value); return
        of 0x1F801060: self.SetRamSize32(value); return
        else:
            discard

    NOT_IMPLEMENTED "MC1 write not implemented: " & $type(T)


proc GetDescription(reg: DelaySizeRegister): seq[string] =
    let recover_period   = if not reg.parts.recovery_period: "false" else: "Use COM0 timings"
    let hold_period      = if not reg.parts.hold_period    : "false" else: "Use COM1 timings"
    let floating_period  = if not reg.parts.floating_period: "false" else: "Use COM2 timings"
    let prestrobe_period = if not reg.parts.floating_period: "false" else: "Use COM3 timings"
    let wide_dma         = if reg.parts.wide_dma.bool: "Use full 32 bits" else: "Use 'Data Bus width' value (bit 12)"

    return @[
        fmt"Write delay        : {reg.parts.write_delay} cycles",
        fmt"Read delay         : {reg.parts.read_delay} cycles",
        fmt"Recovery Period    : {recover_period}",
        fmt"Hold period        : {hold_period}",
        fmt"Floating period    : {floating_period}",
        fmt"Pre-strobe period  : {prestrobe_period}",
        fmt"Data Bus width     : {reg.parts.data_bus_width}",
        fmt"Auto increment     : {reg.parts.auto_increment}",
        fmt"Memory window size : {1 shl reg.parts.memory_window_size} bytes",
        fmt"DMA timing override: {reg.parts.dma_timing_override:04b}b",
        fmt"Address error flag : {reg.parts.address_error_flag}",
        fmt"DMA timing select  : {reg.parts.dma_timing_select}",
        fmt"Wide DMA           : {wide_dma}",
        fmt"Wait extenal device: {reg.parts.wait_external_device}"
    ]


proc SetBiosRomDelaySize32(self: Mc1, value: uint32) =
    trace fmt"write[BIOS ROM Delay/Size] value={value:08x}h"
    self.bios_rom_delay_size.value = value

    assert self.bios_rom_delay_size.parts.UNKNOWN_21_23 == 0, "These should be always zero!"

    notice fmt"BIOS ROM Delay/Size set to: value={value:08x}h"
    for x in GetDescription(self.bios_rom_delay_size):
        notice "- " & x
    # TODO: implement side-effects
    warn "BIOS ROM Delay/Size: sideffects are ignored!"


proc SetRamSize32(self: Mc1, value: uint32) =
    trace fmt"write[RAM Size] value={value:08x}h"
    self.ram_size.value = value

    notice fmt"RAM Size set to: value={value:08x}h"
    notice fmt"- Delay simultaneous CODE+DATA fetch: {self.ram_size.parts.delay_fetch_cycles} cycles"
    notice fmt"- 8MB Memory Window: {self.ram_size.parts.memory_window_8mb}"
    # TODO: implemented side-effects
    warn "RAM Size: sideffects are ignored!"


proc SetComDelayCommonDelay32(self: Mc1, value: uint32) =
    trace fmt"write[COM_DELAY] value={value:08x}h"
    self.com_delay.value = value

    notice fmt"COM Delay set to: value={value:08x}h"
    notice fmt"- COM0: {self.com_delay.parts.COM0} cycles"
    notice fmt"- COM1: {self.com_delay.parts.COM1} cycles"
    notice fmt"- COM2: {self.com_delay.parts.COM2} cycles"
    notice fmt"- COM3: {self.com_delay.parts.COM3} cycles"

    warn "COM Delay: sideffects are ignored!"
