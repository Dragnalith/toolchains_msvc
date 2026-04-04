#include "cfb.hpp"

#include <algorithm>
#include <cstring>
#include <stdexcept>
#include <string>

namespace msi_util {

namespace {

constexpr uint32_t kEndOfChain = 0xFFFFFFFEu;
constexpr uint32_t kFreeSect = 0xFFFFFFFFu;

uint32_t u32_le_p(const uint8_t *p) {
  return static_cast<uint32_t>(p[0]) | (static_cast<uint32_t>(p[1]) << 8) |
         (static_cast<uint32_t>(p[2]) << 16) |
         (static_cast<uint32_t>(p[3]) << 24);
}

uint16_t u16_le_p(const uint8_t *p) {
  return static_cast<uint16_t>(p[0]) | (static_cast<uint16_t>(p[1]) << 8);
}

bool utf16le_to_ascii(std::string_view raw, std::string &out) {
  out.clear();
  for (size_t i = 0; i + 1 < raw.size(); i += 2) {
    uint16_t c = u16_le_p(reinterpret_cast<const uint8_t *>(raw.data() + i));
    if (c == 0)
      break;
    if (c > 127)
      return false;
    out.push_back(static_cast<char>(c));
  }
  return true;
}

bool ieq(std::string_view a, std::string_view b) {
  if (a.size() != b.size())
    return false;
  for (size_t i = 0; i < a.size(); ++i) {
    char ca = a[i], cb = b[i];
    if (ca >= 'A' && ca <= 'Z')
      ca += 32;
    if (cb >= 'A' && cb <= 'Z')
      cb += 32;
    if (ca != cb)
      return false;
  }
  return true;
}

int find_in_tree(const std::vector<CompoundFile::DirEntry> &E, int sid,
                 std::string_view want) {
  if (sid < 0 || static_cast<size_t>(sid) >= E.size())
    return -1;
  const auto &e = E[static_cast<size_t>(sid)];
  if (ieq(e.name, want))
    return sid;
  int L = find_in_tree(E, e.left, want);
  if (L >= 0)
    return L;
  return find_in_tree(E, e.right, want);
}

std::vector<std::string_view> split_path(std::string_view p) {
  std::vector<std::string_view> out;
  size_t i = 0;
  while (i < p.size()) {
    while (i < p.size() && (p[i] == '/' || p[i] == '\\'))
      ++i;
    size_t j = i;
    while (j < p.size() && p[j] != '/' && p[j] != '\\')
      ++j;
    if (j > i)
      out.emplace_back(p.data() + i, j - i);
    i = j;
  }
  return out;
}

} // namespace

CompoundFile::CompoundFile(std::vector<uint8_t> data) : data_(std::move(data)) {
  if (data_.size() < 512)
    throw std::runtime_error("file too small for OLE header");
  if (!read_header())
    throw std::runtime_error("invalid OLE compound file header");
  const uint8_t *hdr = data_.data();
  uint32_t root_sect = u32_le_p(hdr + 0x30);
  load_directory(root_sect);
  uint32_t ssat_start = u32_le_p(hdr + 0x3C);
  uint32_t num_ssat = u32_le_p(hdr + 0x40);
  load_mini_fat(ssat_start, num_ssat);
}

uint32_t CompoundFile::read_u32_le(size_t off) const {
  if (off + 4 > data_.size())
    throw std::runtime_error("read past end");
  return u32_le_p(data_.data() + off);
}

uint16_t CompoundFile::read_u16_le(size_t off) const {
  if (off + 2 > data_.size())
    throw std::runtime_error("read past end");
  return u16_le_p(data_.data() + off);
}

bool CompoundFile::read_header() {
  const uint8_t *h = data_.data();
  static const uint8_t sig[] = {0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1};
  if (std::memcmp(h, sig, 8) != 0)
    return false;
  if (read_u16_le(0x1C) != 0xFFFE)
    return false;
  uint16_t ss = read_u16_le(0x1E);
  uint16_t mss = read_u16_le(0x20);
  if (ss > 31 || mss > 31)
    return false;
  sector_size_ = 1u << ss;
  mini_sector_size_ = 1u << mss;
  mini_cutoff_ = read_u32_le(0x38);
  uint32_t num_sat = read_u32_le(0x2C);
  (void)num_sat;
  load_fat(h);
  return true;
}

void CompoundFile::load_fat(const uint8_t *hdr) {
  fat_.clear();
  const uint32_t num_sat_sectors = u32_le_p(hdr + 0x2C);
  const uint32_t *msat0 = reinterpret_cast<const uint32_t *>(hdr + 0x4C);
  const size_t spp = sector_size_ / 4;
  const size_t total_needed =
      static_cast<size_t>(num_sat_sectors) * spp;

  for (int i = 0; i < 109 && fat_.size() < total_needed; ++i) {
    uint32_t s = msat0[i];
    if (s == kEndOfChain || s == kFreeSect)
      break;
    auto sec = read_sector(s);
    for (size_t j = 0; j < sec.size() / 4 && fat_.size() < total_needed; ++j)
      fat_.push_back(u32_le_p(sec.data() + j * 4));
  }

  uint32_t msat_next = u32_le_p(hdr + 0x44);
  uint32_t num_msat = u32_le_p(hdr + 0x48);
  while (fat_.size() < total_needed && num_msat > 0 &&
         msat_next != kEndOfChain && msat_next != kFreeSect) {
    auto sec = read_sector(msat_next);
    const size_t per = sector_size_ / 4;
    for (size_t k = 0; k + 1 < per && fat_.size() < total_needed; ++k) {
      uint32_t fs = u32_le_p(sec.data() + k * 4);
      if (fs == kFreeSect || fs == kEndOfChain)
        continue;
      auto s2 = read_sector(fs);
      for (size_t j = 0; j < s2.size() / 4 && fat_.size() < total_needed; ++j)
        fat_.push_back(u32_le_p(s2.data() + j * 4));
    }
    msat_next = u32_le_p(sec.data() + (per - 1) * 4);
    --num_msat;
  }

  if (fat_.size() < total_needed)
    throw std::runtime_error("incomplete FAT table");
  fat_.resize(total_needed);
}

std::vector<uint8_t> CompoundFile::read_sector(uint32_t sect) const {
  uint64_t off = static_cast<uint64_t>(sect + 1) * sector_size_;
  if (off + sector_size_ > data_.size())
    throw std::runtime_error("sector out of range");
  return std::vector<uint8_t>(data_.begin() + static_cast<ptrdiff_t>(off),
                              data_.begin() +
                                  static_cast<ptrdiff_t>(off + sector_size_));
}

void CompoundFile::load_directory(uint32_t root_sect) {
  std::vector<uint8_t> dir_data;
  uint32_t s = root_sect;
  while (s != kEndOfChain && s != kFreeSect) {
    auto chunk = read_sector(s);
    dir_data.insert(dir_data.end(), chunk.begin(), chunk.end());
    if (static_cast<size_t>(s) >= fat_.size())
      break;
    s = fat_[s];
  }

  size_t n = dir_data.size() / 128;
  entries_.resize(n);
  for (size_t i = 0; i < n; ++i) {
    const uint8_t *e = dir_data.data() + i * 128;
    uint16_t namelen = u16_le_p(e + 0x40);
    if (namelen == 0)
      continue;
    size_t name_bytes = std::min<size_t>(namelen, 64);
    entries_[i].name16.resize(name_bytes / 2);
    for (size_t k = 0; k + 1 < name_bytes; k += 2)
      entries_[i].name16[k / 2] = u16_le_p(e + k);
    std::string ascii;
    if (!utf16le_to_ascii(
            std::string_view(reinterpret_cast<const char *>(e), name_bytes),
            ascii)) {
      entries_[i].name.assign(reinterpret_cast<const char *>(e), name_bytes);
    } else {
      entries_[i].name = std::move(ascii);
    }
    entries_[i].type = e[0x42];
    entries_[i].left = static_cast<int32_t>(u32_le_p(e + 0x44));
    entries_[i].right = static_cast<int32_t>(u32_le_p(e + 0x48));
    entries_[i].child = static_cast<int32_t>(u32_le_p(e + 0x4C));
    entries_[i].start = u32_le_p(e + 0x74);
    entries_[i].size = u32_le_p(e + 0x78);
  }
}

void CompoundFile::load_mini_fat(uint32_t ssat_start, uint32_t num_ssat) {
  mini_fat_.clear();
  uint32_t s = ssat_start;
  for (uint32_t i = 0; i < num_ssat && s != kEndOfChain && s != kFreeSect;
       ++i) {
    auto sec = read_sector(s);
    size_t n = sec.size() / 4;
    size_t old = mini_fat_.size();
    mini_fat_.resize(old + n);
    for (size_t j = 0; j < n; ++j)
      mini_fat_[old + j] = u32_le_p(sec.data() + j * 4);
    if (static_cast<size_t>(s) >= fat_.size())
      break;
    s = fat_[s];
  }
}

std::vector<uint8_t> CompoundFile::read_chain(uint32_t start, uint64_t size,
                                              bool mini) const {
  std::vector<uint8_t> out;
  if (size == 0)
    return out;
  out.reserve(static_cast<size_t>(std::min<uint64_t>(size, 1u << 30)));
  if (!mini) {
    uint32_t s = start;
    uint64_t remain = size;
    while (remain > 0 && s != kEndOfChain && s != kFreeSect) {
      auto sec = read_sector(s);
      size_t take = static_cast<size_t>(
          std::min<uint64_t>(remain, sector_size_));
      out.insert(out.end(), sec.begin(), sec.begin() + static_cast<ptrdiff_t>(take));
      remain -= take;
      if (static_cast<size_t>(s) >= fat_.size())
        break;
      s = fat_[s];
    }
  } else {
    if (entries_.empty())
      throw std::runtime_error("mini stream without root");
    const auto &root = entries_[0];
    auto mini_container = read_chain(root.start, root.size, false);
    uint32_t s = start;
    uint64_t remain = size;
    while (remain > 0 && s != kEndOfChain && s != kFreeSect) {
      uint64_t off =
          static_cast<uint64_t>(s) * static_cast<uint64_t>(mini_sector_size_);
      size_t take = static_cast<size_t>(
          std::min<uint64_t>(remain, mini_sector_size_));
      if (off + take > mini_container.size())
        throw std::runtime_error("mini stream bounds");
      out.insert(out.end(), mini_container.begin() + static_cast<ptrdiff_t>(off),
                 mini_container.begin() +
                     static_cast<ptrdiff_t>(off + take));
      remain -= take;
      if (static_cast<size_t>(s) >= mini_fat_.size())
        break;
      s = mini_fat_[s];
    }
  }
  if (out.size() > size)
    out.resize(static_cast<size_t>(size));
  return out;
}

int CompoundFile::find_sid_by_path(const std::string &path) const {
  auto parts = split_path(path);
  if (parts.empty())
    return -1;
  int cur = 0;
  for (std::string_view part : parts) {
    int ch = entries_[static_cast<size_t>(cur)].child;
    int sid = find_in_tree(entries_, ch, part);
    if (sid < 0)
      return -1;
    cur = sid;
  }
  return cur;
}

std::optional<std::vector<uint8_t>>
CompoundFile::read_stream(const std::string &path) {
  int sid = find_sid_by_path(path);
  if (sid < 0 || static_cast<size_t>(sid) >= entries_.size())
    return std::nullopt;
  const auto &e = entries_[static_cast<size_t>(sid)];
  if (e.type != 2)
    return std::nullopt;
  const bool mini = e.size > 0 && e.size < mini_cutoff_;
  try {
    return read_chain(e.start, e.size, mini);
  } catch (...) {
    return std::nullopt;
  }
}

std::optional<std::vector<uint8_t>> CompoundFile::read_stream_sid(size_t sid) {
  if (sid >= entries_.size())
    return std::nullopt;
  const auto &e = entries_[sid];
  if (e.type != 2)
    return std::nullopt;
  const bool mini = e.size > 0 && e.size < mini_cutoff_;
  try {
    return read_chain(e.start, e.size, mini);
  } catch (...) {
    return std::nullopt;
  }
}

std::optional<std::vector<uint8_t>>
CompoundFile::read_named_stream(std::string_view want) {
  for (size_t sid = 0; sid < entries_.size(); ++sid) {
    const auto &e = entries_[sid];
    if (e.type != 2)
      continue;
    if (!ieq(e.name, want))
      continue;
    const bool mini = e.size > 0 && e.size < mini_cutoff_;
    try {
      return read_chain(e.start, e.size, mini);
    } catch (...) {
      return std::nullopt;
    }
  }
  return std::nullopt;
}

} // namespace msi_util
