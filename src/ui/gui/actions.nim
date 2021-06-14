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
        help*: string
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
        label, help: string, 
        callback: CallbackProc,
        shortcut: string = "", 
        isSelected: BoolActionProc = AlwaysFalse, 
        isEnabled: BoolActionproc = AlwaysTrue): Action =
    Action(
        label: label,
        help: help,
        callback: callback,
        shortcut: shortcut,
        isSelected: isSelected,
        isEnabled: isEnabled
    )


proc switch(value: var bool) = 
    value = not value


const
    gui_actions* = {
        "debugger.window.toggle": Action.New(
            "Debugger",
            "Toggle Debugger window visibility",
            proc(state: var State) = switch(state.config.debugger.window_visible),
            isSelected = proc(state: var State): bool = state.config.debugger.window_visible
        ),
        "debugger.step": Action.New(
            "Step",
            "Step one instruction",
            proc(state: var State) = state.platform.cpu.RunNext(),
            "F5"
        ),
        "debugger.reset": Action.New(
            "Reset",
            "Reset platform to initial state",
            proc(state: var State) = state.platform.cpu.Reset(),
        ),
        "app.quit": Action.New(
            "Quit", 
            "Quit application", 
            (state: var State) => state.window.setWindowShouldClose(true),
            "Ctrl+q"
        ),
    }.toTable()