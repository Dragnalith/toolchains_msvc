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
        "@rules_cc//cc/toolchains/actions:c_compile": ":cl",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions": ":cl",
        "@rules_cc//cc/toolchains/actions:link_actions": ":link",
        "@rules_cc//cc/toolchains/actions:ar_actions": ":lib",
        "@rules_cc//cc/toolchains/actions:strip": ":link",
    },
    visibility = ["//visibility:public"],
)

cc_tool(
    name = "cl",
    src = "@{msvc_repo}//:cl_host{host}_target{target}",
    data = [
        "@{msvc_repo}//:msvc_all_binaries_host{host}_target{target}",
        "@{msvc_repo}//:msvc_all_includes",
    ],
)

cc_tool(
    name = "link",
    src = "@{msvc_repo}//:link_host{host}_target{target}",
    data = [
        "@{msvc_repo}//:msvc_all_binaries_host{host}_target{target}",
        "@{msvc_repo}//:msvc_all_libs_{target}",
    ],
)

cc_tool(
    name = "lib",
    src = "@{msvc_repo}//:lib_host{host}_target{target}",
    data = [
        "@{msvc_repo}//:msvc_all_binaries_host{host}_target{target}",
    ],
)

cc_tool(
    name = "ml64",
    src = "@{msvc_repo}//:ml64_host{host}_target{target}",
    data = [
        "@{msvc_repo}//:msvc_all_binaries_host{host}_target{target}",
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
        "/nologo",
    ],
)

cc_args(
    name = "base_link_flags",
    actions = [
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "/nologo",
        "/NODEFAULTLIB",
        "/INCREMENTAL:NO"    ],
)

cc_args(
    name = "include_paths",
    actions = [
        "@rules_cc//cc/toolchains/actions:c_compile",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "/external:W0",
        "/external:I",
        "{msvc_include}",
        "/external:I",
        "{winsdk_ucrt_include}",
        "/external:I",
        "{winsdk_um_include}",
        "/external:I",
        "{winsdk_shared_include}",
    ],
    data = [
        "@{msvc_repo}//:msvc_all_includes",
        "@{winsdk_repo}//:shared_include_files",
        "@{winsdk_repo}//:ucrt_include_files",
        "@{winsdk_repo}//:um_include_files",
    ],
    format = {
        "msvc_include": "@{msvc_repo}//:include_dir",
        "winsdk_ucrt_include": "@{winsdk_repo}//:ucrt_include",
        "winsdk_um_include": "@{winsdk_repo}//:um_include",
        "winsdk_shared_include": "@{winsdk_repo}//:shared_include",
    },
)

cc_args(
    name = "lib_paths",
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
        "@{winsdk_repo}//:ucrt_lib_dir_files_x64",
        "@{winsdk_repo}//:um_lib_dir_files_x64",
    ],
    format = {
        "msvc_lib": "@{msvc_repo}//:lib_dir_{target}",
        "winsdk_um_lib": "@{winsdk_repo}//:um_lib_dir_{target}",
        "winsdk_ucrt_lib": "@{winsdk_repo}//:ucrt_lib_dir_{target}",
    },
)

cc_toolchain(
    name = "cc_toolchain",
    args = [
        "base_compile_flags",
        "base_link_flags",
        "include_paths",
        "lib_paths",
    ],
    artifact_name_patterns = [
        "//artifacts:executable",
        "//artifacts:object_file",
        "//artifacts:static_library",
        "//artifacts:alwayslink_static_library",
        "//artifacts:dynamic_library",
        "//artifacts:interface_library",
    ],
    compiler = "{compiler}",
    enabled_features = [
        "//msvc/features:default_features",
        "//msvc/features:no_dotd_file",
        "//msvc/features:parse_showincludes",
    ],
    known_features = [
        "//msvc/features:all_known_features",
    ],
    tool_map = ":all_tools",
)
