# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include inc/imports

template color(r: float32, g: float32, b: float32, a: float32 = 1): untyped = 
    ImVec4(x:r, y:g, z:b, w:a)

const
    GRAY_DIMMED* = color(0.5, 0.5, 0.5)
    RED* = color(1, 0, 0)
    
    ZERO_VALUE* = GRAY_DIMMED