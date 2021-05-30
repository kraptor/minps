# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental:"codeReordering".}

import ../../core/log
import ../../core/util
import ../mmu
import cpu
import cop0

import strutils
import strformat
import instruction

logChannels ["cpu", "disasm"]


type
    Mnemonic {.pure.} = enum 
        lui, ori, sw, nop, addiu, 
        j, `or`, mtc0, bne, addi, 
        lw, sltu, addu, sh, jal,
        andi, jr, lb, beq, mfc0,
        `and`, sll, add, bgtz, 
        blez, lbu, jalr, bltz,
        bgez, bltzal, bgezal, 
        slti, subu, sra

    InstructionPartType {.pure.}  = enum
        CpuRegister
        ImmediateValue
        MemoryAddress
        Cop0Register
        MemoryAddressIndirect
        Offset
        ShiftAmount

    InstructionPartMode {.pure.}  = enum
        Source
        Target

    InstructionPart = object
        mode: InstructionPartMode
        alias: string
        case kind: InstructionPartType
        of MemoryAddressIndirect:
            base_register: uint32
            offset: int32
        else:
            value: uint32

    MetadataPartKind {.pure.} = enum
        MemoryAssignment32
        MemoryAssignment16
        MemoryAssignment8
        MemoryAddressMetadata

    MetadataPart = object
        case kind: MetadataPartKind
        of MemoryAssignment32:
            assign_target32: uint32
            assign_value32: uint32
        of MemoryAssignment16:
            assign_target16: uint32
            assign_value16: uint16
        of MemoryAssignment8:
            assign_target8: uint32
            assign_value8: uint8
        of MemoryAddressMetadata:
            address: uint32
    
    DisassembledInstruction = object
        mnemonic: Mnemonic
        mnemonic_aliases: seq[Mnemonic]
        parts: seq[InstructionPart]
        metadata: seq[MetadataPart]


proc Disasm*(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    case inst.opcode:
    of Opcode.LUI   : return inst.DisasmRtImmediate(cpu, lui)
    of Opcode.ORI   : return inst.DisasmArithmeticImmediate(cpu, ori)
    of Opcode.SW    : return inst.DisasmSW(cpu)
    of Opcode.ADDIU : return inst.DisasmRtImmediate(cpu, addiu)
    of Opcode.J     : return inst.DisasmJ(cpu)
    of Opcode.COP0  : return inst.DisasmCop0(cpu)
    of Opcode.BNE   : return inst.DisasmBxx(cpu, bne)
    of Opcode.ADDI  : return inst.DisasmArithmeticImmediate(cpu, addi)
    of Opcode.LW    : return inst.DisasmLW(cpu)
    of Opcode.SH    : return inst.DisasmSH(cpu)
    of Opcode.JAL   : return inst.DisasmJAL(cpu)
    of Opcode.ANDI  : return inst.DisasmArithmeticImmediate(cpu, andi)
    of Opcode.SB    : return inst.DisasmSB(cpu)
    of Opcode.LB    : return inst.DisasmLB(cpu)
    of Opcode.BEQ   : return inst.DisasmBxx(cpu, beq)
    of Opcode.BGTZ  : return inst.DisasmBxxZ(cpu, bgtz)
    of Opcode.BLEZ  : return inst.DisasmBxxZ(cpu, blez)
    of Opcode.LBU   : return inst.DisasmLBU(cpu)
    of Opcode.SLTI  : return inst.DisasmArithmeticImmediate(cpu, slti)
    of Opcode.BCONDZ: 
        case inst.rt.BCondZ:
        of BLTZ  : return inst.DisasmBxxZ(cpu, bltz)
        of BGEZ  : return inst.DisasmBxxZ(cpu, bgez)
        of BLTZAL: return inst.DisasmBxxZ(cpu, bltzal)
        of BGEZAL: return inst.DisasmBxxZ(cpu, bgezal)
        else:
            NOT_IMPLEMENTED fmt"Missing disassembly for BcondZ {inst}"
    of Opcode.Special:
        case inst.function:
        of Function.SLL : return inst.DisasmSLL(cpu)
        of Function.OR  : return inst.DisasmSpecialArithmetic(cpu, Mnemonic.`or`)
        of Function.SLTU: return inst.DisasmSpecialArithmetic(cpu, sltu)
        of Function.ADDU: return inst.DisasmSpecialArithmetic(cpu, addu)
        of Function.JR  : return inst.DisasmJR(cpu)
        of Function.AND : return inst.DisasmSpecialArithmetic(cpu, Mnemonic.`and`)
        of Function.ADD : return inst.DisasmSpecialArithmetic(cpu, Mnemonic.add)
        of Function.JALR: return inst.DisasmJALR(cpu)
        of Function.SUBU: return inst.DisasmSpecialArithmetic(cpu, subu)
        of Function.SRA : return inst.DisasmSRA(cpu)
        else:
            NOT_IMPLEMENTED fmt"Missing disassembly for SPECIAL {inst}"
    else: 
        NOT_IMPLEMENTED fmt"Missing disassembly for {inst}"


proc DisasmAsText*(inst: Instruction, cpu: Cpu): string = 
    result = DisasmAsText(Disasm(inst, cpu))
    if cpu.inst_in_delay:
        result = fmt"{result} [IN DELAY SLOT]"


proc DisasmAsText*(di: DisassembledInstruction): string =
    var parts: string
    for p in di.parts:
        parts = parts & " " & $p
    return strip(fmt"{di.mnemonic} {parts.strip} {di.metadata}")


proc `$`*(metadata: seq[MetadataPart]): string =
    if metadata.len > 0:
        for m in metadata:
            case m.kind:
            of MemoryAssignment32:
                result = result & fmt"{m.assign_target32:08x}h={m.assign_value32:08x}h "
            of MemoryAssignment16:
                result = result & fmt"{m.assign_target16:08x}h={m.assign_value16:04x}h "
            of MemoryAssignment8:
                result = result & fmt"{m.assign_target8:08x}h={m.assign_value8:02x}h "
            of MemoryAddressMetadata:
                result = result & fmt"address={m.address:08x}h "
        result = fmt"[{result.strip}]"


proc `$`*(part: InstructionPart): string =
    case part.kind:
    of CpuRegister   : return GetCpuRegisterAlias(part.value)
    of ImmediateValue: return fmt"{part.value:x}h"
    of Offset        : return fmt"{cast[int32](part.value):x}h"
    of MemoryAddress : return fmt"{part.value:x}h"
    of Cop0Register  : return GetCop0RegisterAlias(part.value)
    of MemoryAddressIndirect:
        return fmt"{part.offset:x}h({part.base_register.GetCpuRegisterAlias})"
    of ShiftAmount   : return fmt"{cast[int32](part.value)}"
    NOT_IMPLEMENTED "Disassembly part stringify not implemented for: " & $part.kind


proc DisasmRtImmediate(inst: Instruction, cpu: Cpu, mnemonic: Mnemonic): DisassembledInstruction =
    return DisassembledInstruction(
        mnemonic: mnemonic,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister,    value: inst.rt),
            InstructionPart(mode: Source, kind: ImmediateValue, value: inst.imm16)
        ]
    )


proc DisasmArithmeticImmediate(inst: Instruction, cpu: Cpu, mnemonic: Mnemonic): DisassembledInstruction =
    return DisassembledInstruction(
        mnemonic: mnemonic,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister   , value: inst.rt),
            InstructionPart(mode: Source, kind: CpuRegister   , value: inst.rs),
            InstructionPart(mode: Source, kind: ImmediateValue, value: inst.imm16)
        ]
    )


proc DisasmSpecialArithmetic(inst: Instruction, cpu: Cpu, mnemonic: Mnemonic): DisassembledInstruction =
    return DisassembledInstruction(
        mnemonic: mnemonic,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rd),
            InstructionPart(mode: Source, kind: CpuRegister, value: inst.rs),
            InstructionPart(mode: Source, kind: CpuRegister, value: inst.rt),
        ]
    )


proc DisasmSW(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    let 
        offset = cast[int32](inst.imm16.sign_extend)
        target = inst.imm16.sign_extend + cpu.ReadRegisterDebug(inst.rs)
        value  = cpu.ReadRegisterDebug(inst.rt)
        metadata = @[
            MetadataPart(kind: MemoryAssignment32, assign_target32: target, assign_value32: value)
        ]

    return DisassembledInstruction(
        mnemonic: sw,
        parts: @[
            InstructionPart(mode: Source, kind: CpuRegister, value: inst.rt),
            InstructionPart(mode: Target, kind: MemoryAddressIndirect, base_register: inst.rs, offset: offset)
        ],
        metadata: metadata
    )


proc DisasmSH(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    let 
        offset = cast[int32](inst.imm16.sign_extend)
        target = inst.imm16.sign_extend + cpu.ReadRegisterDebug(inst.rs)
        value  = cast[uint16](cpu.ReadRegisterDebug(inst.rt))
        metadata = @[
            MetadataPart(kind: MemoryAssignment16, assign_target16: target, assign_value16: value)
        ]

    return DisassembledInstruction(
        mnemonic: sh,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rt),
            InstructionPart(mode: Target, kind: MemoryAddressIndirect, base_register: inst.rs, offset: offset)
        ],
        metadata: metadata
    )


proc DisasmSB(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    let 
        offset = cast[int32](inst.imm16.sign_extend)
        target = inst.imm16.sign_extend + cpu.ReadRegisterDebug(inst.rs)
        value  = cast[uint8](cpu.ReadRegisterDebug(inst.rt))
        metadata = @[
            MetadataPart(kind: MemoryAssignment8, assign_target8: target, assign_value8: value)
        ]

    return DisassembledInstruction(
        mnemonic: sh,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rt),
            InstructionPart(mode: Target, kind: MemoryAddressIndirect, base_register: inst.rs, offset: offset)
        ],
        metadata: metadata
    )


proc DisasmLW(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    let
        target = inst.imm16.sign_extend + cpu.ReadRegisterDebug(inst.rs)

    return DisassembledInstruction(
        mnemonic: lw,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rt),
            InstructionPart(mode: Source, kind: MemoryAddressIndirect, base_register: inst.rs, offset: cast[int32](inst.imm16.sign_extend))
        ],
        metadata: @[
            MetadataPart(kind: MemoryAddressMetadata, address: target)
        ]
    )


proc DisasmLB(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    let
        target = inst.imm16.sign_extend + cpu.ReadRegisterDebug(inst.rs)

    return DisassembledInstruction(
        mnemonic: lb,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rt),
            InstructionPart(mode: Source, kind: MemoryAddressIndirect, base_register: inst.rs, offset: cast[int32](inst.imm16.sign_extend))
        ],
        metadata: @[
            MetadataPart(kind: MemoryAddressMetadata, address: target)
        ]
    )


proc DisasmLBU(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    let
        target = inst.imm16.sign_extend + cpu.ReadRegisterDebug(inst.rs)

    return DisassembledInstruction(
        mnemonic: lbu,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rt),
            InstructionPart(mode: Source, kind: MemoryAddressIndirect, base_register: inst.rs, offset: cast[int32](inst.imm16.sign_extend))
        ],
        metadata: @[
            MetadataPart(kind: MemoryAddressMetadata, address: target)
        ]
    )


proc DisasmSLL(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    if inst.value == 0:
        return DisassembledInstruction(
            mnemonic: Mnemonic.nop
        )
    else:
        return DisasmSpecialArithmetic(inst, cpu, sll)


proc DisasmJ(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    let 
        delay_slot_pc = cpu.inst_pc + 4  # can't use next_pc, depends on call-site
        target = (inst.target shl 2) or (0xF000_0000'u32 and delay_slot_pc)
    return DisassembledInstruction(
        mnemonic: Mnemonic.j,
        parts: @[
            InstructionPart(mode: Target, kind: MemoryAddress, value: target)
        ]
    )


proc DisasmJAL(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    let 
        delay_slot_pc = cpu.inst_pc + 4  # can't use next_pc, depends on call-site
        target = (inst.target shl 2) or (0xF000_0000'u32 and delay_slot_pc)
    return DisassembledInstruction(
        mnemonic: Mnemonic.jal,
        parts: @[
            InstructionPart(mode: Target, kind: MemoryAddress, value: target)
        ]
    )


proc DisasmJALR(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    let 
        delay_slot_pc = cpu.inst_pc + 4  # can't use next_pc, depends on call-site
        target = (inst.target shl 2) or (0xF000_0000'u32 and delay_slot_pc)
    return DisassembledInstruction(
        mnemonic: Mnemonic.jalr,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rd),
            InstructionPart(mode: Target, kind: MemoryAddress, value: target)
        ]
    )


proc DisasmJR(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    return DisassembledInstruction(
        mnemonic: Mnemonic.jr,
        parts: @[
            # InstructionPart(mode: Target, kind: MemoryAddress, value: target)
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rs)
        ],
        metadata: @[
            MetadataPart(kind: MemoryAddressMetadata, address: cpu.ReadRegisterDebug(inst.rs))
        ]
    )


proc DisasmCop0(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    case inst.rs.Cop0Opcode:
    of MTC:
        return DisassembledInstruction(
            mnemonic: Mnemonic.mtc0,
            parts: @[
                InstructionPart(mode: Source, kind: CpuRegister, value: inst.rt),
                InstructionPart(mode: Target, kind: Cop0Register, value: inst.rd),
            ]
        )
    of MFC:
        return DisassembledInstruction(
            mnemonic: Mnemonic.mfc0,
            parts: @[
                InstructionPart(mode: Target, kind: CpuRegister, value: inst.rt),
                InstructionPart(mode: Source, kind: Cop0Register, value: inst.rd),
            ]
        )
    else:
        NOT_IMPLEMENTED fmt"Cop0 Disasm not implemented for: {inst.rs.Cop0Opcode}"


proc DisasmBxx(inst: Instruction, cpu: Cpu, mnemonic: Mnemonic): DisassembledInstruction =
    let 
        delay_slot_pc = cpu.inst_pc + 4  # can't use next_pc, depends on call-site
        target = (inst.imm16 shl 2).sign_extend + delay_slot_pc
        metadata = @[
            MetadataPart(kind: MemoryAddressMetadata, address: target)
        ]

    return DisassembledInstruction(
        mnemonic: mnemonic,
        parts: @[
            InstructionPart(mode: Source, kind: CpuRegister, value: inst.rs),
            InstructionPart(mode: Source, kind: CpuRegister, value: inst.rt),
            InstructionPart(mode: Target, kind: Offset, value: (inst.imm16 shl 2).sign_extend)
        ],
        metadata: metadata
    )


proc DisasmBxxZ(inst: Instruction, cpu: Cpu, mnemonic: Mnemonic): DisassembledInstruction =
    let 
        delay_slot_pc = cpu.inst_pc + 4  # can't use next_pc, depends on call-site
        target = (inst.imm16 shl 2).sign_extend + delay_slot_pc
        metadata = @[
            MetadataPart(kind: MemoryAddressMetadata, address: target)
        ]

    return DisassembledInstruction(
        mnemonic: mnemonic,
        parts: @[
            InstructionPart(mode: Source, kind: CpuRegister, value: inst.rs),
            InstructionPart(mode: Target, kind: Offset, value: (inst.imm16 shl 2).sign_extend)
        ],
        metadata: metadata
    )

proc DisasmSRA(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    return DisassembledInstruction(
        mnemonic: sra,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rd),
            InstructionPart(mode: Source, kind: CpuRegister, value: inst.rt),
            InstructionPart(mode: Source, kind: ShiftAmount, value: inst.shamt),
        ]
    )