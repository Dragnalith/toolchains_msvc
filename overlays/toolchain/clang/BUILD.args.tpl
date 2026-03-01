load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:args_list.bzl", "cc_args_list")

package(default_visibility = ["//visibility:public"])

# Applied to every tool to prevent accidental host system includes/libs
cc_args(
    name = "nostdinc",
    actions = [
        "@rules_cc//cc/toolchains/actions:assembly_actions",
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
        "@rules_cc//cc/toolchains/actions:link_actions",
        "@rules_cc//cc/toolchains/actions:ar_actions",
        "@rules_cc//cc/toolchains/actions:strip",
    ],
    args = [
        "-nostdinc",
    ],
)

# Collect all compiler args
cc_args_list(
    name = "all_compile_args",
    args = [
        ":base_compile_flags",
        ":msvc_include_paths",
        ":warnings",
    ],
)

# Basic MSVC compile flags
cc_args(
    name = "base_compile_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "--target={clang_target}",
        "-DCOMPILER_MSVC",
        "-DNOMINMAX",
        "-DWIN32_LEAN_AND_MEAN",
        "-D_CRT_SECURE_NO_WARNINGS",
        "-D_UNICODE",
        "-DUNICODE",
        "-fms-compatibility",
        "-fms-extensions",
        "-fms-compatibility-version={cl_internal_version}",
        "-fexceptions",
    ],
)

# MSVC include paths
cc_args(
    name = "msvc_include_paths",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "-isystem",
        "{msvc_include}",
        "-isystem",
        "{winsdk_ucrt_include}",
        "-isystem",
        "{winsdk_um_include}",
        "-isystem",
        "{winsdk_shared_include}",
    ],
    data = [
        "@{msvc_repo}//:msvc_all_includes",
        "@{winsdk_repo}//:um_include_files",
        "@{winsdk_repo}//:ucrt_include_files",
        "@{winsdk_repo}//:shared_include_files",
    ],
    format = {
        "msvc_include": "@{msvc_repo}//:include_dir",
        "winsdk_ucrt_include": "@{winsdk_repo}//:ucrt_include",
        "winsdk_um_include": "@{winsdk_repo}//:um_include",
        "winsdk_shared_include": "@{winsdk_repo}//:shared_include",
    },
)

# Warning configuration
cc_args(
    name = "warnings",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "-Wall",
        "-Wno-error",
    ],
)

# MSVC link flags
cc_args(
    name = "msvc_link_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "/nologo",
        "/MACHINE:{target}",
        "/SUBSYSTEM:CONSOLE",
    ],
)

# MSVC library paths
cc_args(
    name = "msvc_lib_paths",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "/LIBPATH:{msvc_lib}",
        "/LIBPATH:{winsdk_um_lib}",
        "/LIBPATH:{winsdk_ucrt_lib}",
    ],
    data = [
        "@{msvc_repo}//:msvc_all_libs_{target}",
        "@{winsdk_repo}//:um_lib_dir_files_{target}",
        "@{winsdk_repo}//:ucrt_lib_dir_files_{target}",
    ],
    format = {
        "msvc_lib": "@{msvc_repo}//:lib_dir_{target}",
        "winsdk_um_lib": "@{winsdk_repo}//:um_lib_dir_{target}",
        "winsdk_ucrt_lib": "@{winsdk_repo}//:ucrt_lib_dir_{target}",
    },
)

# Debug configuration
cc_args(
    name = "dbg_compile_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "-O0",
        "-g",
        "-gcodeview",
        "-D_DEBUG",
        "-fms-runtime-lib=dll_dbg",
    ],
)

cc_args(
    name = "dbg_link_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "/DEBUG:FULL",
    ],
)

# Optimized configuration
cc_args(
    name = "opt_compile_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "-O2",
        "-DNDEBUG",
        "-fms-runtime-lib=dll",
    ],
)

cc_args(
    name = "opt_link_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "/OPT:REF",
        "/OPT:ICF",
    ],
)

# Fastbuild configuration (default)
cc_args(
    name = "fastbuild_compile_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "-O0",
        "-fms-runtime-lib=dll",
    ],
)

# Static library (archiver) flags
cc_args(
    name = "ar_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:ar_actions",
    ],
    args = [
        "/nologo",
        "/MACHINE:{target}",
    ],
)

# Strip args (dummy)
cc_args(
    name = "msvc_strip_args",
    actions = ["@rules_cc//cc/toolchains/actions:strip"],
    args = [],
)
