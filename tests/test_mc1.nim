# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest

import emulator/mc1


suite "Test MC1 types":

    test "Union sizes":
        check sizeof(DelaySizeRegister) == sizeof(uint32)
        check sizeof(DelaySizeRegisterParts) == sizeof(uint32)
        check sizeof(RamSizeRegisterParts) == sizeof(uint32)
        check sizeof(ComDelayRegisterParts) == sizeof(uint32)