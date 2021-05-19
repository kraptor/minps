# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import ../core/[log]
import cpu/cpu
import cpu/assembler
import mmu
import bios

logChannels ["platform"]


type
    Platform* = ref object
        cpu*: Cpu
        mmu*: Mmu


proc New*(T: type Platform, bios: Bios = nil): Platform =
    debug "Creating Platform..."
    logIndent:
        var bios = if bios != nil: bios else: Bios.New()
        var mmu = Mmu.New(bios)
        result = Platform(
            cpu: Cpu.New(mmu),
            mmu: mmu
        )


proc Reset*(self: Platform) =
    debug "Platform reset..."
    logIndent:
        self.cpu.Reset()
        self.mmu.Reset()
        debug "Platform resetted."


proc Run*(self: Platform) =
    while true:
        self.cpu.RunNext()


proc RunFor*(self: Platform, number_of_instructions: int64) =
    while self.cpu.stats.instruction_count < number_of_instructions:
        self.cpu.RunNext()


proc RunProgram*(self: Platform, program: Program) =
    self.Reset()
    self.mmu.bios = Bios.FromProgram(program)
    self.RunFor(program.len)    
