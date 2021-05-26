#!/bin/bash
# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

pwd
rm -f callgrind.out*
nimble build_callgrind
valgrind --tool=callgrind bin/minps_callgrind
python ../nim_callgrind/nim_callgrind.py `ls callgrind.out.*` callgrind.out
kcachegrind