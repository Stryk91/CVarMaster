---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.ThemeManager = {}
local TM = CVarMaster.ThemeManager

-- ==========================================
-- PRESET COLOR PALETTES
-- ==========================================
TM.PRESETS = {
    -- Default softer green (current theme)
    ["matrix"] = {
        name = "Matrix Green",
        colors = {
            BG_PRIMARY     = { 0.09, 0.10, 0.09, 0.97 },
            BG_SECONDARY   = { 0.06, 0.07, 0.06, 0.95 },
            BG_TERTIARY    = { 0.12, 0.13, 0.12, 1.0 },
            BG_HOVER       = { 0.14, 0.18, 0.14, 1.0 },
            BG_ACTIVE      = { 0.12, 0.22, 0.12, 1.0 },
            ACCENT_PRIMARY   = { 0.35, 0.65, 0.40, 1.0 },
            ACCENT_SECONDARY = { 0.28, 0.52, 0.32, 1.0 },
            ACCENT_HIGHLIGHT = { 0.45, 0.78, 0.50, 1.0 },
            ACCENT_MUTED     = { 0.25, 0.42, 0.28, 0.8 },
            TEXT_PRIMARY   = { 0.88, 0.90, 0.88, 1.0 },
            TEXT_SECONDARY = { 0.62, 0.65, 0.62, 1.0 },
            TEXT_MUTED     = { 0.45, 0.48, 0.45, 1.0 },
            TEXT_ACCENT    = { 0.55, 0.85, 0.58, 1.0 },
            BORDER_DEFAULT = { 0.25, 0.32, 0.25, 0.5 },
            BORDER_SUBTLE  = { 0.20, 0.25, 0.20, 0.3 },
            BORDER_FOCUS   = { 0.40, 0.65, 0.42, 0.7 },
            BORDER_ACCENT  = { 0.35, 0.55, 0.38, 0.6 },
            TITLEBAR_BG    = { 0.12, 0.16, 0.12, 0.98 },
            TITLEBAR_BORDER = { 0.30, 0.45, 0.32, 0.6 },
            BTN_NORMAL     = { 0.14, 0.16, 0.14, 1.0 },
            BTN_HOVER      = { 0.18, 0.26, 0.18, 1.0 },
            BTN_PRESSED    = { 0.12, 0.20, 0.12, 1.0 },
            BTN_BORDER     = { 0.32, 0.48, 0.35, 0.5 },
            BTN_BORDER_HOVER = { 0.40, 0.62, 0.42, 0.7 },
            CAT_NORMAL     = { 0.65, 0.68, 0.65, 1.0 },
            CAT_SELECTED   = { 0.55, 0.85, 0.58, 1.0 },
            CAT_HOVER_BG   = { 0.15, 0.22, 0.15, 0.6 },
            CAT_SELECTED_BG = { 0.18, 0.30, 0.18, 0.8 },
            ROW_ALT        = { 0.08, 0.09, 0.08, 0.4 },
            ROW_HOVER      = { 0.15, 0.20, 0.15, 0.6 },
        },
    },

    -- Cyberpunk purple/pink
    ["cyberpunk"] = {
        name = "Cyberpunk",
        colors = {
            BG_PRIMARY     = { 0.08, 0.06, 0.12, 0.97 },
            BG_SECONDARY   = { 0.05, 0.04, 0.08, 0.95 },
            BG_TERTIARY    = { 0.12, 0.09, 0.16, 1.0 },
            BG_HOVER       = { 0.18, 0.12, 0.22, 1.0 },
            BG_ACTIVE      = { 0.22, 0.14, 0.28, 1.0 },
            ACCENT_PRIMARY   = { 0.85, 0.25, 0.65, 1.0 },
            ACCENT_SECONDARY = { 0.65, 0.20, 0.50, 1.0 },
            ACCENT_HIGHLIGHT = { 1.0, 0.35, 0.75, 1.0 },
            ACCENT_MUTED     = { 0.55, 0.18, 0.42, 0.8 },
            TEXT_PRIMARY   = { 0.92, 0.88, 0.95, 1.0 },
            TEXT_SECONDARY = { 0.68, 0.62, 0.72, 1.0 },
            TEXT_MUTED     = { 0.48, 0.42, 0.52, 1.0 },
            TEXT_ACCENT    = { 0.95, 0.50, 0.80, 1.0 },
            BORDER_DEFAULT = { 0.35, 0.22, 0.42, 0.5 },
            BORDER_SUBTLE  = { 0.25, 0.18, 0.30, 0.3 },
            BORDER_FOCUS   = { 0.80, 0.30, 0.60, 0.7 },
            BORDER_ACCENT  = { 0.60, 0.25, 0.48, 0.6 },
            TITLEBAR_BG    = { 0.14, 0.10, 0.18, 0.98 },
            TITLEBAR_BORDER = { 0.50, 0.25, 0.45, 0.6 },
            BTN_NORMAL     = { 0.14, 0.10, 0.18, 1.0 },
            BTN_HOVER      = { 0.22, 0.15, 0.28, 1.0 },
            BTN_PRESSED    = { 0.18, 0.12, 0.22, 1.0 },
            BTN_BORDER     = { 0.55, 0.28, 0.48, 0.5 },
            BTN_BORDER_HOVER = { 0.75, 0.35, 0.60, 0.7 },
            CAT_NORMAL     = { 0.72, 0.65, 0.75, 1.0 },
            CAT_SELECTED   = { 0.95, 0.50, 0.80, 1.0 },
            CAT_HOVER_BG   = { 0.22, 0.15, 0.28, 0.6 },
            CAT_SELECTED_BG = { 0.30, 0.18, 0.38, 0.8 },
            ROW_ALT        = { 0.10, 0.07, 0.13, 0.4 },
            ROW_HOVER      = { 0.20, 0.14, 0.26, 0.6 },
        },
    },

    -- Oceanic blue
    ["oceanic"] = {
        name = "Oceanic Blue",
        colors = {
            BG_PRIMARY     = { 0.06, 0.09, 0.12, 0.97 },
            BG_SECONDARY   = { 0.04, 0.06, 0.08, 0.95 },
            BG_TERTIARY    = { 0.08, 0.12, 0.16, 1.0 },
            BG_HOVER       = { 0.10, 0.16, 0.22, 1.0 },
            BG_ACTIVE      = { 0.12, 0.20, 0.28, 1.0 },
            ACCENT_PRIMARY   = { 0.30, 0.60, 0.85, 1.0 },
            ACCENT_SECONDARY = { 0.22, 0.48, 0.68, 1.0 },
            ACCENT_HIGHLIGHT = { 0.40, 0.72, 1.0, 1.0 },
            ACCENT_MUTED     = { 0.20, 0.40, 0.58, 0.8 },
            TEXT_PRIMARY   = { 0.88, 0.92, 0.95, 1.0 },
            TEXT_SECONDARY = { 0.60, 0.68, 0.75, 1.0 },
            TEXT_MUTED     = { 0.42, 0.50, 0.58, 1.0 },
            TEXT_ACCENT    = { 0.50, 0.78, 1.0, 1.0 },
            BORDER_DEFAULT = { 0.22, 0.32, 0.42, 0.5 },
            BORDER_SUBTLE  = { 0.16, 0.24, 0.32, 0.3 },
            BORDER_FOCUS   = { 0.35, 0.60, 0.85, 0.7 },
            BORDER_ACCENT  = { 0.28, 0.50, 0.70, 0.6 },
            TITLEBAR_BG    = { 0.10, 0.14, 0.20, 0.98 },
            TITLEBAR_BORDER = { 0.28, 0.45, 0.62, 0.6 },
            BTN_NORMAL     = { 0.10, 0.14, 0.18, 1.0 },
            BTN_HOVER      = { 0.14, 0.22, 0.30, 1.0 },
            BTN_PRESSED    = { 0.12, 0.18, 0.24, 1.0 },
            BTN_BORDER     = { 0.30, 0.48, 0.65, 0.5 },
            BTN_BORDER_HOVER = { 0.40, 0.62, 0.85, 0.7 },
            CAT_NORMAL     = { 0.65, 0.72, 0.78, 1.0 },
            CAT_SELECTED   = { 0.50, 0.78, 1.0, 1.0 },
            CAT_HOVER_BG   = { 0.14, 0.22, 0.30, 0.6 },
            CAT_SELECTED_BG = { 0.18, 0.28, 0.40, 0.8 },
            ROW_ALT        = { 0.07, 0.10, 0.14, 0.4 },
            ROW_HOVER      = { 0.14, 0.20, 0.28, 0.6 },
        },
    },

    -- Blood red
    ["blood"] = {
        name = "Blood Red",
        colors = {
            BG_PRIMARY     = { 0.10, 0.06, 0.06, 0.97 },
            BG_SECONDARY   = { 0.07, 0.04, 0.04, 0.95 },
            BG_TERTIARY    = { 0.14, 0.08, 0.08, 1.0 },
            BG_HOVER       = { 0.20, 0.10, 0.10, 1.0 },
            BG_ACTIVE      = { 0.26, 0.12, 0.12, 1.0 },
            ACCENT_PRIMARY   = { 0.85, 0.25, 0.25, 1.0 },
            ACCENT_SECONDARY = { 0.65, 0.18, 0.18, 1.0 },
            ACCENT_HIGHLIGHT = { 1.0, 0.35, 0.35, 1.0 },
            ACCENT_MUTED     = { 0.55, 0.18, 0.18, 0.8 },
            TEXT_PRIMARY   = { 0.95, 0.88, 0.88, 1.0 },
            TEXT_SECONDARY = { 0.72, 0.62, 0.62, 1.0 },
            TEXT_MUTED     = { 0.52, 0.42, 0.42, 1.0 },
            TEXT_ACCENT    = { 1.0, 0.50, 0.50, 1.0 },
            BORDER_DEFAULT = { 0.40, 0.22, 0.22, 0.5 },
            BORDER_SUBTLE  = { 0.28, 0.16, 0.16, 0.3 },
            BORDER_FOCUS   = { 0.85, 0.30, 0.30, 0.7 },
            BORDER_ACCENT  = { 0.65, 0.25, 0.25, 0.6 },
            TITLEBAR_BG    = { 0.16, 0.10, 0.10, 0.98 },
            TITLEBAR_BORDER = { 0.55, 0.28, 0.28, 0.6 },
            BTN_NORMAL     = { 0.16, 0.10, 0.10, 1.0 },
            BTN_HOVER      = { 0.24, 0.14, 0.14, 1.0 },
            BTN_PRESSED    = { 0.20, 0.12, 0.12, 1.0 },
            BTN_BORDER     = { 0.58, 0.30, 0.30, 0.5 },
            BTN_BORDER_HOVER = { 0.80, 0.38, 0.38, 0.7 },
            CAT_NORMAL     = { 0.78, 0.68, 0.68, 1.0 },
            CAT_SELECTED   = { 1.0, 0.50, 0.50, 1.0 },
            CAT_HOVER_BG   = { 0.24, 0.14, 0.14, 0.6 },
            CAT_SELECTED_BG = { 0.32, 0.18, 0.18, 0.8 },
            ROW_ALT        = { 0.12, 0.07, 0.07, 0.4 },
            ROW_HOVER      = { 0.22, 0.12, 0.12, 0.6 },
        },
    },

    -- Amber/gold warm theme
    ["amber"] = {
        name = "Amber Gold",
        colors = {
            BG_PRIMARY     = { 0.10, 0.09, 0.06, 0.97 },
            BG_SECONDARY   = { 0.07, 0.06, 0.04, 0.95 },
            BG_TERTIARY    = { 0.14, 0.12, 0.08, 1.0 },
            BG_HOVER       = { 0.20, 0.17, 0.10, 1.0 },
            BG_ACTIVE      = { 0.26, 0.22, 0.12, 1.0 },
            ACCENT_PRIMARY   = { 0.92, 0.72, 0.25, 1.0 },
            ACCENT_SECONDARY = { 0.75, 0.58, 0.20, 1.0 },
            ACCENT_HIGHLIGHT = { 1.0, 0.85, 0.35, 1.0 },
            ACCENT_MUTED     = { 0.62, 0.48, 0.18, 0.8 },
            TEXT_PRIMARY   = { 0.95, 0.92, 0.85, 1.0 },
            TEXT_SECONDARY = { 0.75, 0.70, 0.58, 1.0 },
            TEXT_MUTED     = { 0.55, 0.50, 0.40, 1.0 },
            TEXT_ACCENT    = { 1.0, 0.85, 0.45, 1.0 },
            BORDER_DEFAULT = { 0.42, 0.35, 0.20, 0.5 },
            BORDER_SUBTLE  = { 0.30, 0.25, 0.15, 0.3 },
            BORDER_FOCUS   = { 0.90, 0.70, 0.28, 0.7 },
            BORDER_ACCENT  = { 0.70, 0.55, 0.22, 0.6 },
            TITLEBAR_BG    = { 0.16, 0.14, 0.08, 0.98 },
            TITLEBAR_BORDER = { 0.60, 0.48, 0.25, 0.6 },
            BTN_NORMAL     = { 0.16, 0.14, 0.10, 1.0 },
            BTN_HOVER      = { 0.24, 0.20, 0.14, 1.0 },
            BTN_PRESSED    = { 0.20, 0.17, 0.12, 1.0 },
            BTN_BORDER     = { 0.62, 0.50, 0.28, 0.5 },
            BTN_BORDER_HOVER = { 0.85, 0.68, 0.35, 0.7 },
            CAT_NORMAL     = { 0.80, 0.75, 0.62, 1.0 },
            CAT_SELECTED   = { 1.0, 0.85, 0.45, 1.0 },
            CAT_HOVER_BG   = { 0.24, 0.20, 0.12, 0.6 },
            CAT_SELECTED_BG = { 0.32, 0.26, 0.16, 0.8 },
            ROW_ALT        = { 0.12, 0.10, 0.06, 0.4 },
            ROW_HOVER      = { 0.22, 0.18, 0.10, 0.6 },
        },
    },

    -- Minimal light theme
    ["light"] = {
        name = "Light Mode",
        colors = {
            BG_PRIMARY     = { 0.92, 0.92, 0.90, 0.98 },
            BG_SECONDARY   = { 0.88, 0.88, 0.86, 0.96 },
            BG_TERTIARY    = { 0.96, 0.96, 0.94, 1.0 },
            BG_HOVER       = { 0.85, 0.88, 0.85, 1.0 },
            BG_ACTIVE      = { 0.80, 0.85, 0.80, 1.0 },
            ACCENT_PRIMARY   = { 0.20, 0.55, 0.28, 1.0 },
            ACCENT_SECONDARY = { 0.15, 0.42, 0.22, 1.0 },
            ACCENT_HIGHLIGHT = { 0.25, 0.65, 0.32, 1.0 },
            ACCENT_MUTED     = { 0.30, 0.50, 0.35, 0.6 },
            TEXT_PRIMARY   = { 0.15, 0.15, 0.15, 1.0 },
            TEXT_SECONDARY = { 0.40, 0.40, 0.40, 1.0 },
            TEXT_MUTED     = { 0.60, 0.60, 0.60, 1.0 },
            TEXT_ACCENT    = { 0.15, 0.50, 0.22, 1.0 },
            BORDER_DEFAULT = { 0.70, 0.72, 0.70, 0.6 },
            BORDER_SUBTLE  = { 0.80, 0.82, 0.80, 0.4 },
            BORDER_FOCUS   = { 0.25, 0.60, 0.32, 0.8 },
            BORDER_ACCENT  = { 0.30, 0.55, 0.35, 0.7 },
            TITLEBAR_BG    = { 0.85, 0.86, 0.84, 0.98 },
            TITLEBAR_BORDER = { 0.60, 0.65, 0.60, 0.6 },
            BTN_NORMAL     = { 0.88, 0.88, 0.86, 1.0 },
            BTN_HOVER      = { 0.82, 0.85, 0.82, 1.0 },
            BTN_PRESSED    = { 0.78, 0.80, 0.78, 1.0 },
            BTN_BORDER     = { 0.60, 0.65, 0.60, 0.5 },
            BTN_BORDER_HOVER = { 0.30, 0.55, 0.35, 0.7 },
            CAT_NORMAL     = { 0.35, 0.35, 0.35, 1.0 },
            CAT_SELECTED   = { 0.15, 0.50, 0.22, 1.0 },
            CAT_HOVER_BG   = { 0.82, 0.85, 0.82, 0.6 },
            CAT_SELECTED_BG = { 0.78, 0.85, 0.78, 0.8 },
            ROW_ALT        = { 0.90, 0.90, 0.88, 0.4 },
            ROW_HOVER      = { 0.82, 0.85, 0.82, 0.6 },
        },
    },
}

-- ==========================================
-- FONT SETTINGS
-- ==========================================
TM.AVAILABLE_FONTS = {
    { name = "Fritz Quadrata (Default)", path = "Fonts\\FRIZQT__.TTF" },
    { name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
    { name = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
    { name = "Skurri", path = "Fonts\\SKURRI.TTF" },
    { name = "2002", path = "Fonts\\2002.TTF" },
    { name = "2002 Bold", path = "Fonts\\2002B.TTF" },
    { name = "Expressway", path = "Fonts\\EXPRESSWAY.TTF" },
    { name = "Nimrod", path = "Fonts\\NIM_____.TTF" },
}

TM.FONT_FLAGS = {
    { name = "None", flag = "" },
    { name = "Outline", flag = "OUTLINE" },
    { name = "Thick Outline", flag = "THICKOUTLINE" },
    { name = "Monochrome", flag = "MONOCHROME" },
    { name = "Outline + Mono", flag = "OUTLINE, MONOCHROME" },
}

-- Default font settings
TM.DEFAULT_FONT_SETTINGS = {
    face = "Fonts\\FRIZQT__.TTF",
    size = 12,
    flags = "OUTLINE",
    shadowOffsetX = 1,
    shadowOffsetY = -1,
    shadowColorR = 0,
    shadowColorG = 0,
    shadowColorB = 0,
    shadowColorA = 0.8,
}

-- Font objects we create and manage
TM.FontObjects = {}

-- ==========================================
-- INITIALIZATION
-- ==========================================
function TM:Initialize()
    -- Ensure DB exists
    if not CVarMasterDB then CVarMasterDB = {} end
    if not CVarMasterDB.theme then
        CVarMasterDB.theme = {
            preset = "matrix",
            customColors = {},
            font = TM.DEFAULT_FONT_SETTINGS,
        }
    end

    -- Ensure font settings exist
    if not CVarMasterDB.theme.font then
        CVarMasterDB.theme.font = TM.DEFAULT_FONT_SETTINGS
    end

    -- Create font objects
    self:CreateFontObjects()

    -- Apply saved theme
    self:ApplyTheme()
end

-- ==========================================
-- FONT OBJECT MANAGEMENT
-- ==========================================
function TM:CreateFontObjects()
    local settings = self:GetFontSettings()

    -- Create different size variants
    local sizes = {
        { name = "CVarMasterFont_Small", mult = 0.85 },
        { name = "CVarMasterFont_Normal", mult = 1.0 },
        { name = "CVarMasterFont_Large", mult = 1.25 },
        { name = "CVarMasterFont_Header", mult = 1.5 },
    }

    for _, sizeInfo in ipairs(sizes) do
        local fontObj = _G[sizeInfo.name]
        if not fontObj then
            fontObj = CreateFont(sizeInfo.name)
        end

        local size = math.floor(settings.size * sizeInfo.mult)
        fontObj:SetFont(settings.face, size, settings.flags)
        fontObj:SetShadowOffset(settings.shadowOffsetX, settings.shadowOffsetY)
        fontObj:SetShadowColor(
            settings.shadowColorR,
            settings.shadowColorG,
            settings.shadowColorB,
            settings.shadowColorA
        )

        self.FontObjects[sizeInfo.name] = fontObj
    end
end

function TM:UpdateFontObjects()
    local settings = self:GetFontSettings()

    local sizes = {
        { name = "CVarMasterFont_Small", mult = 0.85 },
        { name = "CVarMasterFont_Normal", mult = 1.0 },
        { name = "CVarMasterFont_Large", mult = 1.25 },
        { name = "CVarMasterFont_Header", mult = 1.5 },
    }

    for _, sizeInfo in ipairs(sizes) do
        local fontObj = self.FontObjects[sizeInfo.name] or _G[sizeInfo.name]
        if fontObj then
            local size = math.floor(settings.size * sizeInfo.mult)
            fontObj:SetFont(settings.face, size, settings.flags)
            fontObj:SetShadowOffset(settings.shadowOffsetX, settings.shadowOffsetY)
            fontObj:SetShadowColor(
                settings.shadowColorR,
                settings.shadowColorG,
                settings.shadowColorB,
                settings.shadowColorA
            )
        end
    end

    -- Refresh all registered font strings
    self:RefreshAllFonts()
end

-- Registry of font strings to update
TM.RegisteredFontStrings = {}

function TM:RegisterFontString(fontString, sizeType)
    if fontString then
        table.insert(self.RegisteredFontStrings, { fs = fontString, size = sizeType or "Normal" })
    end
end

function TM:RefreshAllFonts()
    -- Font objects auto-propagate to font strings using SetFontObject
    -- We only need to update the font objects themselves (done in UpdateFontObjects)
    -- No need to rebuild UI - just let WoW handle the propagation
end

function TM:GetFontObject(sizeType)
    local fontName = "CVarMasterFont_" .. (sizeType or "Normal")
    return self.FontObjects[fontName] or _G[fontName] or GameFontNormal
end

-- ==========================================
-- THEME APPLICATION
-- ==========================================
function TM:GetCurrentPreset()
    if CVarMasterDB and CVarMasterDB.theme then
        return CVarMasterDB.theme.preset or "matrix"
    end
    return "matrix"
end

function TM:GetThemeColor(key)
    local preset = self:GetCurrentPreset()
    local presetData = self.PRESETS[preset]

    -- Check custom colors first
    if CVarMasterDB and CVarMasterDB.theme and CVarMasterDB.theme.customColors and CVarMasterDB.theme.customColors[key] then
        return unpack(CVarMasterDB.theme.customColors[key])
    end

    -- Then preset colors
    if presetData and presetData.colors and presetData.colors[key] then
        return unpack(presetData.colors[key])
    end

    -- Fallback
    return 0.5, 0.5, 0.5, 1.0
end

function TM:SetPreset(presetName)
    if not self.PRESETS[presetName] then
        print("|cff00aaffCVarMaster:|r Unknown theme preset: " .. tostring(presetName))
        return false
    end

    if CVarMasterDB and CVarMasterDB.theme then
        CVarMasterDB.theme.preset = presetName
        CVarMasterDB.theme.customColors = {} -- Clear custom overrides
        self:ApplyTheme()
        print("|cff00aaffCVarMaster:|r Theme changed to " .. self.PRESETS[presetName].name)
        return true
    end
    return false
end

function TM:SetCustomColor(key, r, g, b, a)
    if CVarMasterDB and CVarMasterDB.theme then
        CVarMasterDB.theme.customColors = CVarMasterDB.theme.customColors or {}
        CVarMasterDB.theme.customColors[key] = { r, g, b, a or 1.0 }
        self:ApplyTheme()
    end
end

function TM:ResetCustomColors()
    if CVarMasterDB and CVarMasterDB.theme then
        CVarMasterDB.theme.customColors = {}
        self:ApplyTheme()
        print("|cff00aaffCVarMaster:|r Custom colors reset")
    end
end

-- ==========================================
-- FONT MANAGEMENT
-- ==========================================
function TM:GetFontSettings()
    if CVarMasterDB and CVarMasterDB.theme and CVarMasterDB.theme.font then
        return CVarMasterDB.theme.font
    end
    return TM.DEFAULT_FONT_SETTINGS
end

function TM:SetFontFace(path)
    if CVarMasterDB and CVarMasterDB.theme then
        CVarMasterDB.theme.font = CVarMasterDB.theme.font or {}
        CVarMasterDB.theme.font.face = path
        self:UpdateFontObjects()
    end
end

function TM:SetFontSize(size)
    size = math.max(8, math.min(24, size)) -- Clamp 8-24
    if CVarMasterDB and CVarMasterDB.theme then
        CVarMasterDB.theme.font = CVarMasterDB.theme.font or {}
        CVarMasterDB.theme.font.size = size
        self:UpdateFontObjects()
    end
end

function TM:SetFontFlags(flags)
    if CVarMasterDB and CVarMasterDB.theme then
        CVarMasterDB.theme.font = CVarMasterDB.theme.font or {}
        CVarMasterDB.theme.font.flags = flags
        self:UpdateFontObjects()
    end
end

function TM:SetFontShadow(offsetX, offsetY, r, g, b, a)
    if CVarMasterDB and CVarMasterDB.theme then
        CVarMasterDB.theme.font = CVarMasterDB.theme.font or {}
        CVarMasterDB.theme.font.shadowOffsetX = offsetX
        CVarMasterDB.theme.font.shadowOffsetY = offsetY
        CVarMasterDB.theme.font.shadowColorR = r or 0
        CVarMasterDB.theme.font.shadowColorG = g or 0
        CVarMasterDB.theme.font.shadowColorB = b or 0
        CVarMasterDB.theme.font.shadowColorA = a or 0.8
        self:UpdateFontObjects()
    end
end

function TM:ResetFontSettings()
    if CVarMasterDB and CVarMasterDB.theme then
        CVarMasterDB.theme.font = TM.DEFAULT_FONT_SETTINGS
        self:UpdateFontObjects()
        print("|cff00aaffCVarMaster:|r Font settings reset to default")
    end
end

function TM:GetFontFaceName()
    local settings = self:GetFontSettings()
    for _, font in ipairs(self.AVAILABLE_FONTS) do
        if font.path == settings.face then
            return font.name
        end
    end
    return "Unknown"
end

-- ==========================================
-- APPLY THEME TO UI
-- ==========================================
function TM:ApplyTheme()
    -- Update Constants.THEME with current colors
    if CVarMaster.Constants then
        local preset = self:GetCurrentPreset()
        local presetData = self.PRESETS[preset]

        if presetData and presetData.colors then
            for key, color in pairs(presetData.colors) do
                CVarMaster.Constants.THEME[key] = color
            end
        end

        -- Apply custom overrides
        if CVarMasterDB and CVarMasterDB.theme and CVarMasterDB.theme.customColors then
            for key, color in pairs(CVarMasterDB.theme.customColors) do
                CVarMaster.Constants.THEME[key] = color
            end
        end
    end

    -- Refresh main window if it exists
    if CVarMaster.MainWindow and CVarMaster.MainWindow.frame and CVarMaster.MainWindow.frame:IsShown() then
        CVarMaster.MainWindow:RefreshTheme()
    end

    -- Fire callback for other modules
    if CVarMaster.Callbacks then
        CVarMaster.Callbacks:Fire("THEME_CHANGED")
    end
end

-- ==========================================
-- CREATE CUSTOM FONT OBJECT
-- ==========================================
function TM:CreateFont(name, sizeMultiplier)
    local settings = self:GetFontSettings()
    local font = CreateFont(name)

    local size = settings.size * (sizeMultiplier or 1)
    font:SetFont(settings.face, size, settings.flags)
    font:SetShadowOffset(settings.shadowOffsetX, settings.shadowOffsetY)
    font:SetShadowColor(
        settings.shadowColorR,
        settings.shadowColorG,
        settings.shadowColorB,
        settings.shadowColorA
    )

    return font
end

-- ==========================================
-- UTILITY - LIST PRESETS
-- ==========================================
function TM:GetPresetList()
    local list = {}
    for key, preset in pairs(self.PRESETS) do
        table.insert(list, { key = key, name = preset.name })
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- ==========================================
-- SLASH COMMAND HANDLERS
-- ==========================================
function TM:HandleSlashCommand(args)
    local cmd, arg1, arg2 = strsplit(" ", args, 3)
    cmd = cmd and cmd:lower() or ""

    if cmd == "list" then
        print("|cff00aaffCVarMaster Themes:|r")
        local current = self:GetCurrentPreset()
        for _, preset in ipairs(self:GetPresetList()) do
            local marker = (preset.key == current) and " |cff00ff00[ACTIVE]|r" or ""
            print("  " .. preset.name .. " (" .. preset.key .. ")" .. marker)
        end

    elseif cmd == "set" and arg1 then
        self:SetPreset(arg1:lower())

    elseif cmd == "font" then
        if arg1 == "size" and arg2 then
            local size = tonumber(arg2)
            if size then
                self:SetFontSize(size)
                print("|cff00aaffCVarMaster:|r Font size set to " .. size)
            end
        elseif arg1 == "reset" then
            self:ResetFontSettings()
        else
            local settings = self:GetFontSettings()
            print("|cff00aaffCVarMaster Font Settings:|r")
            print("  Size: " .. settings.size)
            print("  Flags: " .. (settings.flags ~= "" and settings.flags or "None"))
            print("  Shadow: " .. settings.shadowOffsetX .. ", " .. settings.shadowOffsetY)
        end

    elseif cmd == "reset" then
        self:SetPreset("matrix")
        self:ResetFontSettings()
        print("|cff00aaffCVarMaster:|r Theme fully reset to defaults")

    else
        print("|cff00aaffCVarMaster Theme Commands:|r")
        print("  /cvm theme list - Show available themes")
        print("  /cvm theme set <name> - Apply a theme")
        print("  /cvm theme font - Show font settings")
        print("  /cvm theme font size <n> - Set font size (8-24)")
        print("  /cvm theme font reset - Reset font to default")
        print("  /cvm theme reset - Reset everything to default")
    end
end
