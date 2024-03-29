# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strutils
import strformat
import bitops

import ../core/[log, util]
import address

logChannels {LogChannel.mc}


const
    MC1_MAX_SIZE = 0x64

    # device regions (in kuseg when possible)
    MC1_START* = (Address 0x1F801000).toKUSEG()
    MC1_END* = KusegAddress MC1_START.uint32 + MC1_MAX_SIZE

    MC3_CACHE_CONTROL_REGISTER_ADDRESS = Address 0xFFFE0130
    MC3_CACHE_CONTROL_REGISTER_ADDRESS_END = Address 0xFFFE0133

type
    MemoryControl* = ref object
        # mc1
        expansion1_base_address: uint32
        expansion2_base_address: uint32
        expansion1_delay_size  : DelaySizeRegister
        expansion3_delay_size  : DelaySizeRegister
        spu_delay_size         : DelaySizeRegister
        cdrom_delay_size       : DelaySizeRegister
        expansion2_delay_size  : DelaySizeRegister
        bios_rom_delay_size    : DelaySizeRegister
        ram_size               : RamSizeRegister
        com_delay              : ComDelayRegister
        # mc3
        cache_control: CacheControlRegister


type
    CacheControlRegisterParts* {.packed.} = object
        UNKNOWN_00_02               {.bitsize: 3.}: uint8
        enable_scratchpad_1         {.bitsize: 1.}: bool
        UNKNOWN_04_05               {.bitsize: 2.}: uint8
        UNKNOWN_06_06               {.bitsize: 1.}: bool # always 0 (false)
        enable_scratchpad_2         {.bitsize: 1.}: bool
        UNKNOWN_08_08               {.bitsize: 1.}: bool
        crash_if_code_cache_enabled {.bitsize: 1.}: bool
        UNKNOWN_10_10               {.bitsize: 1.}: bool # always 0 (false)
        enable_code_cache           {.bitsize: 1.}: bool
        UNKNOWN_12_31               {.bitsize:20.}: uint32

    CacheControlRegister* {.union.} = object
        value: uint32
        parts: CacheControlRegisterParts

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
        UNKNOWN_00_02      {.bitsize: 3.}: uint8
        UNKNOWN_03_03      {.bitsize: 1.}: bool # crashes when zero (see docs)
        UNKNOWN_04_06      {.bitsize: 3.}: uint8
        delay_fetch_cycles {.bitsize: 1.}: uint8
        UNKNOWN_08_08      {.bitsize: 1.}: bool
        memory_window_8mb  {.bitsize: 3.}: MemoryWindow
        UNKNOWN_12_15      {.bitsize: 4.}: uint8
        UNKNOWN_16_31      {.bitsize:16.}: uint16

    RamSizeRegister* {.union.} = object
        value: uint32
        parts: RamSizeRegisterParts

    ComDelayRegisterParts* {.packed.} = object
        COM0          {.bitsize: 4.}: uint8
        COM1          {.bitsize: 4.}: uint8
        COM2          {.bitsize: 4.}: uint8
        COM3          {.bitsize: 4.}: uint8
        UNKNOWN_16_31 {.bitsize:16.}: uint16

    ComDelayRegister* {.union.} = object
        value: uint32
        parts: ComDelayRegisterParts


proc New*(T: type MemoryControl): MemoryControl =
    debug "Creating MemoryControl..."
    result = MemoryControl()
    debug "MemoryControl created!"


proc Reset*(self: MemoryControl) =
    debug "Resetting MemoryControl..."
    # TODO: set maximum cycle delays in all registers
    self.cache_control.value = 0
    warn "MemoryControl Reset not fully implemented. Missing initial values!"
    debug "MemoryControl Resetted."


proc Read8* (self: MemoryControl, address: KusegAddress): uint8  {.inline.} = Read[uint8 ](self, address)
proc Read16*(self: MemoryControl, address: KusegAddress): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: MemoryControl, address: KusegAddress): uint32 {.inline.} = Read[uint32](self, address)

proc Read*[T: uint8|uint16|uint32](self: MemoryControl, address: KusegAddress): T =
    trace fmt"read[{$T}] address={address:08x}h"
    NOT_IMPLEMENTED fmt"MemoryControl Read[{$T}]: address={address}"


proc Write8* (self: MemoryControl, address: KusegAddress, value: uint8 ): uint8  {.inline.} = Write[uint8 ](self, address, value)
proc Write16*(self: MemoryControl, address: KusegAddress, value: uint16): uint16 {.inline.} = Write[uint16](self, address, value)
proc Write32*(self: MemoryControl, address: KusegAddress, value: uint32): uint32 {.inline.} = Write[uint32](self, address, value)

proc Write*[T: uint8|uint16|uint32](self: MemoryControl, address: KusegAddress, value: T) =
    trace fmt"write[{$T}] address={address} value={value:08x}h"

    when T is uint32:
        case address.uint32:
        of 0x1F801000: self.SetExpansion1BaseAddress32 value; return
        of 0x1F801004: self.SetExpansion2BaseAddress32 value; return
        of 0x1F801008: self.SetExpansion1DelaySize32   value; return
        of 0x1F80100C: self.SetExpansion3DelaySize32   value; return
        of 0x1F801010: self.SetBiosRomDelaySize32      value; return
        of 0x1F801014: self.SetSpuDelaySize32          value; return
        of 0x1F801018: self.SetCdRomDelaySize32        value; return
        of 0x1F80101C: self.SetExpansion2DelaySize32   value; return
        of 0x1F801020: self.SetComDelayCommonDelay32   value; return
        of 0x1F801060: self.SetRamSize32               value; return
        else:
            discard
    
    NOT_IMPLEMENTED fmt"MemoryControl Write[{$T}]: address={address} value={value:08x}h"


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


proc SetExpansion1BaseAddress32(self: MemoryControl, value: uint32) =
    trace fmt"write[Expansion 1 Base Address] value={value:08x}h"

    assert value == 0x1F000000, "Unexpected EXP 1 Base Address"

    self.expansion1_base_address = value
    notice fmt"EXPANSION 1 Base Address set to: {value:08x}h"

    # TODO: implement side-effects
    warn "EXPANSION 1 Base Address: sideeffects are ignored!"


proc SetExpansion2BaseAddress32(self: MemoryControl, value: uint32) =
    trace fmt"write[Expansion 2 Base Address] value={value:08x}h"

    assert value == 0x1F802000, "Unexpected EXP 2 Base Address"

    self.expansion2_base_address = value
    notice fmt"EXPANSION 2 Base Address set to: {value:08x}h"

    # TODO: implement side-effects
    warn "EXPANSION 2 Base Address: sideeffects are ignored!"


proc SetExpansion1DelaySize32(self: MemoryControl, value: uint32) =
    SetDelaySizeRegister32("EXPANSION 1 Delay/Size", self.expansion1_delay_size, value)


proc SetBiosRomDelaySize32(self: MemoryControl, value: uint32) =
    SetDelaySizeRegister32("BIOS ROM Delay/Size", self.bios_rom_delay_size, value)


proc SetSpuDelaySize32(self: MemoryControl, value: uint32) =
    SetDelaySizeRegister32("SPU Delay/Size", self.spu_delay_size, value)


proc SetCdRomDelaySize32(self: MemoryControl, value: uint32) =
    SetDelaySizeRegister32("CDROM Delay/Size", self.cdrom_delay_size, value)


proc SetExpansion3DelaySize32(self: MemoryControl, value: uint32) =
    SetDelaySizeRegister32("EXPANSION 3 Delay/Size", self.expansion3_delay_size, value)


proc SetExpansion2DelaySize32(self: MemoryControl, value: uint32) =
    SetDelaySizeRegister32("EXPANSION 2 Delay/Size", self.expansion2_delay_size, value)


proc SetDelaySizeRegister32(name: static string, reg: var DelaySizeRegister, value: uint32) =
    trace fmt"write[{name}] value={value:08x}h"

    # SET_MASK cares about UNKNOWN_21_23 should be always zero
    const SET_MASK = bitnot(0b111'u32 shl 21)
    reg.value = value and SET_MASK 

    notice fmt"{name} set to: {value:08x}h"
    for x in GetDescription(reg):
        notice "- " & x

    # TODO: implement side-effects
    warn fmt"{name}: sideffects are ignored!"


proc SetRamSize32(self: MemoryControl, value: uint32) =
    trace fmt"write[RAM Size] value={value:08x}h"
    self.ram_size.value = value

    notice fmt"RAM Size set to: {value:08x}h"
    notice fmt"- Delay simultaneous CODE+DATA fetch: {self.ram_size.parts.delay_fetch_cycles} cycles"
    notice fmt"- 8MB Memory Window: {self.ram_size.parts.memory_window_8mb}"
    
    # TODO: implemented side-effects
    warn "RAM Size: sideffects are ignored!"


proc SetComDelayCommonDelay32(self: MemoryControl, value: uint32) =
    trace fmt"write[COM DELAY] value={value:08x}h"
    
    const SET_MASK = 0x0000FFFF # UNKNOWN_16_31 always zero
    self.com_delay.value = value and SET_MASK

    notice fmt"COM Delay set to: {value:08x}h"
    notice fmt"- COM0: {self.com_delay.parts.COM0} cycles"
    notice fmt"- COM1: {self.com_delay.parts.COM1} cycles"
    notice fmt"- COM2: {self.com_delay.parts.COM2} cycles"
    notice fmt"- COM3: {self.com_delay.parts.COM3} cycles"

    # TODO: implement side-effects
    warn "COM Delay: sideffects are ignored!"


proc ReadMc3*[T: uint8|uint16|uint32](self: MemoryControl, address: Address): T =
    case address:
    of MC3_CACHE_CONTROL_REGISTER_ADDRESS..MC3_CACHE_CONTROL_REGISTER_ADDRESS_END:
        return GetCacheControl[T](self, address)
    else:
        NOT_IMPLEMENTED fmt"MemoryControl MC3 Read: No device found at KSEG2 address: {address}"


proc WriteMc3*[T: uint8|uint16|uint32](self: MemoryControl, address: Address, value: T) =
    case address:
        of MC3_CACHE_CONTROL_REGISTER_ADDRESS..MC3_CACHE_CONTROL_REGISTER_ADDRESS_END:
            SetCacheControl[T](self, address, value)
        else:
            NOT_IMPLEMENTED fmt"MemoryControl MC3 Write: No device found at KSEG2 address: {address}"


proc SetCacheControl[T: uint32|uint16|uint8](self: MemoryControl, address: Address, value: T) =
    trace fmt"write[{$T}][Cache Control] value={value:08x}h"

    when T is uint32:
        self.cache_control.value = value
        notice fmt"Cache Control set to: {value:08x}h"

    when T is uint16:
        NOT_IMPLEMENTED fmt"Set Cache Control is not implemented for {$T}"

    when T is uint8:
        NOT_IMPLEMENTED fmt"Set Cache Control is not implemented for {$T}"
    
    notice fmt"- Enable ScratchPad 1        : {self.cache_control.parts.enable_scratchpad_1}"
    notice fmt"- Enable ScratchPad 2        : {self.cache_control.parts.enable_scratchpad_2}"
    notice fmt"- Crash if code cache enabled: {self.cache_control.parts.crash_if_code_cache_enabled}"
    notice fmt"- Enable Code Cache          : {self.cache_control.parts.enable_code_cache}"
    
    # TODO: implemented side-effects
    warn "Cache Control: sideffects are ignored!"
    

proc GetCacheControl[T: uint32|uint16|uint8](self: MemoryControl, address: Address): T =
    trace fmt"read[{$T}][Cache Control]"
    NOT_IMPLEMENTED fmt"Get Cache Control is not implemented for {$T}"