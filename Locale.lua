-- BrainTask Locale
-- 本地化字符串表。在所有其他模块之前加载。
-- SavedVariables 在 Lua 文件执行前已由客户端载入，可安全读取。

BrainTask = BrainTask or {}
local BT = BrainTask

-- ── 字符串表 ─────────────────────────────────────────────────────────────

local LOCALES = {}

-- ── English ───────────────────────────────────────────────────────────────
LOCALES["enUS"] = {
    -- Core
    LOADED_MSG          = "Loaded. /bt to open the task window.",
    KEYBIND_TOGGLE      = "Toggle BrainTask Float Window",
    -- Minimap
    MINIMAP_LEFT        = "Left Click: Toggle Task Window",
    MINIMAP_RIGHT       = "Right Click: Open Dashboard",
    -- Dashboard toolbar
    BTN_ADD_WARBAND     = "+ Add Warband Task",
    BTN_ADD_CHAR        = "+ Add Character Task",
    BTN_SETTINGS        = "Settings",
    BTN_CATEGORY_MGMT   = "Categories",
    BTN_CHAR_MGMT       = "Characters",
    LBL_LOCK_WINDOW     = "Lock Window",
    LBL_LOCK_FLOAT_POS  = "Lock Float",
    -- Dashboard columns
    COL_WARBAND         = "Warband Tasks",
    COL_CHAR            = "Character Tasks",
    SEARCH_HINT         = "Search...",
    DRAG_CAT_PREFIX     = "[Cat] ",
    -- Todo form
    FORM_TITLE_ADD      = "Add Task",
    FORM_TITLE_WARBAND  = "Add Warband Task",
    FORM_TITLE_CHAR     = "Add Character Task",
    FORM_TITLE_EDIT     = "Edit Task",
    FIELD_TITLE         = "Title *",
    FIELD_DETAILS       = "Description",
    FIELD_CATEGORY      = "Category *",
    SELECT_CATEGORY     = "Select Category",
    FIELD_RESET         = "Reset Type",
    RESET_NONE          = "One-time",
    RESET_DAILY         = "Daily",
    RESET_WEEKLY        = "Weekly",
    FIELD_AUTO_TRACK    = "Auto Track",
    TRACK_NONE          = "None",
    TRACK_QUEST         = "Quest ID",
    TRACK_BOSS          = "Instance Boss",
    TRACK_CURRENCY      = "Currency",
    QUEST_ID_LABEL      = "Quest ID (comma=any one, semicolon=all groups, ! suffix=reset-aware)",
    ENCOUNTER_ID_LABEL  = "Encounter ID (comma=any one, semicolon=all groups)",
    CURRENCY_ID_LABEL   = "Currency ID (comma=any one, semicolon=all groups)",
    BTN_SAVE            = "Save",
    BTN_CANCEL          = "Cancel",
    CONFIRM_DEL_TODO    = "Delete this task?",
    BTN_DELETE          = "Delete",
    ERR_TITLE_EMPTY     = "Title cannot be empty",
    ERR_NO_CATEGORY     = "Please select a category",
    TOOLTIP_AUTO_TRACK  = "This task auto-completes when conditions are met.",
    TOOLTIP_CLICK_DONE  = "Click: Mark done",
    TOOLTIP_CLICK_UNDO  = "Click: Mark undone",
    TOOLTIP_SHIFT_DIS        = "Shift+Click: Disable",
    TOOLTIP_SHIFT_EN         = "Shift+Click: Enable",
    TOOLTIP_SHIFT_HINT       = "Hold Shift for progress details",
    TOOLTIP_PROGRESS_TITLE   = "Current Progress",
    TOOLTIP_QUEST_DONE       = "Completed",
    TOOLTIP_GROUP_SATISFIED  = "Satisfied by others",
    -- Category management
    TITLE_CAT_MGMT      = "Categories",
    CONFIRM_DEL_CAT     = "This category has linked tasks.\nDelete and unlink them?",
    ADDCAT_LABEL        = "New Category Name",
    BTN_ADD_CAT         = "+ Add",
    -- Character management
    TITLE_CHAR_MGMT     = "Characters",
    CHAR_HINT           = "Drag to reorder - Click eye icon to toggle visibility",
    CURRENT_CHAR        = "(Current)",
    -- Global settings
    TITLE_GLOBAL_SET    = "Global Settings",
    POLL_LABEL          = "Auto-Track Poll Interval",
    POLL_DESC           = "Quest and Boss auto-completion check frequency (seconds, min 1)",
    BTN_APPLY           = "Apply",
    POLL_APPLIED_FMT    = "Applied: %d sec",
    POLL_CURRENT_FMT    = "Current: %d sec",
    DASH_SCALE          = "Dashboard Scale",
    FW_SCALE            = "Float Window Scale",
    -- Language
    LANG_LABEL          = "Interface Language",
    LANG_AUTO           = "Follow Game Language",
    LANG_RELOAD_HINT    = "UI reload required for changes to take effect",
    -- Character note
    SET_CHAR_NOTE       = "Set Note",
    NOTE_DIALOG_TITLE   = "Character Note",
    NOTE_SAVE           = "Save",
    NOTE_CANCEL         = "Cancel",
    NOTE_HEADER         = "Note",
}

-- ── Simplified Chinese / 简体中文 ─────────────────────────────────────────
LOCALES["zhCN"] = {
    LOADED_MSG          = "已加载。/bt 打开待办窗口。",
    KEYBIND_TOGGLE      = "切换 BrainTask 浮动窗口",
    MINIMAP_LEFT        = "左键: 切换待办窗口",
    MINIMAP_RIGHT       = "右键: 打开 Dashboard",
    BTN_ADD_WARBAND     = "+ 添加战团事项",
    BTN_ADD_CHAR        = "+ 添加角色事项",
    BTN_SETTINGS        = "设置",
    BTN_CATEGORY_MGMT   = "分类管理",
    BTN_CHAR_MGMT       = "角色管理",
    LBL_LOCK_WINDOW     = "锁定窗口大小",
    LBL_LOCK_FLOAT_POS  = "锁定悬浮窗",
    COL_WARBAND         = "战团事项",
    COL_CHAR            = "角色事项",
    SEARCH_HINT         = "搜索...",
    DRAG_CAT_PREFIX     = "[分类] ",
    FORM_TITLE_ADD      = "添加待办事项",
    FORM_TITLE_WARBAND  = "添加战团事项",
    FORM_TITLE_CHAR     = "添加角色事项",
    FORM_TITLE_EDIT     = "编辑待办事项",
    FIELD_TITLE         = "标题 *",
    FIELD_DETAILS       = "详细描述",
    FIELD_CATEGORY      = "分类 *",
    SELECT_CATEGORY     = "请选择分类",
    FIELD_RESET         = "重置类型",
    RESET_NONE          = "一次性",
    RESET_DAILY         = "每日",
    RESET_WEEKLY        = "每周",
    FIELD_AUTO_TRACK    = "自动追踪",
    TRACK_NONE          = "无",
    TRACK_QUEST         = "Quest ID",
    TRACK_BOSS          = "副本 Boss",
    TRACK_CURRENCY      = "货币上限",
    QUEST_ID_LABEL      = "Quest ID（逗号=任一满足，分号=全组满足，!后缀=重置感知）",
    ENCOUNTER_ID_LABEL  = "Encounter ID（逗号=任一满足，分号=全组满足）",
    CURRENCY_ID_LABEL   = "Currency ID（逗号=任一满足，分号=全组满足）",
    BTN_SAVE            = "保存",
    BTN_CANCEL          = "取消",
    CONFIRM_DEL_TODO    = "确定删除此待办事项？",
    BTN_DELETE          = "删除",
    ERR_TITLE_EMPTY     = "标题不能为空",
    ERR_NO_CATEGORY     = "请选择分类",
    TOOLTIP_AUTO_TRACK  = "该类型的事项会在相关条件符合时自动完成，无法手动更改",
    TOOLTIP_CLICK_DONE  = "点击：标记完成",
    TOOLTIP_CLICK_UNDO  = "点击：取消完成",
    TOOLTIP_SHIFT_DIS        = "Shift+点击：禁用",
    TOOLTIP_SHIFT_EN         = "Shift+点击：启用",
    TOOLTIP_SHIFT_HINT       = "按住 Shift 查看详细进度",
    TOOLTIP_PROGRESS_TITLE   = "当前进度",
    TOOLTIP_QUEST_DONE       = "已完成",
    TOOLTIP_GROUP_SATISFIED  = "已满足其他要求",
    TITLE_CAT_MGMT      = "分类管理",
    CONFIRM_DEL_CAT     = "此分类下有关联事项，\n确定要删除并解除关联？",
    ADDCAT_LABEL        = "新分类名称",
    BTN_ADD_CAT         = "+ 添加",
    TITLE_CHAR_MGMT     = "角色管理",
    CHAR_HINT           = "拖拽行排序 · 点击眼睛图标切换显示",
    CURRENT_CHAR        = "(当前)",
    TITLE_GLOBAL_SET    = "全局设置",
    POLL_LABEL          = "自动追踪轮询间隔",
    POLL_DESC           = "Quest 和副本 Boss 的自动完成检测频率（秒，最小 1）",
    BTN_APPLY           = "应用",
    POLL_APPLIED_FMT    = "已应用：%d 秒",
    POLL_CURRENT_FMT    = "当前：%d 秒",
    DASH_SCALE          = "Dashboard 缩放",
    FW_SCALE            = "浮动窗口缩放",
    LANG_LABEL          = "界面语言",
    LANG_AUTO           = "跟随游戏语言",
    LANG_RELOAD_HINT    = "更改语言后需重载界面生效",
    -- 角色备注
    SET_CHAR_NOTE       = "设置备注",
    NOTE_DIALOG_TITLE   = "角色备注",
    NOTE_SAVE           = "保存",
    NOTE_CANCEL         = "取消",
    NOTE_HEADER         = "备注",
}

-- ── Traditional Chinese / 繁體中文 ────────────────────────────────────────
LOCALES["zhTW"] = {
    LOADED_MSG          = "已載入。/bt 開啟待辦視窗。",
    KEYBIND_TOGGLE      = "切換 BrainTask 浮動視窗",
    MINIMAP_LEFT        = "左鍵: 切換待辦視窗",
    MINIMAP_RIGHT       = "右鍵: 開啟 Dashboard",
    BTN_ADD_WARBAND     = "+ 新增戰團事項",
    BTN_ADD_CHAR        = "+ 新增角色事項",
    BTN_SETTINGS        = "設定",
    BTN_CATEGORY_MGMT   = "分類管理",
    BTN_CHAR_MGMT       = "角色管理",
    LBL_LOCK_WINDOW     = "鎖定視窗大小",
    LBL_LOCK_FLOAT_POS  = "鎖定懸浮視窗",
    COL_WARBAND         = "戰團事項",
    COL_CHAR            = "角色事項",
    SEARCH_HINT         = "搜尋...",
    DRAG_CAT_PREFIX     = "[分類] ",
    FORM_TITLE_ADD      = "新增待辦事項",
    FORM_TITLE_WARBAND  = "新增戰團事項",
    FORM_TITLE_CHAR     = "新增角色事項",
    FORM_TITLE_EDIT     = "編輯待辦事項",
    FIELD_TITLE         = "標題 *",
    FIELD_DETAILS       = "詳細描述",
    FIELD_CATEGORY      = "分類 *",
    SELECT_CATEGORY     = "請選擇分類",
    FIELD_RESET         = "重置類型",
    RESET_NONE          = "一次性",
    RESET_DAILY         = "每日",
    RESET_WEEKLY        = "每週",
    FIELD_AUTO_TRACK    = "自動追蹤",
    TRACK_NONE          = "無",
    TRACK_QUEST         = "Quest ID",
    TRACK_BOSS          = "副本 Boss",
    TRACK_CURRENCY      = "貨幣上限",
    QUEST_ID_LABEL      = "Quest ID（逗號=任一滿足，分號=全組滿足，!後綴=重置感知）",
    ENCOUNTER_ID_LABEL  = "Encounter ID（逗號=任一滿足，分號=全組滿足）",
    CURRENCY_ID_LABEL   = "Currency ID（逗號=任一滿足，分號=全組滿足）",
    BTN_SAVE            = "儲存",
    BTN_CANCEL          = "取消",
    CONFIRM_DEL_TODO    = "確定刪除此待辦事項？",
    BTN_DELETE          = "刪除",
    ERR_TITLE_EMPTY     = "標題不能為空",
    ERR_NO_CATEGORY     = "請選擇分類",
    TOOLTIP_AUTO_TRACK  = "此類型事項會在條件符合時自動完成，無法手動更改",
    TOOLTIP_CLICK_DONE  = "點擊：標記完成",
    TOOLTIP_CLICK_UNDO  = "點擊：取消完成",
    TOOLTIP_SHIFT_DIS        = "Shift+點擊：停用",
    TOOLTIP_SHIFT_EN         = "Shift+點擊：啟用",
    TOOLTIP_SHIFT_HINT       = "按住 Shift 查看詳細進度",
    TOOLTIP_PROGRESS_TITLE   = "當前進度",
    TOOLTIP_QUEST_DONE       = "已完成",
    TOOLTIP_GROUP_SATISFIED  = "已滿足其他要求",
    TITLE_CAT_MGMT      = "分類管理",
    CONFIRM_DEL_CAT     = "此分類下有關聯事項，\n確定要刪除並解除關聯？",
    ADDCAT_LABEL        = "新分類名稱",
    BTN_ADD_CAT         = "+ 新增",
    TITLE_CHAR_MGMT     = "角色管理",
    CHAR_HINT           = "拖曳排序 · 點擊眼睛圖示切換顯示",
    CURRENT_CHAR        = "（目前）",
    TITLE_GLOBAL_SET    = "全域設定",
    POLL_LABEL          = "自動追蹤輪詢間隔",
    POLL_DESC           = "Quest 和副本 Boss 的自動完成檢測頻率（秒，最小 1）",
    BTN_APPLY           = "套用",
    POLL_APPLIED_FMT    = "已套用：%d 秒",
    POLL_CURRENT_FMT    = "目前：%d 秒",
    DASH_SCALE          = "Dashboard 縮放",
    FW_SCALE            = "浮動視窗縮放",
    LANG_LABEL          = "介面語言",
    LANG_AUTO           = "跟隨遊戲語言",
    LANG_RELOAD_HINT    = "更改語言後需重載介面生效",
    -- 角色備註
    SET_CHAR_NOTE       = "設置備註",
    NOTE_DIALOG_TITLE   = "角色備註",
    NOTE_SAVE           = "儲存",
    NOTE_CANCEL         = "取消",
    NOTE_HEADER         = "備註",
}

-- ── 所有 WoW 支持的语言列表（用于设置下拉菜单）──────────────────────────
-- 未提供翻译的语言回退到 enUS
BT.LANG_OPTIONS = {
    { id = "auto", name = nil },       -- name 在运行时从 BT.L 读取
    { id = "enUS", name = "English" },
    { id = "zhCN", name = "简体中文" },
    { id = "zhTW", name = "繁體中文" },
}

-- ── 语言选择逻辑 ──────────────────────────────────────────────────────────
-- 注意：SavedVariables 在 Lua 文件执行时尚不可用，只能用 GetLocale()。
-- 用户保存的语言偏好在 ADDON_LOADED 事件后由 Core.lua 读取并应用。

local function SelectLocale()
    local lang = GetLocale()
    if lang == "enGB" then lang = "enUS" end
    return LOCALES[lang] or LOCALES["enUS"]
end

BT.L = SelectLocale()

-- ── 本地化管理模块 ────────────────────────────────────────────────────────
-- 各 UI 模块通过 BT.Locale.Register(fn) 注册静态文字刷新回调。
-- Core.lua 在 ADDON_LOADED 后若检测到语言变更，调用 BT.Locale.ApplyAll()。

BT.Locale = {
    all  = LOCALES,   -- 全部语言表，供 Core.lua 切换时使用
    _fns = {},
}

function BT.Locale.Register(fn)
    table.insert(BT.Locale._fns, fn)
end

function BT.Locale.ApplyAll()
    for _, fn in ipairs(BT.Locale._fns) do
        fn()
    end
end
