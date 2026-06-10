"""Repository rule for downloading MSVC compiler artifacts."""

load("//private:common.bzl", "normalize_repository_os")

def _package_url(package_urls, pkg):
    sha256 = pkg.get("sha256")
    url = package_urls.get(sha256)
    if not url:
        fail("Missing URL for MSVC package '{}' ({})".format(pkg.get("filename"), sha256))
    return url

def _create_lowercase_symlinks(ctx, root_path):
    """Creates case-alias symlinks under *root_path* for case-sensitive filesystems.

    On case-sensitive filesystems (ext4, etc.), lld-link and clang-cl cannot find
    libraries/headers when the casing of the ``#include`` directive or link input
    differs from the on-disk filename.  For example, ``#include <DriverSpecs.h>``
    fails when the file is stored as ``driverspecs.h``, and linking against
    ``kernel32.lib`` fails when the file is stored as ``Kernel32.Lib``.

    This helper runs a Python script that scans headers for ``#include``
    directives and creates symlinks for each reference whose casing differs from
    the on-disk name, plus lowercase symlinks for all files.

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
        pass

def _msvc_repo_impl(ctx):
    """Implementation of the msvc_repo rule."""
    if ctx.attr.error:
        fail(ctx.attr.error)

    packages = json.decode(ctx.attr.packages)
    package_urls = json.decode(ctx.attr.package_urls)
    extracted_package_filenames = []

    for pkg in packages:
        sha256 = pkg.get("sha256")
        filename = pkg.get("filename")

        ctx.report_progress("Downloading and Extracting {}".format(filename))

        ctx.download_and_extract(
            url = _package_url(package_urls, pkg),
            sha256 = sha256,
            output = "tmp",
            type = "zip",
        )

        extracted_package_filenames.append(filename)

    ctx.file(
        "package.txt",
        "\n".join(extracted_package_filenames) + ("\n" if extracted_package_filenames else ""),
    )

    tools_dir = ctx.path("tmp/Contents/VC/Tools/MSVC").readdir()[0]
    redist_dir = ctx.path("tmp/Contents/VC/Redist/MSVC").readdir()[0]

    ctx.rename(tools_dir, "Tools")
    ctx.rename(redist_dir, "Redist")
    ctx.delete("tmp")

    # On case-sensitive filesystems, create lowercase symlinks for MSVC
    # headers and libraries (e.g. Tools/lib/x64/Kernel32.Lib -> kernel32.lib).
    _create_lowercase_symlinks(ctx, ctx.path("Tools/lib"))
    _create_lowercase_symlinks(ctx, ctx.path("Tools/include"))

    # Add cl_wrapper.bat next to cl.exe in every host/target config so EXECROOT can be
    # forwarded to cl.exe via /pathmap:%EXECROOT%=. for reproducible paths.
    cl_wrapper_content = """@echo off
:: %CD% provides the absolute path of the current directory (the execroot)
set EXECROOT=%CD%
"%~dp0cl.exe" /pathmap:%EXECROOT%=. %*
"""
    for host in ctx.attr.hosts:
        for target in ctx.attr.targets:
            ctx.file(
                "Tools/bin/Host{host}/{target}/cl_wrapper.bat".format(host = host, target = target),
                cl_wrapper_content,
            )

    # Generate a BUILD file
    ctx.template(
        "BUILD.bazel",
        ctx.attr.src_build,
    )

    return ctx.repo_metadata(reproducible = True)

msvc_repo = repository_rule(
    implementation = _msvc_repo_impl,
    attrs = {
        "packages": attr.string(mandatory = True, doc = "JSON string list of package dicts"),
        "package_urls": attr.string(mandatory = True, doc = "JSON string map from sha256 to URL"),
        "error": attr.string(mandatory = True),
        "hosts": attr.string_list(doc = "Host architectures"),
        "targets": attr.string_list(doc = "Target architectures"),
        "src_build": attr.label(default = Label("//overlays/msvc:BUILD.root.tpl"), allow_single_file = True, doc = "Label to BUILD.root.tpl"),
    },
)
