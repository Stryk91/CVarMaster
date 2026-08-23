-- CVarMaster Micro Menu Button
-- Anchors next to the Character micro button for quick access
local ADDON_NAME, CVarMaster = ...

local function CreateMicroButton()
    local btn = CreateFrame("Button", "CVarMasterMicroButton", UIParent)
    btn:SetSize(28, 36)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(200)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\AddOns\\CVarMaster\\Textures\\icon_micromenu")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetVertexColor(0.7, 0.7, 0.75, 0.8)
    btn.icon = icon

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.85)
    btn.bg = bg

    local borders = {}
    local bColor = { 0.30, 0.30, 0.35, 0.5 }
    local sides = {
        { "TOPLEFT", "TOPRIGHT", nil, 1 },
        { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
        { "TOPLEFT", "BOTTOMLEFT", 1, nil },
        { "TOPRIGHT", "BOTTOMRIGHT", 1, nil },
    }
    for _, s in ipairs(sides) do
        local tex = btn:CreateTexture(nil, "BORDER")
        if s[3] then tex:SetWidth(s[3]) end
        if s[4] then tex:SetHeight(s[4]) end
        tex:SetPoint(s[1])
        tex:SetPoint(s[2])
        tex:SetColorTexture(unpack(bColor))
        borders[#borders + 1] = tex
    end
    btn.borders = borders

    btn:SetScript("OnEnter", function(self)
        self.icon:SetVertexColor(1, 1, 1, 1)
        self.bg:SetColorTexture(0.10, 0.10, 0.15, 0.95)
        for _, b in ipairs(self.borders) do b:SetColorTexture(0.50, 0.55, 0.60, 0.8) end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("CVarMaster", 1, 1, 1)
        GameTooltip:AddLine("Click to toggle CVar Manager", 0.6, 0.6, 0.6)
        GameTooltip:AddLine("Right-click for options", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(0.7, 0.7, 0.75, 0.8)
        self.bg:SetColorTexture(0.05, 0.05, 0.08, 0.85)
        for _, b in ipairs(self.borders) do b:SetColorTexture(0.30, 0.30, 0.35, 0.5) end
        GameTooltip:Hide()
    end)

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if CVarMaster.GUI and CVarMaster.GUI.ShowThemeWindow then
                CVarMaster.GUI:ShowThemeWindow()
            end
        else
            if CVarMaster.GUI then
                local mainWin = CVarMaster.GUI:GetMainWindow()
                if mainWin and mainWin:IsShown() then
                    CVarMaster.GUI:Hide()
                else
                    CVarMaster.GUI:Show()
                end
            end
        end
    end)

    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self._moving = true
            self:StartMoving()
        end
    end)
    -- OnDragStop fires for every drag gesture; only persist when a Shift-move
    -- actually started, otherwise GetPoint() is still the CharacterMicroButton
    -- anchor and restoring it against UIParent lands the button off-screen.
    btn:SetScript("OnDragStop", function(self)
        if not self._moving then return end
        self._moving = false
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        if CVarMaster.db and CVarMaster.db.global then
            CVarMaster.db.global.microBtnPos = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end)

    return btn
end

function CVarMaster:InitMicroButton()
    if CVarMasterMicroButton then return end
    if CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.hideMicroBtn then return end

    local btn = CreateMicroButton()
    local saved = CVarMaster.db and CVarMaster.db.global and CVarMaster.db.global.microBtnPos
    if saved then
        btn:ClearAllPoints()
        btn:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
    else
        if CharacterMicroButton then
            btn:SetPoint("RIGHT", CharacterMicroButton, "LEFT", -2, 0)
        else
            btn:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -260, 0)
        end
    end
end