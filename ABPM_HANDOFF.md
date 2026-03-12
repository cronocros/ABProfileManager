# ABPM Handoff

## 현재 상태

프로젝트는 직접 적용 가능한 WoW Retail 애드온 구조를 갖추고 있다.  
현재 기준 버전은 `v1.3.2`이며, 핵심 기능 구현과 최신 유지보수 반영, 문서 정리, 배포 준비까지 끝난 상태다.

## 현재 구현 범위

- 템플릿 저장 / 복제 / 적용 / 삭제
- 최근 1회 작업 되돌리기
- 문자열 내보내기 / 가져오기
- 전체/부분 적용
- 전체/부분 비우기
- 비교 / 동기화
- 비행 바 `9번 바` 처리
- 전투 중 대기열
- 현재 특성 전환
- 퀘스트 정리 / 전체 퀘스트 포기
- 미니맵 버튼
- 캐릭터 스탯 오버레이
- 전문기술 주간 체크 탭
- 전문기술 체크 오버레이
- 한밤(Midnight) 지도 오버레이
- 와우 `설정 > 애드온` 루트 / 하위 카테고리

## 이번 배포까지 반영된 핵심 사항

- 고스트 덮어쓰기 간헐 버그 완화
  - 플레이어 커서에 다른 액션이 있을 때 고스트 자동 재시도가 수동 드래그를 방해하지 않도록 보강
- 스탯 오버레이 정리
  - `캐릭터 직업 - 특성(아이템레벨)` 헤더 표시
  - 퍼센트 정렬은 측정 기반 고정 폭 컬럼으로 교체
  - 힛트박스를 텍스트 폭에 가깝게 축소
  - 동일 스냅샷 재렌더를 줄여 비용 완화
- profession 주간 체크 개선
  - 숨은 퀘스트 / 완료 플래그 기반 자동 추적
  - profession 아이콘 추가
  - `KP` 표현을 `포인트`로 정리
  - 한국어 클라이언트에서는 공식 퀘스트명을 우선 사용
  - 카드 레이아웃과 source 설명을 더 짧고 읽기 쉽게 정리
- profession 오버레이 확장
  - profession별 아이콘 표시
  - `상세 / 요약 / 최소` 3단 표시 지원
  - 주간 / 1회성 외에 핵심 소스 요약 표시
- 한밤(Midnight) 지도 오버레이 개선
  - 시설 / profession / PvP / 던전 / 구렁 / 평판 카테고리별 라벨 크기와 폭을 다시 재조정
  - 주요 던전 / 구렁 이름을 한국어 라벨과 줄바꿈 규칙으로 보강
  - 포탈 이름, 평판 상인, profession 허브 표시 보강
  - 쿠엘다나스 섬의 `마법학자의 정원` / `태양샘 고원` 입구 라벨 추가
  - 지도 확대 / 축소에 따라 라벨 크기를 완만하게 조정
- 설정 패널 안정화
  - 메인 창용 레이아웃과 와우 `설정 > 애드온`용 레이아웃 분리
  - 우측 박스 overflow 완화
  - `Templates / Action Bars / Professions / Quests` 하위 카테고리 추가
  - 하위 카테고리는 메인 탭 재사용이 아니라 경량 안내 패널 + 바로가기 버튼 구조

## 현재 잔여 메모

1. profession 자동 추적 한계
- 제작 주문, catch-up 같은 일부 예외 획득원은 아직 별도 자동 집계하지 않는다.

2. 한밤(Midnight) 지도 데이터
- 정적 좌표와 수동 라벨 기반이라 패치 후 좌표 보정이 필요할 수 있다.

3. 정적 검사 환경
- 이 작업 환경에는 `lua`/`luac`가 없고, 현재는 `luaparser` 기준 정적 문법 파싱으로 검증한다.

4. 바 모델 메모
- 현재 적용/선택 바 모델은 `1~9번 바`까지만 사용한다.
- `9번 바`는 비행 중 페이지 전환 바다.
- `10~12번` 특수 바는 현재 별도 매핑하지 않는다.

## 중요한 파일

### 부트스트랩

- `ABProfileManager/Core.lua`
- `ABProfileManager/DB.lua`
- `ABProfileManager/Events.lua`
- `ABProfileManager/Commands.lua`

### UI

- `ABProfileManager/UI/MainWindow.lua`
- `ABProfileManager/UI/ProfilePanel.lua`
- `ABProfileManager/UI/ActionBarPanel.lua`
- `ABProfileManager/UI/ProfessionPanel.lua`
- `ABProfileManager/UI/ConfigPanel.lua`
- `ABProfileManager/UI/AddonSettingsPages.lua`
- `ABProfileManager/UI/QuestPanel.lua`
- `ABProfileManager/UI/TransferDialog.lua`
- `ABProfileManager/UI/ConfirmDialogs.lua`
- `ABProfileManager/UI/MinimapButton.lua`
- `ABProfileManager/UI/StatsOverlay.lua`
- `ABProfileManager/UI/ProfessionKnowledgeOverlay.lua`
- `ABProfileManager/UI/SilvermoonMapOverlay.lua`
- `ABProfileManager/UI/Widgets.lua`

### 데이터

- `ABProfileManager/Data/Defaults.lua`
- `ABProfileManager/Data/ProfessionKnowledge.lua`
- `ABProfileManager/Data/SilvermoonMapData.lua`
- `ABProfileManager/Data/StatPriorities.lua`

### 로직

- `ABProfileManager/Modules/ProfileManager.lua`
- `ABProfileManager/Modules/UndoManager.lua`
- `ABProfileManager/Modules/ActionBarScanner.lua`
- `ABProfileManager/Modules/ActionBarApplier.lua`
- `ABProfileManager/Modules/RangeCopyManager.lua`
- `ABProfileManager/Modules/SlotMapper.lua`
- `ABProfileManager/Modules/TemplateSyncManager.lua`
- `ABProfileManager/Modules/TemplateTransfer.lua`
- `ABProfileManager/Modules/GhostManager.lua`
- `ABProfileManager/Modules/QuestManager.lua`
- `ABProfileManager/Modules/ProfessionKnowledgeTracker.lua`

### 사용자 문서

- `README.md`
- `ABProfileManager/README_USER.md`
- `ABProfileManager/ADDON_INTRO.txt`
- `ABPM_FINAL_DESIGN.md`
- `SECURITY_REVIEW.md`

## 다음 작업자가 볼 우선순위

1. 인게임에서 실제 UI 가독성과 좌표를 먼저 확인한다.
2. 지도 라벨 조정은 `SilvermoonMapOverlay.lua`와 `Data/SilvermoonMapData.lua`를 같이 본다.
3. profession 추적 수정은 `Data/ProfessionKnowledge.lua`와 `Modules/ProfessionKnowledgeTracker.lua`를 같이 본다.
4. 설정 패널 수정은 `UI/ConfigPanel.lua`와 `UI/AddonSettingsPages.lua`를 같이 본다.
5. 스탯 오버레이 수정은 `UI/StatsOverlay.lua`, `UI/ConfigPanel.lua`, `DB.lua`, `Events.lua`를 같이 본다.
6. 상태 메시지 포맷은 `Utils.FormatStatusMessage()`를 기준으로 유지한다.
7. import 관련 작업은 `Modules/TemplateTransfer.lua`의 입력 제한을 먼저 확인한다.
8. 버전 표시는 `GetAddOnMetadata(..., "Version")` 경로를 우선 유지한다.

## 릴리스 자산

- 저장소: `https://github.com/cronocros/ABProfileManager`
- 배포 ZIP: `dist/ABProfileManager-v1.3.2.zip`
- 릴리스 노트: `RELEASE_NOTES_v1.3.2.md`
- 소스 백업 ZIP: `backups/source/ABProfileManager-source-v1.3.2-<timestamp>.zip`
- 변경 이력: `CHANGELOG.md`

## 다음 LLM용 요약 프롬프트

```text
프로젝트는 WoW Retail 애드온 ABProfileManager다.
현재 구현 범위는 액션바 템플릿 저장/적용/비교/동기화/문자열 import-export/특성 전환/비행 바 지원/전투 중 대기열/퀘스트 정리/스탯 오버레이/전문기술 자동 추적/한밤(Midnight) 지도 오버레이/와우 설정 하위 카테고리까지 포함한다.

최신 기준 문서는 README.md, ABPM_FINAL_DESIGN.md, ABPM_HANDOFF.md, SECURITY_REVIEW.md 이다.
문서 버전은 v1.3.2 기준으로 맞춰져 있다.

사용자가 민감하게 보는 지점:
- 메인 UI 레이아웃은 건드리지 않고 유지할 것
- profession 자동 추적은 숨은 퀘스트 기반 구조를 유지할 것
- 지도 오버레이는 가독성 우선으로 다룰 것
- 설정 > 애드온 패널은 메인 창과 별도 레이아웃을 유지할 것
- 고스트 드래그와 전투 중 대기열 상호작용을 조심할 것

수정 시 한국어 기본 UI를 유지하고, 톤앤매너는 어두운 청색 바탕 + 금색 포인트 + 섹션 제목 앞 ● 기호를 유지하라.
```
- 전문기술 탭 편의성 보강
  - 전문기술 탭에서 profession 오버레이 표시 여부를 바로 켜고 끌 수 있게 변경
- 메인 창 전면 표시 보강
  - 일반 Blizzard 창보다 뒤로 묻히지 않도록 Toplevel / Raise 동작 보강
