---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local C = CVarMaster.Constants

-- Use shared theme/spacing helpers from Framework
local T = GUI.GetThemeColor
local S = GUI.GetSpacing

-- Scripts database organized by category
local SCRIPTS = {
    {
        category = "Utility & Combat",
        icon = "icon_combat",
        scripts = {
            {
                name = "Instant Dungeon Reset",
                desc = "Resets current dungeon instance",
                script = [[ResetInstances(); print("|cff00aaffCVarMaster:|r Instances reset")]],
            },

            {
                name = "Stop Group Signup Sound",
                desc = "Kills the looping LFG eye animation sound",
                script = [[QueueStatusMinimapButton.EyeHighlightAnim:SetScript("OnLoop", nil); print("|cff00aaffCVarMaster:|r LFG sound stopped")]],
            },
            {
                name = "Clear All World Markers",
                desc = "Removes all raid world markers",
                script = [[for i = 1, 8 do ClearRaidMarker(i) end; print("|cff00aaffCVarMaster:|r World markers cleared")]],
            },
            {
                name = "Leave Party/Group",
                desc = "Instantly leaves current group",
                script = [[LeaveParty(); print("|cff00aaffCVarMaster:|r Left group")]],
            },
        },
    },
    {
        category = "Camera & Display",
        icon = "icon_camera",
        scripts = {
            {
                name = "Max Camera Distance",
                desc = "Sets camera zoom to maximum distance",
                script = [[SetCVar("cameraDistanceMaxZoomFactor", 2.6); print("|cff00aaffCVarMaster:|r Camera max zoom set to 2.6")]],
            },
            {
                name = "Remove Fullscreen Glow",
                desc = "Disables low-health screen glow effect",
                script = [[SetCVar("ffxGlow", 0); print("|cff00aaffCVarMaster:|r Fullscreen glow disabled")]],
            },
            {
                name = "Increase View Distance",
                desc = "Sets far clip to maximum (1600)",
                script = [[SetCVar("farclip", 1600); print("|cff00aaffCVarMaster:|r Far clip set to 1600")]],
            },
            {
                name = "Screenshot (No UI)",
                desc = "Takes a screenshot with UI hidden",
                script = [[SetCVar("screenshotQuality", 10); Screenshot(); print("|cff00aaffCVarMaster:|r Screenshot taken")]],
            },
        },
    },
    {
        category = "Nameplates",
        icon = "icon_nameplates",
        scripts = {
            {
                name = "Nameplate Stacking Mode",
                desc = "Stacks nameplates at unit base (AoE friendly)",
                script = [[SetCVar("nameplateOtherAtBase", 2); print("|cff00aaffCVarMaster:|r Nameplates stacking at base")]],
            },
            {
                name = "Nameplates: Free Stack",
                desc = "Nameplates pile up naturally (better for dense packs)",
                script = [[SetCVar("nameplateMotion", 0); print("|cff00aaffCVarMaster:|r Nameplates free-stacking")]],
            },
            {
                name = "Nameplates: Spread Apart",
                desc = "Nameplates push away from each other (easier to click)",
                script = [[SetCVar("nameplateMotion", 1); print("|cff00aaffCVarMaster:|r Nameplates spreading")]],
            },
            {
                name = "Show All Nameplates",
                desc = "Forces all nameplates visible",
                script = [[SetCVar("nameplateShowAll", 1); SetCVar("nameplateShowEnemies", 1); print("|cff00aaffCVarMaster:|r All nameplates shown")]],
            },
        },
    },
    {
        category = "UI & Action Bars",
        icon = "icon_interface",
        scripts = {
            {
                name = "Disable Auto-Add Spells",
                desc = "Stops new spells auto-adding to action bars",
                script = [[SetCVar("AutoPushSpellToActionBar", 0); print("|cff00aaffCVarMaster:|r Auto-push spells disabled")]],
            },
            {
                name = "Enable Auto-Add Spells",
                desc = "Re-enables auto-adding spells to bars",
                script = [[SetCVar("AutoPushSpellToActionBar", 1); print("|cff00aaffCVarMaster:|r Auto-push spells enabled")]],
            },
            {
                name = "Compact Action Bars",
                desc = "Hides macro names and hotkey text on bars",
                script = [[LOCK_ACTIONBAR = 1; SetCVar("lockActionBars", 1); SetCVar("showHotKeys", 0); print("|cff00aaffCVarMaster:|r Bars locked, hotkeys hidden")]],
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
                script = [[local _, equipped = GetAverageItemLevel(); print("Equipped iLvl: "..format("%.1f", equipped))]],
            },
            {
                name = "Item Level (Overall)",
                desc = "Shows your overall item level including bags",
                script = [[local overall = GetAverageItemLevel(); print("Overall iLvl: "..format("%.1f", overall))]],
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
                script = [[if UnitExists("target") then print("Target GUID: "..UnitGUID("target")) else print("No target") end]],
            },
            {
                name = "NPC ID (Target)",
                desc = "Extracts NPC ID from target GUID",
                script = [[if UnitExists("target") then local g=UnitGUID("target"); local t,_,_,_,_,id=strsplit("-",g); if t=="Creature" then print("NPC ID: "..id) else print("Not an NPC") end else print("No target") end]],
            },
            {
                name = "Target Location",
                desc = "Shows target's map position (if available)",
                script = [[if UnitExists("target") then local m=C_Map.GetBestMapForUnit("target"); if m then local p=C_Map.GetPlayerMapPosition(m,"target"); if p then local x,y=p:GetXY(); print(format("Target pos: %.1f, %.1f", x*100, y*100)) else print("Position unavailable") end else print("No map for target") end else print("No target") end]],
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
                script = [[ReloadUI()]],
            },
            {
                name = "Frame Stack Toggle",
                desc = "Toggle frame stack viewer for debugging",
                script = [[FrameStackTooltip_Toggle()]],
            },
            {
                name = "GC Collect",
                desc = "Forces garbage collection",
                script = [[collectgarbage("collect"); print("GC complete: "..format("%.1f KB", collectgarbage("count")))]],
            },
            {
                name = "Addon Memory Usage",
                desc = "Lists top 10 addons by memory",
                script = [[UpdateAddOnMemoryUsage(); local t={}; for i=1,C_AddOns.GetNumAddOns() do local n=C_AddOns.GetAddOnInfo(i); local m=GetAddOnMemoryUsage(i); if m>0 then t[#t+1]={n=n,m=m} end end; table.sort(t,function(a,b) return a.m>b.m end); print("|cff00aaffTop 10 Addons by Memory:|r"); for i=1,math.min(10,#t) do print(format("  %d. %s: %.1f KB", i, t[i].n, t[i].m)) end]],
            },
            {
                name = "Event Trace Toggle",
                desc = "Opens the event trace debugging tool (/etrace)",
                script = [[local ok, err = pcall(function() SlashCmdList["EVENTTRACE"]("") end); if not ok then print("|cffff8800CVarMaster:|r Event trace unavailable - try /etrace manually") end]],
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
                script = [[DEFAULT_CHAT_FRAME:Clear(); print("|cff00aaffCVarMaster:|r Chat cleared")]],
            },
            {
                name = "Chat Timestamps",
                desc = "Enables HH:MM timestamps in chat",
                script = [[SetCVar("showTimestamps", "6"); print("|cff00aaffCVarMaster:|r Chat timestamps enabled (HH:MM)")]],
            },
            {
                name = "Disable Chat Timestamps",
                desc = "Removes timestamps from chat",
                script = [[SetCVar("showTimestamps", "none"); print("|cff00aaffCVarMaster:|r Chat timestamps disabled")]],
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
                script = [[local fps = GetFramerate(); local _, _, home, world = GetNetStats(); print(format("|cff00aaffFPS:|r %.1f  |cff00aaffHome:|r %dms  |cff00aaffWorld:|r %dms", fps, home, world))]],
            },
            {
                name = "Total Addon Memory",
                desc = "Shows combined memory usage of all addons",
                script = [[UpdateAddOnMemoryUsage(); local total=0; for i=1,C_AddOns.GetNumAddOns() do total=total+GetAddOnMemoryUsage(i) end; print(format("|cff00aaffTotal Addon Memory:|r %.1f MB", total/1024))]],
            },
            {
                name = "Reduce Particle Density",
                desc = "Lowers spell effects for better FPS",
                script = [[SetCVar("particleDensity", 10); print("|cff00aaffCVarMaster:|r Particle density set to low")]],
            },
        },
    },
    {
        category = "Weekly & Tracking",
        icon = "icon_new",
        scripts = {
            {
                name = "Vault Reward Check",
                desc = "Check if Great Vault has a pending reward",
                script = [[C_AddOns.LoadAddOn("Blizzard_WeeklyRewards"); print(C_WeeklyRewards.HasAvailableRewards() and "|cff00ff00Vault Ready!|r" or "|cffff8800No Reward Yet|r")]],
            },
            {
                name = "Quest Watch Count",
                desc = "Shows how many quests are being tracked",
                script = [[print("|cff00aaffQuests watched:|r " .. C_QuestLog.GetNumQuestWatches())]],
            },
            {
                name = "Check Quest Completion",
                desc = "Check if a quest ID has been completed (edit ID)",
                script = [[local id = 0; if id == 0 then print("|cffff8800Edit script: replace 0 with quest ID|r") else print("Quest "..id..": "..(C_QuestLog.IsQuestFlaggedCompleted(id) and "|cffff0000Done|r" or "|cff00ff00Available|r")) end]],
            },
            {
                name = "Weekly Reset Countdown",
                desc = "Shows time until weekly reset",
                script = [[local s = C_DateAndTime.GetSecondsUntilWeeklyReset(); local d = math.floor(s/86400); local h = math.floor((s%86400)/3600); local m = math.floor((s%3600)/60); print(format("|cff00aaffWeekly Reset:|r %dd %dh %dm", d, h, m))]],
            },
        },
    },
    {
        category = "Character Stats",
        icon = "icon_accessibility",
        scripts = {
            {
                name = "Movement Speed",
                desc = "Shows exact movement speed percentage",
                script = [[print(format("|cff00aaffCurrent Speed:|r %.1f%%", GetUnitSpeed("player") / 7 * 100))]],
            },
            {
                name = "Current GCD",
                desc = "Shows your global cooldown in seconds",
                script = [[local _, g = GetSpellCooldown(61304); print(format("|cff00aaffCurrent GCD:|r %.2fs", g or 0))]],
            },
            {
                name = "Coordinates",
                desc = "Shows your exact map position",
                script = [[local m = C_Map.GetBestMapForUnit("player"); if m then local p = C_Map.GetPlayerMapPosition(m, "player"); if p then local x,y = p:GetXY(); print(format("|cff00aaffPosition:|r %.1f, %.1f", x*100, y*100)) end end]],
            },
            {
                name = "Durability Check",
                desc = "Shows lowest durability item",
                script = [=[local lowest, slot = 100, "Unknown"; for i=1,18 do local c,m = GetInventoryItemDurability(i); if c and m and m > 0 then local pct = c/m*100; if pct < lowest then lowest = pct; slot = "Slot "..i end end end; print(format("|cff00aaffLowest Durability:|r %s at %.0f%%", slot, lowest))]=],
            },
            {
                name = "Gold Summary",
                desc = "Shows your current gold across the character",
                script = [[local g = GetMoney(); print(format("|cff00aaffGold:|r %dg %ds %dc", math.floor(g/10000), math.floor((g%10000)/100), g%100))]],
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
                script = [[C_AddOns.LoadAddOn("Blizzard_Professions"); ProfessionsFrame:Show()]],
            },
            {
                name = "Profession Skill Levels",
                desc = "Lists your profession skill levels",
                script = [[local profs = {GetProfessions()}; for _, idx in ipairs(profs) do if idx then local name, _, rank, maxRank = GetProfessionInfo(idx); print(format("|cff00aaff%s:|r %d / %d", name, rank, maxRank)) end end]],
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
    titleBar.accentLine:SetColorTexture(T("ACCENT_PRIMARY"))
    titleBar.accentLine:SetAlpha(0.4)
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
    content:SetWidth(404) -- 450 window - 8 left - 28 right/scrollbar - 10 pad
    scrollFrame:SetScrollChild(content)

    -- Build collapsible script drawers
    local allDrawers = {}
    local ROW_H = 44
    local HEADER_H = 30

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
                drawer.body:SetHeight(#drawer.scripts * ROW_H)
                y = y + (#drawer.scripts * ROW_H)
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
        hBg:SetColorTexture(0.10, 0.09, 0.15, 0.7)
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
            hBg:SetColorTexture(0.14, 0.12, 0.22, 0.8)
            catName:SetTextColor(T("TEXT_ACCENT"))
        end)
        header:SetScript("OnLeave", function()
            hBg:SetColorTexture(0.10, 0.09, 0.15, 0.7)
            catName:SetTextColor(T("TEXT_PRIMARY"))
        end)

        -- Script rows container
        local body = CreateFrame("Frame", nil, content)
        body:SetHeight(#category.scripts * ROW_H)
        drawer.body = body

        -- Build script rows inside body
        for si, script in ipairs(category.scripts) do
            local row = CreateFrame("Frame", nil, body)
            row:SetHeight(ROW_H)
            row:SetPoint("TOPLEFT", 0, -((si - 1) * ROW_H))
            row:SetPoint("TOPRIGHT", 0, -((si - 1) * ROW_H))

            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            local alt = (si % 2 == 0) and 0.04 or 0.06
            row.bg:SetColorTexture(alt, alt - 0.01, alt + 0.04, 0.5)
            GUI.DisableSharpening(row.bg)

            -- Script name
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", 14, -5)
            nameText:SetText(script.name)
            nameText:SetTextColor(T("TEXT_ACCENT"))

            -- Description
            local descText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            descText:SetPoint("TOPLEFT", 14, -21)
            descText:SetPoint("RIGHT", -80, 0)
            descText:SetText(script.desc)
            descText:SetTextColor(T("TEXT_SECONDARY"))
            descText:SetJustifyH("LEFT")
            descText:SetWordWrap(false)

            -- Run button
            local runBtn = GUI:CreateButton(nil, row, "Run", 55, 22)
            runBtn:SetPoint("RIGHT", -8, 0)
            runBtn:SetScript("OnClick", function()
                local success, err = pcall(function() RunScript(script.script) end)
                if not success then
                    print("|cffff0000CVarMaster:|r Script error: " .. tostring(err))
                end
            end)
            runBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Run: " .. script.name, 0.5, 1.0, 0.6)
                GameTooltip:AddLine(script.script, 0.5, 0.5, 0.5, true)
                GameTooltip:Show()
            end)
            runBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            -- Row hover
            row:SetScript("OnEnter", function(self)
                self.bg:SetColorTexture(0.12, 0.10, 0.18, 0.7)
            end)
            row:SetScript("OnLeave", function(self)
                local a = (si % 2 == 0) and 0.04 or 0.06
                self.bg:SetColorTexture(a, a - 0.01, a + 0.04, 0.5)
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
