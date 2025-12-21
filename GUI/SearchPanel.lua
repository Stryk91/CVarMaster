---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI

-- Search history
local searchHistory = {}
local MAX_HISTORY = 10

---Add to search history
---@param term string Search term
function GUI:AddSearchHistory(term)
    if term == "" then return end
    
    -- Remove if already exists
    for i, v in ipairs(searchHistory) do
        if v == term then
            table.remove(searchHistory, i)
            break
        end
    end
    
    -- Add to front
    table.insert(searchHistory, 1, term)
    
    -- Trim to max
    while #searchHistory > MAX_HISTORY do
        table.remove(searchHistory)
    end
end

---Get search history
---@return table history
function GUI:GetSearchHistory()
    return searchHistory
end

---Clear search
function GUI:ClearSearch()
    local mainWindow = GUI:GetMainWindow()
    if mainWindow and mainWindow.searchBox then
        mainWindow.searchBox:SetText("")
        GUI:RefreshCVarList()
    end
end



