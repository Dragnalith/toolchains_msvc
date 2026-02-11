param(
  [Parameter(Mandatory = $true)]
  [string]$MsiPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $MsiPath)) {
    Write-Error "File not found: $MsiPath"
    exit 1
}

$MsiPath = (Resolve-Path $MsiPath).Path

# Helper: call a COM method via reflection (required for WindowsInstaller COM in pwsh)
function Invoke-ComMethod($obj, [string]$method, $params) {
    $obj.GetType().InvokeMember($method, "InvokeMethod", $null, $obj, $params)
}

# Helper: get a COM property via reflection
function Get-ComProperty($obj, [string]$property, $params) {
    $obj.GetType().InvokeMember($property, "GetProperty", $null, $obj, $params)
}

function Invoke-MsiQuery {
  param(
    [Parameter(Mandatory=$true)] $Database,
    [Parameter(Mandatory=$true)] [string]$Sql
  )

  try {
      $view = Invoke-ComMethod $Database "OpenView" @($Sql)
      Invoke-ComMethod $view "Execute" $null | Out-Null

      $rows = @()
      while ($true) {
        $rec = Invoke-ComMethod $view "Fetch" $null
        if ($null -eq $rec) { break }
        $fieldCount = Get-ComProperty $rec "FieldCount" $null
        $row = @()
        for ($i = 1; $i -le $fieldCount; $i++) {
          try {
             $val = Get-ComProperty $rec "StringData" @($i)
             $row += $val
          } catch {
             $row += $null
          }
        }
        $rows += ,$row
      }

      Invoke-ComMethod $view "Close" $null | Out-Null
      return $rows
  } catch {
      Write-Output "Debug: Query failed for SQL: $Sql. Error: $_"
      return @()
  }
}

try {
    # Open MSI database read-only (0)
    $installerType = [Type]::GetTypeFromProgID("WindowsInstaller.Installer")
    $installer = [Activator]::CreateInstance($installerType)
    $db = Invoke-ComMethod $installer "OpenDatabase" @($MsiPath, [Int32]0)

    # Read Media table: DiskId, LastSequence, Cabinet, VolumeLabel, Source
    $mediaRows = Invoke-MsiQuery -Database $db -Sql 'SELECT `DiskId`, `LastSequence`, `Cabinet`, `VolumeLabel`, `Source` FROM `Media` ORDER BY `DiskId`'

    # If no Media table rows, there are no cabinets to report this way.
    if ($mediaRows.Count -eq 0) {
      Write-Output "No Media table rows found. MSI may be uncompressed or nonstandard."
      exit 0
    }

    # Build media objects
    $media = foreach ($r in $mediaRows) {
      [pscustomobject]@{
        DiskId       = [int]$r[0]
        LastSequence = if ($r[1]) { [int]$r[1] } else { $null }
        Cabinet      = $r[2]
        VolumeLabel  = $r[3]
        Source       = $r[4]
      }
    }

    # Determine if MSI uses File.Sequence at all
    $fileSeqRows = Invoke-MsiQuery -Database $db -Sql 'SELECT MIN(`Sequence`), MAX(`Sequence`) FROM `File`'

    [int]$minSeq = 0
    [int]$maxSeq = 0
    $hasFileSeq = $false
    if ($fileSeqRows.Count -gt 0 -and $fileSeqRows[0].Count -ge 2) {
      $minSeqStr = $fileSeqRows[0][0]
      $maxSeqStr = $fileSeqRows[0][1]
      if ($minSeqStr -and $maxSeqStr) {
        $minSeq = [int]$minSeqStr
        $maxSeq = [int]$maxSeqStr
        $hasFileSeq = $true
      }
    }

    # Map each DiskId to a Sequence range using LastSequence boundaries
    $sortedMedia = $media | Sort-Object DiskId
    $prevLast = 0
    $diskRanges = foreach ($m in $sortedMedia) {
      $start = $prevLast + 1
      $end = if ($m.LastSequence) { $m.LastSequence } else { $null }
      $prevLast = if ($m.LastSequence) { $m.LastSequence } else { $prevLast }

      [pscustomobject]@{
        DiskId = $m.DiskId
        StartSequence = $start
        EndSequence = $end
        Cabinet = $m.Cabinet
        VolumeLabel = $m.VolumeLabel
        Source = $m.Source
      }
    }

    # Output one .cab filename per line to stdout
    foreach ($d in $diskRanges) {
      $cab = $d.Cabinet
      if ([string]::IsNullOrWhiteSpace($cab)) { continue }
      $cabName = if ($cab.StartsWith("#")) { $cab.TrimStart("#") } else { $cab }
      Write-Output $cabName
    }

} catch {
    Write-Error "Fatal error: $_"
    exit 1
}
