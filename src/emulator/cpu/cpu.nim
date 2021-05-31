# Copyright (c) 2021 kraptor
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../../core/log
import ../address
import ../mmu

import cop0
import instruction
    
logChannels ["cpu"]


type
    CpuRegisterIndex* = 0..31

    CpuDelayedRegister* = object
        value: uint32
        available_at_cycle: Cycles

    CpuStats* = object
        instruction_count*: int64
        cycle_count: Cycles

    Cpu* = ref object
        regs    *: array[CpuRegisterIndex, uint32]
        pc      *: Address
        pc_next *: Address

        inst           *: Instruction # holds the current instruction to execute
        inst_pc        *: Address  # instruction address of the current excecuting instruction
        inst_in_delay  *: bool # if current instruction is in delay slot
        inst_is_branch *: bool # if current instruction is a branch instruction

        cop0  *: Cop0

        hi*: CpuDelayedRegister
        lo*: CpuDelayedRegister

        stats *: CpuStats
        mmu   *: Mmu


import assembler


proc GetCpuRegisterAlias*(r: CpuRegisterIndex): string {.inline.} =
    const CPU_REGISTER_TO_ALIAS = [
        "zero", "at", "v0", "v1", "a0", "a1", "a2", "a3", 
        "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", 
        "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", 
        "t8", "t9", "k0", "k1", "gp", "sp", "fp_s8", "ra"]
    CPU_REGISTER_TO_ALIAS[r]


proc WriteRegister*(self: Cpu, r: CpuRegisterIndex, v: uint32) =
    let 
        alias = GetCpuRegisterAlias(r)
        prev_value = self.regs[r]

    self.WriteRegisterDebug(r, v)
    trace fmt"write reg[{alias}] {alias}=${r} value={self.regs[r]:08x}h (was={prev_value:08x}h)"


proc ReadRegister*(self: Cpu, r: CpuRegisterIndex): uint32 = 
    let alias = GetCpuRegisterAlias(r)
    trace fmt"read reg[{alias}] {alias}=${r} value={self.regs[r]:08x}h"
    ReadRegisterDebug(self, r)


proc ReadRegisterDebug*(self: Cpu, r: CpuRegisterIndex): uint32 = 
    self.regs[r]

proc WriteRegisterDebug*(self: Cpu, r: CpuRegisterIndex, v: uint32) =
    self.regs[r] = v
    self.regs[0] = 0


proc WriteHiRegister*(cpu: Cpu, value: uint32, cycles: uint64) =
    cpu.hi.value = value
    cpu.hi.available_at_cycle = cpu.stats.cycle_count + cycles


proc WriteLoRegister*(cpu: Cpu, value: uint32, cycles: uint64) =
    cpu.lo.value = value
    cpu.lo.available_at_cycle = cpu.stats.cycle_count + cycles


import operations # NOTE: import here so Cpu type is defined and ready within operations module


proc New*(T: type Cpu, mmu: Mmu): Cpu =
    debug "Creating CPU..."
    result = Cpu(
        mmu: mmu,
        inst: nop
    )
    result.Reset()


proc Reset*(self: Cpu) =
    self.pc = CPU_RESET_ENTRY_POINT
    self.pc_next = CPU_RESET_ENTRY_POINT

    self.regs.reset()
    self.lo.reset()
    self.hi.reset()

    self.inst = nop
    self.inst_pc = CPU_RESET_ENTRY_POINT
    self.inst_is_branch = false
    self.inst_in_delay = false

    self.stats.reset()
    # we always execute a NOP instruction at the beginning
    self.stats.instruction_count = -1 

    self.cop0.Reset()
    warn "Reset: CPU State not fully initialized."


proc AddCycles(self: Cpu, cycles: Cycles) =
    self.stats.cycle_count += cycles


proc RunNext*(self: Cpu) =
    trace fmt"RunNext[pc={self.pc}]"

    self.pc = self.pc_next
    self.pc_next = self.pc + INSTRUCTION_SIZE

    # by executing then fetching, we can easily handle
    # delay slots at the expense of executing an extra
    # instruction after the entry point (a NOP) which
    # it doesn't hurt anyways...

    self.AddCycles self.Execute()
    inc self.stats.instruction_count
    
    self.inst_in_delay = self.inst_is_branch
    self.inst_is_branch = false

    self.Fetch()


proc Fetch(self: Cpu) =
    self.inst = Instruction.New(self.mmu.Read32(self.pc))
    self.inst_pc = self.pc
