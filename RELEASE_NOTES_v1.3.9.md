# ABProfileManager v1.3.9

이번 패치는 오버레이 표시 우선순위와 한밤(Midnight) 지도 오버레이 안정화에 집중한 안정화 릴리스입니다.

## 핵심 변경

- 메인 UI는 계속 기본 WoW 창보다 앞에 유지하고, 스탯 / 전문기술 오버레이는 기본 패널을 가리지 않도록 strata를 낮춰 HUD 성격에 맞게 조정
- 설정 탭의 스탯 오버레이 크기 라벨을 `캐릭터 스탯 오버레이 크기`로 바꿔 어떤 오버레이 설정인지 더 쉽게 구분할 수 있게 정리
- 한밤(Midnight) 지도 오버레이는 refresh 중 중복 진입, 월드맵 전환 직후 parent nil, width/height 0 canvas 같은 예외 경로를 보수적으로 차단
- 지도 오버레이는 내부 오류가 나더라도 전체 UI를 깨뜨리지 않고 오버레이만 숨기고 빠지도록 방어 경로를 추가
- 문서, 버전, 패키지, GitHub 릴리스를 `v1.3.9` 기준으로 갱신

## 배포 파일

- GitHub 직접 다운로드:
  - `https://github.com/cronocros/ABProfileManager/releases/download/v1.3.9/ABProfileManager-v1.3.9.zip`
- 로컬 패키지:
  - `dist/ABProfileManager-v1.3.9.zip`
