# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports
import tables

var
    fonts: Table[string, ptr ImFont]

const 
    USE_EXTRA_SYMBOLS = false


proc LoadDefaultFont*() =
    igGetIO().fonts.addFontDefault()
    fonts["base"] = igGetDefaultFont()


proc LoadFont*(name: string, font: FontConfig) =
    if font.file == "":
        fonts[name] = fonts["base"]
        return

    when USE_EXTRA_SYMBOLS:
        # TODO: to use extra symbols, NimGL ImGUI bindings need to be updated 
        #       with missing functions and types:
        type
            ImVectorImWchar {.importc: "ImVector_ImWchar"} = object
                size* {.importc: "Size".}: int32
                capacity* {.importc: "Capacity".}: int32
                data* {.importc: "Data".}: ptr ImWchar 

        proc newImVectorImWchar(): ptr ImVectorImWchar {.importc: "ImVector_ImWchar_create".}
        proc newImFontGlyphRangesBuilder(): ptr ImFontGlyphRangesBuilder {.importc: "ImFontGlyphRangesBuilder_ImFontGlyphRangesBuilder".}
        proc buildRanges(self: ptr ImFontGlyphRangesBuilder, out_ranges: ptr ImVectorImWchar): void {.importc: "ImFontGlyphRangesBuilder_BuildRanges".}

        var 
            ranges = newImVectorImWchar()
            builder = newImFontGlyphRangesBuilder()
        builder.addText("│┃‖")
        builder.addRanges(igGetIO().fonts.getGlyphRangesDefault)        
        builder.buildRanges(ranges)
        fonts[name] = igGetIO().fonts.addFontFromFileTTF(font.file.cstring, font.size, nil, ranges.data)
    else:
        fonts[name] = igGetIO().fonts.addFontFromFileTTF(font.file.cstring, font.size)
    

proc GetFont*(name: string): ptr ImFont =
    fonts[name]