# ABProfileManager v1.7.4

배포일: `2026-05-25`

WoW Patch 12.0.7 (Midnight) 호환성 재패키징을 포함한 유지보수 릴리스입니다. 이번 재배포는 TOC Interface를 `120005, 120007`로 갱신하고, 툴팁 판매가 처리에서 발생하던 `secret number` taint 오류 방지, BIS 보상 트랙 안내, 스탯 우선순위 표, 언어 기본값 보정을 함께 정리합니다.

직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.4/ABProfileManager-v1.7.4.zip`
로컬 패키지: `dist/ABProfileManager-v1.7.4.zip`

## 주요 변경

### WoW 12.0.7 호환성

- **TOC Interface를 `120005, 120007`로 갱신**
  WoW Retail 12.0.5 호환성을 유지하면서 12.0.7 클라이언트 라인을 함께 지원하도록 정리했습니다.
- **12.0.7 영향 가능 UI/API 경로 정적 점검**
  tooltip ownership, Encounter Journal 랜딩, PVE/Mythic+ 오버레이, currency 조회, PaperDoll stat tooltip setter, aura 조회, 전투부대 은행 점검 경로를 다시 확인했습니다. 기존 `pcall` / 존재 여부 확인 / 전용 tooltip 방어 경로 외 추가 코드 수정이 필요한 부분은 발견하지 못했습니다.
- **스탯 우선순위 데이터는 Patch 12.0.5 baseline 유지**
  이번 재패키징은 12.0.7 클라이언트 호환성 메타데이터 갱신입니다. 12.0.7 밸런스 기준 재검증 데이터로 표기하지 않습니다.

### 툴팁 / MoneyFrame 오류 수정

- **Blizzard `MoneyFrame.lua` secret-number 오류 방지**
  액션바 아이템, 모험 안내서 아이템, Pawn 비교 툴팁 등에서 `attempt to perform arithmetic on a secret number value (execution tainted by 'ABProfileManager')` 오류가 뜨던 경로를 차단했습니다.
- **전역 `GameTooltip` 직접 사용 제거**
  ABPM 자체 UI hover 설명은 애드온 전용 툴팁 프레임을 사용하도록 변경했습니다. ABPM이 Blizzard 기본 `GameTooltip`을 소유한 뒤 다음 아이템 툴팁의 판매가 프레임으로 taint가 이어지는 상황을 줄였습니다.
- **BIS 아이템 hover 툴팁 안전화**
  BIS 오버레이는 더 이상 `GameTooltip:SetHyperlink()`로 실제 아이템 툴팁을 직접 열지 않습니다. `C_TooltipInfo.GetHyperlink()`의 텍스트 정보를 수동 렌더링하고, 판매가/화폐 라인은 건너뛰어 `MoneyFrame_Update` 산술 경로를 타지 않게 했습니다.

### BIS 오버레이

- **쐐기 보상 트랙 안내 추가**
  쐐기 BIS 항목에 `던전 종료 영웅 트랙 3/6 · 266`, `위대한 금고/Voidcore 신화 트랙 1/6 · 272` 같은 대표 보상 프로필을 표시합니다.
- **BIS 카탈로그 재생성 및 검증 보강**
  `Data/BISCatalog.lua`에 쐐기 보상 프로필을 포함하고, 생성 스크립트와 검증 스크립트를 보강했습니다.
- **일부 아이템명/출처 표기 보정**
  한글/영문 표시와 source label을 현재 데이터 기준으로 다시 정리했습니다.

### 스탯 우선순위 표

- **메인 창에 `스탯 우선순위 표` 버튼 추가**
  클래스/전문화별 1차 스탯과 2차 스탯 우선순위를 한 번에 확인할 수 있는 별도 팝업을 추가했습니다.
- **Patch 12.0.5 기준 40개 전문화 데이터 정리**
  영웅 특성, 단일/광역, 레이드/쐐기처럼 분기가 있는 경우 표 안에 그대로 표시합니다. 현재 캐릭터의 전문화 행은 강조됩니다.
- **스탯 오버레이용 기본 우선순위 갱신**
  오버레이 한 줄 표시는 일반 PvE 기준 첫 번째 분기를 기본으로 사용하고, 쐐기 분기가 명시된 일부 힐러 전문화는 별도 M+ 우선순위를 유지합니다.

### 언어 기본값 / fallback

- **첫 설치 언어를 WoW 클라이언트 기준으로 변경**
  한국어 클라이언트는 계속 한국어가 기본입니다. 영어 클라이언트(`enUS`, `enGB`)와 현재 미지원 locale은 영어 UI로 시작합니다.
- **기존 affected 영어 유저 1회 보정**
  이전 버전에서 영어 클라이언트인데 `koKR`가 기본값으로 저장된 경우, 사용자가 직접 한국어를 선택한 기록이 없으면 한 번만 `enUS`로 자동 전환합니다.
- **fallback 순서 정리**
  문자열 fallback은 현재 선택 언어 → 영어 → 한국어 → key 순서로 처리합니다.
- **ruRU PR 처리 방향**
  GitHub PR #2의 러시아어 번역은 감사와 함께 별도 리뷰 대상으로 남깁니다. 이번 릴리스에는 `koKR/enUS` 공식 지원만 유지합니다.

## 공지용 요약

ABProfileManager v1.7.4 유지보수 업데이트입니다.

- WoW Retail 12.0.7 계열 대응을 위해 Interface를 `120005, 120007`로 갱신해 구버전 경고 없이 로드되도록 정리했습니다.
- 액션바/모험 안내서/Pawn 아이템 툴팁에서 발생할 수 있던 `MoneyFrame.lua secret number` 오류를 수정했습니다.
- BIS 오버레이의 아이템 hover 툴팁을 안전한 전용 렌더링으로 바꿔 Blizzard 기본 툴팁 taint 전파를 줄였습니다.
- 쐐기 BIS 항목에 던전 종료/위대한 금고 보상 트랙과 아이템 레벨 안내를 추가했습니다.
- 메인 창에 Patch 12.0.5 baseline 기준 `스탯 우선순위 표`를 추가했습니다.
- English clients now open in English by default. Korean clients still default to Korean.
- Existing affected English users are migrated once from the accidental Korean default to English.

## 인게임 확인 권장

- BIS 오버레이 아이템 행 마우스오버
- 액션바 아이템/장비 버튼 마우스오버
- 모험 안내서 아이템 및 Pawn 비교 툴팁 마우스오버
- `[백금 별 고리]` 등 판매가가 있는 아이템 hover 시 Lua 오류가 더 이상 뜨지 않는지 확인
- WoW 12.0.5/12.0.7 클라이언트에서 구버전 애드온 경고 없이 로드되는지 확인
- 메인 창의 `스탯 우선순위 표` 버튼과 현재 전문화 강조 표시 확인
- 영어 클라이언트 신규 설치 또는 초기화 상태에서 첫 `/abpm` 화면이 영어로 뜨는지 확인
- 한국어 클라이언트 신규 설치 또는 초기화 상태에서 첫 `/abpm` 화면이 한국어로 유지되는지 확인
- 영어 클라이언트에서 사용자가 직접 한국어를 선택한 경우 reload 후에도 한국어가 유지되는지 확인

## 이전 버전에서 업그레이드

- 기존 저장 데이터(`ABPM_DB`)는 그대로 유지됩니다.
- 별도 설정 초기화는 필요하지 않습니다.
- 영어 클라이언트에서 이전 기본값 때문에 한국어가 저장된 경우, 사용자가 직접 한국어를 고른 기록이 없으면 한 번만 영어로 보정됩니다.
- 같은 `v1.7.4` 태그의 유지보수 재패키징입니다. 이미 v1.7.4를 받았다면 최신 ZIP으로 다시 덮어 설치하면 됩니다.
