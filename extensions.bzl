"""Toolchains extension for toolchains_msvc."""

load("//private:flags.bzl", "merge_flags",
    "CL_C_COMPILE_FLAGS_DEFAULT", "CL_CXX_COMPILE_FLAGS_DEFAULT", "CL_LINK_FLAGS_DEFAULT",
    "CL_DBG_C_COMPILE_FLAGS_DEFAULT", "CL_DBG_CXX_COMPILE_FLAGS_DEFAULT", "CL_DBG_LINK_FLAGS_DEFAULT",
    "CL_FASTBUILD_C_COMPILE_FLAGS_DEFAULT", "CL_FASTBUILD_CXX_COMPILE_FLAGS_DEFAULT", "CL_FASTBUILD_LINK_FLAGS_DEFAULT",
    "CL_OPT_C_COMPILE_FLAGS_DEFAULT", "CL_OPT_CXX_COMPILE_FLAGS_DEFAULT", "CL_OPT_LINK_FLAGS_DEFAULT",
    "CLANG_C_COMPILE_FLAGS_DEFAULT", "CLANG_CXX_COMPILE_FLAGS_DEFAULT", "CLANG_LINK_FLAGS_DEFAULT",
    "CLANG_DBG_C_COMPILE_FLAGS_DEFAULT", "CLANG_DBG_CXX_COMPILE_FLAGS_DEFAULT", "CLANG_DBG_LINK_FLAGS_DEFAULT",
    "CLANG_FASTBUILD_C_COMPILE_FLAGS_DEFAULT", "CLANG_FASTBUILD_CXX_COMPILE_FLAGS_DEFAULT", "CLANG_FASTBUILD_LINK_FLAGS_DEFAULT",
    "CLANG_OPT_C_COMPILE_FLAGS_DEFAULT", "CLANG_OPT_CXX_COMPILE_FLAGS_DEFAULT", "CLANG_OPT_LINK_FLAGS_DEFAULT",
)
load("//private:llvm_repo.bzl", "llvm_repo")
load("//private:msvc_repo.bzl", "msvc_repo")
load("//private:msvc_toolchains_repo.bzl", "msvc_toolchains_repo")
load(
    "//private:vs_channel_manifest.bzl",
    "VALID_MSVC_HOSTS",
    "VALID_MSVC_TARGETS",
    "download_and_map",
    "get_msvc_package_ids",
    "get_msvc_redist_package_ids",
    "get_winsdk_msi_list",
    "get_winsdk_package_id",
    "list_clang_version",
    "list_msvc_redist_version",
    "list_msvc_version",
    "list_winsdk_version",
)
load("//private:winsdk_repo.bzl", "winsdk_repo")

CHANNEL_URL = {
    "18": "https://aka.ms/vs/stable/channel",
    "17": "https://aka.ms/vs/17/release/channel",
}

def _find_closest_redist_version(msvc_version, redist_versions_dict):
    """Returns (closest_redist_version, package_map_key)."""
    redist_versions = redist_versions_dict.keys()
    target_v_parts = msvc_version.split(".")[:2]
    target_v = (int(target_v_parts[0]), int(target_v_parts[1]))

    closest_redist = None
    closest_diff = None
    for rv in redist_versions:
        rv_parts = rv.split(".")
        v = (int(rv_parts[0]), int(rv_parts[1]))

        # Starlark doesn't support >= for tuples, check elements manually
        is_greater_or_equal = v[0] > target_v[0] or (v[0] == target_v[0] and v[1] >= target_v[1])
        if is_greater_or_equal:
            diff_0 = v[0] - target_v[0]
            diff_1 = v[1] - target_v[1]
            if closest_diff == None or diff_0 < closest_diff[0] or (diff_0 == closest_diff[0] and diff_1 < closest_diff[1]):
                closest_diff = (diff_0, diff_1)
                closest_redist = rv

    if not closest_redist and redist_versions:
        # Fallback to the latest available redist version if no upper is found
        closest_redist = sorted(redist_versions)[-1]

    if not closest_redist:
        fail("No MSVC redist version could be determined for MSVC version {}".format(msvc_version))

    return (closest_redist, redist_versions_dict[closest_redist])

def _extension_impl(module_ctx):
    # 1. Download manifest and map for each channel
    packages_maps = {}
    for package_map_key, channel_url in CHANNEL_URL.items():
        packages_maps[package_map_key] = download_and_map(module_ctx, channel_url)

    repo_name_value = "msvc_toolchains"
    group = None  # last add_group

    for mod in module_ctx.modules:
        for tag in mod.tags.repo_name:
            repo_name_value = tag.name
        for tag in mod.tags.add_group:
            group = tag

    if group == None:
        fail("At least one toolchain.add_group(...) is required.")

    targets_set = {a: True for a in group.targets} if group.targets else {}
    hosts_set = {a: True for a in group.hosts} if group.hosts else {}
    msvc_versions_set = {v: True for v in group.msvc_version} if group.msvc_version else {}
    llvm_versions_set = {v: True for v in group.llvm_version} if group.llvm_version else {}
    winsdk_versions_set = {v: True for v in group.winsdk_version} if group.winsdk_version else {}

    # Default targets from env or single x64 when not specified in add_group
    if not targets_set:
        env_targets = module_ctx.os.environ.get("BAZEL_TOOLCHAINS_MSVC_TARGETS", "").strip()
        if env_targets:
            targets_set = {a: True for a in [x.strip() for x in env_targets.split(",") if x.strip()]}
        else:
            targets_set = {"x64": True}
    # Default hosts from env or single x64 when not specified in add_group
    if not hosts_set:
        env_hosts = module_ctx.os.environ.get("BAZEL_TOOLCHAINS_MSVC_HOSTS", "").strip()
        if env_hosts:
            hosts_set = {a: True for a in [x.strip() for x in env_hosts.split(",") if x.strip()]}
        else:
            hosts_set = {"x64": True}

    if not msvc_versions_set or not winsdk_versions_set:
        fail("add_group must specify msvc_version and winsdk_version.")

    default_msvc_version = group.default_msvc_version if group.default_msvc_version else None
    default_clang_version = group.default_llvm_version if group.default_llvm_version else None
    default_windows_sdk_version = group.default_winsdk_version if group.default_winsdk_version else None
    cl_with_lld_version = group.cl_with_lld_version if group.cl_with_lld_version else None
    default_compiler = "msvc-cl"

    llvm_versions = llvm_versions_set.keys()
    msvc_versions = msvc_versions_set.keys()
    winsdk_versions = winsdk_versions_set.keys()
    targets = targets_set.keys()
    hosts = hosts_set.keys()

    msvc_versions_dict = list_msvc_version(packages_maps)
    for msvc_version in msvc_versions:
        if msvc_version not in msvc_versions_dict:
            fail("Invalid MSVC version '{}'. Valid versions are: {}".format(msvc_version, msvc_versions_dict.keys()))

    winsdk_versions_dict = list_winsdk_version(packages_maps)
    for winsdk_version in winsdk_versions:
        if winsdk_version not in winsdk_versions_dict:
            fail("Invalid Windows SDK version '{}'. Valid versions are: {}".format(winsdk_version, winsdk_versions_dict.keys()))

    if default_msvc_version == None:
        default_msvc_version = msvc_versions[0] if msvc_versions else "unknown"
    if default_windows_sdk_version == None:
        default_windows_sdk_version = winsdk_versions[0] if winsdk_versions else "unknown"
    if default_compiler == None:
        default_compiler = "msvc-cl"
    if default_clang_version == None and llvm_versions:
        default_clang_version = llvm_versions[0]

    # Validate that default versions are in the declared version lists
    if msvc_versions and default_msvc_version not in msvc_versions:
        fail("default_msvc_version '{}' is not in msvc_version list: {}".format(default_msvc_version, msvc_versions))
    if winsdk_versions and default_windows_sdk_version not in winsdk_versions:
        fail("default_winsdk_version '{}' is not in winsdk_version list: {}".format(default_windows_sdk_version, winsdk_versions))
    if llvm_versions and default_clang_version != None and default_clang_version not in llvm_versions:
        fail("default_llvm_version '{}' is not in llvm_version list: {}".format(default_clang_version, llvm_versions))

    for h in hosts:
        if h not in VALID_MSVC_HOSTS:
            fail("Invalid host '{}', must be one of: {}".format(h, VALID_MSVC_HOSTS))
    for t in targets:
        if t not in VALID_MSVC_TARGETS:
            fail("Invalid target '{}', must be one of: {}".format(t, VALID_MSVC_TARGETS))

    redist_versions_dict = list_msvc_redist_version(packages_maps)

    # 2. Construct all clang repos (only if clang versions are defined)
    if llvm_versions:
        clang_versions_dict = list_clang_version(module_ctx)
        for llvm_version in llvm_versions:
            if llvm_version not in clang_versions_dict:
                fail("Invalid Clang/LLVM version '{}'. Valid versions are: {}".format(llvm_version, clang_versions_dict.keys()))
        for llvm_version in llvm_versions:
            entry = clang_versions_dict[llvm_version]
            for host in hosts:
                if host == "x86":
                    continue  # LLVM does not provide x86 Windows binaries
                url = entry["x64"] if host == "x64" else entry["arm64"]
                digest = entry["x64_digest"] if host == "x64" else entry["arm64_digest"]
                llvm_repo(
                    name = "llvm_{}_{}".format(llvm_version, host),
                    version = llvm_version,
                    host = host,
                    url = url,
                    digest = digest,
                    src_build = Label("//overlays/llvm:BUILD.root.tpl"),
                )

    # 3. Construct all msvc repos
    for msvc_version in msvc_versions:
        msvc_package_map_key = msvc_versions_dict[msvc_version]
        msvc_packages_map = packages_maps[msvc_package_map_key]
        deps = get_msvc_package_ids(msvc_packages_map, msvc_version, hosts = hosts, targets = targets)

        closest_redist, redist_package_map_key = _find_closest_redist_version(msvc_version, redist_versions_dict)
        redist_packages_map = packages_maps[redist_package_map_key]
        redist_deps = get_msvc_redist_package_ids(redist_packages_map, closest_redist, targets = targets)
        deps.extend(redist_deps)

        deps = sorted(deps)

        packages_list = []
        for dep_id in deps:
            pkg = msvc_packages_map.get(dep_id)
            if not pkg:
                pkg = redist_packages_map.get(dep_id)
            if pkg:
                payloads = pkg.get("payloads", [])
                for payload in payloads:
                    if "url" in payload:
                        packages_list.append({
                            "url": payload["url"],
                            "sha256": payload.get("sha256"),
                            "filename": payload.get("fileName"),
                        })

        msvc_repo(
            name = "msvc_{}".format(msvc_version),
            hosts = hosts,
            targets = targets,
            packages = json.encode(packages_list),
            src_build = Label("//overlays/msvc:BUILD.root.tpl"),
        )

    # 4. Construct all winsdk repos
    for winsdk_version in winsdk_versions:
        winsdk_package_map_key = winsdk_versions_dict[winsdk_version]
        winsdk_packages_map = packages_maps[winsdk_package_map_key]
        id = get_winsdk_package_id(winsdk_version)
        required_msi_files = get_winsdk_msi_list(targets)

        cab_list = {}
        msi_list = []
        pkg = winsdk_packages_map.get(id)
        payloads = pkg.get("payloads", [])
        for payload in payloads:
            if "url" in payload and "fileName" in payload:
                raw_filename = payload["fileName"]
                filename = raw_filename
                if raw_filename.startswith("Installers\\"):
                    filename = raw_filename[len("Installers\\"):]
                if filename.endswith(".msi"):
                    for required_msi_file in required_msi_files:
                        if filename.endswith(required_msi_file):
                            msi_list.append({
                                "url": payload["url"],
                                "sha256": payload.get("sha256"),
                                "filename": filename,
                            })
                elif filename.endswith(".cab"):
                    cab_list[filename] = {
                        "url": payload["url"],
                        "sha256": payload.get("sha256"),
                        "filename": filename,
                    }

        packages_list = {
            "cab": cab_list,
            "msi": msi_list,
        }

        winsdk_repo(
            name = "winsdk_{}".format(winsdk_version),
            targets = targets,
            packages = json.encode(packages_list),
            winsdk_version = winsdk_version,
        )

    # 5. Resolve flags (merge defaults with replace/add from group) in the extension
    _g = group
    msvc_default_c_compile_flags = merge_flags(CL_C_COMPILE_FLAGS_DEFAULT, _g.cl_copt, _g.add_cl_copt)
    msvc_default_cxx_compile_flags = merge_flags(CL_CXX_COMPILE_FLAGS_DEFAULT, _g.cl_cxxopt, _g.add_cl_cxxopt)
    msvc_default_link_flags = merge_flags(CL_LINK_FLAGS_DEFAULT, _g.cl_linkopt, _g.add_cl_linkopt)
    msvc_dbg_c_compile_flags = merge_flags(CL_DBG_C_COMPILE_FLAGS_DEFAULT, _g.cl_dbg_copt, _g.add_cl_dbg_copt)
    msvc_dbg_cxx_compile_flags = merge_flags(CL_DBG_CXX_COMPILE_FLAGS_DEFAULT, _g.cl_dbg_cxxopt, _g.add_cl_dbg_cxxopt)
    msvc_dbg_link_flags = merge_flags(CL_DBG_LINK_FLAGS_DEFAULT, _g.cl_dbg_linkopt, _g.add_cl_dbg_linkopt)
    msvc_fastbuild_c_compile_flags = merge_flags(CL_FASTBUILD_C_COMPILE_FLAGS_DEFAULT, _g.cl_fastbuild_copt, _g.add_cl_fastbuild_copt)
    msvc_fastbuild_cxx_compile_flags = merge_flags(CL_FASTBUILD_CXX_COMPILE_FLAGS_DEFAULT, _g.cl_fastbuild_cxxopt, _g.add_cl_fastbuild_cxxopt)
    msvc_fastbuild_link_flags = merge_flags(CL_FASTBUILD_LINK_FLAGS_DEFAULT, _g.cl_fastbuild_linkopt, _g.add_cl_fastbuild_linkopt)
    msvc_opt_c_compile_flags = merge_flags(CL_OPT_C_COMPILE_FLAGS_DEFAULT, _g.cl_opt_copt, _g.add_cl_opt_copt)
    msvc_opt_cxx_compile_flags = merge_flags(CL_OPT_CXX_COMPILE_FLAGS_DEFAULT, _g.cl_opt_cxxopt, _g.add_cl_opt_cxxopt)
    msvc_opt_link_flags = merge_flags(CL_OPT_LINK_FLAGS_DEFAULT, _g.cl_opt_linkopt, _g.add_cl_opt_linkopt)

    clang_default_c_compile_flags = merge_flags(CLANG_C_COMPILE_FLAGS_DEFAULT, _g.clang_copt, _g.add_clang_copt)
    clang_default_cxx_compile_flags = merge_flags(CLANG_CXX_COMPILE_FLAGS_DEFAULT, _g.clang_cxxopt, _g.add_clang_cxxopt)
    clang_default_link_flags = merge_flags(CLANG_LINK_FLAGS_DEFAULT, _g.clang_linkopt, _g.add_clang_linkopt)
    clang_dbg_c_compile_flags = merge_flags(CLANG_DBG_C_COMPILE_FLAGS_DEFAULT, _g.clang_dbg_copt, _g.add_clang_dbg_copt)
    clang_dbg_cxx_compile_flags = merge_flags(CLANG_DBG_CXX_COMPILE_FLAGS_DEFAULT, _g.clang_dbg_cxxopt, _g.add_clang_dbg_cxxopt)
    clang_dbg_link_flags = merge_flags(CLANG_DBG_LINK_FLAGS_DEFAULT, _g.clang_dbg_linkopt, _g.add_clang_dbg_linkopt)
    clang_fastbuild_c_compile_flags = merge_flags(CLANG_FASTBUILD_C_COMPILE_FLAGS_DEFAULT, _g.clang_fastbuild_copt, _g.add_clang_fastbuild_copt)
    clang_fastbuild_cxx_compile_flags = merge_flags(CLANG_FASTBUILD_CXX_COMPILE_FLAGS_DEFAULT, _g.clang_fastbuild_cxxopt, _g.add_clang_fastbuild_cxxopt)
    clang_fastbuild_link_flags = merge_flags(CLANG_FASTBUILD_LINK_FLAGS_DEFAULT, _g.clang_fastbuild_linkopt, _g.add_clang_fastbuild_linkopt)
    clang_opt_c_compile_flags = merge_flags(CLANG_OPT_C_COMPILE_FLAGS_DEFAULT, _g.clang_opt_copt, _g.add_clang_opt_copt)
    clang_opt_cxx_compile_flags = merge_flags(CLANG_OPT_CXX_COMPILE_FLAGS_DEFAULT, _g.clang_opt_cxxopt, _g.add_clang_opt_cxxopt)
    clang_opt_link_flags = merge_flags(CLANG_OPT_LINK_FLAGS_DEFAULT, _g.clang_opt_linkopt, _g.add_clang_opt_linkopt)

    # 6. Instantiate toolchains repo with resolved flags
    msvc_toolchains_repo(
        name = repo_name_value,
        llvm_versions = llvm_versions,
        msvc_versions = msvc_versions,
        cl_with_lld_version = cl_with_lld_version,
        winsdk_versions = winsdk_versions,
        targets = targets,
        hosts = hosts,
        default_msvc_version = default_msvc_version,
        default_clang_version = default_clang_version,
        default_windows_sdk_version = default_windows_sdk_version,
        default_compiler = default_compiler,
        msvc_default_c_compile_flags = msvc_default_c_compile_flags,
        msvc_default_cxx_compile_flags = msvc_default_cxx_compile_flags,
        msvc_default_link_flags = msvc_default_link_flags,
        msvc_dbg_c_compile_flags = msvc_dbg_c_compile_flags,
        msvc_dbg_cxx_compile_flags = msvc_dbg_cxx_compile_flags,
        msvc_dbg_link_flags = msvc_dbg_link_flags,
        msvc_fastbuild_c_compile_flags = msvc_fastbuild_c_compile_flags,
        msvc_fastbuild_cxx_compile_flags = msvc_fastbuild_cxx_compile_flags,
        msvc_fastbuild_link_flags = msvc_fastbuild_link_flags,
        msvc_opt_c_compile_flags = msvc_opt_c_compile_flags,
        msvc_opt_cxx_compile_flags = msvc_opt_cxx_compile_flags,
        msvc_opt_link_flags = msvc_opt_link_flags,
        clang_default_c_compile_flags = clang_default_c_compile_flags,
        clang_default_cxx_compile_flags = clang_default_cxx_compile_flags,
        clang_default_link_flags = clang_default_link_flags,
        clang_dbg_c_compile_flags = clang_dbg_c_compile_flags,
        clang_dbg_cxx_compile_flags = clang_dbg_cxx_compile_flags,
        clang_dbg_link_flags = clang_dbg_link_flags,
        clang_fastbuild_c_compile_flags = clang_fastbuild_c_compile_flags,
        clang_fastbuild_cxx_compile_flags = clang_fastbuild_cxx_compile_flags,
        clang_fastbuild_link_flags = clang_fastbuild_link_flags,
        clang_opt_c_compile_flags = clang_opt_c_compile_flags,
        clang_opt_cxx_compile_flags = clang_opt_cxx_compile_flags,
        clang_opt_link_flags = clang_opt_link_flags,
        default_features = group.features,
        dbg_implies_features = group.dbg_features,
        fastbuild_implies_features = group.fastbuild_features,
        opt_implies_features = group.opt_features,
    )

    return module_ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = [repo_name_value],
        root_module_direct_dev_deps = [],
    )

repo_name_tag = tag_class(attrs = {"name": attr.string(mandatory = True)})

add_group_tag = tag_class(
    attrs = {
        "name": attr.string(default = "default"),  # ignored for now
        "targets": attr.string_list(default = []),
        "hosts": attr.string_list(default = []),
        "msvc_version": attr.string_list(default = []),
        "default_msvc_version": attr.string(default = ""),
        "cl_with_lld_version": attr.string(default = ""),
        "llvm_version": attr.string_list(default = []),
        "default_llvm_version": attr.string(default = ""),
        "winsdk_version": attr.string_list(default = []),
        "default_winsdk_version": attr.string(default = ""),
        "features": attr.string_list(default = []),
        "dbg_features": attr.string_list(default = []),
        "fastbuild_features": attr.string_list(default = []),
        "opt_features": attr.string_list(default = []),
        "cl_copt": attr.string_list(default = []),
        "cl_cxxopt": attr.string_list(default = []),
        "cl_linkopt": attr.string_list(default = []),
        "cl_dbg_copt": attr.string_list(default = []),
        "cl_dbg_cxxopt": attr.string_list(default = []),
        "cl_dbg_linkopt": attr.string_list(default = []),
        "cl_fastbuild_copt": attr.string_list(default = []),
        "cl_fastbuild_cxxopt": attr.string_list(default = []),
        "cl_fastbuild_linkopt": attr.string_list(default = []),
        "cl_opt_copt": attr.string_list(default = []),
        "cl_opt_cxxopt": attr.string_list(default = []),
        "cl_opt_linkopt": attr.string_list(default = []),
        "add_cl_copt": attr.string_list(default = []),
        "add_cl_cxxopt": attr.string_list(default = []),
        "add_cl_linkopt": attr.string_list(default = []),
        "add_cl_dbg_copt": attr.string_list(default = []),
        "add_cl_dbg_cxxopt": attr.string_list(default = []),
        "add_cl_dbg_linkopt": attr.string_list(default = []),
        "add_cl_fastbuild_copt": attr.string_list(default = []),
        "add_cl_fastbuild_cxxopt": attr.string_list(default = []),
        "add_cl_fastbuild_linkopt": attr.string_list(default = []),
        "add_cl_opt_copt": attr.string_list(default = []),
        "add_cl_opt_cxxopt": attr.string_list(default = []),
        "add_cl_opt_linkopt": attr.string_list(default = []),
        "clang_copt": attr.string_list(default = []),
        "clang_cxxopt": attr.string_list(default = []),
        "clang_linkopt": attr.string_list(default = []),
        "clang_dbg_copt": attr.string_list(default = []),
        "clang_dbg_cxxopt": attr.string_list(default = []),
        "clang_dbg_linkopt": attr.string_list(default = []),
        "clang_fastbuild_copt": attr.string_list(default = []),
        "clang_fastbuild_cxxopt": attr.string_list(default = []),
        "clang_fastbuild_linkopt": attr.string_list(default = []),
        "clang_opt_copt": attr.string_list(default = []),
        "clang_opt_cxxopt": attr.string_list(default = []),
        "clang_opt_linkopt": attr.string_list(default = []),
        "add_clang_copt": attr.string_list(default = []),
        "add_clang_cxxopt": attr.string_list(default = []),
        "add_clang_linkopt": attr.string_list(default = []),
        "add_clang_dbg_copt": attr.string_list(default = []),
        "add_clang_dbg_cxxopt": attr.string_list(default = []),
        "add_clang_dbg_linkopt": attr.string_list(default = []),
        "add_clang_fastbuild_copt": attr.string_list(default = []),
        "add_clang_fastbuild_cxxopt": attr.string_list(default = []),
        "add_clang_fastbuild_linkopt": attr.string_list(default = []),
        "add_clang_opt_copt": attr.string_list(default = []),
        "add_clang_opt_cxxopt": attr.string_list(default = []),
        "add_clang_opt_linkopt": attr.string_list(default = []),
    },
)

toolchain = module_extension(
    implementation = _extension_impl,
    tag_classes = {
        "repo_name": repo_name_tag,
        "add_group": add_group_tag,
    },
    environ = [
        "BAZEL_TOOLCHAINS_MSVC_HOSTS",
        "BAZEL_TOOLCHAINS_MSVC_TARGETS",
    ],
)
