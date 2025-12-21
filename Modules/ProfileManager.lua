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

    -- Simple encoding (in production, use proper serialization)
    local str = profileName .. "|"
    for name, value in pairs(profile.cvars) do
        str = str .. name .. "=" .. value .. ";"
    end

    local encoded = CVarMaster.Utils.EncodeString(str)
    CVarMaster.Utils.Print("Profile exported. String length:", #encoded)

    return encoded
end

---Import profile from string
---@param importString string Encoded profile string
---@param newName? string New profile name
---@return boolean success
function PM:ImportProfile(importString, newName)
    -- In production, properly decode and validate
    CVarMaster.Utils.Print("Profile import requires proper deserialization library")
    CVarMaster.Utils.Print("This is a placeholder implementation")
    return false
end
