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


proc simple_row(state: var State, name: string, value: uint32, comment: string) =
    table_next_row()
    table_next_column(); # id is not set
    table_next_column(); text_color fmt"{name:>14}", state.config.gui.palette.REGISTER_DETAIL
    table_next_column(); text_color fmt"{value:>8x}", state.config.gui.palette.REGISTER_DETAIL
    table_next_column(); text_color fmt"{cast[int32](value):>10d}" , state.config.gui.palette.REGISTER_DETAIL
    table_next_column(); text_color fmt"{value:>10}", state.config.gui.palette.REGISTER_DETAIL
    table_next_column(); text_color comment, state.config.gui.palette.REGISTER_DETAIL


proc display_expanded_register(register: Cop0RegisterIndex, state: var State) =
    var cop0 = state.platform.cpu.cop0

    case register.Cop0RegisterName:
        of Cop0RegisterName.PRID: 
            simple_row state, "0..7   Revision", cop0.PRID.Revision, "CPU Revision"
            simple_row state, "8..15  Implementation", cop0.PRID.Implementation, "CPU Implementation"
            simple_row state, "16..31 Not used", cop0.PRID.NotUsed, "Not Used"
        else:
            discard


proc Draw*(state: var State) =
    begin "COP0: Registers", state.config.gui.cop0_registers.window_visible, AlwaysAutoResize:
        font "mono":
            let
                cop0 = state.platform.cpu.cop0
                palette = state.config.gui.palette

            table "cop0_registers", 6:
                table_setup_column fmt"{""id ""}"
                table_setup_column fmt"{""name"":14}"
                table_setup_column fmt"{""hex""}"
                table_setup_column fmt"{""int32""}"
                table_setup_column fmt"{""uint32""}"
                table_setup_column ""
                table_header_row_draw()

                for register, value in cop0.regs:
                    table_next_row()
                    table_next_column(); text_color fmt"{register:>2d}", palette.REGISTER_NUMBER
                    table_next_column(); var open = igTreeNodeEx(fmt"{GetCop0RegisterAlias(register)}".cstring, SpanFullWidth)
                    table_next_column(); text_color value == 0, fmt"{value:>8x}", palette.ZERO_VALUE
                    table_next_column(); text_color value == 0, fmt"{cast[int32](value):>10x}", palette.ZERO_VALUE
                    table_next_column(); text_color value == 0, fmt"{value:>10x} ", palette.ZERO_VALUE
                    table_next_column(); # here goes the comment

                    if open:
                        display_expanded_register register, state
                        igTreePop()