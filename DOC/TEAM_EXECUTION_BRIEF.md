# Team Execution Brief

기준 버전: `v1.4.0`

목적:
- 이 문서는 에이전트 팀이 바로 착수할 수 있도록 작업 순서, 역할, 완료 조건, 승인 기준을 고정한다.
- `v1.4.0` 구현 기준으로는 주요 스트림이 반영되었고, 본 문서는 후속 점검/확장 브리프로 유지한다.

관련 문서:
- [NEXT_WORK_PLAN.md](./NEXT_WORK_PLAN.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [HANDOFF.md](./HANDOFF.md)
- [../sub/README.md](../sub/README.md)

## 최종 작업 분류

[분류] 혼합
[주 담당] source-implementer
[교차 검수] source-reviewer
[문서 반영] doc-maintainer
[총괄 승인] control-lead

## 작업 스트림

### Stream A. Typography Foundation

목표:
- 모든 사용자 가시 텍스트를 도메인별 슬라이더로 조절 가능하게 만든다.

범위:
- 기본 UI 본문
- tooltip
- profession overlay
- stats overlay
- map overlay

핵심 파일:
- `ABProfileManager/UI/Widgets.lua`
- `ABProfileManager/UI/MainWindow.lua`
- `ABProfileManager/UI/ProfilePanel.lua`
- `ABProfileManager/UI/ActionBarPanel.lua`
- `ABProfileManager/UI/ProfessionPanel.lua`
- `ABProfileManager/UI/QuestPanel.lua`
- `ABProfileManager/UI/ConfigPanel.lua`
- `ABProfileManager/UI/ProfessionKnowledgeOverlay.lua`
- `ABProfileManager/UI/StatsOverlay.lua`
- `ABProfileManager/UI/SilvermoonMapOverlay.lua`
- `ABProfileManager/DB.lua`
- `ABProfileManager/Data/Defaults.lua`
- 신규 후보 `ABProfileManager/UI/Typography.lua`

완료 조건:
- 슬라이더 값이 저장된다.
- 한국어/영어에서 텍스트가 읽을 수 있다.
- extreme 값에서 주요 패널이 붕괴하지 않는다.
- 기존 `scale` 저장값과 충돌 없이 읽힌다.

### Stream B. Map Tab and Data

목표:
- 지도 관련 설정을 `지도` 탭으로 분리하고, 평판상인/포탈 확장을 반영한다.

범위:
- 메인 창 탭 추가
- 지도 전용 패널 추가
- map filter 확장
- renown -> 평판상인 필터 분리
- 다른 지도의 포탈 데이터 보강

핵심 파일:
- `ABProfileManager/UI/MainWindow.lua`
- `ABProfileManager/UI/ConfigPanel.lua`
- `ABProfileManager/UI/AddonSettingsPages.lua`
- `ABProfileManager/UI/SilvermoonMapOverlay.lua`
- `ABProfileManager/Data/SilvermoonMapData.lua`
- `ABProfileManager/DB.lua`
- `ABProfileManager/Locale.lua`
- `ABProfileManager/Locale_Additions.lua`

완료 조건:
- 설정 탭에서 지도 제어가 빠지고 지도 탭으로 이동한다.
- 평판상인 필터가 독립 동작한다.
- 지원 지도에서 포탈이 추가 표시된다.
- 지도 텍스트 슬라이더가 실제 label에 반영된다.

### Stream C. Profession UX and Refresh Reliability

목표:
- profession tooltip 문구를 재작성하고, refresh 신뢰도와 좌표 정확도를 점검한다.

범위:
- 문장형 tooltip 요약
- `완료:` / `미완료:` prefix 표기
- reset countdown 정밀화
- glyph 깨짐 제거
- 드랍/논문/1회성 refresh audit
- 1회성 보물 좌표 재검증

핵심 파일:
- `ABProfileManager/UI/ProfessionKnowledgeOverlay.lua`
- `ABProfileManager/UI/ProfessionPanel.lua`
- `ABProfileManager/Modules/ProfessionKnowledgeTracker.lua`
- `ABProfileManager/Events.lua`
- `ABProfileManager/Data/ProfessionKnowledge.lua`
- `ABProfileManager/Data/ProfessionKnowledgeWaypoints.lua`
- `ABProfileManager/Locale.lua`
- `ABProfileManager/Locale_Additions.lua`

완료 조건:
- tooltip 문장이 사용자가 이해 가능한 형태로 바뀐다.
- TomTom 안내와 완료 표기의 glyph 깨짐이 없다.
- source별 refresh 검증 결과가 남는다.
- 좌표 재검증 근거가 기록된다.

### Stream D. Combat Text and Action Safety

목표:
- 전투메시지 모드가 실제 동작하는지 확인하고, 액션바 템플릿 모든 실행에 확인 모달을 강제한다.

범위:
- combat text `위로 / 아래로 / 부채꼴` 검증/수정
- CVar 적용 확인 로직 보강
- 액션바/템플릿 destructive action 강제 confirm

핵심 파일:
- `ABProfileManager/Modules/CombatTextManager.lua`
- `ABProfileManager/UI/ConfigPanel.lua`
- `ABProfileManager/Events.lua`
- `ABProfileManager/DB.lua`
- `ABProfileManager/UI/ConfirmDialogs.lua`
- `ABProfileManager/UI/ActionBarPanel.lua`
- `ABProfileManager/Modules/ProfileManager.lua`
- `ABProfileManager/Commands.lua`
- 필요 시 `Modules/TemplateSyncManager.lua`

완료 조건:
- 모드 선택과 실제 CVar 값이 맞는다.
- 최소 1회 수동 검증 결과가 남는다.
- 템플릿 관련 모든 실행 경로에서 confirm 누락이 없다.

### Stream E. Future Investigation

목표:
- 즉시 구현이 아닌 조사/판단 항목 정리

범위:
- `Waypoint UI` 연동 가능성
- 개인용 빛기둥 대안
- 내부 명명 리팩터링 필요성

산출물:
- 조사 메모
- 보류/승인 판단

## 역할별 즉시 할 일

### control-lead

1. Stream A와 Stream B를 같은 구현 묶음으로 승인
2. Stream C와 Stream D는 A/B 이후 병행 여부 결정
3. `Waypoint UI`는 조사까지만 허용, 구현은 보류로 고정

### source-implementer

1. typography helper 설계 초안 작성
2. map tab UI 스켈레톤 설계
3. combat text 검증 포인트 목록 작성
4. profession refresh audit 방식 제안

### source-reviewer

1. typography 적용 누락 가능 파일 목록 작성
2. SavedVariables migration 위험 지점 식별
3. map overlay collision 위험 지점 식별
4. actionbar confirm 누락 경로 목록 작성

### doc-maintainer

1. 구현 완료 후 바뀔 문서 목록 선확정
2. tooltip/설정 문구 변경으로 인한 README 영향 지점 정리
3. release notes 뼈대 초안 준비

## 권장 구현 순서

1. Stream A 기초 구조
2. Stream B 지도 탭 분리
3. Stream A를 map/profession/stats/main UI로 확장
4. Stream C tooltip/refresh 개편
5. Stream D combat text/confirm 보강
6. Stream C 좌표 검증
7. 문서 반영

## 승인 기준

### source-reviewer 승인 기준

- `git diff --check` 통과
- Lua 파싱 또는 동등 수준 구문 점검 통과
- 주요 패널 글자 크기 extreme 값 수동 확인 포인트 명시
- SavedVariables 호환성 설명 존재
- 전투 중 보호 동작 리스크 설명 존재

### control-lead 승인 기준

- Stream A/B 최소 구현이 함께 묶여야 함
- Stream C/D는 사용자 체감 개선이 명확해야 함
- 좌표 수정은 근거 출처 없이 승인 금지
- 부채꼴 모드는 실제 클라이언트 검증 메모 없이 승인 금지

## 보류 결정

- 개인 전용 3D 빛기둥 구현은 기본 API만으로는 보류
- `Waypoint UI` 연동은 조사 후 별도 승인 없이는 구현하지 않음

## 인계 메모

- 이번 묶음의 가장 큰 리스크는 typography 전역화로 인한 레이아웃 회귀다.
- 두 번째 리스크는 profession refresh와 hidden quest 데이터의 실제 동작 불일치다.
- 세 번째 리스크는 combat text가 코드상 맞아 보여도 클라이언트 체감과 다를 수 있다는 점이다.
