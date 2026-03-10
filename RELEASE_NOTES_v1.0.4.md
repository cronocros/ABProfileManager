# ABProfileManager v1.0.4 Release Notes

`ABProfileManager`의 패치 릴리스 버전입니다.

저장소:
- `https://github.com/cronocros/ABProfileManager`

배포 패키지:
- `dist/ABProfileManager-v1.0.4.zip`

소스 백업:
- `backups/source/ABProfileManager-source-v1.0.4-<timestamp>.zip`

## 요약

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

이번 버전은 캐릭터 스탯 오버레이 추가와 시인성 개선,
탱커 방어 스탯 표시,
DR 구간 색상 표시,
배포 시 자동 소스 백업 생성에 초점을 맞췄습니다.

## 주요 변경

- 치명 / 가속 / 특화 / 유연 스탯 오버레이 추가
- 현재 특성의 PvE 일반 스탯 우선순위 줄 추가
- 탱커 특성은 회피 / 무막 / 막기 추가 표시
- 유연 퍼센트 계산 보정
- `평점 (퍼센트)` 형식과 단계별 DR 퍼센트 색상 적용
- 값 영역 마우스 오버 툴팁 추가
- 설정 탭에서 스탯 오버레이 on/off 지원
- 배포 스크립트가 릴리스 ZIP과 소스 백업 ZIP을 함께 생성하도록 보강

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
ABProfileManager v1.0.4

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

- 캐릭터 스탯 오버레이 추가
- 특성별 PvE 일반 스탯 우선순위 표시 추가
- 탱커 방어 스탯과 DR 구간 색상 표시 추가
- 값 영역 마우스 오버 툴팁 추가
- 배포 시 소스 백업 ZIP 자동 생성
```
