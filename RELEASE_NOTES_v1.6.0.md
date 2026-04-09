# ABProfileManager v1.6.0

릴리스 날짜: 2026-04-09

## 요약

오버레이 스크롤 스케일링 기준점, 메인 UI 탭 텍스트 소실, BIS 오버레이 접기 복원, 오버레이 프레임 레이어 정리 등 UX 회귀를 일괄 수정한 핫픽스 릴리스입니다.

## 주요 변경

### 1. 오버레이 스크롤 스케일링 기준점 수정

- `BISOverlay`와 `ItemLevelOverlay`의 마우스 휠 크기 조절 시 기준점이 타이틀바(TOPLEFT)로 고정됩니다.
- 이전에는 프레임 중심 기준 + 잘못된 오프셋 변환으로 스크롤마다 위치가 들쑥날쑥했습니다.
- 수식을 `left * oldScale / newScale` 방식으로 교정해 연속 스크롤에서도 drift 없이 타이틀바 위치를 유지합니다.

### 2. 메인 UI 탭 텍스트 소실 수정

- 드루이드 등 특정 캐릭터로 접속 시 메인 UI 탭 글자가 보이지 않던 문제를 수정했습니다.
- `RefreshLocale()`에서 `SetText()` 호출 후 `UIPanelButtonTemplate`의 font object가 재적용되면서 커스텀 텍스트 색상이 초기화되는 현상이었습니다.
- `RefreshLocale()` 끝에 `applyTabSelectionStyles()`를 추가해 탭 선택 색상을 항상 재적용합니다.

### 3. BIS 오버레이 접기 상태 복원 수정

- 접은 상태로 닫았다가 다시 열었을 때, 콘텐츠는 숨겨지고 캔버스만 펼쳐져 있던 문제를 수정했습니다.
- `Refresh()` 내 `RebuildContent()`가 접힌 높이를 덮어쓰던 문제로, 재구성 후 접힌 상태면 `ApplyCollapse()`를 한 번 더 호출합니다.

### 4. 오버레이 프레임 레이어 정리

- `BISOverlay`와 `ItemLevelOverlay`의 FrameStrata를 `DIALOG` → `MEDIUM`으로 변경했습니다.
- 던전/공격대 창(PVEFrame)과 같은 레이어에 위치하므로, 캐릭터창이나 스킬창을 열면 자연스럽게 오버레이 위로 올라옵니다.

## 패키지

- 로컬 패키지: `dist/ABProfileManager-v1.6.0.zip`
