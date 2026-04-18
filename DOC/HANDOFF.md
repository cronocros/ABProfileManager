# ABProfileManager Handoff

버전 기준: `main (v1.7.0 기반)`

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
- 블리자드 기본 UI 창 이동 자유화
- 편의기능 탭 통합

## 0. v1.7.0 BIS 카탈로그 재정비 메모

- `Data/BISCatalog.lua`가 BIS 런타임 단일 데이터 소스다. `Data/BISData_Method.lua`, `Data/BISData.lua`는 생성기 입력으로만 쓴다.
- spec 기준은 **40 spec 전체**다. 누락이 나면 먼저 `scripts/refresh_wowhead_bis.py`, `scripts/build_bis_catalog.py` 검증 실패부터 확인한다.
- 새 sourceGroup은 `mythicplus / raid / crafted / tier` 4개다. DB 기본값과 migration도 이 4개를 전제로 한다.
- 필터 적용 후 visible list 기준으로 `1순위 / 2순위 / 3순위+`를 다시 번호 매긴다. 예전처럼 전체 rank를 고정 노출하는 구조가 아니다.
- `레이드 off + 쐐기만 on` 상태에서도 각 부위의 쐐기 드랍템과 인던이 남아야 한다. 이 조건이 깨지면 release blocker로 본다.
- locale은 row에 저장된 `nameKoKR/nameEnUS`, `displaySourceKoKR/displaySourceEnUS`를 그대로 쓴다. 런타임 번역 fallback을 넣지 않는 편이 안전하다.
- 한글명은 `공식 KR 표기 > Wowhead koKR > DOC companion 검증 통과값` 우선순위로 생성한다.
- `제나스 지점`, `알게타르 대학` 같은 alias는 생성기에서 canonical name으로 정규화한다. 런타임에서는 canonical label만 읽는다.
- 오버레이 open/spec/filter 전환은 단일 rebuild 경로를 유지한다. `GET_ITEM_INFO_RECEIVED`는 visible row patch만 처리한다.
- crafted/tier는 Encounter Journal 랜딩 대상이 아니다. `mythicplus/raid`만 랜딩을 유지한다.
- `마이사라 동굴`, `윈드러너 첨탑` direct EJ ID는 아직 미확정이다.

## 0-prev. v1.6.0 오버레이 UX 핫픽스 메모

- `UI/BISOverlay.lua`와 `UI/ItemLevelOverlay.lua`의 마우스 휠 스케일링 기준점을 타이틀바(TOPLEFT)로 고정했다. 수식: `left * oldScale / newScale`.
- `UI/MainWindow.lua`의 `RefreshLocale()`에서 `SetText()` 후 `applyTabSelectionStyles()`를 재호출해 탭 텍스트 색상 소실을 방지한다.
- `UI/BISOverlay.lua`의 `Refresh()`에서 `RebuildContent()` 직후 접힌 상태면 `ApplyCollapse()`를 다시 호출해 프레임 높이를 복원한다.
- `UI/BISOverlay.lua`와 `UI/ItemLevelOverlay.lua`의 FrameStrata를 `DIALOG` → `MEDIUM`으로 변경했다. PVEFrame과 같은 레이어에 위치시켜 캐릭터창/스킬창 등 상위 strata 창에 자연스럽게 가려지도록 한다.

## 1. 회귀 민감 메모

### BIS 추천 장비 오버레이

- `UI/BISOverlay.lua`는 폭/열 간격/스크롤 영역 민감도가 높다. 열 폭만 조정하지 말고 실제 스크롤 thumb와 마지막 열 가림 여부까지 같이 확인해야 한다.
- source 판정은 `sourceGroup` 정적 값을 우선 사용한다. 예전 `sourceLabel` 재분류 로직에 다시 기대지 않는 편이 안전하다.
- `crafted`, `tier`는 랜딩하지 않는다. 이 경로를 건드릴 때는 `openEncounterJournalForEntry()`의 조기 return을 같이 본다.
- locale 누수는 build 단계에서 먼저 막고, 런타임에서는 locale별 저장 문자열만 그대로 노출한다.
- unresolved direct ID:
  - `마이사라 동굴`
  - `윈드러너 첨탑`

### 드랍템 레벨 오버레이

- `UI/ItemLevelOverlay.lua` 우측 패널은 `나의 문장` + `나의 열쇠` 2개 섹션이다.
- 현재 `CREST_ID_BY_GRADE`는 다음 값 기준으로 문서/코드를 맞춰둔 상태다.
  - `adv = 3383`
  - `vet = 3341`
  - `chmp = 3343`
  - `hero = 3345`
  - `myth = 3347`
- `DELVE_RESTORED_KEY_CURRENCY_ID = 3028`
- `열쇠 파편`은 여전히 안전한 itemID가 확정되지 않아 `-` fallback이 남아 있을 수 있다.

### 파티찾기 시즌 최고기록 오버레이

- `UI/MythicPlusRecordOverlay.lua`는 이동형 프레임이 아니라 `ChallengesFrame.DungeonIcons` 위에 붙는다.
- 현재 표시 규칙은 `평점 + 던전명`이다.
- 줄바꿈 override 대상:
  - `윈드러너 첨탑`
  - `삼두정의 권좌`
  - `제나스 지점`
  - `사론의 구덩이`
  - `마법학자의 정원`
  - `마이사라 동굴`
  - `알게타르 대학`

### BlizzardFrameManager / 지도

- `SetUserPlaced(true)`는 반드시 `uiPanel=true` 프레임에만 적용할 것. WorldMapFrame에 적용 시 오른쪽 퀘스트 목록 패널이 숨는다.
- 지도 오버레이는 child/detail map에서 부모 라벨을 억지로 보여주지 않는 현재 기준을 유지하는 편이 안전하다.

## 2. 운영 메모

### profession / quest refresh

- profession/quest refresh는 보호 경로를 거친다.
- `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED` 뒤 follow-up refresh가 들어간다.
- `Modules/ProfessionKnowledgeTracker.lua`는 완료 퀘스트 스냅샷이 실제로 바뀐 경우에만 `questCacheGeneration`과 요약 캐시를 무효화한다.
- `UI/ProfessionKnowledgeOverlay.lua` tooltip 라인은 refresh 때 미리 만들지 않고 hover 시점에만 계산한다.

### 전투메시지 표출 방식

- 현재는 기본 WoW 전투메시지 on/off를 건드리지 않고 `위로 / 아래로 / 부채꼴` 표출 방식과 방향성 분산만 관리한다.
- `_v2` CVar 우선, 없으면 구형 이름 fallback.
- 모드 값은 `1=위로`, `2=아래로`, `3=부채꼴`.

### TomTom waypoint 지역 컨텍스트

- 하란다르와 공허폭풍 일부 보물은 별도 지역 지도라서, 해당 지역에 들어가야 waypoint가 정상 생성된다.
- TomTom 관련 제보가 오면 지역 진입 여부와 map lineage를 먼저 확인한다.

## 3. 미완성 기능

### 스탯 오버레이 쐐기(M+) 우선순위 모드

- `UI/ConfigPanel.lua`에서 `mythicPlusCheck:Hide()`로 UI 숨김 처리
- 재개 시:
  - `UI/StatsOverlay.lua`의 `BuildSnapshot` `isMplus` 분기
  - `DB.lua`의 `IsStatsOverlayMythicPlusMode`
  - `Data/StatPriorities.lua`의 `ns.Data.StatPrioritiesMythicPlus`

### BIS 오버레이 direct EJ ID 미확인

- 현재 추가 확인이 필요한 던전:
  - `마이사라 동굴`
  - `윈드러너 첨탑`
- 현 클라이언트에서는 `EJ_GetInstanceByIndex()` 기반 확인이 더 안전하다.

### 경매장 현행 확장팩 필터 자동 선택

- 설정 탭 체크박스 UI 숨김 처리 유지
- WoW 보안 시스템 taint 문제로 동작 불가

### 패키지에서 로드 제외한 비활성 기능

- 아래 파일들은 repo에는 남겨 두지만 현재 패키지 TOC에서는 제외한다.
  - `Data/WorldEventSchedule.lua`
  - `Modules/MerchantHelper.lua`
  - `Modules/MailHistory.lua`
  - `UI/WorldEventOverlay.lua`
- 다시 살릴 때는 단순히 파일만 고치는 것이 아니라 `ABProfileManager.toc`, `Core.lua`, `Events.lua`, 관련 DB/Locale 키 사용처를 같이 점검해야 한다.

## 4. 중요한 파일

### 핵심

- `ABProfileManager/Core.lua`
- `ABProfileManager/DB.lua`
- `ABProfileManager/Events.lua`
- `ABProfileManager/Locale.lua`
- `ABProfileManager/Locale_Additions.lua`

### 드랍 / BIS / 시즌 최고기록

- `ABProfileManager/UI/ItemLevelOverlay.lua`
- `ABProfileManager/UI/BISOverlay.lua`
- `ABProfileManager/UI/MythicPlusRecordOverlay.lua`
- `ABProfileManager/Data/ItemLevelTable.lua`
- `ABProfileManager/Data/BISCatalog.lua`
- `ABProfileManager/Data/BISData.lua`
- `ABProfileManager/Data/BISData_Method.lua`
- `scripts/build_bis_catalog.py`
- `scripts/refresh_wowhead_bis.py`
- `scripts/refresh_wowhead_mplus_fallbacks.py`

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

- 먼저 `luaparser` 전체 파싱
- 그 다음 `git diff --check`
- 릴리스 작업이면 그 다음 패키징
- 마지막에 푸시, 필요 시 GitHub release

인게임 회귀 포인트:

- profession 카드 폭과 체크박스 레이아웃
- profession overlay 상세/요약/최소
- 전투메시지 설정 체크박스와 `위로 / 아래로 / 부채꼴` 버튼 선택 상태
- 지도 오버레이가 외부 월드맵에서만 표시되는지
- BIS 오버레이 드랍 출처 클릭 → 모험 안내서 loot 탭 랜딩
- BIS 필터 on/off와 visible rank 재계산
- `레이드 off + 쐐기만 on`에서 쐐기 행이 유지되는지
- `제작 + 티어만 on`에서 잘못된 랜딩이 없는지
- 드랍템 레벨 오버레이 우측 `나의 문장 / 나의 열쇠` 패널 수치 확인
- 시즌 최고기록 오버레이의 `평점 / 던전명` 위치와 줄바꿈 확인

## 6. 다음 작업자에게

- UI 퍼블리싱은 이미 사용자가 맞춘 상태를 선호하므로, overflow 보정이나 안전장치 위주로만 접근하는 편이 안전하다.
- BIS 시즌 변경 시에는 `DOC` seed를 출발점으로 삼되, 최종 truth는 외부 검증 결과와 itemID 확인이다.
- 일부 신규 던전 direct ID가 비어 있으므로, 사용자 제보가 오면 먼저 인게임 Encounter Journal 이름과 instanceID부터 확인하는 게 맞다.
