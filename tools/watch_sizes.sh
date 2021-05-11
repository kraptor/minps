# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

watch "ls -lah bin | tr -s ' '| cut -s -d' ' -f5,9"