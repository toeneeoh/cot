library Summon requires Functions

    globals
        group SummonGroup = CreateGroup()

        unit array helicopter
        real array heliangle
        group array helitargets
        real array heliboost
        texttag array helitag
        unit array destroyer
        unit array meatgolem
        unit array hounds
        integer array improvementArmorBonus
    endglobals
    
    function HelicopterExpire takes nothing returns nothing
        local integer pid = ReleaseTimer(GetExpiredTimer())
        
        call SoundHandler("Units\\Human\\Gyrocopter\\GyrocopterPissed6.flac", true, null, helicopter[pid])
        call IssuePointOrder(helicopter[pid], "move", GetUnitX(Hero[pid]) + 1000. * Cos(bj_DEGTORAD * GetUnitFacing(Hero[pid])), GetUnitY(Hero[pid]) + 1000. * Sin(bj_DEGTORAD * GetUnitFacing(Hero[pid])))
        call RemoveUnitTimed(helicopter[pid], 2.)
        call Fade(helicopter[pid], 2., true)
        
        set helicopter[pid] = null
    endfunction
    
    function HelicopterDrop takes nothing returns nothing
        local integer pid = ReleaseTimer(GetExpiredTimer())
        
        call SetUnitFlyHeight(helicopter[pid], 300., 500.)
    endfunction

    function onSummon takes nothing returns nothing
        local unit caster = GetSummoningUnit()
        local unit summon = GetSummonedUnit()
        local integer pid = GetPlayerId(GetOwningPlayer(caster)) + 1
        local integer uid = GetUnitTypeId(summon)
        local group ug = CreateGroup()
        local Spell spell
            
        //Elite Marksman Assault Helicopter
        if uid == 'h03W' or uid == 'h03V' or uid == 'h03H' then
            set spell = ASSAULTHELICOPTER.get(pid)

            call GroupClear(helitargets[pid])
            set heliboost[pid] = BOOST[pid]
            set helicopter[pid] = summon
            call SetUnitFlyHeight(helicopter[pid], 1100., 30000.)
            call UnitAddIndicator(helicopter[pid], 255, 255, 255, 255)
            call TimerStart(NewTimerEx(pid), 0.03, false, function HelicopterDrop)
            set helitag[pid] = CreateTextTag()
            call SetTextTagText(helitag[pid], RealToString(heliboost[pid] * 100) + "%", 0.024)
            call SetTextTagColor(helitag[pid], 255, R2I(270 - heliboost[pid] * 150), R2I(270 - heliboost[pid] * 150), 255)
            call DestroyTextTagTimed(helitag[pid], 28.5)
            call TimerStart(NewTimerEx(pid), spell.values[1] * LBOOST[pid], false, function HelicopterExpire)
            call SoundHandler("Units\\Human\\Gyrocopter\\GyrocopterWhat" + I2S(GetRandomInt(1,5)) + ".flac", true, null, helicopter[pid])
        else
            call DestroyGroup(ug)

            set ug = null
            set caster = null
            set summon = null
            return
        endif

        call GroupAddUnit(SummonGroup, summon)
        
        if IsUnitType(summon, UNIT_TYPE_HERO) then
            call SetHeroLevelBJ(summon, GetHeroLevel(Hero[pid]), false)
            call SuspendHeroXP(summon, true)
        endif
        
        /*/*/*
        //////
        //////
        //////
        */*/*/
        
        call DestroyGroup(ug)
        call spell.destroy()
        
        set ug = null
        set caster = null
        set summon = null
    endfunction

    function SummonInit takes nothing returns nothing
		local trigger summon = CreateTrigger()
        local User u = User.first
        
        loop
            exitwhen u == User.NULL
            call TriggerRegisterPlayerUnitEvent(summon, u.toPlayer(), EVENT_PLAYER_UNIT_SUMMON, null)
            set helitargets[GetPlayerId(u.toPlayer()) + 1] = CreateGroup()
            set u = u.next
        endloop
        
        call TriggerAddAction(summon, function onSummon)
        
        set summon = null
	endfunction

endlibrary
