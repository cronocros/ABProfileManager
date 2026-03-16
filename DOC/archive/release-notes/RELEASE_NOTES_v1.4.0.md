# ABProfileManager v1.4.0

릴리스 날짜: `2026-03-16`

## 요약

이번 릴리스는 지도/글자 크기/profession UX를 한 번에 정리한 버전입니다.

- 메인 창에 `지도` 전용 탭 추가
- 메인 UI, tooltip, 오버레이 글자 크기 슬라이더 추가
- 지도 오버레이 `평판상인` 필터와 외부 지역 포탈 라벨 확장
- profession tooltip 문장형 개편과 정확한 주간 리셋 잔여 시간 표시
- profession refresh follow-up 보강
- 액션바 템플릿 계열 작업 전 경로 확인 모달 강제
- 전투메시지 `부채꼴` 모드 적용 재검증 보강

## 상세 변경

### 1. 지도 탭

- 기존 설정 탭에 섞여 있던 지도 오버레이 관련 기능을 `지도` 전용 탭으로 분리했습니다.
- 지도 탭에서 다음 항목을 바로 조절할 수 있습니다.
  - 지도 오버레이 on/off
  - 지도 오버레이 글자 크기 슬라이더
  - 시설 / 포탈 / 전문기술 / 평판상인 / 던전·공격대 / 구렁 필터
- 평판 관련 NPC 이름은 지도별 고유 이름 대신 모두 `평판상인`으로 통일했습니다.
- 포탈 위치 라벨은 실버문 외에 영원노래 숲, 하란다르, 보이드스톰까지 확장했습니다.

### 2. Typography 슬라이더

- 글자 크기 조절을 프리셋 버튼 대신 슬라이더 중심으로 정리했습니다.
- 1pt 단위로 조절되며 다음 영역을 각각 제어합니다.
  - 메인 UI
  - tooltip
  - 스탯 오버레이
  - 전문기술 오버레이
  - 지도 오버레이
- 슬라이더 값 변경은 즉시 반영되도록 보강했습니다.

### 3. Profession UX

- profession overlay tooltip 문구를 더 읽기 쉬운 문장형 안내로 교체했습니다.
- `완료: 퀘스트명`, `진행 필요: 퀘스트명` 형식으로 상태를 더 직접적으로 보여줍니다.
- 주간 리셋 안내는 `목요일 오전 8시` 기준으로 남은 일/시간/분을 정확히 표시합니다.
- TomTom 설명과 완료 상태 기호에서 깨지던 문자 의존성을 줄였습니다.
- 1회성 profession 보물 좌표는 Method, wow-professions, Blizzard 포럼 좌표를 다시 대조해 주요 오차를 보정했습니다.

### 4. 안정성

- `QUEST_TURNED_IN`, `BAG_UPDATE_DELAYED`, `BAG_NEW_ITEMS_UPDATED`, `LOOT_CLOSED` 이후 profession refresh follow-up 경로를 추가했습니다.
- 전투메시지 설정은 관련 CVar 후보를 모두 다시 쓰고, 읽어온 값과 비교해 적용 실패를 더 보수적으로 감지합니다.
- 템플릿 저장/복제/적용/동기화/되돌리기/가져오기/내보내기 작업은 모두 확인 모달을 거치도록 통일했습니다.

## 참고

- 로컬 패키지: `dist/ABProfileManager-v1.4.0.zip`
- 배포용 소개: [ABProfileManager/ADDON_INTRO.txt](./ABProfileManager/ADDON_INTRO.txt)
- 사용자 안내: [README.md](./README.md)
