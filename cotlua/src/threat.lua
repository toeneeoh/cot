--[[
    threat.lua

    This library handles units behave when they acquire targets and implements a threat system for creeps and bosses.
]]

OnInit.final("Threat", function(Require)
    Require("WorldBounds")
    Require("Damage")

    ACQUIRE_TRIGGER = CreateTrigger()

    local CALL_FOR_HELP_RANGE = 800.

    local filter_unit

    ---@return boolean
    local function ProximityFilter()
        local u = GetFilterUnit()

        return not IsDummy(u) and
        Unit[u] and
        GetUnitAbilityLevel(u, FourCC('Avul')) == 0 and
        GetUnitAbilityLevel(u, FourCC('Aloc')) == 0 and
        GetPlayerId(GetOwningPlayer(u)) < PLAYER_CAP
    end

    local function acquire_new_proximity(source, orig, dist)
        local ug = CreateGroup()
        local x  = GetUnitX(source)
        local y  = GetUnitY(source)
        local new_target = IsUnitInRange(source, orig.unit, dist) and orig.unit or nil

        GroupEnumUnitsInRange(ug, x, y, dist, Filter(ProximityFilter))
        -- dont acquire the same target
        GroupRemoveUnit(ug, orig.unit)

        for enemy in each(ug) do
            if IsUnitInRange(source, enemy, dist) then
                dist = UnitDistance(source, enemy)
                new_target = enemy
            end
        end

        if new_target then
            Unit[new_target]:taunt(Unit[source])
        else
            Unit[source].target = nil
            IssuePointOrderById(source, ORDER_ID_MOVE, Unit[source].original_x, Unit[source].original_y)
        end

        DestroyGroup(ug)
    end

    function DropAggro(unit)
        for enemy in each(unit.taunted) do
            TimerQueue:callDelayed(0., acquire_new_proximity, enemy, unit, CALL_FOR_HELP_RANGE)
        end

        GroupClear(unit.taunted)
    end

    local function reset_aggro_timer(source)
        source = Unit[source]

        if source.aggro_timer then
            source.aggro_timer:reset()
            source.aggro_timer:callDelayed(3., DropAggro, source)
        end
    end

    ---@return boolean
    local function onAcquire()
        local target = GetEventTargetUnit()
        local source = GetTriggerUnit()

        if source and target then
            EVENT_ON_AGGRO:trigger(source, target)
        end

        return false
    end

    local function creep_aggro(source, target)
        local enemy = Unit[source].target or Unit[source]
        Unit[target]:taunt(enemy)
    end

    local function call_for_help(target, source, amount, amount_after_red, damage_type)
        -- call for help
        local ug = CreateGroup()
        MakeGroupInRange(PLAYER_NEUTRAL_AGGRESSIVE, ug, GetUnitX(target), GetUnitY(target), CALL_FOR_HELP_RANGE, Condition(FilterAlly))

        for enemy in each(ug) do
            -- only aggro other creep allies
            if not Unit[enemy].target and GetOwningPlayer(enemy) == PLAYER_CREEP then
                Unit[source]:taunt(Unit[enemy])
            end
        end

        DestroyGroup(ug)
    end

    local function threat_init()
        local u = GetFilterUnit()
        local p = GetOwningPlayer(u)
        local pid = GetPlayerId(p) + 1

        TriggerRegisterUnitEvent(ACQUIRE_TRIGGER, u, EVENT_UNIT_ACQUIRED_TARGET)

        if p == PLAYER_CREEP then
            EVENT_ON_STRUCK_FINAL:register_unit_action(u, call_for_help)
            EVENT_ON_AGGRO:register_unit_action(u, creep_aggro)
        elseif pid <= PLAYER_CAP then
            EVENT_ON_HIT:register_unit_action(u, reset_aggro_timer)
            EVENT_ON_CAST:register_unit_action(u, reset_aggro_timer)
        end

        return false
    end

    TriggerAddCondition(ACQUIRE_TRIGGER, Filter(onAcquire))

    local t = CreateTrigger()
    TriggerRegisterEnterRegion(t, WorldBounds.region, Filter(threat_init))

end, Debug and Debug.getLine())
