#include <iostream>

namespace {
#if defined(_MSC_VER) && !defined(__clang__)
const char* compiler = "cl.exe";
#elif defined(__clang__) && defined(_MSC_VER)
const char* compiler = "clang-cl.exe";
#elif defined(__clang__)
const char* compiler = "clang.exe";
#else
const char* compiler = "unknown";
#endif

#if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__)
const char* target_arch = "x64";
#elif defined(_M_IX86) || defined(__i386__)
const char* target_arch = "x86";
#elif defined(_M_ARM64) || defined(__aarch64__)
const char* target_arch = "arm64";
#else
const char* target_arch = "unknown";
#endif

}

int main() {
    std::cout << "Hello, World!\n"
              << "Compiler: " << compiler;
#if defined(_MSC_VER) && !defined(__clang__)
    std::cout << " (version " << (_MSC_VER / 100) << "." << (_MSC_VER % 100) << ")";
#elif defined(__clang__)
    std::cout << " (version " << __clang_major__ << "." << __clang_minor__ << "." << __clang_patchlevel__ << ")";
#endif
    std::cout << "\nTarget:   " << target_arch << std::endl;
    return 0;
}
