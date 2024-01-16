if Debug then Debug.beginFile 'Summon' end

OnInit.final("Summon", function(require)
    require 'Users'

        SummonGroup = {} ---@type unit[]

        helicopter  = {} ---@type unit[] 
        heliangle   = __jarray(0) ---@type number[] 
        helitargets = {} ---@type group[] 
        heliboost   = __jarray(0) ---@type number[] 
        destroyer   = {} ---@type unit[] 
        meatgolem   = {} ---@type unit[] 
        hounds      = {} ---@type unit[] 

        improvementArmorBonus=__jarray(0) ---@type integer[] 

    ---@param pid integer
    function ClusterRockets(pid)
        local ug = CreateGroup()

        BlzGroupAddGroupFast(helitargets[pid], ug)
        --clean helitargets
        for target in each(ug) do
            if UnitAlive(target) == false or UnitDistance(target, helicopter[pid]) > 1500. or IsUnitAlly(target, Player(pid - 1)) then
                GroupRemoveUnit(helitargets[pid], target)
            end
        end

        DestroyGroup(ug)

        BlzGroupAddGroupFast(helitargets[pid], ug)
        enemyCount = BlzGroupGetSize(ug)

        local x, y, z = GetUnitX(helicopter[pid]), GetUnitY(helicopter[pid]), BlzGetUnitZ(helicopter[pid]) - 20

        --single shot
        if sniperstance[pid] then
            local target = FirstOfGroup(helitargets[pid])

            if UnitAlive(LAST_TARGET[pid]) then
                target = LAST_TARGET[pid]
            end

            local missile = Missiles:create(x, y, z, GetUnitX(target), GetUnitY(target), BlzGetUnitZ(target)) ---@type Missiles
            missile:model("war3mapImported\\HighSpeedProjectile_ByEpsilon.mdx")
            missile:scale(1.1)
            missile:speed(1800)
            missile:arc(GetRandomReal(5, 15))
            missile.source = Hero[pid]
            missile.target = target
            missile.owner = Player(pid - 1)
            missile:vision(500)
            missile.collision = 75.
            missile.damage = ASSAULTHELICOPTER.dmg(pid) * 2.5 * BOOST[pid]

            missile.onHit = function(unit)
                if unit == missile.target then
                    UnitDamageTarget(missile.source, unit, missile.damage, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)

                    return true
                end

                return false
            end
        --multi shot
        else
            for enemy in each(helitarget[pid]) do
                local missile = Missiles:create(x, y, z, GetUnitX(enemy), GetUnitY(enemy), BlzGetUnitZ(enemy)) ---@type Missiles
                missile:model("Abilities\\Spells\\Other\\TinkerRocket\\TinkerRocketMissile.mdl")
                missile:scale(1.1)
                missile:speed(1400)
                missile.source = Hero[pid]
                missile.target = enemy
                missile.owner = Player(pid - 1)
                missile:vision(500)
                missile.collision = 75.
                missile.damage = ASSAULTHELICOPTER.dmg(pid) * BOOST[pid]

                missile.onHit = function(unit)
                    if unit == missile.target then
                        UnitDamageTarget(missile.source, unit, missile.damage, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)

                        return true
                    end

                    return false
                end
            end
        end
    end

    ---@type fun(pid: integer)
    local function HeliCD(pid)
        heliCD[pid] = false
    end

    ---@type fun(pid: integer)
    local function HeliPeriodic(pid)
        if helicopter[pid] then
            local x = GetUnitX(Hero[pid]) + 60. * Cos(bj_DEGTORAD * (heliangle[pid] + GetUnitFacing(Hero[pid])))
            local y = GetUnitY(Hero[pid]) + 60. * Sin(bj_DEGTORAD * (heliangle[pid] + GetUnitFacing(Hero[pid])))

            if DistanceCoords(x, y, GetUnitX(helicopter[pid]), GetUnitY(helicopter[pid])) > 75. then
                DisableTrigger(pointOrder)
                IssuePointOrder(helicopter[pid], "move", x, y)
                EnableTrigger(pointOrder)
            end

            if UnitAlive(LAST_TARGET[pid]) then
                SetUnitFacing(helicopter[pid], bj_RADTODEG * Atan2(LAST_TARGET_Y[pid] - GetUnitY(helicopter[pid]), LAST_TARGET_X[pid] - GetUnitX(helicopter[pid])))
            end

            --acquire helicopter targets near hero
            GroupEnumUnitsInRangeEx(pid, helitargets[pid], GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 1200., Condition(FilterEnemyAwake))

            if BlzGroupGetSize(helitargets[pid]) > 0 and not heliCD[pid] then
                heliCD[pid] = true
                TimerQueue:callDelayed(1.25 - (0.25 * GetUnitAbilityLevel(Hero[pid], FourCC('A06U')) * LBOOST[pid]), HeliCD, pid)
                ClusterRockets(pid)
            end
        end
    end

    local function HeliLeash(pid)
        if helicopter[pid] and UnitDistance(Hero[pid], helicopter[pid]) > 700. then
            SetUnitPosition(helicopter[pid], GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))
        end
    end

    ---@type fun(pid: integer, tag: texttag)
    local function HelicopterExpire(pid, tag, pt)
        SoundHandler("Units\\Human\\Gyrocopter\\GyrocopterPissed6.flac", true, nil, helicopter[pid])
        IssuePointOrder(helicopter[pid], "move", GetUnitX(Hero[pid]) + 1000. * Cos(bj_DEGTORAD * GetUnitFacing(Hero[pid])), GetUnitY(Hero[pid]) + 1000. * Sin(bj_DEGTORAD * GetUnitFacing(Hero[pid])))
        TimerQueue:callDelayed(2., RemoveUnit, helicopter[pid])
        Fade(helicopter[pid], 2., true)
        DestroyTextTag(tag)
        helicopter[pid] = nil

        pt:destroy()
    end

    function onSummon()
        local caster = GetSummoningUnit() ---@type unit 
        local summon = GetSummonedUnit() ---@type unit 
        local pid    = GetPlayerId(GetOwningPlayer(caster)) + 1 ---@type integer 
        local uid    = GetUnitTypeId(summon) ---@type integer 

        --Elite Marksman Assault Helicopter
        if uid == FourCC('h03W') or uid == FourCC('h03V') or uid == FourCC('h03H') then
            GroupClear(helitargets[pid])
            heliboost[pid] = BOOST[pid]
            helicopter[pid] = summon
            SetUnitFlyHeight(helicopter[pid], 1100., 0.)
            SetUnitFlyHeight(helicopter[pid], 300., 500.)
            UnitAddIndicator(helicopter[pid], 255, 255, 255, 255)
            local helitag = CreateTextTag()
            SetTextTagText(helitag, RealToString(heliboost[pid] * 100) .. "\x25", 0.024)
            SetTextTagColor(helitag, 255, R2I(270 - heliboost[pid] * 150), R2I(270 - heliboost[pid] * 150), 255)

            TimerQueue:callPeriodically(FPS_32, not UnitAlive(helicopter[pid]), function() SetTextTagPosUnit(helitag, helicopter[pid], -200.) end)

            SoundHandler("Units\\Human\\Gyrocopter\\GyrocopterWhat" .. (GetRandomInt(1,5)) .. ".flac", true, nil, helicopter[pid])

            local pt = TimerList[pid]:add()
            pt.timer:callPeriodically(0.25, nil, HeliPeriodic, pid)
            pt.timer:callPeriodically(6., nil, function() heliangle[pid] = GetRandomInt(1, 3) * 120 - 60 end)
            pt.timer:callPeriodically(1., nil, HeliLeash, pid)
            TimerQueue:callDelayed(ASSAULTHELICOPTER.dur * LBOOST[pid], HelicopterExpire, pid, helitag, pt)
        else
            return
        end

        SummonGroup[#SummonGroup + 1] = summon

        if IsUnitType(summon, UNIT_TYPE_HERO) then
            SetHeroLevelBJ(summon, GetHeroLevel(Hero[pid]), false)
            SuspendHeroXP(summon, true)
        end
    end

    local summon = CreateTrigger() ---@type trigger 
    local u = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(summon, u.player, EVENT_PLAYER_UNIT_SUMMON, nil)
        helitargets[GetPlayerId(u.player) + 1] = CreateGroup()
        u = u.next
    end

    TriggerAddAction(summon, onSummon)
end)

if Debug then Debug.endFile() end
