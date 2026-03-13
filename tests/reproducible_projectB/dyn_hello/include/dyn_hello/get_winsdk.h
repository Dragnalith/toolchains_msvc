#pragma once

#if defined(HELLO_EXPORTS)
#define HELLO_API __declspec(dllexport)
#else
#define HELLO_API __declspec(dllimport)
#endif

extern "C" {

HELLO_API const char* get_winsdk_build_string(unsigned int version_index);

}
