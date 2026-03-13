# ABProfileManager v1.3.15

배포일: 2026-03-14

## 핵심 변경

- profession 오버레이 tooltip 최소 폭을 넓혀 긴 획득원 이름과 TomTom 안내 문구 줄바꿈을 완화
- profession 오버레이 상단 요약을 상세/요약 모드 모두 `주간 0/0P`, `1회성 0/0P` 형식으로 통일
- 상세 하위 줄은 기존 `0/0` 포인트 표기를 유지해 요약과 세부 항목을 구분
- 더 이상 사용되지 않는 profession overlay locale 키와 dead local 변수를 정리
- 시체 약초채집 오류 추적 문서를 현재 상태로 갱신하고, 실제 구렁/던전 재현은 아직 대기 상태로 기록

## 사용자 영향

- profession 오버레이를 compact/detail 어느 모드로 보든 상단 요약 포인트를 같은 형식으로 빠르게 읽을 수 있습니다.
- tooltip이 이전보다 넓어져 긴 획득원 이름, 완료 목록, TomTom 안내가 덜 잘립니다.
- 시체 약초채집 이슈는 보호 코드는 반영됐지만 실제 구렁/던전 내부 재현 확인은 추가 피드백이 필요합니다.

## 다운로드

- 릴리스 페이지: https://github.com/cronocros/ABProfileManager/releases/tag/v1.3.15
- 직접 다운로드: https://github.com/cronocros/ABProfileManager/releases/download/v1.3.15/ABProfileManager-v1.3.15.zip
