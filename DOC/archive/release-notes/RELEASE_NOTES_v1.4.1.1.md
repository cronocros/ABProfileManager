# ABProfileManager v1.4.1.1

릴리스 날짜: `2026-03-16`

## 요약

이번 릴리스는 profession overlay 세부 정렬과 퀘스트 후보목록 입력 경로를 다시 다듬은 보수적 패치 버전입니다.

- profession 상세 줄의 prefix 뒤 과한 간격과 `|` divider 제거
- profession tooltip 범례 한 줄 표기와 token 색상 정책 정리
- profession row 구분선 길이를 실제 내용 폭에 맞게 보정
- 퀘스트 후보목록의 휠 스크롤과 quest ID 클릭 경로 복구
- 전투메시지 패널 제목 기호 제거와 설명문 겹침 완화

## 상세 변경

### 1. Profession Overlay

- `주  간:` / `1회성:` prefix는 그대로 유지하면서, 뒤쪽 내용이 더 가깝게 붙도록 레이아웃을 다시 조정했습니다.
- 상세 줄 내부 구분자는 `/` 대신 쉼표 기반으로 정리했습니다.
- tooltip 범례는 `범례: 완료 | 미완료` 한 줄로 보여줍니다.
- tooltip 각 항목은 전체 줄을 색칠하지 않고, `완료 / 미완료 / 00/00 / 00/00P` token만 색을 입히도록 바꿨습니다.
- profession 사이를 나누는 separator line은 실제 one-time 라인 폭에 맞춰 더 짧게 맞췄습니다.

### 2. Quest Candidate List

- read-only scroll edit box에 마우스 입력과 휠 스크롤을 다시 연결했습니다.
- quest ID hyperlink 클릭 경로를 다시 연결해, 목록에서 quest ID를 눌렀을 때 퀘스트 상세를 열도록 복구했습니다.

### 3. Combat Text Panel

- 설정 탭 전투메시지 박스 제목 앞 기호를 제거했습니다.
- 설명문 시작 위치를 제목 아래로 내려 title과 겹치지 않도록 보정했습니다.

## 참고

- 로컬 패키지: `dist/ABProfileManager-v1.4.1.1.zip`
- 배포용 소개: [ABProfileManager/ADDON_INTRO.txt](./ABProfileManager/ADDON_INTRO.txt)
- 사용자 안내: [README.md](./README.md)
