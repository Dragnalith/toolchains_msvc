load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@bazel_skylib//rules/directory:subdirectory.bzl", "subdirectory")

package(default_visibility = ["//visibility:public"])

# CL
exports_files(
    [
        "Tools/bin/Hostx64/x64/cl.exe",
        "Tools/bin/Hostx64/x86/cl.exe",
        "Tools/bin/Hostx64/arm64/cl.exe",
        "Tools/bin/Hostx86/x64/cl.exe",
        "Tools/bin/Hostx86/x86/cl.exe",
        "Tools/bin/Hostx86/arm64/cl.exe",
        "Tools/bin/Hostarm64/x64/cl.exe",
        "Tools/bin/Hostarm64/x86/cl.exe",
        "Tools/bin/Hostarm64/arm64/cl.exe",
    ],
    visibility = ["//visibility:public"],
)

alias(
    name = "cl_hostx64_targetx64",
    actual = ":Tools/bin/Hostx64/x64/cl.exe",
)

alias(
    name = "cl_hostx64_targetx86",
    actual = ":Tools/bin/Hostx64/x86/cl.exe",
)

alias(
    name = "cl_hostx64_targetarm64",
    actual = ":Tools/bin/Hostx64/arm64/cl.exe",
)

alias(
    name = "cl_hostx86_targetx64",
    actual = ":Tools/bin/Hostx86/x64/cl.exe",
)

alias(
    name = "cl_hostx86_targetx86",
    actual = ":Tools/bin/Hostx86/x86/cl.exe",
)

alias(
    name = "cl_hostx86_targetarm64",
    actual = ":Tools/bin/Hostx86/arm64/cl.exe",
)

alias(
    name = "cl_hostarm64_targetx64",
    actual = ":Tools/bin/Hostarm64/x64/cl.exe",
)

alias(
    name = "cl_hostarm64_targetx86",
    actual = ":Tools/bin/Hostarm64/x86/cl.exe",
)

alias(
    name = "cl_hostarm64_targetarm64",
    actual = ":Tools/bin/Hostarm64/arm64/cl.exe",
)

# Linker
exports_files(
    [
        "Tools/bin/Hostx64/x64/link.exe",
        "Tools/bin/Hostx64/x86/link.exe",
        "Tools/bin/Hostx64/arm64/link.exe",
        "Tools/bin/Hostx86/x64/link.exe",
        "Tools/bin/Hostx86/x86/link.exe",
        "Tools/bin/Hostx86/arm64/link.exe",
        "Tools/bin/Hostarm64/x64/link.exe",
        "Tools/bin/Hostarm64/x86/link.exe",
        "Tools/bin/Hostarm64/arm64/link.exe",
    ],
    visibility = ["//visibility:public"],
)

alias(
    name = "link_hostx64_targetx64",
    actual = ":Tools/bin/Hostx64/x64/link.exe",
)

alias(
    name = "link_hostx64_targetx86",
    actual = ":Tools/bin/Hostx64/x86/link.exe",
)

alias(
    name = "link_hostx64_targetarm64",
    actual = ":Tools/bin/Hostx64/arm64/link.exe",
)

alias(
    name = "link_hostx86_targetx64",
    actual = ":Tools/bin/Hostx86/x64/link.exe",
)

alias(
    name = "link_hostx86_targetx86",
    actual = ":Tools/bin/Hostx86/x86/link.exe",
)

alias(
    name = "link_hostx86_targetarm64",
    actual = ":Tools/bin/Hostx86/arm64/link.exe",
)

alias(
    name = "link_hostarm64_targetx64",
    actual = ":Tools/bin/Hostarm64/x64/link.exe",
)

alias(
    name = "link_hostarm64_targetx86",
    actual = ":Tools/bin/Hostarm64/x86/link.exe",
)

alias(
    name = "link_hostarm64_targetarm64",
    actual = ":Tools/bin/Hostarm64/arm64/link.exe",
)

# Librarian
exports_files(
    [
        "Tools/bin/Hostx64/x64/lib.exe",
        "Tools/bin/Hostx64/x86/lib.exe",
        "Tools/bin/Hostx64/arm64/lib.exe",
        "Tools/bin/Hostx86/x64/lib.exe",
        "Tools/bin/Hostx86/x86/lib.exe",
        "Tools/bin/Hostx86/arm64/lib.exe",
        "Tools/bin/Hostarm64/x64/lib.exe",
        "Tools/bin/Hostarm64/x86/lib.exe",
        "Tools/bin/Hostarm64/arm64/lib.exe",
    ],
    visibility = ["//visibility:public"],
)

alias(
    name = "lib_hostx64_targetx64",
    actual = ":Tools/bin/Hostx64/x64/lib.exe",
)

alias(
    name = "lib_hostx64_targetx86",
    actual = ":Tools/bin/Hostx64/x86/lib.exe",
)

alias(
    name = "lib_hostx64_targetarm64",
    actual = ":Tools/bin/Hostx64/arm64/lib.exe",
)

alias(
    name = "lib_hostx86_targetx64",
    actual = ":Tools/bin/Hostx86/x64/lib.exe",
)

alias(
    name = "lib_hostx86_targetx86",
    actual = ":Tools/bin/Hostx86/x86/lib.exe",
)

alias(
    name = "lib_hostx86_targetarm64",
    actual = ":Tools/bin/Hostx86/arm64/lib.exe",
)

alias(
    name = "lib_hostarm64_targetx64",
    actual = ":Tools/bin/Hostarm64/x64/lib.exe",
)

alias(
    name = "lib_hostarm64_targetx86",
    actual = ":Tools/bin/Hostarm64/x86/lib.exe",
)

alias(
    name = "lib_hostarm64_targetarm64",
    actual = ":Tools/bin/Hostarm64/arm64/lib.exe",
)

# Assembler
exports_files(
    [
        "Tools/bin/Hostx64/x64/ml64.exe",
        "Tools/bin/Hostx64/x86/ml64.exe",
        "Tools/bin/Hostx64/arm64/ml64.exe",
        "Tools/bin/Hostx86/x64/ml64.exe",
        "Tools/bin/Hostx86/x86/ml64.exe",
        "Tools/bin/Hostx86/arm64/ml64.exe",
        "Tools/bin/Hostarm64/x64/ml64.exe",
        "Tools/bin/Hostarm64/x86/ml64.exe",
        "Tools/bin/Hostarm64/arm64/ml64.exe",
    ],
    visibility = ["//visibility:public"],
)

alias(
    name = "ml64_hostx64_targetx64",
    actual = ":Tools/bin/Hostx64/x64/ml64.exe",
)

alias(
    name = "ml64_hostx64_targetx86",
    actual = ":Tools/bin/Hostx64/x86/ml64.exe",
)

alias(
    name = "ml64_hostx64_targetarm64",
    actual = ":Tools/bin/Hostx64/arm64/ml64.exe",
)

alias(
    name = "ml64_hostx86_targetx64",
    actual = ":Tools/bin/Hostx86/x64/ml64.exe",
)

alias(
    name = "ml64_hostx86_targetx86",
    actual = ":Tools/bin/Hostx86/x86/ml64.exe",
)

alias(
    name = "ml64_hostx86_targetarm64",
    actual = ":Tools/bin/Hostx86/arm64/ml64.exe",
)

alias(
    name = "ml64_hostarm64_targetx64",
    actual = ":Tools/bin/Hostarm64/x64/ml64.exe",
)

alias(
    name = "ml64_hostarm64_targetx86",
    actual = ":Tools/bin/Hostarm64/x86/ml64.exe",
)

alias(
    name = "ml64_hostarm64_targetarm64",
    actual = ":Tools/bin/Hostarm64/arm64/ml64.exe",
)

# Directory tree metadata for precise subdirectory paths.
directory(
    name = "msvc_tree",
    srcs = glob(
        [
            "Tools/include/**",
            "Tools/lib/x64/**",
            "Tools/lib/x86/**",
            "Tools/lib/arm64/**",
            "Tools/bin/Hostx64/x64/**",
            "Tools/bin/Hostx64/x86/**",
            "Tools/bin/Hostx64/arm64/**",
            "Tools/bin/Hostx86/x64/**",
            "Tools/bin/Hostx86/x86/**",
            "Tools/bin/Hostx86/arm64/**",
            "Tools/bin/Hostarm64/x64/**",
            "Tools/bin/Hostarm64/x86/**",
            "Tools/bin/Hostarm64/arm64/**",
        ],
        allow_empty = True,
    ),
)

# Include Dir
subdirectory(
    name = "include_dir",
    parent = ":msvc_tree",
    path = "Tools/include",
)

filegroup(
    name = "msvc_all_includes",
    srcs = glob(
        ["Tools/include/**"],
        allow_empty = True,
    ),
)

# Lib Dir
subdirectory(
    name = "lib_dir_x64",
    parent = ":msvc_tree",
    path = "Tools/lib/x64",
)

filegroup(
    name = "msvc_all_libs_x64",
    srcs = glob(
        ["Tools/lib/x64/**"],
        allow_empty = True,
    ),
)

subdirectory(
    name = "lib_dir_x86",
    parent = ":msvc_tree",
    path = "Tools/lib/x86",
)

filegroup(
    name = "msvc_all_libs_x86",
    srcs = glob(
        ["Tools/lib/x86/**"],
        allow_empty = True,
    ),
)

subdirectory(
    name = "lib_dir_arm64",
    parent = ":msvc_tree",
    path = "Tools/lib/arm64",
)

filegroup(
    name = "msvc_all_libs_arm64",
    srcs = glob(
        ["Tools/lib/arm64/**"],
        allow_empty = True,
    ),
)

# Binaries
filegroup(
    name = "msvc_all_binaries_hostx64_targetx64",
    srcs = glob(
        ["Tools/bin/Hostx64/x64/**"],
        allow_empty = True,
    ),
)

filegroup(
    name = "msvc_all_binaries_hostx64_targetx86",
    srcs = glob(
        ["Tools/bin/Hostx64/x86/**"],
        allow_empty = True,
    ),
)

filegroup(
    name = "msvc_all_binaries_hostx64_targetarm64",
    srcs = glob(
        ["Tools/bin/Hostx64/arm64/**"],
        allow_empty = True,
    ),
)

filegroup(
    name = "msvc_all_binaries_hostx86_targetx64",
    srcs = glob(
        ["Tools/bin/Hostx86/x64/**"],
        allow_empty = True,
    ),
)

filegroup(
    name = "msvc_all_binaries_hostx86_targetx86",
    srcs = glob(
        ["Tools/bin/Hostx86/x86/**"],
        allow_empty = True,
    ),
)

filegroup(
    name = "msvc_all_binaries_hostx86_targetarm64",
    srcs = glob(
        ["Tools/bin/Hostx86/arm64/**"],
        allow_empty = True,
    ),
)

filegroup(
    name = "msvc_all_binaries_hostarm64_targetx64",
    srcs = glob(
        ["Tools/bin/Hostarm64/x64/**"],
        allow_empty = True,
    ),
)

filegroup(
    name = "msvc_all_binaries_hostarm64_targetx86",
    srcs = glob(
        ["Tools/bin/Hostarm64/x86/**"],
        allow_empty = True,
    ),
)

filegroup(
    name = "msvc_all_binaries_hostarm64_targetarm64",
    srcs = glob(
        ["Tools/bin/Hostarm64/arm64/**"],
        allow_empty = True,
    ),
)

