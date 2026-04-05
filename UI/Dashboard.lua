-- BrainTask UI: Dashboard

BrainTask = BrainTask or {}
BrainTask.UI = BrainTask.UI or {}
local BT = BrainTask
BT.UI.Dashboard = {}
local DB = BT.UI.Dashboard

local WIN_W, WIN_H   = 920, 640
local TOP_H, BOT_H   = 38, 38
local LEFT_W         = 400
local ROW_H          = 20
local CELL_W         = 52
local HEAD_H         = 36
local LABEL_W        = 260

-- 前向声明（body 在 rightContent 创建后赋值）
local UpdateLayout
local SetLocked
local lockState              = false
local isDraggingDivider      = false
local isDraggingRightDivider = false
local lockCheckBg, lockCheckMark          -- 在 botBar 区块中赋值
local floatLockCheckBg, floatLockCheckMark
local floatLockState = false
local resizeHandle                -- 在布局更新区块中赋值
local rightDivider                -- 右列标题宽度分割线
local rightDividerLine
local UpdateRightLayout
local initStage = true   -- 初始化阶段标志，OnShow 恢复布局完成前屏蔽 OnSizeChanged

-- ── 主框架 ────────────────────────────────────────────────────────────────

local frame = BT.CreateBackdropFrame("Frame", "BrainTaskDashboard", UIParent, WIN_W, WIN_H)
frame:SetPoint("CENTER")
frame:SetFrameStrata("MEDIUM")
frame:EnableMouse(true)
frame:SetToplevel(true)
frame:SetScript("OnMouseDown", function(self) self:Raise() end)
frame:Hide()

-- ── 顶部工具栏 ────────────────────────────────────────────────────────────

local topBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
topBar:SetHeight(TOP_H)
topBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
topBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
topBar:SetBackdrop(BT.BACKDROP)
topBar:SetBackdropColor(unpack(BT.COLORS.header))
topBar:SetBackdropBorderColor(unpack(BT.COLORS.border))

BT.MakeDraggable(frame, topBar)  -- 仅拖动标题栏时移动窗口

-- 标题
local titleFS = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleFS:SetPoint("LEFT", topBar, "LEFT", 14, 0)
titleFS:SetText("|cff55aaffBrainTask|r Dashboard")


-- 关闭按钮
local closeBtn = CreateFrame("Button", nil, topBar)
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("RIGHT", topBar, "RIGHT", -8, 0)
local closeTex = closeBtn:CreateTexture(nil, "ARTWORK")
closeTex:SetAllPoints()
closeTex:SetAtlas("uitools-icon-close")
closeBtn:SetScript("OnClick", function() frame:Hide() end)
closeBtn:SetScript("OnEnter", function() closeTex:SetVertexColor(1, 0.3, 0.3) end)
closeBtn:SetScript("OnLeave", function() closeTex:SetVertexColor(1, 1, 1) end)

-- ── 底部操作栏 ────────────────────────────────────────────────────────────

local botBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
botBar:SetHeight(BOT_H)
botBar:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  0, 0)
botBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
botBar:SetBackdrop(BT.BACKDROP)
botBar:SetBackdropColor(unpack(BT.COLORS.header))
botBar:SetBackdropBorderColor(unpack(BT.COLORS.border))

local addWarbandBtn = BT.CreateButton(botBar, BT.L.BTN_ADD_WARBAND, 130, 26)
addWarbandBtn:SetPoint("LEFT", botBar, "LEFT", 10, 0)

local addCharBtn = BT.CreateButton(botBar, BT.L.BTN_ADD_CHAR, 130, 26)
addCharBtn:SetPoint("LEFT", addWarbandBtn, "RIGHT", 8, 0)

local globalSettingsBtn = BT.CreateButton(botBar, BT.L.BTN_SETTINGS, 70, 26)
globalSettingsBtn:SetPoint("RIGHT", botBar, "RIGHT", -10, 0)
globalSettingsBtn:SetScript("OnClick", function()
    if BT.UI.GlobalSettings then BT.UI.GlobalSettings.Open() end
end)

local settingsBtn = BT.CreateButton(botBar, BT.L.BTN_CATEGORY_MGMT, 100, 26)
settingsBtn:SetPoint("RIGHT", globalSettingsBtn, "LEFT", -8, 0)
settingsBtn:SetScript("OnClick", function()
    if BT.UI.Settings then BT.UI.Settings.Open() end
end)

local sortCharsBtn = BT.CreateButton(botBar, BT.L.BTN_CHAR_MGMT, 90, 26)
sortCharsBtn:SetPoint("RIGHT", settingsBtn, "LEFT", -8, 0)
sortCharsBtn:SetScript("OnClick", function()
    if BT.UI.SortChars then BT.UI.SortChars.Open() end
end)

-- 锁定复选框
local lockCb = CreateFrame("Button", nil, botBar)
lockCb:SetSize(16, 16)
lockCb:SetPoint("RIGHT", sortCharsBtn, "LEFT", -14, 0)

lockCheckBg = lockCb:CreateTexture(nil, "BACKGROUND")
lockCheckBg:SetAllPoints()
lockCheckBg:SetColorTexture(0.18, 0.18, 0.24, 1)

lockCheckMark = lockCb:CreateTexture(nil, "OVERLAY")
lockCheckMark:SetSize(14, 14)
lockCheckMark:SetPoint("CENTER")
lockCheckMark:SetTexture("Interface/Buttons/UI-CheckBox-Check")
lockCheckMark:SetVertexColor(0.3, 0.9, 0.3, 1)
lockCheckMark:Hide()

local lockLabel = botBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
lockLabel:SetPoint("RIGHT", lockCb, "LEFT", -4, 0)
lockLabel:SetText(BT.L.LBL_LOCK_WINDOW)
lockLabel:SetTextColor(unpack(BT.COLORS.textMuted))

lockCb:SetScript("OnEnter", function() lockCheckBg:SetColorTexture(0.28, 0.28, 0.38, 1) end)
lockCb:SetScript("OnLeave", function()
    if lockState then
        lockCheckBg:SetColorTexture(0.10, 0.24, 0.10, 1)
    else
        lockCheckBg:SetColorTexture(0.18, 0.18, 0.24, 1)
    end
end)
lockCb:SetScript("OnClick", function()
    SetLocked(not lockState)
end)

-- 锁定浮动窗口位置复选框
local floatLockCb = CreateFrame("Button", nil, botBar)
floatLockCb:SetSize(16, 16)
floatLockCb:SetPoint("RIGHT", lockLabel, "LEFT", -14, 0)

floatLockCheckBg = floatLockCb:CreateTexture(nil, "BACKGROUND")
floatLockCheckBg:SetAllPoints()
floatLockCheckBg:SetColorTexture(0.18, 0.18, 0.24, 1)

floatLockCheckMark = floatLockCb:CreateTexture(nil, "OVERLAY")
floatLockCheckMark:SetSize(14, 14)
floatLockCheckMark:SetPoint("CENTER")
floatLockCheckMark:SetTexture("Interface/Buttons/UI-CheckBox-Check")
floatLockCheckMark:SetVertexColor(0.3, 0.9, 0.3, 1)
floatLockCheckMark:Hide()

local floatLockLabel = botBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
floatLockLabel:SetPoint("RIGHT", floatLockCb, "LEFT", -4, 0)
floatLockLabel:SetText(BT.L.LBL_LOCK_FLOAT_POS)
floatLockLabel:SetTextColor(unpack(BT.COLORS.textMuted))

floatLockCb:SetScript("OnEnter", function() floatLockCheckBg:SetColorTexture(0.28, 0.28, 0.38, 1) end)
floatLockCb:SetScript("OnLeave", function()
    if floatLockState then
        floatLockCheckBg:SetColorTexture(0.10, 0.24, 0.10, 1)
    else
        floatLockCheckBg:SetColorTexture(0.18, 0.18, 0.24, 1)
    end
end)
floatLockCb:SetScript("OnClick", function()
    floatLockState = not floatLockState
    if floatLockState then
        floatLockCheckBg:SetColorTexture(0.10, 0.24, 0.10, 1)
        floatLockCheckMark:Show()
    else
        floatLockCheckBg:SetColorTexture(0.18, 0.18, 0.24, 1)
        floatLockCheckMark:Hide()
    end
    if BrainTaskDB then BrainTaskDB.floatWindowLocked = floatLockState end
    if BT.UI.FloatWindow and BT.UI.FloatWindow.SetPositionLocked then
        BT.UI.FloatWindow.SetPositionLocked(floatLockState)
    end
end)

-- ── 分隔线（左右两列之间，可拖拽）──────────────────────────────────────

local dividerFrame = CreateFrame("Frame", nil, frame)
dividerFrame:SetWidth(8)
dividerFrame:SetPoint("TOP",    frame, "TOPLEFT",    LEFT_W, -TOP_H)
dividerFrame:SetPoint("BOTTOM", frame, "BOTTOMLEFT", LEFT_W,  BOT_H)
dividerFrame:EnableMouse(true)

local dividerLine = dividerFrame:CreateTexture(nil, "ARTWORK")
dividerLine:SetWidth(1)
dividerLine:SetPoint("TOP",    dividerFrame, "TOP")
dividerLine:SetPoint("BOTTOM", dividerFrame, "BOTTOM")
dividerLine:SetPoint("CENTER", dividerFrame, "CENTER")
dividerLine:SetColorTexture(unpack(BT.COLORS.border))

-- ── 左列：战团事项 ────────────────────────────────────────────────────────

local leftArea = CreateFrame("Frame", nil, frame)
leftArea:SetPoint("TOPLEFT",    frame, "TOPLEFT",    4,     -TOP_H - 4)
leftArea:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4,      BOT_H + 4)
leftArea:SetWidth(LEFT_W - 8)

-- 列头
local leftHead = CreateFrame("Frame", nil, leftArea, "BackdropTemplate")
leftHead:SetHeight(24)
leftHead:SetPoint("TOPLEFT",  leftArea, "TOPLEFT",  0, 0)
leftHead:SetPoint("TOPRIGHT", leftArea, "TOPRIGHT", 0, 0)
leftHead:SetBackdrop(BT.BACKDROP)
leftHead:SetBackdropColor(unpack(BT.COLORS.bgLight))
leftHead:SetBackdropBorderColor(unpack(BT.COLORS.border))
local leftHeadFS = leftHead:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
leftHeadFS:SetPoint("LEFT", leftHead, "LEFT", 10, 0)
leftHeadFS:SetText("|cffaa88ff" .. BT.L.COL_WARBAND .. "|r")

-- 左列滚动区
local leftScroll = CreateFrame("ScrollFrame", nil, leftArea, "UIPanelScrollFrameTemplate")
leftScroll:SetPoint("TOPLEFT",    leftArea, "TOPLEFT",    0, -26)
leftScroll:SetPoint("BOTTOMRIGHT", leftArea, "BOTTOMRIGHT", -20, 0)

local leftContent = CreateFrame("Frame", nil, leftScroll)
leftContent:SetWidth(leftScroll:GetWidth())
leftContent:SetHeight(1)
leftScroll:SetScrollChild(leftContent)

-- ── 右列：角色事项矩阵 ────────────────────────────────────────────────────

local rightArea = CreateFrame("Frame", nil, frame)
rightArea:SetPoint("TOPLEFT",     frame, "TOPLEFT",    LEFT_W + 4, -TOP_H - 4)
rightArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4,         BOT_H + 4)

-- 列头（固定行：角色名）
local rightHeadFrame = CreateFrame("Frame", nil, rightArea, "BackdropTemplate")
rightHeadFrame:SetHeight(HEAD_H)
rightHeadFrame:SetPoint("TOPLEFT",  rightArea, "TOPLEFT",  0, 0)
rightHeadFrame:SetPoint("TOPRIGHT", rightArea, "TOPRIGHT", 0, 0)
rightHeadFrame:SetBackdrop(BT.BACKDROP)
rightHeadFrame:SetBackdropColor(unpack(BT.COLORS.bgLight))
rightHeadFrame:SetBackdropBorderColor(unpack(BT.COLORS.border))

-- 右列标签
local rightLabel = rightHeadFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
rightLabel:SetPoint("LEFT", rightHeadFrame, "LEFT", 6, 0)
rightLabel:SetTextColor(unpack(BT.COLORS.accent))
rightLabel:SetText("|cff88bbff" .. BT.L.COL_CHAR .. "|r")

-- 右列滚动区（垂直）
local rightScroll = CreateFrame("ScrollFrame", nil, rightArea, "UIPanelScrollFrameTemplate")
rightScroll:SetPoint("TOPLEFT",    rightArea, "TOPLEFT",    0,  -HEAD_H)
rightScroll:SetPoint("BOTTOMRIGHT", rightArea, "BOTTOMRIGHT", -20, 12)

local rightContent = CreateFrame("Frame", nil, rightScroll)
rightContent:SetWidth(rightScroll:GetWidth())
rightContent:SetHeight(1)
rightScroll:SetScrollChild(rightContent)

-- ── 右列横向滚动（其他角色）──────────────────────────────────────────────

-- header 中的横向滚动区（其他角色名字）
local headClipScroll = CreateFrame("ScrollFrame", nil, rightHeadFrame)
headClipScroll:SetPoint("TOPLEFT",     rightHeadFrame, "TOPLEFT",     LABEL_W + CELL_W, 0)
headClipScroll:SetPoint("BOTTOMRIGHT", rightHeadFrame, "BOTTOMRIGHT", -20, 0)

local headClipContent = CreateFrame("Frame", nil, headClipScroll)
headClipContent:SetHeight(HEAD_H)
headClipContent:SetWidth(1)
headClipScroll:SetScrollChild(headClipContent)

-- 横向滚动条（其他角色列，置于 rightArea 底部）
local hScrollBar = CreateFrame("Frame", nil, rightArea)
hScrollBar:SetHeight(12)
hScrollBar:SetPoint("BOTTOMLEFT",  rightArea, "BOTTOMLEFT",  LABEL_W + CELL_W, 0)
hScrollBar:SetPoint("BOTTOMRIGHT", rightArea, "BOTTOMRIGHT", -20, 0)
hScrollBar:Hide()

local scrollTrack = CreateFrame("Frame", nil, hScrollBar)
scrollTrack:SetPoint("TOPLEFT",     hScrollBar, "TOPLEFT",     0, -1)
scrollTrack:SetPoint("BOTTOMRIGHT", hScrollBar, "BOTTOMRIGHT", 0,  1)
local trackBg = scrollTrack:CreateTexture(nil, "BACKGROUND")
trackBg:SetAllPoints()
trackBg:SetColorTexture(0.12, 0.12, 0.18, 1)

local scrollThumb = CreateFrame("Button", nil, scrollTrack)
scrollThumb:SetSize(20, 10)
scrollThumb:SetPoint("LEFT", scrollTrack, "LEFT", 0, 0)
local thumbTex = scrollThumb:CreateTexture(nil, "BACKGROUND")
thumbTex:SetAllPoints()
thumbTex:SetColorTexture(0.35, 0.45, 0.65, 0.85)
scrollThumb:SetScript("OnEnter", function() thumbTex:SetColorTexture(0.45, 0.60, 1.0, 1) end)
scrollThumb:SetScript("OnLeave", function() thumbTex:SetColorTexture(0.35, 0.45, 0.65, 0.85) end)

local hScrollOffset    = 0
local hScrollMaxOffset = 0
local activeRowClips   = {}

local function ApplyHScroll(offset)
    hScrollOffset = math.max(0, math.min(offset, hScrollMaxOffset))
    headClipScroll:SetHorizontalScroll(hScrollOffset)
    for _, clip in ipairs(activeRowClips) do
        clip:SetHorizontalScroll(hScrollOffset)
    end
    -- 更新滑块位置
    if hScrollMaxOffset > 0 then
        local trackW = scrollTrack:GetWidth()
        local thumbW = scrollThumb:GetWidth()
        local pos    = hScrollOffset / hScrollMaxOffset * math.max(trackW - thumbW, 0)
        scrollThumb:ClearAllPoints()
        scrollThumb:SetPoint("LEFT", scrollTrack, "LEFT", pos, 0)
    end
end

-- 拖拽滑块
scrollThumb:SetScript("OnMouseDown", function(self, btn)
    if btn ~= "LeftButton" then return end
    self.dragStartX      = GetCursorPosition() / UIParent:GetEffectiveScale()
    self.dragStartOffset = hScrollOffset
    self:SetScript("OnUpdate", function()
        local dx     = GetCursorPosition() / UIParent:GetEffectiveScale() - self.dragStartX
        local trackW = scrollTrack:GetWidth()
        local thumbW = self:GetWidth()
        local ratio  = dx / math.max(trackW - thumbW, 1)
        ApplyHScroll(self.dragStartOffset + ratio * hScrollMaxOffset)
    end)
end)
scrollThumb:SetScript("OnMouseUp", function(self)
    self:SetScript("OnUpdate", nil)
end)

-- 点击轨道跳转
scrollTrack:EnableMouse(true)
scrollTrack:SetScript("OnMouseDown", function(self, btn)
    if btn ~= "LeftButton" then return end
    local left = self:GetLeft()
    if not left then return end
    local mx     = GetCursorPosition() / UIParent:GetEffectiveScale()
    local trackW = self:GetWidth()
    local thumbW = scrollThumb:GetWidth()
    local pos    = math.max(0, math.min(mx - left - thumbW / 2, trackW - thumbW))
    ApplyHScroll(pos / math.max(trackW - thumbW, 1) * hScrollMaxOffset)
end)

headClipScroll:EnableMouseWheel(true)
headClipScroll:SetScript("OnMouseWheel", function(_, delta)
    ApplyHScroll(hScrollOffset - delta * CELL_W)
end)

-- ── Shift 模式：统一控制编辑/删除按钮可见性 ──────────────────────────────

local shiftButtons    = {}
local nonShiftLabels  = {}
local lastShiftState  = false

local shiftUpdater = CreateFrame("Frame", nil, frame)
shiftUpdater:SetScript("OnUpdate", function()
    local shift = IsShiftKeyDown()
    if shift == lastShiftState then return end
    lastShiftState = shift
    for _, btn in ipairs(shiftButtons) do
        btn:SetShown(shift)
    end
    for _, lbl in ipairs(nonShiftLabels) do
        lbl:SetShown(not shift)
    end
end)

-- ── 布局更新 ──────────────────────────────────────────────────────────────

UpdateLayout = function(newLeftW)
    local frameW = frame:GetWidth()
    LEFT_W = math.max(180, math.min(newLeftW, frameW - 200))

    dividerFrame:ClearAllPoints()
    dividerFrame:SetPoint("TOP",    frame, "TOPLEFT",    LEFT_W, -TOP_H)
    dividerFrame:SetPoint("BOTTOM", frame, "BOTTOMLEFT", LEFT_W,  BOT_H)

    leftArea:SetWidth(LEFT_W - 8)

    rightArea:ClearAllPoints()
    rightArea:SetPoint("TOPLEFT",     frame, "TOPLEFT",     LEFT_W + 4, -TOP_H - 4)
    rightArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4,          BOT_H + 4)

    leftContent:SetWidth(math.max(1, LEFT_W - 28))
    rightContent:SetWidth(math.max(1, frameW - LEFT_W - 28))

    local layout = BrainTaskDB and BrainTaskDB.dashboardLayout
    if layout then
        layout.w     = frameW
        layout.h     = frame:GetHeight()
        layout.leftW = LEFT_W
    end

    -- 右列分割线位置随窗口大小变化重新约束
    if UpdateRightLayout then UpdateRightLayout(LABEL_W) end
end

SetLocked = function(locked)
    lockState = locked
    resizeHandle:SetShown(not locked)
    if locked then
        isDraggingDivider = false
        dividerFrame:SetScript("OnUpdate", nil)
        dividerLine:SetColorTexture(unpack(BT.COLORS.border))
        -- 同时禁用右列标题宽度分割线
        isDraggingRightDivider = false
        if rightDivider     then rightDivider:SetScript("OnUpdate", nil) end
        if rightDividerLine then rightDividerLine:SetColorTexture(unpack(BT.COLORS.border)) end
    end
    -- 同步复选框视觉
    if locked then
        lockCheckBg:SetColorTexture(0.10, 0.24, 0.10, 1)
        lockCheckMark:Show()
    else
        lockCheckBg:SetColorTexture(0.18, 0.18, 0.24, 1)
        lockCheckMark:Hide()
    end
    local layout = BrainTaskDB and BrainTaskDB.dashboardLayout
    if layout then layout.locked = locked end
    -- 同步浮动窗口锁定状态
    if BT.UI.FloatWindow and BT.UI.FloatWindow.SetLocked then
        BT.UI.FloatWindow.SetLocked(locked)
    end
end

-- 分隔线拖拽脚本
dividerFrame:SetScript("OnEnter", function()
    if not lockState then dividerLine:SetColorTexture(unpack(BT.COLORS.accent)) end
end)
dividerFrame:SetScript("OnLeave", function()
    if not isDraggingDivider then dividerLine:SetColorTexture(unpack(BT.COLORS.border)) end
end)
dividerFrame:SetScript("OnMouseDown", function(self)
    if lockState then return end
    isDraggingDivider = true
    local startX    = GetCursorPosition() / UIParent:GetEffectiveScale()
    local startLeft = LEFT_W
    self:SetScript("OnUpdate", function()
        local curX = GetCursorPosition() / UIParent:GetEffectiveScale()
        UpdateLayout(startLeft + (curX - startX))
    end)
end)
dividerFrame:SetScript("OnMouseUp", function(self)
    isDraggingDivider = false
    self:SetScript("OnUpdate", nil)
    dividerLine:SetColorTexture(unpack(BT.COLORS.border))
    UpdateLayout(LEFT_W)
    if DB.Refresh then DB.Refresh() end
end)

-- 缩放手柄（右下角）
frame:SetResizable(true)
frame:SetResizeBounds(400, 200)

resizeHandle = CreateFrame("Frame", nil, frame)
resizeHandle:SetSize(16, 16)
resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 5)
resizeHandle:EnableMouse(true)

local resizeTex = resizeHandle:CreateTexture(nil, "OVERLAY")
resizeTex:SetAllPoints()
resizeTex:SetColorTexture(0.4, 0.4, 0.5, 0.4)

resizeHandle:SetScript("OnEnter", function()
    if not lockState then resizeTex:SetColorTexture(0.5, 0.7, 1.0, 0.6) end
end)
resizeHandle:SetScript("OnLeave", function()
    resizeTex:SetColorTexture(0.4, 0.4, 0.5, 0.4)
end)
resizeHandle:SetScript("OnMouseDown", function(self, btn)
    if btn == "LeftButton" and not lockState then
        local x = frame:GetLeft()
        local y = frame:GetTop()
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
        frame:StartSizing("BOTTOMRIGHT")
    end
end)
resizeHandle:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    UpdateLayout(LEFT_W)
    if DB.Refresh then DB.Refresh() end
end)

frame:SetScript("OnSizeChanged", function()
    if initStage then return end
    UpdateLayout(LEFT_W)
end)

-- ── 右列标题宽度分割线（事项标题 / 角色格子之间，可拖拽）────────────────

UpdateRightLayout = function(newLabelW)
    local rightW = rightArea:GetWidth()
    LABEL_W = math.max(60, math.min(newLabelW, math.max(rightW - CELL_W * 2 - 40, 60)))

    if rightDivider then
        rightDivider:ClearAllPoints()
        rightDivider:SetPoint("TOP",    rightArea, "TOPLEFT",    LABEL_W, 0)
        rightDivider:SetPoint("BOTTOM", rightArea, "BOTTOMLEFT", LABEL_W, 0)
    end

    headClipScroll:ClearAllPoints()
    headClipScroll:SetPoint("TOPLEFT",     rightHeadFrame, "TOPLEFT",     LABEL_W + CELL_W + 10, 0)
    headClipScroll:SetPoint("BOTTOMRIGHT", rightHeadFrame, "BOTTOMRIGHT", -20, 0)

    hScrollBar:ClearAllPoints()
    hScrollBar:SetPoint("BOTTOMLEFT",  rightArea, "BOTTOMLEFT",  LABEL_W + CELL_W + 10, 0)
    hScrollBar:SetPoint("BOTTOMRIGHT", rightArea, "BOTTOMRIGHT", -20, 0)

    local layout = BrainTaskDB and BrainTaskDB.dashboardLayout
    if layout then layout.labelW = LABEL_W end
end

rightDivider = CreateFrame("Frame", nil, rightArea)
rightDivider:SetWidth(8)
rightDivider:SetPoint("TOP",    rightArea, "TOPLEFT",    LABEL_W, 0)
rightDivider:SetPoint("BOTTOM", rightArea, "BOTTOMLEFT", LABEL_W, 0)
rightDivider:EnableMouse(true)

rightDividerLine = rightDivider:CreateTexture(nil, "ARTWORK")
rightDividerLine:SetWidth(1)
rightDividerLine:SetPoint("TOP",    rightDivider, "TOP")
rightDividerLine:SetPoint("BOTTOM", rightDivider, "BOTTOM")
rightDividerLine:SetPoint("CENTER", rightDivider, "CENTER")
rightDividerLine:SetColorTexture(unpack(BT.COLORS.border))

rightDivider:SetScript("OnEnter", function()
    if not lockState then rightDividerLine:SetColorTexture(unpack(BT.COLORS.accent)) end
end)
rightDivider:SetScript("OnLeave", function()
    if not isDraggingRightDivider then rightDividerLine:SetColorTexture(unpack(BT.COLORS.border)) end
end)
rightDivider:SetScript("OnMouseDown", function(self)
    if lockState then return end
    isDraggingRightDivider = true
    local startX      = GetCursorPosition() / UIParent:GetEffectiveScale()
    local startLabelW = LABEL_W
    self:SetScript("OnUpdate", function()
        local curX = GetCursorPosition() / UIParent:GetEffectiveScale()
        UpdateRightLayout(startLabelW + (curX - startX))
    end)
end)
rightDivider:SetScript("OnMouseUp", function(self)
    isDraggingRightDivider = false
    self:SetScript("OnUpdate", nil)
    rightDividerLine:SetColorTexture(unpack(BT.COLORS.border))
    if DB.Refresh then DB.Refresh() end
end)

-- ── 拖拽排序系统 ──────────────────────────────────────────────────────────

local dragState      = nil   -- { type, id, catID, scope, label, items }
local dropTarget     = nil   -- { afterID, catID }
local dragItemsLeft  = {}    -- 左列可拖拽行元数据列表（每次 Refresh 重建）
local dragItemsRight = {}    -- 右列

-- Ghost 框：跟随鼠标的半透明标签
local dragGhost = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
dragGhost:SetSize(220, 22)
dragGhost:SetFrameStrata("TOOLTIP")
dragGhost:SetBackdrop(BT.BACKDROP)
dragGhost:SetBackdropColor(0.05, 0.15, 0.35, 0.9)
dragGhost:SetBackdropBorderColor(0.3, 0.6, 1, 1)
local dragGhostFS = dragGhost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dragGhostFS:SetPoint("LEFT", dragGhost, "LEFT", 8, 0)
dragGhostFS:SetTextColor(0.85, 0.90, 1)
dragGhost:Hide()

-- 落点指示线
local dropLine = CreateFrame("Frame", nil, UIParent)
dropLine:SetHeight(2)
dropLine:SetFrameStrata("TOOLTIP")
local dropLineTex = dropLine:CreateTexture(nil, "OVERLAY")
dropLineTex:SetAllPoints()
dropLineTex:SetColorTexture(0.3, 0.7, 1, 1)
dropLine:Hide()

-- 拖拽时的全局鼠标捕获层（保证 MouseUp 一定能收到）
local dragOverlay = CreateFrame("Frame", nil, UIParent)
dragOverlay:SetAllPoints(UIParent)
dragOverlay:SetFrameStrata("FULLSCREEN")
dragOverlay:EnableMouse(true)
dragOverlay:Hide()

local function EndDrag()
    dragState  = nil
    dropTarget = nil
    dragGhost:Hide()
    dropLine:Hide()
    dragOverlay:Hide()
end

local function CommitDrop()
    if not dragState or not dropTarget then EndDrag(); return end
    if dragState.type == "category" then
        BT.Data.MoveCategory(dragState.id, dropTarget.afterID)
    else
        BT.Data.MoveTodo(dragState.id, dropTarget.catID, dropTarget.afterID)
    end
    EndDrag()
end

dragOverlay:SetScript("OnMouseUp", function(_, btn)
    if btn == "LeftButton" then CommitDrop() end
end)

-- OnUpdate：更新 ghost 位置，计算落点，显示指示线
frame:SetScript("OnUpdate", function()
    if not dragState then return end

    -- 兜底：鼠标已松开但 OnMouseUp 未能触发
    if not IsMouseButtonDown("LeftButton") then
        CommitDrop()
        return
    end

    local uiScale    = UIParent:GetEffectiveScale()
    local rawX, rawY = GetCursorPosition()
    -- Ghost 锚定 UIParent，用 UIParent 坐标系
    local mx, my = rawX / uiScale, rawY / uiScale
    -- 命中测试对比 item frame 的 GetTop/GetBottom，需用 Dashboard 自身的有效缩放
    local hitScale = frame:GetEffectiveScale()
    local hy       = rawY / hitScale

    -- 移动 ghost
    dragGhost:ClearAllPoints()
    dragGhost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", mx + 14, my + 10)

    local items = dragState.items
    if not items or #items == 0 then dropLine:Hide(); return end

    -- 找鼠标命中的行
    local hitIdx, hitUpper = nil, false
    for i, item in ipairs(items) do
        local f = item.frame
        if f:IsVisible() then
            local top, bot = f:GetTop(), f:GetBottom()
            if top and bot and hy >= bot and hy <= top then
                hitIdx   = i
                hitUpper = (hy > (top + bot) / 2)
                break
            end
        end
    end

    if not hitIdx then dropLine:Hide(); dropTarget = nil; return end

    -- 插在上半 → 放在 hitIdx 之前；下半 → 之后
    local insertAfterIdx = hitUpper and (hitIdx - 1) or hitIdx
    insertAfterIdx = math.max(0, math.min(insertAfterIdx, #items))

    if dragState.type == "category" then
        -- afterID 必须是 category ID：从插入点向前找最近的非自身分类
        local afterCatID = nil
        for i = insertAfterIdx, 1, -1 do
            if items[i].type == "category" and items[i].id ~= dragState.id then
                afterCatID = items[i].id
                break
            end
        end
        dropTarget = { afterID = afterCatID }

        -- 自身位置：找当前分类在逻辑上的前驱 category
        local prevCatID = nil
        for i, item in ipairs(items) do
            if item.type == "category" and item.id == dragState.id then
                for j = i - 1, 1, -1 do
                    if items[j].type == "category" then
                        prevCatID = items[j].id; break
                    end
                end
                break
            end
        end
        if dropTarget.afterID == prevCatID then
            dropLine:Hide(); dropTarget = nil; return
        end
    else
        -- todo：直接用 index 判断无意义移动
        local selfIdx = nil
        for i, item in ipairs(items) do
            if item.type == "todo" and item.id == dragState.id then selfIdx = i; break end
        end
        if selfIdx and (insertAfterIdx == selfIdx or insertAfterIdx == selfIdx - 1) then
            dropLine:Hide(); dropTarget = nil; return
        end

        local afterItem = insertAfterIdx > 0 and items[insertAfterIdx] or nil
        local targetCatID
        if afterItem then
            targetCatID = (afterItem.type == "category") and afterItem.id or afterItem.catID
        else
            for _, item in ipairs(items) do
                if item.type == "category" then targetCatID = item.id; break end
            end
        end
        local afterTodoID = (afterItem and afterItem.type == "todo") and afterItem.id or nil
        dropTarget = { afterID = afterTodoID, catID = targetCatID }
    end

    -- 指示线：锚定到行 frame 本身，避免坐标系依赖
    local refFrame = (insertAfterIdx == 0) and items[1].frame or items[insertAfterIdx].frame
    local refAnchor = (insertAfterIdx == 0) and "TOPLEFT" or "BOTTOMLEFT"
    local isLeft = (dragState.items == dragItemsLeft)
    dropLine:ClearAllPoints()
    dropLine:SetPoint("TOPLEFT", refFrame, refAnchor, 0, 0)
    if isLeft then
        dropLine:SetPoint("TOPRIGHT", refFrame,
            (insertAfterIdx == 0) and "TOPRIGHT" or "BOTTOMRIGHT", 0, 0)
    else
        dropLine:SetWidth(LABEL_W)
    end
    dropLine:Show()
end)

local function MakeDragTarget(f, type, id, catID, scope, label, items)
    f:EnableMouse(true)
    f:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" and IsShiftKeyDown() then
            local prefix = (type == "category") and "|cffaa88ff" .. BT.L.DRAG_CAT_PREFIX .. "|r" or ""
            dragState = { type=type, id=id, catID=catID, scope=scope, label=label, items=items }
            dragGhostFS:SetText(prefix .. label)
            dragGhost:Show()
            dragOverlay:Show()
            dropTarget = nil
        end
    end)
end

-- ── 动态渲染：左列（战团事项）────────────────────────────────────────────

local leftRows = {}

local function ClearLeftRows()
    for _, r in ipairs(leftRows) do r:Hide() end
    leftRows = {}
end

local function RefreshLeftColumn(filterText)
    ClearLeftRows()
    dragItemsLeft = {}
    local todos = BT.Data.GetWarbandTodos()
    local y = 0
    local lastCat = -1

    -- 预计算每个分类的完成统计
    local catStats = {}
    for _, todo in ipairs(todos) do
        local cid = todo.categoryID or 0
        if not catStats[cid] then catStats[cid] = { total=0, done=0 } end
        catStats[cid].total = catStats[cid].total + 1
        if BT.Data.GetWarbandCompleted(todo.id) then catStats[cid].done = catStats[cid].done + 1 end
    end

    for _, todo in ipairs(todos) do
        local matches = not (filterText and filterText ~= "") or
            string.find(string.lower(todo.title), string.lower(filterText), 1, true)
        if matches then

        -- 分类标题行
        if todo.categoryID ~= lastCat then
            lastCat = todo.categoryID
            local catRow = CreateFrame("Frame", nil, leftContent)
            catRow:SetHeight(20)
            catRow:SetPoint("TOPLEFT",  leftContent, "TOPLEFT",  0, -y)
            catRow:SetPoint("TOPRIGHT", leftContent, "TOPRIGHT", 0, -y)
            local catBg = catRow:CreateTexture(nil, "BACKGROUND")
            catBg:SetAllPoints()
            catBg:SetColorTexture(0.14, 0.14, 0.20, 1)
            local catFS = catRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            catFS:SetPoint("LEFT", catRow, "LEFT", 8, 0)
            catFS:SetTextColor(unpack(BT.COLORS.accent))
            local catTitle = BT.Data.GetCategoryTitle(todo.categoryID)
            catFS:SetText(catTitle)
            local st = catStats[todo.categoryID or 0] or { total=0, done=0 }
            local stFS = catRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            stFS:SetPoint("RIGHT", catRow, "RIGHT", -8, 0)
            stFS:SetJustifyH("RIGHT")
            stFS:SetText("|cff666666" .. st.done .. "/" .. st.total .. "|r")
            MakeDragTarget(catRow, "category", todo.categoryID, nil, nil, catTitle, dragItemsLeft)
            table.insert(dragItemsLeft, { type="category", id=todo.categoryID, frame=catRow })
            table.insert(leftRows, catRow)
            y = y + 20
        end

        -- 事项行
        local completed = BT.Data.GetWarbandCompleted(todo.id)
        local row = CreateFrame("Frame", nil, leftContent)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT",  leftContent, "TOPLEFT",  0, -y)
        row:SetPoint("TOPRIGHT", leftContent, "TOPRIGHT", 0, -y)

        -- 交替背景
        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        local bgAlpha = (#leftRows % 2 == 0) and 0.07 or 0.03
        rowBg:SetColorTexture(1, 1, 1, bgAlpha)

        -- 复选框
        local cb = CreateFrame("Button", nil, row)
        cb:SetSize(16, 16)
        cb:SetPoint("LEFT", row, "LEFT", 8, 0)
        local cbBg = cb:CreateTexture(nil, "BACKGROUND")
        cbBg:SetAllPoints()
        if completed then
            cbBg:SetColorTexture(0.10, 0.24, 0.10, 1)
        else
            cbBg:SetColorTexture(0.18, 0.18, 0.24, 1)
        end
        local cbCheck = cb:CreateTexture(nil, "OVERLAY")
        cbCheck:SetSize(14, 14)
        cbCheck:SetPoint("CENTER")
        cbCheck:SetTexture("Interface/Buttons/UI-CheckBox-Check")
        cbCheck:SetVertexColor(0.3, 0.9, 0.3, 1)
        if not completed then cbCheck:Hide() end

        local todoID   = todo.id
        local autoTracked = todo.autoTrack and (todo.autoTrack.type == "quest" or todo.autoTrack.type == "instance_boss" or todo.autoTrack.type == "currency")
        if not autoTracked then
            cb:SetScript("OnClick", function()
                local cur = BT.Data.GetWarbandCompleted(todoID)
                BT.Data.SetWarbandCompleted(todoID, not cur)
            end)
            cb:SetScript("OnEnter", function() cbBg:SetColorTexture(0.28, 0.28, 0.38, 1) end)
            cb:SetScript("OnLeave", function()
                if BT.Data.GetWarbandCompleted(todoID) then
                    cbBg:SetColorTexture(0.10, 0.24, 0.10, 1)
                else
                    cbBg:SetColorTexture(0.18, 0.18, 0.24, 1)
                end
            end)
        else
            cb:SetScript("OnEnter", function()
                GameTooltip:SetOwner(cb, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(BT.L.TOOLTIP_AUTO_TRACK, 0.8, 0.8, 0.8, true)
                if todo.autoTrack.type == "currency" then
                    for _, cid in ipairs(todo.autoTrack.currencyIDs or {}) do
                        local info = C_CurrencyInfo.GetCurrencyInfo(cid)
                        if info then
                            GameTooltip:AddLine("|T"..info.iconFileID..":14:14:0:0|t "..info.name, 1, 0.82, 0)
                        end
                    end
                end
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

        -- 标题
        local titleFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        titleFS:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        titleFS:SetPoint("RIGHT", row, "RIGHT", 60, 0)
        titleFS:SetJustifyH("LEFT")
        if completed then
            titleFS:SetText("|cff606060" .. todo.title .. "|r")
        else
            titleFS:SetText(todo.title)
        end
        titleFS:SetTextColor(unpack(BT.COLORS.textNormal))

        -- 重置类型标签
        local resetFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        resetFS:SetPoint("RIGHT", row, "RIGHT", -42, 0)
        resetFS:SetText(BT.ResetTypeLabel(todo.resetType))

        -- 编辑/删除按钮（Shift 时可见）
        local editBtn = CreateFrame("Button", nil, row)
        editBtn:SetSize(18, 18)
        editBtn:SetPoint("RIGHT", row, "RIGHT", -20, 0)
        local editTex = editBtn:CreateTexture(nil, "ARTWORK")
        editTex:SetAllPoints()
        editTex:SetAtlas("lorewalking-map-icon")
        editBtn:SetScript("OnEnter", function() editTex:SetVertexColor(0.3, 0.7, 1) end)
        editBtn:SetScript("OnLeave", function() editTex:SetVertexColor(1, 1, 1) end)
        editBtn:SetScript("OnClick", function()
            DB.OpenTodoForm("warband", todo.id)
        end)
        editBtn:Hide()
        table.insert(shiftButtons, editBtn)

        local delBtn = CreateFrame("Button", nil, row)
        delBtn:SetSize(18, 18)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        local delTex = delBtn:CreateTexture(nil, "ARTWORK")
        delTex:SetAllPoints()
        delTex:SetAtlas("SCRAP-activated")
        delBtn:SetScript("OnEnter", function() delTex:SetVertexColor(1, 0.3, 0.3) end)
        delBtn:SetScript("OnLeave", function() delTex:SetVertexColor(1, 1, 1) end)
        delBtn:SetScript("OnClick", function()
            DB.ConfirmDelete(todo.id)
        end)
        delBtn:Hide()
        table.insert(shiftButtons, delBtn)

        -- Tooltip（details）
        if todo.details and todo.details ~= "" then
            row:SetScript("OnEnter", function(self)
                if dragState then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(todo.title, 1, 1, 1)
                GameTooltip:AddLine(todo.details, 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

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
            if todo.details and todo.details ~= "" then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(todo.title, 1, 1, 1)
                GameTooltip:AddLine(todo.details, 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end
        end)

        MakeDragTarget(row, "todo", todo.id, todo.categoryID, "warband", todo.title, dragItemsLeft)
        table.insert(dragItemsLeft, { type="todo", id=todo.id, catID=todo.categoryID, frame=row })
        table.insert(leftRows, row)
        y = y + ROW_H + 2

        end -- if matches
    end

    leftContent:SetHeight(math.max(y, 40))
end

-- ── 动态渲染：右列（角色事项矩阵）──────────────────────────────────────

local rightRows = {}
local charHeadCells = {}

local function ClearRightContent()
    for _, r in ipairs(rightRows) do r:Hide() end
    rightRows = {}
    for _, c in ipairs(charHeadCells) do c:Hide() end
    charHeadCells = {}
    activeRowClips = {}
end

local function RefreshRightColumn(filterText)
    ClearRightContent()
    dragItemsRight = {}

    local todos = BT.Data.GetCharacterTodos()
    local chars = {}
    local ck = BT.charKey
    -- 当前角色强制第一
    if ck and BrainTaskDB.knownChars[ck] then
        table.insert(chars, { key = ck, info = BrainTaskDB.knownChars[ck] })
    end
    -- 按 charOrder 顺序添加其余角色（跳过隐藏的）
    local hidden = BrainTaskDB.hiddenChars or {}
    for _, k in ipairs(BrainTaskDB.charOrder or {}) do
        if k ~= ck and BrainTaskDB.knownChars[k] and not hidden[k] then
            table.insert(chars, { key = k, info = BrainTaskDB.knownChars[k] })
        end
    end
    -- 兜底：不在 charOrder 里的角色（跳过隐藏的）
    for k, info in pairs(BrainTaskDB.knownChars) do
        local seen = false
        for _, c in ipairs(chars) do if c.key == k then seen = true; break end end
        if not seen and not hidden[k] then table.insert(chars, { key = k, info = info }) end
    end

    -- 预计算每个角色的完成统计
    local charStats = {}
    for _, charEntry in ipairs(chars) do
        local ck = charEntry.key
        local enabled, done = 0, 0
        for _, t in ipairs(todos) do
            if t.enabledChars and t.enabledChars[ck] then
                enabled = enabled + 1
                if BT.Data.GetCharCompleted(t.id, ck) then done = done + 1 end
            end
        end
        charStats[ck] = { enabled=enabled, done=done }
    end

    -- 角色列头：当前角色固定，其余进入横向滚动区
    local numOtherChars = math.max(#chars - 1, 0)
    headClipContent:SetWidth(math.max(numOtherChars * CELL_W, 1))

    for i, charEntry in ipairs(chars) do
        local isCurrent = (i == 1)
        local cellParent = isCurrent and rightHeadFrame or headClipContent
        local cellX      = isCurrent and LABEL_W + 10 or ((i - 2) * CELL_W)

        local cell = CreateFrame("Frame", nil, cellParent)
        cell:SetSize(CELL_W, HEAD_H - 4)
        cell:SetPoint("BOTTOMLEFT", cellParent, "BOTTOMLEFT", cellX, 2)
        local nameFS = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameFS:SetWidth(CELL_W)
        nameFS:SetHeight(14)
        nameFS:SetPoint("TOP", cell, "TOP", 0, -4)
        nameFS:SetText(charEntry.info.name or charEntry.key)
        nameFS:SetJustifyH("CENTER")
        nameFS:SetJustifyV("TOP")
        nameFS:SetWordWrap(false)
        local classKey = charEntry.info and charEntry.info.class
        local clr = classKey and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classKey]
        if clr then
            nameFS:SetTextColor(clr.r, clr.g, clr.b)
        else
            nameFS:SetTextColor(unpack(isCurrent and BT.COLORS.accent or BT.COLORS.textNormal))
        end
        local cst = charStats[charEntry.key] or { enabled=0, done=0 }
        local cstFS = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cstFS:SetWidth(CELL_W)
        cstFS:SetHeight(12)
        cstFS:SetPoint("TOP", nameFS, "BOTTOM", 0, -1)
        cstFS:SetJustifyH("CENTER")
        cstFS:SetText("|cff666666" .. cst.done .. "/" .. cst.enabled .. "|r")
        cell:Show()
        table.insert(charHeadCells, cell)
    end

    -- 事项行
    local y = 0
    local lastCat = -1

    for _, todo in ipairs(todos) do
        local matches = not (filterText and filterText ~= "") or
            string.find(string.lower(todo.title), string.lower(filterText), 1, true)
        if matches then

        -- 分类标题
        if todo.categoryID ~= lastCat then
            lastCat = todo.categoryID
            local catRow = CreateFrame("Frame", nil, rightContent)
            catRow:SetHeight(20)
            catRow:SetPoint("TOPLEFT",  rightContent, "TOPLEFT",  0, -y)
            catRow:SetPoint("TOPRIGHT", rightContent, "TOPRIGHT", 0, -y)
            local catBg = catRow:CreateTexture(nil, "BACKGROUND")
            catBg:SetAllPoints()
            catBg:SetColorTexture(0.14, 0.14, 0.20, 1)
            local catFS = catRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            catFS:SetPoint("LEFT", catRow, "LEFT", 8, 0)
            catFS:SetTextColor(unpack(BT.COLORS.accent))
            local catTitle = BT.Data.GetCategoryTitle(todo.categoryID)
            catFS:SetText(catTitle)
            MakeDragTarget(catRow, "category", todo.categoryID, nil, nil, catTitle, dragItemsRight)
            table.insert(dragItemsRight, { type="category", id=todo.categoryID, frame=catRow })
            table.insert(rightRows, catRow)
            y = y + 20
        end

        local row = CreateFrame("Frame", nil, rightContent)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT",  rightContent, "TOPLEFT",  0, -y)
        row:SetPoint("TOPRIGHT", rightContent, "TOPRIGHT", 0, -y)

        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        rowBg:SetColorTexture(1, 1, 1, (#rightRows % 2 == 0) and 0.05 or 0.02)

        -- 事项标题（左侧固定列）
        local titleFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        titleFS:SetPoint("LEFT",  row, "LEFT", 8, 0)
        titleFS:SetPoint("RIGHT", row, "LEFT", LABEL_W - 60, 0)
        titleFS:SetJustifyH("LEFT")
        titleFS:SetText(todo.title)
        titleFS:SetTextColor(unpack(BT.COLORS.textNormal))

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
        end)

        -- 重置类型标签（[日]/[周]），与战团列保持相同布局（editB 左侧 6px 间距）
        local resetFSR = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        resetFSR:SetPoint("RIGHT", row, "LEFT", LABEL_W - 42, 0)
        resetFSR:SetJustifyH("RIGHT")
        resetFSR:SetText(BT.ResetTypeLabel(todo.resetType))

        -- 编辑/删除（Shift 时可见）
        local editB = CreateFrame("Button", nil, row)
        editB:SetSize(16, 16)
        local eTex = editB:CreateTexture(nil, "ARTWORK")
        eTex:SetAllPoints()
        eTex:SetAtlas("lorewalking-map-icon")
        editB:SetScript("OnEnter", function() eTex:SetVertexColor(0.3, 0.7, 1) end)
        editB:SetScript("OnLeave", function() eTex:SetVertexColor(1, 1, 1) end)
        editB:SetScript("OnClick", function() DB.OpenTodoForm("character", todo.id) end)
        editB:Hide()
        table.insert(shiftButtons, editB)

        local delB = CreateFrame("Button", nil, row)
        delB:SetSize(16, 16)
        delB:SetPoint("RIGHT", row, "LEFT", LABEL_W - 2, 0)
        editB:SetPoint("RIGHT", delB, "LEFT", -2, 0)
        local dTex = delB:CreateTexture(nil, "ARTWORK")
        dTex:SetAllPoints()
        dTex:SetAtlas("SCRAP-activated")
        delB:SetScript("OnEnter", function() dTex:SetVertexColor(1, 0.3, 0.3) end)
        delB:SetScript("OnLeave", function() dTex:SetVertexColor(1, 1, 1) end)
        delB:SetScript("OnClick", function() DB.ConfirmDelete(todo.id) end)
        delB:Hide()
        table.insert(shiftButtons, delB)

        -- 多角色完成进度（非 Shift 时显示）
        local enabledCount, doneCount = 0, 0
        for _, c in ipairs(chars) do
            if todo.enabledChars and todo.enabledChars[c.key] then
                enabledCount = enabledCount + 1
                if BT.Data.GetCharCompleted(todo.id, c.key) then
                    doneCount = doneCount + 1
                end
            end
        end
        local statsLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        statsLbl:SetWidth(40)
        statsLbl:SetPoint("CENTER", row, "LEFT", LABEL_W - 19, 0)
        statsLbl:SetJustifyH("CENTER")
        statsLbl:SetText("|cff666666" .. doneCount .. "/" .. enabledCount .. "|r")
        table.insert(nonShiftLabels, statsLbl)

        -- 角色格子：当前角色固定，其余进入横向滚动区
        local rowClipContent = nil
        if #chars > 1 then
            local rowClip = CreateFrame("ScrollFrame", nil, row)
            rowClip:SetPoint("TOPLEFT",     row, "TOPLEFT",     LABEL_W + CELL_W + 10, 0)
            rowClip:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0,                0)
            rowClipContent = CreateFrame("Frame", nil, rowClip)
            rowClipContent:SetWidth(math.max((#chars - 1) * CELL_W, 1))
            rowClipContent:SetHeight(ROW_H)
            rowClip:SetScrollChild(rowClipContent)
            rowClip:EnableMouseWheel(true)
            rowClip:SetScript("OnMouseWheel", function(_, delta)
                ApplyHScroll(hScrollOffset - delta * CELL_W)
            end)
            table.insert(activeRowClips, rowClip)
        end

        for i, charEntry in ipairs(chars) do
            local charKey  = charEntry.key
            local todoID   = todo.id
            local isCurrent = (i == 1)
            local cellParent = isCurrent and row or rowClipContent
            local cellX      = isCurrent and LABEL_W + 10 or ((i - 2) * CELL_W)

            local cell = CreateFrame("Button", nil, cellParent)
            cell:SetSize(CELL_W, ROW_H)
            cell:SetPoint("LEFT", cellParent, "LEFT", cellX, 0)

            local cbSize = 13
            local cellBg = cell:CreateTexture(nil, "BACKGROUND")
            cellBg:SetSize(cbSize, cbSize)
            cellBg:SetPoint("CENTER", cell, "CENTER")

            local cellCheck = cell:CreateTexture(nil, "OVERLAY")
            cellCheck:SetSize(cbSize - 1, cbSize - 1)
            cellCheck:SetPoint("CENTER", cell, "CENTER")
            cellCheck:SetTexture("Interface/Buttons/UI-CheckBox-Check")
            cellCheck:SetVertexColor(0.3, 0.9, 0.3, 1)
            cellCheck:Hide()

            local function UpdateCell()
                local en = todo.enabledChars and todo.enabledChars[charKey]
                local cp = en and BT.Data.GetCharCompleted(todoID, charKey)
                if not en then
                    cellBg:SetColorTexture(0.15, 0.15, 0.18, 0.3)
                    cellCheck:Hide()
                elseif cp then
                    cellBg:SetColorTexture(0.12, 0.28, 0.12, 1)
                    cellCheck:Show()
                else
                    cellBg:SetColorTexture(0.18, 0.18, 0.28, 1)
                    cellCheck:Hide()
                end
            end
            UpdateCell()

            local autoTracked = todo.autoTrack and (todo.autoTrack.type == "quest" or todo.autoTrack.type == "instance_boss" or todo.autoTrack.type == "currency")
            cell:SetScript("OnClick", function()
                local en = todo.enabledChars and todo.enabledChars[charKey]
                if IsShiftKeyDown() then
                    BT.Data.SetEnabled(todoID, charKey, not en)
                elseif en and not autoTracked then
                    local cp = BT.Data.GetCharCompleted(todoID, charKey)
                    BT.Data.SetCharCompleted(todoID, charKey, not cp)
                end
                UpdateCell()
            end)
            cell:SetScript("OnEnter", function()
                GameTooltip:SetOwner(cell, "ANCHOR_TOP")
                GameTooltip:ClearLines()
                local en = todo.enabledChars and todo.enabledChars[charKey]
                if en then
                    if autoTracked then
                        GameTooltip:AddLine(BT.L.TOOLTIP_AUTO_TRACK, 0.8, 0.8, 0.8, true)
                        if todo.autoTrack.type == "currency" then
                            for _, cid in ipairs(todo.autoTrack.currencyIDs or {}) do
                                local info = C_CurrencyInfo.GetCurrencyInfo(cid)
                                if info then
                                    GameTooltip:AddLine("|T"..info.iconFileID..":14:14:0:0|t "..info.name, 1, 0.82, 0)
                                end
                            end
                        end
                    else
                        local cp = BT.Data.GetCharCompleted(todoID, charKey)
                        GameTooltip:AddLine(cp and BT.L.TOOLTIP_CLICK_UNDO or BT.L.TOOLTIP_CLICK_DONE, 0.8, 0.8, 0.8)
                    end
                    GameTooltip:AddLine(BT.L.TOOLTIP_SHIFT_DIS, 0.55, 0.55, 0.6)
                else
                    GameTooltip:AddLine(BT.L.TOOLTIP_SHIFT_EN, 0.8, 0.8, 0.8)
                end
                GameTooltip:Show()
            end)
            cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

        MakeDragTarget(row, "todo", todo.id, todo.categoryID, "character", todo.title, dragItemsRight)
        table.insert(dragItemsRight, { type="todo", id=todo.id, catID=todo.categoryID, frame=row })
        table.insert(rightRows, row)
        y = y + ROW_H + 2

        end -- if matches
    end

    rightContent:SetHeight(math.max(y, 40))

    -- 更新横向滚动范围并恢复偏移
    local numOtherChars = math.max(#chars - 1, 0)
    local visibleW      = math.max(headClipScroll:GetWidth(), 1)
    hScrollMaxOffset = math.max(0, numOtherChars * CELL_W - visibleW)
    if hScrollMaxOffset > 0 then
        hScrollBar:Show()
        local trackW    = math.max(scrollTrack:GetWidth(), 1)
        local visRatio  = visibleW / math.max(numOtherChars * CELL_W, 1)
        scrollThumb:SetWidth(math.max(20, trackW * visRatio))
    else
        hScrollBar:Hide()
    end
    ApplyHScroll(hScrollOffset)
end

-- ── 顶部筛选框 ────────────────────────────────────────────────────────────

local filterBox = CreateFrame("EditBox", nil, topBar, "BackdropTemplate")
filterBox:SetSize(200, 22)
filterBox:SetPoint("RIGHT", closeBtn, "LEFT", -10, 0)
filterBox:SetTextInsets(4, 22, 0, 0)
filterBox:SetBackdrop(BT.BACKDROP)
filterBox:SetBackdropColor(0.10, 0.10, 0.14, 1)
filterBox:SetBackdropBorderColor(unpack(BT.COLORS.border))
filterBox:SetFont("Fonts/FRIZQT__.TTF", 11, "")
filterBox:SetTextColor(0.9, 0.9, 0.9)
filterBox:SetAutoFocus(false)
filterBox:SetMaxLetters(64)

local clearBtn = CreateFrame("Button", nil, filterBox)
clearBtn:SetSize(18, 18)
clearBtn:SetPoint("RIGHT", filterBox, "RIGHT", -2, 0)
local clearTex = clearBtn:CreateTexture(nil, "ARTWORK")
clearTex:SetAllPoints()
clearTex:SetAtlas("uitools-icon-close")
clearTex:SetAlpha(0.4)
clearBtn:SetScript("OnEnter", function() clearTex:SetAlpha(1) end)
clearBtn:SetScript("OnLeave", function() clearTex:SetAlpha(0.4) end)
clearBtn:SetScript("OnClick", function()
    filterBox:SetText("")
    filterBox:ClearFocus()
end)

local filterHint = filterBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
filterHint:SetPoint("LEFT", filterBox, "LEFT", 6, 0)
filterHint:SetTextColor(0.4, 0.4, 0.45)
filterHint:SetText(BT.L.SEARCH_HINT)

filterBox:SetScript("OnTextChanged", function(self)
    local txt = self:GetText()
    filterHint:SetShown(txt == "")
    RefreshLeftColumn(txt)
    RefreshRightColumn(txt)
end)
filterBox:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    self:ClearFocus()
end)

-- ── 待办事项表单（添加/编辑）弹窗 ───────────────────────────────────────

local formFrame = BT.CreateBackdropFrame("Frame", nil, frame, 380, 510)
formFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
formFrame:SetFrameStrata("DIALOG")
formFrame:EnableMouse(true)
formFrame:Hide()

local formBG = formFrame:CreateTexture(nil, "BACKGROUND")
formBG:SetAllPoints()
formBG:SetColorTexture(0, 0, 0, 0.5)

local formTitle = formFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
formTitle:SetPoint("TOP", formFrame, "TOP", 0, -14)
formTitle:SetText(BT.L.FORM_TITLE_ADD)
formTitle:SetTextColor(unpack(BT.COLORS.textTitle))

-- 关闭表单
local formClose = CreateFrame("Button", nil, formFrame)
formClose:SetSize(20, 20)
formClose:SetPoint("TOPRIGHT", formFrame, "TOPRIGHT", -8, -8)
local fcTex = formClose:CreateTexture(nil, "ARTWORK")
fcTex:SetAllPoints()
fcTex:SetAtlas("uitools-icon-close")
formClose:SetScript("OnClick", function() formFrame:Hide() end)
formClose:SetScript("OnEnter", function() fcTex:SetVertexColor(1, 0.3, 0.3) end)
formClose:SetScript("OnLeave", function() fcTex:SetVertexColor(1, 1, 1) end)

local function MakeFieldLabel(parent, text, yOffset)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, yOffset)
    lbl:SetText(text)
    lbl:SetTextColor(unpack(BT.COLORS.textMuted))
    return lbl
end

local function MakeEditBox(parent, yOffset, w, h, multiLine)
    if multiLine then
        -- 用外层 Frame 固定可视区域
        local wrapper = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        wrapper:SetSize(w or 340, h or 100)
        wrapper:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, yOffset)
        wrapper:SetBackdrop(BT.BACKDROP)
        wrapper:SetBackdropColor(0.10, 0.10, 0.14, 1)
        wrapper:SetBackdropBorderColor(unpack(BT.COLORS.border))

        local scrollFrame = CreateFrame("ScrollFrame", nil, wrapper, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT",     wrapper, "TOPLEFT",      3,  -3)
        scrollFrame:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", -22,  3)

        local ebWidth = (w or 340) - 3 - 22 - 3
        local eb = CreateFrame("EditBox", nil, scrollFrame)
        eb:SetSize(ebWidth, scrollFrame:GetHeight() or 80)
        eb:SetMultiLine(true)
        eb:SetFont("Fonts/FRIZQT__.TTF", 11, "")
        eb:SetTextColor(0.9, 0.9, 0.9)
        eb:SetAutoFocus(false)
        eb:SetMaxLetters(256)
        eb:SetScript("OnTabPressed",      function(self) self:ClearFocus() end)
        eb:SetScript("OnEscapePressed",   function(self) self:ClearFocus() end)
        eb:SetScript("OnEditFocusGained", function(self) BT.activeLinkEditBox = self end)
        eb:SetScript("OnEditFocusLost",   function(self)
            if BT.activeLinkEditBox == self then BT.activeLinkEditBox = nil end
        end)
        eb:SetScript("OnTextChanged", function(self)
            local _, fontSize = self:GetFont()
            local contentH = math.max(1, self:GetNumLines()) * (fontSize + 2) + 10
            self:SetHeight(math.max(scrollFrame:GetHeight(), contentH))
        end)
        scrollFrame:SetScrollChild(eb)
        return eb
    end
    local eb = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    eb:SetSize(w or 340, h or 24)
    eb:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, yOffset)
    eb:SetBackdrop(BT.BACKDROP)
    eb:SetBackdropColor(0.10, 0.10, 0.14, 1)
    eb:SetBackdropBorderColor(unpack(BT.COLORS.border))
    eb:SetFont("Fonts/FRIZQT__.TTF", 11, "")
    eb:SetTextColor(0.9, 0.9, 0.9)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(256)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function(self) BT.activeLinkEditBox = self end)
    eb:SetScript("OnEditFocusLost",   function(self)
        if BT.activeLinkEditBox == self then BT.activeLinkEditBox = nil end
    end)
    return eb
end

-- 表单字段
local _flTitle   = MakeFieldLabel(formFrame, BT.L.FIELD_TITLE,       -42)
local fTitle   = MakeEditBox(formFrame, -58, 340, 24)

local _flDetails = MakeFieldLabel(formFrame, BT.L.FIELD_DETAILS,     -92)
local fDetails = MakeEditBox(formFrame, -108, 340, 100, true)

local _flCat     = MakeFieldLabel(formFrame, BT.L.FIELD_CATEGORY,       -220)
local UpdateSaveBtn  -- forward declaration（须在 RefreshCatDropList 之前声明，以便闭包捕获）

-- 分类下拉（简单按钮实现）
local catDropBtn = BT.CreateButton(formFrame, BT.L.SELECT_CATEGORY, 200, 24)
catDropBtn:SetPoint("TOPLEFT", formFrame, "TOPLEFT", 16, -236)
local selectedCatID = nil

local catDropList = CreateFrame("Frame", nil, formFrame)
catDropList:SetSize(200, 1)
catDropList:SetPoint("TOPLEFT", catDropBtn, "BOTTOMLEFT", 0, -2)
catDropList:SetFrameStrata("FULLSCREEN_DIALOG")
catDropList:EnableMouse(true)
-- 纯色不透明背景（sublayer 0 = 边框色，sublayer 1 = 内部填充色，内缩 1px 显示边框）
local _cdBorder = catDropList:CreateTexture(nil, "BACKGROUND", nil, 0)
_cdBorder:SetAllPoints()
_cdBorder:SetColorTexture(0.22, 0.22, 0.32, 1)
local _cdBg = catDropList:CreateTexture(nil, "BACKGROUND", nil, 1)
_cdBg:SetPoint("TOPLEFT",     catDropList, "TOPLEFT",     1, -1)
_cdBg:SetPoint("BOTTOMRIGHT", catDropList, "BOTTOMRIGHT", -1,  1)
_cdBg:SetColorTexture(0.10, 0.10, 0.14, 1)
catDropList:Hide()

local function RefreshCatDropList()
    -- 清空旧内容
    for _, child in ipairs({ catDropList:GetChildren() }) do
        child:Hide()
    end
    local cats = BT.Data.GetCategories()
    local listH = 0
    for i, cat in ipairs(cats) do
        local item = CreateFrame("Button", nil, catDropList)
        item:SetHeight(22)
        item:SetPoint("TOPLEFT",  catDropList, "TOPLEFT",  2, -listH)
        item:SetPoint("TOPRIGHT", catDropList, "TOPRIGHT", -2, -listH)
        local itemFS = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemFS:SetAllPoints()
        itemFS:SetText(cat.title)
        itemFS:SetJustifyH("LEFT")
        itemFS:SetTextColor(0.9, 0.9, 0.9)
        local iBg = item:CreateTexture(nil, "BACKGROUND")
        iBg:SetAllPoints() iBg:SetColorTexture(0,0,0,0)
        item:SetScript("OnEnter", function() iBg:SetColorTexture(1,1,1,0.06) end)
        item:SetScript("OnLeave", function() iBg:SetColorTexture(0,0,0,0) end)
        local catID = cat.id
        local catTitle = cat.title
        item:SetScript("OnClick", function()
            selectedCatID = catID
            catDropBtn.label:SetText(catTitle)
            catDropList:Hide()
            if UpdateSaveBtn then UpdateSaveBtn() end
        end)
        item:Show()
        listH = listH + 22
    end
    catDropList:SetHeight(math.max(listH, 10))
end

catDropBtn:SetScript("OnClick", function()
    if catDropList:IsVisible() then
        catDropList:Hide()
    else
        RefreshCatDropList()
        catDropList:Show()
    end
end)

local _flReset   = MakeFieldLabel(formFrame, BT.L.FIELD_RESET,     -272)

-- 重置类型选择
local resetTypes = { { id = "none", label = BT.L.RESET_NONE }, { id = "daily", label = BT.L.RESET_DAILY }, { id = "weekly", label = BT.L.RESET_WEEKLY } }
local selectedReset = "none"
local resetBtns = {}

for i, rt in ipairs(resetTypes) do
    local rb = BT.CreateButton(formFrame, rt.label, 80, 22)
    rb:SetPoint("TOPLEFT", formFrame, "TOPLEFT", 16 + (i - 1) * 88, -288)
    local rtID = rt.id
    rb:SetScript("OnClick", function()
        selectedReset = rtID
        for _, b in ipairs(resetBtns) do
            b.isSelected = false
            b:SetBackdropColor(0.15, 0.15, 0.22, 1)
            b:SetBackdropBorderColor(unpack(BT.COLORS.border))
        end
        rb.isSelected = true
        rb:SetBackdropColor(0.18, 0.35, 0.55, 1)
    end)
    rb:SetScript("OnLeave", function(self)
        if self.isSelected then
            self:SetBackdropColor(0.18, 0.35, 0.55, 1)
        else
            self:SetBackdropColor(0.15, 0.15, 0.22, 1)
        end
        self:SetBackdropBorderColor(unpack(BT.COLORS.border))
    end)
    table.insert(resetBtns, rb)
end
resetBtns[1].isSelected = true
resetBtns[1]:SetBackdropColor(0.18, 0.35, 0.55, 1)

local _flTrack   = MakeFieldLabel(formFrame, BT.L.FIELD_AUTO_TRACK,     -322)

-- 追踪类型选择
local trackTypes = { { id = "none", label = BT.L.TRACK_NONE }, { id = "quest", label = BT.L.TRACK_QUEST }, { id = "instance_boss", label = BT.L.TRACK_BOSS }, { id = "currency", label = BT.L.TRACK_CURRENCY } }
local selectedTrack = "none"
local trackBtns = {}

for i, tt in ipairs(trackTypes) do
    local tb = BT.CreateButton(formFrame, tt.label, 80, 22)
    tb:SetPoint("TOPLEFT", formFrame, "TOPLEFT", 16 + (i - 1) * 86, -338)
    local ttID = tt.id
    tb:SetScript("OnClick", function()
        selectedTrack = ttID
        for _, b in ipairs(trackBtns) do
            b.isSelected = false
            b:SetBackdropColor(0.15, 0.15, 0.22, 1)
            b:SetBackdropBorderColor(unpack(BT.COLORS.border))
        end
        tb.isSelected = true
        tb:SetBackdropColor(0.18, 0.35, 0.55, 1)
        -- 显示/隐藏子字段
        formFrame.questIDBox:SetShown(ttID == "quest")
        formFrame.questIDLabel:SetShown(ttID == "quest")
        formFrame.bossEncounterIDBox:SetShown(ttID == "instance_boss")
        formFrame.bossEncounterIDLabel:SetShown(ttID == "instance_boss")
        formFrame.currencyIDBox:SetShown(ttID == "currency")
        formFrame.currencyIDLabel:SetShown(ttID == "currency")
    end)
    tb:SetScript("OnLeave", function(self)
        if self.isSelected then
            self:SetBackdropColor(0.18, 0.35, 0.55, 1)
        else
            self:SetBackdropColor(0.15, 0.15, 0.22, 1)
        end
        self:SetBackdropBorderColor(unpack(BT.COLORS.border))
    end)
    table.insert(trackBtns, tb)
end
trackBtns[1].isSelected = true
trackBtns[1]:SetBackdropColor(0.18, 0.35, 0.55, 1)

-- 解析逗号分隔 ID 列表
local function parseIDs(text)
    local ids = {}
    for s in string.gmatch(text or "", "[^,]+") do
        local n = tonumber(s:match("^%s*(.-)%s*$"))
        if n then table.insert(ids, n) end
    end
    return ids
end

-- Quest ID 输入（支持多个逗号分隔）
formFrame.questIDLabel = MakeFieldLabel(formFrame, BT.L.QUEST_ID_LABEL, -368)
formFrame.questIDLabel:Hide()
formFrame.questIDBox = MakeEditBox(formFrame, -384, 300, 22)
formFrame.questIDBox:Hide()

-- 副本 Boss：输入 Encounter ID（逗号分隔多个）
formFrame.bossEncounterIDLabel = MakeFieldLabel(formFrame, BT.L.ENCOUNTER_ID_LABEL, -368)
formFrame.bossEncounterIDLabel:Hide()
formFrame.bossEncounterIDBox = MakeEditBox(formFrame, -384, 300, 22)
formFrame.bossEncounterIDBox:Hide()

-- 货币上限：输入 Currency ID（逗号分隔多个）
formFrame.currencyIDLabel = MakeFieldLabel(formFrame, BT.L.CURRENCY_ID_LABEL, -368)
formFrame.currencyIDLabel:Hide()
formFrame.currencyIDBox = MakeEditBox(formFrame, -384, 300, 22)
formFrame.currencyIDBox:Hide()

-- 保存按钮
local formEditingID  = nil
local formEditScope  = nil

local function ResetForm()
    fTitle:SetText("")
    fDetails:SetText("")
    selectedCatID  = nil
    selectedReset  = "none"
    selectedTrack  = "none"
    catDropBtn.label:SetText(BT.L.SELECT_CATEGORY)
    for i, b in ipairs(resetBtns)  do b.isSelected = false; b:SetBackdropColor(0.15, 0.15, 0.22, 1) end
    for i, b in ipairs(trackBtns)  do b.isSelected = false; b:SetBackdropColor(0.15, 0.15, 0.22, 1) end
    resetBtns[1].isSelected = true; resetBtns[1]:SetBackdropColor(0.18, 0.35, 0.55, 1)
    trackBtns[1].isSelected = true; trackBtns[1]:SetBackdropColor(0.18, 0.35, 0.55, 1)
    formFrame.questIDBox:SetText("")
    formFrame.questIDBox:Hide()
    formFrame.questIDLabel:Hide()
    formFrame.bossEncounterIDBox:SetText("")
    formFrame.bossEncounterIDBox:Hide()
    formFrame.bossEncounterIDLabel:Hide()
    formFrame.currencyIDBox:SetText("")
    formFrame.currencyIDBox:Hide()
    formFrame.currencyIDLabel:Hide()
    formEditingID = nil
    formEditScope = nil
    if UpdateSaveBtn then UpdateSaveBtn() end
end

local saveBtn = BT.CreateButton(formFrame, BT.L.BTN_SAVE, 100, 26)
saveBtn:SetPoint("BOTTOMRIGHT", formFrame, "BOTTOMRIGHT", -16, 12)
saveBtn:SetScript("OnClick", function()
    local title = fTitle:GetText()
    if not title or title == "" then
        print("|cffff4444[BrainTask]|r " .. BT.L.ERR_TITLE_EMPTY)
        return
    end
    if not selectedCatID then
        print("|cffff4444[BrainTask]|r " .. BT.L.ERR_NO_CATEGORY)
        return
    end

    local autoTrack = nil
    if selectedTrack == "quest" then
        local ids = parseIDs(formFrame.questIDBox:GetText())
        if #ids > 0 then autoTrack = { type = "quest", questIDs = ids } end
    elseif selectedTrack == "instance_boss" then
        local encIDs = parseIDs(formFrame.bossEncounterIDBox:GetText())
        if #encIDs > 0 then
            autoTrack = { type = "instance_boss", encounterIDs = encIDs }
        end
    elseif selectedTrack == "currency" then
        local cids = parseIDs(formFrame.currencyIDBox:GetText())
        if #cids > 0 then autoTrack = { type = "currency", currencyIDs = cids } end
    end

    local opts = {
        title      = title,
        details    = fDetails:GetText() ~= "" and fDetails:GetText() or nil,
        scope      = formEditScope or "warband",
        categoryID = selectedCatID,
        resetType  = selectedReset,
        autoTrack  = autoTrack,
    }

    if formEditingID then
        BT.Data.UpdateTodo(formEditingID, opts)
    else
        BT.Data.CreateTodo(opts)
    end
    formFrame:Hide()
    ResetForm()
end)

UpdateSaveBtn = function()
    local ok = (fTitle:GetText() ~= "") and (selectedCatID ~= nil)
    saveBtn:SetEnabled(ok)
    saveBtn.label:SetTextColor(ok and 1 or 0.45, ok and 1 or 0.45, ok and 1 or 0.45)
end

fTitle:SetScript("OnTextChanged", function() UpdateSaveBtn() end)

local cancelBtn = BT.CreateButton(formFrame, BT.L.BTN_CANCEL, 80, 26)
cancelBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0)
cancelBtn:SetScript("OnClick", function()
    formFrame:Hide()
    ResetForm()
end)

-- ── 删除确认弹窗 ──────────────────────────────────────────────────────────

local confirmFrame = BT.CreateBackdropFrame("Frame", nil, frame, 280, 110)
confirmFrame:SetPoint("CENTER", frame, "CENTER")
confirmFrame:SetFrameStrata("DIALOG")
confirmFrame:EnableMouse(true)
confirmFrame:Hide()

local confirmFS = confirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
confirmFS:SetPoint("CENTER", confirmFrame, "CENTER", 0, 20)
confirmFS:SetText(BT.L.CONFIRM_DEL_TODO)
confirmFS:SetTextColor(1, 0.8, 0.2)

local confirmYes = BT.CreateButton(confirmFrame, BT.L.BTN_DELETE, 90, 26)
confirmYes:SetPoint("BOTTOMRIGHT", confirmFrame, "BOTTOM", -4, 10)

local confirmNo = BT.CreateButton(confirmFrame, BT.L.BTN_CANCEL, 90, 26)
confirmNo:SetPoint("BOTTOMLEFT", confirmFrame, "BOTTOM", 4, 10)
confirmNo:SetScript("OnClick", function() confirmFrame:Hide() end)

function DB.ConfirmDelete(todoID)
    confirmYes:SetScript("OnClick", function()
        BT.Data.DeleteTodo(todoID)
        confirmFrame:Hide()
    end)
    confirmFrame:Show()
end

-- ── 公共接口 ──────────────────────────────────────────────────────────────

function DB.OpenTodoForm(scope, editID)
    ResetForm()
    formEditScope = scope or "warband"
    formTitle:SetText(editID and BT.L.FORM_TITLE_EDIT or
        (scope == "warband" and BT.L.FORM_TITLE_WARBAND or BT.L.FORM_TITLE_CHAR))

    if editID then
        formEditingID = editID
        local todo = BrainTaskDB.todos[editID]
        if todo then
            fTitle:SetText(todo.title or "")
            fDetails:SetText(todo.details or "")
            selectedCatID = todo.categoryID
            local catTitle = BT.Data.GetCategoryTitle(todo.categoryID)
            catDropBtn.label:SetText(catTitle)
            selectedReset = todo.resetType or "none"
            for i, b in ipairs(resetBtns) do
                b.isSelected = false
                b:SetBackdropColor(0.15, 0.15, 0.22, 1)
            end
            for i, rt in ipairs(resetTypes) do
                if rt.id == selectedReset then
                    resetBtns[i].isSelected = true
                    resetBtns[i]:SetBackdropColor(0.18, 0.35, 0.55, 1)
                    break
                end
            end
            if todo.autoTrack then
                selectedTrack = todo.autoTrack.type
                for i, tt in ipairs(trackTypes) do
                    if tt.id == selectedTrack then
                        trackBtns[i].isSelected = true
                        trackBtns[i]:SetBackdropColor(0.18, 0.35, 0.55, 1)
                    else
                        trackBtns[i].isSelected = false
                        trackBtns[i]:SetBackdropColor(0.15, 0.15, 0.22, 1)
                    end
                end
                if selectedTrack == "quest" then
                    local qids = todo.autoTrack.questIDs
                        or (todo.autoTrack.questID and {todo.autoTrack.questID})
                        or {}
                    formFrame.questIDBox:SetText(table.concat(qids, ", "))
                    formFrame.questIDBox:Show()
                    formFrame.questIDLabel:Show()
                elseif selectedTrack == "instance_boss" then
                    local encIDs = todo.autoTrack.encounterIDs or {}
                    formFrame.bossEncounterIDBox:SetText(table.concat(encIDs, ", "))
                    formFrame.bossEncounterIDBox:Show()
                    formFrame.bossEncounterIDLabel:Show()
                elseif selectedTrack == "currency" then
                    local cids = todo.autoTrack.currencyIDs or {}
                    formFrame.currencyIDBox:SetText(table.concat(cids, ", "))
                    formFrame.currencyIDBox:Show()
                    formFrame.currencyIDLabel:Show()
                end
            end
        end
    end
    UpdateSaveBtn()
    formFrame:Show()
end

-- ── 本地化刷新 ────────────────────────────────────────────────────────────

BT.Locale.Register(function()
    -- 底部工具栏
    addWarbandBtn.label:SetText(BT.L.BTN_ADD_WARBAND)
    addCharBtn.label:SetText(BT.L.BTN_ADD_CHAR)
    globalSettingsBtn.label:SetText(BT.L.BTN_SETTINGS)
    settingsBtn.label:SetText(BT.L.BTN_CATEGORY_MGMT)
    sortCharsBtn.label:SetText(BT.L.BTN_CHAR_MGMT)
    lockLabel:SetText(BT.L.LBL_LOCK_WINDOW)
    -- 列标题
    leftHeadFS:SetText("|cffaa88ff" .. BT.L.COL_WARBAND .. "|r")
    rightLabel:SetText("|cff88bbff" .. BT.L.COL_CHAR .. "|r")
    filterHint:SetText(BT.L.SEARCH_HINT)
    -- 表单字段标签
    _flTitle:SetText(BT.L.FIELD_TITLE)
    _flDetails:SetText(BT.L.FIELD_DETAILS)
    _flCat:SetText(BT.L.FIELD_CATEGORY)
    _flReset:SetText(BT.L.FIELD_RESET)
    _flTrack:SetText(BT.L.FIELD_AUTO_TRACK)
    formFrame.questIDLabel:SetText(BT.L.QUEST_ID_LABEL)
    formFrame.bossEncounterIDLabel:SetText(BT.L.ENCOUNTER_ID_LABEL)
    formFrame.currencyIDLabel:SetText(BT.L.CURRENCY_ID_LABEL)
    -- 重置类型 / 追踪类型按钮
    resetBtns[1].label:SetText(BT.L.RESET_NONE)
    resetBtns[2].label:SetText(BT.L.RESET_DAILY)
    resetBtns[3].label:SetText(BT.L.RESET_WEEKLY)
    trackBtns[1].label:SetText(BT.L.TRACK_NONE)
    trackBtns[2].label:SetText(BT.L.TRACK_QUEST)
    trackBtns[3].label:SetText(BT.L.TRACK_BOSS)
    trackBtns[4].label:SetText(BT.L.TRACK_CURRENCY)
    -- 表单按钮
    saveBtn.label:SetText(BT.L.BTN_SAVE)
    cancelBtn.label:SetText(BT.L.BTN_CANCEL)
    -- 删除确认
    confirmFS:SetText(BT.L.CONFIRM_DEL_TODO)
    confirmYes.label:SetText(BT.L.BTN_DELETE)
    confirmNo.label:SetText(BT.L.BTN_CANCEL)
end)

function DB.Refresh()
    if not frame:IsVisible() then return end
    shiftButtons   = {}
    nonShiftLabels = {}
    lastShiftState = not IsShiftKeyDown()  -- 强制 OnUpdate 重新评估一次
    local filterText = filterBox:GetText()
    RefreshLeftColumn(filterText)
    RefreshRightColumn(filterText)
end

-- OnShow：首次打开时从 DB 恢复布局和锁定状态
local layoutApplied = false
frame:SetScript("OnShow", function()
    if not layoutApplied and BrainTaskDB then
        layoutApplied = true
        local layout = BrainTaskDB.dashboardLayout or {}
        LABEL_W = layout.labelW or 260           -- 直接赋值：在所有布局调用之前设置，绕开对 rightArea 尺寸的依赖
        frame:SetSize(layout.w or WIN_W, layout.h or WIN_H)
        UpdateLayout(layout.leftW or 400)        -- 内部末尾调用 UpdateRightLayout(LABEL_W)，此时 rightArea 已锚定
        SetLocked(layout.locked or false)
        initStage = false                        -- 恢复完成，解除对 OnSizeChanged 的屏蔽
        -- 恢复浮动窗口位置锁定状态
        local locked = BrainTaskDB.floatWindowLocked or false
        floatLockState = locked
        if locked then
            floatLockCheckBg:SetColorTexture(0.10, 0.24, 0.10, 1)
            floatLockCheckMark:Show()
        else
            floatLockCheckBg:SetColorTexture(0.18, 0.18, 0.24, 1)
            floatLockCheckMark:Hide()
        end
        if BT.UI.FloatWindow and BT.UI.FloatWindow.SetPositionLocked then
            BT.UI.FloatWindow.SetPositionLocked(locked)
        end
    end
    DB.Refresh()
end)

function DB.Open()
    frame:Show()   -- OnShow 已处理 Refresh
end

function DB.Close()
    frame:Hide()
end

function DB.Toggle()
    if frame:IsVisible() then DB.Close() else DB.Open() end
end

function DB.SetScale(v)
    frame:SetScale(math.max(0.5, math.min(2.0, v or 1.0)))
end

-- 底部按钮绑定
addWarbandBtn:SetScript("OnClick", function() DB.OpenTodoForm("warband", nil) end)
addCharBtn:SetScript("OnClick",    function() DB.OpenTodoForm("character", nil) end)
