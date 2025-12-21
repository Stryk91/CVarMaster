---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local Constants = CVarMaster.Constants

-- Pool of reusable row frames
local rowPool = {}
local activeRows = {}
local ROW_HEIGHT = 28

---Create a CVar row
---@param parent Frame Parent frame
---@param index number Row index
---@return Frame row
local function CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(ROW_HEIGHT)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    
    -- Alternating row colors
    row.normalColor = (index % 2 == 0) and {0.06, 0.06, 0.08, 0.8} or {0.04, 0.04, 0.06, 0.8}
    row:SetBackdropColor(unpack(row.normalColor))
    
    -- Hover highlight
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.1, 0.2, 0.1, 0.9)
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(self.normalColor))
    end)
    
    -- Modified indicator (left edge)
    row.modifiedBar = row:CreateTexture(nil, "OVERLAY")
    row.modifiedBar:SetWidth(3)
    row.modifiedBar:SetPoint("TOPLEFT", 0, 0)
    row.modifiedBar:SetPoint("BOTTOMLEFT", 0, 0)
    row.modifiedBar:SetColorTexture(1, 0.8, 0, 1)
    row.modifiedBar:Hide()
    
    -- CVar name (friendly name)
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetPoint("LEFT", 12, 0)
    row.nameText:SetWidth(200)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetTextColor(0.9, 0.9, 0.9)
    
    -- Technical name (smaller, gray)
    row.techName = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.techName:SetPoint("LEFT", row.nameText, "RIGHT", 8, 0)
    row.techName:SetWidth(150)
    row.techName:SetJustifyH("LEFT")
    row.techName:SetTextColor(0.4, 0.4, 0.4)
    row.techName:SetFont(row.techName:GetFont(), 10)
    
    -- Current value display
    row.valueText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.valueText:SetPoint("LEFT", row.techName, "RIGHT", 8, 0)
    row.valueText:SetWidth(80)
    row.valueText:SetJustifyH("RIGHT")
    
    -- Value editor (appears on click)
    row.editBox = GUI:CreateEditBox(nil, row, 80, 20)
    row.editBox:SetPoint("LEFT", row.valueText, "LEFT", -4, 0)
    row.editBox:Hide()
    
    row.editBox:SetScript("OnEnterPressed", function(self)
        local newValue = self:GetText()
        if row.cvarData then
            CVarMaster.CVarManager:SetCVar(row.cvarData.name, newValue)
            CVarMaster.CVarScanner:UpdateCVarInCache(row.cvarData.name)
            GUI:RefreshCVarList()
        end
        self:Hide()
        row.valueText:Show()
    end)
    
    row.editBox:SetScript("OnEscapePressed", function(self)
        self:Hide()
        row.valueText:Show()
    end)
    
    -- Click to edit
    row:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and self.cvarData then
            self.valueText:Hide()
            self.editBox:SetText(self.cvarData.value)
            self.editBox:Show()
            self.editBox:SetFocus()
            self.editBox:HighlightText()
        elseif button == "RightButton" and self.cvarData then
            -- Show context menu
            GUI:ShowCVarContextMenu(self, self.cvarData)
        end
    end)
    
    -- Default value (smaller text)
    row.defaultText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.defaultText:SetPoint("LEFT", row.valueText, "RIGHT", 16, 0)
    row.defaultText:SetWidth(80)
    row.defaultText:SetJustifyH("RIGHT")
    row.defaultText:SetTextColor(0.4, 0.4, 0.4)
    row.defaultText:SetFont(row.defaultText:GetFont(), 10)
    
    -- Reset button
    row.resetBtn = GUI:CreateButton(nil, row, "Reset", 50, 20)
    row.resetBtn:SetPoint("LEFT", row.defaultText, "RIGHT", 8, 0)
    row.resetBtn:Hide()
    row.resetBtn:SetScript("OnClick", function()
        if row.cvarData then
            CVarMaster.CVarManager:ResetCVar(row.cvarData.name)
            CVarMaster.CVarScanner:UpdateCVarInCache(row.cvarData.name)
            GUI:RefreshCVarList()
        end
    end)
    
    -- Warning icon for dangerous CVars
    row.warningIcon = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.warningIcon:SetPoint("RIGHT", -8, 0)
    row.warningIcon:SetText("|cffff0000!|r")
    row.warningIcon:Hide()
    
    -- Tooltip
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.1, 0.2, 0.1, 0.9)
        if self.cvarData then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.cvarData.friendlyName, 0, 1, 0)
            GameTooltip:AddLine(self.cvarData.name, 0.5, 0.5, 0.5)
            if self.cvarData.description and self.cvarData.description ~= "" then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(self.cvarData.description, 1, 1, 1, true)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Current:", self.cvarData.value, 0.7, 0.7, 0.7, 1, 1, 1)
            GameTooltip:AddDoubleLine("Default:", self.cvarData.defaultValue, 0.7, 0.7, 0.7, 0.6, 0.6, 0.6)
            GameTooltip:AddDoubleLine("Type:", self.cvarData.dataType, 0.7, 0.7, 0.7, 0.6, 0.6, 0.6)
            if self.cvarData.requiresReload then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff8888ffRequires UI Reload|r")
            end
            if self.cvarData.dangerLevel > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cffff0000" .. (self.cvarData.dangerWarning or "Use with caution!") .. "|r")
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff888888Left-click to edit, Right-click for options|r")
            GameTooltip:Show()
        end
    end)
    
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(self.normalColor))
        GameTooltip:Hide()
    end)
    
    return row
end

---Get or create a row
---@param parent Frame Parent frame
---@param index number Row index
---@return Frame row
local function GetRow(parent, index)
    if rowPool[index] then
        local row = rowPool[index]
        row:SetParent(parent)
        row:Show()
        return row
    end
    
    local row = CreateRow(parent, index)
    rowPool[index] = row
    return row
end

---Populate a row with CVar data
---@param row Frame Row frame
---@param cvarData table CVar data
---@param index number Row index
local function PopulateRow(row, cvarData, index)
    row.cvarData = cvarData
    row.index = index
    
    -- Position
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
    row:SetPoint("TOPRIGHT", 0, -((index - 1) * ROW_HEIGHT))
    
    -- Name
    row.nameText:SetText(cvarData.friendlyName or cvarData.name)
    row.techName:SetText(cvarData.name)
    
    -- Value with color coding
    local valueColor = Constants.COLORS.DEFAULT
    if cvarData.isModified then
        valueColor = Constants.COLORS.MODIFIED
        row.modifiedBar:Show()
        row.resetBtn:Show()
    else
        row.modifiedBar:Hide()
        row.resetBtn:Hide()
    end
    
    row.valueText:SetText(cvarData.value)
    row.valueText:SetTextColor(valueColor.r, valueColor.g, valueColor.b)
    
    -- Default value
    row.defaultText:SetText("(" .. (cvarData.defaultValue or "?") .. ")")
    
    -- Warning for dangerous CVars
    if cvarData.dangerLevel and cvarData.dangerLevel > 0 then
        row.warningIcon:Show()
        if cvarData.dangerLevel >= Constants.DANGER_LEVELS.DANGEROUS then
            row.warningIcon:SetText("|cffff0000!!|r")
        else
            row.warningIcon:SetText("|cffffaa00!|r")
        end
    else
        row.warningIcon:Hide()
    end
    
    -- Reset edit state
    row.editBox:Hide()
    row.valueText:Show()
    
    row:Show()
end

---Refresh the CVar list
---@param searchTerm string|nil Search term
function GUI:RefreshCVarList(searchTerm)
    local mainWindow = GUI:GetMainWindow()
    if not mainWindow then return end
    
    local content = mainWindow.listContent
    if not content then return end
    
    -- Get CVars
    local cvars = CVarMaster.CVarScanner:GetCachedCVars()
    
    -- Filter by category
    local selectedCat = GUI:GetSelectedCategory()
    if selectedCat and selectedCat ~= "All" then
        cvars = CVarMaster.CVarScanner:FilterByCategory(selectedCat, cvars)
    end
    
    -- Filter by search
    if searchTerm and searchTerm ~= "" then
        cvars = CVarMaster.CVarScanner:SearchCVars(searchTerm, cvars)
    end
    
    -- Filter modified only if toggled
    if mainWindow.modifiedBtn and mainWindow.modifiedBtn.showModified then
        cvars = CVarMaster.CVarScanner:FilterModified(cvars)
    end
    
    -- Sort by friendly name
    local sorted = {}
    for name, data in pairs(cvars) do
        table.insert(sorted, data)
    end
    table.sort(sorted, function(a, b)
        return (a.friendlyName or a.name) < (b.friendlyName or b.name)
    end)
    
    -- Hide all existing rows
    for _, row in pairs(activeRows) do
        row:Hide()
    end
    activeRows = {}
    
    -- Populate rows
    local index = 1
    for _, cvarData in ipairs(sorted) do
        local row = GetRow(content, index)
        PopulateRow(row, cvarData, index)
        activeRows[index] = row
        index = index + 1
    end
    
    -- Update content height
    content:SetHeight(math.max(1, #sorted * ROW_HEIGHT))
    
    -- Update status
    if mainWindow.status then
        mainWindow.status:SetText(string.format("%d CVars", #sorted))
    end
    
    -- Update category counts
    local categoryCounts = CVarMaster.CVarScanner:GetCategoryCounts()
    GUI:UpdateCategoryCounts(categoryCounts)
end

---Show context menu for a CVar
---@param anchor Frame Anchor frame
---@param cvarData table CVar data
function GUI:ShowCVarContextMenu(anchor, cvarData)
    local menu = {
        { text = cvarData.friendlyName, isTitle = true },
        { text = "Copy Name", func = function()
            -- No clipboard in WoW, just print it
            print("CVar: " .. cvarData.name)
        end },
        { text = "Copy Value", func = function()
            print("Value: " .. cvarData.value)
        end },
    }
    
    if cvarData.isModified then
        table.insert(menu, { text = "Reset to Default", func = function()
            CVarMaster.CVarManager:ResetCVar(cvarData.name)
            CVarMaster.CVarScanner:UpdateCVarInCache(cvarData.name)
            GUI:RefreshCVarList()
        end })
    end
    
    if cvarData.dataType == "boolean" then
        local newVal = (cvarData.value == "1" or cvarData.value == "true") and "0" or "1"
        table.insert(menu, { text = "Toggle Value", func = function()
            CVarMaster.CVarManager:SetCVar(cvarData.name, newVal)
            CVarMaster.CVarScanner:UpdateCVarInCache(cvarData.name)
            GUI:RefreshCVarList()
        end })
    end
    
    -- Use EasyMenu if available, otherwise create simple dropdown
    if EasyMenu then
        EasyMenu(menu, CreateFrame("Frame", nil, anchor, "UIDropDownMenuTemplate"), anchor, 0, 0, "MENU")
    end
end




