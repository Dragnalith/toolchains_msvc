"""Rule wrapping MSBuild so that C++ projects build with the hermetic MSVC and Windows SDK.

The launcher points MSBuild at the staged trees instead of a Visual Studio installation, for an
x64 host. Paths are relative to the execroot, which is the working directory of Bazel actions.
"""

_LAUNCHER = """@echo off
setlocal
set "MSVC=%CD%\\{msvc}\\"
set "WINSDK=%CD%\\{winsdk}\\"
set "WINSDK_VERSION={winsdk_version}"
set "WINSDK_INCLUDE=%WINSDK%Include\\%WINSDK_VERSION%"
set /p VCTOOLS_VERSION=<"%MSVC%Auxiliary\\Build\\Microsoft.VCToolsVersion.default.txt"
:: Tracker and link look up cl.exe and rc.exe on PATH.
set "PATH=%MSVC%Tools\\bin\\Hostx64\\x64;%WINSDK%bin\\%WINSDK_VERSION%\\x64;%PATH%"
:: Every directory keeps its trailing backslash, doubled so as not to escape the closing quote.
"%MSVC%MSBuild\\Current\\Bin\\amd64\\MSBuild.exe" ^
  -p:DisableRegistryUse=true ^
  "-p:VCTargetsPath=%CD%\\{vc_targets}\\\\" ^
  "-p:VCInstallDir_{vc_version}=%MSVC%\\" ^
  "-p:VCToolsInstallDir_{vc_version}=%MSVC%Tools\\\\" ^
  "-p:VCToolsRedistInstallDir_{vc_version}=%MSVC%Redist\\\\" ^
  "-p:VCToolsVersion=%VCTOOLS_VERSION%" ^
  "-p:WindowsSdkDir=%WINSDK%\\" ^
  "-p:WindowsSdkDir_10=%WINSDK%\\" ^
  "-p:UniversalCRTSdkDir_10=%WINSDK%\\" ^
  "-p:UCRTContentRoot=%WINSDK%\\" ^
  "-p:WindowsTargetPlatformVersion=%WINSDK_VERSION%" ^
  "-p:WindowsSDK_IncludePath=%WINSDK_INCLUDE%\\um%%3B%WINSDK_INCLUDE%\\shared%%3B%WINSDK_INCLUDE%\\winrt%%3B%WINSDK_INCLUDE%\\cppwinrt" ^
  "-p:WindowsSDK_ExecutablePath_x64=%WINSDK%bin\\%WINSDK_VERSION%\\x64" ^
  "-p:WindowsSDK_LibraryPath_x64=%WINSDK%Lib\\%WINSDK_VERSION%\\um\\x64" ^
  "-p:WindowsSDK_LibraryPath_x86=%WINSDK%Lib\\%WINSDK_VERSION%\\um\\x86" ^
  "-p:WindowsSDK_LibraryPath_arm64=%WINSDK%Lib\\%WINSDK_VERSION%\\um\\arm64" ^
  -p:PreferredToolArchitecture=x64 ^
  -p:SpectreMitigation=false ^
  %*
"""

def _msbuild_impl(ctx):
    vc_targets = ctx.file.vc_targets.dirname
    launcher = ctx.actions.declare_file(ctx.label.name + ".bat")
    ctx.actions.write(launcher, _LAUNCHER.format(
        msvc = ctx.file.vc_targets.owner.workspace_root.replace("/", "\\"),
        winsdk = ctx.attr.winsdk.label.workspace_root.replace("/", "\\"),
        winsdk_version = "10.0.{}.0".format(ctx.attr.winsdk_version),
        vc_targets = vc_targets.replace("/", "\\"),
        vc_version = vc_targets.rsplit("/", 1)[1].removeprefix("v"),  # VCInstallDir_170 for v170
    ), is_executable = True)
    return DefaultInfo(
        executable = launcher,
        runfiles = ctx.runfiles(transitive_files = depset(transitive = [ctx.attr.msvc.files, ctx.attr.winsdk.files])),
    )

msbuild = rule(
    implementation = _msbuild_impl,
    executable = True,
    attrs = {
        "msvc": attr.label(mandatory = True, doc = "All files of an MSVC repo."),
        "vc_targets": attr.label(mandatory = True, allow_single_file = True, doc = "Microsoft.Cpp.Default.props of the MSVC repo."),
        "winsdk": attr.label(mandatory = True, doc = "All files of a Windows SDK repo."),
        "winsdk_version": attr.string(mandatory = True, doc = "Windows SDK build number, e.g. 26100."),
    },
)
