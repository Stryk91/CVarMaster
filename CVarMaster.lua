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
        local value = args[3]
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
        if CVarMaster.CVarManager then
            local locked = CVarMaster.CVarManager:GetLockedCVars()
            local count = 0
            print("|cff00aaffCVarMaster:|r Locked CVars (persist across sessions):")
            for name, value in pairs(locked) do
                local current = GetCVar(name) or "?"
                local match = (tostring(current) == tostring(value)) and "|cff00ff00OK|r" or "|cffff0000MISMATCH|r"
                print("  |cff88ff88" .. name .. "|r = |cffffff00" .. value .. "|r (current: " .. current .. ") " .. match)
                count = count + 1
            end
            if count == 0 then
                print("  |cff888888No locked CVars|r")
            else
                print("  |cff888888Total: " .. count .. " locked|r")
            end
        end

    elseif cmd == "enforce" then
        if CVarMaster.CVarManager then
            print("|cff00aaffCVarMaster:|r Manual enforcement...")
            CVarMaster.CVarManager:ApplyLockedCVars()
            if CVarMaster.CVarManager.ApplyForceCustom then
                CVarMaster.CVarManager:ApplyForceCustom()
            end
        end

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
        print("  /cvm enforce - Manually apply all locked CVars")
        print("  /cvm backup - Save current state")
        print("  /cvm restore - Restore from backup")
        print("  /cvm scan - Rescan all CVars")
        print("  /cvm profile - Profile management")
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
    CVarMaster.db.global = CVarMaster.db.global or { debug = false }
    CVarMaster.charDB = CVarMasterCharDB or {}
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

    print("|cff00aaffCVarMaster|r v2.0.0 loaded - Type |cff00ff00/cvm|r to open")
end

local function EnforceSettings()
    if not CVarMaster.charDB then return end

    if CVarMaster.CVarManager then
        CVarMaster.CVarManager:ApplyLockedCVars()
    end

    if CVarMaster.CVarManager and CVarMaster.CVarManager.ApplyForceCustom then
        pcall(function() CVarMaster.CVarManager:ApplyForceCustom() end)
    end

    if CVarMaster.charDB.enforceOnLogin and CVarMaster.charDB.activeProfile then
        if CVarMaster.ProfileManager and CVarMaster.ProfileManager.LoadProfile then
            local profileName = CVarMaster.charDB.activeProfile
            local ok = pcall(function()
                CVarMaster.ProfileManager:LoadProfile(profileName)
            end)
            if ok then
                print("|cff00aaffCVarMaster:|r Enforced profile |cffffaa00" .. profileName .. "|r")
            end
        end
    end
end

local enforcePending = false
local enforceCount = 0

local function ScheduleEnforce()
    if enforcePending then return end
    enforcePending = true
    enforceCount = 0
    C_Timer.After(1.0, function()
        EnforceSettings()
        enforceCount = enforceCount + 1
    end)
    C_Timer.After(3.0, function()
        EnforceSettings()
        enforceCount = enforceCount + 1
        enforcePending = false
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
    elseif event == "PLAYER_LOGOUT" then
        CVarMasterDB = CVarMaster.db
        CVarMasterCharDB = CVarMaster.charDB
    end
end)

_G.CVarMaster = CVarMaster
