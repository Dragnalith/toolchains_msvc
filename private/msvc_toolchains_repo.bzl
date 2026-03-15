"""Repository rule to define MSVC toolchains."""

load("//private:libs.bzl", "msvc_lib", "ucrt_lib", "um_lib")
load("//private:utils.bzl", "convert_msvc_arch_to_bazel_arch", "convert_msvc_arch_to_clang_target", "msvc_version_to_cl_internal_version")

def _normalize_lib_name(lib_name):
    """Returns lowercase name without .lib extension."""
    name = lib_name.lower()
    if name.endswith(".lib"):
        return name[:-4]
    return name

def _add_lib_variant(lib_map, lib_name, config_name, label):
    variants = lib_map.get(lib_name)
    if variants == None:
        variants = {}
        lib_map[lib_name] = variants

    existing = variants.get(config_name)
    if existing != None and existing != label:
        fail("Library '{}' has conflicting variants for '{}': '{}' and '{}'".format(lib_name, config_name, existing, label))

    variants[config_name] = label

def _msvc_toolchains_repo_impl(ctx):
    # This repo will just contain the BUILD file defining the toolchains.
    # It assumes the compiler repo is available as external repo.

    # Install common.bzl (string_enum_flag) at repo root
    ctx.template("common.bzl", ctx.attr.src_common, {})

    msvc_versions = ctx.attr.msvc_versions
    msvc_lld_link_version = ctx.attr.msvc_lld_link_version
    clang_versions = ctx.attr.clang_versions
    winsdk_versions = ctx.attr.winsdk_versions
    targets = ctx.attr.targets
    hosts = ctx.attr.hosts

    # Defaults are now resolved in the module extension
    default_msvc_value = ctx.attr.default_msvc
    default_winsdk_value = ctx.attr.default_windows_sdk
    default_llvm_value = ctx.attr.default_clang if ctx.attr.default_clang else "unknown"
    default_compiler_value = ctx.attr.default_compiler

    # Install shared features
    ctx.template(
        "features/msvc/BUILD.bazel",
        ctx.attr.src_features,
        substitutions = {
            "{COMPILER_KIND}": "msvc",
        },
    )

    ctx.template(
        "features/clang/BUILD.bazel",
        ctx.attr.src_features,
        substitutions = {
            "{COMPILER_KIND}": "clang",
        },
    )

    # Install shared args
    ctx.template(
        "args/msvc/BUILD.bazel",
        ctx.attr.src_args_msvc,
        substitutions = {
            "{COMPILER_KIND}": "msvc",
        },
    )

    ctx.template(
        "args/clang/BUILD.bazel",
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
                    toolchain_name = "msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}".format(
                        msvc_version = msvc_version,
                        winsdk_version = winsdk_version,
                        host = host,
                        target = target,
                    )

                    msvc_repo = "msvc_{}".format(msvc_version)
                    if msvc_lld_link_version:
                        if msvc_lld_link_version not in clang_versions:
                            fail("msvc_lld_link_version must be in clang_versions")
                        lld_link_llvm_repo = "llvm_{}_{}".format(clang_versions[0], host)
                        link_cc_tool = """cc_tool(
    name = "link",
    src = "@{llvm_repo}//:lld-link_host{host}_target{target}",
    data = [
        "@{llvm_repo}//:lld_link_exe_only_host{host}_target{target}",
    ],
)""".format(llvm_repo = lld_link_llvm_repo, msvc_repo = msvc_repo, host = host, target = target)
                        base_link_flags = """base_link_flags = [
    "/lldignoreenv",
    "/NODEFAULTLIB",
    "/INCREMENTAL:NO",
    "/PDBALTPATH:%_PDB%",
    "/Brepro",
    "/pdbsourcepath:.",
]"""

                    else:
                        link_cc_tool = """cc_tool(
    name = "link",
    src = "@{msvc_repo}//:link_host{host}_target{target}",
    data = [
        "@{msvc_repo}//:msvc_all_binaries_host{host}_target{target}",
    ],
)""".format(msvc_repo = msvc_repo, host = host, target = target)
                        base_link_flags = """base_link_flags = [
    "/nologo",
    "/NODEFAULTLIB",
    "/INCREMENTAL:NO",
    "/experimental:deterministic",
    "/Brepro",
    "/PDBALTPATH:%_PDB%",
]"""

                    # Install MSVC toolchain
                    ctx.template(
                        "toolchain/{toolchain_name}/BUILD.bazel".format(toolchain_name = toolchain_name),
                        ctx.attr.src_toolchain_msvc,
                        substitutions = {
                            "{toolchain_name}": toolchain_name,
                            "{compiler}": "msvc-cl",
                            "{msvc_repo}": msvc_repo,
                            "{link_cc_tool}": link_cc_tool,
                            "{base_link_flags}": base_link_flags,
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

                        clang_toolchain_name = "clang{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}".format(
                            clang_version = clang_version,
                            msvc_version = msvc_version,
                            winsdk_version = winsdk_version,
                            host = host,
                            target = target,
                        )

                        # Install Clang toolchain
                        ctx.template(
                            "toolchain/{toolchain_name}/BUILD.bazel".format(toolchain_name = clang_toolchain_name),
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

                        clang_cl_toolchain_name = "clang-cl{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}".format(
                            clang_version = clang_version,
                            msvc_version = msvc_version,
                            winsdk_version = winsdk_version,
                            host = host,
                            target = target,
                        )

                        # Install Clang-CL toolchain
                        ctx.template(
                            "toolchain/{toolchain_name}/BUILD.bazel".format(toolchain_name = clang_cl_toolchain_name),
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

    ctx.file("winsdk/BUILD.bazel", """load("//:common.bzl", "string_enum_flag")

package(default_visibility = ["//visibility:public"])

string_enum_flag(
    name = "winsdk",
    build_setting_default = "{default_winsdk}",
    allowed_values = {allowed_winsdk},
)

{config_settings}
""".format(
        default_winsdk = default_winsdk_value,
        allowed_winsdk = winsdk_versions,
        config_settings = "\n".join([
            """config_setting(
    name = "{v}",
    flag_values = {{":winsdk": "{v}"}},
)""".format(v = v)
            for v in winsdk_versions
        ]),
    ))

    ctx.file("msvc/BUILD.bazel", """load("//:common.bzl", "string_enum_flag")

package(default_visibility = ["//visibility:public"])

string_enum_flag(
    name = "msvc",
    build_setting_default = "{default_msvc}",
    allowed_values = {allowed_msvc},
)

{config_settings}
""".format(
        default_msvc = default_msvc_value,
        allowed_msvc = msvc_versions,
        config_settings = "\n".join([
            """config_setting(
    name = "{v}",
    flag_values = {{":msvc": "{v}"}},
)""".format(v = v)
            for v in msvc_versions
        ]),
    ))

    ctx.file("llvm/BUILD.bazel", """load("//:common.bzl", "string_enum_flag")

package(default_visibility = ["//visibility:public"])

string_enum_flag(
    name = "llvm",
    build_setting_default = "{default_llvm}",
    allowed_values = {allowed_llvm},
)

{config_settings}
""".format(
        default_llvm = default_llvm_value,
        allowed_llvm = clang_versions,
        config_settings = "\n".join([
            """config_setting(
    name = "{v}",
    flag_values = {{":llvm": "{v}"}},
)""".format(v = v)
            for v in clang_versions
        ]),
    ))

    ctx.file("compiler/BUILD.bazel", """load("//:common.bzl", "string_enum_flag")

package(default_visibility = ["//visibility:public"])

string_enum_flag(
    name = "compiler",
    build_setting_default = "{default_compiler}",
    allowed_values = [
        "msvc-cl",
        "clang-cl",
        "clang",
    ],
)

{config_settings}
""".format(
        default_compiler = default_compiler_value,
        config_settings = "\n".join([
            """config_setting(
    name = "{v}",
    flag_values = {{":compiler": "{v}"}},
)""".format(v = v)
            for v in ["msvc-cl", "clang-cl", "clang"]
        ]),
    ))

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
    target_settings = [
        "//winsdk:{winsdk_version}",
        "//msvc:{msvc_version}",
        "//compiler:msvc-cl",
    ],
    toolchain = "//toolchain/msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}:cc_toolchain",
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
    target_settings = [
        "//winsdk:{winsdk_version}",
        "//msvc:{msvc_version}",
        "//llvm:{clang_version}",
        "//compiler:clang",
    ],
    toolchain = "//toolchain/clang{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}:cc_toolchain",
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
    target_settings = [
        "//winsdk:{winsdk_version}",
        "//msvc:{msvc_version}",
        "//llvm:{clang_version}",
        "//compiler:clang-cl",
    ],
    toolchain = "//toolchain/clang-cl{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}:cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

    """.format(clang_version = clang_version, msvc_version = msvc_version, winsdk_version = winsdk_version, host = host, target = target, target_arch = target_arch, host_arch = host_arch)

    ctx.file("BUILD.bazel", root_build_file_content)

    # Generate lib/BUILD.bazel with cc_import targets
    lib_build_file_content = """load("@rules_cc//cc:defs.bzl", "cc_import")

package(default_visibility = ["//visibility:public"])

"""

    # 1. Define config_settings for WinSDK and MSVC library selection.
    for winsdk_version in winsdk_versions:
        for target in targets:
            target_arch = convert_msvc_arch_to_bazel_arch(target)
            lib_build_file_content += """
config_setting(
    name = "winsdk{winsdk_version}_{target}",
    flag_values = {{
        "//winsdk:winsdk": "{winsdk_version}",
    }},
    constraint_values = ["@platforms//cpu:{target_arch}"],
)
""".format(
                winsdk_version = winsdk_version,
                target = target,
                target_arch = target_arch,
            )

    for msvc_version in msvc_versions:
        for target in targets:
            target_arch = convert_msvc_arch_to_bazel_arch(target)
            lib_build_file_content += """
config_setting(
    name = "msvc{msvc_version}_{target}",
    flag_values = {{
        "//msvc:msvc": "{msvc_version}",
    }},
    constraint_values = ["@platforms//cpu:{target_arch}"],
)
""".format(
                msvc_version = msvc_version,
                target = target,
                target_arch = target_arch,
            )

    msvc_libs = {}
    winsdk_libs = {}

    # 2. Build lib maps from predefined lists in libs.bzl.
    for winsdk_version in winsdk_versions:
        for target in targets:
            config_name = ":winsdk{winsdk_version}_{target}".format(
                winsdk_version = winsdk_version,
                target = target,
            )

            for lib_name in ucrt_lib:
                lib_path = "Lib/10.0.{winsdk_version}.0/ucrt/{target}/{lib_name}".format(
                    winsdk_version = winsdk_version,
                    target = target,
                    lib_name = lib_name.lower(),
                )
                _add_lib_variant(
                    winsdk_libs,
                    _normalize_lib_name(lib_name),
                    config_name,
                    "@winsdk_{}//:{}".format(winsdk_version, lib_path),
                )

            for lib_name in um_lib:
                lib_path = "Lib/10.0.{winsdk_version}.0/um/{target}/{lib_name}".format(
                    winsdk_version = winsdk_version,
                    target = target,
                    lib_name = lib_name.lower(),
                )
                _add_lib_variant(
                    winsdk_libs,
                    _normalize_lib_name(lib_name),
                    config_name,
                    "@winsdk_{}//:{}".format(winsdk_version, lib_path),
                )

    for msvc_version in msvc_versions:
        for target in targets:
            config_name = ":msvc{msvc_version}_{target}".format(
                msvc_version = msvc_version,
                target = target,
            )

            for lib_name in msvc_lib:
                lib_path = "Tools/lib/{target}/{lib_name}".format(
                    target = target,
                    lib_name = lib_name.lower(),
                )
                _add_lib_variant(
                    msvc_libs,
                    _normalize_lib_name(lib_name),
                    config_name,
                    "@msvc_{}//:{}".format(msvc_version, lib_path),
                )

    # 3. Emit cc_import targets for all discovered libraries.
    all_lib_names = {}
    for lib_name in winsdk_libs.keys():
        all_lib_names[lib_name] = "winsdk"
    for lib_name in msvc_libs.keys():
        existing_origin = all_lib_names.get(lib_name)
        if existing_origin != None and existing_origin != "msvc":
            fail("Library '{}' exists in both WinSDK and MSVC repos; disambiguated target names are required".format(lib_name))
        all_lib_names[lib_name] = "msvc"

    for lib_name in sorted(all_lib_names.keys()):
        if lib_name in winsdk_libs:
            variants = winsdk_libs[lib_name]
        else:
            variants = msvc_libs[lib_name]

        lib_build_file_content += "\ncc_import(\n    name = \"{}\",\n    interface_library = select({{\n".format(lib_name)
        for config_name in sorted(variants.keys()):
            lib_build_file_content += "        \"{}\": \"{}\",\n".format(config_name, variants[config_name])
        lib_build_file_content += "    }),\n    system_provided = True,\n)\n"

    ctx.file("lib/BUILD.bazel", lib_build_file_content)

msvc_toolchains_repo = repository_rule(
    implementation = _msvc_toolchains_repo_impl,
    attrs = {
        "msvc_versions": attr.string_list(mandatory = True),
        "msvc_lld_link_version": attr.string(mandatory = False),
        "clang_versions": attr.string_list(mandatory = True),
        "winsdk_versions": attr.string_list(mandatory = True),
        "targets": attr.string_list(mandatory = True),
        "hosts": attr.string_list(mandatory = True),
        "default_msvc": attr.string(mandatory = True),
        "default_clang": attr.string(mandatory = False),
        "default_windows_sdk": attr.string(mandatory = True),
        "default_compiler": attr.string(mandatory = True),
        "src_features": attr.label(default = Label("//overlays/toolchain:BUILD.features.tpl"), allow_single_file = True),
        "src_artifacts": attr.label(default = Label("//overlays/toolchain:BUILD.artifacts.bazel"), allow_single_file = True),
        "src_args_msvc": attr.label(default = Label("//overlays/toolchain:BUILD.args-msvc.tpl"), allow_single_file = True),
        "src_args_clang": attr.label(default = Label("//overlays/toolchain:BUILD.args-clang.tpl"), allow_single_file = True),
        "src_toolchain_msvc": attr.label(default = Label("//overlays/toolchain/msvc-cl:BUILD.toolchain.tpl"), allow_single_file = True),
        "src_toolchain_clang": attr.label(default = Label("//overlays/toolchain/clang:BUILD.toolchain.tpl"), allow_single_file = True),
        "src_toolchain_clang_cl": attr.label(default = Label("//overlays/toolchain/clang-cl:BUILD.toolchain.tpl"), allow_single_file = True),
        "src_common": attr.label(default = Label("//overlays:common.bzl"), allow_single_file = True),
    },
)
