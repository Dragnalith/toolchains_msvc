#include <dyn_hello/get_winsdk.h>

const char* get_winsdk_build_string(unsigned int version_index) {
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
