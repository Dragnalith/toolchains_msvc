#include <my/Log.h>
#include <iostream>
namespace my::internal {
void Log(std::string_view message) {
    std::cout << message.data() << std::endl;
}
}