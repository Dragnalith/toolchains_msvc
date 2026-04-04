"""Shared helpers for repository rules and the module extension."""

def normalize_repository_os(os_name):
    os_lower = os_name.lower()
    if os_lower.startswith("windows"):
        return "windows"
    if os_lower == "darwin" or os_lower.startswith("mac os"):
        return "macos"
    if os_lower == "linux":
        return "linux"
    return os_lower

def normalize_repository_arch(arch):
    arch_lower = arch.lower()
    if arch_lower in ("amd64", "x86_64"):
        return "x86_64"
    if arch_lower in ("aarch64", "arm64"):
        return "aarch64"
    return arch_lower
