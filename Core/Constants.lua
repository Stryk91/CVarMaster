---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.Constants = {
    VERSION = "1.0.11",

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
        CAUTION = 1,
        DANGEROUS = 2,
        CRITICAL = 3,
    },

    -- Flags
    FLAGS = {
        REQUIRES_RELOAD = 1,
        PROTECTED = 2,
        DEVELOPER = 4,
        HIDDEN = 8,
    },

    -- CVar status colors (unchanged - these are functional)
    COLORS = {
        DEFAULT = { r = 1.0, g = 1.0, b = 1.0 },
        MODIFIED = { r = 1.0, g = 0.9, b = 0.3 },
        DANGEROUS = { r = 1.0, g = 0.3, b = 0.3 },
        CAUTION = { r = 1.0, g = 0.7, b = 0.0 },
        SAFE = { r = 0.3, g = 1.0, b = 0.3 },
        REQUIRES_RELOAD = { r = 0.7, g = 0.7, b = 1.0 },
    },

    -- ==========================================
    -- THEME v1.1 - Softer Green
    -- ==========================================
    THEME = {
        -- Backgrounds (darker, slightly warm)
        BG_PRIMARY     = { 0.09, 0.10, 0.09, 0.97 },   -- Main window
        BG_SECONDARY   = { 0.06, 0.07, 0.06, 0.95 },   -- Sidebar
        BG_TERTIARY    = { 0.12, 0.13, 0.12, 1.0 },    -- Input fields, rows
        BG_HOVER       = { 0.14, 0.18, 0.14, 1.0 },    -- Hover states
        BG_ACTIVE      = { 0.12, 0.22, 0.12, 1.0 },    -- Selected/active
        
        -- Accent colors (softer greens - less neon)
        ACCENT_PRIMARY   = { 0.35, 0.65, 0.40, 1.0 },  -- Main accent
        ACCENT_SECONDARY = { 0.28, 0.52, 0.32, 1.0 },  -- Darker accent
        ACCENT_HIGHLIGHT = { 0.45, 0.78, 0.50, 1.0 },  -- Bright/hover
        ACCENT_MUTED     = { 0.25, 0.42, 0.28, 0.8 },  -- Subtle accent
        
        -- Text colors
        TEXT_PRIMARY   = { 0.88, 0.90, 0.88, 1.0 },    -- Main text
        TEXT_SECONDARY = { 0.62, 0.65, 0.62, 1.0 },    -- Dimmed text
        TEXT_MUTED     = { 0.45, 0.48, 0.45, 1.0 },    -- Disabled/hint
        TEXT_ACCENT    = { 0.55, 0.85, 0.58, 1.0 },    -- Highlighted text
        
        -- Borders (much softer than before)
        BORDER_DEFAULT = { 0.25, 0.32, 0.25, 0.5 },    -- Normal borders
        BORDER_SUBTLE  = { 0.20, 0.25, 0.20, 0.3 },    -- Very subtle
        BORDER_FOCUS   = { 0.40, 0.65, 0.42, 0.7 },    -- Focused element
        BORDER_ACCENT  = { 0.35, 0.55, 0.38, 0.6 },    -- Accent border
        
        -- Title bar
        TITLEBAR_BG    = { 0.12, 0.16, 0.12, 0.98 },   -- Title background
        TITLEBAR_BORDER = { 0.30, 0.45, 0.32, 0.6 },   -- Title border
        
        -- Buttons
        BTN_NORMAL     = { 0.14, 0.16, 0.14, 1.0 },
        BTN_HOVER      = { 0.18, 0.26, 0.18, 1.0 },
        BTN_PRESSED    = { 0.12, 0.20, 0.12, 1.0 },
        BTN_BORDER     = { 0.32, 0.48, 0.35, 0.5 },
        BTN_BORDER_HOVER = { 0.40, 0.62, 0.42, 0.7 },
        
        -- Category list
        CAT_NORMAL     = { 0.65, 0.68, 0.65, 1.0 },    -- Unselected text
        CAT_SELECTED   = { 0.55, 0.85, 0.58, 1.0 },    -- Selected text
        CAT_HOVER_BG   = { 0.15, 0.22, 0.15, 0.6 },    -- Hover background
        CAT_SELECTED_BG = { 0.18, 0.30, 0.18, 0.8 },   -- Selected background
        
        -- Rows (CVar list)
        ROW_ALT        = { 0.08, 0.09, 0.08, 0.4 },    -- Alternating row
        ROW_HOVER      = { 0.15, 0.20, 0.15, 0.6 },    -- Row hover
    },

    -- ==========================================
    -- SPACING v1.1 - More breathing room
    -- ==========================================
    SPACING = {
        XS = 4,    -- Tight: icon to text
        SM = 8,    -- Small: inside buttons
        MD = 12,   -- Medium: between elements
        LG = 16,   -- Large: section padding
        XL = 24,   -- Extra: major sections
    },

    -- GUI dimensions (slightly more generous)
    GUI = {
        WINDOW_WIDTH = 920,
        WINDOW_HEIGHT = 620,
        CATEGORY_WIDTH = 190,
        SEARCH_HEIGHT = 32,
        ROW_HEIGHT = 24,
        PADDING = 12,
        BUTTON_HEIGHT = 28,
        BORDER_SIZE = 1,
    },
}

-- Quick access
CVarMaster.MODES = CVarMaster.Constants.MODES
CVarMaster.TYPES = CVarMaster.Constants.TYPES
CVarMaster.CATEGORIES = CVarMaster.Constants.CATEGORIES
CVarMaster.DANGER_LEVELS = CVarMaster.Constants.DANGER_LEVELS
CVarMaster.THEME = CVarMaster.Constants.THEME
CVarMaster.SPACING = CVarMaster.Constants.SPACING
