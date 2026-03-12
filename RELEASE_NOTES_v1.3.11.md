# ABProfileManager v1.3.11

배포일: 2026-03-13

## 핵심 변경

- profession 오버레이, profession 카드, 퀘스트 목록, 설정 패널의 최근 UI 보정 내용을 현재 상태 기준으로 정리
- 퀘스트 후보 목록에서 퀘스트 ID 클릭으로 상세를 열 수 있게 보강
- profession 오버레이 툴팁과 hover panel 가독성을 다시 정리
- 한밤(Midnight) 지도 오버레이 라벨 데이터와 표시 범위를 최신 조정 상태로 반영
- `설정 > 애드온` 문서와 구조를 실제 구현에 맞춰 재정리
- 루트 문서와 기술 문서를 `DOC` 구조로 재배치
- 이전 릴리스 노트는 `DOC/archive/release-notes/`로 이동

## 문서 정리

- `README.md`: 사용자와 배포 기준 설명으로 재작성
- `ABProfileManager/README_USER.md`: 사용자 안내 중심으로 재정리
- `ABProfileManager/ADDON_INTRO.txt`: 소개/홍보용 문구로 재작성
- `DOC/ARCHITECTURE.md`: 최신 구조와 데이터 흐름 반영
- `DOC/HANDOFF.md`: 현재 상태와 후속 보강 포인트 반영
- `DOC/SECURITY_REVIEW.md`: 현재 입력 경로/외부 의존성 검토 기준으로 갱신
- `DOC/RELEASE_PROCESS.md`: 실제 패키징/릴리스 절차 최신화

## 알려진 이슈

- TomTom 1회성 waypoint panel은 일부 항목에서 첫 선택만 안정적으로 동작하는 사례가 있어 후속 보강 예정

## 다운로드

- 릴리스 페이지: https://github.com/cronocros/ABProfileManager/releases/tag/v1.3.11
- 직접 다운로드: https://github.com/cronocros/ABProfileManager/releases/download/v1.3.11/ABProfileManager-v1.3.11.zip
