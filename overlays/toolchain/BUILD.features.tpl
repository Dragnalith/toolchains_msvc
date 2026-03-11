load("@rules_cc//cc/toolchains:feature.bzl", "cc_feature")
load("@rules_cc//cc/toolchains:feature_constraint.bzl", "cc_feature_constraint")
load("@rules_cc//cc/toolchains:feature_set.bzl", "cc_feature_set")
load("@rules_cc//cc/toolchains:mutually_exclusive_category.bzl", "cc_mutually_exclusive_category")

package(default_visibility = ["//visibility:public"])

cc_feature_set(
    name = "all_known_features",
    all_of = [
        # Plumbing Features
        ":no_legacy_features",
        ":linker_param_file",
        ":archive_param_file",
        ":compiler_input_flags",
        ":compiler_output_flags",
        ":linker_input",
        ":output_execpath_flags",
        ":archiver_input",
        ":archiver_output",
        ":strip_input",
        ":strip_output",
        ":parse_showincludes",
        ":no_dotd_file",
        ":dependency_file",

        # Toolchain Policy Defaults
        ":default_flags",
        ":all_runtime_flags",
        ":all_subsystem_flags",

        # Rule-Level Passthrough
        ":user_compile_flags",
        ":user_compile_defines",
        ":includes",
        ":user_link_flags",

        # Configuration (Mode-Driven)
        ":dbg",
        ":fastbuild",
        ":opt",
        ":treat_warnings_as_errors",
        ":generate_debug_symbols",
        ":generate_pdb_file",
        ":static_runtime",
        ":debug_runtime",
        ":thinlto",
        ":fulllto",
        ":cxx_standard_14",
        ":cxx_standard_17",
        ":cxx_standard_20",
        ":cxx_standard_23",
        ":cxx_standard_26",
        ":cxx_standard_latest",
        ":window_subsystem",
        ":console_subsystem",
    ],
)

cc_feature_set(
    name = "default_features",
    all_of = [
        # Plumbing Features
        ":no_legacy_features",
        ":linker_param_file",
        ":archive_param_file",
        ":compiler_input_flags",
        ":compiler_output_flags",
        ":linker_input",
        ":output_execpath_flags",
        ":archiver_input",
        ":archiver_output",
        ":strip_input",
        ":strip_output",

        # Toolchain Policy Defaults
        ":default_flags",
        ":all_runtime_flags",
        ":all_subsystem_flags",

        # Rule-Level Passthrough
        ":user_compile_flags",
        ":user_compile_defines",
        ":includes",
        ":user_link_flags",
    ],
)

# Plumbing Features
cc_feature(
    name = "no_legacy_features",
    feature_name = "no_legacy_features",
)

cc_feature(
    name = "linker_param_file",
    args = ["//{COMPILER_KIND}/args:param_file_args"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:linker_param_file",
)

cc_feature(
    name = "archive_param_file",
    args = ["//{COMPILER_KIND}/args:param_file_args"],
    feature_name = "archive_param_file",
)

cc_feature(
    name = "compiler_input_flags",
    args = ["//{COMPILER_KIND}/args:compiler_input_flags"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:compiler_input_flags",
)

cc_feature(
    name = "compiler_output_flags",
    args = ["//{COMPILER_KIND}/args:compiler_output_flags"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:compiler_output_flags",
)

cc_feature(
    name = "linker_input",
    args = ["//{COMPILER_KIND}/args:linker_input"],
    feature_name = "linker_input",
)

cc_feature(
    name = "output_execpath_flags",
    args = ["//{COMPILER_KIND}/args:output_execpath_flags"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:output_execpath_flags",
)

cc_feature(
    name = "archiver_input",
    args = ["//{COMPILER_KIND}/args:archiver_input"],
    feature_name = "archiver_input",
)

cc_feature(
    name = "archiver_output",
    args = ["//{COMPILER_KIND}/args:archiver_output"],
    feature_name = "archiver_output",
)

cc_feature(
    name = "strip_input",
    args = ["//{COMPILER_KIND}/args:strip_input"],
    feature_name = "strip_input",
)

cc_feature(
    name = "strip_output",
    args = ["//{COMPILER_KIND}/args:strip_output"],
    feature_name = "strip_output",
)

# Header Dependency Discovery
cc_feature(
    name = "parse_showincludes",
    args = ["//{COMPILER_KIND}/args:parse_showincludes"],
    feature_name = "parse_showincludes",
)

cc_feature(
    name = "no_dotd_file",
    feature_name = "no_dotd_file",
)

cc_feature(
    name = "dependency_file",
    args = ["//{COMPILER_KIND}/args:dependency_file"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:dependency_file",
)

# Toolchain Policy Defaults

cc_feature(
    name = "default_flags",
    args = [
        "//{COMPILER_KIND}/args:default_cxx_compile_flags",
        "//{COMPILER_KIND}/args:default_c_compile_flags",
        "//{COMPILER_KIND}/args:default_assemble_flags",
        "//{COMPILER_KIND}/args:default_link_flags",
        "//{COMPILER_KIND}/args:default_archive_flags",
        "//{COMPILER_KIND}/args:default_strip_flags",
    ],
    feature_name = "default_flags",
)

# Rule-Level Passthrough
cc_feature(
    name = "user_compile_flags",
    args = ["//{COMPILER_KIND}/args:user_compile_flags"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:user_compile_flags",
)

cc_feature(
    name = "user_compile_defines",
    args = ["//{COMPILER_KIND}/args:user_compile_defines"],
    feature_name = "user_compile_defines",
)

cc_feature(
    name = "includes",
    args = ["//{COMPILER_KIND}/args:includes"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:includes",
)

cc_feature(
    name = "user_link_flags",
    args = ["//{COMPILER_KIND}/args:user_link_flags"],
    overrides = "@rules_cc//cc/toolchains/features/legacy:user_link_flags",
)

# Configuration (Mode-Driven)

## Umbrella Mode Features
cc_mutually_exclusive_category(name = "compilation_mode")

cc_feature(
    name = "dbg",
    mutually_exclusive = [":compilation_mode"],
    overrides = "@rules_cc//cc/toolchains/features:dbg",
    args = [
        "//{COMPILER_KIND}/args:dbg_compile_flags",
        "//{COMPILER_KIND}/args:dbg_link_flags",
    ],
)

cc_feature(
    name = "fastbuild",
    mutually_exclusive = [":compilation_mode"],
    overrides = "@rules_cc//cc/toolchains/features:fastbuild",
    args = [
        "//{COMPILER_KIND}/args:fastbuild_compile_flags",
        "//{COMPILER_KIND}/args:fastbuild_link_flags",
    ],
)

cc_feature(
    name = "opt",
    mutually_exclusive = [":compilation_mode"],
    overrides = "@rules_cc//cc/toolchains/features:opt",
    args = [
        "//{COMPILER_KIND}/args:opt_compile_flags",
        "//{COMPILER_KIND}/args:opt_link_flags",
    ],
)

# Semantic Option Features

## Diagnostics
cc_feature(
    name = "treat_warnings_as_errors",
    args = ["//{COMPILER_KIND}/args:treat_warnings_as_errors"],
    feature_name = "treat_warnings_as_errors",
)

## Debug Information
cc_feature(
    name = "generate_debug_symbols",
    args = [
        "//{COMPILER_KIND}/args:generate_debug_symbols_compile",
        "//{COMPILER_KIND}/args:generate_debug_symbols_link",
    ],
    feature_name = "generate_debug_symbols",
    implies = [":generate_pdb_file"],
)

cc_feature(
    name = "generate_pdb_file",
    feature_name = "generate_pdb_file",
)

## Runtime Linkage

cc_feature(
    name = "static_runtime",
    feature_name = "static_runtime",
)

cc_feature(
    name = "debug_runtime",
    feature_name = "debug_runtime",
)

cc_feature_constraint(
    name = "no_static_no_debug_constraint",
    none_of = [":static_runtime", ":debug_runtime"],
)

cc_feature_constraint(
    name = "no_static_debug_constraint",
    all_of = [":debug_runtime"],
    none_of = [":static_runtime"],
)

cc_feature_constraint(
    name = "static_no_debug_constraint",
    all_of = [":static_runtime"],
    none_of = [":debug_runtime"],
)

cc_feature_set(
    name = "static_debug_constraint",
    all_of = [":static_runtime", ":debug_runtime"],
)

cc_feature(
    name = "all_runtime_flags",
    args = [
        "//{COMPILER_KIND}/args:debug_dynamic_runtime_compile",
        "//{COMPILER_KIND}/args:debug_dynamic_runtime_link",
        "//{COMPILER_KIND}/args:debug_static_runtime_compile",
        "//{COMPILER_KIND}/args:debug_static_runtime_link",
        "//{COMPILER_KIND}/args:release_dynamic_runtime_compile",
        "//{COMPILER_KIND}/args:release_dynamic_runtime_link",
        "//{COMPILER_KIND}/args:release_static_runtime_compile",
        "//{COMPILER_KIND}/args:release_static_runtime_link",
    ],
    feature_name = "all_runtime_flags",
)

## Subsystem
cc_mutually_exclusive_category(  
    name = "subsystem_mutually_exclusive_category",  
)

cc_feature(
    name = "all_subsystem_flags",
    args = [
        "//{COMPILER_KIND}/args:window_subsystem",
        "//{COMPILER_KIND}/args:console_subsystem",
    ],
    feature_name = "all_subsystem_flags",
)

cc_feature(
    name = "window_subsystem",
    feature_name = "window_subsystem",
    mutually_exclusive = [":subsystem_mutually_exclusive_category"],
)

cc_feature(
    name = "console_subsystem",
    feature_name = "console_subsystem",
    mutually_exclusive = [":subsystem_mutually_exclusive_category"],
)

cc_feature_constraint(
    name = "no_subsystem_constraint",
    none_of = [":window_subsystem", ":console_subsystem"],
)

## Optimization Technologies
cc_mutually_exclusive_category(name = "lto")

cc_feature(
    name = "thinlto",
    args = [
        "//{COMPILER_KIND}/args:thin_lto_compile",
        "//{COMPILER_KIND}/args:thin_lto_link",
    ],
    feature_name = "thinlto",
    mutually_exclusive = [":lto"],
)

cc_feature(
    name = "fulllto",
    args = [
        "//{COMPILER_KIND}/args:full_lto_compile",
        "//{COMPILER_KIND}/args:full_lto_link",
    ],
    feature_name = "fulllto",
    mutually_exclusive = [":lto"],
)

## Language Standard
cc_mutually_exclusive_category(name = "cxx_standard")

cc_feature(
    name = "cxx_standard_14",
    args = ["//{COMPILER_KIND}/args:cxx_standard_14"],
    feature_name = "cxx_standard_14",
    mutually_exclusive = [":cxx_standard"],
)

cc_feature(
    name = "cxx_standard_17",
    args = ["//{COMPILER_KIND}/args:cxx_standard_17"],
    feature_name = "cxx_standard_17",
    mutually_exclusive = [":cxx_standard"],
)

cc_feature(
    name = "cxx_standard_20",
    args = ["//{COMPILER_KIND}/args:cxx_standard_20"],
    feature_name = "cxx_standard_20",
    mutually_exclusive = [":cxx_standard"],
)

cc_feature(
    name = "cxx_standard_23",
    args = ["//{COMPILER_KIND}/args:cxx_standard_23"],
    feature_name = "cxx_standard_23",
    mutually_exclusive = [":cxx_standard"],
)

cc_feature(
    name = "cxx_standard_26",
    args = ["//{COMPILER_KIND}/args:cxx_standard_26"],
    feature_name = "cxx_standard_26",
    mutually_exclusive = [":cxx_standard"],
)

cc_feature(
    name = "cxx_standard_latest",
    args = ["//{COMPILER_KIND}/args:cxx_standard_latest"],
    feature_name = "cxx_standard_latest",
    mutually_exclusive = [":cxx_standard"],
)
