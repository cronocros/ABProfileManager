# ABProfileManager v1.5.2

릴리스 날짜: `2026-03-29`

## 요약

BISOverlay 클릭 오류 수정과 드랍템 레벨 오버레이 문장 섹션 정리 릴리스.

- BISOverlay: 던전/아이템 행 hover 영역을 `Button`으로 바꿔 클릭 오류 수정
- ItemLevelOverlay: 우측 문장 패널 제거, `기타` 탭 문장 섹션 통합
- Locale/패키지 자산을 `v1.5.2` 기준으로 갱신

## 상세 변경

### 1. BISOverlay 클릭 오류 수정 (`UI/BISOverlay.lua`)

- `tooltipRegion` 타입을 `Frame`에서 `Button`으로 변경
- `RegisterForClicks("LeftButtonUp")` 호출 시 nil 오류가 나던 문제 해결
- 던전 헤더 클릭 → 모험 안내서 열기 경로를 안정화

### 2. 드랍템 레벨 오버레이 문장 섹션 정리 (`UI/ItemLevelOverlay.lua`)

- 프레임 오른쪽 자식 문장 패널 제거
- `기타` 탭 안에 "나의 문장" 섹션을 통합해 한 프레임 안에서 보이도록 단순화
- 기존 통화 ID 추정값 구조는 유지

### 3. 로케일 / 자산 업데이트

- `Locale_Additions.lua`에 문장 섹션 표기 키 보강
- `ABProfileManager.toc` 버전 `1.5.2` 반영
- `dist/ABProfileManager-v1.5.2.zip` 패키지 갱신

## 참고

- 로컬 패키지: `dist/ABProfileManager-v1.5.2.zip`
- Midnight 신규 던전 EJ ID는 여전히 일부 미확인 상태라 클릭 시 모험 안내서만 열리고 해당 던전으로 바로 이동하지 않을 수 있습니다.
- 문장 통화 ID는 영웅(3345) 외 일부가 추정값이라 인게임 검증이 남아 있습니다.
