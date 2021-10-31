# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../core/log
import ../../../core/config
import ../../../core/version
import ../../../emulator/address
import ../../../emulator/platform
import ../../../emulator/cpu/cpu

{.warning[UnusedImport]: off.}
{.warning[HoleEnumConv]: off.}
import nimgl/[glfw, opengl]
import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]