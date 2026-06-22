# Regenerate version.json (and copy the jar) for a new Sight SMP release.
# Usage:  powershell -ExecutionPolicy Bypass -File release.ps1 -Version 1.0.1 [-Jar path\to\sight-1.0.1.jar]
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$Jar
)
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

if (-not $Jar) {
    $candidate = Get-ChildItem -Path (Join-Path $repo '..\..\output') -Filter 'sight-*.jar' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($candidate) { $Jar = $candidate.FullName }
}
if (-not $Jar -or -not (Test-Path $Jar)) { throw "Pass -Jar <path to the built sight jar>" }

# major.minor.patch -> packed code, matching the mod + server gate.
$parts = (($Version -split '[-+]')[0]) -split '\.'
function P($i) { if ($i -lt $parts.Count) { [int]$parts[$i] } else { 0 } }
$code = (P 0) * 1000000 + (P 1) * 1000 + (P 2)

$jarName = "sight-$Version.jar"
Copy-Item $Jar (Join-Path $repo $jarName) -Force
$sha  = (Get-FileHash -Algorithm SHA256 (Join-Path $repo $jarName)).Hash.ToLower()
$size = (Get-Item (Join-Path $repo $jarName)).Length

$json = @"
{
  "version": "$Version",
  "versionCode": $code,
  "url": "https://raw.githubusercontent.com/ashrihan-sketch/sight-smp-pack/main/$jarName",
  "filename": "$jarName",
  "sha256": "$sha",
  "fileSize": $size,
  "fabricApiUrl": "https://cdn.modrinth.com/data/P7dR8mSH/versions/i5tSkVBH/fabric-api-0.141.3%2B1.21.11.jar",
  "fabricApiFilename": "fabric-api-0.141.3+1.21.11.jar"
}
"@
Set-Content -Path (Join-Path $repo 'version.json') -Value $json -Encoding ascii

Write-Output "version.json updated -> $Version (code $code)"
Write-Output "sha256 $sha  size $size"
Write-Output "Next:  git add -A; git commit -m `"release $Version`"; git push"
