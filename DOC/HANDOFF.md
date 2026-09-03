# ABProfileManager Handoff

버전 기준: `v1.13.0` (WoW 12.1.0 / Midnight 시즌 2 대응)

시즌 2 작업의 원본 인계 문서는 [SEASON2_HANDOFF.md](./SEASON2_HANDOFF.md)다. wave별 진행 로그, 미확정 데이터 표, 재개 프롬프트는 그쪽을 본다. 이 문서는 릴리스 이후에도 남길 운영 메모, 회귀 포인트, 미완성 기능만 담는다.

## 0. v1.13.0 작업 메모

시즌 2 인게임 QA에서 나온 결함을 고친 릴리스다. 상세 내역은 [releases/RELEASE_NOTES_v1.13.0.md](./releases/RELEASE_NOTES_v1.13.0.md)와 `CHANGELOG.md`를 본다. 여기에는 다시 밟기 쉬운 함정만 남긴다.

### 회귀 포인트

- **문자열 안 CR.** `UI/MythicPlusRecordOverlay.lua`가 문자열 리터럴 안에 `0x0d`가 섞여 로드에 실패한 적이 있다. Lua는 CRLF 줄바꿈은 받아들이지만 문자열 **안**의 CR은 `unfinished string`이다. Windows에서 `perl -i`로 Lua를 편집하면 이 상태가 만들어진다. 편집은 정규 편집 도구로 하고, 끝나면 문자열 내 단독 CR이 없는지 확인한다.
- **부정 캐시.** 모험 안내서 데이터는 로드 직후 비어 있다. 그 시점의 조회 실패를 캐시에 `false`로 박으면 세션 내내 복구되지 않는다. 실패를 캐시하기 전에 조회 대상 목록이 비어 있지 않은지 먼저 본다.
- **`C_MythicPlus.GetCurrentSeason()`은 준비 전 `-1`을 준다.** `if ok and current then`은 `-1`도 통과시킨다. 캐시 무효화 키에 이 값을 그대로 넣으면 매 접속마다 캐시가 폐기된다.
- **`EJ_GetEncounterInfoByIndex(index, instanceID)`** 는 인스턴스 인자를 받아도 해당 인스턴스가 선택되지 않았으면 빈 값을 준다. 조회 전에 `EJ_SelectInstance`로 선택하고 끝나면 되돌린다.
- **EJ 상태 복원.** 티어·인스턴스·난이도·전리품 필터를 바꾸면 사용자가 보던 안내서 화면이 튄다. 바꾼 것은 전부 되돌린다.
- **프레임 앵커 과제약.** `RIGHT` 앵커는 가로 위치뿐 아니라 세로 중심까지 고정한다. `TOPLEFT` + `RIGHT`만 잡으면 높이가 의도와 다르게 계산된다. 상·하단을 명시한다.
- **`USER_SELECTED` 스탯 우선순위.** `MidnightS1_MPlus_Addon_DB_v1.7.lua`에서 `source="USER_SELECTED"` 표식이 붙은 전문화는 수동 확정값이다. `scripts/refresh_wowhead_stat_priority.py`가 이 줄을 건너뛴다. 수집기를 고칠 때 이 가드를 지우지 않는다.
- **`BISOverlay.lua` top-level local 예산.** 상한 `198`, 현재 `195`. 넘기면 WoW가 청크를 로드하지 못한다. 새 상태는 `EJournal` / `SourcePreview` 테이블 필드로 붙인다.

### 데이터 한계

- BIS 카탈로그의 `boss` 필드는 `657`행 전부 `nil`이다. 보스명은 모험 안내서 전리품 인덱스로 런타임 해석하고 `SavedVariables`에 캐시한다.
- Wowhead 시즌 2 가이드는 슬롯 대안을 제시하지 않는다. 40개 전문화 중 36개가 `Overall BiS` 탭 하나뿐이라 슬롯당 2순위 후보를 만들 수 없다. 다른 출처를 붙이지 않는 한 이 상태가 유지된다.
- 임의 업그레이드 단계의 정확한 아이템 링크는 클라이언트가 제공하지 않는다. `C_ItemUpgrade`는 실제 보유 아이템 전용이고 검증된 bonusID 표가 없다. 툴팁 단계 선택은 `기준:` 줄만 바꾼다.

## 0-1. v1.12.0 작업 메모

### 반영된 변경

- TOC는 `## Interface: 120100` 단일 지정, `## Version: 1.12.0`이다. `Constants.VERSION` fallback도 `1.12.0`이다. 구형 `120005, 120007`은 라이브 클라이언트에 없어 제거했다.
- 클라이언트 기준값은 `12.1.0` 빌드 `69465` (2026-08-21)다. 시즌 2는 2026-08-18 시작했고 패치명은 `Curse of Ula'tek`이다. 신규 지역 `Coiled Isle`, 신규 레이드 `The Venomous Abyss`(8보스), 신규 던전 `Altar of Fangs`(3보스), 신규 Lair `The Tidebound Grotto`가 추가됐다.
- `Data/ItemLevelTable.lua`를 `Midnight Season 2` 값으로 교체했다.
  - 등급은 `expl` 제거 후 5종이다. `gradeMax`는 `adv 282`, `vet 295`, `chmp 308`, `hero 321`, `myth 334`.
  - 강화 랭크 사다리는 기준값 `+0, +3, +6, +10, +13, +16` 6단계다. 제작 품질 사다리는 `+0, +3, +6, +9, +13` 5단계로 서로 다르다.
  - 제작은 base(룬각인) `318`, r5(금박) `331`. 구렁 최고 단계는 `11`을 유지한다.
  - `worldBoss`는 야외 / 일반 / 영웅 / 신화 4난이도로 확장했다. Lair 드랍이 레이드 1보스와 같은 아이템 레벨이라 스키마 변경 없이 값만 넣었다.
  - 수치 그룹마다 `sources` 태그(`dump` / `tooltip` / `guide`)를 요구한다.
  - 하단 `ns.Data.BISRewardProfiles` 블록은 시즌 2 값(`311` / `318`)이며 주석까지 포함해 sha256으로 고정된다.
- `UI/ItemLevelOverlay.lua`의 `CREST_ID_BY_GRADE`를 시즌 2 안개문장(Mistcrest)으로 교체했다: `adv 3442`, `vet 3443`, `chmp 3444`, `hero 3445`, `myth 3446`. 시즌 1 ID와 겹치지 않는 신규 통화다. `DELVE_RESTORED_KEY_CURRENCY_ID = 3028`은 시즌 1 값이 그대로 유효하다.
- 12.1 aura 접근 제한에 대응했다. 전투 / 레이드 조우 / 쐐기 / PvP 중에는 `C_UnitAuras`의 index·slot·instanceID 조회가 Lua 오류를 낸다. `UI/StatsOverlay.lua`의 버프 hash는 `pcall` 실패 시 backoff `2.0초`를 걸고 부분 hash 대신 빈 문자열을 돌려준다. spellID 기반 조회는 종전대로 동작한다.
- `UI/MythicPlusRecordOverlay.lua`의 훅 감시자가 addon 이름에 의존하지 않도록 바꾸고 `PLAYER_ENTERING_WORLD`를 추가했다. `_hooksReady`로 1회 설치는 유지한다.
- `UI/BISOverlay.lua`에 `SeasonGuard`를 추가했다. `dataSeason`과 `ItemLevelTable.season`을 비교해 불일치면 Encounter Journal 자동 랜딩, M+ 자동 점수화, preview snapshot 스캔, preview 순위 점수를 모두 끄고 상단 안내에 짧은 시즌 접두와 경고색을 붙인다. BIS 데이터를 시즌 2로 재생성한 뒤 `dataSeason`도 `Midnight Season 2`로 올려 현재 차단은 꺼져 있다.
- BIS 데이터를 시즌 2로 재생성했다. `scripts/build_bis_catalog.py --overall-only`가 와우헤드 overall 데이터만 사용하며 결과는 `641`행이다(raid 371, crafted 103, mythicplus 88, tier 79). 시즌 1 후보 시드와 관련 입력·스크립트는 제거했다. v1.13.0에서 `657`행(raid 393, crafted 78, mythicplus 107, tier 79)으로 재생성했다.
- Encounter Journal 랜딩 데이터를 시즌 2 던전 8종으로 갱신했다. `currentSeasonTierIndex`는 `13` 그대로다. "현재 시즌" tier가 동적이라 시즌이 바뀌어도 인덱스가 같다는 것을 인게임 덤프로 확인했다.
- 시즌 2 preview selector 두 종은 값을 확인하지 못해 비활성이다. 그 결과 M+ 자동 점수화와 시즌 preview 툴팁이 동작하지 않는다. 지어내면 잘못된 아이템 레벨의 preview가 만들어지므로 비워 두었다.
- `DB:GetBISOverlayMythPreviewCache()`의 무효화 키에 현재 시즌을 추가했다. 기존 무효화 조건이 전부 동결된 `BISMythicVaultLinks.lua`에서 와서 시즌 전환을 감지하지 못했다.
- 검증 하네스 `scripts/run_season2_validation.ps1`과 검증기 3종(`validate_season2_scope.py`, `validate_season2_itemlevel.py`, `validate_locale_contract.py`)을 추가했다.
- 소스 Lua 주석을 전부 제거했다. `scripts/strip_lua_comments.py`가 담당하며 동결 파일 9개와 `ItemLevelTable.lua`의 `BISRewardProfiles` 블록은 예외다.

### 미완 사항

- **릴리스 불가 상태다.** `ItemLevelTable.lua`의 `delves` / `mythicPlus` / `raid` / `pvp`가 아직 `sources = "guide"`라 `-Strict` 검증이 실패한다. 인게임 실측으로 `tooltip` 또는 `dump`로 올려야 패키징할 수 있다.
- PvP 값(명예 `266~295`, 정복 `295~321`)은 랭크 사다리에서 유도한 추정치다. 와우헤드에 시즌 2 PvP 페이지가 없어 인게임 상인 툴팁 확인이 필요하다.
- 영웅 던전 위대한 금고 아이템 레벨이 미확인이다. 클리어 값 `276`(모험가 4/6)은 확정이다.
- `expl` 탐험가 트랙은 대응 문장이 없어 제거했지만 인게임 존재 여부는 미확인이다.
- `Coiled Isle` UiMapID(후보 `2512`), 신규 구렁·던전 UiMapID, 전문기술 지식 questID, 주간 이벤트 좌표가 전부 미확정이다. 지도 / 전문기술 / 주간 이벤트 데이터 작업이 이 때문에 막혀 있다.
- 로케일 3종 갱신 미착수다. `Locale.lua`, `Locale_Additions.lua`, `ABPM_ruRU_Final_v3.lua`는 단일 소유 파일이므로 다른 작업은 키만 요청한다.
- `UI/MythicPlusRecordOverlay.lua`의 `DUNGEON_NAME_OVERRIDES`가 아직 시즌 1 던전 기준이다. 시즌 2 던전 이름 줄바꿈 override는 없다.
- BIS 후보 수가 시즌 1보다 크게 줄었다. 넓은 후보 시드 없이 와우헤드 overall 데이터만 쓰기 때문이며, 적지만 시즌 2에서 실제 획득 가능한 아이템이다.
- 인게임 QA와 v1.12.0 패키징 미착수다. 릴리스 마무리 체크리스트는 `SEASON2_HANDOFF.md` 13장에 있다.

## 0-prev. v1.11 계열 요약

v1.11.0 ~ v1.11.11은 Midnight 시즌 1 BIS 오버레이의 점수화와 tooltip 표시를 다듬은 계열이다. 정적 후보 풀은 v1.3 입력으로 만든 `Data/BISCatalog.lua` `3330`행(`mythicplus 2554`, `raid 485`, `crafted 91`, `tier 200`)이고, v1.7 컴팩트 코어를 `Data/MidnightS1MPlusDB.lua`로 설치해 실제 `itemLink`를 점수화한다. 시즌 preview link DB 2종(`BISMythicVaultLinks.lua` selector `12801`, `BISSeasonPreviewLinks.lua`)을 도입해 검증을 통과한 preview만 addon-owned Blizzard tooltip에 넘기고, 실패하면 기본 `itemLink` fallback으로 떨어진다. 그 밖에 Encounter Journal 랜딩에서 보호된 `C_EncounterJournal.SetTab` 직접 호출 제거, 전투 중 자동 랜딩 생략, `BISOverlay` top-level local 200개 제한 대응, 12.0.7 진균나락 raid 11종 추가, secret number 정규화 보강이 포함된다. 이 계열의 시즌 1 값은 v1.12.0에서 모두 시즌 2로 교체됐다.

v1.10.0 이전 버전별 메모는 [archive/legacy-docs](./archive/legacy-docs)와 [releases](./releases)의 릴리스 노트를 본다. 지금도 유효한 규칙은 아래 회귀 민감 메모와 운영 메모로 옮겨 두었다.

## 현재 상태

프로젝트는 실제 인게임 사용 기준으로 유지되는 WoW Retail 애드온이다. 문서 세트는 루트 `README.md`를 사용자 안내로, `DOC` 아래 문서를 기술/운영 문서로 유지한다.

현재 기준 핵심 기능:

- 액션바 템플릿 저장, 적용, 비교, 부분 적용, 동기화, 최근 1회 되돌리기
- 전문기술 포인트 자동 추적 카드와 오버레이
- Midnight 전투메시지 표출 방식 관리
- 퀘스트 정리와 퀘스트 ID 상세 열기
- 캐릭터 스탯 오버레이
- 한밤(Midnight) 지도 오버레이
- 지도 전용 탭과 typography 슬라이더
- 와우 `설정 > 애드온` 경량 하위 페이지
- 드랍템 레벨정보 오버레이
- BIS 추천 장비 카탈로그 오버레이
- 파티찾기 시즌 최고기록 아이콘 오버레이
- 스탯 우선순위 표 팝업
- 블리자드 기본 UI 창 이동 자유화
- 편의기능 탭 통합

## 1. 회귀 민감 메모

### BIS 추천 장비 오버레이

시즌 동결 상태:

- BIS 런타임 데이터의 기준 해시는 `scripts/validate_season2_scope.py`가 관리한다. 값을 바꾸면 해시도 함께 갱신한다.
- 시즌 2 M+ 던전 풀 8종은 시즌 1과 하나도 겹치지 않는다. 동결된 M+ 후보는 시즌 2에서 전부 획득 불가다.
- `SeasonGuard`가 `ItemLevelTable.season`과 `dataSeason`을 비교해 불일치를 감지하면 Encounter Journal 자동 랜딩, M+ 자동 점수화, preview snapshot 스캔, preview 순위 점수를 끈다. 실패를 반복 시도하지 않는다.
- 상단 안내는 한 줄 고정이고 줄바꿈이 꺼져 있다. 시즌 이름을 그대로 붙이면 스탯 정책 요약이 잘리므로 `[S1]` 형태의 짧은 접두만 쓴다.
- `Data/MidnightS1MPlusDB.lua`와 `v1.7` 입력은 파일명과 달리 시즌 1 BIS 데이터가 아니라 40개 전문화 스탯 우선순위 정책이다. `12.0.5` 기준으로 유지하며 카탈로그 행의 검증 메타데이터도 여기서 나온다.
- `scripts/validate_bis_tooltip_contract.py`가 `BISOverlay` top-level local 개수를 검사한다. 현재 `198`로 상한 `200`에 붙어 있으므로 새 local 대신 기존 테이블 필드를 쓴다.

구조와 표시 규칙:

- `UI/BISOverlay.lua`는 폭/열 간격/스크롤 영역 민감도가 높다. 열 폭만 조정하지 말고 스크롤 thumb와 마지막 열 가림 여부까지 확인한다.
- sourceGroup은 `mythicplus / raid / crafted / tier` 4개다. source 판정은 `sourceGroup` 정적 값을 우선하고 예전 `sourceLabel` 재분류에 기대지 않는다.
- 필터 적용 후 visible list 기준으로 `1순위 / 2순위 / 3순위+`를 다시 번호 매긴다.
- `레이드 off + 쐐기만 on`에서 각 부위의 쐐기 드랍템과 인던이 남아야 한다. 깨지면 release blocker다.
- locale은 row에 저장된 `nameKoKR/nameEnUS`, `displaySourceKoKR/displaySourceEnUS`를 그대로 쓴다. 런타임 번역 fallback을 넣지 않는다. `boss` 필드에는 legacy 한국어 값이 남아 있을 수 있어 런타임 alias 매핑을 같이 본다.
- `crafted`, `tier`는 Encounter Journal 랜딩 대상이 아니다. `openEncounterJournalForEntry()`의 조기 return을 함께 본다.
- 보호된 `C_EncounterJournal.SetTab`을 직접 호출하지 않는다. 전투 중에는 자동 랜딩을 건너뛰어 Blizzard 보호 기능 차단 팝업을 막는다.
- BIS 아이템 hover는 addon-owned Blizzard item tooltip을 쓰고 shopping tooltip 경로로 sell price `MoneyFrame` 렌더링을 차단한다. 전역 `GameTooltip`을 BIS hover 대상으로 쓰지 않는다.
- 검토되지 않은 bonusID를 `itemID`와 임의 조합하지 않는다.
- 즐겨찾기/보유 상태는 캐릭터 record 안에서 전문화별로 분리한다. 즐겨찾기 섹션 이동과 보유 취소선 갱신을 함께 확인한다.
- 장비/가방 링크는 정렬이나 hover에서 다시 스캔하지 않는다. 보유 체크 on 시 저장용 링크를 한 번만 찾는다. 스크롤 중 tooltip 렌더 억제, 점수 캐시, 아이템 요청 dedupe, 분산 큐 규칙을 유지한다.
- hover/자동 큐에서 Encounter Journal UI 상태를 바꾸거나 숨은 loot scan을 다시 연결하지 않는다.
- `StatsOverlay`에 미사용 `PaperDollFrame_Set*` tooltip setter를 다시 연결하지 않는다. `Utils.SafeNumber()`가 정규화하지 못한 secret 값을 원본 그대로 반환하게 바꾸지 않는다.
- `Data/BISEncounterJournal.lua`의 `currentSeasonJournalTierID = 505`, `currentSeasonTierIndex = 13`과 아래 `JournalInstanceID`는 시즌 1 값이며 동결이다. 시즌 2 기준으로 재검증하지 않았다.
  - `Magisters' Terrace = 1300`, `Maisara Caverns = 1315`, `Nexus-Point Xenas = 1316`, `Windrunner Spire = 1299`, `Algeth'ar Academy = 1201`, `Seat of the Triumvirate = 945`, `Skyreach = 476`, `Pit of Saron = 278`

### 드랍템 레벨 오버레이

- `UI/ItemLevelOverlay.lua` 우측 패널은 `나의 문장` + `나의 열쇠` 2개 섹션이다.
- 시즌 2 문장은 안개문장(Mistcrest)이다. `CREST_ID_BY_GRADE = { adv=3442, vet=3443, chmp=3444, hero=3445, myth=3446 }`.
- `DELVE_RESTORED_KEY_CURRENCY_ID = 3028`
- `열쇠 파편`은 안전한 itemID가 확정되지 않아 `-` fallback이 남아 있다.
- 통화 API가 `nil`을 돌려줘도 오류 대신 `-`로 표시한다.
- 구렁 표는 `11단계`까지다. 시즌 2도 최고 단계는 `11`이다.

### 파티찾기 시즌 최고기록 오버레이

- `UI/MythicPlusRecordOverlay.lua`는 이동형 프레임이 아니라 `ChallengesFrame.DungeonIcons` 위에 붙는다. `ChallengesFrame`이 나중에 로드돼도 훅은 정확히 한 번만 설치돼야 한다.
- 표시 규칙은 `평점 + 던전명`이다.
- `DUNGEON_NAME_OVERRIDES`는 아직 시즌 1 던전 이름만 담고 있다. 시즌 2 던전 8종은 override가 없어 기본 표시로 나온다.
- 시즌 2 M+ 던전 `challengeMapID`: `249` 왕들의 안식처, `250` 세스랄리스 사원, `399` 루비 생명의 웅덩이, `584` 눈부신 골짜기, `585` 공허흉터 투기장, `586` 날로라크의 소굴, `587` 죽음의 골목, `588` 송곳니의 제단. 이 값은 `JournalInstanceID`나 `UiMapID`와 다르다.

### BlizzardFrameManager / 지도

- `SetUserPlaced(true)`는 저장 좌표가 있는 UIPanel 프레임에만 적용한다. 저장 좌표가 없는 기본 창을 초기부터 UserPlaced로 고정하면 은행/캐릭터/특성 창이 중앙에 겹친다.
- `global.settings.blizzardFrames.layoutVersion`은 `2`다. 이전 저장 좌표는 1회 비운다.
- WorldMapFrame에 `SetUserPlaced(true)`를 남기면 오른쪽 퀘스트 목록 패널이 숨는다. 위치 저장 없이 드래그 전용으로 유지한다.
- 지도 오버레이는 child/detail map에서 부모 라벨을 억지로 보여주지 않는다.

## 2. 운영 메모

### 12.1 aura 접근 제한

- 전투, 레이드 조우, 쐐기, PvP 중에는 aura가 보호 상태다. 이때 `C_UnitAuras`의 index / slot / instanceID 기반 조회는 Lua 오류를 낸다. spellID 기반 조회는 정상이다.
- `UnitAura` 계열은 보호 상태에서 secret payload를 돌려준다.
- 이 저장소에서 영향을 받는 곳은 `UI/StatsOverlay.lua`의 버프 hash 한 군데다. `Modules/PrivateAurasGuard.lua`는 `PrivateAuraAnchorContainerMixin`이 없으면 조용히 넘어간다.
- 새 aura 코드를 넣을 때는 index/slot 조회 대신 spellID 경로를 쓴다.

### profession / quest refresh

- profession/quest refresh는 보호 경로를 거친다.
- `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED` 뒤 follow-up refresh가 들어간다.
- `Modules/ProfessionKnowledgeTracker.lua`는 완료 퀘스트 스냅샷이 실제로 바뀐 경우에만 `questCacheGeneration`과 요약 캐시를 무효화한다.
- `UI/ProfessionKnowledgeOverlay.lua` tooltip 라인은 refresh 때 미리 만들지 않고 hover 시점에만 계산한다.

### 전투메시지 표출 방식

- 기본 WoW 전투메시지 on/off는 건드리지 않고 `위로 / 아래로 / 부채꼴` 표출 방식과 방향성 분산만 관리한다.
- `_v2` CVar 우선, 없으면 구형 이름 fallback.
- 모드 값은 `1=위로`, `2=아래로`, `3=부채꼴`.

### 오류 로그와 tooltip

- `/abpm log`와 `/abpm errors`는 디버그 로그와 ABPM 보호 오류 로그를 함께 보여준다. 보호 오류는 `Utils.RecordCaughtError()`에 세션 한정으로 저장하고 같은 오류는 count로 압축한다.
- ABPM UI hover 설명은 전역 `GameTooltip`이 아니라 `UI/Widgets.lua`의 `Widgets.GetTooltip()` / `Widgets.HideTooltip()` 전용 프레임을 쓴다.
- `UI/StatsOverlay.lua`의 특화 tooltip은 `C_SpecializationInfo.GetSpecializationMasterySpells()`로 Mastery spellID를 얻고 `C_TooltipInfo.GetSpellByID()` line을 전용 tooltip에 렌더링한다. 전역 `GameTooltip:SetSpellByID()`를 직접 쓰지 않는다.
- `Modules/PrivateAurasGuard.lua`는 PrivateAuras의 좁은 assertion 충돌만 우회한다. 전역 `scriptErrors` CVar는 건드리지 않는다.

### 소스 주석 정책

- 소스 Lua 주석은 전부 제거된 상태다. `scripts/strip_lua_comments.py`가 담당한다.
- 동결 파일 10종과 `Data/ItemLevelTable.lua`의 `BISRewardProfiles` 블록은 제외 대상이다. 이 파일들은 byte-identical을 유지해야 한다.

### TomTom waypoint 지역 컨텍스트

- 하란다르와 공허폭풍 일부 보물은 별도 지역 지도라서 해당 지역에 들어가야 waypoint가 정상 생성된다.
- TomTom 관련 제보가 오면 지역 진입 여부와 map lineage를 먼저 확인한다.

## 3. 미완성 기능

### 시즌 2 미확정 데이터

- PvP 명예 / 정복 아이템 레벨, 영웅 던전 금고 아이템 레벨, `expl` 트랙 존재 여부는 미확인이다. 인게임 툴팁으로만 확정한다.
- `Coiled Isle` UiMapID, 신규 구렁·던전 UiMapID, 전문기술 지식 questID, 주간 이벤트 좌표(시즌 1분도 미실측)가 미확정이라 지도/전문기술/주간 이벤트 작업이 막혀 있다.
- 추정값이나 산술 유도값을 코드에 넣지 않는다. 라이브 덤프나 실제 툴팁으로 확인된 값만 반영한다.

### BIS 시즌 동결

- 시즌 2 BIS 후보 재생성은 v1.12.0 범위 밖이다. SeasonGuard 안내로 저하를 드러내는 것까지가 이번 범위다.
- 시즌 2 데이터를 다시 만들 때는 던전 8종의 `JournalInstanceID`와 현재 시즌 tier를 새로 검증해야 한다. `challengeMapID`를 그대로 쓸 수 없다.

### 스탯 오버레이 쐐기(M+) 우선순위 호환 키

- 전문화별 단일 대표 우선순위를 쓰므로 M+ 전용 UI와 런타임 분기는 제거됐다.
- `DB.lua`의 `mythicPlusMode` 저장 키와 getter/setter는 이전 SavedVariables 호환을 위해 유지한다.
- 콘텐츠별 우선순위를 다시 도입하면 검증된 별도 정책 입력과 UI 문구를 함께 설계해야 한다.
- 스탯 우선순위 값 자체는 12.0.5 기준으로 동결이다.

### 경매장 현행 확장팩 필터 자동 선택

- 설정 탭 체크박스 UI 숨김 처리 유지.
- WoW 보안 시스템 taint 문제로 동작 불가.

### 패키지에서 로드 제외한 비활성 기능

- 아래 파일은 repo에 남기지만 현재 패키지 TOC에서는 제외한다.
  - `Data/WorldEventSchedule.lua`
  - `Modules/MerchantHelper.lua`
  - `Modules/MailHistory.lua`
  - `UI/WorldEventOverlay.lua`
- 다시 살릴 때는 `ABProfileManager.toc`, `Core.lua`, `Events.lua`, 관련 DB/Locale 키 사용처를 같이 점검한다.

## 4. 중요한 파일

### 핵심

- `ABProfileManager/Core.lua`
- `ABProfileManager/DB.lua`
- `ABProfileManager/Events.lua`
- `ABProfileManager/Constants.lua`
- `ABProfileManager/Locale.lua`
- `ABProfileManager/Locale_Additions.lua`
- `ABProfileManager/ABPM_ruRU_Final_v3.lua`

### 드랍 / BIS / 시즌 최고기록

- `ABProfileManager/UI/ItemLevelOverlay.lua`
- `ABProfileManager/UI/BISOverlay.lua`
- `ABProfileManager/UI/MythicPlusRecordOverlay.lua`
- `ABProfileManager/UI/StatsOverlay.lua`
- `ABProfileManager/Data/ItemLevelTable.lua`
- `ABProfileManager/Data/BISCatalog.lua`
- `ABProfileManager/Data/MidnightS1MPlusDB.lua`
- `ABProfileManager/Data/BISRuntimeScoring.lua`
- `ABProfileManager/Data/StatPriorityTable.lua`
- `ABProfileManager/UI/StatPriorityDialog.lua`
- `ABProfileManager/Data/BISMythicVaultLinks.lua`
- `ABProfileManager/Data/BISSeasonPreviewLinks.lua`
- `ABProfileManager/Data/BISEncounterJournal.lua`
- `ABProfileManager/Data/BISData_Method.lua`

### 스크립트

- `scripts/run_season2_validation.ps1`
- `scripts/validate_season2_scope.py`
- `scripts/validate_season2_itemlevel.py`
- `scripts/validate_locale_contract.py`
- `scripts/strip_lua_comments.py`
- `scripts/rebuild_bis_database.ps1`
- `scripts/build_bis_catalog.py`
- `scripts/build_bis_runtime_scoring.py`
- `scripts/validate_bis_mythic_vault_links.py`
- `scripts/validate_bis_season_preview_links.py`
- `scripts/validate_bis_tooltip_contract.py`
- `scripts/validate_bis_encounter_journal.py`
- `scripts/validate_bis_catalog.py`
- `scripts/validate_bis_reward_profiles.py`
- `scripts/audit_bis_data.py`
- `scripts/package_release.ps1`

### 오프라인 생성 입력

- `DOC/MidnightS1_MPlus_Addon_Master_v1.7.md` / `DOC/MidnightS1_MPlus_Addon_DB_v1.7.lua`

### profession / 지도 / 설정

- `ABProfileManager/Modules/ProfessionKnowledgeTracker.lua`
- `ABProfileManager/Modules/TomTomBridge.lua`
- `ABProfileManager/Modules/CombatTextManager.lua`
- `ABProfileManager/UI/ProfessionPanel.lua`
- `ABProfileManager/UI/ProfessionKnowledgeOverlay.lua`
- `ABProfileManager/UI/SilvermoonMapOverlay.lua`
- `ABProfileManager/UI/MapPanel.lua`
- `ABProfileManager/UI/ConfigPanel.lua`
- `ABProfileManager/UI/UtilityPanel.lua`

## 5. 검증 습관

시즌 2 작업 중에는 통합 하네스를 쓴다.

```powershell
pwsh -NoProfile -File .\scripts\run_season2_validation.ps1
pwsh -NoProfile -File .\scripts\run_season2_validation.ps1 -Strict
```

- 하네스 순서: Lua 전체 파싱 → `git diff --check` → 범위 보호(동결 파일 해시) → 아이템 레벨표 → 로케일 계약 → 기존 BIS 검증 6종.
- `-Strict`는 출처가 `guide`뿐인 값을 실패로 처리한다. 릴리스 패키징 직전에는 반드시 `-Strict`로 실행한다. 현재는 `delves` / `mythicPlus` / `raid` / `pvp`가 `guide`라 실패한다.
- BIS 데이터를 다시 만들 일이 있으면 `powershell -ExecutionPolicy Bypass -File .\scripts\rebuild_bis_database.ps1`을 쓴다. 다만 v1.12.0 범위에서는 BIS 데이터가 동결이라 실행하지 않는다.
- 로컬 배포는 작업공간 `dist/` ZIP 생성까지만 한다. WoW 설치 폴더로 복사하지 않는다.
- 원격 공개는 명시적으로 요청받은 경우에만 마지막에 푸시와 GitHub release를 진행한다.

인게임 회귀 포인트:

- 애드온 로드 시 Lua 오류 없음, `Interface: 120100`으로 구버전 경고 없음
- 전투 / 레이드 조우 / 쐐기 / PvP 진행 중 스탯 오버레이가 aura 오류를 내지 않는지
- 드랍템 레벨 오버레이 우측 `나의 문장 / 나의 열쇠` 패널이 안개문장 5종 수량을 표시하는지, 통화가 없을 때 `-`로 떨어지는지
- 아이템 레벨표의 M+ / 구렁 / 레이드 / 제작 수치가 인게임 툴팁과 일치하는지
- BIS 오버레이 상단 안내에 `[S1]` 접두와 경고색이 보이는지, 스탯 정책 요약이 잘리지 않는지
- 시즌 불일치 상태에서 BIS 드랍 출처 클릭 시 자동 랜딩이 생략되는지, 반복 재시도가 없는지
- BIS 아이템 hover 후 액션바 / 모험 안내서 / Pawn 아이템 tooltip에서 `MoneyFrame.lua` 오류가 없는지
- BIS 필터 on/off와 visible rank 재계산, `레이드 off + 쐐기만 on`에서 쐐기 행 유지
- BIS 즐겨찾기/보유 체크, 최상단 즐겨찾기 섹션, 보유 아이템명 취소선, 캐릭터/전문화 전환 후 상태 유지
- 파티찾기 창을 늦게 열어도 시즌 최고기록 오버레이 훅이 1회만 설치되는지, `평점 / 던전명` 위치와 줄바꿈
- 시즌 1 SavedVariables로 로그인해도 창 위치·크기·탭·토글이 유지되는지
- profession 카드 폭과 체크박스 레이아웃, overlay 상세/요약/최소
- 전투메시지 설정 체크박스와 `위로 / 아래로 / 부채꼴` 버튼 선택 상태
- 지도 오버레이가 외부 월드맵에서만 표시되는지
- 메인 창 `스탯 우선순위 표` 버튼, 현재 전문화 강조, 긴 분기 문구 줄바꿈

## 6. 다음 작업자에게

- 시즌 2 작업을 이어받으면 `SEASON2_HANDOFF.md` 11장 진행 로그부터 읽고 wave를 고른다. 12장에 재개 프롬프트가 있다.
- UI 퍼블리싱은 이미 사용자가 맞춘 상태를 선호하므로 overflow 보정과 안전장치 위주로 접근한다.
- 출처가 확인되지 않은 ID·좌표·아이템 레벨은 하드코딩하지 않는다. 모르면 미확인으로 남긴다.
- 동결 파일은 어떤 이유로도 수정하지 않는다. 해시가 하나라도 어긋나면 릴리스를 중단한다.
- 기록물은 한국어로 작성한다. 커밋 메시지, PR 본문, 문서 모두 한국어를 쓴다.
