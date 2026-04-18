param(
    [string]$ProjectRoot = "E:\Dev_ai\wowaddon"
)

$ErrorActionPreference = "Stop"

$addonDir = Join-Path $ProjectRoot "ABProfileManager"
$tocPath = Join-Path $addonDir "ABProfileManager.toc"
$distDir = Join-Path $ProjectRoot "dist"
$archiveDistDir = Join-Path $distDir "archive"
$backupRoot = Join-Path $ProjectRoot "backups"
$sourceBackupDir = Join-Path $backupRoot "source"

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
New-Item -ItemType Directory -Force -Path $archiveDistDir | Out-Null
New-Item -ItemType Directory -Force -Path $sourceBackupDir | Out-Null

$zipPath = Join-Path $distDir ("ABProfileManager-v{0}.zip" -f $version)
$currentZipName = Split-Path -Path $zipPath -Leaf

Get-ChildItem -Path $distDir -File -Filter "ABProfileManager-v*.zip" | Where-Object {
    $_.Name -ne $currentZipName
} | ForEach-Object {
    Move-Item -Force -LiteralPath $_.FullName -Destination (Join-Path $archiveDistDir $_.Name)
}

if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}

Compress-Archive -Path $addonDir -DestinationPath $zipPath -Force

$backupTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupZipPath = Join-Path $sourceBackupDir ("ABProfileManager-source-v{0}-{1}.zip" -f $version, $backupTimestamp)
$backupItems = Get-ChildItem -Path $ProjectRoot -Force | Where-Object {
    $_.Name -notin @(".git", "dist", "backups")
}

if (-not $backupItems) {
    throw "No backup source items found in project root."
}

Compress-Archive -Path $backupItems.FullName -DestinationPath $backupZipPath -Force

Write-Output ("Release package: {0}" -f $zipPath)
Write-Output ("Archived local packages: {0}" -f $archiveDistDir)
Write-Output ("Source backup: {0}" -f $backupZipPath)
