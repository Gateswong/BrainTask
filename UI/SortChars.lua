-- BrainTask UI: 角色管理窗口

BrainTask = BrainTask or {}
BrainTask.UI = BrainTask.UI or {}
local BT = BrainTask
BT.UI.SortChars = {}
local SC = BT.UI.SortChars

local WIN_W, WIN_H = 300, 460
local ROW_H = 32
local ROW_GAP = 2
local ROW_STRIDE = ROW_H + ROW_GAP

-- ── 主框架 ────────────────────────────────────────────────────────────────

local frame = BT.CreateBackdropFrame("Frame", "BrainTaskSortChars", UIParent, WIN_W, WIN_H)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:EnableMouse(true)
frame:SetToplevel(true)
frame:SetScript("OnMouseDown", function(self) self:Raise() end)
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
titleFS:SetText("|cff55aaff" .. BT.L.TITLE_CHAR_MGMT .. "|r")

local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetSize(20, 20)
closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -8, 0)
local closeTex = closeBtn:CreateTexture(nil, "ARTWORK")
closeTex:SetAllPoints()
closeTex:SetAtlas("uitools-icon-close")
closeBtn:SetScript("OnClick", function() frame:Hide() end)
closeBtn:SetScript("OnEnter", function() closeTex:SetVertexColor(1, 0.3, 0.3) end)
closeBtn:SetScript("OnLeave", function() closeTex:SetVertexColor(1, 1, 1) end)

-- 说明文字
local hintFS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hintFS:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -36)
hintFS:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -36)
hintFS:SetText(BT.L.CHAR_HINT)
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

-- ── 拖拽系统 ──────────────────────────────────────────────────────────────

local dragState = nil  -- { fromIdx, targetIdx }

local dragGhost = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dragGhost:SetTextColor(1, 1, 0.5)
dragGhost:Hide()

local dropLine = CreateFrame("Frame", nil, frame, "BackdropTemplate")
dropLine:SetHeight(2)
dropLine:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
dropLine:SetBackdropColor(0.3, 0.7, 1, 1)
dropLine:Hide()

local dragOverlay = CreateFrame("Frame", nil, frame)
dragOverlay:SetAllPoints()
dragOverlay:SetFrameStrata("TOOLTIP")
dragOverlay:EnableMouse(true)
dragOverlay:Hide()

local function GetTargetIdx(cy)
    local scale = UIParent:GetEffectiveScale()
    local contentTop = content:GetTop()
    if not contentTop then return 1 end
    local relY = (cy / scale) - contentTop
    local idx = math.floor(-relY / ROW_STRIDE) + 1
    return math.max(1, math.min(#rows, idx))
end

local function UpdateDropLine(targetIdx)
    local lineY
    if targetIdx <= 1 then
        lineY = 0
    else
        lineY = -(targetIdx - 1) * ROW_STRIDE
    end
    dropLine:ClearAllPoints()
    dropLine:SetPoint("TOPLEFT",  content, "TOPLEFT",  4, lineY)
    dropLine:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, lineY)
    dropLine:Show()
end

dragOverlay:SetScript("OnUpdate", function()
    if not dragState then return end
    local cx, cy = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    dragGhost:ClearAllPoints()
    dragGhost:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx / scale + 10, cy / scale)
    local targetIdx = GetTargetIdx(cy)
    dragState.targetIdx = targetIdx
    UpdateDropLine(targetIdx)
end)

dragOverlay:SetScript("OnMouseUp", function()
    if not dragState then return end
    local from = dragState.fromIdx
    local to   = dragState.targetIdx or from
    if from ~= to then
        local order = BrainTaskDB.charOrder
        local item = table.remove(order, from)
        -- 插入位置需修正：如果 to > from，remove 后 to 应减 1
        local insertAt = (to > from) and (to - 1) or to
        table.insert(order, insertAt, item)
    end
    dragState = nil
    dragGhost:Hide()
    dropLine:Hide()
    dragOverlay:Hide()
    SC.Refresh()
    if BT.UI.Dashboard then BT.UI.Dashboard.Refresh() end
end)

-- ── 渲染列表 ──────────────────────────────────────────────────────────────

function SC.Refresh()
    for _, r in ipairs(rows) do r:Hide() end
    rows = {}

    local order = BrainTaskDB and BrainTaskDB.charOrder
    if not order then return end

    local ck     = BT.charKey
    local hidden = BrainTaskDB.hiddenChars or {}
    local y      = 0

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

            -- 角色名 + 服务器
            local nameStr = (info.name or key)
                .. " |cff505060" .. (info.realm or "") .. "|r"
                .. (key == ck and " |cff55aaff" .. BT.L.CURRENT_CHAR .. "|r" or "")
            local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameFS:SetPoint("LEFT",  row, "LEFT",  10, 0)
            nameFS:SetPoint("RIGHT", row, "RIGHT", -30, 0)
            nameFS:SetJustifyH("LEFT")
            nameFS:SetText(nameStr)

            local classKey = info.class
            local clr = classKey and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classKey]
            if clr then
                nameFS:SetTextColor(clr.r, clr.g, clr.b)
            else
                nameFS:SetTextColor(unpack(BT.COLORS.textNormal))
            end

            -- 可见性切换按钮
            local isHidden = hidden[key]
            local visBtn = CreateFrame("Button", nil, row)
            visBtn:SetSize(20, 20)
            visBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            local visTex = visBtn:CreateTexture(nil, "ARTWORK")
            visTex:SetAllPoints()
            visTex:SetAtlas(isHidden and "GM-icon-visibleDis-pressed" or "GM-icon-visible-hover")
            local capturedKey = key
            visBtn:SetScript("OnClick", function()
                local db = BrainTaskDB
                db.hiddenChars = db.hiddenChars or {}
                if db.hiddenChars[capturedKey] then
                    db.hiddenChars[capturedKey] = nil
                else
                    db.hiddenChars[capturedKey] = true
                end
                visTex:SetAtlas(db.hiddenChars[capturedKey] and "GM-icon-visibleDis-pressed" or "GM-icon-visible-hover")
                if BT.UI.Dashboard then BT.UI.Dashboard.Refresh() end
            end)

            -- 整行可拖拽（visBtn 会消耗自己的 OnMouseDown，不会传到 row）
            row:EnableMouse(true)
            local capturedIdx = idx
            local capturedName = info.name or key
            row:SetScript("OnMouseDown", function(_, btn)
                if btn ~= "LeftButton" then return end
                dragState = { fromIdx = capturedIdx, targetIdx = capturedIdx }
                dragGhost:SetText(capturedName)
                dragGhost:Show()
                dragOverlay:Show()
            end)
            row:SetScript("OnMouseUp", function(_, btn)
                if btn ~= "LeftButton" or not dragState then return end
                local from = dragState.fromIdx
                local to   = dragState.targetIdx or from
                if from ~= to then
                    local order = BrainTaskDB.charOrder
                    local item = table.remove(order, from)
                    local insertAt = (to > from) and (to - 1) or to
                    table.insert(order, insertAt, item)
                end
                dragState = nil
                dragGhost:Hide()
                dropLine:Hide()
                dragOverlay:Hide()
                SC.Refresh()
                if BT.UI.Dashboard then BT.UI.Dashboard.Refresh() end
            end)

            table.insert(rows, row)
            y = y + ROW_STRIDE
        end
    end

    content:SetHeight(math.max(y, 10))
end

-- ── 本地化刷新 ────────────────────────────────────────────────────────────

BT.Locale.Register(function()
    titleFS:SetText("|cff55aaff" .. BT.L.TITLE_CHAR_MGMT .. "|r")
    hintFS:SetText(BT.L.CHAR_HINT)
end)

-- ── 公共接口 ──────────────────────────────────────────────────────────────

function SC.Open()
    SC.Refresh()
    frame:Show()
end

function SC.Close()
    frame:Hide()
end
