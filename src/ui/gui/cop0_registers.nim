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
            var cop0 = state.platform.cpu.cop0
            var cfg = state.config

            text fmt"{""id"":>2} {""alias"":>9} {""hex"":>8} {""int32"":>11} {""uint32"":>11}"
            `----`
            for register, value in cop0.regs:
                var name = $register
                text fmt"{register:>2} "
                sameline
                text fmt"{GetCop0RegisterAlias(register):>9} "
                sameline
                text_color value == 0, fmt"{value:>8x} ", cfg.gui.palette.ZERO_VALUE
                sameline
                text_color value == 0, fmt"{cast[int32](value):>11} ", cfg.gui.palette.ZERO_VALUE
                sameline
                text_color value == 0, fmt"{value:>11}", cfg.gui.palette.ZERO_VALUE
            `----`

