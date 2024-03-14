# Copyright (c) 2024 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest

import minps/api

const git_commit = staticExec("git rev-parse HEAD")

suite "Version":
  ##[
    Checks that version flags and build modes are honored.
    Test configuration used is from config.nims in the test folder.
  ]##

  test "Version values":
    check:
      VersionString == "1.2.3"
      Version == @[1, 2, 3]
      VersionMajor == 1
      VersionMinor == 2
      VersionPatch == 3

  test "BuildMode is set correctly":
    check:
      Build == BuildMode.Debug

  test "VersionBanner is set correctly":
    check:
      VersionBanner == "MinPS v1.2.3 - git:" & git_commit
