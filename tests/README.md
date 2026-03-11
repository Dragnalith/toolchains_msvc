*all_hosts_all_targets* is a project that declares every possible host and target, plus a large set of MSVC, LLVM, and WinSDK versions. Use it to test the full cross product of build axes.

*one_host_one_target* is a project that declares a single host and target (set via env vars). Use it to verify that only the chosen host and target packages are used and that others are not downloaded.

*reproducible_project* is a copy of all_hosts_all_targets. Use it to verify that the same project produces identical output.
