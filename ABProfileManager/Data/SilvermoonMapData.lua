local _, ns = ...

local silvermoonPoints = {
    { key = "auction_house", labelKey = "map_label_auction_house", x = 50.28, y = 74.86, category = "service", size = 20 },
    { key = "inn", labelKey = "map_label_inn", x = 56.28, y = 70.34, category = "service", size = 18 },
    { key = "bank", labelKey = "map_label_bank_vault", x = 50.64, y = 65.43, category = "service", size = 20 },
    { key = "great_vault", labelKey = "map_label_great_vault", x = 49.20, y = 66.20, category = "service", size = 16, offsetX = -18, offsetY = -8 },
    { key = "portal_room", labelKey = "map_label_portal_room", x = 53.33, y = 66.24, category = "travel", size = 18, offsetX = 10, offsetY = 16 },
    { key = "portal_orgrimmar", labelKey = "map_label_portal_orgrimmar", x = 52.60, y = 66.42, category = "travel", size = 14, offsetX = -28, offsetY = -8 },
    { key = "portal_stormwind", labelKey = "map_label_portal_stormwind", x = 53.92, y = 66.34, category = "travel", size = 14, offsetX = 28, offsetY = -8 },
    { key = "portal_timeways", labelKey = "map_label_portal_timeways", x = 53.30, y = 65.20, category = "travel", size = 14, offsetY = 22 },
    { key = "portal_harandar", labelKey = "map_label_portal_harandar", x = 54.48, y = 65.66, category = "travel", size = 14, offsetX = 40, offsetY = 18 },
    { key = "portal_voidstorm", labelKey = "map_label_portal_voidstorm", x = 52.18, y = 65.66, category = "travel", size = 14, offsetX = -40, offsetY = 18 },
    { key = "item_upgrader", labelKey = "map_label_item_upgrader", x = 48.62, y = 61.82, category = "service", size = 15 },
    { key = "mplus_portals", labelKey = "map_label_mplus_portals", x = 42.28, y = 58.31, category = "travel", size = 16 },
    { key = "profession_hub", labelKey = "map_label_profession_hub", x = 45.64, y = 53.99, category = "profession", size = 18 },
    { key = "work_orders", labelKey = "map_label_work_orders", x = 45.12, y = 55.58, category = "profession", size = 14, offsetX = -20, offsetY = -18 },
    { key = "alchemy_trainer", labelKey = "map_label_alchemy_short", x = 46.98, y = 52.07, category = "profession", size = 13, offsetX = 10, offsetY = -10 },
    { key = "herbalism_trainer", labelKey = "map_label_herbalism_short", x = 48.20, y = 51.52, category = "profession", size = 13, offsetX = 28, offsetY = -18 },
    { key = "mining_trainer", labelKey = "map_label_mining_short", x = 42.68, y = 52.84, category = "profession", size = 13, offsetX = -22, offsetY = -4 },
    { key = "blacksmithing_trainer", labelKey = "map_label_blacksmithing_short", x = 43.74, y = 51.86, category = "profession", size = 13, offsetX = -28, offsetY = -18 },
    { key = "engineering_trainer", labelKey = "map_label_engineering_short", x = 43.61, y = 54.06, category = "profession", size = 13, offsetX = -34, offsetY = 14 },
    { key = "leatherworking_trainer", labelKey = "map_label_leatherworking_short", x = 43.21, y = 55.79, category = "profession", size = 13, offsetX = -34, offsetY = 24 },
    { key = "skinning_trainer", labelKey = "map_label_skinning_short", x = 43.27, y = 55.59, category = "profession", size = 13, offsetX = -32, offsetY = 6 },
    { key = "inscription_trainer", labelKey = "map_label_inscription_short", x = 46.81, y = 51.73, category = "profession", size = 13, offsetX = 8, offsetY = -26 },
    { key = "enchanting_trainer", labelKey = "map_label_enchanting_short", x = 47.91, y = 53.90, category = "profession", size = 13, offsetX = 30, offsetY = 8 },
    { key = "tailoring_trainer", labelKey = "map_label_tailoring_short", x = 48.14, y = 54.08, category = "profession", size = 13, offsetX = 30, offsetY = 20 },
    { key = "jewelcrafting_trainer", labelKey = "map_label_jewelcrafting_short", x = 48.13, y = 55.00, category = "profession", size = 13, offsetX = 30, offsetY = 32 },
    { key = "creation_catalyst", labelKey = "map_label_creation_catalyst", x = 40.31, y = 64.85, category = "service", size = 15 },
    { key = "black_market", labelKey = "map_label_black_market", x = 51.80, y = 48.50, category = "service", size = 16 },
    { key = "transmog", labelKey = "map_label_transmog", x = 44.20, y = 73.70, category = "service", size = 15 },
    { key = "trading_post", labelKey = "map_label_trading_post", x = 48.20, y = 78.30, category = "service", size = 15, offsetY = 16 },
    { key = "pvp_hub", labelKey = "map_label_pvp_hub", x = 34.40, y = 81.00, category = "pvp", size = 18 },
    { key = "conquest_vendor", labelKey = "map_label_conquest_vendor", x = 33.80, y = 81.70, category = "pvp", size = 14, offsetX = 18, offsetY = -18 },
    { key = "delve_hub", labelKey = "map_label_delve_hub", x = 52.40, y = 78.04, category = "service", size = 18 },
    { key = "murder_row", labelKey = "map_label_murder_row", x = 56.61, y = 61.10, category = "dungeon", size = 17, width = 170 },
    { key = "the_darkway", labelKey = "map_label_the_darkway", x = 39.30, y = 31.70, category = "delve", size = 17, width = 190 },
    { key = "collegiate_calamity", labelKey = "map_label_collegiate_calamity", x = 40.60, y = 53.70, category = "delve", size = 17, width = 210, offsetX = -16 },
}

ns.Data.SilvermoonMapData = {
    maps = {
        [2393] = { points = silvermoonPoints },
        [2710] = { points = silvermoonPoints },
        [2395] = {
            points = {
                { key = "caeris_fairdawn", labelKey = "map_label_caeris_fairdawn", x = 43.40, y = 47.40, category = "renown", size = 18, width = 180 },
                { key = "windrunner_spire", labelKey = "map_label_windrunner_spire", x = 35.63, y = 78.87, category = "dungeon", size = 18, width = 180 },
                { key = "shadow_enclave", labelKey = "map_label_shadow_enclave", x = 45.55, y = 86.31, category = "delve", size = 18, width = 180 },
            },
        },
        [2413] = {
            points = {
                { key = "naynar", labelKey = "map_label_naynar", x = 51.00, y = 50.80, category = "renown", size = 18, width = 180 },
                { key = "blinding_vale", labelKey = "map_label_blinding_vale", x = 27.43, y = 77.98, category = "delve", size = 18, width = 180 },
                { key = "grudge_pit", labelKey = "map_label_grudge_pit", x = 70.30, y = 67.14, category = "dungeon", size = 18, width = 180 },
            },
        },
        [2405] = {
            points = {
                { key = "anomander", labelKey = "map_label_anomander", x = 52.60, y = 72.80, category = "renown", size = 18, width = 180 },
                { key = "nexus_point_xenas", labelKey = "map_label_nexus_point_xenas", x = 64.70, y = 61.77, category = "delve", size = 18, width = 180 },
                { key = "voidscar_arena", labelKey = "map_label_voidscar_arena", x = 53.62, y = 35.45, category = "dungeon", size = 18, width = 180 },
            },
        },
        [2437] = {
            points = {
                { key = "magovu", labelKey = "map_label_magovu", x = 45.80, y = 65.80, category = "renown", size = 18, width = 170 },
                { key = "chel_the_chip", labelKey = "map_label_chel_the_chip", x = 45.01, y = 67.62, category = "renown", size = 16, width = 180, offsetX = 24, offsetY = 16 },
                { key = "den_of_nalorakk", labelKey = "map_label_den_of_nalorakk", x = 29.99, y = 84.45, category = "delve", size = 18, width = 190 },
                { key = "sunkiller_sanctum", labelKey = "map_label_sunkiller_sanctum", x = 54.80, y = 47.10, category = "dungeon", size = 18, width = 190 },
            },
        },
    },
}
