# ABProfileManager v1.11.9 로컬 패치

패치 기준일: `2026-06-03`

이 문서는 로컬 패치 패키지 기준 릴리스 노트입니다.

- 로컬 패키지: `dist/ABProfileManager-v1.11.9.zip`
- 원격 GitHub 공개 최신 릴리스: `v1.11.0`
- 원격 GitHub 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## 주요 변경

- **레이드 / 티어 신화 preview 보강**
  raid/tier BIS hover는 검토된 시즌 preview item string을 먼저 시도합니다. 클라이언트 tooltip에서 실제 item level이 `272~289` 범위이고 `Myth/신화` 텍스트가 확인된 경우에만 Blizzard 원본 아이템 툴팁으로 표시합니다.
- **제작 r5 285 preview 보강**
  crafted BIS hover는 r5 `285` 제작 preview item string을 먼저 시도합니다. 클라이언트 tooltip에서 실제 item level이 `285`로 확인된 경우에만 Blizzard 원본 아이템 툴팁으로 표시합니다.
- **검증 실패 fallback 유지**
  preview가 로드되지 않거나 검증을 통과하지 않으면 기존처럼 기본 `itemLink` 또는 `item:<itemID>` Blizzard 툴팁으로 fallback합니다.
- **시즌 preview DB 추가**
  `Data/BISSeasonPreviewLinks.lua`가 raid Myth, tier Myth, crafted r5 preview 템플릿과 예외 full link override 위치를 관리합니다.
- **검증 스크립트 추가**
  `scripts/validate_bis_season_preview_links.py`를 추가하고 `scripts/rebuild_bis_database.ps1` 통합 순서에 연결했습니다.
- **M+ 경로 유지**
  M+ `Myth/신화 1/6 272` snapshot, 상단 아이템 툴팁 체크박스 기본 on, shopping tooltip 기반 `MoneyFrame` 차단 경로는 그대로 유지합니다.

## 배포 경계

- 로컬 배포는 작업공간의 `dist/ABProfileManager-v1.11.9.zip` 생성까지만 수행합니다.
- WoW 설치 폴더로 애드온을 자동 복사하지 않습니다.
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 계속 `v1.11.0`을 유지합니다.

## 인게임 확인 권장

- raid/tier BIS hover가 신화 preview 검증 후 Blizzard 원본 툴팁으로 표시되는지 확인
- crafted BIS hover가 r5 `285` preview 검증 후 Blizzard 원본 툴팁으로 표시되는지 확인
- preview 검증 실패 시 기본 `itemLink` 또는 `item:<itemID>` fallback이 유지되는지 확인
- M+ BIS hover가 계속 `Myth/신화 1/6 272` snapshot 기준으로 표시되는지 확인
- BIS hover 뒤 액션바 / 모험 안내서 item tooltip에서 `MoneyFrame.lua secret number` 오류가 재발하지 않는지 확인
