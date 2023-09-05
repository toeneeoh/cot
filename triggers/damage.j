library DamageSystem requires Functions, Spells, Death, PVP, Bosses, Dungeons optional dev

globals
    constant integer THREAT_TARGET_INDEX = 10000
    constant integer THREAT_CAP = 4000
    trigger ACQUIRE_TRIGGER = CreateTrigger()
    hashtable ThreatHash = InitHashtable()

    trigger BeforeArmor = CreateTrigger()
    //trigger AfterArmor = CreateTrigger()
    boolean array HeroInvul
    integer array HeartBlood
    integer array BossDamage
    integer array ignoreflag
    timer SUPER_DUMMY_TIMER = CreateTimer()
    real SUPER_DUMMY_TOTAL_PHYSICAL = 0.
    real SUPER_DUMMY_TOTAL_MAGIC = 0.
    real SUPER_DUMMY_TOTAL = 0.
    real SUPER_DUMMY_LAST = 0.
    real SUPER_DUMMY_DPS = 0.

    constant damagetype PHYSICAL = DAMAGE_TYPE_NORMAL
    constant damagetype SPELL = DAMAGE_TYPE_MAGIC
    constant damagetype PURE = DAMAGE_TYPE_DIVINE
endglobals

function AcquireTarget takes nothing returns boolean
    local unit target = GetEventTargetUnit()
    local unit source = GetTriggerUnit()

    if GetUnitTypeId(source) == DUMMY then
        call BlzSetUnitWeaponBooleanField(source, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
    elseif GetPlayerController(GetOwningPlayer(source)) != MAP_CONTROL_USER then
        call SaveInteger(ThreatHash, GetUnitId(source), THREAT_TARGET_INDEX, GetUnitId(AcquireProximity(source, target, 800.)))
        call TimerStart(NewTimerEx(GetUnitId(target)), 0.03, false, function SwitchAggro)
    endif

    set target = null
    set source = null
    return false
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
        call BlzFrameSetText(dummyText, "Last Hit: " + RealToString(SUPER_DUMMY_LAST) + "\nTotal |cffE15F08Physical|r: " + RealToString(SUPER_DUMMY_TOTAL_PHYSICAL)+ "\nTotal |cff8000ffMagic|r: " + RealToString(SUPER_DUMMY_TOTAL_MAGIC)+ "\nTotal: " + RealToString(SUPER_DUMMY_TOTAL) + "\nDPS: " + RealToString(SUPER_DUMMY_DPS))
    endif

    set t = null
endfunction

function SUPER_DUMMY_RESET takes nothing returns nothing
    set SUPER_DUMMY_TOTAL_PHYSICAL = 0
    set SUPER_DUMMY_TOTAL_MAGIC = 0
    set SUPER_DUMMY_TOTAL = 0
    set SUPER_DUMMY_LAST = 0
    set SUPER_DUMMY_DPS = 0
    call BlzFrameSetText(dummyText, "Last Hit: 0 \nTotal |cffE15F08Physical|r: 0 \nTotal |cff8000ffMagic|r: 0 \nTotal: 0 \nDPS: 0")
endfunction

function ReduceArmorCalc takes real dmg, unit source, unit target returns real
    local real armor = BlzGetUnitArmor(target)
    local real value = dmg
    local integer pid = GetPlayerId(GetOwningPlayer(source)) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(target)) + 1
    local real newarmor = armor

    if Buff.has(source, source, RampageBuff.typeid) then //rampage
        set newarmor = (RMaxBJ(0, armor - armor * (5 * GetUnitAbilityLevel(Hero[pid], RAMPAGE.id)) * 0.01))
    endif

    if Buff.has(source, target, PiercingStrikeDebuff.typeid) then //piercing strikes
        set newarmor = (RMaxBJ(0, armor - armor * (30 + GetUnitAbilityLevel(Hero[pid], 'A0QU')) * 0.01))
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

function CalcAfterReductions takes real dmg, unit source, unit target, damagetype TYPE returns real //after
    local real armor = BlzGetUnitArmor(target)
    local real value = dmg
    local integer pid = GetPlayerId(GetOwningPlayer(source)) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(target)) + 1
    local integer dtype = BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE)
    local integer atype = BlzGetUnitWeaponIntegerField(source, UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0)

    if TYPE != PURE then
        if (dtype == 6 or dtype == 7) then //chaos armor
            set value = value * 0.03
        endif

        if TYPE == PHYSICAL then
            if atype == 5 then
                set value = value * 350.
            endif

            if armor >= 0 then
                set value = value - (value * (0.05 * armor / (1. + 0.05 * armor)))
            else
                set value = value * (2. - Pow(0.94, (-armor)))
            endif
        endif
    endif

    return value
endfunction

function OnDamage takes nothing returns boolean
    local unit source = GetEventDamageSource()
    local unit target = BlzGetEventDamageTarget()
    local real amount = GetEventDamage()
    //local real finalAmount = initAmount
    local damagetype damageType = BlzGetEventDamageType()
    local integer pid = GetPlayerId(GetOwningPlayer(source)) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(target)) + 1
    local integer uid = GetUnitTypeId(source)
    local integer tuid = GetUnitTypeId(target)
    local integer ablevel = 0
    local real dmg = 0.
    local real crit = 0.
    local real unitangle = 0.
    local integer i = 0
    local integer i2 = 0
    local timer t = null
    local unit u = null
    local group ug = CreateGroup()
    local boolean zeroDamage = false
    local PlayerTimer pt
    local Spell spell

    //force unknown damage to magic damage?
    if damageType != PHYSICAL and damageType != SPELL and damageType != PURE then
        set damageType = SPELL
        call BlzSetEventDamageType(SPELL)
    endif

    //physical attack procs
    if damageType == PHYSICAL and IsUnitEnemy(target, GetOwningPlayer(source)) then
        //frost armor debuff
        if Buff.has(target, target, FrostArmorBuff.typeid) then
            set FrostArmorDebuff.add(target, source).duration = 3.
        endif

        if target == Hero[tpid] then //hitting a hero
            //evasion
            if TotalEvasion[tpid] > 0 and GetRandomInt(0, 99) < TotalEvasion[tpid] then
                call DoFloatingTextUnit("Dodged!", target, 1, 90, 0, 9, 180, 180, 20, 0)
                set amount = 0.00
            else
                //heart of demon prince damage taken
                if GetUnitLevel(source) >= 170 and IsUnitEnemy(source, GetOwningPlayer(target)) and HasItemType(target, 'I04Q') then
                    set HeartBlood[tpid] = HeartBlood[tpid] + 1
                    call UpdateItemTooltips(tpid)
                endif
                //death knight on hit
                if not ChaosMode and source == Boss[BOSS_DEATH_KNIGHT] and GetRandomInt(0, 99) < 20 then
                    call UnitDamageTarget(source, target, 5000, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                    call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl", target, "origin"))
                endif
                //legion on hit
                if uid == 'H04R' and damageType == PHYSICAL then
                    if IsUnitIllusion(source) then
                        call UnitDamageTarget(source, target, BlzGetUnitMaxHP(target) / 400., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                    else
                        call UnitDamageTarget(source, target, BlzGetUnitMaxHP(target) / 200., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                    endif
                endif
            endif
            //ursa elder frost nova
            if uid == 'nfpe' and BlzGetUnitAbilityCooldownRemaining(source, 'ACfn') <= 0 then
                call IssueTargetOrder(source, "frostnova", target)
            endif
            //forgotten one tentacle
            if uid == 'n08M' and GetRandomInt(1,5) == 1 then
                call IssueImmediateOrder(source, "waterelemental")
            endif
        endif

        //hero physical attacks
        if IsUnitType(source, UNIT_TYPE_HERO) == true and ignoreflag[pid] != 1 then
            //item effects

            //onhit magic damage (king's clubba)
            if GetUnitAbilityLevel(source, 'Abon') > 0 then
                call UnitDamageTarget(source, target, GetAbilityField(source, 'Abon', 0), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif

            //assassin blade spin count
            if uid == HERO_ASSASSIN then
                set BladeSpinCount[pid] = BladeSpinCount[pid] + 1
            endif

            //vampire blood bank
            if uid == HERO_VAMPIRE then
                set BloodBank[pid] = RMinBJ(BloodBank[pid] + 0.75 * GetHeroStr(Hero[pid], true), 200 * GetHeroInt(Hero[pid], true))

                //vampire blood lord
                if GetUnitAbilityLevel(source, 'A099') > 0 then
                    call UnitDamageTarget(source, target, (0.75 * GetHeroAgi(source, true) + 1 * GetHeroStr(source, true)) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                    call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", target, "chest"))
                endif
            endif

            //master rogue piercing strike
            if GetRandomInt(0, 99) < 20 and GetUnitAbilityLevel(source, PIERCINGSTRIKE.id) > 0 then
                set PiercingStrikeDebuff.add(source, target).duration = 3.
                call SetUnitAnimation(source, "spell slam")
            endif

            if Buff.has(source, target, PiercingStrikeDebuff.typeid) then
                set amount = ReduceArmorCalc(amount, source, target)
            endif

            //bloodzerker
            if uid == HERO_BLOODZERKER then
                //blood cleave
                if GetUnitAbilityLevel(source, BLOODCLEAVE.id) > 0 and ignoreflag[pid] != 2 then
                    set spell = BLOODCLEAVE.get(pid)

                    set i = R2I(spell.values[0])

                    if Buff.has(source, source, RampageBuff.typeid) then
                        set i = i + 5
                    endif

                    if Buff.has(source, source, UndyingRageBuff.typeid) then
                        set i = i * 2
                    endif

                    if GetRandomReal(0, 99) < i * LBOOST[pid] then
                        set dmg = 0
                        set ignoreflag[pid] = 2
                        call MakeGroupInRange(pid, ug, GetUnitX(source), GetUnitY(source), spell.values[1] * LBOOST[pid], Condition(function FilterEnemy))
                        call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Reapers Claws Red.mdx", source, "chest"))

                        loop
                            set u = FirstOfGroup(ug)
                            exitwhen u == null
                            call GroupRemoveUnit(ug, u)
                            call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", u, "chest"))
                            set dmg = dmg + CalcAfterReductions(spell.values[2] * BOOST[pid], source, target, PHYSICAL)
                            call UnitDamageTarget(source, u, spell.values[2] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
                        endloop

                        set ignoreflag[pid] = 0

                        //leech health
                        call HP(source, dmg * 0.5)
                    endif

                    call spell.destroy()
                endif

                //rampage armor ignore
                if Buff.has(source, source, RampageBuff.typeid) then
                    set amount = ReduceArmorCalc(amount, source, target)
                endif
            endif

            //thunderblade overload
            if uid == HERO_THUNDERBLADE and overloadActive[pid] then
                set spell = OVERLOAD.get(pid)

                if GetRandomReal(0, 99) < spell.values[0] * LBOOST[pid] then
                    call UnitDamageTarget(source, target, spell.values[1] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                    call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", target, "origin"))
                    call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", target, "origin"))
                endif

                call spell.destroy()
            endif

            // master rogue
            if uid == HERO_MASTER_ROGUE then 
                //backstab
                if GetUnitAbilityLevel(source, BACKSTAB.id) > 0 then
                    set spell = BACKSTAB.get(pid)

                    set unitangle = bj_RADTODEG * Atan2(GetUnitY(target)-GetUnitY(source), GetUnitX(target)-GetUnitX(source))
                    if unitangle < 0 then
                        set unitangle = unitangle + 360
                    endif
                    if RAbsBJ(unitangle - GetUnitFacing(target)) < 45 and (IsUnitType(target,UNIT_TYPE_STRUCTURE) == false) then
                        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "chest"))
                        call UnitDamageTarget(source, target, spell.values[0] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                    endif

                    call spell.destroy()
                endif
                //instant death
                if GetUnitAbilityLevel(source, INSTANTDEATH.id) > 0 then
                    set spell = INSTANTDEATH.get(pid)

                    if HiddenGuise[pid] then
                        set HiddenGuise[pid] = false
                        set crit = crit + spell.values[1]
                    else
                        if GetUnitAbilityLevel(source,'A0QP') > 0 and RAbsBJ(unitangle - GetUnitFacing(target)) < 45 and (IsUnitType(target,UNIT_TYPE_STRUCTURE) == false) then
                            if GetRandomInt(0, 99) < spell.values[0] * 2 * LBOOST[pid] then
                                set crit = crit + spell.values[1]
                            endif
                        else
                            if GetRandomInt(0, 99) < spell.values[0] * LBOOST[pid] then
                                set crit = crit + spell.values[1]
                            endif
                        endif
                    endif

                    call spell.destroy()
                endif
            endif

            //phoenix ranger fiery arrows / flaming bow
            if uid == HERO_PHOENIX_RANGER then
                if GetUnitAbilityLevel(source,'A0IB') > 0 then
                    set ablevel= GetUnitAbilityLevel(source, 'A0IB')
                    if GetRandomInt(0,99) < ablevel * 2 * LBOOST[pid] then
                        call UnitDamageTarget(source, target, (((UnitGetBonus(source, BONUS_DAMAGE) + GetHeroAgi(source, true)) * .3 + GetHeroAgi(source, true) * ablevel)) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                        call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX(target),GetUnitY(target)))
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
                    set FlamingBowBonus[pid] = (0.5 + 0.0001 * FlamingBowCount[pid]) * (GetHeroAgi(source, true) + UnitGetBonus(source, BONUS_DAMAGE)) * LBOOST[pid]
                    call UnitAddBonus(source, BONUS_DAMAGE, R2I(FlamingBowBonus[pid]))
                endif
            endif

            //holy bash (savior)
            if GetUnitAbilityLevel(source, HOLYBASH.id) > 0 and uid == HERO_SAVIOR then
                set ablevel = GetUnitAbilityLevel(source, HOLYBASH.id)
                set saviorBashCount[pid] = saviorBashCount[pid] + 1
                if saviorBashCount[pid] > 10 then
                    set spell = HOLYBASH.get(pid)
                    call UnitDamageTarget(source, target, spell.values[0] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                    set saviorBashCount[pid] = 0

                    set pt = TimerList[pid].get(source, null, 'Ltsl')

                    //light seal augment
                    if pt != 0 then
                        call MakeGroupInRange(pid, pt.ug, pt.x, pt.y, pt.aoe, Condition(function FilterEnemy))

                        loop
                            set u = FirstOfGroup(pt.ug)
                            exitwhen u == null
                            call GroupRemoveUnit(pt.ug, u)
                            if u != target then
                                call StunUnit(pid, u, 2.)
                                call UnitDamageTarget(source, u, spell.values[0] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                            endif
                        endloop
                    endif

                    call StunUnit(pid, target, 2.)

                    //aoe heal
                    call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), spell.values[1] * LBOOST[pid], Condition(function FilterAlly))

                    loop
                        set u = FirstOfGroup(ug)
                        exitwhen u == null
                        call GroupRemoveUnit(ug, u)
                        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", u, "origin")) //change effect
                        call HP(u, spell.values[2] * BOOST[pid])
                    endloop

                    call spell.destroy()
                endif
            endif

            //bard encore (song of war)
            if LoadInteger(EncoreTargets, GetHandleId(source), 0) > 0 then
                call SaveInteger(EncoreTargets, GetHandleId(source), 0, LoadInteger(EncoreTargets, GetHandleId(source), 0) - 1)
                set ablevel = GetUnitAbilityLevel(Hero[LoadInteger(EncoreTargets, GetHandleId(source), 1)], 'A0AZ')
                call UnitDamageTarget(source, target, (.25 + .25 * ablevel) * GetHeroStat(MainStat(source), source, true) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif

            //demon hound critical strike (dark summoner)
            if uid == SUMMON_HOUND then
                if GetRandomInt(0, 99) < 25 then
                    if destroyerSacrificeFlag[pid] then
                        call DemonHoundAOE(source, target)
                    else
                        call UnitDamageTarget(source, target, GetHeroInt(source, true) * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                    endif
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", GetUnitX(target), GetUnitY(target)))
                endif
            endif

            //destroyer critical strike (dark summoner)
            if uid == SUMMON_DESTROYER then
                set ablevel = 10

                if destroyerDevourStacks[pid] >= 2 then
                    if GetRandomInt(0, 99) < 25 then
                        set crit = crit + 3
                    endif

                    if destroyerDevourStacks[pid] >= 4 then
                        set ablevel = 15
                    endif
                endif
            
                if GetRandomInt(0, 99) < ablevel then
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", GetUnitX(target), GetUnitY(target)))
                    call UnitDamageTarget(source, target, GetHeroInt(source, true) * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                endif
            endif

            //dark savior dark blade
            if GetUnitAbilityLevel(source, 'B01A') > 0 then
                call UnitDamageTarget(source, target, GetHeroInt(source, true) * (0.6 + GetUnitAbilityLevel(source, 'AEim') * 0.1) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                if GetUnitManaPercent(source) >= 0.5 then
                    if metamorphosis[pid] > 0 then
                        call SetUnitManaPercentBJ(source, (GetUnitManaPercent(source) + 0.5))
                    else
                        call SetUnitManaPercentBJ(source, (GetUnitManaPercent(source) - 1.00))
                    endif
                else
                    call IssueImmediateOrder(source, "unimmolation")
                endif
            endif

            //oblivion guard infernal strike / magnetic strike
            if Buff.has(source, source, InfernalStrikeBuff.typeid) or Buff.has(source, source, MagneticStrikeBuff.typeid) then
                set BodyOfFireCharges[pid] = BodyOfFireCharges[pid] - 1

                if GetLocalPlayer() == Player(pid - 1) then
                    call BlzSetAbilityIcon(BODYOFFIRE.id, "ReplaceableTextures\\CommandButtons\\PASBodyOfFire" + I2S(BodyOfFireCharges[pid]) + ".blp")
                endif

                set Buff.get(source, source, InfernalStrikeBuff.typeid).duration = 0.
                set Buff.get(source, source, MagneticStrikeBuff.typeid).duration = 0.

                //disable casting at 0 charges
                if BodyOfFireCharges[pid] <= 0 then
                    call UnitDisableAbility(source, INFERNALSTRIKE.id, true)
                    call BlzUnitHideAbility(source, INFERNALSTRIKE.id, false)
                    call UnitDisableAbility(source, MAGNETICSTRIKE.id, true)
                    call BlzUnitHideAbility(source, MAGNETICSTRIKE.id, false)
                endif

                //refresh charge timer
                set pt = TimerList[pid].get(source, null, 'bofi')
                if pt == 0 then
                    set pt = TimerList[pid].addTimer(pid)
                    set pt.caster = source
                    set pt.tag = 'bofi'

                    call BlzStartUnitAbilityCooldown(source, BODYOFFIRE.id, 5.)
                    call TimerStart(pt.timer, 5., true, function BodyOfFireChargeCD)
                endif

                if Buff.has(source, source, InfernalStrikeBuff.typeid) then
                    set amount = 0.00

                    set ignoreflag[pid] = 1
                    set ablevel = GetUnitAbilityLevel(source, INFERNALSTRIKE.id)

                    call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 250. * LBOOST[pid], Condition(function FilterEnemy))
                    set i = BlzGroupGetSize(ug)

                    loop
                        set u = FirstOfGroup(ug)
                        exitwhen u == null
                        call GroupRemoveUnit(ug, u)
                        if IsUnitType(u, UNIT_TYPE_HERO) then
                            set i = i + 4
                        endif
                        set i2 = BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE)

                        if i2 == 7 then //chaos boss
                            call UnitDamageTarget(source, u, ((GetHeroStr(source, true) * ablevel) + GetWidgetLife(u) * (0.25 + 0.05 * ablevel)) * 7.5 * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
                        elseif i2 == 6 then
                            call UnitDamageTarget(source, u, ((GetHeroStr(source, true) * ablevel) + GetWidgetLife(u) * (0.25 + 0.05 * ablevel)) * 15. * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
                        elseif i2 == 1 then //prechaos boss
                            call UnitDamageTarget(source, u, ((GetHeroStr(source, true) * ablevel) + GetWidgetLife(u) * (0.25 + 0.05 * ablevel)) * 0.5 * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
                        elseif i2 == 0 then
                            call UnitDamageTarget(source, u, ((GetHeroStr(source, true) * ablevel) + GetWidgetLife(u) * (0.25 + 0.05 * ablevel)) * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
                        endif
                    endloop

                    set ignoreflag[pid] = 0

                    call DestroyEffect(AddSpecialEffect("war3mapImported\\Lava_Slam.mdx", GetUnitX(target), GetUnitY(target)))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))

                    //6% max heal
                    call HP(source, BlzGetUnitMaxHP(source) * 0.01 * IMinBJ(6, i))
                elseif Buff.has(source, source, MagneticStrikeBuff.typeid) then
                    call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 250. * LBOOST[pid], Condition(function FilterEnemy))

                    loop
                        set u = FirstOfGroup(ug)
                        exitwhen u == null
                        call GroupRemoveUnit(ug, u)
                        set MagneticStrikeDebuff.add(source, target).duration = 10.
                    endloop


                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", GetUnitX(target), GetUnitY(target)))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))
                endif
            endif

            set i = 3
            //arcanist cds
            if arcanosphereActive[pid] then
                call BlzStartUnitAbilityCooldown(Hero[pid], 'A08X', RMaxBJ(0.01, BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A08X') - 3.))
                call BlzStartUnitAbilityCooldown(Hero[pid], 'A08S', RMaxBJ(0.01, BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A08S') - 3.))
            else
                call BlzStartUnitAbilityCooldown(Hero[pid], 'A05Q', RMaxBJ(0.01, BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A05Q') - 3.))
                call BlzStartUnitAbilityCooldown(Hero[pid], 'A02N', RMaxBJ(0.01, BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A02N') - 3.))
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
                
            //item crits (players)
            if source == Hero[pid] then
                set i = 0

                loop
                    exitwhen i > 5
                    set i2 = GetItemUserData(UnitItemInSlot(Hero[pid], i))

                    if GetRandomInt(0, 99) < Item(i2).calcStat(ITEM_CRIT_CHANCE, 0) then
                        set crit = crit + Item(i2).calcStat(ITEM_CRIT_DAMAGE, 0)
                    endif

                    set i = i + 1
                endloop
            endif

            //elite marksman sniper stance
            if uid == HERO_MARKSMAN_SNIPER then
                set spell = SNIPERSTANCE.get(pid)
                set crit = spell.values[0]
                call spell.destroy()
            endif

            //crit multiplier
            if crit > 0 then
                set amount = amount * crit
            endif
        endif
    elseif damageType == SPELL and IsEnemy(tpid) then //enemy magic resist
        //creeps
        if GetUnitAbilityLevel(target, 'A04A') > 0 then //30%
            set amount = amount * 0.7
        endif

        //protected existence
        if GetUnitAbilityLevel(target, 'Aexi') > 0 then
            set amount = amount * 0.66
        endif

        //astral shield
        if GetUnitAbilityLevel(target, 'Azas') > 0 then
            set amount = amount * 0.33
        endif
        
        //hellfire shield
        if HasItemType(target, 'I03Y') then
            set amount = amount * 0.5
        endif

        if tuid == 'U00G' or tuid == 'H045' then //hellfire / mystic bonus magic resist
            set amount = amount * 0.5
        endif
    endif
        
    /*/*/*
    
    misc
        
    */*/*/

    //summon fatal damage
    if IsUnitInGroup(target, SummonGroup) and CalcAfterReductions(amount, source, target, damageType) > ReduceArmorCalc(GetWidgetLife(target), source, target) then
        set amount = 0.00
        call SummonExpire(target)
    endif

    //searing arrow (phoenix ranger)
    if uid == DUMMY and GetUnitAbilityLevel(source, 'A069') > 0 then
        call UnitRemoveAbility(source, 'A069')
        call DummyCastTarget(Player(pid - 1), target, 'A092', 1, GetUnitX(source), GetUnitY(source), "slow")
        call UnitDamageTarget(Hero[pid], target, (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroAgi(Hero[pid], true)) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endif

    //electrocute lightning
    if uid == DUMMY and GetUnitAbilityLevel(source, 'A09W') > 0 then
        call UnitRemoveAbility(source, 'A09W')
        call UnitDamageTarget(Hero[pid], target, GetWidgetLife(target) * 0.005, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_DIVINE, WEAPON_TYPE_WHOKNOWS)
    endif

    //medean lightning trigger
    if uid == DUMMY and GetUnitAbilityLevel(source, 'A01Y') > 0 then
        set dmg = (GetHeroInt(Hero[pid], true) * (1.5 + 0.5 * GetUnitAbilityLevel(Hero[pid], 'A019'))) * BOOST[pid]

        call UnitRemoveAbility(source, 'A01Y')
        call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endif

    //frozen orb icicle
    if uid == DUMMY and GetUnitAbilityLevel(source, 'A09F') > 0 then
        call UnitDamageTarget(Hero[pid], target, GetHeroInt(Hero[pid], true) * (0.5 + 0.5 * GetUnitAbilityLevel(Hero[pid], 'A011')) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS) 
    endif

    //satan flame strike
    set i = LoadInteger(MiscHash, GetHandleId(source), 'sflm')
    if uid == DUMMY and i > 0 and IsUnitEnemy(target, pboss) then
        call SaveInteger(MiscHash, GetHandleId(source), 'sflm', i - 1)
        call UnitDamageTarget(Boss[BOSS_SATAN], target, 10000, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS) 
    endif

    //instill fear trigger
    if uid == DUMMY and GetUnitAbilityLevel(source, 'A0AE') > 0 then
        call UnitRemoveAbility(source, 'A0AE')
        set InstillFear[pid] = target
        call TimerStart(NewTimerEx(pid), 7., false, function InstillFearExpire)
    endif

    //single shot trigger
    if uid == DUMMY and GetUnitAbilityLevel(source, 'A05J') > 0 then
        call UnitRemoveAbility(source, 'A05J')
    endif

    //nerve gas trigger
    if tuid == DUMMY and GetUnitAbilityLevel(source, 'A01X') > 0 then
        set spell = NERVEGAS.get(pid)

        call UnitRemoveAbility(source, 'A01X')
		call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), spell.values[0] * LBOOST[pid], Condition(function FilterEnemy))
        set i = BlzGroupGetSize(ug)
        call RemoveUnitTimed(source, 5.)
        call RemoveUnitTimed(target, 5.)
        if i > 0 then
            set pt = TimerList[pid].addTimer(pid)
            set pt.dmg = spell.values[1] * BOOST[pid]
            set pt.dur = spell.values[2] * LBOOST[pid]
            set pt.armor = pt.dur //keep track of initial duration
            set pt.agi = 0
            set pt.ug = CreateGroup()
            call BlzGroupAddGroupFast(ug, pt.ug)
            loop
                set u = BlzGroupUnitAt(pt.ug, pt.agi)
                set NerveGasDebuff.add(Hero[pid], u).duration = 10.
                set pt.agi = pt.agi + 1
                exitwhen pt.agi >= i 
            endloop
            call TimerStart(pt.timer, 0.5, true, function NerveGas)
        endif

        call spell.destroy()
    endif
        
    //frost blast trigger
    if uid == DUMMY and GetUnitAbilityLevel(source, 'A04B') > 0 then
        set spell = FROSTBLAST.get(pid)

        call UnitRemoveAbility(source, 'A04B')
        set amount = 0.00
        set dmg = spell.values[0] * BOOST[pid]
        
        call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), spell.values[1] * LBOOST[pid], Condition(function FilterEnemy))
    
        if GetUnitAbilityLevel(Hero[pid], 'B01I') > 0 then
            call UnitRemoveAbility(Hero[pid], 'B01I')
            set dmg = dmg * 2
        endif
        
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetUnitX(target), GetUnitY(target)))
        
        loop
            set u = FirstOfGroup(ug)
            exitwhen u == null
            call GroupRemoveUnit(ug, u)
            if u == target then
                set Freeze.add(Hero[pid], target).duration = spell.values[2] * LBOOST[pid]
                call UnitDamageTarget(Hero[pid], u, dmg * (GetUnitAbilityLevel(u, 'B01G') + 1.), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            else
                set Freeze.add(Hero[pid], target).duration = spell.values[2] * 0.5 * LBOOST[pid]
                call UnitDamageTarget(Hero[pid], u, dmg / (2. - GetUnitAbilityLevel(u, 'B01G')), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
        endloop

        call spell.destroy()
    endif
        
    //blizzard 
    if uid == DUMMY and GetUnitAbilityLevel(source, 'A02O') > 0 then 
        set amount = 0.00
        set pt = TimerList[pid].get(source, null, 'bliz')
        set dmg = pt.dmg
        if pt.agi == 1 then
            set dmg = dmg * 1.3
        endif
        call UnitDamageTarget(Hero[pid], target, dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endif
    
    //meat golem magic resist
    if damageType == SPELL and tuid == SUMMON_GOLEM and golemDevourStacks[tpid] > 0 then
        set amount = amount * (0.75 - golemDevourStacks[tpid] * 0.1)
    endif
    
    //devour handling (dark summoner)
    if uid == DUMMY and GetUnitAbilityLevel(source, 'A00W') > 0 then
        if tuid == SUMMON_GOLEM then //meat golem
            set BorrowedLife[pid * 10] = 0
            call UnitAddBonus(meatgolem[pid], BONUS_HERO_STR, - R2I(GetHeroStr(meatgolem[pid], false) * 0.1 * golemDevourStacks[pid]))
            set golemDevourStacks[pid] = golemDevourStacks[pid] + 1
            call BlzSetHeroProperName(meatgolem[pid], "Meat Golem (" + I2S(golemDevourStacks[pid]) + ")")
            call DoFloatingTextUnit(I2S(golemDevourStacks[pid]), meatgolem[pid], 1, 60, 50, 13.5, 255, 255, 255, 0)
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
                call UnitAddBonus(meatgolem[pid], BONUS_ARMOR, R2I(BlzGetUnitArmor(meatgolem[pid]) * 0.25 + 0.5))
            endif
            if golemDevourStacks[pid] >= GetUnitAbilityLevel(Hero[pid], 'A063') + 1 then
                call UnitDisableAbility(meatgolem[pid], 'A06C', true)
            endif
            call SetUnitAbilityLevel(meatgolem[pid], 'A071', golemDevourStacks[pid])
        elseif tuid == SUMMON_DESTROYER then //destroyer
            set BorrowedLife[pid * 10 + 1] = 0
            call UnitAddBonus(destroyer[pid], BONUS_HERO_INT, - R2I(GetHeroInt(destroyer[pid], false) * 0.15 * destroyerDevourStacks[pid]))
            set destroyerDevourStacks[pid] = destroyerDevourStacks[pid] + 1
            call UnitAddBonus(destroyer[pid], BONUS_HERO_INT, R2I(GetHeroInt(destroyer[pid], false) * 0.15 * destroyerDevourStacks[pid]))
            call BlzSetHeroProperName(destroyer[pid], "Destroyer (" + I2S(destroyerDevourStacks[pid]) + ")")
            call DoFloatingTextUnit(I2S(destroyerDevourStacks[pid]), destroyer[pid], 1, 60, 50, 13.5, 255, 255, 255, 0)
            if destroyerDevourStacks[pid] == 1 then
                call UnitAddAbility(destroyer[pid], 'A071')
                call UnitAddAbility(destroyer[pid], 'A061') //blink
            elseif destroyerDevourStacks[pid] == 2 then
                call UnitAddAbility(destroyer[pid], 'A03B') //crit
            elseif destroyerDevourStacks[pid] == 3 then
                call SetHeroAgi(destroyer[pid], 200, true)
            elseif destroyerDevourStacks[pid] == 4 then
                call SetUnitAbilityLevel(destroyer[pid], 'A02D', 2)
            elseif destroyerDevourStacks[pid] == 5 then
                call SetHeroAgi(destroyer[pid], 400, true)
                call UnitAddBonus(destroyer[pid], BONUS_HERO_INT, R2I(GetHeroInt(destroyer[pid], false) * 0.25))
            endif
            if destroyerDevourStacks[pid] >= GetUnitAbilityLevel(Hero[pid], 'A063') + 1 then
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
        set Stun.add(source, target).duration = 8.
        call KillUnit(source)
    elseif uid == 'h003' then //naga water strike
        if UnitAlive(nagaboss) then
            call UnitDamageTarget(nagaboss, target, BlzGetUnitMaxHP(target) * 0.075, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif
        call RemoveUnit(source)
    endif
        
    /*/*/*
       
    multipliers
            
    */*/*/

    //hardmode spell damage multiplier
    if IsEnemy(pid) and HardMode > 0 and damageType == SPELL then
        set amount = amount * 2
    endif

    //warrior intimidating shout limit break spell damage reduction 40%
    if Buff.has(null, source, IntimidatingShoutDebuff.typeid) and damageType == SPELL then
        if limitBreak[IntimidatingShoutDebuff(Buff.get(null, source, IntimidatingShoutDebuff.typeid)).pid] == 3 then
            set amount = amount * 0.6
        endif
    endif

    //warrior parry
    if Buff.has(target, target, ParryBuff.typeid) and amount > 0. then
        set amount = 0.00
        set spell = PARRY.get(tpid)

        call ParryBuff(Buff.get(target, target, ParryBuff.typeid)).playSound()

        if limitBreak[tpid] == 1 then
            call UnitDamageTarget(target, source, spell.values[0] * 2., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        else
            call UnitDamageTarget(target, source, spell.values[0], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif

        call spell.destroy()
    endif

    //oblivion guard magnetic strike
    if Buff.has(null, target, MagneticStrikeDebuff.typeid) and damageType == SPELL then
        set amount = amount * 1.25
    endif

    //dark savior metamorphosis
    set amount = amount * (1. + metamorphosis[pid])

    //intense focus azazoth bow
    set amount = amount * (1. + IntenseFocus[pid] * 0.01)

    //magnetic stance
    if GetUnitAbilityLevel(source, 'B02E') > 0 then
        set amount = amount * (0.45 + 0.05 * GetUnitAbilityLevel(source, 'B02E'))
    endif

    //tidal wave 15%
    if GetUnitAbilityLevel(target, 'B026') > 0 then
        set amount = amount * 1.15
    endif
        
    //tidal wave 10%
    if Buff.has(null, target, TidalWaveDebuff.typeid) then
        set amount = amount * (1. + TidalWaveDebuff(Buff.get(null, target, TidalWaveDebuff.typeid)).percent)
    endif
    
    //earth elemental storm damage amp
    if GetUnitAbilityLevel(target, 'B04P') > 0 then
        set amount = amount * (1 + 0.04 * GetUnitAbilityLevel(target, 'A04P'))
    endif
    
    //provoke 30%
    if GetUnitAbilityLevel(source, 'B02B') > 0 and IsUnitType(target, UNIT_TYPE_HERO) == true then
        set amount = amount * 0.75
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

    //spell reflect (hate)
    if GetUnitAbilityLevel(target, 'A00S') > 0 and UnitAlive(target) and BlzGetUnitAbilityCooldownRemaining(target, 'A00S') <= 0 and damageType == SPELL and amount > 10000 then
        set unitangle = Atan2(GetUnitY(source) - GetUnitY(target), GetUnitX(source) - GetUnitX(target))
        set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\BoneArmorCasterTC.mdx", GetUnitX(target) + 75. * Cos(unitangle), GetUnitY(target) + 75. * Sin(unitangle))

        call BlzSetSpecialEffectZ(bj_lastCreatedEffect, BlzGetUnitZ(target) + 80.)
        call BlzSetSpecialEffectColorByPlayer(bj_lastCreatedEffect, Player(0))
        call BlzSetSpecialEffectYaw(bj_lastCreatedEffect, unitangle)
        call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 0.9)
        call BlzSetSpecialEffectTimeScale(bj_lastCreatedEffect, 3.)

        call DestroyEffect(bj_lastCreatedEffect)

        call BlzStartUnitAbilityCooldown(target, 'A00S', 5.)
        //call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\ManaShield\\ManaShieldCaster.mdl", target, "origin"))
        call UnitDamageTarget(target, source, RMinBJ(amount, 2500), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)

        set amount = RMaxBJ(0, amount - 20000)
    endif

    //shield damage reduction
    if damageType == PHYSICAL then
        
        set i = 0
        set i2 = 'Zs00' //starting id
        loop
            exitwhen i2 > 'Zs99' //allowing for 100 different shields (0-99)

            if GetUnitAbilityLevel(target, i2) > 0 and GetRandomInt(0, 99) < GetAbilityField(target, i2, 0) then
                set amount = amount * (1. - GetAbilityField(target, i2, 1) * 0.01)
            endif
            
            set i = i + 1
            set i2 = i2 + 1

            if i > 9 then
                set i = 0
                set i2 = i2 + 0xF6 //246
            endif
        endloop
    endif

    //threat system / boss handling
    if IsEnemy(tpid) and uid != DUMMY then
        //call for help
        call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), CALL_FOR_HELP_RANGE, Condition(function FilterEnemy))
        loop
            set u = FirstOfGroup(ug)
            exitwhen u == null
            call GroupRemoveUnit(ug, u)
            if GetUnitCurrentOrder(u) == 0 and u != target then //current idle
                call UnitWakeUp(u)
                call IssueTargetOrder(u, "smart", AcquireProximity(u, source, 800.))
            endif
        endloop

        //if you attack stop the reset timer
        call TimerList[pid].stopAllTimersWithTag('aggr')

        if IsBoss(tuid) != -1 then
            //boss spell casting
            call BossSpellCasting(source, target)

            //invulnerable units dont gain threat
            if damageType == PHYSICAL and GetUnitAbilityLevel(source, 'Avul') == 0 then //only physical because magic procs are too inconsistent 
                set i = LoadInteger(ThreatHash, GetUnitId(target), GetUnitId(source))

                if i < THREAT_CAP then //prevent multiple occurences
                    set i = i + IMaxBJ(1, 100 - R2I(UnitDistance(target, source) * 0.12)) //~40 as melee, ~250 at 700 range
                    call SaveInteger(ThreatHash, GetUnitId(target), GetUnitId(source), i)

                    if i >= THREAT_CAP then
                        if GetUnitById(LoadInteger(ThreatHash, GetUnitId(target), THREAT_TARGET_INDEX)) == source then
                            call FlushChildHashtable(ThreatHash, GetUnitId(target))
                        else //switch target
                            set bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), 0, 0, 1.5)
                            call BlzSetUnitSkin(bj_lastCreatedUnit, 'h00N')
                            if GetLocalPlayer() == Player(pid - 1) then
                                call BlzSetUnitSkin(bj_lastCreatedUnit, 'h01O')
                            endif
                            call SetUnitScale(bj_lastCreatedUnit, 2.5, 2.5, 2.5)
                            call SetUnitFlyHeight(bj_lastCreatedUnit, 250.00, 0.)
                            call SetUnitAnimation(bj_lastCreatedUnit, "birth")
                            call TimerStart(NewTimerEx(GetUnitId(target)), 1.5, false, function SwitchAggro)
                        endif
                        call SaveInteger(ThreatHash, GetUnitId(target), THREAT_TARGET_INDEX, GetUnitId(source))
                    endif
                endif
            endif

            set i = 0

            loop
                exitwhen BossID[i] == tuid or i > BOSS_TOTAL
                set i = i + 1
            endloop

            //keep track of player percentage damage
            set BossDamage[BOSS_TOTAL * i + pid] = BossDamage[BOSS_TOTAL * i + pid] + R2I(CalcAfterReductions(amount, source, target, damageType) * 0.001)
        endif
    endif

    //pure damage multiplier against chaos armor
    if damageType == PURE and (BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE) == 6 or BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE) == 7) then
        call BlzSetEventDamage(amount / 0.03)
    else
        //set final event damage
        call BlzSetEventDamage(amount)
    endif

    //==================
    //after calculations
    //==================

    //ignore dummies
    if uid == DUMMY then
        set amount = 0.00
        call BlzSetEventDamage(amount)
        call BlzSetUnitWeaponBooleanField(source, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false) //so dummies are not hit twice

        call DestroyGroup(ug)

        set t = null
        set u = null
        set ug = null
        set source = null
        set target = null

        return false
    endif

    //zero damage flag
    if CalcAfterReductions(amount, source, target, damageType) <= 0 then
        set zeroDamage = true
    endif

    //undying rage delayed damage
    if Buff.has(target, target, UndyingRageBuff.typeid) then
        call UndyingRageBuff(Buff.get(target, target, UndyingRageBuff.typeid)).addRegen(-amount)
        set amount = 0.00
        call BlzSetEventDamage(amount)
    endif

    //body of fire
    if target == Hero[tpid] and damageType == PHYSICAL and IsUnitEnemy(target, GetOwningPlayer(source)) and GetUnitAbilityLevel(target, BODYOFFIRE.id) > 0 then
        set spell = BODYOFFIRE.get(tpid)

        set dmg = (CalcAfterReductions(amount, target, source, damageType) * 0.05 * GetUnitAbilityLevel(target, BODYOFFIRE.id) + spell.values[0])
        call UnitDamageTarget(target, source, dmg * BOOST[tpid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)

        call spell.destroy()
    endif

    //include summons
    if source == Hero[pid] or IsUnitInGroup(source, SummonGroup) then
        if GetUnitLevel(target) >= 170 and IsUnitEnemy(target, GetOwningPlayer(source)) and HasItemType(Hero[pid], 'I04Q') then //demon heart
            set HeartBlood[pid] = HeartBlood[pid] + 1
            call UpdateItemTooltips(pid)
        endif
        if GetUnitAbilityLevel(Hero[pid], 'B05O') > 0 then //vampiric potion
            call HP(Hero[pid], CalcAfterReductions(amount, source, target, damageType) * 0.03)
            call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\VampiricAuraTarget.mdx", Hero[pid], "chest"))
        endif
    endif

    //dps dummy
    if target == udg_PunchingBag[1] or target == udg_PunchingBag[2] then
        if GetLocalPlayer() == Player(pid - 1) then
            call BlzFrameSetVisible(dummyFrame, true)
        endif
        call TimerList[pid].stopAllTimersWithTag('pbag')
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 10.
        set pt.tag = 'pbag'
        call TimerStart(pt.timer, 1., true, function SUPER_DUMMY_HIDE_TEXT)
        if SUPER_DUMMY_TOTAL <= 0 then
            call TimerStart(NewTimerEx(1), 1., true, function SUPER_DUMMY_DPS_UPDATE)
            if SUPER_DUMMY_TOTAL > 2000000000 then
                call SUPER_DUMMY_RESET()
            endif
        endif

        set SUPER_DUMMY_LAST = CalcAfterReductions(amount, source, target, damageType)

        if damageType == PHYSICAL then
            set SUPER_DUMMY_TOTAL_PHYSICAL = SUPER_DUMMY_TOTAL_PHYSICAL + CalcAfterReductions(amount, source, target, damageType)
        elseif damageType == SPELL then
            set SUPER_DUMMY_TOTAL_MAGIC = SUPER_DUMMY_TOTAL_MAGIC + CalcAfterReductions(amount, source, target, damageType)
        endif
        set SUPER_DUMMY_TOTAL = SUPER_DUMMY_TOTAL + CalcAfterReductions(amount, source, target, damageType)

        call PauseTimer(SUPER_DUMMY_TIMER)
        call TimerStart(SUPER_DUMMY_TIMER, 5., false, function SUPER_DUMMY_RESET)
        call SetWidgetLife(target, BlzGetUnitMaxHP(target))
    endif

    //dev stuff
    static if LIBRARY_dev then
        if BUDDHA_MODE[tpid] and target == Hero[tpid] and CalcAfterReductions(amount, source, target, damageType) > ReduceArmorCalc(GetWidgetLife(target), source, target) then
            set amount = 0.00
            call BlzSetEventDamage(0.00)
        endif
    endif

    set i = GetUnitId(target)

    if not zeroDamage and source != target then
        //damage numbers
        if shield[i] != 0 then
            call ArcingTextTag.create(RealToString(CalcAfterReductions(amount, source, target, damageType)), target, 1, 2, 170, 50, 220, 0)
        elseif damageType == SPELL then
            call ArcingTextTag.create(RealToString(CalcAfterReductions(amount, source, target, damageType)), target, 1, 2, 100, 100, 255, 0)
        elseif damageType == PURE then
            call ArcingTextTag.create(RealToString(CalcAfterReductions(amount, source, target, damageType)), target, 1, 2, 255, 255, 100, 0)
        elseif damageType == PHYSICAL then
            if crit > 0 then
                call ArcingTextTag.create(RealToString(CalcAfterReductions(amount, source, target, damageType)), target, 1, 2.5, 255, 120, 20, 0)
            else
                if CalcAfterReductions(amount, source, target, damageType) >= BlzGetUnitMaxHP(target) * 0.0005 or (target == udg_PunchingBag[1] or target == udg_PunchingBag[2]) then
                    call ArcingTextTag.create(RealToString(CalcAfterReductions(amount, source, target, damageType)), target, 1, 2, 200, 50, 50, 0)
                endif
            endif
        endif
    endif
    
    //shield mitigation
    if shield[i] != 0 then
        if CalcAfterReductions(amount, source, target, damageType) >= ReduceArmorCalc(shield[i].hp, source, target) then
            set amount = amount - ReduceArmorCalc(shield[i].hp, source, target)
            call shield[i].destroy()
        else
            call shield[i].damage(CalcAfterReductions(amount, source, target, damageType), source)
            set amount = 0.00
        endif

        call BlzSetEventDamage(amount)
    endif
    
    //fatal damage
    if CalcAfterReductions(amount, source, target, damageType) > ReduceArmorCalc(GetWidgetLife(target), source, target) then
        if GetUnitAbilityLevel(target, 'B005') > 0 and aoteCD[tpid] then //Gaia Armor
            set aoteCD[tpid] = false
            call BlzSetEventDamage(0.00)
            call HP(target, BlzGetUnitMaxHP(target) * 0.2 * GetUnitAbilityLevel(target, 'A032'))
            call MP(target, BlzGetUnitMaxMana(target) * 0.2 * GetUnitAbilityLevel(target, 'A032'))
            call UnitRemoveAbility(target, 'A033')
            call UnitRemoveAbility(target, 'B005')
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Doom\\DoomDeath.mdl", target, "origin"))
                
            call MakeGroupInRange(tpid, ug, GetUnitX(target), GetUnitY(target), 800., Condition(function FilterEnemy))
                
            set pt = TimerList[tpid].addTimer(tpid)
            set pt.dur = 35.
            set pt.speed = 20.
            set pt.ug = CreateGroup()

            loop
                set u = FirstOfGroup(ug)
                exitwhen u == null
                call GroupRemoveUnit(ug, u)
                call GroupAddUnit(pt.ug, u)
                set Stun.add(target, u).duration = 2.5 * LBOOST[pid]
            endloop

            call TimerStart(NewTimerEx(tpid), 120., false, function GaiaArmorCD)
            call TimerStart(pt.timer, 0.03, true, function GaiaArmorPush)
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

    return false
endfunction
	
function DamageInit takes nothing returns nothing
    local User u = User.first

    call TriggerAddCondition(ACQUIRE_TRIGGER, Filter(function AcquireTarget))

    loop
        exitwhen u == User.NULL
        call TriggerRegisterPlayerUnitEvent(BeforeArmor, u.toPlayer(), EVENT_PLAYER_UNIT_DAMAGING, null)
        //call TriggerRegisterPlayerUnitEvent(AfterArmor, u.toPlayer(), EVENT_PLAYER_UNIT_DAMAGED, function boolexp)
        set u = u.next
    endloop

    call TriggerRegisterPlayerUnitEvent(BeforeArmor, Player(PLAYER_TOWN), EVENT_PLAYER_UNIT_DAMAGING, null)
    call TriggerRegisterPlayerUnitEvent(BeforeArmor, pboss, EVENT_PLAYER_UNIT_DAMAGING, null)
    call TriggerRegisterPlayerUnitEvent(BeforeArmor, Player(PLAYER_NEUTRAL_PASSIVE), EVENT_PLAYER_UNIT_DAMAGING, null)
    call TriggerRegisterPlayerUnitEvent(BeforeArmor, pfoe, EVENT_PLAYER_UNIT_DAMAGING, null)

    //before reductions
    call TriggerAddCondition(BeforeArmor, Filter(function OnDamage))
endfunction
	
endlibrary
