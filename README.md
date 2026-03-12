# ABProfileManager

월드 오브 워크래프트 Retail에서 액션바 복구, 전문기술 포인트 점검, 한밤(Midnight) 지역 길찾기를 한 창과 몇 개의 오버레이로 끝내기 위한 애드온입니다.

제작: `밍밍이와코코`
연락처: `crono1232@gmail.com`

## 현재 버전

- `v1.3.12`
- 저장소: `https://github.com/cronocros/ABProfileManager`
- 최신 릴리스: `https://github.com/cronocros/ABProfileManager/releases/latest`
- 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.3.12/ABProfileManager-v1.3.12.zip`
- 로컬 패키지: `dist/ABProfileManager-v1.3.12.zip`
- 최신 릴리스 노트: [RELEASE_NOTES_v1.3.12.md](./RELEASE_NOTES_v1.3.12.md)

## 왜 쓰는가

- 특성 전환이나 캐릭터 교체 뒤에 엉킨 액션바를 템플릿으로 빠르게 되돌릴 수 있습니다.
- 매주 챙겨야 하는 전문기술 포인트를 자동 추적하고, 오버레이로 바로 확인할 수 있습니다.
- 한밤(Midnight) 지도에서 포탈, 주요 시설, 던전, 구렁, 공격대 입구를 글자로 바로 찾을 수 있습니다.
- 퀘스트 정리, 스탯 오버레이, 미니맵 버튼까지 함께 제공해 반복 점검 시간을 줄입니다.

## 핵심 기능

- 액션바 템플릿 저장, 복제, 비교, 부분 적용, 동기화, 최근 1회 되돌리기
- 전문기술 포인트 자동 추적
  - 주간 퀘스트
  - 전문기술 논문
  - 주간 드랍
  - 평판/풍요 지식서 일부
  - 1회성 보물
- 전문기술 오버레이
  - `상세 / 요약 / 최소` 3단 보기
  - `XS / S / M / L / XL` 5단계 크기
  - 드래그 이동과 위치 저장
- 캐릭터 스탯 오버레이
  - `캐릭터 직업 - 특성(아이템레벨)` 헤더
  - 치명/가속/특화/유연과 특성 우선순위 표시
- 한밤(Midnight) 지도 오버레이
  - 주요 시설, 포탈, 전문기술 허브
  - 던전, 구렁, 공격대 입구
  - 카테고리별 on/off 필터
- 퀘스트 정리
  - 안전 정리 대상
  - 남겨둘 퀘스트
  - 전체 포기 대상
  - 퀘스트 ID 클릭으로 해당 퀘스트 상세 열기

## 설치

`ABProfileManager` 폴더를 아래 경로에 넣으면 됩니다.

```text
World of Warcraft\_retail_\Interface\AddOns\ABProfileManager\
```

확인 파일:

```text
World of Warcraft\_retail_\Interface\AddOns\ABProfileManager\ABProfileManager.toc
```

## 빠른 사용 흐름

1. `/abpm` 입력
2. `현재 접속 캐릭터` 탭에서 템플릿 저장
3. `액션바` 탭에서 비교 또는 적용 범위 선택
4. 필요한 경우 동기화 또는 되돌리기 실행
5. `전문기술` 탭과 오버레이로 이번 주 포인트 진행 확인

## 현재 포함된 화면

- `현재 접속 캐릭터`
- `액션바`
- `전문기술`
- `설정`
- `퀘스트`

설정은 와우 `설정 > 애드온 > ABProfileManager` 아래에서도 경량 하위 페이지로 접근할 수 있습니다.

## 전문기술 기능 메모

- profession 카드와 오버레이는 캐릭터별 진행도를 자동 계산합니다.
- 한국어 클라이언트에서는 퀘스트 제목을 우선 사용하고, 일부 1회성 보물은 고유 영어명을 fallback으로 사용합니다.
- TomTom 연동은 선택 기능입니다.
- 현재 하란다르와 공허폭풍의 일부 1회성 보물 waypoint는 해당 지역 안에 있을 때만 TomTom이 안정적으로 찍는 것으로 확인되어, 안내 문구와 제한 메시지를 반영했습니다.

## 한밤(Midnight) 지도 메모

- 지도 오버레이는 외부 월드맵 기준으로만 보이도록 보수적으로 제한했습니다.
- 라벨은 길이 규칙, 수동 줄바꿈 예외, 겹침 완화, 줌 보정을 함께 적용합니다.
- 정적 좌표 기반이므로 게임 패치 후 일부 위치는 수동 보정이 필요할 수 있습니다.

## 현재 제약

- 실제 액션바 변경 허용 범위는 `1-132`, `145-180`입니다.
- 바 모델은 현재 `1~9번 바`까지 지원합니다.
- `9번 바`는 비행 중 페이지 전환 바입니다.
- `10~12번` 특수 바는 현재 별도 매핑하지 않습니다.
- 전체 퀘스트 포기는 포기 가능한 퀘스트만 대상으로 합니다.
- 제작 주문, catch-up 같은 일부 profession 예외 획득원은 아직 별도 자동 집계하지 않습니다.

## 문서

- 사용자 안내: [ABProfileManager/README_USER.md](./ABProfileManager/README_USER.md)
- 소개 문구: [ABProfileManager/ADDON_INTRO.txt](./ABProfileManager/ADDON_INTRO.txt)
- 문서 색인: [DOC/README.md](./DOC/README.md)
- 아키텍처: [DOC/ARCHITECTURE.md](./DOC/ARCHITECTURE.md)
- 인수인계: [DOC/HANDOFF.md](./DOC/HANDOFF.md)
- 보안 검토: [DOC/SECURITY_REVIEW.md](./DOC/SECURITY_REVIEW.md)
- 배포 절차: [DOC/RELEASE_PROCESS.md](./DOC/RELEASE_PROCESS.md)
- 이전 릴리스 노트: [DOC/archive/release-notes](./DOC/archive/release-notes)

## 이미지 경로 준비

스크린샷과 릴리스 이미지는 `DOC/assets/images/` 아래에 두면 됩니다.

예시:

```md
![메인 창](DOC/assets/images/main-window.png)
```
