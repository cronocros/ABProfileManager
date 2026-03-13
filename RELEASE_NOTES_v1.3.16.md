# ABProfileManager v1.3.16

배포일: 2026-03-14

## 핵심 변경

- Midnight 최신 클라이언트에서 기본 옵션에 잘 보이지 않는 전투메시지 CVar를 설정 탭에서 직접 제어하는 기능 추가
- `기본 전투메시지`, `피해 숫자`, `치유 숫자`, `방향성 피해 숫자 분산` on/off와 `위로 / 아래로 / 부채꼴` 모드 선택 추가
- 선택한 전투메시지 프리셋은 로그인과 월드 진입 때 다시 적용되도록 연결
- 전투메시지 설정은 현재 클라이언트 CVar 값을 1회 읽어 초기값으로 잡아 기존 사용자의 값을 함부로 덮어쓰지 않도록 설계
- 구렁/던전 시체 약초채집 blank Lua 오류는 최신 사용자 피드백 기준 재현되지 않은 상태로 문서 갱신

## 사용자 영향

- Midnight에서 사라진 것처럼 보이던 전투메시지 옵션 일부를 `설정` 탭에서 다시 직접 바꿀 수 있습니다.
- 원하는 경우 `부채꼴` 모드와 숫자 표시 프리셋을 계속 유지할 수 있습니다.
- 최신 기준으로 약초채집 blank 오류는 재현되지 않았지만, 관찰 메모는 유지합니다.

## 다운로드

- 릴리스 페이지: https://github.com/cronocros/ABProfileManager/releases/tag/v1.3.16
- 직접 다운로드: https://github.com/cronocros/ABProfileManager/releases/download/v1.3.16/ABProfileManager-v1.3.16.zip
