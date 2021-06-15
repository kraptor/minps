# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports

import state
import actions
export state
export actions

const
    BUTTON_SIZE_DEFAULT = ImVec2(x: 0, y:0)


template separator*() = igSeparator()
template `----`*() = separator()
template sameline*() = igSameLine()
template text*(value: string) = igText(value)


template begin*(title: string, open: var bool, flags: ImGuiWindowFlags, body: untyped): untyped =
    if not open:
        return        
    block:
        if igBegin(title, open.addr, flags):
            body
        defer: igEnd()


template begin*(title: string, open: var bool, body: untyped): untyped =
    begin(title, open, ImGuiWindowFlags.None):
        body


template button*(label: string, body: untyped): untyped =
    if igButton(label, BUTTON_SIZE_DEFAULT):
        body


template button*(label, tooltip: string, body: untyped): untyped =
    if igButton(label, BUTTON_SIZE_DEFAULT):
        body
    if igIsItemHovered():
        igSetTooltip(tooltip)


template button*(state: State, action_id: string): untyped =
    let action = GetAction(action_id)
    button(action.label, action.help):
        action.Run(state)


template menubar*(body: untyped): untyped =
    if igBeginMainMenuBar():
        body
        igEndMainMenuBar()


template menu*(label: string, body: untyped): untyped =
    if igBeginMenu(label):
        body
        igEndMenu()


template menuitem*(state: var State, action_name: string) =
    let action = GetAction(action_name)
    if igMenuItem(action.label, action.shortcut, action.IsSelected(state), action.IsEnabled(state)):
        action.Run(state)


template address*(state: var State, a: Address) =
    button $a:
        echo "Open memory viewer at: " & $a