-- BrainTask Tracking
-- 自动追踪：Quest ID + 副本 Boss Encounter ID 轮询

BrainTask = BrainTask or {}
local BT = BrainTask
BT.Tracking = {}
local Tracking = BT.Tracking

-- ── 主轮询入口 ────────────────────────────────────────────────────────────

function Tracking.PollAll()
    local charKey = BT.charKey
    if not charKey or not BrainTaskDB then return end

    local d = BrainTaskDB

    for todoID, todo in pairs(d.todos) do
        if todo.autoTrack then
            local isRelevant = false
            if todo.scope == "warband" then
                isRelevant = true
            elseif todo.scope == "character" then
                isRelevant = todo.enabledChars and todo.enabledChars[charKey]
            end

            if isRelevant then
                local alreadyDone
                if todo.scope == "warband" then
                    alreadyDone = BT.Data.GetWarbandCompleted(todoID)
                else
                    alreadyDone = BT.Data.GetCharCompleted(todoID, charKey)
                end

                if not alreadyDone then
                    local detected = false
                    local at = todo.autoTrack

                    if at.type == "quest" then
                        -- 支持新 questIDs 数组和旧 questID 单值
                        local ids = at.questIDs or (at.questID and {at.questID})
                        detected = ids and Tracking.CheckQuestIDs(ids) or false

                    elseif at.type == "instance_boss" then
                        -- 新格式：encounterIDs（EJ Encounter ID 数组）
                        -- 旧格式兼容：instanceID + encounterIndices/encounterIndex
                        if at.encounterIDs then
                            detected = Tracking.CheckEncounterIDs(at.encounterIDs)
                        else
                            local indices = at.encounterIndices
                                or (at.encounterIndex and {at.encounterIndex})
                            detected = indices and Tracking.CheckInstanceBoss(at.instanceID, indices) or false
                        end

                    elseif at.type == "currency" then
                        detected = at.currencyIDs and Tracking.CheckCurrencyIDs(at.currencyIDs) or false
                    end

                    if detected then
                        if todo.scope == "warband" then
                            BT.Data.SetWarbandCompleted(todoID, true)
                        else
                            BT.Data.SetCharCompleted(todoID, charKey, true)
                        end
                    end
                end
            end
        end
    end
end

-- ── Quest ID 检测（任意一个匹配即为完成）────────────────────────────────

function Tracking.CheckQuestIDs(questIDs)
    if not questIDs or #questIDs == 0 then return false end
    local groups = type(questIDs[1]) == "number" and {questIDs} or questIDs
    for _, group in ipairs(groups) do
        local ok = false
        for _, id in ipairs(group) do
            if C_QuestLog.IsQuestFlaggedCompleted(id) == true then ok = true; break end
        end
        if not ok then return false end
    end
    return true
end

-- ── Encounter ID 检测（通过 EJ 名称匹配副本锁，任意一个命中即完成）────

function Tracking.CheckEncounterIDs(encounterIDs)
    if not encounterIDs or #encounterIDs == 0 then return false end
    local groups = type(encounterIDs[1]) == "number" and {encounterIDs} or encounterIDs
    local numSaved = GetNumSavedInstances()
    for _, group in ipairs(groups) do
        local ok = false
        for _, encID in ipairs(group) do
            local encName = EJ_GetEncounterInfo(encID)
            if encName then
                for i = 1, numSaved do
                    local _, _, _, _, locked, _, _, _, _, _, numEncounters =
                        GetSavedInstanceInfo(i)
                    if locked then
                        for j = 1, numEncounters do
                            local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
                            if bossName == encName and isKilled then ok = true; break end
                        end
                    end
                    if ok then break end
                end
            end
            if ok then break end
        end
        if not ok then return false end
    end
    return true
end

-- ── Currency ID 检测（所有货币均达周上限时返回 true）──────────────────

function Tracking.CheckCurrencyIDs(currencyIDs)
    if not currencyIDs or #currencyIDs == 0 then return false end
    local groups = type(currencyIDs[1]) == "number" and {currencyIDs} or currencyIDs
    for _, group in ipairs(groups) do
        local ok = false
        for _, id in ipairs(group) do
            local info = C_CurrencyInfo.GetCurrencyInfo(id)
            if info and info.maxWeeklyQuantity > 0
               and info.quantityEarnedThisWeek >= info.maxWeeklyQuantity then
                ok = true; break
            end
        end
        if not ok then return false end
    end
    return true
end

-- ── Tooltip 进度数据获取 ───────────────────────────────────────────────────

-- Quest 名称查询：WoW API → ATT 直接名 → ATT providers/parent → "Quest {id}" 兜底
local function GetQuestName(id)
    -- 1. WoW 原生接口
    local name = C_QuestLog.GetTitleForQuestID(id)
    if name and name ~= "" then return name end

    -- 2. AllTheThings（不一定安装）
    local ATT = AllTheThings
    if not ATT then return "Quest " .. id end

    -- 2a. ATT 直接名称查询
    if type(ATT.GetQuestName) == "function" then
        name = ATT.GetQuestName(id)
        -- 若名字不以 * 结尾，说明 ATT 找到了真实名称
        if name and name ~= "" and name:sub(-1) ~= "*" then
            return name
        end
        -- 以 * 结尾：ATT 自身也没有名字，继续尝试 providers
    end

    -- 2b. 通过 SearchForObject 拿到 HQT 对象，读取 obj.name
    --     ATT 对有 `an` 字段（如 "n:NPC_ID"）的 HQT 会用 WithAutoName variant
    --     覆写 name getter，返回对应 NPC/物品/法术名称
    if type(ATT.SearchForObject) == "function" then
        local obj = ATT.SearchForObject("questID", id, "field")
        if obj then
            local oname = obj.name
            if oname and oname ~= "" and oname:sub(-1) ~= "*" then
                return oname
            end
            -- `an` 不存在或 name 仍为 *，再试 providers
            if type(ATT.GetNameFromProviders) == "function" then
                local pname = ATT.GetNameFromProviders(obj)
                if pname and pname ~= "" then return pname end
            end
        end
    end

    return "Quest " .. id
end

-- 返回 quest 进度：{{ {name, done}, ... }, ...}，每个子数组为一个 AND 组
function Tracking.GetQuestProgress(questIDs)
    if not questIDs or #questIDs == 0 then return {} end
    local groups = type(questIDs[1]) == "number" and {questIDs} or questIDs
    local result = {}
    for _, group in ipairs(groups) do
        local line = {}
        for _, id in ipairs(group) do
            local name = GetQuestName(id)
            local done = C_QuestLog.IsQuestFlaggedCompleted(id) == true
            table.insert(line, { name = name, done = done })
        end
        table.insert(result, line)
    end
    return result
end

-- 返回 encounter 进度：同结构
function Tracking.GetEncounterProgress(encounterIDs)
    if not encounterIDs or #encounterIDs == 0 then return {} end
    local groups = type(encounterIDs[1]) == "number" and {encounterIDs} or encounterIDs
    local numSaved = GetNumSavedInstances()
    local result = {}
    for _, group in ipairs(groups) do
        local line = {}
        for _, encID in ipairs(group) do
            local encName = EJ_GetEncounterInfo(encID) or ("Encounter "..encID)
            local killed = false
            for i = 1, numSaved do
                local _, _, _, _, locked, _, _, _, _, _, numEncounters = GetSavedInstanceInfo(i)
                if locked then
                    for j = 1, numEncounters do
                        local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
                        if bossName == encName and isKilled then killed = true; break end
                    end
                end
                if killed then break end
            end
            table.insert(line, { name = encName, done = killed })
        end
        table.insert(result, line)
    end
    return result
end

-- 返回 currency 进度：扁平列表（每项一行），含 atCap / groupSatisfied 标志
function Tracking.GetCurrencyProgress(currencyIDs)
    if not currencyIDs or #currencyIDs == 0 then return {} end
    local groups = type(currencyIDs[1]) == "number" and {currencyIDs} or currencyIDs
    local result = {}
    for _, group in ipairs(groups) do
        local groupSatisfied = false
        for _, id in ipairs(group) do
            local info = C_CurrencyInfo.GetCurrencyInfo(id)
            if info and info.maxWeeklyQuantity > 0
               and info.quantityEarnedThisWeek >= info.maxWeeklyQuantity then
                groupSatisfied = true; break
            end
        end
        for _, id in ipairs(group) do
            local info = C_CurrencyInfo.GetCurrencyInfo(id)
            if info then
                local atCap = info.maxWeeklyQuantity > 0
                    and info.quantityEarnedThisWeek >= info.maxWeeklyQuantity
                table.insert(result, {
                    name           = info.name,
                    icon           = info.iconFileID,
                    current        = info.quantityEarnedThisWeek,
                    max            = info.maxWeeklyQuantity,
                    atCap          = atCap,
                    groupSatisfied = groupSatisfied and not atCap,
                })
            end
        end
    end
    return result
end

-- ── 旧格式兼容：Instance ID + Encounter Index 数组 ────────────────────

function Tracking.CheckInstanceBoss(instanceID, encounterIndices)
    if not instanceID or not encounterIndices then return false end
    local numSaved = GetNumSavedInstances()
    for i = 1, numSaved do
        local _, id, _, _, locked, _, _, _, _, _, numEncounters =
            GetSavedInstanceInfo(i)
        if id == instanceID and locked then
            for _, encIdx in ipairs(encounterIndices) do
                if encIdx <= numEncounters then
                    local _, _, isKilled = GetSavedInstanceEncounterInfo(i, encIdx)
                    if isKilled then return true end
                end
            end
        end
    end
    return false
end
