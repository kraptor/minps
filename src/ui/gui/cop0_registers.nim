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
    begin "COP0: Registers", state.config.gui.cop0_registers.window_visible:
        font "mono":
            var cop0 = state.platform.cpu.cop0

            text fmt"{""id"":>2} {""alias"":>8} {""hex"":>8} {""int32"":>11} {""uint32"":>11}"
            `----`
            for index, register in cop0.regs:
                text fmt"{index:>2} {GetCop0RegisterAlias(index):>8} {register:>8x} {cast[int32](register):>11} {register:>11}"
            `----`

