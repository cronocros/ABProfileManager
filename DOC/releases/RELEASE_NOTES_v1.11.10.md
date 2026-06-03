# ABProfileManager v1.11.10 로컬 패치

패치 기준일: `2026-06-03`

이 문서는 로컬 패치 패키지 기준 릴리스 노트입니다.

- 로컬 패키지: `dist/ABProfileManager-v1.11.10.zip`
- 원격 GitHub 공개 최신 릴리스: `v1.11.0`
- 원격 GitHub 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## 주요 변경

- **BISOverlay 로드 오류 수정**
  `UI/BISOverlay.lua` 로드 시 발생하던 `main function has more than 200 local variables` 오류를 수정했습니다.
- **local 변수 예산 정리**
  raid/tier/crafted 시즌 preview 상태와 helper를 `SourcePreview` 테이블 필드로 묶어 BISOverlay top-level local 개수를 `194`로 낮췄습니다.
- **검증 강화**
  `scripts/validate_bis_tooltip_contract.py`가 BISOverlay top-level local 개수 예산도 검사합니다.
- **기존 기능 유지**
  raid/tier/crafted 시즌 preview, M+ `Myth/신화 1/6 272` snapshot, 상단 아이템 툴팁 체크박스 기본 on, shopping tooltip 기반 `MoneyFrame` 차단 경로는 유지합니다.

## 배포 경계

- 로컬 배포는 작업공간의 `dist/ABProfileManager-v1.11.10.zip` 생성까지만 수행합니다.
- WoW 설치 폴더로 애드온을 자동 복사하지 않습니다.
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 계속 `v1.11.0`을 유지합니다.

## 인게임 확인 권장

- 애드온 로드 시 `main function has more than 200 local variables` 오류가 재발하지 않는지 확인
- BIS 오버레이가 정상으로 열리는지 확인
- raid/tier/crafted hover가 기존 시즌 preview 또는 fallback 경로로 표시되는지 확인
- M+ BIS hover가 계속 `Myth/신화 1/6 272` snapshot 기준으로 표시되는지 확인
