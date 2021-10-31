# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental:"codeReordering".}

import json
import jsony

import ../core/log
import ../core/colors

logChannels ["config"]


type
    Config* = object
        bios*: BiosConfig
        gui*: GuiConfig

    BiosConfig* = object
        file*: string

    FontConfig* = object
        file*: string
        size*: float32

    GuiConfig* = object 
        window_width   *: int32
        window_height  *: int32
        ui_font        *: FontConfig
        mono_font      *: FontConfig
        debugger       *: DebuggerConfig
        registers      *: RegistersConfig
        cop0_registers *: Cop0RegistersConfig
        palette        *: ColorPalette

    DebuggerConfig* = object
        window_visible *: bool

    RegistersConfig* = object
        window_visible *: bool

    Cop0RegistersConfig* = object
        window_visible *: bool


proc reset*(cfg: var Config) =
    cfg.bios.file = "bios/bios.bin"
    cfg.gui.ui_font.file = ""
    cfg.gui.ui_font.size = 13
    cfg.gui.mono_font.file = ""
    cfg.gui.mono_font.size = 13
    cfg.gui.window_width = 1024
    cfg.gui.window_height = 800
    cfg.gui.debugger.window_visible = false
    cfg.gui.registers.window_visible = false
    cfg.gui.cop0_registers.window_visible = false

    cfg.gui.palette.reset()


proc newHook*(cfg: var Config) = 
    #[
        NOTE: this method should be exported so jsony can use it when
        loading the configuration file defaults values.
    ]#
    cfg.reset()


proc New*(T: type Config, filename: string): Config =
    notice "Loading configuration from: " & filename
    logIndent:
        var config: Config
                
        try:
            var contents = readFile(filename)
            return fromJson(contents, Config)
        except IOError:
            newHook(config)
            
        result = config


proc save*(config: var Config, filename: string) =
    var content = toJson(config)
    
    # TODO: jsony does not currently support pretty printing. 
    # For now let's use json module instead for pretty printing:
    content = content.fromJson().pretty()

    writeFile(filename, content)


