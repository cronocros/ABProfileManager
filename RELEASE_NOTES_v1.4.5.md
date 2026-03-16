# ABProfileManager v1.4.5

릴리스 날짜: `2026-03-17`

## 요약

인게임 테스트 결과 반영 — AH 필터 재구현 및 쐐기 체크박스 임시 숨김 처리.

- 경매장 확장팩 필터: BrowseSidebar 접근 방식 → 프레임 계층 재귀 탐색 방식으로 재구현
- 스탯 오버레이 쐐기(M+) 체크박스 설정 탭에서 숨김 처리 (기능 코드는 유지, UI만 비노출)
- ADDON_INTRO.txt 쐐기 모드 전환 문구 제거
- DOC/HANDOFF.md 미완성 기능 섹션 추가 (쐐기 모드, AH 필터 재개 안내 포함)

## 상세 변경

### 1. 경매장 필터 재구현 (Events.lua)

`AuctionHouseFrame.BrowseSidebar` 접근이 동작하지 않는 것을 확인. `findAndActivateExpansionCheckbox` 함수로 대체: `AuctionHouseFrame`을 루트로 depth 8까지 재귀 탐색하여 `GetChecked/SetChecked`를 가진 프레임 중 "현행 확장팩 전용" / "Current Expansion Only" 텍스트를 찾아 클릭. `pcall` 래핑 유지.

### 2. 쐐기 체크박스 숨김 (UI/ConfigPanel.lua)

`refs.mythicPlusCheck:Hide()` 추가. DB/Locale/Bind/Refresh 코드는 그대로 유지하여 나중에 `:Show()`만으로 복구 가능. `generalHeight` 420으로 복구.

### 3. ADDON_INTRO.txt 정리

"레이드(PvE) / 쐐기(M+) 우선순위 모드 전환" 항목 제거.

### 4. DOC/HANDOFF.md 미완성 기능 섹션 추가

쐐기 모드 재개 체크리스트 및 AH 필터 `/dump` 디버깅 안내 포함.

## 참고

- 로컬 패키지: `dist/ABProfileManager-v1.4.5.zip`
- 미완성 기능 기록: [DOC/HANDOFF.md](./DOC/HANDOFF.md)
