#include <string_view>
#include <format>

namespace my::internal {
void Log(std::string_view message);

template<typename... Args>
void Log(std::format_string<Args...> fmt, Args&&... args) {
    Log(std::format(fmt, std::forward<Args>(args)...));
}
}

#define MY_LOG(...) my::internal::Log(__VA_ARGS__)