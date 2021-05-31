# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

type
    NotImplementedDefect = ref object of Defect

const 
    NOT_IMPLEMENTED_PREFIX = "[NOT IMPLEMENTED] "


template NOT_IMPLEMENTED*(message: string = "") =
    # by using a block we force the Nim compiler to allocate
    # the string only within the block, therefore only when
    # the code hits the NOT_IMPLEMENTED is allocated. Because
    # this template is used very often during development
    # by issuing a block we save lots and lots of string
    # allocs/deallocs
    block:
        error NOT_IMPLEMENTED_PREFIX & message
        raise NotImplementedDefect(msg: message)


proc divmod*(x, y: SomeSignedInt): tuple[quotent, remainder: SomeSignedInt] {.inline.} =
    # TODO: make sure this is fused into one instruction!
    return (x div y, x mod y)