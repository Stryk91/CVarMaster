---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local Constants = CVarMaster.Constants

-- Currently selected category
local selectedCategory = "All"
local categoryButtons = {}

-- Local theme helper
local function T(key)
    if Constants and Constants.THEME and Constants.THEME[key] then
        return unpack(Constants.THEME[key])
    end
    return 0.5, 0.5, 0.5, 1.0
end

local function S(key)
    if Constants and Constants.SPACING then
        return Constants.SPACING[key] or 8
    end
    return 8
end

-- Category icons using WoW built-in textures
local CATEGORY_ICONS = {
    All           = "Interface\\Icons\\INV_Misc_Map_01",
    Accessibility = "Interface\\Icons\\Spell_Holy_ElunesGrace",
    Audio         = "Interface\\Icons\\INV_Misc_Ear_Human_01",
    Camera        = "Interface\\Icons\\INV_Misc_SpyGlass_03",
    Chat          = "Interface\\Icons\\INV_Letter_15",
    Combat        = "Interface\\Icons\\Ability_DualWield",
    Controls      = "Interface\\Icons\\INV_Misc_Gear_01",
    Graphics      = "Interface\\Icons\\INV_Gizmo_02",
    Interface     = "Interface\\Icons\\INV_Misc_Book_09",
    Nameplates    = "Interface\\Icons\\Spell_ChargePositive",
    Network       = "Interface\\Icons\\INV_Misc_EngGizmos_27",
    Other         = "Interface\\Icons\\INV_Misc_QuestionMark",
    Performance   = "Interface\\Icons\\Inv_Misc_PocketWatch_01",
    ["Raid & Party"] = "Interface\\Icons\\Achievement_BG_winAB_underXminutes",
    Social        = "Interface\\Icons\\INV_Misc_GroupNeedMore",
    Targeting     = "Interface\\Icons\\Ability_Hunter_SniperShot",
    Tooltips      = "Interface\\Icons\\INV_Misc_Note_01",
    World         = "Interface\\Icons\\INV_Misc_Map08",
}

---Create the category list
function GUI:CreateCategoryList(parent)
    local yOffset = -48 -- Below search box
    
    -- "All" button first
    local allBtn = self:CreateCategoryButton(parent, "All", yOffset, "All")
    categoryButtons["All"] = allBtn
    yOffset = yOffset - 30
    
    -- Divider
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("LEFT", S("SM"), 0)
    divider:SetPoint("RIGHT", -S("SM"), 0)
    divider:SetPoint("TOP", 0, yOffset)
    divider:SetColorTexture(T("BORDER_SUBTLE"))
    yOffset = yOffset - S("SM")
    
    -- Category buttons
    local categoryNames = {}
    for _, name in pairs(Constants.CATEGORIES) do
        table.insert(categoryNames, name)
    end
    table.sort(categoryNames)
    
    for _, catName in ipairs(categoryNames) do
        local btn = self:CreateCategoryButton(parent, catName, yOffset, catName)
        categoryButtons[catName] = btn
        yOffset = yOffset - 28
    end
    
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
    btn.indicator:SetColorTexture(T("ACCENT_PRIMARY"))
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
    btn.text:SetTextColor(T("CAT_NORMAL"))
    
    -- Count badge
    btn.countText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.countText:SetPoint("RIGHT", -S("SM"), 0)
    btn.countText:SetTextColor(T("TEXT_MUTED"))
    btn.countText:SetText("")
    
    btn:SetScript("OnEnter", function(self)
        if selectedCategory ~= self.categoryKey then
            self.bg:SetColorTexture(T("CAT_HOVER_BG"))
            self.icon:SetDesaturated(false)
            self.icon:SetVertexColor(1, 1, 1)
        end
        self.text:SetTextColor(T("TEXT_ACCENT"))
    end)
    
    btn:SetScript("OnLeave", function(self)
        if selectedCategory ~= self.categoryKey then
            self.bg:SetColorTexture(0, 0, 0, 0)
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
    
    -- Update button states
    for key, btn in pairs(categoryButtons) do
        if key == categoryKey then
            btn.bg:SetColorTexture(T("CAT_SELECTED_BG"))
            btn.text:SetTextColor(T("CAT_SELECTED"))
            btn.indicator:Show()
            btn.icon:SetDesaturated(false)
            btn.icon:SetVertexColor(1, 1, 1)
        else
            btn.bg:SetColorTexture(0, 0, 0, 0)
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
