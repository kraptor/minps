# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

include core/profiler # NOTE: should be an include for it to work

import chronicles

logScope:
    topics = "main"
    chroniclesLineNumbers = true

import core/version

proc main() =
    echo "minps - a wannabe PlayStation 1 emulator"
    echo "version: " & VersionString
    echo "---"
    notice "minps started", version = VersionString
    notice "minps stopped"

when isMainModule:    
    main()
