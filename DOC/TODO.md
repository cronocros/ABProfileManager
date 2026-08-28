# 남은 할 일

v1.12.0 시즌 2 작업 기준입니다. 다른 에이전트나 작업자가 이 문서만 읽고 이어받을 수 있도록 정리합니다.

작업 배경과 수집 경위는 [SEASON2_HANDOFF.md](./SEASON2_HANDOFF.md)를 봅니다. 소스 제약은 [CODE_NOTES.md](./CODE_NOTES.md)를 봅니다.

## 1. 릴리스를 막고 있는 것

`scripts/run_season2_validation.ps1 -Strict`가 실패합니다. 실패 이유는 하나입니다.

`ABProfileManager/Data/ItemLevelTable.lua`의 `sources` 표에서 `delves`, `mythicPlus`, `raid`, `pvp` 네 구간이 `guide`입니다. 외부 자료만 근거라는 뜻입니다. 인게임에서 확인한 뒤 해당 항목을 `tooltip`으로 바꾸면 풀립니다.

구간별로 무엇을 확인해야 하는지는 다음과 같습니다.

| 구간 | 확인 방법 | 비고 |
| --- | --- | --- |
| `pvp` | 실버문 PvP 허브의 명예 상인과 정복 상인 아이템 툴팁 | 현재 값 `266~295`, `295~321`은 추정치다. 가장 근거가 약하다 |
| `delves` | 구렁 1~11단계 보상 아이템 툴팁 | 8단계에서 상한이 고정되는지 함께 본다 |
| `mythicPlus` | 쐐기 완료 보상과 위대한 금고 툴팁 | `2/6`과 `3/6` 값이 특히 헷갈린다 |
| `raid` | 맹독 심연 보스별 드랍 툴팁 | 1보스와 마지막 두 보스를 우선 확인한다 |

확인이 끝난 구간만 골라 태그를 바꿔도 됩니다. 전부 `tooltip` 또는 `dump`가 되면 `-Strict`가 통과합니다.

## 2. 인게임 확인이 필요한 동작

아직 게임에서 눈으로 보지 못한 변경입니다. `dist/ABProfileManager-v1.12.0.zip`을 설치해 확인합니다.

- BIS 패널 상단 안내에 `[S1]` 접두와 경고색이 나오는가
- BIS 드랍 출처를 클릭하면 모험 안내서로 이동하지 않고 채팅에 기준 시즌 안내가 나오는가
- M+ 자동 점수화가 돌지 않고 정적 순서만 유지되는가
- 드랍템 레벨 오버레이의 구렁 탭이 `266`부터 `295`까지 나오는가
- 레이드 탭에 월드 보스가 야외·일반·영웅·신화 네 줄로 나오는가
- 문장 패널의 안개문장 다섯 종 수량이 실제 보유량과 맞는가
- BIS 오버레이 로드 시 `main function has more than 200 local variables` 오류가 없는가
- 쐐기 진행 중 스탯 오버레이가 갱신되고 오류가 없는가

## 3. 미착수 작업

### W3 지도와 POI

`Data/SilvermoonMapData.lua`, `UI/SilvermoonMapOverlay.lua`, `UI/MapPanel.lua`가 대상입니다.

`Coiled Isle`의 UiMapID가 아직 없습니다. 후보는 `2512`지만 확인되지 않았습니다. 해당 지역 안에서 아래를 실행해야 합니다.

```text
/dump C_Map.GetBestMapForUnit("player")
```

신규 구렁과 던전의 UiMapID도 각각 현지에서 확인해야 합니다. `challengeMapID`는 이미 확보했지만 `UiMapID`와는 다른 값입니다.

### W4 전문기술 지식

`Data/ProfessionKnowledge.lua`, `Data/ProfessionKnowledgeWaypoints.lua`, `Modules/ProfessionKnowledgeTracker.lua`가 대상입니다.

12.1 지식 소스와 주간 리셋 정책, 신규 questID가 필요합니다. 인게임 퀘스트 로그에서 확인합니다.

### W5b 로케일

`Locale.lua`, `Locale_Additions.lua`, `ABPM_ruRU_Final_v3.lua`가 대상입니다.

W2와 W2b가 만든 새 문자열이 있으면 세 언어에 반영합니다. 현재 `ruRU`는 `enUS` 대비 143개가 비어 있고 이 숫자가 `scripts/validate_locale_contract.py`의 기준선입니다. 번역을 채우면 기준선도 함께 낮춥니다.

`ruRU`는 `ABPM_ruRU_Final_v3.lua`가 TOC 맨 뒤에서 주입하는 구조입니다. 새 키를 넣을 때 이 파일도 함께 고쳐야 검증을 통과합니다.

### W7 주간 이벤트

`Data/WorldEventSchedule.lua`가 시즌 1 기준입니다. 좌표에 `인게임 실측 후 수정` 주석이 있었고 시즌 1분도 실측되지 않았습니다. 시즌 2 이벤트 목록과 좌표가 필요합니다.

SavedVariables 마이그레이션 부분은 끝났습니다.

## 4. 판단이 남은 항목

- 일반 던전 아이템 레벨 `214`는 강화 트랙이 없습니다. 현재 스키마에 일반 던전 항목이 없어 넣지 않았습니다. 표시할 가치가 있는지 결정이 필요합니다.
- 시즌 불일치 상태에서도 raid·tier·crafted hover는 계속 preview 링크를 시도합니다. `SeasonGuard`가 이 경로까지 막을지 결정이 필요합니다. 명세의 처리 방침에는 없는 범위입니다.
- `UI/BISOverlay.lua`의 top-level local이 `198`로 상한과 같습니다. 이 파일에 새 local을 추가하면 `scripts/validate_bis_tooltip_contract.py`가 실패합니다. 새 기능은 기존 테이블의 필드로 넣어야 합니다.

## 5. BIS 시즌 2 (진행 중)

### 완료

`ABProfileManager/Data/BISData_Method.lua`를 시즌 2 와우헤드 데이터로 갱신했습니다. 40개 전문화 641행이며 시즌 1 던전 참조는 없습니다. 이 파일은 TOC에 없어 런타임에 로드되지 않으므로 인게임 동작은 아직 바뀌지 않습니다.

`scripts/refresh_wowhead_bis.py`도 함께 고쳤습니다. 괄호 한정어가 붙은 슬롯 라벨을 처리하고, 시즌 2 던전·보스 정규화를 넣고, 대상 파일을 쓰지 않고 결과만 확인하는 `--review` 모드를 추가했습니다.

### 카탈로그 재생성 완료 (B안)

와우헤드 overall 데이터만으로 카탈로그를 다시 만들었습니다. `3330`행에서 `641`행으로 줄었지만 전부 시즌 2 데이터입니다.

| sourceGroup | 행 |
| --- | --- |
| raid | 371 |
| crafted | 103 |
| mythicplus | 88 |
| tier | 79 |

시즌 1 던전 참조는 하나도 남지 않았습니다. 보스 한글명은 공식 Blizzard 한국어 소식에서 확인한 이름을 씁니다.

`ns.Data.BISSpecPolicies` 블록은 재생성하지 않고 기존 값을 그대로 옮깁니다. 12.0.5 기준으로 동결된 스탯 우선순위 정책이기 때문입니다.

### 이전 기록 (해결됨)

카탈로그 재생성이 불가능했습니다. `scripts/build_bis_catalog.py`는 후보 풀을 `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`에서 가져오는데 이것이 시즌 1 데이터입니다. 현재 카탈로그 3330행 중 대부분이 여기서 오고, 와우헤드에서 얻을 수 있는 것은 641행뿐입니다. 그중 M+는 88행에 불과합니다.

지금 재생성하면 시즌 1 후보 풀에 시즌 2 overall만 얹힌 잡탕이 됩니다. 선택이 필요합니다.

B안을 선택해 진행했습니다. "적지만 맞는 추천"이 "많지만 획득 불가한 추천"보다 낫다는 판단입니다.

### 이후 단계 (카탈로그 결정 후)



`Data/BISCatalog.lua`는 시즌 2로 재생성했습니다. 나머지 런타임 BIS 데이터는 아직 시즌 1 기준입니다. 그래서 `SeasonGuard`를 계속 켜 둡니다. 시즌 2 던전 풀은 시즌 1과 겹치는 던전이 하나도 없으므로 BIS의 M+ 후보는 전부 획득할 수 없는 아이템입니다.

`SeasonGuard`가 자동 동작을 꺼서 잘못된 값을 보여주지는 않지만, 추천 목록 자체는 여전히 시즌 1 아이템입니다. 남은 단계는 다음과 같습니다.

- `Data/BISMythicVaultLinks.lua`의 `baselineItemLevel`을 `272`에서 시즌 2 값으로 교체하고 selector 재검토
- `Data/BISSeasonPreviewLinks.lua`의 검증 범위 갱신
- `Data/BISEncounterJournal.lua`의 `currentSeasonJournalTierID`와 `currentSeasonTierIndex` 갱신
- `Data/ItemLevelTable.lua` 하단 `BISRewardProfiles`의 아이템 레벨과 라벨 갱신
- 위 작업 후 `UI/BISOverlay.lua`의 `SeasonGuard.dataSeason`을 `Midnight Season 2`로 올린다. 올리지 않으면 자동 동작이 계속 꺼진 상태로 남는다
- `scripts/validate_season2_scope.py`의 `FROZEN_BLOB_HASHES`와 `REWARD_PROFILES_SHA256`도 새 값으로 교체한다

스탯 우선순위 값도 `12.0.5` 기준으로 동결돼 있습니다. BIS 점수 파이프라인과 공유하므로 함께 다뤄야 합니다.

## 6. 릴리스 절차

`-Strict`가 통과한 뒤 진행합니다. 자세한 절차는 [RELEASE_PROCESS.md](./RELEASE_PROCESS.md)를 봅니다.

- `CHANGELOG.md`의 `1.12.0` 항목을 릴리스 기준으로 확정
- `DOC/releases/RELEASE_NOTES_v1.12.0.md`와 영문판 작성
- `ABProfileManager/ADDON_INTRO.txt`의 버전 문구에서 `작업 중` 표기를 제거하고 변경 내역 추가
- `scripts/package_release.ps1` 실행
- `dist/` 루트에는 최신 ZIP만 두고 이전 ZIP은 `dist/archive/`로 이동
- 로컬 배포는 `dist/` ZIP 생성까지만 수행한다
