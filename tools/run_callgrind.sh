#!/bin/bash
# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

rm -f callgrind.out.*
nimble build_callgrind
bin/minps_callgrind
valgrind --tool=callgrind bin/minps_callgrind
kcachegrind