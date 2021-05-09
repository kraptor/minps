# minps

[![made-with-nim](https://img.shields.io/badge/Made%20with-Nim-ffc200.svg)](https://nim-lang.org/) ![Build](https://github.com/kraptor/minps/workflows/Build/badge.svg)

`minps` - a wannabe PlayStation 1 emulator

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

Release build (with stacktrace support):

    nimble build_release_stacktrace

## Running tests

    nimble test --silent

## Logging configuration

Available defines:
 * `loglevel`: set a minimum log level to log.
 * `loglevel_channels`: set channels to log (separated by commas) or using a wildcard to specify all.

See the file [``src/nim.cfg``](src/nim.cfg) for defaults.
