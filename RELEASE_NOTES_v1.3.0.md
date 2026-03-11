# ABProfileManager v1.3.0

릴리스 날짜: `2026-03-12`

## 핵심 변경

- 스탯 오버레이 퍼센트 정렬을 고정 폭 컬럼으로 다시 맞춰 검은 패딩 표시 문제를 제거
- 스탯 헤더를 `캐릭터 직업 - 특성(아이템레벨)` 형식으로 바꾸고, profession 카드/오버레이에 profession 아이콘을 추가
- profession 오버레이를 접기 / 펼치기 가능한 상세형으로 확장하고, 주간 / 1회성 외에 주퀘 / 드랍 / 논문 / 보물 요약까지 표시
- profession 툴팁 이름은 한국어 클라이언트에서 퀘스트명을 우선 사용하고, 부족한 부분은 패턴 번역으로 한글화
- Midnight 지도 오버레이는 시설, profession, 던전, 구렁 라벨을 크게 키우고 주요 던전 / 구렁 이름을 한국어 라벨로 교체
- 와우 `설정 > 애드온` 패널 레이아웃을 별도로 정리하고, `템플릿 / 액션바 / 전문기술 / 퀘스트` 하위 카테고리를 추가

## 다운로드

- 릴리스 페이지: `https://github.com/cronocros/ABProfileManager/releases/tag/v1.3.0`
- 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.3.0/ABProfileManager-v1.3.0.zip`

## 참고

- 설정 하위 카테고리는 기존 메인 창 탭을 재사용하지 않고, 경량 안내 패널과 메인 탭 바로가기 방식으로 구성했습니다.
- profession 툴팁의 일부 숨은 퀘스트 이름은 클라이언트 API가 제목을 돌려주지 않으면 내장 번역 규칙으로 표시됩니다.
