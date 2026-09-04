# 남은 할 일

v1.13.0 시즌 2 작업 기준입니다. 다른 에이전트나 작업자가 이 문서만 읽고 이어받을 수 있도록 정리합니다.

작업 배경과 수집 경위는 [SEASON2_HANDOFF.md](./SEASON2_HANDOFF.md)를 봅니다. 소스 제약은 [CODE_NOTES.md](./CODE_NOTES.md)를 봅니다.

## 1. 릴리스를 막고 있는 것

`scripts/run_season2_validation.ps1 -Strict`가 실패합니다. 실패 이유는 하나입니다.

`ABProfileManager/Data/ItemLevelTable.lua`의 `sources` 표에서 `delves`, `mythicPlus` 두 구간이 `guide`입니다. PvP는 인게임 상인 툴팁으로, `raid`는 모험 안내서 전리품 목록으로 2026-08-28 확인해 각각 `tooltip`, `dump`로 올렸습니다. 외부 자료만 근거라는 뜻입니다. 인게임에서 확인한 뒤 해당 항목을 `tooltip`으로 바꾸면 풀립니다.

구간별로 무엇을 확인해야 하는지는 다음과 같습니다.

| 구간 | 확인 방법 | 비고 |
| --- | --- | --- |
| `delves` | 구렁 완료 후 보상 상자 아이템 툴팁 | API가 없다. 이번 주 구렁을 돌면 위대한 금고 `세계` 칸이 채워져 금고값은 `C_WeeklyRewards.GetActivities`로도 확인된다. 2026-09-03 와우헤드 구렁 표로 11단계 전 구간(완료 보상 `266/269/272/276/279/282/292/295/295/295/295`, 금고 `279/282/285/289/292/298/302/305/305/305/305`)이 저장소 값과 일치함을 확인했다. 외부 자료라 태그는 그대로 `guide`다 |
| `mythicPlus` | 쐐기 한 판 완료 후 종료 상자 아이템 | 금고 열은 `C_MythicPlus.GetRewardLevelForDifficultyLevel`로 검증했다(11개 중 10개 일치). 던전 종료 열만 남았다. `+8` 금고값이 API에서 `305`로 나오나 앞뒤가 `315`라 API 이상값으로 판단해 표는 `315`를 유지한다 |

확인이 끝난 구간만 골라 태그를 바꿔도 됩니다. 전부 `tooltip` 또는 `dump`가 되면 `-Strict`가 통과합니다.

## 2. 인게임 확인이 필요한 동작

아직 게임에서 눈으로 보지 못한 변경입니다. `dist/ABProfileManager-v1.13.0.zip`을 설치해 확인합니다.

- 냉기 죽음의 기사로 BIS 오버레이를 열어 `가슴` 줄에 투구가 아닌 가슴 방어구가 나오는가
- 수양·신성 사제로 출처 필터를 `레이드`, `쐐기`로 두었을 때 아이템이 잡히는가
- `USER_SELECTED` 8개 전문화(혈기 죽기, 수호 드루, 보존 기원사, 양조·운무 수도, 신성 사제,
  무법 도적, 고양 주술)의 스탯 우선순위가 복구된 값으로 나오는가
- 무법 도적의 스탯 줄이 `가속`으로 시작하는가 (2026-09-03 데이터를 `가속` 1순위로 정정했습니다)
- 복원 주술사의 스탯 줄이 `치명타 및 극대화 > 가속 = 유연성 > 특화`로 나오는가
- 애드온 언어를 `영어`로 바꾼 뒤 `/abpm`, `/abpm help`, `/abpm copy`, `/abpm bankcheck`,
  전문기술 오버레이의 항목 이름, 상태 메시지 접두(`● Info:` / `● Success:` / `◆ Failure:`)가
  모두 영어로 나오는가
- BIS 아이템 클릭 시 모험 안내서가 해당 던전·레이드의 해당 보스까지 열리는가
- 출처 라벨이 `던전명 · 보스명`, `레이드명 · 보스명`으로 나오는가
- 툴팁 단계 선택 버튼이 헤더에 보이고, 단계를 바꾸면 `기준:` 줄이 따라 바뀌는가
- BIS 창을 한 번 열어 스캔을 마친 뒤 `/reload` 하면 보스명이 재스캔 없이 즉시 붙는가
- 신화+ 탭에서 던전명과 `+레벨 점수` 오버레이가 나오는가
- 드랍템 레벨 정보 창의 다섯 탭 모두에서 하단 스트립이 본문과 겹치지 않는가
- 하단에 오늘의 풍요 구렁 이름이 마우스 오버 없이 바로 보이는가
- 시즌 1 지역 지도에서 시즌 2 던전 입구가 표시되는가

진단이 필요하면 다음을 씁니다.

- `/abpm copy mplus` 쐐기 오버레이 진단
- `/abpm copy ej` 모험 안내서 이동 진단
- `/abpm copy log` 디버그·오류 로그

## 3. 미착수 작업

### W3 지도와 POI

`Data/SilvermoonMapData.lua`, `UI/SilvermoonMapOverlay.lua`, `UI/MapPanel.lua`가 대상입니다.

`Coiled Isle`(똬리의 섬)의 UiMapID `2512`는 DB2(`UiMap`, ParentUiMapID 2537)로 확인해 `SilvermoonMapData.lua`에 넣었습니다. 하위 지도 `2509`는 `Vaults of Atal'Utek`이며 송곳니의 제단 입구가 있는 구역입니다. 인게임 최종 확인은 해당 지역 안에서 아래를 실행합니다.

```text
/dump C_Map.GetBestMapForUnit("player")
```

던전·레이드 입구와 구렁 위치는 하드코딩하지 않고 `C_EncounterJournal.GetDungeonEntrancesForMap`, `C_AreaPoiInfo.GetDelvesForMap`으로 런타임 조회합니다. 조회 대상 지도는 `SilvermoonMapData.lua`의 `runtimeMaps`입니다. `challengeMapID`는 `UiMapID`와 다른 값입니다.

### W4 전문기술 지식

`Data/ProfessionKnowledge.lua`, `Data/ProfessionKnowledgeWaypoints.lua`, `Modules/ProfessionKnowledgeTracker.lua`가 대상입니다.

2026-09-03에 12.1 신규 평판 서적을 반영했습니다. `Zul'jarra's Forces` 평판 6단계에서 열리는 `Demystifyin': <직업>` 11종이며 각 10점입니다. 판매처는 똬리의 섬의 `Jan'sari the Watchful`입니다. questID는 DB2로 확인했습니다.

| 직업 | itemID | questID |
| --- | --- | --- |
| 연금술 | 274500 | 96459 |
| 대장기술 | 274515 | 96511 |
| 마법부여 | 274511 | 96512 |
| 기계공학 | 274516 | 96513 |
| 약초채집 | 274513 | 96514 |
| 주문각인 | 274514 | 96515 |
| 보석세공 | 274510 | 96516 |
| 가죽세공 | 274507 | 96517 |
| 채광 | 274509 | 96518 |
| 무두질 | 274508 | 96519 |
| 재봉술 | 274512 | 96520 |

확인 경로는 `ItemXItemEffect` → `ItemEffect` → `SpellEffect`입니다. `Effect = 16`(퀘스트 완료)의 `EffectMiscValue_0`이 questID이고, `Effect = 157`의 `EffectBasePointsF`가 지식 `10`점입니다. 공식 한국어명은 `누구나 쉽게 배우는 기술: <직업>`입니다.

2026-09-04에 주간 questID 72개를 DB2(`QuestV2`, 빌드 `12.1.0.69465`)로 선검증했습니다. 72개 모두 존재합니다.

그 과정에서 **주간 퀘스트 변형 4개가 빠져 있던 것을 찾아 채웠습니다.** 변형 목록은 `match = "any"`라서 빠진 ID가 그 주에 걸리면 완료를 감지하지 못합니다.

| 직업 | 추가한 questID | 퀘스트 이름 | 확인 근거 |
| --- | --- | --- | --- |
| 마법부여 | 93697 | `Shimmering Melodies` | 와우헤드, 보상 `Thalassian Enchanter's Folio` |
| 약초채집 | 93701 | `Brittle and Brilliant` | 와우헤드, 보상 `Thalassian Herbalist's Notes` |
| 채광 | 93707 | `It's Called Silvermoon` | 와우헤드, 보상 `Thalassian Miner's Notes` |
| 무두질 | 93713 | `Essential Materials` | 와우헤드, 보상 `Thalassian Skinner's Notes` |

이제 questID 블록이 연속 구간으로 맞습니다. 제작 7종은 `93690~93696` 각 1개, 마법부여는 `93697~93699`, 약초채집 `93700~93704`, 채광 `93705~93709`, 무두질 `93710~93714`입니다.

남은 것은 인게임 확인 두 가지입니다.

- `treatise` questID 11개(`95127~95131`, `95133~95138`)는 와우헤드에 노출되지 않는 숨은 퀘스트라 이름을 대조하지 못했습니다. DB2 존재만 확인했습니다. 각 직업 논문을 읽고 지식이 오르는지 확인합니다.
- `weekly_drops`와 `weekly_gathering_drops`의 questID도 마찬가지로 존재만 확인했습니다. 실제로 해당 아이템을 먹었을 때 잡히는지 확인합니다.

채집 노드 지식과 후원 제작 의뢰는 저장소가 집계하지 않는 예외로 남아 있습니다.

### W5b 로케일 (완료)

`Locale.lua`, `Locale_Additions.lua`, `ABPM_ruRU_Final_v3.lua`가 대상이었습니다.

2026-09-04에 `ruRU` 누락 143개를 모두 채웠습니다. `scripts/validate_locale_contract.py`의 `RURU_MISSING_BASELINE`도 `143`에서 `0`으로 내렸습니다. 이제 새 문자열을 추가하면서 러시아어를 빠뜨리면 검증이 바로 실패합니다.

`ruRU`에만 있는 키 11개는 그대로 둡니다. `config_language_russian`처럼 러시아어 파일이 자체적으로 쓰는 키라 `enUS`에 대응이 없습니다.

`ruRU`는 `ABPM_ruRU_Final_v3.lua`가 TOC 맨 뒤에서 주입하는 구조입니다. 새 키를 넣을 때 이 파일도 함께 고쳐야 검증을 통과합니다.

### W7 주간 이벤트

`Data/WorldEventSchedule.lua`와 `UI/WorldEventOverlay.lua`는 TOC에 없어 로드되지 않습니다(의도적 비활성, `DOC/CODE_NOTES.md` 참조).

2026-09-04에 아래 세 결함을 모두 고쳤습니다.

- 이벤트 이름과 키를 `saltherilsSoiree` / `stormarionAssault` / `abundance` / `haranirLegends`로 바꾸고 세 언어 문자열을 함께 정정했습니다. 공식 한국어명은 `살데릴의 연회`, `스토마리온 공격`, `풍요`, `하라니르의 전설`입니다.
- mapID를 `2395`(영원노래 숲) / `2405`(공허폭풍) / `2413`(하란다르)로 맞췄습니다. 틀린 값이던 `2444`와 풍요의 `2393`은 없앴습니다. 풍요는 고정 지역이 없어 4개 동굴을 `rotation` 목록으로 옮겼습니다.
- 분 단위 `interval/duration/offset` 단일 모델을 `cadence` 모델(`weekly` / `interval` / `rotating`)로 교체했습니다. 오버레이는 `areaPoiID` 런타임 조회 → 주간 리셋 카운트다운 → 검증된 기준시각 계산 순으로 판정하고, 어느 것도 못 풀면 `미확인`으로 표시합니다.

다시 켜기 전에 남은 것은 인게임 실측 두 건입니다.

| 항목 | 확인 방법 | 반영 위치 |
| --- | --- | --- |
| 스토마리온 공격 30분 주기의 기준시각 | 이벤트 시작 시각을 `GetServerTime()`으로 기록 | `anchor` 값 추가 후 `anchorVerified = true` |
| 풍요 8시간 순환의 기준시각과 순환 순서 | 활성 동굴이 바뀌는 시각과 다음 지역을 두 번 이상 관측 | `anchor`, `rotation` 순서, `anchorVerified`·`rotationVerified = true` |

두 이벤트의 `areaPoiID`를 찾으면 기준시각 없이도 정확한 타이머가 나옵니다. 인게임에서 해당 지역의 지도를 열고 `C_AreaPoiInfo.GetAreaPOIForMap`으로 POI ID를 확인하는 편이 빠릅니다.

```text
/dump C_AreaPoiInfo.GetAreaPOIForMap(2405)
```

좌표는 여전히 외부 가이드 값이고 인게임 실측이 아닙니다. SavedVariables 마이그레이션 부분은 끝났습니다.

## 3-1. 메모리 점검 결과 (2026-09-04)

에이전트 4팀으로 `UI/`, `Modules/`, `Data/`, 코어를 나눠 읽고 메모리 누수·과다 점유·잦은 재로딩을 조사했습니다.

### 고친 것

영구 증가하는 누수 5건과 시한폭탄 1건을 처리했습니다.

| 위치 | 내용 |
| --- | --- |
| `UI/BISOverlay.lua` | `GET_ITEM_INFO_RECEIVED` 캐시 기록을 `requested`/`previewEntry` 게이트 안으로 옮겼습니다. 이 이벤트에는 필터가 없어 세션 내 모든 아이템이 들어오는데 게이트 밖에서 캐시에 쓰고 있었고, 비우는 경로도 없었습니다 |
| `Modules/GhostManager.lua` | 고스트 오버레이 프레임을 풀로 재사용합니다. 이전에는 해소 시 참조만 버려 숨은 프레임이 영구히 쌓였습니다 |
| `Modules/BlizzardFrameManager.lua` | `HookScript("OnDragStop")`을 `ABPMDragStopHooked`로 1회만 겁니다. 해제할 수 없는 훅이라 기능을 껐다 켤 때마다 쌓였습니다 |
| `UI/WorldEventOverlay.lua` | 접힘·비활성·던전 자동 접기·월드 이탈에서 TomTom 경로점을 정리합니다 |
| `DB.lua` | `worldEventCompletions`를 `{ [eventKey] = "YYYY-MM-DD" }`로 바꿔 키 개수를 이벤트 수로 고정했습니다. 이전 형식 키는 첫 조회에서 한 번 정리합니다 |
| `Data/Defaults.lua` | `mythPreviewCache`를 빈 테이블로 비웠습니다. `MergeDefaults`가 로그인마다 `generatedPreviewBonusListID = 12801`을 되채워 preview 캐시가 매번 폐기되는 구조였습니다. **selector `12849`를 넣기 전에 반드시 필요한 수정입니다** |

### 고빈도 경로 8건 (2026-09-04 처리)

단위 시간당 할당량이 큰 경로들입니다. 전부 동작을 바꾸지 않고 할당만 줄이는 수정입니다.

| 위치 | 내용 |
| --- | --- |
| `Events.lua` | `UNIT_AURA`·`UNIT_STATS`·`UNIT_ATTACK_POWER`를 `RegisterUnitEvent(..., "player")`로 바꿨습니다. 이전에는 모든 유닛분이 디스패처의 `pcall`까지 도달한 뒤 버려졌습니다 |
| `UI/StatsOverlay.lua` | `pcall`에 넘기던 익명 클로저 5개를 모듈 레벨 함수로 뺐습니다. `toPlainNumber` 하나만으로 refresh당 55~115개가 생겼습니다 |
| `UI/Typography.lua` | `ApplyFont`가 등록 항목과 `options` 테이블을 재사용합니다. 이전에는 호출마다 테이블 2개를 새로 만들어 `StatsOverlay`의 재사용 버퍼를 무의미하게 만들었습니다 |
| `ABPM_ruRU_Final_v3.lua` | `gsub` 앞에 `find(..., 1, true)` 평문 검사를 넣었습니다. 치환 키에 패턴 메타문자가 없어 결과가 같고, 대부분의 줄은 어느 키도 포함하지 않습니다 |
| `ABPM_ruRU_Final_v3.lua` | `patchTextRegions`가 깊이별 스크래치 버퍼를 재사용합니다. 노드마다 테이블 2개를 만들던 것을 없앴습니다 |
| `ABPM_ruRU_Final_v3.lua` | 툴팁 후처리를 `tip:NumLines()`까지만 돌고, 러시아어가 아니면 즉시 반환합니다. 래퍼의 `{ original(...) }` + `unpack`도 없앴습니다. 감싸는 두 함수 모두 반환값이 없습니다 |
| `Events.lua` | 전문기술 즉시 스캔을 오버레이가 켜져 있거나 패널이 보일 때로 제한했습니다. 그렇지 않으면 `MarkDirty`만 걸고, `IsQuestComplete`의 지연 스캔에 맡깁니다 |
| `Core.lua` | `ns:RefreshUI()`가 현재 탭의 패널 하나만 갱신합니다. 탭을 바꾸는 모든 경로가 `refreshCurrentTab`을 거치므로 숨은 패널은 표시될 때 갱신됩니다 |
| `UI/BISOverlay.lua` | `resolveSeasonDungeonName`에 언어별 메모를 붙였습니다. `table.sort` 비교자 안에서 불리는 경로입니다 |

### 아직 고치지 않은 것

**보통** — `getAllSpecs` 무캐시, Encounter Journal 실패 미기록으로 호버마다 재스캔 4곳, `SilvermoonMapOverlay`의 `GetSeasonNames()` 루프 내 호출과 `resolveDisplayText` 전량 재계산과 O(n²) 배치, `ItemLevelOverlay`의 빈 결과 미캐시, aura 성공 경로 무스로틀, `UI_ERROR_MESSAGE` 클로저, 고스트 스윕 무스로틀, `QuestPanel` 강제 스캔 3회와 탭 전환 이중 호출, 숨은 설정 페이지 6개 매번 갱신, `GetProfessionSections` 무캐시.

**기능 결함 1건** — `UI/WorldEventOverlay.lua`의 행 `OnClick`과 `OnMouseDown`이 **둘 다** 완료 토글을 실행합니다. 좌클릭 한 번에 토글과 역토글이 일어나 제자리로 돌아갈 수 있습니다. `OnMouseDown` 쪽을 지우는 것이 맞습니다. 오버레이가 TOC 비활성이라 인게임 확인은 켠 뒤에 합니다.

### 인게임 확인이 필요한 것

- 전문기술 평가 캐시가 매 스캔 무효화되는지. `/abpm debug on` 후 `Profession knowledge scan refreshed: N completed quests (changed|unchanged)` 로그가 계속 `changed`면 확정입니다. 원인 후보는 `ProfessionKnowledgeTracker.lua:367`이 `completedQuestLookup`에 직접 쓰는 것이고, `IsQuestFlaggedCompleted`는 참인데 `GetAllCompletedQuestIDs`에 없는 questID가 하나라도 있으면 평가 캐시 3종이 영구히 무용지물이 됩니다.
- 애드온 메모리 실측.

```text
/run UpdateAddOnMemoryUsage() print(GetAddOnMemoryUsage("ABProfileManager"))
```

`Data/BISCatalog.lua`가 662KB / 657행으로 항상 상주하며 추정 1.0~1.2MB, 로케일 3종이 310KB입니다.

### 이상 없음으로 확인된 것

로그 버퍼 상한(`DEBUG_LOG_MAX = 200`, `CAUGHT_ERROR_LOG_MAX = 80`), `C_Timer.NewTicker` 사용 0건, `RegisterEvent`·`hooksecurefunc` 중복 가드, `RefreshUI`가 고빈도 이벤트에 물려 있지 않음, 전투 대기열 dedupe와 플러시, 은행 세션 플래그 비영속, 목록 행 풀링 전부, 툴팁 싱글턴, UIParent 스캔과 전역 훅 0건, OnUpdate 스로틀 실동작, `Data/` 테이블의 런타임 복사 없음, `TomTomBridge` 전문기술 경로.

## 4. 판단이 남은 항목

- 일반 던전 아이템 레벨 `214`는 강화 트랙이 없습니다. 현재 스키마에 일반 던전 항목이 없어 넣지 않았습니다. 표시할 가치가 있는지 결정이 필요합니다.
- 시즌 불일치 상태에서도 raid·tier·crafted hover는 계속 preview 링크를 시도합니다. `SeasonGuard`가 이 경로까지 막을지 결정이 필요합니다. 명세의 처리 방침에는 없는 범위입니다.
- `UI/BISOverlay.lua`의 top-level local은 `195`개입니다. `scripts/validate_bis_tooltip_contract.py`의 예산이 `198`, Lua 상한이 `200`이라 여유가 세 개뿐입니다. 새 기능은 기존 테이블의 필드로 넣습니다.

## 5. BIS 시즌 2 (진행 중)

### 완료

`ABProfileManager/Data/BISData_Method.lua`를 시즌 2 와우헤드 데이터로 갱신했습니다. 40개 전문화 657행이며 시즌 1 던전 참조는 없습니다. 이 파일은 TOC에 없어 런타임에 로드되지 않으므로 인게임 동작은 아직 바뀌지 않습니다.

`scripts/refresh_wowhead_bis.py`도 함께 고쳤습니다. 괄호 한정어가 붙은 슬롯 라벨을 처리하고, 시즌 2 던전·보스 정규화를 넣고, 대상 파일을 쓰지 않고 결과만 확인하는 `--review` 모드를 추가했습니다.

### 카탈로그 재생성 완료 (B안)

와우헤드 overall 데이터만으로 카탈로그를 다시 만들었습니다. `3330`행에서 `641`행으로 줄었고(v1.13.0에서 `657`행으로 재생성) 전부 시즌 2 데이터입니다.

| sourceGroup | 행 |
| --- | --- |
| raid | 393 |
| crafted | 78 |
| mythicplus | 107 |
| tier | 79 |

시즌 1 던전 참조는 하나도 남지 않았습니다. 보스 한글명은 공식 Blizzard 한국어 소식에서 확인한 이름을 씁니다.

`ns.Data.BISSpecPolicies` 블록은 재생성하지 않고 기존 값을 그대로 옮깁니다. 12.0.5 기준으로 동결된 스탯 우선순위 정책이기 때문입니다.

### 이전 기록 (해결됨)

카탈로그 재생성이 불가능했습니다. `scripts/build_bis_catalog.py`는 후보 풀을 `DOC/MidnightS1_MPlus_Addon_DB_v1.3.lua`에서 가져오는데 이것이 시즌 1 데이터입니다. 현재 카탈로그 3330행 중 대부분이 여기서 오고, 와우헤드에서 얻을 수 있는 것은 641행뿐입니다. 그중 M+는 88행에 불과합니다.

지금 재생성하면 시즌 1 후보 풀에 시즌 2 overall만 얹힌 잡탕이 됩니다. 선택이 필요합니다.

B안을 선택해 진행했습니다. "적지만 맞는 추천"이 "많지만 획득 불가한 추천"보다 낫다는 판단입니다.

### 이후 단계 (카탈로그 결정 후)



BIS 런타임 데이터를 전부 시즌 2로 전환했고 `SeasonGuard`를 해제했습니다(`dataSeason = "Midnight Season 2"`). Encounter Journal 자동 랜딩이 다시 동작합니다.

다만 preview selector 두 종은 시즌 2 값을 확인하지 못해 비활성입니다. `BISMythicVaultLinks`의 `generatedPreviewBonusListID`와 `BISSeasonPreviewLinks`의 selector item string이 그것이며, 값을 지어내면 잘못된 아이템 레벨의 preview가 만들어지므로 비워 두었습니다. 그 결과 M+ 자동 점수화가 동작하지 않고 hover는 기본 `itemLink`로 표시됩니다.

selector 후보를 2026-09-03 DB2에서 찾았습니다. 아직 파일에 넣지 않았고 인게임 확인이 남았습니다.

- `ItemBonusListGroup`에서 시즌 1 Myth 트랙은 그룹 `612`(`ItemGroupIlvlScalingID = 11`), 시즌 2는 그룹 `618`(`ItemGroupIlvlScalingID = 12`)입니다. 두 그룹 모두 `ItemBonus` `Type=34`의 두 번째 값이 `978`로 같습니다.
- `ItemBonusTreeNode`에 `MinMythicPlusLevel = 10`인 행이 시즌 1은 그룹 `612`, 시즌 2는 그룹 `618`을 가리킵니다. 저장소가 쓰는 `+10 금고 = Myth 1/6` 규칙과 같습니다.
- `ItemBonusListGroupEntry`에서 그룹 `618`의 `SequenceValue = 1`은 `ItemBonusListID = 12849`입니다. 시즌 1의 같은 자리는 `12801`이고 저장소가 시즌 1에 쓰던 값과 일치합니다.
- 즉 `generatedPreviewBonusListID` 후보는 `12849`입니다. 아이템 레벨은 `ItemGroupIlvlScaling` 표에서 계산되고 이 표는 외부로 공개되지 않아 저장소 밖에서는 `318`을 확인할 수 없습니다. 인게임에서 아래를 실행해 `318`이 나오면 확정입니다.

```text
/dump GetDetailedItemLevelInfo("item:268209::::::::::::1:12849")
```

확인되면 `Data/BISMythicVaultLinks.lua`의 `generatedPreviewBonusListID`와 `scripts/validate_bis_mythic_vault_links.py`의 고정값을 함께 갱신합니다. 확인 전에는 넣지 않습니다. 잘못된 selector는 잘못된 아이템 레벨의 preview를 만듭니다.

나머지 데이터 교체는 v1.13.0에서 끝났습니다. `baselineItemLevel = 318`, preview 검증 범위 `318~334`, 제작 `331`, `BISRewardProfiles` 시즌 2 값(`311` / `318`), `SeasonGuard.dataSeason = "Midnight Season 2"`, `FROZEN_BLOB_HASHES`와 `REWARD_PROFILES_SHA256` 갱신까지 반영돼 있습니다. 남은 것은 위 `12849` 인게임 확인 한 건입니다.

스탯 우선순위 값은 2026-09-03에 와우헤드 시즌 2 기준으로 전수 재대조를 마쳤습니다.

## 6. 릴리스 절차

`-Strict`가 통과한 뒤 진행합니다. 자세한 절차는 [RELEASE_PROCESS.md](./RELEASE_PROCESS.md)를 봅니다.

- `CHANGELOG.md`의 `1.13.0` 항목을 릴리스 기준으로 확정
- `DOC/releases/RELEASE_NOTES_v1.13.0.md`와 영문판 작성 (완료)
- `ABProfileManager/ADDON_INTRO.txt`의 버전 문구에서 `작업 중` 표기를 제거하고 변경 내역 추가
- `scripts/package_release.ps1` 실행
- `dist/` 루트에는 최신 ZIP만 두고 이전 ZIP은 `dist/archive/`로 이동
- 로컬 배포는 `dist/` ZIP 생성까지만 수행한다
