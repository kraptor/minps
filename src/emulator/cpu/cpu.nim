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
        value    *: uint32 # value of the register, once timestamp + cycles is reached
        cycles   *: Cycles # how many cycles to wait until available
        timestamp*: Cycles # when the write happened to the register

    CpuPendingLoadRegister* = object
        value *: uint32
        cpu_register*: CpuRegisterIndex        

    CpuStats* = object
        instruction_count*: int64
        cycle_count*: Cycles

    Cpu* = ref object
        regs    *: array[CpuRegisterIndex, uint32]
        pc      *: Address
        pc_next *: Address

        inst           *: Instruction # holds the current instruction to execute
        inst_pc        *: Address  # instruction address of the current excecuting instruction
        inst_in_delay  *: bool # if current instruction is in delay slot
        inst_is_branch *: bool # if current instruction is a branch instruction

        pending_load   *: CpuPendingLoadRegister

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


proc WriteHiRegister*(cpu: Cpu, value: uint32, cycles: int64) =
    cpu.hi.value = value
    cpu.hi.cycles = cycles
    cpu.hi.timestamp = cpu.stats.cycle_count


proc WriteLoRegister*(cpu: Cpu, value: uint32, cycles: int64) =
    cpu.lo.value = value
    cpu.lo.cycles = cycles
    cpu.lo.timestamp = cpu.stats.cycle_count


proc ReadHiRegister*(cpu: Cpu): tuple[value: uint32, cycles: Cycles] =
    let 
        target = cpu.hi.cycles + cpu.hi.timestamp
        now = cpu.stats.cycle_count
        cycles = if now >= target: 0'i64 else: target - now
    return (cpu.hi.value, cycles)


proc ReadLoRegister*(cpu: Cpu): tuple[value: uint32, cycles: Cycles] =
    let 
        target = cpu.lo.cycles + cpu.lo.timestamp
        now = cpu.stats.cycle_count
        cycles = if now >= target: 0'i64 else: target - now
    return (cpu.lo.value, cycles)


proc BeginLoad*(cpu: Cpu, register: CpuRegisterIndex, value: uint32) =
    cpu.pending_load.value = value
    cpu.pending_load.cpu_register = register

proc EndLoad*(cpu: Cpu) =
    cpu.WriteRegister(cpu.pending_load.cpu_register, cpu.pending_load.value)
    cpu.pending_load.reset()


import operations # NOTE: import here so Cpu type is defined and ready within operations module


proc New*(T: type Cpu, mmu: Mmu): Cpu =
    debug "Creating CPU..."
    result = Cpu(mmu: mmu)
    result.Reset()


proc Reset*(self: Cpu) =
    self.pc = CPU_RESET_ENTRY_POINT
    self.pc_next = CPU_RESET_ENTRY_POINT

    self.regs.reset()
    self.lo.reset()
    self.hi.reset()

    self.inst = NOP
    self.inst_pc = CPU_RESET_ENTRY_POINT
    self.inst_is_branch = false
    self.inst_in_delay = false

    self.stats.reset()
    # we always execute a NOP instruction at the beginning
    self.stats.instruction_count = -1 
    self.stats.cycle_count = -1

    self.cop0.Reset()
    warn "Reset: CPU State not fully initialized."


proc AddCycles(self: Cpu, cycles: Cycles) =
    self.stats.cycle_count += cycles


proc RunNext*(self: Cpu) =
    trace fmt"RunNext[pc={self.pc}]"

    self.pc = self.pc_next
    self.pc_next = self.pc + INSTRUCTION_SIZE

    # finalize pending delayed loads
    self.EndLoad()

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
