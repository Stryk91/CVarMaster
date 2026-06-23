---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local function TM() return CVarMaster.ThemeManager end

local ThemeWindow = nil
local themeWindowCounter = 0

-- Use shared theme helper from Framework
local T = GUI.GetThemeColor

-- ==========================================
-- FONT SETTINGS SECTION (restyled)
-- ==========================================
local function CreateFontSection(parent)
    local section = CreateFrame("Frame", nil, parent)
    section:SetHeight(270)

    -- Section bg
    section.bg = section:CreateTexture(nil, "BACKGROUND")
    section.bg:SetAllPoints()
    section.bg:SetColorTexture(0.04, 0.03, 0.07, 0.5)
    GUI.DisableSharpening(section.bg)

    -- Top separator
    section.sep = section:CreateTexture(nil, "ARTWORK")
    section.sep:SetHeight(1)
    section.sep:SetPoint("TOPLEFT", 0, 0)
    section.sep:SetPoint("TOPRIGHT", 0, 0)
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(section.sep, 0.25) end
    GUI.DisableSharpening(section.sep)

    local header = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 12, -10)
    header:SetText("Font Settings")
    header:SetTextColor(0.85, 0.85, 0.90, 1)

    local settings = TM():GetFontSettings()

    -- Row 1: Font Face dropdown
    local faceLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    faceLabel:SetPoint("TOPLEFT", 12, -38)
    faceLabel:SetText("Font:")
    faceLabel:SetTextColor(0.7, 0.7, 0.7)

    local faceDropdown = CreateFrame("DropdownButton", "CVarMasterFontFace" .. themeWindowCounter, section, "WowStyle1DropdownTemplate")
    faceDropdown:SetPoint("LEFT", faceLabel, "RIGHT", 0, 0)
    faceDropdown:SetWidth(200)
    faceDropdown:SetDefaultText("Select Font")

    faceDropdown:SetupMenu(function(dropdown, rootDescription)
        local fonts = TM() and TM().AVAILABLE_FONTS
        if not fonts then
            print("|cffff0000CVarMaster:|r ThemeManager.AVAILABLE_FONTS is nil!")
            return
        end
        for _, font in ipairs(fonts) do
            rootDescription:CreateRadio(font.name, function()
                local s = TM():GetFontSettings()
                return s and s.face == font.path
            end, function()
                TM():SetFontFace(font.path)
            end, font.path)
        end
    end)
    section.faceDropdown = faceDropdown
    section.outlineDropdown = nil -- set below

    -- Row 2: Font Size
    local sizeLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeLabel:SetPoint("TOPLEFT", 12, -78)
    sizeLabel:SetText("Size:")
    sizeLabel:SetTextColor(0.7, 0.7, 0.7)

    local sizeSlider = CreateFrame("Slider", nil, section, "OptionsSliderTemplate")
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
        sizeValue:SetText(math.floor(value))
    end)
    sizeSlider:SetScript("OnMouseUp", function(self)
        TM():SetFontSize(math.floor(self:GetValue()))
    end)

    -- Row 3: Outline dropdown
    local outlineLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    outlineLabel:SetPoint("TOPLEFT", 12, -118)
    outlineLabel:SetText("Outline:")
    outlineLabel:SetTextColor(0.7, 0.7, 0.7)

    local outlineDropdown = CreateFrame("DropdownButton", "CVarMasterOutline" .. themeWindowCounter, section, "WowStyle1DropdownTemplate")
    outlineDropdown:SetPoint("LEFT", outlineLabel, "RIGHT", 0, 0)
    outlineDropdown:SetWidth(150)
    outlineDropdown:SetDefaultText("Select Outline")

    outlineDropdown:SetupMenu(function(dropdown, rootDescription)
        local flags = TM() and TM().FONT_FLAGS
        if not flags then
            print("|cffff0000CVarMaster:|r ThemeManager.FONT_FLAGS is nil!")
            return
        end
        for _, opt in ipairs(flags) do
            rootDescription:CreateRadio(opt.name, function()
                local s = TM():GetFontSettings()
                return s and s.flags == opt.flag
            end, function()
                TM():SetFontFlags(opt.flag)
            end, opt.flag)
        end
    end)

    -- Row 4: Shadow X and Y
    local shadowXLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    shadowXLabel:SetPoint("TOPLEFT", 12, -158)
    shadowXLabel:SetText("Shadow X:")
    shadowXLabel:SetTextColor(0.7, 0.7, 0.7)

    local shadowXSlider = CreateFrame("Slider", nil, section, "OptionsSliderTemplate")
    shadowXSlider:SetSize(70, 16)
    shadowXSlider:SetPoint("LEFT", shadowXLabel, "RIGHT", 6, 0)
    shadowXSlider:SetMinMaxValues(-3, 3)
    shadowXSlider:SetValueStep(0.5)
    shadowXSlider:SetObeyStepOnDrag(true)
    shadowXSlider:SetValue(settings.shadowOffsetX)
    shadowXSlider.Low:SetText(""); shadowXSlider.High:SetText(""); shadowXSlider.Text:SetText("")

    local shadowXValue = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    shadowXValue:SetPoint("LEFT", shadowXSlider, "RIGHT", 4, 0)
    shadowXValue:SetText(string.format("%.1f", settings.shadowOffsetX))

    local shadowYLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    shadowYLabel:SetPoint("LEFT", shadowXValue, "RIGHT", 15, 0)
    shadowYLabel:SetText("Y:")
    shadowYLabel:SetTextColor(0.7, 0.7, 0.7)

    local shadowYSlider = CreateFrame("Slider", nil, section, "OptionsSliderTemplate")
    shadowYSlider:SetSize(70, 16)
    shadowYSlider:SetPoint("LEFT", shadowYLabel, "RIGHT", 6, 0)
    shadowYSlider:SetMinMaxValues(-3, 3)
    shadowYSlider:SetValueStep(0.5)
    shadowYSlider:SetObeyStepOnDrag(true)
    shadowYSlider:SetValue(settings.shadowOffsetY)
    shadowYSlider.Low:SetText(""); shadowYSlider.High:SetText(""); shadowYSlider.Text:SetText("")

    local shadowYValue = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    shadowYValue:SetPoint("LEFT", shadowYSlider, "RIGHT", 4, 0)
    shadowYValue:SetText(string.format("%.1f", settings.shadowOffsetY))

    shadowXSlider:SetScript("OnValueChanged", function(self, value) shadowXValue:SetText(string.format("%.1f", value)) end)
    shadowXSlider:SetScript("OnMouseUp", function(self) local s = TM():GetFontSettings(); TM():SetFontShadow(self:GetValue(), s.shadowOffsetY, s.shadowColorR, s.shadowColorG, s.shadowColorB, s.shadowColorA) end)
    shadowYSlider:SetScript("OnValueChanged", function(self, value) shadowYValue:SetText(string.format("%.1f", value)) end)
    shadowYSlider:SetScript("OnMouseUp", function(self) local s = TM():GetFontSettings(); TM():SetFontShadow(s.shadowOffsetX, self:GetValue(), s.shadowColorR, s.shadowColorG, s.shadowColorB, s.shadowColorA) end)

    -- Row 5: Shadow Opacity
    local shadowAlphaLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    shadowAlphaLabel:SetPoint("TOPLEFT", 12, -198)
    shadowAlphaLabel:SetText("Shadow Opacity:")
    shadowAlphaLabel:SetTextColor(0.7, 0.7, 0.7)

    local shadowAlphaSlider = CreateFrame("Slider", nil, section, "OptionsSliderTemplate")
    shadowAlphaSlider:SetSize(100, 16)
    shadowAlphaSlider:SetPoint("LEFT", shadowAlphaLabel, "RIGHT", 6, 0)
    shadowAlphaSlider:SetMinMaxValues(0, 1)
    shadowAlphaSlider:SetValueStep(0.1)
    shadowAlphaSlider:SetObeyStepOnDrag(true)
    shadowAlphaSlider:SetValue(settings.shadowColorA)
    shadowAlphaSlider.Low:SetText(""); shadowAlphaSlider.High:SetText(""); shadowAlphaSlider.Text:SetText("")

    local shadowAlphaValue = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    shadowAlphaValue:SetPoint("LEFT", shadowAlphaSlider, "RIGHT", 4, 0)
    shadowAlphaValue:SetText(string.format("%.1f", settings.shadowColorA))

    shadowAlphaSlider:SetScript("OnValueChanged", function(self, value) shadowAlphaValue:SetText(string.format("%.1f", value)) end)
    shadowAlphaSlider:SetScript("OnMouseUp", function(self) local s = TM():GetFontSettings(); TM():SetFontShadow(s.shadowOffsetX, s.shadowOffsetY, s.shadowColorR, s.shadowColorG, s.shadowColorB, self:GetValue()) end)

    -- Store refs for external reset
    section.sizeSlider = sizeSlider
    section.shadowXSlider = shadowXSlider
    section.shadowYSlider = shadowYSlider
    section.shadowAlphaSlider = shadowAlphaSlider

    -- Reskin all font sliders to Nihilum style
    GUI:ReskinSlider(sizeSlider)
    GUI:ReskinSlider(shadowXSlider)
    GUI:ReskinSlider(shadowYSlider)
    GUI:ReskinSlider(shadowAlphaSlider)
    section.outlineDropdown = outlineDropdown

    -- Reset Font button
    local resetFontBtn = GUI:CreateButton(nil, section, "Reset Font", 90, 24)
    resetFontBtn:SetPoint("TOPLEFT", 12, -238)
    resetFontBtn:SetScript("OnClick", function()
        TM():ResetFontSettings()
        local ns = TM():GetFontSettings()
        sizeSlider:SetValue(ns.size)
        shadowXSlider:SetValue(ns.shadowOffsetX)
        shadowYSlider:SetValue(ns.shadowOffsetY)
        shadowAlphaSlider:SetValue(ns.shadowColorA)
        faceDropdown:GenerateMenu()
        outlineDropdown:GenerateMenu()
    end)

    return section
end

-- ==========================================
-- MAIN THEME WINDOW
-- ==========================================
function GUI:ShowThemeWindow()
    if ThemeWindow then
    
    -- Inherit scale/alpha from main window
    local mainWin = GUI:GetMainWindow()
    if mainWin then
        ThemeWindow:SetScale(mainWin:GetScale())
    end
    GUI:ApplySpecBackground(ThemeWindow)
    ThemeWindow:Show()
        return
    end

    themeWindowCounter = themeWindowCounter + 1
    ThemeWindow = GUI:CreateNihilumFrame("CVarMasterThemeWindow", UIParent, false)
    ThemeWindow:SetSize(480, 520)
    ThemeWindow:SetClipsChildren(true)
    ThemeWindow:SetPoint("CENTER", 200, 0)
    ThemeWindow:SetMovable(true)
    ThemeWindow:EnableMouse(true)
    ThemeWindow:RegisterForDrag("LeftButton")
    ThemeWindow:SetScript("OnDragStart", ThemeWindow.StartMoving)
    ThemeWindow:SetScript("OnDragStop", ThemeWindow.StopMovingOrSizing)
    ThemeWindow:SetFrameStrata("DIALOG")
    ThemeWindow:SetClampedToScreen(true)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, ThemeWindow)
    titleBar:SetHeight(36)
    titleBar:SetPoint("TOPLEFT", 4, -4)
    titleBar:SetPoint("TOPRIGHT", -4, -4)

    titleBar.accentLine = titleBar:CreateTexture(nil, "ARTWORK")
    titleBar.accentLine:SetHeight(1)
    titleBar.accentLine:SetPoint("BOTTOMLEFT", 0, 0)
    titleBar.accentLine:SetPoint("BOTTOMRIGHT", 0, 0)
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(titleBar.accentLine, 0.4) end
    GUI.DisableSharpening(titleBar.accentLine)

    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(20, 20)
    titleIcon:SetPoint("LEFT", 12, 0)
    titleIcon:SetTexture("Interface\\AddOns\\CVarMaster\\Textures\\icon_theme")
    titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
    title:SetText("Theme Settings")
    title:SetTextColor(0.85, 0.85, 0.90, 1)

    local closeBtn = GUI:CreateButton(nil, titleBar, "X", 30, 30)
    closeBtn:SetPoint("RIGHT", -4, 0)
    closeBtn:SetScript("OnClick", function() ThemeWindow:Hide() end)

    -- Master scroll frame for all content
    local masterScroll = CreateFrame("ScrollFrame", nil, ThemeWindow, "UIPanelScrollFrameTemplate")
    masterScroll:SetPoint("TOPLEFT", 4, -44)
    masterScroll:SetPoint("BOTTOMRIGHT", -24, 52)

    local scrollChild = CreateFrame("Frame", nil, masterScroll)
    scrollChild:SetWidth(440)
    scrollChild:SetHeight(600)  -- will be adjusted at end
    masterScroll:SetScrollChild(scrollChild)

    -- ==========================================
    -- ACCENT COLOR SECTION
    -- ==========================================
    local accentHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    accentHeader:SetPoint("TOPLEFT", 10, -8)
    accentHeader:SetText("Accent Color")
    accentHeader:SetTextColor(0.85, 0.85, 0.90, 1)

    -- Color preview swatch
    local preview = scrollChild:CreateTexture(nil, "ARTWORK")
    preview:SetSize(32, 32)
    preview:SetPoint("TOPLEFT", 14, -74)
    local aR, aG, aB = GUI:GetAccentRGB()
    preview:SetColorTexture(aR, aG, aB, 1)
    GUI.DisableSharpening(preview)

    local previewBorder = scrollChild:CreateTexture(nil, "BORDER")
    previewBorder:SetSize(34, 34)
    previewBorder:SetPoint("CENTER", preview, "CENTER")
    previewBorder:SetColorTexture(0.3, 0.3, 0.3, 1)

    local previewLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewLabel:SetPoint("LEFT", preview, "RIGHT", 10, 0)
    previewLabel:SetText("Current accent color")
    previewLabel:SetTextColor(0.6, 0.6, 0.6)

    -- Hue slider (0-360) - Nihilum style
    local currentHue = (CVarMaster.db and CVarMaster.db.accentHue) or 200
    local hueCont, hueSlider, hueValue = GUI:CreateNihilumSlider(scrollChild, nil, "Hue:", 0, 360, 1, 420)
    hueCont:SetPoint("TOPLEFT", 10, -118)
    hueSlider:SetValue(currentHue)
    hueValue:SetText(math.floor(currentHue) .. "°")

    -- Saturation slider (0-100) - Nihilum style
    local currentSat = (CVarMaster.db and CVarMaster.db.accentSat and CVarMaster.db.accentSat * 100) or 30
    local satCont, satSlider, satValue = GUI:CreateNihilumSlider(scrollChild, nil, "Saturation:", 0, 100, 1, 420)
    satCont:SetPoint("TOPLEFT", 10, -148)
    satSlider:SetValue(currentSat)
    satValue:SetText(math.floor(currentSat) .. "%")

    -- Debounced update (500ms after last slider move)
    local accentTimer = nil
    local function UpdateAccentDebounced()
        -- Update labels immediately (cheap)
        local h = math.floor(hueSlider:GetValue())
        local s = satSlider:GetValue() / 100
        hueValue:SetText(h .. "°")
        satValue:SetText(math.floor(s * 100) .. "%")

        -- Update swatch immediately (cheap preview)
        local hSec = h / 60
        local c = s
        local x = c * (1 - math.abs(hSec % 2 - 1))
        local pr, pg, pb = 0, 0, 0
        if hSec < 1 then pr, pg, pb = c, x, 0
        elseif hSec < 2 then pr, pg, pb = x, c, 0
        elseif hSec < 3 then pr, pg, pb = 0, c, x
        elseif hSec < 4 then pr, pg, pb = 0, x, c
        elseif hSec < 5 then pr, pg, pb = x, 0, c
        else pr, pg, pb = c, 0, x end
        preview:SetColorTexture(0.10 + pr * 0.90, 0.10 + pg * 0.90, 0.10 + pb * 0.90, 1)

        -- Cancel pending timer
        if accentTimer then
            accentTimer:Cancel()
        end

        -- Schedule the expensive refresh
        accentTimer = C_Timer.NewTimer(0.5, function()
            local hv = math.floor(hueSlider:GetValue())
            local sv = satSlider:GetValue() / 100
            GUI:SetAccentHSV(hv, sv)
            local r, g, b = GUI:GetAccentRGB()
            preview:SetColorTexture(r, g, b, 1)
            accentTimer = nil
        end)
    end

    hueSlider:SetScript("OnValueChanged", function() UpdateAccentDebounced() end)
    satSlider:SetScript("OnValueChanged", function() UpdateAccentDebounced() end)

    -- Store slider refs for Reset All
    ThemeWindow.hueSlider = hueSlider
    ThemeWindow.satSlider = satSlider

    -- Divider before font section
    local divider = scrollChild:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", 14, -178)
    divider:SetPoint("TOPRIGHT", -14, -178)
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(divider, 0.25) end
    GUI.DisableSharpening(divider)

    -- Font section
    local fontSection = CreateFontSection(scrollChild)
    fontSection:SetPoint("TOPLEFT", 10, -188)
    fontSection:SetPoint("TOPRIGHT", -10, -188)
    ThemeWindow.fontSection = fontSection

    -- Background Art section
    local bgDivider = scrollChild:CreateTexture(nil, "ARTWORK")
    bgDivider:SetHeight(1)
    bgDivider:SetPoint("TOPLEFT", fontSection, "BOTTOMLEFT", 6, -8)
    bgDivider:SetPoint("TOPRIGHT", fontSection, "BOTTOMRIGHT", -6, -8)
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(bgDivider, 0.25) end
    if GUI.DisableSharpening then GUI.DisableSharpening(bgDivider) end

    local bgHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bgHeader:SetPoint("TOPLEFT", bgDivider, "BOTTOMLEFT", -2, -8)
    bgHeader:SetText("Background Art")
    bgHeader:SetTextColor(0.85, 0.85, 0.90, 1)

    local bgCurrentLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bgCurrentLabel:SetPoint("TOPLEFT", bgHeader, "BOTTOMLEFT", 0, -6)
    bgCurrentLabel:SetTextColor(T("TEXT_MUTED"))

    local currentAtlas = GUI:GetBackgroundAtlas()
    local currentLabel = "None"
    if GUI.BG_ATLAS_LIST then
        for _, entry in ipairs(GUI.BG_ATLAS_LIST) do
            if entry.atlas == currentAtlas then currentLabel = entry.label break end
        end
    end
    bgCurrentLabel:SetText("Current: " .. currentLabel)

    -- BG Art alpha slider
    local savedBgAlpha = (CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.bgAlpha) or 0.5
    local bgAlphaCont, bgAlphaSlider, bgAlphaValue = GUI:CreateNihilumSlider(scrollChild, nil, "Opacity:", 0, 100, 5, 420)
    bgAlphaCont:SetPoint("TOPLEFT", bgCurrentLabel, "BOTTOMLEFT", 0, -8)
    bgAlphaSlider:SetValue(savedBgAlpha * 100)
    bgAlphaValue:SetText(math.floor(savedBgAlpha * 100) .. "%")

    bgAlphaSlider:HookScript("OnValueChanged", function(self, value)
        value = math.floor(value / 5 + 0.5) * 5
        bgAlphaValue:SetText(value .. "%")
        local mainWin = GUI:GetMainWindow()
        if mainWin and mainWin.bgFrame then
            mainWin.bgFrame:SetAlpha(value / 100)
        end
    end)
    bgAlphaSlider:HookScript("OnMouseUp", function(self)
        local value = math.floor(self:GetValue() / 5 + 0.5) * 5
        if CVarMaster.db and CVarMaster.db.global then
            CVarMaster.db.global.bgAlpha = value / 100
        end
    end)

    -- Background choices container (inside master scroll, no nested scroll)
    local bgContent = CreateFrame("Frame", nil, scrollChild)
    bgContent:SetSize(440, 10) -- will grow
    bgContent:SetPoint("TOPLEFT", bgAlphaCont, "BOTTOMLEFT", -4, -6)

    -- Build grid of clickable background options
    local colCount = 3
    local btnW = math.floor(440 / colCount) - 4
    local btnH = 28
    local row, col = 0, 0

    if GUI.BG_ATLAS_LIST then
        for i, entry in ipairs(GUI.BG_ATLAS_LIST) do
            local btn = CreateFrame("Button", nil, bgContent)
            btn:SetSize(btnW, btnH)
            btn:SetPoint("TOPLEFT", col * (btnW + 4), -(row * (btnH + 2)))

            local btnBg = btn:CreateTexture(nil, "BACKGROUND")
            btnBg:SetAllPoints()
            btnBg:SetColorTexture(0.12, 0.12, 0.15, 0.8)

            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btnText:SetPoint("CENTER")
            btnText:SetText(entry.label)
            btnText:SetTextColor(T("TEXT_PRIMARY"))
            btnText:SetWordWrap(false)

            -- Highlight current
            if entry.atlas == currentAtlas then
                local aR, aG, aB = GUI:GetAccentRGB()
                btnBg:SetColorTexture(aR, aG, aB, 0.25)
                btnText:SetTextColor(T("TEXT_ACCENT"))
            end

            btn:SetScript("OnEnter", function(self)
                btnBg:SetColorTexture(0.2, 0.2, 0.25, 0.9)
                btnText:SetTextColor(T("TEXT_ACCENT"))
            end)
            btn:SetScript("OnLeave", function(self)
                local cur = GUI:GetBackgroundAtlas()
                if entry.atlas == cur then
                    local aR, aG, aB = GUI:GetAccentRGB()
                    btnBg:SetColorTexture(aR, aG, aB, 0.25)
                    btnText:SetTextColor(T("TEXT_ACCENT"))
                else
                    btnBg:SetColorTexture(0.12, 0.12, 0.15, 0.8)
                    btnText:SetTextColor(T("TEXT_PRIMARY"))
                end
            end)
            btn:SetScript("OnClick", function()
                GUI:SetBackground(entry.atlas)
                bgCurrentLabel:SetText("Current: " .. entry.label)
                -- Refresh all button highlights
                -- Quick approach: just close and reopen
            end)

            col = col + 1
            if col >= colCount then
                col = 0
                row = row + 1
            end
        end
    end
    bgContent:SetHeight((row + 1) * (btnH + 2))
        -- Set scroll child tall enough for all content
    local totalRows = math.ceil(#GUI.BG_ATLAS_LIST / colCount)
    -- fontSection starts at 188, is 270 tall = 458, then ~30 gap + header + label + grid
    scrollChild:SetHeight(458 + 30 + 50 + (totalRows * (btnH + 2)) + 20)

    -- Opaque bottom bar to mask scroll content
    local bottomBar = CreateFrame("Frame", nil, ThemeWindow)
    bottomBar:SetHeight(50)
    bottomBar:SetPoint("BOTTOMLEFT", 4, 4)
    bottomBar:SetPoint("BOTTOMRIGHT", -4, 4)
    bottomBar:SetFrameLevel(ThemeWindow:GetFrameLevel() + 5)
    local bottomBg = bottomBar:CreateTexture(nil, "BACKGROUND")
    bottomBg:SetAllPoints()
    bottomBg:SetColorTexture(0.06, 0.06, 0.08, 1)
    if GUI.DisableSharpening then GUI.DisableSharpening(bottomBg) end

    -- Bottom buttons (parented to bottomBar so they're above the mask)
    local resetAllBtn = GUI:CreateButton(nil, bottomBar, "Reset All", 90, 28)
    resetAllBtn:SetPoint("LEFT", 8, 0)
    resetAllBtn:SetScript("OnClick", function()
        -- Reset accent to default slate
        hueSlider:SetValue(200)
        satSlider:SetValue(30)
        GUI:SetAccentHSV(200, 0.3)
        -- Reset fonts
        TM():ResetFontSettings()
        local ns = TM():GetFontSettings()
        local fs = fontSection
        fs.sizeSlider:SetValue(ns.size)
        fs.shadowXSlider:SetValue(ns.shadowOffsetX)
        fs.shadowYSlider:SetValue(ns.shadowOffsetY)
        fs.shadowAlphaSlider:SetValue(ns.shadowColorA)
        fs.faceDropdown:GenerateMenu()
        fs.outlineDropdown:GenerateMenu()
        -- Update preview
        local r, g, b = GUI:GetAccentRGB()
        preview:SetColorTexture(r, g, b, 1)
    end)

    -- Reload UI button
    local reloadBtn = GUI:CreateButton(nil, bottomBar, "Reload UI", 80, 28)
    reloadBtn:SetPoint("RIGHT", -8, 0)
    reloadBtn:SetScript("OnClick", function() ReloadUI() end)

    -- Hint text


    GUI:AddResizeHandle(ThemeWindow, 400, 350, 700, 800)
    tinsert(UISpecialFrames, "CVarMasterThemeWindow")

    -- Inherit scale/alpha from main window
    local mainWin = GUI:GetMainWindow()
    if mainWin then
        ThemeWindow:SetScale(mainWin:GetScale())
    end
    GUI:ApplySpecBackground(ThemeWindow)
    ThemeWindow:Show()
end

-- RefreshThemeList is called by old code - make it a no-op now
function GUI:RefreshThemeList()
    -- Palettes removed - no-op
end

CVarMaster.Utils.Debug("ThemePanel module loaded")
