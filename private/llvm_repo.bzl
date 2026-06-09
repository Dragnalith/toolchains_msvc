"""Repository rule for downloading LLVM/Clang compiler artifacts."""

def _package_url(package_urls, pkg):
    sha256 = pkg.get("sha256")
    url = package_urls.get(sha256)
    if not url:
        fail("Missing URL for LLVM package '{}' ({})".format(pkg.get("filename"), sha256))
    return url

def _llvm_repo_impl(ctx):
    version = ctx.attr.version
    host = ctx.attr.host
    host_os = ctx.attr.host_os

    if host == "x64":
        llvm_arch = "x86_64"
    elif host == "arm64":
        llvm_arch = "aarch64"
    else:
        fail("Unsupported LLVM host architecture: {}".format(host))

    packages = json.decode(ctx.attr.packages)
    package_urls = json.decode(ctx.attr.package_urls)
    if len(packages) != 1:
        fail("llvm_repo expects exactly one package, got {}".format(len(packages)))

    pkg = packages[0]
    filename = pkg.get("filename")

    if host_os == "linux":
        # Official LLVM Linux release: LLVM-{v}-Linux-X64.tar.xz
        ctx.report_progress("Downloading and Extracting {}".format(filename))
        ctx.download_and_extract(
            url = _package_url(package_urls, pkg),
            output = ".",
            type = "tar.xz",
            stripPrefix = "LLVM-{}-Linux-{}".format(version, "X64" if host == "x64" else "ARM64"),
            sha256 = pkg.get("sha256"),
        )
        src_build = ctx.attr.src_build_linux
    else:
        # Windows LLVM: clang+llvm-{v}-{arch}-pc-windows-msvc.tar.xz
        ctx.report_progress("Downloading and Extracting {}".format(filename))
        ctx.download_and_extract(
            url = _package_url(package_urls, pkg),
            output = ".",
            type = "tar.xz",
            stripPrefix = "clang+llvm-{}-{}-pc-windows-msvc".format(version, llvm_arch),
            sha256 = pkg.get("sha256"),
        )

        # Wrapper so lld-link is always invoked from the command line (via cmd when Bazel runs the .bat).
        lld_link_wrapper_content = """@echo off
set PATH=%PATH%;%~dp0
lld-link.exe %*
"""
        ctx.file("bin/lld-link_wrapper.bat", lld_link_wrapper_content)
        src_build = ctx.attr.src_build

    ctx.template(
        "BUILD.bazel",
        src_build,
        substitutions = {
            "{LLVM_VERSION}": version.split(".")[0],
        },
    )

    return ctx.repo_metadata(reproducible = True)

llvm_repo = repository_rule(
    implementation = _llvm_repo_impl,
    attrs = {
        "version": attr.string(mandatory = True, doc = "LLVM version"),
        "host": attr.string(mandatory = True, doc = "Host architecture"),
        "host_os": attr.string(mandatory = True, doc = "Host OS (windows or linux)"),
        "packages": attr.string(mandatory = True, doc = "JSON string list containing exactly one package dict"),
        "package_urls": attr.string(mandatory = True, doc = "JSON string map from sha256 to URL"),
        "src_build": attr.label(default = Label("//overlays/llvm:BUILD.root.tpl"), allow_single_file = True, doc = "Label to Windows BUILD.root.tpl"),
        "src_build_linux": attr.label(default = Label("//overlays/llvm:BUILD.root.linux.tpl"), allow_single_file = True, doc = "Label to Linux BUILD.root.tpl"),
    },
)
