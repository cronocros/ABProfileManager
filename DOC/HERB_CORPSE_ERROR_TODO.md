# Herb Corpse Error TODO

기준 버전: `v1.3.16`

## 증상

- 구렁 또는 던전 내부에서 식물 채집 가능 몹을 처치
- 시체에 `약초채집` 상호작용이 뜨는 상태에서 채집 시도
- 내용이 비어 있는 Lua 오류창이 출력됨

## 현재 판단

확률상 두 갈래로 봐야 한다.

1. 직접 상호작용 원인
   - 현재 애드온은 시체 채집, 루팅, 스펠 시전, 유닛 상호작용을 직접 후킹하지 않는다.
   - 그래서 `채집 버튼을 누르는 즉시` 오류가 뜬다면 다른 애드온이 직접 원인일 가능성이 더 높다.

2. 채집 후 갱신 원인
   - 현재 애드온은 채집 후 자주 발생하는 `QUEST_LOG_UPDATE`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `SKILL_LINES_CHANGED`에서 profession/quest UI를 즉시 다시 그린다.
   - `v1.3.14`부터 1차 보호 경로는 들어갔지만, 이벤트 원문과 실제 트리거 시점이 아직 확정되지 않아 추가 추적이 필요하다.
   - 따라서 `채집 성공 직후` 또는 `드랍이 가방에 들어간 직후` 오류가 뜬다면 현재 애드온이 원인일 가능성이 충분하다.

## 코드 근거

- `ABProfileManager/Events.lua`
  - `QUEST_LOG_UPDATE`에서 `QuestPanel:Refresh(true)`와 profession refresh를 같이 호출
  - `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`에서 profession refresh를 호출
- `ABProfileManager/Core.lua`
  - `ns:SafeCall()`은 이름과 달리 `pcall` 방어가 없다
- `ABProfileManager/UI/ProfessionKnowledgeOverlay.lua`
  - `Refresh()`와 `RefreshRow()`는 tracker/data/UI 값을 직접 소비하는 경로라 입력 상태 이상에 민감하다
- 비교 기준
  - `ABProfileManager/UI/SilvermoonMapOverlay.lua`는 `Refresh()`에 `pcall` 방어가 이미 들어가 있음
  - profession overlay와 quest panel도 이제 1차 보호는 들어갔지만, 동일 수준의 공통 refresh 래퍼와 trace는 아직 없다

## 1차 결론

- 현재 애드온이 `직접 시체 채집 기능을 건드린다`는 증거는 없음
- 하지만 `채집으로 인해 발생한 가방/퀘스트/전문기술 갱신 이벤트에서 현재 애드온 UI가 터진다`는 경로는 구조상 충분히 가능함
- 그래서 현 시점 판단은 다음과 같다
  - 직접 트리거: 다른 애드온 가능성 높음
  - 후속 갱신 크래시: 현재 애드온 가능성 높음

## 현재 반영 상태

- `v1.3.14`에서 profession/quest refresh 보호와 `LOOT_CLOSED` 기반 재확인 경로를 추가했다.
- `v1.3.15`에서는 profession 오버레이 tooltip 폭과 요약 표기를 정리했다.
- `v1.3.16` 직전 최신 사용자 피드백 기준으로는 구렁/던전 시체 약초채집 blank Lua 오류가 더 이상 재현되지 않았다.
- 따라서 지금 상태는 `최신 피드백 기준 no-repro, 관찰 유지`다.

## TODO

1. 재현 시점을 분리 확인
   - 채집 버튼을 누르자마자 뜨는지
   - 채집 성공 후 아이템이 들어간 직후 뜨는지
   - 채집 실패 메시지와 동시에 뜨는지

2. 애드온 격리 테스트
   - `ABProfileManager`만 켜고 동일 상황 재현
   - 그다음 GatherMate, HandyNotes, Plumber, TomTom, UI 패키지류를 하나씩 다시 켜며 재현

3. profession overlay 비활성화 테스트
   - `전문기술 오버레이 표시` 끔
   - 가능하면 메인 창도 열지 않은 상태로 재현
   - 이 상태에서 오류가 사라지면 현재 애드온 profession refresh 경로가 1순위

4. quest panel 생성 여부 테스트
   - 한 번도 `/abpm` 창을 열지 않은 fresh 로그인 상태에서 재현
   - 창을 연 뒤 재현
   - 차이가 나면 `QuestPanel` 또는 `ProfessionPanel` refresh 연쇄를 우선 본다

5. 방어 코드 추가 점검
   - `ProfessionKnowledgeOverlay:Refresh()`
   - `ProfessionPanel:Refresh()`
   - `QuestPanel:Refresh()`
   - 위 세 경로의 1차 보호가 실제 blank Lua 창을 멈추는지 재현으로 확인

6. 공통 호출기 정리
   - `ns:SafeCall()`을 실제로 안전하게 바꾸거나
   - UI refresh 전용 `SafeRefresh()` 래퍼를 추가

7. 로컬 디버그 메시지 추가
   - `QUEST_LOG_UPDATE`
   - `BAG_UPDATE_DELAYED`
   - `BAG_NEW_ITEMS_UPDATED`
   - `SKILL_LINES_CHANGED`
   - 어떤 이벤트 직후 터지는지 상태창이나 debug print로 남기기

8. blank Lua 창 원인 확인
   - 다른 오류 처리 애드온이 메시지를 먹는지 확인
   - BugSack/BugGrabber 또는 기본 `/console scriptErrors 1` 상태에서 원문 메시지 확보

## 우선순위

- P1: `ABProfileManager` 단독 재현 여부 확인
- P1: profession overlay 끈 상태 비교
- P2: 장기 운용 중 재발 여부 관찰
- P2: 이벤트별 debug trace 추가
- P2: 다른 애드온과 충돌 조합 식별

## 메모

- 이 이슈는 "다른 애드온 100%" 또는 "현재 애드온 100%"로 바로 단정할 단계는 아니다.
- 다만 현재 코드 구조상, 채집 후 발생하는 profession/quest refresh가 무방비 상태인 것은 명확한 리스크다.
