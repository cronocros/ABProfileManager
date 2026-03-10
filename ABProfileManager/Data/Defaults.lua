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
        },
    },
}
