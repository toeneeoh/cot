--[[
    events.lua

    A library that defines custom events that can assign functions to units or players
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
        local unit_actions_mt = { __mode = 'k' } -- make keys weak for when units are removed
        local event_mt = { __index = thistype }

        ---@return EVENT
        function thistype.create()
            local self = setmetatable({
                unit_actions = setmetatable({}, unit_actions_mt),
            }, event_mt)

            return self
        end

        local recurse = {}

        ---@type fun(self: EVENT, u: unit, ...)
        function thistype:trigger(u, ...)
            if not u then
                return
            end

            -- prevent actions from triggering the event for a unit again
            if not recurse[u] then
                recurse[u] = true
                -- run any actions registered with this unit
                local actions = self.unit_actions[u]
                if actions then
                    for i = 1, #actions do
                        actions[i](u, ...)
                    end
                end
                recurse[u] = nil
            end
        end

        ---@type fun(self: EVENT, u: unit, func: function): boolean
        function thistype:register_unit_action(u, func)
            if not u then
                return false
            end
            if not self.unit_actions[u] then
                self.unit_actions[u] = {}
            end
            -- prevent duplicate registers
            if not TableHas(self.unit_actions[u], func) then
                self.unit_actions[u][#self.unit_actions[u] + 1] = func
                return true
            end

            return false
        end

        function thistype:unregister_unit_action(u, func)
            if not u or not self.unit_actions[u] then
                return
            end

            -- remove all registered functions if not specified
            if not func then
                self.unit_actions[u] = nil
            else
                TableRemove(self.unit_actions[u], func)
            end
        end
    end

    -- A completely different type of event that is not ascribed to units but players
    -- Unlike unit events it is not cleaned automatically upon removal of the unit (because units are not used)

    ---@class PLAYER_EVENT
    ---@field create function
    ---@field actions table
    ---@field trigger function
    ---@field register_action function
    ---@field unregister_action function
    PLAYER_EVENT = {}
    do
        local thistype = PLAYER_EVENT
        local event_mt = { __index = thistype }

        ---@return PLAYER_EVENT
        function thistype.create()
            local self = setmetatable({
                actions = {},
            }, event_mt)

            return self
        end

        ---@type fun(self: EVENT, pid: integer, ...)
        function thistype:trigger(pid, ...)
            -- run any actions registered with the player
            local actions = self.actions[pid]
            if actions then
                for i = 1, #actions do
                    actions[i](pid, ...)
                end
            end
        end

        ---@type fun(self: EVENT, pid: integer, func: function): boolean
        function thistype:register_action(pid, func)
            if not self.actions[pid] then
                self.actions[pid] = {}
            end
            -- prevent duplicate function registration
            if not TableHas(self.actions[pid], func) then
                self.actions[pid][#self.actions[pid] + 1] = func
                return true
            end

            return false
        end

        function thistype:unregister_action(pid, func)
            if not self.actions[pid] then
                return
            end

            -- remove all registered functions if not specified
            if not func then
                self.actions[pid] = nil
            else
                TableRemove(self.actions[pid], func)
            end
        end
    end

    -- event that is called when a unit's stat is changed (either from leveling, UnitTable, or UnitSetBonus)
    EVENT_STAT_CHANGE = EVENT.create() ---@type EVENT

    -- damage events
    EVENT_DUMMY_ON_HIT               = EVENT.create() ---@type EVENT
    EVENT_ON_HIT_EVADE               = EVENT.create() ---@type EVENT
    EVENT_ON_HIT                     = EVENT.create() ---@type EVENT
    EVENT_ON_HIT_MULTIPLIER          = EVENT.create() ---@type EVENT
    EVENT_ON_HIT_AFTER_REDUCTIONS    = EVENT.create() ---@type EVENT
    EVENT_ON_HIT_FINAL               = EVENT.create() ---@type EVENT
    EVENT_ON_STRUCK                  = EVENT.create() ---@type EVENT
    EVENT_ON_STRUCK_MULTIPLIER       = EVENT.create() ---@type EVENT
    EVENT_ON_STRUCK_AFTER_REDUCTIONS = EVENT.create() ---@type EVENT
    EVENT_ON_STRUCK_FINAL            = EVENT.create() ---@type EVENT
    EVENT_ON_FATAL_DAMAGE            = EVENT.create() ---@type EVENT
    EVENT_ENEMY_AI                   = EVENT.create() ---@type EVENT

    -- death events
    EVENT_ON_DEATH    = EVENT.create()
    EVENT_GRAVE_DEATH = EVENT.create()
    EVENT_ON_KILL     = EVENT.create()

    -- unit order events
    EVENT_ON_AGGRO = EVENT.create()
    EVENT_ON_CAST = EVENT.create()
    EVENT_ON_ORDER = EVENT.create()

    -- regions
    EVENT_ON_ENTER_SAFE_AREA = EVENT.create()

    -- specific unit selection (with hotkey as well)
    EVENT_ON_UNIT_SELECT = EVENT.create()
    -- player event version
    EVENT_ON_SELECT = PLAYER_EVENT.create()

    -- mouse events
    EVENT_ON_MOUSE_MOVE = PLAYER_EVENT.create()
    EVENT_ON_M1_DOWN = PLAYER_EVENT.create()
    EVENT_ON_M1_UP = PLAYER_EVENT.create()
    EVENT_ON_M2_DOWN = PLAYER_EVENT.create()
    EVENT_ON_M2_UP = PLAYER_EVENT.create()

    -- on player repick or leave
    EVENT_ON_CLEANUP = PLAYER_EVENT.create()

end, Debug and Debug.getLine())
