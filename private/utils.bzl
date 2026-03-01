"""Utility functions for MSVC architecture conversion."""

def convert_msvc_arch_to_bazel_arch(arch):
    """Convert MSVC arch to Bazel cpu.

    Args:
      arch: MSVC architecture string (e.g., "x64", "x86", "arm64").

    Returns:
      The corresponding Bazel cpu string (e.g., "x86_64", "x86_32", "aarch64").
    """
    if arch == "x64":
        return "x86_64"
    elif arch == "x86":
        return "x86_32"
    elif arch == "arm64":
        return "aarch64"
    else:
        fail("Unsupported msvc arch: {}".format(arch))

def convert_bazel_arch_to_msvc_arch(arch):
    """Convert Bazel cpu to MSVC arch.

    Args:
      arch: Bazel cpu string (e.g., "x86_64", "x86_32", "aarch64").

    Returns:
      The corresponding MSVC architecture string (e.g., "x64", "x86", "arm64").
    """
    if arch == "x86_64":
        return "x64"
    elif arch in ["aarch64", "arm64"]:
        return "arm64"
    elif arch == "x86_32":
        return "x86"
    else:
        fail("Unsupported @platforms//cpu:{} cpu".format(arch))

def msvc_version_to_cl_internal_version(msvc_version):
    """Compute the clang -fms-compatibility-version from an MSVC version string.

    MSVC toolset versions follow the pattern 14.x, while the corresponding
    _MSC_VER major is 19.x (i.e. major + 5). For example, 14.45 -> 19.45.

    Args:
      msvc_version: MSVC toolset version string (e.g. "14.45").

    Returns:
      The compatibility version string (e.g. "19.45").
    """
    parts = msvc_version.split(".")
    major = int(parts[0]) + 5
    return "{}.{}".format(major, parts[1])

def convert_msvc_arch_to_clang_target(arch):
    """Convert MSVC arch to Clang target triple.

    Args:
      arch: MSVC architecture string (e.g., "x64", "x86", "arm64").

    Returns:
      The corresponding Clang target triple.
    """
    if arch == "x64":
        return "x86_64-pc-windows-msvc"
    elif arch == "x86":
        return "i686-pc-windows-msvc"
    elif arch == "arm64":
        return "aarch64-pc-windows-msvc"
    else:
        fail("Unsupported msvc arch: {}".format(arch))
