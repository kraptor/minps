# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest

import emulator/[
    concepts, mmu, bios, platform, mc1
]

import emulator/cpu/cpu


suite "Test concepts":

    test "CPU":
        assert Cpu is Component

    test "MMU":
        assert Mmu is Resettable
        assert Mmu is Readable
        assert Mmu is Writable

    test "BIOS":
        assert Bios is ReadableDevice
        assert Bios isnot WritableDevice

    test "Platform":
        assert Platform is Runnable
        assert Platform is Resettable

    test "MC1":
        assert Mc1 is Device