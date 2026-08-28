"""시즌 2 작업의 범위 보호 검증.

동결하기로 한 BIS 데이터와 스탯 우선순위 파일이 그대로인지, `ItemLevelTable.lua`
하단의 `ns.Data.BISRewardProfiles` 블록이 변하지 않았는지 확인한다.

기준 값은 `DOC/SEASON2_HANDOFF.md` 4장과 같다. 시즌 2 작업 중 이 파일들이
바뀌면 즉시 실패한다.
"""

from __future__ import annotations

import hashlib
import subprocess
import sys
from pathlib import Path


def _use_utf8_output() -> None:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure:
            reconfigure(encoding="utf-8", errors="replace")


_use_utf8_output()


REPO_ROOT = Path(__file__).resolve().parents[1]
ITEM_LEVEL_TABLE = REPO_ROOT / "ABProfileManager" / "Data" / "ItemLevelTable.lua"
REWARD_PROFILES_MARKER = "ns.Data.BISRewardProfiles"

# 런타임에 로드되는 BIS 데이터와 스탯 우선순위다. TOC에 등재돼 있어 값을
# 바꾸면 즉시 인게임 동작이 달라진다.
#
# 2026-08-28 시즌 2로 전환했다. BISCatalog은 와우헤드 overall 641행으로
# 재생성했고, EncounterJournal은 인게임 덤프로 확인한 시즌 2 던전 8종이며,
# preview selector 두 종은 시즌 2 값을 확인하지 못해 비활성으로 두었다.
# 스탯 우선순위는 12.0.5 기준 동결을 유지한다.
FROZEN_BLOB_HASHES = {
    "ABProfileManager/Data/BISCatalog.lua": "1403c3c26d7c98f59d39ce4e4a83e1a65ca5a136",
    "ABProfileManager/Data/BISRuntimeScoring.lua": "d8952d9c5dc49c08466c8609b1de2f628cdc71ab",
    "ABProfileManager/Data/BISMythicVaultLinks.lua": "5cdaf725b8f9bc7851118c841ab5a22c60fb22ba",
    "ABProfileManager/Data/BISSeasonPreviewLinks.lua": "48a2e022629eb9cfc28b8a1f671b2314f7229585",
    "ABProfileManager/Data/BISEncounterJournal.lua": "230a26f4704a6d81634ce6553fabf106a76a0f6b",
    "ABProfileManager/Data/MidnightS1MPlusDB.lua": "5e32e4ddc1cb6864119b04b4a891a9b786bf1d15",
    "ABProfileManager/Data/StatPriorities.lua": "a80a1441f3d9f88e48412f50c01ebfe47ba5f63d",
    "ABProfileManager/Data/StatPriorityTable.lua": "440790be9d920c52d3b99e366f2a2155825467b0",
}

# 카탈로그 생성 입력이다. TOC에 없어 런타임에 로드되지 않으므로 갱신해도
# 인게임 동작이 바뀌지 않는다. 다만 다음 카탈로그 재생성 결과를 좌우하므로
# 무엇이 들어 있는지 추적한다.
#
# BISData_Method.lua는 2026-08-28 `scripts/refresh_wowhead_bis.py`로 시즌 2
# 와우헤드 데이터를 반영했다. 40개 전문화 641행이며 시즌 1 던전 참조는 없다.
GENERATION_INPUT_HASHES = {
    "ABProfileManager/Data/BISData_Method.lua": "14d7c4f974fdbd1a870891ae55facf3c88fc7d99",
}

# 개행 정규화 후 UTF-8 기준 sha256. 2026-08-28 시즌 2 보상 프로필로 교체했다.
# scripts/build_bis_catalog.py의 MPLUS_REWARD_PROFILES와 값이 같아야 한다.
REWARD_PROFILES_SHA256 = "63859fae8e39b8273cb53f5550515d56d8dd465322922aecaf4da1920fb3ce4c"


def git_blob_hash(relative_path: str) -> str:
    """작업 트리 파일의 git blob 해시를 구한다.

    개행 필터 처리를 git에 맡겨야 Windows 체크아웃에서도 값이 일치한다.
    """
    result = subprocess.run(
        ["git", "hash-object", "--", relative_path],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise ValueError(f"{relative_path}: git hash-object 실패: {result.stderr.strip()}")
    return result.stdout.strip()


def validate_hashes(table: dict[str, str], kind: str, advice: str) -> int:
    for relative_path, expected in sorted(table.items()):
        target = REPO_ROOT / relative_path
        if not target.is_file():
            raise ValueError(f"{relative_path}: {kind} 대상 파일이 없다")
        actual = git_blob_hash(relative_path)
        if actual != expected:
            raise ValueError(
                f"{relative_path}: {kind} 파일이 변경됐다. 기대 {expected}, 실제 {actual}. {advice}"
            )
    return len(table)


def validate_reward_profiles() -> int:
    text = ITEM_LEVEL_TABLE.read_text(encoding="utf-8")
    index = text.find(REWARD_PROFILES_MARKER)
    if index < 0:
        raise ValueError(
            f"{ITEM_LEVEL_TABLE.relative_to(REPO_ROOT)}: {REWARD_PROFILES_MARKER} 블록을 찾지 못했다"
        )
    block = text[index:].replace("\r\n", "\n")
    actual = hashlib.sha256(block.encode("utf-8")).hexdigest()
    if actual != REWARD_PROFILES_SHA256:
        raise ValueError(
            f"{ITEM_LEVEL_TABLE.relative_to(REPO_ROOT)}: {REWARD_PROFILES_MARKER} 블록이 변경됐다. "
            f"기대 {REWARD_PROFILES_SHA256}, 실제 {actual}. "
            "시즌 2 아이템 레벨 갱신은 이 블록 위쪽만 수정한다"
        )
    return len(block)


def main() -> None:
    frozen_count = validate_hashes(
        FROZEN_BLOB_HASHES,
        "동결",
        "시즌 2 작업에서 런타임 BIS 데이터와 스탯 우선순위는 수정하지 않는다",
    )
    input_count = validate_hashes(
        GENERATION_INPUT_HASHES,
        "생성 입력",
        "생성 입력을 갱신했다면 이 표의 해시도 함께 올린다",
    )
    block_size = validate_reward_profiles()
    print(
        f"ok: season2 scope frozen_files={frozen_count} "
        f"generation_inputs={input_count} reward_profiles_bytes={block_size}"
    )


if __name__ == "__main__":
    main()
