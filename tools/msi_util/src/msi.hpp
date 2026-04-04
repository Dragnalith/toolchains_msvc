#pragma once

#include "cfb.hpp"

#include <map>
#include <string>
#include <vector>

namespace msi_util {

struct MsiPackage {
  std::map<std::string, std::string> file_map;
  std::vector<std::string> cab_files;
};

[[nodiscard]] MsiPackage parse_msi(CompoundFile &cfb);

/// Strip `#` prefix and return cabinet file name for Media table entries.
[[nodiscard]] std::string normalize_cabinet_entry(std::string_view cabinet);

/// Decode an MSI CFB UTF-16 stream name (same rules as Windows Installer).
[[nodiscard]] std::string decode_msi_entry_name(const std::u16string &name16);

} // namespace msi_util
