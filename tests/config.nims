# Copyright (c) 2024 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# We want tests to behave as if they were in
# src folder so we can use normal imports, etc.
switch "path", "../src"

# Force some compiler flags for tests
switch "define", "MINPS_MODE:debug"
switch "define", "MINPS_VERSION:1.2.3"
switch "define", "debug"

# Silence nim compiler a bit
hint "Processing", false
hint "Conf", false
hint "User", false
hint "Exec", false
hint "Link", false
hint "SuccessX", false
switch "verbosity", "0"
