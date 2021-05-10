# Copyright (c) 2021 kraptor
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import ../../core/log
import ../address
import ../mmu

import assembler
import instruction
    
logChannels ["cpu"]


type
    Cpu* = ref object
        pc*: Address
        mmu*: Mmu

        inst*: Instruction # holds the current instruction to execute

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


proc RunOne*(self: Cpu) =
    trace $self.pc
    logIndent:
        self.Fetch()
        self.Execute()


proc Fetch(self: Cpu) =
    self.inst = Instruction.New(self.mmu.Read32(self.pc))
    self.pc += INSTRUCTION_SIZE