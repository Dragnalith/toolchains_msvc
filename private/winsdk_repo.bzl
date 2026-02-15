"""Repository rule for downloading and extracting Windows SDK artifacts."""

def _get_cabs_from_msi(ctx, local_msi_path):
    """Returns cabinet file names referenced by an MSI."""
    script_path = str(ctx.path(ctx.attr.src_list_msi_cabs))
    msi_path = str(ctx.path(local_msi_path))

    args = [
        "powershell",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        script_path,
        "-MsiPath",
        msi_path,
    ]
    result = ctx.execute(args, quiet = True)
    if result.return_code != 0:
        fail("Listing cabs for {} failed (exit {})".format(local_msi_path, result.return_code))

    cabs = []
    for line in result.stdout.splitlines():
        item = line.strip()
        if item and item.lower().endswith(".cab"):
            cabs.append(item)
    return cabs


def _winsdk_repo_impl(ctx):
    """Implementation of the winsdk_repo rule."""
    packages = json.decode(ctx.attr.packages)
    cab_list = packages.get("cab", {})
    msi_list = packages.get("msi", [])

    if not msi_list:
        fail("No MSI payloads provided to winsdk_repo")

    downloaded_msi_paths = []
    for msi in msi_list:
        filename = msi.get("filename")
        if not filename:
            fail("Each MSI entry must contain 'filename'")

        ctx.report_progress("Downloading '{}'".format(filename))
        ctx.download(
            url = msi.get("url"),
            sha256 = msi.get("sha256"),
            output = "tmp/{}".format(filename),
        )
        downloaded_msi_paths.append(filename)

    required_cabs = {}
    for filename in downloaded_msi_paths:
        for cab_name in _get_cabs_from_msi(ctx, "tmp/{}".format(filename)):
            required_cabs[cab_name] = True

    cab_filenames = []
    for cab_payload in cab_list.values():
        cab_filename = cab_payload.get("filename")
        if cab_filename:
            cab_filenames.append(cab_filename)

    msi_filenames = []
    for msi in msi_list:
        msi_filename = msi.get("filename")
        if msi_filename:
            msi_filenames.append(msi_filename)

    for cab_name in required_cabs.keys():
        if cab_name not in cab_list:
            fail("Required cab '{}' not found in provided package payload list".format(cab_name))

        cab_payload = cab_list[cab_name]

        cab_filename = cab_payload.get("filename")
        ctx.report_progress("Downloading {}".format(cab_filename))
        ctx.download(
            url = cab_payload.get("url"),
            sha256 = cab_payload.get("sha256"),
            output = "tmp/{}".format(cab_filename),
        )

    extract_root = "tmp/extracted"
    for filename in downloaded_msi_paths:
        ctx.report_progress("Extracting '{}'".format(filename))
        extract_args = [
            "msiexec",
            "/a",
            str(ctx.path("tmp/{}".format(filename))).replace("/", "\\"),
            "/qn",
            "TARGETDIR={}".format(str(ctx.path(extract_root)).replace("/", "\\")),
        ]
        result = ctx.execute(extract_args, quiet = True)
        if result.return_code != 0:
            fail("Extracting {} failed (exit {code})".format(filename, code = result.return_code))


    extracted_dir = ctx.path("tmp/extracted/Windows Kits/10")
    for child in extracted_dir.readdir():
        child_name = str(child).replace("\\", "/").rsplit("/", 1)[1]
        ctx.execute([
            "cmd",
            "/c",
            "move",
            str(child).replace("/", "\\"),
            child_name,
        ])

    ctx.delete("tmp")

    ctx.template(
        "BUILD.bazel",
        ctx.attr.src_build,
        substitutions = {
            "{winsdk_version}": ctx.attr.winsdk_version,
        },
    )

winsdk_repo = repository_rule(
    implementation = _winsdk_repo_impl,
    attrs = {
        "winsdk_version": attr.string(mandatory = True),
        "packages": attr.string(doc = "JSON string containing cab and msi payload maps"),
        "targets": attr.string_list(doc = "Target architectures (currently unused)"),
        "src_list_msi_cabs": attr.label(default = Label("//tools:List-MsiCabs.ps1"), doc = "Label to List-MsiCabs.ps1"),
        "src_build": attr.label(default = Label("//overlays/winsdk:BUILD.root.tpl"), allow_single_file = True, doc = "Label to BUILD.root.tpl"),
    },
)
