---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local C = CVarMaster.Constants

-- Use shared theme/spacing helpers from Framework
local T = GUI.GetThemeColor
local S = GUI.GetSpacing

local function SetCVarSafe(name, value, quiet)
    local Manager = CVarMaster.CVarManager
    if Manager and Manager.SetCVar then
        return Manager:SetCVar(name, value, quiet)
    end
    SetCVar(name, tostring(value))
    return true
end

local function ApplyPreset(name, preset, reloadHint)
    print("|cff00aaffCVarMaster:|r Applying " .. name .. "…")
    local applied = 0
    for _, pair in ipairs(preset) do
        if SetCVarSafe(pair[1], pair[2], true) then applied = applied + 1 end
    end
    local note = reloadHint and "  |cffff8800(/reload if any change didn't take)|r" or ""
    print(string.format("|cff00aaffCVarMaster:|r %s — %d/%d setting(s) applied%s", name, applied, #preset, note))
end

local function BlockedByCombat(name)
    print("|cffff8800CVarMaster:|r " .. (name or "This action") ..
        " is disabled during combat (touches protected/secure state).")
end

local widgets = {}
local function GetReadoutWidget(key, yOffset, updater)
    if widgets[key] then return widgets[key] end
    local f = CreateFrame("Frame", "CVarMaster" .. key .. "Widget", UIParent)
    f:SetSize(120, 28)
    f:SetPoint("CENTER", 0, yOffset)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnMouseUp", function(self, button) if button == "RightButton" then self:Hide() end end)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.07, 0.85)
    GUI.DisableSharpening(bg)

    local accent = f:CreateTexture(nil, "ARTWORK")
    accent:SetHeight(1)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(accent, 0.5) end
    GUI.DisableSharpening(accent)

    f.txt = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.txt:SetPoint("CENTER")

    local acc = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        acc = acc + elapsed
        if acc < 0.5 then return end
        acc = 0
        updater(self.txt)
    end)

    f:Hide()
    widgets[key] = f
    return f
end

local function ToggleWidget(key, yOffset, updater, on)
    local w = GetReadoutWidget(key, yOffset, updater)
    if on then w:Show() else w:Hide() end
end

local function SpeedReadout(txt)
    local pct = GetUnitSpeed("player") / 7 * 100
    txt:SetText(format("Speed: %.0f%%", pct))
    if pct > 100.5 then txt:SetTextColor(0.4, 1.0, 0.5)
    elseif pct < 99.5 then txt:SetTextColor(1.0, 0.5, 0.4)
    else txt:SetTextColor(0.9, 0.9, 0.9) end
end

local CRIT_DMG_GEAR = 5.5  -- ring enchant + gems crit damage % (static; edit to match gear)

local function SpellDesc(id)
    local f = (C_Spell and C_Spell.GetSpellDescription) or GetSpellDescription
    return f and f(id)
end

local function DiseaseCritPct(desc)
    if not desc then return nil end
    return tonumber((desc:lower():match("critical strike damage[^%d]-([%d%.]+)%%")))
end

local function CritDamageReadout(txt)
    local _, classFile = UnitClass("player")
    if classFile ~= "DEATHKNIGHT" then
        txt:SetText("Disease Crit: N/A")
        txt:SetTextColor(0.6, 0.6, 0.6)
        return
    end
    local mastery = DiseaseCritPct(SpellDesc(77515)) or 0
    local talent = (IsPlayerSpell and IsPlayerSpell(390166)) and (DiseaseCritPct(SpellDesc(390166)) or 0) or 0
    txt:SetText(format("Disease Crit: %.1f%%", 200 + mastery + talent + CRIT_DMG_GEAR))
    txt:SetTextColor(0.85, 0.7, 1.0)
end

local ssRestorer
local function ScreenshotNoUI()
    if InCombatLockdown() then
        print("|cffff8800CVarMaster:|r Can't hide the UI for a screenshot during combat.")
        return
    end
    UIParent:Hide()
    ssRestorer = ssRestorer or CreateFrame("Frame")
    local r, done = ssRestorer, false
    local function restore()
        if done then return end
        done = true
        r:UnregisterAllEvents()
        r:SetScript("OnEvent", nil)
        UIParent:Show()
        print("|cff00aaffCVarMaster:|r Screenshot taken (UI hidden)")
    end
    r:RegisterEvent("SCREENSHOT_SUCCEEDED")
    r:RegisterEvent("SCREENSHOT_FAILED")
    r:SetScript("OnEvent", restore)
    C_Timer.After(0.25, function() Screenshot() end)
    C_Timer.After(4, restore)
end

-- ===========================================================================
-- Scripts database — action descriptors organized by category
-- Each entry: { name, desc, kind, taint?, + one of run/toggle/param/preset, preview? }
-- kind: "action" (Run) | "info" (Show) | "preset" (Apply) | "toggle" | "param"
-- ===========================================================================
local SCRIPTS = {
    {
        category = "PvP & Arena",
        icon = "icon_combat",
        scripts = {
            {
                name = "PvP Performance",
                desc = "One-click competitive graphics/FPS floor (/reload to fully apply)",
                kind = "preset",
                reload = true,
                preset = {
                    { "graphicsQuality", 0 },
                    { "graphicsViewDistance", 0 },
                    { "graphicsEnvironmentDetail", 0 },
                    { "graphicsGroundClutter", 0 },
                    { "graphicsShadowQuality", 0 },
                    { "graphicsLiquidDetail", 0 },
                    { "graphicsParticleDensity", 1 },
                    { "graphicsSpellDensity", 0 },
                    { "graphicsTextureResolution", 0 },
                    { "graphicsSSAO", 0 },
                    { "graphicsOutlineMode", 0 },
                    { "graphicsComputeEffects", 1 },
                    { "graphicsDepthEffects", 1 },
                    { "farclip", 177 },
                    { "horizonStart", 40 },
                    { "horizonClip", 177 },
                    { "groundEffectDist", 40 },
                    { "groundEffectFade", 40 },
                    { "wmoDoodadDist", 80 },
                    { "wmoLodDist", 50 },
                    { "doodadLodScale", 50 },
                    { "lodObjectCullDist", 20 },
                    { "lodObjectCullSize", 35 },
                    { "lodObjectMinSize", 0 },
                    { "entityLodDist", 1 },
                    { "dynamicLod", 0 },
                    { "terrainMipLevel", 1 },
                    { "worldBaseMip", 2 },
                    { "particleDensity", 1 },
                    { "particleMTDensity", 1 },
                    { "particulatesEnabled", 0 },
                    { "spellClutter", 0 },
                    { "spellVisualDensityFilterSetting", 1 },
                    { "specular", 0 },
                    { "componentSpecular", 0 },
                    { "componentEmissive", 0 },
                    { "reflectionMode", 0 },
                    { "reflectionDownscale", 3 },
                    { "ssaoMagicNormals", 0 },
                    { "clusteredShading", 0 },
                    { "rippleDetail", 0 },
                    { "ffxGlow", 0 },
                    { "ffxDeath", 0 },
                    { "ffxNether", 0 },
                    { "showfootprintparticles", 0 },
                    { "ChromaEffectsEnable", 0 },
                    { "Outline", 0 },
                    { "emphasizeMySpellEffects", 0 },
                    { "shadowTextureSize", 512 },
                    { "volumeFog", 1 },
                    { "weatherDensity", 0 },
                    { "physicsLevel", 0 },
                    { "sunShafts", 0 },
                    { "waterDetail", 0 },
                    { "maxFPS", 380 },
                    { "maxFPSBk", 60 },
                    { "vsync", 0 },
                    { "gxMaxFrameLatency", 1 },
                    { "LowLatencyMode", 2 },
                    { "floatingCombatTextReactives_v2", 0 },
                    { "floatingCombatTextCombatHealingAbsorbSelf_v2", 0 },
                    { "floatingCombatTextCombatDamageAllAutos_v2", 0 },
                    { "floatingCombatTextPetSpellDamage_v2", 0 },
                    { "floatingCombatTextPetMeleeDamage_v2", 0 },
                    { "floatingCombatTextLowManaHealth_v2", 0 },
                    { "showSpenderFeedback", 0 },
                    { "showBuilderFeedback", 0 },
                },
                preview = "Competitive FPS floor from your Perf profile — compute/fog/depth kept ON; weather/physics/shafts/water off.",
            },
            {
                name = "Movement Speed",
                desc = "Live speed readout widget — click to toggle, right-click the widget to close",
                kind = "toggle",
                toggle = {
                    get = function() return widgets.Speed and widgets.Speed:IsShown() end,
                    set = function(on) ToggleWidget("Speed", -140, SpeedReadout, on) end,
                    onLabel = "Shown", offLabel = "Show",
                },
            },
            {
                name = "Disease Crit %",
                desc = "Effective disease crit damage (200% base + mastery + Plague Mastery + gear) — right-click widget to close",
                kind = "toggle",
                toggle = {
                    get = function() return widgets.Crit and widgets.Crit:IsShown() end,
                    set = function(on) ToggleWidget("Crit", -176, CritDamageReadout, on) end,
                    onLabel = "Shown", offLabel = "Show",
                },
            },
        },
    },
    {
        category = "Camera & Display",
        icon = "icon_camera",
        scripts = {
            {
                name = "Max Camera Distance",
                desc = "How far the camera can zoom out",
                kind = "param",
                param = {
                    min = 1.0, max = 2.6, step = 0.1, fmt = "%.1f",
                    get = function() return tonumber(GetCVar("cameraDistanceMaxZoomFactor")) end,
                    apply = function(v) SetCVarSafe("cameraDistanceMaxZoomFactor", string.format("%.1f", v)) end,
                },
            },
            {
                name = "View Distance (Far Clip)",
                desc = "How far terrain/objects render",
                kind = "param",
                param = {
                    min = 177, max = 2000, step = 100, fmt = "%d",
                    get = function() return tonumber(GetCVar("farclip")) end,
                    apply = function(v) SetCVarSafe("farclip", tostring(math.floor(v + 0.5))) end,
                },
            },
            {
                name = "Screenshot Quality",
                desc = "JPEG quality of screenshots (10 = best)",
                kind = "param",
                param = {
                    min = 1, max = 10, step = 1, fmt = "%d",
                    get = function() return tonumber(GetCVar("screenshotQuality")) end,
                    apply = function(v) SetCVarSafe("screenshotQuality", tostring(math.floor(v + 0.5))) end,
                },
            },
            {
                name = "Fullscreen Glow",
                desc = "Low-health screen glow effect",
                kind = "toggle",
                toggle = {
                    get = function() return GetCVar("ffxGlow") == "1" end,
                    set = function(on) SetCVarSafe("ffxGlow", on and 1 or 0) end,
                    onLabel = "On", offLabel = "Off",
                },
            },
            {
                name = "Screenshot (No UI)",
                desc = "Hides the UI, screenshots, restores when the capture completes",
                kind = "action",
                taint = true,
                run = ScreenshotNoUI,
                preview = "Hides UI -> Screenshot -> restores on capture complete (blocked in combat)",
            },
        },
    },
    {
        category = "Nameplates",
        icon = "icon_nameplates",
        scripts = {
            {
                name = "Nameplate Motion",
                desc = "Spread plates apart (easy to click) vs stack them (dense packs)",
                kind = "toggle",
                toggle = {
                    get = function() return GetCVar("nameplateMotion") == "1" end,
                    set = function(on) SetCVarSafe("nameplateMotion", on and 1 or 0) end,
                    onLabel = "Spread", offLabel = "Stack",
                },
            },
            {
                name = "Stack at Base (AoE)",
                desc = "Stacks nameplates at the unit base",
                kind = "toggle",
                toggle = {
                    get = function() return GetCVar("nameplateOtherAtBase") == "2" end,
                    set = function(on) SetCVarSafe("nameplateOtherAtBase", on and 2 or 0) end,
                    onLabel = "On", offLabel = "Off",
                },
            },
            {
                name = "Show All Nameplates",
                desc = "Forces all enemy nameplates visible",
                kind = "preset",
                preset = { { "nameplateShowAll", 1 }, { "nameplateShowEnemies", 1 } },
            },
        },
    },
    {
        category = "UI & Action Bars",
        icon = "icon_interface",
        scripts = {
            {
                name = "Auto-Add Spells to Bars",
                desc = "New spells auto-add to action bars",
                kind = "toggle",
                toggle = {
                    get = function() return GetCVar("AutoPushSpellToActionBar") == "1" end,
                    set = function(on) SetCVarSafe("AutoPushSpellToActionBar", on and 1 or 0) end,
                    onLabel = "On", offLabel = "Off",
                },
            },
            {
                name = "Compact Action Bars",
                desc = "Locks bars and hides hotkey text",
                kind = "action",
                run = function()
                    SetCVarSafe("lockActionBars", 1)
                    SetCVarSafe("showHotKeys", 0)
                    print("|cff00aaffCVarMaster:|r Bars locked, hotkeys hidden")
                end,
            },
        },
    },
    {
        category = "Item Level",
        icon = "icon_tooltips",
        scripts = {
            {
                name = "Item Level (Equipped)",
                desc = "Shows your current equipped item level",
                kind = "info",
                run = function()
                    local _, equipped = GetAverageItemLevel()
                    print("Equipped iLvl: " .. format("%.1f", equipped))
                end,
            },
            {
                name = "Item Level (Overall)",
                desc = "Shows your overall item level including bags",
                kind = "info",
                run = function()
                    local overall = GetAverageItemLevel()
                    print("Overall iLvl: " .. format("%.1f", overall))
                end,
            },
        },
    },
    {
        category = "Target Info",
        icon = "icon_targeting",
        scripts = {
            {
                name = "Target GUID",
                desc = "Shows target's unique GUID",
                kind = "info",
                run = function()
                    if UnitExists("target") then print("Target GUID: " .. UnitGUID("target")) else print("No target") end
                end,
            },
            {
                name = "NPC ID (Target)",
                desc = "Extracts NPC ID from target GUID",
                kind = "info",
                run = function()
                    if UnitExists("target") then
                        local g = UnitGUID("target")
                        local t, _, _, _, _, id = strsplit("-", g)
                        if t == "Creature" then print("NPC ID: " .. id) else print("Not an NPC") end
                    else
                        print("No target")
                    end
                end,
            },
            {
                name = "Target Location",
                desc = "Shows target's map position (if available)",
                kind = "info",
                run = function()
                    if UnitExists("target") then
                        local m = C_Map.GetBestMapForUnit("target")
                        if m then
                            local p = C_Map.GetPlayerMapPosition(m, "target")
                            if p then local x, y = p:GetXY(); print(format("Target pos: %.1f, %.1f", x * 100, y * 100))
                            else print("Position unavailable") end
                        else print("No map for target") end
                    else print("No target") end
                end,
            },
        },
    },
    {
        category = "Character Stats",
        icon = "icon_accessibility",
        scripts = {
            {
                name = "Current GCD",
                desc = "Shows your global cooldown in seconds",
                kind = "info",
                run = function()
                    local info = C_Spell.GetSpellCooldown(61304)
                    local g = (info and info.duration) or 0
                    print(format("|cff00aaffCurrent GCD:|r %.2fs", g))
                end,
            },
            {
                name = "Coordinates",
                desc = "Shows your exact map position",
                kind = "info",
                run = function()
                    local m = C_Map.GetBestMapForUnit("player")
                    if m then
                        local p = C_Map.GetPlayerMapPosition(m, "player")
                        if p then local x, y = p:GetXY(); print(format("|cff00aaffPosition:|r %.1f, %.1f", x * 100, y * 100)) end
                    end
                end,
            },
            {
                name = "Durability Check",
                desc = "Shows lowest durability item",
                kind = "info",
                run = function()
                    local lowest, slot = 100, "Unknown"
                    for i = 1, 18 do
                        local c, m = GetInventoryItemDurability(i)
                        if c and m and m > 0 then
                            local pct = c / m * 100
                            if pct < lowest then lowest = pct; slot = "Slot " .. i end
                        end
                    end
                    print(format("|cff00aaffLowest Durability:|r %s at %.0f%%", slot, lowest))
                end,
            },
            {
                name = "Gold Summary",
                desc = "Shows your current gold",
                kind = "info",
                run = function()
                    local g = GetMoney()
                    print(format("|cff00aaffGold:|r %dg %ds %dc", math.floor(g / 10000), math.floor((g % 10000) / 100), g % 100))
                end,
            },
        },
    },
    {
        category = "Performance",
        icon = "icon_performance",
        scripts = {
            {
                name = "Show FPS + Latency",
                desc = "Prints current FPS and network latency",
                kind = "info",
                run = function()
                    local fps = GetFramerate()
                    local _, _, home, world = GetNetStats()
                    print(format("|cff00aaffFPS:|r %.1f  |cff00aaffHome:|r %dms  |cff00aaffWorld:|r %dms", fps, home, world))
                end,
            },
            {
                name = "Total Addon Memory",
                desc = "Shows combined memory usage of all addons",
                kind = "info",
                run = function()
                    UpdateAddOnMemoryUsage()
                    local total = 0
                    for i = 1, C_AddOns.GetNumAddOns() do total = total + GetAddOnMemoryUsage(i) end
                    print(format("|cff00aaffTotal Addon Memory:|r %.1f MB", total / 1024))
                end,
            },
            {
                name = "Reduce Particle Density",
                desc = "Lowers spell effects for better FPS",
                kind = "action",
                run = function()
                    SetCVarSafe("particleDensity", 10)
                    print("|cff00aaffCVarMaster:|r Particle density set to low")
                end,
            },
        },
    },
    {
        category = "Chat & Social",
        icon = "icon_chat",
        scripts = {
            {
                name = "Clear Chat",
                desc = "Clears the default chat frame",
                kind = "action",
                run = function()
                    DEFAULT_CHAT_FRAME:Clear()
                    print("|cff00aaffCVarMaster:|r Chat cleared")
                end,
            },
            {
                name = "Chat Timestamps",
                desc = "HH:MM timestamps in chat",
                kind = "toggle",
                toggle = {
                    get = function() return GetCVar("showTimestamps") ~= "none" end,
                    set = function(on) SetCVarSafe("showTimestamps", on and "%H:%M " or "none") end,
                    onLabel = "On", offLabel = "Off",
                },
            },
        },
    },
    {
        category = "Weekly & Tracking",
        icon = "icon_new",
        scripts = {
            {
                name = "Vault Reward Check",
                desc = "Check if you've earned any Great Vault rewards",
                kind = "info",
                run = function()
                    C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
                    local earned = false
                    local activities = C_WeeklyRewards.GetActivities()
                    if activities then
                        for _, a in ipairs(activities) do
                            if a.progress and a.threshold and a.progress >= a.threshold then earned = true; break end
                        end
                    end
                    print(earned and "|cff00ff00Rewards Earned!|r" or "|cffff8800Not Yet|r")
                end,
            },
            {
                name = "Quest Watch Count",
                desc = "Shows how many quests are being tracked",
                kind = "info",
                run = function()
                    print("|cff00aaffQuests watched:|r " .. C_QuestLog.GetNumQuestWatches())
                end,
            },
            {
                name = "Weekly Reset Countdown",
                desc = "Shows time until weekly reset",
                kind = "info",
                run = function()
                    local s = C_DateAndTime.GetSecondsUntilWeeklyReset()
                    local d = math.floor(s / 86400); local h = math.floor((s % 86400) / 3600); local m = math.floor((s % 3600) / 60)
                    print(format("|cff00aaffWeekly Reset:|r %dd %dh %dm", d, h, m))
                end,
            },
        },
    },
    {
        category = "Professions",
        icon = "icon_other",
        scripts = {
            {
                name = "Open Professions Panel",
                desc = "Force-opens the professions UI",
                kind = "action",
                run = function()
                    C_AddOns.LoadAddOn("Blizzard_Professions")
                    if ProfessionsFrame then
                        ShowUIPanel(ProfessionsFrame)
                    else
                        print("|cffff8800CVarMaster:|r Professions UI unavailable")
                    end
                end,
            },
            {
                name = "Profession Skill Levels",
                desc = "Lists your profession skill levels",
                kind = "info",
                run = function()
                    local profs = { GetProfessions() }
                    for _, idx in ipairs(profs) do
                        if idx then
                            local name, _, rank, maxRank = GetProfessionInfo(idx)
                            print(format("|cff00aaff%s:|r %d / %d", name, rank, maxRank))
                        end
                    end
                end,
            },
        },
    },
    {
        category = "Utility",
        icon = "icon_scripts",
        scripts = {
            {
                name = "Instant Dungeon Reset",
                desc = "Resets current dungeon instance",
                kind = "action",
                run = function() ResetInstances(); print("|cff00aaffCVarMaster:|r Instances reset") end,
            },
            {
                name = "Stop Group Signup Sound",
                desc = "Kills the looping LFG eye animation sound",
                kind = "action",
                run = function()
                    local anim = QueueStatusButton and QueueStatusButton.EyeHighlightAnim
                    if anim then
                        anim:SetScript("OnLoop", nil)
                        print("|cff00aaffCVarMaster:|r LFG sound stopped")
                    else
                        print("|cffff8800CVarMaster:|r LFG eye not active")
                    end
                end,
            },
            {
                name = "Clear All World Markers",
                desc = "Removes all raid world markers",
                kind = "action",
                run = function()
                    for i = 1, 8 do ClearRaidMarker(i) end
                    print("|cff00aaffCVarMaster:|r World markers cleared")
                end,
            },
            {
                name = "Leave Party/Group",
                desc = "Instantly leaves current group",
                kind = "action",
                run = function() C_PartyInfo.LeaveParty(); print("|cff00aaffCVarMaster:|r Left group") end,
            },
        },
    },
    {
        category = "Debug & Dev",
        icon = "icon_scripts",
        scripts = {
            {
                name = "Reload UI",
                desc = "Reloads the user interface",
                kind = "action",
                run = function() ReloadUI() end,
            },
            {
                name = "Frame Stack Toggle",
                desc = "Toggle frame stack viewer for debugging",
                kind = "action",
                run = function()
                    C_AddOns.LoadAddOn("Blizzard_DebugTools")
                    FrameStackTooltip_Toggle()
                end,
            },
            {
                name = "GC Collect",
                desc = "Forces garbage collection",
                kind = "action",
                run = function()
                    collectgarbage("collect")
                    print("GC complete: " .. format("%.1f KB", collectgarbage("count")))
                end,
            },
            {
                name = "Addon Memory Usage",
                desc = "Lists top 10 addons by memory",
                kind = "info",
                run = function()
                    UpdateAddOnMemoryUsage()
                    local t = {}
                    for i = 1, C_AddOns.GetNumAddOns() do
                        local n = C_AddOns.GetAddOnInfo(i); local m = GetAddOnMemoryUsage(i)
                        if m > 0 then t[#t + 1] = { n = n, m = m } end
                    end
                    table.sort(t, function(a, b) return a.m > b.m end)
                    print("|cff00aaffTop 10 Addons by Memory:|r")
                    for i = 1, math.min(10, #t) do print(format("  %d. %s: %.1f KB", i, t[i].n, t[i].m)) end
                end,
            },
            {
                name = "Event Trace Toggle",
                desc = "Opens the event trace debugging tool (/etrace)",
                kind = "action",
                run = function()
                    local ok = pcall(function() SlashCmdList["EVENTTRACE"]("") end)
                    if not ok then print("|cffff8800CVarMaster:|r Event trace unavailable - try /etrace manually") end
                end,
            },
            {
                name = "All Logs OFF",
                desc = "Disables combat/chat/taint/script + every *EventLog CVar",
                kind = "action",
                run = function()
                    LoggingCombat(false); LoggingChat(false)
                    pcall(SetCVar, "taintLog", "0"); pcall(SetCVar, "scriptErrors", "0")
                    local ok, blocked = 0, 0
                    for _, c in ipairs({ "BeckonTriggerEventlog", "ServerMessageEventLog", "CustomWindowEventLog", "AIControllerEventLog", "CustomDesignEventLog", "AreaTriggerEventLog", "debugGameEvents", "WorldActionsLog", "HotfixEventLog", "AIEventLog", "MoveHistoryEventLog", "SpellScriptEventLog", "UnitEnterCombatLog", "ProcDebugEventLog" }) do
                        pcall(SetCVar, c, "0")
                        if GetCVar(c) ~= "0" then pcall(ConsoleExec, c .. " 0") end
                        if GetCVar(c) == "0" then ok = ok + 1 else blocked = blocked + 1 end
                    end
                    print(string.format("|cff00aaffCVarMaster:|r Logs OFF (combat/chat/taint/script done; %d EventLog set, %d genuinely restricted)", ok, blocked))
                end,
            },
            {
                name = "All Logs ON",
                desc = "Enables combat/chat/taint(1)/script + every *EventLog CVar",
                kind = "action",
                run = function()
                    LoggingCombat(true); LoggingChat(true)
                    pcall(SetCVar, "taintLog", "1"); pcall(SetCVar, "scriptErrors", "1")
                    local ok, blocked = 0, 0
                    for _, c in ipairs({ "BeckonTriggerEventlog", "ServerMessageEventLog", "CustomWindowEventLog", "AIControllerEventLog", "CustomDesignEventLog", "AreaTriggerEventLog", "debugGameEvents", "WorldActionsLog", "HotfixEventLog", "AIEventLog", "MoveHistoryEventLog", "SpellScriptEventLog", "UnitEnterCombatLog", "ProcDebugEventLog" }) do
                        pcall(SetCVar, c, "1")
                        if GetCVar(c) ~= "1" then pcall(ConsoleExec, c .. " 1") end
                        if GetCVar(c) == "1" then ok = ok + 1 else blocked = blocked + 1 end
                    end
                    print(string.format("|cff00aaffCVarMaster:|r Logs ON (combat/chat/taint/script done; %d EventLog set, %d genuinely restricted)", ok, blocked))
                end,
            },
        },
    },
}

local ScriptsWindow = nil

function GUI:ShowScriptsWindow()
    if ScriptsWindow then

    -- Inherit scale/alpha from main window
    local mainWin = GUI:GetMainWindow()
    if mainWin then
        ScriptsWindow:SetScale(mainWin:GetScale())
    end
    GUI:ApplySpecBackground(ScriptsWindow)
    ScriptsWindow:Show()
        return
    end

    -- Create scripts window
    ScriptsWindow = GUI:CreateNihilumFrame("CVarMasterScriptsWindow", UIParent, false)
    ScriptsWindow:SetSize(450, 500)
    ScriptsWindow:SetClipsChildren(true)
    ScriptsWindow:SetPoint("CENTER")
    ScriptsWindow:SetMovable(true)
    ScriptsWindow:EnableMouse(true)
    ScriptsWindow:RegisterForDrag("LeftButton")
    ScriptsWindow:SetScript("OnDragStart", ScriptsWindow.StartMoving)
    ScriptsWindow:SetScript("OnDragStop", ScriptsWindow.StopMovingOrSizing)
    ScriptsWindow:SetFrameStrata("DIALOG")

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, ScriptsWindow)
    titleBar:SetHeight(32)
    titleBar:SetPoint("TOPLEFT", 4, -4)
    titleBar:SetPoint("TOPRIGHT", -4, -4)

    titleBar.accentLine = titleBar:CreateTexture(nil, "ARTWORK")
    titleBar.accentLine:SetHeight(1)
    titleBar.accentLine:SetPoint("BOTTOMLEFT", 0, 0)
    titleBar.accentLine:SetPoint("BOTTOMRIGHT", 0, 0)
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(titleBar.accentLine, 0.4) end
    GUI.DisableSharpening(titleBar.accentLine)

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 12, 0)
        local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(20, 20)
    titleIcon:SetPoint("LEFT", 12, 0)
    titleIcon:SetTexture("Interface\\AddOns\\CVarMaster\\Textures\\icon_scripts")
    titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    title:ClearAllPoints()
    title:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
    title:SetText("Diagnostic Scripts")
    title:SetTextColor(0.85, 0.85, 0.90, 1)

    local closeBtn = GUI:CreateButton(nil, titleBar, "X", 26, 26)
    closeBtn:SetPoint("RIGHT", -4, 0)
    closeBtn:SetScript("OnClick", function() ScriptsWindow:Hide() end)

    -- Content scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, ScriptsWindow, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(math.max(300, scrollFrame:GetWidth() > 0 and scrollFrame:GetWidth() or 404))
    scrollFrame:SetScrollChild(content)
    scrollFrame:SetScript("OnSizeChanged", function(_, w)
        content:SetWidth(math.max(300, w or 300))
    end)

    -- Build collapsible script drawers
    local allDrawers = {}
    local toggleRefreshers = {}  -- re-read toggle state on (re)show
    local paramRefreshers = {}   -- re-read param values on (re)show
    local ROW_H = 44
    local HEADER_H = 30

    local function DrawerBodyHeight(scripts)
        return #scripts * ROW_H
    end

    local function RelayoutAll()
        local y = 0
        for _, drawer in ipairs(allDrawers) do
            drawer.header:ClearAllPoints()
            drawer.header:SetPoint("TOPLEFT", 0, -y)
            drawer.header:SetPoint("TOPRIGHT", 0, -y)
            y = y + HEADER_H
            if drawer.expanded then
                drawer.body:Show()
                drawer.body:ClearAllPoints()
                drawer.body:SetPoint("TOPLEFT", 0, -y)
                drawer.body:SetPoint("TOPRIGHT", 0, -y)
                drawer.body:SetHeight(DrawerBodyHeight(drawer.scripts))
                y = y + DrawerBodyHeight(drawer.scripts)
            else
                drawer.body:Hide()
            end
            y = y + 4 -- gap between categories
        end
        content:SetHeight(y + 20)
    end

    for ci, category in ipairs(SCRIPTS) do
        local drawer = { scripts = category.scripts, expanded = (ci == 1) }

        -- Category header (clickable)
        local header = CreateFrame("Button", nil, content)
        header:SetHeight(HEADER_H)
        drawer.header = header

        -- Header background
        local hBg = header:CreateTexture(nil, "BACKGROUND")
        hBg:SetAllPoints()
        hBg:SetColorTexture(0.10, 0.10, 0.12, 0.7)
        GUI.DisableSharpening(hBg)

        -- Arrow indicator
        local arrow = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        arrow:SetPoint("LEFT", 8, 0)
        arrow:SetTextColor(T("TEXT_MUTED"))
        drawer.arrow = arrow

        -- Category icon
        if category.icon then
            local catIcon = header:CreateTexture(nil, "ARTWORK")
            catIcon:SetSize(16, 16)
            catIcon:SetPoint("LEFT", 22, 0)
            catIcon:SetTexture("Interface\\AddOns\\CVarMaster\\Textures\\" .. category.icon)
            catIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        -- Category name + count
        local catName = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        catName:SetPoint("LEFT", category.icon and 44 or 22, 0)
        catName:SetText(category.category)
        catName:SetTextColor(T("TEXT_PRIMARY"))

        local catCount = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        catCount:SetPoint("LEFT", catName, "RIGHT", 6, 0)
        catCount:SetText("|cff888888(" .. #category.scripts .. ")|r")

        -- Bottom accent line
        local hLine = header:CreateTexture(nil, "ARTWORK")
        hLine:SetHeight(1)
        hLine:SetPoint("BOTTOMLEFT", 12, 0)
        hLine:SetPoint("BOTTOMRIGHT", -12, 0)
        if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(hLine, 0.15) end
        if GUI.DisableSharpening then GUI.DisableSharpening(hLine) end

        -- Hover effects
        header:SetScript("OnEnter", function()
            hBg:SetColorTexture(0.14, 0.14, 0.17, 0.8)
            catName:SetTextColor(T("TEXT_ACCENT"))
        end)
        header:SetScript("OnLeave", function()
            hBg:SetColorTexture(0.10, 0.10, 0.12, 0.7)
            catName:SetTextColor(T("TEXT_PRIMARY"))
        end)

        -- Script rows container
        local body = CreateFrame("Frame", nil, content)
        body:SetHeight(DrawerBodyHeight(category.scripts))
        drawer.body = body

        -- Build script rows inside body
        local rowY = 0
        for si, script in ipairs(category.scripts) do
            local rh = ROW_H
            local row = CreateFrame("Frame", nil, body)
            row:SetHeight(rh)
            row:SetPoint("TOPLEFT", 0, -rowY)
            row:SetPoint("TOPRIGHT", 0, -rowY)
            rowY = rowY + rh

            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            local alt = (si % 2 == 0) and 0.04 or 0.06
            row.bg:SetColorTexture(alt, alt, alt + 0.02, 0.5)
            GUI.DisableSharpening(row.bg)

            -- Script name
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", 14, -5)
            nameText:SetText(script.name)
            nameText:SetTextColor(T("TEXT_ACCENT"))

            -- Combat/taint indicator
            if script.taint then
                local dot = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                dot:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
                dot:SetText("|cffffaa00*|r")
            end

            local kind = script.kind or "action"

            -- Description
            local descText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            descText:SetPoint("TOPLEFT", 14, -21)
            descText:SetPoint("RIGHT", (kind == "param") and -118 or -90, 0)
            descText:SetText(script.desc or "")
            descText:SetTextColor(T("TEXT_SECONDARY"))
            descText:SetJustifyH("LEFT")
            descText:SetWordWrap(false)

            if kind == "toggle" then
                local tg = script.toggle
                local pill = GUI:CreateButton(nil, row, "", 64, 22)
                pill:SetPoint("RIGHT", -8, 0)
                local function refresh()
                    local on = false
                    local ok, res = pcall(tg.get)
                    if ok then on = res end
                    pill.text:SetText(on and (tg.onLabel or "On") or (tg.offLabel or "Off"))
                    if on then pill.text:SetTextColor(0.45, 1.0, 0.55, 1) else pill.text:SetTextColor(0.75, 0.75, 0.78, 1) end
                end
                refresh()
                toggleRefreshers[#toggleRefreshers + 1] = refresh
                pill:SetScript("OnClick", function()
                    if script.taint and InCombatLockdown() then BlockedByCombat(script.name); return end
                    local ok, err = pcall(function() tg.set(not tg.get()) end)
                    if not ok then print("|cffff0000CVarMaster:|r " .. tostring(err)) end
                    refresh()
                end)

            elseif kind == "param" then
                local pm = script.param
                local function fmtVal(v)
                    if (pm.fmt or "%.1f") == "%d" then return string.format("%d", math.floor(v + 0.5)) end
                    return string.format(pm.fmt or "%.1f", v)
                end

                local cur = tonumber(pm.get and select(2, pcall(pm.get))) or pm.default or pm.min
                cur = math.max(pm.min, math.min(pm.max, cur))

                local plus = GUI:CreateButton(nil, row, "+", 24, 22)
                plus:SetPoint("RIGHT", -8, 0)

                local valText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                valText:SetPoint("RIGHT", plus, "LEFT", -6, 0)
                valText:SetWidth(46)
                valText:SetJustifyH("CENTER")
                valText:SetTextColor(T("TEXT_ACCENT"))
                valText:SetText(fmtVal(cur))

                local minus = GUI:CreateButton(nil, row, "-", 24, 22)
                minus:SetPoint("RIGHT", valText, "LEFT", -6, 0)

                paramRefreshers[#paramRefreshers + 1] = function()
                    local v = tonumber(select(2, pcall(pm.get)))
                    if v then
                        cur = math.max(pm.min, math.min(pm.max, v))
                        valText:SetText(fmtVal(cur))
                    end
                end

                local function step(delta)
                    cur = math.max(pm.min, math.min(pm.max, cur + delta))
                    valText:SetText(fmtVal(cur))
                    if script.taint and InCombatLockdown() then BlockedByCombat(script.name); return end
                    local ok, err = pcall(pm.apply, cur)
                    if not ok then print("|cffff0000CVarMaster:|r " .. tostring(err)) end
                end
                minus:SetScript("OnClick", function() step(-pm.step) end)
                plus:SetScript("OnClick", function() step(pm.step) end)

            else
                -- action / info / preset
                local label = (kind == "preset" and "Apply") or (kind == "info" and "Show") or "Run"
                local btn = GUI:CreateButton(nil, row, label, 55, 22)
                btn:SetPoint("RIGHT", -8, 0)
                btn:SetScript("OnClick", function()
                    if script.taint and InCombatLockdown() then BlockedByCombat(script.name); return end
                    if kind == "preset" then
                        local ok, err = pcall(ApplyPreset, script.name, script.preset, script.reload)
                        if not ok then print("|cffff0000CVarMaster:|r " .. tostring(err)) end
                    else
                        local ok, err = pcall(script.run)
                        if not ok then print("|cffff0000CVarMaster:|r Script error: " .. tostring(err)) end
                    end
                end)
                btn:HookScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(label .. ": " .. script.name, 0.5, 1.0, 0.6)
                    if kind == "preset" and script.preset then
                        if script.preview then GameTooltip:AddLine(script.preview, 0.55, 0.55, 0.6, true) end
                        local n = #script.preset
                        local cap = 12
                        for i = 1, math.min(cap, n) do
                            local pr = script.preset[i]
                            GameTooltip:AddLine(pr[1] .. " = " .. tostring(pr[2]), 0.6, 0.6, 0.6)
                        end
                        if n > cap then GameTooltip:AddLine(string.format("…and %d more", n - cap), 0.5, 0.5, 0.5) end
                    elseif script.preview then
                        GameTooltip:AddLine(script.preview, 0.5, 0.5, 0.5, true)
                    end
                    if script.taint then GameTooltip:AddLine("Disabled during combat", 1.0, 0.6, 0.4) end
                    GameTooltip:Show()
                end)
                btn:HookScript("OnLeave", function() GameTooltip:Hide() end)
            end

            -- Row hover
            row:SetScript("OnEnter", function(self)
                self.bg:SetColorTexture(0.12, 0.12, 0.14, 0.7)
            end)
            row:SetScript("OnLeave", function(self)
                local a = (si % 2 == 0) and 0.04 or 0.06
                self.bg:SetColorTexture(a, a, a + 0.02, 0.5)
            end)
        end

        -- Toggle drawer
        header:SetScript("OnClick", function()
            drawer.expanded = not drawer.expanded
            RelayoutAll()
            -- Update arrows
            for _, d in ipairs(allDrawers) do
                d.arrow:SetText(d.expanded and "v" or ">")
            end
        end)

        arrow:SetText(drawer.expanded and "v" or ">")
        table.insert(allDrawers, drawer)
    end

    -- Re-sync toggle pills and param values with live CVar state whenever the window is shown
    ScriptsWindow.RefreshToggles = function()
        for _, fn in ipairs(toggleRefreshers) do pcall(fn) end
        for _, fn in ipairs(paramRefreshers) do pcall(fn) end
    end
    ScriptsWindow:HookScript("OnShow", ScriptsWindow.RefreshToggles)

    -- Initial layout
    RelayoutAll()

    -- Inherit scale/alpha from main window
    local mainWin = GUI:GetMainWindow()
    if mainWin then
        ScriptsWindow:SetScale(mainWin:GetScale())
    end
    GUI:AddResizeHandle(ScriptsWindow, 350, 300, 650, 700)
    GUI:ApplySpecBackground(ScriptsWindow)
    ScriptsWindow:Show()
end
