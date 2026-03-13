local _, ns = ...

ns.Data.Defaults = {
    global = {
        templates = {},
        settings = {
            language = ns.Constants.LANGUAGE.KOREAN,
            confirmActions = true,
            minimap = {
                hide = false,
                angle = 220,
            },
            statsOverlay = {
                enabled = false,
            },
            professionKnowledgeOverlay = {
                enabled = false,
                tooltips = true,
            },
            silvermoonMapOverlay = {
                enabled = false,
                filters = {
                    facilities = true,
                    portals = true,
                    professions = true,
                    dungeons = true,
                    delves = true,
                },
            },
            mouseMoveRestore = {
                enabled = false,
            },
            combatText = {
                managed = false,
                enabled = true,
                damage = true,
                healing = true,
                floatMode = 3,
                directionalDamage = true,
                initialized = false,
            },
        },
    },
    characters = {},
    ui = {
        mainWindow = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 0,
            width = ns.Constants.WINDOW_WIDTH,
            height = ns.Constants.WINDOW_HEIGHT,
        },
        statsOverlay = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 420,
            y = 140,
            scale = 1,
        },
        professionKnowledgeOverlay = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 420,
            y = 70,
            collapsed = false,
            displayMode = "expanded",
            scale = 1,
        },
    },
}
