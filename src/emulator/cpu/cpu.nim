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
    RegisterIndex = 0..31

    Cpu* = ref object
        pc*: Address
        inst*: Instruction # holds the current instruction to execute
        regs*: array[RegisterIndex, uint32]
        mmu*: Mmu

proc WriteRegister*(self: Cpu, r: RegisterIndex, v: uint32) =
    let prev_value = self.regs[r]
    self.regs[r] = v
    self.regs[0] = 0
    trace fmt"write reg[{r}] value={self.regs[r]:08x}h (was={prev_value:08x}h)"


proc ReadRegister*(self: Cpu, r: RegisterIndex): uint32 = 
    trace fmt"read reg[{r}] value={self.regs[r]:08x}h"
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
