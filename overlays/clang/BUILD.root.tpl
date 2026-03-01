load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@bazel_skylib//rules/directory:subdirectory.bzl", "subdirectory")

package(default_visibility = ["//visibility:public"])

exports_files(
    [
        "bin/clang.exe",
        "bin/clang-cl.exe",
        "bin/lld-link.exe",
        "bin/llvm-lib.exe",
        "bin/llvm-ml.exe",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "clang_all_binaries",
    srcs = glob(
        ["bin/**"],
        allow_empty = True,
    ),
)

# Host x64
# We create aliases so it looks like msvc_repo, but since Clang cross-compiles natively,
# they all point to the same binaries.
alias(name = "cl_hostx64_targetx64", actual = ":bin/clang.exe")
alias(name = "cl_hostx64_targetx86", actual = ":bin/clang.exe")
alias(name = "cl_hostx64_targetarm64", actual = ":bin/clang.exe")

alias(name = "cl_hostx86_targetx64", actual = ":bin/clang.exe")
alias(name = "cl_hostx86_targetx86", actual = ":bin/clang.exe")
alias(name = "cl_hostx86_targetarm64", actual = ":bin/clang.exe")

alias(name = "cl_hostarm64_targetx64", actual = ":bin/clang.exe")
alias(name = "cl_hostarm64_targetx86", actual = ":bin/clang.exe")
alias(name = "cl_hostarm64_targetarm64", actual = ":bin/clang.exe")

# Linker
alias(name = "link_hostx64_targetx64", actual = ":bin/lld-link.exe")
alias(name = "link_hostx64_targetx86", actual = ":bin/lld-link.exe")
alias(name = "link_hostx64_targetarm64", actual = ":bin/lld-link.exe")

alias(name = "link_hostx86_targetx64", actual = ":bin/lld-link.exe")
alias(name = "link_hostx86_targetx86", actual = ":bin/lld-link.exe")
alias(name = "link_hostx86_targetarm64", actual = ":bin/lld-link.exe")

alias(name = "link_hostarm64_targetx64", actual = ":bin/lld-link.exe")
alias(name = "link_hostarm64_targetx86", actual = ":bin/lld-link.exe")
alias(name = "link_hostarm64_targetarm64", actual = ":bin/lld-link.exe")

# Librarian
alias(name = "lib_hostx64_targetx64", actual = ":bin/llvm-lib.exe")
alias(name = "lib_hostx64_targetx86", actual = ":bin/llvm-lib.exe")
alias(name = "lib_hostx64_targetarm64", actual = ":bin/llvm-lib.exe")

alias(name = "lib_hostx86_targetx64", actual = ":bin/llvm-lib.exe")
alias(name = "lib_hostx86_targetx86", actual = ":bin/llvm-lib.exe")
alias(name = "lib_hostx86_targetarm64", actual = ":bin/llvm-lib.exe")

alias(name = "lib_hostarm64_targetx64", actual = ":bin/llvm-lib.exe")
alias(name = "lib_hostarm64_targetx86", actual = ":bin/llvm-lib.exe")
alias(name = "lib_hostarm64_targetarm64", actual = ":bin/llvm-lib.exe")

# Assembler
alias(name = "ml64_hostx64_targetx64", actual = ":bin/llvm-ml.exe")
alias(name = "ml64_hostx64_targetx86", actual = ":bin/llvm-ml.exe")
alias(name = "ml64_hostx64_targetarm64", actual = ":bin/llvm-ml.exe")

alias(name = "ml64_hostx86_targetx64", actual = ":bin/llvm-ml.exe")
alias(name = "ml64_hostx86_targetx86", actual = ":bin/llvm-ml.exe")
alias(name = "ml64_hostx86_targetarm64", actual = ":bin/llvm-ml.exe")

alias(name = "ml64_hostarm64_targetx64", actual = ":bin/llvm-ml.exe")
alias(name = "ml64_hostarm64_targetx86", actual = ":bin/llvm-ml.exe")
alias(name = "ml64_hostarm64_targetarm64", actual = ":bin/llvm-ml.exe")

filegroup(
    name = "clang_all_binaries_hostx64_targetx64",
    srcs = [":clang_all_binaries"],
)
filegroup(name = "clang_all_binaries_hostx64_targetx86", srcs = [":clang_all_binaries"])
filegroup(name = "clang_all_binaries_hostx64_targetarm64", srcs = [":clang_all_binaries"])
filegroup(name = "clang_all_binaries_hostx86_targetx64", srcs = [":clang_all_binaries"])
filegroup(name = "clang_all_binaries_hostx86_targetx86", srcs = [":clang_all_binaries"])
filegroup(name = "clang_all_binaries_hostx86_targetarm64", srcs = [":clang_all_binaries"])
filegroup(name = "clang_all_binaries_hostarm64_targetx64", srcs = [":clang_all_binaries"])
filegroup(name = "clang_all_binaries_hostarm64_targetx86", srcs = [":clang_all_binaries"])
filegroup(name = "clang_all_binaries_hostarm64_targetarm64", srcs = [":clang_all_binaries"])
