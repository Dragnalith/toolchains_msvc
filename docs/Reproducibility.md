# Build Tool Hermeticity

Making build tools hermetic requires two things:

1. **Filter environment variables** — only allow tools to see the variables they need.
2. **Disable built-in search paths** — prevent tools from resolving paths outside the build.

In this setup, build tools run only with the `TMP`, `TEMP`, and `SYSTEMROOT` environment variables.

## Per-Tool Behavior

- **cl.exe and link.exe** — They do not search the system path; they treat system include and library locations as coming from the `INCLUDE` and `LIB` environment variables. As long as those are filtered out, the tools do not depend on external files.

- **clang.exe and clang-cl.exe** — They do search built-in paths. Use the `-nostdinc` flag to disable this behavior and keep the build hermetic.

- **lld-link.exe** — It can use built-in search paths for `LIBPATH`. Use the `/lldignoreenv` flag to prevent this.

To fully control which runtime library the linker uses, link with `/nodefaultlib` and specify the runtime library explicitly on the command line.

# Build Tool Reproducibility

## cl.exe

To amend absolute file paths, you need the `/pathmap:<old>=<new>` flag. However, `<old>` must be an absolute path to the current working directory, and Bazel does not provide this value. To work around this, `cl.exe` is wrapped in `cl_wrapper.bat`, which injects the `/pathmap:` flag using the value from `%CD%`.

Additionally, the `/Brepro` and `/experimental:deterministic` flags are required to prevent the insertion of build IDs and timestamps, which would make the build irreproducible.

## link.exe

`link.exe` uses `/experimental:deterministic` and `/Brepro` for the same reasons as `cl.exe`.

Use `/PDBALTPATH:%_PDB%` to rewrite the full path to the PDB file that gets embedded in the executable.

Incremental builds must be disabled using `/INCREMENTAL:NO`.

> **Note:** PDB files cannot be made fully reproducible with `link.exe` because it inserts Stream IDs that vary between builds. It also includes absolute paths to library files. For `.pdb` reproducibility, use `lld-link.exe` instead.

## lib.exe

`lib.exe` uses `/experimental:deterministic` and `/Brepro` for the same reasons as `cl.exe`.

## clang.exe and clang-cl.exe

- `-mno-incremental-linker-compatible` is used to prevent the addition of timestamps in the build.
- `-fdebug-compilation-dir=.`, `-fcoverage-compilation-dir=.`, and `-resource-dir=.` are used to prevent the inclusion of absolute paths in the debug info embedded in the `.obj` files.
- `-no-canonical-prefixes` prevents the compiler from transforming a symlink path to `clang.exe` into its real canonical path.
- `-gno-codeview-command-line` prevents the inclusion of the full command line, which may contain absolute paths.
- `-fno-ident` removes the Clang version and other metadata. While not strictly necessary for reproducibility, it ensures a cleaner output.

## lld-link.exe

- `/INCREMENTAL:NO` disables incremental builds.
- `/Brepro` prevents the inclusion of undesirable timestamps.
- `/PDBALTPATH:%_PDB%` rewrites the full path to the PDB file that gets embedded in the executable.
- `/pdbsourcepath:.` prevents the inclusion of absolute paths in the `S_ENVBLOCK` of the `.pdb` file.
  - This requires `lld-link` to be run from a relative path. For this reason, `lld-link.exe` is wrapped in `lld-link_wrapper.bat`, which adds the current directory to the `PATH` and executes `lld-link` using a relative path.

