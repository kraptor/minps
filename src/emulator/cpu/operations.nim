# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental:"codeReordering".}

import strformat

import ../../core/log
import ../../core/util

import cpu
import cop0
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


proc ExecuteCop0NotImplemented(cpu: Cpu): Cycles {.used.} =
    logIndent:
        trace fmt"{cpu.inst}"
        trace fmt"{cpu.inst.value:032b}"        
    NOT_IMPLEMENTED fmt"Cop0 Opcode not implemented: {cpu.inst.rs.Cop0Opcode}"


proc ExecuteFunctionNotImplemented(cpu: Cpu): Cycles {.used.} = 
    logIndent:
        trace fmt"{cpu.inst}"
        trace fmt"{cpu.inst.value:032b}"
    NOT_IMPLEMENTED fmt"Function Opcode not implemented: {cpu.inst.function}"


const OPCODES = block:
    var o: array[Opcode.high.ord, OperationProc] 
    for x in o.mitems: x = ExecuteNotImplemented
    o[ord Opcode.LUI    ] = Op_LUI
    o[ord Opcode.ORI    ] = Op_ORI
    o[ord Opcode.SW     ] = Op_SW
    o[ord Opcode.Special] = Op_Special
    o[ord Opcode.ADDIU  ] = Op_ADDIU
    o[ord Opcode.J      ] = Op_J
    o[ord Opcode.COP0   ] = Op_COP0
    o[ord Opcode.BNE    ] = Op_BNE
    o[ord Opcode.ADDI   ] = Op_ADDI
    o[ord Opcode.LW     ] = Op_LW
    o # return the array


const FUNCTIONS = block:
    var f: array[Function.high.ord, OperationProc]
    for x in f.mitems: x = ExecuteFunctionNotImplemented
    f[ord Function.SLL ] = Function_SLL
    f[ord Function.OR  ] = Function_OR
    f[ord Function.SLTU] = Function_SLTU
    f[ord Function.ADDU] = Function_ADDU
    f # return the array


const COP0_OPCODES = block:
    var o: array[Cop0Opcode.high.ord, OperationProc]
    for x in o.mitems: x = ExecuteCop0NotImplemented
    o[ord Cop0Opcode.MTC] = Op_MTC0
    o


# Utility functions to support operations
proc BranchWithDelaySlotTo*(cpu: Cpu, target: Address) =
    cpu.inst_is_branch = true
    cpu.pc_next = target
    trace fmt"CPU will branch to: {target} after the delay slot."


proc Execute*(cpu: Cpu): Cycles =
    # TODO: return number of cycles
    
    debug fmt"Execute: {cpu.inst.DisasmAsText(cpu)}"
    logIndent:
        result = OPCODES[ord cpu.inst.opcode] cpu
    


proc Op_Special(cpu: Cpu): Cycles =
    FUNCTIONS[ord cpu.inst.function] cpu


proc Op_COP0(cpu: Cpu): Cycles = 
    COP0_OPCODES[ord cpu.inst.rs.Cop0Opcode] cpu


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

    if unlikely(cpu.cop0.IsolateCacheEnabled):
        # TODO: implement cache in CPU for writes
        warn fmt"Attempt to write with Disable Cache enabled!"
        return

    # TODO: account for write to memory cycles?
    cpu.mmu.Write(address, value)


proc Op_LW(cpu: Cpu): Cycles =
    let
        base = cpu.ReadRegister(cpu.inst.rs)
        offset = cpu.inst.imm16.sign_extend
        address = Address offset + base

    if unlikely(not address.is_aligned):
        NOT_IMPLEMENTED fmt"Address is not aligned: {address}"

    if unlikely(cpu.cop0.IsolateCacheEnabled):
        # TODO: does IsolateCache affect loads??
        NOT_IMPLEMENTED

    let value = cpu.mmu.Read32(address)

    # TODO: LW data loaded into register is delayed 1 instruction
    cpu.WriteRegister(cpu.inst.rt, value)


proc Function_SLL(cpu: Cpu): Cycles =
    let 
        rd = cpu.inst.rd
        rt = cpu.inst.rt
        value = cpu.ReadRegister(rt) shl cpu.inst.shamt

    cpu.WriteRegister(rd, value)


proc Function_SLTU(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        rs_value = cpu.ReadRegister(cpu.inst.rs)
        rt_value = cpu.ReadRegister(cpu.inst.rt)
            
    let value = if rs_value < rt_value: 1'u32  else: 0'u32
    cpu.WriteRegister(rd, value)


proc Function_ADDU(cpu: Cpu): Cycles =
    let 
        rd = cpu.inst.rd
        rs_value = cpu.ReadRegister(cpu.inst.rs)
        rt_value = cpu.ReadRegister(cpu.inst.rt)

    let value = rs_value + rt_value
    cpu.WriteRegister(rd, value)

    NOT_IMPLEMENTED


proc Op_ADDIU(cpu: Cpu): Cycles =
    let
        rt = cpu.inst.rt
        rs = cpu.inst.rs

    let value = cpu.ReadRegister(rs) + cpu.inst.imm16.sign_extend
    cpu.WriteRegister(rt, value)


proc Op_J(cpu: Cpu): Cycles =
    let target = (cpu.inst.target shl 2) or (0xF000_0000'u32 and cpu.pc)
    cpu.BranchWithDelaySlotTo(target.Address)


proc Function_OR(cpu: Cpu): Cycles = 
    let
        rd = cpu.inst.rd
        rs = cpu.inst.rs
        rt = cpu.inst.rt
        value = cpu.ReadRegister(rs) or cpu.ReadRegister(rt)

    cpu.WriteRegister(rd, value)


proc Op_MTC0(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        rt = cpu.inst.rt
        value = cpu.ReadRegister(rt)

    cpu.cop0.WriteRegister(rd, value)


proc Op_BNE(cpu: Cpu): Cycles =
    let
        rs = cpu.inst.rs
        rt = cpu.inst.rt
        offset = (cpu.inst.imm16 shl 2).sign_extend

    if cpu.ReadRegister(rs) != cpu.ReadRegister(rt):
        let address = cpu.pc + offset
        cpu.BranchWithDelaySlotTo(address)


proc Op_ADDI(cpu: Cpu): Cycles =
    let
        rt = cpu.inst.rt
        rs = cpu.inst.rs
        
    try:
        let value = cast[int32](cpu.ReadRegister(rs)) + cast[int32](cpu.inst.imm16.sign_extend)
        cpu.WriteRegister(rt, cast[uint32](value))
    except:
        NOT_IMPLEMENTED "Arithmetic ADD Exception not handled."

