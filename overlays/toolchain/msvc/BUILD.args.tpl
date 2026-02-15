load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:args_list.bzl", "cc_args_list")

package(default_visibility = ["//visibility:public"])

# Collect all compiler args
cc_args_list(
    name = "all_compile_args",
    args = [
        ":msvc_compile_flags",
        ":msvc_include_paths",
        ":warnings",
    ],
)

# Basic MSVC compile flags
cc_args(
    name = "msvc_compile_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "/nologo",
        "/DCOMPILER_MSVC",
        "/DNOMINMAX",
        "/DWIN32_LEAN_AND_MEAN",
        "/D_CRT_SECURE_NO_WARNINGS",
        "/D_UNICODE",
        "/DUNICODE",
        "/Zc:inline",
        "/Zc:preprocessor",
        "/Zc:__cplusplus",
        "/EHsc",
        "/utf-8",
        "/bigobj",
        "/Brepro",
        "/FS",
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
        "/I",
        "{msvc_include}",
        "/I",
        "{winsdk_ucrt_include}",
        "/I",
        "{winsdk_um_include}",
        "/I",
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
        "/W3",
        "/WX-",
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
        "/MACHINE:X64",
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
        "@{msvc_repo}//:msvc_all_libs_x64",
        "@{winsdk_repo}//:um_lib_dir_files_x64",
        "@{winsdk_repo}//:ucrt_lib_dir_files_x64",
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
        "/Od",
        "/Zi",
        "/RTC1",
        "/MDd",
        "/D_DEBUG",
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
        "/O2",
        "/Oi",
        "/Gy",
        "/MD",
        "/DNDEBUG",
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
        "/Od",
        "/MD",
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
        "/MACHINE:X64",
    ],
)

# Strip args (dummy)
cc_args(
    name = "msvc_strip_args",
    actions = ["@rules_cc//cc/toolchains/actions:strip"],
    args = [],
)
