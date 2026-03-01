"""Repository rule for downloading LLVM/Clang compiler artifacts."""

def _llvm_repo_impl(ctx):
    version = ctx.attr.version
    host_os = ctx.os.name
    host = ctx.attr.host

    if "windows" not in host_os:
        fail("LLVM repo only supports Windows host currently")

    if host == "x64":
        llvm_arch = "x86_64"
    elif host == "arm64":
        llvm_arch = "aarch64"
    else:
        fail("Unsupported LLVM host architecture for Windows: {}".format(host))

    url = ctx.attr.url
    digest = ctx.attr.digest
    filename = "clang+llvm-{}-{}-pc-windows-msvc.tar.xz".format(version, llvm_arch)
    ctx.report_progress("Downloading and Extracting {}".format(filename))

    ctx.download_and_extract(
        url = url,
        output = ".",
        type = "tar.xz",
        stripPrefix = "clang+llvm-{}-{}-pc-windows-msvc".format(version, llvm_arch),
        sha256 = digest,
    )

    ctx.template(
        "BUILD.bazel",
        ctx.attr.src_build,
    )

llvm_repo = repository_rule(
    implementation = _llvm_repo_impl,
    attrs = {
        "version": attr.string(mandatory = True, doc = "LLVM version"),
        "host": attr.string(mandatory = True, doc = "Host architecture"),
        "url": attr.string(mandatory = True, doc = "URL to the LLVM package (from list_clang_version)"),
        "digest": attr.string(default = "", doc = "SHA256 hex digest from manifest (sha256:<hex>) for download verification"),
        "src_build": attr.label(default = Label("//overlays/clang:BUILD.root.tpl"), allow_single_file = True, doc = "Label to BUILD.root.tpl"),
    },
)
