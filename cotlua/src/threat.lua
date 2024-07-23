--[[
    threat.lua

    This library handles units behave when they acquire targets and implements a threat system for creeps and bosses.
]]

OnInit.final("Threat", function(Require)
    Require("WorldBounds")
    Require("Damage")

    local CALL_FOR_HELP_RANGE = 800.

    ACQUIRE_TRIGGER = CreateTrigger()
    Threat = array2d(0)
    THREAT_CAP = 4000 ---@type integer 

    ---@return boolean
    local function ProximityFilter()
        local u = GetFilterUnit()

        return not IsDummy(u) and
        GetUnitAbilityLevel(u, FourCC('Avul')) == 0 and
        GetPlayerId(GetOwningPlayer(u)) < PLAYER_CAP
    end

    ---@type fun(source: unit, target: unit, dist: number):unit
    local function AcquireProximity(source, target, dist)
        local ug    = CreateGroup()
        local x     = GetUnitX(source) ---@type number 
        local y     = GetUnitY(source) ---@type number 
        local index = -1

        GroupEnumUnitsInRange(ug, x, y, dist, Filter(ProximityFilter))

        for i, prox in ieach(ug) do
            --dont acquire the same target
            if SquareRoot(Pow(x - GetUnitX(prox), 2) + Pow(y - GetUnitY(prox), 2)) < dist and Unit[source].target ~= target then
                dist = SquareRoot(Pow(x - GetUnitX(prox), 2) + Pow(y - GetUnitY(prox), 2))
                index = i
            end
        end

        if index ~= -1 then
            target = BlzGroupUnitAt(ug, index)
        end

        DestroyGroup(ug)
        return target
    end

    ---@type fun(pt: PlayerTimer)
    function RunDropAggro(pt)
        local ug = CreateGroup()

        MakeGroupInRange(pt.pid, ug, GetUnitX(pt.source), GetUnitY(pt.source), 800., Condition(FilterEnemy))

        for target in each(ug) do
            if Unit[target].target == pt.source then
                local prox = AcquireProximity(target, pt.source, 800.)
                IssueTargetOrder(target, "smart", prox)
                Unit[target].target = prox
                break
            end
        end

        pt:destroy()

        DestroyGroup(ug)
    end

    ---@return boolean
    local function onAcquire()
        local target = GetEventTargetUnit() ---@type unit 
        local source = GetTriggerUnit() ---@type unit 

        EVENT_ON_AGGRO:trigger(source, target)

        if Unit[source] then
            Unit[source].target = target
        end

        return false
    end

    local function enemy_aggro(target, source, amount, amount_after_red, damage_type)
        -- call for help
        local pid = GetPlayerId(GetOwningPlayer(source)) + 1
        local ug = CreateGroup()
        MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), CALL_FOR_HELP_RANGE, Condition(FilterEnemy))

        for enemy in each(ug) do
            if GetUnitCurrentOrder(enemy) == 0 and enemy ~= target then --current idle
                UnitWakeUp(enemy)
                IssueTargetOrder(enemy, "smart", AcquireProximity(enemy, source, 800.))
            end
        end

        DestroyGroup(ug)
    end

    local function threat_init()
        local u = GetFilterUnit()

        TriggerRegisterUnitEvent(ACQUIRE_TRIGGER, u, EVENT_UNIT_ACQUIRED_TARGET)

        if IsEnemy(GetPlayerId(GetOwningPlayer(u)) + 1) then
            EVENT_ON_STRUCK_FINAL:register_unit_action(u, enemy_aggro)
        end

        return false
    end

    TriggerAddCondition(ACQUIRE_TRIGGER, Filter(onAcquire))

    local t = CreateTrigger()
    TriggerRegisterEnterRegion(t, WorldBounds.region, Filter(threat_init))

end, Debug and Debug.getLine())
