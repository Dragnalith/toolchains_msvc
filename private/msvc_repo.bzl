"""Repository rule for downloading MSVC compiler artifacts."""

def _msvc_repo_impl(ctx):
    """Implementation of the msvc_repo rule."""
    packages = json.decode(ctx.attr.packages)
    extracted_package_filenames = []

    for pkg in packages:
        url = pkg.get("url")
        sha256 = pkg.get("sha256")
        filename = pkg.get("filename")

        ctx.report_progress("Downloading and Extracting {}".format(filename))

        ctx.download_and_extract(
            url = url,
            sha256 = sha256,
            output = "tmp",
            type = "zip",
        )

        extracted_package_filenames.append(filename)

    tools_dir = ctx.path("tmp/Contents/VC/Tools/MSVC").readdir()[0]
    redist_dir = ctx.path("tmp/Contents/VC/Redist/MSVC").readdir()[0]

    ctx.execute(["cmd", "/c", "move", str(tools_dir).replace("/", "\\"), "Tools"])
    ctx.execute(["cmd", "/c", "move", str(redist_dir).replace("/", "\\"), "Redist"])
    ctx.file(
        "package.txt",
        "\n".join(extracted_package_filenames) + ("\n" if extracted_package_filenames else ""),
    )
    ctx.delete("tmp")

    # Generate a BUILD file
    ctx.template(
        "BUILD.bazel",
        ctx.attr.src_build,
    )

msvc_repo = repository_rule(
    implementation = _msvc_repo_impl,
    attrs = {
        "packages": attr.string(doc = "JSON string list of package dicts"),
        "hosts": attr.string_list(doc = "Host architectures"),
        "targets": attr.string_list(doc = "Target architectures"),
        "src_build": attr.label(default = Label("//overlays/msvc:BUILD.root.tpl"), allow_single_file = True, doc = "Label to BUILD.root.tpl"),
    },
)
