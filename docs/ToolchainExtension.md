<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Bazel module extension for `toolchains_msvc` (MSVC, Windows SDK, and LLVM).

Fetch MSVC / WinSDK / LLVM packages, and declare toolchains according to `toolchain.toolchain_set(...)` blocks.

Typical `MODULE.bazel` pattern:

```
toolchain = use_extension("@toolchains_msvc//:extensions.bzl", "toolchain")
toolchain.toolchain_set(
    name = "main",
    msvc_versions = ["..."],
    winsdk_versions = ["..."],
)
use_repo(toolchain, "msvc_toolchains")
register_toolchains("@msvc_toolchains//:all")
```

Environment:

* ``BAZEL_TOOLCHAINS_MSVC_HOSTS`` — comma-separated list of hosts, used if ``hosts`` is omitted on a set.
* ``BAZEL_TOOLCHAINS_MSVC_TARGETS`` — comma-separated list of targets, used if ``targets`` is omitted.

<a id="toolchain"></a>

## toolchain

<pre>
toolchain = use_extension("@toolchains_msvc//:extensions.bzl", "toolchain")
toolchain.repo_name(<a href="#toolchain.repo_name-name">name</a>)
toolchain.toolchain_set(<a href="#toolchain.toolchain_set-name">name</a>, <a href="#toolchain.toolchain_set-add_cl_copt">add_cl_copt</a>, <a href="#toolchain.toolchain_set-add_cl_cxxopt">add_cl_cxxopt</a>, <a href="#toolchain.toolchain_set-add_cl_dbg_copt">add_cl_dbg_copt</a>, <a href="#toolchain.toolchain_set-add_cl_dbg_cxxopt">add_cl_dbg_cxxopt</a>,
                        <a href="#toolchain.toolchain_set-add_cl_dbg_linkopt">add_cl_dbg_linkopt</a>, <a href="#toolchain.toolchain_set-add_cl_fastbuild_copt">add_cl_fastbuild_copt</a>, <a href="#toolchain.toolchain_set-add_cl_fastbuild_cxxopt">add_cl_fastbuild_cxxopt</a>,
                        <a href="#toolchain.toolchain_set-add_cl_fastbuild_linkopt">add_cl_fastbuild_linkopt</a>, <a href="#toolchain.toolchain_set-add_cl_linkopt">add_cl_linkopt</a>, <a href="#toolchain.toolchain_set-add_cl_opt_copt">add_cl_opt_copt</a>, <a href="#toolchain.toolchain_set-add_cl_opt_cxxopt">add_cl_opt_cxxopt</a>,
                        <a href="#toolchain.toolchain_set-add_cl_opt_linkopt">add_cl_opt_linkopt</a>, <a href="#toolchain.toolchain_set-add_clang_copt">add_clang_copt</a>, <a href="#toolchain.toolchain_set-add_clang_cxxopt">add_clang_cxxopt</a>, <a href="#toolchain.toolchain_set-add_clang_dbg_copt">add_clang_dbg_copt</a>,
                        <a href="#toolchain.toolchain_set-add_clang_dbg_cxxopt">add_clang_dbg_cxxopt</a>, <a href="#toolchain.toolchain_set-add_clang_dbg_linkopt">add_clang_dbg_linkopt</a>, <a href="#toolchain.toolchain_set-add_clang_fastbuild_copt">add_clang_fastbuild_copt</a>,
                        <a href="#toolchain.toolchain_set-add_clang_fastbuild_cxxopt">add_clang_fastbuild_cxxopt</a>, <a href="#toolchain.toolchain_set-add_clang_fastbuild_linkopt">add_clang_fastbuild_linkopt</a>, <a href="#toolchain.toolchain_set-add_clang_linkopt">add_clang_linkopt</a>,
                        <a href="#toolchain.toolchain_set-add_clang_opt_copt">add_clang_opt_copt</a>, <a href="#toolchain.toolchain_set-add_clang_opt_cxxopt">add_clang_opt_cxxopt</a>, <a href="#toolchain.toolchain_set-add_clang_opt_linkopt">add_clang_opt_linkopt</a>, <a href="#toolchain.toolchain_set-cl_copt">cl_copt</a>,
                        <a href="#toolchain.toolchain_set-cl_cxxopt">cl_cxxopt</a>, <a href="#toolchain.toolchain_set-cl_dbg_copt">cl_dbg_copt</a>, <a href="#toolchain.toolchain_set-cl_dbg_cxxopt">cl_dbg_cxxopt</a>, <a href="#toolchain.toolchain_set-cl_dbg_linkopt">cl_dbg_linkopt</a>, <a href="#toolchain.toolchain_set-cl_fastbuild_copt">cl_fastbuild_copt</a>,
                        <a href="#toolchain.toolchain_set-cl_fastbuild_cxxopt">cl_fastbuild_cxxopt</a>, <a href="#toolchain.toolchain_set-cl_fastbuild_linkopt">cl_fastbuild_linkopt</a>, <a href="#toolchain.toolchain_set-cl_linkopt">cl_linkopt</a>, <a href="#toolchain.toolchain_set-cl_opt_copt">cl_opt_copt</a>,
                        <a href="#toolchain.toolchain_set-cl_opt_cxxopt">cl_opt_cxxopt</a>, <a href="#toolchain.toolchain_set-cl_opt_linkopt">cl_opt_linkopt</a>, <a href="#toolchain.toolchain_set-cl_with_lld_version">cl_with_lld_version</a>, <a href="#toolchain.toolchain_set-clang_copt">clang_copt</a>, <a href="#toolchain.toolchain_set-clang_cxxopt">clang_cxxopt</a>,
                        <a href="#toolchain.toolchain_set-clang_dbg_copt">clang_dbg_copt</a>, <a href="#toolchain.toolchain_set-clang_dbg_cxxopt">clang_dbg_cxxopt</a>, <a href="#toolchain.toolchain_set-clang_dbg_linkopt">clang_dbg_linkopt</a>, <a href="#toolchain.toolchain_set-clang_fastbuild_copt">clang_fastbuild_copt</a>,
                        <a href="#toolchain.toolchain_set-clang_fastbuild_cxxopt">clang_fastbuild_cxxopt</a>, <a href="#toolchain.toolchain_set-clang_fastbuild_linkopt">clang_fastbuild_linkopt</a>, <a href="#toolchain.toolchain_set-clang_linkopt">clang_linkopt</a>,
                        <a href="#toolchain.toolchain_set-clang_opt_copt">clang_opt_copt</a>, <a href="#toolchain.toolchain_set-clang_opt_cxxopt">clang_opt_cxxopt</a>, <a href="#toolchain.toolchain_set-clang_opt_linkopt">clang_opt_linkopt</a>, <a href="#toolchain.toolchain_set-dbg_features">dbg_features</a>,
                        <a href="#toolchain.toolchain_set-fastbuild_features">fastbuild_features</a>, <a href="#toolchain.toolchain_set-features">features</a>, <a href="#toolchain.toolchain_set-hosts">hosts</a>, <a href="#toolchain.toolchain_set-llvm_versions">llvm_versions</a>, <a href="#toolchain.toolchain_set-msvc_versions">msvc_versions</a>,
                        <a href="#toolchain.toolchain_set-opt_features">opt_features</a>, <a href="#toolchain.toolchain_set-targets">targets</a>, <a href="#toolchain.toolchain_set-winsdk_versions">winsdk_versions</a>)
toolchain.default_toolchain_set(<a href="#toolchain.default_toolchain_set-name">name</a>)
toolchain.default_msvc_version(<a href="#toolchain.default_msvc_version-version">version</a>)
toolchain.default_llvm_version(<a href="#toolchain.default_llvm_version-version">version</a>)
toolchain.default_winsdk_version(<a href="#toolchain.default_winsdk_version-version">version</a>)
toolchain.default_compiler(<a href="#toolchain.default_compiler-compiler">compiler</a>)
</pre>

Fetches MSVC, Windows SDK, and optional LLVM artifacts and registers matching C++ toolchains.


**TAG CLASSES**

<a id="toolchain.repo_name"></a>

### repo_name

Sets the name of the generated toolchains repository (default is `msvc_toolchains`).

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="toolchain.repo_name-name"></a>name |  Repository name used in `use_repo(toolchain, "<name>")` and `@<name>//...` labels.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |

<a id="toolchain.toolchain_set"></a>

### toolchain_set

Declares a set of toolchains made of the cross-product of MSVC, WinSDK, and optional LLVM versions, hosts, targets, features, and compiler flags.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="toolchain.toolchain_set-name"></a>name |  Unique name for this toolchain set; must be a valid label segment (no `/`, `\`, `:`, `@`, or spaces).   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="toolchain.toolchain_set-add_cl_copt"></a>add_cl_copt |  Appended to the effective MSVC `cl` or `clang-cl` C flags for the default mode (after defaults or `cl_copt` replacement).   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_cl_cxxopt"></a>add_cl_cxxopt |  Appended to the effective MSVC `cl` or `clang-cl` C++ flags for the default mode.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_cl_dbg_copt"></a>add_cl_dbg_copt |  Appended to the effective MSVC `cl` or `clang-cl` C flags for `-c dbg`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_cl_dbg_cxxopt"></a>add_cl_dbg_cxxopt |  Appended to the effective MSVC `cl` or `clang-cl` C++ flags for `-c dbg`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_cl_dbg_linkopt"></a>add_cl_dbg_linkopt |  Appended to the effective MSVC link flags for `-c dbg`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_cl_fastbuild_copt"></a>add_cl_fastbuild_copt |  Appended to the effective MSVC `cl` or `clang-cl` C flags for `-c fastbuild`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_cl_fastbuild_cxxopt"></a>add_cl_fastbuild_cxxopt |  Appended to the effective MSVC `cl` or `clang-cl` C++ flags for `-c fastbuild`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_cl_fastbuild_linkopt"></a>add_cl_fastbuild_linkopt |  Appended to the effective MSVC link flags for `-c fastbuild`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_cl_linkopt"></a>add_cl_linkopt |  Appended to the effective MSVC link flags for the default mode.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_cl_opt_copt"></a>add_cl_opt_copt |  Appended to the effective MSVC `cl` or `clang-cl` C flags for `-c opt`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_cl_opt_cxxopt"></a>add_cl_opt_cxxopt |  Appended to the effective MSVC `cl` or `clang-cl` C++ flags for `-c opt`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_cl_opt_linkopt"></a>add_cl_opt_linkopt |  Appended to the effective MSVC link flags for `-c opt`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_copt"></a>add_clang_copt |  Appended to the effective Clang C flags for the default mode.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_cxxopt"></a>add_clang_cxxopt |  Appended to the effective Clang C++ flags for the default mode.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_dbg_copt"></a>add_clang_dbg_copt |  Appended to the effective Clang C flags for `-c dbg`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_dbg_cxxopt"></a>add_clang_dbg_cxxopt |  Appended to the effective Clang C++ flags for `-c dbg`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_dbg_linkopt"></a>add_clang_dbg_linkopt |  Appended to the effective Clang link flags for `-c dbg`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_fastbuild_copt"></a>add_clang_fastbuild_copt |  Appended to the effective Clang C flags for `-c fastbuild`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_fastbuild_cxxopt"></a>add_clang_fastbuild_cxxopt |  Appended to the effective Clang C++ flags for `-c fastbuild`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_fastbuild_linkopt"></a>add_clang_fastbuild_linkopt |  Appended to the effective Clang link flags for `-c fastbuild`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_linkopt"></a>add_clang_linkopt |  Appended to the effective Clang link flags for the default mode.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_opt_copt"></a>add_clang_opt_copt |  Appended to the effective Clang C flags for `-c opt`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_opt_cxxopt"></a>add_clang_opt_cxxopt |  Appended to the effective Clang C++ flags for `-c opt`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-add_clang_opt_linkopt"></a>add_clang_opt_linkopt |  Appended to the effective Clang link flags for `-c opt`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_copt"></a>cl_copt |  MSVC `cl` or `clang-cl` C compile options for the default compilation mode; replaces the built-in default list.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_cxxopt"></a>cl_cxxopt |  MSVC `cl` or `clang-cl` C++ compile options for the default mode; replaces the built-in default list.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_dbg_copt"></a>cl_dbg_copt |  MSVC `cl` or `clang-cl` C compile options for `-c dbg`; replaces the dbg defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_dbg_cxxopt"></a>cl_dbg_cxxopt |  MSVC `cl` or `clang-cl` C++ compile options for `-c dbg`; replaces the dbg defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_dbg_linkopt"></a>cl_dbg_linkopt |  MSVC link flags for `-c dbg`; replaces the dbg defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_fastbuild_copt"></a>cl_fastbuild_copt |  MSVC `cl` or `clang-cl` C compile options for `-c fastbuild`; replaces fastbuild defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_fastbuild_cxxopt"></a>cl_fastbuild_cxxopt |  MSVC `cl` or `clang-cl` C++ compile options for `-c fastbuild`; replaces fastbuild defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_fastbuild_linkopt"></a>cl_fastbuild_linkopt |  MSVC link flags for `-c fastbuild`; replaces fastbuild defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_linkopt"></a>cl_linkopt |  MSVC link flags for the default mode; replaces the built-in default list.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_opt_copt"></a>cl_opt_copt |  MSVC `cl` or `clang-cl` C compile options for `-c opt`; replaces opt defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_opt_cxxopt"></a>cl_opt_cxxopt |  MSVC `cl` or `clang-cl` C++ compile options for `-c opt`; replaces opt defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_opt_linkopt"></a>cl_opt_linkopt |  MSVC link flags for `-c opt`; replaces opt defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-cl_with_lld_version"></a>cl_with_lld_version |  Optional LLVM version string to pull in `lld-link` for use with `cl` (adds an LLVM repo for that version).   | String | optional |  `""`  |
| <a id="toolchain.toolchain_set-clang_copt"></a>clang_copt |  Clang C compile options for the default mode; non-empty replaces the built-in default list.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-clang_cxxopt"></a>clang_cxxopt |  Clang C++ compile options for the default mode; non-empty replaces the built-in default list.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-clang_dbg_copt"></a>clang_dbg_copt |  Clang C compile options for `-c dbg`; non-empty replaces dbg defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-clang_dbg_cxxopt"></a>clang_dbg_cxxopt |  Clang C++ compile options for `-c dbg`; non-empty replaces dbg defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-clang_dbg_linkopt"></a>clang_dbg_linkopt |  Clang link flags for `-c dbg`; non-empty replaces dbg defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-clang_fastbuild_copt"></a>clang_fastbuild_copt |  Clang C compile options for `-c fastbuild`; non-empty replaces fastbuild defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-clang_fastbuild_cxxopt"></a>clang_fastbuild_cxxopt |  Clang C++ compile options for `-c fastbuild`; non-empty replaces fastbuild defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-clang_fastbuild_linkopt"></a>clang_fastbuild_linkopt |  Clang link flags for `-c fastbuild`; non-empty replaces fastbuild defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-clang_linkopt"></a>clang_linkopt |  Clang/lld link flags for the default mode; non-empty replaces the built-in default list.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-clang_opt_copt"></a>clang_opt_copt |  Clang C compile options for `-c opt`; non-empty replaces opt defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-clang_opt_cxxopt"></a>clang_opt_cxxopt |  Clang C++ compile options for `-c opt`; non-empty replaces opt defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-clang_opt_linkopt"></a>clang_opt_linkopt |  Clang link flags for `-c opt`; non-empty replaces opt defaults.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-dbg_features"></a>dbg_features |  Extra `features` enabled when compiling with `-c dbg`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-fastbuild_features"></a>fastbuild_features |  Extra `features` enabled when compiling with `-c fastbuild`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-features"></a>features |  Default `features` to be enabled for this toolchain set (Bazel `cc` feature names).   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-hosts"></a>hosts |  List of host architecture, value should be among `x64`, `x86` or `arm64`. If empty, uses `BAZEL_TOOLCHAINS_MSVC_HOSTS` or `x64`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-llvm_versions"></a>llvm_versions |  LLVM/Clang versions for `clang` / `clang-cl` based toolchains. Can be empty.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-msvc_versions"></a>msvc_versions |  List of enabled MSVC versions. Must have at least one element.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-opt_features"></a>opt_features |  Extra `features` enabled when compiling with `-c opt`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-targets"></a>targets |  List of target architecture, among `x64`, `x86` or `arm64`. If empty, uses `BAZEL_TOOLCHAINS_MSVC_TARGETS` or `x64`.   | List of strings | optional |  `[]`  |
| <a id="toolchain.toolchain_set-winsdk_versions"></a>winsdk_versions |  Windows SDK versions for this toolchain set. Must have at least one element.   | List of strings | optional |  `[]`  |

<a id="toolchain.default_toolchain_set"></a>

### default_toolchain_set

Selects which declared `toolchain_set` is the default for the generated repo. Otherwise, the first declared toolchain set is used.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="toolchain.default_toolchain_set-name"></a>name |  Must match the `name` of a `toolchain.toolchain_set` in this extension invocation.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |

<a id="toolchain.default_msvc_version"></a>

### default_msvc_version

Default MSVC toolset version for the aggregate toolchains repository (must appear in some `toolchain_set`).

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="toolchain.default_msvc_version-version"></a>version |  Must be one of the MSVC versions declared in `toolchain_set`. If the whole `default_msvc_version` tag is omitted, the first MSVC version across sets is used.   | String | required |  |

<a id="toolchain.default_llvm_version"></a>

### default_llvm_version

Default LLVM version when LLVM is used (must appear in at least one `toolchain_set`).

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="toolchain.default_llvm_version-version"></a>version |  Must be one of the LLVM versions declared in `toolchain_set`. If the whole `default_llvm_version` tag is omitted, the first LLVM version across sets is used when LLVM is enabled.   | String | required |  |

<a id="toolchain.default_winsdk_version"></a>

### default_winsdk_version

Default Windows SDK version (must appear in at least one `toolchain_set`).

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="toolchain.default_winsdk_version-version"></a>version |  Must be one of the WinSDK versions declared in `toolchain_set`. If the whole `default_winsdk_version` tag is omitted, the first WinSDK version across sets is used.   | String | required |  |

<a id="toolchain.default_compiler"></a>

### default_compiler

Default compiler to be used (`msvc-cl`, `clang-cl`, or `clang`) when resolving toolchains.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="toolchain.default_compiler-compiler"></a>compiler |  `msvc-cl` uses MSVC `cl`; `clang-cl` / `clang` require LLVM versions to be declared.   | String | required |  |


