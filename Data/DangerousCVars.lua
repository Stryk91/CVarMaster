---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

-- Database of dangerous CVars with risk levels
CVarMaster.DangerousCVars = {
    -- CRITICAL - Can crash game or corrupt data
    ["gxApi"] = {
        level = CVarMaster.DANGER_LEVELS.CRITICAL,
        warning = "Changing graphics API can crash the game. Requires restart.",
        requiresReload = true,
    },

    ["gxWindow"] = {
        level = CVarMaster.DANGER_LEVELS.CRITICAL,
        warning = "Changing window mode incorrectly can make game unresponsive.",
        requiresReload = true,
    },

    ["gxMaximize"] = {
        level = CVarMaster.DANGER_LEVELS.CRITICAL,
        warning = "Can cause display issues. Requires restart.",
        requiresReload = true,
    },

    -- DANGEROUS - Can break functionality
    ["gxRefresh"] = {
        level = CVarMaster.DANGER_LEVELS.DANGEROUS,
        warning = "Wrong refresh rate can cause display problems.",
        requiresReload = true,
    },

    ["gxResolution"] = {
        level = CVarMaster.DANGER_LEVELS.DANGEROUS,
        warning = "Incorrect resolution can make UI unusable.",
        requiresReload = true,
    },

    ["gxWindowedResolution"] = {
        level = CVarMaster.DANGER_LEVELS.DANGEROUS,
        warning = "Can cause window sizing issues.",
        requiresReload = true,
    },

    ["ffxGlow"] = {
        level = CVarMaster.DANGER_LEVELS.DANGEROUS,
        warning = "Can cause severe performance issues on some hardware.",
    },

    ["ffxDeath"] = {
        level = CVarMaster.DANGER_LEVELS.DANGEROUS,
        warning = "Disabling death effects may cause visual glitches.",
    },

    -- CAUTION - May cause issues
    ["RAIDgraphicsQuality"] = {
        level = CVarMaster.DANGER_LEVELS.CAUTION,
        warning = "Automatically reduces graphics in raids. May cause flickering.",
    },

    ["weatherDensity"] = {
        level = CVarMaster.DANGER_LEVELS.CAUTION,
        warning = "Very high values can impact performance significantly.",
    },

    ["M2Faster"] = {
        level = CVarMaster.DANGER_LEVELS.CAUTION,
        warning = "Can cause animation issues with some models.",
    },

    ["hwDetect"] = {
        level = CVarMaster.DANGER_LEVELS.CAUTION,
        warning = "Disabling hardware detection may cause stability issues.",
    },

    ["portal"] = {
        level = CVarMaster.DANGER_LEVELS.CAUTION,
        warning = "Disabling portals may cause zone transition problems.",
    },

    ["characterAmbient"] = {
        level = CVarMaster.DANGER_LEVELS.CAUTION,
        warning = "Can make characters too dark or bright in certain areas.",
    },

    ["particleMTDensity"] = {
        level = CVarMaster.DANGER_LEVELS.CAUTION,
        warning = "High values can severely impact performance.",
    },

    -- CVars that require reload
    ["scriptErrors"] = {
        requiresReload = false, -- Actually doesn't, but shown as example
    },

    ["showTutorials"] = {
        requiresReload = false,
    },
}

-- CVars that are protected/hidden and shouldn't be modified
CVarMaster.ProtectedCVars = {
    "realmList",
    "portal",
    "accountName",
    "movieSubtitle",
}

-- CVars that require UI reload
CVarMaster.ReloadRequiredCVars = {
    "useUiScale",
    "uiScale",
    "gxApi",
    "gxWindow",
    "gxRefresh",
    "gxResolution",
    "gxWindowedResolution",
    "gxMaximize",
    "chatStyle",
}

---Check if CVar is dangerous
---@param cvarName string CVar name
---@return number level Danger level
---@return string warning Warning message
function CVarMaster.GetCVarDanger(cvarName)
    local danger = CVarMaster.DangerousCVars[cvarName]
    if danger then
        return danger.level or CVarMaster.DANGER_LEVELS.SAFE, danger.warning or ""
    end
    return CVarMaster.DANGER_LEVELS.SAFE, ""
end

---Check if CVar requires reload
---@param cvarName string CVar name
---@return boolean requiresReload
function CVarMaster.RequiresReload(cvarName)
    -- Check explicit dangerous CVars first
    local danger = CVarMaster.DangerousCVars[cvarName]
    if danger and danger.requiresReload ~= nil then
        return danger.requiresReload
    end

    -- Check reload list
    for _, name in ipairs(CVarMaster.ReloadRequiredCVars) do
        if name == cvarName then
            return true
        end
    end

    -- Graphics API changes usually require reload
    if cvarName:match("^gx") then
        return true
    end

    return false
end

---Check if CVar is protected
---@param cvarName string CVar name
---@return boolean protected
function CVarMaster.IsProtected(cvarName)
    for _, name in ipairs(CVarMaster.ProtectedCVars) do
        if name == cvarName then
            return true
        end
    end
    return false
end
