--[[
MidnightS1_MPlus_Addon_DB_v1.7.lua
World of Warcraft: 한밤 시즌 1 / 12.0.5
목적: 다른 애드온이 바로 참조할 수 있는 컴팩트 장비 점수화 코어 DB.

검증/운영 원칙
1. 한글명은 공식 한글 클라이언트, Blizzard KO 문서, Wowhead KO 개별 페이지 기준만 허용한다.
2. 영어명 임의 번역 금지. 미검증 한글명은 저장하지 않는다.
3. itemId는 기본 아이템 ID다. 쐐기 금고/종료/레이드 난이도/업그레이드 트랙은 itemId만으로 판정하지 않는다.
4. 실제 점수는 itemLink 기반으로 계산한다.
   - 실제 아이템 레벨: GetDetailedItemLevelInfo(itemLink)
   - 실제 스탯: C_Item.GetItemStats(itemLink)
5. '영웅/신화'는 쐐기 자체가 아니라 업그레이드 트랙 또는 레이드 난이도 표기다.
   UI에는 '쐐기 종료 보상', '쐐기 금고 보상', '레이드 영웅', '레이드 신화'처럼 출처를 분리해 표시한다.
6. 최종 BiS 확정은 이 파일의 스탯 점수 + 티어 4셋 + 장신구/무기 특수효과 + SimC/QE/로그 검증을 함께 사용한다.

주요 공개 API
- DB.GetSpecProfile(specKey)
- DB.NormalizeStats(rawStats)
- DB.BuildRuntimeItemRecord(itemLink, specKey, sourceType, options, slot)
- DB.ScoreItemRecord(record, specKey, slot)
- DB.SortItemLinks(specKey, slot, itemLinks, sourceType, options)
- DB.GetMPlusRewardInfo(keyLevel, sourceType)
- DB.RunSelfCheck()
]]--

local ADDON_NAME = ...
_G.MidnightS1MPlusDB = _G.MidnightS1MPlusDB or {}
local DB = _G.MidnightS1MPlusDB

DB.schemaVersion = "1.7"
DB.patch = "12.0.5"
DB.seasonKo = "한밤 시즌 1"
DB.generatedAtKST = "2026-06-01"
DB.localePolicy = "KO_VERIFIED_ONLY__NO_AD_HOC_TRANSLATION"

DB.SOURCE_TYPES = {
  MPLUS_END_DUNGEON = { ko="쐐기 종료 보상", group="MPLUS", needsKeyLevel=true },
  MPLUS_GREAT_VAULT = { ko="쐐기 금고 보상", group="MPLUS", needsKeyLevel=true },
  MPLUS_BONUS_ROLL = { ko="쐐기 보너스 굴림", group="MPLUS", needsKeyLevel=true },
  RAID_LFR = { ko="레이드 공격대 찾기", group="RAID" },
  RAID_NORMAL = { ko="레이드 일반", group="RAID" },
  RAID_HEROIC = { ko="레이드 영웅", group="RAID" },
  RAID_MYTHIC = { ko="레이드 신화", group="RAID" },
  CATALYST = { ko="촉매 변환", group="CATALYST" },
  UNKNOWN = { ko="출처 미확인", group="UNKNOWN" },
}

-- 한밤 시즌 1 쐐기 보상표. +10 이상은 금고/보너스 굴림에서 신화 1/6 후보.
DB.MPLUS_REWARDS = {
  [2]  = { endItemLevel=250, endTrackKo="용사 2/6", vaultItemLevel=259, vaultTrackKo="영웅 1/6" },
  [3]  = { endItemLevel=250, endTrackKo="용사 2/6", vaultItemLevel=259, vaultTrackKo="영웅 1/6" },
  [4]  = { endItemLevel=253, endTrackKo="용사 3/6", vaultItemLevel=263, vaultTrackKo="영웅 2/6" },
  [5]  = { endItemLevel=256, endTrackKo="용사 4/6", vaultItemLevel=263, vaultTrackKo="영웅 2/6" },
  [6]  = { endItemLevel=259, endTrackKo="영웅 1/6", vaultItemLevel=266, vaultTrackKo="영웅 3/6" },
  [7]  = { endItemLevel=259, endTrackKo="영웅 1/6", vaultItemLevel=269, vaultTrackKo="영웅 4/6" },
  [8]  = { endItemLevel=263, endTrackKo="영웅 2/6", vaultItemLevel=269, vaultTrackKo="영웅 4/6" },
  [9]  = { endItemLevel=263, endTrackKo="영웅 2/6", vaultItemLevel=269, vaultTrackKo="영웅 4/6" },
  [10] = { endItemLevel=266, endTrackKo="영웅 3/6", vaultItemLevel=272, vaultTrackKo="신화 1/6" },
}

DB.DUNGEONS = {
  MAGISTERS_TERRACE = { ko="마법학자의 정원", en="Magisters' Terrace" },
  MAISARA_CAVERNS = { ko="마이사라 동굴", en="Maisara Caverns" },
  NEXUS_POINT_XENAS = { ko="공결탑 제나스", en="Nexus-Point Xenas" },
  WINDRUNNER_SPIRE = { ko="윈드러너 첨탑", en="Windrunner Spire" },
  ALGETHAR_ACADEMY = { ko="알게타르 대학", en="Algeth'ar Academy" },
  SEAT_OF_THE_TRIUMVIRATE = { ko="삼두정의 권좌", en="Seat of the Triumvirate" },
  SKYREACH = { ko="하늘탑", en="Skyreach" },
  PIT_OF_SARON = { ko="사론의 구덩이", en="Pit of Saron" },
}

-- C_Item.GetItemStats() raw token -> 내부 한글 canonical stat.
DB.STAT_TOKEN_MAP = {
  ITEM_MOD_CRIT_RATING_SHORT = "치명타 및 극대화",
  ITEM_MOD_CRIT_RATING = "치명타 및 극대화",
  ITEM_MOD_CRITICAL_STRIKE_RATING_SHORT = "치명타 및 극대화",
  ITEM_MOD_HASTE_RATING_SHORT = "가속",
  ITEM_MOD_HASTE_RATING = "가속",
  ITEM_MOD_SPELL_HASTE_RATING_SHORT = "가속",
  ITEM_MOD_MASTERY_RATING_SHORT = "특화",
  ITEM_MOD_MASTERY_RATING = "특화",
  ITEM_MOD_VERSATILITY = "유연성",
  ITEM_MOD_VERSATILITY_SHORT = "유연성",
  ITEM_MOD_STRENGTH_SHORT = "힘",
  ITEM_MOD_STRENGTH = "힘",
  ITEM_MOD_AGILITY_SHORT = "민첩",
  ITEM_MOD_AGILITY = "민첩",
  ITEM_MOD_INTELLECT_SHORT = "지능",
  ITEM_MOD_INTELLECT = "지능",
  ITEM_MOD_STAMINA_SHORT = "체력",
  ITEM_MOD_STAMINA = "체력",
}

-- 단일 대표 스탯 우선순위. 사용자가 직접 선택한 값은 source="USER_SELECTED".
DB.SPECS = {
  DEATHKNIGHT_BLOOD = { classKo="죽음의 기사", specKo="혈기", role="TANK", armor="PLATE", primary="힘", priority="치명타 및 극대화 > 가속 > 유연성 = 특화", weights={ ["치명타 및 극대화"]=100, ["가속"]=85, ["유연성"]=75, ["특화"]=75 }, source="USER_SELECTED" },
  DEATHKNIGHT_FROST = { classKo="죽음의 기사", specKo="냉기", role="DPS", armor="PLATE", primary="힘", priority="치명타 및 극대화 >= 특화 >> 가속 > 유연성", weights={ ["치명타 및 극대화"]=100, ["특화"]=95, ["가속"]=65, ["유연성"]=45 } },
  DEATHKNIGHT_UNHOLY = { classKo="죽음의 기사", specKo="부정", role="DPS", armor="PLATE", primary="힘", priority="치명타 및 극대화 >= 특화 >> 가속 >= 유연성", weights={ ["치명타 및 극대화"]=100, ["특화"]=95, ["가속"]=65, ["유연성"]=60 } },

  DEMONHUNTER_DEVOURER = { classKo="악마사냥꾼", specKo="포식", role="DPS", armor="LEATHER", primary="지능", priority="특화 > 가속 > 치명타 및 극대화 >>> 유연성", weights={ ["특화"]=100, ["가속"]=85, ["치명타 및 극대화"]=70, ["유연성"]=35 } },
  DEMONHUNTER_HAVOC = { classKo="악마사냥꾼", specKo="파멸", role="DPS", armor="LEATHER", primary="민첩", priority="치명타 및 극대화 > 특화 >> 가속 > 유연성", weights={ ["치명타 및 극대화"]=100, ["특화"]=85, ["가속"]=60, ["유연성"]=40 } },
  DEMONHUNTER_VENGEANCE = { classKo="악마사냥꾼", specKo="복수", role="TANK", armor="LEATHER", primary="민첩", priority="가속 >= 유연성 >= 치명타 및 극대화 > 특화", weights={ ["가속"]=100, ["유연성"]=90, ["치명타 및 극대화"]=80, ["특화"]=55 } },

  DRUID_BALANCE = { classKo="드루이드", specKo="조화", role="DPS", armor="LEATHER", primary="지능", priority="특화 > 치명타 및 극대화 = 가속 >> 유연성", weights={ ["특화"]=100, ["치명타 및 극대화"]=85, ["가속"]=85, ["유연성"]=45 } },
  DRUID_FERAL = { classKo="드루이드", specKo="야성", role="DPS", armor="LEATHER", primary="민첩", priority="특화 > 가속 > 치명타 및 극대화 > 유연성", weights={ ["특화"]=100, ["가속"]=85, ["치명타 및 극대화"]=70, ["유연성"]=45 } },
  DRUID_GUARDIAN = { classKo="드루이드", specKo="수호", role="TANK", armor="LEATHER", primary="민첩", priority="가속 > 특화 = 유연성 > 치명타 및 극대화", weights={ ["가속"]=100, ["특화"]=85, ["유연성"]=85, ["치명타 및 극대화"]=55 }, source="USER_SELECTED" },
  DRUID_RESTO = { classKo="드루이드", specKo="회복", role="HEALER", armor="LEATHER", primary="지능", priority="특화 = 가속 >= 유연성 >> 치명타 및 극대화", weights={ ["특화"]=100, ["가속"]=100, ["유연성"]=80, ["치명타 및 극대화"]=45 } },

  EVOKER_DEVASTATION = { classKo="기원사", specKo="황폐", role="DPS", armor="MAIL", primary="지능", priority="치명타 및 극대화 > 가속 = 특화 > 유연성", weights={ ["치명타 및 극대화"]=100, ["가속"]=85, ["특화"]=85, ["유연성"]=50 } },
  EVOKER_PRESERVATION = { classKo="기원사", specKo="보존", role="HEALER", armor="MAIL", primary="지능", priority="특화 > 치명타 및 극대화 = 가속 > 유연성", weights={ ["특화"]=100, ["치명타 및 극대화"]=85, ["가속"]=85, ["유연성"]=55 }, source="USER_SELECTED" },
  EVOKER_AUGMENTATION = { classKo="기원사", specKo="증강", role="DPS", armor="MAIL", primary="지능", priority="치명타 및 극대화 > 가속 > 특화 > 유연성", weights={ ["치명타 및 극대화"]=100, ["가속"]=85, ["특화"]=70, ["유연성"]=45 } },

  HUNTER_BEASTMASTERY = { classKo="사냥꾼", specKo="야수", role="DPS", armor="MAIL", primary="민첩", priority="치명타 및 극대화 > 가속 > 특화 > 유연성", weights={ ["치명타 및 극대화"]=100, ["가속"]=85, ["특화"]=70, ["유연성"]=45 }, note="자료 간 충돌이 있어 재검토 권장" },
  HUNTER_MARKSMANSHIP = { classKo="사냥꾼", specKo="사격", role="DPS", armor="MAIL", primary="민첩", priority="치명타 및 극대화 > 특화 > 가속 > 유연성", weights={ ["치명타 및 극대화"]=100, ["특화"]=85, ["가속"]=70, ["유연성"]=45 } },
  HUNTER_SURVIVAL = { classKo="사냥꾼", specKo="생존", role="DPS", armor="MAIL", primary="민첩", priority="특화 > 치명타 및 극대화 = 가속 > 유연성", weights={ ["특화"]=100, ["치명타 및 극대화"]=85, ["가속"]=85, ["유연성"]=45 } },

  MAGE_ARCANE = { classKo="마법사", specKo="비전", role="DPS", armor="CLOTH", primary="지능", priority="특화 > 가속 >= 치명타 및 극대화 >> 유연성", weights={ ["특화"]=100, ["가속"]=85, ["치명타 및 극대화"]=80, ["유연성"]=40 } },
  MAGE_FIRE = { classKo="마법사", specKo="화염", role="DPS", armor="CLOTH", primary="지능", priority="가속 >= 특화 > 유연성 >> 치명타 및 극대화", weights={ ["가속"]=100, ["특화"]=90, ["유연성"]=70, ["치명타 및 극대화"]=35 } },
  MAGE_FROST = { classKo="마법사", specKo="냉기", role="DPS", armor="CLOTH", primary="지능", priority="특화 >= 치명타 및 극대화 >> 유연성 >= 가속", weights={ ["특화"]=100, ["치명타 및 극대화"]=90, ["유연성"]=65, ["가속"]=60 } },

  MONK_BREWMASTER = { classKo="수도사", specKo="양조", role="TANK", armor="LEATHER", primary="민첩", priority="치명타 및 극대화 > 유연성 = 특화 > 가속", weights={ ["치명타 및 극대화"]=100, ["유연성"]=85, ["특화"]=85, ["가속"]=60 }, source="USER_SELECTED" },
  MONK_MISTWEAVER = { classKo="수도사", specKo="운무", role="HEALER", armor="LEATHER", primary="지능", priority="가속 > 치명타 및 극대화 = 유연성 > 특화", weights={ ["가속"]=100, ["치명타 및 극대화"]=85, ["유연성"]=85, ["특화"]=55 }, source="USER_SELECTED" },
  MONK_WINDWALKER = { classKo="수도사", specKo="풍운", role="DPS", armor="LEATHER", primary="민첩", priority="가속 = 치명타 및 극대화 = 특화 >>> 유연성", weights={ ["가속"]=100, ["치명타 및 극대화"]=100, ["특화"]=100, ["유연성"]=40 } },

  PALADIN_HOLY = { classKo="성기사", specKo="신성", role="HEALER", armor="PLATE", primary="지능", priority="특화 > 가속 = 치명타 및 극대화 > 유연성", weights={ ["특화"]=100, ["가속"]=85, ["치명타 및 극대화"]=85, ["유연성"]=55 } },
  PALADIN_PROTECTION = { classKo="성기사", specKo="보호", role="TANK", armor="PLATE", primary="힘", priority="가속 > 유연성 = 치명타 및 극대화 > 특화", weights={ ["가속"]=100, ["유연성"]=85, ["치명타 및 극대화"]=85, ["특화"]=60 } },
  PALADIN_RETRIBUTION = { classKo="성기사", specKo="징벌", role="DPS", armor="PLATE", primary="힘", priority="특화 > 치명타 및 극대화 > 가속 > 유연성", weights={ ["특화"]=100, ["치명타 및 극대화"]=85, ["가속"]=70, ["유연성"]=50 } },

  PRIEST_DISC = { classKo="사제", specKo="수양", role="HEALER", armor="CLOTH", primary="지능", priority="가속 > 치명타 및 극대화 > 특화 > 유연성", weights={ ["가속"]=100, ["치명타 및 극대화"]=85, ["특화"]=70, ["유연성"]=55 } },
  PRIEST_HOLY = { classKo="사제", specKo="신성", role="HEALER", armor="CLOTH", primary="지능", priority="치명타 및 극대화 > 특화 > 유연성 > 가속", weights={ ["치명타 및 극대화"]=100, ["특화"]=90, ["유연성"]=80, ["가속"]=55 }, source="USER_SELECTED" },
  PRIEST_SHADOW = { classKo="사제", specKo="암흑", role="DPS", armor="CLOTH", primary="지능", priority="가속 > 특화 > 치명타 및 극대화 > 유연성", weights={ ["가속"]=100, ["특화"]=85, ["치명타 및 극대화"]=70, ["유연성"]=50 } },

  ROGUE_ASSASSINATION = { classKo="도적", specKo="암살", role="DPS", armor="LEATHER", primary="민첩", priority="치명타 및 극대화 > 가속 > 특화 > 유연성", weights={ ["치명타 및 극대화"]=100, ["가속"]=85, ["특화"]=70, ["유연성"]=45 } },
  ROGUE_OUTLAW = { classKo="도적", specKo="무법", role="DPS", armor="LEATHER", primary="민첩", priority="가속 > 치명타 및 극대화 = 유연성 > 특화", weights={ ["가속"]=100, ["치명타 및 극대화"]=85, ["유연성"]=85, ["특화"]=55 }, source="USER_SELECTED" },
  ROGUE_SUBTLETY = { classKo="도적", specKo="잠행", role="DPS", armor="LEATHER", primary="민첩", priority="특화 > 가속 >= 치명타 및 극대화 >> 유연성", weights={ ["특화"]=100, ["가속"]=90, ["치명타 및 극대화"]=82, ["유연성"]=40 } },

  SHAMAN_ELEMENTAL = { classKo="주술사", specKo="정기", role="DPS", armor="MAIL", primary="지능", priority="특화 > 가속 = 치명타 및 극대화 >> 유연성", weights={ ["특화"]=100, ["가속"]=85, ["치명타 및 극대화"]=85, ["유연성"]=45 } },
  SHAMAN_ENHANCEMENT = { classKo="주술사", specKo="고양", role="DPS", armor="MAIL", primary="민첩", priority="특화 = 가속 > 치명타 및 극대화 > 유연성", weights={ ["특화"]=100, ["가속"]=100, ["치명타 및 극대화"]=75, ["유연성"]=45 }, source="USER_SELECTED" },
  SHAMAN_RESTORATION = { classKo="주술사", specKo="복원", role="HEALER", armor="MAIL", primary="지능", priority="치명타 및 극대화 > 특화 = 유연성 > 가속", weights={ ["치명타 및 극대화"]=100, ["특화"]=85, ["유연성"]=85, ["가속"]=55 } },

  WARLOCK_AFFLICTION = { classKo="흑마법사", specKo="고통", role="DPS", armor="CLOTH", primary="지능", priority="특화 = 치명타 및 극대화 > 가속 > 유연성", weights={ ["특화"]=100, ["치명타 및 극대화"]=100, ["가속"]=75, ["유연성"]=45 } },
  WARLOCK_DEMONOLOGY = { classKo="흑마법사", specKo="악마", role="DPS", armor="CLOTH", primary="지능", priority="가속 = 치명타 및 극대화 > 특화 > 유연성", weights={ ["가속"]=100, ["치명타 및 극대화"]=100, ["특화"]=75, ["유연성"]=45 } },
  WARLOCK_DESTRUCTION = { classKo="흑마법사", specKo="파괴", role="DPS", armor="CLOTH", primary="지능", priority="가속 = 치명타 및 극대화 > 특화 > 유연성", weights={ ["가속"]=100, ["치명타 및 극대화"]=100, ["특화"]=75, ["유연성"]=45 } },

  WARRIOR_ARMS = { classKo="전사", specKo="무기", role="DPS", armor="PLATE", primary="힘", priority="치명타 및 극대화 > 가속 > 특화 > 유연성", weights={ ["치명타 및 극대화"]=100, ["가속"]=85, ["특화"]=70, ["유연성"]=45 } },
  WARRIOR_FURY = { classKo="전사", specKo="분노", role="DPS", armor="PLATE", primary="힘", priority="가속 > 특화 > 치명타 및 극대화 > 유연성", weights={ ["가속"]=100, ["특화"]=85, ["치명타 및 극대화"]=70, ["유연성"]=45 } },
  WARRIOR_PROTECTION = { classKo="전사", specKo="방어", role="TANK", armor="PLATE", primary="힘", priority="가속 > 유연성 = 치명타 및 극대화 > 특화", weights={ ["가속"]=100, ["유연성"]=85, ["치명타 및 극대화"]=85, ["특화"]=60 } },
}

local function copyTable(t)
  local r = {}
  if not t then return r end
  for k, v in pairs(t) do r[k] = v end
  return r
end

function DB.GetSpecProfile(specKey)
  return DB.SPECS[specKey]
end

function DB.NormalizeStats(rawStats)
  local out = {}
  for key, value in pairs(rawStats or {}) do
    local statKo = DB.STAT_TOKEN_MAP[key] or key
    out[statKo] = (out[statKo] or 0) + (tonumber(value) or 0)
  end
  return out
end

function DB.GetItemIdFromLink(itemLink)
  if not itemLink then return nil end
  return tonumber(string.match(itemLink, "item:(%d+)"))
end

function DB.GetDetailedItemLevel(itemLink)
  if not itemLink then return nil end
  if type(GetDetailedItemLevelInfo) == "function" then
    local effectiveILvl = GetDetailedItemLevelInfo(itemLink)
    return effectiveILvl
  end
  return nil
end

function DB.GetRawItemStats(itemLink)
  if not itemLink then return {} end
  if C_Item and type(C_Item.GetItemStats) == "function" then
    return C_Item.GetItemStats(itemLink) or {}
  end
  if type(GetItemStats) == "function" then
    return GetItemStats(itemLink) or {}
  end
  return {}
end

function DB.NormalizeSourceType(sourceType)
  if DB.SOURCE_TYPES[sourceType] then return sourceType end
  return "UNKNOWN"
end

function DB.GetSourceLabelKo(sourceType, keyLevel, upgradeTrackText)
  sourceType = DB.NormalizeSourceType(sourceType)
  local source = DB.SOURCE_TYPES[sourceType]
  local label = source.ko
  if source.group == "MPLUS" and keyLevel then
    label = label .. " +" .. tostring(keyLevel)
  end
  if upgradeTrackText and upgradeTrackText ~= "" then
    label = label .. " / " .. upgradeTrackText
  end
  return label
end

function DB.GetMPlusRewardInfo(keyLevel, sourceType)
  if not keyLevel then return nil end
  local level = tonumber(keyLevel) or 0
  if level >= 10 then level = 10 end
  if level < 2 then level = 2 end
  local row = DB.MPLUS_REWARDS[level]
  if not row then return nil end
  sourceType = DB.NormalizeSourceType(sourceType)
  if sourceType == "MPLUS_END_DUNGEON" then
    return { itemLevel=row.endItemLevel, trackKo=row.endTrackKo, mythTrack=false, sourceKo="쐐기 종료 보상" }
  end
  if sourceType == "MPLUS_GREAT_VAULT" or sourceType == "MPLUS_BONUS_ROLL" then
    return { itemLevel=row.vaultItemLevel, trackKo=row.vaultTrackKo, mythTrack=(level >= 10), sourceKo=DB.SOURCE_TYPES[sourceType].ko }
  end
  return nil
end

function DB.BuildRuntimeItemRecord(itemLink, specKey, sourceType, options, slot)
  options = options or {}
  if type(options) ~= "table" then options = { keyLevel = options } end
  sourceType = DB.NormalizeSourceType(sourceType)
  local rawStats = options.rawStats or DB.GetRawItemStats(itemLink)
  local actualItemLevel = options.actualItemLevel or DB.GetDetailedItemLevel(itemLink)
  local reward = DB.GetMPlusRewardInfo(options.keyLevel, sourceType)
  local rec = {
    itemLink = itemLink,
    baseItemId = options.baseItemId or DB.GetItemIdFromLink(itemLink),
    specKey = specKey,
    slot = slot,
    sourceType = sourceType,
    keyLevel = options.keyLevel,
    sourceLabelKo = DB.GetSourceLabelKo(sourceType, options.keyLevel, options.upgradeTrackText),
    actualItemLevel = actualItemLevel,
    upgradeTrackText = options.upgradeTrackText,
    rawStats = rawStats,
    stats = DB.NormalizeStats(rawStats),
    expectedReward = reward,
    raidBossKo = options.raidBossKo,
    raidDifficultyKo = options.raidDifficultyKo,
    tierSetPiece = options.tierSetPiece or false,
    trinketManualRank = options.trinketManualRank,
  }
  return rec
end

function DB.GetPrimaryStatWeight(spec, slot)
  if not spec then return 0 end
  if spec.role == "DPS" then return 125 end
  if spec.role == "HEALER" then return 118 end
  if spec.role == "TANK" then return 115 end
  return 110
end

function DB.GetItemLevelWeight(spec, slot)
  local w = 28
  if slot == "MAIN_HAND" or slot == "TWO_HAND" or slot == "RANGED" then w = 85 end
  if slot == "TRINKET" then w = 40 end
  if spec and spec.role == "TANK" then w = w + 12 end
  return w
end

function DB.ScoreItemRecord(record, specKey, slot)
  specKey = specKey or (record and record.specKey)
  slot = slot or (record and record.slot)
  local spec = DB.SPECS[specKey]
  local score = 0
  local evidence = { notes = {}, specKey=specKey, priority = spec and spec.priority }
  if not record or not spec then
    evidence.error = "NO_RECORD_OR_SPEC"
    return 0, evidence
  end

  local stats = record.stats or {}
  local primaryValue = tonumber(stats[spec.primary] or 0) or 0
  if primaryValue > 0 then
    local weight = DB.GetPrimaryStatWeight(spec, slot)
    score = score + primaryValue * weight
    evidence.notes[#evidence.notes+1] = spec.primary .. "=" .. primaryValue .. "*" .. weight
  end

  for statKo, weight in pairs(spec.weights or {}) do
    local value = tonumber(stats[statKo] or 0) or 0
    if value > 0 then
      score = score + value * weight
      evidence.notes[#evidence.notes+1] = statKo .. "=" .. value .. "*" .. weight
    end
  end

  if record.actualItemLevel then
    local weight = DB.GetItemLevelWeight(spec, slot)
    score = score + record.actualItemLevel * weight
    evidence.notes[#evidence.notes+1] = "아이템레벨=" .. tostring(record.actualItemLevel) .. "*" .. tostring(weight)
  end

  if record.tierSetPiece then
    score = score + 7000
    evidence.notes[#evidence.notes+1] = "티어세트조각=+7000"
  end

  if slot == "TRINKET" then
    evidence.trinketReviewRequired = true
    evidence.notes[#evidence.notes+1] = "장신구 특수효과는 수동 등급/SimC/QE 보정 필요"
    if record.trinketManualRank == "S" then score = score + 5000 end
    if record.trinketManualRank == "A" then score = score + 3000 end
    if record.trinketManualRank == "B" then score = score + 1500 end
  end

  local source = DB.SOURCE_TYPES[record.sourceType or "UNKNOWN"]
  if source and source.group == "MPLUS" then
    local reward = record.expectedReward
    if reward then
      evidence.notes[#evidence.notes+1] = reward.sourceKo .. ":" .. reward.trackKo .. ":ilvl" .. tostring(reward.itemLevel)
      if reward.mythTrack then
        evidence.mplusMythTrackCandidate = true
      end
    end
  end

  evidence.score = score
  return score, evidence
end

function DB.ScoreItemLink(itemLink, specKey, slot, sourceType, options)
  local record = DB.BuildRuntimeItemRecord(itemLink, specKey, sourceType, options or {}, slot)
  local score, evidence = DB.ScoreItemRecord(record, specKey, slot)
  record.score = score
  record.evidence = evidence
  return record
end

function DB.SortItemLinks(specKey, slot, itemLinks, sourceType, options)
  local out = {}
  for _, itemLink in ipairs(itemLinks or {}) do
    out[#out+1] = DB.ScoreItemLink(itemLink, specKey, slot, sourceType, options or {})
  end
  table.sort(out, function(a, b) return (a.score or 0) > (b.score or 0) end)
  return out
end

function DB.RunSelfCheck()
  local result = { ok=true, specCount=0, errors={}, warnings={} }
  for specKey, spec in pairs(DB.SPECS or {}) do
    result.specCount = result.specCount + 1
    if not spec.priority or not spec.weights then
      result.ok = false
      result.errors[#result.errors+1] = specKey .. ": missing priority/weights"
    end
  end
  local hp = DB.SPECS.PRIEST_HOLY
  if not hp or hp.priority ~= "치명타 및 극대화 > 특화 > 유연성 > 가속" then
    result.ok = false
    result.errors[#result.errors+1] = "PRIEST_HOLY priority mismatch"
  end
  if result.specCount < 40 then
    result.warnings[#result.warnings+1] = "specCount < 40: 신규 전문화/키 누락 여부 확인 필요"
  end
  result.warnings[#result.warnings+1] = "itemId만으로 쐐기 금고/레이드 난이도 판정 금지. itemLink와 실제 트랙 텍스트를 함께 확인하세요."
  result.warnings[#result.warnings+1] = "장신구/무기 특수효과는 이 스탯 점수만으로 최종 BiS 확정하지 마세요."
  return result
end

DB.PROMPTS = {
  maintain = [[
WoW 한밤 시즌 1 / 12.0.5 장비 추천 애드온 DB를 갱신한다.
- 한글명은 공식 클라이언트/Blizzard KO/Wowhead KO에서 확인된 값만 사용한다.
- 영어명을 임의 번역하지 않는다.
- itemId만으로 쐐기 금고, 쐐기 종료, 레이드 난이도, 신화 트랙을 판정하지 않는다.
- 실제 점수 계산은 itemLink -> GetDetailedItemLevelInfo -> C_Item.GetItemStats -> NormalizeStats -> ScoreItemRecord 순서로 한다.
- '=' 스탯은 반드시 같은 가중치로 둔다.
- UI 표기는 '쐐기 종료 보상 +10 / 영웅 3/6', '쐐기 금고 보상 +10 / 신화 1/6', '레이드 영웅'처럼 출처와 트랙을 분리한다.
- 장신구/무기 특수효과는 SimC/QE/로그 보정값을 별도로 둔다.
  ]]
}

return DB
