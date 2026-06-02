"""Validate the shipped current-season Encounter Journal landing data."""

from __future__ import annotations

import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
JOURNAL_DB = REPO_ROOT / "ABProfileManager" / "Data" / "BISEncounterJournal.lua"
TOC = REPO_ROOT / "ABProfileManager" / "ABProfileManager.toc"
EXPECTED_TIER_INDEX = 13
EXPECTED_JOURNAL_TIER_ID = 505
EXPECTED_DB2_BUILD = "12.0.1.66838"
EXPECTED_INSTANCE_IDS_BY_DUNGEON = {
    "마법학자의 정원": 1300,
    "마이사라 동굴": 1315,
    "제나스 지점": 1316,
    "공결점 제나스": 1316,
    "공결탑 제나스": 1316,
    "윈드러너 첨탑": 1299,
    "알게타르 아카데미": 1201,
    "알게타르 대학": 1201,
    "삼두정의 권좌": 945,
    "하늘탑": 476,
    "사론의 구덩이": 278,
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
