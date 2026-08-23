---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.ProfileManager = {}
local PM = CVarMaster.ProfileManager

---Save current CVars as named profile
---@param profileName string Profile name
---@param includeAll? boolean Include all CVars (default: only modified)
---@param setActive? boolean Set as active profile (default: true)
---@return boolean success
function PM:SaveProfile(profileName, includeAll, setActive)
    if not profileName or profileName == "" then
        CVarMaster.Utils.Error("Profile name required")
        return false
    end

    -- Default setActive to true
    if setActive == nil then
        setActive = true
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

    -- Track as active profile
    if setActive and CVarMaster.charDB then
        CVarMaster.charDB.activeProfile = profileName
    end

    local count = 0
    for _ in pairs(profile.cvars) do count = count + 1 end

    CVarMaster.Utils.Print("Saved profile '" .. profileName .. "' with", count, "CVars")
    return true
end

---Load profile
---@param profileName string Profile name
---@param silent? boolean Suppress chat output (auto-enforce path must stay silent)
---@return boolean success
function PM:LoadProfile(profileName, silent)
    if not CVarMaster.db.profiles or not CVarMaster.db.profiles[profileName] then
        if not silent then
            CVarMaster.Utils.Error("Profile not found:", profileName)
        end
        return false
    end

    local profile = CVarMaster.db.profiles[profileName]

    -- Backup current state
    CVarMaster.CVarManager:BackupAll(silent)

    local count = 0
    for name, value in pairs(profile.cvars) do
        local current = GetCVar(name)
        if current ~= nil and tostring(current) ~= tostring(value) then
            if SetCVar(name, value) then
                CVarMaster.CVarScanner:UpdateCVarInCache(name)
                count = count + 1
            end
        end
    end

    -- Track active profile
    if CVarMaster.charDB then
        CVarMaster.charDB.activeProfile = profileName
    end

    if not silent then
        CVarMaster.Utils.Print("Loaded profile '" .. profileName .. "' -", count, "CVars applied")
    end
    return true
end

---Get active profile name
---@return string|nil profileName
function PM:GetActiveProfile()
    if CVarMaster.charDB then
        return CVarMaster.charDB.activeProfile
    end
    return nil
end

---Set active profile (for tracking without loading)
---@param profileName string|nil
function PM:SetActiveProfile(profileName)
    if CVarMaster.charDB then
        CVarMaster.charDB.activeProfile = profileName
    end
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

-- Export-string escaping: '\' guards the structural chars '|', ';', '=' (and itself).
-- Only these four are ever treated as escapes on import, so legacy strings with
-- raw backslashes in values (font paths) still round-trip unchanged.
local ESCAPABLE = { ["|"] = true, [";"] = true, ["="] = true, ["\\"] = true }

local function EscapeField(s)
    return (tostring(s):gsub("\\", "\\\\"):gsub("|", "\\|"):gsub(";", "\\;"):gsub("=", "\\="))
end

local function UnescapeField(s)
    return (s:gsub("\\([|;=\\])", "%1"))
end

---Split on a separator, honoring backslash escapes; parts keep their escaping
local function SplitEscaped(s, sep)
    local parts, cur, i, n = {}, {}, 1, #s
    while i <= n do
        local c = s:sub(i, i)
        if c == "\\" and ESCAPABLE[s:sub(i + 1, i + 1)] then
            cur[#cur + 1] = s:sub(i, i + 1)
            i = i + 2
        elseif c == sep then
            parts[#parts + 1] = table.concat(cur)
            cur = {}
            i = i + 1
        else
            cur[#cur + 1] = c
            i = i + 1
        end
    end
    parts[#parts + 1] = table.concat(cur)
    return parts
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
        table.insert(parts, EscapeField(name) .. "=" .. EscapeField(value))
    end

    local str = EscapeField(profileName) .. "|" .. table.concat(parts, ";")
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

    -- Parse: profileName|cvar1=val1;cvar2=val2;... (escaped '|'/';'/'=' stay literal)
    local headParts = SplitEscaped(decoded, "|")
    if #headParts < 2 then
        CVarMaster.Utils.Error("Invalid import format - missing profile name")
        return false
    end

    local profileName = newName or UnescapeField(headParts[1])
    local cvarData = table.concat(headParts, "|", 2)

    if profileName == "" then
        CVarMaster.Utils.Error("Profile name is empty")
        return false
    end

    -- Parse CVars
    local cvars = {}
    local count = 0

    for _, pair in ipairs(SplitEscaped(cvarData, ";")) do
        if pair ~= "" then
            local eqParts = SplitEscaped(pair, "=")
            if #eqParts >= 2 then
                local name = UnescapeField(eqParts[1])
                local value = UnescapeField(table.concat(eqParts, "=", 2))
                if name ~= "" then
                    cvars[name] = value
                    count = count + 1
                end
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

-- Reusable import dialog (created once)
local importDialog = nil
local importEditBox = nil

---Show import dialog (creates once, reuses)
function PM:ShowImportDialog()
    if not importDialog then
        local dialog = CreateFrame("Frame", "CVarMasterImportDialog", UIParent, "BackdropTemplate")
        dialog:SetSize(500, 300)
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

        local scrollContainer = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
        scrollContainer:SetPoint("TOPLEFT", 12, -50)
        scrollContainer:SetPoint("TOPRIGHT", -12, -50)
        scrollContainer:SetHeight(180)
        scrollContainer:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        scrollContainer:SetBackdropColor(0.1, 0.1, 0.12, 1)
        scrollContainer:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local scrollFrame = CreateFrame("ScrollFrame", "CVarMasterImportScroll", scrollContainer, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 4, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", -22, 4)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetWidth(scrollFrame:GetWidth() or 440)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(GameFontHighlightSmall)
        editBox:SetAutoFocus(true)
        editBox:SetTextInsets(8, 8, 4, 4)
        scrollFrame:SetScrollChild(editBox)
        importEditBox = editBox

        editBox:SetScript("OnShow", function(self)
            self:SetWidth(scrollFrame:GetWidth())
        end)

        local closeBtn = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -2, -2)

        local importBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        importBtn:SetPoint("BOTTOM", -50, 12)
        importBtn:SetSize(100, 26)
        importBtn:SetText("Import")
        importBtn:SetScript("OnClick", function()
            local text = importEditBox:GetText()
            if PM:ImportProfile(text) then
                dialog:Hide()
                if CVarMaster.GUI and CVarMaster.GUI.RefreshProfileList then
                    CVarMaster.GUI:RefreshProfileList()
                end
            end
        end)

        local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        cancelBtn:SetPoint("BOTTOM", 50, 12)
        cancelBtn:SetSize(100, 26)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetScript("OnClick", function() dialog:Hide() end)

        tinsert(UISpecialFrames, "CVarMasterImportDialog")
        importDialog = dialog
    end

    -- Reset and show
    importEditBox:SetText("")
    importDialog:Show()
    importEditBox:SetFocus()
end
