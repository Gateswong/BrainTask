-- BrainTask UI: 浮动小窗

BrainTask = BrainTask or {}
BrainTask.UI = BrainTask.UI or {}
local BT = BrainTask
BT.UI.FloatWindow = {}
local FW = BT.UI.FloatWindow

local WIN_W, WIN_H = 280, 420
local ROW_H = 24
local INDENT = 10

-- ── 主框架 ────────────────────────────────────────────────────────────────

local frame = BT.CreateBackdropFrame("Frame", "BrainTaskFloatWindow", UIParent, WIN_W, WIN_H)
frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -60, -200)
frame:SetFrameStrata("MEDIUM")
frame:EnableMouse(true)
frame:SetToplevel(true)
frame:SetScript("OnMouseDown", function(self) self:Raise() end)
frame:Hide()

-- 标题栏
local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
titleBar:SetHeight(28)
titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0,  0)
titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT",  0,  0)
titleBar:SetBackdrop(BT.BACKDROP)
titleBar:SetBackdropColor(unpack(BT.COLORS.header))
titleBar:SetBackdropBorderColor(unpack(BT.COLORS.border))

BT.MakeDraggable(frame, titleBar)
titleBar:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    if BrainTaskDB then
        BrainTaskDB.floatWindowPos = { x = frame:GetLeft(), y = frame:GetTop() }
    end
end)

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
titleText:SetText("|cff55aaffBrainTask|r")

-- 关闭按钮
local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetSize(20, 20)
closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
local closeTex = closeBtn:CreateTexture(nil, "ARTWORK")
closeTex:SetAllPoints()
closeTex:SetAtlas("uitools-icon-close")
closeBtn:SetScript("OnClick", function() frame:Hide() end)
closeBtn:SetScript("OnEnter", function() closeTex:SetVertexColor(1, 0.3, 0.3) end)
closeBtn:SetScript("OnLeave", function() closeTex:SetVertexColor(1, 1, 1) end)

-- Dashboard 链接按钮（标题栏，关闭按钮左侧）
local dashBtn = CreateFrame("Button", nil, titleBar)
dashBtn:SetSize(24, 24)
dashBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
local dashFS = dashBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
dashFS:SetAllPoints()
dashFS:SetText("≡")
dashFS:SetTextColor(0.6, 0.6, 0.65)
dashBtn:SetScript("OnClick", function()
    if BT.UI.Dashboard then BT.UI.Dashboard.Toggle() end
end)
dashBtn:SetScript("OnEnter", function() dashFS:SetTextColor(0.4, 0.8, 1) end)
dashBtn:SetScript("OnLeave", function() dashFS:SetTextColor(0.6, 0.6, 0.65) end)

-- ── 滚动区域 ──────────────────────────────────────────────────────────────

local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT",     frame, "TOPLEFT",   4,  -32)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 8)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetWidth(scrollFrame:GetWidth() - 4)
content:SetHeight(1)
scrollFrame:SetScrollChild(content)

-- 缩放手柄（右下角）
frame:SetResizable(true)
frame:SetResizeBounds(160, 200)

local resizeHandle = CreateFrame("Frame", nil, frame)
resizeHandle:SetSize(16, 16)
resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 5)
resizeHandle:EnableMouse(true)

local resizeTex = resizeHandle:CreateTexture(nil, "OVERLAY")
resizeTex:SetAllPoints()
resizeTex:SetColorTexture(0.4, 0.4, 0.5, 0.4)

resizeHandle:SetScript("OnEnter", function()
    resizeTex:SetColorTexture(0.5, 0.7, 1.0, 0.6)
end)
resizeHandle:SetScript("OnLeave", function()
    resizeTex:SetColorTexture(0.4, 0.4, 0.5, 0.4)
end)
resizeHandle:SetScript("OnMouseDown", function(self, btn)
    if btn == "LeftButton" then
        local x = frame:GetLeft()
        local y = frame:GetTop()
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
        frame:StartSizing("BOTTOMRIGHT")
    end
end)
resizeHandle:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    content:SetWidth(math.max(1, scrollFrame:GetWidth() - 4))
    if BrainTaskDB then
        BrainTaskDB.floatWindowSize = { w = frame:GetWidth(), h = frame:GetHeight() }
    end
end)

frame:SetScript("OnSizeChanged", function()
    content:SetWidth(math.max(1, scrollFrame:GetWidth() - 4))
end)

-- ── 备注 Frame（单例）────────────────────────────────────────────────────

local noteExpanded = true
local noteFrame    = nil

local function EnsureNoteFrame(parent)
    if noteFrame then
        noteFrame:SetParent(parent)
        return noteFrame
    end
    noteFrame = CreateFrame("Frame", nil, parent)
    noteFrame:SetHyperlinksEnabled(true)

    noteFrame.fs = noteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteFrame.fs:SetPoint("TOPLEFT",  noteFrame, "TOPLEFT",  INDENT + 22, -2)
    noteFrame.fs:SetPoint("TOPRIGHT", noteFrame, "TOPRIGHT", -6, -2)
    noteFrame.fs:SetJustifyH("LEFT")
    noteFrame.fs:SetWordWrap(true)
    noteFrame.fs:SetNonSpaceWrap(true)

    noteFrame:SetScript("OnHyperlinkClick", function(self, link, text, button)
        SetItemRef(link, text, button)
    end)
    noteFrame:SetScript("OnHyperlinkEnter", function(self, link, text)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    noteFrame:SetScript("OnHyperlinkLeave", function(self)
        GameTooltip:Hide()
    end)

    noteFrame:EnableMouse(true)
    noteFrame:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then
            noteExpanded = not noteExpanded
            FW.Refresh()
        end
    end)
    noteFrame:SetScript("OnEnter", function(self)
        if not noteExpanded and self.noteText and self.noteText ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.noteText, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end
    end)
    noteFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return noteFrame
end

-- ── 行池（复用 frame 对象）───────────────────────────────────────────────

local rowPool = {}

local function AcquireRow(parent)
    local row = table.remove(rowPool)
    if not row then
        row = CreateFrame("Frame", nil, parent)
        row:SetHeight(ROW_H)

        -- 复选框（自定义）
        local cb = CreateFrame("Button", nil, row)
        cb:SetSize(16, 16)
        cb:SetPoint("LEFT", row, "LEFT", INDENT, 0)

        local cbBg = cb:CreateTexture(nil, "BACKGROUND")
        cbBg:SetAllPoints()
        cbBg:SetColorTexture(0.18, 0.18, 0.24, 1)
        cb.bg = cbBg

        local cbCheck = cb:CreateTexture(nil, "OVERLAY")
        cbCheck:SetSize(14, 14)
        cbCheck:SetPoint("CENTER")
        cbCheck:SetTexture("Interface/Buttons/UI-CheckBox-Check")
        cbCheck:SetVertexColor(0.3, 0.9, 0.3, 1)
        cbCheck:Hide()
        cb.check = cbCheck

        cb:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.28, 0.28, 0.38, 1)
        end)
        cb:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0.18, 0.18, 0.24, 1)
        end)
        row.cb = cb

        -- 重置图标（右对齐，独立 FontString）
        local resetFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        resetFS:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        resetFS:SetJustifyH("RIGHT")
        resetFS:SetHeight(ROW_H)
        row.resetFS = resetFS

        -- 标题文字（右端锁定到 resetFS 左侧）
        local titleFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        titleFS:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        titleFS:SetPoint("RIGHT", resetFS, "LEFT", -2, 0)
        titleFS:SetJustifyH("LEFT")
        titleFS:SetHeight(ROW_H)
        row.titleFS = titleFS

        -- 行背景（hover）
        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        rowBg:SetColorTexture(0, 0, 0, 0)
        row.rowBg = rowBg

        -- 超链接支持（标题中的物品/成就链接可点击）
        row:SetHyperlinksEnabled(true)
        row:SetScript("OnHyperlinkClick", function(self, link, text, button)
            SetItemRef(link, text, button)
        end)
        row:SetScript("OnHyperlinkEnter", function(self, link, text)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end)
        row:SetScript("OnHyperlinkLeave", function(self)
            GameTooltip:Hide()
            if self.details and self.details ~= "" then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self.todoTitle or "", 1, 1, 1)
                GameTooltip:AddLine(self.details, 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end
        end)

        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            self.rowBg:SetColorTexture(1, 1, 1, 0.04)
            local showTip = false
            if self.details and self.details ~= "" then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self.todoTitle or "", 1, 1, 1)
                GameTooltip:AddLine(self.details, 0.8, 0.8, 0.8, true)
                showTip = true
            end
            if self.autoTrack and self.autoTrack.type == "currency" then
                if not showTip then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:ClearLines()
                    showTip = true
                end
                GameTooltip:AddLine(BT.L.TOOLTIP_AUTO_TRACK, 0.8, 0.8, 0.8, true)
                for _, cid in ipairs(self.autoTrack.currencyIDs or {}) do
                    local info = C_CurrencyInfo.GetCurrencyInfo(cid)
                    if info then
                        GameTooltip:AddLine("|T"..info.iconFileID..":14:14:0:0|t "..info.name, 1, 0.82, 0)
                    end
                end
            end
            if showTip then GameTooltip:Show() end
        end)
        row:SetScript("OnLeave", function(self)
            self.rowBg:SetColorTexture(0, 0, 0, 0)
            GameTooltip:Hide()
        end)
    else
        row:SetParent(parent)
    end
    row:Show()
    return row
end

local function ReleaseRow(row)
    row:Hide()
    row:SetParent(nil)
    row.cb:SetScript("OnClick", nil)
    row.details = nil
    row.todoTitle = nil
    row.autoTrack = nil
    row.resetFS:SetText("")
    table.insert(rowPool, row)
end

-- ── 渲染 ──────────────────────────────────────────────────────────────────

local activeRows  = {}
local activeHeads = {}

local function ClearContent()
    for _, r in ipairs(activeRows) do ReleaseRow(r) end
    activeRows = {}
    for _, h in ipairs(activeHeads) do h:Hide() end
    activeHeads = {}
    if noteFrame then noteFrame:Hide() end
end

local headerPool = {}

local function AcquireHeader(parent)
    local h = table.remove(headerPool)
    if not h then
        h = CreateFrame("Frame", nil, parent)
        h:SetHeight(20)
        local bg = h:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.14, 0.14, 0.20, 1)
        local fs = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", h, "LEFT", 6, 0)
        fs:SetTextColor(unpack(BT.COLORS.accent))
        h.fs = fs
    else
        h:SetParent(parent)
    end
    h:Show()
    return h
end

local function ReleaseHeader(h)
    h:Hide()
    h:SetParent(nil)
    table.insert(headerPool, h)
end

function FW.Refresh()
    if not frame:IsVisible() then return end
    ClearContent()

    local charKey = BT.charKey
    if not charKey then return end

    local totalCount, doneCount = 0, 0
    local yOffset  = 0
    local lastCat  = -1

    -- 角色备注（显示在所有事项之前）
    local charNote = BT.Data.GetCharNote(charKey)
    if charNote and charNote ~= "" then
        local nf = EnsureNoteFrame(content)
        nf.noteText = charNote
        nf:ClearAllPoints()
        nf:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -yOffset)
        nf:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -yOffset)

        if noteExpanded then
            nf.fs:SetText(charNote)
            nf.fs:SetTextColor(0.85, 0.85, 0.85)
            -- 按换行符数量估算行数（GetNumLines 在首次渲染前不可靠）
            local lineCount = 1
            for _ in charNote:gmatch("\n") do lineCount = lineCount + 1 end
            nf:SetHeight(lineCount * 14 + 6)
        else
            local firstLine = charNote:match("([^\n]*)")
            nf.fs:SetText(firstLine)
            nf.fs:SetTextColor(0.45, 0.45, 0.45)
            nf:SetHeight(ROW_H)
        end

        nf:Show()
        yOffset = yOffset + nf:GetHeight() + 2
    end

    local todos = BT.Data.GetTodosForChar(charKey)
    if #todos == 0 then
        content:SetHeight(math.max(yOffset + 10, 40))
        titleText:SetText("|cff55aaffBrainTask|r")
        return
    end

    for _, entry in ipairs(todos) do
        local todo      = entry.todo
        local completed = entry.completed

        totalCount = totalCount + 1
        if completed then doneCount = doneCount + 1 end

        -- 分类标题
        local catID = todo.categoryID
        if catID ~= lastCat then
            lastCat = catID
            local h = AcquireHeader(content)
            h:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -yOffset)
            h:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -yOffset)
            h.fs:SetText(BT.Data.GetCategoryTitle(catID))
            table.insert(activeHeads, h)
            yOffset = yOffset + 20
        end

        -- 事项行
        local row = AcquireRow(content)
        row:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -yOffset)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -yOffset)
        row.details   = todo.details
        row.todoTitle = todo.title
        row.autoTrack = todo.autoTrack

        -- 标题文字（完成则加删除线色）
        local scopeTag = todo.scope == "warband" and CreateAtlasMarkup("warbands-icon", 14, 14) .. " " or ""
        if completed then
            row.titleFS:SetText("|cff606060" .. todo.title .. "|r")
        else
            row.titleFS:SetText(scopeTag .. todo.title)
        end
        row.resetFS:SetText(BT.ResetTypeLabel(todo.resetType))

        -- 复选框状态
        if completed then
            row.cb.check:Show()
            row.cb.bg:SetColorTexture(0.10, 0.24, 0.10, 1)
        else
            row.cb.check:Hide()
            row.cb.bg:SetColorTexture(0.18, 0.18, 0.24, 1)
        end

        -- 点击回调（捕获闭包变量）
        local todoID      = todo.id
        local scope       = todo.scope
        local ck          = charKey
        local isCompleted = completed
        local autoTracked = todo.autoTrack and (todo.autoTrack.type == "quest" or todo.autoTrack.type == "instance_boss" or todo.autoTrack.type == "currency")
        if not autoTracked then
            row.cb:SetScript("OnClick", function()
                if scope == "warband" then
                    BT.Data.SetWarbandCompleted(todoID, not isCompleted)
                else
                    BT.Data.SetCharCompleted(todoID, ck, not isCompleted)
                end
            end)
        else
            row.cb:SetScript("OnClick", nil)
        end

        table.insert(activeRows, row)
        yOffset = yOffset + ROW_H + 2
    end

    content:SetHeight(math.max(yOffset, 40))
    titleText:SetText(string.format("|cff55aaffBrainTask|r  |cff888888%d/%d|r", doneCount, totalCount))
end

-- ── 公共接口 ──────────────────────────────────────────────────────────────

function FW.Toggle()
    if frame:IsVisible() then
        FW.Close()
    else
        FW.Open()
    end
end

local sizeRestored = false
function FW.Open()
    if not sizeRestored and BrainTaskDB then
        sizeRestored = true
        if BrainTaskDB.floatWindowSize then
            local sz = BrainTaskDB.floatWindowSize
            frame:SetSize(sz.w or WIN_W, sz.h or WIN_H)
        end
        if BrainTaskDB.floatWindowPos then
            local pos = BrainTaskDB.floatWindowPos
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
        end
        FW.SetPositionLocked(BrainTaskDB.floatWindowLocked or false)
    end
    frame:Show()
    FW.Refresh()
    if BrainTaskDB then BrainTaskDB.floatWindowVisible = true end
end

function FW.Close()
    frame:Hide()
    if BrainTaskDB then BrainTaskDB.floatWindowVisible = false end
end

function FW.SetScale(v)
    frame:SetScale(math.max(0.5, math.min(2.0, v or 1.0)))
end

function FW.SetLocked(locked)
    resizeHandle:SetShown(not locked)
end

function FW.SetPositionLocked(locked)
    if locked then
        titleBar:SetScript("OnDragStart", nil)
    else
        titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
        titleBar:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            if BrainTaskDB then
                BrainTaskDB.floatWindowPos = { x = frame:GetLeft(), y = frame:GetTop() }
            end
        end)
    end
    if BrainTaskDB then BrainTaskDB.floatWindowLocked = locked end
end
