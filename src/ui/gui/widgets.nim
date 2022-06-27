# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports
import std/times

import state
import actions
import fonts

export state
export actions
export fonts

const
    BUTTON_SIZE_DEFAULT = ImVec2(x: 0, y:0)

template toVec4*(c: Color): ImVec4 = ImVec4(x:c.r,y:c.g,z:c.b,w:c.a)


template font*(font_name: string, body: untyped): untyped =
    igPushFont(GetFont(font_name))
    block:
        body
        defer: igPopFont()


template push_id*(value, body) =
    igPushId(value)
    body
    igPopId()


template separator*() = igSeparator()
template `----`*() = separator()
template sameline*() = igSameLine()
template text*(value: string) = igText(value.cstring)
template text_color*(value: string, c: Color) = igTextColored c.toVec4(), value.cstring


template tooltip*(body) =
    igBeginTooltip()
    body
    igEndTooltip()

template text_color*(condition: bool, value: string, true_color: Color, false_color: Color) =
    if condition: 
        text_color value, true_color 
    else: 
        text_color value, false_color


template text_color*(condition: bool, value: string, true_color: Color) =
    if condition: 
        text_color value, true_color 
    else: 
        text value


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


template button*(state: var State, action_id: string): untyped =
    let 
        action = GetActionByName(action_id)
        
    button(action.label):
        action.Run(state)

    if igIsItemHovered():
        tooltip:
            text action.help
            if action.shortcut != "":
                igSameLine()
                text "(" & action.shortcut & ")"


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
    font "ui":
        if igBeginPopupModal(id.cstring, nil, AlwaysAutoResize):
            content
            igEndPopup()


# proc not_implemented*(message: string): string =
#     result = "NOT IMPLEMENTED##" & message
#     popup_modal result:
#         text message
#         separator
#         button "ok":
#             close_current_popup()


template reference_address*(state: var State, a: Address) =
    font "mono":
        button $a:
            echo "NOT IMPLEMENTED: open memory address at: " & $a


template reference_cpu_register*(state: var State, register: CpuRegisterIndex) =
    font "mono":
        # button $CpuRegisterAlias(register):
        #     echo "NOT IMPLEMENTED: open cpu register info for: " & $register
        text $register.CpuRegisterAlias
        if igIsItemHovered():
            tooltip:
                var 
                    value = state.platform.cpu.ReadRegisterDebug(register)
                    value_str = ""

                text "CPU Register"
                igSeparator()
                
                formatValue(value_str, value, ">8x")
                text "  value (hex): " & value_str

                formatValue(value_str, cast[int32](value), ">11")
                text "  value (i32): " & value_str

                formatValue(value_str, value, ">11")
                text "  value (u32): " & $value_str


template push_style*(style_var: ImGuiStyleVar, value: ImVec2, body) =
    igPushStyleVar(stylevar, value)
    body
    igPopStyleVar()


template table*(name: string, columns: Natural, body) =
    if igBeginTable(name, columns):
        body
        igEndTable()


proc table_next_row* = igTableNextRow()
proc table_next_column* = igTableNextColumn()


proc table_setup_column*(name: string, flags: ImguiTableColumnFlags = 
    ImGuiTableColumnFlags.None) = igTableSetupColumn(name.cstring, flags)


proc table_header_row_draw* = igTableHeadersRow()