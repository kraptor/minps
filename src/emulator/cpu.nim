# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../core/[log, util]
import address, mmu, instruction, assembler

logChannels ["cpu"]


type
    Cpu* = ref object
        pc: Address
        mmu: Mmu

        instruction: Instruction


proc New*(T: type Cpu, mmu: Mmu): Cpu =
    debug "Creating CPU..."
    result = Cpu(
        mmu: mmu,
        instruction: NOP
    )
    result.Reset()


proc Reset*(self: Cpu) =
    self.pc = CPU_RESET_ENTRY_POINT
    self.instruction = NOP
    warn "Reset: CPU State not fully initialized."


proc RunOne*(self: Cpu) =
    trace $self.pc
    logIndent:
        self.Fetch()
        self.Execute()
        NOT_IMPLEMENTED "RunInstruction is not implemented"


proc Fetch(self: Cpu) =
    self.instruction = Instruction.New(self.mmu.Read32(self.pc))
    debug fmt"{self.instruction}"
    debug $self.instruction.opcode


proc Execute(self: Cpu) =
    case self.instruction.opcode:
    of LUI:
        NOT_IMPLEMENTED "Missing LUI implementation"
    else:
        NOT_IMPLEMENTED

