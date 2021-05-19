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


proc lui*(target: CpuRegisterIndex, immediate: uint16): Instruction =
    result.I.opcode = LUI
    result.I.rt = target.uint8
    result.I.imm16 = immediate


proc ori*(target, source: CpuRegisterIndex, value: uint16): Instruction =
    result.I.opcode = ORI
    result.I.rt = target.uint8
    result.I.rs = source.uint8
    result.I.imm16 = value


proc sll*(target, source: CpuRegisterIndex, amount: 0..0b11111): Instruction =
    result.R.opcode = Special
    result.R.function = SLL
    result.R.rd = target.uint8
    result.R.rt = source.uint8
    result.R.shamt = amount.uint8


proc addiu*(target, source, immediate: uint16): Instruction =
    result.I.opcode = ADDIU
    result.I.rt = target.uint8
    result.I.rs = source.uint8
    result.I.imm16 = immediate


