# ABProfileManager v1.5.4

릴리스 날짜: `2026-03-30`

## 요약

인게임 QA를 반영해 BIS 시즌 툴팁, 드랍템 레벨 오버레이, 설정 UI를 다시 다듬은 후속 릴리스입니다.

- BISOverlay: Encounter Journal 시즌 preview hyperlink를 우선 사용해 한밤 시즌 1 M+ preview 기준 아이템레벨/스탯 툴팁을 노림
- BISOverlay: 아이콘 / 아이템명 / 던전 / BIS 배지 간격과 기본 폭을 더 촘촘하게 조정
- ItemLevelOverlay: `나의 문장` 패널을 아래로 내리고 `위대한 금고`와의 간격을 더 줄였으며 문장 글자 크기를 확대
- ItemLevelOverlay: `단계` 컬럼을 넓히고 일부 보상 등급에 `?/?` 표기를 추가
- MainWindow / ConfigPanel / AddonSettings: ESC 닫기, 설정 겹침 수정, Utility 하위 메뉴 노출
- ProfessionKnowledgeOverlay: 1회성 포인트를 모두 획득한 경우 화면 오버레이에서만 1회성 표시를 숨김

## 상세 변경

### 1. BIS 시즌 툴팁 정리 (`UI/BISOverlay.lua`)

- `C_EncounterJournal.SetPreviewMythicPlusLevel()`과 loot info의 `link`를 이용해 시즌 preview hyperlink를 우선 조회
- preview hyperlink가 있으면 `GameTooltip:SetHyperlink(link)`로 base item이 아닌 시즌 preview item tooltip을 우선 표시
- fallback 경로에서는 기존처럼 요약 라인을 유지하되, 잘못된 `250~266` 보정 문구만 남고 내부 스탯이 과거 템 기준으로 보이는 상황을 줄이도록 링크 선택 로직을 정리
- BIS 행 기본 폭, 들여쓰기, 던전 컬럼, 배지 컬럼 폭을 줄여 전체 밀도를 높임

### 2. 드랍템 레벨 오버레이 정리 (`UI/ItemLevelOverlay.lua`)

- 전체 기본 폭을 줄이고 `단계` 컬럼 폭을 늘려 `10단계`, `11단계` 줄바꿈을 완화
- `클리어 보상` / `위대한 금고`에서 rank가 확정되지 않은 트랙은 `?/?` 표기를 추가
- 우측 `나의 문장` 패널을 더 아래에서 시작하게 조정해 표 타이틀과 직접 겹쳐 보이던 인상을 줄임
- `위대한 금고`와 `나의 문장` 사이 시각 간격을 더 줄이고 문장 라인 글자 크기를 확대

### 3. 설정/창 레이아웃 보정

- 메인 설정 탭에서 디버그 체크박스와 로그 버튼이 겹치지 않도록 버튼을 별도 줄로 재배치
- WoW 기본 설정의 ABPM 카테고리에 `Utility` 하위 페이지를 노출해 메인 UI 탭 구조와 맞춤
- 메인 창을 `ESC`로 닫을 수 있도록 `UISpecialFrames` 등록과 키 입력 처리 보강
- typography / combat text 박스 높이를 다시 조정해 오버플로우와 과한 여백을 줄임

### 4. 전문기술 오버레이 정리 (`UI/ProfessionKnowledgeOverlay.lua`)

- 1회성 포인트를 전부 획득한 profession은 화면 오버레이 요약/상세에서 `1회성` 표기를 숨김
- 주간 요약/상세와 툴팁은 그대로 유지해 확인 정보는 잃지 않도록 구성

## 참고

- 로컬 패키지: `dist/ABProfileManager-v1.5.4.zip`
- BIS 툴팁의 정확한 현재 시즌 스탯 표시는 Encounter Journal이 시즌 preview hyperlink를 주는 경우에 가장 정확합니다.
- Encounter Journal preview 링크가 없는 아이템은 WoW addon API 특성상 base item tooltip로 떨어질 수 있어, 이 경우는 시즌 요약 라인을 함께 확인하는 것을 기준으로 둡니다.
