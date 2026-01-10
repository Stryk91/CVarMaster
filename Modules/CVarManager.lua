---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.CVarManager = {}
local Manager = CVarMaster.CVarManager

-- Backup storage
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
    if data.requiresReload or DANGEROUS_RESET_CVARS[cvarName] then
        print("|cff00aaffCVarMaster|r: Set |cffffaa00" .. (data.friendlyName or cvarName) .. "|r - |cffff8800/reload may be required|r")
    else
        print("|cff00aaffCVarMaster|r: Set |cffffaa00" .. (data.friendlyName or cvarName) .. "|r to " .. value)
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

---Backup all CVars
function Manager:BackupAll()
    local cvars = CVarMaster.CVarScanner:GetCachedCVars()
    backups.full = {}

    for name, data in pairs(cvars) do
        backups.full[name] = data.value
    end

    local count = 0
    for _ in pairs(backups.full) do count = count + 1 end
    print("|cff00aaffCVarMaster|r: Backed up " .. count .. " CVars")
end

---Restore from backup
function Manager:RestoreBackup(full)
    if IsInCombat() then
        print("|cffff8800CVarMaster:|r Cannot restore backup during combat")
        return 0
    end

    local backup = full and backups.full or backups.single
    if not backup then
        print("|cffff0000CVarMaster:|r No backup found")
        return 0
    end

    local count = 0
    for name, value in pairs(backup) do
        SetCVar(name, value)
        CVarMaster.CVarScanner:UpdateCVarInCache(name)
        count = count + 1
    end

    print("|cff00aaffCVarMaster|r: Restored " .. count .. " CVars from backup")
    print("|cffff8800Note:|r Some changes may require |cff00ff00/reload|r")
    return count
end

---Get backup info
function Manager:GetBackupInfo()
    local singleCount, fullCount = 0, 0
    if backups.single then for _ in pairs(backups.single) do singleCount = singleCount + 1 end end
    if backups.full then for _ in pairs(backups.full) do fullCount = fullCount + 1 end end
    
    return {
        hasSingleBackup = backups.single ~= nil,
        hasFullBackup = backups.full ~= nil,
        singleCount = singleCount,
        fullCount = fullCount,
    }
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

---Apply all locked CVars (called on PLAYER_LOGIN)
---@return number count Number of CVars applied
function Manager:ApplyLockedCVars()
    local locked = self:GetLockedCVars()
    local count = 0
    local failed = 0

    for cvarName, value in pairs(locked) do
        local currentValue = GetCVar(cvarName)
        if currentValue ~= nil then
            if currentValue ~= value then
                SetCVar(cvarName, value)
                count = count + 1
            end
        else
            -- CVar no longer exists, remove from locks
            CVarMaster.charDB.lockedCVars[cvarName] = nil
            failed = failed + 1
        end
    end

    if count > 0 or failed > 0 then
        local msg = "|cff00aaffCVarMaster:|r Applied " .. count .. " locked CVar(s)"
        if failed > 0 then
            msg = msg .. " |cff888888(" .. failed .. " removed - no longer exist)|r"
        end
        print(msg)
    end

    return count
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
