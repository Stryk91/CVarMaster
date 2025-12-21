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
