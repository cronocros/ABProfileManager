local _, ns = ...

-- 아이템 레벨 참조 테이블 — Midnight 시즌 1 실측 기준 (2026.02)
-- grade: "expl"탐험가 / "adv"모험가 / "vet"노련가 / "chmp"챔피언 / "hero"영웅 / "myth"신화
-- maxilvl: 해당 등급 풀 강화 최대 아이템 레벨
-- vault / vaultGrade / vaultMax: 주간 보상 아이템 레벨 및 등급
ns.Data.ItemLevelTable = {
    season = "Midnight Season 1",

    gradeMax = {
        expl = 220,
        adv  = 237,
        vet  = 250,
        chmp = 263,
        hero = 276,
        myth = 289,
    },

    -- 구렁 (단계별 드랍 / 주간보상) — Midnight 시즌 1 실측 기준
    -- crestDrop: 해당 단계 클리어 시 드랍되는 문장 등급
    -- ※ 아이템 레벨은 8단계(250/챔피언)에서 상한 고정; 11단계는 신화 문장(황금 보물상자)만 추가
    delves = {
        { tier=1,  ilvl=220, grade="adv",  maxilvl=237, vault=233, vaultGrade="vet",  vaultMax=250, crestDrop="adv"  },
        { tier=2,  ilvl=224, grade="adv",  maxilvl=237, vault=237, vaultGrade="vet",  vaultMax=250, crestDrop="adv"  },
        { tier=3,  ilvl=227, grade="adv",  maxilvl=237, vault=240, vaultGrade="vet",  vaultMax=250, crestDrop="adv"  },
        { tier=4,  ilvl=230, grade="adv",  maxilvl=237, vault=243, vaultGrade="vet",  vaultMax=250, crestDrop="adv"  },
        { tier=5,  ilvl=233, grade="vet",  maxilvl=250, vault=246, vaultGrade="chmp", vaultMax=263, crestDrop="vet"  },
        { tier=6,  ilvl=237, grade="vet",  maxilvl=250, vault=253, vaultGrade="chmp", vaultMax=263, crestDrop="vet"  },
        { tier=7,  ilvl=246, grade="chmp", maxilvl=263, vault=256, vaultGrade="chmp", vaultMax=263, crestDrop="chmp" },
        { tier=8,  ilvl=250, grade="chmp", maxilvl=263, vault=259, vaultGrade="hero", vaultMax=276, crestDrop="chmp" },
        { tier=9,  ilvl=250, grade="chmp", maxilvl=263, vault=259, vaultGrade="hero", vaultMax=276, crestDrop="chmp" },
        { tier=10, ilvl=250, grade="chmp", maxilvl=263, vault=259, vaultGrade="hero", vaultMax=276, crestDrop="chmp" },
        { tier=11, ilvl=250, grade="chmp", maxilvl=263, vault=259, vaultGrade="hero", vaultMax=276, crestDrop="myth" },
    },

    -- 5인 던전 + 쐐기
    -- rank: 해당 등급 내 업그레이드 단계, rankMax: 최대 단계 (예: 2/6)
    -- crestDrop: 클리어 시 드랍 문장 등급
    mythicPlus = {
        heroic  = { labelKey="ilvl_dungeon_heroic",  ilvl=230, grade="adv",  maxilvl=237, rank=nil, rankMax=nil, vault=243, vaultGrade="vet",  vaultRank=nil, vaultMax=250, crestDrop=nil  },
        mythic0 = { labelKey="ilvl_dungeon_mythic0", ilvl=246, grade="chmp", maxilvl=263, rank=1,   rankMax=6,   vault=256, vaultGrade="chmp", vaultRank=5,   vaultMax=263, crestDrop="chmp" },
        endOfDungeon = {
            { key=2,  ilvl=250, grade="chmp", maxilvl=263, rank=2, rankMax=6, vault=259, vaultGrade="hero", vaultRank=1, vaultMax=276, crestDrop="chmp" },
            { key=3,  ilvl=250, grade="chmp", maxilvl=263, rank=2, rankMax=6, vault=259, vaultGrade="hero", vaultRank=1, vaultMax=276, crestDrop="chmp" },
            { key=4,  ilvl=253, grade="chmp", maxilvl=263, rank=3, rankMax=6, vault=263, vaultGrade="hero", vaultRank=2, vaultMax=276, crestDrop="hero" },
            { key=5,  ilvl=256, grade="chmp", maxilvl=263, rank=4, rankMax=6, vault=263, vaultGrade="hero", vaultRank=2, vaultMax=276, crestDrop="hero" },
            { key=6,  ilvl=259, grade="hero", maxilvl=276, rank=1, rankMax=6, vault=266, vaultGrade="hero", vaultRank=3, vaultMax=276, crestDrop="hero" },
            { key=7,  ilvl=259, grade="hero", maxilvl=276, rank=1, rankMax=6, vault=269, vaultGrade="hero", vaultRank=4, vaultMax=276, crestDrop="hero" },
            { key=8,  ilvl=263, grade="hero", maxilvl=276, rank=2, rankMax=6, vault=269, vaultGrade="hero", vaultRank=4, vaultMax=276, crestDrop="hero" },
            { key=9,  ilvl=263, grade="hero", maxilvl=276, rank=2, rankMax=6, vault=269, vaultGrade="hero", vaultRank=4, vaultMax=276, crestDrop="myth" },
            { key=10, ilvl=266, grade="hero", maxilvl=276, rank=3, rankMax=6, vault=272, vaultGrade="myth", vaultRank=1, vaultMax=289, crestDrop="myth" },
            { key=11, ilvl=266, grade="hero", maxilvl=276, rank=3, rankMax=6, vault=272, vaultGrade="myth", vaultRank=1, vaultMax=289, crestDrop="myth" },
            { key=12, ilvl=266, grade="hero", maxilvl=276, rank=3, rankMax=6, vault=272, vaultGrade="myth", vaultRank=1, vaultMax=289, crestDrop="myth" },
        },
    },

    -- 레이드 보스 드랍 범위 + 주간 금고 보상
    raid = {
        normal = { min=233, max=243, grade="vet",  maxilvl=250, vault=246, vaultGrade="chmp", labelKey="ilvl_raid_normal", crestDrop="chmp" },
        heroic = { min=246, max=256, grade="hero", maxilvl=276, vault=259, vaultGrade="hero", labelKey="ilvl_raid_heroic", crestDrop="hero" },
        mythic = { min=259, max=272, grade="myth", maxilvl=289, vault=272, vaultGrade="myth", labelKey="ilvl_raid_mythic", crestDrop="myth" },
    },

    worldBoss = { ilvl=233, grade="vet", maxilvl=250, crestDrop="chmp" },

    crafted = {
        base = { ilvl=272, labelKey="ilvl_crafted_runecarved" },
        r5   = { ilvl=285, labelKey="ilvl_crafted_gilded" },
    },

    pvp = {
        honor    = { min=220, max=250, labelKey="ilvl_pvp_honor" },
        conquest = { min=250, max=276, labelKey="ilvl_pvp_conquest" },
    },
}
