# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

const Version* {.strdefine.} = "devel"
const VersionTag*: string = (staticExec "git tag --points-at HEAD")
const VersionCommit*: string = (staticExec "git rev-parse HEAD")
const VersionString* = getVersionString()


proc getVersionString(): string =
    result = Version

    if defined(MINPS_DEBUG):
        result = result & ".debug"
    if defined(MINPS_RELEASE):
        result = result & ".release"
    if defined(MINPS_PROFILER):
        result = result & ".profiler"

    result = result & " (" & VersionCommit & ")"