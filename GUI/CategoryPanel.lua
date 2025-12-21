---@class CVarMaster
local ADDON_NAME, CVarMaster = ...

local GUI = CVarMaster.GUI
local Constants = CVarMaster.Constants

-- Currently selected category
local selectedCategory = "All"
local categoryButtons = {}

---Create the category list
function GUI:CreateCategoryList(parent)
    local yOffset = -44 -- Below search box
    
    -- "All" button first
    local allBtn = self:CreateCategoryButton(parent, "All", yOffset, "All")
    categoryButtons["All"] = allBtn
    yOffset = yOffset - 26
    
    -- Divider
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("LEFT", 8, 0)
    divider:SetPoint("RIGHT", -8, 0)
    divider:SetPoint("TOP", 0, yOffset)
    divider:SetColorTexture(0.2, 0.5, 0.2, 0.4)
    yOffset = yOffset - 8
    
    -- Category buttons - use the category NAME as key (e.g., "Camera", "Graphics")
    local categoryNames = {}
    for _, name in pairs(Constants.CATEGORIES) do
        table.insert(categoryNames, name)
    end
    table.sort(categoryNames)
    
    for _, catName in ipairs(categoryNames) do
        local btn = self:CreateCategoryButton(parent, catName, yOffset, catName)
        categoryButtons[catName] = btn
        yOffset = yOffset - 24
    end
    
    -- Select "All" by default
    self:SelectCategory("All")
end

---Create a single category button
function GUI:CreateCategoryButton(parent, text, yOffset, categoryKey)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(22)
    btn:SetPoint("TOPLEFT", 6, yOffset)
    btn:SetPoint("TOPRIGHT", -6, yOffset)
    btn.categoryKey = categoryKey or text
    
    -- Background (shows on hover/selected)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.1, 0.4, 0.1, 0)
    
    -- Category name
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("LEFT", 8, 0)
    btn.text:SetText(text)
    btn.text:SetTextColor(0.7, 0.7, 0.7)
    
    -- Count badge
    btn.countText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.countText:SetPoint("RIGHT", -8, 0)
    btn.countText:SetTextColor(0.5, 0.5, 0.5)
    btn.countText:SetText("")
    
    btn:SetScript("OnEnter", function(self)
        if selectedCategory ~= self.categoryKey then
            self.bg:SetColorTexture(0.15, 0.4, 0.15, 0.5)
        end
        self.text:SetTextColor(0.9, 1, 0.9)
    end)
    
    btn:SetScript("OnLeave", function(self)
        if selectedCategory ~= self.categoryKey then
            self.bg:SetColorTexture(0.1, 0.4, 0.1, 0)
        end
        if selectedCategory == self.categoryKey then
            self.text:SetTextColor(0, 1, 0)
        else
            self.text:SetTextColor(0.7, 0.7, 0.7)
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
            btn.bg:SetColorTexture(0.1, 0.5, 0.1, 0.7)
            btn.text:SetTextColor(0, 1, 0)
        else
            btn.bg:SetColorTexture(0.1, 0.4, 0.1, 0)
            btn.text:SetTextColor(0.7, 0.7, 0.7)
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
---@param categoryCounts table Map of category NAME to count (e.g., {["Camera"] = 50, ["Graphics"] = 120})
function GUI:UpdateCategoryCounts(categoryCounts)
    local totalCount = 0
    
    -- Count total and update each category button
    for catName, count in pairs(categoryCounts) do
        totalCount = totalCount + count
        if categoryButtons[catName] then
            categoryButtons[catName].countText:SetText(tostring(count))
        end
    end
    
    -- Update "All" count with total
    if categoryButtons["All"] then
        categoryButtons["All"].countText:SetText(tostring(totalCount))
    end
end
