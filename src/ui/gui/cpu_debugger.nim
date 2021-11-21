# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat

include inc/imports

import ../../emulator/cpu/instruction
import ../../emulator/cpu/disassembler
import ../../emulator/mmu
import ../../core/util
import state
import widgets


const
    DEBUGGER_ITEM_SPACING = ImVec2(x: 8, y: 0)


proc Draw(inst: Instruction, cpu: Cpu, palette: ColorPalette) =
    if inst.value == 0:
        text_color inst.Disasm(cpu).DisasmAsText(), palette.DEBUGGER_INST_NOP
    else:    
        text_color inst.Disasm(cpu).DisasmAsText(), palette.DEBUGGER_INST_DEFAULT


proc Draw*(state: var State) =
    var
        palette = state.config.gui.palette

    begin "CPU: Debugger", state.config.gui.debugger.window_visible, AlwaysAutoResize:
        
        block top_toolbar:
            button state, "cpu.debugger.step"
            sameline
            button state, "cpu.debugger.reset"
        `----`
        
        push_style ImguiStyleVar.ItemSpacing, DEBUGGER_ITEM_SPACING:
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
                        inst.Draw(cpu, palette)

                block current_instruction:
                    `----`
                    text " PC"
                    sameline
                    address state, pc
                    sameline
                    cpu.inst.Draw(cpu, palette)
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
                        inst.Draw(cpu, palette)
