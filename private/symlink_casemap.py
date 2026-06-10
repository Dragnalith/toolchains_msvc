#!/usr/bin/env python3
"""Create case-symlink aliases for Windows SDK / MSVC CRT headers and libraries.

On case-sensitive filesystems (ext4, XFS, etc.), ``#include "DriverSpecs.h"``
fails when the on-disk file is ``driverspecs.h``.  This script scans header
files for ``#include`` directives, finds case-insensitive matches on disk, and
creates symlinks so that every referenced name resolves correctly.

Also creates lowercase symlinks for all files (e.g. ``Kernel32.Lib`` ->
``kernel32.lib``) so that lld-link can find libraries by their conventional
lowercase names.

Usage:
    symlink_casemap.py <root_dir>
"""

import os
import re
import sys


INCLUDE_RE = re.compile(r'^\s*#\s*include\s+["<]([^">]+)[">]')


def main(root):
    # Phase 1: build a map of (directory -> {lowercase_name: [actual_names]})
    dir_map = {}
    for dirpath, _dirnames, filenames in os.walk(root):
        lower_map = {}
        for f in filenames:
            low = f.lower()
            lower_map.setdefault(low, []).append(f)
        if lower_map:
            dir_map[dirpath] = lower_map

    include_dirs = set(dir_map.keys())

    # Phase 2: scan headers for #include references
    needed_symlinks = []
    seen = set()

    for dirpath in include_dirs:
        lower_map = dir_map[dirpath]
        all_files = []
        for names in lower_map.values():
            all_files.extend(names)

        for fname in all_files:
            if not fname.endswith(('.h', '.hpp', '.idl', '.inl', '.c', '.cpp')):
                continue
            fpath = os.path.join(dirpath, fname)
            try:
                with open(fpath, 'r', errors='ignore') as f:
                    for line in f:
                        m = INCLUDE_RE.match(line)
                        if not m:
                            continue
                        inc = m.group(1)
                        inc_base = os.path.basename(inc)
                        inc_lower = inc_base.lower()

                        for search_dir in include_dirs:
                            low_map = dir_map.get(search_dir, {})
                            if inc_lower in low_map:
                                actuals = low_map[inc_lower]
                                if inc_base not in actuals and (search_dir, inc_base) not in seen:
                                    target = actuals[0]
                                    needed_symlinks.append((search_dir, inc_base, target))
                                    seen.add((search_dir, inc_base))
                                break
            except (OSError, IOError):
                pass

    # Phase 3: create symlinks for #include mismatches
    created = 0
    for dirpath, link_name, target in needed_symlinks:
        link_path = os.path.join(dirpath, link_name)
        if os.path.exists(link_path):
            continue
        try:
            os.symlink(target, link_path)
            created += 1
        except OSError:
            pass

    # Phase 4: create lowercase symlinks for all files
    lower_created = 0
    for dirpath, lower_map in dir_map.items():
        for low, actuals in lower_map.items():
            for actual in actuals:
                if actual != low:
                    link_path = os.path.join(dirpath, low)
                    if not os.path.exists(link_path):
                        try:
                            os.symlink(actual, link_path)
                            lower_created += 1
                        except OSError:
                            pass

    print("Created {} include-alias symlinks and {} lowercase symlinks under {}".format(
        created, lower_created, root))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: {} <root_dir>".format(sys.argv[0]), file=sys.stderr)
        sys.exit(1)
    main(sys.argv[1])
