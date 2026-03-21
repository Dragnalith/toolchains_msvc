# MSVC toolchain for Bazel [![Build Status](https://github.com/Dragnalith/toolchains_msvc/actions/workflows/test.yml/badge.svg)](https://github.com/Dragnalith/toolchains_msvc/actions/workflows/test.yml)

*This is a prototype; expect the API to change before stabilization*

## Disclaimer

This toolchain downloads and uses MSVC and the Windows SDK from Visual Studio Build Tools. By using this toolchain, you agree to the Microsoft Visual Studio License Terms: https://visualstudio.microsoft.com/license-terms/

## Quick Start

Add this to your `MODULE.bazel`:

```starlark
bazel_dep(name = "toolchains_msvc", version = "0.1.0")
git_override(
    module_name = "toolchains_msvc",
    remote = "https://github.com/mdelorme/toolchains_msvc",
    tag = "0.1.0",
)

toolchain = use_extension("@toolchains_msvc//:extensions.bzl", "toolchain")

toolchain.toolchain_set(
    msvc_versions = ["14.44"],
    winsdk_versions = ["26100"],
)

use_repo(toolchain, "msvc_toolchains")

register_toolchains("@msvc_toolchains//:all")
```

## Description

This module provides hermetic C++ toolchains for `rules_cc` targeting the MSVC ABI on Windows. It supports:

* `cl.exe`
* `clang-cl.exe`
* `clang.exe`

The extension validates MSVC and Windows SDK versions against the Visual Studio channel manifest, and validates LLVM versions against published LLVM releases.

It generates:

* `@msvc_<version>` for each requested MSVC version
* `@winsdk_<version>` for each requested Windows SDK version
* `@llvm_<version>_<host>` for each requested LLVM version and host architecture
* `@msvc_toolchains` containing build flags, library targets, and toolchain registrations

Inside `@msvc_toolchains`:

* `//winsdk`, `//msvc`, `//llvm`, `//compiler`, and `//toolchain_set` expose build setting flags
* `//lib` exposes import libraries such as `@msvc_toolchains//lib:kernel32`
* `//:all` registers every generated toolchain
* `//toolchain_set/<name>/...` contains the per-toolchain-set generated toolchain definitions

## Features

### Distribution Management

* Downloads MSVC, Windows SDK, and LLVM artifacts on demand
* Creates one external repo per unique MSVC, WinSDK, and LLVM version
* Supports multiple independently configured toolchain sets in the same generated repo

### Toolchain Selection

* Toolchain registration can be broad with `register_toolchains("@msvc_toolchains//:all")`
* Toolchain resolution can be controlled with build flags for toolchain set, MSVC version, WinSDK version, LLVM version, and compiler kind

### Customization

* Per-toolchain-set defaults for MSVC, WinSDK, and LLVM
* Per-toolchain-set feature implication lists for default, `dbg`, `fastbuild`, and `opt`
* Per-toolchain-set compile and link flag replacement or extension
* Optional `cl_with_lld_version` support to use `cl.exe` with `lld-link.exe`

### Reproducibility

* Uses wrapper scripts and deterministic compiler and linker options
* Normalizes generated toolchain layout and configuration through Bazel build settings
* Clang toolchains reuse the selected MSVC and WinSDK sysroot rather than host-installed tools

## Toolchain Sets

`toolchain.toolchain_set(...)` is the main configuration entry point.

Each toolchain set:

* must have a unique `name`
* generates its toolchains under `@msvc_toolchains//toolchain_set/<name>/...`
* prefixes every generated root toolchain target with `<name>_`
* can have independent version lists, features, and flags

If multiple toolchain sets are declared, choose the default set with:

```starlark
toolchain.default_toolchain_set(name = "default")
```

If `default_toolchain_set(...)` is omitted, the first declared `toolchain_set(...)` becomes the default.

The generated repo has one global default each for MSVC, LLVM, WinSDK, and compiler (the `//msvc`, `//llvm`, `//winsdk`, and `//compiler` build settings). Configure them with tags alongside `toolchain_set` (not inside it):

```starlark
toolchain.default_msvc_version(version = "14.44")
toolchain.default_llvm_version(version = "22.1.0")
toolchain.default_winsdk_version(version = "26100")
toolchain.default_compiler(compiler = "msvc-cl")
```

If a tag is omitted, the default is the first version listed across all `toolchain_set` declarations (for LLVM, the first LLVM version in use, or empty when no LLVM is configured). The compiler defaults to `msvc-cl`. Each chosen version must appear in the union of versions declared across toolchain sets.

## Selection Flags

The generated repo exposes build setting flags that influence toolchain resolution:

* `--@msvc_toolchains//toolchain_set=<toolchain-set-name>`
* `--@msvc_toolchains//msvc:msvc=<msvc-version>`
* `--@msvc_toolchains//winsdk:winsdk=<winsdk-version>`
* `--@msvc_toolchains//llvm:llvm=<llvm-version>`
* `--@msvc_toolchains//compiler:compiler=msvc-cl|clang-cl|clang`

Example:

```powershell
bazel build ^
  --@msvc_toolchains//toolchain_set=default ^
  --@msvc_toolchains//msvc:msvc=14.44 ^
  --@msvc_toolchains//winsdk:winsdk=26100 ^
  --@msvc_toolchains//compiler:compiler=msvc-cl ^
  //...
```

Register every generated toolchain and rely on the flags:

```starlark
register_toolchains("@msvc_toolchains//:all")
```

Clang and clang-cl toolchains use the selected MSVC and WinSDK sysroot, so they require both an LLVM version and an MSVC version.

## `cl_with_lld_version`

`cl_with_lld_version` lets an MSVC toolchain set use `cl.exe` with `lld-link.exe`.

Example:

```starlark
toolchain.toolchain_set(
    name = "default",
    hosts = ["x64"],
    targets = ["x64"],
    msvc_versions = ["14.44"],
    winsdk_versions = ["26100"],
    cl_with_lld_version = "22.1.0",
)
```

Notes:

* `cl_with_lld_version` is validated against the same allowed LLVM release list as `llvm_versions`
* it is legal to specify `cl_with_lld_version` without any `llvm_versions`
* adding `cl_with_lld_version` still creates the corresponding `@llvm_<version>_<host>` repos
* clang and clang-cl toolchains are only generated from `llvm_versions`, not from `cl_with_lld_version`

At the time of writing this README, the following values are available (the actual available values are fetched dynamically at build time from the Visual Studio channel manifest and the LLVM GitHub releases):

| Parameter | Supported Values |
| --- | --- |
| `host` | `x86`, `x64`, `arm64` |
| `target` | `x86`, `x64`, `arm64` |
| `msvc_versions` | `14.29`, `14.30`, `14.31`, `14.32`, `14.33`, `14.34`, `14.35`, `14.36`, `14.37`, `14.38`, `14.39`, `14.40`, `14.41`, `14.42`, `14.43`, `14.44`, `14.50` |
| `winsdk_versions` | `19041`, `22621`, `26100` |
| `llvm_versions` | `20.1.0`, `20.1.1`, `20.1.2`, `20.1.3`, `20.1.4`, `20.1.5`, `20.1.6`, `20.1.7`, `20.1.8`, `21.1.0`, `21.1.1`, `21.1.2`, `21.1.3`, `21.1.4`, `21.1.5`, `21.1.6`, `21.1.7`, `21.1.8`, `22.1.0` |

> **Note:** ARM64 host support requires MSVC version 14.33 or later.
