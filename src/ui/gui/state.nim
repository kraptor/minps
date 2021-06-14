# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports
import ../../emulator/platform

type
    State* = object
        window   *: GLFWWindow
        context  *: ptr ImGuiContext
        config   *: Config
        platform *: Platform