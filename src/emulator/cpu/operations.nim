# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental:"codeReordering".}

import strformat

import ../../core/log
import ../../core/util

import cpu
import instruction

import ../mmu
import ../address

logChannels ["cpu", "ops"]


type
    Cycles = uint64
    OperationProc = proc(self: Cpu): Cycles {.gcsafe.}


proc ExecuteNotImplemented(self: Cpu): Cycles {.used.} = 
    NOT_IMPLEMENTED fmt"Opcode not implemented: {self.inst.opcode}"


proc ExecuteFunctionNotImplemented(self: Cpu): Cycles {.used.} = 
    NOT_IMPLEMENTED fmt"Function Opcode not implemented: {self.inst.function}"


const OPCODES = block:
    var o: array[Opcode.high.ord, OperationProc] 
    for x in o.mitems: x = ExecuteNotImplemented
    o[ord Opcode.LUI] = Op_LUI
    o[ord Opcode.ORI] = Op_ORI
    o[ord Opcode.SW] = Op_SW
    o[ord Opcode.Special] = Op_Special
    o # return the array


const FUNCTIONS = block:
    var f: array[Function.high.ord, OperationProc]
    for x in f.mitems: x = ExecuteFunctionNotImplemented
    f # return the array


proc Execute*(self: Cpu): Cycles =
    # TODO: return number of cycles
    trace fmt"Execute: {self.inst}"
    trace fmt"  {self.inst.value:032b}"
    OPCODES[ord self.inst.opcode] self


proc Op_Special(self: Cpu): Cycles =
    FUNCTIONS[ord self.inst.function] self


proc Op_LUI(self: Cpu): Cycles = 
    self.WriteRegister(
        self.inst.rt, 
        self.inst.imm16.zero_extend shl 16
    )
    

proc Op_ORI(self: Cpu): Cycles =
    self.WriteRegister(
        self.inst.rt,
        self.ReadRegister(self.inst.rs) or self.inst.imm16.zero_extend
    )


proc Op_SW(self: Cpu): Cycles =
    let
        offset = self.inst.imm16.sign_extend
        base = self.ReadRegister(self.inst.rs)
        value = self.ReadRegister(self.inst.rt)
        address = Address offset + base

    if not address.is_aligned:
        NOT_IMPLEMENTED fmt"Address is not aligned: {address}"
        
    self.mmu.Write(address, value)