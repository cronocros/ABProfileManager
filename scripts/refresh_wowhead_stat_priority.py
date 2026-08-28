"""와우헤드 전문화 가이드에서 스탯 우선순위를 수집한다.

`DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`의 `DB.SPECS` 항목 중 `priority`와
`weights`를 갱신한다. 갱신 후 `scripts/build_bis_runtime_scoring.py`를 돌려야
런타임 파일 세 개에 반영된다.

수집 대상은 전문화 개요 페이지다. 와우헤드에는 전문화별 stat-priority 전용
주소가 없고, 개요 페이지 본문에 `[b]Haste >>> Versatility = Critical Strike =
Mastery[/b]` 형태로 한 줄이 들어 있다. 역할에 따라 주소가 `overview-pve-dps`,
`overview-pve-healer`, `overview-pve-tank`로 갈린다.

가중치는 문장에서 기계적으로 만든다. 첫 스탯을 100으로 두고 연산자마다 정해진
폭만큼 낮춘다. `=`는 0, `>=`와 `=>`는 5, `>`는 15, `>>`는 25, `>>>`는 35이며
하한은 30이다. 문장에 네 스탯이 다 나오지 않으면 빠진 스탯을 가장 낮은 값으로
채우고 결과에 표시한다.

문장을 찾지 못한 전문화는 건드리지 않는다. 추정으로 채우면 점수화가 조용히
틀어지므로 기존 값을 그대로 둔다.

`--review <경로>`를 주면 파일을 쓰지 않고 수집 결과만 JSON으로 남긴다.
"""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
from pathlib import Path

import requests


def _use_utf8_output() -> None:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure:
            reconfigure(encoding="utf-8", errors="replace")


_use_utf8_output()


REPO_ROOT = Path(__file__).resolve().parents[1]
SCORING_DB = REPO_ROOT / "DOC" / "MidnightS1_MPlus_Addon_DB_v1.7.lua"
GUIDE_SLUGS = ("overview-pve-dps", "overview-pve-healer", "overview-pve-tank")

STAT_KOKR = {
    "Critical Strike": "치명타 및 극대화",
    "Crit": "치명타 및 극대화",
    "Haste": "가속",
    "Mastery": "특화",
    "Versatility": "유연성",
}
ALL_STATS = ("치명타 및 극대화", "가속", "특화", "유연성")
OPERATOR_DROP = {"=": 0, ">=": 5, "=>": 5, ">": 15, ">>": 25, ">>>": 35}
MIN_WEIGHT = 30

STAT_PATTERN = r"(?:Haste|Critical Strike|Crit|Mastery|Versatility)"
CHAIN_PATTERN = re.compile(rf"{STAT_PATTERN}(?:\s*[>=]{{1,3}}\s*{STAT_PATTERN})+")
OPERATOR_PATTERN = re.compile(r"\s*(>>>|>>|>=|=>|>|=)\s*")

SPEC_KEY_ALIASES = {
    "DRUID_RESTORATION": "DRUID_RESTO",
    "HUNTER_BEAST_MASTERY": "HUNTER_BEASTMASTERY",
    "PRIEST_DISCIPLINE": "PRIEST_DISC",
}


def load_spec_targets() -> list[tuple[int, str]]:
    """BIS 수집기의 전문화 목록에서 클래스와 전문화 경로를 뽑는다."""
    import importlib.util

    spec = importlib.util.spec_from_file_location(
        "refresh_wowhead_bis", REPO_ROOT / "scripts" / "refresh_wowhead_bis.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    targets = []
    for spec_id, url in module.SPECS:
        targets.append((spec_id, url.split("/classes/")[1].split("/bis-gear")[0]))
    return targets, module.HEADERS


def fetch_chain(session: requests.Session, headers: dict, path: str) -> str | None:
    for slug in GUIDE_SLUGS:
        url = f"https://www.wowhead.com/guide/classes/{path}/{slug}"
        try:
            response = session.get(url, headers=headers, timeout=30)
        except requests.RequestException:
            continue
        if response.status_code != 200:
            continue
        text = html.unescape(response.text).replace("\\r", " ").replace("\\n", " ")
        text = re.sub(r"\[(?!b\]|/b\])[^\]]{0,120}\]", " ", text)
        matches = CHAIN_PATTERN.findall(text)
        if matches:
            return max(matches, key=len)
    return None


def convert(chain: str):
    tokens = OPERATOR_PATTERN.split(chain.strip())
    stats, operators = tokens[0::2], tokens[1::2]

    korean, seen = [], set()
    for raw in stats:
        name = STAT_KOKR.get(raw.strip())
        if not name or name in seen:
            return None, None, None
        seen.add(name)
        korean.append(name)

    weights, current = {korean[0]: 100}, 100
    for operator, name in zip(operators, korean[1:]):
        current = max(MIN_WEIGHT, current - OPERATOR_DROP.get(operator, 15))
        weights[name] = current

    missing = [name for name in ALL_STATS if name not in weights]
    for name in missing:
        weights[name] = max(MIN_WEIGHT, current - 15)

    parts = []
    for index, name in enumerate(korean):
        parts.append(name)
        if index < len(operators):
            parts.append(operators[index])
    priority = " ".join(parts)
    if missing:
        priority += " > " + " = ".join(missing)
    return priority, weights, missing


def apply_to_scoring_db(results: dict) -> int:
    import importlib.util

    spec = importlib.util.spec_from_file_location(
        "build_bis_catalog", REPO_ROOT / "scripts" / "build_bis_catalog.py"
    )
    catalog = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(catalog)
    id_to_key = {value: key for key, value in catalog.SPEC_KEY_TO_ID.items()}

    text = SCORING_DB.read_text(encoding="utf-8")
    changed = 0
    for spec_id, info in results.items():
        key = id_to_key.get(int(spec_id))
        if not key:
            continue
        key = SPEC_KEY_ALIASES.get(key, key)
        match = re.search(rf"^(  {re.escape(key)} = \{{.*?)$", text, re.M)
        if not match:
            raise ValueError(f"{SCORING_DB.name}: {key} 항목을 찾지 못했다")
        line = match.group(1)
        updated = re.sub(r'priority="[^"]*"', f'priority="{info["priority"]}"', line, count=1)
        weight_text = ", ".join(f'["{k}"]={v}' for k, v in info["weights"].items())
        updated = re.sub(r"weights=\{[^}]*\}", "weights={ " + weight_text + " }", updated, count=1)
        if updated != line:
            text = text.replace(line, updated, 1)
            changed += 1
    SCORING_DB.write_text(text, encoding="utf-8")
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--review", metavar="PATH", help="파일을 쓰지 않고 결과만 JSON으로 남긴다")
    args = parser.parse_args()

    targets, headers = load_spec_targets()
    results, skipped, filled = {}, [], []

    with requests.Session() as session:
        for spec_id, path in targets:
            chain = fetch_chain(session, headers, path)
            if not chain:
                skipped.append((spec_id, path, "문장을 찾지 못했다"))
                continue
            priority, weights, missing = convert(chain)
            if not priority:
                skipped.append((spec_id, path, f"해석 실패: {chain}"))
                continue
            results[str(spec_id)] = {
                "path": path,
                "chain": chain,
                "priority": priority,
                "weights": weights,
                "filled": missing,
            }
            if missing:
                filled.append((spec_id, path, missing))
            print(f"{spec_id:5} {path:28} {priority}")

    for spec_id, path, reason in skipped:
        print(f"보류 {spec_id:5} {path:28} {reason}", file=sys.stderr)
    for spec_id, path, missing in filled:
        print(f"보정 {spec_id:5} {path:28} 누락: {', '.join(missing)}", file=sys.stderr)

    if args.review:
        Path(args.review).write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"ok: stat priority review specs={len(results)} skipped={len(skipped)} path={args.review}")
        return 0

    changed = apply_to_scoring_db(results)
    print(
        f"ok: stat priority updated specs={changed} skipped={len(skipped)} filled={len(filled)}. "
        "scripts/build_bis_runtime_scoring.py를 이어서 실행한다"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
