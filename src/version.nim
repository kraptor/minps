# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

const VersionCommit*: string = (staticExec "git rev-parse HEAD")
const VersionTag*: string = (staticExec "git tag --points-at HEAD")
const VersionString* = getVersionString()


proc getVersionString(): string =
    result = VersionTag

    if result.len == 0:
        result = "devel"

    if defined(MINPS_DEBUG):
        result = result & ".debug"
    if defined(MINPS_RELEASE):
        result = result & ".release"
    if defined(MINPS_PROFILER):
        result = result & ".profiler"

    result = result & " (" & VersionCommit & ")"
