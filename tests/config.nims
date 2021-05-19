# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

switch "path", "../src"

hint "Processing", false
hint "Conf", false
hint "User", false
hint "Exec", false
hint "Link", false
hint "SuccessX", false

switch "verbosity", "0"

# switch "define", "loglevel=Notice"
switch "define", "loglevel_channels="

if not defined(windows):
    switch "passC", "-Wno-packed-bitfield-compat"