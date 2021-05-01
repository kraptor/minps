# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

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


template Read32*(self: Mmu, address: Address): uint32 = Read[uint32](self, address)
template Read16*(self: Mmu, address: Address): uint16 = Read[uint16](self, address)
template Read8*(self: Mmu, address: Address): uint8 = Read[uint8](self, address)

proc Read*[T: uint32|uint16|uint8](self: Mmu, address: Address): T =

    let ka = address.toKUSEG()

    # if pa < Bios.Start: NOT_IMPLEMENTED

    # if pa >= Bios.Start:
    #     NOT_IMPLEMENTED()


    NOT_IMPLEMENTED()


