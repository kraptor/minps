# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports
import nimgl/imgui
import state


proc draw*(state: var State) =
    if igBeginMainMenuBar():
        if igBeginMenu "MinPS":
            if igMenuItem("Quit"):
                state.window.setWindowShouldClose(true)
            igEndMenu()
        igEndMainMenuBar()