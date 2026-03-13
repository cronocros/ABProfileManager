# ABProfileManager v1.3.14

배포일: 2026-03-14

## 핵심 변경

- profession/quest refresh 경로를 보수적으로 감싸 내부 오류가 전체 UI를 깨뜨리지 않도록 안정화
- `LOOT_CLOSED` 이후 profession refresh를 다시 확인해 1회성 보물과 채집 완료 반영 타이밍을 더 안전하게 보강
- profession 오버레이 tooltip 진행 표기를 `1/1개 . 3/3P` 형식으로 정리
- 프로젝트 전체 리뷰 TODO와 시체 약초채집 오류 추적 TODO 문서를 추가
- 문서 전반과 릴리스 메타데이터를 `v1.3.14` 기준으로 다시 최신화

## 사용자 영향

- profession/quest refresh 중 내부 오류가 나더라도 이전보다 전체 UI가 무너질 가능성이 줄어듭니다.
- 채집/루팅 직후 1회성 profession 완료 상태가 갱신되는 경로를 더 보수적으로 확인합니다.
- profession 오버레이 tooltip에서 완료 항목 수와 포인트 수를 더 읽기 쉬운 형식으로 확인할 수 있습니다.

## 다운로드

- 릴리스 페이지: https://github.com/cronocros/ABProfileManager/releases/tag/v1.3.14
- 직접 다운로드: https://github.com/cronocros/ABProfileManager/releases/download/v1.3.14/ABProfileManager-v1.3.14.zip
