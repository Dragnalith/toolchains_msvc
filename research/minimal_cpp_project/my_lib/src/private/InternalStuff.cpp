#include <private/InternalStuff.h>
#include <my/Log.h>
#include <my_dyn_lib/Helpers.h>

namespace my {

void InitFrame(Frame& /*frame*/) {
    MY_LOG("InitFrame: AddMultiply(1, 2, 3) = {}", MyAddMultiply(1, 2, 3));
}

}