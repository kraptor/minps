# Copyright (c) 2024 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

##[
  Implementation of the [Configuration] de/serialization.
]##

import pkg/jsony
import json

type
  Configuration* = object ## Default configuration.
    discard

proc dump_json*(self: Configuration, pretty: bool = false): string =
  ## Dump configuration as a JSON string.
  if pretty:
    return self.toJson().parseJson().pretty()
  self.toJson()

proc load_json*(_: typedesc[Configuration], json: string): Configuration =
  ## Load a configuration from a JSON string.
  fromJson(json, Configuration)
