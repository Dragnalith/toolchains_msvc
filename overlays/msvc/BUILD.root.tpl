load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@bazel_skylib//rules/directory:subdirectory.bzl", "subdirectory")

package(default_visibility = ["//visibility:public"])

# CL
exports_files(
    ["Tools/bin/Hostx64/x64/cl.exe"],
    visibility = ["//visibility:public"],
)

alias(
    name = "cl_x64",
    actual = ":Tools/bin/Hostx64/x64/cl.exe",
)

# Linker
exports_files(
    ["Tools/bin/Hostx64/x64/link.exe"],
    visibility = ["//visibility:public"],
)

alias(
    name = "link_x64",
    actual = ":Tools/bin/Hostx64/x64/link.exe",
)

# Librarian
exports_files(
    ["Tools/bin/Hostx64/x64/lib.exe"],
    visibility = ["//visibility:public"],
)

alias(
    name = "lib_x64",
    actual = ":Tools/bin/Hostx64/x64/lib.exe",
)

# Assembler
exports_files(
    ["Tools/bin/Hostx64/x64/ml64.exe"],
    visibility = ["//visibility:public"],
)

alias(
    name = "ml64_x64",
    actual = ":Tools/bin/Hostx64/x64/ml64.exe",
)

# Directory tree metadata for precise subdirectory paths.
directory(
    name = "msvc_tree",
    srcs = glob(
        [
            "Tools/include/**",
            "Tools/lib/x64/**",
        ],
        allow_empty = False,
    ),
)

# Include Dir
subdirectory(
    name = "include_dir",
    parent = ":msvc_tree",
    path = "Tools/include",
)

# Lib Dir
subdirectory(
    name = "lib_dir_x64",
    parent = ":msvc_tree",
    path = "Tools/lib/x64",
)

filegroup(
    name = "msvc_all_includes",
    srcs = glob(
        ["Tools/include/**"],
        allow_empty = False,
    ),
)

filegroup(
    name = "msvc_all_libs_x64",
    srcs = glob(
        ["Tools/lib/x64/**"],
        allow_empty = False,
    ),
)

filegroup(
    name = "msvc_all_binaries_x64",
    srcs = glob(
        [
            "Tools/bin/Hostx64/x64/**",
        ],
        allow_empty = False,
    ),
)
