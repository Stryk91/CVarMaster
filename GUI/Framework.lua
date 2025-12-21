---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

CVarMaster.GUI = CVarMaster.GUI or {}
local GUI = CVarMaster.GUI

-- Constants
local BACKDROP_INFO = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

---Create a styled frame with dark theme
---@param name string Frame name
---@param parent Frame Parent frame
---@param width number Frame width
---@param height number Frame height
---@return Frame frame
function GUI:CreateFrame(name, parent, width, height)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop(BACKDROP_INFO)
    frame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    frame:SetBackdropBorderColor(0.2, 0.6, 0.2, 0.8)
    return frame
end

---Create a styled button
---@param name string Button name
---@param parent Frame Parent frame
---@param text string Button text
---@param width number Button width
---@param height number Button height
---@return Button button
function GUI:CreateButton(name, parent, text, width, height)
    local btn = CreateFrame("Button", name, parent, "BackdropTemplate")
    btn:SetSize(width or 100, height or 24)
    btn:SetBackdrop(BACKDROP_INFO)
    btn:SetBackdropColor(0.15, 0.15, 0.2, 1)
    btn:SetBackdropBorderColor(0.3, 0.8, 0.3, 0.6)
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(0.8, 1, 0.8)
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.4, 0.2, 1)
        self:SetBackdropBorderColor(0, 1, 0, 0.8)
    end)
    
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.2, 1)
        self:SetBackdropBorderColor(0.3, 0.8, 0.3, 0.6)
    end)
    
    btn:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.1, 0.3, 0.1, 1)
    end)
    
    btn:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.2, 0.4, 0.2, 1)
    end)
    
    return btn
end

---Create a styled editbox/input field
---@param name string EditBox name
---@param parent Frame Parent frame
---@param width number Width
---@param height number Height
---@return EditBox editbox
function GUI:CreateEditBox(name, parent, width, height)
    local box = CreateFrame("EditBox", name, parent, "BackdropTemplate")
    box:SetSize(width or 200, height or 24)
    box:SetBackdrop(BACKDROP_INFO)
    box:SetBackdropColor(0.1, 0.1, 0.12, 1)
    box:SetBackdropBorderColor(0.3, 0.5, 0.3, 0.6)
    box:SetFontObject(GameFontHighlightSmall)
    box:SetTextInsets(8, 8, 0, 0)
    box:SetAutoFocus(false)
    box:EnableMouse(true)
    
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(0, 1, 0, 0.8)
    end)
    box:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.3, 0.5, 0.3, 0.6)
    end)
    
    return box
end

---Create a styled checkbox
---@param name string Checkbox name
---@param parent Frame Parent frame
---@param label string Label text
---@return CheckButton checkbox
function GUI:CreateCheckbox(name, parent, label)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.label:SetText(label)
    cb.label:SetTextColor(0.8, 0.8, 0.8)
    
    return cb
end

---Create a styled slider
---@param name string Slider name
---@param parent Frame Parent frame
---@param minVal number Minimum value
---@param maxVal number Maximum value
---@param step number Step value
---@return Slider slider
function GUI:CreateSlider(name, parent, minVal, maxVal, step)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetSize(180, 18)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)
    
    slider.Low:SetText(tostring(minVal))
    slider.High:SetText(tostring(maxVal))
    
    -- Value text
    slider.value = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slider.value:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    
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
    
    local scrollFrame = CreateFrame("ScrollFrame", name, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -24, 4)
    
    local content = CreateFrame("Frame", name .. "Content", scrollFrame)
    content:SetSize(width - 28, 1) -- Height will grow
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
---@param width number Width
---@param options table Array of {text, value} options
---@return Frame dropdown
function GUI:CreateDropdown(name, parent, width, options)
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, width or 150)
    
    local function Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, opt in ipairs(options) do
            info.text = opt.text
            info.value = opt.value
            info.func = function()
                UIDropDownMenu_SetSelectedValue(dropdown, opt.value)
                UIDropDownMenu_SetText(dropdown, opt.text)
                if dropdown.OnValueChanged then
                    dropdown:OnValueChanged(opt.value)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, Initialize)
    
    return dropdown
end

---Create section header
---@param parent Frame Parent frame
---@param text string Header text
---@param yOffset number Y offset
---@return FontString header
function GUI:CreateHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 10, yOffset or -10)
    header:SetText(text)
    header:SetTextColor(0, 1, 0)
    return header
end

---Create horizontal divider
---@param parent Frame Parent frame
---@param yOffset number Y offset
---@return Texture divider
function GUI:CreateDivider(parent, yOffset)
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("LEFT", 10, 0)
    divider:SetPoint("RIGHT", -10, 0)
    divider:SetPoint("TOP", 0, yOffset)
    divider:SetColorTexture(0.2, 0.6, 0.2, 0.5)
    return divider
end




