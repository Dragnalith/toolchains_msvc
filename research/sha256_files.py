#!/usr/bin/env python3
"""Print SHA256 hash for each given file. With multiple files, last line is Identical/Different."""

import hashlib
import sys


def sha256_file(path: str) -> str:
    """Compute SHA256 hex digest of file at path."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: sha256_files.py <file> [<file> ...]", file=sys.stderr)
        sys.exit(1)

    paths = sys.argv[1:]
    hashes: list[str] = []

    for path in paths:
        try:
            digest = sha256_file(path)
            hashes.append(digest)
            print(f"{digest}  {path}")
        except OSError as e:
            print(f"Error: {path}: {e}", file=sys.stderr)
            sys.exit(1)

    if len(hashes) > 1:
        if len(set(hashes)) == 1:
            print("Identical")
        else:
            print("Different")


if __name__ == "__main__":
    main()
