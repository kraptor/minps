# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports
import nimgl/imgui

import state
import widgets


proc draw*(state: var State) =
    var state = state   
    menubar:
        menu "MinPS":
            menuitem(state, "quit")
