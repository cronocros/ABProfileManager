param(
    [string]$ProjectRoot = "E:\Dev_ai\wowadon"
)

$ErrorActionPreference = "Stop"

$addonDir = Join-Path $ProjectRoot "ABProfileManager"
$tocPath = Join-Path $addonDir "ABProfileManager.toc"
$distDir = Join-Path $ProjectRoot "dist"

if (-not (Test-Path $addonDir)) {
    throw "Addon folder not found: $addonDir"
}

if (-not (Test-Path $tocPath)) {
    throw "TOC file not found: $tocPath"
}

$tocContent = Get-Content -Path $tocPath
$versionLine = $tocContent | Where-Object { $_ -match '^## Version:\s*(.+)$' } | Select-Object -First 1
if (-not $versionLine) {
    throw "Version line not found in TOC."
}

$version = ([regex]::Match($versionLine, '^## Version:\s*(.+)$')).Groups[1].Value.Trim()
if ([string]::IsNullOrWhiteSpace($version)) {
    throw "Parsed version is empty."
}

New-Item -ItemType Directory -Force -Path $distDir | Out-Null

$zipPath = Join-Path $distDir ("ABProfileManager-v{0}.zip" -f $version)
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}

Compress-Archive -Path $addonDir -DestinationPath $zipPath -Force
Write-Output $zipPath

