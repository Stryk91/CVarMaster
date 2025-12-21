---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

-- Database module placeholder
-- Main database is managed in CVarMaster.lua
-- This file can be expanded for advanced database operations

CVarMaster.Database = {}

---Initialize database
---@param savedVars table Saved variables
---@param charVars table Character variables
function CVarMaster.Database:Initialize(savedVars, charVars)
    CVarMaster.db = savedVars or {}
    CVarMaster.charDB = charVars or {}

    -- Ensure structure
    CVarMaster.db.global = CVarMaster.db.global or { debug = false }
    CVarMaster.db.profiles = CVarMaster.db.profiles or {}

    CVarMaster.charDB.mode = CVarMaster.charDB.mode or CVarMaster.MODES.BASIC
    CVarMaster.charDB.favorites = CVarMaster.charDB.favorites or {}
    CVarMaster.charDB.filters = CVarMaster.charDB.filters or {}
end

return CVarMaster.Database
