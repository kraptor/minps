# Copyright (c) 2024 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

##[
  This module provides version constants.

  These constants are generated at compile-time.
]##

import strutils
import sequtils
import strformat

const
  MINPS_VERSION {.strdefine: "MINPS_VERSION".} = "0.0.0"
    ## If no MINPS_VERSION is defined, an unversioned (0.0.0) 
    ## version is set. 
    ## 
    ## See [VersionString] for the actual version used when this help was generated.
  GitCommit* = staticExec("git rev-parse HEAD") ## Git commit at compile time

  VersionString* = MINPS_VERSION ## MINPS_VERSION resolved at compile time
  VersionBanner* = fmt"MinPS v{VersionString} - git:{GitCommit}"

    ## This is the banner that should be used when presenting information to the user
  Version*: seq[int] = VersionString.split(".").map(parseInt) ## Version as a seq
  VersionMajor* = Version[0] ## Major version
  VersionMinor* = Version[1] ## Minor version
  VersionPatch* = Version[2] ## Patch version
