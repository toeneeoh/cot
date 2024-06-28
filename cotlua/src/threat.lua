--[[
    threat.lua

    This library handles units behave when they acquire targets and implements a threat system for creeps and bosses.
]]

OnInit.final("Threat", function(Require)
    Require("WorldBounds")

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
        local attacker = GetTriggerUnit() ---@type unit 
        local pid = GetPlayerId(GetOwningPlayer(attacker)) + 1

        if IsDummy(attacker) then
            BlzSetUnitWeaponBooleanField(attacker, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
        elseif GetPlayerController(Player(pid - 1)) ~= MAP_CONTROL_USER then
            Unit[attacker].target = AcquireProximity(attacker, target, 800.)
            TimerQueue:callDelayed(FPS_32, SwitchAggro, attacker, target)
        elseif Unit[attacker] then
            Unit[attacker].target = target

            if Unit[attacker].movespeed > MOVESPEED.MAX then
                BlzSetUnitFacingEx(attacker, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(attacker), GetUnitX(target) - GetUnitX(attacker)))
            end
        end

        return false
    end

    local function onStruck(target, source, amount_after_red, damage_type)
        --call for help
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

        --stop the reset timer on damage
        TimerList[pid]:stopAllTimers('aggr')

        local index = IsBoss(target)

        if index ~= -1 and IsUnitIllusion(target) == false then
            --boss spell casting
            BossSpellCasting(source, target)

            if damage_type == PHYSICAL then --only physical because magic procs are too inconsistent 

                local threat = Threat[target][source]

                if threat < THREAT_CAP then --prevent multiple occurences
                    threat = threat + IMaxBJ(1, 100 - R2I(UnitDistance(target, source) * 0.12)) --~40 as melee, ~250 at 700 range
                    Threat[target][source] = threat

                    --switch target
                    if threat >= THREAT_CAP and Unit[target].target ~= source and Threat[target].switching == 0 then
                        ChangeAggro(target, source)
                    end
                end
            end

            --keep track of boss damage
            BossTable[index].damage[pid] = BossTable[index].damage[pid] + amount_after_red
            BossTable[index].total_damage = BossTable[index].total_damage + amount_after_red
        end
    end

    local function threat_init()
        local u = GetFilterUnit()

        TriggerRegisterUnitEvent(ACQUIRE_TRIGGER, u, EVENT_UNIT_ACQUIRED_TARGET)

        if IsEnemy(GetPlayerId(GetOwningPlayer(u)) + 1) then
            EVENT_ON_STRUCK_AFTER_REDUCTIONS:register_unit_action(u, onStruck)
        end

        return false
    end

    TriggerAddCondition(ACQUIRE_TRIGGER, Filter(onAcquire))

    local t = CreateTrigger()
    TriggerRegisterEnterRegion(t, WorldBounds.region, Filter(threat_init))

end, Debug and Debug.getLine())
