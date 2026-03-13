#include <hello_lib/current_version.h>

#include <dyn_hello/get_winsdk.h>
#include <sdkddkver.h>

namespace {

#if defined(COMPILER_IS_CL) 
int version_major = _MSC_VER / 100;
int version_minor = _MSC_VER % 100;
int version_patch = 0;
const char* compiler = "cl.exe";
const bool is_cl = true;
const bool is_clang_cl = false;
const bool is_clang = false;
#elif defined(COMPILER_IS_CLANG_CL)
int version_major = __clang_major__;
int version_minor = __clang_minor__;
int version_patch = __clang_patchlevel__;
const char* compiler = "clang-cl.exe";
const bool is_cl = false;
const bool is_clang_cl = true;
const bool is_clang = false;
#elif defined(COMPILER_IS_CLANG)
int version_major = __clang_major__;
int version_minor = __clang_minor__;
int version_patch = __clang_patchlevel__;
const char* compiler = "clang.exe";
const bool is_cl = false;
const bool is_clang_cl = false;
const bool is_clang = true;
#else
#error "Unknown compiler"
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



} // namespace

namespace hello_lib {

VersionInfo get_current_version() {
    VersionInfo info;
    info.target_arch = target_arch;
    info.compiler = compiler;

    std::string msvc_version = std::to_string(_MSC_VER / 100 - 5) + "." + std::to_string(_MSC_VER % 100);
    info.msvc_version = msvc_version;

    if (is_cl) {
        info.compiler_version = msvc_version;
    } else {
        info.compiler_version = std::to_string(version_major) + "." + std::to_string(version_minor) + "." + std::to_string(version_patch);
    }
    
    info.winsdk_version = get_winsdk_build_string(NTDDI_VERSION & 0xFF);

    (void)(is_clang_cl);
    (void)(is_clang);
    (void)(is_x64);
    (void)(is_x86);
    (void)(is_arm64);

    return info;
}

} // namespace hello_lib
