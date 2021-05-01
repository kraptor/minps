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
        Read[uint32](x, Address) is uint32
        Read[uint16](x, Address) is uint16
        Read[uint8](x, Address) is uint8

    Component* = concept x
        x is Resettable
