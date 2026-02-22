load("//private:msvc_repo.bzl", "msvc_repo")
load("//private:msvc_toolchains_repo.bzl", "msvc_toolchains_repo")
load(
    "//private:vs_channel_manifest.bzl",
    "download_and_map",
    "get_msvc_package_ids",
    "get_winsdk_msi_list",
    "get_winsdk_package_id",
)
load("//private:winsdk_repo.bzl", "winsdk_repo")

def _extension_impl(ctx):
    # 1. Download manifest and map
    packages_map = download_and_map(ctx)

    # 2. For verification, hardcode one version
    msvc_versions = ["14.44"]
    winsdk_versions = ["26100"]
    targets = ["x86", "x64", "arm", "arm64"]
    hosts = ["x86", "x64", "arm64"]

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
    )

    return ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = ["msvc_toolchains"],
        root_module_direct_dev_deps = [],
    )

toolchain = module_extension(
    implementation = _extension_impl,
)
