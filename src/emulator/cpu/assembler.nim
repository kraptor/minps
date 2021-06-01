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

proc Bxx(opcode: Opcode, a, b: CpuRegisterIndex, offset: int16): Instruction =
    IType(opcode, a, b, cast[uint16](offset) shr 2)


proc LUI  *(target        : CpuRegisterIndex,  value: uint16): Instruction = IType(Opcode.LUI  , target,      0, value)
proc ORI  *(target, source: CpuRegisterIndex,  value: uint16): Instruction = IType(Opcode.ORI  , target, source, value)
proc ADDIU*(target, source: CpuRegisterIndex,  value: uint16): Instruction = IType(Opcode.ADDIU, target, source, value)
proc SW   *(source,   base: CpuRegisterIndex, offset:  int16): Instruction = IType(Opcode.SW   , source,   base, cast[uint16](offset))
proc LW   *(target,   base: CpuRegisterIndex, offset:  int16): Instruction = IType(Opcode.LW   , target,   base, cast[uint16](offset))
proc ADDI* (target, source: CpuRegisterIndex,  value:  int16): Instruction = IType(Opcode.ADDI , target, source, cast[uint16](value))
proc BEQ*  (a, b: CpuRegisterIndex, offset:  int16): Instruction = Bxx(Opcode.BEQ , a, b, offset)
proc BNE*  (a, b: CpuRegisterIndex, offset:  int16): Instruction = Bxx(Opcode.BNE , a, b, offset)
proc BLEZ* (a   : CpuRegisterIndex, offset:  int16): Instruction = Bxx(Opcode.BLEZ, a, 0, offset)
proc BGTZ* (a   : CpuRegisterIndex, offset:  int16): Instruction = Bxx(Opcode.BGTZ, a, 0, offset)

proc SLL *(target, source: CpuRegisterIndex, amount: 0..0b11111): Instruction = RType(Function.SLL, 0, source, target, amount)
proc OR  *(target, a, b: CpuRegisterIndex): Instruction = RType(Function.OR  , a, b, target, 0)
proc SLTU*(target, a, b: CpuRegisterIndex): Instruction = RType(Function.SLTU, a, b, target, 0)
proc ADDU*(target, a, b: CpuRegisterIndex): Instruction = RType(Function.ADDU, a, b, target, 0)

proc J*(target: uint32) : Instruction = JType(Opcode.J, target shr 2)


proc MTC0*(source: CpuRegisterIndex, target: Cop0RegisterName): Instruction =
    result.R.opcode = Opcode.COP0
    result.R.rs = Cop0Opcode.MTC.ord
    result.R.rt = cast[uint8](source)
    result.R.rd = cast[uint8](target)



