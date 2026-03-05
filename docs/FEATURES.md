# Plumbing Features

| feature                       | source    | action      |
|-------------------------------|-----------|-------------|
| `no_legacy_features`          | toolchain |             |
| `compiler_input_flags`        | toolchain | compile     |
| `compiler_output_flags`       | toolchain | compile     |
| `include_paths`               | toolchain | compile     |
| `external_include_paths`      | toolchain | compile     |
| `preprocessor_defines`        | toolchain | compile     |
| `dependency_file`             | toolchain | compile     |
| `linker_input`                | toolchain | link        |
| `libraries_to_link`           | toolchain | link        |
| `library_search_directories`  | toolchain | link        |
| `output_execpath_flags`       | toolchain | link        |
| `linker_param_file`           | toolchain | link        |
| `archiver_input`              | toolchain | archive     |
| `archiver_flags`              | toolchain | archive     |
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
| `default_link_libs`           | default   | link     |

# Rule-Level Passthrough

| feature                       | source    | action  |
|-------------------------------|-----------|---------|
| `user_compile_flags`          | copts     | compile |
| `user_compile_defines`        | defines   | compile |
| `includes`                    | includes  | compile |
| `user_system_include_paths`   | includes  | compile |
| `user_link_flags`             | linkopts  | link    |

# Configuration (Mode-Driven)

## Umbrella Mode Features

| feature     | source    | action       |
|-------------|-----------|--------------|
| `dbg`       | dbg       | compile,link |
| `fastbuild` | fastbuild | compile,link |
| `opt`       | opt       | compile,link |

## Fine-Grain Mode Flags

| feature                    | source    | action  |
|----------------------------|-----------|---------|
| `dbg_compile_flags`        | dbg       | compile |
| `fastbuild_compile_flags`  | fastbuild | compile |
| `opt_compile_flags`        | opt       | compile |
| `dbg_link_flags`           | dbg       | link    |
| `fastbuild_link_flags`     | fastbuild | link    |
| `opt_link_flags`           | opt       | link    |

# Semantic Option Features

## Diagnostics

- `treat_warnings_as_errors`

## Debug Information

- `generate_debug_symbols`

## Runtime Linkage

- `dynamic_link_msvcrt`
- `static_link_msvcrt`
- `debug_runtime`

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
