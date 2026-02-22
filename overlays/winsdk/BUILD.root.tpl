load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@bazel_skylib//rules/directory:subdirectory.bzl", "subdirectory")

package(default_visibility = ["//visibility:public"])

# Include Dirs
directory(
    name = "winsdk_tree",
    srcs = glob(
        [
            "Include/10.0.{winsdk_version}.0/ucrt/**",
            "Include/10.0.{winsdk_version}.0/um/**",
            "Include/10.0.{winsdk_version}.0/shared/**",
            "Lib/10.0.{winsdk_version}.0/um/x64/**",
            "Lib/10.0.{winsdk_version}.0/ucrt/x64/**",
            "Lib/10.0.{winsdk_version}.0/um/x86/**",
            "Lib/10.0.{winsdk_version}.0/ucrt/x86/**",
            "Lib/10.0.{winsdk_version}.0/um/arm64/**",
            "Lib/10.0.{winsdk_version}.0/ucrt/arm64/**",
        ],
        allow_empty = True,
    ),
)

subdirectory(
    name = "ucrt_include",
    parent = ":winsdk_tree",
    path = "Include/10.0.{winsdk_version}.0/ucrt",
)

filegroup(
    name = "ucrt_include_files",
    srcs = glob(
        ["Include/10.0.{winsdk_version}.0/ucrt/**"],
        allow_empty = True,
    ),
)

subdirectory(
    name = "um_include",
    parent = ":winsdk_tree",
    path = "Include/10.0.{winsdk_version}.0/um",
)

filegroup(
    name = "um_include_files",
    srcs = glob(
        ["Include/10.0.{winsdk_version}.0/um/**"],
        allow_empty = True,
    ),
)

subdirectory(
    name = "shared_include",
    parent = ":winsdk_tree",
    path = "Include/10.0.{winsdk_version}.0/shared",
)

filegroup(
    name = "shared_include_files",
    srcs = glob(
        ["Include/10.0.{winsdk_version}.0/shared/**"],
        allow_empty = True,
    ),
)

# Lib Dirs
subdirectory(
    name = "um_lib_dir_x64",
    parent = ":winsdk_tree",
    path = "Lib/10.0.{winsdk_version}.0/um/x64",
)

filegroup(
    name = "um_lib_dir_files_x64",
    srcs = glob(
        ["Lib/10.0.{winsdk_version}.0/um/x64/**"],
        allow_empty = True,
    ),
)

subdirectory(
    name = "ucrt_lib_dir_x64",
    parent = ":winsdk_tree",
    path = "Lib/10.0.{winsdk_version}.0/ucrt/x64",
)

filegroup(
    name = "ucrt_lib_dir_files_x64",
    srcs = glob(
        ["Lib/10.0.{winsdk_version}.0/ucrt/x64/**"],
        allow_empty = True,
    ),
)

subdirectory(
    name = "um_lib_dir_x86",
    parent = ":winsdk_tree",
    path = "Lib/10.0.{winsdk_version}.0/um/x86",
)

filegroup(
    name = "um_lib_dir_files_x86",
    srcs = glob(
        ["Lib/10.0.{winsdk_version}.0/um/x86/**"],
        allow_empty = True,
    ),
)

subdirectory(
    name = "ucrt_lib_dir_x86",
    parent = ":winsdk_tree",
    path = "Lib/10.0.{winsdk_version}.0/ucrt/x86",
)

filegroup(
    name = "ucrt_lib_dir_files_x86",
    srcs = glob(
        ["Lib/10.0.{winsdk_version}.0/ucrt/x86/**"],
        allow_empty = True,
    ),
)

subdirectory(
    name = "um_lib_dir_arm64",
    parent = ":winsdk_tree",
    path = "Lib/10.0.{winsdk_version}.0/um/arm64",
)

filegroup(
    name = "um_lib_dir_files_arm64",
    srcs = glob(
        ["Lib/10.0.{winsdk_version}.0/um/arm64/**"],
        allow_empty = True,
    ),
)

subdirectory(
    name = "ucrt_lib_dir_arm64",
    parent = ":winsdk_tree",
    path = "Lib/10.0.{winsdk_version}.0/ucrt/arm64",
)

filegroup(
    name = "ucrt_lib_dir_files_arm64",
    srcs = glob(
        ["Lib/10.0.{winsdk_version}.0/ucrt/arm64/**"],
        allow_empty = True,
    ),
)

