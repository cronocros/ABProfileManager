# 인게임 확인 체크리스트

인게임에서 직접 보거나 덤프를 떠야 확정되는 항목만 모았습니다. 항목마다 **실행 → 판정 → 조치**를 적었고, 조치는 어느 파일의 무엇을 어떤 값으로 바꾸는지까지 씁니다.

기준 커밋은 `1c8402b`이고 버전은 `ABProfileManager/ABProfileManager.toc`의 `## Version`을 따릅니다. 배경은 [TODO.md](./TODO.md), 소스 제약은 [CODE_NOTES.md](./CODE_NOTES.md)를 봅니다.

`/dump`는 결과가 길면 잘립니다. 잘리면 `/run print(...)` 쪽을 쓰거나 `/abpm copy log`로 옮겨 담습니다.

---

## 0. 시작 전

```text
/abpm debug on
```

디버그 로그는 이번 접속에만 유지됩니다. 로그를 꺼내려면 아래를 씁니다.

```text
/abpm copy log
```

애드온이 최신인지부터 확인합니다. `dist/`의 ZIP이 아니라 저장소 작업본을 설치했는지 봅니다.

---

## 1. 릴리스를 막고 있는 것

`scripts/run_season2_validation.ps1 -Strict`는 `Data/ItemLevelTable.lua`의 `sources`에 `guide`가 하나라도 있으면 실패합니다. 지금 `delves`와 `mythicPlus` 둘이 `guide`입니다. 이 둘을 올려야 릴리스할 수 있습니다.

### 1-1. 구렁 아이템 레벨

**실행** — 구렁을 한 단계라도 완료하고 보상 상자 아이템에 마우스를 올려 아이템 레벨을 읽습니다. 이번 주 구렁을 돌았다면 위대한 금고 `세계` 칸이 채워지므로 금고값은 아래로 교차 확인할 수 있습니다.

```text
/run for _,a in ipairs(C_WeeklyRewards.GetActivities()) do print(a.type, a.level, C_WeeklyRewards.GetExampleRewardItemHyperlinks(a.id)) end
```

**판정** — 저장소가 들고 있는 값입니다. 단계 1~11 순서입니다.

| 구분 | 값 |
| --- | --- |
| 완료 보상 | `266 / 269 / 272 / 276 / 279 / 282 / 292 / 295 / 295 / 295 / 295` |
| 금고 | `279 / 282 / 285 / 289 / 292 / 298 / 302 / 305 / 305 / 305 / 305` |

돌아본 단계의 값이 표와 같으면 통과입니다. 다르면 그 단계의 행을 실제 값으로 고칩니다.

**조치** — `ABProfileManager/Data/ItemLevelTable.lua`의 `sources.delves`를 `"guide"`에서 `"tooltip"`으로 바꿉니다. 값이 틀렸다면 `delves` 표의 해당 `tier` 행의 `ilvl` 또는 `vault`를 먼저 고칩니다.

### 1-2. 쐐기 던전 종료 아이템 레벨

금고 열은 이미 API로 검증했습니다. 던전 종료 열만 남았습니다.

**실행** — 쐐기를 한 판 완료하고 종료 상자 아이템의 아이템 레벨을 읽습니다. 아래로 API 값도 함께 뜹니다.

```text
/run for i=2,12 do print(i, C_MythicPlus.GetRewardLevelForDifficultyLevel(i)) end
```

**판정** — 저장소 값입니다. `+2`부터 `+12`까지입니다.

| 구분 | 값 |
| --- | --- |
| 던전 종료 | `295 / 295 / 298 / 302 / 305 / 305 / 308 / 308 / 311 / 311 / 311` |
| 금고 | `305 / 305 / 308 / 308 / 311 / 315 / 315 / 315 / 318 / 318 / 318` |

`+8` 금고값은 API가 `305`를 돌려주지만 앞뒤가 `315`라 API 이상값으로 보고 표는 `315`를 유지하고 있습니다. 툴팁이 `315`를 보여주면 그대로 두고, `305`를 보여주면 표를 고칩니다.

영웅 던전은 `276`(금고 `289`), 신화 0은 `292`(금고 `302`)입니다.

**조치** — `Data/ItemLevelTable.lua`의 `sources.mythicPlus`를 `"tooltip"`으로 바꿉니다. 값이 틀렸다면 `mythicPlus.endOfDungeon`의 해당 `key` 행을 먼저 고칩니다.

### 1-3. 두 항목을 다 올린 뒤

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_season2_validation.ps1 -Strict
```

통과하면 [RELEASE_PROCESS.md](./RELEASE_PROCESS.md) 순서로 패키징합니다.

---

## 2. BIS preview selector (M+ 완료)

**2026-09-04에 확정했습니다.** 아래 덤프가 `318`을 돌려줘 `Data/BISMythicVaultLinks.lua`의 `generatedPreviewBonusListID`를 `12849`로 올렸고, M+ 자동 점수화와 preview 툴팁이 켜졌습니다. 아래 절차는 시즌이 바뀔 때 다시 씁니다.

`Data/BISSeasonPreviewLinks.lua`의 raid/tier/crafted selector item string은 아직 확인 전입니다.

**실행**

```text
/dump GetDetailedItemLevelInfo("item:268209::::::::::::1:12849")
```

전역이 없다면 아래를 씁니다.

```text
/dump C_Item.GetDetailedItemLevelInfo("item:268209::::::::::::1:12849")
```

**판정** — 첫 반환값이 `318`이면 확정입니다. **`318`이 아니면 절대 넣지 마세요.** 잘못된 selector는 잘못된 아이템 레벨의 preview를 만듭니다.

**조치** — 세 곳을 함께 고칩니다.

1. `ABProfileManager/Data/BISMythicVaultLinks.lua` — `generatedPreviewBonusListID = nil` → `generatedPreviewBonusListID = 12849`
2. `scripts/validate_bis_mythic_vault_links.py` — `EXPECTED_PREVIEW_BONUS_LIST_ID = None` → `EXPECTED_PREVIEW_BONUS_LIST_ID = 12849`. 같은 파일의 "값을 지어내면" 주석도 확인된 값으로 고칩니다.
3. 넣은 뒤 `/reload`를 **두 번** 합니다. preview 캐시가 매 로그인 폐기되지 않고 유지되는지 확인하는 절차입니다. `Data/Defaults.lua`의 `mythPreviewCache`를 빈 테이블로 고친 것이 이 문제를 막기 위한 것입니다.

확인 후:

```powershell
python scripts\validate_bis_mythic_vault_links.py
```

---

## 3. W7 월드 이벤트

`Data/WorldEventSchedule.lua`와 `UI/WorldEventOverlay.lua`는 TOC에 없어 **로드되지 않습니다.** 아래를 재야 켤 수 있습니다.

### 3-1. AreaPOI ID 찾기 (이게 되면 3-2는 불필요)

**실행** — 각 지역에서 실행합니다. 공허폭풍이 스토마리온 공격용이고, 나머지 셋은 풍요 동굴용입니다.

```text
/run local m=2405 for _,id in ipairs(C_AreaPoiInfo.GetAreaPOIForMap(m) or {}) do local i=C_AreaPoiInfo.GetAreaPOIInfo(m,id) print(id, i and i.name, C_AreaPoiInfo.GetAreaPOISecondsLeft(id)) end
```

`m` 값을 바꿔가며 네 지역을 봅니다.

| 지역 | mapID |
| --- | --- |
| 공허폭풍 | `2405` |
| 영원노래 숲 | `2395` |
| 줄아만 | `2437` |
| 하란다르 | `2413` |

**판정** — 이름이 `스토마리온`이나 `풍요` 관련인 POI의 `id`를 적어 둡니다. `GetAreaPOISecondsLeft`가 숫자를 돌려주면 그것만으로 정확한 타이머가 나옵니다.

**조치** — `Data/WorldEventSchedule.lua`의 해당 이벤트에 `areaPoiID = <찾은 값>`을 넣습니다. 풍요는 `rotation`의 각 항목에 넣습니다. 이미 확인된 값은 연회 `8600`, 전설 `8423`입니다.

### 3-2. 기준시각 실측 (POI ID를 못 찾았을 때만)

**실행** — 이벤트가 **시작하는 순간** 실행합니다.

```text
/run print(GetServerTime(), date("%Y-%m-%d %H:%M:%S"))
```

풍요는 활성 동굴이 바뀌는 시각과 다음 지역을 **두 번 이상** 관측해야 순환 순서까지 확정됩니다.

**조치** — `Data/WorldEventSchedule.lua`에서

- 스토마리온: `anchor = <서버시각 초>` 추가, `anchorVerified = false` → `true`
- 풍요: `anchor` 추가, `rotation` 배열 순서를 관측 순서로 재배열, `anchorVerified`와 `rotationVerified` 둘 다 `true`

### 3-3. 좌표 실측

현재 좌표는 외부 가이드 값입니다. 각 지점에서 실행합니다.

```text
/run local m=C_Map.GetBestMapForUnit("player") local p=C_Map.GetPlayerMapPosition(m,"player") print(m, string.format("%.2f %.2f", p.x*100, p.y*100))
```

| 이벤트 | 현재 값 |
| --- | --- |
| 살데릴의 연회 | `2395` 42.70 / 47.27 |
| 스토마리온 공격 | `2405` 26.80 / 67.80 |
| 하라니르의 전설 | `2413` 51.00 / 50.80 |
| 풍요 · Watha'nan Crypts | `2395` 56.78 / 65.79 |
| 풍요 · Loaknit Den | `2437` 31.62 / 26.14 |
| 풍요 · Floaret Grotto | `2413` 66.14 / 61.69 |
| 풍요 · Abundant Voidburrow | `2405` 38.82 / 53.31 |

### 3-4. 오버레이를 켠 뒤 확인

**조치** — `ABProfileManager/ABProfileManager.toc`에 `Data\WorldEventSchedule.lua`와 `UI\WorldEventOverlay.lua`를 넣습니다. `Data\` 항목은 다른 `Data\` 줄과 함께, `UI\` 항목은 다른 오버레이 뒤에 둡니다.

켠 뒤 볼 것:

- 이벤트 행을 **좌클릭 한 번** 했을 때 완료 표시(ReadyCheck 아이콘)가 켜진 채로 유지되는가. 제자리로 돌아오면 토글이 두 번 걸린 것입니다
- 주간 이벤트 두 종이 `주간`과 주간 리셋까지 남은 시간을 보여주는가
- 기준시각을 아직 안 넣은 이벤트가 `미확인`과 `-`로 나오는가 (가짜 카운트다운이 나오면 안 됩니다)
- 오버레이를 끄거나 접거나 던전에 들어갔을 때 TomTom 화살표가 사라지는가
- 애드온 언어를 영어·러시아어로 바꿨을 때 카운트다운이 `1시간 20분`이 아니라 그 언어로 나오는가

---

## 4. W3 지도

**실행** — 똬리의 섬 안에서 실행합니다.

```text
/dump C_Map.GetBestMapForUnit("player")
```

**판정** — `2512`가 나오면 `Data/SilvermoonMapData.lua`의 값이 맞습니다. 하위 지도 `2509`(`Vaults of Atal'Utek`, 송곳니의 제단 입구 구역) 안에서도 한 번 봅니다.

**조치** — 다른 값이 나오면 `Data/SilvermoonMapData.lua`의 `nameAliases`와 `runtimeMaps`에서 `2512`를 실제 값으로 바꿉니다.

---

## 5. W4 전문기술

### 5-1. 채운 주간 questID 4개

2026-09-04에 누락을 찾아 채운 것들입니다. 목록이 `match = "any"`라 빠진 ID가 그 주에 걸리면 완료를 감지하지 못합니다.

**실행**

```text
/run for _,q in ipairs({93697,93701,93707,93713}) do print(q, C_QuestLog.IsQuestFlaggedCompleted(q)) end
```

**판정**

| 직업 | questID | 퀘스트 |
| --- | --- | --- |
| 마법부여 | 93697 | Shimmering Melodies |
| 약초채집 | 93701 | Brittle and Brilliant |
| 채광 | 93707 | It's Called Silvermoon |
| 무두질 | 93713 | Essential Materials |

이번 주 주간 퀘스트가 이 중 하나로 걸렸고 완료했다면 `true`가 나와야 하고, 전문기술 화면의 해당 항목도 완료로 잡혀야 합니다.

**조치** — `true`인데 화면이 미완료면 `Data/ProfessionKnowledge.lua`의 해당 직업 `weekly_quest` 목록을 다시 봅니다.

### 5-2. 논문 questID 11종

와우헤드에 노출되지 않는 숨은 퀘스트라 이름 대조를 못 했습니다. DB2 존재만 확인한 상태입니다.

**실행** — 논문을 읽기 전과 후에 각각 실행해 값이 바뀌는지 봅니다.

```text
/run for q=95127,95138 do print(q, C_QuestLog.IsQuestFlaggedCompleted(q)) end
```

**판정** — 논문을 읽은 직업의 questID가 `false`에서 `true`로 바뀌고 전문기술 화면의 지식이 1 오르면 맞습니다. `95132`는 저장소가 쓰지 않는 ID이므로 무시합니다.

**조치** — 어긋나면 `Data/ProfessionKnowledge.lua`의 해당 직업 `treatise` 항목의 questID를 실제 값으로 고칩니다.

### 5-3. 평가 캐시가 매번 무효화되는지

`Tracker:IsQuestComplete`가 `completedQuestLookup`에 직접 쓰는데, `IsQuestFlaggedCompleted`는 참인데 `GetAllCompletedQuestIDs`에는 없는 questID가 하나라도 있으면 평가 캐시 3종이 **영구히 무용지물**이 됩니다.

**실행**

```text
/abpm debug on
```

전문기술 화면을 열고 가방을 몇 번 정리한 뒤

```text
/abpm copy log
```

**판정** — `Profession knowledge scan refreshed: N completed quests (changed)` 가 **매번** `changed`로 찍히면 확정입니다. `unchanged`가 섞이면 정상입니다.

참고로 완료 퀘스트 수는 아래로 봅니다.

```text
/dump #C_QuestLog.GetAllCompletedQuestIDs()
```

**조치** — 확정되면 `Modules/ProfessionKnowledgeTracker.lua`의 `IsQuestComplete`가 `completedQuestLookup`을 오염시키지 않게 하고 `questStatusLookup`에만 쓰도록 고칩니다. 또는 `hasSameQuestLookup`이 "fresh에 있는데 existing에 없는" 방향만 보게 바꿉니다.

---

## 6. 메모리 수정 회귀 확인

PR #11~#15에서 고친 것들입니다. 캐시를 많이 넣어서 **오래된 값이 남는** 종류의 회귀가 주 위험입니다.

### 6-1. 로그인 직후 BIS (가장 중요)

부분 결과가 캐시에 굳는 결함을 고쳤습니다. 굳으면 세션 내내 남습니다.

**실행** — 접속하자마자 곧바로 BIS 오버레이를 엽니다. 닫고 30초쯤 뒤 다시 엽니다.

**판정** — 두 번 다 전문화 탭이 전부 나오고 직업 이름이 `UNKNOWN` 같은 값이 아니어야 합니다. 보스명은 처음엔 비어 있어도 다시 호버하면 붙어야 합니다.

**조치** — 전문화가 빠진 채 굳으면 `UI/BISOverlay.lua`의 `getAllSpecs` 완전성 검사를, 보스명이 영영 안 붙으면 `EJournal.lastMatchPoolTrusted` 조건을 다시 봅니다.

### 6-2. 언어 전환

```text
/abpm
```

설정에서 언어를 바꾸고 아래를 확인합니다.

- BIS 전문화 탭 **툴팁**의 전문화 이름이 바뀌는가
- BIS 목록의 던전·출처 라벨이 바뀌는가
- 전문기술 화면의 섹션 제목과 항목 이름이 바뀌는가
- 지도 오버레이 라벨이 바뀌는가

하나라도 이전 언어로 남으면 해당 캐시의 무효화가 빠진 것입니다.

### 6-3. 러시아어 치환

언어를 러시아어로 두고 봅니다.

- 스탯 오버레이에 `Critical Strike`가 온전히 나오는가 (`치명ical Strike` 같은 잡탕이면 프런티어 패턴이 안 걸린 것)
- 액션바 적용·비우기 결과 메시지, 고스트 메시지, `/abpm help` 전체가 러시아어인가
- `%s`/`%d` 자리가 깨진 곳이 없는가 (143개가 새 번역이라 여기서 드러납니다)

### 6-4. 신화+ 아이콘

**실행** — 던전 찾기 창의 신화+ 탭을 엽니다. 그 다음 **PVE 창을 연 채로** `/reload` 하고 다시 봅니다.

**판정** — 두 경우 다 던전 아이콘에 `평점 / 던전명` 오버레이가 나와야 합니다. `/reload` 후에만 안 나오면 믹스인 훅 타이밍 문제입니다.

**조치** — `UI/MythicPlusRecordOverlay.lua`의 `hookIcon`이 `rawget(icon, "SetUp")` 비교로 인스턴스 훅을 거는 경로를 다시 봅니다.

### 6-5. 지도 오버레이

- 월드맵을 열고 확대·축소를 반복했을 때 라벨 위치와 글자 크기가 안정적인가
- 지도 패널에서 **필터를 껐다 켜** 포인트를 줄였다 늘렸을 때 글자 크기가 맞는가 (포인트 집합 비교가 틀리면 여기서 드러납니다)
- 시즌 1 지역 지도에서 시즌 2 던전 입구가 표시되는가

### 6-6. 스탯 오버레이

- 버프를 걸고 풀 때 수치가 반응하는가 (버프 hash 캐시 무효화)
- 전투 진입·이탈, 장비 교체 후 수치가 맞는가
- 폰트 크기 슬라이더를 움직였을 때 모든 오버레이와 패널 글자가 따라오는가
- **공격대 전투 중** aura 관련 Lua 오류가 없는가

```text
/abpm errors
```

### 6-7. 고스트 마커

- 미보유 주문이 든 템플릿을 적용해 마커가 표시되는가
- 마커를 **드래그해 해제**했을 때 상태 메시지에 슬롯 이름이 제대로 나오는가 (`칸 0`이면 회귀)
- 액션바를 편집하거나 자세를 바꿨을 때 0.1초 뒤 마커가 갱신되는가
- 적용과 해제를 여러 번 반복해도 마커가 엉뚱한 버튼에 뜨거나 겹치지 않는가

### 6-8. 메인 창 탭

`ns:RefreshUI()`가 현재 탭만 갱신하도록 바뀌었습니다. 누락이 있으면 여기서 드러납니다.

- 프로필 탭에서 템플릿을 저장한 뒤 액션바 탭으로 가면 반영돼 있는가
- 편의기능 탭에서 오버레이를 켠 뒤 지도 탭으로 가면 반영돼 있는가
- **퀘스트 탭이 열린 상태에서 퀘스트 탭 버튼을 다시 눌렀을 때** 목록이 갱신되는가
- Blizzard 설정 창에서 ABProfileManager 하위 페이지를 열어 둔 채 템플릿을 만들면 요약이 갱신되는가

### 6-9. 전문기술 지연 스캔

**실행** — 전문기술 오버레이를 **끄고** 퀘스트를 완료하거나 루팅을 합니다. 그 다음 전문기술 탭을 엽니다.

**판정** — 포인트가 최신이어야 합니다. 오래된 값이면 지연 스캔이 안 도는 것입니다.

### 6-10. 창 이동과 은행

- 편의기능에서 Blizzard 창 이동을 껐다 켠 뒤 창을 드래그하면 위치가 저장되는가
- 편의기능 탭 자체가 정상 표시되는가 (재진입 가드 추가)
- BIS 목록 스크롤바를 드래그하는 **도중** PVE 창을 닫았다 다시 열었을 때 스크롤이 정상인가

```text
/abpm bankcheck
```

은행을 열고 오류 메시지가 나오는 상황에서 세션이 정리되는지, 로그아웃·존 이동 후 재접속에 잠김이 없는지 봅니다.

### 6-11. 메모리 실측

```text
/run local u=(C_AddOns and C_AddOns.UpdateAddOnMemoryUsage) or UpdateAddOnMemoryUsage local g=(C_AddOns and C_AddOns.GetAddOnMemoryUsage) or GetAddOnMemoryUsage u() print(string.format("ABPM %.1f KB", g("ABProfileManager")))
```

접속 직후, BIS 창을 여러 번 연 뒤, 공격대 전투 뒤 각각 재보면 증가 추세를 볼 수 있습니다. `Data/BISCatalog.lua`가 662KB / 657행으로 항상 상주하므로 기저값 자체가 1MB 안팎으로 나오는 것은 정상입니다.

---

## 7. 판정이 필요한 미확정 항목

### 7-1. `issecretvalue` 동작

`UI/StatsOverlay.lua`의 `isSecretValue`가 `pcall` 실패 시 `false`(= secret 아님)를 돌려줍니다. 이 전제가 맞는지 정적으로는 판정할 수 없습니다.

```text
/dump type(issecretvalue)
```

`function`이 아니면 그 경로 자체가 죽어 있는 것입니다.

### 7-2. Blizzard 설정 프레임의 `IsShown`

숨은 설정 화면을 건너뛰는 최적화가 실제로 효과가 있는지 판정합니다.

**실행** — 설정 창을 **닫은 상태에서** 실행합니다.

```text
/dump ABPMSettingsCategoryPanel and ABPMSettingsCategoryPanel:IsShown()
```

**판정** — `false`면 최적화가 동작합니다. `true`면 Blizzard가 컨테이너 가시성으로만 감추는 빌드라 걸러내지 못합니다(이득 0, 회귀도 0).

### 7-3. 일반 던전 아이템 레벨

일반 던전 `214`는 강화 트랙이 없어 현재 스키마에 항목이 없습니다. 표시할 가치가 있는지 결정이 필요합니다.

---

## 8. 마무리

인게임 확인을 반영한 뒤 반드시 다시 돌립니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_season2_validation.ps1 -Strict
```

문제가 나오면 [TODO.md](./TODO.md)와 [CODE_NOTES.md](./CODE_NOTES.md)를 함께 갱신합니다. 확인이 끝난 항목은 이 문서에서 지우지 말고 결과를 적어 두면 다음 시즌에 다시 씁니다.

진단이 필요할 때 쓰는 명령입니다.

```text
/abpm copy log
```

```text
/abpm copy ej
```

```text
/abpm copy mplus
```
