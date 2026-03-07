# Build Tool Hermeticity

Making build tools hermetic requires two things:

1. **Filter environment variables** — only allow tools to see the variables they need.
2. **Disable built-in search paths** — prevent tools from resolving paths outside the build.

In this setup, build tools run only with the `TMP`, `TEMP`, and `SYSTEMROOT` environment variables.

## Per-tool behavior

- **cl.exe and link.exe** — They do not search the system path; they treat system include and lib locations as coming from the `INCLUDE` and `LIB` environment variables. As long as those are filtered out, the tools do not depend on external files.

- **clang.exe and clang-cl.exe** — They do search built-in paths. Use the `-nostdinc` flag to disable that and keep the build hermetic.

- **lld-link.exe** — It can use built-in search paths for `LIBPATH`. Use the `/lldignoreenv` flag to prevent that.

To fully control which runtime library the linker uses, link with `/nodefaultlib` and specify the runtime library explicitly on the command line.


# Note

/Z7
/INCREMENTAL:NO

/Brepro for link.exe and cl.exe
Verify .obj embedded relative file path to .pdb
strip absolute path from .pdb
random_seed
prente __TIME__, __FILE__, etc