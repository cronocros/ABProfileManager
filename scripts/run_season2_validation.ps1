param(
    [switch]$Strict
)

# 시즌 2(v1.12.0) 작업용 통합 검증.
#
# 순서: Lua 전체 파싱 -> 공백 오류 -> 범위 보호 -> 아이템 레벨표 -> 로케일 계약
#       -> 기존 BIS 회귀 검증.
#
# -Strict를 주면 아이템 레벨표에서 외부 가이드만 근거인 값을 실패로 처리한다.
# 릴리스 패키징 직전에는 반드시 -Strict로 실행한다.

$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))

function Invoke-Step {
    param(
        [string]$Label,
        [scriptblock]$Action
    )

    Write-Output ("==> {0}" -f $Label)
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw ("검증 실패 (종료 코드 {0}): {1}" -f $LASTEXITCODE, $Label)
    }
    Write-Output ("<== 통과: {0}" -f $Label)
}

function Invoke-PythonStep {
    param(
        [string]$Label,
        [string]$Script,
        [string[]]$Arguments = @()
    )

    Invoke-Step $Label { & python $Script @Arguments }
}

Write-Output "시즌 2 검증을 시작합니다."
Write-Output ("저장소 경로: {0}" -f $repoRoot)
if ($Strict) {
    Write-Output "모드: strict (가이드 전용 출처를 실패로 처리)"
} else {
    Write-Output "모드: 일반 (가이드 전용 출처는 경고)"
}

$itemLevelArgs = @()
if ($Strict) {
    $itemLevelArgs += "--strict"
}

Push-Location $repoRoot
try {
    Invoke-Step "Lua 전체 파싱" {
        @'
from luaparser import ast
import pathlib
count = 0
for path in pathlib.Path("ABProfileManager").rglob("*.lua"):
    ast.parse(path.read_text(encoding="utf-8"))
    count += 1
print(f"ok: lua parse files={count}")
'@ | & python -
    }

    Invoke-Step "공백 오류 검사" { & git diff --check }

    Invoke-PythonStep "범위 보호 (동결 파일)" "scripts/validate_season2_scope.py"
    Invoke-PythonStep "아이템 레벨표" "scripts/validate_season2_itemlevel.py" $itemLevelArgs
    Invoke-PythonStep "로케일 계약" "scripts/validate_locale_contract.py"

    Invoke-PythonStep "BIS Myth preview selector" "scripts/validate_bis_mythic_vault_links.py"
    Invoke-PythonStep "BIS 시즌 preview selector" "scripts/validate_bis_season_preview_links.py"
    Invoke-PythonStep "BIS tooltip 정적 계약" "scripts/validate_bis_tooltip_contract.py"
    Invoke-PythonStep "BIS Encounter Journal 데이터" "scripts/validate_bis_encounter_journal.py"
    Invoke-PythonStep "BIS 카탈로그" "scripts/validate_bis_catalog.py"
    Invoke-PythonStep "BIS 데이터 감사" "scripts/audit_bis_data.py"
}
finally {
    Pop-Location
}

Write-Output "시즌 2 검증을 모두 통과했습니다."
