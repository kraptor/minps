# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

type
    NotImplementedDefect = ref object of Defect

template NOT_IMPLEMENTED*(message: string = "") =
    error message
    var e: NotImplementedDefect = new NotImplementedDefect
    e.msg = message
    raise e
