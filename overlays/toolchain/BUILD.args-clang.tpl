load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:nested_args.bzl", "cc_nested_args")

package(default_visibility = ["//visibility:public"])

# === Plumbing Features ===

cc_args(
    name = "compiler_input_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "-c",
        "{source_file}",
    ],
    format = {"source_file": "@rules_cc//cc/toolchains/variables:source_file"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:source_file",
)

cc_args(
    name = "compiler_output_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = [
        "-o",
        "{output_file}",
    ],
    format = {"output_file": "@rules_cc//cc/toolchains/variables:output_file"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:output_file",
)

cc_args(
    name = "linker_input",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    nested = [":linker_libraries_to_link_args"],
    requires_not_none = "@rules_cc//cc/toolchains/variables:libraries_to_link",
)

cc_nested_args(
    name = "linker_libraries_to_link_args",
    iterate_over = "@rules_cc//cc/toolchains/variables:libraries_to_link",
    nested = [
        ":link_object_file_group",
        ":link_object_file",
        ":link_interface_library",
        ":link_static_library",
        ":link_dynamic_library",
    ],
)

cc_nested_args(
    name = "link_object_file_group",
    args = ["{object_files}"],
    format = {"object_files": "@rules_cc//cc/toolchains/variables:libraries_to_link.object_files"},
    iterate_over = "@rules_cc//cc/toolchains/variables:libraries_to_link.object_files",
    requires_equal = "@rules_cc//cc/toolchains/variables:libraries_to_link.type",
    requires_equal_value = "object_file_group",
)

cc_nested_args(
    name = "link_object_file",
    args = ["{object_file}"],
    format = {"object_file": "@rules_cc//cc/toolchains/variables:libraries_to_link.name"},
    requires_equal = "@rules_cc//cc/toolchains/variables:libraries_to_link.type",
    requires_equal_value = "object_file",
)

cc_nested_args(
    name = "link_interface_library",
    args = ["{library}"],
    format = {"library": "@rules_cc//cc/toolchains/variables:libraries_to_link.name"},
    requires_equal = "@rules_cc//cc/toolchains/variables:libraries_to_link.type",
    requires_equal_value = "interface_library",
)

cc_nested_args(
    name = "link_static_library",
    args = ["{library}"],
    format = {"library": "@rules_cc//cc/toolchains/variables:libraries_to_link.name"},
    requires_equal = "@rules_cc//cc/toolchains/variables:libraries_to_link.type",
    requires_equal_value = "static_library",
)

cc_nested_args(
    name = "link_dynamic_library",
    args = ["{library}"],
    format = {"library": "@rules_cc//cc/toolchains/variables:libraries_to_link.name"},
    requires_equal = "@rules_cc//cc/toolchains/variables:libraries_to_link.type",
    requires_equal_value = "dynamic_library",
)

cc_args(
    name = "output_execpath_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["/OUT:{output_execpath}"],
    format = {"output_execpath": "@rules_cc//cc/toolchains/variables:output_execpath"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:output_execpath",
)

cc_args(
    name = "param_file_args",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
        "@rules_cc//cc/toolchains/actions:ar_actions",
    ],
    args = ["@{param_file}"],
    format = {"param_file": "@rules_cc//cc/toolchains/variables:linker_param_file"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:linker_param_file",
)

cc_args(
    name = "archiver_output",
    actions = ["@rules_cc//cc/toolchains/actions:ar_actions"],
    args = ["/OUT:{output_execpath}"],
    format = {"output_execpath": "@rules_cc//cc/toolchains/variables:output_execpath"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:output_execpath",
)

cc_args(
    name = "archiver_input",
    actions = ["@rules_cc//cc/toolchains/actions:ar_actions"],
    nested = [":archiver_libraries_to_link_iterate"],
    requires_not_none = "@rules_cc//cc/toolchains/variables:libraries_to_link",
)

cc_nested_args(
    name = "archiver_libraries_to_link_iterate",
    iterate_over = "@rules_cc//cc/toolchains/variables:libraries_to_link",
    nested = [
        ":archiver_link_obj_file",
        ":archiver_link_object_file_group",
    ],
)

cc_nested_args(
    name = "archiver_link_obj_file",
    args = ["{object_file}"],
    format = {"object_file": "@rules_cc//cc/toolchains/variables:libraries_to_link.name"},
    requires_equal = "@rules_cc//cc/toolchains/variables:libraries_to_link.type",
    requires_equal_value = "object_file",
)

cc_nested_args(
    name = "archiver_link_object_file_group",
    args = ["{object_files}"],
    format = {"object_files": "@rules_cc//cc/toolchains/variables:libraries_to_link.object_files"},
    iterate_over = "@rules_cc//cc/toolchains/variables:libraries_to_link.object_files",
    requires_equal = "@rules_cc//cc/toolchains/variables:libraries_to_link.type",
    requires_equal_value = "object_file_group",
)

cc_args(
    name = "strip_input",
    actions = ["@rules_cc//cc/toolchains/actions:strip"],
    args = [],
)

cc_args(
    name = "strip_output",
    actions = ["@rules_cc//cc/toolchains/actions:strip"],
    args = [],
)

# === Header Dependency Discovery ===

cc_args(
    name = "parse_showincludes",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [],
)

cc_args(
    name = "dependency_file",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile",
    ],
    args = [
        "-MD",
        "-MF",
        "{dependency_file}",
    ],
    format = {"dependency_file": "@rules_cc//cc/toolchains/variables:dependency_file"},
    requires_not_none = "@rules_cc//cc/toolchains/variables:dependency_file",
)

# === Toolchain Policy Defaults ===

cc_args(
    name = "default_cxx_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_compile_actions"],
    args = [],
)

cc_args(
    name = "default_c_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:c_compile"],
    args = [],
)

cc_args(
    name = "default_assemble_flags",
    actions = ["@rules_cc//cc/toolchains/actions:assembly_actions"],
    args = [],
)

cc_args(
    name = "default_link_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "kernel32.lib",
    ],
)

cc_args(
    name = "default_archive_flags",
    actions = ["@rules_cc//cc/toolchains/actions:ar_actions"],
    args = [],
)

cc_args(
    name = "default_strip_flags",
    actions = ["@rules_cc//cc/toolchains/actions:strip"],
    args = [],
)

# === Rule-Level Passthrough ===

cc_args(
    name = "user_compile_flags",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = ["{flag}"],
    format = {"flag": "@rules_cc//cc/toolchains/variables:user_compile_flags"},
    iterate_over = "@rules_cc//cc/toolchains/variables:user_compile_flags",
    requires_not_none = "@rules_cc//cc/toolchains/variables:user_compile_flags",
)

cc_args(
    name = "user_compile_defines",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = ["-D{define}"],
    format = {"define": "@rules_cc//cc/toolchains/variables:preprocessor_defines"},
    iterate_over = "@rules_cc//cc/toolchains/variables:preprocessor_defines",
)

cc_args(
    name = "includes",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [],
)

cc_args(
    name = "user_link_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["{user_link_flags}"],
    format = {"user_link_flags": "@rules_cc//cc/toolchains/variables:user_link_flags"},
    iterate_over = "@rules_cc//cc/toolchains/variables:user_link_flags",
    requires_not_none = "@rules_cc//cc/toolchains/variables:user_link_flags",
)

# === Configuration (Mode-Driven) ===

cc_args(
    name = "dbg_compile_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [],
)

cc_args(
    name = "fastbuild_compile_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [],
)

cc_args(
    name = "opt_compile_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [],
)

cc_args(
    name = "dbg_link_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [],
)

cc_args(
    name = "fastbuild_link_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [],
)

cc_args(
    name = "opt_link_flags",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [],
)

# === Semantic Option Features ===

cc_args(
    name = "treat_warnings_as_errors",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = ["-Werror"],
)

cc_args(
    name = "generate_debug_symbols_compile",
    actions = ["@rules_cc//cc/toolchains/actions:compile_actions"],
    args = ["-gcodeview"],
)

cc_args(
    name = "generate_debug_symbols_link",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = ["/DEBUG"],
)

cc_args(
    name = "release_dynamic_runtime_compile",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "-fms-runtime-lib=dll",
    ],
    requires_any_of = ["//{COMPILER_KIND}/features:no_static_no_debug_constraint"],
)

cc_args(
    name = "release_dynamic_runtime_link",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "ucrt.lib",
        "msvcrt.lib",
        "vcruntime.lib",
        "msvcprt.lib",
    ],
    requires_any_of = ["//{COMPILER_KIND}/features:no_static_no_debug_constraint"],
)

cc_args(
    name = "release_static_runtime_compile",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "-fms-runtime-lib=static",
    ],
    requires_any_of = ["//{COMPILER_KIND}/features:static_no_debug_constraint"],
)

cc_args(
    name = "release_static_runtime_link",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "libucrt.lib",
        "libvcruntime.lib",
        "libcmt.lib",
        "libcpmt.lib",
    ],
    requires_any_of = ["//{COMPILER_KIND}/features:static_no_debug_constraint"],
)

cc_args(
    name = "debug_dynamic_runtime_compile",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "-fms-runtime-lib=dll_dbg",
        "-D_DEBUG",
    ],
    requires_any_of = ["//{COMPILER_KIND}/features:no_static_debug_constraint"],
)

cc_args(
    name = "debug_dynamic_runtime_link",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "ucrtd.lib",
        "msvcrtd.lib",
        "vcruntimed.lib",
        "msvcprtd.lib",
    ],
    requires_any_of = ["//{COMPILER_KIND}/features:no_static_debug_constraint"],
)

cc_args(
    name = "debug_static_runtime_compile",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "-fms-runtime-lib=static_dbg",
        "-D_DEBUG",
    ],
    requires_any_of = ["//{COMPILER_KIND}/features:static_debug_constraint"],
)

cc_args(
    name = "debug_static_runtime_link",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "libucrtd.lib",
        "libvcruntimed.lib",
        "libcmtd.lib",
        "libcpmtd.lib",
    ],
    requires_any_of = ["//{COMPILER_KIND}/features:static_debug_constraint"],
)

cc_args(
    name = "window_subsystem",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    requires_any_of = ["//{COMPILER_KIND}/features:window_subsystem"],
    args = ["/SUBSYSTEM:WINDOWS"],
)

cc_args(
    name = "console_subsystem",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    requires_any_of = ["//{COMPILER_KIND}/features:no_subsystem_constraint"],
    args = ["/SUBSYSTEM:CONSOLE"],
)

# === Optimization Technologies ===

cc_args(
    name = "thin_lto_compile",
    actions = [
        "@rules_cc//cc/toolchains/actions:compile_actions",
    ],
    args = ["-flto=thin"],
)

cc_args(
    name = "thin_lto_link",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = ["/LTCG"],
)

cc_args(
    name = "full_lto_compile",
    actions = [
        "@rules_cc//cc/toolchains/actions:compile_actions",
    ],
    args = ["-flto"],
)
cc_args(
    name = "full_lto_link",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = ["/LTCG"],
)

# === Language Standard ===

cc_args(
    name = "cxx_standard_14",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_compile_actions"],
    args = ["-std=c++14"],
)

cc_args(
    name = "cxx_standard_17",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_compile_actions"],
    args = ["-std=c++17"],
)

cc_args(
    name = "cxx_standard_20",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_compile_actions"],
    args = ["-std=c++20"],
)

cc_args(
    name = "cxx_standard_23",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_compile_actions"],
    args = ["-std=c++23"],
)

cc_args(
    name = "cxx_standard_26",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_compile_actions"],
    args = ["-std=c++26"],
)


cc_args(
    name = "cxx_standard_latest",
    actions = ["@rules_cc//cc/toolchains/actions:cpp_compile_actions"],
    args = ["-std=c++2c"],
)
