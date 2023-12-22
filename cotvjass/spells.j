library Spells requires Functions, TimerUtils, Commands, Donator, heroselection, Balance

globals
    HashTable SpellTooltips
	boolean array isteleporting
	dialog array dChangeSkin
    dialog array dCosmetics
	button array dSkin
    button array dCosmetic
	string array dSkinName
	integer array dPage
	integer TOTAL_SKINS
	boolean array ispublic
	constant integer SKINS_PER_PAGE = 6
	boolean array HiddenGuise
    group array StasisFieldTargets
    boolean array stasisFieldActive
	location array FlightTarget
    group array markedfordeath
    boolean array sniperstance
    effect array lightningeffect
    effect array songeffect
    dialog array heropanel
    button array heropanelbutton
    dialog array votekickpanel
    button array votekickpanelbutton
    boolean array hero_panel_on
    integer array DMG_NUMBERS
    boolean array BP_DESELECT
    effect array shield
    unit array shieldtarget
    real array shieldpercent
    real array shieldhp
    real array shieldmax
    group shieldGroup = CreateGroup()
    boolean array aoteCD
    boolean array ReincarnationRevival
    integer array ResurrectionRevival
    boolean array FightMe
    boolean array heliCD
    real array ControlTimeCD
    real array StasisFieldCD
    real array ArcaneShiftCD
    real array SpaceTimeRippleCD
    real array ResurrectionCD
    integer array undyingRageAttackBonus
    group array ArcaneBarrageHit
    group array attargets
    location array attargetpoint
    integer array golemDevourStacks
    integer array destroyerDevourStacks
    boolean array destroyerSacrificeFlag
    boolean array magneticForceFlag
    boolean array overloadActive
    effect array overloadEffect
    boolean array bloodMistActive
    effect array bloodMistEffect
    boolean array arcanosphereActive
    unit array arcanosphere
    group array arcanosphereGroup
    integer array saviorBashCount
    group array magnetic_stance_group
    boolean array PhantomSlashing
    real array BloodBank
    hashtable BloodDomain = InitHashtable()
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
    unit array darkSeal
    boolean array darkSealActive
    real array darkSealBAT
    integer array metaDamageBonus
    real array SteedChargeX
    real array SteedChargeY
    integer array masterElement
    constant integer SONG_WAR = 'A024'
    constant integer SONG_HARMONY = 'A01A'
    constant integer SONG_PEACE = 'A09X'
    constant integer SONG_FATIGUE = 'A00N'
    boolean array altModifier
    integer array BodyOfFireCharges
    integer array lastCast
    integer array limitBreak

    abilityreallevelfield array SPELL_FIELD
    integer SPELL_FIELD_TOTAL = 6
endglobals

function AdaptiveStrikeTornado takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real x = GetUnitX(pt.target)
    local real y = GetUnitY(pt.target)
    local group ug = CreateGroup()
    local unit target = null

    set pt.dur = pt.dur - 1.

    if pt.dur < 0 then
        call SetUnitAnimation(pt.target, "death")
        call TimerList[pid].removePlayerTimer(pt)
    else
        call IssuePointOrder(pt.target, "move", x + 150. * Cos(pt.angle), y + 150. * Sin(pt.angle))
        call MakeGroupInRange(pid, ug, x, y, 200., Condition(function FilterEnemy))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call UnitDamageTarget(Hero[pid], target, pt.dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    endif

    call DestroyGroup(ug)

    set ug = null
endfunction

function AdaptiveStrike takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    call UnitRemoveAbility(pt.caster, ADAPTIVESTRIKE.id2)
    call UnitDisableAbility(pt.caster, ADAPTIVESTRIKE.id, false)

    if lastCast[pid] == 0 then
        call UnitDisableAbility(pt.caster, ADAPTIVESTRIKE.id, true)
        call BlzUnitHideAbility(pt.caster, ADAPTIVESTRIKE.id, false)
    endif

    call TimerList[pid].removePlayerTimer(pt)
endfunction

function WindScarPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real x = GetUnitX(pt.target)
    local real y = GetUnitY(pt.target)
    local group ug = CreateGroup()
    local unit target = null
    local boolean found = false
    local PlayerTimer pt2

    //pt.agi at 0 is default, 1 is limit break

    set pt.dur = pt.dur + 0.05
    set pt.time = pt.time + 1.

    if (pt.dur > 1. and pt.agi == 0) or (pt.dur > 5. and pt.agi == 1) then
        call SetUnitAnimation(pt.target, "death")
        if pt.agi == 0 then
            call BezierCurve(pt.i).destroy()
        endif
        call TimerList[pid].removePlayerTimer(pt)
    else
        if ModuloReal(pt.time, 70.) <= 0.03 then
            call GroupClear(pt.ug)
        endif

        call MakeGroupInRange(pid, ug, x, y, pt.aoe, Condition(function FilterEnemy))
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            set found = true
            call GroupRemoveUnit(ug, target)

            if not IsUnitInGroup(target, pt.ug) then
                call GroupAddUnit(pt.ug, target)
                call UnitDamageTarget(Hero[pid], target, pt.dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
        endloop

        if pt.agi == 1 then
            set pt.angle = pt.angle + bj_PI * 0.045
            call SetUnitXBounded(pt.target, GetUnitX(pt.caster) + 150. * Cos(pt.angle))
            call SetUnitYBounded(pt.target, GetUnitY(pt.caster) + 150. * Sin(pt.angle))
            call BlzSetUnitFacingEx(pt.target, bj_RADTODEG * (pt.angle + bj_PI * 0.5))
        else
            call BezierCurve(pt.i).calcT(pt.dur)
            call SetUnitXBounded(pt.target, BezierCurve(pt.i).X)
            call SetUnitYBounded(pt.target, BezierCurve(pt.i).Y)
        endif
    endif

    call DestroyGroup(ug)

    set ug = null
endfunction

function WindScar takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer i = 0
    local real angle = 0.
    local PlayerTimer pt2

    if limitBreak[pid] == 4 then
        loop
            exitwhen i == 3

            set pt2 = TimerList[pid].addTimer(pid)
            set pt2.ug = CreateGroup()
            set pt2.aoe = 120.
            set pt2.angle = 2. * bj_PI / 3. * i
            set pt2.caster = pt.caster
            set pt2.target = GetDummy(GetUnitX(pt.caster) + 150. * Cos(pt2.angle), GetUnitY(pt.caster) + 150. * Sin(pt2.angle), 0, 0, DUMMY_RECYCLE_TIME)
            set pt2.dmg = pt.spell.values[0]
            set pt2.agi = 1

            call BlzSetUnitSkin(pt2.target, 'h044')
            call SetUnitScale(pt2.target, 0.6, 0.6, 0.6)
            call UnitAddAbility(pt2.target, 'Amrf')
            call SetUnitFlyHeight(pt2.target, 30.00, 0.00)
            call BlzSetUnitFacingEx(pt2.target, bj_RADTODEG * (pt2.angle + bj_PI * 0.5))
            call SetUnitVertexColor(pt2.target, 255, 255, 0, 255)

            call TimerStart(pt2.timer, 0.03, true, function WindScarPeriodic)
            set i = i + 1
        endloop
    else
        call SoundHandler("Abilities\\Spells\\Orc\\Shockwave\\Shockwave.flac", true, null, pt.caster)

        set i = -1
        set angle = pt.angle

        loop
            exitwhen i > 1

            set pt2 = TimerList[pid].addTimer(pid)
            set pt2.ug = CreateGroup()
            set pt2.aoe = 150.
            set pt2.angle = angle + i / 4. * bj_PI
            set pt2.target = GetDummy(GetUnitX(pt.caster) + 100. * Cos(pt2.angle), GetUnitY(pt.caster) + 100. * Sin(pt2.angle), 0, 0, DUMMY_RECYCLE_TIME)
            set pt2.x = GetUnitX(pt2.target)
            set pt2.y = GetUnitY(pt2.target)
            set pt2.speed = 700.
            set pt2.dmg = pt.spell.values[0]
            set pt2.i = BezierCurve.create()
            //add bezier points
            call BezierCurve(pt2.i).addPoint(pt2.x, pt2.y)
            call BezierCurve(pt2.i).addPoint(pt2.x + pt2.speed * 0.6 * Cos(pt2.angle), pt2.y + pt2.speed * 0.6 * Sin(pt2.angle))
            call BezierCurve(pt2.i).addPoint(pt2.x + pt2.speed * Cos(angle), pt2.y + pt2.speed * Sin(angle))

            call BlzSetUnitSkin(pt2.target, 'h044')
            call SetUnitScale(pt2.target, 1., 1., 1.)
            call UnitAddAbility(pt2.target, 'Amrf')
            call SetUnitFlyHeight(pt2.target, 10.00, 0.00)
            call BlzSetUnitFacingEx(pt2.target, bj_RADTODEG * pt2.angle)

            call TimerStart(pt2.timer, 0.03, true, function WindScarPeriodic)
            set i = i + 1
        endloop

        call SetUnitTimeScale(pt.caster, 1.)
    endif

    call TimerList[pid].removePlayerTimer(pt)
endfunction

function BodyOfFireChargeCD takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer MAX_CHARGES = 5

    set BodyOfFireCharges[pid] = IMinBJ(MAX_CHARGES, BodyOfFireCharges[pid] + 1)
    call UnitDisableAbility(pt.caster, INFERNALSTRIKE.id, false)
    call UnitDisableAbility(pt.caster, MAGNETICSTRIKE.id, false)

    if GetLocalPlayer() == Player(pid - 1) then
        call BlzSetAbilityIcon(BODYOFFIRE.id, "ReplaceableTextures\\CommandButtons\\PASBodyOfFire" + I2S(BodyOfFireCharges[pid]) + ".blp")
    endif

    if BodyOfFireCharges[pid] >= MAX_CHARGES then
        call BlzStartUnitAbilityCooldown(pt.caster, BODYOFFIRE.id, 0.)
        call TimerList[pid].removePlayerTimer(pt)
    else
        call BlzStartUnitAbilityCooldown(pt.caster, BODYOFFIRE.id, 10.)
    endif
endfunction

function Grow takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    set pt.dur = pt.dur - 1
    set pt.dmg = pt.dmg + 0.008

    if pt.dur > 0 then
        call SetUnitScale(pt.caster, pt.dmg, pt.dmg, pt.dmg)
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif
endfunction

function GaiaArmorExpire takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    call TimerList[pid].removePlayerTimer(pt)
endfunction

function FlameBreathPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real mp = GetUnitState(Hero[pid], UNIT_STATE_MANA)
    local group ug = CreateGroup()
    local unit target = null
    local real x = GetUnitX(Hero[pid])
    local real y = GetUnitY(Hero[pid])

    //trapezoid
    local real Ax = x + 50 * Cos(pt.angle + bj_PI * 0.5)
    local real Ay = y + 50 * Sin(pt.angle + bj_PI * 0.5)
    local real Bx = x + 50 * Cos(pt.angle - bj_PI * 0.5)
    local real By = y + 50 * Sin(pt.angle - bj_PI * 0.5)
    local real Cx = Bx + pt.aoe * Cos(pt.angle - bj_PI * 0.125) * LBOOST[pid]
    local real Cy = By + pt.aoe * Sin(pt.angle - bj_PI * 0.125) * LBOOST[pid]
    local real Dx = Ax + pt.aoe * Cos(pt.angle + bj_PI * 0.125) * LBOOST[pid]
    local real Dy = Ay + pt.aoe * Sin(pt.angle + bj_PI * 0.125) * LBOOST[pid]
    local real AB
    local real BC
    local real CD
    local real DA

    set pt.dur = pt.dur + 1

    call MakeGroupInRange(pid, ug, x, y, pt.aoe * LBOOST[pid], Condition(function FilterEnemy))

    if GetUnitCurrentOrder(Hero[pid]) == OrderId("clusterrockets") and GetWidgetLife(Hero[pid]) >= .406 and mp >= BlzGetUnitMaxMana(Hero[pid]) * 0.025 then
        if ModuloReal(pt.dur, 2.) == 0 then
            call SetUnitState(Hero[pid], UNIT_STATE_MANA, mp - BlzGetUnitMaxMana(Hero[pid]) * 0.025)
        endif
        if ModuloReal(pt.dur, 5.) == 0 then
            call SoundHandler("Abilities\\Spells\\Other\\BreathOfFire\\BreathOfFire1.flac", true, null, Hero[pid])
        endif

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)

            set x = GetUnitX(target)
            set y = GetUnitY(target)

            set AB = (y - By) * (Ax - Bx) - (x - Bx) * (Ay - By)
            set BC = (y - Cy) * (Bx - Cx) - (x - Cx) * (By - Cy)
            set CD = (y - Dy) * (Cx - Dx) - (x - Dx) * (Cy - Dy)
            set DA = (y - Ay) * (Dx - Ax) - (x - Ax) * (Dy - Ay)
            
            if (AB >= 0 and BC >= 0 and CD >= 0 and DA >= 0) or (AB <= 0 and BC <= 0 and CD <= 0 and DA <= 0) then
                call UnitDamageTarget(Hero[pid], target, pt.dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
        endloop
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
endfunction

function HiddenGuiseExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())

    call ShowUnit(Hero[pid], true)
    call Item.assign(UnitAddItemById(Hero[pid], 'I0OW'))
    call reselect(Hero[pid])
    set HiddenGuise[pid] = true
endfunction

function HandGrenadePeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null
    local real x = GetUnitX(pt.target)
    local real y = GetUnitY(pt.target)

    set pt.dur = pt.dur - pt.speed

    if pt.dur > 0 then
        call SetUnitXBounded(pt.target, x + pt.speed * Cos(pt.angle))
        call SetUnitYBounded(pt.target, y + pt.speed * Sin(pt.angle))
        call SetUnitFlyHeight(pt.target, RMaxBJ(50 + pt.armor * (1. - pt.dur / pt.armor) * pt.dur / pt.armor * 1.3, 1.), 0)
    elseif pt.dur > -66 * pt.speed then
        call SetUnitTimeScalePercent(pt.target, 0)
    else
        //explode
        call MakeGroupInRange(pid, ug, x, y, pt.aoe, Condition(function FilterEnemy))
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call StunUnit(pid, target, 3.)
            call UnitDamageTarget(Hero[pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    
        call SetUnitAnimation(pt.target, "death")
        call DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
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

    set pt.dmg = (0.05 + ablev * 0.05) * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroAgi(Hero[pid], true)) * BOOST[pid]
    set pt.dur = 5
    set pt.target = target

    call TimerStart(pt.timer, 1., true, function SearingArrowBurn)
endfunction

function DashPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null
    local real x = GetUnitX(pt.caster)
    local real y = GetUnitY(pt.caster)

    set pt.dur = pt.dur - pt.speed

    if pt.dur > 0 and IsUnitInRangeXY(pt.caster, pt.x, pt.y, pt.dur + 500.) then
        //movement
        call SetUnitXBounded(pt.target, x + pt.speed * Cos(pt.angle))
        call SetUnitYBounded(pt.target, y + pt.speed * Sin(pt.angle))
        call SetUnitXBounded(pt.caster, x + pt.speed * Cos(pt.angle))
        call SetUnitYBounded(pt.caster, y + pt.speed * Sin(pt.angle))

        call BlzSetUnitFacingEx(pt.target, pt.angle * bj_RADTODEG)

        //phoenix flight
        if HeroID[pid] == HERO_PHOENIX_RANGER then
            call MakeGroupInRange(pid, ug, x, y, pt.aoe, Condition(function FilterEnemy))
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                if IsUnitInGroup(target, pt.ug) == false then
                    call GroupAddUnit(pt.ug, target)
                    call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX(target), GetUnitY(target)))
                    call UnitDamageTarget(pt.caster, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                    if GetUnitAbilityLevel(target, 'B02O') > 0 then
                        call UnitRemoveAbility(target, 'B02O')
                        call SearingArrowIgnite(target, pid)
                    endif
                endif
            endloop
        //thunder dash
        elseif HeroID[pid] == HERO_THUNDERBLADE then
            if pt.dur < (GetUnitAbilityLevel(pt.caster, THUNDERDASH.id) + 3) * 150 - 200 then
                call MakeGroupInRange(pid, ug, x, y, 150.00, Condition(function FilterEnemy))
                //check for impact
                if BlzGroupGetSize(ug) > 0 or IsTerrainWalkable(x + pt.speed * Cos(pt.angle), y + pt.speed * Sin(pt.angle)) == false then 
                    call SetUnitXBounded(pt.caster, x)
                    call SetUnitYBounded(pt.caster, y)
                    set pt.dur = 0
                    call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x, y))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x + 140, y + 140))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x + 140, y - 140))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x - 140, y + 140))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x - 140, y - 140))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x, y))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x + 100, y + 100))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x + 100, y - 100))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x - 100, y + 100))
                    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x - 100, y - 100))
                    call MakeGroupInRange(pid, ug, x, y, pt.aoe, Condition(function FilterEnemy))
                    loop
                        set target = FirstOfGroup(ug)
                        exitwhen target == null
                        call GroupRemoveUnit(ug, target)
                        call UnitDamageTarget(pt.caster, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                    endloop
                endif
            endif
        endif
    else
        call UnitRemoveAbility(pt.caster, 'Avul')
        call ShowUnit(pt.caster, true)
        call reselect(pt.caster)
        call SetUnitPathing(pt.caster, true)
        call SetUnitAnimation(pt.target, "death")
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

function SpinDashRecast takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    call UnitDisableAbility(pt.caster, SPINDASH.id, false)
    call UnitRemoveAbility(pt.caster, SPINDASH.id2)
    call BlzStartUnitAbilityCooldown(pt.caster, SPINDASH.id, 3.)

    call TimerList[pid].removePlayerTimer(pt)
endfunction

function SpinDashPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null
    local real x = GetUnitX(pt.caster)
    local real y = GetUnitY(pt.caster)

    if pt.dur > 0 and IsUnitInRangeXY(pt.caster, pt.x, pt.y, pt.dur) then
        call SetUnitXBounded(pt.caster, x + pt.speed * Cos(pt.angle))
        call SetUnitYBounded(pt.caster, y + pt.speed * Sin(pt.angle))
        set pt.dur = pt.dur - pt.speed

        call MakeGroupInRange(pid, ug, x, y, 225. * LBOOST[pid], Condition(function FilterEnemy))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)

            if not IsUnitInGroup(target, pt.ug) then
                call GroupAddUnit(pt.ug, target)
                if limitBreak[pid] == 2 then
                    call UnitDamageTarget(pt.caster, target, pt.spell.values[0] * 2. * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                    set SpinDashDebuff.add(pt.caster, target).duration = 2.
                else
                    call UnitDamageTarget(pt.caster, target, pt.spell.values[0] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                endif
            endif
        endloop
    else
        call SetUnitPropWindow(pt.caster, bj_DEGTORAD * 60.)
        call SetUnitTimeScale(pt.caster, 1.)
        call AddUnitAnimationProperties(pt.caster, "spin", false)
        call SetUnitPathing(pt.caster, true)
        call IssueImmediateOrder(pt.caster, "stop")
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
endfunction

function LeapPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null
    local real x = GetUnitX(pt.target)
    local real y = GetUnitY(pt.target)
    local real accel = 0.

    if pt.dur > 0 and IsUnitInRangeXY(pt.target, pt.x, pt.y, pt.dur) then
        set accel = pt.dur / pt.armor
        //movement
        call SetUnitXBounded(pt.target, x + (pt.speed / (1 + accel)) * Cos(pt.angle))
        call SetUnitYBounded(pt.target, y + (pt.speed / (1 + accel)) * Sin(pt.angle))
        set pt.dur = pt.dur - (pt.speed / (1 + accel))

        if pt.dur <= pt.armor - 120 and pt.dur >= pt.armor - 160 then //sick animation
            call SetUnitTimeScale(pt.target, 0)
        endif

        set accel = pt.dur / pt.armor

        call SetUnitFlyHeight(pt.target, 20 + pt.armor * (1. - accel) * accel * 1.3, 0)

        if pt.dur <= 0 then
            if DistanceCoords(x, y, pt.x, pt.y) < 25. then
                call SetUnitXBounded(pt.target, pt.x)
                call SetUnitYBounded(pt.target, pt.y)
            endif

            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x, pt.y))
            call MakeGroupInRange(pid, ug, pt.x, pt.y, pt.spell.values[1] * LBOOST[pid], Condition(function FilterEnemy))

            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Devour\\DevourEffectArt.mdl", target, "chest"))
                call UnitDamageTarget(pt.target, target, pt.spell.values[0] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endloop
        endif
    else
        call SetUnitFlyHeight(pt.target, 0, 0)
        call reselect(pt.target)
        call SetUnitTimeScale(pt.target, 1.)
        call SetUnitPropWindow(pt.target, bj_DEGTORAD * 60.)
        call SetUnitPathing(pt.target, true)
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

function PhantomSlashPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null
    local real x = GetUnitX(pt.target)
    local real y = GetUnitY(pt.target)

    set pt.dur = pt.dur - pt.speed

    call IssueImmediateOrderById(pt.target, 852178)
    if pt.dur - pt.speed <= 0 then
        call IssueImmediateOrder(pt.target, "stop")
    endif

    if pt.dur > 0 then
        call MakeGroupInRange(pid, ug, x, y, 200., Condition(function FilterEnemy))

        //movement
        if IsTerrainWalkable(x + pt.speed * Cos(pt.angle), y + pt.speed * Sin(pt.angle)) then
            call SetUnitXBounded(pt.target, x + pt.speed * Cos(pt.angle))
            call SetUnitYBounded(pt.target, y + pt.speed * Sin(pt.angle))
        else
            set pt.dur = 0
        endif

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if not IsUnitInGroup(target, pt.ug) then
                call GroupAddUnit(pt.ug, target)
                call SetUnitPathing(target, false)
                call DummyCastTarget(Player(PLAYER_NEUTRAL_PASSIVE), target, 'A02B', 1, x, y, "slow")
                call UnitDamageTarget(Hero[pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
        endloop
    else
        call BlzUnitDisableAbility(pt.target, 'A07Y', false, false)
        loop
            set target = FirstOfGroup(pt.ug)
            exitwhen target == null
            call GroupRemoveUnit(pt.ug, target)
            call SetUnitPathing(target, true)
        endloop
        set PhantomSlashing[pid] = false
        call SetUnitTimeScale(pt.target, 1.)
        call SetUnitAnimationByIndex(pt.target, 4)
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

function DaggerStormPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null
    local real x = GetUnitX(pt.target)
    local real y = GetUnitY(pt.target)

    set pt.dur = pt.dur - pt.speed

    if pt.dur > 0 then
        //dagger movement
        call SetUnitXBounded(pt.target, x + pt.speed * Cos(pt.angle))
        call SetUnitYBounded(pt.target, y + pt.speed * Sin(pt.angle))

        call MakeGroupInRange(pid, ug, x, y, pt.aoe, Condition(function FilterEnemy))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if not IsUnitInGroup(target, pt.ug) then
                call GroupAddUnit(pt.ug, target)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "origin"))
                call UnitDamageTarget(Hero[pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                set pt.dmg = pt.dmg * 0.95
            endif
        endloop
    else
        call SetUnitAnimation(pt.target, "death")
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

function BallOfLightningPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null
    local real x = GetUnitX(pt.target)
    local real y = GetUnitY(pt.target)

    set pt.dur = pt.dur - pt.speed

    if pt.dur > 0 then
        call MakeGroupInRange(pid, ug, x, y, pt.aoe, Condition(function FilterEnemy))

        //ball movement
        call SetUnitXBounded(pt.target, x + pt.speed * Cos(pt.angle))
        call SetUnitYBounded(pt.target, y + pt.speed * Sin(pt.angle))

        set target = FirstOfGroup(ug)

        if target != null then
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", target, "origin"))
            call UnitDamageTarget(Hero[pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)

            set pt.dur = 0
        endif
    else
        call SetUnitAnimation(pt.target, "death")
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

function SteedChargePush takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real dist = DistanceCoords(pt.x, pt.y, GetUnitX(pt.target), GetUnitY(pt.target))

    set pt.dur = pt.dur - 1

    call SetUnitXBounded(pt.target, GetUnitX(pt.target) + (5 + dist) * 0.1 * Cos(pt.angle))
    call SetUnitYBounded(pt.target, GetUnitY(pt.target) + (5 + dist) * 0.1 * Sin(pt.angle))

    if pt.dur <= 0 or dist > 250. then
        call TimerList[pid].removePlayerTimer(pt)
    endif
endfunction

function SteedCharge takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real speed = Movespeed[pid] * 0.045
    local unit target = null
    local group ug = CreateGroup()

    if pt.dur == 1. then
        set pt.dur = 0
        call SetUnitPathing(Hero[pid], false)
        call SetUnitPropWindow(Hero[pid], 0)
    endif

    if IsUnitLoaded(Hero[pid]) or IsUnitInRangeXY(Hero[pid], pt.x, pt.y, speed + 5.) or IsUnitInRangeXY(Hero[pid], pt.x, pt.y, 1000.) == false then
        call SetUnitPropWindow(Hero[pid], bj_DEGTORAD * 60.)
        call SetUnitPathing(Hero[pid], true)
        call SetUnitAnimationByIndex(Hero[pid], 1)
        call TimerList[pid].removePlayerTimer(pt)
    else
        call BlzSetUnitFacingEx(Hero[pid], bj_RADTODEG * pt.angle)
        call SetUnitXBounded(Hero[pid], GetUnitX(Hero[pid]) + speed * Cos(pt.angle))
        call SetUnitYBounded(Hero[pid], GetUnitY(Hero[pid]) + speed * Sin(pt.angle))
        call SetUnitAnimationByIndex(Hero[pid], 0)

        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 150., Condition(function FilterEnemy))
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if Buff.has(Hero[pid], target, SteedChargeStun.typeid) == false then
                set Stun.add(Hero[pid], target).duration = 1.
                set SteedChargeStun.add(Hero[pid], target).duration = 2.
                call DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl", target, "origin"))
            endif
        endloop
    endif

    call DestroyGroup(ug)

    set target = null
    set ug = null
endfunction

function TriRocketMovement takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real x = GetUnitX(Hero[pid]) + 50 * Cos(bj_DEGTORAD * pt.angle) 
    local real y = GetUnitY(Hero[pid]) + 50 * Sin(bj_DEGTORAD * pt.angle) 

    set pt.dur = pt.dur - 50

    if pt.dur > 0 then
        if IsTerrainWalkable(x, y) then
            call SetUnitXBounded(Hero[pid], x)
            call SetUnitYBounded(Hero[pid], y)
        else
            call TimerList[pid].removePlayerTimer(pt)
        endif
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif
endfunction

function TriRocket takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer ablev = GetUnitAbilityLevel(Hero[pid], TRIROCKET.id)
    local unit target
    local group ug = CreateGroup()

    set pt.dur = pt.dur - 45

    if pt.dur > 0 then
        call MakeGroupInRange(pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), pt.aoe, Condition(function FilterEnemy))
        call SetUnitXBounded(pt.target, GetUnitX(pt.target) + 45 * Cos(bj_DEGTORAD * pt.angle))
        call SetUnitYBounded(pt.target, GetUnitY(pt.target) + 45 * Sin(bj_DEGTORAD * pt.angle))
        call BlzSetUnitFacingEx(pt.target, pt.angle)
    
        if BlzGroupGetSize(ug) > 0 then
            //boom
            call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\GyroCopter\\GyroCopterMissile.mdl", GetUnitX(pt.target), GetUnitY(pt.target)))
            call MakeGroupInRange(pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), 150. * LBOOST[pid], Condition(function FilterEnemy))

            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call UnitDamageTarget(Hero[pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endloop

            call RecycleDummy(pt.target)
            call TimerList[pid].removePlayerTimer(pt)
        endif
    else
        call RecycleDummy(pt.target)
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

function SanctifiedGround takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target
    local group ug = CreateGroup()

    call MakeGroupInRange(pid, ug, pt.x, pt.y, pt.aoe, Condition(function FilterEnemy))

    set pt.dur = pt.dur - 1
       
    if pt.dur > 0 then
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set SanctifiedGroundDebuff.add(Hero[pid], target).duration = 1.
        endloop

        if pt.dur == 2 then
            call Fade(pt.target, 1., true)
        endif
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
endfunction

function DivineJudgement takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local PlayerTimer pt2
    local unit target
    local group ug = CreateGroup()
    local real x = GetUnitX(pt.target)
    local real y = GetUnitY(pt.target)

    set pt.dur = pt.dur - 40.

	if pt.dur > 0 then
//
        call MakeGroupInRange(pid, ug, x, y, 150. * LBOOST[pid], Condition(function FilterEnemy))
        call SetUnitXBounded(pt.target, x + 40. * Cos(pt.angle))
        call SetUnitYBounded(pt.target, y + 40. * Sin(pt.angle))

        set pt2 = TimerList[pid].get(pt.caster, null, 'Ltsl')

        if pt2 != 0 then
            set LightSealBuff.add(pt.caster, pt.caster).duration = 20.
        endif

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if IsUnitInGroup(target, pt.ug) == false then
                call GroupAddUnit(pt.ug, target)
                if pt2 != 0 and IsUnitInRangeXY(target, pt2.x, pt2.y, 450.) then
                    if IsUnitType(target, UNIT_TYPE_HERO) == true then
                        call LightSealBuff(Buff.get(pt.caster, pt.caster, LightSealBuff.typeid)).addStack(5)
                    else
                        call LightSealBuff(Buff.get(pt.caster, pt.caster, LightSealBuff.typeid)).addStack(1)
                    endif
                endif
                call UnitDamageTarget(pt.caster, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
        endloop
    else
        call SetUnitTimeScale(pt.target, 1.5)
        call SetUnitAnimation(pt.target, "death")
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)

    set target = null
    set ug = null
endfunction

function BorrowedLifeAutocast takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null

    call MakeGroupInRange(pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), 1250., Condition(function FilterHound))

    set target = FirstOfGroup(ug)

    if target != null then
        call IssueTargetOrder(pt.target, "bloodlust", target)
    endif

    call DestroyGroup(ug)

    set target = null
    set ug = null
endfunction

function DevourAutocast takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null

    call MakeGroupInRange(pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), 1250., Condition(function FilterHound))

    set target = FirstOfGroup(ug)

    if target != null then
        call IssueTargetOrder(pt.target, "faeriefire", target)
    endif

    call DestroyGroup(ug)

    set target = null
    set ug = null
endfunction

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
                call UnitDamageTarget(Hero[pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
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
                call UnitDamageTarget(Hero[pid], target, (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid], true)) * 0.25 * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
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

    call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 250. * LBOOST[pid], Condition(function FilterEnemy))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Critters\\Albatross\\CritterBloodAlbatross.mdl", target, "chest"))
        call UnitDamageTarget(Hero[pid], target, multiplier * GetHeroAgi(Hero[pid], true) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop

    call DestroyGroup(ug)

    set ug = null
endfunction

function SummoningImprovement takes integer pid, unit summon, real str, real agi, real int returns nothing
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A022') - 1 //summoning improvement
    local integer uid = GetUnitTypeId(summon)
    local integer i

    //stat ratios
    call SetHeroStr(summon, R2I(str * (GetHeroInt(Hero[pid], true) + GetHeroStr(Hero[pid], true)) * BOOST[pid]), true)
    if uid != SUMMON_DESTROYER then
        call SetHeroAgi(summon, R2I(agi * GetHeroInt(Hero[pid], true) * BOOST[pid]), true)
    else
        call BlzSetUnitArmor(summon, agi * GetHeroInt(Hero[pid], true) * BOOST[pid])
    endif
    call SetHeroInt(summon, R2I(int * GetHeroInt(Hero[pid], true) * BOOST[pid]), true)
    set improvementArmorBonus[pid] = 0

    if ablev > 0 then
        call SetUnitMoveSpeed(summon, GetUnitDefaultMoveSpeed(summon) + ablev * 10)
        
        //armor bonus
        set improvementArmorBonus[pid] = improvementArmorBonus[pid] + R2I((Pow(ablev, 1.2) + (Pow(ablev, 4) - Pow(ablev, 3.9)) / 90) / 2 + ablev + 6.5)

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

function BlizzardPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    set pt.dur = pt.dur - 1

    if pt.dur < 3 then
        call TimerList[pid].removePlayerTimer(pt)
    elseif pt.dur < 1 then
        call IssueImmediateOrder(pt.caster, "stop")
    endif
endfunction

function BloodLeechAoE takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A07A')
    local real dmg = (2.75 + 0.25 * ablev) * (GetHeroAgi(Hero[pid], true) + GetHeroStr(Hero[pid], true)) * BOOST[pid]

    if GetUnitAbilityLevel(Hero[pid], 'A099') > 0 then
        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 500 * LBOOST[pid], Condition(function FilterEnemy))

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
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(Hero[pid]) - GetUnitY(bj_lastCreatedUnit), GetUnitX(Hero[pid]) - GetUnitX(bj_lastCreatedUnit)))
            call InstantAttack(bj_lastCreatedUnit, Hero[pid])
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

function SpawnDaggers takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local PlayerTimer pt2
    local integer i = 0
    local real x
    local real y
    local real angle

    set pt.dur = pt.dur - 1

    if pt.dur >= 0 then
        loop
            exitwhen i > 1
            set pt2 = TimerList[pid].addTimer(pid)

            set angle = Atan2(pt.aoe - pt.y, pt.armor - pt.x) + GetRandomReal(bj_PI / -6., bj_PI / 6.)
            set x = pt.armor + GetRandomReal(70., 300.) * Cos(angle)
            set y = pt.aoe + GetRandomReal(70., 300.) * Sin(angle)

            set pt2.target = GetDummy(x, y, 0, 0, 1.)
            set pt2.angle = Atan2(pt.y - y, pt.x - x) + GetRandomReal(bj_PI / -60., bj_PI / 60.)
            set pt2.dur = 1150.
            set pt2.speed = 60.
            set pt2.aoe = 45.
            set pt2.dmg = GetHeroAgi(Hero[pid], true) * 2. * BOOST[pid]
            set pt2.ug = CreateGroup()
            set pt2.sfx = AddSpecialEffectTarget("Abilities\\Weapons\\WardenMissile\\WardenMissile.mdl", pt2.target, "overhead")

            call BlzSetUnitFacingEx(pt2.target, bj_RADTODEG * pt2.angle)
            call SetUnitScale(pt2.target, 1.2, 1.2, 1.2)
            call SetUnitFlyHeight(pt2.target, 35.00, 0.00)

            call TimerStart(pt2.timer, 0.03, true, function DaggerStormPeriodic)

            set i = i + 1
        endloop
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif
endfunction

function SongOfWar takes integer pid, real x, real y, real aoe returns nothing
    local group ug = CreateGroup()
    local unit target
    local integer count = BlzGroupGetSize(SongOfWarTarget)
    local integer index = 0
    local integer bonus
    local PlayerTimer pt = TimerList[pid].get(null, Hero[pid], 'impr')
    local real x2 = 0
    local real y2 = 0
    local real aoe2 = 0

    call MakeGroupInRange(pid, ug, x, y, aoe, Condition(function FilterAllyHero))

    //improv
    if pt != 0 and pt.agi == SONG_WAR then
        set x2 = pt.x
        set y2 = pt.y
        set aoe2 = pt.aoe
        call GroupEnumUnitsInRangeEx(pid, ug, x2, y2, aoe2, Condition(function FilterAllyHero))
    endif

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
            if ((BardSong[pid] == SONG_WAR and IsUnitInRangeXY(target, x, y, aoe) and UnitAlive(Hero[pid])) or IsUnitInRangeXY(target, x2, y2, aoe2)) and UnitAlive(target) then
                //update bonus
                call UnitAddBonus(target, BONUS_DAMAGE, - (LoadInteger(MiscHash, 's', GetHandleId(target))))
                set bonus = R2I((GetHeroStat(MainStat(target), target, true) + UnitGetBonus(target, BONUS_DAMAGE)) * 0.2)
                call SaveInteger(MiscHash, 's', GetHandleId(target), bonus) 
                call UnitAddBonus(target, BONUS_DAMAGE, bonus)
            else
                //remove bonus
                call GroupRemoveUnit(SongOfWarTarget, target)
                call UnitAddBonus(target, BONUS_DAMAGE, - (LoadInteger(MiscHash, 's', GetHandleId(target))))
                call RemoveSavedInteger(MiscHash, 's', GetHandleId(target))
                call RemoveSavedInteger(MiscHash, 'p', GetHandleId(target))
                call UnitRemoveAbility(target, 'B017')
                set index = index - 1
            endif
        endif
        set index = index + 1
        exitwhen index >= count
    endloop

    call DestroyGroup(ug)

    set target = null
    set ug = null
endfunction

function ImprovPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target
    local group ug = CreateGroup()

    set pt.time = pt.time + TimerGetElapsed(pt.timer)

    if pt.time >= pt.dur then
        call BlzSetSpecialEffectScale(pt.sfx, 1.)
        call SetUnitScale(pt.caster, 1., 1., 1.)
        call TimerList[pid].removePlayerTimer(pt)
    else
        call MakeGroupInRange(pid, ug, pt.x, pt.y, pt.aoe, Condition(function isalive))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if IsUnitAlly(target, Player(pid - 1)) == false then
                if ModuloInteger(R2I(pt.time), 2) == 0 then
                    call UnitDamageTarget(Hero[pid], target, pt.dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                endif
                if pt.agi == SONG_FATIGUE then
                    set SongOfFatigueSlow.add(Hero[pid], target).duration = 2.
                endif
            endif
        endloop
    endif
    
    call DestroyGroup(ug)

    set ug = null
endfunction

function SongOfPeaceExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())

    call UnitRemoveAbility(Hero[pid], 'A01B')
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

function BloodDomainTick takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target
    local group ug = CreateGroup()
    local group ug2 = CreateGroup()
    local integer size
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A09B')

    set pt.dur = pt.dur - 1

    if pt.dur > 0 then
        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), pt.aoe, Condition(function FilterEnemyDead))

        call MakeGroupInRange(pid, ug2, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), pt.aoe, Condition(function FilterEnemy))
        set size = BlzGroupGetSize(ug2) - 1
        set pt.dmg = ((0.5 + 0.5 * ablev) * GetHeroAgi(Hero[pid], true)) + ((1.5 + 0.5 * ablev) * GetHeroStr(Hero[pid], true))
        set pt.dmg = RMaxBJ(pt.dmg * 0.2, pt.dmg * (1 - (0.17 - 0.02 * ablev) * size))
        set pt.armor = 1 * (GetHeroAgi(Hero[pid], true) + GetHeroStr(Hero[pid], true))
        set pt.armor = RMaxBJ(pt.armor * 0.2, pt.armor * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(ug) - 1)))
        call DestroyGroup(ug2)

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set BloodBank[pid] = RMinBJ(BloodBank[pid] + pt.armor, 200 * GetHeroInt(Hero[pid], true))

            if UnitAlive(target) then
                call UnitDamageTarget(Hero[pid], target, pt.dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif

            set bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), 'A09D', 1, DUMMY_RECYCLE_TIME)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(Hero[pid]) - GetUnitY(bj_lastCreatedUnit),  GetUnitX(Hero[pid]) - GetUnitX(bj_lastCreatedUnit)))
            call InstantAttack(bj_lastCreatedUnit, Hero[pid])
        endloop
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)
    call DestroyGroup(ug2)

    set ug = null
    set ug2 = null
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

function ArcaneComet takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)
    local real x = LoadReal(MiscHash, 0, GetHandleId(t))
    local real y = LoadReal(MiscHash, 1, GetHandleId(t))
    local unit target
    local group ug = CreateGroup()
    local real dmg = GetHeroInt(Hero[pid], true) * 2 * BOOST[pid]

    call MakeGroupInRange(pid, ug, x, y, 150. * LBOOST[pid], Condition(function FilterEnemy))

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
    if HeroID[pid] == HERO_ARCANIST then
        call BlzUnitHideAbility(Hero[pid], 'A05Q', false)
        call BlzUnitHideAbility(Hero[pid], 'A02N', false)

        call UnitRemoveAbility(Hero[pid], 'A08S')
        call UnitRemoveAbility(Hero[pid], 'A08X')

        call SetUnitTurnSpeed(Hero[pid], GetUnitDefaultTurnSpeed(Hero[pid]))
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
        call SetUnitPropWindow(target, bj_DEGTORAD * 60.)
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
            call SetUnitPropWindow(target, bj_DEGTORAD * 60.)
            call SetUnitPathing(target, true)
        endloop
        
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
endfunction

function GatekeepersPact takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target = null
    local group ug = CreateGroup()
    local effect fx = AddSpecialEffect("war3mapImported\\AnnihilationBlast.mdx", GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))

    call BlzSetSpecialEffectColor(fx, 25, 255, 0)
    call DestroyEffect(fx)

    call SetUnitAnimationByIndex(Hero[pid], 2)
    call BlzPauseUnitEx(Hero[pid], false)
    call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), pt.spell.values[1] * LBOOST[pid], Condition(function FilterEnemy))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call StunUnit(pid, target, 5.)
        call UnitDamageTarget(Hero[pid], target, pt.spell.values[0] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop

    call TimerList[pid].removePlayerTimer(pt)
    call DestroyGroup(ug)

    set ug = null
    set fx = null
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
        else
            call IssueImmediateOrder(Hero[pid], "unimmolation")
        endif
    else
        call ReleaseTimer(t)
    endif

    set t = null
endfunction

function LightSeal takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
       
    call TimerList[pid].removePlayerTimer(pt)
endfunction

function DarkSeal takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target

    call MakeGroupInRange(pid, ug, pt.x, pt.y, 450 * LBOOST[pid], Condition(function FilterEnemy))

    set pt.dur = pt.dur - 1
       
    if pt.dur > 0 then
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call GroupAddUnit(pt.ug, target)
            set DarkSealDebuff.add(pt.caster, target).duration = 1.
        endloop
    else
        set darkSeal[pid] = null
        set darkSealActive[pid] = false
        call BlzSetUnitAttackCooldown(Hero[pid], BlzGetUnitAttackCooldown(Hero[pid], 0) + darkSealBAT[pid], 0)
        set darkSealBAT[pid] = 0
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

function FrozenOrbPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target
    local real x = GetUnitX(pt.caster)
    local real y = GetUnitY(pt.caster)
    local real angle = 0.

    set pt.agi = pt.agi + 1
    set pt.dur = pt.dur - 6.

    if pt.dur > 0 then
        //orb movement
        call SetUnitXBounded(pt.caster, x + 6 * Cos(pt.angle))
        call SetUnitYBounded(pt.caster, y + 6 * Sin(pt.angle))

        //icicle every second
        if ModuloInteger(pt.agi, 33) == 0 then
            call MakeGroupInRange(pid, ug, x, y, 750. * LBOOST[pid], Condition(function FilterEnemy))
            
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                set angle = Atan2(GetUnitY(target) - y, GetUnitX(target) - x)
                set bj_lastCreatedUnit = GetDummy(x + 50. * Cos(angle), y + 50 * Sin(angle), 'A09F', 1, 3.)
                call SetUnitOwner(bj_lastCreatedUnit, Player(pid - 1), false)
                call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(pt.caster), GetUnitX(target) - GetUnitX(pt.caster)))
                call SetUnitScale(bj_lastCreatedUnit, 0.35, 0.35, 0.35)
                call SetUnitFlyHeight(bj_lastCreatedUnit, GetUnitFlyHeight(pt.caster), 0)
                call InstantAttack(bj_lastCreatedUnit, target)
            endloop
        endif
    else
        //show original cast
        call UnitRemoveAbility(Hero[pid], 'A01W')
        call BlzUnitHideAbility(Hero[pid], 'A011', false)

        //orb shatter
        call MakeGroupInRange(pid, ug, x, y, 400. * LBOOST[pid], Condition(function FilterEnemy))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set Freeze.add(pt.target, target).duration = 3.
            call UnitDamageTarget(pt.target, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop

        call DestroyEffect(AddSpecialEffect("war3mapImported\\FrostNova.mdx", x, y))

        call SetUnitAnimation(pt.caster, "death")
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)

    set ug = null
    set target = null
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
        
        call MakeGroupInRange(pid, ug, GetUnitX(meatgolem[pid]), GetUnitY(meatgolem[pid]), 600. * LBOOST[pid], Condition(function FilterEnemy))
        
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
    
    call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 400. * LBOOST[pid], Condition(function FilterEnemy))
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call UnitDamageTarget(source, target, GetHeroInt(source, true) * 1.25 * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop
    
    call DestroyGroup(ug)
    
    set ug = null
endfunction

function DestroyerAttackSpeed takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer base = 0

    if destroyerDevourStacks[pid] == 5 then
        set base = 400
    elseif destroyerDevourStacks[pid] >= 3 then
        set base = 200
    endif

    if pt.x != GetUnitX(destroyer[pid]) or pt.y != GetUnitY(destroyer[pid]) then
        call SetHeroAgi(destroyer[pid], base, true)
        call TimerList[pid].removePlayerTimer(pt)
    else
        call SetHeroAgi(destroyer[pid], IMinBJ(GetHeroAgi(destroyer[pid], false) + 50, 400), true)
    endif
endfunction

function MagneticStanceAggro takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = GetTimerData(t)

    if GetUnitAbilityLevel(Hero[pid], 'B02E') > 0 then
        call Taunt(Hero[pid], pid, 800., false, 500, 500)
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
    
    if GetUnitAbilityLevel(Hero[pid], 'B02E') > 0 and UnitAlive(Hero[pid]) then
        call MakeGroupInRange(pid, magnetic_stance_group[pid], GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 500. * LBOOST[pid], Condition(function FilterEnemy))
        
        loop
            set target = FirstOfGroup(magnetic_stance_group[pid])
            exitwhen target == null
            call GroupRemoveUnit(magnetic_stance_group[pid], target)
            set angle = Atan2(GetUnitY(Hero[pid]) - GetUnitY(target), GetUnitX(Hero[pid]) - GetUnitX(target))
            call UnitWakeUp(target)
            if GetUnitMoveSpeed(target) > 0 and (GetUnitCurrentOrder(target) == 0 or GetUnitCurrentOrder(target) == 851971) and IsTerrainWalkable(GetUnitX(target) + (3. * Cos(angle)), GetUnitY(target) + (3. * Sin(angle))) and UnitDistance(Hero[pid], target) > 100. then
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
    local real damage = GetHeroInt(Hero[pid], true) * (5 + GetUnitAbilityLevel(Hero[pid],'A078') * 3) * BOOST[pid]
    
    if BlzGroupGetSize(attargets[pid]) > 0 then
        loop
            set target = FirstOfGroup(attargets[pid])
            exitwhen target == null
            call GroupRemoveUnit(attargets[pid], target)
            call PauseUnit(target, false)
            call SetUnitFlyHeight(target, 0.00, 0.00)
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
                call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(u) - GetUnitY(target), GetUnitX(u) - GetUnitX(target)))
                call InstantAttack(bj_lastCreatedUnit, u)
                call UnitDamageTarget(target, u, BlzGetUnitMaxHP(u) * 0.1, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                if UnitAlive(u) then
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
    
    if UnitAlive(nagaboss) then
        call MakeGroupInRect(FOE_ID, ug, gg_rct_Naga_Dungeon_Boss, Condition(function FilterEnemy))
        
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
            if ModuloInteger(num, 2) == 0 then
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

    if UnitAlive(u) then
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

    if UnitAlive(u) then
        set nt = NagaThorns.add(u, u)
        set nt.duration = 6.5
    endif
    
    call RemoveSavedHandle(MiscHash, GetHandleId(t), 0)
    call ReleaseTimer(t)
    
    set u = null
    set t = null
endfunction

function ElementalStorm takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer rand = GetRandomInt(1, 4)
    local real angle = GetRandomInt(0, 359) * bj_DEGTORAD
    local integer dist = GetRandomInt(50, 200)
    local real x2 = pt.x + dist * Cos(angle)
    local real y2 = pt.y + dist * Sin(angle)
    local group ug = CreateGroup()
    local unit target
    
    set pt.dur = pt.dur - 1

    //guarantee the first 6 strikes are your chosen element
    if pt.dur >= 6 then
        set rand = pt.agi
    else
        loop
            exitwhen (rand != pt.agi and rand != pt.str and rand != pt.int)
            set rand = GetRandomInt(1, 4)
        endloop
    endif

    //alternate elements
    if pt.str == 0 then
        set pt.str = rand
    elseif pt.int == 0 then
        set pt.int = rand
    else
        set pt.str = 0
        set pt.int = 0
    endif

    if pt.dur >= 0 then
        call DestroyEffectTimed(AddSpecialEffect("war3mapImported\\Lightnings Long.mdx", x2, y2), 1.)

        //fire aoe
        if rand == 1 then
            call MakeGroupInRange(pid, ug, pt.x, pt.y, pt.aoe * 1.5 * LBOOST[pid], Condition(function FilterEnemy))
            call DestroyEffectTimed(AddSpecialEffect("war3mapImported\\Flame Burst.mdx", x2, y2), 2.)
        else
            call MakeGroupInRange(pid, ug, pt.x, pt.y, pt.aoe * LBOOST[pid], Condition(function FilterEnemy))
        endif

        set target = FirstOfGroup(ug)

        //sfx
        if rand == 2 then
            call DestroyEffectTimed(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", x2, y2), 2.)
            call MP(Hero[pid], BlzGetUnitMaxMana(Hero[pid]) * 0.15)
        elseif rand == 3 then
            call UnitDamageTarget(Hero[pid], target, GetWidgetLife(target) * 0.015, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_DIVINE, WEAPON_TYPE_WHOKNOWS)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "origin"))
        elseif rand == 4 then
            call DestroyEffectTimed(AddSpecialEffect("war3mapImported\\Earth NovaTarget.mdx", x2, y2), 2.)
        endif

        //unique effects
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if rand == 1 then //fire
                call UnitDamageTarget(Hero[pid], target, pt.dmg * 1.5 * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            else
                call UnitDamageTarget(Hero[pid], target, pt.dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                if rand == 2 then //ice
                    set Freeze.add(Hero[pid], target).duration = 2.
                elseif rand == 4 then //earth
                    if Buff.has(null, target, EarthDebuff.typeid) then
                        call IncUnitAbilityLevel(target, 'A04P')
                    endif
                    set EarthDebuff.add(Hero[pid], target).duration = 10.
                endif
            endif
        endloop
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
endfunction

function ControlTime takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    call BlzSetUnitAttackCooldown(Hero[pid], BlzGetUnitAttackCooldown(Hero[pid], 0) / 0.5, 0)
endfunction

function ArcaneBarrage takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local unit target
    local integer i = BlzGroupGetSize(ArcaneBarrageHit[pid])
    local real dmg = GetHeroInt(Hero[pid], true) * (GetUnitAbilityLevel(Hero[pid], 'A02N') + 1) * BOOST[pid]
    
    loop
        set target = FirstOfGroup(ArcaneBarrageHit[pid])
        exitwhen target == null
        call GroupRemoveUnit(ArcaneBarrageHit[pid], target)
        if UnitAlive(target) then
            if i == 1 then
                call UnitDamageTarget(Hero[pid], target, dmg * 3, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            else
                call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
        endif
    endloop
    
    set target = null
endfunction

function ArcaneBoltsPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null
    local real x = GetUnitX(pt.target)
    local real y = GetUnitY(pt.target)

    set pt.dur = pt.dur - 40.

    if pt.dur >= 0 then
        call MakeGroupInRange(pid, ug, x, y, 125., Condition(function FilterEnemy))

        set target = FirstOfGroup(ug)

        //a unit was found
        if target != null then
            call MakeGroupInRange(pid, ug, x, y, pt.aoe * LBOOST[pid], Condition(function FilterEnemy))

            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call UnitDamageTarget(Hero[pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endloop

            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x, y))
            set pt.dur = 0
        else
            call SetUnitXBounded(pt.target, x + 40. * Cos(pt.angle))
            call SetUnitYBounded(pt.target, y + 40. * Sin(pt.angle))
        endif
    else
        call SetUnitAnimation(pt.target, "death")
        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

function ArcaneBolts takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real x = GetUnitX(Hero[pid])
    local real y = GetUnitY(Hero[pid])
    local unit target = null
    local PlayerTimer pt2

    set pt.dur = pt.dur - 1

    if pt.dur >= 0 then
        set target = GetDummy(x, y, 0, 0, 3.)

        call BlzSetUnitSkin(target, 'h00Y')
        call BlzSetUnitFacingEx(target, bj_RADTODEG * pt.angle)
        call SetUnitFlyHeight(target, 55.00, 0.00)
        call SetUnitScale(target, 1.3, 1.3, 1.3)

        set pt2 = TimerList[pid].addTimer(pid)
        set pt2.angle = pt.angle
        set pt2.target = target
        set pt2.dur = 1000.
        set pt2.aoe = 250.
        set pt2.dmg = GetHeroInt(Hero[pid], true) * 2 * BOOST[pid]

        call TimerStart(pt2.timer, 0.03, true, function ArcaneBoltsPeriodic)
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif

    set target = null
endfunction

function HeliCD takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
        
    set heliCD[pid] = false
endfunction

function MetamorphosisPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    set pt.dur = pt.dur - 0.03

    //call BlzSetSpecialEffectTime(pt.sfx, RMaxBJ(0, pt.dur / RMaxBJ(0.001, pt.dmg)))

    if pt.dur > 0 then
        /*call BlzSetSpecialEffectX(pt.sfx, GetUnitX(Hero[pid]))
        call BlzSetSpecialEffectY(pt.sfx, GetUnitY(Hero[pid]))
        call BlzSetSpecialEffectZ(pt.sfx, 575.)*/
    else
        set metamorphosis[pid] = 0.
        /*call BlzSetSpecialEffectScale(pt.sfx, 0.)
        call BlzSetSpecialEffectTimeScale(pt.sfx, 5.)
        call TimerList[pid].removePlayerTimer(pt)*/
    endif
endfunction

function Monsoon takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target

    set pt.dur = pt.dur - 1
    
    if pt.dur >= 0 then
        //in case of Overload toggling
        call pt.spell.setValues(pid)

        call MakeGroupInRange(pid, ug, pt.x, pt.y, pt.spell.values[1] * LBOOST[pid], Condition(function FilterEnemy))
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", GetUnitX(target), GetUnitY(target)))
            call UnitDamageTarget(Hero[pid], target, pt.spell.values[2] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
endfunction

function Omnislash takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real x = GetUnitX(Hero[pid])
    local real y = GetUnitY(Hero[pid])
    local group ug = CreateGroup()
    local unit target

    call pt.spell.setValues(pid)
    
    set pt.dur = pt.dur - 1
    
    if pt.dur >= 0 then
        call MakeGroupInRange(pid, ug, x, y, 600., Condition(function FilterEnemy))
        
        set target = FirstOfGroup(ug)

        if target != null then
            call SetUnitAnimation(Hero[pid], "Attack Slam")
            call SetUnitXBounded(Hero[pid], GetUnitX(target) + 60. * Cos(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
            call SetUnitYBounded(Hero[pid], GetUnitY(target) + 60. * Sin(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
            call BlzSetUnitFacingEx(Hero[pid], GetUnitFacing(target))
            call UnitDamageTarget(Hero[pid], target, pt.spell.values[1] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Blink\\BlinkHero[pid].mdl", Hero[pid], "chest"))
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "chest"))
        else
            set pt.dur = 0
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

function HeliRocketPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target = GetDummy(GetUnitX(helicopter[pid]), GetUnitY(helicopter[pid]), 'A04F', 1, DUMMY_RECYCLE_TIME)
    local group ug = CreateGroup()

    set pt.dur = pt.dur - 1

    if pt.dur == 0 then
        call SoundHandler("Units\\Human\\Gyrocopter\\GyrocopterPissed1.flac", true, null, helicopter[pid])
        call SetUnitFlyHeight(target, GetUnitFlyHeight(helicopter[pid]), 30000.)
        call IssuePointOrder(target, "clusterrockets", pt.x, pt.y)
    elseif pt.dur < 0 then
        //explode
        call DestroyEffect(AddSpecialEffect("war3mapImported\\NewMassiveEX.mdx", pt.x, pt.y))
        call MakeGroupInRange(pid, ug, pt.x, pt.y, 400. * heliboost[pid], Condition(function FilterEnemy))
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call StunUnit(pid, target, 4.)
            call UnitDamageTarget(Hero[pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop

        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)
    
    set target = null
    set ug = null
endfunction

function ClusterRocketsDamage takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local unit target
    local group ug = CreateGroup()
    local Spell spell = ASSAULTHELICOPTER.get(pid)
    
    call BlzGroupAddGroupFast(helitargets[pid], ug)
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if LoadInteger(MiscHash, GetHandleId(target), 'heli') == 1 and sniperstance[pid] then
            call UnitDamageTarget(Hero[pid], target, spell.values[0] * heliboost[pid] * 3., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            call RemoveSavedInteger(MiscHash, GetHandleId(target), 'heli')
        elseif not sniperstance[pid] then
            call UnitDamageTarget(Hero[pid], target, spell.values[0] * heliboost[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif
    endloop
    
    call DestroyGroup(ug)
    call spell.destroy()
    
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
        if UnitAlive(target) == false or UnitDistance(target, helicopter[pid]) > 1500. or IsUnitAlly(target, Player(pid - 1)) then
            call GroupRemoveUnit(helitargets[pid], target)
        endif
    endloop
    
    call BlzGroupAddGroupFast(helitargets[pid], ug)
    set enemyCount = BlzGroupGetSize(ug)
    
    if enemyCount > 0 then
        if sniperstance[pid] then
            if UnitAlive(LAST_TARGET[pid]) then
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
                if UnitAlive(targetArray[i]) then
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

function FightMeExpire takes nothing returns nothing
    set FightMe[ReleaseTimer(GetExpiredTimer())] = false
endfunction

function ResetCD takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    call UnitResetCooldown(Hero[pid])
    call UnitResetCooldown(Backpack[pid])
endfunction

function DemonicSacrificeExpire takes nothing returns nothing
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
    
    call MakeGroupInRange(pid, ug, pt.x, pt.y, pt.spell.values[1] * LBOOST[pid], Condition(function FilterEnemy))
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        set Stun.add(Hero[pid], target).duration = pt.spell.values[2] * LBOOST[pid]
        call UnitDamageTarget(Hero[pid], target, pt.spell.values[0] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop
    
    if SquareRoot(Pow(GetUnitX(Hero[pid]) - pt.x, 2) + Pow(GetUnitY(Hero[pid]) - pt.y, 2)) < 1000. then
        call SetUnitPosition(Hero[pid], pt.x, pt.y)
    endif

    call SetUnitAnimation(Hero[pid], "birth")
    call SetUnitTimeScale(Hero[pid], 1)
    call Fade(Hero[pid], 0.8, false)
    
    call DestroyGroup(ug)

    call TimerList[pid].removePlayerTimer(pt)
    
    set ug = null
endfunction

function SmokebombPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target

    set pt.dur = pt.dur - 1

    call MakeGroupInRange(pid, ug, pt.x, pt.y, 300. * LBOOST[pid], Condition(function isalive))

    if pt.dur > 0 then
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if IsUnitAlly(target, Player(pid - 1)) then
                set SmokebombBuff.add(Hero[pid], target).duration = 1.
            else
                set SmokebombDebuff.add(Hero[pid], target).duration = 1.
            endif
        endloop
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif
                    
    call DestroyGroup(ug)

    set ug = null
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
    local integer ablev = GetUnitAbilityLevel(Hero[pid], 'A019')
    local integer i = 0
    local unit target
    local real x = GetUnitX(Hero[pid])
    local real y = GetUnitY(Hero[pid])
    local real aoe = 900. * LBOOST[pid]
    local integer count = 0
    local real angle = 0.

    set pt.dur = pt.dur - 1
    call DestroyEffect(pt.sfx)
    
    if pt.dur >= 0 then
        call MakeGroupInRange(pid, ug, x, y, aoe, Condition(function FilterEnemy))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null or i >= ablev + 1
            call GroupRemoveUnit(ug, target)

            set bj_lastCreatedUnit = GetDummy(x, y, 'A01Y', 1, 4.)
            call SetUnitOwner(bj_lastCreatedUnit, Player(pid - 1), false)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(bj_lastCreatedUnit), GetUnitX(target) - GetUnitX(bj_lastCreatedUnit)))
            call UnitDisableAbility(bj_lastCreatedUnit, 'Amov', true)
            call InstantAttack(bj_lastCreatedUnit, target)

            set i = i + 1
        endloop

        //dark seal augment
        if darkSealActive[pid] then
            call BlzGroupAddGroupFast(TimerList[pid].get(null, Hero[pid], 'Dksl').ug, ug)
            set count = BlzGroupGetSize(ug)
            set i = 0

            if count > 0 then
                loop
                    set target = BlzGroupUnitAt(ug, i)

                    if GetUnitAbilityLevel(target, 'A06W') > 0 then
                        set angle = 360. / count * (i + 1) * bj_DEGTORAD
                        set x = GetUnitX(darkSeal[pid]) + 380 * Cos(angle)
                        set y = GetUnitY(darkSeal[pid]) + 380 * Sin(angle)

                        set bj_lastCreatedUnit = GetDummy(x, y, 'A01Y', 1, 4.)
                        call SetUnitOwner(bj_lastCreatedUnit, Player(pid - 1), false)
                        call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(bj_lastCreatedUnit), GetUnitX(target) - GetUnitX(bj_lastCreatedUnit)))
                        call UnitDisableAbility(bj_lastCreatedUnit, 'Amov', true)
                        call InstantAttack(bj_lastCreatedUnit, target)
                    endif

                    set i = i + 1
                    exitwhen i >= count
                endloop
            endif
        endif
        
        if pt.dur > 0 then
            set pt.sfx = AddSpecialEffectTarget("war3mapImported\\LightningShield" + I2S(R2I(pt.dur)) + ".mdx", Hero[pid], "origin")
            call BlzSetSpecialEffectTimeScale(pt.sfx, 1.5)
            call BlzPlaySpecialEffect(pt.sfx, ANIM_TYPE_STAND)
        else
            call TimerList[pid].removePlayerTimer(pt)
        endif
    endif
        
    call DestroyGroup(ug)
    
    set target = null
    set ug = null
endfunction

function GaiaArmorPush takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target
    local real angle = 0.
    local real x = 0.
    local real y = 0.
    local group ug = CreateGroup()

    call BlzGroupAddGroupFast(pt.ug, ug)
    
    set pt.dur = pt.dur - 1
    
    if pt.dur > 0 then
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set x = GetUnitX(target)
            set y = GetUnitY(target)
            set angle = Atan2(y - GetUnitY(Hero[pid]), x - GetUnitX(Hero[pid]))
            if IsTerrainWalkable(x + pt.speed * Cos(angle), y + pt.speed * Sin(angle)) then
                call SetUnitXBounded(target, x + pt.speed * Cos(angle))
                call SetUnitYBounded(target, y + pt.speed * Sin(angle))
            endif
        endloop
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
endfunction

function GaiaArmorCD takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())

    if HeroID[pid] == HERO_ELEMENTALIST then
        set aoteCD[pid] = true
        call UnitAddAbility(Hero[pid], 'A033')
        call BlzUnitHideAbility(Hero[pid], 'A033', true)
    endif
endfunction

function BladeStorm takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit u
    local Spell spell = BLADESTORM.get(pid)
    
    set pt.dur = pt.dur - 1
    
    if UnitAlive(Hero[pid]) and pt.dur >= 0 then
        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), spell.values[0] * LBOOST[pid], Condition(function FilterEnemy))

        if GetRandomInt(0, 99) < spell.values[2] * LBOOST[pid] then
            set u = BlzGroupUnitAt(ug, GetRandomInt(0, BlzGroupGetSize(ug) - 1))
            call DummyCastTarget(GetOwningPlayer(Hero[pid]), u, 'A09S', 1, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), "forkedlightning")
            call UnitDamageTarget(Hero[pid], u, spell.values[3] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif

        loop
            set u = FirstOfGroup(ug)
            exitwhen u == null
            call GroupRemoveUnit(ug, u)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", u, "origin"))
            call UnitDamageTarget(Hero[pid], u, spell.values[1] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    else
        call AddUnitAnimationProperties(Hero[pid], "spin", false)
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)
    call spell.destroy()
    
    set ug = null
    set u = null
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

function TidalWavePeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target = null
    local group ug = CreateGroup()
    local TidalWaveDebuff debuff
    local real x = 0.
    local real y = 0.

    local real Ax = pt.x + 200. * Cos(pt.angle + bj_PI * 5. / 8.)
    local real Bx = pt.x + 200. * Cos(pt.angle + bj_PI * 3. / 8.)
    local real Cx = pt.x + 200. * Cos(pt.angle - bj_PI * 3. / 8.)
    local real Dx = pt.x + 200. * Cos(pt.angle - bj_PI * 5. / 8.)

    local real Ay = pt.y + 200. * Sin(pt.angle + bj_PI * 5. / 8.)
    local real By = pt.y + 200. * Sin(pt.angle + bj_PI * 3. / 8.)
    local real Cy = pt.y + 200. * Sin(pt.angle - bj_PI * 3. / 8.)
    local real Dy = pt.y + 200. * Sin(pt.angle - bj_PI * 5. / 8.)

    local real AB = 0.
    local real BC = 0.
    local real CD = 0.
    local real DA = 0.

    set pt.dur = pt.dur - 20
    set pt.time = pt.time + TimerGetElapsed(pt.timer)

    if pt.time >= 1.5 then
        call SetUnitTimeScale(pt.target, 0.)
    endif

	if pt.dur > 0 then
        call MakeGroupInRange(pid, ug, pt.x, pt.y, 400, Condition(function FilterEnemy))

        set pt.x = pt.x + 20 * Cos(pt.angle)
        set pt.y = pt.y + 20 * Sin(pt.angle)
        call SetUnitXBounded(pt.target, pt.x)
        call SetUnitXBounded(pt.target, pt.y)

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)

            set x = GetUnitX(target)
            set y = GetUnitY(target)

            set AB = (y - By) * (Ax - Bx) - (x - Bx) * (Ay - By)
            set BC = (y - Cy) * (Bx - Cx) - (x - Cx) * (By - Cy)
            set CD = (y - Dy) * (Cx - Dx) - (x - Dx) * (Cy - Dy)
            set DA = (y - Ay) * (Dx - Ax) - (x - Ax) * (Dy - Ay)
            
            if (AB >= 0 and BC >= 0 and CD >= 0 and DA >= 0) or (AB <= 0 and BC <= 0 and CD <= 0 and DA <= 0) then
                if IsUnitType(target, UNIT_TYPE_STRUCTURE) == false and GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(x, y) then
                    call DestroyEffect(AddSpecialEffect("war3mapImported\\SlideWater.mdx", GetUnitX(target), GetUnitY(target)))
                    call SetUnitXBounded(target, x + 8.5 * Cos(pt.angle))
                    call SetUnitYBounded(target, y + 8.5 * Sin(pt.angle))
                endif
                
                set SoakedDebuff.add(Hero[pid], target).duration = 5.
                set debuff = TidalWaveDebuff.add(Hero[pid], target)

                if IsUnitType(target, UNIT_TYPE_HERO) == true then
                    set debuff.duration = 5.
                else
                    set debuff.duration = 10.
                endif

                if pt.agi == 1 then
                    set debuff.percent = .20
                endif
            endif

        endloop
    else
        call DEBUGMSG("hi")
        call SetUnitAnimation(pt.target, "death")
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)

    set target = null
    set ug = null
endfunction

function WhirlpoolPeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target
    local real angle = 0
    
    set pt.agi = pt.agi + 1
    set pt.dur = pt.dur - 0.03
        
    if pt.dur > 0 then
        call MakeGroupInRange(pid, ug, pt.x, pt.y, pt.aoe * LBOOST[pid], Condition(function FilterEnemy))
        set pt.dur = pt.dur - 0.0015 * IMinBJ(BlzGroupGetSize(ug), 20)
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            //movement effects
            set angle = Atan2(pt.y - GetUnitY(target), pt.x - GetUnitX(target))
            
            if IsUnitType(target, UNIT_TYPE_HERO) == false and GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(GetUnitX(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Cos(angle), GetUnitY(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Sin(angle)) then
                call SetUnitPathing(target, false)
                call SetUnitXBounded(target, GetUnitX(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Cos(angle))
                call SetUnitYBounded(target, GetUnitY(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Sin(angle))
            endif
            call SetUnitPathing(target, true)
            
            if ModuloInteger(pt.agi, 33) == 0 then
                call UnitDamageTarget(Hero[pid], target, pt.dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif

            set SoakedDebuff.add(Hero[pid], target).duration = 5.
        endloop
    elseif pt.dur <= 0 then
        call DestroyEffectTimed(AddSpecialEffect("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", pt.x, pt.y), 3.)
        call TimerList[pid].removePlayerTimer(pt)
    endif
        
    call DestroyGroup(ug)    
    
    set ug = null
    set target = null
endfunction

function Electrocute takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target
    
    if UnitAlive(Hero[pid]) and HeroID[pid] == HERO_ELEMENTALIST then
    
        call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 900., Condition(function FilterEnemy))

        set target = FirstOfGroup(ug)

        if target != null then
            set bj_lastCreatedUnit = GetDummy(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 'A09W', 1, 1.)
            call SetUnitOwner(bj_lastCreatedUnit, Player(pid - 1), false)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(bj_lastCreatedUnit), GetUnitX(target) - GetUnitX(bj_lastCreatedUnit)))
            call InstantAttack(bj_lastCreatedUnit, target)
        endif
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
endfunction

function StanceAbilityDelay takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
        
    call UnitRemoveAbility(Hero[pid], 'Avul')
    call UnitRemoveAbility(Hero[pid], 'A03C')
    call UnitAddAbility(Hero[pid], 'A03C')
endfunction

function DeathStrikeTP takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real x = GetUnitX(pt.target) - 80 * Cos(GetUnitFacing(pt.target) * bj_DEGTORAD)
	local real y = GetUnitY(pt.target) - 80 * Sin(GetUnitFacing(pt.target) * bj_DEGTORAD)

    call BlzPauseUnitEx(pt.target, false)
    if IsTerrainWalkable(x, y) then
        call SetUnitXBounded(Hero[pid], x)
        call SetUnitYBounded(Hero[pid], y)
        call BlzSetUnitFacingEx(Hero[pid], Atan2(GetUnitY(pt.target) - y, GetUnitX(pt.target) - x)) 
    endif
    call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", pt.target, "origin"))
    call UnitDamageTarget(Hero[pid], pt.target, pt.spell.values[0] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    call IssueTargetOrder(Hero[pid], "smart", pt.target)

    call TimerList[pid].removePlayerTimer(pt)
endfunction

function Unimmobilize takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    call UnitRemoveAbility(pt.target, 'S00I')
    call SetUnitTurnSpeed(pt.target, GetUnitDefaultTurnSpeed(pt.target))
    
    call TimerList[pid].removePlayerTimer(pt)
endfunction

function ToneOfDeath takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null
    local real angle = 0.
    local real x = 0.
    local real y = 0.
    local integer index = 0
    local integer count = 0
    local real damage = (0.5 + 0.5 * GetUnitAbilityLevel(Hero[pid], 'A02K')) * GetHeroInt(Hero[pid], true) * BOOST[pid]
    local real rand = GetRandomReal(bj_PI / -9., bj_PI / 9.)

    set pt.dur = pt.dur - 1
    
    if pt.dur > 0 then
        set x = GetUnitX(pt.target) + 3 * Cos(pt.angle)
        set y = GetUnitY(pt.target) + 3 * Sin(pt.angle)

        //blackhole movement
        call SetUnitXBounded(pt.target, x)
        call SetUnitYBounded(pt.target, y)

        call MakeGroupInRange(pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), 350. * LBOOST[pid], Condition(function FilterEnemy))

        set count = BlzGroupGetSize(ug)

        if count > 0 then
            loop
                set target = BlzGroupUnitAt(ug, index)
                //enemy movement
                if GetUnitMoveSpeed(target) > 0 then
                    set angle = Atan2(GetUnitY(pt.target) - GetUnitY(target), GetUnitX(pt.target) - GetUnitX(target))
                    set x = GetUnitX(target) + (17. + 30. / (UnitDistance(target, pt.target) + 1)) * Cos(angle + rand)
                    set y = GetUnitY(target) + (17. + 30. / (UnitDistance(target, pt.target) + 1)) * Sin(angle + rand)
                    
                    if GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(x, y) then
                        if IsUnitType(target, UNIT_TYPE_HERO) == false then
                            call SetUnitPathing(target, false)
                        endif
                        call SetUnitXBounded(target, x)
                        call SetUnitYBounded(target, y)
                    endif
                endif

                //damage per second
                if ModuloReal(pt.dur, 33.) == 0 then
                    call UnitDamageTarget(Hero[pid], target, damage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                endif

                set index = index + 1
                exitwhen index >= count
            endloop
        endif
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
endfunction

function ResetAza takes nothing returns nothing
	if GetWidgetLife(Boss[BOSS_AZAZOTH])>0.5 then
		call PauseUnit(Boss[BOSS_AZAZOTH],false)
		call SetUnitAnimation(Boss[BOSS_AZAZOTH], "stand")
	endif
	set udg_Azazoth_Casting_Spell = false
endfunction

function AstralDevastation takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer i = 1
    local integer i2 = 0
    local group ug = CreateGroup()
    local unit target
    local integer playerBonus = 0
    local real x = 0.
    local real y = 0.

    call DoFloatingTextUnit("Astral Devastation", pt.caster, 2, 70, 0, 11, 100, 40, 40, 0)

    set pt.dur = pt.dur - 1

    if pt.dur > 0 then //azazoth cast
        call SetUnitAnimation(pt.caster, "spell slam")
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", pt.caster, "origin"))
    else
        if pid != BOSS_ID then
            set playerBonus = 20
        else
            call PauseUnit(pt.caster, false)
        endif

        loop
            exitwhen i > 8
            set i2 = -1
            loop
                exitwhen i2 > 1
                set x = GetUnitX(pt.caster) + (150 * i) * Cos(bj_DEGTORAD * (pt.angle + 40 * i2))
                set y = GetUnitY(pt.caster) + (150 * i) * Sin(bj_DEGTORAD * (pt.angle + 40 * i2))
                call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", x, y))
                if i2 == 0 and playerBonus > 0 then
                    call GroupEnumUnitsInRangeEx(pid, ug, x, y, 130. + playerBonus, Condition(function FilterEnemy))
                    set playerBonus = playerBonus + 40
                else
                    call GroupEnumUnitsInRangeEx(pid, ug, x, y, 130., Condition(function FilterEnemy))
                endif
                set i2 = i2 + 1
            endloop
            set i = i + 1
        endloop

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call UnitDamageTarget(pt.caster, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop

        call TimerList[pid].removePlayerTimer(pt)
    endif

    call DestroyGroup(ug)

    set target = null
	set ug = null
endfunction

function AstralAnnihilation takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer i
    local integer i2
    local real angle
    local real x = GetUnitX(pt.caster)
    local real y = GetUnitY(pt.caster)
    local group ug = CreateGroup()
    local unit target

	call DoFloatingTextUnit("Astral Annihilation", Boss[BOSS_AZAZOTH], 2, 70, 0, 11, 100, 40, 40, 0)

    set pt.dur = pt.dur - 1

    if pt.dur > 0 then //azazoth cast
        call SetUnitAnimation(pt.caster, "spell slam")
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", pt.caster, "origin"))
    else
        if pid == BOSS_ID then
            call PauseUnit(pt.caster, false)
        endif

        set i2 = 1
        loop
            exitwhen i2 > 9
            set i = 0
            loop
                exitwhen i > 11
                set angle = 2 * bj_PI * i / 12.
                call DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x + 100 * i2 * Cos(angle), y + 100 * i2 * Sin(angle)))
                set i = i + 1
            endloop
            set i2 = i2 + 1
        endloop
        
        call MakeGroupInRange(pid, ug, x, y, 900., Filter(function FilterEnemy))
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call UnitDamageTarget(pt.caster, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop

        call TimerList[pid].removePlayerTimer(pt)
    endif

	call DestroyGroup(ug)

	set ug = null
    set target = null
endfunction

function ArcaneRadiance takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
	local real dmg = (GetHeroStr(Hero[pid], true) + GetHeroInt(Hero[pid], true)) * BOOST[pid]
	local group ug = CreateGroup()
	local unit target

    set pt.dur = pt.dur - 1
	
	call MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 750 * LBOOST[pid], Condition(function FilterAlive))
	
	loop
		set target = FirstOfGroup(ug)
		exitwhen target == null
		call GroupRemoveUnit(ug, target)
		if IsUnitEnemy(target, Player(pid - 1)) then
			call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", GetUnitX(target), GetUnitY(target)))
			call UnitDamageTarget(Hero[pid], target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		elseif GetUnitTypeId(target) != BACKPACK and GetPlayerId(GetOwningPlayer(target)) < 9 and GetUnitAbilityLevel(target, 'Aloc') == 0 then
			call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", GetUnitX(target), GetUnitY(target)))
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

function WhirlStrikes takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real aoe = (240 + 40 * GetUnitAbilityLevel(Hero[pid], 'A0FP')) * LBOOST[pid]
    local real dmg = (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid],true)) * (GetUnitAbilityLevel(Hero[pid],'A0FP') + 1) * BOOST[pid] * 0.06
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

    if UnitAlive(Hero[pid]) and getRect(GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) == getRect(pt.x, pt.y) then
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
    call TimerStart(pt.timer, dur, false, function MassTeleportFinish)
endfunction

function TeleportHomePeriodic takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    set pt.dur = pt.dur - 0.05

    call BlzSetSpecialEffectTime(pt.sfx, RMaxBJ(0, 1. - pt.dur / pt.agi))

    if pt.dur < 0 then
        call UnitRemoveAbility(Hero[pid],'A050')
        call PauseUnit(Hero[pid],false)
        call PauseUnit(Backpack[pid],false)
        
        if UnitAlive(Hero[pid]) then
            call SetUnitPositionLoc(Hero[pid], TownCenter)
            call SetCameraBoundsRectForPlayerEx(Player(pid - 1), gg_rct_Main_Map)
            call PanCameraToTimedLocForPlayer(Player(pid - 1), TownCenter, 0)
        endif

        call BlzSetSpecialEffectTimeScale(pt.sfx, 5.)
        call BlzPlaySpecialEffect(pt.sfx, ANIM_TYPE_DEATH)
        call TimerList[pid].removePlayerTimer(pt)
    endif

	set isteleporting[pid] = false
endfunction

function TeleportHome takes player p, integer dur returns nothing
	local integer pid = GetPlayerId(p) + 1
    local PlayerTimer pt = TimerList[pid].addTimer(pid)
	
	set isteleporting[pid] = true
	
    call PauseUnit(Backpack[pid], true)
	call PauseUnit(Hero[pid], true)
	call UnitAddAbility(Hero[pid], 'A050')
    call BlzUnitHideAbility(Hero[pid], 'A050', true)
    
    set pt.dur = dur
    set pt.agi = dur
    set pt.sfx = AddSpecialEffect("war3mapImported\\Progressbar.mdl", GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 125.0)

    call BlzSetSpecialEffectZ(pt.sfx, 500.0)
    call BlzSetSpecialEffectTimeScale(pt.sfx, 0.001)
    call BlzSetSpecialEffectColorByPlayer(pt.sfx, Player(4))
    call DestroyEffectTimed(pt.sfx, dur)
    call TimerStart(pt.timer, 0.05, true, function TeleportHomePeriodic)
endfunction

function BossBlastTaper takes unit boss, integer baseDamage, integer effectability, real AOE returns nothing
    local real castx = GetUnitX(boss)
    local real casty = GetUnitY(boss)
    local real dx = 0.
    local real dy = 0.
    local group g = CreateGroup()
    local unit target
    local real angle
    local real distance
    local integer i =1

	loop
		exitwhen i > 18
		set angle= bj_PI *i /9.
        set target = GetDummy(castx, casty, effectability, 1, DUMMY_RECYCLE_TIME)
        call SetUnitFlyHeight(target, 150., 0)
        call IssuePointOrder(target, "breathoffire", castx + 40 * Cos(angle), casty + 40 * Sin(angle))
		set i = i + 1
	endloop
	call GroupEnumUnitsInRange(g, castx, casty, AOE, Condition(function ishostileEnemy))
	loop
		set target = FirstOfGroup(g)
		exitwhen target == null
		call GroupRemoveUnit(g, target)
		//call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
		set dx= GetUnitX(target) -castx
		set dy= GetUnitY(target) -casty
		set distance= SquareRoot(dx * dx +dy * dy)
		if distance<150 then
			call UnitDamageTarget(boss,target, baseDamage, true, false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
		else
			call UnitDamageTarget(boss,target, baseDamage /(distance/200.), true, false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
		endif
	endloop

	call DestroyGroup(g)
	call PauseUnit(boss,false)

    set target = null
    set g = null
endfunction

function BossPlusSpell takes unit boss, integer baseDamage, integer hgroup, string speffect returns nothing
    local real castx = GetUnitX(boss)
    local real casty = GetUnitY(boss)
    local real dx
    local real dy
    local integer i = -8
    local group g= CreateGroup()
    local unit target

    if UnitAlive(boss) then
        loop
            exitwhen i > 8
            call DestroyEffect(AddSpecialEffect(speffect, castx +80 * i, casty-75))
            call DestroyEffect(AddSpecialEffect(speffect, castx +80 * i, casty + 75))
            call DestroyEffect(AddSpecialEffect(speffect, castx-75, casty +80 * i))
            call DestroyEffect(AddSpecialEffect(speffect, castx + 75, casty +80 * i))
            set i = i + 1
        endloop
        call GroupEnumUnitsInRange(g, castx, casty, 750, Condition(function ishostileEnemy))
        loop
            set target = FirstOfGroup(g)
            exitwhen target == null
            call GroupRemoveUnit(g, target)
            //call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
            set dx = RAbsBJ(GetUnitX(target)- castx)
            set dy = RAbsBJ(GetUnitY(target)- casty)
            if dx<150 and dy<700 then
                call UnitDamageTarget(boss, target, baseDamage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            elseif dx<700 and dy<150 then
                call UnitDamageTarget(boss, target, baseDamage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
            set target = null
        endloop
    endif

	call DestroyGroup(g)

	set g= null
endfunction

function BossXSpell takes unit boss, integer baseDamage, integer hgroup, string speffect returns nothing
    local real castx = GetUnitX(boss)
    local real casty = GetUnitY(boss)
    local real dx
    local real dy
    local integer i = -8
    local group g= CreateGroup()
    local unit target

    if UnitAlive(boss) then
        loop
            exitwhen i > 8
                call DestroyEffect(AddSpecialEffect(speffect, castx +75 * i, casty +75 * i))
                call DestroyEffect(AddSpecialEffect(speffect, castx +75 * i, casty -75 * i))
            set i = i + 1
        endloop
        call GroupEnumUnitsInRange(g, castx, casty, 750, Condition(function ishostileEnemy))
        loop
            set target = FirstOfGroup(g)
            exitwhen target == null
            call GroupRemoveUnit(g, target)
            set dx = RAbsBJ(GetUnitX(target)- castx)
            set dy = RAbsBJ(GetUnitY(target)- casty)
            if RAbsBJ(dx -dy) <200 then
                call UnitDamageTarget(boss, target, baseDamage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
            set target = null
        endloop
    endif

	call DestroyGroup(g)

	set g= null
endfunction

function BossInnerRing takes unit boss, integer baseDamage, integer hgroup, real AOE, string speffect returns nothing
    local real castx
    local real casty
    local group g
    local unit target
    local real angle
    local integer i =0

    set castx = GetUnitX(boss)
    set casty = GetUnitY(boss)
    set g= CreateGroup()
    loop
        exitwhen i > 6
        set angle= bj_PI *i /3.
        call DestroyEffect(AddSpecialEffect(speffect, castx +AOE*.4 * Cos(angle), casty +AOE*.4 * Sin(angle)))
        call DestroyEffect(AddSpecialEffect(speffect, castx +AOE*.8 * Cos(angle), casty +AOE*.8 * Sin(angle)))
        set i = i + 1
    endloop
    call GroupEnumUnitsInRange(g, castx, casty, AOE, Condition(function ishostileEnemy))
    loop
        set target = FirstOfGroup(g)
        exitwhen target == null
        call GroupRemoveUnit(g, target)
        //call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
        call UnitDamageTarget(boss,target, baseDamage, true, false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
        set target = null
    endloop

	call DestroyGroup(g)

    set g = null
endfunction

function BossOuterRing takes unit boss, integer baseDamage, integer hgroup, real innerRadius, real outerRadius, string speffect returns nothing
    local real castx
    local real casty
    local real dx
    local real dy
    local group g
    local unit target
    local real angle
    local real distance = outerRadius-innerRadius
    local integer i =0

    set castx = GetUnitX(boss)
    set casty = GetUnitY(boss)
    set g= CreateGroup()
    loop
        exitwhen i > 10
        set angle= bj_PI *i /5.
        call DestroyEffect(AddSpecialEffect(speffect, castx +(innerRadius + distance/6)*Cos(angle), casty +(innerRadius + distance/6)*Sin(angle)))
        call DestroyEffect(AddSpecialEffect(speffect, castx +(outerRadius-distance/6)*Cos(angle), casty +(outerRadius-distance/6)*Sin(angle)))
        set i = i + 1
    endloop
    call GroupEnumUnitsInRange(g, castx, casty, outerRadius, Condition(function ishostileEnemy))
    loop
        set target = FirstOfGroup(g)
        exitwhen target == null
        call GroupRemoveUnit(g, target)
        set dx= GetUnitX(target) -castx
        set dy= GetUnitY(target) -casty
        set distance= SquareRoot(dx * dx +dy * dy)
        if distance>innerRadius then
            call UnitDamageTarget(boss,target, baseDamage, true, false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
        endif
        set target = null
    endloop

	call DestroyGroup(g)

    set g = null
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
    local player p = GetTriggerPlayer()
	local button b = GetClickedButton()
	local integer pid = GetPlayerId(p) + 1
	local integer i = 0
	local integer numshown = 0
    local integer name = StringHash(User[p].name)
	
	loop
		exitwhen i > TOTAL_SKINS or b == dSkin[TOTAL_SKINS * pid + i]
		set i = i + 1
	endloop
	
	if b == dSkin[JASS_MAX_ARRAY_SIZE - 1] then
		if dPage[pid] >= TOTAL_SKINS then
			set dPage[pid] = 0
		endif
		
		call DialogClear(dChangeSkin[pid])
		
		set i = dPage[pid]

		loop
			exitwhen numshown > SKINS_PER_PAGE or i > TOTAL_SKINS
			
            if CosmeticTable[name][i + DONATOR_SKIN_OFFSET] > 0 or ispublic[i + DONATOR_SKIN_OFFSET] then
                set numshown = numshown + 1
                if numshown <= SKINS_PER_PAGE then
                    set dSkin[TOTAL_SKINS * pid + i + DONATOR_SKIN_OFFSET] = DialogAddButton(dChangeSkin[pid], dSkinName[i + DONATOR_SKIN_OFFSET], 0)
                endif
            endif

            if numshown <= SKINS_PER_PAGE then
                set dPage[pid] = dPage[pid] + 1
            endif
			
			set i = i + 1
		endloop

		set dSkin[JASS_MAX_ARRAY_SIZE - 1] = DialogAddButton(dChangeSkin[pid], "Next Page", 0)
		
		call DialogAddButton(dChangeSkin[pid], "Cancel", 0)
		call DialogSetMessage(dChangeSkin[pid], "Select Appearance")
		call DialogDisplay(GetTriggerPlayer(), dChangeSkin[pid], true) 

        set b = null
        set p = null
		return
	endif
	
	if i <= TOTAL_SKINS then
        set Profile[pid].skin = i
	endif
	
	call DialogClear(dChangeSkin[pid])
	
	set b = null
    set p = null
endfunction

function ChangeSkin takes player p returns nothing
	local integer pid = GetPlayerId(p) + 1
	local integer i = 0
	local integer numshown = 0
    local integer name = StringHash(User[p].name)
	
	set dPage[pid] = 0
	
	loop
		exitwhen numshown > SKINS_PER_PAGE or i > TOTAL_SKINS

        if CosmeticTable[name][i + DONATOR_SKIN_OFFSET] > 0 or ispublic[i + DONATOR_SKIN_OFFSET] then
            set numshown = numshown + 1
            if numshown <= SKINS_PER_PAGE then
                set dSkin[TOTAL_SKINS * pid + i + DONATOR_SKIN_OFFSET] = DialogAddButton(dChangeSkin[pid], dSkinName[i + DONATOR_SKIN_OFFSET], 0)
            else
                set dSkin[JASS_MAX_ARRAY_SIZE - 1] = DialogAddButton(dChangeSkin[pid], "Next Page", 0)
            endif
        endif
			
        if numshown <= SKINS_PER_PAGE then
            set dPage[pid] = dPage[pid] + 1
        endif

		set i = i + 1
	endloop
	
	call DialogAddButton(dChangeSkin[pid], "Cancel", 0)
	call DialogSetMessage(dChangeSkin[pid], "Select Appearance")
	call DialogDisplay(p, dChangeSkin[pid], true)
endfunction

function CosmeticButtonClick takes nothing returns nothing
    local player p = GetTriggerPlayer()
	local button b = GetClickedButton()
	local integer pid = GetPlayerId(p) + 1
	local integer i = 0
	local integer numshown = 0
    local integer name = StringHash(User[p].name)
	
	loop
		exitwhen i > cosmeticTotal or b == dCosmetic[cosmeticTotal * pid + i]
		set i = i + 1
	endloop
	
	if b == dCosmetic[JASS_MAX_ARRAY_SIZE - 1] then
		if dPage[pid] > cosmeticTotal then
			set dPage[pid] = 0
		endif
		
		call DialogClear(dCosmetics[pid])
		
		set i = dPage[pid]

		loop
            exitwhen numshown > SKINS_PER_PAGE or i > cosmeticTotal

            if CosmeticTable[name][i + DONATOR_AURA_OFFSET] > 0 then
                set numshown = numshown + 1
                if numshown <= SKINS_PER_PAGE then
                    set dCosmetic[cosmeticTotal * pid + i] = DialogAddButton(dCosmetics[pid], cosmeticName[i], 0)
                endif
            endif

            if numshown <= SKINS_PER_PAGE then
                set dPage[pid] = dPage[pid] + 1
            endif
                
            set i = i + 1
        endloop

		set dCosmetic[JASS_MAX_ARRAY_SIZE - 1] = DialogAddButton(dCosmetics[pid], "Next Page", 0)
		
		call DialogAddButton(dCosmetics[pid], "Cancel", 0)
		call DialogDisplay(GetTriggerPlayer(), dCosmetics[pid], true) 

        set b = null
        set p = null
		return
	endif
	
	if i <= cosmeticTotal then
        call CosmeticSpecialEffect(pid, i)
	endif
	
	call DialogClear(dCosmetics[pid])
	
    set b = null
    set p = null
endfunction

function DisplaySpecialEffects takes player p returns nothing
    local integer pid = GetPlayerId(p) + 1
	local integer i = 0
	local integer numshown = 0
    local integer name = StringHash(User[p].name)

	set dPage[pid] = 0
	
	loop
		exitwhen numshown > SKINS_PER_PAGE or i > cosmeticTotal
		
        if CosmeticTable[name][i + DONATOR_AURA_OFFSET] > 0 then
            set numshown = numshown + 1
            if numshown <= SKINS_PER_PAGE then
                set dCosmetic[cosmeticTotal * pid + i] = DialogAddButton(dCosmetics[pid], cosmeticName[i], 0)
            else
                set dCosmetic[JASS_MAX_ARRAY_SIZE - 1] = DialogAddButton(dCosmetics[pid], "Next Page", 0)
            endif
		endif

        if numshown <= SKINS_PER_PAGE then
            set dPage[pid] = dPage[pid] + 1
        endif
			
		set i = i + 1
	endloop
	
	call DialogAddButton(dCosmetics[pid], "Cancel", 0)
	call DialogDisplay(p, dCosmetics[pid], true)
endfunction

function Invigoration takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local real heal = (GetHeroInt(Hero[pid],true) * .15)
    local real mp = BlzGetUnitMaxMana(Hero[pid]) * 0.02
    local group ug = CreateGroup()
    local unit target
    local unit ftarget
    local real percent = 100.

    set pt.dur = pt.dur + 1

    call MakeGroupInRange(pid, ug, pt.x, pt.y, 850 * LBOOST[pid], Condition(function FilterAllyHero))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if percent > GetUnitLifePercent(target) then
            set percent = GetUnitLifePercent(target)
            set ftarget = target
        endif
    endloop

    if pt.dur > 10 then
        set mp = mp * 2
    endif

    if GetUnitCurrentOrder(Hero[pid]) == OrderId("clusterrockets") and GetWidgetLife(Hero[pid]) >= .406 then
        if ModuloReal(pt.dur, 2.) == 0 then
            call MP(Hero[pid], mp)
        endif
        set heal = (heal + BlzGetUnitMaxHP(ftarget) * 0.01) * BOOST[pid]
        call HP(ftarget, heal)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", ftarget, "origin"))
    else
        call TimerList[pid].removePlayerTimer(pt)
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
    set ftarget = null
endfunction

function NerveGas takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target
    local integer count = BlzGroupGetSize(pt.ug)
    local integer index = 0
    
    set pt.dur = pt.dur - 1
	
	if pt.dur < 0 then
        call TimerList[pid].removePlayerTimer(pt)
	else
        if count > 0 then
            loop
                set target = BlzGroupUnitAt(pt.ug, index)
                if UnitAlive(target) and GetUnitAbilityLevel(target, 'Avul') == 0 then
                    call UnitDamageTarget(Hero[pid], target, pt.dmg / pt.armor, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
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
    local PlayerTimer pt
    
    if caster == Hero[pid] then
        set Moving[pid] = false
    endif

	if sid == 'AImt' or sid == 'A02J' or sid == 'A018' then //God Blink / Backpack Teleport
        if UnitAlive(Hero[pid]) == false then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport while dead.")
        elseif sid == 'A018' and ChaosMode then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTimedTextToPlayer(p, 0, 0, 20.00, "With the Gods dead, these items no longer have the ability to move around the map with free will. Their powers are dead, however their innate fighting powers are left unscathed.")
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
    elseif sid == 'A01S' or sid == 'A03D' or sid == 'A061' then //Short blink
        if getRect(x, y) != getRect(GetSpellTargetX(), GetSpellTargetY()) then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport there.")
        endif

    elseif sid == 'A0FV' then //Teleport Home
        if UnitAlive(Hero[pid]) == false then
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
        elseif getRect(x, y) == gg_rct_Main_Map or getRect(x, y) == gg_rct_Cave or getRect(x, y) == gg_rct_Gods_Vision or getRect(x, y) == gg_rct_Tavern then
        else
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "Unable to teleport out of here.")
        endif
	elseif sid == 'A048' then //Resurrection
        if target != HeroGrave[tpid] then
            call IssueImmediateOrder(caster, "stop")
            call DisplayTextToPlayer(p, 0, 0, "You must target a tombstone!")
        elseif GetUnitAbilityLevel(HeroGrave[tpid], 'A045') > 0 then
            call IssueImmediateOrder(caster, "stop")
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

function OnChannel takes nothing returns boolean
    if GetSpellAbilityId() == 'IATK' then
        call UnitRemoveAbility(GetTriggerUnit(), 'IATK')
    endif

    return false
endfunction

function OnLearn takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local integer sid = GetLearnedSkill()
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local integer ablev = GetUnitAbilityLevel(u, sid)
    local ability abil = null
    local integer i = 0

    //find ability
    loop
        set abil = BlzGetUnitAbilityByIndex(u, i)
        exitwhen BlzGetAbilityId(abil) == sid

        set i = i + 1
    endloop

    //store original tooltip
    if SpellTooltips[sid].string[ablev] == null then
        set SpellTooltips[sid].string[ablev] = BlzGetAbilityStringLevelField(abil, ABILITY_SLF_TOOLTIP_NORMAL_EXTENDED, ablev - 1)
    endif

    //remove bracket indicators
    call UpdateSpellTooltips(pid)

    if sid == 'A032' then //Gaia Armor
        call UnitAddAbility(u, 'A033')
        call BlzUnitHideAbility(u, 'A033', true)
        set aoteCD[pid] = true
    elseif sid == ADAPTIVESTRIKE.id then //adaptive strike
        if ablev == 1 then
            call UnitDisableAbility(u, sid, true)
            call BlzUnitHideAbility(u, sid, false)
        endif

        if SpellTooltips[ADAPTIVESTRIKE.id2].string[ablev] == null then
            set SpellTooltips[ADAPTIVESTRIKE.id2].string[ablev] = BlzGetAbilityStringLevelField(BlzGetUnitAbility(u, sid), ABILITY_SLF_TOOLTIP_NORMAL_EXTENDED, ablev - 1)
        endif
    elseif sid == LIMITBREAK.id then //limit break
        if GetLocalPlayer() == GetOwningPlayer(u) and ablev == 1 then
            call BlzFrameSetVisible(LimitBreakBackdrop, true)
        endif
    endif

    set u = null

    return false
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
    local integer ablev = GetUnitAbilityLevel(caster, sid)
    local group ug = CreateGroup()
    local real x = GetUnitX(caster)
    local real y = GetUnitY(caster)
    local real x2 = 0
    local real y2 = 0
    local real dmg = 0
    local real heal = 0
    local real angle = 0
    local real dur = 0
    local real aoe = 0
    local integer i = 0
    local integer i2 = 0
    local group g = null
    local unit u = null
    local timer t = null
    local User U = User.first
    local PlayerTimer pt = 0
    local Buff myBuff
    local Spell spell
    local Item itm2

    //store last cast spell id
    set lastCast[pid] = sid
    
    //calculate spell values for player
    if LoadInteger(SAVE_TABLE, KEY_SPELLS, sid) != 0 then
        set spell = Spell.create(LoadInteger(SAVE_TABLE, KEY_SPELLS, sid))
        call spell.setValues(pid)
    endif

	//========================
	//Actions
	//========================

	if sid == 'A03V' then //Move Item (Hero)
        if ItemsDisabled[pid] == false then
            call UnitRemoveItem(caster, itm)
            call UnitAddItem(Backpack[pid], itm)
        endif
	elseif sid == 'A0L0' then //Hero Info
		call StatsInfo(p, pid)
	elseif sid == 'A0GD' then //Item Info
        call ItemInfo(pid, Item[itm])
	elseif sid == 'A06X' then //Quest Progress
		call DisplayQuestProgress(p)
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
	elseif sid == 'A00B' then //Movement Toggle
		call ForceRemovePlayer(rightclicked, p)
		if IsPlayerInForce(p, rightclickactivator) then
            call DisplayTextToPlayer(p, 0, 0, "Movement Toggle disabled.")
			call ForceRemovePlayer(rightclickactivator, p)
		else
            call DisplayTextToPlayer(p, 0, 0, "Movement Toggle enabled.")
			call ForceAddPlayer(rightclickactivator, p)
		endif
    elseif sid == 'A02T' then //Hero Panels
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
        if DMG_NUMBERS[pid] == 0 then
            set DMG_NUMBERS[pid] = 1
            call DisplayTextToPlayer(p, 0, 0, "Damage Numbers for allied damage received disabled.")
        elseif DMG_NUMBERS[pid] == 1 then
            set DMG_NUMBERS[pid] = 2
            call DisplayTextToPlayer(p, 0, 0, "Damage Numbers for all damage disabled.")
        else
            set DMG_NUMBERS[pid] = 0
            call DisplayTextToPlayer(p, 0, 0, "Damage Numbers enabled.")
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
	//Item Spells
	//========================
	
	elseif sid == 'A083' then //Paladin Book
		set dmg = 3 * GetHeroInt(caster, true) * BOOST[pid]
        if GetUnitTypeId(target) == BACKPACK then
            call HP(Hero[tpid], dmg)
        else
            call HP(target, dmg)
        endif
	elseif sid == 'A02A' then //Instill Fear
		if BlzBitAnd(HERO_PROF[pid], PROF_DAGGER) != 0 then
            call DummyCastTarget(p, target, 'A0AE', 1, x, y, "firebolt")
        else
            call DisplayTimedTextToPlayer(p,0,0, 15., "You do not have the proficiency to use this spell!")
		endif
    elseif sid == 'A055' then //Darkest of Darkness
        set DarkestOfDarkness.add(Hero[pid], Hero[pid]).duration = 20.
	elseif sid == 'A0IS' then //Abyssal Bow
		set dmg= (UnitGetBonus(caster,BONUS_DAMAGE) + GetHeroAgi(caster, true)) * 4 * BOOST[pid]
		if BlzBitAnd(HERO_PROF[pid], PROF_BOW) == 0 then
			set dmg= dmg * 0.5
		endif
		call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
	elseif sid == 'A07G' then //Azazoth Sword (Bladestorm)
		if BlzBitAnd(HERO_PROF[pid], PROF_SWORD) != 0 then
            set pt = TimerList[pid].addTimer(pid)
            set pt.dur = 5.
            call TimerStart(pt.timer, 0.05, true, function AzazothBladeStorm)
        else
            call DisplayTimedTextToPlayer(p,0,0, 15., "You do not have the proficiency to use this spell!")
		endif
	elseif sid == 'A0SX' then //Azazoth Staff
		if BlzBitAnd(HERO_PROF[pid], PROF_STAFF) != 0 then
            set pt = TimerList[pid].addTimer(pid)
            set pt.caster = caster
            set pt.dmg = 40 * GetHeroInt(caster, true) * BOOST[pid]
            set pt.angle = bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
            set pt.dur = 0
            call TimerStart(pt.timer, 0., false, function AstralDevastation)
        else
            call DisplayTimedTextToPlayer(p, 0, 0, 15., "You do not have the proficiency to use this spell!")
        endif
	elseif sid == 'A0B5' then //Azazoth Hammer (Stomp)
		if BlzBitAnd(HERO_PROF[pid], PROF_HEAVY) != 0 then
            call MakeGroupInRange(pid, ug, x, y, 550.00, Condition(function FilterEnemy))
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                set AzazothHammerStomp.add(caster, target).duration = 15.
                call UnitDamageTarget(caster, target, 15.00 * GetHeroStr(caster, true) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endloop
        else
            call DisplayTimedTextToPlayer(p,0,0, 15., "You do not have the proficiency to use this spell!")
        endif

	elseif sid == 'A00E' then //final blast
		set i = 1
		call MakeGroupInRange(pid, ug, x, y, 600.00, Condition(function FilterEnemy))
		loop
			exitwhen i > 12
			if i < 7 then
				set x = GetUnitX(caster) + 200 * Cos(60.00 * i * bj_DEGTORAD)
				set y = GetUnitY(caster) + 200 * Sin(60.00 * i * bj_DEGTORAD)
				call DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
			endif
			set x = GetUnitX(caster) + 400 * Cos(60.00 * i * bj_DEGTORAD)
			set y = GetUnitY(caster) + 400 * Sin(60.00 * i * bj_DEGTORAD)
			call DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
			set x = GetUnitX(caster) + 600 * Cos(60.00 * i * bj_DEGTORAD)
			set y = GetUnitY(caster) + 600 * Sin(60.00 * i * bj_DEGTORAD)
			call DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
			set i = i + 1
		endloop
		loop
			set u = FirstOfGroup(ug)
			exitwhen u == null
			call GroupRemoveUnit(ug, u)
			call UnitDamageTarget(caster, u, 10.00 * (GetHeroInt(caster, true) + GetHeroAgi(caster, true) + GetHeroStr(caster, true)) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		endloop
	
	//========================
	//Backpack
	//========================
		
	elseif sid == 'A0DT' then //Move Item (Backpack)
        if ItemsDisabled[pid] == false then
            call UnitRemoveItem(caster, itm)
            call UnitAddItem(Hero[pid], itm)
        endif
	elseif sid == 'A0KX' then //Change Skin
		call ChangeSkin(p)
    elseif sid == 'A04N' then //Special Effects
        call DisplaySpecialEffects(p)
    elseif sid == 'A02J' then //Mass Teleport
        if ablev > 1 then
            call MassTeleport(pid, target, ablev, 3 - ablev * .25)
        else
            call MassTeleport(pid, target, ablev, 3)
        endif
	elseif sid == 'A00R' then //Next Backpack Page
        set i = MAX_INVENTORY_SLOTS + 5 //29
        loop
            exitwhen i == 11 //last slot of visible backpack
            set Profile[pid].hero.items[i] = Profile[pid].hero.items[i - 6]

            set i = i - 1
        endloop

        set i = 0
        loop
            exitwhen i > 5

            set itm = UnitItemInSlot(Backpack[pid], i)
            call UnitRemoveItem(Backpack[pid], itm)
            call SetItemPosition(itm, 30000., 30000.)
            call SetItemVisible(itm, false)

            set i = i + 1
        endloop

        set i = 0
        set itm = null
        loop
            exitwhen i > 5
            if Profile[pid].hero.items[MAX_INVENTORY_SLOTS + i] != 0 then
                set itm = Profile[pid].hero.items[MAX_INVENTORY_SLOTS + i].obj
                call SetItemVisible(itm, true)
                call UnitAddItem(Backpack[pid], itm)
                call UnitDropItemSlot(Backpack[pid], itm, i)
                call SetItemDroppable(itm, (not ItemsDisabled[pid]))
                set Profile[pid].hero.items[MAX_INVENTORY_SLOTS + i] = 0
            endif
            set i = i + 1
        endloop

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
			elseif GetItemTypeId(itm) == 'I062' then
				call HP(Hero[pid], 500)
				set i = 6
            elseif GetItemTypeId(itm) == 'I0MP' then
                call HP(Hero[pid], 50000 + BlzGetUnitMaxHP(Hero[pid]) * 0.08)
                call MP(Hero[pid], BlzGetUnitMaxMana(Hero[pid]) * 0.08)
				set i = 6
			elseif GetItemTypeId(itm) == 'I0MQ' then
                call HP(Hero[pid], BlzGetUnitMaxHP(Hero[pid]) * 0.15)
				set i = 6
			endif
            set i = i + 1
		endloop
	
		if i == 6 then
			call DisplayTextToPlayer(p,0,0, "You do not have a potion to consume.")
		elseif i == 7 then
			if GetItemCharges(itm) < 2 then
                call Item[itm].destroy()
			else
                set Item[itm].charge = Item[itm].charges - 1
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
			elseif GetItemTypeId(itm) == 'I06E' then
				call MP(Hero[pid], 500)
				set i = 6
            elseif GetItemTypeId(itm) == 'I0MP' then
                call HP(Hero[pid], 50000 + BlzGetUnitMaxHP(Hero[pid]) * 0.08)
                call MP(Hero[pid], BlzGetUnitMaxMana(Hero[pid]) * 0.08)
				set i = 6
			elseif GetItemTypeId(itm) == 'I0MQ' then
                call HP(Hero[pid], BlzGetUnitMaxHP(Hero[pid]) * 0.15)
				set i = 6
			endif
			set i = i + 1
		endloop
	
		if i == 6 then
			call DisplayTextToPlayer(p,0,0, "You do not have a potion to consume.")
		elseif i == 7 then
			if GetItemCharges(itm) < 2 then
                call Item[itm].destroy()
			else
                set Item[itm].charge = Item[itm].charges - 1
			endif
		endif
    elseif sid == 'A05N' then //Unique Consumable (Backpack)
		loop
			exitwhen i > 5
			set itm = UnitItemInSlot(caster, i)
			if GetItemTypeId(itm) == 'I02K' then
                if UnitAlive(Hero[pid]) then
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
                call Item[itm].destroy()
			else
                set Item[itm].charge = Item[itm].charges - 1
			endif
		endif

	//====================
    //Arcane Warrior
    //====================
	
	elseif sid == 'A0KD' then //Arcane Strike
		set dmg = (GetUnitAbilityLevel(caster, sid) * 0.5) * (GetHeroStr(caster, true) + GetHeroInt(caster, true)) * BOOST[pid]
		
		call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 300. * LBOOST[pid], Condition(function FilterEnemy))
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
            set pt.dur = ArcaneMightFormula(pid) * BOOST[pid] //statboost
            set pt.target = target
            call UnitAddBonus(target, BONUS_HERO_STR, R2I(pt.dur))
            if GetUnitTypeId(target) != SUMMON_DESTROYER then
                call UnitAddBonus(target, BONUS_HERO_AGI, R2I(pt.dur))
            endif
            call UnitAddBonus(target, BONUS_HERO_INT, R2I(pt.dur))
            set pt.dmg = (UnitGetBonus(target, BONUS_DAMAGE) + GetHeroStat(MainStat(target),target,true)) * (ablev + 7) / 20. * BOOST[pid] //attack boost
            call UnitAddBonus(target,BONUS_DAMAGE, R2I(pt.dmg))
            call TimerStart(pt.timer, 15. * BOOST[pid], false, function ArcaneMightExpire)
        endif
	elseif sid == 'A0KC' then //Arcane Nova
		call GroupEnumUnitsInRange(ug, GetSpellTargetX(), GetSpellTargetY(), 300 * LBOOST[pid], Condition(function isalive))
		set dmg= (ablev * .5) * (GetHeroStr(caster,true) + GetHeroInt(caster,true)) * BOOST[pid]
		loop
			set target = FirstOfGroup(ug)
			exitwhen target == null
			call GroupRemoveUnit(ug, target)
			if IsUnitType(target, UNIT_TYPE_STRUCTURE)==false then
				if IsUnitAlly(target, p) then
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
        set pt.dur = 10 * BOOST[pid]
        call DestroyEffectTimed(AddSpecialEffectTarget("war3mapImported\\HolyAurora.MDX", caster, "origin"), pt.dur)
        call TimerStart(pt.timer, 2., true, function ArcaneRadiance)
		
	//====================
    //Savior
    //====================

    elseif sid == LIGHTSEAL.id then //Light Seal
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = spell.values[0] * LBOOST[pid]
        set pt.x = GetSpellTargetX()
        set pt.y = GetSpellTargetY()
        set pt.caster = caster
        set pt.target = GetDummy(pt.x, pt.y, 0, 0, pt.dur)
        set pt.armor = 0
        set pt.str = 0
        set pt.aoe = 450.
        set pt.tag = 'Ltsl'
        set pt.ug = CreateGroup()
        set pt.spell = spell

        call BlzSetUnitSkin(pt.target, 'h046')
        call UnitDisableAbility(pt.target, 'Amov', true)
        call SetUnitScale(pt.target, 6.1, 6.1, 6.1)
        call BlzSetUnitFacingEx(pt.target, 270)
        call SetUnitVertexColor(pt.target, 255, 255, 200, 200)
        call SetUnitAnimation(pt.target, "birth")
        call SetUnitTimeScale(pt.target, 0.9)
        call DelayAnimation(pid, pt.target, 1., 0, 1., false)

        call TimerStart(pt.timer, pt.dur, false, function LightSeal)

	elseif sid == DIVINEJUDGEMENT.id then //Divine Judgement
        set pt = TimerList[pid].addTimer(pid)
		set pt.angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set pt.target = GetDummy(x, y, 0, 0, DUMMY_RECYCLE_TIME)
        set pt.caster = caster
        set pt.dur = 1000.
		set pt.dmg = spell.values[0] * BOOST[pid]
        set pt.ug = CreateGroup()
        set pt.spell = spell

        call BlzSetUnitSkin(pt.target, 'h00X')
        call BlzSetUnitFacingEx(pt.target, pt.angle * bj_RADTODEG)
        call SetUnitScale(pt.target, 1.1, 1.1, 0.8)
        call SetUnitFlyHeight(pt.target, 25.00, 0.)

        call TimerStart(pt.timer, 0.03, true, function DivineJudgement)
	
	elseif sid == SAVIORSGUIDANCE.id then //Savior's Guidance
		set dmg = spell.values[0] * BOOST[pid]
        set dur = 9 + ablev

        call spell.destroy()

        set pt = TimerList[pid].get(caster, null, 'Ltsl')

        //light seal augment
        if pt != 0 then
            call MakeGroupInRange(pid, pt.ug, pt.x, pt.y, pt.aoe, Condition(function FilterAllyHero))

            if caster != target and UnitAlive(target) then
                call GroupAddUnit(pt.ug, target)
            endif
            
            call GroupAddUnit(pt.ug, caster)

            loop
                set target = FirstOfGroup(pt.ug)
                exitwhen target == null
                call GroupRemoveUnit(pt.ug, target)
                call shield.add(target, dmg, dur)
            endloop
        //normal cast
        else
            if caster != target and target != null then
                call shield.add(target, dmg, dur)
            endif
            
            call shield.add(caster, dmg, dur)
        endif
        
	elseif sid == 'A0AT' then //Thunder Clap
		call MakeGroupInRange(pid, ug, x, y, spell.values[1] * LBOOST[pid], Condition(function FilterEnemy))

        set pt = TimerList[pid].get(caster, null, 'Ltsl')

        if pt != 0 then
            call GroupEnumUnitsInRangeEx(pid, ug, pt.x, pt.y, pt.aoe, Condition(function FilterEnemy))
            set LightSealBuff.add(caster, caster).duration = 20.
        endif

		loop
			set target = FirstOfGroup(ug)
			exitwhen target == null
			call GroupRemoveUnit(ug,target)
            set SaviorThunderClap.add(caster, target).duration = 5.
            if pt != 0 and IsUnitInRangeXY(target, pt.x, pt.y, pt.aoe) then
                if IsUnitType(target, UNIT_TYPE_HERO) == true then
                    call LightSealBuff(Buff.get(caster, caster, LightSealBuff.typeid)).addStack(5)
                else
                    call LightSealBuff(Buff.get(caster, caster, LightSealBuff.typeid)).addStack(1)
                endif
            endif
			call UnitDamageTarget(caster, target, spell.values[0] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		endloop

        call spell.destroy()

        call Taunt(caster, pid, 800., true, 2000, 2000)

	elseif sid == RIGHTEOUSMIGHT.id then //Righteous Might
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 60
        set pt.dmg = BlzGetUnitRealField(caster, UNIT_RF_SCALING_VALUE)
        set pt.caster = caster

        set myBuff = RighteousMightBuff.create()
        set RighteousMightBuff(myBuff).dmg = spell.values[0]
        set RighteousMightBuff(myBuff).armor = spell.values[1]
        set myBuff.check(caster, caster).duration = spell.values[4] * LBOOST[pid]

        call HP(caster, spell.values[2] * LBOOST[pid])

		call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\HolyAwakening.mdx", caster, "origin"))

		set i = 1
		loop
			exitwhen i > 24
			set angle= 2 * bj_PI *i /24.
			call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", x + 500 * Cos(angle), y + 500 * Sin(angle)))
			set i = i + 1
		endloop

        call MakeGroupInRange(pid, ug, x, y, 500 * LBOOST[pid], Condition(function FilterEnemy))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call UnitDamageTarget(Hero[pid], target, spell.values[3] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop

        call TimerStart(pt.timer, 0.01, true, function Grow)

        call spell.destroy()
		
	//====================
    //Bloodzerker
    //====================
    
    elseif sid == BLOODLEAP.id then //blood leap
        //minimum distance
        set angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set dur = RMaxBJ(DistanceCoords(x, y, GetSpellTargetX(), GetSpellTargetY()), 400)
        set x = x + dur * Cos(angle)
        set y = y + dur * Sin(angle)

        if IsTerrainWalkable(x, y) then
            call UnitDamageTarget(caster, caster, 0.1 * BlzGetUnitMaxHP(caster), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_DIVINE, WEAPON_TYPE_WHOKNOWS)

            set pt = TimerList[pid].addTimer(pid)
            set pt.angle = angle
            set pt.dur = dur
            set pt.armor = dur
            set pt.speed = 40.
            set pt.target = caster
            set pt.x = x
            set pt.y = y
            set pt.spell = spell

            if UnitAddAbility(caster, 'Amrf') then
                call UnitRemoveAbility(caster, 'Amrf')
            endif

            call SetUnitTimeScale(caster, 0.75)
            call SetUnitPathing(caster, false)
            call SetUnitPropWindow(caster, 0)
            call DelayAnimation(pid, caster, (pt.dur / 30. * 0.03) + 0.5, 1, 0, false)
            call TimerStart(pt.timer, 0.03, true, function LeapPeriodic)
		else
            call IssueImmediateOrder(caster, "stop")
			call DisplayTextToPlayer(p, 0, 0, "Cannot target there")
            call BlzStartUnitAbilityCooldown(caster, sid, 0)
		endif
	elseif sid == BLOODFRENZY.id then //Blood Frenzy
        set BloodFrenzyBuff.add(caster, caster).duration = 5.
	elseif sid == BLOODCURDLINGSCREAM.id then //Blood-curdling Scream
        call UnitDamageTarget(caster, caster, 0.1 * BlzGetUnitMaxHP(caster), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_DIVINE, WEAPON_TYPE_WHOKNOWS)
		call MakeGroupInRange(pid, ug, x, y, spell.values[0] * LBOOST[pid], Condition(function FilterEnemy))

		loop
			set target = FirstOfGroup(ug)
			exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set BloodCurdlingScreamDebuff.add(caster, target).duration = (ablev + 6) * LBOOST[pid]
		endloop
    elseif sid == UNDYINGRAGE.id then //undying rage
        set UndyingRageBuff.add(caster, caster).duration = 10.
	
	//====================
    //Warrior
    //====================
    
    elseif sid == SPINDASH.id or sid == SPINDASH.id2 then //spin dash
        set x = GetSpellTargetX()
        set y = GetSpellTargetY()

        if IsTerrainWalkable(x, y) or sid == SPINDASH.id2 then
            if GetUnitAbilityLevel(caster, ADAPTIVESTRIKE.id2) == 0 then
                call UnitDisableAbility(caster, ADAPTIVESTRIKE.id, false)
            endif

            if sid == SPINDASH.id2 then
                call UnitDisableAbility(caster, SPINDASH.id, false)
                call UnitRemoveAbility(caster, SPINDASH.id2)

                set pt = TimerList[pid].get(caster, null, SPINDASH.typeid)
                set x = pt.x
                set y = pt.y

                call BlzStartUnitAbilityCooldown(caster, SPINDASH.id, 3. + TimerGetRemaining(pt.timer))
                call TimerList[pid].removePlayerTimer(pt)

                set pt = TimerList[pid].get(caster, null, 'sdas')
                if pt != 0 then
                    call TimerList[pid].removePlayerTimer(pt)
                endif
            else
                call UnitDisableAbility(caster, SPINDASH.id, true)
                call UnitAddAbility(caster, SPINDASH.id2)

                set pt = TimerList[pid].addTimer(pid)
                set pt.x = GetUnitX(caster)
                set pt.y = GetUnitY(caster)
                set pt.caster = caster
                set pt.tag = SPINDASH.typeid

                call TimerStart(pt.timer, 2., false, function SpinDashRecast)
            endif

            set pt = TimerList[pid].addTimer(pid)
            set pt.x = x
            set pt.y = y
            set pt.angle = Atan2(y - GetUnitY(caster), x - GetUnitX(caster))
            set pt.dur = RMinBJ(1000., DistanceCoords(GetUnitX(caster), GetUnitY(caster), x, y))
            set pt.speed = 40.
            set pt.caster = caster
            set pt.ug = CreateGroup()
            set pt.spell = spell
            set pt.tag = 'sdas'

            call SetUnitPropWindow(caster, 0)
            call SetUnitTimeScale(caster, 2.)
            call AddUnitAnimationProperties(caster, "spin", true)
            call SetUnitPathing(caster, false)
            call TimerStart(pt.timer, 0.03, true, function SpinDashPeriodic)
		else
			call DisplayTextToPlayer(p, 0, 0, "Cannot target there")
		endif
	elseif sid == INTIMIDATINGSHOUT.id then //intimidating shout
        if GetUnitAbilityLevel(caster, ADAPTIVESTRIKE.id2) == 0 then
            call UnitDisableAbility(caster, ADAPTIVESTRIKE.id, false)
        endif

        call MakeGroupInRange(pid, ug, x, y, spell.values[0] * LBOOST[pid], Condition(function FilterEnemy))

        if limitBreak[pid] == 3 then
            set bj_lastCreatedEffect = AddSpecialEffectTarget("war3mapImported\\BattleCryCaster.mdx", caster, "origin")
            call BlzSetSpecialEffectColor(bj_lastCreatedEffect, 255, 255, 0)
        else
            set bj_lastCreatedEffect = AddSpecialEffectTarget("Abilities\\Spells\\Other\\HowlOfTerror\\HowlCaster.mdl", caster, "origin")
        endif

        call DestroyEffect(bj_lastCreatedEffect)

		loop
			set target = FirstOfGroup(ug)
			exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set IntimidatingShoutDebuff.add(caster, target).duration = spell.values[1] * LBOOST[pid]
		endloop
	elseif sid == LIMITBREAK.id then //limit break
        call BlzStartUnitAbilityCooldown(caster, ADAPTIVESTRIKE.id, 0.)
        call BlzSetUnitAbilityCooldown(caster, ADAPTIVESTRIKE.id, GetUnitAbilityLevel(caster, ADAPTIVESTRIKE.id) - 1, 0.)

        set LimitBreakBuff.add(caster, caster).duration = spell.values[0] * LBOOST[pid]
        call spell.destroy()

	//====================
    //Vampire Lord
    //====================

    elseif sid == 'A07A' then //blood leech
		set dmg = (2.75 + 0.25 * ablev) * (GetHeroAgi(Hero[pid], true) + GetHeroStr(caster,true)) * BOOST[pid]
        call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        set BloodBank[pid] = RMinBJ(BloodBank[pid] + 10 * GetHeroAgi(Hero[pid], true) + 5 * GetHeroStr(Hero[pid], true), 200 * GetHeroInt(Hero[pid], true))
    elseif sid == 'A09B' then //blood domain
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 5.
        if GetHeroStr(caster, true) > GetHeroAgi(caster, true) and GetUnitAbilityLevel(caster, 'A097') > 0 then
            set pt.aoe = 400 * 2 * LBOOST[pid]
        else
            set pt.aoe = 400 * LBOOST[pid]
        endif

        call MakeGroupInRange(pid, ug, x, y, pt.aoe, Condition(function FilterEnemyDead))

        set g = CreateGroup()
        call MakeGroupInRange(pid, g, x, y, pt.aoe, Condition(function FilterEnemy))

        set pt.dmg = ((0.5 + 0.5 * ablev) * GetHeroAgi(Hero[pid], true)) + ((1.5 + 0.5 * ablev) * GetHeroStr(Hero[pid], true))
        set pt.dmg = RMaxBJ(pt.dmg * 0.2, pt.dmg * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(g) - 1)))
        set pt.armor = 1 * (GetHeroAgi(Hero[pid], true) + GetHeroStr(Hero[pid], true))
        set pt.armor = RMaxBJ(pt.armor * 0.2, pt.armor * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(ug) - 1)))

        call DestroyGroup(g)

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set BloodBank[pid] = RMinBJ(BloodBank[pid] + pt.armor, 200 * GetHeroInt(Hero[pid], true))

            if UnitAlive(target) then
                call UnitDamageTarget(caster, target, pt.dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                if GetHeroStr(caster, true) > GetHeroAgi(caster, true) and GetUnitAbilityLevel(caster, 'A097') > 0 then //str taunt
                    //switch target only here not in BloodDomainTick
                endif
            endif

            set bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), 'A09D', 1, DUMMY_RECYCLE_TIME)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(caster) - GetUnitY(bj_lastCreatedUnit), GetUnitX(caster) - GetUnitX(bj_lastCreatedUnit)))
            call InstantAttack(bj_lastCreatedUnit, caster)
        endloop

        call TimerStart(pt.timer, 1., true, function BloodDomainTick)
    elseif sid == 'A09A' then //blood nova
        set dmg = 40 * GetHeroInt(caster, true) //blood cost 20%

        if BloodBank[pid] >= dmg then
            set BloodBank[pid] = BloodBank[pid] - dmg
            call SetUnitState(Hero[pid], UNIT_STATE_MANA, BloodBank[pid])
            set dmg = dmg * 0.3 + (3 * GetHeroAgi(Hero[pid], true) + 2 * GetHeroStr(Hero[pid], true))
            call MakeGroupInRange(pid, ug, x, y, (225 + 25 * ablev) * LBOOST[pid], Condition(function FilterEnemy))
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call UnitDamageTarget(caster, target, dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
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
            call TimerStart(pt.timer, 1., true, function BloodLeechAoE)
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

        call TimerStart(pt.timer, (9 + ablev) * LBOOST[pid], false, function BloodLordExpire)
        call BlzSetUnitAttackCooldown(caster, BlzGetUnitAttackCooldown(caster, 0) * 0.7, 0)
        call DestroyEffectTimed(AddSpecialEffectTarget("war3mapImported\\Burning Rage Red.mdx", caster, "overhead"), (9 + ablev) * BOOST[pid])
        call SetUnitAnimationByIndex(caster, 3)
        call UnitAddAbility(caster, 'A099')
        set BloodBank[pid] = 0
        call SetUnitState(Hero[pid], UNIT_STATE_MANA, BloodBank[pid])

	//====================
    //Hydromancer
    //====================
    
	elseif sid == 'A08E' then //blizzard
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = (ablev + 3) * LBOOST[pid]
        set pt.dmg = GetHeroInt(Hero[pid], true) * (GetUnitAbilityLevel(Hero[pid], 'A08E') * 0.25)
        set pt.caster = GetDummy(x, y, 'A02O', 1, pt.dur + 3.)
        set pt.aoe = (175 + 25. * ablev) * LBOOST[pid]
        set pt.tag = 'bliz'
        call BlzSetAbilityRealLevelField(BlzGetUnitAbility(pt.caster, 'A02O'), ABILITY_RLF_AREA_OF_EFFECT, ablev - 1, pt.aoe)
        call IncUnitAbilityLevel(pt.caster, 'A02O')
        call DecUnitAbilityLevel(pt.caster, 'A02O')
        call SetUnitOwner(pt.caster, p, true)
        if UnitRemoveAbility(caster, 'B01I') then
            set pt.agi = 1
		endif
        call TimerStart(pt.timer, 1., true, function BlizzardPeriodic)
        call IssuePointOrder(pt.caster, "blizzard", GetSpellTargetX(), GetSpellTargetY())
	elseif sid == FROSTBLAST.id then //Frost blast
        set u = GetDummy(x, y, 'A04B', 1, DUMMY_RECYCLE_TIME)
        call SetUnitOwner(u, p, true)
        call IssueTargetOrder(u, "thunderbolt", target)

        call spell.destroy()
    elseif sid == WHIRLPOOL.id then //Whirlpool
        if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
            set pt = TimerList[pid].addTimer(pid)
            set pt.dmg = spell.values[0]
            set pt.aoe = spell.values[1] * LBOOST[pid]
            set pt.dur = spell.values[2] * LBOOST[pid]
            set pt.x = GetSpellTargetX()
            set pt.y = GetSpellTargetY()
            set pt.agi = 0
            set pt.spell = spell

            if GetUnitAbilityLevel(Hero[pid], 'B01I') > 0 then
                call UnitRemoveAbility(Hero[pid], 'B01I')
                set pt.dur = pt.dur + 2
            endif

            set bj_lastCreatedUnit = GetDummy(pt.x, pt.y, 0, 0, pt.dur)
            call BlzSetUnitSkin(bj_lastCreatedUnit, 'h01I')
            call SetUnitTimeScale(bj_lastCreatedUnit, 1.3)
            call SetUnitScale(bj_lastCreatedUnit, 0.6, 0.6, 0.6)
            call SetUnitAnimation(bj_lastCreatedUnit, "birth")
            call SetUnitFlyHeight(bj_lastCreatedUnit, 50., 0)
            call PauseUnit(bj_lastCreatedUnit, true)
            set bj_lastCreatedUnit = GetDummy(pt.x, pt.y, 0, 0, pt.dur)
            call BlzSetUnitSkin(bj_lastCreatedUnit, 'h01I')
            call SetUnitTimeScale(bj_lastCreatedUnit, 1.1)
            call SetUnitScale(bj_lastCreatedUnit, 0.35, 0.35, 0.35)
            call SetUnitAnimation(bj_lastCreatedUnit, "birth")
            call SetUnitFlyHeight(bj_lastCreatedUnit, 50., 0)
            call PauseUnit(bj_lastCreatedUnit, true)
            call TimerStart(pt.timer, 0.03, true, function WhirlpoolPeriodic)
        else
            call DisplayTextToPlayer(p, 0, 0, "Cannot cast there")
        endif
    elseif sid == TIDALWAVE.id then //Tidal Wave
        set pt = TimerList[pid].addTimer(pid)
        if GetUnitAbilityLevel(Hero[pid], 'B01I') > 0 then
            set pt.agi = 1
            call UnitRemoveAbility(Hero[pid], 'B01I')
        else
            set pt .agi = 0
        endif
        set pt.angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set pt.dur = spell.values[0] * LBOOST[pid]
        set pt.target = GetDummy(x, y, 0, 0, DUMMY_RECYCLE_TIME) 
        set pt.x = x
        set pt.y = y
        set pt.spell = spell
        call BlzSetUnitSkin(pt.target, 'h04X')
        call SetUnitAnimation(pt.target, "birth")
        call SetUnitScale(pt.target, 0.8, 0.8, 0.8)
        call BlzSetUnitFacingEx(pt.target, pt.angle * bj_RADTODEG)
        call TimerStart(pt.timer, 0.03, true, function TidalWavePeriodic)
    elseif sid == ICEBARRAGE.id then //ice barrage
        
	//====================
    //Thunderblade
    //====================
    
    elseif sid == THUNDERDASH.id then //Thunder Dash
        call TimerList[pid].stopAllTimersWithTag('omni')
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = spell.values[0] * LBOOST[pid]
        set pt.dmg = spell.values[1] * BOOST[pid]
        set pt.aoe = spell.values[2] * LBOOST[pid]
        set pt.angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set pt.caster = caster
        set pt.target = GetDummy(x, y, 0, 0, DUMMY_RECYCLE_TIME)
        set pt.speed = 35.
        set pt.x = x + pt.dur * Cos(pt.angle)
        set pt.y = y + pt.dur * Sin(pt.angle)
        call SetUnitVertexColor(caster, 255, 255, 255, 255)
        call SetUnitTimeScale(caster, 1.)
        call ShowUnit(caster,false)
        call UnitAddAbility(caster, 'Avul')
        call BlzSetUnitSkin(pt.target, 'h00B')
        call SetUnitScale(pt.target, 1.5, 1.5, 1.5)
        call SetUnitFlyHeight(pt.target, 150.00, 0.00)
        call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\FarseerMissile\\FarseerMissile.mdl", x, y))

        call TimerStart(pt.timer, 0.03, true, function DashPeriodic)
	elseif sid == OMNISLASH.id then //Omnislash
        set pt = TimerList[pid].addTimer(pid)
        set pt.spell = spell
        set pt.dur = spell.values[0] * LBOOST[pid] - 1
        set pt.tag = 'omni'

        call SetUnitTimeScale(caster, 2.5)
		call SetUnitVertexColorBJ(caster, 100, 100, 100, 50.00)
		call SetUnitXBounded(caster, GetUnitX(target) + 60. * Cos(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
        call SetUnitYBounded(caster, GetUnitY(target) + 60. * Sin(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
        call BlzSetUnitFacingEx(caster, GetUnitFacing(target))
		call UnitDamageTarget(caster, target, spell.values[1] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Blink\\Blinkcaster.mdl", caster, "chest"))
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "chest"))
        
        call TimerStart(pt.timer, 0.4, true, function Omnislash)
	elseif sid == MONSOON.id then //Monsoon
        set pt = TimerList[pid].addTimer(pid)
        set pt.spell = spell
        set pt.x = GetSpellTargetX()
        set pt.y = GetSpellTargetY()
        set pt.dur = spell.values[0] * LBOOST[pid]
    
        set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\AnimatedEnviromentalEffectRainBv005", GetSpellTargetX(), GetSpellTargetY())
        call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 0.4)
        call DestroyEffectTimed(bj_lastCreatedEffect, pt.dur)
		call TimerStart(pt.timer, 1., true, function Monsoon)
	elseif sid == BLADESTORM.id then //Bladestorm
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 9

        call AddUnitAnimationProperties(Hero[pid], "spin", true)
        call TimerStart(pt.timer, 0.33, true, function BladeStorm)
	
	//====================
    //Royal Guardian
    //====================

	elseif sid == 'A06B' then //Steed Charge
        if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
            call SoundHandler("Units\\Human\\Knight\\KnightYesAttack3.flac", true, null, caster)
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Polymorph\\PolyMorphDoneGround.mdl", x, y))
            set SteedChargeX[pid] = GetSpellTargetX()
            set SteedChargeY[pid] = GetSpellTargetY()
            
            call BlzUnitHideAbility(caster, 'A06K', false)
            call IssueImmediateOrderById(caster, 852180)
            call BlzUnitHideAbility(caster, 'A06K', true)
            call BlzStartUnitAbilityCooldown(caster, 'A06B', 30.)
        else
            call SetUnitPosition(Hero[pid], x, y)
            call DisplayTextToPlayer(p, 0, 0, "Cannot cast there")
        endif
	
	elseif sid == 'A0HT' then //Shield Slam
		set dmg = ablev * (GetHeroStr(caster, true) + 4 * BlzGetUnitArmor(caster)) * BOOST[pid]
        set dur = 2 + IMinBJ(2, ShieldCount[pid])
        call StunUnit(pid, target, dur)

        set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\DetroitSmash_Effect_CasterArt.mdx", x, y)
        call BlzSetSpecialEffectYaw(bj_lastCreatedEffect, bj_DEGTORAD * GetUnitFacing(caster))
        call DestroyEffect(bj_lastCreatedEffect)

		if ShieldCount[pid] > 0 then
            set dmg = dmg * (1 + IMinBJ(2, ShieldCount[pid]) * 0.2)

            call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)

            call MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 300 * LBOOST[pid], Condition(function FilterEnemy))
            call GroupRemoveUnit(ug, target)

            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call UnitDamageTarget(caster, target, dmg * .5, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endloop
		else
            call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
		endif
	elseif sid == 'A0EG' then //Royal Plate
		if ShieldCount[pid] > 0 then
			set i = R2I((0.006 *Pow(ablev,5) + 10 *Pow(ablev,2) +25 * ablev + UnitGetBonus(caster, BONUS_ARMOR) * .23) * BOOST[pid] * 1.3 + 0.5)
		else
			set i = R2I((0.006 *Pow(ablev,5) + 10 *Pow(ablev,2) +25 * ablev) * BOOST[pid] + 0.5)
		endif
		call UnitAddBonus(caster, BONUS_ARMOR, i)
        set pt = TimerList[pid].addTimer(pid)
        set pt.armor = i

        call TimerStart(pt.timer, 15., false, function RoyalPlateExpire)
	elseif sid == 'A04Y' then //Provoke
        set heal = (BlzGetUnitMaxHP(caster) - GetWidgetLife(caster)) * (0.2 + 0.01 * ablev) * BOOST[pid]
        call HP(caster, heal)
        call MakeGroupInRange(pid, ug, x, y, (450 + 50 * ablev) * LBOOST[pid], Condition(function FilterEnemy))
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Taunt\\TauntCaster.mdl", caster, "origin"))
        
		loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call DummyCastTarget(p, target, 'A04X', 1, GetUnitX(target), GetUnitY(target), "slow")
		endloop

        call Taunt(caster, pid, 800., true, 2000, 2000)
    elseif sid == 'A09E' then //Fight Me
        set FightMe[pid] = true
        call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Voodoo\\VoodooAura.mdl", caster, "origin"), (4 + ablev) * BOOST[pid])
        call TimerStart(NewTimerEx(pid), (4 + ablev) * BOOST[pid], false, function FightMeExpire)
		
	//====================
    //High Priestess
    //====================
	
	elseif sid == 'A0DU' then //Invigoration
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 0
        set pt.x = GetUnitX(caster)
        set pt.y = GetUnitY(caster)

		call TimerStart(pt.timer, 0.5, true, function Invigoration)
	elseif sid == 'A0JE' then //Divine Light
        set ResurrectionCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A048') - 2
        if ResurrectionCD[pid] > 0 then
            call BlzStartUnitAbilityCooldown(Hero[pid], 'A048', ResurrectionCD[pid])
        else
            call BlzEndUnitAbilityCooldown(Hero[pid], 'A048')
        endif

		set heal = (0.25 + ablev * 0.25) * GetHeroInt(caster,true)
        if GetUnitTypeId(target) == BACKPACK then
            set heal = (heal + BlzGetUnitMaxHP(Hero[pid]) * 0.05) * BOOST[pid]
            call HP(Hero[tpid], heal)
		elseif IsUnitAlly(target,p) then
            set heal = (heal + BlzGetUnitMaxHP(target) * 0.05) * BOOST[pid]
            call HP(target, heal)
		endif
	elseif sid == 'A0JG' then //Sanctified Ground
        set ResurrectionCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A048') - 2
        if ResurrectionCD[pid] > 0 then
            call BlzStartUnitAbilityCooldown(Hero[pid], 'A048', ResurrectionCD[pid])
        else
            call BlzEndUnitAbilityCooldown(Hero[pid], 'A048')
        endif

        set pt = TimerList[pid].addTimer(pid)
        set pt.x = GetSpellTargetX()
        set pt.y = GetSpellTargetY()
        set pt.dur = ((11 + ablev) * 2) * LBOOST[pid]
        set pt.target = GetDummy(pt.x, pt.y, 0, 0, pt.dur * 0.5)
        set dmg = LBOOST[pid]
        set pt.aoe = 400 * dmg
        call UnitDisableAbility(pt.target, 'Amov', true)
        call BlzSetUnitSkin(pt.target, 'h04D')
        call SetUnitScale(pt.target, dmg, dmg, dmg)
        call SetUnitAnimation(pt.target, "birth")
        call BlzSetUnitFacingEx(pt.target, 270.)

        call TimerStart(pt.timer, 0.5, true, function SanctifiedGround)
	elseif sid == 'A0JD' then //Holy Rays
        set ResurrectionCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A048') - 2
        if ResurrectionCD[pid] > 0 then
            call BlzStartUnitAbilityCooldown(Hero[pid], 'A048', ResurrectionCD[pid])
        else
            call BlzEndUnitAbilityCooldown(Hero[pid], 'A048')
        endif

		set heal = ablev * 0.5 * GetHeroInt(caster,true) * BOOST[pid]
		call MakeGroupInRange(pid, ug, x, y, 600 * LBOOST[pid], Condition(function isalive))
		loop
			set target = FirstOfGroup(ug)
			exitwhen target == null
			call GroupRemoveUnit(ug, target)
            if IsUnitAlly(target, p) then
                set bj_lastCreatedUnit = GetDummy(x, y, 'A09Q', 1, DUMMY_RECYCLE_TIME)
                call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(bj_lastCreatedUnit), GetUnitX(target) - GetUnitX(bj_lastCreatedUnit)))
                call InstantAttack(bj_lastCreatedUnit, target)
                call HP(target, heal)
            else
                set bj_lastCreatedUnit = GetDummy(x, y, 'A014', 1, DUMMY_RECYCLE_TIME)
                call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(bj_lastCreatedUnit), GetUnitX(target) - GetUnitX(bj_lastCreatedUnit)))
                call InstantAttack(bj_lastCreatedUnit, target)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\AncestralGuardianMissile\\AncestralGuardianMissile.mdl", target, "chest"))
                call UnitDamageTarget(caster, target, heal * 4, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
		endloop
	elseif sid == 'A0J3' then //Protection
        set ResurrectionCD[pid] = BlzGetUnitAbilityCooldownRemaining(Hero[pid], 'A048') - 2
        if ResurrectionCD[pid] > 0 then
            call BlzStartUnitAbilityCooldown(Hero[pid], 'A048', ResurrectionCD[pid])
        else
            call BlzEndUnitAbilityCooldown(Hero[pid], 'A048')
        endif

        call MakeGroupInRange(pid, ug, x, y, 650. * LBOOST[pid], Condition(function FilterAllyHero))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set ProtectionBuff.add(caster, target).duration = 99999.
            set shield.add(target, GetHeroInt(caster, true) * 3 * BOOST[pid], 20 + 10 * ablev).color = 4
        endloop
    elseif sid == 'A048' then //resurrection
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(HeroGrave[tpid]), GetUnitY(HeroGrave[tpid])))
        set ResurrectionRevival[tpid] = pid
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
	//====================
    //Master Rogue
    //====================

	elseif sid == DEATHSTRIKE.id then //Death Strike
        call AddUnitAnimationProperties(caster, "alternate", false)
        set pt = TimerList[pid].addTimer(pid)
        set pt.target = target
        set pt.spell = spell

        call BlzPauseUnitEx(target, true)
        call TimerStart(pt.timer, 0.03, true, function DeathStrikeTP)
        call UnitAddAbility(target, 'S00I')
        call SetUnitTurnSpeed(target, 0)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl", caster, "chest"))

        set pt = TimerList[pid].addTimer(pid)
        set pt.target = target

        call TimerStart(pt.timer, spell.values[1] * LBOOST[pid], true, function Unimmobilize)
	elseif sid == HIDDENGUISE.id then //hidden guise
        set bj_lastCreatedEffect = AddSpecialEffect("Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", x, y)
        call BlzSetSpecialEffectYaw(bj_lastCreatedEffect, GetUnitFacing(caster) * bj_DEGTORAD)
        call DestroyEffectTimed(bj_lastCreatedEffect, 2.)
        call IssueImmediateOrder(caster, "stop")
        call ShowUnit(caster, false)
        call TimerStart(NewTimerEx(pid), 2., false, function HiddenGuiseExpire)
	elseif sid == NERVEGAS.id then //Nerve Gas
        call AddUnitAnimationProperties(caster, "alternate", false)
        set target = GetDummy(GetSpellTargetX(), GetSpellTargetY(), 0, 0, 0)
        call UnitRemoveAbility(target, 'Avul')
        call UnitRemoveAbility(target, 'Aloc')
        set u = GetDummy(x, y, 'A01X', 1, 0)
        call SetUnitOwner(u, p, true)
        call IssueTargetOrder(u, "acidbomb", target)
        
	//====================
    //Assassin
    //====================

	elseif sid == 'A0BG' then //Shadow Shuriken
        //change blade spin to active
        call UnitAddAbility(caster, 'A0AS')
        call UnitDisableAbility(caster, 'A0AQ', true)
        call UpdateManaCosts(caster)

        set pt = TimerList[pid].addTimer(pid)
        set pt.target = GetDummy(x, y, 0, 0, DUMMY_RECYCLE_TIME)
        set pt.ug = CreateGroup()
        set pt.dur = 750.
        set pt.aoe = 200.
        set pt.armor = 60.
        set pt.int = 0
        set pt.angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x) 
        set pt.dmg = (GetHeroAgi(caster,true) * 2 + UnitGetBonus(caster,BONUS_DAMAGE)) * (GetUnitAbilityLevel(caster, sid) + 5) * 0.25 * BOOST[pid] 

        call BlzSetUnitSkin(pt.target, 'h00F')
        call SetUnitScale(pt.target, 1.1, 1.1, 1.1)
        call SetUnitVertexColor(pt.target, 50, 50, 50, 255)
        call UnitAddAbility(pt.target, 'Amrf')
        call SetUnitFlyHeight(pt.target, 75.00, 0.00)
        call BlzSetUnitFacingEx(pt.target, bj_RADTODEG * pt.angle)

        call TimerStart(pt.timer, 0.03, true, function ShadowShuriken)
	elseif sid == 'A01E' then //Smoke bomb
        //change blade spin to active
        call UnitAddAbility(caster, 'A0AS')
        call UnitDisableAbility(caster, 'A0AQ', true)
        call UpdateManaCosts(caster)

        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 16. * LBOOST[pid]
        set pt.x = GetSpellTargetX()
        set pt.y = GetSpellTargetY()
        set pt.agi = 9 + ablev
        call TimerStart(pt.timer, 0.5, true, function SmokebombPeriodic)
        call DestroyEffectTimed(AddSpecialEffect("war3mapImported\\GreySmoke.mdx", GetSpellTargetX(), GetSpellTargetY()), pt.dur * 0.5)
	elseif sid == 'A00T' then //Blink Strike
		if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
            //change blade spin to active
            call UnitAddAbility(caster, 'A0AS')
            call UnitDisableAbility(caster, 'A0AQ', true)
            call UpdateManaCosts(caster)

			set i =0
			loop
				exitwhen i>11
				set angle = 2 *bj_PI *i /12.
				call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\FeralSpirit\\feralspiritdone.mdl", GetSpellTargetX()+190 * Cos(angle), GetSpellTargetY()+190 * Sin(angle)))
				set i = i + 1
			endloop
			call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\FeralSpirit\\feralspiritdone.mdl", GetSpellTargetX(), GetSpellTargetY()))
			call MakeGroupInRange(pid, ug, GetSpellTargetX(), GetSpellTargetY(), 200.*LBOOST[pid], Condition(function FilterEnemy))
			loop
				set target = FirstOfGroup(ug)
				exitwhen target == null
				call GroupRemoveUnit(ug, target)
				call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "origin"))
                if GetUnitAbilityLevel(target, 'B019') > 0 then
                    call GroupRemoveUnit(markedfordeath[pid], target)
                    call SetUnitPathing(target, true)
                    call UnitRemoveAbility(target, 'B019')
                    set BlinkStrike.add(Hero[pid], Hero[pid]).duration = 6.
                    call UnitDamageTarget(caster, target, ablev * .25 * (GetHeroAgi(caster,true)*3 + UnitGetBonus(caster,BONUS_DAMAGE)) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                else
                    call UnitDamageTarget(caster, target, ablev * .25 * (GetHeroAgi(caster,true)*3 + UnitGetBonus(caster,BONUS_DAMAGE)) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
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
        call UpdateManaCosts(caster)

        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 15
        set pt.x = GetSpellTargetX()
        set pt.y = GetSpellTargetY()
        set pt.armor = x
        set pt.aoe = y

        call TimerStart(pt.timer, 0.03, true, function SpawnDaggers)
        
	//====================
    //Arcanist
    //====================
    
    elseif sid == 'A04C' then //Control Time
        call BlzSetUnitAttackCooldown(Hero[pid], BlzGetUnitAttackCooldown(Hero[pid], 0) * 0.5, 0)
        call TimerStart(NewTimerEx(pid), 10. * LBOOST[pid], false, function ControlTime)
    
    elseif sid == 'A05Q' then //Arcane Bolts
        set angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x) 

        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 1
        set pt.angle = angle
        call TimerStart(pt.timer, 0, true, function ArcaneBolts)

        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = ablev + 1
        set pt.angle = angle
        call TimerStart(pt.timer, 0.2, true, function ArcaneBolts)

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
        
        call MakeGroupInRange(pid, ArcaneBarrageHit[pid], x, y, 750. * LBOOST[pid], Condition(function FilterEnemy))
        
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
        set pt.aoe = 250. * LBOOST[pid]
        set pt.x = GetSpellTargetX()
        set pt.y = GetSpellTargetY()

        set pt.target = GetDummy(pt.x, pt.y, 0, 0, 6.)
        call BlzSetUnitSkin(pt.target, 'h02B')
        call SetUnitScale(pt.target, 1.05, 1.05, 1.05)
        call UnitDisableAbility(pt.target, 'Amov', true)
        call SetUnitFlyHeight(pt.target, 0., 0.)
        call SetUnitAnimation(pt.target, "birth")

        set stasisFieldActive[pid] = true

        call TimerStart(pt.timer, 0.25, true, function StasisField)
        call TimerStart(NewTimerEx(pid), 6., false, function StasisFieldActive)

    elseif sid == 'A078' then //Arcane Shift
        set attargetpoint[pid] = GetSpellTargetLoc()

        call MakeGroupInRange(pid, attargets[pid], GetSpellTargetX(), GetSpellTargetY(), 350.00 * LBOOST[pid], Condition(function FilterEnemy))
        call MakeGroupInRange(pid, ug, GetSpellTargetX(), GetSpellTargetY(), 350.00 * LBOOST[pid], Condition(function FilterEnemy))
        
        set target = FirstOfGroup(attargets[pid])
        
        if target != null then
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", GetUnitX(target), GetUnitY(target)))
                call PauseUnit(target, true)
                if UnitAddAbility(target, 'Amrf') then
                    call UnitRemoveAbility(target, 'Amrf')
                endif
                call SetUnitFlyHeight(target, 600.00, 0.00)
            endloop
            call TimerStart(NewTimerEx(pid), 3.5, false, function ATExpire)
            call SetPlayerAbilityAvailable(p, 'A078', false)
            call UnitAddAbility(caster, 'A00A')
            call SetUnitAbilityLevel(caster, 'A00A', GetUnitAbilityLevel(caster, 'A078'))
        endif
        
    elseif sid == 'A00A' then //Arcane Shift Second Cast
        set dmg = GetHeroInt(Hero[pid], true) * (5 + GetUnitAbilityLevel(Hero[pid], 'A078') * 3) * BOOST[pid]
    
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
                call SetUnitFlyHeight(target, 0.00, 0.00)
                call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))
            endloop
            
            call MakeGroupInRange(pid, ug, GetSpellTargetX(), GetSpellTargetY(), 350. * LBOOST[pid], Condition(function FilterEnemy))
            
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
        set dmg = (8 + 4 * ablev) * LBOOST[pid]

        //replace bolts and barrage
        call BlzUnitHideAbility(Hero[pid], 'A05Q', true)
        call BlzUnitHideAbility(Hero[pid], 'A02N', true)
        call UnitAddAbility(Hero[pid], 'A08X')
        call UnitAddAbility(Hero[pid], 'A08S')
        call SetUnitAbilityLevel(Hero[pid], 'A08X', GetUnitAbilityLevel(Hero[pid], 'A05Q'))
        call SetUnitAbilityLevel(Hero[pid], 'A08S', GetUnitAbilityLevel(Hero[pid], 'A02N'))

        call TimerStart(NewTimerEx(pid), dmg, false, function Arcanosphere)
        call TimerStart(NewTimerEx(pid), 0.5, true, function ArcanosphereBuffs)

        call SetUnitTurnSpeed(Hero[pid], 1.)
        set arcanosphereActive[pid] = true

	//====================
    //Dark Savior
    //====================
	
    elseif sid == 'A019' then //Medean Lightning
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 3.
        set pt.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\LightningShield\\LightningShieldTarget.mdl", caster, "origin")
        call BlzSetSpecialEffectTimeScale(pt.sfx, 1.5)

        call TimerStart(pt.timer, 1., true, function MedeanLightning)
	elseif sid == 'A074' then //Freezing Blast
        set dmg = (GetHeroInt(caster, true) * (ablev + 2)) * BOOST[pid]
        set heal = 250 * LBOOST[pid]
        set x = GetUnitX(target)
        set y = GetUnitY(target)

        call MakeGroupInRange(pid, ug, x, y, heal, Condition(function FilterEnemy))

        if darkSealActive[pid] then //dark seal
            set pt = TimerList[pid].get(null, Hero[pid], 'Dksl')
            call BlzGroupAddGroupFast(pt.ug, ug)
                
            set bj_lastCreatedEffect = AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetUnitX(darkSeal[pid]), GetUnitY(darkSeal[pid]))
            call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 5)
            call DestroyEffectTimed(bj_lastCreatedEffect, 3)
        endif
            
        call DestroyEffect(AddSpecialEffect("war3mapImported\\AquaSpikeVersion2.mdx", x, y))
            
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            set Freeze.add(Hero[pid], target).duration = 1.5 * LBOOST[pid]
            if IsUnitInGroup(target, ug) and IsUnitInRangeXY(target, x, y, heal) == true then
                call UnitDamageTarget(caster, target, dmg * 2, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            else
                call UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endif
        endloop
        
    elseif sid == 'A0GO' then //Dark Seal
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 20 * LBOOST[pid]
        set pt.x = GetSpellTargetX()
        set pt.y = GetSpellTargetY()
        set pt.tag = 'Dksl'
        set pt.target = caster
        set pt.agi = 0
        set pt.ug = CreateGroup()

        set darkSealBAT[pid] = 0
        set darkSeal[pid] = GetDummy(pt.x, pt.y, 0, 0, pt.dur * 0.5) 

        call BlzSetUnitSkin(darkSeal[pid], 'h03X')
        call UnitDisableAbility(darkSeal[pid], 'Amov', true)
        call SetUnitScale(darkSeal[pid], 6.1, 6.1, 6.1)
        call BlzSetUnitFacingEx(darkSeal[pid], 270)
        call SetUnitAnimation(darkSeal[pid], "birth")
        call SetUnitTimeScale(darkSeal[pid], 0.8)
        call DelayAnimation(pid, darkSeal[pid], 1., 0, 1., false)

        set darkSealActive[pid] = true
        
        call TimerStart(pt.timer, 0.5, true, function DarkSeal)
    
    elseif sid == 'A02S' then //metamorphosis
        set dmg = GetWidgetLife(Hero[pid]) * 0.5
        call SetWidgetLife(Hero[pid], dmg)
        set metamorphosis[pid] = RMaxBJ(0.01, dmg / (BlzGetUnitMaxHP(Hero[pid]) * 1.))

        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = (5 + 5 * ablev) * LBOOST[pid]
        set pt.dmg = pt.dur

        call TimerStart(pt.timer, 0.03, true, function MetamorphosisPeriodic)
        
	//====================
    //Phoenix Ranger
    //====================

	elseif sid == 'A0FT' then //Phoenix Flight
        set dur = RMinBJ((350 + ablev * 150) * LBOOST[pid], RMaxBJ(17., DistanceCoords(x, y, GetSpellTargetX(), GetSpellTargetY())))
        set angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set x = x + dur * Cos(angle)
        set y = y + dur * Sin(angle)

		if IsTerrainWalkable(x, y) then
            set pt = TimerList[pid].addTimer(pid)
            set pt.dur = dur
            set pt.speed = 33.
            set pt.angle = angle
            set pt.x = x
            set pt.y = y
            set pt.aoe = 250. * LBOOST[pid]
            set pt.caster = caster
            set pt.target = GetDummy(GetUnitX(caster), GetUnitY(caster), 0, 0, 5.)
            set pt.dmg = GetHeroAgi(caster, true) * 1.5 * BOOST[pid]
            set pt.ug = CreateGroup()
            call UnitAddAbility(caster, 'Avul')
            call ShowUnit(caster, false)

            call BlzSetUnitSkin(pt.target, 'h01B')
            call BlzSetUnitFacingEx(pt.target, bj_RADTODEG * pt.angle)
            call SetUnitFlyHeight(pt.target, 150., 0)
            call SetUnitAnimation(pt.target, "birth")
            call SetUnitTimeScale(pt.target, 2)
            call SetUnitScale(pt.target, 1.5, 1.5, 1.5)

            call TimerStart(pt.timer, 0.03, true, function DashPeriodic)
		else
			call DisplayTextToPlayer(p, 0, 0, "Cannot target there")
		endif
    elseif sid == 'A090' then //Searing Arrow
        call MakeGroupInRange(pid, ug, x, y, 750., Condition(function FilterEnemy))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)

            set bj_lastCreatedUnit = GetDummy(x, y, 'A069', 1, 2.5)
            call SetUnitOwner(bj_lastCreatedUnit, Player(pid - 1), true)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(y - GetUnitY(target), x - GetUnitX(target)))
            call UnitDisableAbility(bj_lastCreatedUnit, 'Amov', true)
            call InstantAttack(bj_lastCreatedUnit, target)
        endloop

	elseif sid == 'A0F6' then //Flaming bow
        set FlamingBowCount[pid] = 0
        set FlamingBowBonus[pid] = 0.5 * (GetHeroAgi(Hero[pid], true) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) * LBOOST[pid]
        set dur = 15. * LBOOST[pid]
		call DestroyEffectTimed(AddSpecialEffectTarget("Environment\\SmallBuildingspeffect\\SmallBuildingspeffect2.mdl", caster, "weapon"), dur)
        call UnitAddAbility(caster, 'A08B')
		call UnitAddBonus(caster, BONUS_DAMAGE, R2I(FlamingBowBonus[pid]))
        set pt = TimerList[pid].addTimer(pid)

        call TimerStart(pt.timer, dur, false, function FlamingBowExpire)
		
	//====================
    //Elementalist
    //====================
    
    //ball of lightning
    elseif sid == 'A0GV' then
        set pt = TimerList[pid].addTimer(pid)
        set pt.angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set pt.target = GetDummy(x + 25. * Cos(pt.angle), y + 25. * Sin(pt.angle), 0, 0, 5.)
        set pt.aoe = 150.
        set pt.dur = 650. + 200. * ablev
        set pt.speed = 25. + 2. * ablev
        set pt.dmg = GetHeroInt(caster, true) * (5. + ablev) * BOOST[pid]
        
        call BlzSetUnitSkin(pt.target, 'h070')
        call SetUnitFlyHeight(pt.target, 50., 0)
        call SetUnitScale(pt.target, 1. + .2 * ablev, 1. + .2 * ablev, 1. + .2 * ablev)

        call TimerStart(pt.timer, 0.03, true, function BallOfLightningPeriodic)

    //master of elements
    elseif sid == 'A0J8' then // fire
        set masterElement[pid] = 1
        call TimerList[pid].stopAllTimersWithTag('elec')
        call UnitRemoveAbility(caster, 'B01W')
        call UnitRemoveAbility(caster, 'B01V')
        call UnitRemoveAbility(caster, 'B01Z')
        call SetPlayerAbilityAvailable(p, 'A0JZ', true)
        call UnitAddAbility(caster, 'B01Y')
        call SetPlayerAbilityAvailable(p, 'A0JX', false)
        call SetPlayerAbilityAvailable(p, 'A0JV', false)
        call SetPlayerAbilityAvailable(p, 'A0JY', false)
        call SetPlayerAbilityAvailable(p, 'A0JW', false)
        call DestroyEffect(lightningeffect[pid])
        call DestroyEffect(lightningeffect[pid * 8])
        set lightningeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Fire Uber.mdx", caster, "right hand")
        set lightningeffect[pid * 8] = AddSpecialEffectTarget("war3mapImported\\Fire Uber.mdx", caster, "left hand")
    elseif sid == 'A0J6' then // ice
        set masterElement[pid] = 2
        call TimerList[pid].stopAllTimersWithTag('elec')
        call UnitRemoveAbility(caster, 'B01Y')
        call UnitRemoveAbility(caster, 'B01V')
        call UnitRemoveAbility(caster, 'B01Z')
        call SetPlayerAbilityAvailable(p, 'A0JZ', false)
        call SetPlayerAbilityAvailable(p, 'A0JV', true)
        call SetPlayerAbilityAvailable(p, 'A0JY', false)
        call SetPlayerAbilityAvailable(p, 'A0JW', false)
        call DestroyEffect(lightningeffect[pid])
        call DestroyEffect(lightningeffect[pid * 8])
        set lightningeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Water High.mdx", caster, "right hand")
        set lightningeffect[pid * 8] = AddSpecialEffectTarget("war3mapImported\\Water High.mdx", caster, "left hand")
    elseif sid == 'A0J9' then //lightning
        set masterElement[pid] = 3
        call UnitRemoveAbility(caster, 'B01Y')
        call UnitRemoveAbility(caster, 'B01W')
        call UnitRemoveAbility(caster, 'B01V')
        call SetPlayerAbilityAvailable(p, 'A0JZ', false)
        call SetPlayerAbilityAvailable(p, 'A0JX', false)
        call SetPlayerAbilityAvailable(p, 'A0JV', false)
        call SetPlayerAbilityAvailable(p, 'A0JY', true)
        call SetPlayerAbilityAvailable(p, 'A0JW', false)
        call DestroyEffect(lightningeffect[pid])
        call DestroyEffect(lightningeffect[pid * 8])
        set lightningeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Storm Cast.mdx", caster, "right hand")
        set lightningeffect[pid * 8] = AddSpecialEffectTarget("war3mapImported\\Storm Cast.mdx", caster, "left hand")

        if TimerList[pid].hasTimerWithTag('elec') == false then
            set pt = TimerList[pid].addTimer(pid)
            set pt.tag = 'elec'
            call TimerStart(pt.timer, 5., true, function Electrocute)
        endif
    elseif sid == 'A0JA' then //earth
        set masterElement[pid] = 4
        call UnitRemoveAbility(caster, 'B01Y')
        call UnitRemoveAbility(caster, 'B01W')
        call UnitRemoveAbility(caster, 'B01Z')
        call TimerList[pid].stopAllTimersWithTag('elec')
        call SetPlayerAbilityAvailable(p, 'A0JZ', false)
        call SetPlayerAbilityAvailable(p, 'A0JX', false)
        call SetPlayerAbilityAvailable(p, 'A0JV', false)
        call SetPlayerAbilityAvailable(p, 'A0JY', false)
        call SetPlayerAbilityAvailable(p, 'A0JW', true)
        call DestroyEffect(lightningeffect[pid])
        call DestroyEffect(lightningeffect[pid * 8])
        set lightningeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Earth High.mdx", caster, "right hand")
        set lightningeffect[pid * 8] = AddSpecialEffectTarget("war3mapImported\\Earth High.mdx", caster, "left hand")
	
	elseif sid == 'A011' then //Frozen Orb
        set pt = TimerList[pid].addTimer(pid)
        set pt.angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set pt.dur = 1000.
        set pt.tag = 'forb'
        set pt.agi = 16
        set pt.dmg = GetHeroInt(Hero[pid], true) * 3. * ablev * BOOST[pid]

        set target = GetDummy(x + 75 * Cos(pt.angle), y + 75 * Sin(pt.angle), 0, 0, 8.) 
        call BlzSetUnitSkin(target, 'h06Z')
        call SetUnitScale(target, 1.3, 1.3, 1.3)
        call SetUnitFlyHeight(target, 70.00, 0.00)

        //i swear it makes sense
        set pt.caster = target
        set pt.target = caster

        call TimerStart(pt.timer, 0.03, true, function FrozenOrbPeriodic)

        //show second cast
        call BlzUnitHideAbility(Hero[pid], 'A011', true)
        call UnitAddAbility(Hero[pid], 'A01W')
        call SetUnitAbilityLevel(Hero[pid], 'A01W', ablev)
    elseif sid == 'A01U' then //Flame Breath
        call TimerList[pid].stopAllTimersWithTag('fbre')
        set pt = TimerList[pid].addTimer(pid)
        set pt.angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set pt.dmg = GetHeroInt(Hero[pid], true) * (0.5 + 0.5 * ablev)
        set pt.sfx = AddSpecialEffect("war3mapImported\\FlameBreath.mdx", x + 75 * Cos(pt.angle), y + 75 * Sin(pt.angle))
        set pt.tag = 'fbre'
        set pt.aoe = 750.
        call BlzSetSpecialEffectScale(pt.sfx, 1.8 * LBOOST[pid])
        call BlzSetSpecialEffectTimeScale(pt.sfx, 1.5)
        call BlzSetSpecialEffectYaw(pt.sfx, pt.angle)
        call TimerStart(pt.timer, 0.5, true, function FlameBreathPeriodic)
    elseif sid == 'A032' then //Gaia Armor
        set pt = TimerList[pid].addTimer(pid)
        set pt.sfx = AddSpecialEffectTarget("war3mapImported\\Archnathid Armor.mdx", caster, "chest") 
        set pt.tag = 'garm'
        call BlzSetSpecialEffectColor(pt.sfx, 160, 255, 160)

        set dmg = GetHeroInt(caster, true) * (0.5 + 0.5 * ablev) * BOOST[pid]

        if masterElement[pid] == 4 then //earth element bonus
            set dmg = dmg * 5.
        endif
    
        call TimerStart(pt.timer, 30., false, function GaiaArmorExpire)
        call shield.add(caster, dmg, 31.)
        
    elseif sid == 'A04H' then //Elemental Storm
        set pt = TimerList[pid].addTimer(pid)
        set pt.x = GetSpellTargetX()
        set pt.y = GetSpellTargetY()
        set pt.dmg = GetHeroInt(caster, true) * (2 + ablev)
        set pt.dur = 12.
        set pt.aoe = 400.

        if masterElement[pid] == 0 then
            set pt.agi = GetRandomInt(1, 4)
        else
            set pt.agi = masterElement[pid]
        endif
        
        call TimerStart(pt.timer, 0.4, true, function ElementalStorm)
    
	//====================
    //Oblivion Guard
    //====================
    
    elseif sid == METEOR.id then //Meteor
        if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
            set pt = TimerList[pid].addTimer(pid)
            set pt.x = GetSpellTargetX()
            set pt.y = GetSpellTargetY()
            set pt.spell = spell
            
            call BlzPauseUnitEx(caster, true)
            call SetUnitAnimation(caster, "death")
            call SetUnitTimeScale(caster, 2)
            call Fade(caster, 0.8, true)
            set bj_lastCreatedEffect = AddSpecialEffect("Units\\Demon\\Infernal\\InfernalBirth.mdl", pt.x, pt.y)
            call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 2.5)
            call DestroyEffectTimed(bj_lastCreatedEffect, 2.)
            call BlzSetSpecialEffectYaw(bj_lastCreatedEffect, Atan2(pt.y - GetUnitY(caster), pt.x - GetUnitX(caster)))
            
            call TimerStart(pt.timer, 0.9, false, function MeteorExpire)
        else
            call SetUnitPosition(caster, x, y)
            call DisplayTextToPlayer(p,0,0,"Cannot target there")
        endif
        
    elseif sid == INFERNALSTRIKE.id then //Infernal Strike
        set Buff.get(caster, caster, MagneticStrikeBuff.typeid).duration = 0.
        set InfernalStrikeBuff.add(caster, caster).duration = 99999.
    elseif sid == MAGNETICSTRIKE.id then //magnetic strike
        set Buff.get(caster, caster, InfernalStrikeBuff.typeid).duration = 0.
        set MagneticStrikeBuff.add(caster, caster).duration = 99999.
    elseif sid == GATEKEEPERSPACT.id then //Gatekeeper's Pact
        set pt = TimerList[pid].addTimer(pid)
        set pt.spell = spell
        call BlzPauseUnitEx(caster, true)
        call DestroyEffectTimed(AddSpecialEffect("war3mapImported\\AnnihilationTarget.mdx", x, y), 2)
        call TimerStart(pt.timer, 2, false, function GatekeepersPact)
        
	//====================
    //Dark Summoner
    //====================
    
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
                        set heal = BlzGetUnitMaxHP(target) * .30 * BOOST[pid]
                        call HP(target, heal)
                    endif
                endloop
            elseif GetUnitTypeId(target)== SUMMON_GOLEM then //meat golem
                call UnitAddAbility(caster, 'A0K2')
                call BlzUnitHideAbility(caster, 'A0K2', true)
                
                if golemDevourStacks[pid] < 4 then
                    call SummonExpire(target)
                endif
                
                call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Orc\\AncestralSpirit\\AncestralSpiritCaster.mdl", caster, "origin"), 3)
                call TimerStart(NewTimerEx(pid), 15. * LBOOST[pid], false, function DemonicSacrificeExpire)
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
        set angle = GetUnitFacing(caster)
        set x = x + 150 * Cos(bj_DEGTORAD * angle)
        set y = y + 150 * Sin(bj_DEGTORAD * angle)

        loop
            exitwhen i >= ablev + 2 //number of hounds

            if hounds[pid * 10 + i] == null then
                set hounds[pid * 10 + i] = CreateUnit(p, SUMMON_HOUND, x, y, angle)
            else
                call TimerList[pid].stopAllTimersWithTag(GetUnitId(hounds[pid * 10 + i]))
                call ShowUnit(hounds[pid * 10 + i], true)
                call ReviveHero(hounds[pid * 10 + i], x, y, false)
                call SetWidgetLife(hounds[pid * 10 + i], BlzGetUnitMaxHP(hounds[pid * 10 + i]))
                call SetUnitState(hounds[pid * 10 + i], UNIT_STATE_MANA, BlzGetUnitMaxMana(hounds[pid * 10 + i]))
                call SetUnitScale(hounds[pid * 10 + i], 0.85, 0.85, 0.85)
                call SetUnitPosition(hounds[pid * 10 + i], x, y)
                call BlzSetUnitFacingEx(hounds[pid * 10 + i], angle)
                call SetUnitVertexColor(hounds[pid * 10 + i], 120, 60, 60, 255)
                call UnitSetBonus(hounds[pid * 10 + i], BONUS_ARMOR, 0)
                call SetUnitAbilityLevel(hounds[pid * 10 + i], 'A06F', 1)
            endif

            set pt = TimerList[pid].addTimer(pid)
            set pt.x = x
            set pt.y = y
            set pt.dur = 60.
            set pt.armor = 60.
            set pt.tag = GetUnitId(hounds[pid * 10 + i])
            set pt.target = hounds[pid * 10 + i]

            call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", hounds[pid * 10 + i], "origin"), 2.)

            call SummoningImprovement(pid, hounds[pid * 10 + i], 0.2, 0.075, 0.25)

            if destroyerSacrificeFlag[pid] then
                call SetUnitVertexColor(hounds[pid * 10 + i], 90, 90, 230, 255)
                call SetUnitScale(hounds[pid * 10 + i], 1.15, 1.15, 1.15)
                call SetUnitAbilityLevel(hounds[pid * 10 + i], 'A06F', 2)
            endif

            call GroupAddUnit(SummonGroup, hounds[pid * 10 + i])

            call SetHeroXP(hounds[pid * 10 + i], R2I(RequiredXP(GetHeroLevel(Hero[pid]) - 1) + ((GetHeroLevel(Hero[pid]) + 1) * pt.dur * 100 / pt.armor) - 1), false)

            call TimerStart(pt.timer, 0.5, true, function SummonDurationXPBar)

            set i = i + 1
        endloop

    elseif sid == 'A0KH' then //summon meat golem
        call TimerList[pid].stopAllTimersWithTag('dvou')
        set angle = GetUnitFacing(caster)
        set x = x + 150 * Cos(bj_DEGTORAD * angle)
        set y = y + 150 * Sin(bj_DEGTORAD * angle)

        if meatgolem[pid] == null then
            set meatgolem[pid] = CreateUnit(p, SUMMON_GOLEM, x, y, angle)
        else
            call TimerList[pid].stopAllTimersWithTag(GetUnitId(meatgolem[pid]))
            call ShowUnit(meatgolem[pid], true)
            call ReviveHero(meatgolem[pid], x, y, false)
            call SetWidgetLife(meatgolem[pid], BlzGetUnitMaxHP(meatgolem[pid]))
            call SetUnitState(meatgolem[pid], UNIT_STATE_MANA, BlzGetUnitMaxMana(meatgolem[pid]))
            call SetUnitScale(meatgolem[pid], 1., 1., 1.)
            call SetUnitPosition(meatgolem[pid], x, y)
            call BlzSetUnitFacingEx(meatgolem[pid], angle)
            call UnitRemoveAbility(meatgolem[pid], 'A071') //borrowed life
            call UnitRemoveAbility(meatgolem[pid], 'A0B0') //thunder clap
            call UnitRemoveAbility(meatgolem[pid], 'A06O') //magnetic force
            call UnitRemoveAbility(meatgolem[pid], 'A06C') //devour
            call UnitSetBonus(meatgolem[pid], BONUS_ARMOR, 0)
            call UnitSetBonus(meatgolem[pid], BONUS_HERO_STR, 0)
        endif

        set pt = TimerList[pid].addTimer(pid)
        set pt.x = x
        set pt.y = y
        set pt.dur = 180.
        set pt.armor = 180.
        set pt.tag = GetUnitId(meatgolem[pid])
        set pt.target = meatgolem[pid]

        set golemDevourStacks[pid] = 0
        set BorrowedLife[pid * 10] = 0

        call BlzSetHeroProperName(meatgolem[pid], "Meat Golem") 

        call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", meatgolem[pid], "origin"), 2.)

        call SummoningImprovement(pid, meatgolem[pid], 0.4, 0.6, 0)

        call GroupAddUnit(SummonGroup, meatgolem[pid])

        call SetHeroXP(meatgolem[pid], R2I(RequiredXP(GetHeroLevel(Hero[pid]) - 1) + ((GetHeroLevel(Hero[pid]) + 1) * pt.dur * 100 / pt.armor) - 1), false)

        call TimerStart(pt.timer, 0.5, true, function SummonDurationXPBar)
    elseif sid == 'A0KG' then //summon destroyer
        call TimerList[pid].stopAllTimersWithTag('blif')
        set angle = GetUnitFacing(caster) + 180
        set x = x + 150 * Cos(bj_DEGTORAD * angle)
        set y = y + 150 * Sin(bj_DEGTORAD * angle)

        if destroyer[pid] == null then
            set destroyer[pid] = CreateUnit(p, SUMMON_DESTROYER, x, y, angle + 180)
        else
            call TimerList[pid].stopAllTimersWithTag(GetUnitId(destroyer[pid]))
            call ShowUnit(destroyer[pid], true)
            call ReviveHero(destroyer[pid], x, y, false)
            call SetWidgetLife(destroyer[pid], BlzGetUnitMaxHP(destroyer[pid]))
            call SetUnitState(destroyer[pid], UNIT_STATE_MANA, BlzGetUnitMaxMana(destroyer[pid]))
            call SetUnitPosition(destroyer[pid], x, y)
            call BlzSetUnitFacingEx(destroyer[pid], angle + 180)
            call SetUnitAbilityLevel(destroyer[pid], 'A02D', 1)
            call SetUnitAbilityLevel(destroyer[pid], 'A06J', 1)
            call UnitRemoveAbility(destroyer[pid], 'A061') //blink
            call UnitRemoveAbility(destroyer[pid], 'A03B') //crit
            call UnitRemoveAbility(destroyer[pid], 'A071') //borrowed life
            call UnitRemoveAbility(destroyer[pid], 'A04Z') //devour
            call UnitSetBonus(destroyer[pid], BONUS_ARMOR, 0)
            call UnitSetBonus(destroyer[pid], BONUS_HERO_STR, 0)
            call UnitSetBonus(destroyer[pid], BONUS_HERO_AGI, 0)
            call UnitSetBonus(destroyer[pid], BONUS_HERO_INT, 0)
            call SetHeroAgi(destroyer[pid], 0, true)
        endif

        set pt = TimerList[pid].addTimer(pid)
        set pt.x = x
        set pt.y = y
        set pt.dur = 180.
        set pt.armor = 180.
        set pt.tag = GetUnitId(destroyer[pid])
        set pt.target = destroyer[pid]

        set BorrowedLife[pid * 10 + 1] = 0
        set destroyerDevourStacks[pid] = 0
        set destroyerSacrificeFlag[pid] = false

        call BlzSetHeroProperName(destroyer[pid], "Destroyer") 

        call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", destroyer[pid], "origin"), 2.)

        call SummoningImprovement(pid, destroyer[pid], 0.0666, 0.005, 0.5 * ablev)

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

        call SetHeroXP(destroyer[pid], R2I(RequiredXP(GetHeroLevel(Hero[pid]) - 1) + ((GetHeroLevel(Hero[pid]) + 1) * pt.dur * 100 / pt.armor) - 1), false)

        call TimerStart(pt.timer, 0.5, true, function SummonDurationXPBar)

    elseif sid == 'A0KI' then //Taunt (Meat Golem)
        call Taunt(caster, pid, 800., true, 2000, 0)

    elseif sid == 'A0B0' then //Thunder Clap (Meat Golem)
		call MakeGroupInRange(pid, ug, x, y, 300., Condition(function FilterEnemy))
		loop
			set target = FirstOfGroup(ug)
			exitwhen target == null
            set MeatGolemThunderClap.add(caster, target).duration = 3.
			call GroupRemoveUnit(ug,target)
		endloop
        
    elseif sid == 'A06C' then //Devour (Meat Golem)
        if GetUnitTypeId(target) == SUMMON_HOUND and GetOwningPlayer(target) == p and golemDevourStacks[pid] < GetUnitAbilityLevel(Hero[pid], 'A063') + 1 then
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", target, "chest"))
            set bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), 'A00W', 1, DUMMY_RECYCLE_TIME)
            call SetUnitOwner(bj_lastCreatedUnit, p, false)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(caster) - GetUnitY(target),  GetUnitX(caster) - GetUnitX(target)))
            call InstantAttack(bj_lastCreatedUnit, caster)
            call SummonExpire(target)
        endif
    
    elseif sid == 'A04Z' then //Devour (Destroyer)
        if GetUnitTypeId(target) == SUMMON_HOUND and GetOwningPlayer(target) == p and destroyerDevourStacks[pid] < GetUnitAbilityLevel(Hero[pid], 'A063') + 1 then
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", target, "chest"))
            set bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), 'A00W', 1, DUMMY_RECYCLE_TIME)
            call SetUnitOwner(bj_lastCreatedUnit, p, false)
            call BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(caster) - GetUnitY(target),  GetUnitX(caster) - GetUnitX(target)))
            call InstantAttack(bj_lastCreatedUnit, caster)
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
        
	//====================
    //Bard
    //====================

    elseif sid == 'A025' then //Song of Fatigue
        set BardSong[pid] = SONG_FATIGUE
        call SetPlayerAbilityAvailable(p, SONG_FATIGUE, true)
        call SetPlayerAbilityAvailable(p, SONG_HARMONY, false)
        call SetPlayerAbilityAvailable(p, SONG_PEACE, false)
        call SetPlayerAbilityAvailable(p, SONG_WAR, false)
        if songeffect[pid] == null then
            set songeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Music effect01.mdx", caster, "overhead")
        endif
        call BlzSetSpecialEffectColorByPlayer(songeffect[pid], Player(3))
    elseif sid == 'A026' then //Song of Harmony
        set BardSong[pid] = SONG_HARMONY
        call SetPlayerAbilityAvailable(p, SONG_FATIGUE, false)
        call SetPlayerAbilityAvailable(p, SONG_HARMONY, true)
        call SetPlayerAbilityAvailable(p, SONG_PEACE, false)
        call SetPlayerAbilityAvailable(p, SONG_WAR, false)
        if songeffect[pid] == null then
            set songeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Music effect01.mdx", caster, "overhead")
        endif
        call BlzSetSpecialEffectColorByPlayer(songeffect[pid], Player(6))
    elseif sid == 'A027' then //Song of Peace
        set BardSong[pid] = SONG_PEACE
        call SetPlayerAbilityAvailable(p, SONG_FATIGUE, false)
        call SetPlayerAbilityAvailable(p, SONG_HARMONY, false)
        call SetPlayerAbilityAvailable(p, SONG_PEACE, true)
        call SetPlayerAbilityAvailable(p, SONG_WAR, false)
        if songeffect[pid] == null then
            set songeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Music effect01.mdx", caster, "overhead")
        endif
        call BlzSetSpecialEffectColorByPlayer(songeffect[pid], Player(4))
    elseif sid == 'A02C' then //Song of War
        set BardSong[pid] = SONG_WAR
        call SetPlayerAbilityAvailable(p, SONG_FATIGUE, false)
        call SetPlayerAbilityAvailable(p, SONG_HARMONY, false)
        call SetPlayerAbilityAvailable(p, SONG_PEACE, false)
        call SetPlayerAbilityAvailable(p, SONG_WAR, true)
        if songeffect[pid] == null then
            set songeffect[pid] = AddSpecialEffectTarget("war3mapImported\\Music effect01.mdx", caster, "overhead")
        endif
        call BlzSetSpecialEffectColorByPlayer(songeffect[pid], Player(0))

    elseif sid == 'A0AZ' then //Encore
        set pt = TimerList[pid].get(null, caster, 'impr')
        set i = pt.agi
        set aoe = 900.00 * LBOOST[pid] 

        call MakeGroupInRange(pid, ug, x, y, aoe, Condition(function isalive))

        //harmony all allied units
        //war all allied heroes
        //fatigue all enemies
        //peace all heroes

        if pt != 0 then
            call GroupEnumUnitsInRangeEx(pid, ug, pt.x, pt.y, pt.aoe, Condition(function isalive))
            set x2 = pt.x
            set y2 = pt.y
            set angle = pt.aoe
        endif

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            set tpid = GetPlayerId(GetOwningPlayer(target)) + 1
            call GroupRemoveUnit(ug, target)

            //allied units
            if IsUnitAlly(target, p) == true then
                //song of harmony
                if (BardSong[pid] == SONG_HARMONY and IsUnitInRangeXY(target, x, y, aoe)) or (i == SONG_HARMONY and IsUnitInRangeXY(target, x2, y2, angle)) then 
                    set heal = GetHeroInt(caster, true) * (.75 + .25 * ablev) * BOOST[pid]
                    call HP(target, heal)
                    call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", target, "origin"))
                endif
                //heroes
                if target == Hero[tpid] then
                    //song of war
                    if (BardSong[pid] == SONG_WAR and IsUnitInRangeXY(target, x, y, aoe)) or (i == SONG_WAR and IsUnitInRangeXY(target, x2, y2, angle)) then 
                        if LoadInteger(EncoreTargets, GetHandleId(target), 2) == 0 then
                            set pt = TimerList[tpid].addTimer(tpid)
                            set pt.target = target
                            call SaveInteger(EncoreTargets, GetHandleId(target), 0, 10)
                            call SaveInteger(EncoreTargets, GetHandleId(target), 1, pid)
                            call SaveInteger(EncoreTargets, GetHandleId(target), 2, 6)
                            call SaveEffectHandle(EncoreTargets, GetHandleId(target), 3, AddSpecialEffectTarget("Abilities\\Spells\\Items\\VampiricPotion\\VampPotionCaster.mdl", target, "origin"))
                            call TimerStart(pt.timer, 1, true, function WarEncorePeriodic)
                        else
                            call SaveInteger(EncoreTargets, GetHandleId(target), 0, 10)
                            call SaveInteger(EncoreTargets, GetHandleId(target), 1, pid)
                            call SaveInteger(EncoreTargets, GetHandleId(target), 2, 6)
                        endif
                    endif
                    //song of peace
                    if (BardSong[pid] == SONG_PEACE and IsUnitInRangeXY(target, x, y, aoe)) or (i == SONG_PEACE and IsUnitInRangeXY(target, x2, y2, angle)) then 
                        call UnitAddAbility(target, 'A01B')
                        call TimerStart(NewTimerEx(GetPlayerId(GetOwningPlayer(target)) + 1), 5. * LBOOST[pid], false, function SongOfPeaceExpire)
                    endif
                endif
            else
            //enemies
                //song of fatigue
                if (BardSong[pid] == SONG_FATIGUE and IsUnitInRangeXY(target, x, y, aoe)) or (i == SONG_FATIGUE and IsUnitInRangeXY(target, x2, y2, angle)) then 
                    call StunUnit(pid, target, 3 * LBOOST[pid])
                endif
            endif
        endloop

    elseif sid == 'A02H' then //Melody of Life
        set heal = BardMelodyCost[pid] * (.25 + .25 * ablev) * BOOST[pid]
        if GetUnitTypeId(target) == BACKPACK then
            call HP(Hero[tpid], heal)
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", GetUnitX(Hero[tpid]), GetUnitY(Hero[tpid])))
        elseif IsUnitAlly(target, p) then
            call HP(target, heal)
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", GetUnitX(target), GetUnitY(target)))
        endif

    elseif sid == 'A06Y' then //Improv
        if BardSong[pid] != 0 then
            set pt = TimerList[pid].addTimer(pid)
            set pt.dur = 20. * LBOOST[pid]
            set pt.x = GetSpellTargetX()
            set pt.y = GetSpellTargetY()
            set pt.target = caster
            set pt.caster = GetDummy(pt.x, pt.y, 0, 0, pt.dur)
            set pt.agi = BardSong[pid]
            set pt.aoe = 750.
            set pt.tag = 'impr' //important for aura check
            set pt.dmg = GetHeroInt(caster, true) * 0.25 * ablev

            call SetUnitScale(pt.caster, 3., 3., 3.)
            call SetUnitOwner(pt.caster, Player(PLAYER_TOWN), true)
            call UnitAddAbility(pt.caster, BardSong[pid])
            call SaveInteger(MiscHash, GetHandleId(pt.caster), 'dspl', BardSong[pid])

            //auras for allies
            if BardSong[pid] != SONG_FATIGUE then
                call BlzSetAbilityRealLevelField(BlzGetUnitAbility(pt.caster, BardSong[pid]), ABILITY_RLF_AREA_OF_EFFECT, 0, pt.aoe)
                call IncUnitAbilityLevel(pt.caster, BardSong[pid])
                call DecUnitAbilityLevel(pt.caster, BardSong[pid])
            endif

            if BardSong[pid] == SONG_WAR then
                set pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingRed.mdx", pt.caster, "origin")
            elseif BardSong[pid] == SONG_HARMONY then
                set pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingGreen.mdx", pt.caster, "origin")
            elseif BardSong[pid] == SONG_PEACE then
                set pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingYellow.mdx", pt.caster, "origin")
            elseif BardSong[pid] == SONG_FATIGUE then
                set pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingPurple.mdx", pt.caster, "origin")
            endif

            call BlzSetSpecialEffectScale(pt.sfx, 4.5)

            call TimerStart(pt.timer, 1., true, function ImprovPeriodic)
        endif

    elseif sid == 'A02K' then //Tone of Death
        set pt = TimerList[pid].addTimer(pid)
        set pt.angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set pt.target = GetDummy(x + 250 * Cos(pt.angle), y + 250 * Sin(pt.angle), 0, 0, 6.)
        set pt.sfx = AddSpecialEffectTarget("war3mapImported\\BlackHoleSpell.mdx", pt.target, "origin") 
        set pt.dur = 180.
        call SetUnitScale(pt.target, 0.5, 0.5, 0.5)

        call TimerStart(pt.timer, 0.03, true, function ToneOfDeath)
        
	//====================
    //Elite Marksman
    //====================
    
    elseif sid == TRIROCKET.id then //Tri-rocket
        set i = 0

        call SoundHandler("Units\\Human\\SteamTank\\SteamTankAttack1.flac", true, p, caster)

        loop
            exitwhen i > 2
            set pt = TimerList[pid].addTimer(pid)
            set pt.target = GetDummy(x, y, 0, 0, 0) 
            set pt.aoe = 100. //hit range
            set pt.dur = 700. 
            set pt.angle = (bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x) + (10. * i - 10.)) 
            set pt.dmg = spell.values[0] * BOOST[pid]
            call BlzSetUnitFacingEx(pt.target, pt.angle)
            call BlzSetUnitSkin(pt.target, 'h01C')
            call SetUnitFlyHeight(pt.target, 75., 0.)
            call SetUnitScalePercent(pt.target, 100.00, 100.00, 100.00)
            call TimerStart(pt.timer, 0.03, true, function TriRocket)
            set i = i + 1
        endloop

        //movement
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 250.
        set pt.angle = (bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x) - 180) 
        call TimerStart(pt.timer, 0.03, true, function TriRocketMovement)

    elseif sid == SINGLESHOT.id then //.600 Single Shot
        set x = x + 80 * Cos(GetUnitFacing(Hero[pid]) * bj_DEGTORAD)
        set y = y + 80 * Sin(GetUnitFacing(Hero[pid]) * bj_DEGTORAD)
        set angle = Atan2(MouseY[pid] - y, MouseX[pid] - x) * bj_RADTODEG
        set dur = (180 - RAbsBJ(RAbsBJ(angle - GetUnitFacing(Hero[pid])) - 180)) * 0.5
        set angle = bj_DEGTORAD * (angle + GetRandomReal(-(dur), dur))
        set bj_lastCreatedUnit = GetDummy(x + 1500. * Cos(angle), y + 1500. * Sin(angle), 0, 0, 1.5)
        call SetUnitOwner(bj_lastCreatedUnit, p, true)
        call UnitRemoveAbility(bj_lastCreatedUnit, 'Avul')
        call UnitRemoveAbility(bj_lastCreatedUnit, 'Aloc')
        set target = GetDummy(x, y, 'A05J', 1, 1.5)
        call SetUnitOwner(target, p, false)
        call BlzSetUnitFacingEx(target, bj_RADTODEG * angle)
        call UnitDisableAbility(target, 'Amov', true)
        call InstantAttack(target, bj_lastCreatedUnit)
        call SoundHandler("war3mapImported\\xm1014-3.wav", false, Player(pid - 1), null)

        set i = 1

        loop
            exitwhen i > 30
            call MakeGroupInRange(pid, ug, x, y, 150. * LBOOST[pid], Condition(function FilterEnemy))

            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                if Buff.has(Hero[pid], target, SingleShotDebuff.typeid) == false then
                    call UnitDamageTarget(Hero[pid], target, spell.values[0] * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
                endif
                set SingleShotDebuff.add(Hero[pid], target).duration = 3.
            endloop

            set x = x + 50 * Cos(angle)
            set y = y + 50 * Sin(angle)
            set i = i + 1
        endloop
        
    elseif sid == SNIPERSTANCE.id then //Sniper Stance On
        if sniperstance[pid] then
            set sniperstance[pid] = false
            call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 0, 6.)
            call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 1, 6.)
            call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 2, 6.)
            call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 3, 6.)
            call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 4, 6.)
            call BlzSetAbilityStringLevelField(BlzGetUnitAbility(caster, sid), ABILITY_SLF_TOOLTIP_NORMAL, 0, "Enable Sniper Stance - [|cffffcc00D|r]")
        else
            set sniperstance[pid] = true
            call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 0, 3.)
            call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 1, 3.)
            call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 2, 3.)
            call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 3, 3.)
            call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 4, 3.)
            call BlzSetAbilityStringLevelField(BlzGetUnitAbility(caster, sid), ABILITY_SLF_TOOLTIP_NORMAL, 0, "Disable Sniper Stance - [|cffffcc00D|r]")
        endif

        call UnitAddAbility(caster, 'Avul')
        call TimerStart(NewTimerEx(pid), 0.03, false, function StanceAbilityDelay)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\Defend\\DefendCaster.mdl", caster, "origin"))
    elseif sid == HANDGRENADE.id then //Hand Grenade
        if UnitAlive(helicopter[pid]) then
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Flare\\FlareCaster.mdl", x, y))
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Flare\\FlareTarget.mdl", GetSpellTargetX(), GetSpellTargetY()))
            set pt = TimerList[pid].addTimer(pid)
            set pt.x = GetSpellTargetX()
            set pt.y = GetSpellTargetY()
            set pt.dur = 3.
            set pt.dmg = spell.values[1] * heliboost[pid]
            call TimerStart(pt.timer, 0.7, true, function HeliRocketPeriodic)
        else
            set pt = TimerList[pid].addTimer(pid)
            set pt.target = GetDummy(x, y, 0, 0, 5.)
            set pt.angle = Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
            set pt.dur = SquareRoot(Pow(GetSpellTargetX() - x, 2) + Pow(GetSpellTargetY() - y, 2))
            set pt.armor = pt.dur
            set pt.speed = 24.
            set pt.aoe = 300. * LBOOST[pid]
            set pt.dmg = spell.values[0] * BOOST[pid]
            call BlzSetUnitSkin(pt.target, 'h03J')
            call SetUnitScale(pt.target, 1.5, 1.5, 1.5)
            call TimerStart(pt.timer, 0.03, true, function HandGrenadePeriodic)
        endif
        
    elseif sid == U235SHELL.id then //U-235 Shell
        set i = 1
        set i2 = 1
        set angle = bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
        set g = CreateGroup()
        set dmg = spell.values[0] * BOOST[pid]
        
        loop
            exitwhen i > 10
            loop
                exitwhen i2 > 3
                set x = GetUnitX(caster) + 175 * i * Cos((angle + 10 * i2 - 20) * bj_DEGTORAD)
                set y = GetUnitY(caster) + 175 * i * Sin((angle + 10 * i2 - 20) * bj_DEGTORAD)
                
                call DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
                call MakeGroupInRange(pid, ug, x, y, 150. * LBOOST[pid], Condition(function FilterEnemy))

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

        //movement
        set pt = TimerList[pid].addTimer(pid)
        set pt.dur = 250.
        set pt.angle = angle - 180
        call TimerStart(pt.timer, 0.03, true, function TriRocketMovement)
		
	//========================
	//Misc
	//========================
		
	elseif sid == 'A09G' then //Free Dobby
		call RemoveUnit(caster)
		call DisplayTextToPlayer(p, 0, 0, "The worker has gone home to live out his life in peace.")
		
	elseif sid == 'A0A9' or sid == 'A0A7' or sid == 'A0A6' or sid == 'S001' or sid == 'A0A5' then //Castle of the Gods
		if ChaosMode then
			call IssueImmediateOrder(caster, "stop")
			call DisplayTimedTextToPlayer(p, 0, 0, 10.00, "With the Gods dead, the Castle of Gods can no longer draw enough power from them in order to use its abilities.")
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
            call BlzSetSpecialEffectScale(HeroTimedLife[pid], 0)
            call DestroyEffect(HeroTimedLife[pid])
            
            if sid == 'A042' then //item revival
                set itm2 = GetResurrectionItem(pid, false)
                set heal = ItemData[itm2.id][ITEM_ABILITY] * 0.01
            
                set itm2.charge = itm2.charges - 1
                
                if ItemData[itm2.id][ITEM_ABILITY * ABILITY_OFFSET] == 'Anrv' and itm2.charges <= 0 then //remove perishable resurrections
                    call itm2.destroy()
                endif
                
                call RevivePlayer(pid, GetSpellTargetX(), GetSpellTargetY(), heal, heal)
            elseif sid == 'A044' then //pr reincarnation
                call RevivePlayer(pid, GetSpellTargetX(), GetSpellTargetY(), 100, 100)

                call BlzStartUnitAbilityCooldown(Hero[pid], REINCARNATION.id, 300.)
            elseif sid == 'A045' then //high priestess revival
                set heal = 20 + 10 * GetUnitAbilityLevel(Hero[ResurrectionRevival[pid]], 'A048')
                call RevivePlayer(pid, GetSpellTargetX(), GetSpellTargetY(), heal, heal)
            endif
            
            if sid != 'A045' and ResurrectionRevival[pid] > 0 then //refund HP cooldown and mana
                call BlzEndUnitAbilityCooldown(Hero[ResurrectionRevival[pid]], 'A048')
                call SetUnitState(Hero[ResurrectionRevival[pid]], UNIT_STATE_MANA, BlzGetUnitMaxMana(Hero[ResurrectionRevival[pid]]) * 0.5)
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
    elseif sid == 'A00Q' then //banish demon
        set itm = GetItemFromUnit(caster, 'I0OU')
        if ChaosMode then
            if target == Boss[BOSS_LEGION] then
                call Item[itm].destroy()
                if BANISH_FLAG == false then
                    set BANISH_FLAG = true
                    call DisplayTimedTextToForce(FORCE_PLAYING, 30., "|cffffcc00Legion:|r Fool! Did you really think splashing water on me would do anything?")
                endif
            else
                call DisplayTimedTextToPlayer(p, 0., 0., 30., "Maybe you shouldn't waste this...")
            endif
        else
            if target == Boss[BOSS_DEATH_KNIGHT] then 
                call Item[itm].destroy()
                if BANISH_FLAG == false then
                    set BANISH_FLAG = true
                    call DisplayTimedTextToForce(FORCE_PLAYING, 30., "|cffffcc00Death Knight:|r ...???")
                endif
            else
                call DisplayTimedTextToPlayer(p, 0., 0., 30., "Maybe you shouldn't waste this...")
            endif
        endif
	endif

    //on cast aggro (ignore actions menu)
    if caster == Hero[pid] and sid != 'A03V' and sid != 'A0L0' and sid != 'A0GD' and sid != 'A06X' and sid != 'A08Y' and sid != 'A00B' and sid != 'A02T' and sid != 'A031' and sid != 'A067' then
        if GetSpellTargetX() == 0. and GetSpellTargetY() == 0. then
            call Taunt(caster, pid, 800., false, 0, 200)
        else
            call Taunt(caster, pid, RMinBJ(800., DistanceCoords(x, y, GetSpellTargetX(), GetSpellTargetY())), false, 0, 200)
        endif
    endif
	
	call DestroyGroup(ug)
	
	set caster = null
	set target = null
	set p = null
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
    local trigger channel = CreateTrigger()
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
        set heropanel[pid] = DialogCreate()
        set votekickpanel[pid] = DialogCreate()
        set ArcaneBarrageHit[pid] = CreateGroup()
        set attargets[pid] = CreateGroup()
        set StasisFieldTargets[pid] = CreateGroup()
        set arcanosphereGroup[pid] = CreateGroup()
        set magnetic_stance_group[pid] = CreateGroup()
		call TriggerRegisterDialogEvent(skinbuttonclick, dChangeSkin[pid])
        call TriggerRegisterDialogEvent(cosmeticbuttonclick, dCosmetics[pid])
        call TriggerRegisterDialogEvent(heropanelclick, heropanel[pid])
        call TriggerRegisterDialogEvent(votekickpanelclick, votekickpanel[pid])
		call TriggerRegisterPlayerUnitEvent(spell, u.toPlayer(), EVENT_PLAYER_UNIT_SPELL_EFFECT, null)
		call TriggerRegisterPlayerUnitEvent(cast, u.toPlayer(), EVENT_PLAYER_UNIT_SPELL_CAST, null)
		call TriggerRegisterPlayerUnitEvent(finish, u.toPlayer(), EVENT_PLAYER_UNIT_SPELL_FINISH, null)
        call TriggerRegisterPlayerUnitEvent(learn, u.toPlayer(), EVENT_PLAYER_HERO_SKILL, null)
		call TriggerRegisterPlayerUnitEvent(channel, u.toPlayer(), EVENT_PLAYER_UNIT_SPELL_CHANNEL, null)
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A0JV', false) //elementalist setup
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A0JX', false)
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A0JW', false)
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A0JZ', false)
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A0JY', false)
		call SetPlayerAbilityAvailable(u.toPlayer(), prMulti[0], false) //pr setup
		call SetPlayerAbilityAvailable(u.toPlayer(), prMulti[1], false)
		call SetPlayerAbilityAvailable(u.toPlayer(), prMulti[2], false)
		call SetPlayerAbilityAvailable(u.toPlayer(), prMulti[3], false)
		call SetPlayerAbilityAvailable(u.toPlayer(), prMulti[4], false)
		call SetPlayerAbilityAvailable(u.toPlayer(), 'A0AP', false)
		call SetPlayerAbilityAvailable(u.toPlayer(), SONG_HARMONY, false)  //bard setup
		call SetPlayerAbilityAvailable(u.toPlayer(), SONG_PEACE, false) 
		call SetPlayerAbilityAvailable(u.toPlayer(), SONG_WAR, false)
        call SetPlayerAbilityAvailable(u.toPlayer(), SONG_FATIGUE, false)
        call SetPlayerAbilityAvailable(u.toPlayer(), DETECT_LEAVE_ABILITY, false)
		set u = u.next
	endloop

    /*
    call SetPlayerAbilityAvailable(Player(PLAYER_TOWN), SONG_WAR, true)
    call SetPlayerAbilityAvailable(Player(PLAYER_TOWN), SONG_HARMONY, true)
    call SetPlayerAbilityAvailable(Player(PLAYER_TOWN), SONG_PEACE, true)
    call SetPlayerAbilityAvailable(Player(PLAYER_TOWN), SONG_FATIGUE, true)
    */
    call SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_HARMONY, false)
    call SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_WAR, false)
    call SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_PEACE, false)
    call SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_FATIGUE, false)
    call SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), DETECT_LEAVE_ABILITY, false)
    call TriggerRegisterPlayerUnitEvent(onenemyspell, pfoe, EVENT_PLAYER_UNIT_SPELL_EFFECT, null)
    call TriggerAddAction(onenemyspell, function EnemySpells)
	
	call TriggerAddCondition(skinbuttonclick, Filter(function SkinButtonClick))
    call TriggerAddCondition(cosmeticbuttonclick, Filter(function CosmeticButtonClick))
    call TriggerAddCondition(heropanelclick, Filter(function HeroPanelClick))
    call TriggerAddCondition(votekickpanelclick, Filter(function VotekickPanelClick))
	
	call TriggerAddAction(spell, function OnEffect)
	call TriggerAddAction(cast, function OnCast)
	call TriggerAddAction(finish, function OnFinish)
    call TriggerAddCondition(learn, Filter(function OnLearn))
    call TriggerAddCondition(channel, Filter(function OnChannel))
	
    set spell = null
    set onenemyspell = null
	set cast = null
	set finish = null
    set learn = null
    set channel = null
	set skinbuttonclick = null
    set cosmeticbuttonclick = null
    set heropanelclick = null
    set votekickpanelclick = null
endfunction

endlibrary
