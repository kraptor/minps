# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../core/[log]
import address
import cpu/cpu
import cpu/assembler
import cpu/disassembler
import mmu
import bios/bios

logChannels ["platform"]


type
    Platform* = object
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


proc Reset*(self: var Platform) =
    debug "Platform reset..."
    logIndent:
        Reset self.cpu
        Reset self.mmu
        debug "Platform resetted."


proc RunNext*(self: var Platform) =
    debug fmt"[CPU] {self.cpu.pc}: {self.cpu.inst.DisasmAsText(self.cpu)}"
    logIndent:
        self.cpu.RunNext()


proc Run*(self: var Platform) =
    while true:
        RunNext(self)    


proc RunFor*(self: var Platform, number_of_instructions: int64) =
    let 
        start = self.cpu.stats.instruction_count
        target = start + number_of_instructions

    while self.cpu.stats.instruction_count < target:
        debug fmt"[CPU] {self.cpu.pc}: {self.cpu.inst.DisasmAsText(self.cpu)}"
        logIndent:
            self.cpu.RunNext()


proc RunToPc*(self: var Platform, pc: Address) =
    while self.cpu.pc != pc:
        debug fmt"[CPU] {self.cpu.pc}: {self.cpu.inst.DisasmAsText(self.cpu)}"
        logIndent:
            self.cpu.RunNext()


proc SetProgram*(self: var Platform, program: Program) =
    self.mmu.bios = Bios.FromProgram(program)


proc RunProgram*(self: var Platform, program: Program) =
    self.SetProgram(program)
    self.RunFor(program.len + 1) # pc will point right after the last instruction


proc RunProgramToPc*(self: var Platform, program: Program, pc: Address) =
    self.mmu.bios = Bios.FromProgram(program)
    self.RunToPc(pc)
