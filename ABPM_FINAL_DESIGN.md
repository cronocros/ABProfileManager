# ABPM Final Design

현재 제품 상태:
- `v1.3.7`
- 구현 완료
- 1차 출시 완료
- 최신 배포 기준 문서

## 목적

`ABProfileManager`는 WoW Retail용 액션바 템플릿 관리 애드온이다.
현재 범위는 액션바 템플릿 저장, 적용, 비교, 동기화, 전체/부분 비우기, 문자열 내보내기/가져오기, 퀘스트 정리, 스탯 오버레이, 전문기술 추적, 한밤(Midnight) 지도 오버레이까지 포함한다.

## 제품 범위

- 템플릿 저장 / 복제 / 적용 / 삭제
- 같은 이름 저장 시 덮어쓰기 확인
- 세션 기준 최근 1회 되돌리기
- 전체 액션바 또는 부분 범위 적용
- 현재 액션바와 템플릿 비교
- 비교 결과 기반 동기화
- 현재 적용 가능한 칸만 맞추기
- 템플릿 정보 확장 표시
- 템플릿 문자열 내보내기 / 가져오기
- 현재 특성 전환
- 비행 중 페이지 전환 바 저장/적용
- 퀘스트 정리 / 전체 퀘스트 포기
- 전투 중 대기열 처리
- 누락 액션 고스트 오버레이
- 고스트 드래그 해제 / 다른 액션으로 덮어쓰기
- 캐릭터 스탯 오버레이
- 전문기술 주간 체크 탭
- 전문기술 체크 오버레이
- 한밤(Midnight) 지도 오버레이
- 와우 `설정 > 애드온` 루트 / 하위 카테고리
- 메인 타이틀 / 설정 버전 표기
- 메인 창 전면 표시 보강

## 제외 범위

- 채팅창 레이아웃 관리
- 미터 레이아웃 관리
- 외부 클립보드 직접 복사
- Blizzard 기본 캐릭터창 대체
- profession crafting order 전체 자동 집계

## 아키텍처

### 루트 파일

- `Core.lua`
  - 네임스페이스 초기화
  - 모듈 초기화 오케스트레이션
- `DB.lua`
  - SavedVariables 초기화
  - UI 설정, 템플릿, 캐릭터 기록 관리
- `Commands.lua`
  - `/abpm` 명령 처리
- `Events.lua`
  - `ADDON_LOADED`, `PLAYER_LOGIN`, `PLAYER_REGEN_ENABLED` 등 이벤트 처리
- `Locale.lua`
  - 기본 로케일 문자열
- `Locale_Additions.lua`
  - 추가 기능용 로케일 문자열 오버레이
- `Utils.lua`
  - 공용 유틸리티
  - 상태 메시지 포맷

### Modules

- `ActionBarScanner.lua`
  - 액션바 전체 스캔
- `ActionBarApplier.lua`
  - 실제 적용/비우기
  - 전투 중 대기열 처리
  - 고스트 재시도
- `ProfileManager.lua`
  - 템플릿 저장/로드/적용/삭제
- `UndoManager.lua`
  - 최근 1회 작업 직전 상태 저장
  - 되돌리기 실행
- `RangeCopyManager.lua`
  - 적용 범위 정규화
  - 전체/바/바 범위/선택 바/칸 범위 처리
- `SlotMapper.lua`
  - 논리 슬롯과 실제 슬롯 검증
  - 바 이름 및 선택 범위 설명
- `TemplateSyncManager.lua`
  - 비교 및 동기화 로직
- `TemplateTransfer.lua`
  - 문자열 내보내기/가져오기
- `GhostManager.lua`
  - 누락 액션 시각 오버레이
- `QuestManager.lua`
  - 퀘스트 로그 스캔
  - 안전 정리 후보 계산
  - 전체 포기 후보 계산
  - 실제 퀘스트 포기 실행
- `ProfessionKnowledgeTracker.lua`
  - profession별 자동 추적
  - 완료 퀘스트 / 숨은 퀘스트 / 내장 매핑 기반 진행도 계산
  - profession 오버레이 / 탭용 집계 데이터 제공

### Data

- `Data/Defaults.lua`
  - SavedVariables 기본값
- `Data/ProfessionKnowledge.lua`
  - profession별 획득원 정의
- `Data/SilvermoonMapData.lua`
  - 한밤(Midnight) 지도 라벨 위치 정의
- `Data/StatPriorities.lua`
  - 특성별 PvE 일반 우선순위 정의

### UI

- `MainWindow.lua`
  - 메인 프레임
  - 탭 전환
  - 하단 상태 요약 박스
  - 외부 진입용 `OpenToTab`
- `ProfilePanel.lua`
  - 현재 접속 캐릭터 정보
  - 특성 전환
  - 템플릿 목록
  - 템플릿 작업
- `ActionBarPanel.lua`
  - 적용 범위
  - 범위 요약
  - 비교 결과
  - 동기화 작업
- `ProfessionPanel.lua`
  - profession 카드
  - 주간 / 1회성 진행도
  - profession 아이콘 / 포인트 합계 / 재스캔
- `ConfigPanel.lua`
  - 메인 창 설정 탭
  - 와우 `설정 > 애드온` 루트 패널 등록
  - 설정 전용 레이아웃
- `AddonSettingsPages.lua`
  - 와우 `설정 > 애드온 > ABProfileManager` 하위 카테고리
  - `Templates / Action Bars / Professions / Quests` 경량 안내 패널
- `QuestPanel.lua`
  - 퀘스트 정리 기준 요약
  - 퀘스트 후보 목록
  - 안전 정리 / 전체 포기 실행
- `TransferDialog.lua`
  - 문자열 내보내기/가져오기
- `ConfirmDialogs.lua`
  - 적용/비우기/삭제 확인 모달
- `MinimapButton.lua`
  - 미니맵 단순 버튼형 UI
- `StatsOverlay.lua`
  - 배경 없는 글자형 캐릭터 스탯 오버레이
  - 드래그 이동 및 위치 저장
  - 탱커 방어 스탯 / 특성별 우선순위 표시
  - `캐릭터 직업 - 특성(아이템레벨)` 헤더
  - 크기 스케일 적용
- `ProfessionKnowledgeOverlay.lua`
  - profession 포인트 오버레이
  - 아이콘 / 접기 / 펼치기 / 드래그 이동
  - 크기 스케일 적용
- `SilvermoonMapOverlay.lua`
  - 한밤(Midnight) 지도 텍스트 오버레이
  - 시설 / profession / 평판 상인 / 던전 / 구렁 라벨 표시
  - 카테고리별 필터 on/off 반영
  - 보수적인 map 해석과 길이 기반 한국어 줄바꿈 규칙 적용
- `Widgets.lua`
  - 공용 위젯 및 스크롤/패널 스타일

## 데이터 모델

### 논리 슬롯

- 내부 논리 슬롯 범위: `1..196`
- 실제 변경 허용 범위:
  - `1..132`
  - `145..180`

### 바 모델

- 일반 바 + 비행 중 페이지 전환 바 포함
- 비행 중 바는 `9번 바`로 표기
- 현재 UI/적용 범위 모델은 `1~9번 바`까지만 지원
- `10~12번` 특수 바는 현재 별도 매핑하지 않음

### 템플릿 레코드

주요 필드:

- `sourceType`
- `sourceKey`
- `characterKey`
- `class`
- `specID`
- `savedAt`
- `slots`

### profession 추적 레코드

주요 필드:

- `weeklyResetKey`
- `characters[characterKey]`
- `objectives[sourceKey]`
- `completed`
- `pointsEarned`
- `lastScanAt`

## UI 설계 요약

### 현재 접속 캐릭터 탭

- 상단:
  - 현재 캐릭터 정보
  - 직업/특성 아이콘
  - 현재 특성 `▶` 식별이 들어간 특성 전환 버튼
  - 템플릿 이름 입력
  - 저장 / 복제 / 목록 새로고침 / 삭제 버튼
- 하단 좌측:
  - 템플릿 목록
  - 이전 / 다음 템플릿 이동
- 하단 우측:
  - 템플릿 정보 스크롤 박스
    - 저장 캐릭터 / 직업 / 특성 ID / 특성명
    - 기록된 액션 수 / 빈 칸 수 / 주문 / 매크로 / 아이템 / 기타 개수
  - 버튼 세로 배치
    - 적용
    - 전체 액션바 비우기
    - 직전 작업 되돌리기
    - 문자열 내보내기
    - 문자열 가져오기

### 액션바 탭

- 상단 좌측: 선택한 템플릿 정보
- 상단 우측: 비교 결과 전체 스크롤 표시
- 하단 좌측: 적용 범위 선택 + 범위 요약
- 하단 우측: 비교 / 동기화 / 직전 작업 되돌리기
- 동기화 버튼은 현재 선택 범위 기준으로 hover 툴팁과 클릭 전 설명을 가변 표시

### 전문기술 탭

- profession 카드 2개까지 자동 표시
- 카드 헤더:
  - profession 아이콘
  - profession 이름
  - 합계 포인트
- 카드 본문:
  - `주간`
  - `1회성`
  - 소스별 진행도
  - 마우스 오버 상세 설명
- 카드 하단:
  - 마지막 스캔 표시
  - `재스캔`

### 설정 탭

- 좌측:
  - 언어
  - 미니맵 버튼
  - 확인창
  - 디버그 로그
- 우측:
  - 스탯 오버레이
  - profession 오버레이
  - 한밤(Midnight) 지도 오버레이
- 하단:
  - 현재 세션 요약
  - profession 마지막 스캔
  - 활성 오버레이 상태
  - 지도 라벨 카테고리 체크박스

### 퀘스트 탭

- 상단 좌측: 정리 기준과 현재 퀘스트 요약
- 상단 우측: 새로고침 / 안전 정리 / 전체 포기 버튼
- 하단 3열: 안전 정리 대상 / 남겨둘 퀘스트 / 전체 포기 대상 목록

### profession 오버레이

- 요약형:
  - profession별 아이콘
  - 총 포인트
  - 주간 / 1회성 핵심 소스 요약
- 확장형:
  - profession별 요약
  - `주간` 상세
  - `1회성` 상세
- 드래그 이동
- 접기 / 펼치기

### 한밤(Midnight) 지도 오버레이

- 대형 텍스트 라벨 기반
- 카테고리별 크기 차등
  - 시설
  - 이동
  - profession
  - PvP
  - 던전
  - 구렁
  - 평판
- 정적 좌표 데이터 기반
- 한국어 라벨 우선
- 긴 라벨은 붙여쓰기 또는 수동 줄바꿈 라벨을 우선 사용
- 쿠엘다나스 섬의 `마법학자의 정원` / `태양샘 고원` 입구 라벨 포함

### 와우 설정 하위 카테고리

- 루트:
  - 공통 설정
  - 상태 요약
- 하위:
  - `Templates`
  - `Action Bars`
  - `Professions`
  - `Quests`
- 각 하위 패널은 경량 설명 + 상태 요약 + 메인 탭 열기 버튼 구조

## 동작 원칙

- 전투 중 보호된 액션바는 즉시 변경하지 않음
- 대기열 저장 후 전투 종료 시 재시도
- 누락 스킬/아이템/매크로는 고스트로 처리
- 플레이어가 커서에 다른 액션을 들고 있을 때는 고스트 자동 재시도가 수동 덮어쓰기를 방해하지 않음
- 매크로는 이름 + 본문 기준으로 엄격하게 검증
- 전체 비우기는 1차 실행 후 남은 칸을 다시 점검해 2차 비우기를 수행
- 상태 메시지는 `성공 / 실패 / 안내` 형식으로 표시
- 되돌리기는 가장 최근에 실제 실행된 변경 작업 직전 상태만 복구
- 퀘스트 안전 정리는 진행도 있는 퀘스트와 완료/보고 가능 퀘스트를 남김
- 전체 퀘스트 포기는 현재 포기 가능한 퀘스트만 대상으로 함
- 퀘스트 탭은 숨김/작업/현상금 계열 항목을 정리 후보에서 제외
- 스탯 오버레이는 전투 중에도 표시를 유지하고, 능력치 이벤트 시 자동 갱신
- 스탯 오버레이의 퍼센트는 항상 소수 둘째 자리까지 표시하고, 측정된 고정 폭 컬럼으로 맞춘다
- 2차 스탯은 rating 기준 `30 / 39 / 47 / 54 / 66%` DR 구간에 따라 퍼센트 숫자만 단계적으로 색상 변경
- profession 체크는 숨은 퀘스트 / 완료 플래그 / 내장 데이터 기반으로 계산
- profession 오버레이는 접힘 상태도 SavedVariables에 저장
- profession 오버레이는 `상세 / 요약 / 최소` 3단 표시 모드를 지원
- profession / stats 오버레이는 저장된 scale 값을 읽어 전체 프레임 크기를 함께 조정한다
- 지도 오버레이는 지원 지도에서만 활성화하고, 표시 중일 때만 갱신 드라이버를 유지
- 지도 오버레이는 지도 줌 비율에 따라 글자 크기를 완만하게 조정
- 지도 오버레이는 카테고리 필터 값이 바뀌면 즉시 재배치한다
- 와우 `설정 > 애드온`은 메인 창과 레이아웃을 공유하지 않고 별도 경량 패널을 사용

## 보안/안전 설계

- 동적 코드 실행을 사용하지 않음
- 문자열 가져오기는 데이터 파싱만 허용
- import 입력은 길이, 줄 수, 중복 슬롯, 액션 종류를 검증
- 템플릿 이름은 단일행 기준으로 정화
- `전체 퀘스트 포기`는 확인 설정과 관계없이 항상 확인 모달 표시
- 파괴적 작업은 확인 모달 우선 원칙 유지
- profession 표시용 퀘스트명은 클라이언트에서 읽은 공식 제목을 우선 사용하고, 없을 때만 내장 번역 사용

## 현재 디자인 원칙

- 한국어 UI 우선
- 영어는 옵션
- 어두운 청색 계열 바탕 + 금색 포인트
- 섹션 제목 앞 `●` 식별 기호 사용
- 작업 결과는 하단 요약창 중심으로 출력
- 미니맵 버튼은 축소된 사각 `AB` 버튼 표현을 사용
- 오버레이는 불필요한 배경 박스를 줄이고 정보 밀도와 가독성을 함께 유지

## 릴리스 운영 정보

- 저장소: `https://github.com/cronocros/ABProfileManager`
- 기본 브랜치: `main`
- 현재 배포 버전: `v1.3.7`
- 현재 배포 산출물: `dist/ABProfileManager-v1.3.7.zip`
- GitHub 릴리스 본문 기준 문서: `RELEASE_NOTES_v1.3.7.md`
- 소스 백업 산출물: `backups/source/ABProfileManager-source-v1.3.7-<timestamp>.zip`
- 버전 기록 기준 문서: `CHANGELOG.md`

## 알려진 제한

- 실제 변경 허용 범위는 현재 `1-132`, `145-180`만 사용한다
- 바 모델은 `1~9번 바`까지만 지원한다
- 제작 주문, catch-up 같은 profession 예외 획득원은 아직 전체 자동 집계를 하지 않는다
- 한밤(Midnight) 지도 오버레이는 정적 좌표 기반이라 향후 패치 시 좌표 보정이 필요할 수 있다
- 이 작업 환경에는 `lua`/`luac`가 없고, 정적 문법 검사는 `luaparser` 기준으로 수행한다

## 기준 문서

- `README.md`
- `ABPM_FINAL_DESIGN.md`
- `ABPM_HANDOFF.md`
- `SECURITY_REVIEW.md`
- `ABProfileManager/README_USER.md`
- `ABProfileManager/ADDON_INTRO.txt`
