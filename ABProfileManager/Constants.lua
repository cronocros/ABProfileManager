local _, ns = ...

ns.Constants = {
    ADDON_PREFIX = "ABProfileManager",
    TITLE = "ABProfileManager",
    WINDOW_TITLE = "액션바매니저",
    AUTHOR = "밍밍이와코코",
    CONTACT_EMAIL = "crono1232@gmail.com",
    VERSION = (GetAddOnMetadata and GetAddOnMetadata("ABProfileManager", "Version")) or "1.3.6",
    LOGICAL_SLOT_MIN = 1,
    LOGICAL_SLOT_MAX = 196,
    BAR_COUNT = 9,
    SLOTS_PER_BAR = 12,
    WINDOW_WIDTH = 900,
    WINDOW_HEIGHT = 900,
    APPLY_MODE = {
        FULL = "full",
        BAR = "bar",
        BAR_RANGE = "bar_range",
        BAR_SET = "bar_set",
        SLOT_RANGE = "slot_range",
    },
    SOURCE_KIND = {
        TEMPLATE = "template",
    },
    LANGUAGE = {
        KOREAN = "koKR",
        ENGLISH = "enUS",
    },
    DEFAULT_ICON = "Interface\\Icons\\INV_Inscription_ScrollOfWisdom_01",
}
