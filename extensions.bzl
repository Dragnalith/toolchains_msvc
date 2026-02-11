"""Module extension for the MSVC toolchain."""

def _repo_impl(ctx):
    ctx.file("found.txt", ctx.attr.content)

    # 1. Download the root manifest
    ctx.download(
        url = "https://aka.ms/vs/17/release/channel",
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
    ctx.download(
        url = package_manifest_url,
        output = "visual_studio_package_manifest.json",
    )

    ctx.file("BUILD.bazel", 'exports_files(["found.txt", "visual_studio_root_manifest.json", "visual_studio_package_manifest.json"])')

msvc_repo = repository_rule(
    implementation = _repo_impl,
    attrs = {
        "content": attr.string(),
    },
)

def _extension_impl(ctx):
    content = ""
    for mod in ctx.modules:
        for toolchain in mod.tags.msvc:
            content += "MSVC Toolchain: {}, SDK: {}\n".format(toolchain.msvc_version, toolchain.win_sdk_version)

    msvc_repo(
        name = "msvc_toolchain",
        content = content,
    )
    return ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = [],
        root_module_direct_dev_deps = [],
    )

add_toolchain = module_extension(
    implementation = _extension_impl,
    tag_classes = {
        "msvc": tag_class(
            attrs = {
                "msvc_version": attr.string(mandatory = True),
                "win_sdk_version": attr.string(mandatory = True),
            },
        ),
    },
)
