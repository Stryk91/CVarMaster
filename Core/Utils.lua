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

-- Base64 character set
local B64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- Build reverse lookup table
local B64_DECODE = {}
for i = 1, #B64_CHARS do
    B64_DECODE[B64_CHARS:sub(i, i)] = i - 1
end

---Encode string to base64
---@param str string String to encode
---@return string Encoded string
function Utils.EncodeString(str)
    local result = {}
    local padding = (3 - #str % 3) % 3

    -- Pad string
    str = str .. string.rep('\0', padding)

    for i = 1, #str, 3 do
        local a, b, c = string.byte(str, i, i + 2)
        local n = a * 65536 + b * 256 + c

        local c1 = math.floor(n / 262144) % 64 + 1
        local c2 = math.floor(n / 4096) % 64 + 1
        local c3 = math.floor(n / 64) % 64 + 1
        local c4 = n % 64 + 1

        table.insert(result, B64_CHARS:sub(c1, c1))
        table.insert(result, B64_CHARS:sub(c2, c2))
        table.insert(result, B64_CHARS:sub(c3, c3))
        table.insert(result, B64_CHARS:sub(c4, c4))
    end

    -- Replace padding with =
    local encoded = table.concat(result)
    if padding > 0 then
        encoded = encoded:sub(1, -padding - 1) .. string.rep('=', padding)
    end

    return encoded
end

---Decode base64 string
---@param str string Encoded string
---@return string|nil Decoded string
function Utils.DecodeString(str)
    if not str or str == "" then return nil end

    -- Remove whitespace
    str = str:gsub("%s+", "")

    -- Check for valid base64
    if not str:match("^[A-Za-z0-9+/=]+$") then
        return nil
    end

    -- Count padding
    local padding = 0
    if str:sub(-2) == "==" then
        padding = 2
    elseif str:sub(-1) == "=" then
        padding = 1
    end

    -- Remove padding for processing
    str = str:gsub("=", "A")

    local result = {}

    for i = 1, #str, 4 do
        local c1 = B64_DECODE[str:sub(i, i)] or 0
        local c2 = B64_DECODE[str:sub(i + 1, i + 1)] or 0
        local c3 = B64_DECODE[str:sub(i + 2, i + 2)] or 0
        local c4 = B64_DECODE[str:sub(i + 3, i + 3)] or 0

        local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4

        table.insert(result, string.char(math.floor(n / 65536) % 256))
        table.insert(result, string.char(math.floor(n / 256) % 256))
        table.insert(result, string.char(n % 256))
    end

    local decoded = table.concat(result)

    -- Remove padding bytes
    if padding > 0 then
        decoded = decoded:sub(1, -padding - 1)
    end

    return decoded
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
