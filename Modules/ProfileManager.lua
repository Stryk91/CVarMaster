---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.ProfileManager = {}
local PM = CVarMaster.ProfileManager

---Save current CVars as named profile
---@param profileName string Profile name
---@param includeAll? boolean Include all CVars (default: only modified)
---@return boolean success
function PM:SaveProfile(profileName, includeAll)
    if not profileName or profileName == "" then
        CVarMaster.Utils.Error("Profile name required")
        return false
    end

    local profile = {
        name = profileName,
        timestamp = time(),
        version = CVarMaster.Constants.VERSION,
        cvars = {},
    }

    local cvars = includeAll and CVarMaster.CVarScanner:GetCachedCVars()
                             or CVarMaster.CVarScanner:FilterModified()

    for name, data in pairs(cvars) do
        profile.cvars[name] = data.value
    end

    -- Save to database
    if not CVarMaster.db.profiles then
        CVarMaster.db.profiles = {}
    end

    CVarMaster.db.profiles[profileName] = profile

    local count = 0
    for _ in pairs(profile.cvars) do count = count + 1 end

    CVarMaster.Utils.Print("Saved profile '" .. profileName .. "' with", count, "CVars")
    return true
end

---Load profile
---@param profileName string Profile name
---@return boolean success
function PM:LoadProfile(profileName)
    if not CVarMaster.db.profiles or not CVarMaster.db.profiles[profileName] then
        CVarMaster.Utils.Error("Profile not found:", profileName)
        return false
    end

    local profile = CVarMaster.db.profiles[profileName]

    -- Backup current state
    CVarMaster.CVarManager:BackupAll()

    local count = 0
    for name, value in pairs(profile.cvars) do
        if SetCVar(name, value) then
            CVarMaster.CVarScanner:UpdateCVarInCache(name)
            count = count + 1
        end
    end

    CVarMaster.Utils.Print("Loaded profile '" .. profileName .. "' -", count, "CVars applied")
    return true
end

---Delete profile
---@param profileName string Profile name
---@return boolean success
function PM:DeleteProfile(profileName)
    if not CVarMaster.db.profiles or not CVarMaster.db.profiles[profileName] then
        CVarMaster.Utils.Error("Profile not found:", profileName)
        return false
    end

    CVarMaster.db.profiles[profileName] = nil
    CVarMaster.Utils.Print("Deleted profile:", profileName)
    return true
end

---Get all profiles
---@return table profiles List of profile names
function PM:GetProfiles()
    if not CVarMaster.db.profiles then
        return {}
    end

    local profiles = {}
    for name in pairs(CVarMaster.db.profiles) do
        table.insert(profiles, name)
    end

    return profiles
end

---Export profile to string
---@param profileName string Profile name
---@return string|nil exportString Encoded profile string
function PM:ExportProfile(profileName)
    if not CVarMaster.db.profiles or not CVarMaster.db.profiles[profileName] then
        CVarMaster.Utils.Error("Profile not found:", profileName)
        return nil
    end

    local profile = CVarMaster.db.profiles[profileName]

    -- Build export string: profileName|cvar1=val1;cvar2=val2;...
    local parts = {}
    for name, value in pairs(profile.cvars) do
        -- Escape special characters
        local escapedVal = tostring(value):gsub("|", "\\|"):gsub(";", "\\;"):gsub("=", "\\=")
        table.insert(parts, name .. "=" .. escapedVal)
    end

    local str = profileName .. "|" .. table.concat(parts, ";")
    local encoded = CVarMaster.Utils.EncodeString(str)

    local count = 0
    for _ in pairs(profile.cvars) do count = count + 1 end

    CVarMaster.Utils.Print("Profile exported:", count, "CVars, string length:", #encoded)
    return encoded
end

---Import profile from string
---@param importString string Encoded profile string
---@param newName? string Optional new profile name (overrides embedded name)
---@return boolean success
function PM:ImportProfile(importString, newName)
    if not importString or importString == "" then
        CVarMaster.Utils.Error("Import string is empty")
        return false
    end

    -- Strip !CVM: prefix if present (from WeakAura export format)
    if importString:sub(1, 5) == "!CVM:" then
        importString = importString:sub(6)
    end

    -- Decode base64
    local decoded = CVarMaster.Utils.DecodeString(importString)
    if not decoded then
        CVarMaster.Utils.Error("Failed to decode import string - invalid format")
        return false
    end

    -- Parse: profileName|cvar1=val1;cvar2=val2;...
    local pipePos = decoded:find("|")
    if not pipePos then
        CVarMaster.Utils.Error("Invalid import format - missing profile name")
        return false
    end

    local profileName = newName or decoded:sub(1, pipePos - 1)
    local cvarData = decoded:sub(pipePos + 1)

    if profileName == "" then
        CVarMaster.Utils.Error("Profile name is empty")
        return false
    end

    -- Parse CVars
    local cvars = {}
    local count = 0

    -- Split by unescaped semicolons
    for pair in cvarData:gmatch("[^;]+") do
        -- Find unescaped equals sign
        local eqPos = pair:find("[^\\]=")
        if eqPos then
            eqPos = eqPos + 1  -- Adjust for pattern match
        else
            eqPos = pair:find("^=")
            if eqPos then eqPos = 1 end
        end

        if eqPos then
            local name = pair:sub(1, eqPos - 1)
            local value = pair:sub(eqPos + 1)

            -- Unescape special characters
            name = name:gsub("\\|", "|"):gsub("\\;", ";"):gsub("\\=", "=")
            value = value:gsub("\\|", "|"):gsub("\\;", ";"):gsub("\\=", "=")

            if name ~= "" then
                cvars[name] = value
                count = count + 1
            end
        end
    end

    if count == 0 then
        CVarMaster.Utils.Error("No CVars found in import string")
        return false
    end

    -- Create profile
    local profile = {
        name = profileName,
        timestamp = time(),
        version = CVarMaster.Constants.VERSION,
        imported = true,
        cvars = cvars,
    }

    -- Initialize profiles table if needed
    if not CVarMaster.db.profiles then
        CVarMaster.db.profiles = {}
    end

    -- Check for existing profile
    if CVarMaster.db.profiles[profileName] then
        CVarMaster.Utils.Print("Overwriting existing profile:", profileName)
    end

    CVarMaster.db.profiles[profileName] = profile
    CVarMaster.Utils.Print("Imported profile '" .. profileName .. "' with", count, "CVars")

    return true
end

---Show import dialog
function PM:ShowImportDialog()
    local dialog = CreateFrame("Frame", "CVarMasterImportDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(500, 200)
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

    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cff00ff00Import Profile|r")

    local info = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info:SetPoint("TOP", title, "BOTTOM", 0, -4)
    info:SetText("|cff888888Paste CVarMaster export string below|r")

    local editBox = CreateFrame("EditBox", nil, dialog, "BackdropTemplate")
    editBox:SetPoint("TOPLEFT", 12, -50)
    editBox:SetPoint("TOPRIGHT", -12, -50)
    editBox:SetHeight(80)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetAutoFocus(true)
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editBox:SetBackdropColor(0.1, 0.1, 0.12, 1)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    editBox:SetTextInsets(8, 8, 4, 4)

    local closeBtn = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)

    local importBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    importBtn:SetPoint("BOTTOM", -50, 12)
    importBtn:SetSize(100, 26)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        if PM:ImportProfile(text) then
            dialog:Hide()
            -- Refresh profile list if visible
            if CVarMaster.GUI and CVarMaster.GUI.RefreshProfileList then
                CVarMaster.GUI:RefreshProfileList()
            end
        end
    end)

    local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelBtn:SetPoint("BOTTOM", 50, 12)
    cancelBtn:SetSize(100, 26)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        dialog:Hide()
    end)

    tinsert(UISpecialFrames, "CVarMasterImportDialog")
    dialog:Show()
end
