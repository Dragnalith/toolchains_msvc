load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@bazel_skylib//rules/directory:subdirectory.bzl", "subdirectory")

package(default_visibility = ["//visibility:public"])

exports_files(
    [
        "bin/clang",
        "bin/clang-cl",
        "bin/clang-format",
        "bin/clang-tidy",
        "bin/lld-link",
        "bin/llvm-lib",
        "bin/llvm-ml",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "clang_exe_only",
    srcs = ["bin/clang"],
)

filegroup(
    name = "clang_cl_exe_only",
    srcs = ["bin/clang-cl"],
)

filegroup(
    name = "clang-format",
    srcs = ["bin/clang-format"],
)

filegroup(
    name = "clang-tidy",
    srcs = ["bin/clang-tidy"],
)

directory(
    name = "llvm_tree",
    srcs = glob(["lib/clang/**"]),
)

subdirectory(
    name = "clang_builtin_include",
    parent = ":llvm_tree",
    path = "lib/clang/{LLVM_VERSION}/include",
)

filegroup(
    name = "clang_builtin_include_files",
    srcs = glob(["lib/clang/{LLVM_VERSION}/include/**"]),
)

filegroup(
    name = "lld_link_exe_only",
    srcs = [
        "bin/lld-link",
    ],
)

filegroup(name = "llvm_lib_exe_only", srcs = ["bin/llvm-lib"])
filegroup(name = "llvm_ml_exe_only", srcs = ["bin/llvm-ml"])

# Clang cross-compiles natively for MSVC targets, so all host/target
# combinations point to the same binaries.

alias(name = "clang_hostx64_targetx64", actual = ":bin/clang")
alias(name = "clang_hostx64_targetx86", actual = ":bin/clang")
alias(name = "clang_hostx64_targetarm64", actual = ":bin/clang")

alias(name = "clang_hostx86_targetx64", actual = ":bin/clang")
alias(name = "clang_hostx86_targetx86", actual = ":bin/clang")
alias(name = "clang_hostx86_targetarm64", actual = ":bin/clang")

alias(name = "clang_hostarm64_targetx64", actual = ":bin/clang")
alias(name = "clang_hostarm64_targetx86", actual = ":bin/clang")
alias(name = "clang_hostarm64_targetarm64", actual = ":bin/clang")

alias(name = "clang-cl_hostx64_targetx64", actual = ":bin/clang-cl")
alias(name = "clang-cl_hostx64_targetx86", actual = ":bin/clang-cl")
alias(name = "clang-cl_hostx64_targetarm64", actual = ":bin/clang-cl")

alias(name = "clang-cl_hostx86_targetx64", actual = ":bin/clang-cl")
alias(name = "clang-cl_hostx86_targetx86", actual = ":bin/clang-cl")
alias(name = "clang-cl_hostx86_targetarm64", actual = ":bin/clang-cl")

alias(name = "clang-cl_hostarm64_targetx64", actual = ":bin/clang-cl")
alias(name = "clang-cl_hostarm64_targetx86", actual = ":bin/clang-cl")
alias(name = "clang-cl_hostarm64_targetarm64", actual = ":bin/clang-cl")

alias(name = "lld-link_hostx64_targetx64", actual = ":bin/lld-link")
alias(name = "lld-link_hostx64_targetx86", actual = ":bin/lld-link")
alias(name = "lld-link_hostx64_targetarm64", actual = ":bin/lld-link")
alias(name = "lld-link_hostx86_targetx64", actual = ":bin/lld-link")
alias(name = "lld-link_hostx86_targetx86", actual = ":bin/lld-link")
alias(name = "lld-link_hostx86_targetarm64", actual = ":bin/lld-link")
alias(name = "lld-link_hostarm64_targetx64", actual = ":bin/lld-link")
alias(name = "lld-link_hostarm64_targetx86", actual = ":bin/lld-link")
alias(name = "lld-link_hostarm64_targetarm64", actual = ":bin/lld-link")

alias(name = "llvm-lib_hostx64_targetx64", actual = ":bin/llvm-lib")
alias(name = "llvm-lib_hostx64_targetx86", actual = ":bin/llvm-lib")
alias(name = "llvm-lib_hostx64_targetarm64", actual = ":bin/llvm-lib")
alias(name = "llvm-lib_hostx86_targetx64", actual = ":bin/llvm-lib")
alias(name = "llvm-lib_hostx86_targetx86", actual = ":bin/llvm-lib")
alias(name = "llvm-lib_hostx86_targetarm64", actual = ":bin/llvm-lib")
alias(name = "llvm-lib_hostarm64_targetx64", actual = ":bin/llvm-lib")
alias(name = "llvm-lib_hostarm64_targetx86", actual = ":bin/llvm-lib")
alias(name = "llvm-lib_hostarm64_targetarm64", actual = ":bin/llvm-lib")

alias(name = "llvm-ml_hostx64_targetx64", actual = ":bin/llvm-ml")
alias(name = "llvm-ml_hostx64_targetx86", actual = ":bin/llvm-ml")
alias(name = "llvm-ml_hostx64_targetarm64", actual = ":bin/llvm-ml")
alias(name = "llvm-ml_hostx86_targetx64", actual = ":bin/llvm-ml")
alias(name = "llvm-ml_hostx86_targetx86", actual = ":bin/llvm-ml")
alias(name = "llvm-ml_hostx86_targetarm64", actual = ":bin/llvm-ml")
alias(name = "llvm-ml_hostarm64_targetx64", actual = ":bin/llvm-ml")
alias(name = "llvm-ml_hostarm64_targetx86", actual = ":bin/llvm-ml")
alias(name = "llvm-ml_hostarm64_targetarm64", actual = ":bin/llvm-ml")

filegroup(name = "clang_exe_only_hostx64_targetx64", srcs = [":clang_exe_only"])
filegroup(name = "clang_exe_only_hostx64_targetx86", srcs = [":clang_exe_only"])
filegroup(name = "clang_exe_only_hostx64_targetarm64", srcs = [":clang_exe_only"])
filegroup(name = "clang_exe_only_hostx86_targetx64", srcs = [":clang_exe_only"])
filegroup(name = "clang_exe_only_hostx86_targetx86", srcs = [":clang_exe_only"])
filegroup(name = "clang_exe_only_hostx86_targetarm64", srcs = [":clang_exe_only"])
filegroup(name = "clang_exe_only_hostarm64_targetx64", srcs = [":clang_exe_only"])
filegroup(name = "clang_exe_only_hostarm64_targetx86", srcs = [":clang_exe_only"])
filegroup(name = "clang_exe_only_hostarm64_targetarm64", srcs = [":clang_exe_only"])

filegroup(name = "clang_cl_exe_only_hostx64_targetx64", srcs = [":clang_cl_exe_only"])
filegroup(name = "clang_cl_exe_only_hostx64_targetx86", srcs = [":clang_cl_exe_only"])
filegroup(name = "clang_cl_exe_only_hostx64_targetarm64", srcs = [":clang_cl_exe_only"])
filegroup(name = "clang_cl_exe_only_hostx86_targetx64", srcs = [":clang_cl_exe_only"])
filegroup(name = "clang_cl_exe_only_hostx86_targetx86", srcs = [":clang_cl_exe_only"])
filegroup(name = "clang_cl_exe_only_hostx86_targetarm64", srcs = [":clang_cl_exe_only"])
filegroup(name = "clang_cl_exe_only_hostarm64_targetx64", srcs = [":clang_cl_exe_only"])
filegroup(name = "clang_cl_exe_only_hostarm64_targetx86", srcs = [":clang_cl_exe_only"])
filegroup(name = "clang_cl_exe_only_hostarm64_targetarm64", srcs = [":clang_cl_exe_only"])

filegroup(name = "lld_link_exe_only_hostx64_targetx64", srcs = [":lld_link_exe_only"])
filegroup(name = "lld_link_exe_only_hostx64_targetx86", srcs = [":lld_link_exe_only"])
filegroup(name = "lld_link_exe_only_hostx64_targetarm64", srcs = [":lld_link_exe_only"])
filegroup(name = "lld_link_exe_only_hostx86_targetx64", srcs = [":lld_link_exe_only"])
filegroup(name = "lld_link_exe_only_hostx86_targetx86", srcs = [":lld_link_exe_only"])
filegroup(name = "lld_link_exe_only_hostx86_targetarm64", srcs = [":lld_link_exe_only"])
filegroup(name = "lld_link_exe_only_hostarm64_targetx64", srcs = [":lld_link_exe_only"])
filegroup(name = "lld_link_exe_only_hostarm64_targetx86", srcs = [":lld_link_exe_only"])
filegroup(name = "lld_link_exe_only_hostarm64_targetarm64", srcs = [":lld_link_exe_only"])

filegroup(name = "llvm_lib_exe_only_hostx64_targetx64", srcs = [":llvm_lib_exe_only"])
filegroup(name = "llvm_lib_exe_only_hostx64_targetx86", srcs = [":llvm_lib_exe_only"])
filegroup(name = "llvm_lib_exe_only_hostx64_targetarm64", srcs = [":llvm_lib_exe_only"])
filegroup(name = "llvm_lib_exe_only_hostx86_targetx64", srcs = [":llvm_lib_exe_only"])
filegroup(name = "llvm_lib_exe_only_hostx86_targetx86", srcs = [":llvm_lib_exe_only"])
filegroup(name = "llvm_lib_exe_only_hostx86_targetarm64", srcs = [":llvm_lib_exe_only"])
filegroup(name = "llvm_lib_exe_only_hostarm64_targetx64", srcs = [":llvm_lib_exe_only"])
filegroup(name = "llvm_lib_exe_only_hostarm64_targetx86", srcs = [":llvm_lib_exe_only"])
filegroup(name = "llvm_lib_exe_only_hostarm64_targetarm64", srcs = [":llvm_lib_exe_only"])

filegroup(name = "llvm_ml_exe_only_hostx64_targetx64", srcs = [":llvm_ml_exe_only"])
filegroup(name = "llvm_ml_exe_only_hostx64_targetx86", srcs = [":llvm_ml_exe_only"])
filegroup(name = "llvm_ml_exe_only_hostx64_targetarm64", srcs = [":llvm_ml_exe_only"])
filegroup(name = "llvm_ml_exe_only_hostx86_targetx64", srcs = [":llvm_ml_exe_only"])
filegroup(name = "llvm_ml_exe_only_hostx86_targetx86", srcs = [":llvm_ml_exe_only"])
filegroup(name = "llvm_ml_exe_only_hostx86_targetarm64", srcs = [":llvm_ml_exe_only"])
filegroup(name = "llvm_ml_exe_only_hostarm64_targetx64", srcs = [":llvm_ml_exe_only"])
filegroup(name = "llvm_ml_exe_only_hostarm64_targetx86", srcs = [":llvm_ml_exe_only"])
filegroup(name = "llvm_ml_exe_only_hostarm64_targetarm64", srcs = [":llvm_ml_exe_only"])
