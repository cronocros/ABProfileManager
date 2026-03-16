# ABProfileManager Architecture

버전 기준: `v1.4.1.1`

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
- `UI/ProfessionKnowledgeOverlay.lua`
  - 상단 요약은 문장형 안내와 정확한 주간 리셋 잔여 시간 표시를 사용
  - tooltip은 범례, 완료/미완료 색상, source별 요약 규칙, TomTom 안내를 함께 노출
- `Modules/CombatTextManager.lua`
  - Midnight 최신 전투메시지 `_v2` CVar와 구형 이름 fallback을 함께 관리
  - 현재 클라이언트 값을 읽어 초기 스냅샷을 만들고, 사용자가 켠 표출 방식만 다시 적용
  - 적용 후 read-back 검증과 짧은 retry로 `부채꼴` 모드 실패를 더 보수적으로 감지
- `UI/ConfigPanel.lua`
  - 일반 설정, typography 슬라이더, 개요, 전투메시지 표출 방식 설정을 담당
- `UI/MapPanel.lua`
  - 지도 오버레이 전용 탭
  - 지도 글자 크기 슬라이더와 카테고리 필터 제공
- `Modules/TomTomBridge.lua`
  - TomTom 선택적 연동
  - 하란다르/공허폭풍 일부 1회성 보물은 해당 지역 진입 후 waypoint 생성 안내를 포함

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
  - typography 도메인별 오프셋
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
- 사용자가 켠 전투메시지 표출 방식 상태

## 동작 흐름

### 로그인

1. `ADDON_LOADED`
2. DB 초기화
3. 모듈 초기화
4. `PLAYER_LOGIN`
5. profession/stats UI refresh
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
3. exact map과 제한된 alias만 조회하고, 지원하지 않는 child/detail map fallback은 차단
4. 라벨 줄바꿈/오프셋/카테고리 필터/지도 글자 크기 반영
5. WorldMap에 텍스트 오버레이 렌더

## 안정성 메모

- profession/TomTom 연동은 메인 기능에 영향을 주지 않도록 선택 기능으로 유지한다.
- profession/quest refresh는 내부 예외가 나도 전체 UI를 깨뜨리지 않도록 보수적으로 처리한다.
- 지도 오버레이는 refresh 중 예외가 나도 메인 UI를 깨뜨리지 않게 방어한다.
- 지도 오버레이는 지원하지 않는 child/detail map에서 부모 지도 라벨을 억지로 보여주지 않는다.
- 와우 `설정 > 애드온`은 메인 창 재사용이 아니라 경량 패널만 사용한다.
- 대규모 UI 리디자인보다 현재 배치 유지와 overflow 방지 보정을 우선한다.

## 현재 운영 메모

- TomTom 1회성 waypoint는 하란다르/공허폭풍 일부 보물에서 별도 지역 지도 컨텍스트를 사용하므로, 해당 지역에 들어간 뒤 생성된다.
- 지도 좌표는 패치 후 수동 보정이 필요할 수 있다.
- 제작 주문, catch-up 같은 profession 예외 획득원은 아직 별도 자동 집계하지 않는다.
