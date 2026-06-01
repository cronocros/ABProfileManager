# ABProfileManager v1.11.1 로컬 패치

패치 기준일: `2026-06-02`

이 문서는 로컬 패치 패키지 기준 릴리스 노트입니다.

- 로컬 패키지: `dist/ABProfileManager-v1.11.1.zip`
- 원격 GitHub 공개 최신 릴리스: `v1.11.0`
- 원격 GitHub 직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.11.0/ABProfileManager-v1.11.0.zip`

## 주요 변경

- **BIS tooltip 색 보존**
  BIS item tooltip 수동 렌더러가 Blizzard tooltip line color와 품질 색을 보존합니다.
- **M+ 검증 full link 자동 검색**
  상단 아이템 토글을 켜면 자동 검색 큐가 `Data/BISMythicVaultLinks.lua`에서 M+ 후보 full link를 찾습니다.
- **검증된 Myth 1/6 272 링크만 자동 점수화**
  자동 검색 full link 자체가 위대한 금고 `Myth 1/6 272`로 검증된 경우에만 해당 링크의 실제 스탯 / 실제 ilvl로 점수화합니다.
- **266 종료보상 fallback 유지**
  던전 종료 `Hero 3/6 266` 링크만 있으면 272 기준 라벨은 표시하지만 점수는 미검증 fallback으로 유지합니다.
- **itemID 기반 링크 조립 금지**
  `itemID`만으로 `itemLink`/bonusID를 만들거나 조립하지 않습니다.
- **rebuild 스로틀 완화**
  실제 장비/가방 링크를 우선하고, 점수 캐시, 아이템 요청 dedupe, 분산 큐를 사용합니다.
- **MoneyFrame taint 경로 차단**
  hover/자동 큐에서 Encounter Journal UI 상태를 변경하거나 숨은 loot scan을 실행하지 않습니다.
- **BIS 재생성 진입점 추가**
  `scripts/rebuild_bis_database.ps1`는 v1.3 카탈로그 입력 → v1.7 scoring 입력 → curated Myth link validate → catalog validate → audit 순서로 실행합니다.
- **검증 링크 validator 추가**
  `scripts/validate_bis_mythic_vault_links.py`는 baseline, 카탈로그 itemID 포함 여부, full item string 형식을 검사합니다.

## Seed 경계

- M+/tier 추가는 v1.3 파일만 갱신할 수 있습니다.
- 점수 정책은 v1.7 파일에서 관리합니다.
- 검증된 Myth 1/6 272 full link 추가/교체는 `Data/BISMythicVaultLinks.lua`만 갱신합니다.
- 초기 검증 링크 DB는 비어 있습니다. 클라이언트 API가 제공하지 않는 272 bonusID를 추측해서 채우지 않습니다.
- raid/crafted는 아직 기존 `BISCatalog.lua` 보존 seed입니다.
- 완전 단일 seed 재생성은 후속 범위입니다.

## 인게임 확인 권장

- 상단 아이템 토글 on/off에 따른 검증 DB M+ full link 자동 검색
- 위대한 금고 `Myth 1/6 272`로 검증된 full link만 실제 스탯 / 실제 ilvl 자동 점수화
- 던전 종료 `Hero 3/6 266` 링크만 있을 때 272 기준 라벨 표시와 미검증 fallback 유지
- 실제 장비/가방 링크 우선 적용
- tooltip의 Blizzard line color / 품질 색 보존
- 자동 점수 분산 큐가 rebuild를 과도하게 반복하지 않는지 확인
- BIS hover/자동 큐 뒤 모험 안내서 아이템 hover에서 `MoneyFrame.lua secret number` 오류가 재발하지 않는지 확인
- `레이드 off + 쐐기만 on`, `제작 + 티어만 on`, visible rank 재계산
