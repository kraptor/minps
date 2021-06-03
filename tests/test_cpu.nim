# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import strformat

import core/log
import core/util
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

        check:
            cpu.stats.instruction_count == program.len
            cpu.ReadRegisterDebug(10) == 0xF0000'u32
            cpu.ReadRegisterDebug(11) == 0xFFFF0000'u32
            cpu.stats.cycle_count == 2

    test "ORI":
        cpu.WriteRegisterDebug(21, 1'u32)
        p.RunProgram(@[
            ORI(10, 11, 0xF),
            ORI(20, 21, 0),
        ])

        check:
            cpu.ReadRegisterDebug(10) == 0xF
            cpu.ReadRegisterDebug(20) == 1
            cpu.stats.cycle_count == 2

    test "SW":
        cpu.WriteRegisterDebug(10, 0xFFFF_FFFF'u32)
        p.RunProgram(@[
            SW(10, 0, 0) 
        ])

        check:
            ReadDebug[uint32](cpu.mmu, 0.Address) == 0xFFFF_FFFF'u32
            cpu.stats.instruction_count == 1
            cpu.stats.cycle_count == 1

    test "SW - unaligned store":
        expect NotImplementedDefect:
            p.RunProgram(@[
                SW(10, 0, 0b01)
            ])

    test "SH":
        cpu.WriteRegisterDebug(10, 0xFFFF_FFFF'u32)

        p.RunProgram(@[
            SH(10, 0, 0), # aligned % 4 - 32bits
            SH(10, 0, 6)  # aligned % 2 - 16bits
        ])

        check:
            ReadDebug[uint32](cpu.mmu, 0.Address) == 0xFFFF'u32
            ReadDebug[uint16](cpu.mmu, 6.Address) == 0xFFFF'u16
            cpu.stats.instruction_count == 2
            cpu.stats.cycle_count == 2

    test "SH - unaligned store":
        expect NotImplementedDefect:
            p.RunProgram(@[
                SH(10, 0, 0b01)
            ])

    test "SB":
        cpu.WriteRegisterDebug(10, 0xFFFF_FFFF'u32)

        p.RunProgram(@[
            SB(10, 0, 0), # aligned % 4 - 32bits
            SB(10, 0, 6), # aligned % 2 - 16bits
            SB(10, 0, 9), # aligned % 1 - 16bits
        ])

        check:
            ReadDebug[uint8](cpu.mmu, 0.Address) == 0xFF'u32
            ReadDebug[uint8](cpu.mmu, 6.Address) == 0xFF'u16
            ReadDebug[uint8](cpu.mmu, 9.Address) == 0xFF'u16
            cpu.stats.instruction_count == 3
            cpu.stats.cycle_count == 3

    test "LW":
        cpu.mmu.WriteDebug( 0.Address, 0xDEADBEEF'u32)
        cpu.mmu.WriteDebug(16.Address, 0xAABBCCDD'u32)
        cpu.WriteRegisterDebug(1, 16)
        
        p.RunProgram(@[
            LW(10, 0,  0), # read at 0x0
            LW(11, 0, 16), # read at 0x0 + 10
            LW(12, 1,  0), # read at  16 +  0
        ])
        
        check:
            cpu.ReadRegisterDebug(10) == 0xDEADBEEF'u32
            cpu.ReadRegisterDebug(11) == 0xAABBCCDD'u32
            cpu.ReadRegisterDebug(12) == 0xAABBCCDD'u32
            cpu.stats.instruction_count == 3
            cpu.stats.cycle_count == 3

    test "LW - unaligned load":
        expect NotImplementedDefect:
            p.RunProgram(@[
                LW(10, 0, 0b01)
            ])

    test "LH":
        skip()

        # cpu.mmu.WriteDebug( 0.Address, 0xDEADBEEF'u32)
        # cpu.mmu.WriteDebug( 4.Address, 0xAABBCCDD'u32)
        # cpu.WriteRegisterDebug(1, 16)
        
        # p.RunProgram(@[
        #     LH(10, 0, 0), # read at 0x0
        #     LH(11, 0, 6), # read at 0x0 + 6
        # ])
        
        # check:
        #     cpu.ReadRegisterDebug(10) == 0xBEEF'u32
        #     cpu.ReadRegisterDebug(11) == 0xAABB'u32
        #     cpu.stats.instruction_count == 2
        #     cpu.stats.cycle_count == 2

    test "LH - unaligned load":
        skip()

        # expect NotImplementedDefect:
        #     p.RunProgram(@[
        #         LH(10, 0, 0b01)
        #     ])

    test "LB":
        cpu.mmu.WriteDebug( 0.Address, 0xDEADBEEF'u32)
        cpu.mmu.WriteDebug( 4.Address, 0xAABBCCDD'u32)
        cpu.WriteRegisterDebug(1, 16)
        
        p.RunProgram(@[
            LB(10, 0, 0), # read at 0x0
            LB(11, 0, 6), # read at 0x0 + 6
            LB(12, 0, 7), # read at 0x0 + 7
        ])
        
        check:
            cpu.ReadRegisterDebug(10) == 0xFFFF_FFEF'u32
            cpu.ReadRegisterDebug(11) == 0xFFFF_FFBB'u32
            cpu.ReadRegisterDebug(12) == 0xFFFF_FFAA'u32
            cpu.stats.instruction_count == 3
            cpu.stats.cycle_count == 3

    test "LBU":
        cpu.mmu.WriteDebug( 0.Address, 0xDEADBEEF'u32)
        cpu.mmu.WriteDebug( 4.Address, 0xAABBCCDD'u32)
        cpu.WriteRegisterDebug(1, 16)
        
        p.RunProgram(@[
            LBU(10, 0, 0), # read at 0x0
            LBU(11, 0, 6), # read at 0x0 + 6
            LBU(12, 0, 7), # read at 0x0 + 7
        ])
        
        check:
            cpu.ReadRegisterDebug(10) == 0xEF'u32
            cpu.ReadRegisterDebug(11) == 0xBB'u32
            cpu.ReadRegisterDebug(12) == 0xAA'u32
            cpu.stats.instruction_count == 3
            cpu.stats.cycle_count == 3    

    test "NOP":
        p.RunProgram(@[
            NOP
        ])

        check:
            cpu.stats.cycle_count == 1

    test "ADDIU":
        cpu.WriteRegisterDebug(11, 1)
        cpu.WriteRegisterDebug(21, 0xFFFF_FFFF'u32)

        p.RunProgram(@[
            ADDIU(10, 11, 0),
            ADDIU(20, 21, 1), # checks wrap-around
        ])

        check:
            cpu.ReadRegisterDebug(10) == 1
            cpu.ReadRegisterDebug(20) == 0
            cpu.stats.cycle_count == 2

    test "ADDI":
        p.RunProgram(@[
            ADDI( 1, 0, -1), # 0 + (-1) = -1
            ADDI( 2, 0,  1), # 0 + 1 = 1
        ])

        check:
            cast[int32](cpu.ReadRegisterDebug(1)) == -1
            cast[int32](cpu.ReadRegisterDebug(2)) == 1
            cpu.stats.cycle_count == 2

    test "ADDI - overflow":
        cpu.WriteRegisterDebug(10, cast[uint32](int32.high))
        
        # TODO: once implemented check for CPU exception, etc.
        expect NotImplementedDefect:
            p.RunProgram(@[
                ADDI( 1, 10, 1), # high + 1 = overflow exception
            ])

    test "ADDI - underflow":
        cpu.WriteRegisterDebug(10, cast[uint32](int32.low))
        
        # TODO: once implemented check for CPU exception, etc.
        expect NotImplementedDefect:
            p.RunProgram(@[
                ADDI( 1, 10, -1), # low - 1 = underflow exception
            ])

    test "ADD":
        cpu.WriteRegisterDebug(10, cast[uint32](-1))
        cpu.WriteRegisterDebug(11, 1)
        p.RunProgram(@[
            ADD(1, 0, 10), # 0 + (-1) = -1
            ADD(2, 0, 11), # 0 + 1 = 1
        ])

        check:
            cast[int32](cpu.ReadRegisterDebug(1)) == -1
            cast[int32](cpu.ReadRegisterDebug(2)) == 1
            cpu.stats.cycle_count == 2

    test "ADD - overflow":
        cpu.WriteRegisterDebug(10, cast[uint32](int32.high))
        cpu.WriteRegisterDebug(11, 1)
        
        # TODO: once implemented check for CPU exception, etc.
        expect NotImplementedDefect:
            p.RunProgram(@[
                ADD(1, 10, 11), # high + 1 = overflow exception
            ])

    test "ADD - underflow":
        cpu.WriteRegisterDebug(10, cast[uint32](int32.low))
        cpu.WriteRegisterDebug(11, cast[uint32](-1))
        
        # TODO: once implemented check for CPU exception, etc.
        expect NotImplementedDefect:
            p.RunProgram(@[
                ADD( 1, 10, 11), # low - 1 = underflow exception
            ])

    test "ADDU":
        cpu.WriteRegisterDebug(10, 10)
        cpu.WriteRegisterDebug(11, 0xFFFF_FFFF'u32)

        p.RunProgram(@[
            ADDU(1, 10,  0), # $2 = 10
            ADDU(2, 10, 10), # $2 = 20
            ADDU(3, 10, 11), # $2 = 9 -- overflow
        ])

        check:
            cpu.ReadRegisterDebug(1) == 10
            cpu.ReadRegisterDebug(2) == 20
            cpu.ReadRegisterDebug(3) == 9

    test "ANDI":
        cpu.WriteRegisterDebug(1, 0b01)
        
        p.RunProgram(@[
            ANDI(10, 1, 0b01),
            ANDI(11, 0, 0b00),
            ANDI(12, 1, 0b10),
        ])

        check:
            cpu.ReadRegisterDebug(10) == 1
            cpu.ReadRegisterDebug(11) == 0
            cpu.ReadRegisterDebug(12) == 0


    test "AND":
        cpu.WriteRegisterDebug(1, 0b101)
        cpu.WriteRegisterDebug(2, 0b010)
        
        p.RunProgram(@[
            AND(10, 1, 1),
            AND(11, 0, 0),
            AND(12, 1, 2),
        ])

        check:
            cpu.ReadRegisterDebug(10) == 0b101
            cpu.ReadRegisterDebug(11) == 0
            cpu.ReadRegisterDebug(12) == 0
    

    test "SLL":
        cpu.WriteRegisterDebug(11, 0b1)
        p.RunProgram(@[
            SLL(10, 11, 1),
            SLL(11, 11, 2),
        ])

        check:
            cpu.ReadRegisterDebug(10) == 0b10
            cpu.ReadRegisterDebug(11) == 0b100
            cpu.stats.cycle_count == 2

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

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    test "JR":
        let start = cpu.pc

        cpu.WriteRegisterDebug(20, start + 12)

        p.RunProgramToPc(@[
            JR(20),     # start    --+ 
            ADDIU( 1, 0, 100), # start+4    | : executed (DS)
            ADDIU(10, 0, 100), # start+8    | : not executed
            ADDIU(11, 0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    test "JR - unaligned address":
        let start = cpu.pc

        cpu.WriteRegisterDebug(20, start + 1)

        expect NotImplementedDefect:
            p.RunProgram(@[
                JR(20),
            ])        

    test "JAL":
        let start = cpu.pc

        p.RunProgramToPc(@[
            JAL(start + 12),   # start    --+ 
            ADDIU( 1, 0, 100), # start+4    | : executed (DS)
            ADDIU(10, 0, 100), # start+8    | : not executed, but address set in 31
            ADDIU(11, 0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.ReadRegisterDebug(31) == start + 8
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    test "JALR":
        let start = cpu.pc

        cpu.WriteRegisterDebug(2, start + 12)

        p.RunProgramToPc(@[
            JALR(20, 2),       # start    --+ 
            ADDIU( 1, 0, 100), # start+4    | : executed (DS)
            ADDIU(10, 0, 100), # start+8    | : not executed, but address set in 31
            ADDIU(11, 0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.ReadRegisterDebug(20) == start + 8
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    test "OR":
        cpu.WriteRegisterDebug(11, 1)
        
        p.RunProgram(@[
            OR(10, 10, 11),
            OR(11, 11,  0),
            OR(12,  0,  0),
            OR(13, 11, 11),
        ])

        check:
            cpu.ReadRegisterDebug(10) == 1
            cpu.ReadRegisterDebug(11) == 1
            cpu.ReadRegisterDebug(12) == 0
            cpu.ReadRegisterDebug(13) == 1
            cpu.stats.cycle_count == 4

    test "MTC0":
        cpu.WriteRegisterDebug(1, 100)

        p.RunProgram(@[
            MTC0(1, SR)
        ])

        check:
            cpu.cop0.ReadRegisterDebug(SR) == 100
            cpu.stats.cycle_count == 1

    test "MFC0":
        cpu.cop0.WriteRegisterDebug(SR, 100)

        p.RunProgram(@[
            MFC0(1, SR)
        ])

        check:
            cpu.ReadRegisterDebug(1) == 100
            cpu.stats.cycle_count == 1

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

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    test "BEQ":
        let start = cpu.pc
        cpu.WriteRegisterDebug(1, 100)
        cpu.WriteRegisterDebug(2, 100)

        p.RunProgramToPc(@[
            BEQ(   1, 2,  +8), # start    --+ : pc at ds + 8 = 12
            ADDIU( 1, 0, 100), # start+4    | : executed (DS)
            ADDIU(10, 0, 100), # start+8    | : not executed
            ADDIU(11, 0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    
    test "BGTZ":
        let start = cpu.pc
        cpu.WriteRegisterDebug(1, cast[uint32](100'i32))

        p.RunProgramToPc(@[
            BGTZ(  1, +8     ), # start    --+ : pc at ds + 8 = 12
            ADDIU( 1,  0, 100), # start+4    | : executed (DS)
            ADDIU(10,  0, 100), # start+8    | : not executed
            ADDIU(11,  0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    test "BLEZ":
        let start = cpu.pc
        cpu.WriteRegisterDebug(1, cast[uint32](-1'i32))

        p.RunProgramToPc(@[
            BLEZ(  1, +8     ), # start    --+ : pc at ds + 8 = 12
            ADDIU( 1,  0, 100), # start+4    | : executed (DS)
            ADDIU(10,  0, 100), # start+8    | : not executed
            ADDIU(11,  0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    test "SLTU":
        cpu.WriteRegisterDebug(1, 10)
        cpu.WriteRegisterDebug(2, 0)
        cpu.WriteRegisterDebug(3, 20)

        p.RunProgram(@[
            SLTU(10, 0, 0), # 0 <  0 ? --> $10 = 0
            SLTU(11, 0, 1), # 0 < 10 ? --> $11 = 1
            SLTU(12, 1, 0), # 10 < 0 ? --> $12 = 0
            SLTU(13, 1, 3), # 10 < 20? --> $13 = 1
        ])

        check:
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 1
            cpu.ReadRegisterDebug(12) == 0
            cpu.ReadRegisterDebug(13) == 1

    test "BLTZ":
        let start = cpu.pc
        cpu.WriteRegisterDebug(1, cast[uint32](-1'i32))

        p.RunProgramToPc(@[
            BLTZ(  1, +8     ), # start    --+ : pc at ds + 8 = 12
            ADDIU( 1,  0, 100), # start+4    | : executed (DS)
            ADDIU(10,  0, 100), # start+8    | : not executed
            ADDIU(11,  0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.ReadRegisterDebug(31) == 0 # no link
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    test "BGEZ":
        let start = cpu.pc
        cpu.WriteRegisterDebug(1, cast[uint32](1'i32))

        p.RunProgramToPc(@[
            BGEZ(  1, +8     ), # start    --+ : pc at ds + 8 = 12
            ADDIU( 1,  0, 100), # start+4    | : executed (DS)
            ADDIU(10,  0, 100), # start+8    | : not executed
            ADDIU(11,  0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.ReadRegisterDebug(31) == 0 # no link
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    test "BLTZAL":
        let start = cpu.pc
        cpu.WriteRegisterDebug(1, cast[uint32](-1'i32))

        p.RunProgramToPc(@[
            BLTZAL(1, +8     ), # start    --+ : pc at ds + 8 = 12
            ADDIU( 1,  0, 100), # start+4    | : executed (DS)
            ADDIU(10,  0, 100), # start+8    | : not executed, links $31 here
            ADDIU(11,  0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.ReadRegisterDebug(31) == start + 8 # links
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    test "BGEZAL":
        let start = cpu.pc
        cpu.WriteRegisterDebug(1, cast[uint32](1'i32))

        p.RunProgramToPc(@[
            BGEZAL(1, +8     ), # start    --+ : pc at ds + 8 = 12
            ADDIU( 1,  0, 100), # start+4    | : executed (DS)
            ADDIU(10,  0, 100), # start+8    | : not executed, links $31 here
            ADDIU(11,  0, 100), # start+12 <-+ : executed
        ],
            start + 16
        )

        check:
            cpu.ReadRegisterDebug( 1) == 100
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 100
            cpu.ReadRegisterDebug(31) == start + 8 # links
            cpu.stats.cycle_count == 3
            cpu.stats.instruction_count == 3

    test "SLTI":
        skip()

    test "SUBU":
        skip()

    test "SRA":
        skip()

    test "DIV":
        skip()

    test "MFLO":
        skip()

    test "MFHI":
        skip()

