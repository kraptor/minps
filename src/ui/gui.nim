# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../core/log
import ../core/config
import ../emulator/platform
import ../emulator/bios/bios

import gui/application


logChannels ["gui", "main"]


proc main*(config: var Config) = 
    notice "Initializing application..."

    var platform = Platform.New()
    var app = Application.New(config, platform)

    while not app.IsClosing():
        app.ProcessEvents()
        app.Draw()
        app.Present()

    app.Terminate()
