# Project Review TODO

기준 버전: `v1.3.13`

프로젝트 전체를 다시 훑어본 기준으로, 지금 우선순위는 아래 4개 축으로 정리된다.

## P1 안정성

1. profession / quest refresh 보호
   - `Events.lua`에서 `QUEST_LOG_UPDATE`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `SKILL_LINES_CHANGED`가 profession/quest UI refresh를 바로 호출한다.
   - `ProfessionKnowledgeOverlay`, `ProfessionPanel`, `QuestPanel`은 현재 `pcall` 보호가 없다.

2. refresh 디버그 추적 추가
   - 빈 Lua 오류창은 현재 코드만으로는 원문 추적이 어렵다.
   - 이벤트 이름, 호출 패널, 실패 메시지를 최소 로그로 남겨야 한다.

3. refresh 중복 진입 완화
   - 채집/루팅 직후 `QUEST_LOG_UPDATE`와 `BAG_*`가 연속으로 올 수 있다.
   - profession 갱신은 짧은 지연 또는 dirty-flag 기반 단일 refresh로 합치는 편이 안전하다.

4. `ns:SafeCall()` 역할 정리
   - 이름과 달리 실제로는 안전 호출이 아니다.
   - 전역 변경은 위험하므로 1차로는 국소 래퍼를 두고, 2차에서 공통화 여부를 결정한다.

## P1 사용성

1. profession 오버레이 툴팁 표기 통일
   - 완료/전체 항목과 포인트 표기를 한글 기준으로 더 읽기 쉽게 유지
   - 이번 요청인 `1/1개 . 3/3P` 반영

2. profession 오버레이 힌트 강화
   - `1회성` 우클릭 TomTom panel은 기능은 있으나 발견성이 낮다.
   - 우클릭 가능 상태를 row 또는 tooltip에 더 명확히 안내할 여지가 있다.

3. 오류 발생 시 사용자 피드백 보강
   - refresh 실패 시 조용히 깨지거나 빈 오류창만 뜨는 대신
   - 상태창에 `profession refresh 실패` 같은 최소 안내를 남기는 편이 낫다.

## P2 구조 정리

1. `ProfessionKnowledgeOverlay.lua` 분리
   - 파일이 가장 크고 UI, tooltip, hover panel, waypoint, row layout이 한 파일에 몰려 있다.
   - tooltip/hover/row layout helper를 분리하면 수정 리스크를 줄일 수 있다.

2. 템플릿 상세 렌더링 중복 제거
   - `ProfilePanel`과 `ActionBarPanel`에 source detail 문자열 조립이 중복된다.
   - 공통 builder로 묶으면 문구 수정이 쉬워진다.

3. 패널별 tooltip helper 공통화
   - `ActionBarPanel`, `ProfilePanel`, `QuestPanel`, `ProfessionPanel`에 유사한 tooltip 코드가 반복된다.
   - 폰트, 색상, 줄바꿈 정책을 공통 유틸로 묶을 수 있다.

4. 숨겨진 패널 refresh 최소화
   - `ns:RefreshUI()`는 생성된 패널을 전부 refresh한다.
   - 숨겨진 패널까지 항상 갱신할 필요가 있는지 점검할 가치가 있다.

## P2 데이터 / 릴리스 품질

1. profession 데이터 검증 스크립트
   - `Data/ProfessionKnowledge.lua`와 waypoint 데이터는 양이 많아 수작업 실수 가능성이 높다.
   - 중복 questID, 빈 labelKey, waypoint 누락 검사를 자동화하면 좋다.

2. locale 키 검증
   - `Locale.lua`와 `Locale_Additions.lua`에 키가 많다.
   - tooltip/설정 문구 추가 시 누락을 잡는 체크가 있으면 안전하다.

3. 릴리스 전 최소 회귀 체크리스트 문서화
   - 액션바 적용/되돌리기
   - profession overlay 3모드
   - quest panel 링크
   - Midnight map overlay

## 현재 작업 순서 제안

1. corpse herb 오류 추적을 위한 refresh 방어 + debug trace
2. profession tooltip/표기 polish
3. profession overlay 코드 분리 또는 helper 정리
4. 공통 tooltip / source detail builder 정리
