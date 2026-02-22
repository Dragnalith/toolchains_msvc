"""Repository rule to define MSVC toolchains."""

load("//private:utils.bzl", "convert_msvc_arch_to_bazel_arch")

def _msvc_toolchains_repo_impl(ctx):
    # This repo will just contain the BUILD file defining the toolchains.
    # It assumes the compiler repo is available as external repo.

    msvc_versions = ctx.attr.msvc_versions
    winsdk_versions = ctx.attr.winsdk_versions
    targets = ctx.attr.targets
    hosts = ctx.attr.hosts

    # Install BUILD.features.bazel
    ctx.template(
        "msvc/features/BUILD.bazel",
        ctx.attr.src_features,
    )

    # Install BUILD.artifacts.bazel
    ctx.template(
        "msvc/artifacts/BUILD.bazel",
        ctx.attr.src_artifacts,
    )

    for winsdk_version in winsdk_versions:
        for msvc_version in msvc_versions:
            for host in hosts:
                for target in targets:
                    # Install BUILD.args.bazel
                    ctx.template(
                        "toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/args/BUILD.bazel".format(msvc_version = msvc_version, host = host, target = target, winsdk_version = winsdk_version),
                        ctx.attr.src_args,
                        substitutions = {
                            "{msvc_repo}": "msvc_{}".format(msvc_version),
                            "{winsdk_repo}": "winsdk_{}".format(winsdk_version),
                            "{target}": target,
                            "{host}": host,
                        },
                    )

                    # Install BUILD.toolchain.bazel
                    ctx.template(
                        "toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/BUILD.bazel".format(msvc_version = msvc_version, host = host, target = target, winsdk_version = winsdk_version),
                        ctx.attr.src_toolchain,
                        substitutions = {
                            "{msvc_version}": msvc_version,
                            "{winsdk_version}": winsdk_version,
                            "{target}": target,
                            "{host}": host,
                        },
                    )

                    # Install BUILD.tools.tpl
                    ctx.template(
                        "toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}/tools/BUILD.bazel".format(msvc_version = msvc_version, host = host, target = target, winsdk_version = winsdk_version),
                        ctx.attr.src_tools,
                        substitutions = {
                            "{msvc_repo}": "msvc_{}".format(msvc_version),
                            "{target}": target,
                            "{host}": host,
                        },
                    )

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
    name = "msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}_toolchain",
    exec_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{host_arch}",
    ],
    target_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{target_arch}",
    ],
    toolchain = "//toolchain_msvc_{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}:cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

    """.format(msvc_version = msvc_version, winsdk_version = winsdk_version, host = host, target = target, target_arch = target_arch, host_arch = host_arch)

    # Generate empty root BUILD.bazel to define the package
    ctx.file("BUILD.bazel", root_build_file_content)

msvc_toolchains_repo = repository_rule(
    implementation = _msvc_toolchains_repo_impl,
    attrs = {
        "msvc_versions": attr.string_list(mandatory = True),
        "winsdk_versions": attr.string_list(mandatory = True),
        "targets": attr.string_list(mandatory = True),
        "hosts": attr.string_list(mandatory = True),
        "src_features": attr.label(default = Label("//overlays/toolchain/msvc:BUILD.features.bazel"), allow_single_file = True),
        "src_artifacts": attr.label(default = Label("//overlays/toolchain/msvc:BUILD.artifacts.bazel"), allow_single_file = True),
        "src_args": attr.label(default = Label("//overlays/toolchain/msvc:BUILD.args.tpl"), allow_single_file = True),
        "src_toolchain": attr.label(default = Label("//overlays/toolchain/msvc:BUILD.toolchain.tpl"), allow_single_file = True),
        "src_tools": attr.label(default = Label("//overlays/toolchain/msvc:BUILD.tools.tpl"), allow_single_file = True),
    },
)
