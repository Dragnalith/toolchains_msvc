"""Repository rule to fetch a pinned msiutil release binary for the repository host."""

load("//private:common.bzl", "normalize_repository_arch", "normalize_repository_os")

MSIUTIL_VERSION = "0.2.0"

MSIUTIL_BASE_URL = "https://github.com/Dragnalith/msiutil/releases/download/{version}".format(version = MSIUTIL_VERSION)

MSIUTIL_FILE_SHA256 = {
    "msiutil_darwin_amd64": "6a26269cdf21837cede4cde08c37ea82c2a7d44d2db0dcef48015a31bfffb365",
    "msiutil_darwin_arm64": "b74f81d2232a31274abda7852785a4e8b0c130857224001bbd005a1eff09b8be",
    "msiutil_linux_amd64": "82bbb33670b6b603da58e726d55d39b583fabea538e3ff3c982ac9189c333798",
    "msiutil_linux_arm64": "8f2583c44d10208b49ae894dbdb74089407404ae6f7288a1484d82b643b1acb7",
    "msiutil_windows_amd64.exe": "b5742ad3bbb20c74f2a1d61515ad98f859d5600e2b8022bd47976d7d49e5970b",
    "msiutil_windows_arm64.exe": "4df39db6957bff4987867b77254257897c8b3c41c91593166925e9bc4b7e0aaf",
}

def _msiutil_asset_key(exec_os, exec_cpu):
    if exec_os == "macos":
        if exec_cpu == "x86_64":
            return "msiutil_darwin_amd64"
        if exec_cpu == "aarch64":
            return "msiutil_darwin_arm64"
    if exec_os == "linux":
        if exec_cpu == "x86_64":
            return "msiutil_linux_amd64"
        if exec_cpu == "aarch64":
            return "msiutil_linux_arm64"
    if exec_os == "windows":
        if exec_cpu == "x86_64":
            return "msiutil_windows_amd64.exe"
        if exec_cpu == "aarch64":
            return "msiutil_windows_arm64.exe"
    return None

def _msiutil_repo_impl(ctx):
    exec_os = normalize_repository_os(ctx.os.name)
    exec_cpu = normalize_repository_arch(ctx.os.arch)
    asset = _msiutil_asset_key(exec_os, exec_cpu)
    if not asset:
        fail(
            "msiutil_repo: unsupported host OS/arch: {}, {} (normalized {}, {})".format(
                ctx.os.name,
                ctx.os.arch,
                exec_os,
                exec_cpu,
            ),
        )

    url = "{}/{}".format(MSIUTIL_BASE_URL, asset)
    sha256 = MSIUTIL_FILE_SHA256[asset]
    out_name = "msiutil.exe" if exec_os == "windows" else "msiutil"

    ctx.report_progress("Downloading msiutil {} for {}/{}".format(MSIUTIL_VERSION, exec_os, exec_cpu))
    ctx.download(
        url = url,
        output = out_name,
        sha256 = sha256,
        executable = True,
    )

    ctx.file(
        "BUILD.bazel",
        """\
exports_files(
    ["{out}"],
    visibility = ["//visibility:public"],
)
""".format(out = out_name),
    )

    return ctx.repo_metadata(reproducible = True)

msiutil_repo = repository_rule(
    implementation = _msiutil_repo_impl,
    attrs = {},
)
