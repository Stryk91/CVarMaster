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

-- Modern backdrop with softer edges
local BACKDROP_SOFT = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileEdge = true,
    tileSize = 16,
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- Simpler backdrop for inner elements
local BACKDROP_INNER = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

---Create a styled frame with dark theme
---@param name string|nil Frame name
---@param parent Frame Parent frame
---@param width number Frame width
---@param height number Frame height
---@param useModernBackdrop boolean|nil Use softer tooltip-style backdrop
---@return Frame frame
function GUI:CreateFrame(name, parent, width, height, useModernBackdrop)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    
    if useModernBackdrop then
        frame:SetBackdrop(BACKDROP_SOFT)
    else
        frame:SetBackdrop(BACKDROP_INNER)
    end
    
    frame:SetBackdropColor(T("BG_PRIMARY"))
    frame:SetBackdropBorderColor(T("BORDER_DEFAULT"))
    return frame
end

---Create a styled button
---@param name string|nil Button name
---@param parent Frame Parent frame
---@param text string Button text
---@param width number|nil Button width
---@param height number|nil Button height
---@return Button button
function GUI:CreateButton(name, parent, text, width, height)
    local C = CVarMaster.Constants and CVarMaster.Constants.GUI or { BUTTON_HEIGHT = 28 }
    
    local btn = CreateFrame("Button", name, parent, "BackdropTemplate")
    btn:SetSize(width or 100, height or C.BUTTON_HEIGHT)
    btn:SetBackdrop(BACKDROP_INNER)
    btn:SetBackdropColor(T("BTN_NORMAL"))
    btn:SetBackdropBorderColor(T("BTN_BORDER"))
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(T("TEXT_PRIMARY"))
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(T("BTN_HOVER"))
        self:SetBackdropBorderColor(T("BTN_BORDER_HOVER"))
        self.text:SetTextColor(T("TEXT_ACCENT"))
    end)
    
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(T("BTN_NORMAL"))
        self:SetBackdropBorderColor(T("BTN_BORDER"))
        self.text:SetTextColor(T("TEXT_PRIMARY"))
    end)
    
    btn:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(T("BTN_PRESSED"))
    end)
    
    btn:SetScript("OnMouseUp", function(self)
        if self:IsMouseOver() then
            self:SetBackdropColor(T("BTN_HOVER"))
        else
            self:SetBackdropColor(T("BTN_NORMAL"))
        end
    end)
    
    return btn
end

---Create a styled editbox/input field
---@param name string|nil EditBox name
---@param parent Frame Parent frame
---@param width number|nil Width
---@param height number|nil Height
---@return EditBox editbox
function GUI:CreateEditBox(name, parent, width, height)
    local C = CVarMaster.Constants and CVarMaster.Constants.GUI or { SEARCH_HEIGHT = 32 }
    
    local box = CreateFrame("EditBox", name, parent, "BackdropTemplate")
    box:SetSize(width or 200, height or C.SEARCH_HEIGHT)
    box:SetBackdrop(BACKDROP_INNER)
    box:SetBackdropColor(T("BG_TERTIARY"))
    box:SetBackdropBorderColor(T("BORDER_SUBTLE"))
    box:SetFontObject(GameFontHighlight)
    box:SetTextInsets(S("SM") + 2, S("SM"), 0, 0)
    box:SetAutoFocus(false)
    box:EnableMouse(true)
    box:SetTextColor(T("TEXT_PRIMARY"))
    
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(T("BORDER_FOCUS"))
    end)
    box:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(T("BORDER_SUBTLE"))
    end)
    
    return box
end

---Create a styled checkbox
---@param name string|nil Checkbox name
---@param parent Frame Parent frame
---@param label string Label text
---@return CheckButton checkbox
function GUI:CreateCheckbox(name, parent, label)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.label:SetPoint("LEFT", cb, "RIGHT", S("XS"), 0)
    cb.label:SetText(label)
    cb.label:SetTextColor(T("TEXT_PRIMARY"))
    
    return cb
end

---Create a styled slider
---@param name string|nil Slider name
---@param parent Frame Parent frame
---@param minVal number Minimum value
---@param maxVal number Maximum value
---@param step number|nil Step value
---@return Slider slider
function GUI:CreateSlider(name, parent, minVal, maxVal, step)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetSize(180, 18)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)
    
    slider.Low:SetText(tostring(minVal))
    slider.High:SetText(tostring(maxVal))
    slider.Low:SetTextColor(T("TEXT_MUTED"))
    slider.High:SetTextColor(T("TEXT_MUTED"))
    
    -- Value text
    slider.value = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    slider.value:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    slider.value:SetTextColor(T("TEXT_SECONDARY"))
    
    slider:SetScript("OnValueChanged", function(self, value)
        self.value:SetText(string.format("%.1f", value))
    end)
    
    return slider
end

---Create a scrollable list frame
---@param name string Frame name
---@param parent Frame Parent frame
---@param width number Width
---@param height number Height
---@return Frame scrollFrame, Frame content
function GUI:CreateScrollFrame(name, parent, width, height)
    local container = GUI:CreateFrame(name .. "Container", parent, width, height)
    container:SetBackdropColor(T("BG_SECONDARY"))
    container:SetBackdropBorderColor(T("BORDER_SUBTLE"))
    
    local scrollFrame = CreateFrame("ScrollFrame", name, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", S("XS"), -S("XS"))
    scrollFrame:SetPoint("BOTTOMRIGHT", -22, S("XS"))
    
    local content = CreateFrame("Frame", name .. "Content", scrollFrame)
    content:SetSize(width - 28, 1)
    scrollFrame:SetScrollChild(content)
    
    -- Style the scrollbar
    local scrollBar = _G[name .. "ScrollBar"]
    if scrollBar then
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    end
    
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

-- Expose theme helper for other modules
GUI.GetThemeColor = T
GUI.GetSpacing = S
