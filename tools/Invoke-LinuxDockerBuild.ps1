param(
  [string]$ImageName = "skate3-recomp-linux-builder",
  [ValidateSet("Debug", "Release", "RelWithDebInfo")]
  [string]$Configuration = "RelWithDebInfo",
  [switch]$RebuildImage,
  [switch]$Clean,
  [string]$AssetRoot = "",
  [string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"

function Resolve-FullPath([string]$PathValue) {
  if ([string]::IsNullOrWhiteSpace($PathValue)) {
    return ""
  }
  return [System.IO.Path]::GetFullPath($PathValue)
}

$repoRoot = Resolve-FullPath (Join-Path $PSScriptRoot "..")
$dockerfile = Join-Path $repoRoot "docker/linux-amd64/Dockerfile"
$dockerContext = Join-Path $repoRoot "docker/linux-amd64"
$assetRootResolved = Resolve-FullPath $AssetRoot
$projectRootResolved = Resolve-FullPath $ProjectRoot

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw "docker was not found in PATH. Install Docker Desktop first."
}

if (($assetRootResolved -and -not $projectRootResolved) -or (-not $assetRootResolved -and $projectRootResolved)) {
  throw "AssetRoot and ProjectRoot must be provided together. Omit both to build the Linux SDK only."
}

if ($assetRootResolved -and -not (Test-Path -LiteralPath $assetRootResolved -PathType Container)) {
  throw "AssetRoot not found: $assetRootResolved"
}

if ($Clean) {
  foreach ($path in @(
    (Join-Path $repoRoot "out\build\linux-amd64"),
    (Join-Path $repoRoot "out\install\linux-amd64")
  )) {
    if (Test-Path -LiteralPath $path) {
      Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
  if ($projectRootResolved -and (Test-Path -LiteralPath $projectRootResolved)) {
    Remove-Item -LiteralPath $projectRootResolved -Recurse -Force -ErrorAction SilentlyContinue
  }
}

if ($projectRootResolved) {
  New-Item -ItemType Directory -Force -Path $projectRootResolved | Out-Null
}

$imageExists = $false
try {
  docker image inspect $ImageName *> $null
  $imageExists = $true
} catch {
  $imageExists = $false
}

if ($RebuildImage -or -not $imageExists) {
  Write-Host "Building Docker image $ImageName..."
  & docker build -t $ImageName -f $dockerfile $dockerContext
  if ($LASTEXITCODE -ne 0) {
    throw "docker build failed"
  }
}

$buildPreset = switch ($Configuration) {
  "Debug" { "linux-amd64-debug" }
  "Release" { "linux-amd64-release" }
  default { "linux-amd64-relwithdebinfo" }
}

$generatedPreset = switch ($Configuration) {
  "Debug" { "linux-amd64-debug" }
  "Release" { "linux-amd64-release" }
  default { "linux-amd64-relwithdebinfo" }
}

$cleanSnippet = ""

$projectSnippet = ""
if ($assetRootResolved -and $projectRootResolved) {
  $projectSnippet = @"
if [ ! -f /project/skate3_manifest.toml ]; then
  /work/out/install/linux-amd64/bin/rexglue init \
    --project-name Skate3 \
    --xex-path /assets/default.xex_uncrypted.xex \
    --game-root /assets \
    --project-root /project
fi
/work/out/install/linux-amd64/bin/rexglue codegen /project/skate3_manifest.toml
cd /project
cmake --preset $generatedPreset -DCMAKE_PREFIX_PATH=/work/out/install/linux-amd64
cmake --build --preset $generatedPreset --target skate3 --parallel
"@
}

$containerScript = @"
set -euo pipefail
$cleanSnippet
if [ -d /work/.git ]; then
  git config --global --add safe.directory /work
  git -C /work submodule update --init --recursive
fi
cmake --preset linux-amd64 -DCMAKE_C_COMPILER=/usr/bin/clang-20 -DCMAKE_CXX_COMPILER=/usr/bin/clang++-20
cmake --build --preset $buildPreset --target install --parallel
$projectSnippet
"@

$dockerArgs = @(
  "run", "--rm",
  "-v", "${repoRoot}:/work",
  "-w", "/work"
)

if ($assetRootResolved) {
  $dockerArgs += @("-v", "${assetRootResolved}:/assets:ro")
}
if ($projectRootResolved) {
  $dockerArgs += @("-v", "${projectRootResolved}:/project")
}

$dockerArgs += @($ImageName, "bash", "-lc", $containerScript)

Write-Host "Running Linux Docker build..."
& docker @dockerArgs
if ($LASTEXITCODE -ne 0) {
  throw "docker run failed"
}

Write-Host "Done."
Write-Host "SDK install: $repoRoot\out\install\linux-amd64"
if ($projectRootResolved) {
  Write-Host "Generated project: $projectRootResolved"
}
