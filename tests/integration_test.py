import argparse
import json
import platform
import subprocess
import sys
from pathlib import Path

DEFAULT_MSVC_VERSIONS = ["14.33", "14.40", "14.44", "14.50"]
DEFAULT_WINSDK_VERSIONS = ["19041", "22621", "26100"]
DEFAULT_CLANG_VERSIONS = ["20.1.0", "22.1.0"]


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


def run_bazel(args: list[str], cwd: Path) -> tuple[int, str]:
    """Run bazel with given args. Returns (returncode, stdout).

    Stderr is streamed live to stdout.
    """
    cmd = ["bazel", "run", "//:hello_world"] + args
    with subprocess.Popen(
        cmd,
        cwd=str(cwd),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    ) as proc:
        for line in proc.stderr:
            print(line, end="")
            sys.stdout.flush()
        stdout = proc.stdout.read()
        proc.wait()
        return proc.returncode, stdout


def validate_output(
    stdout: str,
    expected_target: str,
    expected_compiler: str,
    expected_winsdk_version: str,
    expected_compiler_version: str = "",
    expected_msvc_version: str = "",
) -> bool:
    """Validate that stdout contains expected JSON config. Returns True if valid."""
    try:
        data = json.loads(stdout.strip())
    except json.JSONDecodeError:
        return False
    is_valid = (
        data.get("target") == expected_target
        and data.get("compiler") == expected_compiler
        and data.get("winsdk_version") == expected_winsdk_version
    )
    if expected_compiler_version:
        is_valid = is_valid and data.get("compiler_version") == expected_compiler_version
    if expected_msvc_version:
        is_valid = is_valid and data.get("msvc_version") == expected_msvc_version
    return is_valid



def get_default_targets(host: str) -> list[str]:
    """Get default targets for a given host."""
    if host in ("x64", "x86"):
        return ["x86", "x64"]
    return ["arm64"]


def run_test(
    workspace_dir: Path,
    test_label: str,
    current: int,
    total: int,
    *,
    host: str | None = None,
    target: str | None = None,
    extra_toolchains: str | None = None,
    msvc_hosts_env: str | None = None,
    msvc_targets_env: str | None = None,
    expected_target: str,
    expected_compiler: str,
    expected_compiler_version: str,
    expected_msvc_version: str,
    expected_winsdk_version: str,
) -> None:
    """Run a single bazel test case and validate the output."""
    bazel_args = ['--noshow_progress']
    if host is not None:
        bazel_args.append(f"--host_platform=//:windows_{host}")
    if target is not None:
        bazel_args.append(f"--platforms=//:windows_{target}")
    if extra_toolchains is not None:
        bazel_args.append(f"--extra_toolchains=@msvc_toolchains//:{extra_toolchains}")
    if msvc_hosts_env is not None:
        bazel_args.append(f"--repo_env=BAZEL_TOOLCHAINS_MSVC_HOSTS={msvc_hosts_env}")
    if msvc_targets_env is not None:
        bazel_args.append(f"--repo_env=BAZEL_TOOLCHAINS_MSVC_TARGETS={msvc_targets_env}")

    print(f"[{current}/{total}] TEST({test_label}): bazel run //:hello_world {' '.join(bazel_args)}")
    returncode, stdout = run_bazel(bazel_args, workspace_dir)
    print(stdout, end="" if stdout.endswith("\n") else "\n")

    if returncode != 0:
        fatal_error(
            f"FAILED: bazel run failed (exit code {returncode})\n"
            f"Expected: JSON with target={expected_target}, compiler={expected_compiler}, winsdk_version={expected_winsdk_version}"
        )
    if not validate_output(
        stdout,
        expected_target=expected_target,
        expected_compiler=expected_compiler,
        expected_winsdk_version=expected_winsdk_version,
        expected_compiler_version=expected_compiler_version,
        expected_msvc_version=expected_msvc_version,
    ):
        fatal_error(
            f"FAILED: Output validation failed\n"
            f"Expected: target={expected_target}, compiler={expected_compiler}, compiler_version={expected_compiler_version}, msvc_version={expected_msvc_version}, winsdk_version={expected_winsdk_version}"
        )
    print("PASSED")
    sys.stdout.flush()


def run_all_hosts_all_targets(
    script_dir: Path,
    hosts: list[str],
    targets: list[str],
    msvc_versions: list[str],
    winsdk_versions: list[str],
    clang_versions: list[str] = [],
) -> None:
    """Run all_hosts_all_targets tests."""
    print("DESCRIPTION: Test all toolchains in a workspace configured with every possible toolchain combination.")
    print(f"hosts: {', '.join(hosts)}")
    print(f"targets: {', '.join(targets)}")
    print(f"msvc-versions: {', '.join(msvc_versions)}")
    print(f"winsdk-versions: {', '.join(winsdk_versions)}")
    print(f"clang-versions: {', '.join(clang_versions)}")

    workspace_dir = script_dir / "all_hosts_all_targets"
    check(workspace_dir.is_dir(), f"Workspace not found: {workspace_dir}")

    tests = []
    for host in hosts:
        host_targets = [t for t in targets if t in get_default_targets(host)]
        for target in host_targets:
            for msvc in msvc_versions:
                for winsdk in winsdk_versions:
                    tests.append(dict(
                        host=host, target=target,
                        extra_toolchains=f"msvc{msvc}_winsdk{winsdk}_host{host}_target{target}",
                        expected_target=target, expected_compiler="cl.exe",
                        expected_compiler_version=msvc, expected_msvc_version=msvc,
                        expected_winsdk_version=winsdk,
                    ))
                    if host != "x86":
                        for clang_version in clang_versions:
                            tests.append(dict(
                                host=host, target=target,
                                extra_toolchains=f"clang{clang_version}_msvc{msvc}_winsdk{winsdk}_host{host}_target{target}",
                                expected_target=target, expected_compiler="clang.exe",
                                expected_compiler_version=clang_version, expected_msvc_version=msvc,
                                expected_winsdk_version=winsdk,
                            ))
                            tests.append(dict(
                                host=host, target=target,
                                extra_toolchains=f"clang-cl{clang_version}_msvc{msvc}_winsdk{winsdk}_host{host}_target{target}",
                                expected_target=target, expected_compiler="clang-cl.exe",
                                expected_compiler_version=clang_version, expected_msvc_version="",
                                expected_winsdk_version=winsdk,
                            ))
    total = len(tests)
    for current, kwargs in enumerate(tests, 1):
        run_test(workspace_dir, "all_hosts_all_targets", current, total, **kwargs)


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

    tests = []
    for host in hosts:
        host_targets = [t for t in targets if t in get_default_targets(host)]
        for target in host_targets:
            tests.append(dict(
                host=host, target=target,
                msvc_hosts_env=host, msvc_targets_env=target,
                expected_target=target, expected_compiler="cl.exe",
                expected_compiler_version="14.44", expected_msvc_version="14.44",
                expected_winsdk_version="26100",
            ))
    total = len(tests)
    for current, kwargs in enumerate(tests, 1):
        run_test(workspace_dir, "one_host_one_target", current, total, **kwargs)


def run_test_default(
    script_dir: Path,
    hosts: list[str],
    targets: list[str],
    clang_versions: list[str] = [],
) -> None:
    """Run test_default tests."""
    print("DESCRIPTION: Test default toolchain in all_hosts_all_targets workspace.")
    print(f"hosts: {', '.join(hosts)}")
    print(f"targets: {', '.join(targets)}")
    print(f"clang-versions: {', '.join(clang_versions)}")

    workspace_dir = script_dir / "all_hosts_all_targets"
    check(workspace_dir.is_dir(), f"Workspace not found: {workspace_dir}")

    tests = []
    for host in hosts:
        host_targets = [t for t in targets if t in get_default_targets(host)]
        for target in host_targets:
            tests.append(dict(
                host=host, target=target,
                expected_target=target, expected_compiler="cl.exe",
                expected_compiler_version="14.44", expected_msvc_version="14.44",
                expected_winsdk_version="26100",
            ))
    total = len(tests)
    for current, kwargs in enumerate(tests, 1):
        run_test(workspace_dir, "test_default", current, total, **kwargs)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Integration tests for toolchains_msvc",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # all_hosts_all_targets command
    all_hosts_all_targets_parser = subparsers.add_parser("all_hosts_all_targets", help="Test all toolchain combinations")
    all_hosts_all_targets_parser.add_argument("--hosts", type=parse_comma_list, default=None, help="Comma-separated host architectures (default: x86, x64 on AMD64, arm64 on ARM64)")
    all_hosts_all_targets_parser.add_argument("--targets", type=parse_comma_list, default=None, help="Comma-separated target architectures (default: x86, x64 for x64/x86 host, arm64 for arm64 host)")
    all_hosts_all_targets_parser.add_argument("--msvc_versions", type=parse_comma_list, default=DEFAULT_MSVC_VERSIONS, help="Comma-separated MSVC versions (default: 14.33, 14.40, 14.44, 14.50)")
    all_hosts_all_targets_parser.add_argument("--winsdk_versions", type=parse_comma_list, default=DEFAULT_WINSDK_VERSIONS, help="Comma-separated Windows SDK versions (default: 19041, 22621, 26100)")
    all_hosts_all_targets_parser.add_argument("--clang_versions", type=parse_comma_list, default=DEFAULT_CLANG_VERSIONS, help="Comma-separated Clang/LLVM versions to also test; if empty only msvc is tested (default: 20.1.0, 22.1.0)")

    # one_host_one_target command
    one_host_parser = subparsers.add_parser("one_host_one_target", help="Test workspace with single host and target (fixed 14.44/26100)")
    one_host_parser.add_argument("--hosts", type=parse_comma_list, default=None, help="Comma-separated host architectures (default: x86, x64 on AMD64, arm64 on ARM64)")
    one_host_parser.add_argument("--targets", type=parse_comma_list, default=None, help="Comma-separated target architectures (default: x86, x64 for x64/x86 host, arm64 for arm64 host)")

    # test_default command
    test_default_parser = subparsers.add_parser("test_default", help="Test default toolchain configuration")
    test_default_parser.add_argument("--hosts", type=parse_comma_list, default=None, help="Comma-separated host architectures (default: x86, x64 on AMD64, arm64 on ARM64)")
    test_default_parser.add_argument("--targets", type=parse_comma_list, default=None, help="Comma-separated target architectures (default: x86, x64 for x64/x86 host, arm64 for arm64 host)")
    test_default_parser.add_argument("--clang_versions", type=parse_comma_list, default=DEFAULT_CLANG_VERSIONS, help="Comma-separated Clang/LLVM versions to also test; if empty only msvc is tested (default: 20.1.0, 22.1.0)")

    args = parser.parse_args()
    script_dir = Path(__file__).resolve().parent

    hosts = args.hosts or get_default_hosts()
    for h in hosts:
        check(h in ("x64", "x86", "arm64"), f"Invalid host: {h}")

    targets = args.targets or sorted(set(t for h in hosts for t in get_default_targets(h)))
    for t in targets:
        check(t in ("x64", "x86", "arm64"), f"Invalid target: {t}")

    if args.command == "all_hosts_all_targets":
        run_all_hosts_all_targets(script_dir, hosts, targets, args.msvc_versions, args.winsdk_versions, args.clang_versions)
    elif args.command == "one_host_one_target":
        run_one_host_one_target(script_dir, hosts, targets)
    elif args.command == "test_default":
        run_test_default(script_dir, hosts, targets, args.clang_versions)


if __name__ == "__main__":
    main()
