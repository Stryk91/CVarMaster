---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local Constants = CVarMaster.Constants

local MainWindow = nil
local isInitialized = false
local currentScale = 1.0

function GUI:InitMainWindow()
    if isInitialized then return end
    
    if not Constants or not Constants.GUI then return end
    
    local C = Constants.GUI
    
    -- Create main frame
    MainWindow = GUI:CreateFrame("CVarMasterMainWindow", UIParent, C.WINDOW_WIDTH, C.WINDOW_HEIGHT)
    if not MainWindow then return end
    
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
    titleBar:SetHeight(32)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    titleBar:SetBackdropColor(0.1, 0.3, 0.1, 0.95)
    titleBar:SetBackdropBorderColor(0, 0.8, 0, 0.8)
    
    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", 12, 0)
    title:SetText("|cff00aaffCVar|r|cffffffffMaster|r")
    
    -- Version
    local version = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    version:SetPoint("LEFT", title, "RIGHT", 8, 0)
    version:SetText("v" .. Constants.VERSION)
    version:SetTextColor(0.5, 0.5, 0.5)
    
    -- Close button
    local closeBtn = GUI:CreateButton(nil, titleBar, "X", 28, 28)
    closeBtn:SetPoint("RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function() MainWindow:Hide() end)
    
    -- ========== SCALE SLIDER (using OptionsSliderTemplate) ==========
    local scaleContainer = CreateFrame("Frame", nil, titleBar)
    scaleContainer:SetSize(160, 28)
    scaleContainer:SetPoint("RIGHT", closeBtn, "LEFT", -16, 0)
    
    -- Scale label
    local scaleLabel = scaleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleLabel:SetPoint("LEFT", 0, 0)
    scaleLabel:SetText("Scale:")
    scaleLabel:SetTextColor(0.7, 0.7, 0.7)
    
    -- Use proper WoW slider template
    local scaleSlider = CreateFrame("Slider", "CVarMasterScaleSlider", scaleContainer, "OptionsSliderTemplate")
    scaleSlider:SetSize(80, 17)
    scaleSlider:SetPoint("LEFT", scaleLabel, "RIGHT", 8, 0)
    scaleSlider:SetMinMaxValues(60, 140)
    scaleSlider:SetValueStep(5)
    scaleSlider:SetObeyStepOnDrag(true)
    
    -- Hide the default low/high text
    scaleSlider.Low:SetText("")
    scaleSlider.High:SetText("")
    scaleSlider.Text:SetText("")
    
    -- Scale value display
    local scaleValue = scaleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleValue:SetPoint("LEFT", scaleSlider, "RIGHT", 6, 0)
    scaleValue:SetWidth(35)
    scaleValue:SetJustifyH("LEFT")
    scaleValue:SetTextColor(0.8, 1, 0.8)
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
    
    -- Only update on mouse up to prevent spazzing
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / 5 + 0.5) * 5 -- Round to nearest 5
        scaleValue:SetText(value .. "%")
    end)
    
    scaleSlider:SetScript("OnMouseUp", function(self)
        local value = math.floor(self:GetValue() / 5 + 0.5) * 5
        currentScale = value / 100
        MainWindow:SetScale(currentScale)
        
        -- Save to DB
        if CVarMaster.db and CVarMaster.db.global then
            CVarMaster.db.global.windowScale = currentScale
        end
    end)
    
    -- Tooltip
    scaleSlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Window Scale", 1, 1, 1)
        GameTooltip:AddLine("Drag to resize window (60% - 140%)", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Release to apply", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    scaleSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    MainWindow.scaleSlider = scaleSlider
    -- ========== END SCALE SLIDER ==========
    
    -- Content area
    local content = CreateFrame("Frame", nil, MainWindow)
    content:SetPoint("TOPLEFT", 0, -32)
    content:SetPoint("BOTTOMRIGHT", 0, 0)
    MainWindow.content = content
    
    -- Left sidebar
    local sidebar = GUI:CreateFrame(nil, content, C.CATEGORY_WIDTH, 1)
    sidebar:SetPoint("TOPLEFT", 4, -4)
    sidebar:SetPoint("BOTTOMLEFT", 4, 4)
    sidebar:SetBackdropColor(0.03, 0.03, 0.05, 0.9)
    MainWindow.sidebar = sidebar
    
    -- Search box
    local searchBox = GUI:CreateEditBox("CVarMasterSearch", sidebar, C.CATEGORY_WIDTH - 16, 26)
    searchBox:SetPoint("TOPLEFT", 8, -8)
    searchBox:SetPoint("TOPRIGHT", -8, -8)
    
    local searchIcon = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchIcon:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
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
    rightPanel:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 4, 0)
    rightPanel:SetPoint("BOTTOMRIGHT", -4, 4)
    MainWindow.rightPanel = rightPanel
    
    -- CVar list
    local listContainer, listContent = GUI:CreateScrollFrame("CVarMasterList", rightPanel, 
        C.WINDOW_WIDTH - C.CATEGORY_WIDTH - 20, C.WINDOW_HEIGHT - 80)
    listContainer:SetPoint("TOPLEFT", 0, -4)
    listContainer:SetPoint("BOTTOMRIGHT", 0, 40)
    MainWindow.listContainer = listContainer
    MainWindow.listContent = listContent
    
    -- Bottom bar
    local bottomBar = CreateFrame("Frame", nil, rightPanel)
    bottomBar:SetHeight(36)
    bottomBar:SetPoint("BOTTOMLEFT", 0, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", 0, 0)
    
    local status = bottomBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("LEFT", 8, 0)
    status:SetTextColor(0.6, 0.6, 0.6)
    MainWindow.status = status
    
    local scanBtn = GUI:CreateButton(nil, bottomBar, "Rescan", 70, 26)
    scanBtn:SetPoint("RIGHT", -8, 0)
    scanBtn:SetScript("OnClick", function()
        CVarMaster.CVarScanner:RefreshCache()
        GUI:RefreshCVarList()
    end)
    
    local backupBtn = GUI:CreateButton(nil, bottomBar, "Backup", 70, 26)
    backupBtn:SetPoint("RIGHT", scanBtn, "LEFT", -4, 0)
    backupBtn:SetScript("OnClick", function()
        if CVarMaster.CVarManager then
            CVarMaster.CVarManager:BackupAll()
        end
    end)
    
    local modifiedBtn = GUI:CreateButton(nil, bottomBar, "Modified Only", 90, 26)
    modifiedBtn:SetPoint("RIGHT", backupBtn, "LEFT", -4, 0)
    modifiedBtn.showModified = false
    modifiedBtn:SetScript("OnClick", function(self)
        self.showModified = not self.showModified
        self.text:SetText(self.showModified and "Show All" or "Modified Only")
        GUI:RefreshCVarList()
    end)
    MainWindow.modifiedBtn = modifiedBtn
    
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


