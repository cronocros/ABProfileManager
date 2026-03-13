# ABProfileManager Handoff

버전 기준: `v1.3.13`

## 현재 상태

프로젝트는 실제 인게임에서 사용 중인 WoW Retail 애드온이며, 루트 문서와 기술 문서는 현재 구조 기준으로 다시 정리된 상태다.

이번 정리 기준:

- 문서 구조를 `DOC` 중심으로 재배치
- 이전 릴리스 노트는 `DOC/archive/release-notes`로 이동
- 최신 릴리스 노트만 루트 유지
- README, 사용자 문서, 인트로, 아키텍처, 인수인계, 보안, 배포 절차를 최신화
- TomTom waypoint는 정상 동작이며 하란다르/공허폭풍은 해당 지역 진입 후 생성된다는 설명으로 정리
- 인트로와 사용자 문서에 TomTom waypoint 기능 소개를 추가

## 현재 핵심 기능

- 액션바 템플릿 저장, 적용, 비교, 동기화
- 전체/부분 비우기
- 최근 1회 되돌리기
- 문자열 import/export
- 퀘스트 정리와 전체 포기
- 스탯 오버레이
- 전문기술 자동 추적 카드와 오버레이
- 한밤(Midnight) 지도 오버레이
- 와우 `설정 > 애드온` 하위 카테고리

## 사용자가 민감하게 보는 지점

1. 메인 UI 레이아웃은 크게 건드리지 말 것
2. profession 카드와 overlay의 정렬, 여백, 폰트는 이미 여러 번 맞춘 상태라 큰 재배치는 피할 것
3. 지도 오버레이는 가독성과 위치를 우선하며, 내부 지도에 뜨지 않게 유지할 것
4. 설정 패널은 메인 UI와 별도 레이아웃을 유지할 것
5. 고스트 드래그와 전투 중 대기열 상호작용은 항상 보수적으로 다룰 것

## 현재 운영 메모

### 1. TomTom waypoint 지역 컨텍스트

- profession 오버레이 `1회성` 우클릭 panel은 현재 정상 동작한다
- 하란다르와 공허폭풍 일부 보물은 별도 지역 지도라서, 해당 지역에 들어가면 waypoint가 생성된다
- 관련 설명은 인게임 메시지, 사용자 문서, 인트로에 반영 완료 상태다

운영 메모:

- TomTom 관련 제보가 오면 다른 지역에서 테스트한 것인지 먼저 확인한다
- 추가 수정이 필요하면 `Modules/TomTomBridge.lua`와 `UI/ProfessionKnowledgeOverlay.lua`를 같이 본다
- mapID 제한과 현재 플레이어 지도 lineage를 먼저 확인한다

### 2. 지도 좌표 보정

- 정적 좌표 기반이라 패치 후 drift가 생길 수 있다
- 보정은 `Data/SilvermoonMapData.lua`와 `UI/SilvermoonMapOverlay.lua`를 같이 수정한다

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
- `ABProfileManager/Data/ProfessionKnowledge.lua`
- `ABProfileManager/Data/ProfessionKnowledgeWaypoints.lua`
- `ABProfileManager/Data/SilvermoonMapData.lua`
- `ABProfileManager/UI/ProfessionPanel.lua`
- `ABProfileManager/UI/ProfessionKnowledgeOverlay.lua`
- `ABProfileManager/UI/SilvermoonMapOverlay.lua`

### 퀘스트 / 스탯 / 설정

- `ABProfileManager/Modules/QuestManager.lua`
- `ABProfileManager/UI/QuestPanel.lua`
- `ABProfileManager/UI/StatsOverlay.lua`
- `ABProfileManager/UI/ConfigPanel.lua`
- `ABProfileManager/UI/AddonSettingsPages.lua`

## 검증 습관

- 먼저 `luaparser` 전체 파싱
- 그 다음 `git diff --check`
- 그 다음 패키징
- 마지막에 푸시/릴리스

인게임 회귀 포인트:

- profession 카드 폭과 체크박스 레이아웃
- profession overlay 상세/요약/최소
- 지도 오버레이 외부 월드맵만 표시되는지
- 퀘스트 ID 링크 클릭
- 스탯 overlay drag/hitbox

## 문서 위치

- 루트 사용자 문서: `README.md`
- 사용자 안내: `ABProfileManager/README_USER.md`
- 소개 텍스트: `ABProfileManager/ADDON_INTRO.txt`
- 기술 문서 색인: `DOC/README.md`
- 아키텍처: `DOC/ARCHITECTURE.md`
- 보안 검토: `DOC/SECURITY_REVIEW.md`
- 배포 절차: `DOC/RELEASE_PROCESS.md`

## 다음 작업자에게

- TomTom waypoint는 현재 동작 설명까지 정리된 상태이므로, 회귀 제보가 오면 먼저 지역 진입 여부와 map lineage부터 확인하는 것이 맞다.
- UI 퍼블리싱은 이미 사용자가 맞춘 상태를 선호하므로, overflow 보정이나 안전장치 위주로만 접근하는 편이 안전하다.
