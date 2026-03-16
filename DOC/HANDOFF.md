# ABProfileManager Handoff

버전 기준: `v1.4.6`

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

## 사용자가 민감하게 보는 지점

1. 메인 UI 레이아웃은 크게 건드리지 말 것
2. profession 카드와 overlay의 정렬, 여백, 폰트는 이미 여러 번 맞춘 상태라 큰 재배치는 피할 것
3. typography 슬라이더는 전역 영향 범위가 넓으므로 font만 바꾸지 말고 overflow와 hitbox까지 같이 볼 것
4. 지도 오버레이는 가독성과 위치를 우선하며, 내부 지도에 뜨지 않게 유지할 것
5. 설정 패널과 지도 탭은 역할을 섞지 말 것
6. 고스트 드래그와 전투 중 대기열 상호작용은 항상 보수적으로 다룰 것

## 운영 메모

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

### 퀘스트 / 스탯 / 설정

- `ABProfileManager/Modules/QuestManager.lua`
- `ABProfileManager/UI/QuestPanel.lua`
- `ABProfileManager/UI/StatsOverlay.lua`
- `ABProfileManager/UI/ConfigPanel.lua`
- `ABProfileManager/UI/AddonSettingsPages.lua`

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

## 문서 위치

- 루트 사용자 문서: `README.md`
- 배포용 소개 텍스트: `ABProfileManager/ADDON_INTRO.txt`
- 기술 문서 색인: `DOC/README.md`
- 아키텍처: `DOC/ARCHITECTURE.md`
- 보안 검토: `DOC/SECURITY_REVIEW.md`
- 배포 절차: `DOC/RELEASE_PROCESS.md`

## 미완성 기능 — 추후 작업 예정

### 스탯 오버레이 쐐기(M+) 우선순위 모드

- **상태**: 설정 탭 체크박스 UI 숨김 처리 (v1.4.5). 기능 자체는 DB/Locale/ConfigPanel에 구현이 남아 있음.
- **이유**: 인게임 테스트에서 동작 불안정 확인. 탱커 6종 M+ 데이터는 정상이나 UI 토글이 일관되게 반응하지 않는 경우 발생.
- **재개 시 작업 위치**: `UI/ConfigPanel.lua` (`mythicPlusCheck:Hide()` 제거 후 다시 노출), `UI/StatsOverlay.lua` (`BuildSnapshot`의 `isMplus` 분기), `DB.lua` (`IsStatsOverlayMythicPlusMode`), `Data/StatPriorities.lua` (`ns.Data.StatPrioritiesMythicPlus`).
- **체크리스트**: 쐐기 모드 on/off 전환 후 overlay 즉시 갱신 여부, 특성 변경 시 isMplus 상태 유지 여부, 툴팁 타이틀 `[쐐기]`/`[레이드]` 정상 교체 여부.

### 경매장 현행 확장팩 필터 자동 선택

- **상태**: 설정 탭 체크박스 UI 숨김 처리 (v1.4.6). 기능 코드는 `Events.lua`에 유지. 동작 불가 확인.
- **디버깅 결과 (v1.4.5~v1.4.6)**:
  - 옥셔네이터(Auctionator) 애드온이 AH UI를 교체하고 있음. `AuctionHouseFrame` 아래 `AuctionatorAHFrame`이 실제 UI를 담당.
  - "현행 확장팩 전용" 텍스트는 WoW 보안 시스템에 의해 차단됨: `GetText()` 반환값이 "secret string value tainted by ABProfileManager" 오류 발생 → 텍스트 기반 탐색 불가.
  - `AuctionHouseFrame` 내 CheckButton을 `GetObjectType()` 기반으로 탐색하면 depth 2에 unnamed CheckButton 1개 존재 (필터 닫힌 상태에서는 [H] 숨김).
  - `/abpm ahdebug` 임시 명령어 3종 추가: `names` (프레임 이름 스캔), `checks` (CheckButton 탐색), `find <keyword>` (키워드 탐색, depth 12).
- **현재 구현 방식** (`Events.lua`):
  1. 필터 버튼("필터"/"Filter" 텍스트)을 찾아 클릭
  2. 0.35초 후 `AuctionHouseFrame` 하위에서 Auctionator 프레임을 제외한 visible CheckButton 탐색 → 클릭
  3. 클릭 후 0.15초 뒤 필터 버튼 재클릭으로 패널 닫기
- **미해결 문제**: 필터 버튼 클릭 후 해당 CheckButton이 실제로 IsVisible() = true가 되는지 확인 필요. 필터 패널이 열린 상태에서 `/abpm ahdebug checks`를 실행해 CheckButton이 [V] 상태가 되는지 검증하면 됨.
- **재개 시 작업 위치**: `Events.lua` (`findExpansionCheckButton`, `applyAuctionHouseExpansionFilter`), `UI/ConfigPanel.lua` (`auctionHouseFilterCheck:Hide()` 제거 후 복구).

## 다음 작업자에게

- TomTom waypoint는 현재 동작 설명까지 정리된 상태이므로, 회귀 제보가 오면 먼저 지역 진입 여부와 map lineage부터 확인하는 것이 맞다.
- UI 퍼블리싱은 이미 사용자가 맞춘 상태를 선호하므로, overflow 보정이나 안전장치 위주로만 접근하는 편이 안전하다.
