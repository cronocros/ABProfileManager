# ABProfileManager Architecture

버전 기준: `main (v1.7.0 기반)`

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
- BIS 추천 장비 카탈로그 오버레이
- 파티찾기 시즌 최고기록 아이콘 오버레이

핵심 원칙:

- 기존 메인 UI 레이아웃은 쉽게 흔들지 않는다.
- 액션바와 profession 로직은 데이터 중심으로 유지한다.
- 지도 오버레이는 보수적인 맵 판정과 정적 좌표를 사용한다.
- 글자 크기 변경은 도메인별 typography 계층으로 통합한다.
- 파괴적 작업은 확인창과 입력 검증을 우선한다.
- BIS 런타임은 생성된 정적 카탈로그만 읽고, 열기 시점의 병합/정규화/웹 조회를 금지한다.

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
  - 현재 캐릭터 클래스의 전 특성 탭과 부위별 추천 장비 카탈로그 렌더
  - 정적 `Data/BISCatalog.lua`를 읽어 slot별 후보를 구성
  - 필터는 `mythicplus / raid / crafted / tier` 4개 기본 on
  - 필터 적용 후 살아남은 후보를 기준으로 visible rank를 다시 계산
  - 첫 2개는 `1순위 / 2순위`, 이후는 `3순위+` 배지로 표기
  - `아이템명 / 드랍 출처 / 유형 / 우선순위` 중심 열 구성
  - `mythicplus`, `raid`만 가능한 경우 Encounter Journal loot 탭 랜딩
  - `crafted`, `tier`는 Encounter Journal 랜딩 대상에서 제외
  - 행 hover는 시즌 preview 기반 아이템 툴팁 경로 사용
  - `GET_ITEM_INFO_RECEIVED`는 전체 rebuild 대신 visible row patch만 수행
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
  - BIS source filter 기본값은 `mythicplus/raid/crafted/tier` 전부 on
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
- `Data/BISCatalog.lua`
  - 런타임에서 직접 읽는 단일 BIS 카탈로그
  - row별 `specID, slot, itemID, nameKoKR, nameEnUS, sourceGroup, sourceLabel, overallRank, sourceRank` 보관
  - `dungeon / boss / profession / catalyst` 등 source detail과 locale별 표기를 함께 저장
- `Data/BISData_Method.lua`
  - Wowhead `current Overall BiS` seed 입력
- `Data/BISData.lua`
  - Wowhead `Best Gear from Mythic+` + seed fallback 입력
- `scripts/refresh_wowhead_bis.py`
  - Wowhead `current Overall BiS` 40 spec 데이터를 `Data/BISData_Method.lua`로 재생성
- `scripts/refresh_wowhead_mplus_fallbacks.py`
  - Wowhead M+ 추천 후보를 `Data/BISData.lua`로 재생성
- `scripts/build_bis_catalog.py`
  - `DOC` seed와 Wowhead/Wago DB2 검증 데이터를 합쳐 `Data/BISCatalog.lua`를 생성
  - dungeon/source alias canonicalization, locale 누수 검사, itemID 검증을 포함

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
  - BIS 추천 장비 카탈로그 오버레이
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

## BIS 카탈로그 흐름

1. `scripts/refresh_wowhead_bis.py`
2. `scripts/refresh_wowhead_mplus_fallbacks.py`
3. `scripts/build_bis_catalog.py`
4. 생성 결과 `Data/BISCatalog.lua`를 패키지에 포함
5. 게임 런타임에서는 `UI/BISOverlay.lua`가 `Data/BISCatalog.lua`만 읽음

런타임 규칙:

- open/spec/filter 전환은 단일 rebuild 경로를 사용
- slot grouping과 정렬 키는 생성 시점에 최대한 고정
- locale 선택은 row에 저장된 `nameKoKR/nameEnUS`, `displaySourceKoKR/displaySourceEnUS`만 사용
- `GET_ITEM_INFO_RECEIVED`는 icon/quality/item hyperlink 보정이 필요한 visible row만 patch

## 회귀 포인트

- BIS 필터 on/off 후 visible rank가 기대대로 다시 계산되는지
- `레이드 off + 쐐기만 on`에서 쐐기 드랍템과 인던명이 남는지
- `제작 + 티어만 on`에서 Encounter Journal 잘못 랜딩이 없는지
- `koKR`에서 영어 누수, `enUS`에서 한글 누수가 없는지
- 스크롤 thumb, 마지막 열 가림, 저장 위치/스케일, 접힘 상태 복원이 유지되는지
