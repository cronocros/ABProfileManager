# ABProfileManager v1.4.6

릴리스 날짜: `2026-03-17`

## 요약

경매장 AH 필터 디버깅 결과 반영 — 미작동 확인으로 체크박스 UI 숨김 처리 및 디버그 기록 보완.

- 경매장 현 확장팩 필터 체크박스 설정 탭에서 숨김 (기능 코드는 유지, UI만 비노출)
- Events.lua AH 필터 재구현: 텍스트 기반 → 필터 버튼 클릭 + visible CheckButton 타겟팅 방식
- Commands.lua `/abpm ahdebug` 디버그 명령어 확장 (names / checks / find 모드)
- DOC/HANDOFF.md 경매장 필터 디버깅 결과 상세 기록

## 상세 변경

### 1. 경매장 필터 체크박스 숨김 (UI/ConfigPanel.lua)

`refs.auctionHouseFilterCheck:Hide()` 추가. 인접한 statsOverlayCheck의 앵커를 mouseMoveRestoreCheck로 재연결해 레이아웃 공백 제거. DB/Locale/이벤트 코드는 그대로 유지하여 나중에 `:Show()`로 복구 가능.

### 2. AH 필터 구현 방식 변경 (Events.lua)

이전: `GetText()` 기반 텍스트 탐색 → WoW 보안 시스템의 "secret string value tainted" 오류로 동작 불가.

현재: 2단계 방식.
1. "필터"/"Filter" 텍스트 버튼 탐색 → 클릭 (텍스트 접근 가능)
2. 0.35초 후 `AuctionHouseFrame` 하위에서 Auctionator 프레임 제외 + visible CheckButton 탐색 → 클릭

### 3. 디버그 명령어 확장 (Commands.lua)

`/abpm ahdebug <mode>`:
- `(기본)`: AuctionHouseFrame depth 10 텍스트 스캔
- `ui`: UIParent visible 자식 depth 6 텍스트 스캔
- `names`: AuctionHouseFrame depth 12 프레임 이름 스캔
- `checks`: AuctionHouseFrame depth 12 CheckButton 타입 스캔
- `find <keyword>`: UIParent visible 자식 depth 12 키워드 탐색

### 4. HANDOFF.md 업데이트

경매장 필터 디버깅 전 과정 기록:
- Auctionator 애드온 AH UI 교체 확인
- WoW 보안 시스템으로 텍스트 접근 차단 확인
- 현재 구현 방식 및 미해결 문제 기록
- 재개 체크리스트 추가

## 참고

- 로컬 패키지: `dist/ABProfileManager-v1.4.6.zip`
- 미완성 기능 기록: [DOC/HANDOFF.md](./DOC/HANDOFF.md)
