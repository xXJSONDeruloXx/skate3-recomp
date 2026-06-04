param(
  [string]$PackageZip = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3.0

$repoRoot = Split-Path -Parent $PSScriptRoot
$packageRoot = Join-Path $repoRoot "packaging\linux"
$packager = Join-Path $repoRoot "tools\New-Skate3LinuxReleasePackage.ps1"

if (-not (Test-Path -LiteralPath $packager -PathType Leaf)) {
  throw "Packager script not found: $packager"
}

function Require-Contains([string]$Text, [string]$Needle) {
  if ($Text -notmatch [regex]::Escape($Needle)) {
    throw "Expected text to contain: $Needle"
  }
}

$readme = Get-Content -LiteralPath (Join-Path $packageRoot "README.txt") -Raw
$dropNote = Get-Content -LiteralPath (Join-Path $packageRoot "Skate 3 Files\Put Skate 3 files here.txt") -Raw
$launcher = Get-Content -LiteralPath (Join-Path $packageRoot "Launch Skate 3 Recomp.sh") -Raw

Require-Contains $readme "default.xex_uncrypted.xex"
Require-Contains $readme "Launch Skate 3 Recomp.sh"
Require-Contains $dropNote "default.xex_uncrypted.xex"
Require-Contains $launcher "Skate 3 Files"
Require-Contains $launcher "librexruntimerd.so"

if (-not [string]::IsNullOrWhiteSpace($PackageZip)) {
  if (-not (Test-Path -LiteralPath $PackageZip -PathType Leaf)) {
    throw "Package zip not found: $PackageZip"
  }

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [System.IO.Compression.ZipFile]::OpenRead($PackageZip)
  try {
    $entryNames = @($zip.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
    foreach ($required in @(
      "Skate3Recomp-Linux/Launch Skate 3 Recomp.sh",
      "Skate3Recomp-Linux/Launch Skate 3 Recomp.desktop",
      "Skate3Recomp-Linux/app/skate3",
      "Skate3Recomp-Linux/app/librexruntimerd.so"
    )) {
      if ($entryNames -notcontains $required) {
        throw "Package zip is missing $required"
      }
    }
  } finally {
    $zip.Dispose()
  }
}

"Linux package template checks passed"
