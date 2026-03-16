# ABProfileManager v1.4.2

릴리스 날짜: `2026-03-16`

## 요약

인게임 테스트 기반 UI 버그 수정 + 스탯 오버레이 기능 확장 릴리스입니다.

**버그 수정 (5건):**
- 전문기술 오버레이 prefix 간격 완전 해소 (고정 너비 → 자동 크기)
- 전문기술 오버레이 히트박스·드래그·툴팁 범위가 시각 영역과 일치하도록 수정
- 퀘스트 후보 목록 스크롤이 아래로 내려가다 위로 튕기던 버그 수정
- 설정 탭 전투메시지 섹션 오버플로우 해소
- WoW 기본 설정 > 애드온 패널 전투메시지 섹션 오버플로우 해소

**설정 탭 개선 (4건):**
- 일반 설정 설명 텍스트와 타이틀 겹침 수정
- 확인 체크박스 설명에 "템플릿 적용 또는 비우기 전에" 문구 명시
- 스탯 오버레이 탱커 방어스탯 표시 여부 체크박스 추가
- 스탯 오버레이 PvE/쐐기 우선순위 모드 체크박스 추가

**기타:**
- 지도 오버레이 글자 크기 슬라이더 최대값 상향 (12 → 20)
- Icy Veins 기반 쐐기(M+) 전용 스탯 우선순위 테이블 추가 (탱크 버서틸리티 우선, 일부 딜러 헤이스트 우선)

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

### 6. 설정 탭 — 일반 설정 설명 텍스트 위치 (UI/ConfigPanel.lua)

**증상:** 일반 설정 아웃박스 안의 언어 안내 텍스트가 박스 타이틀과 겹쳐 보임.

**수정:** `languageHint` anchor를 박스 TOPLEFT 기준 y=-18에서 `generalBox.title` BOTTOMLEFT 기준 y=-10으로 변경.

### 7. 확인 체크박스 설명 문구 개선 (Locale_Additions.lua)

**변경:** "최종 확인 창 표시" → "템플릿 적용 또는 비우기 전에 최종 확인 창 표시"로 동작을 명확히 기술.

### 8. 탱커 방어스탯 표시 체크박스 (UI/ConfigPanel.lua, UI/StatsOverlay.lua, DB.lua)

스탯 오버레이에서 탱커 특성일 때 회피/반격/막기 수치 표시 여부를 설정 탭 체크박스로 제어할 수 있게 추가. 기본값: 표시.

- `DB:IsStatsOverlayTankStatsEnabled()` / `DB:SetStatsOverlayTankStatsEnabled()` 추가
- `shouldShowTankDefensiveStats()` 에서 DB 설정을 참조하도록 변경

### 9. 쐐기(M+) 스탯 우선순위 모드 (UI/ConfigPanel.lua, UI/StatsOverlay.lua, Data/StatPriorities.lua, DB.lua)

스탯 오버레이에서 PvE(레이드)와 쐐기(M+) 우선순위를 전환하는 체크박스 추가. Icy Veins 기반 M+ 전용 테이블(`ns.Data.StatPrioritiesMythicPlus`) 추가. 기본값: PvE 모드.

M+ 주요 변경점:
- 탱크 특성(Blood DK, Protection Warrior/Paladin, Brewmaster, Guardian, Vengeance): 버서틸리티 우선
- Elemental Shaman, Balance Druid: 헤이스트 우선
- PvE와 동일한 스펙은 nil(fallback)으로 처리

### 10. 지도 오버레이 글자 크기 슬라이더 최대값 상향 (DB.lua)

`mapOverlay` typography 범위를 max=12 → max=20으로 확대.

## 참고

- 로컬 패키지: `dist/ABProfileManager-v1.4.2.zip`
- 배포용 소개: [ABProfileManager/ADDON_INTRO.txt](./ABProfileManager/ADDON_INTRO.txt)
- 사용자 안내: [README.md](./README.md)
