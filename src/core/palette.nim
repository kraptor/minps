# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import colors

type
    ColorPalette* = object
        ZERO_VALUE  *: Color
        REGISTER_ID *: Color


const
    # a simple palette with standard colors
    SIMPLE_DARK    = color(  1,  22,  39) # very dark/blue
    SIMPLE_LIGHT   = color(253, 255, 252) # very light/white
    SIMPLE_SUCCESS = color( 46, 196, 182) # tealish
    SIMPLE_ERROR   = color(231,  29,  54) # redish
    SIMPLE_WARNING = color(255, 159,  28) # orangish


proc setDefaults*(palette: var ColorPalette) = 
    palette = DefaultPalette

const
    DefaultPalette* = ColorPalette(
        ZERO_VALUE: GRAY_DIMMED,
        REGISTER_ID: SIMPLE_SUCCESS
    )