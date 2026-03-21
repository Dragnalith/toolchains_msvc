"""Toolchains extension for toolchains_msvc."""

load(
    "//private:flags.bzl",
    "CLANG_CXX_COMPILE_FLAGS_DEFAULT",
    "CLANG_C_COMPILE_FLAGS_DEFAULT",
    "CLANG_DBG_CXX_COMPILE_FLAGS_DEFAULT",
    "CLANG_DBG_C_COMPILE_FLAGS_DEFAULT",
    "CLANG_DBG_LINK_FLAGS_DEFAULT",
    "CLANG_FASTBUILD_CXX_COMPILE_FLAGS_DEFAULT",
    "CLANG_FASTBUILD_C_COMPILE_FLAGS_DEFAULT",
    "CLANG_FASTBUILD_LINK_FLAGS_DEFAULT",
    "CLANG_LINK_FLAGS_DEFAULT",
    "CLANG_OPT_CXX_COMPILE_FLAGS_DEFAULT",
    "CLANG_OPT_C_COMPILE_FLAGS_DEFAULT",
    "CLANG_OPT_LINK_FLAGS_DEFAULT",
    "CL_CXX_COMPILE_FLAGS_DEFAULT",
    "CL_C_COMPILE_FLAGS_DEFAULT",
    "CL_DBG_CXX_COMPILE_FLAGS_DEFAULT",
    "CL_DBG_C_COMPILE_FLAGS_DEFAULT",
    "CL_DBG_LINK_FLAGS_DEFAULT",
    "CL_FASTBUILD_CXX_COMPILE_FLAGS_DEFAULT",
    "CL_FASTBUILD_C_COMPILE_FLAGS_DEFAULT",
    "CL_FASTBUILD_LINK_FLAGS_DEFAULT",
    "CL_LINK_FLAGS_DEFAULT",
    "CL_OPT_CXX_COMPILE_FLAGS_DEFAULT",
    "CL_OPT_C_COMPILE_FLAGS_DEFAULT",
    "CL_OPT_LINK_FLAGS_DEFAULT",
    "merge_flags",
)
load("//private:llvm_repo.bzl", "llvm_repo")
load("//private:lock_file_repo.bzl", "lock_file_repo")
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
            if closest_diff == None:
                closest_diff = (diff_0, diff_1)
                closest_redist = rv
            elif diff_0 < closest_diff[0] or (diff_0 == closest_diff[0] and diff_1 < closest_diff[1]):
                closest_redist = rv

    if not closest_redist and redist_versions:
        # Fallback to the latest available redist version if no upper is found
        closest_redist = sorted(redist_versions)[-1]

    if not closest_redist:
        fail("No MSVC redist version could be determined for MSVC version {}".format(msvc_version))

    return (closest_redist, redist_versions_dict[closest_redist])

def _unique_values(values):
    """Returns values without duplicates while preserving order."""
    seen = {}
    result = []
    for value in values:
        if value not in seen:
            seen[value] = True
            result.append(value)
    return result

def _env_list(module_ctx, env_var):
    value = module_ctx.os.environ.get(env_var, "").strip()
    if not value:
        return []
    return _unique_values([item.strip() for item in value.split(",") if item.strip()])

def _resolve_group_axis(module_ctx, explicit_values, env_var, fallback):
    """Returns explicit values, env override values, or fallback values."""
    if explicit_values:
        return _unique_values(explicit_values)
    env_values = _env_list(module_ctx, env_var)
    if env_values:
        return env_values
    return fallback

def _validate_toolchain_set_name(name):
    """Ensures toolchain_set names can be used as labels and folder names."""
    if not name:
        fail("toolchain_set name must not be empty.")
    for invalid_char in ["/", "\\", ":", "@", " "]:
        if invalid_char in name:
            fail("Invalid toolchain_set name '{}': must not contain '{}'.".format(name, invalid_char))

def _sort_packages(packages):
    return sorted(packages, key = lambda pkg: "{}\n{}".format(pkg["filename"], pkg["sha256"]))

def _register_package_url(all_packages_url, sha256, url):
    existing = all_packages_url.get(sha256)
    if existing == None:
        all_packages_url[sha256] = url
        return

def _package_urls_for_repo(all_packages_url, packages):
    package_urls = {}
    for pkg in packages:
        sha256 = pkg["sha256"]
        url = all_packages_url.get(sha256)
        if url == None:
            fail("Missing URL for package digest '{}' (file '{}')".format(sha256, pkg["filename"]))
        package_urls[sha256] = url
    return package_urls

def _sorted_union_keys(left, right):
    keys = {}
    for key in left:
        keys[key] = True
    for key in right:
        keys[key] = True
    return sorted(keys.keys())

def _packages_by_filename(packages):
    packages_by_filename = {}
    for package in packages:
        if type(package) == "dict" and package.get("filename") != None:
            packages_by_filename[package["filename"]] = package
    return packages_by_filename

def _diff_repo_packages(repo_name, repo_packages, user_repo_packages):
    if type(repo_packages) != "list" or type(user_repo_packages) != "list":
        return "packages: type mismatch (MODULE: {}, lock: {}).\n".format(
            type(repo_packages),
            type(user_repo_packages),
        )

    diff_text = ""
    if len(repo_packages) != len(user_repo_packages):
        diff_text += "packages: MODULE has {} entries, lock file has {} entries (repository '{}').\n".format(
            len(repo_packages),
            len(user_repo_packages),
            repo_name,
        )

    repo_by_fn = _packages_by_filename(repo_packages)
    user_repo_by_fn = _packages_by_filename(user_repo_packages)
    for fn in _sorted_union_keys(repo_by_fn, user_repo_by_fn):
        repo_pkg = repo_by_fn.get(fn)
        user_repo_pkg = user_repo_by_fn.get(fn)
        if repo_pkg == None:
            diff_text += "packages: filename {} only in lock file.\n".format(repr(fn))
        elif user_repo_pkg == None:
            diff_text += "packages: filename {} only in MODULE resolution.\n".format(repr(fn))
        else:
            if repo_pkg.get("filename") != user_repo_pkg.get("filename"):
                diff_text += "packages: filename field differs for {}: MODULE {} vs lock {}.\n".format(
                    repr(fn),
                    repr(repo_pkg.get("filename")),
                    repr(user_repo_pkg.get("filename")),
                )
            if repo_pkg.get("sha256") != user_repo_pkg.get("sha256"):
                diff_text += "packages: sha256 differs for filename {}: MODULE {} vs lock {}.\n".format(
                    repr(fn),
                    repr(repo_pkg.get("sha256")),
                    repr(user_repo_pkg.get("sha256")),
                )
    return diff_text

def _diff_repo_definition(repo_name, repo, user_repo):
    diff_text = ""
    for key in _sorted_union_keys(repo, user_repo):
        in_mod = key in repo
        in_lock = key in user_repo
        if not in_mod:
            diff_text += "Key '{}' only in lock file (repository '{}').\n".format(key, repo_name)
        elif not in_lock:
            diff_text += "Key '{}' only in MODULE resolution (repository '{}').\n".format(key, repo_name)
        elif repo[key] != user_repo[key]:
            if key == "packages":
                diff_text += _diff_repo_packages(repo_name, repo["packages"], user_repo["packages"])
            else:
                diff_text += "Key '{}' differs in repository '{}': MODULE {} vs lock {}.\n".format(
                    key,
                    repo_name,
                    repr(repo[key]),
                    repr(user_repo[key]),
                )
    return diff_text

def _lock_error_for_repo(relative_lock_file_path, repo_name, repo, user_lock_repos):
    if user_lock_repos == None:
        return "The lock file '{}' does not exist or is invalid for repository '{}'. You must run `bazel run @toolchains_msvc//:pin` to create it.".format(
            relative_lock_file_path,
            repo_name,
        )

    user_repo = user_lock_repos.get(repo_name)
    if user_repo == None:
        return "The lock file '{}' does not contain the definition for repository '{}'. Run `bazel run @toolchains_msvc//:pin` to update the lock file.".format(
            relative_lock_file_path,
            repo_name,
        )

    if user_repo == repo:
        return ""

    diff_text = _diff_repo_definition(repo_name, repo, user_repo)
    return "The lock file '{}' does not match the toolchain definition for repository '{}'. Differences:\n{}\nRun `bazel run @toolchains_msvc//:pin` to update the lock file.".format(
        relative_lock_file_path,
        repo_name,
        diff_text,
    )

def _llvm_package_filename(version, host):
    if host == "x64":
        llvm_arch = "x86_64"
    elif host == "arm64":
        llvm_arch = "aarch64"
    else:
        fail("Unsupported LLVM host architecture for package filename: {}".format(host))
    return "clang+llvm-{}-{}-pc-windows-msvc.tar.xz".format(version, llvm_arch)

def _register_repo_definition(repos, repo):
    name = repo["name"]
    existing = repos.get(name)
    if existing == None:
        repos[name] = repo
        return
    if existing != repo:
        fail("Conflicting definitions for repo '{}': {} != {}".format(name, existing, repo))

def _extension_impl(module_ctx):
    # 1. Download manifest and map for each channel
    packages_maps = {}
    for package_map_key, channel_url in CHANNEL_URL.items():
        package_map, license_url = download_and_map(module_ctx, channel_url)
        packages_maps[package_map_key] = package_map

        accept_eula = module_ctx.os.environ.get("BAZEL_TOOLCHAINS_MSVC_ACCEPT_MICROSOFT_VISUAL_STUDIO_BUILDTOOLS_EULA", "").lower()
        if accept_eula not in ["1", "true"]:
            fail("\n\n" +
                 "You must accept the Microsoft Visual Studio Build Tools License to use this toolchain.\n" +
                 "License URL: {}\n\n".format(license_url) +
                 "To accept the license, set the environment variable BAZEL_TOOLCHAINS_MSVC_ACCEPT_MICROSOFT_VISUAL_STUDIO_BUILDTOOLS_EULA=1\n")

    repo_name_value = "msvc_toolchains"
    toolchain_sets = []
    default_toolchain_set_name = None
    lock_file_label = None
    is_locked = False

    for mod in module_ctx.modules:
        for tag in mod.tags.repo_name:
            repo_name_value = tag.name
        for tag in mod.tags.toolchain_set:
            toolchain_sets.append(tag)
        for tag in mod.tags.default_toolchain_set:
            default_toolchain_set_name = tag.name
        for tag in mod.tags.lock:
            if lock_file_label != None:
                fail("lock tag must be declared at most once.")
            if not tag.file:
                fail("lock file label must not be empty.")
            lock_file_label = tag.file
            is_locked = True

    if not toolchain_sets:
        fail("At least one toolchain.toolchain_set(...) is required.")

    msvc_versions_dict = list_msvc_version(packages_maps)
    winsdk_versions_dict = list_winsdk_version(packages_maps)
    redist_versions_dict = list_msvc_redist_version(packages_maps)
    clang_versions_dict = None

    group_configs = []
    group_names = []
    group_names_set = {}
    all_targets = []
    all_hosts = []
    all_msvc_versions = []
    all_llvm_versions = []
    all_winsdk_versions = []

    for group in toolchain_sets:
        group_name = group.name
        _validate_toolchain_set_name(group_name)
        if group_name in group_names_set:
            fail("Duplicate toolchain_set name '{}'.".format(group_name))
        group_names_set[group_name] = True
        group_names.append(group_name)

        targets = _resolve_group_axis(module_ctx, group.targets, "BAZEL_TOOLCHAINS_MSVC_TARGETS", ["x64"])
        hosts = _resolve_group_axis(module_ctx, group.hosts, "BAZEL_TOOLCHAINS_MSVC_HOSTS", ["x64"])
        msvc_versions = _unique_values(group.msvc_versions)
        llvm_versions = _unique_values(group.llvm_versions)
        cl_with_lld_version = group.cl_with_lld_version if group.cl_with_lld_version else ""
        winsdk_versions = _unique_values(group.winsdk_versions)
        llvm_repo_versions = _unique_values(llvm_versions + ([cl_with_lld_version] if cl_with_lld_version else []))

        if not msvc_versions or not winsdk_versions:
            fail("toolchain_set '{}' must specify msvc_versions and winsdk_versions.".format(group_name))

        default_msvc_version = group.default_msvc_version if group.default_msvc_version else msvc_versions[0]
        default_clang_version = group.default_llvm_version if group.default_llvm_version else (llvm_versions[0] if llvm_versions else "")
        default_windows_sdk_version = group.default_winsdk_version if group.default_winsdk_version else winsdk_versions[0]
        default_compiler = "msvc-cl"

        for msvc_version in msvc_versions:
            if msvc_version not in msvc_versions_dict:
                fail("Invalid MSVC version '{}' in toolchain_set '{}'. Valid versions are: {}".format(msvc_version, group_name, msvc_versions_dict.keys()))
        for winsdk_version in winsdk_versions:
            if winsdk_version not in winsdk_versions_dict:
                fail("Invalid Windows SDK version '{}' in toolchain_set '{}'. Valid versions are: {}".format(winsdk_version, group_name, winsdk_versions_dict.keys()))

        if default_msvc_version not in msvc_versions:
            fail("toolchain_set '{}': default_msvc_version '{}' is not in msvc_versions list: {}".format(group_name, default_msvc_version, msvc_versions))
        if default_windows_sdk_version not in winsdk_versions:
            fail("toolchain_set '{}': default_winsdk_version '{}' is not in winsdk_versions list: {}".format(group_name, default_windows_sdk_version, winsdk_versions))

        if llvm_repo_versions:
            if clang_versions_dict == None:
                clang_versions_dict = list_clang_version(module_ctx)
            for llvm_version in llvm_repo_versions:
                if llvm_version not in clang_versions_dict:
                    fail("Invalid Clang/LLVM version '{}' in toolchain_set '{}'. Valid versions are: {}".format(llvm_version, group_name, clang_versions_dict.keys()))
        if llvm_versions:
            if default_clang_version and default_clang_version not in llvm_versions:
                fail("toolchain_set '{}': default_llvm_version '{}' is not in llvm_versions list: {}".format(group_name, default_clang_version, llvm_versions))
        elif default_clang_version:
            fail("toolchain_set '{}': default_llvm_version requires llvm_versions to be set.".format(group_name))

        for h in hosts:
            if h not in VALID_MSVC_HOSTS:
                fail("Invalid host '{}' in toolchain_set '{}', must be one of: {}".format(h, group_name, VALID_MSVC_HOSTS))
        for t in targets:
            if t not in VALID_MSVC_TARGETS:
                fail("Invalid target '{}' in toolchain_set '{}', must be one of: {}".format(t, group_name, VALID_MSVC_TARGETS))

        all_targets = _unique_values(all_targets + targets)
        all_hosts = _unique_values(all_hosts + hosts)
        all_msvc_versions = _unique_values(all_msvc_versions + msvc_versions)
        all_llvm_versions = _unique_values(all_llvm_versions + llvm_repo_versions)
        all_winsdk_versions = _unique_values(all_winsdk_versions + winsdk_versions)

        # Resolve flags (merge defaults with replace/add from each toolchain_set) in the extension.
        msvc_default_c_compile_flags = merge_flags(CL_C_COMPILE_FLAGS_DEFAULT, group.cl_copt, group.add_cl_copt)
        msvc_default_cxx_compile_flags = merge_flags(CL_CXX_COMPILE_FLAGS_DEFAULT, group.cl_cxxopt, group.add_cl_cxxopt)
        msvc_default_link_flags = merge_flags(CL_LINK_FLAGS_DEFAULT, group.cl_linkopt, group.add_cl_linkopt)
        msvc_dbg_c_compile_flags = merge_flags(CL_DBG_C_COMPILE_FLAGS_DEFAULT, group.cl_dbg_copt, group.add_cl_dbg_copt)
        msvc_dbg_cxx_compile_flags = merge_flags(CL_DBG_CXX_COMPILE_FLAGS_DEFAULT, group.cl_dbg_cxxopt, group.add_cl_dbg_cxxopt)
        msvc_dbg_link_flags = merge_flags(CL_DBG_LINK_FLAGS_DEFAULT, group.cl_dbg_linkopt, group.add_cl_dbg_linkopt)
        msvc_fastbuild_c_compile_flags = merge_flags(CL_FASTBUILD_C_COMPILE_FLAGS_DEFAULT, group.cl_fastbuild_copt, group.add_cl_fastbuild_copt)
        msvc_fastbuild_cxx_compile_flags = merge_flags(CL_FASTBUILD_CXX_COMPILE_FLAGS_DEFAULT, group.cl_fastbuild_cxxopt, group.add_cl_fastbuild_cxxopt)
        msvc_fastbuild_link_flags = merge_flags(CL_FASTBUILD_LINK_FLAGS_DEFAULT, group.cl_fastbuild_linkopt, group.add_cl_fastbuild_linkopt)
        msvc_opt_c_compile_flags = merge_flags(CL_OPT_C_COMPILE_FLAGS_DEFAULT, group.cl_opt_copt, group.add_cl_opt_copt)
        msvc_opt_cxx_compile_flags = merge_flags(CL_OPT_CXX_COMPILE_FLAGS_DEFAULT, group.cl_opt_cxxopt, group.add_cl_opt_cxxopt)
        msvc_opt_link_flags = merge_flags(CL_OPT_LINK_FLAGS_DEFAULT, group.cl_opt_linkopt, group.add_cl_opt_linkopt)

        clang_default_c_compile_flags = merge_flags(CLANG_C_COMPILE_FLAGS_DEFAULT, group.clang_copt, group.add_clang_copt)
        clang_default_cxx_compile_flags = merge_flags(CLANG_CXX_COMPILE_FLAGS_DEFAULT, group.clang_cxxopt, group.add_clang_cxxopt)
        clang_default_link_flags = merge_flags(CLANG_LINK_FLAGS_DEFAULT, group.clang_linkopt, group.add_clang_linkopt)
        clang_dbg_c_compile_flags = merge_flags(CLANG_DBG_C_COMPILE_FLAGS_DEFAULT, group.clang_dbg_copt, group.add_clang_dbg_copt)
        clang_dbg_cxx_compile_flags = merge_flags(CLANG_DBG_CXX_COMPILE_FLAGS_DEFAULT, group.clang_dbg_cxxopt, group.add_clang_dbg_cxxopt)
        clang_dbg_link_flags = merge_flags(CLANG_DBG_LINK_FLAGS_DEFAULT, group.clang_dbg_linkopt, group.add_clang_dbg_linkopt)
        clang_fastbuild_c_compile_flags = merge_flags(CLANG_FASTBUILD_C_COMPILE_FLAGS_DEFAULT, group.clang_fastbuild_copt, group.add_clang_fastbuild_copt)
        clang_fastbuild_cxx_compile_flags = merge_flags(CLANG_FASTBUILD_CXX_COMPILE_FLAGS_DEFAULT, group.clang_fastbuild_cxxopt, group.add_clang_fastbuild_cxxopt)
        clang_fastbuild_link_flags = merge_flags(CLANG_FASTBUILD_LINK_FLAGS_DEFAULT, group.clang_fastbuild_linkopt, group.add_clang_fastbuild_linkopt)
        clang_opt_c_compile_flags = merge_flags(CLANG_OPT_C_COMPILE_FLAGS_DEFAULT, group.clang_opt_copt, group.add_clang_opt_copt)
        clang_opt_cxx_compile_flags = merge_flags(CLANG_OPT_CXX_COMPILE_FLAGS_DEFAULT, group.clang_opt_cxxopt, group.add_clang_opt_cxxopt)
        clang_opt_link_flags = merge_flags(CLANG_OPT_LINK_FLAGS_DEFAULT, group.clang_opt_linkopt, group.add_clang_opt_linkopt)

        group_configs.append({
            "name": group_name,
            "targets": targets,
            "hosts": hosts,
            "msvc_versions": msvc_versions,
            "llvm_versions": llvm_versions,
            "winsdk_versions": winsdk_versions,
            "default_msvc_version": default_msvc_version,
            "default_clang_version": default_clang_version,
            "default_windows_sdk_version": default_windows_sdk_version,
            "default_compiler": default_compiler,
            "cl_with_lld_version": cl_with_lld_version,
            "msvc_default_c_compile_flags": msvc_default_c_compile_flags,
            "msvc_default_cxx_compile_flags": msvc_default_cxx_compile_flags,
            "msvc_default_link_flags": msvc_default_link_flags,
            "msvc_dbg_c_compile_flags": msvc_dbg_c_compile_flags,
            "msvc_dbg_cxx_compile_flags": msvc_dbg_cxx_compile_flags,
            "msvc_dbg_link_flags": msvc_dbg_link_flags,
            "msvc_fastbuild_c_compile_flags": msvc_fastbuild_c_compile_flags,
            "msvc_fastbuild_cxx_compile_flags": msvc_fastbuild_cxx_compile_flags,
            "msvc_fastbuild_link_flags": msvc_fastbuild_link_flags,
            "msvc_opt_c_compile_flags": msvc_opt_c_compile_flags,
            "msvc_opt_cxx_compile_flags": msvc_opt_cxx_compile_flags,
            "msvc_opt_link_flags": msvc_opt_link_flags,
            "clang_default_c_compile_flags": clang_default_c_compile_flags,
            "clang_default_cxx_compile_flags": clang_default_cxx_compile_flags,
            "clang_default_link_flags": clang_default_link_flags,
            "clang_dbg_c_compile_flags": clang_dbg_c_compile_flags,
            "clang_dbg_cxx_compile_flags": clang_dbg_cxx_compile_flags,
            "clang_dbg_link_flags": clang_dbg_link_flags,
            "clang_fastbuild_c_compile_flags": clang_fastbuild_c_compile_flags,
            "clang_fastbuild_cxx_compile_flags": clang_fastbuild_cxx_compile_flags,
            "clang_fastbuild_link_flags": clang_fastbuild_link_flags,
            "clang_opt_c_compile_flags": clang_opt_c_compile_flags,
            "clang_opt_cxx_compile_flags": clang_opt_cxx_compile_flags,
            "clang_opt_link_flags": clang_opt_link_flags,
            "default_features": group.features,
            "dbg_implies_features": group.dbg_features,
            "fastbuild_implies_features": group.fastbuild_features,
            "opt_implies_features": group.opt_features,
        })

    if default_toolchain_set_name == None:
        default_toolchain_set_name = group_names[0]
    elif default_toolchain_set_name not in group_names_set:
        fail("default_toolchain_set '{}' does not match any declared toolchain_set. Available values: {}".format(default_toolchain_set_name, group_names))

    default_group = None
    for group_config in group_configs:
        if group_config["name"] == default_toolchain_set_name:
            default_group = group_config
            break
    if default_group == None:
        fail("Internal error: failed to resolve default toolchain_set '{}'.".format(default_toolchain_set_name))

    all_packages_url = {}
    for package_map_key in sorted(packages_maps.keys()):
        packages_map = packages_maps[package_map_key]
        for package_id in sorted(packages_map.keys()):
            payloads = packages_map[package_id].get("payloads", [])
            for payload in payloads:
                url = payload.get("url")
                sha256 = payload.get("sha256")
                if url and sha256:
                    _register_package_url(all_packages_url, sha256, url)
    if clang_versions_dict != None:
        for llvm_version in sorted(clang_versions_dict.keys()):
            entry = clang_versions_dict[llvm_version]
            for arch in ["x64", "arm64"]:
                url = entry.get(arch)
                sha256 = entry.get("{}_digest".format(arch))
                if url and sha256:
                    _register_package_url(all_packages_url, sha256, url)

    repos = {}

    # 2. Construct llvm repo definitions (only if llvm versions are defined)
    if all_llvm_versions:
        for llvm_version in all_llvm_versions:
            entry = clang_versions_dict[llvm_version]
            for host in all_hosts:
                if host == "x86":
                    continue  # LLVM does not provide x86 Windows binaries
                digest = entry["x64_digest"] if host == "x64" else entry["arm64_digest"]
                if not digest:
                    fail("Missing digest for LLVM version '{}' host '{}' in {}".format(llvm_version, host, entry))
                _register_repo_definition(repos, {
                    "kind": "llvm",
                    "name": "llvm_{}_{}".format(llvm_version, host),
                    "version": llvm_version,
                    "host": host,
                    "packages": _sort_packages([{
                        "filename": _llvm_package_filename(llvm_version, host),
                        "sha256": digest,
                    }]),
                })

    # 3. Construct all msvc repo definitions
    for msvc_version in all_msvc_versions:
        msvc_package_map_key = msvc_versions_dict[msvc_version]
        msvc_packages_map = packages_maps[msvc_package_map_key]
        deps = get_msvc_package_ids(msvc_packages_map, msvc_version, hosts = all_hosts, targets = all_targets)

        closest_redist, redist_package_map_key = _find_closest_redist_version(msvc_version, redist_versions_dict)
        redist_packages_map = packages_maps[redist_package_map_key]
        redist_deps = get_msvc_redist_package_ids(redist_packages_map, closest_redist, targets = all_targets)
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
                        sha256 = payload.get("sha256")
                        filename = payload.get("fileName")
                        if not sha256 or not filename:
                            fail("MSVC payload in '{}' is missing sha256 or fileName".format(dep_id))
                        packages_list.append({
                            "filename": filename,
                            "sha256": sha256,
                        })

        _register_repo_definition(repos, {
            "kind": "msvc",
            "name": "msvc_{}".format(msvc_version),
            "hosts": all_hosts,
            "targets": all_targets,
            "packages": _sort_packages(packages_list),
        })

    # 4. Construct all winsdk repo definitions
    for winsdk_version in all_winsdk_versions:
        winsdk_package_map_key = winsdk_versions_dict[winsdk_version]
        winsdk_packages_map = packages_maps[winsdk_package_map_key]
        id = get_winsdk_package_id(winsdk_version)
        required_msi_files = get_winsdk_msi_list(all_targets)

        packages_list = []
        pkg = winsdk_packages_map.get(id)
        payloads = pkg.get("payloads", [])
        for payload in payloads:
            if "url" in payload and "fileName" in payload:
                sha256 = payload.get("sha256")
                if not sha256:
                    fail("WinSDK payload for '{}' is missing sha256".format(id))
                raw_filename = payload["fileName"]
                filename = raw_filename
                if raw_filename.startswith("Installers\\"):
                    filename = raw_filename[len("Installers\\"):]
                if filename.endswith(".msi"):
                    for required_msi_file in required_msi_files:
                        if filename.endswith(required_msi_file):
                            packages_list.append({
                                "filename": filename,
                                "sha256": sha256,
                            })
                            break
                elif filename.endswith(".cab"):
                    packages_list.append({
                        "filename": filename,
                        "sha256": sha256,
                    })

        _register_repo_definition(repos, {
            "kind": "winsdk",
            "name": "winsdk_{}".format(winsdk_version),
            "targets": all_targets,
            "packages": _sort_packages(packages_list),
            "winsdk_version": winsdk_version,
        })

    default_repo_llvm_version = default_group["default_clang_version"]
    if not default_repo_llvm_version and default_group["cl_with_lld_version"]:
        default_repo_llvm_version = default_group["cl_with_lld_version"]

    module_lock_repos = {
        repo_name: repos[repo_name]
        for repo_name in sorted(repos.keys())
    }

    user_lock_repos = None
    relative_lock_file_path = None
    if is_locked:
        module_ctx.watch(lock_file_label)
        lock_path = module_ctx.path(lock_file_label)
        if lock_path.exists:
            user_lock_repos = json.decode(module_ctx.read(lock_file_label), default = None)
        if lock_file_label.package:
            relative_lock_file_path = "{}/{}".format(lock_file_label.package, lock_file_label.name)
        else:
            relative_lock_file_path = lock_file_label.name

    lock_file_repo(
        name = "toolchains_msvc_lock",
        lock_json = json.encode_indent(module_lock_repos),
        lock_file_path = relative_lock_file_path,
    )

    for repo_name in sorted(module_lock_repos.keys()):
        repo = module_lock_repos[repo_name]
        kind = repo["kind"]

        lock_error = _lock_error_for_repo(
                relative_lock_file_path,
                repo_name,
                module_lock_repos[repo_name],
                user_lock_repos,
        )

        if lock_error:
            packages = []
            package_urls = {}
        else:
            packages = repo["packages"]
            package_urls = _package_urls_for_repo(all_packages_url, repo["packages"])

        if kind == "llvm":
            llvm_repo(
                name = repo["name"],
                version = repo["version"],
                host = repo["host"],
                packages = json.encode(packages),
                package_urls = json.encode(package_urls),
                error = lock_error,
            )
            continue

        if kind == "msvc":
            msvc_repo(
                name = repo["name"],
                hosts = repo["hosts"],
                targets = repo["targets"],
                packages = json.encode(packages),
                package_urls = json.encode(package_urls),
                error = lock_error,
            )
            continue

        if kind == "winsdk":
            winsdk_repo(
                name = repo["name"],
                targets = repo["targets"],
                packages = json.encode(packages),
                package_urls = json.encode(package_urls),
                winsdk_version = repo["winsdk_version"],
                error = lock_error,
            )
            continue

        fail("Unsupported repo kind '{}' for repo '{}'".format(kind, repo["name"]))

    # 5. Instantiate toolchains repo with resolved toolchain_set configs.
    msvc_toolchains_repo(
        name = repo_name_value,
        group_configs = json.encode(group_configs),
        toolchain_sets = group_names,
        default_toolchain_set = default_toolchain_set_name,
        llvm_versions = all_llvm_versions,
        msvc_versions = all_msvc_versions,
        winsdk_versions = all_winsdk_versions,
        targets = all_targets,
        hosts = all_hosts,
        default_msvc_version = default_group["default_msvc_version"],
        default_clang_version = default_repo_llvm_version,
        default_windows_sdk_version = default_group["default_windows_sdk_version"],
        default_compiler = default_group["default_compiler"],
    )

    return module_ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = [repo_name_value],
        root_module_direct_dev_deps = [],
    )

repo_name_tag = tag_class(attrs = {"name": attr.string(mandatory = True)})

toolchain_set_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "targets": attr.string_list(default = []),
        "hosts": attr.string_list(default = []),
        "msvc_versions": attr.string_list(default = []),
        "default_msvc_version": attr.string(default = ""),
        "cl_with_lld_version": attr.string(default = ""),
        "llvm_versions": attr.string_list(default = []),
        "default_llvm_version": attr.string(default = ""),
        "winsdk_versions": attr.string_list(default = []),
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

default_toolchain_set_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
    },
)

lock_tag = tag_class(
    attrs = {
        "file": attr.label(mandatory = True),
    },
)

toolchain = module_extension(
    implementation = _extension_impl,
    tag_classes = {
        "lock": lock_tag,
        "repo_name": repo_name_tag,
        "toolchain_set": toolchain_set_tag,
        "default_toolchain_set": default_toolchain_set_tag,
    },
    environ = [
        "BAZEL_TOOLCHAINS_MSVC_HOSTS",
        "BAZEL_TOOLCHAINS_MSVC_TARGETS",
        "BAZEL_TOOLCHAINS_MSVC_ACCEPT_MICROSOFT_VISUAL_STUDIO_BUILDTOOLS_EULA",
    ],
)
