"""Module extension for the MSVC toolchain."""

def _repo_impl(ctx):
    ctx.file("found.txt", ctx.attr.content)
    ctx.file("BUILD.bazel", 'exports_files(["found.txt"])')

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
