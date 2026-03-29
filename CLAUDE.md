# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

`ABProfileManager`는 WoW Retail (Interface 120001 = Patch 12.0.1, Midnight 확장팩) Lua 애드온이다. 액션바 프로필 관리, 전문기술 포인트 추적, 지도/스탯 오버레이, 전투메시지 설정 관리, BIS 인던 드랍 정보 오버레이 등을 한 애드온으로 처리한다.

**현재 버전**: v1.5.1

## 검증 명령어

```bash
# Lua 구문 전체 검사 (수정 후 반드시 실행)
python -c "import pathlib, sys; from luaparser import ast; errors=[f for f in pathlib.Path('ABProfileManager').rglob('*.lua') if not (lambda f: (ast.parse(f.read_text(encoding='utf-8')), True) or True)(f)]; [print(e) for e in errors]"

# 공백 오류 검사
git diff --check

# 릴리스 패키징 (PowerShell)
powershell -ExecutionPolicy Bypass -File .\scripts\package_release.ps1
```

디버깅: 인게임에서 `/abpm debug on` 명령으로 디버그 로그 활성화.

## 코드 구조

```
ABProfileManager/
├── Core.lua          # 네임스페이스 초기화, 모듈 부트스트랩
├── DB.lua            # SavedVariables(ABPM_DB) 초기화 및 관리
├── Events.lua        # WoW 이벤트 핸들러 (ADDON_LOADED, PLAYER_LOGIN 등)
├── Commands.lua      # /abpm 슬래시 명령 처리
├── Constants.lua     # 게임 상수 (바, 슬롯, 모드)
├── Locale.lua / Locale_Additions.lua  # 한국어(koKR) 기본 / 영어(enUS) fallback
├── Modules/          # 핵심 로직 (13개 모듈)
├── Data/             # 정적 데이터 (Defaults, ProfessionKnowledge, SilvermoonMapData, StatPriorities, ItemLevelTable, BISData)
└── UI/               # 사용자 인터페이스 (18개 모듈, BISOverlay/ItemLevelOverlay 포함)
```

### 핵심 패턴

**네임스페이스**: 모든 파일이 `local addonName, ns = ...`로 공유 네임스페이스를 사용한다.

**모듈 초기화**: 각 모듈은 `Initialize()` 메서드를 구현하고 `Core.lua`의 `InitializeStartupModules()`에서 순서대로 호출된다. `_initialized` 플래그로 중복 초기화를 방지한다.

**SavedVariables 구조**:
- `global.settings` — 언어, 오버레이 표시, typography 오프셋, 지도 필터 등 계정 공통 설정
- `ui` — 창/오버레이 위치
- 캐릭터별 — `"RealmName-CharacterName"` 키로 profession 진행상태, 템플릿, 전투메시지 설정 저장

**안전 호출**: `ns:SafeCall(target, methodName, ...)` — 선택 기능의 nil 오류 방지용.

**UI Refresh**: `ns:RefreshUI()`로 모든 패널/오버레이에 일괄 브로드캐스트.

## 회귀 민감 영역

다음 영역은 변경 시 인게임 직접 검증이 필요하다:

1. **메인 UI 레이아웃** — 큰 재배치 금지, overflow 보정 위주로만 접근
2. **profession 카드/오버레이** — 정렬, 여백, 폰트를 여러 번 맞춘 상태
3. **typography 슬라이더** — 전역 영향, font만 바꾸지 말고 overflow/hitbox까지 함께 확인
4. **지도 오버레이** — 내부 인스턴스/마이크로맵에 뜨지 않게 유지, child/detail map에서 부모 라벨 억지로 표시 금지
5. **고스트 드래그 / 전투 중 대기열** — 항상 보수적으로 처리
6. **BlizzardFrameManager** — `SetUserPlaced(true)`는 `uiPanel=true` 프레임에만 적용. WorldMapFrame에 적용 시 WoW compact 모드 전환 → 지도 오른쪽 퀘스트 목록 패널 숨겨짐. `UpdateUIPanelPositions` 훅도 `uiPanel=true` 프레임만 대상으로 해야 함 — 전체 적용 시 WorldMapFrame `ClearAllPoints` 반복으로 퀘스트 목록 주기적 소실.
7. **GC 최적화 버퍼** — `SilvermoonMapOverlay.lua`와 `StatsOverlay.lua`에 모듈 레벨 재사용 버퍼 선언. 이 버퍼들(`_layoutPoints`, `_candidateBuf`, `_snapshotParts` 등)을 제거하거나 함수 내부로 이동하면 GC spike 재발.
8. **BIS 오버레이 tooltip 품질 표시** — `GameTooltipTextLeft1` 색상을 에픽 보라(0.80, 0.35, 1.00)로 강제 설정. WoW DB 베이스 아이템은 파란색이나 M+ 실착용은 에픽 이상임을 표시. 이 방식은 bonus ID 없이 색상만 수정.
9. **문장 수 패널 통화 ID** — `UI/ItemLevelOverlay.lua`의 `CREST_CURRENCY_IDS` 테이블. 영웅(3345) 확인, 나머지 추정. "?" 표시 시 인게임 `/dump C_CurrencyInfo.GetCurrencyInfo(ID)` 로 확인 후 수정.

인게임 회귀 체크리스트:
- profession 카드 폭과 체크박스 레이아웃
- profession overlay 상세/요약/최소 모드
- 전투메시지 설정 체크박스와 위로/아래로/부채꼴 버튼 선택 상태
- 지도 오버레이가 외부 월드맵에서만 표시되는지
- 지도를 열었을 때 오른쪽 퀘스트 목록이 정상 표시되는지
- 퀘스트 ID 링크 클릭 동작
- 스탯 overlay drag/hitbox
- BIS 오버레이 던전 헤더 클릭 → 모험 안내서 열림
- 드랍템 레벨 오버레이 문장 수 사이드 패널 "?" 여부 확인

## 주요 서브시스템 작동 방식

### Profession 추적
이벤트: `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED` 후 follow-up refresh 포함. 관련 파일: `Modules/ProfessionKnowledgeTracker.lua`, `Data/ProfessionKnowledge.lua`.

### 전투메시지 관리
`_v2` CVar 우선, 없으면 구형 이름 fallback. 모드 값: `1=위로`, `2=아래로`, `3=부채꼴`. 관련 파일: `Modules/CombatTextManager.lua`, `UI/ConfigPanel.lua`.

### 지도 오버레이
정적 좌표 기반. 패치 후 drift 가능. 보정 시 `Data/SilvermoonMapData.lua`와 `UI/SilvermoonMapOverlay.lua`를 함께 수정.

### TomTom 연동
선택적 연동(`Modules/TomTomBridge.lua`). 하란다르/공허폭풍 일부 1회성 보물은 해당 지역 진입 후 waypoint 생성. TomTom 이슈 제보 시 지역 진입 여부와 map lineage부터 확인.

### BlizzardFrameManager
`Modules/BlizzardFrameManager.lua`. MANAGED_FRAMES 목록의 프레임에 SetMovable + 위치 저장/복원 적용. `uiPanel=true` 프레임(CharacterFrame, QuestLogFrame 등)은 `SetUserPlaced(true)` 적용 — WoW UIPanelLayout 재배치 방지. WorldMapFrame 등 비UIPanel 프레임은 `SetUserPlaced` 건드리지 않음.

### 이벤트 디바운싱
`Events.lua`에서 고빈도 이벤트를 0.15초 내 1회로 합산:
- `QUEST_LOG_UPDATE` → `refreshQuestPanel()` (QuestManager:Scan은 퀘스트당 5+ API 호출)
- `UNIT_AURA/STATS/COMBAT_RATING_UPDATE` 등 → `refreshStatsOverlay()`
새 이벤트 핸들러 추가 시 비활성 상태 early return과 디바운스 패턴 함께 적용할 것.

### BIS 인던 드랍 오버레이
`UI/BISOverlay.lua`. 전클래스/전특성(39개 스펙) BIS 인던 드랍 아이템을 탭별로 표시 (던전/레이드/월드보스/제작). 행 풀(pool) 패턴으로 재활용. 던전 헤더 클릭 시 WoW 모험 안내서(EncounterJournal) 열기(`DUNGEON_EJ_IDS` 테이블). M+ 툴팁은 `GameTooltipTextLeft1` 색상 강제로 에픽 표시. 마우스 휠 스케일 지원.
- `_isDungeonHeader` / `_ejDungeonName` 플래그: `resetRow()`에서 초기화, `RebuildContent` 헤더 생성 시 설정
- Midnight 신규 던전 EJ ID 미확인: `마이사라 동굴`, `공결점 제나스`, `윈드러너 첨탑` → `nil`로 마킹, 인게임 확인 후 수정

### 아이템 레벨 오버레이 + 문장 수 패널
`UI/ItemLevelOverlay.lua`. 던전/레이드/M+/제작 탭별 드랍 템렙 표 + 위대한 금고 컬럼. 우측에 `EnsureCrestPanel()` / `UpdateCrestPanel()` 으로 생성한 자식 프레임 — 현재 보유 문장(Crest) 수 실시간 표시. `C_CurrencyInfo.GetCurrencyInfo(id)` 사용.
- `CREST_CURRENCY_IDS` 테이블: 영웅(3345) 확인, 나머지 3342~3346 추정 — "?" 표시 시 인게임 `/dump` 로 확인

## 숨겨진 미완성 기능

수정 전 반드시 인지할 것:

- **스탯 오버레이 쐐기(M+) 우선순위 모드**: `UI/ConfigPanel.lua`에서 `mythicPlusCheck:Hide()`로 숨김 처리. 재개 시 `UI/StatsOverlay.lua`의 `BuildSnapshot` `isMplus` 분기, `DB.lua`의 `IsStatsOverlayMythicPlusMode`, `Data/StatPriorities.lua`의 `ns.Data.StatPrioritiesMythicPlus` 함께 확인.
- **경매장 현행 확장팩 필터 자동 선택**: `UI/ConfigPanel.lua`에서 `auctionHouseFilterCheck:Hide()`로 숨김. WoW 보안 시스템에 의해 `GetText()` taint 발생으로 동작 불가. `Events.lua`에 코드 유지.
- **BIS 던전 EJ ID 미확인 (Midnight 신규 던전)**: `마이사라 동굴`, `공결점 제나스`, `윈드러너 첨탑`의 EncounterJournal instanceID가 현재 `nil`. 클릭 시 모험 안내서는 열리나 해당 던전으로 이동하지 않음. 인게임 `EJ_GetInstanceInfo()` 또는 Wowhead로 확인 후 `UI/BISOverlay.lua`의 `DUNGEON_EJ_IDS` 수정.
- **문장 수 통화 ID 미확인**: `UI/ItemLevelOverlay.lua`의 `CREST_CURRENCY_IDS`. 영웅(3345) 외 추정값. "?" 표시 시 `/dump C_CurrencyInfo.GetCurrencyInfo(ID)`로 각 ID 확인 후 수정.

## 에이전트 팀 구조 (`sub/`)

4역할 체계: `control-lead`(요청 분류/최종 승인), `doc-maintainer`(문서), `source-implementer`(소스 수정), `source-reviewer`(검수). 소스 변경은 implementer → reviewer 교차 검수 후 control-lead 승인 순서를 따른다.

## 릴리스 프로세스

`DOC/RELEASE_PROCESS.md` 참조. 요약: Lua 구문 검사 → whitespace check → 패키징 → git commit/push → GitHub release.

## 문서 위치

- 사용자 가이드: `README.md`
- 아키텍처: `DOC/ARCHITECTURE.md`
- 현재 상태/인계: `DOC/HANDOFF.md`
- 배포 절차: `DOC/RELEASE_PROCESS.md`
- 보안 검토: `DOC/SECURITY_REVIEW.md`
