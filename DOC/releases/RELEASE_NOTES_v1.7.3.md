# ABProfileManager v1.7.3

WoW Patch 12.0.5 (한밤 .5) — 스탯 오버레이 안정화, 고스트 일괄 정리, BIS 카탈로그 12.0.5 검증 갱신.

직접 다운로드: `https://github.com/cronocros/ABProfileManager/releases/download/v1.7.3/ABProfileManager-v1.7.3.zip`
로컬 패키지: `dist/ABProfileManager-v1.7.3.zip`

## 변경 내용

### 버그 수정 — 스탯 오버레이

- **인던 진입 시 스탯이 0으로 표시되던 문제 수정**
  `PLAYER_ENTERING_WORLD` / `ZONE_CHANGED_NEW_AREA` 시점에 PaperDoll API가 일시적으로 0을 반환하면서 그 0 값이 캐시 signature로 남아 이후에도 0이 표시되던 문제를 해결했습니다. 인스턴스/존 변경 시 `StatsOverlay:InvalidateState()`로 캐시를 무효화하고, 짧은 딜레이의 후속 force refresh를 한 번 더 호출해 API 값이 정상적으로 채워지자마자 즉시 갱신되도록 보강했습니다.
- **장신구/사용효과/외부 버프가 실시간으로 반영되지 않던 문제 수정**
  `BuildStateSignature`에 활성 player 버프 hash(`spellId:expirationTime:applications`)를 포함시켰습니다. 트링킷 발동, 물약, 외부 버프로 stat 절대값이 변하면 같은 stat 결과여도 signature가 달라져 즉시 갱신됩니다. 또한 `UNIT_AURA` 디바운스를 0.45s(slow) → 0.15s(normal)로 단축해 발동 효과 반응성을 개선했습니다.
- **장비 교체 / 특성 변경 시 강제 갱신 추가**
  `PLAYER_EQUIPMENT_CHANGED`와 `PLAYER_SPECIALIZATION_CHANGED` 처리 경로에 force refresh를 적용해 장비/특성 변경 직후 stat 표시가 한 박자 늦게 따라오던 문제를 막습니다.
- **새 이벤트 등록**
  `ZONE_CHANGED_NEW_AREA`, `PLAYER_ENTER_COMBAT`, `PLAYER_LEAVE_COMBAT`을 등록해 인스턴스/전투 진입·이탈 시점의 stat 갱신 누락을 막습니다.

### 신규 기능 — 고스트 스킬 일괄 제거

- 액션바 탭 동기화 작업 영역 하단에 **`고스트 모두 제거`** 버튼을 추가했습니다.
- 클릭 한 번으로 액션바 위에 떠 있는 모든 고스트(사용 불가 표시) 마커를 일괄 정리합니다. 실제 등록된 스킬/매크로/아이템은 건드리지 않습니다.
- 동기화 후 잔여 고스트가 누적되었거나 특성 전환으로 사용 불가 액션이 다수 남았을 때 유용합니다.
- `Modules/ActionBarApplier.lua`에 `DismissAllPendingGhosts()` API를 추가했고, `Modules/GhostManager:RefreshGhosts()`를 통해 오버레이도 같이 정리됩니다.
- Locale 키: `ghost_clear_all_button / ghost_clear_all_tip / ghost_clear_all_long / ghost_clear_all_none / ghost_clear_all_done` (영어/한국어 동시 추가).

### 데이터 — BIS 카탈로그 12.0.5 출처 정합성 검증

- WoW Patch 12.0.5 (2026-04-23 한밤 .5 핫픽스) 기준으로 `Data/BISCatalog.lua`의 출처 라벨을 외부 가이드(Icy Veins / Method / Wowhead / Maxroll)와 대조해 재검증했습니다.
- 공허 첨탑(The Voidspire) 레이드의 4개 보스가 모두 `displaySourceKoKR = "공허 첨탑"`으로 묶여 UI에서 구분이 불가능했던 충돌을 정리했습니다.
  - `Lightblinded Vanguard` → `빛에 눈먼 선봉대`
  - `Crown of the Cosmos` → `우주의 왕관`
  - `Fallen-King Salhadaar` → `몰락한 왕 살하다르`
  - `The Voidspire` (레이드 전체) → `공허 첨탑` 유지
- 한밤 폭포 레이드 보스 라벨(`Belo'ren`, `Vorasius`, `Chimaerus`, `Vaelgor & Ezzorak`, `Midnight Falls`) 정합성 점검 결과 큰 오류는 없습니다.
- 기존 BIS 런타임 정책(`Data/BISCatalog.lua` 단일 소스, 4개 sourceGroup 필터, visible 후보 재번호화)은 그대로 유지됩니다.

### 부수 안정성 패치

- `Modules/ProfessionKnowledgeTracker.lua`: `C_QuestLog.GetAllCompletedQuestIDs` 호출을 `pcall`로 감쌌습니다. WoW 12.0.5에서 일부 환경에서 이 API가 예외를 일으키면서 전문기술 카드 갱신이 실패하던 문제를 막습니다.
- `UI/BISOverlay.lua`:
  - `SOURCE_GROUP_ORDER` 테이블을 추가해 `table.sort`에서 `mythicplus → raid → tier → crafted` 순서를 명시적으로 고정했습니다.
  - 시간여행(Timewalking) 던전에서 아이템 ilvl이 스케일다운으로 표시될 때 BIS 미리보기 ilvl 범위 검증을 우회하도록 보강했습니다.

### 후속 안내 — v1.7.4 예정 작업

- 12.0.5 핫픽스로 가치가 변한 트링킷(예: `Light Company Guidon`, `Shadow of the Empyrean Requiem`, `Light of the Cosmic Crescendo`)의 spec별 우선순위 재조정은 SimC 재검증을 거쳐 v1.7.4에서 일괄 반영합니다.
- 그때까지는 BIS 오버레이의 출처/보스 라벨은 정확히 표시되며, 트링킷 항목 자체의 게임 내 사용성에는 영향이 없습니다.

## 기술 세부 사항

### Stats overlay signature 강화

`UI/StatsOverlay.lua`의 `BuildStateSignature`에 다음 두 축이 추가됐습니다.

- `IsInInstance()` 결과의 `inInstance` / `instanceType`. 인스턴스 컨텍스트 자체가 signature의 일부이므로 인던 진입/이탈 시 자연스럽게 갱신됩니다.
- `C_UnitAuras.GetAuraDataByIndex("player", n, "HELPFUL")` 결과를 인덱스 1~40에 걸쳐 `spellId:expirationTime*10:applications` 형식으로 직렬화한 buff hash. 모든 helpful aura의 만료시각이 변하면 hash가 변경되므로 trinket / consumable / 외부 버프가 stat에 영향을 주지 않더라도 표시가 갱신됩니다.

`Refresh(options)`는 새 옵션 `{ force = true }`를 받아 `lastStateSignature` / `lastSnapshotSignature`를 우회합니다. 외부에서 `StatsOverlay:InvalidateState()`로 명시적 캐시 무효화도 가능합니다.

### Ghost 일괄 제거

`ActionBarApplier:DismissAllPendingGhosts()`는 `pendingGhosts` 테이블을 순회하며 모든 항목을 비운 뒤 `GhostManager:RefreshGhosts()`로 화면 갱신을 요청합니다. 처리 건수를 반환하므로 0건일 때 별도 안내 문구를 띄울 수 있습니다.

## 회귀 체크리스트 (인게임)

- [ ] `/abpm` → `액션바` 탭 → 동기화 영역 하단 `고스트 모두 제거` 버튼이 보이고, 잔여 고스트가 1회 클릭으로 사라지는지 확인
- [ ] 인스턴스 진입 직후 스탯 오버레이의 4대 부 능력치(치/가/특/유)가 0으로 묶이지 않고 정상 값이 즉시 표시되는지
- [ ] 장신구 사용효과(예: 즉발 폭발 트링킷)를 발동했을 때 0.2초 안에 부 능력치 표시가 변하는지
- [ ] 특성 전환 / 장비 교체 후 아이템레벨/부 능력치가 한 호흡 안에 따라오는지
- [ ] BIS 오버레이의 출처/보스명이 12.0.5 기준으로 정확한지

## 이전 버전에서 업그레이드

- 기존 저장 데이터(`ABPM_DB`)는 그대로 유지됩니다.
- 별도 설정 재조정이 필요하지 않습니다.
- 액션바 탭 sync 영역에 새 버튼이 한 줄 추가됩니다.
