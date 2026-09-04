# AGENTS.md

This file provides guidance to Codex and other repository-aware agents when working with code in this repository.

## 프로젝트 개요

`ABProfileManager`는 WoW Retail (Interface 120100 = Patch 12.1.0, Midnight 확장팩) Lua 애드온이다. 액션바 프로필 관리, 전문기술 포인트 추적, 지도/스탯 오버레이, 전투메시지 설정 관리, BIS 추천 장비 카탈로그, 드랍 템렙/시즌 최고기록 오버레이를 한 애드온으로 처리한다.

**현재 기준**: `v1.13.0`, TOC `## Interface: 120100`, WoW 12.1.0 빌드 69465. 시즌은 Midnight 시즌 2(패치명 `Curse of Ula'tek`, 2026-08-18 시작).

시즌 2 범위와 인계 사항은 `DOC/SEASON2_HANDOFF.md`를 본다.

## 소스 주석 정책

- `ABProfileManager/` 아래 Lua 소스에는 주석이 없다. 설계 의도와 배경 설명은 `DOC/CODE_NOTES.md`에서 찾는다. 코드를 고치기 전에 이 문서를 먼저 본다.
- 새 주석을 소스에 다시 넣지 않는다. 설명이 필요하면 `DOC/CODE_NOTES.md`에 적는다.
- 제거는 `scripts/strip_lua_comments.py`가 담당한다. 스캐너로 문자열과 주석을 구분하고, 처리 전후 AST를 비교해 코드가 바뀌지 않았음을 확인한 파일만 쓴다. `--check`는 검사만 하고, `--extract <경로>`는 제거 대상 주석을 먼저 파일로 남긴다.
- 제외 대상: 동결 파일 9개(`Data/BISCatalog.lua`, `BISRuntimeScoring.lua`, `BISMythicVaultLinks.lua`, `BISSeasonPreviewLinks.lua`, `BISEncounterJournal.lua`, `MidnightS1MPlusDB.lua`, `BISData_Method.lua`, `StatPriorities.lua`, `StatPriorityTable.lua`)와 `Data/ItemLevelTable.lua`의 `ns.Data.BISRewardProfiles` 이후 블록. 이 블록은 주석까지 포함해 sha256으로 고정돼 있다.

## 검증 명령어

통합 검증은 아래 하나로 실행한다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_season2_validation.ps1
```

순서: Lua 전체 파싱 → `git diff --check` → 범위 보호 → 아이템 레벨표 → 로케일 계약 → 기존 BIS 검증 6종.

시즌 2 신규 검증기 3종:
- `scripts/validate_season2_scope.py` — 동결 파일이 변경되지 않았는지 확인
- `scripts/validate_season2_itemlevel.py` — `Data/ItemLevelTable.lua`의 값과 출처 확인
- `scripts/validate_locale_contract.py` — 로케일 키 계약 확인

릴리스 전에는 반드시 `-Strict`로 다시 돌린다. `-Strict`는 아이템 레벨표에서 외부 가이드만 근거인 값(`sources`의 `guide`)을 실패로 처리한다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_season2_validation.ps1 -Strict
powershell -ExecutionPolicy Bypass -File .\scripts\package_release.ps1
```

현재 `Data/ItemLevelTable.lua`의 `delves`와 `mythicPlus`가 `guide`라서 `-Strict`가 실패한다. 인게임 확인 전에는 릴리스할 수 없다. `raid`는 모험 안내서 전리품 목록으로, `pvp`와 `worldBoss`, `crafted`는 인게임 툴팁으로 확인을 마쳤다.

디버깅: 인게임에서 `/abpm debug on`

## 코드 구조

```text
ABProfileManager/
├── Core.lua
├── DB.lua
├── Events.lua
├── Commands.lua
├── Constants.lua
├── Locale.lua / Locale_Additions.lua
├── Modules/
├── Data/
└── UI/
```

## 핵심 패턴

- 모든 파일은 `local addonName, ns = ...` 네임스페이스를 공유한다.
- 각 모듈은 `Initialize()`를 구현하고 `Core.lua`의 `InitializeStartupModules()`에서 순서대로 호출된다.
- `global.settings`는 계정 공통 설정, `ui`는 창/오버레이 위치, 캐릭터별 데이터는 `"Realm-Character"` 키에 저장된다.
- `ns:SafeCall(target, methodName, ...)`는 optional 기능 nil 오류 방지용이다.
- `ns:RefreshUI()`는 전체 패널/오버레이 refresh 진입점이다.

## 회귀 민감 영역

1. 메인 UI 레이아웃
2. profession 카드/오버레이
3. typography 슬라이더
   - 스탯 오버레이 특화 tooltip은 전문화 특화 주문 tooltip data를 우선 렌더링
4. 지도 오버레이
5. 고스트 드래그 / 전투 중 대기열
6. BlizzardFrameManager (`uiPanel=true` 프레임만 `SetUserPlaced(true)`)
   - 저장 좌표가 없는 UIPanel 창은 `SetUserPlaced(true)`로 고정하지 않는다
   - `layoutVersion=2` 이전 저장 좌표는 1회 초기화한다
7. `SilvermoonMapOverlay.lua`, `StatsOverlay.lua`의 재사용 버퍼
   - WoW 12.1부터 전투/레이드 조우/쐐기/PvP 중에는 `C_UnitAuras`의 index·slot·instanceID 기반 조회가 Lua 오류를 낸다. spellID 기반 조회는 정상이다
   - 버프 hash는 실패 시 `AURA_SCAN_BACKOFF_SECONDS` 동안 조회를 멈추고 빈 문자열을 돌려준다. 부분 hash를 남기면 보호 상태가 오갈 때 signature가 흔들려 불필요한 refresh가 생기므로 빈 값으로 통일한다
8. `UI/BISOverlay.lua`
   - `SeasonGuard.dataSeason`이 `Data/ItemLevelTable.lua`의 `season`과 다르면 Encounter Journal 자동 랜딩, M+ 자동 점수화, preview snapshot 스캔, preview 순위 점수를 모두 멈춘다. 현재 둘 다 `Midnight Season 2`라 차단은 꺼져 있다. BIS 데이터를 새 시즌으로 갱신할 때 이 값을 함께 올린다
   - 상단 안내는 한 줄 고정에 줄바꿈이 꺼져 있다. 시즌이 어긋날 때만 `SeasonGuard.ApplyNotice()`가 `S1` 형태의 짧은 접두와 경고색을 붙인다. 시즌 이름을 그대로 붙이면 스탯 정책 요약이 잘린다
   - BIS 데이터를 새 시즌으로 갱신할 때 `SeasonGuard.dataSeason`도 함께 올린다. 올리지 않으면 자동 동작이 계속 꺼져 있다
   - 정적 후보는 `Data/BISCatalog.lua`만 읽고, 링크 점수는 `Data/BISRuntimeScoring.lua`로 계산한다
   - `GET_ITEM_INFO_RECEIVED` 핸들러의 캐시 기록은 `requested` 또는 `previewEntry` 게이트 안에 둔다. 이 이벤트에는 필터가 없어 세션 내 모든 아이템이 들어오고, 게이트 밖에서 캐시에 쓰면 BIS와 무관한 아이템까지 무제한으로 쌓인다
   - top-level local은 현재 `195`개다. `scripts/validate_bis_tooltip_contract.py`의 예산은 `198`, Lua 청크 상한은 `200`이다. 새 기능은 새 local 대신 기존 테이블 필드를 쓴다. 시즌 preview helper는 `SourcePreview` 테이블에 묶어 둔다
   - BIS 전용 item tooltip은 shopping tooltip 경로를 사용해 sell price `MoneyFrame` 렌더링을 차단한다
   - hover/자동 큐에서 Encounter Journal UI 상태를 바꾸거나 숨은 loot scan을 하지 않는다. 보호된 `C_EncounterJournal.SetTab`을 직접 호출하지 않으며, 전투 중에는 자동 랜딩을 건너뛴다
   - 스크롤 중 tooltip 렌더 억제, 점수 캐시, 아이템 요청 dedupe, 분산 큐로 rebuild 스로틀을 완화한다. `GET_ITEM_INFO_RECEIVED`는 visible row만 갱신한다
   - 드루이드 4특성 헤더 폭과 필터 겹침 여부를 같이 확인
9. `UI/ItemLevelOverlay.lua`
   - 구렁 표는 `11단계`까지만 유효하다. 시즌 2에서도 그대로다
   - `CREST_ID_BY_GRADE`는 안개문장(Mistcrest) 기준 `adv=3442, vet=3443, chmp=3444, hero=3445, myth=3446`
   - `worldBoss` 블록은 `world / normal / heroic / mythic` 4난이도로 렌더링된다
   - `보물지도 사용`, `나의 문장 / 나의 열쇠` 패널을 같이 확인
10. `UI/MythicPlusRecordOverlay.lua`
    - `평점 / 던전명`만 표시

## 인게임 회귀 체크리스트

- 전투부대 은행 세션 보호: `/abpm bankcheck`, `/abpm bankreset` 동작 확인
- 은행 NPC 접근 시 `BANKFRAME_OPENED` 정상 감지 여부
- 로그아웃/존 이동 후 재접속 시 은행 잠김 현상 없는지 확인
- profession 카드 폭과 체크박스 레이아웃, 오버레이 상세/요약/최소
- 전투메시지 설정 버튼 선택 상태
- 지도 오버레이가 외부 월드맵에서만 표시되는지
- 퀘스트 목록 패널 표시와 퀘스트 ID 링크 클릭 동작
- 스탯 overlay drag/hitbox
- 전투/레이드 조우/쐐기/PvP 중 aura 조회 Lua 오류가 없는지 확인
- BIS 목록이 시즌 2 아이템만 담고 출처가 공식 한글명으로 표시되는지 확인
- BIS 드랍 출처 클릭 시 시즌 2 던전의 모험 안내서로 이동하는지 확인
- 상단 안내에 `S1` 같은 시즌 접두가 나타나지 않는지 확인
- BIS 필터 / 열 폭 / 마지막 열 가림 여부
- BISOverlay 로드 시 `main function has more than 200 local variables` 오류가 없는지 확인
- BIS hover 뒤 액션바 / 모험 안내서 tooltip에서 `MoneyFrame.lua secret number` 오류가 재발하지 않는지 확인
- `레이드 off + 쐐기만 on`에서 쐐기 행과 던전명이 유지되는지
- 드랍템 레벨 오버레이 우측 패널 수치와 문장 보유량 확인
- 구렁 탭이 `11단계`까지만 나오는지
- 시즌 최고기록 오버레이의 `평점 / 던전명` 표시 확인

## 주요 서브시스템

### Profession 추적

이벤트: `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED`

- 주간 퀘스트 변형 목록은 `match = "any"`다. questID가 하나라도 빠지면 그 주 완료를 감지하지 못한다. 12.1 구간은 제작 7종 `93690~93696`, 마법부여 `93697~93699`, 약초채집 `93700~93704`, 채광 `93705~93709`, 무두질 `93710~93714`로 연속이다.
- 평판 서적은 직업마다 2종이다. 시즌 1 세력 서적 1종과 12.1 `Zul'jarra's Forces` 서적 `Demystifyin': <직업>` 1종이며 각 10점이다. questID는 `96459`, `96511~96520`이다.
- `Modules/ProfessionKnowledgeTracker.lua`의 `translateObjectiveName`은 한국어 선택일 때만 번역표를 적용한다. 영어/러시아어에서는 원문 이름을 그대로 쓴다.

### 전투메시지 관리

`_v2` CVar 우선, 없으면 구형 이름 fallback. 모드 값: `1=위로`, `2=아래로`, `3=부채꼴`

### BIS 추천 장비 카탈로그

현재 상태: 시즌 2로 재생성 완료(`--overall-only`, 657행: raid 393 / crafted 78 / mythicplus 107 / tier 79). M+ preview selector는 2026-09-04 인게임 확인으로 `12849`를 확정해 자동 점수화가 켜졌다. raid/tier/crafted 시즌 preview selector는 아직 확인 전이라 그쪽 툴팁만 기본 `itemLink`로 표시된다. `DOC/TODO.md` 5장 참조.

런타임 데이터:
- `Data/BISCatalog.lua`
- `Data/MidnightS1MPlusDB.lua`
- `Data/BISRuntimeScoring.lua`
- `Data/BISMythicVaultLinks.lua`
- `Data/BISSeasonPreviewLinks.lua`
- `Data/BISEncounterJournal.lua`

생성 입력:
- `Data/BISData_Method.lua` — 와우헤드 전문화별 overall BiS. 카탈로그의 유일한 후보 원천이다
- `DOC/MidnightS1_MPlus_Addon_Master_v1.7.md`, `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua` — 40개 전문화 스탯 우선순위 정책. 파일명에 `MidnightS1`이 붙어 있지만 시즌 1 BIS 데이터가 아니다. 점수화 코어 구조는 `12.0.5` 시점 그대로이고, `DB.SPECS`의 `priority`와 `weights`는 와우헤드 전문화별 stat-priority 페이지의 시즌 2 값으로 갱신했다. 카탈로그 행의 검증 메타데이터도 여기서 나온다

생성/검증 스크립트:
- `scripts/refresh_wowhead_bis.py` — 와우헤드 수집. `--review <경로>`는 파일을 쓰지 않고 결과만 JSON으로 남긴다
- `scripts/build_bis_catalog.py`, `scripts/build_bis_runtime_scoring.py`
- `scripts/validate_bis_mythic_vault_links.py`, `scripts/validate_bis_season_preview_links.py`
- `scripts/validate_bis_tooltip_contract.py`, `scripts/validate_bis_encounter_journal.py`
- `scripts/validate_bis_catalog.py`, `scripts/audit_bis_data.py`
- `scripts/rebuild_bis_database.ps1`

중요 규칙:
- 런타임 merge/정규화/웹 조회 금지
- `mythicplus / raid / crafted / tier` 4개 필터 모두 기본 on. 필터 후 visible list 기준으로 `1순위 / 2순위 / 3순위+`를 재번호화
- 카탈로그는 `scripts/build_bis_catalog.py --overall-only`로 와우헤드 overall 데이터만 사용해 만든다. 시즌 1 후보 시드와 문서 입력은 제거됐다
- `ns.Data.BISSpecPolicies` 블록은 `scripts/build_bis_catalog.py`가 재생성하지 않고 기존 값을 옮긴다. 값을 바꾸려면 `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`를 고치고 `scripts/build_bis_runtime_scoring.py`를 돌린다. 이 스크립트가 `BISSpecPolicies`와 각 행의 `statPrioritySummary`를 함께 고친다
- DB2 빌드 접두사는 TOC의 Interface 번호에서 유도한다. 하드코딩하면 다음 패치에서 신규 아이템 메타데이터를 찾지 못한다
- 한글명은 공식 한글 클라이언트, Blizzard KO 문서, Wowhead KO 개별 페이지만 허용한다. 영어명 임의 번역과 위키 표기는 쓰지 않는다
- 검증 snapshot이 없는 후보는 기존 정적 순서를 유지한다
- 장비/가방 링크는 정렬이나 hover에서 스캔하지 않고, 보유 체크 on 시 저장용으로만 한 번 찾는다
- 임의 bonusID를 조립하지 않는다. M+ selector와 full link override는 `Data/BISMythicVaultLinks.lua`, raid/tier/crafted 시즌 preview selector와 override는 `Data/BISSeasonPreviewLinks.lua`에서만 관리하고 각각 대응 validate 스크립트로 확인한다
- M+ selector는 `12849`로 확정했다. `GetDetailedItemLevelInfo("item:268209::::::::::::1:12849")`가 `318`을 돌려준다. `Data/BISSeasonPreviewLinks.lua`의 raid/tier/crafted selector는 아직 확인 전이라 비어 있다. 값을 지어내면 잘못된 아이템 레벨의 preview가 만들어지므로 확인 전에는 넣지 않는다
- 시즌 M+ 던전 풀이 바뀌면 `Data/BISEncounterJournal.lua`의 현재 시즌 tier와 `JournalInstanceID`만 갱신하고 `scripts/validate_bis_encounter_journal.py`로 확인한다
- selector 또는 item string 템플릿이 바뀌면 이전 snapshot cache를 초기화한다. 다른 템렙으로 해석된 preview는 같은 세션에서 다시 큐에 넣지 않는다
- hover는 검증된 preview item string을 먼저 시도하고, 없으면 클라이언트가 로드한 기본 `itemLink` 또는 `item:<itemID>`로 fallback한다. 어느 경로든 addon-owned Blizzard `GameTooltip:SetHyperlink()`로 표시한다
- `scripts/rebuild_bis_database.ps1`는 카탈로그 생성(`--overall-only`) → v1.7 scoring 입력 → Myth preview selector/override validate → non-M+ season preview validate → tooltip contract validate → Encounter Journal validate → catalog validate → audit 순서로 실행한다

### 아이템 레벨 오버레이 + 문장/열쇠 패널

시즌 2 고정값:
- `CREST_ID_BY_GRADE = { adv=3442, vet=3443, chmp=3444, hero=3445, myth=3446 }` (안개문장)
- `DELVE_RESTORED_KEY_CURRENCY_ID = 3028` (시즌 1 값 그대로 유효)
- `gradeMax = { adv=282, vet=295, chmp=308, hero=321, myth=334 }`. 탐험가(`expl`) 트랙은 시즌 2에 없어 제거했다
- 랭크 사다리는 기준값 `+0,+3,+6,+10,+13,+16` 6단계. 제작 품질 사다리는 `+0,+3,+6,+9,+13` 5단계
- 제작 base `318`, r5 `331`
- 구렁 최고 단계는 `11단계`

### 전투부대 은행(Warband Bank) 세션 보호

`Events.lua` 내 구현. 유령 세션(ghost session) 및 잠김 현상 방어.

핵심 함수:
- `abpmCloseBankSessions()` (local) — 모든 은행 프레임 닫기 + 세션 플래그 초기화
- `ns.ABPM_CanUseWarbandBank()` — `C_Bank.HasBankType` / `C_Bank.CanUseBank` 사전 점검, 불가 시 채팅 경고
- `ns.ABPM_ResetBankSession()` — 강제 세션 초기화, 외부 모듈/명령어에서 호출 가능

이벤트:
- `PLAYER_LEAVING_WORLD`, `PLAYER_LOGOUT` → `abpmCloseBankSessions()` 호출
- `BANKFRAME_OPENED` / `BANKFRAME_CLOSED` → `abpmBankSessionActive` 플래그 관리
- `UI_ERROR_MESSAGE` → 은행 관련 에러 감지 시 세션 자동 정리

슬래시 명령어:
- `/abpm bankcheck` — 전투부대 은행 가용 상태 출력
- `/abpm bankreset` — 세션 강제 초기화

## 미완성 기능

- 스탯 오버레이 `mythicPlusMode` 저장 키는 이전 SavedVariables 호환용으로만 유지
- 경매장 현행 확장팩 필터 자동 선택
- `Data/ItemLevelTable.lua`의 `delves / mythicPlus` 출처를 인게임 확인으로 바꿔 `guide`를 없애야 `-Strict` 검증이 통과한다. `raid`는 `dump`, `pvp`와 `worldBoss`·`crafted`는 `tooltip`으로 승급했다
- BIS 시즌 2 raid/tier/crafted preview selector 확정: `BISSeasonPreviewLinks`의 selector item string을 인게임에서 확인한 뒤 반영한다. M+ 쪽 `generatedPreviewBonusListID = 12849`는 2026-09-04에 확정했다. `DOC/TODO.md` 5장 참조

## 릴리스 프로세스

`DOC/RELEASE_PROCESS.md` 참조.

현재 로컬 패키지 정책:
- `dist/` 루트에는 최신 ZIP만 유지, 이전 로컬 ZIP은 `dist/archive/`로 이동
- 로컬 배포는 작업공간 `dist/` ZIP 생성까지만 수행하고 WoW 설치 폴더로 복사하지 않는다

## 문서 위치

- 사용자 가이드: `README.md`
- 인트로 자산: `ABProfileManager/ADDON_INTRO.txt`
- 아키텍처: `DOC/ARCHITECTURE.md`
- 코드 주석 대체 노트: `DOC/CODE_NOTES.md`
- 인게임 확인 체크리스트: `DOC/INGAME_CHECKLIST.md`
- 현재 상태/인계: `DOC/HANDOFF.md`
- 시즌 2 인계: `DOC/SEASON2_HANDOFF.md`
- 배포 절차: `DOC/RELEASE_PROCESS.md`
- 보안 검토: `DOC/SECURITY_REVIEW.md`
