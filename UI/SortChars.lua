-- BrainTask UI: 角色排序窗口

BrainTask = BrainTask or {}
BrainTask.UI = BrainTask.UI or {}
local BT = BrainTask
BT.UI.SortChars = {}
local SC = BT.UI.SortChars

local WIN_W, WIN_H = 280, 460
local ROW_H = 32

-- ── 主框架 ────────────────────────────────────────────────────────────────

local frame = BT.CreateBackdropFrame("Frame", "BrainTaskSortChars", UIParent, WIN_W, WIN_H)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:EnableMouse(true)
frame:Hide()

-- 标题栏
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
titleFS:SetText("|cff55aaff角色排序|r")

local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetSize(20, 20)
closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -8, 0)
local cX = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cX:SetAllPoints() cX:SetText("X") cX:SetTextColor(0.6, 0.6, 0.65)
closeBtn:SetScript("OnClick", function() frame:Hide() end)
closeBtn:SetScript("OnEnter", function() cX:SetTextColor(1, 0.3, 0.3) end)
closeBtn:SetScript("OnLeave", function() cX:SetTextColor(0.6, 0.6, 0.65) end)

-- 说明文字
local hintFS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hintFS:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -36)
hintFS:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -36)
hintFS:SetText("当前角色始终显示在 Dashboard 第一列")
hintFS:SetTextColor(unpack(BT.COLORS.textMuted))
hintFS:SetJustifyH("LEFT")

-- ── 滚动列表 ──────────────────────────────────────────────────────────────

local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT",    frame, "TOPLEFT",    6, -54)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 10)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetWidth(scrollFrame:GetWidth())
content:SetHeight(1)
scrollFrame:SetScrollChild(content)

local rows = {}

-- ── 渲染列表 ──────────────────────────────────────────────────────────────

local function SwapOrder(i, j)
    local order = BrainTaskDB.charOrder
    order[i], order[j] = order[j], order[i]
end

function SC.Refresh()
    for _, r in ipairs(rows) do r:Hide() end
    rows = {}

    local order = BrainTaskDB and BrainTaskDB.charOrder
    if not order then return end

    local ck = BT.charKey
    local y  = 0

    for idx, key in ipairs(order) do
        local info = BrainTaskDB.knownChars[key]
        if info then
            local row = CreateFrame("Frame", nil, content)
            row:SetHeight(ROW_H)
            row:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -y)
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)

            -- 交替背景
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(1, 1, 1, (#rows % 2 == 0) and 0.05 or 0.02)

            -- 角色名 + 职业
            local nameStr = info.name or key
            if key == ck then
                nameStr = nameStr .. " |cff55aaff(当前)|r"
            end
            local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameFS:SetPoint("LEFT", row, "LEFT", 10, 0)
            nameFS:SetPoint("RIGHT", row, "RIGHT", -52, 0)
            nameFS:SetJustifyH("LEFT")
            nameFS:SetText(nameStr)
            nameFS:SetTextColor(unpack(BT.COLORS.textNormal))

            -- ↑ 按钮
            local upBtn = CreateFrame("Button", nil, row)
            upBtn:SetSize(20, 20)
            upBtn:SetPoint("RIGHT", row, "RIGHT", -28, 0)
            local upFS = upBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            upFS:SetAllPoints() upFS:SetText("↑")
            if idx == 1 then
                upFS:SetTextColor(0.3, 0.3, 0.35)
            else
                upFS:SetTextColor(0.6, 0.7, 0.9)
                upBtn:SetScript("OnEnter", function() upFS:SetTextColor(0.3, 0.7, 1) end)
                upBtn:SetScript("OnLeave", function() upFS:SetTextColor(0.6, 0.7, 0.9) end)
                local i = idx
                upBtn:SetScript("OnClick", function()
                    SwapOrder(i, i - 1)
                    SC.Refresh()
                    if BT.UI.Dashboard then BT.UI.Dashboard.Refresh() end
                end)
            end

            -- ↓ 按钮
            local downBtn = CreateFrame("Button", nil, row)
            downBtn:SetSize(20, 20)
            downBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            local downFS = downBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            downFS:SetAllPoints() downFS:SetText("↓")
            if idx == #order then
                downFS:SetTextColor(0.3, 0.3, 0.35)
            else
                downFS:SetTextColor(0.6, 0.7, 0.9)
                downBtn:SetScript("OnEnter", function() downFS:SetTextColor(0.3, 0.7, 1) end)
                downBtn:SetScript("OnLeave", function() downFS:SetTextColor(0.6, 0.7, 0.9) end)
                local i = idx
                downBtn:SetScript("OnClick", function()
                    SwapOrder(i, i + 1)
                    SC.Refresh()
                    if BT.UI.Dashboard then BT.UI.Dashboard.Refresh() end
                end)
            end

            table.insert(rows, row)
            y = y + ROW_H + 2
        end
    end

    content:SetHeight(math.max(y, 10))
end

-- ── 公共接口 ──────────────────────────────────────────────────────────────

function SC.Open()
    SC.Refresh()
    frame:Show()
end

function SC.Close()
    frame:Hide()
end
