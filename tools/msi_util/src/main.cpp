#include "cab.hpp"
#include "cfb.hpp"
#include "msi.hpp"

#include <argparse/argparse.hpp>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <optional>
#include <string_view>
#include <vector>

namespace fs = std::filesystem;

static std::vector<uint8_t> read_entire_file(const fs::path &p) {
  std::ifstream f(p, std::ios::binary | std::ios::ate);
  if (!f)
    throw std::runtime_error("cannot open file: " + p.string());
  const auto sz = f.tellg();
  f.seekg(0);
  std::vector<uint8_t> buf(static_cast<size_t>(sz));
  f.read(reinterpret_cast<char *>(buf.data()), sz);
  if (!f)
    throw std::runtime_error("read error: " + p.string());
  return buf;
}

static bool ieq_sv(std::string_view a, std::string_view b) {
  if (a.size() != b.size())
    return false;
  for (size_t i = 0; i < a.size(); ++i) {
    char ca = a[i], cb = b[i];
    if (ca >= 'A' && ca <= 'Z')
      ca += static_cast<char>('a' - 'A');
    if (cb >= 'A' && cb <= 'Z')
      cb += static_cast<char>('a' - 'A');
    if (ca != cb)
      return false;
  }
  return true;
}

static void write_file(const fs::path &root, const std::string &rel,
                       const std::vector<uint8_t> &data) {
  fs::path out = root;
  for (const auto &part : fs::path(rel)) {
    const std::string s = part.string();
    if (s == "..")
      throw std::runtime_error("invalid path in MSI file table");
    if (s == ".")
      continue;
    out /= part;
  }
  fs::create_directories(out.parent_path());
  std::ofstream f(out, std::ios::binary | std::ios::trunc);
  if (!f)
    throw std::runtime_error("cannot write: " + out.string());
  f.write(reinterpret_cast<const char *>(data.data()),
          static_cast<std::streamsize>(data.size()));
}

static int cmd_list_cab(const fs::path &msi_path) {
  auto raw = read_entire_file(msi_path);
  msi_util::CompoundFile cfb(std::move(raw));
  const auto pkg = msi_util::parse_msi(cfb);
  for (const auto &c : pkg.cab_files) {
    const std::string line = msi_util::normalize_cabinet_entry(c);
    if (!line.empty())
      std::cout << line << '\n';
  }
  return 0;
}

static int cmd_extract(const fs::path &out_dir, const fs::path &msi_path) {
  auto raw = read_entire_file(msi_path);
  msi_util::CompoundFile cfb(std::move(raw));
  const auto pkg = msi_util::parse_msi(cfb);
  const fs::path msi_abs = fs::absolute(msi_path);
  const fs::path msi_dir = msi_abs.parent_path();

  for (const std::string &cab_ref : pkg.cab_files) {
    std::vector<uint8_t> cab_bytes;
    if (!cab_ref.empty() && cab_ref[0] == '#') {
      const std::string want = msi_util::normalize_cabinet_entry(cab_ref);
      std::optional<std::vector<uint8_t>> emb;
      for (size_t sid = 0; sid < cfb.entries().size(); ++sid) {
        const auto &e = cfb.entries()[sid];
        if (e.type != 2)
          continue;
        const std::string dec = msi_util::decode_msi_entry_name(e.name16);
        if (ieq_sv(dec, want) || ieq_sv(e.name, want)) {
          emb = cfb.read_stream_sid(sid);
          break;
        }
      }
      if (!emb) {
        std::cerr << "embedded cabinet stream not found: " << want << '\n';
        return 1;
      }
      cab_bytes = std::move(*emb);
    } else {
      const fs::path cab_path = msi_dir / fs::path(cab_ref);
      cab_bytes = read_entire_file(cab_path);
    }

    const bool ok = msi_util::extract_cab(
        cab_bytes, [&](const std::string &name, const std::vector<uint8_t> &data) {
          const auto it = pkg.file_map.find(name);
          if (it == pkg.file_map.end())
            return true;
          write_file(out_dir, it->second, data);
          return true;
        });
    if (!ok) {
      std::cerr << "failed to parse cabinet\n";
      return 1;
    }
  }
  return 0;
}

int main(int argc, const char **argv) {
  argparse::ArgumentParser program("msi-util", "",
                                   argparse::default_arguments::help);

  argparse::ArgumentParser list_cmd("list-cab", "",
                                    argparse::default_arguments::help);
  list_cmd.add_argument("msi").help("path to .msi file");

  argparse::ArgumentParser extract_cmd("extract", "",
                                         argparse::default_arguments::help);
  extract_cmd.add_argument("--output-dir")
      .required()
      .help("destination directory");
  extract_cmd.add_argument("msi").help("path to .msi file");

  program.add_subparser(list_cmd);
  program.add_subparser(extract_cmd);

  try {
    program.parse_args(argc, argv);
  } catch (const std::exception &err) {
    std::cerr << err.what() << '\n';
    std::cerr << program;
    return 1;
  }

  try {
    if (program.is_subcommand_used("list-cab")) {
      return cmd_list_cab(fs::path(list_cmd.get<std::string>("msi")));
    }
    if (program.is_subcommand_used("extract")) {
      return cmd_extract(
          fs::path(extract_cmd.get<std::string>("--output-dir")),
          fs::path(extract_cmd.get<std::string>("msi")));
    }
  } catch (const std::exception &e) {
    std::cerr << e.what() << '\n';
    return 1;
  }

  std::cerr << program;
  return 1;
}
