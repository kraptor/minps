# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest

import emulator/[
    concepts, mmu, platform, mc, ram
]

import emulator/cpu/[cpu, cop0]
import emulator/bios/bios


suite "Test concepts":

    test "CPU":
        assert Cpu is Component

    test "Cop0":
        assert Cop0 is Component

    test "MMU":
        assert Mmu is Resettable
        assert Mmu is Readable
        assert Mmu is Writable

    test "BIOS":
        assert Bios is ReadableDevice
        assert Bios isnot WritableDevice

    test "RAM":
        assert Ram is Component
        assert Ram is Resettable
        assert Ram is WritableDevice
        assert Ram is ReadableDevice

    test "Platform":
        assert Platform is Runnable
        assert Platform is Resettable

    test "MemoryControl":
        assert MemoryControl is Device