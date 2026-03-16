# ABProfileManager v1.4.2

릴리스 날짜: `2026-03-16`

## 요약

인게임 테스트에서 발견된 UI 버그 5건을 수정한 패치 릴리스입니다.

- 전문기술 오버레이 prefix 간격 완전 해소 (고정 너비 → 자동 크기)
- 전문기술 오버레이 히트박스·드래그·툴팁 범위가 시각 영역과 일치하도록 수정
- 퀘스트 후보 목록 스크롤이 아래로 내려가다 위로 튕기던 버그 수정
- 설정 탭 전투메시지 섹션 오버플로우 해소
- WoW 기본 설정 > 애드온 패널 전투메시지 섹션 오버플로우 해소

## 상세 변경

### 1. 전문기술 오버레이 — prefix 간격 (UI/ProfessionKnowledgeOverlay.lua)

**증상:** `1회성:          보물` 처럼 레이블과 값 사이에 불필요한 공백이 발생.

**원인:** `주  간:` / `1회성:` prefix FontString에 고정 너비(56px Korean, 74px English)를 설정했으나, 실제 텍스트 렌더링 너비(약 36~40px)보다 커서 TOPRIGHT 기준점이 텍스트 끝보다 오른쪽에 위치.

**수정:** `SetWidth()` 호출을 제거하여 WoW가 텍스트 실제 너비로 FontString을 자동 크기 조정하도록 변경. TOPRIGHT = 실제 텍스트 끝, 값 텍스트가 4px 간격으로 바로 옆에 배치.

### 2. 전문기술 오버레이 — 캔버스/히트박스/드래그 영역 (UI/ProfessionKnowledgeOverlay.lua)

**증상:** 툴팁이 오버레이 바깥에서 발동, 드래그앤드롭도 시각 영역 밖에서 동작, 히트박스가 실제보다 넓음.

**원인:** `contentWidth = 860` 하드코딩으로 각 row Frame이 860px 너비로 생성. 최종 프레임 너비(실제 콘텐츠 기준 측정값)보다 훨씬 넓어 row가 프레임 경계 밖으로 삐져나옴.

**수정:** `RefreshInternal()` 끝에 post-pass를 추가하여 최종 확정된 `width` 기준으로 각 row 너비와 내부 detail/summary FontString 너비를 재조정.

### 3. 퀘스트 후보 목록 스크롤 (UI/Widgets.lua)

**증상:** 스크롤박스를 아래로 내리면 다시 상단으로 튕겨 올라감.

**원인:** `CreateScrollEditBox`의 `OnCursorChanged` 핸들러가 클릭 시 커서 위치 y=0을 받아 `scrollFrame:SetVerticalScroll(0)`을 실행, 스크롤을 강제로 상단으로 초기화.

**수정:** `OnCursorChanged` 핸들러 시작부에서 `host.readOnly`일 때 즉시 return. readOnly 스크롤박스에서는 커서 이동이 스크롤 위치에 영향을 주지 않음.

### 4. 설정 탭 전투메시지 오버플로우 (UI/ConfigPanel.lua)

**증상:** 설정 탭의 전투메시지 아웃박스에서 표시 모드 버튼이 박스 아래로 잘림.

**원인:** `combatTextBox` 높이 기본값이 `overviewHeight`와 동일한 194px로, 내부 콘텐츠(힌트 텍스트 2줄 + 체크박스 2개 + 모드 레이블 + 버튼 3개) 총 높이 약 202px보다 작음.

**수정:** `Create()` 호출 시 `combatTextHeight = 214` 명시적으로 전달.

### 5. WoW 기본 설정 애드온 패널 전투메시지 오버플로우 (UI/ConfigPanel.lua)

**증상:** WoW 기본 설정 > 애드온 탭에서 전투메시지 섹션이 잘림.

**원인:** `RegisterSettingsCategory()` 의 `columnWidth = 300`(좁은 컬럼)에서 힌트 텍스트가 3줄로 늘어나고 체크박스 텍스트도 2줄로 늘어나 필요 높이 약 234px인데, `combatTextBox` 높이가 174px.

**수정:** `RegisterSettingsCategory()` 호출 시 `combatTextHeight = 244`, 패널 총 높이 700 → 720px 확대.

## 참고

- 로컬 패키지: `dist/ABProfileManager-v1.4.2.zip`
- 배포용 소개: [ABProfileManager/ADDON_INTRO.txt](./ABProfileManager/ADDON_INTRO.txt)
- 사용자 안내: [README.md](./README.md)
