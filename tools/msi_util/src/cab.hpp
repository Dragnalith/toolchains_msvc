#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

namespace msi_util {

/// Extract each file from a CAB (MSZIP or uncompressed). Invokes `on_file` with
/// internal CAB path and uncompressed bytes. Returns false on fatal parse error.
bool extract_cab(const std::vector<uint8_t> &cab,
                 const std::function<bool(const std::string &name,
                                          const std::vector<uint8_t> &data)> &on_file);

} // namespace msi_util
