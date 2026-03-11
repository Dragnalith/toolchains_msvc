#pragma once

#include <string>

namespace hello_lib {

struct VersionInfo {
    std::string compiler;
    std::string compiler_version;
    std::string msvc_version;
    std::string winsdk_version;
    std::string target_arch;
};

VersionInfo get_current_version();

} // namespace hello_lib
