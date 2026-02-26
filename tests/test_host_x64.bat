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
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk19041_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.44 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk19041_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk19041_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.44 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk19041_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk19041_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.40 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk19041_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.40 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk19041_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.40 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk19041_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.40 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk19041_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.33 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk19041_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.33 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk19041_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.33 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk19041_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.33 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk19041_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.29 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk19041_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.29 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk19041_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.29 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk19041_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.29 --winsdk-version 19041
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk22621_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.44 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk22621_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk22621_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.44 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk22621_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk22621_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.40 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk22621_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.40 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk22621_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.40 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk22621_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.40 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk22621_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.33 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk22621_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.33 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk22621_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.33 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk22621_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.33 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk22621_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.29 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk22621_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.29 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk22621_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.29 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk22621_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.29 --winsdk-version 22621
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk26100_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk26100_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk26100_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.44_winsdk26100_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk26100_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.40 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk26100_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.40 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk26100_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.40 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.40_winsdk26100_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.40 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk26100_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.33 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk26100_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.33 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk26100_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.33 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.33_winsdk26100_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.33 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk26100_hostx86_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.29 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x86 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk26100_hostx86_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.29 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x86 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk26100_hostx64_targetx86 | python ..\check_hello_world.py --target x86 --compiler cl.exe --compiler-version 19.29 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
bazel run //:hello_world --host_platform=//:windows_x64 --platforms=//:windows_x64 --extra_toolchains=@msvc_toolchains//:msvc_14.29_winsdk26100_hostx64_targetx64 | python ..\check_hello_world.py --target x64 --compiler cl.exe --compiler-version 19.29 --winsdk-version 26100
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