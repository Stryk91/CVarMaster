---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

-- Slash commands
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
        -- Build profile name from remaining args (handles "Mythic Raid" with or without quotes)
        local profileName = ""
        if args[3] then
            local nameParts = {}
            for i = 3, #args do
                table.insert(nameParts, args[i])
            end
            profileName = table.concat(nameParts, " ")
            -- Strip surrounding quotes if present
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
                    -- Copy to clipboard via editbox
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
    elseif cmd == "help" then
        print("|cff00aaffCVarMaster|r Commands:")
        print("  /cvm - Open GUI")
        print("  /cvm search <term> - Find CVars by name/description")
        print("  /cvm get <name> - Show CVar details")
        print("  /cvm set <name> <value> - Change CVar (safety-checked)")
        print("  /cvm reset <name|all> - Reset to default")
        print("  /cvm modified - List changed CVars")
        print("  /cvm backup - Save current state")
        print("  /cvm restore - Restore from backup")
        print("  /cvm scan - Rescan all CVars")
        print("  /cvm profile - Profile management (save/load/delete/list)")
        print("  /cvm help - Show this help")
    else
        print("|cff00aaffCVarMaster|r: /cvm or /cvm help")
    end
end

-- Main initialization  
local frame = CreateFrame("Frame")
CVarMaster.db = nil

local function Initialize()
    CVarMaster.db = CVarMasterDB or {}
    CVarMaster.db.global = CVarMaster.db.global or { debug = false }
    CVarMaster.charDB = CVarMasterCharDB or {}
    CVarMaster.charDB.mode = CVarMaster.charDB.mode or "basic"
    
    -- Scan CVars silently
    if CVarMaster.CVarScanner then
        CVarMaster.CVarScanner:ScanAll()
    end
    
    print("|cff00aaffCVarMaster|r v1.0.5 loaded - Type |cff00ff00/cvm|r to open")
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        Initialize()
    elseif event == "PLAYER_LOGOUT" then
        CVarMasterDB = CVarMaster.db
        CVarMasterCharDB = CVarMaster.charDB
    end
end)

_G.CVarMaster = CVarMaster
