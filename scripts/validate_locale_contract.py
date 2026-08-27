"""로케일 키 계약 검증.

`koKR`과 `enUS`는 키 집합이 정확히 같아야 한다. `ruRU`는 별도 확장 파일
`ABPM_ruRU_Final_v3.lua`가 TOC 맨 뒤에서 `Locale.strings.ruRU`에 주입하는
구조이므로 그 파일까지 함께 파싱해야 비교가 성립한다.

`ruRU`는 커뮤니티 번역이라 이미 일부 키가 비어 있다. 현재 상태를 기준선으로
고정하고, 누락이 그보다 늘어나면 실패한다. 즉 새 문자열을 추가하면서 러시아어
번역을 빠뜨리면 잡힌다.
"""

from __future__ import annotations

import re
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
LOCALE = REPO_ROOT / "ABProfileManager" / "Locale.lua"
LOCALE_ADDITIONS = REPO_ROOT / "ABProfileManager" / "Locale_Additions.lua"
LOCALE_RURU = REPO_ROOT / "ABProfileManager" / "ABPM_ruRU_Final_v3.lua"
RURU_STRINGS_TABLE = "LOCALE_STRINGS_RURU"

# v1.11.11 기준 ruRU 번역 격차. 번역이 채워지면 이 값을 낮춘다.
RURU_MISSING_BASELINE = 143
RURU_EXTRA_BASELINE = 11


def key_name(node) -> str | None:
    if isinstance(node, astnodes.Name):
        return node.id
    if isinstance(node, astnodes.String):
        value = node.s
        if isinstance(value, (bytes, bytearray)):
            return value.decode("utf-8")
        return value
    return None


def table_entries(table: astnodes.Table) -> dict[str, object]:
    entries: dict[str, object] = {}
    for field in table.fields:
        name = key_name(field.key)
        if name is not None:
            entries[name] = field.value
    return entries


def is_empty_string(node) -> bool:
    if not isinstance(node, astnodes.String):
        return False
    value = node.s
    if isinstance(value, (bytes, bytearray)):
        value = value.decode("utf-8")
    return value.strip() == ""


def parse_base_strings() -> dict[str, dict[str, object]]:
    tree = lua_ast.parse(LOCALE.read_text(encoding="utf-8"))
    for node in lua_ast.walk(tree):
        if not isinstance(node, astnodes.Assign):
            continue
        for target, value in zip(node.targets, node.values):
            if lua_ast.to_lua_source(target) != "Locale.strings":
                continue
            if not isinstance(value, astnodes.Table):
                continue
            result: dict[str, dict[str, object]] = {}
            for field in value.fields:
                language = key_name(field.key)
                if language and isinstance(field.value, astnodes.Table):
                    result[language] = table_entries(field.value)
            return result
    raise ValueError(f"{LOCALE.relative_to(REPO_ROOT)}: Locale.strings 테이블을 찾지 못했다")


def parse_additions(languages: list[str]) -> dict[str, dict[str, object]]:
    tree = lua_ast.parse(LOCALE_ADDITIONS.read_text(encoding="utf-8"))
    result: dict[str, dict[str, object]] = {language: {} for language in languages}
    for node in lua_ast.walk(tree):
        if not isinstance(node, astnodes.Assign):
            continue
        for target, value in zip(node.targets, node.values):
            source = lua_ast.to_lua_source(target)
            for language in languages:
                # `enUS.key = ...`와 `enUS["key"] = ...` 두 표기를 모두 센다.
                # 점 표기만 보면 대괄호로 추가된 키를 놓쳐 언어 간 불일치를
                # 그냥 통과시킨다.
                dot_prefix = f"{language}."
                bracket_match = re.match(rf'^{language}\[\s*"(.+?)"\s*\]$', source)
                if bracket_match:
                    result[language][bracket_match.group(1)] = value
                elif source.startswith(dot_prefix):
                    result[language][source[len(dot_prefix):]] = value
    return result


def parse_ruru() -> dict[str, object]:
    tree = lua_ast.parse(LOCALE_RURU.read_text(encoding="utf-8"))
    for node in lua_ast.walk(tree):
        if not isinstance(node, astnodes.LocalAssign):
            continue
        for target, value in zip(node.targets, node.values):
            if not isinstance(target, astnodes.Name) or target.id != RURU_STRINGS_TABLE:
                continue
            if isinstance(value, astnodes.Table):
                return table_entries(value)
    raise ValueError(
        f"{LOCALE_RURU.relative_to(REPO_ROOT)}: {RURU_STRINGS_TABLE} 테이블을 찾지 못했다. "
        "ruRU 주입 파일 구조가 바뀌면 이 검증기를 함께 갱신한다"
    )


def report_empty(language: str, entries: dict[str, object], source: Path) -> None:
    empty = sorted(key for key, value in entries.items() if is_empty_string(value))
    if empty:
        preview = ", ".join(empty[:5])
        raise ValueError(
            f"{source.relative_to(REPO_ROOT)}: {language} 번역이 비어 있는 키 {len(empty)}개: {preview}"
        )


def main() -> None:
    base = parse_base_strings()
    for language in ("enUS", "koKR"):
        if language not in base:
            raise ValueError(f"{LOCALE.relative_to(REPO_ROOT)}: {language} 문자열 테이블이 없다")

    additions = parse_additions(["enUS", "koKR"])
    ruru = parse_ruru()

    merged: dict[str, dict[str, object]] = {}
    for language in ("enUS", "koKR"):
        combined = dict(base[language])
        combined.update(additions[language])
        merged[language] = combined

    report_empty("enUS", base["enUS"], LOCALE)
    report_empty("koKR", base["koKR"], LOCALE)
    report_empty("enUS", additions["enUS"], LOCALE_ADDITIONS)
    report_empty("koKR", additions["koKR"], LOCALE_ADDITIONS)
    report_empty("ruRU", ruru, LOCALE_RURU)

    english = set(merged["enUS"])
    korean = set(merged["koKR"])
    missing_in_korean = sorted(english - korean)
    missing_in_english = sorted(korean - english)
    if missing_in_korean or missing_in_english:
        raise ValueError(
            "enUS와 koKR 키 집합이 다르다. "
            f"koKR 누락 {len(missing_in_korean)}개 {missing_in_korean[:5]}, "
            f"enUS 누락 {len(missing_in_english)}개 {missing_in_english[:5]}"
        )

    russian = set(ruru)
    ruru_missing = sorted(english - russian)
    ruru_extra = sorted(russian - english)
    if len(ruru_missing) > RURU_MISSING_BASELINE:
        raise ValueError(
            f"ruRU 번역 누락이 기준선 {RURU_MISSING_BASELINE}개에서 {len(ruru_missing)}개로 늘었다. "
            f"새로 빠진 키 예시: {ruru_missing[:5]}"
        )
    if len(ruru_extra) > RURU_EXTRA_BASELINE:
        raise ValueError(
            f"ruRU에만 있는 키가 기준선 {RURU_EXTRA_BASELINE}개에서 {len(ruru_extra)}개로 늘었다. "
            f"예시: {ruru_extra[:5]}"
        )

    print(
        f"ok: locale contract enUS={len(english)} koKR={len(korean)} ruRU={len(russian)} "
        f"ruRU_missing={len(ruru_missing)}/{RURU_MISSING_BASELINE} "
        f"ruRU_extra={len(ruru_extra)}/{RURU_EXTRA_BASELINE}"
    )


if __name__ == "__main__":
    main()
