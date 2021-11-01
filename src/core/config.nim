# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# {.experimental:"codeReordering".}

import json
import jsony

import ../core/log
import ../core/palette

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


proc setDefaults*(cfg: var Config) =
    cfg.gui.debugger.window_visible = false
    cfg.gui.registers.window_visible = false
    cfg.gui.cop0_registers.window_visible = false


proc newHook*(debugger: var DebuggerConfig) =
    debugger.window_visible = false


proc newHook*(registers: var RegistersConfig) =
    registers.window_visible = false


proc newHook*(cop0_registers: var Cop0RegistersConfig) =
    cop0_registers.window_visible = false


proc newHook*(palette: var ColorPalette) = 
    palette = DefaultPalette


proc newHook*(bios: var BiosConfig) = 
    bios.file = "bios/bios.bin"


proc newHook*(font: var FontConfig) = 
    font.file = ""
    font.size = 13


proc newHook*(gui: var GuiConfig) =
    gui.window_width = 1024
    gui.window_height = 800
    newHook gui.ui_font
    newHook gui.mono_font
    newHook gui.debugger
    newHook gui.registers
    newHook gui.cop0_registers
    newHook gui.palette


proc newHook*(config: var Config) =
    newHook config.gui
    newHook config.bios


proc New*(T: type Config, filename: string): Config =
    notice "Loading configuration from: " & filename
    logIndent:
        var config: Config
        
        try:
            var contents = readFile(filename)
            return fromJson(contents, Config)
        except IOError:
            # use defaults in config cannot be read
            newHook config
            
        result = config


proc save*(config: var Config, filename: string) =
    var content = toJson(config)
    
    # TODO: jsony does not currently support pretty printing. 
    # For now let's use json module instead for pretty printing:
    content = content.fromJson().pretty()

    writeFile(filename, content)


