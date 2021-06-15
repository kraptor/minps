# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports
import tables

var
    fonts: Table[string, ptr ImFont]

proc LoadFont*(name: string, font: FontConfig) =
    fonts[name] = igGetIO().fonts.addFontFromFileTTF(font.file, font.size)


proc GetFont*(name: string): ptr ImFont =
    fonts[name]