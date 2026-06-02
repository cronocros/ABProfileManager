# ABProfileManager v1.11.4 로컬 패치

패치 기준일: `2026-06-03`

이 문서는 로컬 패치 패키지 기준 릴리스 노트입니다.

- 로컬 패키지: `dist/ABProfileManager-v1.11.4.zip`
- 원격 GitHub 공개 최신 릴리스: `v1.11.0`
- 원격 GitHub 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## 주요 변경

- **M+ Encounter Journal 랜딩 보정**
  M+ 드랍 출처 클릭 시 현재 시즌 tier를 먼저 선택하고 availability guard를 통과한 경우에만 검증된 `JournalInstanceID`로 대상 던전 loot 탭을 엽니다.
- **한밤 시즌 1 던전 ID 검증**
  `Magisters' Terrace 1300`, `Maisara Caverns 1315`, `Nexus-Point Xenas 1316`, `Windrunner Spire 1299`, `Algeth'ar Academy 1201`, `Seat of the Triumvirate 945`, `Skyreach 476`, `Pit of Saron 278`을 사용합니다.
- **selector preview hyperlink 로드 재시도**
  preview hyperlink가 아직 로드되지 않아 snapshot이 비어 있으면 비동기 아이템 로드 뒤 exact selector 링크를 다시 검증합니다. 실패 callback은 timeout으로 정리하고 링크별 재시도는 세션에서 최대 2회로 제한합니다.
- **hover 즉시 해석**
  저장 snapshot이 없는 M+ 행 hover도 selector preview hyperlink의 즉시 해석을 한 번 시도합니다.

## 배포 경계

- 이 패치는 로컬 전용 패키지 `dist/ABProfileManager-v1.11.4.zip` 기준입니다.
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 계속 `v1.11.0`을 유지합니다.

## 인게임 확인 권장

- M+ 8개 던전 드랍 출처 클릭이 현재 시즌 tier를 선택한 뒤 올바른 Encounter Journal loot 탭으로 랜딩하는지 확인
- 사용 가능하지 않은 시즌 tier에서 잘못된 던전 랜딩을 시도하지 않는지 확인
- 첫 selector preview 조회가 비어 있어도 비동기 아이템 로드 뒤 snapshot이 채워지는지 확인
- snapshot이 없는 M+ 행 hover에서 preview hyperlink 즉시 해석이 가능한 경우 tooltip이 바로 채워지는지 확인
