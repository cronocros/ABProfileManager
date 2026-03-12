# ABProfileManager v1.0.7 Release Notes

`ABProfileManager`의 패치 릴리스 버전입니다.

저장소:
- `https://github.com/cronocros/ABProfileManager`

배포 패키지:
- `dist/ABProfileManager-v1.0.7.zip`

소스 백업:
- `backups/source/ABProfileManager-source-v1.0.7-<timestamp>.zip`

## 요약

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

이번 버전은 스탯 오버레이 퍼센트의 소수점 위치를 더 정확히 맞추고,
캐릭터 스탯 툴팁 재사용 시 발생하던 폰트 오류를 수정한 릴리스입니다.

## 주요 변경

- 스탯 오버레이 퍼센트 표기를 `정수부`와 `소수부` 컬럼으로 분리해 소수점 위치 정렬 보정
- 스탯 퍼센트는 항상 소수 둘째 자리까지 표시
- 캐릭터 스탯 툴팁 재사용 프록시에 폰트를 직접 지정해 `Font not set` 오류 수정
- 문서와 배포 메타데이터를 `v1.0.7` 기준으로 갱신

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
ABProfileManager v1.0.7

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

- 스탯 오버레이 퍼센트 소수점 위치 정렬 보정
- 스탯 퍼센트 소수 둘째 자리 고정
- 캐릭터 스탯 툴팁 재사용 시 Font not set 오류 수정
- 문서와 배포 메타데이터를 v1.0.7 기준으로 갱신
```
