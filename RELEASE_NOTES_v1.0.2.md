# ABProfileManager v1.0.2 Release Notes

`ABProfileManager`의 패치 릴리스 버전입니다.

저장소:
- `https://github.com/cronocros/ABProfileManager`

배포 패키지:
- `dist/ABProfileManager-v1.0.2.zip`

## 요약

WoW Retail용 액션바 템플릿 관리 애드온입니다.

이번 버전은 템플릿 저장 UX를 보강하는 유지보수 릴리스입니다.
이미 존재하는 이름으로 템플릿을 저장할 때는 바로 덮어쓰지 않고,
현재 액션바 내용으로 덮어쓸지 먼저 확인창을 띄우도록 정리했습니다.

## 주요 변경

- 같은 이름 템플릿 저장 시 덮어쓰기 확인창 추가
- 템플릿 저장 UI와 슬래시 저장 경로를 동일한 확인 로직으로 통일
- 문서와 배포 메타데이터를 `v1.0.2` 기준으로 갱신

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
ABProfileManager v1.0.2

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

- 같은 이름 템플릿 저장 시 덮어쓰기 확인창 추가
- 템플릿 저장 UI와 슬래시 저장 경로를 동일한 확인 로직으로 통일
- 문서와 배포 메타데이터를 v1.0.2 기준으로 갱신
```
