# MSVC toolchain for Bazel [![Build Status](https://github.com/Dragnalith/toolchains_msvc/actions/workflows/build.yml/badge.svg)](https://github.com/Dragnalith/toolchains_msvc/actions/workflows/build.yml)

*This is a prototype; expect the API to change before stabilization*

## Disclaimer

This toolchain downloads and uses MSVC and the Windows SDK from Visual Studio Build Tools. By using this toolchain, you agree to the Microsoft Visual Studio License Terms: https://visualstudio.microsoft.com/license-terms/

## Description

This module provides a C++ toolchain for `rules_cc` using the official MSVC compiler and Windows SDK.

The toolchain ensures that only packages belonging to the `Microsoft.VisualStudio.Product.BuildTools` product are downloaded by checking the Visual Studio channel manifest.

It generates:
*   `@msvc_{version}` for each requested MSVC version
*   `@winsdk_{version}` for each requested Windows SDK version
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

toolchain = use_extension("@toolchains_msvc//extensions:toolchain.bzl", "toolchain")

toolchain.msvc_compiler(version = "14.50")
toolchain.msvc_compiler(version = "14.44")
toolchain.windows_sdk(version = "26100")
toolchain.windows_sdk(version = "19041")
toolchain.target(arch = "x86")
toolchain.target(arch = "x64")
toolchain.target(arch = "arm64")
toolchain.host(arch = "x86")
toolchain.host(arch = "x64")
toolchain.host(arch = "arm64")

use_repo(toolchain, "msvc_toolchains")

register_toolchains("@msvc_toolchains//:msvc_14.44_winsdk19041_hostx64_target_x64")
```

This registers toolchains for all combinations of the declared targets, SDK versions, and compiler versions.

## Toolchain Selection

The toolchain name follows this pattern:
`@msvc_toolchains//:msvc_<msvc-version>_winsdk<winsdk-version>_host<host-arch>_target<target-arch>`

Currently supported values are:

| Parameter | Supported Values |
| --- | --- |
| `host` | `x86`, `x64`, `arm64` |
| `target` | `x86`, `x64`, `arm64` |
| `msvc-version` | `14.29`, `14.30`, `14.31`, `14.32`, `14.33`, `14.34`, `14.35`, `14.36`, `14.37`, `14.38`, `14.39`, `14.40`, `14.41`, `14.42`, `14.43`, `14.44`, `14.50` |
| `winsdk-version` | `19041`, `22621`, `26100` |

The toolchain can be selected with `register_toolchains(...)` in your `MODULE.bazel` file. It can also be overridden without changing the `MODULE.bazel` by using the `--extra_toolchains` flag on the command line (e.g. `bazel build --extra_toolchains=@msvc_toolchains//:msvc_14.50_winsdk26100_hostx64_target_x64 //...`).
