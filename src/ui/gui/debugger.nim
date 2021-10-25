# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat

include inc/imports
import nimgl/imgui

import ../../emulator/cpu/instruction
import ../../emulator/cpu/disassembler
import ../../emulator/mmu
import ../../core/util
import state
import widgets


proc Draw*(state: var State) =
    begin "Debugger", state.config.debugger.window_visible:
        block top_toolbar:
            button state, "debugger.step"
            sameline
            button state, "debugger.reset"
        `----`

        block pc_info:
            font "mono":
                text "PC="
                sameline
                address state, state.platform.cpu.pc
        `----` 

        var 
            cpu = state.platform.cpu
            pc = cpu.pc # - 0xbfc0_0000'u32

        const 
            debug_instruction_peek_before = 10
            debug_instruction_peek_after = 10

        font "mono":
            block prev_instructions:
                # display previous instructions
                for i in countdown(debug_instruction_peek_before, 1):
                    var mem_addr = pc - (i.uint32 * sizeof(Instruction).uint32)
                    
                    # do not peek addressess below 0x0
                    if mem_addr > pc:
                        continue

                    text "   "
                    sameline
                    address state, mem_addr
                    sameline
                    var inst = Instruction.New(cpu.mmu.ReadDebug32(mem_addr))
                    text inst.Disasm(cpu).DisasmAsText()

            block current_instruction:
                `----`
                text "PC:"
                sameline
                address state, pc
                sameline
                text cpu.inst.Disasm(cpu).DisasmAsText()
                `----`
            
            block next_instructions:
                for i in 1'u32 .. debug_instruction_peek_after:
                    var mem_addr = pc + (i * sizeof(Instruction).uint32)
                    
                    # do not peek instructions over maximum value
                    if mem_addr < pc:
                        break
                    
                    text "   "
                    sameline
                    address state, mem_addr
                    sameline
                    var inst = Instruction.New(ReadDebug[uint32](cpu.mmu, mem_addr))
                    text inst.Disasm(cpu).DisasmAsText()
            `----`

