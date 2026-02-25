load("//private:msvc_repo.bzl", "msvc_repo")
load("//private:msvc_toolchains_repo.bzl", "msvc_toolchains_repo")
load("//private:utils.bzl", "convert_bazel_arch_to_msvc_arch")
load(
    "//private:vs_channel_manifest.bzl",
    "VALID_MSVC_HOSTS",
    "VALID_MSVC_TARGETS",
    "download_and_map",
    "get_msvc_package_ids",
    "get_winsdk_msi_list",
    "get_winsdk_package_id",
    "list_msvc_version",
    "list_winsdk_version",
)
load("//private:winsdk_repo.bzl", "winsdk_repo")

def _extension_impl(module_ctx):
    # 1. Download manifest and map
    packages_map = download_and_map(module_ctx)

    msvc_versions_set = {}
    winsdk_versions_set = {}
    targets_set = {}
    hosts_set = {}

    for mod in module_ctx.modules:
        for tag in mod.tags.msvc_compiler:
            msvc_versions_set[tag.version] = True
        for tag in mod.tags.windows_sdk:
            winsdk_versions_set[tag.version] = True
        for tag in mod.tags.target:
            targets_set[tag.arch] = True
        for tag in mod.tags.host:
            hosts_set[tag.arch] = True

    msvc_versions = msvc_versions_set.keys()
    winsdk_versions = winsdk_versions_set.keys()

    valid_msvc_versions = list_msvc_version(packages_map)
    for msvc_version in msvc_versions:
        if msvc_version not in valid_msvc_versions:
            fail("Invalid MSVC version '{}'. Valid versions are: {}".format(msvc_version, valid_msvc_versions))

    valid_winsdk_versions = list_winsdk_version(packages_map)
    for winsdk_version in winsdk_versions:
        if winsdk_version not in valid_winsdk_versions:
            fail("Invalid Windows SDK version '{}'. Valid versions are: {}".format(winsdk_version, valid_winsdk_versions))
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

    # 3. Construct all msvc repos
    for msvc_version in msvc_versions:
        deps = get_msvc_package_ids(packages_map, msvc_version, hosts = hosts, targets = targets)

        packages_list = []
        for dep_id in deps:
            pkg = packages_map.get(dep_id)
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
        id = get_winsdk_package_id(winsdk_version)
        required_msi_files = get_winsdk_msi_list(targets)

        cab_list = {}
        msi_list = []
        pkg = packages_map.get(id)
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

msvc_compiler_tag = tag_class(attrs = {"version": attr.string(mandatory = True)})
windows_sdk_tag = tag_class(attrs = {"version": attr.string(mandatory = True)})
target_tag = tag_class(attrs = {"arch": attr.string(mandatory = True)})
host_tag = tag_class(attrs = {"arch": attr.string(mandatory = True)})

toolchain = module_extension(
    implementation = _extension_impl,
    tag_classes = {
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
