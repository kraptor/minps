# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import address

type
    Resettable* = concept x
        x.Reset()

    Runnable* = concept x
        x.Run()

    Readable* = concept x
        x.Read32(Address) is uint32
        x.Read16(Address) is uint16
        x.Read8(Address) is uint8

    Component* = concept x
        x is Resettable
