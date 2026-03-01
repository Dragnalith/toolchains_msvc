#!/usr/bin/env python3
"""Analyze exec.json - extract input paths from commands."""

import argparse
import json
import sys
from pathlib import Path


KINDS = ("bin", "header", "lib", "pdb", "idl", "other")

KIND_EXTENSIONS = {
    "bin": (".exe", ".dll"),
    "header": (".h", ".hh", ".hpp", ".hxx"),
    "lib": (".lib",),
    "pdb": (".pdb",),
    "idl": (".idl",),
    "other": (),
}


def _get_kind(path: str) -> str:
    """Return kind of file from path: bin, header, lib, pdb, idl, or other."""
    p = Path(path)
    ext = p.suffix.lower()
    if ext:
        for kind, exts in KIND_EXTENSIONS.items():
            if kind == "other":
                continue
            if ext in exts:
                return kind
    elif any(part.lower() in ("include", "includes") for part in p.parts):
        return "header"
    return "other"


def _filter_by_kind(inputs: list, kind: str | None) -> list:
    """Filter inputs by kind. If kind is None, return all."""
    if kind is None:
        return inputs
    return [inp for inp in inputs if _get_kind(inp.get("path", "")) == kind]


def _load_command(exec_json: Path, index: int) -> dict:
    """Parse and return the Nth JSON object from the file (0-based index)."""
    with open(exec_json, encoding="utf-8") as f:
        content = f.read()
    decoder = json.JSONDecoder()
    for i in range(index + 1):
        cmd, idx = decoder.raw_decode(content)
        if i < index:
            content = content[idx:].lstrip()
            if not content:
                raise IndexError(f"Command index {index} out of range (only {i + 1} commands)")
    return cmd


def _load_all_commands(exec_json: Path) -> list[dict]:
    """Parse and return all JSON objects from the file."""
    with open(exec_json, encoding="utf-8") as f:
        content = f.read()
    decoder = json.JSONDecoder()
    commands = []
    while content.strip():
        cmd, idx = decoder.raw_decode(content)
        commands.append(cmd)
        content = content[idx:].lstrip()
    return commands


def cmd_list(args: argparse.Namespace) -> int:
    """List all input paths from the selected command."""
    exec_json = args.file
    if not exec_json.exists():
        print(f"Error: {exec_json} not found", file=sys.stderr)
        return 1

    try:
        cmd = _load_command(exec_json, args.cmd)
    except IndexError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    all_inputs = cmd.get("inputs", [])
    kinds = KINDS if args.all else [args.kind]
    if not args.all and args.kind is None:
        kinds = [None]

    for kind in kinds:
        inputs = _filter_by_kind(all_inputs, kind)
        if args.all:
            print(f"{kind}:")
        for inp in inputs:
            path = inp.get("path", "")
            if path:
                print(path)
        if args.all and inputs:
            print()
    return 0


def cmd_size(args: argparse.Namespace) -> int:
    """Sum the size of all input files from digest.sizeBytes."""
    exec_json = args.file
    if not exec_json.exists():
        print(f"Error: {exec_json} not found", file=sys.stderr)
        return 1

    try:
        cmd = _load_command(exec_json, args.cmd)
    except IndexError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    all_inputs = cmd.get("inputs", [])
    kinds = KINDS if args.all else [args.kind]
    if not args.all and args.kind is None:
        kinds = [None]

    for kind in kinds:
        inputs = _filter_by_kind(all_inputs, kind)
        total = sum(int(inp.get("digest", {}).get("sizeBytes", "0")) for inp in inputs)
        mb = total / (1024**2)
        size_str = f"{mb:.2f} MB ({total})"
        if args.all:
            print(f"{kind}: {size_str}")
        else:
            print(size_str)
    return 0


def cmd_list_cmd(args: argparse.Namespace) -> int:
    """List all commands with index and commandArgs."""
    exec_json = args.file
    if not exec_json.exists():
        print(f"Error: {exec_json} not found", file=sys.stderr)
        return 1

    commands = _load_all_commands(exec_json)
    for i, cmd in enumerate(commands):
        args_list = cmd.get("commandArgs", [])
        line = " ".join(str(a) for a in args_list)
        print(f"{i}: {line}")
    return 0


def cmd_count(args: argparse.Namespace) -> int:
    """Count the number of input files (filtered by --kind if specified)."""
    exec_json = args.file
    if not exec_json.exists():
        print(f"Error: {exec_json} not found", file=sys.stderr)
        return 1

    try:
        cmd = _load_command(exec_json, args.cmd)
    except IndexError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    all_inputs = cmd.get("inputs", [])
    kinds = KINDS if args.all else [args.kind]
    if not args.all and args.kind is None:
        kinds = [None]

    for kind in kinds:
        inputs = _filter_by_kind(all_inputs, kind)
        if args.all:
            print(f"{kind}: {len(inputs)}")
        else:
            print(len(inputs))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Analyze exec.json from Bazel execution logs.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    common_parser = argparse.ArgumentParser(add_help=False)
    common_parser.add_argument("file", type=Path, help="Path to exec.json")
    common_parser.add_argument("--cmd", type=int, default=0, help="Command index (default: 0)")
    kind_group = common_parser.add_mutually_exclusive_group()
    kind_group.add_argument("--kind", choices=KINDS, help="Filter inputs by file kind")
    kind_group.add_argument("--all", action="store_true", help="Run for all kinds (bin, header, lib, other)")

    list_parser = subparsers.add_parser("list", parents=[common_parser], help="List all input paths from the selected command")
    list_parser.set_defaults(func=cmd_list)

    size_parser = subparsers.add_parser("size", parents=[common_parser], help="Sum size of all input files (digest.sizeBytes)")
    size_parser.set_defaults(func=cmd_size)

    count_parser = subparsers.add_parser("count", parents=[common_parser], help="Count the number of input files")
    count_parser.set_defaults(func=cmd_count)

    list_cmd_parser = subparsers.add_parser("list-cmd", help="List all commands with index and commandArgs")
    list_cmd_parser.add_argument("file", type=Path, help="Path to exec.json")
    list_cmd_parser.set_defaults(func=cmd_list_cmd)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
