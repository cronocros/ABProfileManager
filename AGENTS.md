# AGENTS.md

This file provides guidance to Codex and other repository-aware agents when working with code in this repository.

## 프로젝트 개요

`ABProfileManager`는 WoW Retail (Interface 120001 = Patch 12.0.1, Midnight 확장팩) Lua 애드온이다. 액션바 프로필 관리, 전문기술 포인트 추적, 지도/스탯 오버레이, 전투메시지 설정 관리, BIS 추천 장비 카탈로그, 드랍 템렙/시즌 최고기록 오버레이를 한 애드온으로 처리한다.

**현재 기준**: `main (v1.7.0 기반)`

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
4. 지도 오버레이
5. 고스트 드래그 / 전투 중 대기열
6. BlizzardFrameManager (`uiPanel=true` 프레임만 `SetUserPlaced(true)`)
7. `SilvermoonMapOverlay.lua`, `StatsOverlay.lua`의 재사용 버퍼
8. `UI/BISOverlay.lua`
   - `Data/BISCatalog.lua`만 읽는다
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
- BIS 오버레이 드랍 출처 클릭 → 모험 안내서 loot 탭 랜딩
- BIS 필터 / 열 폭 / 마지막 열 가림 여부
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

생성 입력:
- `Data/BISData_Method.lua`
- `Data/BISData.lua`
- `DOC/wow_midnight_s1_mplus_bis_final.md`
- `DOC/wow_midnight_s1_mplus_bis_korean_companion.md`

생성 스크립트:
- `scripts/refresh_wowhead_bis.py`
- `scripts/refresh_wowhead_mplus_fallbacks.py`
- `scripts/build_bis_catalog.py`

중요 규칙:
- 런타임 merge/정규화/웹 조회 금지
- `mythicplus / raid / crafted / tier` 4개 필터 모두 기본 on
- 필터 후 visible list 기준으로 `1순위 / 2순위 / 3순위+`를 재번호화

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

- 스탯 오버레이 쐐기(M+) 우선순위 모드
- 경매장 현행 확장팩 필터 자동 선택
- BIS 던전 direct EJ ID 추가 확인 (`마이사라 동굴`, `윈드러너 첨탑`)

## 릴리스 프로세스

`DOC/RELEASE_PROCESS.md` 참조.

현재 로컬 패키지 정책:
- `dist/` 루트에는 최신 ZIP만 유지
- 이전 로컬 ZIP은 `dist/archive/`로 이동

## 문서 위치

- 사용자 가이드: `README.md`
- 인트로 자산: `ABProfileManager/ADDON_INTRO.txt`
- 아키텍처: `DOC/ARCHITECTURE.md`
- 현재 상태/인계: `DOC/HANDOFF.md`
- 배포 절차: `DOC/RELEASE_PROCESS.md`
- 보안 검토: `DOC/SECURITY_REVIEW.md`
