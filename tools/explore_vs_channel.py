"""
This script provides utilities to explore the Visual Studio channel manifest, analyze package structures, and extract content from packages.

It supports:
- Downloading and parsing channel manifests and package manifests.
- analyzing dependencies between packages.
- listing available MSVC versions.
- listing files within a package payload.
- Downloading and extracting specific packages or MSI files, including handling of associated cabinet files.

*This script is for research purposes only and should not be used in the module implementation.*
"""
import json
import sys
import urllib.request
import argparse
import re
import os
import zipfile
import io
import subprocess
import tempfile
import pprint

def get_dependencies(root_id, packages_map, filter_lambda, no_duplicate=True):
    visited = set()
    found_dependencies = dict()

    def visit(current_id):
        pkgs = packages_map.get(current_id)
        if not pkgs:
            return

        for pkg in pkgs:
            visit_key = current_id
            if visit_key in visited:
                return
            visited.add(visit_key)

            if current_id != root_id:
                if filter_lambda(current_id, pkg):
                    if no_duplicate:
                        assert current_id not in found_dependencies, f"Duplicate package id '{current_id}'"
                    found_dependencies[current_id] = pkg

            dependencies = pkg.get('dependencies', {})
            for dep_id, dep_info in dependencies.items():
                # Check 'when' condition
                if isinstance(dep_info, dict):
                    when_clause = dep_info.get('when')
                    if when_clause is not None:
                            if root_id not in when_clause:
                                continue
                
                visit(dep_id)

    visit(root_id)
    return found_dependencies

def download_manifest(root_url=None, save_to_file=False):
    if root_url is None:
        root_url = "https://aka.ms/vs/stable/channel"
        #root_url = "https://aka.ms/vs/17/release/channel"
        #root_url = "https://aka.ms/vs/16/release/channel"

    # print(f"Downloading root manifest from {root_url}...")
    with urllib.request.urlopen(root_url) as response:
        root_content = response.read()
    
    if save_to_file:
        with open("vs_manifest.json", "wb") as f:
            f.write(root_content)

    root_manifest = json.loads(root_content.decode('utf-8'))
    
    package_manifest_url = None
    for item in root_manifest.get("channelItems", []):
        if item["id"] == "Microsoft.VisualStudio.Manifests.VisualStudio":
            package_manifest_url = item["payloads"][0]["url"]
            break
    
    assert package_manifest_url is not None, "Could not find Microsoft.VisualStudio.Manifests.VisualStudio in root manifest"

    # print(f"Downloading package manifest from {package_manifest_url}...")
    with urllib.request.urlopen(package_manifest_url) as response:
        package_content = response.read()

    if save_to_file:
        with open("vs_package_manifest.json", "wb") as f:
            f.write(package_content)

    return json.loads(package_content.decode('utf-8'))


def main():
    parser = argparse.ArgumentParser(description="Visual Studio Package Analysis Tool")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Package command
    package_parser = subparsers.add_parser("package", help="Analyze packages")
    package_parser.add_argument("filter_prefix", help="Prefix to filter packages (e.g., Microsoft.VC.14.29)")

    # MSVC Package command
    package_parser = subparsers.add_parser("msvc", help="Analyze packages")
    package_parser.add_argument("--version", help="Compiler Version", default=None)

    # Version command
    version_parser = subparsers.add_parser("version", help="Show version information")

    # Download command
    download_parser = subparsers.add_parser("download", help="Download and unzip a package")
    download_parser.add_argument("destination_path", nargs='?', help="Path to unzip the package")
    download_parser.add_argument("--id", dest="package_id", required=True, help="Package ID to download")

    # Manifest command
    manifest_parser = subparsers.add_parser("manifest", help="Download manifests")

    # Files command
    files_parser = subparsers.add_parser("files", help="List files in a package")
    files_parser.add_argument("--id", dest="package_id", required=True, help="Package ID to analyze")

    # Extract MSI command
    extract_msi_parser = subparsers.add_parser("extract-msi", help="Extract MSI content")
    extract_msi_parser.add_argument("--id", dest="package_id", required=True, help="Package ID")
    extract_msi_parser.add_argument("--msi", dest="msi_name", required=True, help="MSI file name to extract")
    extract_msi_parser.add_argument("destination_path", nargs='?', help="Path to extract the MSI")

    args = parser.parse_args()

    if args.command == "manifest":
        download_manifest(save_to_file=True)
        print("Manifests downloaded to vs_manifest.json and vs_package_manifest.json")
        return

    data = download_manifest()
    assert 'packages' in data, "'packages' key not found in JSON."
    packages_map = {}
    for p in data['packages']:
        if 'id' in p and (not 'language' in p or p['language'].lower() == 'en-us'):
            packages_map.setdefault(p['id'], []).append(p)
    
    root_id = "Microsoft.VisualStudio.Product.BuildTools"
    assert root_id in packages_map, f"Root package '{root_id}' not found."

    if args.command == "package":
        filter_prefix = args.filter_prefix.lower()

        filter_lambda = lambda pid, pkg: (
            (not 'language' in pkg or pkg['language'].lower() == 'en-us') and
            pid.lower().startswith(filter_prefix)
        )

        found = get_dependencies(root_id, packages_map, filter_lambda)

        for result_id in sorted(found):
            print(result_id)
    
    
    if args.command == "msvc":
        filter_prefix = f"Microsoft.VC.{args.version}".lower()

        filter_lambda = lambda pid, pkg: (
            pid.lower().startswith(filter_prefix) and
            pid.lower().endswith(".base") and
            "spectre" not in pid.lower() and
            ".props" not in pid.lower() and
            ".servicing" not in pid.lower() and
            ".mfc" not in pid.lower() and
            ".atl" not in pid.lower() and
            ".onecore" not in pid.lower() and
            ".store" not in pid.lower() and
            ".cli" not in pid.lower() and
            ".ca." not in pid.lower()
        )

        found = get_dependencies(root_id, packages_map, filter_lambda)

        for result_id in sorted(found):
            print(result_id)
            
    elif args.command == "version":
        filter_lambda = lambda pid, pkg: (pid.lower().startswith("microsoft.vc."))
        found = get_dependencies(root_id, packages_map, filter_lambda)
        
        versions = set()
        for pid in found:
            # Extract version using regex: Microsoft.VC.<Version>...
            # Assuming version is 4 component standard (e.g. 14.29.16.11)
            # User example: "Microsoft.VC.14.29.16.11.*****"
            match = re.search(r'Microsoft\.VC\.(\d+\.\d+)\.\d+\.\d+\.', pid, re.IGNORECASE)
            if match:
                versions.add(match.group(1))

        for v in sorted(versions):
            print(v)

    elif args.command == "files":
        if args.package_id not in packages_map:
             print(f"Error: Package '{args.package_id}' not found.")
             sys.exit(1)
        
        pkgs = packages_map[args.package_id]
        for pkg in pkgs:
            payloads = pkg.get('payloads', [])
            for payload in payloads:
                if 'fileName' in payload:
                    print(payload['fileName'])

    elif args.command == "download":
        assert len(packages_map[args.package_id]) == 1
        pkg = packages_map[args.package_id][0]
        if not pkg:
            print(f"Error: Package '{args.package_id}' not found.")
            sys.exit(1)
        
        payloads = pkg.get('payloads')
        if not payloads:
             print(f"Error: No payloads found for package '{args.package_id}'.")
             sys.exit(1)
             
        url = payloads[0].get('url')
        if not url:
             print(f"Error: No URL found in the first payload of package '{args.package_id}'.")
             sys.exit(1)

        print(f"Downloading {url}...")
        with urllib.request.urlopen(url) as response:
            data = response.read()
        
        destination_path = args.destination_path
        if not destination_path:
            destination_path = args.package_id

        print(f"Unzipping to {destination_path}...")
        if not os.path.exists(destination_path):
            os.makedirs(destination_path)

        with zipfile.ZipFile(io.BytesIO(data)) as z:
            z.extractall(destination_path)

    elif args.command == "extract-msi":
        if args.package_id not in packages_map:
             print(f"Error: Package '{args.package_id}' not found.")
             sys.exit(1)
        assert len(packages_map[args.package_id]) == 1
        pkg = packages_map[args.package_id][0]
        payloads = pkg.get('payloads', [])
        target_payload = None
        for payload in payloads:
            if payload.get('fileName') == args.msi_name:
                target_payload = payload
                break
        
        if not target_payload:
            print(f"Error: MSI '{args.msi_name}' not found in package '{args.package_id}'.")
            sys.exit(1)
            
        url = target_payload.get('url')
        if not url:
             print(f"Error: No URL found for MSI '{args.msi_name}'.")
             sys.exit(1)

        # Determine output directory
        if args.destination_path:
             output_dir = os.path.abspath(args.destination_path)
        else:
             output_dir_name = args.msi_name.replace('\\', '--')
             output_dir = os.path.abspath(output_dir_name)
        
        # Create temp dir
        with tempfile.TemporaryDirectory() as temp_dir:
            print(f"Created temp dir: {temp_dir}")
            temp_msi_path = os.path.join(temp_dir, os.path.basename(args.msi_name))
            
            print(f"Downloading MSI to {temp_msi_path}...")
            # Download MSI
            with urllib.request.urlopen(url) as response:
                with open(temp_msi_path, 'wb') as f:
                    f.write(response.read())

            # List cabs
            print("Listing required .cab files...")
            ps_script = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'List-MsiCabs.ps1')
            cmd_list = ['powershell', '-ExecutionPolicy', 'Bypass', '-File', ps_script, '-MsiPath', temp_msi_path]
            
            try:
                output = subprocess.check_output(cmd_list, stderr=subprocess.STDOUT).decode('utf-8')
            except subprocess.CalledProcessError as e:
                print(f"Error running List-MsiCabs.ps1: {e.output.decode('utf-8')}")
                sys.exit(1)
                
            cab_files = [line.strip() for line in output.splitlines() if line.strip()]
            
            # Download cabs
            for cab_file in cab_files:
                # Find payload for this cab
                cab_payload = None
                for payload in payloads:
                    # Payload fileName might match cab_file exactly or be a path ending in it.
                    if payload.get('fileName') == cab_file:
                        cab_payload = payload
                        break
                    if os.path.basename(payload.get('fileName', '')) == cab_file:
                         cab_payload = payload
                         break
                
                if cab_payload:
                    cab_url = cab_payload.get('url')
                    if cab_url:
                        cab_dest = os.path.join(temp_dir, cab_file)
                        print(f"Downloading {cab_file} to {cab_dest}...")
                        with urllib.request.urlopen(cab_url) as response:
                            with open(cab_dest, 'wb') as f:
                                f.write(response.read())
                    else:
                        print(f"Warning: URL not found for cab '{cab_file}'")
                else:
                    print(f"Warning: Payload not found for cab '{cab_file}' in package")
                    pass

            print(f"Extracting to {output_dir}...")
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)

            extract_cmd = f'msiexec /a "{temp_msi_path}" /qn TARGETDIR="{output_dir}"'
            subprocess.check_call(extract_cmd)

if __name__ == "__main__":
    main()
