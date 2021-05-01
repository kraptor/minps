# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat


type
    Instruction* = distinct uint32


proc `$`*(value: Instruction): string = fmt"Instruction: {cast[uint32](value):08X}h"
