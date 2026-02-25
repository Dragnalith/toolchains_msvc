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
