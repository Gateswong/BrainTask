-- BrainTask UI: 设置弹窗（分类管理）

BrainTask = BrainTask or {}
BrainTask.UI = BrainTask.UI or {}
local BT = BrainTask
BT.UI.Settings = {}
local ST = BT.UI.Settings

local WIN_W, WIN_H = 380, 480

-- ── 主框架 ────────────────────────────────────────────────────────────────

local frame = BT.CreateBackdropFrame("Frame", "BrainTaskSettings", UIParent, WIN_W, WIN_H)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:EnableMouse(true)
frame:SetToplevel(true)
frame:SetScript("OnMouseDown", function(self) self:Raise() end)
frame:Hide()

-- 标题
local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
titleBar:SetHeight(30)
titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
titleBar:SetBackdrop(BT.BACKDROP)
titleBar:SetBackdropColor(unpack(BT.COLORS.header))
titleBar:SetBackdropBorderColor(unpack(BT.COLORS.border))

BT.MakeDraggable(frame, titleBar)

local titleFS = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleFS:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
titleFS:SetText("|cff55aaff分类管理|r")

local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetSize(20, 20)
closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -8, 0)
local closeTex = closeBtn:CreateTexture(nil, "ARTWORK")
closeTex:SetAllPoints()
closeTex:SetAtlas("uitools-icon-close")
closeBtn:SetScript("OnClick", function() frame:Hide() end)
closeBtn:SetScript("OnEnter", function() closeTex:SetVertexColor(1, 0.3, 0.3) end)
closeBtn:SetScript("OnLeave", function() closeTex:SetVertexColor(1, 1, 1) end)

-- ── 分类列表（滚动）──────────────────────────────────────────────────────

local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT",    frame, "TOPLEFT",    6, -36)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 80)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetWidth(scrollFrame:GetWidth())
content:SetHeight(1)
scrollFrame:SetScrollChild(content)

local catRows = {}

-- 删除确认弹窗（内嵌）
local confirmFrame = BT.CreateBackdropFrame("Frame", nil, frame, 260, 100)
confirmFrame:SetPoint("CENTER", frame, "CENTER")
confirmFrame:SetFrameStrata("DIALOG")
confirmFrame:EnableMouse(true)
confirmFrame:Hide()

local confirmFS = confirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
confirmFS:SetPoint("CENTER", confirmFrame, "CENTER", 0, 18)
confirmFS:SetText("此分类下有关联事项，\n确定要删除并解除关联？")
confirmFS:SetTextColor(1, 0.8, 0.2)

local confirmYes = BT.CreateButton(confirmFrame, "删除", 90, 24)
confirmYes:SetPoint("BOTTOMRIGHT", confirmFrame, "BOTTOM", -4, 8)

local confirmNo = BT.CreateButton(confirmFrame, "取消", 90, 24)
confirmNo:SetPoint("BOTTOMLEFT", confirmFrame, "BOTTOM", 4, 8)
confirmNo:SetScript("OnClick", function() confirmFrame:Hide() end)

local function TryDeleteCategory(catID)
    -- 检查是否有关联事项
    local hasLinked = false
    for _, todo in pairs(BrainTaskDB.todos) do
        if todo.categoryID == catID then
            hasLinked = true
            break
        end
    end
    if hasLinked then
        confirmYes:SetScript("OnClick", function()
            BT.Data.DeleteCategory(catID)
            confirmFrame:Hide()
            ST.Refresh()
        end)
        confirmFrame:Show()
    else
        BT.Data.DeleteCategory(catID)
        ST.Refresh()
    end
end

-- ── 内联编辑 EditBox ───────────────────────────────────────────────────────

local editingCatID = nil

local inlineBox = CreateFrame("EditBox", nil, content, "BackdropTemplate")
inlineBox:SetSize(220, 22)
inlineBox:SetBackdrop(BT.BACKDROP)
inlineBox:SetBackdropColor(0.10, 0.10, 0.14, 1)
inlineBox:SetBackdropBorderColor(unpack(BT.COLORS.accent))
inlineBox:SetFont("Fonts/FRIZQT__.TTF", 11, "")
inlineBox:SetTextColor(0.9, 0.9, 0.9)
inlineBox:SetAutoFocus(false)
inlineBox:SetMaxLetters(64)
inlineBox:Hide()

inlineBox:SetScript("OnEnterPressed", function(self)
    local txt = self:GetText()
    if txt and txt ~= "" and editingCatID then
        BT.Data.UpdateCategory(editingCatID, txt)
        editingCatID = nil
        self:Hide()
        ST.Refresh()
    end
end)
inlineBox:SetScript("OnEscapePressed", function(self)
    editingCatID = nil
    self:Hide()
end)

-- ── 渲染分类列表 ──────────────────────────────────────────────────────────

function ST.Refresh()
    for _, r in ipairs(catRows) do r:Hide() end
    catRows = {}
    inlineBox:Hide()
    editingCatID = nil

    local cats = BT.Data.GetCategories()
    local y = 0
    local ROW_H = 30

    for _, cat in ipairs(cats) do
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -y)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, (#catRows % 2 == 0) and 0.05 or 0.02)

        local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameFS:SetPoint("LEFT",  row, "LEFT", 12, 0)
        nameFS:SetPoint("RIGHT", row, "RIGHT", -70, 0)
        nameFS:SetJustifyH("LEFT")
        nameFS:SetText(cat.title)
        nameFS:SetTextColor(unpack(BT.COLORS.textNormal))

        -- 编辑按钮
        local editBtn = CreateFrame("Button", nil, row)
        editBtn:SetSize(20, 20)
        editBtn:SetPoint("RIGHT", row, "RIGHT", -36, 0)
        local eTex = editBtn:CreateTexture(nil, "ARTWORK")
        eTex:SetAllPoints()
        eTex:SetAtlas("lorewalking-map-icon")
        editBtn:SetScript("OnEnter", function() eTex:SetVertexColor(0.3, 0.7, 1) end)
        editBtn:SetScript("OnLeave", function() eTex:SetVertexColor(1, 1, 1) end)
        local catID = cat.id
        editBtn:SetScript("OnClick", function()
            editingCatID = catID
            inlineBox:SetPoint("LEFT", row, "LEFT", 10, 0)
            inlineBox:SetPoint("RIGHT", row, "RIGHT", -70, 0)
            inlineBox:SetText(cat.title)
            inlineBox:SetParent(row)
            inlineBox:Show()
            inlineBox:SetFocus()
            inlineBox:HighlightText()
        end)

        -- 删除按钮
        local delBtn = CreateFrame("Button", nil, row)
        delBtn:SetSize(20, 20)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        local dTex = delBtn:CreateTexture(nil, "ARTWORK")
        dTex:SetAllPoints()
        dTex:SetAtlas("SCRAP-activated")
        delBtn:SetScript("OnEnter", function() dTex:SetVertexColor(1, 0.3, 0.3) end)
        delBtn:SetScript("OnLeave", function() dTex:SetVertexColor(1, 1, 1) end)
        delBtn:SetScript("OnClick", function() TryDeleteCategory(catID) end)

        table.insert(catRows, row)
        y = y + ROW_H + 2
    end

    content:SetHeight(math.max(y, 10))
end

-- ── 底部：添加分类 ────────────────────────────────────────────────────────

local addBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
addBar:SetHeight(56)
addBar:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  0, 0)
addBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
addBar:SetBackdrop(BT.BACKDROP)
addBar:SetBackdropColor(unpack(BT.COLORS.header))
addBar:SetBackdropBorderColor(unpack(BT.COLORS.border))

local addLabel = addBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
addLabel:SetPoint("TOPLEFT", addBar, "TOPLEFT", 12, -8)
addLabel:SetText("新分类名称")
addLabel:SetTextColor(unpack(BT.COLORS.textMuted))

local newCatBox = CreateFrame("EditBox", nil, addBar, "BackdropTemplate")
newCatBox:SetSize(220, 24)
newCatBox:SetPoint("BOTTOMLEFT", addBar, "BOTTOMLEFT", 12, 8)
newCatBox:SetBackdrop(BT.BACKDROP)
newCatBox:SetBackdropColor(0.10, 0.10, 0.14, 1)
newCatBox:SetBackdropBorderColor(unpack(BT.COLORS.border))
newCatBox:SetFont("Fonts/FRIZQT__.TTF", 11, "")
newCatBox:SetTextColor(0.9, 0.9, 0.9)
newCatBox:SetAutoFocus(false)
newCatBox:SetMaxLetters(64)
newCatBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local addBtn = BT.CreateButton(addBar, "+ 添加", 90, 24)
addBtn:SetPoint("LEFT", newCatBox, "RIGHT", 8, 0)

local function DoAddCategory()
    local txt = newCatBox:GetText()
    if txt and txt ~= "" then
        BT.Data.CreateCategory(txt)
        newCatBox:SetText("")
        newCatBox:ClearFocus()
        ST.Refresh()
    end
end

addBtn:SetScript("OnClick", DoAddCategory)
newCatBox:SetScript("OnEnterPressed", DoAddCategory)

-- ── 公共接口 ──────────────────────────────────────────────────────────────

function ST.Open()
    ST.Refresh()
    frame:Show()
end

function ST.Close()
    frame:Hide()
end
