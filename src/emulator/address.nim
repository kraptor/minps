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

proc u32*(value: Address): uint32 = cast[uint32](value)
proc `+`*(x: Address, y: uint32): Address = cast[Address](x.u32 + y)
proc `+=`*(x: var Address, y: SomeInteger) = x = cast[Address](x.u32 + y)

type
    KusegAddress* = distinct range[KUSEG_START.u32 .. KSEG0_START.u32 - 1]
    Kseg0Address* = distinct range[KSEG0_START.u32 .. KSEG1_START.u32 - 1]
    Kseg1Address* = distinct range[KSEG1_START.u32 .. KSEG2_START.u32 - 1]
    Kseg2Address* = distinct range[KSEG2_START.u32 .. 0xFFFF_FFFF'u32]

    SomeAddress = Address|KusegAddress|Kseg0Address|Kseg1Address|Kseg2Address

proc u32*(value: SomeAddress): uint32 = cast[uint32](value)
proc u32*(value: uint32): uint32 = value
proc `$` *(self: SomeAddress): string = fmt"{self.u32:08x}h"
proc `+` *[T: SomeAddress](x, y: T): T         = cast[T](x.u32 + y.u32)
proc `-` *[T: SomeAddress](x, y: T): T         = cast[T](x.u32 - y.u32)
proc `-` *[T: SomeAddress](x: T, y: uint32): T = cast[T](x.u32 - y.u32)
proc `<` *[T: SomeAddress](x, y: T): bool      = x.u32 <  y.u32
proc `<=`*[T: SomeAddress](x, y: T): bool      = x.u32 <= y.u32
proc `==`*[T: SomeAddress](x, y: T): bool      = x.u32 == y.u32

proc toKUSEG*(self: Address): KusegAddress = KusegAddress(self.u32 and 0x1FFF_FFFF'u32)
# proc toKSEG0*(self: Address): Kseg0Address = Kseg0Address(self.u32 and 0x8FFF_FFFF'u32)
# proc toKSEG1*(self: Address): Kseg1Address = Kseg1Address(self.u32 and 0xAFFF_FFFF'u32)
# proc toKSEG2*(self: Address): Kseg2Address = Kseg2Address(self.u32 and 0xCFFF_FFFF'u32)
proc inKSEG2*(self: Address): bool = self >= KSEG2_START


proc is_aligned*[T: uint32|uint16|uint8](x: uint32): bool =
    when T is uint8:
        result = true
    when T is uint16:
        result = (x and 0b1) == 0b0
    when T is uint32:
        result = (x and 0b11) == 0b00


proc is_aligned*[T: uint32|uint16|uint8](x: Address     ): bool = is_aligned[T](x.u32)
proc is_aligned*[T: uint32|uint16|uint8](x: KusegAddress): bool = is_aligned[T](x.u32)
proc is_aligned*[T: uint32|uint16|uint8](x: Kseg0Address): bool = is_aligned[T](x.u32)
proc is_aligned*[T: uint32|uint16|uint8](x: Kseg1Address): bool = is_aligned[T](x.u32)
proc is_aligned*[T: uint32|uint16|uint8](x: Kseg2Address): bool = is_aligned[T](x.u32)