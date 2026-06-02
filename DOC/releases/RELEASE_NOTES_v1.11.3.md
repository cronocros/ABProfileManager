# ABProfileManager v1.11.3 로컬 패치

패치 기준일: `2026-06-02`

이 문서는 로컬 패치 패키지 기준 릴리스 노트입니다.

- 로컬 패키지: `dist/ABProfileManager-v1.11.3.zip`
- 원격 GitHub 공개 최신 릴리스: `v1.11.0`
- 원격 GitHub 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## 주요 변경

- **가방에 없는 M+ 항목도 Myth 1/6 272 preview 생성**
  상단 아이템 토글을 켜면 M+ 후보마다 내장 selector `12801`을 사용해 `Myth 1/6 272` preview item string을 자동 생성합니다.
- **2차 스탯과 기본 아이템 tooltip 표시**
  생성 preview가 클라이언트에서 실제 `272`로 검증되면 tooltip line, 색상, 실제 스탯을 snapshot으로 저장합니다.
- **반복 스캔 방지**
  한 번 저장한 snapshot은 계정 SavedVariables에서 재사용합니다. 이후 hover와 자동 점수 계산은 저장값을 읽습니다.
- **selector 변경과 실패 preview 정리**
  selector 또는 item string 템플릿이 바뀌면 이전 snapshot cache를 초기화합니다. 실제 다른 템렙으로 해석된 preview는 같은 세션에서 반복 재시도하지 않습니다.
- **수동 DB는 예외 override로 유지**
  자동 생성으로 처리하지 못하는 항목만 `Data/BISMythicVaultLinks.lua`의 `linksByItemID`에 full link를 추가합니다.
- **정확도 경계 유지**
  검토되지 않은 bonusID는 임의 조립하지 않습니다. 생성 preview도 클라이언트가 실제 `272`로 확인한 경우에만 사용합니다.

## 데이터 갱신 경계

- 시즌 변경 시 `Data/BISMythicVaultLinks.lua`의 selector를 검토하고 validator 기대값을 함께 갱신합니다.
- 예외 항목용 full link override도 같은 파일에 추가합니다.
- `python .\scripts\validate_bis_mythic_vault_links.py`로 baseline, selector, override 형식을 확인합니다.

## 인게임 확인 권장

- 상단 아이템 토글 on 후 가방에 없는 M+ 항목 hover에서 `Myth 1/6 272`, 2차 스탯, 품질 색이 표시되는지 확인
- 처음 한 번 로딩 뒤 재접속 시 SavedVariables snapshot이 재사용되는지 확인
- BIS 목록을 빠르게 스크롤할 때 tooltip 연속 생성으로 인한 끊김이 줄었는지 확인
- BIS hover 뒤 모험 안내서 아이템 hover에서 `MoneyFrame.lua secret number` 오류가 재발하지 않는지 확인
