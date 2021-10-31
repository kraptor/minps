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
import colors
import widgets


template text_color*(text: string, color: ImVec4) =
    igTextColored color, text.cstring


proc text_color*(enabled: bool, text: string, true_color: ImVec4, false_color: ImVec4) =
    if enabled:
        text_color text, true_color
    else:
        text_color text, false_color


proc text_color*(enabled: bool, text: string, true_color: ImVec4) =
    if enabled:
        text_color text, true_color
    else:
        text text


proc Draw*(state: var State) =
    begin "CPU: Registers", state.config.gui.registers.window_visible, AlwaysAutoResize:
        font "mono":
            var cpu = state.platform.cpu

            text fmt"{""id"":>2} {""alias"":>5} {""hex"":>8} {""int32"":>11} {""uint32"":>11}"
            `----`
            for register, value in cpu.regs:
                text fmt"{register:>2} "
                sameline
                text fmt"{GetCpuRegisterAlias(register):>5} "
                sameline
                text_color value == 0, fmt"{value:>8x}", colors.ZERO_VALUE
                sameline
                text_color value == 0, fmt"{cast[int32](value):>11} ", colors.ZERO_VALUE
                sameline
                text_color value == 0, fmt"{value:>11}", colors.ZERO_VALUE
            `----`

