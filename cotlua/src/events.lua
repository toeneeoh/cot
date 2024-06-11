--[[
    events.lua

    A library that defines custom events that can assign functions to units
]]

OnInit.final("Events", function()

    ---@class EVENT
    ---@field create function
    ---@field unit_actions table
    ---@field trigger function
    ---@field register_unit_action function
    ---@field unregister_unit_action function
    EVENT = {}
    do
        local thistype = EVENT
        local unit_actions_mt = { __mode = 'k' } --make keys weak for when units are removed
        local event_mt = { __index = thistype }

        ---@type fun(): EVENT
        function thistype.create()
            local self = setmetatable({
                unit_actions = setmetatable({}, unit_actions_mt),
            }, event_mt)

            return self
        end

        ---@type fun(self: EVENT, u: unit, ...)
        function thistype:trigger(u, ...)
            --run any actions registered with this unit
            local actions = self.unit_actions[u]
            if actions then
                for _, action in ipairs(actions) do
                    action(u, ...)
                end
            end
        end

        ---@type fun(self: EVENT, u: unit, func: function)
        function thistype:register_unit_action(u, func)
            if not u then
                return
            end
            if not self.unit_actions[u] then
                self.unit_actions[u] = {}
            end
            --prevent duplicate registers
            if not TableHas(self.unit_actions[u], func) then
                self.unit_actions[u][#self.unit_actions[u] + 1] = func
            end
        end

        function thistype:unregister_unit_action(u, func)
            if not u or not self.unit_actions[u] then
                return
            end

            --remove all registered functions if not specified
            if not func then
                self.unit_actions[u] = nil
            else
                TableRemove(self.unit_actions[u], func)
            end
        end
    end

    --event that is called when a unit's stat is changed (either from leveling, UnitTable, or UnitSetBonus)
    EVENT_STAT_CHANGE = EVENT.create() ---@type EVENT

end, Debug.getLine())
