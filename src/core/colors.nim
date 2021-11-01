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


const
    # Predefined colors
    GRAY_DIMMED* = color(0.2, 0.2, 0.2)



