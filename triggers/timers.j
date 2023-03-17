library Timers requires Functions, TimerUtils, Commands, Dungeons, Bosses, Spells, TerrainPathability

globals
    boolean array MISSILE_EXPIRE_AOE
    group HeroGroup = CreateGroup()
    timer array SaveTimer
    real array LAST_HERO_X
    real array LAST_HERO_Y
    timer wanderingTimer = CreateTimer()
endglobals

function BossBonusLinger takes nothing returns nothing
    local integer i = ReleaseTimer(GetExpiredTimer())
    local integer index = 0
    local integer count = BlzGroupGetSize(HeroGroup)
    local integer numplayers = 0

    if CWLoading == false and GetWidgetLife(Boss[i]) >= 0.406 then
        loop
            if IsUnitInRange(BlzGroupUnitAt(HeroGroup, index), Boss[i], NEARBY_BOSS_RANGE) then
                set numplayers = numplayers + 1
            endif
            set index = index + 1
            exitwhen index >= count
        endloop

        set BossNearbyPlayers[i] = numplayers
    endif
endfunction

function ReturnBoss takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer i = GetTimerData(t)
    local real angle

    if GetWidgetLife(Boss[i]) >= 0.406 and not CWLoading then
        set angle = Atan2(GetLocationY(BossLoc[i]) - GetUnitY(Boss[i]), GetLocationX(BossLoc[i]) - GetUnitX(Boss[i]))
        if IsUnitInRangeLoc(Boss[i], BossLoc[i], 100.) then
            call ReleaseTimer(t)
            call SetUnitMoveSpeed(Boss[i], GetUnitDefaultMoveSpeed(Boss[i]))
            call SetUnitPathing(Boss[i], true)
            call UnitRemoveAbility(Boss[i], 'Amrf')
            call SetUnitTurnSpeed(Boss[i], GetUnitDefaultTurnSpeed(Boss[i]))
        else
            call SetUnitXBounded(Boss[i], GetUnitX(Boss[i]) + 20. * Cos(angle))
            call SetUnitYBounded(Boss[i], GetUnitY(Boss[i]) + 20. * Sin(angle))
            call IssuePointOrder(Boss[i], "move", GetUnitX(Boss[i]) + 70. * Cos(angle), GetUnitY(Boss[i]) + 70. * Sin(angle))
        endif
    else
        call ReleaseTimer(t)
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

function Periodic takes nothing returns boolean
    local integer pid
    local integer pid2
    local integer i = 0
    local integer i2 = 0
    local real x
    local real y
    local User u = User.first
    local User u2
    local boolean isInvuln
    local unit target
    local unit target2
    local group ug = CreateGroup()
    local PlayerTimer pt
    local integer ablev = 0

    //fight me invulnerability
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
        set u = User.first
        set isInvuln = false
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        loop
            exitwhen u == User.NULL
            set pid2 = GetPlayerId(u.toPlayer()) + 1
            
            if FightMe[pid2] and IsUnitInRange(target, Hero[pid2], 800. * BOOST(pid2)) then
                set isInvuln = true
            endif
                    
            set u = u.next
        endloop
                
        if isInvuln == false then
            call GroupRemoveUnit(FightMeGroup, target)
            call UnitRemoveAbility(target, 'Avul')
        endif
    endloop
    
    call DestroyGroup(ug)

    set u = User.first
    
    loop
        exitwhen u == User.NULL
        set pid = GetPlayerId(u.toPlayer()) + 1

        //player shit

        if HeroID[pid] > 0 then

            //backpack move
            if isteleporting[pid] == false then
                set x = GetUnitX(Hero[pid]) + 50 * Cos((GetUnitFacing(Hero[pid]) - 45) * bj_DEGTORAD)
                set y = GetUnitY(Hero[pid]) + 50 * Sin((GetUnitFacing(Hero[pid]) - 45) * bj_DEGTORAD)
                if IsUnitInRange(Hero[pid], Backpack[pid], 1000.) == false then
                    call SetUnitXBounded(Backpack[pid], x)
                    call SetUnitYBounded(Backpack[pid], y)
                elseif bpmoving[pid] == false or IsUnitInRange(Hero[pid], Backpack[pid], 800.) == false then
                    if IsUnitInRange(Hero[pid], Backpack[pid], 50.) == false then
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
                
                call GroupEnumUnitsInRangeEx(pid, helitargets[pid], GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 1200., Condition(function FilterEnemyAwake))
            
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

            //meta duration update
            set ablev = GetUnitAbilityLevel(Hero[pid], 'A02S')
            if ablev > 0 then
                call BlzSetAbilityRealLevelField(BlzGetUnitAbility(Hero[pid], 'A02S'), ABILITY_RLF_DURATION_HERO, ablev - 1, (5. + 5. * ablev) * LBOOST(pid))
            endif

            //steed charge meta duration update
            set ablev = GetUnitAbilityLevel(Hero[pid], 'A06K')
            if ablev > 0 then
                call BlzSetAbilityRealLevelField(BlzGetUnitAbility(Hero[pid], 'A06K'), ABILITY_RLF_DURATION_HERO, ablev - 1, 10. * LBOOST(pid))
            endif

            //dark seal bonuses
            if darkSealActive[pid] then
                set pt = TimerList[pid].getTimerWithTargetTag(Hero[pid], 'Dksl')
                if pt != 0 then
                    set i = 0
                    set i2 = BlzGroupGetSize(pt.ug)
                    set x = 0.
                    if i2 > 0 then
                        loop
                            set target = BlzGroupUnitAt(pt.ug, i)
                            if IsUnitType(target, UNIT_TYPE_HERO) then
                                set x = x + 10.
                            else
                                set x = x + 1.
                            endif

                            set i = i + 1
                            exitwhen i >= i2
                        endloop
                    endif
                    set x = RMinBJ(5. + GetHeroLevel(Hero[pid]) / 100 * 10, x)
                    set BoostValue[pid] = BoostValue[pid] + x * 0.01
                    call BlzSetUnitAttackCooldown(Hero[pid], BlzGetUnitAttackCooldown(Hero[pid], 0) + darkSealBAT[pid], 0)
                    set darkSealBAT[pid] = BlzGetUnitAttackCooldown(Hero[pid], 0) * x * 0.01
                    call BlzSetUnitAttackCooldown(Hero[pid], BlzGetUnitAttackCooldown(Hero[pid], 0) - darkSealBAT[pid], 0)
                endif
            endif

            set i = 0
            
            //damage taken
            set DmgTaken[pid] = RMaxBJ(0, DmgBase[pid] * ItemTotaldef[pid] * DR_mod[pid]) //prestige bonus
            set SpellTaken[pid] = RMaxBJ(0, SpellTakenBase[pid] * ItemTotaldef[pid] * ItemSpelldef[pid] * DR_mod[pid])
            
            if GetUnitAbilityLevel(Hero[pid], 'B01V') > 0 then //master of elements (earth)
                set DmgTaken[pid] = DmgTaken[pid] * 0.75
                set SpellTaken[pid] = SpellTaken[pid] * 0.75
            endif
            if HeroID[pid] == HERO_VAMPIRE and GetUnitAbilityLevel(Hero[pid], 'A097') > 0 and GetHeroStr(Hero[pid], true) > GetHeroAgi(Hero[pid], true) then //vampire str resist
                set DmgTaken[pid] = DmgTaken[pid] * (1 - 0.01 * (BloodBank[pid] / (GetHeroInt(Hero[pid], true) * 10)))
                set SpellTaken[pid] = SpellTaken[pid] * (1 - 0.01 * (BloodBank[pid] / (GetHeroInt(Hero[pid], true) * 10)))
            endif
            if GetUnitAbilityLevel(Hero[pid], 'B024') > 0 then //arcane aura
                set SpellTaken[pid] = SpellTaken[pid] * RMaxBJ(0.96 - 0.01 * ArcaneAura(pid), 0.8)
            endif
            if GetUnitAbilityLevel(Hero[pid], 'A01B') > 0 then //song of peace
                set DmgTaken[pid] = DmgTaken[pid] * 0.8
                set SpellTaken[pid] = SpellTaken[pid] * 0.8 
            endif 
            if GetUnitAbilityLevel(Hero[pid], 'B056') > 0 then //darkest of darkness
                set DmgTaken[pid] = DmgTaken[pid] * 0.6
                set SpellTaken[pid] = SpellTaken[pid] * 0.6
            endif
            if GetUnitAbilityLevel(Hero[pid], 'A05T') > 0 then //magnetic stance
                set DmgTaken[pid] = DmgTaken[pid] * (0.95 - 0.05 * GetUnitAbilityLevel(Hero[pid], 'A05R'))
                set SpellTaken[pid] = SpellTaken[pid] * (0.95 - 0.05 * GetUnitAbilityLevel(Hero[pid], 'A05R'))
            endif
            if GetUnitAbilityLevel(Hero[pid], 'A09I') > 0 then //protected
                set DmgTaken[pid] = DmgTaken[pid] * (0.93 - 0.02 * GetUnitAbilityLevel(Buff.get(null, Hero[pid], ProtectedBuff.typeid).source, 'A0HS'))
                set SpellTaken[pid] = SpellTaken[pid] * (0.93 - 0.02 * GetUnitAbilityLevel(Buff.get(null, Hero[pid], ProtectedBuff.typeid).source, 'A0HS'))
            endif
            if TimerList[pid].hasTimerWithTag('omni') then //omnislash 80% reduction 
                set DmgTaken[pid] = DmgTaken[pid] * 0.2
                set SpellTaken[pid] = SpellTaken[pid] * 0.2
            endif
            if GetUnitAbilityLevel(Hero[pid], 'B018') > 0 then
                set SpellTaken[pid] = 0
            endif
            
            //evasion
            set TotalEvasion[pid] = 0

            if GetUnitAbilityLevel(Hero[pid], 'Asmk') > 0 then //assassin smokebomb
                set target = Buff.get(null, Hero[pid], SmokebombBuff.typeid).source

                if target == Hero[pid] then
                    set TotalEvasion[pid] = TotalEvasion[pid] + (9 + GetUnitAbilityLevel(Hero[pid], 'A01E')) * 2
                else
                    set TotalEvasion[pid] = TotalEvasion[pid] + 9 + GetUnitAbilityLevel(target, 'A01E')
                endif
            endif

            set TotalEvasion[pid] = TotalEvasion[pid] + ItemEvasion[pid]

            if TotalEvasion[pid] > 100 or PhantomSlashing[pid] then
                set TotalEvasion[pid] = 100
            endif
                
            set HasShield[pid] = CheckShields(Hero[pid])

            //regeneration
            set TotalRegen[pid] = 0

            set TotalRegen[pid] = TotalRegen[pid] + ItemRegen[pid]

            //chaos shield 
            set x = IMinBJ(5, R2I((BlzGetUnitMaxHP(Hero[pid]) - GetWidgetLife(Hero[pid])) / BlzGetUnitMaxHP(Hero[pid]) * 100 / 15))

            if HasItemType(Hero[pid], 'I01J') then
                set TotalRegen[pid] = TotalRegen[pid] + BlzGetUnitMaxHP(Hero[pid]) * 0.001 * x
            elseif HasItemType(Hero[pid], 'I02R') then
                set TotalRegen[pid] = TotalRegen[pid] + BlzGetUnitMaxHP(Hero[pid]) * 0.0015 * x
            elseif HasItemType(Hero[pid], 'I01C') then
                set TotalRegen[pid] = TotalRegen[pid] + BlzGetUnitMaxHP(Hero[pid]) * 0.002 * x
            endif

            set TotalRegen[pid] = TotalRegen[pid] * (1. + Reg_mod[pid] * 0.01)

            call UnitSetBonus(Hero[pid], BONUS_LIFE_REGEN, TotalRegen[pid])
            
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
                    set Movespeed[pid] = Movespeed[pid] + 150
                endif
                if GetUnitAbilityLevel(Hero[pid], 'BUau') > 0 then //blood horn
                    set Movespeed[pid] = Movespeed[pid] + 75
                endif
                if GetUnitAbilityLevel(Hero[pid], 'Adiv') > 0 then //blood horn
                    set Movespeed[pid] = Movespeed[pid] + 25 + 25 * GetUnitAbilityLevel(Hero[pid], 'Adiv')
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
        endif
        
        set u = u.next
    endloop

    set ug = null
    set target = null
    set target2 = null

    return false
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
        set r = SelectGroupedRegion(rand)

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
    
    if udg_Chaos_World_On then
        if GetUnitTypeId(Boss[BOSS_LEGION]) != 0 and GetWidgetLife(Boss[BOSS_LEGION]) >= 0.406 then
            loop
                set x = GetRandomReal(GetRectMinX(gg_rct_Main_Map), GetRectMaxX(gg_rct_Main_Map))
                set y = GetRandomReal(GetRectMinY(gg_rct_Main_Map), GetRectMaxY(gg_rct_Main_Map))
                set x2 = GetUnitX(Boss[BOSS_LEGION])
                set y2 = GetUnitY(Boss[BOSS_LEGION])
                
                exitwhen LineContainsBox(x2, y2, x, y, -4000, -3000, 4000, 5000, 0.3) == false and IsTerrainWalkable(x, y) and DistanceCoords(x, y, x2, y2) > 1500.
            endloop
        
            call IssuePointOrder(Boss[BOSS_LEGION], "patrol", x, y )
        endif
    else
        if GetUnitTypeId(Boss[BOSS_DEATH_KNIGHT]) != 0 and GetWidgetLife(Boss[BOSS_DEATH_KNIGHT]) >= 0.406 then
            loop
                set x = GetRandomReal(GetRectMinX(gg_rct_Main_Map), GetRectMaxX(gg_rct_Main_Map))
                set y = GetRandomReal(GetRectMinY(gg_rct_Main_Map), GetRectMaxY(gg_rct_Main_Map))
                set x2 = GetUnitX(Boss[BOSS_DEATH_KNIGHT])
                set y2 = GetUnitY(Boss[BOSS_DEATH_KNIGHT])
                
                exitwhen LineContainsBox(x2, y2, x, y, -4000, -3000, 4000, 5000, 0.3) == false and IsTerrainWalkable(x, y) and DistanceCoords(x, y, x2, y2) > 1500.
            endloop
        
            call IssuePointOrder(Boss[BOSS_DEATH_KNIGHT], "patrol", x, y )
        endif
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

    if GetRandomInt(0, 99) < 5 then
        set x = GetRandomReal(GetRectMinX(gg_rct_Tavern), GetRectMaxX(gg_rct_Tavern))
        set y = GetRandomReal(GetRectMinY(gg_rct_Tavern), GetRectMaxY(gg_rct_Tavern))
    endif
    
    call IsTerrainWalkable(x, y)
	call SetUnitPosition(gg_unit_n01F_0576, TerrainPathability_X, TerrainPathability_Y) //random starting spot
endfunction

function OneSecond takes nothing returns nothing
    local integer pid
    local real hp = 0.
    local real mp = 0.
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
    
    //boss regeneration / player scaling / reset
    loop
        exitwhen i > BOSS_TOTAL
        set index = 0
        set count = BlzGroupGetSize(HeroGroup)
        set numplayers = 0
        if CWLoading == false and GetWidgetLife(Boss[i]) >= 0.406 then
            //death knight / legion exception
            if BossID[i] != 'H04R' and BossID[i] != 'H040' then
                if IsUnitInRangeLoc(Boss[i], BossLoc[i], 2000.) == false and GetUnitAbilityLevel(Boss[i], 'Amrf') == 0 then
                    set hp = GetHeroStr(Boss[i], false) * 25 * 0.08
                    if GetUnitAbilityLevel(Boss[i], 'Asan') > 0 then
                        set hp = hp * 0.5
                    endif
                    call UnitSetBonus(Boss[i], BONUS_LIFE_REGEN, hp)
                    call UnitAddAbility(Boss[i], 'Amrf')
                    call SetUnitMoveSpeed(Boss[i], 522)
                    call SetUnitPathing(Boss[i], false)
                    call SetUnitTurnSpeed(Boss[i], 1.)
                    call TimerStart(NewTimerEx(i), 0.06, true, function ReturnBoss)
                endif
            endif

            //determine number of nearby heroes
            loop
                if IsUnitInRange(BlzGroupUnitAt(HeroGroup, index), Boss[i], NEARBY_BOSS_RANGE) then
                    set numplayers = numplayers + 1
                endif
                set index = index + 1
                exitwhen index >= count
            endloop

            set BossNearbyPlayers[i] = IMaxBJ(BossNearbyPlayers[i], numplayers)

            if numplayers < BossNearbyPlayers[i] then
                call TimerStart(NewTimerEx(i), 5., false, function BossBonusLinger)
            endif

            //calculate hp regeneration
            if GetWidgetLife(Boss[i]) > GetHeroStr(Boss[i], false) * 25 * 0.15 then // > 15%
                if udg_Chaos_World_On then
                    set hp = GetHeroStr(Boss[i], false) * 25 * (0.0001 + 0.0004 * BossNearbyPlayers[i]) //0.04% per player
                else
                    set hp = GetHeroStr(Boss[i], false) * 25 * 0.002 * BossNearbyPlayers[i] //0.2%
                endif
            else
                if udg_Chaos_World_On then
                    set hp = GetHeroStr(Boss[i], false) * 25 * (0.0002 + 0.0008 * BossNearbyPlayers[i]) //0.08%
                else
                    set hp = GetHeroStr(Boss[i], false) * 25 * 0.004 * BossNearbyPlayers[i] //0.4%
                endif
            endif

            if numplayers == 0 then //out of combat?
                set hp = GetHeroStr(Boss[i], false) * 25 * 0.02 //2%
            else //bonus damage and health
                if udg_Chaos_World_On then
                    call UnitSetBonus(Boss[i], BONUS_DAMAGE, R2I(BlzGetUnitBaseDamage(Boss[i], 0) * 0.2 * (BossNearbyPlayers[i] - 1)))
                    call UnitSetBonus(Boss[i], BONUS_HERO_STR, R2I(GetHeroStr(Boss[i], false) * 0.2 * (BossNearbyPlayers[i] - 1)))
                endif
            endif

            //sanctified ground debuff
            if GetUnitAbilityLevel(Boss[i], 'Asan') > 0 then
                set hp = hp * 0.5
            endif

            //non-returning hp regeneration
            if GetUnitAbilityLevel(Boss[i], 'Amrf') == 0 then
                call UnitSetBonus(Boss[i], BONUS_LIFE_REGEN, hp)
            endif
        endif
        set i = i + 1
    endloop
    
    //summon regeneration
    call BlzGroupAddGroupFast(SummonGroup, ug)
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if GetWidgetLife(target) >= 0.406 and GetUnitAbilityLevel(target, 'A06Q') > 0 then
            if GetUnitTypeId(target) == SUMMON_DESTROYER then
                call UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.0005 * GetUnitAbilityLevel(target, 'A06Q')))
            elseif GetUnitTypeId(target) == SUMMON_HOUND and GetUnitAbilityLevel(target, 'A06Q') > 9 then
                call UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.0005 * GetUnitAbilityLevel(target, 'A06Q')))
            else
                call UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.00025 * GetUnitAbilityLevel(target, 'A06Q')))
            endif
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

                    call MultiboardSetItemValueBJ(MULTI_BOARD, 1, udg_MultiBoardsSpot[pid], User(pid - 1).nameColored)
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

        //Heli leash
        if helicopter[pid] != null and UnitDistance(Hero[pid], helicopter[pid]) > 700. then
            call SetUnitPosition(helicopter[pid], GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))
        endif

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
        
        if HeroID[pid] > 0 then
            //update mana costs
            call UnitSpecification(Hero[pid])

            //intense focus
            if GetUnitAbilityLevel(Hero[pid], 'A0B9') > 0 and GetWidgetLife(Hero[pid]) >= 0.406 and LAST_HERO_X[pid] == GetUnitX(Hero[pid]) and LAST_HERO_Y[pid] == GetUnitY(Hero[pid]) and udg_HeroCanUseBow[pid] then
                set IntenseFocus[pid] = IMinBJ(10, IntenseFocus[pid] + 1)
            else
                set IntenseFocus[pid] = 0
            endif

            //keep track of hero positions
            set LAST_HERO_X[pid] = GetUnitX(Hero[pid])
            set LAST_HERO_Y[pid] = GetUnitY(Hero[pid])

            //PVP leave range
            if ArenaQueue[pid] > 0 and IsUnitInRangeXY(Hero[pid], -1311., 2905., 1000.) == false then
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
                    //15% of blood spent
                    call HP(Hero[pid], ((0.25 + 0.25 * GetUnitAbilityLevel(Hero[pid], 'A093')) * GetHeroStr(Hero[pid], true) + hp * 0.15) * BOOST(pid))
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

            //elite marksman
            if GetUnitAbilityLevel(Hero[pid], 'A049') > 0 then
                set STOOLTIP[pid] = SniperStanceTooltip(pid)
                call BlzSetAbilityTooltip('A049', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A049') - 1)

                set STOOLTIP[pid + 8] = SniperStanceExtendedTooltip(pid)
                call BlzSetAbilityExtendedTooltip('A049', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 9], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A049') - 1)
            endif

            if GetUnitAbilityLevel(Hero[pid], 'A06U') > 0 then
                set STOOLTIP[pid + 16] = AssaultHelicopterTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A06U'))
                call BlzSetAbilityExtendedTooltip('A06U', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 17], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A06U') - 1)
            endif

            if GetUnitAbilityLevel(Hero[pid], 'A06I') > 0 then
                set STOOLTIP[pid + 24] = TriRocketTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A06I'))
                call BlzSetAbilityExtendedTooltip('A06I', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 25], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A06I') - 1)
            endif
            
            //thunder blade
            if GetUnitAbilityLevel(Hero[pid], 'A0MN') > 0 then
                set STOOLTIP[pid] = MonsoonTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A0MN'))
                call BlzSetAbilityExtendedTooltip('A0MN', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0MN') - 1)
            endif
            
            //master rogue
            if GetUnitAbilityLevel(Hero[pid], 'A0F7') > 0 then
                set STOOLTIP[pid] = NerveGasTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A0F7'))
                call BlzSetAbilityExtendedTooltip('A0F7', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0F7') - 1)
            endif

            if GetUnitAbilityLevel(Hero[pid], 'A0QQ') > 0 then
                set STOOLTIP[pid + 8] = InstantDeathTooltip(pid)
                call BlzSetAbilityExtendedTooltip('A0QQ', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 9], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0QQ') - 1)
            endif
            
            //arcane warrior
            if GetUnitAbilityLevel(Hero[pid], 'A07X') > 0 then
                set STOOLTIP[pid] = ArcaneMightTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A07X'))
                call BlzSetAbilityExtendedTooltip('A07X', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A07X') - 1)
            endif
            
            //warrior
            if GetUnitAbilityLevel(Hero[pid], 'A0FL') > 0 then
                set STOOLTIP[pid] = CounterStrikeTooltip(pid, GetUnitAbilityLevel(Hero[pid], 'A0FL'))
                call BlzSetAbilityExtendedTooltip('A0FL', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0FL') - 1)
            endif

            //assassin
            if GetUnitAbilityLevel(Hero[pid], 'A0AQ') > 0 then
                set STOOLTIP[pid] = BladeSpinTooltip(pid)
                call BlzSetAbilityExtendedTooltip('A0AQ', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0AQ') - 1)
                call BlzSetAbilityExtendedTooltip('A0AS', STOOLTIP[GetPlayerId(GetLocalPlayer()) + 1], GetUnitAbilityLevel(Hero[GetPlayerId(GetLocalPlayer()) + 1], 'A0AS') - 1)
            endif

            if BardSong[pid] == 1 then
                call SongOfWar(pid, false)
            endif

            //900 (?) range auras
            call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 900., Condition(function isalive))

            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                if IsUnitAlly(target, Player(pid - 1)) and GetUnitAbilityLevel(Hero[pid], 'A0HS') > 0 then
                    set ProtectedBuff.add(Hero[pid], target).duration = 2.
                elseif IsUnitAlly(target, Player(pid - 1)) == false then
                    if BardSong[pid] == 4 then
                        set SongOfFatigueSlow.add(Hero[pid], target).duration = 2.
                    elseif GetUnitAbilityLevel(Hero[pid], 'B01W') > 0 then
                        set IceElementSlow.add(Hero[pid], target).duration = 2.
                    endif
                endif
            endloop

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
                    if RAbsBJ(angle * bj_RADTODEG - GetUnitFacing(Hero[pid])) < 30. or RAbsBJ(angle * bj_RADTODEG - GetUnitFacing(Hero[pid])) > 330. then
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
    local integer i = 0
    local integer i2 = 0
    local integer i3 = 0
    local integer pid = 0
    local User U = User.first
    
    //shields
    loop
        set i = GetUnitUserData(BlzGroupUnitAt(shieldGroup, i2))
        if isShielded[i] then
            call SetUnitXBounded(shieldunit[i], GetUnitX(shieldtarget[i]))
            call SetUnitYBounded(shieldunit[i], GetUnitY(shieldtarget[i]))
            set i3 = R2I(shieldhp[i] / shieldmax[i] * 100.0)
            if i3 > shieldpercent[i] then
                set shieldpercent[i] = shieldpercent[i] + 3
                call SetUnitTimeScale(shieldunit[i], 0.95)
            elseif i3 < shieldpercent[i] and shieldpercent[i] - i3 > 3 then
                set shieldpercent[i] = shieldpercent[i] - 3
                call SetUnitTimeScale(shieldunit[i], -0.95)
            else
                call SetUnitTimeScale(shieldunit[i], 0)
            endif
        endif
        set i2 = i2 + 1
        exitwhen i2 >= BlzGroupGetSize(shieldGroup)
    endloop

    loop
        exitwhen U == User.NULL
        set pid = GetPlayerId(U.toPlayer()) + 1

        //heli text follow
        if helitag[pid] != null and GetWidgetLife(helicopter[pid]) >= 0.406 then
            call SetTextTagPosUnit(helitag[pid], helicopter[pid], -200.)
        endif
        
        //camera lock
        if hselection[pid] then
            if (GetLocalPlayer() == U.toPlayer()) then
                call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, 500, 0 )
                call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, 340, 0 )
                call SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, 60, 0 )
                call SetCameraField(CAMERA_FIELD_ZOFFSET, 200, 0 )
                call SetCameraField(CAMERA_FIELD_ROTATION, GetUnitFacing(hstarget[hslook[pid]]) + 180, 0 )
                call SetCameraTargetController(gg_unit_h00T_0511, 0, 0, false)
            endif
        elseif CameraLock[pid] then
            if (GetLocalPlayer() == U.toPlayer()) then
                call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, udg_Zoom[pid], 0 )
            endif
        endif

        set U = U.next
    endloop
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
    call TriggerAddCondition(pointthreefive, Filter(function Periodic))
    
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

    call TriggerRegisterTimerExpireEvent(wandering, wanderingTimer)
    call TimerStart(wanderingTimer, 2040. - (User.AmountPlaying * 240), true, function ShadowStepExpire)
    
    loop
        exitwhen u == User.NULL
        set SaveTimer[u.id] = CreateTimer()
        call TriggerRegisterTimerExpireEvent(savetimer, SaveTimer[u.id])
        set u = u.next
    endloop
    
    call TriggerAddAction(savetimer, function Trig_SaveTimer_Actions)
    
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
    set wandering = null
endfunction

endlibrary
