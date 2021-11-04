# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat

include inc/imports

import ../../emulator/cpu/cpu
import ../../emulator/cpu/instruction
import ../../emulator/cpu/disassembler
import ../../emulator/mmu
import ../../core/util

import state
import widgets


proc draw_register_row(id: string, name: string, value: uint32, palette: ColorPalette) =
    table_next_row()
    table_next_column(); text_color fmt"{id:>3}", palette.REGISTER_NUMBER
    table_next_column(); text_color fmt"{name:>6}", palette.REGISTER_NAME
    table_next_column(); text_color value == 0, fmt"{value:>8x}", palette.ZERO_VALUE
    table_next_column(); text_color value == 0, fmt"{cast[int32](value):>10}", palette.ZERO_VALUE
    table_next_column(); text_color value == 0, fmt"{value:>10} ", palette.ZERO_VALUE


proc draw_register_row(name: string, value: uint32, palette: ColorPalette) =
    draw_register_row("", name, value, palette)


proc Draw*(state: var State) =
    begin "CPU: Registers", state.config.gui.registers.window_visible, AlwaysAutoResize:
        font "mono":
            var cpu = state.platform.cpu
            var cfg = state.config

            table "registers", 5:
                table_setup_column fmt"{""id"":>3}"
                table_setup_column fmt"{""name"":>6}"
                table_setup_column fmt"{""hex"":>8}"
                table_setup_column fmt"{""int32"":>10}"
                table_setup_column fmt"{""uint32"":>10} "
                table_header_row_draw()

                for register, value in cpu.regs:
                    draw_register_row(
                        $register, 
                        $register.CpuRegisterAlias,
                        value, 
                        cfg.gui.palette
                    )
                `----`

                # HI register
                block hi_register:
                    let 
                        hi_data = state.platform.cpu.ReadHiRegister()
                        value = if hi_data.cycles >= 0: 0'u32 else: hi_data.value
                    draw_register_row("HI", value, cfg.gui.palette)
                
                # LO register
                block lo_register:
                    let
                        lo_data = state.platform.cpu.ReadHiRegister()
                        value = if lo_data.cycles >= 0: 0'u32 else: lo_data.value
                    draw_register_row("LO", value, cfg.gui.palette)

                `----`

                # PC register
                table_next_row()
                table_next_column(); text "   "
                table_next_column(); text_color fmt"{""PC"":>6}", cfg.gui.palette.REGISTER_NAME
                table_next_column(); text fmt"{state.platform.cpu.pc.uint32:>8x}"
                table_next_column();
                table_next_column();


