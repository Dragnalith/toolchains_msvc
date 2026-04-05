# Semantic Option Features

User-facing features that can be enabled to change toolchain behavior.

## Diagnostics

### `treat_warnings_as_errors`

Promotes all compiler warnings to errors. Applies to compile actions only.

## Debug Information

### `generate_debug_symbols`

Generates debug information for compile and link actions.

## Runtime Linkage

`static_runtime` and `debug_runtime` are independent and combinable:

| `static_runtime` | `debug_runtime` | CRT flag |
|-----------------|----------------|----------|
| off             | off            | `/MD`    |
| on              | off            | `/MT`    |
| off             | on             | `/MDd`   |
| on              | on             | `/MTd`   |

### `static_runtime`

Links against the static CRT instead of the DLL CRT.

### `debug_runtime`

Links against the debug CRT variant. Also defines `_DEBUG`.

## Subsystem

`window_subsystem` and `console_subsystem` are mutually exclusive. When neither is active the default is console (no explicit `/SUBSYSTEM` flag).

### `window_subsystem`

Sets `/SUBSYSTEM:WINDOWS` (GUI application, no console window).

### `console_subsystem`

Sets `/SUBSYSTEM:CONSOLE` (console application). Explicit alternative to the implicit default.

## Optimization Technologies

`thinlto` and `fulllto` are mutually exclusive.

### `thinlto`

Enables Thin Link-Time Optimization. Adds `/GL` at compile time and `/LTCG` at link time (cl/clang-cl). Uses `-flto=thin` for clang.

### `fulllto`

Enables Full Link-Time Optimization. Same flags as `thinlto` for cl/clang-cl (`/GL` + `/LTCG`). Uses `-flto` for clang.

## Language Standard

All `cxx_standard_*` features are mutually exclusive. No default is applied; without one the compiler's built-in default is used.

| Feature              | cl/clang-cl flag | clang flag        |
|----------------------|------------------|-------------------|
| `cxx_standard_14`    | `/std:c++14`     | `-std=c++14`      |
| `cxx_standard_17`    | `/std:c++17`     | `-std=c++17`      |
| `cxx_standard_20`    | `/std:c++20`     | `-std=c++20`      |
| `cxx_standard_23`    | `/std:c++23`     | `-std=c++23`      |
| `cxx_standard_26`    | `/std:c++26`     | `-std=c++26`      |
| `cxx_standard_latest`| `/std:c++latest` | `-std=c++2c`      |
