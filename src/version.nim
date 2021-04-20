# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

const Version* = getVersion()
const VersionTag*: string = (staticExec "git tag --points-at HEAD")
const VersionCommit*: string = (staticExec "git rev-parse HEAD")
const VersionString* = getVersionString()

proc getVersion(): string =
    const version {.strdefine.} = "devel"
    result = version
    if defined(MINPS_DEBUG):
        result = result & ".debug"
    if defined(MINPS_RELEASE):
        result = result & ".release"
    if defined(MINPS_PROFILER):
        result = result & ".profiler"

proc getVersionString(): string =
    result = Version
    result = result & " (" & VersionCommit & ")"
