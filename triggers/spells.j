library Spells requires Functions, TimerUtils, Commands, heroselection, Balance

globals
	boolean array isteleporting
	dialog array dChangeSkin
    dialog array dCosmetics
	button array dSkin
    button array dCosmetic
	string array dSkinName
	integer array dPage
	integer TotalSkins
	boolean array ispublic
	constant integer SkinsPerPage = 6
	effect array radiance
	boolean array Windwalk
	group array nervetargets
    group array StasisFieldTargets
    boolean array stasisFieldActive
	location array FlightTarget
	hashtable ScreamTargets = InitHashtable()
	real array initDistance
    integer array bloodfrenzybonus
    trigger frozenorb = CreateTrigger()
    trigger daggerstorm = CreateTrigger()
    trigger phantomslash = CreateTrigger()
    effect array tpto
    group blackholed = CreateGroup()
    group array markedfordeath
    boolean array sniperstance
    timer array lightningtimer
    effect array lightningeffect
    real array whirldur
    location array whirlspot
    real array WhirlDamage
    effect array whirlpoolcloud
    group array whirlpooled
    unit array dummymodel
    effect array dummyeffect
    unit array blizzarddamager
    real array WaveDamage
	integer array WaveBuffed
    group tidalwaved = CreateGroup()
    dialog array heropanel
    button array heropanelbutton
    dialog array votekickpanel
    button array votekickpanelbutton
    boolean array hero_panel_on
    boolean array dmgnumber
    boolean array BP_DESELECT
    unit array shieldunit
    unit array shieldtarget
    integer shieldindexmax = 0
    integer array shieldpercent
    real array shieldhp
    real array shieldmax
    boolean array isShielded
    boolean array aoteCD
    group array aotePush
    integer array aotePushAmount
    group array medeanLightningHit
    group InSmokebomb = CreateGroup()
    real array SmokebombX
    real array SmokebombY
    integer array SmokebombValue
    integer array SmokebombBonus
    boolean array ReincarnationRevival
    integer array ResurrectionRevival
    integer array ReincarnationPRCD
    integer array ResurrectionCD
    group array ProtectionGroup
    group FightMeGroup = CreateGroup()
    boolean array FightMe
    unit array frostblastdummy
    boolean array heliCD
    unit array grenade
    integer array grenadedelay
    real array ControlTimeCD
    real array ArcaneBoltsCD
    real array ArcaneBarrageCD
    real array StasisFieldCD
    real array ArcaneShiftCD
    real array SpaceTimeRippleCD
    group array ArcaneBarrageHit
    group array PhoenixHit
    group array ProvokeTargets
    integer array infernalStrikes
    boolean array infernalStrike
    timer array infernalStrikeTimer
    group array attargets
    location array attargetpoint
    integer array golemDevourStacks
    integer array destroyerDevourStacks
    unit array destroyerTarget
    real array destroyerAttackSpeed
    timer array destroyertimer
    boolean array destroyerSacrificeFlag
    boolean array magneticForceFlag
    effect array darkSeal
    group array darkSealTargets
    boolean array darkSealActive
    boolean array CounterCd
    boolean array overloadActive
    effect array overloadEffect
    boolean array rampageActive
    boolean array bloodMistActive
    effect array bloodMistEffect
    effect array rampageEffect
    trigger tempTrig
    boolean array arcanosphereActive
    unit array arcanosphere
    group array arcanosphereGroup
    integer array saviorBashCount
    group array magnetic_stance_group
    boolean array PhantomSlashing
    real array BloodBank
    hashtable BloodDomain = InitHashtable()
	hashtable Pillars = InitHashtable()
    hashtable EncoreTargets = InitHashtable()
    group SongOfWarTarget = CreateGroup()
    integer array BardSong
    boolean array InspireActive
    real array BardMelodyCost
    real array FlamingBowBonus
    integer array FlamingBowCount
    unit array InstillFear
    real array BorrowedLife
    integer array BladeSpinCount
    integer array IntenseFocus
endglobals

function ShadowShuriken takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target
    local integer mana = 6 //percent mana restored per unit hit
    local integer percentcap = 50

    if pt.dur > 0 then
        call SetUnitXBounded(pt.target, GetUnitX(pt.target) + pt.armor * Cos(pt.angle))
        call SetUnitYBounded(pt.target, GetUnitY(pt.target) + pt.armor * Sin(pt.angle))

        set pt.dur = pt.dur - pt.armor

        call MakeGroupInRange(pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), pt.aoe, Condition(function FilterEnemy))
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if IsUnitInGroup(target, pt.ug) == false then
                call GroupAddUnit(pt.ug, target)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "chest"))
                call UnitDamageTarget(Hero[pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                if GetUnitAbilityLevel(target, 'B019') > 0 and pt.int < 50 then //using int for total mana restored
                    if IsUnitType(target, UNIT_TYPE_HERO) then
                        set mana = mana * 4 //quadruple for bosses
                    endif

                    set pt.int = pt.int + mana

                    if pt.int > percentcap then
                        set mana = ModuloInteger(pt.int, percentcap)
                    endif

                    call GroupRemoveUnit(markedfordeath[pid], target)
                    call SetUnitState(Hero[pid], UNIT_STATE_MANA, GetUnitState(Hero[pid], UNIT_STATE_MANA) + BlzGetUnitMaxMana(Hero[pid]) * mana * 0.01)
                    call SetUnitPathing(target, true)
                    call UnitRemoveAbility(target, 'B019')
                    call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIma\\AImaTarget.mdl", Hero[pid], "origin"))
                endif
            endif
        endloop
    else
        call SetUnitAnimation(pt.target, "death")
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
endfunction

function AzazothBladeStorm takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target
    local group ug = CreateGroup()

    set pt.dur = pt.dur - 0.05 //tick rate

    if pt.dur > 0 then
        //spawn effect
        set target = GetDummy(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0, 0, 0.75)
        call BlzSetUnitSkin(target, 'h00D')
        call SetUnitTimeScale(target, GetRandomReal(0.8, 1.1))
        call SetUnitScale(target, 1.30, 1.30, 1.30)
        call SetUnitAnimationByIndex(target, 0)
        call SetUnitFlyHeight(target, GetRandomReal(50., 100.), 0)
        call BlzSetUnitFacingEx(target, GetRandomReal(0, 359.))

        set target = GetDummy(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0, 0, 0.75)
        call BlzSetUnitSkin(target, 'h00D')
        call SetUnitTimeScale(target, GetRandomReal(0.8, 1.1))
        call SetUnitScale(target, 0.7, 0.7, 0.7)
        call SetUnitAnimationByIndex(target, 0)
        call SetUnitFlyHeight(target, GetRandomReal(50., 100.), 0)
        call BlzSetUnitFacingEx(target, GetRandomReal(0, 359.))

        if pt.dur < 4.85 and ModuloReal(pt.dur, 0.25) < 0.05 then //do damage every 0.25 second
            call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 300., Condition(function FilterEnemy))
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Critters\\Albatross\\CritterBloodAlbatross.mdl", target, "chest"))
                call UnitDamageTarget(Hero[pid], target, (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid], true)) * 0.25 * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endloop
        endif

    else
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set target = null
    set ug = null
endfunction

function BladeSpin takes integer pid, integer multiplier returns nothing
    local group ug = CreateGroup()
    local unit target
    local PlayerTimer pt = TimerList[pid].addTimer(pid)

    call DelayAnimation(pid, Hero[pid], 0.5, 0, 1., true)
    call SetUnitTimeScale(Hero[pid], 1.75)
    call SetUnitAnimationByIndex(Hero[pid], 5)

    set target = GetDummy(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0, 0, DUMMY_RECYCLE_TIME)
    call BlzSetUnitSkin(target, 'h00C')
    call SetUnitTimeScale(target, 0.5)
    call SetUnitScale(target, 1.35, 1.35, 1.35)
    call SetUnitAnimationByIndex(target, 0)
    call SetUnitFlyHeight(target, 75., 0)
    call BlzSetUnitFacingEx(target, GetUnitFacing(Hero[pid]))

    set target = GetDummy(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0, 0, DUMMY_RECYCLE_TIME)
    call BlzSetUnitSkin(target, 'h00C')
    call SetUnitTimeScale(target, 0.5)
    call SetUnitScale(target, 1.35, 1.35, 1.35)
    call SetUnitAnimationByIndex(target, 0)
    call SetUnitFlyHeight(target, 75., 0)
    call BlzSetUnitFacingEx(target, GetUnitFacing(Hero[pid]) + 180)

    call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 250. * LBOOST(pid), Condition(function FilterEnemy))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Critters\\Albatross\\CritterBloodAlbatross.mdl", target, "chest"))
        call UnitDamageTarget(Hero[pid], target, multiplier * GetHeroAgi(Hero[pid], true) * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop

    call DestroyGroup(ug)

    set ug = null
endfunction

function SummoningImprovement takes integer pid, unit summon, real str, real agi, real int returns nothing
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A022') - 1 //summoning improvement
    local integer uid = GetUnitTypeId(summon)
    local integer i
    local real boost = BOOST(pid)

    //stat ratios
    call SetHeroStr(summon, R2I(str * (GetHeroInt(Hero[pid], true) + GetHeroStr(Hero[pid], true)) * boost), true)
    if uid != SUMMON_DESTROYER then
        call SetHeroAgi(summon, R2I(agi * GetHeroInt(Hero[pid], true) * boost), true)
    else
        call BlzSetUnitArmor(summon, agi * GetHeroInt(Hero[pid], true) * boost)
    endif
    call SetHeroInt(summon, R2I(int * GetHeroInt(Hero[pid], true) * boost), true)
    set improvementArmorBonus[pid] = 0

    if ablev > 0 then
        call SetUnitMoveSpeed(summon, GetUnitDefaultMoveSpeed(summon) + ablev * 10)
        
        //armor bonus
        set improvementArmorBonus[pid] = improvementArmorBonus[pid] + R2I((Pow(ablev, 1.2) + (Pow(ablev, 4) - Pow(ablev, 3.9)) / 90) / 2 + ablev + 6)

        //status bar buff
        call UnitAddAbility(summon, 'A06Q')
        call SetUnitAbilityLevel(summon, 'A06Q', ablev)
    endif

    if uid == SUMMON_GOLEM then //golem
        if GetUnitAbilityLevel(Hero[pid], 'A063') > 0 then //golem devour ability
            call UnitAddAbility(summon, 'A06C')
            call SetUnitAbilityLevel(summon, 'A06C', GetUnitAbilityLevel(Hero[pid], 'A063'))
        endif
        if ablev >= 20 then
            call UnitAddAbility(summon, 'A0IQ')
        endif
    elseif uid == SUMMON_DESTROYER then //destroyer
        if GetUnitAbilityLevel(Hero[pid], 'A063') > 0 then //destroyer devour ability
            call UnitAddAbility(summon, 'A04Z')
            call SetUnitAbilityLevel(summon, 'A04Z', GetUnitAbilityLevel(Hero[pid], 'A063'))
        endif
        if ablev >= 20 then
        else
            //set improvementArmorBonus[pid] = improvementArmorBonus[pid] * 0.75
        endif
        if ablev >= 30 then
            call UnitAddAbility(summon, 'A0IQ')
            //set improvementArmorBonus[pid] = improvementArmorBonus[pid] + R2I(improvementArmorBonus[pid] * 0.35)
        endif
    elseif uid == SUMMON_HOUND then //demon hound
        if ablev >= 20 then
            //set improvementArmorBonus[pid] = improvementArmorBonus[pid] * 0.75 
        else
            //set improvementArmorBonus[pid] = improvementArmorBonus[pid] * 0.5
        endif
    endif

    call UnitSetBonus(summon, BONUS_ARMOR, improvementArmorBonus[pid])
endfunction

function InstillFearExpire takes nothing returns nothing
    set InstillFear[ReleaseTimer(GetExpiredTimer())] = null
endfunction

function SaviorBashHeal takes integer pid, integer ablevel returns nothing
    local group ug = CreateGroup()
    local unit target
    local real heal = 25 + (ablevel * 0.1 + 0.4) * GetHeroStr(Hero[pid], true) * BOOST(pid)

    call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 600 * LBOOST(pid), Condition(function FilterAlly))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call DestroyEffect( AddSpecialEffectTarget("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", target, "origin")) //change effect
        call HP(target, heal)
    endloop
    //effect here maybe

    call DestroyGroup(ug)

    set ug = null
endfunction

function ArcaneAura takes integer pid returns integer
    local integer ablev = 0
    local User u = User.first

    loop
        exitwhen u == User.NULL

        if IsUnitInRange(Hero[pid], Hero[u.id], 900.) then //check for range
            set ablev = IMaxBJ(ablev, GetUnitAbilityLevel(Hero[u.id], 'AHad')) //level of arcane aura
        endif

        set u = u.next
    endloop

    return ablev
endfunction

function BlizzardAnimationExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())

    call IssueImmediateOrder(blizzarddamager[pid], "stop")
endfunction

function BlizzardExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())

    set blizzarddamager[pid] = null
endfunction

function BloodLeechAoE takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A07A')
    local real dmg = (2.75 + 0.25 * ablev) * (GetHeroAgi(Hero[pid], true) + GetHeroStr(Hero[pid], true)) * BOOST(pid)

    if GetUnitAbilityLevel(Hero[pid], 'A099') > 0 then
        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 500 * LBOOST(pid), Condition(function FilterEnemy))

        if BlzGroupGetSize(ug) > 0 then
            call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\DarknessLeechTarget_Portrait.mdx", Hero[pid], "origin"))
        endif

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set BloodBank[pid] = RMinBJ(BloodBank[pid] + 3.33 * GetHeroAgi(Hero[pid], true) + 1.67 * GetHeroStr(Hero[pid], true), 200 * GetHeroInt(Hero[pid], true))
            call UnitDamageTarget(Hero[pid], target, 0.33 * dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)

            set bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), 'A0A1', 1, DUMMY_RECYCLE_TIME)
            call BlzSetUnitWeaponBooleanField(bj_lastCreatedUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(Hero[pid]) - GetUnitY(bj_lastCreatedUnit), GetUnitX(Hero[pid]) - GetUnitX(bj_lastCreatedUnit)))
            call IssueTargetOrder(bj_lastCreatedUnit, "attack", Hero[pid])
        endloop
    else
        call UnitDisableAbility(Hero[pid], 'A07A', false)
        call UnitDisableAbility(Hero[pid], 'A09B', false)
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
endfunction

function Inspire takes integer pid returns nothing
    local integer ablev = 0
    local integer index = 0
    local integer count = BlzGroupGetSize(HeroGroup)
    local integer tpid = 0
    local unit target

    loop
        set target = BlzGroupUnitAt(HeroGroup, index)
        set tpid = GetPlayerId(GetOwningPlayer(target)) + 1

        if InspireActive[tpid] and IsUnitInRange(Hero[pid], target, 900.) then //look for a bard with inspire active
            set ablev = GetUnitAbilityLevel(target, 'A09Y')

            if ablev > 0 then
                call UnitAddAbility(Hero[pid], 'A0A0')
                call SetUnitAbilityLevel(Hero[pid], 'A0A0', ablev)
                exitwhen true
            endif
        else
            call UnitRemoveAbility(Hero[pid], 'A0A0')
        endif

        set index = index + 1
        exitwhen index >= count
    endloop

    set target = null
endfunction

function Protector takes integer pid returns nothing
    local integer tpid = 0
    local group ug = CreateGroup()
    local unit target
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A09I')

    call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 800., Condition(function FilterRoyalGuardian))

    if BlzGroupGetSize(ug) == 0 then
        call UnitRemoveAbility(Hero[pid], 'A09I')
    else
        set target = FirstOfGroup(ug)
        set ablev = GetUnitAbilityLevel(target, 'A0HS')

        if ablev > 0 then
            call UnitAddAbility(Hero[pid], 'A09I')
            call SetUnitAbilityLevel(Hero[pid], 'A09I', ablev)
        endif
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

function SpawnDaggers takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer i = 0
    local real x
    local real y
    local real angle

    set pt.dur = pt.dur - 1

    if pt.dur >= 0 then
        loop
            exitwhen i > 1
            set udg_PS_Index_Max = ( udg_PS_Index_Max + 1 )
            set udg_PS_Caster[udg_PS_Index_Max] = Hero[pid]
            set angle = bj_RADTODEG * Atan2(pt.aoe - pt.y, pt.armor - pt.x) + GetRandomReal(-30., 30.)
            set x = pt.armor + GetRandomReal(70., 300.) * Cos(bj_DEGTORAD * angle)
            set y = pt.aoe + GetRandomReal(70., 300.) * Sin(bj_DEGTORAD * angle)
            set udg_PS_HitEffect[udg_PS_Index_Max] = "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl"
            set angle = bj_RADTODEG * Atan2(pt.y - y, pt.x - x) + GetRandomReal(-3., 3.)
            set udg_PS_Angle[udg_PS_Index_Max] = angle
            set udg_PS_Aoe[udg_PS_Index_Max] = -1.00
            set udg_PS_HitTerrain[udg_PS_Index_Max] = false
            set udg_PS_Pierce[udg_PS_Index_Max] = true
            set udg_PS_NoHitEff[udg_PS_Index_Max] = false
            set udg_PS_Damage[udg_PS_Index_Max] = GetHeroAgi(Hero[pid], true) * BOOST(pid)
            set udg_PS_Range[udg_PS_Index_Max] = 1150.00
            set udg_PS_Speed[udg_PS_Index_Max] = 0
            set udg_PS_HitRange[udg_PS_Index_Max] = 0
            set udg_PS_BuffEffect[udg_PS_Index_Max] = true
            set udg_PS_BuffEffectTrigger[udg_PS_Index_Max] = daggerstorm
            set udg_PS_DamagedUnits[udg_PS_Index_Max] = CreateGroup()
            set udg_PS_Dummy[udg_PS_Index_Max] = GetDummy(x, y, 0, 0, 0) 
            call BlzSetUnitFacingEx(udg_PS_Dummy[udg_PS_Index_Max], angle)
            call SetUnitFlyHeight(udg_PS_Dummy[udg_PS_Index_Max], 25.00, 0.00 )
            set udg_PS_Dummy_Effect[udg_PS_Index_Max] = AddSpecialEffectTarget("Abilities\\Weapons\\WardenMissile\\WardenMissile.mdl", udg_PS_Dummy[udg_PS_Index_Max], "overhead" )

            set i = i + 1
        endloop
    else
        loop
            set udg_PS_Speed[pt.agi + i] = 55.00
            set udg_PS_HitRange[pt.agi + i] = 45.00
            set i = i + 1
            exitwhen i > 60
        endloop
        call TimerList[pid].removePlayerTimer(pt)
    endif
endfunction

function SongOfWar takes integer pid, boolean clear returns nothing
    local group ug = CreateGroup()
    local unit target
    local integer count = BlzGroupGetSize(SongOfWarTarget)
    local integer index = 0
    local integer bonus

    if clear then
        loop
            set target = BlzGroupUnitAt(SongOfWarTarget, index)
            if LoadInteger(MiscHash, 's', GetHandleId(target)) > 0 and LoadInteger(MiscHash, 'p', GetHandleId(target)) == pid then
                call GroupRemoveUnit(SongOfWarTarget, target)
                call UnitAddBonus(target, BONUS_DAMAGE, - (LoadInteger(MiscHash, 's', GetHandleId(target))))
                call RemoveSavedInteger(MiscHash, 's', GetHandleId(target))
                call RemoveSavedInteger(MiscHash, 'p', GetHandleId(target))
                call UnitRemoveAbility(target, 'B017')
                set index = index - 1
            endif
            set index = index + 1
            exitwhen index >= count
        endloop
    else
        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 900.00, Condition(function FilterAllyHero))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set bonus = R2I((GetHeroStat(MainStat(target), target, true) + UnitGetBonus(target, BONUS_DAMAGE)) * 0.2)
            if LoadInteger(MiscHash, 's', GetHandleId(target)) == 0 and LoadInteger(MiscHash, 'p', GetHandleId(target)) == 0 then
                call GroupAddUnit(SongOfWarTarget, target)
                call SaveInteger(MiscHash, 's', GetHandleId(target), bonus) 
                call SaveInteger(MiscHash, 'p', GetHandleId(target), pid)
                call UnitAddBonus(target, BONUS_DAMAGE, bonus)
            endif
        endloop
        
        set count = BlzGroupGetSize(SongOfWarTarget)

        loop
            set target = BlzGroupUnitAt(SongOfWarTarget, index)
            if LoadInteger(MiscHash, 's', GetHandleId(target)) > 0 and LoadInteger(MiscHash, 'p', GetHandleId(target)) == pid then
                if IsUnitInRange(target, Hero[pid], 900.) == false or GetWidgetLife(Hero[pid]) < 0.406 or GetWidgetLife(target) < 0.406 then
                    call GroupRemoveUnit(SongOfWarTarget, target)
                    call UnitAddBonus(target, BONUS_DAMAGE, - (LoadInteger(MiscHash, 's', GetHandleId(target))))
                    call RemoveSavedInteger(MiscHash, 's', GetHandleId(target))
                    call RemoveSavedInteger(MiscHash, 'p', GetHandleId(target))
                    call UnitRemoveAbility(target, 'B017')
                    set index = index - 1
                else //update bonus
                    call UnitAddBonus(target, BONUS_DAMAGE, - (LoadInteger(MiscHash, 's', GetHandleId(target))))
                    set bonus = R2I((GetHeroStat(MainStat(target), target, true) + UnitGetBonus(target, BONUS_DAMAGE)) * 0.2)
                    call SaveInteger(MiscHash, 's', GetHandleId(target), bonus) 
                    call UnitAddBonus(target, BONUS_DAMAGE, bonus)
                endif
            endif
            set index = index + 1
            exitwhen index >= count
        endloop
    endif

    call DestroyGroup(ug)

    set target = null
    set ug = null
endfunction

function SongOfPeaceExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())

    call UnitRemoveAbility(Hero[pid], 'A01B')
endfunction

function SongOfPeaceEx takes integer pid returns nothing
    local unit target
    local integer index = 0
    local integer count = BlzGroupGetSize(HeroGroup)
    local real boost = LBOOST(pid)

    loop
        set target = BlzGroupUnitAt(HeroGroup, index)

        if IsUnitInRange(target, Hero[pid], 900.) then
            call UnitAddAbility(target, 'A01B')
                
            call TimerStart(NewTimerEx(GetPlayerId(GetOwningPlayer(target)) + 1), 5. * boost, false, function SongOfPeaceExpire)
        endif

        set index = index + 1
        exitwhen index >= count
    endloop
        
    set target = null
endfunction

function WarEncorePeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer dur = LoadInteger(EncoreTargets, GetHandleId(pt.target), 2) 

    set dur = dur - 1
    
    if dur > 0 then 
        call SaveInteger(EncoreTargets, GetHandleId(pt.target), 2, dur)
    else
        call DestroyEffect(LoadEffectHandle(EncoreTargets, GetHandleId(pt.target), 3))
        call RemoveSavedInteger(EncoreTargets, GetHandleId(pt.target), 0)
        call RemoveSavedInteger(EncoreTargets, GetHandleId(pt.target), 1)
        call RemoveSavedInteger(EncoreTargets, GetHandleId(pt.target), 2)
        call RemoveSavedHandle(EncoreTargets, GetHandleId(pt.target), 3)
        call TimerList[pid].removePlayerTimer(pt)
    endif
endfunction

function IcePrisonPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer i = 0
    local integer i2 = 0
    local unit target
    local real angle
    local real dist = pt.aoe
    local group ug = CreateGroup()
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A098')

    if pt.aoe > 160 then
        call MakeGroupInRange(pid, ug, pt.x, pt.y, pt.aoe, Condition(function FilterEnemy))
        set dist = dist - 15
        set pt.aoe = dist

        loop //move dummy effects
            exitwhen i2 > 7
            set angle = bj_PI * 2 * i2 / 8.
            call SetUnitPosition(LoadUnitHandle(Pillars, pid, i2), pt.x + dist * Cos(angle), pt.y + dist * Sin(angle) )
            set i2 = i2 + 1
        endloop
        
        set dist = dist * .9
        loop //move outlier units inward
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if GetUnitMoveSpeed(target) > 0 and IsUnitInRangeXY(target, pt.x, pt.y, 120.) == false then
                set angle = Atan2((pt.y - GetUnitY(target)), (pt.x - GetUnitX(target)))
                call SetUnitPathing(target, false)
                call SetUnitXBounded(target, GetUnitX(target) + 50 * Cos(angle))
                call SetUnitYBounded(target, GetUnitY(target) + 50 * Sin(angle))
            endif
        endloop
    else
        loop
            exitwhen i2 > 7
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetUnitX(LoadUnitHandle(Pillars, pid, i2)), GetUnitY(LoadUnitHandle(Pillars, pid, i2)) ))
            call BlzSetUnitSkin(LoadUnitHandle(Pillars, pid, i2), DUMMY)
            call RemoveSavedHandle(Pillars, pid, i2)
            set i2 = i2 + 1
        endloop
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", pt.x, pt.y))
        call MakeGroupInRange(pid, ug, pt.x, pt.y, 300 * LBOOST(pid), Condition(function FilterEnemy))
        loop 
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call SetUnitPathing(target, true)
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetUnitX(target), GetUnitY(target)))
            if GetUnitAbilityLevel(target,'B01G')>0 then
                call DummyCastTarget(Player(pid - 1), target, 'A0DS', R2I(3 * BOOST(pid)), GetUnitX(target), GetUnitY(target), "thunderbolt")
                call UnitDamageTarget(Hero[pid], target, pt.dmg * 1.5, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            else
                call DummyCastTarget(Player(pid - 1), target, 'A0DS', R2I(2 * BOOST(pid)), GetUnitX(target), GetUnitY(target), "thunderbolt")
                call UnitDamageTarget(Hero[pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
        endloop

        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set target = null
    set ug = null
endfunction

function BloodDomainTick takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target
    local group ug = CreateGroup()
    local integer size
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A09B')

    set pt.dur = pt.dur - 1

    if pt.dur > 0 then
        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), pt.aoe, Condition(function FilterEnemyDead))

        set tg = CreateGroup()
        call MakeGroupInRange(pid, tg, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), pt.aoe, Condition(function FilterEnemy))
        set size = BlzGroupGetSize(tg) - 1
        set pt.dmg = ((0.5 + 0.5 * ablev) * GetHeroAgi(Hero[pid], true)) + ((1.5 + 0.5 * ablev) * GetHeroStr(Hero[pid], true))
        set pt.dmg = RMaxBJ(pt.dmg * 0.2, pt.dmg * (1 - (0.17 - 0.02 * ablev) * size))
        set pt.armor = 1 * (GetHeroAgi(Hero[pid], true) + GetHeroStr(Hero[pid], true))
        set pt.armor = RMaxBJ(pt.armor * 0.2, pt.armor * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(ug) - 1)))
        call DestroyGroup(tg)

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set BloodBank[pid] = RMinBJ(BloodBank[pid] + pt.armor, 200 * GetHeroInt(Hero[pid], true))

            if GetWidgetLife(target) >= 0.406 then
                call UnitDamageTarget(Hero[pid], target, pt.dmg * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif

            set bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), 'A09D', 1, DUMMY_RECYCLE_TIME)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(Hero[pid]) - GetUnitY(bj_lastCreatedUnit),  GetUnitX(Hero[pid]) - GetUnitX(bj_lastCreatedUnit)))
            call BlzSetUnitWeaponBooleanField(bj_lastCreatedUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
            call IssueTargetOrder(bj_lastCreatedUnit, "attack", Hero[pid])
        endloop
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
endfunction

function BloodLordExpire takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    call BlzSetUnitAttackCooldown(Hero[pid], BlzGetUnitAttackCooldown(Hero[pid], 0) / 0.7, 0)
    call UnitRemoveAbility(Hero[pid], 'A099')
    call UnitAddBonus(Hero[pid], BONUS_HERO_AGI, -(pt.agi))
    call UnitAddBonus(Hero[pid], BONUS_HERO_STR, -(pt.str))
    
    call TimerList[pid].removePlayerTimer(pt)
endfunction

function SearingArrowBurn takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    set pt.dur = pt.dur - 1

    if pt.dur >= 0 then
        call UnitDamageTarget(Hero[pid], pt.target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif
endfunction

function SearingArrowIgnite takes unit target, integer pid returns nothing
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A090')
    local PlayerTimer pt = TimerList[pid].addTimer(pid)

    call DestroyEffectTimed(AddSpecialEffectTarget("war3mapImported\\FireNormal1.mdl", target, "chest"), 5)

    set pt.dmg = (0.05 + ablev * 0.05) * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroAgi(Hero[pid], true)) * BOOST(pid)
    set pt.dur = 5
    set pt.target = target

    call TimerStart(pt.getTimer(), 1., true, function SearingArrowBurn)
endfunction

function SearingArrow takes integer pid, real x, real y returns nothing
    local group ug = CreateGroup()
    local unit target

    call MakeGroupInRange(pid, ug, x, y, 750., Condition(function FilterEnemy))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)

        set bj_lastCreatedUnit = CreateUnit(Player(pid - 1), 'h02U', x, y, bj_RADTODEG * Atan2(y - GetUnitY(target), x - GetUnitX(target)))

        call IssueTargetOrder(bj_lastCreatedUnit, "attack", target)
        call RemoveUnitTimed(bj_lastCreatedUnit, 2.5)
    endloop

    call DestroyGroup(ug)

    set ug = null
endfunction

function ArcaneComet takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local real x = LoadReal(MiscHash, 0, GetHandleId(t))
    local real y = LoadReal(MiscHash, 1, GetHandleId(t))
    local unit target
    local group ug = CreateGroup()
    local real dmg = GetHeroInt(Hero[pid], true) * 2 * BOOST(pid)

    call MakeGroupInRange(pid, ug, x, y, 150. * LBOOST(pid), Condition(function FilterEnemy))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop

    call RemoveSavedReal(MiscHash, 0, GetHandleId(t))
    call RemoveSavedReal(MiscHash, 1, GetHandleId(t))
    call ReleaseTimer(t)
    call DestroyGroup(ug)
    
    set t = null
    set ug = null
endfunction

function ArcaneComets takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local integer times = LoadInteger(MiscHash, 0, GetHandleId(t))
    local real x = LoadReal(MiscHash, 1, GetHandleId(t))
    local real y = LoadReal(MiscHash, 2, GetHandleId(t))
    local timer t2

    call SaveInteger(MiscHash, 0, GetHandleId(t), times - 1)

    if times > 0 then
        set t2 = NewTimerEx(pid)
        call SaveReal(MiscHash, 0, GetHandleId(t2), x)
        call SaveReal(MiscHash, 1, GetHandleId(t2), y)

        call DestroyEffect(AddSpecialEffect("war3mapImported\\Voidfall Medium.mdx", x, y))
        call TimerStart(t2, 0.8, false, function ArcaneComet)
    else
        call RemoveSavedInteger(MiscHash, 0, GetHandleId(t))
        call RemoveSavedReal(MiscHash, 1, GetHandleId(t))
        call RemoveSavedReal(MiscHash, 2, GetHandleId(t))
        call ReleaseTimer(t)
    endif

    set t = null
    set t2 = null
endfunction

function ArcanosphereBuffs takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local unit target
    local group ug = CreateGroup()

    if arcanosphereActive[pid] then
        call MakeGroupInRange(pid, ug, GetUnitX(arcanosphere[pid]), GetUnitY(arcanosphere[pid]), 800., Condition(function FilterEnemy))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if GetUnitAbilityLevel(target, 'A08V') == 0 then
                call UnitAddAbility(target, 'A08V')
                call UnitAddAbility(target, 'B02N')
                call GroupAddUnit(arcanosphereGroup[pid], target)
            endif
        endloop
    else
        loop
            set target = FirstOfGroup(arcanosphereGroup[pid])
            exitwhen target == null
            call GroupRemoveUnit(arcanosphereGroup[pid], target)
            call UnitRemoveAbility(target, 'A08V')
            call UnitRemoveAbility(target, 'B02N')
        endloop

        call ReleaseTimer(t)
    endif

    call DestroyGroup(ug)

    set t = null
    set ug = null
endfunction

function Arcanosphere takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())

    call SetUnitAnimation(arcanosphere[pid], "death")
    call RemoveUnitTimed(arcanosphere[pid], 5.)
    
    //return arcanist spells
    if GetUnitTypeId(Hero[pid]) == HERO_ARCANIST then
        call BlzUnitHideAbility(Hero[pid], 'A05Q', false)
        call BlzUnitHideAbility(Hero[pid], 'A02N', false)

        call UnitRemoveAbility(Hero[pid], 'A08S')
        call UnitRemoveAbility(Hero[pid], 'A08X')
    endif

    set arcanosphereActive[pid] = false
    set arcanosphere[pid] = null
endfunction

function StasisFieldActive takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local unit target

    set stasisFieldActive[pid] = false

    loop
        set target = FirstOfGroup(StasisFieldTargets[pid])
        exitwhen target == null
        call GroupRemoveUnit(StasisFieldTargets[pid], target)
        call SetUnitPropWindow(target, 60.)
        call SetUnitPathing(target, true)
    endloop
endfunction

function StasisField takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target

    if stasisFieldActive[pid] then
        call MakeGroupInRange(pid, ug, pt.x, pt.y, pt.aoe, Condition(function FilterEnemy))
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if(IsUnitInGroup(target, StasisFieldTargets[pid]) == false) then
                call GroupAddUnit(StasisFieldTargets[pid], target)
                call SetUnitPropWindow(target, 0)
            endif
        endloop
    else
        loop
            set target = FirstOfGroup(StasisFieldTargets[pid])
            exitwhen target == null
            call GroupRemoveUnit(StasisFieldTargets[pid], target)
            call SetUnitPropWindow(target, 60.)
            call SetUnitPathing(target, true)
        endloop
        
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
endfunction

function PiercingStrikeExpire takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    set pt.dur = pt.dur - 1.

    if pt.dur <= 0 then
        call DestroyEffect(LoadEffectHandle(MiscHash, GetUnitId(pt.target), pid))
        call RemoveSavedHandle(MiscHash, GetUnitId(pt.target), pid)
        call TimerList[pid].removePlayerTimer(pt)
    endif
endfunction

function GatekeepersPact takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local unit target
    local group ug = CreateGroup()
    local effect fx = AddSpecialEffect("war3mapImported\\AnnihilationBlast.mdx", GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))
    local real boost = BOOST(pid)

    call BlzSetSpecialEffectColor(fx, 25, 255, 0)
    call DestroyEffect(fx)

    call SetUnitAnimationByIndex(Hero[pid], 2)
    call BlzPauseUnitEx(Hero[pid], false)
    call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 500. * BOOST(pid), Condition(function FilterEnemy))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call StunUnit(pid, target, 5.)
        call UnitDamageTarget(Hero[pid], target, GetHeroStr(Hero[pid], true) * 15. * boost, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop

    call DestroyGroup(ug)

    set ug = null
    set fx = null
endfunction

function WindwalkEnd takes nothing returns nothing
    call AddUnitAnimationProperties(Hero[ReleaseTimer(GetExpiredTimer())], "alternate", false)
endfunction

function WindwalkStart takes nothing returns nothing
    set Windwalk[ReleaseTimer(GetExpiredTimer())] = true
endfunction

function BloodCleave takes integer pid returns nothing
    local group ug = CreateGroup()
    local unit target
    local real dmg

    //call SetUnitAnimation(Hero[pid], "spin")
    call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 220. * BOOST(pid), Condition(function FilterEnemy))
    call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Reapers Claws Red.mdx", Hero[pid], "chest"))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if rampageActive[pid] then //rampage bonus
            set dmg = (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid], true) * 2) * (GetUnitAbilityLevel(Hero[pid], 'A05X') * 0.1) * (1 + 0.2 * GetUnitAbilityLevel(Hero[pid], 'A0GZ')) * BOOST(pid)
        else
            set dmg = (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid], true) * 2) * (GetUnitAbilityLevel(Hero[pid], 'A05X') * 0.1) * BOOST(pid)
        endif
        call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", target, "chest"))
        call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop

    //call TimerStart(NewTimerEx(pid), 1.3, false, function Stand)

    call DestroyGroup(ug)

    set ug = null
endfunction

function FreezingBlast takes integer pid, real x, real y, real AOE, real dmg returns nothing
    local group ug = CreateGroup()
    local unit target

    call MakeGroupInRange(pid, ug, x, y, AOE, Condition(function FilterEnemy))

    if darkSealActive[pid] then //Augment
        call BlzGroupAddGroupFast(darkSealTargets[pid], ug)
            
        set bj_lastCreatedEffect = AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", BlzGetLocalSpecialEffectX(darkSeal[pid]), BlzGetLocalSpecialEffectY(darkSeal[pid]))
        call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 5)
        call DestroyEffectTimed(bj_lastCreatedEffect, 3)
    endif
        
    call DestroyEffect(AddSpecialEffect("war3mapImported\\AquaSpikeVersion2.mdx", x, y))
        
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call DummyCastTarget(Player(pid - 1), target, 'A07H', 1, GetUnitX(target), GetUnitY(target), "thunderbolt")
        if IsUnitInGroup(target, darkSealTargets[pid]) and IsUnitInRangeXY(target, x, y, AOE) == true then
            call UnitDamageTarget(Hero[pid], target, dmg * 2, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        else
            call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif
    endloop

    call DestroyGroup(ug)

    set ug = null
endfunction

function RoyalPlateExpire takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer armor = R2I(pt.armor)

    call UnitAddBonus(Hero[pid], BONUS_ARMOR, -armor)

    call TimerList[pid].removePlayerTimer(pt)
endfunction

function OverloadLoop takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)

    if overloadActive[pid] then
        if GetUnitState(Hero[pid], UNIT_STATE_MANA) > BlzGetUnitMaxMana(Hero[pid]) * 0.02 then
            call SetUnitState(Hero[pid], UNIT_STATE_MANA, GetUnitState(Hero[pid], UNIT_STATE_MANA) - BlzGetUnitMaxMana(Hero[pid]) * 0.02)
        endif
    else
        call ReleaseTimer(t)
    endif

    set t = null
endfunction

function RampageLoop takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)

    if rampageActive[pid] then
        if GetWidgetLife(Hero[pid]) > BlzGetUnitMaxHP(Hero[pid]) * 0.2 then
            call SetWidgetLife(Hero[pid], GetWidgetLife(Hero[pid]) - 0.03 * GetWidgetLife(Hero[pid]))
        endif
    else
        call ReleaseTimer(t)
    endif

    set t = null
endfunction

function CounterStrikeCD takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
		
    set CounterCd[pid] = false
endfunction

function CounterStrike takes unit u returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local group ug = CreateGroup()
    local unit target
    local real dmg = CounterStrikeFormula(pid) * BOOST(pid)
    
    call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 250. * BOOST(pid), Condition(function FilterEnemy))
    call SetUnitAnimation(Hero[pid], "spell")
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "origin"))
        call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop
    
    call DestroyGroup(ug)
    
    set ug = null
endfunction

function DarkSealExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())

    call FadeSFX(darkSeal[pid], true, false)
    call FadeSFX(darkSeal[pid * 8], true, false)
    set darkSealActive[pid] = false
endfunction

function DarkSeal takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local unit target
    local real radius = 450 * LBOOST(pid)
    local integer index = 0
    local integer count = 0

    if darkSealActive[pid] == false then
        loop
            set target = FirstOfGroup(darkSealTargets[pid])
            exitwhen target == null
            call GroupRemoveUnit(darkSealTargets[pid], target)
            call UnitRemoveAbility(target, 'A06W')
        endloop
        
        call ReleaseTimer(t)
    else
        call GroupEnumUnitsInRangeEx(pid, darkSealTargets[pid], BlzGetLocalSpecialEffectX(darkSeal[pid]), BlzGetLocalSpecialEffectY(darkSeal[pid]), radius, Condition(function FilterEnemy))
        set count = BlzGroupGetSize(darkSealTargets[pid])
        
        loop
            set target = BlzGroupUnitAt(darkSealTargets[pid], index)
            if IsUnitInRangeXY(target, BlzGetLocalSpecialEffectX(darkSeal[pid]), BlzGetLocalSpecialEffectY(darkSeal[pid]), radius) then
                if not Buff.has(null, target, 'B06W') then
                    set DarkSealSlow.add(Hero[pid], target).duration = 1.
                endif
            else
                call UnitRemoveAbility(target, 'A06W')
                call GroupRemoveUnit(darkSealTargets[pid], target)
                set index = index - 1
            endif
            set index = index + 1
            exitwhen index >= count
        endloop
    endif
    

    set t = null
    set target = null
endfunction

function FrozenOrbIcicle takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local unit orb = LoadUnitHandle(MiscHash, 0, GetHandleId(t))
    local group ug = CreateGroup()
    local unit target

    if GetWidgetLife(orb) >= 0.406 then
        call MakeGroupInRange(pid, ug, GetUnitX(orb), GetUnitY(orb), 750. * LBOOST(pid), Condition(function FilterEnemy))
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set bj_lastCreatedUnit = GetDummy(GetUnitX(orb), GetUnitY(orb), 'A09F', 1, DUMMY_RECYCLE_TIME)
            call BlzSetUnitWeaponBooleanField(bj_lastCreatedUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(orb), GetUnitX(target) - GetUnitX(orb)))
            call SetUnitScale(bj_lastCreatedUnit, 0.5, 0.5, 0.5)
            call SaveInteger(MiscHash, GetHandleId(bj_lastCreatedUnit), 'forb', pid)
            call IssueTargetOrder(bj_lastCreatedUnit, "attack", target)
        endloop
    else
        call RemoveSavedHandle(MiscHash, 0, GetHandleId(t))
        call ReleaseTimer(t)
    endif
    
    call DestroyGroup(ug)

    set orb = null
    set t = null
    set ug = null
    set target = null
endfunction

function FrozenOrb takes nothing returns nothing
    call DummyCastTarget(GetOwningPlayer(udg_PS_Caster[udg_PS_Index]), udg_PS_BuffEffectUnit, 'A04Q', 9, GetUnitX(udg_PS_BuffEffectUnit), GetUnitY(udg_PS_BuffEffectUnit), "ensnare")

    if udg_PS_NoHitEff[udg_PS_Index] == false then
        set udg_PS_NoHitEff[udg_PS_Index] = true
        call DestroyEffectTimed(AddSpecialEffect("war3mapImported\\FreezingRing.mdx", GetUnitX(udg_PS_Dummy[udg_PS_Index]), GetUnitY(udg_PS_Dummy[udg_PS_Index])), 1.)
    endif
endfunction

function MagneticForceCD takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    set magneticForceFlag[pid] = false
endfunction

function MagneticForcePull takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local group ug
    local unit target
    local real angle
    
    if magneticForceFlag[pid] then
        set ug = CreateGroup()
        
        call MakeGroupInRange(pid, ug, GetUnitX(meatgolem[pid]), GetUnitY(meatgolem[pid]), 600. * BOOST(pid), Condition(function FilterEnemy))
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set angle = Atan2(GetUnitY(meatgolem[pid]) - GetUnitY(target), GetUnitX(meatgolem[pid]) - GetUnitX(target))
            if GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(GetUnitX(target) + (7. * Cos(angle)), GetUnitY(target) + (7. * Sin(angle))) then
                call SetUnitXBounded(target, GetUnitX(target) + (7. * Cos(angle)))
                call SetUnitYBounded(target, GetUnitY(target) + (7. * Sin(angle)))
            endif
        endloop
    else
        call ReleaseTimer(t)
    endif
    
    call DestroyGroup(ug)
        
    set ug = null
    set t = null
endfunction

function DemonHoundAOE takes unit source, unit target returns nothing
    local group ug = CreateGroup()
    local integer pid = GetPlayerId(GetOwningPlayer(source)) + 1
    local real boost = BOOST(pid)
    
    call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 400. * LBOOST(pid), Condition(function FilterEnemy))
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call UnitDamageTarget(source, target, GetHeroInt(source, true) * 1.25 * boost, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop
    
    call DestroyGroup(ug)
    
    set ug = null
endfunction

function DestroyerAttackSpeed takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer i = 1

    loop
        exitwhen t == destroyertimer[i]
        set i = i + 1
    endloop

    if destroyerDevourStacks[i] >= 3 then
        set destroyerAttackSpeed[i] = destroyerAttackSpeed[i] + 100
        call UnitAddBonus(destroyer[i], BONUS_ATTACK_SPEED, 100)
    else
        set destroyerAttackSpeed[i] = destroyerAttackSpeed[i] + 50
        call UnitAddBonus(destroyer[i], BONUS_ATTACK_SPEED, 50)
    endif
    
    set t = null
endfunction

function MagneticStanceAggro takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)

    if GetUnitAbilityLevel(Hero[pid], 'A05T') > 0 then
        call Taunt(Hero[pid], pid, false, 50, 50)
    else
        call ReleaseTimer(t)
    endif

    set t = null
endfunction

function MagneticStancePull takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local unit target
    local real angle
    
    if GetUnitAbilityLevel(Hero[pid], 'A05T') > 0 then
        call MakeGroupInRange(pid, magnetic_stance_group[pid], GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 500. * LBOOST(pid), Condition(function FilterEnemy))
        
        loop
            set target = FirstOfGroup(magnetic_stance_group[pid])
            exitwhen target == null
            call GroupRemoveUnit(magnetic_stance_group[pid], target)
            set angle = Atan2(GetUnitY(Hero[pid]) - GetUnitY(target), GetUnitX(Hero[pid]) - GetUnitX(target))
            call UnitWakeUp(target)
            if GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(GetUnitX(target) + (3. * Cos(angle)), GetUnitY(target) + (3. * Sin(angle))) and UnitDistance(Hero[pid], target) > 100. then
                call SetUnitXBounded(target, GetUnitX(target) + (3. * Cos(angle)))
                call SetUnitYBounded(target, GetUnitY(target) + (3. * Sin(angle)))
            endif
        endloop
    else
        call ReleaseTimer(t)
    endif
    
    set t = null
endfunction

function ATExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local unit target
    local real damage = GetHeroInt(Hero[pid], true) * (5 + GetUnitAbilityLevel(Hero[pid],'A078') * 3) * BOOST(pid)
    
    if BlzGroupGetSize(attargets[pid]) > 0 then
        loop
            set target = FirstOfGroup(attargets[pid])
            exitwhen target == null
            call GroupRemoveUnit(attargets[pid], target)
            call PauseUnit(target, false)
            call SetUnitFlyHeight( target, 0.00, 0.00 )
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))
            call UnitDamageTarget(Hero[pid], target, damage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
        
        call SetPlayerAbilityAvailable(Player(pid - 1), 'A078', true)
        call UnitRemoveAbility(Hero[pid], 'A00A')
        call ReleaseTimer(t)
        
        call RemoveLocation(attargetpoint[pid])
    endif
    
    set t = null
    set target = null
endfunction

function InfernalStrikesExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer i = 1
    
    loop
        exitwhen i > 8
        if t == infernalStrikeTimer[i] then
            set infernalStrikes[i] = 0
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    set t = null
endfunction

function InfernalStrikes takes integer pid, unit target returns nothing
    local group ug = CreateGroup()
    local integer num
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A05S')
    local integer dtype = BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE)
    
    call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 250. * BOOST(pid), Condition(function FilterEnemy))
    set num = BlzGroupGetSize(ug)
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        set ignoreflag = true
        if dtype == 6 or dtype == 7 then
            call UnitDamageTarget(Hero[pid], target, ((GetHeroStr(Hero[pid], true) * ablev) + GetWidgetLife(target) * (0.25 + 0.05 * ablev)) * 33.33 * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
        else
            call UnitDamageTarget(Hero[pid], target, ((GetHeroStr(Hero[pid], true) * ablev) + GetWidgetLife(target) * (0.25 + 0.05 * ablev)) * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
        endif
    endloop
    
    call HP(Hero[pid], BlzGetUnitMaxHP(Hero[pid]) * 0.01 * num)
    
    call DestroyGroup(ug)
    
    set ug = null
endfunction

function HandGrenade takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target

    call MakeGroupInRange(pid, ug, GetLocationX(FlightTarget[pid]), GetLocationY(FlightTarget[pid]), 300 * BOOST(pid), Condition(function FilterEnemy))
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call DummyCastTarget(Player(pid - 1), target, 'A0DS', 6, GetUnitX(target), GetUnitY(target), "thunderbolt")
        call UnitDamageTarget(Hero[pid], target, GetHeroAgi(Hero[pid], true) * GetUnitAbilityLevel(Hero[pid], 'A0J4') * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop
    
    call DestroyEffect(AddSpecialEffectLoc("Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", FlightTarget[pid]))
    call RemoveLocation(FlightTarget[pid])
    call RemoveUnitTimed(grenade[pid], 2.)
    set grenade[pid] = null
    
    call DestroyGroup(ug)
    
    set ug = null
endfunction

function SpiritCallPeriodic takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer time = GetTimerData(t)
    local group ug = CreateGroup()
    local group ug2 = CreateGroup()
    local unit target
    local unit u
    local SpiritCallSlow scs
    
    call SetTimerData(t, time - 1)
    
    call GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon_Boss, Condition(function isspirit))
    
    if time > 0 then
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if GetRandomInt(0, 99) < 25 then
                call GroupEnumUnitsInRect(ug2, gg_rct_Naga_Dungeon_Boss, Condition(function isplayerunit))
                set u = BlzGroupUnitAt(ug2, GetRandomInt(0, BlzGroupGetSize(ug2) - 1))
                call IssuePointOrder(target, "move", GetUnitX(u), GetUnitY(u))
            endif
            call GroupEnumUnitsInRange(ug2, GetUnitX(target), GetUnitY(target), 300., Condition(function isplayerunit))
            loop
                set u = FirstOfGroup(ug2)
                exitwhen u == null
                call GroupRemoveUnit(ug2, u)
                set bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), 'A09R', 1, DUMMY_RECYCLE_TIME)
                call BlzSetUnitWeaponBooleanField(bj_lastCreatedUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
                call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(u) - GetUnitY(target), GetUnitX(u) - GetUnitX(target)))
                call IssueTargetOrder(bj_lastCreatedUnit, "attack", u)
                call UnitDamageTarget(target, u, BlzGetUnitMaxHP(u) * 0.1, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                if GetWidgetLife(u) >= 0.406 then
                    set scs = SpiritCallSlow.add(u, u)
                    set scs.duration = 5.
                endif
            endloop
        endloop
    else
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call SetUnitVertexColor(target, 100, 255, 100, 255)
            call SetUnitScale(target, 1, 1, 1)
            call IssuePointOrder(target, "move", GetRandomReal(GetRectMinX(gg_rct_Naga_Dungeon_Boss_Vision), GetRectMaxX(gg_rct_Naga_Dungeon_Boss_Vision)), GetRandomReal(GetRectMinY(gg_rct_Naga_Dungeon_Boss_Vision), GetRectMaxY(gg_rct_Naga_Dungeon_Boss_Vision)))
        endloop
    
        call ReleaseTimer(t)
    endif
    
    call DestroyGroup(ug)
    call DestroyGroup(ug2)
    
    set t = null
    set ug = null
    set ug2 = null
endfunction

function SpiritCall takes nothing returns nothing
    local timer t = NewTimerEx(15)
    local group ug = CreateGroup()
    local unit target
    
    call GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon_Boss, Condition(function isspirit))
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call SetUnitVertexColor(target, 255, 25, 25, 255)
        call SetUnitScale(target, 1.25, 1.25, 1.25)
    endloop
    
    call TimerStart(t, 1., true, function SpiritCallPeriodic)
    
    call DestroyGroup(ug)
    
    set t = null
    set ug = null
endfunction

function CollapseExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local real x = LoadReal(MiscHash, 0, GetHandleId(t))
    local real y = LoadReal(MiscHash, 1, GetHandleId(t))
    local group ug = CreateGroup()
    local unit target
    
    call GroupEnumUnitsInRange(ug, x, y, 500., Condition(function isplayerunit))
    call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", x + 150, y + 150))
    call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", x - 150, y - 150))
    call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", x + 150, y - 150))
    call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", x - 150, y + 150))
        
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call UnitDamageTarget(nagaboss, target, BlzGetUnitMaxHP(target) * GetRandomReal(0.75, 1), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop
        
    call RemoveSavedReal(MiscHash, 0, GetHandleId(t))
    call RemoveSavedReal(MiscHash, 1, GetHandleId(t))
    call ReleaseTimer(t)
        
    call DestroyGroup(ug)
        
    set t = null
    set ug = null
endfunction

function NagaCollapse takes nothing returns nothing
    local timer t
    local integer i = 0
    local unit dummy

    loop
        exitwhen i > 9
        set dummy = GetDummy(GetRandomReal(GetRectMinX(gg_rct_Naga_Dungeon_Boss), GetRectMaxX(gg_rct_Naga_Dungeon_Boss)), GetRandomReal(GetRectMinY(gg_rct_Naga_Dungeon_Boss), GetRectMaxY(gg_rct_Naga_Dungeon_Boss)), 0, 0, 4.)
        call BlzSetUnitFacingEx(dummy, 270.)
        call BlzSetUnitSkin(dummy, 'e01F')
        call SetUnitScale(dummy, 10., 10., 10.)
        call SetUnitVertexColor(dummy, 0, 255, 255, 255)
        set t = NewTimer()
        call SaveReal(MiscHash, 0, GetHandleId(t), GetUnitX(dummy))
        call SaveReal(MiscHash, 1, GetHandleId(t), GetUnitY(dummy))
        call TimerStart(t, 3., false, function CollapseExpire)
        set i = i + 1
    endloop
    
    set t = null
    set dummy = null
endfunction

function NagaWaterStrike takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local group ug = CreateGroup()
    local unit target
    local unit dummy
    
    if GetWidgetLife(nagaboss) >= 0.406 then
        call MakeGroupInRect(foeid, ug, gg_rct_Naga_Dungeon_Boss, Condition(function FilterEnemy))
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set dummy = CreateUnit(pfoe, 'h003', GetUnitX(nagaboss), GetUnitY(nagaboss), 0)
            call IssueTargetOrder(dummy, "smart", target)
        endloop
    else
        set nagawaterstrikecd = false
        call ReleaseTimer(t)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set dummy = null
    set t = null
endfunction

function NagaMiasmaDamage takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer num = GetTimerData(t)
    local group ug = CreateGroup()
    local unit target
    local unit caster = LoadUnitHandle(MiscHash, GetHandleId(t), 0)
    
    call SetTimerData(t, num - 1)
    
    if num > 0 then
        call GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon, Condition(function isplayerunit))
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if periodicIsSecond(num, 0.5, 1) then
                call DestroyEffectTimed(AddSpecialEffectTarget("Units\\Undead\\PlagueCloud\\PlagueCloudtarget.mdl", target, "overhead"), 2)
            endif
            call UnitDamageTarget(caster, target, 25000 + BlzGetUnitMaxHP(target) * 0.03, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    else
        call RemoveSavedHandle(MiscHash, GetHandleId(t), 0)
        call ReleaseTimer(t)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set t = null
    set caster = null
endfunction

function NagaMiasma takes nothing returns nothing
    local timer t = GetExpiredTimer()
    
    call SetTimerData(t, 40)
    call TimerStart(t, 0.5, true, function NagaMiasmaDamage)
    
    set t = null
endfunction

function SwarmBeetle takes nothing returns nothing
   local timer t = GetExpiredTimer()
   local unit u = LoadUnitHandle(MiscHash, GetHandleId(t), 0)
   local unit u2 = LoadUnitHandle(MiscHash, GetHandleId(t), 1)
   
   call PauseUnit(u, false)
   call UnitRemoveAbility(u, 'Avul')
   call IssueTargetOrder(u, "attack", u2)
   call UnitApplyTimedLife(u, 'BTLF', 6.5)
   call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Parasite\\ParasiteTarget.mdl", u, "overhead"), 5.)
   
   call RemoveSavedHandle(MiscHash, GetHandleId(t), 0)
   call RemoveSavedHandle(MiscHash, GetHandleId(t), 1)
   call ReleaseTimer(t)
   
   set t = null
   set u = null
   set u2 = null
endfunction

function ApplyNagaAtkSpeed takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local unit u = LoadUnitHandle(MiscHash, GetHandleId(t), 0)
    local NagaEliteAtkSpeed nt

    if GetWidgetLife(u) >= 0.406 then
        set nt = NagaEliteAtkSpeed.add(u, u)
        set nt.duration = 4
    endif
    
    call RemoveSavedHandle(MiscHash, GetHandleId(t), 0)
    call ReleaseTimer(t)
    
    set u = null
    set t = null
endfunction

function ApplyNagaThorns takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local unit u = LoadUnitHandle(MiscHash, GetHandleId(t), 0)
    local NagaThorns nt

    if GetWidgetLife(u) >= 0.406 then
        set nt = NagaThorns.add(u, u)
        set nt.duration = 6.5
    endif
    
    call RemoveSavedHandle(MiscHash, GetHandleId(t), 0)
    call ReleaseTimer(t)
    
    set u = null
    set t = null
endfunction

function ElementalStorm takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local real x = LoadReal(MiscHash, GetHandleId(t), 0)
    local real y = LoadReal(MiscHash, GetHandleId(t), 1)
    local integer num = LoadInteger(MiscHash, GetHandleId(t), 2)
    local integer rand = GetRandomInt(1, 4)
    local real angle = GetRandomInt(0, 359) * bj_DEGTORAD
    local integer dist = GetRandomInt(0, 250)
    local real x2 = x + dist * Cos(angle)
    local real y2 = y + dist * Sin(angle)
    local group ug = CreateGroup()
    local unit target
    
    call MakeGroupInRange(pid, ug, x2, y2, 230. * BOOST(pid), Condition(function FilterEnemy))
    
    call SaveInteger(MiscHash, GetHandleId(t), 2, num - 1)
    
    if num > 0 then
        call DestroyEffectTimed(AddSpecialEffect("war3mapImported\\Lightnings Long.mdx", x2, y2), 1.)
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if rand == 1 then //fire
                call UnitDamageTarget(Hero[pid], target, GetHeroInt(Hero[pid], true) * 6 * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            elseif rand == 2 then //ice
                call DummyCastTarget(Player(pid - 1), target, 'A04Q', R2I(5 * LBOOST(pid)), x2, y2, "ensnare")
                call UnitDamageTarget(Hero[pid], target, GetHeroInt(Hero[pid], true) * 3, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            elseif rand == 3 then //lightning
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "origin"))
                call DummyCastTarget(Player(pid - 1), target, 'A0DS', R2I(4 * LBOOST(pid)), x2, y2, "thunderbolt")
                call UnitDamageTarget(Hero[pid], target, GetHeroInt(Hero[pid], true) * GetRandomInt(1, 10) * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            elseif rand == 4 then //earth
                call DummyCastTarget(Player(pid - 1), target, 'A04P', 1, x2, y2, "slow")
                call UnitDamageTarget(Hero[pid], target, GetHeroInt(Hero[pid], true) * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
        endloop
        if rand == 1 then
            call DestroyEffectTimed(AddSpecialEffect("war3mapImported\\Flame Burst.mdx", x2, y2), 2.)
        elseif rand == 2 then
            call DestroyEffectTimed(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", x2, y2), 2.)
        elseif rand == 4 then
            call DestroyEffectTimed(AddSpecialEffect("war3mapImported\\Earth NovaTarget.mdx", x2, y2), 2.)
        endif
    else
        call RemoveSavedReal(MiscHash, GetHandleId(t), 0)
        call RemoveSavedReal(MiscHash, GetHandleId(t), 1)
        call RemoveSavedInteger(MiscHash, GetHandleId(t), 2)
        call ReleaseTimer(t)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set t = null
endfunction

function ControlTime takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    call BlzSetUnitAttackCooldown(Hero[pid], BlzGetUnitAttackCooldown(Hero[pid], 0) / 0.5, 0)
endfunction

function ArcaneBarrage takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local unit target
    local integer i = BlzGroupGetSize(ArcaneBarrageHit[pid])
    local real dmg = GetHeroInt(Hero[pid], true) * (GetUnitAbilityLevel(Hero[pid], 'A02N') + 1) * BOOST(pid)
    
    loop
        set target = FirstOfGroup(ArcaneBarrageHit[pid])
        exitwhen target == null
        call GroupRemoveUnit(ArcaneBarrageHit[pid], target)
        if GetWidgetLife(target) >= 0.406 then
            if i == 1 then
                call UnitDamageTarget(Hero[pid], target, dmg * 3, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            else
                call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
        endif
    endloop
    
    set target = null
endfunction

function ArcaneBolts takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local integer num = LoadInteger(MiscHash, 0, GetHandleId(t))
    local real angle = LoadReal(MiscHash, 1, GetHandleId(t))

    call SaveInteger(MiscHash, 0, GetHandleId(t), num - 1)

    if num > -1 then
        set udg_PS_Index_Max = ( udg_PS_Index_Max + 1 )
        set udg_PS_Caster[udg_PS_Index_Max] = Hero[pid]
        set udg_PS_Dummy[udg_PS_Index_Max] = CreateUnit(Player(pid - 1), 'h00L', GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), GetUnitFacing(Hero[pid]))
        set udg_PS_HitEffect[udg_PS_Index_Max] = "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl"
        set udg_PS_Angle[udg_PS_Index_Max] = bj_RADTODEG * angle
        set udg_PS_Aoe[udg_PS_Index_Max] = 250 * BOOST(pid)
        set udg_PS_HitTerrain[udg_PS_Index_Max] = true
        set udg_PS_NoHitEff[udg_PS_Index_Max] = true
        set udg_PS_Pierce[udg_PS_Index_Max] = false
        set udg_PS_Damage[udg_PS_Index_Max] = GetHeroInt(Hero[pid], true) * 2 * BOOST(pid)
        set udg_PS_Range[udg_PS_Index_Max] = 1000.00
        set udg_PS_Speed[udg_PS_Index_Max] = 40.00
        set udg_PS_HitRange[udg_PS_Index_Max] = 125.00
        set udg_PS_DamagedUnits[udg_PS_Index_Max] = CreateGroup()
        set udg_PS_Dummy_Effect[udg_PS_Index_Max] = AddSpecialEffectTarget("ArcaneRocketProjectile.mdx", udg_PS_Dummy[udg_PS_Index_Max], "origin")
        
        call SetUnitXBounded(udg_PS_Dummy[udg_PS_Index_Max], GetUnitX(Hero[pid]))
        call SetUnitYBounded(udg_PS_Dummy[udg_PS_Index_Max], GetUnitY(Hero[pid]))
        call UnitAddAbility(udg_PS_Dummy[udg_PS_Index_Max], 'Amrf')
        call UnitRemoveAbility(udg_PS_Dummy[udg_PS_Index_Max], 'Amrf')
        call SetUnitFlyHeight( udg_PS_Dummy[udg_PS_Index_Max], 25.00, 0.00 )
        call SetUnitScalePercent( udg_PS_Dummy[udg_PS_Index_Max], 130.00, 130.00, 130.00 )
    else
        call RemoveSavedInteger(MiscHash, 0, GetHandleId(t))
        call RemoveSavedReal(MiscHash, 1, GetHandleId(t))
        call ReleaseTimer(t)
    endif
    
    set t = null
endfunction

function HeliCD takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
        
    set heliCD[pid] = false
endfunction

function MetamorphosisExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    set HeroInvul[pid] = true
    call TimerStart(NewTimerEx(pid), 1.0, false, function MetamorphosisInvulnExpire)
endfunction

function MetamorphosisStart takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    set HeroInvul[pid] = false
    set ismetamorphosis[pid] = true
    call GroupRemoveUnit(AffectedByWeather, Hero[pid])
    call EnterWeather(Hero[pid])
    call TimerStart(NewTimerEx(pid), 10 * GetUnitAbilityLevel(Hero[pid], 'AEme') - 0.2, false, function MetamorphosisExpire)
endfunction

function Monsoon takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local integer num = R2I(LoadReal(MiscHash, GetHandleId(t), 0))
    local real AOE = LoadReal(MiscHash, GetHandleId(t), 1)
    local real x = LoadReal(MiscHash, GetHandleId(t), 2)
    local real y = LoadReal(MiscHash, GetHandleId(t), 3)
    local group ug = CreateGroup()
    local unit target
    local real dmg = MonsoonFormula(pid) * BOOST(pid)
    
    if GetUnitAbilityLevel(Hero[pid],'B0ov') > 0 then
        set dmg = dmg * (1 + 0.1 * GetUnitAbilityLevel(Hero[pid],'A096'))
    endif
    
    call SaveReal(MiscHash, GetHandleId(t), 0, num - 1)
    
    if num > 0 then
        call MakeGroupInRange(pid, ug, x, y, AOE, Condition(function FilterEnemy))
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call DestroyEffect(AddSpecialEffect( "Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", GetUnitX(target), GetUnitY(target) ))
            call UnitDamageTarget(Hero[pid],target,dmg,true,false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
        endloop
    else
        call RemoveSavedReal(MiscHash, GetHandleId(t), 0)
        call RemoveSavedReal(MiscHash, GetHandleId(t), 1)
        call RemoveSavedReal(MiscHash, GetHandleId(t), 2)
        call RemoveSavedReal(MiscHash, GetHandleId(t), 3)
        call ReleaseTimer(t)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
    set t = null
endfunction

function Omnislash takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real x = GetUnitX(Hero[pid])
    local real y = GetUnitY(Hero[pid])
    local group ug = CreateGroup()
    local unit target
    local real dmg = OmnislashFormula(pid) * BOOST(pid)
    
    if GetUnitAbilityLevel(Hero[pid],'B0ov') > 0 then
        set dmg = dmg * (1 + 0.1 * GetUnitAbilityLevel(Hero[pid],'A096'))
    endif
    
    set pt.dur = pt.dur - 1
    
    if pt.dur > 0 then
        call MakeGroupInRange(pid, ug, x, y, 600., Condition(function FilterEnemy))
        
        set target = FirstOfGroup(ug)

        if target != null then
            call SetUnitAnimation(Hero[pid], "Attack Slam")
            call SetUnitXBounded(Hero[pid], GetUnitX(target) + 60. * Cos(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
            call SetUnitYBounded(Hero[pid], GetUnitY(target) + 60. * Sin(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
            call BlzSetUnitFacingEx(Hero[pid], GetUnitFacing(target))
            call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
            call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\NightElf\\Blink\\BlinkHero[pid].mdl", Hero[pid], "chest" ) )
            call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "chest" ) )
        else
            call reselect(Hero[pid])
            call SetUnitVertexColor(Hero[pid], 255, 255, 255, 255)
            call SetUnitTimeScale(Hero[pid], 1.)
            call TimerList[pid].removePlayerTimer(pt)
        endif
    else
        call reselect(Hero[pid])
		call SetUnitVertexColor(Hero[pid], 255, 255, 255, 255)
        call SetUnitTimeScale(Hero[pid], 1.)
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
endfunction

function HeliRocketDamage takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local real dmg = (GetHeroAgi(Hero[pid], true) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) * 0.5 * heliboost[pid]
    local unit target
    local group ug = CreateGroup()
    
    call DestroyEffect(AddSpecialEffect("war3mapImported\\NewMassiveEX.mdx", GetLocationX(FlightTarget[pid]), GetLocationY(FlightTarget[pid])))
    call MakeGroupInRange(pid, ug, GetLocationX(FlightTarget[pid]), GetLocationY(FlightTarget[pid]), 400. * heliboost[pid], Condition(function FilterEnemy))
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call DummyCastTarget(Player(pid - 1), target, 'A0DS', 8, GetUnitX(target), GetUnitY(target), "thunderbolt")
        call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop

    call RemoveLocation(FlightTarget[pid])

    call DestroyGroup(ug)
    
    set ug = null
    set target = null
endfunction

function HeliRocket takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local unit target = GetDummy(GetUnitX(helicopter[pid]), GetUnitY(helicopter[pid]), 'A04F', 1, DUMMY_RECYCLE_TIME)

    call SoundHandler("units\\Human\\Gyrocopter\\GyrocopterPissed1.wav", Player(pid - 1))
    call IssuePointOrder(target, "clusterrockets", GetLocationX(FlightTarget[pid]), GetLocationY(FlightTarget[pid]))
    call SetUnitFlyHeight(target, GetUnitFlyHeight(helicopter[pid]), 30000.)

    call TimerStart(NewTimerEx(pid), 0.7, false, function HeliRocketDamage)
    
    set target = null
endfunction

function ClusterRocketsDamage takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local real dmg = AssaultHelicopterFormula(pid) * heliboost[pid]
    local unit target
    local group ug = CreateGroup()
    
    call BlzGroupAddGroupFast(helitargets[pid], ug)
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if LoadInteger(MiscHash, GetHandleId(target), 'heli') == 1 and sniperstance[pid] then
            call UnitDamageTarget(Hero[pid], target, dmg * 2.5, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            call RemoveSavedInteger(MiscHash, GetHandleId(target), 'heli')
        elseif not sniperstance[pid] then
            call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif
    endloop
    
    call DestroyGroup(ug)
    
    set ug = null
endfunction

function ClusterRockets takes integer pid returns nothing
    local integer i = 0
    local integer i2 = 0
    local group array ugs
    local group ug = CreateGroup()
    local group ug2 = CreateGroup()
    local unit target
    local unit target2
    local integer enemyCount = 0
    local integer enemyCaptured = 0
    local integer groupIndex = 0
    local unit array targetArray

    call BlzGroupAddGroupFast(helitargets[pid], ug)
    //clean helitargets
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if GetWidgetLife(target) < 0.406 or UnitDistance(target, helicopter[pid]) > 1500. or IsUnitType(target, UNIT_TYPE_DEAD) then
            call GroupRemoveUnit(helitargets[pid], target)
        endif
    endloop
    
    call BlzGroupAddGroupFast(helitargets[pid], ug)
    set enemyCount = BlzGroupGetSize(ug)
    
    if enemyCount > 0 then
        if sniperstance[pid] then
            if GetWidgetLife(LAST_TARGET[pid]) >= 0.406 then
                set target = LAST_TARGET[pid]
            else
                set target = FirstOfGroup(helitargets[pid])
            endif
            call GroupClear(helitargets[pid])
            call GroupAddUnit(helitargets[pid], target)
            set target2 = GetDummy(GetUnitX(helicopter[pid]), GetUnitY(helicopter[pid]), 'A03N', 1, DUMMY_RECYCLE_TIME)
            call SetUnitOwner(target2, Player(pid - 1), true)
            call IssuePointOrder(target2, "clusterrockets", GetUnitX(target), GetUnitY(target))
            call SetUnitFlyHeight(target2, GetUnitFlyHeight(helicopter[pid]), 30000.)
            call SaveInteger(MiscHash, GetHandleId(target), 'heli', 1)
        else
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                if enemyCaptured < enemyCount then
                    set ugs[i] = CreateGroup()
                    call MakeGroupInRange(pid, ugs[i], GetUnitX(target), GetUnitY(target), 300., Condition(function FilterEnemy))
                    set enemyCaptured = enemyCaptured + BlzGroupGetSize(ugs[i])
                    set targetArray[i] = null
                    if i > 0 then
                        //check overlapping units
                        call BlzGroupAddGroupFast(ugs[i], ug2)
                        loop
                            set target2 = FirstOfGroup(ug2)
                            exitwhen target2 == null
                            call GroupRemoveUnit(ug2, target2)
                            set i2 = 0
                            loop
                                exitwhen i2 == i
                                if IsUnitInGroup(target2, ugs[i2]) then
                                    set enemyCaptured = enemyCaptured - 1
                                    call GroupRemoveUnit(ugs[i], target2)
                                endif
                                set i2 = i2 + 1
                            endloop
                        endloop
                        if BlzGroupGetSize(ugs[i]) > 0 then
                            set targetArray[i] = FirstOfGroup(ugs[i])
                        endif
                        if enemyCaptured >= enemyCount then
                            set groupIndex = i
                            exitwhen true
                        endif
                    else
                        set targetArray[0] = target
                    endif
                elseif groupIndex == 0 then
                    set groupIndex = i
                    exitwhen true
                endif
                set i = i + 1
            endloop
            
            set i = 0
                
            loop
                exitwhen i > groupIndex
                if GetWidgetLife(targetArray[i]) >= 0.406 and IsUnitType(targetArray[i], UNIT_TYPE_DEAD) == false then
                    set target = GetDummy(GetUnitX(helicopter[pid]), GetUnitY(helicopter[pid]), 'A04D', 1, DUMMY_RECYCLE_TIME)
                    call SetUnitOwner(target, Player(pid - 1), true)
                    call IssuePointOrder(target, "clusterrockets", GetUnitX(targetArray[i]), GetUnitY(targetArray[i]))
                    call SetUnitFlyHeight(target, GetUnitFlyHeight(helicopter[pid]), 30000.)
                endif
                set targetArray[i] = null
                call DestroyGroup(ugs[i])
                set ugs[i] = null
                set i = i + 1
            endloop
        endif
    
        call TimerStart(NewTimerEx(pid), 0.8, false, function ClusterRocketsDamage)
    endif


    call DestroyGroup(ug)
    call DestroyGroup(ug2)

    set ug = null
    set ug2 = null
    set target = null
    set target2 = null
endfunction

function TriRocketCD takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())

    call BlzEndUnitAbilityCooldown(Hero[pid], 'A06I')
endfunction

function FightMeExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    set FightMe[pid] = false
endfunction

function ProtectionExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local unit target

    loop
        set target = FirstOfGroup(ProtectionGroup[pid])
        exitwhen target == null
        call GroupRemoveUnit(ProtectionGroup[pid], target)
        call UnitRemoveAbility(target, 'B01S')
    endloop
    
    set target = null
endfunction

function ResetCD takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    call UnitResetCooldown(Hero[pid])
    call UnitResetCooldown(Backpack[pid])
    set ReincarnationPRCD[pid] = 1
    set ResurrectionCD[pid] = 1
endfunction

function DemonicSarificeExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    call UnitRemoveAbility(Hero[pid], 'A0K2')
endfunction

function MeteorExpire takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target

    call DestroyTreesInRange(pt.x, pt.y, 250)
    call reselect(Hero[pid])
    call BlzPauseUnitEx(Hero[pid], false)
    
    call MakeGroupInRange(pid, ug, pt.x, pt.y, 300 * LBOOST(pid), Condition(function FilterEnemy))
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call DummyCastTarget(Player(PLAYER_NEUTRAL_PASSIVE), target, 'A0DS', 2, GetUnitX(target), GetUnitY(target), "thunderbolt")
        call UnitDamageTarget(Hero[pid], target, GetHeroStr(Hero[pid], true) * GetUnitAbilityLevel(Hero[pid], 'A07O') + 100, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop
    
    if SquareRoot(Pow(GetUnitX(Hero[pid]) - pt.x, 2) + Pow(GetUnitY(Hero[pid]) - pt.y, 2)) < 1000. then
        call SetUnitPosition(Hero[pid], pt.x, pt.y)
    endif

    call SetUnitAnimation(Hero[pid], "birth")
    call SetUnitTimeScale(Hero[pid], 1)
    call Fade(Hero[pid], 40, 0.03, -1)
    
    call DestroyGroup(ug)

    call TimerList[pid].removePlayerTimer(pt)
    
    set ug = null
endfunction

function SmokebombExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    set SmokebombX[pid] = 0
    set SmokebombY[pid] = 0
endfunction

function FlamingBowExpire takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    
    call UnitRemoveAbility(Hero[pid], 'A08B')
    call UnitAddBonus(Hero[pid], BONUS_DAMAGE, -R2I(FlamingBowBonus[pid]))
    set FlamingBowBonus[pid] = 0
    set FlamingBowCount[pid] = 0
        
    call TimerList[pid].removePlayerTimer(pt)
endfunction

function MedeanLightning takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'AOcl')
    local real dmg = ((GetHeroInt(Hero[pid], true) * (ablev + 1)) + 100) * BOOST(pid)
    local unit target
    
    if pt.agi > 0 then //dark seal
        if BlzGroupGetSize(darkSealTargets[pid * 8]) == 0 then
            call BlzGroupAddGroupFast(darkSealTargets[pid], darkSealTargets[pid * 8])
        endif

        loop
            set target = BlzGroupUnitAt(darkSealTargets[pid * 8], GetRandomInt(0, BlzGroupGetSize(darkSealTargets[pid * 8]) - 1))
            if target == null or GetWidgetLife(target) < 0.406 then
                call GroupRemoveUnit(darkSealTargets[pid], target)
                call GroupRemoveUnit(darkSealTargets[pid * 8], target)
            endif
            exitwhen (target != null and GetWidgetLife(target) >= 0.406) or BlzGroupGetSize(darkSealTargets[pid * 8]) <= 0
        endloop
        
        if darkSealActive[pid] == false or target == null or pt.dur <= 0 then
            call GroupClear(medeanLightningHit[pid])
            call GroupClear(darkSealTargets[pid * 8])
            call TimerList[pid].removePlayerTimer(pt)
        else
            set pt.dur = pt.dur - 1
            call GroupRemoveUnit(darkSealTargets[pid * 8], target)
            set bj_lastCreatedUnit = GetDummy(pt.x, pt.y, 'A01Y', 1, DUMMY_RECYCLE_TIME)
            call SaveInteger(MiscHash, GetHandleId(bj_lastCreatedUnit), 'mede', pid)
            call BlzSetUnitWeaponBooleanField(bj_lastCreatedUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(bj_lastCreatedUnit), GetUnitX(target) - GetUnitX(bj_lastCreatedUnit)))
            call IssueTargetOrder(bj_lastCreatedUnit, "attack", target)
            set pt.x = GetUnitX(target)
            set pt.y = GetUnitY(target)
        endif
    else
        call MakeGroupInRange(pid, ug, pt.x, pt.y, 500.00, Condition(function FilterEnemy))
            
        loop
            set target = FirstOfGroup(ug)
            call GroupRemoveUnit(ug, target)
            exitwhen IsUnitInGroup(target, medeanLightningHit[pid]) == false or target == null
        endloop
    
        if pt.dur > 0 and target != null then
            set pt.dur = pt.dur - 1
        
            if IsUnitInGroup(target, darkSealTargets[pid]) then
                set pt.agi = 1
            endif

            set bj_lastCreatedUnit = GetDummy(pt.x, pt.y, 'A01Y', 1, DUMMY_RECYCLE_TIME)
            call SaveInteger(MiscHash, GetHandleId(bj_lastCreatedUnit), 'mede', pid)
            call BlzSetUnitWeaponBooleanField(bj_lastCreatedUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(bj_lastCreatedUnit), GetUnitX(target) - GetUnitX(bj_lastCreatedUnit)))
            call IssueTargetOrder(bj_lastCreatedUnit, "attack", target)
            set pt.x = GetUnitX(target)
            set pt.y = GetUnitY(target)
            call GroupAddUnit(medeanLightningHit[pid], target)
        else
            call GroupClear(medeanLightningHit[pid])
            call TimerList[pid].removePlayerTimer(pt)
        endif
    endif
    
    call DestroyGroup(ug)
    
    set target = null
    set ug = null
endfunction

function ArmorOfTheElementsPush takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local real angle
    local unit u
    local group ug = CreateGroup()
    
    call BlzGroupAddGroupFast(aotePush[pid], ug)
    
    set aotePushAmount[pid] = aotePushAmount[pid] - 1
    
    if aotePushAmount[pid] > 0 then
        loop
            set u = FirstOfGroup(ug)
            exitwhen u == null
            call GroupRemoveUnit(ug, u)
            set angle = Atan2(GetUnitY(u) - GetUnitY(Hero[pid]), GetUnitX(u) - GetUnitX(Hero[pid]))
            if IsTerrainWalkable(GetUnitX(u) + 20 * Cos(angle), GetUnitY(u) + 10 * Sin(angle)) then
                call SetUnitXBounded(u, GetUnitX(u) + 20 * Cos(angle))
                call SetUnitYBounded(u, GetUnitY(u) + 20 * Sin(angle))
            endif
        endloop
    else
        call ReleaseTimer(t)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set u = null
    set t = null
endfunction

function ArmorOfTheElementsCD takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())

    if HeroID[pid] == HERO_ELEMENTALIST then
        set aoteCD[pid] = true
        call UnitAddAbility(Hero[pid], 'A033')
        call BlzUnitHideAbility(Hero[pid], 'A033', true)
    endif
endfunction
    
function ArmorOfTheElements takes unit u returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local group ug = CreateGroup()
    local unit target
    
    call UnitRemoveAbility(u, 'Avul')
    call SetUnitState(u, UNIT_STATE_MANA, GetUnitState(u, UNIT_STATE_MANA) + GetUnitState(u, UNIT_STATE_MAX_MANA) * 0.5)
    call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Doom\\DoomDeath.mdl", u, "origin"))
        
    call MakeGroupInRange(pid, ug, GetUnitX(u), GetUnitY(u), 800., Condition(function FilterEnemy))
        
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call GroupAddUnit(aotePush[pid], target)
        call DummyCastTarget(Player(PLAYER_NEUTRAL_PASSIVE), target, 'A0DS', 5, GetUnitX(target), GetUnitY(target), "thunderbolt")
    endloop
    
    set aotePushAmount[pid] = 35
        
    call TimerStart(NewTimerEx(pid), 0.03, true, function ArmorOfTheElementsPush)
    call TimerStart(NewTimerEx(pid), 120., false, function ArmorOfTheElementsCD)
    
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
endfunction

function BladeStorm takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = LoadInteger(MiscHash, 0, GetHandleId(t))
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A03O')
    local real AOE = 400 * LBOOST(pid)
    local real dmg = GetHeroAgi(Hero[pid],true) * ablev * 0.2 * BOOST(pid)
    local integer time = GetTimerData(t)
    local group ug = CreateGroup()
    local unit u
    
    call SetTimerData(t, time + 1)
    
    if GetUnitAbilityLevel(Hero[pid],'B0ov') > 0 then
        set dmg = dmg * (1 + 0.1 * GetUnitAbilityLevel(Hero[pid],'A096'))
    endif
    
    if GetWidgetLife(Hero[pid]) >= 0.406 and time < 9 then
        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), AOE, Condition(function FilterEnemy))

        if GetRandomInt(0, 99) < 15 * LBOOST(pid) then
            set u = BlzGroupUnitAt(ug, GetRandomInt(0, BlzGroupGetSize(ug) - 1))
            call DummyCastTarget(GetOwningPlayer(Hero[pid]), u, 'A09S', 1, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), "forkedlightning")
            call UnitDamageTarget(Hero[pid], u, GetHeroAgi(Hero[pid], true) * (2 + ablev) * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif
        loop
            set u = FirstOfGroup(ug)
            exitwhen u == null
            call GroupRemoveUnit(ug, u)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", u, "origin"))
            call UnitDamageTarget(Hero[pid], u, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    else
        call RemoveSavedInteger(MiscHash, 0, GetHandleId(t))
        call ReleaseTimer(t)
        call AddUnitAnimationProperties(Hero[pid], "spin", false)
    endif
    
    call DestroyGroup(ug)
    
    set t = null
    set ug = null
    set u = null
endfunction

function AvatarExpire takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real dmg = pt.dmg
    local real armor = pt.armor

    call UnitRemoveAbility(Hero[pid], 'A0CZ')
    if GetUnitTypeId(Hero[pid]) == HERO_SAVIOR then
        call UnitAddBonus(Hero[pid], BONUS_DAMAGE, - R2I(dmg))
        call UnitAddBonus(Hero[pid], BONUS_ARMOR, - R2I(armor))
    endif
    
    call TimerList[pid].removePlayerTimer(pt)
endfunction

function ArcaneMightExpire takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer stat = R2I(pt.dur)
    local integer dmg = R2I(pt.dmg)

    call UnitAddBonus(pt.target, BONUS_DAMAGE, - dmg)
    call UnitAddBonus(pt.target, BONUS_HERO_STR, -(stat))
    if GetUnitTypeId(pt.target) != SUMMON_DESTROYER then
        call UnitAddBonus(pt.target, BONUS_HERO_AGI, -(stat))
    endif
    call UnitAddBonus(pt.target, BONUS_HERO_INT, -(stat))
    call UnitRemoveAbility(pt.target, 'B0AM')
    
    call TimerList[pid].removePlayerTimer(pt)
endfunction

function HydroTidalWave takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local unit target
    local group ug = CreateGroup()
    local real x = GetUnitX(udg_DashDummy[pid])
    local real y = GetUnitY(udg_DashDummy[pid])

	if udg_DashDistance[pid] > 0 and GetUnitTypeId(Hero[pid]) == HERO_HYDROMANCER then
//
        call MakeGroupInRange(pid, ug, x, y, 300 * BOOST(pid), Condition(function FilterEnemy))
        call SetUnitPosition(udg_DashDummy[pid], x + 34 * Cos(udg_DashAngleR[pid]), y + 34 * Sin(udg_DashAngleR[pid]))
        
        set udg_DashDistance[pid] = udg_DashDistance[pid] - 34

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if IsUnitType(target, UNIT_TYPE_STRUCTURE) == false and GetUnitMoveSpeed(target) > 0 then
                call DestroyEffect(AddSpecialEffect("war3mapImported\\SlideWater.mdx", GetUnitX(target), GetUnitY(target)))
                call SetUnitPosition(target, GetUnitX(target) + Cos(udg_DashAngleR[pid]) * 17, GetUnitY(target) + Sin(udg_DashAngleR[pid]) * 17)
            endif
            
            if WaveBuffed[pid] == 1 and IsUnitInGroup(target, tidalwaved) == false then
                call DummyCastTarget(GetOwningPlayer(Hero[pid]), target, 'A03B', 1, GetUnitX(target), GetUnitY(target), "slow")
                call DummyCastTarget(GetOwningPlayer(Hero[pid]), target, 'A02P', 1, GetUnitX(target), GetUnitY(target), "cripple")
            elseif WaveBuffed[pid] == 0 and IsUnitInGroup(target, tidalwaved) == false then
                call DummyCastTarget(GetOwningPlayer(Hero[pid]), target, 'A03B', 1, GetUnitX(target), GetUnitY(target), "slow")
                call DummyCastTarget(GetOwningPlayer(Hero[pid]), target, 'A02R', 1, GetUnitX(target), GetUnitY(target), "cripple")
            endif
            call GroupAddUnit(tidalwaved, target)
        endloop
        
    elseif udg_DashDistance[pid] < 0 then
        set WaveBuffed[pid] = 0
        
        call ReleaseTimer(t)
        call RecycleDummy(udg_DashDummy[pid])
        
        loop
            set target = FirstOfGroup(tidalwaved)
            exitwhen target == null
            call GroupRemoveUnit(tidalwaved, target)
        endloop
    endif
    
    call DestroyGroup(ug)

    set target = null
    set ug = null
    set t = null
endfunction

function HydroWhirlpool takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer time = GetTimerData(t)
    local integer pid = LoadInteger(MiscHash, 0, GetHandleId(t))
    local real x
    local real y
    local real dx
    local real dy
    local real boost = BOOST(pid)
    local group ug = CreateGroup()
    local unit target
    local real dist
    local real angle = 0
    local integer i = 0
    local location loc
    
    call SetTimerData(t, time + 1)
        
    if whirldur[pid] > 0 then
        set x = GetLocationX(whirlspot[pid])
        set y = GetLocationY(whirlspot[pid])
        call MakeGroupInRange(pid, ug, x, y, 330 * boost, Condition(function FilterEnemy))
        set whirldur[pid] = whirldur[pid] - 0.03
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            //movement effects
            set angle = Atan2(y - GetUnitY(target), x - GetUnitX(target))
            set loc = GetUnitLoc(target)
            
            if IsUnitType(target, UNIT_TYPE_HERO) == false and GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(GetUnitX(target) + (17. + 30. / (Distance(loc, whirlspot[pid]) + 1)) * Cos(angle), GetUnitY(target) + (17. + 30. / (Distance(loc, whirlspot[pid]) + 1)) * Sin(angle)) then
                call SetUnitPathing(target, false)
                call SetUnitXBounded(target, GetUnitX(target) + (17. + 30. / (Distance(loc, whirlspot[pid]) + 1)) * Cos(angle))
                call SetUnitYBounded(target, GetUnitY(target) + (17. + 30. / (Distance(loc, whirlspot[pid]) + 1)) * Sin(angle))
            endif
            call SetUnitPathing(target, true)
            
            call RemoveLocation(loc)
            
            if periodicIsSecond(time, 0.03, 1) then
                call UnitDamageTarget(Hero[pid], target, WhirlDamage[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
            
            call GroupAddUnit(whirlpooled[pid], target)
            
            if IsUnitType(target, UNIT_TYPE_HERO) == true then
                set whirldur[pid] = whirldur[pid] - 0.03
            else
                set whirldur[pid] = whirldur[pid] - 0.003
            endif

            if GetUnitAbilityLevel(target, 'B01G') == 0 then
                call DummyCastTarget(GetOwningPlayer(Hero[pid]), target, 'A03B', 1, GetUnitX(target), GetUnitY(target), "slow")
            endif
            if whirldur[pid] < 0 then
                call DummyCastTarget(GetOwningPlayer(Hero[pid]), target, 'A03B', 1, GetUnitX(target), GetUnitY(target), "slow")
            endif
        endloop

        loop
            exitwhen i > 5
            set dx = GetUnitX(dummymodel[pid * 5 + i]) - x
            set dy = GetUnitY(dummymodel[pid * 5 + i]) - y
            set dist = SquareRoot(dx * dx + dy * dy)
            set angle = Atan2(dy, dx)
            call SetUnitXBounded(dummymodel[pid * 5 + i], x + dist * Cos(angle + .05 + i / 50.))
            call SetUnitYBounded(dummymodel[pid * 5 + i], y + dist * Sin(angle + .05 + i / 50.))
            call BlzSetUnitFacingEx(dummymodel[pid * 5 + i], angle * bj_RADTODEG + 90)
            set i = i + 1
        endloop
    elseif whirldur[pid] <= 0 then
        set whirldur[pid] = 0
        loop
            exitwhen i > 5
            call DestroyEffect(dummyeffect[pid * 5 + i])
            call RecycleDummy(dummymodel[pid * 5 + i])
            set dummymodel[pid * 5 + i] = null
            set dummyeffect[pid * 5 + i] = null
            set i = i + 1
        endloop
        loop
            set target = FirstOfGroup(whirlpooled[pid])
            exitwhen target == null
            call GroupRemoveUnit(whirlpooled[pid], target)
            call SetUnitPathing(target, true)
            call SetUnitPosition(target, GetUnitX(target), GetUnitY(target))
        endloop
        call DestroyEffectTimed(AddSpecialEffect("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", GetLocationX(whirlspot[pid]), GetLocationY(whirlspot[pid])), 3)
        call RemoveLocation(whirlspot[pid])
        call DestroyEffect(whirlpoolcloud[pid])
        set whirlpoolcloud[pid] = null
        call RemoveSavedInteger(MiscHash, 0, GetHandleId(t))
        call ReleaseTimer(t)
    endif
        
    call DestroyGroup(ug)    
    
    set t = null
    set ug = null
    set target = null
    set loc = null
endfunction

function Electrocute takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = LoadInteger(MiscHash, 0, GetHandleId(t))
    local real boost = BOOST(pid)
    local group ug = CreateGroup()
    local timer et
    local unit target
    
    if IsUnitType(Hero[pid], UNIT_TYPE_DEAD) == false and HeroID[pid] == HERO_ELEMENTALIST then
    
        set et = NewTimer()
       
        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 600 * LBOOST(pid), Condition(function FilterEnemy))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set bj_lastCreatedUnit = GetDummy(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 'A09W', 1, DUMMY_RECYCLE_TIME)
            call BlzSetUnitWeaponBooleanField(bj_lastCreatedUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(bj_lastCreatedUnit), GetUnitX(target) - GetUnitX(bj_lastCreatedUnit)))
            call IssueTargetOrder(bj_lastCreatedUnit, "attack", target)
            call UnitDamageTarget(Hero[pid], target, GetHeroInt(Hero[pid], true) * .5 * boost, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    endif
    
    call DestroyGroup(ug)
    
    set t = null
    set ug = null
    set target = null
    set et = null
endfunction

function StanceAbilityDelay takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
        
    call UnitRemoveAbility(Hero[pid], 'Avul')
    call UnitRemoveAbility(Hero[pid], 'A03C')
    call UnitAddAbility(Hero[pid], 'A03C')

    call EnterWeather(Hero[pid])
endfunction

function DeathStrikeTP takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local unit target = LoadUnitHandle(MiscHash, 0, GetHandleId(t))
    local real x = GetUnitX(target) - 80 * Cos(GetUnitFacing(target) * bj_DEGTORAD)
	local real y = GetUnitY(target) - 80 * Sin(GetUnitFacing(target) * bj_DEGTORAD)
    local real dmg = (GetUnitAbilityLevel(Hero[pid], 'A0QV') + 1) * 0.5 * GetHeroAgi(Hero[pid], true) * BOOST(pid)
    
    if Windwalk[pid] then
        set Windwalk[pid] = false
        set dmg = dmg + ((UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroAgi(Hero[pid], true)) * .25 * GetUnitAbilityLevel(Hero[pid], 'A0F5') + GetHeroAgi(Hero[pid], true) * GetUnitAbilityLevel(Hero[pid], 'A0F5')) * BOOST(pid)
        call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Orc\\Devour\\DevourEffectArt.mdl", Hero[pid], "overhead" ) )
        call UnitRemoveAbility(Hero[pid], 'BOwk')
    endif

    call BlzPauseUnitEx(target, false)
    if IsTerrainWalkable(x, y) then
        call SetUnitXBounded(Hero[pid], x)
        call SetUnitYBounded(Hero[pid], y)
        call BlzSetUnitFacingEx(Hero[pid], Atan2(GetUnitY(target) - y, GetUnitX(target) - x)) 
    endif
    call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", target, "origin"))
    call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    call IssueTargetOrder(Hero[pid], "smart", target)

    call RemoveSavedHandle(MiscHash, 0, GetHandleId(t))
    
    call ReleaseTimer(t)
    
    set t = null
    set target = null
endfunction

function Unimmobilize takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local unit u = LoadUnitHandle(MiscHash, 0, GetHandleId(t))
    
    call UnitRemoveAbility(u, 'S00I')
    call SetUnitTurnSpeed(u, GetUnitDefaultTurnSpeed(u))
    
    call RemoveSavedHandle(MiscHash, 0, GetHandleId(t))
    call ReleaseTimer(t)
    
    set t = null
    set u = null
endfunction

function PhantomSlash takes nothing returns nothing
    call DummyCastTarget(Player(PLAYER_NEUTRAL_PASSIVE), udg_A_CB_BuffEffectUnit, 'A02B', 1, GetUnitX(udg_A_CB_BuffEffectUnit), GetUnitY(udg_A_CB_BuffEffectUnit), "slow")
    call GroupAddUnit(markedfordeath[GetPlayerId(GetOwningPlayer(udg_A_CB_Caster[udg_A_CB_Index])) + 1], udg_A_CB_BuffEffectUnit)
    if GetUnitAbilityLevel(udg_A_CB_BuffEffectUnit, 'B019') == 0 then
        call UnitAddAbility(udg_A_CB_BuffEffectUnit, 'B019')
    endif
endfunction

function DaggerStorm takes nothing returns nothing
    set udg_PS_Damage[udg_PS_Index] = udg_PS_Damage[udg_PS_Index] * 0.95
endfunction

function ToneOfDeath takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local unit u = LoadUnitHandle(MiscHash, 0, GetHandleId(t))
    local integer time = GetTimerData(t)
    local integer pid = LoadInteger(MiscHash, 1, GetHandleId(t))
    local group ug = CreateGroup()
    local group g = CreateGroup()
    local unit target
    local real angle
    local real damage = (0.5 + 0.5 * GetUnitAbilityLevel(Hero[pid], 'A02K')) * GetHeroInt(Hero[pid], true) * BOOST(pid)
    local integer rand = GetRandomInt(-10, 10)
    
    call SetTimerData(t, time + 1)
    
    call MakeGroupInRange(pid, ug, GetUnitX(u), GetUnitY(u), 350. * BOOST(pid), Condition(function FilterEnemy))
    call MakeGroupInRange(pid, g, GetUnitX(u), GetUnitY(u), 350. * BOOST(pid), Condition(function FilterEnemy))
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if GetUnitMoveSpeed(target) > 0 then
            call GroupAddUnit(blackholed, target)
            set angle = bj_RADTODEG * Atan2(GetUnitY(u) - GetUnitY(target), GetUnitX(u) - GetUnitX(target))
            
            if GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(GetUnitX(target) + (17. + 30. / (UnitDistance(target, u) + 1)) * Cos((angle + rand) * bj_DEGTORAD), GetUnitY(target) + (15. + 40. / (UnitDistance(target, u) + 1)) * Sin((angle + rand) * bj_DEGTORAD)) then
                call SetUnitPathing(target, false)
                call SetUnitXBounded(target, GetUnitX(target) + (17. + 30. / (UnitDistance(target, u) + 1)) * Cos((angle + rand) * bj_DEGTORAD))
                call SetUnitYBounded(target, GetUnitY(target) + (17. + 30. / (UnitDistance(target, u) + 1)) * Sin((angle + rand) * bj_DEGTORAD))
            endif
        endif
    endloop
    
    if periodicIsSecond(time, 0.03, 1) and time > 0 then
        loop
            set target = FirstOfGroup(g)
            exitwhen target == null
            call GroupRemoveUnit(g, target)
            call UnitDamageTarget(Hero[pid], target, damage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
        if time >= 164 then
            loop
                set target = FirstOfGroup(blackholed)
                exitwhen target == null
                call GroupRemoveUnit(blackholed, target)
                call SetUnitPathing(target, true)
                call SetUnitPosition(target, GetUnitX(target), GetUnitY(target))
            endloop
            call RemoveSavedInteger(MiscHash, 1, GetHandleId(t))
            call RemoveSavedHandle(MiscHash, 0, GetHandleId(t))
            call ReleaseTimer(t)
        endif
    endif
    
    call DestroyGroup(ug)
    call DestroyGroup(g)
    
    set t = null
    set u = null
    set ug = null
    set g = null
    set target = null
endfunction

function BloodFrenzyExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    
    call UnitAddBonus(Hero[pid], BONUS_DAMAGE, - bloodfrenzybonus[pid])
    call BlzSetUnitAttackCooldown(Hero[pid],BlzGetUnitAttackCooldown(Hero[pid], 0) * 1.20, 0)
    call UnitRemoveAbility(Hero[pid], 'A07E')
    call UnitRemoveAbility(Hero[pid], 'Bbsk')
    
    call PauseTimer(t)
    call ReleaseTimer(t)
    
    set bloodfrenzybonus[pid] = 0
    set t = null
endfunction

function ResetAza takes nothing returns nothing
	if GetWidgetLife(ChaosBoss[BOSS_AZAZOTH])>0.5 then
		call PauseUnit(ChaosBoss[BOSS_AZAZOTH],false)
		call SetUnitAnimation(ChaosBoss[BOSS_AZAZOTH], "stand")
	endif
	set udg_Azazoth_Casting_Spell=false
endfunction

function AstralDevastation takes unit caster, real dur, real dmg, real angle returns nothing
    local location loc = GetUnitLoc(caster)
    local location loc2
    local integer i = 1
    local integer i2
    local group g = CreateGroup()
    local unit target
    local integer playerBonus = 0
    local integer pid = GetPlayerId(GetOwningPlayer(caster)) + 1

    call DoFloatingTextUnit("Astral Devastation", caster, 2, 70, 0, 11, 100, 40, 40, 0)

    if pid == bossid then //azazoth cast
        set udg_Azazoth_Casting_Spell=true
        call PauseUnit(caster, true)
        call SetUnitAnimation(caster, "spell slam")
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", caster, "origin"))
        call TriggerSleepAction(0.1 * dur)
        call SetUnitAnimation(caster, "spell slam")
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", caster, "origin"))
        call TriggerSleepAction(0.1 * dur)
        call SetUnitAnimation(caster, "spell slam")
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", caster, "origin"))
        call TriggerSleepAction(0.1 * dur)
    else
        set playerBonus = 20
    endif

	loop
		exitwhen i > 8
		set i2 = -1
		loop
			exitwhen i2 > 1
			set loc2 = PolarProjectionBJ(loc, 150 * i, angle + 40 * i2 )
			call DestroyEffect(AddSpecialEffectLoc("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", loc2))
            if i2 == 0 and playerBonus > 0 then
                call GroupEnumUnitsInRangeEx(pid, g, GetLocationX(loc2), GetLocationY(loc2), 130. + playerBonus, Condition(function FilterEnemy))
                set playerBonus = playerBonus + 40
            else
                call GroupEnumUnitsInRangeEx(pid, g, GetLocationX(loc2), GetLocationY(loc2), 130., Condition(function FilterEnemy))
            endif
			call RemoveLocation(loc2)
			set i2 = i2 + 1
		endloop
		set i = i + 1
	endloop

    loop
        set target = FirstOfGroup(g)
        exitwhen target == null
        call GroupRemoveUnit(g, target)
        call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop

    if pid == bossid then
        call TriggerSleepAction(0.27)
        call ResetAza()
    endif

	call RemoveLocation(loc)

    set loc = null
    set loc2 = null
	set g = null
endfunction

function AstralAnnihilation takes nothing returns nothing
    local integer i
    local integer i2
    local real angle
    local real x
    local real y
    local group g
    local real dmg = 2000000.
    local location loc = GetUnitLoc(ChaosBoss[BOSS_AZAZOTH])
    local unit target

	set udg_Azazoth_Casting_Spell=true
	call PauseUnit(ChaosBoss[BOSS_AZAZOTH],true)
	call DoFloatingTextUnit("Astral Annihilation" , ChaosBoss[BOSS_AZAZOTH], 2, 70, 0, 11, 100, 40, 40, 0)
	call SetUnitAnimation(ChaosBoss[BOSS_AZAZOTH], "spell slam")
	call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", ChaosBoss[BOSS_AZAZOTH], "origin"))
	call TriggerSleepAction(0.60)
	call SetUnitAnimation(ChaosBoss[BOSS_AZAZOTH], "spell slam")
	call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", ChaosBoss[BOSS_AZAZOTH], "origin"))
	call TriggerSleepAction(0.60)
	call SetUnitAnimation(ChaosBoss[BOSS_AZAZOTH], "spell slam")
	call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", ChaosBoss[BOSS_AZAZOTH], "origin"))
	call TriggerSleepAction(0.60)
	call SetUnitAnimation(ChaosBoss[BOSS_AZAZOTH], "spell slam")
	call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", ChaosBoss[BOSS_AZAZOTH], "origin"))
	call TriggerSleepAction(0.60)
	set x = GetUnitX(ChaosBoss[BOSS_AZAZOTH])
	set y = GetUnitY(ChaosBoss[BOSS_AZAZOTH])
	set loc = Location(x, y)
	set i2=1
	loop
		exitwhen i2>9
		set i=0
		loop
			exitwhen i>11
			set angle=2 * bj_PI * i / 12.
			call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", x+100*i2*Cos(angle), y+100*i2*Sin(angle) ))
			set i=i+1
		endloop
		set i2=i2+1
	endloop
	
	set g=GetUnitsInRangeOfLocMatching(900, loc, Condition(function ishostileEnemy))
	loop
		set target=FirstOfGroup(g)
		exitwhen target== null
		call GroupRemoveUnit(g, target)
		call UnitDamageTarget(ChaosBoss[BOSS_AZAZOTH], target, HMscale(dmg), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		set target=null
	endloop
	call DestroyGroup(g)
	set g=null
	call TriggerSleepAction(0.27)
	call RemoveLocation(loc)
	call ResetAza()
    set loc = null
endfunction

function ArcaneRadiance takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
	local real boost = BOOST(pid)
	local real dmg = (GetHeroStr(Hero[pid], true) + GetHeroInt(Hero[pid], true)) * boost
	local group ug = CreateGroup()
	local unit target

    set pt.dur = pt.dur - 1
	
	call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 750 * boost, Condition(function FilterAlive))
	
	loop
		set target = FirstOfGroup(ug)
		exitwhen target == null
		call GroupRemoveUnit(ug, target)
		if IsUnitEnemy(target, Player(pid - 1)) and IsUnitType(target,UNIT_TYPE_DEAD) == false then
			call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", GetUnitX(target), GetUnitY(target) ))
			call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		elseif GetUnitTypeId(target) != BACKPACK and GetPlayerId(GetOwningPlayer(target)) < 9 and GetUnitAbilityLevel(target, 'Aloc') == 0 and IsUnitType(target,UNIT_TYPE_DEAD) == false then
			call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", GetUnitX(target), GetUnitY(target) ))
            call HP(target, dmg)
		endif
	endloop
	
	if pt.dur - 1 <= 0 then
        call TimerList[pid].removePlayerTimer(pt)
	endif
	
	call DestroyGroup(ug)
	
	set ug = null
	set target = null
endfunction

function BloodCurdlingScreamExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer armorloss = LoadInteger(ScreamTargets, 0, GetHandleId(t))
    local integer currentarmor = LoadInteger(ScreamTargets, 1, GetHandleId(t))
    local unit u = LoadUnitHandle(ScreamTargets, 2, GetHandleId(t))
    local integer ablev = LoadInteger(ScreamTargets, 3, GetHandleId(t))
    
	call SetTimerData(t, GetTimerData(t) + 1)
    
	if GetTimerData(t) > 35 then
        call BlzSetUnitArmor(u, BlzGetUnitArmor(u) + armorloss)
        call RemoveSavedInteger(ScreamTargets, 0, GetHandleId(t))
        call RemoveSavedInteger(ScreamTargets, 1, GetHandleId(t))
        call RemoveSavedHandle(ScreamTargets, 2, GetHandleId(t))
		call ReleaseTimer(t)
        call UnitRemoveAbility(u, 'A0F1')
        call UnitRemoveAbility(u, 'B01B')
	else
        if R2I(BlzGetUnitArmor(u)) != currentarmor then
            call BlzSetUnitArmor(u, BlzGetUnitArmor(u) + armorloss)
            set armorloss = IMaxBJ(0, R2I(BlzGetUnitArmor(u) * (0.12 + 0.02 * ablev)))
            call SaveInteger(ScreamTargets, 0, GetHandleId(t), armorloss)
            call BlzSetUnitArmor(u, BlzGetUnitArmor(u) - armorloss)
            set currentarmor = R2I(BlzGetUnitArmor(u))
            call SaveInteger(ScreamTargets, 1, GetHandleId(t), currentarmor)
        endif
    endif
    
	set t = null
	set u = null
endfunction

function WhirlStrikes takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real aoe = (240 + 40 * GetUnitAbilityLevel(Hero[pid], 'A0FP')) * LBOOST(pid)
    local real dmg = (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid],true)) * (GetUnitAbilityLevel(Hero[pid],'A0FP') + 1) * BOOST(pid) * 0.06
    local group ug
    local unit target

    set pt.dur = pt.dur - 1

	if GetWidgetLife(Hero[pid]) >= .406 and pt.dur > 1 then
		set ug = CreateGroup()
		call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), aoe, Condition(function FilterEnemy))
		loop
			set target = FirstOfGroup(ug)
			exitwhen target == null
			call GroupRemoveUnit(ug, target)
			call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "origin")) 
			call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		endloop
		call DestroyGroup(ug)
	else
        call TimerList[pid].removePlayerTimer(pt)
	endif

	set ug = null
endfunction

function MassTeleportFinish takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    set isteleporting[pid] = false
    call BlzPauseUnitEx(Backpack[pid], false)

    if GetWidgetLife(Hero[pid]) >= 0.406 and getRect(GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) == getRect(pt.x, pt.y) then
        call SetUnitPosition(Hero[pid], pt.x, pt.y)
        call SetUnitPosition(Backpack[pid], pt.x, pt.y)
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportTarget.mdl", GetUnitX(Hero[pid]), GetUnitY(Hero[pid])))
    endif
    
    call TimerList[pid].removePlayerTimer(pt)
endfunction

function MassTeleport takes integer pid, unit u, integer ablev, real dur returns nothing
    local PlayerTimer pt = TimerList[pid].addTimer(pid)
    
    set isteleporting[pid] = true
    call BlzPauseUnitEx(Backpack[pid], true)
    //call DummyCastTarget(p, u, 'A01R', ablev, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), "massteleport")
    call DestroyEffectTimed(AddSpecialEffect("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportTo.mdl", GetUnitX(u), GetUnitY(u)), dur)
    call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", Backpack[pid], "origin"))
    set pt.x = GetUnitX(u)
    set pt.y = GetUnitY(u)
    call TimerStart(pt.getTimer(), dur, false, function MassTeleportFinish)
endfunction

function TeleportHomeFinish takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    call UnitRemoveAbility(Hero[pid],'A050')
	call PauseUnit(Hero[pid],false)
    call PauseUnit(Backpack[pid],false)
	
	if GetWidgetLife(Hero[pid]) >= 0.406 then
        call SetUnitPositionLoc(Hero[pid], TownCenter)
        call SetCameraBoundsRectForPlayerEx(Player(pid - 1), gg_rct_Main_Map)
        call PanCameraToTimedLocForPlayer(Player(pid - 1), TownCenter, 0)
        call EnterWeather(Hero[pid])
	endif

	set isteleporting[pid] = false
endfunction

function TeleportHome takes player p, integer dur returns nothing
	local integer pid = GetPlayerId(p) + 1
    local effect e = AddSpecialEffect("war3mapImported\\Progressbar.mdl", GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 100.0)
	
	set isteleporting[pid] = true
	
    call PauseUnit(Backpack[pid],true)
	call PauseUnit(Hero[pid],true)
	call UnitAddAbility(Hero[pid],'A050')
    call BlzUnitHideAbility(Hero[pid], 'A050', true)
    
    call BlzSetSpecialEffectHeight(e, 200.0)
    if dur > 10 then
        call BlzSetSpecialEffectTimeScale(e, 0.09)
    else
        call BlzSetSpecialEffectTimeScale(e, 0.03 + (1. / dur))
    endif
    call BlzSetSpecialEffectColorByPlayer(e, Player(4))
    call DestroyEffectTimed(e, dur)
    
    call TimerStart(NewTimerEx(pid), dur, false, function TeleportHomeFinish)
    
    set e = null
endfunction

function BossBlastTaper takes unit boss, integer baseDamage, integer effectability, real AOE returns nothing
local real castx
local real casty
local real dx
local real dy
local group g
local unit target
local real angle
local real distance
local integer i=1
	call PauseUnit(boss,true)
	call TriggerSleepAction(2)
	if GetWidgetLife(boss)<1 then
		return
	endif
	set castx=GetUnitX(boss)
	set casty=GetUnitY(boss)
	set g= CreateGroup()
	loop
		exitwhen i > 18
		set angle= bj_PI *i /9.
        set target = GetDummy(castx, casty, effectability, 1, DUMMY_RECYCLE_TIME)
        call SetUnitFlyHeight(target, 150., 0)
        call IssuePointOrder(target, "breathoffire", castx + 40 * Cos(angle), casty + 40 * Sin(angle))
		set i = i + 1
	endloop
	call GroupEnumUnitsInRange(g, castx, casty, AOE, Condition(function ishostileEnemy))
	set baseDamage= HMscale(baseDamage)
	loop
		set target=FirstOfGroup(g)
		exitwhen target == null
		call GroupRemoveUnit(g, target)
		//call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
		set dx= GetUnitX(target) -castx
		set dy= GetUnitY(target) -casty
		set distance= SquareRoot( dx*dx +dy*dy )
		if distance<150 then
			call UnitDamageTarget(boss,target, baseDamage, true, false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
		else
			call UnitDamageTarget(boss,target, baseDamage /(distance/200.), true, false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
		endif
		set target=null
	endloop
	call DestroyGroup(g)
	call PauseUnit(boss,false)
endfunction

function addtotg takes nothing returns nothing
	if IsUnitInGroup(GetEnumUnit(),tg)==false then
		call GroupAddUnit(tg,GetEnumUnit())
	endif
endfunction

function BossLineSpell takes unit boss, unit Starget, integer baseDamage, integer hgroup, string speffect returns nothing
local real castx=GetUnitX(boss)
local real casty=GetUnitY(boss)
local real TX=GetUnitX(Starget)
local real TY=GetUnitY(Starget)
local real dx
local real dy
local integer i=1
local group g
local unit target
local real angle= Atan2( TY-casty, TX-castx )
	call DestroyEffect(AddSpecialEffect(speffect, TX, TY) )
	call BlzSetUnitFacingEx(boss,angle)
	call PauseUnit(boss, true)
	call TriggerSleepAction(1.5)
	if GetWidgetLife(boss)<1 then
		return
	endif
	set castx=GetUnitX(boss)
	set casty=GetUnitY(boss)
	set angle= Atan2( TY-casty, TX-castx )
	set tg=CreateGroup()
	loop
		exitwhen i > 8
		set TX=castx +Cos(angle)*i*90
		set TY=casty+Sin(angle)*i*90
		call DestroyEffect(AddSpecialEffect(speffect,TX,TY) )
		set g= CreateGroup()
		call GroupEnumUnitsInRange(g, TX, TY, 200, Condition(function ishostileEnemy))
		call ForGroup(g,function addtotg)
		call DestroyGroup(g)
		set i = i + 1
	endloop
	set baseDamage= HMscale(baseDamage)
	loop
		set target=FirstOfGroup(tg)
		exitwhen target == null
		call GroupRemoveUnit(tg, target)
		call UnitDamageTarget(boss, target, baseDamage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		set target=null
	endloop
	call DestroyGroup(tg)
	set g= null
endfunction

function BossPlusSpell takes unit boss, integer baseDamage, integer hgroup, string speffect returns nothing
local real castx=GetUnitX(boss)
local real casty=GetUnitY(boss)
local real dx
local real dy
local integer i= -8
local group g= CreateGroup()
local unit target
	loop
		exitwhen i > 8
		call DestroyEffect(AddSpecialEffect(speffect, castx +80*i, casty-75) )
		call DestroyEffect(AddSpecialEffect(speffect, castx +80*i, casty+75) )
		call DestroyEffect(AddSpecialEffect(speffect, castx-75, casty +80*i) )
		call DestroyEffect(AddSpecialEffect(speffect, castx+75, casty +80*i) )
		set i = i + 1
	endloop
	call GroupEnumUnitsInRange(g, castx, casty, 750, Condition(function ishostileEnemy))
	set baseDamage= HMscale(baseDamage)
	loop
		set target=FirstOfGroup(g)
		exitwhen target == null
		call GroupRemoveUnit(g, target)
		//call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
		set dx=RAbsBJ(GetUnitX(target)- castx)
		set dy=RAbsBJ(GetUnitY(target)- casty)
		if dx<150 and dy<700 then
			call UnitDamageTarget(boss, target, baseDamage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		elseif dx<700 and dy<150 then
			call UnitDamageTarget(boss, target, baseDamage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		endif
		set target=null
	endloop
	call DestroyGroup(g)
	set g= null
endfunction

function BossXSpell takes unit boss, integer baseDamage, integer hgroup, string speffect returns nothing
local real castx=GetUnitX(boss)
local real casty=GetUnitY(boss)
local real dx
local real dy
local integer i= -8
local group g= CreateGroup()
local unit target
	loop
		exitwhen i > 8
			call DestroyEffect(AddSpecialEffect(speffect, castx +75*i, casty +75*i) )
			call DestroyEffect(AddSpecialEffect(speffect, castx +75*i, casty -75*i) )
		set i = i + 1
	endloop
	call GroupEnumUnitsInRange(g, castx, casty, 750, Condition(function ishostileEnemy))
	set baseDamage= HMscale(baseDamage)
	loop
		set target=FirstOfGroup(g)
		exitwhen target == null
		call GroupRemoveUnit(g, target)
		set dx=RAbsBJ(GetUnitX(target)- castx)
		set dy=RAbsBJ(GetUnitY(target)- casty)
		if RAbsBJ(dx -dy) <200 then
			call UnitDamageTarget(boss, target, baseDamage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		endif
		set target=null
	endloop
	call DestroyGroup(g)
	set g= null
endfunction

function BossInnerRing takes unit boss, integer baseDamage, integer hgroup, real AOE, string speffect returns nothing
local real castx
local real casty
local group g
local unit target
local real angle
local integer i=0
	call PauseUnit(boss, true)
	call TriggerSleepAction(1.5)
	if GetWidgetLife(boss)<1 then
		return
	endif
	set castx=GetUnitX(boss)
	set casty=GetUnitY(boss)
	set g= CreateGroup()
	loop
		exitwhen i > 6
		set angle= bj_PI *i /3.
		call DestroyEffect(AddSpecialEffect(speffect, castx +AOE*.4*Cos(angle), casty +AOE*.4*Sin(angle) ) )
		call DestroyEffect(AddSpecialEffect(speffect, castx +AOE*.8*Cos(angle), casty +AOE*.8*Sin(angle) ) )
		set i = i + 1
	endloop
	call GroupEnumUnitsInRange(g, castx, casty, AOE, Condition(function ishostileEnemy))
	set baseDamage= HMscale(baseDamage)
	loop
		set target=FirstOfGroup(g)
		exitwhen target == null
		call GroupRemoveUnit(g, target)
		//call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
		call UnitDamageTarget(boss,target, baseDamage, true, false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
		set target=null
	endloop
	call DestroyGroup(g)
	call PauseUnit(boss, false)
endfunction

function BossOuterRing takes unit boss, integer baseDamage, integer hgroup, real innerRadius, real outerRadius, string speffect returns nothing
local real castx
local real casty
local real dx
local real dy
local group g
local unit target
local real angle
local real distance=outerRadius-innerRadius
local integer i=0
	call PauseUnit(boss, true)
	call TriggerSleepAction(1.5)
	if GetWidgetLife(boss)<1 then
		return
	endif
	set castx=GetUnitX(boss)
	set casty=GetUnitY(boss)
	set g= CreateGroup()
	loop
		exitwhen i > 10
		set angle= bj_PI *i /5.
		call DestroyEffect(AddSpecialEffect(speffect, castx +(innerRadius+distance/6)*Cos(angle), casty +(innerRadius+distance/6)*Sin(angle) ) )
		call DestroyEffect(AddSpecialEffect(speffect, castx +(outerRadius-distance/6)*Cos(angle), casty +(outerRadius-distance/6)*Sin(angle) ) )
		set i = i + 1
	endloop
	call GroupEnumUnitsInRange(g, castx, casty, outerRadius, Condition(function ishostileEnemy))
	set baseDamage= HMscale(baseDamage)
	loop
		set target=FirstOfGroup(g)
		exitwhen target == null
		call GroupRemoveUnit(g, target)
		set dx= GetUnitX(target) -castx
		set dy= GetUnitY(target) -casty
		set distance= SquareRoot( dx*dx +dy*dy )
		if distance>innerRadius then
			call UnitDamageTarget(boss,target, baseDamage, true, false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
		endif
		set target=null
	endloop
	call DestroyGroup(g)
	call PauseUnit(boss, false)
endfunction

function VotekickPanelClick takes nothing returns nothing
    local button b = GetClickedButton()
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p) + 1
    local integer i = 0
    local integer clickedbutton = 0
    local boolean isbutton = false
    local integer id
    
    loop
        exitwhen i > 6
        if b == votekickpanelbutton[pid * 8 + i] then
            set clickedbutton = i
            set isbutton = true
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    if isbutton and VOTING_TYPE == 0 then
        set votekickPlayer = clickedbutton
        set votekickingPlayer = pid
        call Votekick()
    endif

    set b = null
    set p = null
endfunction

function HeroPanelClick takes nothing returns nothing
    local button b = GetClickedButton()
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p) + 1
    local integer i = 0
    local integer clickedbutton = 0
    local boolean isbutton = false
    local integer id
    
    loop
        exitwhen i > 8
        if b == heropanelbutton[pid * 8 + i] then
            set clickedbutton = i
            set isbutton = true
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    if isbutton then
        if hero_panel_on[pid * 8 + clickedbutton] == false then
            set hero_panel_on[pid * 8 + clickedbutton] = true
            call ShowHeroPanel(p, Player(clickedbutton), true)
        else
            set hero_panel_on[pid * 8 + clickedbutton] = false
            call ShowHeroPanel(p, Player(clickedbutton), false)
        endif
    endif

    set b = null
    set p = null
endfunction

function SkinButtonClick takes nothing returns nothing
	local button b = GetClickedButton()
	local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
	local integer i = 0
	local integer numshown = 0
	
	loop
		exitwhen i > TotalSkins or b == dSkin[TotalSkins * pid + i]
		set i = i + 1
	endloop
	
	if b == dSkin[5000 + pid] then
		if dPage[pid] >= TotalSkins then
			set dPage[pid] = 1
		endif
		
		call DialogClear(dChangeSkin[pid])
		
		set i = dPage[pid]

		loop
			exitwhen numshown >= SkinsPerPage or i > TotalSkins
		
			if not ispublic[i] then
				set dPage[pid] = dPage[pid] + 1
			endif
			
			if dPage[pid] == i then
				set dSkin[TotalSkins * pid + i] = DialogAddButton(dChangeSkin[pid], dSkinName[i], 0)
				set dPage[pid] = dPage[pid] + 1
				set numshown = numshown + 1
			endif
			
			set i = i + 1
		endloop

		set dSkin[5000 + pid] = DialogAddButton(dChangeSkin[pid], "Next Page", 0)
		
		call DialogAddButton(dChangeSkin[pid], "Cancel", 0)
		call DialogSetMessage(dChangeSkin[pid], "Select Appearance")
		call DialogDisplay(GetTriggerPlayer(), dChangeSkin[pid], true) 
		return
	endif
	
	if i <= TotalSkins then
        call BlzSetUnitSkin(Backpack[pid], skinID[i])
        if skinID[i] == 'H02O' then
            call AddUnitAnimationProperties(Backpack[pid], "alternate", true)
        endif
	endif
	
	call DialogClear(dChangeSkin[pid])
	
	set b = null
endfunction

function ChangeSkin takes player p returns nothing
	local integer pid = GetPlayerId(p) + 1
	local integer i = 0
	local integer numshown = 0
	
	set dPage[pid] = 0
	
	loop
		exitwhen numshown >= SkinsPerPage or i > TotalSkins
		
		if not ispublic[i] then
			set dPage[pid] = dPage[pid] + 1
			if IsDonatorOrPrestige(pid, i) then
				set dSkin[TotalSkins * pid + i] = DialogAddButton(dChangeSkin[pid], dSkinName[i], 0)
				set numshown = numshown + 1
			endif
		endif
			
		if not IsDonatorOrPrestige(pid, i) and dPage[pid] == i then
			set dSkin[TotalSkins * pid + i] = DialogAddButton(dChangeSkin[pid], dSkinName[i], 0)
			set dPage[pid] = dPage[pid] + 1
			set numshown = numshown + 1
		endif
			
		set i = i + 1
	endloop
	
	if TotalSkins > i and numshown == SkinsPerPage then
		set dSkin[5000 + pid] = DialogAddButton(dChangeSkin[pid], "Next Page", 0)
	endif
	
	call DialogAddButton(dChangeSkin[pid], "Cancel", 0)
	call DialogSetMessage(dChangeSkin[pid], "Select Appearance")
	call DialogDisplay(p, dChangeSkin[pid], true)
endfunction

function CosmeticButtonClick takes nothing returns nothing
	local button b = GetClickedButton()
	local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
	local integer i = 0
	local integer numshown = 0
	
	loop
		exitwhen i > cosmeticTotal or b == dCosmetic[cosmeticTotal * pid + i]
		set i = i + 1
	endloop
	
	if b == dCosmetic[5000 + pid] then
		if dPage[pid] > cosmeticTotal then
			set dPage[pid] = 1
		endif
		
		call DialogClear(dCosmetics[pid])
		
		set i = dPage[pid]

		loop
            exitwhen numshown > SkinsPerPage or i > cosmeticTotal
            
            if IsPlayerInForce(GetTriggerPlayer(), cosmeticGroup[i]) then
                set numshown = numshown + 1
                if numshown < SkinsPerPage + 1 then
                    set dPage[pid] = dPage[pid] + 1
                    set dCosmetic[cosmeticTotal * pid + i] = DialogAddButton(dCosmetics[pid], cosmeticName[i], 0)
                endif
            endif
                
            set i = i + 1
        endloop

		set dCosmetic[5000 + pid] = DialogAddButton(dCosmetics[pid], "Next Page", 0)
		
		call DialogAddButton(dCosmetics[pid], "Cancel", 0)
		call DialogDisplay(GetTriggerPlayer(), dCosmetics[pid], true) 
		return
	endif
	
	if i <= cosmeticTotal then
        call DoSpecialEffect(pid, i)
	endif
	
	call DialogClear(dCosmetics[pid])
	
	set b = null
endfunction

function SpecialEffects takes player p returns nothing
    local integer pid = GetPlayerId(p) + 1
	local integer i = 0
	local integer numshown = 0

	set dPage[pid] = 0
	
	loop
		exitwhen numshown > SkinsPerPage or i > cosmeticTotal
		
		if IsPlayerInForce(p, cosmeticGroup[i]) then
            set numshown = numshown + 1
            if numshown < SkinsPerPage + 1 then
                set dPage[pid] = dPage[pid] + 1
                set dCosmetic[cosmeticTotal * pid + i] = DialogAddButton(dCosmetics[pid], cosmeticName[i], 0)
            endif
		endif
			
		set i = i + 1
	endloop
	
	if numshown > SkinsPerPage then
		set dCosmetic[5000 + pid] = DialogAddButton(dCosmetics[pid], "Next Page", 0)
	endif
	
	call DialogAddButton(dCosmetics[pid], "Cancel", 0)
	call DialogDisplay(p, dCosmetics[pid], true)
endfunction

function Trig_Devastation_nodouble takes nothing returns nothing
	if IsUnitInGroup(GetEnumUnit(),tg)==false then
		call GroupAddUnit(tg,GetEnumUnit())
	endif
endfunction

function Triage_Heal takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local real heal = (GetHeroInt(Hero[pid],true) * .4 + 40) * BOOST(pid)
    local group ug = CreateGroup()
    local unit target
    local unit ftarget
    local real percent = 100.

    call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 850 * BOOST(pid), Condition(function FilterAllyHero))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if percent > GetUnitLifePercent(target) then
            set percent = GetUnitLifePercent(target)
            set ftarget = target
        endif
    endloop

    if GetUnitCurrentOrder(Hero[pid])==OrderId("clusterrockets") and GetWidgetLife(Hero[pid]) >= .406 and GetUnitState(Hero[pid], UNIT_STATE_MANA) >= GetUnitState(Hero[pid],UNIT_STATE_MAX_MANA) * .02 then
        if GetWidgetLife(ftarget) < BlzGetUnitMaxHP(ftarget) then
            call DoFloatingTextUnit(RealToString(heal), ftarget , 1 , 60 , 0 , 10 , 50 , 100 , 50 , 0)
            call SetWidgetLife(ftarget, GetWidgetLife(ftarget) + heal)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", ftarget, "origin"))
            call SetUnitState(Hero[pid], UNIT_STATE_MANA, GetUnitState(Hero[pid], UNIT_STATE_MANA) - GetUnitState(Hero[pid], UNIT_STATE_MAX_MANA) * .02)
        endif
    else
        call IssueImmediateOrder(Hero[pid], "stop")
        call ReleaseTimer(t)
    endif
    
    call DestroyGroup(ug)
    
    set t = null
    set ug = null
    set target = null
    set ftarget = null
endfunction

function ClearNerveTargets takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local unit target

    loop
        set target = FirstOfGroup(nervetargets[pid])
        exitwhen target == null
        call GroupRemoveUnit(nervetargets[pid], target)
        call UnitRemoveAbility(target, 'A0T5')
        call UnitRemoveAbility(target, 'A0T1')
    endloop

    call DestroyGroup(nervetargets[pid])
endfunction

function NerveGas takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real dmg = NerveGasFormula(pid) * BOOST(pid)
    local unit target
    local integer count = BlzGroupGetSize(nervetargets[pid])
    local integer index = 0
    
    set pt.dur = pt.dur - 1
	
	if pt.dur < 1 then
        call TimerList[pid].removePlayerTimer(pt)
	else
        if count > 0 then
            loop
                set target = BlzGroupUnitAt(nervetargets[pid], index)
                if IsUnitType(target, UNIT_TYPE_DEAD) == false and GetUnitAbilityLevel(target, 'Avul') == 0 then
                    call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                endif
                set index = index + 1
                exitwhen index >= count
            endloop
        endif
	endif
	
	set target = null
endfunction

function OnCast takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    local integer sid = GetSpellAbilityId()
    local player p = GetOwningPlayer(caster)
    local integer pid = GetPlayerId(p) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(target)) + 1
    local real x = GetUnitX(caster)
    local real y = GetUnitY(caster)
    local integer ablev = GetUnitAbilityLevel(caster, sid)
    local real dur = 0
    
    if caster == Hero[pid] then
        set Moving[pid] = false
    endif

	if sid == 'AImt' or sid == 'A02J' or sid == 'A018' then //Global Blink / Backpack Teleport
        if GetWidgetLife(Hero[pid]) < 0.406 then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport while dead.")
        elseif sid == 'A018' and udg_Chaos_World_On then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTimedTextToPlayer(p, 0, 0, 20.00, "With the Gods dead, these items no longer have the ability to move around the map with free will. Their powers are dead, however their innate fighting powers are left unscathed." )
        elseif getRect(x, y) != gg_rct_Main_Map then
            call IssueImmediateOrder(caster, "stop")
			call DisplayTimedTextToPlayer(p, 0, 0, 5., "Unable to teleport there.")
        elseif getRect(x, y) != getRect(GetSpellTargetX(), GetSpellTargetY()) then
			call IssueImmediateOrder(caster, "stop")
			call DisplayTimedTextToPlayer(p, 0, 0, 5., "Unable to teleport there.")
        elseif IsPlayerInForce(p, QUEUE_GROUP) then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport while queueing for a dungeon.")
        elseif IsPlayerInForce(p, NAGA_GROUP) then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport while in a dungeon.")
		endif
    elseif sid == 'A01S' or sid == 'A0AC' or sid == 'A03D' or sid == 'A061' then //Short blink
        if getRect(x, y) != getRect(GetSpellTargetX(), GetSpellTargetY()) then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport there.")
        endif

    elseif sid == 'A0FV' then //Teleport Home
        if GetWidgetLife(Hero[pid]) < 0.406 then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport while dead.")
        elseif IsPlayerInForce(p, QUEUE_GROUP) then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport while queueing for a dungeon.")
        elseif IsPlayerInForce(p, NAGA_GROUP) then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport while in a dungeon.")
        elseif GodsParticipant[pid] then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport out of here.")
        elseif getRect(x, y) == gg_rct_Main_Map or getRect(x, y) == gg_rct_Cave or getRect(x, y) == gg_rct_Gods_Vision or getRect(x, y) == gg_rct_Tavern or getRect(x, y) == gg_rct_Church then
        else
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport out of here.")
        endif
	elseif sid == 'A048' then //Resurrection
        call IssueImmediateOrder(caster, "stop")
        if target != HeroGrave[tpid] then
            call DisplayTextToPlayer(p, 0, 0, "You must target a tombstone!")
        elseif GetUnitAbilityLevel(HeroGrave[tpid], 'A045') == 0 then
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(HeroGrave[tpid]), GetUnitY(HeroGrave[tpid])))
            set ResurrectionRevival[tpid] = pid
            set ResurrectionCD[pid] = 15
            call UnitDisableAbility(Hero[pid], sid, true)
            call BlzUnitHideAbility(Hero[pid], sid, false)
            call UnitAddAbility(HeroGrave[tpid], 'A045')
            
            call BlzSetSpecialEffectScale(HeroReviveIndicator[tpid], dur)
            call DestroyEffect(HeroReviveIndicator[tpid])
            set HeroReviveIndicator[tpid] = AddSpecialEffect("UI\\Feedback\\Target\\Target.mdx", GetUnitX(HeroGrave[tpid]), GetUnitY(HeroGrave[tpid]))
                
            if GetLocalPlayer() == Player(tpid - 1) then
                set dur = 15
            endif
                
            call BlzSetSpecialEffectTimeScale(HeroReviveIndicator[tpid], 0)
            call BlzSetSpecialEffectScale(HeroReviveIndicator[tpid], dur)
            call BlzSetSpecialEffectZ(HeroReviveIndicator[tpid], BlzGetLocalSpecialEffectZ(HeroReviveIndicator[tpid]) - 100)
            call DestroyEffectTimed(HeroReviveIndicator[tpid], 12.8)
        else
            call DisplayTextToPlayer(p, 0, 0, "This player is already being revived!")
		endif
    elseif sid == 'A07X' then //Arcane Might
        if GetUnitAbilityLevel(target, 'B0AM') > 0 or IAbsBJ(GetHeroLevel(caster) - GetHeroLevel(target)) > 70 then
            call IssueImmediateOrder(caster, "stop")
        endif
    elseif sid == 'A08X' then //Arcane Comets
        if not IsUnitInRangeXY(arcanosphere[pid], MouseX[pid], MouseY[pid], 800.) then //outside arcanosphere
            call IssueImmediateOrder(caster, "stop")
        endif
    elseif sid == 'A09A' then //Blood Nova
        if BloodBank[pid] < 40 * GetHeroInt(caster, true) then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Not enough blood.")
        endif
    endif
	
	set caster = null
    set target = null
	set p = null
endfunction

function OnLearn takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer sid = GetLearnedSkill()
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1

    if sid == 'A032' then //Armor of the Elements
        call UnitAddAbility(u, 'A033')
        call BlzUnitHideAbility(u, 'A033', true)
        set aoteCD[pid] = true
    endif

    set u = null
endfunction

function OnFinish takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer sid = GetSpellAbilityId()
    local player p = GetOwningPlayer(caster)
    local integer ablev = GetUnitAbilityLevel(caster, sid)

	if sid == 'A0FV' then //Teleport Town
        if ablev > 1 then
            call TeleportHome(p, 11 - ablev)
        else
            call TeleportHome(p, 12)
        endif
    endif
	
	set caster = null
	set p = null
endfunction

function EnemySpells takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer sid = GetSpellAbilityId()
    local integer pid
    local timer t
    local integer i = 0
    local unit u
    local User U
    local integer rand = GetRandomInt(0, 359)
    local group ug = CreateGroup()
    local unit target
    
    if sid == 'A04K' then //naga dungeon thorns
        call DoFloatingTextUnit("Thorns", caster, 2, 50, 0, 13.5, 255, 255, 125, 0)
        set t = NewTimer()
        call SaveUnitHandle(MiscHash, GetHandleId(t), 0, caster)
        call TimerStart(t, 2., false, function ApplyNagaThorns)
        call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Orc\\SpikeBarrier\\SpikeBarrier.mdl", caster, "origin"), 8.5)
    elseif sid == 'A04R' then //naga dungeon swarm
        call DoFloatingTextUnit("Swarm", caster, 2, 50, 0, 13.5, 155, 255, 255, 0)
        call GroupEnumUnitsInRange(ug, GetUnitX(caster), GetUnitY(caster), 1250., Condition(function isplayerunit))
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            if GetRandomReal(0, 1.) <= 0.75 then
                call GroupRemoveUnit(ug, target)
            endif
            set u = CreateUnit(GetOwningPlayer(caster), 'u002', GetUnitX(caster) + GetRandomInt(125, 250) * Cos(bj_DEGTORAD * (rand + i * 30)), GetUnitY(caster) + GetRandomInt(125, 250) * Sin(bj_DEGTORAD * (rand + i * 30)), 0)
            call BlzSetUnitFacingEx(u, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(u), GetUnitX(target) - GetUnitX(u)))
            call PauseUnit(u, true)
            call UnitAddAbility(u, 'Avul')
            call SetUnitAnimation(u, "birth")
            set t = NewTimer()
            call SaveUnitHandle(MiscHash, GetHandleId(t), 0, u)
            call SaveUnitHandle(MiscHash, GetHandleId(t), 1, target)
            call TimerStart(t, GetRandomReal(0.75, 1), false, function SwarmBeetle)
            set i = i + 1
        endloop
    elseif sid == 'A04V' then //naga atk speed
        call DoFloatingTextUnit("Enrage", caster, 2, 50, 0, 13.5, 255, 255, 125, 0)
        set t = NewTimer()
        call SaveUnitHandle(MiscHash, GetHandleId(t), 0, caster)
        call TimerStart(t, 2., false, function ApplyNagaAtkSpeed)
    elseif sid == 'A04W' then //naga massive aoe
        call DoFloatingTextUnit("Miasma", caster, 2, 50, 0, 13.5, 255, 255, 125, 0)
        call SetUnitAnimation(caster, "channel")
        set t = NewTimer()
        call SaveUnitHandle(MiscHash, GetHandleId(t), 0, caster)
        call TimerStart(t, 2., false, function NagaMiasma)
        set i = 0
        loop
            exitwhen i > 3
            set bj_lastCreatedEffect = AddSpecialEffect("Abilities\\Spells\\Undead\\PlagueCloud\\PlagueCloudCaster.mdl", GetUnitX(caster) + 175 * Cos(bj_PI * i / 2 + (bj_PI / 4.)), GetUnitY(caster) + 175 * Sin(bj_PI * i / 2 + (bj_PI / 4.)))
            call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 2.)
            call DestroyEffectTimed(bj_lastCreatedEffect, 21.)
            set i = i + 1
        endloop
    elseif sid == 'A05C' then //naga wisp thing?
        call DoFloatingTextUnit("Spirit Call", caster, 2, 50, 0, 13.5, 255, 255, 125, 0)
        call SpiritCall()
    elseif sid == 'A05K' then //naga boss rock fall
        call DoFloatingTextUnit("Collapse", caster, 2, 50, 0, 13.5, 255, 255, 125, 0)
        call NagaCollapse()
    endif
    
    set caster = null
    set target = null
    set t = null
    set u = null
endfunction

function OnEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    local player p = GetOwningPlayer(caster)
    local item itm = GetSpellTargetItem()
    local integer itemid = GetItemTypeId(itm)
    local integer sid = GetSpellAbilityId()
    local integer pid = GetPlayerId(p) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(target)) + 1
    local integer ablev = GetUnitAbilityLevel(caster,sid)
    local location loc
    local group ug = CreateGroup()
    local integer array locint
    local integer i = 0
    local integer i2 =0
    local real x = GetUnitX(caster)
    local real y = GetUnitY(caster)
    local real boost = BOOST(pid)
    local real dmg
    local real heal
    local real armor
    local real angle
    local real AOE
    local real dur
    local real loopr
    local effect speffect
    local group g
    local unit u
    local unit dummy
    local timer t
    local lightning array ray
    local User U
    local PlayerTimer pt

	if GetSpellTargetX() != 0 and GetSpellTargetY() != 0 then
		set loc = GetSpellTargetLoc()
	elseif GetSpellTargetUnit()!=null then
		set loc = GetUnitLoc(target)
	else
		set loc = GetUnitLoc(caster)
	endif
    
	//========================
	//Actions
	//========================

	if sid == 'A03V' then //Move Item (Hero)
		call UnitRemoveItem(caster, itm)
		call UnitAddItem(Backpack[pid], itm)
	elseif sid == 'A0DT' then //Move Item (Backpack)
		call UnitRemoveItem(caster, itm)
		call UnitAddItem(Hero[pid], itm)
	elseif sid == 'A06X' then //Quest Progress
		call DisplayQuestProgress(p)
	elseif sid == 'A0GD' then //Item Info
        call DisplayTimedTextToPlayer(p,0,0, 15., GetObjectName(itemid))
        call DisplayTimedTextToPlayer(p,0,0, 15., "-----------------------------------------")
		if ItemProfMod(itemid,pid) < 1 then
			call DisplayTimedTextToPlayer(p,0,0, 15., "|cffffcc00Proficiency: " + RealToString(ItemProfMod(itemid,pid)*100)+"%" )
		endif
		if ItemData[itemid][StringHash("health")] != 0 then
			call DisplayTimedTextToPlayer(p,0,0, 15., "|cffffffffHealth: " + RealToString(ItemData[itemid][StringHash("health")]))
		endif
		if ItemData[itemid][StringHash("armor")] != 0 then
			call DisplayTimedTextToPlayer(p,0,0, 15., "|cffa4a4feArmor: " + RealToString(ItemData[itemid][StringHash("armor")]))
		endif
		if ItemData[itemid][StringHash("damage")] != 0 then
			call DisplayTimedTextToPlayer(p,0,0, 15., "|cffff6600Damage: " + RealToString(ItemData[itemid][StringHash("damage")]) )
		endif
		if ItemData[itemid][StringHash("str")] + ItemData[itemid][StringHash("stats")] != 0 then
			call DisplayTimedTextToPlayer(p,0,0, 15., "|cff990000Strength: " + RealToString(ItemData[itemid][StringHash("str")] + ItemData[itemid][StringHash("stats")]) )
		endif
		if ItemData[itemid][StringHash("agi")] + ItemData[itemid][StringHash("stats")] != 0 then
			call DisplayTimedTextToPlayer(p,0,0, 15., "|cff006600Agility: " + RealToString(ItemData[itemid][StringHash("agi")] + ItemData[itemid][StringHash("stats")]) )
		endif
		if ItemData[itemid][StringHash("int")] + ItemData[itemid][StringHash("stats")] != 0 then
			call DisplayTimedTextToPlayer(p,0,0, 15., "|cff3333ffIntelligence: " + RealToString(ItemData[itemid][StringHash("int")] + ItemData[itemid][StringHash("stats")]) )
		endif
        if ItemData[itemid][StringHash("mr")] != 0 then
            call DisplayTimedTextToPlayer(p,0,0, 15., "|cff8000ffSpell Resistance: " + RealToString(ItemData[itemid][StringHash("mr")]) + "%" )
        endif
        if ItemData[itemid][StringHash("dr")] != 0 then
            call DisplayTimedTextToPlayer(p,0,0, 15., "|cffff8040Damage Resistance: " + RealToString(ItemData[itemid][StringHash("dr")]) + "%" )
        endif
		if ItemData[itemid][StringHash("regen")] != 0 then
			call DisplayTimedTextToPlayer(p,0,0, 15., "|cff800040Regeneration: " + RealToString(ItemData[itemid][StringHash("regen")]) )
		endif
        if ItemData[itemid][StringHash("evasion")] != 0 then
			call DisplayTimedTextToPlayer(p,0,0, 15., "|cff008080Evasion: " + RealToString(ItemData[itemid][StringHash("evasion")]) + "%" )
		endif
        if ItemData[itemid][StringHash("spellboost")] != 0 then
			call DisplayTimedTextToPlayer(p,0,0, 15., "|cff6666FFSpellboost: " + RealToString(ItemData[itemid][StringHash("spellboost")]) + "%" )
		endif
        if ItemData[itemid][StringHash("movespeed")] != 0 then
			call DisplayTimedTextToPlayer(p,0,0, 15., "Movespeed: " + RealToString(ItemData[itemid][StringHash("movespeed")]))
		endif
                
        set i = 0
                
        loop
            exitwhen i > udg_PermanentInteger[2]
            if UpItem[i] == itemid and UpDiscountItem[i] > 0 then
                call DisplayTimedTextToPlayer(p,0,0, 15., "Discount Item: " + GetObjectName(UpDiscountItem[i]))
                exitwhen true
            endif
            set i = i + 1
        endloop
                
        if ItemToIndex(itemid) > 0 then //item info cannot be cast on backpacked items
            call DisplayTimedTextToPlayer(p,0,0, 15., "|c0000ff33Saveable|r")
        endif

	//========================
	//Item Spells
	//========================
	
	elseif sid == 'A083' then //Paladin Book
		set dmg=  3 *GetHeroInt(caster, true) *boost
        if GetUnitTypeId(target) == BACKPACK then
            call HP(Hero[tpid], dmg)
        else
            call HP(target, dmg)
        endif
	elseif sid == 'A02A' then //Instill Fear
		if udg_HeroCanUseDagger[pid] then
            call DummyCastTarget(p, target, 'A0AE', 1, x, y, "firebolt")
        else
            call DisplayTimedTextToPlayer(p,0,0, 15., "You do not have the proficiency to use this spell!")
		endif
    elseif sid == 'A055' then //Darkest of Darkness
        set DarkestOfDarkness.add(Hero[pid], Hero[pid]).duration = 10.
	elseif sid == 'A0IS' then //Abyssal Bow
		set dmg= (UnitGetBonus(caster,BONUS_DAMAGE) + GetHeroAgi(caster, true)) * 4 *BOOST(pid)
		if udg_HeroCanUseBow[pid]== false then
			set dmg= dmg * 0.5
		endif
		call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
	elseif sid == 'A07G' then //Azazoth Sword (Bladestorm)
		if udg_HeroCanUseShortSword[pid] then
            set pt = TimerList[pid].addTimer(pid)
            set pt.dur = 5.
            call TimerStart(pt.getTimer(), 0.05, true, function AzazothBladeStorm)
        else
            call DisplayTimedTextToPlayer(p,0,0, 15., "You do not have the proficiency to use this spell!")
		endif
	elseif sid == 'A0SX' then //Azazoth Staff
        if udg_HeroCanUseStaff[pid] then
            call AstralDevastation(caster, 0, 40 * GetHeroInt(caster, true) * BOOST(pid), bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x))
        else
            call DisplayTimedTextToPlayer(p,0,0, 15., "You do not have the proficiency to use this spell!")
        endif
	elseif sid == 'A0B5' then //Azazoth Hammer (Stomp)
        if udg_HeroCanUseHeavy[pid] then
            call MakeGroupInRange(pid, ug, x, y, 550.00, Condition(function FilterEnemy))
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call DummyCastTarget(p, target, 'A0B7', 1, x, y, "slow")
                call UnitDamageTarget(caster, target, 15.00 * GetHeroStr(caster, true) * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
            endloop
        else
            call DisplayTimedTextToPlayer(p,0,0, 15., "You do not have the proficiency to use this spell!")
        endif

	elseif sid == 'A0RK' then //final blast
		set i = 1
		call MakeGroupInRange(pid, ug, x, y, 600.00, Condition(function FilterEnemy))
		loop
			exitwhen i > 12
			if i < 7 then
				set x = GetUnitX(caster) + 100 * Cos(60.00 * i * bj_DEGTORAD)
				set y = GetUnitY(caster) + 100 * Sin(60.00 * i * bj_DEGTORAD)
				call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", x, y ))
				set x = GetUnitX(caster) + 200 * Cos(60.00 * i * bj_DEGTORAD)
				set y = GetUnitY(caster) + 200 * Sin(60.00 * i * bj_DEGTORAD)
				call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", x, y ))
			endif
			set x = GetUnitX(caster) + 300 * Cos(30.00 * i * bj_DEGTORAD)
			set y = GetUnitY(caster) + 300 * Sin(30.00 * i * bj_DEGTORAD)
			call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", x, y ))
			set x = GetUnitX(caster) + 400 * Cos(60.00 * i * bj_DEGTORAD)
			set y = GetUnitY(caster) + 400 * Sin(60.00 * i * bj_DEGTORAD)
			call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", x, y ))
			set x = GetUnitX(caster) + 500 * Cos(60.00 * i * bj_DEGTORAD)
			set y = GetUnitY(caster) + 500 * Sin(60.00 * i * bj_DEGTORAD)
			call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", x, y ))
			set x = GetUnitX(caster) + 600 * Cos(60.00 * i * bj_DEGTORAD)
			set y = GetUnitY(caster) + 600 * Sin(60.00 * i * bj_DEGTORAD)
			call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", x, y ))
			set i = i + 1
		endloop
		loop
			set u = FirstOfGroup(ug)
			exitwhen u == null
			call GroupRemoveUnit(ug, u)
			call UnitDamageTarget(caster, u, 15.00 * GetHeroInt(caster, true) * BOOST(pid), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
		endloop
	
	//========================
	//Backpack
	//========================
		
	elseif sid == 'A0L0' then //Hero Info
		call StatsInfo(p, pid)
	elseif sid == 'A0KX' then //Change Skin
		call ChangeSkin(p)
    elseif sid == 'A04N' then //Special Effects
        call SpecialEffects(p)
    elseif sid == 'A02J' then //Mass Teleport
        if ablev > 1 then
            call MassTeleport(pid, target, ablev, 3 - ablev * .25)
        else
            call MassTeleport(pid, target, ablev, 3)
        endif
	elseif sid == 'A00R' then //Next Backpack Page
        if ItemsDisabled[pid] == false then
            loop
                exitwhen i > 5

                set itm = UnitItemInSlot(Backpack[pid], i)
                set Profiles[pid].hd.items[i + 6 + 6 * Profiles[pid].pageIndex] = itm
                if itm != null then
                    call UnitRemoveItem(Backpack[pid], itm)
                    call SetItemPosition(itm, 30000, 30000)
                    call SetItemVisible(itm, false)
                endif
                
                set i = i + 1
            endloop

            set Profiles[pid].pageIndex = Profiles[pid].pageIndex + 1
            if Profiles[pid].pageIndex > 2 then
                set Profiles[pid].pageIndex = 0
            endif

            set i = 0

            loop
                exitwhen i > 5
            
                call UnitAddItem(Backpack[pid], Profiles[pid].hd.items[i + 6 + 6 * Profiles[pid].pageIndex])
                call UnitDropItemSlot(Backpack[pid], Profiles[pid].hd.items[i + 6 + 6 * Profiles[pid].pageIndex], i)
                
                set i = i + 1
            endloop
        endif
	elseif sid == 'A00B' then //Movement Toggle
		call ForceRemovePlayer(rightclicked, p)
		if IsPlayerInForce(p, rightclickactivator) then
            call DisplayTextToPlayer(p, 0, 0, "Movement Toggle disabled.")
			call ForceRemovePlayer(rightclickactivator, p)
		else
            call DisplayTextToPlayer(p, 0, 0, "Movement Toggle enabled.")
			call ForceAddPlayer(rightclickactivator, p)
		endif
    elseif sid == 'A08Y' then //Auto-attack Toggle
        if autoAttackDisabled[pid] then
			set autoAttackDisabled[pid] = false
			call DisplayTimedTextToPlayer(p, 0, 0, 10, "Toggled Auto Attacking on.")
            call BlzSetUnitWeaponBooleanField(Hero[pid], UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
		else
			set autoAttackDisabled[pid] = true
			call DisplayTimedTextToPlayer(p, 0, 0, 10, "Toggled Auto Attacking off.")
            call BlzSetUnitWeaponBooleanField(Hero[pid], UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
		endif

    elseif sid == 'A02T' then //Hero Panels
        set U = User.first
        
        call DialogClear(heropanel[pid])
        
		loop
            exitwhen U == User.NULL
            
            if pid != GetPlayerId(U.toPlayer()) + 1 and HeroID[GetPlayerId(U.toPlayer()) + 1] != 0 then
                set heropanelbutton[pid * 8 + GetPlayerId(U.toPlayer())] = DialogAddButton(heropanel[pid], GetPlayerName(Player(GetPlayerId(U.toPlayer()))), 0)
            endif

            set U = U.next
        endloop
        
        call DialogAddButton(heropanel[pid], "Cancel", 0)
        call DialogDisplay(p, heropanel[pid], true)
        
    elseif sid == 'A031' then //Damage Numbers
        if dmgnumber[pid] then
            set dmgnumber[pid] = false
            call DisplayTextToPlayer(p, 0, 0, "Damage Numbers enabled.")
        else
            set dmgnumber[pid] = true
            call DisplayTextToPlayer(p, 0, 0, "Damage Numbers disabled.")
        endif
        
    elseif sid == 'A067' then //Deselect Backpack
        if BP_DESELECT[pid] then
            set BP_DESELECT[pid] = false
            call DisplayTextToPlayer(p, 0, 0, "Deselect Backpack disabled.")
        else
            set BP_DESELECT[pid] = true
            call DisplayTextToPlayer(p, 0, 0, "Deselect Backpack enabled.")
        endif

	//========================
	//Enemy Spells
	//========================
	
	elseif sid == 'A03T' then //Bryan_Hammer
		call UnitDamageTarget(caster,target,11000,true,false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
		call TriggerSleepAction(0.2)
		call IssueTargetOrder(caster, "attack", target)
	elseif sid == 'A0DF' then //Evil_Laser
		call UnitDamageTarget(caster,target,20100,true,false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
		call UnitDamageTarget(caster,target,90100,true,false,ATTACK_TYPE_CHAOS, DAMAGE_TYPE_NORMAL,WEAPON_TYPE_WHOKNOWS)
		call TriggerSleepAction(0.25)
		call IssueTargetOrder(caster, "attack", target)

	/*/*/*====================
        Arcane Warrior
    ====================*/*/*/
	
	elseif sid == 'A0KD' then //Arcane Strike
		set dmg = ( GetUnitAbilityLevel(caster, sid) * 0.5 ) * ( GetHeroStr(caster, true) + GetHeroInt(caster, true) ) * boost
		
		call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 300. *boost, Condition(function FilterEnemy))
		call DestroyEffect(AddSpecialEffectTarget("origin", target, "Abilities\\Spells\\Items\\AIil\\AIilTarget.mdl"))
		call DestroyEffect(AddSpecialEffectTarget("origin", target, "Abilities\\Spells\\Undead\\OrbOfDeath\\AnnihilationMissile.mdl"))
		call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		loop
			set u = FirstOfGroup(ug)
			exitwhen u == null
            call GroupRemoveUnit(ug, u)
			if u != target then
				call UnitDamageTarget(caster, u, dmg / 4., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
			endif
		endloop
	elseif sid == 'A07X' then //Arcane Might
        if GetUnitAbilityLevel(target, 'B0AM') == 0 and IAbsBJ(GetHeroLevel(caster) - GetHeroLevel(target)) <= 70 then
            set pt = TimerList[tpid].addTimer(tpid)
            set pt.dur = ArcaneMightFormula(pid) * boost //statboost
            set pt.target = target
            call UnitAddBonus(target, BONUS_HERO_STR, R2I(pt.dur))
            if GetUnitTypeId(target) != SUMMON_DESTROYER then
                call UnitAddBonus(target, BONUS_HERO_AGI, R2I(pt.dur))
            endif
            call UnitAddBonus(target, BONUS_HERO_INT, R2I(pt.dur))
            set pt.dmg = (UnitGetBonus(target, BONUS_DAMAGE) + GetHeroStat(MainStat(target),target,true)) * (ablev + 7) / 20. * boost //attack boost
            call UnitAddBonus(target,BONUS_DAMAGE, R2I(pt.dmg))
            call TimerStart(pt.getTimer(), 15. * boost, false, function ArcaneMightExpire)
        endif
	elseif sid == 'A0KC' then //Arcane Nova
		call GroupEnumUnitsInRange(ug, GetSpellTargetX(), GetSpellTargetY(), 300*LBOOST(pid), Condition(function isalive))
		set dmg= (ablev * .5) * (GetHeroStr(caster,true) + GetHeroInt(caster,true)) * boost
		loop
			set target=FirstOfGroup(ug)
			exitwhen target == null
			call GroupRemoveUnit(ug, target)
			if IsUnitType(target, UNIT_TYPE_STRUCTURE)==false then
				if IsUnitAlly(target, p ) then
                    call HP(target, dmg)
					call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Orc\\HealingWave\\HealingWaveTarget.mdl", target, "overhead"))
				else
					call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
					call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\Defend\\DefendCaster.mdl", target, "origin"))
				endif
			endif
		endloop
		call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\ReplenishHealth\\ReplenishHealthCasterOverhead.mdl", GetSpellTargetX(), GetSpellTargetY()))
		call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\Disenchant\\DisenchantSpecialArt.mdl", GetSpellTargetX(), GetSpellTargetY()))
	elseif sid == 'A07P' then //Arcane Radiance
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 10 * boost
        call DestroyEffectTimed(AddSpecialEffectTarget("war3mapImported\\HolyAurora.MDX", caster, "origin"), pt.dur)
        call TimerStart(pt.getTimer(), 2., true, function ArcaneRadiance)
		
	/*/*======================
        Savior
    ======================*/*/
	
	elseif sid == 'A0KU' then //Savior's Guidance
		set dmg = GetHeroStr(caster,true) * (2.25 + .25 * ablev) * boost
        set dur = 9 + ablev
        
		if caster != target and IsUnitType(target, UNIT_TYPE_DEAD) == false then
            call Shield(target, dmg, dur)
		endif
        
        call Shield(caster, dmg, dur)
        
	elseif sid == 'A0AT' then //Thunder clap
		set AOE = 200 + 50 * ablev
		set dmg = 0.25 * (ablev + 1) * (UnitGetBonus(caster, BONUS_DAMAGE) + GetHeroStr(caster,true) * 2) * boost
		call MakeGroupInRange(pid, ug, x, y, AOE * LBOOST(pid), Condition(function FilterEnemy))
		loop
			set target= FirstOfGroup(ug)
			exitwhen target== null
			call GroupRemoveUnit(ug,target)
            call DummyCastTarget(p, target, 'A05J', 1, x, y, "slow")
			call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		endloop
	elseif sid == 'A038' then //Divine Judgement
		set angle= Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x )
		set dmg=R2I( 0.33*(ablev+1)*(UnitGetBonus(caster,BONUS_DAMAGE)+GetHeroStr(caster,true)*2 )* boost )
		set AOE = 150.*LBOOST(pid)
		set g= CreateGroup()
		call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", caster, "origin" ) )
		set i= 1
		loop
			exitwhen i > 10
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\ReplenishHealth\\ReplenishHealthCasterOverhead.mdl", x +100.*i*SquareRoot(boost)*Cos(angle) , y +100.*i*SquareRoot(boost)*Sin(angle) ) )
			call MakeGroupInRange(pid, ug, x +100.*i*SquareRoot(boost)*Cos(angle) , y +100.*i*SquareRoot(boost)*Sin(angle), AOE, Condition(function FilterEnemy))
			call BlzGroupAddGroupFast(ug,g)
			call GroupClear(ug)
			set i= i+1
		endloop
		loop
			set target= FirstOfGroup(g)
			exitwhen target == null
			call GroupRemoveUnit(g, target)
			call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		endloop
		call DestroyGroup(g)
	elseif sid == 'A08R' then //Avatar Righteous Might
        call DummyCastTarget(p, caster, 'A08W', ablev, x, y, "bloodlust")
		set dmg= (UnitGetBonus(caster,BONUS_DAMAGE)+GetHeroStr(caster,true)) * (.4 + (.2 * ablev)) * boost
		set armor= BlzGetUnitArmor(caster) * (.4 + (.2 * ablev)) * boost
		set i = 1
		call UnitAddAbility(caster, 'A0CZ')
        call HP(caster, BlzGetUnitMaxHP(caster) * (0.11 + 0.03 * ablev) * LBOOST(pid))
		call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\ReviveHuman\\ReviveHuman.mdl", x, y ))
		loop
			exitwhen i > 24
			set angle= 2*bj_PI *i /24.
			call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", x+ 500*Cos(angle), y+ 500*Sin(angle) ))
			set i = i + 1
		endloop
        call MakeGroupInRange(pid, ug, x, y, 500 * LBOOST(pid), Condition(function FilterEnemy))
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call UnitDamageTarget(Hero[pid], target, (ablev+1) *2 *GetHeroStr(caster,true) * boost, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
        
		call UnitAddBonus(caster, BONUS_DAMAGE, R2I(dmg) )
		call UnitAddBonus(caster, BONUS_ARMOR, R2I(armor) )

        set pt = TimerList[pid].addTimer(pid)
        set pt.dmg = dmg
        set pt.armor = armor

        call TimerStart(pt.getTimer(), (ablev + 3) * 2, false, function AvatarExpire)
		
	/*/*======================
        Bloodzerker
    ======================*/*/
    
    elseif sid == 'A05Z' then //Leap
        if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
            call SetWidgetLife(caster, GetWidgetLife(caster) - BlzGetUnitMaxHP(caster) * 0.05)
            if UnitAddAbility(caster,'Amrf') then
                call UnitRemoveAbility(caster, 'Amrf')
            endif
            set udg_DashAngleR[pid] = Atan2(GetLocationY(loc) - y, GetLocationX(loc) - x)
            set FlightTarget[pid]=GetSpellTargetLoc()
            set udg_DashDistance[pid]= RMaxBJ(SquareRoot(Pow(GetLocationX(loc) - x, 2) + Pow(GetLocationY(loc) - y, 2)), 400)
            if IsTerrainWalkable(x + Cos(udg_DashAngleR[pid]) * udg_DashDistance[pid], y + Sin(udg_DashAngleR[pid]) * udg_DashDistance[pid]) then
                set initDistance[pid]= udg_DashDistance[pid]
                call SetUnitTimeScale(caster, 0.75)
                call SetUnitPathing(caster, false)
                call SetUnitPropWindow(caster, 0)
                call DelayAnimation(pid, caster, (initDistance[pid] / 30. * 0.03) + 0.5, 1, 0, false)
            else
                set udg_DashDistance[pid] = 0
                call SetUnitPosition(caster, x, y)
                call DisplayTextToPlayer(p, 0, 0, "Cannot target there")
            endif
		else
			call SetUnitPosition(caster, x, y)
			call DisplayTextToPlayer(p, 0, 0, "Cannot target there")
		endif
	elseif sid == 'A05Y' then //Blood Frenzy
		set bloodfrenzybonus[pid] = R2I((UnitGetBonus(caster, BONUS_DAMAGE) + GetHeroStr(caster, true)) * LBOOST(pid))
        call BlzSetUnitAttackCooldown(caster, BlzGetUnitAttackCooldown(caster, 0) / 1.20, 0)
		call SetWidgetLife(caster, GetWidgetLife(caster) - BlzGetUnitMaxHP(caster) * 0.15)
        if IsUnitType(caster, UNIT_TYPE_DEAD) == false then
            call UnitAddBonus(caster, BONUS_DAMAGE, bloodfrenzybonus[pid])
            call UnitAddAbility(caster, 'A07E')
            call TimerStart(NewTimerEx(pid), 10.0, false, function BloodFrenzyExpire)
        endif
	elseif sid == 'A06H' then //Blood-curdling Scream
		call SetWidgetLife(caster, GetWidgetLife(caster) - BlzGetUnitMaxHP(caster) * 0.05)
		call MakeGroupInRange(pid, ug, x, y, 420 * boost, Condition(function FilterEnemy))

		loop
			set target = FirstOfGroup(ug)
			exitwhen target == null
            call GroupRemoveUnit(ug, target)
			if GetUnitAbilityLevel(target, 'A0F1') == 0 then
                if target == Hero[GetPlayerId(GetOwningPlayer(target)) + 1] then
                    set pt = TimerList[GetPlayerId(GetOwningPlayer(target)) + 1].addTimer(GetPlayerId(GetOwningPlayer(target)) + 1)
                    set t = pt.getTimer()
                else
                    set t = NewTimerEx(pid)
                endif

                call UnitAddAbility(target, 'A0F1')
                set i2 = IMaxBJ(0, R2I(BlzGetUnitArmor(target) * (0.12 + 0.02 * ablev)))
                if i2 > 0 then
                    call SaveInteger(ScreamTargets, 0, GetHandleId(t), i2)
                    call BlzSetUnitArmor(target, BlzGetUnitArmor(target) - i2)
                    set armor = BlzGetUnitArmor(target)
                    call SaveInteger(ScreamTargets, 1, GetHandleId(t), R2I(armor))
                    call SaveUnitHandle(ScreamTargets, 2, GetHandleId(t), target)
                    call SaveInteger(ScreamTargets, 3, GetHandleId(t), ablev)
                    call TimerStart(t, 0.2, true, function BloodCurdlingScreamExpire)
                endif
			endif
		endloop
	
	/*/*======================
        Warrior
    ======================*/*/
    
    elseif sid == 'A0EE' then //leap
		if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
            if UnitAddAbility(caster,'Amrf') then
                call UnitRemoveAbility(caster,'Amrf')
            endif
            set udg_DashAngleR[pid]=Atan2(GetLocationY(loc) - y, GetLocationX(loc) - x)
            set FlightTarget[pid]=GetSpellTargetLoc()
            call SetUnitTimeScale(caster, 0.75)
            call SetUnitPathing(caster, false)
            call SetUnitPropWindow(caster, 0)
            set udg_DashDistance[pid]= SquareRoot(Pow(GetLocationX(loc) - x, 2) + Pow(GetLocationY(loc) - y, 2))
            if udg_DashDistance[pid] < 17 then
                set udg_DashDistance[pid] = 17
            endif
            set initDistance[pid]= udg_DashDistance[pid]
            call DelayAnimation(pid, caster, (initDistance[pid] / 26. * 0.03) + 0.2, 1, 0, false)
		else
			call SetUnitPosition(caster, x, y)
			call DisplayTextToPlayer(p, 0, 0, "Cannot target there")
		endif
	elseif sid == 'A01C' then //war stomp
		set boost = LBOOST(pid)
        call MakeGroupInRange(pid, ug, x, y, 260 * boost, Condition(function FilterEnemy))
		set dmg = GetUnitAbilityLevel(caster,'A01C')*GetHeroStr(caster,true)*BOOST(pid)
		//call DestroyEffectTimed(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x, y), 1)
		loop
			set target = FirstOfGroup(ug)
			exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call DummyCastTarget(p, target, 'A0DS', R2I(GetUnitAbilityLevel(caster, 'A01C') * boost), GetUnitX(target), GetUnitY(target), "thunderbolt")
			call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		endloop
	elseif sid == 'A0FP' then //whirl strikes
        call TimerList[pid].stopAllTimersWithTag('dani')
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 10 * LBOOST(pid)
        call SetUnitTimeScale(caster, 1.)
		call TimerStart(pt.getTimer(), 0.2, true, function WhirlStrikes)

	/*/*======================
        Vampire
    ======================*/*/

    elseif sid == 'A07A' then //blood leech
		set dmg = (2.75 + 0.25 * ablev) * (GetHeroAgi(Hero[pid], true) + GetHeroStr(caster,true)) * boost
        call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        set BloodBank[pid] = RMinBJ(BloodBank[pid] + 10 * GetHeroAgi(Hero[pid], true) + 5 * GetHeroStr(Hero[pid], true), 200 * GetHeroInt(Hero[pid], true))
    elseif sid == 'A09B' then //blood domain
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 5.
        if GetHeroStr(caster, true) > GetHeroAgi(caster, true) and GetUnitAbilityLevel(caster, 'A097') > 0 then
            set pt.aoe = 400 * 2 * LBOOST(pid)
        else
            set pt.aoe = 400 * LBOOST(pid)
        endif

        call MakeGroupInRange(pid, ug, x, y, pt.aoe, Condition(function FilterEnemyDead))

        set tg = CreateGroup()
        call MakeGroupInRange(pid, tg, x, y, pt.aoe, Condition(function FilterEnemy))

        set pt.dmg = ((0.5 + 0.5 * ablev) * GetHeroAgi(Hero[pid], true)) + ((1.5 + 0.5 * ablev) * GetHeroStr(Hero[pid], true))
        set pt.dmg = RMaxBJ(pt.dmg * 0.2, pt.dmg * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(tg) - 1)))
        set pt.armor = 1 * (GetHeroAgi(Hero[pid], true) + GetHeroStr(Hero[pid], true))
        set pt.armor = RMaxBJ(pt.armor * 0.2, pt.armor * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(ug) - 1)))

        call DestroyGroup(tg)

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set BloodBank[pid] = RMinBJ(BloodBank[pid] + pt.armor, 200 * GetHeroInt(Hero[pid], true))

            if GetWidgetLife(target) >= 0.406 then
                call UnitDamageTarget(caster, target, pt.dmg * boost, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                if GetHeroStr(caster, true) > GetHeroAgi(caster, true) and GetUnitAbilityLevel(caster, 'A097') > 0 then //str taunt
                    //switch target only here not in BloodDomainTick
                endif
            endif

            set bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), 'A09D', 1, DUMMY_RECYCLE_TIME)
            call BlzSetUnitWeaponBooleanField(bj_lastCreatedUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(caster) - GetUnitY(bj_lastCreatedUnit), GetUnitX(caster) - GetUnitX(bj_lastCreatedUnit)))
            call IssueTargetOrder(bj_lastCreatedUnit, "attack", caster)
        endloop

        call TimerStart(pt.getTimer(), 1., true, function BloodDomainTick)
    elseif sid == 'A09A' then //blood nova
        set dmg = 40 * GetHeroInt(caster, true) //blood cost 20%

        if BloodBank[pid] >= dmg then
            set BloodBank[pid] = BloodBank[pid] - dmg
            call SetUnitState(Hero[pid], UNIT_STATE_MANA, BloodBank[pid])
            set dmg = dmg * 0.3 + (3 * GetHeroAgi(Hero[pid], true) + 2 * GetHeroStr(Hero[pid], true))
            call MakeGroupInRange(pid, ug, x, y, (225 + 25 * ablev) * LBOOST(pid), Condition(function FilterEnemy))
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call UnitDamageTarget(caster, target, dmg * boost, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endloop
            set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\Death Nova.mdx", x, y)
            call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 0.5 + 0.1 * ablev)
            call DestroyEffect(bj_lastCreatedEffect)
        endif
    elseif sid == 'A097' then //blood lord
        if GetHeroAgi(caster, true) > GetHeroStr(caster, true) then
            set pt = TimerList[pid].addTimer(pid)
            call UnitDisableAbility(Hero[pid], 'A07A', true)
            call BlzUnitHideAbility(Hero[pid], 'A07A', false)
            call UnitDisableAbility(Hero[pid], 'A09B', true)
            call BlzUnitHideAbility(Hero[pid], 'A09B', false)
            call TimerStart(pt.getTimer(), 1., true, function BloodLeechAoE)
            set pt = TimerList[pid].addTimer(pid)
            set pt.agi = R2I(BloodBank[pid] * 0.01)
            set pt.str = 0
            call UnitAddBonus(caster, BONUS_HERO_AGI, pt.agi)
        else
            set pt = TimerList[pid].addTimer(pid)
            set pt.str = R2I(BloodBank[pid] * 0.01)
            set pt.agi = 0
            call UnitAddBonus(caster, BONUS_HERO_STR, pt.str)
        endif

        set boost = LBOOST(pid)
        call TimerStart(pt.getTimer(), (9 + ablev) * boost, false, function BloodLordExpire)
        call BlzSetUnitAttackCooldown(caster, BlzGetUnitAttackCooldown(caster, 0) * 0.7, 0)
        call DestroyEffectTimed(AddSpecialEffectTarget("war3mapImported\\Burning Rage Red.mdx", caster, "overhead"), (9 + ablev) * boost)
        call SetUnitAnimationByIndex(caster, 3)
        call UnitAddAbility(caster, 'A099')
        set BloodBank[pid] = 0
        call SetUnitState(Hero[pid], UNIT_STATE_MANA, BloodBank[pid])


	/*/*/*====================
        Hydromancer
    ====================*/*/*/
    
	elseif sid == 'A08E' then //blizzard
        set pt = TimerList[pid]
		set dur = ablev + 3
        set boost = LBOOST(pid)
        set blizzarddamager[pid] = GetDummy(x, y, 'A02O', GetUnitAbilityLevel(caster,'A08E'), dur * boost + 3.)
        call SetUnitOwner(blizzarddamager[pid], p, true)
        if GetUnitAbilityLevel(caster,'B01I') > 0 then
			call UnitRemoveAbility(caster,'B01I')
            call SaveInteger(MiscHash, 0, GetHandleId(blizzarddamager[pid]), 1)
		endif
        call TimerStart(NewTimerEx(pid), dur * boost - 0.7, false, function BlizzardAnimationExpire)
        call TimerStart(NewTimerEx(pid), dur * boost + 0.2, false, function BlizzardExpire)
        call IssuePointOrder(blizzarddamager[pid], "blizzard", GetSpellTargetX(), GetSpellTargetY())
	elseif sid == 'A0GI' then //Frost blast
        set frostblastdummy[pid] = GetDummy(x, y, 'A04B', 1, DUMMY_RECYCLE_TIME)
        call SetUnitOwner(frostblastdummy[pid], p, true)
        call IssueTargetOrder(frostblastdummy[pid], "thunderbolt", target)
		
    elseif sid == 'A03X' then //Whirlpool
        if IsTerrainWalkable(GetLocationX(whirlspot[pid]), GetLocationY(whirlspot[pid])) then
            call GroupClear(whirlpooled[pid])
            set whirlspot[pid] = GetSpellTargetLoc()
            set x = GetLocationX(whirlspot[pid])
            set y = GetLocationY(whirlspot[pid])
            set whirldur[pid] = (2 + ablev * 2) * LBOOST(pid)
            loop
                exitwhen i > 5
                set angle = bj_PI * 2 * i / 5
                set dummymodel[pid * 5 + i] = GetDummy(x + Cos(angle) * 230. * i / 5, y + Sin(angle) * 230. * i / 5, 0, 0, 0)
                call SetUnitOwner(dummymodel[pid * 5 + i], Player(pid - 1), true)
                call BlzSetUnitFacingEx(dummymodel[pid * 5 + i], angle * bj_RADTODEG + 90)
                set dummyeffect[pid * 5 + i] = AddSpecialEffectTarget("war3mapImported\\WaterArchon_Missile.mdx", dummymodel[pid * 5 + i], "origin")
                set i = i + 1
            endloop
            if GetUnitAbilityLevel(Hero[pid], 'B01I') > 0 then
                call UnitRemoveAbility(Hero[pid], 'B01I')
                set whirldur[pid] = whirldur[pid] + 2
            endif
            set whirlpoolcloud[pid] = AddSpecialEffect("Abilities\\Spells\\Human\\CloudOfFog\\CloudOfFog.mdl", x, y)
            set WhirlDamage[pid] = GetHeroInt(Hero[pid], true) * 0.25 * ablev * boost
            set t = NewTimer()
            call SaveInteger(MiscHash, 0, GetHandleId(t), pid)
            call TimerStart(t, 0.03, true, function HydroWhirlpool)
        else
            call DisplayTextToPlayer(p, 0, 0, "Cannot cast there")
        endif
    elseif sid == 'A077' then //Tidal Wave
        set udg_DashAngleR[pid] = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        if GetUnitAbilityLevel(Hero[pid], 'B01I') > 0 then
            set WaveBuffed[pid] = 1
            call UnitRemoveAbility(Hero[pid], 'B01I')
        else
            set WaveBuffed[pid] = 0
        endif
        set udg_DashDistance[pid] = (500 + ablev * 100) * boost
        set udg_DashDummy[pid] = CreateUnit(p, 'h04X', x, y, udg_DashAngleR[pid] * bj_RADTODEG)
        call SetUnitScale(udg_DashDummy[pid], 0.8, 0.8, 0.8)
        set t = NewTimer()
        call SetTimerData(t, pid)
        call TimerStart(t, 0.06, true, function HydroTidalWave)
    elseif sid == 'A098' then //Ice Prison
        if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
            set pt = TimerList[pid].addTimer(pid)
            set pt.aoe = (300 + 60 * ablev) * LBOOST(pid)
            set pt.x = GetSpellTargetX()
            set pt.y = GetSpellTargetY()
            set pt.dmg = GetHeroInt(caster, true) * ablev * boost

            if GetUnitAbilityLevel(Hero[pid],'B01I') > 0 then
                call UnitRemoveAbility(Hero[pid], 'B01I')
                set pt.aoe = pt.aoe * (1.33) 
            endif

            loop
                exitwhen i > 7
                set angle = bj_PI * 2 * i / 8.
                set target = GetDummy(pt.x + pt.aoe * Cos(angle), pt.y + pt.aoe * Sin(angle), 0, 0, DUMMY_RECYCLE_TIME)
                call BlzSetUnitSkin(target, 'e00P')
                call SetUnitScale(target, 0.6, 0.6, 0.6 )
                call SaveUnitHandle(Pillars, pid, i, target)
                set i = i + 1
            endloop

            call TimerStart(pt.getTimer(), 0.05, true, function IcePrisonPeriodic)
        else
            call SetUnitPosition(Hero[pid], x, y)
            call DisplayTextToPlayer(p,0,0,"Cannot cast there")
        endif
        
	/*========================
        Thunderblade
	========================*/
    
    elseif sid == 'A095' then //Thunder Dash
        call TimerList[pid].stopAllTimersWithTag('omni')
        call SetUnitVertexColor(caster, 255, 255, 255, 255)
        call SetUnitTimeScale(caster, 1.)
        set udg_DashAngleR[pid] = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set udg_DashDistance[pid] = (ablev+3) * 150 * LBOOST(pid)
        call ShowUnit(caster,false)
        call UnitAddAbility(caster, 'Avul')
        call BlzPauseUnitEx(caster, true)
        set udg_DashDummy[pid] = GetDummy(x, y, 0, 0, DUMMY_RECYCLE_TIME)
        call BlzSetUnitSkin(udg_DashDummy[pid], 'h00B')
        call SetUnitScale(udg_DashDummy[pid], 1.5, 1.5, 1.5)
        call SetUnitFlyHeight( udg_DashDummy[pid], 150.00, 0.00 )
        call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\FarseerMissile\\FarseerMissile.mdl",x,y))
	elseif sid == 'A0os' then //Omnislash
        set pt = TimerList[pid].addTimer(pid)
		set dmg = OmnislashFormula(pid) * boost
        set pt.dur = R2I((2 + ablev) * LBOOST(pid))
        set pt.tag = 'omni'

		if GetUnitAbilityLevel(caster,'B0ov') > 0 then
			set dmg = dmg * (1 + 0.1 * GetUnitAbilityLevel(caster,'A096'))
		endif

        call SetUnitTimeScale(caster, 2.5)
		call SetUnitVertexColorBJ(caster, 100, 100, 100, 50.00)
		call SetUnitXBounded(caster, GetUnitX(target) + 60. * Cos(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
        call SetUnitYBounded(caster, GetUnitY(target) + 60. * Sin(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
        call BlzSetUnitFacingEx(caster, GetUnitFacing(target))
		call UnitDamageTarget( caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\NightElf\\Blink\\Blinkcaster.mdl", caster, "chest" ) )
        call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "chest" ) )
        
        call TimerStart(pt.getTimer(), 0.4, true, function Omnislash)
	elseif sid == 'A0MN' then //Monsoon
        set t = NewTimerEx(pid)
        call SaveReal(MiscHash, GetHandleId(t), 0, (ablev + 1) * LBOOST(pid))
        call SaveReal(MiscHash, GetHandleId(t), 1, (275 + 25 * ablev) * boost)
        call SaveReal(MiscHash, GetHandleId(t), 2, GetSpellTargetX())
        call SaveReal(MiscHash, GetHandleId(t), 3, GetSpellTargetY())
        set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\AnimatedEnviromentalEffectRainBv005", GetSpellTargetX(), GetSpellTargetY())
        call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 0.4)
        call DestroyEffectTimed(bj_lastCreatedEffect, 5.)
		call TimerStart(t, 1., true, function Monsoon)
	elseif sid == 'A03O' then //Bladestorm
        set t = NewTimer()
        call AddUnitAnimationProperties(Hero[pid], "spin", true)
        call SaveInteger(MiscHash, 0, GetHandleId(t), pid)
        call TimerStart(t, 0.33, true, function BladeStorm)
	
	/*/*======================
        Royal Guardian
    ======================*/*/
	
	elseif sid == 'A0HT' then //Shield Slam
		set dmg = ablev * (GetHeroStr(caster, true) + 4 * BlzGetUnitArmor(caster)) * BOOST(pid)
        set dur = 2 + IMinBJ(2, HasShield[pid])
        call StunUnit(pid, target, dur)

        set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\DetroitSmash_Effect_CasterArt.mdx", x, y)
        call BlzSetSpecialEffectYaw(bj_lastCreatedEffect, bj_DEGTORAD * GetUnitFacing(caster))
        call DestroyEffect(bj_lastCreatedEffect)

		if HasShield[pid] > 0 then
            set dmg = dmg * (1 + IMinBJ(2, HasShield[pid]) * 0.2)

            call UnitDamageTarget( caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )

            call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 300 * LBOOST(pid), Condition(function FilterEnemy))
            call GroupRemoveUnit(ug, target)

            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call UnitDamageTarget(caster, target, dmg * .5, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endloop
		else
            call UnitDamageTarget( caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
		endif
	elseif sid == 'A0EG' then //Royal Plate
		if HasShield[pid] > 0 then
			set i = R2I(( 0.006 *Pow(ablev,5) + 10 *Pow(ablev,2) +25*ablev + UnitGetBonus(caster, BONUS_ARMOR) * .23) * boost * 1.3)
		else
			set i = R2I(( 0.006 *Pow(ablev,5) + 10 *Pow(ablev,2) +25*ablev ) *boost)
		endif
		call UnitAddBonus( caster, BONUS_ARMOR, i )
        set pt = TimerList[pid].addTimer(pid)
        set pt.armor = i

        call TimerStart(pt.getTimer(), 15., false, function RoyalPlateExpire)
	elseif sid == 'A04Y' then //Provoke
        set heal = (BlzGetUnitMaxHP(caster) - GetWidgetLife(caster)) * (0.2 + 0.01 * ablev) * boost
		call SetWidgetLife(caster, GetWidgetLife(caster) + heal)
        call MakeGroupInRange(pid, ProvokeTargets[pid], x, y, (500 + 50 * ablev) * LBOOST(pid), Condition(function FilterEnemy))
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Taunt\\TauntCaster.mdl", caster, "origin"))
        set i = 0
        set i2 = BlzGroupGetSize(ProvokeTargets[pid])
        
		loop
            set target = BlzGroupUnitAt(ProvokeTargets[pid], i)
            call DummyCastTarget(p, target, 'A04X', 1, GetUnitX(target), GetUnitY(target), "slow")
            set i = i + 1
            exitwhen i >= i2
		endloop
    elseif sid == 'A09E' then //Fight Me
        set FightMe[pid] = true
        call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Voodoo\\VoodooAura.mdl", caster, "origin"), (4 + ablev) * boost)
        call TimerStart(NewTimerEx(pid), (4 + ablev) * boost, false, function FightMeExpire)
		
	/*/*/*====================
        High Priestess
    ====================*/*/*/
	
	elseif sid == 'A0DU' then //Triage
        if ResurrectionCD[pid] > 2 then
            set ResurrectionCD[pid] = ResurrectionCD[pid] - 2
        endif
		call TimerStart(NewTimerEx(pid), 0.5 / LBOOST(pid), true, function Triage_Heal)
	elseif sid == 'A0J3' then //Protection
        if ResurrectionCD[pid] > 2 then
            set ResurrectionCD[pid] = ResurrectionCD[pid] - 2
        endif

        call MakeGroupInRange(pid, ProtectionGroup[pid], x, y, 650., Condition(function FilterAllyHero))
        
        call TimerStart(NewTimerEx(pid), 5. * boost, false, function ProtectionExpire)
        
		//call SetUnitState(caster,UNIT_STATE_MANA, GetUnitState(caster,UNIT_STATE_MANA) /2.)
	elseif sid == 'A0JD' then //Healing Rays
        if ResurrectionCD[pid] > 2 then
            set ResurrectionCD[pid] = ResurrectionCD[pid] - 2
        endif
		set heal = ablev * GetHeroInt(caster,true) * boost
		set i = 1
		call MakeGroupInRange(pid, ug, x, y, 600 * LBOOST(pid), Condition(function FilterAlly))
		loop
			set target = FirstOfGroup(ug)
			exitwhen target == null
			call GroupRemoveUnit(ug, target)
            set bj_lastCreatedUnit = GetDummy(x, y, 'A09Q', 1, DUMMY_RECYCLE_TIME)
            call BlzSetUnitWeaponBooleanField(bj_lastCreatedUnit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(bj_lastCreatedUnit), GetUnitX(target) - GetUnitX(bj_lastCreatedUnit)))
            call IssueTargetOrder(bj_lastCreatedUnit, "attack", target)
            call HP(target, heal)
			set i = i + 1
		endloop
	elseif sid == 'A0JE' then //Divine Light
        if ResurrectionCD[pid] > 2 then
            set ResurrectionCD[pid] = ResurrectionCD[pid] - 2
        endif
		set heal= (50 + ablev * GetHeroInt(caster,true)) * BOOST(pid)
        if GetUnitTypeId(target) == BACKPACK then
            call HP(Hero[tpid], heal)
		elseif IsUnitAlly(target,p) then
            call HP(target, heal)
		else
			call UnitDamageTarget( caster, target, heal, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
		endif
	elseif sid == 'A0JG' then //Holy Shock
        if ResurrectionCD[pid] > 2 then
            set ResurrectionCD[pid] = ResurrectionCD[pid] - 2
        endif
		set dmg = (ablev + 1) * GetHeroInt(caster,true) * BOOST(pid)
		call GroupEnumUnitsInRange(ug, GetSpellTargetX(), GetSpellTargetY(), 275.00*LBOOST(pid), Condition(function isalive))
		loop
			set target = FirstOfGroup(ug)
			exitwhen target == null
			call GroupRemoveUnit(ug, target)
			if IsUnitAlly(target,p) then
                call HP(target, dmg)
				call DestroyEffect( AddSpecialEffectTarget("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl",target,"origin") )
			else
				call UnitDamageTarget( caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
				call DestroyEffect( AddSpecialEffectTarget("Abilities\\Spells\\Demon\\DemonBoltImpact\\DemonBoltImpact.mdl",target,"origin") )
			endif
		endloop
        set bj_lastCreatedEffect = AddSpecialEffect("Abilities\\Spells\\Undead\\ReplenishHealth\\ReplenishHealthCasterOverhead.mdl", GetSpellTargetX(), GetSpellTargetY())
        call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 2.5)
        call DestroyEffectTimed(bj_lastCreatedEffect, 2.5)
		
	/*========================
        Master Rogue
	========================*/
	elseif sid == 'A0QV' then //Death Strike
        call AddUnitAnimationProperties(caster, "alternate", false)
        set t = NewTimerEx(pid)
        call SaveUnitHandle(MiscHash, 0, GetHandleId(t), target)
        call BlzPauseUnitEx(target, true)
        call TimerStart(t, 0.03, true, function DeathStrikeTP)
        call UnitAddAbility(target, 'S00I')
        call SetUnitTurnSpeed(target, 0)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl", caster, "chest"))

        set t = NewTimer()
        call SaveUnitHandle(MiscHash, 0, GetHandleId(t), target)
        call TimerStart(t, ablev * 0.6 * BOOST(pid), true, function Unimmobilize)
	elseif sid == 'A0F5' then //Windwalk
        call AddUnitAnimationProperties(caster, "alternate", true)
        call TimerStart(NewTimerEx(pid), 0.2, false, function WindwalkStart)
        call TimerStart(NewTimerEx(pid), 3 + 2 * ablev, false, function WindwalkEnd)
	elseif sid == 'A0F7' then //Nerve Gas
        call AddUnitAnimationProperties(caster, "alternate", false)
        set dummy = GetDummy(GetSpellTargetX(), GetSpellTargetY(), 0, 0, 0)
        call UnitRemoveAbility(dummy, 'Avul')
        call UnitRemoveAbility(dummy, 'Aloc')
        set u = GetDummy(x, y, 'A01X', 1, 0)
        call SetUnitOwner(u, p, true)
        call IssueTargetOrder(u, "acidbomb", dummy)
        
	/*========================
        Assassin
	========================*/

	elseif sid == 'A0BG' then //Shadow Shuriken
        //change blade spin to active
        call UnitAddAbility(caster, 'A0AS')
        call UnitDisableAbility(caster, 'A0AQ', true)
        call UnitSpecification(caster)

        set pt = TimerList[pid].addTimer(pid)
        set pt.target = GetDummy(x, y, 0, 0, DUMMY_RECYCLE_TIME)
        set pt.ug = CreateGroup()
        set pt.dur = 750.
        set pt.aoe = 200.
        set pt.armor = 60.
        set pt.int = 0
        set pt.angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x) 
        set pt.dmg = (GetHeroAgi(caster,true) * 2 + UnitGetBonus(caster,BONUS_DAMAGE)) * (GetUnitAbilityLevel(caster, sid) + 5) * 0.25 * BOOST(pid) 

        call BlzSetUnitSkin(pt.target, 'h00F')
        call SetUnitScale(pt.target, 1.1, 1.1, 1.1)
        call SetUnitVertexColor(pt.target, 50, 50, 50, 255)
        call UnitAddAbility(pt.target, 'Amrf')
        call SetUnitFlyHeight(pt.target, 75.00, 0.00)
        call BlzSetUnitFacingEx(pt.target, bj_RADTODEG * pt.angle)

        call TimerStart(pt.getTimer(), 0.03, true, function ShadowShuriken)
	elseif sid == 'A01E' then //Smoke bomb
        //change blade spin to active
        call UnitAddAbility(caster, 'A0AS')
        call UnitDisableAbility(caster, 'A0AQ', true)
        call UnitSpecification(caster)

        set dmg = LBOOST(pid)
        set SmokebombValue[pid] = 9 + ablev
        set SmokebombX[pid] = GetSpellTargetX()
        set SmokebombY[pid] = GetSpellTargetY()
        call TimerStart(NewTimerEx(pid), 8. * dmg, false, function SmokebombExpire)
        call DestroyEffectTimed(AddSpecialEffect("war3mapImported\\GreySmoke.mdx", GetSpellTargetX(), GetSpellTargetY()), 8 * dmg)
	elseif sid == 'A00T' then //Blink Strike
		if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
            //change blade spin to active
            call UnitAddAbility(caster, 'A0AS')
            call UnitDisableAbility(caster, 'A0AQ', true)
            call UnitSpecification(caster)

			set i=0
			loop
				exitwhen i>11
				set angle=2 *bj_PI *i /12.
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\FeralSpirit\\feralspiritdone.mdl", GetSpellTargetX()+190*Cos(angle), GetSpellTargetY()+190*Sin(angle) ) )
				set i= i+1
			endloop
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\FeralSpirit\\feralspiritdone.mdl", GetSpellTargetX(), GetSpellTargetY() ) )
			call MakeGroupInRange(pid, ug, GetSpellTargetX(), GetSpellTargetY(), 200.*LBOOST(pid), Condition(function FilterEnemy))
			loop
				set target = FirstOfGroup(ug)
				exitwhen target == null
				call GroupRemoveUnit(ug, target)
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "origin" ) )
                if GetUnitAbilityLevel(target, 'B019') > 0 then
                    call GroupRemoveUnit(markedfordeath[pid], target)
                    call SetUnitPathing(target, true)
                    call UnitRemoveAbility(target, 'B019')
                    set BlinkStrike.add(Hero[pid], Hero[pid]).duration = 6.
                    call UnitDamageTarget( caster, target, ablev * .25 * (GetHeroAgi(caster,true)*3+UnitGetBonus(caster,BONUS_DAMAGE)) *boost, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
                else
                    call UnitDamageTarget( caster, target, ablev * .25 * (GetHeroAgi(caster,true)*3+UnitGetBonus(caster,BONUS_DAMAGE)) *boost, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS )
                endif
			endloop
			call SetUnitXBounded(caster, GetSpellTargetX())
			call SetUnitYBounded(caster, GetSpellTargetY())
		else
			call DisplayTextToPlayer(p, 0, 0, "Cannot target there")
			call SetUnitPosition(caster, x, y)
		endif
    elseif sid == 'A00P' then //dagger storm
        //change blade spin to active
        call UnitAddAbility(caster, 'A0AS')
        call UnitDisableAbility(caster, 'A0AQ', true)
        call UnitSpecification(caster)

        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 30
        set pt.x = GetSpellTargetX()
        set pt.y = GetSpellTargetY()
        set pt.armor = x
        set pt.aoe = y
        set pt.agi = udg_PS_Index_Max + 1

        call TimerStart(pt.getTimer(), 0.03, true, function SpawnDaggers)
        
    /*/*/*====================
        Arcanist
    ====================*/*/*/
    
    elseif sid == 'A04C' then //Control Time
        call BlzSetUnitAttackCooldown(Hero[pid], BlzGetUnitAttackCooldown(Hero[pid], 0) * 0.5, 0)
        call TimerStart(NewTimerEx(pid), 10. * LBOOST(pid), false, function ControlTime)
    
    elseif sid == 'A05Q' then //Arcane Bolts
        set angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)

        set t = NewTimerEx(pid)
        call SaveInteger(MiscHash, 0, GetHandleId(t), 0)
        call SaveReal(MiscHash, 1, GetHandleId(t), angle)
        call TimerStart(t, 0, true, function ArcaneBolts)
        
        set t = NewTimerEx(pid)
        call SaveInteger(MiscHash, 0, GetHandleId(t), ablev)
        call SaveReal(MiscHash, 1, GetHandleId(t), angle)
        call TimerStart(t, 0.2, true, function ArcaneBolts)

    elseif sid == 'A08X' then //Arcane Comets
        if IsUnitInRangeXY(arcanosphere[pid], MouseX[pid], MouseY[pid], 800.) then
            set t = NewTimerEx(pid)
            call SaveInteger(MiscHash, 0, GetHandleId(t), ablev + 2)
            call SaveReal(MiscHash, 1, GetHandleId(t), MouseX[pid])
            call SaveReal(MiscHash, 2, GetHandleId(t), MouseY[pid])
            call TimerStart(t, 0.3, true, function ArcaneComets)
        endif
        
    elseif sid == 'A02N' or sid == 'A08S' then //Arcane Barrage
        set i = 0
        
        call MakeGroupInRange(pid, ArcaneBarrageHit[pid], x, y, 750. * BOOST(pid), Condition(function FilterEnemy))
        
        set i2 = BlzGroupGetSize(ArcaneBarrageHit[pid])
        set target = FirstOfGroup(ArcaneBarrageHit[pid])
        
        if target != null then
            if i2 == 1 then
                loop
                    exitwhen i > 2
                    set x = GetUnitX(Hero[pid]) + 40. * Cos(bj_DEGTORAD * (GetUnitFacing(Hero[pid]) - 60 + i * 120))
                    set y = GetUnitY(Hero[pid]) + 40. * Sin(bj_DEGTORAD * (GetUnitFacing(Hero[pid]) - 60 + i * 120))
                    call DummyCastPoint(Player(PLAYER_NEUTRAL_PASSIVE), GetUnitX(target), GetUnitY(target), 'A01V', 1, x, y, "clusterrockets")
                    set i = i + 1
                endloop
            else
                loop
                    set target = BlzGroupUnitAt(ArcaneBarrageHit[pid], i)
                    set x = GetUnitX(Hero[pid]) + 40. * Cos(bj_DEGTORAD * (GetUnitFacing(Hero[pid]) + i * (360. / BlzGroupGetSize(ArcaneBarrageHit[pid]))))
                    set y = GetUnitY(Hero[pid]) + 40. * Sin(bj_DEGTORAD * (GetUnitFacing(Hero[pid]) + i * (360. / BlzGroupGetSize(ArcaneBarrageHit[pid]))))
                    call DummyCastPoint(Player(PLAYER_NEUTRAL_PASSIVE), GetUnitX(target), GetUnitY(target), 'A01V', 1, x, y, "clusterrockets")
                    set i = i + 1
                    exitwhen i >= i2
                endloop
            endif
        
            call TimerStart(NewTimerEx(pid), 0.8, false, function ArcaneBarrage)
        endif
        
    elseif sid == 'A075' then //Stasis Field
        set pt = TimerList[pid].addTimer(pid)
        set pt.aoe = 250. * LBOOST(pid)
        set pt.x = GetSpellTargetX()
        set pt.y = GetSpellTargetY()

        set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\Void Disc.mdx", GetSpellTargetX(), GetSpellTargetY())
        call DestroyEffectTimed(bj_lastCreatedEffect, 6.)
        call BlzSetSpecialEffectHeight(bj_lastCreatedEffect, 130.0)
        call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 1.05)

        set stasisFieldActive[pid] = true

        call TimerStart(pt.getTimer(), 0.25, true, function StasisField)
        call TimerStart(NewTimerEx(pid), 6., false, function StasisFieldActive)

    elseif sid == 'A078' then //Arcane Shift
        set attargetpoint[pid] = GetSpellTargetLoc()

        call MakeGroupInRange(pid, attargets[pid], GetSpellTargetX(), GetSpellTargetY(), 350.00 * boost, Condition(function FilterEnemy))
        call MakeGroupInRange(pid, ug, GetSpellTargetX(), GetSpellTargetY(), 350.00 * boost, Condition(function FilterEnemy))
        
        set target = FirstOfGroup(attargets[pid])
        
        if target != null then
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call DestroyEffect(AddSpecialEffect( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", GetUnitX(target), GetUnitY(target) ))
                call PauseUnit(target, true)
                if UnitAddAbility(target, 'Amrf') then
                    call UnitRemoveAbility(target, 'Amrf')
                endif
                call SetUnitFlyHeight( target, 600.00, 0.00 )
            endloop
            call TimerStart(NewTimerEx(pid), 3.5, false, function ATExpire)
            call SetPlayerAbilityAvailable(p, 'A078', false)
            call UnitAddAbility(caster, 'A00A')
            call SetUnitAbilityLevel(caster, 'A00A', GetUnitAbilityLevel(caster, 'A078'))
        endif
        
    elseif sid == 'A00A' then //Arcane Shift Second Cast
        set dmg = GetHeroInt(Hero[pid], true) * (5 + GetUnitAbilityLevel(Hero[pid], 'A078') * 3) * BOOST(pid)
    
        if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
            loop
                set target = FirstOfGroup(attargets[pid])
                exitwhen target == null
                call GroupRemoveUnit(attargets[pid], target)
                if SquareRoot(Pow(GetUnitX(target) - GetSpellTargetX(), 2) + Pow(GetUnitY(target) - GetSpellTargetY(), 2)) < 1500. and GetUnitMoveSpeed(target) > 0 then
                    call SetUnitPathing(target, false)
                    call SetUnitXBounded(target, GetSpellTargetX())
                    call SetUnitYBounded(target, GetSpellTargetY())
                    call ResetPathingTimed(target, 2.)
                endif
                call PauseUnit(target, false)
                call SetUnitFlyHeight( target, 0.00, 0.00 )
                call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))
            endloop
            
            call MakeGroupInRange(pid, ug, GetSpellTargetX(), GetSpellTargetY(), 350. * boost, Condition(function FilterEnemy))
            
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endloop
            
            call SetPlayerAbilityAvailable(p, 'A078', true)
            call UnitRemoveAbility(Hero[pid], 'A00A')
            
            call RemoveLocation(attargetpoint[pid])
        else
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Cannot target there")
        endif

    elseif sid == 'A079' then //Arcanosphere
        set arcanosphere[pid] = GetDummy(GetSpellTargetX(), GetSpellTargetY(), 0, 0, 0)
        call BlzSetUnitSkin(arcanosphere[pid], 'e00M')
        call SetUnitScale(arcanosphere[pid], 10., 10., 10.)
        call SetUnitFlyHeight(arcanosphere[pid], -50.00, 0.00)
        call SetUnitAnimation(arcanosphere[pid], "birth")
        call SetUnitTimeScale(arcanosphere[pid], 0.4)
        call UnitDisableAbility(arcanosphere[pid], 'Amov', true)

        //duration
        set dmg = (8 + 4 * ablev) * LBOOST(pid)

        //replace bolts and barrage
        call BlzUnitHideAbility(Hero[pid], 'A05Q', true)
        call BlzUnitHideAbility(Hero[pid], 'A02N', true)
        call UnitAddAbility(Hero[pid], 'A08X')
        call UnitAddAbility(Hero[pid], 'A08S')
        call SetUnitAbilityLevel(Hero[pid], 'A08X', GetUnitAbilityLevel(Hero[pid], 'A05Q'))
        call SetUnitAbilityLevel(Hero[pid], 'A08S', GetUnitAbilityLevel(Hero[pid], 'A02N'))

        call TimerStart(NewTimerEx(pid), dmg, false, function Arcanosphere)
        call TimerStart(NewTimerEx(pid), 0.5, true, function ArcanosphereBuffs)

        set arcanosphereActive[pid] = true

	/*/*/*====================
        Dark Savior
    ====================*/*/*/
	
	elseif sid == 'A074' then //Freezing Blast
        set AOE = 250. * boost
        set dmg = (GetHeroInt(caster, true) * ablev + 100) * boost

        call FreezingBlast(pid, GetSpellTargetX(), GetSpellTargetY(), AOE, dmg)
        
    elseif sid == 'AOcl' then //Medean Lightning
        set dmg = ((GetHeroInt(caster, true) * (ablev + 1)) + 100) * boost
        
        call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        call GroupAddUnit(medeanLightningHit[pid], target)

        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = ablev + 1
        set pt.x = GetUnitX(target)
        set pt.y = GetUnitY(target)

        if IsUnitInGroup(target, darkSealTargets[pid]) then
            set pt.dur = 15.
            set pt.agi = 1
        endif

        call TimerStart(pt.getTimer(), 0.3, true, function MedeanLightning)
        
    elseif sid == 'A0GO' then //Dark Seal
        set dmg = 10 * LBOOST(pid)

        set darkSeal[pid] = AddSpecialEffect("Doodads\\BlackCitadel\\Props\\RuneArt\\RuneArt1.mdl", GetSpellTargetX(), GetSpellTargetY())
        set darkSeal[pid * 8] = AddSpecialEffect("Doodads\\BlackCitadel\\Props\\RuneArt\\RuneArt2.mdl", GetSpellTargetX(), GetSpellTargetY() + 20)
        
        call BlzSetSpecialEffectTimeScale(darkSeal[pid], 0.6)
        call BlzSetSpecialEffectTimeScale(darkSeal[pid * 8], 0.6)
        call BlzSetSpecialEffectScale(darkSeal[pid], 6.1)
        call BlzSetSpecialEffectScale(darkSeal[pid * 8], 2.45)
        call BlzSetSpecialEffectZ(darkSeal[pid], BlzGetLocalSpecialEffectZ(darkSeal[pid]) - 40)
        call BlzSetSpecialEffectZ(darkSeal[pid * 8], BlzGetLocalSpecialEffectZ(darkSeal[pid * 8]) - 20)
        call BlzSetSpecialEffectYaw(darkSeal[pid], Deg2Rad(315))
        call BlzSetSpecialEffectYaw(darkSeal[pid * 8], Deg2Rad(270))
        call FadeSFX(darkSeal[pid], false, false)
        call FadeSFX(darkSeal[pid * 8], false, false)
        call DestroyEffectTimed(darkSeal[pid], dmg)
        call DestroyEffectTimed(darkSeal[pid * 8], dmg)
        set darkSealActive[pid] = true
        
        call TimerStart(NewTimerEx(pid), 0.1, true, function DarkSeal)
        call TimerStart(NewTimerEx(pid), dmg - 1.1, false, function DarkSealExpire)
        
	/*========================
        Phoenix Ranger
	========================*/

	elseif sid == 'A0FT' then //Phoenix Flight
		if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
			set dur= SquareRoot( Pow(GetSpellTargetX()-x,2) +Pow(GetSpellTargetY()-y,2) )
			set udg_DashDistance[pid]=( 350 + ablev * 150 ) * (1. + BoostValue[pid]) // INLINED!!
			set udg_DashAngleR[pid]=Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
			if udg_DashDistance[pid] > dur then
				set udg_DashDistance[pid]=dur
				set FlightTarget[pid]= GetSpellTargetLoc()
			else
				set FlightTarget[pid]=Location(x + udg_DashDistance[pid] *Cos(udg_DashAngleR[pid]), y + udg_DashDistance[pid] *Sin(udg_DashAngleR[pid]))
			endif
            if IsTerrainWalkable(GetLocationX(FlightTarget[pid]), GetLocationY(FlightTarget[pid])) then
                if udg_DashDistance[pid] < 17 then
                    set udg_DashDistance[pid] = 17
                endif
                call UnitAddAbility(caster, 'Avul')
                call ShowUnit(caster, false)
                set udg_DashDummy[pid]=CreateUnit(p, 'h01B', x, y, udg_DashAngleR[pid] * bj_RADTODEG)
                call SetUnitAnimation(udg_DashDummy[pid], "birth")
                call SetUnitTimeScale(udg_DashDummy[pid], 2)
                call SetUnitScale(udg_DashDummy[pid], 1.5, 1.5, 1.5)
            else
                call RemoveLocation(FlightTarget[pid])
                set udg_DashDistance[pid] = 0
                call SetUnitPosition(caster, x, y)
                call DisplayTextToPlayer(p, 0, 0, "Cannot target there")
            endif
		else
			call SetUnitPosition(caster, x, y)
			call DisplayTextToPlayer(p, 0, 0, "Cannot target there")
		endif
    elseif sid == 'A090' then //Searing Arrow
        call SearingArrow(pid, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))

	elseif sid == 'A0F6' then //Flaming bow
        set FlamingBowCount[pid] = 0
        set FlamingBowBonus[pid] = 0.5 * (GetHeroAgi(Hero[pid], true) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) * LBOOST(pid)
        set dur = 15. * LBOOST(pid)
		call DestroyEffectTimed(AddSpecialEffectTarget("Environment\\SmallBuildingspeffect\\SmallBuildingspeffect2.mdl", caster, "weapon"), dur)
        call UnitAddAbility(caster, 'A08B')
		call UnitAddBonus( caster, BONUS_DAMAGE, R2I(FlamingBowBonus[pid]))
        set pt = TimerList[pid].addTimer(pid)

        call TimerStart(pt.getTimer(), dur, false, function FlamingBowExpire)
		
	/*/*/*====================
        Elementalist
    ====================*/*/*/
    
    //ball of lightning
    elseif sid == 'A0GV' then
        set udg_PS_Index_Max = ( udg_PS_Index_Max + 1 )
        set udg_PS_Caster[udg_PS_Index_Max] = caster
        set udg_PS_HitEffect[udg_PS_Index_Max] = "Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl"
        set udg_PS_Angle[udg_PS_Index_Max] = bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set udg_PS_Aoe[udg_PS_Index_Max] = 140 + 40 * ablev
        set udg_PS_HitTerrain[udg_PS_Index_Max] = false
        set udg_PS_Pierce[udg_PS_Index_Max] = false
        set udg_PS_Damage[udg_PS_Index_Max] = (GetHeroInt(caster,true))*2*ablev *BOOST(pid)
        set udg_PS_Range[udg_PS_Index_Max] = (700 +150*ablev) *LBOOST(pid)
        set udg_PS_Speed[udg_PS_Index_Max] = 25.+2*ablev
        set udg_PS_HitRange[udg_PS_Index_Max] = 150
        set udg_PS_Dummy[udg_PS_Index_Max] = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h00L', x, y, udg_PS_Angle[udg_PS_Index_Max] )
        set udg_PS_Dummy_Effect[udg_PS_Index_Max] = AddSpecialEffectTarget("Abilities\\Weapons\\FarseerMissile\\FarseerMissile.mdl", udg_PS_Dummy[udg_PS_Index_Max], "chest")
        call SetUnitXBounded(udg_PS_Dummy[udg_PS_Index_Max], x)
        call SetUnitYBounded(udg_PS_Dummy[udg_PS_Index_Max], y)
        call UnitAddAbilityBJ( 'Amrf', udg_PS_Dummy[udg_PS_Index_Max] )
        call UnitRemoveAbilityBJ( 'Amrf', udg_PS_Dummy[udg_PS_Index_Max] )
        call SetUnitFlyHeightBJ( udg_PS_Dummy[udg_PS_Index_Max], 30.00, 0.00 )
        call SetUnitScalePercent( udg_PS_Dummy[udg_PS_Index_Max], 100 +20*ablev, 100 +20*ablev, 100 +20*ablev )

    //master of elements
    elseif sid == 'A0J8' then // fire
        call PauseTimer(lightningtimer[pid])
        call SetPlayerAbilityAvailable(p, 'A0JZ', true)
        call SetPlayerAbilityAvailable(p, 'A0JX', false)
        call SetPlayerAbilityAvailable(p, 'A0JV', false)
        call SetPlayerAbilityAvailable(p, 'A0JY', false)
        call SetPlayerAbilityAvailable(p, 'A0JW', false)
        call SetPlayerAbilityAvailable(p, 'S000', false)
        call DestroyEffect(lightningeffect[pid])
        call DestroyEffect(lightningeffect[pid * 8])
        set lightningeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Fire Uber.mdx", caster, "right hand")
        set lightningeffect[pid * 8] = AddSpecialEffectTarget("war3mapImported\\Fire Uber.mdx", caster, "left hand")
    elseif sid == 'A0J6' then // ice
        call PauseTimer(lightningtimer[pid])
        call SetPlayerAbilityAvailable(p, 'A0JZ', false)
        call SetPlayerAbilityAvailable(p, 'S000', true)
        call SetPlayerAbilityAvailable(p, 'A0JV', true)
        call SetPlayerAbilityAvailable(p, 'A0JY', false)
        call SetPlayerAbilityAvailable(p, 'A0JW', false)
        call BlzUnitHideAbility(Hero[pid], 'S000', true)
        call DestroyEffect(lightningeffect[pid])
        call DestroyEffect(lightningeffect[pid * 8])
        set lightningeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Water High.mdx", caster, "right hand")
        set lightningeffect[pid * 8] = AddSpecialEffectTarget("war3mapImported\\Water High.mdx", caster, "left hand")
    elseif sid == 'A0J9' then //lightning
        //call PauseTimer(lightningtimer[pid])
        call SetPlayerAbilityAvailable(p, 'A0JZ', false)
        call SetPlayerAbilityAvailable(p, 'A0JX', false)
        call SetPlayerAbilityAvailable(p, 'A0JV', false)
        call SetPlayerAbilityAvailable(p, 'A0JY', true)
        call SetPlayerAbilityAvailable(p, 'A0JW', false)
        call SetPlayerAbilityAvailable(p, 'S000', false)
        call DestroyEffect(lightningeffect[pid])
        call DestroyEffect(lightningeffect[pid * 8])
        set lightningeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Storm Cast.mdx", caster, "right hand")
        set lightningeffect[pid * 8] = AddSpecialEffectTarget("war3mapImported\\Storm Cast.mdx", caster, "left hand")

        call SaveInteger(MiscHash, 0, GetHandleId(lightningtimer[pid]), pid)
        call TimerStart(lightningtimer[pid], 4. - 1 * boost, true, function Electrocute)
    elseif sid == 'A0JA' then //earth
        call PauseTimer(lightningtimer[pid])
        call SetPlayerAbilityAvailable(p, 'A0JZ', false)
        call SetPlayerAbilityAvailable(p, 'A0JX', false)
        call SetPlayerAbilityAvailable(p, 'A0JV', false)
        call SetPlayerAbilityAvailable(p, 'A0JY', false)
        call SetPlayerAbilityAvailable(p, 'A0JW', true)
        call SetPlayerAbilityAvailable(p, 'S000', false)
        call DestroyEffect(lightningeffect[pid])
        call DestroyEffect(lightningeffect[pid * 8])
        set lightningeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Earth High.mdx", caster, "right hand")
        set lightningeffect[pid * 8] = AddSpecialEffectTarget("war3mapImported\\Earth High.mdx", caster, "left hand")
	
	elseif sid == 'A011' then //Frozen Orb
        set udg_PS_Index_Max = ( udg_PS_Index_Max + 1 )
        set udg_PS_Caster[udg_PS_Index_Max] = caster
        set udg_PS_HitEffect[udg_PS_Index_Max] = "war3mapImported\\FrostNova.mdx"
        set udg_PS_Angle[udg_PS_Index_Max] = bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set udg_PS_Aoe[udg_PS_Index_Max] = 400. * LBOOST(pid)
        set udg_PS_HitTerrain[udg_PS_Index_Max] = false
        set udg_PS_NoHitEff[udg_PS_Index_Max] = false
        set udg_PS_Pierce[udg_PS_Index_Max] = false
        set udg_PS_Damage[udg_PS_Index_Max] = GetHeroInt(caster, true) * 3 * GetUnitAbilityLevel(caster, 'A011') * boost
        set udg_PS_Range[udg_PS_Index_Max] = 1000.
        set udg_PS_Speed[udg_PS_Index_Max] = 6.5
        set udg_PS_HitRange[udg_PS_Index_Max] = 0.
        set udg_PS_DamagedUnits[udg_PS_Index_Max] = CreateGroup()
        set udg_PS_Dummy[udg_PS_Index_Max] = CreateUnit( Player(PLAYER_NEUTRAL_PASSIVE), 'h00L', x, y, udg_PS_Angle[udg_PS_Index_Max] )
        set udg_PS_BuffEffect[udg_PS_Index_Max] = true
        set udg_PS_BuffEffectTrigger[udg_PS_Index_Max] = frozenorb
        set MISSILE_EXPIRE_AOE[udg_PS_Index_Max] = true
        call SetUnitXBounded(udg_PS_Dummy[udg_PS_Index_Max], x + 75 * Cos(udg_PS_Angle[udg_PS_Index_Max] * bj_DEGTORAD))
        call SetUnitYBounded(udg_PS_Dummy[udg_PS_Index_Max], y + 75 * Sin(udg_PS_Angle[udg_PS_Index_Max] * bj_DEGTORAD))
        set udg_PS_Dummy_Effect[udg_PS_Index_Max] = AddSpecialEffectTarget("war3mapImported\\FrostOrb.mdx", udg_PS_Dummy[udg_PS_Index_Max], "origin" )
        call SetUnitScalePercent( udg_PS_Dummy[udg_PS_Index_Max], 130., 130., 130. )
        call UnitAddAbilityBJ( 'Amrf', udg_PS_Dummy[udg_PS_Index_Max] )
        call UnitRemoveAbilityBJ( 'Amrf', udg_PS_Dummy[udg_PS_Index_Max] )
        call SetUnitFlyHeightBJ( udg_PS_Dummy[udg_PS_Index_Max], 65.00, 0.00 )
        set t = NewTimerEx(pid)
        call SaveUnitHandle(MiscHash, 0, GetHandleId(t), udg_PS_Dummy[udg_PS_Index_Max])
        call TimerStart(t, 1, true, function FrozenOrbIcicle)
        
    elseif sid == 'A032' then //Armor of the Elements
        set dmg = (BlzGetUnitMaxHP(caster) / 10. + GetHeroInt(caster, true) * (2.9 + 0.1 * ablev)) * boost
    
        call Shield(caster, dmg, 15)
        
    elseif sid == 'A04H' then //Elemental Storm
        set t = NewTimerEx(pid)
        
        call SaveReal(MiscHash, GetHandleId(t), 0, GetSpellTargetX())
        call SaveReal(MiscHash, GetHandleId(t), 1, GetSpellTargetY())
        call SaveInteger(MiscHash, GetHandleId(t), 2, 3 + ablev * 3)
        
        call TimerStart(t, 0.5, true, function ElementalStorm)
    
    /*/*======================
        Oblivion Guard
    ======================*/*/
    
    elseif sid == 'A07O' then //Meteor
        if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
            set pt = TimerList[pid].addTimer(pid)
            set pt.x = GetSpellTargetX()
            set pt.y = GetSpellTargetY()
            
            call BlzPauseUnitEx(caster, true)
            call SetUnitAnimation(caster, "death")
            call SetUnitTimeScale(caster, 2)
            call Fade(caster, 33, 0.03, 1)
            set bj_lastCreatedEffect = AddSpecialEffect("Units\\Demon\\Infernal\\InfernalBirth.mdl", pt.x, pt.y)
            call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 2.5)
            call DestroyEffectTimed(bj_lastCreatedEffect, 2.)
            call BlzSetSpecialEffectYaw(bj_lastCreatedEffect, Atan2(pt.y - GetUnitY(caster), pt.x - GetUnitX(caster)))
            
            call TimerStart(pt.getTimer(), 0.9, false, function MeteorExpire)
        else
            call SetUnitPosition(caster, x, y)
            call DisplayTextToPlayer(p,0,0,"Cannot target there")
        endif
        
    elseif sid == 'A05S' then //Infernal Strikes
        set infernalStrikes[pid] = 3
        call PauseTimer(infernalStrikeTimer[pid])
        call TimerStart(infernalStrikeTimer[pid], 10, false, function InfernalStrikesExpire)
        
    elseif sid == 'A05R' then //Magnetic Stance
        call SetUnitVertexColor(Hero[pid], 255, 25, 25, 255)
        call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Call of Dread Red.mdx", Hero[pid], "origin"))
        call BlzUnitHideAbility(Hero[pid], 'A05R', true)
        call UnitAddAbility(Hero[pid], 'A05T')
        call UnitAddAbility(Hero[pid], 'A05W')
        call BlzUnitHideAbility(Hero[pid], 'A05W', true)
        call SetUnitAbilityLevel(Hero[pid], 'A05T', ablev)
        call TimerStart(NewTimerEx(pid), 1., true, function MagneticStanceAggro)
        call TimerStart(NewTimerEx(pid), 0.1, true, function MagneticStancePull)
        
        
    elseif sid == 'A05T' then //Magnetic Stance Second Cast
        set dmg = GetHeroStr(Hero[pid], true) * (5 + ablev)
        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 500. * boost, Condition(function FilterEnemy))
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call DummyCastTarget(p, target, 'A08U', 1, GetUnitX(target), GetUnitY(target), "slow")
            call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    
        call UnitRemoveAbility(Hero[pid], 'A05W')
        call UnitRemoveAbility(Hero[pid], 'B02E')
        call SetUnitVertexColor(Hero[pid], 255, 255, 255, 255)
        call DestroyEffect(AddSpecialEffect("war3mapImported\\RedAftershock.mdx", GetUnitX(Hero[pid]), GetUnitY(Hero[pid])))
        call UnitRemoveAbility(Hero[pid], 'A05T')
        call BlzUnitHideAbility(Hero[pid], 'A05R', false)
        call BlzStartUnitAbilityCooldown(Hero[pid], 'A05R', 20)
    
    elseif sid == 'A0GJ' then //Gatekeeper's Pact
        call BlzPauseUnitEx(caster, true)
        call DestroyEffectTimed(AddSpecialEffect("war3mapImported\\AnnihilationTarget.mdx", x, y), 2)
        call TimerStart(NewTimerEx(pid), 2, false, function GatekeepersPact)
        
    /*/*/*====================
        Dark Summoner
    ====================*/*/*/
    
    elseif sid == 'A022' then //Recall
        call RecallSummons(pid)
        
    elseif sid == 'A0K1' then //Demonic Sacrifice
        if GetOwningPlayer(target) == p then
            if GetUnitTypeId(target) == SUMMON_HOUND then //demon hound
                call SummonExpire(target)
                call BlzGroupAddGroupFast(SummonGroup, ug)
                
                loop
                    set target = FirstOfGroup(ug)
                    exitwhen target == null
                    call GroupRemoveUnit(ug, target)
                    if GetOwningPlayer(target) == p then
                        set heal = BlzGetUnitMaxHP(target) * .30 * boost
                        call HP(target, heal)
                    endif
                endloop
            elseif GetUnitTypeId(target)== SUMMON_GOLEM then //meat golem
                call UnitAddAbility(caster, 'A0K2')
                call BlzUnitHideAbility(caster, 'A0K2', true)
                
                if golemDevourStacks[pid] < 2 then
                    call SummonExpire(target)
                endif
                
                call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Orc\\AncestralSpirit\\AncestralSpiritCaster.mdl", caster, "origin"), 3)
                call TimerStart(NewTimerEx(pid), 15. * boost, false, function DemonicSarificeExpire)
            elseif GetUnitTypeId(target)== SUMMON_DESTROYER then //destroyer
                call SummonExpire(target)
                set destroyerSacrificeFlag[pid] = true
                
                call BlzGroupAddGroupFast(SummonGroup, ug)
                
                loop
                    set target = FirstOfGroup(ug)
                    exitwhen target == null
                    call GroupRemoveUnit(ug, target)
                    if GetOwningPlayer(target) == p and GetUnitTypeId(target) == SUMMON_HOUND then
                        call SetUnitVertexColor(target, 90, 90, 230, 255)
                        call SetUnitScale(target, 1.15, 1.15, 1.15)
                        call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Call of Dread Purple.mdx", target, "origin"))
                        call SetUnitAbilityLevel(target, 'A06F', 2)
                    endif
                endloop
            endif
        else
            call DisplayTextToPlayer(p, 0, 0, "You must target your own summons!")
        endif

    elseif sid == 'A0KF' then //summon demon hound
        set i = 0

        loop
            exitwhen i >= ablev + 2 //number of hounds

            set angle = GetUnitFacing(caster)
            set pt = TimerList[pid].addTimer(pid)
            set pt.x = x + 150 * Cos(bj_DEGTORAD * angle)
            set pt.y = y + 150 * Sin(bj_DEGTORAD * angle)
            set pt.dur = 60.
            set pt.armor = 60.

            if hounds[pid * 10 + i] == null then
                set hounds[pid * 10 + i] = CreateUnit(p, SUMMON_HOUND, pt.x, pt.y, angle)
            else
                call TimerList[pid].stopAllTimersWithTag(GetUnitId(hounds[pid * 10 + i]))
                call ShowUnit(hounds[pid * 10 + i], true)
                call ReviveHero(hounds[pid * 10 + i], pt.x, pt.y, false)
                call SetUnitScale(hounds[pid * 10 + i], 0.85, 0.85, 0.85)
                call SetUnitPosition(hounds[pid * 10 + i], pt.x, pt.y)
                call BlzSetUnitFacingEx(hounds[pid * 10 + i], angle)
                call SetUnitVertexColor(hounds[pid * 10 + i], 120, 60, 60, 255)
                call UnitSetBonus(hounds[pid * 10 + i], BONUS_ARMOR, 0)
                call SetUnitAbilityLevel(hounds[pid * 10 + i], 'A06F', 1)
            endif

            set pt.tag = GetUnitId(hounds[pid * 10 + i])
            set pt.target = hounds[pid * 10 + i]

            call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", hounds[pid * 10 + i], "origin"), 2.)

            call SummoningImprovement(pid, hounds[pid * 10 + i], 0.2, 0.075, 0.25)

            call SetUnitState(hounds[pid * 10 + i], UNIT_STATE_MANA, GetUnitState(hounds[pid * 10 + i], UNIT_STATE_MAX_MANA))
            call SetWidgetLife(hounds[pid * 10 + i], BlzGetUnitMaxHP(hounds[pid * 10 + i]))

            if destroyerSacrificeFlag[pid] then
                call SetUnitVertexColor(hounds[pid * 10 + i], 90, 90, 230, 255)
                call SetUnitScale(hounds[pid * 10 + i], 1.15, 1.15, 1.15)
                call SetUnitAbilityLevel(hounds[pid * 10 + i], 'A06F', 2)
            endif

            call GroupAddUnit(SummonGroup, hounds[pid * 10 + i])
            call EnterWeather(hounds[pid * 10 + i])

            call SetHeroXP(hounds[pid * 10 + i], R2I(RequiredXP(GetHeroLevel(Hero[pid]) - 1) + ((GetHeroLevel(Hero[pid]) + 1) * pt.dur * 100 / pt.armor) - 1), false)

            call TimerStart(pt.getTimer(), 0.5, true, function SummonDurationXPBar)

            set i = i + 1
        endloop

    elseif sid == 'A0KH' then //summon meat golem
        set angle = GetUnitFacing(caster)
        set pt = TimerList[pid].addTimer(pid)
        set pt.x = x + 150 * Cos(bj_DEGTORAD * angle)
        set pt.y = y + 150 * Sin(bj_DEGTORAD * angle)
        set pt.dur = 180.
        set pt.armor = 180.
        set golemDevourStacks[pid] = 0
        set BorrowedLife[pid * 10] = 0

        if meatgolem[pid] == null then
            set meatgolem[pid] = CreateUnit(p, SUMMON_GOLEM, pt.x, pt.y, angle)
        else
            call TimerList[pid].stopAllTimersWithTag(GetUnitId(meatgolem[pid]))
            call ShowUnit(meatgolem[pid], true)
            call ReviveHero(meatgolem[pid], pt.x, pt.y, false)
            call SetUnitScale(meatgolem[pid], 1., 1., 1.)
            call SetUnitPosition(meatgolem[pid], pt.x, pt.y)
            call BlzSetUnitFacingEx(meatgolem[pid], angle)
            call UnitRemoveAbility(meatgolem[pid], 'A071') //borrowed life
            call UnitRemoveAbility(meatgolem[pid], 'A0B0') //thunder clap
            call UnitRemoveAbility(meatgolem[pid], 'A06O') //magnetic force
            call UnitRemoveAbility(meatgolem[pid], 'A06C') //devour
            call UnitSetBonus(meatgolem[pid], BONUS_ARMOR, 0)
            call UnitSetBonus(meatgolem[pid], BONUS_HERO_STR, 0)
        endif

        call BlzSetHeroProperName(meatgolem[pid], "Meat Golem") 
        set pt.tag = GetUnitId(meatgolem[pid])
        set pt.target = meatgolem[pid]

        call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", meatgolem[pid], "origin"), 2.)

        call SummoningImprovement(pid, meatgolem[pid], 0.4, 0.6, 0)

        call SetWidgetLife(meatgolem[pid], BlzGetUnitMaxHP(meatgolem[pid]))
        call SetUnitState(meatgolem[pid], UNIT_STATE_MANA, GetUnitState(meatgolem[pid], UNIT_STATE_MAX_MANA))

        call EnterWeather(meatgolem[pid])
        call GroupAddUnit(SummonGroup, meatgolem[pid])

        call SetHeroXP(meatgolem[pid], R2I(RequiredXP(GetHeroLevel(Hero[pid]) - 1) + ((GetHeroLevel(Hero[pid]) + 1) * pt.dur * 100 / pt.armor) - 1), false)

        call TimerStart(pt.getTimer(), 0.5, true, function SummonDurationXPBar)
    elseif sid == 'A0KG' then //summon destroyer
        set angle = GetUnitFacing(caster) + 180
        set pt = TimerList[pid].addTimer(pid)
        set pt.x = x + 150 * Cos(bj_DEGTORAD * angle)
        set pt.y = y + 150 * Sin(bj_DEGTORAD * angle)
        set pt.dur = 180.
        set pt.armor = 180.
        set destroyerDevourStacks[pid] = 0
        set BorrowedLife[pid * 10 + 1] = 0
        set destroyerSacrificeFlag[pid] = false

        if destroyer[pid] == null then
            set destroyer[pid] = CreateUnit(p, SUMMON_DESTROYER, pt.x, pt.y, angle + 180)
        else
            call TimerList[pid].stopAllTimersWithTag(GetUnitId(destroyer[pid]))
            call ShowUnit(destroyer[pid], true)
            call ReviveHero(destroyer[pid], pt.x, pt.y, false)
            call SetUnitPosition(destroyer[pid], pt.x, pt.y)
            call BlzSetUnitFacingEx(destroyer[pid], angle + 180)
            call SetUnitAbilityLevel(destroyer[pid], 'A02D', 1)
            call SetUnitAbilityLevel(destroyer[pid], 'A06J', 1)
            call UnitRemoveAbility(destroyer[pid], 'A061') //blink
            call UnitRemoveAbility(destroyer[pid], 'A071') //borrowed life
            call UnitRemoveAbility(destroyer[pid], 'A04Z') //devour
            call UnitSetBonus(destroyer[pid], BONUS_ARMOR, 0)
            call UnitSetBonus(destroyer[pid], BONUS_HERO_STR, 0)
            call UnitSetBonus(destroyer[pid], BONUS_HERO_INT, 0)
        endif

        call BlzSetHeroProperName(destroyer[pid], "Destroyer") 
        set pt.tag = GetUnitId(destroyer[pid])
        set pt.target = destroyer[pid]

        call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", destroyer[pid], "origin"), 2.)

        call SummoningImprovement(pid, destroyer[pid], 0.1, 0.0075, 0.5 * ablev)

        call SetWidgetLife(destroyer[pid], BlzGetUnitMaxHP(destroyer[pid]))
        call SetUnitState(destroyer[pid], UNIT_STATE_MANA, GetUnitState(destroyer[pid], UNIT_STATE_MAX_MANA))

        //revert hounds to normal
        call BlzGroupAddGroupFast(SummonGroup, ug)
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if GetOwningPlayer(target) == p and GetUnitTypeId(target) == SUMMON_HOUND then
                call SetUnitVertexColor(target, 120, 60, 60, 255)
                call SetUnitScale(target, 0.85, 0.85, 0.85)
                call SetUnitAbilityLevel(target, 'A06F', 1)
            endif
        endloop

        call GroupAddUnit(SummonGroup, destroyer[pid])
        call EnterWeather(destroyer[pid])

        call SetHeroXP(destroyer[pid], R2I(RequiredXP(GetHeroLevel(Hero[pid]) - 1) + ((GetHeroLevel(Hero[pid]) + 1) * pt.dur * 100 / pt.armor) - 1), false)

        call TimerStart(pt.getTimer(), 0.5, true, function SummonDurationXPBar)

    elseif sid == 'A0KI' then //Taunt (Meat Golem)

    elseif sid == 'A0B0' then //Thunder Clap (Meat Golem)
		call MakeGroupInRange(pid, ug, x, y, 300., Condition(function FilterEnemy))
		loop
			set target= FirstOfGroup(ug)
			exitwhen target== null
            call DummyCastTarget(p, target, 'A0B4', 1, x, y, "slow")
			call GroupRemoveUnit(ug,target)
		endloop
        
    elseif sid == 'A06C' then //Devour (Meat Golem)
        if GetUnitTypeId(target) == SUMMON_HOUND and GetOwningPlayer(target) == p and golemDevourStacks[pid] < GetUnitAbilityLevel(Hero[pid], 'A063') + 1 then
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", target, "chest"))
            call IssueTargetOrder(CreateUnit(Player(pid - 1), 'h00X', GetUnitX(target), GetUnitY(target), 0), "attack", caster)
            call SummonExpire(target)
        endif
    
    elseif sid == 'A04Z' then //Devour (Destroyer)
        if GetUnitTypeId(target) == SUMMON_HOUND and GetOwningPlayer(target) == p and destroyerDevourStacks[pid] < GetUnitAbilityLevel(Hero[pid], 'A063') + 1 then
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", target, "chest"))
            call IssueTargetOrder(CreateUnit(Player(pid - 1), 'h00X', GetUnitX(target), GetUnitY(target), 0), "attack", caster)
            call SummonExpire(target)
        endif
        
    elseif sid == 'A06O' then //Magnetic Force (meat golem)
        set magneticForceFlag[pid] = true
        call TimerStart(NewTimerEx(pid), 0.05, true, function MagneticForcePull)
        call TimerStart(NewTimerEx(pid), 10., false, function MagneticForceCD)

    elseif sid == 'A071' then //Borrowed Life
        if GetUnitTypeId(target) == SUMMON_HOUND and GetOwningPlayer(target) == p then
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", target, "chest"))
            call SummonExpire(target)

            if ablev == 1 then
                set i = 120
            elseif ablev == 2 then
                set i = 60
            elseif ablev == 3 then
                set i = 30
            elseif ablev == 4 then
                set i = 20
            elseif ablev == 5 then
                set i = 15
            endif

            if GetUnitTypeId(caster) == SUMMON_GOLEM then
                set BorrowedLife[pid * 10] = i
            elseif GetUnitTypeId(caster) == SUMMON_DESTROYER then
                set BorrowedLife[pid * 10 + 1] = i
            endif
        endif
        
    /*/*/*====================
        Bard
    ====================*/*/*/

    elseif sid == 'A025' then //Song of Fatigue
        set BardSong[pid] = 4
        call SetPlayerAbilityAvailable(p, 'S00N', true )
        call SetPlayerAbilityAvailable(p, 'A01A', false )
        call SetPlayerAbilityAvailable(p, 'A09X', false )
        call SetPlayerAbilityAvailable(p, 'A024', false )
        call SongOfWar(pid, true)
    elseif sid == 'A026' then //Song of Harmony
        set BardSong[pid] = 3
        call SetPlayerAbilityAvailable(p, 'S00N', false )
        call SetPlayerAbilityAvailable(p, 'A01A', true )
        call SetPlayerAbilityAvailable(p, 'A09X', false )
        call SetPlayerAbilityAvailable(p, 'A024', false )
        call SongOfWar(pid, true)
    elseif sid == 'A027' then //Song of Peace
        set BardSong[pid] = 2
        call SetPlayerAbilityAvailable(p, 'S00N', false )
        call SetPlayerAbilityAvailable(p, 'A01A', false )
        call SetPlayerAbilityAvailable(p, 'A09X', true )
        call SetPlayerAbilityAvailable(p, 'A024', false )
        call SongOfWar(pid, true)
    elseif sid == 'A02C' then //Song of War
        set BardSong[pid] = 1
        call SetPlayerAbilityAvailable(p, 'S00N', false )
        call SetPlayerAbilityAvailable(p, 'A01A', false )
        call SetPlayerAbilityAvailable(p, 'A09X', false )
        call SetPlayerAbilityAvailable(p, 'A024', true )
        call SongOfWar(pid, false)

    elseif sid == 'A0AZ' then //Encore
        if BardSong[pid] == 1 then //Song of War
            call MakeGroupInRange(pid, ug, x, y, 900.00 * boost, Condition(function FilterAllyHero))
        
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                set tpid = GetPlayerId(GetOwningPlayer(target)) + 1
                if LoadInteger(EncoreTargets, GetHandleId(target), 2) == 0 then
                    set pt = TimerList[tpid].addTimer(tpid)
                    set pt.target = target
                    call SaveInteger(EncoreTargets, GetHandleId(target), 0, 20)
                    call SaveInteger(EncoreTargets, GetHandleId(target), 1, pid)
                    call SaveInteger(EncoreTargets, GetHandleId(target), 2, 6)
                    call SaveEffectHandle(EncoreTargets, GetHandleId(target), 3, AddSpecialEffectTarget("Abilities\\Spells\\Items\\VampiricPotion\\VampPotionCaster.mdl", target, "origin"))
                    call TimerStart(pt.getTimer(), 1, true, function WarEncorePeriodic)
                else
                    call SaveInteger(EncoreTargets, GetHandleId(target), 0, 20)
                    call SaveInteger(EncoreTargets, GetHandleId(target), 1, pid)
                    call SaveInteger(EncoreTargets, GetHandleId(target), 2, 6)
                endif
            endloop
        elseif BardSong[pid] == 3 then //Song of Harmony
            call MakeGroupInRange(pid, ug, x, y, 900.00 * boost, Condition(function FilterAlly))
            
            set heal = GetHeroInt(caster, true) * (.75 + .25 * ablev) *boost
        
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call HP(target, heal)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", target, "origin"))
            endloop
        elseif BardSong[pid] == 2 then //Song of Peace
            call SongOfPeaceEx(pid)
        elseif BardSong[pid] == 4 then //Song of Fatigue
            call MakeGroupInRange(pid, ug, x, y, 900.00 *boost, Condition(function FilterEnemy))
        
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call DummyCastTarget(p, target, 'A0DS', R2I(6 * boost), GetUnitX(target), GetUnitY(target), "thunderbolt")
            endloop
        endif

    elseif sid == 'A02H' then //Melody of Life
        set heal = BardMelodyCost[pid] * (.25 + .25 * ablev) * boost
        if GetUnitTypeId(target) == BACKPACK then
            call HP(Hero[tpid], heal)
            call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", GetUnitX(Hero[tpid]), GetUnitY(Hero[tpid]) ))
        elseif IsUnitAlly(target, p) then
            call HP(target, heal)
            call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", GetUnitX(target), GetUnitY(target) ))
        endif
    elseif sid == 'A02K' then //Tone of Death
        set udg_PS_Index_Max = ( udg_PS_Index_Max + 1 )
        set udg_PS_Caster[udg_PS_Index_Max] = caster
        set udg_PS_HitEffect[udg_PS_Index_Max] = ""
        set udg_PS_Angle[udg_PS_Index_Max] = bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set udg_PS_Aoe[udg_PS_Index_Max] = -1.00
        set udg_PS_HitTerrain[udg_PS_Index_Max] = false
        set udg_PS_NoHitEff[udg_PS_Index_Max] = false
        set udg_PS_Pierce[udg_PS_Index_Max] = true
        set udg_PS_Damage[udg_PS_Index_Max] = 0 //GetHeroInt(caster, true) * ablev *3 * boost
        set udg_PS_Range[udg_PS_Index_Max] = 500.00
        set udg_PS_Speed[udg_PS_Index_Max] = 3.00
        set udg_PS_HitRange[udg_PS_Index_Max] = 0
        set udg_PS_DamagedUnits[udg_PS_Index_Max] = CreateGroup()
        set udg_PS_Dummy[udg_PS_Index_Max] = CreateUnit( Player(PLAYER_NEUTRAL_PASSIVE), 'h00L', x, y, udg_PS_Angle[udg_PS_Index_Max] )
        call SetUnitXBounded(udg_PS_Dummy[udg_PS_Index_Max], x + 150 * Cos(udg_PS_Angle[udg_PS_Index_Max] * bj_DEGTORAD))
        call SetUnitYBounded(udg_PS_Dummy[udg_PS_Index_Max], y + 150 * Sin(udg_PS_Angle[udg_PS_Index_Max] * bj_DEGTORAD))
        set udg_PS_Dummy_Effect[udg_PS_Index_Max] = AddSpecialEffectTarget("war3mapImported\\BlackHoleSpell.mdx", udg_PS_Dummy[udg_PS_Index_Max], "origin" )
        call SetUnitScalePercent( udg_PS_Dummy[udg_PS_Index_Max], 60.00, 60.00, 60.00 )
        set t = NewTimer()
        call SaveInteger(MiscHash, 1, GetHandleId(t), pid)
        call SaveUnitHandle(MiscHash, 0, GetHandleId(t), udg_PS_Dummy[udg_PS_Index_Max])
        call TimerStart(t, 0.03, true, function ToneOfDeath)
        //call UnitAddAbility(udg_PS_Dummy[udg_PS_Index_Max], 'Amrf' )
        //call UnitRemoveAbility(udg_PS_Dummy[udg_PS_Index_Max], 'Amrf' )
        //call SetUnitFlyHeight( udg_PS_Dummy[udg_PS_Index_Max], 0.00, 0.00 )
        
    /*========================
        Elite Marksman
    ========================*/
    
    elseif sid == 'A06I' then //Tri-rocket
        set i = 1
        loop
            exitwhen i > 3
            set udg_PS_Index_Max = ( udg_PS_Index_Max + 1 )
            set udg_PS_Caster[udg_PS_Index_Max] = caster
            set udg_PS_HitEffect[udg_PS_Index_Max] = "Abilities\\Weapons\\GyroCopter\\GyroCopterMissile.mdl"
            set udg_PS_Angle[udg_PS_Index_Max] = ( bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x) + I2R(( ( 15 * i ) - 30 )) )
            set udg_PS_Aoe[udg_PS_Index_Max] = 120.00
            set udg_PS_HitTerrain[udg_PS_Index_Max] = false
            set udg_PS_NoHitEff[udg_PS_Index_Max] = false
            set udg_PS_Pierce[udg_PS_Index_Max] = false
            set udg_PS_Damage[udg_PS_Index_Max] = GetUnitAbilityLevel(udg_PS_Caster[udg_PS_Index_Max],'A06I') * GetHeroAgi(udg_PS_Caster[udg_PS_Index_Max],true) + (UnitGetBonus(udg_PS_Caster[udg_PS_Index_Max],BONUS_DAMAGE) + GetHeroAgi(udg_PS_Caster[udg_PS_Index_Max],true)) * (GetUnitAbilityLevel(udg_PS_Caster[udg_PS_Index_Max],'A06I') * .1)
            set udg_PS_Damage[udg_PS_Index_Max] =  udg_PS_Damage[udg_PS_Index_Max] * boost
            set udg_PS_Range[udg_PS_Index_Max] = 700.00
            set udg_PS_Speed[udg_PS_Index_Max] = 45.00
            set udg_PS_HitRange[udg_PS_Index_Max] = 100.00
            set udg_PS_Dummy[udg_PS_Index_Max] = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h00L', x, y, udg_PS_Angle[udg_PS_Index_Max] )
            call SetUnitXBounded(udg_PS_Dummy[udg_PS_Index_Max], x)
            call SetUnitYBounded(udg_PS_Dummy[udg_PS_Index_Max], y)
            set udg_PS_Dummy_Effect[udg_PS_Index_Max] = AddSpecialEffectTarget("Abilities\\Weapons\\GyroCopter\\GyroCopterMissile.mdl", udg_PS_Dummy[udg_PS_Index_Max], "origin" )
            call SetUnitScalePercent( udg_PS_Dummy[udg_PS_Index_Max], 100.00, 100.00, 100.00 )
            set i = i + 1
        endloop
        // Knockback
        set udg_A_CB_Index_Max = ( udg_A_CB_Index_Max + 1 )
        set udg_A_CB_Caster[udg_A_CB_Index_Max] = caster
        set udg_A_CB_Range[udg_A_CB_Index_Max] = 250.00
        set udg_A_CB_Angle[udg_A_CB_Index_Max] = ( bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x) - 180 )
        set udg_A_CB_Dmg[udg_A_CB_Index_Max] = -1.00
        set udg_A_CB_Animation[udg_A_CB_Index_Max] = false
        set udg_A_CB_Moving[udg_A_CB_Index_Max] = false
        
        /*if GetUnitTypeId(caster) == HERO_MARKSMAN_SNIPER then
            call TimerStart(NewTimerEx(pid), 3., false, function TriRocketCD)
        endif*/
        
    elseif sid == 'A049' then //Sniper Stance
        if sniperstance[pid] == false then
            set sniperstance[pid] = true
            call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 0, 3.)
            call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 1, 3.)
            call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 2, 3.)
            call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 3, 3.)
            call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 4, 3.)
        else
            set sniperstance[pid] = false
            call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 0, 6.)
            call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 1, 6.)
            call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 2, 6.)
            call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 3, 6.)
            call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 4, 6.)
        endif

        call UpdateTooltips()
        call UnitAddAbility(caster, 'Avul')
        call GroupRemoveUnit(AffectedByWeather, Hero[pid])
        call TimerStart(NewTimerEx(pid), 0.03, false, function StanceAbilityDelay)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\Defend\\DefendCaster.mdl", caster, "origin"))
        
    elseif sid == 'A0J4' then //Hand Grenade
        if GetWidgetLife(helicopter[pid]) >= 0.406 then
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Flare\\FlareCaster.mdl", x, y))
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Flare\\FlareTarget.mdl", GetSpellTargetX(), GetSpellTargetY()))
            set FlightTarget[pid]= GetSpellTargetLoc()
            call TimerStart(NewTimerEx(pid), 2., false, function HeliRocket)
        else
            set grenade[pid] = GetDummy(x, y, 0, 0, 0)
            call BlzSetUnitSkin(grenade[pid], 'h03J')
            call SetUnitScale(grenade[pid], 1.5, 1.5, 1.5)
            set grenadedelay[pid] = 0
            set udg_DashAngleR[pid]=Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
            set FlightTarget[pid]= GetSpellTargetLoc()
            set udg_DashDistance[pid]= SquareRoot(Pow(GetSpellTargetX() - x, 2) + Pow(GetSpellTargetY() - y, 2))
            set initDistance[pid] = udg_DashDistance[pid]
        endif
        
    elseif sid == 'A06V' then //U 235 Shell
        set i = 1
        set i2 = 1
        set angle = bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set g = CreateGroup()
        set dmg = ((GetUnitAbilityLevel(caster,'A06V') + 2) * (GetHeroAgi(caster,true) + UnitGetBonus(caster,BONUS_DAMAGE)) + (GetHeroAgi(caster,true) * 5)) * boost
        
        loop
            exitwhen i > 10
            loop
                exitwhen i2 > 3
                set x = GetUnitX(caster) + 175 * i * Cos((angle + 10 * i2 - 20) * bj_DEGTORAD)
                set y = GetUnitY(caster) + 175 * i * Sin((angle + 10 * i2 - 20) * bj_DEGTORAD)
                
                call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", x, y ))
                call MakeGroupInRange(pid, ug, x, y, 150. * boost, Condition(function FilterEnemy))

                loop
                    set target = FirstOfGroup(ug)
                    exitwhen target == null
                    call GroupRemoveUnit(ug, target)
                    if not IsUnitInGroup(target, g) then
                        call GroupAddUnit(g, target)
                    endif
                endloop
                set i2 = i2 + 1
            endloop
            set i = i + 1
            set i2 = 1
        endloop
        
        loop
            set target = FirstOfGroup(g)
            exitwhen target == null
            call GroupRemoveUnit(g, target)
            call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop

        call DestroyGroup(g)
        // Knockback
        set udg_A_CB_Index_Max = ( udg_A_CB_Index_Max + 1 )
        set udg_A_CB_Caster[udg_A_CB_Index_Max] = caster
        set udg_A_CB_Range[udg_A_CB_Index_Max] = 500.00
        set udg_A_CB_Angle[udg_A_CB_Index_Max] = angle + 180.00
        set udg_A_CB_Targets[udg_A_CB_Index_Max] = CreateGroup()
        set udg_A_CB_Dmg[udg_A_CB_Index_Max] = -1.00
        set udg_A_CB_Animation[udg_A_CB_Index_Max] = false
		
	//========================
	//Potions (HP, MP)
	//========================
	
	elseif sid == 'A09C' then //Health Potion (Backpack)
		loop
			exitwhen i > 5
			set itm = UnitItemInSlot(caster, i)
			if GetItemTypeId(itm) == 'I0BJ' then
				call HP(Hero[pid], 10000)
				set i = 6
			elseif GetItemTypeId(itm) == 'I028' then
				call HP(Hero[pid], 2000)
				set i = 6
			elseif GetItemTypeId(itm) == 'pghe' then
				call HP(Hero[pid], 500)
				set i = 6
            elseif GetItemTypeId(itm) == 'I0MP' then
				call HP(Hero[pid], 50000)
				call pheal(Hero[pid], .08, .08)
				set i = 6
			elseif GetItemTypeId(itm) == 'I0MQ' then
				call pheal(Hero[pid], .15, 0)
				set i = 6
			endif
            set i = i + 1
		endloop
	
		if i == 6 then
			call DisplayTextToPlayer(p,0,0, "You do not have a potion to consume.")
		elseif i == 7 then
			if GetItemCharges(itm) < 2 then
				call RemoveItem(itm)
			else
				call SetItemCharges(itm, GetItemCharges(itm) - 1)
			endif
		endif
	elseif sid == 'A0FS' then //Mana Potion (Backpack)
		loop
			exitwhen i > 5
			set itm = UnitItemInSlot(caster, i)
			if GetItemTypeId(itm) == 'I0BL' then
				call MP(Hero[pid], 10000)
				set i = 6
			elseif GetItemTypeId(itm) == 'I00D' then
				call MP(Hero[pid], 2000)
				set i = 6
			elseif GetItemTypeId(itm) == 'pgma' then
				call MP(Hero[pid], 500)
				set i = 6
            elseif GetItemTypeId(itm) == 'I0MP' then
				call HP(Hero[pid], 50000)
				call pheal(Hero[pid], .08, .08)
				set i = 6
			endif
			set i = i + 1
		endloop
	
		if i == 6 then
			call DisplayTextToPlayer(p,0,0, "You do not have a potion to consume.")
		elseif i == 7 then
			if GetItemCharges(itm) < 2 then
				call RemoveItem(itm)
			else
				call SetItemCharges(itm, GetItemCharges(itm) - 1)
			endif
		endif
        
    elseif sid == 'A05N' then //Unique Consumable (Backpack)
		loop
			exitwhen i > 5
			set itm = UnitItemInSlot(caster, i)
			if GetItemTypeId(itm) == 'vamp' then
                if GetWidgetLife(Hero[pid]) >= 0.406 then
                    set VampiricPotion.add(Hero[pid], Hero[pid]).duration = 10.
                endif
				set i = 6
			elseif GetItemTypeId(itm) == 'I027' then
                call DummyCastTarget(p, Hero[pid], 'A05P', 1, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), "invisibility")
				set i = 6
			endif
			set i = i + 1
		endloop
	
		if i == 6 then
			call DisplayTextToPlayer(p,0,0, "You do not have a consumable.")
		elseif i == 7 then
			if GetItemCharges(itm) < 2 then
				call RemoveItem(itm)
			else
				call SetItemCharges(itm, GetItemCharges(itm) - 1)
			endif
		endif
		
	//========================
	//Misc
	//========================
		
	elseif sid == 'A09G' then //Free Dobby
		call RemoveUnit(caster)
		call DisplayTextToPlayer(p, 0, 0, "The worker has gone home to live out his life in peace.")
		
	elseif sid == 'A0A9' or sid == 'A0A8' or sid == 'A0A7' or sid == 'A0A6' or sid == 'S001' or sid == 'A0A5' then //Castle of the Gods
		if udg_Chaos_World_On then
			call IssueImmediateOrder(caster, "stop")
			call DisplayTimedTextToPlayer(p, 0, 0, 10.00, "With the Gods dead, the Castle of Gods can no longer draw enough power from them in order to use its abilities." )
		endif
        
    elseif sid == 'A0JI' then //Hero Selection UI
        call Scroll(p, -1)
        
    elseif sid == 'A0JQ' then
        call Scroll(p, 1)
        
    elseif sid == 'A0JR' then
        set hssort[pid] = true
        set hsstat[pid] = 3
        call Scroll(p, 1)
        
    elseif sid == 'A0JS' then
        set hssort[pid] = true
        set hsstat[pid] = 1
        call Scroll(p, 1)
        
    elseif sid == 'A0JT' then
        set hssort[pid] = true
        set hsstat[pid] = 2
        call Scroll(p, 1)
        
    elseif sid == 'A0JU' then //sort
        set hssort[pid] = false

    elseif sid == hsselectid[hslook[pid]] then //pick hero
        call Selection(pid, hsskinid[hslook[pid]])

    elseif sid == 'A042' or sid == 'A044' or sid == 'A045' then //Grave Revive
        if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
            
            call PauseTimer(HeroGraveTimer[pid])

            call BlzSetSpecialEffectScale(HeroReviveIndicator[pid], 0)
            call DestroyEffect(HeroReviveIndicator[pid])
            call RecycleDummy(HeroTimedLife[pid])
            set HeroTimedLife[pid] = null
            
            if sid == 'A042' then //item revival
                set itm = GetResurrectionItem(pid, false)
                set heal = ItemData[GetItemTypeId(itm)][StringHash("res")] * 0.01
            
                call SetItemCharges(itm, GetItemCharges(itm) - 1)
                
                if ItemData[GetItemTypeId(itm)][StringHash("recharge")] == 0 and GetItemCharges(itm) == 0 then
                    call UnitRemoveItem(Hero[pid], itm)
                    call RemoveItem(itm)
                endif
                
                call RevivePlayer(pid, GetSpellTargetX(), GetSpellTargetY(), heal, heal)
            elseif sid == 'A044' then //pr reincarnation
                call RevivePlayer(pid, GetSpellTargetX(), GetSpellTargetY(), 100, 100)
                call BlzUnitHideAbility(Hero[pid], 'A04A', true)
                call UnitDisableAbility(Hero[pid], 'A047', false)
                call IssueImmediateOrder(Hero[pid], "avatar")
                set ReincarnationPRCD[pid] = 299
            elseif sid == 'A045' then //high priestess revival
                set heal = 20 + 10 * GetUnitAbilityLevel(Hero[ResurrectionRevival[pid]], 'A048')
                call RevivePlayer(pid, GetSpellTargetX(), GetSpellTargetY(), heal, heal)
                set ResurrectionCD[ResurrectionRevival[pid]] = 600 - 100 * GetUnitAbilityLevel(Hero[ResurrectionRevival[pid]], 'A048')
            endif
            
            if sid != 'A045' and ResurrectionRevival[pid] > 0 then //refund HP cooldown
                set ResurrectionCD[ResurrectionRevival[pid]] = 1
            endif
            
            set ReincarnationRevival[pid] = false
            set ResurrectionRevival[pid] = 0
            call UnitRemoveAbility(HeroGrave[pid], 'A042')
            call UnitRemoveAbility(HeroGrave[pid], 'A044')
            call UnitRemoveAbility(HeroGrave[pid], 'A045')
            call SetUnitPosition(HeroGrave[pid], 30000, 30000)
            call ShowUnit(HeroGrave[pid], false)
        else
            call DisplayTextToPlayer(p, 0, 0, "Cannot target there")
        endif
	endif
	
	if nocd[pid] then //No Cooldowns
        call TimerStart(NewTimerEx(pid), 0.05, false, function ResetCD)
	endif

    if nocost[pid] then //No Manacost
        call SetUnitState(Hero[pid], UNIT_STATE_MANA, GetUnitState(Hero[pid], UNIT_STATE_MAX_MANA))
	endif
	
	call RemoveLocation(loc)
	call DestroyGroup(ug)
	
	set caster = null
	set target = null
	set p = null
	set loc = null
	set itm = null
	set ug = null
	set u = null
	set g = null
	set t = null
endfunction

//===========================================================================
function SpellsInit takes nothing returns nothing
    local trigger spell = CreateTrigger()
    local trigger onenemyspell = CreateTrigger()
	local trigger cast = CreateTrigger()
	local trigger finish = CreateTrigger()
    local trigger learn = CreateTrigger()
	local trigger skinbuttonclick = CreateTrigger()
    local trigger cosmeticbuttonclick = CreateTrigger()
    local trigger heropanelclick = CreateTrigger()
    local trigger votekickpanelclick = CreateTrigger()
	local integer pid
    local User u = User.first
	
	loop
		exitwhen u == User.NULL
        set pid = GetPlayerId(u.toPlayer()) + 1
		set dChangeSkin[pid] = DialogCreate()
        set dCosmetics[pid] = DialogCreate()
        set markedfordeath[pid] = CreateGroup()
        set lightningtimer[pid] = CreateTimer()
        set heropanel[pid] = DialogCreate()
        set votekickpanel[pid] = DialogCreate()
        set whirlpooled[pid] = CreateGroup()
        set aotePush[pid] = CreateGroup()
        set medeanLightningHit[pid] = CreateGroup()
        set ProtectionGroup[pid] = CreateGroup()
        set ArcaneBarrageHit[pid] = CreateGroup()
        set PhoenixHit[pid] = CreateGroup()
        set ProvokeTargets[pid] = CreateGroup()
        set attargets[pid] = CreateGroup()
        set destroyertimer[pid] = CreateTimer()
        set infernalStrikeTimer[pid] = CreateTimer()
        set darkSealTargets[pid] = CreateGroup()
        set darkSealTargets[pid * 8] = CreateGroup()
        set StasisFieldTargets[pid] = CreateGroup()
        set arcanosphereGroup[pid] = CreateGroup()
        set magnetic_stance_group[pid] = CreateGroup()
		call TriggerRegisterDialogEvent(skinbuttonclick, dChangeSkin[pid])
        call TriggerRegisterDialogEvent(cosmeticbuttonclick, dCosmetics[pid])
        call TriggerRegisterDialogEvent(heropanelclick, heropanel[pid])
        call TriggerRegisterDialogEvent(votekickpanelclick, votekickpanel[pid])
		call TriggerRegisterPlayerUnitEvent(spell, u.toPlayer(), EVENT_PLAYER_UNIT_SPELL_EFFECT, function boolexp)
		call TriggerRegisterPlayerUnitEvent(cast, u.toPlayer(), EVENT_PLAYER_UNIT_SPELL_CAST, function boolexp)
		call TriggerRegisterPlayerUnitEvent(finish, u.toPlayer(), EVENT_PLAYER_UNIT_SPELL_FINISH, function boolexp)
        call TriggerRegisterPlayerUnitEvent(learn, u.toPlayer(), EVENT_PLAYER_HERO_SKILL, function boolexp)
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A0JV', false) //elementalist setup
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A0JX', false)
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A0JW', false)
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A0JZ', false)
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A0JY', false)
        call SetPlayerAbilityAvailable(u.toPlayer(), 'S000', false)
		call SetPlayerAbilityAvailable(u.toPlayer(),prMulti[1],false) //pr setup
		call SetPlayerAbilityAvailable(u.toPlayer(),prMulti[2],false)
		call SetPlayerAbilityAvailable(u.toPlayer(),prMulti[3],false)
		call SetPlayerAbilityAvailable(u.toPlayer(),prMulti[4],false)
		call SetPlayerAbilityAvailable(u.toPlayer(),prMulti[5],false)
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A01A', false ) 
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A09X', false ) //bard setup
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A024', false )
		call SetPlayerAbilityAvailable(u.toPlayer(),'A0AP',false)
        call SetPlayerAbilityAvailable(u.toPlayer(), 'S00N', false)
        call SetPlayerAbilityAvailable(u.toPlayer(), DETECT_LEAVE_ABILITY, false)
		set u = u.next
	endloop
    
    call SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), 'A01A', false )
    call SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), 'A024', false )
    call SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), 'A09X', false )
    call SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), 'S00N', false )
    call SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), DETECT_LEAVE_ABILITY, false)
    call TriggerRegisterPlayerUnitEvent(onenemyspell, pfoe, EVENT_PLAYER_UNIT_SPELL_EFFECT, function boolexp)
    call TriggerAddAction(onenemyspell, function EnemySpells)
	
	call TriggerAddCondition(skinbuttonclick, Filter(function SkinButtonClick))
    call TriggerAddCondition(cosmeticbuttonclick, Filter(function CosmeticButtonClick))
    call TriggerAddCondition(heropanelclick, Filter(function HeroPanelClick))
    call TriggerAddCondition(votekickpanelclick, Filter(function VotekickPanelClick))
	
	call TriggerAddAction(spell, function OnEffect)
	call TriggerAddAction(cast, function OnCast)
	call TriggerAddAction(finish, function OnFinish)
    call TriggerAddAction(learn, function OnLearn)
    
    call TriggerAddAction(frozenorb, function FrozenOrb)
    call TriggerAddAction(daggerstorm, function DaggerStorm)
    call TriggerAddAction(phantomslash, function PhantomSlash)
	
    set spell = null
    set onenemyspell = null
	set cast = null
	set finish = null
    set learn = null
	set skinbuttonclick = null
    set cosmeticbuttonclick = null
    set heropanelclick = null
    set votekickpanelclick = null
endfunction

endlibrary
