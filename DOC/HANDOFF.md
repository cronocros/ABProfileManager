# ABProfileManager Handoff

버전 기준: `main (v1.5.9 기반)`

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
- BIS 인던 드랍 정보 오버레이
- 파티찾기 시즌 최고기록 아이콘 오버레이
- 블리자드 기본 UI 창 이동 자유화
- 편의기능 탭 통합

## 0. v1.5.9 오버레이 / BIS / CPU 메모

- `Data/BISData_Method.lua`는 이제 Wowhead `current Overall BiS` 39 spec 데이터를 먼저 넣고, 기존 `Data/BISData.lua` 수기 던전 데이터를 같은 슬롯의 fallback `대체재 / 2순위 / 3순위`로 뒤에 병합한다.
- 단, 수기 던전 fallback은 top BIS가 `mythicplus`가 아닌 슬롯에만 붙인다.
- `UI/BISOverlay.lua`는 `반지 / 장신구`를 상위 2개 공동 BIS로 표시한다.
- `UI/BISOverlay.lua`는 `GET_ITEM_INFO_RECEIVED`마다 전체 리스트를 다시 그리지 않고 `RefreshVisibleItemRows()`만 태운다. 깜빡임 회귀가 나오면 `scheduleRebuild()`, `RefreshVisibleItemRows()`, `Refresh()`의 render signature 분기를 먼저 본다.
- BIS source filter 기본값은 `mythicplus / raid / crafted` 전부 on이고, 예전 `쐐기만 on` 저장값은 DB migration으로 1회 승격된다.
- BIS 필터 버튼은 체크박스형 compact UI다. 드루이드 4특성처럼 헤더가 빡빡한 클래스 레이아웃 기준으로 맞춘 상태라 폭을 크게 다시 키우면 겹침이 쉽게 재발한다.
- BIS 헤더에는 `참고용, 실제 템은 직접 확인` 안내가 들어간다.
- BIS 아이템 hover 툴팁은 시즌 preview 경로로 다시 연결됐다. hover 회귀가 나오면 `showSeasonItemTooltip()`, `tooltipRegion` mouse script, preview validation 분기를 같이 본다.
- BIS 랜딩은 드랍 출처 클릭 기준이다. 제작과 촉매 항목은 Encounter Journal 랜딩 대상이 아니다.
- BIS 오버레이는 위치 / scale / collapsed / anchorMode를 저장한다. 사용자가 한 번 드래그하면 이후 재오픈은 저장 좌표를 우선한다.
- 던전명 direct 보정:
  - `공결탑 제나스 = tier 13 / instanceID 1314`
  - 사용자 인게임 출력에서 `tier 12 / instanceID 1316` 후보도 확인됨
  - `알게타르 대학 = instanceID 2526`
- `공결점 제나스`는 잘못된 한글명이었고, 현재 표시/랜딩 기준은 `공결탑 제나스`다.
- `알게타르 아카데미`는 현재 한국어 표기상 `알게타르 대학` alias를 같이 쓴다.
- `정기 주술사(262)`는 이전 누락 항목이었고, 지금은 Wowhead 기준으로 반영되어 있다.
- `UI/MythicPlusRecordOverlay.lua`는 이제 `평점 + 던전명`만 표시한다. 시간 라인은 사용하지 않는다.
- 긴 한글 던전명은 강제 줄바꿈 override를 사용한다.
- `ABProfileManager.toc`는 현재 비활성/미완성 상태인 `WorldEventSchedule`, `MerchantHelper`, `MailHistory`, `WorldEventOverlay`를 런타임 로드 대상에서 제외한다. 소스 파일은 저장소에 남아 있지만 메모리 절감을 위해 게임 내에서는 불러오지 않는다.
- `UI/ItemLevelOverlay.lua`는 `currentTab + avgIlvl + language` 시그니처가 바뀔 때만 본문 표를 다시 구성한다. `CURRENCY_DISPLAY_UPDATE` 류의 잦은 이벤트에서는 우측 패널만 갱신하고, 풍요 구렁 이름 스캔은 캐시 후 `ACTIVE_DELVE_DATA_UPDATE`, `AREA_POIS_UPDATED`에서만 무효화한다.
- `UI/ItemLevelOverlay.lua`는 사용자가 드래그한 뒤 `anchorMode = overlay`를 저장하고, 닫았다가 다시 열어도 저장 위치를 우선 복원한다.
- 구렁 탭 보조 문구는 `보물지도 사용`으로 바뀌었다.
- `Modules/ProfessionKnowledgeTracker.lua`는 profession 정의와 현재 보유 profession 목록을 캐시한다. `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_SPECIALIZATION_CHANGED`, `SKILL_LINES_CHANGED`에서만 profession 목록 캐시를 무효화한다.
- `UI/ProfessionKnowledgeOverlay.lua`는 profession hover 툴팁을 매 refresh마다 전부 만들지 않고, 실제 hover 시점에만 지연 생성한다.
- `UI/ProfessionKnowledgeOverlay.lua`와 `UI/StatsOverlay.lua`는 마우스 휠 scale 저장을 지원한다.
- `Core.lua`의 `RefreshUI()`는 이제 메인 창이 닫혀 있을 때 내부 탭 패널 전체를 refresh하지 않는다. 메인 창 탭 전환도 현재 탭만 refresh하는 경로로 바뀌었으므로, 패널 stale 제보가 오면 `Core.lua`, `UI/MainWindow.lua`를 함께 본다.
- 상시 CPU 점유 원인으로는 `StatsOverlay`와 `SilvermoonMapOverlay`가 1순위였다.
  - `StatsOverlay`는 raw state signature가 같으면 `BuildSnapshot()`을 생략한다.
  - `SilvermoonMapOverlay`는 상시 0.5초 polling 대신 월드맵 상호작용 시점의 짧은 burst refresh만 유지한다.
  - `Events.lua`의 `PLAYER_SPECIALIZATION_CHANGED`, `SKILL_LINES_CHANGED`는 전역 `ns:RefreshUI()` 대신 관련 UI만 부분 갱신한다.

## 1. 회귀 민감 메모

### BIS 인던 드랍 정보 오버레이

- `UI/BISOverlay.lua`는 폭/열 간격/스크롤 영역 민감도가 높다. 열 폭만 조정하지 말고 실제 스크롤 thumb와 마지막 열 가림 여부까지 같이 확인해야 한다.
- `sourceType`를 그대로 믿지 않고 `sourceLabel`도 함께 다시 해석한다. 레이드 only인데 쐐기 행이 남는 회귀가 나면 이 재분류 경로를 먼저 본다.
- Encounter Journal live scan은 Journal이 열려 있는 동안 보수적으로 제한한다. 다시 무리하게 live preview를 돌리면 모험 안내서 내용이 사라지거나 랜딩 직후 흔들리는 회귀가 난다.
- 제작 / 촉매는 랜딩하지 않는다. 이 경로를 건드릴 때는 `hasRaidMetaLabel()`과 crafted/sourceType 분기를 같이 본다.
- 현재 unresolved direct ID:
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
  - `공결탑 제나스`
  - `사론의 구덩이`
  - `마법학자의 정원`
  - `마이사라 동굴`
  - `알케타르 대학`

### BlizzardFrameManager / 지도

- `SetUserPlaced(true)`는 반드시 `uiPanel=true` 프레임에만 적용할 것. WorldMapFrame에 적용 시 오른쪽 퀘스트 목록 패널이 숨는다.
- 지도 오버레이는 child/detail map에서 부모 라벨을 억지로 보여주지 않는 현재 기준을 유지하는 편이 안전하다.

## 2. 운영 메모

### profession / quest refresh

- profession/quest refresh는 보호 경로를 거친다.
- `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED` 뒤 follow-up refresh가 들어간다.
- `Modules/ProfessionKnowledgeTracker.lua`는 완료 퀘스트 스냅샷이 실제로 바뀐 경우에만 `questCacheGeneration`과 요약 캐시를 무효화한다.
- `UI/ProfessionKnowledgeOverlay.lua` tooltip 라인은 refresh 때 미리 만들지 않고 hover 시점에만 계산한다.
- 시체 채집/보물 채집 관련 제보가 오면 `Events.lua`, `UI/ProfessionKnowledgeOverlay.lua`, `UI/ProfessionPanel.lua`, `UI/QuestPanel.lua`를 먼저 본다.
- `ProfessionKnowledgeTracker:RefreshQuestCache()`는 completed quest 집합이 실제로 바뀐 경우에만 generation/cache를 올린다. profession 툴팁/요약 리빌드가 괜히 반복되면 이 경로를 먼저 본다.

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
- 예전처럼 `EJ_GetCurrentInstance()`를 쓰면 안 된다. 현 클라이언트에서는 제거된 API다.
- 인게임 확인 시 `EJ_GetInstanceByIndex()` 기반 매크로나 직접 Encounter Journal 출력값을 기준으로 확인하는 편이 안전하다.

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
- `ABProfileManager/Data/BISData.lua`
- `ABProfileManager/Data/BISData_Method.lua`

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
- BIS 필터 on/off와 열 가림 여부
- 드랍템 레벨 오버레이 우측 `나의 문장` / `나의 열쇠` 패널 수치 확인
- 시즌 최고기록 오버레이의 `평점 / 던전명` 위치와 줄바꿈 확인

## 6. 다음 작업자에게

- UI 퍼블리싱은 이미 사용자가 맞춘 상태를 선호하므로, overflow 보정이나 안전장치 위주로만 접근하는 편이 안전하다.
- BIS 데이터는 Wowhead `current Overall BiS`와 수기 fallback을 함께 쓰므로, 시즌 변경 시 source 던전 / slot / itemID / sourceType을 같이 재검증해야 한다.
- 일부 신규 던전 direct ID가 비어 있으므로, 사용자 제보가 오면 먼저 인게임 Encounter Journal 이름과 instanceID부터 확인하는 게 맞다.
