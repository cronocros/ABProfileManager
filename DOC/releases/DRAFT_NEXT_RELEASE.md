# 다음 릴리스 임시 기록

이 파일은 정식 릴리스 노트를 쓰기 전까지만 두는 작업 메모입니다. 사용자 배포용 문장이 아니라 무엇을 왜 고쳤는지 남기는 용도이며, 정식 노트를 만들 때 이 파일은 지웁니다.

기준 버전은 `ABProfileManager/ABProfileManager.toc`의 `## Version`을 따릅니다. 아래 항목은 아직 릴리스되지 않은 작업분입니다.

## 2026-09-04 작업분

### 월드 이벤트 데이터와 주기 모델 (W7)

`Data/WorldEventSchedule.lua`, `UI/WorldEventOverlay.lua`

데이터가 시즌 1 기준이라 이벤트 이름, 지역, 주기가 모두 실제와 달랐습니다.

- 이벤트 키와 이름을 실제 값으로 교체했습니다. `saltherilsSoiree`(살데릴의 연회), `stormarionAssault`(스토마리온 공격), `abundance`(풍요), `haranirLegends`(하라니르의 전설)입니다. 이전 값은 `Saldeeryl's Court`, `Stomarion Assault`, `Legend of Haranyr`였습니다.
- mapID를 `2395`(영원노래 숲), `2405`(공허폭풍), `2413`(하란다르)로 맞췄습니다. 이전의 `2444`는 공허폭풍 하위 지도였고, 풍요에 붙어 있던 `2393`은 실버문이라 관련이 없었습니다.
- 풍요는 고정 지역이 없어 4개 동굴을 `rotation` 목록으로 옮겼습니다. 좌표는 외부 가이드 두 곳이 일치한 값입니다.
- 분 단위 `interval`/`duration`/`offset` 단일 모델을 `cadence` 모델(`weekly`, `interval`, `rotating`)로 바꿨습니다. 네 이벤트 중 어느 것도 이전 모델과 맞지 않았습니다.
- 오버레이 판정 순서는 `areaPoiID` 런타임 조회, 주간 리셋 카운트다운, 검증된 기준시각 계산 순입니다. 어느 것도 풀리지 않으면 `미확인`으로 표시하고 카운트다운을 만들어내지 않습니다.
- 카운트다운 포맷의 `시간`/`분`/`초`가 소스에 하드코딩돼 있어 영어와 러시아어에서도 한국어로 나왔습니다. 로케일 키 3종으로 옮겼습니다.

오버레이는 여전히 TOC에 없어 비활성입니다. 기준시각 실측이 남아 있습니다.

### 전문기술 주간 퀘스트 questID 누락 (W4)

`Data/ProfessionKnowledge.lua`

주간 퀘스트 변형 목록은 `match = "any"`라 그 주에 걸린 변형 하나만 완료하면 됩니다. 목록에서 questID가 빠져 있으면 그 주에는 완료를 감지하지 못합니다.

DB2 `QuestV2`(빌드 `12.1.0.69465`)로 주간 questID 72개를 대조하다 누락 4개를 찾아 채웠습니다.

| 직업 | questID | 퀘스트 이름 |
| --- | --- | --- |
| 마법부여 | 93697 | Shimmering Melodies |
| 약초채집 | 93701 | Brittle and Brilliant |
| 채광 | 93707 | It's Called Silvermoon |
| 무두질 | 93713 | Essential Materials |

이제 questID 블록이 연속 구간으로 맞습니다. 제작 7종 `93690~93696`, 마법부여 `93697~93699`, 약초채집 `93700~93704`, 채광 `93705~93709`, 무두질 `93710~93714`입니다.

### 러시아어 번역 (W5b)

`ABPM_ruRU_Final_v3.lua`, `scripts/validate_locale_contract.py`

`enUS` 대비 비어 있던 143개를 채웠습니다. 검증기의 `RURU_MISSING_BASELINE`을 `143`에서 `0`으로 내려, 앞으로 새 문자열에 러시아어를 빠뜨리면 검증이 바로 실패합니다.

## 2026-09-04 메모리 누수 수정

에이전트 4팀으로 나눠 메모리 점검을 돌리고, 영구 증가하는 누수 5건과 시한폭탄 1건을 고쳤습니다. 전체 조사 결과는 `DOC/TODO.md` 3-1장에 있습니다.

- `UI/BISOverlay.lua` — `GET_ITEM_INFO_RECEIVED`에는 필터가 없어 세션 내 모든 아이템 로드가 들어옵니다. 그런데 캐시 기록이 `requested` 게이트 바깥에 있어 BIS와 무관한 아이템까지 링크 캐시에 쌓였고, 비우는 경로도 없었습니다. 게이트 안으로 옮겼습니다.
- `Modules/GhostManager.lua` — 고스트 오버레이 프레임을 풀로 재사용합니다. WoW 프레임은 회수되지 않는데 해소 시 참조만 버리고 있어, 템플릿 적용과 해소를 반복할 때마다 숨은 프레임이 영구히 쌓였습니다.
- `Modules/BlizzardFrameManager.lua` — `HookScript("OnDragStop")`을 1회만 겁니다. 해제할 수 없는 훅이라 창 이동 기능을 껐다 켤 때마다 누적됐습니다.
- `UI/WorldEventOverlay.lua` — 접힘, 비활성, 던전 자동 접기, 월드 이탈에서 TomTom 경로점을 정리합니다. 이전에는 정리가 `UpdateContent` 맨 끝에만 있어 그 네 경로에서 화살표가 남았습니다.
- `DB.lua` — `worldEventCompletions`가 `키_날짜` 형태라 만료 없이 쌓였습니다. `{ [eventKey] = "YYYY-MM-DD" }`로 바꿔 키 개수를 이벤트 수로 고정했습니다.
- `Data/Defaults.lua` — `mythPreviewCache` 기본값에 실제 데이터와 다른 값이 박혀 있어, `MergeDefaults`가 로그인마다 되채우고 그때마다 캐시가 통째로 폐기되는 구조였습니다. 빈 테이블로 바꿨습니다. 지금은 selector가 비어 있어 드러나지 않지만 `12849`를 넣는 순간 발현할 결함이었습니다.

## 2026-09-04 고빈도 경로 할당 정리

동작은 그대로 두고 초당 할당량만 줄인 수정입니다. 전투 중 프레임 하락과 GC 스파이크에 영향을 줍니다.

- `Events.lua` — 유닛 이벤트 3종을 `RegisterUnitEvent(..., "player")`로 등록합니다.
- `UI/StatsOverlay.lua` — `pcall`에 넘기던 익명 클로저 5개를 모듈 레벨 함수로 뺐습니다.
- `UI/Typography.lua` — `ApplyFont`가 등록 항목을 재사용합니다.
- `ABPM_ruRU_Final_v3.lua` — 치환 전에 평문 `find`로 걸러내고, 스크래치 버퍼를 재사용하고, 툴팁 후처리를 실제 줄 수까지만 돌립니다.
- `Events.lua` — 전문기술 즉시 스캔을 화면이 보일 때로 제한했습니다.
- `Core.lua` — `RefreshUI`가 현재 탭만 갱신합니다.
- `UI/BISOverlay.lua` — 던전명 해석에 메모를 붙였습니다.

## 사용자에게 보일 만한 항목

정식 노트를 쓸 때는 아래 세 줄이면 충분합니다. 나머지는 내부 정리입니다.

- 전문기술 주간 퀘스트 일부가 완료로 잡히지 않던 문제를 고쳤습니다.
- 러시아어 번역을 모두 채웠습니다.
- 월드 이벤트 데이터를 현재 시즌 기준으로 정리했습니다. 해당 오버레이는 아직 꺼져 있습니다.
- 오래 접속해 있을 때 애드온이 메모리를 계속 붙잡던 문제 몇 가지를 고쳤습니다.
- 전투 중과 창을 열어 둔 상태에서 애드온이 쓰던 자원을 줄였습니다.
