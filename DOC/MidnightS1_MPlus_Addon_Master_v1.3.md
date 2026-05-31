# Midnight S1 M+ Addon Master v1.3
생성일: 2026-05-31 KST
대상: World of Warcraft 한밤 시즌 1 / 12.0.5 / 쐐기 + 위대한 금고/촉매 티어 기반 애드온 DB

## 0. v1.3 결론

v1.3은 v1.2에서 확정한 **전문화별 대표 2차 스탯 우선순위 1개**를 유지하면서, 아이템 우선순위를 다음 방식으로 업데이트했다.

| 항목 | v1.3 처리 |
|---|---|
| 2차 스탯 우선순위 | v1.2 사용자 선택/검증값 유지 |
| 아이템 우선순위 | 정적 확정이 아니라 실제 `itemLink` 런타임 점수화로 재정렬 |
| 티어 4셋 | 고정 4부위가 아니라 5부위 중 실제 점수 상위 4개 선택 |
| 신화 아이템 | `itemId` 단독 판정 금지. `itemLink + bonusIds + actualItemLevel + upgradeTrackText` 필요 |
| 장신구/무기 | 수동 seed 등급 제공, 최종 BiS는 SimC/Raidbots/QE/로그 보정 필요 |
| 검증 컬럼 | `mythTrackVerified`, `v13Score`, `v13Evidence`, `staticPriorityStatus`, `requiresRuntimeItemLink` |

## 1. 왜 정적 아이템 순위를 확정하지 않았나

기존 DB의 쐐기 장비 풀에는 공식 한글명, 아이템 ID, 던전명은 들어 있지만 **각 아이템의 실제 신화 itemLink와 실제 2차 스탯 수치**는 들어 있지 않다. WoW의 `itemId`는 기본 템플릿 ID이며, 같은 `itemId`라도 보상 출처와 bonus ID, 업그레이드 트랙에 따라 실제 아이템 레벨과 스탯이 달라진다.

따라서 애드온에서는 다음 원칙을 사용한다.

```lua
local itemLink = GetInventoryItemLink("player", slotId)
local record = DB.BuildRuntimeItemRecordV13(itemLink, specKey, sourceType, keyLevel, slot)
local score = DB.ScoreRuntimeItemV13(record, specKey, slot)
```

## 2. 스탯 산정 원칙

아이템 레벨이 오르면 주스탯/2차 스탯이 증가하지만, 애드온에서 단일 공개 공식을 임의로 재현하지 않는다. 실제 아이템 링크를 기준으로 Blizzard 클라이언트 API에서 읽는다.

```lua
local ilvl = C_Item.GetDetailedItemLevelInfo(itemLink)
local stats = C_Item.GetItemStats(itemLink)
```

이 방식이 필요한 이유:

1. 같은 base `itemId`라도 Hero/Myth 트랙과 업그레이드 단계에 따라 실제 스탯이 달라진다.
2. 아이템 예산/분배/특수효과/업그레이드 트랙을 정적 공식으로 안정적으로 재현하기 어렵다.
3. 애드온은 플레이어가 실제 보유한 신화 itemLink의 스탯을 직접 읽을 수 있다.

## 3. v1.2 단일 대표 2차 스탯 우선순위 유지

v1.3은 v1.2의 사용자 선택값을 그대로 사용한다.

| 전문화 | v1.3 대표 2차 스탯 |
|---|---|
| 신성 사제 | 치명타 및 극대화 > 유연성 = 특화 > 가속 |
| 운무 수도사 | 가속 > 치명타 및 극대화 = 유연성 > 특화 |
| 보존 기원사 | 특화 > 치명타 및 극대화 = 가속 > 유연성 |
| 혈기 죽음의 기사 | 치명타 및 극대화 > 가속 > 유연성 = 특화 |
| 고양 주술사 | 특화 = 가속 > 치명타 및 극대화 > 유연성 |
| 무법 도적 | 가속 > 치명타 및 극대화 = 유연성 > 특화 |
| 양조 수도사 | 치명타 및 극대화 > 유연성 = 특화 > 가속 |
| 수호 드루이드 | 가속 > 특화 = 유연성 > 치명타 및 극대화 |

전체 40개 전문화의 우선순위는 Lua 파일의 `DB.SINGLE_STAT_PRIORITY_V12`를 참조한다.

## 4. 티어 4셋 정책

v1.3의 티어 정책은 다음과 같다.

| 항목 | 정책 |
|---|---|
| 티어 획득 경로 | 쐐기 위대한 금고 던전 슬롯 또는 쐐기 적격 아이템 촉매 변환 |
| 레이드 드랍 티어 | 제외 |
| 추천 방식 | 5부위 중 실제 itemLink 점수 상위 4개 |
| 정적 고정 4부위 | 사용하지 않음 |
| 함수 | `DB.GetBestFourTierPiecesV13(specKey, tierItemLinks, sourceType, keyLevel)` |

티어는 세트 효과 자체가 강하기 때문에 단순 2차 스탯만으로 오프피스를 고르면 안 된다. 4셋 유지 여부를 먼저 확인하고, 그다음 실제 아이템 레벨과 2차 스탯을 비교한다.

## 5. 슬롯별 아이템 우선순위 업데이트 방식

정적 후보 풀을 가져오는 함수:

```lua
local staticPool = DB.BuildStaticSlotPriorityV13("MAGE_FROST", "HEAD")
```

실제 itemLink 목록을 점수화하는 함수:

```lua
local sorted = DB.BuildRuntimeSlotPriorityV13(
  "MAGE_FROST",
  "HEAD",
  itemLinks,
  "GREAT_VAULT_DUNGEON",
  10
)
```

정적 후보 풀은 `requiresRuntimeItemLink=true`를 표시한다. 즉, UI에서는 “후보 풀 검증됨”과 “신화/최종 BiS 검증됨”을 분리해서 보여줘야 한다.

## 6. 장신구/무기 정책

장신구와 무기는 단순 스탯 점수보다 특수효과와 직업별 상호작용이 훨씬 중요할 수 있다. 그래서 v1.3은 다음처럼 처리한다.

| 구분 | 처리 |
|---|---|
| 장신구 | `DB.TRINKET_PRIORITY_SEED_V13`에 A/B/C seed 등급 제공 |
| 무기 | 주스탯 기준 후보 풀 제공, 직업별 착용 가능 여부는 애드온/클라이언트에서 추가 확인 |
| 최종 BiS | `finalBisVerified=false` 유지 |
| 보정 | SimC/Raidbots/QE/로그 확인 후 별도 수동 보정 |

## 7. 애드온 적용 예시

`.toc` 예시:

```toc
## Interface: 120005
## Title: Midnight S1 M+ BIS Helper
## SavedVariables: MidnightS1DBSaved

Data/MidnightS1_MPlus_Addon_DB_v1.3.lua
Core.lua
Scoring.lua
TooltipScanner.lua
```

Core.lua 흐름 예시:

```lua
local DB = MidnightS1MPlusDB
local specKey = "MAGE_FROST"
local slot = "HEAD"
local link = GetInventoryItemLink("player", 1)

local record = DB.BuildRuntimeItemRecordV13(link, specKey, "GREAT_VAULT_DUNGEON", 10, slot)

-- 툴팁 스캐너에서 "신화 1/6" 같은 텍스트를 확인한 경우만 호출
DB.MarkMythTrackVerified(record, "신화 1/6")

local score, evidence = DB.ScoreRuntimeItemV13(record, specKey, slot)
```

## 8. v1.3 프롬프트

아래 프롬프트는 에이전트/하네스에 그대로 전달하기 위한 것이다.

```text
너는 World of Warcraft 한밤 시즌 1 / 12.0.5 쐐기 BiS 애드온 구현 에이전트다.
목표는 정적 itemId 표가 아니라 실제 신화 itemLink 기반 점수화 애드온을 만드는 것이다.
반드시 지킬 규칙:
1) 한글명은 공식 한글 클라이언트, Blizzard 공식 한국어 문서, Wowhead 한국어 페이지에서 확인된 명칭만 사용한다.
2) 영문명을 임의 번역하지 않는다. 확인되지 않으면 ko="검증 필요"로 둔다.
3) itemId만으로 신화/Hero/일반 트랙을 판정하지 않는다.
4) 플레이어 장비/후보 장비의 실제 itemLink를 받아 C_Item.GetDetailedItemLevelInfo(itemLink)와 C_Item.GetItemStats(itemLink)를 호출한다.
5) DB.ScoreRuntimeItemV13(record, specKey, slot)을 사용해 v1.2에서 확정한 단일 2차 스탯 우선순위로 점수화한다.
6) 티어는 5부위 중 실제 itemLink 점수 상위 4부위를 추천한다. 단 4셋 유지 여부를 반드시 UI에 표시한다.
7) 장신구/무기 특수효과는 static score로 최종 확정하지 않는다. SimC/Raidbots/QE/로그 보정이 필요하다는 경고를 표시한다.
8) UI 컬럼에는 baseItemId, itemLink, actualItemLevel, upgradeTrackText, mythTrackVerified, statScore, v13Score, validationLevel을 분리 표시한다.
```

## 9. 검증 체크리스트

| 체크 | 기준 |
|---|---|
| 한글명 | 공식 한글/Wowhead KO 기준, 임의 번역 금지 |
| 공결탑 제나스 | `Nexus-Point Xenas` 직역 금지, 공결탑 제나스 고정 |
| 신화 판정 | itemId 단독 금지 |
| 스탯 계산 | C_Item.GetItemStats(itemLink) 사용 |
| 아이템 레벨 | C_Item.GetDetailedItemLevelInfo(itemLink) 사용 |
| 최종 BiS | 정적 true 금지. SimC/QE/로그 필요 |
| 장신구 | seed 등급만 사용, finalBiS 아님 |

## 10. 산출물

- `MidnightS1_MPlus_Addon_DB_v1.3.lua`: 애드온 로드용 단일 Lua DB/정책/함수
- `MidnightS1_MPlus_Addon_Master_v1.3.md`: 사람이 보는 마스터 문서
- `MidnightS1_MPlus_Addon_Final_v1.3.zip`: 위 2개 패키지
