#include "cab.hpp"

#include <zlib.h>

#include <cstring>
#include <stdexcept>

namespace msi_util {

namespace {

uint32_t read_u32_le(const uint8_t *p) {
  return static_cast<uint32_t>(p[0]) | (static_cast<uint32_t>(p[1]) << 8) |
         (static_cast<uint32_t>(p[2]) << 16) |
         (static_cast<uint32_t>(p[3]) << 24);
}

uint16_t read_u16_le(const uint8_t *p) {
  return static_cast<uint16_t>(p[0]) | (static_cast<uint16_t>(p[1]) << 8);
}

bool inflate_mszip_payload(const uint8_t *payload, size_t payload_len,
                             std::vector<uint8_t> &uncomp, size_t expect_uncomp,
                             const std::vector<uint8_t> *dict) {
  if (payload_len < 2 || payload[0] != 'C' || payload[1] != 'K')
    return false;
  z_stream strm{};
  strm.next_in = const_cast<Bytef *>(payload + 2);
  strm.avail_in = static_cast<uInt>(payload_len - 2);
  uncomp.resize(expect_uncomp);
  strm.next_out = uncomp.data();
  strm.avail_out = static_cast<uInt>(expect_uncomp);
  if (inflateInit2(&strm, -15) != Z_OK)
    return false;
  if (dict != nullptr && !dict->empty()) {
    if (inflateSetDictionary(&strm, dict->data(),
                             static_cast<uInt>(dict->size())) != Z_OK) {
      inflateEnd(&strm);
      return false;
    }
  }
  const int ret = inflate(&strm, Z_FINISH);
  inflateEnd(&strm);
  return ret == Z_STREAM_END && strm.total_out == expect_uncomp;
}

bool read_folder_data(const std::vector<uint8_t> &cab,
                      const uint8_t *folder_hdr, uint8_t cb_reserve_data,
                      std::vector<uint8_t> &out) {
  out.clear();
  uint32_t coff_start = read_u32_le(folder_hdr);
  uint16_t cc_fdata = read_u16_le(folder_hdr + 4);
  uint16_t type_compress = read_u16_le(folder_hdr + 6);
  const uint16_t comp_mask = 0xF;
  const uint16_t comp_none = 0;
  const uint16_t comp_mszip = 1;
  if ((type_compress & comp_mask) != comp_none &&
      (type_compress & comp_mask) != comp_mszip)
    return false;

  const size_t data_hdr_size = 8 + static_cast<size_t>(cb_reserve_data);
  size_t pos = static_cast<size_t>(coff_start);
  std::vector<uint8_t> prev_block;

  for (uint16_t bi = 0; bi < cc_fdata; ++bi) {
    if (pos + data_hdr_size > cab.size())
      return false;
    const uint8_t *d = cab.data() + pos;
    const uint16_t cb_data = read_u16_le(d + 4);
    const uint16_t cb_uncomp = read_u16_le(d + 6);
    pos += data_hdr_size;
    if (pos + cb_data > cab.size())
      return false;
    const uint8_t *payload = cab.data() + pos;
    pos += cb_data;

    if ((type_compress & comp_mask) == comp_none) {
      if (cb_data != cb_uncomp)
        return false;
      out.insert(out.end(), payload, payload + cb_data);
    } else {
      std::vector<uint8_t> block;
      const std::vector<uint8_t> *dict =
          prev_block.empty() ? nullptr : &prev_block;
      if (!inflate_mszip_payload(payload, cb_data, block, cb_uncomp, dict))
        return false;
      prev_block = block;
      out.insert(out.end(), block.begin(), block.end());
    }
  }
  return true;
}

} // namespace

bool extract_cab(const std::vector<uint8_t> &cab,
                 const std::function<bool(const std::string &name,
                                          const std::vector<uint8_t> &data)> &on_file) {
  if (cab.size() < 36)
    return false;
  if (cab[0] != 'M' || cab[1] != 'S' || cab[2] != 'C' || cab[3] != 'F')
    return false;
  if (read_u32_le(cab.data() + 4) != 0 || read_u32_le(cab.data() + 12) != 0 ||
      read_u32_le(cab.data() + 20) != 0)
    return false;
  if (cab[0x18] != 3 || cab[0x19] != 1)
    return false;
  const uint16_t flags = read_u16_le(cab.data() + 0x1E);
  if (flags & 1 || flags & 2)
    return false;

  const uint16_t c_folders = read_u16_le(cab.data() + 0x1A);
  const uint16_t c_files = read_u16_le(cab.data() + 0x1C);
  const uint32_t c_off_files = read_u32_le(cab.data() + 0x10);

  size_t off = 36;
  uint8_t cb_reserve_folder = 0;
  uint8_t cb_reserve_data = 0;

  if (flags & 4) {
    if (off + 4 > cab.size())
      return false;
    const uint16_t cb_reserve_hdr = read_u16_le(cab.data() + off);
    cb_reserve_folder = cab[off + 2];
    cb_reserve_data = cab[off + 3];
    off += 4 + static_cast<size_t>(cb_reserve_hdr);
  }

  const size_t folder_entry_size = 8 + static_cast<size_t>(cb_reserve_folder);
  std::vector<std::vector<uint8_t>> folder_data;
  folder_data.resize(c_folders);
  for (uint16_t i = 0; i < c_folders; ++i) {
    if (off + folder_entry_size > cab.size())
      return false;
    if (!read_folder_data(cab, cab.data() + off, cb_reserve_data,
                          folder_data[i]))
      return false;
    off += folder_entry_size;
  }

  if (c_off_files > cab.size())
    return false;
  off = c_off_files;
  std::vector<uint32_t> cb_file;
  std::vector<uint32_t> u_off;
  std::vector<uint16_t> i_folder;
  std::vector<std::string> names;
  cb_file.reserve(c_files);
  u_off.reserve(c_files);
  i_folder.reserve(c_files);
  names.reserve(c_files);

  for (uint16_t i = 0; i < c_files; ++i) {
    if (off + 16 > cab.size())
      return false;
    cb_file.push_back(read_u32_le(cab.data() + off));
    u_off.push_back(read_u32_le(cab.data() + off + 4));
    i_folder.push_back(read_u16_le(cab.data() + off + 8));
    off += 16;
    size_t z = off;
    while (z < cab.size() && cab[z] != 0)
      ++z;
    names.emplace_back(reinterpret_cast<const char *>(cab.data() + off), z - off);
    off = z + 1;
  }

  for (size_t i = 0; i < names.size(); ++i) {
    if (static_cast<size_t>(i_folder[i]) >= folder_data.size())
      return false;
    const auto &fd = folder_data[i_folder[i]];
    if (static_cast<uint64_t>(u_off[i]) + cb_file[i] > fd.size())
      return false;
    std::vector<uint8_t> chunk(cb_file[i]);
    std::memcpy(chunk.data(), fd.data() + u_off[i], cb_file[i]);
    if (!on_file(names[i], chunk))
      return false;
  }
  return true;
}

} // namespace msi_util
