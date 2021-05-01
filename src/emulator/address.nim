# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat

type Address* = uint32

const
    # memory regions
    KUSEG_START* = Address 0x00000000 # 2GB Size
    KSEG0_START* = Address 0x80000000 # 512MB - cached memory
    KSEG1_START* = Address 0xA0000000 # 512MB - uncached memory
    KSEG2_START* = Address 0xC0000000 # 1GB

    # other constants
    CPU_RESET_ENTRY_POINT* = Address 0xBFC00000

type
    KusegAddress* = range[KUSEG_START .. KSEG0_START - 1]
    Kseg0Address* = range[KSEG0_START .. KSEG1_START - 1]
    Kseg1Address* = range[KSEG1_START .. KSEG2_START - 1]
    Kseg2Address* = range[KSEG2_START .. Address 0xFFFF_FFFF]

#     DeviceAddress* = distinct DeviceAddress

# proc value(self: Address): uint32 = cast[uint32](self)
proc `$`*(self: Address): string = fmt"{cast[uint32](self):08x}h"
proc `$`*(self: KusegAddress): string = fmt"{cast[uint32](self):08x}h (KUSEG)"
proc `$`*(self: Kseg0Address): string = fmt"{cast[uint32](self):08x}h (KSEG0)"
proc `$`*(self: Kseg1Address): string = fmt"{cast[uint32](self):08x}h (KSEG1)"
proc `$`*(self: Kseg2Address): string = fmt"{cast[uint32](self):08x}h (KSEG2)"

proc toKUSEG*(self: Address): KusegAddress = KusegAddress(self and 0x1FFFFFFF)
proc toKSEG0*(self: Address): Kseg0Address = Kseg0Address(self and 0x8FFFFFFF'u32)
proc toKSEG1*(self: Address): Kseg1Address = Kseg1Address(self and 0xAFFFFFFF'u32)
proc toKSEG2*(self: Address): Kseg2Address = Kseg2Address(self and 0xCFFFFFFF'u32)


