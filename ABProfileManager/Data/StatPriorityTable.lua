local _, ns = ...

-- 메인 윈도우 "스탯 우선순위 표" 팝업이 표시할 행 데이터.
-- WoW Midnight Season 1 / Patch 12.0.5 (2026-04-29) 기준.
-- priorityText 는 화면에 그대로 출력되므로 영웅 특성 / 콘텐츠 / 빌드 분기 텍스트를 그대로 보존한다.
-- 한 줄에 들어가지 않는 분기는 "\n" 으로 줄바꿈 처리한다.
ns.Data.StatPriorityTable = {
    -- 죽음의 기사
    { classTag = "DEATHKNIGHT", specIndex = 1, primaryStat = "strength",
      priorityText = "San'layn: 가속 > 특화 = 치명타 = 유연\nDeathbringer: 치명타 > 특화 = 유연 > 가속" },
    { classTag = "DEATHKNIGHT", specIndex = 2, primaryStat = "strength",
      priorityText = "치명타 > 특화 > 가속 > 유연" },
    { classTag = "DEATHKNIGHT", specIndex = 3, primaryStat = "strength",
      priorityText = "특화 > 치명타 > 가속 > 유연" },

    -- 악마사냥꾼
    { classTag = "DEMONHUNTER", specIndex = 3, primaryStat = "intellect",
      priorityText = "단일: 가속 > 특화 > 치명타 > 유연\n광역: 특화 > 가속 > 치명타 > 유연",
      specNameOverride = "포식" },
    { classTag = "DEMONHUNTER", specIndex = 1, primaryStat = "agility",
      priorityText = "치명타 > 특화 > 가속 > 유연" },
    { classTag = "DEMONHUNTER", specIndex = 2, primaryStat = "agility",
      priorityText = "방어: 가속 > 치명타 > 유연 > 특화\n공격: 치명타 > 유연 > 가속 > 특화" },

    -- 드루이드
    { classTag = "DRUID", specIndex = 1, primaryStat = "intellect",
      priorityText = "Keeper of the Grove: 특화 > 가속 = 치명타 > 유연\nElune's Chosen: 특화 > 가속 > 치명타 > 유연" },
    { classTag = "DRUID", specIndex = 2, primaryStat = "agility",
      priorityText = "Druid of the Claw: 특화 > 가속 > 치명타 > 유연\nWildstalker: 특화 > 치명타 > 가속 > 유연" },
    { classTag = "DRUID", specIndex = 3, primaryStat = "agility",
      priorityText = "가속 > 유연 > 치명타 > 특화" },
    { classTag = "DRUID", specIndex = 4, primaryStat = "intellect",
      priorityText = "가속 > 특화 > 유연 > 치명타" },

    -- 기원사
    { classTag = "EVOKER", specIndex = 3, primaryStat = "intellect",
      priorityText = "치명타 > 가속 > 특화 > 유연" },
    { classTag = "EVOKER", specIndex = 1, primaryStat = "intellect",
      priorityText = "치명타 > 가속 > 특화 > 유연" },
    { classTag = "EVOKER", specIndex = 2, primaryStat = "intellect",
      priorityText = "기본 / 레이드: 특화 > 치명타 > 가속 > 유연\n쐐기 일부: 특화 > 가속 > 치명타 > 유연" },

    -- 사냥꾼
    { classTag = "HUNTER", specIndex = 1, primaryStat = "agility",
      priorityText = "단일: 특화 > 가속 > 치명타 > 유연\n광역: 특화 > 치명타 > 가속 또는 유연" },
    { classTag = "HUNTER", specIndex = 2, primaryStat = "agility",
      priorityText = "치명타 > 특화 > 유연 > 가속" },
    { classTag = "HUNTER", specIndex = 3, primaryStat = "agility",
      priorityText = "Pack Leader: 특화 > 치명타 = 가속 > 유연\nSentinel: 특화 > 치명타 > 가속 > 유연" },

    -- 마법사
    { classTag = "MAGE", specIndex = 1, primaryStat = "intellect",
      priorityText = "특화 > 가속 > 치명타 > 유연" },
    { classTag = "MAGE", specIndex = 2, primaryStat = "intellect",
      priorityText = "가속 > 특화 > 유연 > 치명타" },
    { classTag = "MAGE", specIndex = 3, primaryStat = "intellect",
      priorityText = "특화 > 치명타 > 가속 > 유연" },

    -- 수도사
    { classTag = "MONK", specIndex = 1, primaryStat = "agility",
      priorityText = "방어: 유연 = 치명타 = 특화 > 가속\n공격: 치명타 > 특화 > 유연 > 가속" },
    { classTag = "MONK", specIndex = 2, primaryStat = "intellect",
      priorityText = "가속 > 치명타 > 유연 > 특화" },
    { classTag = "MONK", specIndex = 3, primaryStat = "agility",
      priorityText = "빌드 A: 가속 > 치명타 > 특화 > 유연\n빌드 B: 가속 > 특화 > 치명타 > 유연" },

    -- 성기사
    { classTag = "PALADIN", specIndex = 1, primaryStat = "intellect",
      priorityText = "특화 > 가속 = 치명타 > 유연" },
    { classTag = "PALADIN", specIndex = 2, primaryStat = "strength",
      priorityText = "방어: 가속 > 유연 > 특화 > 치명타\n공격: 가속 > 유연 > 치명타 > 특화" },
    { classTag = "PALADIN", specIndex = 3, primaryStat = "strength",
      priorityText = "특화 > 치명타 > 가속 > 유연" },

    -- 사제
    { classTag = "PRIEST", specIndex = 1, primaryStat = "intellect",
      priorityText = "레이드: 가속 > 치명타 > 특화 > 유연\n쐐기: 가속 > 치명타 > 유연 > 특화" },
    { classTag = "PRIEST", specIndex = 2, primaryStat = "intellect",
      priorityText = "레이드: 치명타 > 유연 = 특화 > 가속\n쐐기: 유연 > 치명타 > 가속 > 특화" },
    { classTag = "PRIEST", specIndex = 3, primaryStat = "intellect",
      priorityText = "가속 > 특화 > 치명타 > 유연" },

    -- 도적
    { classTag = "ROGUE", specIndex = 1, primaryStat = "agility",
      priorityText = "치명타 > 가속 > 특화 > 유연" },
    { classTag = "ROGUE", specIndex = 2, primaryStat = "agility",
      priorityText = "가속 > 치명타 > 유연 > 특화" },
    { classTag = "ROGUE", specIndex = 3, primaryStat = "agility",
      priorityText = "Deathstalker 단일: 특화 > 가속 목표치 > 치명타 > 유연\nTrickster 단일: 치명타 > 가속 목표치 > 특화 > 유연\n광역 · 쐐기: 특화 > 가속 목표치 > 치명타 > 유연" },

    -- 주술사
    { classTag = "SHAMAN", specIndex = 1, primaryStat = "intellect",
      priorityText = "특화 목표치까지 > 가속 = 치명타 > 유연" },
    { classTag = "SHAMAN", specIndex = 2, primaryStat = "agility",
      priorityText = "Stormbringer: 가속 > 특화 = 치명타 > 유연\nTotemic: 특화 > 가속 > 치명타 > 유연" },
    { classTag = "SHAMAN", specIndex = 3, primaryStat = "intellect",
      priorityText = "치명타 > 특화 = 유연 > 가속" },

    -- 흑마법사
    { classTag = "WARLOCK", specIndex = 1, primaryStat = "intellect",
      priorityText = "특화 = 치명타 > 가속 > 유연" },
    { classTag = "WARLOCK", specIndex = 2, primaryStat = "intellect",
      priorityText = "가속 = 치명타 > 특화 > 유연" },
    { classTag = "WARLOCK", specIndex = 3, primaryStat = "intellect",
      priorityText = "가속 > 특화 ≥ 치명타 > 유연" },

    -- 전사
    { classTag = "WARRIOR", specIndex = 1, primaryStat = "strength",
      priorityText = "치명타 > 가속 > 특화 > 유연" },
    { classTag = "WARRIOR", specIndex = 2, primaryStat = "strength",
      priorityText = "가속 > 특화 > 치명타 > 유연" },
    { classTag = "WARRIOR", specIndex = 3, primaryStat = "strength",
      priorityText = "가속 > 치명타 > 유연 > 특화" },
}

-- 각 직업/specIndex 의 specID 매핑 (게임 클라이언트의 GetSpecializationInfoForClassID 와 일치).
-- ns.SpecL(specID, fallback) 으로 한국어 전문화 이름을 얻을 때 사용.
ns.Data.StatPrioritySpecIDs = {
    DEATHKNIGHT = { [1] = 250, [2] = 251, [3] = 252 },
    DEMONHUNTER = { [1] = 577, [2] = 581, [3] = 1382 },
    DRUID       = { [1] = 102, [2] = 103, [3] = 104, [4] = 105 },
    EVOKER      = { [1] = 1467, [2] = 1468, [3] = 1473 },
    HUNTER      = { [1] = 253, [2] = 254, [3] = 255 },
    MAGE        = { [1] = 62, [2] = 63, [3] = 64 },
    MONK        = { [1] = 268, [2] = 270, [3] = 269 },
    PALADIN     = { [1] = 65, [2] = 66, [3] = 70 },
    PRIEST      = { [1] = 256, [2] = 257, [3] = 258 },
    ROGUE       = { [1] = 259, [2] = 260, [3] = 261 },
    SHAMAN      = { [1] = 262, [2] = 263, [3] = 264 },
    WARLOCK     = { [1] = 265, [2] = 266, [3] = 267 },
    WARRIOR     = { [1] = 71, [2] = 72, [3] = 73 },
}
