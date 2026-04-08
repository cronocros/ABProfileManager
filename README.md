# ABProfileManager

월드 오브 워크래프트 Retail에서 액션바 복구, 전문기술 포인트 점검, 한밤(Midnight) 지역 길찾기, BIS 인던 드랍 정보, 드랍 템렙 표, 파티찾기 시즌 최고기록 확인까지 한 창과 몇 개의 오버레이로 정리하는 애드온입니다.

제작: `밍밍이와코코`
연락처: `crono1232@gmail.com`

## 현재 버전

- `v1.5.9`
- 저장소: `https://github.com/cronocros/ABProfileManager`
- 최신 릴리스: `https://github.com/cronocros/ABProfileManager/releases/latest`
- 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.5.9/ABProfileManager-v1.5.9.zip`
- 로컬 패키지: `dist/ABProfileManager-v1.5.9.zip`
- 최신 릴리스 노트: [RELEASE_NOTES_v1.5.9.md](./RELEASE_NOTES_v1.5.9.md)

## 요약

- 특성 전환이나 캐릭터 변경 뒤 엉킨 액션바를 템플릿으로 복구
- 전문기술 포인트와 1회성 보물을 자동 추적
- 한밤(Midnight) 지도에서 포탈, 시설, 던전, 구렁 위치를 텍스트 오버레이로 확인
- 던전/레이드/M+/제작 드랍 아이템 레벨 표와 우측 `나의 문장` / `나의 열쇠` 패널 제공
- 전클래스/전특성 BIS 인던 드랍 정보 오버레이 제공
- 파티찾기 시즌 최고기록 던전 아이콘 위에 `평점 + 던전명` 오버레이 제공

## v1.4.7 이후 추가/강화

- `드랍템 레벨정보 오버레이`가 `4열 표 + 우측 나의 문장 / 나의 열쇠 패널` 구조로 확장되었습니다.
- `BIS 인던 드랍 정보`가 전특성 부위별 `BIS / 대체 / 3순위` 구조, `쐐기 / 레이드 / 제작` 필터, `드랍 출처 / 유형 / BIS 여부` 열, Encounter Journal 랜딩까지 포함하는 실사용 오버레이로 정리되었습니다.
- Wowhead `current Overall BiS` 39 spec 데이터를 1순위로 쓰고, Wowhead `Best Gear from Mythic+` 후보와 기존 seed fallback을 합친 M+ 대체재를 부위별 fallback으로 함께 보여주도록 바뀌었습니다.
- `반지 / 장신구`는 상위 2개를 공동 BIS로 표시하고, 상단 BIS가 레이드/제작인 슬롯만 기존 수기 M+ fallback을 붙이도록 보강했습니다.
- BIS hover 툴팁, BIS/드랍템 위치 복원, Stats/전문기술/BIS 마우스 휠 스케일 저장이 반영되었습니다.
- 파티찾기 신화+ 시즌 최고기록 던전 아이콘에 `평점 + 던전명`을 직접 표시하는 `MythicPlusRecordOverlay`가 추가되었습니다.
- BIS 랜딩 이름 보정, 필터 기본값 마이그레이션, visible-row 갱신 기반 깜빡임 완화, Stats/지도 오버레이 idle CPU 완화가 반영되었습니다.

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
  - 슬라이더 기반 글자 크기 조절
  - 드래그 이동과 위치 저장
  - 상단 요약은 사용자 문장 중심 안내와 정확한 목요일 오전 8시 리셋 잔여 시간 표시
  - tooltip 범례를 `범례: 완료 | 미완료` 한 줄로 정리
  - TomTom 설치 시 미완료 1회성 보물 waypoint 선택
- 전체 typography
  - 메인 창, tooltip, 스탯 오버레이, 전문기술 오버레이, 지도 오버레이 글자 크기를 1pt 단위 슬라이더로 조절
- 한밤(Midnight) 지도 탭
  - 지도 오버레이 전용 탭 분리
  - 포탈 / 시설 / 전문기술 / 평판상인 / 던전·공격대 / 구렁 필터
  - 실버문 외 영원노래 숲, 하란다르, 보이드스톰 포탈 위치 라벨 확장
- 전투메시지 설정
  - `위로 / 아래로 / 부채꼴` 모드 선택
  - 방향성 분산 on/off
  - 로그인/월드 진입 직후 retry 경로 포함
- 캐릭터 스탯 오버레이
  - `캐릭터 직업 - 특성(아이템레벨)` 헤더
  - 치명/가속/특화/유연과 특성 우선순위 표시
  - 탱커 방어스탯(회피/반격/막기) 표시 여부 설정
  - 마우스 휠 스케일 조절과 저장
- 퀘스트 정리
  - 안전 정리 대상
  - 남겨둘 퀘스트
  - 전체 포기 대상
  - 퀘스트 ID 클릭으로 해당 퀘스트 상세 열기
- BIS 인던 드랍 정보 오버레이
  - 전클래스/전특성 BIS 아이템 표시
  - 부위별 `BIS / 대체 / 3순위` 정렬
  - `반지 / 장신구`는 상위 2개 공동 BIS 표시
  - `아이템명 / 드랍 출처 / 유형 / BIS 여부` 열 표시
  - 체크박스형 `쐐기 / 레이드 / 제작` 필터
  - 드랍 출처 클릭 시 가능한 경우 Encounter Journal loot 탭 랜딩
  - 아이템 hover 시 현재 시즌 preview 툴팁 표시
  - 헤더에 `참고용, 실제 템은 직접 확인` 안내 문구 표시
  - 마우스 휠 스케일 조절과 위치 저장/복원
- 드랍 아이템 레벨 오버레이
  - 던전 / 레이드 / M+ / 제작 탭별 드랍 템렙 표
  - `단/난이도 | 클리어보상 | 드랍문장 | 위대한 금고` 4열 표
  - 우측 고정 `나의 문장` 패널
  - `나의 열쇠` 패널에서 오늘의 풍요 4개, 열쇠 파편, 복원된 열쇠 확인
  - 구렁 탭 `보물지도 사용` 행과 위치 저장/복원
  - 쐐기 섹션 헤더에 챔피언/영웅/신화 최고 강화 레벨 요약 표시
- 파티찾기 시즌 최고기록 아이콘 오버레이
  - 신화+ 던전 탭의 시즌 최고기록 던전 아이콘 위에 `평점 + 던전명` 표시
  - 긴 한글 던전명은 지정 규칙으로 줄바꿈
  - Utility 탭 체크박스로 on/off

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
6. `지도` 탭에서 지도 오버레이와 지도 글자 크기 조정
7. `편의기능` 탭에서 BIS / 드랍템 / 시즌 최고기록 오버레이 on/off
8. `설정` 탭에서 전체 글자 크기와 전투메시지 모드 조정

## 현재 포함된 화면

- `현재 접속 캐릭터`
- `액션바`
- `전문기술`
- `지도`
- `설정`
- `퀘스트`
- `편의기능`

설정은 와우 `설정 > 애드온 > ABProfileManager` 아래에서도 경량 하위 페이지로 접근할 수 있습니다.

## BIS / 드랍 메모

- BIS 정보는 참고용입니다. 실제 템은 게임 내에서 직접 확인하는 전제를 유지합니다.
- BIS 기준 소스는 Wowhead `current Overall BiS`이며, 39개 spec 전체를 반영합니다.
- `반지 / 장신구`는 상위 2개를 공동 BIS로 표시합니다.
- BIS 행 hover 툴팁은 현재 시즌 preview 경로를 다시 사용합니다.
- 상단 BIS가 `mythicplus`가 아닌 슬롯만 Wowhead `Best Gear from Mythic+` 후보 기반 M+ fallback을 붙입니다.
- 제작과 촉매 항목은 Encounter Journal 랜딩 대상이 아닙니다.
- `공결탑 제나스`, `알게타르 대학`은 직접 ID 보정이 들어가 있습니다.
- `정기 주술사(262)` 누락은 현재 해소되었습니다.
- `마이사라 동굴`, `윈드러너 첨탑`은 Encounter Journal instanceID 확정 전까지 안내서만 열리고 특정 던전으로 바로 이동하지 않을 수 있습니다.
- BIS 아이템 캐시가 늦게 들어와도 전체 오버레이를 다시 그리지 않고, 보이는 행만 갱신하도록 조정되어 있습니다.
- BIS 갱신 스크립트는 `scripts/refresh_wowhead_bis.py`, M+ fallback 갱신 스크립트는 `scripts/refresh_wowhead_mplus_fallbacks.py`를 사용합니다.

## 현재 제약

- 실제 액션바 변경 허용 범위는 `1-132`, `145-180`입니다.
- 바 모델은 현재 `1~9번 바`까지 지원합니다.
- `9번 바`는 비행 중 페이지 전환 바입니다.
- `10~12번` 특수 바는 현재 별도 매핑하지 않습니다.
- 전체 퀘스트 포기는 포기 가능한 퀘스트만 대상으로 합니다.
- 제작 주문, catch-up 같은 일부 profession 예외 획득원은 아직 별도 자동 집계하지 않습니다.
- 전투메시지 설정은 기본 WoW 전투메시지 on/off를 대신하지 않습니다.
- `열쇠 파편`은 Blizzard API에서 안전한 itemID가 확정되지 않아 `-`로 표시될 수 있습니다.

## 문서

- 기본 사용자 안내: 이 문서
- 배포용 소개 텍스트: [ABProfileManager/ADDON_INTRO.txt](./ABProfileManager/ADDON_INTRO.txt)
- 에이전트 작업 지침: [AGENTS.md](./AGENTS.md)
- 문서 색인: [DOC/README.md](./DOC/README.md)
- 서브 에이전트 팀: [sub/README.md](./sub/README.md)
- 아키텍처: [DOC/ARCHITECTURE.md](./DOC/ARCHITECTURE.md)
- 인수인계: [DOC/HANDOFF.md](./DOC/HANDOFF.md)
- 보안 검토: [DOC/SECURITY_REVIEW.md](./DOC/SECURITY_REVIEW.md)
- 배포 절차: [DOC/RELEASE_PROCESS.md](./DOC/RELEASE_PROCESS.md)
- 이전 릴리스 노트: [DOC/archive/release-notes/](./DOC/archive/release-notes/)
