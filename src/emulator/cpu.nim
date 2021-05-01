# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../core/[log, util]
import address, mmu, instruction

logChannels ["cpu"]


type
    Cpu* = ref object
        pc: Address
        mmu: Mmu


proc New*(T: type Cpu, mmu: Mmu): Cpu =
    debug "Creating CPU..."
    result = Cpu(
        mmu: mmu
    )
    result.Reset()


proc Reset*(self: Cpu) =
    self.pc = CPU_RESET_ENTRY_POINT
    warn "Reset: CPU State not fully initialized."


proc RunOne*(self: Cpu) =
    trace "RunOne"
    logIndent:
        trace "Fetching instruction at: " & $self.pc
        let instruction = Instruction(self.mmu.Read32(self.pc))
        debug fmt"RunInstruction: {instruction}"
        NOT_IMPLEMENTED "RunInstruction is not implemented"
