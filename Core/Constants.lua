---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

-- Single source of truth for the version is the TOC's "## Version:" field.
-- Reading it back here keeps every display (main GUI title, tooltip, exported
-- profiles) in lockstep with the TOC automatically — no second number to bump.
local TOC_VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata
    and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")) or "0.0.0"

CVarMaster.Constants = {
    VERSION = TOC_VERSION,

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
        NEW_12 = "New in 12.0",
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
    -- THEME v2.0 - Neutral Slate
    -- ==========================================
    THEME = {
        -- Backgrounds (deep dark)
        BG_PRIMARY     = { 0.055, 0.045, 0.095, 0.15 },  -- Main window - very transparent for void
        BG_SECONDARY   = { 0.040, 0.032, 0.075, 0.2 },   -- Sidebar - transparent for void
        BG_TERTIARY    = { 0.075, 0.065, 0.130, 0.25 },  -- Input fields, rows - transparent for void
        BG_HOVER       = { 0.095, 0.080, 0.165, 0.4 },   -- Hover states - semi-transparent
        BG_ACTIVE      = { 0.110, 0.085, 0.200, 0.5 },   -- Selected/active

        -- Accent colors (neutral slate)
        ACCENT_PRIMARY   = { 0.45, 0.50, 0.55, 1.0 },   -- Slate accent
        ACCENT_SECONDARY = { 0.35, 0.40, 0.45, 1.0 },   -- Darker slate
        ACCENT_HIGHLIGHT = { 0.62, 0.50, 0.95, 1.0 },   -- Bright glow
        ACCENT_MUTED     = { 0.30, 0.34, 0.38, 0.7 },   -- Subtle slate
        ACCENT_COPPER    = { 0.70, 0.50, 0.35, 1.0 },   -- Copper/bronze accent

        -- Text colors
        TEXT_PRIMARY   = { 0.90, 0.90, 0.92, 1.0 },    -- Clean white
        TEXT_SECONDARY = { 0.60, 0.62, 0.65, 1.0 },    -- Muted grey
        TEXT_MUTED     = { 0.42, 0.38, 0.52, 1.0 },    -- Disabled/hint
        TEXT_ACCENT    = { 0.70, 0.75, 0.80, 1.0 },    -- Highlighted slate

        -- Borders (subtle slate)
        BORDER_DEFAULT = { 0.28, 0.24, 0.45, 0.5 },    -- Normal borders
        BORDER_SUBTLE  = { 0.20, 0.18, 0.35, 0.3 },    -- Very subtle
        BORDER_FOCUS   = { 0.50, 0.55, 0.60, 0.8 },    -- Focused - slate
        BORDER_ACCENT  = { 0.50, 0.40, 0.75, 0.6 },    -- Accent border

        -- Title bar - semi-transparent for void
        TITLEBAR_BG    = { 0.070, 0.055, 0.120, 0.2 },  -- Let void show through
        TITLEBAR_BORDER = { 0.35, 0.38, 0.42, 0.4 },    -- Subtle slate border

        -- Buttons - semi-transparent for void
        BTN_NORMAL     = { 0.085, 0.070, 0.150, 0.6 },
        BTN_HOVER      = { 0.120, 0.095, 0.210, 0.75 },
        BTN_PRESSED    = { 0.150, 0.115, 0.260, 0.85 },
        BTN_BORDER     = { 0.38, 0.30, 0.60, 0.5 },
        BTN_BORDER_HOVER = { 0.55, 0.45, 0.85, 0.8 },

        -- Category list
        CAT_NORMAL     = { 0.68, 0.64, 0.78, 1.0 },    -- Unselected text
        CAT_SELECTED   = { 0.75, 0.78, 0.82, 1.0 },    -- Selected - bright slate
        CAT_HOVER_BG   = { 0.10, 0.08, 0.18, 0.35 },   -- Hover - more transparent
        CAT_SELECTED_BG = { 0.14, 0.11, 0.26, 0.5 },   -- Selected - semi-transparent

        -- Rows (CVar list)
        ROW_ALT        = { 0.06, 0.05, 0.11, 0.2 },    -- Alternating row - subtle
        ROW_HOVER      = { 0.12, 0.09, 0.22, 0.4 },    -- Row hover

        -- Glow/effects
        GLOW_PRIMARY   = { 0.45, 0.50, 0.55, 0.4 },    -- Slate glow overlay
        GLOW_HIGHLIGHT = { 0.65, 0.55, 1.00, 0.3 },    -- Bright highlight
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

    -- Custom textures
    TEXTURES = {
        PATH = "Interface\\AddOns\\CVarMaster\\Textures\\",
        -- Panels
        PANEL_BG = "Interface\\AddOns\\CVarMaster\\Textures\\panel_background",
        SIDEBAR = "Interface\\AddOns\\CVarMaster\\Textures\\sidebar_panel",
        TOOLTIP = "Interface\\AddOns\\CVarMaster\\Textures\\tooltip_panel",
        HEADER_BAR = "Interface\\AddOns\\CVarMaster\\Textures\\header_bar",
        -- Buttons
        BTN_PRIMARY = "Interface\\AddOns\\CVarMaster\\Textures\\button_primary",
        BTN_GHOST = "Interface\\AddOns\\CVarMaster\\Textures\\button_ghost",
        BTN_DANGER = "Interface\\AddOns\\CVarMaster\\Textures\\button_danger",
        -- UI Elements
        INPUT_FIELD = "Interface\\AddOns\\CVarMaster\\Textures\\input_fields",
        ROW = "Interface\\AddOns\\CVarMaster\\Textures\\row_elements",
        SCROLLBAR = "Interface\\AddOns\\CVarMaster\\Textures\\scrollbar",
    },
}

-- Quick access
CVarMaster.MODES = CVarMaster.Constants.MODES
CVarMaster.TYPES = CVarMaster.Constants.TYPES
CVarMaster.CATEGORIES = CVarMaster.Constants.CATEGORIES
CVarMaster.DANGER_LEVELS = CVarMaster.Constants.DANGER_LEVELS
CVarMaster.THEME = CVarMaster.Constants.THEME
CVarMaster.SPACING = CVarMaster.Constants.SPACING
