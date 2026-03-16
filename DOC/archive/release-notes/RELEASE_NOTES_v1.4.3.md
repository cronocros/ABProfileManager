# ABProfileManager v1.4.3

릴리스 날짜: `2026-03-16`

## 요약

인게임 테스트 결과를 반영한 UX 개선 릴리스입니다.

- 전문기술 오버레이 툴팁 리셋 잔여시간 문장 색상 추가
- 스탯 오버레이 쐐기 모드 표시 방식을 툴팁으로 이동
- 템플릿 목록 마우스 휠 스크롤 지원
- 설정 탭 노란 상태 메시지 제거 (개요 박스만으로 충분)
- 전문기술 재스캔 완료 시 OK 팝업 모달 표시
- ADDON_INTRO.txt 마케팅 관점 소개 텍스트로 전면 재작성

## 상세 변경

### 1. 전문기술 오버레이 툴팁 — 리셋 잔여시간 색상 (UI/ProfessionKnowledgeOverlay.lua)

목요일 오전 8시 리셋까지 잔여시간 문장이 일반 본문과 동일한 색상(off-white)으로 표시돼 눈에 띄지 않던 문제. `TOOLTIP_COLORS`에 `reset = {0.72, 0.92, 1.00}` (하늘색) 추가, 해당 줄에 적용.

### 2. 스탯 오버레이 — 쐐기 모드 표시 방식 변경 (UI/StatsOverlay.lua)

기존: 쐐기 모드 활성화 시 우선순위 레이블 앞에 `[쐐기] ` 문구가 붙어 가독성이 저하.
변경: 레이블은 스펙명만 유지, 툴팁에 `레이드` 또는 `쐐기` 모드명을 하늘색 줄로 표시.

### 3. 템플릿 목록 마우스 휠 스크롤 (UI/ProfilePanel.lua)

템플릿이 11개를 초과할 때 ▲/▼ 버튼만 있고 마우스 휠 스크롤이 없던 문제. `templatesBox` 및 각 row에 `OnMouseWheel` 핸들러를 추가하여 휠 업/다운으로 목록 오프셋을 조절.

### 4. 설정 탭 — 노란 상태 메시지 제거 (UI/ConfigPanel.lua)

요약 박스 위에 노란색으로 표시되던 설정 변경 상태 메시지 위젯 제거. 주 창 상태바(하단)와 요약 박스 내용으로 충분.

### 5. 전문기술 재스캔 완료 팝업 (UI/ProfessionPanel.lua, UI/ConfirmDialogs.lua)

재스캔 버튼 클릭 후 완료 피드백이 없던 문제. `ConfirmDialogs:ShowInfo()` 메서드와 `ABPM_INFO_MESSAGE` StaticPopup 추가. 재스캔 완료 시 전문기술명을 포함한 완료 메시지를 OK 모달로 표시.

### 6. ADDON_INTRO.txt 전면 재작성 (ABProfileManager/ADDON_INTRO.txt)

기술 목록 나열식에서 사용자 혜택 중심 마케팅 텍스트로 전면 재작성. 핵심 기능 5가지를 시각적으로 구분하고, 추천 대상과 시작 방법을 포함.

## 참고

- 로컬 패키지: `dist/ABProfileManager-v1.4.3.zip`
- 배포용 소개: [ABProfileManager/ADDON_INTRO.txt](./ABProfileManager/ADDON_INTRO.txt)
- 사용자 안내: [README.md](./README.md)
