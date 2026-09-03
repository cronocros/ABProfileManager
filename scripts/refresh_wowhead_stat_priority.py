"""와우헤드 전문화 스탯 우선순위 페이지에서 우선순위를 수집한다.

`DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`의 `DB.SPECS` 항목 중 `priority`와
`weights`를 갱신한다. 갱신 후 `scripts/build_bis_runtime_scoring.py`를 돌려야
런타임 파일 세 개에 반영된다.

수집 대상은 전문화별 스탯 우선순위 전용 페이지다. 주소는
`guide/classes/<클래스>/<전문화>/stat-priority-pve-<역할>`이고 역할은
`DB.SPECS`의 `role` 값에서 가져온다. 40개 전문화 전부에 이 페이지가 있다.

이전 판은 개요 페이지 본문의 `[b]Haste >>> Versatility[/b]` 형태 한 줄을
읽었다. 그 방식은 두 가지 문제가 있었다. 첫째, 문장이 없는 전문화가 6개
있었다. 둘째, `Haste until you reach 27% > Critical Strike => ...`처럼 첫
스탯에 조건이 붙으면 정규식이 그 앞부분을 버리고 뒤만 잡아, 1순위 스탯이
조용히 꼴찌로 밀렸다. 도적 무법과 악마사냥꾼 포식이 그렇게 어긋나 있었다.

전용 페이지의 우선순위는 영웅 특성별 순서 목록이다.

    [ol][li]Agility[/li][li]Haste[/li][li]Critical Strike[/li]...[/ol]

한 항목에 여러 스탯이 들어 있으면(`Mastery / Critical Strike`,
`Haste = Crit`, `Critical Strike and Haste`) 같은 순위로 본다. 항목 안에
`>` 계열 연산자가 있으면 그 순서를 그대로 쓴다. `(until 800)`이나
`to 1200 rating` 같은 조건 문구는 떼어내고, 같은 스탯이 두 번 나오면 앞선
자리만 남긴다. 주 능력치와 아이템 레벨, 방어도, 체력은 보조 스탯이 아니므로
버린다.

영웅 특성 목록이 서로 다르면 순위의 평균으로 합친다. 평균이 같은 스탯은
동급으로 묶는다. 하나를 골라 쓰면 나머지 빌드가 통째로 틀어지고, 추정으로
채우면 점수화가 조용히 틀어진다.

가중치는 합친 순서에서 기계적으로 만든다. 첫 스탯 100에서 시작해 동급은 0,
아래 순위는 15씩 낮추고 하한은 30이다.

`source="USER_SELECTED"`가 붙은 항목은 사람이 직접 고른 값이므로 수집 결과로
덮지 않는다. 표식과 근거 주석은 남고 값만 바뀌면 다음 유지보수자가 절충안이
아직 살아 있다고 오해한다. 보존한 항목은 `보존` 줄로 알린다.

`--review <경로>`를 주면 파일을 쓰지 않고 수집 결과만 JSON으로 남긴다.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import sys
import time
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

# 사람이 직접 고른 값이라는 표식이다. 이 표식이 붙은 항목은 수집 결과로 덮지
# 않는다. 표식과 근거 주석만 남고 값이 사라지면 다음 유지보수자가 절충안이
# 아직 살아 있다고 오해한다.
USER_SELECTED_MARKER = 'source="USER_SELECTED"'

STAT_KOKR = {
    "critical strike": "치명타 및 극대화",
    "crit": "치명타 및 극대화",
    "haste": "가속",
    "mastery": "특화",
    "versatility": "유연성",
}
ALL_STATS = ("치명타 및 극대화", "가속", "특화", "유연성")
ROLE_SLUG = {"DPS": "pve-dps", "HEALER": "pve-healer", "TANK": "pve-tank"}
STEP_DROP = 15
MIN_WEIGHT = 30
REQUEST_DELAY = 2.0

SPEC_KEY_ALIASES = {
    "DRUID_RESTORATION": "DRUID_RESTO",
    "HUNTER_BEAST_MASTERY": "HUNTER_BEASTMASTERY",
    "PRIEST_DISCIPLINE": "PRIEST_DISC",
}

MARKUP_PATTERN = re.compile(r'WH\.markup\.printHtml\(\s*"((?:[^"\\]|\\.)*)"', re.S)
LIST_PATTERN = re.compile(r"\[ol\](.*?)\[/ol\]", re.S)
ITEM_PATTERN = re.compile(r"\[li\](.*?)\[/li\]", re.S)
FORMAT_TAG_PATTERN = re.compile(r"\[/?[^\]]*\]")
PAREN_PATTERN = re.compile(r"\([^)]*\)")
CONDITION_PATTERN = re.compile(r"\s+(?:until|to|above|below|at)\s+.*$", re.I)
ORDER_SPLIT_PATTERN = re.compile(r"\s*(?:>=|=>|>>>|>>|>)\s*")
TIE_SPLIT_PATTERN = re.compile(r"\s*(?:/|=|,|\band\b)\s*")
EXPLAINED_MARKER = "Stats Explained"


def load_module(name: str):
    spec = importlib.util.spec_from_file_location(name, REPO_ROOT / "scripts" / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_spec_targets() -> tuple[list[tuple[int, str, str]], dict]:
    """전문화별 수집 주소와 역할을 모은다."""
    bis = load_module("refresh_wowhead_bis")
    catalog = load_module("build_bis_catalog")
    id_to_key = {value: key for key, value in catalog.SPEC_KEY_TO_ID.items()}

    text = SCORING_DB.read_text(encoding="utf-8")
    roles = {
        match.group(1): match.group(2)
        for match in re.finditer(r'^  ([A-Z0-9_]+) = \{.*?role="([A-Z]+)"', text, re.M)
    }

    targets = []
    for spec_id, url in bis.SPECS:
        key = id_to_key.get(spec_id)
        if not key:
            raise ValueError(f"{spec_id}: 전문화 키를 찾지 못했다")
        key = SPEC_KEY_ALIASES.get(key, key)
        role = roles.get(key)
        if not role:
            raise ValueError(f"{key}: {SCORING_DB.name}에서 role을 찾지 못했다")
        slug = ROLE_SLUG.get(role)
        if not slug:
            raise ValueError(f"{key}: 알 수 없는 role {role}")
        path = url.split("/classes/")[1].split("/bis-gear")[0]
        targets.append((spec_id, path, slug))
    return targets, bis.HEADERS


def fetch_body(session: requests.Session, headers: dict, path: str, slug: str) -> tuple[str, str | None]:
    url = f"https://www.wowhead.com/guide/classes/{path}/stat-priority-{slug}"
    try:
        response = session.get(url, headers=headers, timeout=30)
    except requests.RequestException:
        return url, None
    if response.status_code != 200:
        return url, None
    blocks = MARKUP_PATTERN.findall(response.text)
    if not blocks:
        return url, None
    body = max(blocks, key=len)
    body = body.encode("utf-8").decode("unicode_escape", "ignore")
    body = body.encode("latin1", "ignore").decode("utf-8", "ignore")
    body = body.replace("\\/", "/")
    cut = body.find(EXPLAINED_MARKER)
    if cut > 0:
        body = body[:cut]
    return url, body


def parse_item(text: str) -> list[list[str]]:
    """목록 한 줄에서 보조 스탯 순위를 뽑는다."""
    cleaned = FORMAT_TAG_PATTERN.sub(" ", text)
    cleaned = PAREN_PATTERN.sub(" ", cleaned)
    cleaned = CONDITION_PATTERN.sub("", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned).strip(" .")

    tiers = []
    for chunk in ORDER_SPLIT_PATTERN.split(cleaned):
        names = []
        for token in TIE_SPLIT_PATTERN.split(chunk):
            name = STAT_KOKR.get(token.strip().strip(".").lower())
            if name and name not in names:
                names.append(name)
        if names:
            tiers.append(names)
    return tiers


def parse_builds(body: str) -> list[tuple[tuple[str, ...], ...]]:
    """영웅 특성별 순위 목록을 중복 없이 모은다."""
    builds = []
    for block in LIST_PATTERN.findall(body):
        tiers: list[tuple[str, ...]] = []
        seen: set[str] = set()
        for item in ITEM_PATTERN.findall(block):
            for names in parse_item(item):
                fresh = tuple(name for name in names if name not in seen)
                if not fresh:
                    continue
                seen.update(fresh)
                tiers.append(fresh)
        if not tiers:
            continue
        build = tuple(tiers)
        if build not in builds:
            builds.append(build)
    return builds


def merge_builds(builds: list[tuple[tuple[str, ...], ...]]) -> tuple[list[list[str]], list[str]]:
    """빌드별 순위를 평균으로 합치고, 빠진 스탯을 보고한다."""
    totals: dict[str, float] = {}
    counts: dict[str, int] = {}
    for build in builds:
        for rank, names in enumerate(build, start=1):
            for name in names:
                totals[name] = totals.get(name, 0.0) + rank
                counts[name] = counts.get(name, 0) + 1

    missing = [name for name in ALL_STATS if name not in totals]
    if not counts:
        return [], list(ALL_STATS)

    lowest = max(totals[name] / counts[name] for name in totals)
    averages = {name: totals[name] / counts[name] for name in totals}
    for name in missing:
        averages[name] = lowest + 1

    groups: list[list[str]] = []
    for name in sorted(averages, key=lambda item: (averages[item], ALL_STATS.index(item))):
        if groups and averages[groups[-1][0]] == averages[name]:
            groups[-1].append(name)
        else:
            groups.append([name])
    return groups, missing


def render(groups: list[list[str]]) -> tuple[str, dict[str, int]]:
    weights: dict[str, int] = {}
    current = 100
    parts: list[str] = []
    for index, group in enumerate(groups):
        if index:
            current = max(MIN_WEIGHT, current - STEP_DROP)
            parts.append(">")
        parts.append(" = ".join(group))
        for name in group:
            weights[name] = current
    return " ".join(parts), weights


def apply_to_scoring_db(results: dict) -> tuple[int, list[str]]:
    catalog = load_module("build_bis_catalog")
    id_to_key = {value: key for key, value in catalog.SPEC_KEY_TO_ID.items()}

    text = SCORING_DB.read_text(encoding="utf-8")
    changed = 0
    protected: list[str] = []
    for spec_id, info in results.items():
        key = id_to_key.get(int(spec_id))
        if not key:
            continue
        key = SPEC_KEY_ALIASES.get(key, key)
        match = re.search(rf"^(  {re.escape(key)} = \{{.*?)$", text, re.M)
        if not match:
            raise ValueError(f"{SCORING_DB.name}: {key} 항목을 찾지 못했다")
        line = match.group(1)
        if USER_SELECTED_MARKER in line:
            protected.append(key)
            continue
        updated = re.sub(r'priority="[^"]*"', f'priority="{info["priority"]}"', line, count=1)
        weight_text = ", ".join(f'["{k}"]={v}' for k, v in info["weights"].items())
        updated = re.sub(r"weights=\{[^}]*\}", "weights={ " + weight_text + " }", updated, count=1)
        if updated != line:
            text = text.replace(line, updated, 1)
            changed += 1
    SCORING_DB.write_text(text, encoding="utf-8")
    return changed, protected


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--review", metavar="PATH", help="파일을 쓰지 않고 결과만 JSON으로 남긴다")
    args = parser.parse_args()

    targets, headers = load_spec_targets()
    results: dict[str, dict] = {}
    skipped: list[tuple[int, str, str]] = []
    filled: list[tuple[int, str, list[str]]] = []

    with requests.Session() as session:
        for spec_id, path, slug in targets:
            url, body = fetch_body(session, headers, path, slug)
            time.sleep(REQUEST_DELAY)
            if not body:
                skipped.append((spec_id, path, "페이지를 읽지 못했다"))
                continue
            builds = parse_builds(body)
            if not builds:
                skipped.append((spec_id, path, "순위 목록을 찾지 못했다"))
                continue
            groups, missing = merge_builds(builds)
            if not groups:
                skipped.append((spec_id, path, "보조 스탯을 찾지 못했다"))
                continue
            priority, weights = render(groups)
            results[str(spec_id)] = {
                "path": path,
                "url": url,
                "builds": [[list(tier) for tier in build] for build in builds],
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

    changed, protected = apply_to_scoring_db(results)
    for key in protected:
        print(f"보존 {key:28} 사용자 확정 값이라 덮어쓰지 않는다", file=sys.stderr)
    print(
        f"ok: stat priority updated specs={changed} skipped={len(skipped)} "
        f"filled={len(filled)} protected={len(protected)}. "
        "scripts/build_bis_runtime_scoring.py를 이어서 실행한다"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
