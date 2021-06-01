# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import strformat

import core/log
import emulator/cpu/cpu
import emulator/platform
import emulator/cpu/instruction
import emulator/cpu/assembler
import emulator/cpu/cop0

import emulator/mmu
import emulator/address

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
        check sizeof(Cop0CauseRegister) == sizeof(uint32)
        

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
        check cpu.stats.cycle_count == 2

    test "ORI":
        cpu.WriteRegisterDebug(21, 1'u32)
        p.RunProgram(@[
            ORI(10, 11, 0xF),
            ORI(20, 21, 0),
        ])

        check cpu.ReadRegisterDebug(10) == 0xF
        check cpu.ReadRegisterDebug(20) == 1
        check cpu.stats.cycle_count == 2

    test "SW":
        cpu.WriteRegisterDebug(10, 0xFFFF_FFFF'u32)
        p.RunProgram(@[
            SW(10, 0, 0) 
        ])
        check ReadDebug[uint32](cpu.mmu, 0.Address) == 0xFFFF_FFFF'u32
        check cpu.stats.instruction_count == 1

    test "NOP":
        p.RunProgram(@[
            NOP
        ])
        check cpu.stats.cycle_count == 1

    test "ADDIU":
        cpu.WriteRegisterDebug(11, 1)
        cpu.WriteRegisterDebug(21, 0xFFFF_FFFF'u32)

        p.RunProgram(@[
            ADDIU(10, 11, 0),
            ADDIU(20, 21, 1), # checks wrap-around
        ])

        check cpu.ReadRegisterDebug(10) == 1
        check cpu.ReadRegisterDebug(20) == 0
        cpu.stats.cycle_count = 2

    test "SLL":
        cpu.WriteRegisterDebug(11, 0b1)
        p.RunProgram(@[
            SLL(10, 11, 1),
            SLL(11, 11, 2),
        ])

        check cpu.ReadRegisterDebug(10) == 0b10
        check cpu.ReadRegisterDebug(11) == 0b100
        check cpu.stats.cycle_count == 2

    test "J":
        let start = cpu.pc

        p.RunProgramToPc(@[
            J(start + 12),     # start    --+ 
            ADDIU( 1, 0, 100), # start+4    | : executed (DS)
            ADDIU(10, 0, 100), # start+8    | : not executed
            ADDIU(11, 0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check cpu.ReadRegisterDebug( 1) == 100
        check cpu.ReadRegisterDebug(10) == 0
        check cpu.ReadRegisterDebug(11) == 100
        check cpu.stats.cycle_count == 3
        check cpu.stats.instruction_count == 3
        

    test "OR":
        cpu.WriteRegisterDebug(11, 1)
        
        p.RunProgram(@[
            OR(10, 10, 11),
            OR(11, 11,  0),
            OR(12,  0,  0),
            OR(13, 11, 11),
        ])

        check cpu.ReadRegisterDebug(10) == 1
        check cpu.ReadRegisterDebug(11) == 1
        check cpu.ReadRegisterDebug(12) == 0
        check cpu.ReadRegisterDebug(13) == 1
        check cpu.stats.cycle_count == 4


    test "MTC0":
        cpu.WriteRegisterDebug(1, 100)

        p.RunProgram(@[
            MTC0(1, SR)
        ])

        check cpu.cop0.ReadRegisterDebug(SR) == 100
        assert cpu.stats.cycle_count == 1


    test "BNE":
        let start = cpu.pc
        cpu.WriteRegisterDebug(1, 100)

        p.RunProgramToPc(@[
            BNE(   0, 1,  +8), # start    --+ : pc at ds + 8 = 12
            ADDIU( 1, 0, 100), # start+4    | : executed (DS)
            ADDIU(10, 0, 100), # start+8    | : not executed
            ADDIU(11, 0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check cpu.ReadRegisterDebug( 1) == 100
        check cpu.ReadRegisterDebug(10) == 0
        check cpu.ReadRegisterDebug(11) == 100
        check cpu.stats.cycle_count == 3
        check cpu.stats.instruction_count == 3