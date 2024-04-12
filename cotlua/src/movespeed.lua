--[[
    movespeed.lua

    A module that implements unit movespeeds above the 522 hard limit.
]]

OnInit.global("Movespeed", function(Require)
    Require('TimerQueue')

do
    local MSX_PERIOD = 0.00625
    local MSX_MARGIN = 0.01
    local MSX_PERIODIC = nil ---@type function

    MOVESPEED_MIN = 100
    MOVESPEED_MAX = 522
    CUSTOM_MOVEMENT_TIMER = TimerQueue.create()
    MOVESPEED = setmetatable({}, {
        __newindex = function(tbl, key, val)
            if not CUSTOM_MOVEMENT_TIMER:isPaused() then
                CUSTOM_MOVEMENT_TIMER:callPeriodically(MSX_PERIOD, nil, MSX_PERIODIC)
            end
            rawset(tbl, key, val)
        end})

    local function ApproxEqual (A, B)
        return (A >= (B - MSX_MARGIN)) and (A <= (B + MSX_MARGIN))
    end

    MSX_PERIODIC = function()
        local u,order,d,dy,dx,ny,nx = nil,nil,nil,nil,nil,nil,nil
        for i = 1, #MOVESPEED do
            u = Unit[MOVESPEED[i]] ---@type Unit
            nx = GetUnitX(u.unit)
            ny = GetUnitY(u.unit)
            if not IsUnitPaused(u.unit) and (not ApproxEqual(nx, u.x) or not ApproxEqual(ny, u.y)) then
                order = GetUnitCurrentOrder(u.unit)
                dx = nx - u.x
                dy = ny - u.y
                d  = math.sqrt(dx ^ 2 + dy ^ 2)
                dx = dx / d * (u.movespeed - MOVESPEED_MAX) * MSX_PERIOD
                dy = dy / d * (u.movespeed - MOVESPEED_MAX) * MSX_PERIOD
                if (order == ORDER_ID_MOVE or order == ORDER_ID_SMART) and (((u.orderX - nx) ^ 2) < (dx ^ 2)) and (((u.orderY - ny) ^ 2) < (dy ^ 2)) then
                    u.x = u.orderX
                    u.y = u.orderY
                    IssueImmediateOrderById(u.unit, ORDER_ID_HOLD_POSITION)
                else
                    u.x = nx + dx
                    u.y = ny + dy
                end
            elseif u.movespeed <= MOVESPEED_MAX then
                MOVESPEED[i] = MOVESPEED[#MOVESPEED]
                MOVESPEED[#MOVESPEED] = nil
                i = i - 1
                if #MOVESPEED <= 0 then
                    CUSTOM_MOVEMENT_TIMER:pause()
                end
            end
        end
    end
end

end, Debug.getLine())
