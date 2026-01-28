---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local TM = CVarMaster.ThemeManager

local ThemeWindow = nil

-- Local theme helper (with ThemeManager support)
local function T(key)
    if CVarMaster.ThemeManager and CVarMaster.ThemeManager.GetThemeColor then
        return CVarMaster.ThemeManager:GetThemeColor(key)
    end
    if CVarMaster.Constants and CVarMaster.Constants.THEME and CVarMaster.Constants.THEME[key] then
        return unpack(CVarMaster.Constants.THEME[key])
    end
    return 0.5, 0.5, 0.5, 1.0
end

local function S(key)
    if CVarMaster.Constants and CVarMaster.Constants.SPACING then
        return CVarMaster.Constants.SPACING[key] or 8
    end
    return 8
end

-- ==========================================
-- PRESET ROW COMPONENT
-- ==========================================
local function CreatePresetRow(parent, presetKey, presetData, yOffset, isActive)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(52)
    row:SetPoint("TOPLEFT", 0, yOffset)
    row:SetPoint("TOPRIGHT", 0, yOffset)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })

    local bgColor = isActive and { 0.12, 0.16, 0.12, 1 } or { 0.06, 0.06, 0.08, 0.9 }
    local borderColor = isActive and { 0.35, 0.65, 0.40, 0.8 } or { 0.15, 0.15, 0.18, 1 }

    row:SetBackdropColor(unpack(bgColor))
    row:SetBackdropBorderColor(unpack(borderColor))

    -- Hover effect
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        if not isActive then
            self:SetBackdropColor(0.1, 0.12, 0.15, 1)
            self:SetBackdropBorderColor(0, 0.5, 0.8, 0.6)
        end
    end)
    row:SetScript("OnLeave", function(self)
        if not isActive then
            self:SetBackdropColor(unpack(bgColor))
            self:SetBackdropBorderColor(unpack(borderColor))
        end
    end)

    -- Color swatches showing theme colors
    local swatchContainer = CreateFrame("Frame", nil, row)
    swatchContainer:SetSize(80, 24)
    swatchContainer:SetPoint("LEFT", 10, 0)

    local colors = presetData.colors
    local swatchColors = {
        colors.ACCENT_PRIMARY,
        colors.BG_PRIMARY,
        colors.TEXT_ACCENT,
        colors.BORDER_FOCUS,
    }

    for i, color in ipairs(swatchColors) do
        local swatch = swatchContainer:CreateTexture(nil, "ARTWORK")
        swatch:SetSize(16, 16)
        swatch:SetPoint("LEFT", (i - 1) * 18, 0)
        swatch:SetColorTexture(color[1], color[2], color[3], 1)

        local border = swatchContainer:CreateTexture(nil, "BORDER")
        border:SetSize(18, 18)
        border:SetPoint("CENTER", swatch, "CENTER", 0, 0)
        border:SetColorTexture(0.2, 0.2, 0.2, 1)
    end

    -- Preset name
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", swatchContainer, "RIGHT", 12, 0)
    nameText:SetText(presetData.name)
    nameText:SetTextColor(0.85, 0.95, 0.85)

    -- Active indicator
    if isActive then
        local activeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        activeText:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
        activeText:SetText("|cff00ff00[ACTIVE]|r")
    end

    -- Apply button
    local applyBtn = GUI:CreateButton(nil, row, isActive and "Active" or "Apply", 70, 26)
    applyBtn:SetPoint("RIGHT", -10, 0)

    if isActive then
        applyBtn:SetBackdropBorderColor(0.3, 0.6, 0.3, 0.8)
        applyBtn.text:SetTextColor(0.5, 0.9, 0.5)
        applyBtn:SetScript("OnClick", nil)
    else
        applyBtn:SetBackdropBorderColor(0.2, 0.4, 0.6, 0.8)
        applyBtn:SetScript("OnClick", function()
            TM:SetPreset(presetKey)
            GUI:RefreshThemeList()
        end)
        applyBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.1, 0.2, 0.35, 1)
            self:SetBackdropBorderColor(0.3, 0.5, 0.8, 1)
            self.text:SetTextColor(0.5, 0.7, 1)
        end)
        applyBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(T("BTN_NORMAL"))
            self:SetBackdropBorderColor(0.2, 0.4, 0.6, 0.8)
            self.text:SetTextColor(T("TEXT_PRIMARY"))
        end)
    end

    return row
end

-- ==========================================
-- FONT SETTINGS SECTION
-- ==========================================
local function CreateFontSection(parent)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section:SetHeight(270)
    section:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    section:SetBackdropColor(0.05, 0.05, 0.07, 1)
    section:SetBackdropBorderColor(0.2, 0.25, 0.3, 1)

    -- Header
    local header = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 12, -10)
    header:SetText("|cff00ccffFont Settings|r")

    local settings = TM:GetFontSettings()

    -- Row 1: Font Face dropdown (y = -38)
    local faceLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    faceLabel:SetPoint("TOPLEFT", 12, -38)
    faceLabel:SetText("Font:")
    faceLabel:SetTextColor(0.7, 0.7, 0.7)

    local faceDropdown = CreateFrame("DropdownButton", "CVarMasterFontFaceDropdown", section, "WowStyle1DropdownTemplate")
    faceDropdown:SetPoint("LEFT", faceLabel, "RIGHT", 0, 0)
    faceDropdown:SetWidth(200)
    faceDropdown:SetDefaultText("Select Font")

    faceDropdown:SetupMenu(function(dropdown, rootDescription)
        for _, font in ipairs(TM.AVAILABLE_FONTS) do
            rootDescription:CreateRadio(font.name, function()
                return TM:GetFontSettings().face == font.path
            end, function()
                TM:SetFontFace(font.path)
            end, font.path)
        end
    end)
    section.faceDropdown = faceDropdown

    -- Row 2: Font Size (y = -78)
    local sizeLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeLabel:SetPoint("TOPLEFT", 12, -78)
    sizeLabel:SetText("Size:")
    sizeLabel:SetTextColor(0.7, 0.7, 0.7)

    local sizeSlider = CreateFrame("Slider", "CVarMasterFontSizeSlider", section, "OptionsSliderTemplate")
    sizeSlider:SetSize(100, 16)
    sizeSlider:SetPoint("LEFT", sizeLabel, "RIGHT", 8, 0)
    sizeSlider:SetMinMaxValues(8, 24)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetObeyStepOnDrag(true)
    sizeSlider:SetValue(settings.size)
    sizeSlider.Low:SetText("")
    sizeSlider.High:SetText("")
    sizeSlider.Text:SetText("")

    local sizeValue = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sizeValue:SetPoint("LEFT", sizeSlider, "RIGHT", 6, 0)
    sizeValue:SetText(settings.size)

    sizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        sizeValue:SetText(value)
        -- Don't apply yet - wait for mouse release
    end)

    sizeSlider:SetScript("OnMouseUp", function(self)
        local value = math.floor(self:GetValue())
        TM:SetFontSize(value)
    end)

    -- Row 3: Outline dropdown (y = -118)
    local outlineLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    outlineLabel:SetPoint("TOPLEFT", 12, -118)
    outlineLabel:SetText("Outline:")
    outlineLabel:SetTextColor(0.7, 0.7, 0.7)

    local outlineDropdown = CreateFrame("DropdownButton", "CVarMasterFontOutlineDropdown", section, "WowStyle1DropdownTemplate")
    outlineDropdown:SetPoint("LEFT", outlineLabel, "RIGHT", 0, 0)
    outlineDropdown:SetWidth(150)
    outlineDropdown:SetDefaultText("Select Outline")

    outlineDropdown:SetupMenu(function(dropdown, rootDescription)
        for _, opt in ipairs(TM.FONT_FLAGS) do
            rootDescription:CreateRadio(opt.name, function()
                return TM:GetFontSettings().flags == opt.flag
            end, function()
                TM:SetFontFlags(opt.flag)
            end, opt.flag)
        end
    end)

    -- Row 4: Shadow X and Y (y = -158)
    local shadowXLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    shadowXLabel:SetPoint("TOPLEFT", 12, -158)
    shadowXLabel:SetText("Shadow X:")
    shadowXLabel:SetTextColor(0.7, 0.7, 0.7)

    local shadowXSlider = CreateFrame("Slider", "CVarMasterShadowXSlider", section, "OptionsSliderTemplate")
    shadowXSlider:SetSize(70, 16)
    shadowXSlider:SetPoint("LEFT", shadowXLabel, "RIGHT", 6, 0)
    shadowXSlider:SetMinMaxValues(-3, 3)
    shadowXSlider:SetValueStep(0.5)
    shadowXSlider:SetObeyStepOnDrag(true)
    shadowXSlider:SetValue(settings.shadowOffsetX)
    shadowXSlider.Low:SetText("")
    shadowXSlider.High:SetText("")
    shadowXSlider.Text:SetText("")

    local shadowXValue = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    shadowXValue:SetPoint("LEFT", shadowXSlider, "RIGHT", 4, 0)
    shadowXValue:SetText(string.format("%.1f", settings.shadowOffsetX))

    local shadowYLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    shadowYLabel:SetPoint("LEFT", shadowXValue, "RIGHT", 15, 0)
    shadowYLabel:SetText("Y:")
    shadowYLabel:SetTextColor(0.7, 0.7, 0.7)

    local shadowYSlider = CreateFrame("Slider", "CVarMasterShadowYSlider", section, "OptionsSliderTemplate")
    shadowYSlider:SetSize(70, 16)
    shadowYSlider:SetPoint("LEFT", shadowYLabel, "RIGHT", 6, 0)
    shadowYSlider:SetMinMaxValues(-3, 3)
    shadowYSlider:SetValueStep(0.5)
    shadowYSlider:SetObeyStepOnDrag(true)
    shadowYSlider:SetValue(settings.shadowOffsetY)
    shadowYSlider.Low:SetText("")
    shadowYSlider.High:SetText("")
    shadowYSlider.Text:SetText("")

    local shadowYValue = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    shadowYValue:SetPoint("LEFT", shadowYSlider, "RIGHT", 4, 0)
    shadowYValue:SetText(string.format("%.1f", settings.shadowOffsetY))

    shadowXSlider:SetScript("OnValueChanged", function(self, value)
        shadowXValue:SetText(string.format("%.1f", value))
        -- Don't apply yet - wait for mouse release
    end)

    shadowXSlider:SetScript("OnMouseUp", function(self)
        local s = TM:GetFontSettings()
        TM:SetFontShadow(self:GetValue(), s.shadowOffsetY, s.shadowColorR, s.shadowColorG, s.shadowColorB, s.shadowColorA)
    end)

    shadowYSlider:SetScript("OnValueChanged", function(self, value)
        shadowYValue:SetText(string.format("%.1f", value))
        -- Don't apply yet - wait for mouse release
    end)

    shadowYSlider:SetScript("OnMouseUp", function(self)
        local s = TM:GetFontSettings()
        TM:SetFontShadow(s.shadowOffsetX, self:GetValue(), s.shadowColorR, s.shadowColorG, s.shadowColorB, s.shadowColorA)
    end)

    -- Row 5: Shadow Opacity (y = -198)
    local shadowAlphaLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    shadowAlphaLabel:SetPoint("TOPLEFT", 12, -198)
    shadowAlphaLabel:SetText("Shadow Opacity:")
    shadowAlphaLabel:SetTextColor(0.7, 0.7, 0.7)

    local shadowAlphaSlider = CreateFrame("Slider", "CVarMasterShadowAlphaSlider", section, "OptionsSliderTemplate")
    shadowAlphaSlider:SetSize(100, 16)
    shadowAlphaSlider:SetPoint("LEFT", shadowAlphaLabel, "RIGHT", 6, 0)
    shadowAlphaSlider:SetMinMaxValues(0, 1)
    shadowAlphaSlider:SetValueStep(0.1)
    shadowAlphaSlider:SetObeyStepOnDrag(true)
    shadowAlphaSlider:SetValue(settings.shadowColorA)
    shadowAlphaSlider.Low:SetText("")
    shadowAlphaSlider.High:SetText("")
    shadowAlphaSlider.Text:SetText("")

    local shadowAlphaValue = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    shadowAlphaValue:SetPoint("LEFT", shadowAlphaSlider, "RIGHT", 4, 0)
    shadowAlphaValue:SetText(string.format("%.1f", settings.shadowColorA))

    shadowAlphaSlider:SetScript("OnValueChanged", function(self, value)
        shadowAlphaValue:SetText(string.format("%.1f", value))
        -- Don't apply yet - wait for mouse release
    end)

    shadowAlphaSlider:SetScript("OnMouseUp", function(self)
        local s = TM:GetFontSettings()
        TM:SetFontShadow(s.shadowOffsetX, s.shadowOffsetY, s.shadowColorR, s.shadowColorG, s.shadowColorB, self:GetValue())
    end)

    -- Row 6: Reset Font button (y = -238)
    local resetFontBtn = GUI:CreateButton(nil, section, "Reset Font", 90, 24)
    resetFontBtn:SetPoint("TOPLEFT", 12, -238)
    resetFontBtn:SetBackdropBorderColor(0.5, 0.3, 0.3, 0.8)
    resetFontBtn:SetScript("OnClick", function()
        TM:ResetFontSettings()
        local newSettings = TM:GetFontSettings()
        sizeSlider:SetValue(newSettings.size)
        shadowXSlider:SetValue(newSettings.shadowOffsetX)
        shadowYSlider:SetValue(newSettings.shadowOffsetY)
        shadowAlphaSlider:SetValue(newSettings.shadowColorA)
        -- Reset dropdowns (re-evaluate selected state)
        faceDropdown:GenerateMenu()
        outlineDropdown:GenerateMenu()
    end)
    resetFontBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(0.7, 0.4, 0.4, 1)
        self.text:SetTextColor(1, 0.6, 0.6)
    end)
    resetFontBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(T("BTN_NORMAL"))
        self:SetBackdropBorderColor(0.5, 0.3, 0.3, 0.8)
        self.text:SetTextColor(T("TEXT_PRIMARY"))
    end)

    return section
end

-- ==========================================
-- MAIN THEME WINDOW
-- ==========================================
function GUI:ShowThemeWindow()
    -- Recreate window to pick up theme changes
    if ThemeWindow then
        ThemeWindow:Hide()
        ThemeWindow:SetParent(nil)
        ThemeWindow = nil
    end

    if not ThemeWindow then
        ThemeWindow = GUI:CreateFrame("CVarMasterThemeWindow", UIParent, 520, 740, true)
        ThemeWindow:SetPoint("CENTER", 200, 0)
        ThemeWindow:SetMovable(true)
        ThemeWindow:EnableMouse(true)
        ThemeWindow:RegisterForDrag("LeftButton")
        ThemeWindow:SetScript("OnDragStart", ThemeWindow.StartMoving)
        ThemeWindow:SetScript("OnDragStop", ThemeWindow.StopMovingOrSizing)
        ThemeWindow:SetFrameStrata("DIALOG")
        ThemeWindow:SetClampedToScreen(true)

        -- Title bar
        local titleBar = CreateFrame("Frame", nil, ThemeWindow, "BackdropTemplate")
        titleBar:SetHeight(36)
        titleBar:SetPoint("TOPLEFT", 4, -4)
        titleBar:SetPoint("TOPRIGHT", -4, -4)
        titleBar:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        titleBar:SetBackdropColor(0.08, 0.1, 0.12, 1)
        titleBar:SetBackdropBorderColor(0.2, 0.25, 0.3, 1)

        -- Title with icon
        local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
        titleIcon:SetSize(20, 20)
        titleIcon:SetPoint("LEFT", 12, 0)
        titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Gem_Variety_02")
        titleIcon:SetVertexColor(0.8, 0.6, 1, 1)

        local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
        title:SetText("|cffAA66FFTheme|r |cffE8EBE8Customization|r")

        -- Close button
        local closeBtn = GUI:CreateButton(nil, titleBar, "X", 30, 30)
        closeBtn:SetPoint("RIGHT", -4, 0)
        closeBtn:SetScript("OnClick", function() ThemeWindow:Hide() end)

        -- Section: Color Palettes
        local paletteHeader = ThemeWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        paletteHeader:SetPoint("TOPLEFT", 14, -52)
        paletteHeader:SetText("|cff00ccffColor Palettes|r")

        -- Palette list scroll container (shorter to make room for font section)
        local listContainer, listContent = GUI:CreateScrollFrame("CVarMasterThemeList", ThemeWindow, 496, 180)
        listContainer:SetPoint("TOP", 0, -72)
        ThemeWindow.listContent = listContent
        ThemeWindow.listContainer = listContainer

        -- Font section - positioned absolutely from bottom (220px tall + 60px for bottom bar)
        local fontSection = CreateFontSection(ThemeWindow)
        fontSection:SetPoint("BOTTOMLEFT", 10, 60)
        fontSection:SetPoint("BOTTOMRIGHT", -10, 60)
        ThemeWindow.fontSection = fontSection

        -- Divider between palette and font section
        local divider = ThemeWindow:CreateTexture(nil, "ARTWORK")
        divider:SetHeight(1)
        divider:SetPoint("LEFT", 14, 0)
        divider:SetPoint("RIGHT", -14, 0)
        divider:SetPoint("BOTTOM", fontSection, "TOP", 0, 10)
        divider:SetColorTexture(0.25, 0.3, 0.35, 0.8)

        -- Bottom buttons
        local resetAllBtn = GUI:CreateButton(nil, ThemeWindow, "Reset All", 90, 28)
        resetAllBtn:SetPoint("BOTTOMLEFT", 12, 18)
        resetAllBtn:SetBackdropBorderColor(0.5, 0.25, 0.25, 0.8)
        resetAllBtn:SetScript("OnClick", function()
            TM:SetPreset("matrix")
            TM:ResetFontSettings()
            GUI:RefreshThemeList()
            -- Refresh font sliders and dropdowns
            local newSettings = TM:GetFontSettings()
            if _G["CVarMasterFontSizeSlider"] then
                _G["CVarMasterFontSizeSlider"]:SetValue(newSettings.size)
            end
            if _G["CVarMasterShadowXSlider"] then
                _G["CVarMasterShadowXSlider"]:SetValue(newSettings.shadowOffsetX)
            end
            if _G["CVarMasterShadowYSlider"] then
                _G["CVarMasterShadowYSlider"]:SetValue(newSettings.shadowOffsetY)
            end
            if _G["CVarMasterShadowAlphaSlider"] then
                _G["CVarMasterShadowAlphaSlider"]:SetValue(newSettings.shadowColorA)
            end
            if _G["CVarMasterFontFaceDropdown"] then
                _G["CVarMasterFontFaceDropdown"]:GenerateMenu()
            end
            if _G["CVarMasterFontOutlineDropdown"] then
                _G["CVarMasterFontOutlineDropdown"]:GenerateMenu()
            end
        end)
        resetAllBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.35, 0.12, 0.12, 1)
            self:SetBackdropBorderColor(0.7, 0.3, 0.3, 1)
            self.text:SetTextColor(1, 0.5, 0.5)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Reset All Settings", 1, 0.5, 0.5)
            GameTooltip:AddLine("Restore default theme and font settings", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        resetAllBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(T("BTN_NORMAL"))
            self:SetBackdropBorderColor(0.5, 0.25, 0.25, 0.8)
            self.text:SetTextColor(T("TEXT_PRIMARY"))
            GameTooltip:Hide()
        end)

        -- Reload notice (next to reset button)
        local reloadNotice = CreateFrame("Frame", nil, ThemeWindow, "BackdropTemplate")
        reloadNotice:SetHeight(28)
        reloadNotice:SetPoint("BOTTOMLEFT", resetAllBtn, "BOTTOMRIGHT", 10, 0)
        reloadNotice:SetPoint("BOTTOMRIGHT", -12, 18)
        reloadNotice:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        reloadNotice:SetBackdropColor(0.15, 0.12, 0.08, 1)
        reloadNotice:SetBackdropBorderColor(0.6, 0.5, 0.2, 0.8)

        local reloadIcon = reloadNotice:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        reloadIcon:SetPoint("LEFT", 10, 0)
        reloadIcon:SetText("|cffffcc00!|r")

        local reloadText = reloadNotice:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        reloadText:SetPoint("LEFT", reloadIcon, "RIGHT", 8, 0)
        reloadText:SetText("|cffffdd88Some changes require /reload to fully apply|r")

        local reloadBtn = GUI:CreateButton(nil, reloadNotice, "Reload UI", 70, 22)
        reloadBtn:SetPoint("RIGHT", -4, 0)
        reloadBtn:SetBackdropBorderColor(0.5, 0.4, 0.2, 0.8)
        reloadBtn:SetScript("OnClick", function()
            ReloadUI()
        end)
        reloadBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.3, 0.25, 0.1, 1)
            self:SetBackdropBorderColor(0.7, 0.6, 0.3, 1)
            self.text:SetTextColor(1, 0.9, 0.5)
        end)
        reloadBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(T("BTN_NORMAL"))
            self:SetBackdropBorderColor(0.5, 0.4, 0.2, 0.8)
            self.text:SetTextColor(T("TEXT_PRIMARY"))
        end)

        tinsert(UISpecialFrames, "CVarMasterThemeWindow")
    end

    GUI:RefreshThemeList()
    ThemeWindow:Show()
end

-- ==========================================
-- REFRESH THEME LIST
-- ==========================================
function GUI:RefreshThemeList()
    if not ThemeWindow or not ThemeWindow.listContent then return end

    local content = ThemeWindow.listContent

    -- Clear existing
    for _, child in pairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local currentPreset = TM:GetCurrentPreset()
    local presets = TM:GetPresetList()

    local yOffset = 0

    for _, preset in ipairs(presets) do
        local isActive = (preset.key == currentPreset)
        local row = CreatePresetRow(content, preset.key, TM.PRESETS[preset.key], yOffset, isActive)
        yOffset = yOffset - 56
    end

    content:SetHeight(math.max(1, math.abs(yOffset)))
end

CVarMaster.Utils.Debug("ThemePanel module loaded")
