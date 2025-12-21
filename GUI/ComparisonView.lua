---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI

local CompareWindow = nil

---Show comparison window
---@param compareType string "default" or "backup"
function GUI:ShowComparisonWindow(compareType)
    if not CompareWindow then
        CompareWindow = GUI:CreateFrame("CVarMasterCompareWindow", UIParent, 500, 450)
        CompareWindow:SetPoint("CENTER", 200, 0)
        CompareWindow:SetMovable(true)
        CompareWindow:EnableMouse(true)
        CompareWindow:RegisterForDrag("LeftButton")
        CompareWindow:SetScript("OnDragStart", CompareWindow.StartMoving)
        CompareWindow:SetScript("OnDragStop", CompareWindow.StopMovingOrSizing)
        CompareWindow:SetFrameStrata("DIALOG")
        
        -- Title
        CompareWindow.title = CompareWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        CompareWindow.title:SetPoint("TOP", 0, -12)
        
        -- Close button
        local closeBtn = GUI:CreateButton(nil, CompareWindow, "X", 24, 24)
        closeBtn:SetPoint("TOPRIGHT", -4, -4)
        closeBtn:SetScript("OnClick", function() CompareWindow:Hide() end)
        
        -- Header row
        local header = CreateFrame("Frame", nil, CompareWindow)
        header:SetHeight(24)
        header:SetPoint("TOPLEFT", 10, -40)
        header:SetPoint("TOPRIGHT", -10, -40)
        
        local h1 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h1:SetPoint("LEFT", 0, 0)
        h1:SetWidth(180)
        h1:SetText("|cff00ff00CVar|r")
        
        local h2 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h2:SetPoint("LEFT", 190, 0)
        h2:SetWidth(100)
        h2:SetText("|cff00ff00Current|r")
        
        CompareWindow.compareHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        CompareWindow.compareHeader:SetPoint("LEFT", 300, 0)
        CompareWindow.compareHeader:SetWidth(100)
        
        -- Scroll list
        local listContainer, listContent = GUI:CreateScrollFrame("CVarMasterCompareList", CompareWindow, 480, 340)
        listContainer:SetPoint("TOP", 0, -68)
        CompareWindow.listContent = listContent
        
        -- Apply all button
        local applyBtn = GUI:CreateButton(nil, CompareWindow, "Apply All Changes", 140, 28)
        applyBtn:SetPoint("BOTTOM", 0, 12)
        CompareWindow.applyBtn = applyBtn
        
        tinsert(UISpecialFrames, "CVarMasterCompareWindow")
    end
    
    -- Configure for compare type
    if compareType == "default" then
        CompareWindow.title:SetText("|cff00ff00Compare: Current vs Defaults|r")
        CompareWindow.compareHeader:SetText("|cffaaaaDefault|r")
    else
        CompareWindow.title:SetText("|cff00ff00Compare: Current vs Backup|r")
        CompareWindow.compareHeader:SetText("|cffaaaaBackup|r")
    end
    
    GUI:RefreshComparison(compareType)
    CompareWindow:Show()
end

---Refresh comparison list
---@param compareType string "default" or "backup"
function GUI:RefreshComparison(compareType)
    if not CompareWindow or not CompareWindow.listContent then return end
    
    local content = CompareWindow.listContent
    
    -- Clear existing
    for _, child in pairs({content:GetChildren()}) do
        child:Hide()
    end
    
    local cvars = CVarMaster.CVarScanner:GetCachedCVars()
    local differences = {}
    
    for name, data in pairs(cvars) do
        local compareValue
        if compareType == "default" then
            compareValue = data.defaultValue
        else
            -- Get from backup
            compareValue = CVarMaster.db.backup and CVarMaster.db.backup[name]
        end
        
        if compareValue and data.value ~= compareValue then
            table.insert(differences, {
                name = name,
                friendlyName = data.friendlyName,
                current = data.value,
                compare = compareValue
            })
        end
    end
    
    table.sort(differences, function(a, b) return a.friendlyName < b.friendlyName end)
    
    local yOffset = 0
    for _, diff in ipairs(differences) do
        local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
        row:SetHeight(24)
        row:SetPoint("TOPLEFT", 0, yOffset)
        row:SetPoint("TOPRIGHT", 0, yOffset)
        row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
        row:SetBackdropColor(0.08, 0.08, 0.1, 0.8)
        
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", 4, 0)
        nameText:SetWidth(180)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(diff.friendlyName)
        nameText:SetTextColor(0.8, 0.8, 0.8)
        
        local currentText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        currentText:SetPoint("LEFT", 190, 0)
        currentText:SetWidth(100)
        currentText:SetText(diff.current)
        currentText:SetTextColor(1, 0.8, 0.3)
        
        local compareText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        compareText:SetPoint("LEFT", 300, 0)
        compareText:SetWidth(100)
        compareText:SetText(diff.compare)
        compareText:SetTextColor(0.5, 0.5, 0.5)
        
        local applyBtn = GUI:CreateButton(nil, row, "Apply", 50, 20)
        applyBtn:SetPoint("RIGHT", -4, 0)
        applyBtn:SetScript("OnClick", function()
            CVarMaster.CVarManager:SetCVar(diff.name, diff.compare)
            CVarMaster.CVarScanner:UpdateCVarInCache(diff.name)
            GUI:RefreshComparison(compareType)
            GUI:RefreshCVarList()
        end)
        
        yOffset = yOffset - 26
    end
    
    content:SetHeight(math.max(1, math.abs(yOffset)))
    
    if #differences == 0 then
        local noDiff = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noDiff:SetPoint("CENTER")
        noDiff:SetText("|cff666666No differences found|r")
    end
    
    -- Configure apply all button
    CompareWindow.applyBtn:SetScript("OnClick", function()
        for _, diff in ipairs(differences) do
            CVarMaster.CVarManager:SetCVar(diff.name, diff.compare)
        end
        CVarMaster.CVarScanner:RefreshCache()
        GUI:RefreshComparison(compareType)
        GUI:RefreshCVarList()
        CVarMaster.Utils.Print("Applied", #differences, "changes")
    end)
end

CVarMaster.Utils.Debug("ComparisonView module loaded")
