# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental:"codeReordering".}

import strformat

import ../../core/log
import ../../core/util

import cpu
import instruction

logChannels ["cpu", "ops"]

type
    Cycles = Natural

const ops = block:
    var operations: array[Opcode.high.ord, typeof(ExecuteNotImplemented)]
    for x in operations.mitems:
        x = ExecuteNotImplemented
    operations[Opcode.LUI.ord] = ExecuteLUI
    operations


proc Execute*(self: Cpu) =
    discard ops[self.inst.opcode.ord](self)


proc ExecuteNotImplemented(self: Cpu): Cycles {.used.}= 
    NOT_IMPLEMENTED fmt"Opcode not implemented: {self.inst.opcode}"


proc ExecuteLUI(self: Cpu): Cycles =
    NOT_IMPLEMENTED "LUI is not implemented"