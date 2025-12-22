---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

-- Slash commands
SLASH_CVARMASTER1 = "/cvarmaster"
SLASH_CVARMASTER2 = "/cvm"

SlashCmdList["CVARMASTER"] = function(msg)
    local cmd = (msg or ""):match("^(%S*)") or ""
    cmd = cmd:lower()

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
    elseif cmd == "help" then
        print("|cff00aaffCVarMaster|r Commands:")
        print("  /cvm - Open GUI")
        print("  /cvm scan - Rescan CVars")
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
        CVarMaster.CVarScanner:ScanAllCVars()
    end
    
    print("|cff00aaffCVarMaster|r v1.1.0 loaded - Type |cff00ff00/cvm|r to open")
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
