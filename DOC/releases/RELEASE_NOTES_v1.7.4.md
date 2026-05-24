# ABProfileManager v1.7.4

배포일: `2026-05-25`

WoW Patch 12.0.5 (Midnight) 대응 유지보수 릴리스입니다. 이번 재배포는 툴팁 판매가 처리에서 발생하던 `secret number` taint 오류를 막고, BIS 보상 트랙 안내와 스탯 우선순위 표를 함께 정리합니다.

직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.4/ABProfileManager-v1.7.4.zip`
로컬 패키지: `dist/ABProfileManager-v1.7.4.zip`

## 주요 변경

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

## 공지용 요약

ABProfileManager v1.7.4 유지보수 업데이트입니다.

- 액션바/모험 안내서/Pawn 아이템 툴팁에서 발생할 수 있던 `MoneyFrame.lua secret number` 오류를 수정했습니다.
- BIS 오버레이의 아이템 hover 툴팁을 안전한 전용 렌더링으로 바꿔 Blizzard 기본 툴팁 taint 전파를 줄였습니다.
- 쐐기 BIS 항목에 던전 종료/위대한 금고 보상 트랙과 아이템 레벨 안내를 추가했습니다.
- 메인 창에 Patch 12.0.5 기준 `스탯 우선순위 표`를 추가했습니다.

## 인게임 확인 권장

- BIS 오버레이 아이템 행 마우스오버
- 액션바 아이템/장비 버튼 마우스오버
- 모험 안내서 아이템 및 Pawn 비교 툴팁 마우스오버
- `[백금 별 고리]` 등 판매가가 있는 아이템 hover 시 Lua 오류가 더 이상 뜨지 않는지 확인
- 메인 창의 `스탯 우선순위 표` 버튼과 현재 전문화 강조 표시 확인

## 이전 버전에서 업그레이드

- 기존 저장 데이터(`ABPM_DB`)는 그대로 유지됩니다.
- 별도 설정 초기화는 필요하지 않습니다.
- 같은 `v1.7.4` 태그의 유지보수 재패키징입니다. 이미 v1.7.4를 받았다면 최신 ZIP으로 다시 덮어 설치하면 됩니다.
