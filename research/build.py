"""
This tool compiles minimal_cpp_project and explores various flags and behaviors of clang, clang-cl, and msvc-cl.
"""

import argparse
import os
import pathlib
import subprocess

# Minimal env for subprocesses: only TMP, TEMP and SYSTEMROOT from current environment
def _subprocess_env():
    keys = ("SYSTEMROOT", "TEMP", "TMP")
    return {k: os.environ[k] for k in keys if k in os.environ}

def find_build_env_txt() -> pathlib.Path | None:
    """Search for build_env.txt in this directory and parent directories."""
    directory = pathlib.Path(__file__).resolve().parent
    while directory != directory.parent:
        candidate = directory / "build_env.txt"
        if candidate.is_file():
            return candidate
        directory = directory.parent
    return None


def load_build_env() -> tuple[pathlib.Path, pathlib.Path, pathlib.Path, str]:
    """Load msvc_root, llvm_root, winsdk_root, winsdk_version from build_env.txt."""
    env_file = find_build_env_txt()
    if env_file is None:
        raise FileNotFoundError(
            "build_env.txt not found in this directory or any parent. "
            "Create one with: msvc_root=..., llvm_root=..., winsdk_root=..., winsdk_version=..."
        )
    values: dict[str, str] = {}
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"\'')
            if key:
                values[key] = value
    required = ("msvc_root", "llvm_root", "winsdk_root", "winsdk_version")
    missing = [k for k in required if k not in values]
    if missing:
        raise KeyError(f"build_env.txt ({env_file}) missing: {', '.join(missing)}")
    msvc_root = pathlib.Path(values["msvc_root"])
    llvm_root = pathlib.Path(values["llvm_root"])
    winsdk_root = pathlib.Path(values["winsdk_root"])
    winsdk_version = values["winsdk_version"]
    dir_checks = [
        ("msvc_root", msvc_root),
        ("llvm_root", llvm_root),
        ("winsdk_root", winsdk_root),
    ]
    bad = []
    for name, p in dir_checks:
        if not p.exists():
            bad.append(f"{name}={p} (does not exist)")
        elif not p.is_dir():
            bad.append(f"{name}={p} (not a directory)")
    if bad:
        raise FileNotFoundError(
            f"build_env.txt ({env_file}): paths must be existing directories:\n  " + "\n  ".join(bad)
        )
    return (msvc_root, llvm_root, winsdk_root, winsdk_version)

def fatal_error(message: str):
    print(f"Error: {message}")
    exit(1)
    
def check(condition: bool, message: str):
    if not condition:
        fatal_error(message)

class Environment:
    def __init__(self, msvc_root: pathlib.Path, llvm_root: pathlib.Path, winsdk_root: pathlib.Path, winsdk_version: str, verbose: bool = False):
        self.msvc_root = msvc_root
        self.cl_exe = msvc_root / "bin/Hostx64/x64/cl.exe"
        self.link_exe = msvc_root / "bin/Hostx64/x64/link.exe"
        self.lib_exe = msvc_root / "bin/Hostx64/x64/lib.exe"
        self.msvc_include = msvc_root / "include"
        self.msvc_lib = msvc_root / "lib/x64"
        self.llvm_root = llvm_root
        self.clang_exe = llvm_root / "bin/clang.exe"
        self.clang_cl_exe = llvm_root / "bin/clang-cl.exe"
        #self.lld_link_exe = llvm_root / "bin/lld-link.exe"
        self.lld_link_exe = pathlib.Path("lld-link.exe")
        self.llvm_lib_exe = llvm_root / "bin/llvm-lib.exe"
        self.winsdk_root = winsdk_root
        self.winsdk_ucrt = winsdk_root / f"include/10.0.{winsdk_version}.0/ucrt"
        self.winsdk_um = winsdk_root / f"include/10.0.{winsdk_version}.0/um"
        self.winsdk_shared = winsdk_root / f"include/10.0.{winsdk_version}.0/shared"
        self.winsdk_um_lib = winsdk_root / f"lib/10.0.{winsdk_version}.0/um/x64"
        self.winsdk_ucrt_lib = winsdk_root / f"lib/10.0.{winsdk_version}.0/ucrt/x64"
        self.verbose = verbose
    def _run(self, exe: pathlib.Path, args: list[str|pathlib.Path]):
        #check(exe.is_file(), f"{exe} is not a file")
        run_args = [str(a) for a in [exe, *args]]
        print(' '.join(run_args))
        env = os.environ.copy()
        llvm_bin = str(self.llvm_root / "bin")
        existing = env.get("PATH", "")
        env["PATH"] = llvm_bin + (os.pathsep + existing) if existing else llvm_bin
        result = subprocess.run(run_args, env=env)
        check(result.returncode == 0, f"{exe.name} failed with return code {result.returncode}")
        
    def cl(self, args: list[str|pathlib.Path]):
        self._run(self.cl_exe, args)
        
    def lib(self, args: list[str|pathlib.Path]):
        self._run(self.lib_exe, args)
        
    def link(self, args: list[str|pathlib.Path]):
        self._run(self.link_exe, args)

    def clang(self, args: list[str|pathlib.Path]):
        self._run(self.clang_exe, args)

    def clang_cl(self, args: list[str|pathlib.Path]):
        self._run(self.clang_cl_exe, args)

    def lld_link(self, args: list[str|pathlib.Path]):
        self._run(self.lld_link_exe, args)

    def llvm_lib(self, args: list[str|pathlib.Path]):
        self._run(self.llvm_lib_exe, args)

class Project:
    def __init__(self, project_root: pathlib.Path):
        self.root = project_root
        self.output = self.root / '_build'


def build_clang(env: Environment, project: Project) -> pathlib.Path | None:
    # clang uses GCC-style flags; lld-link uses MSVC-style link flags
    compile_flags = ['-std=c++20', '-nostdinc', '-g', '--target=x86_64-pc-windows-msvc', '-c', '-fms-runtime-lib=dll']
    archive_flags = ['/nologo']
    link_flags = ['/nologo', '/DEBUG', '/SUBSYSTEM:CONSOLE', '/lldignoreenv', '/nodefaultlib',
        'ucrt.lib', 'msvcrt.lib', 'msvcprt.lib', 'vcruntime.lib', 'kernel32.lib']
    bin_dir = project.output / 'clang/bin'
    imd_dir = project.output / 'clang/imd'
    system_includes = ['-isystem', env.msvc_include, '-isystem', env.winsdk_ucrt, '-isystem', env.winsdk_um, '-isystem', env.winsdk_shared]
    system_lib_paths = [f'/LIBPATH:{env.msvc_lib}', f'/LIBPATH:{env.winsdk_ucrt_lib}', f'/LIBPATH:{env.winsdk_um_lib}']

    bin_dir.mkdir(parents=True, exist_ok=True)
    imd_dir.mkdir(parents=True, exist_ok=True)

    private_lib_include = project.root / "my_lib/src"
    lib_include = project.root / "my_lib/include"
    app_include = project.root / "my_app"

    # COMPILE (clang)
    print('[1/8] CLANG App.obj')
    env.clang(compile_flags + system_includes + ['-I', private_lib_include, '-I', lib_include, '-o', imd_dir / 'App.obj', project.root / 'my_lib/src/private/App.cpp'])
    print('[2/8] CLANG Log.obj')
    env.clang(compile_flags + system_includes + ['-I', private_lib_include, '-I', lib_include, '-o', imd_dir / 'Log.obj', project.root / 'my_lib/src/private/Log.cpp'])
    print('[3/8] CLANG InternalStuff.obj')
    env.clang(compile_flags + system_includes + ['-I', private_lib_include, '-I', lib_include, '-o', imd_dir / 'InternalStuff.obj', project.root / 'my_lib/src/private/InternalStuff.cpp'])
    print('[4/8] CLANG EventLoop.obj')
    env.clang(compile_flags + system_includes + ['-I', private_lib_include, '-I', lib_include, '-o', imd_dir / 'EventLoop.obj', project.root / 'my_lib/src/private/EventLoop.cpp'])
    print('[5/8] CLANG MyApp.obj')
    env.clang(compile_flags + system_includes + ['-I', app_include, '-I', lib_include, '-o', imd_dir / 'MyApp.obj', project.root / 'my_app/MyApp.cpp'])
    print('[6/8] CLANG main.obj')
    env.clang(compile_flags + system_includes + ['-I', app_include, '-I', lib_include, '-o', imd_dir / 'main.obj', project.root / 'my_app/main.cpp'])

    # ARCHIVE (llvm-lib.exe)
    print('[7/8] llvm-lib my_lib.lib')
    env.llvm_lib(archive_flags + ['/OUT:{}'.format(imd_dir / 'my_lib.lib'), imd_dir / 'App.obj', imd_dir / 'Log.obj', imd_dir / 'InternalStuff.obj', imd_dir / 'EventLoop.obj'])

    # LINK (lld-link)
    print('[8/8] lld-link my_app.exe')
    env.lld_link(link_flags + system_lib_paths + ['/OUT:{}'.format(bin_dir / 'my_app.exe'), '/PDB:{}'.format(bin_dir / 'my_app.pdb'), '/INCREMENTAL', '/ILK:{}'.format(bin_dir / 'my_app.ilk'), imd_dir / 'main.obj', imd_dir / 'MyApp.obj', imd_dir / 'my_lib.lib'])

    exe = bin_dir / 'my_app.exe'
    print('Build successful: {}'.format(exe))
    return exe

def build_msvc(env: Environment, project: Project) -> pathlib.Path:
    compile_flags = ['/nologo', '/std:c++20', '/Zi', '/EHsc', '/MD']
    archive_flags = ['/nologo']
    link_flags = ['/nologo', '/DEBUG', '/SUBSYSTEM:CONSOLE']
    link_flags += [
        '/nodefaultlib', 
        'ucrt.lib', 
        'msvcrt.lib', 
        'msvcprt.lib', 
        'vcruntime.lib', 
        'kernel32.lib'
    ]
    bin_dir = project.output / 'msvc/bin'
    imd_dir = project.output / 'msvc/imd'
    system_includes = ['/I', env.msvc_include, '/I', env.winsdk_ucrt, '/I', env.winsdk_um, '/I', env.winsdk_shared]
    system_lib_paths = [f'/LIBPATH:{env.msvc_lib}', f'/LIBPATH:{env.winsdk_ucrt_lib}', f'/LIBPATH:{env.winsdk_um_lib}']
    
    bin_dir.mkdir(parents=True, exist_ok=True)
    imd_dir.mkdir(parents=True, exist_ok=True)
    
    private_lib_include = project.root / "my_lib/src"
    lib_include = project.root / "my_lib/include"
    app_include = project.root / "my_app"
    
    # COMPILE
    print('[1/8] CL App.obj')
    env.cl(compile_flags +  system_includes + ['/I', private_lib_include, '/I', lib_include, '/c', project.root / 'my_lib/src/private/App.cpp', f"/Fo:{imd_dir / 'App.obj'}", f'/Fd:{imd_dir / 'App.pdb'}'])
    print('[2/8] CL Log.obj')
    env.cl(compile_flags +  system_includes + ['/I', private_lib_include, '/I', lib_include, '/c', project.root / 'my_lib/src/private/Log.cpp', f"/Fo:{imd_dir / 'Log.obj'}", f'/Fd:{imd_dir / 'Log.pdb'}'])
    print('[3/8] CL InternalStuff.obj')
    env.cl(compile_flags +  system_includes + ['/I', private_lib_include, '/I', lib_include, '/c', project.root / 'my_lib/src/private/InternalStuff.cpp', f"/Fo:{imd_dir / 'InternalStuff.obj'}", f'/Fd:{imd_dir / 'InternalStuff.pdb'}'])
    print('[4/8] CL EventLoop.obj')
    env.cl(compile_flags +  system_includes + ['/I', private_lib_include, '/I', lib_include, '/c', project.root / 'my_lib/src/private/EventLoop.cpp', f"/Fo:{imd_dir / 'EventLoop.obj'}", f'/Fd:{imd_dir / 'EventLoop.pdb'}'])
    print('[5/8] CL MyApp.obj')
    env.cl(compile_flags +  system_includes + ['/I', f'"{app_include}"', '/I', lib_include, '/c', project.root / 'my_app/MyApp.cpp', f"/Fo:{imd_dir / 'MyApp.obj'}", f'/Fd:{imd_dir / 'MyApp.pdb'}'])
    print('[6/8] CL main.obj')
    env.cl(compile_flags +  system_includes + ['/I', f'"{app_include}"', '/I', lib_include, '/c', project.root / 'my_app/main.cpp', f"/Fo:{imd_dir / 'main.obj'}", f'/Fd:{imd_dir / 'main.pdb'}'])

    # ARCHIVE
    print('[7/8] LIB my_lib.lib')
    env.lib(archive_flags + ['/nologo', '/OUT:{}'.format(imd_dir / 'my_lib.lib'), imd_dir / 'App.obj', imd_dir / 'Log.obj', imd_dir / 'InternalStuff.obj', imd_dir / 'EventLoop.obj'] )
    
    # LINK
    print('[8/8] LINK my_app.exe')
    env.link(link_flags + system_lib_paths +['/nologo', '/OUT:{}'.format(bin_dir / 'my_app.exe'), '/PDB:{}'.format(bin_dir / 'my_app.pdb'), '/INCREMENTAL', '/ILK:{}'.format(bin_dir / 'my_app.ilk'), imd_dir / 'main.obj', imd_dir / 'MyApp.obj', imd_dir / 'my_lib.lib'] )
    
    exe = bin_dir / 'my_app.exe'
    print('Build successful: {}'.format(exe))
    return exe

def build_clang_cl(env: Environment, project: Project) -> pathlib.Path | None:
    # Same args as build_msvc; use clang-cl.exe and link.exe
    compile_flags = ['/nologo', '/std:c++20', '/Zi', '/EHsc', '/MD', '-nostdinc']
    archive_flags = ['/nologo']
    link_flags = ['/nologo', '/DEBUG', '/SUBSYSTEM:CONSOLE', '/nodefaultlib',
        'ucrt.lib', 'msvcrt.lib', 'msvcprt.lib', 'vcruntime.lib', 'kernel32.lib']
    bin_dir = project.output / 'clang-cl/bin'
    imd_dir = project.output / 'clang-cl/imd'
    system_includes = ['/external:I', env.msvc_include, '/external:I', env.winsdk_ucrt, '/external:I', env.winsdk_um, '/external:I', env.winsdk_shared]
    system_lib_paths = [f'/LIBPATH:{env.msvc_lib}', f'/LIBPATH:{env.winsdk_ucrt_lib}', f'/LIBPATH:{env.winsdk_um_lib}']

    bin_dir.mkdir(parents=True, exist_ok=True)
    imd_dir.mkdir(parents=True, exist_ok=True)

    private_lib_include = project.root / "my_lib/src"
    lib_include = project.root / "my_lib/include"
    app_include = project.root / "my_app"

    # COMPILE (clang-cl)
    print('[1/8] CLANG-CL App.obj')
    env.clang_cl(compile_flags + system_includes + ['/I', private_lib_include, '/I', lib_include, '/c', project.root / 'my_lib/src/private/App.cpp', f"/Fo:{imd_dir / 'App.obj'}", f'/Fd:{imd_dir / 'App.pdb'}'])
    print('[2/8] CLANG-CL Log.obj')
    env.clang_cl(compile_flags + system_includes + ['/I', private_lib_include, '/I', lib_include, '/c', project.root / 'my_lib/src/private/Log.cpp', f"/Fo:{imd_dir / 'Log.obj'}", f'/Fd:{imd_dir / 'Log.pdb'}'])
    print('[3/8] CLANG-CL InternalStuff.obj')
    env.clang_cl(compile_flags + system_includes + ['/I', private_lib_include, '/I', lib_include, '/c', project.root / 'my_lib/src/private/InternalStuff.cpp', f"/Fo:{imd_dir / 'InternalStuff.obj'}", f'/Fd:{imd_dir / 'InternalStuff.pdb'}'])
    print('[4/8] CLANG-CL EventLoop.obj')
    env.clang_cl(compile_flags + system_includes + ['/I', private_lib_include, '/I', lib_include, '/c', project.root / 'my_lib/src/private/EventLoop.cpp', f"/Fo:{imd_dir / 'EventLoop.obj'}", f'/Fd:{imd_dir / 'EventLoop.pdb'}'])
    print('[5/8] CLANG-CL MyApp.obj')
    env.clang_cl(compile_flags + system_includes + ['/I', f'"{app_include}"', '/I', lib_include, '/c', project.root / 'my_app/MyApp.cpp', f"/Fo:{imd_dir / 'MyApp.obj'}", f'/Fd:{imd_dir / 'MyApp.pdb'}'])
    print('[6/8] CLANG-CL main.obj')
    env.clang_cl(compile_flags + system_includes + ['/I', f'"{app_include}"', '/I', lib_include, '/c', project.root / 'my_app/main.cpp', f"/Fo:{imd_dir / 'main.obj'}", f'/Fd:{imd_dir / 'main.pdb'}'])

    # ARCHIVE
    print('[7/8] LIB my_lib.lib')
    env.lib(archive_flags + ['/nologo', '/OUT:{}'.format(imd_dir / 'my_lib.lib'), imd_dir / 'App.obj', imd_dir / 'Log.obj', imd_dir / 'InternalStuff.obj', imd_dir / 'EventLoop.obj'])

    # LINK (link.exe)
    print('[8/8] LINK my_app.exe')
    env.link(link_flags + system_lib_paths + ['/nologo', '/OUT:{}'.format(bin_dir / 'my_app.exe'), '/PDB:{}'.format(bin_dir / 'my_app.pdb'), '/INCREMENTAL', '/ILK:{}'.format(bin_dir / 'my_app.ilk'), imd_dir / 'main.obj', imd_dir / 'MyApp.obj', imd_dir / 'my_lib.lib'])

    exe = bin_dir / 'my_app.exe'
    print('Build successful: {}'.format(exe))
    return exe


BUILDERS = {
    "msvc": build_msvc,
    "clang": build_clang,
    "clang-cl": build_clang_cl,
}


def parse_args():
    parser = argparse.ArgumentParser(description="Compile minimal_cpp_project and explore clang/clang-cl/msvc-cl flags.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Print compiler/linker command lines")
    subparsers = parser.add_subparsers(dest="command", required=True, help="Subcommand")

    build_parser = subparsers.add_parser("build", help="Build the project")
    build_parser.add_argument(
        "compiler",
        choices=["msvc", "clang", "clang-cl"],
        help="Compiler to use",
    )

    run_parser = subparsers.add_parser("run", help="Build the project and run the output")
    run_parser.add_argument(
        "compiler",
        choices=["msvc", "clang", "clang-cl"],
        help="Compiler to use",
    )

    return parser.parse_args()


def main():
    args = parse_args()
    project_root = pathlib.Path(__file__).parent / "minimal_cpp_project"
    project = Project(project_root)
    msvc_root, llvm_root, winsdk_root, winsdk_version = load_build_env()
    env = Environment(msvc_root, llvm_root, winsdk_root, winsdk_version, verbose=args.verbose)

    build_fn = BUILDERS[args.compiler]
    exe = build_fn(env, project)

    if args.command == "run":
        if exe is None or not exe.is_file():
            fatal_error(f"Build did not produce an executable: {exe}")
        subprocess.run([str(exe)], env=_subprocess_env())


if __name__ == "__main__":
    main()