if Debug then Debug.beginFile 'Orders' end

OnInit.final("Orders", function(require)
    require 'Users'

    pointOrder         = CreateTrigger() ---@type trigger 
    bpmoving=__jarray(false) ---@type boolean[] 
    metamorphosis=__jarray(0) ---@type number[] 
    LAST_TARGET={} ---@type unit[] 
    LAST_TARGET_X=__jarray(0) ---@type number[] 
    LAST_TARGET_Y=__jarray(0) ---@type number[] 
    Moving=__jarray(false) ---@type boolean[] 

function OnOrder()
    local source      = GetTriggerUnit() ---@type unit 
    local p        = GetTriggerPlayer() ---@type player 
    local pid         = GetPlayerId(p) + 1 ---@type integer 
    local hl         = GetHeroLevel(source) ---@type integer 
    local id         = GetIssuedOrderId() ---@type integer 
    local x      = GetUnitX(source) ---@type number 
    local y      = GetUnitY(source) ---@type number 
    local ug       = CreateGroup()
    local pt ---@type PlayerTimer 

    if LIBRARY_dev then
        if EXTRA_DEBUG then
            DEBUGMSG(OrderId2String(id))
            DEBUGMSG((id))
        end
    end

    --smart
    if id == 851971 then --after 3 seconds drop aggro from all nearby enemies and redirect to allies
        pt = TimerList[pid]:get('aggr', nil, source)
        if not pt then
            pt = TimerList[pid]:add()
            pt.target = source
            pt.tag = 'aggr'
            TimerQueue:callDelayed(3., RunDropAggro, pt)
        end
    end

    --undefend
    if id == 852056 and GetPlayerController(GetOwningPlayer(source)) ~= MAP_CONTROL_USER then
        --flush threat level and acquired target
        Threat[source] = __jarray(0)
        --if unit is removed then deindex and flush references
        if GetUnitAbilityLevel(source, DETECT_LEAVE_ABILITY) == 0 then
            UnitDeindex(source)
        end
    end

    --faerfirefireon
    if id == 852150 then --devour
        pt = TimerList[pid]:get('blif', nil, source)
        if pt then
            pt:destroy()
        end
        pt = TimerList[pid]:add()
        pt.tag = 'dvou'
        pt.target = source
        pt.timer:callDelayed(1., DevourAutocast, pt)
    end

    --faeriefireoff
    if id == 852151 then --devour
        TimerList[pid]:stopAllTimers('dvou')
    end

    --bloodluston
    if id == 852102 then --borrowed life
        pt = TimerList[pid]:get('dvou', nil, source)
        if pt then
            pt:destroy()
        end
        pt = TimerList[pid]:add()
        pt.tag = 'blif'
        pt.target = source
        pt.timer:callDelayed(1., BorrowedLifeAutocast, pt)
    end

    --bloodlustoff
    if id == 852103 then --borrowed life
        TimerList[pid]:stopAllTimers('blif')
    end

    --mana shield = 852589

    --warrior parry
    if id == 852589 and GetUnitAbilityLevel(source, PARRY.id) > 0 then
        UnitDisableAbility(source, PARRY.id, true)
        UnitDisableAbility(source, PARRY.id, false)
        BlzStartUnitAbilityCooldown(source, PARRY.id, 4.)
        lastCast[pid] = PARRY.id

        pt = TimerList[pid]:get(ADAPTIVESTRIKE.id)

        if limitBreak[pid] & 0x10 and not pt then
            ADAPTIVESTRIKE.effect(source, x, y)
        else
            UnitDisableAbility(source, ADAPTIVESTRIKE.id, false)
            BlzStartUnitAbilityCooldown(source, ADAPTIVESTRIKE.id, TimerGetRemaining(pt.timer))
        end

        if BlzBitAnd(limitBreak[pid], 0x1) > 0 then
            ParryBuff:add(source, source):duration(1.)
        else
            ParryBuff:add(source, source):duration(0.5)
        end
    end

    --assassin blade spin
    if id == 852589 and GetUnitAbilityLevel(source, BLADESPIN.id) > 0 then

        if GetUnitState(source, UNIT_STATE_MANA) >= BlzGetUnitMaxMana(source) * 0.05 then
            SetUnitState(source, UNIT_STATE_MANA, GetUnitState(source, UNIT_STATE_MANA) - BlzGetUnitMaxMana(source) * 0.05)

            UnitRemoveAbility(source, BLADESPIN.id)
            UnitDisableAbility(source, BLADESPINPASSIVE.id, false)
            BLADESPIN.spin(source, true)
        else
            UnitRemoveAbility(source, BLADESPIN.id)
            UnitAddAbility(source, BLADESPIN.id)
        end
    end

    --immolation = 852177

    --phoenix ranger multi-shot
    if GetUnitTypeId(source) == HERO_PHOENIX_RANGER and isteleporting[pid] == false then
        if id == 852177 then
            SetPlayerAbilityAvailable(p, prMulti[IMinBJ(4, R2I(hl / 50.))], true)
            MultiShot[pid] = true
        elseif id == 852178 then
            SetPlayerAbilityAvailable(p, prMulti[0], false)
            SetPlayerAbilityAvailable(p, prMulti[1], false)
            SetPlayerAbilityAvailable(p, prMulti[2], false)
            SetPlayerAbilityAvailable(p, prMulti[3], false)
            SetPlayerAbilityAvailable(p, prMulti[4], false)
            MultiShot[pid] = false
        end
    end

    --bard inspire
    if id == 852178 and GetUnitAbilityLevel(source, INSPIRE.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
        InspireActive[pid] = false
        local b = InspireBuff:get(source, source)
        if b then b:dispel() end
    end

    --bloodzerker rampage
    if id == 852178 and GetUnitAbilityLevel(source, RAMPAGE.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
        local b = RampageBuff:get(source, source)
        if b then DEBUGMSG("Yeah") b:dispel() end
    end

    --thunderblade overload
    if id == 852178 and GetUnitAbilityLevel(source, OVERLOAD.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
        local b = OverloadBuff:get(source, source)
        if b then b:dispel() end
    end

    --oblivion guard magnetic stance
    if id == 852178 and GetUnitAbilityLevel(source, MAGNETICSTANCE.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
        local b = MagneticStanceBuff:get(source, source)
        if b then b:dispel() end
    end

    --assassin phantomslash
    if id == 852177 and GetUnitAbilityLevel(source, PHANTOMSLASH.id) > 0 and not IsUnitStunned(source) then
        if MouseX[pid] ~= 0 and MouseY[pid] ~= 0 and PhantomSlashing[pid] == false then
            local spell = PHANTOMSLASH:create() ---@type PHANTOMSLASH
            spell:update(pid)
            spell.caster = source
            spell.x = x
            spell.y = y

            spell:onCast()
        end
    end

    --vampire blood mist
    if id == 852177 and GetUnitAbilityLevel(source, BLOODMIST.id) > 0 then
        BloodMistBuff:add(source, source):duration(99999.)
    elseif id == 852178 and GetUnitAbilityLevel(source, BLOODMIST.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
        local b = BloodMistBuff:get(source, source)
        if b then b:dispel() end
    end

    --backpack ai
    if source == Backpack[pid] and id ~= 851972 and id ~= 851993 then --not stopping or holding position
        bpmoving[pid] = true
        pt = TimerList[pid]:get('bkpk', source, nil)

        if not pt then
            pt = TimerList[pid]:add()
            pt.dur = 4.
            pt.tag = 'bkpk'
            pt.source = source

            TimerQueue:callDelayed(1., MoveExpire, pt)
        else
            pt.dur = 4.
        end
    end

    --unit limits
    if id == FourCC('h01P') or id == FourCC('h03Y') or id == FourCC('h04B') or id == FourCC('n09E') or id == FourCC('n00Q') or id == FourCC('n023') or id == FourCC('n09F') or id == FourCC('h010') or id == FourCC('h04U') or id == FourCC('h053') then --worker
        if workerCount[pid] < 5 or (workerCount[pid] < 15 and id == FourCC('h053')) or (workerCount[pid] < 30 and id == FourCC('n00Q')) then
            workerCount[pid] = workerCount[pid] + 1
        else
            SetPlayerTechResearched(p, FourCC('R013'), 0)
        end
    elseif id == FourCC('e00J') or id == FourCC('e000') or id == FourCC('e00H') or id == FourCC('e00K') or id == FourCC('e006') or id == FourCC('e00I') or id == FourCC('e00T') or id == FourCC('e00Y') then --small lumber
        if smallwispCount[pid] < 1 or (smallwispCount[pid] < 6 and id ~= FourCC('e00I') and id ~= FourCC('e00T') and id ~= FourCC('e00Y')) or (smallwispCount[pid] < 12 and id ~= FourCC('e006') and id ~= FourCC('e00I') and id ~= FourCC('e00T') and id ~= FourCC('e00Y')) then
            smallwispCount[pid] = smallwispCount[pid] + 1
        else
            SetPlayerTechResearched(p, FourCC('R014'), 0)
        end
    elseif id == FourCC('e00Z') or id == FourCC('e00R') or id == FourCC('e00Q') or id == FourCC('e01L') or id == FourCC('e01E') or id == FourCC('e010') then --large lumber
        if largewispCount[pid] < 1 or (largewispCount[pid] < 2 and id ~= FourCC('e010')) or (largewispCount[pid] < 3 and id ~= FourCC('e00R') and id ~= FourCC('e010')) or (largewispCount[pid] < 6 and id ~= FourCC('e00R') and id ~= FourCC('e01E') and id ~= FourCC('e010')) then
            largewispCount[pid] = largewispCount[pid] + 1
        else
            SetPlayerTechResearched(p, FourCC('R015'), 0)
        end
    elseif id == FourCC('h00S') or id == FourCC('h017') or id == FourCC('h00I') or id == FourCC('h016') or id == FourCC('nwlg') or id == FourCC('h004') or id == FourCC('h04V') or id == FourCC('o02P') then --warrior
        if warriorCount[pid] < 6 or (warriorCount[pid] < 12 and id ~= FourCC('nwlg') and id ~= FourCC('h04V')) then
            warriorCount[pid] = warriorCount[pid] + 1
            ExperienceControl(pid)
        else
            SetPlayerTechResearched(p, FourCC('R016'), 0)
        end
    elseif id == FourCC('n00A') or id == FourCC('n014') or id == FourCC('n009') or id == FourCC('n00D') or id == FourCC('n002') or id == FourCC('h005') or id == FourCC('o02Q') then --ranger
        if rangerCount[pid] < 6 or (rangerCount[pid] < 12 and id ~= FourCC('n002')) then
            rangerCount[pid] = rangerCount[pid] + 1
            ExperienceControl(pid)
        else
            SetPlayerTechResearched(p, FourCC('R017'), 0)
        end
    end

    --determine moving
    if GetOrderPointX() ~= 0 and GetOrderPointY() ~= 0 and source == Hero[pid] and (GetUnitCurrentOrder(Hero[pid]) == OrderId("move") or GetUnitCurrentOrder(Hero[pid]) == OrderId("smart") or GetUnitCurrentOrder(Hero[pid]) == OrderId("attack")) then
        clickedpointX[pid] = GetOrderPointX()
        clickedpointY[pid] = GetOrderPointY()
        Moving[pid] = true
    end

    if GetOrderPointX() == 0 and GetOrderPointY() == 0 and source == Hero[pid] then
        clickedpointX[pid] = GetUnitX(Hero[pid])
        clickedpointY[pid] = GetUnitY(Hero[pid])
        Moving[pid] = false
    end

    if LIBRARY_dev then
        if nocd[pid] then --No Cooldowns
            TimerQueue:callDelayed(0.1, ResetCD, pid)
        end

        if nocost[pid] then --No Manacost
            SetUnitState(Hero[pid], UNIT_STATE_MANA, GetUnitState(Hero[pid], UNIT_STATE_MAX_MANA))
        end
    end

    DestroyGroup(ug)
end

function OnTargetOrder()
    local source      = GetTriggerUnit() ---@type unit 
    local target      = GetOrderTargetUnit() ---@type unit 
    local id         = GetIssuedOrderId() ---@type integer 
    local pid         = GetPlayerId(GetOwningPlayer(source)) + 1 ---@type integer 
    local itm      = GetOrderTargetItem() ---@type item 
    local i         = GetItemSlot(itm, source) ---@type integer 
    local i2         = 0 ---@type integer 

    if LIBRARY_dev then
        if EXTRA_DEBUG then
            DEBUGMSG(OrderId2String(id))
            DEBUGMSG((id))
        end
    end

    if id >= 852002 and id <= 852007 and i >= 0 then --move item slot
        if GetLocalPlayer() == Player(pid - 1) then
            BlzFrameSetTexture(INVENTORYBACKDROP[i], SPRITE_RARITY[Item[UnitItemInSlot(source, id - 852002)].level], 0, true)
            BlzFrameSetTexture(INVENTORYBACKDROP[id - 852002], SPRITE_RARITY[Item[itm].level], 0, true)
        end

        if id - 852002 ~= i then --order slot not equal current slot
            if GetUnitTypeId(source) == BACKPACK then
                i = i + 6
                i2 = i2 + 6
            end

            Profile[pid].hero.items[id - 852002 + i2] = Item[itm] --move slot = current item

            if Item[UnitItemInSlot(source, id - 852002)] then
                Profile[pid].hero.items[i] = Item[UnitItemInSlot(source, id - 852002)] --item that was swapped = previous item slot
            else
                Profile[pid].hero.items[i] = nil
            end
        end
    end

    --hero targets enemy
    if source == Hero[pid] and IsUnitEnemy(target, Player(pid - 1)) then
        LAST_TARGET[pid] = target
        LAST_TARGET_X[pid] = GetUnitX(target)
        LAST_TARGET_Y[pid] = GetUnitY(target)

        clickedpointX[pid] = GetUnitX(target)
        clickedpointY[pid] = GetUnitY(target)

        --gyro
        if UnitAlive(helicopter[pid]) and (OrderId2String(id) == "smart" or OrderId2String(id) == "attack") then
            GroupEnumUnitsInRangeEx(pid, helitargets[pid], GetUnitX(target), GetUnitY(target), 700., Condition(FilterEnemy))
            GroupEnumUnitsInRangeEx(pid, helitargets[pid], GetUnitX(source), GetUnitY(source), 1200., Condition(FilterEnemy))
            SetUnitFacing(helicopter[pid], bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(helicopter[pid]), GetUnitX(target) - GetUnitX(helicopter[pid])))
        end
    end
end

    local ordertarget = CreateTrigger() ---@type trigger
    local u = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(pointOrder, u.player, EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, nil)
        TriggerRegisterPlayerUnitEvent(ordertarget, u.player, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, nil)
        TriggerRegisterPlayerUnitEvent(pointOrder, u.player, EVENT_PLAYER_UNIT_ISSUED_ORDER, nil)
        --call TriggerRegisterPlayerUnitEvent(backpackorder, u.player, EVENT_PLAYER_UNIT_ISSUED_UNIT_ORDER, null)
        u = u.next
    end

    TriggerAddAction(pointOrder, OnOrder)
    TriggerAddAction(ordertarget, OnTargetOrder)

end)

if Debug then Debug.endFile() end
