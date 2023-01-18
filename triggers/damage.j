library DamageSystem requires Functions, Spells, Death, PVP, Bosses, Dungeons optional dev

globals
    trigger BeforeArmor = CreateTrigger()
    //trigger AfterArmor = CreateTrigger()
    boolean array HeroInvul
    real array HeartDealt
    real array HeartHits
    boolean ignoreflag = false
    timer SUPER_DUMMY_TIMER = CreateTimer()
    real SUPER_DUMMY_TOTAL = 0.
    real SUPER_DUMMY_LAST = 0.
    real SUPER_DUMMY_DPS = 0.

    constant damagetype PHYSICAL = DAMAGE_TYPE_NORMAL
    constant damagetype SPELL = DAMAGE_TYPE_MAGIC
endglobals

function SwitchAggro takes nothing returns nothing
    local integer id = ReleaseTimer(GetExpiredTimer())
    local unit u = GetUnitById(id)
    local unit target = GetUnitTarget(u)

    call FlushChildHashtable(ThreatHash, id)
    call IssueTargetOrder(u, "smart", target)
    call SaveInteger(ThreatHash, id, THREAT_TARGET_INDEX, GetUnitId(target))

    set u = null
    set target = null
endfunction

function SUPER_DUMMY_HIDE_TEXT takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    set pt.dur = pt.dur - 1
    
    if pt.dur <= 0 then
        if GetLocalPlayer() == Player(pid - 1) then
            call BlzFrameSetVisible(dummyFrame, false)
        endif

        call TimerList[pid].removePlayerTimer(pt)
    endif
endfunction

function SUPER_DUMMY_DPS_UPDATE takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer count = GetTimerData(t)

    if SUPER_DUMMY_TOTAL <= 0 then
        call ReleaseTimer(t)
    else
        set SUPER_DUMMY_DPS = RMaxBJ(SUPER_DUMMY_DPS, SUPER_DUMMY_TOTAL / count)
        call SetTimerData(t, count + 1)
        call BlzFrameSetText(dummyText, "Last Hit: " + R2S(SUPER_DUMMY_LAST) + "\nTotal: " + R2S(SUPER_DUMMY_TOTAL) + "\nDPS: " + R2S(SUPER_DUMMY_DPS))
    endif

    set t = null
endfunction

function SUPER_DUMMY_RESET takes nothing returns nothing
    set SUPER_DUMMY_TOTAL = 0
    set SUPER_DUMMY_LAST = 0
    set SUPER_DUMMY_DPS = 0
    call BlzFrameSetText(dummyText, "Last Hit: 0.00 \nTotal: 0.00 \nDPS: 0.00")
endfunction

function ReduceArmorCalc takes real dmg, unit source, unit target returns real
    local real armor = BlzGetUnitArmor(target)
    local real value = dmg
    local integer pid = GetPlayerId(GetOwningPlayer(source)) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(target)) + 1
    local real newarmor = armor

    if LoadEffectHandle(MiscHash, GetUnitId(target), pid) != null then //piercing strikes
        set newarmor = (RMaxBJ(0, armor - armor * (30 + GetUnitAbilityLevel(Hero[pid], 'A0F6')) * 0.01))
    endif

    if GetUnitAbilityLevel(source, 'A0F6') > 0 then //flaming bow
        set newarmor = (RMaxBJ(0, armor - armor * (10 + GetUnitAbilityLevel(Hero[pid], 'A0F6') * 1) * 0.01)) 
    endif

    if newarmor >= 0 then
        set value = dmg - (dmg * (0.05 * newarmor / (1 + 0.05 * newarmor)))
    else
        set value = dmg * (2 - Pow(0.94, (-newarmor)))
    endif

    if armor >= 0 then
        set value = value / (1 - (0.05 * armor / (1 + 0.05 * armor)))
    endif

    return value
endfunction

function ApplyArmorCalc takes real dmg, unit source, unit target, damagetype TYPE returns real //after
    local real armor = BlzGetUnitArmor(target)
    local real value = dmg
    local integer pid = GetPlayerId(GetOwningPlayer(source)) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(target)) + 1
    local integer dtype = BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE)
    local integer atype = BlzGetUnitWeaponIntegerField(source, UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0)

    if (dtype == 6 or dtype == 7) then //chaos armor
        set value = value * 0.03
    endif

    if TYPE == PHYSICAL then
        if atype == 5 then
            set value = value * 350
        endif

        if armor >= 0 then
            set value = value - (value * (0.05 * armor / (1 + 0.05 * armor)))
        else
            set value = value * (2 - Pow(0.94, (-armor)))
        endif
    endif

    return value
endfunction

function AdjustArmorCalc takes real dmg, unit source, unit target, damagetype TYPE returns real //before
    local real armor = BlzGetUnitArmor(target)
    local real value = 1
    local integer pid = GetPlayerId(GetOwningPlayer(source)) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(target)) + 1

    if udg_Chaos_World_On and IsEnemy(tpid) then
        set value = value * 0.03
    endif

    if TYPE == PHYSICAL then
        if armor >= 0 then
            set value = 1 - (0.05 * armor / (1 + 0.05 * armor))
        else
            set value = 2 - Pow(0.94, (-armor))
        endif
    endif

    return dmg / value
endfunction

function OnDamageBeforeArmor takes nothing returns nothing
    local unit source = GetEventDamageSource()
    local unit target = BlzGetEventDamageTarget()
    local real amount = GetEventDamage()
    local damagetype damageType = BlzGetEventDamageType()
    local integer pid = GetPlayerId(GetOwningPlayer(source)) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(target)) + 1
    local integer uid = GetUnitTypeId(source)
    local integer tuid = GetUnitTypeId(target)
    local real boost = BOOST(pid)
    local real lowboost = LBOOST(pid)
    local integer ablevel = 0
    local real dmg = 0.
    local integer crit = 1
    local real unitangle = 0.
    local integer i = 0
    local timer t = null
    local unit u = null
    local group ug = CreateGroup()
    local PlayerTimer pt

    //force random shit to be magic damage?
    if damageType != PHYSICAL and damageType != SPELL then
        call BlzSetEventDamageType(SPELL)
    endif

    //abilities and crits triggered only by physical attacks, only works with player heroes on enemies
    if damageType == PHYSICAL and IsUnitType(source, UNIT_TYPE_HERO) and IsUnitEnemy(source, GetOwningPlayer(target)) and pid < 9 and not ignoreflag then
        /*/*/*
            
        //probably include built in enemy evasion here
            
        */*/*/
        
        //assassin blade spin count
        if uid == HERO_ASSASSIN then
            set BladeSpinCount[pid] = BladeSpinCount[pid] + 1
        endif

        //vampire blood bank
        if uid == HERO_VAMPIRE then
            set BloodBank[pid] = RMinBJ(BloodBank[pid] + 0.75 * GetHeroStr(Hero[pid], true), 200 * GetHeroInt(Hero[pid], true))

            //vampire blood lord
            if GetUnitAbilityLevel(source, 'A099') > 0 then
                set dmg = dmg + ((0.75 * GetHeroAgi(source, true) + 1 * GetHeroStr(source, true)) * boost)
                call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", target, "chest"))
            endif
        endif

        //master rogue piercing strikes
        if GetRandomInt(0, 99) < 20 and GetUnitAbilityLevel(source, 'A0QU') > 0 then
            set pt = TimerList[pid].getTimerWithTargetTag(target, 'pstr')
            if pt == 0 then
                set pt = TimerList[pid].addTimer(pid)
                set pt.target = target
                set pt.tag = 'pstr'
                set pt.dur = 2.
                call TimerStart(pt.getTimer(), 1., true, function PiercingStrikeExpire)
                set bj_lastCreatedEffect = AddSpecialEffectTarget("war3mapImported\\Armor Penetration Orange.mdx", target, "overhead") 
                call SaveEffectHandle(MiscHash, GetUnitId(target), pid, bj_lastCreatedEffect)
                call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 0)
                if GetLocalPlayer() == GetOwningPlayer(source) then
                    call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 1)
                endif
            else
                set pt.dur = 2.
            endif

            call SetUnitAnimation(source, "spell slam")
        endif

        if LoadEffectHandle(MiscHash, GetUnitId(target), pid) != null then
            set amount = ReduceArmorCalc(amount, source, target)
        endif

        //bloodzerker blood cleave / blood leech
        if uid == HERO_BLOODZERKER and GetUnitAbilityLevel(source, 'A05X') > 0 then
            if rampageActive[pid] then
                set i = (10 + GetUnitAbilityLevel(source, 'A0GZ'))
            else
                set i = 10
            endif

            if GetRandomReal(0, 99) < i * boost then
                call BloodCleave(pid)
            endif

            if rampageActive[pid] then
                set i = 25 + GetUnitAbilityLevel(source, 'A0GZ')
            else
                set i = 25
            endif
            
            if GetRandomReal(0, 99) < i * boost then
                call HP(source, BlzGetUnitMaxHP(source) * (0.012 + 0.002 * GetUnitAbilityLevel(source, 'A05X')) * boost)
                call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\VampiricAuraTarget.mdx", source, "origin"))
            endif
        endif
        //thunderblade overload
        if uid == HERO_THUNDERBLADE and overloadActive[pid] then
            if GetRandomReal(0, 99) < (10 + GetUnitAbilityLevel(source, 'A096')) * boost then
                set dmg = dmg + (GetHeroAgi(source, true) * GetUnitAbilityLevel(source, 'A096') * boost)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", target, "origin"))
	            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", target, "origin"))
            endif
        endif
        //master rogue windwalk
        if Windwalk[pid] then
            set Windwalk[pid] = false
            set ablevel= GetUnitAbilityLevel(source, 'A0F5')
            set dmg = dmg + ((UnitGetBonus(source, BONUS_DAMAGE) + GetHeroAgi(source,true )) * .25 * ablevel + GetHeroAgi(source,true ) * ablevel) * boost
            call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Orc\\Devour\\DevourEffectArt.mdl", source, "chest" ) )
            call UnitRemoveAbility(source,'BOwk')
            call AddUnitAnimationProperties(source, "alternate", false)
        endif
        //master rogue backstab
        if GetUnitAbilityLevel(source,'A0QP') > 0 and uid == HERO_MASTER_ROGUE then
            set ablevel= GetUnitAbilityLevel(source, 'A0QP')
            set unitangle = bj_RADTODEG * Atan2(GetUnitY(target)-GetUnitY(source), GetUnitX(target)-GetUnitX(source))
            if unitangle<0 then
                set unitangle=unitangle+360
            endif
            if RAbsBJ( unitangle - GetUnitFacing(target) )<45 and (IsUnitType(target,UNIT_TYPE_STRUCTURE) == false) then
                call DestroyEffect( AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "chest") )
                set dmg = dmg + (GetHeroAgi(source,true)*0.13 +UnitGetBonus(source ,BONUS_DAMAGE)*.03) * ablevel * boost
            endif
        endif
        //phoenix ranger fiery arrows / flaming bow
        if uid == HERO_PHOENIX_RANGER then
            if GetUnitAbilityLevel(source,'A0IB') > 0 then
                set ablevel= GetUnitAbilityLevel(source, 'A0IB')
                if GetRandomInt(0,99) < ablevel * 2 * lowboost then
                    set dmg = dmg + (((UnitGetBonus(source, BONUS_DAMAGE) + GetHeroAgi(source, true)) * .3 + GetHeroAgi(source, true) * ablevel)) * boost
                    call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX(target),GetUnitY(target) ) )
                    if GetUnitAbilityLevel(target, 'B02O') > 0 then
                        call UnitRemoveAbility(target, 'B02O')
                        call SearingArrowIgnite(target, pid)
                    endif
                endif
            endif

            if GetUnitAbilityLevel(source, 'A0F6') > 0 then //armor pen
                set amount = ReduceArmorCalc(amount, source, target)
            endif

            if GetUnitAbilityLevel(source, 'A08B') > 0 then //damage ramp
                set ablevel = GetUnitAbilityLevel(source, 'A0F6')
                call UnitAddBonus(source, BONUS_DAMAGE, -R2I(FlamingBowBonus[pid]))
                if MultiShot[pid] then
                    set FlamingBowCount[pid] = IMinBJ(FlamingBowCount[pid] + R2I(100 / (2 + R2I(IMinBJ(GetHeroLevel(source), 200) / 50.))), 3000 + 200 * ablevel) 
                else
                    set FlamingBowCount[pid] = IMinBJ(FlamingBowCount[pid] + 100, 3000 + 200 * ablevel)
                endif
                set FlamingBowBonus[pid] = (0.5 + 0.0001 * FlamingBowCount[pid]) * (GetHeroAgi(source, true) + UnitGetBonus(source, BONUS_DAMAGE)) * LBOOST(pid)
                call UnitAddBonus(source, BONUS_DAMAGE, R2I(FlamingBowBonus[pid]))
            endif
        endif
        //savior bash
        if GetUnitAbilityLevel(source, 'A0GG') > 0 and uid == HERO_SAVIOR then
            set ablevel= GetUnitAbilityLevel(source, 'A0GG')
            set saviorBashCount[pid] = saviorBashCount[pid] + 1
            if saviorBashCount[pid] > 9 then
                set saviorBashCount[pid] = 0
                set dmg = dmg + (((UnitGetBonus(source, BONUS_DAMAGE) + GetHeroStr(source,true)) * .3) + GetHeroStr(source, true) * (0.4 + 0.1 * ablevel)) * boost
                call StunUnit(pid, target, 2)
                call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX(target),GetUnitY(target) ) )
                call SaviorBashHeal(pid, ablevel)
            endif
        endif
        //bard encore (song of war)
        if LoadInteger(EncoreTargets, GetHandleId(source), 0) > 0 then
            call SaveInteger(EncoreTargets, GetHandleId(source), 0, LoadInteger(EncoreTargets, GetHandleId(source), 0) - 1)
            set ablevel = GetUnitAbilityLevel(Hero[LoadInteger(EncoreTargets, GetHandleId(source), 1)], 'A0AZ')
            set dmg = dmg + (.25 + .25 * ablevel) * GetHeroStat(MainStat(source), source, true) * boost
        endif
        //demon hound critical strike (dark summoner)
        if uid == SUMMON_HOUND then
            if GetRandomInt(0, 99) < 25 then
                if destroyerSacrificeFlag[pid] then
                    call DemonHoundAOE(source, target)
                else
                    set dmg = dmg + GetHeroInt(source, true) * LBOOST(pid)
                endif
                call DestroyEffect(AddSpecialEffect( "Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", GetUnitX(target), GetUnitY(target) ))
            endif
        endif
        //destroyer critical strike (dark summoner)
        if uid == SUMMON_DESTROYER then
            if destroyerDevourStacks[pid] >= 4 then
                set ablevel = 15
            else
                set ablevel = 10
            endif
        
            if GetRandomInt(0, 99) < ablevel then
                set dmg = dmg + GetHeroInt(source, true) * LBOOST(pid)
                call DestroyEffect(AddSpecialEffect( "Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", GetUnitX(target), GetUnitY(target) ))
            endif
        endif
        //dark savior dark blade
        if GetUnitAbilityLevel(source, 'B01A') > 0 then
            if ismetamorphosis[pid] then
                set dmg = dmg + GetHeroInt(source, true) * (0.4 + GetUnitAbilityLevel(source, 'AEim') * 0.1) * boost
            else
                if GetUnitManaPercent(source) >= 1.00 then
                    set dmg = dmg + GetHeroInt(source, true) * (0.4 + GetUnitAbilityLevel(source, 'AEim') * 0.1)  * boost
                    call SetUnitManaPercentBJ( source, ( GetUnitManaPercent(source) - 1.00 ) )
                else
                    call IssueImmediateOrder( source, "unimmolation" )
                endif
            endif
        endif
        //oblivion guard infernal strikes
        if GetUnitAbilityLevel(source, 'B00P') > 0 and infernalStrike[pid] == false then
            if infernalStrikes[pid] > 0 then
                set amount = 0.00
                set infernalStrikes[pid] = infernalStrikes[pid] - 1
                set infernalStrike[pid] = true
                call InfernalStrikes(pid, target)
                set infernalStrike[pid] = false
                call DestroyEffect(AddSpecialEffect("war3mapImported\\Lava_Slam.mdx", GetUnitX(target), GetUnitY(target)))
                call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))
                call SetUnitTimeScale(source, 1)
            else
                call UnitRemoveAbility(source, 'B00P')
            endif
        endif

        if HasItemType(source, 'I04C') and GetRandomInt(0, 99) < 5 then
            set dmg = dmg + 250
        endif

        if dmg > 0 then //so multiple texts dont stack
            call UnitDamageTarget(source, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif

        //master rogue instant death
        if GetUnitAbilityLevel(source,'A0QQ') > 0 and uid == HERO_MASTER_ROGUE then
            if GetRandomInt(0, 99) < 5 * lowboost then
                set crit = crit + InstantDeathFormula(pid)
            endif
        endif
        //elite marksman sniper stance
        if uid == HERO_MARKSMAN_SNIPER then
            set crit = crit + 4
        endif

        //arcanist cds
        set i = 2
        if arcanosphereActive[pid] then
            set ArcaneBoltsCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A08X') - i
            if ArcaneBoltsCD[pid] > 0 then
                call BlzStartUnitAbilityCooldown(Hero[pid], 'A08X', ArcaneBoltsCD[pid])
            else
                call BlzEndUnitAbilityCooldown(Hero[pid], 'A08X')
            endif
            set ArcaneBarrageCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A08S') - i
            if ArcaneBarrageCD[pid] > 0 then
                call BlzStartUnitAbilityCooldown(Hero[pid], 'A08S', ArcaneBarrageCD[pid])
            else
                call BlzEndUnitAbilityCooldown(Hero[pid], 'A08S')
            endif
        else
            set ArcaneBoltsCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A05Q') - i
            if ArcaneBoltsCD[pid] > 0 then
                call BlzStartUnitAbilityCooldown(Hero[pid], 'A05Q', ArcaneBoltsCD[pid])
            else
                call BlzEndUnitAbilityCooldown(Hero[pid], 'A05Q')
            endif
            set ArcaneBarrageCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A02N') - i
            if ArcaneBarrageCD[pid] > 0 then
                call BlzStartUnitAbilityCooldown(Hero[pid], 'A02N', ArcaneBarrageCD[pid])
            else
                call BlzEndUnitAbilityCooldown(Hero[pid], 'A02N')
            endif
        endif
        set StasisFieldCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A075') - i
        if StasisFieldCD[pid] > 0 then
            call BlzStartUnitAbilityCooldown(Hero[pid], 'A075', StasisFieldCD[pid])
        else
            call BlzEndUnitAbilityCooldown(Hero[pid], 'A075')
        endif
        set ArcaneShiftCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A078') - i
        if ArcaneShiftCD[pid] > 0 then
            call BlzStartUnitAbilityCooldown(Hero[pid], 'A078', ArcaneShiftCD[pid])
        else
            call BlzEndUnitAbilityCooldown(Hero[pid], 'A078')
        endif
        set SpaceTimeRippleCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A079') - i
        if SpaceTimeRippleCD[pid] > 0 then
            call BlzStartUnitAbilityCooldown(Hero[pid], 'A079', SpaceTimeRippleCD[pid])
        else
            call BlzEndUnitAbilityCooldown(Hero[pid], 'A079')
        endif
        set ControlTimeCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A04C') - i
        if ControlTimeCD[pid] > 0 then
            call BlzStartUnitAbilityCooldown(Hero[pid], 'A04C', ControlTimeCD[pid])
        else
            call BlzEndUnitAbilityCooldown(Hero[pid], 'A04C')
        endif

        //phoenix ranger multi shot
        if MultiShot[pid] then
            set amount = amount * 0.6
        endif
            
        //death knight onhit
        if GetRandomInt(0, 99) < 20 and uid == 'H040' then
            call UnitDamageTarget(source, target, 5000, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl", target, "origin"))
        endif
        //Item crits (restricted to players.)
        if HeroID[pid] > 0 then
            set i = 0

            loop
                exitwhen i > 5
                set ablevel = GetItemTypeId(UnitItemInSlot(Hero[pid], i))
                if GetRandomInt(0, 99) < (ItemData[ablevel][StringHash("chance")]) then
                    set crit = crit + (ItemData[ablevel][StringHash("crit")])
                endif
                set i = i + 1
            endloop

            if crit > 1 then
                set amount = amount * crit //add all crits together
            endif
        endif
    elseif damageType == SPELL and IsEnemy(tpid) then //innate enemy spell resist
        if tuid == 'n01M' then //magnataur
            set amount = amount * 0.7
        elseif tuid == 'n01R' then //frost drake
            set amount = amount * 0.7
        elseif tuid == 'n02P' then //frost dragon
            set amount = amount * 0.7
        elseif tuid == 'n099' then //frost elder dragon
            set amount = amount * 0.7
        elseif tuid == 'n02L' then //devourer
            set amount = amount * 0.7
        elseif tuid == 'O02H' then //dark soul
            set amount = amount * 0.7
        elseif tuid == 'O02M' then //pure existence
            set amount = amount * 0.7
        elseif tuid == 'O02T' then //azazoth
            set amount = amount * 0.5
        endif
        
        if HasItemType(target, 'I03Y') then
            set amount= amount * 0.5
        endif

        if tuid == 'U00G' or tuid == 'H045' then
            set amount = amount * 0.5
        endif
    endif
        
    /*/*/*
            
    enemy physical attacks
            
    */*/*/

    if damageType == PHYSICAL and IsUnitEnemy(target, GetOwningPlayer(source)) then
        //evasion
        if target == Hero[tpid] and GetWidgetLife(Hero[tpid]) >= 0.406 then //hitting a hero
            if TotalEvasion[tpid] > 0 and GetRandomInt(0, 99) < TotalEvasion[tpid] then
                call DoFloatingTextUnit("Dodged!", target, 1, 90, 0, 9, 180, 180, 20, 0)
                set amount = 0.00
            else
                //heart of demon prince hits taken
                if GetUnitLevel(source) >= 170 and IsUnitEnemy(source, GetOwningPlayer(target)) and HasItemType(target, 'I04Q') then
                    set HeartHits[tpid] = HeartHits[tpid] + 1
                    call UpdateTooltips()
                endif
                //master of elements (earth)
                if GetUnitAbilityLevel(target,'B01V') > 0 then
                    call UnitDamageTarget(target, source, GetHeroInt(target, true) * 0.3 * BOOST(tpid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                endif
                //counter strike
                if GetRandomInt(0, 99) < 14 and GetUnitAbilityLevel(target,'A0FL') > 0 and CounterCd[tpid] == false then
                    if GetWidgetLife(target) >= 0.406 then
                        set CounterCd[tpid]=true
                        call TimerStart(NewTimerEx(tpid), 1.1 / BOOST(tpid), false, function CounterStrikeCD)
                        call CounterStrike(target)
                    endif
                endif
            endif
            //ursa elder frost nova
            if uid=='nfpe' and GetRandomInt(1,10)==1 then
                call DummyCastTarget(pfoe, target, 'ACfn', 1, GetUnitX(target), GetUnitY(target), "frostnova")
            endif
            //forgotten one tentacle
            if uid=='n08M' and GetRandomInt(1,5)==1 then
                call IssueImmediateOrder(source, "waterelemental")
            endif
        endif
    endif
    
    /*/*/*
    
    boss spells
        
    */*/*/
    
    if target == PreChaosBoss[BOSS_HELLFIRE] and GetWidgetLife(PreChaosBoss[BOSS_HELLFIRE]) >= 0.406 then //Hellfire Magi
        set i = GetRandomInt(1, 15)
        if trifirecd == false then
            if i==1 then
                call IssuePointOrder(target, "carrionswarm", GetUnitX(source), GetUnitY(source) )
            elseif i==2 then
                call IssuePointOrder(target, "flamestrike", GetUnitX(source), GetUnitY(source) )
            endif
            if i < 3 then
                set trifirecd = true
                call TimerStart(NewTimer(), 3.00, false, function TrifireCD)
            endif
        endif
    elseif target == PreChaosBoss[BOSS_TAUREN] and GetWidgetLife(PreChaosBoss[BOSS_TAUREN]) >= 0.406 then //Tauren
        set i = GetRandomInt(1,15)
        if i==1 then
            call IssuePointOrder( PreChaosBoss[BOSS_TAUREN], "carrionswarm", GetUnitX(source), GetUnitY(source))
        elseif i==2 and taurencd == false then
            set taurencd = true
            call SetUnitAnimation(PreChaosBoss[BOSS_TAUREN], "slam")
            call DoFloatingTextUnit( "War Stomp" , PreChaosBoss[BOSS_TAUREN] , 1.75 , 70 , 0 , 11 , 120, 105, 50 , 0)
            call TimerStart(NewTimer(), 1.0, true, function TaurenStomp)
            call TimerStart(NewTimer(), 13., false, function TaurenStompCD)
        endif
    elseif target == PreChaosBoss[BOSS_DWARF] and GetWidgetLife(PreChaosBoss[BOSS_DWARF]) >= 0.406 then //Dwarf
        set i = GetRandomInt(0,100)
        if dwarfcd == false then
            if i<3 then
                call IssueImmediateOrder(PreChaosBoss[BOSS_DWARF], "avatar")
            elseif i<10 then
                set dwarfcd = true
                call SetUnitAnimation(PreChaosBoss[BOSS_DWARF], "slam")
                call DoFloatingTextUnit( "Thunder Clap" , PreChaosBoss[BOSS_DWARF] , 1.75 , 70 , 0 , 11 , 0, 255, 255 , 0)
                call TimerStart(NewTimer(), 1.0, true, function DwarfStomp)
                call TimerStart(NewTimer(), 14., false, function DwarfStompCD)
            endif
        endif
    elseif target == PreChaosBoss[BOSS_DEATH_KNIGHT] and GetWidgetLife(PreChaosBoss[BOSS_DEATH_KNIGHT]) >= 0.406 then //Death Knight
        set i = GetRandomInt(0, 99)
        if i < 10 and BossSpellCD[10] == false then //shadow step
            set BossSpellCD[10] = true
            call ShadowStep(source, 1.5)
            call TimerStart(NewTimerEx(10), 20.00, false, function BossCD)
        elseif i < 8 and deathstrikecd == false then
            call GroupEnumUnitsInRange(deathstriketargets, GetUnitX(PreChaosBoss[BOSS_DEATH_KNIGHT]), GetUnitY(PreChaosBoss[BOSS_DEATH_KNIGHT]), 1250., Condition(function isplayerunit))
            call DoFloatingTextUnit( "Death Strikes" , PreChaosBoss[BOSS_DEATH_KNIGHT] , 1.75 , 70 , 0 , 11 , 110, 0, 110 , 0)
            set deathstrikecd = true
            loop
                set u = FirstOfGroup(deathstriketargets)
                exitwhen u == null
                call GroupRemoveUnit(deathstriketargets, u)
                if BlzGroupGetSize(deathstriketargets) < 4 then
                    set t = NewTimer()
                    set bj_lastCreatedUnit = GetDummy(GetUnitX(u), GetUnitY(u), 0, 0, DUMMY_RECYCLE_TIME) 
                    call SetUnitScale(bj_lastCreatedUnit, 4., 4., 4.)
                    call BlzSetUnitSkin(bj_lastCreatedUnit, 'e01F')
                    call SaveReal(MiscHash, GetHandleId(t), 0, GetUnitX(u))
                    call SaveReal(MiscHash, GetHandleId(t), 1, GetUnitY(u))
                    call SaveUnitHandle(MiscHash, GetHandleId(t), 2, bj_lastCreatedUnit)
                    call TimerStart(t, 3, false, function DeathStrike)
                endif
            endloop
            call TimerStart(NewTimer(), 8.00, false, function DeathStrikeCD)
        endif
    //Goddesses
    elseif (target == PreChaosBoss[BOSS_HATE] or target == PreChaosBoss[BOSS_LOVE] or target == PreChaosBoss[BOSS_KNOWLEDGE]) then
        //Love Holy Ward
        if GetWidgetLife(PreChaosBoss[BOSS_LOVE]) >= 0.406 and (GetWidgetLife(PreChaosBoss[BOSS_LOVE]) / BlzGetUnitMaxHP(PreChaosBoss[BOSS_LOVE])) <= 0.8 then
            if holywardcd == false then
                set holywardcd = true
                set holyward = CreateUnit(pboss, 'o009', GetRandomReal(GetRectMinX(gg_rct_Crystal_Spawn) - 600, GetRectMaxX(gg_rct_Crystal_Spawn) + 600), GetRandomReal(GetRectMinY(gg_rct_Crystal_Spawn) - 600, GetRectMaxY(gg_rct_Crystal_Spawn) + 600), 0)
            
                call MakeGroupInRange(bossid, ug, GetUnitX(holyward), GetUnitY(holyward), 1250, Condition(function FilterEnemy))
                call BlzSetUnitMaxHP(holyward, 10 * BlzGroupGetSize(ug))
                
                call TimerStart(NewTimer(), 10, false, function HolyWard)
                call TimerStart(NewTimer(), 40, false, function HolyWardCD)

                call GroupClear(ug)
            endif
        endif

        //Knowledge Ghost Shroud
        if GetWidgetLife(PreChaosBoss[BOSS_KNOWLEDGE]) >= 0.406 and (GetWidgetLife(PreChaosBoss[BOSS_KNOWLEDGE]) / BlzGetUnitMaxHP(PreChaosBoss[BOSS_KNOWLEDGE])) <= 0.8 then
            call IssueTargetOrder(PreChaosBoss[BOSS_KNOWLEDGE], "silence", source)
            call IssueTargetOrder(PreChaosBoss[BOSS_KNOWLEDGE], "hex", source)

            set i = GetRandomInt(0, 99)
            if i < 30 and ghostshroudcd == false then
                //ghost shroud
                set ghostshroudcd = true
                call UnitAddAbility(PreChaosBoss[BOSS_KNOWLEDGE], 'A08M')
                call DummyCastTarget(pboss, PreChaosBoss[BOSS_KNOWLEDGE], 'A08I', 1, GetUnitX(PreChaosBoss[BOSS_KNOWLEDGE]), GetUnitY(PreChaosBoss[BOSS_KNOWLEDGE]), "banish")
                call TimerStart(NewTimer(), 1, true, function GhostShroud)
                call TimerStart(NewTimer(), 20, false, function GhostShroudCD)
            endif
        endif

    //Life
    elseif (target == PreChaosBoss[BOSS_LIFE]) and GetWidgetLife(target) >= 0.406 and (GetWidgetLife(target) / BlzGetUnitMaxHP(target)) <= 0.9 and sunstrikecd == false then
        set sunstrikecd = true
        call TimerStart(NewTimer(), 20, false, function SunStrikeCD)

        call GroupEnumUnitsInRange(ug, GetUnitX(target), GetUnitY(target), 1250., Condition(function isplayerAlly))

        set i = 1

        loop
            set u = FirstOfGroup(ug)
            exitwhen (i > 3 or u == null)
            call GroupRemoveUnit(ug, u)

            set bj_lastCreatedUnit = GetDummy(GetUnitX(u), GetUnitY(u), 0, 0, 3.)
            call SetUnitScale(bj_lastCreatedUnit, 4., 4., 4.)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, 270)
            call BlzSetUnitSkin(bj_lastCreatedUnit, 'e01F')
            call SetUnitVertexColor(bj_lastCreatedUnit, 200, 200, 0, 255)

            set t = NewTimer()
            call SaveReal(MiscHash, 0, GetHandleId(t), GetUnitX(u))
            call SaveReal(MiscHash, 1, GetHandleId(t), GetUnitY(u))
            call TimerStart(t, 3, false, function SunStrike)

            set i = i + 1
        endloop
    //Demon Prince
    elseif target == ChaosBoss[BOSS_DEMON_PRINCE] and GetWidgetLife(ChaosBoss[BOSS_DEMON_PRINCE]) >= 0.406 and (GetWidgetLife(ChaosBoss[BOSS_DEMON_PRINCE]) / BlzGetUnitMaxHP(ChaosBoss[BOSS_DEMON_PRINCE])) <= 0.5 then
        if GetUnitAbilityLevel(ChaosBoss[BOSS_DEMON_PRINCE], 'Bblo') == 0 then
            call DummyCastTarget(pboss, ChaosBoss[BOSS_DEMON_PRINCE], 'A041', 1, GetUnitX(ChaosBoss[BOSS_DEMON_PRINCE]), GetUnitY(ChaosBoss[BOSS_DEMON_PRINCE]), "bloodlust")
        endif
    //Absolute Horror
    elseif target == ChaosBoss[BOSS_ABSOLUTE_HORROR] and GetWidgetLife(ChaosBoss[BOSS_ABSOLUTE_HORROR]) >= 0.406 and (GetWidgetLife(ChaosBoss[BOSS_ABSOLUTE_HORROR]) / BlzGetUnitMaxHP(ChaosBoss[BOSS_ABSOLUTE_HORROR])) <= 0.8 then
        set i = GetRandomInt(0, 99)
        if i < 10 and truestealthcd == false then
            call GroupEnumUnitsInRange(ug, GetUnitX(ChaosBoss[BOSS_ABSOLUTE_HORROR]), GetUnitY(ChaosBoss[BOSS_ABSOLUTE_HORROR]), 1500., Condition(function isplayerunit))
            call DoFloatingTextUnit( "True Stealth" , ChaosBoss[BOSS_ABSOLUTE_HORROR] , 1.75 , 100 , 0 , 12 , 90, 30, 150 , 0)
            call UnitRemoveBuffs(ChaosBoss[BOSS_ABSOLUTE_HORROR], false, true)
            call UnitAddAbility(ChaosBoss[BOSS_ABSOLUTE_HORROR], 'Avul')
            call UnitAddAbility(ChaosBoss[BOSS_ABSOLUTE_HORROR], 'A043')
            call IssueImmediateOrder(ChaosBoss[BOSS_ABSOLUTE_HORROR], "windwalk")
            set u = FirstOfGroup(ug)
            if u != null then
                set truestealthcd = true
                set unitangle = Atan2(GetUnitY(u) - GetUnitY(ChaosBoss[BOSS_ABSOLUTE_HORROR]), GetUnitX(u) - GetUnitX(ChaosBoss[BOSS_ABSOLUTE_HORROR]))
                call UnitAddAbility(ChaosBoss[BOSS_ABSOLUTE_HORROR], 'Amrf')
                call IssuePointOrder(ChaosBoss[BOSS_ABSOLUTE_HORROR], "move", GetUnitX(u) + 300 * Cos(unitangle), GetUnitY(u) + 300 * Sin(unitangle))
                set t = NewTimer()
                call SaveReal(MiscHash, 0, GetHandleId(t), GetUnitX(u) + 150 * Cos(unitangle))
                call SaveReal(MiscHash, 1, GetHandleId(t), GetUnitY(u) + 150 * Sin(unitangle))
                call TimerStart(t, 2., false, function TrueStealth)
                call TimerStart(NewTimer(), 10., false, function TrueStealthCD)
            else
                call UnitRemoveAbility(ChaosBoss[BOSS_ABSOLUTE_HORROR], 'Avul')
                call UnitRemoveAbility(ChaosBoss[BOSS_ABSOLUTE_HORROR], 'A043')
                call UnitRemoveAbility(ChaosBoss[BOSS_ABSOLUTE_HORROR], 'BOwk')
            endif
            call GroupClear(ug)
        endif
    //Satan
    elseif target == ChaosBoss[BOSS_SATAN] and GetWidgetLife(ChaosBoss[BOSS_SATAN]) >= 0.406 then
        if GetRandomInt(0,99) < 10 then
            call SatanFlameStrike(GetUnitX(source), GetUnitY(source))
        endif
    //Legion
    elseif uid == 'H04R' and damageType == PHYSICAL then
        if IsUnitIllusion(source) then
            call UnitDamageTarget(source, target, BlzGetUnitMaxHP(target) / 400., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        else
            call UnitDamageTarget(source, target, BlzGetUnitMaxHP(target) / 200., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif

    elseif target == ChaosBoss[BOSS_LEGION] and GetWidgetLife(ChaosBoss[BOSS_LEGION]) >= 0.406 and (GetWidgetLife(ChaosBoss[BOSS_LEGION]) / BlzGetUnitMaxHP(ChaosBoss[BOSS_LEGION])) <= 0.8 then
        set i = GetRandomInt(0, 99)
        if i < 10 and BossSpellCD[10] == false then //shadow step
            set BossSpellCD[10] = true
            call ShadowStep(source, 1.5)
            call TimerStart(NewTimerEx(10), 20.00, false, function BossCD)
        elseif i < 15 and legionillusioncd == false and TimerList[bossid].hasTimerWithTag('tpin') == false then
            set legionillusioncd = true
            call LegionIllusion()
            call TimerStart(NewTimer(), 60, false, function LegionIllusionCD)
        endif

    //Forgotten Leader
    elseif target == ChaosBoss[BOSS_FORGOTTEN_LEADER] and GetWidgetLife(ChaosBoss[BOSS_FORGOTTEN_LEADER]) >= 0.406 then
        set i = GetRandomInt(0, 99)
        if i < 6 and unstoppableforcecd == false then
            call GroupEnumUnitsInRange(ug, GetUnitX(ChaosBoss[BOSS_FORGOTTEN_LEADER]), GetUnitY(ChaosBoss[BOSS_FORGOTTEN_LEADER]), 1500., Condition(function isplayerAlly))
            set u = FirstOfGroup(ug)
            if u != null then
                call DoFloatingTextUnit( "Unstoppable Force" , ChaosBoss[BOSS_FORGOTTEN_LEADER] , 1.75 , 100 , 0 , 12 , 255, 0, 0 , 0)
                call TimerStart(NewTimer(), 11.00, false, function UnstoppableForceCD)
                set unstoppableforcecd = true
                set unitangle = Atan2(GetUnitY(u) - GetUnitY(ChaosBoss[BOSS_FORGOTTEN_LEADER]), GetUnitX(u) - GetUnitX(ChaosBoss[BOSS_FORGOTTEN_LEADER]))
                call PauseUnit(ChaosBoss[BOSS_FORGOTTEN_LEADER], true)
                call BlzSetUnitFacingEx(ChaosBoss[BOSS_FORGOTTEN_LEADER], bj_RADTODEG * unitangle)
                set bj_lastCreatedUnit = GetDummy(GetUnitX(u), GetUnitY(u), 0, 0, 3.)
                call SetUnitScale(bj_lastCreatedUnit, 10., 10., 10.)
                call BlzSetUnitFacingEx(bj_lastCreatedUnit, 270.)
                call BlzSetUnitSkin(bj_lastCreatedUnit, 'e01F')
                call SetUnitVertexColor(bj_lastCreatedUnit, 200, 200, 0, 255)
                call GroupClear(unstoppableforcehit)
                set t = NewTimer()
                call SaveReal(MiscHash, 0, GetHandleId(t), GetUnitX(u))
                call SaveReal(MiscHash, 1, GetHandleId(t), GetUnitY(u))
                call TimerStart(t, 2.5, false, function UnstoppableForce)
            endif
            call GroupClear(ug)
        endif
    endif
    
    /*/*/*
    
    misc
        
    */*/*/

    if IsUnitInGroup(target, SummonGroup) and ApplyArmorCalc(amount, source, target, damageType) > ReduceArmorCalc(GetWidgetLife(target), source, target) then //fatal damage summons
        set amount = 0.00
        call SummonExpire(target)
    endif

    //blood domain thing
    if uid == DUMMY and target == Hero[tpid] then
        set amount = 0.00
    endif

    //searing arrow pr 
    if uid == 'h02U' then
        call UnitDamageTarget(Hero[pid], target, (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroAgi(Hero[pid], true)) * boost, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        call IssueTargetOrder(source, "slow", target)
        set amount = 0.00
    endif

    //medean lightning trigger
    set i = LoadInteger(MiscHash, GetHandleId(source), 'mede')
    if uid == DUMMY and i > 0 then
        set dmg = ((GetHeroInt(Hero[i], true) * (GetUnitAbilityLevel(Hero[i], 'AOcl') + 1)) + 100) * BOOST(i)

        call UnitDamageTarget(Hero[i], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        call RemoveSavedInteger(MiscHash, GetHandleId(source), 'mede')
        set amount = 0.00
    endif

    //frozen orb icicle
    set i = LoadInteger(MiscHash, GetHandleId(source), 'forb')
    if uid == DUMMY and i > 0 then
        call UnitShareVision(Hero[i], GetOwningPlayer(target), true)
        call UnitDamageTarget(Hero[i], target, GetHeroInt(Hero[i], true) * (0.5 + 0.5 * GetUnitAbilityLevel(Hero[i], 'A011')) * BOOST(i), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS) 
        set amount = 0.00
    endif

    //satan flame strike
    set i = LoadInteger(MiscHash, GetHandleId(source), 'sflm')
    if uid == DUMMY and i > 0 and IsUnitEnemy(target, pboss) then
        call SaveInteger(MiscHash, GetHandleId(source), 'sflm', i - 1)
        call UnitDamageTarget(ChaosBoss[BOSS_SATAN], target, HMscale(10000), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS) 
        set amount = 0.00
    endif

    //instill fear trigger
    if uid == DUMMY and GetUnitAbilityLevel(source, 'A0AE') > 0 then
        set amount = 0.00
        call UnitRemoveAbility(source, 'A0AE')
        set InstillFear[pid] = target
        call TimerStart(NewTimerEx(pid), 7., false, function InstillFearExpire)
    endif

    //nerve gas trigger
    if tuid == DUMMY and GetUnitAbilityLevel(source, 'A01X') > 0 then
        set amount = 0.00
		set nervetargets[pid] = CreateGroup()
        call UnitRemoveAbility(source, 'A01X')
		call MakeGroupInRange(pid, nervetargets[pid], GetUnitX(target), GetUnitY(target), (195 + 10 * GetUnitAbilityLevel(Hero[pid], 'A0F7')) * LBOOST(pid), Condition(function FilterEnemy))
        set i = BlzGroupGetSize(nervetargets[pid])
        call RemoveUnitTimed(source, 5.)
        call RemoveUnitTimed(target, 5.)
        if i > 0 then
            set pt = TimerList[pid].addTimer(pid)
            set pt.dur = 20 * LBOOST(pid)
            set pt.agi = 0
            loop
                set u = BlzGroupUnitAt(nervetargets[pid], pt.agi)
                call UnitAddAbility(u, 'A0T5')
                call UnitAddAbility(u, 'A0T1')
                set pt.agi = pt.agi + 1
                exitwhen pt.agi >= i 
            endloop
            call TimerStart(pt.getTimer(), 0.5, true, function NerveGas)
            call TimerStart(NewTimerEx(pid), pt.dur * 0.5, false, function ClearNerveTargets)
        else
            call DestroyGroup(nervetargets[pid])
        endif
    endif
        
    //frost blast trigger
    if source == frostblastdummy[pid] and GetWidgetLife(frostblastdummy[pid]) >= 0.406 then
        set amount = 0.00
        set frostblastdummy[pid] = null
        set dmg = 0.75 * GetHeroInt(Hero[pid], true) * GetUnitAbilityLevel(Hero[pid], 'A0GI') * boost
        
        call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 250 * LBOOST(pid), Condition(function FilterEnemy))
    
        if GetUnitAbilityLevel(Hero[pid], 'B01I') > 0 then
            call UnitRemoveAbility(Hero[pid], 'B01I')
            set dmg = dmg * 1.4
        endif
        
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetUnitX(target), GetUnitY(target)))
        
        loop
            set u = FirstOfGroup(ug)
            exitwhen u == null
            call GroupRemoveUnit(ug, u)
            if u == target then
                if GetUnitAbilityLevel(u, 'B01G') > 0 then
                    call DummyCastTarget(Player(pid - 1), u, 'A0DS', R2I(4 * LBOOST(pid)), GetUnitX(u), GetUnitY(u), "thunderbolt")
                    call UnitDamageTarget(Hero[pid], u, dmg * 2, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                else
                    call DummyCastTarget(Player(pid - 1), u, 'A0DS', R2I(4 * LBOOST(pid)), GetUnitX(u), GetUnitY(u), "thunderbolt")
                    call UnitDamageTarget(Hero[pid], u, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                endif
            else
                if GetUnitAbilityLevel(u, 'B01G') > 0 then
                    call DummyCastTarget(Player(pid - 1), u, 'A0DS', R2I(2 * LBOOST(pid)), GetUnitX(u), GetUnitY(u), "thunderbolt")
                    call UnitDamageTarget(Hero[pid], u, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                else
                    call DummyCastTarget(Player(pid - 1), u, 'A0DS', R2I(2 * LBOOST(pid)), GetUnitX(u), GetUnitY(u), "thunderbolt")
                    call UnitDamageTarget(Hero[pid], u, dmg * 0.5, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                endif
            endif
        endloop
    endif
        
    //blizzard damager
    if source == blizzarddamager[pid] then
        set amount = 0.00
        set dmg = GetHeroInt(Hero[pid], true) * (GetUnitAbilityLevel(Hero[pid], 'A08E') * 0.25) * boost
        if LoadInteger(MiscHash, 0, GetHandleId(source)) > 0 then
            set dmg = dmg * 1.3
        endif
        call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endif
    
    //meat golem magic resist
    if damageType == SPELL and tuid == SUMMON_GOLEM and golemDevourStacks[tpid] > 0 then
        set amount = amount * (0.75 - golemDevourStacks[tpid] * 0.1)
    endif
    
    //devour stack animation
    if uid == 'h00X' then
        call RemoveUnit(source)
        set amount = 0.00
        if tuid == SUMMON_GOLEM then //meat golem
            set BorrowedLife[pid * 10] = 0
            call UnitAddBonus(meatgolem[pid], BONUS_HERO_STR, - R2I(GetHeroStr(meatgolem[pid], false) * 0.1 * golemDevourStacks[pid]))
            set golemDevourStacks[pid] = golemDevourStacks[pid] + 1
            call BlzSetHeroProperName(meatgolem[pid], "Meat Golem (" + I2S(golemDevourStacks[pid]) + ")")
            call DoFloatingTextUnit(I2S(golemDevourStacks[pid]), meatgolem[pid] , 1 , 60 , 50 , 13.5 , 255, 255, 255 , 0)
            call UnitAddBonus(meatgolem[pid], BONUS_HERO_STR, R2I(GetHeroStr(meatgolem[pid], false) * 0.1 * golemDevourStacks[pid]))
            call SetUnitScale(meatgolem[pid], 1 + golemDevourStacks[pid] * 0.07, 1 + golemDevourStacks[pid] * 0.07, 1 + golemDevourStacks[pid] * 0.07)
            //magnetic
            if golemDevourStacks[pid] == 1 then
                call UnitAddAbility(meatgolem[pid], 'A071')
            elseif golemDevourStacks[pid] == 2 then
                call UnitAddAbility(meatgolem[pid], 'A06O')
            //thunder clap
            elseif golemDevourStacks[pid] == 3 then
                call UnitAddAbility(meatgolem[pid], 'A0B0')
            elseif golemDevourStacks[pid] == 5 then
                call UnitAddBonus(meatgolem[pid], BONUS_ARMOR, R2I(BlzGetUnitArmor(meatgolem[pid]) * 0.25))
                call UnitDisableAbility(meatgolem[pid], 'A06C', true)
            endif
            call SetUnitAbilityLevel(meatgolem[pid], 'A071', golemDevourStacks[pid])
        elseif tuid == SUMMON_DESTROYER then //destroyer
            set BorrowedLife[pid * 10 + 1] = 0
            set destroyerDevourStacks[pid] = destroyerDevourStacks[pid] + 1
            call BlzSetHeroProperName(destroyer[pid], "Destroyer (" + I2S(destroyerDevourStacks[pid]) + ")")
            call DoFloatingTextUnit(I2S(destroyerDevourStacks[pid]) , destroyer[pid] , 1 , 60 , 50 , 13.5 , 255, 255, 255 , 0)
            if destroyerDevourStacks[pid] == 1 then
                call UnitAddAbility(destroyer[pid], 'A071')
                call UnitAddBonus(destroyer[pid], BONUS_HERO_INT, R2I(GetHeroInt(destroyer[pid], false) * 0.4))
            elseif destroyerDevourStacks[pid] == 2 then
                call UnitAddAbility(destroyer[pid], 'A061') //blink
            elseif destroyerDevourStacks[pid] == 3 then
                call SetUnitAbilityLevel(destroyer[pid], 'A06J', 2)
            elseif destroyerDevourStacks[pid] == 4 then
                call SetUnitAbilityLevel(destroyer[pid], 'A02D', 2)
            elseif destroyerDevourStacks[pid] == 5 then
                call UnitAddBonus(destroyer[pid], BONUS_HERO_INT, R2I(GetHeroInt(destroyer[pid], false) * 0.6))
                call UnitDisableAbility(destroyer[pid], 'A04Z', true)
            endif
            call SetUnitAbilityLevel(destroyer[pid], 'A071', destroyerDevourStacks[pid])
        endif
    endif
    
    //dungeon mobs
    if tuid == 'n01L' then //naga defender target
        set amount = amount * (1 - LoadInteger(MiscHash, GetHandleId(target), 'dmgr') * 0.1)
        if BlzGetUnitAbilityCooldownRemaining(target, 'A04K') == 0 and GetUnitLifePercent(target) < 90. then
            call IssueImmediateOrder(target, "berserk")
        elseif BlzGetUnitAbilityCooldownRemaining(target, 'A04R') == 0 and GetUnitLifePercent(target) < 80. then
            call IssueImmediateOrder(target, "battleroar")
        endif
        
        if damageType == PHYSICAL and GetUnitAbilityLevel(target, 'B04S') > 0 then
            call UnitDamageTarget(target, source, BlzGetUnitMaxHP(source) * 0.2, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif
    elseif tuid == 'n005' then //naga elite target
        set amount = amount * (1 - LoadInteger(MiscHash, GetHandleId(target), 'dmgr') * 0.1)
        if BlzGetUnitAbilityCooldownRemaining(target, 'A04V') == 0 and GetUnitLifePercent(target) < 90. then
            call IssueImmediateOrder(target, "battleroar")
        elseif BlzGetUnitAbilityCooldownRemaining(target, 'A04W') == 0 and GetUnitLifePercent(target) < 80. then
            call IssueImmediateOrder(target, "berserk")
        endif
    elseif tuid == 'O006' then //naga boss target
        set amount = amount * (1 - LoadInteger(MiscHash, GetHandleId(target), 'dmgr') * 0.1)
        if nagawaterstrikecd == false then
            set nagawaterstrikecd = true
            call TimerStart(NewTimer(), 5., true, function NagaWaterStrike)
        elseif BlzGetUnitAbilityCooldownRemaining(target, 'A05C') == 0 and GetUnitLifePercent(target) < 90. then
            call IssueImmediateOrder(target, "berserk")
        elseif BlzGetUnitAbilityCooldownRemaining(target, 'A05K') == 0 and GetUnitLifePercent(target) < 80. then
            call IssueImmediateOrder(target, "battleroar")
        endif
    elseif tuid == 'u002' then //beetle target
        if damageType == SPELL then
            set amount = 0.00
        endif
    endif
    
    if uid == 'n01L' then //naga defender source
        if damageType == PHYSICAL then
            set amount = 0.00
            
            call SaveInteger(MiscHash, GetHandleId(source), 'hits', LoadInteger(MiscHash, GetHandleId(source), 'hits') + 1)
            call DoFloatingTextUnit(I2S(LoadInteger(MiscHash, GetHandleId(source), 'hits')), target, 1.5, 50, 150., 14.5, 255, 255, 255, 0)
    
            if LoadUnitHandle(MiscHash, GetHandleId(source), 'targ') != target then
                call SaveInteger(MiscHash, GetHandleId(source), 'hits', 1)
                call SaveUnitHandle(MiscHash, GetHandleId(source), 'targ', target)
            elseif LoadInteger(MiscHash, GetHandleId(source), 'hits') > 2 then
                call NagaAutoAttack(source, BlzGetUnitMaxHP(target) * 0.7, GetUnitX(target), GetUnitY(target), 120., Condition(function isplayerunit))
                call DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", target, "origin"))
                call SaveInteger(MiscHash, GetHandleId(source), 'hits', 0)
                call SaveUnitHandle(MiscHash, GetHandleId(source), 'targ', null)
            endif

        endif
    elseif uid == 'n005' then //naga elite source
        
    elseif uid == 'u002' then //beetle source
        call DummyCastTarget(pfoe, target, 'A0DS', 16, GetUnitX(target), GetUnitY(target), "thunderbolt")
        call KillUnit(source)
    elseif uid == 'h003' then //naga water strike
        if GetWidgetLife(nagaboss) >= 0.406 then
            call UnitDamageTarget(nagaboss, target, BlzGetUnitMaxHP(target) * 0.075, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif
        call RemoveUnit(source)
    endif
        
    /*/*/*
       
    multipliers
            
    */*/*/

    //intense focus azazoth bow
    if IntenseFocus[pid] > 0 then
        set amount = amount * (1 + IntenseFocus[pid] * 0.01)
    endif

    //magnetic shockwave stance
    if GetUnitAbilityLevel(source, 'A05T') > 0 then
        set amount = amount * (0.45 + 0.05 * GetUnitAbilityLevel(source, 'A05R'))
    endif

    //tidal wave 15%
    if GetUnitAbilityLevel(target, 'B026') > 0 then
        set amount = amount * 1.15
    endif
        
    //tidal wave 10%
    if GetUnitAbilityLevel(target, 'B00Q') > 0 then
        set amount = amount * 1.1
    endif
    
    //earth elemental storm 20%
    if GetUnitAbilityLevel(target, 'B02C') > 0 then
        set amount = amount * 1.2
    endif
    
    //provoke 30%
    if GetUnitAbilityLevel(source, 'B02B') > 0 and not IsUnitInGroup(source, ProvokeTargets[GetPlayerId(GetOwningPlayer(target)) + 1]) and IsUnitType(target, UNIT_TYPE_HERO) == true then
        set amount = amount * 0.7
    endif
    
    //paladin
    if target == gg_unit_H01T_0259 then
        if damageType == PHYSICAL or (damageType == SPELL and amount >= 800) then
            if GetRandomInt(1, 5) == 1 then
                call IssueTargetOrder(gg_unit_H01T_0259, "attack", source)
                if pallyENRAGE == false then
                    call PaladinEnrage(true)
                endif
            endif
        endif
    endif
    
    //hero damage dealt
    if source == Hero[pid] then
        if DealtDmgBase[pid] > 0 and damageType == PHYSICAL then
            set amount = amount * DealtDmgBase[pid]
        endif

        //instill fear 15%
        if GetUnitAbilityLevel(target, 'B02U') > 0 and target == InstillFear[pid] then
            set amount = amount * 1.15
        endif
    endif
    
    //hero damage taken
    if target == Hero[tpid] then
        //invuln (without avul)
        if HeroInvul[tpid] then
            set amount = 0.00
        elseif damageType == PHYSICAL then
            set amount = amount * DmgTaken[tpid]
        elseif damageType == SPELL then
            set amount = amount * SpellTaken[tpid]
        endif
    endif

    //Hate Spell Reflect
    if target == PreChaosBoss[BOSS_HATE] and GetWidgetLife(target) >= 0.406 and source == Hero[pid] and spellreflectcd == false and damageType == SPELL and amount > 10000 then
        set spellreflectcd = true

        call TimerStart(NewTimer(), 5, false, function SpellReflectCD)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\ManaShield\\ManaShieldCaster.mdl", target, "origin"))
        call UnitDamageTarget(PreChaosBoss[BOSS_HATE], Hero[pid], RMinBJ(amount, 2500), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)

        set amount = RMaxBJ(0, amount - 20000)
    endif

    //adjust amount with armor formulas below

    //shield blocks
    if damageType == PHYSICAL then
        if HasItemType(target, 'I04W') and GetRandomInt(0, 99) < 20 then
            set amount = IMaxBJ(0, R2I(amount - AdjustArmorCalc(50000, source, target, damageType))) //multiply
        endif
        
        if HasItemType(target, 'I0MC') and GetRandomInt(0, 99) < 15 then
            set amount = IMaxBJ(0, R2I(amount - AdjustArmorCalc(500, source, target, damageType)))
        endif
        
        if HasItemType(target, 'I0MB') and GetRandomInt(0, 99) < 15 then
            set amount = IMaxBJ(0, R2I(amount - AdjustArmorCalc(1000, source, target, damageType)))
        endif
        
        if HasItemType(target, 'I05D') and GetRandomInt(0, 99) < 15 then
            set amount = IMaxBJ(0, R2I(amount - AdjustArmorCalc(10000, source, target, damageType)))
        endif
        
        if HasItemType(target, 'I0C2') and GetRandomInt(0, 99) < 14 then
            set amount = IMaxBJ(0, R2I(amount - AdjustArmorCalc(25000, source, target, damageType)))
        endif
        
        if HasItemType(target, 'I0C4') and GetRandomInt(0, 99) < 22 then
            set amount = IMaxBJ(0, R2I(amount - AdjustArmorCalc(75000, source, target, damageType)))
        endif
    endif

    //call for help / threat system
    if IsEnemy(tpid) then
        call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), CALL_FOR_HELP_RANGE, Condition(function FilterEnemy))
        loop
            set u = FirstOfGroup(ug)
            exitwhen u == null
            call GroupRemoveUnit(ug, u)
            if GetUnitCurrentOrder(u) == 0 then //current idle
                call UnitWakeUp(u)
                call IssueTargetOrder(u, "smart", source)
                call SaveInteger(ThreatHash, GetUnitId(u), THREAT_TARGET_INDEX, GetUnitId(source))
            endif
        endloop

        //invulnerable units dont gain threat
        if GetUnitAbilityLevel(source, 'Avul') == 0 then
            set i = LoadInteger(ThreatHash, GetUnitId(target), GetUnitId(source))

            if i < THREAT_CAP then //prevent multiple occurences
                if damageType == DAMAGE_TYPE_MAGIC then //not sure about this tbh
                    set i = i + 10
                endif

                set i = i + IMaxBJ(1, 100 - R2I(UnitDistance(target, source) * 0.12)) //~20 as melee, ~125 at 700 range
                call SaveInteger(ThreatHash, GetUnitId(target), GetUnitId(source), i)

                if i >= THREAT_CAP then
                    if GetUnitById(LoadInteger(ThreatHash, GetUnitId(target), THREAT_TARGET_INDEX)) == source then
                        call FlushChildHashtable(ThreatHash, GetUnitId(target))
                    else //switch target
                        set bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), 0, 0, 1.5)
                        call BlzSetUnitSkin(bj_lastCreatedUnit, 'h00N')
                        call SetUnitScale(bj_lastCreatedUnit, 2., 2., 2.)
                        call SetUnitFlyHeight(bj_lastCreatedUnit, 200.00, 0.)
                        call SetUnitAnimation(bj_lastCreatedUnit, "birth")
                        call TimerStart(NewTimerEx(GetUnitId(target)), 1.5, false, function SwitchAggro)
                    endif
                    call SaveInteger(ThreatHash, GetUnitId(target), THREAT_TARGET_INDEX, GetUnitId(source))
                endif
            endif
        endif
    endif

    call BlzSetEventDamage(amount)

    //body of fire
    if target == Hero[tpid] and damageType == PHYSICAL and IsUnitEnemy(target, GetOwningPlayer(source)) and GetUnitAbilityLevel(target, 'A07R') > 0 then
        set dmg = (ApplyArmorCalc(amount, source, target, damageType) * 0.05 + GetHeroStr(target, true) * 0.1) * GetUnitAbilityLevel(target, 'A07R')
        call UnitDamageTarget(target, source, dmg * BOOST(tpid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
    endif

    //ignore zero damage
    if R2I(ApplyArmorCalc(amount, source, target, damageType)) <= 0 then
        set t = null
        set u = null
        set source = null
        set target = null
        return
    endif

    //misc
    if source == Hero[pid] or IsUnitInGroup(source, SummonGroup) then
        if GetUnitLevel(target) >= 170 and IsUnitEnemy(target, GetOwningPlayer(source)) and HasItemType(Hero[pid], 'I04Q') then //demon heart
            set HeartDealt[pid] = HeartDealt[pid] + ApplyArmorCalc(amount, source, target, damageType)
            call UpdateTooltips()
        endif
        if GetUnitAbilityLevel(Hero[pid], 'B05O') > 0 then //vampiric potion
            call HP(Hero[pid], ApplyArmorCalc(amount, source, target, damageType) * 0.03)
            call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\VampiricAuraTarget.mdx", Hero[pid], "chest"))
        endif
    endif

    //dps dummy
    if target == udg_PunchingBag[1] or target == udg_PunchingBag[2] then
        if GetLocalPlayer() == Player(pid - 1) then
            call BlzFrameSetVisible(dummyFrame, true)
        endif
        set pt = TimerList[pid].getTimerWithTargetTag(null, 'pbag')
        if pt == 0 then
            set pt = TimerList[pid].addTimer(pid)
            set pt.dur = 10.
            set pt.tag = 'pbag'
            call TimerStart(pt.getTimer(), 1., true, function SUPER_DUMMY_HIDE_TEXT)
        else
            set pt.dur = 10.
        endif
        set SUPER_DUMMY_LAST = ApplyArmorCalc(amount, source, target, damageType)
        if SUPER_DUMMY_TOTAL <= 0 then
            call TimerStart(NewTimerEx(1), 1., true, function SUPER_DUMMY_DPS_UPDATE)
        endif
        set SUPER_DUMMY_TOTAL = SUPER_DUMMY_TOTAL + SUPER_DUMMY_LAST
        call PauseTimer(SUPER_DUMMY_TIMER)
        call TimerStart(SUPER_DUMMY_TIMER, 5., false, function SUPER_DUMMY_RESET)
        call SetWidgetLife(target, BlzGetUnitMaxHP(target))
    endif

    //dev stuff
    static if LIBRARY_dev then
        if BUDDHA_MODE[tpid] and target == Hero[tpid] and ApplyArmorCalc(amount, source, target, damageType) > ReduceArmorCalc(GetWidgetLife(target), source, target) then
            set amount = 0.00
            call BlzSetEventDamage(0.00)
        endif
    endif
    
    //shield index
    set i = 0
    loop
        exitwhen target == shieldtarget[i] or i > 100
        set i = i + 1
    endloop

    //dps text
    if not dmgnumber[pid] and not dmgnumber[tpid] and tuid != GRAVE then
        if isShielded[i] then
            call DoFloatingTextUnit( RealToString(ApplyArmorCalc(amount, source, target, damageType)), target, 1, 90, 0, 10, 150, 60, 240, 0 )
        elseif ignoreflag then //coded physical
            call DoFloatingTextUnit( RealToString(ApplyArmorCalc(amount, source, target, damageType)), target, 1, 90, 0, 9, 200, 50, 50, 0)
        elseif damageType == SPELL then
            call DoFloatingTextUnit( RealToString(ApplyArmorCalc(amount, source, target, damageType)), target, 1, 90, 90, 10, 100, 100, 255, 0 )
        else
            if crit > 1 then
                call DoFloatingTextUnit( RealToString(ApplyArmorCalc(amount, source, target, damageType)), target, 1, 90, 0, 10, 255, 120, 20, 0 )
            else
                if ApplyArmorCalc(amount, source, target, damageType) >= BlzGetUnitMaxHP(target) * 0.0005 or (target == udg_PunchingBag[1] or target == udg_PunchingBag[2]) then
                    call DoFloatingTextUnit( RealToString(ApplyArmorCalc(amount, source, target, damageType)), target, 1, 90, 0, 9, 200, 50, 50, 0 )
                endif
            endif
        endif
    endif
    
    set ignoreflag = false
    
    //shield mitigation
    if isShielded[i] then
        if ApplyArmorCalc(amount, source, target, damageType) >= ReduceArmorCalc(shieldhp[i], source, target) then
            set dmg = amount - ReduceArmorCalc(shieldhp[i], source, target)
            call BlzSetEventDamage(dmg)
            set amount = dmg
            //call SetWidgetLife(target, GetWidgetLife(target) + (ApplyArmorCalc(amount, source, target, damageType) - shieldhp[i]))
            call IndexShields(i)
        else
            set shieldhp[i] = shieldhp[i] - ApplyArmorCalc(amount, source, target, damageType)
            set amount = 0.00
            call BlzSetEventDamage(0.00)
            //call SetWidgetLife(target, GetWidgetLife(target) + ApplyArmorCalc(amount, source, target, damageType))
        endif
    endif
    
    //fatal hit
    if ApplyArmorCalc(amount, source, target, damageType) > ReduceArmorCalc(GetWidgetLife(target), source, target) then
        if GetUnitAbilityLevel(target, 'B005') > 0 and aoteCD[tpid] then //Armor of the Elements
            call BlzSetEventDamage(0.00)
            call SetWidgetLife(target, BlzGetUnitMaxHP(target) * 0.5)
            call UnitAddAbility(target, 'Avul')
            set aoteCD[tpid] = false
            call UnitRemoveAbility(target, 'A033')
            call UnitRemoveAbility(target, 'B005')
            call ArmorOfTheElements(target)
        endif
    endif

    //holy ward hits required
    if target == holyward then
        set amount = 0.00
        call BlzSetEventDamage(0.00)
        call SetWidgetLife(holyward, GetWidgetLife(holyward) - 1)
    endif

    call DestroyGroup(ug)

    set t = null
    set u = null
    set ug = null
    set source = null
    set target = null
endfunction
	
function DamageInit takes nothing returns nothing
    local User u = User.first

    loop
        exitwhen u == User.NULL
        call TriggerRegisterPlayerUnitEvent(BeforeArmor, u.toPlayer(), EVENT_PLAYER_UNIT_DAMAGING, function boolexp)
        //call TriggerRegisterPlayerUnitEvent(AfterArmor, u.toPlayer(), EVENT_PLAYER_UNIT_DAMAGED, function boolexp)
        set u = u.next
    endloop

    call TriggerRegisterPlayerUnitEvent(BeforeArmor, Player(8), EVENT_PLAYER_UNIT_DAMAGING, function boolexp)
    call TriggerRegisterPlayerUnitEvent(BeforeArmor, pboss, EVENT_PLAYER_UNIT_DAMAGING, function boolexp)
    call TriggerRegisterPlayerUnitEvent(BeforeArmor, Player(PLAYER_NEUTRAL_PASSIVE), EVENT_PLAYER_UNIT_DAMAGING, function boolexp)
    call TriggerRegisterPlayerUnitEvent(BeforeArmor, pfoe, EVENT_PLAYER_UNIT_DAMAGING, function boolexp)

    call TriggerAddAction(BeforeArmor, function OnDamageBeforeArmor)

    //hook UnitDamageTarget EnemyVisionAggro
endfunction
	
endlibrary
