# ABProfileManager v1.5.9

릴리스 날짜: 2026-04-08

## 요약

이번 릴리스는 BIS 표시 규칙, overlay 위치/크기 저장, hover 툴팁 복원, 구렁 표기 수정, idle CPU hot path 완화를 한 번에 정리한 유지보수 릴리스입니다.

## 주요 변경

### 1. BIS 오버레이 정리

- Wowhead `current Overall BiS` 39 spec 기준은 그대로 유지합니다.
- `반지 / 장신구`는 상위 2개를 공동 BIS로 표시합니다.
- top BIS가 `mythicplus`가 아닌 슬롯만 기존 수기 M+ fallback을 뒤에 붙이도록 병합 정책을 보강했습니다.
- BIS 아이템 hover는 기존 시즌 preview tooltip 경로를 다시 사용합니다.
- 제작 / 촉매는 계속 Encounter Journal 랜딩 대상에서 제외합니다.

### 2. Overlay UX 보강

- `BISOverlay`와 `ItemLevelOverlay`는 드래그 후 닫았다가 다시 열어도 저장 좌표를 우선 복원합니다.
- `StatsOverlay`, `ProfessionKnowledgeOverlay`, `BISOverlay`는 마우스 휠 scale 저장을 지원합니다.
- `ItemLevelOverlay` 구렁 탭 문구를 `보물지도 사용`으로 교체했습니다.

### 3. CPU / 성능 완화

- `StatsOverlay`는 raw state signature가 같으면 snapshot 재구성을 건너뛰어 aura/stat 이벤트 idle 비용을 줄였습니다.
- `SilvermoonMapOverlay`는 상시 0.5초 polling 대신 월드맵 상호작용 시점의 짧은 burst refresh만 유지합니다.
- `PLAYER_SPECIALIZATION_CHANGED`, `SKILL_LINES_CHANGED`는 전역 `RefreshUI()` 대신 관련 UI만 부분 갱신하도록 정리했습니다.

### 4. 문서 / 릴리스 메타데이터

- `README.md`
- `AGENTS.md`
- `ABProfileManager/ADDON_INTRO.txt`
- `DOC/ARCHITECTURE.md`
- `DOC/HANDOFF.md`
- `DOC/SECURITY_REVIEW.md`
- `DOC/README.md`
- `CHANGELOG.md`

위 문서들을 `v1.5.9` 기준으로 갱신했습니다.

## 패키지

- 로컬 패키지: `dist/ABProfileManager-v1.5.9.zip`
