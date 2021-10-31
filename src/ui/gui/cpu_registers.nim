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


proc Draw*(state: var State) =
    begin "CPU: Registers", state.config.gui.registers.window_visible, AlwaysAutoResize:
        font "mono":
            var cpu = state.platform.cpu
            var cfg = state.config

            text fmt"{""id"":>2} {""alias"":>5} {""hex"":>8} {""int32"":>11} {""uint32"":>11}"
            `----`
            for register, value in cpu.regs:
                text fmt"{register:>2} "
                sameline
                text fmt"{GetCpuRegisterAlias(register):>5} "
                sameline
                text_color value == 0, fmt"{value:>8x}", cfg.gui.palette.ZERO_VALUE
                sameline
                text_color value == 0, fmt"{cast[int32](value):>11} ", cfg.gui.palette.ZERO_VALUE
                sameline
                text_color value == 0, fmt"{value:>11}", cfg.gui.palette.ZERO_VALUE
            `----`

