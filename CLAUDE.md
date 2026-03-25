# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

`ABProfileManager`는 WoW Retail (Interface 120001 = Patch 12.0.1, Midnight 확장팩) Lua 애드온이다. 액션바 프로필 관리, 전문기술 포인트 추적, 지도/스탯 오버레이, 전투메시지 설정 관리 등을 한 애드온으로 처리한다.

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
├── Data/             # 정적 데이터 (Defaults, ProfessionKnowledge, SilvermoonMapData, StatPriorities)
└── UI/               # 사용자 인터페이스 (16개 모듈)
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

인게임 회귀 체크리스트:
- profession 카드 폭과 체크박스 레이아웃
- profession overlay 상세/요약/최소 모드
- 전투메시지 설정 체크박스와 위로/아래로/부채꼴 버튼 선택 상태
- 지도 오버레이가 외부 월드맵에서만 표시되는지
- 퀘스트 ID 링크 클릭 동작
- 스탯 overlay drag/hitbox

## 주요 서브시스템 작동 방식

### Profession 추적
이벤트: `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED` 후 follow-up refresh 포함. 관련 파일: `Modules/ProfessionKnowledgeTracker.lua`, `Data/ProfessionKnowledge.lua`.

### 전투메시지 관리
`_v2` CVar 우선, 없으면 구형 이름 fallback. 모드 값: `1=위로`, `2=아래로`, `3=부채꼴`. 관련 파일: `Modules/CombatTextManager.lua`, `UI/ConfigPanel.lua`.

### 지도 오버레이
정적 좌표 기반. 패치 후 drift 가능. 보정 시 `Data/SilvermoonMapData.lua`와 `UI/SilvermoonMapOverlay.lua`를 함께 수정.

### TomTom 연동
선택적 연동(`Modules/TomTomBridge.lua`). 하란다르/공허폭풍 일부 1회성 보물은 해당 지역 진입 후 waypoint 생성. TomTom 이슈 제보 시 지역 진입 여부와 map lineage부터 확인.

## 숨겨진 미완성 기능

수정 전 반드시 인지할 것:

- **스탯 오버레이 쐐기(M+) 우선순위 모드**: `UI/ConfigPanel.lua`에서 `mythicPlusCheck:Hide()`로 숨김 처리. 재개 시 `UI/StatsOverlay.lua`의 `BuildSnapshot` `isMplus` 분기, `DB.lua`의 `IsStatsOverlayMythicPlusMode`, `Data/StatPriorities.lua`의 `ns.Data.StatPrioritiesMythicPlus` 함께 확인.
- **경매장 현행 확장팩 필터 자동 선택**: `UI/ConfigPanel.lua`에서 `auctionHouseFilterCheck:Hide()`로 숨김. WoW 보안 시스템에 의해 `GetText()` taint 발생으로 동작 불가. `Events.lua`에 코드 유지.

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
