# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports
import nimgl/imgui
import state
import actions
import widgets


template menuitem(state: var State, action_name: string) =
    let action = gui_actions[action_name]
    if igMenuItem(action.label, action.shortcut, action.IsSelected(state), action.IsEnabled(state)):
        action.Run(state)


proc draw*(state: var State) =
    var state = state
    if igBeginMainMenuBar():
        if igBeginMenu("MinPS"):
            # if igMenuItem("Quit"):
            #     gui_actions["quit"].Run(state)
            menuitem(state, "quit")
            igEndMenu()
        igEndMainMenuBar()