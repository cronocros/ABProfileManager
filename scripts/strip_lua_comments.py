"""Lua 소스에서 주석을 제거하고 포맷을 정리한다.

주석은 문자열 안에도 들어갈 수 있으므로 단순 정규식으로 지우면 코드가
깨진다. 이 스크립트는 짧은 문자열, 긴 문자열, 짧은 주석, 긴 주석을 구분하는
스캐너로 처리한다.

안전장치가 셋 있다.

1. 동결 파일은 건드리지 않는다. `DOC/SEASON2_HANDOFF.md` 4장 목록과 같다.
2. `Data/ItemLevelTable.lua`는 `ns.Data.BISRewardProfiles` 앞까지만 처리한다.
   그 뒤 블록은 주석까지 포함해 sha256으로 고정돼 있다.
3. 파일마다 처리 전후를 파싱해 `to_lua_source` 결과를 비교한다. 다르면 그
   파일은 쓰지 않고 실패로 처리한다. 주석만 사라졌음을 기계적으로 증명한다.

`--extract <경로>`를 주면 제거할 주석을 먼저 모아 파일로 남긴다.
`--check`는 파일을 쓰지 않고 검사만 한다.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from luaparser import ast as lua_ast


def _use_utf8_output() -> None:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure:
            reconfigure(encoding="utf-8", errors="replace")


_use_utf8_output()


REPO_ROOT = Path(__file__).resolve().parents[1]
ADDON_ROOT = REPO_ROOT / "ABProfileManager"

FROZEN_FILES = {
    "Data/BISCatalog.lua",
    "Data/BISRuntimeScoring.lua",
    "Data/BISMythicVaultLinks.lua",
    "Data/BISSeasonPreviewLinks.lua",
    "Data/BISEncounterJournal.lua",
    "Data/MidnightS1MPlusDB.lua",
    "Data/BISData_Method.lua",
    "Data/StatPriorities.lua",
    "Data/StatPriorityTable.lua",
}

PARTIAL_FILES = {
    # 파일 경로: 이 문자열이 나오는 지점부터 끝까지는 손대지 않는다.
    "Data/ItemLevelTable.lua": "ns.Data.BISRewardProfiles",
}


def long_bracket_len(text: str, index: int) -> int:
    """`[==[` 형태의 여는 긴 괄호 길이를 센다. 아니면 0."""
    if text[index] != "[":
        return 0
    cursor = index + 1
    equals = 0
    while cursor < len(text) and text[cursor] == "=":
        equals += 1
        cursor += 1
    if cursor < len(text) and text[cursor] == "[":
        return cursor - index + 1
    return 0


def skip_long_bracket(text: str, index: int, opener_len: int) -> int:
    """긴 괄호 본문 끝(닫는 괄호 다음 위치)을 돌려준다."""
    closer = "]" + "=" * (opener_len - 2) + "]"
    end = text.find(closer, index + opener_len)
    if end < 0:
        return len(text)
    return end + len(closer)


def skip_quoted(text: str, index: int) -> int:
    quote = text[index]
    cursor = index + 1
    while cursor < len(text):
        char = text[cursor]
        if char == "\\":
            cursor += 2
            continue
        if char == quote:
            return cursor + 1
        if char == "\n":
            return cursor
        cursor += 1
    return len(text)


def split_comments(text: str) -> tuple[str, list[str]]:
    """주석을 제거한 소스와 제거된 주석 목록을 돌려준다."""
    out: list[str] = []
    comments: list[str] = []
    index = 0
    length = len(text)
    while index < length:
        char = text[index]
        if char in "\"'":
            end = skip_quoted(text, index)
            out.append(text[index:end])
            index = end
            continue
        opener = long_bracket_len(text, index)
        if opener:
            end = skip_long_bracket(text, index, opener)
            out.append(text[index:end])
            index = end
            continue
        if char == "-" and text.startswith("--", index):
            body_start = index + 2
            opener = long_bracket_len(text, body_start)
            if opener:
                end = skip_long_bracket(text, body_start, opener)
                comments.append(text[index:end])
                index = end
                continue
            end = text.find("\n", index)
            if end < 0:
                end = length
            comments.append(text[index:end])
            index = end
            continue
        out.append(char)
        index += 1
    return "".join(out), comments


def tidy(text: str) -> str:
    """뒤 공백을 지우고 빈 줄이 세 줄 이상 이어지지 않게 한다."""
    lines = [line.rstrip() for line in text.split("\n")]
    result: list[str] = []
    blank_run = 0
    for line in lines:
        if line:
            blank_run = 0
            result.append(line)
            continue
        blank_run += 1
        if blank_run <= 1:
            result.append(line)
    while result and not result[-1]:
        result.pop()
    return "\n".join(result) + "\n"


def normalized(source: str) -> str:
    return lua_ast.to_lua_source(lua_ast.parse(source))


def process(path: Path, extract: list[str] | None, write: bool) -> tuple[bool, int]:
    relative = path.relative_to(ADDON_ROOT).as_posix()
    if relative in FROZEN_FILES:
        return False, 0

    original = path.read_text(encoding="utf-8")
    marker = PARTIAL_FILES.get(relative)
    if marker:
        cut = original.index(marker)
        # 마커가 속한 주석 블록까지 보존하려면 마커 앞의 빈 줄 경계에서 자른다.
        cut = original.rfind("\n\n", 0, cut) + 1
        head, tail = original[:cut], original[cut:]
    else:
        head, tail = original, ""

    stripped, comments = split_comments(head)
    rebuilt = tidy(stripped) + ("\n" + tail if tail else "")

    if normalized(original) != normalized(rebuilt):
        raise ValueError(f"{relative}: 주석 제거 후 코드 의미가 달라졌다")

    if extract is not None and comments:
        extract.append(f"## {relative}\n")
        extract.extend(comment.rstrip() for comment in comments)
        extract.append("")

    changed = rebuilt != original
    if changed and write:
        path.write_text(rebuilt, encoding="utf-8")
    return changed, len(comments)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--extract", help="제거할 주석을 이 경로에 모아 남긴다")
    parser.add_argument("--check", action="store_true", help="파일을 쓰지 않고 검사만 한다")
    args = parser.parse_args()

    extract: list[str] | None = [] if args.extract else None
    changed_files = 0
    total_comments = 0
    skipped = 0

    for path in sorted(ADDON_ROOT.rglob("*.lua")):
        relative = path.relative_to(ADDON_ROOT).as_posix()
        if relative in FROZEN_FILES:
            skipped += 1
            continue
        changed, count = process(path, extract, write=not args.check)
        total_comments += count
        if changed:
            changed_files += 1

    if extract is not None and args.extract:
        Path(args.extract).write_text("\n".join(extract), encoding="utf-8")

    mode = "check" if args.check else "write"
    print(
        f"ok: strip lua comments mode={mode} changed={changed_files} "
        f"comments={total_comments} frozen_skipped={skipped}"
    )


if __name__ == "__main__":
    main()
