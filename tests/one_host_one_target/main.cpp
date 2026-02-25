#include <iostream>
#include <string>
#include <sdkddkver.h>

namespace {
#if defined(_MSC_VER) && !defined(__clang__)
const char* compiler = "cl.exe";
const bool is_cl = true;
const bool is_clang_cl = false;
const bool is_clang = false;
int version_minor = _MSC_VER % 100;
int version_major = _MSC_VER / 100;
#elif defined(__clang__) && defined(_MSC_VER)
const char* compiler = "clang-cl.exe";
const bool is_cl = false;
const bool is_clang_cl = true;
const bool is_clang = false;
int version_minor = __clang_minor__;
int version_major = __clang_major__;
#elif defined(__clang__)
const char* compiler = "clang.exe";
const bool is_cl = false;
const bool is_clang_cl = false;
const bool is_clang = true;
int version_minor = __clang_minor__;
int version_major = __clang_major__;
#else
#error "Unknown compiler
#endif

#if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__)
const char* target_arch = "x64";
const bool is_x64 = true;
const bool is_x86 = false;
const bool is_arm64 = false;
#elif defined(_M_IX86) || defined(__i386__)
const char* target_arch = "x86";
const bool is_x64 = false;
const bool is_x86 = true;
const bool is_arm64 = false;
#elif defined(_M_ARM64) || defined(__aarch64__)
const char* target_arch = "arm64";
const bool is_x64 = false;
const bool is_x86 = false;
const bool is_arm64 = true;
#else
#error "Unknown target architecture"
#endif

const char* get_winsdk_build_string() {
    unsigned int version_index = NTDDI_VERSION & 0xFF;

    switch (version_index) {
        case 0x08: return "19041"; // VB
        case 0x09: return "19645"; // MN
        case 0x0A: return "20348"; // FE
        case 0x0B: return "22000"; // CO
        case 0x0C: return "22621"; // NI
        case 0x0D: return "25236"; // CU
        case 0x0E: return "25398"; // ZN
        case 0x0F: return "25941"; // GA
        case 0x10: return "26100"; // GE
        default:   return "unknown";
    }
}

}

int main() {

    std::string compiler_version = std::to_string(version_major) + "." + std::to_string(version_minor);
    std::string winsdk_version = get_winsdk_build_string();

    std::cout << "{\n"
              << "  \"compiler\": \"" << compiler << "\",\n"
              << "  \"compiler_version\": \"" << compiler_version << "\",\n"
              << "  \"winsdk_version\": \"" << winsdk_version << "\",\n"
              << "  \"target\": \"" << target_arch << "\"\n"
              << "}" << std::endl;
    return 0;
}
