# Plumbing Features

| feature                       | source    | action      |
|-------------------------------|-----------|-------------|
| `no_legacy_features`          | toolchain |             |
| `compiler_input_flags`        | toolchain | compile     |
| `compiler_output_flags`       | toolchain | compile     |
| `dependency_file`             | toolchain | compile     |
| `linker_input`                | toolchain | link        |
| `output_execpath_flags`       | toolchain | link        |
| `linker_param_file`           | toolchain | link        |
| `archiver_input`              | toolchain | archive     |
| `archiver_output`             | toolchain | archive     |
| `strip_input`                 | toolchain | strip       |
| `strip_output`                | toolchain | strip       |

# Header Dependency Discovery

| feature                       | compiler        |
|-------------------------------|-----------------|
| `parse_showincludes`          | cl              |
| `no_dotd_file`                | cl              |
| `dependency_file`             | clang,clang-cl  |

# Toolchain Policy Defaults

| feature                       | source    | action   |
|-------------------------------|-----------|----------|
| `default_compile_flags`       | default   | compile  |
| `default_cxx_compile_flags`   | default   | compile  |
| `default_c_compile_flags`     | default   | compile  |
| `default_assemble_flags`      | default   | assemble |
| `default_link_flags`          | default   | link     |
| `default_archive_flags`       | default   | archive  |
| `default_strip_flags`         | default   | strip    |

# Rule-Level Passthrough

| feature                       | source    | action  |
|-------------------------------|-----------|---------|
| `user_compile_flags`          | copts     | compile |
| `user_compile_defines`        | defines   | compile |
| `includes`                    | includes  | compile |
| `user_link_flags`             | linkopts  | link    |

# Configuration (Mode-Driven)

## Umbrella Mode Features

| feature     | source    | action       |
|-------------|-----------|--------------|
| `dbg`       | dbg       | compile,link |
| `fastbuild` | fastbuild | compile,link |
| `opt`       | opt       | compile,link |

# Semantic Option Features

## Diagnostics

- `treat_warnings_as_errors`

## Debug Information

- `generate_debug_symbols`

## Runtime Linkage

- `static_runtime`
- `debug_runtime`

## Subsystem

- `window_subsystem`

## Optimization Technologies

- `thinlto`
- `fulllto`
- `fdo_instrument`
- `fdo_optimize`

## Language Standard

- `cxx_standard_14`
- `cxx_standard_17`
- `cxx_standard_20`
- `cxx_standard_23`
- `cxx_standard_26`
