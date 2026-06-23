---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.ThemeManager = {}
local TM = CVarMaster.ThemeManager

-- ==========================================

-- ==========================================
-- FONT SETTINGS
-- ==========================================
-- Bundled font (ships with CVarMaster)
local BUNDLED_FONT = "Interface\\AddOns\\CVarMaster\\Fonts\\Kanit-Medium.ttf"

-- Available fonts (bundled first, then WoW built-ins)
TM.AVAILABLE_FONTS = {
    { name = "Kanit Medium", path = BUNDLED_FONT },
    { name = "Fritz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
    { name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
    { name = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
    { name = "Skurri", path = "Fonts\\SKURRI.TTF" },
    { name = "2002", path = "Fonts\\2002.TTF" },
    { name = "2002 Bold", path = "Fonts\\2002B.TTF" },
    { name = "Expressway", path = "Fonts\\EXPRESSWAY.TTF" },
    { name = "Nimrod", path = "Fonts\\NIM_____.TTF" },
}

-- Custom fonts from SharedMedia_MyMedia
local SMAF_PATH = "Interface\\AddOns\\SharedMedia_MyMedia\\font\\"
local CUSTOM_FONTS = {
    { name = "Accidental Presidency", path = SMAF_PATH .. "Accidental Presidency.ttf" },
    { name = "Action Man", path = SMAF_PATH .. "ActionMan.ttf" },
    { name = "Albas", path = SMAF_PATH .. "ALBAS___.ttf" },
    { name = "Arm Wrestler", path = SMAF_PATH .. "ArmWrestler.ttf" },
    { name = "Baars", path = SMAF_PATH .. "BAARS___.TTF" },
    { name = "Blazed", path = SMAF_PATH .. "Blazed.ttf" },
    { name = "Boris Black Bloxx", path = SMAF_PATH .. "BorisBlackBloxx.ttf" },
    { name = "Boris Black Bloxx Dirty", path = SMAF_PATH .. "BorisBlackBloxxDirty.ttf" },
    { name = "Collegia", path = SMAF_PATH .. "COLLEGIA.ttf" },
    { name = "Continuum Medium", path = SMAF_PATH .. "ContinuumMedium.ttf" },
    { name = "DejaVu Sans", path = SMAF_PATH .. "DejaVuSans.ttf" },
    { name = "DejaVu Sans Bold", path = SMAF_PATH .. "DejaVuSans-Bold.ttf" },
    { name = "Die Die Die", path = SMAF_PATH .. "DieDieDie.ttf" },
    { name = "Diogenes", path = SMAF_PATH .. "DIOGENES.ttf" },
    { name = "Disko", path = SMAF_PATH .. "Disko.ttf" },
    { name = "Expressway Bold", path = SMAF_PATH .. "Expressway-Bold.ttf" },
    { name = "Homespun", path = SMAF_PATH .. "Homespun.ttf" },
    { name = "Impact", path = SMAF_PATH .. "impact.ttf" },
    { name = "Kanit Black", path = SMAF_PATH .. "Kanit-Black.ttf" },
    { name = "Kanit Bold", path = SMAF_PATH .. "Kanit-Bold.ttf" },
    { name = "Kanit ExtraBold", path = SMAF_PATH .. "Kanit-ExtraBold.ttf" },
    { name = "Kanit Light", path = SMAF_PATH .. "Kanit-Light.ttf" },
    { name = "Kanit SemiBold", path = SMAF_PATH .. "Kanit-SemiBold.ttf" },
    { name = "Liberation Sans", path = SMAF_PATH .. "LiberationSans-Regular.ttf" },
    { name = "Liberation Serif", path = SMAF_PATH .. "LiberationSerif-Regular.ttf" },
    { name = "Mystik Orbs", path = SMAF_PATH .. "MystikOrbs.ttf" },
    { name = "Pokemon Solid", path = SMAF_PATH .. "Pokemon Solid.ttf" },
    { name = "PT Sans Narrow Bold", path = SMAF_PATH .. "PTSansNarrow-Bold.ttf" },
    { name = "Rock Show Whiplash", path = SMAF_PATH .. "Rock Show Whiplash.ttf" },
    { name = "SF Diego Sans", path = SMAF_PATH .. "SF Diego Sans.ttf" },
    { name = "Solange", path = SMAF_PATH .. "Solange.ttf" },
    { name = "Starcine", path = SMAF_PATH .. "starcine.ttf" },
    { name = "Trashco", path = SMAF_PATH .. "trashco.ttf" },
    { name = "Ubuntu Condensed", path = SMAF_PATH .. "Ubuntu-C.ttf" },
    { name = "Ubuntu Light", path = SMAF_PATH .. "Ubuntu-L.ttf" },
    { name = "Verdana", path = SMAF_PATH .. "Verdana.ttf" },
    { name = "Waltograph UI", path = SMAF_PATH .. "waltographUI.ttf" },
    { name = "X360", path = SMAF_PATH .. "X360.ttf" },
    { name = "Yanone Kaffeesatz", path = SMAF_PATH .. "YanoneKaffeesatz-Regular.ttf" },
}

-- Custom fonts live in the SharedMedia_MyMedia addon's font folder. Show them only
-- if that addon is installed — it need NOT be enabled, since WoW loads the .ttf files
-- by path regardless of load state. (A per-font SetFont probe proved unreliable: WoW
-- loads TTFs lazily, so cold fonts report as missing even when the file is present.)
local function IsAddOnInstalled(name)
    local getInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
    if not getInfo then return false end
    local found, _, _, _, reason = getInfo(name)
    return found ~= nil and reason ~= "MISSING"
end

if IsAddOnInstalled("SharedMedia_MyMedia") then
    for _, font in ipairs(CUSTOM_FONTS) do
        table.insert(TM.AVAILABLE_FONTS, font)
    end
end

TM.FONT_FLAGS = {
    { name = "None", flag = "" },
    { name = "Outline", flag = "OUTLINE" },
    { name = "Thick Outline", flag = "THICKOUTLINE" },
    { name = "Monochrome", flag = "MONOCHROME" },
    { name = "Outline + Mono", flag = "OUTLINE, MONOCHROME" },
}

-- Default font settings
TM.DEFAULT_FONT_SETTINGS = {
    face = "Interface\\AddOns\\CVarMaster\\Fonts\\Kanit-Medium.ttf",
    size = 15,
    flags = "",
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
    -- Use the addon's single saved-variables table. NEVER create a fresh one here:
    -- doing so binds the GLOBAL CVarMasterDB to a different table than CVarMaster.db,
    -- which silently drops profiles (they're written through CVarMaster.db but WoW
    -- serializes the global). CVarMaster.lua binds CVarMaster.db before calling us,
    -- so this just re-points the global at that same table as a safety net.
    CVarMasterDB = CVarMaster.db or CVarMasterDB or {}
    CVarMaster.db = CVarMasterDB
    if not CVarMasterDB.theme then
        CVarMasterDB.theme = {
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
    local settings = self:GetFontSettings()
    CVarMaster.GUI:RefreshFonts(settings)
end

function TM:GetFontObject(sizeType)
    local fontName = "CVarMasterFont_" .. (sizeType or "Normal")
    return self.FontObjects[fontName] or _G[fontName] or GameFontNormal
end

-- ==========================================
-- THEME APPLICATION
-- ==========================================

function TM:GetThemeColor(key)
    if CVarMaster.Constants and CVarMaster.Constants.THEME and CVarMaster.Constants.THEME[key] then
        return unpack(CVarMaster.Constants.THEME[key])
    end
    return 0.5, 0.5, 0.5, 1.0
end


-- ==========================================
-- FONT MANAGEMENT
-- ==========================================
function TM:GetFontSettings()
    local d = TM.DEFAULT_FONT_SETTINGS
    if CVarMasterDB and CVarMasterDB.theme and CVarMasterDB.theme.font then
        local s = CVarMasterDB.theme.font
        -- Migrate old SharedMedia Kanit path to bundled version
        local face = s.face or d.face
        if face and face:find("SharedMedia") and face:find("Kanit%-Medium") then
            face = "Interface\\AddOns\\CVarMaster\\Fonts\\Kanit-Medium.ttf"
            s.face = face -- persist migration
        end
        return {
            face = face,
            size = s.size or d.size,
            flags = s.flags or d.flags,
            shadowOffsetX = s.shadowOffsetX or d.shadowOffsetX,
            shadowOffsetY = s.shadowOffsetY or d.shadowOffsetY,
            shadowColorR = s.shadowColorR or d.shadowColorR,
            shadowColorG = s.shadowColorG or d.shadowColorG,
            shadowColorB = s.shadowColorB or d.shadowColorB,
            shadowColorA = s.shadowColorA or d.shadowColorA,
        }
    end
    return d
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
    -- Constants.THEME is the source of truth - no overrides needed

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
-- SLASH COMMAND HANDLERS
-- ==========================================
function TM:HandleSlashCommand(args)
    local cmd, arg1, arg2 = strsplit(" ", args, 3)
    cmd = cmd and cmd:lower() or ""

    if cmd == "font" then
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
        self:ResetFontSettings()
        print("|cff00aaffCVarMaster:|r Font settings reset to defaults")

    else
        print("|cff00aaffCVarMaster Theme Commands:|r")
        print("  /cvm theme font - Show font settings")
        print("  /cvm theme font size <n> - Set font size")
        print("  /cvm theme font reset - Reset font")
        print("  /cvm theme reset - Reset all theme settings")
    end
end
