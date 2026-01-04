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
            CVarMaster.CVarScanner:RefreshCache()
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
        print("  /cvm scan - Rescan CVars")
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
