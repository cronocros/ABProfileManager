# ABProfileManager v1.4.4

릴리스 날짜: `2026-03-17`

## 요약

인게임 테스트 결과를 반영한 스탯 오버레이 수정 및 경매장 신기능 릴리스입니다.

- 스탯 오버레이 M+ 우선순위 데이터 단순화 (탱커 전용 오버라이드만 유지)
- 스탯 오버레이 쐐기 모드 툴팁 표시 방식 수정
- 경매장 현 확장팩 필터 자동 선택 체크박스 신규 추가

## 상세 변경

### 1. 스탯 오버레이 — M+ 우선순위 데이터 수정 (Data/StatPriorities.lua)

기존: 비탱커 특성까지 M+ 오버라이드 항목이 있어 모든 특성이 유연 1위로 잘못 표시되는 현상.
변경: `ns.Data.StatPrioritiesMythicPlus` 테이블을 탱커 6개 특성(방어 전사, 방어 성기사, 혈기 죽기, 양조 수도사, 수호 드루이드, 복수 악사)만 유연 우선으로 유지. 비탱커는 PvE 테이블로 폴백.

### 2. 스탯 오버레이 — 쐐기 모드 툴팁 수정 (UI/StatsOverlay.lua)

기존: 우선순위 행 툴팁에서 `AddLine`으로 쐐기/레이드 모드 문자열을 기존 내용 아래에 추가.
변경: 툴팁 타이틀 문자열에 `[쐐기]` / `[레이드]` 를 합친 뒤 `SetText` 호출. `AddLine` 블록 제거.

### 3. 경매장 현 확장팩 필터 자동 선택 (Events.lua, DB.lua, Data/Defaults.lua, Locale_Additions.lua, UI/ConfigPanel.lua)

설정 탭에 "경매장 열 때 현재 확장팩 탭 자동 선택" 체크박스 추가.
`AUCTION_HOUSE_SHOW` 이벤트를 수신해 0.2초 딜레이 후 `AuctionHouseFrame.BrowseSidebar`의 ScrollBox를 순회, `expansionLevel`이 `GetExpansionLevel()`과 일치하는 카테고리 항목을 클릭. pcall 래핑으로 UI 구조가 달라도 에러 없이 실패.

## 참고

- 로컬 패키지: `dist/ABProfileManager-v1.4.4.zip`
- 배포용 소개: [ABProfileManager/ADDON_INTRO.txt](./ABProfileManager/ADDON_INTRO.txt)
- 사용자 안내: [README.md](./README.md)
