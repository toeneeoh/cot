--[[
    events.lua

    A library that defines custom events that can be registered with functions
]]

OnInit.final("Events", function()

    --Custom event that is called when a unit's stat is changed (either from leveling, UnitTable, or UnitSetBonus)
    ---@class EVENT_STAT_CHANGE
    ---@field trigger function
    ---@field register_unit_action function
    ---@field register_event_action function
    EVENT_STAT_CHANGE = {}
    do
        local thistype = EVENT_STAT_CHANGE
        local unit_actions = {} ---@type table[]
        local event_actions = {} ---@type function[]

        local mt = {
                --make keys weak for when units are removed
                __mode = 'k'
            }

        setmetatable(unit_actions, mt)

        ---@type fun(u: unit)
        function thistype.trigger(u)
            --run any actions registered with this event
            for _, v in ipairs(event_actions) do
                v()
            end

            --run any actions registered with this unit
            if unit_actions[u] then
                for _, v in ipairs(unit_actions[u]) do
                    v(u)
                end
            end
        end

        ---@type fun(func: function)
        function thistype.register_event_action(func)
            event_actions[#event_actions + 1] = func
        end

        ---@type fun(u: unit, func: function)
        function thistype.register_unit_action(u, func)
            unit_actions[u] = unit_actions[u] or {}
            unit_actions[u][#unit_actions[u] + 1] = func
        end
    end
end, Debug.getLine())
