# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import colors

type
    ColorPalette* = object
        ZERO_VALUE     *: Color
        REGISTER_NAME  *: Color
        REGISTER_NUMBER*: Color
        REGISTER_DETAIL*: Color


proc setDefaults*(palette: var ColorPalette) = 
    palette = DefaultPalette


const
    DefaultPalette* = ColorPalette(
        ZERO_VALUE     : GRAY_DIMMED,
        REGISTER_NUMBER: GRAY_DIMMED,
        REGISTER_NAME  : PALETTE_LIGHT,
        REGISTER_DETAIL: GRAY_DIMMED
    )