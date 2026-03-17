"""Repository rule for exposing a lock file and pin target."""

def _lock_file_repo_impl(ctx):
    ctx.file("lock.json", ctx.attr.lock_json + "\n")
    raw_lock_file_path = ctx.attr.lock_file_path

    if not raw_lock_file_path:
        ctx.file("pin.bat", """@echo off
if "%BUILD_WORKSPACE_DIRECTORY%"=="" echo BUILD_WORKSPACE_DIRECTORY is not set
if "%BUILD_WORKSPACE_DIRECTORY%"=="" exit /b 1
echo No lock file destination configured. Add toolchain.lock(file = "...") to MODULE.bazel.
exit /b 1
""")
    else:
        lock_file_path = raw_lock_file_path.replace("/", "\\")
        ctx.file("pin.bat", """@echo off
if "%BUILD_WORKSPACE_DIRECTORY%"=="" echo BUILD_WORKSPACE_DIRECTORY is not set
if "%BUILD_WORKSPACE_DIRECTORY%"=="" exit /b 1
set "TARGET_PATH=%BUILD_WORKSPACE_DIRECTORY%\\{lock_file_path}"
for %%I in ("%TARGET_PATH%") do set "TARGET_DIR=%%~dpI"
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%" >nul 2>nul
if errorlevel 1 exit /b 1
copy /Y "%~dp0lock.json" "%TARGET_PATH%" >nul
if errorlevel 1 exit /b 1
echo Wrote %TARGET_PATH%
""".format(lock_file_path = lock_file_path))

    ctx.file("BUILD.bazel", """package(default_visibility = ["//visibility:public"])

exports_files(["lock.json", "pin.bat"])
""")

lock_file_repo = repository_rule(
    implementation = _lock_file_repo_impl,
    attrs = {
        "lock_json": attr.string(mandatory = True),
        "lock_file_path": attr.string(mandatory = False, default = ""),
    },
)
