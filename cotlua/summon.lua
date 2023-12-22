if Debug then Debug.beginFile 'Summon' end

OnInit.final("Summon", function(require)
    require 'Users'

        SummonGroup       = CreateGroup()

        helicopter={} ---@type unit[] 
        heliangle=__jarray(0) ---@type number[] 
        helitargets={} ---@type group[] 
        heliboost=__jarray(0) ---@type number[] 
        helitag={} ---@type texttag[] 
        destroyer={} ---@type unit[] 
        meatgolem={} ---@type unit[] 
        hounds={} ---@type unit[] 
        improvementArmorBonus=__jarray(0) ---@type integer[] 

    ---@type fun(pid: integer)
    function ClusterRocketsDamage(pid)
        local ug       = CreateGroup()

        BlzGroupAddGroupFast(helitargets[pid], ug)

        local target = FirstOfGroup(ug)
        while target do
            GroupRemoveUnit(ug, target)
            if LoadInteger(MiscHash, GetHandleId(target), FourCC('heli')) == 1 and sniperstance[pid] then
                UnitDamageTarget(Hero[pid], target, ASSAULTHELICOPTER.dmg(pid) * heliboost[pid] * 3., true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                RemoveSavedInteger(MiscHash, GetHandleId(target), FourCC('heli'))
            elseif not sniperstance[pid] then
                UnitDamageTarget(Hero[pid], target, ASSAULTHELICOPTER.dmg(pid) * heliboost[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            end
            target = FirstOfGroup(ug)
        end

        DestroyGroup(ug)
    end

    ---@param pid integer
    function ClusterRockets(pid)
        local i         = 0 ---@type integer 
        local i2         = 0 ---@type integer 
        local ugs={} ---@type group[] 
        local ug       = CreateGroup()
        local ug2       = CreateGroup()
        local target ---@type unit 
        local target2 ---@type unit 
        local enemyCount         = 0 ---@type integer 
        local enemyCaptured         = 0 ---@type integer 
        local groupIndex         = 0 ---@type integer 
        local targetArray={} ---@type unit[] 

        BlzGroupAddGroupFast(helitargets[pid], ug)
        --clean helitargets
        while true do
            target = FirstOfGroup(ug)
            if target == nil then break end
            GroupRemoveUnit(ug, target)
            if UnitAlive(target) == false or UnitDistance(target, helicopter[pid]) > 1500. or IsUnitAlly(target, Player(pid - 1)) then
                GroupRemoveUnit(helitargets[pid], target)
            end
        end

        BlzGroupAddGroupFast(helitargets[pid], ug)
        enemyCount = BlzGroupGetSize(ug)

        if enemyCount > 0 then
            if sniperstance[pid] then
                if UnitAlive(LAST_TARGET[pid]) then
                    target = LAST_TARGET[pid]
                else
                    target = FirstOfGroup(helitargets[pid])
                end
                GroupClear(helitargets[pid])
                GroupAddUnit(helitargets[pid], target)
                target2 = GetDummy(GetUnitX(helicopter[pid]), GetUnitY(helicopter[pid]), FourCC('A03N'), 1, DUMMY_RECYCLE_TIME)
                SetUnitOwner(target2, Player(pid - 1), true)
                IssuePointOrder(target2, "clusterrockets", GetUnitX(target), GetUnitY(target))
                SetUnitFlyHeight(target2, GetUnitFlyHeight(helicopter[pid]), 30000.)
                SaveInteger(MiscHash, GetHandleId(target), FourCC('heli'), 1)
            else
                target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    if enemyCaptured < enemyCount then
                        ugs[i] = CreateGroup()
                        MakeGroupInRange(pid, ugs[i], GetUnitX(target), GetUnitY(target), 300., Condition(FilterEnemy))
                        enemyCaptured = enemyCaptured + BlzGroupGetSize(ugs[i])
                        targetArray[i] = nil
                        if i > 0 then
                            --check overlapping units
                            BlzGroupAddGroupFast(ugs[i], ug2)
                            while true do
                                target2 = FirstOfGroup(ug2)
                                if target2 == nil then break end
                                GroupRemoveUnit(ug2, target2)
                                i2 = 0
                                while i2 ~= i do
                                    if IsUnitInGroup(target2, ugs[i2]) then
                                        enemyCaptured = enemyCaptured - 1
                                        GroupRemoveUnit(ugs[i], target2)
                                    end
                                    i2 = i2 + 1
                                end
                            end
                            if BlzGroupGetSize(ugs[i]) > 0 then
                                targetArray[i] = FirstOfGroup(ugs[i])
                            end
                            if enemyCaptured >= enemyCount then
                                groupIndex = i
                                break
                            end
                        else
                            targetArray[0] = target
                        end
                    elseif groupIndex == 0 then
                        groupIndex = i
                        break
                    end
                    i = i + 1
                    target = FirstOfGroup(ug)
                end

                i = 0

                while i <= groupIndex do
                    if UnitAlive(targetArray[i]) then
                        target = GetDummy(GetUnitX(helicopter[pid]), GetUnitY(helicopter[pid]), FourCC('A04D'), 1, DUMMY_RECYCLE_TIME)
                        SetUnitOwner(target, Player(pid - 1), true)
                        IssuePointOrder(target, "clusterrockets", GetUnitX(targetArray[i]), GetUnitY(targetArray[i]))
                        SetUnitFlyHeight(target, GetUnitFlyHeight(helicopter[pid]), 30000.)
                    end
                    targetArray[i] = nil
                    DestroyGroup(ugs[i])
                    ugs[i] = nil
                    i = i + 1
                end
            end

            TimerQueue:callDelayed(0.8, ClusterRocketsDamage, pid)
        end


        DestroyGroup(ug)
        DestroyGroup(ug2)
    end

    ---@type fun(pid: integer)
    function HeliCD(pid)
        heliCD[pid] = false
    end

    ---@type fun(pt: PlayerTimer)
    function HeliPeriodic(pt)
        if UnitAlive(helicopter[pt.pid]) then
            local x = GetUnitX(Hero[pt.pid]) + 60. * Cos(bj_DEGTORAD * (heliangle[pt.pid] + GetUnitFacing(Hero[pt.pid])))
            local y = GetUnitY(Hero[pt.pid]) + 60. * Sin(bj_DEGTORAD * (heliangle[pt.pid] + GetUnitFacing(Hero[pt.pid])))

            if DistanceCoords(x, y, GetUnitX(helicopter[pt.pid]), GetUnitY(helicopter[pt.pid])) > 75. then
                DisableTrigger(pointOrder)
                IssuePointOrder(helicopter[pt.pid], "move", x, y)
                EnableTrigger(pointOrder)
            end

            GroupEnumUnitsInRangeEx(pt.pid, helitargets[pt.pid], GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]), 1200., Condition(FilterEnemyAwake))

            if BlzGroupGetSize(helitargets[pt.pid]) > 0 and not heliCD[pt.pid] then
                heliCD[pt.pid] = true
                TimerQueue:callDelayed(1.25 - (0.25 * GetUnitAbilityLevel(Hero[pt.pid], FourCC('A06U')) * LBOOST[pt.pid]), HeliCD, pt.pid)
                ClusterRockets(pt.pid)
            end
        else
            pt:destroy()
        end
    end

    ---@type fun(pid: integer)
    function HelicopterExpire(pid)
        SoundHandler("Units\\Human\\Gyrocopter\\GyrocopterPissed6.flac", true, nil, helicopter[pid])
        IssuePointOrder(helicopter[pid], "move", GetUnitX(Hero[pid]) + 1000. * Cos(bj_DEGTORAD * GetUnitFacing(Hero[pid])), GetUnitY(Hero[pid]) + 1000. * Sin(bj_DEGTORAD * GetUnitFacing(Hero[pid])))
        TimerQueue:callDelayed(2., RemoveUnit, helicopter[pid])
        Fade(helicopter[pid], 2., true)

        helicopter[pid] = nil
    end

    function onSummon()
        local caster      = GetSummoningUnit() ---@type unit 
        local summon      = GetSummonedUnit() ---@type unit 
        local pid         = GetPlayerId(GetOwningPlayer(caster)) + 1 ---@type integer 
        local uid         = GetUnitTypeId(summon) ---@type integer 
        local ug       = CreateGroup()
        local pt ---@type PlayerTimer 

        --Elite Marksman Assault Helicopter
        if uid == FourCC('h03W') or uid == FourCC('h03V') or uid == FourCC('h03H') then
            GroupClear(helitargets[pid])
            heliboost[pid] = BOOST[pid]
            helicopter[pid] = summon
            SetUnitFlyHeight(helicopter[pid], 1100., 0.)
            SetUnitFlyHeight(helicopter[pid], 300., 500.)
            UnitAddIndicator(helicopter[pid], 255, 255, 255, 255)
            helitag[pid] = CreateTextTag()
            SetTextTagText(helitag[pid], RealToString(heliboost[pid] * 100) .. "%", 0.024)
            SetTextTagColor(helitag[pid], 255, R2I(270 - heliboost[pid] * 150), R2I(270 - heliboost[pid] * 150), 255)
            DestroyTextTagTimed(helitag[pid], 28.5)
            SoundHandler("Units\\Human\\Gyrocopter\\GyrocopterWhat" .. (GetRandomInt(1,5)) .. ".flac", true, nil, helicopter[pid])

            pt = TimerList[pid]:add()
            pt.timer:callPeriodically(0.35, nil, HeliPeriodic, pt)
            TimerQueue:callDelayed(ASSAULTHELICOPTER.dur * LBOOST[pid], HelicopterExpire, pid)
            TimerQueue:callPeriodically(6., not UnitAlive(helicopter[pid]), function() heliangle[pid] = GetRandomInt(1, 3) * 120 - 60 end)
        else
            DestroyGroup(ug)
            return
        end

        GroupAddUnit(SummonGroup, summon)

        if IsUnitType(summon, UNIT_TYPE_HERO) then
            SetHeroLevelBJ(summon, GetHeroLevel(Hero[pid]), false)
            SuspendHeroXP(summon, true)
        end

        DestroyGroup(ug)
    end

    local summon         = CreateTrigger() ---@type trigger 
    local u      = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(summon, u.player, EVENT_PLAYER_UNIT_SUMMON, nil)
        helitargets[GetPlayerId(u.player) + 1] = CreateGroup()
        u = u.next
    end

    TriggerAddAction(summon, onSummon)

end)

if Debug then Debug.endFile() end
