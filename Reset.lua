-- BrainTask Reset
-- 日/周重置检测与执行

BrainTask = BrainTask or {}
local BT = BrainTask
BT.Reset = {}
local Reset = BT.Reset

function Reset.Check()
    local d = BrainTaskDB
    if not d then return end

    local now = time()

    -- ── 日重置 ──────────────────────────────────────────────────────────
    local okD, secUntilDaily = pcall(C_DateAndTime.GetSecondsUntilDailyReset)
    if okD and secUntilDaily and secUntilDaily > 0 then
        -- 上次日重置的时间戳
        local lastDaily = now - (86400 - secUntilDaily)
        if (d.lastDailyReset or 0) < lastDaily then
            Reset.ResetByType("daily")
            d.lastDailyReset = lastDaily
        end
    end

    -- ── 周重置 ──────────────────────────────────────────────────────────
    local okW, secUntilWeekly = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset)
    if okW and secUntilWeekly and secUntilWeekly > 0 then
        local lastWeekly = now - (604800 - secUntilWeekly)
        if (d.lastWeeklyReset or 0) < lastWeekly then
            Reset.ResetByType("weekly")
            d.lastWeeklyReset = lastWeekly
        end
    end
end

function Reset.ResetByType(resetType)
    local d = BrainTaskDB
    for todoID, todo in pairs(d.todos) do
        if todo.resetType == resetType then
            if todo.scope == "warband" then
                if d.warbandData[todoID] then
                    d.warbandData[todoID].completed   = false
                    d.warbandData[todoID].completedAt = nil
                end
            else
                -- 角色事项：重置所有已记录角色的状态
                for _, charTodos in pairs(d.charData) do
                    if charTodos[todoID] then
                        charTodos[todoID].completed   = false
                        charTodos[todoID].completedAt = nil
                    end
                end
            end
        end
    end
end
