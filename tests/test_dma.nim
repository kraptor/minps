# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest

import emulator/dma


suite "Test DmaDevice types":

    test "DMA Registers size":
        check:
            sizeof(DmaDevice) == sizeof(DMA_MAP_MAX_SIZE)

    test "DMA Registers initial values":
        let d = DmaDevice.New()
        Reset d

        check:
            d.DPCR.value == 0x07654321.uint32