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

logChannels ["testing"]


suite "Instruction types":

    test "Union sizes":
        check sizeof(Instruction) == sizeof(uint32)
        check sizeof(JumpInstruction) == sizeof(uint32)
        check sizeof(RegisterInstruction) == sizeof(uint32)
        check sizeof(ImmediateInstruction) == sizeof(uint32)


suite "Instruction execution correctness":
    setup:
        var 
            p = Platform.New()
            cpu = p.cpu

    test "LUI":
        check cpu.ReadRegisterDebug(10) == 0
        check cpu.ReadRegisterDebug(11) == 0
        
        let program = @[
            lui(10, 0xF'u16),
            lui(11, 0xFFFF'u16),
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
            ori(10, 11, 0xF),
            ori(20, 21, 0),
        ])

        check cpu.ReadRegisterDebug(10) == 0xF
        check cpu.ReadRegisterDebug(20) == 1

    test "SLL":
        check cpu.ReadRegisterDebug(10) == 0
        check cpu.ReadRegisterDebug(11) == 0

        cpu.WriteRegister(11, 0b1)
        p.RunProgram(@[
            sll(10, 11, 1),
            sll(11, 11, 2),
        ])

        check cpu.ReadRegisterDebug(10) == 0b10
        check cpu.ReadRegisterDebug(11) == 0b100

    test "ADDIU":
        cpu.WriteRegister(11, 1)
        cpu.WriteRegister(21, 0xFFFF_FFFF'u32)

        p.RunProgram(@[
            addiu(10, 11, 0),
            addiu(20, 21, 1), # checks wrap-around
        ])

        check cpu.ReadRegisterDebug(10) == 1
        check cpu.ReadRegisterDebug(20) == 0