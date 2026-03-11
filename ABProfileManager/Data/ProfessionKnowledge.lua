local _, ns = ...

local function buildCraftingProfession(key, skillLine, labelKey)
    return {
        key = key,
        skillLine = skillLine,
        labelKey = labelKey,
        noteKey = "pk_profession_note_crafting",
        weekly = {
            {
                key = "weekly_quest",
                labelKey = "pk_source_weekly_quest",
                max = 1,
                pointsPerStep = 2,
                noteKey = "pk_note_weekly_quest_2",
            },
            {
                key = "weekly_drops",
                labelKey = "pk_source_weekly_drops",
                max = 4,
                pointsPerStep = 1,
                noteKey = "pk_note_weekly_drops_4",
            },
            {
                key = "treatise",
                labelKey = "pk_source_treatise",
                max = 1,
                pointsPerStep = 1,
                noteKey = "pk_note_treatise_1",
            },
        },
        oneTime = {
            {
                key = "treasures",
                labelKey = "pk_source_treasures",
                max = 8,
                pointsPerStep = 3,
                noteKey = "pk_note_treasures_8x3",
            },
        },
    }
end

local function buildGatheringProfession(key, skillLine, labelKey, dropCount, extraOneTime)
    local definition = {
        key = key,
        skillLine = skillLine,
        labelKey = labelKey,
        noteKey = "pk_profession_note_gathering",
        weekly = {
            {
                key = "trainer_weekly",
                labelKey = "pk_source_trainer_weekly",
                max = 1,
                pointsPerStep = 3,
                noteKey = "pk_note_weekly_quest_3",
            },
            {
                key = "weekly_gathering_drops",
                labelKey = "pk_source_weekly_gathering_drops",
                max = dropCount,
                pointsPerStep = 1,
                noteKey = "pk_note_weekly_gathering_drops",
            },
            {
                key = "treatise",
                labelKey = "pk_source_treatise",
                max = 1,
                pointsPerStep = 1,
                noteKey = "pk_note_treatise_1",
            },
        },
        oneTime = {
            {
                key = "treasures",
                labelKey = "pk_source_treasures",
                max = 8,
                pointsPerStep = 3,
                noteKey = "pk_note_treasures_8x3",
            },
        },
    }

    if type(extraOneTime) == "table" then
        definition.oneTime[#definition.oneTime + 1] = extraOneTime
    end

    return definition
end

local professions = {
    buildCraftingProfession("alchemy", 171, "profession_alchemy"),
    buildCraftingProfession("blacksmithing", 164, "profession_blacksmithing"),
    {
        key = "enchanting",
        skillLine = 333,
        labelKey = "profession_enchanting",
        noteKey = "pk_profession_note_enchanting",
        weekly = {
            {
                key = "weekly_quest",
                labelKey = "pk_source_weekly_quest",
                max = 1,
                pointsPerStep = 3,
                noteKey = "pk_note_weekly_quest_3",
            },
            {
                key = "weekly_drops",
                labelKey = "pk_source_weekly_drops",
                max = 4,
                pointsPerStep = 1,
                noteKey = "pk_note_weekly_drops_4",
            },
            {
                key = "disenchant_drops",
                labelKey = "pk_source_disenchant_drops",
                max = 9,
                pointsPerStep = 1,
                noteKey = "pk_note_disenchant_drops_9",
            },
            {
                key = "treatise",
                labelKey = "pk_source_treatise",
                max = 1,
                pointsPerStep = 1,
                noteKey = "pk_note_treatise_1",
            },
        },
        oneTime = {
            {
                key = "treasures",
                labelKey = "pk_source_treasures",
                max = 8,
                pointsPerStep = 3,
                noteKey = "pk_note_treasures_8x3",
            },
        },
    },
    buildCraftingProfession("engineering", 202, "profession_engineering"),
    buildGatheringProfession("herbalism", 182, "profession_herbalism", 9, {
        key = "first_discoveries",
        labelKey = "pk_source_first_discoveries",
        max = 34,
        pointsPerStep = 1,
        noteKey = "pk_note_first_discoveries_herbalism",
    }),
    buildCraftingProfession("inscription", 773, "profession_inscription"),
    buildCraftingProfession("jewelcrafting", 755, "profession_jewelcrafting"),
    buildCraftingProfession("leatherworking", 165, "profession_leatherworking"),
    buildGatheringProfession("mining", 186, "profession_mining", 8, {
        key = "first_discoveries",
        labelKey = "pk_source_first_discoveries",
        max = 25,
        pointsPerStep = 1,
        noteKey = "pk_note_first_discoveries_mining",
    }),
    buildGatheringProfession("skinning", 393, "profession_skinning", 8, nil),
    buildCraftingProfession("tailoring", 197, "profession_tailoring"),
}

ns.Data.ProfessionKnowledge = {
    order = {
        "alchemy",
        "blacksmithing",
        "enchanting",
        "engineering",
        "herbalism",
        "inscription",
        "jewelcrafting",
        "leatherworking",
        "mining",
        "skinning",
        "tailoring",
    },
    professions = professions,
}
