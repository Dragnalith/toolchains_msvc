load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:tool.bzl", "cc_tool")
load("@rules_cc//cc/toolchains:tool_map.bzl", "cc_tool_map")
load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")

package(default_visibility = ["//visibility:public"])

# tools
cc_tool_map(
    name = "all_tools",
    tools = {
        "@rules_cc//cc/toolchains/actions:assembly_actions": ":ml64",
        "@rules_cc//cc/toolchains/actions:c_compile": ":clang",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions": ":clang",
        "@rules_cc//cc/toolchains/actions:link_actions": ":link",
        "@rules_cc//cc/toolchains/actions:ar_actions": ":lib",
        "@rules_cc//cc/toolchains/actions:strip": ":link",
    },
    visibility = ["//visibility:public"],
)

cc_tool(
    name = "clang",
    src = "@{llvm_repo}//:{compiler}_host{host}_target{target}",
    data = [
        "@{llvm_repo}//:clang_exe_only_host{host}_target{target}",
        "@{msvc_repo}//:msvc_all_includes",
    ],
)

cc_tool(
    name = "link",
    src = "@{llvm_repo}//:lld-link_host{host}_target{target}",
    data = [
        "@{llvm_repo}//:lld_link_exe_only_host{host}_target{target}",
    ],
)

cc_tool(
    name = "lib",
    src = "@{llvm_repo}//:llvm-lib_host{host}_target{target}",
    data = [
        "@{llvm_repo}//:llvm_lib_exe_only_host{host}_target{target}",
    ],
)

cc_tool(
    name = "ml64",
    src = "@{llvm_repo}//:llvm-ml_host{host}_target{target}",
    data = [
        "@{llvm_repo}//:llvm_ml_exe_only_host{host}_target{target}",
    ],
)

# args
cc_args(
    name = "base_compile_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "--target={clang_target}",
        "-fms-compatibility",
        "-fms-extensions",
        "-fms-compatibility-version={cl_internal_version}",
        "-nostdinc",
        "-mno-incremental-linker-compatible",
        "-fdebug-compilation-dir=.",
        "-fcoverage-compilation-dir=.",
        "-resource-dir=.",
        "-no-canonical-prefixes",
        "-gno-codeview-command-line",
        "-fno-ident",
    ],
)

cc_args(
    name = "base_link_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "/lldignoreenv",
        "/NODEFAULTLIB",
        "/INCREMENTAL:NO",
        "/PDBALTPATH:%_PDB%",
        "/Brepro",
        "/pdbsourcepath:.",
    ],
)

cc_args(
    name = "include_paths",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    allowlist_include_directories = [
        "@{msvc_repo}//:include_dir",
        "@{winsdk_repo}//:ucrt_include",
        "@{winsdk_repo}//:um_include",
        "@{winsdk_repo}//:shared_include",
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

filegroup(
    name = "file_ucrt",
    srcs = ["@{winsdk_repo}//:Lib/10.0.{winsdk_version}.0/ucrt/{target}/ucrt.lib"],
)

filegroup(
    name = "file_msvcrt",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/msvcrt.lib"],
)

filegroup(
    name = "file_vcruntime",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/vcruntime.lib"],
)

filegroup(
    name = "file_msvcprt",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/msvcprt.lib"],
)

filegroup(
    name = "file_libucrt",
    srcs = ["@{winsdk_repo}//:Lib/10.0.{winsdk_version}.0/ucrt/{target}/libucrt.lib"],
)

filegroup(
    name = "file_libvcruntime",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/libvcruntime.lib"],
)

filegroup(
    name = "file_libcmt",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/libcmt.lib"],
)

filegroup(
    name = "file_libcpmt",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/libcpmt.lib"],
)

filegroup(
    name = "file_ucrtd",
    srcs = ["@{winsdk_repo}//:Lib/10.0.{winsdk_version}.0/ucrt/{target}/ucrtd.lib"],
)

filegroup(
    name = "file_msvcrtd",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/msvcrtd.lib"],
)

filegroup(
    name = "file_vcruntimed",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/vcruntimed.lib"],
)

filegroup(
    name = "file_msvcprtd",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/msvcprtd.lib"],
)

filegroup(
    name = "file_libucrtd",
    srcs = ["@{winsdk_repo}//:Lib/10.0.{winsdk_version}.0/ucrt/{target}/libucrtd.lib"],
)

filegroup(
    name = "file_libvcruntimed",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/libvcruntimed.lib"],
)

filegroup(
    name = "file_libcmtd",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/libcmtd.lib"],
)

filegroup(
    name = "file_libcpmtd",
    srcs = ["@{msvc_repo}//:Tools/lib/{target}/libcpmtd.lib"],
)

cc_args(
    name = "release_dynamic_runtime_link",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "{ucrt}",
        "{msvcrt}",
        "{vcruntime}",
        "{msvcprt}",
    ],
    data = [
        ":file_ucrt",
        ":file_msvcrt",
        ":file_vcruntime",
        ":file_msvcprt",
    ],
    format = {
        "ucrt": ":file_ucrt",
        "msvcrt": ":file_msvcrt",
        "vcruntime": ":file_vcruntime",
        "msvcprt": ":file_msvcprt",
    },
    requires_any_of = ["{features_package}/clang:no_static_no_debug_constraint"],
)

cc_args(
    name = "release_static_runtime_link",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "{libucrt}",
        "{libvcruntime}",
        "{libcmt}",
        "{libcpmt}",
    ],
    data = [
        ":file_libucrt",
        ":file_libvcruntime",
        ":file_libcmt",
        ":file_libcpmt",
    ],
    format = {
        "libucrt": ":file_libucrt",
        "libvcruntime": ":file_libvcruntime",
        "libcmt": ":file_libcmt",
        "libcpmt": ":file_libcpmt",
    },
    requires_any_of = ["{features_package}/clang:static_no_debug_constraint"],
)

cc_args(
    name = "debug_dynamic_runtime_link",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "{ucrtd}",
        "{msvcrtd}",
        "{vcruntimed}",
        "{msvcprtd}",
    ],
    data = [
        ":file_ucrtd",
        ":file_msvcrtd",
        ":file_vcruntimed",
        ":file_msvcprtd",
    ],
    format = {
        "ucrtd": ":file_ucrtd",
        "msvcrtd": ":file_msvcrtd",
        "vcruntimed": ":file_vcruntimed",
        "msvcprtd": ":file_msvcprtd",
    },
    requires_any_of = ["{features_package}/clang:no_static_debug_constraint"],
)

cc_args(
    name = "debug_static_runtime_link",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "{libucrtd}",
        "{libvcruntimed}",
        "{libcmtd}",
        "{libcpmtd}",
    ],
    data = [
        ":file_libucrtd",
        ":file_libvcruntimed",
        ":file_libcmtd",
        ":file_libcpmtd",
    ],
    format = {
        "libucrtd": ":file_libucrtd",
        "libvcruntimed": ":file_libvcruntimed",
        "libcmtd": ":file_libcmtd",
        "libcpmtd": ":file_libcpmtd",
    },
    requires_any_of = ["{features_package}/clang:static_debug_constraint"],
)

# cc_toolchain
cc_toolchain(
    name = "cc_toolchain",
    compiler = "{compiler}",
    supports_param_files = True,
    args = [
        ":base_compile_flags",
        ":base_link_flags",
        ":include_paths",
        ":release_dynamic_runtime_link",
        ":release_static_runtime_link",
        ":debug_dynamic_runtime_link",
        ":debug_static_runtime_link",
    ],
    artifact_name_patterns = [
        "{artifacts_package}:executable",
        "{artifacts_package}:object_file",
        "{artifacts_package}:static_library",
        "{artifacts_package}:alwayslink_static_library",
        "{artifacts_package}:dynamic_library",
        "{artifacts_package}:interface_library",
    ],
    enabled_features = [
        "{features_package}/clang:default_features",
        "{features_package}/clang:dependency_file",
    ],
    known_features = [
        "{features_package}/clang:all_known_features",
    ],
    tool_map = ":all_tools",
)
