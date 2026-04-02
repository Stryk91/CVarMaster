---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local Constants = CVarMaster.Constants

-- Currently selected category
local selectedCategory = "All"
local categoryButtons = {}

-- Use shared theme/spacing helpers from Framework
local T = GUI.GetThemeColor
local S = GUI.GetSpacing

-- Category icons using WoW built-in textures
local CATEGORY_ICONS = {
    All           = "Interface\\AddOns\\CVarMaster\\Textures\\icon_all",
    Accessibility = "Interface\\AddOns\\CVarMaster\\Textures\\icon_accessibility",
    Audio         = "Interface\\AddOns\\CVarMaster\\Textures\\icon_audio",
    Camera        = "Interface\\AddOns\\CVarMaster\\Textures\\icon_camera",
    Chat          = "Interface\\AddOns\\CVarMaster\\Textures\\icon_chat",
    Combat        = "Interface\\AddOns\\CVarMaster\\Textures\\icon_combat",
    Controls      = "Interface\\AddOns\\CVarMaster\\Textures\\icon_controls",
    Graphics      = "Interface\\AddOns\\CVarMaster\\Textures\\icon_graphics",
    Interface     = "Interface\\AddOns\\CVarMaster\\Textures\\icon_interface",
    Nameplates    = "Interface\\AddOns\\CVarMaster\\Textures\\icon_nameplates",
    Network       = "Interface\\AddOns\\CVarMaster\\Textures\\icon_network",
    Other         = "Interface\\AddOns\\CVarMaster\\Textures\\icon_other",
    ["New in 12.0"] = "Interface\\AddOns\\CVarMaster\\Textures\\icon_new",
    Performance   = "Interface\\AddOns\\CVarMaster\\Textures\\icon_performance",
    ["Raid & Party"] = "Interface\\AddOns\\CVarMaster\\Textures\\icon_raid",
    Social        = "Interface\\AddOns\\CVarMaster\\Textures\\icon_social",
    Targeting     = "Interface\\AddOns\\CVarMaster\\Textures\\icon_targeting",
    Tooltips      = "Interface\\AddOns\\CVarMaster\\Textures\\icon_tooltips",
    World         = "Interface\\AddOns\\CVarMaster\\Textures\\icon_world",
}

---Create the category list
function GUI:CreateCategoryList(parent)
    -- Scroll container below search box
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetPoint("TOPLEFT", 0, -44)
    scrollFrame:SetPoint("BOTTOMRIGHT", 0, 42)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(Constants.GUI.CATEGORY_WIDTH or 190)
    scrollFrame:SetScrollChild(scrollChild)

    -- Mouse wheel scrolling
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local contentH = scrollChild:GetHeight()
        local viewH = self:GetHeight()
        local range = contentH - viewH
        if range <= 0 then return end
        local step = 28
        local current = self:GetVerticalScroll()
        local newScroll = math.max(0, math.min(range, current - delta * step))
        self:SetVerticalScroll(newScroll)
    end)

    local yOffset = -4

    -- "All" button first
    local allBtn = self:CreateCategoryButton(scrollChild, "All", yOffset, "All")
    categoryButtons["All"] = allBtn
    yOffset = yOffset - 30
    
    -- Divider
    local divider = scrollChild:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("LEFT", 16, 0)
    divider:SetPoint("RIGHT", -16, 0)
    divider:SetPoint("TOP", 0, yOffset)
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(divider, 0.2) end
    if GUI.DisableSharpening then GUI.DisableSharpening(divider) end
    yOffset = yOffset - S("SM")
    
    -- Category buttons
    local categoryNames = {}
    for _, name in pairs(Constants.CATEGORIES) do
        table.insert(categoryNames, name)
    end
    table.sort(categoryNames)
    
    for _, catName in ipairs(categoryNames) do
        local btn = self:CreateCategoryButton(scrollChild, catName, yOffset, catName)
        categoryButtons[catName] = btn
        yOffset = yOffset - 28
    end
    
    -- Set scroll child height to fit all content
    scrollChild:SetHeight(math.abs(yOffset) + 10)
    
    -- Select "All" by default
    self:SelectCategory("All")
end

---Create a single category button
function GUI:CreateCategoryButton(parent, text, yOffset, categoryKey)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(26)
    btn:SetPoint("TOPLEFT", S("XS"), yOffset)
    btn:SetPoint("TOPRIGHT", -S("XS"), yOffset)
    btn.categoryKey = categoryKey or text
    
    -- Background (shows on hover/selected)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0, 0, 0, 0)
    
    -- Selection indicator (left bar)
    btn.indicator = btn:CreateTexture(nil, "ARTWORK")
    btn.indicator:SetWidth(3)
    btn.indicator:SetPoint("TOPLEFT", 0, -2)
    btn.indicator:SetPoint("BOTTOMLEFT", 0, 2)
    if GUI.RegisterAccentTexture then GUI:RegisterAccentTexture(btn.indicator, 1.0) end
    if GUI.DisableSharpening then GUI.DisableSharpening(btn.indicator) end
    btn.indicator:Hide()
    
    -- Category icon
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetSize(18, 18)
    btn.icon:SetPoint("LEFT", S("SM"), 0)
    local iconPath = CATEGORY_ICONS[text] or CATEGORY_ICONS["Other"]
    btn.icon:SetTexture(iconPath)
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim icon borders
    
    -- Desaturate unselected icons slightly
    btn.icon:SetDesaturated(true)
    btn.icon:SetVertexColor(0.7, 0.7, 0.7)
    
    -- Category name (positioned after icon)
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("LEFT", btn.icon, "RIGHT", S("SM"), 0)
    btn.text:SetText(text)
    btn.text:SetWordWrap(false)
    btn.text:SetWidth(120)
    btn.text:SetTextColor(T("CAT_NORMAL"))
    
    -- Count badge
    btn.countText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.countText:SetPoint("RIGHT", -S("SM"), 0)
    btn.countText:SetTextColor(T("TEXT_MUTED"))
    btn.countText:SetText("")
    
    -- Set hover bg color once (we'll fade alpha)
    btn.bg:SetColorTexture(T("CAT_HOVER_BG"))
    if GUI.DisableSharpening then GUI.DisableSharpening(btn.bg) end
    btn.bg:SetAlpha(0)

    btn:SetScript("OnEnter", function(self)
        if selectedCategory ~= self.categoryKey then
            GUI.SmoothFade(self.bg, 1, 0.12)
            self.icon:SetDesaturated(false)
            self.icon:SetVertexColor(1, 1, 1)
        end
        self.text:SetTextColor(T("TEXT_ACCENT"))
    end)

    btn:SetScript("OnLeave", function(self)
        if selectedCategory ~= self.categoryKey then
            GUI.SmoothFade(self.bg, 0, 0.15)
            self.icon:SetDesaturated(true)
            self.icon:SetVertexColor(0.7, 0.7, 0.7)
            self.text:SetTextColor(T("CAT_NORMAL"))
        else
            self.text:SetTextColor(T("CAT_SELECTED"))
        end
    end)
    
    btn:SetScript("OnClick", function(self)
        GUI:SelectCategory(self.categoryKey)
    end)
    
    return btn
end

---Select a category
function GUI:SelectCategory(categoryKey)
    local oldSelected = selectedCategory
    selectedCategory = categoryKey
    
    -- Update button states with smooth transitions
    for key, btn in pairs(categoryButtons) do
        if key == categoryKey then
            btn.bg:SetColorTexture(T("CAT_SELECTED_BG"))
            GUI.SmoothFade(btn.bg, 1, 0.15)
            btn.text:SetTextColor(T("CAT_SELECTED"))
            btn.indicator:Show()
            btn.icon:SetDesaturated(false)
            btn.icon:SetVertexColor(1, 1, 1)
        else
            btn.bg:SetColorTexture(T("CAT_HOVER_BG"))
            GUI.SmoothFade(btn.bg, 0, 0.1)
            btn.text:SetTextColor(T("CAT_NORMAL"))
            btn.indicator:Hide()
            btn.icon:SetDesaturated(true)
            btn.icon:SetVertexColor(0.7, 0.7, 0.7)
        end
    end
    
    -- Refresh list if category changed
    if oldSelected ~= categoryKey then
        GUI:RefreshCVarList()
    end
end

---Get selected category
function GUI:GetSelectedCategory()
    return selectedCategory
end

---Update category counts
---@param categoryCounts table Map of category NAME to count
function GUI:UpdateCategoryCounts(categoryCounts)
    local totalCount = 0
    
    for catName, count in pairs(categoryCounts) do
        totalCount = totalCount + count
        if categoryButtons[catName] then
            categoryButtons[catName].countText:SetText(tostring(count))
        end
    end
    
    if categoryButtons["All"] then
        categoryButtons["All"].countText:SetText(tostring(totalCount))
    end
end
