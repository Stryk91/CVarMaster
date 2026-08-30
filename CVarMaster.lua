---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

SLASH_CVARMASTER1 = "/cvarmaster"
SLASH_CVARMASTER2 = "/cvm"

SlashCmdList["CVARMASTER"] = function(msg)
    local args = {}
    for word in (msg or ""):gmatch("%S+") do
        table.insert(args, word)
    end

    local cmd = (args[1] or ""):lower()

    if cmd == "" or cmd == "show" or cmd == "open" then
        if CVarMaster.GUI and CVarMaster.GUI.Show then
            CVarMaster.GUI:Show()
        else
            print("|cffff0000CVarMaster:|r GUI not available!")
        end
    elseif cmd == "scan" then
        if CVarMaster.CVarScanner then
            local count = CVarMaster.CVarScanner:RefreshCache()
            print("|cff00aaffCVarMaster:|r Scanned " .. (count or 0) .. " CVars")
        end

    elseif cmd == "search" or cmd == "find" then
        local term = args[2]
        if not term or term == "" then
            print("|cffff0000CVarMaster:|r Usage: /cvm search <term>")
        elseif CVarMaster.CVarScanner then
            local results = CVarMaster.CVarScanner:Search(term)
            local count = 0
            print("|cff00aaffCVarMaster:|r Search results for '" .. term .. "':")
            for name, data in pairs(results) do
                local modified = data.isModified and "|cffffaa00*|r" or ""
                print("  " .. modified .. "|cff88ff88" .. name .. "|r = " .. data.value)
                count = count + 1
                if count >= 20 then
                    print("  |cff888888... and more (use GUI for full list)|r")
                    break
                end
            end
            if count == 0 then
                print("  |cff888888No results found|r")
            end
        end

    elseif cmd == "get" then
        local cvarName = args[2]
        if not cvarName or cvarName == "" then
            print("|cffff0000CVarMaster:|r Usage: /cvm get <cvarName>")
        elseif CVarMaster.CVarScanner then
            local data = CVarMaster.CVarScanner:GetCVarData(cvarName)
            if data then
                print("|cff00aaffCVarMaster:|r CVar Details:")
                print("  Name: |cff88ff88" .. data.name .. "|r")
                if data.friendlyName then
                    print("  Friendly: " .. data.friendlyName)
                end
                print("  Value: |cffffff00" .. data.value .. "|r")
                print("  Default: " .. (data.defaultValue or "?"))
                print("  Modified: " .. (data.isModified and "|cffff0000Yes|r" or "|cff00ff00No|r"))
                print("  Category: " .. (data.category or "Unknown"))
                print("  Type: " .. (data.dataType or "string"))
                if data.description then
                    print("  Description: " .. data.description)
                end
            else
                print("|cffff0000CVarMaster:|r CVar not found: " .. cvarName)
            end
        end

    elseif cmd == "set" then
        local cvarName = args[2]
        local value
        if args[3] then
            local valueParts = {}
            for i = 3, #args do
                table.insert(valueParts, args[i])
            end
            value = table.concat(valueParts, " ")
        end
        if not cvarName or cvarName == "" or not value then
            print("|cffff0000CVarMaster:|r Usage: /cvm set <cvarName> <value>")
        elseif CVarMaster.CVarManager then
            CVarMaster.CVarManager:SetCVar(cvarName, value)
        end

    elseif cmd == "reset" then
        local target = args[2]
        if not target or target == "" then
            print("|cffff0000CVarMaster:|r Usage: /cvm reset <cvarName|all>")
        elseif target:lower() == "all" then
            if CVarMaster.CVarManager then
                CVarMaster.CVarManager:ResetAll()
            end
        elseif CVarMaster.CVarManager then
            CVarMaster.CVarManager:ResetCVar(target)
        end

    elseif cmd == "modified" or cmd == "mod" then
        if CVarMaster.CVarScanner then
            local modified = CVarMaster.CVarScanner:FilterModified()
            local count = 0
            print("|cff00aaffCVarMaster:|r Modified CVars:")
            for name, data in pairs(modified) do
                print("  |cff88ff88" .. name .. "|r: |cffffff00" .. data.value .. "|r (default: " .. (data.defaultValue or "?") .. ")")
                count = count + 1
            end
            if count == 0 then
                print("  |cff888888No modified CVars|r")
            else
                print("  |cff888888Total: " .. count .. " modified|r")
            end
        end

    elseif cmd == "backup" then
        if CVarMaster.CVarManager then
            CVarMaster.CVarManager:BackupAll()
        end

    elseif cmd == "restore" then
        if CVarMaster.CVarManager then
            CVarMaster.CVarManager:RestoreBackup(true)
        end

    elseif cmd == "profile" or cmd == "p" then
        local subCmd = (args[2] or ""):lower()
        local profileName = ""
        if args[3] then
            local nameParts = {}
            for i = 3, #args do
                table.insert(nameParts, args[i])
            end
            profileName = table.concat(nameParts, " ")
            profileName = profileName:match('^"?(.-)"?$') or profileName
        end

        if subCmd == "save" or subCmd == "s" then
            if profileName == "" then
                print("|cffff0000CVarMaster:|r Usage: /cvm profile save <name>")
                print("  Example: /cvm profile save MyProfile")
                print("  Example: /cvm profile save Mythic Raid")
            elseif CVarMaster.ProfileManager then
                CVarMaster.ProfileManager:SaveProfile(profileName)
            end
        elseif subCmd == "load" or subCmd == "l" then
            if profileName == "" then
                print("|cffff0000CVarMaster:|r Usage: /cvm profile load <name>")
            elseif CVarMaster.ProfileManager then
                CVarMaster.ProfileManager:LoadProfile(profileName)
            end
        elseif subCmd == "delete" or subCmd == "d" or subCmd == "del" then
            if profileName == "" then
                print("|cffff0000CVarMaster:|r Usage: /cvm profile delete <name>")
            elseif CVarMaster.ProfileManager then
                CVarMaster.ProfileManager:DeleteProfile(profileName)
            end
        elseif subCmd == "list" or subCmd == "ls" then
            if CVarMaster.ProfileManager then
                local profiles = CVarMaster.ProfileManager:GetProfiles()
                if #profiles == 0 then
                    print("|cff00aaffCVarMaster:|r No saved profiles")
                else
                    print("|cff00aaffCVarMaster:|r Saved profiles:")
                    for _, name in ipairs(profiles) do
                        print("  - " .. name)
                    end
                end
            end
        elseif subCmd == "export" or subCmd == "e" then
            if profileName == "" then
                print("|cffff0000CVarMaster:|r Usage: /cvm profile export <name>")
            elseif CVarMaster.ProfileManager then
                local exported = CVarMaster.ProfileManager:ExportProfile(profileName)
                if exported then
                    local editBox = ChatFrame1EditBox
                    if editBox then
                        editBox:SetText(exported)
                        editBox:HighlightText()
                        print("|cff00aaffCVarMaster:|r Export string copied to chat editbox - press Ctrl+C")
                    end
                end
            end
        elseif subCmd == "import" or subCmd == "i" then
            if CVarMaster.ProfileManager then
                CVarMaster.ProfileManager:ShowImportDialog()
            end
        else
            print("|cff00aaffCVarMaster|r Profile Commands:")
            print("  /cvm profile save <name> - Save current CVars")
            print("  /cvm profile load <name> - Load a profile")
            print("  /cvm profile delete <name> - Delete a profile")
            print("  /cvm profile list - List all profiles")
            print("  /cvm profile export <name> - Export to string")
            print("  /cvm profile import - Import from string")
        end
    elseif cmd == "lock" then
        local cvarName = args[2]
        if not cvarName or cvarName == "" then
            print("|cffff0000CVarMaster:|r Usage: /cvm lock <cvarName>")
        elseif CVarMaster.CVarManager then
            CVarMaster.CVarManager:LockCVar(cvarName)
        end

    elseif cmd == "unlock" then
        local cvarName = args[2]
        if not cvarName or cvarName == "" then
            print("|cffff0000CVarMaster:|r Usage: /cvm unlock <cvarName>")
        elseif CVarMaster.CVarManager then
            CVarMaster.CVarManager:UnlockCVar(cvarName)
        end

    elseif cmd == "locked" or cmd == "locks" then
        local sub = (args[2] or ""):lower()
        if sub == "prune" then
            if CVarMaster.CVarManager then
                local pruned = CVarMaster.CVarManager:PruneStaleLocks()
                print("|cff00aaffCVarMaster:|r Pruned " .. pruned .. " lock(s) on unregistered CVars")
            end
        elseif CVarMaster.CVarManager then
            local locked = CVarMaster.CVarManager:GetLockedCVars()
            local count, stale = 0, 0
            print("|cff00aaffCVarMaster:|r Locked CVars (persist across sessions):")
            for name, value in pairs(locked) do
                local current = GetCVar(name)
                local status
                if current == nil then
                    status = "|cffff8800NOT REGISTERED|r"
                    current = "?"
                    stale = stale + 1
                elseif tostring(current) == tostring(value) then
                    status = "|cff00ff00OK|r"
                else
                    status = "|cffff0000MISMATCH|r"
                end
                print("  |cff88ff88" .. name .. "|r = |cffffff00" .. value .. "|r (current: " .. current .. ") " .. status)
                count = count + 1
            end
            if count == 0 then
                print("  |cff888888No locked CVars|r")
            else
                print("  |cff888888Total: " .. count .. " locked|r")
                if stale > 0 then
                    print("  |cff888888" .. stale .. " not registered this session - /cvm locked prune to remove|r")
                end
            end
        end

    elseif cmd == "enforce" then
        if CVarMaster.CVarManager then
            print("|cff00aaffCVarMaster:|r Manual enforcement...")
            local applied, notRegistered = CVarMaster.CVarManager:ApplyLockedCVars()
            if CVarMaster.CVarManager.ApplyForceCustom then
                CVarMaster.CVarManager:ApplyForceCustom()
            end
            local note = (notRegistered or 0) > 0
                and ("  |cffff8800(" .. notRegistered .. " not registered - see /cvm locked)|r") or ""
            print("|cff00aaffCVarMaster:|r Applied " .. (applied or 0) .. " locked CVar(s)." .. note)
        end

    elseif cmd == "button" or cmd == "microbutton" then
        local hidden = CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.hideMicroBtn
        CVarMaster:SetMicroButtonShown(hidden and true or false)
        print("|cff00aaffCVarMaster:|r Micro button " .. (hidden and "|cff00ff00shown|r" or "|cffff8800hidden|r"))

    elseif cmd == "debug" then
        if CVarMaster.db and CVarMaster.db.global then
            CVarMaster.db.global.debug = not CVarMaster.db.global.debug
            print("|cff00aaffCVarMaster:|r Debug mode " .. (CVarMaster.db.global.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        end

    elseif cmd == "compare" or cmd == "diff" then
        if CVarMaster.CVarManager then
            CVarMaster.CVarManager:CompareToBackup()
        else
            print("|cffff0000CVarMaster:|r Manager not available")
        end

    elseif cmd == "audit" then
        if CVarMaster.CVarScanner and CVarMaster.CVarScanner.Audit then
            CVarMaster.CVarScanner:Audit()
        else
            print("|cffff0000CVarMaster:|r Scanner not available")
        end

    elseif cmd == "autoenforce" then
        local sub = (args[2] or ""):lower()
        if not CVarMaster.charDB then
            print("|cffff0000CVarMaster:|r charDB not initialized")
        elseif sub == "on" or sub == "true" or sub == "1" then
            CVarMaster.charDB.autoEnforce = true
            print("|cff00aaffCVarMaster:|r Auto-enforce |cff00ff00ON|r. Locked CVars will reapply on login/zone.")
        elseif sub == "off" or sub == "false" or sub == "0" then
            CVarMaster.charDB.autoEnforce = false
            print("|cff00aaffCVarMaster:|r Auto-enforce |cffff8800OFF|r. Use |cff00ff00/cvm enforce|r manually.")
        else
            local state = CVarMaster.charDB.autoEnforce and "|cff00ff00ON|r" or "|cffff8800OFF|r"
            print("|cff00aaffCVarMaster:|r Auto-enforce is " .. state .. ". Usage: /cvm autoenforce on|off")
        end

    elseif cmd == "help" then
        print("|cff00aaffCVarMaster|r Commands:")
        print("  /cvm - Open GUI")
        print("  /cvm search <term> - Find CVars by name/description")
        print("  /cvm get <name> - Show CVar details")
        print("  /cvm set <name> <value> - Change CVar (safety-checked)")
        print("  /cvm reset <name|all> - Reset to default")
        print("  /cvm modified - List changed CVars")
        print("  /cvm compare - Compare current values to last backup")
        print("  /cvm lock <name> - Lock CVar (persists across sessions)")
        print("  /cvm unlock <name> - Unlock CVar")
        print("  /cvm locked - List locked CVars (shows current vs locked)")
        print("  /cvm locked prune - Remove locks on CVars gone from the client")
        print("  /cvm enforce - Manually apply all locked CVars")
        print("  /cvm backup - Save current state")
        print("  /cvm restore - Restore from backup")
        print("  /cvm scan - Rescan all CVars")
        print("  /cvm audit - Diff live client CVars against KnownCVars list")
        print("  /cvm profile - Profile management")
        print("  /cvm button - Toggle the micro-menu button")
        print("  /cvm help - Show this help")
    else
        print("|cff00aaffCVarMaster|r: /cvm or /cvm help")
    end
end

local frame = CreateFrame("Frame")
CVarMaster.db = nil
local initialized = false

local function Initialize()
    if initialized then return end
    initialized = true

    CVarMaster.db = CVarMasterDB or {}
    -- Bind the saved-variables GLOBAL to our working alias immediately.
    -- WoW serializes the global (CVarMasterDB) at logout, not CVarMaster.db.
    -- If we leave the global nil here, the next code to touch it (ThemeManager)
    -- creates a SEPARATE table and binds that to the global — profiles written
    -- through CVarMaster.db then never get saved. Binding now makes them the
    -- same table for the whole session, so divergence is impossible.
    CVarMasterDB = CVarMaster.db
    CVarMaster.db.global = CVarMaster.db.global or { debug = false }
    -- User-assigned category overrides keyed by CVar name.
    -- Persists across sessions; checked first by Scanner:GetCategory.
    CVarMaster.db.categoryOverrides = CVarMaster.db.categoryOverrides or {}
    CVarMaster.charDB = CVarMasterCharDB or {}
    CVarMasterCharDB = CVarMaster.charDB
    CVarMaster.charDB.mode = CVarMaster.charDB.mode or "basic"
    CVarMaster.charDB.lockedCVars = CVarMaster.charDB.lockedCVars or {}
    CVarMaster.charDB.forceCustom = CVarMaster.charDB.forceCustom or {}
    CVarMaster.charDB.enforceOnLogin = CVarMaster.charDB.enforceOnLogin or false
    CVarMaster.charDB.activeProfile = CVarMaster.charDB.activeProfile or nil

    if CVarMaster.GUI and CVarMaster.GUI.LoadAccentFromDB then
        CVarMaster.GUI:LoadAccentFromDB()
    end

    if CVarMaster.ThemeManager and CVarMaster.ThemeManager.Initialize then
        CVarMaster.ThemeManager:Initialize()
    end

    if CVarMaster.CVarScanner then
        CVarMaster.CVarScanner:ScanAll()
    end

    -- Deliberately silent on load. Any print() at addon-init time taints
    -- ChatFrame1's tracked CircularBuffer, which can cascade into chat
    -- re-emit loops in instances ("X has joined the battle" spam). Print
    -- only on explicit user action via /cvm commands instead.
end

local function EnforceSettings()
    if not CVarMaster.charDB then return end

    if CVarMaster.CVarManager then
        CVarMaster.CVarManager:ApplyLockedCVars(true)
    end

    if CVarMaster.CVarManager and CVarMaster.CVarManager.ApplyForceCustom then
        -- silent=true: this only runs on the auto-enforce path (guard: no print()
        -- during PLAYER_ENTERING_WORLD); /cvm enforce calls ApplyForceCustom loud.
        pcall(function() CVarMaster.CVarManager:ApplyForceCustom(true) end)
    end

    if CVarMaster.charDB.enforceOnLogin and CVarMaster.charDB.activeProfile then
        if CVarMaster.ProfileManager and CVarMaster.ProfileManager.LoadProfile then
            local profileName = CVarMaster.charDB.activeProfile
            pcall(function()
                CVarMaster.ProfileManager:LoadProfile(profileName, true)
            end)
        end
    end
end

local enforcePending = false
local hasEnforcedThisSession = false
local enforceDeferred = false

local function IsRiskyContext()
    -- Auto-applying CVars from insecure code while CompactPartyFrame/CompactRaidFrame
    -- or nameplates are spinning up taints those frames for the rest of the session.
    -- Skip when we're in any instance OR have a home-category party/raid.
    if IsInInstance and select(1, IsInInstance()) then return true end
    if IsInGroup and IsInGroup(LE_PARTY_CATEGORY_HOME or 1) then return true end
    return false
end

local function ScheduleEnforce()
    if hasEnforcedThisSession or enforcePending then return end

    -- DIAGNOSTIC: auto-enforce is opt-in. Default off so we can isolate
    -- whether the locking path is the source of UI taint reports. Manual
    -- /cvm enforce still works for testing. Flip charDB.autoEnforce = true
    -- (or use /cvm autoenforce on) to re-enable the original behaviour.
    -- Silent on auto-fired paths: any print() at PLAYER_ENTERING_WORLD
    -- taints ChatFrame1 and seeds chat-redraw cascades inside instances.
    -- Status is visible via /cvm autoenforce.
    if not (CVarMaster.charDB and CVarMaster.charDB.autoEnforce) then
        return
    end

    if InCombatLockdown() then
        -- Logged in while flagged in combat: retry when combat drops instead
        -- of silently losing enforcement for the whole session.
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    if IsRiskyContext() then
        enforceDeferred = true
        frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        frame:RegisterEvent("GROUP_ROSTER_UPDATE")
        return
    end

    enforcePending = true
    C_Timer.After(1.0, function()
        enforcePending = false
        if InCombatLockdown() then
            frame:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end
        if IsRiskyContext() then
            -- Context turned risky inside the 1s window (e.g. login-while-grouped
            -- roster sync): defer exactly like the schedule-time guard does.
            enforceDeferred = true
            frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
            frame:RegisterEvent("GROUP_ROSTER_UPDATE")
            return
        end
        -- One attempt per session, even on error: an escaping Lua error here
        -- would fire at loading-screen time and leave state wedged.
        pcall(EnforceSettings)
        hasEnforcedThisSession = true
    end)
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("LOADING_SCREEN_DISABLED")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "CVarMaster" then
        Initialize()
    elseif event == "LOADING_SCREEN_DISABLED" or event == "PLAYER_ENTERING_WORLD" then
        ScheduleEnforce()
        if event == "PLAYER_ENTERING_WORLD" and CVarMaster.InitMicroButton then
            C_Timer.After(1, function() CVarMaster:InitMicroButton() end)
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "GROUP_ROSTER_UPDATE" then
        if enforceDeferred and not hasEnforcedThisSession and not InCombatLockdown() and not IsRiskyContext() then
            enforceDeferred = false
            frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
            frame:UnregisterEvent("GROUP_ROSTER_UPDATE")
            ScheduleEnforce()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        if not hasEnforcedThisSession then
            ScheduleEnforce()
        end
    elseif event == "PLAYER_LOGOUT" then
        CVarMasterDB = CVarMaster.db
        CVarMasterCharDB = CVarMaster.charDB
    end
end)

function CVarMaster_OnAddonCompartmentClick(addonName, buttonName)
    if CVarMaster.GUI then
        local mainWin = CVarMaster.GUI:GetMainWindow()
        if mainWin and mainWin:IsShown() then
            CVarMaster.GUI:Hide()
        else
            CVarMaster.GUI:Show()
        end
    end
end

function CVarMaster_OnAddonCompartmentEnter(addonName, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("CVarMaster v" .. (CVarMaster.Constants and CVarMaster.Constants.VERSION or "2.0"), 1, 1, 1)
    GameTooltip:AddLine("Click to toggle CVar Manager", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

function CVarMaster_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end

_G.CVarMaster = CVarMaster
