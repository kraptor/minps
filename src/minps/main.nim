# Copyright (c) 2024 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import cligen

import api

proc minps_cli(config_file: string = DefaultConfigFile): string =
  ## Start MinPS in command-line mode
  echo VersionBanner

proc minps_gui(config_file: string = DefaultConfigFile) =
  ## Start MinPS with a GUI
  echo VersionBanner

proc minps_main*() =
  ## Main entry point

  clCfg.version = VersionString
  clCfg.useMulti =
    """
${doc}

Usage:
  $command [SUBCOMMAND [parameters/options]]

Available SUBCOMMANDs:
$subcmds
Direct parameters available when no SUBCOMMAND is invoked:
  -h, --help     Display this help.
  --help-syntax  General syntax help.
  -v, --version  Display MinPS version."""

  dispatchMulti(
    [
      "multi",
      cmdName = "minps_" & $Build,
      doc = VersionBanner,
      short = {"version": 'v'},
      help = {"version": "Display MinPS version."},
    ],
    [
      minps_cli,
      cmdName = "cli",
      short = {"version": 'v'},
      help = {
        "help": "Show this help message.",
        "help-syntax": "Show advanced help syntax.",
        "version": "Display MinPS version.",
        "config-file": "Use specified config file.",
      },
    ],
    [
      minps_gui,
      cmdName = "gui",
      short = {"version": 'v'},
      help = {
        "help": "Show this help message.",
        "help-syntax": "Show advanced help syntax.",
        "version": "Display MinPS version.",
      },
    ],
  )
