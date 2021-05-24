# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest

import core/log
import emulator/cpu/cpu
import emulator/platform
import emulator/cpu/instruction
import emulator/cpu/assembler
import emulator/cpu/cop0


logChannels ["testing"]


suite "CPU types":

    test "Union sizes":
        check sizeof(Instruction) == sizeof(uint32)
        check sizeof(JumpInstruction) == sizeof(uint32)
        check sizeof(RegisterInstruction) == sizeof(uint32)
        check sizeof(ImmediateInstruction) == sizeof(uint32)

suite "Cop0 types":
    test "Union sizes":
        check sizeof(Cop0RegisterArray) == sizeof(Cop0RegistersParts)
        check sizeof(Cop0SystemStatusRegister) == sizeof(uint32)
        check sizeof(Cop0DCICRegister) == sizeof(uint32)



suite "Instruction execution correctness":
    setup:
        var 
            p = Platform.New()
            cpu = p.cpu

    test "LUI":
        check cpu.ReadRegisterDebug(10) == 0
        check cpu.ReadRegisterDebug(11) == 0
        
        let program = @[
            LUI(10, 0xF'u16),
            LUI(11, 0xFFFF'u16),
        ]

        p.RunProgram(program)
        check cpu.stats.instruction_count == program.len
        check cpu.ReadRegisterDebug(10) == 0xF0000'u32
        check cpu.ReadRegisterDebug(11) == 0xFFFF0000'u32


    test "ORI":
        check cpu.ReadRegisterDebug(10) == 0
        check cpu.ReadRegisterDebug(11) == 0
                
        cpu.WriteRegisterDebug(21, 1'u32)
        p.RunProgram(@[
            ORI(10, 11, 0xF),
            ORI(20, 21, 0),
        ])

        check cpu.ReadRegisterDebug(10) == 0xF
        check cpu.ReadRegisterDebug(20) == 1

    test "SLL":
        check cpu.ReadRegisterDebug(10) == 0
        check cpu.ReadRegisterDebug(11) == 0

        cpu.WriteRegister(11, 0b1)
        p.RunProgram(@[
            SLL(10, 11, 1),
            SLL(11, 11, 2),
        ])

        check cpu.ReadRegisterDebug(10) == 0b10
        check cpu.ReadRegisterDebug(11) == 0b100

    test "ADDIU":
        cpu.WriteRegister(11, 1)
        cpu.WriteRegister(21, 0xFFFF_FFFF'u32)

        p.RunProgram(@[
            ADDIU(10, 11, 0),
            ADDIU(20, 21, 1), # checks wrap-around
        ])

        check cpu.ReadRegisterDebug(10) == 1
        check cpu.ReadRegisterDebug(20) == 0


    test "OR":
        cpu.WriteRegister(11, 1)
        
        p.RunProgram(@[
            OR(10, 10, 11),
            OR(11, 11, 0),
            OR(12, 0, 0),
            OR(13, 11, 11),
        ])

        check cpu.ReadRegisterDebug(10) == 1
        check cpu.ReadRegisterDebug(11) == 1
        check cpu.ReadRegisterDebug(12) == 0
        check cpu.ReadRegisterDebug(13) == 1

