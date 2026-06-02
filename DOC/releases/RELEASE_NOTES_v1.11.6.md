# ABProfileManager v1.11.6 로컬 패치

패치 기준일: `2026-06-03`

이 문서는 로컬 패치 패키지 기준 릴리스 노트입니다.

- 로컬 패키지: `dist/ABProfileManager-v1.11.6.zip`
- 원격 GitHub 공개 최신 릴리스: `v1.11.0`
- 원격 GitHub 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## 주요 변경

- **검토된 Myth 1/6 272 selector**
  Midnight 시즌 selector `12801`은 extracted ItemBonus DB2 build `12.0.1.66838`에서 검토했습니다.
- **계정 공통 snapshot schema v3**
  상단 아이템 토글을 켜면 검증된 `Myth/신화 1/6 272` full item link를 계정 SavedVariables snapshot schema v3로 한 번 저장합니다. 이후 hover와 자동 점수화는 저장 결과를 재사용합니다.
- **Blizzard 원본 아이템 툴팁**
  M+ BIS hover는 snapshot의 full item link를 addon-owned Blizzard `GameTooltip:SetHyperlink()`에 전달해 Blizzard 원본 2차 스탯을 표시합니다.
- **MoneyFrame sell-price 차단**
  BIS 전용 item tooltip은 shopping tooltip 경로를 사용해 sell price `MoneyFrame` 렌더링을 차단합니다.
- **secret-number 접점 축소**
  `StatsOverlay`의 미사용 `PaperDollFrame_Set*` setter를 제거했습니다. `SafeNumber()`가 secret 값을 일반 숫자로 정규화하지 못하면 원본을 전파하지 않고 `0`으로 fallback합니다.

## 배포 경계

- 로컬 배포는 작업공간의 `dist/ABProfileManager-v1.11.6.zip` 생성까지만 수행합니다.
- WoW 설치 폴더로 애드온을 자동 복사하지 않습니다.
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 계속 `v1.11.0`을 유지합니다.

## 인게임 확인 권장

- 상단 아이템 토글을 켠 뒤 M+ BIS 아이템 hover가 `Myth/신화 1/6 272` 기준 Blizzard 원본 2차 스탯을 표시하는지 확인
- 같은 아이템을 다시 hover하거나 목록을 스크롤할 때 저장 snapshot이 재사용되고 과도한 끊김이 없는지 확인
- BIS hover 뒤 액션바 / 모험 안내서 item tooltip에서 `MoneyFrame.lua secret number` 오류가 재발하지 않는지 확인
- 스탯 오버레이 hover와 전투 중 스탯 갱신에서 secret-number 오류가 재발하지 않는지 확인
