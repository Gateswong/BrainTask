-- BrainTask Data
-- 数据层：SavedVariables CRUD

BrainTask = BrainTask or {}
local BT = BrainTask
BT.Data = {}
local Data = BT.Data

local function db() return BrainTaskDB end

-- ── 待办事项 ──────────────────────────────────────────────────────────────

function Data.CreateTodo(opts)
    local d = db()
    local id = d.nextTodoID
    d.nextTodoID = id + 1
    d.todos[id] = {
        id           = id,
        title        = opts.title or "未命名",
        details      = opts.details or nil,
        scope        = opts.scope or "warband",
        enabledChars = opts.enabledChars or {},
        categoryID   = opts.categoryID or nil,
        autoTrack    = opts.autoTrack or nil,
        resetType    = opts.resetType or "none",
        createdAt    = time(),
    }
    Data.RefreshUI()
    return id
end

function Data.UpdateTodo(todoID, opts)
    local todo = db().todos[todoID]
    if not todo then return end
    for k, v in pairs(opts) do
        todo[k] = v
    end
    Data.RefreshUI()
end

function Data.DeleteTodo(todoID)
    local d = db()
    d.todos[todoID] = nil
    d.warbandData[todoID] = nil
    for _, charTodos in pairs(d.charData) do
        charTodos[todoID] = nil
    end
    Data.RefreshUI()
end

-- ── 完成状态 ──────────────────────────────────────────────────────────────

-- 战团事项：账号级唯一状态
function Data.SetWarbandCompleted(todoID, completed)
    local d = db()
    d.warbandData[todoID] = d.warbandData[todoID] or {}
    d.warbandData[todoID].completed  = completed
    d.warbandData[todoID].completedAt = completed and time() or nil
    Data.RefreshUI()
end

-- 角色事项：按角色存储
function Data.SetCharCompleted(todoID, charKey, completed)
    local d = db()
    d.charData[charKey] = d.charData[charKey] or {}
    d.charData[charKey][todoID] = d.charData[charKey][todoID] or {}
    d.charData[charKey][todoID].completed  = completed
    d.charData[charKey][todoID].completedAt = completed and time() or nil
    Data.RefreshUI()
end

-- 获取战团事项完成状态
function Data.GetWarbandCompleted(todoID)
    local state = db().warbandData[todoID]
    return state and state.completed or false
end

-- 获取角色事项完成状态
function Data.GetCharCompleted(todoID, charKey)
    local charData = db().charData[charKey]
    if not charData then return false end
    local state = charData[todoID]
    return state and state.completed or false
end

-- ── 角色启用状态（仅 character scope）─────────────────────────────────────

function Data.SetEnabled(todoID, charKey, enabled)
    local todo = db().todos[todoID]
    if not todo or todo.scope ~= "character" then return end
    todo.enabledChars = todo.enabledChars or {}
    if enabled then
        todo.enabledChars[charKey] = true
    else
        todo.enabledChars[charKey] = nil
        -- 同时清除完成记录
        local charData = db().charData[charKey]
        if charData then charData[todoID] = nil end
    end
    Data.RefreshUI()
end

function Data.IsEnabled(todoID, charKey)
    local todo = db().todos[todoID]
    if not todo then return false end
    if todo.scope == "warband" then return true end
    return todo.enabledChars and todo.enabledChars[charKey] or false
end

-- ── 查询 ──────────────────────────────────────────────────────────────────

-- 当前角色可见的全部待办事项（warband 全部 + character 中已启用的）
function Data.GetTodosForChar(charKey)
    local result = {}
    for todoID, todo in pairs(db().todos) do
        if todo.scope == "warband" then
            table.insert(result, {
                todo      = todo,
                completed = Data.GetWarbandCompleted(todoID),
            })
        elseif todo.scope == "character" then
            if todo.enabledChars and todo.enabledChars[charKey] then
                table.insert(result, {
                    todo      = todo,
                    completed = Data.GetCharCompleted(todoID, charKey),
                })
            end
        end
    end
    local cats = db().categories
    table.sort(result, function(a, b)
        local cA = cats[a.todo.categoryID or 0]
        local cB = cats[b.todo.categoryID or 0]
        local sA = cA and (cA.sortOrder or cA.id) or (a.todo.categoryID or 0)
        local sB = cB and (cB.sortOrder or cB.id) or (b.todo.categoryID or 0)
        if sA ~= sB then return sA < sB end
        return (a.todo.sortOrder or a.todo.id) < (b.todo.sortOrder or b.todo.id)
    end)
    return result
end

-- 所有战团事项（按分类排序）
function Data.GetWarbandTodos()
    local result = {}
    for _, todo in pairs(db().todos) do
        if todo.scope == "warband" then
            table.insert(result, todo)
        end
    end
    local cats = db().categories
    table.sort(result, function(a, b)
        local cA = cats[a.categoryID or 0]
        local cB = cats[b.categoryID or 0]
        local sA = cA and (cA.sortOrder or cA.id) or (a.categoryID or 0)
        local sB = cB and (cB.sortOrder or cB.id) or (b.categoryID or 0)
        if sA ~= sB then return sA < sB end
        return (a.sortOrder or a.id) < (b.sortOrder or b.id)
    end)
    return result
end

-- 所有角色事项（按分类排序）
function Data.GetCharacterTodos()
    local result = {}
    for _, todo in pairs(db().todos) do
        if todo.scope == "character" then
            table.insert(result, todo)
        end
    end
    local cats = db().categories
    table.sort(result, function(a, b)
        local cA = cats[a.categoryID or 0]
        local cB = cats[b.categoryID or 0]
        local sA = cA and (cA.sortOrder or cA.id) or (a.categoryID or 0)
        local sB = cB and (cB.sortOrder or cB.id) or (b.categoryID or 0)
        if sA ~= sB then return sA < sB end
        return (a.sortOrder or a.id) < (b.sortOrder or b.id)
    end)
    return result
end

-- ── 分类 ──────────────────────────────────────────────────────────────────

function Data.CreateCategory(title)
    local d = db()
    local id = d.nextCatID
    d.nextCatID = id + 1
    d.categories[id] = { id = id, title = title }
    Data.RefreshUI()
    return id
end

function Data.UpdateCategory(catID, title)
    local cat = db().categories[catID]
    if cat then
        cat.title = title
        Data.RefreshUI()
    end
end

function Data.DeleteCategory(catID)
    db().categories[catID] = nil
    -- 解除关联（不删除待办事项）
    for _, todo in pairs(db().todos) do
        if todo.categoryID == catID then
            todo.categoryID = nil
        end
    end
    Data.RefreshUI()
end

function Data.GetCategories()
    local result = {}
    for _, cat in pairs(db().categories) do
        table.insert(result, cat)
    end
    table.sort(result, function(a, b)
        return (a.sortOrder or a.id) < (b.sortOrder or b.id)
    end)
    return result
end

-- 将分类移动到 afterCatID 之后（nil = 移到首位）
function Data.MoveCategory(catID, afterCatID)
    local moving = db().categories[catID]
    if not moving then return end
    local ordered = Data.GetCategories()
    local newList = {}
    for _, c in ipairs(ordered) do
        if c.id ~= catID then table.insert(newList, c) end
    end
    if afterCatID == nil then
        table.insert(newList, 1, moving)
    else
        local inserted = false
        for i, c in ipairs(newList) do
            if c.id == afterCatID then
                table.insert(newList, i + 1, moving)
                inserted = true
                break
            end
        end
        if not inserted then table.insert(newList, moving) end
    end
    for i, c in ipairs(newList) do c.sortOrder = i end
    Data.RefreshUI()
end

-- 将事项移动到 targetCatID 分类中 afterTodoID 之后（nil = 该分类首位）
function Data.MoveTodo(todoID, targetCatID, afterTodoID)
    local d = db()
    local todo = d.todos[todoID]
    if not todo then return end
    todo.categoryID = targetCatID
    local peers = {}
    for _, t in pairs(d.todos) do
        if t.id ~= todoID and t.scope == todo.scope and t.categoryID == targetCatID then
            table.insert(peers, t)
        end
    end
    table.sort(peers, function(a, b)
        return (a.sortOrder or a.id) < (b.sortOrder or b.id)
    end)
    local newList = {}
    local inserted = false
    if afterTodoID == nil then
        table.insert(newList, todo)
        inserted = true
    end
    for _, t in ipairs(peers) do
        table.insert(newList, t)
        if t.id == afterTodoID then
            table.insert(newList, todo)
            inserted = true
        end
    end
    if not inserted then table.insert(newList, todo) end
    for i, t in ipairs(newList) do t.sortOrder = i end
    Data.RefreshUI()
end

function Data.GetCategoryTitle(catID)
    if not catID then return "未分类" end
    local cat = db().categories[catID]
    return cat and cat.title or "未分类"
end

-- ── 统计 ──────────────────────────────────────────────────────────────────

-- 战团事项完成统计：{ total, completed }
function Data.GetWarbandStats()
    local total, completed = 0, 0
    for todoID, todo in pairs(db().todos) do
        if todo.scope == "warband" then
            total = total + 1
            if Data.GetWarbandCompleted(todoID) then
                completed = completed + 1
            end
        end
    end
    return total, completed
end

-- ── UI 刷新广播 ───────────────────────────────────────────────────────────

function Data.RefreshUI()
    if BT.UI.FloatWindow and BT.UI.FloatWindow.Refresh then
        BT.UI.FloatWindow.Refresh()
    end
    if BT.UI.Dashboard and BT.UI.Dashboard.Refresh then
        BT.UI.Dashboard.Refresh()
    end
end
