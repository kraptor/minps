#!/bin/bash
# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

watchexec -rce nim,cfg "echo \"BUILD STARTS ****************\" && nimble build_release && clear && bin/minps_release && echo \"TERMINATED!\""
