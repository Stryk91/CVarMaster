---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local Constants = CVarMaster.Constants

local MainWindow = nil
local isInitialized = false
local currentScale = 1.0

-- Local theme helper
local function T(key)
    if Constants and Constants.THEME and Constants.THEME[key] then
        return unpack(Constants.THEME[key])
    end
    return 0.5, 0.5, 0.5, 1.0
end

local function S(key)
    if Constants and Constants.SPACING then
        return Constants.SPACING[key] or 8
    end
    return 8
end

function GUI:InitMainWindow()
    if isInitialized then return end
    
    if not Constants or not Constants.GUI then return end
    
    local C = Constants.GUI
    
    -- Create main frame with modern backdrop
    MainWindow = GUI:CreateFrame("CVarMasterMainWindow", UIParent, C.WINDOW_WIDTH, C.WINDOW_HEIGHT, true)
    if not MainWindow then return end
    
    MainWindow:SetBackdropColor(T("BG_PRIMARY"))
    MainWindow:SetBackdropBorderColor(T("BORDER_DEFAULT"))
    MainWindow:SetPoint("CENTER")
    MainWindow:SetMovable(true)
    MainWindow:EnableMouse(true)
    MainWindow:RegisterForDrag("LeftButton")
    MainWindow:SetScript("OnDragStart", MainWindow.StartMoving)
    MainWindow:SetScript("OnDragStop", MainWindow.StopMovingOrSizing)
    MainWindow:SetClampedToScreen(true)
    MainWindow:SetFrameStrata("HIGH")
    MainWindow:Hide()
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, MainWindow, "BackdropTemplate")
    titleBar:SetHeight(36)
    titleBar:SetPoint("TOPLEFT", 4, -4)
    titleBar:SetPoint("TOPRIGHT", -4, -4)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    titleBar:SetBackdropColor(T("TITLEBAR_BG"))
    titleBar:SetBackdropBorderColor(T("TITLEBAR_BORDER"))
    
    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", S("LG"), 0)
    title:SetText("|cff5BD663CVar|r|cffE8EBE8Master|r")
    
    -- Version
    local version = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    version:SetPoint("LEFT", title, "RIGHT", S("SM"), 0)
    version:SetText("v" .. Constants.VERSION)
    version:SetTextColor(T("TEXT_MUTED"))

    -- Subtitle / Call to action
    local subtitle = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("LEFT", version, "RIGHT", S("LG"), 0)
    subtitle:SetText("|cff888888Comment on CurseForge with your idea and I'll make this addon better!|r")

    -- Close button
    local closeBtn = GUI:CreateButton(nil, titleBar, "X", 30, 30)
    closeBtn:SetPoint("RIGHT", -S("XS"), 0)
    closeBtn:SetScript("OnClick", function() MainWindow:Hide() end)
    
    -- ========== SCALE SLIDER ==========
    local scaleContainer = CreateFrame("Frame", nil, titleBar)
    scaleContainer:SetSize(170, 30)
    scaleContainer:SetPoint("RIGHT", closeBtn, "LEFT", -S("LG"), 0)
    
    -- Scale label
    local scaleLabel = scaleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("LEFT", 0, 0)
    scaleLabel:SetText("Scale:")
    scaleLabel:SetTextColor(T("TEXT_SECONDARY"))
    
    -- Use proper WoW slider template
    local scaleSlider = CreateFrame("Slider", "CVarMasterScaleSlider", scaleContainer, "OptionsSliderTemplate")
    scaleSlider:SetSize(85, 17)
    scaleSlider:SetPoint("LEFT", scaleLabel, "RIGHT", S("SM"), 0)
    scaleSlider:SetMinMaxValues(60, 140)
    scaleSlider:SetValueStep(5)
    scaleSlider:SetObeyStepOnDrag(true)
    
    -- Hide the default low/high text
    scaleSlider.Low:SetText("")
    scaleSlider.High:SetText("")
    scaleSlider.Text:SetText("")
    
    -- Scale value display
    local scaleValue = scaleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleValue:SetPoint("LEFT", scaleSlider, "RIGHT", S("SM"), 0)
    scaleValue:SetWidth(40)
    scaleValue:SetJustifyH("LEFT")
    scaleValue:SetTextColor(T("TEXT_ACCENT"))
    MainWindow.scaleValue = scaleValue
    
    -- Load saved scale
    local savedScale = 100
    if CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.windowScale then
        savedScale = math.floor(CVarMaster.db.global.windowScale * 100)
    end
    currentScale = savedScale / 100
    scaleSlider:SetValue(savedScale)
    scaleValue:SetText(savedScale .. "%")
    MainWindow:SetScale(currentScale)
    
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / 5 + 0.5) * 5
        scaleValue:SetText(value .. "%")
    end)
    
    scaleSlider:SetScript("OnMouseUp", function(self)
        local value = math.floor(self:GetValue() / 5 + 0.5) * 5
        currentScale = value / 100
        MainWindow:SetScale(currentScale)
        
        if CVarMaster.db and CVarMaster.db.global then
            CVarMaster.db.global.windowScale = currentScale
        end
    end)
    
    scaleSlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Window Scale", 1, 1, 1)
        GameTooltip:AddLine("Drag to resize window (60% - 140%)", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Release to apply", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    scaleSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    MainWindow.scaleSlider = scaleSlider
    
    -- Content area
    local content = CreateFrame("Frame", nil, MainWindow)
    content:SetPoint("TOPLEFT", 4, -44)
    content:SetPoint("BOTTOMRIGHT", -4, 4)
    MainWindow.content = content
    
    -- Left sidebar
    local sidebar = GUI:CreateFrame(nil, content, C.CATEGORY_WIDTH, 1)
    sidebar:SetPoint("TOPLEFT", S("XS"), -S("XS"))
    sidebar:SetPoint("BOTTOMLEFT", S("XS"), S("XS"))
    sidebar:SetBackdropColor(T("BG_SECONDARY"))
    sidebar:SetBackdropBorderColor(T("BORDER_SUBTLE"))
    MainWindow.sidebar = sidebar
    
    -- Search box
    local searchBox = GUI:CreateEditBox("CVarMasterSearch", sidebar, C.CATEGORY_WIDTH - S("LG"), C.SEARCH_HEIGHT)
    searchBox:SetPoint("TOPLEFT", S("SM"), -S("SM"))
    searchBox:SetPoint("TOPRIGHT", -S("SM"), -S("SM"))
    
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
    
    -- Right panel
    local rightPanel = CreateFrame("Frame", nil, content)
    rightPanel:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", S("XS"), 0)
    rightPanel:SetPoint("BOTTOMRIGHT", -S("XS"), S("XS"))
    MainWindow.rightPanel = rightPanel
    
    -- CVar list
    local listContainer, listContent = GUI:CreateScrollFrame("CVarMasterList", rightPanel, 
        C.WINDOW_WIDTH - C.CATEGORY_WIDTH - 32, C.WINDOW_HEIGHT - 100)
    listContainer:SetPoint("TOPLEFT", 0, -S("XS"))
    listContainer:SetPoint("BOTTOMRIGHT", 0, 44)
    MainWindow.listContainer = listContainer
    MainWindow.listContent = listContent
    
    -- Bottom bar
    local bottomBar = CreateFrame("Frame", nil, rightPanel)
    bottomBar:SetHeight(40)
    bottomBar:SetPoint("BOTTOMLEFT", 0, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", 0, 0)
    
    local status = bottomBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status:SetPoint("LEFT", S("SM"), 0)
    status:SetTextColor(T("TEXT_SECONDARY"))
    MainWindow.status = status
    
    local scanBtn = GUI:CreateButton(nil, bottomBar, "Rescan", 80, C.BUTTON_HEIGHT)
    scanBtn:SetPoint("RIGHT", -S("SM"), 0)
    scanBtn:SetScript("OnClick", function()
        CVarMaster.CVarScanner:RefreshCache()
        GUI:RefreshCVarList()
    end)
    
    local backupBtn = GUI:CreateButton(nil, bottomBar, "Backup", 80, C.BUTTON_HEIGHT)
    backupBtn:SetPoint("RIGHT", scanBtn, "LEFT", -S("SM"), 0)
    backupBtn:SetScript("OnClick", function()
        if CVarMaster.CVarManager then
            CVarMaster.CVarManager:BackupAll()
        end
    end)
    
    local modifiedBtn = GUI:CreateButton(nil, bottomBar, "Modified Only", 100, C.BUTTON_HEIGHT)
    modifiedBtn:SetPoint("RIGHT", backupBtn, "LEFT", -S("SM"), 0)
    modifiedBtn.showModified = false
    modifiedBtn:SetScript("OnClick", function(self)
        self.showModified = not self.showModified
        self.text:SetText(self.showModified and "Show All" or "Modified Only")
        GUI:RefreshCVarList()
    end)
    MainWindow.modifiedBtn = modifiedBtn

    -- Profiles button
    local profileBtn = GUI:CreateButton(nil, bottomBar, "Profiles", 80, C.BUTTON_HEIGHT)
    profileBtn:SetPoint("RIGHT", modifiedBtn, "LEFT", -S("SM"), 0)
    profileBtn:SetScript("OnClick", function()
        if GUI.ShowProfileWindow then
            GUI:ShowProfileWindow()
        end
    end)
    profileBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Profile Manager", 1, 1, 1)
        GameTooltip:AddLine("Save, load, and share CVar profiles", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    profileBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- WeakAura Export button
    local waExportBtn = GUI:CreateButton(nil, bottomBar, "WA Export", 80, C.BUTTON_HEIGHT)
    waExportBtn:SetPoint("RIGHT", profileBtn, "LEFT", -S("SM"), 0)
    waExportBtn:SetScript("OnClick", function()
        if CVarMaster.WeakAuraExport then
            CVarMaster.WeakAuraExport:ShowExportDialog()
        end
    end)
    waExportBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Export to WeakAura", 1, 1, 1)
        GameTooltip:AddLine("Generate init script for modified CVars", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Paste into WeakAura Init Action", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    waExportBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
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
    
    pcall(function() GUI:RefreshCVarList() end)
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

function GUI:GetMainWindow()
    return MainWindow
end
