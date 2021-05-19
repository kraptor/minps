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
    OperationProc = proc(cpu: Cpu): Cycles {.gcsafe.}


proc ExecuteNotImplemented(cpu: Cpu): Cycles {.used.} = 
    logIndent:
        trace fmt"{cpu.inst}"
        trace fmt"{cpu.inst.value:032b}"
    NOT_IMPLEMENTED fmt"Opcode not implemented: {cpu.inst.opcode}"


proc ExecuteFunctionNotImplemented(cpu: Cpu): Cycles {.used.} = 
    logIndent:
        trace fmt"{cpu.inst}"
        trace fmt"{cpu.inst.value:032b}"
    NOT_IMPLEMENTED fmt"Function Opcode not implemented: {cpu.inst.function}"


const OPCODES = block:
    var o: array[Opcode.high.ord, OperationProc] 
    for x in o.mitems: x = ExecuteNotImplemented
    o[ord Opcode.LUI]     = Op_LUI
    o[ord Opcode.ORI]     = Op_ORI
    o[ord Opcode.SW ]     = Op_SW
    o[ord Opcode.Special] = Op_Special
    o[ord Opcode.ADDIU]   = Op_ADDIU
    o[ord Opcode.J]       = Op_J
    o # return the array


const FUNCTIONS = block:
    var f: array[Function.high.ord, OperationProc]
    for x in f.mitems: x = ExecuteFunctionNotImplemented
    f[ord Function.SLL] = Op_SLL
    f[ord Function.OR ] = Op_OR
    f # return the array


# Utility functions to support operations
proc BranchWithDelaySlotTo*(cpu: Cpu, target: Address) =
    cpu.inst_is_branch = true
    cpu.pc_next = target


proc Execute*(cpu: Cpu): Cycles =
    # TODO: return number of cycles
    debug fmt"Execute: {cpu.inst.DisasmAsText(cpu)}"
    OPCODES[ord cpu.inst.opcode] cpu


proc Op_Special(cpu: Cpu): Cycles =
    FUNCTIONS[ord cpu.inst.function] cpu


proc Op_LUI(cpu: Cpu): Cycles = 
    let
        rt = cpu.inst.rt
        value = cpu.inst.imm16.zero_extend shl 16

    cpu.WriteRegister(rt, value)
    

proc Op_ORI(cpu: Cpu): Cycles =
    let
        rt = cpu.inst.rt
        rs = cpu.inst.rs
        value = cpu.ReadRegister(rs) or cpu.inst.imm16.zero_extend

    cpu.WriteRegister(rt, value)


proc Op_SW(cpu: Cpu): Cycles =
    let
        base = cpu.ReadRegister(cpu.inst.rs)
        offset = cpu.inst.imm16.sign_extend
        address = Address offset + base
        value = cpu.ReadRegister(cpu.inst.rt)

    if unlikely(not address.is_aligned):
        NOT_IMPLEMENTED fmt"Address is not aligned: {address}"
    
    # TODO: account for write to memory cycles?
    cpu.mmu.Write(address, value)


proc Op_SLL(cpu: Cpu): Cycles =
    let 
        rd = cpu.inst.rd
        rt = cpu.inst.rt
        value = cpu.ReadRegister(rt) shl cpu.inst.shamt

    cpu.WriteRegister(rd, value)


proc Op_ADDIU(cpu: Cpu): Cycles =
    let
        rt = cpu.inst.rt
        rs = cpu.inst.rs
        value = cpu.ReadRegister(rs) + cpu.inst.imm16.sign_extend

    cpu.WriteRegister(rt, value)


proc Op_J(cpu: Cpu): Cycles =
    let target = (cpu.inst.target shl 2) or (0xF000_0000'u32 and cpu.pc)
    cpu.BranchWithDelaySlotTo(target.Address)


proc Op_OR(cpu: Cpu): Cycles = 
    let
        rd = cpu.inst.rd
        rs = cpu.inst.rs
        rt = cpu.inst.rt
        value = cpu.ReadRegister(rs) or cpu.ReadRegister(rt)

    cpu.WriteRegister(rd, value)