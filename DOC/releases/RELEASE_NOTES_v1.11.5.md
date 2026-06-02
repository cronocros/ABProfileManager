# ABProfileManager v1.11.5 로컬 패치

패치 기준일: `2026-06-03`

이 문서는 로컬 패치 패키지 기준 릴리스 노트입니다.

- 로컬 패키지: `dist/ABProfileManager-v1.11.5.zip`
- 원격 GitHub 공개 최신 릴리스: `v1.11.0`
- 원격 GitHub 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## 주요 변경

- **보호된 Encounter Journal 탭 호출 제거**
  BIS 드랍 출처 클릭 랜딩에서 보호된 `C_EncounterJournal.SetTab` 직접 호출을 제거했습니다.
- **전투 중 자동 랜딩 생략**
  전투 중에는 Encounter Journal 자동 랜딩을 건너뛰어 Blizzard 보호 기능 차단 팝업을 방지합니다.
- **비전투 랜딩 경로 유지**
  비전투 중 M+ 드랍 출처 클릭은 현재 시즌 tier를 먼저 선택하고 availability guard를 통과한 경우에만 검증된 `JournalInstanceID`로 대상 던전을 엽니다.

## 배포 경계

- 로컬 배포는 작업공간의 `dist/ABProfileManager-v1.11.5.zip` 생성까지만 수행합니다.
- WoW 설치 폴더로 애드온을 자동 복사하지 않습니다.
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 계속 `v1.11.0`을 유지합니다.

## 인게임 확인 권장

- 비전투 중 M+ 드랍 출처 클릭이 현재 시즌 tier와 availability guard를 거쳐 올바른 Encounter Journal 랜딩을 수행하는지 확인
- 전투 중 BIS 드랍 출처 클릭이 자동 랜딩을 건너뛰고 Blizzard 보호 기능 차단 팝업을 띄우지 않는지 확인
- crafted/tier 항목은 Encounter Journal 랜딩 대상이 아닌지 확인
