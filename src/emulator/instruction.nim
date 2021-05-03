# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat

type
    Opcode* {.pure.} =  enum
        SPECIAL = 0x00, BCONDZ = 0x01, J     = 0x02, JAL   = 0x03, 
        BEQ     = 0x04, BNE    = 0x05, BLEZ  = 0x06, BGTZ  = 0x07, 
        ADDI    = 0x08, ADDIU  = 0x09, SLTI  = 0x0a, SLTIU = 0x0b, 
        ANDI    = 0x0c, ORI    = 0x0d, XORI  = 0x0e, LUI   = 0x0f, 
        COP0    = 0x10, COP1   = 0x11, COP2  = 0x12, COP3  = 0x13, 
        Unk14   = 0x14, Unk15  = 0x15, Unk16 = 0x16, Unk17 = 0x17, 
        Unk18   = 0x18, Unk19  = 0x19, Unk1A = 0x1a, Unk1B = 0x1b, 
        Unk1C   = 0x1c, Unk1D  = 0x1d, Unk1E = 0x1e, Unk1F = 0x1f,
        LB      = 0x20, LH     = 0x21, LWL   = 0x22, LW    = 0x23, 
        LBU     = 0x24, LHU    = 0x25, LWR   = 0x26, Unk27 = 0x27,
        SB      = 0x28, SH     = 0x29, SWL   = 0x2a, SW    = 0x2b, 
        Unk2C   = 0x2c, Unk2D  = 0x2d, SWR   = 0x2e, Unk2F = 0x2f,
        LWC0    = 0x30, LWC1   = 0x31, LWC2  = 0x32, LWC3  = 0x33, 
        Unk34   = 0x34, Unk35  = 0x35, Unk36 = 0x36, Unk37 = 0x37,
        SWC0    = 0x38, SWC1   = 0x39, SWC2  = 0x3a, SWC3  = 0x3b, 
        Unk3C   = 0x3c, Unk3D  = 0x3d, Unk3E = 0x3e, Unk3F = 0x3f

    Function* {.pure.} = enum
        SLL     = 0x00, Unk01  = 0x01, SRL   = 0x02, SRA   = 0x03, 
        SLLV    = 0x04, Unk05  = 0x05, SRLV  = 0x06, SRAV  = 0x07, 
        JR      = 0x08, JALR   = 0x09, Unk0A = 0x0a, Unk0B = 0x0b, 
        Syscall = 0x0c, Break  = 0x0d, Unk0E = 0x0e, Unk0F = 0x0f,
        MFHI    = 0x10, MTHI   = 0x11, MFLO  = 0x12, MTLO  = 0x13, 
        Unk14   = 0x14, Unk15  = 0x15, Unk16 = 0x16, Unk17 = 0x17,
        MULT    = 0x18, MULTU  = 0x19, DIV   = 0x1a, DIVU  = 0x1b, 
        Unk1C   = 0x1c, Unk1D  = 0x1d, Unk1E = 0x1e, Unk1F = 0x1f,
        ADD     = 0x20, ADDU   = 0x21, SUB   = 0x22, SUBU  = 0x23, 
        AND     = 0x24, OR     = 0x25, XOR   = 0x26, NOR   = 0x27,
        Unk28   = 0x28, Unk29  = 0x29, SLT   = 0x2a, SLTU  = 0x2b, 
        Unk2C   = 0x2c, Unk2D  = 0x2d, Unk2E = 0x2e, Unk2F = 0x2f, 
        Unk30   = 0x30, Unk31  = 0x31, Unk32 = 0x32, Unk33 = 0x33, 
        Unk34   = 0x34, Unk35  = 0x35, Unk36 = 0x36, Unk37 = 0x37,
        Unk38   = 0x38, Unk39  = 0x39, Unk3A = 0x3a, Unk3B = 0x3b, 
        Unk3C   = 0x3c, Unk3D  = 0x3d, Unk3E = 0x3e, Unk3F = 0x3f

    Cop0Opcode* {.pure.} = enum
        MFC   = 0b00000
        CFC   = 0b00010
        MTC   = 0b00100
        CTC   = 0b00110
        BC    = 0b01000
        OTHER = 0b10000

    ImmediateInstruction* {.packed.} = object
        imm16  * {.bitsize: 16.}: uint16
        rt     * {.bitsize:  5.}: uint8
        rs     * {.bitsize:  5.}: uint8
        opcode * {.bitsize:  6.}: Opcode

    JumpInstruction* {.packed.} = object
        target * {.bitsize: 26.}: uint32
        opcode * {.bitsize:  6.}: Opcode

    RegisterInstruction* {.packed.} = object
        function * {.bitsize: 6.}: Function
        shamt    * {.bitsize: 5.}: uint8
        rd       * {.bitsize: 5.}: uint8
        rt       * {.bitsize: 5.}: uint8
        rs       * {.bitsize: 5.}: uint8
        opcode   * {.bitsize: 6.}: Opcode

    Instruction* {.union.} = object
        J     *: JumpInstruction
        R     *: RegisterInstruction
        I     *: ImmediateInstruction
        value *: uint32

const INSTRUCTION_SIZE* = sizeof(uint32) div 8

#converter FromU32*(src: uint32): Instruction = result.value = src

# Direct accessors to instruction parts
proc opcode  *(inst: Instruction): Opcode   {.inline.} = inst.I.opcode
proc rs      *(inst: Instruction): uint8    {.inline.} = inst.I.rs
proc rt      *(inst: Instruction): uint8    {.inline.} = inst.I.rt
proc imm16   *(inst: Instruction): uint16   {.inline.} = inst.I.imm16
proc rd      *(inst: Instruction): uint8    {.inline.} = inst.R.rd
proc shamt   *(inst: Instruction): uint8    {.inline.} = inst.R.shamt
proc function*(inst: Instruction): Function {.inline.} = inst.R.function
proc target  *(inst: Instruction): uint32   {.inline.} = inst.J.target

proc `$`*(inst: Instruction): string =
    fmt"Instruction({inst.value:08X}h, Opcode: {inst.opcode})"


proc New*(T: type Instruction, v: uint32): Instruction = 
    Instruction(
        value: v
    )
