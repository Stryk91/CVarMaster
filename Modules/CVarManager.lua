---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.CVarManager = {}
local Manager = CVarMaster.CVarManager

-- Backup storage (single-CVar backups are session-only; full backups persist to DB)
local backups = {}

-- CVars that need confirmation/reload before taking effect
local DANGEROUS_RESET_CVARS = {
    ["uiScale"] = true,
    ["useUiScale"] = true,
    ["gxApi"] = true,
    ["gxWindow"] = true,
    ["gxMaximize"] = true,
    ["gxRefresh"] = true,
    ["gxResolution"] = true,
    ["gxWindowedResolution"] = true,
    ["renderScale"] = true,
    ["RenderScale"] = true,
    ["graphicsQuality"] = true,
}

-- Check if player is in combat
local function IsInCombat()
    return InCombatLockdown() or UnitAffectingCombat("player")
end

-- Check if CVar is combat protected
local function IsCombatProtected(cvarName)
    return CVarMaster.CombatProtectedCVars and CVarMaster.CombatProtectedCVars[cvarName]
end

---Set CVar value with safety checks
function Manager:SetCVar(cvarName, value, skipWarning)
    local data = CVarMaster.CVarScanner:GetCVarData(cvarName)
    if not data then
        print("|cffff0000CVarMaster:|r CVar not found:", cvarName)
        return false
    end

    -- Check if protected
    if data.isProtected then
        print("|cffff0000CVarMaster:|r Cannot modify protected CVar:", cvarName)
        return false
    end
    
    -- Check combat protection
    if IsCombatProtected(cvarName) and IsInCombat() then
        print("|cffff8800CVarMaster:|r Cannot modify |cffffaa00" .. cvarName .. "|r during combat")
        print("|cff888888Exit combat first, then try again.|r")
        return false
    end

    -- Backup current value
    self:BackupCVar(cvarName)

    -- Convert value to string
    local cvarString = tostring(value)

    -- Set CVar
    SetCVar(cvarName, cvarString)

    -- Update cache
    CVarMaster.CVarScanner:UpdateCVarInCache(cvarName)

    -- Warn if reload required
    if not skipWarning then
        if data.requiresReload or DANGEROUS_RESET_CVARS[cvarName] then
            print("|cff00aaffCVarMaster|r: Set |cffffaa00" .. (data.friendlyName or cvarName) .. "|r - |cffff8800/reload may be required|r")
        else
            print("|cff00aaffCVarMaster|r: Set |cffffaa00" .. (data.friendlyName or cvarName) .. "|r to " .. value)
        end
    end

    return true
end

---Reset CVar to default value
function Manager:ResetCVar(cvarName)
    local data = CVarMaster.CVarScanner:GetCVarData(cvarName)
    if not data then
        return false
    end
    
    -- Check combat protection
    if IsCombatProtected(cvarName) and IsInCombat() then
        print("|cffff8800CVarMaster:|r Cannot reset |cffffaa00" .. cvarName .. "|r during combat")
        return false
    end

    -- For dangerous CVars, warn but don't auto-apply visual changes
    if DANGEROUS_RESET_CVARS[cvarName] then
        -- Backup first
        self:BackupCVar(cvarName)
        
        -- Set the CVar (will take effect on reload for most dangerous ones)
        SetCVar(cvarName, data.defaultValue)
        CVarMaster.CVarScanner:UpdateCVarInCache(cvarName)
        
        print("|cff00aaffCVarMaster|r: Reset |cffffaa00" .. (data.friendlyName or cvarName) .. "|r to default")
        print("|cffff8800Note:|r Visual changes will apply after |cff00ff00/reload|r")
        return true
    end

    -- Normal CVars - apply immediately
    self:BackupCVar(cvarName)
    SetCVar(cvarName, data.defaultValue)
    CVarMaster.CVarScanner:UpdateCVarInCache(cvarName)
    
    print("|cff00aaffCVarMaster|r: Reset |cffffaa00" .. (data.friendlyName or cvarName) .. "|r to default (" .. data.defaultValue .. ")")
    return true
end

---Reset all CVars in category to defaults
function Manager:ResetCategory(category)
    if IsInCombat() then
        print("|cffff8800CVarMaster:|r Cannot reset category during combat")
        return 0
    end

    local cvars = CVarMaster.CVarScanner:FilterByCategory(category)
    local count = 0
    local needsReload = false

    for name, data in pairs(cvars) do
        if data.isModified then
            if DANGEROUS_RESET_CVARS[name] then
                needsReload = true
            end
            if self:ResetCVar(name) then
                count = count + 1
            end
        end
    end

    print("|cff00aaffCVarMaster|r: Reset " .. count .. " CVars in category: " .. category)
    if needsReload then
        print("|cffff8800Note:|r Some changes require |cff00ff00/reload|r")
    end
    return count
end

---Reset all modified CVars
function Manager:ResetAll()
    if IsInCombat() then
        print("|cffff8800CVarMaster:|r Cannot reset all CVars during combat")
        return 0
    end

    local modified = CVarMaster.CVarScanner:FilterModified()
    local count = 0

    self:BackupAll()

    for name in pairs(modified) do
        if self:ResetCVar(name) then
            count = count + 1
        end
    end

    print("|cff00aaffCVarMaster|r: Reset " .. count .. " CVars to defaults")
    print("|cffff8800Note:|r Some changes may require |cff00ff00/reload|r")
    return count
end

---Backup single CVar
function Manager:BackupCVar(cvarName)
    local value = GetCVar(cvarName)
    if value then
        if not backups.single then
            backups.single = {}
        end
        backups.single[cvarName] = value
    end
end

---Backup all CVars (persists to SavedVariables)
---@param silent? boolean Suppress chat output (auto-enforce path must stay silent)
function Manager:BackupAll(silent)
    local cvars = CVarMaster.CVarScanner:GetCachedCVars()
    backups.full = {}

    for name, data in pairs(cvars) do
        backups.full[name] = data.value
    end

    -- Persist to DB so backups survive /reload
    if CVarMaster.db then
        CVarMaster.db.backup = backups.full
    end

    if not silent then
        local count = 0
        for _ in pairs(backups.full) do count = count + 1 end
        print("|cff00aaffCVarMaster|r: Backed up " .. count .. " CVars")
    end
end

---Restore from backup
function Manager:RestoreBackup(full)
    if IsInCombat() then
        print("|cffff8800CVarMaster:|r Cannot restore backup during combat")
        return 0
    end

    -- Try session backup first, then persisted DB backup
    local backup = full and (backups.full or (CVarMaster.db and CVarMaster.db.backup)) or backups.single
    if not backup then
        print("|cffff0000CVarMaster:|r No backup found")
        return 0
    end

    local count, skipped = 0, 0
    for name, value in pairs(backup) do
        if GetCVar(name) ~= nil then
            SetCVar(name, value)
            CVarMaster.CVarScanner:UpdateCVarInCache(name)
            count = count + 1
        else
            skipped = skipped + 1
        end
    end

    local skipNote = skipped > 0 and (" (" .. skipped .. " removed CVars skipped)") or ""
    print("|cff00aaffCVarMaster|r: Restored " .. count .. " CVars from backup" .. skipNote)
    print("|cffff8800Note:|r Some changes may require |cff00ff00/reload|r")
    return count
end

---Get backup info
function Manager:GetBackupInfo()
    local singleCount, fullCount = 0, 0
    if backups.single then for _ in pairs(backups.single) do singleCount = singleCount + 1 end end
    local fullBackup = backups.full or (CVarMaster.db and CVarMaster.db.backup)
    if fullBackup then for _ in pairs(fullBackup) do fullCount = fullCount + 1 end end

    return {
        hasSingleBackup = backups.single ~= nil,
        hasFullBackup = fullBackup ~= nil,
        singleCount = singleCount,
        fullCount = fullCount,
    }
end

---Compare current CVar values against saved backup, print drifted ones
function Manager:CompareToBackup()
    local backup = backups.full or (CVarMaster.db and CVarMaster.db.backup)
    if not backup then
        print("|cffff0000CVarMaster:|r No backup found. Hit Backup first, then /reload to test.")
        return
    end

    local drifted = {}
    local matched = 0
    local total = 0

    for name, savedValue in pairs(backup) do
        total = total + 1
        local currentValue = GetCVar(name)
        if currentValue == nil then
            -- CVar no longer exists
            table.insert(drifted, { name = name, saved = savedValue, current = "NIL", reason = "removed" })
        elseif tostring(currentValue) ~= tostring(savedValue) then
            table.insert(drifted, { name = name, saved = savedValue, current = currentValue, reason = "changed" })
        else
            matched = matched + 1
        end
    end

    -- Sort by name
    table.sort(drifted, function(a, b) return a.name < b.name end)

    print("|cff00aaffCVarMaster|r: Backup comparison — " .. total .. " CVars checked")
    print("|cff00ff00  Held:|r " .. matched .. "  |cffff4444Drifted:|r " .. #drifted)

    if #drifted > 0 then
        print("|cffff8800  --- Drifted CVars (need lock to persist) ---|r")
        for _, d in ipairs(drifted) do
            local savedStr = tostring(d.saved)
            local currentStr = tostring(d.current)
            -- Truncate long values
            if #savedStr > 20 then savedStr = savedStr:sub(1, 17) .. "..." end
            if #currentStr > 20 then currentStr = currentStr:sub(1, 17) .. "..." end
            print(string.format("  |cffcccccc%s|r: |cffff4444%s|r -> |cff44ff44%s|r", d.name, savedStr, currentStr))
        end
    else
        print("|cff00ff00  All CVars held their values!|r")
    end

    -- Store results for GUI access
    CVarMaster.lastCompare = { drifted = drifted, matched = matched, total = total }
    return drifted
end

---Check if CVar is combat protected
function Manager:IsCombatProtected(cvarName)
    return IsCombatProtected(cvarName)
end

---Check if currently in combat
function Manager:IsInCombat()
    return IsInCombat()
end

-- ============================================================================
-- LOCK/PERSIST SYSTEM
-- Locked CVars are automatically reapplied on PLAYER_LOGIN
-- ============================================================================

---Lock a CVar to persist across sessions
---@param cvarName string CVar name
---@param value string|nil Value to lock (uses current value if nil)
function Manager:LockCVar(cvarName, value)
    local data = CVarMaster.CVarScanner:GetCVarData(cvarName)
    if not data then
        print("|cffff0000CVarMaster:|r CVar not found:", cvarName)
        return false
    end

    -- Ensure charDB exists
    if not CVarMaster.charDB then
        CVarMaster.charDB = {}
    end
    if not CVarMaster.charDB.lockedCVars then
        CVarMaster.charDB.lockedCVars = {}
    end

    -- Use current value if not specified
    local lockValue = value or data.value
    CVarMaster.charDB.lockedCVars[cvarName] = lockValue

    print("|cff00aaffCVarMaster:|r Locked |cffffaa00" .. (data.friendlyName or cvarName) .. "|r = " .. lockValue)
    return true
end

---Unlock a CVar (stop persisting)
---@param cvarName string CVar name
function Manager:UnlockCVar(cvarName)
    if not CVarMaster.charDB or not CVarMaster.charDB.lockedCVars then
        print("|cffff0000CVarMaster:|r No locked CVars")
        return false
    end

    if not CVarMaster.charDB.lockedCVars[cvarName] then
        print("|cffff0000CVarMaster:|r CVar not locked:", cvarName)
        return false
    end

    local data = CVarMaster.CVarScanner:GetCVarData(cvarName)
    local friendlyName = data and data.friendlyName or cvarName

    CVarMaster.charDB.lockedCVars[cvarName] = nil
    print("|cff00aaffCVarMaster:|r Unlocked |cffffaa00" .. friendlyName .. "|r")
    return true
end

---Check if a CVar is locked
---@param cvarName string CVar name
---@return boolean isLocked
---@return string|nil lockedValue
function Manager:IsLocked(cvarName)
    if not CVarMaster.charDB or not CVarMaster.charDB.lockedCVars then
        return false, nil
    end
    local value = CVarMaster.charDB.lockedCVars[cvarName]
    return value ~= nil, value
end

---Get all locked CVars
---@return table lockedCVars Table of {cvarName = value}
function Manager:GetLockedCVars()
    if not CVarMaster.charDB or not CVarMaster.charDB.lockedCVars then
        return {}
    end
    return CVarMaster.charDB.lockedCVars
end

---Apply all locked CVars (called after loading screen)
---@param silent? boolean Suppress even debug output (auto-enforce path must stay silent)
---@return number count Number of CVars applied
---@return number notRegistered Number of locks whose CVar wasn't registered yet
function Manager:ApplyLockedCVars(silent)
    local locked = self:GetLockedCVars()
    local count = 0
    local notRegistered = 0
    local debug = not silent and CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.debug

    for cvarName, value in pairs(locked) do
        local before = GetCVar(cvarName)
        if before ~= nil then
            local lockedStr = tostring(value)
            -- ONLY call SetCVar if value actually differs (avoid re-tainting CVars)
            if tostring(before) ~= lockedStr then
                SetCVar(cvarName, lockedStr)
                if debug then
                    local after = GetCVar(cvarName)
                    local status = (tostring(after) == lockedStr) and "|cff00ff00OK|r" or "|cffff0000FAIL|r"
                    print("  " .. cvarName .. ": " .. tostring(before) .. " -> " .. tostring(after) .. " (want: " .. lockedStr .. ") " .. status)
                end
                count = count + 1
            end
        else
            -- Lazily-registered CVars can still read nil this early in the session.
            -- Keep the lock (deleting here silently destroys user data); use
            -- /cvm locked prune for deliberate cleanup of truly removed CVars.
            notRegistered = notRegistered + 1
        end
    end

    return count, notRegistered
end

---Remove locks whose CVars aren't registered in this session
---@return number pruned Number of locks removed
function Manager:PruneStaleLocks()
    local locked = self:GetLockedCVars()
    local pruned = 0
    for cvarName in pairs(locked) do
        if GetCVar(cvarName) == nil then
            locked[cvarName] = nil
            pruned = pruned + 1
        end
    end
    return pruned
end

---Toggle lock state for a CVar
---@param cvarName string CVar name
---@return boolean newLockState
function Manager:ToggleLock(cvarName)
    local isLocked = self:IsLocked(cvarName)
    if isLocked then
        self:UnlockCVar(cvarName)
        return false
    else
        self:LockCVar(cvarName)
        return true
    end
end

-- ============================================================================
-- FORCE CUSTOM SYSTEM
-- Special settings that override the game defaults every login
-- ============================================================================

---Apply Force Custom settings (called on PLAYER_LOGIN)
---@param silent? boolean Suppress chat output (auto-enforce path must stay silent)
function Manager:ApplyForceCustom(silent)
    if not CVarMaster.charDB or not CVarMaster.charDB.forceCustom then
        return 0
    end

    local forceCustom = CVarMaster.charDB.forceCustom
    local count = 0

    -- Force gxMaxFrameLatency to 1 if enabled
    if forceCustom.gxMaxFrameLatency1 then
        local current = GetCVar("GxMaxFrameLatency")
        if current ~= "1" then
            SetCVar("GxMaxFrameLatency", "1")
            count = count + 1
        end
    end

    if count > 0 and not silent then
        print("|cff00aaffCVarMaster:|r Applied " .. count .. " Force Custom setting(s)")
    end

    return count
end

---Set Force Custom option
---@param option string The option key (e.g., "gxMaxFrameLatency1")
---@param enabled boolean Whether to enable the force
function Manager:SetForceCustom(option, enabled)
    if not CVarMaster.charDB then
        CVarMaster.charDB = {}
    end
    if not CVarMaster.charDB.forceCustom then
        CVarMaster.charDB.forceCustom = {}
    end

    CVarMaster.charDB.forceCustom[option] = enabled

    -- Apply immediately
    if option == "gxMaxFrameLatency1" then
        if enabled then
            SetCVar("GxMaxFrameLatency", "1")
            print("|cff00aaffCVarMaster:|r Forced |cffffaa00GxMaxFrameLatency|r to |cff00ff001|r (Triple Buffering override)")
        else
            -- Don't reset it, just stop enforcing
            print("|cff00aaffCVarMaster:|r Stopped forcing |cffffaa00GxMaxFrameLatency|r")
        end
    end
end

---Get Force Custom option state
---@param option string The option key
---@return boolean enabled
function Manager:GetForceCustom(option)
    if not CVarMaster.charDB or not CVarMaster.charDB.forceCustom then
        return false
    end
    return CVarMaster.charDB.forceCustom[option] or false
end

---Get all Force Custom settings
---@return table settings
function Manager:GetAllForceCustom()
    if not CVarMaster.charDB or not CVarMaster.charDB.forceCustom then
        return {}
    end
    return CVarMaster.charDB.forceCustom
end

---Lock all modified CVars from active profile
---@return number count Number of CVars locked
function Manager:LockActiveProfile()
    local activeProfile = CVarMaster.ProfileManager and CVarMaster.ProfileManager:GetActiveProfile()
    if not activeProfile then
        print("|cffff0000CVarMaster:|r No active profile set")
        return 0
    end

    if not CVarMaster.db.profiles or not CVarMaster.db.profiles[activeProfile] then
        print("|cffff0000CVarMaster:|r Profile not found: " .. activeProfile)
        return 0
    end

    local profile = CVarMaster.db.profiles[activeProfile]
    local count = 0

    -- Ensure lockedCVars table exists
    if not CVarMaster.charDB then CVarMaster.charDB = {} end
    if not CVarMaster.charDB.lockedCVars then CVarMaster.charDB.lockedCVars = {} end

    -- Lock all CVars in the profile
    for cvarName, value in pairs(profile.cvars) do
        CVarMaster.charDB.lockedCVars[cvarName] = value
        count = count + 1
    end

    print("|cff00aaffCVarMaster:|r Locked |cff00ff00" .. count .. "|r CVars from profile |cffffaa00" .. activeProfile .. "|r")
    return count
end

---Unlock all CVars from active profile
---@return number count Number of CVars unlocked
function Manager:UnlockActiveProfile()
    local activeProfile = CVarMaster.ProfileManager and CVarMaster.ProfileManager:GetActiveProfile()
    if not activeProfile then
        print("|cffff0000CVarMaster:|r No active profile set")
        return 0
    end

    if not CVarMaster.db.profiles or not CVarMaster.db.profiles[activeProfile] then
        print("|cffff0000CVarMaster:|r Profile not found: " .. activeProfile)
        return 0
    end

    if not CVarMaster.charDB or not CVarMaster.charDB.lockedCVars then
        return 0
    end

    local profile = CVarMaster.db.profiles[activeProfile]
    local count = 0

    -- Unlock all CVars that are in the profile
    for cvarName in pairs(profile.cvars) do
        if CVarMaster.charDB.lockedCVars[cvarName] then
            CVarMaster.charDB.lockedCVars[cvarName] = nil
            count = count + 1
        end
    end

    print("|cff00aaffCVarMaster:|r Unlocked |cffff8800" .. count .. "|r CVars from profile |cffffaa00" .. activeProfile .. "|r")
    return count
end
