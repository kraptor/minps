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
    table_next_column(); text_color fmt"{name}", state.config.gui.palette.REGISTER_DETAIL
    table_next_column(); text_color fmt"{value:>8x}", state.config.gui.palette.REGISTER_DETAIL
    table_next_column(); text_color fmt"{cast[int32](value):>10d}" , state.config.gui.palette.REGISTER_DETAIL
    table_next_column(); text_color fmt"{value:>10}", state.config.gui.palette.REGISTER_DETAIL
    table_next_column(); text_color comment, state.config.gui.palette.REGISTER_DETAIL


proc display_expanded_register(register: Cop0RegisterIndex, state: var State) =
    var cop0 = state.platform.cpu.cop0

    case register.Cop0RegisterName:
        of Cop0RegisterName.PRID: 
            simple_row state, "0-7   Rev", cop0.PRID.Revision, "CPU Revision"
            simple_row state, "8-15  Imp", cop0.PRID.Implementation, "CPU Implementation"
            simple_row state, "16-31 ???", cop0.PRID.NotUsed, "Not Used"
        of Cop0RegisterName.SR:
            simple_row state, "0     IEc", cop0.SR.IEc.uint32, $cop0.SR.IEc & " - Current Interrupt Enable"
            simple_row state, "1     KUc", cop0.SR.KUc.uint32, $cop0.SR.KUc & " - Current Kernel/User Mode"
            simple_row state, "2     IEp", cop0.SR.IEp.uint32, $cop0.SR.IEp & " - Previous Interrupt Disable" 
            simple_row state, "3     KUp", cop0.SR.KUp.uint32, $cop0.SR.KUp & " - Previous Kernel/User Mode"
            simple_row state, "4     IEo", cop0.SR.IEo.uint32, $cop0.SR.IEo & " - Old Interrupt Disable" 
            simple_row state, "5     KUo", cop0.SR.KUo.uint32, $cop0.SR.KUo & " - Old Kernel/User Mode"
            simple_row state, "6-7   ???", cop0.SR.Unused_06_07, "Not used (zero)"
            simple_row state, "8-15  Im", cop0.SR.Im, fmt"{cop0.SR.Im:08b} - Interrupt Mask"
            simple_row state, "16    Isc", cop0.SR.Isc.uint32, $cop0.SR.Isc & " - Isolate Cache"
            simple_row state, "17    Swc", cop0.SR.Swc.uint32, $cop0.SR.Swc & " - Swapped Cache Mode"
            simple_row state, "18    PZ", cop0.SR.PZ.uint32, $cop0.SR.PZ & " - PZ"
            simple_row state, "19    CM", cop0.SR.CM.uint32, $cop0.SR.CM & " - CM"
            simple_row state, "20    PE", cop0.SR.PE.uint32, $cop0.SR.PE & " - Cache Parity Error"
            simple_row state, "21    TS", cop0.SR.TS.uint32, $cop0.SR.TS & " - TLB Shutdown"
            simple_row state, "22    BEV", cop0.SR.BEV.uint32, $cop0.SR.BEV & " - Boot Exception Vector location"
            simple_row state, "23-24 ???", cop0.SR.Unused_23_24.uint32, "Not used (zero)"
            simple_row state, "25    RE", cop0.SR.RE.uint32, $cop0.SR.RE & " - Reverse Endianess"
            simple_row state, "26-27 ???", cop0.SR.Unused_26_27.uint32, "Not used (zero)"
            simple_row state, "28    CU0", cop0.SR.CU0.uint32, $cop0.SR.CU0 & " - Cop0 Enable"
            simple_row state, "29    CU1", cop0.SR.CU1.uint32, $cop0.SR.CU1 & " - Cop1 Enable (none)"
            simple_row state, "30    CU2", cop0.SR.CU2.uint32, $cop0.SR.CU2 & " - Cop2 Enable (GTE)"
            simple_row state, "31    CU3", cop0.SR.CU3.uint32, $cop0.SR.CU3 & " - Cop3 Enable (none)"
        else:
            discard


proc Draw*(state: var State) =
    begin "COP0: Registers", state.config.gui.cop0_registers.window_visible:
        font "mono":
            let
                cop0 = state.platform.cpu.cop0
                palette = state.config.gui.palette

            table "cop0_registers", 6:
                table_setup_column fmt"{""id ""}", WidthFixed
                table_setup_column fmt"{""name"":14}", WidthFixed
                table_setup_column fmt"{""hex"":>8}", WidthFixed
                table_setup_column fmt"{""int32"":>10}", WidthFixed
                table_setup_column fmt"{""uint32"":>10}", WidthFixed
                table_setup_column "", ImGuiTableColumnFlags.WidthStretch # comment
                table_header_row_draw()

                for register, value in cop0.regs:
                    table_next_row()
                    table_next_column(); text_color fmt"{register:>2d}", palette.REGISTER_NUMBER
                    table_next_column(); var open = igTreeNodeEx(fmt"{GetCop0RegisterAlias(register)}".cstring, SpanFullWidth)
                    table_next_column(); text_color value == 0, fmt"{value:>8x}", palette.ZERO_VALUE
                    table_next_column(); text_color value == 0, fmt"{cast[int32](value):>10x}", palette.ZERO_VALUE
                    table_next_column(); text_color value == 0, fmt"{value:>10x} ", palette.ZERO_VALUE
                    table_next_column(); text_color $register.Cop0RegisterDescription, palette.REGISTER_DESCRIPTION # here goes the comment

                    if open:
                        display_expanded_register register, state
                        igTreePop()