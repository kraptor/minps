# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

type
    Color* = tuple
        r: float32
        g: float32
        b: float32
        a: float32
        
    ColorPalette* = object
        ZERO_VALUE  *: Color
        REGISTER_ID *: Color


proc reset*(palette: var ColorPalette) = 
    palette = DefaultPalette


proc color*(r: float32, g: float32, b: float32, a: float32 = 1): Color = 
    (r:r, g:g, b:b, a:a)


proc color*(r: uint8, g: uint8, b: uint8, a: uint8 = 255): Color = 
    (r:r.float32/255'f32, g:g.float32/255'f32, b:b.float32/255'f32, a:a.float32/255'f32)


const
    # Predefined colors
    GRAY_DIMMED* = color(0.2, 0.2, 0.2)

    # a simple palette with standard colors
    SIMPLE_DARK   * = color(  1,  22,  39) # very dark/blue
    SIMPLE_LIGHT  * = color(253, 255, 252) # very light/white
    SIMPLE_SUCCESS* = color( 46, 196, 182) # tealish
    SIMPLE_ERROR  * = color(231,  29,  54) # redish
    SIMPLE_WARNING* = color(255, 159,  28) # orangish

    DefaultPalette* = ColorPalette(
        ZERO_VALUE: GRAY_DIMMED,
        REGISTER_ID: SIMPLE_SUCCESS
    )

