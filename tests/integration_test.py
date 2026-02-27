import argparse
import itertools
import json
import platform
import subprocess
import sys
from pathlib import Path

DEFAULT_MSVC_VERSIONS = ["14.33", "14.40", "14.44"]
DEFAULT_WINSDK_VERSIONS = ["19041", "22621", "26100"]


def get_default_hosts() -> list[str]:
    """Default hosts based on current architecture: x86,x64 on AMD64, arm64 on ARM64."""
    machine = platform.machine().upper()
    if machine in ("AMD64", "X86_64"):
        return ["x86", "x64"]
    if machine in ("ARM64", "AARCH64"):
        return ["arm64"]
    fatal_error(f"Unsupported architecture: {machine}")


def fatal_error(msg: str) -> None:
    """Print error message and exit with failure."""
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def check(condition: bool, msg: str) -> None:
    """Exit with fatal error if condition is False."""
    if not condition:
        fatal_error(msg)


def parse_comma_list(value: str) -> list[str]:
    """Parse comma-separated string into list of stripped values."""
    return [v.strip() for v in value.split(",") if v.strip()]


def run_bazel(args: list[str], cwd: Path) -> tuple[int, str, str]:
    """Run bazel with given args. Returns (returncode, stdout, stderr)."""
    cmd = ["bazel", "run", "//:hello_world"] + args
    result = subprocess.run(
        cmd,
        cwd=str(cwd),
        stdout=subprocess.PIPE,
        stderr=None,
        text=True,
    )
    return result.returncode, result.stdout, result.stderr or ""


def validate_output(
    stdout: str,
    expected_target: str,
    expected_compiler: str,
    expected_winsdk_version: str,
) -> bool:
    """Validate that stdout contains expected JSON config. Returns True if valid."""
    try:
        data = json.loads(stdout.strip())
    except json.JSONDecodeError:
        return False
    return (
        data.get("target") == expected_target
        and data.get("compiler") == expected_compiler
        and data.get("winsdk_version") == expected_winsdk_version
    )


def _format_failure_output(stdout: str, stderr: str) -> str:
    """Format stdout and stderr for failure messages."""
    parts = []
    if stdout:
        parts.append(f"stdout:\n{stdout}")
    if stderr:
        parts.append(f"stderr:\n{stderr}")
    return "\n".join(parts) if parts else "(no output)"


def get_default_targets(host: str) -> list[str]:
    """Get default targets for a given host."""
    if host in ("x64", "x86"):
        return ["x86", "x64"]
    return ["arm64"]


def run_all_host_all_target(
    script_dir: Path,
    hosts: list[str],
    targets: list[str],
    msvc_versions: list[str],
    winsdk_versions: list[str],
) -> None:
    """Run all_host_all_target tests."""
    print("DESCRIPTION: Test all toolchains in a workspace configured with every possible toolchain combination.")
    print(f"hosts: {', '.join(hosts)}")
    print(f"targets: {', '.join(targets)}")
    print(f"msvc-versions: {', '.join(msvc_versions)}")
    print(f"winsdk-versions: {', '.join(winsdk_versions)}")

    workspace_dir = script_dir / "all_hosts_all_targets"
    check(workspace_dir.is_dir(), f"Workspace not found: {workspace_dir}")

    for host in hosts:
        host_targets = [t for t in targets if t in get_default_targets(host)]
        for target, msvc, winsdk in itertools.product(host_targets, msvc_versions, winsdk_versions):
            toolchain_name = f"msvc_{msvc}_winsdk{winsdk}_host{host}_target{target}"
            bazel_args = [
                f"--host_platform=//:windows_{host}",
                f"--platforms=//:windows_{target}",
                f"--extra_toolchains=@msvc_toolchains//:{toolchain_name}",
            ]

            test_cmd = "bazel run //:hello_world " + " ".join(bazel_args)
            print(f"TEST: {test_cmd}")

            returncode, stdout, stderr = run_bazel(bazel_args, workspace_dir)
            print(stdout, end="" if stdout.endswith("\n") else "\n")

            if returncode != 0:
                fatal_error(
                    f"FAILED: bazel run failed (exit code {returncode})\n"
                    f"Expected: JSON with target={target}, compiler=cl.exe, winsdk_version={winsdk}\n"
                    f"{_format_failure_output(stdout, stderr)}"
                )

            if not validate_output(
                stdout,
                expected_target=target,
                expected_compiler="cl.exe",
                expected_winsdk_version=winsdk,
            ):
                fatal_error(
                    f"FAILED: Output validation failed\n"
                    f"Expected: target={target}, compiler=cl.exe, winsdk_version={winsdk}\n"
                    f"{_format_failure_output(stdout, stderr)}"
                )

            print("PASSED")


def run_one_host_one_target(
    script_dir: Path,
    hosts: list[str],
    targets: list[str],
) -> None:
    """Run one_host_one_target tests (fixed 14.44/26100)."""
    print("DESCRIPTION: Test toolchains in a workspace configured with only one host and one target.")
    print(f"hosts: {', '.join(hosts)}")
    print(f"targets: {', '.join(targets)}")
    print("msvc-versions: 14.44")
    print("winsdk-versions: 26100")

    workspace_dir = script_dir / "one_host_one_target"
    check(workspace_dir.is_dir(), f"Workspace not found: {workspace_dir}")

    winsdk = "26100"

    for host in hosts:
        host_targets = [t for t in targets if t in get_default_targets(host)]
        for target in host_targets:
            bazel_args = [
                f"--host_platform=//:windows_{host}",
                f"--platforms=//:windows_{target}",
                "--repo_env=BAZEL_TOOLCHAINS_MSVC_HOSTS=" + host,
                "--repo_env=BAZEL_TOOLCHAINS_MSVC_TARGETS=" + target,
            ]

            test_cmd = "bazel run //:hello_world " + " ".join(bazel_args)
            print(f"TEST: {test_cmd}")

            returncode, stdout, stderr = run_bazel(bazel_args, workspace_dir)
            print(stdout, end="" if stdout.endswith("\n") else "\n")

            if returncode != 0:
                fatal_error(
                    f"FAILED: bazel run failed (exit code {returncode})\n"
                    f"Expected: JSON with target={target}, compiler=cl.exe, winsdk_version={winsdk}\n"
                    f"{_format_failure_output(stdout, stderr)}"
                )

            if not validate_output(
                stdout,
                expected_target=target,
                expected_compiler="cl.exe",
                expected_winsdk_version=winsdk,
            ):
                fatal_error(
                    f"FAILED: Output validation failed\n"
                    f"Expected: target={target}, compiler=cl.exe, winsdk_version={winsdk}\n"
                    f"{_format_failure_output(stdout, stderr)}"
                )

            print("PASSED")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Integration tests for toolchains_msvc",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # all_host_all_target command
    all_host_all_target_parser = subparsers.add_parser("all_host_all_target", help="Test all toolchain combinations")
    all_host_all_target_parser.add_argument(
        "--hosts",
        default=None,
        help="Comma-separated host architectures (default: x86,x64 on AMD64, arm64 on ARM64)",
    )
    all_host_all_target_parser.add_argument(
        "--targets",
        default=None,
        help="Comma-separated target architectures (default: x86,x64 for x64/x86 host, arm64 for arm64 host)",
    )
    all_host_all_target_parser.add_argument(
        "--msvc_versions",
        default=None,
        help="Comma-separated MSVC versions (default: 14.29,14.33,14.40,14.44)",
    )
    all_host_all_target_parser.add_argument(
        "--winsdk_versions",
        default=None,
        help="Comma-separated Windows SDK versions (default: 19041,22621,26100)",
    )

    # one_host_one_target command
    one_host_parser = subparsers.add_parser(
        "one_host_one_target",
        help="Test workspace with single host and target (fixed 14.44/26100)",
    )
    one_host_parser.add_argument(
        "--hosts",
        default=None,
        help="Comma-separated host architectures (default: x86,x64 on AMD64, arm64 on ARM64)",
    )
    one_host_parser.add_argument(
        "--targets",
        default=None,
        help="Comma-separated target architectures (default: x86,x64 for x64/x86 host, arm64 for arm64 host)",
    )

    args = parser.parse_args()
    script_dir = Path(__file__).resolve().parent

    if args.hosts:
        hosts = parse_comma_list(args.hosts)
        for h in hosts:
            check(h in ("x64", "x86", "arm64"), f"Invalid host: {h}")
    else:
        hosts = get_default_hosts()

    if args.targets:
        targets = parse_comma_list(args.targets)
        for t in targets:
            check(t in ("x64", "x86", "arm64"), f"Invalid target: {t}")
    else:
        targets = sorted(set(t for h in hosts for t in get_default_targets(h)))

    if args.command == "all_host_all_target":
        msvc_versions = (
            parse_comma_list(args.msvc_versions) if args.msvc_versions else DEFAULT_MSVC_VERSIONS
        )
        winsdk_versions = (
            parse_comma_list(args.winsdk_versions) if args.winsdk_versions else DEFAULT_WINSDK_VERSIONS
        )
        run_all_host_all_target(script_dir, hosts, targets, msvc_versions, winsdk_versions)
    else:
        run_one_host_one_target(script_dir, hosts, targets)


if __name__ == "__main__":
    main()
