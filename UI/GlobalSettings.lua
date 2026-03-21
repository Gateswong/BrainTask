-- BrainTask UI: 全局设置

BrainTask = BrainTask or {}
BrainTask.UI = BrainTask.UI or {}
local BT = BrainTask
BT.UI.GlobalSettings = {}
local GS = BT.UI.GlobalSettings

local WIN_W, WIN_H = 340, 280

-- ── 主框架 ────────────────────────────────────────────────────────────────

local frame = BT.CreateBackdropFrame("Frame", "BrainTaskGlobalSettings", UIParent, WIN_W, WIN_H)
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
titleFS:SetText("|cff55aaff全局设置|r")

local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetSize(20, 20)
closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -8, 0)
local closeTex = closeBtn:CreateTexture(nil, "ARTWORK")
closeTex:SetAllPoints()
closeTex:SetAtlas("uitools-icon-close")
closeBtn:SetScript("OnClick", function() frame:Hide() end)
closeBtn:SetScript("OnEnter", function() closeTex:SetVertexColor(1, 0.3, 0.3) end)
closeBtn:SetScript("OnLeave", function() closeTex:SetVertexColor(1, 1, 1) end)

-- ── 轮询间隔 ─────────────────────────────────────────────────────────────

local pollLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
pollLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -46)
pollLabel:SetText("自动追踪轮询间隔")
pollLabel:SetTextColor(unpack(BT.COLORS.textNormal))

local pollDesc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pollDesc:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -66)
pollDesc:SetTextColor(unpack(BT.COLORS.textMuted))
pollDesc:SetText("Quest 和副本 Boss 的自动完成检测频率（秒，最小 1）")

local pollBox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
pollBox:SetSize(60, 26)
pollBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -90)
pollBox:SetBackdrop(BT.BACKDROP)
pollBox:SetBackdropColor(0.10, 0.10, 0.14, 1)
pollBox:SetBackdropBorderColor(unpack(BT.COLORS.border))
pollBox:SetFont("Fonts/FRIZQT__.TTF", 12, "")
pollBox:SetTextColor(0.9, 0.9, 0.9)
pollBox:SetAutoFocus(false)
pollBox:SetMaxLetters(4)
pollBox:SetNumeric(true)
pollBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local pollApplyBtn = BT.CreateButton(frame, "应用", 70, 26)
pollApplyBtn:SetPoint("LEFT", pollBox, "RIGHT", 8, 0)

local pollCurFS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pollCurFS:SetPoint("LEFT", pollApplyBtn, "RIGHT", 10, 0)
pollCurFS:SetTextColor(unpack(BT.COLORS.textMuted))

local function ApplyPollInterval()
    local val = math.max(1, tonumber(pollBox:GetText()) or 15)
    pollBox:SetText(tostring(val))
    pollBox:ClearFocus()
    BrainTaskDB.pollInterval = val
    BT.StartPollTicker(val)
    pollCurFS:SetText("已应用：" .. val .. " 秒")
end

pollApplyBtn:SetScript("OnClick", ApplyPollInterval)
pollBox:SetScript("OnEnterPressed", ApplyPollInterval)

-- ── 缩放滑条辅助 ─────────────────────────────────────────────────────────

local function MakeSlider(parent, yOffset)
    local sl = CreateFrame("Slider", nil, parent)
    sl:SetOrientation("HORIZONTAL")
    sl:SetSize(160, 16)
    sl:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, yOffset)
    sl:SetThumbTexture("Interface/Buttons/UI-SliderBar-Button-Horizontal")
    local bg = sl:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface/Buttons/UI-SliderBar-Background")
    bg:SetPoint("LEFT",  sl, "LEFT",  3, 0)
    bg:SetPoint("RIGHT", sl, "RIGHT", -3, 0)
    bg:SetHeight(8)
    bg:SetTexCoord(0, 0.484375, 0, 0.25)
    sl:SetMinMaxValues(0.5, 2.0)
    sl:SetValueStep(0.05)
    sl:SetObeyStepOnDrag(true)
    return sl
end

-- ── Dashboard 缩放 ────────────────────────────────────────────────────────

local dashLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dashLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -132)
dashLabel:SetText("Dashboard 缩放")
dashLabel:SetTextColor(unpack(BT.COLORS.textNormal))

local dashSlider = MakeSlider(frame, -154)

local dashBox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
dashBox:SetSize(50, 22)
dashBox:SetPoint("LEFT", dashSlider, "RIGHT", 10, 0)
dashBox:SetBackdrop(BT.BACKDROP)
dashBox:SetBackdropColor(0.10, 0.10, 0.14, 1)
dashBox:SetBackdropBorderColor(unpack(BT.COLORS.border))
dashBox:SetFont("Fonts/FRIZQT__.TTF", 11, "")
dashBox:SetTextColor(0.9, 0.9, 0.9)
dashBox:SetAutoFocus(false)
dashBox:SetMaxLetters(4)
dashBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local function ApplyDashScale(val)
    val = math.max(0.5, math.min(2.0, val))
    val = math.floor(val * 20 + 0.5) / 20
    dashSlider:SetValue(val)
    dashBox:SetText(string.format("%.2f", val))
    dashBox:ClearFocus()
    if BrainTaskDB then BrainTaskDB.dashboardScale = val end
    if BT.UI.Dashboard and BT.UI.Dashboard.SetScale then
        BT.UI.Dashboard.SetScale(val)
    end
end

dashSlider:SetScript("OnValueChanged", function(self, val)
    dashBox:SetText(string.format("%.2f", val))
    if BrainTaskDB then BrainTaskDB.dashboardScale = val end
    if BT.UI.Dashboard and BT.UI.Dashboard.SetScale then
        BT.UI.Dashboard.SetScale(val)
    end
end)

dashBox:SetScript("OnEnterPressed", function(self)
    ApplyDashScale(tonumber(self:GetText()) or 1.0)
end)

-- ── 浮动窗口缩放 ──────────────────────────────────────────────────────────

local fwLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fwLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -192)
fwLabel:SetText("浮动窗口缩放")
fwLabel:SetTextColor(unpack(BT.COLORS.textNormal))

local fwSlider = MakeSlider(frame, -214)

local fwBox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
fwBox:SetSize(50, 22)
fwBox:SetPoint("LEFT", fwSlider, "RIGHT", 10, 0)
fwBox:SetBackdrop(BT.BACKDROP)
fwBox:SetBackdropColor(0.10, 0.10, 0.14, 1)
fwBox:SetBackdropBorderColor(unpack(BT.COLORS.border))
fwBox:SetFont("Fonts/FRIZQT__.TTF", 11, "")
fwBox:SetTextColor(0.9, 0.9, 0.9)
fwBox:SetAutoFocus(false)
fwBox:SetMaxLetters(4)
fwBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local function ApplyFWScale(val)
    val = math.max(0.5, math.min(2.0, val))
    val = math.floor(val * 20 + 0.5) / 20
    fwSlider:SetValue(val)
    fwBox:SetText(string.format("%.2f", val))
    fwBox:ClearFocus()
    if BrainTaskDB then BrainTaskDB.floatWindowScale = val end
    if BT.UI.FloatWindow and BT.UI.FloatWindow.SetScale then
        BT.UI.FloatWindow.SetScale(val)
    end
end

fwSlider:SetScript("OnValueChanged", function(self, val)
    fwBox:SetText(string.format("%.2f", val))
    if BrainTaskDB then BrainTaskDB.floatWindowScale = val end
    if BT.UI.FloatWindow and BT.UI.FloatWindow.SetScale then
        BT.UI.FloatWindow.SetScale(val)
    end
end)

fwBox:SetScript("OnEnterPressed", function(self)
    ApplyFWScale(tonumber(self:GetText()) or 1.0)
end)

-- ── 公共接口 ──────────────────────────────────────────────────────────────

function GS.Open()
    local db = BrainTaskDB
    local cur = db and db.pollInterval or 15
    pollBox:SetText(tostring(cur))
    pollCurFS:SetText("当前：" .. cur .. " 秒")

    local ds = db and db.dashboardScale or 1.0
    dashSlider:SetValue(ds)
    dashBox:SetText(string.format("%.2f", ds))

    local fs = db and db.floatWindowScale or 1.0
    fwSlider:SetValue(fs)
    fwBox:SetText(string.format("%.2f", fs))

    frame:Show()
end

function GS.Close()
    frame:Hide()
end
