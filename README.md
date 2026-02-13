# MSVC toolchain for Bazel

*This is a prototype; expect the API to change before stabilization*

## Disclaimer

This toolchain downloads and uses MSVC and the Windows SDK from Visual Studio Build Tools. By using this toolchain, you agree to the Microsoft Visual Studio License Terms: https://visualstudio.microsoft.com/license-terms/

## Description

This module provides a C++ toolchain for `rules_cc` using the official MSVC compiler and Windows SDK.

The toolchain ensures that only packages belonging to the `Microsoft.VisualStudio.Product.BuildTools` product are downloaded by checking the Visual Studio channel manifest.

It generates:
*   `@msvc_<version>` for each requested MSVC version
*   `@winsdk_<version>` for each requested Windows SDK version
*   `@msvc_toolchains` containing all toolchain definitions

## Usage

Add this to your `MODULE.bazel`:

```starlark
bazel_dep(name = "toolchains_msvc", version = "0.1.0")
git_override(
    module_name = "toolchains_msvc",
    remote = "https://github.com/mdelorme/toolchains_msvc",
    tag = "0.1.0",
)

toolchain = use_extension("@toolchains_msvc//extensions:toolchain.bzl", "toolchain")

toolchain.license_agreement(agree = True)
toolchain.msvc_compiler(version = "14.44.17.14")
toolchain.msvc_compiler(version = "14.50.18.0")
toolchain.windows_sdk(version = "19041")
toolchain.windows_sdk(version = "26100")
toolchain.target(arch = "x86_64")
toolchain.target(arch = "x86_32")
toolchain.target(arch = "aarch64")

use_repo(toolchain, "msvc_toolchains")

register_toolchains("@msvc_toolchains//:all")
```

This registers toolchains for all combinations of the declared targets, SDK versions, and compiler versions.
