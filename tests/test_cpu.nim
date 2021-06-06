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
            NOP,
            LW(11, 0, 16), # read at 0x0 + 10
            NOP,
            LW(12, 1,  0), # read at  16 +  0
            NOP,
            LW(13, 0, 0 ), # read at 0x0 but not store the result (load delay)
        ])
        
        check:
            cpu.ReadRegisterDebug(10) == 0xDEADBEEF'u32
            cpu.ReadRegisterDebug(11) == 0xAABBCCDD'u32
            cpu.ReadRegisterDebug(12) == 0xAABBCCDD'u32
            cpu.ReadRegisterDebug(13) == 0 # load delay didnt' store the data yet
            cpu.stats.instruction_count == 7
            cpu.stats.cycle_count == 7

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
        #     NOP,
        #     LH(11, 0, 6), # read at 0x0 + 6
        #     NOP,
        #     LH(13, 0, 0), # read at 0x0
        # ])
        
        # check:
        #     cpu.ReadRegisterDebug(10) == 0xBEEF'u32
        #     cpu.ReadRegisterDebug(11) == 0xAABB'u32
        #     cpu.ReadRegisterDebug(13) == 0
        #     cpu.stats.instruction_count == 5
        #     cpu.stats.cycle_count == 5

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
            NOP,
            LB(11, 0, 6), # read at 0x0 + 6
            NOP,
            LB(12, 0, 7), # read at 0x0 + 7
            NOP,
            LB(13, 0, 0), # test load delay
        ])
        
        check:
            cpu.ReadRegisterDebug(10) == 0xFFFF_FFEF'u32
            cpu.ReadRegisterDebug(11) == 0xFFFF_FFBB'u32
            cpu.ReadRegisterDebug(12) == 0xFFFF_FFAA'u32
            cpu.ReadRegisterDebug(13) == 0
            cpu.stats.instruction_count == 7
            cpu.stats.cycle_count == 7

    test "LBU":
        cpu.mmu.WriteDebug( 0.Address, 0xDEADBEEF'u32)
        cpu.mmu.WriteDebug( 4.Address, 0xAABBCCDD'u32)
        cpu.WriteRegisterDebug(1, 16)
        
        p.RunProgram(@[
            LBU(10, 0, 0), # read at 0x0
            NOP,
            LBU(11, 0, 6), # read at 0x0 + 6
            NOP,
            LBU(12, 0, 7), # read at 0x0 + 7
            NOP,
            LBU(13, 0, 0), # test load delay
        ])
        
        check:
            cpu.ReadRegisterDebug(10) == 0xEF'u32
            cpu.ReadRegisterDebug(11) == 0xBB'u32
            cpu.ReadRegisterDebug(12) == 0xAA'u32
            cpu.ReadRegisterDebug(13) == 0
            cpu.stats.instruction_count == 7
            cpu.stats.cycle_count == 7

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

    test "SLT":
        cpu.WriteRegisterDebug(1, 10)
        cpu.WriteRegisterDebug(2, 0)
        cpu.WriteRegisterDebug(3, cast[uint32](-1))
        cpu.WriteRegisterDebug(4, cast[uint32](-2))

        p.RunProgram(@[
            SLT(10, 0, 0), # 0 <  0 ? --> false
            SLT(11, 0, 1), # 0 < 10 ? --> true
            SLT(12, 1, 0), # 10 < 0 ? --> false
            SLT(13, 1, 3), # 10 < -1? --> false
            SLT(14, 4, 3), # -2 < -1? --> true
            SLT(15, 3, 4), # -1 < -2? --> false
        ])

        check:
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 1
            cpu.ReadRegisterDebug(12) == 0
            cpu.ReadRegisterDebug(13) == 0
            cpu.ReadRegisterDebug(14) == 1
            cpu.ReadRegisterDebug(15) == 0

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
        cpu.WriteRegisterDebug(1, 10)
        cpu.WriteRegisterDebug(2, cast[uint32](-10))

        p.RunProgram(@[
            SLTI(10, 1, -1), #  10 < -1 = false
            SLTI(11, 2, -1), # -10 < -1 = true
            SLTI(12, 0,  0), #   0 <  0 = false
        ])

        check:
            cpu.ReadRegisterDebug(10) == 0
            cpu.ReadRegisterDebug(11) == 1
            cpu.ReadRegisterDebug(12) == 0

    test "SUBU":
        cpu.WriteRegisterDebug(10, 10)
        cpu.WriteRegisterDebug(11, 1)

        p.RunProgram(@[
            SUBU(1, 10,  0), # 10 - 0 = 10
            SUBU(2, 10, 10), # 10 - 10 = 0
            SUBU(3,  0, 11), #  0 - 10 = 0xFFFF_FFFF  # underflow
        ])

        check:
            cpu.ReadRegisterDebug(1) == 10
            cpu.ReadRegisterDebug(2) == 0
            cpu.ReadRegisterDebug(3) == 0xFFFF_FFFF'u32

    test "SRA":
        cpu.WriteRegisterDebug(10, cast[uint32](-1))
        cpu.WriteRegisterDebug(11, cast[uint32](int32.high))

        p.RunProgram(@[
            SRA(1, 10, 1),
            SRA(2,  0, 1),
            SRA(3, 11, 1),
        ])

        check:
            cpu.ReadRegisterDebug(1) == cast[uint32](-1 shr 1)
            cpu.ReadRegisterDebug(2) == 0
            cpu.ReadRegisterDebug(3) == cast[uint32](int32.high shr 1)

    test "DIV - Standard division":
        let 
            num = 10'u32
            den =  3'u32
        cpu.WriteRegisterDebug(10, num)
        cpu.WriteRegisterDebug(11, den)

        p.RunProgram(@[DIV(10, 11)])

        let 
            (remainder, hi_cycles) = cpu.ReadHiRegister()
            (quotient, lo_cycles) = cpu.ReadLoRegister()

        check:
            remainder == cast[uint32](1)
            hi_cycles == 36 - 1
            quotient == cast[uint32](3)
            lo_cycles == 36 - 1

    test "DIV - Positive division by 0":
        let num = 10'u32
        cpu.WriteRegisterDebug(10, num)

        p.RunProgram(@[DIV(10, 0)])

        let 
            (hi_value, hi_cycles) = cpu.ReadHiRegister()
            (lo_value, lo_cycles) = cpu.ReadLoRegister()

        check:
            hi_value == cast[uint32](num)
            hi_cycles == 36 - 1
            lo_value == cast[uint32](-1)
            lo_cycles == 36 - 1

    test "DIV - Negative division by 0":
        let num = -1
        cpu.WriteRegisterDebug(10, cast[uint32](num))

        p.RunProgram(@[DIV(10, 0)])

        let 
            (hi_value, hi_cycles) = cpu.ReadHiRegister()
            (lo_value, lo_cycles) = cpu.ReadLoRegister()

        check:
            hi_value == cast[uint32](num)
            hi_cycles == 36 - 1
            lo_value == cast[uint32](1)
            lo_cycles == 36 - 1

    test "DIV - (-80000000h div -1)":
        let minus_inf = -0x8000_0000
        cpu.WriteRegisterDebug(10, cast[uint32](minus_inf))
        cpu.WriteRegisterDebug(11, cast[uint32](-1))

        p.RunProgram(@[DIV(10, 11)])

        let 
            (hi_value, hi_cycles) = cpu.ReadHiRegister()
            (lo_value, lo_cycles) = cpu.ReadLoRegister()

        check:
            hi_value == 0
            hi_cycles == 36 - 1
            lo_value == cast[uint32](minus_inf)
            lo_cycles == 36 - 1

    test "MFLO/MFHI":
        let 
            num = 10'u32
            den =  3'u32
        cpu.WriteRegisterDebug(10, num)
        cpu.WriteRegisterDebug(11, den)

        p.RunProgram(@[
            MFLO(1),     #  1 cycle  | nothing set in the register, should be 0 and 1 cycle
            DIV(10, 11), #  1 cycle  | should be 1 cycle by itself, but accessing HI/LO blocks cpu
            MFLO(2),     # 36 cycles | quotent, should block for 35 cycles + 1 cycle for the instruction itself
            MFHI(3),     #  1 cycle  | remainder, should not block, just 1 cycle
            NOP,         #  1 cycle  | 1 extra cycle here to check past the delayed register timestamp
            MFLO(4),     #  1 cycle  | past the target timestamp + cycles in LO
            MFHI(5),     #  1 cycle  | past the target timestamp + cycles in HI
        ])

        check:
            cpu.stats.cycle_count == 1 + 1 + 36 + 1 + 1 + 1 + 1
            cpu.ReadRegisterDebug(1) == 0
            cpu.ReadRegisterDebug(2) == 3
            cpu.ReadRegisterDebug(3) == 1
            cpu.ReadRegisterDebug(4) == 3
            cpu.ReadRegisterDebug(5) == 1

    test "SRL":
        cpu.WriteRegisterDebug(10, 0b1)
        cpu.WriteRegisterDebug(11, 0xFFFF_FFFF'u32)
        p.RunProgram(@[
            SRL(1, 10, 1),
            SRL(2, 11, 4),
            SRL(3, 11, 0),
        ])

        check:
            cpu.ReadRegisterDebug(1) == 0b0
            cpu.ReadRegisterDebug(2) == 0x0FFF_FFFF
            cpu.ReadRegisterDebug(3) == 0xFFFF_FFFF'u32

    test "SLTIU":
        cpu.WriteRegisterDebug(10, 10)
        p.RunProgram(@[
            SLTIU(1, 10, 10), # $1 = 0 (10 < 10)
            SLTIU(2, 10,  9), # $2 = 0 (10 <  9)
            SLTIU(3, 10, 11), # $3 = 1 (10 < 11)
        ])

        check:
            cpu.ReadRegisterDebug(1) == 0
            cpu.ReadRegisterDebug(2) == 0
            cpu.ReadRegisterDebug(3) == 1

    test "DIVU":
        let 
            num = 10'u32
            den =  3'u32
        cpu.WriteRegisterDebug(10, num)
        cpu.WriteRegisterDebug(11, den)

        p.RunProgram(@[DIVU(10, 11)])

        let 
            (remainder, hi_cycles) = cpu.ReadHiRegister()
            (quotient, lo_cycles) = cpu.ReadLoRegister()

        check:
            remainder == cast[uint32](1)
            hi_cycles == 36 - 1
            quotient == cast[uint32](3)
            lo_cycles == 36 - 1

    test "DIVU - Division by 0":
        let 
            num = 10'u32
        cpu.WriteRegisterDebug(10, num)

        p.RunProgram(@[DIVU(10, 0)])

        let 
            (remainder, hi_cycles) = cpu.ReadHiRegister()
            (quotient, lo_cycles) = cpu.ReadLoRegister()

        check:
            remainder == num
            hi_cycles == 36 - 1
            quotient == 0xFFFF_FFFF'u32
            lo_cycles == 36 - 1