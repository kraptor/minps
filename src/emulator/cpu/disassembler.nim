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
    Mnemonic {.pure.} = enum lui, ori, sw, nop, addiu, j, `or`, mtc0

    InstructionType {.pure.}  = enum I, J, R

    InstructionPartType {.pure.}  = enum
        CpuRegister
        ImmediateValue
        MemoryBase
        MemoryOffset
        MemoryAddress
        Cop0Register

    InstructionPartMode {.pure.}  = enum
        Source
        Target

    InstructionPart = object
        mode: InstructionPartMode
        value: uint32
        alias: string
        kind: InstructionPartType

    MetadataPartKind {.pure.} = enum
        metaCpuRegister
        metaMemoryAddress

    MetadataPart = object
        key: uint32
        value: uint32
        kind: MetadataPartKind
    
    DisassembledInstruction = object
        kind: InstructionType
        mnemonic: Mnemonic
        mnemonic_aliases: seq[Mnemonic]
        parts: seq[InstructionPart]
        metadata: seq[MetadataPart]


proc Disasm*(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    case inst.opcode:
    of Opcode.LUI  : return inst.DisasmRtImmediate(cpu, lui)
    of Opcode.ORI  : return inst.DisasmORI(cpu)
    of Opcode.SW   : return inst.DisasmSW(cpu)
    of Opcode.ADDIU: return inst.DisasmRtImmediate(cpu, addiu)
    of Opcode.J    : return inst.DisasmJ(cpu)
    of Opcode.COP0 : return inst.DisasmCop0(cpu)
    of Opcode.Special:
        case inst.function:
        of Function.SLL: return inst.DisasmSLL(cpu)
        of Function.OR : return inst.DisasmOR(cpu)
        else:
            NOT_IMPLEMENTED fmt"Missing disassembly for SPECIAL {inst}"
    else: 
        NOT_IMPLEMENTED fmt"Missing disassembly for {inst}"


proc DisasmAsText*(inst: Instruction, cpu: Cpu): string = 
    result = DisasmAsText(Disasm(inst, cpu))
    if cpu.inst_in_delay:
        result = fmt"{result} [IN DELAY SLOT]"


proc DisasmAsText*(di: DisassembledInstruction): string =
    case di.mnemonic:
    of sw:
        result = fmt"{$di.mnemonic} {di.parts[0]} {di.parts[1]}({di.parts[2]}) [{$di.metadata}]"
        return result
    else:
        var parts: string
        for p in di.parts:
            parts = parts & " " & $p
        return $di.mnemonic & parts


proc `$`*(metadata: seq[MetadataPart]): string =
    for m in metadata:
        case m.kind:
        of metaCpuRegister:
            result = result & fmt"{GetCpuRegisterAlias(m.key)}={m.value:08x}h "
        of metaMemoryAddress:
            result = result & fmt"{m.key:08x}h={m.value:08x}h "
    result = result.strip()

proc `$`*(part: InstructionPart): string =
    case part.kind:
    of CpuRegister   : return GetCpuRegisterAlias(part.value)
    of ImmediateValue: return fmt"{part.value:x}h"
    of MemoryOffset  : return fmt"{part.value:x}h"
    of MemoryBase    : return GetCpuRegisterAlias(part.value)   
    of MemoryAddress : return fmt"{part.value:x}h"
    of Cop0Register  : return GetCop0RegisterAlias(part.value)
    NOT_IMPLEMENTED "Disassembly part stringify not implemented for: " & $part.kind


proc DisasmRtImmediate(inst: Instruction, cpu: Cpu, mnemonic: Mnemonic): DisassembledInstruction =
    return DisassembledInstruction(
        mnemonic: mnemonic,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rt),
            InstructionPart(mode: Source, kind: ImmediateValue, value: inst.imm16)
        ]
    )


proc DisasmORI(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    return DisassembledInstruction(
        mnemonic: Mnemonic.ori,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rt),
            InstructionPart(mode: Source, kind: CpuRegister, value: inst.rs),
            InstructionPart(mode: Source, kind: ImmediateValue, value: inst.imm16)
        ]
    )


proc DisasmSW(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    let 
        target = inst.imm16.sign_extend + cpu.ReadRegisterDebug(inst.rs)
        metadata = @[
            MetadataPart(kind: metaMemoryAddress, key: target, value: cpu.ReadRegisterDebug(inst.rt))
        ]

    return DisassembledInstruction(
        mnemonic: sw,
        parts: @[
            InstructionPart(mode: Source, kind: CpuRegister, value: inst.rt),
            InstructionPart(mode: Target, kind: MemoryBase, value: inst.rs),
            InstructionPart(mode: Target, kind: MemoryOffset, value: inst.imm16),
        ],
        metadata: metadata
    )


proc DisasmSLL(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    if inst.value == 0:
        return DisassembledInstruction(
            mnemonic: Mnemonic.nop
        )
    else:
        NOT_IMPLEMENTED "Standard SLL disassembly is not implemented."


proc DisasmJ(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    let target = (inst.target shl 2) or (0xF000_0000'u32 and cpu.pc)
    return DisassembledInstruction(
        mnemonic: Mnemonic.j,
        parts: @[
            InstructionPart(mode: Target, kind: MemoryAddress, value: target)
        ]
    )


proc DisasmOR(inst: Instruction, cpu: Cpu): DisassembledInstruction =
    return DisassembledInstruction(
        mnemonic: Mnemonic.`or`,
        parts: @[
            InstructionPart(mode: Target, kind: CpuRegister, value: inst.rd),
            InstructionPart(mode: Source, kind: CpuRegister, value: inst.rs),
            InstructionPart(mode: Source, kind: CpuRegister, value: inst.rt),
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
    else:
        NOT_IMPLEMENTED