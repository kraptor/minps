# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import core/version

suite "version":
    test "version value":
        check:
            version.Version == "devel"