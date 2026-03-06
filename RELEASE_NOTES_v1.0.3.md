# ABProfileManager v1.0.3 Release Notes

`ABProfileManager`의 패치 릴리스 버전입니다.

저장소:
- `https://github.com/cronocros/ABProfileManager`

배포 패키지:
- `dist/ABProfileManager-v1.0.3.zip`

## 요약

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

이번 버전은 템플릿 관리 화면 정보성을 높이고,
전체 비우기 안정성을 보강하고,
미니맵 버튼 표현을 다시 정리하는 데 초점을 맞췄습니다.

## 주요 변경

- 메인 타이틀과 설정 영역에 현재 버전 표시 추가
- 템플릿 삭제 버튼을 저장 / 복제 / 목록 새로고침 옆으로 이동
- 템플릿 정보에 특성명, 기록된 액션 수, 주문 / 매크로 / 아이템 통계 추가
- 전체 액션바 비우기 시 남은 칸을 다시 확인하는 2차 검증 패스 추가
- 미니맵 버튼을 축소된 사각 `AB` 버튼형으로 원복
- 문서에 현재 바 모델이 `1~9번`만 지원되고 `10~12번` 특수 바는 별도 미지원이라고 명시

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
ABProfileManager v1.0.3

WoW Retail용 액션바 템플릿 관리 애드온 유지보수 릴리스입니다.

- 메인 타이틀과 설정 영역에 현재 버전 표시 추가
- 템플릿 삭제 버튼을 상단 버튼 행으로 이동
- 템플릿 정보에 특성명과 기록 통계 추가
- 전체 액션바 비우기 2차 검증 패스 추가
- 미니맵 버튼을 축소된 사각 AB 버튼형으로 원복
```
