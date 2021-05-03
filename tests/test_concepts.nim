# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest

import emulator/[
    concepts, cpu, mmu, bios, platform
]

suite "Test concepts":

    test "CPU":
        assert Cpu is Component

    test "MMU":
        assert Mmu is Resettable
        assert Mmu is Readable
        assert Mmu is Writable

    test "BIOS":
        assert Bios is Component
        assert Bios is Readable
        assert Bios isnot Writable

    test "Platform":
        assert Platform is Runnable
        assert Platform is Resettable
