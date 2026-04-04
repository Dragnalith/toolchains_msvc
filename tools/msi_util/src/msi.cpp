#include "msi.hpp"

#include <algorithm>
#include <cstring>
#include <map>
#include <stdexcept>
#include <string_view>

namespace msi_util {
namespace detail {

static void utf8_append_char32(std::string &out, char32_t cp) {
  if (cp <= 0x7F) {
    out.push_back(static_cast<char>(cp));
  } else if (cp <= 0x7FF) {
    out.push_back(static_cast<char>(0xC0 | ((cp >> 6) & 0x1F)));
    out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
  } else if (cp <= 0xFFFF) {
    out.push_back(static_cast<char>(0xE0 | ((cp >> 12) & 0x0F)));
    out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
    out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
  } else {
    out.push_back(static_cast<char>(0xF0 | ((cp >> 18) & 0x07)));
    out.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3F)));
    out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
    out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
  }
}

std::string decode_msi_name(const std::u16string &name) {
  static constexpr char kAlphabet[] =
      "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz._!";
  std::string out;
  for (char16_t cu : name) {
    if (cu == 0)
      break;
    const auto r = static_cast<char32_t>(cu);
    if (r >= 0x3800 && r < 0x4800) {
      out.push_back(kAlphabet[(r - 0x3800) & 0x3F]);
      out.push_back(kAlphabet[((r - 0x3800) >> 6) & 0x3F]);
    } else if (r >= 0x4800 && r <= 0x4840) {
      out.push_back(kAlphabet[r - 0x4800]);
    } else {
      utf8_append_char32(out, r);
    }
  }
  return out;
}


std::vector<std::string> decode_strings(const std::vector<uint8_t> &string_data,
                                        const std::vector<uint8_t> &string_pool) {
  std::vector<std::string> strs;
  size_t offset = 0;
  size_t pos = 0;
  while (pos + 4 <= string_pool.size()) {
    uint16_t string_len = static_cast<uint16_t>(string_pool[pos]) |
                           (static_cast<uint16_t>(string_pool[pos + 1]) << 8);
    uint16_t occ =
        static_cast<uint16_t>(string_pool[pos + 2]) |
        (static_cast<uint16_t>(string_pool[pos + 3]) << 8);
    pos += 4;
    if (occ > 0) {
      uint32_t big_len = string_len;
      if (string_len == 0) {
        if (pos + 4 > string_pool.size())
          break;
        std::memcpy(&big_len, string_pool.data() + pos, 4);
        pos += 4;
      }
      if (offset + big_len > string_data.size())
        throw std::runtime_error("corrupt MSI string table");
      strs.emplace_back(
          reinterpret_cast<const char *>(string_data.data() + offset),
          big_len);
      offset += big_len;
    } else {
      strs.emplace_back();
    }
  }
  return strs;
}

std::string get_modern_name(std::string_view name) {
  size_t bar = std::string_view::npos;
  for (size_t i = 0; i < name.size(); ++i) {
    if (name[i] == '|') {
      bar = i;
      break;
    }
  }
  if (bar == std::string_view::npos)
    return std::string(name);
  return std::string(name.substr(bar + 1));
}

struct DirectoryRow {
  std::string directory;
  std::string directory_parent;
  std::string default_dir;
};

struct ComponentRow {
  std::string component;
  std::string component_id;
  std::string directory;
  uint16_t attributes{0};
  std::string condition;
  std::string key_path;
};

struct MediaRow {
  uint16_t disk_id{0};
  uint16_t last_seq1{0};
  uint16_t last_seq2{0};
  std::string disk_prompt;
  std::string cabinet;
  std::string volume_label;
  std::string source;
};

struct FileRow {
  std::string file;
  std::string component;
  std::string file_name;
  uint16_t file_size1{0};
  uint16_t file_size2{0};
  std::string version;
  std::string language;
  uint16_t attributes{0};
  uint16_t sequence1{0};
  uint16_t sequence2{0};
};

template <typename T>
void parse_table(const std::vector<uint16_t> &data,
                 const std::vector<std::string> &strings, std::vector<T> &out) {
  constexpr int ncols = [] {
    if constexpr (std::is_same_v<T, DirectoryRow>)
      return 3;
    if constexpr (std::is_same_v<T, ComponentRow>)
      return 6;
    if constexpr (std::is_same_v<T, MediaRow>)
      return 7;
    if constexpr (std::is_same_v<T, FileRow>)
      return 10;
    return 0;
  }();
  static_assert(ncols > 0, "");
  if (data.size() % static_cast<size_t>(ncols) != 0)
    throw std::runtime_error("invalid MSI table size");
  const size_t nrows = data.size() / static_cast<size_t>(ncols);
  out.resize(nrows);
  for (size_t i = 0; i < nrows; ++i) {
    T row{};
    for (int j = 0; j < ncols; ++j) {
      const uint16_t val = data[(nrows * static_cast<size_t>(j)) + i];
      if constexpr (std::is_same_v<T, DirectoryRow>) {
        if (j == 0)
          row.directory = strings.at(val);
        else if (j == 1)
          row.directory_parent = strings.at(val);
        else
          row.default_dir = strings.at(val);
      } else if constexpr (std::is_same_v<T, ComponentRow>) {
        if (j == 0)
          row.component = strings.at(val);
        else if (j == 1)
          row.component_id = strings.at(val);
        else if (j == 2)
          row.directory = strings.at(val);
        else if (j == 3)
          row.attributes = val;
        else if (j == 4)
          row.condition = strings.at(val);
        else
          row.key_path = strings.at(val);
      } else if constexpr (std::is_same_v<T, MediaRow>) {
        if (j == 0)
          row.disk_id = val;
        else if (j == 1)
          row.last_seq1 = val;
        else if (j == 2)
          row.last_seq2 = val;
        else if (j == 3)
          row.disk_prompt = strings.at(val);
        else if (j == 4)
          row.cabinet = strings.at(val);
        else if (j == 5)
          row.volume_label = strings.at(val);
        else
          row.source = strings.at(val);
      } else if constexpr (std::is_same_v<T, FileRow>) {
        if (j == 0)
          row.file = strings.at(val);
        else if (j == 1)
          row.component = strings.at(val);
        else if (j == 2)
          row.file_name = strings.at(val);
        else if (j == 3)
          row.file_size1 = val;
        else if (j == 4)
          row.file_size2 = val;
        else if (j == 5)
          row.version = strings.at(val);
        else if (j == 6)
          row.language = strings.at(val);
        else if (j == 7)
          row.attributes = val;
        else if (j == 8)
          row.sequence1 = val;
        else
          row.sequence2 = val;
      }
    }
    out[i] = std::move(row);
  }
}

} // namespace detail

std::string decode_msi_entry_name(const std::u16string &name16) {
  return detail::decode_msi_name(name16);
}

std::string normalize_cabinet_entry(std::string_view cabinet) {
  if (!cabinet.empty() && cabinet[0] == '#')
    return std::string(cabinet.substr(1));
  return std::string(cabinet);
}

MsiPackage parse_msi(CompoundFile &cfb) {
  std::vector<uint8_t> string_pool;
  std::vector<uint8_t> string_data;
  std::map<std::string, std::vector<uint16_t>> raw_tables;

  for (size_t sid = 0; sid < cfb.entries().size(); ++sid) {
    const auto &ent = cfb.entries()[sid];
    if (ent.type != 2)
      continue;
    const std::string dec = detail::decode_msi_name(ent.name16);
    auto data = cfb.read_stream_sid(sid);
    if (!data)
      continue;
    if (dec == "!_StringPool") {
      string_pool = std::move(*data);
    } else if (dec == "!_StringData") {
      string_data = std::move(*data);
    } else if (dec.size() > 1 && dec[0] == '!' && dec[1] != '_') {
      const std::string tname = dec.substr(1);
      const size_t n = data->size() / 2;
      std::vector<uint16_t> raw(n);
      for (size_t i = 0; i < n; ++i) {
        raw[i] = static_cast<uint16_t>((*data)[i * 2]) |
                 (static_cast<uint16_t>((*data)[i * 2 + 1]) << 8);
      }
      raw_tables[tname] = std::move(raw);
    }
  }

  if (string_pool.empty() || string_data.empty())
    throw std::runtime_error("MSI missing string pool or string data");

  const std::vector<std::string> strings =
      detail::decode_strings(string_data, string_pool);

  std::vector<detail::DirectoryRow> dirs;
  std::vector<detail::ComponentRow> comps;
  std::vector<detail::MediaRow> medias;
  std::vector<detail::FileRow> files;

  if (raw_tables.count("Directory"))
    detail::parse_table(raw_tables["Directory"], strings, dirs);
  if (raw_tables.count("Component"))
    detail::parse_table(raw_tables["Component"], strings, comps);
  if (raw_tables.count("Media"))
    detail::parse_table(raw_tables["Media"], strings, medias);
  if (raw_tables.count("File"))
    detail::parse_table(raw_tables["File"], strings, files);

  // Match List-MsiCabs.ps1: `SELECT ... FROM Media ORDER BY DiskId`
  std::stable_sort(medias.begin(), medias.end(),
                     [](const detail::MediaRow &a, const detail::MediaRow &b) {
                       return a.disk_id < b.disk_id;
                     });

  std::map<std::string, detail::DirectoryRow> dir_map;
  for (const auto &d : dirs)
    dir_map[d.directory] = d;

  std::map<std::string, std::string> dir_path_map;
  for (const auto &dir : dirs) {
    detail::DirectoryRow d = dir;
    if (d.directory == "TARGETDIR")
      d.default_dir = ".";
    std::vector<std::string> path_parts;
    path_parts.push_back(detail::get_modern_name(d.default_dir));
    std::string next_parent = d.directory_parent;
    while (!next_parent.empty()) {
      const auto it = dir_map.find(next_parent);
      if (it == dir_map.end())
        break;
      detail::DirectoryRow parent_row = it->second;
      if (parent_row.directory == "TARGETDIR")
        parent_row.default_dir = ".";
      path_parts.push_back(detail::get_modern_name(parent_row.default_dir));
      next_parent = parent_row.directory_parent;
    }
    std::string joined;
    for (auto it = path_parts.rbegin(); it != path_parts.rend(); ++it) {
      if (!joined.empty())
        joined.push_back('/');
      joined += *it;
    }
    dir_path_map[d.directory] = joined;
  }

  std::map<std::string, std::string> component_dir_map;
  for (const auto &c : comps)
    component_dir_map[c.component] = dir_path_map[c.directory];

  std::map<std::string, std::string> file_to_path;
  for (const auto &f : files) {
    const std::string dir = component_dir_map[f.component];
    const std::string base = detail::get_modern_name(f.file_name);
    if (!dir.empty())
      file_to_path[f.file] = dir + "/" + base;
    else
      file_to_path[f.file] = base;
  }

  MsiPackage pkg;
  pkg.file_map = std::move(file_to_path);
  for (const auto &m : medias) {
    if (!m.cabinet.empty())
      pkg.cab_files.push_back(m.cabinet);
  }
  return pkg;
}

} // namespace msi_util
