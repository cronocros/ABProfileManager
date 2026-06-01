# ABProfileManager v1.11.2 로컬 패치

패치 기준일: `2026-06-02`

이 문서는 로컬 패치 패키지 기준 릴리스 노트입니다.

- 로컬 패키지: `dist/ABProfileManager-v1.11.2.zip`
- 원격 GitHub 공개 최신 릴리스: `v1.11.0`
- 원격 GitHub 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## 주요 변경

- **스크롤 중 tooltip 렌더 억제**
  BIS 목록을 휠 또는 thumb로 스크롤하는 동안 행 hover tooltip 생성을 잠시 멈춰 연속 렌더링 부하를 줄였습니다.
- **Myth 1/6 272 스냅샷 영구 캐시**
  상단 아이템 토글이 켜져 있으면 검증된 272 full link를 한 번 읽고 tooltip line, 색상, 실제 스탯을 계정 SavedVariables에 저장합니다.
- **저장 스냅샷 기반 tooltip과 점수화**
  저장 후에는 hover와 자동 점수 계산이 스냅샷만 읽습니다. 매 hover마다 링크, 가방, 모험 안내서를 다시 조회하지 않습니다.
- **가방 최고 링크 우선 제거**
  가방 링크는 더 이상 슬롯 정렬과 hover 표시를 좌우하지 않습니다. 보유 체크를 켤 때 저장용 링크를 한 번 찾는 데만 사용합니다.
- **가방 이벤트 전체 rebuild 제거**
  `BAG_UPDATE_DELAYED`, `PLAYER_EQUIPMENT_CHANGED`가 BIS 전체 목록을 반복 rebuild하지 않습니다.
- **정확도 경계 유지**
  272 full link가 없는 후보는 itemID나 bonusID를 추측하지 않고 미검증 안내를 표시합니다.
- **소스 정리**
  과거 Encounter Journal preview 경로의 미사용 보조 함수와 rebuild 시 가방 인덱스 생성 코드를 제거했습니다.

## 데이터 갱신 경계

- 검증된 Myth 1/6 272 full link 추가/교체는 `Data/BISMythicVaultLinks.lua`만 갱신합니다.
- 등록 full link는 클라이언트가 실제 272로 확인한 경우에만 SavedVariables 스냅샷으로 저장됩니다.
- M+/tier 후보 풀은 v1.3 파일, 점수 정책은 v1.7 파일에서 관리합니다.
- 272 bonusID는 추측 생성하지 않습니다.

## 인게임 확인 권장

- BIS 목록을 빠르게 스크롤할 때 tooltip 연속 생성으로 인한 끊김이 줄었는지 확인
- 상단 아이템 토글 on 후 검증 full link가 스냅샷으로 저장되고 재접속 뒤 재사용되는지 확인
- 272 스냅샷이 없는 행은 미검증 안내만 표시하는지 확인
- 보유 체크 on/off와 즐겨찾기 정렬이 유지되는지 확인
- BIS hover 뒤 모험 안내서 아이템 hover에서 `MoneyFrame.lua secret number` 오류가 재발하지 않는지 확인
