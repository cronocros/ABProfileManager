local _, ns = ...

local function objective(name, points, questIDs, match)
    return {
        name = name,
        points = points,
        questIDs = questIDs,
        match = match or "all",
    }
end

local function source(key, labelKey, objectives)
    return {
        key = key,
        labelKey = labelKey,
        objectives = objectives or {},
    }
end

local function buildObjectives(entries)
    local objectives = {}
    for _, entry in ipairs(entries or {}) do
        objectives[#objectives + 1] = objective(entry[1], entry[2], entry[3], entry[4])
    end
    return objectives
end

local professions = {
    {
        key = "alchemy",
        skillLine = 171,
        labelKey = "profession_alchemy",
        noteKey = "pk_profession_note_crafting",
        weekly = {
            source("weekly_quest", "pk_source_weekly_quest", buildObjectives({
                { "Weekly Quest", 1, { 93690 }, "any" },
            })),
            source("weekly_drops", "pk_source_weekly_drops", buildObjectives({
                { "Lightbloomed Spore Sample", 2, { 93528 } },
                { "Aged Cruor", 2, { 93529 } },
            })),
            source("treatise", "pk_source_treatise", buildObjectives({
                { "Treatise", 1, { 95127 } },
            })),
        },
        oneTime = {
            source("treasures", "pk_source_treasures", buildObjectives({
                { "Freshly Plucked Peacebloom", 3, { 89115 } },
                { "Pristine Potion", 3, { 89117 } },
                { "Vial of Zul'Aman Oddities", 3, { 89114 } },
                { "Measured Ladle", 3, { 89116 } },
                { "Vial of Rootlands Oddities", 3, { 89113 } },
                { "Vial of Voidstorm Oddities", 3, { 89112 } },
                { "Vial of Eversong Oddities", 3, { 89111 } },
                { "Failed Experiment", 3, { 89118 } },
            })),
            source("renown_reward", "pk_source_renown_reward", buildObjectives({
                { "Beyond the Event Horizon: Alchemy", 10, { 93794 } },
            })),
        },
    },
    {
        key = "blacksmithing",
        skillLine = 164,
        labelKey = "profession_blacksmithing",
        noteKey = "pk_profession_note_crafting",
        weekly = {
            source("weekly_quest", "pk_source_weekly_quest", buildObjectives({
                { "Weekly Quest", 2, { 93691 }, "any" },
            })),
            source("weekly_drops", "pk_source_weekly_drops", buildObjectives({
                { "Thalassian Whestone", 2, { 93530 } },
                { "Infused Quenching Oil", 2, { 93531 } },
            })),
            source("treatise", "pk_source_treatise", buildObjectives({
                { "Treatise", 1, { 95128 } },
            })),
        },
        oneTime = {
            source("treasures", "pk_source_treasures", buildObjectives({
                { "Deconstructed Forge Techniques", 3, { 89177 } },
                { "Silvermoon Smithing Kit", 3, { 89178 } },
                { "Carefully Racked Spear", 3, { 89179 } },
                { "Metalworking Cheat Sheet", 3, { 89180 } },
                { "Voidstorm Defense Spear", 3, { 89181 } },
                { "Rutaani Floratender's Sword", 3, { 89182 } },
                { "Sin'dorei Master's Forgemace", 3, { 89183 } },
                { "Silvermoon Blacksmith's Hammer", 3, { 89184 } },
            })),
            source("renown_reward", "pk_source_renown_reward", buildObjectives({
                { "Beyond the Event Horizon: Blacksmithing", 10, { 93795 } },
            })),
        },
    },
    {
        key = "enchanting",
        skillLine = 333,
        labelKey = "profession_enchanting",
        noteKey = "pk_profession_note_enchanting",
        weekly = {
            source("weekly_quest", "pk_source_weekly_quest", buildObjectives({
                { "Weekly Quest", 3, { 93698, 93699 }, "any" },
            })),
            source("weekly_drops", "pk_source_weekly_drops", buildObjectives({
                { "Voidstorm Ashes", 2, { 93532 } },
                { "Lost Thalassian Vellum", 2, { 93533 } },
            })),
            source("disenchant_drops", "pk_source_disenchant_drops", buildObjectives({
                { "Disenchant Drop 1", 1, { 95048 } },
                { "Disenchant Drop 2", 1, { 95049 } },
                { "Disenchant Drop 3", 1, { 95050 } },
                { "Disenchant Drop 4", 1, { 95051 } },
                { "Disenchant Drop 5", 1, { 95052 } },
                { "Greater Disenchant Drop", 4, { 95053 } },
            })),
            source("treatise", "pk_source_treatise", buildObjectives({
                { "Treatise", 1, { 95129 } },
            })),
        },
        oneTime = {
            source("treasures", "pk_source_treasures", buildObjectives({
                { "Enchanted Amani Mask", 3, { 89100 } },
                { "Enchanted Sunfire Silk", 3, { 89101 } },
                { "Pure Void Crystal", 3, { 89102 } },
                { "Everblazing Sunmote", 3, { 89103 } },
                { "Entropic Shard", 3, { 89104 } },
                { "Primal Essence Orb", 3, { 89105 } },
                { "Loa-Blessed Dust", 3, { 89106 } },
                { "Sin'dorei Enchanting Rod", 3, { 89107 } },
            })),
            source("renown_reward", "pk_source_renown_reward", buildObjectives({
                { "Skill Issue: Enchanting", 10, { 92374 } },
            })),
            source("abundance_reward", "pk_source_abundance_reward", buildObjectives({
                { "Echo of Abundance: Enchanting", 10, { 92186 } },
            })),
        },
    },
    {
        key = "engineering",
        skillLine = 202,
        labelKey = "profession_engineering",
        noteKey = "pk_profession_note_crafting",
        weekly = {
            source("weekly_quest", "pk_source_weekly_quest", buildObjectives({
                { "Weekly Quest", 1, { 93692 }, "any" },
            })),
            source("weekly_drops", "pk_source_weekly_drops", buildObjectives({
                { "Dance Gear", 2, { 93534 } },
                { "Dawn Capacitor", 2, { 93535 } },
            })),
            source("treatise", "pk_source_treatise", buildObjectives({
                { "Treatise", 1, { 95138 } },
            })),
        },
        oneTime = {
            source("treasures", "pk_source_treasures", buildObjectives({
                { "One Engineer's Junk", 3, { 89133 } },
                { "Miniaturized Transport Skiff", 3, { 89134 } },
                { "Manual of Mistakes and Mishaps", 3, { 89135 } },
                { "Expeditious Pylon", 3, { 89136 } },
                { "Etheral Stormwrench", 3, { 89137 } },
                { "Offline Helper Bot", 3, { 89138 } },
                { "What To Do When Nothing Works", 3, { 89139 } },
                { "Handy Wrench", 3, { 89140 } },
            })),
            source("renown_reward", "pk_source_renown_reward", buildObjectives({
                { "Beyond the Event Horizon: Engineering", 10, { 93796 } },
            })),
        },
    },
    {
        key = "herbalism",
        skillLine = 182,
        labelKey = "profession_herbalism",
        noteKey = "pk_profession_note_gathering",
        weekly = {
            source("weekly_quest", "pk_source_trainer_weekly", buildObjectives({
                { "Trainer Weekly Quest", 3, { 93700, 93702, 93703, 93704 }, "any" },
            })),
            source("weekly_gathering_drops", "pk_source_weekly_gathering_drops", buildObjectives({
                { "Gathered Herb Sample 1", 1, { 81425 } },
                { "Gathered Herb Sample 2", 1, { 81426 } },
                { "Gathered Herb Sample 3", 1, { 81427 } },
                { "Gathered Herb Sample 4", 1, { 81428 } },
                { "Gathered Herb Sample 5", 1, { 81429 } },
                { "Greater Herb Sample", 4, { 81430 } },
            })),
            source("treatise", "pk_source_treatise", buildObjectives({
                { "Treatise", 1, { 95130 } },
            })),
        },
        oneTime = {
            source("treasures", "pk_source_treasures", buildObjectives({
                { "Bloomed Bud", 3, { 89162 } },
                { "Sweeping Harvester's Scythe", 3, { 89161 } },
                { "Simple Leaf Pruners", 3, { 89160 } },
                { "Lightbloom Root", 3, { 89159 } },
                { "A Spade", 3, { 89158 } },
                { "Harvester's Sickle", 3, { 89157 } },
                { "Peculiar Lotus", 3, { 89156 } },
                { "Planting Shovel", 3, { 89155 } },
            })),
            source("renown_reward", "pk_source_renown_reward", buildObjectives({
                { "Traditions of the Haranir: Herbalism", 10, { 93411 } },
            })),
            source("abundance_reward", "pk_source_abundance_reward", buildObjectives({
                { "Echo of Abundance: Herbalism", 10, { 92174 } },
            })),
            source("first_discoveries", "pk_source_first_discoveries", buildObjectives({
                { "Tranquility Bloom", 1, { 87729 } },
                { "Lush Tranquility Bloom", 1, { 87730 } },
                { "Lightfused Tranquility Bloom", 1, { 87731 } },
                { "Voidbound Tranquility Bloom", 1, { 87734 } },
                { "Primal Tranquility Bloom", 1, { 87733 } },
                { "Wild Tranquility Bloom", 1, { 87732 } },
                { "Sanguithorn", 1, { 87735 } },
                { "Lush Sanguithorn", 1, { 87736 } },
                { "Lightfused Sanguithorn", 1, { 87737 } },
                { "Voidbound Sanguithorn", 1, { 87740 } },
                { "Primal Sanguithorn", 1, { 87739 } },
                { "Wild Sanguithorn", 1, { 87738 } },
                { "Azeroot", 1, { 87741 } },
                { "Lush Azeroot", 1, { 87742 } },
                { "Lightfused Azeroot", 1, { 87743 } },
                { "Voidbound Azeroot", 1, { 87746 } },
                { "Primal Azeroot", 1, { 87745 } },
                { "Wild Azeroot", 1, { 87744 } },
                { "Argentleaf", 1, { 87747 } },
                { "Lush Argentleaf", 1, { 87748 } },
                { "Lightfused Argentleaf", 1, { 87749 } },
                { "Voidbound Argentleaf", 1, { 87752 } },
                { "Primal Argentleaf", 1, { 87751 } },
                { "Wild Argentleaf", 1, { 87750 } },
                { "Mana Lily", 1, { 87753 } },
                { "Lightfused Mana Lily", 1, { 87755 } },
                { "Lush Mana Lily", 1, { 87754 } },
                { "Voidbound Mana Lily", 1, { 87758 } },
                { "Primal Mana Lily", 1, { 87757 } },
                { "Wild Mana Lily", 1, { 87756 } },
            })),
        },
    },
    {
        key = "inscription",
        skillLine = 773,
        labelKey = "profession_inscription",
        noteKey = "pk_profession_note_crafting",
        weekly = {
            source("weekly_quest", "pk_source_weekly_quest", buildObjectives({
                { "Weekly Quest", 4, { 93693 }, "any" },
            })),
            source("weekly_drops", "pk_source_weekly_drops", buildObjectives({
                { "Brilliant Phoenix Ink", 2, { 93536 } },
                { "Loa-Blessed Rune", 2, { 93537 } },
            })),
            source("treatise", "pk_source_treatise", buildObjectives({
                { "Treatise", 1, { 95131 } },
            })),
        },
        oneTime = {
            source("treasures", "pk_source_treasures", buildObjectives({
                { "Void-Touched Quill", 3, { 89067 } },
                { "Leather-Bound Techniques", 3, { 89068 } },
                { "Spare Ink", 3, { 89069 } },
                { "Intrepid Explorer's Marker", 3, { 89070 } },
                { "Leftover Sanguithorn Pigment", 3, { 89071 } },
                { "Half-Baked Techniques", 3, { 89072 } },
                { "Songwriter's Pen", 3, { 89073 } },
                { "Songwriter's Quill", 3, { 89074 } },
            })),
            source("renown_reward", "pk_source_renown_reward", buildObjectives({
                { "Traditions of the Haranir: Inscription", 10, { 93412 } },
            })),
        },
    },
    {
        key = "jewelcrafting",
        skillLine = 755,
        labelKey = "profession_jewelcrafting",
        noteKey = "pk_profession_note_crafting",
        weekly = {
            source("weekly_quest", "pk_source_weekly_quest", buildObjectives({
                { "Weekly Quest", 3, { 93694 }, "any" },
            })),
            source("weekly_drops", "pk_source_weekly_drops", buildObjectives({
                { "Void-Touched Eversong Diamond Fragments", 2, { 93539 } },
                { "Harandar Stone Sample", 2, { 93538 } },
            })),
            source("treatise", "pk_source_treatise", buildObjectives({
                { "Treatise", 1, { 95133 } },
            })),
        },
        oneTime = {
            source("treasures", "pk_source_treasures", buildObjectives({
                { "Sin'dorei Masterwork Chisel", 3, { 89122 } },
                { "Speculative Voidstorm Crystal", 3, { 89123 } },
                { "Dual-Function Magnifiers", 3, { 89124 } },
                { "Poorly Rounded Vial", 3, { 89125 } },
                { "Shattered Glass", 3, { 89126 } },
                { "Vintage Soul Gem", 3, { 89127 } },
                { "Ethereal Gem Pliers", 3, { 89128 } },
                { "Sin'dorei Gem Faceters", 3, { 89129 } },
            })),
            source("renown_reward", "pk_source_renown_reward", buildObjectives({
                { "Skill Issue: Jewelcrafting", 10, { 93222 } },
            })),
        },
    },
    {
        key = "leatherworking",
        skillLine = 165,
        labelKey = "profession_leatherworking",
        noteKey = "pk_profession_note_crafting",
        weekly = {
            source("weekly_quest", "pk_source_weekly_quest", buildObjectives({
                { "Weekly Quest", 2, { 93695 }, "any" },
            })),
            source("weekly_drops", "pk_source_weekly_drops", buildObjectives({
                { "Amani Tanning Oil", 2, { 93540 } },
                { "Thalassian Mana Oil", 2, { 93541 } },
            })),
            source("treatise", "pk_source_treatise", buildObjectives({
                { "Treatise", 1, { 95134 } },
            })),
        },
        oneTime = {
            source("treasures", "pk_source_treasures", buildObjectives({
                { "Amani Leatherworker's Tool", 3, { 89089 } },
                { "Ethereal Leatherworking Knife", 3, { 89090 } },
                { "Prestigiously Racked Hide", 3, { 89091 } },
                { "Bundle of Tanner's Trinkets", 3, { 89092 } },
                { "Patterns: Beyond the Void", 3, { 89093 } },
                { "Haranir Leatherworking Mallet", 3, { 89094 } },
                { "Haranir Leatherworking Knife", 3, { 89095 } },
                { "Artisan's Considered Order", 3, { 89096 } },
            })),
            source("renown_reward", "pk_source_renown_reward", buildObjectives({
                { "Whisper of the Loa: Leatherworking", 10, { 92371 } },
            })),
        },
    },
    {
        key = "mining",
        skillLine = 186,
        labelKey = "profession_mining",
        noteKey = "pk_profession_note_gathering",
        weekly = {
            source("weekly_quest", "pk_source_trainer_weekly", buildObjectives({
                { "Trainer Weekly Quest", 3, { 93705, 93706, 93708, 93709 }, "any" },
            })),
            source("weekly_gathering_drops", "pk_source_weekly_gathering_drops", buildObjectives({
                { "Mined Ore Sample 1", 1, { 88673 } },
                { "Mined Ore Sample 2", 1, { 88674 } },
                { "Mined Ore Sample 3", 1, { 88675 } },
                { "Mined Ore Sample 4", 1, { 88676 } },
                { "Mined Ore Sample 5", 1, { 88677 } },
                { "Greater Ore Sample", 3, { 88678 } },
            })),
            source("treatise", "pk_source_treatise", buildObjectives({
                { "Treatise", 1, { 95135 } },
            })),
        },
        oneTime = {
            source("treasures", "pk_source_treasures", buildObjectives({
                { "Miner's Guide to Voidstorm", 3, { 89144 } },
                { "Spelunker's Lucky Charm", 3, { 89145 } },
                { "Lost Voidstorm Satchel", 3, { 89146 } },
                { "Solid Ore Punchers", 3, { 89147 } },
                { "Glimmering Void Pearl", 3, { 89148 } },
                { "Amani Expert's Chisel", 3, { 89149 } },
                { "Star Metal Deposit", 3, { 89150 } },
                { "Spare Expedition Torch", 3, { 89151 } },
            })),
            source("renown_reward", "pk_source_renown_reward", buildObjectives({
                { "Whisper of the Loa: Mining", 10, { 92372 } },
            })),
            source("abundance_reward", "pk_source_abundance_reward", buildObjectives({
                { "Echo of Abundance: Mining", 10, { 92187 } },
            })),
            source("first_discoveries", "pk_source_first_discoveries", buildObjectives({
                { "Refulgent Copper", 1, { 88475 } },
                { "Rich Refulgent Copper", 1, { 88476 } },
                { "Refulgent Copper Seam", 1, { 88480 } },
                { "Primal Refulgent Copper", 1, { 88479 } },
                { "Lightfused Refulgent Copper", 1, { 88487 } },
                { "Wild Refulgent Copper", 1, { 88486 } },
                { "Voidbound Refulgent Copper", 1, { 88463 } },
                { "Umbral Tin", 1, { 88477 } },
                { "Rich Umbral Tin", 1, { 88478 } },
                { "Umbral Tin Seam", 1, { 88481 } },
                { "Primal Umbral Tin", 1, { 88469 } },
                { "Lightfused Umbral Tin", 1, { 88488 } },
                { "Wild Umbral Tin", 1, { 88485 } },
                { "Voidbound Umbral Tin", 1, { 88470 } },
                { "Brilliant Silver", 1, { 88471 } },
                { "Rich Brilliant Silver", 1, { 88491 } },
                { "Brilliant Silver Seam", 1, { 88466 } },
                { "Primal Brilliant Silver", 1, { 88490 } },
                { "Lightfused Brilliant Silver", 1, { 88484 } },
                { "Wild Brilliant Silver", 1, { 88472 } },
                { "Voidbound Brilliant Silver", 1, { 88465 } },
            })),
        },
    },
    {
        key = "skinning",
        skillLine = 393,
        labelKey = "profession_skinning",
        noteKey = "pk_profession_note_gathering",
        weekly = {
            source("weekly_quest", "pk_source_trainer_weekly", buildObjectives({
                { "Trainer Weekly Quest", 3, { 93710, 93711, 93712, 93714 }, "any" },
            })),
            source("weekly_gathering_drops", "pk_source_weekly_gathering_drops", buildObjectives({
                { "Skinned Trophy 1", 1, { 88534 } },
                { "Skinned Trophy 2", 1, { 88549 } },
                { "Skinned Trophy 3", 1, { 88537 } },
                { "Skinned Trophy 4", 1, { 88536 } },
                { "Skinned Trophy 5", 1, { 88530 } },
                { "Greater Skinning Trophy", 3, { 88529 } },
            })),
            source("treatise", "pk_source_treatise", buildObjectives({
                { "Treatise", 1, { 95136 } },
            })),
        },
        oneTime = {
            source("treasures", "pk_source_treasures", buildObjectives({
                { "Lightbloom Afflicted Hide", 3, { 89166 } },
                { "Cadre Skinning Knife", 3, { 89167 } },
                { "Primal Hide", 3, { 89168 } },
                { "Voidstorm Leather Sample", 3, { 89169 } },
                { "Amani Tanning Oil", 3, { 89170 } },
                { "Sin'dorei Tanning Oil", 3, { 89171 } },
                { "Amani Skinning Knife", 3, { 89172 } },
                { "Thalassian Skinning Knife", 3, { 89173 } },
            })),
            source("renown_reward", "pk_source_renown_reward", buildObjectives({
                { "Whisper of the Loa: Skinning", 10, { 92373 } },
            })),
            source("abundance_reward", "pk_source_abundance_reward", buildObjectives({
                { "Echo of Abundance: Skinning", 10, { 92188 } },
            })),
        },
    },
    {
        key = "tailoring",
        skillLine = 197,
        labelKey = "profession_tailoring",
        noteKey = "pk_profession_note_crafting",
        weekly = {
            source("weekly_quest", "pk_source_weekly_quest", buildObjectives({
                { "Weekly Quest", 2, { 93696 }, "any" },
            })),
            source("weekly_drops", "pk_source_weekly_drops", buildObjectives({
                { "Embroidered Memento", 2, { 93542 } },
                { "Finely Woven Lynx Collar", 2, { 93543 } },
            })),
            source("treatise", "pk_source_treatise", buildObjectives({
                { "Treatise", 1, { 95137 } },
            })),
        },
        oneTime = {
            source("treasures", "pk_source_treasures", buildObjectives({
                { "A Child's Stuffy", 3, { 89078 } },
                { "A Really Nice Curtain", 3, { 89079 } },
                { "Sin'dorei Outfitter's Ruler", 3, { 89080 } },
                { "Wooden Weaving Sowrd", 3, { 89081 } },
                { "Book of Sin'dorei Stitches", 3, { 89082 } },
                { "Satin Throw Pillow", 3, { 89083 } },
                { "Particularly Enchanting Tablecloth", 3, { 89084 } },
                { "Artisan's Cover Comb", 3, { 89085 } },
            })),
            source("renown_reward", "pk_source_renown_reward", buildObjectives({
                { "Skill Issue: Tailoring", 10, { 93201 } },
            })),
        },
    },
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
