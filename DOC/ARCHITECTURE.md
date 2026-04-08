# ABProfileManager Architecture

버전 기준: `main (v1.5.9 기반)`

## 목적

`ABProfileManager`는 WoW Retail에서 다음 작업을 한 번에 처리하는 관리형 애드온입니다.

- 액션바 템플릿 저장, 비교, 부분 적용, 동기화
- 최근 1회 되돌리기
- 퀘스트 정리
- 전문기술 포인트 자동 추적
- 전투메시지 표출 방식 관리
- 캐릭터 스탯 오버레이
- 한밤(Midnight) 지도 오버레이
- 전체 typography 슬라이더
- 드랍템 레벨 참조 오버레이
- BIS 인던 드랍 정보 오버레이
- 파티찾기 시즌 최고기록 아이콘 오버레이

핵심 원칙:

- 기존 메인 UI 레이아웃은 쉽게 흔들지 않는다.
- 액션바와 profession 로직은 데이터 중심으로 유지한다.
- 지도 오버레이는 보수적인 맵 판정과 정적 좌표를 사용한다.
- 글자 크기 변경은 도메인별 typography 계층으로 통합한다.
- 파괴적 작업은 확인창과 입력 검증을 우선한다.

## 부트스트랩

- `ABProfileManager/Core.lua`
  - 네임스페이스 초기화
  - 시작 시 모듈 초기화
- `ABProfileManager/DB.lua`
  - SavedVariables 초기화
  - 공통 설정, UI 위치, character 데이터 관리
- `ABProfileManager/Events.lua`
  - `ADDON_LOADED`
  - `PLAYER_LOGIN`
  - `PLAYER_ENTERING_WORLD`
  - profession / quest / stats 갱신 이벤트 연결
- `ABProfileManager/Commands.lua`
  - `/abpm` 슬래시 명령 처리
- 현재 비활성/미완성 기능인 `MerchantHelper`, `MailHistory`, `WorldEventOverlay`, `WorldEventSchedule`는 repo에는 유지하지만 패키지 TOC 로드 목록에서는 제외한다.

## 주요 모듈

### 액션바

- `Modules/ActionBarScanner.lua`
  - 현재 액션바 상태 스캔
- `Modules/ActionBarApplier.lua`
  - 실제 적용, 비우기, 전투 중 대기열, 고스트 재시도
- `Modules/ProfileManager.lua`
  - 템플릿 저장, 삭제, 적용
- `Modules/TemplateSyncManager.lua`
  - 비교와 동기화
- `Modules/TemplateTransfer.lua`
  - 문자열 내보내기/가져오기
- `Modules/RangeCopyManager.lua`
  - 전체, 바, 선택 바, 슬롯 범위 해석
- `Modules/SlotMapper.lua`
  - 실제 수정 가능한 슬롯 매핑
- `Modules/UndoManager.lua`
  - 최근 1회 작업 복구
- `Modules/GhostManager.lua`
  - 누락 액션 고스트 표시

### profession / 지도 / 설정

- `Modules/ProfessionKnowledgeTracker.lua`
  - profession별 획득원 집계
  - 완료 퀘스트/숨은 퀘스트 기반 추적
  - 카드/오버레이/툴팁 데이터 제공
- `Modules/CombatTextManager.lua`
  - Midnight 최신 전투메시지 `_v2` CVar와 구형 이름 fallback을 함께 관리
- `Modules/TomTomBridge.lua`
  - TomTom 선택적 연동
  - 하란다르/공허폭풍 일부 1회성 보물은 해당 지역 진입 후 waypoint 생성
- `UI/ProfessionKnowledgeOverlay.lua`
  - 상단 요약은 문장형 안내와 정확한 주간 리셋 잔여 시간 표시를 사용
  - tooltip은 범례, 완료/미완료 색상, source별 요약 규칙, TomTom 안내를 함께 노출
- `UI/ConfigPanel.lua`
  - 일반 설정, typography 슬라이더, 개요, 전투메시지 표출 방식 설정
- `UI/MapPanel.lua`
  - 지도 오버레이 전용 탭
  - 지도 글자 크기 슬라이더와 카테고리 필터 제공

### 드랍 / BIS / 시즌 최고기록

- `UI/ItemLevelOverlay.lua`
  - 파티찾기(PVEFrame) 열릴 때 옆에 표시
  - 탭: 개요 / 쐐기 / 구렁 / 레이드 / 기타
  - 각 행: `단/난이도 | 클리어보상 | 드랍문장 | 위대한 금고`
  - 우측 고정 패널에 현재 문장 보유량과 `오늘의 풍요 4개 / 열쇠 파편 / 복원된 열쇠` 표시
  - 구렁 표 보조 행은 `보물지도 사용` 문구를 사용
  - 위치 저장 뒤 재오픈 시 저장 좌표를 우선 복원
  - `CREST_ID_BY_GRADE = { adv=3383, vet=3341, chmp=3343, hero=3345, myth=3347 }`
  - `DELVE_RESTORED_KEY_CURRENCY_ID = 3028`
- `UI/BISOverlay.lua`
  - 현재 캐릭터 클래스의 전 특성 탭과 부위별 BIS 리스트 렌더
  - `아이템명 / 드랍 출처 / 유형 / BIS 여부` 열 구성
  - 체크박스형 `쐐기 / 레이드 / 제작` 필터
  - `반지 / 장신구`는 상위 2개 공동 BIS 표시
  - 헤더에 `참고용, 실제 템은 직접 확인` 안내 문구 노출
  - 드랍 출처 클릭 시 가능한 경우 Encounter Journal loot 탭 랜딩
  - 제작 / 촉매 항목은 Encounter Journal 랜딩 대상에서 제외
  - 행 hover는 시즌 preview 기반 아이템 툴팁 경로 사용
  - 헤더 마우스 휠로 0.5~2.0배 스케일 조절
  - 위치 / 스케일 / 접기 상태를 저장하고 재오픈 시 복원
- `UI/MythicPlusRecordOverlay.lua`
  - `ChallengesFrame.DungeonIcons` 위에 `평점 + 던전명` 표시
  - 시간 라인은 사용하지 않음
  - 긴 한글 던전명은 별도 줄바꿈 규칙 적용
  - Utility 탭 체크박스로 on/off

## 데이터 계층

- `Data/Defaults.lua`
  - SavedVariables 기본값
  - BIS source filter 기본값은 `mythicplus/raid/crafted` 전부 on
- `Data/ProfessionKnowledge.lua`
  - profession별 획득원 정의
- `Data/ProfessionKnowledgeWaypoints.lua`
  - profession 1회성 보물 좌표
- `Data/SilvermoonMapData.lua`
  - 한밤(Midnight) 지도 라벨 정의
- `Data/StatPriorities.lua`
  - 특성별 일반 PvE 우선순위
- `Data/ItemLevelTable.lua`
  - 컨텐츠별 드랍 아이템 레벨 테이블
- `Data/BISData.lua`
  - Wowhead `Best Gear from Mythic+` 후보와 seed fallback을 합친 M+ 대체재 데이터
- `scripts/refresh_wowhead_bis.py`
  - Wowhead `current Overall BiS` 39 spec 데이터를 `Data/BISData_Method.lua`로 재생성
- `scripts/refresh_wowhead_mplus_fallbacks.py`
  - Wowhead M+ 추천 후보를 `Data/BISData.lua` fallback으로 재생성
- `Data/BISData_Method.lua`
  - Wowhead `current Overall BiS` 39 spec 데이터를 우선 적용
  - `Data/BISData.lua` fallback은 top BIS가 `mythicplus`가 아닌 슬롯에만 `대체재 / 2순위 / 3순위`로 뒤에 병합
  - slot + itemID 중복은 제거

## UI 계층

- `UI/MainWindow.lua`
  - 메인 프레임과 탭 전환
- `UI/ProfilePanel.lua`
  - 현재 캐릭터, 템플릿 목록, 템플릿 작업
- `UI/ActionBarPanel.lua`
  - 범위 선택, 비교, 동기화
- `UI/ProfessionPanel.lua`
  - profession 카드, 오버레이 설정, 재스캔
- `UI/MapPanel.lua`
  - 지도 탭, 포탈/평판상인 필터, 지도 글자 크기 조절
- `UI/QuestPanel.lua`
  - 퀘스트 후보 목록, 안전 정리, 전체 포기
- `UI/ConfigPanel.lua`
  - 메인 설정 탭
- `UI/AddonSettingsPages.lua`
  - 와우 `설정 > 애드온` 하위 카테고리
- `UI/Typography.lua`
  - 도메인별 글자 크기 보정과 tooltip 폰트 재적용
- `UI/StatsOverlay.lua`
  - 캐릭터 스탯 오버레이
- `UI/ProfessionKnowledgeOverlay.lua`
  - profession 포인트 오버레이
- `UI/SilvermoonMapOverlay.lua`
  - 한밤(Midnight) 지도 텍스트 오버레이
- `UI/ItemLevelOverlay.lua`
  - 드랍 아이템 레벨 참조 오버레이
- `UI/BISOverlay.lua`
  - BIS 인던 드랍 정보 오버레이
- `UI/MythicPlusRecordOverlay.lua`
  - 시즌 최고기록 아이콘 오버레이
- `UI/UtilityPanel.lua`
  - 편의기능 탭

## 저장 구조

### 계정 공통

- `global.settings`
  - 언어
  - 확인창
  - 디버그
  - 오버레이 표시 여부
  - BIS source filter / 잠금 상태
  - typography 도메인별 오프셋
  - 지도 라벨 카테고리 필터
  - 마우스 이동 자동 복구

### UI

- `ui`
  - 메인 창 위치
  - profession 오버레이 위치/모드/scale
  - stats 오버레이 위치/scale
  - itemLevelOverlay 위치/scale/currentTab/collapsed/anchorMode
  - bisOverlay 위치/scale/collapsed/anchorMode

### 캐릭터별

- profession 진행 상태
- 캐릭터 기본 정보
- 템플릿 작성 시 원본 캐릭터 메타데이터
- 사용자가 켠 전투메시지 표출 방식 상태

## 동작 흐름

### 로그인

1. `ADDON_LOADED`
2. DB 초기화
3. 모듈 초기화
4. `PLAYER_LOGIN`
5. profession/stats/UI refresh
6. 필요 시 `autoInteract` 복구
7. 필요 시 전투메시지 표출 방식 재적용

### profession 추적

1. profession key 확인
2. source 정의 로드
3. source별 objective 완료 상태 계산
4. weekly/one-time section 합계 계산
5. 카드/오버레이/툴팁용 파생 데이터 생성
6. loot/quest/bag 계열 이벤트 후 refresh를 다시 합쳐 반영
7. bag/loot 계열 이벤트 후 follow-up refresh를 한 번 더 실행

### 지도 오버레이

1. 현재 지도 mapID 확인
2. 내부 인스턴스/마이크로맵 차단
3. exact map과 제한된 alias만 조회
4. 라벨 줄바꿈/오프셋/카테고리 필터/지도 글자 크기 반영
5. WorldMap에 텍스트 오버레이 렌더

### BIS 오버레이

1. `EnsureFrame()`으로 프레임, 스크롤, spec/filter UI 생성
2. `EnsureTabs()`로 현재 클래스 spec icon 탭 생성
3. `RebuildContent()`로 선택된 specID의 BISData를 부위→아이템 순서로 렌더
4. `GET_ITEM_INFO_RECEIVED`는 전체 rebuild 대신 디바운스된 `RefreshVisibleItemRows()`만 실행
5. `Refresh()`는 anchor target이나 render signature가 바뀐 경우에만 full rebuild 수행
6. 드랍 출처 클릭 시 `openEncounterJournalForEntry()`로 Encounter Journal loot 탭 랜딩 시도
7. `반지 / 장신구`는 display-only 공동 BIS 규칙으로 상위 2개 배지를 유지

### 시즌 최고기록 오버레이

1. `ChallengesFrame.DungeonIcons` 아이콘 프레임 재사용
2. `ensureDisplay()`로 아이콘별 overlay fontstring 생성
3. `RefreshIcon()`에서 점수와 던전명을 계산해 하단 정렬
4. `formatDungeonDisplayName()`에서 긴 한글 던전명 강제 줄바꿈

## 성능 및 GC 최적화 패턴

### SilvermoonMapOverlay

- `LayoutPoints`는 월드맵 상호작용 시 burst refresh 동안 반복 호출되므로 모듈 레벨 재사용 버퍼를 유지한다.
- `_layoutPoints`, `_layoutEntries`, `_layoutPlaced`, `_layoutPlacedPool`, `_candidateBuf`, `_mapInfoCache` 등을 함수 내부로 옮기면 GC spike가 재발한다.
- 상시 polling 대신 `OnShow`, `SetMapID`, `CanvasScale/Zoom`, `MouseWheel`, `SizeChanged`에 맞춘 짧은 driver burst만 유지한다.
- size bucket이 변하지 않으면 `OnSizeChanged`가 다시 burst를 arm하지 않고, 안정된 layoutKey가 한 번 확인되면 driver를 즉시 내린다.

### StatsOverlay

- `BuildSnapshotSignature`는 모듈 레벨 `_snapshotParts` 재사용 버퍼를 사용한다.
- `BuildStateSignature`는 `_stateSignatureParts` 버퍼를 재사용하고, 고빈도 aura/stat 이벤트는 `Events.lua`에서 느린 throttle로 분리한다.
- 고빈도 aura/stat 이벤트에서는 raw state signature가 같으면 `BuildSnapshot()` 자체를 건너뛴다.

### BISOverlay

- item info 지연 수신 시 전체 컨텐츠를 다시 만들지 않는다.
- visible row만 갱신하고, anchor target이 바뀌지 않으면 `ClearAllPoints/SetPoint`를 스킵한다.
- Encounter Journal live scan은 Journal이 열린 상태나 직후에는 보수적으로 제한한다.

### ProfessionKnowledgeTracker / Overlay

- 완료 퀘스트 전체 스캔 결과가 직전과 같으면 `questCacheGeneration`과 evaluation cache를 다시 만들지 않는다.
- `ProfessionKnowledgeOverlay` tooltip 라인은 row refresh 시 선계산하지 않고 hover 시점에만 구성한다.

### Core / MainWindow refresh 경로

- `Core.lua`의 `ns:RefreshUI()`는 메인 창이 닫혀 있을 때 숨겨진 내부 탭 패널 refresh를 생략한다.
- `MainWindow.lua` 탭 전환은 전역 refresh 대신 현재 탭과 상태 영역만 갱신한다.

### QuestPanel

- `QUEST_LOG_UPDATE`는 `Events.lua`에서 0.15초 디바운스
- `QuestPanel.RefreshInternal`은 `IsVisible()` 가드 사용

## 안정성 메모

- profession/TomTom 연동은 메인 기능에 영향을 주지 않도록 선택 기능으로 유지한다.
- 지도 오버레이는 지원하지 않는 child/detail map에서 부모 지도 라벨을 억지로 보여주지 않는다.
- 와우 `설정 > 애드온`은 메인 창 재사용이 아니라 경량 패널만 사용한다.
- 대규모 UI 리디자인보다 현재 배치 유지와 overflow 방지 보정을 우선한다.
- BIS / ItemLevel / MythicPlusRecord 오버레이는 오류가 나도 메인 UI 전체를 깨뜨리지 않도록 보수적으로 감싼다.

## 현재 운영 메모

- TomTom 1회성 waypoint는 하란다르/공허폭풍 일부 보물에서 별도 지역 지도 컨텍스트를 사용하므로, 해당 지역에 들어간 뒤 생성된다.
- 지도 좌표는 패치 후 수동 보정이 필요할 수 있다.
- 제작 주문, catch-up 같은 profession 예외 획득원은 아직 별도 자동 집계하지 않는다.
- BIS 랜딩 direct ID 확인값:
  - `공결탑 제나스 = tier 13 / instanceID 1314`
  - `알게타르 대학 = instanceID 2526`
- `마이사라 동굴`, `윈드러너 첨탑`은 Encounter Journal instanceID 추가 확인이 필요하다.
