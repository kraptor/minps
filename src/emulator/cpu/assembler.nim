# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import cpu
import instruction

let
    nop* = Instruction.New(0'u32)

type
    Program* = seq[Instruction]


proc I(opcode: Opcode, rt, rs: CpuRegisterIndex, imm16: uint16): Instruction =
    result.I.opcode = opcode
    result.I.rt = rt.uint8
    result.I.rs = rs.uint8
    result.I.imm16 = imm16


proc R(function: Function, rs, rt, rd: CpuRegisterIndex, amount: 0..0b11111): Instruction =
    result.R.opcode = Opcode.Special
    result.R.function = function
    result.R.rs = rs.uint8
    result.R.rt = rt.uint8
    result.R.rd = rd.uint8
    result.R.shamt = amount.uint8


proc LUI*(target: CpuRegisterIndex, imm: uint16): Instruction =
    I(Opcode.LUI, target, 0, imm)


proc ORI*(target, source: CpuRegisterIndex, imm: uint16): Instruction =
    I(Opcode.ORI, target, source, imm)


proc SLL*(target, source: CpuRegisterIndex, amount: 0..0b11111): Instruction =
    R(Function.SLL, 0, source, target, amount)


proc ADDIU*(target, source, imm: uint16): Instruction =
    I(Opcode.ADDIU, target, source, imm)


proc OR*(target, source_a, source_b: CpuRegisterIndex): Instruction =
    R(Function.OR, source_a, source_b, target, 0)
