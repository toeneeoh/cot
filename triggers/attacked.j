library Attacked requires Functions, Spells

globals
    boolean pallyENRAGE = false
endglobals

function onAttack takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local unit u2 = GetAttacker()
    local integer tuid = GetUnitTypeId(u2)
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(u2)) + 1
    local integer rand
    local real atk
    local real dur
    local real boost
    local location loc
    local integer i = 0
    local group ug
    local unit target
    
    if u2 == Hero[tpid] and Moving[tpid] then //movement system
        set Moving[tpid] = false
    endif
    
    if (pid < PLAYER_CAP and tpid < PLAYER_CAP and pid != tpid and IsUnitAlly(u2, GetOwningPlayer(u))) then //prevent friendly fire
		call IssueImmediateOrder(u2, "stop")
	endif

    if tuid == HERO_ASSASSIN then //blade spin
        if BladeSpinCount[tpid] >= BladeSpinFormula(tpid) - 1 then //8 7 6 5 per 100 levels
            set BladeSpinCount[tpid] = 0
            call BladeSpin(tpid, 8)
        endif
    endif
    
    if GetUnitTypeId(u2) == SUMMON_DESTROYER and u != destroyerTarget[tpid] then //dark summoner destroyer
        set destroyerTarget[tpid] = u
        call UnitClearBonus(u2, BONUS_ATTACK_SPEED)
        set destroyerAttackSpeed[tpid] = 0
        call TimerStart(destroyertimer[tpid], 1, true, function DestroyerAttackSpeed)
    endif

    if (GetUnitTypeId(u) == 'O02B' or GetUnitTypeId(u2) == 'O02B') then //Slaughter Spells
        set rand = GetRandomInt(1, 8)
        if HardMode > 0 then
            call SetUnitAbilityLevel(ChaosBoss[BOSS_SLAUGHTER_QUEEN], 'A064', 2)
        else
            call SetUnitAbilityLevel(ChaosBoss[BOSS_SLAUGHTER_QUEEN], 'A064', 1)
        endif
        if GetUnitTypeId(u2) == 'O02B' then
            set u = GetAttacker()
        endif
        if rand == 1 and BlzGetUnitAbilityCooldownRemaining(ChaosBoss[BOSS_SLAUGHTER_QUEEN], 'A064') <= 0 and BossSpellCD[1] == false then
            set BossSpellCD[1] = true
            call DoFloatingTextUnit( "Avatar" , ChaosBoss[BOSS_SLAUGHTER_QUEEN] , 1.75 , 100 , 0 , 12 , 154 , 38 , 158 , 0)
            call TimerStart(NewTimer(), 2, false, function SlaughterAvatar)
        endif
    elseif GetUnitTypeId(u) == 'O02H' then //Dark Soul Spells
        set rand = GetRandomInt(1, 100)
        if BossSpellCD[2] == false then
            if rand < 6 then
                set BossSpellCD[2]=true
                call DoFloatingTextUnit("+ MORTIFYING +" , u , 3 , 70 , 0 , 10 , 255, 255, 255 , 0)
                call TriggerSleepAction(0.5)
                call PauseUnit(u, true)
                call TriggerSleepAction(1.5)
                call BossPlusSpell(u, 1000111,1, "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl")
                call PauseUnit(u, false)
                call TimerStart(NewTimerEx(2), 4.0, false, function BossCD)
            elseif rand < 12 then
                set BossSpellCD[2]=true
                call DoFloatingTextUnit("x TERRIFYING x" , u , 3 , 70 , 0 , 10 , 255, 255, 255 , 0)
                call TriggerSleepAction(0.5)
                call PauseUnit(u, true)
                call TriggerSleepAction(1.5)
                call BossXSpell(u, 1000111,1, "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl")
                call PauseUnit(u, false)
                call TimerStart(NewTimerEx(2), 4.0, false, function BossCD)
            elseif rand < 20 then
                call IssueImmediateOrder(u, "stomp")
            endif
        endif
    elseif GetUnitTypeId(u) == 'O02K' then //Thanatos Spells
        set rand = GetRandomInt(0, 99)

        if GetUnitTypeId(u) == 'O02K' and BossSpellCD[5] == false then
            if rand < 5 and UnitDistance(u, u2) > 250 then
                set BossSpellCD[5] = true
                call DoFloatingTextUnit("Swift Hunt" , u , 1 , 70 , 0 , 10 , 255, 255, 255 , 0)
                call TimerStart(NewTimer(), 1.5, false, function ThanatosSwiftHunt)
                call TimerStart(NewTimerEx(5), 10., false, function BossCD)
            elseif rand < 10 then
                set BossSpellCD[5] = true
                call DoFloatingTextUnit( "Death Beckons" , u , 2 , 70 , 0 , 10 , 255, 255, 255 , 0)
                call BossBlastTaper(u, 1000000, 'A0A4', 750) 
                call TimerStart(NewTimerEx(5), 12., false, function BossCD)
            endif
        endif
    elseif GetUnitTypeId(u) == 'O02M' or GetUnitTypeId(u2) == 'O02M' then //Existence Spells
        set rand= GetRandomInt(0, 99)
        if GetUnitTypeId(u2) == 'O02M' then
            set u = GetAttacker()
        endif
        if rand <5 and BossSpellCD[4]== false then
            set BossSpellCD[4]=true
            call TimerStart(NewTimerEx(4), 5., false, function BossCD)
            call DoFloatingTextUnit( "Devastation" , u , 2 , 70 , 0 , 12 , 255, 40, 40 , 0)
            call BossBlastTaper(u, 1500111,'A0AB', 800)
        elseif rand <10 and BossSpellCD[4]== false then
            set BossSpellCD[4]=true
            call TimerStart(NewTimerEx(4), 5., false, function BossCD)
            call DoFloatingTextUnit("Extermination" , u , 3 , 70 , 0 , 12 , 255, 255, 255 , 0)
            call TriggerSleepAction(1.5)
            call BossXSpell(u, 500111,2, "Abilities\\Spells\\Undead\\ReplenishMana\\ReplenishManaCasterOverhead.mdl")
            call TriggerSleepAction(1)
            call BossPlusSpell(u, 500111,2, "Abilities\\Spells\\Undead\\ReplenishMana\\ReplenishManaCasterOverhead.mdl")
        elseif rand <15 and BossSpellCD[4]== false then
            set BossSpellCD[4]=true
            call TimerStart(NewTimerEx(4), 5., false, function BossCD)
            call DoFloatingTextUnit("Implosion" , u , 3 , 70 , 0 , 12 , 68, 68, 255 , 0)
            call TriggerSleepAction(1)
            call BossInnerRing(u, 1000111,2, 400, "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl")
        elseif rand <20 and BossSpellCD[4]== false then
            set BossSpellCD[4]=true
            call TimerStart(NewTimerEx(4), 5., false, function BossCD)
            call DoFloatingTextUnit("Explosion" , u , 3 , 70 , 0 , 12 , 255, 100, 50 , 0)
            call TriggerSleepAction(1)
            call BossOuterRing(u, 500111,2, 450, 900, "Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl")
        elseif rand <30 and BossSpellCD[6]== false then
            set BossSpellCD[6]=true
            call DoFloatingTextUnit("Protected Existence" , u , 3 , 70 , 0 , 12 , 100, 255, 100 , 0)
            call DestroyEffectTimed(AddSpecialEffectTarget( "war3mapImported\\DemonShieldTarget3A.mdx", u, "origin"), 10.)
            call UnitAddAbility(u,'ACmi')
            call TimerStart(NewTimer(), 10., false, function ExistenceProtectionExpire)
            call TimerStart(NewTimerEx(6), 25., false, function BossCD)
        endif
    elseif GetUnitTypeId(u) == 'O02T' or GetUnitTypeId(u2) == 'O02T' then //Azazoth Spells
        set rand= GetRandomInt(0, 99)
        set loc= GetUnitLoc(ChaosBoss[BOSS_AZAZOTH])
        if udg_Azazoth_Casting_Spell == false then
            if rand<10 and GetUnitLifePercent(ChaosBoss[BOSS_AZAZOTH]) < 50 and BossSpellCD[3] == false then
                set BossSpellCD[3]=true
                set udg_Azazoth_Casting_Spell=true
                call PauseUnit(ChaosBoss[BOSS_AZAZOTH],true)
                call SetUnitAnimation(ChaosBoss[BOSS_AZAZOTH], "spell slam")
                call TriggerSleepAction(0.27)
                call DoFloatingTextUnit("Astral Restoration" , ChaosBoss[BOSS_AZAZOTH] , 2 , 70 , 0 , 11 , 200 , 200 , 77 , 0)
                call DestroyEffect(AddSpecialEffectLoc("Abilities\\Spells\\Items\\AIil\\AIilTarget.mdl",loc))
                call DestroyEffect(AddSpecialEffectLoc("Abilities\\Spells\\Items\\AIre\\AIreTarget.mdl",loc))
                call DestroyEffect(AddSpecialEffectLoc("Abilities\\Spells\\Items\\AIvi\\AIviTarget.mdl",loc))
                call DestroyEffect(AddSpecialEffectLoc("Abilities\\Spells\\Orc\\HealingWave\\HealingWaveTarget.mdl",loc))
                call TriggerSleepAction(0.27)
                call SetUnitLifePercentBJ(ChaosBoss[BOSS_AZAZOTH], GetUnitLifePercent(ChaosBoss[BOSS_AZAZOTH]) + 10 )
                call ResetAza()
                call TimerStart(NewTimerEx(3), 60., false, function BossCD)
            elseif rand <15 and BossSpellCD[7] == false then
                set BossSpellCD[7]=true
                if GetUnitLifePercent(ChaosBoss[BOSS_AZAZOTH]) > 75 then
                    call AstralDevastation(ChaosBoss[BOSS_AZAZOTH], GetRandomReal(6,7), HMscale(4000000), GetUnitFacing(ChaosBoss[BOSS_AZAZOTH]))
                elseif GetUnitLifePercent(ChaosBoss[BOSS_AZAZOTH]) > 50 then
                    call AstralDevastation(ChaosBoss[BOSS_AZAZOTH], GetRandomReal(5,6), HMscale(4000000), GetUnitFacing(ChaosBoss[BOSS_AZAZOTH]))
                elseif GetUnitLifePercent(ChaosBoss[BOSS_AZAZOTH]) > 25 then
                    call AstralDevastation(ChaosBoss[BOSS_AZAZOTH], GetRandomReal(4,5), HMscale(4000000), GetUnitFacing(ChaosBoss[BOSS_AZAZOTH]))
                else
                    call AstralDevastation(ChaosBoss[BOSS_AZAZOTH], GetRandomReal(3,4), HMscale(4000000), GetUnitFacing(ChaosBoss[BOSS_AZAZOTH]))
                endif
                call TimerStart(NewTimerEx(7), 20 + GetUnitLifePercent(ChaosBoss[BOSS_AZAZOTH]) / 10., false, function BossCD)
            elseif rand <25 and BossSpellCD[7] == false then
                set BossSpellCD[7]=true
                set udg_Azazoth_Casting_Spell=true
                call PauseUnit(ChaosBoss[BOSS_AZAZOTH],true)
                call SetUnitAnimation(ChaosBoss[BOSS_AZAZOTH], "spell slam")
                if u == ChaosBoss[BOSS_AZAZOTH] then
                    set u = GetAttacker()
                endif
                call SetUnitAnimation(ChaosBoss[BOSS_AZAZOTH], "spell slam")
                call DoFloatingTextUnit("Strength Obliteration" , ChaosBoss[BOSS_AZAZOTH], 2, 70, 0, 11, 255, 0, 0, 0)
                call DummyCastTarget(pboss, u, 'A0J1', 1, GetUnitX(ChaosBoss[BOSS_AZAZOTH]), GetUnitY(ChaosBoss[BOSS_AZAZOTH]), "cripple")
                call TriggerSleepAction(0.30)
                call UnitDamageTarget(ChaosBoss[BOSS_AZAZOTH], u, HMscale(1000000.), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                call TriggerSleepAction(2)
                call ResetAza()
                call TimerStart(NewTimerEx(7), 10 + GetUnitLifePercent(ChaosBoss[BOSS_AZAZOTH]) / 10., false, function BossCD)
            elseif rand <30 and BossSpellCD[9]==false then
                set BossSpellCD[9] = true
                call AstralAnnihilation()
                call TimerStart(NewTimerEx(9), GetRandomInt(35, 45) + GetUnitLifePercent(ChaosBoss[BOSS_AZAZOTH]) / 10., false, function BossCD)
            elseif rand <40 and BossSpellCD[8]==false then
                set BossSpellCD[8] = true
                call DoFloatingTextUnit("Astral Shield" , ChaosBoss[BOSS_AZAZOTH], 3, 70, 0, 11, 102, 255, 102, 0)
                call DestroyEffectTimed(AddSpecialEffectTarget( "war3mapImported\\DemonShieldTarget3A.mdx", ChaosBoss[BOSS_AZAZOTH], "origin"), 13.)
                set udg_Azazoth_Casting_Spell=true
                call PauseUnit(ChaosBoss[BOSS_AZAZOTH],true)
                call SetUnitAnimation(ChaosBoss[BOSS_AZAZOTH], "spell slam")
                call TriggerSleepAction(0.27)
                call UnitAddAbility(ChaosBoss[BOSS_AZAZOTH],'A0J2')
                call UnitAddAbility(ChaosBoss[BOSS_AZAZOTH],'ACmi')
                call TriggerSleepAction(0.27)
                call ResetAza()
                call TriggerSleepAction(12)
                call DestroyEffect(AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", ChaosBoss[BOSS_AZAZOTH], "origin"))
                call UnitRemoveAbility(ChaosBoss[BOSS_AZAZOTH],'ACmi')
                call UnitRemoveAbility(ChaosBoss[BOSS_AZAZOTH],'A0J2')
                call TimerStart(NewTimerEx(8), GetRandomInt(25, 35) + GetUnitLifePercent(ChaosBoss[BOSS_AZAZOTH]) / 10., false, function BossCD)
            endif
        endif
    endif
    
    call RemoveLocation(loc)

    set u = null
    set u2 = null
    set loc = null
endfunction

//===========================================================================
function AttackedInit takes nothing returns nothing
    local trigger attacked = CreateTrigger()
    local User u = User.first

	loop
		exitwhen u == User.NULL
		call TriggerRegisterPlayerUnitEvent(attacked, u.toPlayer(), EVENT_PLAYER_UNIT_ATTACKED, function boolexp)
		set u = u.next
	endloop
    
    call TriggerRegisterPlayerUnitEvent(attacked, Player(8), EVENT_PLAYER_UNIT_ATTACKED, function boolexp)
    call TriggerRegisterPlayerUnitEvent(attacked, pboss, EVENT_PLAYER_UNIT_ATTACKED, function boolexp)
    call TriggerRegisterPlayerUnitEvent(attacked, pfoe, EVENT_PLAYER_UNIT_ATTACKED, function boolexp)
    
	call TriggerAddAction(attacked, function onAttack)

    set attacked = null
endfunction

endlibrary
