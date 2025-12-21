---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.Constants = {
    VERSION = "1.0.0",

    -- Display modes
    MODES = {
        BASIC = "basic",
        ADVANCED = "advanced",
    },

    -- CVar data types
    TYPES = {
        BOOLEAN = "boolean",
        INTEGER = "integer",
        FLOAT = "float",
        STRING = "string",
    },

    -- Categories
    CATEGORIES = {
        GRAPHICS = "Graphics",
        COMBAT = "Combat",
        UI = "Interface",
        AUDIO = "Audio",
        NETWORK = "Network",
        NAMEPLATE = "Nameplates",
        CAMERA = "Camera",
        CONTROLS = "Controls",
        ACCESSIBILITY = "Accessibility",
        PERFORMANCE = "Performance",
        CHAT = "Chat",
        SOCIAL = "Social",
        TOOLTIP = "Tooltips",
        TARGETING = "Targeting",
        RAID = "Raid & Party",
        WORLD = "World",
        OTHER = "Other",
    },

    -- Danger levels
    DANGER_LEVELS = {
        SAFE = 0,
        CAUTION = 1,    -- May cause issues
        DANGEROUS = 2,  -- Can break things
        CRITICAL = 3,   -- Can crash game
    },

    -- Flags
    FLAGS = {
        REQUIRES_RELOAD = 1,
        PROTECTED = 2,
        DEVELOPER = 4,
        HIDDEN = 8,
    },

    -- Colors
    COLORS = {
        DEFAULT = { r = 1.0, g = 1.0, b = 1.0 },
        MODIFIED = { r = 1.0, g = 0.9, b = 0.3 },
        DANGEROUS = { r = 1.0, g = 0.3, b = 0.3 },
        CAUTION = { r = 1.0, g = 0.7, b = 0.0 },
        SAFE = { r = 0.3, g = 1.0, b = 0.3 },
        REQUIRES_RELOAD = { r = 0.7, g = 0.7, b = 1.0 },
    },

    -- GUI dimensions
    GUI = {
        WINDOW_WIDTH = 900,
        WINDOW_HEIGHT = 600,
        CATEGORY_WIDTH = 180,
        SEARCH_HEIGHT = 30,
        ROW_HEIGHT = 20,
        PADDING = 10,
    },
}

-- Quick access
CVarMaster.MODES = CVarMaster.Constants.MODES
CVarMaster.TYPES = CVarMaster.Constants.TYPES
CVarMaster.CATEGORIES = CVarMaster.Constants.CATEGORIES
CVarMaster.DANGER_LEVELS = CVarMaster.Constants.DANGER_LEVELS
