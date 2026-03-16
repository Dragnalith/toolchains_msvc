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

def _append_list_line(content, var_name, values, item_prefix = ""):
    """Appends 'var_name = [item_prefix"v1", item_prefix"v2", ...]' for generated .bzl files."""
    if not values:
        s = "[]"
    else:
        # Escape so generated Starlark is valid if a value contains backslash or quote
        escaped = ["\"" + item_prefix + str(x).replace("\\", "\\\\").replace("\"", "\\\"") + "\"" for x in values]
        s = "[" + ", ".join(escaped) + "]"
    return content + var_name + " = " + s + "\n"

def _toolchain_set_prefix(group_name):
    return "toolchain_set/{}".format(group_name)

def _msvc_toolchains_repo_impl(ctx):
    # Install common.bzl (string_enum_flag) at repo root
    ctx.template("common.bzl", ctx.attr.src_common, {})

    group_configs = json.decode(ctx.attr.group_configs)
    msvc_versions = ctx.attr.msvc_versions
    llvm_versions = ctx.attr.llvm_versions
    winsdk_versions = ctx.attr.winsdk_versions
    targets = ctx.attr.targets

    default_msvc_value = ctx.attr.default_msvc_version
    default_winsdk_value = ctx.attr.default_windows_sdk_version
    default_llvm_value = ctx.attr.default_clang_version if ctx.attr.default_clang_version else "unknown"
    default_compiler_value = ctx.attr.default_compiler
    default_toolchain_set_value = ctx.attr.default_toolchain_set

    root_build_file_content = """
package(default_visibility = ["//visibility:public"])
"""

    for group in group_configs:
        group_name = group["name"]
        group_prefix = _toolchain_set_prefix(group_name)
        features_package = "//{}".format(group_prefix + "/features")
        args_package = "//{}".format(group_prefix + "/args")
        artifacts_package = "//{}".format(group_prefix + "/artifacts")

        ctx.template(
            "{}/features/msvc/BUILD.bazel".format(group_prefix),
            ctx.attr.src_features,
            substitutions = {
                "{COMPILER_KIND}": "msvc",
                "{features_package}": features_package,
                "{args_package}": args_package,
            },
        )
        ctx.template(
            "{}/features/clang/BUILD.bazel".format(group_prefix),
            ctx.attr.src_features,
            substitutions = {
                "{COMPILER_KIND}": "clang",
                "{features_package}": features_package,
                "{args_package}": args_package,
            },
        )

        msvc_flags_content = ""
        msvc_flags_content = _append_list_line(msvc_flags_content, "default_c_compile_flags", group["msvc_default_c_compile_flags"])
        msvc_flags_content = _append_list_line(msvc_flags_content, "default_cxx_compile_flags", group["msvc_default_cxx_compile_flags"])
        msvc_flags_content = _append_list_line(msvc_flags_content, "default_link_flags", group["msvc_default_link_flags"])
        msvc_flags_content = _append_list_line(msvc_flags_content, "dbg_c_compile_flags", group["msvc_dbg_c_compile_flags"])
        msvc_flags_content = _append_list_line(msvc_flags_content, "dbg_cxx_compile_flags", group["msvc_dbg_cxx_compile_flags"])
        msvc_flags_content = _append_list_line(msvc_flags_content, "dbg_link_flags", group["msvc_dbg_link_flags"])
        msvc_flags_content = _append_list_line(msvc_flags_content, "fastbuild_c_compile_flags", group["msvc_fastbuild_c_compile_flags"])
        msvc_flags_content = _append_list_line(msvc_flags_content, "fastbuild_cxx_compile_flags", group["msvc_fastbuild_cxx_compile_flags"])
        msvc_flags_content = _append_list_line(msvc_flags_content, "fastbuild_link_flags", group["msvc_fastbuild_link_flags"])
        msvc_flags_content = _append_list_line(msvc_flags_content, "opt_c_compile_flags", group["msvc_opt_c_compile_flags"])
        msvc_flags_content = _append_list_line(msvc_flags_content, "opt_cxx_compile_flags", group["msvc_opt_cxx_compile_flags"])
        msvc_flags_content = _append_list_line(msvc_flags_content, "opt_link_flags", group["msvc_opt_link_flags"])
        ctx.file("{}/args/msvc/flags.bzl".format(group_prefix), msvc_flags_content)

        clang_flags_content = ""
        clang_flags_content = _append_list_line(clang_flags_content, "default_c_compile_flags", group["clang_default_c_compile_flags"])
        clang_flags_content = _append_list_line(clang_flags_content, "default_cxx_compile_flags", group["clang_default_cxx_compile_flags"])
        clang_flags_content = _append_list_line(clang_flags_content, "default_link_flags", group["clang_default_link_flags"])
        clang_flags_content = _append_list_line(clang_flags_content, "dbg_c_compile_flags", group["clang_dbg_c_compile_flags"])
        clang_flags_content = _append_list_line(clang_flags_content, "dbg_cxx_compile_flags", group["clang_dbg_cxx_compile_flags"])
        clang_flags_content = _append_list_line(clang_flags_content, "dbg_link_flags", group["clang_dbg_link_flags"])
        clang_flags_content = _append_list_line(clang_flags_content, "fastbuild_c_compile_flags", group["clang_fastbuild_c_compile_flags"])
        clang_flags_content = _append_list_line(clang_flags_content, "fastbuild_cxx_compile_flags", group["clang_fastbuild_cxx_compile_flags"])
        clang_flags_content = _append_list_line(clang_flags_content, "fastbuild_link_flags", group["clang_fastbuild_link_flags"])
        clang_flags_content = _append_list_line(clang_flags_content, "opt_c_compile_flags", group["clang_opt_c_compile_flags"])
        clang_flags_content = _append_list_line(clang_flags_content, "opt_cxx_compile_flags", group["clang_opt_cxx_compile_flags"])
        clang_flags_content = _append_list_line(clang_flags_content, "opt_link_flags", group["clang_opt_link_flags"])
        ctx.file("{}/args/clang/flags.bzl".format(group_prefix), clang_flags_content)

        features_content = ""
        features_content = _append_list_line(features_content, "default_implied_features", group["default_features"], item_prefix = ":")
        features_content = _append_list_line(features_content, "dbg_implied_features", group["dbg_implies_features"], item_prefix = ":")
        features_content = _append_list_line(features_content, "fastbuild_implied_features", group["fastbuild_implies_features"], item_prefix = ":")
        features_content = _append_list_line(features_content, "opt_implied_features", group["opt_implies_features"], item_prefix = ":")
        ctx.file("{}/features/features.bzl".format(group_prefix), features_content)
        ctx.file("{}/features/BUILD.bazel".format(group_prefix), """package(default_visibility = ["//visibility:public"])
""")

        ctx.template(
            "{}/args/msvc/BUILD.bazel".format(group_prefix),
            ctx.attr.src_args_msvc,
            substitutions = {
                "{COMPILER_KIND}": "msvc",
                "{features_package}": features_package,
            },
        )
        ctx.template(
            "{}/args/clang/BUILD.bazel".format(group_prefix),
            ctx.attr.src_args_clang,
            substitutions = {
                "{COMPILER_KIND}": "clang",
                "{features_package}": features_package,
            },
        )
        ctx.template(
            "{}/artifacts/BUILD.bazel".format(group_prefix),
            ctx.attr.src_artifacts,
        )

        group_msvc_versions = group["msvc_versions"]
        group_llvm_versions = group["llvm_versions"]
        group_winsdk_versions = group["winsdk_versions"]
        group_targets = group["targets"]
        group_hosts = group["hosts"]
        cl_with_lld_version = group["cl_with_lld_version"]

        for winsdk_version in group_winsdk_versions:
            for msvc_version in group_msvc_versions:
                for host in group_hosts:
                    for target in group_targets:
                        toolchain_name = "{group_name}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}".format(
                            group_name = group_name,
                            msvc_version = msvc_version,
                            winsdk_version = winsdk_version,
                            host = host,
                            target = target,
                        )

                        msvc_repo = "msvc_{}".format(msvc_version)
                        if cl_with_lld_version:
                            lld_link_llvm_repo = "llvm_{}_{}".format(cl_with_lld_version, host)
                            link_cc_tool = """cc_tool(
    name = "link",
    src = "@{llvm_repo}//:lld-link_host{host}_target{target}",
    data = [
        "@{llvm_repo}//:lld_link_exe_only_host{host}_target{target}",
    ],
)""".format(llvm_repo = lld_link_llvm_repo, host = host, target = target)
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

                        ctx.template(
                            "{group_prefix}/toolchain/{toolchain_name}/BUILD.bazel".format(
                                group_prefix = group_prefix,
                                toolchain_name = toolchain_name,
                            ),
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
                                "{artifacts_package}": artifacts_package,
                                "{features_package}": features_package,
                            },
                        )

                        target_arch = convert_msvc_arch_to_bazel_arch(target)
                        host_arch = convert_msvc_arch_to_bazel_arch(host)
                        root_build_file_content += """
toolchain(
    name = "{toolchain_name}",
    exec_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{host_arch}",
    ],
    target_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{target_arch}",
    ],
    target_settings = [
        "//toolchain_set:{group_name}",
        "//winsdk:{winsdk_version}",
        "//msvc:{msvc_version}",
        "//compiler:msvc-cl",
    ],
    toolchain = "//{group_prefix}/toolchain/{toolchain_name}:cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

    """.format(
                            toolchain_name = toolchain_name,
                            group_name = group_name,
                            winsdk_version = winsdk_version,
                            msvc_version = msvc_version,
                            group_prefix = group_prefix,
                            target_arch = target_arch,
                            host_arch = host_arch,
                        )

                        for llvm_version in group_llvm_versions:
                            if host == "x86":
                                continue  # LLVM does not provide x86 Windows binaries
                            clang_target = convert_msvc_arch_to_clang_target(target)
                            compatibility_version = msvc_version_to_cl_internal_version(msvc_version)

                            clang_toolchain_name = "{group_name}_clang{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}".format(
                                group_name = group_name,
                                clang_version = llvm_version,
                                msvc_version = msvc_version,
                                winsdk_version = winsdk_version,
                                host = host,
                                target = target,
                            )
                            ctx.template(
                                "{group_prefix}/toolchain/{toolchain_name}/BUILD.bazel".format(
                                    group_prefix = group_prefix,
                                    toolchain_name = clang_toolchain_name,
                                ),
                                ctx.attr.src_toolchain_clang,
                                substitutions = {
                                    "{toolchain_name}": clang_toolchain_name,
                                    "{compiler}": "clang",
                                    "{llvm_repo}": "llvm_{}_{}".format(llvm_version, host),
                                    "{msvc_repo}": "msvc_{}".format(msvc_version),
                                    "{winsdk_repo}": "winsdk_{}".format(winsdk_version),
                                    "{clang_version}": llvm_version,
                                    "{msvc_version}": msvc_version,
                                    "{winsdk_version}": winsdk_version,
                                    "{clang_target}": clang_target,
                                    "{cl_internal_version}": compatibility_version,
                                    "{target}": target,
                                    "{host}": host,
                                    "{artifacts_package}": artifacts_package,
                                    "{features_package}": features_package,
                                },
                            )

                            root_build_file_content += """
toolchain(
    name = "{toolchain_name}",
    exec_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{host_arch}",
    ],
    target_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{target_arch}",
    ],
    target_settings = [
        "//toolchain_set:{group_name}",
        "//winsdk:{winsdk_version}",
        "//msvc:{msvc_version}",
        "//llvm:{clang_version}",
        "//compiler:clang",
    ],
    toolchain = "//{group_prefix}/toolchain/{toolchain_name}:cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

    """.format(
                                toolchain_name = clang_toolchain_name,
                                group_name = group_name,
                                winsdk_version = winsdk_version,
                                msvc_version = msvc_version,
                                clang_version = llvm_version,
                                group_prefix = group_prefix,
                                target_arch = target_arch,
                                host_arch = host_arch,
                            )

                            clang_cl_toolchain_name = "{group_name}_clang-cl{clang_version}_msvc{msvc_version}_winsdk{winsdk_version}_host{host}_target{target}".format(
                                group_name = group_name,
                                clang_version = llvm_version,
                                msvc_version = msvc_version,
                                winsdk_version = winsdk_version,
                                host = host,
                                target = target,
                            )
                            ctx.template(
                                "{group_prefix}/toolchain/{toolchain_name}/BUILD.bazel".format(
                                    group_prefix = group_prefix,
                                    toolchain_name = clang_cl_toolchain_name,
                                ),
                                ctx.attr.src_toolchain_clang_cl,
                                substitutions = {
                                    "{toolchain_name}": clang_cl_toolchain_name,
                                    "{compiler}": "clang-cl",
                                    "{llvm_repo}": "llvm_{}_{}".format(llvm_version, host),
                                    "{msvc_repo}": "msvc_{}".format(msvc_version),
                                    "{winsdk_repo}": "winsdk_{}".format(winsdk_version),
                                    "{clang_target}": clang_target,
                                    "{cl_internal_version}": compatibility_version,
                                    "{msvc_version}": msvc_version,
                                    "{winsdk_version}": winsdk_version,
                                    "{target}": target,
                                    "{host}": host,
                                    "{artifacts_package}": artifacts_package,
                                    "{features_package}": features_package,
                                },
                            )

                            root_build_file_content += """
toolchain(
    name = "{toolchain_name}",
    exec_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{host_arch}",
    ],
    target_compatible_with = [
        "@platforms//os:windows",
        "@platforms//cpu:{target_arch}",
    ],
    target_settings = [
        "//toolchain_set:{group_name}",
        "//winsdk:{winsdk_version}",
        "//msvc:{msvc_version}",
        "//llvm:{clang_version}",
        "//compiler:clang-cl",
    ],
    toolchain = "//{group_prefix}/toolchain/{toolchain_name}:cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

    """.format(
                                toolchain_name = clang_cl_toolchain_name,
                                group_name = group_name,
                                winsdk_version = winsdk_version,
                                msvc_version = msvc_version,
                                clang_version = llvm_version,
                                group_prefix = group_prefix,
                                target_arch = target_arch,
                                host_arch = host_arch,
                            )

    ctx.file("BUILD.bazel", root_build_file_content)

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

    ctx.file("toolchain_set/BUILD.bazel", """load("//:common.bzl", "string_enum_flag")

package(default_visibility = ["//visibility:public"])

string_enum_flag(
    name = "toolchain_set",
    build_setting_default = "{default_toolchain_set}",
    allowed_values = {allowed_toolchain_sets},
)

{config_settings}
""".format(
        default_toolchain_set = default_toolchain_set_value,
        allowed_toolchain_sets = ctx.attr.toolchain_sets,
        config_settings = "\n".join([
            """config_setting(
    name = "{v}",
    flag_values = {{"//toolchain_set": "{v}"}},
)""".format(v = v)
            for v in ctx.attr.toolchain_sets
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
        allowed_llvm = llvm_versions,
        config_settings = "\n".join([
            """config_setting(
    name = "{v}",
    flag_values = {{":llvm": "{v}"}},
)""".format(v = v)
            for v in llvm_versions
        ]),
    ))

    compiler_build_file = """load("//:common.bzl", "string_enum_flag")

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
    )
    ctx.file("compiler/BUILD.bazel", compiler_build_file)

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
        "group_configs": attr.string(mandatory = True),
        "toolchain_sets": attr.string_list(mandatory = True),
        "default_toolchain_set": attr.string(mandatory = True),
        "msvc_versions": attr.string_list(mandatory = True),
        "llvm_versions": attr.string_list(mandatory = True),
        "winsdk_versions": attr.string_list(mandatory = True),
        "targets": attr.string_list(mandatory = True),
        "hosts": attr.string_list(mandatory = True),
        "default_msvc_version": attr.string(mandatory = True),
        "default_clang_version": attr.string(mandatory = False),
        "default_windows_sdk_version": attr.string(mandatory = True),
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
