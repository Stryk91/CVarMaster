---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI

local ProfileWindow = nil

-- Use shared theme/spacing helpers from Framework
local T = GUI.GetThemeColor
local S = GUI.GetSpacing



-- Share dialog: created once and reused; every Share click used to spawn a
-- new unnamed frame with no close button (frames are never GC'd in WoW).
local shareDialog = nil
local function ShowShareDialog(profileName, exported)
    if not shareDialog then
        local dialog = GUI:CreateNihilumFrame("CVarMasterShareDialog", UIParent, false)
        dialog:SetSize(400, 120)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("FULLSCREEN_DIALOG")

        dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dialog.title:SetPoint("TOP", 0, -10)

        local closeBtn = GUI:CreateButton(nil, dialog, "X", 22, 22)
        closeBtn:SetPoint("TOPRIGHT", -6, -6)
        closeBtn:SetScript("OnClick", function() dialog:Hide() end)

        local editBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
        editBox:SetSize(360, 24)
        editBox:SetPoint("CENTER", 0, 0)
        editBox:SetAutoFocus(true)
        editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
        dialog.editBox = editBox

        local hint = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("BOTTOM", 0, 10)
        hint:SetText("|cff888888Ctrl+C to copy, Escape to close|r")

        tinsert(UISpecialFrames, "CVarMasterShareDialog")
        shareDialog = dialog
    end

    shareDialog.title:SetText("|cff00ccffShare Profile: " .. profileName .. "|r")
    shareDialog.editBox:SetText(exported)
    shareDialog:Show()
    shareDialog.editBox:SetFocus()
    shareDialog.editBox:HighlightText()
end

-- Custom styled row for profile list. Rows are pooled by RefreshProfileList
-- (WoW never GC's frames, so rebuild-per-refresh leaks ~40 UI objects per
-- profile per refresh): handlers read row.profileName instead of capturing a
-- name, so a row can be retargeted without rebuilding.
local function CreateProfileRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(44)

    -- Background texture (no BackdropTemplate - let void show through)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0.06, 0.06, 0.08, 0.6)
    GUI.DisableSharpening(row.bg)

    -- Bottom separator
    row.sep = row:CreateTexture(nil, "ARTWORK")
    row.sep:SetHeight(1)
    row.sep:SetPoint("BOTTOMLEFT", 0, 0)
    row.sep:SetPoint("BOTTOMRIGHT", 0, 0)
    row.sep:SetColorTexture(0.15, 0.15, 0.18, 0.6)
    GUI.DisableSharpening(row.sep)

    -- Hover effect
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.10, 0.09, 0.16, 0.8)
        local aR, aG, aB = GUI:GetAccentRGB()
        self.sep:SetColorTexture(aR, aG, aB, 0.4)
    end)
    row:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.06, 0.06, 0.08, 0.6)
        self.sep:SetColorTexture(0.15, 0.15, 0.18, 0.6)
        self.sep:SetAlpha(1)
    end)

    -- Profile icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", 10, 0)
    icon:SetTexture("Interface\\AddOns\\CVarMaster\\Textures\\icon_profile")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Profile name
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    row.nameText:SetTextColor(0.85, 0.95, 0.85)
    row.nameText:SetWidth(140)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)





    -- Action buttons container
    local btnContainer = CreateFrame("Frame", nil, row)
    btnContainer:SetSize(100, 28)
    btnContainer:SetPoint("RIGHT", -8, 0)

    -- Delete button (red X)
    local deleteBtn = GUI:CreateButton(nil, btnContainer, "X", 26, 24)
    deleteBtn:SetPoint("RIGHT", 0, 0)
    deleteBtn:SetBackdropBorderColor(0.6, 0.2, 0.2, 0.8)
    deleteBtn.text:SetTextColor(0.9, 0.3, 0.3)
    deleteBtn:SetScript("OnClick", function()
        StaticPopup_Show("CVARMASTER_DELETE_PROFILE", row.profileName, nil, { profileName = row.profileName })
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
    local loadBtn = GUI:CreateButton(nil, btnContainer, "Load", 44, 24)
    loadBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -4, 0)
    loadBtn:SetBackdropBorderColor(0.2, 0.5, 0.2, 0.8)
    loadBtn:SetScript("OnClick", function()
        CVarMaster.ProfileManager:LoadProfile(row.profileName)
        if CVarMaster.CVarScanner then
            CVarMaster.CVarScanner:RefreshCache()
        end
        if GUI.RefreshCVarList then
            GUI:RefreshCVarList()
        end
        GUI:RefreshProfileList()
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
    local shareBtn = GUI:CreateButton(nil, btnContainer, "Share", 44, 24)
    shareBtn:SetPoint("RIGHT", loadBtn, "LEFT", -4, 0)
    shareBtn:SetBackdropBorderColor(0.2, 0.4, 0.6, 0.8)
    shareBtn:SetScript("OnClick", function()
        local exported = CVarMaster.ProfileManager:ExportProfile(row.profileName)
        if exported then
            ShowShareDialog(row.profileName, exported)
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

    function row:SetProfile(profileName)
        self.profileName = profileName
        self.nameText:SetText(profileName)
    end

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
        ProfileWindow = GUI:CreateNihilumFrame("CVarMasterProfileWindow", UIParent, true)
        ProfileWindow:SetSize(520, 480)
        ProfileWindow:SetClipsChildren(true)
        ProfileWindow:SetPoint("CENTER", 200, 0)
        ProfileWindow:SetMovable(true)
        ProfileWindow:EnableMouse(true)
        ProfileWindow:RegisterForDrag("LeftButton")
        ProfileWindow:SetScript("OnDragStart", ProfileWindow.StartMoving)
        ProfileWindow:SetScript("OnDragStop", ProfileWindow.StopMovingOrSizing)
        ProfileWindow:SetFrameStrata("DIALOG")
        ProfileWindow:SetClampedToScreen(true)

        -- Title bar (transparent - let nine-slice show through)
        local titleBar = CreateFrame("Frame", nil, ProfileWindow)
        titleBar:SetHeight(36)
        titleBar:SetPoint("TOPLEFT", 4, -4)
        titleBar:SetPoint("TOPRIGHT", -4, -4)

        -- Subtle bottom accent line
        titleBar.accentLine = titleBar:CreateTexture(nil, "ARTWORK")
        titleBar.accentLine:SetHeight(1)
        titleBar.accentLine:SetPoint("BOTTOMLEFT", 0, 0)
        titleBar.accentLine:SetPoint("BOTTOMRIGHT", 0, 0)
        if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(titleBar.accentLine, 0.4) end
        GUI.DisableSharpening(titleBar.accentLine)

        -- Title with icon
        local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
        titleIcon:SetSize(20, 20)
        titleIcon:SetPoint("LEFT", 12, 0)
        titleIcon:SetTexture("Interface\\AddOns\\CVarMaster\\Textures\\icon_profile")
        titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
        title:SetText("Profile Manager")
        title:SetTextColor(0.85, 0.85, 0.90, 1)

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
        local listContainer, listContent = GUI:CreateScrollFrame("CVarMasterProfileList", ProfileWindow, 496, 290)
        listContainer:SetPoint("TOP", 0, -68)
        ProfileWindow.listContent = listContent
        ProfileWindow.listContainer = listContainer

        -- Divider
        local divider = ProfileWindow:CreateTexture(nil, "ARTWORK")
        divider:SetHeight(1)
        divider:SetPoint("LEFT", 14, 0)
        divider:SetPoint("RIGHT", -14, 0)
        divider:SetPoint("BOTTOM", 0, 108)
        if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(divider, 0.25) end
        GUI.DisableSharpening(divider)

        -- New profile section header
        local newHeader = ProfileWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        newHeader:SetPoint("BOTTOMLEFT", 14, 82)
        newHeader:SetText("Create New Profile")
        newHeader:SetTextColor(0.85, 0.85, 0.90, 1)

        -- Name input with styled container
        local inputContainer = CreateFrame("Frame", nil, ProfileWindow)
        inputContainer:SetSize(380, 34)
        inputContainer:SetPoint("BOTTOMLEFT", 12, 44)

        -- Input bg (dark void with border)
        inputContainer.bg = inputContainer:CreateTexture(nil, "BACKGROUND")
        inputContainer.bg:SetAllPoints()
        inputContainer.bg:SetColorTexture(0.04, 0.03, 0.07, 0.9)
        GUI.DisableSharpening(inputContainer.bg)

        -- 4-edge border
        local function addEdge(parent, anchor1, anchor2, w, h, r, g, b, a)
            local t = parent:CreateTexture(nil, "BORDER")
            t:SetColorTexture(r, g, b, a)
            if w then t:SetWidth(w) end
            if h then t:SetHeight(h) end
            t:SetPoint(anchor1[1], anchor1[2] or parent, anchor1[3] or anchor1[1], anchor1[4] or 0, anchor1[5] or 0)
            if anchor2 then t:SetPoint(anchor2[1], anchor2[2] or parent, anchor2[3] or anchor2[1], anchor2[4] or 0, anchor2[5] or 0) end
            GUI.DisableSharpening(t)
            return t
        end
        inputContainer.borderTop = addEdge(inputContainer, {"TOPLEFT"}, {"TOPRIGHT"}, nil, 1, 0.20, 0.18, 0.30, 0.8)
        inputContainer.borderBot = addEdge(inputContainer, {"BOTTOMLEFT"}, {"BOTTOMRIGHT"}, nil, 1, 0.20, 0.18, 0.30, 0.8)
        inputContainer.borderL = addEdge(inputContainer, {"TOPLEFT"}, {"BOTTOMLEFT"}, 1, nil, 0.20, 0.18, 0.30, 0.8)
        inputContainer.borderR = addEdge(inputContainer, {"TOPRIGHT"}, {"BOTTOMRIGHT"}, 1, nil, 0.20, 0.18, 0.30, 0.8)

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
            local ac = {T("ACCENT_PRIMARY")}
            for _, edge in pairs({inputContainer.borderTop, inputContainer.borderBot, inputContainer.borderL, inputContainer.borderR}) do
                edge:SetColorTexture(ac[1] or 0.5, ac[2] or 0.38, ac[3] or 0.85, 0.8)
            end
        end)
        nameInput:SetScript("OnEditFocusLost", function()
            for _, edge in pairs({inputContainer.borderTop, inputContainer.borderBot, inputContainer.borderL, inputContainer.borderR}) do
                edge:SetColorTexture(0.20, 0.18, 0.30, 0.8)
            end
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

        -- Update Active button (saves to currently loaded profile) - on bottom row
        local updateActiveBtn = GUI:CreateButton(nil, ProfileWindow, "Update Active", 100, 30)
        updateActiveBtn:SetPoint("LEFT", importBtn, "RIGHT", 8, 0)
        updateActiveBtn:SetBackdropBorderColor(0.4, 0.4, 0.2, 0.8)
        updateActiveBtn:SetScript("OnClick", function()
            local activeProfile = CVarMaster.ProfileManager and CVarMaster.ProfileManager:GetActiveProfile()
            if activeProfile and activeProfile ~= "" then
                CVarMaster.ProfileManager:SaveProfile(activeProfile)
                GUI:RefreshProfileList()
            else
                print("|cffff0000CVarMaster:|r No active profile. Load a profile first or save a new one.")
            end
        end)
        updateActiveBtn:SetScript("OnEnter", function(self)
            local activeProfile = CVarMaster.ProfileManager and CVarMaster.ProfileManager:GetActiveProfile()
            self:SetBackdropColor(0.25, 0.25, 0.1, 1)
            self:SetBackdropBorderColor(0.6, 0.6, 0.3, 1)
            self.text:SetTextColor(1, 1, 0.5)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            if activeProfile then
                GameTooltip:SetText("Update Active Profile", 1, 1, 0.5)
                GameTooltip:AddLine("Save current CVars to: |cff00ff00" .. activeProfile .. "|r", 0.7, 0.7, 0.7)
            else
                GameTooltip:SetText("No Active Profile", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("Load a profile first, then use this to save changes", 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        end)
        updateActiveBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(T("BTN_NORMAL"))
            self:SetBackdropBorderColor(0.4, 0.4, 0.2, 0.8)
            self.text:SetTextColor(T("TEXT_PRIMARY"))
            GameTooltip:Hide()
        end)
        ProfileWindow.updateActiveBtn = updateActiveBtn
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


        GUI:AddResizeHandle(ProfileWindow, 480, 400, 750, 700)
        tinsert(UISpecialFrames, "CVarMasterProfileWindow")
    end

    GUI:RefreshProfileList()

    -- Inherit scale/alpha from main window
    local mainWin = GUI:GetMainWindow()
    if mainWin then
        ProfileWindow:SetScale(mainWin:GetScale())
    end
    GUI:ApplySpecBackground(ProfileWindow)
    ProfileWindow:Show()
end

---Refresh profile list
function GUI:RefreshProfileList()
    if not ProfileWindow or not ProfileWindow.listContent then return end

    local content = ProfileWindow.listContent
    ProfileWindow.rows = ProfileWindow.rows or {}
    local rows = ProfileWindow.rows

    local profiles = CVarMaster.ProfileManager:GetProfiles()

    -- Sort alphabetically
    table.sort(profiles, function(a, b) return a:lower() < b:lower() end)

    -- Update subtitle
    if ProfileWindow.subtitle then
        local count = #profiles
        local activeProfile = CVarMaster.ProfileManager and CVarMaster.ProfileManager:GetActiveProfile()
        local activeText = ""
        if activeProfile then
            activeText = " |cff888888•|r Active: |cff00ff00" .. activeProfile .. "|r"
        end

        if count == 0 then
            ProfileWindow.subtitle:SetText("|cff888888No saved profiles yet|r")
        elseif count == 1 then
            ProfileWindow.subtitle:SetText("|cff888888" .. count .. " saved profile|r" .. activeText)
        else
            ProfileWindow.subtitle:SetText("|cff888888" .. count .. " saved profiles|r" .. activeText)
        end
    end

    local yOffset = 0

    for i, name in ipairs(profiles) do
        local row = rows[i]
        if not row then
            row = CreateProfileRow(content)
            rows[i] = row
        end
        row:SetProfile(name)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, yOffset)
        row:SetPoint("TOPRIGHT", 0, yOffset)
        row:Show()
        yOffset = yOffset - 48
    end

    -- Hide pooled rows beyond this refresh's count
    for i = #profiles + 1, #rows do
        rows[i]:Hide()
    end

    content:SetHeight(math.max(1, math.abs(yOffset)))

    -- Empty state (created once, toggled)
    if not ProfileWindow.emptyFrame then
        local emptyFrame = CreateFrame("Frame", nil, content)
        emptyFrame:SetAllPoints()

        local emptyIcon = emptyFrame:CreateTexture(nil, "ARTWORK")
        emptyIcon:SetSize(48, 48)
        emptyIcon:SetPoint("CENTER", 0, 30)
        emptyIcon:SetTexture("Interface\\AddOns\\CVarMaster\\Textures\\icon_profile")
        emptyIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        emptyIcon:SetAlpha(0.3)

        local emptyText = emptyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyText:SetPoint("CENTER", 0, -10)
        emptyText:SetText("|cff555555No profiles saved|r")

        local emptyHint = emptyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        emptyHint:SetPoint("CENTER", 0, -30)
        emptyHint:SetText("|cff444444Enter a name below and click Save|r")

        ProfileWindow.emptyFrame = emptyFrame
    end
    ProfileWindow.emptyFrame:SetShown(#profiles == 0)
end

CVarMaster.Utils.Debug("ProfilePanel module loaded")
