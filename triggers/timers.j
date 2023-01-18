library Timers requires Functions, TimerUtils, Commands, Dungeons, Bosses, Spells, TerrainPathability

globals
    boolean array MISSILE_EXPIRE_AOE
    group HeroGroup = CreateGroup()
    timer array SaveTimer
    real array LAST_HERO_X
    real array LAST_HERO_Y
endglobals

function ReturnBoss takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer i = GetTimerData(t)
    local real hp
    local real angle

    if udg_Chaos_World_On then
        set angle = Atan2(GetLocationY(ChaosBossLoc[i]) - GetUnitY(ChaosBoss[i]), GetLocationX(ChaosBossLoc[i]) - GetUnitX(ChaosBoss[i]))
        if IsUnitInRangeLoc(ChaosBoss[i], ChaosBossLoc[i], 100.) then
            call ReleaseTimer(t)
            call SetUnitMoveSpeed(ChaosBoss[i], GetUnitDefaultMoveSpeed(ChaosBoss[i]))
            call SetUnitPathing(ChaosBoss[i], true)
            call UnitRemoveAbility(ChaosBoss[i], 'Amrf')
            call SetUnitTurnSpeed(ChaosBoss[i], GetUnitDefaultTurnSpeed(ChaosBoss[i]))
        else
            set hp = BlzGetUnitMaxHP(ChaosBoss[i]) * 0.008
            call SetUnitXBounded(ChaosBoss[i], GetUnitX(ChaosBoss[i]) + 20. * Cos(angle))
            call SetUnitYBounded(ChaosBoss[i], GetUnitY(ChaosBoss[i]) + 20. * Sin(angle))
            call IssuePointOrder(ChaosBoss[i], "move", GetUnitX(ChaosBoss[i]) + 70. * Cos(angle), GetUnitY(ChaosBoss[i]) + 70. * Sin(angle))
            call SetWidgetLife(ChaosBoss[i], GetWidgetLife(ChaosBoss[i]) + hp)
        endif
    else
        set angle = Atan2(GetLocationY(PreChaosBossLoc[i]) - GetUnitY(PreChaosBoss[i]), GetLocationX(PreChaosBossLoc[i]) - GetUnitX(PreChaosBoss[i]))
        if IsUnitInRangeLoc(PreChaosBoss[i], PreChaosBossLoc[i], 100.) then
            call ReleaseTimer(t)
            call SetUnitMoveSpeed(PreChaosBoss[i], GetUnitDefaultMoveSpeed(PreChaosBoss[i]))
            call SetUnitPathing(PreChaosBoss[i], true)
            call UnitRemoveAbility(PreChaosBoss[i], 'Amrf')
            call SetUnitTurnSpeed(PreChaosBoss[i], GetUnitDefaultTurnSpeed(PreChaosBoss[i]))
        else
            set hp = BlzGetUnitMaxHP(PreChaosBoss[i]) * 0.008
            call SetUnitXBounded(PreChaosBoss[i], GetUnitX(PreChaosBoss[i]) + 20. * Cos(angle))
            call SetUnitYBounded(PreChaosBoss[i], GetUnitY(PreChaosBoss[i]) + 20. * Sin(angle))
            call IssuePointOrder(PreChaosBoss[i], "move", GetUnitX(PreChaosBoss[i]) + 70. * Cos(angle), GetUnitY(PreChaosBoss[i]) + 70. * Sin(angle))
            call SetWidgetLife(PreChaosBoss[i], GetWidgetLife(PreChaosBoss[i]) + hp)
        endif
    endif

    set t = null
endfunction

function DelayedSave takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    
    if ActionSave(Player(pid - 1)) or HeroID[pid] == 0 then
        call ReleaseTimer(t)
    endif
    
    set t = null
endfunction

function HelicopterSwap takes nothing returns nothing
    local User u = User.first
    local integer pid
    
    loop
        exitwhen u == User.NULL
        set pid = GetPlayerId(u.toPlayer()) + 1
        
        if GetWidgetLife(helicopter[pid]) >= 0.406 then
            set heliangle[pid] = GetRandomInt(1, 3) * 120 - 60
        endif
        
        set u = u.next
    endloop

endfunction

function FightMeInvuln takes nothing returns nothing
    local User u = User.first
    local User u2
    local integer pid
    local integer pid2
    local boolean isInvuln
    local unit target
    local unit target2
    local group ug = CreateGroup()
    
    loop
        exitwhen u == User.NULL
        set pid = GetPlayerId(u.toPlayer()) + 1
        
        if FightMe[pid] then
            call GroupEnumUnitsInRange(ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 800. * BOOST(pid), Condition(function isplayerunit))
            call GroupRemoveUnit(ug, Hero[pid])
            
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call GroupAddUnit(FightMeGroup, target)
                call UnitAddAbility(target, 'Avul')
            endloop
        endif
        
        set u = u.next
    endloop
    
    call BlzGroupAddGroupFast(FightMeGroup, ug)
    
    loop
        set u2 = User.first
        set isInvuln = false
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        loop
            exitwhen u2 == User.NULL
            set pid2 = GetPlayerId(u2.toPlayer()) + 1
            
            if FightMe[pid2] and IsUnitInRange(target, Hero[pid2], 800. * BOOST(pid2)) then
                set isInvuln = true
            endif
                    
            set u2 = u2.next
        endloop
                
        if isInvuln == false then
            call GroupRemoveUnit(FightMeGroup, target)
            call UnitRemoveAbility(target, 'Avul')
        endif
    endloop
    
    call DestroyGroup(ug)
    
    set target = null
    set target2 = null
    set ug = null
endfunction

function SmokebombEvasion takes nothing returns nothing
    local User u = User.first
    local User u2
    local integer pid
    local integer pid2
    local boolean inSmoke

    loop
        exitwhen u == User.NULL
        set inSmoke = false
        set pid = GetPlayerId(u.toPlayer()) + 1
        
        if IsUnitInGroup(Hero[pid], InSmokebomb) then //determine if hero still in smoke
            set u2 = User.first
            loop
                exitwhen u2 == User.NULL
                set pid2 = GetPlayerId(u2.toPlayer()) + 1
                
                if SmokebombX[pid2] != 0 and SmokebombY[pid2] != 0 and IsUnitInRangeXY(Hero[pid], SmokebombX[pid2], SmokebombY[pid2], 300.00 * LBOOST(pid2)) and (SmokebombBonus[pid] == SmokebombValue[pid2] or SmokebombBonus[pid] == SmokebombValue[pid2] * 2) then
                    set inSmoke = true
                    exitwhen true
                endif
                
                set u2 = u2.next
            endloop
            
            //not in smoke anymore
            if inSmoke == false then
                call GroupRemoveUnit(InSmokebomb, Hero[pid])
                call UnitRemoveAbility(Hero[pid], 'A03S')
                call UnitRemoveAbility(Hero[pid], 'B027')
                set SmokebombBonus[pid] = 0
            endif
        else //add to group / apply bonuses
            if SmokebombX[pid] != 0 and SmokebombY[pid] != 0 and IsUnitInRangeXY(Hero[pid], SmokebombX[pid], SmokebombY[pid], 300.00 * LBOOST(pid)) then //self double bonus
                call GroupAddUnit(InSmokebomb, Hero[pid])
                call UnitAddAbility(Hero[pid], 'A03S')
                call BlzUnitHideAbility(Hero[pid], 'A03S', true)
                set SmokebombBonus[pid] = SmokebombValue[pid] * 2
            else //bonus from allies
                set u2 = User.first
                loop
                    exitwhen u2 == User.NULL
                    set pid2 = GetPlayerId(u2.toPlayer()) + 1
                    
                    if SmokebombX[pid2] != 0 and SmokebombY[pid2] != 0 and IsUnitInRangeXY(Hero[pid], SmokebombX[pid2], SmokebombY[pid2], 300.00 * LBOOST(pid2)) then
                        call GroupAddUnit(InSmokebomb, Hero[pid])
                        call UnitAddAbility(Hero[pid], 'A03S')
                        call BlzUnitHideAbility(Hero[pid], 'A03S', true)
                        set SmokebombBonus[pid] = SmokebombValue[pid2]
                        exitwhen true
                    endif
                    
                    set u2 = u2.next
                endloop
            endif
        endif
        
        set u = u.next
    endloop
endfunction

function Periodic takes nothing returns nothing
    local integer pid
    local real x
    local real y
    local integer i = 0
    local User p = User.first
    
    loop
        exitwhen p == User.NULL
        set pid = GetPlayerId(p.toPlayer()) + 1
        
        //backpack
        
        if Backpack[pid] != null and not isteleporting[pid] then
            if bpmoving[pid] == false or UnitDistance(Hero[pid], Backpack[pid]) >= 800. then
                set x = GetUnitX(Hero[pid]) - 30.
                set y = GetUnitY(Hero[pid]) + 30.
                if UnitDistance(Hero[pid], Backpack[pid]) >= 1000. then
                    call SetUnitXBounded(Backpack[pid], x)
                    call SetUnitYBounded(Backpack[pid], y)
                endif
                if isteleporting[pid] == false and UnitDistance(Hero[pid], Backpack[pid]) > 80. then
                    call DisableTrigger(pointOrder)
                    call IssuePointOrder(Backpack[pid], "move", x, y)
                    call EnableTrigger(pointOrder)
                endif
            endif
        endif
        
        //gyro
        
        if GetWidgetLife(helicopter[pid]) >= 0.406 then
            set x = GetUnitX(Hero[pid]) + 60. * Cos(bj_DEGTORAD * (heliangle[pid] + GetUnitFacing(Hero[pid])))
            set y = GetUnitY(Hero[pid]) + 60. * Sin(bj_DEGTORAD * (heliangle[pid] + GetUnitFacing(Hero[pid])))
        
            if DistanceCoords(x, y, GetUnitX(helicopter[pid]), GetUnitY(helicopter[pid])) > 75. then
                call DisableTrigger(pointOrder)
                call IssuePointOrder(helicopter[pid], "move", x, y)
                call EnableTrigger(pointOrder)
            endif
            
            call GroupEnumUnitsInRangeEx(pid, helitargets[pid], GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 800., Condition(function FilterEnemyAwake))
        
            if BlzGroupGetSize(helitargets[pid]) > 0 and not heliCD[pid] then
                set heliCD[pid] = true
                call TimerStart(NewTimerEx(pid), 1.25 - (0.25 * GetUnitAbilityLevel(Hero[pid], 'A06U') * LBOOST(pid)), false, function HeliCD)
                call ClusterRockets(pid)
            endif
        endif
        
        //spellboost
        
        set BoostValue[pid] = Spl_mod[pid] / 100. + ItemSpellboost[pid]
            
        if GetUnitAbilityLevel(Hero[pid], 'A0A0') > 0 then //inspire
            set BoostValue[pid] = BoostValue[pid] + (0.08 + 0.02 * GetUnitAbilityLevel(Hero[pid], 'A0A0'))
        endif 
        if GetUnitAbilityLevel(Hero[pid], 'B01Y') > 0 then //Firestorm
            set BoostValue[pid] = BoostValue[pid] + 0.15
        endif
        if GetUnitAbilityLevel(Hero[pid], 'B022') > 0 then //Demonic Sacrifice
            set BoostValue[pid] = BoostValue[pid] + 0.15
        endif
        
        if IsUnitInGroup(Hero[pid], AffectedByWeather) then
            if udg_Weather == 6 then
                set BoostValue[pid] = BoostValue[pid] - 0.05
            elseif udg_Weather == 5 then
                set BoostValue[pid] = BoostValue[pid] - 0.10
            elseif udg_Weather == 10 then
                set BoostValue[pid] = BoostValue[pid] - 0.20
            elseif udg_Weather == 15 then
                set BoostValue[pid] = BoostValue[pid] - 0.15
            elseif udg_Weather == 17 then
                set BoostValue[pid] = BoostValue[pid] + 0.3
                set DmgTaken[pid] = DmgTaken[pid] * 1.25
                set SpellTaken[pid] = SpellTaken[pid] * 1.25
            endif
        endif

        if GetHeroLevel(Hero[pid]) > 399 then
            set i = 45
        elseif GetHeroLevel(Hero[pid]) > 299 then
            set i = 35
        elseif GetHeroLevel(Hero[pid]) > 199 then
            set i = 25
        elseif GetHeroLevel(Hero[pid]) > 99 then
            set i = 15
        else
            set i = 5
        endif
        
        set BoostValue[pid] = BoostValue[pid] + (IMinBJ(BlzGroupGetSize(darkSealTargets[pid]), i) * 0.01) //dark seal

        set i = 0
        
        //damage taken
            
        set DmgTaken[pid] = RMaxBJ(0, DmgBase[pid] * ItemTotaldef[pid] * DR_mod[pid]) //prestige bonus
        set SpellTaken[pid] = RMaxBJ(0, SpellTakenBase[pid] * ItemTotaldef[pid] * ItemSpelldef[pid] * DR_mod[pid])
        
        if GetUnitAbilityLevel(Hero[pid], 'B01V') > 0 then //master of elements (earth)
            set DmgTaken[pid] = DmgTaken[pid] * 0.8
            set SpellTaken[pid] = SpellTaken[pid] * 0.8
        endif
        if HeroID[pid] == HERO_VAMPIRE and GetUnitAbilityLevel(Hero[pid], 'A097') > 0 and GetHeroStr(Hero[pid], true) > GetHeroAgi(Hero[pid], true) then //vampire str resist
            set DmgTaken[pid] = DmgTaken[pid] * (1 - 0.01 * (BloodBank[pid] / (GetHeroInt(Hero[pid], true) * 8)))
            set SpellTaken[pid] = SpellTaken[pid] * (1 - 0.01 * (BloodBank[pid] / (GetHeroInt(Hero[pid], true) * 8)))
        endif
        if GetUnitAbilityLevel(Hero[pid], 'B024') > 0 then //arcane aura
            set SpellTaken[pid] = SpellTaken[pid] * RMaxBJ(0.96 - 0.01 * ArcaneAura(pid), 0.8)
        endif
        if GetUnitAbilityLevel(Hero[pid], 'B01Y') > 0 then //master of elements (fire)
            set DmgTaken[pid] = DmgTaken[pid] * 1.3
            set SpellTaken[pid] = SpellTaken[pid] * 1.3
        endif
        if GetUnitAbilityLevel(Hero[pid], 'B01S') > 0 then //protection
            set DmgTaken[pid] = DmgTaken[pid] / 3.
            set SpellTaken[pid] = SpellTaken[pid] / 3.
        endif 
        if GetUnitAbilityLevel(Hero[pid], 'A01B') > 0 then //song of peace
            set DmgTaken[pid] = DmgTaken[pid] * 0.8
            set SpellTaken[pid] = SpellTaken[pid] * 0.8 
        endif 
        if GetUnitAbilityLevel(Hero[pid], 'B056') > 0 then //darkest of darkness
            set DmgTaken[pid] = DmgTaken[pid] * 0.6
            set SpellTaken[pid] = SpellTaken[pid] * 0.6
        endif
        if GetUnitAbilityLevel(Hero[pid], 'A05T') > 0 then //magnetic shockwave stance
            set DmgTaken[pid] = DmgTaken[pid] * (0.85 - 0.05 * GetUnitAbilityLevel(Hero[pid], 'A05R'))
            set SpellTaken[pid] = SpellTaken[pid] * (0.85 - 0.05 * GetUnitAbilityLevel(Hero[pid], 'A05R'))
        endif
        if GetUnitAbilityLevel(Hero[pid], 'A09I') > 0 then //protected
            set DmgTaken[pid] = DmgTaken[pid] * (0.88 - 0.02 * GetUnitAbilityLevel(Hero[pid], 'A09I'))
            set SpellTaken[pid] = SpellTaken[pid] * (0.88 - 0.02 * GetUnitAbilityLevel(Hero[pid], 'A09I'))
        endif
        if TimerList[pid].hasTimerWithTag('omni') then //omnislash 80% reduction 
            set DmgTaken[pid] = DmgTaken[pid] * 0.2
            set SpellTaken[pid] = SpellTaken[pid] * 0.2
        endif
        
        //evasion
        
        set TotalEvasion[pid] = ItemEvasion[pid] + SmokebombBonus[pid]

        if GetUnitAbilityLevel(Hero[pid], 'A03Y') > 0 then //assassin smokebomb
            set TotalEvasion[pid] = TotalEvasion[pid] + 30
        endif

        if TotalEvasion[pid] > 100 or PhantomSlashing[pid] then
            set TotalEvasion[pid] = 100
        endif
            
        set HasShield[pid] = CheckShields(Hero[pid])
        
        //movement speed

        if arcanosphereActive[pid] and IsUnitInRangeXY(Hero[pid], GetUnitX(arcanosphere[pid]), GetUnitY(arcanosphere[pid]), 800.) then
            set Movespeed[pid] = 1000
            call SetUnitMoveSpeed(Hero[pid], 522)
        else
            //bonuses
            set Movespeed[pid] = R2I(GetUnitDefaultMoveSpeed(Hero[pid])) + ItemMovespeed[pid]
            
            if GetUnitAbilityLevel(Hero[pid], 'B02A') > 0 then //barrage
                set Movespeed[pid] = Movespeed[pid] + 150
            endif
            if GetUnitAbilityLevel(Hero[pid], 'B01I') > 0 then //infused water
                set Movespeed[pid] = Movespeed[pid] + 150
            endif
            if GetUnitAbilityLevel(Hero[pid], 'B02F') > 0 then //drum of war
                set Movespeed[pid] = Movespeed[pid] + 75
            endif
            if GetUnitAbilityLevel(Hero[pid], 'BUau') > 0 then //blood horn
                set Movespeed[pid] = Movespeed[pid] + 75
            endif
            if rampageActive[pid] then //rampage movespeed
                set Movespeed[pid] = Movespeed[pid] + 50
            endif
            if bloodMistActive[pid] and BloodBank[pid] > (25 * GetHeroInt(Hero[pid], true)) then //blood mist movespeed
                set Movespeed[pid] = Movespeed[pid] + 50 + 50 * GetUnitAbilityLevel(Hero[pid], 'A093')
            endif

            if IsUnitInGroup(Hero[pid], AffectedByWeather) then
                if udg_Weather == 1 then //hurricane
                    set Movespeed[pid] = R2I(Movespeed[pid] * 0.3)
                elseif udg_Weather == 2 then //heavy snow
                    set Movespeed[pid] = R2I(Movespeed[pid] * 0.65)
                elseif udg_Weather == 3 then //snow
                    set Movespeed[pid] = R2I(Movespeed[pid] * 0.7)
                elseif udg_Weather == 4 then //fog
                    set Movespeed[pid] = R2I(Movespeed[pid] * 0.9)
                elseif udg_Weather == 5 then //heavy rain
                    set Movespeed[pid] = R2I(Movespeed[pid] * 0.75)
                elseif udg_Weather == 6 then //rain
                    set Movespeed[pid] = R2I(Movespeed[pid] * 0.8)
                elseif udg_Weather == 8 then //sunny
                    set Movespeed[pid] = R2I(Movespeed[pid] * 1.2)
                elseif udg_Weather == 9 then //divine grace
                    set Movespeed[pid] = R2I(Movespeed[pid] * 2.)
                elseif udg_Weather == 11 then //chaotic hurricane
                    set Movespeed[pid] = R2I(Movespeed[pid] * 0.2)
                elseif udg_Weather == 12 then //chaotic heavy snow
                    set Movespeed[pid] = R2I(Movespeed[pid] * 0.55)
                elseif udg_Weather == 14 then //chaotic fog
                    set Movespeed[pid] = R2I(Movespeed[pid] * 0.8)
                elseif udg_Weather == 15 then //chaotic heavy rain
                    set Movespeed[pid] = R2I(Movespeed[pid] * 0.7)
                endif
            endif
            
            if GetUnitAbilityLevel(Hero[pid], 'B01Z') > 0 then //master of elements (lightning)
                set Movespeed[pid] = R2I(Movespeed[pid] * 1.4)
            endif
            if GetUnitAbilityLevel(Hero[pid], 'B02D') > 0 then //wind walk
                set Movespeed[pid] = R2I(Movespeed[pid] * (1.05 + GetUnitAbilityLevel(Hero[pid], 'A0F5') * 0.1))
            endif
            
            call SetUnitMoveSpeed(Hero[pid], IMinBJ(522, Movespeed[pid]))

            if Movespeed[pid] > 600 then
                set Movespeed[pid] = 600
            endif

            //Adjust Backpack MS
            call SetUnitMoveSpeed(Backpack[pid], Movespeed[pid])

            if sniperstance[pid] then
                set Movespeed[pid] = 100
                call SetUnitMoveSpeed(Hero[pid], 100)
            endif
        endif
        
        set p = p.next
    endloop

endfunction

function CreateWell takes nothing returns nothing
    local integer heal = 50
    local real x
    local real y
    local rect r
    local integer rand = GetRandomInt(1, 14)

    if rand == 14 then
        set rand = 15 //exclude elder dragon
    endif

    if wellcount < 7 then
        set r = SelectGroupedRegion(GetRandomInt(1, 15))

        set wellcount = wellcount + 1
        loop
            set x = GetRandomReal(GetRectMinX(r), GetRectMaxX(r))
            set y = GetRandomReal(GetRectMinY(r), GetRectMaxY(r))
            exitwhen IsTerrainWalkable(x, y)
        endloop
        set well[wellcount] = GetDummy(x, y, 0, 0, 0)
        call BlzSetUnitFacingEx(well[wellcount], 270)
        call UnitRemoveAbility(well[wellcount], 'Aloc')
        call ShowUnit(well[wellcount], false)
        call ShowUnit(well[wellcount], true)
        if GetRandomInt(0, 2) < 2 then
            call BlzSetUnitSkin(well[wellcount], 'h04W')
            call BlzSetUnitName(well[wellcount], "Health Well")
        else
            call BlzSetUnitSkin(well[wellcount], 'h05H')
            call BlzSetUnitName(well[wellcount], "Mana Well")
            set heal = heal + 100 //mana
        endif
        call SetUnitScale(well[wellcount], 0.5, 0.5, 0.5)
        set wellheal[wellcount] = heal
    endif

    set r = null
endfunction

function SpawnStruggleUnits takes nothing returns nothing
    local integer i=1
    local integer end = R2I(udg_Struggle_Wave_SR[udg_Struggle_WaveN])
    local integer rand = GetRandomInt(1,4)
    local unit u

    loop
        exitwhen i > end
        if udg_Struggle_WaveUCN > 0 and udg_Struggle_Pcount > 0 then
            if BlzGroupGetSize(StruggleWaveGroup) < 70 then
                set udg_Struggle_WaveUCN = udg_Struggle_WaveUCN - 1
                set u = CreateUnit(pboss, udg_Struggle_WaveU[udg_Struggle_WaveN], GetRectCenterX(gg_rct_Infinite_Struggle), GetRectCenterY(gg_rct_Infinite_Struggle), bj_UNIT_FACING)
                call SetUnitXBounded(u, GetRandomReal(GetRectMinX(udg_Struggle_SpawnR[rand]), GetRectMaxX(udg_Struggle_SpawnR[rand])))
                call SetUnitYBounded(u, GetRandomReal(GetRectMinY(udg_Struggle_SpawnR[rand]), GetRectMaxY(udg_Struggle_SpawnR[rand])))
                call GroupAddUnit(StruggleWaveGroup, u)
                call SetUnitCreepGuard(u, false)
                call SetUnitAcquireRange(u, 3000.)
            endif
        endif
        set i = i + 1
    endloop

    set u = null
endfunction

function LavaBurn takes nothing returns nothing
    local group burnMe = CreateGroup()
    local group ug = CreateGroup()
    local unit u
    local real dmg
    
    call GroupEnumUnitsInRect(burnMe, gg_rct_Lava1, Condition(function isplayerunit))
    call GroupEnumUnitsInRect(ug, gg_rct_Lava2, Condition(function isplayerunit))
    call BlzGroupAddGroupFast(ug, burnMe)
    
    loop
		set u=FirstOfGroup(burnMe)
		exitwhen u==null
		call GroupRemoveUnit(burnMe, u)
        set dmg = BlzGetUnitMaxHP(u) / 40 + 1000
        if GetUnitFlyHeight(u) < 75.00 then
            if GetUnitTypeId(u) != 0 and GetUnitState(u,UNIT_STATE_LIFE) > dmg then
                call SetUnitState(u, UNIT_STATE_LIFE, GetUnitState(u,UNIT_STATE_LIFE) - dmg)
                call DoFloatingTextUnit( RealToString(dmg) , u, 0.8,70,0, 8, 100 , 40 , 40 ,0)
            elseif GetUnitTypeId(u) != 0 then
                call SetUnitState(u, UNIT_STATE_LIFE, GetUnitState(u,UNIT_STATE_LIFE) - dmg)
                call DoFloatingTextUnit( RealToString(GetUnitState(u,UNIT_STATE_LIFE)) , u, 0.8,70,0, 8, 100 , 40 , 40 ,0)
            endif
        endif
	endloop

    call DestroyGroup(burnMe)
	call DestroyGroup(ug)
	
	set burnMe=null
    set ug = null
    set u = null
endfunction

function ColosseumXPDecrease takes nothing returns nothing
    local User u = User.first
    local integer i
    
	loop
		exitwhen u == User.NULL
        set i = GetPlayerId(u.toPlayer()) + 1
		if HeroID[i] > 0 and InColo[i] and udg_Colloseum_XP[i] > 0.05 then
			set udg_Colloseum_XP[i]= udg_Colloseum_XP[i] - 0.005
		endif
        if udg_Colloseum_XP[i] < 0.05 then
            set udg_Colloseum_XP[i] = 0.05
        endif
        call ExperienceControl(i)
		set u = u.next
	endloop
endfunction

function ColosseumXPIncrease takes nothing returns nothing
    local User u = User.first
    local integer i
    
	loop
		exitwhen u == User.NULL
        set i = GetPlayerId(u.toPlayer()) + 1
        if HeroID[i] > 0 and InColo[i] == false and udg_Colloseum_XP[i] < 1.30 then
            if udg_Colloseum_XP[i] < 0.75 then
                set udg_Colloseum_XP[i] = udg_Colloseum_XP[i] + 0.02
            else
                set udg_Colloseum_XP[i] = udg_Colloseum_XP[i] + 0.01
            endif
            if udg_Colloseum_XP[i] > 1.30 then
                set udg_Colloseum_XP[i] = 1.30
            endif
            call ExperienceControl(i)
        endif
        set u = u.next
    endloop
endfunction

function WanderingGuys takes nothing returns nothing
    local real x
    local real y
    local real x2
    local real y2
    
    if GetUnitTypeId(PreChaosBoss[BOSS_DEATH_KNIGHT]) != 0 and GetWidgetLife(PreChaosBoss[BOSS_DEATH_KNIGHT]) >= 0.406 then
        loop
            set x = GetRandomReal(GetRectMinX(gg_rct_Main_Map), GetRectMaxX(gg_rct_Main_Map))
            set y = GetRandomReal(GetRectMinY(gg_rct_Main_Map), GetRectMaxY(gg_rct_Main_Map))
            set x2 = GetUnitX(PreChaosBoss[BOSS_DEATH_KNIGHT])
            set y2 = GetUnitY(PreChaosBoss[BOSS_DEATH_KNIGHT])
            
            exitwhen LineContainsBox(x2, y2, x, y, -4000, -3000, 4000, 5000, 0.3) == false and IsTerrainWalkable(x, y) and DistanceCoords(x, y, x2, y2) > 1500.
        endloop
    
        call IssuePointOrder(PreChaosBoss[BOSS_DEATH_KNIGHT], "patrol", x, y )
    endif
    if GetUnitTypeId(ChaosBoss[BOSS_LEGION]) != 0 and GetWidgetLife(ChaosBoss[BOSS_LEGION]) >= 0.406 then
        loop
            set x = GetRandomReal(GetRectMinX(gg_rct_Main_Map), GetRectMaxX(gg_rct_Main_Map))
            set y = GetRandomReal(GetRectMinY(gg_rct_Main_Map), GetRectMaxY(gg_rct_Main_Map))
            set x2 = GetUnitX(ChaosBoss[BOSS_LEGION])
            set y2 = GetUnitY(ChaosBoss[BOSS_LEGION])
            
            exitwhen LineContainsBox(x2, y2, x, y, -4000, -3000, 4000, 5000, 0.3) == false and IsTerrainWalkable(x, y) and DistanceCoords(x, y, x2, y2) > 1500.
        endloop
    
        call IssuePointOrder(ChaosBoss[BOSS_LEGION], "patrol", x, y )
    endif
    if GetWidgetLife(gg_unit_H01T_0259) >= 0.406 then
        set x = GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 500, GetRectMaxX(gg_rct_Town_Boundry) - 500)
        set y = GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 500, GetRectMaxY(gg_rct_Town_Boundry) - 500)
    
        call IssuePointOrder(gg_unit_H01T_0259, "move", x, y )
    endif
    if GetWidgetLife(gg_unit_H01Y_0099) >= 0.406 then
        set x = GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 500, GetRectMaxX(gg_rct_Town_Boundry) - 500)
        set y = GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 500, GetRectMaxY(gg_rct_Town_Boundry) - 500)
    
        call IssuePointOrder(gg_unit_H01Y_0099, "move", x, y )
    endif
endfunction

function Trig_SaveTimer_Actions takes nothing returns nothing
    local User u = User.first
    local integer pid
    
	loop
		exitwhen u == User.NULL
        set pid = GetPlayerId(u.toPlayer()) + 1
		if GetExpiredTimer() == SaveTimer[pid] then
            if autosave[pid] and not ActionSave(u.toPlayer()) then
                call TimerStart(NewTimerEx(pid), 30, true, function DelayedSave)
            endif
		endif
		set u = u.next
	endloop
endfunction

function TimePlayed takes nothing returns nothing
    local User u = User.first
    local integer i
    
    loop
        exitwhen u == User.NULL
        set i = GetPlayerId(u.toPlayer()) + 1
        set udg_TimePlayed[i] = udg_TimePlayed[i] + 1
        set u = u.next
    endloop
endfunction

function AFKClock takes nothing returns nothing
    local integer pid
    local User u = User.first

    set afkInt = GetRandomInt(1000,9999)
    call BlzFrameSetText(afkText, "TYPE -" + I2S(afkInt))

	loop
		exitwhen u == User.NULL
        set pid = GetPlayerId(u.toPlayer()) + 1

		if HeroID[pid] > 0 then
            if afkTextVisible[pid] then
                if GetLocalPlayer() == Player(pid - 1) then
                    call BlzFrameSetVisible(afkTextBG, false)
                endif
                call PanCameraToTimedLocForPlayer(u.toPlayer(), TownCenter, 0 )
                call DisplayTextToForce(FORCE_PLAYING, u.nameColored + " was removed for being AFK.")
                call SetPlayerStateBJ(u.toPlayer(), PLAYER_STATE_RESOURCE_LUMBER, 0 )
                call SetPlayerStateBJ(u.toPlayer(), PLAYER_STATE_RESOURCE_GOLD, 0 )
                call DisplayTextToPlayer(u.toPlayer(),0,0, "You have lost the game. All of your structures and units will be removed from the game, however you may stay and watch or leave as you choose." )
                call SharedRepick(u.toPlayer())
                //call SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_FOOD_USED, 0)
            elseif panCounter[pid] < 75 or moveCounter[pid] < 1000 then
                set afkTextVisible[pid] = true
                if GetLocalPlayer() == Player(pid - 1) then
                    call BlzFrameSetVisible(afkTextBG, true)
                endif
            endif
		endif

        set moveCounter[pid] = 0
        set panCounter[pid] = 0

        set u = u.next
	endloop
endfunction

function ShopkeeperMove takes nothing returns nothing
    local real x = GetRandomReal(GetRectMinX(gg_rct_Main_Map), GetRectMaxX(gg_rct_Main_Map))
    local real y = GetRandomReal(GetRectMinY(gg_rct_Main_Map), GetRectMaxY(gg_rct_Main_Map))
    
    call IsTerrainWalkable(x, y)
	call SetUnitPosition(gg_unit_n01F_0576, TerrainPathability_X, TerrainPathability_Y) //random starting spot
endfunction

function OneSecond takes nothing returns nothing
    local integer pid
    local real hp
    local real mp
    local integer i = 0
    local integer boardpos = 0
    local group g = CreateGroup()
    local group ug = CreateGroup()
    local unit target
    local integer index = 0
    local integer count = 0
    local integer numplayers = 0
    local User p = User.first

    set TIME = TIME + 1
    
    //Heli leash

    loop
        exitwhen p == User.NULL
        set pid = GetPlayerId(p.toPlayer()) + 1
    
        if helicopter[pid] != null and UnitDistance(Hero[pid], helicopter[pid]) > 700. then
            call SetUnitPosition(helicopter[pid], GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))
        endif
    
        set p = p.next
    endloop

    set p = User.first

    //Boss regeneration / player scaling / reset
    loop
        exitwhen i > BOSS_TOTAL and not udg_Chaos_World_On
        exitwhen i > CHAOS_BOSS_TOTAL and udg_Chaos_World_On
        set index = 0
        set count = BlzGroupGetSize(HeroGroup)
        set numplayers = 0
        if udg_Chaos_World_On and GetWidgetLife(ChaosBoss[i]) >= 0.406 then
            if ChaosBoss[i] != ChaosBoss[BOSS_LEGION] then
                if IsUnitInRangeLoc(ChaosBoss[i], ChaosBossLoc[i], 2000.) == false and GetUnitAbilityLevel(ChaosBoss[i], 'Amrf') == 0 then
                    call UnitAddAbility(ChaosBoss[i], 'Amrf')
                    call SetUnitMoveSpeed(ChaosBoss[i], 522)
                    call SetUnitPathing(ChaosBoss[i], false)
                    call SetUnitTurnSpeed(ChaosBoss[i], 1.)
                    call TimerStart(NewTimerEx(i), 0.06, true, function ReturnBoss)
                endif
            endif

            loop
                if IsUnitInRange(BlzGroupUnitAt(HeroGroup, index), ChaosBoss[i], 1800.) then
                    set numplayers = numplayers + 1
                endif
                set index = index + 1
                exitwhen index >= count
            endloop
            if GetWidgetLife(ChaosBoss[i]) > BlzGetUnitMaxHP(ChaosBoss[i]) * 0.15 then // > 15%
                set hp = BlzGetUnitMaxHP(ChaosBoss[i]) * 0.0005 * numplayers //0.05%
            else
                set hp = BlzGetUnitMaxHP(ChaosBoss[i]) * 0.001 * numplayers //0.1%
            endif

            if numplayers == 0 then //out of combat?
                set hp = BlzGetUnitMaxHP(ChaosBoss[i]) * 0.02
            else //bonus damage and health
                call UnitSetBonus(ChaosBoss[i], BONUS_DAMAGE, R2I(BlzGetUnitBaseDamage(ChaosBoss[i], 0) * 0.1 * (numplayers - 1)))
                call UnitSetBonus(ChaosBoss[i], BONUS_HERO_STR, R2I(GetHeroStr(ChaosBoss[i], false) * 0.1 * (numplayers - 1)))
            endif

            call SetWidgetLife(ChaosBoss[i], GetWidgetLife(ChaosBoss[i]) + hp)
        elseif udg_Chaos_World_On == false and GetWidgetLife(PreChaosBoss[i]) >= 0.406 then
            if PreChaosBoss[i] != PreChaosBoss[BOSS_DEATH_KNIGHT] then
                if IsUnitInRangeLoc(PreChaosBoss[i], PreChaosBossLoc[i], 2000.) == false and GetUnitAbilityLevel(PreChaosBoss[i], 'Amrf') == 0 then
                    call UnitAddAbility(PreChaosBoss[i], 'Amrf')
                    call SetUnitMoveSpeed(PreChaosBoss[i], 522)
                    call SetUnitPathing(PreChaosBoss[i], false)
                    call SetUnitTurnSpeed(PreChaosBoss[i], 1.)
                    call TimerStart(NewTimerEx(i), 0.06, true, function ReturnBoss)
                endif
            endif

            loop
                if IsUnitInRange(BlzGroupUnitAt(HeroGroup, index), PreChaosBoss[i], 1800.) then
                    set numplayers = numplayers + 1
                endif
                set index = index + 1
                exitwhen index >= count
            endloop
            if GetWidgetLife(PreChaosBoss[i]) > BlzGetUnitMaxHP(PreChaosBoss[i]) * 0.15 then // > 15%
                set hp = BlzGetUnitMaxHP(PreChaosBoss[i]) * 0.002 * numplayers //0.2%
            else
                set hp = BlzGetUnitMaxHP(PreChaosBoss[i]) * 0.004 * numplayers //0.4%
            endif

            if numplayers == 0 then
                set hp = BlzGetUnitMaxHP(PreChaosBoss[i]) * 0.02
            endif

            call SetWidgetLife(PreChaosBoss[i], GetWidgetLife(PreChaosBoss[i]) + hp)
        endif
        set i = i + 1
    endloop
    
    //Summon regeneration
    call BlzGroupAddGroupFast(SummonGroup, ug)
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if GetWidgetLife(target) >= 0.406 and GetUnitAbilityLevel(target, 'A06Q') > 0 then
            if GetUnitTypeId(target) == SUMMON_DESTROYER then
                set hp = BlzGetUnitMaxHP(target) * (0.02 + 0.0005 * GetUnitAbilityLevel(target, 'A06Q'))
            elseif GetUnitTypeId(target) == SUMMON_HOUND and GetUnitAbilityLevel(target, 'A06Q') > 9 then
                set hp = BlzGetUnitMaxHP(target) * (0.02 + 0.0005 * GetUnitAbilityLevel(target, 'A06Q'))
            else
                set hp = BlzGetUnitMaxHP(target) * (0.01 + 0.00025 * GetUnitAbilityLevel(target, 'A06Q'))
            endif
            call SetUnitState(target, UNIT_STATE_LIFE, GetWidgetLife(target) + hp)
        endif
    endloop

    //zeppelin kill
    if udg_Chaos_World_On then
        call ZeppelinKill()
    endif
    
    //Keep villagers in town
    call GroupEnumUnitsInRange(ug, 0, 0, 4000., Condition(function isvillager))
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if DistanceCoords(-250, 350, GetUnitX(target), GetUnitY(target)) > 3500. then
            call IssuePointOrderLoc(target, "move", TownCenter)
            if pallyENRAGE and target == gg_unit_H01T_0259 then
                call UnitRemoveAbility(target, 'Bblo')
                call BlzSetHeroProperName(target, "|c00F8A48BBuzan the Fearless|r")
                call UnitAddBonus(target, BONUS_DAMAGE, -5000)
                set pallyENRAGE = false
            endif
        endif
    endloop
    
    //Update Multiboard
    call BlzFrameSetText(clockText, IntegerToTime(TIME))
    //call MultiboardSetTitleText(MULTI_BOARD,  "Curse of Time RPG: |c009966ffNevermore|r - " + IntegerToTime(TIME))
    
    //Undespawn Units
    call BlzGroupAddGroupFast(despawnGroup, ug)
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call GroupEnumUnitsInRange(g, GetUnitX(target), GetUnitY(target), 800., Condition(function Trig_Enemy_Of_Hostile))
        if BlzGroupGetSize(g) == 0 then
            call GroupRemoveUnit(despawnGroup, target)
            call TimerStart(NewTimerEx(GetUnitId(target)), 1., false, function Undespawn)
        endif
        call GroupClear(g)
    endloop
    
    //add & remove players in dungeon queue
    if QUEUE_DUNGEON > 0 then
        loop
            exitwhen p == User.NULL
            set pid = GetPlayerId(p.toPlayer()) + 1

            if IsUnitInRangeXY(Hero[pid], QUEUE_X, QUEUE_Y, 500.) and GetWidgetLife(Hero[pid]) >= 0.406 and isteleporting[pid] == false then
                if IsPlayerInForce(p.toPlayer(), QUEUE_GROUP) == false and GetHeroLevel(Hero[pid]) >= QUEUE_LEVEL then
                    call ForceAddPlayer(QUEUE_GROUP, p.toPlayer())
                endif
            elseif IsPlayerInForce(p.toPlayer(), QUEUE_GROUP) then
                call ForceRemovePlayer(QUEUE_GROUP, p.toPlayer())
                set QUEUE_READY[pid] = false
                if GetLocalPlayer() == p.toPlayer() then
                    call MultiboardDisplay(MULTI_BOARD, true)
                endif
            endif
        
            set p = p.next
        endloop
    endif

    //refresh multiboard
    set pid = 1

    loop
        exitwhen pid > PLAYER_CAP

        if udg_MultiBoardsSpot[pid] > 0 then
            if IsPlayerInForce(Player(pid - 1), FORCE_PLAYING) then
                if HeroID[pid] > 0 then
                    set hp = GetUnitState(Hero[pid], UNIT_STATE_LIFE) / BlzGetUnitMaxHP(Hero[pid]) * 100

                    call MultiboardSetItemValueBJ(MULTI_BOARD, 5, udg_MultiBoardsSpot[pid], I2S(GetHeroLevel(Hero[pid])))
                    call MultiboardSetItemColorBJ(MULTI_BOARD, 5, udg_MultiBoardsSpot[pid], 62, 77, 98, 0)
                    call MultiboardSetItemValueBJ(MULTI_BOARD, 4, udg_MultiBoardsSpot[pid], GetUnitName(Hero[pid]))
                    call MultiboardSetItemValueBJ(MULTI_BOARD, 6, udg_MultiBoardsSpot[pid], I2S(R2I(hp)))
                    call MultiboardSetItemColorBJ(MULTI_BOARD, 6, udg_MultiBoardsSpot[pid], Pow(100 - hp, 1.1), SquareRoot(hp * 100) - 10, 0, 0)

                    if udg_Hardcore[pid] then
                        call MultiboardSetItemStyleBJ(MULTI_BOARD, 2, udg_MultiBoardsSpot[pid], false, true)
                        call MultiboardSetItemIconBJ(MULTI_BOARD, 2, udg_MultiBoardsSpot[pid], "ReplaceableTextures\\CommandButtons\\BTNBirial.blp")
                    else
                        call MultiboardSetItemStyleBJ(MULTI_BOARD, 2, udg_MultiBoardsSpot[pid], false, false)
                    endif
                    call MultiboardSetItemStyleBJ(MULTI_BOARD, 3, udg_MultiBoardsSpot[pid], false, true)
                    call MultiboardSetItemIconBJ(MULTI_BOARD, 3, udg_MultiBoardsSpot[pid], BlzGetAbilityIcon(GetUnitTypeId(Hero[pid])) )
                else
                    call MultiboardSetItemStyleBJ(MULTI_BOARD, 2, udg_MultiBoardsSpot[pid], false, false)
                    call MultiboardSetItemStyleBJ(MULTI_BOARD, 3, udg_MultiBoardsSpot[pid], false, false)
                    call MultiboardSetItemValueBJ(MULTI_BOARD, 4, udg_MultiBoardsSpot[pid], "")
                    call MultiboardSetItemValueBJ(MULTI_BOARD, 5, udg_MultiBoardsSpot[pid], "")
                    call MultiboardSetItemValueBJ(MULTI_BOARD, 6, udg_MultiBoardsSpot[pid], "")
                endif
            endif
        endif

        set pid = pid + 1
    endloop

    set p = User.first
    
    loop
        exitwhen p == User.NULL
        set pid = GetPlayerId(p.toPlayer()) + 1

        //Refresh dungeon queue multiboard
        if CountPlayersInForceBJ(QUEUE_GROUP) > 0 then
            call MultiboardSetRowCount(QUEUE_BOARD, CountPlayersInForceBJ(QUEUE_GROUP))
            call MultiboardSetColumnCount(QUEUE_BOARD, 2)
                
            if IsPlayerInForce(p.toPlayer(), QUEUE_GROUP) then
                call MultiboardSetItemStyleBJ( QUEUE_BOARD, 1, boardpos, true, false )
                call MultiboardSetItemStyleBJ( QUEUE_BOARD, 2, boardpos, false, true )

                call MultiboardSetItemValueBJ( QUEUE_BOARD, 1, boardpos, p.nameColored )
                
                call MultiboardSetItemWidthBJ( QUEUE_BOARD, 1, boardpos, 10.00 )
                call MultiboardSetItemWidthBJ( QUEUE_BOARD, 2, boardpos, 1.00 )
                
                if QUEUE_READY[pid] then
                    call MultiboardSetItemIconBJ( QUEUE_BOARD, 2, boardpos, "ReplaceableTextures\\CommandButtons\\BTNcheck.blp")
                else
                    call MultiboardSetItemIconBJ( QUEUE_BOARD, 2, boardpos, "ReplaceableTextures\\CommandButtons\\BTNCancel.blp")
                endif
                        
                set boardpos = boardpos + 1
            endif
        else
            set QUEUE_DUNGEON = 0
            call MultiboardDisplay(QUEUE_BOARD, false)
            call MultiboardDisplay(MULTI_BOARD, true)
        endif
        
        //Cooldowns
        
        if ReincarnationPRCD[pid] > 0 and HeroID[pid] == HERO_PHOENIX_RANGER then
            set ReincarnationPRCD[pid] = ReincarnationPRCD[pid] - 1
            if ReincarnationPRCD[pid] <= 0 then
                call BlzUnitHideAbility(Hero[pid], 'A04A', false)
                call UnitDisableAbility(Hero[pid], 'A047', true)
                call BlzUnitHideAbility(Hero[pid], 'A047', true)
            endif
        endif
        
        if ResurrectionCD[pid] > 0 then
            if GetUnitAbilityLevel(Hero[pid], 'A048') > 0 then
                set ResurrectionCD[pid] = ResurrectionCD[pid] - 1
                if ResurrectionCD[pid] <= 0 then
                    call UnitDisableAbility(Hero[pid], 'A048', false)
                endif
            endif
        endif
        
        if ArcaneBoltsCD[pid] > 0 then
            set ArcaneBoltsCD[pid] = ArcaneBoltsCD[pid] - 1
            if ArcaneBoltsCD[pid] <= 0 then
                call BlzEndUnitAbilityCooldown(Hero[pid], 'A05Q')
            endif
        endif
        
        if ArcaneBarrageCD[pid] > 0 then
            set ArcaneBarrageCD[pid] = ArcaneBarrageCD[pid] - 1
            if ArcaneBarrageCD[pid] <= 0 then
                call BlzEndUnitAbilityCooldown(Hero[pid], 'A02N')
            endif
        endif
        
        if StasisFieldCD[pid] > 0 then
            set StasisFieldCD[pid] = StasisFieldCD[pid] - 1
            if StasisFieldCD[pid] <= 0 then
                call BlzEndUnitAbilityCooldown(Hero[pid], 'A075')
            endif
        endif
        
        if ArcaneShiftCD[pid] > 0 then
            set ArcaneShiftCD[pid] = ArcaneShiftCD[pid] - 1
            if ArcaneShiftCD[pid] <= 0 then
                call BlzEndUnitAbilityCooldown(Hero[pid], 'A078')
            endif
        endif
        
        if SpaceTimeRippleCD[pid] > 0 then
            set SpaceTimeRippleCD[pid] = SpaceTimeRippleCD[pid] - 1
            if SpaceTimeRippleCD[pid] <= 0 then
                call BlzEndUnitAbilityCooldown(Hero[pid], 'A079')
            endif
        endif
        
        if ControlTimeCD[pid] > 0 then
            set ControlTimeCD[pid] = ControlTimeCD[pid] - 1
            if ControlTimeCD[pid] <= 0 then
                call BlzEndUnitAbilityCooldown(Hero[pid], 'A04C')
            endif
        endif
        
        if HeroID[pid] > 0 then
            //update mana costs
            call UnitSpecification(Hero[pid])

            //intense focus
            if GetUnitAbilityLevel(Hero[pid], 'A0B9') > 0 and GetWidgetLife(Hero[pid]) >= 0.406 and LAST_HERO_X[pid] == GetUnitX(Hero[pid]) and LAST_HERO_Y[pid] == GetUnitY(Hero[pid]) then
                set IntenseFocus[pid] = IMinBJ(10, IntenseFocus[pid] + 1)
            else
                set IntenseFocus[pid] = 0
            endif

            //keep track of hero positions
            set LAST_HERO_X[pid] = GetUnitX(Hero[pid])
            set LAST_HERO_Y[pid] = GetUnitY(Hero[pid])

            //PVP leave range
            if ArenaQueue[pid] > 0 and IsUnitInRangeXY(Hero[pid], 651, -576, 1000.) == false then
                set ArenaQueue[pid] = 0
                call DisplayTimedTextToPlayer(p.toPlayer(), 0, 0, 5.0, "You have been removed from the PvP queue.")
            endif

            set hp = GetUnitState(Hero[pid], UNIT_STATE_LIFE) / BlzGetUnitMaxHP(Hero[pid]) * 100
        
            //backpack hp/mp percentage
            if hp >= 1 then
                set hp = GetUnitState(Hero[pid], UNIT_STATE_LIFE) / BlzGetUnitMaxHP(Hero[pid])
                call SetUnitState(Backpack[pid], UNIT_STATE_LIFE, BlzGetUnitMaxHP(Backpack[pid]) * hp)
                set mp = GetUnitState(Hero[pid], UNIT_STATE_MANA) / GetUnitState(Hero[pid], UNIT_STATE_MAX_MANA)
                call SetUnitState(Backpack[pid], UNIT_STATE_MANA, GetUnitState(Backpack[pid], UNIT_STATE_MAX_MANA) * mp)
            endif

            set hp = IMinBJ(5, R2I((BlzGetUnitMaxHP(Hero[pid]) - GetWidgetLife(Hero[pid])) / BlzGetUnitMaxHP(Hero[pid]) * 100 / 15))

            //chaos shield regen
            if HasItemType(Hero[pid], 'I01J') and GetWidgetLife(Hero[pid]) >= 0.406 then
                call SetUnitState(Hero[pid], UNIT_STATE_LIFE, GetUnitState(Hero[pid], UNIT_STATE_LIFE) + BlzGetUnitMaxHP(Hero[pid]) * 0.002 * hp)
            elseif HasItemType(Hero[pid], 'I02R') and GetWidgetLife(Hero[pid]) >= 0.406 then
                call SetUnitState(Hero[pid], UNIT_STATE_LIFE, GetUnitState(Hero[pid], UNIT_STATE_LIFE) + BlzGetUnitMaxHP(Hero[pid]) * 0.003 * hp)
            elseif HasItemType(Hero[pid], 'I01C') and GetWidgetLife(Hero[pid]) >= 0.406 then
                call SetUnitState(Hero[pid], UNIT_STATE_LIFE, GetUnitState(Hero[pid], UNIT_STATE_LIFE) + BlzGetUnitMaxHP(Hero[pid]) * 0.004 * hp)
            endif
            
            //blood bank
            if HeroID[pid] == HERO_VAMPIRE then
                set BloodBank[pid] = RMinBJ(BloodBank[pid], 200 * GetHeroInt(Hero[pid], true))
                call BlzSetUnitMaxMana(Hero[pid], R2I(200 * GetHeroInt(Hero[pid], true)))
                call SetUnitState(Hero[pid], UNIT_STATE_MANA, BloodBank[pid])

                set hp = (BloodBank[pid] / (200 * GetHeroInt(Hero[pid], true))) * 5
                if GetLocalPlayer() == Player(pid - 1) then
                    call BlzSetAbilityIcon('A07K', "ReplaceableTextures\\CommandButtons\\BTNSimpleHugePotion" + I2S(R2I(hp)) + "_5.blp")
                    call BlzSetAbilityExtendedTooltip('A07K', "The Vampire Lord's attacks and spells accumulate blood that can be used to empower himself.|nEach attack fills the bank by |cffFF0B110.75 x Str|r and the max amount that can be stored is |cff0080ff200 x Int|r|n|cff990000Blood Stored:|r " + I2S(R2I(BloodBank[pid])), 0)
                endif

                //vampire cooldowns
                if GetUnitAbilityLevel(Hero[pid], 'A097') > 0 and GetHeroAgi(Hero[pid], true) > GetHeroStr(Hero[pid], true) then
                    call BlzSetUnitAbilityCooldown(Hero[pid], 'A07A', GetUnitAbilityLevel(Hero[pid], 'A07A') - 1, 3.)
                    call BlzSetUnitAbilityCooldown(Hero[pid], 'A09A', GetUnitAbilityLevel(Hero[pid], 'A09A') - 1, 2.5)
                    call BlzSetUnitAbilityCooldown(Hero[pid], 'A09B', GetUnitAbilityLevel(Hero[pid], 'A09B') - 1, 5.)
                else
                    call BlzSetUnitAbilityCooldown(Hero[pid], 'A07A', GetUnitAbilityLevel(Hero[pid], 'A07A') - 1, 6.)
                    call BlzSetUnitAbilityCooldown(Hero[pid], 'A09A', GetUnitAbilityLevel(Hero[pid], 'A09A') - 1, 5.)
                    call BlzSetUnitAbilityCooldown(Hero[pid], 'A09B', GetUnitAbilityLevel(Hero[pid], 'A09B') - 1, 10.)
                endif

                //vampire blood mist
                set hp = 16 * GetHeroInt(Hero[pid], true)

                if bloodMistActive[pid] and BloodBank[pid] > hp then
                    set BloodBank[pid] = BloodBank[pid] - hp
                    call SetUnitState(Hero[pid], UNIT_STATE_MANA, BloodBank[pid])
                    call HP(Hero[pid], ((0.5 + 0.5 * GetUnitAbilityLevel(Hero[pid], 'A093')) * GetHeroStr(Hero[pid], true) * BOOST(pid))) 
                    if GetUnitAbilityLevel(Hero[pid], 'B02Q') == 0 then
                        call UnitAddItemById(Hero[pid], 'I0OE')
                    endif
                    if bloodMistEffect[pid] == null then
                        set bloodMistEffect[pid] = AddSpecialEffectTarget("war3mapImported\\Chumpool.mdx", Hero[pid], "origin")
                    endif
                else
                    call UnitRemoveAbility(Hero[pid], 'B02Q')
                    if bloodMistEffect[pid] != null then
                        call DestroyEffect(bloodMistEffect[pid])
                        set bloodMistEffect[pid] = null
                    endif
                endif
            endif

            //inspire mana cost
            if InspireActive[pid] then
                set hp = GetUnitState(Hero[pid], UNIT_STATE_MANA)
                set mp = BlzGetUnitMaxMana(Hero[pid]) * 0.02
                call SetUnitState(Hero[pid], UNIT_STATE_MANA, RMaxBJ(hp - mp, 0))
                if hp - mp <= 0 then
                    call IssueImmediateOrderById(Hero[pid], 852178)
                endif
            endif

            //tooltips
        
            if GetUnitAbilityLevel(Hero[pid], 'A048') > 0 then
                set STOOLTIP[pid] = ReincarnationTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A048'))
                call BlzSetAbilityExtendedTooltip('A048', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A048') - 1)
            endif
            
            if GetUnitAbilityLevel(Hero[pid], 'A0MN') > 0 then
                set STOOLTIP[pid] = MonsoonTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A0MN'))
                call BlzSetAbilityExtendedTooltip('A0MN', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0MN') - 1)
            endif
            
            if GetUnitAbilityLevel(Hero[pid], 'A0F7') > 0 then
                set STOOLTIP[pid] = NerveGasTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A0F7'))
                call BlzSetAbilityExtendedTooltip('A0F7', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0F7') - 1)
            endif
            
            if GetUnitAbilityLevel(Hero[pid], 'A07X') > 0 then
                set STOOLTIP[pid] = ArcaneMightTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A07X'))
                call BlzSetAbilityExtendedTooltip('A07X', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A07X') - 1)
            endif
            
            if GetUnitAbilityLevel(Hero[pid], 'A06U') > 0 then
                set STOOLTIP[pid] = AssaultHelicopterTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A06U'))
                call BlzSetAbilityExtendedTooltip('A06U', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A06U') - 1)
            endif
            
            if GetUnitAbilityLevel(Hero[pid], 'A0FL') > 0 then
                set STOOLTIP[pid] = CounterStrikeTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A0FL'))
                call BlzSetAbilityExtendedTooltip('A0FL', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0FL') - 1)
            endif

            if GetUnitAbilityLevel(Hero[pid], 'A0QQ') > 0 then
                set STOOLTIP[pid] = InstantDeathTooltip(pid)
                call BlzSetAbilityExtendedTooltip('A0QQ', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0QQ') - 1)
            endif

            if GetUnitAbilityLevel(Hero[pid], 'A0AQ') > 0 then
                set STOOLTIP[pid] = BladeSpinTooltip(pid)
                call BlzSetAbilityExtendedTooltip('A0AQ', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0AQ') - 1)
                call BlzSetAbilityExtendedTooltip('A0AS', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0AS') - 1)
            endif

            if BardSong[pid] == 1 then
                call SongOfWar(pid, false)
            endif

            call Protector(pid) //royal guardian
            call Inspire(pid) //bard
        else
            call MultiboardSetItemValueBJ(MULTI_BOARD, 6, udg_MultiBoardsSpot[pid], "")
        endif

        set p = p.next
    endloop

    call SetPlayerAbilityAvailable(pfoe, 'Agyv', true)
    call SetPlayerAbilityAvailable(pfoe, 'Agyv', false)
    
    call DestroyGroup(g)
    call DestroyGroup(ug)
    
    set g = null
    set ug = null
    set target = null
endfunction

function CustomMovement takes nothing returns nothing
    local real angle
    local real dist
    local real x
    local real y
    local integer pid
    local User p = User.first

    loop
        exitwhen p == User.NULL
        set pid = GetPlayerId(p.toPlayer()) + 1

        if Moving[pid] and GetUnitAbilityLevel(Hero[pid], 'BPSE') == 0 and GetUnitAbilityLevel(Hero[pid], 'BEer') == 0 and GetUnitAbilityLevel(Hero[pid], 'BSTN') == 0 then
            if GetUnitCurrentOrder(Hero[pid]) == OrderId("stop") or GetUnitCurrentOrder(Hero[pid]) == OrderId("holdposition") or GetUnitCurrentOrder(Hero[pid]) == 0 then
                set Moving[pid] = false
            else
                set dist = DistanceCoords(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), clickedpointX[pid], clickedpointY[pid])
                if dist < 55. then
                    set Moving[pid] = false
                elseif Movespeed[pid] - 522 > 0 then
                    set angle = Atan2(clickedpointY[pid] - GetUnitY(Hero[pid]), clickedpointX[pid] - GetUnitX(Hero[pid]))
                    if RAbsBJ(angle - bj_DEGTORAD * GetUnitFacing(Hero[pid])) < bj_PI / 8. then
                        set x = GetUnitX(Hero[pid]) + (((Movespeed[pid] - 522) * 0.06) + 1) * Cos(bj_DEGTORAD * GetUnitFacing(Hero[pid]))
                        set y = GetUnitY(Hero[pid]) + (((Movespeed[pid] - 522) * 0.06) + 1) * Sin(bj_DEGTORAD * GetUnitFacing(Hero[pid]))
                        if dist > (Movespeed[pid] - 522) * 0.06 and IsTerrainWalkable(x, y) then
                            call SetUnitXBounded(Hero[pid], x)
                            call SetUnitYBounded(Hero[pid], y)
                        endif
                    endif
                endif
            endif
        endif
        
        set p = p.next
    endloop
endfunction

function PeriodicFPS takes nothing returns nothing
    local real hp
    local real mp 
    local unit target
    local location loc
    local real damage
    local real boost
    local real angle
    local group ug = CreateGroup()
    local group g
    local integer i = 1
    local integer i2 = 0
    local integer pid
    local real x
    local real y
    local User p = User.first
    
    //Shields
        
    loop
        exitwhen i > shieldindexmax
        if isShielded[i] then
            call SetUnitXBounded(shieldunit[i], GetUnitX(shieldtarget[i]))
            call SetUnitYBounded(shieldunit[i], GetUnitY(shieldtarget[i]))
            //call BlzSetSpecialEffectHeight(shieldunit[i], 350.00)
            set hp = R2I(shieldhp[i] / shieldmax[i] * 100.0)
            if hp > shieldpercent[i] then
                set shieldpercent[i] = shieldpercent[i] + 3
                call SetUnitTimeScale(shieldunit[i], 0.95)
            elseif hp < shieldpercent[i] and shieldpercent[i] - hp > 3 then
                set shieldpercent[i] = shieldpercent[i] - 3
                call SetUnitTimeScale(shieldunit[i], -0.95)
            else
                call SetUnitTimeScale(shieldunit[i], 0)
            endif
        endif
        set i = i + 1
    endloop
    
    //Ability Movement
        
    set udg_A_CB_Index = 1
    loop
        exitwhen udg_A_CB_Index > udg_A_CB_Index_Max or udg_A_CB_Index_Max == 0
        if udg_A_CB_Range[udg_A_CB_Index] > 0.00 then
            if udg_A_CB_Animation[udg_A_CB_Index] == true then
                call SetUnitAnimation( udg_A_CB_Caster[udg_A_CB_Index], "attack" )
            endif
            set udg_A_CB_Range[udg_A_CB_Index] = ( udg_A_CB_Range[udg_A_CB_Index] - 50. )
            set x = GetUnitX(udg_A_CB_Caster[udg_A_CB_Index]) + 50. *Cos(udg_A_CB_Angle[udg_A_CB_Index]*bj_DEGTORAD)
            set y = GetUnitY(udg_A_CB_Caster[udg_A_CB_Index]) + 50. *Sin(udg_A_CB_Angle[udg_A_CB_Index]*bj_DEGTORAD)
            call SetUnitPathing(udg_A_CB_Caster[udg_A_CB_Index], false)
            if udg_A_CB_Moving[udg_A_CB_Index] then
                call IssueImmediateOrder( udg_A_CB_Caster[udg_A_CB_Index], "stop" )
                call BlzSetUnitFacingEx(udg_A_CB_Caster[udg_A_CB_Index], udg_A_CB_Angle[udg_A_CB_Index])
            endif
            if IsTerrainWalkable(x, y) == false then
                set udg_A_CB_Range[udg_A_CB_Index] = 0.00
            else
                call SetUnitXBounded(udg_A_CB_Caster[udg_A_CB_Index], x)
                call SetUnitYBounded(udg_A_CB_Caster[udg_A_CB_Index], y)
            endif
            if udg_A_CB_Dmg[udg_A_CB_Index] > 0.00 then
                call MakeGroupInRange(GetPlayerId(GetOwningPlayer(udg_A_CB_Caster[udg_A_CB_Index])) + 1, ug, x, y, udg_A_CB_HitRange[udg_A_CB_Index], Condition(function FilterEnemy))
                
                loop
                    set target = FirstOfGroup(ug)
                    exitwhen target == null
                    call GroupRemoveUnit(ug, target)
                    if IsUnitInGroup(target, udg_A_CB_Targets[udg_A_CB_Index]) == false then
                        call GroupAddUnit(udg_A_CB_Targets[udg_A_CB_Index], target)
                        call UnitDamageTarget(udg_A_CB_Caster[udg_A_CB_Index], target, udg_A_CB_Dmg[udg_A_CB_Index], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                        if udg_A_CB_BuffEffect[udg_A_CB_Index] == true then
                            set udg_A_CB_BuffEffectUnit = target
                            call TriggerExecute( udg_A_CB_BuffEffectTrigger[udg_A_CB_Index] )
                            set udg_A_CB_BuffEffectUnit = null
                        endif
                    endif
                endloop
            else
                call MakeGroupInRange(GetPlayerId(GetOwningPlayer(udg_A_CB_Caster[udg_A_CB_Index])) + 1, ug, x, y, 75.0, Condition(function FilterEnemy))
                
                loop
                    set target = FirstOfGroup(ug)
                    exitwhen target == null
                    call GroupRemoveUnit(ug, target)
                    if udg_A_CB_BuffEffect[udg_A_CB_Index] == true then
                        set udg_A_CB_BuffEffectUnit = target
                        call TriggerExecute( udg_A_CB_BuffEffectTrigger[udg_A_CB_Index] )
                        set udg_A_CB_BuffEffectUnit = null
                    endif
                endloop
            endif
        else
            loop
                set target = FirstOfGroup(markedfordeath[GetPlayerId(GetOwningPlayer(udg_A_CB_Caster[udg_A_CB_Index])) + 1])
                exitwhen target == null
                call GroupRemoveUnit(markedfordeath[GetPlayerId(GetOwningPlayer(udg_A_CB_Caster[udg_A_CB_Index])) + 1], target)
                call SetUnitPathing(target, true)
            endloop
            set PhantomSlashing[GetPlayerId(GetOwningPlayer(udg_A_CB_Caster[udg_A_CB_Index])) + 1] = false
            call UnitRemoveAbility(udg_A_CB_Caster[udg_A_CB_Index], 'Aeth')
            call SetUnitPathing(udg_A_CB_Caster[udg_A_CB_Index], true)
            call SetUnitTimeScale( udg_A_CB_Caster[udg_A_CB_Index], 1.0)
            set udg_A_CB_Targets[udg_A_CB_Index] = udg_A_CB_Targets[udg_A_CB_Index_Max]
            call DestroyGroup (udg_A_CB_Targets[udg_A_CB_Index_Max])
            set udg_A_CB_Caster[udg_A_CB_Index] = udg_A_CB_Caster[udg_A_CB_Index_Max]
            set udg_A_CB_Caster[udg_A_CB_Index_Max] = null
            set udg_A_CB_Range[udg_A_CB_Index] = udg_A_CB_Range[udg_A_CB_Index_Max]
            set udg_A_CB_Range[udg_A_CB_Index_Max] = 0.00
            set udg_A_CB_Angle[udg_A_CB_Index] = udg_A_CB_Angle[udg_A_CB_Index_Max]
            set udg_A_CB_Angle[udg_A_CB_Index_Max] = 0.00
            set udg_A_CB_Index_Max = ( udg_A_CB_Index_Max - 1 )
            set udg_A_CB_Index = ( udg_A_CB_Index - 1 )
            set udg_A_CB_Dmg[udg_A_CB_Index] = udg_A_CB_Dmg[udg_A_CB_Index_Max]
            set udg_A_CB_Dmg[udg_A_CB_Index_Max] = 0.00
            set udg_A_CB_Point[udg_A_CB_Index] = udg_A_CB_Point[udg_A_CB_Index_Max]
            call RemoveLocation (udg_A_CB_Point[udg_A_CB_Index_Max])
            set udg_A_CB_Moving[udg_A_CB_Index] = udg_A_CB_Moving[udg_A_CB_Index_Max]
            set udg_A_CB_Moving[udg_A_CB_Index_Max] = false
            set udg_A_CB_Animation[udg_A_CB_Index] = udg_A_CB_Animation[udg_A_CB_Index_Max]
            set udg_A_CB_Animation[udg_A_CB_Index_Max] = false
        endif
        set udg_A_CB_Index = udg_A_CB_Index + 1
    endloop
    
    //Projectile Movement
    
    set udg_PS_Index = 1
    loop
        exitwhen udg_PS_Index > udg_PS_Index_Max
        set udg_TempPointCF[1] = GetUnitLoc(udg_PS_Dummy[udg_PS_Index])
        if udg_PS_Range[udg_PS_Index] > 0.00 then
            set udg_PS_Range[udg_PS_Index] = ( udg_PS_Range[udg_PS_Index] - udg_PS_Speed[udg_PS_Index] )
            if udg_PS_HitTerrain[udg_PS_Index] == true then
                if IsTerrainWalkable(GetLocationX(udg_TempPointCF[1]), GetLocationY(udg_TempPointCF[1])) == false then
                    set udg_PS_Range[udg_PS_Index] = 0
                endif
            endif
            set udg_TempPointCF[2] = PolarProjectionBJ(udg_TempPointCF[1], udg_PS_Speed[udg_PS_Index], udg_PS_Angle[udg_PS_Index])
            call MakeGroupInRange(GetPlayerId(GetOwningPlayer(udg_PS_Caster[udg_PS_Index])) + 1, ug, GetLocationX(udg_TempPointCF[1]), GetLocationY(udg_TempPointCF[1]), udg_PS_HitRange[udg_PS_Index], Condition(function FilterEnemy))
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                set udg_TempPointCF[3] = GetUnitLoc(target)
                if DistanceBetweenPoints(udg_TempPointCF[1], udg_TempPointCF[3]) <= udg_PS_HitRange[udg_PS_Index] then
                    if udg_PS_Pierce[udg_PS_Index] == false then
                        set udg_PS_Range[udg_PS_Index] = 0
                        call DestroyEffectTimed(AddSpecialEffectLoc( udg_PS_HitEffect[udg_PS_Index], udg_TempPointCF[1] ), 1.)
                        set udg_PS_NoHitEff[udg_PS_Index] = false
                        if udg_PS_Aoe[udg_PS_Index] > 0.00 then
                            set g = CreateGroup()
                            call MakeGroupInRange(GetPlayerId(GetOwningPlayer(udg_PS_Caster[udg_PS_Index])) + 1, g, GetLocationX(udg_TempPointCF[1]), GetLocationY(udg_TempPointCF[1]), udg_PS_Aoe[udg_PS_Index], Condition(function FilterEnemy))
                            loop
                                set target = FirstOfGroup(g)
                                exitwhen target == null
                                call GroupRemoveUnit(g, target)
                                if udg_PS_BuffEffect[udg_PS_Index] == true then
                                    set udg_PS_BuffEffectUnit = target
                                    call TriggerExecute( udg_PS_BuffEffectTrigger[udg_PS_Index] )
                                    set udg_PS_BuffEffectUnit = null
                                endif
                                call UnitDamageTarget( udg_PS_Caster[udg_PS_Index], target, udg_PS_Damage[udg_PS_Index], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
                            endloop
                            call DestroyGroup(g)
                        else
                            call UnitDamageTarget( udg_PS_Caster[udg_PS_Index], target, udg_PS_Damage[udg_PS_Index], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
                            if udg_PS_BuffEffect[udg_PS_Index] == true then
                                set udg_PS_BuffEffectUnit = target
                                call TriggerExecute( udg_PS_BuffEffectTrigger[udg_PS_Index] )
                                set udg_PS_BuffEffectUnit = null
                            endif
                        endif
                        exitwhen true
                    else
                        if IsUnitInGroup(target, udg_PS_DamagedUnits[udg_PS_Index]) == false then
                            call DestroyEffectTimed(AddSpecialEffectTarget( udg_PS_HitEffect[udg_PS_Index], target, "chest" ), 1.)
                            call GroupAddUnit( udg_PS_DamagedUnits[udg_PS_Index], target )
                            if udg_PS_BuffEffect[udg_PS_Index] == true then
                                set udg_PS_BuffEffectUnit = target
                                call TriggerExecute( udg_PS_BuffEffectTrigger[udg_PS_Index] )
                                set udg_PS_BuffEffectUnit = null
                            endif
                            call UnitDamageTarget( udg_PS_Caster[udg_PS_Index], target, udg_PS_Damage[udg_PS_Index], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
                        endif
                    endif
                endif
                call RemoveLocation (udg_TempPointCF[3])
            endloop
            //ie frozen orb
            if MISSILE_EXPIRE_AOE[udg_PS_Index] and udg_PS_Range[udg_PS_Index] <= 0 then
                set g = CreateGroup()
                call MakeGroupInRange(GetPlayerId(GetOwningPlayer(udg_PS_Caster[udg_PS_Index])) + 1, g, GetLocationX(udg_TempPointCF[2]), GetLocationY(udg_TempPointCF[2]), udg_PS_Aoe[udg_PS_Index], Condition(function FilterEnemy))
                call DestroyEffectTimed(AddSpecialEffectLoc(udg_PS_HitEffect[udg_PS_Index_Max], udg_TempPointCF[1]), 1.)
                loop
                    set target = FirstOfGroup(g)
                    exitwhen target == null
                    call GroupRemoveUnit(g, target)
                    if udg_PS_BuffEffect[udg_PS_Index] == true then
                        set udg_PS_BuffEffectUnit = target
                        call TriggerExecute( udg_PS_BuffEffectTrigger[udg_PS_Index] )
                        set udg_PS_BuffEffectUnit = null
                    endif
                    call UnitDamageTarget( udg_PS_Caster[udg_PS_Index], target, udg_PS_Damage[udg_PS_Index], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
                endloop
                call DestroyGroup(g)
            endif
            call SetUnitPathing(udg_PS_Dummy[udg_PS_Index], false)
            call SetUnitXBounded(udg_PS_Dummy[udg_PS_Index], GetLocationX(udg_TempPointCF[2]))
            call SetUnitYBounded(udg_PS_Dummy[udg_PS_Index], GetLocationY(udg_TempPointCF[2]))
            call RemoveLocation (udg_TempPointCF[1])
            call RemoveLocation (udg_TempPointCF[2])
        else
            call RemoveLocation (udg_TempPointCF[1])
            call DestroyEffect( udg_PS_Dummy_Effect[udg_PS_Index] )
            call GroupClear( udg_PS_DamagedUnits[udg_PS_Index] )
            call BlzGroupAddGroupFast( udg_PS_DamagedUnits[udg_PS_Index_Max], udg_PS_DamagedUnits[udg_PS_Index] )
            call DestroyGroup (udg_PS_DamagedUnits[udg_PS_Index_Max])
            if GetUnitTypeId(udg_PS_Dummy[udg_PS_Index]) == DUMMY then
                call RecycleDummy(udg_PS_Dummy[udg_PS_Index])
            else
                call UnitApplyTimedLife(udg_PS_Dummy[udg_PS_Index], 'BTLF', 0.5)
            endif
            set udg_PS_BuffEffectTrigger[udg_PS_Index] = udg_PS_BuffEffectTrigger[udg_PS_Index_Max]
            set udg_PS_BuffEffectTrigger[udg_PS_Index_Max] = null
            set udg_PS_BuffEffect[udg_PS_Index] = udg_PS_BuffEffect[udg_PS_Index_Max]
            set udg_PS_BuffEffect[udg_PS_Index_Max] = false
            set udg_PS_Caster[udg_PS_Index] = udg_PS_Caster[udg_PS_Index_Max]
            set udg_PS_Caster[udg_PS_Index_Max] = null
            set udg_PS_Dummy[udg_PS_Index] = udg_PS_Dummy[udg_PS_Index_Max]
            set udg_PS_Dummy[udg_PS_Index_Max] = null
            set udg_PS_Angle[udg_PS_Index] = udg_PS_Angle[udg_PS_Index_Max]
            set udg_PS_Angle[udg_PS_Index_Max] = 0.00
            set udg_PS_Aoe[udg_PS_Index] = udg_PS_Aoe[udg_PS_Index_Max]
            set udg_PS_Aoe[udg_PS_Index_Max] = 0.00
            set udg_PS_Damage[udg_PS_Index] = udg_PS_Damage[udg_PS_Index_Max]
            set udg_PS_Damage[udg_PS_Index_Max] = 0.00
            set udg_PS_HitRange[udg_PS_Index] = udg_PS_HitRange[udg_PS_Index_Max]
            set udg_PS_HitRange[udg_PS_Index_Max] = 0.00
            set udg_PS_Range[udg_PS_Index] = udg_PS_Range[udg_PS_Index_Max]
            set udg_PS_Range[udg_PS_Index_Max] = 0.00
            set udg_PS_Speed[udg_PS_Index] = udg_PS_Speed[udg_PS_Index_Max]
            set udg_PS_Speed[udg_PS_Index_Max] = 0.00
            set udg_PS_HitTerrain[udg_PS_Index] = udg_PS_HitTerrain[udg_PS_Index_Max]
            set udg_PS_HitTerrain[udg_PS_Index_Max] = false
            set udg_PS_HitTerrainDMGS[udg_PS_Index] = udg_PS_HitTerrainDMGS[udg_PS_Index_Max]
            set udg_PS_HitTerrainDMGS[udg_PS_Index_Max] = false
            set udg_PS_Pierce[udg_PS_Index] = udg_PS_Pierce[udg_PS_Index_Max]
            set udg_PS_Pierce[udg_PS_Index_Max] = false
            set udg_PS_NoHitEff[udg_PS_Index] = udg_PS_NoHitEff[udg_PS_Index_Max]
            set udg_PS_NoHitEff[udg_PS_Index_Max] = false
            set udg_PS_Dummy_Effect[udg_PS_Index] = udg_PS_Dummy_Effect[udg_PS_Index_Max]
            set udg_PS_Dummy_Effect[udg_PS_Index_Max] = null
            set udg_PS_HitEffect[udg_PS_Index] = udg_PS_HitEffect[udg_PS_Index_Max]
            set udg_PS_HitEffect[udg_PS_Index_Max] = ""
            set MISSILE_EXPIRE_AOE[udg_PS_Index] = MISSILE_EXPIRE_AOE[udg_PS_Index_Max]
            set MISSILE_EXPIRE_AOE[udg_PS_Index_Max] = false
            set udg_PS_Index_Max = ( udg_PS_Index_Max - 1 )
            set udg_PS_Index = ( udg_PS_Index - 1 )
        endif
        set udg_PS_Index = udg_PS_Index + 1
    endloop

    loop
        exitwhen p == User.NULL
        set pid = GetPlayerId(p.toPlayer()) + 1
        
            //Ability Loops
            
            //Phoenix Ranger Phoenix Flight
            
            if udg_DashDistance[pid] > 0 and HeroID[pid] == HERO_PHOENIX_RANGER then
                if DistanceCoords(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), GetUnitX(udg_DashDummy[pid]), GetUnitY(udg_DashDummy[pid])) < 250. then
                    call BlzSetUnitFacingEx(udg_DashDummy[pid], udg_DashAngleR[pid] * bj_RADTODEG)
                    set loc=Location(GetUnitX(udg_DashDummy[pid]) +33 *Cos(udg_DashAngleR[pid]), GetUnitY(udg_DashDummy[pid]) +33 *Sin(udg_DashAngleR[pid]))
                    set boost= BOOST(pid)
                    set damage=GetHeroAgi(Hero[pid],true) *1.5 *boost
                    call SetUnitPathing(Hero[pid], false)
                    call SetUnitXBounded(Hero[pid], GetLocationX(loc))
                    call SetUnitYBounded(Hero[pid], GetLocationY(loc))
                    call SetUnitPositionLoc(udg_DashDummy[pid], loc)
                    call MakeGroupInRange(pid, ug, GetLocationX(loc), GetLocationY(loc), 250*boost, Condition(function FilterEnemy))
                    call RemoveLocation(loc)
                    loop
                        set target=FirstOfGroup(ug)
                        exitwhen target == null
                        call GroupRemoveUnit(ug, target)
                        if IsUnitInGroup(target, PhoenixHit[pid])==false then
                            call GroupAddUnit(PhoenixHit[pid], target)
                            call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl",GetUnitX(target),GetUnitY(target)))
                            call UnitDamageTarget(Hero[pid],target,damage,true,false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
                            if GetUnitAbilityLevel(target, 'B02O') > 0 then
                                call UnitRemoveAbility(target, 'B02O')
                                call SearingArrowIgnite(target, pid)
                            endif
                        endif
                    endloop
                    set udg_DashDistance[pid]=udg_DashDistance[pid] - 33
                    if udg_DashDistance[pid] <= 0 then
                        set udg_DashDistance[pid]=0
                        call KillUnit(udg_DashDummy[pid])
                        call RemoveUnitTimed(udg_DashDummy[pid], 2)
                        call UnitRemoveAbility(Hero[pid], 'Avul')
                        call ShowUnit(Hero[pid], true)
                        call reselect(Hero[pid])
                        call SetUnitPathing(Hero[pid], true)
                        call GroupClear(PhoenixHit[pid])
                        call RemoveLocation(FlightTarget[pid])
                        call EnterWeather(Hero[pid])
                    endif
                else
                    set udg_DashDistance[pid] = 0
                    call KillUnit(udg_DashDummy[pid])
                    call RemoveUnitTimed(udg_DashDummy[pid], 2)
                    call UnitRemoveAbility(Hero[pid], 'Avul')
                    call ShowUnit(Hero[pid], true)
                    call reselect(Hero[pid])
                    call SetUnitPathing(Hero[pid], true)
                    call GroupClear(PhoenixHit[pid])
                    call RemoveLocation(FlightTarget[pid])
                    call EnterWeather(Hero[pid])
                endif
            
            //Warrior Leap
            
            elseif udg_DashDistance[pid] > 0 and HeroID[pid] == HERO_WARRIOR then
                if DistanceCoords(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), GetLocationX(FlightTarget[pid]), GetLocationY(FlightTarget[pid])) < 1000. then
                    set x= udg_DashDistance[pid] / initDistance[pid]
                    call SetUnitXBounded(Hero[pid], GetUnitX(Hero[pid]) + (40 / (1 + x)) * Cos(udg_DashAngleR[pid]))
                    call SetUnitYBounded(Hero[pid], GetUnitY(Hero[pid]) + (40 / (1 + x)) * Sin(udg_DashAngleR[pid]))
                    set udg_DashDistance[pid]=udg_DashDistance[pid] - (40 / (1 + x))
                    if udg_DashDistance[pid] <= initDistance[pid] - 120 and udg_DashDistance[pid] >= initDistance[pid] - 160 then //sick animation
                        call SetUnitTimeScale(Hero[pid], 0)
                    endif
                    set x= udg_DashDistance[pid] / initDistance[pid]
                    call SetUnitFlyHeight(Hero[pid],20 +initDistance[pid]*(1.-x)*x*1.3,0)
                    
                    if udg_DashDistance[pid] <= 0 then
                        set boost= BOOST(pid)
                        set udg_DashDistance[pid]=0
                        set damage= ( UnitGetBonus(Hero[pid],BONUS_DAMAGE) +GetHeroStr(Hero[pid], true)*2 ) *.35 *GetUnitAbilityLevel(Hero[pid],'A0EE') *boost
                        call SetUnitXBounded(Hero[pid], GetLocationX(FlightTarget[pid]))
                        call SetUnitYBounded(Hero[pid], GetLocationY(FlightTarget[pid]))
                        call SetUnitFlyHeight(Hero[pid], 0, 0)
                        call reselect(Hero[pid])
                        call SetUnitTimeScale(Hero[pid], 1.)
                        call SetUnitPropWindow(Hero[pid], 60.)
                        call SetUnitPathing(Hero[pid], true)
                        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(Hero[pid]), GetUnitY(Hero[pid])))
                        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 300 * LBOOST(pid), Condition(function FilterEnemy))
                        loop
                            set target = FirstOfGroup(ug)
                            exitwhen target == null
                            call GroupRemoveUnit(ug, target)
                            call UnitDamageTarget(Hero[pid], target, damage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                        endloop
                        call RemoveLocation(FlightTarget[pid])
                    endif
                else
                    set udg_DashDistance[pid] = 0
                    call SetUnitFlyHeight(Hero[pid], 0, 0)
                    call reselect(Hero[pid])
                    call SetUnitTimeScale(Hero[pid], 1.)
                    call SetUnitPropWindow(Hero[pid], 60.)
                    call SetUnitPathing(Hero[pid], true)
                    call RemoveLocation(FlightTarget[pid])
                endif
            
            //Bloodzerker Leap
            
            elseif udg_DashDistance[pid] > 0 and HeroID[pid] == HERO_BLOODZERKER then
                if DistanceCoords(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), GetLocationX(FlightTarget[pid]), GetLocationY(FlightTarget[pid])) < 1000. then
                    set x= udg_DashDistance[pid] / initDistance[pid]
                    call SetUnitXBounded(Hero[pid], GetUnitX(Hero[pid]) + (40 / (1 + x)) * Cos(udg_DashAngleR[pid]))
                    call SetUnitYBounded(Hero[pid], GetUnitY(Hero[pid]) + (40 / (1 + x)) * Sin(udg_DashAngleR[pid]))
                    set udg_DashDistance[pid]=udg_DashDistance[pid] - (40 / (1 + x))
                    if udg_DashDistance[pid] <= initDistance[pid] - 120 and udg_DashDistance[pid] >= initDistance[pid] - 160 then //sick animation
                        call SetUnitTimeScale(Hero[pid], 0)
                    endif
                    set x= udg_DashDistance[pid] / initDistance[pid]
                    call SetUnitFlyHeight(Hero[pid],20 +initDistance[pid]*(1.-x)*x*1.3,0)
                    if udg_DashDistance[pid] <= 0 then
                        if DistanceCoords(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), GetLocationX(FlightTarget[pid]), GetLocationY(FlightTarget[pid])) < 25 then
                            call SetUnitXBounded(Hero[pid], GetLocationX(FlightTarget[pid]))
                            call SetUnitYBounded(Hero[pid], GetLocationY(FlightTarget[pid]))
                        endif
                        call SetUnitFlyHeight(Hero[pid], 0, 0)
                        set boost= BOOST(pid)
                        set udg_DashDistance[pid]=0
                        set damage = (((UnitGetBonus(Hero[pid],BONUS_DAMAGE) + GetHeroStr(Hero[pid], true)) * 0.25 * GetUnitAbilityLevel(Hero[pid], 'A05Z')) + (GetHeroStr(Hero[pid], true) * GetUnitAbilityLevel(Hero[pid], 'A05Z'))) * boost
                        call reselect(Hero[pid])
                        call SetUnitTimeScale(Hero[pid], 1.)
                        call SetUnitPropWindow(Hero[pid], 60.)
                        call SetUnitPathing(Hero[pid], true)
                        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(Hero[pid]), GetUnitY(Hero[pid])))
                        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 260.00 * LBOOST(pid), Condition(function FilterEnemy))
                        if rampageActive[pid] then //rampage bonus
                            set damage = damage * (1 + 0.2 * GetUnitAbilityLevel(Hero[pid], 'A0GZ'))
                        endif
                        loop
                            set target = FirstOfGroup(ug)
                            exitwhen target == null
                            call GroupRemoveUnit(ug, target)
                            call UnitDamageTarget(Hero[pid], target, damage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                        endloop
                        call RemoveLocation(FlightTarget[pid])
                        call GroupClear(ug)
                    endif
                else
                    set udg_DashDistance[pid] = 0
                    call SetUnitFlyHeight(Hero[pid], 0, 0)
                    call reselect(Hero[pid])
                    call SetUnitTimeScale(Hero[pid], 1.)
                    call SetUnitPropWindow(Hero[pid], 60.)
                    call SetUnitPathing(Hero[pid], true)
                    call RemoveLocation(FlightTarget[pid])
                endif
            
            //Thunderblade Thunder Dash
            
            elseif udg_DashDistance[pid] > 0 and HeroID[pid] == HERO_THUNDERBLADE then
                set x = GetUnitX(udg_DashDummy[pid]) + 35 * Cos(udg_DashAngleR[pid])
                set y = GetUnitY(udg_DashDummy[pid]) + 35 * Sin(udg_DashAngleR[pid])
                if DistanceCoords(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), x, y) < 250. then
                    call SetUnitXBounded(udg_DashDummy[pid], x)
                    call SetUnitYBounded(udg_DashDummy[pid], y)
                    call SetUnitPosition(Hero[pid], x, y)
                    set udg_DashDistance[pid] = udg_DashDistance[pid] - 35
                    if udg_DashDistance[pid] < (GetUnitAbilityLevel(Hero[pid], 'A095') + 3) * 150 - 200 then
                        call MakeGroupInRange(pid, ug, x, y, 150.00, Condition(function FilterEnemy))
                        if BlzGroupGetSize(ug) > 0 or IsTerrainWalkable(x, y) == false then //check for hit
                            set udg_DashDistance[pid] = 0
                            set damage = GetHeroAgi(Hero[pid],true) * 2 * BOOST(pid)
                            if GetUnitAbilityLevel(Hero[pid],'B0ov') > 0  then
                                set damage = damage * (1 + 0.1 *GetUnitAbilityLevel(Hero[pid],'A096'))
                            endif
                            call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x,y))
                            call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x+140,y+140))
                            call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x+140,y-140))
                            call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x-140,y+140))
                            call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x-140,y-140))
                            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x,y))
                            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x+100,y+100))
                            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x+100,y-100))
                            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x-100,y+100))
                            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x-100,y-100))
                            call MakeGroupInRange(pid, ug, x, y, 260 * LBOOST(pid), Condition(function FilterEnemy))
                            loop
                                set target = FirstOfGroup(ug)
                                exitwhen target == null
                                call GroupRemoveUnit(ug, target)
                                call UnitDamageTarget(Hero[pid], target, damage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                            endloop
                        endif
                    endif
                    if udg_DashDistance[pid] <= 0 then
                        call SetUnitAnimation(udg_DashDummy[pid], "death")
                        call ShowUnit(Hero[pid], true)
                        call reselect(Hero[pid])
                        call UnitRemoveAbility(Hero[pid], 'Avul')
                        call BlzPauseUnitEx(Hero[pid], false)
                        call SetUnitPathing(Hero[pid], true)
                        call EnterWeather(Hero[pid])
                    endif
                    call GroupClear(ug)
                else
                    call SetUnitAnimation(udg_DashDummy[pid], "death")
                    set udg_DashDistance[pid] = 0
                    call ShowUnit(Hero[pid], true)
                    call reselect(Hero[pid])
                    call UnitRemoveAbility(Hero[pid], 'Avul')
                    call BlzPauseUnitEx(Hero[pid], false)
                    call SetUnitPathing(Hero[pid], true)
                    call EnterWeather(Hero[pid])
                endif
            endif
            
            //Elite Marksman
            
            if HeroID[pid] == HERO_MARKSMAN then
                //grenade
                if GetWidgetLife(grenade[pid]) >= 0.406 then
                    if udg_DashDistance[pid] > 0 then
                        call SetUnitPosition(grenade[pid], GetUnitX(grenade[pid]) + 22.01 *Cos(udg_DashAngleR[pid]), GetUnitY(grenade[pid]) + 22.01 *Sin(udg_DashAngleR[pid]))
                        set udg_DashDistance[pid] = udg_DashDistance[pid] - 22.01
                        call SetUnitFlyHeight(grenade[pid],50 +initDistance[pid]*(1.-udg_DashDistance[pid] / initDistance[pid])*udg_DashDistance[pid] / initDistance[pid]*1.3,0)
                    endif
                
                    if udg_DashDistance[pid] < 0 then
                        set udg_DashDistance[pid] = 0
                        call SetUnitPositionLoc(grenade[pid], FlightTarget[pid])
                        call SetUnitFlyHeight(grenade[pid], 10, 0)
                        call SetUnitTimeScalePercent(grenade[pid], 0)
                        call TimerStart(NewTimerEx(pid), 2., false, function HandGrenade)
                    endif
                endif

                //heli text follow
                if helitag[pid] != null and GetWidgetLife(helicopter[pid]) >= 0.406 then
                    call SetTextTagPosUnit(helitag[pid], helicopter[pid], -200.)
                endif
            endif
            
            //Camera Lock
            
            if hselection[pid] then
                if (GetLocalPlayer() == p.toPlayer()) then
                    call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, 500, 0 )
                    call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, 340, 0 )
                    call SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, 60, 0 )
                    call SetCameraField(CAMERA_FIELD_ZOFFSET, 200, 0 )
                    call SetCameraField(CAMERA_FIELD_ROTATION, GetUnitFacing(hstarget[hslook[pid]]) + 180, 0 )
                    call SetCameraTargetController(gg_unit_h00T_0511, 0, 0, false)
                endif
            elseif CameraLock[pid] then
                if (GetLocalPlayer() == p.toPlayer()) then
                    call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, udg_Zoom[pid], 0 )
                endif
            endif

        set p = p.next
    endloop
    
    call DestroyGroup(ug)
    
    set loc = null
    set target = null
    set ug = null
    set g = null
endfunction

//===========================================================================
function TimerInit takes nothing returns nothing
    //local trigger periodic = CreateTrigger()
    //local trigger movement = CreateTrigger()
    local trigger thirtymin = CreateTrigger()
    local trigger fivemin = CreateTrigger()
    local trigger min = CreateTrigger()
    local trigger prechaosrespawn = CreateTrigger()
    local trigger onepointfive = CreateTrigger()
    local trigger savetimer = CreateTrigger()
    local trigger sixseconds = CreateTrigger()
    local trigger onesecond = CreateTrigger()
    local trigger pointthreefive = CreateTrigger()
    local trigger coloxp = CreateTrigger()
    local trigger struggle = CreateTrigger()
    local trigger wandering = CreateTrigger()
    local User u = User.first
    
    call TimerStart(NewTimer(), 0.03, true, function PeriodicFPS)
    call TimerStart(NewTimer(), 0.06, true, function CustomMovement)
    
    call TriggerRegisterTimerEvent(pointthreefive, 0.35, true)
    call TriggerAddAction(pointthreefive, function Periodic)
    call TriggerAddAction(pointthreefive, function SmokebombEvasion)
    call TriggerAddAction(pointthreefive, function FightMeInvuln)
    
    call TriggerRegisterTimerEvent(onesecond, 1.00, true)
    call TriggerAddAction(onesecond, function OneSecond)
    
    call TriggerRegisterTimerEvent(onepointfive, 1.50, true)
    call TriggerAddAction(onepointfive, function LavaBurn)
    
    call TriggerRegisterTimerEvent(sixseconds, 6.00, true)
    call TriggerAddAction(sixseconds, function HelicopterSwap)
    
    call TriggerRegisterTimerExpireEvent(struggle, strugglespawn)
    call TriggerAddAction(struggle, function SpawnStruggleUnits)
    
    call TriggerRegisterTimerEvent(coloxp, 15.00, true)
    call TriggerAddAction(coloxp, function WanderingGuys)
    call TriggerAddAction(coloxp, function ColosseumXPDecrease)
    
    call TriggerRegisterTimerEvent(min, 60.00, true)
    call TriggerAddAction(min, function TimePlayed)
    call TriggerAddAction(min, function ColosseumXPIncrease)
    call TriggerAddAction(min, function SpawnForgotten)
    
    //call TriggerRegisterTimerEvent(prechaosrespawn, 120.00, true)
    
    call TriggerRegisterTimerEvent(fivemin, 300.00, true)
    call ShopkeeperMove()
    call TriggerAddAction(fivemin, function ShopkeeperMove)
    call TriggerAddAction(fivemin, function CreateWell)

    call TriggerRegisterTimerEvent(thirtymin, 1800.00, true)
    call TriggerAddAction(thirtymin, function AFKClock)

    call TriggerRegisterTimerEvent(wandering, 34. - (User.AmountPlaying * 4), false)
    call TriggerAddCondition(wandering, Filter(function ShadowStepExpire))
    
    loop
        exitwhen u == User.NULL
        set SaveTimer[u.id] = CreateTimer()
        call TriggerRegisterTimerExpireEvent(savetimer, SaveTimer[u.id])
        set u = u.next
    endloop
    
    call TriggerAddAction( savetimer, function Trig_SaveTimer_Actions )
    
    //set periodic = null
    //set movement = null
    set thirtymin = null
    set fivemin = null
    set min = null
    set onepointfive = null
    set sixseconds = null
    set onesecond = null
    set pointthreefive = null
    set savetimer = null
    set prechaosrespawn = null
    set coloxp = null
    set struggle = null
endfunction

endlibrary
