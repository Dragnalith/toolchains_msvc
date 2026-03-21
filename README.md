# MSVC toolchain for Bazel [![Build Status](https://github.com/Dragnalith/toolchains_msvc/actions/workflows/test.yml/badge.svg)](https://github.com/Dragnalith/toolchains_msvc/actions/workflows/test.yml)

*This is a prototype; expect the API to change before stabilization.*

## What is this?

`toolchains_msvc` is a Bazel module that provides hermetic, reproducible C++ toolchains for building native Windows applications targeting the MSVC ABI. It downloads MSVC, the Windows SDK, and optionally LLVM directly from official Microsoft and LLVM distribution channels — no prior Visual Studio installation required.

Supported compiler frontends:

* `cl.exe` — the MSVC compiler
* `clang-cl.exe` — Clang in MSVC-compatible mode
* `clang.exe` — Clang targeting the MSVC ABI

All toolchains use the MSVC headers and Windows SDK as their sysroot, and pass deterministic flags to produce reproducible build outputs.

## Disclaimer

This module downloads and uses MSVC and the Windows SDK from Visual Studio Build Tools. By using this module you agree to the Microsoft Visual Studio License Terms: https://visualstudio.microsoft.com/license-terms/

Before MSVC is downloaded, you must set the following environment variable to confirm acceptance:

```
BAZEL_TOOLCHAINS_MSVC_AGREE_WITH_VS_EULA=1
```

If the variable is not set, the build will fail and print the license URL. 

## Quick Start

Add this to your `MODULE.bazel`:

```starlark
bazel_dep(name = "toolchains_msvc", version = "0.1.0")
git_override(
    module_name = "toolchains_msvc",
    remote = "https://github.com/Dragnalith/toolchains_msvc",
    tag = "0.1.0",
)

toolchain = use_extension("@toolchains_msvc//:extensions.bzl", "toolchain")

toolchain.toolchain_set(
    name = "default",
    msvc_versions = ["14.44"],
    winsdk_versions = ["26100"],
)

use_repo(toolchain, "msvc_toolchains")

register_toolchains("@msvc_toolchains//:all")
```

Read the EULA https://visualstudio.microsoft.com/license-terms/, and if you agree, set acceptance environment variable, then build:

```bash
set BAZEL_TOOLCHAINS_MSVC_AGREE_WITH_VS_EULA=1
bazel build //...
```

Or you can set in as bazel command line flag:
```bash
bazel build //... --repo_env=BAZEL_TOOLCHAINS_MSVC_AGREE_WITH_VS_EULA=1
```

## Generated Repositories

The extension creates the aggregate `@msvc_toolchains` repository (name customizable via `toolchain.repo_name(...)`), which contains:

* `//msvc`, `//winsdk`, `//llvm`, `//compiler`, `//toolchain_set` — build setting flags for toolchain selection
* `//lib` — on-demand system library imports (e.g. `@msvc_toolchains//lib:kernel32`)
* `//:all` — registers every generated toolchain
* `//toolchain_set/<name>/...` — per-toolchain-set generated toolchain definitions

## Toolchain Sets

`toolchain.toolchain_set(...)` is the main configuration entry point. Each declaration produces a set of toolchains from the cross-product of host platform, target platform, MSVC version, Windows SDK version, optional LLVM version, and compiler frontend.

```starlark
toolchain.toolchain_set(
    name = "default",           # required, unique identifier
    hosts = ["x64"],            # optional; defaults to BAZEL_TOOLCHAINS_MSVC_HOSTS or x64
    targets = ["x64"],          # optional; defaults to BAZEL_TOOLCHAINS_MSVC_TARGETS or x64
    msvc_versions = ["14.44"],
    winsdk_versions = ["26100"],
    llvm_versions = ["22.1.0"], # optional; enables clang-cl and clang toolchains
    features = [],              # default features enabled for this set
    dbg_features = [],          # extra features for -c dbg
    fastbuild_features = [],    # extra features for -c fastbuild
    opt_features = [],          # extra features for -c opt
)
```

Multiple toolchain sets can coexist. To select the default one, add:

```starlark
toolchain.default_toolchain_set(name = "default")
```

If omitted, the first declared `toolchain_set` becomes the default.

### Global Defaults

The aggregate repo exposes one global default for each dimension. Configure them alongside `toolchain_set` (not inside it):

```starlark
toolchain.default_msvc_version(version = "14.44")
toolchain.default_llvm_version(version = "22.1.0")
toolchain.default_winsdk_version(version = "26100")
toolchain.default_compiler(compiler = "msvc-cl")  # msvc-cl | clang-cl | clang
```

If a tag is omitted, the default is the first version listed across all `toolchain_set` declarations. The compiler defaults to `msvc-cl`.

## Toolchain Selection Flags

The generated repo exposes build setting flags to override the active toolchain at build time:

* `--@msvc_toolchains//toolchain_set=<name>`
* `--@msvc_toolchains//msvc:msvc=<msvc-version>`
* `--@msvc_toolchains//winsdk:winsdk=<winsdk-version>`
* `--@msvc_toolchains//llvm:llvm=<llvm-version>`
* `--@msvc_toolchains//compiler:compiler=msvc-cl|clang-cl|clang`

All settings have defaults, so `bazel build //...` works with no extra flags.

Example:

```bash
bazel build ^
  --@msvc_toolchains//toolchain_set=default ^
  --@msvc_toolchains//msvc:msvc=14.44 ^
  --@msvc_toolchains//winsdk:winsdk=26100 ^
  --@msvc_toolchains//compiler:compiler=clang-cl ^
  //...
```

## Features

The toolchains expose semantic Bazel features that can be enabled per target or per toolchain set. Key features:

| Feature | Effect |
| --- | --- |
| `treat_warnings_as_errors` | Promotes all warnings to errors (compile only) |
| `generate_debug_symbols` | Generates debug info for compile and link actions |
| `static_runtime` | Links against the static CRT (`/MT` / `/MTd`) instead of the DLL CRT |
| `debug_runtime` | Links against the debug CRT (`/MDd` / `/MTd`); defines `_DEBUG` |
| `thinlto` | Thin LTO (`/GL` + `/LTCG` for cl/clang-cl, `-flto=thin` for clang) |
| `fulllto` | Full LTO (same flags for cl/clang-cl, `-flto` for clang) |
| `window_subsystem` | Sets `/SUBSYSTEM:WINDOWS` (GUI, no console) |
| `console_subsystem` | Sets `/SUBSYSTEM:CONSOLE` explicitly |
| `cxx_standard_14` / `17` / `20` / `23` / `26` / `latest` | Sets the C++ language standard; mutually exclusive |

See [`docs/Features.md`](docs/Features.md) for full details.

## Customizing Flags

Each toolchain set accepts flag lists that either replace or extend the built-in defaults, per compilation mode and compiler family:

```starlark
toolchain.toolchain_set(
    name = "default",
    msvc_versions = ["14.44"],
    winsdk_versions = ["26100"],
    # Replace the default cl.exe flags for opt mode:
    cl_opt_copt = ["/O2", "/Ob3", "/Zc:__cplusplus"],
    # Append extra flags without replacing defaults:
    add_cl_cxxopt = ["/permissive-"],
    # Same for clang:
    add_clang_opt_copt = ["-ffast-math"],
)
```

The pattern is `[add_]<compiler>_<mode>_<copt|cxxopt|linkopt>`:
* `cl_*` applies to `cl.exe` and `clang-cl.exe`
* `clang_*` applies to `clang.exe`
* Omitting `add_` replaces the built-in default list; prefixing with `add_` appends to it

## System Libraries

System libraries are **not** bundled as toolchain dependencies. They are on-demand `cc_import` targets. This avoids uploading ~600 MB of libraries for every remote execution action when most targets only need a handful.

Declare them as regular `deps`:

```starlark
cc_binary(
    name = "my_app",
    srcs = ["main.cc"],
    deps = [
        "@msvc_toolchains//lib:kernel32",
        "@msvc_toolchains//lib:user32",
    ],
)
```

Each alias resolves to the correct library for the Windows SDK version selected at build time.

## Lock File (Reproducible Pinning)

To pin every downloaded artifact to a known SHA-256 and make fetches fully reproducible, add a lock file:

```starlark
toolchain.lock(file = "//:toolchains_msvc.json.lock")
```

Generate or refresh the lock file after any version change:

```bash
bazel run @toolchains_msvc//:pin
```

The repository rule will then fail if a downloaded package does not match the recorded hash.

## `cl_with_lld_version`

`cl_with_lld_version` makes an MSVC (`cl.exe`) toolchain set use `lld-link.exe` as its linker. This enables fully deterministic PDB files, which `link.exe` cannot produce.

```starlark
toolchain.toolchain_set(
    name = "default",
    msvc_versions = ["14.44"],
    winsdk_versions = ["26100"],
    cl_with_lld_version = "22.1.0",
)
```

Notes:
* `cl_with_lld_version` is validated against the same allowed LLVM release list as `llvm_versions`
* it is legal to specify it without any `llvm_versions`
* `clang` and `clang-cl` toolchains are generated only from `llvm_versions`, not from `cl_with_lld_version`

## Custom Repo Name

The generated aggregate repository is named `msvc_toolchains` by default. To change it:

```starlark
toolchain.repo_name(name = "my_toolchains")

use_repo(toolchain, "my_toolchains")
register_toolchains("@my_toolchains//:all")
```

## Environment Variables

| Variable | Effect |
| --- | --- |
| `BAZEL_TOOLCHAINS_MSVC_HOSTS` | Comma-separated default host list when `hosts` is omitted on a toolchain set |
| `BAZEL_TOOLCHAINS_MSVC_TARGETS` | Comma-separated default target list when `targets` is omitted |

## Supported Versions

The following values are available at the time of writing (actual available values are fetched dynamically):

| Parameter | Supported Values |
| --- | --- |
| `hosts` / `targets` | `x86`, `x64`, `arm64` |
| `msvc_versions` | `14.29`, `14.30`, `14.31`, `14.32`, `14.33`, `14.34`, `14.35`, `14.36`, `14.37`, `14.38`, `14.39`, `14.40`, `14.41`, `14.42`, `14.43`, `14.44`, `14.50`, `14.51` |
| `winsdk_versions` | `19041`, `22621`, `26100` |
| `llvm_versions` | `20.1.7`, `20.1.8`, `21.1.0`, `21.1.1`, `21.1.2`, `21.1.3`, `21.1.4`, `21.1.5`, `21.1.6`, `21.1.7`, `21.1.8`, `22.1.0`, `22.1.1` |

> **Note:** ARM64 host support requires MSVC version 14.33 or later.

## Further Reading

* [`docs/Features.md`](docs/Features.md) — all semantic toolchain features
* [`docs/ToolchainExtension.md`](docs/ToolchainExtension.md) — full extension API reference
* [`docs/Reproducibility.md`](docs/Reproducibility.md) — how hermeticity and determinism are achieved
