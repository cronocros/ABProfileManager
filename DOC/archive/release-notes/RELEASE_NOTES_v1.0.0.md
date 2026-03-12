# ABProfileManager v1.0.0 Release Notes

`ABProfileManager`의 1차 출시 버전입니다.

저장소:
- `https://github.com/cronocros/ABProfileManager`

배포 패키지:
- `dist/ABProfileManager-v1.0.0.zip`

## 요약

WoW Retail용 액션바 템플릿 관리 애드온입니다.

현재 액션바를 템플릿으로 저장하고, 전체 또는 일부 범위를 다시 적용할 수 있습니다.
비교, 동기화, 최근 1회 되돌리기, 문자열 가져오기/내보내기, 현재 특성 전환, 퀘스트 정리 기능을 포함합니다.

## 주요 기능

- 템플릿 저장 / 복제 / 적용 / 삭제
- 전체 / 부분 범위 적용
- 비교 / 동기화
- 최근 1회 되돌리기
- 문자열 내보내기 / 가져오기
- 현재 특성 전환
- 비행 바 `9번 바` 지원
- 전투 중 대기열 처리
- 매크로 검증 강화
- 퀘스트 정리 / 전체 퀘스트 포기
- 한국어 기본 UI / 영어 옵션
- 미니맵 버튼

## 보안 / 안전

- 문자열 가져오기는 코드 실행이 아니라 데이터 파싱만 허용
- import 문자열 길이 / 줄 수 / 중복 슬롯 / 액션 종류 검증
- 템플릿 이름 단일행 정화
- `전체 퀘스트 포기`는 항상 확인 모달 표시

## 설치

`ABProfileManager` 폴더를 아래 경로에 복사합니다.

```text
World of Warcraft\_retail_\Interface\AddOns\
```

최종 경로:

```text
World of Warcraft\_retail_\Interface\AddOns\ABProfileManager\ABProfileManager.toc
```

## 알려진 메모

- 이 개발 환경에는 `lua`/`luac`가 없어 정적 문법 검사는 자동으로 돌리지 못했습니다.
- 하단 요약창 오른쪽 끝 미세 정렬은 후순위 메모로 남겨두었습니다.

## GitHub 릴리스 본문용 짧은 문구

```text
ABProfileManager v1.0.0

WoW Retail용 액션바 템플릿 관리 애드온 첫 출시 버전입니다.

- 템플릿 저장 / 복제 / 적용 / 삭제
- 전체 / 부분 범위 적용
- 비교 / 동기화
- 최근 1회 되돌리기
- 문자열 내보내기 / 가져오기
- 현재 특성 전환
- 비행 바 9번 바 지원
- 퀘스트 정리 / 전체 퀘스트 포기
- 한국어 기본 UI / 영어 옵션

보안 보강:
- import 문자열 검증 강화
- 전체 퀘스트 포기 강제 확인
```
