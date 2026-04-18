# ABProfileManager v1.7.0

배포일: `2026-04-18`

직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.0/ABProfileManager-v1.7.0.zip`
로컬 패키지: `dist/ABProfileManager-v1.7.0.zip`

## 요약

이번 릴리스는 한밤(Midnight) 시즌 1 BIS 오버레이를 전면 재정비한 버전입니다.

핵심은 기존의 `overall BIS 1개 + runtime fallback` 표시를 버리고, 각 spec/부위별로 `쐐기 / 레이드 / 제작 / 티어` 후보를 정적 카탈로그로 묶어 필터 후에도 살아 있는 추천 목록으로 보여주도록 바꾼 점입니다.

## 주요 변경

- BIS 런타임 데이터 소스를 `Data/BISCatalog.lua` 단일 카탈로그로 통합
- 한밤 시즌 1 기준 40 spec 전체 반영
- `쐐기 / 레이드 / 제작 / 티어` 4개 필터를 모두 기본 on으로 통일
- 필터 적용 후 남은 후보를 기준으로 `1순위 / 2순위 / 3순위+`를 다시 번호 매김
- `레이드 off + 쐐기만 on` 상태에서도 부위별 쐐기 드랍템과 인던명이 유지되도록 수정
- `koKR/enUS` 아이템명과 source label을 분리 저장하고 locale 누수 검증 추가
- `crafted`, `tier`는 Encounter Journal 잘못 랜딩을 막기 위해 비랜딩 유지
- `scripts/build_bis_catalog.py` 추가
- `scripts/refresh_wowhead_bis.py`, `scripts/refresh_wowhead_mplus_fallbacks.py`를 40 spec 기준으로 정리

## 데이터 메모

- `DOC/wow_midnight_s1_mplus_bis_final.md`
- `DOC/wow_midnight_s1_mplus_bis_korean_companion.md`

위 두 문서를 seed로 사용하되, 최종값은 Wowhead/Wago DB2 검증 결과와 itemID 확인을 우선합니다.

생성 파이프라인은 dungeon alias 정규화, locale 누수 검사, itemID 확인, sourceGroup 분류를 모두 끝낸 뒤 정적 Lua 파일을 출력합니다.

## 검증

- 40 spec 전체 존재 확인
- `itemID, slot, sourceGroup, overallRank, sourceRank` 필수값 검증
- `koKR` 영어 누수 0건, `enUS` 한글 누수 0건 확인
- `luaparser` 전체 Lua 파싱
- `git diff --check`
- 릴리스 패키징

## 알려진 메모

- `마이사라 동굴`, `윈드러너 첨탑` direct Encounter Journal instanceID는 아직 추가 확인이 필요합니다.
- `열쇠 파편`은 Blizzard API 기준 안전한 itemID가 여전히 확정되지 않아 `-`로 표시될 수 있습니다.
