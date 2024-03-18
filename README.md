<!--
 Copyright (c) 2024 kraptor
 
 This software is released under the MIT License.
 https://opensource.org/licenses/MIT
-->

# **MinPS** - a wannabe PlayStation 1 emulator

![License](https://img.shields.io/github/license/kraptor/minps?color=olive)
[![made-with-nim](https://img.shields.io/badge/Made%20with-Nim-ffc200.svg)](https://nim-lang.org/)
[![Language](https://img.shields.io/github/languages/top/kraptor/minps?logo=Nim)](https://nim-lang.org/)
![Languages](https://img.shields.io/github/languages/count/kraptor/minps?label=Languages)
![Code Size](https://img.shields.io/github/languages/code-size/kraptor/minps)
![Build](https://github.com/kraptor/minps/workflows/Build/badge.svg)

**NOTE**: the previous version of this repository [was archived in the `old` branch](https://github.com/kraptor/minps/tree/old).

# Build

## Requirements

**MinPS** requires the following software preinstalled:
   * [git](https://git-scm.com/) (any modern versions should do)
   * [nim](https://nim-lang.org/) >= 2.0.2
   * [nimble](https://github.com/nim-lang/nimble) >= 0.14.2

## Release mode

```sh
$ ./build.sh
```

**MinPS** can be built in several modes. To see all possible build modes, use the following command:

```bash
$ nimble -l tasks
```

It's possible to build everything with:

```bash
$ nimble -l build_all
```

## Developer documentation

Generate the documentation locally with:

```bash
$ nimble -l build_docs
```

Then open the generated `htmldocs/minps.html` file in any browser.

# Debug

## Performance (using callgrind)

It's possible to build an optimized version that supports callgrind:

```bash
$ nimble -l run_callgrind
```