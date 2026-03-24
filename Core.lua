-- BrainTask Core
-- 命名空间、事件总线、初始化入口

BrainTask = BrainTask or {}
local BT = BrainTask

BT.UI = BT.UI or {}

-- 颜色常量（所有 UI 模块共用）
BT.COLORS = {
    bg          = { 0.08, 0.08, 0.10, 0.95 },
    bgLight     = { 0.12, 0.12, 0.16, 0.92 },
    bgRow       = { 0.11, 0.11, 0.14, 0.85 },
    bgRowAlt    = { 0.09, 0.09, 0.12, 0.85 },
    border      = { 0.22, 0.22, 0.32, 1 },
    header      = { 0.14, 0.14, 0.20, 1 },
    accent      = { 0.25, 0.60, 1.00, 1 },
    textNormal  = { 0.90, 0.90, 0.90, 1 },
    textMuted   = { 0.50, 0.50, 0.55, 1 },
    textTitle   = { 1.00, 1.00, 1.00, 1 },
    green       = { 0.30, 0.90, 0.30, 1 },
    red         = { 0.90, 0.30, 0.30, 1 },
    yellow      = { 1.00, 0.80, 0.10, 1 },
    warbandTag  = { 0.55, 0.35, 0.90, 1 },
}

-- 共用 backdrop 配置
BT.BACKDROP = {
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile     = true,
    tileSize = 16,
    edgeSize = 12,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- 当前角色 key（Name-Realm）
BT.charKey = nil

-- ── 事件帧 ──────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == "BrainTask" then
        -- SavedVariables 在此事件后才可读取
        local db = BrainTaskDB
        local savedLang = db and db.language
        if savedLang and savedLang ~= "auto" then
            local newLocale = BT.Locale.all[savedLang]
            if newLocale and newLocale ~= BT.L then
                BT.L = newLocale
                BT.Locale.ApplyAll()
            end
        end
    elseif event == "PLAYER_LOGIN" then
        BT.OnLogin()
    elseif event == "QUEST_LOG_UPDATE" or event == "UPDATE_INSTANCE_INFO" then
        if BT.Tracking then
            BT.Tracking.PollAll()
        end
    end
end)

-- ── 初始化 ───────────────────────────────────────────────────────────────
function BT.OnLogin()
    -- 初始化 SavedVariables
    BrainTaskDB = BrainTaskDB or {}
    local db = BrainTaskDB
    db.todos         = db.todos         or {}
    db.categories    = db.categories    or {}
    db.warbandData   = db.warbandData   or {}
    db.charData      = db.charData      or {}
    db.knownChars    = db.knownChars    or {}
    db.lastDailyReset  = db.lastDailyReset  or 0
    db.lastWeeklyReset = db.lastWeeklyReset or 0
    db.nextTodoID    = db.nextTodoID    or 1
    db.nextCatID     = db.nextCatID     or 1
    db.language        = db.language        or "auto"
    db.minimapAngle    = db.minimapAngle    or math.rad(225)
    db.dashboardLayout = db.dashboardLayout or { w = 920, h = 640, leftW = 400, labelW = 260, locked = false }
    db.charOrder       = db.charOrder       or {}
    db.pollInterval    = db.pollInterval    or 15
    db.dashboardScale  = db.dashboardScale  or 1.0
    db.floatWindowScale = db.floatWindowScale or 1.0
    db.floatWindowSize   = db.floatWindowSize   or { w = 280, h = 420 }
    db.floatWindowLocked = db.floatWindowLocked or false
    db.hiddenChars     = db.hiddenChars     or {}

    -- 注册当前角色
    local name  = UnitName("player")
    local realm = GetRealmName()
    BT.charKey  = name .. "-" .. realm
    local isNewChar = db.knownChars[BT.charKey] == nil
    db.knownChars[BT.charKey] = {
        name  = name,
        realm = realm,
        class = select(2, UnitClass("player")),
    }
    if isNewChar then
        db.hiddenChars[BT.charKey] = true
    end

    -- 将所有 knownChars 中不在 charOrder 里的角色补入末尾（兼容 charOrder 引入前的旧数据）
    for k in pairs(db.knownChars) do
        local found = false
        for _, ko in ipairs(db.charOrder) do
            if ko == k then found = true; break end
        end
        if not found then table.insert(db.charOrder, k) end
    end

    -- 重置检测
    if BT.Reset then BT.Reset.Check() end

    -- 自动追踪
    if BT.Tracking then BT.Tracking.PollAll() end
    BT.StartPollTicker(db.pollInterval)

    -- 窗口缩放
    if BT.UI.Dashboard and BT.UI.Dashboard.SetScale then
        BT.UI.Dashboard.SetScale(db.dashboardScale)
    end
    if BT.UI.FloatWindow and BT.UI.FloatWindow.SetScale then
        BT.UI.FloatWindow.SetScale(db.floatWindowScale)
    end

    -- 恢复浮动窗口可见性
    if db.floatWindowVisible and BT.UI.FloatWindow then
        BT.UI.FloatWindow.Open()
    end

    -- 斜杠命令
    SLASH_BRAINTASK1 = "/bt"
    SLASH_BRAINTASK2 = "/btask"
    SlashCmdList["BRAINTASK"] = function(msg)
        if BT.UI.FloatWindow then
            BT.UI.FloatWindow.Toggle()
        end
    end

    print("|cff55aaff[BrainTask]|r " .. BT.L.LOADED_MSG)
end

-- ── 快捷键绑定（纯 Lua，无需 Bindings.xml）─────────────────────────────
-- WoW 在按键触发时直接调用同名全局函数
BINDING_HEADER_BRAINTASK        = "BrainTask"
BINDING_NAME_BRAINTASK_TOGGLE   = BT.L.KEYBIND_TOGGLE

function BRAINTASK_TOGGLE()
    if BT.UI.FloatWindow then
        BT.UI.FloatWindow.Toggle()
    end
end

-- ── 轮询 Ticker ───────────────────────────────────────────────────────────

local pollTicker = nil

function BT.StartPollTicker(interval)
    interval = math.max(1, tonumber(interval) or 15)
    if pollTicker then pollTicker:Cancel() end
    pollTicker = C_Timer.NewTicker(interval, function()
        if BT.Tracking then BT.Tracking.PollAll() end
    end)
end

-- ── 工具函数 ──────────────────────────────────────────────────────────────

-- 创建带 backdrop 的 Frame
function BT.CreateBackdropFrame(frameType, name, parent, w, h)
    local f = CreateFrame(frameType or "Frame", name, parent, "BackdropTemplate")
    if w and h then f:SetSize(w, h) end
    f:SetBackdrop(BT.BACKDROP)
    f:SetBackdropColor(unpack(BT.COLORS.bg))
    f:SetBackdropBorderColor(unpack(BT.COLORS.border))
    return f
end

-- 创建标签文字
function BT.CreateLabel(parent, text, fontObj, r, g, b, a)
    local fs = parent:CreateFontString(nil, "OVERLAY", fontObj or "GameFontNormal")
    fs:SetText(text or "")
    fs:SetTextColor(r or 0.9, g or 0.9, b or 0.9, a or 1)
    return fs
end

-- 创建简单按钮
function BT.CreateButton(parent, text, w, h)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w or 100, h or 24)
    btn:SetBackdrop(BT.BACKDROP)
    btn:SetBackdropColor(0.15, 0.15, 0.22, 1)
    btn:SetBackdropBorderColor(unpack(BT.COLORS.border))

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetAllPoints()
    label:SetText(text or "")
    label:SetTextColor(unpack(BT.COLORS.textNormal))
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.22, 0.22, 0.32, 1)
        self:SetBackdropBorderColor(unpack(BT.COLORS.accent))
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.22, 1)
        self:SetBackdropBorderColor(unpack(BT.COLORS.border))
    end)
    return btn
end

-- 使 Frame 可拖拽
function BT.MakeDraggable(frame, handle)
    handle = handle or frame
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function() frame:StartMoving() end)
    handle:SetScript("OnDragStop",  function() frame:StopMovingOrSizing() end)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
end

-- 重置类型标签文字
function BT.ResetTypeLabel(resetType)
    if resetType == "daily"  then return CreateAtlasMarkup("quest-recurring-available", 14, 14) end
    if resetType == "weekly" then return CreateAtlasMarkup("quest-wrapper-available",   14, 14) end
    return ""
end

-- 链接插入支持：Shift+点击物品/成就时将链接重定向到当前聚焦的 BT 输入框
BT.activeLinkEditBox = nil

local function BT_InsertLink(link)
    if BT.activeLinkEditBox and BT.activeLinkEditBox:IsVisible() then
        BT.activeLinkEditBox:Insert(link)
    end
end

-- 防抖：WoW 存在 bug 会连续调用两次
local btLinkDebounce = true
local btLinkHook = function(link)
    if btLinkDebounce then
        btLinkDebounce = false
        C_Timer.After(0.1, function() btLinkDebounce = true end)
        BT_InsertLink(link)
    end
end

-- WoW Retail 用 ChatFrameUtil.InsertLink，老版本用 ChatEdit_InsertLink
if type(ChatFrameUtil) == "table" and type(ChatFrameUtil.InsertLink) == "function" then
    hooksecurefunc(ChatFrameUtil, "InsertLink", btLinkHook)
else
    hooksecurefunc("ChatEdit_InsertLink", btLinkHook)
end

-- 副本日志链接需单独 hook（EncounterJournal 是按需加载的插件）
hooksecurefunc(C_AddOns, "LoadAddOn", function(name)
    if name ~= "Blizzard_EncounterJournal" or not EncounterJournal then return end
    if EncounterJournal_OnClick then
        hooksecurefunc("EncounterJournal_OnClick", function(self)
            if IsModifiedClick("CHATLINK") and self.link then
                BT_InsertLink(self.link)
            end
        end)
    end
    if EncounterJournalBossButton_OnClick then
        hooksecurefunc("EncounterJournalBossButton_OnClick", function(self)
            if IsModifiedClick("CHATLINK") and self.link then
                BT_InsertLink(self.link)
            end
        end)
    end
end)

