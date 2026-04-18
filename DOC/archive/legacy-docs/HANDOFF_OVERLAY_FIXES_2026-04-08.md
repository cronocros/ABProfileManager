# BIS/ItemLevel 오버레이 종합 수정 + 스탯 우선순위 업데이트

> **핸드오프 문서** — 이 문서는 Claude Code, ChatGPT, Gemini 등 어떤 AI든 이어서 작업할 수 있도록 작성됨.
> 작업일: 2026-04-08 | 프로젝트: ABProfileManager (WoW Retail Addon) | 기반: v1.5.9

## 프로젝트 기본 정보

- **레포 위치**: `E:\Dev_ai\wowaddon\` (루트), 애드온은 `ABProfileManager/` 하위
- **언어**: Lua (WoW API), 한국어 UI 기본
- **네임스페이스**: 모든 파일이 `local addonName, ns = ...`로 공유 네임스페이스 사용
- **검증 명령**: `python -c "import pathlib, sys; from luaparser import ast; ..."` (CLAUDE.md 참조)
- **TOC 파일**: `ABProfileManager/ABProfileManager.toc` — 파일 로드 순서 정의
- **SavedVariables**: `ABPM_DB` 단일 변수, `DB.lua`에서 관리
- **프로젝트 가이드**: `CLAUDE.md` 파일에 전체 아키텍처, 회귀 민감 영역, 서브시스템 설명 있음

## 현재 코드 상태 (이전 세션 변경 내역)

`BISOverlay.lua`에 다음 변경이 적용된 상태:
1. `extractTooltipItemLevel` 패턴: `(%d%d%d)` → `(%d+)` (유지)
2. `getPreviewMythicPlusLootContext()` / `getPreviewRaidLootContext()`에 itemID-only 캐시 fallback 추가 (**제거 예정**)
3. 프리캐시 엔진 3함수 추가 (`buildPreCacheQueue`, `runPreCacheBatch`, `StartPreCacheSession`) (**제거 예정**)
4. `RebuildContent()` 시작/끝에 프리캐시 연동 코드 (**제거 예정**)
5. `OnHide`에 프리캐시 취소 코드 (**제거 예정**)
6. `showSeasonItemTooltip()` 내 base 툴팁 억제 로직 (**전면 교체 예정**)

## Context

이전 세션에서 EJ preview 프리캐시를 추가했으나, 인게임 테스트 결과:
1. 프리캐시가 EJ 자체를 로드하므로 **여전히 초기 로딩이 무거움**
2. 시즌 1 아이템 레벨(250~289)이 제대로 표시되지 않음
3. 메인UI 탭 이름들이 사라진 회귀 발생
4. 두 오버레이 타이틀바에 잠금/위치초기화 버튼 필요
5. 스크롤 확대/축소 기준점이 두 오버레이 간 불일치

이에 따라 **EJ 기반 툴팁을 완전히 제거**하고 정적 데이터 기반 경량 툴팁으로 전환, UI 개선, 스탯 우선순위 업데이트를 수행한다.

## 수정 대상 파일

- `ABProfileManager/UI/BISOverlay.lua` — 툴팁 전면 교체, 프리캐시 제거, 타이틀바 버튼 추가, 스케일 원점 수정
- `ABProfileManager/UI/ItemLevelOverlay.lua` — 타이틀바 버튼 추가, 스케일 원점 수정
- `ABProfileManager/Locale_Additions.lua` — 새 로케일 키 추가
- `ABProfileManager/Data/StatPriorities.lua` — 전클래스 스탯 우선순위 Wowhead 기준 보정

---

## Phase A: BIS 오버레이 성능 근본 해결

### A-1: 프리캐시 시스템 완전 제거

이전 세션에서 추가한 코드를 전부 롤백/제거한다.

**제거 대상** (`BISOverlay.lua`):
- `buildPreCacheQueue()` 함수 전체
- `runPreCacheBatch()` 함수 전체
- `BISOverlay:StartPreCacheSession()` 함수 전체
- `BISOverlay._preCacheToken`, `BISOverlay._preCacheInProgress` 선언
- `RebuildContent()` 시작의 토큰 취소 코드
- `RebuildContent()` 끝의 `self:StartPreCacheSession(specID)` 호출
- `OnHide` 핸들러의 프리캐시 취소 코드
- `getPreviewMythicPlusLootContext()` 안의 itemID-only fallback 블록
- `getPreviewRaidLootContext()` 안의 itemID-only fallback 블록

**유지 대상**:
- `getPreviewMythicPlusLootContext()` / `getPreviewRaidLootContext()` 함수 자체 (클릭→모험안내서 열기에서 사용)
- `openEncounterJournalForEntry()` (on-demand 클릭 기능)
- `extractTooltipItemLevel` 패턴 수정(`%d+`)은 유지

### A-2: showSeasonItemTooltip 경량화 전면 교체

현재 함수가 EJ preview 로딩 → validation → SetHyperlink 하는 것을 **전부 제거**하고 정적 데이터만 사용.

**새 구현**:
```
1. GetItemInfo(row.itemID) → 아이템명, 품질색상 (이미 캐시된 경우 즉시)
2. 정적 정보만 표시:
   - 아이템명 (품질 색상)
   - 시즌 헤더
   - 부위 / 출처 / 기준 / 순위 (기존 entry 데이터)
   - 아이템 레벨 범위 (ItemLevelTable 기반):
     * M+: getSeasonalMythicPlusSummary("run") + ("vault") 
     * Raid: getSeasonalRaidSummaryLines()
     * Crafted: getSeasonalCraftedSummaryLines()
   - 모험안내서 열기 힌트
3. EJ 프리뷰 관련 코드 일체 없음 (previewContext, validation, SetHyperlink 등)
```

**제거되는 함수** (tooltip에서만 사용):
- `validatePreviewTooltip()`
- `validateRaidPreviewTooltip()`
- `processEncounterJournalTooltip()` (tooltip SetHyperlink용)

---

## Phase B: ABPM 메인창 탭 이름 소실 수정

### B-1: 원인 (확인됨)

**증상**: ABPM 메인창(`/abpm`) 탭 이름이 캐릭터에 따라 보이거나 안 보임 (간헐적).

**근본 원인**: 타이밍 레이스 컨디션
- `MainWindow.lua:166-185`: 탭을 **빈 텍스트 `""`**로 생성
- `MainWindow.lua:70-76`: `RefreshLocale()`에서 나중에 텍스트 설정
- `RefreshLocale()`은 `RefreshStatus()` → `RefreshUI()` 체인으로 호출됨
- 메인창이 `RefreshLocale()` 호출 전에 표시되면 탭 텍스트가 비어있음
- 캐릭터별 로딩 타이밍 차이로 간헐적 발생

**이전 세션 변경과 무관** — BISOverlay.lua만 수정했고 MainWindow.lua는 미수정.

### B-2: 수정

**파일**: `ABProfileManager/UI/MainWindow.lua`

`Initialize()` 함수 끝에서 `self:RefreshLocale()` 호출을 추가하여, 프레임 생성 직후 탭 텍스트가 즉시 설정되도록 보장.

현재 흐름:
```
Initialize() → 탭 생성(빈 텍스트) → ... (나중에 RefreshUI → RefreshLocale)
```
수정 후:
```
Initialize() → 탭 생성(빈 텍스트) → RefreshLocale() 즉시 호출 → 텍스트 설정됨
```

---

## Phase C: 타이틀바 UI 컨트롤 추가

### 대상: BISOverlay + ItemLevelOverlay 양쪽

현재 양쪽 모두 **접기 버튼**만 있음. 추가할 것:

1. **잠금 버튼** (드래그 비활성화 토글)
   - 크기: 18x18, 접기 버튼 왼쪽
   - 텍스트: 잠김="L", 풀림="U" (단순 글자 박스)
   - 클릭: `ns.DB:Set[BIS|ItemLevel]OverlayLocked(toggle)`
   
2. **위치초기화 버튼**
   - 크기: 18x18, 잠금 버튼 왼쪽
   - 텍스트: "R" (단순 글자 박스)
   - 클릭: `ns.Data.Defaults.ui.[bis|itemLevel]Overlay` 기본값으로 복원

### BISOverlay 구현 위치
- `EnsureFrame()` 내 collapseBtn 생성 직후 (~line 2041)
- `avgLabel` 오른쪽 여백 조정: `-(PADDING + 16)` → `-(PADDING + 60)`

### ItemLevelOverlay 구현 위치
- `EnsureFrame()` 내 toggleBtn 생성 직후 (~line 635)
- `avgLabel` 오른쪽 여백 조정: `-24` → `-66`

### 기본 위치값 (Defaults.lua에서 확인)
- BIS: `{ point="CENTER", relativePoint="CENTER", x=806, y=-100, anchorMode="itemlevel" }`
- ItemLevel: `{ point="CENTER", relativePoint="CENTER", x=350, y=-100, anchorMode="mythicplus" }`

---

## Phase D: 스크롤 확대/축소 기준점 통일

### 문제
`SetScale()` 호출 시 WoW는 프레임의 앵커 포인트 기준으로 확대. 드래그 후 저장된 앵커가 TOPLEFT이면 좌상단 기준, CENTER이면 중앙 기준. 두 오버레이의 앵커 상태가 다르면 확대 기준점이 달라짐.

### 해결: 시각적 중심 보정 (center-pivot scaling)
`setOverlayScale()` / `setScale()` 에서 스케일 변경 전후 프레임 중심 좌표를 계산하여 위치를 보정.

```lua
-- 공통 패턴:
local oldScale = currentScale
-- 새 스케일 적용
local cx = frame:GetLeft() + (frame:GetWidth() * oldScale) / 2
local cy = frame:GetTop()  - (frame:GetHeight() * oldScale) / 2
frame:SetScale(newScale)
frame:ClearAllPoints()
frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
    cx / newScale - frame:GetWidth() / 2,
    cy / newScale + frame:GetHeight() / 2)
-- 위치 저장
```

**수정 파일**:
- `BISOverlay.lua` `setOverlayScale()` (~line 1023)
- `ItemLevelOverlay.lua` `setScale()` (~line 148)

---

## Phase E: 커밋 및 배포

1. Lua 구문 전체 검사
2. 공백 검사 (`git diff --check`)
3. git commit
4. 릴리스 패키징

---

## Phase F: 스탯 우선순위 보정 (커밋 후)

### F-1: Wowhead에서 풍운 수도사부터 시작

URL: `https://www.wowhead.com/ko/guide/classes/monk/windwalker/stat-priority-pve-dps`
현재 데이터 (`StatPriorities.lua` line 53):
```lua
MONK = {
    [3] = { { "versatility" }, { "crit" }, { "haste" }, { "mastery" } }  -- 풍운
}
```
→ Wowhead 최신 기준으로 업데이트

### F-2: 전클래스 전특성 보정

13개 클래스 × 3~4특성 = 37개 스펙 전부 Wowhead에서 최신 데이터 수집 후 업데이트.

**데이터 형식**: `{ { "stat1" }, { "stat2" }, { "stat3" }, { "stat4" } }`
**동등 우선순위**: `{ "crit", "haste" }` 같은 서브테이블로 표현

**파일**: `ABProfileManager/Data/StatPriorities.lua`

---

## 검증 방법

### Phase A-B 검증
1. PVEFrame 열기 → BIS 오버레이 즉시 표시 (초기 로딩 없음)
2. 아이템 hover → 즉시 경량 툴팁 (아이템명 + 시즌 범위 + 출처 정보)
3. 아이템 클릭 → 모험 안내서 정상 열림 (on-demand EJ 로딩)
4. 탭 이름 정상 표시 확인

### Phase C 검증
5. 잠금 버튼 클릭 → 드래그 불가 확인, 다시 클릭 → 드래그 가능
6. 위치초기화 버튼 → 기본 위치로 즉시 복원

### Phase D 검증
7. 양쪽 오버레이에서 스크롤 확대/축소 → 프레임 중심 기준으로 확대 (동일 동작)

### Phase F 검증
8. 스탯 오버레이에서 전클래스/전특성 우선순위가 Wowhead 최신 기준과 일치

---

## 핵심 파일별 함수/라인 맵 (이어서 작업할 AI를 위한 참조)

### `ABProfileManager/UI/BISOverlay.lua` (~3000줄)
| 라인 범위 | 함수/섹션 | 설명 |
|-----------|----------|------|
| 1-67 | 상수, 캐시 선언 | `SCALE_STEP`, `BIS_SOURCE_LABEL_KEYS`, `EJ_PREVIEW_CONTEXT_CACHE` 등 |
| 162-167 | 캐시 테이블들 | `EJ_INSTANCE_CACHE`, `EJ_PREVIEW_LINK_CACHE`, `EJ_PREVIEW_CONTEXT_CACHE` |
| 190-200 | `ensureEncounterJournalLoaded()` | EJ UI 로딩 (무거운 작업) |
| 218-232 | `getSeasonPreviewKeyLevel()` | 시즌 프리뷰 키 레벨 결정 |
| 374-492 | `getPreviewMythicPlusLootContext()` | M+ EJ 프리뷰 (유지 — 클릭 기능용) |
| 491-586 | `getPreviewRaidLootContext()` | 레이드 EJ 프리뷰 (유지 — 클릭 기능용) |
| ~620 | `processEncounterJournalTooltip()` | **제거 대상** — 툴팁 SetHyperlink용 |
| 1023-1035 | `setOverlayScale()` | 마우스 휠 스케일 (Phase D 수정 대상) |
| 1325-1349 | `extractTooltipItemLevel()` | ilvl 추출 (`%d+` 수정 완료) |
| 1351-1397 | `validatePreviewTooltip()` / `validateRaidPreviewTooltip()` | **제거 대상** |
| 1508-1522 | `getSeasonalMythicPlusRange()` / `getSeasonalRaidRange()` | 시즌 ilvl 범위 (유지) |
| 1524-1560 | `getSeasonalRaidSummaryLines()` / `getSeasonalCraftedSummaryLines()` | 시즌 요약 (유지) |
| ~1700-1820 | 프리캐시 엔진 | **전체 제거 대상** |
| 1876-1925 | `UpdateSourceFilterButtons()` | 소스 필터 버튼 텍스트 갱신 |
| 1963-1990 | 프레임 드래그/스케일 설정 | OnDragStart, OnDragStop, OnMouseWheel |
| 1992-2060 | 타이틀바 생성 | titleBar, titleText, collapseBtn (Phase C 추가 위치) |
| ~2425-2560 | `showSeasonItemTooltip()` | **전면 교체 대상** |
| ~2650-2660 | tooltipRegion OnEnter | `showSeasonItemTooltip` 호출 지점 |
| ~2830 | `RebuildContent()` | 콘텐츠 빌드 (프리캐시 호출 제거) |
| ~3010 | `Refresh()` | 오버레이 갱신 |
| ~3100 | `Initialize()` | PVEFrame 훅 설정 |

### `ABProfileManager/UI/ItemLevelOverlay.lua` (~1050줄)
| 라인 범위 | 함수/섹션 | 설명 |
|-----------|----------|------|
| 148-156 | `setScale()` | 마우스 휠 스케일 (Phase D 수정 대상) |
| 585-604 | 드래그/스케일 설정 | OnDragStart, OnDragStop, OnMouseWheel |
| 606-635 | 타이틀바 생성 | titleBar, titleText, toggleBtn (Phase C 추가 위치) |
| 625-627 | avgLabel 위치 | `RIGHT, titleBar, RIGHT, -24, 0` (여백 조정 필요) |
| 648-664 | 탭 버튼 생성 | `TAB_KEYS` 배열 기반 |
| 825-849 | `RefreshHeader()` | 탭 텍스트 갱신 |
| 906-911 | `ToggleCollapsed()` | 접기/펼치기 |

### `ABProfileManager/UI/MainWindow.lua` (~290줄)
| 라인 범위 | 함수/섹션 | 설명 |
|-----------|----------|------|
| 62-77 | `RefreshLocale()` | 탭 텍스트 설정 (Phase B 수정점) |
| 79-260 | `Initialize()` | 프레임 생성, 탭 생성(빈 텍스트) |
| 166-185 | 탭 버튼 생성 | 빈 텍스트 `""` — RefreshLocale 호출 필요 |

### `ABProfileManager/Data/Defaults.lua`
| 라인 | 키 | 기본값 |
|------|-----|--------|
| 109-118 | `ui.itemLevelOverlay` | `point="CENTER", x=350, y=-100, anchorMode="mythicplus"` |
| 119-127 | `ui.bisOverlay` | `point="CENTER", x=806, y=-100, anchorMode="itemlevel"` |

### `ABProfileManager/DB.lua`
| 함수 | 설명 |
|------|------|
| `IsBISOverlayLocked()` / `SetBISOverlayLocked()` | BIS 드래그 잠금 |
| `IsItemLevelOverlayLocked()` / `SetItemLevelOverlayLocked()` | ItemLevel 드래그 잠금 |
| `SaveBISOverlayPosition(frame)` | BIS 위치 저장 |
| `SaveItemLevelOverlayPosition(frame)` | ItemLevel 위치 저장 |
| `GetBISOverlayConfig()` | BIS 설정 (scale, point, collapsed 등) |
| `GetItemLevelOverlayConfig()` | ItemLevel 설정 |
| `SetBISOverlayScale(value)` | 스케일 저장 (0.75~1.35 clamp) |

### `ABProfileManager/Data/StatPriorities.lua` (98줄)
| 라인 범위 | 테이블 | 설명 |
|-----------|--------|------|
| 7-74 | `ns.Data.StatPriorities` | PvE 스탯 우선순위 (13 클래스 37 스펙) |
| 78-97 | `ns.Data.StatPrioritiesMythicPlus` | M+ 탱커 스펙 오버라이드 |

**데이터 형식**: `CLASS = { [specIndex] = { { "stat1" }, { "stat2", "stat3" }, { "stat4" } } }`
**스탯 키**: `"crit"`, `"haste"`, `"mastery"`, `"versatility"`
**클래스 키**: `WARRIOR`, `PALADIN`, `HUNTER`, `ROGUE`, `PRIEST`, `DEATHKNIGHT`, `SHAMAN`, `MAGE`, `WARLOCK`, `MONK`, `DRUID`, `DEMONHUNTER`, `EVOKER`

### 기존 재사용 함수 (BISOverlay.lua 내)
- `getSeasonalMythicPlusSummary(mode)` — "run" 또는 "vault" 모드로 M+ 시즌 요약 문자열
- `getSeasonalRaidSummaryLines()` — 레이드 난이도별 ilvl 요약 배열
- `getSeasonalCraftedSummaryLines()` — 제작 ilvl 요약 배열
- `getQualityColor(quality)` — 품질 색상 {r, g, b}
- `canonicalNote(note)` — BIS 등급 정규화
- `notePlain(noteKind, noteIndex)` — 등급 표시 텍스트
- `localizeSlot(slotName)` — 부위 한국어 변환
- `getSourceBasisLabel(sourceType)` — 출처 기준 라벨
- `getDisplaySourceLabel(entry)` — 출처 표시 라벨
- `getEntrySourceType(entry)` — 출처 타입 ("mythicplus"/"raid"/"crafted")

---

## Wowhead 스탯 우선순위 URL 패턴

```
https://www.wowhead.com/ko/guide/classes/{class}/{spec}/stat-priority-pve-dps
https://www.wowhead.com/ko/guide/classes/{class}/{spec}/stat-priority-pve-healer
https://www.wowhead.com/ko/guide/classes/{class}/{spec}/stat-priority-pve-tank
```

예시:
- 풍운 수도사: `/monk/windwalker/stat-priority-pve-dps`
- 신성 성기사: `/paladin/holy/stat-priority-pve-healer`
- 수호 전사: `/warrior/protection/stat-priority-pve-tank`
