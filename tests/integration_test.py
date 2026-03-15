import argparse
import hashlib
import itertools
import json
import platform
import subprocess
import sys
import threading
from pathlib import Path
from typing import NoReturn

DEFAULT_MSVC_VERSIONS = ["14.50", "14.44", "14.40", "14.33"]
DEFAULT_WINSDK_VERSIONS = ["26100", "22621", "19041"]
DEFAULT_CLANG_VERSIONS = ["22.1.0", "20.1.0"]
ALL_COMPILERS = ["msvc", "clang", "clang-cl"]


def get_default_hosts() -> list[str]:
    """Default hosts based on current architecture: x86,x64 on AMD64, arm64 on ARM64."""
    machine = platform.machine().upper()
    if machine in ("AMD64", "X86_64"):
        return ["x64", "x86"]
    if machine in ("ARM64", "AARCH64"):
        return ["arm64"]
    fatal_error(f"Unsupported architecture: {machine}")


def fatal_error(msg: str) -> NoReturn:
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


def compute_file_sha256(path: Path) -> str:
    """Compute SHA256 hash of file contents. File must exist."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def collect_project_hashes(workspace_dir: Path, _root: Path | None = None) -> dict[str, str]:
    """Collect relative_path -> sha256 for all files, skipping dirs whose name starts with 'bazel-'."""
    if _root is None:
        _root = workspace_dir
    result: dict[str, str] = {}
    for entry in _root.iterdir():
        if entry.name == "MODULE.bazel.lock":
            continue
        if entry.is_symlink():
            continue
        if entry.is_dir():
            if entry.name.startswith("bazel-"):
                continue
            result.update(collect_project_hashes(workspace_dir, entry))
        else:
            rel = entry.relative_to(workspace_dir)
            result[str(rel).replace("\\", "/")] = compute_file_sha256(entry)
    return result


def collect_build_artifact_hashes(workspace_dir: Path) -> dict[str, str]:
    """Collect path_key -> sha256 for bazel-bin artifacts: _objs/hello_world/main.obj, hello_world.exe, hello_world.pdb (if exists)."""
    result: dict[str, str] = {}
    bazel_bin = workspace_dir / "bazel-bin"
    if not bazel_bin.exists():
        return result
    artifacts = [
        "bazel-bin/dyn_hello/_objs/dyn_hello/dyn_hello.obj",
        "bazel-bin/dyn_hello/dyn_hello.lo.lib",
        "bazel-bin/dyn_hello/_objs/dyn_hello/dyn_hello.obj",
        "bazel-bin/hello_dll/hello_dll.dll",
        "bazel-bin/hello_dll/hello_dll.lib",
        "bazel-bin/hello_dll/hello_dll.pdb",
        "bazel-bin/hello_lib/_objs/hello_lib/current_version.obj",
        "bazel-bin/hello_lib/hello_lib.lib",
        "bazel-bin/hello_world/_objs/hello_world/main.obj",
        "bazel-bin/hello_world/hello_world.exe",
        "bazel-bin/hello_world/hello_world.pdb",
        "MODULE.bazel.lock",
    ]
    for rel in artifacts:
        p = workspace_dir / rel
        if not p.exists():
            fatal_error(f"Required artifact {rel} not found in {bazel_bin}")
        result[rel.replace("\\", "/")] = compute_file_sha256(p)
    return result


def run(cmd: list[str], cwd: Path, *, no_stderr_flush: bool = False) -> tuple[int, str]:
    """Run command and return (returncode, stdout).
    
    Unless no_stderr_flush is True, stderr is captured and streamed live.
    """
    stderr_dest = None if no_stderr_flush else subprocess.PIPE
    with subprocess.Popen(
        cmd,
        cwd=str(cwd),
        stdout=subprocess.PIPE,
        stderr=stderr_dest,
        text=True,
    ) as proc:
        stderr_thread: threading.Thread | None = None
        if not no_stderr_flush and proc.stderr is not None:
            stderr = proc.stderr

            def consume_stderr():
                for line in stderr:
                    print(line, end="", file=sys.stderr)
                    sys.stderr.flush()

            stderr_thread = threading.Thread(target=consume_stderr)
            stderr_thread.start()
        stdout = proc.stdout.read() if proc.stdout else ""
        proc.wait()
        if stderr_thread is not None:
            stderr_thread.join()
        return proc.returncode, stdout


def parse_aquery_to_actions(stdout: str) -> dict:
    """Parse aquery jsonproto stdout into { compile: { args, outputs }, link: { args, outputs } }."""
    data = json.loads(stdout.strip())
    artifacts_by_id = {artifact["id"]: artifact for artifact in data.get("artifacts", [])}
    path_fragments_by_id = {fragment["id"]: fragment for fragment in data.get("pathFragments", [])}

    def resolve_path_fragment(path_fragment_id: int) -> str | None:
        parts = []
        current_id = path_fragment_id
        while current_id is not None:
            fragment = path_fragments_by_id.get(current_id)
            if fragment is None:
                return None
            parts.append(fragment["label"])
            current_id = fragment.get("parentId")
        parts.reverse()
        return "/".join(parts)

    def resolve_outputs(action: dict) -> list[str]:
        output_paths = []
        for output_id in action.get("outputIds", []):
            artifact = artifacts_by_id.get(output_id)
            if artifact is None:
                continue
            path_fragment_id = artifact.get("pathFragmentId")
            if path_fragment_id is None:
                continue
            path = resolve_path_fragment(path_fragment_id)
            if path is not None:
                output_paths.append(path)

        # Keep compatibility with any aquery shape that provides paths directly.
        if output_paths:
            return output_paths
        return action.get("outputs", [])

    actions = data.get("actions", [])
    result: dict[str, dict] = {}
    for action in actions:
        mnemonic = action.get("mnemonic", "")
        if mnemonic == "CppCompile":
            result["compile"] = {
                "args": action.get("arguments", []),
                "outputs": resolve_outputs(action),
            }
        elif mnemonic == "CppLink":
            result["link"] = {
                "args": action.get("arguments", []),
                "outputs": resolve_outputs(action),
            }
    
    if "compile" not in result:
        fatal_error("CppCompile action not found in aquery output")
    if "link" not in result:
        fatal_error("CppLink action not found in aquery output")
    
    return result




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
        return ["x64", "x86"]
    return ["arm64"]


def get_compilers_to_test(compilers: list[str] | None) -> list[str]:
    """Return validated compiler drivers to test."""
    selected_compilers = compilers or ALL_COMPILERS
    for compiler in selected_compilers:
        check(compiler in ALL_COMPILERS, f"Invalid compiler: {compiler} (allowed: {', '.join(ALL_COMPILERS)})")
    return selected_compilers


def select_axis_values(values: list[str], mode: str) -> list[str]:
    """Select either the full axis or a single representative value."""
    if mode == "one":
        return values[:1]
    return values


def iter_host_target_pairs(hosts: list[str], targets: list[str]):
    """Yield valid host/target pairs from the requested axes."""
    for host in hosts:
        supported_targets = set(get_default_targets(host))
        for target in targets:
            if target in supported_targets:
                yield host, target


def iter_toolchain_cases(
    hosts: list[str],
    targets: list[str],
    msvc_versions: list[str],
    winsdk_versions: list[str],
    clang_versions: list[str],
    compilers: list[str] | None,
):
    """Yield valid toolchain combinations across the requested axes."""
    selected_compilers = get_compilers_to_test(compilers)
    for host, target in iter_host_target_pairs(hosts, targets):
        for msvc_version, winsdk_version in itertools.product(msvc_versions, winsdk_versions):
            if "msvc" in selected_compilers:
                yield {
                    "host": host,
                    "target": target,
                    "compiler": "msvc",
                    "compiler_version": msvc_version,
                    "msvc_version": msvc_version,
                    "winsdk_version": winsdk_version,
                }
            if host != "x86" and clang_versions:
                for clang_version in clang_versions:
                    if "clang" in selected_compilers:
                        yield {
                            "host": host,
                            "target": target,
                            "compiler": "clang",
                            "compiler_version": clang_version,
                            "msvc_version": msvc_version,
                            "winsdk_version": winsdk_version,
                        }
                    if "clang-cl" in selected_compilers:
                        yield {
                            "host": host,
                            "target": target,
                            "compiler": "clang-cl",
                            "compiler_version": clang_version,
                            "msvc_version": msvc_version,
                            "winsdk_version": winsdk_version,
                        }


def get_toolchain_flag_args(case: dict[str, str]) -> list[str]:
    """Build Bazel flag args for toolchain selection (--@msvc_toolchains//msvc=, etc.)."""
    msvc_version = case["msvc_version"]
    winsdk_version = case["winsdk_version"]
    compiler = case["compiler"]
    compiler_version = case["compiler_version"]
    compiler_flag_value = {"msvc": "msvc-cl", "clang": "clang", "clang-cl": "clang-cl"}[compiler]
    flags = [
        f"--@msvc_toolchains//msvc:msvc={msvc_version}",
        f"--@msvc_toolchains//winsdk:winsdk={winsdk_version}",
        f"--@msvc_toolchains//compiler:compiler={compiler_flag_value}",
    ]
    if compiler in ("clang", "clang-cl"):
        flags.append(f"--@msvc_toolchains//llvm:llvm={compiler_version}")
    return flags


def get_expected_compiler_binary(compiler: str) -> str:
    """Map a compiler driver to the executable name reported by the test."""
    return {
        "msvc": "cl.exe",
        "clang": "clang.exe",
        "clang-cl": "clang-cl.exe",
    }[compiler]


def run_test(
    workspace_dir: Path,
    test_label: str,
    current: int,
    total: int,
    *,
    show_progress: bool = False,
    no_stderr_flush: bool = False,
    host: str | None = None,
    target: str | None = None,
    toolchain_flags: list[str] | None = None,
    msvc_hosts_env: str | None = None,
    msvc_targets_env: str | None = None,
    expected_target: str,
    expected_compiler: str,
    expected_compiler_version: str,
    expected_msvc_version: str,
    expected_winsdk_version: str,
) -> None:
    """Run a single bazel test case and validate the output."""
    bazel_args = [] if show_progress else ['--noshow_progress']
    if host is not None:
        bazel_args.append(f"--host_platform=//:windows_{host}")
    if target is not None:
        bazel_args.append(f"--platforms=//:windows_{target}")
    if toolchain_flags is not None:
        bazel_args.extend(toolchain_flags)
    if msvc_hosts_env is not None:
        bazel_args.append(f"--repo_env=BAZEL_TOOLCHAINS_MSVC_HOSTS={msvc_hosts_env}")
    if msvc_targets_env is not None:
        bazel_args.append(f"--repo_env=BAZEL_TOOLCHAINS_MSVC_TARGETS={msvc_targets_env}")

    print(f"[{current}/{total}] TEST({test_label}): bazel run //:hello_world {' '.join(bazel_args)}")
    cmd = ["bazel", "run", "//:hello_world"] + bazel_args
    returncode, stdout = run(cmd, workspace_dir, no_stderr_flush=no_stderr_flush)
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
    compilers: list[str] | None = None,
    show_progress: bool = False,
    no_stderr_flush: bool = False,
) -> None:
    """Run all_hosts_all_targets tests."""
    compilers = get_compilers_to_test(compilers)

    print("DESCRIPTION: Test all toolchains in a workspace configured with every possible toolchain combination.")
    print(f"hosts: {', '.join(hosts)}")
    print(f"targets: {', '.join(targets)}")
    print(f"compilers: {', '.join(compilers)}")
    print(f"msvc-versions: {', '.join(msvc_versions)}")
    print(f"winsdk-versions: {', '.join(winsdk_versions)}")
    print(f"clang-versions: {', '.join(clang_versions)}")

    workspace_dir = script_dir / "all_hosts_all_targets"
    check(workspace_dir.is_dir(), f"Workspace not found: {workspace_dir}")

    tests = []
    for case in iter_toolchain_cases(hosts, targets, msvc_versions, winsdk_versions, clang_versions, compilers):
        tests.append(dict(
            host=case["host"],
            target=case["target"],
            toolchain_flags=get_toolchain_flag_args(case),
            expected_target=case["target"],
            expected_compiler=get_expected_compiler_binary(case["compiler"]),
            expected_compiler_version=case["compiler_version"],
            expected_msvc_version=case["msvc_version"] if case["compiler"] != "clang-cl" else "",
            expected_winsdk_version=case["winsdk_version"],
        ))
    total = len(tests)
    for current, kwargs in enumerate(tests, 1):
        run_test(workspace_dir, "all_hosts_all_targets", current, total, show_progress=show_progress, no_stderr_flush=no_stderr_flush, **kwargs)


def _compare_hashes(
    first: dict[str, str],
    second: dict[str, str],
    label: str,
) -> None:
    """Compare two path->sha256 dicts; fatal_error with all differences if any."""
    only_first = sorted(set(first) - set(second))
    only_second = sorted(set(second) - set(first))
    mismatches = [
        (key, first[key], second[key])
        for key in sorted(set(first) & set(second))
        if first[key] != second[key]
    ]
    if not (only_first or only_second or mismatches):
        return
    lines = [f"Differences in {label}:"]
    if only_first:
        lines.append(f"  only in first run: {only_first}")
    if only_second:
        lines.append(f"  only in second run: {only_second}")
    for key, h1, h2 in mismatches:
        lines.append(f"  SHA256 mismatch {key}: {h1} vs {h2}")
    fatal_error("\n".join(lines))


def run_reproducible_test(
    script_dir: Path,
    hosts: list[str],
    targets: list[str],
    msvc_versions: list[str],
    winsdk_versions: list[str],
    clang_versions: list[str] = [],
    compilers: list[str] | None = None,
    show_progress: bool = False,
    no_stderr_flush: bool = False,
) -> None:
    """Run reproducible tests: build once in reproducible_projectA, once in reproducible_projectB (copy), compare hashes."""
    compilers = get_compilers_to_test(compilers)

    print("DESCRIPTION: Reproducibility test: build //:hello_world in reproducible_projectA and in reproducible_projectB, compare SHA256.")
    print(f"hosts: {', '.join(hosts)}")
    print(f"targets: {', '.join(targets)}")
    print(f"compilers: {', '.join(compilers)}")
    print(f"msvc-versions: {', '.join(msvc_versions)}")
    print(f"winsdk-versions: {', '.join(winsdk_versions)}")
    print(f"clang-versions: {', '.join(clang_versions)}")

    workspace_A = script_dir / "reproducible_projectA"
    workspace_B = script_dir / "reproducible_projectB"
    check(workspace_A.is_dir(), f"Workspace not found: {workspace_A}")
    check(workspace_B.is_dir(), f"Workspace not found: {workspace_B}")

    tests = []
    for case in iter_toolchain_cases(hosts, targets, msvc_versions, winsdk_versions, clang_versions, compilers):
        tests.append(dict(
            host=case["host"],
            target=case["target"],
            toolchain_flags=get_toolchain_flag_args(case),
        ))
    total = len(tests)
    bazel_args_base = [] if show_progress else ["--noshow_progress"]

    for current, kwargs in enumerate(tests, 1):
        host = kwargs["host"]
        target = kwargs["target"]
        toolchain_flags = kwargs["toolchain_flags"]
        bazel_args = bazel_args_base + [
            f"--host_platform=//:windows_{host}",
            f"--platforms=//:windows_{target}",
            "--features=generate_debug_symbols",
        ] + toolchain_flags
        cmd_line = " ".join(["bazel", "build", "//hello_world"] + bazel_args)
        print(f"[{current}/{total}] REPRODUCIBLE_TEST: {cmd_line}")
        sys.stdout.flush()

        def build(workspace: Path) -> None:
            run(["bazel", "clean"], workspace, no_stderr_flush=no_stderr_flush)
            cmd = ["bazel", "build", "//hello_world"] + bazel_args
            returncode, _ = run(cmd, workspace, no_stderr_flush=no_stderr_flush)
            if returncode != 0:
                fatal_error(f"reproducible_test: bazel build failed in {workspace.name} (exit code {returncode})")

        project_hashes_1 = collect_project_hashes(workspace_A)
        
        build(workspace_A)
        artifact_hashes_1 = collect_build_artifact_hashes(workspace_A)
        
        build(workspace_A)
        artifact_hashes_2 = collect_build_artifact_hashes(workspace_A)
        _compare_hashes(artifact_hashes_1, artifact_hashes_2, "build artifacts (rebuild two times reproducible_projectA)")

        project_hashes_2 = collect_project_hashes(workspace_B)
        _compare_hashes(project_hashes_1, project_hashes_2, "project source files (reproducible_projectA vs reproducible_projectB)")
        build(workspace_B)
        artifact_hashes_3 = collect_build_artifact_hashes(workspace_B)

        _compare_hashes(artifact_hashes_1, artifact_hashes_3, "build artifacts (reproducible_projectA vs reproducible_projectB)")

        print("PASSED")
        sys.stdout.flush()


def run_one_host_one_target(
    script_dir: Path,
    hosts: list[str],
    targets: list[str],
    show_progress: bool = False,
    no_stderr_flush: bool = False,
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
        run_test(workspace_dir, "one_host_one_target", current, total, show_progress=show_progress, no_stderr_flush=no_stderr_flush, **kwargs)


def run_test_default(
    script_dir: Path,
    hosts: list[str],
    targets: list[str],
    clang_versions: list[str] = [],
    show_progress: bool = False,
    no_stderr_flush: bool = False,
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
        run_test(workspace_dir, "test_default", current, total, show_progress=show_progress, no_stderr_flush=no_stderr_flush, **kwargs)

class FeatureTest:
    def __init__(self, features_list: list[str], cl_c_args: list[str] = [], cl_link_args: list[str] = [], clang_c_args: list[str] = [], clang_link_args: list[str] = [], output_file: list[str] = []):
        self.features_list = features_list
        self.cl_c_args = cl_c_args
        self.cl_link_args = cl_link_args
        self.clang_c_args = clang_c_args
        self.clang_link_args = clang_link_args
        self.output_file = output_file
        
FEATURE_TESTS = [FeatureTest(
    features_list=[], 
    cl_c_args=["$/D_DEBUG", "/MD", "$/MDd", "$/MT", "$/MTd"],
    clang_c_args=["$-D_DEBUG""-fms-runtime-lib=dll", "$-fms-runtime-lib=dll_dbg", "$-fms-runtime-lib=static", "$-fms-runtime-lib=static_dbg"],
    cl_link_args=["/SUBSYSTEM:CONSOLE", "$/SUBSYSTEM:WINDOW"],
    clang_link_args=["/SUBSYSTEM:CONSOLE", "$/SUBSYSTEM:WINDOW"],
), FeatureTest(
    features_list=["debug_runtime", "static_runtime"], 
    cl_c_args=["/D_DEBUG","$/MD", "$/MDd", "$/MT", "/MTd"],
    clang_c_args=["-D_DEBUG", "$-fms-runtime-lib=dll", "$-fms-runtime-lib=dll_dbg", "$-fms-runtime-lib=static", "-fms-runtime-lib=static_dbg"],
), FeatureTest(
    features_list=["static_runtime"], 
    cl_c_args=["$/D_DEBUG","$/MD", "$/MDd", "/MT", "$/MTd"],
    clang_c_args=["$-D_DEBUG", "$-fms-runtime-lib=dll", "$-fms-runtime-lib=dll_dbg", "-fms-runtime-lib=static", "$-fms-runtime-lib=static_dbg"],
), FeatureTest(
    features_list=["debug_runtime"], 
    cl_c_args=["/D_DEBUG", "$/MD", "/MDd", "$/MT", "$/MTd"],
    clang_c_args=["-D_DEBUG", "$-fms-runtime-lib=dll", "-fms-runtime-lib=dll_dbg", "$-fms-runtime-lib=static", "$-fms-runtime-lib=static_dbg"],
), FeatureTest(
    features_list=["generate_debug_symbols"], 
    cl_c_args=["/Z7"],
    cl_link_args=["/DEBUG"],
    clang_c_args=["-gcodeview"],
    clang_link_args=["/DEBUG"],
    output_file=["hello_world.pdb"],
), FeatureTest(
    features_list=["treat_warnings_as_errors"], 
    cl_c_args=["/WX"],
    clang_c_args=["-Werror"],
), FeatureTest(
    features_list=["thinlto"],
    cl_c_args=["/GL"],
    clang_c_args=["-flto=thin"],
    clang_link_args=["/LTCG"],
    cl_link_args=["/LTCG"],
), FeatureTest(
    features_list=["fulllto"],
    cl_c_args=["/GL"],
    clang_c_args=["-flto"],
    clang_link_args=["/LTCG"],
    cl_link_args=["/LTCG"],
)]

def run_test_features(
    script_dir: Path,
    *,
    no_stderr_flush: bool = False,
) -> None:
    """Run aquery tests for each feature configuration and validate compile/link args."""
    workspace_dir = script_dir / "all_hosts_all_targets"
    check(workspace_dir.is_dir(), f"Workspace not found: {workspace_dir}")

    # Use first available versions from defaults
    msvc_version = DEFAULT_MSVC_VERSIONS[0]
    winsdk_version = DEFAULT_WINSDK_VERSIONS[0]
    clang_version = DEFAULT_CLANG_VERSIONS[0]
    
    # Determine host/target based on current architecture
    hosts = get_default_hosts()
    host = hosts[0]
    targets = get_default_targets(host)
    target = targets[0]
    
    # Define toolchains to test: msvc (cl.exe), clang, clang-cl
    toolchain_cases = [
        {"compiler": "msvc", "compiler_version": msvc_version, "msvc_version": msvc_version, "winsdk_version": winsdk_version, "host": host, "target": target},
        {"compiler": "clang", "compiler_version": clang_version, "msvc_version": msvc_version, "winsdk_version": winsdk_version, "host": host, "target": target},
        {"compiler": "clang-cl", "compiler_version": clang_version, "msvc_version": msvc_version, "winsdk_version": winsdk_version, "host": host, "target": target},
    ]
    toolchains = [(c["compiler"], c) for c in toolchain_cases]
    
    # Feature tests should not run on x86 host (clang toolchains not supported)
    check(host != "x86", "Feature tests should not use x86 host")
    
    total_tests = len(FEATURE_TESTS) * len(toolchains)
    test_counter = 0
    
    for toolchain_name, case in toolchains:
        toolchain_flags = get_toolchain_flag_args(case)
        for feature_test in FEATURE_TESTS:
            test_counter += 1
            features_str = ",".join(feature_test.features_list) if feature_test.features_list else "default"
            
            cmd = [
                "bazel", "aquery", 
                'mnemonic("CppLink|CppCompile",//:hello_world)', 
                "--output=jsonproto",
                f"--host_platform=//:windows_{host}",
                f"--platforms=//:windows_{target}",
            ] + toolchain_flags
            if feature_test.features_list:
                for feature in feature_test.features_list:
                    cmd.append(f"--features={feature}")
            
            print(f"[{test_counter}/{total_tests}] TEST_FEATURES({toolchain_name}, {features_str}): {' '.join(cmd)}")
            
            returncode, stdout = run(cmd, workspace_dir, no_stderr_flush=no_stderr_flush)
            if returncode != 0:
                fatal_error(f"bazel aquery failed (exit code {returncode})")
            
            actions = parse_aquery_to_actions(stdout)
            
            compile_args = actions["compile"]["args"]
            link_args = actions["link"]["args"]
            link_outputs = actions["link"]["outputs"]
            
            def validate_args(actual_args: list[str], expected_args: list[str], action_name: str) -> None:
                for expected in expected_args:
                    if expected.startswith("$"):
                        arg_to_check = expected[1:]
                        if arg_to_check in actual_args:
                            fatal_error(
                                f"FAILED: {action_name} should NOT contain '{arg_to_check}' for toolchain={toolchain_name}, features={features_str}\n"
                                f"Actual args: {actual_args}"
                            )
                    else:
                        if expected not in actual_args:
                            fatal_error(
                                f"FAILED: {action_name} should contain '{expected}' for toolchain={toolchain_name}, features={features_str}\n"
                                f"Actual args: {actual_args}"
                            )
            
            if toolchain_name in ("msvc", "clang-cl"):
                validate_args(compile_args, feature_test.cl_c_args, "CppCompile")
                validate_args(link_args, feature_test.cl_link_args, "CppLink")
            else:
                validate_args(compile_args, feature_test.clang_c_args, "CppCompile")
                validate_args(link_args, feature_test.clang_link_args, "CppLink")
            
            for expected_output in feature_test.output_file:
                found = any(output.lower().endswith(expected_output.lower()) for output in link_outputs)
                if not found:
                    fatal_error(
                        f"FAILED: Link outputs should end with '{expected_output}' for toolchain={toolchain_name}, features={features_str}\n"
                        f"Actual outputs: {link_outputs}"
                    )
            
            print("PASSED")
            sys.stdout.flush()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Integration tests for toolchains_msvc",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    show_progress_help = "Show Bazel progress (do not pass --noshow_progress to bazel)"

    matrix_parent = argparse.ArgumentParser(add_help=False)
    matrix_parent.add_argument("--hosts", type=parse_comma_list, default=None, help="Comma-separated host architectures (default: x86, x64 on AMD64, arm64 on ARM64)")
    matrix_parent.add_argument("--targets", type=parse_comma_list, default=None, help="Comma-separated target architectures (default: x86, x64 for x64/x86 host, arm64 for arm64 host)")
    matrix_parent.add_argument("--compilers", type=parse_comma_list, default=None, help="Comma-separated compiler drivers to test: msvc, clang, clang-cl (default: all). Clang/clang-cl only run when --clang_versions is non-empty.")
    matrix_parent.add_argument("--msvc_versions", type=parse_comma_list, default=DEFAULT_MSVC_VERSIONS, help="Comma-separated MSVC versions (default: 14.33, 14.40, 14.44, 14.50)")
    matrix_parent.add_argument("--winsdk_versions", type=parse_comma_list, default=DEFAULT_WINSDK_VERSIONS, help="Comma-separated Windows SDK versions (default: 19041, 22621, 26100)")
    matrix_parent.add_argument("--clang_versions", type=parse_comma_list, default=DEFAULT_CLANG_VERSIONS, help="Comma-separated Clang/LLVM versions to also test; if empty only msvc is tested (default: 20.1.0, 22.1.0)")
    matrix_mode_group = matrix_parent.add_mutually_exclusive_group()
    matrix_mode_group.add_argument("--all", dest="axis_mode", action="store_const", const="all", default="all", help="Run the full valid cross-product across the requested axes")
    matrix_mode_group.add_argument("--one", dest="axis_mode", action="store_const", const="one", help="Run one value per version/architecture axis")
    matrix_parent.add_argument("--show-progress", action="store_true", dest="show_progress", help=show_progress_help)
    matrix_parent.add_argument("--no-stderr-flush", action="store_true", dest="no_stderr_flush", help="Do not capture or flush stderr; let it go to the terminal")

    # all_hosts_all_targets command
    all_hosts_all_targets_parser = subparsers.add_parser("all_hosts_all_targets", parents=[matrix_parent], help="Test all toolchain combinations")

    # reproducible_test command (same args as all_hosts_all_targets)
    reproducible_parser = subparsers.add_parser("reproducible_test", parents=[matrix_parent], help="Two clean builds of //:hello_world, compare SHA256 of project and artifacts")

    # one_host_one_target command
    one_host_parser = subparsers.add_parser("one_host_one_target", help="Test workspace with single host and target (fixed 14.44/26100)")
    one_host_parser.add_argument("--hosts", type=parse_comma_list, default=None, help="Comma-separated host architectures (default: x86, x64 on AMD64, arm64 on ARM64)")
    one_host_parser.add_argument("--targets", type=parse_comma_list, default=None, help="Comma-separated target architectures (default: x86, x64 for x64/x86 host, arm64 for arm64 host)")
    one_host_parser.add_argument("--show-progress", action="store_true", dest="show_progress", help=show_progress_help)
    one_host_parser.add_argument("--no-stderr-flush", action="store_true", dest="no_stderr_flush", help="Do not capture or flush stderr; let it go to the terminal")

    # test_default command
    test_default_parser = subparsers.add_parser("test_default", help="Test default toolchain configuration")
    test_default_parser.add_argument("--hosts", type=parse_comma_list, default=None, help="Comma-separated host architectures (default: x86, x64 on AMD64, arm64 on ARM64)")
    test_default_parser.add_argument("--targets", type=parse_comma_list, default=None, help="Comma-separated target architectures (default: x86, x64 for x64/x86 host, arm64 for arm64 host)")
    test_default_parser.add_argument("--clang_versions", type=parse_comma_list, default=DEFAULT_CLANG_VERSIONS, help="Comma-separated Clang/LLVM versions to also test; if empty only msvc is tested (default: 20.1.0, 22.1.0)")
    test_default_parser.add_argument("--show-progress", action="store_true", dest="show_progress", help=show_progress_help)
    test_default_parser.add_argument("--no-stderr-flush", action="store_true", dest="no_stderr_flush", help="Do not capture or flush stderr; let it go to the terminal")

    # test_features command
    test_features_parser = subparsers.add_parser("test_features", help="Run aquery on //:hello_world and output CppCompile/CppLink args and outputs as JSON")
    test_features_parser.add_argument("--no-stderr-flush", action="store_true", dest="no_stderr_flush", help="Do not capture or flush stderr; let it go to the terminal")

    args = parser.parse_args()
    script_dir = Path(__file__).resolve().parent

    hosts = getattr(args, "hosts", None) or get_default_hosts()
    for h in hosts:
        check(h in ("x64", "x86", "arm64"), f"Invalid host: {h}")
    targets = getattr(args, "targets", None) or sorted(set(t for h in hosts for t in get_default_targets(h)))
    for t in targets:
        check(t in ("x64", "x86", "arm64"), f"Invalid target: {t}")

    if args.command == "all_hosts_all_targets":
        hosts = select_axis_values(hosts, args.axis_mode)
        targets = select_axis_values(targets, args.axis_mode)
        args.msvc_versions = select_axis_values(args.msvc_versions, args.axis_mode)
        args.winsdk_versions = select_axis_values(args.winsdk_versions, args.axis_mode)
        args.clang_versions = select_axis_values(args.clang_versions, args.axis_mode)
        run_all_hosts_all_targets(script_dir, hosts, targets, args.msvc_versions, args.winsdk_versions, args.clang_versions, compilers=getattr(args, "compilers", None), show_progress=args.show_progress, no_stderr_flush=args.no_stderr_flush)
    elif args.command == "reproducible_test":
        hosts = select_axis_values(hosts, args.axis_mode)
        targets = select_axis_values(targets, args.axis_mode)
        args.msvc_versions = select_axis_values(args.msvc_versions, args.axis_mode)
        args.winsdk_versions = select_axis_values(args.winsdk_versions, args.axis_mode)
        args.clang_versions = select_axis_values(args.clang_versions, args.axis_mode)
        run_reproducible_test(script_dir, hosts, targets, args.msvc_versions, args.winsdk_versions, args.clang_versions, compilers=getattr(args, "compilers", None), show_progress=args.show_progress, no_stderr_flush=args.no_stderr_flush)
    elif args.command == "one_host_one_target":
        run_one_host_one_target(script_dir, hosts, targets, show_progress=args.show_progress, no_stderr_flush=args.no_stderr_flush)
    elif args.command == "test_default":
        run_test_default(script_dir, hosts, targets, args.clang_versions, show_progress=args.show_progress, no_stderr_flush=args.no_stderr_flush)
    elif args.command == "test_features":
        run_test_features(script_dir, no_stderr_flush=args.no_stderr_flush)


if __name__ == "__main__":
    main()
