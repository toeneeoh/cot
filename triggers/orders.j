library Order requires Functions, TimerUtils, Commands, Spells

globals
    trigger pointOrder = CreateTrigger()
    boolean array bpmoving
    timer array bpmove
    real array metamorphosis
    unit array LAST_TARGET
    real array LAST_TARGET_X
    real array LAST_TARGET_Y
    boolean array Moving
endglobals

function OnOrder takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p) + 1
    local integer hl = GetHeroLevel(u)
    local integer id = GetIssuedOrderId()
    local real x = GetUnitX(u)
    local real y = GetUnitY(u)
    local real hp = 0
    local integer i = 0
    local group ug
    local PlayerTimer pt
    local User U = User.first

    static if LIBRARY_dev then
        if EXTRA_DEBUG then
            call BJDebugMsg(OrderId2String(id))
            call BJDebugMsg(I2S(id))
        endif
    endif

    if id == 851971 then //smart, after 3 seconds drop aggro from all nearby enemies and redirect to allies
        set pt = TimerList[pid].getTimerWithTargetTag(u, 'aggr')
        if pt == 0 then
            set pt = TimerList[pid].addTimer(pid)
            set pt.target = u
            set pt.tag = 'aggr' 
            call TimerStart(pt.getTimer(), 3., true, function RunDropAggro)
        endif
    endif

    if id == 852056 then //undefend
        //flush threat level and acquired target
        call FlushChildHashtable(ThreatHash, GetUnitId(u))
        //if unit is removed then deindex
        if GetUnitAbilityLevel(u, DETECT_LEAVE_ABILITY) == 0 then
            call UnitDeIndex(u)
        endif
    endif

    if id == 852150 then //faeriefireon devour
        set pt = TimerList[pid].getTimerWithTargetTag(u, 'blif')
        if pt != 0 then
            call TimerList[pid].removePlayerTimer(pt)
        endif
        set pt = TimerList[pid].addTimer(pid)
        set pt.tag = 'dvou'
        set pt.target = u
        call TimerStart(pt.getTimer(), 1., true, function DevourAutocast)
    endif

    if id == 852151 then //faeriefireoff devour
        call TimerList[pid].stopAllTimersWithTag('dvou')
    endif
    
    if id == 852102 then //bloodluston borrowed life
        set pt = TimerList[pid].getTimerWithTargetTag(u, 'dvou')
        if pt != 0 then
            call TimerList[pid].removePlayerTimer(pt)
        endif
        set pt = TimerList[pid].addTimer(pid)
        set pt.tag = 'blif'
        set pt.target = u
        call TimerStart(pt.getTimer(), 1., true, function BorrowedLifeAutocast)
    endif

    if id == 852103 then //bloodlustoff borrowed life
        call TimerList[pid].stopAllTimersWithTag('blif')
    endif

    //unit limits
    if id == 'h01P' or id == 'h03Y' or id == 'h04B' or id == 'n09E' or id == 'n00Q' or id == 'n023' or id == 'n09F' or id == 'h010' or id == 'h04U' or id == 'h053' then //worker
        if workerCount[pid] < 5 or (workerCount[pid] < 15 and id == 'h053') or (workerCount[pid] < 30 and id == 'n00Q') then
            set workerCount[pid] = workerCount[pid] + 1
        else
            call SetPlayerTechResearched(p, 'R013', 0)
        endif
    elseif id == 'e00J' or id == 'e000' or id == 'e00H' or id == 'e00K' or id == 'e006' or id == 'e00I' or id == 'e00T' or id == 'e00Y' then //small lumber
        if smallwispCount[pid] < 1 or (smallwispCount[pid] < 6 and id != 'e00I' and id != 'e00T' and id != 'e00Y') or (smallwispCount[pid] < 12 and id != 'e006' and id != 'e00I' and id != 'e00T' and id != 'e00Y') then
            set smallwispCount[pid] = smallwispCount[pid] + 1
        else
            call SetPlayerTechResearched(p, 'R014', 0)
        endif
    elseif id == 'e00Z' or id == 'e00R' or id == 'e00Q' or id == 'e01L' or id == 'e01E' or id == 'e010' then //large lumber
        if largewispCount[pid] < 1 or (largewispCount[pid] < 2 and id != 'e010') or (largewispCount[pid] < 3 and id != 'e00R' and id != 'e010') or (largewispCount[pid] < 6 and id != 'e00R' and id != 'e01E' and id != 'e010') then
            set largewispCount[pid] = largewispCount[pid] + 1
        else
            call SetPlayerTechResearched(p, 'R015', 0)
        endif
    elseif id == 'h00S' or id == 'h017' or id == 'h00I' or id == 'h016' or id == 'nwlg' or id == 'h004' or id == 'h04V' or id == 'o02P' then //warrior
        if warriorCount[pid] < 6 or (warriorCount[pid] < 12 and id != 'nwlg' and id != 'h04V') then
            set warriorCount[pid] = warriorCount[pid] + 1
        else
            call SetPlayerTechResearched(p, 'R016', 0)
        endif
    elseif id == 'n00A' or id == 'n014' or id == 'n009' or id == 'n00D' or id == 'n002' or id == 'h005' or id == 'o02Q' then //ranger
        if rangerCount[pid] < 6 or (rangerCount[pid] < 12 and id != 'n002') then
            set rangerCount[pid] = rangerCount[pid] + 1
        else
            call SetPlayerTechResearched(p, 'R017', 0)
        endif
    endif
    
    call ExperienceControl(pid)
    
    //phoenix ranger multi-shot
    if GetUnitTypeId(u) == HERO_PHOENIX_RANGER and isteleporting[pid] == false then
        if id == OrderId("defend") then
            if hl >= 200 then
                call SetPlayerAbilityAvailable(p, prMulti[5],true)
            elseif hl >= 150 then
                call SetPlayerAbilityAvailable(p, prMulti[4],true)
            elseif hl >= 100 then
                call SetPlayerAbilityAvailable(p, prMulti[3],true)
            elseif hl >= 50 then
                call SetPlayerAbilityAvailable(p, prMulti[2],true)
            else
                call SetPlayerAbilityAvailable(p, prMulti[1],true)
            endif
            set MultiShot[pid] = true
        elseif id == OrderId("undefend") then
            call SetPlayerAbilityAvailable(p, prMulti[1],false)
            call SetPlayerAbilityAvailable(p, prMulti[2],false)
            call SetPlayerAbilityAvailable(p, prMulti[3],false)
            call SetPlayerAbilityAvailable(p, prMulti[4],false)
            call SetPlayerAbilityAvailable(p, prMulti[5],false)
            set MultiShot[pid] = false
        endif
    endif

    //assassin blade spin
    if id == 852589 and GetUnitAbilityLevel(u, 'A0AS') > 0 then //mana shield
        if GetUnitState(u, UNIT_STATE_MANA) >= BlzGetUnitMaxMana(u) * 0.05 then
            call SetUnitState(u, UNIT_STATE_MANA, GetUnitState(u, UNIT_STATE_MANA) - BlzGetUnitMaxMana(u) * 0.05)
            call UnitRemoveAbility(u, 'A0AS')
            call UnitDisableAbility(u, 'A0AQ', false)
            call BladeSpin(pid, 4)
        else
            call UnitRemoveAbility(u, 'A0AS')
            call UnitAddAbility(u, 'A0AS')
        endif
    endif

    //bard inspire
    if id == 852177 and GetUnitAbilityLevel(u, 'A09Y') > 0 then
        set InspireActive[pid] = true
    elseif id == 852178 and GetUnitAbilityLevel(u, 'A09Y') > 0 and IsUnitPaused(u) == false and IsUnitLoaded(u) == false then
        set InspireActive[pid] = false
    endif

    //bloodzerker rampage
    if id == 852177 and GetUnitAbilityLevel(u, 'A0GZ') > 0 then
        set rampageActive[pid] = true
        set rampageEffect[pid] = AddSpecialEffectTarget("war3mapImported\\Windwalk Blood.mdx", u, "origin")
        call TimerStart(NewTimerEx(pid), 1, true, function RampageLoop)
    elseif id == 852178 and GetUnitAbilityLevel(u, 'A0GZ') > 0 and IsUnitPaused(u) == false and IsUnitLoaded(u) == false then
        set rampageActive[pid] = false
        call DestroyEffect(rampageEffect[pid])
    endif

    //thunderblade overload
    if id == 852177 and GetUnitAbilityLevel(u, 'A096') > 0 then
        call DestroyEffect(overloadEffect[pid])
        set overloadActive[pid] = true
        set overloadEffect[pid] = AddSpecialEffectTarget("war3mapImported\\Windwalk Blue Soul.mdx", u, "origin")
        call TimerStart(NewTimerEx(pid), 1, true, function OverloadLoop)
    elseif id == 852178 and GetUnitAbilityLevel(u, 'A096') > 0 and IsUnitPaused(u) == false and IsUnitLoaded(u) == false then
        set overloadActive[pid] = false
        call DestroyEffect(overloadEffect[pid])
    endif

    //assassin phantomslash
    if id == 852177 and GetUnitAbilityLevel(u, 'A07Y') > 0 and GetUnitAbilityLevel(u, 'BPSE') == 0 then
        if MouseX[pid] != 0 and MouseY[pid] != 0 then
            call BlzUnitDisableAbility(u, 'A07Y', true, false)

            call SetUnitState(u, UNIT_STATE_MANA, GetUnitState(u, UNIT_STATE_MANA) - BlzGetUnitMaxMana(u) * (.1 - 0.025 * GetUnitAbilityLevel(u, 'A07Y')))
            set PhantomSlashing[pid] = true
            set TotalEvasion[pid] = 100
            set pt = TimerList[pid].addTimer(pid)
            set pt.dur = SquareRoot(Pow(MouseX[pid] - GetUnitX(u), 2) + Pow(MouseY[pid] - GetUnitY(u), 2))
            set pt.speed = 60.
            set pt.dmg = GetHeroAgi(u, true) * 1.5 * BOOST(pid)
            set pt.angle = Atan2(MouseY[pid] - GetUnitY(u), MouseX[pid] - GetUnitX(u))
            set pt.target = u
            set pt.ug = CreateGroup()
            if pt.dur > 750. then
                set pt.dur = 750.
            endif

            call TimerStart(pt.getTimer(), 0.03, true, function PhantomSlashPeriodic)

            call SetUnitTimeScale(u, 1.5)
            call SetUnitAnimationByIndex(u, 5)
            call BlzSetUnitFacingEx(u, pt.angle * bj_RADTODEG)

            set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\ShadowWarrior.mdl", GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))
            call BlzSetSpecialEffectColorByPlayer(bj_lastCreatedEffect, p)
            call BlzSetSpecialEffectYaw(bj_lastCreatedEffect, pt.angle)
            call FadeSFX(bj_lastCreatedEffect, true, true)
            call BlzPlaySpecialEffect(bj_lastCreatedEffect, ANIM_TYPE_ATTACK)
        endif
    endif
    
    //vampire blood mist
    if id == 852177 and GetUnitAbilityLevel(u, 'A093') > 0 then
        set bloodMistActive[pid] = true
        set bloodMistEffect[pid] = AddSpecialEffectTarget("war3mapImported\\Chumpool.mdx", u, "origin")
    elseif id == 852178 and GetUnitAbilityLevel(u, 'A093') > 0 and IsUnitPaused(u) == false and IsUnitLoaded(u) == false then
        set bloodMistActive[pid] = false
        call UnitRemoveAbility(Hero[pid], 'B02Q')
        if bloodMistEffect[pid] != null then
            call DestroyEffect(bloodMistEffect[pid])
            set bloodMistEffect[pid] = null
        endif
    endif

    //steed charge
    if id == 852180 and HeroID[pid] == HERO_ROYAL_GUARDIAN then
        set pt = TimerList[pid].addTimer(pid)
        set pt.x = SteedChargeX[pid]
        set pt.y = SteedChargeY[pid]
        set pt.dur = 1.
        set pt.angle = Atan2(pt.y - GetUnitY(Hero[pid]), pt.x - GetUnitX(Hero[pid]))

        call TimerStart(pt.getTimer(), 0.03, true, function SteedCharge)
    endif
    
    //backpack ai
    if u == Backpack[pid] and id != OrderId("stop") and id != OrderId("move") then
        set bpmoving[pid] = true
        call PauseTimer(bpmove[pid])
        call TimerStart(bpmove[pid], 4., true, function MoveExpire)
    endif
    
    //determine moving
    if GetOrderPointX() != 0 and GetOrderPointY() != 0 and u == Hero[pid] and (GetUnitCurrentOrder(Hero[pid]) == OrderId("move") or GetUnitCurrentOrder(Hero[pid]) == OrderId("smart") or GetUnitCurrentOrder(Hero[pid]) == OrderId("attack")) then
        set clickedpointX[pid] = GetOrderPointX()
        set clickedpointY[pid] = GetOrderPointY()
        set Moving[pid] = true
    endif
    
    if GetOrderPointX() == 0 and GetOrderPointY() == 0 and u == Hero[pid] then
        set clickedpointX[pid] = GetUnitX(Hero[pid])
        set clickedpointY[pid] = GetUnitY(Hero[pid])
        set Moving[pid] = false
    endif
    
    set u = null
    set p = null
endfunction

function OnTargetOrder takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local unit u2 = GetOrderTargetUnit()
    local integer id = GetIssuedOrderId()
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local integer i = 0
    local item itm = GetOrderTargetItem()

    static if LIBRARY_dev then
        //call DEBUGMSG(OrderId2String(id))
    endif

    //hero targets enemy
    if u == Hero[pid] and IsUnitEnemy(u2, Player(pid - 1)) then
        set LAST_TARGET[pid] = u2
        set LAST_TARGET_X[pid] = GetUnitX(u2)
        set LAST_TARGET_Y[pid] = GetUnitY(u2)

        set clickedpointX[pid] = GetUnitX(u2)
        set clickedpointY[pid] = GetUnitY(u2)

        //gyro
        if GetWidgetLife(helicopter[pid]) >= 0.406 and (OrderId2String(id) == "smart" or OrderId2String(id) == "attack") then
            call GroupEnumUnitsInRangeEx(pid, helitargets[pid], GetUnitX(u2), GetUnitY(u2), 700., Condition(function FilterEnemy))
            call GroupEnumUnitsInRangeEx(pid, helitargets[pid], GetUnitX(u), GetUnitY(u), 1200., Condition(function FilterEnemy))
            call SetUnitFacing(helicopter[pid], bj_RADTODEG * Atan2(GetUnitY(u2) - GetUnitY(helicopter[pid]), GetUnitX(u2) - GetUnitX(helicopter[pid])))
        endif
    endif
    
    set u = null
    set u2 = null
endfunction

//===========================================================================
function OrdersInit takes nothing returns nothing
    local trigger ordertarget = CreateTrigger()
    local User u = User.first

    loop
        exitwhen u == User.NULL
        set bpmove[GetPlayerId(u.toPlayer()) + 1] = CreateTimer()
        call TriggerRegisterPlayerUnitEvent(pointOrder, u.toPlayer(), EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, null)
        call TriggerRegisterPlayerUnitEvent(ordertarget, u.toPlayer(), EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, null)
        call TriggerRegisterPlayerUnitEvent(pointOrder, u.toPlayer(), EVENT_PLAYER_UNIT_ISSUED_ORDER, null)
        //call TriggerRegisterPlayerUnitEvent(backpackorder, u.toPlayer(), EVENT_PLAYER_UNIT_ISSUED_UNIT_ORDER, null)
        set u = u.next
    endloop

    call TriggerAddAction(pointOrder, function OnOrder)
    call TriggerAddAction(ordertarget, function OnTargetOrder)
    
    set ordertarget = null
endfunction

endlibrary
