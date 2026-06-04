param(
  [string]$AppDir = "",
  [string]$RuntimeLibDir = "",
  [string]$OutputDir = "",
  [string]$PackageRootName = "Skate3Recomp-Linux",
  [string]$ZipName = "Skate3Recomp-Linux-linux-amd64.zip"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3.0

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($AppDir)) {
  $AppDir = Join-Path $repoRoot ".tmp\skate3-linux\out\build\linux-amd64-relwithdebinfo"
}
if ([string]::IsNullOrWhiteSpace($RuntimeLibDir)) {
  $RuntimeLibDir = Join-Path $repoRoot "out\install\linux-amd64\lib"
}
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
  $OutputDir = Join-Path $repoRoot "out\release"
}

function Assert-UnderPath([string]$Path, [string]$ParentPath, [string]$Description) {
  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $fullParent = [System.IO.Path]::GetFullPath($ParentPath).TrimEnd('\') + '\'
  if (-not $fullPath.StartsWith($fullParent, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "$Description must stay under $fullParent, got $fullPath"
  }
}

function Copy-RequiredFile([string]$Source, [string]$Destination) {
  if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "Required file missing: $Source"
  }
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
  Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Assert-NoGameFiles([string]$Root) {
  $forbiddenFileNames = @("default.xex", "default.xex_uncrypted.xex", "nxeart")
  $badFiles = @(Get-ChildItem -LiteralPath $Root -Recurse -Force -File |
    Where-Object { $forbiddenFileNames -icontains $_.Name })
  $badDirs = @(Get-ChildItem -LiteralPath $Root -Recurse -Force -Directory |
    Where-Object { $_.Name -ieq "data" -and $_.FullName -notlike "*Skate 3 Files*" })
  if ($badFiles.Count -gt 0 -or $badDirs.Count -gt 0) {
    $bad = @($badFiles + $badDirs | ForEach-Object { $_.FullName })
    throw "Release package contains game-file paths:`n$($bad -join [Environment]::NewLine)"
  }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$stagingRoot = Join-Path $OutputDir "staging"
$packageRoot = Join-Path $stagingRoot $PackageRootName
$zipPath = Join-Path $OutputDir $ZipName

Assert-UnderPath $stagingRoot $OutputDir "Staging folder"
if (Test-Path -LiteralPath $packageRoot) {
  Assert-UnderPath $packageRoot $stagingRoot "Package staging folder"
  Remove-Item -LiteralPath $packageRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null

$templateRoot = Join-Path $repoRoot "packaging\linux"
if (-not (Test-Path -LiteralPath $templateRoot -PathType Container)) {
  throw "Package template folder missing: $templateRoot"
}

Get-ChildItem -LiteralPath $templateRoot -Force | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $packageRoot -Recurse -Force
}
Copy-RequiredFile -Source (Join-Path $repoRoot "README.md") -Destination (Join-Path $packageRoot "README-GitHub.md")
Copy-RequiredFile -Source (Join-Path $repoRoot "CREDITS.md") -Destination (Join-Path $packageRoot "CREDITS.md")
Copy-RequiredFile -Source (Join-Path $repoRoot "LICENSE") -Destination (Join-Path $packageRoot "LICENSE")

$appOut = Join-Path $packageRoot "app"
Copy-RequiredFile -Source (Join-Path $AppDir "skate3") -Destination (Join-Path $appOut "skate3")

$runtimeLib = Join-Path $AppDir "librexruntimerd.so"
if (-not (Test-Path -LiteralPath $runtimeLib -PathType Leaf)) {
  $runtimeLib = Join-Path $RuntimeLibDir "librexruntimerd.so"
}
Copy-RequiredFile -Source $runtimeLib -Destination (Join-Path $appOut "librexruntimerd.so")

$optionalTracy = Join-Path $AppDir "libTracyClientrd.so"
if (-not (Test-Path -LiteralPath $optionalTracy -PathType Leaf)) {
  $optionalTracy = Join-Path $RuntimeLibDir "libTracyClientrd.so"
}
if (Test-Path -LiteralPath $optionalTracy -PathType Leaf) {
  Copy-Item -LiteralPath $optionalTracy -Destination (Join-Path $appOut "libTracyClientrd.so") -Force
}

$head = (& git -C $repoRoot rev-parse HEAD).Trim()
$hashes = @(
  Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $appOut "skate3")
  Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $appOut "librexruntimerd.so")
)
if (Test-Path -LiteralPath (Join-Path $appOut "libTracyClientrd.so") -PathType Leaf) {
  $hashes += Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $appOut "libTracyClientrd.so")
}

$buildInfo = @()
$buildInfo += "Skate 3 Recomp Linux package"
$buildInfo += "Source commit: $head"
$buildInfo += "Built app source: $AppDir"
$buildInfo += "Runtime library source: $RuntimeLibDir"
$buildInfo += ""
$buildInfo += "Included app file hashes:"
$buildInfo += ($hashes | ForEach-Object {
  "{0}  {1}" -f $_.Hash, ([System.IO.Path]::GetFileName($_.Path))
})
Set-Content -LiteralPath (Join-Path $packageRoot "BUILD_INFO.txt") -Value $buildInfo -Encoding ASCII

Assert-NoGameFiles $packageRoot

if (Test-Path -LiteralPath $zipPath) {
  Remove-Item -LiteralPath $zipPath -Force
}
Push-Location $stagingRoot
try {
  Compress-Archive -Path $PackageRootName -DestinationPath $zipPath -CompressionLevel Optimal
} finally {
  Pop-Location
}

[pscustomobject]@{
  PackageRoot = $packageRoot
  ZipPath = $zipPath
  ZipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash
  AppHash = ($hashes | Where-Object { $_.Path -like "*\skate3" }).Hash
  RuntimeHash = ($hashes | Where-Object { $_.Path -like "*\librexruntimerd.so" }).Hash
}
