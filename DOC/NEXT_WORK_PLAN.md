# Next Work Plan

기준 버전: `v1.4.0`

상태:
- 이 문서는 `v1.4.0` 구현 전후 설계/TODO 기록용 문서다.
- `v1.4.0`에서 지도 탭, typography, profession tooltip, 액션바 확인 모달, 전투메시지 재검증 보강은 반영되었다.
- 남은 항목은 후속 검증/보정 과제로 본다.

## 운영 원칙

- 메인 UI 레이아웃, profession overlay, 지도 overlay, 액션바 적용 흐름은 회귀 민감 영역으로 본다.
- 저장 구조는 기존 `ABPM_DB`와 호환성을 유지한다.
- 지도 기능은 UI 명칭은 `지도`로 확장하되, 1차 구현에서는 내부 `SilvermoonMap*` 명명 일부를 유지해 마이그레이션 리스크를 줄인다.
- 특수 기호(`●`, `✓`, `▶`, `→`, `·`)는 폰트 깨짐 제보가 있는 구간부터 plain text 또는 폰트 안전 표기로 치환한다.
- 글자 크기 조절은 개별 위젯 난립 방식이 아니라 `도메인별 typography 슬라이더` 체계로 통합한다.

## 팀 분배

- `control-lead`
  - 우선순위 승인, 작업 묶음 분리, 외부 의존성 허용 여부 결정
- `source-implementer`
  - 지도 탭 추가, 전역 typography 체계 도입, profession tooltip 개편, refresh 보강, 액션바 확인 모달 보강
- `source-reviewer`
  - SavedVariables 호환성, 전투 중 보호 프레임/taint, overlay 성능/겹침, 툴팁 폰트 회귀, 영어 줄바꿈 회귀 점검
- `doc-maintainer`
  - README, ARCHITECTURE, HANDOFF, RELEASE_NOTES, CHANGELOG 후속 반영

## 우선순위 TODO

### P0

1. 메인 창에 `지도` 탭을 추가하고, 기존 `설정` 탭의 지도 관련 제어를 새 탭으로 이동
2. 전역 typography 시스템 설계 및 모든 사용자 가시 텍스트 영역에 슬라이더 적용
3. 지도 오버레이 필터에 `평판상인` 추가
4. 다른 지도에도 포탈 위치를 표시할 수 있도록 데이터 구조 확장
5. 전문기술 오버레이 툴팁 문구를 사용자 친화형으로 재정의
6. 전문기술 오버레이 툴팁에 `목요일 리셋까지 몇시간 몇분` 형식의 정확한 남은 시간 표시
7. 전문기술 tooltip/패널 전반의 폰트와 기호 표기를 일관화
8. 영어 locale 전환 시 새 슬라이더/UI 문구와 줄바꿈 영향 검증
9. 전투메시지 `위로 / 아래로 / 부채꼴` 모드가 실제 최신 클라이언트에서 동작하는지 재검증하고 수정 설계 확정
10. 액션바 템플릿 관련 모든 실행 경로에 강제 확인 모달 적용

### P1

1. profession `드랍 / 논문 / 1회성` 갱신 누락 여부 재검증
2. 1회성 보물 좌표를 외부 자료와 대조해 재검증
3. 지도에 표시되는 평판상인 명칭을 전부 `평판상인`으로 통일
4. 와우 `설정 > 애드온` 하위 카테고리에도 `지도` 추가 여부 결정
5. 슬라이더 extreme 값에서 메인 UI, tooltip, overlay hitbox, label collision 검증
6. 기존 `scale` 저장값과 새 typography offset 저장값 마이그레이션 검증

### P2

1. 커스텀 waypoint + 빛기둥 UX 가능 범위 확정
2. TomTom 외 추가 의존성(`Waypoint UI`) 허용 여부 판단
3. 내부 명명(`SilvermoonMap*`)을 `MapOverlay*`로 정리할지 후속 리팩터링 판단

## 설계

### 1. 지도 탭 분리

목표:
- 지도 관련 설정을 `설정` 탭에서 분리해 `지도` 탭으로 이동한다.
- 지도 overlay 제어, 필터, 스케일 조절, 지도별 안내를 한 곳에 모은다.

영향 파일:
- `ABProfileManager/UI/MainWindow.lua`
- `ABProfileManager/UI/ConfigPanel.lua`
- `ABProfileManager/UI/AddonSettingsPages.lua`
- 신규 후보: `ABProfileManager/UI/MapPanel.lua`
- `ABProfileManager/Locale.lua`
- `ABProfileManager/Locale_Additions.lua`

구조안:
- `MainWindow`에 `map` 탭을 추가한다.
- `ConfigPanel`에서 지도 관련 block을 제거하고, `MapPanel`이 전담한다.
- `MapPanel`에는 아래 요소를 둔다.
  - 지도 overlay on/off
  - 지도 텍스트 슬라이더
  - 카테고리 체크박스
    - 시설
    - 포탈
    - 전문기술
    - 던전/공격대
    - 구렁
    - 평판상인
  - 지원 지도/주의사항 안내
- `AddonSettingsPages`에도 동일하게 `지도` 하위 카테고리를 추가할지 결정한다.
  - 권장: 추가
  - 이유: 현재 professions/quests만 분리되어 있어 지도만 빠지면 일관성이 깨짐

주의:
- 현재 `MainWindow`는 탭 5개 기준 폭으로 잡혀 있다. 탭이 6개가 되면 버튼 폭 재조정이 필요할 수 있으나 현재 창 폭 안에는 들어간다.
- `ConfigPanel` overview 텍스트에 들어가는 지도 설명도 새 탭 기준으로 문구 수정이 필요하다.

### 2. 전역 typography 시스템

목표:
- 사용자가 `전부다` 조절할 수 있다는 요구를 충족하되, 설정 UI가 과도하게 복잡해지지 않도록 도메인별 슬라이더로 묶는다.
- 메인 창, 설정, 탭 본문, 리스트, 도움말, tooltip, overlay를 전부 제어 가능한 구조로 바꾼다.

권장 도메인:
- 기본 UI 텍스트
  - 메인 창 제목 제외 본문 라벨, 리스트, 카드 설명, 상태 텍스트
- 툴팁 텍스트
  - profession tooltip, hover panel, 향후 map tooltip 포함
- 전문기술 오버레이 텍스트
- 스탯 오버레이 텍스트
- 지도 오버레이 텍스트

설정 UX:
- `지도` 탭에는 지도 텍스트 슬라이더를 둔다.
- `설정` 탭에는 나머지 typography 슬라이더를 유지하거나, 별도 `글자` 섹션으로 정리한다.
- 사용성 측면에서 권장되는 최종 구조:
  - `설정` 탭: 기본 UI, 툴팁, 전문기술 overlay, 스탯 overlay
  - `지도` 탭: 지도 overlay 전용

후보 신규 파일:
- `ABProfileManager/UI/Typography.lua`

영향 파일:
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
- `ABProfileManager/UI/AddonSettingsPages.lua`
- `ABProfileManager/DB.lua`
- `ABProfileManager/Data/Defaults.lua`
- `ABProfileManager/ABProfileManager.toc`

저장 구조 권장안:
- `global.settings.typography.uiOffset`
- `global.settings.typography.tooltipOffset`
- `ui.professionKnowledgeOverlay.fontSizeOffset`
- `ui.statsOverlay.fontSizeOffset`
- `global.settings.silvermoonMapOverlay.fontSizeOffset`

기존 scale와의 관계:
- `profession/stats overlay scale`는 1차에서는 읽기 호환 유지
- 새 `fontSizeOffset`이 있으면 그것을 우선 사용
- 없으면 기존 scale을 nearest offset으로 매핑
- 안정화 후 필요하면 legacy field 정리

왜 도메인별인가:
- 모든 텍스트를 개별 컨트롤로 두면 설정이 과도하게 복잡해진다.
- 실제 사용성은 `본문`, `툴팁`, `오버레이`, `지도` 정도로 나누는 것이 충분하다.
- 구현도 `Widgets`와 공통 helper 중심으로 흡수 가능하다.

### 3. 지도 오버레이 사용자 스케일

현재 상태:
- `SilvermoonMapOverlay`는 `point.size * categoryScale * densityScale * crowdScale * zoomScale`로 폰트 크기를 계산한다.
- 사용자 설정 기반 scale은 아직 없다.

영향 파일:
- `ABProfileManager/UI/SilvermoonMapOverlay.lua`
- `ABProfileManager/DB.lua`
- `ABProfileManager/Data/Defaults.lua`
- `ABProfileManager/UI/MapPanel.lua` 예정
- `ABProfileManager/UI/Typography.lua` 예정

설계안:
- 저장 위치는 `global.settings.silvermoonMapOverlay.fontSizeOffset` 또는 `fontSizeLevel` 같은 정수형 값이 더 적합하다.
- 사용자는 슬라이더로 조정하고, 실제 계산은 `1pt` 단위 정수 보정으로 처리한다.
- 현재 배치 로직이 폰트 크기에 민감하므로 `곱셈 배율`보다 `정수 offset`이 더 예측 가능하다.
- 권장 계산식:
  - `computedFontSize = floor((point.size * pointScale * densityScale * crowdScale * zoomScale) + 0.5)`
  - `finalFontSize = clamp(computedFontSize + userOffset, minFontSize, maxFontSize)`
- 권장 슬라이더 범위:
  - 최소 `-4`
  - 최대 `+8`
  - 조정 단위 `1`
- 범위를 이렇게 잡는 이유:
  - `-4`보다 작아지면 외부 지역 라벨과 영어 라벨 가독성이 급격히 나빠질 가능성이 큼
  - `+8`보다 커지면 dense map에서 충돌 비용이 급격히 증가하고 수동 offset 데이터가 무너지기 쉬움
- UI 표시는 `-4 ~ +8` 같은 내부 값보다 실제 설명형으로 같이 보여주는 편이 낫다.
  - 예: `현재 글자 크기 보정: +2`

리스크:
- 스케일이 커질수록 label overlap이 급증한다.
- zoom out 상태에서 `crowdScale`과 합쳐지면 특정 지도에서 과도하게 커질 수 있다.

완화:
- 사용자 offset 적용 후에도 `min/max font` clamp를 둔다.
- dense map에서는 상한을 한 번 더 clamp하는 방안 검토.
- extreme 값에서는 `manualWrap`/`noWrap` 라벨을 우선 재검토한다.

### 4. 모든 글자 크기 조절 UI의 슬라이더 전환

목표:
- 현재 `버튼 프리셋` 또는 고정 폰트로 되어 있는 모든 사용자 가시 텍스트를 slider 기반 typography 체계로 바꾼다.
- 조정 단위는 사용자가 체감 가능한 `1pt` 단위로 맞춘다.

대상 범위:
- 메인 창 탭 라벨
- 메인 창 status box
- Profile / ActionBar / Profession / Quest / Config 패널 본문
- Addon Settings 하위 카테고리 패널
- profession tooltip 및 hover panel
- 지도 오버레이
- 전문기술 오버레이
- 캐릭터 스탯 오버레이

현재 상태:
- profession/stats overlay는 `scale` 배율 저장 방식이다.
- map overlay는 아직 사용자 크기 제어가 없다.
- 메인 UI 본문은 `Widgets.lua`와 각 패널 개별 `SetFont`가 혼재한다.

권장 설계:
- 기본 UI는 공통 `uiOffset` 슬라이더로 묶는다.
- tooltip은 `tooltipOffset` 슬라이더로 별도 제어한다.
- `지도`는 font size offset 정수 슬라이더
- `전문기술 overlay`는 font size offset 정수 슬라이더 + 프레임 최소폭 자동 재계산
- `스탯 overlay`는 font size offset 정수 슬라이더 + 텍스트 폭 측정 기반 frame width 재계산

권장 범위:
- 기본 UI: `-2 ~ +5`, step `1`
- tooltip: `-2 ~ +5`, step `1`
- profession overlay: `-3 ~ +6`, step `1`
- stats overlay: `-2 ~ +6`, step `1`
- map overlay: `-4 ~ +8`, step `1`

왜 범위가 서로 다른가:
- 기본 UI와 tooltip은 창 폭과 체크박스 라벨 제약이 강해서 범위를 좁게 가져가는 편이 안전하다.
- profession/stats는 frame 내부 고정 레이아웃 비중이 커서 너무 작은 값/큰 값을 넓게 열면 overflow와 hitbox 문제가 빠르게 생긴다.
- map overlay는 위치 기반 텍스트라 축소/확대 자유도가 더 필요하지만, 충돌 제어를 위해 상한은 제한해야 한다.

호환성 방안:
- 기존 `scale` 저장값은 즉시 제거하지 않고 읽기 호환을 유지한다.
- 새 구현에서는 기존 배율 값을 nearest offset으로 한 번 매핑하거나, 새 값이 없을 때만 fallback으로 사용한다.

검증 항목:
- 최소값에서 한국어/영어 모두 읽을 수 있는지
- 기본 UI 체크박스와 버튼 라벨이 잘리지 않는지
- status box와 scroll text spacing이 유지되는지
- 최대값에서 profession detail line overflow가 없는지
- stats overlay의 프레임 폭, hitbox, drag 영역이 텍스트와 어긋나지 않는지
- map overlay collision 비용이 급격히 증가하지 않는지

### 5. 영어 locale 영향

현재 우려:
- 영어는 한국어보다 문자열 길이가 길어 `MapPanel`, profession tooltip, overlay summary, Addon Settings 하위 패널에서 줄바꿈이 더 쉽게 발생한다.
- 슬라이더 추가로 `현재 값 표시`, `최소/최대 설명`, `리셋 안내`가 들어가면 폭 압박이 더 커진다.

영향 파일:
- `ABProfileManager/Locale.lua`
- `ABProfileManager/Locale_Additions.lua`
- `ABProfileManager/UI/MapPanel.lua` 예정
- `ABProfileManager/UI/ProfessionKnowledgeOverlay.lua`
- `ABProfileManager/UI/ProfessionPanel.lua`
- `ABProfileManager/UI/AddonSettingsPages.lua`

검증 계획:
- `koKR`, `enUS`를 모두 전환해 각 슬라이더 레이블과 상태 메시지를 점검
- 영어 환경에서 다음을 별도 확인
  - 지도 탭 필터 체크박스 줄바꿈
  - profession tooltip 문장형 요약 줄바꿈
  - overlay row title wrap
  - Addon Settings subpanel 요약 문구 폭

완화:
- 길이가 긴 locale key는 설명/라벨을 분리한다.
- 체크박스 라벨은 필요 시 짧은 버전과 긴 툴팁 설명으로 나눈다.
- map filter는 2열 고정 대신 폭에 따라 세로 단일열 fallback도 검토한다.

### 6. 평판상인 표시와 지도별 포탈 확장

현재 상태:
- `SilvermoonMapData`에는 `renown` category가 이미 존재한다.
- 하지만 `getFilterKey()`는 `renown`을 별도 필터로 분기하지 않아 사실상 `facilities`에 묶인다.
- 포탈은 현재 실버문 쪽에만 집중돼 있고, 다른 지도에는 travel point가 거의 없다.

영향 파일:
- `ABProfileManager/Data/SilvermoonMapData.lua`
- `ABProfileManager/UI/SilvermoonMapOverlay.lua`
- `ABProfileManager/DB.lua`
- `ABProfileManager/UI/MapPanel.lua`
- `ABProfileManager/Locale*.lua`

설계안:
- `renown` 카테고리를 실제 독립 필터로 승격한다.
- 지도 데이터에서 평판상인 라벨은 세부 NPC명이 아니라 모두 `평판상인`으로 통일한다.
- 다른 지도의 주요 포탈도 `travel` category로 추가한다.
- 명명 규칙:
  - 내부 key는 개별 유지 가능
  - 사용자 노출 label은 동일하게 `평판상인`

리서치 작업:
- 어떤 지도에 어떤 포탈이 노출되어야 하는지는 실제 게임 동선 기준으로 다시 목록화가 필요하다.
- 데이터 추가 전, mapID/alias/nameAlias 충돌 여부를 점검한다.

### 7. profession tooltip 문구 개편

현재 문제:
- 상단 요약이 `주간 xx점 중 x점 획득 · 1회성 xx점 중 x점 획득` 형태라 직관성이 떨어진다.
- objective 목록도 `완료 퀘스트명`이 아니라 `완료: 퀘스트명`처럼 역할이 먼저 보여야 한다.
- TomTom 안내와 완료 항목 앞 기호가 일부 폰트에서 깨진다.

영향 파일:
- `ABProfileManager/UI/ProfessionKnowledgeOverlay.lua`
- `ABProfileManager/UI/ProfessionPanel.lua`
- `ABProfileManager/Locale_Additions.lua`
- `ABProfileManager/Locale.lua`

개편안:
- tooltip 상단 요약은 문장형으로 변경한다.
  - `주간 퀘스트로 획득 가능한 12P중 3P를 획득하셨습니다.`
  - `1회성으로 획득 가능한 44P중 15P를 획득하셨습니다.`
- reset 문구는 `목요일 리셋까지 00일 00시간 00분 남았습니다.` 또는 `00시간 00분 남았습니다.` 형식으로 통일한다.
- objective row 문구는 역할 우선 표기로 바꾼다.
  - `완료: 퀘스트명`
  - `미완료: 퀘스트명`
  - 필요 시 `획득처:` 같은 접두어도 동일 규칙으로 적용
- TomTom 안내와 완료 행 앞 기호는 glyph 의존을 줄인다.
  - 권장: `완료:`, `미완료:`, `TomTom 안내:` 같은 plain text
  - 비권장: `•`, `●`, `✓`, `▶` 계속 사용

폰트 일관성 설계:
- profession panel/overlay/tooltips는 공통 helper를 통해 한 폰트 경로와 flag를 사용한다.
- `Widgets.lua`에 typography helper를 추가하거나, profession 전용 helper를 재사용하도록 정리한다.
- `GameTooltip:AddLine` 기본 폰트와 custom `FontString:SetFont`가 섞여 있어서 시각 차이가 생길 수 있으므로 tooltip line builder도 통일이 필요하다.

### 8. profession refresh 재검증

현재 관찰:
- tracker는 hidden quest/완료 quest 기반으로 상태를 계산한다.
- `QUEST_LOG_UPDATE`, `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED` 등에서 refresh를 걸고 있다.
- 드랍/논문 누락 제보가 있다는 점에서, 실제 hidden quest 반영 타이밍과 refresh 타이밍이 안 맞을 가능성이 있다.

영향 파일:
- `ABProfileManager/Modules/ProfessionKnowledgeTracker.lua`
- `ABProfileManager/Events.lua`
- `ABProfileManager/UI/ProfessionKnowledgeOverlay.lua`
- `ABProfileManager/UI/ProfessionPanel.lua`
- `ABProfileManager/Data/ProfessionKnowledge.lua`

검증 TODO:
- 주간 퀘스트
- 논문
- 주간 드랍
- 채집 드랍
- 마력추출 드랍
- 1회성 보물
- 첫 발견
- 평판/풍요 보상

검증 설계:
- 구현 시 `debug audit` 출력 또는 상태 dump helper를 추가해 source별 questID와 complete 판정을 직접 볼 수 있게 한다.
- `LOOT_CLOSED` 직후 1회 refresh만으로 부족하면 짧은 지연 재확인 1회 추가를 검토한다.
- 각 objective가 `questIDs` 기반인지, `match = any/all`인지, 실제 게임에서 사용하는 hidden quest와 일치하는지 재검증한다.

리스크:
- Blizzard가 hidden quest ID를 바꾸면 데이터는 맞아도 갱신이 안 된다.
- 루팅 직후에는 quest flag 반영이 늦어 즉시 refresh에서 false가 나올 수 있다.

### 9. 1회성 보물 좌표 재검증

범위:
- `Data/ProfessionKnowledgeWaypoints.lua`
- profession tooltip/panel에 보이는 모든 one-time treasure 좌표

작업 기준:
- 실제 수정 전 최소 3개 출처 대조
  - Wowhead
  - Warcraft Wiki
  - profession 가이드 또는 좌표 애드온 데이터
- mapID, zone alias, 지역 진입 제한 여부를 함께 확인

주의:
- 하란다르/공허폭풍처럼 별도 지역 컨텍스트가 필요한 항목은 좌표만 맞아도 waypoint 생성 조건이 다를 수 있다.
- 좌표 오차인지, mapID 오차인지, TomTom/지역 제한 문제인지 분리해서 봐야 한다.

### 10. 전투메시지 부채꼴 모드 재검증

현재 상태:
- 코드상으로는 `floatingCombatTextFloatMode_v2` 우선, 구형 `floatingCombatTextFloatMode` fallback으로 쓰고 있다.
- 값 매핑은 현재 `1=위로`, `2=아래로`, `3=부채꼴`로 가정하고 있다.
- 사용자 제보는 `이전 구현이 실제로 동작하지 않는다`는 것이다.

확인한 자료:
- Warcraft Wiki의 Patch 12.0.0 API 변경 문서에 `floatingCombatTextFloatMode_v2`가 추가된 것으로 나온다.
  - https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes
- Warcraft Wiki의 CVar 데이터에도 `floatingCombatTextFloatMode` / 관련 v2 CVar가 존재한다.
  - https://warcraft.wiki.gg/wiki/Module:API_info/cvar/data
- Blizzard 공식 포럼에서도 최신 클라이언트는 `_v2` CVar를 직접 써야 하는 사례가 확인된다.
  - https://us.forums.blizzard.com/en/wow/t/floating-combat-text/2241907

위 자료를 바탕으로 한 현재 추론:
- CVar 이름 자체는 현 코드 방향이 크게 틀렸을 가능성은 낮다.
- 실제 미동작 원인은 아래 후보를 우선 의심한다.
  - `floatMode` 값 매핑이 현재 클라이언트 체감과 다를 가능성
  - `enableFloatingCombatText` / damage / healing / directionalDamage와의 조합 문제
  - 설정 직후 즉시 체감되지 않고 재로드/재로그인 후 반영되는 클라이언트 특성
  - 다른 애드온 또는 클라이언트 내 숨은 옵션이 CVar를 덮어쓰는 문제

구현 전 검증 TODO:
- `/console floatingCombatTextFloatMode_v2 1/2/3` 수동 테스트
- 애드온 UI 버튼과 실제 CVar 값이 일치하는지 로그 확인
- `directionalDamage` on/off 조합에서 부채꼴 체감이 달라지는지 확인
- 로그인, 월드 진입, ReloadUI 후 재적용 여부 확인
- `_v2`와 구형 CVar가 동시에 존재할 때 우선순위가 안전한지 재검토

설계 보강:
- 상태 패널에 현재 읽힌 실제 CVar 이름과 값을 debug 모드에서 노출하는 방안 검토
- 필요하면 `ApplyConfiguredSettings()` 직후 `ReadCurrentSettings()` 재검증을 붙여 적용 실패를 감지
- `부채꼴` 설명 문구를 시각적으로 더 분명하게 바꿔 사용자가 기대하는 효과와 다른지 구분할 수 있게 한다

### 11. 액션바 템플릿 강제 확인 모달

현재 상태:
- 일부 경로는 `ConfirmDialogs`를 쓰고 있으나, 확인 창 호출 지점이 제한적이다.
- 현재 검색 기준 사용 중 확인 모달은 주로 template overwrite/delete, quest cleanup 쪽에 몰려 있다.

영향 파일:
- `ABProfileManager/UI/ConfirmDialogs.lua`
- `ABProfileManager/Modules/ProfileManager.lua`
- `ABProfileManager/UI/ActionBarPanel.lua`
- `ABProfileManager/Commands.lua`
- 필요 시 `Modules/TemplateSyncManager.lua`, `Modules/UndoManager.lua`, `Modules/TemplateTransfer.lua`

설계안:
- 액션바/템플릿 관련 실행은 모두 `mandatory confirm wrapper`를 거치게 한다.
- 확인 대상 후보:
  - 템플릿 저장 overwrite
  - 템플릿 삭제
  - 템플릿 적용
  - 범위 적용
  - 비교 후 sync 실행
  - fill empty / clear extras / exact sync
  - undo
  - import
  - slash command 기반 destructive action
- 문구는 실행 대상과 범위를 함께 보여준다.
  - 예: 현재 캐릭터 / 선택 바 / 슬롯 범위 / clear 여부

리스크:
- 전투 중 대기열과 확인창이 섞이면 사용자가 실행 상태를 오해할 수 있다.
- 확인 후 combat lockdown으로 즉시 실행이 안 되는 경로는 상태 메시지를 함께 정리해야 한다.

### 12. 빛기둥 waypoint 가능 여부

현재 판단:
- `ABProfileManager` 단독으로 사용자가 원하는 임의 좌표에 `나만 보이는 커스텀 3D 빛기둥`을 월드에 직접 렌더링하는 것은 현실적으로 어렵다.
- 이유:
  - WoW의 기본 `World Marker`는 파티/공격대용 world marker이며 개인 전용 arbitrary beacon과는 다르다.
  - API도 `PlaceRaidMarker` 같은 protected world marker 계열이라 현재 요구와 정확히 맞지 않는다.
- 대신 대안은 있다.
  - TomTom류 waypoint/arrow 연동
  - `Waypoint UI` 같은 외부 애드온과의 연동 검토

대안 설계:
- 최소안
  - 현행 TomTom waypoint + arrow 유지
- 확장안
  - `Waypoint UI`가 공개 연동 지점을 제공하면 그쪽 beam형 marker를 추적 대상으로 연결
- 보류안
  - 외부 의존성 없이 커스텀 beam 구현은 목표에서 제외

외부 확인 출처:
- [World Marker - Warcraft Wiki](https://warcraft.wiki.gg/wiki/World_Marker)
- [World of Warcraft API - Warcraft Wiki](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API)
- [Waypoint UI - CurseForge](https://www.curseforge.com/wow/addons/waypointui/description)
- [Waypoint UI Replaces WoW’s Navigation Frame - Icy Veins](https://www.icy-veins.com/wow/news/waypoint-ui-replaces-wows-navigation-frame-and-it-looks-clean/)

위 출처를 기준으로 한 추론:
- 기본 API 쪽은 raid/world marker 중심이고,
- beam형 시각효과는 외부 네비게이션 애드온이 자체 UX로 제공하는 영역이다.

### 13. 의존성 / 엣지케이스 점검

핵심 의존성:
- WoW 기본 UI API
- TomTom optional dependency
- 잠재적 추가 후보: `Waypoint UI`

예상 문제:
- 지도 scale 증가 시 라벨 겹침
- slider 최소/최대값에서 영어 문구 overflow
- 기존 scale 저장값과 새 font offset 저장값 공존에 따른 migration 문제
- 개별 패널에서 직접 `SetFont` 하는 코드가 남아 typography helper를 우회할 가능성
- tooltip과 overlay가 서로 다른 font flag를 써 시각적 일관성이 깨질 가능성
- 새 `평판상인` 필터 추가 후 기존 저장값과의 호환성
- profession tooltip 문자열 길이 증가로 tooltip 폭/줄바꿈 재조정 필요
- glyph 제거 시 locale 문자열 전체 재정비 필요
- hidden quest 반영 지연
- actionbar confirm 추가 후 사용 흐름이 길어질 수 있음
- 전투 중 protected action/queue 상태 메시지 혼선

필수 점검 항목:
- 한국어/영어 locale 동시 반영
- 저장값 migration default 처리
- typography helper를 모든 주요 패널이 실제로 사용하도록 통일됐는지
- overlay strata / frame level
- WorldMap 열림/닫힘 refresh 비용
- TomTom 미설치 시 degrade 동작
- profession tooltip line count 증가에 따른 tooltip 폭/성능

## 구현 시작 전 체크리스트

1. `지도 탭 분리`와 `지도 글자 슬라이더`를 같은 브랜치/같은 PR로 묶을지 결정
2. 기본 UI/tooltip/profession/stats/map 전부를 같은 typography 도입 PR로 묶을지 결정
3. `평판상인 + 포탈 데이터 확장`은 UI 작업과 분리할지 결정
4. profession refresh는 먼저 `audit/debug`를 넣고 고칠지, 바로 이벤트 경로를 손볼지 결정
5. 전투메시지 부채꼴 모드는 실제 클라이언트 테스트 우선인지, 코드 정리 우선인지 결정
6. `Waypoint UI` 연동은 optional dependency로 허용할지 사용자 승인 필요
7. treasure 좌표 검증은 외부 자료 확인 시간을 별도 확보할지 결정

## 현재 결론

- 다음 구현 묶음의 1순위는 `지도 탭 분리 + 전역 typography 슬라이더 + 평판상인 필터 분리`다.
- 크기 조절 UX는 기존 preset 버튼보다 slider가 맞지만, `1pt 단위` 요구 때문에 기본 UI/tooltip/map/profession/stats 전부 레이아웃 재검증이 동반된다.
- profession 영역은 단순 문구 수정으로 끝나지 않고 `refresh 신뢰도 점검 + font/glyph 정리 + 영어 폭 검증`을 같이 해야 한다.
- 전투메시지 `부채꼴`은 CVar 이름보다 `적용 타이밍/값 매핑/클라이언트 체감` 쪽을 다시 확인하는 게 우선이다.
- `빛기둥`은 기본 API만으로는 요구한 형태를 그대로 충족시키기 어렵고, 외부 애드온 연동 여부를 먼저 결정해야 한다.
- 액션바 확인 모달은 전 경로 강제 적용이 맞다.
