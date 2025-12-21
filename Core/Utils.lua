---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.Utils = {}
local Utils = CVarMaster.Utils

---Deep copy table
---@param orig table
---@return table
function Utils.DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in next, orig, nil do
            copy[Utils.DeepCopy(k)] = Utils.DeepCopy(v)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

---Parse CVar value to proper type
---@param value string Raw CVar value
---@param dataType string Data type
---@return any Parsed value
function Utils.ParseCVarValue(value, dataType)
    if not value then return nil end

    if dataType == CVarMaster.TYPES.BOOLEAN then
        return value == "1" or value == "true"
    elseif dataType == CVarMaster.TYPES.INTEGER then
        return tonumber(value) and math.floor(tonumber(value)) or 0
    elseif dataType == CVarMaster.TYPES.FLOAT then
        return tonumber(value) or 0.0
    else
        return tostring(value)
    end
end

---Convert value to CVar string
---@param value any Value to convert
---@param dataType string Data type
---@return string CVar string
function Utils.ToCVarString(value, dataType)
    if dataType == CVarMaster.TYPES.BOOLEAN then
        return value and "1" or "0"
    elseif dataType == CVarMaster.TYPES.INTEGER then
        return tostring(math.floor(tonumber(value) or 0))
    elseif dataType == CVarMaster.TYPES.FLOAT then
        return tostring(tonumber(value) or 0.0)
    else
        return tostring(value or "")
    end
end

---Detect CVar data type from value
---@param value string CVar value
---@return string Data type
function Utils.DetectCVarType(value)
    if value == "0" or value == "1" or value == "true" or value == "false" then
        return CVarMaster.TYPES.BOOLEAN
    end

    local num = tonumber(value)
    if num then
        if math.floor(num) == num then
            return CVarMaster.TYPES.INTEGER
        else
            return CVarMaster.TYPES.FLOAT
        end
    end

    return CVarMaster.TYPES.STRING
end

---Format CVar value for display
---@param value any Value
---@param dataType string Data type
---@param basic boolean Basic mode
---@return string Formatted value
function Utils.FormatCVarValue(value, dataType, basic)
    if basic then
        if dataType == CVarMaster.TYPES.BOOLEAN then
            return value and "Enabled" or "Disabled"
        end
    end

    if dataType == CVarMaster.TYPES.BOOLEAN then
        return value and "1 (On)" or "0 (Off)"
    elseif dataType == CVarMaster.TYPES.FLOAT then
        return string.format("%.3f", value)
    else
        return tostring(value)
    end
end

---Get color for CVar based on state
---@param cvarData table CVar data
---@return number r, number g, number b Color
function Utils.GetCVarColor(cvarData)
    if cvarData.dangerLevel and cvarData.dangerLevel >= CVarMaster.DANGER_LEVELS.DANGEROUS then
        local c = CVarMaster.Constants.COLORS.DANGEROUS
        return c.r, c.g, c.b
    end

    if cvarData.dangerLevel and cvarData.dangerLevel >= CVarMaster.DANGER_LEVELS.CAUTION then
        local c = CVarMaster.Constants.COLORS.CAUTION
        return c.r, c.g, c.b
    end

    if cvarData.requiresReload then
        local c = CVarMaster.Constants.COLORS.REQUIRES_RELOAD
        return c.r, c.g, c.b
    end

    if cvarData.isModified then
        local c = CVarMaster.Constants.COLORS.MODIFIED
        return c.r, c.g, c.b
    end

    local c = CVarMaster.Constants.COLORS.DEFAULT
    return c.r, c.g, c.b
end

---Encode string for export
---@param str string String to encode
---@return string Encoded string
function Utils.EncodeString(str)
    -- Simple base64-like encoding for profile export
    -- In production, use proper Base64 library
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result = ""

    for i = 1, #str, 3 do
        local a, b, c = string.byte(str, i, i + 2)
        b = b or 0
        c = c or 0

        local n = a * 65536 + b * 256 + c

        local c1 = math.floor(n / 262144) % 64 + 1
        local c2 = math.floor(n / 4096) % 64 + 1
        local c3 = math.floor(n / 64) % 64 + 1
        local c4 = n % 64 + 1

        result = result .. b64chars:sub(c1, c1) .. b64chars:sub(c2, c2)
        if b > 0 then result = result .. b64chars:sub(c3, c3) end
        if c > 0 then result = result .. b64chars:sub(c4, c4) end
    end

    return result
end

---Print message
---@param ... any Messages
function Utils.Print(...)
    print("|cff00aaffCVarMaster|r:", ...)
end

---Print error
---@param ... any Messages
function Utils.Error(...)
    print("|cffff0000CVarMaster Error|r:", ...)
end

---Print debug (if enabled)
---@param ... any Messages
function Utils.Debug(...)
    if CVarMaster.db and CVarMaster.db.global.debug then
        print("|cffaaaaaa[Debug]|r", ...)
    end
end

---Safe function call
---@param func function Function to call
---@param ... any Arguments
---@return boolean success, any result
function Utils.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        Utils.Error("Function call failed:", result)
    end
    return success, result
end
