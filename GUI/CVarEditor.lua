---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local Constants = CVarMaster.Constants

-- Pool of reusable row frames
local rowPool = {}
local activeRows = {}

-- Local theme helpers
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

local function GetRowHeight()
    return (Constants and Constants.GUI and Constants.GUI.ROW_HEIGHT) or 24
end

---Create a CVar row
---@param parent Frame Parent frame
---@param index number Row index
---@return Frame row
local function CreateRow(parent, index)
    local ROW_HEIGHT = GetRowHeight()
    
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(ROW_HEIGHT)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    
    -- Alternating row colors (softer)
    if index % 2 == 0 then
        row.normalColor = { T("ROW_ALT") }
    else
        row.normalColor = { 0, 0, 0, 0 }
    end
    row:SetBackdropColor(unpack(row.normalColor))
    
    -- Hover highlight
    row:EnableMouse(true)
    
    -- Modified indicator (left edge) - softer color
    row.modifiedBar = row:CreateTexture(nil, "OVERLAY")
    row.modifiedBar:SetWidth(3)
    row.modifiedBar:SetPoint("TOPLEFT", 0, -2)
    row.modifiedBar:SetPoint("BOTTOMLEFT", 0, 2)
    row.modifiedBar:SetColorTexture(0.95, 0.75, 0.25, 1)
    row.modifiedBar:Hide()
    
    -- CVar name (friendly name) - more prominent
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.nameText:SetPoint("LEFT", S("MD"), 0)
    row.nameText:SetWidth(220)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetTextColor(T("TEXT_PRIMARY"))
    
    -- Technical name (smaller, muted)
    row.techName = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.techName:SetPoint("LEFT", row.nameText, "RIGHT", S("SM"), 0)
    row.techName:SetWidth(160)
    row.techName:SetJustifyH("LEFT")
    row.techName:SetTextColor(T("TEXT_MUTED"))
    
    -- Current value display
    row.valueText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.valueText:SetPoint("LEFT", row.techName, "RIGHT", S("SM"), 0)
    row.valueText:SetWidth(90)
    row.valueText:SetJustifyH("RIGHT")
    
    -- Value editor (appears on click)
    row.editBox = GUI:CreateEditBox(nil, row, 90, 22)
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
            GUI:ShowCVarContextMenu(self, self.cvarData)
        end
    end)
    
    -- Default value (smaller, muted)
    row.defaultText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.defaultText:SetPoint("LEFT", row.valueText, "RIGHT", S("MD"), 0)
    row.defaultText:SetWidth(90)
    row.defaultText:SetJustifyH("RIGHT")
    row.defaultText:SetTextColor(T("TEXT_MUTED"))
    
    -- Reset button
    row.resetBtn = GUI:CreateButton(nil, row, "Reset", 55, 22)
    row.resetBtn:SetPoint("LEFT", row.defaultText, "RIGHT", S("SM"), 0)
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
    row.warningIcon:SetPoint("RIGHT", -S("SM"), 0)
    row.warningIcon:SetText("|cffff6644!|r")
    row.warningIcon:Hide()
    
    -- Hover/Leave handlers
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(T("ROW_HOVER"))
        if self.cvarData then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            
            -- Header
            local r, g, b = T("ACCENT_PRIMARY")
            GameTooltip:AddLine(self.cvarData.friendlyName, r, g, b)
            GameTooltip:AddLine(self.cvarData.name, 0.5, 0.5, 0.5)
            
            -- Description
            if self.cvarData.description and self.cvarData.description ~= "" then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(self.cvarData.description, 1, 1, 1, true)
            end
            
            -- Values
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Current:", self.cvarData.value, 0.7, 0.7, 0.7, 1, 1, 1)
            GameTooltip:AddDoubleLine("Default:", self.cvarData.defaultValue, 0.7, 0.7, 0.7, 0.6, 0.6, 0.6)
            GameTooltip:AddDoubleLine("Type:", self.cvarData.dataType, 0.7, 0.7, 0.7, 0.6, 0.6, 0.6)
            
            -- Warnings
            if self.cvarData.requiresReload then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff8888ffRequires UI Reload|r")
            end
            if self.cvarData.dangerLevel and self.cvarData.dangerLevel > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cffff6644" .. (self.cvarData.dangerWarning or "Use with caution!") .. "|r")
            end
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff888888Left-click to edit  |  Right-click for description|r")
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
    local ROW_HEIGHT = GetRowHeight()
    
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
    
    -- Warning for dangerous CVars (softer orange instead of red)
    if cvarData.dangerLevel and cvarData.dangerLevel > 0 then
        row.warningIcon:Show()
        if cvarData.dangerLevel >= Constants.DANGER_LEVELS.DANGEROUS then
            row.warningIcon:SetText("|cffff5533!!|r")
        else
            row.warningIcon:SetText("|cffffaa44!|r")
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

    local ROW_HEIGHT = GetRowHeight()

    -- Get search term from searchbox if not provided (preserves filter after edits)
    if not searchTerm and mainWindow.searchBox then
        searchTerm = mainWindow.searchBox:GetText()
    end

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

-- Description popup frame (created once, reused)
local descriptionPopup = nil

local function CreateDescriptionPopup()
    if descriptionPopup then return descriptionPopup end

    local popup = CreateFrame("Frame", "CVarMasterDescPopup", UIParent, "BackdropTemplate")
    popup:SetSize(400, 200)
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(100)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)

    -- Dark theme background
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    popup:SetBackdropColor(0.08, 0.09, 0.08, 0.98)
    popup:SetBackdropBorderColor(0.35, 0.55, 0.38, 0.8)

    -- Title bar
    popup.titleBar = CreateFrame("Frame", nil, popup, "BackdropTemplate")
    popup.titleBar:SetHeight(28)
    popup.titleBar:SetPoint("TOPLEFT", 2, -2)
    popup.titleBar:SetPoint("TOPRIGHT", -2, -2)
    popup.titleBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    popup.titleBar:SetBackdropColor(0.12, 0.16, 0.12, 1)

    -- Title text (friendly name)
    popup.title = popup.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    popup.title:SetPoint("LEFT", 10, 0)
    popup.title:SetTextColor(0.55, 0.85, 0.58, 1)

    -- Close button
    popup.closeBtn = CreateFrame("Button", nil, popup.titleBar)
    popup.closeBtn:SetSize(20, 20)
    popup.closeBtn:SetPoint("RIGHT", -4, 0)
    popup.closeBtn:SetNormalFontObject("GameFontNormal")
    popup.closeBtn.text = popup.closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popup.closeBtn.text:SetPoint("CENTER")
    popup.closeBtn.text:SetText("X")
    popup.closeBtn.text:SetTextColor(0.8, 0.8, 0.8)
    popup.closeBtn:SetScript("OnClick", function() popup:Hide() end)
    popup.closeBtn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 0.3, 0.3) end)
    popup.closeBtn:SetScript("OnLeave", function(self) self.text:SetTextColor(0.8, 0.8, 0.8) end)

    -- Technical name
    popup.techName = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    popup.techName:SetPoint("TOPLEFT", popup.titleBar, "BOTTOMLEFT", 10, -8)
    popup.techName:SetTextColor(0.5, 0.5, 0.5)

    -- Separator line
    popup.sep = popup:CreateTexture(nil, "ARTWORK")
    popup.sep:SetHeight(1)
    popup.sep:SetPoint("TOPLEFT", popup.techName, "BOTTOMLEFT", -5, -8)
    popup.sep:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -10, 0)
    popup.sep:SetColorTexture(0.3, 0.4, 0.32, 0.5)

    -- Description text (scrollable)
    popup.scrollFrame = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    popup.scrollFrame:SetPoint("TOPLEFT", popup.sep, "BOTTOMLEFT", 0, -8)
    popup.scrollFrame:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -28, 50)

    popup.descText = CreateFrame("Frame", nil, popup.scrollFrame)
    popup.descText:SetSize(350, 100)
    popup.scrollFrame:SetScrollChild(popup.descText)

    popup.descLabel = popup.descText:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    popup.descLabel:SetPoint("TOPLEFT", 5, -5)
    popup.descLabel:SetWidth(340)
    popup.descLabel:SetJustifyH("LEFT")
    popup.descLabel:SetJustifyV("TOP")
    popup.descLabel:SetSpacing(3)

    -- Info section at bottom
    popup.infoFrame = CreateFrame("Frame", nil, popup, "BackdropTemplate")
    popup.infoFrame:SetHeight(40)
    popup.infoFrame:SetPoint("BOTTOMLEFT", 2, 2)
    popup.infoFrame:SetPoint("BOTTOMRIGHT", -2, 2)
    popup.infoFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    popup.infoFrame:SetBackdropColor(0.06, 0.07, 0.06, 1)

    popup.currentLabel = popup.infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    popup.currentLabel:SetPoint("LEFT", 10, 6)
    popup.currentLabel:SetTextColor(0.6, 0.6, 0.6)

    popup.currentValue = popup.infoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    popup.currentValue:SetPoint("LEFT", popup.currentLabel, "RIGHT", 5, 0)

    popup.defaultLabel = popup.infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    popup.defaultLabel:SetPoint("LEFT", 10, -8)
    popup.defaultLabel:SetTextColor(0.6, 0.6, 0.6)

    popup.defaultValue = popup.infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    popup.defaultValue:SetPoint("LEFT", popup.defaultLabel, "RIGHT", 5, 0)
    popup.defaultValue:SetTextColor(0.5, 0.5, 0.5)

    popup.typeLabel = popup.infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    popup.typeLabel:SetPoint("RIGHT", -10, 0)
    popup.typeLabel:SetTextColor(0.5, 0.5, 0.5)

    -- Hide on escape
    popup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            self:SetPropagateKeyboardInput(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    popup:Hide()
    descriptionPopup = popup
    return popup
end

---Show description popup for a CVar
---@param anchor Frame Anchor frame
---@param cvarData table CVar data
function GUI:ShowCVarContextMenu(anchor, cvarData)
    local popup = CreateDescriptionPopup()

    -- Set content
    popup.title:SetText(cvarData.friendlyName or cvarData.name)
    popup.techName:SetText("CVar: " .. cvarData.name)

    -- Description
    local desc = cvarData.description
    if not desc or desc == "" then
        desc = "No description available for this CVar."
    end
    popup.descLabel:SetText(desc)

    -- Adjust scroll content height based on text
    local textHeight = popup.descLabel:GetStringHeight() + 20
    popup.descText:SetHeight(math.max(50, textHeight))

    -- Current/Default values
    popup.currentLabel:SetText("Current:")
    popup.currentValue:SetText(cvarData.value)
    if cvarData.isModified then
        popup.currentValue:SetTextColor(1, 0.9, 0.3) -- Yellow for modified
    else
        popup.currentValue:SetTextColor(0.3, 1, 0.3) -- Green for default
    end

    popup.defaultLabel:SetText("Default:")
    popup.defaultValue:SetText(cvarData.defaultValue or "?")

    -- Type
    popup.typeLabel:SetText("Type: " .. (cvarData.dataType or "unknown"))

    -- Position near anchor
    popup:ClearAllPoints()
    popup:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 10, 0)

    -- Show
    popup:Show()
    popup:Raise()
end
