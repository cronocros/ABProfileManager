param(
    [string]$CatalogSource = "DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua",
    [string]$ScoringSource = "DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua"
)

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))

function Resolve-RepoPath {
    param(
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

function Invoke-PythonStep {
    param(
        [string]$Label,
        [string]$Script,
        [string[]]$Arguments = @()
    )

    Write-Output ("==> {0}" -f $Label)
    & python $Script @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("Step failed with exit code {0}: {1}" -f $LASTEXITCODE, $Label)
    }
    Write-Output ("<== Completed: {0}" -f $Label)
}

$catalogPath = Resolve-RepoPath $CatalogSource
$scoringPath = Resolve-RepoPath $ScoringSource

if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
    throw "Catalog source not found: $catalogPath"
}

if (-not (Test-Path -LiteralPath $scoringPath -PathType Leaf)) {
    throw "Scoring source not found: $scoringPath"
}

Write-Output "Rebuilding BIS database."
Write-Output ("Repository root: {0}" -f $repoRoot)
Write-Output ("Catalog source: {0}" -f $catalogPath)
Write-Output ("Scoring source: {0}" -f $scoringPath)

Push-Location $repoRoot
try {
    Invoke-PythonStep "Build BIS catalog" "scripts/build_bis_catalog.py" @("--addon-db", $catalogPath)
    Invoke-PythonStep "Build BIS runtime scoring" "scripts/build_bis_runtime_scoring.py" @("--source", $scoringPath)
    Invoke-PythonStep "Validate Myth preview selector and overrides" "scripts/validate_bis_mythic_vault_links.py"
    Invoke-PythonStep "Validate Encounter Journal landing data" "scripts/validate_bis_encounter_journal.py"
    Invoke-PythonStep "Validate BIS catalog" "scripts/validate_bis_catalog.py"
    Invoke-PythonStep "Audit BIS data" "scripts/audit_bis_data.py"
}
finally {
    Pop-Location
}

Write-Output "BIS database rebuild completed successfully."
