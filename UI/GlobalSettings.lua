-- BrainTask UI: 全局设置

BrainTask = BrainTask or {}
BrainTask.UI = BrainTask.UI or {}
local BT = BrainTask
BT.UI.GlobalSettings = {}
local GS = BT.UI.GlobalSettings

local WIN_W, WIN_H = 340, 348

-- ── 主框架 ────────────────────────────────────────────────────────────────

local frame = BT.CreateBackdropFrame("Frame", "BrainTaskGlobalSettings", UIParent, WIN_W, WIN_H)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:EnableMouse(true)
frame:SetToplevel(true)
frame:SetScript("OnMouseDown", function(self) self:Raise() end)
frame:Hide()
tinsert(UISpecialFrames, "BrainTaskGlobalSettings")

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
titleFS:SetText("|cff55aaff" .. BT.L.TITLE_GLOBAL_SET .. "|r")

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
pollLabel:SetText(BT.L.POLL_LABEL)
pollLabel:SetTextColor(unpack(BT.COLORS.textNormal))

local pollDesc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pollDesc:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -66)
pollDesc:SetTextColor(unpack(BT.COLORS.textMuted))
pollDesc:SetText(BT.L.POLL_DESC)

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

local pollApplyBtn = BT.CreateButton(frame, BT.L.BTN_APPLY, 70, 26)
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
    pollCurFS:SetText(string.format(BT.L.POLL_APPLIED_FMT, val))
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
dashLabel:SetText(BT.L.DASH_SCALE)
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
fwLabel:SetText(BT.L.FW_SCALE)
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

-- ── 界面语言 ──────────────────────────────────────────────────────────────

local langSectionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
langSectionLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -252)
langSectionLabel:SetText(BT.L.LANG_LABEL)
langSectionLabel:SetTextColor(unpack(BT.COLORS.textNormal))

-- 当前选中语言的显示名称
local function GetLangDisplayName(id)
    for _, opt in ipairs(BT.LANG_OPTIONS) do
        if opt.id == id then
            return opt.id == "auto" and BT.L.LANG_AUTO or opt.name
        end
    end
    return BT.L.LANG_AUTO
end

-- 语言选择按钮（显示当前语言）
local langDropBtn = BT.CreateButton(frame, BT.L.LANG_AUTO, 220, 26)
langDropBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -272)

-- 下拉列表
local langDropList = CreateFrame("Frame", nil, frame)
langDropList:SetSize(220, 1)
langDropList:SetPoint("BOTTOMLEFT", langDropBtn, "TOPLEFT", 0, 2)
langDropList:SetFrameStrata("FULLSCREEN_DIALOG")
langDropList:EnableMouse(true)
local _ldBorder = langDropList:CreateTexture(nil, "BACKGROUND", nil, 0)
_ldBorder:SetAllPoints()
_ldBorder:SetColorTexture(0.22, 0.22, 0.32, 1)
local _ldBg = langDropList:CreateTexture(nil, "BACKGROUND", nil, 1)
_ldBg:SetPoint("TOPLEFT",     langDropList, "TOPLEFT",     1, -1)
_ldBg:SetPoint("BOTTOMRIGHT", langDropList, "BOTTOMRIGHT", -1,  1)
_ldBg:SetColorTexture(0.10, 0.10, 0.14, 1)
langDropList:Hide()

local function BuildLangDropList()
    for _, child in ipairs({ langDropList:GetChildren() }) do
        child:Hide()
    end
    local listH = 0
    for _, opt in ipairs(BT.LANG_OPTIONS) do
        local displayName = (opt.id == "auto") and BT.L.LANG_AUTO or opt.name
        local item = CreateFrame("Button", nil, langDropList)
        item:SetHeight(22)
        item:SetPoint("TOPLEFT",  langDropList, "TOPLEFT",  2, -listH)
        item:SetPoint("TOPRIGHT", langDropList, "TOPRIGHT", -2, -listH)
        local itemFS = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemFS:SetAllPoints()
        itemFS:SetText(displayName)
        itemFS:SetJustifyH("LEFT")
        itemFS:SetTextColor(0.9, 0.9, 0.9)
        local iBg = item:CreateTexture(nil, "BACKGROUND")
        iBg:SetAllPoints()
        iBg:SetColorTexture(0, 0, 0, 0)
        item:SetScript("OnEnter", function() iBg:SetColorTexture(1, 1, 1, 0.06) end)
        item:SetScript("OnLeave", function() iBg:SetColorTexture(0, 0, 0, 0) end)
        local optID = opt.id
        item:SetScript("OnClick", function()
            langDropList:Hide()
            if BrainTaskDB then
                BrainTaskDB.language = optID
            end
            ReloadUI()
        end)
        item:Show()
        listH = listH + 22
    end
    langDropList:SetHeight(math.max(listH, 10))
end

langDropBtn:SetScript("OnClick", function()
    if langDropList:IsVisible() then
        langDropList:Hide()
    else
        BuildLangDropList()
        langDropList:Show()
    end
end)

-- 关闭下拉框（点击其他地方）
frame:SetScript("OnMouseDown", function(self)
    self:Raise()
    langDropList:Hide()
end)

local langHint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
langHint:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -304)
langHint:SetText(BT.L.LANG_RELOAD_HINT)
langHint:SetTextColor(unpack(BT.COLORS.textMuted))

-- ── 本地化刷新 ────────────────────────────────────────────────────────────

BT.Locale.Register(function()
    titleFS:SetText("|cff55aaff" .. BT.L.TITLE_GLOBAL_SET .. "|r")
    pollLabel:SetText(BT.L.POLL_LABEL)
    pollDesc:SetText(BT.L.POLL_DESC)
    pollApplyBtn.label:SetText(BT.L.BTN_APPLY)
    dashLabel:SetText(BT.L.DASH_SCALE)
    fwLabel:SetText(BT.L.FW_SCALE)
    langSectionLabel:SetText(BT.L.LANG_LABEL)
    langHint:SetText(BT.L.LANG_RELOAD_HINT)
end)

-- ── 公共接口 ──────────────────────────────────────────────────────────────

function GS.Open()
    local db = BrainTaskDB
    local cur = db and db.pollInterval or 15
    pollBox:SetText(tostring(cur))
    pollCurFS:SetText(string.format(BT.L.POLL_CURRENT_FMT, cur))

    local ds = db and db.dashboardScale or 1.0
    dashSlider:SetValue(ds)
    dashBox:SetText(string.format("%.2f", ds))

    local fs = db and db.floatWindowScale or 1.0
    fwSlider:SetValue(fs)
    fwBox:SetText(string.format("%.2f", fs))

    local lang = db and db.language or "auto"
    langDropBtn.label:SetText(GetLangDisplayName(lang))

    langDropList:Hide()
    frame:Show()
end

function GS.Close()
    frame:Hide()
end
