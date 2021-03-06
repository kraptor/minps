# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest

import emulator/mc


suite "Test MemoryControl 1 types":

    test "Union sizes":
        check:
            sizeof(DelaySizeRegister) == sizeof(uint32)
            sizeof(DelaySizeRegisterParts) == sizeof(uint32)
            sizeof(RamSizeRegisterParts) == sizeof(uint32)
            sizeof(ComDelayRegisterParts) == sizeof(uint32)

suite "Test MemoryControl 3 types":
    test "Union sizes":
        check:
            sizeof(CacheControlRegisterParts) == sizeof(uint32)
            sizeof(CacheControlRegister) == sizeof(uint32)