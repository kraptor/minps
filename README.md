# minps - a wannabe PlayStation 1 emulator

## Building instructions

``minps`` can be compiled in different flavors using ``nimble``:

### Debug build
    nimble build_debug

### Profiler build
    nimble build_profiler

### Profiler build (memory)
    nimble build_profiler_memory

### Release build
    nimble build_release

### Release build (with stacktrace support)
    nimble build_release_stacktrace

## Running tests
    nimble test --silent

## Logging configuration
``minps`` uses [nim-chronicles](https://github.com/status-im/nim-chronicles) for logging. Use any of it's configuration options to change the default logging behavior in ``src/nim.cfg``