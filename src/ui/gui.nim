# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat

import ../core/log
import ../core/util
import ../core/config

import gui/application


logChannels ["gui", "main"]


proc main*(config: var Config) = 
    notice "Initializing application..."
    var app = Application.New(config)

    while not app.IsClosing():
        app.ProcessEvents()
        app.Draw()
        app.Present()

    app.Terminate()
