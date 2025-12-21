---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.CVarScanner = {}
local Scanner = CVarMaster.CVarScanner

local cvarCache = {}
local lastScanTime = 0

---Get description for a CVar
local function GetDescription(cvarName)
    if CVarMaster.CVarDescriptions and CVarMaster.CVarDescriptions[cvarName] then
        return CVarMaster.CVarDescriptions[cvarName]
    end
    return nil
end

---Get pretty name for a CVar
local function GetPrettyName(cvarName)
    if CVarMaster.CVarPrettyNames and CVarMaster.CVarPrettyNames[cvarName] then
        return CVarMaster.CVarPrettyNames[cvarName]
    end
    if CVarMaster.CVarMappings and CVarMaster.CVarMappings[cvarName] then
        return CVarMaster.CVarMappings[cvarName].friendlyName
    end
    return nil
end

---Get category for a CVar
local function GetCategory(cvarName)
    if CVarMaster.CVarCategories then
        for category, cvars in pairs(CVarMaster.CVarCategories) do
            for _, name in ipairs(cvars) do
                if name == cvarName then
                    return category
                end
            end
        end
    end
    -- Infer from name
    local lower = cvarName:lower()
    if lower:find("nameplate") then return "Nameplates"
    elseif lower:find("camera") then return "Camera"
    elseif lower:find("sound") or lower:find("audio") or lower:find("music") then return "Audio"
    elseif lower:find("graphics") or lower:find("render") or lower:find("shadow") or lower:find("texture") or lower:find("ssao") or lower:find("msaa") then return "Graphics"
    elseif lower:find("chat") then return "Chat"
    elseif lower:find("combat") or lower:find("threat") or lower:find("floating") then return "Combat"
    elseif lower:find("target") then return "Targeting"
    elseif lower:find("tooltip") then return "Tooltips"
    elseif lower:find("raid") or lower:find("party") then return "Raid & Party"
    elseif lower:find("network") or lower:find("net") or lower:find("ipv") then return "Network"
    elseif lower:find("mouse") or lower:find("key") or lower:find("action") or lower:find("bind") then return "Controls"
    elseif lower:find("unit") or lower:find("status") or lower:find("ui") then return "Interface"
    elseif lower:find("colorblind") or lower:find("accessibility") then return "Accessibility"
    elseif lower:find("fps") or lower:find("perf") or lower:find("lod") or lower:find("cache") then return "Performance"
    elseif lower:find("guild") or lower:find("friend") or lower:find("social") then return "Social"
    elseif lower:find("world") or lower:find("terrain") or lower:find("weather") then return "World"
    end
    return "Other"
end

---Check if CVar is combat protected
local function IsCombatProtected(cvarName)
    return CVarMaster.CombatProtectedCVars and CVarMaster.CombatProtectedCVars[cvarName]
end

---Scan a single CVar and return its data
local function ScanCVar(cvarName)
    local value = GetCVar(cvarName)
    if not value then return nil end
    
    local defaultValue = GetCVarDefault(cvarName)
    local isModified = value ~= defaultValue
    
    local dataType = "string"
    if value == "0" or value == "1" then
        dataType = "boolean"
    elseif tonumber(value) then
        dataType = "number"
    end
    
    return {
        name = cvarName,
        value = value,
        defaultValue = defaultValue or value,
        isModified = isModified,
        dataType = dataType,
        category = GetCategory(cvarName),
        friendlyName = GetPrettyName(cvarName),
        description = GetDescription(cvarName),
        isCombatProtected = IsCombatProtected(cvarName),
        isProtected = false,
        dangerLevel = 0,
    }
end

---Full scan of all known CVars
function Scanner:ScanAll()
    cvarCache = {}
    local count = 0
    
    if CVarMaster.KnownCVars then
        for _, cvarName in ipairs(CVarMaster.KnownCVars) do
            local data = ScanCVar(cvarName)
            if data then
                cvarCache[cvarName] = data
                count = count + 1
            end
        end
    end
    
    if CVarMaster.CVarMappings then
        for cvarName, mapping in pairs(CVarMaster.CVarMappings) do
            if cvarCache[cvarName] then
                -- Already cached - apply overrides from CVarMappings
                if mapping.category then
                    cvarCache[cvarName].category = mapping.category
                end
                if mapping.friendlyName then
                    cvarCache[cvarName].friendlyName = mapping.friendlyName
                end
            else
                -- Not cached - scan and apply
                local data = ScanCVar(cvarName)
                if data then
                    data.friendlyName = mapping.friendlyName or data.friendlyName
                    data.category = mapping.category or data.category
                    cvarCache[cvarName] = data
                    count = count + 1
                end
            end
        end
    end
    
    lastScanTime = GetTime()
    return count
end

function Scanner:RefreshCache()
    return self:ScanAll()
end

function Scanner:GetCachedCVars()
    if next(cvarCache) == nil then
        self:ScanAll()
    end
    return cvarCache
end

function Scanner:GetCVarData(cvarName)
    if not cvarCache[cvarName] then
        local data = ScanCVar(cvarName)
        if data then
            cvarCache[cvarName] = data
        end
    end
    return cvarCache[cvarName]
end

function Scanner:UpdateCVarInCache(cvarName)
    local data = ScanCVar(cvarName)
    if data then
        cvarCache[cvarName] = data
    end
    return data
end

---Filter CVars by category name
function Scanner:FilterByCategory(categoryName, sourceTable)
    local source = sourceTable or self:GetCachedCVars()
    local results = {}
    for name, data in pairs(source) do
        if data.category == categoryName then
            results[name] = data
        end
    end
    return results
end

---Filter modified CVars
function Scanner:FilterModified(sourceTable)
    local source = sourceTable or self:GetCachedCVars()
    local results = {}
    for name, data in pairs(source) do
        if data.isModified then
            results[name] = data
        end
    end
    return results
end

---Search CVars by name/description
function Scanner:Search(query)
    local results = {}
    local lowerQuery = query:lower()
    
    for name, data in pairs(self:GetCachedCVars()) do
        local match = false
        if name:lower():find(lowerQuery, 1, true) then match = true end
        if data.friendlyName and data.friendlyName:lower():find(lowerQuery, 1, true) then match = true end
        if data.description and data.description:lower():find(lowerQuery, 1, true) then match = true end
        if match then results[name] = data end
    end
    
    return results
end

---Alias for Search
function Scanner:SearchCVars(query, sourceTable)
    local lowerQuery = query:lower()
    local source = sourceTable or self:GetCachedCVars()
    local results = {}
    
    for name, data in pairs(source) do
        local match = false
        if name:lower():find(lowerQuery, 1, true) then match = true end
        if data.friendlyName and data.friendlyName:lower():find(lowerQuery, 1, true) then match = true end
        if data.description and data.description:lower():find(lowerQuery, 1, true) then match = true end
        if match then results[name] = data end
    end
    
    return results
end

---Get all unique category names
function Scanner:GetCategories()
    local categories = {}
    local seen = {}
    
    for _, data in pairs(self:GetCachedCVars()) do
        if data.category and not seen[data.category] then
            seen[data.category] = true
            table.insert(categories, data.category)
        end
    end
    
    table.sort(categories)
    return categories
end

---Get category counts (returns table mapping category name to count)
function Scanner:GetCategoryCounts()
    local counts = {}
    
    for _, data in pairs(self:GetCachedCVars()) do
        local cat = data.category or "Other"
        counts[cat] = (counts[cat] or 0) + 1
    end
    
    return counts
end

---Get total CVar count
function Scanner:GetCount()
    local count = 0
    for _ in pairs(self:GetCachedCVars()) do count = count + 1 end
    return count
end

---Get modified count
function Scanner:GetModifiedCount()
    local count = 0
    for _, data in pairs(self:GetCachedCVars()) do
        if data.isModified then count = count + 1 end
    end
    return count
end
