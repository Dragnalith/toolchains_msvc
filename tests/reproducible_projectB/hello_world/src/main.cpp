#include <iostream>
#include <hello_lib/current_version.h>

int main() {
    hello_lib::VersionInfo info = hello_lib::get_current_version();

    std::cout << "{\n"
              << "  \"compiler\": \"" << info.compiler << "\",\n"
              << "  \"compiler_version\": \"" << info.compiler_version << "\",\n"
              << "  \"msvc_version\": \"" << info.msvc_version << "\",\n"
              << "  \"winsdk_version\": \"" << info.winsdk_version << "\",\n"
              << "  \"target\": \"" << info.target_arch << "\"\n"
              << "}";
    return 0;
}
