"""Repository rule for downloading and extracting Windows SDK artifacts."""

load("//private:common.bzl", "normalize_repository_os")

def _package_url(package_urls, pkg):
    sha256 = pkg.get("sha256")
    url = package_urls.get(sha256)
    if not url:
        fail("Missing URL for WinSDK package '{}' ({})".format(pkg.get("filename"), sha256))
    return url

def _create_lowercase_symlinks(ctx, root_path):
    """Creates case-alias symlinks under *root_path* for case-sensitive filesystems.

    On case-sensitive filesystems (ext4, etc.), lld-link and clang-cl cannot find
    libraries/headers when the casing of the ``#include`` directive or link input
    differs from the on-disk filename.  For example, ``#include <DriverSpecs.h>``
    fails when the file is stored as ``driverspecs.h``, and linking against
    ``kernel32.lib`` fails when the file is stored as ``Kernel32.Lib``.

    This helper runs a Python script that:
      1. Scans header files for ``#include`` directives
      2. Creates symlinks for each reference whose casing differs from on-disk name
      3. Creates lowercase symlinks for all files (e.g. ``Kernel32.Lib`` -> ``kernel32.lib``)

    Skipped on Windows (NTFS is case-insensitive, and symlinks would collide).
    """
    if normalize_repository_os(ctx.os.name) == "windows":
        return

    script = ctx.path(Label("@toolchains_msvc//private:symlink_casemap.py"))
    result = ctx.execute([
        "python3",
        str(script),
        str(root_path),
    ])
    if result.return_code != 0:
        # Non-fatal: missing symlinks may cause compile errors later but
        # shouldn't fail the repo fetch entirely.
        pass

def _get_cabs_from_msi(msi_util_path, ctx, local_msi_path):
    """Returns cabinet file names referenced by an MSI (via msi-util list-cab)."""
    msi_util = str(msi_util_path)
    msi_path = str(ctx.path(local_msi_path))

    result = ctx.execute([msi_util, "list-cab", msi_path], quiet = True)
    if result.return_code != 0:
        fail("Listing cabs for {} failed (exit {}): {}".format(local_msi_path, result.return_code, result.stderr))

    cabs = []
    for line in result.stdout.splitlines():
        item = line.strip()
        if item and item.lower().endswith(".cab"):
            cabs.append(item)
    return cabs

def _winsdk_repo_impl(ctx):
    """Implementation of the winsdk_repo rule."""
    if ctx.attr.error:
        fail(ctx.attr.error)

    packages = json.decode(ctx.attr.packages)
    package_urls = json.decode(ctx.attr.package_urls)
    msi_binary = ctx.path(ctx.attr.msiutil)

    cab_list = {}
    msi_list = []
    for pkg in packages:
        filename = pkg.get("filename")
        if not filename:
            fail("Each WinSDK package entry must contain 'filename'")
        if filename.lower().endswith(".msi"):
            msi_list.append(pkg)
        elif filename.lower().endswith(".cab"):
            cab_list[filename] = pkg
        else:
            fail("Unsupported WinSDK package '{}': expected .msi or .cab".format(filename))

    if not msi_list:
        fail("No MSI payloads provided to winsdk_repo")

    downloaded_msi_paths = []
    for msi in msi_list:
        filename = msi.get("filename")
        if not filename:
            fail("Each MSI entry must contain 'filename'")

        ctx.report_progress("Downloading '{}'".format(filename))
        ctx.download(
            url = _package_url(package_urls, msi),
            sha256 = msi.get("sha256"),
            output = "tmp/{}".format(filename),
        )
        downloaded_msi_paths.append(filename)

    required_cabs = {}
    for filename in downloaded_msi_paths:
        for cab_name in _get_cabs_from_msi(msi_binary, ctx, "tmp/{}".format(filename)):
            required_cabs[cab_name] = True

    msi_filenames = []
    for msi in msi_list:
        msi_filename = msi.get("filename")
        if msi_filename:
            msi_filenames.append(msi_filename)

    for cab_name in sorted(required_cabs.keys()):
        if cab_name not in cab_list:
            fail("Required cab '{}' not found in provided package payload list".format(cab_name))

        cab_payload = cab_list[cab_name]

        cab_filename = cab_payload.get("filename")
        ctx.report_progress("Downloading {}".format(cab_filename))
        ctx.download(
            url = _package_url(package_urls, cab_payload),
            sha256 = cab_payload.get("sha256"),
            output = "tmp/{}".format(cab_filename),
        )

    msi_util = str(msi_binary)
    extract_root = str(ctx.path("tmp/extracted"))
    for filename in downloaded_msi_paths:
        ctx.report_progress("Extracting MSI '{}'".format(filename))
        msi_path = str(ctx.path("tmp/{}".format(filename)))
        result = ctx.execute(
            [msi_util, "extract", "--output-dir", extract_root, msi_path],
            quiet = True,
        )
        if result.return_code != 0:
            fail("Extracting MSI {} failed (exit {}): {}".format(filename, result.return_code, result.stderr))

    extracted_dir = ctx.path("tmp/extracted/Windows Kits/10")
    for child in extracted_dir.readdir():
        child_name = str(child).replace("\\", "/").rsplit("/", 1)[1]
        ctx.rename(child, child_name)

    ctx.delete("tmp")

    # On case-sensitive filesystems, create lowercase symlinks for WinSDK
    # headers and libraries (e.g. Include/10.0.xxxxx.0/um/Windows.h -> windows.h,
    # Lib/10.0.xxxxx.0/um/x64/Kernel32.Lib -> kernel32.lib).
    for subdir in ["Include", "Lib"]:
        p = ctx.path(subdir)
        if p.exists:
            _create_lowercase_symlinks(ctx, p)

    ctx.file(
        "package.txt",
        "\n".join(msi_filenames) + ("\n" if msi_filenames else ""),
    )

    ctx.template(
        "BUILD.bazel",
        ctx.attr.src_build,
        substitutions = {
            "{winsdk_version}": ctx.attr.winsdk_version,
        },
    )

    return ctx.repo_metadata(reproducible = True)

winsdk_repo = repository_rule(
    implementation = _winsdk_repo_impl,
    attrs = {
        "msiutil": attr.label(mandatory = True, doc = "The msiutil binary (typically ``@msiutil//:<basename>`` exported by ``msiutil_repo``)."),
        "winsdk_version": attr.string(mandatory = True),
        "packages": attr.string(mandatory = True, doc = "JSON string list of WinSDK package dicts"),
        "package_urls": attr.string(mandatory = True, doc = "JSON string map from sha256 to URL"),
        "error": attr.string(mandatory = True),
        "targets": attr.string_list(doc = "Target architectures (currently unused)"),
        "src_build": attr.label(default = Label("//overlays/winsdk:BUILD.root.tpl"), allow_single_file = True, doc = "Label to BUILD.root.tpl"),
    },
)
