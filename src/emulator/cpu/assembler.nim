# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import instruction
import cpu
import cop0

let
    NOP* = Instruction.New(0'u32)

type
    Program* = seq[Instruction]


proc IType(opcode: Opcode, rt, rs: CpuRegisterIndex, imm16: uint16): Instruction =
    result.I.opcode = opcode
    result.I.rt = rt.uint8
    result.I.rs = rs.uint8
    result.I.imm16 = imm16


proc RType(function: Function, rs, rt, rd: CpuRegisterIndex, amount: 0..0b11111): Instruction =
    result.R.opcode = Opcode.Special
    result.R.function = function
    result.R.rs = rs.uint8
    result.R.rt = rt.uint8
    result.R.rd = rd.uint8
    result.R.shamt = amount.uint8


proc JType(opcode: Opcode, target_26: uint32): Instruction =
    result.J.opcode = opcode
    result.J.target = target_26


proc LUI*(target: CpuRegisterIndex, imm: uint16): Instruction = 
    IType(Opcode.LUI, target, 0, imm)


proc ORI*(target, source: CpuRegisterIndex, imm: uint16): Instruction =
    IType(Opcode.ORI, target, source, imm)


proc SLL*(target, source: CpuRegisterIndex, amount: 0..0b11111): Instruction =
    RType(Function.SLL, 0, source, target, amount)


proc ADDIU*(target, source, imm: uint16): Instruction =
    IType(Opcode.ADDIU, target, source, imm)


proc OR*(target, source_a, source_b: CpuRegisterIndex): Instruction =
    RType(Function.OR, source_a, source_b, target, 0)


proc SW*(source, base: CpuRegisterIndex, offset: uint16) : Instruction =
    IType(Opcode.SW, source, base, offset)

proc J*(target: uint32) : Instruction =
    JType(Opcode.J, target shr 2)
    
proc MTC0*(source: CpuRegisterIndex, target: Cop0RegisterName): Instruction =
    result.R.opcode = Opcode.COP0
    result.R.rs = Cop0Opcode.MTC.ord
    result.R.rt = cast[uint8](source)
    result.R.rd = cast[uint8](target)
    