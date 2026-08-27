"""시즌 아이템 레벨표 일관성과 출처 표기 검증.

`Data/ItemLevelTable.lua`의 `ns.Data.ItemLevelTable`만 검사한다. 같은 파일
아래쪽의 `ns.Data.BISRewardProfiles`는 동결 대상이며
`scripts/validate_season2_scope.py`가 따로 확인한다.

검사 항목은 두 가지다.

1. 구조 일관성. 등급 상한이 오름차순인지, 구렁 단계가 연속인지, 각 행의
   아이템 레벨이 자기 등급 상한을 넘지 않는지 확인한다.
2. 출처 표기. 시즌이 시즌 1에서 바뀌면 `sources` 테이블을 요구한다. 실제
   위험은 오탈자가 아니라 출처 없는 값이므로, 외부 가이드만 근거인 값은
   경고로 표시하고 `--strict`에서는 실패로 처리한다. 릴리스 패키징은
   `--strict`로 돌린다.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from luaparser import ast as lua_ast
from luaparser import astnodes


def _use_utf8_output() -> None:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure:
            reconfigure(encoding="utf-8", errors="replace")


_use_utf8_output()


REPO_ROOT = Path(__file__).resolve().parents[1]
ITEM_LEVEL_TABLE = REPO_ROOT / "ABProfileManager" / "Data" / "ItemLevelTable.lua"
TABLE_NAME = "ns.Data.ItemLevelTable"

SEASON1_NAME = "Midnight Season 1"
# 시즌 2에는 탐험가(expl) 트랙과 대응 문장이 없어 등급에서 제외한다.
GRADE_ORDER = ("adv", "vet", "chmp", "hero", "myth")
SOURCE_SECTIONS = ("delves", "mythicPlus", "raid", "worldBoss", "crafted", "pvp")
ALLOWED_SOURCE_TAGS = ("dump", "tooltip", "guide")


def lua_value(node):
    if isinstance(node, astnodes.Number):
        return node.n
    if isinstance(node, astnodes.String):
        value = node.s
        return value.decode("utf-8") if isinstance(value, (bytes, bytearray)) else value
    if isinstance(node, astnodes.TrueExpr):
        return True
    if isinstance(node, astnodes.FalseExpr):
        return False
    if isinstance(node, astnodes.Nil):
        return None
    if isinstance(node, astnodes.UMinusOp):
        inner = lua_value(node.operand)
        return -inner if isinstance(inner, (int, float)) else None
    if isinstance(node, astnodes.Table):
        keyed: dict = {}
        array: list = []
        for field in node.fields:
            key = field.key
            if isinstance(key, astnodes.Name):
                keyed[key.id] = lua_value(field.value)
            elif isinstance(key, astnodes.String):
                raw = key.s
                name = raw.decode("utf-8") if isinstance(raw, (bytes, bytearray)) else raw
                keyed[name] = lua_value(field.value)
            elif isinstance(key, astnodes.Number):
                keyed[key.n] = lua_value(field.value)
            else:
                array.append(lua_value(field.value))
        if keyed and array:
            keyed["__array"] = array
            return keyed
        return keyed if keyed else array
    return None


def load_table() -> dict:
    tree = lua_ast.parse(ITEM_LEVEL_TABLE.read_text(encoding="utf-8"))
    for node in lua_ast.walk(tree):
        if not isinstance(node, astnodes.Assign):
            continue
        for target, value in zip(node.targets, node.values):
            if lua_ast.to_lua_source(target) == TABLE_NAME and isinstance(value, astnodes.Table):
                return lua_value(value)
    raise ValueError(f"{ITEM_LEVEL_TABLE.relative_to(REPO_ROOT)}: {TABLE_NAME} 테이블을 찾지 못했다")


def fail(message: str) -> None:
    raise ValueError(f"{ITEM_LEVEL_TABLE.relative_to(REPO_ROOT)}: {message}")


def validate_grade_max(table: dict) -> dict:
    grade_max = table.get("gradeMax")
    if not isinstance(grade_max, dict):
        fail("gradeMax 테이블이 없다")
    previous = 0
    for grade in GRADE_ORDER:
        value = grade_max.get(grade)
        if not isinstance(value, (int, float)):
            fail(f"gradeMax.{grade} 값이 없다")
        if value <= previous:
            fail(f"gradeMax가 오름차순이 아니다. {grade}={value}, 직전={previous}")
        previous = value
    return grade_max


def check_row_grade(label: str, row: dict, grade_max: dict) -> None:
    grade = row.get("grade")
    ilvl = row.get("ilvl")
    maxilvl = row.get("maxilvl")
    if grade is not None:
        if grade not in grade_max:
            fail(f"{label}: 알 수 없는 등급 {grade!r}")
        if isinstance(maxilvl, (int, float)) and maxilvl != grade_max[grade]:
            fail(f"{label}: maxilvl {maxilvl}이 gradeMax.{grade} {grade_max[grade]}과 다르다")
    if isinstance(ilvl, (int, float)) and isinstance(maxilvl, (int, float)) and ilvl > maxilvl:
        fail(f"{label}: ilvl {ilvl}이 maxilvl {maxilvl}보다 크다")

    vault_grade = row.get("vaultGrade")
    vault = row.get("vault")
    vault_max = row.get("vaultMax")
    if vault_grade is not None:
        if vault_grade not in grade_max:
            fail(f"{label}: 알 수 없는 금고 등급 {vault_grade!r}")
        if isinstance(vault_max, (int, float)) and vault_max != grade_max[vault_grade]:
            fail(f"{label}: vaultMax {vault_max}가 gradeMax.{vault_grade} {grade_max[vault_grade]}과 다르다")
    if isinstance(vault, (int, float)) and isinstance(vault_max, (int, float)) and vault > vault_max:
        fail(f"{label}: vault {vault}가 vaultMax {vault_max}보다 크다")

    crest = row.get("crestDrop")
    if crest is not None and crest not in grade_max:
        fail(f"{label}: 알 수 없는 문장 등급 {crest!r}")


def validate_delves(table: dict, grade_max: dict) -> int:
    delves = table.get("delves")
    if not isinstance(delves, list) or not delves:
        fail("delves 목록이 없다")
    previous_tier = 0
    previous_ilvl = 0
    for row in delves:
        if not isinstance(row, dict):
            fail("delves 행이 테이블이 아니다")
        tier = row.get("tier")
        if tier != previous_tier + 1:
            fail(f"구렁 단계가 연속이 아니다. {previous_tier} 다음에 {tier}")
        check_row_grade(f"구렁 {tier}단계", row, grade_max)
        ilvl = row.get("ilvl")
        if isinstance(ilvl, (int, float)):
            if ilvl < previous_ilvl:
                fail(f"구렁 {tier}단계 ilvl {ilvl}이 직전 단계 {previous_ilvl}보다 낮다")
            previous_ilvl = ilvl
        previous_tier = tier
    return previous_tier


def validate_mythic_plus(table: dict, grade_max: dict) -> int:
    mythic_plus = table.get("mythicPlus")
    if not isinstance(mythic_plus, dict):
        fail("mythicPlus 테이블이 없다")
    for key in ("heroic", "mythic0"):
        row = mythic_plus.get(key)
        if not isinstance(row, dict):
            fail(f"mythicPlus.{key} 항목이 없다")
        check_row_grade(f"mythicPlus.{key}", row, grade_max)

    end_of_dungeon = mythic_plus.get("endOfDungeon")
    if not isinstance(end_of_dungeon, list) or not end_of_dungeon:
        fail("mythicPlus.endOfDungeon 목록이 없다")
    previous_key = 0
    previous_ilvl = 0
    for row in end_of_dungeon:
        key = row.get("key")
        if not isinstance(key, (int, float)) or key <= previous_key:
            fail(f"endOfDungeon key가 오름차순이 아니다. {previous_key} 다음에 {key}")
        label = f"endOfDungeon +{key}"
        check_row_grade(label, row, grade_max)
        rank = row.get("rank")
        rank_max = row.get("rankMax")
        if isinstance(rank, (int, float)) and isinstance(rank_max, (int, float)) and rank > rank_max:
            fail(f"{label}: rank {rank}가 rankMax {rank_max}보다 크다")
        vault_rank = row.get("vaultRank")
        if isinstance(vault_rank, (int, float)) and isinstance(rank_max, (int, float)) and vault_rank > rank_max:
            fail(f"{label}: vaultRank {vault_rank}가 rankMax {rank_max}보다 크다")
        ilvl = row.get("ilvl")
        if isinstance(ilvl, (int, float)):
            if ilvl < previous_ilvl:
                fail(f"{label}: ilvl {ilvl}이 직전 단계 {previous_ilvl}보다 낮다")
            previous_ilvl = ilvl
        previous_key = key
    return len(end_of_dungeon)


def validate_raid(table: dict, grade_max: dict) -> None:
    raid = table.get("raid")
    if not isinstance(raid, dict):
        fail("raid 테이블이 없다")
    previous_min = 0
    for difficulty in ("normal", "heroic", "mythic"):
        row = raid.get(difficulty)
        if not isinstance(row, dict):
            fail(f"raid.{difficulty} 항목이 없다")
        low = row.get("min")
        high = row.get("max")
        if not isinstance(low, (int, float)) or not isinstance(high, (int, float)):
            fail(f"raid.{difficulty}: min 또는 max가 없다")
        if low > high:
            fail(f"raid.{difficulty}: min {low}이 max {high}보다 크다")
        if low <= previous_min:
            fail(f"raid 난이도별 min이 오름차순이 아니다. {difficulty}={low}, 직전={previous_min}")
        previous_min = low
        check_row_grade(f"raid.{difficulty}", row, grade_max)


def validate_simple_sections(table: dict, grade_max: dict) -> None:
    world_boss = table.get("worldBoss")
    if isinstance(world_boss, dict):
        # 시즌 2 월드 보스와 Lair는 야외부터 신화까지 난이도가 나뉜다.
        # 예전 단일 항목 형태도 계속 받아들인다.
        if "ilvl" in world_boss:
            check_row_grade("worldBoss", world_boss, grade_max)
        else:
            previous = 0
            for difficulty in ("world", "normal", "heroic", "mythic"):
                row = world_boss.get(difficulty)
                if not isinstance(row, dict):
                    fail(f"worldBoss.{difficulty} 항목이 없다")
                check_row_grade(f"worldBoss.{difficulty}", row, grade_max)
                ilvl = row.get("ilvl")
                if not isinstance(ilvl, (int, float)):
                    fail(f"worldBoss.{difficulty}: ilvl이 없다")
                if ilvl <= previous:
                    fail(
                        f"worldBoss 난이도별 ilvl이 오름차순이 아니다. "
                        f"{difficulty}={ilvl}, 직전={previous}"
                    )
                previous = ilvl

    crafted = table.get("crafted")
    if not isinstance(crafted, dict):
        fail("crafted 테이블이 없다")
    base = (crafted.get("base") or {}).get("ilvl")
    rank5 = (crafted.get("r5") or {}).get("ilvl")
    if not isinstance(base, (int, float)) or not isinstance(rank5, (int, float)):
        fail("crafted.base.ilvl 또는 crafted.r5.ilvl이 없다")
    if base > rank5:
        fail(f"crafted.base {base}가 crafted.r5 {rank5}보다 높다")

    pvp = table.get("pvp")
    if not isinstance(pvp, dict):
        fail("pvp 테이블이 없다")
    for bracket in ("honor", "conquest"):
        row = pvp.get(bracket)
        if not isinstance(row, dict):
            fail(f"pvp.{bracket} 항목이 없다")
        low = row.get("min")
        high = row.get("max")
        if not isinstance(low, (int, float)) or not isinstance(high, (int, float)):
            fail(f"pvp.{bracket}: min 또는 max가 없다")
        if low > high:
            fail(f"pvp.{bracket}: min {low}이 max {high}보다 크다")


def validate_sources(table: dict, season: str, strict: bool) -> list[str]:
    sources = table.get("sources")
    if season == SEASON1_NAME:
        if sources is None:
            return [
                f"note: season이 아직 {SEASON1_NAME}이라 sources 표기를 요구하지 않는다"
            ]
    if not isinstance(sources, dict):
        fail(
            "sources 테이블이 없다. 시즌을 갱신할 때는 각 구간의 근거를 "
            f"{SOURCE_SECTIONS} 키로 남긴다"
        )

    warnings: list[str] = []
    guide_only: list[str] = []
    for section in SOURCE_SECTIONS:
        tag = sources.get(section)
        if tag is None:
            fail(f"sources.{section} 표기가 없다")
        if tag not in ALLOWED_SOURCE_TAGS:
            fail(f"sources.{section} 값 {tag!r}는 허용 목록 {ALLOWED_SOURCE_TAGS} 밖이다")
        if tag == "guide":
            guide_only.append(section)

    if guide_only:
        message = (
            "외부 가이드만 근거인 구간: " + ", ".join(guide_only) +
            ". 인게임 덤프 또는 실제 툴팁으로 확인한다"
        )
        if strict:
            fail(message)
        warnings.append(f"warn: {message}")
    return warnings


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--strict",
        action="store_true",
        help="외부 가이드만 근거인 값을 실패로 처리한다. 릴리스 패키징에서 사용한다.",
    )
    args = parser.parse_args()

    table = load_table()
    season = table.get("season")
    if not isinstance(season, str) or not season.strip():
        fail("season 문자열이 없다")

    grade_max = validate_grade_max(table)
    delve_tiers = validate_delves(table, grade_max)
    key_rows = validate_mythic_plus(table, grade_max)
    validate_raid(table, grade_max)
    validate_simple_sections(table, grade_max)
    notes = validate_sources(table, season, args.strict)

    for note in notes:
        print(note, file=sys.stderr)
    print(
        f"ok: item level table season={season!r} delve_tiers={delve_tiers} "
        f"keystone_rows={key_rows} myth_cap={grade_max['myth']}"
    )


if __name__ == "__main__":
    main()
