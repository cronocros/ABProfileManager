# Midnight 시즌 2 업데이트 핸드오프 (v1.12.0 작업)

이 문서는 `Midnight 시즌 2` 대응 작업을 여러 세션·여러 에이전트가 이어서 진행하기 위한 인계 문서입니다.
작업 도중 세션이 끊기면 이 문서의 `11. 진행 로그`와 `12. 재개 프롬프트`만 읽고 바로 이어받을 수 있어야 합니다.

- 작성 기준일: 2026-08-27
- 기준 브랜치: `codex/midnight-s2-update`
- 직전 릴리스: `v1.11.11` (WoW 12.0.7 대응)
- 목표 릴리스: `v1.12.0` (WoW 12.1.0 대응)
- 계획 출처: ChatGPT/Codex 세션 "한밤 시즌 2 업데이트 계획 수립" (계획만 수립, 코드 변경 없음)

### 개정 이력

| 날짜 | 내용 |
| --- | --- |
| 2026-08-27 | 최초 작성 |
| 2026-08-27 | 계획 검증 반영. 신규 콘텐츠 종류 구분, BIS 동결 파급(5장) 신설, 소유자 없던 파일 3종 wave 배정, W5 분할, 롤백 기준, 검증기 명세 보강 |
| 2026-08-27 | W1, W8, W6, W5a 진행 결과 반영. M+ 던전 풀과 통화 이름 덤프 결과, 12.1 aura API 제한 기록 |
| 2026-08-27 | W7 마이그레이션 부분 반영. BIS preview snapshot 캐시의 시즌 무효화 추가 |
| 2026-08-28 | G1 리뷰 반영. 안내 라벨 축약, `GetTime` 폴백, 시즌 판정 캐시, 로케일 검증기 대괄호 표기, 문서 Interface 번호 수정. 통화 ID 덤프 결과 기록 |
| 2026-08-28 | 안개문장 통화 ID 확정. `CREST_ID_BY_GRADE`를 `3442~3446`으로 교체 |
| 2026-08-28 | 시즌 2 M+ 아이템 레벨 실측표 기록. 등급 상한은 유도값만 있어 코드 미반영 |
| 2026-08-28 | 와우헤드 조사 반영. `+46` 상승 폭, 제작 값, 구렁 단계·문장 매핑, 등급 상한 출처 충돌, `expl` 트랙과 Lair 스키마 영향 기록 |
| 2026-08-28 | 문장 툴팁 5종 실측으로 트랙 범위 확정. 툴팁 하한이 `2/6`임을 확인해 앞서 기록한 M+ 표 충돌을 해소. `gradeMax` 확정 |
| 2026-08-28 | 랭크 사다리 6단계 확정. 구렁·레이드 표 확보, M+ 표 오차 정정, Lair 드랍이 레이드 1보스와 동일함을 인게임 툴팁으로 확인 |
| 2026-08-28 | 제작 품질 사다리 확인으로 제작 값 확정(`318` / `331`). PvP는 와우헤드에 시즌 2 자료가 없음을 확인 |

## 1. 확정된 사실

라이브 클라이언트 `GetBuildInfo()` 덤프로 확정된 값입니다.

```text
ABPM 12.1.0 69465 Aug 21 2026 120100
```

- 클라이언트 버전: `12.1.0`
- 빌드 번호: `69465`
- 빌드 날짜: `Aug 21 2026`
- TOC Interface 번호: `120100`

## 2. 시즌 2 콘텐츠 개요

외부 자료 기준이며, 종류 구분이 중요합니다. 계획 초안은 이름만 나열해 지역·레이드·던전이 섞여 있었습니다.

| 이름 | 종류 | 비고 |
| --- | --- | --- |
| `Curse of Ula'tek` | 패치명 | 12.1 |
| `Coiled Isle` | 신규 지역 | 2026-08-11 선행 오픈. 시즌보다 7일 빠름 |
| `Venomous Abyss` | 신규 레이드 | 보스 8 |
| `Altar of Fangs` | 신규 던전 | 보스 3. 레이드가 아님 |
| 신규 구렁 3종 | 구렁 | 세부 미확정 |

시즌 2 자체는 2026-08-18 시작했습니다.

M+ 던전 풀은 8개이며 라이브 덤프로 확정했습니다. 6장 표를 참조합니다.

- Midnight 던전 5종: `Altar of Fangs`, `Murder Row`, `Den of Nalorakk`, `The Blinding Vale`, `Voidscar Arena`
- 복귀 던전 3종: `Kings' Rest`, `Ruby Life Pools`, `Temple of Sethraliss`

문장(crest) 통화는 시즌 2에서 `Mistcrest`(한국어 `안개문장`)로 바뀌었고, 라이브 덤프 결과 시즌 1과 다른 신규 ID로 교체됐습니다. 6장을 참조합니다.

위 항목은 전부 외부 가이드 기준입니다. 6장 정책에 따라 인게임 확인 전에는 코드에 넣지 않습니다.

### 12.1 애드온 API 변경

12.1은 시즌 콘텐츠보다 aura 접근 제한이 더 큰 변경입니다.

- 전투, 레이드 조우, 쐐기, PvP 중에는 aura가 보호 상태가 됩니다. 이때 `C_UnitAuras`의 index / slot / instanceID 기반 조회를 애드온이 호출하면 **Lua 오류**가 납니다. spellID나 spell 이름 기반 조회는 종전대로 동작합니다.
- `UnitAura` 계열은 보호 상태에서 전부 secret payload를 돌려줍니다.
- 표시용으로는 `AuraContainer` / `AuraButton`과 `AddAuraGroup()`, `AddAuraSlot()`, `AddItemEnchantment()`, `SetAuraGroupFilterString()`이 새로 제공됩니다.
- `C_UnitAuras.AddAuraSound()` / `RemoveAuraSound()`는 기존 `PrivateAuraAppliedSound` 계열의 새 이름입니다.

이 저장소에서 영향을 받는 곳은 `UI/StatsOverlay.lua`의 버프 hash 한 군데이며 W5a에서 처리했습니다. `Modules/PrivateAurasGuard.lua`는 `PrivateAuraAnchorContainerMixin`이 없으면 조용히 넘어가도록 이미 방어돼 있어 추가 작업이 필요 없습니다.

## 3. 승인된 결정

사용자 승인이 끝난 항목입니다. 재논의 없이 이 전제로 진행합니다.

- 릴리스 버전은 `v1.12.0`으로 올린다.
- 접근 방식은 "시즌 데이터 계약 + 검증 하네스"를 채택한다. 대규모 구조 변경은 하지 않는다.
- BIS 추천 장비 데이터는 이번 작업에서 **동결**한다.
- 스탯 우선순위 값도 **동결**하고, 문서·주석에 `12.0.5 기준`임을 명시한다.
- 출처가 확인되지 않은 ID·좌표·아이템 레벨은 하드코딩하지 않는다. 라이브 덤프 또는 실제 툴팁으로 확인된 값만 반영한다.
- 기록물은 한국어로 작성한다. 커밋 메시지, PR 본문, 문서 모두 한국어를 사용한다.

## 4. 작업 범위

### 포함

- `1.11.11` → `1.12.0` 버전 갱신과 `12.1.0` 호환성 점검
- 드랍·금고·구렁·M+·레이드·제작·PvP 아이템 레벨 갱신
- `Mistcrest` 통화와 복원 열쇠 표시 갱신
- `Coiled Isle`, `Altar of Fangs`, 신규 구렁·Lair·레이드·이동시설 지도 정보
- 전문기술 지식 퀘스트·보물·웨이포인트와 12.1 리셋 정책
- 주간 이벤트 스케줄과 SavedVariables 마이그레이션
- M+ 시즌 최고기록 UI와 Blizzard 지연 로드 호환성
- `UI/StatsOverlay.lua`의 12.1 aura / secret-number / API 호환성
- `koKR` / `enUS` / `ruRU` 번역
- BIS 동결로 생기는 표시 저하의 정직한 안내 (5장)
- README, 인트로, 아키텍처, 인계서, 릴리스 노트, 패키지

### 제외 (동결)

- BIS 후보 아이템과 순위
- `Data/BISCatalog.lua`, 런타임 점수화, 시즌 preview selector
- BIS Encounter Journal 데이터
- `Data/ItemLevelTable.lua` 하단 `ns.Data.BISRewardProfiles` 블록 (현재 83행 이후)

`UI/BISOverlay.lua`는 데이터 파일이 아니므로 5장의 안내 표시 작업 범위 안에서만 수정합니다. 후보 목록·순위 계산 로직은 건드리지 않습니다.

### 동결 파일 기준 해시

작업 종료 시 아래 파일은 byte-identical이어야 합니다. `git hash-object <파일>` 결과가 아래와 같아야 합니다.

```text
9e89e80a0de93b4e76fd395be153506c27f737a0  ABProfileManager/Data/BISCatalog.lua
d8952d9c5dc49c08466c8609b1de2f628cdc71ab  ABProfileManager/Data/BISRuntimeScoring.lua
b1184cc041d179d6d43463b58543e13d6504ac27  ABProfileManager/Data/BISMythicVaultLinks.lua
b27b68e8ddc95dba1a9f238432d7878c9e0deaaa  ABProfileManager/Data/BISSeasonPreviewLinks.lua
0192dcf511efd708e82b6e1a2521ca87358cf638  ABProfileManager/Data/BISEncounterJournal.lua
7c57c1c13d5cb5a1e8e8b8bba2de85bf33b9d5a4  ABProfileManager/Data/MidnightS1MPlusDB.lua
5e2e7ab04673834413cb9e169dc0a840454a05d4  ABProfileManager/Data/BISData.lua
367603310b6366448e8f93e267d2f732c1ef7254  ABProfileManager/Data/BISData_Method.lua
6b88749d036c3b25aa970d27506d851af92ee2a3  ABProfileManager/Data/StatPriorities.lua
0f5fe46cd949b72a160ec804ace9c5e37978c0fd  ABProfileManager/Data/StatPriorityTable.lua
```

참고: `UI/BISOverlay.lua`는 동결 대상이 아닙니다. v1.11.11 기준 해시는 `581eb5ba7cc2e1662cf42f7c302ae5f9dd5eec58`이고, W8과 G1 반영 후 해시는 `b317cc5f165f988b5db87e55544e19fd00c528af`입니다.

## 5. BIS 동결의 파급 (반드시 처리)

BIS 데이터를 동결하면 시즌 2에서 BIS 오버레이가 **조용히 오작동**합니다. 동결 결정 자체는 유지하되, 이 저하를 사용자에게 숨기지 않는 것이 v1.12.0의 필수 작업입니다.

| 위치 | 시즌 1 고정값 | 시즌 2에서 생기는 문제 |
| --- | --- | --- |
| `Data/BISMythicVaultLinks.lua` 14행 | `baselineItemLevel = 272`, selector `12801` | 시즌 2 Myth 1/6 템렙이 달라 preview 검증이 실패한다. 다른 템렙으로 해석된 preview는 세션 음성 캐시로 재시도가 막히므로 **M+ 자동 점수화가 전부 무효**가 되고 정적 순서만 남는다 |
| `Data/BISSeasonPreviewLinks.lua` | raid/tier `272~289`, crafted `285` | 검증 범위 밖이라 hover 툴팁이 전부 기본 `itemLink` fallback으로 떨어진다 |
| `Data/BISEncounterJournal.lua` 9~10행 | `currentSeasonJournalTierID = 505`, `currentSeasonTierIndex = 13` | M+ 클릭 랜딩이 시즌 1 tier로 간다 |
| `Data/BISCatalog.lua` | 시즌 1 M+ 던전 풀 기준 후보 | 라이브 덤프 결과 시즌 2 던전 풀 8종이 시즌 1과 **하나도 겹치지 않는다**. M+ 후보 전부가 시즌 2에서 획득 불가다 |
| `Data/ItemLevelTable.lua` 83행 이후 | `itemLevel = 266 / 272`, 라벨 `쐐기 영웅 트랙 3/6 · 266` | 상단 아이템 레벨 오버레이는 시즌 2 값, BIS 툴팁은 시즌 1 값이라 **한 화면에서 수치가 모순**된다 |

또한 `AGENTS.md`의 "미완성 기능"에 이미 `시즌 교체 시 BIS M+ 던전 JournalInstanceID와 현재 시즌 tier 재검증`이 적혀 있습니다. 동결 결정과 충돌하므로 문서를 함께 정리합니다.

### 처리 방침 (W8)

- BIS 패널에 기준 시즌을 노출한다. 상단 안내는 한 줄 고정에 줄바꿈이 꺼져 있고 폭이 좁아 시즌 이름을 그대로 붙이면 스탯 정책 요약이 잘리므로, `S1` 형태의 짧은 접두와 경고색으로 표시한다.
- 시즌 불일치가 감지되면 Encounter Journal 자동 랜딩과 M+ 자동 점수화를 **끈다**. 실패를 반복 시도하지 않는다.
- 시즌 불일치 판정 근거는 `Data/ItemLevelTable.lua`의 `season` 값과 BIS 쪽 시즌 기준값 비교로 한다. 새 API를 쓰지 않는다.
- 후보 목록·순위 계산·카탈로그 데이터는 그대로 둔다.

이 작업은 BIS 데이터 변경이 아니라 표시 정직성 문제이므로 이번 범위에 포함합니다.

## 6. 미확정 데이터 (수집 필요)

아래 값은 아직 확정되지 않았습니다. 라이브 덤프 또는 실제 툴팁으로 확인하기 전에는 코드에 넣지 않습니다.

| 항목 | 상태 | 확정 방법 |
| --- | --- | --- |
| 시즌 2 M+ 아이템 레벨 (신화 0 ~ +12) | 확정 (정정본) | 제공 표의 2/6·3/6 값을 네 출처 기준으로 정정 |
| 구렁 단계별 아이템 레벨 | 확정 | 와우헤드 시즌 2 구렁 표 |
| 레이드 난이도별 아이템 레벨과 금고 | 확정 | 와우헤드 + 인게임 드랍 툴팁 |
| 등급별 최대 아이템 레벨 (`gradeMax`) | 확정 (`282 / 295 / 308 / 321 / 334`) | 문장 툴팁 5종 실측 |
| `expl` 탐험가 트랙 존재 여부 | 미확정 | 시즌 2에 대응 문장이 없다. 인게임 확인 필요 |
| 제작 base / r5 아이템 레벨 | 확정 (`318` / `331`) | 문장 툴팁 + 인게임 품질 보너스 툴팁 |
| 구렁 최고 단계 | 확정 (`11` 유지) | 와우헤드 시즌 2 구렁 가이드 |
| PvP 명예 / 정복 아이템 레벨 | 미확정 | 와우헤드에 시즌 2 페이지 없음. 인게임 상인 툴팁 |
| 영웅 던전 아이템 레벨 | 미확정 | 인게임 툴팁 |
| `Mistcrest` 통화 ID와 개명/교체 여부 | 확정 | 신규 ID `3442~3446`으로 교체 |
| 복원 열쇠 통화 ID | 확정 | `3028` 그대로 유효 |
| `Coiled Isle` UiMapID (후보 `2512`) | 후보만 있음 | `C_Map.GetBestMapForUnit("player")` 덤프 |
| 신규 구렁·던전 UiMapID | 미확정 | 현지 이동 후 지도 덤프 |
| M+ 던전 풀 8종과 각 `challengeMapID` | 확정 | 2026-08-27 `C_ChallengeMode.GetMapTable()` 덤프 완료 |
| 전문기술 지식 questID | 미확정 | 인게임 퀘스트 로그 확인 |
| 주간 이벤트 좌표 (시즌 1분도 미실측) | 미확정 | 인게임 실측 |

### 수집 진행 상황

통화 ID를 `C_CurrencyInfo.GetCurrencyInfo(id)`로 직접 훑어 확정했습니다. 통화 목록 API의 `currencyTypesID` 필드는 `nil`이라 쓸 수 없었습니다.

| ID | 이름 | 비고 |
| --- | --- | --- |
| 3028 | 복원된 금고 열쇠 | 시즌 1 값이 그대로 유효하다 |
| 3310 | 금고 열쇠 파편 | |
| 3378 | 새벽빛 마나용제 | |
| 3437~3441 | 모험가 / 노련가 / 챔피언 / 영웅 / 신화 안개문장 | 첫 번째 세트 |
| 3442~3446 | 모험가 / 노련가 / 챔피언 / 영웅 / 신화 안개문장 | 두 번째 세트, 이름이 같다 |
| 3465 | 맹독역병 마나용제 | |

확정된 사실입니다.

- `Mistcrest`의 한국어명은 `안개문장`입니다.
- 시즌 1 문장 ID `3383 / 3341 / 3343 / 3345 / 3347`과 **전혀 다른 ID**입니다. 즉 문장 통화는 재사용이 아니라 **신규 통화로 교체**됐고, `CREST_ID_BY_GRADE` 5개 항목을 전부 갈아야 합니다.
- 복원 열쇠 `3028`은 그대로이므로 `DELVE_RESTORED_KEY_CURRENCY_ID`는 수정할 필요가 없습니다.

두 세트 중 어느 쪽이 실제 통화인지도 확정했습니다.

| ID | quantity | maxQuantity | discovered |
| --- | --- | --- | --- |
| 3437 | 0 | 0 | false |
| 3438 | 40 | 0 | true |
| 3439 | 0 | 0 | false |
| 3440 | 0 | 0 | false |
| 3441 | 0 | 0 | false |
| 3442 | 2 | 300 | true |
| 3443 | 40 | 300 | true |
| 3444 | 10 | 300 | true |
| 3445 | 5 | 200 | true |
| 3446 | 0 | 200 | false |

`3442~3446`이 실제 사용 통화입니다. 등급별 상한이 `300 / 300 / 300 / 200 / 200`으로 잡혀 있고 대부분 발견 상태입니다. `3437~3441`은 상한이 전부 `0`이고 `3438`만 발견돼 있는데, 그 수량 `40`이 `3443`과 정확히 같습니다. 계정 공유 사본이나 누적 집계용 거울 통화로 보이며 표시에 쓰지 않습니다.

| 등급 | 통화 ID |
| --- | --- |
| `adv` 모험가 | 3442 |
| `vet` 노련가 | 3443 |
| `chmp` 챔피언 | 3444 |
| `hero` 영웅 | 3445 |
| `myth` 신화 | 3446 |

`C_ChallengeMode.GetMapTable()` 덤프로 시즌 2 M+ 던전 풀 8종과 `challengeMapID`가 확정됐습니다.

| challengeMapID | 던전 |
| --- | --- |
| 249 | 왕들의 안식처 |
| 250 | 세스랄리스 사원 |
| 399 | 루비 생명의 웅덩이 |
| 584 | 눈부신 골짜기 |
| 585 | 공허흉터 투기장 |
| 586 | 날로라크의 소굴 |
| 587 | 죽음의 골목 |
| 588 | 송곳니의 제단 |

시즌 1 풀은 `Algeth'ar Academy`, `Magisters' Terrace`, `Maisara Caverns`, `Nexus-Point Xenas`, `Pit of Saron`, `Seat of the Triumvirate`, `Skyreach`, `Windrunner Spire`였습니다(`scripts/audit_bis_data.py` 출력 기준). **겹치는 던전이 하나도 없습니다.** 즉 동결된 BIS 카탈로그의 M+ 후보는 시즌 2에서 전부 획득 불가이며, 5장의 판단이 확인됐습니다.

`challengeMapID`는 `JournalInstanceID`나 `UiMapID`와 다른 값입니다. 지도와 Encounter Journal 작업에는 별도 확인이 필요합니다.

### 시즌 2 M+ 아이템 레벨 (인게임 표 실측)

출처 태그는 `tooltip`입니다.

| 단수 | 클리어 | 위대한 금고 |
| --- | --- | --- |
| 신화 0 | 292 (챔피언 1/6) | 302 (챔피언 4/6) |
| +2 | 296 (챔피언 2/6) | 305 (영웅 1/6) |
| +3 | 296 (챔피언 2/6) | 305 (영웅 1/6) |
| +4 | 299 (챔피언 3/6) | 309 (영웅 2/6) |
| +5 | 302 (챔피언 4/6) | 309 (영웅 2/6) |
| +6 | 305 (영웅 1/6) | 312 (영웅 3/6) |
| +7 | 305 (영웅 1/6) | 315 (영웅 4/6) |
| +8 | 309 (영웅 2/6) | 315 (영웅 4/6) |
| +9 | 309 (영웅 2/6) | 315 (영웅 4/6) |
| +10 | 312 (영웅 3/6) | 318 (신화 1/6) |
| +11 | 312 (영웅 3/6) | 318 (신화 1/6) |
| +12 이상 | 312 (영웅 3/6) | 318 (신화 1/6) |

시즌 1과 달리 영웅 던전 행은 이 표에 없습니다. `mythicPlus.heroic` 값은 따로 확인해야 합니다.

### 등급 상한 유도값 (미확정, 실측 필요)

위 표의 트랙 라벨에서 각 등급의 1/6 값이 나옵니다. 시즌 1이 6단계에 걸쳐 `+17`(단계별 `4, 3, 3, 3, 4`)이었고 시즌 2 표의 관측 구간도 같은 간격을 보입니다.

| 등급 | 1/6 관측값 | 6/6 유도값 |
| --- | --- | --- |
| `chmp` 챔피언 | 292 | 309 |
| `hero` 영웅 | 305 | 322 |
| `myth` 신화 | 318 | 335 |

`expl`, `adv`, `vet`는 관측값이 없습니다.

**이 유도값은 코드에 넣지 않습니다.** 3장 정책상 산술로 만든 값은 근거가 아닙니다. 아이템 강화 NPC의 트랙 표에서 각 등급 `6/6` 값을 직접 확인한 뒤 반영합니다. 검증기가 `maxilvl`이 `gradeMax`와 일치하는지 검사하므로 상한이 확정돼야 M+ 행도 쓸 수 있습니다.

### W2 착수에 아직 필요한 값

- 등급별 최대 아이템 레벨 6종 (`expl` / `adv` / `vet` / `chmp` / `hero` / `myth`)
- 영웅 던전 클리어·금고 아이템 레벨
- 구렁 단계별 드랍·금고 아이템 레벨과 최고 단계 (시즌 1은 11단계)
- 레이드 일반 / 영웅 / 신화 드랍 범위와 금고 값
- 제작 base / r5 아이템 레벨
- PvP 명예 / 정복 범위
- 월드 보스 아이템 레벨

### 와우헤드 조사 결과 (출처 `guide`, 인게임 확인 전)

2026-08-28 조사입니다. 6장 정책상 이 값들은 그대로 코드에 넣지 않습니다.

**아이템 레벨 상승 폭이 공식 발표됐습니다.** 시즌 1 대비 통상 `+39`가 아니라 **`+46`**입니다. Blizzard가 PTR 피드백을 받아 7을 더 올렸다고 밝혔습니다. Myth 9/6 최대는 `344`입니다.

우리 시즌 1 실측표에 `+46`을 적용하면 인게임 M+ 표와 정확히 맞습니다.

| 항목 | 시즌 1 | +46 | 인게임 실측 |
| --- | --- | --- | --- |
| M+ 신화 0 클리어 | 246 | 292 | 292 ✓ |
| 영웅 트랙 1/6 | 259 | 305 | 305 ✓ |
| 금고 신화 1/6 | 272 | 318 | 318 ✓ |

**제작 아이템 레벨은 두 출처가 일치해 사실상 확정입니다.**

| 등급 | 시즌 1 | +46 | 와우헤드 제작 표 |
| --- | --- | --- | --- |
| base (룬각인) | 272 | 318 | Epic Hero `305 - 318` 상한 |
| r5 (금박) | 285 | 331 | Epic Myth `318 - 331` 상한 |

**구렁은 최고 단계가 `11`로 유지됩니다.** 다만 문장 등급 매핑이 시즌 1과 다릅니다.

| 단계 | 시즌 1 `crestDrop` | 시즌 2 (와우헤드) |
| --- | --- | --- |
| T4 | adv | adv |
| T5~6 | vet | vet |
| T7~10 | chmp | chmp |
| T11 | chmp (11단계만 myth) | hero. 황금 보관함은 hero + myth |

**등급 상한은 아직 확정할 수 없습니다.** 출처끼리 어긋납니다.

| 등급 | 시즌 1 실측 + 46 | 전투부대 업적 임계값 |
| --- | --- | --- |
| adv | 283 | 282 |
| vet | 296 | 295 |
| chmp | 309 | 308 |
| hero | 322 | 321 |
| myth | 335 | 331 |

adv부터 hero까지는 `1` 차이, myth는 `4` 차이입니다. 업적 임계값이 트랙 6/6과 같다는 보장이 없고(시즌 1 제작 r5 `285`가 myth 상한 `289`보다 낮았던 것과 같은 구조), 시즌 1 실측표 자체가 6/6이 아니라 다음 트랙 시작값일 가능성도 남아 있습니다. **아이템 강화 NPC(실버문 `Cuzolth`)의 트랙 표를 직접 봐야 끝납니다.**

**스키마에 영향을 주는 변경도 있습니다.**

- 와우헤드는 시즌 2 업그레이드 트랙을 `Adventurer ~ Myth` **5종**으로 설명합니다. 현재 `gradeMax`에는 `expl`이 있고 `scripts/validate_season2_itemlevel.py`의 `GRADE_ORDER`도 6종을 요구합니다. `expl` 트랙이 없어졌다면 검증기도 함께 고쳐야 합니다.
- `Lair`라는 신규 콘텐츠가 추가됐습니다. `The Tidebound Grotto`가 첫 Lair이며 World부터 Mythic까지 난이도가 있고 위대한 금고 레이드 칸에 반영됩니다. 현재 표의 `worldBoss` 항목을 Lair로 대체할지 판단이 필요합니다.
- `Ascendant Venomstone`이 무기·장신구·목을 Myth 8 상당까지 올립니다. 최대 아이템 레벨 표기에 영향을 줄 수 있습니다.

### 시즌 2 업그레이드 트랙 범위 (문장 툴팁 실측, 출처 `tooltip`)

2026-08-28 인게임 문장 툴팁에서 직접 확인했습니다. 강화 NPC 화면을 볼 필요 없이 각 문장 툴팁이 트랙 범위와 제작 범위를 모두 적어 줍니다.

| 문장 | 장비 강화 범위 | 제작 아이템 레벨 범위 |
| --- | --- | --- |
| 모험가 안개문장 | 269 ~ 282 | 266 ~ 279 |
| 노련가 안개문장 | 282 ~ 295 | 279 ~ 292 |
| 챔피언 안개문장 | 295 ~ 308 | 툴팁에 없음 |
| 영웅 안개문장 | 308 ~ 321 | 305 ~ 318 |
| 신화 안개문장 | 321 ~ 334 | 318 ~ 331 |

와우헤드 값과 전부 일치합니다. 따라서 `gradeMax`는 `vet 295`, `chmp 308`, `hero 321`, `myth 334`입니다. 전투부대 업적 임계값이 myth만 `331`로 낮은 것은 업적 기준이 트랙 6/6과 다르기 때문이며 상한 판단에 쓰지 않습니다.

제작 값도 확정입니다. base(룬각인) `318`, r5(금박) `331`로 앞서 유도한 값과 같습니다.

문장 툴팁에 적힌 획득처도 시즌 1과 다릅니다.

| 문장 | 획득처 (툴팁) |
| --- | --- |
| 노련가 | 반복 야외 이벤트, 공격대 찾기 맹독 심연, 영웅 시즌 던전, 5~6 레벨 구렁, 4~5 레벨 보물 추적자의 은혜 |
| 챔피언 | 주간 야외 이벤트, 일반 맹독 심연, 신화 시즌 던전, 2~3 레벨 신화 쐐기돌 던전, 7~10 레벨 구렁, 6~7 레벨 보물 추적자의 은혜 |
| 영웅 | 영웅 맹독 심연, 4~8 레벨 신화 쐐기돌 던전, 11 레벨 구렁, 8 레벨 이상 보물 추적자의 은혜 |
| 신화 | 신화 맹독 심연, 9 레벨 이상 신화 쐐기돌 던전 |

주간 상한도 확인됐습니다. 노련가·챔피언은 `300`, 영웅은 `200`입니다.

### 트랙 범위 해석 (충돌 해소됨)

문장 툴팁의 아래쪽 값은 트랙 `1/6`이 아니라 `2/6`입니다. 문장은 `1/6`에서 `2/6`으로 올릴 때부터 쓰이므로 툴팁이 "이 문장으로 도달 가능한 범위"를 적기 때문입니다. 따라서 `1/6 = 툴팁 하한 - 3`입니다.

다섯 등급이 모두 이 규칙과 M+ 실측표에 동시에 들어맞습니다.

| 등급 | 1/6 | 2/6 (툴팁 하한) | 6/6 (`gradeMax`) | 제작 범위 |
| --- | --- | --- | --- | --- |
| `adv` 모험가 | 266 | 269 | 282 | 266 ~ 279 |
| `vet` 노련가 | 279 | 282 | 295 | 279 ~ 292 |
| `chmp` 챔피언 | 292 | 295 | 308 | 미표기 |
| `hero` 영웅 | 305 | 308 | 321 | 305 ~ 318 |
| `myth` 신화 | 318 | 321 | 334 | 318 ~ 331 |

M+ 실측표의 `챔피언 1/6 = 292`, `영웅 1/6 = 305`, `신화 1/6 = 318`이 그대로 맞습니다. 앞서 기록했던 "3 차이 충돌"은 툴팁 하한을 `1/6`으로 읽은 오독이었고 실제 충돌은 없습니다.

각 트랙은 `1/6`부터 `6/6`까지 `+16`이며 단계 간격은 `4, 3, 3, 3, 3`입니다. 제작 범위는 `1/6`부터 `6/6 - 3`까지입니다.

**확정된 `gradeMax`**: `adv 282`, `vet 295`, `chmp 308`, `hero 321`, `myth 334`.

`expl` 트랙은 시즌 2에 대응하는 문장이 없습니다. 현재 `Data/ItemLevelTable.lua`와 `scripts/validate_season2_itemlevel.py`의 `GRADE_ORDER`가 `expl`을 요구하므로, W2에서 이 항목을 어떻게 다룰지 결정해야 합니다. 탐험가 등급 장비가 시즌 2에 존재하는지 인게임에서 먼저 확인합니다.

문장 툴팁에 적힌 획득처는 다음과 같습니다.

| 문장 | 획득처 (툴팁) | 주간 상한 |
| --- | --- | --- |
| 모험가 | 반복 가능 야외 이벤트, 4 레벨 구렁 | 300 |
| 노련가 | 반복 야외 이벤트, 공격대 찾기 맹독 심연, 영웅 시즌 던전, 5~6 레벨 구렁, 4~5 레벨 보물 추적자의 은혜 | 300 |
| 챔피언 | 주간 야외 이벤트, 일반 맹독 심연, 신화 시즌 던전, 2~3 레벨 신화 쐐기돌 던전, 7~10 레벨 구렁, 6~7 레벨 보물 추적자의 은혜 | 300 |
| 영웅 | 영웅 맹독 심연, 4~8 레벨 신화 쐐기돌 던전, 11 레벨 구렁, 8 레벨 이상 보물 추적자의 은혜 | 200 |
| 신화 | 신화 맹독 심연, 9 레벨 이상 신화 쐐기돌 던전 | 200 |

### 확정된 랭크 사다리

트랙별 `1/6 ~ 6/6` 값이 네 출처에서 모두 일치합니다. 문장 툴팁, 와우헤드 M+ 표, 와우헤드 레이드 표, 인게임 레이드 드랍 툴팁입니다.

기준값에 `+0, +3, +6, +10, +13, +16`을 더하면 각 랭크가 나옵니다.

| 등급 | 1/6 | 2/6 | 3/6 | 4/6 | 5/6 | 6/6 |
| --- | --- | --- | --- | --- | --- | --- |
| `adv` | 266 | 269 | 272 | 276 | 279 | 282 |
| `vet` | 279 | 282 | 285 | 289 | 292 | 295 |
| `chmp` | 292 | 295 | 298 | 302 | 305 | 308 |
| `hero` | 305 | 308 | 311 | 315 | 318 | 321 |
| `myth` | 318 | 321 | 324 | 328 | 331 | 334 |

전투부대 업적 임계값 `282 / 295 / 308 / 321 / 331`은 앞 네 등급이 `6/6`, 신화만 `5/6`입니다. 앞서 신화만 `4` 어긋나 보였던 이유가 이것입니다.

### 사용자 제공 M+ 표의 오차

앞서 기록한 M+ 표는 `2/6`과 `3/6` 구간이 실제보다 `1`씩 높습니다.

| 랭크 | 제공 표 | 실제 (네 출처 일치) |
| --- | --- | --- |
| 챔피언 2/6 | 296 | 295 |
| 챔피언 3/6 | 299 | 298 |
| 영웅 2/6 | 309 | 308 |
| 영웅 3/6 | 312 | 311 |

`1/6`, `4/6`, `5/6` 값(292, 302, 305, 318 등)은 정확합니다. 해당 표는 인게임 화면이 아니라 커뮤니티 정리 자료로 보입니다. 아래 M+ 표는 와우헤드와 문장 툴팁 기준으로 정정한 값입니다.

### 시즌 2 M+ 아이템 레벨 (정정)

| 열쇠 단계 | 던전 종료 | 문장 | 위대한 금고 |
| --- | --- | --- | --- |
| 신화 0 | 292 (챔피언 1/6) | 챔피언 | 302 (챔피언 4/6) |
| +2 | 295 (챔피언 2/6) | 챔피언 | 305 (영웅 1/6) |
| +3 | 295 (챔피언 2/6) | 챔피언 | 305 (영웅 1/6) |
| +4 | 298 (챔피언 3/6) | 영웅 | 308 (영웅 2/6) |
| +5 | 302 (챔피언 4/6) | 영웅 | 308 (영웅 2/6) |
| +6 | 305 (영웅 1/6) | 영웅 | 311 (영웅 3/6) |
| +7 | 305 (영웅 1/6) | 영웅 | 315 (영웅 4/6) |
| +8 | 308 (영웅 2/6) | 영웅 | 315 (영웅 4/6) |
| +9 | 308 (영웅 2/6) | 신화 | 315 (영웅 4/6) |
| +10 | 311 (영웅 3/6) | 신화 | 318 (신화 1/6) |
| +11 | 311 (영웅 3/6) | 신화 | 318 (신화 1/6) |
| +12 이상 | 311 (영웅 3/6) | 신화 | 318 (신화 1/6) |

신화 0의 금고 값 `302`는 사용자 제공 표에서 가져왔고 와우헤드 표에는 신화 0 행이 없습니다. 별도 확인이 필요합니다.

### 시즌 2 구렁 아이템 레벨 (출처 `guide`)

| 단계 | 일반 보상 | 보물 추적자의 은혜 | 위대한 금고 | 문장 |
| --- | --- | --- | --- | --- |
| 1 | 266 (모험가 1/6) | - | 279 (노련가 1/6) | - |
| 2 | 269 (모험가 2/6) | - | 282 (노련가 2/6) | - |
| 3 | 272 (모험가 3/6) | - | 285 (노련가 3/6) | - |
| 4 | 276 (모험가 4/6) | 282 (노련가 2/6) | 289 (노련가 4/6) | 모험가 |
| 5 | 279 (노련가 1/6) | 289 (노련가 4/6) | 292 (챔피언 1/6) | 노련가 |
| 6 | 282 (노련가 2/6) | 292 (챔피언 1/6) | 298 (챔피언 3/6) | 노련가 |
| 7 | 292 (챔피언 1/6) | 295 (챔피언 2/6) | 302 (챔피언 4/6) | 챔피언 |
| 8 | 295 (챔피언 2/6) | 305 (영웅 1/6) | 305 (영웅 1/6) | 챔피언 |
| 9 | 295 (챔피언 2/6) | 305 (영웅 1/6) | 305 (영웅 1/6) | 챔피언 |
| 10 | 295 (챔피언 2/6) | 305 (영웅 1/6) | 305 (영웅 1/6) | 챔피언 |
| 11 | 295 (챔피언 2/6) | 305 (영웅 1/6) | 305 (영웅 1/6) | 영웅. 황금 보관함은 영웅 + 신화 |

시즌 1과 같은 구조로 8단계에서 상한이 고정되고 9~11단계는 값이 같습니다. 최고 단계는 `11`로 유지됩니다.

### 시즌 2 레이드 아이템 레벨 (와우헤드 + 인게임 툴팁)

보스 순서에 따라 값이 올라갑니다.

| 보스 | 공격대 찾기 | 일반 | 영웅 | 신화 |
| --- | --- | --- | --- | --- |
| 1 (Nek'zali) | 279 (노련가 1/6) | 292 (챔피언 1/6) | 305 (영웅 1/6) | 318 (신화 1/6) |
| 2~3 | 282 (2/6) | 295 (2/6) | 308 (2/6) | 321 (2/6) |
| 4~6 | 285 (3/6) | 298 (3/6) | 311 (3/6) | 324 (3/6) |
| 7~8 | 289 (4/6) | 302 (4/6) | 315 (4/6) | 344 (신화 9 상당) |

위대한 금고 보상은 난이도별로 다음과 같습니다.

| 난이도 | 금고 아이템 레벨 |
| --- | --- |
| 공격대 찾기 | 292 (챔피언 1/6) |
| 일반 | 305 (영웅 1/6) |
| 영웅 | 318 (신화 1/6) |
| 신화 | 334 (신화 6/6) |

매우 희귀 아이템과 신화 난이도 마지막 두 보스 드랍은 `344`(신화 9 상당)입니다.

인게임 `방파제 장화` 툴팁으로 일반 `292` 챔피언 1/6, 영웅 `305` 영웅 1/6, 신화 `318` 신화 1/6을 직접 확인했습니다. 해당 아이템의 출처는 `님리사 웨이브콜러`이며 Lair 보스입니다. 즉 **Lair 드랍이 레이드 첫 보스와 같은 아이템 레벨**입니다.

### 시즌 2 제작 아이템 레벨 (확정)

인게임 가죽세공 손목(`골목 방랑자의 굴절띠`) 품질 보너스 툴팁에서 제작 품질 사다리를 확인했습니다.

| 품질 | 보너스 | 예시 값 |
| --- | --- | --- |
| 1성 | +0 | 292 |
| 2성 | +3 | 295 |
| 3성 | +6 | 298 |
| 4성 | +9 | 301 |
| 5성 | +13 | 305 |

제작 품질 사다리는 `+0, +3, +6, +9, +13`으로 5단계이며, 강화 랭크 사다리(`+0, +3, +6, +10, +13, +16`, 6단계)와 다릅니다.

이 사다리를 문장 툴팁의 제작 범위에 적용하면 값이 정확히 맞습니다.

| 사용 문장 | 1성 | 5성 | 문장 툴팁 표기 |
| --- | --- | --- | --- |
| 영웅 안개문장 | 305 | 318 | `305 ~ 318` ✓ |
| 신화 안개문장 | 318 | 331 | `318 ~ 331` ✓ |

따라서 `Data/ItemLevelTable.lua`의 제작 항목은 다음과 같습니다. 시즌 1 값(`272` / `285`)에 `+46`을 적용한 결과와도 같습니다.

- `crafted.base` (룬각인): `318`
- `crafted.r5` (금박): `331`

**시즌 2 제작 최고 아이템 레벨은 `331`입니다.**

### PvP 자료 부재

와우헤드에 시즌 2 PvP 보상 페이지가 아직 없습니다. `midnight-pvp-rewards-season-2` 계열 주소는 모두 404이고 시즌 1 페이지만 존재합니다. 명예·정복 아이템 레벨은 인게임 상인 툴팁으로 확인해야 합니다.

시즌 1 값은 명예 `220~250`, 정복 `250~276`이었습니다. 단순히 `+46`을 더하면 `266~296`과 `296~322`가 되지만, 확정된 랭크 사다리에 맞추면 명예 `266~295`(모험가 1/6 ~ 노련가 6/6), 정복 `295~321`(챔피언 2/6 ~ 영웅 6/6)일 가능성이 있습니다. 어느 쪽도 근거가 없으므로 인게임 확인 전까지 반영하지 않습니다.

### 아직 없는 값

- PvP 명예 / 정복 아이템 레벨 (와우헤드에 시즌 2 페이지 없음, 인게임 상인 툴팁 필요)
- 영웅 던전 클리어·금고 아이템 레벨 (문장 툴팁상 노련가 문장을 주는 콘텐츠)
- `worldBoss` 항목을 Lair로 대체할지 여부 (설계 판단)
- `expl` 탐험가 트랙 존재 여부 (설계 판단)

### 수집용 인게임 명령

```text
/run local v,b,d,t=GetBuildInfo(); print("ABPM",v,b,d,t)
/run for _,id in ipairs(C_ChallengeMode.GetMapTable()) do local n=select(1,C_ChallengeMode.GetMapUIInfo(id)); print(id,n) end
/dump C_Map.GetBestMapForUnit("player")
/run for i=1,C_CurrencyInfo.GetCurrencyListSize() do local e=C_CurrencyInfo.GetCurrencyListInfo(i); if e then print(i,e.name,e.currencyTypesID) end end
```

수집 결과는 `DOC/season2/` 아래에 원문 그대로 남기고, 계약 파일에는 확정 값만 옮깁니다.

## 7. 현재 저장소 기준값 (시즌 1 상태)

수정 대상 파일의 현재 값입니다. 시즌 2 값과 대조할 baseline으로 사용합니다.

### `ABProfileManager/ABProfileManager.toc`

- `## Interface: 120005, 120007`
- `## Version: 1.11.11`

### `ABProfileManager/Constants.lua`

- `VERSION` fallback 문자열이 `"1.11.11"`
- `CLIENT_LOCALE_LANGUAGE`에 `koKR`, `enUS`, `enGB`만 매핑. `ruRU`는 `ABPM_ruRU_Final_v3.lua`가 런타임에 주입

### `ABProfileManager/Data/ItemLevelTable.lua` (116행)

- `season = "Midnight Season 1"`
- `gradeMax`: `expl 220 / adv 237 / vet 250 / chmp 263 / hero 276 / myth 289`
- `delves`: `tier 1~11`, 아이템 레벨은 8단계 `250`에서 상한 고정, 11단계만 `crestDrop="myth"`
- `mythicPlus.heroic` `230`, `mythicPlus.mythic0` `246`, `endOfDungeon` `key 2~12` (`250~266`)
- `raid`: normal `246~256` / heroic `259~269` / mythic `272~282`
- `worldBoss` `233`, `crafted.base` `272`, `crafted.r5` `285`
- `pvp.honor` `220~250`, `pvp.conquest` `250~276`
- 83행부터 `ns.Data.BISRewardProfiles` — **동결 구간**

### `ABProfileManager/UI/ItemLevelOverlay.lua` (1232행)

- `DELVE_RESTORED_KEY_CURRENCY_ID = 3028` (34행)
- `CREST_ID_BY_GRADE = { adv=3383, vet=3341, chmp=3343, hero=3345, myth=3347 }` (40~46행)
- 구렁 표는 `11단계`까지만 유효

### `ABProfileManager/Data/SilvermoonMapData.lua` (135행)

- `silvermoonPoints` 37개 POI (서비스/이동/전문기술/PvP/던전/구렁 카테고리)
- `aliases = { [2710]=2393, [2424]=1270 }`, 별도 `nameAliases` 존재

### `ABProfileManager/Data/WorldEventSchedule.lua` (61행)

- 주석이 `한밤 시즌 1 주간 이벤트` 기준
- `saldeerylsCourt` 등 이벤트가 `mapID = 2395`에 묶여 있음
- 좌표에 `※ 인게임 실측 후 수정` 주석이 남아 있음. 시즌 1분도 미실측 상태

### `ABProfileManager/Data/Defaults.lua` / `DB.lua`

- `Defaults.lua` 55행 `layoutVersion = 1`, 74행 `schemaVersion = 3`
- `DB.lua` 712~714행에서 `blizzardFrames.layoutVersion < 2`를 1회 마이그레이션
- `DB.lua` 1043행에서 BIS preview `schemaVersion` 3을 확인

### 기타

- `Data/ProfessionKnowledge.lua` 496행, `Data/ProfessionKnowledgeWaypoints.lua` 116행
- `UI/MythicPlusRecordOverlay.lua` 338행 — `평점 / 던전명`만 표시
- `Locale.lua` 922행 (`enUS`/`koKR` 3개 테이블: strings, classNames, specNames)
- `Locale_Additions.lua` 1174행
- `ABPM_ruRU_Final_v3.lua` — `ruRU` 확장. 1545행 부근에서 `Locale.strings.ruRU` 등을 주입하므로 TOC 로드 순서상 `UI/ConfigPanel.lua` 다음에 위치

## 8. 작업 DAG

```text
W0 공식자료 + 라이브 클라이언트 시즌 계약 확정
 ├─ W1 버전/TOC/API 호환성            (W0 없이 착수 가능)
 ├─ W6 검증 스크립트/범위 보호        (W0 없이 골격 착수 가능)
 ├─ W5a M+ 기록 UI / StatsOverlay 호환 (W0 없이 착수 가능)
 ├─ W8 BIS 시즌 불일치 안내            (W0 없이 착수 가능)
 ├─ W2 아이템레벨·통화·구렁 데이터
 │    └─ W2b ItemLevelOverlay 적용
 ├─ W3 지도·POI·alias·웨이포인트
 ├─ W4 전문기술 지식 데이터/API
 ├─ W7 주간 이벤트·SavedVariables 마이그레이션
 └─ W5b locale 3종                     (W2~W4 문자열 확정 후)
          ↓
     G1 명세 전용 리뷰
          ↓
     통합 및 전체 회귀
          ↓
     G2 코드 품질 전용 리뷰
          ↓
     12.1 인게임 QA
          ↺ 실패 작업만 담당 wave로 환류
          ↓
     문서·v1.12.0 패키징
```

동시 구현 에이전트는 최대 3명입니다. 코디네이터는 파일 소유권·의존성·통합만 담당하고 직접 구현하지 않습니다. 구현자와 리뷰어는 분리합니다.

**병렬성 주의**: W0은 인게임 덤프에 묶여 있어 W2, W2b, W3, W4, W7의 데이터 부분을 전부 막습니다. 덤프 수집 전에 실제로 병렬 진행할 수 있는 것은 `W1`, `W6`, `W5a`, `W8` 네 개뿐입니다. 계획 초안의 "항상 3명 병렬"은 W0 완료 이후에만 성립합니다.

### wave별 소유 파일과 완료 조건

| Wave | 소유 파일 | 산출물 | 완료 조건 |
| --- | --- | --- | --- |
| W0 | `DOC/season2/season-contract.md`, `DOC/season2/live-dump-*.txt` | 시즌 계약 문서 | 6장 표의 모든 항목이 확정 또는 "이번 릴리스 보류"로 결론 |
| W1 | `ABProfileManager.toc`, `Constants.lua`, `Core.lua` | `Interface: 120100`, `VERSION 1.12.0` | Lua 전체 파싱 통과, 인게임 로드 오류 없음 |
| W2 | `Data/ItemLevelTable.lua` (83행 이전만) | 시즌 2 아이템 레벨표 | `validate_season2_itemlevel.py` 통과, `BISRewardProfiles` 무변경 |
| W2b | `UI/ItemLevelOverlay.lua` | 통화 ID·구렁 단계·패널 표시 | 통화 nil일 때 오류 대신 `-` 표시 |
| W3 | `Data/SilvermoonMapData.lua`, `UI/SilvermoonMapOverlay.lua`, `UI/MapPanel.lua` | 신규 지역 POI·alias | canonical/alias/child/dungeon/unknown mapID 각각 검증 |
| W4 | `Data/ProfessionKnowledge.lua`, `Data/ProfessionKnowledgeWaypoints.lua`, `Modules/ProfessionKnowledgeTracker.lua` | 12.1 지식 소스·리셋 정책 | 주간 리셋 경계에서 카운트 오차 없음 |
| W5a | `UI/MythicPlusRecordOverlay.lua`, `UI/StatsOverlay.lua` | 기록 UI·스탯 12.1 호환 | `ChallengesFrame` 지연 로드에서 훅 1회 설치, secret number 직접 전달 없음 |
| W5b | `Locale.lua`, `Locale_Additions.lua`, `ABPM_ruRU_Final_v3.lua` | 3개 로케일 문자열 | `validate_locale_contract.py` 통과 |
| W6 | `scripts/validate_season2_*.py`, `scripts/validate_locale_contract.py`, `scripts/run_season2_validation.ps1` | 검증 하네스 | 하네스가 다른 wave 산출물에서 전부 통과 |
| W7 | `Data/WorldEventSchedule.lua`, `Data/Defaults.lua`, `DB.lua` | 시즌 2 이벤트·마이그레이션 | 시즌 1 SavedVariables로 로그인해도 위치·크기·탭·토글 유지 |
| W8 | `UI/BISOverlay.lua`, `AGENTS.md` 해당 절 | 시즌 불일치 안내 | 5장 처리 방침 4개 항목 충족, 동결 데이터 파일 무변경 |

파일 충돌 방지: 같은 파일을 두 wave가 동시에 수정하지 않습니다. `Locale*.lua`는 W5b 단독 소유이므로 다른 wave는 문자열 키만 요청하고 직접 편집하지 않습니다.

`Data/MidnightS1MPlusDB.lua`는 파일명이 시즌 1 기준이지만 동결 대상입니다. 시즌 2에서 이 DB를 계속 로드할지는 W8에서 결론을 내고 진행 로그에 남깁니다. 파일 자체는 이번 릴리스에서 수정하지 않습니다.

### 각 wave의 내부 루프

```text
근거 수집
 → 실패하는 계약/검증 작성
 → 최소 구현
 → 좁은 검증
 → 별도 리뷰
 → 통합 검증
 → 인게임 시나리오
 → 실패 시 해당 wave로 환류
```

## 9. 검증 하네스

| 스크립트 | 검사 내용 |
| --- | --- |
| `scripts/validate_season2_itemlevel.py` | 시즌명, 업그레이드 트랙, 구렁/M+/금고 행 수, rank·ilvl 일관성, **모든 수치의 출처 태그 존재 여부** |
| `scripts/validate_locale_contract.py` | `koKR`/`enUS`/`ruRU` 키 집합 일치, 빈 번역 검출 |
| `scripts/validate_season2_scope.py` | 4장 동결 파일 해시 일치, `ItemLevelTable.lua`의 `BISRewardProfiles` 이후 무변경 |
| `scripts/run_season2_validation.ps1` | 위 3종 + Lua 전체 파싱 + `git diff --check` + 기존 BIS 회귀 검증 순차 실행 |

실행 방법입니다. 릴리스 패키징 직전에는 반드시 `-Strict`로 실행합니다.

```powershell
pwsh -NoProfile -File .\scripts
un_season2_validation.ps1
pwsh -NoProfile -File .\scripts
un_season2_validation.ps1 -Strict
```

기준선 값 세 가지는 데이터가 바뀌면 함께 갱신합니다.

- `validate_season2_scope.py`의 `FROZEN_BLOB_HASHES`와 `REWARD_PROFILES_SHA256`
- `validate_locale_contract.py`의 `RURU_MISSING_BASELINE = 143`, `RURU_EXTRA_BASELINE = 11`
- `validate_season2_itemlevel.py`의 `SEASON1_NAME`

`validate_season2_itemlevel.py`는 `season`이 아직 시즌 1이면 출처 표기를 요구하지 않습니다. W2가 `season`을 바꾸는 순간 `sources` 테이블이 필수가 되며, 각 구간에 `dump` / `tooltip` / `guide` 중 하나를 적어야 합니다.

명세 보강 사항 두 가지입니다.

- `validate_locale_contract.py`는 `Locale.lua`만 봐서는 안 됩니다. `ruRU`는 `ABPM_ruRU_Final_v3.lua`가 TOC 맨 뒤에서 `Locale.strings.ruRU`에 주입하는 구조이므로, 주입 파일까지 파싱 대상에 넣어야 키 집합 비교가 성립합니다.
- `validate_season2_itemlevel.py`는 값 일관성만 검사하면 정책을 강제하지 못합니다. 실제 위험은 오탈자가 아니라 출처 없는 값이므로, 각 수치 그룹에 `source = "dump" | "tooltip" | "guide"` 태그를 요구하고 `guide`만 있는 값은 경고로 처리합니다.

기존 검증 명령은 `AGENTS.md`의 "검증 명령어" 절을 그대로 사용합니다. 2026-08-27 기준 전부 통과 상태입니다.

```text
validate_bis_catalog.py            ok: specs=40 rows=3330
validate_bis_season_preview_links  ok: raid=89 tier=65 crafted=28
validate_bis_tooltip_contract.py   ok (BISOverlay top-level locals 197)
```

W8이 `UI/BISOverlay.lua`를 수정하면 `validate_bis_tooltip_contract.py`의 top-level local 예산을 다시 통과해야 합니다. 현재 여유는 3개뿐이므로 새 local 대신 기존 테이블 필드를 사용합니다.

## 10. 핵심 엣지케이스와 중단 기준

### 엣지케이스

- 시즌 1 SavedVariables로 업그레이드해도 창 위치·크기·탭·토글이 유지된다
- `koKR`/`enUS`/`ruRU`에서 같은 행 수와 레이아웃을 유지한다
- 통화나 POI API가 `nil`이면 오류 대신 `-` 또는 숨김으로 처리한다
- 전투 중 API 호출로 taint 또는 보호 기능 차단 팝업이 생기지 않는다
- `ChallengesFrame`이 나중에 로드돼도 훅이 정확히 한 번만 설치된다
- 지도 canonical/alias/child/dungeon/unknown mapID를 각각 검증한다
- 구렁 단계별 일반/Bountiful/금고 보상을 분리해 표시한다
- secret number를 산술 연산이나 문자열 포맷에 직접 전달하지 않는다
- 지도 전환 후 이전 시즌 라벨이나 재사용 버퍼가 남지 않는다
- 동결 대상 BIS 파일과 `BISRewardProfiles`가 byte-identical이다
- BIS 패널이 시즌 불일치 상태를 숨기지 않는다

### 릴리스 중단 기준

아래 중 하나라도 해당하면 v1.12.0 패키징을 중단하고 진행 로그에 사유를 남깁니다.

- 동결 파일 해시가 하나라도 어긋난다
- 인게임 로드 시 Lua 오류가 발생한다
- 전투 중 보호 기능 차단 팝업이 재현된다
- 아이템 레벨표에 출처가 `guide`뿐인 값이 남아 있다
- 시즌 1 SavedVariables 업그레이드에서 설정 손실이 발생한다

인게임 QA는 `AGENTS.md`의 "인게임 회귀 체크리스트" 전체와 `/abpm debug on`, `/abpm bankcheck`, `/abpm bankreset`까지 포함합니다.

## 11. 진행 로그

작업할 때마다 이 표를 갱신합니다. 세션을 이어받는 쪽은 이 표를 먼저 읽습니다.

| Wave | 상태 | 담당 | 마지막 갱신 | 메모 |
| --- | --- | --- | --- | --- |
| W0 | 진행중 | Claude | 2026-08-27 | 빌드 정보, M+ 던전 풀 8종 `challengeMapID`, 통화 이름 계열 확정. 통화 ID, 아이템 레벨표, 지도 ID는 아직 미확정 |
| W1 | 완료 | Claude | 2026-08-27 | `Interface: 120100` 단일 지정, `Version 1.12.0`, `Constants.VERSION` fallback 갱신. Lua 64개 파싱 통과. 구형 `120005, 120007`은 라이브에 존재하지 않아 제거했다. `ADDON_INTRO.txt`의 버전 문구는 패키징 시점(13장)에 함께 갱신한다 |
| W2 | 대기 | - | 2026-08-28 | M+ 구간은 실측 확보. 등급 상한(`gradeMax`)과 구렁·레이드·제작·PvP 값이 없어 표를 못 바꾼다. 일부만 바꾸면 한 테이블에 두 시즌이 섞이고 `season`도 못 올려 `SeasonGuard`가 계속 잠든다 |
| W2b | 진행중 | Claude | 2026-08-28 | `CREST_ID_BY_GRADE`를 시즌 2 안개문장 `3442~3446`으로 교체. `DELVE_RESTORED_KEY_CURRENCY_ID`는 `3028` 그대로 유효해 수정하지 않았다. 구렁 최고 단계와 패널 수치는 W2 아이템 레벨표 확정 후 |
| W3 | 대기 | - | 2026-08-27 | W0 차단 |
| W4 | 대기 | - | 2026-08-27 | W0 차단 |
| W5a | 완료 | Claude | 2026-08-27 | `StatsOverlay`의 aura index 조회에 backoff 추가. 12.1 보호 상태에서 오류 경로를 매 refresh마다 밟지 않고, 부분 hash 대신 빈 값으로 통일한다. `MythicPlusRecordOverlay` 훅 감시자가 addon 이름에 의존하지 않도록 바꾸고 `PLAYER_ENTERING_WORLD`를 추가했다. `_hooksReady`로 1회 설치는 그대로 보장된다. 인게임 검증은 쐐기 진행 중 확인 필요 |
| W5b | 대기 | - | 2026-08-27 | W2~W4 문자열 확정 후 |
| W6 | 완료 | Claude | 2026-08-27 | 검증기 3종과 `run_season2_validation.ps1` 작성. 세 검증기 모두 음성 테스트로 실제 검출을 확인했다. 하네스 전체 통과 |
| W7 | 진행중 | Claude | 2026-08-27 | 마이그레이션 부분 완료. `DB:GetBISOverlayMythPreviewCache()`의 무효화 키에 현재 시즌을 추가해 시즌이 넘어가면 이전 시즌 snapshot을 한 번 비운다. 기존 무효화 조건이 전부 동결된 `BISMythicVaultLinks.lua`에서 와서 시즌 전환을 감지하지 못했다. 버전 상승이 설정을 초기화하지 않는 것도 확인했다(`layoutVersion`, `languageMigrationVersion`은 각자 카운터를 쓴다). 주간 이벤트 데이터는 W0 차단 |
| W8 | 완료 | Claude | 2026-08-27 | `UI/BISOverlay.lua`에 `SeasonGuard` 추가. `dataSeason = "Midnight Season 1"`과 `ItemLevelTable.season` 비교로 불일치 판정. 불일치 시 EJ 자동 랜딩, M+ 자동 점수화, preview snapshot 스캔, preview 순위 점수를 모두 차단하고 상단 안내에 `[기준 시즌]` 접두를 붙인다. 새 해시 `git hash-object`로 확인 필요. top-level locals `197 → 198`(상한과 동일). `AGENTS.md` 충돌 항목 정리 완료. `Data/MidnightS1MPlusDB.lua`는 계속 로드하되 SeasonGuard가 의존 자동화를 끄는 것으로 결론. 인게임 검증은 W2가 `season`을 시즌 2로 바꾼 뒤 가능 |
| G1 | 완료 | Claude | 2026-08-28 | W1, W5a, W6, W7, W8 스펙 대조. 실제 결함 3건(안내 라벨이 스탯 요약을 잘라냄, README/AGENTS Interface 오정보, `GetTime` 부재 시 backoff 영구 차단)과 잠재 3건(시즌 판정 `nil` 캐시, hover preview 반복 시도, 로케일 검증기 대괄호 표기 누락) 도출. hover preview 반복 시도를 뺀 5건 수정 완료 |
| G2 | 미착수 | - | 2026-08-27 | |
| 인게임 QA | 미착수 | - | 2026-08-27 | |
| 패키징 | 미착수 | - | 2026-08-27 | |

상태 값은 `미착수` / `대기` / `진행중` / `리뷰대기` / `완료` / `보류` 중 하나를 씁니다. `대기`는 선행 작업 때문에 시작할 수 없는 상태입니다.

## 12. 재개 프롬프트

새 세션에서 아래 내용을 그대로 사용합니다.

```text
저장소 E:\Dev_ai\wowaddon, 브랜치 codex/midnight-s2-update에서 Midnight 시즌 2(v1.12.0) 작업을 이어서 진행해.
먼저 DOC/SEASON2_HANDOFF.md를 읽고 11장 진행 로그에서 다음 수행할 wave를 고른다.
승인된 전제는 3장에 있고, 4장의 동결 파일은 절대 수정하지 않는다.
6장 미확정 데이터는 라이브 덤프 없이 추정값으로 채우지 않는다. 필요하면 인게임 명령을 요청한다.
작업 후에는 9장 검증을 실행하고, 11장 진행 로그를 갱신한 다음 결과를 보고한다.
커밋 메시지와 PR 본문은 한국어로 작성한다.
```

## 13. 릴리스 마무리 체크

- `CHANGELOG.md`에 `1.12.0` 항목 추가
- `DOC/HANDOFF.md`에 v1.12.0 패치 메모 추가
- `DOC/releases/RELEASE_NOTES_v1.12.0.md` / `_EN.md` 작성
- `DOC/README.md` 인덱스 갱신
- `AGENTS.md`의 "현재 기준", Interface 번호, "미완성 기능"의 BIS 시즌 재검증 항목 갱신
- `CLAUDE.md`의 기준 버전 갱신 (현재 `v1.7.4`로 오래된 값이 남아 있음)
- `scripts/package_release.ps1` 실행 후 `dist/` 루트에 최신 ZIP만 유지, 이전 ZIP은 `dist/archive/`로 이동
- 로컬 배포는 `dist/` ZIP 생성까지만 수행하고 WoW 설치 폴더로 복사하지 않는다
