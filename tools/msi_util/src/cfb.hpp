#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace msi_util {

/// Minimal read-only Compound File Binary (OLE) reader for MSI files.
class CompoundFile {
public:
  struct DirEntry {
    std::string name;
    std::u16string name16;
    uint8_t type{0};
    int32_t left{-1};
    int32_t right{-1};
    int32_t child{-1};
    uint32_t start{0};
    uint64_t size{0};
  };

  explicit CompoundFile(std::vector<uint8_t> data);

  [[nodiscard]] std::optional<std::vector<uint8_t>>
  read_stream(const std::string &path);

  /// Case-insensitive match on a single stream leaf name (e.g. `!File`).
  [[nodiscard]] std::optional<std::vector<uint8_t>>
  read_named_stream(std::string_view leaf);

  [[nodiscard]] const std::vector<DirEntry> &entries() const { return entries_; }

  [[nodiscard]] std::optional<std::vector<uint8_t>> read_stream_sid(size_t sid);

  [[nodiscard]] const std::vector<uint8_t> &data() const { return data_; }

private:
  std::vector<uint8_t> data_;
  uint32_t sector_size_{512};
  uint32_t mini_sector_size_{64};
  uint32_t mini_cutoff_{4096};
  std::vector<uint32_t> fat_;
  std::vector<uint32_t> mini_fat_;

  std::vector<DirEntry> entries_;

  [[nodiscard]] uint32_t read_u32_le(size_t off) const;
  [[nodiscard]] uint16_t read_u16_le(size_t off) const;
  [[nodiscard]] bool read_header();
  void load_fat(const uint8_t *hdr);
  [[nodiscard]] std::vector<uint8_t> read_sector(uint32_t sect) const;
  void load_directory(uint32_t root_sect);
  void load_mini_fat(uint32_t ssat_start, uint32_t num_ssat);
  [[nodiscard]] std::vector<uint8_t>
  read_chain(uint32_t start, uint64_t size, bool mini) const;
  [[nodiscard]] int find_sid_by_path(const std::string &path) const;
};

} // namespace msi_util
