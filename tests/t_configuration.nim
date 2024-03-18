# Copyright (c) 2024 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import strutils
import sequtils

import minps/api

proc delete_whitespace(text: string): string =
  multireplace(
    text, (" ", ""), ("\t", ""), ("\v", ""), ("\r", ""), ("\l", ""), ("\f", "")
  )

const default_config =
  delete_whitespace""" 
    {
    } 
  """

suite "Configuration":
  setup:
    var c = Configuration()

  test "Default configuration":
    check:
      c.dump_json() == default_config

  test "Configuration load and store is idempotent":
    check:
      c.dump_json() == Configuration.load_json(default_config).dump_json()
