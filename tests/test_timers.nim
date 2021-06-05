# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest

import emulator/timers


suite "Test Timers types":

    test "Union sizes":
        check:
            sizeof(TimerMode) == sizeof(uint32)
            sizeof(Timer2Mode) == sizeof(uint32)
