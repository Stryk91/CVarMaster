---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI

local ProfileWindow = nil

---Show profile management window
function GUI:ShowProfileWindow()
    if not ProfileWindow then
        ProfileWindow = GUI:CreateFrame("CVarMasterProfileWindow", UIParent, 350, 400)
        ProfileWindow:SetPoint("CENTER", 200, 0)
        ProfileWindow:SetMovable(true)
        ProfileWindow:EnableMouse(true)
        ProfileWindow:RegisterForDrag("LeftButton")
        ProfileWindow:SetScript("OnDragStart", ProfileWindow.StartMoving)
        ProfileWindow:SetScript("OnDragStop", ProfileWindow.StopMovingOrSizing)
        ProfileWindow:SetFrameStrata("DIALOG")
        
        -- Title
        local title = ProfileWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -12)
        title:SetText("|cff00ff00Profile Manager|r")
        
        -- Close button
        local closeBtn = GUI:CreateButton(nil, ProfileWindow, "X", 24, 24)
        closeBtn:SetPoint("TOPRIGHT", -4, -4)
        closeBtn:SetScript("OnClick", function() ProfileWindow:Hide() end)
        
        -- Profile list
        local listContainer, listContent = GUI:CreateScrollFrame("CVarMasterProfileList", ProfileWindow, 330, 250)
        listContainer:SetPoint("TOP", 0, -40)
        ProfileWindow.listContent = listContent
        
        -- New profile input
        local nameInput = GUI:CreateEditBox("CVarMasterNewProfile", ProfileWindow, 200, 26)
        nameInput:SetPoint("BOTTOMLEFT", 10, 50)
        
        local placeholder = ProfileWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        placeholder:SetPoint("LEFT", nameInput, "LEFT", 8, 0)
        placeholder:SetText("|cff666666New profile name...|r")
        nameInput.placeholder = placeholder
        
        nameInput:SetScript("OnTextChanged", function(self)
            self.placeholder:SetShown(self:GetText() == "")
        end)
        
        -- Save button
        local saveBtn = GUI:CreateButton(nil, ProfileWindow, "Save Current", 100, 26)
        saveBtn:SetPoint("LEFT", nameInput, "RIGHT", 8, 0)
        saveBtn:SetScript("OnClick", function()
            local name = nameInput:GetText()
            if name ~= "" then
                CVarMaster.ProfileManager:SaveProfile(name)
                nameInput:SetText("")
                GUI:RefreshProfileList()
            end
        end)
        
        nameInput:SetScript("OnEnterPressed", function(self)
            saveBtn:Click()
        end)
        
        -- Import button
        local importBtn = GUI:CreateButton(nil, ProfileWindow, "Import", 80, 26)
        importBtn:SetPoint("BOTTOMLEFT", 10, 15)
        importBtn:SetScript("OnClick", function()
            CVarMaster.Utils.Print("Paste import string in chat: /cvm import <string>")
        end)
        
        tinsert(UISpecialFrames, "CVarMasterProfileWindow")
    end
    
    GUI:RefreshProfileList()
    ProfileWindow:Show()
end

---Refresh profile list
function GUI:RefreshProfileList()
    if not ProfileWindow or not ProfileWindow.listContent then return end
    
    local content = ProfileWindow.listContent
    
    -- Clear existing
    for _, child in pairs({content:GetChildren()}) do
        child:Hide()
    end
    
    local profiles = CVarMaster.ProfileManager:GetProfiles()
    local yOffset = 0
    
    for _, name in ipairs(profiles) do
        local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
        row:SetHeight(30)
        row:SetPoint("TOPLEFT", 0, yOffset)
        row:SetPoint("TOPRIGHT", 0, yOffset)
        row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
        row:SetBackdropColor(0.08, 0.08, 0.1, 0.8)
        
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", 10, 0)
        nameText:SetText(name)
        nameText:SetTextColor(0.8, 1, 0.8)
        
        local deleteBtn = GUI:CreateButton(nil, row, "X", 24, 22)
        deleteBtn:SetPoint("RIGHT", -4, 0)
        deleteBtn:SetBackdropBorderColor(0.8, 0.2, 0.2, 0.6)
        deleteBtn:SetScript("OnClick", function()
            CVarMaster.ProfileManager:DeleteProfile(name)
            GUI:RefreshProfileList()
        end)
        
        local loadBtn = GUI:CreateButton(nil, row, "Load", 50, 22)
        loadBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -4, 0)
        loadBtn:SetScript("OnClick", function()
            CVarMaster.ProfileManager:LoadProfile(name)
            CVarMaster.CVarScanner:RefreshCache()
            GUI:RefreshCVarList()
        end)
        
        local exportBtn = GUI:CreateButton(nil, row, "Export", 50, 22)
        exportBtn:SetPoint("RIGHT", loadBtn, "LEFT", -4, 0)
        exportBtn:SetScript("OnClick", function()
            local exported = CVarMaster.ProfileManager:ExportProfile(name)
            if exported then
                print("|cff00ff00Export string:|r")
                print(exported)
            end
        end)
        
        yOffset = yOffset - 32
    end
    
    content:SetHeight(math.max(1, math.abs(yOffset)))
    
    if #profiles == 0 then
        local noProfiles = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noProfiles:SetPoint("CENTER")
        noProfiles:SetText("|cff666666No saved profiles|r")
    end
end

CVarMaster.Utils.Debug("ProfilePanel module loaded")
