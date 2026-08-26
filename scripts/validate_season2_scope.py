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

# v1.11.11 기준 `git hash-object` 값. BIS 데이터를 새 시즌으로 갱신하는
# 별도 작업에서만 이 표를 바꾼다.
FROZEN_BLOB_HASHES = {
    "ABProfileManager/Data/BISCatalog.lua": "9e89e80a0de93b4e76fd395be153506c27f737a0",
    "ABProfileManager/Data/BISRuntimeScoring.lua": "d8952d9c5dc49c08466c8609b1de2f628cdc71ab",
    "ABProfileManager/Data/BISMythicVaultLinks.lua": "b1184cc041d179d6d43463b58543e13d6504ac27",
    "ABProfileManager/Data/BISSeasonPreviewLinks.lua": "b27b68e8ddc95dba1a9f238432d7878c9e0deaaa",
    "ABProfileManager/Data/BISEncounterJournal.lua": "0192dcf511efd708e82b6e1a2521ca87358cf638",
    "ABProfileManager/Data/MidnightS1MPlusDB.lua": "7c57c1c13d5cb5a1e8e8b8bba2de85bf33b9d5a4",
    "ABProfileManager/Data/BISData.lua": "5e2e7ab04673834413cb9e169dc0a840454a05d4",
    "ABProfileManager/Data/BISData_Method.lua": "367603310b6366448e8f93e267d2f732c1ef7254",
    "ABProfileManager/Data/StatPriorities.lua": "6b88749d036c3b25aa970d27506d851af92ee2a3",
    "ABProfileManager/Data/StatPriorityTable.lua": "0f5fe46cd949b72a160ec804ace9c5e37978c0fd",
}

# 개행 정규화 후 UTF-8 기준 sha256.
REWARD_PROFILES_SHA256 = "2c4c5c8caa97dc21e2288e7bd04f999be46ac81b9b030ab6bf34ffca7acf110d"


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


def validate_frozen_files() -> int:
    for relative_path, expected in sorted(FROZEN_BLOB_HASHES.items()):
        target = REPO_ROOT / relative_path
        if not target.is_file():
            raise ValueError(f"{relative_path}: 동결 대상 파일이 없다")
        actual = git_blob_hash(relative_path)
        if actual != expected:
            raise ValueError(
                f"{relative_path}: 동결 파일이 변경됐다. 기대 {expected}, 실제 {actual}. "
                "시즌 2 작업에서 BIS 데이터와 스탯 우선순위는 수정하지 않는다"
            )
    return len(FROZEN_BLOB_HASHES)


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
    frozen_count = validate_frozen_files()
    block_size = validate_reward_profiles()
    print(
        f"ok: season2 scope frozen_files={frozen_count} "
        f"reward_profiles_bytes={block_size}"
    )


if __name__ == "__main__":
    main()
