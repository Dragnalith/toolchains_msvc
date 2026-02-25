@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo Testing all_hosts_all_targets
pushd "%~dp0all_hosts_all_targets"
bazel run //:hello_world | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
popd

echo Testing one_host_one_target
pushd "%~dp0one_host_one_target"
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --repo_env=BAZEL_TOOLCHAINS_MSVC_HOSTS=x86 --repo_env=BAZEL_TOOLCHAINS_MSVC_TARGETS=x86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --repo_env=BAZEL_TOOLCHAINS_MSVC_HOSTS=x86 --repo_env=BAZEL_TOOLCHAINS_MSVC_TARGETS=x64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --repo_env=BAZEL_TOOLCHAINS_MSVC_HOSTS=x64 --repo_env=BAZEL_TOOLCHAINS_MSVC_TARGETS=x86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --repo_env=BAZEL_TOOLCHAINS_MSVC_HOSTS=x64 --repo_env=BAZEL_TOOLCHAINS_MSVC_TARGETS=x64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
popd

endlocal