# Copyright (c) 2021 kraptor
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat

type Address* = distinct uint32

const
    # memory regions
    KUSEG_START* = Address 0x00000000 # 2GB Size
    KSEG0_START* = Address 0x80000000 # 512MB - cached memory
    KSEG1_START* = Address 0xA0000000 # 512MB - uncached memory
    KSEG2_START* = Address 0xC0000000 # 1GB

    # other constants
    CPU_RESET_ENTRY_POINT* = Address 0xBFC00000

converter u32(value: Address): uint32 = value.uint32

type
    KusegAddress* = distinct range[KUSEG_START.u32 .. KSEG0_START.u32 - 1]
    Kseg0Address* = distinct range[KSEG0_START.u32 .. KSEG1_START.u32 - 1]
    Kseg1Address* = distinct range[KSEG1_START.u32 .. KSEG2_START.u32 - 1]
    Kseg2Address* = distinct range[KSEG2_START.u32 .. 0xFFFF_FFFF.Address.u32]

    SomeAddress = Address|KusegAddress|Kseg0Address|Kseg1Address|Kseg2Address

proc `$`*(self: SomeAddress): string = fmt"{self.uint32:08x}h"
proc `+`*[T: SomeAddress](x, y: T): T = T(x.uint32 + y.uint32)
proc `-`*[T: SomeAddress](x, y: T): T = T(x.uint32 - y.uint32)
proc `<`*[T: SomeAddress](x, y: T): bool = x.uint32 < y.uint32
proc `<=`*[T: SomeAddress](x, y: T): bool = x.uint32 <= y.uint32

proc toKUSEG*(self: Address): KusegAddress = KusegAddress(self and 0x1FFF_FFFF'u32)
# proc toKSEG0*(self: Address): Kseg0Address = Kseg0Address(self and 0x8FFF_FFFF'u32)
# proc toKSEG1*(self: Address): Kseg1Address = Kseg1Address(self and 0xAFFF_FFFF'u32)
# proc toKSEG2*(self: Address): Kseg2Address = Kseg2Address(self and 0xCFFF_FFFF'u32)

proc inKSEG2*(self: Address): bool = self.uint32 >= KSEG2_START

proc `+`*(x: Address, y: uint32): Address = Address(x.uint32 + y)
proc `+=`*(x: var Address, y: SomeInteger) = x = Address(x.u32 + y)

proc is_aligned*(x: SomeAddress): bool = (x.uint32 and 0b11) == 0b00