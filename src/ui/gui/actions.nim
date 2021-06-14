# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports

import state
import sugar
import tables
export tables

type
    CallbackProc = proc(state: var State) {.closure.}
    BoolActionProc = proc(state: var State): bool {.closure.}

    Action* = object
        label*: string
        title*: string
        shortcut*: string
        callback: CallbackProc
        isSelected: BoolActionProc
        isEnabled : BoolActionProc


proc Run*(action: Action, state: var State) = action.callback(state)
proc IsSelected*(action: Action, state: var State): bool = action.isSelected(state)
proc IsEnabled*(action: Action, state: var State): bool = action.isEnabled(state)

proc AlwaysTrue(state: var State): bool = true
proc AlwaysFalse(state: var State): bool = false

proc New(
        t: type Action, 
        label, title: string, 
        callback: CallbackProc,
        shortcut: string = "", 
        isSelected: BoolActionProc = AlwaysFalse, 
        isEnabled: BoolActionproc = AlwaysTrue): Action =
    Action(
        label: label,
        title: title,
        callback: callback,
        shortcut: shortcut,
        isSelected: isSelected,
        isEnabled: isEnabled
    )


let
    gui_actions* = {
        "quit": Action.New(
            "Quit", 
            "Quit application", 
            proc(state: var State) = state.window.setWindowShouldClose(true),
            "Ctrl+q"
        ),
    }.toTable()