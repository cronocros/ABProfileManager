# ABProfileManager v1.5.7

릴리스 날짜: 2026-03-30

## 요약

이번 릴리스는 인게임 QA 기준으로 `BIS 인던 드랍 정보`의 현재 시즌 정확도를 다시 정리하고, `드랍템 레벨 정보`와 `시즌 최고기록` 오버레이 디자인을 다듬은 로컬 QA 핫픽스입니다.

## 주요 변경

### 1. BIS 인던 드랍 정보

- `Data/BISData_Method.lua` 하단의 예전 수기 BIS 병합을 제거해, 현 시즌 Method 데이터 뒤에 이전 시즌/타 스펙 대체재가 섞이던 문제를 차단했습니다.
- `UI/BISOverlay.lua`는 `sourceType`와 `sourceLabel`을 다시 해석해 잘못 태깅된 던전 항목을 `mythicplus` 경로로 되돌립니다.
- 영어 source label은 가능한 한 한글 던전/레이드/제작 이름으로 정규화하고, 끝까지 해석되지 않으면 최소한 `레이드` / `제작`처럼 소스 타입명으로 정리합니다.
- BIS 아이템 클릭은 `itemID -> instanceID/encounterID` 해석을 우선 사용하도록 바꿔, 던전/레이드 loot 탭 랜딩을 보강했습니다.

### 2. BIS 툴팁 현재 시즌 처리

- `mythicplus`와 `raid`는 Encounter Journal preview link가 현재 시즌 범위 안에 들어올 때만 실제 시즌 툴팁을 사용합니다.
- 검증되지 않는 `raid/crafted` 항목은 잘못된 저레벨 raw item tooltip 대신 현재 시즌 레이드/제작 아이템 레벨 요약을 표시합니다.
- 귀환 던전 구아이템은 item age로 필터링하지 않고, source provenance와 preview validation 기준으로만 처리합니다.

### 3. 드랍템 레벨 정보

- `ItemLevelOverlay` 전체 폭과 `위대한 금고` 열을 더 넓혀 잘림을 줄였습니다.
- 우측 `나의 열쇠` 패널의 `오늘의 풍요` 줄 폰트를 한 단계 낮춰 패널 밀도를 정리했습니다.

### 4. 파티찾기 시즌 최고기록

- `MythicPlusRecordOverlay`는 더 이상 아웃박스를 쓰지 않고, 던전 아이콘 위에 `평점`과 `최고기록 시간`만 투명 오버레이로 표시합니다.
- 기존 `단수` 텍스트는 제거했습니다.

## 패키지

- 로컬 패키지: `dist/ABProfileManager-v1.5.7.zip`
