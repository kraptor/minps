# `minps` - a wannabe PlayStation 1 emulator

[![made-with-nim](https://img.shields.io/badge/Made%20with-Nim-ffc200.svg)](https://nim-lang.org/)
![Build](https://github.com/kraptor/minps/workflows/Build/badge.svg)

![License](https://img.shields.io/github/license/kraptor/minps?color=pink)
![Total Lines](https://img.shields.io/tokei/lines/github/kraptor/minps?label=Total%20Lines)
![Language](https://img.shields.io/github/languages/top/kraptor/minps?logo=Nim)
![Languages](https://img.shields.io/github/languages/count/kraptor/minps?label=Languages)
![Code Size](https://img.shields.io/github/languages/code-size/kraptor/minps)

## Building instructions

``minps`` can be compiled in different flavors using ``nimble``.

Debug build:

    nimble build_debug

Profiler build:

    nimble build_profiler

Profiler build (memory):

    nimble build_profiler_memory

Release build:

    nimble build_release

Release build with symbols for Valgrind/Callgrind:

    nimble build_callgrind

Release build (with stacktrace support):

    nimble build_release_stacktrace

## Running tests

    nimble test --silent

## Logging configuration

Available defines:

* `loglevel`: set a minimum log level to log.
* `loglevel_channels`: set channels to log (separated by commas) or using a wildcard to specify all.
* `log_indentation_width`: how many spaces to use when indenting the log output.

See the file [``src/nim.cfg``](src/nim.cfg) for defaults.
