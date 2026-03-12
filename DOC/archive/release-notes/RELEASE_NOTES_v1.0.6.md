# ABProfileManager v1.0.6 Release Notes

`ABProfileManager`의 패치 릴리스 버전입니다.

저장소:
- `https://github.com/cronocros/ABProfileManager`

배포 패키지:
- `dist/ABProfileManager-v1.0.6.zip`

소스 백업:
- `backups/source/ABProfileManager-source-v1.0.6-<timestamp>.zip`

## 요약

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

이번 버전은 스탯 오버레이의 퍼센트 표기를 더 안정적으로 정렬하고,
스탯 툴팁을 Blizzard 캐릭터창 설명에 더 가깝게 보이도록 보정한 릴리스입니다.

## 주요 변경

- 스탯 오버레이 퍼센트 표기를 항상 소수 둘째 자리까지 유지
- 한 자리수/두 자리수 퍼센트가 섞여도 괄호 열과 소수점 위치가 어긋나지 않도록 정렬 보정
- 스탯 값 영역 툴팁은 Blizzard 캐릭터 스탯 setter를 우선 재사용해 특화 등 스펙별 설명을 최대한 원문에 가깝게 표시
- 문서와 배포 메타데이터를 `v1.0.6` 기준으로 갱신

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
ABProfileManager v1.0.6

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

- 스탯 오버레이 퍼센트 소수 둘째 자리 고정
- 괄호 열과 소수점 위치 정렬 보정
- 캐릭터창에 가까운 스탯 툴팁 재사용
- 문서와 배포 메타데이터를 v1.0.6 기준으로 갱신
```
