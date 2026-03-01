"""Toolchains extension for toolchains_msvc."""

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

    msvc_versions_set = {}
    clang_versions_set = {}
    winsdk_versions_set = {}
    targets_set = {}
    hosts_set = {}

    for mod in module_ctx.modules:
        for tag in mod.tags.clang_compiler:
            clang_versions_set[tag.version] = True
        for tag in mod.tags.msvc_compiler:
            msvc_versions_set[tag.version] = True
        for tag in mod.tags.windows_sdk:
            winsdk_versions_set[tag.version] = True
        for tag in mod.tags.target:
            targets_set[tag.arch] = True
        for tag in mod.tags.host:
            hosts_set[tag.arch] = True

    clang_versions = clang_versions_set.keys()
    msvc_versions = msvc_versions_set.keys()
    winsdk_versions = winsdk_versions_set.keys()

    msvc_versions_dict = list_msvc_version(packages_maps)
    for msvc_version in msvc_versions:
        if msvc_version not in msvc_versions_dict:
            fail("Invalid MSVC version '{}'. Valid versions are: {}".format(msvc_version, msvc_versions_dict.keys()))

    winsdk_versions_dict = list_winsdk_version(packages_maps)
    for winsdk_version in winsdk_versions:
        if winsdk_version not in winsdk_versions_dict:
            fail("Invalid Windows SDK version '{}'. Valid versions are: {}".format(winsdk_version, winsdk_versions_dict.keys()))

    targets = targets_set.keys()
    hosts = hosts_set.keys()

    env_hosts = module_ctx.os.environ.get("BAZEL_TOOLCHAINS_MSVC_HOSTS", "").strip()
    if hosts and env_hosts != "":
        fail("BAZEL_TOOLCHAINS_MSVC_HOSTS environment variable is set, but toolchain.host() was also called. Please use only one mechanism.")

    if not hosts:
        if env_hosts != "":
            hosts = [h.strip() for h in env_hosts.split(",") if h.strip()]

    env_targets = module_ctx.os.environ.get("BAZEL_TOOLCHAINS_MSVC_TARGETS", "").strip()
    if targets and env_targets != "":
        fail("BAZEL_TOOLCHAINS_MSVC_TARGETS environment variable is set, but toolchain.target() was also called. Please use only one mechanism.")

    if not targets:
        if env_targets != "":
            targets = [t.strip() for t in env_targets.split(",") if t.strip()]
        else:
            fail("No targets specified. Please use toolchain.target() or set BAZEL_TOOLCHAINS_MSVC_TARGETS.")

    for h in hosts:
        if h not in VALID_MSVC_HOSTS:
            fail("Invalid host '{}', must be one of: {}".format(h, VALID_MSVC_HOSTS))
    for t in targets:
        if t not in VALID_MSVC_TARGETS:
            fail("Invalid target '{}', must be one of: {}".format(t, VALID_MSVC_TARGETS))

    redist_versions_dict = list_msvc_redist_version(packages_maps)

    # 2. Construct all clang repos (only if clang versions are defined)
    if clang_versions:
        clang_versions_dict = list_clang_version(module_ctx)
        for clang_version in clang_versions:
            if clang_version not in clang_versions_dict:
                fail("Invalid Clang/LLVM version '{}'. Valid versions are: {}".format(clang_version, clang_versions_dict.keys()))
        for clang_version in clang_versions:
            entry = clang_versions_dict[clang_version]
            for host in hosts:
                if host == "x86":
                    continue  # LLVM does not provide x86 Windows binaries
                url = entry["x64"] if host == "x64" else entry["arm64"]
                digest = entry["x64_digest"] if host == "x64" else entry["arm64_digest"]
                llvm_repo(
                    name = "llvm_{}_{}".format(clang_version, host),
                    version = clang_version,
                    host = host,
                    url = url,
                    digest = digest,
                    src_build = Label("//overlays/clang:BUILD.root.tpl"),
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

    # 5. Instantiate msvc_toolchains repo
    msvc_toolchains_repo(
        name = "msvc_toolchains",
        clang_versions = clang_versions,
        msvc_versions = msvc_versions,
        winsdk_versions = winsdk_versions,
        targets = targets,
        hosts = hosts,
    )

    return module_ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = ["msvc_toolchains"],
        root_module_direct_dev_deps = [],
    )

clang_compiler_tag = tag_class(attrs = {"version": attr.string(mandatory = True)})
msvc_compiler_tag = tag_class(attrs = {"version": attr.string(mandatory = True)})
windows_sdk_tag = tag_class(attrs = {"version": attr.string(mandatory = True)})
target_tag = tag_class(attrs = {"arch": attr.string(mandatory = True)})
host_tag = tag_class(attrs = {"arch": attr.string(mandatory = True)})

toolchain = module_extension(
    implementation = _extension_impl,
    tag_classes = {
        "clang_compiler": clang_compiler_tag,
        "msvc_compiler": msvc_compiler_tag,
        "windows_sdk": windows_sdk_tag,
        "target": target_tag,
        "host": host_tag,
    },
    environ = [
        "BAZEL_TOOLCHAINS_MSVC_HOSTS",
        "BAZEL_TOOLCHAINS_MSVC_TARGETS",
    ],
)
