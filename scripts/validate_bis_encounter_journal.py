"""Validate the shipped current-season Encounter Journal landing data."""

from __future__ import annotations

import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
JOURNAL_DB = REPO_ROOT / "ABProfileManager" / "Data" / "BISEncounterJournal.lua"
TOC = REPO_ROOT / "ABProfileManager" / "ABProfileManager.toc"
EXPECTED_TIER_INDEX = 13
EXPECTED_JOURNAL_TIER_ID = 505
EXPECTED_DB2_BUILD = "12.1.0.69465"
# 시즌 2 M+ 던전 8종. 2026-08-28 인게임 EJ_GetInstanceByIndex 덤프로 확인했다.
EXPECTED_INSTANCE_IDS_BY_DUNGEON = {
    "송곳니의 제단": 1322,
    "날로라크의 소굴": 1311,
    "죽음의 골목": 1304,
    "눈부신 골짜기": 1309,
    "공허흉터 투기장": 1313,
    "왕들의 안식처": 1041,
    "루비 생명의 웅덩이": 1202,
    "세스랄리스 사원": 1030,
}


def main() -> None:
    text = JOURNAL_DB.read_text(encoding="utf-8")
    toc_text = TOC.read_text(encoding="utf-8")

    build_match = re.search(r'\bverifiedDB2Build\s*=\s*"([^"]+)"', text)
    if not build_match or build_match.group(1) != EXPECTED_DB2_BUILD:
        raise ValueError(
            "BISEncounterJournal.lua must declare "
            f'verifiedDB2Build = "{EXPECTED_DB2_BUILD}"'
        )

    tier_id_match = re.search(r"\bcurrentSeasonJournalTierID\s*=\s*(\d+)", text)
    if not tier_id_match or int(tier_id_match.group(1)) != EXPECTED_JOURNAL_TIER_ID:
        raise ValueError(
            "BISEncounterJournal.lua must declare "
            f"currentSeasonJournalTierID = {EXPECTED_JOURNAL_TIER_ID}"
        )

    tier_match = re.search(r"\bcurrentSeasonTierIndex\s*=\s*(\d+)", text)
    if not tier_match or int(tier_match.group(1)) != EXPECTED_TIER_INDEX:
        raise ValueError(
            "BISEncounterJournal.lua must declare "
            f"currentSeasonTierIndex = {EXPECTED_TIER_INDEX}"
        )

    entries = {
        dungeon: int(instance_id)
        for dungeon, instance_id in re.findall(
            r'^\s*\["([^"]+)"\]\s*=\s*(\d+)\s*,?\s*$',
            text,
            re.M,
        )
    }
    if entries != EXPECTED_INSTANCE_IDS_BY_DUNGEON:
        raise ValueError(
            "BISEncounterJournal.lua current-season instance map mismatch: "
            f"{entries!r}"
        )

    toc_line = r"Data\BISEncounterJournal.lua"
    if toc_line not in toc_text:
        raise ValueError(f"ABProfileManager.toc must load {toc_line}")

    print(
        "ok: current-season Encounter Journal landing "
        f"build={EXPECTED_DB2_BUILD} "
        f"journal_tier={EXPECTED_JOURNAL_TIER_ID} "
        f"ui_tier_index={EXPECTED_TIER_INDEX} "
        f"aliases={len(entries)}"
    )


if __name__ == "__main__":
    main()
