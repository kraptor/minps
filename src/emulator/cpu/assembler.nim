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
    result.I.rs = rs.uint8
    result.I.rt = rt.uint8
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


proc LUI  *(target        : CpuRegisterIndex,  value: uint16): Instruction = IType(Opcode.LUI  , target,      0, value)
proc ORI  *(target, source: CpuRegisterIndex,  value: uint16): Instruction = IType(Opcode.ORI  , target, source, value)
proc ADDIU*(target, source: CpuRegisterIndex,  value: uint16): Instruction = IType(Opcode.ADDIU, target, source, value)
proc ANDI *(target, source: CpuRegisterIndex,  value: uint16): Instruction = IType(Opcode.ANDI , target, source, value)
proc SW   *(source,   base: CpuRegisterIndex, offset:  int16): Instruction = IType(Opcode.SW   , source,   base, cast[uint16](offset))
proc SH   *(source,   base: CpuRegisterIndex, offset:  int16): Instruction = IType(Opcode.SH   , source,   base, cast[uint16](offset))
proc SB   *(source,   base: CpuRegisterIndex, offset:  int16): Instruction = IType(Opcode.SB   , source,   base, cast[uint16](offset))
proc LW   *(target,   base: CpuRegisterIndex, offset:  int16): Instruction = IType(Opcode.LW   , target,   base, cast[uint16](offset))
proc LH   *(target,   base: CpuRegisterIndex, offset:  int16): Instruction = IType(Opcode.LH   , target,   base, cast[uint16](offset))
proc LB   *(target,   base: CpuRegisterIndex, offset:  int16): Instruction = IType(Opcode.LB   , target,   base, cast[uint16](offset))
proc LBU  *(target,   base: CpuRegisterIndex, offset:  int16): Instruction = IType(Opcode.LBU  , target,   base, cast[uint16](offset))
proc ADDI *(target, source: CpuRegisterIndex,  value:  int16): Instruction = IType(Opcode.ADDI , target, source, cast[uint16](value))
proc SLTI *(target, source: CpuRegisterIndex,  value:  int16): Instruction = IType(Opcode.SLTI , target, source, cast[uint16](value))


proc Bxx(opcode: Opcode, a, b: CpuRegisterIndex, offset: int16): Instruction =
    IType(opcode, a, b, cast[uint16](offset) shr 2)


proc BEQ  *(a, b: CpuRegisterIndex, offset:  int16): Instruction = Bxx(Opcode.BEQ , a, b, offset)
proc BNE  *(a, b: CpuRegisterIndex, offset:  int16): Instruction = Bxx(Opcode.BNE , a, b, offset)
proc BLEZ *(a   : CpuRegisterIndex, offset:  int16): Instruction = Bxx(Opcode.BLEZ, 0, a, offset)
proc BGTZ *(a   : CpuRegisterIndex, offset:  int16): Instruction = Bxx(Opcode.BGTZ, 0, a, offset)

proc SLL *(target, source: CpuRegisterIndex, amount: 0..0b111111): Instruction = RType(Function.SLL, 0, source, target, amount)
proc SRA *(target, source: CpuRegisterIndex, amount: 0..0b111111): Instruction = RType(Function.SRA, 0, source, target, amount)
proc OR  *(target, a, b: CpuRegisterIndex): Instruction = RType(Function.OR  , a, b, target, 0)
proc SLTU*(target, a, b: CpuRegisterIndex): Instruction = RType(Function.SLTU, a, b, target, 0)
proc ADDU*(target, a, b: CpuRegisterIndex): Instruction = RType(Function.ADDU, a, b, target, 0)
proc ADD *(target, a, b: CpuRegisterIndex): Instruction = RType(Function.ADD , a, b, target, 0)
proc AND *(target, a, b: CpuRegisterIndex): Instruction = RType(Function.AND , a, b, target, 0)
proc SUBU*(target, a, b: CpuRegisterIndex): Instruction = RType(Function.SUBU, a, b, target, 0)

proc J   *(target: uint32) : Instruction = JType(Opcode.J  , target shr 2)
proc JR  *(target: CpuRegisterIndex) : Instruction = RType(Function.JR, target, 0, 0, 0)
proc JAL *(target: uint32) : Instruction = JType(Opcode.JAL, target shr 2)
proc JALR*(target, source: CpuRegisterIndex): Instruction = RType(Function.JALR, source, 0, target, 0)


proc BCond(op: BCondZ, rs: CpuRegisterIndex, offset: int16): Instruction =
    result.I.opcode = Opcode.BCONDZ
    result.I.rs = cast[uint8](rs)
    result.I.rt = cast[uint8](op)
    result.I.imm16 = cast[uint16](offset) shr 2


proc BLTZ  *(rs: CpuRegisterIndex, offset: int16): Instruction = BCond(BCondZ.BLTZ  , rs, offset)
proc BGEZ  *(rs: CpuRegisterIndex, offset: int16): Instruction = BCond(BCondZ.BGEZ  , rs, offset)
proc BLTZAL*(rs: CpuRegisterIndex, offset: int16): Instruction = BCond(BCondZ.BLTZAL, rs, offset)
proc BGEZAL*(rs: CpuRegisterIndex, offset: int16): Instruction = BCond(BCondZ.BGEZAL, rs, offset)


proc MTC0*(source: CpuRegisterIndex, target: Cop0RegisterName): Instruction =
    result.R.opcode = Opcode.COP0
    result.R.rs = Cop0Opcode.MTC.ord
    result.R.rt = cast[uint8](source)
    result.R.rd = cast[uint8](target)


proc MFC0*(target: CpuRegisterIndex, source: Cop0RegisterName): Instruction =
    result.R.opcode = Opcode.COP0
    result.R.rs = Cop0Opcode.MFC.ord
    result.R.rt = cast[uint8](target)
    result.R.rd = cast[uint8](source)
