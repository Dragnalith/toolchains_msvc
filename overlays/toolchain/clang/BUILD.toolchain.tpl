load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")

package(default_visibility = ["//visibility:public"])

cc_toolchain(
    name = "cc_toolchain",
    compiler = "{compiler}",
    args = [
        "//{toolchain_name}/args:nostdinc",
        "//{toolchain_name}/args:base_compile_flags",
        "//{toolchain_name}/args:msvc_include_paths",
        "//{toolchain_name}/args:warnings",
        "//{toolchain_name}/args:msvc_link_flags",
        "//{toolchain_name}/args:msvc_lib_paths",
        "//{toolchain_name}/args:ar_flags",
        "//{toolchain_name}/args:fastbuild_compile_flags",
        "//{toolchain_name}/args:msvc_strip_args",
    ],
    artifact_name_patterns = [
        "//msvc/artifacts:executable",
        "//msvc/artifacts:object_file",
        "//msvc/artifacts:static_library",
        "//msvc/artifacts:alwayslink_static_library",
        "//msvc/artifacts:dynamic_library",
        "//msvc/artifacts:interface_library",
    ],
    enabled_features = [
        "//clang/features:clang_features",
    ],
    known_features = [
        "//clang/features:clang_features",
    ],
    tool_map = "//{toolchain_name}/tools:all_tools",
)
