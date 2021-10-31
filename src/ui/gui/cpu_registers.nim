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
    begin "CPU: Registers", state.config.gui.registers.window_visible:
        font "mono":
            var cpu = state.platform.cpu

            text fmt"{""id"":>2} {""alias"":>5} {""hex"":>8} {""int32"":>11} {""uint32"":>11}"
            `----`
            for index, register in cpu.regs:
                text fmt"{index:>2} {GetCpuRegisterAlias(index):>5} {register:>8x} {cast[int32](register):>11} {register:>11}"
            `----`

