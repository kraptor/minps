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



proc color*(r: float32, g: float32, b: float32, a: float32 = 1): Color = 
    (r:r, g:g, b:b, a:a)


proc color*(r: uint8, g: uint8, b: uint8, a: uint8 = 255): Color = 
    (r:r.float32/255'f32, g:g.float32/255'f32, b:b.float32/255'f32, a:a.float32/255'f32)


# predefined colors
const
    # basic colors
    WHITE      * = color(1.0, 1.0, 1.0)
    BLACK      * = color(0.0, 0.0, 0.0)
    GRAY       * = color(0.5, 0.5, 0.5)
    GRAY_DIMMED* = color(0.35, 0.35, 0.35)
    RED        * = color(1.0, 0.0, 0.0)
    GREEN      * = color(0.0, 1.0, 0.0)
    BLUE       * = color(0.0, 0.0, 1.0)

    # palette colors
    PALETTE_DARK    * = color(  1,  22,  39)
    PALETTE_LIGHT   * = color(253, 255, 252)
    PALETTE_TEALISH * = color( 46, 196, 182)
    PALETTE_REDISH  * = color(231,  29,  54)
    PALETTE_ORANGISH* = color(255, 159,  28)



