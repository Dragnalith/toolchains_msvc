load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")

package(default_visibility = ["//visibility:public"])

cc_toolchain(
    name = "cc_toolchain",
    args = [
        "//toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/args:msvc_compile_flags",
        "//toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/args:msvc_include_paths",
        "//toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/args:warnings",
        "//toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/args:msvc_link_flags",
        "//toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/args:msvc_lib_paths",
        "//toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/args:ar_flags",
        "//toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/args:fastbuild_compile_flags",
        "//toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/args:msvc_strip_args",
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
        "//msvc/features:msvc_features",
    ],
    known_features = [
        "//msvc/features:msvc_features",
    ],
    tool_map = "//toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/tools:all_tools",
)
