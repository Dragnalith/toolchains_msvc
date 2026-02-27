"""Module for downloading and parsing Visual Studio channel manifests."""

def download_and_map(ctx, channel_url):
    """Downloads the VS manifest from the given channel and returns a mapping of package IDs to package data.

    Args:
        ctx: The module_context or repository_ctx.
        channel_url: The channel URL to download from (e.g., "https://aka.ms/vs/17/release/channel").

    Returns:
        A dictionary mapping package IDs to package data.
    """

    # 1. Download the root manifest
    ctx.report_progress("Downloading Visual Studio root manifest from {}...".format(channel_url))
    ctx.download(
        url = channel_url,
        output = "visual_studio_root_manifest.json",
    )

    # 2. Parse the root manifest to find the package manifest URL
    root_manifest_content = ctx.read("visual_studio_root_manifest.json")
    root_manifest = json.decode(root_manifest_content)

    package_manifest_url = None
    for item in root_manifest["channelItems"]:
        if item["id"] == "Microsoft.VisualStudio.Manifests.VisualStudio":
            package_manifest_url = item["payloads"][0]["url"]
            break

    if not package_manifest_url:
        fail("Could not find Microsoft.VisualStudio.Manifests.VisualStudio in root manifest")

    # 3. Download the package manifest
    ctx.report_progress("Downloading Visual Studio package manifest...")
    ctx.download(
        url = package_manifest_url,
        output = "visual_studio_package_manifest.json",
    )

    package_manifest_content = ctx.read("visual_studio_package_manifest.json")
    package_manifest = json.decode(package_manifest_content)

    packages_map = {}
    for pkg in package_manifest.get("packages", []):
        if "id" not in pkg:
            fail("Every package must have an id")

        lang = pkg.get("language")
        if lang and lang.lower() != "en-us":
            continue

        pkg_id = pkg["id"].lower()
        packages_map[pkg_id] = pkg
        if pkg_id not in packages_map:
            fail("Package not found: {pkg_id}".format(pkg_id = pkg_id))

    return packages_map

def get_winsdk_msi_list(targets):
    msi_list = [
        "Windows SDK for Windows Store Apps Tools-x86_en-us.msi",
        "Windows SDK for Windows Store Apps Headers-x86_en-us.msi",
        "Windows SDK for Windows Store Apps Headers OnecoreUap-x86_en-us.msi",
        "Windows SDK for Windows Store Apps Libs-x86_en-us.msi",
        "Universal CRT Headers Libraries and Sources-x86_en-us.msi",
        "Windows SDK Desktop Headers x86-x86_en-us.msi",
        "Windows SDK Desktop Headers x64-x86_en-us.msi",
        "Windows SDK Desktop Headers arm64-x86_en-us.msi",
        "Windows SDK Desktop Headers arm-x86_en-us.msi",
        "Windows SDK OnecoreUap Headers x86-x86_en-us.msi",
        "Windows SDK OnecoreUap Headers x64-x86_en-us.msi",
        "Windows SDK OnecoreUap Headers arm64-x86_en-us.msi",
        "Windows SDK OnecoreUap Headers arm-x86_en-us.msi",
    ]
    for target in targets:
        msi_list.append("Windows SDK Desktop Libs {target}-x86_en-us.msi".format(target = target))
    return msi_list

def get_winsdk_package_id(version):
    """Finds all dependencies for a specific Windows SDK version."""
    if version == "19041":
        return "Win10SDK_10.0.19041".lower()
    else:
        return "Win11SDK_10.0.{version}".format(version = version).lower()

# Valid values for hosts: x86, x64, arm64
VALID_MSVC_HOSTS = ["x86", "x64", "arm64"]

# Valid values for targets: x86, x64, arm64
VALID_MSVC_TARGETS = ["x86", "x64", "arm64"]

def get_msvc_package_ids(
        packages_map,
        version,
        hosts = None,
        targets = None):
    """Finds all dependencies for a specific MSVC version.

    Args:
        packages_map: The map of package IDs to package data.
        version: The MSVC version string (e.g., "14.44.17.14").
        hosts: List of host architectures to include. Valid: x86, x64, arm64.
               Default None means include all hosts.
        targets: List of target architectures to include. Valid: x86, x64, arm64.
                 Default None means include all targets.

    Returns:
        A list of package IDs sorted alphabetically.
    """
    if hosts == None:
        hosts = VALID_MSVC_HOSTS
    if targets == None:
        targets = VALID_MSVC_TARGETS

    for h in hosts:
        if h not in VALID_MSVC_HOSTS:
            fail("Invalid host '{}', must be one of: {}".format(h, VALID_MSVC_HOSTS))
    for t in targets:
        if t not in VALID_MSVC_TARGETS:
            fail("Invalid target '{}', must be one of: {}".format(t, VALID_MSVC_TARGETS))

    # Construct Hosts and Targets filter
    excluded_targets = [t for t in VALID_MSVC_TARGETS if t not in targets]
    target_filter_patterns = [
        "." + t + "."
        for t in excluded_targets
    ]

    excluded_hosts = [h for h in VALID_MSVC_HOSTS if h not in hosts]
    host_filter_patterns = [
        "host" + h + "."
        for h in excluded_hosts
    ]

    def should_exclude_package(pid_lower):
        """Returns True if package should be excluded based on hosts/targets."""
        for pattern in target_filter_patterns:
            if pattern in pid_lower:
                return True
        for pattern in host_filter_patterns:
            if pattern in pid_lower:
                return True
        return False

    root_id = "Microsoft.VisualStudio.Product.BuildTools".lower()
    filter_prefix = "Microsoft.VC.{}.".format(version).lower()

    visited = {}
    found_dependencies = {}

    stack = [root_id]

    max_iterations = len(packages_map) * 10

    for _ in range(max_iterations):
        if not stack:
            break

        current_id = stack.pop()

        if current_id in visited:
            continue
        visited[current_id] = True

        if current_id not in packages_map: 
                continue
        pkg = packages_map.get(current_id)

        pid_lower = current_id.lower()

        is_match = False
        if current_id != root_id:
            if (pid_lower.startswith(filter_prefix) and
                pid_lower.endswith(".base") and
                "spectre" not in pid_lower and
                ".props" not in pid_lower and
                ".servicing" not in pid_lower and
                ".mfc" not in pid_lower and
                ".atl" not in pid_lower and
                ".onecore" not in pid_lower and
                ".cli" not in pid_lower and
                ".ca." not in pid_lower and
                ".redist." not in pid_lower and
                not should_exclude_package(pid_lower)):
                is_match = True

        if is_match:
            found_dependencies[current_id] = True

        dependencies = pkg.get("dependencies", {})
        for dep_id, dep_info in dependencies.items():
            if type(dep_info) == "dict":
                when_clause = dep_info.get("when")
                if when_clause != None:
                    found_root = False
                    for w in when_clause:
                        if w == root_id:
                            found_root = True
                            break
                    if not found_root:
                        continue
            stack.append(dep_id.lower())

    return sorted(found_dependencies.keys())

def list_winsdk_version(packages_maps):
    """Finds all available Windows SDK versions from the manifests.

    Args:
        packages_maps: Dict mapping package_map id (e.g., "18", "17") to package_map.

    Returns:
        A dict mapping version to package_map key. When printing, use .keys() for version list.
    """
    versions = {}
    # Prefer most recent package map (e.g. "18" over "17") when versions overlap
    for package_map_key in sorted(packages_maps.keys(), reverse = True):
        packages_map = packages_maps[package_map_key]
        for pkg_id in packages_map:
            version = None
            if pkg_id.startswith("Win11SDK_10.0.".lower()):
                version = pkg_id[len("Win11SDK_10.0."):]
            elif pkg_id.startswith("Win10SDK_10.0.".lower()):
                version = pkg_id[len("Win10SDK_10.0."):]

            if version:
                is_valid_version = True
                for p in version.split("."):
                    if not p.isdigit():
                        is_valid_version = False
                        break
                if is_valid_version and version not in versions:
                    versions[version] = package_map_key
    return {v: versions[v] for v in sorted(versions.keys())}

def list_msvc_version(packages_maps):
    """Finds all available MSVC versions from the manifests.

    Args:
        packages_maps: Dict mapping package_map id (e.g., "18", "17") to package_map.

    Returns:
        A dict mapping version to package_map key. When printing, use .keys() for version list.
    """
    versions = {}
    # Prefer most recent package map (e.g. "18" over "17") when versions overlap
    for package_map_key in sorted(packages_maps.keys(), reverse = True):
        packages_map = packages_maps[package_map_key]
        for pkg_id in packages_map:
            if pkg_id.startswith("Microsoft.VC.".lower()):
                remainder = pkg_id[len("Microsoft.VC."):]
                parts = remainder.split(".")
                version_parts = []
                for p in parts:
                    if p.isdigit():
                        version_parts.append(p)
                    else:
                        break
                if len(version_parts) >= 2:
                    version = ".".join(version_parts[:2])
                    if version not in versions:
                        versions[version] = package_map_key
    return {v: versions[v] for v in sorted(versions.keys())}

def get_msvc_redist_package_ids(
        packages_map,
        version,
        targets = None):
    """Finds all dependencies for a specific MSVC redist version.

    Args:
        packages_map: The map of package IDs to package data.
        version: The MSVC redist version string (e.g., "14.34").
        targets: List of target architectures to include. Valid: x86, x64, arm64.
                 Default None means include all targets.

    Returns:
        A list of package IDs sorted alphabetically.
    """
    if targets == None:
        targets = VALID_MSVC_TARGETS

    for t in targets:
        if t not in VALID_MSVC_TARGETS:
            fail("Invalid target '{}', must be one of: {}".format(t, VALID_MSVC_TARGETS))

    # Construct Targets filter
    excluded_targets = [t for t in VALID_MSVC_TARGETS if t not in targets]
    target_filter_patterns = [
        "." + t + "."
        for t in excluded_targets
    ]

    def should_exclude_package(pid_lower):
        """Returns True if package should be excluded based on targets."""
        for pattern in target_filter_patterns:
            if pattern in pid_lower:
                return True
        return False

    root_id = "Microsoft.VisualStudio.Product.BuildTools".lower()
    filter_prefix = "Microsoft.VC.{}.".format(version).lower()

    visited = {}
    found_dependencies = {}

    stack = [root_id]

    max_iterations = len(packages_map) * 2

    for _ in range(max_iterations):
        if not stack:
            break

        current_id = stack.pop()

        if current_id in visited:
            continue
        visited[current_id] = True

        pkg = packages_map.get(current_id)
        if not pkg:
            continue

        pid_lower = current_id.lower()

        is_match = False
        if current_id != root_id:
            if (pid_lower.startswith(filter_prefix) and
                pid_lower.endswith(".base") and
                ".crt.redist." in pid_lower and
                "spectre" not in pid_lower and
                ".props" not in pid_lower and
                ".servicing" not in pid_lower and
                ".mfc" not in pid_lower and
                ".atl" not in pid_lower and
                ".onecore" not in pid_lower and
                ".cli" not in pid_lower and
                ".ca." not in pid_lower and
                not should_exclude_package(pid_lower)):
                is_match = True

        if is_match:
            found_dependencies[current_id] = True

        dependencies = pkg.get("dependencies", {})
        for dep_id, dep_info in dependencies.items():
            if type(dep_info) == "dict":
                when_clause = dep_info.get("when")
                if when_clause != None:
                    found_root = False
                    for w in when_clause:
                        if w == root_id:
                            found_root = True
                            break
                    if not found_root:
                        continue

            stack.append(dep_id.lower())

    return sorted(found_dependencies.keys())

def list_msvc_redist_version(packages_maps):
    """Finds all available MSVC Redist versions from the manifests.

    Args:
        packages_maps: Dict mapping package_map id (e.g., "18", "17") to package_map.

    Returns:
        A dict mapping version to package_map key. When printing, use .keys() for version list.
    """
    versions = {}
    # Prefer most recent package map (e.g. "18" over "17") when versions overlap
    for package_map_key in sorted(packages_maps.keys(), reverse = True):
        packages_map = packages_maps[package_map_key]
        for pkg_id in packages_map:
            if pkg_id.startswith("Microsoft.VC.".lower()) and ".CRT.Redist.".lower() in pkg_id and pkg_id.endswith(".base"):
                remainder = pkg_id[len("Microsoft.VC."):]
                parts = remainder.split(".")
                version_parts = []
                for p in parts:
                    if p.isdigit():
                        version_parts.append(p)
                    else:
                        break
                if len(version_parts) >= 2:
                    version = ".".join(version_parts[:2])
                    if version not in versions:
                        versions[version] = package_map_key
    return {v: versions[v] for v in sorted(versions.keys())}
