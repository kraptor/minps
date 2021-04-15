# minps - a wannabe PlayStation 1 emulator

## Building instructions

``minps`` can be compiled in different flavors using ``nimble``:

### Debug build
    nimble build_debug

### Profile build
    nimble build_profiler

### Release build
    nimble build_release

> :information_source: **NOTE**
>
>``minps`` uses ``nim-chronicles`` for logging. Use any of it's configuration options to change the default logging behavior in ``src/nim.cfg``