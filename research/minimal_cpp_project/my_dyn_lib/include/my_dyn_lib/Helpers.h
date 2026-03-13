#pragma once

#ifdef MY_EXPORT
#define MY_API __declspec(dllexport)
#else
#define MY_API __declspec(dllimport)
#endif

namespace my_dyn {

MY_API int Square(int x);

}

extern "C" {
MY_API int MyAddMultiply(int a, int b, int c);
}