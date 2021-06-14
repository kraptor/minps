# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports

import state
import actions
export state
export actions


template menuitem*(state: var State, action_name: string) =
    let action = gui_actions[action_name]
    if igMenuItem(action.label, action.shortcut, action.IsSelected(state), action.IsEnabled(state)):
        action.Run(state)