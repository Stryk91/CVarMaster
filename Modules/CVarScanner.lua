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

-- Reverse lookup table: cvarName → category (built once on first use)
local categoryLookup = nil

local function BuildCategoryLookup()
    categoryLookup = {}
    if CVarMaster.CVars12_1Lookup then
        for cvarName in pairs(CVarMaster.CVars12_1Lookup) do
            categoryLookup[cvarName] = "New in 12.1"
        end
    end
    if CVarMaster.CVars12Lookup then
        for cvarName in pairs(CVarMaster.CVars12Lookup) do
            -- 12.1 priority wins if a name somehow appears in both lists
            if not categoryLookup[cvarName] then
                categoryLookup[cvarName] = "New in 12.0"
            end
        end
    end
    if CVarMaster.CVarCategories then
        for category, cvars in pairs(CVarMaster.CVarCategories) do
            for _, name in ipairs(cvars) do
                -- Don't overwrite 12.0 priority
                if not categoryLookup[name] then
                    categoryLookup[name] = category
                end
            end
        end
    end
end

---Get category for a CVar
local function GetCategory(cvarName)
    -- User overrides take absolute priority. Set via Scanner:SetCategoryOverride.
    local overrides = CVarMaster.db and CVarMaster.db.categoryOverrides
    if overrides and overrides[cvarName] then
        return overrides[cvarName]
    end
    if not categoryLookup then
        BuildCategoryLookup()
    end
    if categoryLookup[cvarName] then
        return categoryLookup[cvarName]
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
    
    -- Use mapping dataType if available (avoids 0/1 boolean misclassification)
    local dataType = nil
    if CVarMaster.CVarMappings and CVarMaster.CVarMappings[cvarName] then
        dataType = CVarMaster.CVarMappings[cvarName].dataType
    end
    if not dataType then
        -- Heuristic fallback for unknown CVars
        local num = tonumber(value)
        if num then
            if num == math.floor(num) then
                dataType = "integer"
            else
                dataType = "float"
            end
        else
            dataType = "string"
        end
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
        isProtected = CVarMaster.ProtectedCVars and CVarMaster.ProtectedCVars[cvarName] or false,
        dangerLevel = CVarMaster.GetCVarDanger and select(1, CVarMaster.GetCVarDanger(cvarName)) or 0,
        requiresReload = CVarMaster.RequiresReload and CVarMaster.RequiresReload(cvarName) or false,
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
        local userOverrides = CVarMaster.db and CVarMaster.db.categoryOverrides
        for cvarName, mapping in pairs(CVarMaster.CVarMappings) do
            -- A user override always wins over CVarMappings.category. Without
            -- this check, the second pass below would clobber the override
            -- that ScanCVar -> GetCategory just resolved correctly, so user
            -- overrides would silently revert on every ScanAll.
            local userPickedCategory = userOverrides and userOverrides[cvarName] ~= nil

            if cvarCache[cvarName] then
                -- Already cached - apply overrides from CVarMappings
                if mapping.category and not userPickedCategory then
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
                    -- ScanCVar already set data.category via GetCategory, which
                    -- consults user overrides. Only apply the mapping category
                    -- when the user hasn't claimed this CVar.
                    if not userPickedCategory then
                        data.category = mapping.category or data.category
                    end
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

---Apply the CVarMappings category overlay to a freshly scanned entry, mirroring
---ScanAll's second pass. Without this, any single-CVar rescan (e.g. the one
---Manager:SetCVar triggers after every edit) silently drops the mapping
---category and the row jumps to whatever GetCategory infers ("Other").
---User overrides still win, same as in ScanAll.
local function ApplyMappingOverlay(data)
    if not data then return data end
    local mapping = CVarMaster.CVarMappings and CVarMaster.CVarMappings[data.name]
    if mapping and mapping.category then
        local overrides = CVarMaster.db and CVarMaster.db.categoryOverrides
        if not (overrides and overrides[data.name] ~= nil) then
            data.category = mapping.category
        end
    end
    return data
end

function Scanner:GetCVarData(cvarName)
    if not cvarCache[cvarName] then
        local data = ApplyMappingOverlay(ScanCVar(cvarName))
        if data then
            cvarCache[cvarName] = data
        end
    end
    return cvarCache[cvarName]
end

function Scanner:UpdateCVarInCache(cvarName)
    local data = ApplyMappingOverlay(ScanCVar(cvarName))
    if data then
        cvarCache[cvarName] = data
    end
    return data
end

---Refresh a single cache entry when the client fires CVAR_UPDATE (Blizzard
---Options, other addons or scripts changing values behind our back). Only
---already-cached names are refreshed, keeping the handler cheap.
function Scanner:OnCVarChanged(cvarName)
    if cvarName and cvarCache[cvarName] then
        self:UpdateCVarInCache(cvarName)
    end
end

---Patch the cached category field on an entry without re-scanning the CVar.
---A full re-scan calls GetCVar/GetCVarDefault, which on certain restricted
---CVars (e.g. event-log family) can taint when called repeatedly from
---insecure code. Since changing category doesn't change value/type/etc.,
---the cached entry is structurally the same — we only mutate one field.
local function PatchCachedCategory(cvarName, newCategory)
    local entry = cvarCache[cvarName]
    if not entry then return end
    entry.category = newCategory or GetCategory(cvarName)
end

---Set or clear a user category override for a CVar. Persists in
---CVarMaster.db.categoryOverrides and is consulted first by GetCategory.
---Pass nil/empty for newCategory to clear the override.
---@param cvarName string
---@param newCategory string|nil
function Scanner:SetCategoryOverride(cvarName, newCategory)
    if not (CVarMaster.db and cvarName) then return end
    CVarMaster.db.categoryOverrides = CVarMaster.db.categoryOverrides or {}
    if newCategory == nil or newCategory == "" then
        CVarMaster.db.categoryOverrides[cvarName] = nil
        PatchCachedCategory(cvarName, nil)  -- recompute via GetCategory inference
    else
        CVarMaster.db.categoryOverrides[cvarName] = newCategory
        PatchCachedCategory(cvarName, newCategory)
    end
end

---Bulk apply a category to many CVars in one shot. Returns count actually changed.
---@param cvarNames table list of CVar names
---@param newCategory string
---@return number changed
function Scanner:BulkSetCategoryOverride(cvarNames, newCategory)
    if not (CVarMaster.db and newCategory and newCategory ~= "") then return 0 end
    CVarMaster.db.categoryOverrides = CVarMaster.db.categoryOverrides or {}
    local changed = 0
    for _, name in ipairs(cvarNames) do
        if CVarMaster.db.categoryOverrides[name] ~= newCategory then
            CVarMaster.db.categoryOverrides[name] = newCategory
            changed = changed + 1
        end
        -- Patch only the .category field on the cache entry. Avoids the
        -- per-CVar GetCVar/GetCVarDefault re-scan that triggered the
        -- taint cascade when bulk-applying to large selections.
        PatchCachedCategory(name, newCategory)
    end
    return changed
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

---Search-term aliases: shorthand / synonyms a user might type that don't
---literally appear in CVar names, descriptions or categories. Each alias
---expands to extra substrings that are OR-matched alongside the typed word,
---so "gfx" also surfaces graphics / gx* / render CVars. Keys MUST be lowercase.
---Only add expansions the plain substring match can't already find (e.g.
---"cam" needs no alias — it's a substring of "camera"), and never expand a
---word to something SHORTER/more generic ("nameplate"->"np" matched 20+
---unrelated CVars via showNPETutorials, UnitNameNPC, VoiceInput, ...).
local SEARCH_ALIASES = {
    gfx       = { "graphic", "gx", "render", "shader" },
    gpu       = { "graphic", "gx", "render" },
    graphics  = { "gx", "render" },
    vfx       = { "visual", "particle", "spelleffect" },
    sfx       = { "sound", "audio" },
    fps       = { "performance", "lod" },
    framerate = { "performance" },
    aa        = { "antialias" },
    np        = { "nameplate" },
    ui        = { "interface" },
    net       = { "latency" },
}

---Helper: does a single query word (or any of its aliases) appear in the text?
local function wordMatches(word, searchText)
    if searchText:find(word, 1, true) then
        return true
    end
    local aliases = SEARCH_ALIASES[word]
    if aliases then
        for _, alt in ipairs(aliases) do
            if searchText:find(alt, 1, true) then
                return true
            end
        end
    end
    return false
end

---Helper: Check if all words (alias-expanded) are found in the searchable text
local function matchesAllWords(words, searchText)
    for _, word in ipairs(words) do
        if not wordMatches(word, searchText) then
            return false
        end
    end
    return true
end

---Search CVars by name/description (multi-word AND search)
---Build the searchable text for a CVar entry. Includes the name, friendly
---name, description AND the category, so users can search by concept
---("camera", "audio", "raid") and find anything in that category even if
---the CVar name itself doesn't contain the word.
local function BuildSearchText(name, data)
    local parts = { name:lower() }
    if data.friendlyName then parts[#parts + 1] = data.friendlyName:lower() end
    if data.description  then parts[#parts + 1] = data.description:lower()  end
    if data.category     then parts[#parts + 1] = data.category:lower()     end
    return table.concat(parts, " ")
end

function Scanner:Search(query)
    local results = {}
    local lowerQuery = query:lower()

    -- Split query into words (space-separated)
    local words = {}
    for word in lowerQuery:gmatch("%S+") do
        table.insert(words, word)
    end

    for name, data in pairs(self:GetCachedCVars()) do
        if matchesAllWords(words, BuildSearchText(name, data)) then
            results[name] = data
        end
    end

    return results
end

---Alias for Search with optional source table
function Scanner:SearchCVars(query, sourceTable)
    if not sourceTable then
        return self:Search(query)
    end
    local lowerQuery = query:lower()
    local words = {}
    for word in lowerQuery:gmatch("%S+") do
        table.insert(words, word)
    end
    local results = {}
    for name, data in pairs(sourceTable) do
        if matchesAllWords(words, BuildSearchText(name, data)) then
            results[name] = data
        end
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

---Audit the live client's CVars against KnownCVars + CVarMappings.
---Reports CVars that exist in the running client but aren't in our lists
---(missing) and CVars in our lists that the client no longer has (deprecated).
---Result is saved to CVarMasterDB.audit so it survives /reload to disk.
---@return table missing Sorted list of live CVar names not in our data
---@return table deprecated Sorted list of our entries that no longer exist
function Scanner:Audit()
    -- ConsoleGetAllCommands is a global on retail (the Console system has no
    -- Namespace in the API docs). Older or alt clients may not have it.
    local enumerator = _G.ConsoleGetAllCommands
    if type(enumerator) ~= "function" then
        print("|cffff0000CVarMaster:|r ConsoleGetAllCommands not available on this client.")
        return {}, {}
    end

    -- Build a case-insensitive set of every CVar name we already know about,
    -- pulling from both KnownCVars (the array list) and CVarMappings (the
    -- friendly-name table). Values stored in the set are the original case.
    local known = {}
    local knownCount = 0
    if CVarMaster.KnownCVars then
        for _, name in ipairs(CVarMaster.KnownCVars) do
            local key = name:lower()
            if not known[key] then
                known[key] = name
                knownCount = knownCount + 1
            end
        end
    end
    if CVarMaster.CVarMappings then
        for name in pairs(CVarMaster.CVarMappings) do
            local key = name:lower()
            if not known[key] then
                known[key] = name
                knownCount = knownCount + 1
            end
        end
    end

    -- Walk the live console command table.
    -- Enum.ConsoleCommandType.Cvar = 0 in retail. Fall back to 0 if Enum
    -- isn't populated rather than the wrong default of 1 (which is Command).
    local cvarType = (Enum and Enum.ConsoleCommandType and Enum.ConsoleCommandType.Cvar) or 0
    local commands = enumerator() or {}

    local liveSet = {}
    local liveCount = 0
    local missing = {}
    for _, cmd in ipairs(commands) do
        local isCVar
        if cvarType ~= nil then
            isCVar = cmd.commandType == cvarType
        else
            -- Fallback if Enum isn't populated: trust the field exists and use 1.
            isCVar = cmd.commandType == 1
        end
        if isCVar and cmd.command then
            local key = cmd.command:lower()
            if not liveSet[key] then
                liveSet[key] = cmd.command
                liveCount = liveCount + 1
                if not known[key] then
                    table.insert(missing, cmd.command)
                end
            end
        end
    end

    local deprecated = {}
    for key, originalName in pairs(known) do
        if not liveSet[key] then
            table.insert(deprecated, originalName)
        end
    end

    table.sort(missing)
    table.sort(deprecated)

    -- Persist to SavedVariables so the result survives /reload and is readable
    -- from disk for manual patching of KnownCVars.lua.
    if CVarMaster.db then
        CVarMaster.db.audit = {
            timestamp = time(),
            liveCount = liveCount,
            knownCount = knownCount,
            missing = missing,
            deprecated = deprecated,
        }
    end

    -- Summary to chat.
    print(string.format("|cff00aaffCVarMaster Audit|r"))
    print(string.format("  Live CVars in client:        |cff00ff00%d|r", liveCount))
    print(string.format("  In KnownCVars + Mappings:    |cff00ff00%d|r", knownCount))
    print(string.format("  Missing (live, not listed):  |cffff8800%d|r", #missing))
    print(string.format("  Deprecated (listed, gone):   |cffff4040%d|r", #deprecated))

    -- Show a sample of each so the user can sanity-check before reloading.
    local function showSample(label, list, color)
        if #list == 0 then return end
        local sampleCount = math.min(8, #list)
        local parts = {}
        for i = 1, sampleCount do parts[i] = list[i] end
        print(string.format("  %s sample: %s%s|r", label, color, table.concat(parts, ", ")))
        if #list > sampleCount then
            print(string.format("    %s|cff888888(+%d more)|r", string.rep(" ", 14), #list - sampleCount))
        end
    end
    showSample("Missing",    missing,    "|cffffaa44")
    showSample("Deprecated", deprecated, "|cffff8888")

    print("|cff888888Saved to CVarMasterDB.audit. /reload to flush to disk.|r")

    return missing, deprecated
end
