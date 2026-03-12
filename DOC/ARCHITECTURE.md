# ABProfileManager Architecture

버전 기준: `v1.3.12`

## 목적

`ABProfileManager`는 WoW Retail에서 다음 작업을 한 번에 처리하는 관리형 애드온입니다.

- 액션바 템플릿 저장, 비교, 부분 적용, 동기화
- 최근 1회 되돌리기
- 퀘스트 정리
- 전문기술 포인트 자동 추적
- 캐릭터 스탯 오버레이
- 한밤(Midnight) 지도 오버레이

핵심 원칙:

- 기존 메인 UI 레이아웃은 쉽게 흔들지 않는다.
- 액션바와 profession 로직은 데이터 중심으로 유지한다.
- 지도 오버레이는 보수적인 맵 판정과 정적 좌표를 사용한다.
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

### 퀘스트

- `Modules/QuestManager.lua`
  - 안전 정리 대상 계산
  - 전체 포기 대상 계산
  - 퀘스트 ID 링크 포맷

### 전문기술

- `Modules/ProfessionKnowledgeTracker.lua`
  - profession별 획득원 집계
  - 완료 퀘스트/숨은 퀘스트 기반 추적
  - 카드/오버레이/툴팁 데이터 제공
- `Modules/TomTomBridge.lua`
  - TomTom 선택적 연동
  - 하란다르/공허폭풍 일부 1회성 보물은 현재 지역 제한 안내를 포함

## 데이터 계층

- `Data/Defaults.lua`
  - SavedVariables 기본값
- `Data/ProfessionKnowledge.lua`
  - profession별 획득원 정의
- `Data/ProfessionKnowledgeWaypoints.lua`
  - profession 1회성 보물 좌표
- `Data/SilvermoonMapData.lua`
  - 한밤(Midnight) 지도 라벨 정의
- `Data/StatPriorities.lua`
  - 특성별 일반 PvE 우선순위

## UI 계층

- `UI/MainWindow.lua`
  - 메인 프레임과 탭 전환
- `UI/ProfilePanel.lua`
  - 현재 캐릭터, 템플릿 목록, 템플릿 작업
- `UI/ActionBarPanel.lua`
  - 범위 선택, 비교, 동기화
- `UI/ProfessionPanel.lua`
  - profession 카드, 오버레이 설정, 재스캔
- `UI/QuestPanel.lua`
  - 퀘스트 후보 목록, 안전 정리, 전체 포기
- `UI/ConfigPanel.lua`
  - 메인 설정 탭
- `UI/AddonSettingsPages.lua`
  - 와우 `설정 > 애드온` 하위 카테고리
- `UI/StatsOverlay.lua`
  - 캐릭터 스탯 오버레이
- `UI/ProfessionKnowledgeOverlay.lua`
  - profession 포인트 오버레이
- `UI/SilvermoonMapOverlay.lua`
  - 한밤(Midnight) 지도 텍스트 오버레이
- `UI/TransferDialog.lua`
  - import/export 대화상자
- `UI/ConfirmDialogs.lua`
  - 확인 모달
- `UI/MinimapButton.lua`
  - 미니맵 버튼
- `UI/Widgets.lua`
  - 공용 위젯

## 저장 구조

### 계정 공통

- `global.settings`
  - 언어
  - 확인창
  - 디버그
  - 오버레이 표시 여부
  - 오버레이 스케일
  - 지도 라벨 카테고리 필터
  - 마우스 이동 자동 복구

### UI

- `ui`
  - 메인 창 위치
  - profession 오버레이 위치/모드
  - stats 오버레이 위치

### 캐릭터별

- profession 진행 상태
- 캐릭터 기본 정보
- 템플릿 작성 시 원본 캐릭터 메타데이터

## 동작 흐름

### 로그인

1. `ADDON_LOADED`
2. DB 초기화
3. 모듈 초기화
4. `PLAYER_LOGIN`
5. profession/stats UI refresh
6. 필요 시 `autoInteract` 복구

### profession 추적

1. profession key 확인
2. source 정의 로드
3. source별 objective 완료 상태 계산
4. weekly/one-time section 합계 계산
5. 카드/오버레이/툴팁용 파생 데이터 생성

### 지도 오버레이

1. 현재 지도 mapID 확인
2. 내부 인스턴스/마이크로맵 차단
3. exact map, alias, 제한된 fallback 순으로 데이터 조회
4. 라벨 줄바꿈/오프셋/카테고리 필터 반영
5. WorldMap에 텍스트 오버레이 렌더

## 안정성 메모

- profession/TomTom 연동은 메인 기능에 영향을 주지 않도록 선택 기능으로 유지한다.
- 지도 오버레이는 refresh 중 예외가 나도 메인 UI를 깨뜨리지 않게 방어한다.
- 와우 `설정 > 애드온`은 메인 창 재사용이 아니라 경량 패널만 사용한다.
- 대규모 UI 리디자인보다 현재 배치 유지와 overflow 방지 보정을 우선한다.

## 현재 알려진 보류 사항

- TomTom 1회성 waypoint는 하란다르/공허폭풍 일부 보물에서 현재 해당 지역 안에 있을 때만 안정적으로 생성되는 것으로 확인됐다.
- 지도 좌표는 패치 후 수동 보정이 필요할 수 있다.
- 제작 주문, catch-up 같은 profession 예외 획득원은 아직 별도 자동 집계하지 않는다.
