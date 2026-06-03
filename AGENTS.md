# AGENTS.md

This file provides guidance to Codex and other repository-aware agents when working with code in this repository.

## 프로젝트 개요

`ABProfileManager`는 WoW Retail (Interface 120005, 120007 = Patch 12.0.5/12.0.7 계열, Midnight 확장팩) Lua 애드온이다. 액션바 프로필 관리, 전문기술 포인트 추적, 지도/스탯 오버레이, 전투메시지 설정 관리, BIS 추천 장비 카탈로그, 드랍 템렙/시즌 최고기록 오버레이를 한 애드온으로 처리한다.

**현재 기준**: `v1.11.7 로컬 패치 기반`

## 검증 명령어

```bash
@'
from luaparser import ast
import pathlib
for path in pathlib.Path("ABProfileManager").rglob("*.lua"):
    ast.parse(path.read_text(encoding="utf-8"))
print("ok")
'@ | python -

git diff --check

python .\scripts\validate_bis_catalog.py
python .\scripts\validate_bis_mythic_vault_links.py
python .\scripts\validate_bis_tooltip_contract.py
python .\scripts\validate_bis_encounter_journal.py
python .\scripts\audit_bis_data.py

powershell -ExecutionPolicy Bypass -File .\scripts\package_release.ps1
```

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
   - 스탯 오버레이 특화 tooltip은 현재 전문화 특화 주문 tooltip data를 우선 렌더링
4. 지도 오버레이
5. 고스트 드래그 / 전투 중 대기열
6. BlizzardFrameManager (`uiPanel=true` 프레임만 `SetUserPlaced(true)`)
   - 저장 좌표가 없는 UIPanel 창은 `SetUserPlaced(true)`로 고정하지 않는다
   - `layoutVersion=2` 이전 저장 좌표는 1회 초기화한다
7. `SilvermoonMapOverlay.lua`, `StatsOverlay.lua`의 재사용 버퍼
8. `UI/BISOverlay.lua`
   - 정적 후보는 `Data/BISCatalog.lua`만 읽고, 실제 링크 점수는 `Data/BISRuntimeScoring.lua`를 통해 계산한다
   - 상단 아이템 토글이 켜져 있으면 extracted ItemBonus DB2 build `12.0.1.66838`에서 검토한 `Data/BISMythicVaultLinks.lua`의 내장 selector `12801`로 M+ `Myth 1/6 272` preview를 만들고 한 번 스캔해 계정 SavedVariables snapshot schema v3로 저장한다
   - 생성 preview 또는 수동 override full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 snapshot의 실제 스탯 / 실제 ilvl로 점수화한다
   - selector 또는 item string 템플릿이 바뀌면 이전 snapshot cache를 초기화하고, 다른 템렙으로 해석된 preview는 세션 음성 캐시로 반복 재시도를 막는다
   - preview hyperlink 비동기 로드는 itemID wake signal로만 사용하고, 완료 뒤 exact selector 링크를 다시 검증한다. 실패 callback은 timeout으로 정리하고 링크별 재시도는 세션 최대 2회로 제한한다
   - 던전 종료 `Hero 3/6 266` 링크만 있으면 `Myth 1/6 272` 기준 라벨은 표시하되 점수는 미검증 fallback으로 유지한다
   - 임의 bonusID를 조립하지 않는다. 검토된 시즌 selector만 `Data/BISMythicVaultLinks.lua`에서 관리한다
   - M+ hover는 검증 snapshot의 full item link를 addon-owned Blizzard `GameTooltip:SetHyperlink()`에 전달해 Blizzard 원본 2차 스탯을 렌더링한다
   - raid/crafted/tier hover는 검증된 시즌 full link가 없으면 임의 bonusID를 만들지 않고 클라이언트가 로드한 기본 `itemLink`를 addon-owned Blizzard `GameTooltip:SetHyperlink()`에 전달해 표시한다
   - BIS 전용 item tooltip은 shopping tooltip 경로를 사용해 sell price `MoneyFrame` 렌더링을 차단한다
   - hover/자동 큐에서 Encounter Journal UI 상태를 바꾸거나 숨은 loot scan을 하지 않는다
   - M+ 클릭 랜딩은 `Data/BISEncounterJournal.lua`의 검증 `JournalInstanceID`만 사용하고, 현재 시즌 tier 선선택과 availability guard를 유지한다
   - Encounter Journal 랜딩에서 보호된 `C_EncounterJournal.SetTab`을 직접 호출하지 않는다
   - 전투 중에는 자동 랜딩을 건너뛰어 Blizzard 보호 기능 차단 팝업을 방지한다
   - 스크롤 중 tooltip 렌더 억제, 점수 캐시, 아이템 요청 dedupe, 분산 큐로 rebuild 스로틀을 완화한다
   - `GET_ITEM_INFO_RECEIVED`는 visible row만 갱신한다
   - crafted/tier는 Encounter Journal 랜딩 대상이 아니다
   - 드루이드 4특성 헤더 폭과 필터 겹침 여부를 같이 확인
9. `UI/ItemLevelOverlay.lua`
   - 구렁 표는 현재 `11단계`까지만 유효
   - `보물지도 사용`, `나의 문장 / 나의 열쇠` 패널을 같이 확인
10. `UI/MythicPlusRecordOverlay.lua`
   - `평점 / 던전명`만 표시

## 인게임 회귀 체크리스트

- 전투부대 은행 세션 보호: `/abpm bankcheck`, `/abpm bankreset` 동작 확인
- 은행 NPC 접근 시 `BANKFRAME_OPENED` 정상 감지 여부
- 로그아웃/존 이동 후 재접속 시 은행 잠김 현상 없는지 확인
- profession 카드 폭과 체크박스 레이아웃
- profession overlay 상세/요약/최소
- 전투메시지 설정 버튼 선택 상태
- 지도 오버레이가 외부 월드맵에서만 표시되는지
- 퀘스트 목록 패널이 정상 표시되는지
- 퀘스트 ID 링크 클릭 동작
- 스탯 overlay drag/hitbox
- BIS 오버레이 드랍 출처 클릭 → 비전투 중 모험 안내서 loot 탭 랜딩
- 전투 중 BIS 드랍 출처 클릭 → 자동 랜딩 생략, Blizzard 보호 기능 차단 팝업 없음
- BIS 필터 / 열 폭 / 마지막 열 가림 여부
- BIS 상단 아이템 토글 on/off, M+ selector preview 자동 생성, `Myth 1/6 272` 검증 preview만 자동 점수화되는지 확인
- 던전 종료 `Hero 3/6 266` 링크만 있을 때 `Myth 1/6 272` 기준 라벨은 표시되고 점수는 미검증 fallback으로 유지되는지 확인
- BIS tooltip이 addon-owned Blizzard `GameTooltip:SetHyperlink()` 경로로 원본 2차 스탯을 표시하고 M+ 272 snapshot / raid-craft-tier 기본 itemLink 캐시를 재사용하는지 확인
- BIS hover 뒤 액션바 / 모험 안내서 tooltip에서 `MoneyFrame.lua secret number` 오류가 재발하지 않는지 확인
- M+ 자동 점수 분산 큐가 rebuild를 과도하게 반복하지 않는지 확인
- `레이드 off + 쐐기만 on`에서 쐐기 행과 던전명이 유지되는지
- 드랍템 레벨 오버레이 우측 패널 수치 확인
- 구렁 탭이 `11단계`까지만 나오는지
- 시즌 최고기록 오버레이의 `평점 / 던전명` 표시 확인

## 주요 서브시스템

### Profession 추적

이벤트: `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED`

### 전투메시지 관리

`_v2` CVar 우선, 없으면 구형 이름 fallback. 모드 값: `1=위로`, `2=아래로`, `3=부채꼴`

### BIS 추천 장비 카탈로그

런타임 데이터:
- `Data/BISCatalog.lua`
- `Data/MidnightS1MPlusDB.lua`
- `Data/BISRuntimeScoring.lua`
- `Data/BISMythicVaultLinks.lua`
- `Data/BISEncounterJournal.lua`

생성 입력:
- `Data/BISData_Method.lua`
- `Data/BISData.lua`
- `DOC/wow_midnight_s1_mplus_bis_final.md`
- `DOC/wow_midnight_s1_mplus_bis_korean_companion.md`
- `DOC/MidnightS1_MPlus_Addon_Master_v1.3.md`
- `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`
- `DOC/MidnightS1_MPlus_Addon_Master_v1.7.md`
- `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`

생성 스크립트:
- `scripts/refresh_wowhead_bis.py`
- `scripts/refresh_wowhead_mplus_fallbacks.py`
- `scripts/build_bis_catalog.py`
- `scripts/build_bis_runtime_scoring.py`
- `scripts/validate_bis_mythic_vault_links.py`
- `scripts/validate_bis_tooltip_contract.py`
- `scripts/validate_bis_encounter_journal.py`
- `scripts/rebuild_bis_database.ps1`

중요 규칙:
- 런타임 merge/정규화/웹 조회 금지
- `mythicplus / raid / crafted / tier` 4개 필터 모두 기본 on
- 필터 후 visible list 기준으로 `1순위 / 2순위 / 3순위+`를 재번호화
- 정적 후보 풀은 v1.3 입력을 유지하고, 전문화별 스탯 우선순위와 실제 `itemLink` 점수는 v1.7 컴팩트 코어를 사용한다
- 검증 snapshot이 없는 후보는 기존 정적 순서를 유지한다
- 장비/가방 링크는 정렬이나 hover에서 스캔하지 않고, 보유 체크 on 시 저장용으로만 한 번 찾는다
- 상단 아이템 토글이 켜지면 M+ 후보는 extracted ItemBonus DB2 build `12.0.1.66838`에서 검토한 `Data/BISMythicVaultLinks.lua`의 내장 selector `12801`로 preview item string을 만들고 계정 SavedVariables snapshot schema v3로 저장한다
- 생성 preview 또는 수동 override full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 snapshot의 실제 스탯 / 실제 ilvl로 점수화한다. 던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨만 표시하고 점수는 미검증 fallback으로 유지한다
- M+ hover는 검증 snapshot의 full item link를 addon-owned Blizzard `GameTooltip:SetHyperlink()`에 전달해 원본 2차 스탯을 표시하고, shopping tooltip 경로로 sell price `MoneyFrame` 렌더링을 차단한다
- raid/crafted/tier hover는 검증된 시즌 full link가 없으면 클라이언트가 로드한 기본 `itemLink`를 세션 캐시에 저장하고 addon-owned Blizzard `GameTooltip:SetHyperlink()`로 표시한다
- selector 또는 item string 템플릿 변경 시 기존 snapshot cache는 초기화한다. 다른 템렙으로 해석된 preview는 같은 세션에서 다시 큐에 넣지 않는다
- M+ 자동 검색은 임의 bonusID를 조립하지 않으며, hover/자동 큐에서 Encounter Journal UI 상태를 변경하지 않는다
- Encounter Journal 랜딩에서 보호된 `C_EncounterJournal.SetTab` 직접 호출을 사용하지 않으며, 전투 중에는 자동 랜딩을 건너뛴다
- `scripts/rebuild_bis_database.ps1`는 v1.3 카탈로그 입력 → v1.7 scoring 입력 → Myth preview selector/override validate → tooltip contract validate → Encounter Journal validate → catalog validate → audit 순서로 실행한다
- M+/tier 추가는 v1.3 파일만 갱신할 수 있고, 점수 정책은 v1.7 파일에서 관리한다. raid/crafted는 아직 기존 `BISCatalog.lua` 보존 seed이므로 완전 단일 seed 재생성은 후속 범위다
- 시즌 selector 교체 또는 예외 항목용 `Myth 1/6 272` full link override 추가는 `Data/BISMythicVaultLinks.lua`만 갱신하고 `scripts/validate_bis_mythic_vault_links.py`로 확인한다
- 시즌 M+ 던전 풀이 바뀌면 `Data/BISEncounterJournal.lua`의 현재 시즌 tier와 `JournalInstanceID`만 갱신하고 `scripts/validate_bis_encounter_journal.py`로 확인한다

### 아이템 레벨 오버레이 + 문장/열쇠 패널

현재 고정값:
- `CREST_ID_BY_GRADE = { adv=3383, vet=3341, chmp=3343, hero=3345, myth=3347 }`
- `DELVE_RESTORED_KEY_CURRENCY_ID = 3028`
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
- 시즌 교체 시 BIS M+ 던전 `JournalInstanceID`와 현재 시즌 tier 재검증

## 릴리스 프로세스

`DOC/RELEASE_PROCESS.md` 참조.

현재 로컬 패키지 정책:
- `dist/` 루트에는 최신 ZIP만 유지
- 이전 로컬 ZIP은 `dist/archive/`로 이동
- 로컬 배포는 작업공간 `dist/` ZIP 생성까지만 수행하고 WoW 설치 폴더로 복사하지 않는다

## 문서 위치

- 사용자 가이드: `README.md`
- 인트로 자산: `ABProfileManager/ADDON_INTRO.txt`
- 아키텍처: `DOC/ARCHITECTURE.md`
- 현재 상태/인계: `DOC/HANDOFF.md`
- 배포 절차: `DOC/RELEASE_PROCESS.md`
- 보안 검토: `DOC/SECURITY_REVIEW.md`
