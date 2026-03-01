# MSVC toolchain for Bazel [![Build Status](https://github.com/Dragnalith/toolchains_msvc/actions/workflows/build.yml/badge.svg)](https://github.com/Dragnalith/toolchains_msvc/actions/workflows/build.yml)

*This is a prototype; expect the API to change before stabilization*

## Disclaimer

This toolchain downloads and uses MSVC and the Windows SDK from Visual Studio Build Tools. By using this toolchain, you agree to the Microsoft Visual Studio License Terms: https://visualstudio.microsoft.com/license-terms/

## Description

This module provides C++ hermetic toolchains for `rules_cc` targeting MSVC ABI. It supports cl.exe, clang-cl.exe and clang.exe.

The toolchain ensures that only packages belonging to the `Microsoft.VisualStudio.Product.BuildTools` product are downloaded by checking the Visual Studio channel manifest.

It generates:
*   `@msvc_{version}` for each requested MSVC version
*   `@winsdk_{version}` for each requested Windows SDK version
*   `@llvm_{version}_{host}` for each requested Clang version and host architecture
*   `@msvc_toolchains` containing all toolchain definitions

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

toolchain.msvc_compiler(version = "14.44")
toolchain.msvc_compiler(version = "14.50")
toolchain.clang_compiler(version = "20.1.0")
toolchain.clang_compiler(version = "22.1.0")
toolchain.windows_sdk(version = "26100")
toolchain.windows_sdk(version = "19041")
toolchain.target(arch = "x64")
toolchain.target(arch = "x86")
toolchain.target(arch = "arm64")
toolchain.host(arch = "x64")

use_repo(toolchain, "msvc_toolchains")

register_toolchains("@msvc_toolchains//:msvc14.44_winsdk26100_hostx64_targetx64")
```

## Toolchain Selection

The toolchain can be selected with `register_toolchains(...)` in your `MODULE.bazel` file. It can also be overridden without changing the `MODULE.bazel` by using the `--extra_toolchains` flag on the command line (e.g. `bazel build --extra_toolchains=@msvc_toolchains//:msvc14.50_winsdk26100_hostx64_target_x64 //...`).

MSVC toolchain names follow this pattern:
`@msvc_toolchains//:msvc<msvc-version>_winsdk<winsdk-version>_host<host-arch>_target<target-arch>`

Clang toolchain names follow this pattern:
`@msvc_toolchains//:clang<clang-version>_msvc<msvc-version>_winsdk<winsdk-version>_host<host-arch>_target<target-arch>`

Clang toolchains use the MSVC "sysroot", so they require both a `clang_compiler` version and an `msvc_compiler` version to be declared.

At the time of writing this README, the following values are available (the actual available values are fetched dynamically at build time from the Visual Studio channel manifest and the LLVM GitHub releases):

| Parameter | Supported Values |
| --- | --- |
| `host` | `x86`, `x64`, `arm64` |
| `target` | `x86`, `x64`, `arm64` |
| `msvc-version` | `14.29`, `14.30`, `14.31`, `14.32`, `14.33`, `14.34`, `14.35`, `14.36`, `14.37`, `14.38`, `14.39`, `14.40`, `14.41`, `14.42`, `14.43`, `14.44`, `14.50` |
| `winsdk-version` | `19041`, `22621`, `26100` |
| `clang-version` | `20.1.0`, `20.1.1`, `20.1.2`, `20.1.3`, `20.1.4`, `20.1.5`, `20.1.6`, `20.1.7`, `20.1.8`, `21.1.0`, `21.1.1`, `21.1.2`, `21.1.3`, `21.1.4`, `21.1.5`, `21.1.6`, `21.1.7`, `21.1.8`, `22.1.0` |

> **Note:** ARM64 host support requires MSVC version 14.33 or later.
