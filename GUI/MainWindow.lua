---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local Constants = CVarMaster.Constants

local MainWindow = nil
local isInitialized = false
local currentScale = 1.0

-- Use shared theme/spacing helpers from Framework
local T = GUI.GetThemeColor
local S = GUI.GetSpacing

function GUI:InitMainWindow()
    if isInitialized then return end
    
    if not Constants or not Constants.GUI then return end
    
    local C = Constants.GUI
    
    -- Create main frame with Nihilum nine-slice (Plumber pattern - single TGA, no BackdropTemplate)
    MainWindow = GUI:CreateNihilumFrame("CVarMasterMainWindow", UIParent, true)
    MainWindow:SetSize(C.WINDOW_WIDTH, C.WINDOW_HEIGHT)
    if not MainWindow then return end
    MainWindow:SetPoint("CENTER")
    MainWindow:SetMovable(true)
    MainWindow:EnableMouse(true)
    MainWindow:RegisterForDrag("LeftButton")
    MainWindow:SetScript("OnDragStart", MainWindow.StartMoving)
    MainWindow:SetScript("OnDragStop", MainWindow.StopMovingOrSizing)
    MainWindow:SetClampedToScreen(true)
    MainWindow:SetResizable(true)
    MainWindow:SetResizeBounds(700, 450, 1400, 900)
    MainWindow:SetFrameStrata("HIGH")
    MainWindow:Hide()
    
    -- Title bar (lightweight - no BackdropTemplate to avoid opacity stacking over void)
    local titleBar = CreateFrame("Frame", nil, MainWindow)
    titleBar:SetHeight(36)
    titleBar:SetPoint("TOPLEFT", 4, -10)
    titleBar:SetPoint("TOPRIGHT", -4, -10)

    -- Subtle bottom accent line only (let the void show through)
    titleBar.accentLine = titleBar:CreateTexture(nil, "ARTWORK")
    titleBar.accentLine:SetHeight(1)
    titleBar.accentLine:SetPoint("BOTTOMLEFT", 0, 0)
    titleBar.accentLine:SetPoint("BOTTOMRIGHT", 0, 0)
    GUI:RegisterAccentTexture(titleBar.accentLine, 0.4)
    GUI.DisableSharpening(titleBar.accentLine)
    
    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", S("LG"), 0)
    title:SetText("CVarMaster")
    title:SetTextColor(0.85, 0.85, 0.90, 1)
    
    -- Version
    local version = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    version:SetPoint("LEFT", title, "RIGHT", S("SM"), 0)
    version:SetText("v" .. Constants.VERSION)
    version:SetTextColor(T("TEXT_MUTED"))



    -- Close button (minimal - no backdrop needed)
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPoint("RIGHT", -S("XS"), 0)
    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeBtn.text:SetPoint("CENTER")
    closeBtn.text:SetText("X")
    closeBtn.text:SetTextColor(T("TEXT_MUTED"))
    closeBtn:SetScript("OnClick", function() MainWindow:Hide() end)
    closeBtn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function(self) self.text:SetTextColor(T("TEXT_MUTED")) end)
    
    -- ========== NIHILUM SLIDER FACTORY ==========
    local function CreateNihilumSlider(parent, name, label, minVal, maxVal, step, width)
        local container = CreateFrame("Frame", nil, parent)
        container:SetSize(width or 145, 20)

        -- Label
        local lbl = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", 0, 0)
        lbl:SetText(label)
        lbl:SetTextColor(T("TEXT_MUTED"))

        -- Use OptionsSliderTemplate for proper drag mechanics, then reskin
        local slider = CreateFrame("Slider", name, container, "OptionsSliderTemplate")
        slider:SetSize(70, 14)
        slider:SetPoint("LEFT", lbl, "RIGHT", 6, 0)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)

        -- Hide template labels
        slider.Low:SetText("")
        slider.High:SetText("")
        slider.Text:SetText("")

        -- Reskin: hide default textures
        local regions = { slider:GetRegions() }
        for _, region in ipairs(regions) do
            if region:IsObjectType("Texture") and region ~= slider:GetThumbTexture() then
                region:SetColorTexture(0, 0, 0, 0)
                region:SetAlpha(0)
            end
        end

        -- Custom track
        local track = slider:CreateTexture(nil, "BACKGROUND")
        track:SetPoint("LEFT", 0, 0)
        track:SetPoint("RIGHT", 0, 0)
        track:SetHeight(4)
        track:SetColorTexture(0.10, 0.10, 0.14, 1)
        if GUI.DisableSharpening then GUI.DisableSharpening(track) end

        -- Track border
        local trackBorder = slider:CreateTexture(nil, "BORDER", nil, -1)
        trackBorder:SetPoint("TOPLEFT", track, "TOPLEFT", -1, 1)
        trackBorder:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", 1, -1)
        trackBorder:SetColorTexture(0.25, 0.25, 0.30, 0.5)
        if GUI.DisableSharpening then GUI.DisableSharpening(trackBorder) end

        -- Fill bar
        local fill = slider:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("LEFT", track, "LEFT", 0, 0)
        fill:SetHeight(4)
        fill:SetWidth(1)
        local aR, aG, aB = GUI:GetAccentRGB()
        fill:SetColorTexture(aR, aG, aB, 0.6)
        if GUI.DisableSharpening then GUI.DisableSharpening(fill) end
        if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(fill, 0.6) end

        -- Reskin thumb
        local thumb = slider:GetThumbTexture()
        thumb:SetSize(10, 10)
        thumb:SetColorTexture(0.85, 0.85, 0.90, 1)

        -- Value text
        local val = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        val:SetPoint("LEFT", slider, "RIGHT", 6, 0)
        val:SetWidth(35)
        val:SetJustifyH("LEFT")
        val:SetTextColor(T("TEXT_ACCENT"))

        -- Update fill on value change
        slider:HookScript("OnValueChanged", function(self)
            local pct = (self:GetValue() - minVal) / (maxVal - minVal)
            local trackW = self:GetWidth()
            fill:SetWidth(math.max(1, pct * trackW))
        end)

        return container, slider, val
    end

    -- ========== ALPHA SLIDER ==========
    local alphaCont, alphaSlider, alphaValue = CreateNihilumSlider(
        titleBar, "CVarMasterAlphaSlider", "Alpha:", 30, 100, 5, 150)
    alphaCont:SetPoint("RIGHT", closeBtn, "LEFT", -S("SM"), 0)
    MainWindow.alphaValue = alphaValue

    local savedAlpha = 100
    if CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.windowAlpha then
        savedAlpha = math.floor(CVarMaster.db.global.windowAlpha * 100)
    end
    alphaSlider:SetValue(savedAlpha)
    alphaValue:SetText(savedAlpha .. "%")
    MainWindow:SetAlpha(savedAlpha / 100)

    alphaSlider:HookScript("OnValueChanged", function(self, value)
        value = math.floor(value / 5 + 0.5) * 5
        alphaValue:SetText(value .. "%")
        MainWindow:SetAlpha(value / 100)
    end)

    alphaSlider:HookScript("OnMouseUp", function(self)
        local value = math.floor(self:GetValue() / 5 + 0.5) * 5
        if CVarMaster.db and CVarMaster.db.global then
            CVarMaster.db.global.windowAlpha = value / 100
        end
    end)

    alphaSlider:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Window Transparency", 1, 1, 1)
        GameTooltip:AddLine("Drag to adjust opacity (30% - 100%)", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    alphaSlider:HookScript("OnLeave", function() GameTooltip:Hide() end)
    MainWindow.alphaSlider = alphaSlider

    -- ========== SCALE SLIDER ==========
    local scaleCont, scaleSlider, scaleValue = CreateNihilumSlider(
        titleBar, "CVarMasterScaleSlider", "Scale:", 60, 140, 5, 150)
    scaleCont:SetPoint("RIGHT", alphaCont, "LEFT", -S("MD"), 0)
    MainWindow.scaleValue = scaleValue

    local savedScale = 100
    if CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.windowScale then
        savedScale = math.floor(CVarMaster.db.global.windowScale * 100)
    end
    currentScale = savedScale / 100
    scaleSlider:SetValue(savedScale)
    scaleValue:SetText(savedScale .. "%")
    MainWindow:SetScale(currentScale)


    scaleSlider:HookScript("OnValueChanged", function(self, value)
        value = math.floor(value / 5 + 0.5) * 5
        scaleValue:SetText(value .. "%")
    end)

    scaleSlider:HookScript("OnMouseUp", function(self)
        local value = math.floor(self:GetValue() / 5 + 0.5) * 5
        currentScale = value / 100
        MainWindow:SetScale(currentScale)

        if CVarMaster.db and CVarMaster.db.global then
            CVarMaster.db.global.windowScale = currentScale
        end
    end)

    scaleSlider:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Window Scale", 1, 1, 1)
        GameTooltip:AddLine("Drag to resize window (60% - 140%)", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Release to apply", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    scaleSlider:HookScript("OnLeave", function() GameTooltip:Hide() end)
    MainWindow.scaleSlider = scaleSlider
    
    -- Spec background art - child of MainWindow but ignores parent alpha
    local bgFrame = CreateFrame("Frame", "CVarMasterBGFrame", MainWindow)
    bgFrame:SetPoint("TOPLEFT", 14, -14)
    bgFrame:SetPoint("BOTTOMRIGHT", -14, 14)
    bgFrame:SetFrameLevel(math.max(1, MainWindow:GetFrameLevel()))
    bgFrame:EnableMouse(false)
    bgFrame:SetIgnoreParentAlpha(true)
    MainWindow.bgFrame = bgFrame

    local bgArt = bgFrame:CreateTexture(nil, "ARTWORK")
    bgArt:SetAllPoints()
    local savedBgAlpha = (CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.bgAlpha) or 0.5
    bgFrame:SetAlpha(savedBgAlpha)
    bgArt:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    if GUI.DisableSharpening then GUI.DisableSharpening(bgArt) end
    MainWindow.bgArt = bgArt

    -- Load saved background or default to none
    local savedBg = CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.bgAtlas
    if savedBg and savedBg ~= "" then
        bgArt:SetAtlas(savedBg, false)
        bgFrame:Show()
    else
        bgFrame:Hide()
    end

    -- Independent border overlay - stays at full alpha regardless of MainWindow alpha
    local borderFrame = CreateFrame("Frame", "CVarMasterBorderFrame", MainWindow)
    borderFrame:SetAllPoints()
    borderFrame:SetFrameLevel(MainWindow:GetFrameLevel() + 10)
    borderFrame:EnableMouse(false)
    borderFrame:SetIgnoreParentAlpha(true)
    MainWindow.borderFrame = borderFrame

    -- Duplicate nine-slice border (pieces 1-4, 6-9 = border, skip 5 = center)
    local TEX = "Interface\\AddOns\\CVarMaster\\Textures\\nihilum_frame"
    local NS = 12/128
    local NE = 116/128
    local cs = 14
    local aR, aG, aB = GUI:GetAccentRGB()

    local bp = {}
    borderFrame._pieces = bp
    for i = 1, 9 do
        bp[i] = borderFrame:CreateTexture(nil, "BORDER")
        bp[i]:SetTexture(TEX)
        if GUI.DisableSharpening then GUI.DisableSharpening(bp[i]) end
    end

    -- Corners
    bp[1]:SetSize(cs, cs); bp[3]:SetSize(cs, cs)
    bp[7]:SetSize(cs, cs); bp[9]:SetSize(cs, cs)

    bp[1]:SetPoint("TOPLEFT", borderFrame, "TOPLEFT")
    bp[3]:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT")
    bp[7]:SetPoint("BOTTOMLEFT", borderFrame, "BOTTOMLEFT")
    bp[9]:SetPoint("BOTTOMRIGHT", borderFrame, "BOTTOMRIGHT")

    -- Edges
    bp[2]:SetPoint("TOPLEFT", bp[1], "TOPRIGHT")
    bp[2]:SetPoint("BOTTOMRIGHT", bp[3], "BOTTOMLEFT")
    bp[4]:SetPoint("TOPLEFT", bp[1], "BOTTOMLEFT")
    bp[4]:SetPoint("BOTTOMRIGHT", bp[7], "TOPRIGHT")
    bp[6]:SetPoint("TOPLEFT", bp[3], "BOTTOMLEFT")
    bp[6]:SetPoint("BOTTOMRIGHT", bp[9], "TOPRIGHT")
    bp[8]:SetPoint("TOPLEFT", bp[7], "TOPRIGHT")
    bp[8]:SetPoint("BOTTOMRIGHT", bp[9], "BOTTOMLEFT")

    -- Center (transparent - just structural)
    bp[5]:SetPoint("TOPLEFT", bp[1], "BOTTOMRIGHT")
    bp[5]:SetPoint("BOTTOMRIGHT", bp[9], "TOPLEFT")

    -- TexCoords
    bp[1]:SetTexCoord(0, NS, 0, NS)
    bp[2]:SetTexCoord(NS, NE, 0, NS)
    bp[3]:SetTexCoord(NE, 1, 0, NS)
    bp[4]:SetTexCoord(0, NS, NS, NE)
    bp[5]:SetTexCoord(NS, NE, NS, NE)
    bp[6]:SetTexCoord(NE, 1, NS, NE)
    bp[7]:SetTexCoord(0, NS, NE, 1)
    bp[8]:SetTexCoord(NS, NE, NE, 1)
    bp[9]:SetTexCoord(NE, 1, NE, 1)

    -- Accent colors on border pieces, hide center
    for _, idx in ipairs({1, 2, 3, 4, 6, 7, 8, 9}) do
        bp[idx]:SetVertexColor(aR, aG, aB, 1)
    end
    bp[5]:Hide()
    bp[5] = nil -- remove so accent refresh loop skips it

    -- Register border pieces for accent color refresh
    GUI:RegisterNihilumFrame(borderFrame)
    borderFrame.pieces = bp



    -- Content area
    local content = CreateFrame("Frame", nil, MainWindow)
    content:SetPoint("TOPLEFT", 4, -44)
    content:SetPoint("BOTTOMRIGHT", -4, 4)
    MainWindow.content = content
    
    -- Left sidebar (transparent - let main void show through, just add right edge divider)
    local sidebar = CreateFrame("Frame", nil, content)
    sidebar:SetWidth(C.CATEGORY_WIDTH)
    sidebar:SetPoint("TOPLEFT", S("XS"), -S("XS"))
    sidebar:SetPoint("BOTTOMLEFT", S("XS"), S("XS"))

    -- Right-edge divider (Plumber-style vertical gradient)
    sidebar.divider = sidebar:CreateTexture(nil, "ARTWORK")
    sidebar.divider:SetWidth(2)
    sidebar.divider:SetPoint("TOPRIGHT", 0, -12)
    sidebar.divider:SetPoint("BOTTOMRIGHT", 0, 12)
    GUI:RegisterAccentTexture(sidebar.divider, 0.2)
    if GUI.DisableSharpening then GUI.DisableSharpening(sidebar.divider) end

    MainWindow.sidebar = sidebar
    
    -- Search box
    local searchBox = GUI:CreateEditBox("CVarMasterSearch", sidebar, C.CATEGORY_WIDTH - S("LG"), C.SEARCH_HEIGHT)
    searchBox:SetPoint("TOPLEFT", S("SM"), -S("MD"))
    searchBox:SetPoint("TOPRIGHT", -S("SM"), -S("MD"))
    
    local searchIcon = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchIcon:SetPoint("LEFT", searchBox, "LEFT", S("SM"), 0)
    searchIcon:SetText("|cff666666Search...|r")
    searchBox.placeholder = searchIcon
    
    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        self.placeholder:SetShown(text == "")
        GUI:RefreshCVarList(text)
    end)
    
    searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    MainWindow.searchBox = searchBox
    
    -- Category list
    if GUI.CreateCategoryList then
        GUI:CreateCategoryList(sidebar)
    end

    -- Settings buttons at sidebar bottom
    local sidebarBtnH = 24
    local sidebarBtnGap = 4

    local sidebarBottomBar = CreateFrame("Frame", nil, sidebar)
    sidebarBottomBar:SetHeight(40)
    sidebarBottomBar:SetPoint("BOTTOMLEFT", 0, 0)
    sidebarBottomBar:SetPoint("BOTTOMRIGHT", 0, 0)
    sidebarBottomBar:SetFrameLevel(sidebar:GetFrameLevel() + 5)

    -- Opaque background to mask scrolling text
    local sbBg = sidebarBottomBar:CreateTexture(nil, "BACKGROUND")
    sbBg:SetAllPoints()
    sbBg:SetColorTexture(0.06, 0.06, 0.08, 0.7)
    if GUI.DisableSharpening then GUI.DisableSharpening(sbBg) end

    local sbLine = sidebarBottomBar:CreateTexture(nil, "ARTWORK")
    sbLine:SetHeight(2)
    sbLine:SetPoint("TOPLEFT", 12, 0)
    sbLine:SetPoint("TOPRIGHT", -12, 0)
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(sbLine, 0.15) end
    if GUI.DisableSharpening then GUI.DisableSharpening(sbLine) end

    local sbCreateBtn = GUI.CreateTexturedButton and function(name, parent, text, w, h, style)
        return GUI:CreateTexturedButton(name, parent, text, w, h, style or "ghost")
    end or function(name, parent, text, w, h)
        return GUI:CreateButton(name, parent, text, w, h)
    end

    local sbTheme = sbCreateBtn(nil, sidebarBottomBar, "Theme", 55, sidebarBtnH, "ghost")
    sbTheme:SetPoint("LEFT", S("SM"), 0)
    sbTheme:SetScript("OnClick", function()
        if GUI.ShowThemeWindow then GUI:ShowThemeWindow() end
    end)

    local sbScripts = sbCreateBtn(nil, sidebarBottomBar, "Scripts", 55, sidebarBtnH, "ghost")
    sbScripts:SetPoint("LEFT", sbTheme, "RIGHT", sidebarBtnGap, 0)
    sbScripts:SetScript("OnClick", function()
        if GUI.ShowScriptsWindow then GUI:ShowScriptsWindow() end
    end)

    local sbProfiles = sbCreateBtn(nil, sidebarBottomBar, "Profiles", 60, sidebarBtnH, "ghost")
    sbProfiles:SetPoint("LEFT", sbScripts, "RIGHT", sidebarBtnGap, 0)
    sbProfiles:SetScript("OnClick", function()
        if GUI.ShowProfileWindow then GUI:ShowProfileWindow() end
    end)
    
    -- Right panel
    local rightPanel = CreateFrame("Frame", nil, content)
    rightPanel:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", S("XS"), 0)
    rightPanel:SetPoint("BOTTOMRIGHT", -S("XS"), S("XS"))
    MainWindow.rightPanel = rightPanel
    
    -- CVar list
    local listContainer, listContent = GUI:CreateScrollFrame("CVarMasterList", rightPanel, 
        C.WINDOW_WIDTH - C.CATEGORY_WIDTH - 32, C.WINDOW_HEIGHT - 100)
    -- Column headers with draggable dividers
    local headerFrame = CreateFrame("Frame", nil, rightPanel)
    headerFrame:SetHeight(18)
    headerFrame:SetPoint("TOPLEFT", 0, -S("XS"))
    headerFrame:SetPoint("TOPRIGHT", 0, -S("XS"))

    local hName = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hName:SetPoint("LEFT", S("MD"), 0)
    hName:SetText("Name")
    MainWindow._hName = hName
    hName:SetTextColor(T("TEXT_MUTED"))

    local hCVar = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hCVar:SetText("CVar")
    MainWindow._hCVar = hCVar
    hCVar:SetTextColor(T("TEXT_MUTED"))

    local hValue = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hValue:SetWidth(90)
    hValue:SetJustifyH("RIGHT")
    hValue:SetText("Value")
    MainWindow._hValue = hValue
    hValue:SetTextColor(T("TEXT_MUTED"))

    local hDefault = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hDefault:SetPoint("LEFT", hValue, "RIGHT", S("MD"), 0)
    hDefault:SetWidth(90)
    hDefault:SetJustifyH("RIGHT")
    hDefault:SetText("Default")
    MainWindow._hDefault = hDefault

    -- Draggable column divider factory (full-height with grip icon)
    local function CreateColumnDivider(parent)
        local divider = CreateFrame("Button", nil, parent)
        divider:SetWidth(10)
        divider:SetPoint("TOP", 0, -S("XS"))
        divider:SetPoint("BOTTOM", 0, 44)
        divider:EnableMouse(true)
        divider:SetFrameLevel(parent:GetFrameLevel() + 5)

        -- Full-height separator line (extends through list area)
        divider.line = divider:CreateTexture(nil, "OVERLAY")
        divider.line:SetWidth(1)
        divider.line:SetPoint("TOP", 0, 0)
        divider.line:SetPoint("BOTTOM", 0, 44) -- stop above bottom bar
        divider.line:SetColorTexture(0.35, 0.35, 0.40, 0.2)
        if GUI.DisableSharpening then GUI.DisableSharpening(divider.line) end

        -- Grip icon at top (three small horizontal lines)
        local gripH = 14
        local gripFrame = CreateFrame("Frame", nil, divider)
        gripFrame:SetSize(10, gripH)
        gripFrame:SetPoint("TOP", 0, -1)
        for i = 0, 2 do
            local grip = gripFrame:CreateTexture(nil, "OVERLAY")
            grip:SetSize(6, 1)
            grip:SetPoint("TOP", 0, -(i * 4) - 2)
            grip:SetColorTexture(0.55, 0.55, 0.60, 0.5)
            if GUI.DisableSharpening then GUI.DisableSharpening(grip) end
        end
        divider._grip = gripFrame

        divider:SetScript("OnEnter", function(self)
            SetCursor("UI_RESIZE_CURSOR")
            self.line:SetColorTexture(0.55, 0.55, 0.60, 0.6)
            for _, r in ipairs({self._grip:GetRegions()}) do
                if r.SetColorTexture then r:SetColorTexture(0.75, 0.75, 0.80, 0.9) end
            end
        end)
        divider:SetScript("OnLeave", function(self)
            if not self._dragging then
                SetCursor(nil)
                self.line:SetColorTexture(0.35, 0.35, 0.40, 0.2)
                for _, r in ipairs({self._grip:GetRegions()}) do
                    if r.SetColorTexture then r:SetColorTexture(0.55, 0.55, 0.60, 0.5) end
                end
            end
        end)

        return divider
    end

    -- Divider between Name and CVar (parented to rightPanel for full height)
    local divNameCVar = CreateColumnDivider(rightPanel)
    -- Divider between CVar and Value
    local divCVarValue = CreateColumnDivider(rightPanel)
    -- Divider between Value and Default
    local divValueDefault = CreateColumnDivider(rightPanel)

    -- Store user-set column widths (nil = auto-calc)
    local RecalcColumns  -- forward declaration for divider closures
    MainWindow._userNameW = nil
    MainWindow._userTechW = nil

    -- Drag logic for Name|CVar divider
    divNameCVar:SetScript("OnMouseDown", function(self)
        self._dragging = true
        self._startX = select(1, GetCursorPosition()) / (self:GetEffectiveScale() or 1)
        self._startNameW = GUI._colNameW or 180
        self._startTechW = GUI._colTechW or 190
    end)
    divNameCVar:SetScript("OnMouseUp", function(self)
        self._dragging = false
        SetCursor(nil)
        self.line:SetColorTexture(0.35, 0.35, 0.40, 0.2)
        for _, r in ipairs({self._grip:GetRegions()}) do
            if r.SetColorTexture then r:SetColorTexture(0.55, 0.55, 0.60, 0.5) end
        end
    end)
    divNameCVar:SetScript("OnUpdate", function(self)
        if not self._dragging then return end
        local curX = select(1, GetCursorPosition()) / (self:GetEffectiveScale() or 1)
        local delta = curX - self._startX
        local newNameW = math.max(80, math.min(400, self._startNameW + delta))
        local newTechW = math.max(80, math.min(400, self._startTechW - delta))
        MainWindow._userNameW = newNameW
        MainWindow._userTechW = newTechW
        RecalcColumns()
    end)

    -- Drag logic for CVar|Value divider
    divCVarValue:SetScript("OnMouseDown", function(self)
        self._dragging = true
        self._startX = select(1, GetCursorPosition()) / (self:GetEffectiveScale() or 1)
        self._startTechW = GUI._colTechW or 190
    end)
    divCVarValue:SetScript("OnMouseUp", function(self)
        self._dragging = false
        SetCursor(nil)
        self.line:SetColorTexture(0.35, 0.35, 0.40, 0.2)
        for _, r in ipairs({self._grip:GetRegions()}) do
            if r.SetColorTexture then r:SetColorTexture(0.55, 0.55, 0.60, 0.5) end
        end
    end)
    divCVarValue:SetScript("OnUpdate", function(self)
        if not self._dragging then return end
        local curX = select(1, GetCursorPosition()) / (self:GetEffectiveScale() or 1)
        local delta = curX - self._startX
        local newTechW = math.max(80, math.min(500, self._startTechW + delta))
        MainWindow._userTechW = newTechW
        RecalcColumns()
    end)

    -- Drag logic for Value|Default divider
    divValueDefault:SetScript("OnMouseDown", function(self)
        self._dragging = true
        self._startX = select(1, GetCursorPosition()) / (self:GetEffectiveScale() or 1)
        self._startValueW = GUI._colValueW or 90
        self._startDefaultW = GUI._colDefaultW or 90
    end)
    divValueDefault:SetScript("OnMouseUp", function(self)
        self._dragging = false
        SetCursor(nil)
        self.line:SetColorTexture(0.35, 0.35, 0.40, 0.2)
        for _, r in ipairs({self._grip:GetRegions()}) do
            if r.SetColorTexture then r:SetColorTexture(0.55, 0.55, 0.60, 0.5) end
        end
    end)
    divValueDefault:SetScript("OnUpdate", function(self)
        if not self._dragging then return end
        local curX = select(1, GetCursorPosition()) / (self:GetEffectiveScale() or 1)
        local delta = curX - self._startX
        local newValueW = math.max(50, math.min(200, self._startValueW + delta))
        MainWindow._userValueW = newValueW
        RecalcColumns()
    end)

    MainWindow._divNameCVar = divNameCVar
    MainWindow._divCVarValue = divCVarValue
    MainWindow._divValueDefault = divValueDefault
    MainWindow._userValueW = nil
    MainWindow._userDefaultW = nil
    hDefault:SetTextColor(T("TEXT_MUTED"))

    -- Subtle line under headers
    local headerLine = headerFrame:CreateTexture(nil, "ARTWORK")
    headerLine:SetHeight(2)
    headerLine:SetPoint("BOTTOMLEFT", 8, 0)
    headerLine:SetPoint("BOTTOMRIGHT", -8, 0)
    headerLine:SetColorTexture(T("TEXT_MUTED"))
    headerLine:SetAlpha(0.2)
    if GUI.DisableSharpening then GUI.DisableSharpening(headerLine) end

    listContainer:SetPoint("TOPLEFT", 0, -(S("XS") + 20))
    listContainer:SetPoint("BOTTOMRIGHT", 0, 44)
    MainWindow.listContainer = listContainer
    MainWindow.listContent = listContent
    
    -- Bottom bar
    local bottomBar = CreateFrame("Frame", nil, rightPanel)
    bottomBar:SetHeight(40)
    bottomBar:SetPoint("BOTTOMLEFT", 0, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", 0, 0)

    -- Top accent line (subtle separator)
    bottomBar.topLine = bottomBar:CreateTexture(nil, "ARTWORK")
    bottomBar.topLine:SetHeight(2)
    bottomBar.topLine:SetPoint("TOPLEFT", 8, 0)
    bottomBar.topLine:SetPoint("TOPRIGHT", -8, 0)
    GUI:RegisterAccentTexture(bottomBar.topLine, 0.25)
    GUI.DisableSharpening(bottomBar.topLine)
    

    
    -- Use textured buttons if available, fallback to regular
    local createBtn = GUI.CreateTexturedButton and function(name, parent, text, w, h, style)
        return GUI:CreateTexturedButton(name, parent, text, w, h, style or "primary")
    end or function(name, parent, text, w, h)
        return GUI:CreateButton(name, parent, text, w, h)
    end

    local scanBtn = createBtn(nil, bottomBar, "Rescan", 80, C.BUTTON_HEIGHT)
    scanBtn:SetPoint("RIGHT", -S("SM"), 0)
    scanBtn:SetScript("OnClick", function()
        CVarMaster.CVarScanner:RefreshCache()
        GUI:RefreshCVarList()
    end)

    local backupBtn = createBtn(nil, bottomBar, "Backup", 80, C.BUTTON_HEIGHT)
    backupBtn:SetPoint("RIGHT", scanBtn, "LEFT", -S("MD"), 0)
    backupBtn:SetScript("OnClick", function()
        if CVarMaster.CVarManager then
            CVarMaster.CVarManager:BackupAll()
        end
    end)

    local modifiedBtn = createBtn(nil, bottomBar, "Modified Only", 110, C.BUTTON_HEIGHT, "ghost")
    modifiedBtn:SetPoint("RIGHT", backupBtn, "LEFT", -S("MD"), 0)
    modifiedBtn.showModified = false
    modifiedBtn:SetScript("OnClick", function(self)
        self.showModified = not self.showModified
        self.text:SetText(self.showModified and "Show All" or "Modified Only")
        GUI:RefreshCVarList()
    end)
    MainWindow.modifiedBtn = modifiedBtn

    local lockedBtn = createBtn(nil, bottomBar, "Show Locked", 110, C.BUTTON_HEIGHT, "ghost")
    lockedBtn:SetPoint("RIGHT", modifiedBtn, "LEFT", -S("MD"), 0)
    lockedBtn.showLocked = false
    lockedBtn:SetScript("OnClick", function(self)
        self.showLocked = not self.showLocked
        self.text:SetText(self.showLocked and "Show All" or "Show Locked")
        GUI:RefreshCVarList()
    end)
    MainWindow.lockedBtn = lockedBtn







    -- Resize handle (bottom-right corner)
    local resizeHandle = CreateFrame("Button", nil, MainWindow)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", -4, 4)
    resizeHandle:SetFrameLevel(MainWindow:GetFrameLevel() + 10)
    resizeHandle:EnableMouse(true)

    -- Draw a subtle grip indicator (three diagonal lines)
    for i = 0, 2 do
        local line = resizeHandle:CreateTexture(nil, "OVERLAY")
        line:SetSize(10 - (i * 3), 1)
        line:SetPoint("BOTTOMRIGHT", -(i * 4) - 1, (i * 4) + 1)
        line:SetColorTexture(0.5, 0.5, 0.55, 0.5)
        if GUI.DisableSharpening then GUI.DisableSharpening(line) end
    end

    resizeHandle:SetScript("OnMouseDown", function(self)
        if not InCombatLockdown() then
            MainWindow:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeHandle:SetScript("OnMouseUp", function(self)
        MainWindow:StopMovingOrSizing()
        -- Save size
        if CVarMaster.db and CVarMaster.db.global then
            CVarMaster.db.global.windowWidth = MainWindow:GetWidth()
            CVarMaster.db.global.windowHeight = MainWindow:GetHeight()
        end
    end)
    resizeHandle:SetScript("OnEnter", function(self)
        SetCursor("UI_RESIZE_CURSOR")
        for _, region in ipairs({ self:GetRegions() }) do
            if region.SetColorTexture then
                region:SetColorTexture(0.7, 0.7, 0.75, 0.8)
            end
        end
    end)
    resizeHandle:SetScript("OnLeave", function(self)
        SetCursor(nil)
        for _, region in ipairs({ self:GetRegions() }) do
            if region.SetColorTexture then
                region:SetColorTexture(0.5, 0.5, 0.55, 0.5)
            end
        end
    end)

    -- Dynamic column widths on resize
    RecalcColumns = function()
        if not MainWindow then return end
        local totalW = MainWindow:GetWidth()
        local rightW = totalW - (Constants.GUI.CATEGORY_WIDTH or 190) - 40
        local fixedW = 270 -- value + default + reset + padding
        local flexW = rightW - fixedW
        if flexW < 200 then flexW = 200 end

        local nameW, techW
        if MainWindow._userNameW and MainWindow._userTechW then
            nameW = MainWindow._userNameW
            techW = MainWindow._userTechW
        elseif MainWindow._userNameW then
            nameW = MainWindow._userNameW
            techW = flexW - nameW
        elseif MainWindow._userTechW then
            techW = MainWindow._userTechW
            nameW = flexW - techW
        else
            nameW = math.floor(flexW * 0.48)
            techW = math.floor(flexW * 0.52)
        end

        -- Clamp
        nameW = math.max(80, math.min(400, nameW))
        techW = math.max(80, math.min(500, techW))

        GUI._colNameW = nameW
        GUI._colTechW = techW

        -- Position headers
        if MainWindow._hCVar then
            MainWindow._hCVar:SetPoint("LEFT", MainWindow._hName, "LEFT", nameW + 6, 0)
        end
        if MainWindow._hValue then
            MainWindow._hValue:SetPoint("LEFT", MainWindow._hCVar, "LEFT", techW + 6, 0)
        end

        -- Value and Default widths
        local valueW = (MainWindow._userValueW) or 90
        local defaultW = 90
        GUI._colValueW = valueW
        GUI._colDefaultW = defaultW

        -- Position headers
        if MainWindow._hDefault then
            MainWindow._hDefault:SetPoint("LEFT", MainWindow._hValue, "RIGHT", 12, 0)
            MainWindow._hDefault:SetWidth(defaultW)
        end
        if MainWindow._hValue then
            MainWindow._hValue:SetWidth(valueW)
        end

        -- Position dividers (children of rightPanel, anchor LEFT from hName)
        local hNameLeft = MainWindow._hName
        if MainWindow._divNameCVar and hNameLeft then
            MainWindow._divNameCVar:ClearAllPoints()
            MainWindow._divNameCVar:SetPoint("TOP", 0, -S("XS"))
            MainWindow._divNameCVar:SetPoint("BOTTOM", 0, 44)
            MainWindow._divNameCVar:SetPoint("LEFT", hNameLeft, "LEFT", nameW - 2, 0)
        end
        if MainWindow._divCVarValue and hNameLeft then
            MainWindow._divCVarValue:ClearAllPoints()
            MainWindow._divCVarValue:SetPoint("TOP", 0, -S("XS"))
            MainWindow._divCVarValue:SetPoint("BOTTOM", 0, 44)
            MainWindow._divCVarValue:SetPoint("LEFT", hNameLeft, "LEFT", nameW + techW + 2, 0)
        end
        if MainWindow._divValueDefault and hNameLeft then
            MainWindow._divValueDefault:ClearAllPoints()
            MainWindow._divValueDefault:SetPoint("TOP", 0, -S("XS"))
            MainWindow._divValueDefault:SetPoint("BOTTOM", 0, 44)
            MainWindow._divValueDefault:SetPoint("LEFT", hNameLeft, "LEFT", nameW + techW + valueW + 8, 0)
        end

        -- Update all active rows
        local activeRows = GUI._activeRows
        if activeRows then
            for _, row in pairs(activeRows) do
                if row.nameText then row.nameText:SetWidth(nameW) end
                if row.techName then row.techName:SetWidth(techW) end
                if row.valueText then row.valueText:SetWidth(valueW) end
                if row.defaultText then row.defaultText:SetWidth(defaultW) end
            end
        end
    end

    MainWindow:HookScript("OnSizeChanged", function()
        RecalcColumns()
    end)

    -- Initial calc
    RecalcColumns()

    tinsert(UISpecialFrames, "CVarMasterMainWindow")
    isInitialized = true
end

function GUI:Show()
    if not isInitialized then
        local success, err = pcall(function() GUI:InitMainWindow() end)
        if not success then
            print("|cffff0000CVarMaster ERROR:|r " .. tostring(err))
            return
        end
    end
    
    if not MainWindow then return end
    
    -- Apply saved size
    if CVarMaster.db and CVarMaster.db.global then
        if CVarMaster.db.global.windowWidth and CVarMaster.db.global.windowHeight then
            MainWindow:SetSize(CVarMaster.db.global.windowWidth, CVarMaster.db.global.windowHeight)
        end
    end

    -- Apply saved scale
    if CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.windowScale then
        local savedScale = CVarMaster.db.global.windowScale
        MainWindow:SetScale(savedScale)

        if MainWindow.scaleSlider then
            MainWindow.scaleSlider:SetValue(math.floor(savedScale * 100))
        end
        if MainWindow.scaleValue then
            MainWindow.scaleValue:SetText(math.floor(savedScale * 100) .. "%")
        end
    end
    
    local ok, err = pcall(function() GUI:RefreshCVarList() end)
    if not ok then
        print("|cffff0000CVarMaster ERROR in RefreshCVarList:|r " .. tostring(err))
    end

    -- Apply saved font settings to all UI elements
    if CVarMaster.ThemeManager then
        CVarMaster.ThemeManager:RefreshAllFonts()
    end

    MainWindow:Show()
end

function GUI:Hide()
    if MainWindow then MainWindow:Hide() end
end

function GUI:Toggle()
    if MainWindow and MainWindow:IsShown() then
        GUI:Hide()
    else
        GUI:Show()
    end
end

-- Background atlas management
local BG_ATLAS_LIST = {
    { label = "None", atlas = "" },
    -- Death Knight
    { label = "DK - Blood", atlas = "talents-background-deathknight-blood" },
    { label = "DK - Frost", atlas = "talents-background-deathknight-frost" },
    { label = "DK - Unholy", atlas = "talents-background-deathknight-unholy" },
    -- Demon Hunter
    { label = "DH - Havoc", atlas = "talents-background-demonhunter-havoc" },
    { label = "DH - Vengeance", atlas = "talents-background-demonhunter-vengeance" },
    -- Druid
    { label = "Druid - Balance", atlas = "talents-background-druid-balance" },
    { label = "Druid - Feral", atlas = "talents-background-druid-feral" },
    { label = "Druid - Guardian", atlas = "talents-background-druid-guardian" },
    { label = "Druid - Resto", atlas = "talents-background-druid-restoration" },
    -- Evoker
    { label = "Evoker - Devastation", atlas = "talents-background-evoker-devastation" },
    { label = "Evoker - Preservation", atlas = "talents-background-evoker-preservation" },
    { label = "Evoker - Augmentation", atlas = "talents-background-evoker-augmentation" },
    -- Hunter
    { label = "Hunter - BM", atlas = "talents-background-hunter-beastmastery" },
    { label = "Hunter - MM", atlas = "talents-background-hunter-marksmanship" },
    { label = "Hunter - Survival", atlas = "talents-background-hunter-survival" },
    -- Mage
    { label = "Mage - Arcane", atlas = "talents-background-mage-arcane" },
    { label = "Mage - Fire", atlas = "talents-background-mage-fire" },
    { label = "Mage - Frost", atlas = "talents-background-mage-frost" },
    -- Monk
    { label = "Monk - Brewmaster", atlas = "talents-background-monk-brewmaster" },
    { label = "Monk - Windwalker", atlas = "talents-background-monk-windwalker" },
    { label = "Monk - Mistweaver", atlas = "talents-background-monk-mistweaver" },
    -- Paladin
    { label = "Paladin - Holy", atlas = "talents-background-paladin-holy" },
    { label = "Paladin - Prot", atlas = "talents-background-paladin-protection" },
    { label = "Paladin - Ret", atlas = "talents-background-paladin-retribution" },
    -- Priest
    { label = "Priest - Disc", atlas = "talents-background-priest-discipline" },
    { label = "Priest - Holy", atlas = "talents-background-priest-holy" },
    { label = "Priest - Shadow", atlas = "talents-background-priest-shadow" },
    -- Rogue
    { label = "Rogue - Assassination", atlas = "talents-background-rogue-assassination" },
    { label = "Rogue - Outlaw", atlas = "talents-background-rogue-outlaw" },
    { label = "Rogue - Subtlety", atlas = "talents-background-rogue-subtlety" },
    -- Shaman
    { label = "Shaman - Elemental", atlas = "talents-background-shaman-elemental" },
    { label = "Shaman - Enhancement", atlas = "talents-background-shaman-enhancement" },
    { label = "Shaman - Resto", atlas = "talents-background-shaman-restoration" },
    -- Warlock
    { label = "Warlock - Affliction", atlas = "talents-background-warlock-affliction" },
    { label = "Warlock - Demonology", atlas = "talents-background-warlock-demonology" },
    { label = "Warlock - Destruction", atlas = "talents-background-warlock-destruction" },
    -- Warrior
    { label = "Warrior - Arms", atlas = "talents-background-warrior-arms" },
    { label = "Warrior - Fury", atlas = "talents-background-warrior-fury" },
    { label = "Warrior - Prot", atlas = "talents-background-warrior-protection" },
}

GUI.BG_ATLAS_LIST = BG_ATLAS_LIST

function GUI:SetBackground(atlasName)
    if not MainWindow or not MainWindow.bgArt then return end
    if atlasName == "" or not atlasName then
        if MainWindow.bgFrame then MainWindow.bgFrame:Hide() end
    else
        MainWindow.bgArt:SetAtlas(atlasName, false)
        MainWindow.bgArt:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        if MainWindow.bgFrame then MainWindow.bgFrame:Show() end
    end
    if CVarMaster.db and CVarMaster.db.global then
        CVarMaster.db.global.bgAtlas = atlasName
    end
end

function GUI:GetBackgroundAtlas()
    return CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.bgAtlas or ""
end

-- Get the current player's spec talent background atlas
local SPEC_ATLAS_MAP = {
    [250] = "talents-background-deathknight-blood",
    [251] = "talents-background-deathknight-frost",
    [252] = "talents-background-deathknight-unholy",
    [577] = "talents-background-demonhunter-havoc",
    [581] = "talents-background-demonhunter-vengeance",
    [102] = "talents-background-druid-balance",
    [103] = "talents-background-druid-feral",
    [104] = "talents-background-druid-guardian",
    [105] = "talents-background-druid-restoration",
    [1467] = "talents-background-evoker-devastation",
    [1468] = "talents-background-evoker-preservation",
    [1473] = "talents-background-evoker-augmentation",
    [253] = "talents-background-hunter-beastmastery",
    [254] = "talents-background-hunter-marksmanship",
    [255] = "talents-background-hunter-survival",
    [62] = "talents-background-mage-arcane",
    [63] = "talents-background-mage-fire",
    [64] = "talents-background-mage-frost",
    [268] = "talents-background-monk-brewmaster",
    [269] = "talents-background-monk-windwalker",
    [270] = "talents-background-monk-mistweaver",
    [65] = "talents-background-paladin-holy",
    [66] = "talents-background-paladin-protection",
    [70] = "talents-background-paladin-retribution",
    [256] = "talents-background-priest-discipline",
    [257] = "talents-background-priest-holy",
    [258] = "talents-background-priest-shadow",
    [259] = "talents-background-rogue-assassination",
    [260] = "talents-background-rogue-outlaw",
    [261] = "talents-background-rogue-subtlety",
    [262] = "talents-background-shaman-elemental",
    [263] = "talents-background-shaman-enhancement",
    [264] = "talents-background-shaman-restoration",
    [265] = "talents-background-warlock-affliction",
    [266] = "talents-background-warlock-demonology",
    [267] = "talents-background-warlock-destruction",
    [71] = "talents-background-warrior-arms",
    [72] = "talents-background-warrior-fury",
    [73] = "talents-background-warrior-protection",
    [1480] = "talents-background-demonhunter-devourer",
}

function GUI:GetPlayerSpecAtlas()
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex then
        local specID = GetSpecializationInfo(specIndex)
        if specID and SPEC_ATLAS_MAP[specID] then
            return SPEC_ATLAS_MAP[specID]
        end
    end
    return nil
end

-- Apply spec background to a sub-window frame
function GUI:ApplySpecBackground(frame)
    if not frame then return end
    
    local customTex = "Interface\\AddOns\\CVarMaster\\Textures\\bg_custom_01"
    
    if frame._specBgFrame then
        -- Already exists, just refresh texture
        frame._specBg:SetTexture(customTex)
        frame._specBgFrame:Show()
        return
    end

    -- Use a child frame so we can control draw order above nine-slice body
    local bgFrame = CreateFrame("Frame", nil, frame)
    bgFrame:SetPoint("TOPLEFT", 14, -14)
    bgFrame:SetPoint("BOTTOMRIGHT", -14, 14)
    bgFrame:SetFrameLevel(frame:GetFrameLevel() + 1)
    bgFrame:EnableMouse(false)
    frame._specBgFrame = bgFrame

    local bg = bgFrame:CreateTexture(nil, "ARTWORK")
    bg:SetAllPoints()
    bg:SetAlpha(0.35)
    bg:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    if GUI.DisableSharpening then GUI.DisableSharpening(bg) end
    frame._specBg = bg
    
    bg:SetTexture(customTex)
end

function GUI:GetMainWindow()
    return MainWindow
end
