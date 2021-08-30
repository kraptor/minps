# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports

import state
import actions
import fonts

export state
export actions
export fonts

const
    BUTTON_SIZE_DEFAULT = ImVec2(x: 0, y:0)


template font*(font_name: string, body: untyped): untyped =
    igPushFont(GetFont(font_name))
    block:
        body
        defer: igPopFont()


template separator*() = igSeparator()
template `----`*() = separator()
template sameline*() = igSameLine()
template text*(value: string) = igText(value)


template begin*(title: string, open: var bool, flags: ImGuiWindowFlags, body: untyped): untyped =
    if not open:
        return        
    block:
        if igBegin(title.cstring, open.addr, flags):
            body
        defer: igEnd()


template begin*(title: string, open: var bool, body: untyped): untyped =
    begin(title, open, ImGuiWindowFlags.None):
        body


template button*(label: string, body: untyped): untyped =
    if igButton(label.cstring, BUTTON_SIZE_DEFAULT):
        body


template button*(label, tooltip: string, body: untyped): untyped =
    if igButton(label.cstring, BUTTON_SIZE_DEFAULT):
        body
    if igIsItemHovered():
        igSetTooltip(tooltip.cstring)


template button*(state: State, action_id: string): untyped =
    let 
        action = GetActionByName(action_id)
        
    button(action.label):
        action.Run(state)

    if igIsItemHovered():
        igBeginTooltip()
        text action.help
        if action.shortcut != "":
            igSameLine()
            text "(" & action.shortcut & ")"
        igEndTooltip()


template menubar*(body: untyped): untyped =
    if igBeginMainMenuBar():
        body
        igEndMainMenuBar()


template menu*(label: string, body: untyped): untyped =
    if igBeginMenu(label.cstring):
        body
        igEndMenu()


template menuitem*(state: var State, action_name: string) =
    let action = GetActionByName(action_name)
    if igMenuItem(action.label.cstring, action.shortcut.cstring, action.IsSelected(state), action.IsEnabled(state)):
        action.Run(state)


template open_popup(name: string) = igOpenPopup(name.cstring)


template close_current_popup() = igCloseCurrentPopup()


template popup_modal(id: string, content: untyped) =
    if igBeginPopupModal(id.cstring, nil, AlwaysAutoResize):
        content
        igEndPopup()


proc not_implemented*(message: string): string =
    result = "NOT IMPLEMENTED##" & message
    popup_modal result:
        text message
        separator
        button "ok":
            close_current_popup()


template address*(state: var State, a: Address) =
    font "mono":
        let popup_id = not_implemented("Open memory viewer at: " & $a)
        button $a:
            open_popup(popup_id)

        