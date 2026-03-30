# ABProfileManager Handoff

버전 기준: `main (v1.5.4 기반)`

## 현재 상태

프로젝트는 실제 인게임 사용 기준으로 유지되는 WoW Retail 애드온이다. 문서 세트는 루트 `README.md`를 사용자 안내로, `DOC` 아래 문서를 기술/운영 문서로 정리한 상태다.

현재 기준 핵심 기능:

- 액션바 템플릿 저장, 적용, 비교, 부분 적용, 동기화, 최근 1회 되돌리기
- 전문기술 포인트 자동 추적 카드와 오버레이
- Midnight 전투메시지 표출 방식 관리
- 퀘스트 정리와 퀘스트 ID 상세 열기
- 캐릭터 스탯 오버레이
- 한밤(Midnight) 지도 오버레이
- 지도 전용 탭과 typography 슬라이더
- 와우 `설정 > 애드온` 경량 하위 페이지
- 드랍템 레벨정보 오버레이 (쐐기/레이드/구렁 탭, 파티찾기창 연동, 4열 표 + 우측 `나의 문장` 패널)
- 블리자드 기본 UI 창 이동 자유화 (BlizzardFrameManager)
- 편의기능 탭 (UtilityPanel) 통합
- BIS 인던 드랍 정보 오버레이 (전 클래스/특성, 던전 클릭 → 모험 안내서)
- **[비활성]** 월드이벤트 오버레이 — Midnight 이벤트 스케줄 미확정, 자동감지 미동작
- **[비활성]** 상점 도안/장난감 음영처리 (MerchantHelper) — Midnight spellID API 불일치
- **[비활성]** 우편 수신자 히스토리 (MailHistory) — WoW taint 문제로 자동완성 미동작

## 사용자가 민감하게 보는 지점

1. 메인 UI 레이아웃은 크게 건드리지 말 것
2. profession 카드와 overlay의 정렬, 여백, 폰트는 이미 여러 번 맞춘 상태라 큰 재배치는 피할 것
3. typography 슬라이더는 전역 영향 범위가 넓으므로 font만 바꾸지 말고 overflow와 hitbox까지 같이 볼 것
4. 지도 오버레이는 가독성과 위치를 우선하며, 내부 지도에 뜨지 않게 유지할 것
5. 설정 패널과 지도 탭은 역할을 섞지 말 것
6. 고스트 드래그와 전투 중 대기열 상호작용은 항상 보수적으로 다룰 것

## 운영 메모

### 0. v1.5.4 QA 반영 메모

- BIS 시즌 툴팁의 정확한 현재 시즌 스탯은 `itemID`만으로는 보장되지 않는다. `UI/BISOverlay.lua`는 Encounter Journal preview hyperlink를 얻을 수 있을 때만 그 링크로 툴팁을 열도록 정리했다.
- Encounter Journal이 시즌 preview link를 주지 못하는 던전/아이템은 base item tooltip로 떨어질 수 있으므로, 이 경로를 다시 건드릴 때는 `getPreviewMythicPlusLootLink()`와 `showSeasonItemTooltip()`를 같이 본다.
- 드랍템 레벨 오버레이와 BIS 오버레이는 폭/간격 민감도가 높다. 컬럼 상수만 바꿀 게 아니라 실제 한글 문자열 잘림과 탭/스크롤 영역까지 같이 봐야 한다.

### 1. TomTom waypoint 지역 컨텍스트

- profession 오버레이 `1회성` 우클릭 panel은 현재 정상 동작한다
- 하란다르와 공허폭풍 일부 보물은 별도 지역 지도라서, 해당 지역에 들어가면 waypoint가 생성된다

운영 메모:

- TomTom 관련 제보가 오면 다른 지역에서 테스트한 것인지 먼저 확인한다
- 추가 수정이 필요하면 `Modules/TomTomBridge.lua`와 `UI/ProfessionKnowledgeOverlay.lua`를 같이 본다
- mapID 제한과 현재 플레이어 지도 lineage를 먼저 확인한다

### 2. profession refresh 안정화

- profession/quest refresh는 이제 보호 경로를 거친다
- 채집/루팅 직후 연속 이벤트는 짧게 합쳐 처리한다
- `LOOT_CLOSED` 이후에도 profession refresh를 다시 확인해 1회성 완료 반영 누락 가능성을 줄였다
- `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED` 뒤 follow-up refresh를 추가로 태워 드랍/논문/1회성 누락 가능성을 더 줄였다
- 최신 사용자 피드백 기준으로 구렁/던전 시체 약초채집 blank Lua 오류는 재현되지 않았다

운영 메모:

- 시체 채집/보물 채집 관련 제보가 오면 `Events.lua`, `UI/ProfessionKnowledgeOverlay.lua`, `UI/ProfessionPanel.lua`, `UI/QuestPanel.lua`를 먼저 본다
- 오류 원문이 필요하면 `/abpm debug on`과 기본 Lua 오류 표시를 같이 켜고 본다

### 3. 전투메시지 표출 방식 관리

- Midnight 최신 클라이언트는 일부 전투메시지 옵션이 기본 UI에서 잘 보이지 않는다
- 현재는 `CombatTextManager`가 `_v2` CVar를 우선 사용하고, 없으면 구형 이름으로 fallback 한다
- 현재는 기본 WoW 전투메시지 on/off는 건드리지 않고, `위로 / 아래로 / 부채꼴` 표출 방식과 방향성 분산만 다시 적용한다
- 사용자가 설정 탭에서 항목을 건드리면 해당 표출 방식을 저장하고 바로 적용한다
- 로그인/월드 진입 직후에는 짧은 retry까지 함께 태워 적용 누락을 줄인다
- `전투메시지 표출 방식 관리`를 끄면 이후 로그인/월드 진입 때 강제 재적용하지 않는다

운영 메모:

- 전투메시지 모드 관련 제보가 오면 `Modules/CombatTextManager.lua`, `UI/ConfigPanel.lua`, `DB.lua`, `Events.lua`를 같이 본다
- 모드 값은 `1=위로`, `2=아래로`, `3=부채꼴` 기준으로 저장한다

### 4. 지도 좌표 보정

- 정적 좌표 기반이라 패치 후 drift가 생길 수 있다
- 보정은 `Data/SilvermoonMapData.lua`와 `UI/SilvermoonMapOverlay.lua`를 같이 수정한다
- 외부 지역 포탈 좌표는 실버문보다 검증 신뢰도가 낮으므로 사용자 제보가 들어오면 우선 재확인한다
- 지원하지 않는 child/detail map은 부모 지도 라벨을 억지로 따라오지 않게 숨기는 것이 현재 기준이다

### 5. BIS 인던 드랍 정보 오버레이

- `UI/BISOverlay.lua` — 전 클래스/특성 BIS 아이템 목록, 스펙 탭, 부위별 섹션 렌더
- `Data/BISData.lua` — 수기 specID 키, { dungeon, boss, itemID, slot, note } 배열
- `Data/BISData_Method.lua` — Method.gg 기반 시즌 1 던전 BIS 보강 데이터, itemID 기준 병합
- **아이템 행 클릭 → 모험 안내서 자동 열기**: `DUNGEON_EJ_IDS` 테이블에 instanceID 매핑
  - returning 던전(마법학자의 정원/알게타르/삼두정/하늘탑/사론의 구덩이): instanceID 확인값
  - Midnight 신규 던전(마이사라 동굴/공결점 제나스/윈드러너 첨탑): instanceID 미확인 → nil (EJ는 열리나 특정 던전으로 이동 안 됨)
- **아이템 툴팁**: 베이스 아이템 툴팁 대신 한밤 시즌 1 던전 트랙 요약을 커스텀 표시
- **마우스 휠 스케일**: 헤더 영역(스크롤프레임 밖) 스크롤 시 프레임 0.5~2.0배 스케일 조절
- **잠금/접기**: 잠금은 UtilityPanel bisLockCheck, 접기는 오버레이 우상단 −/+ 버튼

### 6. 드랍템 레벨 오버레이 — 4열 표 + 우측 `나의 문장` 패널

- `UI/ItemLevelOverlay.lua` — `단 / 클리어보상 / 드랍문장 / 위대한 금고` 4열 레이아웃 + 우측 고정 문장 패널
- 우측 패널에 현재 문장 보유량을 한 번만 통합 표시
- 쐐기 헤더 옆에 챔피언 / 영웅 / 신화 최고 강화 레벨 요약 표시
- `C_CurrencyInfo.GetCurrencyInfo(id)` 로 현재 문장 보유량 표시
- 통화 ID는 `CREST_ID_BY_GRADE` 테이블로 관리
- **통화 ID (Midnight 시즌 1)**:
  - 영웅 새벽 문장 = 3345 (연구 확인)
  - 나머지(모험가/노련가/챔피언/신화): 3342~3346 순서 추정 → 인게임 검증 필요
  - ID가 틀리면 수치가 "?" 로 표시됨 — `CREST_ID_BY_GRADE` 테이블에서 수정

### 7. BlizzardFrameManager (블리자드 창 이동)

- `Modules/BlizzardFrameManager.lua` — MANAGED_FRAMES 목록의 각 프레임에 SetMovable + OnDragStop 저장 + OnShow 복원
- `UpdateUIPanelPositions` hooksecurefunc로 탭 전환 시 깜박임 없이 복원
- `lazyAddon` 패턴: ADDON_LOADED 이벤트 → 지연 로드 프레임(전문기술, 탤런트 등)에 적용
- **주의**: `QuestFrame`(NPC 퀘스트 대화창)은 MANAGED_FRAMES에 넣지 말 것 — 퀘스트 목록창 소실 원인
- **주의**: `SetUserPlaced(true)`는 반드시 `uiPanel=true` 프레임에만 적용할 것. WorldMapFrame 등 비UIPanel 프레임에 적용 시 WoW가 compact/customized 모드로 인식해 오른쪽 퀘스트 목록 패널을 숨김.

### 8. GC 최적화 (SilvermoonMapOverlay / StatsOverlay / QuestPanel)

- **SilvermoonMapOverlay**: `LayoutPoints` hot path가 호출당 0개 신규 테이블 생성으로 최적화됨
  - 모듈 레벨 재사용 버퍼: `_layoutPoints`, `_layoutEntries`, `_layoutPlaced`, `_layoutPlacedPool`, `_scoreRect`, `_bestRect`, `_candidateBuf[16]`
  - `_mapInfoCache`: `C_Map.GetMapInfo` pcall 결과 세션 영구 캐시 (mapID → result)
- **StatsOverlay**: `BuildSnapshotSignature` — 모듈 레벨 `_snapshotParts` 재사용 버퍼
- **QuestPanel**: `RefreshInternal`에 `IsVisible()` 가드 추가
- **Events.lua**: `QUEST_LOG_UPDATE` 0.15초 디바운스 추가

### 9. MerchantHelper / MailHistory / WorldEventOverlay (비활성)

- 세 모듈 모두 `Core.lua` 초기화 목록과 `Events.lua` 이벤트 등록에서 주석 처리
- 파일은 유지 (미래 재활성화 대비)
- 백그라운드 활동 없음: 이벤트 미등록, 프레임 미생성, OnUpdate 미실행
- **재활성화 시**: `Core.lua` 주석 해제 + `Events.lua` 주석 해제

### 10. 디버그 로그 버퍼 & `/abpm log` 명령

- `Utils.lua` — `debugLogBuffer` (최대 200줄), `Utils.GetDebugLog()`, `Utils.ClearDebugLog()`
- `/abpm log` 명령 → 팝업 EditBox에 로그 출력, 복사 가능

## 중요한 파일

### 핵심

- `ABProfileManager/Core.lua`
- `ABProfileManager/DB.lua`
- `ABProfileManager/Events.lua`
- `ABProfileManager/Locale.lua`
- `ABProfileManager/Locale_Additions.lua`

### 액션바

- `ABProfileManager/Modules/ActionBarScanner.lua`
- `ABProfileManager/Modules/ActionBarApplier.lua`
- `ABProfileManager/Modules/ProfileManager.lua`
- `ABProfileManager/Modules/TemplateSyncManager.lua`
- `ABProfileManager/Modules/TemplateTransfer.lua`
- `ABProfileManager/Modules/UndoManager.lua`
- `ABProfileManager/Modules/GhostManager.lua`

### profession / 지도

- `ABProfileManager/Modules/ProfessionKnowledgeTracker.lua`
- `ABProfileManager/Modules/TomTomBridge.lua`
- `ABProfileManager/Modules/CombatTextManager.lua`
- `ABProfileManager/Data/ProfessionKnowledge.lua`
- `ABProfileManager/Data/ProfessionKnowledgeWaypoints.lua`
- `ABProfileManager/Data/SilvermoonMapData.lua`
- `ABProfileManager/UI/ProfessionPanel.lua`
- `ABProfileManager/UI/ProfessionKnowledgeOverlay.lua`
- `ABProfileManager/UI/SilvermoonMapOverlay.lua`
- `ABProfileManager/UI/MapPanel.lua`
- `ABProfileManager/UI/Typography.lua`

### 퀘스트 / 스탯 / 설정 / 편의기능

- `ABProfileManager/Modules/QuestManager.lua`
- `ABProfileManager/UI/QuestPanel.lua`
- `ABProfileManager/UI/StatsOverlay.lua`
- `ABProfileManager/UI/ConfigPanel.lua`
- `ABProfileManager/UI/AddonSettingsPages.lua`
- `ABProfileManager/UI/UtilityPanel.lua`

### 드랍/아이템레벨/BIS 오버레이

- `ABProfileManager/Modules/BlizzardFrameManager.lua` — 블리자드 UI 창 이동/복원
- `ABProfileManager/UI/ItemLevelOverlay.lua` — 드랍템 레벨 참조 오버레이 (파티찾기창 연동, 4열 표 + 우측 `나의 문장` 패널)
- `ABProfileManager/Data/ItemLevelTable.lua` — 쐐기/레이드/구렁 ilvl 데이터 (Midnight 시즌 1)
- `ABProfileManager/UI/BISOverlay.lua` — BIS 인던 드랍 정보 오버레이 (전 클래스/특성)
- `ABProfileManager/Data/BISData.lua` — specID 키 BIS 아이템 목록
- `ABProfileManager/Data/BISData_Method.lua` — Method.gg 기반 BIS 보강 데이터

### 비활성 모듈 (코드 유지, 초기화 비활성)

- `ABProfileManager/Modules/MerchantHelper.lua` — 상점 도안/장난감 음영 (Midnight API 불일치)
- `ABProfileManager/Modules/MailHistory.lua` — 우편 수신자 히스토리 (WoW taint)
- `ABProfileManager/UI/WorldEventOverlay.lua` — 월드이벤트 오버레이 (스케줄 미확정)
- `ABProfileManager/Data/WorldEventSchedule.lua` — Midnight 이벤트 스케줄 데이터

## 검증 습관

- 먼저 `luaparser` 전체 파싱
- 그 다음 `git diff --check`
- 릴리스 작업이면 그 다음 패키징
- 마지막에 푸시, 필요할 때만 릴리스

인게임 회귀 포인트:

- profession 카드 폭과 체크박스 레이아웃
- profession overlay 상세/요약/최소
- 전투메시지 설정 체크박스와 `위로 / 아래로 / 부채꼴` 버튼 선택 상태
- 지도 오버레이 외부 월드맵만 표시되는지
- 퀘스트 ID 링크 클릭
- 스탯 overlay drag/hitbox
- BIS 오버레이 아이템 행 클릭 → 모험 안내서 열림 확인
- 드랍템 레벨 오버레이 우측 `나의 문장` 패널의 수치/"?" 여부 확인

## 미완성 기능 — 추후 작업 예정

### 스탯 오버레이 쐐기(M+) 우선순위 모드

- **상태**: 설정 탭 체크박스 UI 숨김 처리 (v1.4.5). 기능 자체는 DB/Locale/ConfigPanel에 구현이 남아 있음.
- **이유**: 인게임 테스트에서 동작 불안정 확인. 탱커 6종 M+ 데이터는 정상이나 UI 토글이 일관되게 반응하지 않는 경우 발생.
- **재개 시 작업 위치**: `UI/ConfigPanel.lua` (`mythicPlusCheck:Hide()` 제거 후 다시 노출), `UI/StatsOverlay.lua` (`BuildSnapshot`의 `isMplus` 분기), `DB.lua` (`IsStatsOverlayMythicPlusMode`), `Data/StatPriorities.lua` (`ns.Data.StatPrioritiesMythicPlus`).

### BIS 오버레이 Midnight 신규 던전 EJ instanceID

- 마이사라 동굴 / 공결점 제나스 / 윈드러너 첨탑의 EJ instanceID 미확인
- `UI/BISOverlay.lua` 상단 `DUNGEON_EJ_IDS` 테이블에 nil 로 마킹됨
- 인게임에서 `/dump EJ_GetCurrentInstance()` 또는 Wowhead에서 확인 후 채워 넣으면 됨

### 드랍 문장 통화 ID 검증

- `UI/ItemLevelOverlay.lua`의 `CREST_ID_BY_GRADE` 테이블
- 영웅 새벽 문장(3345) 외 나머지 4종은 연속값 추정 → 인게임 `/dump C_CurrencyInfo.GetCurrencyInfo(3342)` 등으로 검증 필요

### 경매장 현행 확장팩 필터 자동 선택

- **상태**: 설정 탭 체크박스 UI 숨김 처리 (v1.4.6). WoW 보안 시스템 taint 문제로 동작 불가.

## 문서 위치

- 루트 사용자 문서: `README.md`
- 배포용 소개 텍스트: `ABProfileManager/ADDON_INTRO.txt`
- 기술 문서 색인: `DOC/README.md`
- 아키텍처: `DOC/ARCHITECTURE.md`
- 보안 검토: `DOC/SECURITY_REVIEW.md`
- 배포 절차: `DOC/RELEASE_PROCESS.md`

## 다음 작업자에게

- TomTom waypoint는 현재 동작 설명까지 정리된 상태이므로, 회귀 제보가 오면 먼저 지역 진입 여부와 map lineage부터 확인하는 것이 맞다.
- UI 퍼블리싱은 이미 사용자가 맞춘 상태를 선호하므로, overflow 보정이나 안전장치 위주로만 접근하는 편이 안전하다.
- BIS 데이터는 수기 데이터와 Method.gg 보강 데이터를 함께 사용하므로, 시즌 변경 시 source 던전/slot/itemID를 같이 재검증해야 한다.
- 문장 컬럼의 통화 ID는 추정값 포함이므로 인게임에서 "?" 표시 시 통화 ID를 수정해야 한다.
