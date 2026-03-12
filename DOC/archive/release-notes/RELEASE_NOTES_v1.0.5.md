# ABProfileManager v1.0.5 Release Notes

`ABProfileManager`의 패치 릴리스 버전입니다.

저장소:
- `https://github.com/cronocros/ABProfileManager`

배포 패키지:
- `dist/ABProfileManager-v1.0.5.zip`

소스 백업:
- `backups/source/ABProfileManager-source-v1.0.5-<timestamp>.zip`

## 요약

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

이번 버전은 스탯 오버레이의 퍼센트 정렬을 보정해
짧은 평점과 긴 평점이 섞여도 퍼센트 시작 위치가 일정하게 보이도록 정리한 릴리스입니다.

## 주요 변경

- 스탯 오버레이의 평점 컬럼 폭 고정
- 평점 자릿수와 무관하게 퍼센트 시작 위치 정렬 보정
- 문서와 배포 메타데이터를 `v1.0.5` 기준으로 갱신

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
- 인게임 기준 주요 동작은 수동 확인이 필요합니다.

## GitHub 릴리스 본문용 짧은 문구

```text
ABProfileManager v1.0.5

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

- 스탯 오버레이 퍼센트 정렬 보정
- 짧은 평점과 긴 평점이 섞여도 시작 위치 고정
- 문서와 배포 메타데이터를 v1.0.5 기준으로 갱신
```
