local _, ns = ...

-- 아이템 레벨 참조 테이블 — Midnight 시즌 2 기준 (2026.08)
-- grade: "adv"모험가 / "vet"노련가 / "chmp"챔피언 / "hero"영웅 / "myth"신화
--   시즌 2에는 탐험가(expl) 트랙과 대응 문장이 없어 항목을 제거했다.
-- maxilvl: 해당 등급 풀 강화 최대 아이템 레벨 (트랙 6/6)
-- vault / vaultGrade / vaultMax: 주간 보상 아이템 레벨 및 등급
--
-- 랭크 사다리: 각 트랙은 기준값에 +0, +3, +6, +10, +13, +16을 더한 6단계다.
--   adv  266 269 272 276 279 282
--   vet  279 282 285 289 292 295
--   chmp 292 295 298 302 305 308
--   hero 305 308 311 315 318 321
--   myth 318 321 324 328 331 334
-- 제작 품질 사다리는 +0, +3, +6, +9, +13의 5단계로 강화 사다리와 다르다.
--
-- 값의 근거는 아래 sources 표에 남긴다. 자세한 수집 경위는
-- DOC/SEASON2_HANDOFF.md 6장을 참고한다.
ns.Data.ItemLevelTable = {
    season = "Midnight Season 2",

    -- 각 구간 값의 근거. "dump"는 라이브 API 덤프, "tooltip"은 인게임 툴팁
    -- 실측, "guide"는 외부 자료다. guide만 있는 값은 릴리스 전에 인게임에서
    -- 확인해야 하며 scripts/run_season2_validation.ps1 -Strict가 이를 막는다.
    sources = {
        delves     = "guide",
        mythicPlus = "guide",
        raid       = "guide",
        worldBoss  = "tooltip",
        crafted    = "tooltip",
        pvp        = "guide",
    },

    gradeMax = {
        adv  = 282,
        vet  = 295,
        chmp = 308,
        hero = 321,
        myth = 334,
    },

    -- 구렁 (단계별 드랍 / 주간보상) — 시즌 2 기준
    -- crestDrop: 해당 단계 클리어 시 드랍되는 문장 등급
    -- ※ 아이템 레벨은 8단계(295/챔피언)에서 상한 고정. 9~11단계는 값이 같고
    --    11단계는 영웅 문장, 황금 보관함에서 신화 문장이 추가된다.
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

    -- 5인 던전 + 쐐기
    -- rank: 해당 등급 내 업그레이드 단계, rankMax: 최대 단계 (예: 2/6)
    -- crestDrop: 클리어 시 드랍 문장 등급
    -- ※ 일반 던전은 강화 트랙이 없는 214이며 표에 넣지 않는다.
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

    -- 레이드 보스 드랍 범위 + 주간 금고 보상
    -- 맹독 심연(The Venomous Abyss) 8보스 기준. 뒤 보스일수록 값이 높다.
    --   1보스 / 2~3보스 / 4~6보스 / 7~8보스 순으로 트랙 1/6, 2/6, 3/6, 4/6
    -- ※ 신화 난이도 마지막 두 보스와 매우 희귀 아이템은 344(신화 9 상당)다.
    -- ※ 공격대 찾기는 279~289이며 표에는 일반 이상만 표시한다.
    raid = {
        normal = { min=292, max=302, grade="chmp", maxilvl=308, vault=305, vaultGrade="hero", labelKey="ilvl_raid_normal", crestDrop="chmp" },
        heroic = { min=305, max=315, grade="hero", maxilvl=321, vault=318, vaultGrade="myth", labelKey="ilvl_raid_heroic", crestDrop="hero" },
        mythic = { min=318, max=324, grade="myth", maxilvl=334, vault=334, vaultGrade="myth", labelKey="ilvl_raid_mythic", crestDrop="myth" },
    },

    -- 월드 보스 / Lair(조수결속 동굴). 야외부터 신화까지 난이도가 있다.
    -- 야외 난이도가 시즌 1 월드 보스 자리를 대체하고, 상위 난이도는 레이드
    -- 1보스와 같은 값이다.
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

    -- ※ PvP는 아직 인게임에서 확인하지 못했다. 시즌 1 값에 +46을 더하고
    --    확정된 랭크 사다리에 맞춘 추정치이며 sources.pvp = "guide"다.
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
            itemLevel = 266,
            upgradeTrack = "Hero",
            upgradeTrackKo = "영웅",
            upgradeRank = "3/6",
            displayLabel = "쐐기 영웅 트랙",
            fullLabel = "쐐기 영웅 트랙 3/6 · 266 · 던전 종료 · M+10 이상",
            itemString = nil,
            itemLink = nil,
        },
        mplus_great_vault_voidcore = {
            source = "mythicplus",
            sourceLabel = "쐐기",
            rewardContext = "great_vault_voidcore",
            rewardContextLabel = "위대한 금고/Voidcore",
            minKeystoneLevel = 10,
            itemLevel = 272,
            upgradeTrack = "Myth",
            upgradeTrackKo = "신화",
            upgradeRank = "1/6",
            displayLabel = "쐐기 신화 트랙",
            fullLabel = "쐐기 신화 트랙 1/6 · 272 · 위대한 금고/Voidcore · M+10 이상",
            itemString = nil,
            itemLink = nil,
        },
    },
}
