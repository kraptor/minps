# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat

include inc/imports

import ../../emulator/cpu/cpu
import ../../emulator/cpu/instruction
import ../../emulator/cpu/disassembler
import ../../emulator/cpu/cop0
import ../../emulator/mmu
import ../../core/util

import state
import widgets


proc Draw*(state: var State) =
    begin "COP0: Registers", state.config.gui.cop0_registers.window_visible, AlwaysAutoResize:
        font "mono":
            let
                cop0 = state.platform.cpu.cop0
                palette = state.config.gui.palette

            table "cop0_registers", 5:
                table_setup_column fmt"{""id"":>3}"
                table_setup_column fmt"{""name"":>6}"
                table_setup_column fmt"{""hex"":>8}"
                table_setup_column fmt"{""int32"":>10}"
                table_setup_column fmt"{""uint32"":>10} "
                table_header_row_draw()

                for register, value in cop0.regs:
                    table_next_row()
                    table_next_column(); text_color fmt"{register:>3}", palette.REGISTER_NUMBER
                    table_next_column(); text_color fmt"{GetCop0RegisterAlias(register):>6}", palette.REGISTER_NAME
                    table_next_column(); text_color value == 0, fmt"{value:>8x}", palette.ZERO_VALUE
                    table_next_column(); text_color value == 0, fmt"{cast[int32](value):>10}", palette.ZERO_VALUE
                    table_next_column(); text_color value == 0, fmt"{value:>10} ", palette.ZERO_VALUE