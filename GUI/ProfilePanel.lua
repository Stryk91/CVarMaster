---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI

local ProfileWindow = nil

-- Local theme helper (with ThemeManager support)
local function T(key)
    if CVarMaster.ThemeManager and CVarMaster.ThemeManager.GetThemeColor then
        return CVarMaster.ThemeManager:GetThemeColor(key)
    end
    if CVarMaster.Constants and CVarMaster.Constants.THEME and CVarMaster.Constants.THEME[key] then
        return unpack(CVarMaster.Constants.THEME[key])
    end
    return 0.5, 0.5, 0.5, 1.0
end

local function S(key)
    if CVarMaster.Constants and CVarMaster.Constants.SPACING then
        return CVarMaster.Constants.SPACING[key] or 8
    end
    return 8
end

-- Custom styled row for profile list
local function CreateProfileRow(parent, name, yOffset)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(44)
    row:SetPoint("TOPLEFT", 0, yOffset)
    row:SetPoint("TOPRIGHT", 0, yOffset)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    row:SetBackdropColor(0.06, 0.06, 0.08, 0.9)
    row:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)

    -- Hover effect
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.1, 0.12, 0.15, 1)
        self:SetBackdropBorderColor(0, 0.5, 0.8, 0.6)
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.06, 0.06, 0.08, 0.9)
        self:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    end)

    -- Profile icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", 10, 0)
    icon:SetTexture("Interface\\BUTTONS\\UI-GuildButton-PublicNote-Up")
    icon:SetVertexColor(0.4, 0.8, 1, 0.8)

    -- Profile name
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    nameText:SetText(name)
    nameText:SetTextColor(0.85, 0.95, 0.85)
    nameText:SetWidth(140)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)

    -- Action buttons container
    local btnContainer = CreateFrame("Frame", nil, row)
    btnContainer:SetSize(180, 28)
    btnContainer:SetPoint("RIGHT", -8, 0)

    -- Delete button (red X)
    local deleteBtn = GUI:CreateButton(nil, btnContainer, "X", 28, 26)
    deleteBtn:SetPoint("RIGHT", 0, 0)
    deleteBtn:SetBackdropBorderColor(0.6, 0.2, 0.2, 0.8)
    deleteBtn.text:SetTextColor(0.9, 0.3, 0.3)
    deleteBtn:SetScript("OnClick", function()
        StaticPopup_Show("CVARMASTER_DELETE_PROFILE", name, nil, { profileName = name })
    end)
    deleteBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.4, 0.1, 0.1, 1)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Delete Profile", 1, 0.3, 0.3)
        GameTooltip:Show()
    end)
    deleteBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(T("BTN_NORMAL"))
        self:SetBackdropBorderColor(0.6, 0.2, 0.2, 0.8)
        GameTooltip:Hide()
    end)

    -- Load button (green)
    local loadBtn = GUI:CreateButton(nil, btnContainer, "Load", 50, 26)
    loadBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -4, 0)
    loadBtn:SetBackdropBorderColor(0.2, 0.5, 0.2, 0.8)
    loadBtn:SetScript("OnClick", function()
        CVarMaster.ProfileManager:LoadProfile(name)
        if CVarMaster.CVarScanner then
            CVarMaster.CVarScanner:RefreshCache()
        end
        if GUI.RefreshCVarList then
            GUI:RefreshCVarList()
        end
    end)
    loadBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.35, 0.15, 1)
        self:SetBackdropBorderColor(0.3, 0.7, 0.3, 1)
        self.text:SetTextColor(0.5, 1, 0.5)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Load Profile", 0.5, 1, 0.5)
        GameTooltip:AddLine("Apply all CVars from this profile", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    loadBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(T("BTN_NORMAL"))
        self:SetBackdropBorderColor(0.2, 0.5, 0.2, 0.8)
        self.text:SetTextColor(T("TEXT_PRIMARY"))
        GameTooltip:Hide()
    end)

    -- Share button (blue)
    local shareBtn = GUI:CreateButton(nil, btnContainer, "Share", 48, 26)
    shareBtn:SetPoint("RIGHT", loadBtn, "LEFT", -4, 0)
    shareBtn:SetBackdropBorderColor(0.2, 0.4, 0.6, 0.8)
    shareBtn:SetScript("OnClick", function()
        if CVarMaster.WeakAuraExport then
            CVarMaster.WeakAuraExport:ShowEncodedExportDialog(name)
        end
    end)
    shareBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.1, 0.2, 0.35, 1)
        self:SetBackdropBorderColor(0.3, 0.5, 0.8, 1)
        self.text:SetTextColor(0.5, 0.7, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Share Profile", 0.5, 0.7, 1)
        GameTooltip:AddLine("Copy encoded string for sharing", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    shareBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(T("BTN_NORMAL"))
        self:SetBackdropBorderColor(0.2, 0.4, 0.6, 0.8)
        self.text:SetTextColor(T("TEXT_PRIMARY"))
        GameTooltip:Hide()
    end)

    -- Export button (yellow)
    local exportBtn = GUI:CreateButton(nil, btnContainer, "WA", 32, 26)
    exportBtn:SetPoint("RIGHT", shareBtn, "LEFT", -4, 0)
    exportBtn:SetBackdropBorderColor(0.5, 0.4, 0.2, 0.8)
    exportBtn:SetScript("OnClick", function()
        if CVarMaster.WeakAuraExport then
            CVarMaster.WeakAuraExport:ShowProfileExportDialog(name)
        end
    end)
    exportBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.25, 0.1, 1)
        self:SetBackdropBorderColor(0.7, 0.6, 0.3, 1)
        self.text:SetTextColor(1, 0.9, 0.5)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("WeakAura Export", 1, 0.9, 0.5)
        GameTooltip:AddLine("Generate init script for WeakAuras", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    exportBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(T("BTN_NORMAL"))
        self:SetBackdropBorderColor(0.5, 0.4, 0.2, 0.8)
        self.text:SetTextColor(T("TEXT_PRIMARY"))
        GameTooltip:Hide()
    end)

    return row
end

-- Delete confirmation dialog
StaticPopupDialogs["CVARMASTER_DELETE_PROFILE"] = {
    text = "Delete profile \"%s\"?",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function(self, data)
        CVarMaster.ProfileManager:DeleteProfile(data.profileName)
        GUI:RefreshProfileList()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

---Show profile management window
function GUI:ShowProfileWindow()
    if not ProfileWindow then
        ProfileWindow = GUI:CreateFrame("CVarMasterProfileWindow", UIParent, 420, 480, true)
        ProfileWindow:SetPoint("CENTER", 200, 0)
        ProfileWindow:SetMovable(true)
        ProfileWindow:EnableMouse(true)
        ProfileWindow:RegisterForDrag("LeftButton")
        ProfileWindow:SetScript("OnDragStart", ProfileWindow.StartMoving)
        ProfileWindow:SetScript("OnDragStop", ProfileWindow.StopMovingOrSizing)
        ProfileWindow:SetFrameStrata("DIALOG")
        ProfileWindow:SetClampedToScreen(true)

        -- Title bar
        local titleBar = CreateFrame("Frame", nil, ProfileWindow, "BackdropTemplate")
        titleBar:SetHeight(36)
        titleBar:SetPoint("TOPLEFT", 4, -4)
        titleBar:SetPoint("TOPRIGHT", -4, -4)
        titleBar:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        titleBar:SetBackdropColor(0.08, 0.1, 0.12, 1)
        titleBar:SetBackdropBorderColor(0.2, 0.25, 0.3, 1)

        -- Title with icon
        local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
        titleIcon:SetSize(20, 20)
        titleIcon:SetPoint("LEFT", 12, 0)
        titleIcon:SetTexture("Interface\\BUTTONS\\UI-GuildButton-PublicNote-Up")
        titleIcon:SetVertexColor(0, 0.7, 1, 1)

        local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
        title:SetText("|cff5BD663Profile|r |cffE8EBE8Manager|r")

        -- Close button
        local closeBtn = GUI:CreateButton(nil, titleBar, "X", 30, 30)
        closeBtn:SetPoint("RIGHT", -4, 0)
        closeBtn:SetScript("OnClick", function() ProfileWindow:Hide() end)

        -- Subtitle with count
        local subtitle = ProfileWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        subtitle:SetPoint("TOPLEFT", 14, -46)
        subtitle:SetText("|cff888888Saved CVar configurations|r")
        ProfileWindow.subtitle = subtitle

        -- Profile list scroll container
        local listContainer, listContent = GUI:CreateScrollFrame("CVarMasterProfileList", ProfileWindow, 396, 290)
        listContainer:SetPoint("TOP", 0, -68)
        ProfileWindow.listContent = listContent
        ProfileWindow.listContainer = listContainer

        -- Divider
        local divider = ProfileWindow:CreateTexture(nil, "ARTWORK")
        divider:SetHeight(1)
        divider:SetPoint("LEFT", 14, 0)
        divider:SetPoint("RIGHT", -14, 0)
        divider:SetPoint("BOTTOM", 0, 108)
        divider:SetColorTexture(0.25, 0.3, 0.35, 0.8)

        -- New profile section header
        local newHeader = ProfileWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        newHeader:SetPoint("BOTTOMLEFT", 14, 82)
        newHeader:SetText("|cff00ccffCreate New Profile|r")

        -- Name input with styled container
        local inputContainer = CreateFrame("Frame", nil, ProfileWindow, "BackdropTemplate")
        inputContainer:SetSize(280, 34)
        inputContainer:SetPoint("BOTTOMLEFT", 12, 44)
        inputContainer:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        inputContainer:SetBackdropColor(0.05, 0.05, 0.07, 1)
        inputContainer:SetBackdropBorderColor(0.2, 0.25, 0.3, 1)

        local nameInput = CreateFrame("EditBox", "CVarMasterNewProfile", inputContainer)
        nameInput:SetPoint("TOPLEFT", 10, -2)
        nameInput:SetPoint("BOTTOMRIGHT", -10, 2)
        nameInput:SetFontObject(GameFontHighlight)
        nameInput:SetAutoFocus(false)
        nameInput:EnableMouse(true)
        nameInput:SetTextColor(0.9, 0.95, 0.9)

        local placeholder = inputContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        placeholder:SetPoint("LEFT", 10, 0)
        placeholder:SetText("|cff555555Enter profile name...|r")
        nameInput.placeholder = placeholder

        nameInput:SetScript("OnTextChanged", function(self)
            self.placeholder:SetShown(self:GetText() == "")
        end)
        nameInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        -- Focus effect on container
        nameInput:SetScript("OnEditFocusGained", function()
            inputContainer:SetBackdropBorderColor(0, 0.6, 1, 0.8)
        end)
        nameInput:SetScript("OnEditFocusLost", function()
            inputContainer:SetBackdropBorderColor(0.2, 0.25, 0.3, 1)
        end)

        ProfileWindow.nameInput = nameInput

        -- Save button
        local saveBtn = GUI:CreateButton(nil, ProfileWindow, "Save Current", 100, 32)
        saveBtn:SetPoint("LEFT", inputContainer, "RIGHT", 8, 0)
        saveBtn:SetBackdropBorderColor(0.2, 0.5, 0.2, 0.8)
        saveBtn:SetScript("OnClick", function()
            local name = nameInput:GetText()
            if name ~= "" then
                CVarMaster.ProfileManager:SaveProfile(name)
                nameInput:SetText("")
                nameInput.placeholder:Show()
                GUI:RefreshProfileList()
            else
                print("|cffff0000CVarMaster:|r Enter a profile name first")
            end
        end)
        saveBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.15, 0.35, 0.15, 1)
            self:SetBackdropBorderColor(0.3, 0.7, 0.3, 1)
            self.text:SetTextColor(0.5, 1, 0.5)
        end)
        saveBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(T("BTN_NORMAL"))
            self:SetBackdropBorderColor(0.2, 0.5, 0.2, 0.8)
            self.text:SetTextColor(T("TEXT_PRIMARY"))
        end)

        nameInput:SetScript("OnEnterPressed", function(self)
            saveBtn:Click()
        end)

        -- Bottom button row
        local importBtn = GUI:CreateButton(nil, ProfileWindow, "Import", 90, 30)
        importBtn:SetPoint("BOTTOMLEFT", 12, 10)
        importBtn:SetBackdropBorderColor(0.3, 0.3, 0.5, 0.8)
        importBtn:SetScript("OnClick", function()
            if CVarMaster.ProfileManager and CVarMaster.ProfileManager.ShowImportDialog then
                CVarMaster.ProfileManager:ShowImportDialog()
            end
        end)
        importBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.25, 1)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Import Profile", 1, 1, 1)
            GameTooltip:AddLine("Paste encoded string from another player", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        importBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(T("BTN_NORMAL"))
            GameTooltip:Hide()
        end)

        -- Help text
        local helpText = ProfileWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        helpText:SetPoint("BOTTOM", 0, 14)
        helpText:SetText("|cff666666Tip: Use /cvm profile <save|load|delete> <name>|r")

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
        child:SetParent(nil)
    end

    local profiles = CVarMaster.ProfileManager:GetProfiles()

    -- Sort alphabetically
    table.sort(profiles, function(a, b) return a:lower() < b:lower() end)

    -- Update subtitle
    if ProfileWindow.subtitle then
        local count = #profiles
        if count == 0 then
            ProfileWindow.subtitle:SetText("|cff888888No saved profiles yet|r")
        elseif count == 1 then
            ProfileWindow.subtitle:SetText("|cff888888" .. count .. " saved profile|r")
        else
            ProfileWindow.subtitle:SetText("|cff888888" .. count .. " saved profiles|r")
        end
    end

    local yOffset = 0

    for _, name in ipairs(profiles) do
        local row = CreateProfileRow(content, name, yOffset)
        yOffset = yOffset - 48
    end

    content:SetHeight(math.max(1, math.abs(yOffset)))

    -- Empty state
    if #profiles == 0 then
        local emptyFrame = CreateFrame("Frame", nil, content)
        emptyFrame:SetAllPoints()

        local emptyIcon = emptyFrame:CreateTexture(nil, "ARTWORK")
        emptyIcon:SetSize(48, 48)
        emptyIcon:SetPoint("CENTER", 0, 30)
        emptyIcon:SetTexture("Interface\\BUTTONS\\UI-GuildButton-PublicNote-Up")
        emptyIcon:SetVertexColor(0.3, 0.3, 0.3, 0.5)

        local emptyText = emptyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyText:SetPoint("CENTER", 0, -10)
        emptyText:SetText("|cff555555No profiles saved|r")

        local emptyHint = emptyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        emptyHint:SetPoint("CENTER", 0, -30)
        emptyHint:SetText("|cff444444Enter a name below and click Save|r")
    end
end

CVarMaster.Utils.Debug("ProfilePanel module loaded")
