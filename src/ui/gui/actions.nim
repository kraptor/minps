# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import sugar
import options
import strutils
import tables
export tables # make sure callers have access to tables module

include inc/imports
import state

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


proc AlwaysTrue*(state: var State): bool = true
proc AlwaysFalse*(state: var State): bool = false
proc DummyCallback(state: var State) = discard


proc New(
        t: type Action, 
        label, help: string, 
        callback: CallbackProc = DummyCallback,
        shortcut: string = "", 
        isSelected: BoolActionProc = AlwaysFalse, 
        isEnabled: BoolActionproc = AlwaysTrue): Action =
    
    result = Action(
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
    NO_ACTION* = Action.New("no.action", "No action")

    ACTIONS = {
        "cop0.registers.window.toggle": Action.New(
            "COP0 Registers",
            "Toggle COP0 Registers window visibility",
            proc(state: var State) = switch(state.config.gui.cop0_registers.window_visible),
            isSelected = proc(state: var State): bool = state.config.gui.cop0_registers.window_visible,
            shortcut = "Super+C"
        ),
        "cpu.registers.window.toggle": Action.New(
            "CPU Registers",
            "Toggle CPU Registers window visibility",
            proc(state: var State) = switch(state.config.gui.registers.window_visible),
            isSelected = proc(state: var State): bool = state.config.gui.registers.window_visible,
            shortcut = "Super+R"
        ),
        "cpu.debugger.window.toggle": Action.New(
            "CPU Debugger",
            "Toggle CPU Debugger window visibility",
            proc(state: var State) = switch(state.config.gui.debugger.window_visible),
            isSelected = proc(state: var State): bool = state.config.gui.debugger.window_visible,
            shortcut = "Super+D"
        ),
        "cpu.debugger.step": Action.New(
            "Step",
            "Step one instruction",
            proc(state: var State) = 
                block:
                    state.platform.cpu.RunNext()
                    logFlush()
            ,
            "F10"
        ),
        "cpu.debugger.reset": Action.New(
            "Reset",
            "Reset platform to initial state",
            proc(state: var State) = state.platform.cpu.Reset(),
        ),
        "app.config.reset": Action.New(
            "Reset configuration",
            "Reset configuration to default values",
            proc(state: var State) = newHook state.config
        ),
        "app.config.reset_palette": Action.New(
            "Reset color palette",
            "Reset color palette to default values",
            proc(state: var State) = newHook state.config.gui.palette
        ),
        "app.quit": Action.New(
            "Quit", 
            "Quit application", 
            (state: var State) => state.window.setWindowShouldClose(true),
            "Ctrl+Q"
        ),
    }.toTable()


proc GetActionByName*(name: string): Action = 
    if name in ACTIONS:
        return ACTIONS[name]
    NO_ACTION


proc GetActionByShortcut*(shortcut: string): Action =
    for action in ACTIONS.values:
        if action.shortcut.toLowerAscii() == shortcut.toLowerAscii():
            return action
    NO_ACTION