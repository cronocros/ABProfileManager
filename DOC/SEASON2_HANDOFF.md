# Midnight 시즌 2 업데이트 핸드오프 (v1.12.0 작업)

이 문서는 `Midnight 시즌 2` 대응 작업을 여러 세션·여러 에이전트가 이어서 진행하기 위한 인계 문서입니다.
작업 도중 세션이 끊기면 이 문서의 `9. 진행 로그`와 `10. 재개 프롬프트`만 읽고 바로 이어받을 수 있어야 합니다.

- 작성 기준일: 2026-08-27
- 기준 브랜치: `codex/midnight-s2-update` (현재 `main`과 동일 커밋 `2946160`)
- 직전 릴리스: `v1.11.11` (WoW 12.0.7 대응)
- 목표 릴리스: `v1.12.0` (WoW 12.1.0 대응)
- 계획 출처: ChatGPT/Codex 세션 "한밤 시즌 2 업데이트 계획 수립" (계획만 수립, 코드 변경 없음)

## 1. 확정된 사실

라이브 클라이언트 `GetBuildInfo()` 덤프로 확정된 값입니다.

```text
ABPM 12.1.0 69465 Aug 21 2026 120100
```

- 클라이언트 버전: `12.1.0`
- 빌드 번호: `69465`
- 빌드 날짜: `Aug 21 2026`
- TOC Interface 번호: `120100`

시즌 2는 지역별로 2026년 8월 18~19일에 시작했습니다. 신규 콘텐츠로 `Coiled Isle`, `Venomous Abyss`, `Altar of Fangs`, 신규 구렁 3종, 신규 M+ 로테이션이 열렸습니다.

## 2. 승인된 결정

사용자 승인이 끝난 항목입니다. 재논의 없이 이 전제로 진행합니다.

- 릴리스 버전은 `v1.12.0`으로 올린다.
- 접근 방식은 "시즌 데이터 계약 + 검증 하네스"를 채택한다. 대규모 구조 변경은 하지 않는다.
- BIS 추천 장비 데이터는 이번 작업에서 **동결**한다.
- 스탯 우선순위 값도 **동결**하고, 문서·주석에 `12.0.5 기준`임을 명시한다.
- 출처가 확인되지 않은 ID·좌표·아이템 레벨은 하드코딩하지 않는다. 라이브 덤프 또는 실제 툴팁으로 확인된 값만 반영한다.

## 3. 작업 범위

### 포함

- `1.11.11` → `1.12.0` 버전 갱신과 `12.1.0` 호환성 점검
- 드랍·금고·구렁·M+·레이드·제작·PvP 아이템 레벨 갱신
- `Mistcrest` 통화와 복원 열쇠 표시 갱신
- `Coiled Isle`, `Altar of Fangs`, 신규 구렁·Lair·레이드·이동시설 지도 정보
- 전문기술 지식 퀘스트·보물·웨이포인트와 12.1 리셋 정책
- M+ 시즌 최고기록 UI와 Blizzard 지연 로드 호환성
- `UI/StatsOverlay.lua`의 12.1 aura / secret-number / API 호환성
- `koKR` / `enUS` / `ruRU` 번역
- README, 인트로, 아키텍처, 인계서, 릴리스 노트, 패키지

### 제외 (동결)

- BIS 후보 아이템과 순위
- `Data/BISCatalog.lua`, 런타임 점수화, 시즌 preview selector
- BIS Encounter Journal 데이터와 `UI/BISOverlay.lua` 동작 변경
- `Data/ItemLevelTable.lua` 하단 `ns.Data.BISRewardProfiles` 블록 (현재 83행 이후)

### 동결 파일 기준 해시

작업 종료 시 아래 파일은 byte-identical이어야 합니다. `git hash-object <파일>` 결과가 아래와 같아야 합니다.

```text
9e89e80a0de93b4e76fd395be153506c27f737a0  ABProfileManager/Data/BISCatalog.lua
d8952d9c5dc49c08466c8609b1de2f628cdc71ab  ABProfileManager/Data/BISRuntimeScoring.lua
b1184cc041d179d6d43463b58543e13d6504ac27  ABProfileManager/Data/BISMythicVaultLinks.lua
b27b68e8ddc95dba1a9f238432d7878c9e0deaaa  ABProfileManager/Data/BISSeasonPreviewLinks.lua
0192dcf511efd708e82b6e1a2521ca87358cf638  ABProfileManager/Data/BISEncounterJournal.lua
7c57c1c13d5cb5a1e8e8b8bba2de85bf33b9d5a4  ABProfileManager/Data/MidnightS1MPlusDB.lua
5e2e7ab04673834413cb9e169dc0a840454a05d4  ABProfileManager/Data/BISData.lua
367603310b6366448e8f93e267d2f732c1ef7254  ABProfileManager/Data/BISData_Method.lua
581eb5ba7cc2e1662cf42f7c302ae5f9dd5eec58  ABProfileManager/UI/BISOverlay.lua
6b88749d036c3b25aa970d27506d851af92ee2a3  ABProfileManager/Data/StatPriorities.lua
0f5fe46cd949b72a160ec804ace9c5e37978c0fd  ABProfileManager/Data/StatPriorityTable.lua
```

`UI/BISOverlay.lua`는 12.1 API 파손이 실제로 확인된 경우에만 예외적으로 수정하고, 그때는 이 문서의 진행 로그에 사유와 새 해시를 남깁니다.

## 4. 현재 저장소 기준값 (시즌 1 상태)

수정 대상 파일의 현재 값입니다. 시즌 2 값과 대조할 baseline으로 사용합니다.

### `ABProfileManager/ABProfileManager.toc`

- `## Interface: 120005, 120007`
- `## Version: 1.11.11`

### `ABProfileManager/Constants.lua`

- `VERSION` fallback 문자열이 `"1.11.11"`
- `CLIENT_LOCALE_LANGUAGE`에 `koKR`, `enUS`, `enGB`만 매핑. `ruRU`는 `ABPM_ruRU_Final_v3.lua`가 런타임에 주입

### `ABProfileManager/Data/ItemLevelTable.lua` (116행)

- `season = "Midnight Season 1"`
- `gradeMax`: `expl 220 / adv 237 / vet 250 / chmp 263 / hero 276 / myth 289`
- `delves`: `tier 1~11`, 아이템 레벨은 8단계 `250`에서 상한 고정, 11단계만 `crestDrop="myth"`
- `mythicPlus.heroic` `230`, `mythicPlus.mythic0` `246`, `endOfDungeon` `key 2~12` (`250~266`)
- `raid`: normal `246~256` / heroic `259~269` / mythic `272~282`
- `worldBoss` `233`, `crafted.base` `272`, `crafted.r5` `285`
- `pvp.honor` `220~250`, `pvp.conquest` `250~276`
- 83행부터 `ns.Data.BISRewardProfiles` — **동결 구간**

### `ABProfileManager/UI/ItemLevelOverlay.lua` (1232행)

- `DELVE_RESTORED_KEY_CURRENCY_ID = 3028` (34행)
- `CREST_ID_BY_GRADE = { adv=3383, vet=3341, chmp=3343, hero=3345, myth=3347 }` (40~46행)
- 구렁 표는 `11단계`까지만 유효

### `ABProfileManager/Data/SilvermoonMapData.lua` (135행)

- `silvermoonPoints` 37개 POI (서비스/이동/전문기술/PvP/던전/구렁 카테고리)
- `aliases = { [2710]=2393, [2424]=1270 }`, 별도 `nameAliases` 존재
- 시즌 1 기준 `the_darkway`, `murder_row`, `delve_hub` 등이 포함됨

### 기타

- `Data/ProfessionKnowledge.lua` 496행, `Data/ProfessionKnowledgeWaypoints.lua` 116행
- `Data/WorldEventSchedule.lua` 61행
- `UI/MythicPlusRecordOverlay.lua` 338행 — `평점 / 던전명`만 표시
- `Locale.lua` 922행 (`enUS`/`koKR` 3개 테이블: strings, classNames, specNames)
- `Locale_Additions.lua` 1174행
- `ABPM_ruRU_Final_v3.lua` — `ruRU` 확장. `Locale.strings.ruRU` 등을 뒤에서 주입하므로 TOC 로드 순서상 `UI/ConfigPanel.lua` 다음에 위치

## 5. 미확정 데이터 (수집 필요)

아래 값은 아직 확정되지 않았습니다. 라이브 덤프 또는 실제 툴팁으로 확인하기 전에는 코드에 넣지 않습니다.

| 항목 | 상태 | 확정 방법 |
| --- | --- | --- |
| 시즌 2 전체 아이템 레벨표 (구렁/M+/금고/레이드/제작/PvP) | 미확정 | 인게임 툴팁 + 아이템 강화 NPC 실측 |
| `Mistcrest` 통화 ID | 미확정 | 통화 목록 덤프 또는 통화 탭 링크 |
| 시즌 2 문장(crest) 통화 ID 5종 | 미확정 | 위와 동일. 시즌 1 값 `3383/3341/3343/3345/3347`는 재사용 금지 |
| 복원 열쇠 통화 ID | 미확정 | 시즌 1 값 `3028` 유효 여부 확인 |
| `Coiled Isle` UiMapID (후보 `2512`) | 후보만 있음 | `C_Map.GetBestMapForUnit("player")` 덤프 |
| 신규 구렁·던전 UiMapID / JournalInstanceID | 미확정 | `C_ChallengeMode.GetMapTable()` 덤프 |
| 신규 M+ 던전 풀 | 미확정 | `C_ChallengeMode.GetMapTable()` 덤프 |
| 전문기술 지식 questID | 미확정 | 인게임 퀘스트 로그 확인 |
| 구렁 최고 단계 (시즌 1은 11단계) | 미확정 | 인게임 구렁 UI |

### 수집용 인게임 명령

```text
/run local v,b,d,t=GetBuildInfo(); print("ABPM",v,b,d,t)
/run for _,id in ipairs(C_ChallengeMode.GetMapTable()) do local n=select(1,C_ChallengeMode.GetMapUIInfo(id)); print(id,n) end
/dump C_Map.GetBestMapForUnit("player")
/run for i=1,C_CurrencyInfo.GetCurrencyListSize() do local e=C_CurrencyInfo.GetCurrencyListInfo(i); if e then print(i,e.name,e.currencyTypesID) end end
```

수집 결과는 `DOC/season2/` 아래에 원문 그대로 남기고, 계약 파일에는 확정 값만 옮깁니다.

## 6. 작업 DAG

```text
W0 공식자료 + 라이브 클라이언트 시즌 계약 확정
 ├─ W1 버전/TOC/API 호환성
 ├─ W2 아이템레벨·통화·구렁 데이터
 │    └─ W2b ItemLevelOverlay 적용
 ├─ W3 지도·POI·alias·웨이포인트
 ├─ W4 전문기술 지식 데이터/API
 ├─ W5 M+ 기록·StatsOverlay·locale
 └─ W6 검증 스크립트/범위 보호
          ↓
     G1 명세 전용 리뷰
          ↓
     통합 및 전체 회귀
          ↓
     G2 코드 품질 전용 리뷰
          ↓
     12.1 인게임 QA
          ↺ 실패 작업만 담당 wave로 환류
          ↓
     문서·v1.12.0 패키징
```

동시 구현 에이전트는 최대 3명입니다. 코디네이터는 파일 소유권·의존성·통합만 담당하고 직접 구현하지 않습니다. 구현자와 리뷰어는 분리합니다.

### wave별 소유 파일과 완료 조건

| Wave | 소유 파일 | 산출물 | 완료 조건 |
| --- | --- | --- | --- |
| W0 | `DOC/season2/season-contract.md`, `DOC/season2/live-dump-*.txt` | 시즌 계약 문서 | 5장 표의 모든 항목이 확정 또는 "이번 릴리스 보류"로 결론 |
| W1 | `ABProfileManager.toc`, `Constants.lua`, `Core.lua` | `Interface: 120100` 추가, `VERSION 1.12.0` | Lua 전체 파싱 통과, 인게임 로드 오류 없음 |
| W2 | `Data/ItemLevelTable.lua` (83행 이전만) | 시즌 2 아이템 레벨표 | `validate_season2_itemlevel.py` 통과, `BISRewardProfiles` 무변경 |
| W2b | `UI/ItemLevelOverlay.lua` | 통화 ID·구렁 단계·패널 표시 | 통화 nil일 때 오류 대신 `-` 표시 |
| W3 | `Data/SilvermoonMapData.lua`, `UI/SilvermoonMapOverlay.lua`, `UI/MapPanel.lua` | 신규 지역 POI·alias | canonical/alias/child/dungeon/unknown mapID 각각 검증 |
| W4 | `Data/ProfessionKnowledge.lua`, `Data/ProfessionKnowledgeWaypoints.lua`, `Modules/ProfessionKnowledgeTracker.lua` | 12.1 지식 소스·리셋 정책 | 주간 리셋 경계에서 카운트 오차 없음 |
| W5 | `UI/MythicPlusRecordOverlay.lua`, `UI/StatsOverlay.lua`, `Locale.lua`, `Locale_Additions.lua`, `ABPM_ruRU_Final_v3.lua` | 기록 UI·스탯 호환·3개 로케일 | `validate_locale_contract.py` 통과 |
| W6 | `scripts/validate_season2_*.py`, `scripts/validate_locale_contract.py`, `scripts/run_season2_validation.ps1` | 검증 하네스 | 하네스가 W1~W5 산출물에서 전부 통과 |

파일 충돌 방지: 같은 파일을 두 wave가 동시에 수정하지 않습니다. `Locale*.lua`는 W5 단독 소유이므로 다른 wave는 문자열 키만 요청하고 직접 편집하지 않습니다.

### 각 wave의 내부 루프

```text
근거 수집
 → 실패하는 계약/검증 작성
 → 최소 구현
 → 좁은 검증
 → 별도 리뷰
 → 통합 검증
 → 인게임 시나리오
 → 실패 시 해당 wave로 환류
```

## 7. 신규 검증 하네스

| 스크립트 | 검사 내용 |
| --- | --- |
| `scripts/validate_season2_itemlevel.py` | 시즌명, 업그레이드 트랙, 구렁/M+/금고 행 수, rank·ilvl 일관성 |
| `scripts/validate_locale_contract.py` | `koKR`/`enUS`/`ruRU` 키 집합 일치, 빈 번역 검출 |
| `scripts/validate_season2_scope.py` | 3장 동결 파일 해시 일치, `ItemLevelTable.lua`의 `BISRewardProfiles` 이후 무변경 |
| `scripts/run_season2_validation.ps1` | 위 3종 + Lua 전체 파싱 + `git diff --check` + 기존 BIS 회귀 검증 순차 실행 |

기존 검증 명령은 `AGENTS.md`의 "검증 명령어" 절을 그대로 사용합니다. 2026-08-27 기준 전부 통과 상태입니다.

```text
validate_bis_catalog.py            ok: specs=40 rows=3330
validate_bis_season_preview_links  ok: raid=89 tier=65 crafted=28
validate_bis_tooltip_contract.py   ok (BISOverlay top-level locals 197)
```

## 8. 핵심 엣지케이스

- 시즌 1 SavedVariables로 업그레이드해도 창 위치·크기·탭·토글이 유지된다
- `koKR`/`enUS`/`ruRU`에서 같은 행 수와 레이아웃을 유지한다
- 통화나 POI API가 `nil`이면 오류 대신 `-` 또는 숨김으로 처리한다
- 전투 중 API 호출로 taint 또는 보호 기능 차단 팝업이 생기지 않는다
- `ChallengesFrame`이 나중에 로드돼도 훅이 정확히 한 번만 설치된다
- 지도 canonical/alias/child/dungeon/unknown mapID를 각각 검증한다
- 구렁 단계별 일반/Bountiful/금고 보상을 분리해 표시한다
- secret number를 산술 연산이나 문자열 포맷에 직접 전달하지 않는다
- 지도 전환 후 이전 시즌 라벨이나 재사용 버퍼가 남지 않는다
- 동결 대상 BIS 파일과 `BISRewardProfiles`가 byte-identical이다

인게임 QA는 `AGENTS.md`의 "인게임 회귀 체크리스트" 전체와 `/abpm debug on`, `/abpm bankcheck`, `/abpm bankreset`까지 포함합니다.

## 9. 진행 로그

작업할 때마다 이 표를 갱신합니다. 세션을 이어받는 쪽은 이 표를 먼저 읽습니다.

| Wave | 상태 | 담당 | 마지막 갱신 | 메모 |
| --- | --- | --- | --- | --- |
| W0 | 미착수 | - | 2026-08-27 | 빌드 정보만 확정 (`12.1.0` / `69465` / `120100`). 나머지 ID는 5장 참조 |
| W1 | 미착수 | - | 2026-08-27 | |
| W2 | 미착수 | - | 2026-08-27 | |
| W2b | 미착수 | - | 2026-08-27 | |
| W3 | 미착수 | - | 2026-08-27 | |
| W4 | 미착수 | - | 2026-08-27 | |
| W5 | 미착수 | - | 2026-08-27 | |
| W6 | 미착수 | - | 2026-08-27 | |
| G1 | 미착수 | - | 2026-08-27 | |
| G2 | 미착수 | - | 2026-08-27 | |
| 인게임 QA | 미착수 | - | 2026-08-27 | |
| 패키징 | 미착수 | - | 2026-08-27 | |

상태 값은 `미착수` / `진행중` / `리뷰대기` / `완료` / `보류` 중 하나를 씁니다.

## 10. 재개 프롬프트

새 세션에서 아래 내용을 그대로 사용합니다.

```text
저장소 E:\Dev_ai\wowaddon, 브랜치 codex/midnight-s2-update에서 Midnight 시즌 2(v1.12.0) 작업을 이어서 진행해.
먼저 DOC/SEASON2_HANDOFF.md를 읽고 9장 진행 로그에서 다음 수행할 wave를 고른다.
승인된 전제는 2장에 있고, 3장의 동결 파일은 절대 수정하지 않는다.
5장 미확정 데이터는 라이브 덤프 없이 추정값으로 채우지 않는다. 필요하면 인게임 명령을 요청한다.
작업 후에는 7장 검증을 실행하고, 9장 진행 로그를 갱신한 다음 결과를 보고한다.
```

## 11. 릴리스 마무리 체크

- `CHANGELOG.md`에 `1.12.0` 항목 추가
- `DOC/HANDOFF.md`에 v1.12.0 패치 메모 추가
- `DOC/releases/RELEASE_NOTES_v1.12.0.md` / `_EN.md` 작성
- `DOC/README.md` 인덱스 갱신
- `AGENTS.md`의 "현재 기준"과 프로젝트 개요 Interface 번호 갱신
- `CLAUDE.md`의 기준 버전 갱신 (현재 `v1.7.4`로 오래된 값이 남아 있음)
- `scripts/package_release.ps1` 실행 후 `dist/` 루트에 최신 ZIP만 유지, 이전 ZIP은 `dist/archive/`로 이동
- 로컬 배포는 `dist/` ZIP 생성까지만 수행하고 WoW 설치 폴더로 복사하지 않는다
