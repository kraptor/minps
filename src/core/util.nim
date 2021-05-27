# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

type
    NotImplementedDefect = ref object of Defect

const 
    NOT_IMPLEMENTED_PREFIX = "[NOT IMPLEMENTED] "


template NOT_IMPLEMENTED*(message: string = "") =
    error NOT_IMPLEMENTED_PREFIX & message
    raise NotImplementedDefect(msg: message)

