---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

-- CVar categorization by pattern matching and known names
CVarMaster.CVarCategories = {
    -- Graphics
    Graphics = {
        "graphics", "render", "shadow", "texture", "particle", "effect",
        "ambient", "terrain", "liquid", "reflection", "ssao", "bloom",
        "outline", "glow", "distortion", "weather", "projectedTextures",
        "groundEffectDensity", "groundEffectDist", "horizonFarclipScale",
    },

    -- Camera
    Camera = {
        "camera", "pitch", "yaw", "zoom", "fov", "viewdistance",
    },

    -- Nameplates
    Nameplates = {
        "nameplate", "namePlate",
    },

    -- Combat
    Combat = {
        "combat", "floatingCombatText", "lossOfControl", "autoDismount",
        "autoLoot", "autoSelfCast", "combatLog",
    },

    -- Interface
    Interface = {
        "ui", "actionbar", "unitframe", "raidframe", "partyframe",
        "playerframe", "targetframe", "focusframe", "bossframe",
        "showTargetOf", "displayFreeBagSlots", "missingTransmogSourceInItemTooltips",
    },

    -- Audio
    Audio = {
        "Sound_", "music", "voice", "dialog", "ambience",
    },

    -- Network
    Network = {
        "network", "lag", "latency", "SpellQueue", "reducedLag",
    },

    -- Performance
    Performance = {
        "maxFPS", "RAIDgraphics", "preloadWorld",
    },

    -- Tooltips
    Tooltips = {
        "tooltip", "UberTooltip", "showTooltips",
    },

    -- Chat
    Chat = {
        "chat", "whisper", "profanity", "removeChatDelay",
    },

    -- Accessibility
    Accessibility = {
        "colorblind", "accessibility", "CursorSizePreferred",
    },

    -- Controls
    Controls = {
        "mouse", "keyboard", "gamepad", "binding", "softTarget",
        "autoInteract", "interactOnLeftClick",
    },

    -- Targeting
    Targeting = {
        "target", "focus", "assist", "TargetNearest",
    },

    -- Raid & Party
    ["Raid & Party"] = {
        "raid", "party", "arena", "battleground",
    },

    -- World
    World = {
        "world", "map", "minimap", "questlog", "objective",
    },

    -- Social
    Social = {
        "social", "guild", "friend", "showRecruitmentNotification",
    },
}

-- Function to determine category from CVar name
function CVarMaster.GetCVarCategory(cvarName)
    -- Check explicit mappings first
    local mapping = CVarMaster.CVarMappings[cvarName]
    if mapping and mapping.category then
        return mapping.category
    end

    -- Pattern matching
    local lowerName = cvarName:lower()

    for category, patterns in pairs(CVarMaster.CVarCategories) do
        for _, pattern in ipairs(patterns) do
            if lowerName:find(pattern:lower(), 1, true) then
                return category
            end
        end
    end

    return "Other"
end
