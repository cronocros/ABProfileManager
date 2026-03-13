# ABProfileManager Handoff

버전 기준: `v1.3.16`

## 현재 상태

프로젝트는 실제 인게임에서 사용 중인 WoW Retail 애드온이며, 루트 문서와 기술 문서는 현재 구조 기준으로 다시 정리된 상태다.

이번 정리 기준:

- 문서 구조를 `DOC` 중심으로 재배치
- 이전 릴리스 노트는 `DOC/archive/release-notes`로 이동
- 최신 릴리스 노트만 루트 유지
- README, 사용자 문서, 인트로, 아키텍처, 인수인계, 보안, 배포 절차를 최신화
- TomTom waypoint는 정상 동작이며 하란다르/공허폭풍은 해당 지역 진입 후 생성된다는 설명으로 정리
- 인트로와 사용자 문서에 TomTom waypoint 기능 소개를 추가
- profession/quest refresh는 내부 예외를 보호하도록 보강
- loot 종료 후 profession refresh를 다시 확인하도록 연결
- profession 오버레이 tooltip 진행 표기를 `1/1개 . 3/3P` 형식으로 정리
- profession 오버레이 상단 요약을 `주간 0/0P`, `1회성 0/0P` 형식으로 통일
- profession 오버레이 tooltip 최소 폭을 넓혀 긴 이름과 안내 문구 가독성을 보강
- Midnight 전투메시지 CVar를 설정 탭에서 직접 제어하는 섹션을 추가
- 선택한 전투메시지 프리셋은 로그인과 월드 진입 때 다시 적용된다

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

### 2. profession refresh 안정화

- profession/quest refresh는 이제 보호 경로를 거친다
- 채집/루팅 직후 연속 이벤트는 짧게 합쳐 처리한다
- `LOOT_CLOSED` 이후에도 profession refresh를 다시 확인해 1회성 완료 반영 누락 가능성을 줄였다
- 최신 사용자 피드백 기준으로 구렁/던전 시체 약초채집 blank Lua 오류는 재현되지 않았다
- 다만 다른 애드온 조합과 장기 운용까지 완전 종결된 것은 아니므로 관찰 메모는 유지한다

운영 메모:

- 시체 채집/보물 채집 관련 제보가 오면 `Events.lua`, `UI/ProfessionKnowledgeOverlay.lua`, `UI/ProfessionPanel.lua`, `UI/QuestPanel.lua`를 먼저 본다
- 오류 원문이 필요하면 `/abpm debug on`과 기본 Lua 오류 표시를 같이 켜고 본다

### 3. 전투메시지 CVar 직접 제어

- Midnight 최신 클라이언트는 일부 전투메시지 옵션이 기본 UI에서 잘 보이지 않는다
- 현재는 `CombatTextManager`가 `_v2` CVar를 우선 사용하고, 없으면 구형 이름으로 fallback 한다
- 사용자가 설정 탭에서 항목을 건드리면 해당 프리셋을 저장하고 바로 적용한다
- `전투메시지 직접 제어`를 끄면 이후 로그인/월드 진입 때 강제 재적용하지 않는다

운영 메모:

- 전투메시지 모드 관련 제보가 오면 `Modules/CombatTextManager.lua`, `UI/ConfigPanel.lua`, `DB.lua`, `Events.lua`를 같이 본다
- 모드 값은 `1=위로`, `2=아래로`, `3=부채꼴` 기준으로 저장한다

### 4. 지도 좌표 보정

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
- `ABProfileManager/Modules/CombatTextManager.lua`
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
- 전투메시지 설정 체크박스와 `위로 / 아래로 / 부채꼴` 버튼 선택 상태
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
