# ABProfileManager Architecture

기준: `v1.13.0` / TOC `## Interface: 120100` / WoW `12.1.0` 빌드 `69465` (2026-08-21)
시즌: Midnight 시즌 2 (`Curse of Ula'tek`, 2026-08-18 시작)

## 목적

`ABProfileManager`는 WoW Retail에서 다음을 한 애드온에서 처리합니다.

- 액션바 템플릿 저장, 비교, 부분 적용, 동기화, 최근 1회 되돌리기
- 퀘스트 정리
- 전문기술 지식 포인트 추적
- 전투메시지 표출 방식 관리
- 캐릭터 스탯 오버레이
- 한밤(Midnight) 지도 오버레이
- 도메인별 typography 슬라이더
- 드랍 아이템 레벨 참조 오버레이
- BIS 추천 장비 카탈로그 오버레이
- 파티찾기 시즌 최고기록 아이콘 오버레이
- 전문화별 대표 스탯 우선순위 표 팝업

핵심 원칙:

- 메인 UI 레이아웃은 쉽게 흔들지 않는다.
- 액션바와 profession 로직은 데이터 중심으로 유지한다.
- 지도 오버레이는 보수적인 맵 판정과 정적 좌표를 사용한다.
- 파괴적 작업은 확인창과 입력 검증을 우선한다.
- BIS 정적 후보는 생성된 카탈로그만 읽고, 열기 시점의 병합/웹 조회를 금지한다.
- 확인되지 않은 ID·좌표·아이템 레벨은 하드코딩하지 않는다.
- 애드온 hover 설명은 전용 tooltip frame을 사용한다. BIS 아이템 hover는 addon-owned Blizzard item tooltip에 `SetHyperlink()`로 전달하고, shopping tooltip 경로로 sell price `MoneyFrame` 렌더링을 차단한다.
- 소스 Lua에는 주석을 두지 않는다. `scripts/strip_lua_comments.py`가 제거를 담당한다.
- 로컬 배포는 `dist/` ZIP 생성까지만 하고 WoW 설치 폴더로 복사하지 않는다.

## 파일 구성과 로드 순서

TOC 순서가 곧 의존 순서입니다. 아래 그룹은 TOC에 적힌 순서 그대로입니다.

1. 코어: `Core.lua` → `Constants.lua` → `Locale.lua` → `Locale_Additions.lua` → `Utils.lua`
2. 데이터: `Data\Defaults` → `StatPriorities` → `StatPriorityTable` → `ProfessionKnowledge` → `ProfessionKnowledgeWaypoints` → `SilvermoonMapData` → `ItemLevelTable` → `BISCatalog` → `BISMythicVaultLinks` → `BISSeasonPreviewLinks` → `BISEncounterJournal` → `MidnightS1MPlusDB` → `BISRuntimeScoring`
3. 저장소: `DB.lua`
4. 모듈: `SlotMapper` → `ActionBarScanner` → `UndoManager` → `RangeCopyManager` → `ActionBarApplier` → `TemplateSyncManager` → `TemplateTransfer` → `GhostManager` → `ProfileManager` → `QuestManager` → `ProfessionKnowledgeTracker` → `TomTomBridge` → `CombatTextManager` → `BlizzardFrameManager` → `PrivateAurasGuard`
5. UI: `Typography` → `Widgets` → `ConfirmDialogs` → `MinimapButton` → `StatsOverlay` → `ProfessionKnowledgeOverlay` → `ItemLevelOverlay` → `BISOverlay` → `MythicPlusRecordOverlay` → `TransferDialog` → `ProfilePanel` → `ActionBarPanel` → `ProfessionPanel` → `MapPanel` → `QuestPanel` → `AddonSettingsPages` → `ConfigPanel`
6. 러시아어 확장: `ABPM_ruRU_Final_v3.lua` — `ConfigPanel` 뒤에서 `Locale.strings.ruRU`에 주입한다. `Locale.lua`보다 먼저 로드하면 안 된다.
7. 나머지 UI: `UtilityPanel` → `SilvermoonMapOverlay` → `StatPriorityDialog` → `MainWindow`
8. 진입점: `Commands.lua` → `Events.lua`

repo에는 있으나 TOC에서 제외된 비활성 파일: `Modules\MerchantHelper.lua`, `Modules\MailHistory.lua`, `UI\WorldEventOverlay.lua`, `Data\WorldEventSchedule.lua`.

## 부트스트랩

- `Core.lua` — 네임스페이스 초기화, 시작 시 모듈 초기화
- `DB.lua` — SavedVariables 초기화, 공통 설정 / UI 위치 / character 데이터, 스키마 마이그레이션
- `Events.lua` — `ADDON_LOADED`, `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, profession / quest / stats 갱신 이벤트 연결
- `Commands.lua` — `/abpm` 슬래시 명령

## 주요 모듈

### 액션바

- `Modules/ActionBarScanner.lua` — 현재 액션바 상태 스캔
- `Modules/ActionBarApplier.lua` — 적용, 비우기, 전투 중 대기열, 고스트 재시도
- `Modules/ProfileManager.lua` — 템플릿 저장/삭제/적용
- `Modules/TemplateSyncManager.lua` — 비교와 동기화
- `Modules/TemplateTransfer.lua` — 문자열 내보내기/가져오기
- `Modules/RangeCopyManager.lua` — 전체 / 바 / 선택 바 / 슬롯 범위 해석
- `Modules/SlotMapper.lua` — 실제 수정 가능한 슬롯 매핑
- `Modules/UndoManager.lua` — 최근 1회 작업 복구
- `Modules/GhostManager.lua` — 누락 액션 고스트 표시

### profession / 지도 / 설정

- `Modules/ProfessionKnowledgeTracker.lua` — profession별 획득원 집계, 완료/숨은 퀘스트 기반 추적, 카드·오버레이·tooltip 데이터 제공
- `Modules/CombatTextManager.lua` — 전투메시지 `_v2` CVar와 구형 이름 fallback을 함께 관리
- `Modules/BlizzardFrameManager.lua` — 선택한 Blizzard 기본 창을 드래그 가능하게 만든다. 저장 좌표가 있는 UIPanel 창만 `SetUserPlaced(true)`로 복원하고, `global.settings.blizzardFrames.layoutVersion=2` 이전 좌표는 1회 초기화
- `Modules/PrivateAurasGuard.lua` — Blizzard PrivateAuras의 auraInstanceID 충돌 assertion만 좁게 완화. `PrivateAuraAnchorContainerMixin`이 없으면 조용히 넘어간다
- `Modules/TomTomBridge.lua` — TomTom 선택적 연동. 일부 1회성 보물은 해당 지역 진입 후 waypoint 생성

### 오버레이

- `UI/StatsOverlay.lua` — 캐릭터 스탯 오버레이. 특화 tooltip은 현재 전문화의 Mastery spell tooltip data를 ABPM 전용 tooltip에 렌더링한다. 미사용 `PaperDollFrame_Set*` setter 호출은 제거해 Blizzard tooltip taint 접점을 줄였다
- `UI/ItemLevelOverlay.lua` — 파티찾기(PVEFrame) 옆에 표시. 탭 `overview / mythicplus / delves / raid / other`. 각 행은 `단·난이도 | 클리어보상 | 드랍문장 | 위대한 금고`. 우측 고정 패널에 문장 보유량과 `오늘의 풍요 4개 / 열쇠 파편 / 복원된 열쇠` 표시. 위치·스케일·탭·접힘 상태를 저장하고 복원한다
  - `CREST_ID_BY_GRADE = { adv=3442, vet=3443, chmp=3444, hero=3445, myth=3446 }` (안개문장 / Mistcrest)
  - `DELVE_RESTORED_KEY_CURRENCY_ID = 3028`
  - `CREST_PANEL_GRADES = { adv, vet, chmp, hero, myth }`
- `UI/BISOverlay.lua` — BIS 추천 장비 카탈로그. 아래 별도 절 참조
- `UI/MythicPlusRecordOverlay.lua` — `ChallengesFrame.DungeonIcons` 위에 `평점 + 던전명` 표시. 시간 라인은 쓰지 않는다. Utility 탭 체크박스로 on/off
  - 훅 설치는 `setupHooks()` 한 곳에 모으고 `_hooksReady`로 중복을 막는다. `ChallengesDungeonIconMixin.SetUp`, `ChallengesFrame` `OnShow`/`OnHide`, `ChallengesFrame.Update`를 후킹한다
  - `ChallengesFrame`이 아직 없으면 `ADDON_LOADED` / `PLAYER_ENTERING_WORLD` watcher로 재시도하고, 성공하면 watcher를 해제한다. Blizzard 지연 로드 대응이다
  - `DUNGEON_NAME_OVERRIDES`는 긴 한글 던전명 줄바꿈 표다. 현재 항목은 시즌 1 던전명 기준이며 시즌 2 던전명은 미반영 상태다

### 패널

- `UI/MainWindow.lua` — 메인 프레임과 탭 전환
- `UI/Widgets.lua` — 공통 위젯 헬퍼, 애드온 전용 tooltip frame(`Widgets.GetTooltip`, `Widgets.HideTooltip`)
- `UI/ProfilePanel.lua` / `ActionBarPanel.lua` / `ProfessionPanel.lua` / `QuestPanel.lua` / `UtilityPanel.lua`
- `UI/MapPanel.lua` — 지도 탭, 포탈·평판상인 필터, 지도 글자 크기
- `UI/ConfigPanel.lua` — 일반 설정, typography 슬라이더, 개요, 전투메시지 표출 방식
- `UI/AddonSettingsPages.lua` — 와우 `설정 > 애드온` 하위 카테고리
- `UI/Typography.lua` — 도메인별 글자 크기 보정과 tooltip 폰트 재적용
- `UI/StatPriorityDialog.lua` — 40개 전문화 단일 대표 스탯 우선순위 표 팝업
- `UI/ProfessionKnowledgeOverlay.lua` — profession 포인트 오버레이. 상단은 문장형 안내와 주간 리셋 잔여 시간, tooltip은 범례·색상·source별 요약·TomTom 안내
- `UI/SilvermoonMapOverlay.lua` — 한밤 지도 텍스트 오버레이

## 시즌 2 신규 구조

### SeasonGuard (`UI/BISOverlay.lua`)

BIS 데이터와 `SeasonGuard.dataSeason`이 모두 시즌 2라 현재 차단은 꺼져 있습니다. 다음 시즌 전환 때 데이터가 뒤처지면 다시 켜져 조용한 오작동을 드러냅니다.

- 기준값은 `SeasonGuard.dataSeason = "Midnight Season 2"`. 현재 시즌은 `ns.Data.ItemLevelTable.season`에서 읽는다. 새 API를 쓰지 않는다
- `SeasonGuard.IsMismatched()`는 판정 결과를 `cachedMismatch`에 캐시한다. `ItemLevelTable`이 없으면 `false`로 본다
- 불일치일 때 다음 자동 동작을 끈다
  - Encounter Journal 자동 랜딩 (안내 메시지 출력 후 반환)
  - `scheduleAutomaticRuntimeScores()` M+ 자동 점수화 큐
  - `resolveMythPreviewSnapshot()` preview snapshot 스캔
  - `getPreviewRankingScore()` preview 기반 순위 점수
- 시즌이 어긋날 때만 `SeasonGuard.ApplyNotice()`가 상단 안내에 데이터 시즌에서 유도한 `[S2]` 형태의 짧은 접두를 붙이고 경고색으로 칠한다. 상단 안내는 한 줄 고정이라 시즌 이름 전체를 붙이면 스탯 정책 요약이 잘린다
- 후보 목록, 정적 순위, 카탈로그 데이터는 그대로 둔다

### aura backoff (`UI/StatsOverlay.lua`)

12.1부터 전투 / 레이드 조우 / 쐐기 / PvP 중에는 aura가 보호 상태가 되고, `C_UnitAuras`의 index·slot·instanceID 기반 조회가 Lua 오류를 냅니다. spellID 기반 조회는 정상입니다.

- 버프 hash 수집 `getPlayerBuffHash()`가 유일한 영향 지점이다
- `C_UnitAuras.GetAuraDataByIndex` 호출을 `pcall`로 감싼다
- 실패하면 `_auraScanBlockedUntil = now + AURA_SCAN_BACKOFF_SECONDS`(2.0초)로 잠그고 빈 hash를 돌려준다. 잠금 중에는 스캔 자체를 건너뛴다
- `GetTime`이 없으면 잠금 없이 빈 hash만 돌려준다

### mythPreviewCache 시즌 무효화 (`DB.lua`)

`DB:GetBISOverlayMythPreviewCache()`는 계정 SavedVariables의 preview snapshot 캐시를 반환하며, 아래 중 하나라도 어긋나면 캐시를 통째로 새로 만듭니다.

- `schemaVersion` (기본 3)
- `baselineItemLevel` (기본 318)
- `generatedPreviewBonusListID`
- `generatedPreviewItemStringTemplate`
- `season` — `ns.Data.ItemLevelTable.season` 값. 시즌 2 신설 조건이다

시즌이 바뀌면 시즌 1 기준으로 검증된 snapshot이 자동으로 버려집니다.

## 데이터 계층

### `Data/ItemLevelTable.lua`

시즌 2 스키마입니다. 상단 `ns.Data.ItemLevelTable`과 하단 `ns.Data.BISRewardProfiles`는 성격이 다릅니다.

- `season = "Midnight Season 2"` — SeasonGuard와 preview 캐시 무효화의 판정 근거
- `sources` — 섹션별 근거 표기. 값은 `dump` / `tooltip` / `guide`
  - 현재: `raid`는 `dump`, `worldBoss` / `crafted` / `pvp`는 `tooltip`. `delves`, `mythicPlus`만 `guide`
  - `guide`가 남아 있으면 `-Strict` 검증이 실패한다. 릴리스 전에 실측으로 승급해야 한다
- `gradeMax` — 5등급 `adv 282 / vet 295 / chmp 308 / hero 321 / myth 334`. 시즌 2에 대응 문장이 없는 탐험가(`expl`) 트랙은 제거했다
- `delves` — 1~11단계. 단계별 `ilvl / grade / maxilvl / vault / vaultGrade / vaultMax / crestDrop`
- `mythicPlus` — `heroic`, `mythic0`, `endOfDungeon` 배열(+2~+12). 랭크 표기 `rank / rankMax`
- `raid` — `normal / heroic / mythic`. 난이도별 `min~max`와 금고
- `worldBoss` — 4난이도로 확장. `world 279 / normal 292 / heroic 305 / mythic 318`
- `crafted` — `base 318`, `r5 331`
- `pvp` — `honor 263~295`, `conquest 292~308`. 2026-08-28 상인 툴팁 실측(`sources.pvp = "tooltip"`)
- 하단 `ns.Data.BISRewardProfiles` — BIS row가 참조하는 대표 보상 트랙. 시즌 2 값(`311` / `318`)이며 sha256으로 고정된다. 주석 제거 대상에서도 제외된다

랭크 사다리는 기준값 `+0, +3, +6, +10, +13, +16`의 6단계, 제작 품질 사다리는 `+0, +3, +6, +9, +13`의 5단계입니다.

### 그 외 데이터

- `Data/Defaults.lua` — SavedVariables 기본값. BIS source filter는 `mythicplus/raid/crafted/tier` 전부 on, BIS item tooltip 토글은 on
- `Data/ProfessionKnowledge.lua`, `Data/ProfessionKnowledgeWaypoints.lua` — profession 획득원 정의와 1회성 보물 좌표
- `Data/SilvermoonMapData.lua` — 한밤 지도 라벨 정의
- `Data/StatPriorities.lua` — 스탯 오버레이 한 줄 표시용 단일 대표 우선순위 (와우헤드 시즌 2 값, 해시 동결)
- `Data/StatPriorityTable.lua` — 스탯 우선순위 표 팝업용 40개 전문화 표와 specID map (와우헤드 시즌 2 값, 해시 동결)

### BIS 데이터 (시즌 2 기준, 해시 동결)

- `Data/BISCatalog.lua` — 런타임이 직접 읽는 단일 정적 후보 카탈로그. 총 `657`행 (`raid 393`, `mythicplus 107`, `tier 79`, `crafted 78`). 시즌 1 v1.11 계열은 `3330`행이었다. row별 `specID, slot, itemID, nameKoKR, nameEnUS, sourceGroup, sourceLabel, overallRank, sourceRank`와 source detail, 검증 메타를 함께 보관
- `Data/MidnightS1MPlusDB.lua` — 실제 `itemLink`에서 아이템 레벨과 스탯을 읽어 전문화별 점수를 계산하는 런타임 점수 코어
- `Data/BISRuntimeScoring.lua` — ABPM specID / slot / sourceGroup을 점수 코어 키로 변환하는 어댑터
- `Data/BISMythicVaultLinks.lua` — M+ 금고 Myth 1/6 `baselineItemLevel = 318`, snapshot schema v3. 시즌 2 selector(`generatedPreviewBonusListID`)는 인게임 미확인이라 `nil`이고 자동 preview가 꺼져 있다. 후보 `12849`는 `DOC/TODO.md` 5장에 있다
- `Data/BISSeasonPreviewLinks.lua` — raid Myth `318~334`, tier Myth `318~334`, crafted r5 `331` 검증 범위. `linksBySourceAndItemID`는 세 출처 모두 비어 있다
- `Data/BISEncounterJournal.lua` — M+ 도감 랜딩용 UI tier index, `JournalTierID`, 검증된 `JournalInstanceID`. `MapID`는 `EJ_SelectInstance()` 입력으로 쓰지 않는다
- `Data/BISData_Method.lua` — 와우헤드 전문화별 overall BiS. 카탈로그의 유일한 후보 원천이며 런타임에 로드되지 않는다

카탈로그와 도감 랜딩 데이터는 v1.13.0에서 시즌 2로 재생성했습니다. preview selector 두 종만 인게임 미확인이라 비활성이며, 그 결과 M+ 자동 점수화와 시즌 preview 툴팁이 동작하지 않습니다.

## BIS 오버레이 런타임

`UI/BISOverlay.lua`는 정적 카탈로그를 렌더링하고, 시즌이 일치할 때만 실제 `itemLink` 기반 점수화를 덧붙입니다.

표시:

- 현재 캐릭터 클래스의 전 특성 탭과 부위별 후보를 slot으로 묶어 렌더
- 필터 `mythicplus / raid / crafted / tier` 4개 기본 on. 필터 적용 후 남은 후보로 visible rank를 재계산하고 첫 2개는 `1순위 / 2순위`, 이후는 `3순위+`
- 즐겨찾기/보유 체크박스는 캐릭터별·전문화별 저장. 즐겨찾기는 최상단 섹션, 보유 아이템명은 취소선
- 열 구성은 `아이템명 / 드랍 출처 / 트랙·검증 상태 / 우선순위`
- 헤더에 현재 전문화 스탯 정책과 정적 최종 BiS 미확정 상태 표시. 시즌이 어긋날 때만 짧은 시즌 접두와 경고색이 붙는다
- 헤더 마우스 휠로 0.5~2.0배 스케일. 위치 / 스케일 / 접힘 상태를 저장하고 복원

tooltip:

- M+ hover는 검증된 Myth 1/6 snapshot의 full item link를 addon-owned Blizzard item tooltip에 `SetHyperlink()`로 전달한다. 없으면 미검증 안내만 표시
- raid / tier / crafted hover는 검증된 시즌 preview를 먼저 시도하고, 실패하면 기본 `itemLink` 또는 `item:<itemID>`를 세션 캐시에 넣어 같은 경로로 fallback
- 시즌 preview helper는 `SourcePreview` 테이블 필드로 묶어 WoW Lua chunk의 top-level local 200개 제한을 넘지 않게 유지한다
- BIS 전용 tooltip은 shopping tooltip 경로로 sell price `MoneyFrame` 렌더링을 차단한다

성능·안전:

- open / spec / filter 전환은 단일 rebuild 경로를 사용한다
- `GET_ITEM_INFO_RECEIVED`는 전체 rebuild 대신 visible row patch만 수행한다
- 스크롤 중 hover tooltip 생성을 억제하고, 점수 캐시 / 아이템 요청 dedupe / 분산 큐로 rebuild 부담을 낮춘다
- 장비·가방 링크는 정렬이나 hover에서 스캔하지 않고, 보유 체크 on 시 저장용으로 한 번만 찾는다
- hover / 자동 큐에서 Encounter Journal UI 상태를 바꾸거나 숨은 loot scan을 하지 않는다
- Encounter Journal 랜딩은 비전투 중에만, 현재 시즌 tier 선택과 availability guard를 통과한 경우에만 수행한다. 보호된 `C_EncounterJournal.SetTab`은 직접 호출하지 않는다
- 임의 bonusID를 조립하지 않는다. selector는 데이터 파일에서만 관리한다
- 다른 템렙으로 해석된 preview는 세션 음성 캐시에 넣어 반복 큐잉을 막고, 링크별 재시도는 세션 최대 2회다
- `Utils.SafeNumber()`는 secret 값을 정규화하지 못하면 원본을 전파하지 않고 `0`으로 fallback한다

## 저장 구조

계정 공통 `global.settings`:

- 언어, 확인창, 디버그, 오버레이 표시 여부
- BIS source filter / 잠금 / item tooltip 토글과 사용자 설정 플래그
- BIS preview snapshot 캐시 `mythPreviewCache` (schemaVersion / baselineItemLevel / selector / template / season / itemsByID)
- typography 도메인별 오프셋
- 지도 라벨 카테고리 필터
- 마우스 이동 자동 복구
- Blizzard 기본 창 이동 설정과 저장 좌표 layout version

`ui`:

- 메인 창 위치
- profession 오버레이 위치 / 모드 / scale
- stats 오버레이 위치 / scale
- itemLevelOverlay 위치 / scale / currentTab / collapsed / anchorMode
- bisOverlay 위치 / scale / collapsed / anchorMode

캐릭터별:

- profession 진행 상태, 캐릭터 기본 정보
- 템플릿 작성 시 원본 캐릭터 메타데이터
- 사용자가 켠 전투메시지 표출 방식 상태
- 전문화별 BIS 즐겨찾기 / 보유 아이템 상태

## BIS 카탈로그 재생성 흐름

시즌 2에서는 동결 상태이므로 실행하지 않습니다. 구조만 남깁니다.

1. `scripts/refresh_wowhead_bis.py`로 `Data/BISData_Method.lua`를 갱신
2. `scripts/rebuild_bis_database.ps1` 실행
3. 내부 순서: `build_bis_catalog.py --addon-db` → `build_bis_runtime_scoring.py` → `validate_bis_mythic_vault_links.py` → `validate_bis_season_preview_links.py` → `validate_bis_tooltip_contract.py` → `validate_bis_encounter_journal.py` → `validate_bis_catalog.py` → `audit_bis_data.py`
4. 결과 `Data/BISCatalog.lua`, `Data/MidnightS1MPlusDB.lua`, `Data/BISRuntimeScoring.lua`를 패키지에 포함

seed 경계:

- 후보는 와우헤드 overall 데이터에서만 온다. 점수 정책은 `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`에서 관리한다. 코어 구조는 `12.0.5` 시점 그대로이고 스탯 우선순위 값은 시즌 2 기준이다
- M+ selector 교체와 Myth full link override는 `Data/BISMythicVaultLinks.lua`만 갱신한다
- raid / tier / crafted preview selector와 override는 `Data/BISSeasonPreviewLinks.lua`만 갱신한다
- raid / crafted는 아직 기존 `BISCatalog.lua` 보존 seed다. 완전 단일 seed 재생성은 후속 범위다

## 검증 하네스

진입점은 `scripts/run_season2_validation.ps1`입니다. `-Strict`를 주면 아이템 레벨표에서 `guide`만 근거인 값을 실패로 처리합니다. 릴리스 패키징 직전에는 반드시 `-Strict`로 돌립니다.

실행 순서:

| 단계 | 대상 | 확인 내용 |
| --- | --- | --- |
| Lua 전체 파싱 | `ABProfileManager/**/*.lua` | `luaparser`로 전 파일 파싱 |
| 공백 오류 검사 | 작업 트리 | `git diff --check` |
| `validate_season2_scope.py` | 동결 파일 8종 + 생성 입력 1종 + `BISRewardProfiles` | `git hash-object` 블롭 해시와 블록 sha256 대조 |
| `validate_season2_itemlevel.py` | `ns.Data.ItemLevelTable` | 등급 상한 오름차순, 구렁 단계 연속, 행별 ilvl이 등급 상한 이하, `sources` 표기. `--strict`에서 `guide`는 실패 |
| `validate_locale_contract.py` | `Locale` + `Locale_Additions` + ruRU 확장 | `koKR`/`enUS` 키 집합 동일, `ruRU` 누락·잉여가 기준선(`143` / `11`)을 넘지 않는지 |
| `validate_bis_mythic_vault_links.py` | `BISMythicVaultLinks` | baseline, selector, override itemID, item string 형식 |
| `validate_bis_season_preview_links.py` | `BISSeasonPreviewLinks` | raid/tier/crafted profile, TOC 로드, selector 템플릿, override itemID |
| `validate_bis_tooltip_contract.py` | `BISOverlay`, `StatsOverlay` | addon-owned tooltip, shopping sell-price 차단, snapshot schema v3, setter 제거, `SafeNumber()` fallback, top-level local 예산(현재 `195`, 검증기 상한 `198`, Lua 상한 `200`) |
| `validate_bis_encounter_journal.py` | `BISEncounterJournal` | 시즌 tier와 `JournalInstanceID` 매핑, TOC 로드 |
| `validate_bis_catalog.py` | `BISCatalog` | 40개 전문화, raid/crafted row 보존, reward profile, 정적 itemLink/bonusID 미생성 |
| `audit_bis_data.py` | BIS 데이터 전반 | 감사 리포트 |

보조 스크립트:

- `scripts/strip_lua_comments.py` — 소스 주석 제거. 동결 파일 9종은 건드리지 않고, `Data/ItemLevelTable.lua`는 `ns.Data.BISRewardProfiles` 앞까지만 처리한다. 파일마다 처리 전후 AST를 비교해 주석만 사라졌음을 증명하고, 다르면 쓰지 않는다. `--check`는 검사만, `--extract`는 제거할 주석을 별도 파일로 남긴다
- `scripts/package_release.ps1` — `dist/` ZIP 생성
- `scripts/refresh_wowhead_bis.py` — 와우헤드 수집. `--review <경로>`는 파일을 쓰지 않고 결과만 확인한다
- `scripts/validate_bis_reward_profiles.py` — M+ BIS row의 보상 프로필 key 참조 검증

현재 상태: `sources`의 `delves / mythicPlus / raid / pvp`가 `guide`로 남아 있어 `-Strict`가 실패합니다. 이 상태로는 릴리스할 수 없습니다.

## 회귀 포인트

시즌 2:

- BIS 상단 안내에 시즌 접두가 붙지 않는지(데이터와 `SeasonGuard.dataSeason`이 모두 시즌 2일 때가 정상)
- 시즌 불일치일 때 Encounter Journal 자동 랜딩, M+ 자동 점수화, preview snapshot 스캔이 모두 멈추고 실패 재시도가 없는지
- 시즌이 바뀌면 기존 `mythPreviewCache`가 버려지고 새로 만들어지는지
- 전투 / 레이드 조우 / 쐐기 / PvP 중 스탯 오버레이에서 aura Lua 오류가 나지 않고 2초 backoff가 걸리는지
- 아이템 레벨 오버레이가 안개문장 5종(`3442~3446`) 보유량과 복원 열쇠 `3028`을 표시하는지
- 구렁 1~11단계, M+ +2~+12, 레이드 3난이도, `worldBoss` 4난이도 행이 `gradeMax` 상한을 넘지 않는지
- `ChallengesFrame`이 늦게 로드돼도 M+ 기록 오버레이 훅이 한 번만 설치되는지

BIS / 표시:

- 필터 on/off 후 visible rank가 다시 계산되는지
- 아이템 토글이 기본 on이고, 직접 off 후 재오픈해도 유지되는지
- 즐겨찾기 / 보유 체크가 캐릭터별·전문화별로 분리 저장되고 즉시 갱신되는지
- `레이드 off + 쐐기만 on`에서 쐐기 드랍템과 인던명이 남는지
- BIS hover 뒤 액션바 / 모험 안내서 / Pawn item tooltip에서 `MoneyFrame.lua secret number` 오류가 재발하지 않는지
- `koKR`에서 영어 누수, `enUS`에서 한글 누수가 없는지
- 스크롤 thumb, 마지막 열 가림, 저장 위치·스케일, 접힘 복원이 유지되는지
- `스탯 우선순위 표` 버튼, 현재 전문화 강조, 긴 분기 문구 줄바꿈이 유지되는지
