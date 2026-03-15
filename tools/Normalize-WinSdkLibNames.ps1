param(
  [Parameter(Mandatory = $true)]
  [string]$LibRoot
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $LibRoot)) {
    Write-Error "Expected WinSDK Lib directory was not found: $LibRoot"
    exit 1
}

$LibRoot = (Resolve-Path -LiteralPath $LibRoot).Path

Get-ChildItem -LiteralPath $LibRoot -Recurse -File | ForEach-Object {
    $lowerName = $_.Name.ToLowerInvariant()
    if ($_.Name -cne $lowerName) {
        $tempName = "{0}.cursor_tmp_lower_{1}" -f $_.Name, [guid]::NewGuid().ToString("N")
        Rename-Item -LiteralPath $_.FullName -NewName $tempName
        Rename-Item -LiteralPath (Join-Path $_.DirectoryName $tempName) -NewName $lowerName
    }
}
