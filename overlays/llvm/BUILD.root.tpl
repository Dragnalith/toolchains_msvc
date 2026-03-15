load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@bazel_skylib//rules/directory:subdirectory.bzl", "subdirectory")

package(default_visibility = ["//visibility:public"])

exports_files(
    [
        "bin/clang.exe",
        "bin/clang-cl.exe",
        "bin/lld-link.exe",
        "bin/lld-link_wrapper.bat",
        "bin/llvm-lib.exe",
        "bin/llvm-ml.exe",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "clang_exe_only",
    srcs = ["bin/clang.exe"],
)

filegroup(
    name = "clang_cl_exe_only",
    srcs = ["bin/clang-cl.exe"],
)

filegroup(
    name = "lld_link_exe_only",
    srcs = [
        "bin/lld-link.exe",
        "bin/lld-link_wrapper.bat",
    ],
)

# lib and ml64 need minimal data for toolchain (user requested only clang/clang-cl/lld-link above)
filegroup(name = "llvm_lib_exe_only", srcs = ["bin/llvm-lib.exe"])
filegroup(name = "llvm_ml_exe_only", srcs = ["bin/llvm-ml.exe"])

# Host x64
# We create aliases so it looks like msvc_repo, but since Clang cross-compiles natively,
# they all point to the same binaries.
alias(name = "clang_hostx64_targetx64", actual = ":bin/clang.exe")
alias(name = "clang_hostx64_targetx86", actual = ":bin/clang.exe")
alias(name = "clang_hostx64_targetarm64", actual = ":bin/clang.exe")
alias(name = "clang-cl_hostx64_targetx64", actual = ":bin/clang-cl.exe")
alias(name = "clang-cl_hostx64_targetx86", actual = ":bin/clang-cl.exe")
alias(name = "clang-cl_hostx64_targetarm64", actual = ":bin/clang-cl.exe")

alias(name = "clang_hostx86_targetx64", actual = ":bin/clang.exe")
alias(name = "clang_hostx86_targetx86", actual = ":bin/clang.exe")
alias(name = "clang_hostx86_targetarm64", actual = ":bin/clang.exe")
alias(name = "clang-cl_hostx86_targetx64", actual = ":bin/clang-cl.exe")
alias(name = "clang-cl_hostx86_targetx86", actual = ":bin/clang-cl.exe")
alias(name = "clang-cl_hostx86_targetarm64", actual = ":bin/clang-cl.exe")

alias(name = "clang_hostarm64_targetx64", actual = ":bin/clang.exe")
alias(name = "clang_hostarm64_targetx86", actual = ":bin/clang.exe")
alias(name = "clang_hostarm64_targetarm64", actual = ":bin/clang.exe")
alias(name = "clang-cl_hostarm64_targetx64", actual = ":bin/clang-cl.exe")
alias(name = "clang-cl_hostarm64_targetx86", actual = ":bin/clang-cl.exe")
alias(name = "clang-cl_hostarm64_targetarm64", actual = ":bin/clang-cl.exe")

# Linker (via wrapper so lld-link is always invoked from the command line)
alias(name = "lld-link_hostx64_targetx64", actual = ":bin/lld-link_wrapper.bat")
alias(name = "lld-link_hostx64_targetx86", actual = ":bin/lld-link_wrapper.bat")
alias(name = "lld-link_hostx64_targetarm64", actual = ":bin/lld-link_wrapper.bat")

alias(name = "lld-link_hostx86_targetx64", actual = ":bin/lld-link_wrapper.bat")
alias(name = "lld-link_hostx86_targetx86", actual = ":bin/lld-link_wrapper.bat")
alias(name = "lld-link_hostx86_targetarm64", actual = ":bin/lld-link_wrapper.bat")

alias(name = "lld-link_hostarm64_targetx64", actual = ":bin/lld-link_wrapper.bat")
alias(name = "lld-link_hostarm64_targetx86", actual = ":bin/lld-link_wrapper.bat")
alias(name = "lld-link_hostarm64_targetarm64", actual = ":bin/lld-link_wrapper.bat")

# Librarian
alias(name = "llvm-lib_hostx64_targetx64", actual = ":bin/llvm-lib.exe")
alias(name = "llvm-lib_hostx64_targetx86", actual = ":bin/llvm-lib.exe")
alias(name = "llvm-lib_hostx64_targetarm64", actual = ":bin/llvm-lib.exe")

alias(name = "llvm-lib_hostx86_targetx64", actual = ":bin/llvm-lib.exe")
alias(name = "llvm-lib_hostx86_targetx86", actual = ":bin/llvm-lib.exe")
alias(name = "llvm-lib_hostx86_targetarm64", actual = ":bin/llvm-lib.exe")

alias(name = "llvm-lib_hostarm64_targetx64", actual = ":bin/llvm-lib.exe")
alias(name = "llvm-lib_hostarm64_targetx86", actual = ":bin/llvm-lib.exe")
alias(name = "llvm-lib_hostarm64_targetarm64", actual = ":bin/llvm-lib.exe")

# Assembler
alias(name = "llvm-ml_hostx64_targetx64", actual = ":bin/llvm-ml.exe")
alias(name = "llvm-ml_hostx64_targetx86", actual = ":bin/llvm-ml.exe")
alias(name = "llvm-ml_hostx64_targetarm64", actual = ":bin/llvm-ml.exe")

alias(name = "llvm-ml_hostx86_targetx64", actual = ":bin/llvm-ml.exe")
alias(name = "llvm-ml_hostx86_targetx86", actual = ":bin/llvm-ml.exe")
alias(name = "llvm-ml_hostx86_targetarm64", actual = ":bin/llvm-ml.exe")

alias(name = "llvm-ml_hostarm64_targetx64", actual = ":bin/llvm-ml.exe")
alias(name = "llvm-ml_hostarm64_targetx86", actual = ":bin/llvm-ml.exe")
alias(name = "llvm-ml_hostarm64_targetarm64", actual = ":bin/llvm-ml.exe")

# Host/target variants for toolchain data (Clang cross-compiles natively, all point to same)
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
