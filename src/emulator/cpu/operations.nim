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
    OperationProc = proc(self: Cpu): Cycles {.gcsafe.}


proc ExecuteNotImplemented(self: Cpu): Cycles {.used.} = 
    NOT_IMPLEMENTED fmt"Opcode not implemented: {self.inst.opcode}"


proc ExecuteFunctionNotImplemented(self: Cpu): Cycles {.used.} = 
    NOT_IMPLEMENTED fmt"Function Opcode not implemented: {self.inst.function}"


const OPCODES = block:
    var o: array[Opcode.high.ord, OperationProc] 
    for x in o.mitems: x = ExecuteNotImplemented
    o[ord Opcode.LUI] = Op_LUI
    o[ord Opcode.Special] = Op_Special
    o # return the array


const FUNCTIONS = block:
    var f: array[Function.high.ord, OperationProc]
    for x in f.mitems: x = ExecuteFunctionNotImplemented
    f # return the array


proc Execute*(self: Cpu): Cycles =
    # TODO: return number of cycles
    OPCODES[ord self.inst.opcode] self


proc Op_Special(self: Cpu): Cycles =
    FUNCTIONS[ord self.inst.function] self


proc Op_LUI(self: Cpu): Cycles = 
    NOT_IMPLEMENTED "LUI is not implemented"