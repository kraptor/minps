# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports

import state
import widgets


proc Draw*(state: var State) =
    
    # FIXME: following var declaration is a workaround for 
    #   a compiler bug. Remove it when not needed!
    var s = state 

    menubar:
        menu "MinPS":
            `----`
            menuitem state, "app.quit"

        menu "Debugger":
            menuitem state, "cpu.debugger.step"
            `----`
            menuitem state, "cpu.debugger.reset"

        menu "Windows":
            menuitem state, "cpu.registers.window.toggle"
            menuitem state, "cpu.debugger.window.toggle"
            menuitem state, "cop0.registers.window.toggle"

        