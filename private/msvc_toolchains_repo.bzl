"""Repository rule to define MSVC toolchains."""

load("//private:utils.bzl", "convert_msvc_arch_to_bazel_arch", "convert_msvc_arch_to_clang_target", "msvc_version_to_cl_internal_version")

def _msvc_toolchains_repo_impl(ctx):
    # This repo will just contain the BUILD file defining the toolchains.
    # It assumes the compiler repo is available as external repo.

    msvc_versions = ctx.attr.msvc_versions
    clang_versions = ctx.attr.clang_versions
    winsdk_versions = ctx.attr.winsdk_versions
    targets = ctx.attr.targets
    hosts = ctx.attr.hosts

    # Install shared features
    ctx.template(
        "msvc/features/BUILD.bazel",
        ctx.attr.src_features,
        substitutions = {
            "{COMPILER_KIND}": "msvc",
        },
    )

    ctx.template(
        "clang/features/BUILD.bazel",
        ctx.attr.src_features,
        substitutions = {
            "{COMPILER_KIND}": "clang",
        },
    )

    # Install shared args
    ctx.template(
        "msvc/args/BUILD.bazel",
        ctx.attr.src_args_msvc,
        substitutions = {
            "{COMPILER_KIND}": "msvc",
        },
    )

    ctx.template(
        "clang/args/BUILD.bazel",
        ctx.attr.src_args_clang,
        substitutions = {
            "{COMPILER_KIND}": "clang",
        },
    )

    # Install shared artifacts
    ctx.template(
        "artifacts/BUILD.bazel",
        ctx.attr.src_artifacts,
    )

    # Install per-toolchain BUILD files
    for winsdk_version in winsdk_versions:
        for msvc_version in msvc_versions:
            for host in hosts:
                for target in targets:
                    toolchain_name = "toolchain_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}".format(
                        msvc_version = msvc_version,
                        winsdk_version = winsdk_version,
                        host = host,
                        target = target,
                    )

                    # Install MSVC toolchain
                    ctx.template(
                        "{toolchain_name}/BUILD.bazel".format(toolchain_name = toolchain_name),
                        ctx.attr.src_toolchain_msvc,
                        substitutions = {
                            "{toolchain_name}": toolchain_name,
                            "{compiler}": "msvc-cl",
                            "{msvc_repo}": "msvc_{}".format(msvc_version),
                            "{winsdk_repo}": "winsdk_{}".format(winsdk_version),
                            "{msvc_version}": msvc_version,
                            "{winsdk_version}": winsdk_version,
                            "{target}": target,
                            "{host}": host,
                        },
                    )

                    for clang_version in clang_versions:
                        if host == "x86":
                            continue  # LLVM does not provide x86 Windows binaries
                        clang_target = convert_msvc_arch_to_clang_target(target)
                        compatibility_version = msvc_version_to_cl_internal_version(msvc_version)

                        clang_toolchain_name = "toolchain_clang{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}".format(
                            clang_version = clang_version,
                            msvc_version = msvc_version,
                            winsdk_version = winsdk_version,
                            host = host,
                            target = target,
                        )

                        # Install Clang toolchain
                        ctx.template(
                            "{toolchain_name}/BUILD.bazel".format(toolchain_name = clang_toolchain_name),
                            ctx.attr.src_toolchain_clang,
                            substitutions = {
                                "{toolchain_name}": clang_toolchain_name,
                                "{compiler}": "clang",
                                "{llvm_repo}": "llvm_{}_{}".format(clang_version, host),
                                "{msvc_repo}": "msvc_{}".format(msvc_version),
                                "{winsdk_repo}": "winsdk_{}".format(winsdk_version),
                                "{clang_version}": clang_version,
                                "{msvc_version}": msvc_version,
                                "{winsdk_version}": winsdk_version,
                                "{clang_target}": clang_target,
                                "{cl_internal_version}": compatibility_version,
                                "{target}": target,
                                "{host}": host,
                            },
                        )

                        clang_cl_toolchain_name = "toolchain_clang-cl{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}".format(
                            clang_version = clang_version,
                            msvc_version = msvc_version,
                            winsdk_version = winsdk_version,
                            host = host,
                            target = target,
                        )

                        # Install Clang-CL toolchain
                        ctx.template(
                            "{toolchain_name}/BUILD.bazel".format(toolchain_name = clang_cl_toolchain_name),
                            ctx.attr.src_toolchain_clang_cl,
                            substitutions = {
                                "{toolchain_name}": clang_cl_toolchain_name,
                                "{compiler}": "clang-cl",
                                "{llvm_repo}": "llvm_{}_{}".format(clang_version, host),
                                "{msvc_repo}": "msvc_{}".format(msvc_version),
                                "{winsdk_repo}": "winsdk_{}".format(winsdk_version),
                                "{clang_target}": clang_target,
                                "{cl_internal_version}": compatibility_version,
                                "{msvc_version}": msvc_version,
                                "{winsdk_version}": winsdk_version,
                                "{target}": target,
                                "{host}": host,
                            },
                        )

    # Generate root BUILD.bazel with toolchain registrations
    root_build_file_content = """
package(default_visibility = ["//visibility:public"])

"""

    for winsdk_version in winsdk_versions:
        for msvc_version in msvc_versions:
            for target in targets:
                for host in hosts:
                    target_arch = convert_msvc_arch_to_bazel_arch(target)
                    host_arch = convert_msvc_arch_to_bazel_arch(host)
                    root_build_file_content += """
toolchain(
    name = "msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}",
    exec_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{host_arch}",
    ],
    target_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{target_arch}",
    ],
    toolchain = "//toolchain_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}:cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

    """.format(msvc_version = msvc_version, winsdk_version = winsdk_version, host = host, target = target, target_arch = target_arch, host_arch = host_arch)

                    for clang_version in clang_versions:
                        if host == "x86":
                            continue  # LLVM does not provide x86 Windows binaries
                        root_build_file_content += """
toolchain(
    name = "clang{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}",
    exec_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{host_arch}",
    ],
    target_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{target_arch}",
    ],
    toolchain = "//toolchain_clang{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}:cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

toolchain(
    name = "clang-cl{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}",
    exec_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{host_arch}",
    ],
    target_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{target_arch}",
    ],
    toolchain = "//toolchain_clang-cl{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}:cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

    """.format(clang_version = clang_version, msvc_version = msvc_version, winsdk_version = winsdk_version, host = host, target = target, target_arch = target_arch, host_arch = host_arch)

    ctx.file("BUILD.bazel", root_build_file_content)

msvc_toolchains_repo = repository_rule(
    implementation = _msvc_toolchains_repo_impl,
    attrs = {
        "msvc_versions": attr.string_list(mandatory = True),
        "clang_versions": attr.string_list(mandatory = True),
        "winsdk_versions": attr.string_list(mandatory = True),
        "targets": attr.string_list(mandatory = True),
        "hosts": attr.string_list(mandatory = True),
        "src_features": attr.label(default = Label("//overlays/toolchain:BUILD.features.tpl"), allow_single_file = True),
        "src_artifacts": attr.label(default = Label("//overlays/toolchain:BUILD.artifacts.bazel"), allow_single_file = True),
        "src_args_msvc": attr.label(default = Label("//overlays/toolchain:BUILD.args-msvc.tpl"), allow_single_file = True),
        "src_args_clang": attr.label(default = Label("//overlays/toolchain:BUILD.args-clang.tpl"), allow_single_file = True),
        "src_toolchain_msvc": attr.label(default = Label("//overlays/toolchain/cl:BUILD.toolchain.tpl"), allow_single_file = True),
        "src_toolchain_clang": attr.label(default = Label("//overlays/toolchain/clang:BUILD.toolchain.tpl"), allow_single_file = True),
        "src_toolchain_clang_cl": attr.label(default = Label("//overlays/toolchain/clang-cl:BUILD.toolchain.tpl"), allow_single_file = True),
    },
)
