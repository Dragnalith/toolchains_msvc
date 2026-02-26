@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo Testing all_hosts_all_targets (arm64 host and target)
pushd "%~dp0all_hosts_all_targets"
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk19041_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk19041_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.40 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk19041_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.33 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk19041_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.29 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk22621_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk22621_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.40 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk22621_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.33 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk22621_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.29 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk26100_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk26100_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.40 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk26100_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.33 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_arm64 --platforms=//:windows_arm64 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk26100_hostarm64_targetarm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.29 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
popd

echo Testing one_host_one_target_arm
pushd %~dp0one_host_one_target
bazel run //:hello_world --repo_env=BAZEL_TOOLCHAINS_MSVC_HOSTS=arm64 --repo_env=BAZEL_TOOLCHAINS_MSVC_TARGETS=arm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
popd

endlocal
