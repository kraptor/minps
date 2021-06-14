# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports
import nimgl/imgui

import state
import widgets


proc Draw*(state: var State) =
    begin "Debugger", state.config.debugger.window_visible:
        button state, "debugger.step"
        sameline
        button state, "debugger.reset"
        `----`       
        text "PC: " 
        sameline
        address state, state.platform.cpu.pc
