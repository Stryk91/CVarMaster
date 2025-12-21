---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

-- Friendly name mappings for Basic mode
CVarMaster.CVarMappings = {
    -- Camera
    ["cameraDistanceMaxZoomFactor"] = {
        friendlyName = "Max Camera Distance",
        description = "How far you can zoom out the camera",
        category = "Camera",
        basicWidget = "slider",
        basicMin = 1.0,
        basicMax = 2.6,
        basicLabels = { "Close", "Normal", "Far", "Very Far" },
    },

    ["cameraYawMoveSpeed"] = {
        friendlyName = "Camera Horizontal Turn Speed",
        description = "How fast the camera rotates left/right",
        category = "Camera",
        basicWidget = "slider",
        basicMin = 0.005,
        basicMax = 0.025,
        basicLabels = { "Slow", "Normal", "Fast" },
    },

    ["cameraPitchMoveSpeed"] = {
        friendlyName = "Camera Vertical Turn Speed",
        description = "How fast the camera rotates up/down",
        category = "Camera",
        basicWidget = "slider",
        basicMin = 0.005,
        basicMax = 0.025,
        basicLabels = { "Slow", "Normal", "Fast" },
    },

    ["cameraWaterCollision"] = {
        friendlyName = "Camera Water Collision",
        description = "Prevents camera from going underwater",
        category = "Camera",
        basicWidget = "checkbox",
    },

    -- Nameplates
    ["nameplateMaxDistance"] = {
        friendlyName = "Nameplate View Distance",
        description = "Maximum distance to show nameplates",
        category = "Nameplates",
        basicWidget = "slider",
        basicMin = 10,
        basicMax = 60,
        basicLabels = { "Close", "Normal", "Far", "Maximum" },
    },

    ["nameplateGlobalScale"] = {
        friendlyName = "Nameplate Size",
        description = "Overall size of all nameplates",
        category = "Nameplates",
        basicWidget = "slider",
        basicMin = 0.5,
        basicMax = 2.0,
        basicLabels = { "Small", "Normal", "Large", "Huge" },
    },

    ["nameplateOtherTopInset"] = {
        friendlyName = "Enemy Nameplate Top Margin",
        description = "Vertical spacing for enemy nameplates",
        category = "Nameplates",
        basicWidget = "slider",
        basicMin = -1,
        basicMax = 0.2,
    },

    ["nameplateShowEnemies"] = {
        friendlyName = "Show Enemy Nameplates",
        description = "Display nameplates for enemy units",
        category = "Nameplates",
        basicWidget = "checkbox",
    },

    ["nameplateShowFriends"] = {
        friendlyName = "Show Friendly Nameplates",
        description = "Display nameplates for friendly units",
        category = "Nameplates",
        basicWidget = "checkbox",
    },

    -- Graphics
    ["graphicsQuality"] = {
        friendlyName = "Graphics Quality Preset",
        description = "Overall graphics quality setting",
        category = "Graphics",
        basicWidget = "dropdown",
        basicOptions = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" },
        basicLabels = { "Low", "Fair", "Good", "High", "Ultra", "6", "7", "8", "9", "10" },
    },

    ["renderScale"] = {
        friendlyName = "Render Scale",
        description = "Resolution scaling (higher = sharper but slower)",
        category = "Graphics",
        basicWidget = "slider",
        basicMin = 0.5,
        basicMax = 2.0,
        basicLabels = { "Performance", "Balanced", "Quality" },
    },

    ["particleDensity"] = {
        friendlyName = "Particle Density",
        description = "Amount of spell effects and particles",
        category = "Graphics",
        basicWidget = "slider",
        basicMin = 0,
        basicMax = 100,
        basicLabels = { "None", "Low", "Medium", "High", "Ultra" },
    },

    ["shadowTextureSize"] = {
        friendlyName = "Shadow Quality",
        description = "Quality of shadow rendering",
        category = "Graphics",
        basicWidget = "dropdown",
        basicOptions = { "512", "1024", "2048", "4096" },
        basicLabels = { "Low", "Medium", "High", "Ultra" },
    },

    -- Combat
    ["floatingCombatTextCombatDamage"] = {
        friendlyName = "Show Damage Numbers",
        description = "Display damage numbers during combat",
        category = "Combat",
        basicWidget = "checkbox",
    },

    ["floatingCombatTextCombatHealing"] = {
        friendlyName = "Show Healing Numbers",
        description = "Display healing numbers",
        category = "Combat",
        basicWidget = "checkbox",
    },

    ["combatLogPeriodicSpells"] = {
        friendlyName = "Log Periodic Spell Effects",
        description = "Show periodic damage/healing in combat log",
        category = "Combat",
        basicWidget = "checkbox",
    },

    ["autoDismountFlying"] = {
        friendlyName = "Auto Dismount When Flying",
        description = "Automatically dismount when casting spells while flying",
        category = "Combat",
        basicWidget = "checkbox",
    },

    -- Interface
    ["uiScale"] = {
        friendlyName = "UI Scale",
        description = "Overall size of the user interface",
        category = "Interface",
        basicWidget = "slider",
        basicMin = 0.64,
        basicMax = 1.0,
        basicLabels = { "Small", "Normal", "Large" },
    },

    ["useUiScale"] = {
        friendlyName = "Enable Custom UI Scale",
        description = "Use custom UI scaling instead of automatic",
        category = "Interface",
        basicWidget = "checkbox",
    },

    ["colorblindMode"] = {
        friendlyName = "Colorblind Mode",
        description = "Enable colorblind-friendly interface",
        category = "Accessibility",
        basicWidget = "dropdown",
        basicOptions = { "0", "1", "2", "3" },
        basicLabels = { "None", "Protanopia", "Deuteranopia", "Tritanopia" },
    },

    -- Performance
    ["maxFPS"] = {
        friendlyName = "Max Frame Rate (Foreground)",
        description = "Maximum FPS when game window is active",
        category = "Performance",
        basicWidget = "slider",
        basicMin = 30,
        basicMax = 200,
        basicLabels = { "30", "60", "120", "144", "Unlimited" },
    },

    ["maxFPSBk"] = {
        friendlyName = "Max Frame Rate (Background)",
        description = "Maximum FPS when game window is in background",
        category = "Performance",
        basicWidget = "slider",
        basicMin = 10,
        basicMax = 60,
        basicLabels = { "10", "30", "60" },
    },

    ["RAIDgraphicsQuality"] = {
        friendlyName = "Raid Graphics Quality",
        description = "Automatically reduce graphics quality in raids",
        category = "Performance",
        basicWidget = "checkbox",
    },

    -- Audio
    ["Sound_MasterVolume"] = {
        friendlyName = "Master Volume",
        description = "Overall volume level",
        category = "Audio",
        basicWidget = "slider",
        basicMin = 0.0,
        basicMax = 1.0,
        basicLabels = { "Mute", "Quiet", "Normal", "Loud" },
    },

    ["Sound_MusicVolume"] = {
        friendlyName = "Music Volume",
        description = "Background music volume",
        category = "Audio",
        basicWidget = "slider",
        basicMin = 0.0,
        basicMax = 1.0,
        basicLabels = { "Mute", "Quiet", "Normal", "Loud" },
    },

    ["Sound_SFXVolume"] = {
        friendlyName = "Sound Effects Volume",
        description = "Sound effects and spell sounds volume",
        category = "Audio",
        basicWidget = "slider",
        basicMin = 0.0,
        basicMax = 1.0,
        basicLabels = { "Mute", "Quiet", "Normal", "Loud" },
    },

    -- Tooltips
    ["UberTooltips"] = {
        friendlyName = "Enhanced Tooltips",
        description = "Show additional information in tooltips",
        category = "Tooltips",
        basicWidget = "checkbox",
    },

    ["showTooltips"] = {
        friendlyName = "Show Tooltips",
        description = "Display tooltips when hovering over items/spells",
        category = "Tooltips",
        basicWidget = "checkbox",
    },

    -- Network
    ["reducedLagTolerance"] = {
        friendlyName = "Reduced Lag Tolerance",
        description = "Optimize network performance (may affect spell queueing)",
        category = "Network",
        basicWidget = "checkbox",
    },

    ["SpellQueueWindow"] = {
        friendlyName = "Spell Queue Window",
        description = "Time window for queuing next spell (milliseconds)",
        category = "Network",
        basicWidget = "slider",
        basicMin = 0,
        basicMax = 400,
        basicLabels = { "Off", "100ms", "200ms", "400ms" },
    },

    -- Chat
    ["chatStyle"] = {
        friendlyName = "Chat Style",
        description = "Classic or modern chat window style",
        category = "Chat",
        basicWidget = "dropdown",
        basicOptions = { "classic", "im" },
        basicLabels = { "Classic", "Modern (IM Style)" },
    },

    ["profanityFilter"] = {
        friendlyName = "Profanity Filter",
        description = "Filter inappropriate language in chat",
        category = "Chat",
        basicWidget = "checkbox",
    },

    -- Targeting
    ["TargetNearestUseOld"] = {
        friendlyName = "Use Old Target Nearest",
        description = "Use legacy target nearest enemy behavior",
        category = "Targeting",
        basicWidget = "checkbox",
    },

    ["autoLootDefault"] = {
        friendlyName = "Auto Loot",
        description = "Automatically loot corpses and containers",
        category = "Interface",
        basicWidget = "checkbox",
    },


    -- Network (Additional)
    ["useIPv6"] = {
        friendlyName = "Use IPv6",
        description = "Enable IPv6 network connections",
        category = "Network",
        basicWidget = "checkbox",
    },

    ["disableServerNagle"] = {
        friendlyName = "Disable Nagle Algorithm",
        description = "Disable TCP Nagle algorithm for lower latency (may increase bandwidth)",
        category = "Network",
        basicWidget = "checkbox",
    },

    ["disableAutoRealmSelect"] = {
        friendlyName = "Disable Auto Realm Select",
        description = "Prevent automatic realm selection",
        category = "Network",
        basicWidget = "checkbox",
    },

    ["gxFixLag"] = {
        friendlyName = "Fix Graphics Lag",
        description = "Reduce input lag by modifying render queue",
        category = "Network",
        basicWidget = "checkbox",
    },

    ["gxMaxFrameLatency"] = {
        friendlyName = "Max Frame Latency",
        description = "Maximum frames to queue (lower = less input lag, higher = smoother)",
        category = "Graphics",
        basicWidget = "slider",
        basicMin = 1,
        basicMax = 6,
        basicLabels = { "1 (Low Latency)", "3 (Balanced)", "6 (Smooth)" },
    },

    ["initialRealmListTimeout"] = {
        friendlyName = "Realm List Timeout",
        description = "Timeout for initial realm list fetch (seconds)",
        category = "Network",
        basicWidget = "slider",
        basicMin = 5,
        basicMax = 60,
    },

    ["serverAlert"] = {
        friendlyName = "Server Alerts",
        description = "Show server alert messages",
        category = "Network",
        basicWidget = "checkbox",
    },
    -- FFX (Full Screen Effects)
    ["ffxGlow"] = {
        friendlyName = "FFX Glow",
        description = "Full screen glow effect",
        category = "Graphics",
        basicWidget = "checkbox",
    },

    ["ffxNether"] = {
        friendlyName = "FFX Nether",
        description = "Full screen nether/glow effect",
        category = "Graphics",
        basicWidget = "checkbox",
    },

    ["ffxDeath"] = {
        friendlyName = "FFX Death",
        description = "Full screen death effect",
        category = "Graphics",
        basicWidget = "checkbox",
    },

    ["ffxAntiAliasingMode"] = {
        friendlyName = "FFX Anti-Aliasing Mode",
        description = "Full screen anti-aliasing mode",
        category = "Graphics",
        basicWidget = "dropdown",
        basicOptions = { "0", "1", "2", "3" },
        basicLabels = { "Off", "Low", "Medium", "High" },
    },

    ["ffxRectangle"] = {
        friendlyName = "FFX Rectangle",
        description = "Use rectangle texture for full screen effects",
        category = "Graphics",
        basicWidget = "checkbox",
    },
}

-- Store in global namespace
CVarMaster.FriendlyNames = {}
for cvar, data in pairs(CVarMaster.CVarMappings) do
    CVarMaster.FriendlyNames[cvar] = data.friendlyName
end
