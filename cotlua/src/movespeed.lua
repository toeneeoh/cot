--[[
    movespeed.lua

    A module that implements unit movespeeds above the 522 game limit.
]]

OnInit.global("Movespeed", function(Require)
    Require('TimerQueue')

    do
        MOVESPEED = { MIN = 100, MAX = 522, SOFTCAP = 600, units = {} }

        local MOVESPEED = MOVESPEED
        local MS_PERIOD = 0.00625
        local MS_MARGIN = 0.01

        local sqrt = math.sqrt

        local function ApproxEqual (A, B)
            return (A >= (B - MS_MARGIN)) and (A <= (B + MS_MARGIN))
        end

        local MS_PERIODIC = function()
            local u,order,d,dy,dx,ny,nx = nil,nil,nil,nil,nil,nil,nil
            for i = 1, #MOVESPEED.units do
                u = Unit[MOVESPEED.units[i]] ---@type Unit
                nx = GetUnitX(u.unit)
                ny = GetUnitY(u.unit)
                if not IsUnitPaused(u.unit) and (not ApproxEqual(nx, u.x) or not ApproxEqual(ny, u.y)) then
                    order = GetUnitCurrentOrder(u.unit)
                    dx = nx - u.x
                    dy = ny - u.y
                    d  = sqrt(dx * dx + dy * dy)
                    dx = dx / d * (u.movespeed - MOVESPEED.MAX) * MS_PERIOD
                    dy = dy / d * (u.movespeed - MOVESPEED.MAX) * MS_PERIOD
                    if (order == ORDER_ID_MOVE or order == ORDER_ID_SMART) and (((u.orderX - nx) ^ 2) < (dx * dx)) and (((u.orderY - ny) ^ 2) < (dy * dy)) then
                        u.x = u.orderX
                        u.y = u.orderY
                        IssueImmediateOrderById(u.unit, ORDER_ID_HOLD_POSITION)
                    else
                        u.x = nx + dx
                        u.y = ny + dy
                    end
                end
            end
        end

        TimerQueue:callPeriodically(MS_PERIOD, nil, MS_PERIODIC)
    end
end, Debug and Debug.getLine())
