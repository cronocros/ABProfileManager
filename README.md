# ABProfileManager

월드 오브 워크래프트 Retail에서 액션바 복구, 전문기술 포인트 점검, 한밤(Midnight) 지역 길찾기를 한 창과 몇 개의 오버레이로 끝내기 위한 애드온입니다.

제작: `밍밍이와코코`
연락처: `crono1232@gmail.com`

## 현재 버전

- `v1.3.16`
- 저장소: `https://github.com/cronocros/ABProfileManager`
- 최신 릴리스: `https://github.com/cronocros/ABProfileManager/releases/latest`
- 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.3.16/ABProfileManager-v1.3.16.zip`
- 로컬 패키지: `dist/ABProfileManager-v1.3.16.zip`
- 최신 릴리스 노트: [RELEASE_NOTES_v1.3.16.md](./RELEASE_NOTES_v1.3.16.md)

## 요약

- 특성 전환이나 캐릭터 변경 뒤 엉킨 액션바를 템플릿으로 복구
- 전문기술 포인트와 1회성 보물을 자동 추적
- 한밤(Midnight) 지도에서 포탈, 시설, 던전, 구렁 위치를 텍스트 오버레이로 확인
- 설정 탭에서 전투메시지 CVar를 직접 제어

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
  - 상단 요약은 `주간 0/0P`, `1회성 0/0P` 형식으로 통일
  - TomTom 설치 시 미완료 1회성 보물 waypoint 선택
- 전투메시지 설정
  - 게임 옵션에 안 보이는 Midnight 전투메시지 CVar를 설정 탭에서 직접 제어
  - `위로 / 아래로 / 부채꼴` 모드 선택
  - 전투메시지, 피해 숫자, 치유 숫자, 방향성 피해 분산 on/off
  - 로그인/월드 진입 시 선택한 프리셋 재적용
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

## 빠른 시작

1. `/abpm` 입력
2. `현재 접속 캐릭터` 탭에서 템플릿 저장
3. `액션바` 탭에서 비교 또는 적용 범위 선택
4. 필요한 경우 동기화 또는 되돌리기 실행
5. `전문기술` 탭과 오버레이로 이번 주 포인트 진행 확인
6. TomTom이 있으면 `1회성` 줄 우클릭으로 미완료 보물 waypoint 선택
7. `설정` 탭에서 전투메시지 모드와 표시 여부 조정

## 현재 포함된 화면

- `현재 접속 캐릭터`
- `액션바`
- `전문기술`
- `설정`
- `퀘스트`

설정은 와우 `설정 > 애드온 > ABProfileManager` 아래에서도 경량 하위 페이지로 접근할 수 있습니다.

## 전문기술 메모

- profession 카드와 오버레이는 캐릭터별 진행도를 자동 계산합니다.
- 한국어 클라이언트에서는 퀘스트 제목을 우선 사용하고, 일부 1회성 보물은 고유 영어명을 fallback으로 사용합니다.
- TomTom 연동은 선택 기능입니다.
- 미완료 1회성 보물은 profession 오버레이의 `1회성` 줄 우클릭으로 TomTom waypoint를 찍을 수 있습니다.
- 하란다르와 공허폭풍 일부 보물은 별도 지역 지도라서, 해당 지역에 들어가면 TomTom waypoint가 정상적으로 생성됩니다.

## 지도 메모

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
- 전투메시지 설정은 최신 Midnight CVar 기준으로 동작하며, 다른 전투메시지 애드온이 값을 다시 덮어쓰면 우선순위에 따라 달라질 수 있습니다.

## 문서

- 기본 사용자 안내: 이 문서
- 문서 색인: [DOC/README.md](./DOC/README.md)
- 서브 에이전트 팀: [sub/README.md](./sub/README.md)
- 아키텍처: [DOC/ARCHITECTURE.md](./DOC/ARCHITECTURE.md)
- 인수인계: [DOC/HANDOFF.md](./DOC/HANDOFF.md)
- 보안 검토: [DOC/SECURITY_REVIEW.md](./DOC/SECURITY_REVIEW.md)
- 배포 절차: [DOC/RELEASE_PROCESS.md](./DOC/RELEASE_PROCESS.md)
- 이전 릴리스 노트: [DOC/archive/release-notes](./DOC/archive/release-notes)
