---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.SafetyManager = {}
local Safety = CVarMaster.SafetyManager

---Check if a CVar change is safe
---@param cvarName string CVar name
---@param newValue string New value
---@return boolean safe, string|nil warning
function Safety:CheckSafety(cvarName, newValue)
    local dangerData = CVarMaster.DangerousCVars[cvarName]
    
    if not dangerData then
        return true, nil
    end
    
    -- Check danger level
    if dangerData.level >= CVarMaster.DANGER_LEVELS.CRITICAL then
        return false, dangerData.warning or "This CVar can crash or break your game!"
    end
    
    if dangerData.level >= CVarMaster.DANGER_LEVELS.DANGEROUS then
        return true, dangerData.warning or "This CVar may cause issues. Use with caution."
    end
    
    return true, nil
end

---Show safety confirmation dialog
---@param cvarName string CVar name
---@param newValue string New value
---@param onConfirm function Callback if confirmed
function Safety:ShowConfirmation(cvarName, newValue, onConfirm)
    local data = CVarMaster.DangerousCVars[cvarName]
    local warning = data and data.warning or "This may cause issues."
    
    StaticPopupDialogs["CVARMASTER_CONFIRM"] = {
        text = string.format(
            "|cffff0000Warning:|r Changing |cffffaa00%s|r\n\n%s\n\nAre you sure?",
            cvarName, warning
        ),
        button1 = "Yes, Change It",
        button2 = "Cancel",
        OnAccept = function()
            if onConfirm then onConfirm() end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    
    StaticPopup_Show("CVARMASTER_CONFIRM")
end

---Get danger level for a CVar
---@param cvarName string CVar name
---@return number level, string|nil warning
function CVarMaster.GetCVarDanger(cvarName)
    local data = CVarMaster.DangerousCVars[cvarName]
    if data then
        return data.level or 0, data.warning
    end
    return 0, nil
end

---Check if CVar requires reload
---@param cvarName string CVar name
---@return boolean requiresReload
function CVarMaster.RequiresReload(cvarName)
    -- Check mappings
    local mapping = CVarMaster.CVarMappings[cvarName]
    if mapping and mapping.requiresReload then
        return true
    end
    
    -- Check dangerous list
    local danger = CVarMaster.DangerousCVars[cvarName]
    if danger and danger.requiresReload then
        return true
    end
    
    return false
end

---Check if CVar is protected
---@param cvarName string CVar name
---@return boolean isProtected
function CVarMaster.IsProtected(cvarName)
    local danger = CVarMaster.DangerousCVars[cvarName]
    return danger and danger.protected or false
end

CVarMaster.Utils.Debug("SafetyManager module loaded")
