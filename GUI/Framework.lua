---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.GUI = CVarMaster.GUI or {}
local GUI = CVarMaster.GUI

-- Get theme colors (with ThemeManager support)
local function T(key)
    if CVarMaster.ThemeManager and CVarMaster.ThemeManager.GetThemeColor then
        return CVarMaster.ThemeManager:GetThemeColor(key)
    end
    if CVarMaster.Constants and CVarMaster.Constants.THEME and CVarMaster.Constants.THEME[key] then
        return unpack(CVarMaster.Constants.THEME[key])
    end
    return 0.5, 0.5, 0.5, 1.0
end

-- Get spacing value
local function S(key)
    if CVarMaster.Constants and CVarMaster.Constants.SPACING then
        return CVarMaster.Constants.SPACING[key] or 8
    end
    return 8
end

-- Modern backdrop with rounded feel (using dialog border for softer look)
local BACKDROP_SOFT = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileEdge = true,
    tileSize = 32,
    edgeSize = 24,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
}

-- Clean modern backdrop for panels
local BACKDROP_PANEL = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileEdge = true,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

-- Minimal backdrop for inner elements (border only - no bgFile to prevent opacity stacking)
local BACKDROP_INNER = {
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

-- Nihilum void theme backdrop (proper 9-slice from DC)
local BACKDROP_NIHILUM = {
    bgFile = "Interface\\AddOns\\CVarMaster\\textures\\center",
    edgeFile = "Interface\\AddOns\\CVarMaster\\textures\\edge",
    tile = true,
    tileSize = 128,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- Disable texture sharpening for sub-pixel smooth rendering (Plumber pattern)
local function DisableSharpening(texture)
    if texture and texture.SetTexelSnappingBias then
        texture:SetTexelSnappingBias(0)
        texture:SetSnapToPixelGrid(false)
    end
end
GUI.DisableSharpening = DisableSharpening

-- ==========================================
-- ACCENT COLOR SYSTEM (vertex color on neutral TGAs)
-- ==========================================
-- Default slate accent
local accentR, accentG, accentB = 0.45, 0.50, 0.55
-- Body tint (neutral dark)
local bodyR, bodyG, bodyB = 0.44, 0.40, 1.0
-- Saturation multiplier (1 = full color, 0 = greyscale)
local accentSat = 0.3

-- Track all nine-slice elements for live refresh (weak values so abandoned frames can be GC'd)
local registeredFrames = setmetatable({}, { __mode = "k" })
local registeredButtons = setmetatable({}, { __mode = "k" })
local registeredAccentTextures = setmetatable({}, { __mode = "k" })
local registeredTexturedButtons = setmetatable({}, { __mode = "k" })

function GUI:SetAccentHSV(hue, sat)
    -- Convert hue (0-360) + sat (0-1) to RGB accent
    hue = hue % 360
    sat = sat or 1.0
    accentSat = sat

    local h = hue / 60
    local c = sat
    local x = c * (1 - math.abs(h % 2 - 1))
    local r, g, b = 0, 0, 0

    if h < 1 then r, g, b = c, x, 0
    elseif h < 2 then r, g, b = x, c, 0
    elseif h < 3 then r, g, b = 0, c, x
    elseif h < 4 then r, g, b = 0, x, c
    elseif h < 5 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end

    -- Boost to usable range (pure hue is 0-1, we want bright accents)
    accentR = 0.10 + r * 0.90
    accentG = 0.10 + g * 0.90
    accentB = 0.10 + b * 0.90

    -- Body gets a subtle tint of the accent
    bodyR = 0.35 + r * 0.15
    bodyG = 0.35 + g * 0.15
    bodyB = 0.35 + b * 0.25  -- neutral depth in body

    -- Refresh all registered elements
    for frame in pairs(registeredFrames) do
        local p = frame.pieces
        if p then
            for _, idx in ipairs({1, 2, 3, 4, 6, 7, 8, 9}) do
                if p[idx] then
                    p[idx]:SetVertexColor(accentR, accentG, accentB, 1)
                end
            end
            if p[5] then
                p[5]:SetVertexColor(bodyR, bodyG, bodyB, 1)
            end
        end
    end

    for btn in pairs(registeredButtons) do
        if btn._9p and btn:IsObjectType("Button") then
            for i = 1, 9 do
                if btn._9p[i] then
                    btn._9p[i]:SetVertexColor(accentR, accentG, accentB, 1)
                end
            end
        end
    end

    -- Refresh accent textures (lines, dividers, indicators)
    for tex, alpha in pairs(registeredAccentTextures) do
        if tex.SetColorTexture then
            tex:SetColorTexture(accentR, accentG, accentB, alpha)
        end
    end

    -- Refresh textured button hover borders
    for btn in pairs(registeredTexturedButtons) do
        if btn.hoverFrame and btn.hoverFrame.SetBackdropBorderColor then
            btn.hoverFrame:SetBackdropBorderColor(accentR, accentG, accentB, 0.6)
        end
    end

    -- Store in saved vars
    if CVarMaster.db then
        CVarMaster.db.accentHue = hue
        CVarMaster.db.accentSat = sat
    end
end

function GUI:GetAccentRGB()
    return accentR, accentG, accentB
end

function GUI:LoadAccentFromDB()
    if CVarMaster.db and CVarMaster.db.accentHue then
        GUI:SetAccentHSV(CVarMaster.db.accentHue, CVarMaster.db.accentSat or 0.3)
    end
end

function GUI:CreateNihilumSlider(parent, name, label, minVal, maxVal, step, width)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width or 200, 20)

    -- Label
    if label and label ~= "" then
        local lbl = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", 0, 0)
        lbl:SetText(label)
        lbl:SetTextColor(T("TEXT_MUTED"))
        container._label = lbl
    end

    -- Slider using OptionsSliderTemplate for proper drag, then reskin
    local slider = CreateFrame("Slider", name, container, "OptionsSliderTemplate")
    slider:SetSize(width and (width - 80) or 120, 14)
    if container._label then
        slider:SetPoint("LEFT", container._label, "RIGHT", 6, 0)
    else
        slider:SetPoint("LEFT", 0, 0)
    end
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    -- Hide template labels
    slider.Low:SetText("")
    slider.High:SetText("")
    slider.Text:SetText("")

    -- Hide default textures
    local regions = { slider:GetRegions() }
    for _, region in ipairs(regions) do
        if region:IsObjectType("Texture") and region ~= slider:GetThumbTexture() then
            region:SetColorTexture(0, 0, 0, 0)
            region:SetAlpha(0)
        end
    end

    -- Dark track
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", 0, 0)
    track:SetPoint("RIGHT", 0, 0)
    track:SetHeight(4)
    track:SetColorTexture(0.10, 0.10, 0.14, 1)
    DisableSharpening(track)

    -- Track border
    local trackBorder = slider:CreateTexture(nil, "BORDER", nil, -1)
    trackBorder:SetPoint("TOPLEFT", track, "TOPLEFT", -1, 1)
    trackBorder:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", 1, -1)
    trackBorder:SetColorTexture(0.25, 0.25, 0.30, 0.5)
    DisableSharpening(trackBorder)

    -- Accent fill bar
    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)
    fill:SetHeight(4)
    fill:SetWidth(1)
    fill:SetColorTexture(accentR, accentG, accentB, 0.6)
    DisableSharpening(fill)
    registeredAccentTextures[fill] = 0.6

    -- Reskin thumb
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(10, 10)
    thumb:SetColorTexture(0.85, 0.85, 0.90, 1)

    -- Value text
    local val = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    val:SetPoint("LEFT", slider, "RIGHT", 6, 0)
    val:SetWidth(45)
    val:SetJustifyH("LEFT")
    val:SetTextColor(T("TEXT_ACCENT"))

    -- Fill update on value change
    slider:HookScript("OnValueChanged", function(self)
        local pct = (self:GetValue() - minVal) / (maxVal - minVal)
        fill:SetWidth(math.max(1, pct * self:GetWidth()))
    end)

    slider._fill = fill
    slider._valueText = val
    container._slider = slider

    return container, slider, val
end

-- Reskin an existing OptionsSliderTemplate slider to match Nihilum style
function GUI:ReskinSlider(slider)
    -- Hide default textures
    local regions = { slider:GetRegions() }
    for _, region in ipairs(regions) do
        if region:IsObjectType("Texture") and region ~= slider:GetThumbTexture() then
            region:SetColorTexture(0, 0, 0, 0)
            region:SetAlpha(0)
        end
    end

    -- Dark track
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", 0, 0)
    track:SetPoint("RIGHT", 0, 0)
    track:SetHeight(4)
    track:SetColorTexture(0.10, 0.10, 0.14, 1)
    DisableSharpening(track)

    -- Track border
    local trackBorder = slider:CreateTexture(nil, "BORDER", nil, -1)
    trackBorder:SetPoint("TOPLEFT", track, "TOPLEFT", -1, 1)
    trackBorder:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", 1, -1)
    trackBorder:SetColorTexture(0.25, 0.25, 0.30, 0.5)
    DisableSharpening(trackBorder)

    -- Accent fill
    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)
    fill:SetHeight(4)
    fill:SetWidth(1)
    fill:SetColorTexture(accentR, accentG, accentB, 0.6)
    DisableSharpening(fill)
    registeredAccentTextures[fill] = 0.6

    -- Reskin thumb
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(10, 10)
    thumb:SetColorTexture(0.85, 0.85, 0.90, 1)

    -- Fill update
    local minVal, maxVal = slider:GetMinMaxValues()
    slider:HookScript("OnValueChanged", function(self)
        local mn, mx = self:GetMinMaxValues()
        local pct = (self:GetValue() - mn) / (mx - mn)
        fill:SetWidth(math.max(1, pct * self:GetWidth()))
    end)

    -- Initial fill
    C_Timer.After(0, function()
        local mn, mx = slider:GetMinMaxValues()
        local pct = (slider:GetValue() - mn) / (mx - mn)
        fill:SetWidth(math.max(1, pct * slider:GetWidth()))
    end)
end

function GUI:AddResizeHandle(frame, minW, minH, maxW, maxH)
    frame:SetResizable(true)
    frame:SetResizeBounds(minW or 300, minH or 250, maxW or 800, maxH or 700)

    local handle = CreateFrame("Button", nil, frame)
    handle:SetSize(16, 16)
    handle:SetPoint("BOTTOMRIGHT", -4, 4)
    handle:SetFrameLevel(frame:GetFrameLevel() + 10)
    handle:EnableMouse(true)

    for i = 0, 2 do
        local line = handle:CreateTexture(nil, "OVERLAY")
        line:SetSize(10 - (i * 3), 1)
        line:SetPoint("BOTTOMRIGHT", -(i * 4) - 1, (i * 4) + 1)
        line:SetColorTexture(0.5, 0.5, 0.55, 0.5)
        DisableSharpening(line)
    end

    handle:SetScript("OnMouseDown", function()
        if not InCombatLockdown() then frame:StartSizing("BOTTOMRIGHT") end
    end)
    handle:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
    handle:SetScript("OnEnter", function(self)
        SetCursor("UI_RESIZE_CURSOR")
        for _, r in ipairs({ self:GetRegions() }) do
            if r.SetColorTexture then r:SetColorTexture(0.7, 0.7, 0.75, 0.8) end
        end
    end)
    handle:SetScript("OnLeave", function(self)
        SetCursor(nil)
        for _, r in ipairs({ self:GetRegions() }) do
            if r.SetColorTexture then r:SetColorTexture(0.5, 0.5, 0.55, 0.5) end
        end
    end)

    return handle
end

function GUI:RegisterNihilumFrame(frame)
    if frame then registeredFrames[frame] = true end
end

function GUI:RegisterAccentTexture(tex, alpha)
    if tex then
        registeredAccentTextures[tex] = alpha or 1.0
        tex:SetColorTexture(accentR, accentG, accentB, alpha or 1.0)
    end
end

-- Font refresh: walk all registered NihilumFrames, find every FontString, apply font settings
local originalFontSizes = setmetatable({}, { __mode = "k" })
local DEFAULT_BASE_SIZE = 12

local function CollectFontStrings(frame, out)
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:IsObjectType("FontString") then
            out[#out + 1] = region
        end
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        CollectFontStrings(child, out)
    end
end

function GUI:RefreshFonts(settings)
    if not settings then return end
    local all = {}
    for frame in pairs(registeredFrames) do
        CollectFontStrings(frame, all)
    end

    local scale = settings.size / DEFAULT_BASE_SIZE
    for _, fs in ipairs(all) do
        if not originalFontSizes[fs] then
            local _, curSize = fs:GetFont()
            originalFontSizes[fs] = curSize or DEFAULT_BASE_SIZE
        end
        local newSize = math.max(8, math.floor(originalFontSizes[fs] * scale + 0.5))
        CVarMaster.ThemeManager.SafeSetFont(fs, settings.face, newSize, settings.flags)
        fs:SetShadowOffset(settings.shadowOffsetX, settings.shadowOffsetY)
        fs:SetShadowColor(settings.shadowColorR, settings.shadowColorG, settings.shadowColorB, settings.shadowColorA)
    end
end

-- Apply current font settings to a single FontString (lightweight, for virtual scroll rows)
function GUI:ApplyCurrentFont(fs)
    if not fs or not CVarMaster.ThemeManager then return end
    local settings = CVarMaster.ThemeManager:GetFontSettings()
    if not settings or not settings.face then return end

    if not originalFontSizes[fs] then
        local _, curSize = fs:GetFont()
        originalFontSizes[fs] = curSize or DEFAULT_BASE_SIZE
    end

    local scale = settings.size / DEFAULT_BASE_SIZE
    local newSize = math.max(8, math.floor(originalFontSizes[fs] * scale + 0.5))
    CVarMaster.ThemeManager.SafeSetFont(fs, settings.face, newSize, settings.flags)
    fs:SetShadowOffset(settings.shadowOffsetX, settings.shadowOffsetY)
    fs:SetShadowColor(settings.shadowColorR, settings.shadowColorG, settings.shadowColorB, settings.shadowColorA)
end

-- Nihilum nine-slice frame (Plumber pattern - single TGA, TexCoord regions)
-- Layout: 128x128 TGA divided into 9 regions via TexCoord
-- Corners: 14px, Edges: stretch, Center: stretch
local NIHILUM_FRAME_TEX = "Interface\\AddOns\\CVarMaster\\Textures\\nihilum_frame"
local NS = 12/128  -- normalized corner size (12px of 128px texture)
local NE = 116/128 -- normalized edge end

function GUI:CreateNihilumFrame(name, parent, showHeader)
    local f = CreateFrame("Frame", name, parent)

    -- 9 texture pieces: 1-3 top, 4-6 middle, 7-9 bottom
    local p = {}
    f.pieces = p

    for i = 1, 9 do
        p[i] = f:CreateTexture(nil, "BORDER")
        p[i]:SetTexture(NIHILUM_FRAME_TEX)
        DisableSharpening(p[i])
    end

    -- Corner sizes match the 12px border in the TGA
    local cs = 14

    -- Corners (fixed size)
    p[1]:SetSize(cs, cs)
    p[3]:SetSize(cs, cs)
    p[7]:SetSize(cs, cs)
    p[9]:SetSize(cs, cs)

    -- Anchors
    p[1]:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    p[3]:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    p[7]:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    p[9]:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

    -- Edges (stretch between corners)
    p[2]:SetPoint("TOPLEFT", p[1], "TOPRIGHT", 0, 0)
    p[2]:SetPoint("BOTTOMRIGHT", p[3], "BOTTOMLEFT", 0, 0)
    p[4]:SetPoint("TOPLEFT", p[1], "BOTTOMLEFT", 0, 0)
    p[4]:SetPoint("BOTTOMRIGHT", p[7], "TOPRIGHT", 0, 0)
    p[6]:SetPoint("TOPLEFT", p[3], "BOTTOMLEFT", 0, 0)
    p[6]:SetPoint("BOTTOMRIGHT", p[9], "TOPRIGHT", 0, 0)
    p[8]:SetPoint("TOPLEFT", p[7], "TOPRIGHT", 0, 0)
    p[8]:SetPoint("BOTTOMRIGHT", p[9], "BOTTOMLEFT", 0, 0)

    -- Center
    p[5]:SetPoint("TOPLEFT", p[1], "BOTTOMRIGHT", 0, 0)
    p[5]:SetPoint("BOTTOMRIGHT", p[9], "TOPLEFT", 0, 0)

    -- TexCoords (L, R, T, B)
    p[1]:SetTexCoord(0,  NS, 0,  NS)   -- top-left corner
    p[2]:SetTexCoord(NS, NE, 0,  NS)   -- top edge
    p[3]:SetTexCoord(NE, 1,  0,  NS)   -- top-right corner
    p[4]:SetTexCoord(0,  NS, NS, NE)   -- left edge
    p[5]:SetTexCoord(NS, NE, NS, NE)   -- center
    p[6]:SetTexCoord(NE, 1,  NS, NE)   -- right edge
    p[7]:SetTexCoord(0,  NS, NE, 1)    -- bottom-left corner
    p[8]:SetTexCoord(NS, NE, NE, 1)    -- bottom edge
    p[9]:SetTexCoord(NE, 1,  NE, 1)    -- bottom-right corner

    -- Apply accent vertex colors
    for _, idx in ipairs({1, 2, 3, 4, 6, 7, 8, 9}) do
        p[idx]:SetVertexColor(accentR, accentG, accentB, 1)
    end
    p[5]:SetVertexColor(bodyR, bodyG, bodyB, 1)

    -- Register for live refresh
    registeredFrames[f] = true
    f:SetScript("OnHide", function(self)
        -- Keep registered (might show again)
    end)

    f:EnableMouse(true)
    return f
end

-- Animation driver frame (single OnUpdate for all animations)
local animDriver = CreateFrame("Frame")
local activeAnims = {}
local activeColorAnims = {}

animDriver:SetScript("OnUpdate", function(self, delta)
    -- Alpha animations
    for obj, anim in pairs(activeAnims) do
        anim.elapsed = anim.elapsed + delta
        local progress = math.min(anim.elapsed / anim.duration, 1)
        local eased = 1 - (1 - progress) ^ 3
        obj:SetAlpha(anim.startAlpha + (anim.targetAlpha - anim.startAlpha) * eased)
        if progress >= 1 then
            activeAnims[obj] = nil
        end
    end
    -- Color transitions (backdrop)
    for key, anim in pairs(activeColorAnims) do
        anim.elapsed = anim.elapsed + delta
        local progress = math.min(anim.elapsed / anim.duration, 1)
        local eased = 1 - (1 - progress) ^ 2
        local r = anim.startR + (anim.targetR - anim.startR) * eased
        local g = anim.startG + (anim.targetG - anim.startG) * eased
        local b = anim.startB + (anim.targetB - anim.startB) * eased
        local a = anim.startA + (anim.targetA - anim.startA) * eased
        if anim.isBorder then
            anim.frame:SetBackdropBorderColor(r, g, b, a)
        else
            anim.frame:SetBackdropColor(r, g, b, a)
        end
        if progress >= 1 then
            activeColorAnims[key] = nil
        end
    end
end)

-- Smooth fade helper for modern transitions (works on frames and textures)
local function SmoothFade(obj, targetAlpha, duration)
    if not obj then return end
    duration = duration or 0.15
    local startAlpha = obj:GetAlpha()
    if math.abs(startAlpha - targetAlpha) < 0.01 then
        obj:SetAlpha(targetAlpha)
        return
    end
    activeAnims[obj] = {
        startAlpha = startAlpha,
        targetAlpha = targetAlpha,
        duration = duration,
        elapsed = 0,
    }
end

-- Color interpolation helper
local function LerpColor(r1, g1, b1, a1, r2, g2, b2, a2, t)
    return r1 + (r2 - r1) * t,
           g1 + (g2 - g1) * t,
           b1 + (b2 - b1) * t,
           a1 + (a2 - a1) * t
end

-- activeColorAnims declared above with animDriver

-- Smooth color transition for backdrops (uses central animation driver)
-- Can be called as: SmoothColorTransition(frame, "COLOR_KEY") or (frame, "COLOR_KEY", duration, isBorder)
local function SmoothColorTransition(frame, colorKey, duration, isBorder)
    if not frame or not frame.GetBackdropColor then return end
    local targetR, targetG, targetB, targetA = T(colorKey)
    duration = duration or 0.12
    local startR, startG, startB, startA
    if isBorder then
        startR, startG, startB, startA = frame:GetBackdropBorderColor()
    else
        startR, startG, startB, startA = frame:GetBackdropColor()
    end
    local animKey = tostring(frame) .. (isBorder and "_border" or "_bg")
    activeColorAnims[animKey] = {
        frame = frame,
        isBorder = isBorder,
        startR = startR, startG = startG, startB = startB, startA = startA,
        targetR = targetR, targetG = targetG, targetB = targetB, targetA = targetA,
        duration = duration,
        elapsed = 0,
    }
end

---Create a styled frame with dark theme
---@param name string|nil Frame name
---@param parent Frame Parent frame
---@param width number Frame width
---@param height number Frame height
---@param backdropStyle string|boolean|nil "nihilum", "soft", "panel", "inner", or true for soft
---@return Frame frame
function GUI:CreateFrame(name, parent, width, height, backdropStyle)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    frame:SetSize(width, height)

    -- Select backdrop based on style
    if backdropStyle == "nihilum" then
        frame:SetBackdrop(BACKDROP_NIHILUM)
        frame:SetBackdropColor(1, 1, 1, 1) -- TGA provides color
        frame:SetBackdropBorderColor(1, 1, 1, 1)
    elseif backdropStyle == "soft" or backdropStyle == true then
        frame:SetBackdrop(BACKDROP_SOFT)
        frame:SetBackdropColor(T("BG_PRIMARY"))
        frame:SetBackdropBorderColor(T("BORDER_DEFAULT"))
    elseif backdropStyle == "panel" then
        frame:SetBackdrop(BACKDROP_PANEL)
        frame:SetBackdropColor(T("BG_PRIMARY"))
        frame:SetBackdropBorderColor(T("BORDER_DEFAULT"))
    else
        frame:SetBackdrop(BACKDROP_INNER)
        frame:SetBackdropColor(T("BG_PRIMARY"))
        frame:SetBackdropBorderColor(T("BORDER_DEFAULT"))
    end

    return frame
end

---Create a textured panel using custom art
---@param name string|nil Frame name
---@param parent Frame Parent frame
---@param width number Frame width
---@param height number Frame height
---@param style string|nil "main", "sidebar", or "tooltip"
---@return Frame frame
function GUI:CreateTexturedPanel(name, parent, width, height, style)
    local TEX = CVarMaster.Constants and CVarMaster.Constants.TEXTURES

    local frame = CreateFrame("Frame", name, parent or UIParent)
    frame:SetSize(width, height)

    -- Background texture
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    if TEX then
        local texPath = TEX.PANEL_BG
        if style == "sidebar" then texPath = TEX.SIDEBAR
        elseif style == "tooltip" then texPath = TEX.TOOLTIP end
        frame.bg:SetTexture(texPath)
    else
        frame.bg:SetColorTexture(T("BG_PRIMARY"))
    end

    return frame
end

---Create a styled button with smooth transitions
---@param name string|nil Button name
---@param parent Frame Parent frame
---@param text string Button text
---@param width number|nil Button width
---@param height number|nil Button height
---@return Button button
-- Button nine-slice texture (64x64 TGA: top half = normal, bottom half = hover)
local BTN_TEX = "Interface\\AddOns\\CVarMaster\\Textures\\nihilum_button"
local BNS = 5/64    -- corner size normalized to texture width
local BNE = 59/64   -- edge end normalized
local BCS = 5        -- corner size in pixels

-- TexCoord tables for button states (L, R, T, B)
-- Normal state: top half of 64x64 (y 0-31)
local BTN_TC_NORMAL = {
    { 0,   BNS, 0,     BNS },      -- TL corner
    { BNS, BNE, 0,     BNS },      -- top edge
    { BNE, 1,   0,     BNS },      -- TR corner
    { 0,   BNS, BNS,   27/64 },    -- left edge
    { BNS, BNE, BNS,   27/64 },    -- center
    { BNE, 1,   BNS,   27/64 },    -- right edge
    { 0,   BNS, 27/64, 0.5 },      -- BL corner
    { BNS, BNE, 27/64, 0.5 },      -- bottom edge
    { BNE, 1,   27/64, 0.5 },      -- BR corner
}
-- Hover state: bottom half (y 32-63)
local BTN_TC_HOVER = {
    { 0,   BNS, 0.5,     0.5+BNS },    -- TL
    { BNS, BNE, 0.5,     0.5+BNS },    -- top
    { BNE, 1,   0.5,     0.5+BNS },    -- TR
    { 0,   BNS, 0.5+BNS, 59/64 },      -- left
    { BNS, BNE, 0.5+BNS, 59/64 },      -- center
    { BNE, 1,   0.5+BNS, 59/64 },      -- right
    { 0,   BNS, 59/64,   1 },           -- BL
    { BNS, BNE, 59/64,   1 },           -- bottom
    { BNE, 1,   59/64,   1 },           -- BR
}

local function SetButtonState(btn, tcTable)
    for i = 1, 9 do
        local tc = tcTable[i]
        btn._9p[i]:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
    end
end

function GUI:CreateButton(name, parent, text, width, height)
    local C = CVarMaster.Constants and CVarMaster.Constants.GUI or { BUTTON_HEIGHT = 28 }

    local btn = CreateFrame("Button", name, parent)
    btn:SetSize(width or 100, height or C.BUTTON_HEIGHT)

    -- Nine-slice from button TGA
    btn._9p = {}
    for i = 1, 9 do
        btn._9p[i] = btn:CreateTexture(nil, "BACKGROUND")
        btn._9p[i]:SetTexture(BTN_TEX)
        DisableSharpening(btn._9p[i])
    end

    local p = btn._9p

    -- Corners (fixed size)
    p[1]:SetSize(BCS, BCS); p[3]:SetSize(BCS, BCS)
    p[7]:SetSize(BCS, BCS); p[9]:SetSize(BCS, BCS)

    -- Anchor corners
    p[1]:SetPoint("TOPLEFT")
    p[3]:SetPoint("TOPRIGHT")
    p[7]:SetPoint("BOTTOMLEFT")
    p[9]:SetPoint("BOTTOMRIGHT")

    -- Edges (stretch between corners)
    p[2]:SetPoint("TOPLEFT", p[1], "TOPRIGHT")
    p[2]:SetPoint("BOTTOMRIGHT", p[3], "BOTTOMLEFT")
    p[4]:SetPoint("TOPLEFT", p[1], "BOTTOMLEFT")
    p[4]:SetPoint("BOTTOMRIGHT", p[7], "TOPRIGHT")
    p[6]:SetPoint("TOPLEFT", p[3], "BOTTOMLEFT")
    p[6]:SetPoint("BOTTOMRIGHT", p[9], "TOPRIGHT")
    p[8]:SetPoint("TOPLEFT", p[7], "TOPRIGHT")
    p[8]:SetPoint("BOTTOMRIGHT", p[9], "BOTTOMLEFT")

    -- Center
    p[5]:SetPoint("TOPLEFT", p[1], "BOTTOMRIGHT")
    p[5]:SetPoint("BOTTOMRIGHT", p[9], "TOPLEFT")

    -- Set normal state TexCoords
    SetButtonState(btn, BTN_TC_NORMAL)

    -- Apply accent vertex color
    for i = 1, 9 do
        p[i]:SetVertexColor(accentR, accentG, accentB, 1)
    end

    -- Register for live refresh
    registeredButtons[btn] = true

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(T("TEXT_PRIMARY"))

    -- Backwards-compatible shims (ProfilePanel etc override OnEnter/OnLeave,
    -- so we detect hover state from SetBackdropColor calls)
    btn._isHovered = false
    function btn:SetBackdropColor(r, g, b, a)
        -- Detect if this is a hover call (brighter than normal threshold)
        local isHover = (r + g + b) > 0.25
        if isHover and not self._isHovered then
            self._isHovered = true
            SetButtonState(self, BTN_TC_HOVER)
        elseif not isHover and self._isHovered then
            self._isHovered = false
            SetButtonState(self, BTN_TC_NORMAL)
        end
    end
    function btn:SetBackdropBorderColor(r, g, b, a) end
    function btn:GetBackdropColor() return 0.06, 0.05, 0.11, 1 end
    function btn:GetBackdropBorderColor() return 0.22, 0.16, 0.47, 1 end

    btn:SetScript("OnEnter", function(self)
        SetButtonState(self, BTN_TC_HOVER)
        self.text:SetTextColor(T("TEXT_ACCENT"))
    end)

    btn:SetScript("OnLeave", function(self)
        SetButtonState(self, BTN_TC_NORMAL)
        self.text:SetTextColor(T("TEXT_PRIMARY"))
    end)

    btn:SetScript("OnMouseDown", function(self)
        -- Darken on press via vertex color
        for i = 1, 9 do
            self._9p[i]:SetVertexColor(0.7, 0.7, 0.7, 1)
        end
    end)

    btn:SetScript("OnMouseUp", function(self)
        -- Reset vertex color to accent (not white)
        for i = 1, 9 do
            self._9p[i]:SetVertexColor(accentR, accentG, accentB, 1)
        end
        if self:IsMouseOver() then
            SetButtonState(self, BTN_TC_HOVER)
        else
            SetButtonState(self, BTN_TC_NORMAL)
        end
    end)

    return btn
end

---Create a textured button using custom art
---@param name string|nil Button name
---@param parent Frame Parent frame
---@param text string Button text
---@param width number|nil Button width
---@param height number|nil Button height
---@param style string|nil "primary", "ghost", or "danger"
---@return Button button
function GUI:CreateTexturedButton(name, parent, text, width, height, style)
    local C = CVarMaster.Constants and CVarMaster.Constants.GUI or { BUTTON_HEIGHT = 28 }
    local TEX = CVarMaster.Constants and CVarMaster.Constants.TEXTURES

    local btn = CreateFrame("Button", name, parent)
    btn:SetSize(width or 100, height or C.BUTTON_HEIGHT)

    -- Background texture
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    if TEX then
        local texPath = TEX.BTN_PRIMARY
        if style == "ghost" then texPath = TEX.BTN_GHOST
        elseif style == "danger" then texPath = TEX.BTN_DANGER end
        btn.bg:SetTexture(texPath)
    else
        btn.bg:SetColorTexture(T("BTN_NORMAL"))
    end

    -- Highlight overlay with inset for border effect
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetPoint("TOPLEFT", 1, -1)
    btn.highlight:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.highlight:SetColorTexture(1, 1, 1, 0.08)
    btn.highlight:SetBlendMode("ADD")

    -- Hover accent border using nihilum button texture (matches Reset button style)
    btn.hoverFrame = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    btn.hoverFrame:SetPoint("TOPLEFT", -1, 1)
    btn.hoverFrame:SetPoint("BOTTOMRIGHT", 1, -1)
    btn.hoverFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    local aR, aG, aB = accentR, accentG, accentB
    btn.hoverFrame:SetBackdropBorderColor(aR, aG, aB, 0.6)
    btn.hoverFrame:Hide()
    registeredTexturedButtons[btn] = true

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(T("TEXT_PRIMARY"))

    btn:SetScript("OnEnter", function(self)
        self.text:SetTextColor(T("TEXT_ACCENT"))
        self.bg:SetVertexColor(1.2, 1.2, 1.2)
        if self.hoverFrame then self.hoverFrame:Show() end
    end)

    btn:SetScript("OnLeave", function(self)
        self.text:SetTextColor(T("TEXT_PRIMARY"))
        self.bg:SetVertexColor(1, 1, 1)
        if self.hoverFrame then self.hoverFrame:Hide() end
    end)

    btn:SetScript("OnMouseDown", function(self)
        self.bg:SetVertexColor(0.8, 0.8, 0.8)
    end)

    btn:SetScript("OnMouseUp", function(self)
        if self:IsMouseOver() then
            self.bg:SetVertexColor(1.2, 1.2, 1.2)
        else
            self.bg:SetVertexColor(1, 1, 1)
        end
    end)

    return btn
end

---Create a Nihilum-styled editbox (no BackdropTemplate - accent-aware borders)
---@param name string|nil EditBox name
---@param parent Frame Parent frame
---@param width number|nil Width
---@param height number|nil Height
---@return EditBox editbox
function GUI:CreateEditBox(name, parent, width, height)
    local C = CVarMaster.Constants and CVarMaster.Constants.GUI or { SEARCH_HEIGHT = 32 }

    local box = CreateFrame("EditBox", name, parent)
    box:SetSize(width or 200, height or C.SEARCH_HEIGHT)

    -- Background texture (no BackdropTemplate)
    box.bg = box:CreateTexture(nil, "BACKGROUND")
    box.bg:SetPoint("TOPLEFT", 1, -1)
    box.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    box.bg:SetColorTexture(T("BG_TERTIARY"))
    DisableSharpening(box.bg)

    -- 1px accent-aware border (4 edge textures)
    local bR, bG, bB, bA = T("BORDER_SUBTLE")
    box._borders = {}
    local sides = {
        { p1 = "TOPLEFT", p2 = "TOPRIGHT", w = nil, h = 1 },
        { p1 = "BOTTOMLEFT", p2 = "BOTTOMRIGHT", w = nil, h = 1 },
        { p1 = "TOPLEFT", p2 = "BOTTOMLEFT", w = 1, h = nil, inY = -1, outY = 1 },
        { p1 = "TOPRIGHT", p2 = "BOTTOMRIGHT", w = 1, h = nil, inY = -1, outY = 1 },
    }
    for i, s in ipairs(sides) do
        local tex = box:CreateTexture(nil, "BORDER")
        if s.w then tex:SetWidth(s.w) end
        if s.h then tex:SetHeight(s.h) end
        tex:SetPoint(s.p1, 0, s.inY or 0)
        tex:SetPoint(s.p2, 0, s.outY or 0)
        tex:SetColorTexture(bR, bG, bB, bA)
        DisableSharpening(tex)
        box._borders[i] = tex
    end

    box:SetFontObject(GameFontHighlight)
    box:SetTextInsets(S("SM") + 2, S("SM"), 0, 0)
    box:SetAutoFocus(false)
    box:EnableMouse(true)
    box:SetTextColor(T("TEXT_PRIMARY"))

    -- Focus/blur border color changes
    local function SetBorderColor(r, g, b, a)
        for _, tex in ipairs(box._borders) do
            tex:SetColorTexture(r, g, b, a)
        end
    end
    box.SetBorderColor = SetBorderColor

    -- Shim for code that still calls SetBackdropBorderColor
    function box:SetBackdropBorderColor(r, g, b, a) SetBorderColor(r, g, b, a) end
    function box:SetBackdropColor() end
    function box:GetBackdropColor() return T("BG_TERTIARY") end

    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusGained", function()
        SetBorderColor(accentR, accentG, accentB, 0.8)
    end)
    box:SetScript("OnEditFocusLost", function()
        SetBorderColor(T("BORDER_SUBTLE"))
    end)

    return box
end

---Create a Nihilum-styled checkbox (no UICheckButtonTemplate - accent-colored)
---@param name string|nil Checkbox name
---@param parent Frame Parent frame
---@param label string Label text
---@return CheckButton checkbox
function GUI:CreateCheckbox(name, parent, label)
    local SIZE = 18

    local cb = CreateFrame("CheckButton", name, parent)
    cb:SetSize(SIZE, SIZE)

    -- Box background
    cb.bg = cb:CreateTexture(nil, "BACKGROUND")
    cb.bg:SetAllPoints()
    cb.bg:SetColorTexture(T("BG_TERTIARY"))
    DisableSharpening(cb.bg)

    -- Box border (1px, accent-muted)
    local bR, bG, bB, bA = T("BORDER_DEFAULT")
    cb._borders = {}
    local edges = {
        { "TOPLEFT", "TOPRIGHT", nil, 1 },
        { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
        { "TOPLEFT", "BOTTOMLEFT", 1, nil },
        { "TOPRIGHT", "BOTTOMRIGHT", 1, nil },
    }
    for i, e in ipairs(edges) do
        local tex = cb:CreateTexture(nil, "BORDER")
        if e[3] then tex:SetWidth(e[3]) end
        if e[4] then tex:SetHeight(e[4]) end
        tex:SetPoint(e[1])
        tex:SetPoint(e[2])
        tex:SetColorTexture(bR, bG, bB, bA)
        DisableSharpening(tex)
        cb._borders[i] = tex
    end

    -- Checkmark (accent-colored, visible when checked)
    cb.check = cb:CreateTexture(nil, "OVERLAY")
    cb.check:SetSize(SIZE - 4, SIZE - 4)
    cb.check:SetPoint("CENTER")
    cb.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cb.check:SetVertexColor(accentR, accentG, accentB, 1)
    cb.check:SetDesaturated(true)
    cb.check:Hide()
    registeredAccentTextures[cb.check] = nil -- managed manually

    -- Label text
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.label:SetPoint("LEFT", cb, "RIGHT", S("SM"), 0)
    cb.label:SetText(label)
    cb.label:SetTextColor(T("TEXT_PRIMARY"))

    -- State management
    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        if checked then
            self.check:Show()
            for _, tex in ipairs(self._borders) do
                tex:SetColorTexture(accentR, accentG, accentB, 0.7)
            end
        else
            self.check:Hide()
            local r, g, b, a = T("BORDER_DEFAULT")
            for _, tex in ipairs(self._borders) do
                tex:SetColorTexture(r, g, b, a)
            end
        end
    end)

    -- Sync visual on SetChecked
    hooksecurefunc(cb, "SetChecked", function(self, checked)
        if checked then
            self.check:Show()
            for _, tex in ipairs(self._borders) do
                tex:SetColorTexture(accentR, accentG, accentB, 0.7)
            end
        else
            self.check:Hide()
            local r, g, b, a = T("BORDER_DEFAULT")
            for _, tex in ipairs(self._borders) do
                tex:SetColorTexture(r, g, b, a)
            end
        end
    end)

    -- Hover
    cb:SetScript("OnEnter", function(self)
        for _, tex in ipairs(self._borders) do
            tex:SetColorTexture(accentR, accentG, accentB, 0.5)
        end
    end)
    cb:SetScript("OnLeave", function(self)
        if self:GetChecked() then
            for _, tex in ipairs(self._borders) do
                tex:SetColorTexture(accentR, accentG, accentB, 0.7)
            end
        else
            local r, g, b, a = T("BORDER_DEFAULT")
            for _, tex in ipairs(self._borders) do
                tex:SetColorTexture(r, g, b, a)
            end
        end
    end)

    return cb
end

---Create a Nihilum-styled slider (no OptionsSliderTemplate - accent track/thumb)
---@param name string|nil Slider name
---@param parent Frame Parent frame
---@param minVal number Minimum value
---@param maxVal number Maximum value
---@param step number|nil Step value
---@return Slider slider
function GUI:CreateSlider(name, parent, minVal, maxVal, step)
    local TRACK_H = 4
    local THUMB_W = 12
    local THUMB_H = 16

    local slider = CreateFrame("Slider", name, parent)
    slider:SetSize(180, THUMB_H)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)

    -- Track background
    slider.trackBg = slider:CreateTexture(nil, "BACKGROUND")
    slider.trackBg:SetHeight(TRACK_H)
    slider.trackBg:SetPoint("LEFT", 0, 0)
    slider.trackBg:SetPoint("RIGHT", 0, 0)
    slider.trackBg:SetColorTexture(T("BG_TERTIARY"))
    DisableSharpening(slider.trackBg)

    -- Track fill (accent color, stretches from left to thumb position)
    slider.trackFill = slider:CreateTexture(nil, "ARTWORK")
    slider.trackFill:SetHeight(TRACK_H)
    slider.trackFill:SetPoint("LEFT", slider.trackBg, "LEFT")
    slider.trackFill:SetColorTexture(accentR, accentG, accentB, 0.6)
    DisableSharpening(slider.trackFill)

    -- Thumb texture (accent-colored rectangle)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(THUMB_W, THUMB_H)
    thumb:SetColorTexture(accentR, accentG, accentB, 1)
    DisableSharpening(thumb)
    slider:SetThumbTexture(thumb)

    -- Register thumb for accent refresh
    registeredAccentTextures[thumb] = 1.0

    -- Track fill update
    local function UpdateFill(self)
        local min, max = self:GetMinMaxValues()
        local val = self:GetValue()
        local range = max - min
        if range <= 0 then
            slider.trackFill:SetWidth(1)
            return
        end
        local pct = (val - min) / range
        local trackWidth = self:GetWidth()
        slider.trackFill:SetWidth(math.max(1, pct * trackWidth))
    end

    -- Value text (below slider)
    slider.value = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slider.value:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    slider.value:SetTextColor(T("TEXT_SECONDARY"))

    slider:SetScript("OnValueChanged", function(self, value)
        self.value:SetText(string.format("%.1f", value))
        UpdateFill(self)
    end)

    -- Hover feedback on thumb
    slider:SetScript("OnEnter", function(self)
        thumb:SetColorTexture(accentR * 1.3, accentG * 1.3, accentB * 1.3, 1)
    end)
    slider:SetScript("OnLeave", function(self)
        thumb:SetColorTexture(accentR, accentG, accentB, 1)
    end)

    -- Initial fill
    slider:SetScript("OnShow", function(self)
        C_Timer.After(0, function() UpdateFill(self) end)
    end)

    -- Shims for code expecting OptionsSliderTemplate children
    slider.Low = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -1)
    slider.Low:SetTextColor(T("TEXT_MUTED"))
    slider.High = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -1)
    slider.High:SetTextColor(T("TEXT_MUTED"))
    slider.Text = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slider.Text:SetPoint("BOTTOM", slider, "TOP", 0, 2)

    return slider
end

---Create a Nihilum-styled scroll frame (no UIPanelScrollFrameTemplate - accent scrollbar)
---@param name string Frame name
---@param parent Frame Parent frame
---@param width number Width
---@param height number Height
---@return Frame container, Frame content
function GUI:CreateScrollFrame(name, parent, width, height)
    local SCROLLBAR_W = 8
    local THUMB_MIN_H = 24

    local container = CreateFrame("Frame", name .. "Container", parent)
    container:SetSize(width, height)

    -- Scroll frame (no Blizzard template)
    local scrollFrame = CreateFrame("ScrollFrame", name, container)
    scrollFrame:SetPoint("TOPLEFT", S("XS"), -S("XS"))
    scrollFrame:SetPoint("BOTTOMRIGHT", -(SCROLLBAR_W + S("SM")), S("XS"))

    -- Content frame (use calculated width - GetWidth() returns 0 before layout)
    local contentWidth = width - SCROLLBAR_W - S("SM") - S("XS") * 2
    local content = CreateFrame("Frame", name .. "Content", scrollFrame)
    content:SetWidth(contentWidth)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    -- Scrollbar track
    local track = CreateFrame("Frame", nil, container)
    track:SetWidth(SCROLLBAR_W)
    track:SetPoint("TOPRIGHT", -2, -S("XS"))
    track:SetPoint("BOTTOMRIGHT", -2, S("XS"))

    track.bg = track:CreateTexture(nil, "BACKGROUND")
    track.bg:SetAllPoints()
    track.bg:SetColorTexture(T("BG_TERTIARY"))
    DisableSharpening(track.bg)

    -- Scrollbar thumb
    local thumbFrame = CreateFrame("Frame", nil, track)
    thumbFrame:SetWidth(SCROLLBAR_W)
    thumbFrame:SetHeight(THUMB_MIN_H)
    thumbFrame:SetPoint("TOP", track, "TOP")
    thumbFrame:EnableMouse(true)
    thumbFrame:SetMovable(true)

    thumbFrame.tex = thumbFrame:CreateTexture(nil, "OVERLAY")
    thumbFrame.tex:SetAllPoints()
    thumbFrame.tex:SetColorTexture(accentR, accentG, accentB, 0.5)
    DisableSharpening(thumbFrame.tex)
    registeredAccentTextures[thumbFrame.tex] = 0.5

    -- Thumb drag logic
    local isDragging = false
    local dragStartY = 0
    local dragStartScroll = 0

    thumbFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = true
            dragStartY = select(2, GetCursorPosition()) / (container:GetEffectiveScale() or 1)
            dragStartScroll = scrollFrame:GetVerticalScroll()
        end
    end)

    thumbFrame:SetScript("OnMouseUp", function()
        isDragging = false
    end)

    thumbFrame:SetScript("OnEnter", function(self)
        self.tex:SetColorTexture(accentR, accentG, accentB, 0.8)
    end)

    thumbFrame:SetScript("OnLeave", function(self)
        if not isDragging then
            self.tex:SetColorTexture(accentR, accentG, accentB, 0.5)
        end
    end)

    -- Update thumb position and size based on scroll state
    local function UpdateThumb()
        local contentH = content:GetHeight() or 1
        local viewH = scrollFrame:GetHeight() or 1
        local scrollRange = contentH - viewH

        if scrollRange <= 0 then
            thumbFrame:Hide()
            return
        end
        thumbFrame:Show()

        local trackH = track:GetHeight() or 1
        local thumbH = math.max(THUMB_MIN_H, (viewH / contentH) * trackH)
        thumbFrame:SetHeight(thumbH)

        local scrollPct = scrollFrame:GetVerticalScroll() / scrollRange
        local thumbTravel = trackH - thumbH
        local thumbY = -(scrollPct * thumbTravel)
        thumbFrame:ClearAllPoints()
        thumbFrame:SetPoint("TOP", track, "TOP", 0, thumbY)
    end

    -- Drag update (on container so it keeps updating even if mouse leaves thumb)
    container:SetScript("OnUpdate", function()
        if isDragging then
            local curY = select(2, GetCursorPosition()) / (container:GetEffectiveScale() or 1)
            local deltaY = dragStartY - curY
            local trackH = track:GetHeight() or 1
            local contentH = content:GetHeight() or 1
            local viewH = scrollFrame:GetHeight() or 1
            local scrollRange = contentH - viewH
            if scrollRange > 0 and trackH > 0 then
                local thumbH = thumbFrame:GetHeight()
                local thumbTravel = trackH - thumbH
                if thumbTravel > 0 then
                    local scrollDelta = (deltaY / thumbTravel) * scrollRange
                    local newScroll = math.max(0, math.min(scrollRange, dragStartScroll + scrollDelta))
                    scrollFrame:SetVerticalScroll(newScroll)
                    UpdateThumb()
                end
            end
        end
    end)

    -- Mouse wheel scrolling
    container:EnableMouseWheel(true)
    container:SetScript("OnMouseWheel", function(self, delta)
        local contentH = content:GetHeight() or 1
        local viewH = scrollFrame:GetHeight() or 1
        local scrollRange = contentH - viewH
        if scrollRange <= 0 then return end
        local step = math.min(40, scrollRange * 0.1)
        local current = scrollFrame:GetVerticalScroll()
        local newScroll = math.max(0, math.min(scrollRange, current - delta * step))
        scrollFrame:SetVerticalScroll(newScroll)
        UpdateThumb()
    end)

    -- Also scroll when mouse is over the scroll frame itself
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        container:GetScript("OnMouseWheel")(container, delta)
    end)

    -- Hook content height changes to update thumb
    content:SetScript("OnSizeChanged", function()
        C_Timer.After(0, UpdateThumb)
    end)

    scrollFrame:SetScript("OnScrollRangeChanged", function()
        UpdateThumb()
    end)

    -- Expose for external access
    container.scrollFrame = scrollFrame
    container.content = content
    container.UpdateThumb = UpdateThumb

    return container, content
end

---Create a dropdown menu
---@param name string Dropdown name
---@param parent Frame Parent frame
---@param width number|nil Width
---@param options table Array of {text, value} options
---@return Frame dropdown
function GUI:CreateDropdown(name, parent, width, options)
    local dropdown = CreateFrame("DropdownButton", name, parent, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(width or 150)
    dropdown:SetDefaultText("Select...")

    -- Track selected value for external access
    dropdown.selectedValue = nil

    dropdown:SetupMenu(function(dd, rootDescription)
        for _, opt in ipairs(options) do
            rootDescription:CreateRadio(opt.text, function()
                return dropdown.selectedValue == opt.value
            end, function()
                dropdown.selectedValue = opt.value
                if dropdown.OnValueChanged then
                    dropdown:OnValueChanged(opt.value)
                end
            end, opt.value)
        end
    end)

    return dropdown
end

---Create section header
---@param parent Frame Parent frame
---@param text string Header text
---@param yOffset number|nil Y offset
---@return FontString header
function GUI:CreateHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", S("MD"), yOffset or -S("MD"))
    header:SetText(text)
    header:SetTextColor(T("ACCENT_PRIMARY"))
    return header
end

---Create horizontal divider
---@param parent Frame Parent frame
---@param yOffset number Y offset
---@return Texture divider
function GUI:CreateDivider(parent, yOffset)
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("LEFT", S("MD"), 0)
    divider:SetPoint("RIGHT", -S("MD"), 0)
    divider:SetPoint("TOP", 0, yOffset)
    divider:SetColorTexture(T("BORDER_SUBTLE"))
    return divider
end

---Create a lightweight panel with colored bg texture (NO BackdropTemplate - prevents opacity stacking)
---@param parent Frame Parent frame
---@param r number Red (0-1)
---@param g number Green (0-1)
---@param b number Blue (0-1)
---@param a number Alpha (0-1)
---@param borderR number|nil Border red
---@param borderG number|nil Border green
---@param borderB number|nil Border blue
---@param borderA number|nil Border alpha
---@return Frame panel
function GUI:CreateLightPanel(parent, r, g, b, a, borderR, borderG, borderB, borderA)
    local panel = CreateFrame("Frame", nil, parent)

    -- Background as a simple texture (no stacking)
    panel.bg = panel:CreateTexture(nil, "BACKGROUND")
    panel.bg:SetAllPoints()
    panel.bg:SetColorTexture(r or 0, g or 0, b or 0, a or 0)
    DisableSharpening(panel.bg)

    -- Optional 1px border
    if borderR then
        local bA = borderA or 0.3
        panel.borderTop = panel:CreateTexture(nil, "BORDER")
        panel.borderTop:SetHeight(1)
        panel.borderTop:SetPoint("TOPLEFT")
        panel.borderTop:SetPoint("TOPRIGHT")
        panel.borderTop:SetColorTexture(borderR, borderG, borderB, bA)

        panel.borderBottom = panel:CreateTexture(nil, "BORDER")
        panel.borderBottom:SetHeight(1)
        panel.borderBottom:SetPoint("BOTTOMLEFT")
        panel.borderBottom:SetPoint("BOTTOMRIGHT")
        panel.borderBottom:SetColorTexture(borderR, borderG, borderB, bA)

        panel.borderLeft = panel:CreateTexture(nil, "BORDER")
        panel.borderLeft:SetWidth(1)
        panel.borderLeft:SetPoint("TOPLEFT", 0, -1)
        panel.borderLeft:SetPoint("BOTTOMLEFT", 0, 1)
        panel.borderLeft:SetColorTexture(borderR, borderG, borderB, bA)

        panel.borderRight = panel:CreateTexture(nil, "BORDER")
        panel.borderRight:SetWidth(1)
        panel.borderRight:SetPoint("TOPRIGHT", 0, -1)
        panel.borderRight:SetPoint("BOTTOMRIGHT", 0, 1)
        panel.borderRight:SetColorTexture(borderR, borderG, borderB, bA)
    end

    -- Helper to change bg color without BackdropTemplate overhead
    function panel:SetBGColor(nr, ng, nb, na)
        self.bg:SetColorTexture(nr, ng, nb, na)
    end

    -- Helper to change bg alpha only
    function panel:SetBGAlpha(na)
        self.bg:SetAlpha(na)
    end

    return panel
end

-- Expose helpers for other modules
GUI.GetThemeColor = T
GUI.GetSpacing = S
GUI.SmoothFade = SmoothFade
GUI.SmoothColorTransition = SmoothColorTransition
GUI.LerpColor = LerpColor
