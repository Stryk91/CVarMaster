---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local Constants = CVarMaster.Constants

-- Pool of reusable row frames
local rowPool = {}
local activeRows = {}
local prevSortedCount = nil
GUI._activeRows = activeRows
local sortedData = {}
local BUFFER_ROWS = 4
local scrollHookInstalled = false

-- Use shared theme/spacing helpers from Framework
local T = GUI.GetThemeColor
local S = GUI.GetSpacing

local function GetRowHeight()
    return (Constants and Constants.GUI and Constants.GUI.ROW_HEIGHT) or 24
end

-- Confirmation dialog for the Change Category action. The text uses a
-- generic "%s" placeholder so the call site can pre-format the full
-- message (including count + target category). Avoids argument-order
-- traps in StaticPopup_Show where mismatched %d/%s vs arg types would
-- silently kill the popup before display.
-- data shape: { targets = {names...}, category = "X" or nil }.
-- A nil category clears overrides (resets to default categorization).
StaticPopupDialogs["CVARMASTER_CONFIRM_CATEGORY"] = {
    text = "%s",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if not (data and data.targets) then return end
        if data.category then
            CVarMaster.CVarScanner:BulkSetCategoryOverride(data.targets, data.category)
        else
            for _, name in ipairs(data.targets) do
                CVarMaster.CVarScanner:SetCategoryOverride(name, nil)
            end
        end
        -- Clear selection after a successful batch.
        GUI.checkedCVars = {}
        if GUI.RefreshCVarList then GUI:RefreshCVarList() end
        if GUI.RefreshCategoryList then GUI:RefreshCategoryList() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = STATICPOPUP_NUMDIALOGS,
}

---Create a CVar row
---@param parent Frame Parent frame
---@param index number Row index
---@return Frame row
local function CreateRow(parent, index)
    local ROW_HEIGHT = GetRowHeight()
    
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    -- Background as simple texture (no BackdropTemplate - prevents opacity stacking)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    if GUI.DisableSharpening then GUI.DisableSharpening(row.bg) end

    -- Alternating row colors (very subtle - let void show through)
    if index % 2 == 0 then
        row.normalColor = { T("ROW_ALT") }
        row.bg:SetColorTexture(T("ROW_ALT"))
    else
        row.normalColor = { 0, 0, 0, 0 }
        row.bg:SetColorTexture(0, 0, 0, 0)
    end
    
    -- Hover highlight
    row:EnableMouse(true)

    -- Selection checkbox at the very left, before the modified marker.
    -- Toggling stores into GUI.checkedCVars (session-only set keyed by CVar
    -- name). Used by the description popup's Change Category button to
    -- batch-apply a category override across every checked CVar.
    row.checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.checkbox:SetSize(18, 18)
    row.checkbox:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.checkbox:SetHitRectInsets(-2, -2, -2, -2)
    row.checkbox:SetScript("OnClick", function(self)
        if not row.cvarData then return end
        GUI.checkedCVars = GUI.checkedCVars or {}
        if self:GetChecked() then
            GUI.checkedCVars[row.cvarData.name] = true
        else
            GUI.checkedCVars[row.cvarData.name] = nil
        end
    end)

    -- Modified indicator (left edge) - softer color, positioned just after
    -- the checkbox so they read left-to-right: [check] | [name].
    row.modifiedBar = row:CreateTexture(nil, "OVERLAY")
    row.modifiedBar:SetWidth(3)
    row.modifiedBar:SetPoint("TOPLEFT", 24, -2)
    row.modifiedBar:SetPoint("BOTTOMLEFT", 24, 2)
    row.modifiedBar:SetColorTexture(0.95, 0.75, 0.25, 1)
    row.modifiedBar:Hide()

    -- CVar name (friendly name) - anchored to the right of modifiedBar so
    -- it stays put whether or not the row is modified (anchors persist
    -- across :Hide() on the bar).
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.nameText:SetPoint("LEFT", row.modifiedBar, "RIGHT", S("SM"), 0)
    row.nameText:SetWidth(GUI._colNameW or 180)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)
    row.nameText:SetTextColor(T("TEXT_PRIMARY"))
    
    -- Technical name (smaller, muted)
    row.techName = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.techName:SetPoint("LEFT", row.nameText, "RIGHT", S("SM"), 0)
    row.techName:SetWidth(GUI._colTechW or 190)
    row.techName:SetJustifyH("LEFT")
    row.techName:SetWordWrap(false)
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
    
    -- Lock icon (custom TGA)
    row.lockIcon = row:CreateTexture(nil, "OVERLAY")
    row.lockIcon:SetSize(14, 14)
    row.lockIcon:SetPoint("RIGHT", -S("SM") - 20, 0)
    row.lockIcon:SetTexture("Interface\\AddOns\\CVarMaster\\Textures\\icon_lock")
    row.lockIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.lockIcon:Hide()

    -- Warning icon for dangerous CVars
    row.warningIcon = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.warningIcon:SetPoint("RIGHT", -S("SM"), 0)
    row.warningIcon:SetText("|cffff6644!|r")
    row.warningIcon:Hide()
    
    -- Hover/Leave handlers
    row:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(T("ROW_HOVER"))
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
            
            -- Lock status
            local isLocked = CVarMaster.CVarManager and CVarMaster.CVarManager:IsLocked(self.cvarData.name)
            if isLocked then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff88aaff@ LOCKED|r - persists across sessions")
            end

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
            GameTooltip:AddLine("|cff888888Left-click to edit  |  Right-click for options|r")
            GameTooltip:Show()
        end
    end)
    
    row:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(unpack(self.normalColor))
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

    -- Sync checkbox state from session selection set.
    if row.checkbox then
        row.checkbox:SetChecked((GUI.checkedCVars and GUI.checkedCVars[cvarData.name]) and true or false)
    end

    -- Name
    row.nameText:SetText(cvarData.friendlyName or cvarData.name)
    row.techName:SetText(cvarData.name)
    
    -- Value with color coding
    local valueColor = Constants.COLORS.DEFAULT
    if cvarData.isModified then
        valueColor = Constants.COLORS.MODIFIED
        row.modifiedBar:Show()
        row.resetBtn:Show()
        -- Subtle warm tint so modified rows stand out
        row.normalColor = { 0.12, 0.08, 0.02, 0.25 }
        row.bg:SetColorTexture(0.12, 0.08, 0.02, 0.25)
    else
        row.modifiedBar:Hide()
        row.resetBtn:Hide()
        -- Restore standard alternating color
        if index % 2 == 0 then
            row.normalColor = { T("ROW_ALT") }
            row.bg:SetColorTexture(T("ROW_ALT"))
        else
            row.normalColor = { 0, 0, 0, 0 }
            row.bg:SetColorTexture(0, 0, 0, 0)
        end
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

    -- Lock icon for persistent CVars
    local isLocked = CVarMaster.CVarManager and CVarMaster.CVarManager:IsLocked(cvarData.name)
    if isLocked then
        row.lockIcon:Show()
    else
        row.lockIcon:Hide()
    end
    
    -- Reset edit state
    row.editBox:Hide()
    row.valueText:Show()

    -- Apply current font settings to this row's text elements
    GUI:ApplyCurrentFont(row.nameText)
    GUI:ApplyCurrentFont(row.techName)
    GUI:ApplyCurrentFont(row.valueText)
    GUI:ApplyCurrentFont(row.defaultText)
    
    row:Show()
end


---Update only visible rows based on scroll position (virtual scrolling)
local function UpdateVisibleRows()
    local mainWindow = GUI:GetMainWindow()
    if not mainWindow or not mainWindow.listContainer then return end

    local content = mainWindow.listContent
    local scrollFrame = mainWindow.listContainer.scrollFrame
    if not content or not scrollFrame or #sortedData == 0 then return end

    local ROW_HEIGHT = GetRowHeight()
    local scrollOffset = scrollFrame:GetVerticalScroll()
    local viewHeight = scrollFrame:GetHeight()

    local firstVisible = math.max(1, math.floor(scrollOffset / ROW_HEIGHT) + 1 - BUFFER_ROWS)
    local lastVisible = math.min(#sortedData, math.ceil((scrollOffset + viewHeight) / ROW_HEIGHT) + BUFFER_ROWS)

    -- Hide rows outside visible range
    for i, row in pairs(activeRows) do
        if i < firstVisible or i > lastVisible then
            row:Hide()
            activeRows[i] = nil
        end
    end

    -- Show/create rows in visible range
    for i = firstVisible, lastVisible do
        if sortedData[i] and not activeRows[i] then
            local row = GetRow(content, i)
            PopulateRow(row, sortedData[i], i)
            activeRows[i] = row
        end
    end
end
---Refresh the CVar list
---@param searchTerm string|nil Search term
function GUI:RefreshCVarList(searchTerm)
    local mainWindow = GUI:GetMainWindow()
    if not mainWindow then return end

    local content = mainWindow.listContent
    if not content then return end

    local ROW_HEIGHT = GetRowHeight()

    -- Capture scroll position so a refresh from an in-place edit (value
    -- change, lock toggle, category override) doesn't yank the user back
    -- to the top of the list. SetVerticalScroll auto-clamps if the new
    -- result set is shorter, so navigation calls (search/category/filter)
    -- still land at a sensible position.
    local prevScroll = 0
    if mainWindow.listContainer and mainWindow.listContainer.scrollFrame then
        prevScroll = mainWindow.listContainer.scrollFrame:GetVerticalScroll() or 0
    end

    -- Get search term from searchbox if not provided (preserves filter after edits)
    if not searchTerm and mainWindow.searchBox then
        searchTerm = mainWindow.searchBox:GetText()
    end

    -- Get CVars
    local cvars = CVarMaster.CVarScanner:GetCachedCVars()

    -- Filter by category. Search is scoped to the selected category --
    -- the "All" tab is the explicit global-scope option. This matches user
    -- expectation: when on a specific category, typing in the search box
    -- narrows within that category only.
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

    -- Filter locked only if toggled
    if mainWindow.lockedBtn and mainWindow.lockedBtn.showLocked then
        local filtered = {}
        for name, data in pairs(cvars) do
            if CVarMaster.CVarManager and CVarMaster.CVarManager:IsLocked(name) then
                filtered[name] = data
            end
        end
        cvars = filtered
    end
    
    -- Sort by friendly name
    local sorted = {}
    for name, data in pairs(cvars) do
        table.insert(sorted, data)
    end
    table.sort(sorted, function(a, b)
        return (a.friendlyName or a.name) < (b.friendlyName or b.name)
    end)
    
    -- Store data for virtual scrolling
    sortedData = sorted

    -- Hide all existing rows
    for i, row in pairs(activeRows) do
        row:Hide()
        activeRows[i] = nil
    end
    
    -- Update content height
    content:SetHeight(math.max(1, #sorted * ROW_HEIGHT))

    -- Preserve scroll only when the result-set size is unchanged (in-place
    -- edits: value change, lock toggle, category override). Snap to top on
    -- any size change (search, category switch, filter toggle) — otherwise
    -- the prior scroll offset can land past the new content's end, leaving
    -- the user staring at empty space below the last row. WoW's scrollframe
    -- clamps lazily, so we don't get a free fix from SetVerticalScroll.
    local newCount = #sorted
    local restoredScroll = (prevSortedCount == newCount) and prevScroll or 0
    prevSortedCount = newCount
    if mainWindow.listContainer and mainWindow.listContainer.scrollFrame then
        mainWindow.listContainer.scrollFrame:SetVerticalScroll(restoredScroll)
        if mainWindow.listContainer.UpdateThumb then
            mainWindow.listContainer.UpdateThumb()
        end
    end

    -- Install scroll monitor once
    if not scrollHookInstalled and mainWindow.listContainer then
        local lastScroll = -1
        mainWindow.listContainer:HookScript("OnUpdate", function()
            local sf = mainWindow.listContainer.scrollFrame
            if not sf then return end
            local pos = sf:GetVerticalScroll()
            if pos ~= lastScroll then
                lastScroll = pos
                UpdateVisibleRows()
            end
        end)
        scrollHookInstalled = true
    end

    -- Render visible rows
    UpdateVisibleRows()

    -- Update category counts
    local categoryCounts = CVarMaster.CVarScanner:GetCategoryCounts()
    GUI:UpdateCategoryCounts(categoryCounts)
end

-- Description popup frame (created once, reused)
local descriptionPopup = nil

local function CreateDescriptionPopup()
    if descriptionPopup then return descriptionPopup end

    local popup = GUI:CreateNihilumFrame("CVarMasterDescPopup", UIParent, false)
    popup:SetSize(400, 200)
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(100)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)

    -- Title bar
    popup.titleBar = CreateFrame("Frame", nil, popup)
    popup.titleBar:SetHeight(28)
    popup.titleBar:SetPoint("TOPLEFT", 4, -4)
    popup.titleBar:SetPoint("TOPRIGHT", -4, -4)

    popup.titleBar.accentLine = popup.titleBar:CreateTexture(nil, "ARTWORK")
    popup.titleBar.accentLine:SetHeight(1)
    popup.titleBar.accentLine:SetPoint("BOTTOMLEFT", 0, 0)
    popup.titleBar.accentLine:SetPoint("BOTTOMRIGHT", 0, 0)
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(popup.titleBar.accentLine, 0.4) end
    if GUI.DisableSharpening then GUI.DisableSharpening(popup.titleBar.accentLine) end

    -- Title text (friendly name)
    popup.title = popup.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    popup.title:SetPoint("LEFT", 10, 0)
    popup.title:SetTextColor(T("ACCENT_HIGHLIGHT"))

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
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(popup.sep, 0.25) end

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
    popup.infoFrame = CreateFrame("Frame", nil, popup)
    popup.infoFrame:SetHeight(40)
    popup.infoFrame:SetPoint("BOTTOMLEFT", 4, 4)
    popup.infoFrame:SetPoint("BOTTOMRIGHT", -4, 4)

    popup.infoFrame.bg = popup.infoFrame:CreateTexture(nil, "BACKGROUND")
    popup.infoFrame.bg:SetAllPoints()
    popup.infoFrame.bg:SetColorTexture(0.04, 0.03, 0.07, 0.5)
    if GUI.DisableSharpening then GUI.DisableSharpening(popup.infoFrame.bg) end

    popup.infoFrame.topSep = popup.infoFrame:CreateTexture(nil, "ARTWORK")
    popup.infoFrame.topSep:SetHeight(1)
    popup.infoFrame.topSep:SetPoint("TOPLEFT", 0, 0)
    popup.infoFrame.topSep:SetPoint("TOPRIGHT", 0, 0)
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(popup.infoFrame.topSep, 0.2) end
    if GUI.DisableSharpening then GUI.DisableSharpening(popup.infoFrame.topSep) end

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

    -- Lock button
    popup.lockBtn = GUI:CreateButton(nil, popup.infoFrame, "Lock", 70, 22)
    popup.lockBtn:SetPoint("RIGHT", popup.typeLabel, "LEFT", -15, 0)

    popup.lockBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(T("BTN_HOVER"))
    end)
    popup.lockBtn:SetScript("OnLeave", function(self)
        local isLocked = popup.cvarData and CVarMaster.CVarManager and CVarMaster.CVarManager:IsLocked(popup.cvarData.name)
        if isLocked then
            self:SetBackdropColor(0.18, 0.22, 0.25, 1)
        else
            self:SetBackdropColor(T("BTN_NORMAL"))
        end
    end)
    popup.lockBtn:SetScript("OnClick", function()
        if popup.cvarData and CVarMaster.CVarManager then
            CVarMaster.CVarManager:ToggleLock(popup.cvarData.name)
            -- Update button state
            local isLocked = CVarMaster.CVarManager:IsLocked(popup.cvarData.name)
            if isLocked then
                popup.lockBtn.text:SetText("Unlock")
                popup.lockBtn:SetBackdropColor(0.18, 0.22, 0.25, 1)
            else
                popup.lockBtn.text:SetText("Lock")
                popup.lockBtn:SetBackdropColor(T("BTN_NORMAL"))
            end
            -- Refresh main list to update lock icons
            if GUI.RefreshCVarList then
                GUI:RefreshCVarList()
            end
        end
    end)

    -- Change Category button. If any rows are checked, the action targets
    -- every checked CVar (batch). Otherwise it targets the current popup's
    -- single CVar. Opens a MenuUtil context menu listing all categories,
    -- then a StaticPopup confirmation before applying.
    popup.categoryBtn = GUI:CreateButton(nil, popup.infoFrame, "Change Category", 130, 22)
    popup.categoryBtn:SetPoint("RIGHT", popup.lockBtn, "LEFT", -8, 0)
    popup.categoryBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(T("BTN_HOVER"))
    end)
    popup.categoryBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(T("BTN_NORMAL"))
    end)
    popup.categoryBtn:SetScript("OnClick", function(self)
        local checked = GUI.checkedCVars or {}
        local targets = {}
        for name in pairs(checked) do targets[#targets + 1] = name end
        if #targets == 0 and popup.cvarData then
            targets[1] = popup.cvarData.name
        end
        if #targets == 0 then return end

        if not (MenuUtil and MenuUtil.CreateContextMenu) then return end

        local categories = CVarMaster.CVarScanner:GetCategories()

        MenuUtil.CreateContextMenu(self, function(_, root)
            root:CreateTitle(string.format("Move %d CVar(s) to:", #targets))
            for _, cat in ipairs(categories) do
                root:CreateButton(cat, function()
                    local msg = string.format("Move %d CVar(s) to category '%s'?", #targets, cat)
                    StaticPopup_Show("CVARMASTER_CONFIRM_CATEGORY", msg, nil, {
                        targets = targets,
                        category = cat,
                    })
                end)
            end
            root:CreateDivider()
            root:CreateButton("|cffff8888Reset to default|r", function()
                local msg = string.format("Reset %d CVar(s) to default categorisation?", #targets)
                StaticPopup_Show("CVARMASTER_CONFIRM_CATEGORY", msg, nil, {
                    targets = targets,
                    category = nil,
                })
            end)
        end)
    end)

    -- ESC-close via UISpecialFrames (the frame has a global name). A plain
    -- OnKeyDown handler never fires here — keyboard input is never enabled on
    -- this frame — and SetPropagateKeyboardInput is combat-protected since 10.1.5.
    tinsert(UISpecialFrames, "CVarMasterDescPopup")

    popup:Hide()
    descriptionPopup = popup
    return popup
end

---Show description popup for a CVar
---@param anchor Frame Anchor frame
---@param cvarData table CVar data
function GUI:ShowCVarContextMenu(anchor, cvarData)
    local popup = CreateDescriptionPopup()

    -- Store cvarData for lock button
    popup.cvarData = cvarData

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

    -- Update lock button state
    local isLocked = CVarMaster.CVarManager and CVarMaster.CVarManager:IsLocked(cvarData.name)
    if isLocked then
        popup.lockBtn.text:SetText("Unlock")
        popup.lockBtn:SetBackdropColor(0.18, 0.22, 0.25, 1)
    else
        popup.lockBtn.text:SetText("Lock")
        popup.lockBtn:SetBackdropColor(T("BTN_NORMAL"))
    end

    -- Smart position - avoid clipping off screen edges
    popup:ClearAllPoints()
    local screenWidth = GetScreenWidth() * UIParent:GetEffectiveScale()
    local anchorRight = anchor:GetRight() or 0
    if anchorRight + 420 > screenWidth then
        -- Not enough room on the right, anchor to the left
        popup:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -10, 0)
    else
        popup:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 10, 0)
    end

    -- Sync scale with main window
    local mainWin = GUI:GetMainWindow()
    if mainWin then
        popup:SetScale(mainWin:GetScale())
    end

    -- Apply current font settings to popup text elements
    GUI:ApplyCurrentFont(popup.title)
    GUI:ApplyCurrentFont(popup.techName)
    GUI:ApplyCurrentFont(popup.descLabel)
    GUI:ApplyCurrentFont(popup.currentLabel)
    GUI:ApplyCurrentFont(popup.currentValue)
    GUI:ApplyCurrentFont(popup.defaultLabel)
    GUI:ApplyCurrentFont(popup.defaultValue)
    GUI:ApplyCurrentFont(popup.typeLabel)

    -- Show
    popup:Show()
    popup:Raise()
end
