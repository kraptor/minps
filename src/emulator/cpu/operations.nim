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
import disassembler

import ../mmu
import ../address

logChannels ["cpu", "ops"]


type
    Cycles = uint64
    OperationProc = proc(self: Cpu): Cycles {.gcsafe.}


proc ExecuteNotImplemented(self: Cpu): Cycles {.used.} = 
    logIndent:
        trace fmt"{self.inst}"
        trace fmt"{self.inst.value:032b}"
    NOT_IMPLEMENTED fmt"Opcode not implemented: {self.inst.opcode}"


proc ExecuteFunctionNotImplemented(self: Cpu): Cycles {.used.} = 
    logIndent:
        trace fmt"{self.inst}"
        trace fmt"{self.inst.value:032b}"
    NOT_IMPLEMENTED fmt"Function Opcode not implemented: {self.inst.function}"


const OPCODES = block:
    var o: array[Opcode.high.ord, OperationProc] 
    for x in o.mitems: x = ExecuteNotImplemented
    o[ord Opcode.LUI] = Op_LUI
    o[ord Opcode.ORI] = Op_ORI
    o[ord Opcode.SW ] = Op_SW
    o[ord Opcode.Special] = Op_Special
    o[ord Opcode.ADDIU] = Op_ADDIU
    o # return the array


const FUNCTIONS = block:
    var f: array[Function.high.ord, OperationProc]
    for x in f.mitems: x = ExecuteFunctionNotImplemented
    f[ord Function.SLL] = Op_SLL
    f # return the array


proc Execute*(self: Cpu): Cycles =
    # TODO: return number of cycles
    debug fmt"Execute: {self.inst.DisasmAsText(self)}"
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
    
    # TODO: account for write to memory cycles?
    self.mmu.Write(address, value)


proc Op_SLL(self: Cpu): Cycles =
    self.WriteRegister(
        self.inst.rd,
        self.ReadRegister(self.inst.rt) shl self.inst.shamt
    )


proc Op_ADDIU(self: Cpu): Cycles =
    self.WriteRegister(
        self.inst.rt,
        self.ReadRegister(self.inst.rs) + self.inst.imm16.sign_extend
    )