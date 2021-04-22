# minps

`minps` - a wannabe PlayStation 1 emulator

[![made-with-python](https://img.shields.io/badge/Made%20with-Nim-ffc200.svg)](https://nim-lang.org/) ![build + tests](https://github.com/kraptor/minps/actions/workflows/ci.yml/badge.svg) 

## Building instructions

``minps`` can be compiled in different flavors using ``nimble``.

Debug build: 

    nimble build_debug```

Profiler build

    nimble build_profiler

Profiler build (memory)

    nimble build_profiler_memory

Release build

    nimble build_release

Release build (with stacktrace support)

    nimble build_release_stacktrace

## Running tests

    nimble test --silent

## Logging configuration
``minps`` uses [nim-chronicles](https://github.com/status-im/nim-chronicles) for logging. Use any of it's configuration options to change the default logging behavior. To do so, edit the file [``src/nim.cfg``](src/nim.cfg)