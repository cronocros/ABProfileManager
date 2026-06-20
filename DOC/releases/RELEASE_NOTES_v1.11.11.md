# ABProfileManager v1.11.11 로컬 패치

패치 기준일: `2026-06-21`

이 문서는 로컬 패치 패키지 기준 릴리스 노트입니다.

- 로컬 패키지: `dist/ABProfileManager-v1.11.11.zip`
- 원격 GitHub 공개 최신 릴리스: `v1.11.0`
- 원격 GitHub 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## 주요 변경

- **진균나락 BIS 후보 추가**
  WoW 12.0.7 신규 단일 보스 레이드 `진균나락(Sporefall)`의 `부식수렁(Rotmire)` 드랍 11종을 raid BIS 후보에 추가했습니다.
- **우선순위 재계산**
  방어구 타입, 전역 목/반지/장신구 슬롯, v1.7 스탯 우선순위를 기준으로 신규 raid 후보의 slot별 우선순위를 반영했습니다.
- **카탈로그 확장**
  BIS 카탈로그는 총 `3330`행입니다: `mythicplus 2554`, `raid 485`, `crafted 91`, `tier 200`.
- **진균나락 preview/locale 지원**
  raid Myth preview 허용 범위를 item level `298`까지 확장하고, BIS hover와 출처 라벨에 `진균나락 / 부식수렁` 표기를 추가했습니다.
- **12.0.7 호환 보강**
  StatsOverlay secret number 변환, Encounter Journal tier fallback, 전투부대 은행 세션 감지, 액션바 cursor mutation, 구렁 API/PVE refresh 보호 경로를 점검했습니다.

## 배포 경계

- 로컬 배포는 작업공간의 `dist/ABProfileManager-v1.11.11.zip` 생성까지만 수행합니다.
- WoW 설치 폴더로 애드온을 자동 복사하지 않습니다.
- 원격 GitHub 공개 최신 릴리스와 직접 다운로드는 계속 `v1.11.0`을 유지합니다.

## 인게임 확인 권장

- BIS 오버레이에서 raid 필터 on 상태로 `진균나락 / 부식수렁` 후보가 표시되는지 확인
- 필터 조합 변경 후 visible rank가 `1순위 / 2순위 / 3순위+`로 다시 매겨지는지 확인
- 진균나락 raid hover가 시즌 preview 또는 기본 item tooltip fallback으로 표시되는지 확인
- 전투 중 BIS 출처 클릭에서 보호 기능 차단 팝업이 나오지 않는지 확인
- 스탯 오버레이, 전투부대 은행, 액션바 적용, 구렁 탭이 12.0.7 클라이언트에서 정상 동작하는지 확인
