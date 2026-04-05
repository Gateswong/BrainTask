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
    if not questIDs then return false end
    for _, id in ipairs(questIDs) do
        if C_QuestLog.IsQuestFlaggedCompleted(id) == true then
            return true
        end
    end
    return false
end

-- ── Encounter ID 检测（通过 EJ 名称匹配副本锁，任意一个命中即完成）────

function Tracking.CheckEncounterIDs(encounterIDs)
    if not encounterIDs then return false end
    local numSaved = GetNumSavedInstances()
    for _, encID in ipairs(encounterIDs) do
        local encName = EJ_GetEncounterInfo(encID)
        if encName then
            for i = 1, numSaved do
                local _, _, _, _, locked, _, _, _, _, _, numEncounters =
                    GetSavedInstanceInfo(i)
                if locked then
                    for j = 1, numEncounters do
                        local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
                        if bossName == encName and isKilled then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

-- ── Currency ID 检测（所有货币均达周上限时返回 true）──────────────────

function Tracking.CheckCurrencyIDs(currencyIDs)
    if not currencyIDs or #currencyIDs == 0 then return false end
    for _, id in ipairs(currencyIDs) do
        local info = C_CurrencyInfo.GetCurrencyInfo(id)
        if not info or info.maxWeeklyQuantity <= 0 then return false end
        if info.quantityEarnedThisWeek < info.maxWeeklyQuantity then return false end
    end
    return true
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
