@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo Testing one_host_one_target_arm
pushd %~dp0one_host_one_target
bazel run //:hello_world --repo_env=BAZEL_TOOLCHAINS_MSVC_HOSTS=arm64 --repo_env=BAZEL_TOOLCHAINS_MSVC_TARGETS=arm64 | python ..\check_hello_world.py --target arm64 --compiler cl.exe --compiler-version 19.44 --winsdk-version 26100
if %errorlevel% neq 0 exit /b %errorlevel%
popd

endlocal
