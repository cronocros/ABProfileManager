# World of Warcraft: 한밤 시즌 1 / 12.0.5 쐐기 장비 DB v0.5

> 목적: 애드온 제작 참고용 DB 자료.
> 검증 원칙: 한글명은 Wowhead 한국어 페이지 또는 공식 한글 표기에서 확인된 것만 사용. 임의 번역 금지.
> 생성일: 2026-05-31 KST
> v0.4 변경: v0.3 기반 + 엄격 BiS 검증 레이어 / Myth Track 런타임 판정 / 전문화별 최적화 정책 추가
> v0.3 변경: 전문화별 2차 스탯 우선도 재검증, BiS 검증 플래그, Myth Track 판정 정책 추가
> 범위: 레이드 드랍 제외. 쐐기 던전 드랍 + 위대한 금고 던전 슬롯/촉매 티어 4셋 구조.

## 0. 데이터 신뢰도

| 항목 | 상태 |
|---|---|
| 한밤 시즌 1 쐐기 보상 구조 | 검증 완료 |
| 던전 한글명 | 검증 완료 |
| 쐐기 드랍 아이템 한글명/ID | 검증 완료: Wowhead 한국어 아이템 URL 기준 |
| 티어 세트명 | 검증 완료: Wowhead 한국어 아이템 세트 기준 |
| 티어 개별 아이템 ID | 검증 완료: Wowhead 한국어 아이템 세트/개별 아이템 URL 기준 |
| 전문화별 최종 BiS | 정적 확정 불가. `bisOptimalVerified=false` 기본값. 심크/QE/로그 기반 보정 필요 |

## 0.1 v0.3 검증 결론 — 기존 v0.2의 성격과 보강 내용

| 항목 | v0.2 상태 | v0.3 처리 |
|---|---|---|
| 쐐기 던전명/한글명 | 검증 완료 | 유지. `공결탑 제나스` 고정 |
| 티어 5부위 ID/한글명 | 검증 완료 | 유지 |
| 쐐기 드랍 아이템 풀 | 검증 완료 | 유지. 단, “최적 BiS 확정”과는 분리 |
| 전문화별 2차 스탯 | 일부 오래되었거나 부정확 | 전 전문화 재검증 후 `secondaryPriority` 추가 |
| 최적 BiS 여부 | 미확정 | 모든 레코드에 `bisOptimalVerified=false` 기본값 부여 |
| 신화/영웅 트랙 구분 | `itemId`만 존재 | `itemId`만으로 트랙 판정 금지. `itemLink/bonusId/upgradeTrack` 필드 필요 |

### 핵심 결론

현재 DB는 **“검증된 쐐기 드랍 풀 + 티어/촉매 + 전문화별 스탯 우선도 DB”**로 사용 가능하다.
하지만 각 전문화의 “가장 최적화된 최종 BiS”는 정적 테이블만으로 확정하면 안 된다. 이유는 다음과 같다.

1. 같은 `itemId`라도 보상 출처와 보너스 ID에 따라 아이템 레벨/업그레이드 트랙이 달라질 수 있다.
2. 쐐기 +10 종료 보상은 Hero 트랙이고, +10 위대한 금고/보너스롤은 Myth 트랙이다.
3. 티어 4셋 부위는 고정 가치가 있어서 단순 2차 스탯만으로 교체하면 안 된다.
4. 장신구는 2차 스탯보다 효과 튜닝이 더 중요할 수 있다.
5. 힐러/탱커는 던전 패턴, 생존 목적, 팀 조합에 따라 우선도가 바뀐다.

```lua
ITEM_TRACK_POLICY = {
  baseItemIdIsDifficultySpecific = false,
  reason = "WoW itemId는 기본 아이템 식별자이며, 신화/영웅/업그레이드 트랙 판정에는 itemLink의 bonusId/upgradeTrack/itemLevel 정보가 필요하다.",
  mplusEndOfDungeonPlus10 = { track="Hero", upgrade="3/6", itemLevel=266, mythTrack=false },
  mplusGreatVaultPlus10   = { track="Myth", upgrade="1/6", itemLevel=272, mythTrack=true },
  mplusBonusRollPlus10    = { track="Myth", upgrade="1/6", itemLevel=272, mythTrack=true },
  addonRequiredFields = { "baseItemId", "itemLink", "bonusIds", "itemLevel", "upgradeTrack", "upgradeRank", "sourceType" },
}

VALIDATION_COLUMNS = {
  koNameVerified = true,
  baseItemIdVerified = true,
  lootPoolVerified = true,
  statPriorityVerified = true,
  mythTrackVerifiedByItemIdOnly = false,
  requiresItemLinkBonusIdForMythTrack = true,
  bisOptimalVerifiedDefault = false,
}
```


## 1. 던전명 매핑

```lua
DUNGEONS = {
  MAGISTERS_TERRACE = { ko = "마법학자의 정원", en = "Magisters' Terrace" },
  MAISARA_CAVERNS = { ko = "마이사라 동굴", en = "Maisara Caverns" },
  NEXUS_POINT_XENAS = { ko = "공결탑 제나스", en = "Nexus-Point Xenas" },
  WINDRUNNER_SPIRE = { ko = "윈드러너 첨탑", en = "Windrunner Spire" },
  ALGETHAR_ACADEMY = { ko = "알게타르 대학", en = "Algeth'ar Academy" },
  SEAT_OF_THE_TRIUMVIRATE = { ko = "삼두정의 권좌", en = "Seat of the Triumvirate" },
  SKYREACH = { ko = "하늘탑", en = "Skyreach" },
  PIT_OF_SARON = { ko = "사론의 구덩이", en = "Pit of Saron" },
}
```

## 2. 전문화 기본 DB v0.3 — 스탯 우선도 검증 반영

> v0.2의 `statHint`는 폐기(deprecated). 애드온에서는 아래 `secondaryPriority`, `secondaryOrder`, `statPriorityVerified`, `bisOptimalVerified`, `bisStatus`를 기준으로 사용한다.
> `bisOptimalVerified=false`는 “아이템 이름/ID/드랍풀/스탯 우선도는 검증됐지만, 모든 캐릭터에 대해 정적 BiS 확정이라고 볼 수는 없음”을 뜻한다.

```lua
SPECS = {
  DEATHKNIGHT_BLOOD = { classKo="죽음의 기사", specKo="혈기", role="TANK", armor="PLATE", primary="힘", tierSetId=1978, tierSetKo="가혹한 기수의 탄식",
    secondaryPriority="아이템레벨/힘 우선, 가속·특화·유연성 균형", secondaryOrder={"가속","특화","유연성","치명타 및 극대화"}, statPriorityVerified=true, statPriorityStatus="TANK_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="혈기 DK는 영웅 특성/생존-딜 목적에 따라 가속·특화·유연성 가치가 달라짐.", source="WOWHEAD_BLOOD_DK_GEAR" },
  DEATHKNIGHT_FROST = { classKo="죽음의 기사", specKo="냉기", role="DPS", armor="PLATE", primary="힘", tierSetId=1978, tierSetKo="가혹한 기수의 탄식",
    secondaryPriority="치명타 및 극대화 >= 특화 >> 가속 > 유연성", secondaryOrder={"치명타 및 극대화","특화","가속","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="무기 DPS/힘과 함께 치명·특화 조합 우선.", source="WOWHEAD_FROST_DK_GEAR" },
  DEATHKNIGHT_UNHOLY = { classKo="죽음의 기사", specKo="부정", role="DPS", armor="PLATE", primary="힘", tierSetId=1978, tierSetKo="가혹한 기수의 탄식",
    secondaryPriority="치명타 및 극대화 >= 특화 >> 가속 >= 유연성", secondaryOrder={"치명타 및 극대화","특화","가속","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="치명·특화 중심. 실제 장비는 심크 권장.", source="WOWHEAD_UNHOLY_DK_GEAR" },
  DEMONHUNTER_DEVOURER = { classKo="악마사냥꾼", specKo="포식", role="DPS", armor="LEATHER", primary="지능", tierSetId=1979, tierSetKo="포식의 파괴자의 허물",
    secondaryPriority="특화 >= 가속 > 치명타 및 극대화 >>> 유연성", secondaryOrder={"특화","가속","치명타 및 극대화","유연성"}, statPriorityVerified=true, statPriorityStatus="CORRECTED_V02_PRIMARY_STAT",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="v0.2의 주스탯 민첩 표기는 오류. 포식은 지능 DPS 기준으로 수정.", source="WOWHEAD_DEVOURER_DH_GEAR" },
  DEMONHUNTER_HAVOC = { classKo="악마사냥꾼", specKo="파멸", role="DPS", armor="LEATHER", primary="민첩", tierSetId=1979, tierSetKo="포식의 파괴자의 허물",
    secondaryPriority="치명타 및 극대화 > 특화 >> 가속 > 유연성", secondaryOrder={"치명타 및 극대화","특화","가속","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="치명·특화 우선.", source="WOWHEAD_HAVOC_DH_GEAR" },
  DEMONHUNTER_VENGEANCE = { classKo="악마사냥꾼", specKo="복수", role="TANK", armor="LEATHER", primary="민첩", tierSetId=1979, tierSetKo="포식의 파괴자의 허물",
    secondaryPriority="아이템레벨 >>> 가속 >= 유연성 >= 치명타 및 극대화 > 특화", secondaryOrder={"가속","유연성","치명타 및 극대화","특화"}, statPriorityVerified=true, statPriorityStatus="TANK_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="탱커는 장신구/템렙 가치가 2차 스탯보다 큰 경우 많음.", source="WOWHEAD_VENGEANCE_DH_GEAR" },
  DRUID_BALANCE = { classKo="드루이드", specKo="조화", role="DPS", armor="LEATHER", primary="지능", tierSetId=1980, tierSetKo="영롱한 꽃의 새싹",
    secondaryPriority="특화 > 치명타 및 극대화 = 가속 >> 유연성", secondaryOrder={"특화","치명타 및 극대화","가속","유연성"}, statPriorityVerified=true, statPriorityStatus="CORRECTED_V02_STAT_PRIORITY",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="v0.2의 가속 우선 표기는 조화 12.0.5 기준과 맞지 않아 수정.", source="WOWHEAD_BALANCE_DRUID_GEAR" },
  DRUID_FERAL = { classKo="드루이드", specKo="야성", role="DPS", armor="LEATHER", primary="민첩", tierSetId=1980, tierSetKo="영롱한 꽃의 새싹",
    secondaryPriority="특화 > 가속 > 치명타 및 극대화 > 유연성", secondaryOrder={"특화","가속","치명타 및 극대화","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="특화 중심. 가속/치명은 빌드·보유 장비에 따라 심크.", source="WOWHEAD_FERAL_DRUID_GEAR" },
  DRUID_GUARDIAN = { classKo="드루이드", specKo="수호", role="TANK", armor="LEATHER", primary="민첩", tierSetId=1980, tierSetKo="영롱한 꽃의 새싹",
    secondaryPriority="아이템레벨/민첩 우선, 가속 > 유연성 > 특화 = 치명타 및 극대화", secondaryOrder={"가속","유연성","특화","치명타 및 극대화"}, statPriorityVerified=true, statPriorityStatus="TANK_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="수호는 +10 ilvl 차이가 스탯 조합보다 우선될 수 있음.", source="WOWHEAD_GUARDIAN_DRUID_GEAR" },
  DRUID_RESTO = { classKo="드루이드", specKo="회복", role="HEALER", armor="LEATHER", primary="지능", tierSetId=1980, tierSetKo="영롱한 꽃의 새싹",
    secondaryPriority="특화 = 가속 >= 유연성 >> 치명타 및 극대화", secondaryOrder={"특화","가속","유연성","치명타 및 극대화"}, statPriorityVerified=true, statPriorityStatus="HEALER_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="힐러는 던전 패턴/힐 프로필에 따라 QE/로그 확인 권장.", source="WOWHEAD_RESTO_DRUID_GEAR" },
  EVOKER_DEVASTATION = { classKo="기원사", specKo="황폐", role="DPS", armor="MAIL", primary="지능", tierSetId=1981, tierSetKo="검은 갈퀴발톱의 제복",
    secondaryPriority="치명타 및 극대화 > 가속 = 특화 > 유연성", secondaryOrder={"치명타 및 극대화","가속","특화","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="치명 우선, 가속/특화 동급권.", source="WOWHEAD_DEVASTATION_EVOKER_GEAR" },
  EVOKER_PRESERVATION = { classKo="기원사", specKo="보존", role="HEALER", armor="MAIL", primary="지능", tierSetId=1981, tierSetKo="검은 갈퀴발톱의 제복",
    secondaryPriority="특화 > 치명타 및 극대화 >= 가속 >> 유연성", secondaryOrder={"특화","치명타 및 극대화","가속","유연성"}, statPriorityVerified=true, statPriorityStatus="HEALER_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="보존은 힐 프로필/던전 단수에 따라 QE 권장.", source="WOWHEAD_PRESERVATION_EVOKER_GEAR" },
  EVOKER_AUGMENTATION = { classKo="기원사", specKo="증강", role="DPS", armor="MAIL", primary="지능", tierSetId=1981, tierSetKo="검은 갈퀴발톱의 제복",
    secondaryPriority="치명타 및 극대화 > 가속 > 특화 > 유연성", secondaryOrder={"치명타 및 극대화","가속","특화","유연성"}, statPriorityVerified=true, statPriorityStatus="CORRECTED_V02_STAT_PRIORITY",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="v0.2의 특화 최우선 표기는 12.0.5 Wowhead 기준과 달라 수정.", source="WOWHEAD_AUGMENTATION_EVOKER_GEAR" },
  HUNTER_BM = { classKo="사냥꾼", specKo="야수", role="DPS", armor="MAIL", primary="민첩", tierSetId=1982, tierSetKo="원시 파수꾼의 위장",
    secondaryPriority="무기 공격력/민첩 우선, 일반: 특화 > 가속 > 치명타 및 극대화 > 유연성", secondaryOrder={"특화","가속","치명타 및 극대화","유연성"}, statPriorityVerified=true, statPriorityStatus="CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="일부 M+ 빌드/자료는 치명·가속 우선으로 달라짐. 심크/로그 검증 필요.", source="WOWHEAD_BM_HUNTER_GEAR" },
  HUNTER_MARKSMAN = { classKo="사냥꾼", specKo="사격", role="DPS", armor="MAIL", primary="민첩", tierSetId=1982, tierSetKo="원시 파수꾼의 위장",
    secondaryPriority="치명타 및 극대화 >>> 특화 > 가속 > 유연성", secondaryOrder={"치명타 및 극대화","특화","가속","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="치명 보유 여부가 매우 중요.", source="WOWHEAD_MARKSMAN_HUNTER_OVERVIEW" },
  HUNTER_SURVIVAL = { classKo="사냥꾼", specKo="생존", role="DPS", armor="MAIL", primary="민첩", tierSetId=1982, tierSetKo="원시 파수꾼의 위장",
    secondaryPriority="특화 > 치명타 및 극대화 = 가속 > 유연성", secondaryOrder={"특화","치명타 및 극대화","가속","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="특화 우선, 치명/가속은 빌드 따라 근접.", source="WOWHEAD_SURVIVAL_HUNTER_GEAR" },
  MAGE_ARCANE = { classKo="마법사", specKo="비전", role="DPS", armor="CLOTH", primary="지능", tierSetId=1983, tierSetKo="공허파괴자의 합의",
    secondaryPriority="특화 > 가속 >= 치명타 및 극대화 >> 유연성", secondaryOrder={"특화","가속","치명타 및 극대화","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="특화 중심.", source="WOWHEAD_ARCANE_MAGE_GEAR" },
  MAGE_FIRE = { classKo="마법사", specKo="화염", role="DPS", armor="CLOTH", primary="지능", tierSetId=1983, tierSetKo="공허파괴자의 합의",
    secondaryPriority="가속 >= 특화 > 유연성 >> 치명타 및 극대화", secondaryOrder={"가속","특화","유연성","치명타 및 극대화"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="가속/특화 중심, 치명 낮음.", source="WOWHEAD_FIRE_MAGE_GEAR" },
  MAGE_FROST = { classKo="마법사", specKo="냉기", role="DPS", armor="CLOTH", primary="지능", tierSetId=1983, tierSetKo="공허파괴자의 합의",
    secondaryPriority="특화 >= 치명타 및 극대화 >> 가속 >= 유연성", secondaryOrder={"특화","치명타 및 극대화","가속","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="사용자 지적과 일치. 쐐기 오프피스는 특화+치명 또는 특화 포함 조합 우선.", source="WOWHEAD_FROST_MAGE_GEAR_STAT" },
  MONK_BREWMASTER = { classKo="수도사", specKo="양조", role="TANK", armor="LEATHER", primary="민첩", tierSetId=1984, tierSetKo="라덴에게 선택받은 자의 길",
    secondaryPriority="아이템레벨 우선, 동일 템렙: 치명타 및 극대화 = 유연성 = 특화 > 가속", secondaryOrder={"치명타 및 극대화","유연성","특화","가속"}, statPriorityVerified=true, statPriorityStatus="TANK_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="방어 기준. 딜 세팅은 심크 필요.", source="WOWHEAD_BREWMASTER_MONK_GEAR" },
  MONK_MISTWEAVER = { classKo="수도사", specKo="운무", role="HEALER", armor="LEATHER", primary="지능", tierSetId=1984, tierSetKo="라덴에게 선택받은 자의 길",
    secondaryPriority="가속 > 치명타 및 극대화 > 유연성 >> 특화", secondaryOrder={"가속","치명타 및 극대화","유연성","특화"}, statPriorityVerified=true, statPriorityStatus="HEALER_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="힐러 장신구/마나/던전 패턴 보정 필요.", source="WOWHEAD_MISTWEAVER_MONK_GEAR" },
  MONK_WINDWALKER = { classKo="수도사", specKo="풍운", role="DPS", armor="LEATHER", primary="민첩", tierSetId=1984, tierSetKo="라덴에게 선택받은 자의 길",
    secondaryPriority="가속 = 치명타 및 극대화 = 특화 >>> 유연성", secondaryOrder={"가속","치명타 및 극대화","특화","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="상위 3개 스탯이 거의 동급, 유연성 회피.", source="WOWHEAD_WINDWALKER_MONK_GEAR" },
  PALADIN_HOLY = { classKo="성기사", specKo="신성", role="HEALER", armor="PLATE", primary="지능", tierSetId=1985, tierSetKo="빛나는 선고의 예복",
    secondaryPriority="지능 우선, 특화 > 가속 = 치명타 및 극대화 > 유연성", secondaryOrder={"특화","가속","치명타 및 극대화","유연성"}, statPriorityVerified=true, statPriorityStatus="HEALER_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="힐러는 QELive/로그 보정 권장.", source="WOWHEAD_HOLY_PALADIN_GEAR" },
  PALADIN_PROTECTION = { classKo="성기사", specKo="보호", role="TANK", armor="PLATE", primary="힘", tierSetId=1985, tierSetKo="빛나는 선고의 예복",
    secondaryPriority="가속 > 유연성 = 치명타 및 극대화 > 특화", secondaryOrder={"가속","유연성","치명타 및 극대화","특화"}, statPriorityVerified=true, statPriorityStatus="TANK_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="고가속 선호. 장신구/생존은 별도.", source="WOWHEAD_PROTECTION_PALADIN_GEAR" },
  PALADIN_RETRIBUTION = { classKo="성기사", specKo="징벌", role="DPS", armor="PLATE", primary="힘", tierSetId=1985, tierSetKo="빛나는 선고의 예복",
    secondaryPriority="특화 > 치명타 및 극대화 > 가속 > 유연성", secondaryOrder={"특화","치명타 및 극대화","가속","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="특화 중심. Haste/Mastery 균형 의견도 있어 심크 권장.", source="WOWHEAD_RETRIBUTION_PALADIN_GUIDE" },
  PRIEST_DISC = { classKo="사제", specKo="수양", role="HEALER", armor="CLOTH", primary="지능", tierSetId=1986, tierSetKo="맹목적인 맹세의 번뇌",
    secondaryPriority="가속 > 치명타 및 극대화 > 특화 > 유연성", secondaryOrder={"가속","치명타 및 극대화","특화","유연성"}, statPriorityVerified=true, statPriorityStatus="HEALER_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="쐐기 힐/딜 비중에 따라 QE 권장.", source="WOWHEAD_DISC_PRIEST_GEAR" },
  PRIEST_HOLY = { classKo="사제", specKo="신성", role="HEALER", armor="CLOTH", primary="지능", tierSetId=1986, tierSetKo="맹목적인 맹세의 번뇌",
    secondaryPriority="쐐기 기준: 가속 > 유연성 = 치명타 및 극대화 > 특화", secondaryOrder={"가속","유연성","치명타 및 극대화","특화"}, statPriorityVerified=true, statPriorityStatus="EXTERNAL_MPLUS_CROSSCHECK",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="Wowhead M+ 섹션과 외부 가이드 교차 확인. 신성 사제는 레이드/쐐기 우선도가 다름.", source="WOWHEAD_HOLY_PRIEST_MPLUS_METHOD_CROSSCHECK" },
  PRIEST_SHADOW = { classKo="사제", specKo="암흑", role="DPS", armor="CLOTH", primary="지능", tierSetId=1986, tierSetKo="맹목적인 맹세의 번뇌",
    secondaryPriority="가속 > 특화 > 치명타 및 극대화 > 유연성", secondaryOrder={"가속","특화","치명타 및 극대화","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="가속/특화 상위.", source="WOWHEAD_SHADOW_PRIEST_GEAR" },
  ROGUE_ASSASSINATION = { classKo="도적", specKo="암살", role="DPS", armor="LEATHER", primary="민첩", tierSetId=1987, tierSetKo="암담한 재담의 광대",
    secondaryPriority="치명타 및 극대화 > 가속 > 특화 > 유연성", secondaryOrder={"치명타 및 극대화","가속","특화","유연성"}, statPriorityVerified=true, statPriorityStatus="CORRECTED_V02_STAT_PRIORITY",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="v0.2의 특화 최우선 표기에서 수정.", source="WOWHEAD_ASSASSINATION_ROGUE_OVERVIEW" },
  ROGUE_OUTLAW = { classKo="도적", specKo="무법", role="DPS", armor="LEATHER", primary="민첩", tierSetId=1987, tierSetKo="암담한 재담의 광대",
    secondaryPriority="가속 21~23% 근처까지 우선, 이후 치명타 및 극대화 >= 유연성 > 특화", secondaryOrder={"가속","치명타 및 극대화","유연성","특화"}, statPriorityVerified=true, statPriorityStatus="BREAKPOINT_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="가속 캡/구간 기반. 단순 선형 우선도 아님.", source="WOWHEAD_OUTLAW_ROGUE_OVERVIEW" },
  ROGUE_SUBTLETY = { classKo="도적", specKo="잠행", role="DPS", armor="LEATHER", primary="민첩", tierSetId=1987, tierSetKo="암담한 재담의 광대",
    secondaryPriority="특화 > 가속 구간값 >= 치명타 및 극대화 >> 유연성", secondaryOrder={"특화","가속","치명타 및 극대화","유연성"}, statPriorityVerified=true, statPriorityStatus="BREAKPOINT_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="영웅 특성에 따라 가속 목표치가 존재.", source="WOWHEAD_SUBTLETY_ROGUE_GEAR" },
  SHAMAN_ELEMENTAL = { classKo="주술사", specKo="정기", role="DPS", armor="MAIL", primary="지능", tierSetId=1988, tierSetKo="원시 핵의 옷차림",
    secondaryPriority="특화 목표치 우선 → 가속 = 치명타 및 극대화 >> 유연성", secondaryOrder={"특화","가속","치명타 및 극대화","유연성"}, statPriorityVerified=true, statPriorityStatus="BREAKPOINT_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="특화 약 72%/1200 rating 목표 후 가속·치명 분배.", source="WOWHEAD_ELEMENTAL_SHAMAN_STAT" },
  SHAMAN_ENHANCEMENT = { classKo="주술사", specKo="고양", role="DPS", armor="MAIL", primary="민첩", tierSetId=1988, tierSetKo="원시 핵의 옷차림",
    secondaryPriority="특화 > 가속 > 치명타 및 극대화 > 유연성", secondaryOrder={"특화","가속","치명타 및 극대화","유연성"}, statPriorityVerified=true, statPriorityStatus="CORRECTED_V02_STAT_PRIORITY",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="v0.2의 가속 최우선 표기에서 수정. 영웅 특성 따라 가속/특화 비중 변동.", source="WOWHEAD_ENHANCEMENT_SHAMAN_GEAR" },
  SHAMAN_RESTORATION = { classKo="주술사", specKo="복원", role="HEALER", armor="MAIL", primary="지능", tierSetId=1988, tierSetKo="원시 핵의 옷차림",
    secondaryPriority="치명타 및 극대화 > 특화 = 유연성 > 가속", secondaryOrder={"치명타 및 극대화","특화","유연성","가속"}, statPriorityVerified=true, statPriorityStatus="HEALER_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="치명 우선, 가속은 낮게 평가.", source="WOWHEAD_RESTORATION_SHAMAN_GEAR" },
  WARLOCK_AFFLICTION = { classKo="흑마법사", specKo="고통", role="DPS", armor="CLOTH", primary="지능", tierSetId=1989, tierSetKo="불태우는 심연의 지배",
    secondaryPriority="특화 = 치명타 및 극대화 > 가속 > 유연성", secondaryOrder={"특화","치명타 및 극대화","가속","유연성"}, statPriorityVerified=true, statPriorityStatus="CORRECTED_V02_STAT_PRIORITY",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="v0.2의 가속 최우선 표기에서 수정.", source="WOWHEAD_AFFLICTION_WARLOCK_GEAR" },
  WARLOCK_DEMONOLOGY = { classKo="흑마법사", specKo="악마", role="DPS", armor="CLOTH", primary="지능", tierSetId=1989, tierSetKo="불태우는 심연의 지배",
    secondaryPriority="가속 = 치명타 및 극대화 > 특화 > 유연성", secondaryOrder={"가속","치명타 및 극대화","특화","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="가속/치명 동급권.", source="WOWHEAD_DEMONOLOGY_WARLOCK_OVERVIEW" },
  WARLOCK_DESTRUCTION = { classKo="흑마법사", specKo="파괴", role="DPS", armor="CLOTH", primary="지능", tierSetId=1989, tierSetKo="불태우는 심연의 지배",
    secondaryPriority="가속 > 특화 = 치명타 및 극대화 > 유연성", secondaryOrder={"가속","특화","치명타 및 극대화","유연성"}, statPriorityVerified=true, statPriorityStatus="CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="일부 자료는 가속=치명으로 보며, 장비별 심크 필요.", source="WOWHEAD_DESTRUCTION_WARLOCK_GEAR" },
  WARRIOR_ARMS = { classKo="전사", specKo="무기", role="DPS", armor="PLATE", primary="힘", tierSetId=1990, tierSetKo="밤의 종결자의 분노",
    secondaryPriority="치명타 및 극대화 >= 가속 > 특화 > 유연성", secondaryOrder={"치명타 및 극대화","가속","특화","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="치명/가속 우선.", source="WOWHEAD_ARMS_WARRIOR_GEAR" },
  WARRIOR_FURY = { classKo="전사", specKo="분노", role="DPS", armor="PLATE", primary="힘", tierSetId=1990, tierSetKo="밤의 종결자의 분노",
    secondaryPriority="가속 >= 특화 > 치명타 및 극대화 = 유연성", secondaryOrder={"가속","특화","치명타 및 극대화","유연성"}, statPriorityVerified=true, statPriorityStatus="VERIFIED",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="가속/특화 우선.", source="WOWHEAD_FURY_WARRIOR_GEAR" },
  WARRIOR_PROTECTION = { classKo="전사", specKo="방어", role="TANK", armor="PLATE", primary="힘", tierSetId=1990, tierSetKo="밤의 종결자의 분노",
    secondaryPriority="가속 > 유연성 = 치명타 및 극대화 > 특화", secondaryOrder={"가속","유연성","치명타 및 극대화","특화"}, statPriorityVerified=true, statPriorityStatus="TANK_CONTEXTUAL",
    bisOptimalVerified=false, bisStatus="LOOT_POOL_AND_STAT_PRIORITY_VERIFIED__STATIC_BIS_NOT_CONFIRMED",
    preferredStatPairRule="상위 2개 2차 스탯 조합 우선. 동일/구간형 전문화는 note 참고.", note="생존/딜 목적 따라 치명·유연 순서 변동 가능.", source="WOWHEAD_PROTECTION_WARRIOR_GEAR" },
}
```

## 2.1 냉기 마법사 검증 예시

사용자 지적처럼 냉기 마법사는 **특화 >= 치명타 및 극대화 >> 가속 >= 유연성** 방향이 맞다.
따라서 쐐기 오프피스 후보를 평가할 때는 다음처럼 판단한다.

| 평가 | 예시 | 판단 |
|---|---|---|
| 최우선 조합 | 특화 + 치명타 및 극대화 | 냉법용 최고 선호 조합 |
| 허용 조합 | 특화 + 가속 | 특화가 있어 사용 가능. 치명 부족 시 보정 필요 |
| 낮은 선호 | 치명타 및 극대화 + 유연성 | 특화가 없어 냉법 최적 오프피스 후보로는 약함 |
| 티어 부위 | 공허파괴자의 합의 4셋 | 2차 스탯이 완벽하지 않아도 세트 효과 때문에 우선 |

예: `공허파괴자의 면사포`는 마법사 티어 머리이므로 4셋 구성의 일부로 평가하고, `니사라의 어깨덧옷`처럼 특화가 포함된 쐐기 천 어깨는 오프피스 후보로 점수화한다. 반면 `지맥 다리보호구`처럼 치명+유연 조합인 아이템은 냉법의 2차 스탯 방향과 완전히 맞는 후보는 아니다.


## 3. 촉매/위대한 금고 티어 DB

> 원칙: 티어는 레이드 드랍을 제외하더라도 위대한 금고 던전 슬롯 또는 촉매 변환으로 4셋 구성 가능.
> 애드온 구현 권장: `tierSlots = {HEAD, SHOULDERS, CHEST, HANDS, LEGS}` 중 4개를 활성 티어로 취급하고, 남는 1부위는 M+ 오프피스로 비교.

```lua
TIER_SETS = {
  [1978] = {
    classKo="죽음의 기사", setKo="가혹한 기수의 탄식", source="WOWHEAD_KO_ITEM_SET_1978",
    pieces = {
      CHEST={id=249973, ko="가혹한 기수의 흉갑", slotKo="가슴"},
      HANDS={id=249971, ko="가혹한 기수의 해골손아귀", slotKo="손"},
      HEAD ={id=249970, ko="가혹한 기수의 왕관", slotKo="머리"},
      LEGS ={id=249969, ko="가혹한 기수의 다리보호대", slotKo="다리"},
      SHOULDERS={id=249968, ko="가혹한 기수의 공포가시", slotKo="어깨"},
    }
  },
  [1979] = {
    classKo="악마사냥꾼", setKo="포식의 파괴자의 허물", source="WOWHEAD_KO_ITEM_SET_1979",
    pieces = {
      CHEST={id=250036, ko="포식의 파괴자 동력장치", slotKo="가슴"},
      HANDS={id=250034, ko="포식의 파괴자 정수 손장갑", slotKo="손"},
      HEAD ={id=250033, ko="포식의 파괴자 유입구", slotKo="머리"},
      LEGS ={id=250032, ko="포식의 파괴자 피스톤", slotKo="다리"},
      SHOULDERS={id=250031, ko="포식의 파괴자 배출장갑", slotKo="어깨"},
    }
  },
  [1980] = {
    classKo="드루이드", setKo="영롱한 꽃의 새싹", source="WOWHEAD_KO_ITEM_SET_1980",
    pieces = {
      CHEST={id=250027, ko="영롱한 꽃의 밑동", slotKo="가슴"},
      HANDS={id=250025, ko="영롱한 꽃의 나무지기", slotKo="손"},
      HEAD ={id=250024, ko="영롱한 꽃의 나뭇가지", slotKo="머리"},
      LEGS ={id=250023, ko="영롱한 꽃의 체관싸개", slotKo="다리"},
      SHOULDERS={id=250022, ko="영롱한 꽃의 씨앗 깍지", slotKo="어깨"},
    }
  },
  [1981] = {
    classKo="기원사", setKo="검은 갈퀴발톱의 제복", source="WOWHEAD_KO_ITEM_SET_1981",
    pieces = {
      CHEST={id=250000, ko="검은 갈퀴발톱의 광란수호물", slotKo="가슴"},
      HANDS={id=249998, ko="검은 갈퀴발톱의 집행자 손아귀", slotKo="손"},
      HEAD ={id=249997, ko="검은 갈퀴발톱의 뿔투구", slotKo="머리"},
      LEGS ={id=249996, ko="검은 갈퀴발톱의 경갑", slotKo="다리"},
      SHOULDERS={id=249995, ko="검은 갈퀴발톱의 봉화", slotKo="어깨"},
    }
  },
  [1982] = {
    classKo="사냥꾼", setKo="원시 파수꾼의 위장", source="WOWHEAD_KO_ITEM_SET_1982",
    pieces = {
      CHEST={id=249991, ko="원시 파수꾼의 비늘판금", slotKo="가슴"},
      HANDS={id=249989, ko="원시 파수꾼의 갈퀴보호대", slotKo="손"},
      HEAD ={id=249988, ko="원시 파수꾼의 아귀", slotKo="머리"},
      LEGS ={id=249987, ko="원시 파수꾼의 다리보호대", slotKo="다리"},
      SHOULDERS={id=249986, ko="원시 파수꾼의 전리품", slotKo="어깨"},
    }
  },
  [1983] = {
    classKo="마법사", setKo="공허파괴자의 합의", source="WOWHEAD_KO_ITEM_SET_1983",
    pieces = {
      CHEST={id=250063, ko="공허파괴자의 로브", slotKo="가슴"},
      HANDS={id=250061, ko="공허파괴자의 장갑", slotKo="손"},
      HEAD ={id=250060, ko="공허파괴자의 면사포", slotKo="머리"},
      LEGS ={id=250059, ko="공허파괴자의 무릎바지", slotKo="다리"},
      SHOULDERS={id=250058, ko="공허파괴자의 지맥 연결체", slotKo="어깨"},
    }
  },
  [1984] = {
    classKo="수도사", setKo="라덴에게 선택받은 자의 길", source="WOWHEAD_KO_ITEM_SET_1984",
    pieces = {
      CHEST={id=250018, ko="라덴에게 선택받은 자의 전투복", slotKo="가슴"},
      HANDS={id=250016, ko="라덴에게 선택받은 자의 천둥주먹", slotKo="손"},
      HEAD ={id=250015, ko="라덴에게 선택받은 자의 무시무시한 안면", slotKo="머리"},
      LEGS ={id=250014, ko="라덴에게 선택받은 자의 싹쓸이 바지", slotKo="다리"},
      SHOULDERS={id=250013, ko="라덴에게 선택받은 자의 기의 돌", slotKo="어깨"},
    }
  },
  [1985] = {
    classKo="성기사", setKo="빛나는 선고의 예복", source="WOWHEAD_KO_ITEM_SET_1985",
    pieces = {
      CHEST={id=249964, ko="빛나는 선고의 신성 전쟁판금", slotKo="가슴"},
      HANDS={id=249962, ko="빛나는 선고의 건틀릿", slotKo="손"},
      HEAD ={id=249961, ko="빛나는 선고의 흔들림 없는 시선", slotKo="머리"},
      LEGS ={id=249960, ko="빛나는 선고의 경갑", slotKo="다리"},
      SHOULDERS={id=249959, ko="빛나는 선고의 섭리의 경계", slotKo="어깨"},
    }
  },
  [1986] = {
    classKo="사제", setKo="맹목적인 맹세의 번뇌", source="WOWHEAD_KO_ITEM_SET_1986",
    pieces = {
      CHEST={id=250054, ko="맹목적인 맹세의 예복", slotKo="가슴"},
      HANDS={id=250052, ko="맹목적인 맹세의 손길", slotKo="손"},
      HEAD ={id=250051, ko="맹목적인 맹세의 날개 달린 문장", slotKo="머리"},
      LEGS ={id=250050, ko="맹목적인 맹세의 다리보호구", slotKo="다리"},
      SHOULDERS={id=250049, ko="맹목적인 맹세의 대천사보호대", slotKo="어깨"},
    }
  },
  [1987] = {
    classKo="도적", setKo="암담한 재담의 광대", source="WOWHEAD_KO_ITEM_SET_1987",
    pieces = {
      CHEST={id=250009, ko="암담한 재담의 광적인 치장", slotKo="가슴"},
      HANDS={id=250007, ko="암담한 재담의 손재주", slotKo="손"},
      HEAD ={id=250006, ko="암담한 재담의 가면", slotKo="머리"},
      LEGS ={id=250005, ko="암담한 재담의 칼날집", slotKo="다리"},
      SHOULDERS={id=250004, ko="암담한 재담의 맹독 보관통", slotKo="어깨"},
    }
  },
  [1988] = {
    classKo="주술사", setKo="원시 핵의 옷차림", source="WOWHEAD_KO_ITEM_SET_1988",
    pieces = {
      CHEST={id=249982, ko="원시 핵의 포옹", slotKo="가슴"},
      HANDS={id=249980, ko="원시 핵의 대지손아귀", slotKo="손"},
      HEAD ={id=249979, ko="원시 핵의 집중점", slotKo="머리"},
      LEGS ={id=249978, ko="원시 핵의 다리보호구", slotKo="다리"},
      SHOULDERS={id=249977, ko="원시 핵의 돌개바람", slotKo="어깨"},
    }
  },
  [1989] = {
    classKo="흑마법사", setKo="불태우는 심연의 지배", source="WOWHEAD_KO_ITEM_SET_1989",
    pieces = {
      CHEST={id=250045, ko="불태우는 심연의 공포로브", slotKo="가슴"},
      HANDS={id=250043, ko="불태우는 심연의 손아귀", slotKo="손"},
      HEAD ={id=250042, ko="불태우는 심연의 이글거리는 불길", slotKo="머리"},
      LEGS ={id=250041, ko="불태우는 심연의 기둥", slotKo="다리"},
      SHOULDERS={id=250040, ko="불태우는 심연의 격노", slotKo="어깨"},
    }
  },
  [1990] = {
    classKo="전사", setKo="밤의 종결자의 분노", source="WOWHEAD_KO_ITEM_SET_1990",
    pieces = {
      CHEST={id=249955, ko="밤의 종결자의 가슴보호갑", slotKo="가슴"},
      HANDS={id=249953, ko="밤의 종결자의 철권", slotKo="손"},
      HEAD ={id=249952, ko="밤의 종결자의 엄니", slotKo="머리"},
      LEGS ={id=249951, ko="밤의 종결자의 정강이싸개", slotKo="다리"},
      SHOULDERS={id=249950, ko="밤의 종결자의 견갑", slotKo="어깨"},
    }
  },
}
```

## 4. 쐐기 드랍 아이템 풀: 장신구/목/반지/망토

```lua
ACCESSORIES = {
  { slot="NECK", id=251096, ko="괴로운 비탄의 펜던트", dungeon="윈드러너 첨탑" },
  { slot="NECK", id=50228, ko="뾰족한 이미르하임 목장식", dungeon="사론의 구덩이" },
  { slot="NECK", id=151309, ko="뒤틀리는 공허의 목걸이", dungeon="삼두정의 권좌" },
  { slot="RING", id=251115, ko="분기점의 고리", dungeon="마법학자의 정원" },
  { slot="RING", id=251217, ko="공허의 맞물림", dungeon="공결탑 제나스" },
  { slot="RING", id=251093, ko="소외된 빛", dungeon="공결탑 제나스" },
  { slot="RING", id=193708, ko="백금 별의 고리", dungeon="알게타르 대학" },
  { slot="RING", id=49812, ko="훔친 결혼반지", dungeon="사론의 구덩이" },
  { slot="RING", id=151308, ko="에레다스 귀족의 인장", dungeon="삼두정의 권좌" },
  { slot="RING", id=151311, ko="삼두정의 고리", dungeon="삼두정의 권좌" },
  { slot="BACK", id=260312, ko="저항하는 수호자의 외투", dungeon="마법학자의 정원" },
  { slot="BACK", id=251161, ko="영혼사냥꾼의 장막", dungeon="마이사라 동굴" },
  { slot="BACK", id=193712, ko="물약으로 얼룩진 망토", dungeon="알게타르 대학" },
  { slot="BACK", id=49823, ko="쓰러진 추기경의 망토", dungeon="사론의 구덩이" },
  { slot="BACK", id=258575, ko="강도 높은 미늘 큰망토", dungeon="하늘탑" },
}
```

## 5. 쐐기 드랍 아이템 풀: 천

```lua
CLOTH_ARMOR = {
  { slot="HEAD", id=193703, ko="조직화된 법왕의 가면", dungeon="알게타르 대학" },
  { slot="HEAD", id=251080, ko="덤불여명 후광", dungeon="윈드러너 첨탑" },
  { slot="HEAD", id=151337, ko="흑마술사의 관", dungeon="삼두정의 권좌" },
  { slot="SHOULDERS", id=251213, ko="니사라의 어깨덧옷", dungeon="공결탑 제나스" },
  { slot="SHOULDERS", id=251085, ko="어둠의 헌신의 어깨덧옷", dungeon="윈드러너 첨탑" },
  { slot="SHOULDERS", id=151299, ko="총독의 암영 어깨덧옷", dungeon="삼두정의 권좌" },
  { slot="SHOULDERS", id=258578, ko="빛의 결속자 어깨보호대", dungeon="하늘탑" },
  { slot="CHEST", id=251120, ko="떨어지는 암영의 싸개", dungeon="마법학자의 정원" },
  { slot="CHEST", id=193720, ko="청동 도전자의 로브", dungeon="마이사라 동굴" },
  { slot="CHEST", id=49825, ko="창백한 뼈 로브", dungeon="사론의 구덩이" },
  { slot="CHEST", id=151303, ko="공허술사 로브", dungeon="삼두정의 권좌" },
  { slot="WRIST", id=251108, ko="경계하는 진노의 싸개", dungeon="마법학자의 정원" },
  { slot="WRIST", id=49809, ko="땅속 이끼의 손목보호구", dungeon="사론의 구덩이" },
  { slot="WRIST", id=151305, ko="혼돈의 손목싸개", dungeon="삼두정의 권좌" },
  { slot="WRIST", id=258580, ko="작열하는 빛의 팔보호구", dungeon="하늘탑" },
  { slot="HANDS", id=251172, ko="부정사술 결속대", dungeon="마이사라 동굴" },
  { slot="HANDS", id=251211, ko="으스러진 손가락보호대", dungeon="공결탑 제나스" },
  { slot="HANDS", id=193713, ko="실험 안전 장갑", dungeon="알게타르 대학" },
  { slot="HANDS", id=151300, ko="승천자의 손등싸개", dungeon="삼두정의 권좌" },
  { slot="WAIST", id=251102, ko="순응의 죔쇠띠", dungeon="마법학자의 정원" },
  { slot="WAIST", id=50263, ko="빛과 소금 허리띠", dungeon="사론의 구덩이" },
  { slot="LEGS", id=251205, ko="지맥 다리보호구", dungeon="공결탑 제나스" },
  { slot="LEGS", id=251090, ko="사령관의 빛바랜 짧은바지", dungeon="윈드러너 첨탑" },
  { slot="LEGS", id=151304, ko="정복자의 다리보호구", dungeon="삼두정의 권좌" },
  { slot="LEGS", id=258574, ko="소용돌이치는 빛의 다리싸개", dungeon="하늘탑" },
  { slot="FEET", id=251167, ko="밤사냥감 추적자", dungeon="마이사라 동굴" },
  { slot="FEET", id=49805, ko="얼음둘레 덧신", dungeon="사론의 구덩이" },
  { slot="FEET", id=258584, ko="빛의 결속자 발보호대", dungeon="하늘탑" },
}
```

## 6. 쐐기 드랍 아이템 풀: 가죽

```lua
LEATHER_ARMOR = {
  { slot="HEAD", id=251109, ko="주문절단 그림자복면", dungeon="마법학자의 정원" },
  { slot="HEAD", id=251177, ko="악취 나는 부정왕관", dungeon="마이사라 동굴" },
  { slot="HEAD", id=151336, ko="공허에 스친 두건", dungeon="삼두정의 권좌" },
  { slot="SHOULDERS", id=251171, ko="마법에 걸린 해골가시", dungeon="마이사라 동굴" },
  { slot="SHOULDERS", id=251092, ko="전사한 그런트의 어깨덧옷", dungeon="윈드러너 첨탑" },
  { slot="SHOULDERS", id=258581, ko="붉은깃털 어깨덧옷", dungeon="하늘탑" },
  { slot="CHEST", id=251216, ko="악독한 조끼", dungeon="공결탑 제나스" },
  { slot="CHEST", id=251099, ko="울부짖는 강풍의 조끼", dungeon="윈드러너 첨탑" },
  { slot="CHEST", id=258586, ko="붉은깃털 가슴보호대", dungeon="하늘탑" },
  { slot="WRIST", id=50264, ko="물어뜯긴 가죽 손목보호구", dungeon="사론의 구덩이" },
  { slot="WRIST", id=251103, ko="관리인의 소매장식", dungeon="마법학자의 정원" },
  { slot="WRIST", id=193714, ko="광란뿌리 소매장식", dungeon="알게타르 대학" },
  { slot="WRIST", id=151315, ko="암흑의 구속 팔보호구", dungeon="삼두정의 권좌" },
  { slot="HANDS", id=251113, ko="농후한 찐득이 장갑", dungeon="마법학자의 정원" },
  { slot="HANDS", id=251204, ko="핵장인의 제어 장치", dungeon="공결탑 제나스" },
  { slot="HANDS", id=193721, ko="루비 참가자의 장갑", dungeon="알게타르 대학" },
  { slot="HANDS", id=151318, ko="암흑 구름의 장갑", dungeon="삼두정의 권좌" },
  { slot="WAIST", id=251082, ko="치악덩굴 허리끈", dungeon="윈드러너 첨탑" },
  { slot="WAIST", id=251166, ko="매사냥꾼의 허리끈", dungeon="마이사라 동굴" },
  { slot="WAIST", id=151316, ko="암영 덩굴손의 허리끈", dungeon="삼두정의 권좌" },
  { slot="WAIST", id=49806, ko="바위갈퀴의 검은띠", dungeon="사론의 구덩이" },
  { slot="LEGS", id=251087, ko="머무는 유산의 다리싸개", dungeon="윈드러너 첨탑" },
  { slot="LEGS", id=49817, ko="털이 많은 고룡가죽 다리보호구", dungeon="사론의 구덩이" },
  { slot="LEGS", id=151314, ko="변화의 추적자 가죽 바지", dungeon="삼두정의 권좌" },
  { slot="FEET", id=251121, ko="도마나르의 광포한 발보호대", dungeon="마법학자의 정원" },
  { slot="FEET", id=251210, ko="일월식 발목화", dungeon="공결탑 제나스" },
  { slot="FEET", id=151317, ko="스며드는 공포의 발보호구", dungeon="삼두정의 권좌" },
  { slot="FEET", id=258577, ko="타오르는 집중의 장화", dungeon="하늘탑" },
}
```

## 7. 쐐기 드랍 아이템 풀: 사슬

```lua
MAIL_ARMOR = {
  { slot="HEAD", id=251119, ko="회오리의 안면", dungeon="마법학자의 정원" },
  { slot="HEAD", id=49824, ko="쫓겨난 발키르의 뿔", dungeon="사론의 구덩이" },
  { slot="HEAD", id=258585, ko="뾰족눈 광투구", dungeon="하늘탑" },
  { slot="SHOULDERS", id=251176, ko="부활자의 무게", dungeon="마이사라 동굴" },
  { slot="SHOULDERS", id=251097, ko="화살의 비행 어깨덮개", dungeon="윈드러너 첨탑" },
  { slot="SHOULDERS", id=193704, ko="비늘 학위 어깨덮개", dungeon="알게타르 대학" },
  { slot="SHOULDERS", id=50233, ko="쫓겨난 발키르의 어깨보호대", dungeon="사론의 구덩이" },
  { slot="SHOULDERS", id=151323, ko="공허 사냥꾼의 견갑", dungeon="삼두정의 권좌" },
  { slot="CHEST", id=251114, ko="공허왜곡 수액사슬", dungeon="마법학자의 정원" },
  { slot="CHEST", id=251179, ko="썩어가는 흉갑", dungeon="마이사라 동굴" },
  { slot="CHEST", id=151325, ko="공허 고리 로브", dungeon="삼두정의 권좌" },
  { slot="CHEST", id=258576, ko="뾰족눈 가슴보호대", dungeon="하늘탑" },
  { slot="WRIST", id=251209, ko="핵감시관 소매장식", dungeon="공결탑 제나스" },
  { slot="WRIST", id=251079, ko="호박석잎 팔보호구", dungeon="윈드러너 첨탑" },
  { slot="WRIST", id=151321, ko="검은송곳니 비늘 손목보호구", dungeon="삼두정의 권좌" },
  { slot="HANDS", id=251089, ko="잊힌 명예의 손장갑", dungeon="윈드러너 첨탑" },
  { slot="WAIST", id=251110, ko="선래쉬의 태양띠", dungeon="마법학자의 정원" },
  { slot="WAIST", id=193722, ko="하늘빛 경쟁의 허리띠", dungeon="알게타르 대학" },
  { slot="WAIST", id=49810, ko="거친 좀비 허리띠", dungeon="사론의 구덩이" },
  { slot="WAIST", id=151326, ko="속박된 마력의 허리보호대", dungeon="삼두정의 권좌" },
  { slot="LEGS", id=251104, ko="질서정연한 행실의 다리보호구", dungeon="마법학자의 정원" },
  { slot="LEGS", id=251170, ko="교활매듭 긴바지", dungeon="마이사라 동굴" },
  { slot="LEGS", id=251215, ko="천상의 기만의 경갑", dungeon="공결탑 제나스" },
  { slot="LEGS", id=49811, ko="검은용가죽 짧은바지", dungeon="사론의 구덩이" },
  { slot="LEGS", id=151338, ko="움직이는 어둠의 다리보호구", dungeon="삼두정의 권좌" },
  { slot="FEET", id=251084, ko="채찍뱀 발덮개", dungeon="윈드러너 첨탑" },
  { slot="FEET", id=193715, ko="폭발적인 성장의 장화", dungeon="알게타르 대학" },
  { slot="FEET", id=258582, ko="강도 높은 미늘 장화", dungeon="하늘탑" },
}
```

## 8. 쐐기 드랍 아이템 풀: 판금

```lua
PLATE_ARMOR = {
  { slot="HEAD", id=251098, ko="화살 제조인의 빛바랜 면갑", dungeon="윈드러너 첨탑" },
  { slot="HEAD", id=49819, ko="해골 군주의 두개골", dungeon="사론의 구덩이" },
  { slot="HEAD", id=151333, ko="암흑 특사의 관", dungeon="삼두정의 권좌" },
  { slot="HEAD", id=258579, ko="내장분쇄자 철갑투구", dungeon="하늘탑" },
  { slot="SHOULDERS", id=251164, ko="융합체의 멜빵", dungeon="마이사라 동굴" },
  { slot="SHOULDERS", id=251157, ko="작열하는 어깨덮개", dungeon="공결탑 제나스" },
  { slot="SHOULDERS", id=50234, ko="얼어붙은 피의 어깨철갑", dungeon="사론의 구덩이" },
  { slot="SHOULDERS", id=151331, ko="뒤틀린 자의 견갑", dungeon="삼두정의 권좌" },
  { slot="SHOULDERS", id=258587, ko="이글거리는 광선의 어깨덮개", dungeon="하늘탑" },
  { slot="CHEST", id=251101, ko="비전 수호병의 껍질", dungeon="마법학자의 정원" },
  { slot="CHEST", id=193705, ko="검증된 지식의 가슴보호갑", dungeon="알게타르 대학" },
  { slot="CHEST", id=50272, ko="서리고룡 뼈갑옷", dungeon="사론의 구덩이" },
  { slot="CHEST", id=151329, ko="어둠의 손길 가슴보호갑", dungeon="삼두정의 권좌" },
  { slot="WRIST", id=263193, ko="트롤사냥꾼의 손목매듭", dungeon="마이사라 동굴" },
  { slot="WRIST", id=251203, ko="카스레스의 결속띠", dungeon="공결탑 제나스" },
  { slot="HANDS", id=251081, ko="잿불숲 손아귀", dungeon="윈드러너 첨탑" },
  { slot="HANDS", id=151332, ko="공허발톱 건틀릿", dungeon="삼두정의 권좌" },
  { slot="HANDS", id=258583, ko="진홍빛 건틀릿", dungeon="하늘탑" },
  { slot="WAIST", id=251112, ko="어둠분열 요대", dungeon="마법학자의 정원" },
  { slot="WAIST", id=251086, ko="갈퀴올가미 수호자", dungeon="윈드러너 첨탑" },
  { slot="WAIST", id=49808, ko="구부러진 황금띠", dungeon="사론의 구덩이" },
  { slot="WAIST", id=151327, ko="어둠수호병의 요대", dungeon="삼두정의 권좌" },
  { slot="LEGS", id=251118, ko="잔존하는 암흑의 다리갑옷", dungeon="마법학자의 정원" },
  { slot="LEGS", id=251208, ko="빛흉터 다리가리개", dungeon="공결탑 제나스" },
  { slot="LEGS", id=193706, ko="존경받는 교수의 경갑", dungeon="알게타르 대학" },
  { slot="FEET", id=251107, ko="서약신도 디딤장화", dungeon="마법학자의 정원" },
  { slot="FEET", id=251091, ko="격노한 복수의 발덮개", dungeon="윈드러너 첨탑" },
  { slot="FEET", id=251169, ko="불길한 운명의 발등싸개", dungeon="마이사라 동굴" },
  { slot="FEET", id=151330, ko="함정 방어 장화", dungeon="삼두정의 권좌" },
}
```

## 9. 쐐기 드랍 아이템 풀: 장신구

```lua
TRINKETS = {
  { id=250256, ko="바람의 심장", usableBy="ALL_PRIMARY", dungeon="윈드러너 첨탑" },
  { id=250242, ko="젤리 복제기", usableBy="AGILITY_STRENGTH", dungeon="마법학자의 정원" },
  { id=250226, ko="내장걸쇠의 뒤틀린 갈고리", usableBy="AGILITY_STRENGTH", dungeon="윈드러너 첨탑" },
  { id=250227, ko="크롤루크의 전쟁 깃발", usableBy="AGILITY_STRENGTH", dungeon="윈드러너 첨탑" },
  { id=193701, ko="알게타르 수수께끼 상자", usableBy="AGILITY_STRENGTH", dungeon="알게타르 대학" },
  { id=151307, ko="공허 추적자의 계약", usableBy="AGILITY_STRENGTH", dungeon="삼두정의 권좌" },
  { id=252420, ko="태양섬광 분광경", usableBy="AGILITY_STRENGTH", dungeon="하늘탑" },
  { id=252421, ko="썩어가는 방울", usableBy="TANK_AGILITY_STRENGTH", dungeon="사론의 구덩이" },
  { id=151312, ko="순수한 공허의 유리병", usableBy="TANK_AGILITY_STRENGTH", dungeon="삼두정의 권좌" },
  { id=252418, ko="태양 핵 점화자", usableBy="TANK_AGILITY_STRENGTH", dungeon="하늘탑" },
  { id=250257, ko="가라앉는 공허의 눈", usableBy="AGILITY_INTELLECT", dungeon="마법학자의 정원" },
  { id=250144, ko="잿불날개 깃털", usableBy="AGILITY_INTELLECT", dungeon="윈드러너 첨탑" },
  { id=250241, ko="빛의 징표", usableBy="STRENGTH", dungeon="공결탑 제나스" },
  { id=193719, ko="용 경기 장비", usableBy="STRENGTH", dungeon="알게타르 대학" },
  { id=250223, ko="영혼포획자의 부적", usableBy="INTELLECT", dungeon="마이사라 동굴" },
  { id=193718, ko="에메랄드 감독의 호루라기", usableBy="INTELLECT", dungeon="알게타르 대학" },
  { id=50259, ko="영구결빙 수정", usableBy="INTELLECT", dungeon="사론의 구덩이" },
  { id=151310, ko="현실 파괴 장치", usableBy="INTELLECT", dungeon="삼두정의 권좌" },
  { id=250246, ko="연료 보급의 보주", usableBy="HEALER_INTELLECT", dungeon="마법학자의 정원" },
  { id=250253, ko="어스름망령의 속삭임", usableBy="HEALER_INTELLECT", dungeon="공결탑 제나스" },
  { id=151340, ko="르우라의 메아리", usableBy="HEALER_INTELLECT", dungeon="삼두정의 권좌" },
  { id=252411, ko="광휘의 태양석", usableBy="HEALER_INTELLECT", dungeon="하늘탑" },
  { id=250258, ko="괴로워하는 영혼의 그릇", usableBy="MASTERY", dungeon="마이사라 동굴" },
}
```

## 10. 쐐기 드랍 아이템 풀: 무기/보조장비/방패

```lua
WEAPONS = {
  { type="AXE_1H", stat="AGILITY", id=251175, ko="영혼역병 가로날도끼", dungeon="마이사라 동굴" },
  { type="AXE_1H", stat="STRENGTH", id=251088, ko="전쟁으로 마모된 가로날도끼", dungeon="윈드러너 첨탑" },
  { type="DAGGER", stat="AGILITY", id=251212, ko="찬란한 분리검", dungeon="공결탑 제나스" },
  { type="DAGGER", stat="AGILITY", id=49807, ko="크리크의 딱정벌레 단도", dungeon="사론의 구덩이" },
  { type="DAGGER", stat="AGILITY", id=258436, ko="불타는 태양의 칼날", dungeon="하늘탑" },
  { type="DAGGER", stat="INTELLECT", id=251111, ko="갈라진 장막의 쐐기", dungeon="마법학자의 정원" },
  { type="DAGGER", stat="INTELLECT", id=251178, ko="의식용 사술칼날", dungeon="마이사라 동굴" },
  { type="DAGGER", stat="INTELLECT", id=50227, ko="외과의사의 바늘", dungeon="사론의 구덩이" },
  { type="FIST", stat="AGILITY", id=251163, ko="광전사의 사술발톱", dungeon="마이사라 동굴" },
  { type="FIST", stat="AGILITY", id=258524, ko="암흑 총독의 손아귀", dungeon="삼두정의 권좌" },
  { type="FIST", stat="AGILITY", id=258438, ko="타오르는 태양발톱", dungeon="하늘탑" },
  { type="FIST", stat="INTELLECT", id=110033, ko="대현자의 비전", dungeon="하늘탑" },
  { type="MACE_1H", stat="AGILITY", id=251207, ko="공포도리깨 곤봉", dungeon="공결탑 제나스" },
  { type="MACE_1H", stat="STRENGTH", id=251100, ko="악행의 나무망치", dungeon="마법학자의 정원" },
  { type="MACE_1H", stat="STRENGTH", id=258525, ko="끝없는 밤의 홀", dungeon="삼두정의 권좌" },
  { type="MACE_1H", stat="INTELLECT", id=251083, ko="발굴용 곤봉", dungeon="윈드러너 첨탑" },
  { type="SWORD_1H", stat="AGILITY", id=251122, ko="어둠칼날 절단기", dungeon="마법학자의 정원" },
  { type="SWORD_1H", stat="STRENGTH", id=193711, ko="주문파멸 커틀라스", dungeon="알게타르 대학" },
  { type="SWORD_1H", stat="STRENGTH", id=110032, ko="부리파괴자 시미터", dungeon="하늘탑" },
  { type="SWORD_1H", stat="INTELLECT", id=193710, ko="주문은총 사브르", dungeon="알게타르 대학" },
  { type="SWORD_1H", stat="INTELLECT", id=258218, ko="하늘파괴자의 칼날", dungeon="하늘탑" },
  { type="WARGLAIVE", stat="AGILITY_INTELLECT", id=251106, ko="결의의 룬글레이브", dungeon="마법학자의 정원" },
  { type="WARGLAIVE", stat="AGILITY_INTELLECT", id=193717, ko="미스타크리아의 수확기", dungeon="알게타르 대학" },
  { type="WAND", stat="INTELLECT", id=258516, ko="사프리쉬의 시선 마법봉", dungeon="삼두정의 권좌" },

  { type="AXE_2H", stat="STRENGTH", id=251117, ko="소용돌이 공허절단기", dungeon="마법학자의 정원" },
  { type="AXE_2H", stat="STRENGTH", id=193716, ko="알게타르 조경 도끼", dungeon="알게타르 대학" },
  { type="MACE_2H", stat="STRENGTH", id=49802, ko="가프로스트의 2톤 망치", dungeon="사론의 구덩이" },
  { type="POLEARM", stat="AGILITY", id=251162, ko="배신자의 갈퀴발톱", dungeon="마이사라 동굴" },
  { type="POLEARM", stat="AGILITY", id=258484, ko="비릭스의 태양창", dungeon="하늘탑" },
  { type="STAFF", stat="AGILITY", id=251077, ko="뿌리감시관의 가지", dungeon="윈드러너 첨탑" },
  { type="STAFF", stat="AGILITY", id=193723, ko="흑요석 골대지킴이 뾰족지팡이", dungeon="알게타르 대학" },
  { type="STAFF", stat="INTELLECT", id=251201, ko="핵심불꽃 다용도 도구", dungeon="공결탑 제나스" },
  { type="STAFF", stat="INTELLECT", id=193707, ko="최종 학점", dungeon="알게타르 대학" },
  { type="STAFF", stat="INTELLECT", id=258514, ko="주라알의 암영 뾰족지팡이", dungeon="삼두정의 권좌" },
  { type="STAFF", stat="INTELLECT", id=110031, ko="격노한 피조물의 척추", dungeon="하늘탑" },
  { type="SWORD_2H", stat="STRENGTH", id=251168, ko="생명 약탈자의 커틀라스", dungeon="마이사라 동굴" },
  { type="SWORD_2H", stat="STRENGTH", id=251078, ko="잿불여명 수호검", dungeon="윈드러너 첨탑" },
  { type="SWORD_2H", stat="STRENGTH", id=110030, ko="차크람 파괴자 대검", dungeon="하늘탑" },

  { type="BOW", stat="AGILITY", id=251174, ko="기만자의 부식활", dungeon="마이사라 동굴" },
  { type="BOW", stat="AGILITY", id=251095, ko="태풍의 심장", dungeon="윈드러너 첨탑" },
  { type="CROSSBOW", stat="AGILITY", id=258412, ko="폭풍구체자의 석궁", dungeon="하늘탑" },
  { type="GUN", stat="AGILITY", id=49813, ko="서리파멸 소총", dungeon="사론의 구덩이" },
  { type="OFF_HAND", stat="INTELLECT", id=193709, ko="벡사무스의 배출 마법봉", dungeon="알게타르 대학" },
  { type="OFF_HAND", stat="INTELLECT", id=258472, ko="루크란의 태양 성물함", dungeon="하늘탑" },
  { type="SHIELD", stat="INTELLECT_STRENGTH", id=251105, ko="주문파괴자의 수호물", dungeon="마법학자의 정원" },
  { type="SHIELD", stat="INTELLECT_STRENGTH", id=110034, ko="비릭스의 불굴의 보루 방패", dungeon="하늘탑" },
}
```

## 11. 애드온 로직 권장

```lua
-- 1) 해당 전문화의 armor/primary/role을 찾는다.
-- 2) TIER_SETS[spec.tierSetId]에서 5부위 중 4부위를 tier로 잠근다.
-- 3) 남는 tier slot 1개는 같은 armor pool의 M+ 오프피스와 비교한다.
-- 4) 목/반지/망토/장신구/무기는 ACCESSORIES/TRINKETS/WEAPONS에서 primary/role/type으로 필터한다.
-- 5) statHint는 절대 점수표가 아니라 기본 정렬 보조값이다. 실제 순위는 심크/QE 결과를 override 테이블로 보정한다.
```

## 12. 검증 로그

- 2026-05-30 KST: 빈 `pieces={}`였던 티어 세트 1979~1981, 1984~1989의 개별 조각명/Item ID/슬롯을 Wowhead 한국어 아이템 세트 페이지와 개별 아이템 페이지 기준으로 보강.
- 원칙: 한글명은 Wowhead 한국어에 노출된 문자열만 사용. 영어 원문 임의 번역 없음.
- `source` 필드는 애드온 내부 검증 추적용으로 추가. 실제 URL은 `https://www.wowhead.com/ko/item-set=<setId>` 또는 `https://www.wowhead.com/ko/item=<itemId>` 형식으로 조회 가능.

## 13. 주의사항

- 이 DB는 “정확한 한글명/ID 풀”을 우선한 자료다.
- 전문화별 최종 BiS는 아이템 레벨, 금고 보상, 촉매 충전, 장신구 너프/버프, 캐릭터 현재 스탯에 따라 달라진다.
- v0.2 기준 티어 5부위 조각명/Item ID는 전 직업 검증 완료. 이후 추가 항목도 한글명이 확인되지 않으면 절대 임의 번역하지 말고 빈값 또는 `검증필요`로 둔다.


## 13. v0.3 애드온용 BiS 판정 알고리즘 권장안

```lua
BIS_SCORING_POLICY = {
  tier4 = {
    required = true,
    sourceAllowed = { "GREAT_VAULT_DUNGEON", "CATALYST_FROM_MPLUS_ELIGIBLE_ITEM" },
    raidDropAllowed = false,
    rule = "HEAD/SHOULDERS/CHEST/HANDS/LEGS 중 4부위는 tierSetId와 itemId를 기준으로 세트 활성 여부를 먼저 판단한다."
  },
  itemTrack = {
    mythTrackCannotBeDeterminedByItemIdOnly = true,
    requiredRuntimeCheck = { "itemLink", "bonusIds", "itemLevel", "upgradeTrack" },
    rejectAsMythIfOnlyBaseItemId = true,
  },
  statScoring = {
    useSpecSecondaryOrder = true,
    preferTopTwoSecondaryStats = true,
    penalizeLowestSecondaryStat = true,
    breakpointSpecs = { "ROGUE_OUTLAW", "ROGUE_SUBTLETY", "SHAMAN_ELEMENTAL" },
  },
  trinkets = {
    doNotScoreBySecondaryStatsOnly = true,
    reason = "장신구는 효과 튜닝/쿨기 정렬/던전 패턴 영향이 커서 전문화별 가이드 또는 로그 기반 별도 테이블 필요."
  },
  validation = {
    koNameVerifiedColumn = "koNameVerified",
    statPriorityVerifiedColumn = "statPriorityVerified",
    bisOptimalVerifiedColumn = "bisOptimalVerified",
    defaultBisOptimalVerified = false,
  }
}
```

### 운영 규칙

| 규칙 | 설명 |
|---|---|
| `itemId`만으로 신화템 표시 금지 | 같은 기본 아이템도 Hero/Myth 트랙이 갈릴 수 있으므로 아이템 링크/보너스 ID 필요 |
| 쐐기 종료 보상과 금고 보상 분리 | +10 종료 보상은 Hero 트랙, +10 금고/보너스롤은 Myth 트랙으로 분리 |
| 티어는 스탯보다 우선 | 4셋 완성 전에는 티어 효과가 단순 2차 스탯보다 우선될 수 있음 |
| 최종 BiS 확정 플래그는 보수적으로 | 심크/QE/상위 로그 또는 전문화별 BiS 가이드에서 슬롯별로 일치할 때만 `bisOptimalVerified=true` |
| 한글명 미확인 시 출력 금지 | 영문명을 임의 번역하지 않고 `koNameVerified=false`, `ko=""` 처리 |



---

# v0.4 엄격 BiS 검증 레이어

> 목적: v0.3의 쐐기 드랍 풀/티어 DB 위에, 애드온에서 **최적화 BiS 여부를 안전하게 판정하기 위한 검증 컬럼과 런타임 평가 정책**을 추가한다.
> 중요한 결론: `itemId` 단독으로는 신화/영웅 트랙을 구분하지 않는다. `itemLink`, `bonusIds`, `itemLevel`, `upgradeTrack`를 같이 저장해야 한다.
> `bisOptimalVerified=true`는 **현행 전문화 가이드에서 해당 슬롯/아이템을 명시 추천했거나**, 사용자의 실제 캐릭터 기준 심크/Raidbots/QE/로그 검증이 끝난 경우에만 사용한다.

## v0.4 검증 상태 요약

| 검증 항목 | v0.4 상태 | 설명 |
|---|---|---|
| 한글명 정책 | 검증 엄격화 | Wowhead KO/공식 한글명만 사용. 영어 직역 금지 |
| 쐐기 드랍 풀 | 검증 완료 | v0.3의 Wowhead KO 시즌 1 쐐기 풀 유지 |
| 티어 4셋 | 검증 완료 | 위대한 금고 던전 슬롯/촉매 기준 포함 |
| 2차 스탯 우선도 | 검증 완료/문맥형 | 전 전문화에 `statPriorityVerified`, `statPriorityStatus` 유지 |
| 정적 최종 BiS | 기본 미확정 | 캐릭터별 심크/로그/가이드 명시 확인 없이는 `bisOptimalVerified=false` |
| Myth Track | 런타임 판정 필요 | `baseItemId`만으로 Myth Track 판정 금지 |

## Myth Track 저장 정책

```lua
MPLUS_MYTH_TRACK_POLICY_V04 = {
  baseItemIdIsDifficultySpecific = false,
  mplusEndOfDungeonPlus10 = { itemLevel=266, track="Hero", upgrade="3/6", mythTrack=false },
  mplusGreatVaultPlus10 = { itemLevel=272, track="Myth", upgrade="1/6", mythTrack=true },
  mplusBonusRollPlus10 = { itemLevel=272, track="Myth", upgrade="1/6", mythTrack=true },
  requiredRuntimeFields = { "baseItemId", "itemLink", "bonusIds", "itemLevel", "upgradeTrack", "upgradeRank", "sourceType", "slot", "stats" },
}
```

## 전문화별 최적화/검증 컬럼 v0.4

| specKey | 직업 | 전문화 | 역할 | 주스탯 | 2차 스탯 우선도 | 상태 | 스탯검증 | 쐐기풀검증 | 정적최종BiS | 검증 레벨 |
|---|---|---|---|---|---|---|---:|---:|---:|---|
| `DEATHKNIGHT_BLOOD` | 죽음의 기사 | 혈기 | TANK | 힘 | 아이템레벨/힘 우선, 가속·특화·유연성 균형 | `TANK_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `DEATHKNIGHT_FROST` | 죽음의 기사 | 냉기 | DPS | 힘 | 치명타 및 극대화 >= 특화 >> 가속 > 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `DEATHKNIGHT_UNHOLY` | 죽음의 기사 | 부정 | DPS | 힘 | 치명타 및 극대화 >= 특화 >> 가속 >= 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `DEMONHUNTER_DEVOURER` | 악마사냥꾼 | 포식 | DPS | 지능 | 특화 >= 가속 > 치명타 및 극대화 >>> 유연성 | `CORRECTED_V02_PRIMARY_STAT` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `DEMONHUNTER_HAVOC` | 악마사냥꾼 | 파멸 | DPS | 민첩 | 치명타 및 극대화 > 특화 >> 가속 > 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `DEMONHUNTER_VENGEANCE` | 악마사냥꾼 | 복수 | TANK | 민첩 | 아이템레벨 >>> 가속 >= 유연성 >= 치명타 및 극대화 > 특화 | `TANK_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `DRUID_BALANCE` | 드루이드 | 조화 | DPS | 지능 | 특화 > 치명타 및 극대화 = 가속 >> 유연성 | `CORRECTED_V02_STAT_PRIORITY` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `DRUID_FERAL` | 드루이드 | 야성 | DPS | 민첩 | 특화 > 가속 > 치명타 및 극대화 > 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `DRUID_GUARDIAN` | 드루이드 | 수호 | TANK | 민첩 | 아이템레벨/민첩 우선, 가속 > 유연성 > 특화 = 치명타 및 극대화 | `TANK_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `DRUID_RESTO` | 드루이드 | 회복 | HEALER | 지능 | 특화 = 가속 >= 유연성 >> 치명타 및 극대화 | `HEALER_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `EVOKER_DEVASTATION` | 기원사 | 황폐 | DPS | 지능 | 치명타 및 극대화 > 가속 = 특화 > 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `EVOKER_PRESERVATION` | 기원사 | 보존 | HEALER | 지능 | 특화 > 치명타 및 극대화 >= 가속 >> 유연성 | `HEALER_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `EVOKER_AUGMENTATION` | 기원사 | 증강 | DPS | 지능 | 치명타 및 극대화 > 가속 > 특화 > 유연성 | `CORRECTED_V02_STAT_PRIORITY` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `HUNTER_BM` | 사냥꾼 | 야수 | DPS | 민첩 | 무기 공격력/민첩 우선, 일반: 특화 > 가속 > 치명타 및 극대화 > 유연성 | `CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `HUNTER_MARKSMAN` | 사냥꾼 | 사격 | DPS | 민첩 | 치명타 및 극대화 >>> 특화 > 가속 > 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `HUNTER_SURVIVAL` | 사냥꾼 | 생존 | DPS | 민첩 | 특화 > 치명타 및 극대화 = 가속 > 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `MAGE_ARCANE` | 마법사 | 비전 | DPS | 지능 | 특화 > 가속 >= 치명타 및 극대화 >> 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `MAGE_FIRE` | 마법사 | 화염 | DPS | 지능 | 가속 >= 특화 > 유연성 >> 치명타 및 극대화 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `MAGE_FROST` | 마법사 | 냉기 | DPS | 지능 | 특화 >= 치명타 및 극대화 >> 가속 >= 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `MONK_BREWMASTER` | 수도사 | 양조 | TANK | 민첩 | 아이템레벨 우선, 동일 템렙: 치명타 및 극대화 = 유연성 = 특화 > 가속 | `TANK_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `MONK_MISTWEAVER` | 수도사 | 운무 | HEALER | 지능 | 가속 > 치명타 및 극대화 > 유연성 >> 특화 | `HEALER_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `MONK_WINDWALKER` | 수도사 | 풍운 | DPS | 민첩 | 가속 = 치명타 및 극대화 = 특화 >>> 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `PALADIN_HOLY` | 성기사 | 신성 | HEALER | 지능 | 지능 우선, 특화 > 가속 = 치명타 및 극대화 > 유연성 | `HEALER_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `PALADIN_PROTECTION` | 성기사 | 보호 | TANK | 힘 | 가속 > 유연성 = 치명타 및 극대화 > 특화 | `TANK_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `PALADIN_RETRIBUTION` | 성기사 | 징벌 | DPS | 힘 | 특화 > 치명타 및 극대화 > 가속 > 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `PRIEST_DISC` | 사제 | 수양 | HEALER | 지능 | 가속 > 치명타 및 극대화 > 특화 > 유연성 | `HEALER_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `PRIEST_HOLY` | 사제 | 신성 | HEALER | 지능 | 쐐기 기준: 가속 > 유연성 = 치명타 및 극대화 > 특화 | `EXTERNAL_MPLUS_CROSSCHECK` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `PRIEST_SHADOW` | 사제 | 암흑 | DPS | 지능 | 가속 > 특화 > 치명타 및 극대화 > 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `ROGUE_ASSASSINATION` | 도적 | 암살 | DPS | 민첩 | 치명타 및 극대화 > 가속 > 특화 > 유연성 | `CORRECTED_V02_STAT_PRIORITY` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `ROGUE_OUTLAW` | 도적 | 무법 | DPS | 민첩 | 가속 21~23% 근처까지 우선, 이후 치명타 및 극대화 >= 유연성 > 특화 | `BREAKPOINT_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `ROGUE_SUBTLETY` | 도적 | 잠행 | DPS | 민첩 | 특화 > 가속 구간값 >= 치명타 및 극대화 >> 유연성 | `BREAKPOINT_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `SHAMAN_ELEMENTAL` | 주술사 | 정기 | DPS | 지능 | 특화 목표치 우선 → 가속 = 치명타 및 극대화 >> 유연성 | `BREAKPOINT_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `SHAMAN_ENHANCEMENT` | 주술사 | 고양 | DPS | 민첩 | 특화 > 가속 > 치명타 및 극대화 > 유연성 | `CORRECTED_V02_STAT_PRIORITY` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `SHAMAN_RESTORATION` | 주술사 | 복원 | HEALER | 지능 | 치명타 및 극대화 > 특화 = 유연성 > 가속 | `HEALER_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `WARLOCK_AFFLICTION` | 흑마법사 | 고통 | DPS | 지능 | 특화 = 치명타 및 극대화 > 가속 > 유연성 | `CORRECTED_V02_STAT_PRIORITY` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `WARLOCK_DEMONOLOGY` | 흑마법사 | 악마 | DPS | 지능 | 가속 = 치명타 및 극대화 > 특화 > 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `WARLOCK_DESTRUCTION` | 흑마법사 | 파괴 | DPS | 지능 | 가속 > 특화 = 치명타 및 극대화 > 유연성 | `CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `WARRIOR_ARMS` | 전사 | 무기 | DPS | 힘 | 치명타 및 극대화 >= 가속 > 특화 > 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `WARRIOR_FURY` | 전사 | 분노 | DPS | 힘 | 가속 >= 특화 > 치명타 및 극대화 = 유연성 | `VERIFIED` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |
| `WARRIOR_PROTECTION` | 전사 | 방어 | TANK | 힘 | 가속 > 유연성 = 치명타 및 극대화 > 특화 | `TANK_CONTEXTUAL` | ✅ | ✅ | ❌ | `STRICT_STATIC_DB_CANNOT_CERTIFY_FINAL_BIS__RUNTIME_SIM_REQUIRED` |

## 애드온 판정 권장 로직

```lua
-- 1. 아이템이 티어면 4셋 유지 여부를 먼저 본다.
-- 2. 쐐기/금고/보너스롤 출처면 itemLink의 bonusIds/upgradeTrack로 Myth Track 여부를 판정한다.
-- 3. 일반 방어구/목/반지/망토는 전문화별 secondaryWeights로 점수화한다.
-- 4. 무기와 장신구는 단순 2차 스탯 점수만으로 최종 BiS 처리하지 않는다.
-- 5. bisOptimalVerified=true는 현행 가이드 명시 추천 또는 캐릭터별 심크/QE/로그 검증 후에만 세팅한다.
```

## 냉기 마법사 검증 예시

냉법은 v0.4 기준으로 `secondaryPriority="특화 >= 치명타 및 극대화 >> 가속 >= 유연성"`이며, 비티어 방어구/목/반지/망토 후보는 **특화 + 치명타 및 극대화** 조합을 최우선으로 점수화한다. 단, Wowhead 냉법 가이드도 지능/아이템레벨과 개인 심크를 함께 보라고 명시하므로, 단순히 특화/치명 아이템이라고 해서 모든 캐릭터에서 `bisOptimalVerified=true`가 되지는 않는다.

## v0.4 산출물

- `MidnightS1_MPlus_DB_patch_v0.4.lua`: 애드온용 검증 정책/스탯 가중치/런타임 평가 함수
- `MidnightS1_MPlus_BiS_Validation_v0.4.json`: 외부 도구/생성 파이프라인용 JSON



---

# v0.5 추가: Myth Track itemLink 필수 정책 / 아이템 레벨·스탯 산정 정책 / 애드온 사용법

> v0.5 핵심 변경: `itemId`만으로 신화/영웅을 구분하지 않는다. 애드온은 반드시 실제 `itemLink`를 저장하고, 그 링크에서 `bonusIds`, 실제 아이템 레벨, 업그레이드 트랙, 실제 스탯을 읽어야 한다.

## 0.5.1 Myth Track itemLink 정책

```lua
MPLUS_MYTHIC_ITEMLINK_POLICY_V05 = {
  baseItemIdIsDifficultySpecific = false,
  baseItemIdMeaning = "itemId는 기본 아이템 템플릿 ID다. Myth/Hero/Champion 트랙 판정값이 아니다.",
  mythicItemLinkRequired = true,
  mythicItemLinkMustBeRuntimeCaptured = true,
  neverInventBonusIds = true,
  neverBuildMythicLinkByGuessing = true,
  validMythicEvidence = {
    "itemLink에서 추출한 bonusIds",
    "C_Item.GetDetailedItemLevelInfo(itemLink)의 actualItemLevel",
    "툴팁 또는 업그레이드 API에서 확인한 업그레이드 트랙: 신화/Myth",
    "획득 출처: 위대한 금고 던전 슬롯 또는 성운의 공허핵/보너스롤 등 해당 단수의 금고 보상과 동일한 보상",
  },
  warning = "Hero 5/6 등 업그레이드된 Hero 장비가 Myth 1/6과 같은 아이템 레벨에 도달할 수 있으므로, itemLevel만으로 Myth Track으로 판정하면 안 된다.",
}
```

### 저장 필드 권장안

```lua
ITEM_RECORD_SCHEMA_V05 = {
  baseItemId = "number",           -- Wowhead item=ID 기준 기본 ID
  ko = "string",                   -- 검증된 한글명
  slot = "string",
  dungeonKo = "string|nil",
  sourceType = "MPLUS_END|GREAT_VAULT_DUNGEON|BONUS_ROLL|CATALYST|UNKNOWN",

  -- Myth Track 판정에 필요한 런타임 필드
  itemLink = "string|nil",         -- 실제 링크. 반드시 전체 bonusId 포함 링크여야 함
  itemString = "string|nil",       -- item:... 원문
  bonusIds = "table|nil",
  actualItemLevel = "number|nil",
  sparseItemLevel = "number|nil",
  upgradeTrack = "string|nil",     -- 예: 신화 / Myth / Hero. API 또는 툴팁 스캔
  upgradeRank = "string|nil",      -- 예: 1/6
  mythTrackVerified = "boolean",   -- itemId 단독으로 true 금지
  mythTrackEvidence = "table",

  -- 스탯 판정
  stats = "table|nil",             -- C_Item.GetItemStats(itemLink) 결과
  statScore = "number|nil",
  specScore = "number|nil",
  bisOptimalVerified = "boolean",  -- 심크/QE/로그/현행 가이드 확인 전까지 false
}
```

## 0.5.2 한밤 시즌 1 쐐기 단수별 보상 테이블

> 아래 표는 v0.5의 기준 테이블이다. 실제 애드온에서는 획득한 아이템의 `itemLink`를 기준으로 최종 검증한다.

| 쐐기 단수 | 던전 종료 보상 | 종료 트랙 | 위대한 금고 | 금고 트랙 | 비고 |
|---:|---:|---|---:|---|---|
| +2 | 250 | Champion 2/6 | 259 | Hero 1/6 | 금고 1칸: 1회 완료 |
| +3 | 250 | Champion 2/6 | 259 | Hero 1/6 |  |
| +4 | 253 | Champion 3/6 | 263 | Hero 2/6 |  |
| +5 | 256 | Champion 4/6 | 263 | Hero 2/6 |  |
| +6 | 259 | Hero 1/6 | 266 | Hero 3/6 |  |
| +7 | 259 | Hero 1/6 | 269 | Hero 4/6 |  |
| +8 | 263 | Hero 2/6 | 269 | Hero 4/6 |  |
| +9 | 263 | Hero 2/6 | 269 | Hero 4/6 | 신화 여명문장 구간 |
| +10 이상 | 266 | Hero 3/6 | 272 | Myth 1/6 | Myth Track 금고 기준점 |

## 0.5.3 아이템 레벨 상승 시 스탯 산정 원칙

정확한 결론: **애드온에서 직접 수식으로 재계산하지 말고, 클라이언트가 계산한 실제 값을 읽어야 한다.**

WoW 장비 스탯은 단순히 `itemId`와 `itemLevel`만으로 고정 계산되는 값이 아니다. 아이템 링크 안의 bonus ID, 업그레이드 트랙, 소켓/부가 효과, 슬롯, 무기/방어구 유형, 장신구 효과 등에 따라 최종 툴팁 값이 달라진다. 따라서 v0.5의 공식은 아래처럼 정의한다.

```lua
-- authoritative formula for addon use
actualItemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
stats = C_Item.GetItemStats(itemLink)

-- specialization scoring formula
statScore = 0
for statName, statValue in pairs(stats or {}) do
  statScore = statScore + statValue * GetSpecStatWeight(specKey, statName)
end

specScore = statScore
          + GetItemLevelWeight(specKey, slot) * actualItemLevel
          + GetTierSetBonusScore(specKey, itemLink)
          + GetTrinketOrWeaponEffectScore(specKey, itemLink)
```

### 비교/검증용 성장률 계산

같은 기본 아이템의 서로 다른 링크가 있을 때만 성장률을 계산한다.

```lua
statGrowthRatio = statsAtHigherIlvl[statName] / statsAtLowerIlvl[statName]
statDelta = statsAtHigherIlvl[statName] - statsAtLowerIlvl[statName]
```

주의: 이 성장률은 “해당 아이템/해당 스탯/해당 두 링크 사이의 관측값”일 뿐, 모든 아이템에 동일하게 적용되는 보편 공식으로 쓰면 안 된다.

## 0.5.4 애드온 파일 사용법

### 1) `MidnightS1_MPlus_Verified_DB_v0.5.md`

문서형 기준 DB다. 사람이 검토하는 원본 문서로 사용한다. 애드온 런타임에서 직접 읽기보다는, 아래 Lua/JSON을 생성하는 기준 문서로 둔다.

### 2) `MidnightS1_MPlus_DB_patch_v0.5.lua`

애드온에 직접 포함할 Lua 패치 파일이다.

`.toc` 예시:

```toc
## Interface: 120005
## Title: Midnight S1 M+ BIS Helper
## SavedVariables: MidnightS1DBSaved
Data/MidnightS1_MPlus_DB_patch_v0.5.lua
Core.lua
```

애드온 로딩 시 아래 순서로 사용한다.

```lua
-- 1. 정적 DB 로드
local specPolicy = SPEC_OPTIMIZATION_POLICY_V05[specKey]

-- 2. 장비 링크 수집
local link = GetInventoryItemLink("player", slotId)

-- 3. 실제 아이템 정보 계산
local info = MS1V05_BuildRuntimeItemRecord(link, specKey, sourceType)

-- 4. Myth Track 검증
if info.mythTrackVerified then
  -- 신화 트랙으로 인정
end

-- 5. 전문화별 스탯 점수 계산
local score = MS1V05_ScoreItemForSpec(info, specKey)
```

### 3) `MidnightS1_MPlus_BiS_Validation_v0.5.json`

외부 파이프라인용이다. 예를 들어 Node/Python으로 Wowhead 검증, 심크 결과 병합, Lua 테이블 자동생성에 사용한다. WoW 애드온은 기본적으로 JSON 파서가 없으므로 런타임에서는 Lua 파일을 쓰는 편이 안전하다.

## 0.5.5 런타임 수집 예시 코드

```lua
local function MS1V05_GetItemString(itemLink)
  if not itemLink then return nil end
  return itemLink:match("item[%-?%d:]+")
end

local function MS1V05_ParseBonusIds(itemLink)
  local itemString = MS1V05_GetItemString(itemLink)
  if not itemString then return {} end
  local parts = { strsplit(":", itemString) }
  -- itemString 포맷상 bonusId 개수와 위치는 클라이언트 버전에 따라 해석 보정이 필요하다.
  -- v0.5에서는 bonusIds 원문 저장 + actualItemLevel/API 검증을 병행한다.
  return parts
end

function MS1V05_BuildRuntimeItemRecord(itemLink, specKey, sourceType)
  if not itemLink then return nil end

  local actualItemLevel, previewLevel, sparseItemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
  local stats = C_Item.GetItemStats(itemLink)
  local itemString = MS1V05_GetItemString(itemLink)
  local itemId = tonumber(itemString and itemString:match("item:(%-?%d+)"))

  local record = {
    baseItemId = itemId,
    itemLink = itemLink,
    itemString = itemString,
    bonusIdsRaw = MS1V05_ParseBonusIds(itemLink),
    actualItemLevel = actualItemLevel,
    sparseItemLevel = sparseItemLevel,
    sourceType = sourceType or "UNKNOWN",
    stats = stats,
    mythTrackVerified = false,
    mythTrackEvidence = {},
  }

  -- itemLevel만으로 Myth 판정 금지. 다만 +10 금고/보너스롤로 들어온 272+ 링크는 후보로 표시.
  if (sourceType == "GREAT_VAULT_DUNGEON" or sourceType == "BONUS_ROLL") and actualItemLevel and actualItemLevel >= 272 then
    record.mythTrackCandidate = true
    table.insert(record.mythTrackEvidence, "sourceType=" .. sourceType)
    table.insert(record.mythTrackEvidence, "actualItemLevel=" .. tostring(actualItemLevel))
  end

  return record
end
```

## 0.5.6 주의: Myth Track 판정은 2단계로 한다

| 단계 | 판정 | 이유 |
|---|---|---|
| 1차 | `mythTrackCandidate=true` | +10 이상 금고/보너스롤 + 272 이상 등 후보 조건 |
| 2차 | `mythTrackVerified=true` | 툴팁/업그레이드 트랙/API/bonusId까지 확인한 확정 조건 |

`actualItemLevel=272`만으로는 확정하지 않는다. Hero 트랙 업그레이드 장비와 같은 레벨 구간이 겹칠 수 있기 때문이다.

## 0.5.7 추천 구현 구조

```text
Addon/
  MidnightS1BIS.toc
  Core.lua
  Scoring.lua
  TooltipScanner.lua
  Data/
    MidnightS1_MPlus_DB_patch_v0.5.lua
  Tools/
    MidnightS1_MPlus_BiS_Validation_v0.5.json
```

- `Core.lua`: 이벤트, 캐릭터 전문화, 장비 스캔
- `Scoring.lua`: 전문화별 스탯 점수/티어/장신구 보정
- `TooltipScanner.lua`: 업그레이드 트랙 텍스트 확인. 예: 신화, Myth, Hero
- `Data/*.lua`: 검증된 정적 DB와 정책
- `Tools/*.json`: 외부 검증/재생성 파이프라인용


---

# v1.0 최종 병합 운영 가이드

## 왜 v1.0은 2개 파일만 제공하는가

기존 v0.5는 `MD / Lua / JSON` 세 파일 구조였다. 애드온 제작 단계에서는 파일이 많아질수록 동기화 오류가 생기기 쉬우므로 v1.0은 다음 두 개로 병합했다.

| 파일 | 용도 | 애드온에 직접 포함 |
|---|---|---:|
| `MidnightS1_MPlus_Addon_DB_v1.0.lua` | 실제 애드온 로드용 단일 DB + 런타임 검증 함수 + 프롬프트 내장 | 예 |
| `MidnightS1_MPlus_Addon_Master_v1.0.md` | 사람이 보는 설계 문서, 검증 원칙, 유지보수 프롬프트, 기존 DB 설명 | 아니오 |

JSON은 별도 파일로 유지하지 않았다. 외부 파이프라인이 필요하면 Lua의 `DB.PROMPTS`와 테이블을 기준으로 다시 생성하는 편이 안전하다.

## 애드온 로드 예시

```toc
## Interface: 120005
## Title: Midnight S1 M+ BIS Helper
## SavedVariables: MidnightS1DBSaved

Data/MidnightS1_MPlus_Addon_DB_v1.0.lua
Core.lua
TooltipScanner.lua
Scoring.lua
```

## 런타임 사용 예시

```lua
local DB = MidnightS1MPlusDB
local slotId = 16 -- main hand 예시
local itemLink = GetInventoryItemLink("player", slotId)

local record = DB.BuildRuntimeItemRecord(
  itemLink,
  "MAGE_FROST",
  "GREAT_VAULT_DUNGEON",
  10,
  "MAIN_HAND"
)

-- 툴팁 스캐너가 "신화 1/6" 같은 텍스트를 확인한 뒤 호출
DB.MarkMythTrackVerified(record, "신화 1/6")

local score = DB.ScoreItemForSpec(record, "MAGE_FROST")
local verification = DB.GetStaticVerification("MAGE_FROST", record)
```

## UI 표시 권장 문구

| 상태 | UI 표기 |
|---|---|
| `mythTrackVerified=true` | 신화 트랙 확인됨 |
| `mythTrackCandidate=true` but not verified | 신화 후보: 툴팁 확인 필요 |
| `bisOptimalVerified=false` | 최종 BiS 확정 아님: 심크/QE 필요 |
| `statPriorityVerified=true` | 전문화 스탯 우선도 검증됨 |
| `koNamePolicy` 정상 | 공식/검증 한글명 사용 |

## 아이템 레벨 상승과 스탯 산정 원칙

애드온에서 아이템 레벨별 2차 스탯을 직접 수식으로 재계산하지 않는다. 같은 `itemId`라도 `itemLink`의 bonus ID, 업그레이드 트랙, 아이템 레벨에 따라 실제 스탯이 달라질 수 있다. 따라서 실제 비교는 항상 다음 순서로 수행한다.

```lua
local effectiveILvl, isPreview, baseILvl = C_Item.GetDetailedItemLevelInfo(itemLink)
local rawStats = C_Item.GetItemStats(itemLink)
```

그 뒤 `DB.NormalizeStats(rawStats)`와 `DB.ScoreItemForSpec(record, specKey)`를 사용한다.

## 유지보수 프롬프트

아래 프롬프트는 이후 DB 업데이트, 한글명 검증, BiS 후보 검토용으로 그대로 사용할 수 있다.

### 1) 한글명/아이템ID 검증 프롬프트

```text
너는 World of Warcraft 한밤 시즌 1 / 12.0.5 쐐기 장비 DB 검증 에이전트다.
반드시 공식 한글 클라이언트 표기, Wowhead 한국어 페이지, Blizzard 공식 문서 중 하나로 한글명/아이템ID/던전명을 확인한다.
영문명을 직접 번역하지 않는다. 확인되지 않은 한글명은 ko="검증 필요"로 남긴다.
itemId만으로 Hero/Myth 트랙을 판단하지 않는다. 실제 itemLink, bonusIds, actualItemLevel, upgradeTrackText, sourceType을 함께 기록한다.
최종 BiS는 staticFinalBisVerified=true로 두지 않는다. 현행 가이드 명시, SimC/Raidbots/QE/로그 검증이 있을 때만 true로 바꾼다.
```

### 2) 애드온 구현 프롬프트

```text
이 Lua DB를 사용해 애드온을 구현하라.
1) 플레이어 장비의 실제 itemLink를 GetInventoryItemLink로 수집한다.
2) DB.BuildRuntimeItemRecord(itemLink, specKey, sourceType, keyLevel, slot)로 런타임 레코드를 만든다.
3) 툴팁 또는 API에서 신화/Myth 업그레이드 트랙 텍스트가 확인될 때만 DB.MarkMythTrackVerified(record, text)를 호출한다.
4) DB.ScoreItemForSpec(record, specKey)로 2차 스탯 점수를 계산한다.
5) 티어 4셋, 장신구 효과, 무기 DPS, 심크/QE 결과는 별도 가중치로 보정한다.
6) UI에는 '검증된 후보', '신화 후보', '신화 검증 완료', '최종 BiS 아님/심크 필요'를 분리해서 표시한다.
```

### 3) 전문화별 BiS 후보 리뷰 프롬프트

```text
전문화별 슬롯 BiS 후보를 검토하라.
입력: specKey, 실제 itemLink 목록, 각 itemLink의 actualItemLevel/stats/upgradeTrack/sourceType.
출력: 슬롯별 추천 후보, 점수 근거, 티어 4셋 유지 여부, 신화 트랙 검증 여부, 최종 BiS 확정 여부.
주의: 2차 스탯 점수만으로 장신구/무기/티어를 최종 확정하지 말고, SimC/Raidbots/QE/로그 검증 필요 여부를 명시한다.
```

## 절대 금지 사항

1. 영문 아이템명/던전명을 한국어로 직접 번역해서 `ko` 필드에 넣지 않는다.
2. `itemId`만 보고 신화템으로 표시하지 않는다.
3. +10 종료 보상을 Myth Track으로 표시하지 않는다.
4. 정적 스탯 우선도만으로 장신구/무기/티어를 최종 BiS 확정하지 않는다.
5. 확인되지 않은 한글명에 `verified=true`를 붙이지 않는다.
