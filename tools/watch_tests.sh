# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

watchexec -rce nim,cfg "nimble --silent test && clear && echo TESTS OK"