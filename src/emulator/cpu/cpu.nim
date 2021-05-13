# Copyright (c) 2021 kraptor
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../../core/log
import ../address
import ../mmu

import assembler
import instruction
    
logChannels ["cpu"]


type
    CpuRegisterIndex* = 0..31

    Cpu* = ref object
        pc*: Address
        inst*: Instruction # holds the current instruction to execute
        regs*: array[CpuRegisterIndex, uint32]
        mmu*: Mmu


proc GetCpuRegisterAlias*(r: CpuRegisterIndex): string =
    const CPU_REGISTER_TO_ALIAS = [
        "zero", "at", "v0", "v1", "a0", "a1", "a2", "a3", 
        "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", 
        "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", 
        "t8", "t9", "k0", "k1", "gp", "sp", "fp", "ra"]
    CPU_REGISTER_TO_ALIAS[r]


proc WriteRegister*(self: Cpu, r: CpuRegisterIndex, v: uint32) =
    let 
        alias = GetCpuRegisterAlias(r)
        prev_value = self.regs[r]
    self.regs[r] = v
    self.regs[0] = 0
    trace fmt"write reg[{alias}] {alias}=${r} value={self.regs[r]:08x}h (was={prev_value:08x}h)"


proc ReadRegister*(self: Cpu, r: CpuRegisterIndex): uint32 = 
    let alias = GetCpuRegisterAlias(r)
    trace fmt"read reg[{alias}] {alias}=${r} value={self.regs[r]:08x}h"
    ReadRegisterDebug(self, r)


proc ReadRegisterDebug*(self: Cpu, r: CpuRegisterIndex): uint32 = 
    self.regs[r]


import operations # NOTE: import here so Cpu type is defined and ready within operations module


proc New*(T: type Cpu, mmu: Mmu): Cpu =
    debug "Creating CPU..."
    result = Cpu(
        mmu: mmu,
        inst: NOP
    )
    result.Reset()


proc Reset*(self: Cpu) =
    self.pc = CPU_RESET_ENTRY_POINT
    self.inst = NOP
    warn "Reset: CPU State not fully initialized."


proc RunNext*(self: Cpu) =
    trace fmt"RunNext[pc={self.pc}]"
    logIndent:
        self.Fetch()
        discard self.Execute() # TODO: don't discard cycles


proc Fetch(self: Cpu) =
    self.inst = Instruction.New(self.mmu.Read32(self.pc))
    self.pc += INSTRUCTION_SIZE
