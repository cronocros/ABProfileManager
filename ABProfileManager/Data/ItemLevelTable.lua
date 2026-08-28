local _, ns = ...

ns.Data.ItemLevelTable = {
    season = "Midnight Season 2",

    sources = {
        delves     = "guide",
        mythicPlus = "guide",
        raid       = "dump",
        worldBoss  = "tooltip",
        crafted    = "tooltip",
        pvp        = "tooltip",
    },

    gradeMax = {
        adv  = 282,
        vet  = 295,
        chmp = 308,
        hero = 321,
        myth = 334,
    },

    delves = {
        { tier=1,  ilvl=266, grade="adv",  maxilvl=282, vault=279, vaultGrade="vet",  vaultMax=295, crestDrop=nil    },
        { tier=2,  ilvl=269, grade="adv",  maxilvl=282, vault=282, vaultGrade="vet",  vaultMax=295, crestDrop=nil    },
        { tier=3,  ilvl=272, grade="adv",  maxilvl=282, vault=285, vaultGrade="vet",  vaultMax=295, crestDrop=nil    },
        { tier=4,  ilvl=276, grade="adv",  maxilvl=282, vault=289, vaultGrade="vet",  vaultMax=295, crestDrop="adv"  },
        { tier=5,  ilvl=279, grade="vet",  maxilvl=295, vault=292, vaultGrade="chmp", vaultMax=308, crestDrop="vet"  },
        { tier=6,  ilvl=282, grade="vet",  maxilvl=295, vault=298, vaultGrade="chmp", vaultMax=308, crestDrop="vet"  },
        { tier=7,  ilvl=292, grade="chmp", maxilvl=308, vault=302, vaultGrade="chmp", vaultMax=308, crestDrop="chmp" },
        { tier=8,  ilvl=295, grade="chmp", maxilvl=308, vault=305, vaultGrade="hero", vaultMax=321, crestDrop="chmp" },
        { tier=9,  ilvl=295, grade="chmp", maxilvl=308, vault=305, vaultGrade="hero", vaultMax=321, crestDrop="chmp" },
        { tier=10, ilvl=295, grade="chmp", maxilvl=308, vault=305, vaultGrade="hero", vaultMax=321, crestDrop="chmp" },
        { tier=11, ilvl=295, grade="chmp", maxilvl=308, vault=305, vaultGrade="hero", vaultMax=321, crestDrop="hero" },
    },

    mythicPlus = {
        heroic  = { labelKey="ilvl_dungeon_heroic",  ilvl=276, grade="adv",  maxilvl=282, rank=4,   rankMax=6,   vault=289, vaultGrade="vet",  vaultRank=4,   vaultMax=295, crestDrop="vet"  },
        mythic0 = { labelKey="ilvl_dungeon_mythic0", ilvl=292, grade="chmp", maxilvl=308, rank=1,   rankMax=6,   vault=302, vaultGrade="chmp", vaultRank=4,   vaultMax=308, crestDrop="chmp" },
        endOfDungeon = {
            { key=2,  ilvl=295, grade="chmp", maxilvl=308, rank=2, rankMax=6, vault=305, vaultGrade="hero", vaultRank=1, vaultMax=321, crestDrop="chmp" },
            { key=3,  ilvl=295, grade="chmp", maxilvl=308, rank=2, rankMax=6, vault=305, vaultGrade="hero", vaultRank=1, vaultMax=321, crestDrop="chmp" },
            { key=4,  ilvl=298, grade="chmp", maxilvl=308, rank=3, rankMax=6, vault=308, vaultGrade="hero", vaultRank=2, vaultMax=321, crestDrop="hero" },
            { key=5,  ilvl=302, grade="chmp", maxilvl=308, rank=4, rankMax=6, vault=308, vaultGrade="hero", vaultRank=2, vaultMax=321, crestDrop="hero" },
            { key=6,  ilvl=305, grade="hero", maxilvl=321, rank=1, rankMax=6, vault=311, vaultGrade="hero", vaultRank=3, vaultMax=321, crestDrop="hero" },
            { key=7,  ilvl=305, grade="hero", maxilvl=321, rank=1, rankMax=6, vault=315, vaultGrade="hero", vaultRank=4, vaultMax=321, crestDrop="hero" },
            { key=8,  ilvl=308, grade="hero", maxilvl=321, rank=2, rankMax=6, vault=315, vaultGrade="hero", vaultRank=4, vaultMax=321, crestDrop="hero" },
            { key=9,  ilvl=308, grade="hero", maxilvl=321, rank=2, rankMax=6, vault=315, vaultGrade="hero", vaultRank=4, vaultMax=321, crestDrop="myth" },
            { key=10, ilvl=311, grade="hero", maxilvl=321, rank=3, rankMax=6, vault=318, vaultGrade="myth", vaultRank=1, vaultMax=334, crestDrop="myth" },
            { key=11, ilvl=311, grade="hero", maxilvl=321, rank=3, rankMax=6, vault=318, vaultGrade="myth", vaultRank=1, vaultMax=334, crestDrop="myth" },
            { key=12, ilvl=311, grade="hero", maxilvl=321, rank=3, rankMax=6, vault=318, vaultGrade="myth", vaultRank=1, vaultMax=334, crestDrop="myth" },
        },
    },

    raid = {
        normal = { min=292, max=302, grade="chmp", maxilvl=308, vault=305, vaultGrade="hero", labelKey="ilvl_raid_normal", crestDrop="chmp" },
        heroic = { min=305, max=315, grade="hero", maxilvl=321, vault=318, vaultGrade="myth", labelKey="ilvl_raid_heroic", crestDrop="hero" },
        mythic = { min=318, max=324, grade="myth", maxilvl=334, vault=334, vaultGrade="myth", labelKey="ilvl_raid_mythic", crestDrop="myth" },
    },

    worldBoss = {
        world  = { labelKey="ilvl_world_boss",   ilvl=279, grade="vet",  maxilvl=295, crestDrop="chmp" },
        normal = { labelKey="ilvl_raid_normal",  ilvl=292, grade="chmp", maxilvl=308, crestDrop="chmp" },
        heroic = { labelKey="ilvl_raid_heroic",  ilvl=305, grade="hero", maxilvl=321, crestDrop="hero" },
        mythic = { labelKey="ilvl_raid_mythic",  ilvl=318, grade="myth", maxilvl=334, crestDrop="myth" },
    },

    crafted = {
        base = { ilvl=318, labelKey="ilvl_crafted_runecarved" },
        r5   = { ilvl=331, labelKey="ilvl_crafted_gilded" },
    },

    pvp = {
        honor    = { min=266, max=295, labelKey="ilvl_pvp_honor" },
        conquest = { min=295, max=321, labelKey="ilvl_pvp_conquest" },
    },
}


-- BIS 툴팁용 보상 프로필. 단수는 요구 조건이고, 대표 표기는 업그레이드 트랙을 우선한다.
ns.Data.BISRewardProfiles = {
    mythicplus = {
        mplus_end_of_dungeon = {
            source = "mythicplus",
            sourceLabel = "쐐기",
            rewardContext = "end_of_dungeon",
            rewardContextLabel = "던전 종료",
            minKeystoneLevel = 10,
            itemLevel = 311,
            upgradeTrack = "Hero",
            upgradeTrackKo = "영웅",
            upgradeRank = "3/6",
            displayLabel = "쐐기 영웅 트랙",
            fullLabel = "쐐기 영웅 트랙 3/6 · 311 · 던전 종료 · M+10 이상",
            itemString = nil,
            itemLink = nil,
        },
        mplus_great_vault_voidcore = {
            source = "mythicplus",
            sourceLabel = "쐐기",
            rewardContext = "great_vault_voidcore",
            rewardContextLabel = "위대한 금고/Voidcore",
            minKeystoneLevel = 10,
            itemLevel = 318,
            upgradeTrack = "Myth",
            upgradeTrackKo = "신화",
            upgradeRank = "1/6",
            displayLabel = "쐐기 신화 트랙",
            fullLabel = "쐐기 신화 트랙 1/6 · 318 · 위대한 금고/Voidcore · M+10 이상",
            itemString = nil,
            itemLink = nil,
        },
    },
}
