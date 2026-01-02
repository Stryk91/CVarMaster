---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.WeakAuraExport = {}
local WAE = CVarMaster.WeakAuraExport

local ExportDialog = nil

---Check if CVar is combat-protected
---@param cvarName string
---@return boolean
local function IsCombatProtected(cvarName)
    return CVarMaster.CombatProtectedCVars and CVarMaster.CombatProtectedCVars[cvarName] or false
end

---Generate SetCVar lines from CVar table
---@param cvars table Table of {name = value} or {name = {value = x}}
---@param addComments boolean Add combat-protected warnings
---@return string lines, number count, number combatCount
local function GenerateSetCVarLines(cvars, addComments)
    local lines = {}
    local count = 0
    local combatCount = 0

    -- Sort for consistent output
    local sorted = {}
    for name, data in pairs(cvars) do
        local value = type(data) == "table" and data.value or data
        table.insert(sorted, {name = name, value = value})
    end
    table.sort(sorted, function(a, b) return a.name < b.name end)

    for _, item in ipairs(sorted) do
        local value = tostring(item.value):gsub('"', '\\"')
        local isCombat = IsCombatProtected(item.name)

        if isCombat then
            combatCount = combatCount + 1
            if addComments then
                table.insert(lines, string.format('  -- COMBAT PROTECTED: %s', item.name))
            end
        end

        table.insert(lines, string.format('  SetCVar("%s", "%s")', item.name, value))
        count = count + 1
    end

    return table.concat(lines, "\n"), count, combatCount
end

---Generate WeakAura init script for current modified CVars
---@return string|nil script, number|nil count
function WAE:GenerateScript()
    local modified = CVarMaster.CVarScanner:FilterModified()
    if not modified or not next(modified) then
        CVarMaster.Utils.Error("No modified CVars to export")
        return nil
    end

    local lines, count, combatCount = GenerateSetCVarLines(modified, true)
    local timestamp = date("%Y-%m-%d %H:%M:%S")

    local combatWarning = ""
    if combatCount > 0 then
        combatWarning = string.format("\n-- WARNING: %d CVars are combat-protected (require out of combat)", combatCount)
    end

    local script = string.format([[
-- CVarMaster Export
-- Generated: %s
-- CVars: %d total%s

function()
%s
  print("|cff00aaffCVarMaster|r: %d CVars applied")
end
]], timestamp, count, combatWarning, lines, count)

    return script, count
end

---Generate WeakAura init script for a saved profile
---@param profileName string Profile name
---@return string|nil script, number|nil count
function WAE:GenerateProfileScript(profileName)
    if not CVarMaster.db.profiles or not CVarMaster.db.profiles[profileName] then
        CVarMaster.Utils.Error("Profile not found:", profileName)
        return nil
    end

    local profile = CVarMaster.db.profiles[profileName]
    if not profile.cvars or not next(profile.cvars) then
        CVarMaster.Utils.Error("Profile has no CVars:", profileName)
        return nil
    end

    local lines, count, combatCount = GenerateSetCVarLines(profile.cvars, true)
    local timestamp = date("%Y-%m-%d %H:%M:%S")
    local profileTime = profile.timestamp and date("%Y-%m-%d %H:%M:%S", profile.timestamp) or "unknown"

    local combatWarning = ""
    if combatCount > 0 then
        combatWarning = string.format("\n-- WARNING: %d CVars are combat-protected (require out of combat)", combatCount)
    end

    local script = string.format([[
-- CVarMaster Profile Export: %s
-- Profile Created: %s
-- Exported: %s
-- CVars: %d total%s

function()
%s
  print("|cff00aaffCVarMaster|r: Profile '%s' applied (%d CVars)")
end
]], profileName, profileTime, timestamp, count, combatWarning, lines, profileName, count)

    return script, count
end

---Generate full encoded aura string (simplified - no LibSerialize)
---@param cvars table CVar data
---@param auraName string Name for the aura
---@return string|nil encoded
function WAE:GenerateFullAura(cvars, auraName)
    if not cvars or not next(cvars) then
        return nil
    end

    -- Build simple encoded format: !CVM:name:cvar1=val1;cvar2=val2;...
    local parts = {}
    for name, data in pairs(cvars) do
        local value = type(data) == "table" and data.value or data
        table.insert(parts, name .. "=" .. tostring(value))
    end

    local dataStr = table.concat(parts, ";")
    local encoded = CVarMaster.Utils.EncodeString(auraName .. "|" .. dataStr)

    return "!CVM:" .. encoded
end

---Create or get export dialog
---@return Frame dialog
local function GetExportDialog()
    if ExportDialog then return ExportDialog end

    local dialog = CreateFrame("Frame", "CVarMasterWAExport", UIParent, "BackdropTemplate")
    dialog:SetSize(600, 500)
    dialog:SetPoint("CENTER")
    dialog:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dialog:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    dialog:SetBackdropBorderColor(0, 0.6, 1, 0.8)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    dialog:Hide()

    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    dialog.title = title

    -- Info text
    local info = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info:SetPoint("TOP", title, "BOTTOM", 0, -4)
    info:SetTextColor(0.7, 0.7, 0.7)
    dialog.info = info

    -- Text area with scroll
    local textBg = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
    textBg:SetPoint("TOPLEFT", 12, -55)
    textBg:SetPoint("BOTTOMRIGHT", -12, 50)
    textBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    textBg:SetBackdropColor(0.02, 0.02, 0.04, 1)
    textBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local scrollFrame = CreateFrame("ScrollFrame", "CVarMasterExportScroll", textBg, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)

    local editBox = CreateFrame("EditBox", "CVarMasterExportEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(100000)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetTextColor(1, 1, 0.8, 1)
    editBox:SetWidth(530)
    editBox:SetHeight(10000)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    scrollFrame:SetScrollChild(editBox)
    dialog.editBox = editBox
    dialog.scrollFrame = scrollFrame

    -- Close button
    local closeBtn = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)

    -- Select All button
    local selectBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    selectBtn:SetPoint("BOTTOMLEFT", 12, 12)
    selectBtn:SetSize(100, 26)
    selectBtn:SetText("Select All")
    selectBtn:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)

    -- Copy hint
    local copyHint = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    copyHint:SetPoint("LEFT", selectBtn, "RIGHT", 10, 0)
    copyHint:SetText("|cff888888Ctrl+C to copy after selecting|r")

    tinsert(UISpecialFrames, "CVarMasterWAExport")
    ExportDialog = dialog
    return dialog
end

---Show export dialog for current modified CVars
function WAE:ShowExportDialog()
    local script, count = WAE:GenerateScript()
    if not script then return end

    local dialog = GetExportDialog()
    dialog.title:SetText("|cff00ff00WeakAura Export|r")
    dialog.info:SetText(count .. " modified CVars - Paste into WeakAura Init Action")
    dialog:Show()
    
    -- Use chunked insert (SetText fails on large text in WoW)
    dialog.editBox:SetText("")
    dialog.editBox:SetFocus()
    local pos = 1
    while pos <= #script do
        dialog.editBox:Insert(script:sub(pos, pos + 1999))
        pos = pos + 2000
    end
    dialog.editBox:SetCursorPosition(0)
    dialog.editBox:HighlightText()
end

---Show export dialog for a specific profile
---@param profileName string Profile name
function WAE:ShowProfileExportDialog(profileName)
    local script, count = WAE:GenerateProfileScript(profileName)
    if not script then return end

    local dialog = GetExportDialog()
    dialog.title:SetText("|cff00ff00WeakAura Export: " .. profileName .. "|r")
    dialog.info:SetText(count .. " CVars - Paste into WeakAura Init Action")
    dialog:Show()
    
    -- Use chunked insert
    dialog.editBox:SetText("")
    dialog.editBox:SetFocus()
    local pos = 1
    while pos <= #script do
        dialog.editBox:Insert(script:sub(pos, pos + 1999))
        pos = pos + 2000
    end
    dialog.editBox:SetCursorPosition(0)
    dialog.editBox:HighlightText()
end

---Show export dialog with encoded string (for import into other CVarMaster)
---@param profileName string Profile name
function WAE:ShowEncodedExportDialog(profileName)
    if not CVarMaster.db.profiles or not CVarMaster.db.profiles[profileName] then
        CVarMaster.Utils.Error("Profile not found:", profileName)
        return
    end

    local profile = CVarMaster.db.profiles[profileName]
    local encoded = WAE:GenerateFullAura(profile.cvars, profileName)
    if not encoded then
        CVarMaster.Utils.Error("Failed to encode profile")
        return
    end

    local count = 0
    for _ in pairs(profile.cvars) do count = count + 1 end

    local dialog = GetExportDialog()
    dialog.title:SetText("|cff00ff00CVarMaster Export: " .. profileName .. "|r")
    dialog.info:SetText(count .. " CVars - Share this string to import into another CVarMaster")
    dialog.editBox:SetText(encoded)
    dialog.editBox:HighlightText()
    dialog:Show()
end

CVarMaster.Utils.Debug("WeakAuraExport module loaded")
