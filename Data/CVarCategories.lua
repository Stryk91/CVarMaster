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
        "nagle", "realm", "server", "ipv6", "ipv4", "timeout",
        "frameLatency", "gxFixLag",
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

-- 12.0 Midnight CVars (added in patch 12.0.0/12.0.1)
CVarMaster.CVars12 = {
    -- Combat Audio Alerts (CAA)
    "CAADebuffSelfAlert", "CAAEnabled", "CAAInterruptCast", "CAAInterruptCastSuccess",
    "CAAPartyHealthFrequency", "CAAPartyHealthPercent", "CAAPartyHealthVoice", "CAAPartyHealthVolume",
    "CAAPlayerCastFormat", "CAAPlayerCastMinTime", "CAAPlayerCastMode", "CAAPlayerCastThrottle",
    "CAAPlayerCastVoice", "CAAPlayerCastVolume", "CAAPlayerHealthFormat", "CAAPlayerHealthPercent",
    "CAAPlayerHealthThrottle", "CAAPlayerHealthVoice", "CAAPlayerHealthVolume",
    "CAAResource1Formats", "CAAResource1Percents", "CAAResource1Throttle", "CAAResource1Voice", "CAAResource1Volume",
    "CAAResource2Formats", "CAAResource2Percents", "CAAResource2Throttle", "CAAResource2Voice", "CAAResource2Volume",
    "CAASayCombatEnd", "CAASayCombatStart", "CAASayIfTargeted", "CAASayTargetName",
    "CAASayYourDebuffs", "CAASayYourDebuffsFormat", "CAASayYourDebuffsMinDuration", "CAASayYourDebuffsVoice", "CAASayYourDebuffsVolume",
    "CAASpeed", "CAATargetCastFormat", "CAATargetCastMinTime", "CAATargetCastMode", "CAATargetCastThrottle",
    "CAATargetCastVoice", "CAATargetCastVolume", "CAATargetDeathBehavior", "CAATargetHealthFormat",
    "CAATargetHealthPercent", "CAATargetHealthThrottle", "CAATargetHealthVoice", "CAATargetHealthVolume",
    "CAAVoice", "CAAVolume",
    -- Encounter Timeline/Warnings
    "combatWarningsEnabled", "encounterTimelineEnabled", "encounterTimelineHideForOtherRoles",
    "encounterTimelineHideLongCountdowns", "encounterTimelineHideQueuedCountdowns",
    "encounterTimelineHighlightDuration", "encounterTimelineIconographyEnabled", "encounterTimelineShowSequenceCount",
    "encounterWarningsDefaultMessageDuration", "encounterWarningsEnabled", "encounterWarningsHideIfNotTargetingPlayer",
    "encounterWarningsLevel", "Sound_EnableEncounterWarningsSounds", "Sound_EncounterWarningsVolume",
    -- Damage Meter/External Defensives
    "damageMeterEnabled", "damageMeterResetOnNewInstance", "externalDefensivesEnabled",
    -- Floating Combat Text v2
    "enablePetBattleFloatingCombatText_v2", "floatingCombatTextAuraFade_v2", "floatingCombatTextAuras_v2",
    "floatingCombatTextCombatDamage_v2", "floatingCombatTextCombatDamageAllAutos_v2",
    "floatingCombatTextCombatDamageDirectionalOffset_v2", "floatingCombatTextCombatDamageDirectionalScale_v2",
    "floatingCombatTextCombatHealing_v2", "floatingCombatTextCombatHealingAbsorbSelf_v2",
    "floatingCombatTextCombatHealingAbsorbTarget_v2", "floatingCombatTextCombatLogPeriodicSpells_v2",
    "floatingCombatTextCombatState_v2", "floatingCombatTextComboPoints_v2", "floatingCombatTextDamageReduction_v2",
    "floatingCombatTextDodgeParryMiss_v2", "floatingCombatTextEnergyGains_v2", "floatingCombatTextFloatMode_v2",
    "floatingCombatTextFriendlyHealers_v2", "floatingCombatTextHonorGains_v2", "floatingCombatTextLowManaHealth_v2",
    "floatingCombatTextPeriodicEnergyGains_v2", "floatingCombatTextPetMeleeDamage_v2", "floatingCombatTextPetSpellDamage_v2",
    "floatingCombatTextReactives_v2", "floatingCombatTextRepChanges_v2",
    "WorldTextCritScreenY_v2", "WorldTextGravity_v2", "WorldTextMinAlpha_v2", "WorldTextNonRandomZ_v2",
    "WorldTextRampDuration_v2", "WorldTextRampPow_v2", "WorldTextRampPowCrit_v2", "WorldTextRandomXY_v2",
    "WorldTextRandomZMax_v2", "WorldTextRandomZMin_v2", "WorldTextScale_v2", "WorldTextScreenY_v2", "WorldTextStartPosRandomness_v2",
    -- Nameplates 12.0
    "nameplateAuraScale", "nameplateDebuffPadding", "nameplateShowCastBars", "nameplateShowClassColor",
    "nameplateShowFriendlyClassColor", "nameplateShowFriendlyPlayerGuardians", "nameplateShowFriendlyPlayerMinions",
    "nameplateShowFriendlyPlayerPets", "nameplateShowFriendlyPlayers", "nameplateShowFriendlyPlayerTotems",
    "nameplateShowOffscreen", "nameplateShowOnlyNameForFriendlyPlayerUnits", "nameplateSimplifiedScale",
    "nameplateSize", "nameplateStyle", "nameplateUseClassColorForFriendlyPlayerUnitNames",
    -- Raid Frames 12.0
    "raidFramesCenterBigDefensive", "raidFramesDispelIndicatorOverlay", "raidFramesDispelIndicatorType",
    "raidFramesDisplayLargerRoleSpecificDebuffs", "raidFramesHealthBarColor", "raidFramesHealthBarColorBG",
    -- PvP Diminishing Returns
    "spellDiminishPVPEnemiesEnabled", "spellDiminishPVPOnlyTriggerableByMe",
    -- Transmog 12.0
    "alwaysShowRuneIcons", "lastTransmogCustomSetIDNoSpec", "lastTransmogCustomSetIDSpec1",
    "lastTransmogCustomSetIDSpec2", "lastTransmogCustomSetIDSpec3", "lastTransmogCustomSetIDSpec4",
    "lastTransmogOutfitIDNoSpec", "showAllItemsInTransmog", "showCustomSetDetails",
    "transmogHideIgnoredSlots", "transmogrifySetsFilters",
    -- Delve Tiered Entrance
    "highestUnlockedTieredEntranceTier", "lastLockedTieredEntranceCompanionAbilities", "lastSelectedTieredEntranceTier",
    -- Chat/UI 12.0
    "addonChatRestrictionsForced", "auctionSortByBuyoutPrice", "auctionSortByUnitPrice", "chatBubblesRaid",
    "disableSuggestedLevelActivityFilter", "enableConnectToPhotoSharing", "endeavorInitiativesLastPoints",
    "imageSharingPublishCooldown", "lfgListAdvancedFiltersVersion", "majorFactionRenownMap",
    "petJournalFilterVersion", "seenPurchasableClassCapstone", "trackedInitiativeTasks",
    -- Secret Values / Addon Restrictions
    "secretChallengeModeRestrictionsForced", "secretCombatRestrictionsForced", "secretEncounterRestrictionsForced",
    "secretMapRestrictionsForced", "secretPvPMatchRestrictionsForced",
    "secretAurasForced", "secretCooldownsForced", "secretSpellcastsForced",
    "secretUnitComparisonForced", "secretUnitIdentityForced", "secretUnitPowerForced", "secretUnitPowerMaxForced",
}
-- Build lookup table for fast checking
CVarMaster.CVars12Lookup = {}
for _, name in ipairs(CVarMaster.CVars12) do
    CVarMaster.CVars12Lookup[name] = true
end

-- Function to determine category from CVar name
function CVarMaster.GetCVarCategory(cvarName)
    -- Check 12.0 CVars first (priority category)
    if CVarMaster.CVars12Lookup[cvarName] then
        return "New in 12.0"
    end

    -- Check explicit mappings
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
