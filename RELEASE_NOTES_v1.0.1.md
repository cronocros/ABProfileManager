# ABProfileManager v1.0.1 Release Notes

`ABProfileManager`의 패치 릴리스 버전입니다.

저장소:
- `https://github.com/cronocros/ABProfileManager`

배포 패키지:
- `dist/ABProfileManager-v1.0.1.zip`

## 요약

WoW Retail용 액션바 템플릿 관리 애드온입니다.

이번 버전은 기존 출시본을 다듬는 유지보수 릴리스입니다.
고스트 슬롯을 직접 드래그로 해제하거나 다른 액션으로 덮어쓸 수 있게 했고,
현재 캐릭터가 실제로 적용 가능한 템플릿 액션만 반영하는 동기화 버튼을 추가했습니다.
미니맵 버튼도 더 작은 둥근 아이콘형으로 정리했습니다.

## 주요 변경

- 고스트 슬롯 드래그 해제 지원
- 고스트 슬롯 위에 다른 액션을 올려 덮어쓰기 지원
- 수동으로 바꾼 고스트 슬롯의 자동 재시도 해제 보강
- `적용 가능한 칸만 맞추기` 동기화 버튼 추가
- 미니맵 버튼 스케일 축소 및 둥근 아이콘형 정리
- 문서와 배포 메타데이터를 `v1.0.1` 기준으로 갱신

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
ABProfileManager v1.0.1

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

- 고스트 슬롯 드래그 해제 / 덮어쓰기 지원
- 적용 가능한 칸만 맞추기 동기화 버튼 추가
- 수동 변경된 고스트 슬롯 자동 재시도 해제
- 미니맵 버튼 스케일 축소 및 둥근 아이콘형 정리
```
