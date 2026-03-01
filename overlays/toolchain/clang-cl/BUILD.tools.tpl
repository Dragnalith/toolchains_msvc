load("@rules_cc//cc/toolchains:tool.bzl", "cc_tool")
load("@rules_cc//cc/toolchains:tool_map.bzl", "cc_tool_map")

package(default_visibility = ["//visibility:public"])

cc_tool_map(
    name = "all_tools",
    tools = {
        "@rules_cc//cc/toolchains/actions:assembly_actions": ":ml64",
        "@rules_cc//cc/toolchains/actions:c_compile": ":cl",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions": ":cl",
        "@rules_cc//cc/toolchains/actions:link_actions": ":link",
        "@rules_cc//cc/toolchains/actions:ar_actions": ":lib",
        "@rules_cc//cc/toolchains/actions:strip": ":link",
    },
    visibility = ["//visibility:public"],
)

cc_tool(
    name = "cl",
    src = "@{llvm_repo}//:{compiler}_host{host}_target{target}",
    data = [
        "@{llvm_repo}//:clang_all_binaries_host{host}_target{target}",
        "@{msvc_repo}//:msvc_all_includes",
    ],
)

cc_tool(
    name = "link",
    src = "@{llvm_repo}//:lld-link_host{host}_target{target}",
    data = [
        "@{llvm_repo}//:clang_all_binaries_host{host}_target{target}",
        "@{msvc_repo}//:msvc_all_libs_{target}",
    ],
)

cc_tool(
    name = "lib",
    src = "@{llvm_repo}//:llvm-lib_host{host}_target{target}",
    data = [
        "@{llvm_repo}//:clang_all_binaries_host{host}_target{target}",
    ],
)

cc_tool(
    name = "ml64",
    src = "@{llvm_repo}//:llvm-ml_host{host}_target{target}",
    data = [
        "@{llvm_repo}//:clang_all_binaries_host{host}_target{target}",
    ],
)
