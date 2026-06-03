# ABProfileManager v1.11.7 로컬 패치

패치 기준일: `2026-06-03`

이 문서는 로컬 패치 패키지 기준 릴리스 노트입니다.

- 로컬 패키지: `dist/ABProfileManager-v1.11.7.zip`
- 원격 GitHub 공개 최신 릴리스: `v1.11.0`
- 원격 GitHub 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## 주요 변경

- **레이드 / 제작 / 티어 기본 아이템 툴팁**
  상단 아이템 토글을 켜면 raid/crafted/tier BIS hover도 addon-owned Blizzard `GameTooltip:SetHyperlink()` 기본 item tooltip을 표시합니다.
- **임의 bonusID 조립 금지 유지**
  이 출처들은 검증된 시즌 full link가 없는 정적 `itemID` 후보이므로, 시즌 강화 링크를 추측하지 않고 클라이언트가 로드한 기본 `itemLink`만 사용합니다.
- **세션 캐시 재사용**
  성공한 기본 `itemLink`는 세션 메모리 캐시에 저장해 반복 hover 로딩 부담을 줄입니다.
- **M+ 경로 유지**
  M+ `Myth/신화 1/6 272` 검증 snapshot, Blizzard 원본 tooltip, shopping tooltip 기반 `MoneyFrame` 차단 경로는 그대로 유지합니다.
- **계약 검증 확장**
  `scripts/validate_bis_tooltip_contract.py`가 raid/crafted/tier 기본 Blizzard tooltip 경로도 확인합니다.

## 배포 경계

- 로컬 배포는 작업공간의 `dist/ABProfileManager-v1.11.7.zip` 생성까지만 수행합니다.
- WoW 설치 폴더로 애드온을 자동 복사하지 않습니다.
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 계속 `v1.11.0`을 유지합니다.

## 인게임 확인 권장

- 상단 아이템 토글을 켠 뒤 레이드 / 제작 / 티어 BIS hover가 Blizzard 기본 아이템 툴팁을 표시하는지 확인
- 같은 레이드 / 제작 / 티어 아이템을 다시 hover할 때 세션 캐시로 즉시 표시되는지 확인
- M+ BIS hover가 계속 `Myth/신화 1/6 272` 기준으로 표시되는지 확인
- BIS hover 뒤 액션바 / 모험 안내서 item tooltip에서 `MoneyFrame.lua secret number` 오류가 재발하지 않는지 확인
