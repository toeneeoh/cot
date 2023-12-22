library Attacked requires Functions, Spells

globals
    boolean pallyENRAGE = false
endglobals

function OnAttack takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local unit u2 = GetAttacker()
    local integer tuid = GetUnitTypeId(u2)
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(u2)) + 1
    local integer rand
    local real atk
    local real dur
    local real x = GetUnitX(u)
    local real y = GetUnitY(u)
    local integer i = 0
    local group ug
    local unit target
    local PlayerTimer pt

    if u2 == Hero[tpid] and Moving[tpid] then //movement system
        set Moving[tpid] = false
    endif
    
    if (pid <= PLAYER_CAP and tpid <= PLAYER_CAP and pid != tpid and IsUnitAlly(u2, GetOwningPlayer(u))) then //prevent friendly fire
		call IssueImmediateOrder(u2, "stop")
	endif

    if tuid == HERO_ASSASSIN then //blade spin
        if BladeSpinCount[tpid] >= BladeSpinFormula(tpid) - 1 then //8 7 6 5 per 100 levels
            set BladeSpinCount[tpid] = 0
            call BladeSpin(tpid, 8)
        endif
    endif

    if tuid == HERO_SAVIOR and GetUnitAbilityLevel(u2, HOLYBASH.id) > 0 and saviorBashCount[tpid] == 9 then
        set pt = TimerList[pid].get(u2, null, 'Ltsl')

        if pt != 0 then
            set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\Judgement NoHive.mdx", pt.x, pt.y)
            call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 1.8)
        else
            set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\Judgement NoHive.mdx", x, y)
            call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 0.8)
        endif

        set saviorBashCount[tpid] = 10
        call BlzSetSpecialEffectTimeScale(bj_lastCreatedEffect, 1.5)
        call BlzSetSpecialEffectTime(bj_lastCreatedEffect, 0.7)
        call DestroyEffectTimed(bj_lastCreatedEffect, 1.5)
    endif
    
    if GetUnitTypeId(u2) == SUMMON_DESTROYER then //dark summoner destroyer
        set pt = TimerList[tpid].get(null, u, 'datk')

        if pt == 0 then
            call TimerList[tpid].stopAllTimersWithTag('datk')
            set pt = TimerList[tpid].addTimer(tpid)
            set pt.x = GetUnitX(u2)
            set pt.y = GetUnitY(u2)
            set pt.target = u
            set pt.tag = 'datk'
            call SetHeroAgi(u2, 0, true)
            if destroyerDevourStacks[tpid] == 5 then
                call SetHeroAgi(u2, 400, true)
            elseif destroyerDevourStacks[tpid] >= 3 then
                call SetHeroAgi(u2, 200, true)
            endif
            call TimerStart(pt.timer, 1., true, function DestroyerAttackSpeed)
        endif
    endif

    set u = null
    set u2 = null

    return false
endfunction

//===========================================================================
function AttackedInit takes nothing returns nothing
    local trigger attacked = CreateTrigger()
    local User u = User.first

	loop
		exitwhen u == User.NULL
		call TriggerRegisterPlayerUnitEvent(attacked, u.toPlayer(), EVENT_PLAYER_UNIT_ATTACKED, null)
		set u = u.next
	endloop
    
    call TriggerRegisterPlayerUnitEvent(attacked, Player(PLAYER_TOWN), EVENT_PLAYER_UNIT_ATTACKED, null)
    call TriggerRegisterPlayerUnitEvent(attacked, pboss, EVENT_PLAYER_UNIT_ATTACKED, null)
    call TriggerRegisterPlayerUnitEvent(attacked, pfoe, EVENT_PLAYER_UNIT_ATTACKED, null)
    
	call TriggerAddCondition(attacked, function OnAttack)

    set attacked = null
endfunction

endlibrary
