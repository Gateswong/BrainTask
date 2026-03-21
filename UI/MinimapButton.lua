-- BrainTask UI: 小地图按钮

BrainTask = BrainTask or {}
BrainTask.UI = BrainTask.UI or {}
local BT = BrainTask

local btn = CreateFrame("Button", "BrainTaskMinimapButton", Minimap)
btn:SetSize(32, 32)
btn:SetFrameStrata("MEDIUM")
btn:SetFrameLevel(8)

-- 圆形遮罩（点击区域裁剪为圆形）
btn:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")

local bg = btn:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetTexture("Interface/Minimap/UI-Minimap-ZoomButton-Background")

local icon = btn:CreateTexture(nil, "ARTWORK")
icon:SetSize(18, 18)
icon:SetPoint("CENTER")
icon:SetTexture("Interface/ICONS/INV_Misc_Note_06")

local border = btn:CreateTexture(nil, "OVERLAY")
border:SetSize(53, 53)
border:SetPoint("CENTER")
border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")

-- ── 位置（可拖动围绕小地图）──────────────────────────────────────────────

local RADIUS = 80

local function UpdatePosition()
    local angle = BrainTaskDB and BrainTaskDB.minimapAngle or math.rad(225)
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * RADIUS,
        math.sin(angle) * RADIUS)
end

btn:RegisterForDrag("LeftButton")
btn:SetMovable(true)

btn:SetScript("OnDragStart", function(self)
    self.dragging = true
    self:LockHighlight()
end)

btn:SetScript("OnUpdate", function(self)
    if not self.dragging then return end
    local mx, my = Minimap:GetCenter()
    local scale  = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    local angle  = math.atan2(cy - my, cx - mx)
    if BrainTaskDB then BrainTaskDB.minimapAngle = angle end
    UpdatePosition()
end)

btn:SetScript("OnDragStop", function(self)
    self.dragging = false
    self:UnlockHighlight()
end)

-- ── 点击事件 ─────────────────────────────────────────────────────────────

btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
btn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if BT.UI.FloatWindow then BT.UI.FloatWindow.Toggle() end
    elseif button == "RightButton" then
        if BT.UI.Dashboard then BT.UI.Dashboard.Open() end
    end
end)

-- ── Tooltip ───────────────────────────────────────────────────────────────

btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("BrainTask", 0.25, 0.6, 1)
    GameTooltip:AddLine("左键: 切换待办窗口", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("右键: 打开 Dashboard", 0.9, 0.9, 0.9)
    GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ── 初始化位置（在 PLAYER_LOGIN 后 DB 可用时调用）──────────────────────

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    UpdatePosition()
    initFrame:UnregisterEvent("PLAYER_LOGIN")
end)
