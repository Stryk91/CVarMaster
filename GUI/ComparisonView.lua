---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI

local CompareWindow = nil

---Show comparison window
---@param compareType string "default" or "backup"
function GUI:ShowComparisonWindow(compareType)
    if not CompareWindow then
        CompareWindow = GUI:CreateNihilumFrame("CVarMasterCompareWindow", UIParent)
        CompareWindow:SetSize(500, 450)
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
        CompareWindow.compareHeader:SetText("|cffaaaaaaDefault|r")
    else
        CompareWindow.title:SetText("|cff00ff00Compare: Current vs Backup|r")
        CompareWindow.compareHeader:SetText("|cffaaaaaaBackup|r")
    end
    
    GUI:RefreshComparison(compareType)
    CompareWindow:Show()
end

---Acquire a pooled row (WoW never GC's frames, so rebuild-per-refresh leaks)
local function AcquireCompareRow(content, index)
    CompareWindow.rows = CompareWindow.rows or {}
    local row = CompareWindow.rows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, content, "BackdropTemplate")
    row:SetHeight(24)
    row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
    row:SetBackdropColor(0.08, 0.08, 0.1, 0.8)

    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetPoint("LEFT", 4, 0)
    row.nameText:SetWidth(180)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetTextColor(0.8, 0.8, 0.8)

    row.currentText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.currentText:SetPoint("LEFT", 190, 0)
    row.currentText:SetWidth(100)
    row.currentText:SetTextColor(1, 0.8, 0.3)

    row.compareText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.compareText:SetPoint("LEFT", 300, 0)
    row.compareText:SetWidth(100)
    row.compareText:SetTextColor(0.5, 0.5, 0.5)

    row.applyBtn = GUI:CreateButton(nil, row, "Apply", 50, 20)
    row.applyBtn:SetPoint("RIGHT", -4, 0)

    CompareWindow.rows[index] = row
    return row
end

---Refresh comparison list
---@param compareType string "default" or "backup"
function GUI:RefreshComparison(compareType)
    if not CompareWindow or not CompareWindow.listContent then return end

    local content = CompareWindow.listContent

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
                label = data.friendlyName or name,
                current = data.value,
                compare = compareValue
            })
        end
    end

    table.sort(differences, function(a, b) return a.label < b.label end)

    local yOffset = 0
    for i, diff in ipairs(differences) do
        local row = AcquireCompareRow(content, i)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, yOffset)
        row:SetPoint("TOPRIGHT", 0, yOffset)
        row.nameText:SetText(diff.label)
        row.currentText:SetText(diff.current)
        row.compareText:SetText(diff.compare)
        row.applyBtn:SetScript("OnClick", function()
            CVarMaster.CVarManager:SetCVar(diff.name, diff.compare)
            GUI:RefreshComparison(compareType)
            GUI:RefreshCVarList()
        end)
        row:Show()
        yOffset = yOffset - 26
    end

    -- Hide pooled rows beyond this refresh's count
    if CompareWindow.rows then
        for i = #differences + 1, #CompareWindow.rows do
            CompareWindow.rows[i]:Hide()
        end
    end

    content:SetHeight(math.max(1, math.abs(yOffset)))

    if not CompareWindow.noDiffText then
        CompareWindow.noDiffText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        CompareWindow.noDiffText:SetPoint("CENTER")
        CompareWindow.noDiffText:SetText("|cff666666No differences found|r")
    end
    CompareWindow.noDiffText:SetShown(#differences == 0)
    
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
