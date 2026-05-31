# Midnight S1 Addon DB v1.7 — Compact Integration Guide

대상: World of Warcraft **한밤 시즌 1 / 12.0.5** 장비 추천 애드온.

이 버전은 v1.6의 장황한 수정 이력과 중복 설명을 제거하고, 다른 애드온이 바로 참조해야 하는 **정책·API·스탯 가중치·출처 분류**만 남긴 정리본이다.

## 1. 핵심 정책

| 항목 | 정책 |
|---|---|
| 한글명 | 공식 한글 클라이언트, Blizzard KO, Wowhead KO에서 검증된 명칭만 사용 |
| 임의 번역 | 금지. 미검증 한글명은 저장하지 않음 |
| itemId | 기본 아이템 ID. 난이도/트랙 판정에 단독 사용 금지 |
| 실제 점수 | 반드시 `itemLink` 기준으로 실제 아이템 레벨과 실제 스탯을 읽어서 계산 |
| 영웅/신화 표기 | 쐐기 자체가 아니라 업그레이드 트랙 또는 레이드 난이도. UI에서 출처와 분리 표시 |
| 최종 BiS | 스탯 점수만으로 확정 금지. 티어, 장신구/무기 효과, SimC/QE/로그 보정 필요 |

## 2. 공식/검증 기준

- Blizzard 12.0.5 공식 노트: 성운의 공허핵 보상은 해당 쐐기돌 레벨의 위대한 금고 보상과 같고, +10 이상에서는 신화 1/6 기준으로 안내됨.
- Wowhead 한밤 시즌 1 쐐기 가이드: +10 기준 쐐기 종료 보상과 금고 보상의 아이템 레벨/트랙이 다름. 종료 보상과 금고 보상을 같은 것으로 취급하면 안 됨.
- Warcraft Wiki API: `GetDetailedItemLevelInfo(itemLink)`와 `C_Item.GetItemStats(itemLink)`를 통해 실제 아이템 레벨과 itemLink 기준 스탯을 읽어야 함.

## 3. 출처 표기 규칙

| 내부 sourceType | UI 표기 |
|---|---|
| `MPLUS_END_DUNGEON` | 쐐기 종료 보상 |
| `MPLUS_GREAT_VAULT` | 쐐기 금고 보상 |
| `MPLUS_BONUS_ROLL` | 쐐기 보너스 굴림 |
| `RAID_LFR` | 레이드 공격대 찾기 |
| `RAID_NORMAL` | 레이드 일반 |
| `RAID_HEROIC` | 레이드 영웅 |
| `RAID_MYTHIC` | 레이드 신화 |
| `CATALYST` | 촉매 변환 |

예시 UI:

```text
쐐기 종료 보상 +10 / 영웅 3/6
쐐기 금고 보상 +10 / 신화 1/6
레이드 영웅 / 실제 아이템 링크 기준
```

## 4. 쐐기 보상표

| 단수 | 쐐기 종료 | 쐐기 금고 |
|---:|---|---|
| +2~+3 | 250 / 용사 2/6 | 259 / 영웅 1/6 |
| +4 | 253 / 용사 3/6 | 263 / 영웅 2/6 |
| +5 | 256 / 용사 4/6 | 263 / 영웅 2/6 |
| +6 | 259 / 영웅 1/6 | 266 / 영웅 3/6 |
| +7 | 259 / 영웅 1/6 | 269 / 영웅 4/6 |
| +8~+9 | 263 / 영웅 2/6 | 269 / 영웅 4/6 |
| +10 이상 | 266 / 영웅 3/6 | 272 / 신화 1/6 |

## 5. 애드온 연동 API

```lua
local DB = MidnightS1MPlusDB
local record = DB.BuildRuntimeItemRecord(
  itemLink,
  "PRIEST_HOLY",
  "MPLUS_GREAT_VAULT",
  { keyLevel = 10, upgradeTrackText = "신화 1/6" },
  "CHEST"
)

local score, evidence = DB.ScoreItemRecord(record, "PRIEST_HOLY", "CHEST")
```

여러 아이템을 정렬할 때:

```lua
local sorted = DB.SortItemLinks("MAGE_FROST", "HEAD", itemLinks, "MPLUS_GREAT_VAULT", { keyLevel = 10 })
```

## 6. 스탯 계산 규칙

1. `C_Item.GetItemStats(itemLink)`로 raw stat token 획득.
2. `DB.NormalizeStats(rawStats)`로 내부 한글 canonical stat으로 변환.
3. 전문화별 `weights`를 곱해 점수 산정.
4. 동일 표기인 `=`는 반드시 같은 가중치를 사용.
5. 신성 사제는 사용자 확정값: **치명타 및 극대화 > 특화 > 유연성 > 가속**.

## 7. 장신구/무기 주의사항

스탯 점수는 장비 후보 정렬의 기본값이다. 장신구와 무기는 특수효과, 무기 DPS, 내부 쿨다운, 대상 수, 던전 패턴에 따라 실제 가치가 크게 달라진다.

애드온은 다음 필드를 추가 보정용으로 두는 것이 좋다.

```lua
trinketManualRank = "S" -- S/A/B/C
weaponDpsOverride = number
simcDelta = number
qeliveDelta = number
logEvidence = "..."
```

## 8. 유지보수 프롬프트

```text
WoW 한밤 시즌 1 / 12.0.5 장비 추천 애드온 DB를 갱신한다.
한글명은 공식 클라이언트/Blizzard KO/Wowhead KO에서 확인된 값만 사용한다.
영어명을 임의 번역하지 않는다.
itemId만으로 쐐기 금고, 쐐기 종료, 레이드 난이도, 신화 트랙을 판정하지 않는다.
실제 점수 계산은 itemLink -> GetDetailedItemLevelInfo -> C_Item.GetItemStats -> NormalizeStats -> ScoreItemRecord 순서로 한다.
'=' 스탯은 반드시 같은 가중치로 둔다.
UI 표기는 '쐐기 종료 보상 +10 / 영웅 3/6', '쐐기 금고 보상 +10 / 신화 1/6', '레이드 영웅'처럼 출처와 트랙을 분리한다.
장신구/무기 특수효과는 SimC/QE/로그 보정값을 별도로 둔다.
```

## 9. 파일 구성

| 파일 | 용도 |
|---|---|
| `MidnightS1_MPlus_Addon_DB_v1.7.lua` | 애드온 로드용 컴팩트 코어 DB |
| `MidnightS1_MPlus_Addon_Master_v1.7.md` | 사람/개발자용 통합 문서 |
| `MidnightS1_MPlus_Addon_Final_v1.7.zip` | 배포용 묶음 |

## 10. v1.7에서 제거한 것

- 과거 v0.x~v1.6의 중복 변경 이력.
- 검증되지 않은 정적 레이드 아이템명.
- itemId만 보고 신화/영웅을 확정하는 설명.
- 실제 itemLink 없이 최종 BiS라고 표시하는 정적 순위 표현.
