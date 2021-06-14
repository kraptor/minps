# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports

import state
import actions
export state
export actions


template menubar*(body: untyped): untyped =
    if igBeginMainMenuBar():
        body
        igEndMainMenuBar()


template menu*(label: string, body: untyped): untyped =
    if igBeginMenu(label):
        body
        igEndMenu()


template menuitem*(state: var State, action_name: string) =
    let action = gui_actions[action_name]
    if igMenuItem(action.label, action.shortcut, action.IsSelected(state), action.IsEnabled(state)):
        action.Run(state)