[CmdletBinding()]
param(
    [string]$Version
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$tocPath = Join-Path $repoRoot "HousingNudge.toc"

if (-not (Test-Path -LiteralPath $tocPath)) {
    throw "Could not find HousingNudge.toc at $tocPath"
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $tocText = Get-Content -LiteralPath $tocPath -Raw
    $match = [regex]::Match($tocText, '(?m)^##\s*Version:\s*(\S+)\s*$')
    if (-not $match.Success) {
        throw "Could not read ## Version from HousingNudge.toc."
    }
    $Version = $match.Groups[1].Value
}

$distRoot = Join-Path $repoRoot "dist"
$stageDir = Join-Path $distRoot "HousingNudge"

if (Test-Path -LiteralPath $stageDir) {
    Remove-Item -LiteralPath $stageDir -Recurse -Force
}
New-Item -ItemType Directory -Path $stageDir -Force | Out-Null

$runtimeFiles = @(
    "HousingNudge.toc",
    "Core.lua",
    "Pulse.lua",
    "UI.lua"
)

foreach ($file in $runtimeFiles) {
    $source = Join-Path $repoRoot $file
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Missing runtime file: $file"
    }
    Copy-Item -LiteralPath $source -Destination $stageDir -Force
}

$zipPath = Join-Path $distRoot ("HousingNudge-" + $Version + ".zip")
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -LiteralPath $stageDir -DestinationPath $zipPath -CompressionLevel Optimal
Write-Host "Created $zipPath"
