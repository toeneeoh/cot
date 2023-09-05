library Bosses initializer init requires Functions, Spells

globals
    boolean holywardcd = false
    unit holyward
    group legionillusions = CreateGroup()
endglobals

function BossCD takes nothing returns nothing
    set BossSpellCD[ReleaseTimer(GetExpiredTimer())] = false
endfunction

function BossUnpause takes nothing returns nothing
    local integer i = ReleaseTimer(GetExpiredTimer())
    
    call PauseUnit(Boss[i], false)
    call SetUnitAnimation(Boss[i], "stand")
endfunction
    
function StompPeriodic takes nothing returns nothing
    local PlayerTimer pt = TimerList[BOSS_ID].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null
        
    set pt.dur = pt.dur - 1
        
    if pt.dur <= 0 or UnitAlive(pt.caster) == false then
        call TimerList[BOSS_ID].removePlayerTimer(pt)
    else
        call MakeGroupInRange(BOSS_ID, ug, GetUnitX(pt.caster), GetUnitY(pt.caster), 300., Condition(function FilterEnemy))
        
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(pt.caster), GetUnitY(pt.caster)))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call UnitDamageTarget(pt.caster, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    endif
        
    call DestroyGroup(ug)
        
    set ug = null
    set target = null
endfunction

/*/*/*

Minotaur

*/*/*/

/*/*/*

Hellfire Magi

*/*/*/

/*/*/*

Dwarf

*/*/*/

/*/*/*

Death Knight

*/*/*/

function ShadowStepTeleport takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    call SetUnitXBounded(pt.target, pt.x)
    call SetUnitYBounded(pt.target, pt.y)
    call SetUnitVertexColor(pt.target, BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_RED), BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_GREEN), BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_BLUE), 255)
    call PauseUnit(pt.target, false)
    call BlzSetUnitFacingEx(pt.target, 270.)

    call TimerList[pid].removePlayerTimer(pt)
endfunction

function BossTeleport takes unit target, real dur returns nothing
    local integer i = 0
    local PlayerTimer pt
    local unit guy = null
    local string msg = ""
    local integer pid = GetPlayerId(GetOwningPlayer(target)) + 1

    if ChaosMode then
        set guy = Boss[BOSS_LEGION]
        set msg = "Shadow Step"
        call BlzStartUnitAbilityCooldown(guy, 'A0AV', 2040. - (User.AmountPlaying * 240))
    else
        set guy = Boss[BOSS_DEATH_KNIGHT]
        set msg = "Death March"
        call BlzStartUnitAbilityCooldown(guy, 'A0AU', 2040. - (User.AmountPlaying * 240))
    endif

    if UnitAlive(guy) then
        call DoFloatingTextUnit(msg, guy, 1.75, 100, 0, 12, 154, 38, 158, 0)
        call PauseUnit(guy, true)
        call Fade(guy, dur - 0.5, true)
        set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
        set pt.x = GetUnitX(target)
        set pt.y = GetUnitY(target)
        set pt.tag = 'tpin'
        set pt.target = guy 
        set bj_lastCreatedUnit = GetDummy(pt.x, pt.y, 0, 0, dur)
        call BlzSetUnitSkin(bj_lastCreatedUnit, GetUnitTypeId(guy))
        call SetUnitVertexColor(bj_lastCreatedUnit, BlzGetUnitIntegerField(bj_lastCreatedUnit, UNIT_IF_TINTING_COLOR_RED), BlzGetUnitIntegerField(bj_lastCreatedUnit, UNIT_IF_TINTING_COLOR_GREEN), BlzGetUnitIntegerField(bj_lastCreatedUnit, UNIT_IF_TINTING_COLOR_BLUE), 0)
        call Fade(bj_lastCreatedUnit, dur, false)
        call BlzSetUnitFacingEx(bj_lastCreatedUnit, 270.)
        call PauseUnit(bj_lastCreatedUnit, true)
        call TimerStart(pt.timer, dur, false, function ShadowStepTeleport)
        if dur >= 4 then
           call PlaySound("Sound\\Interface\\CreepAggroWhat1.flac")
            if ChaosMode then
                call DisplayTimedTextToForce(FORCE_PLAYING, 20., "|cffffcc00Legion:|r There is no escape " + User(pid - 1).nameColored + "..")
            else
                call DisplayTimedTextToForce(FORCE_PLAYING, 20., "|cffffcc00Death Knight:|r Prepare yourself " + User(pid - 1).nameColored + "!")
            endif
        endif
    endif

    set guy = null
endfunction

function ShadowStepExpire takes nothing returns boolean
    local group ug = CreateGroup()
    local group g = CreateGroup()
    local unit guy
    local integer i = 0

    if ChaosMode then
        set guy = Boss[BOSS_LEGION]
    else
        set guy = Boss[BOSS_DEATH_KNIGHT]
    endif

    call GroupEnumUnitsInRect(ug, gg_rct_Main_Map, Condition(function ischar))
    call GroupEnumUnitsInRect(g, gg_rct_NoSin, Condition(function ischar))

    loop
        exitwhen i > BOSS_TOTAL
        call GroupEnumUnitsInRangeEx(BOSS_ID, g, GetLocationX(BossLoc[i]), GetLocationY(BossLoc[i]), 2000., Condition(function ischar))
        set i = i + 1
    endloop

    if BlzGroupGetSize(g) > 0 then
        call BlzGroupRemoveGroupFast(g, ug)
    endif

    call GroupEnumUnitsInRange(g, GetUnitX(guy), GetUnitY(guy), 1500., Condition(function ischar))

    if BlzGroupGetSize(ug) > 0 and BlzGroupGetSize(g) == 0 then //no nearby players and player available to teleport to
        set guy = BlzGroupUnitAt(ug, GetRandomInt(0, BlzGroupGetSize(ug) - 1)) 
        if guy != null then
            set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\BlackSmoke.mdx", GetUnitX(guy), GetUnitY(guy))
            call BlzSetSpecialEffectTimeScale(bj_lastCreatedEffect, 0.75)
            call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 1.)
            call DestroyEffectTimed(bj_lastCreatedEffect, 3.)

            call BossTeleport(guy, 4.)
        endif
    endif

    call DestroyGroup(ug)
    call DestroyGroup(g)

    set ug = null
    set g = null
    set guy = null

    return false
endfunction
    
function DeathStrike takes nothing returns nothing
    local PlayerTimer pt = TimerList[BOSS_ID].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null

    call SetUnitAnimation(pt.caster, "death")
        
    call MakeGroupInRange(BOSS_ID, ug, pt.x, pt.y, 180., Condition(function FilterEnemy))
    call DestroyEffect(AddSpecialEffect("NecroticBlast.mdx", pt.x, pt.y))
        
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call UnitDamageTarget(Boss[BOSS_DEATH_KNIGHT], target, 15000., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop
        
    call TimerList[BOSS_ID].removePlayerTimer(pt)
    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

/*/*/*

//Goddesses

*/*/*/

function SunStrike takes nothing returns nothing
    local PlayerTimer pt = TimerList[BOSS_ID].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null

    call MakeGroupInRange(BOSS_ID, ug, pt.x, pt.y, 150., Condition(function FilterEnemy))

    call DestroyEffect(AddSpecialEffect("war3mapImported\\OrbitalRay.mdx", pt.x, pt.y))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)

        call UnitDamageTarget(Boss[BOSS_LIFE], target, 25000., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop

    call TimerList[BOSS_ID].removePlayerTimer(pt)

    call DestroyGroup(ug)

    set ug = null
endfunction

function HolyWardCD takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())

    set holywardcd = false
endfunction

function HolyWard takes nothing returns nothing
    local group ug = CreateGroup()
    local unit target

    call ReleaseTimer(GetExpiredTimer())

    if UnitAlive(holyward) then
        call KillUnit(holyward)
        call MakeGroupInRange(BOSS_ID, ug, GetUnitX(holyward), GetUnitY(holyward), 2500., Condition(function FilterAllyHero))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)

            call HP(target, 100000)
            set HolyBlessing.add(target, target).duration = 30.
            call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", target, "origin"), 2)
        endloop
    endif

    call DestroyGroup(ug)

    set holyward = null
    set ug = null
endfunction

function GhostShroud takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local group ug = CreateGroup()
    local unit target
    
    if IsUnitType(Boss[BOSS_KNOWLEDGE], UNIT_TYPE_ETHEREAL) then
        call MakeGroupInRange(BOSS_ID, ug, GetUnitX(Boss[BOSS_KNOWLEDGE]), GetUnitY(Boss[BOSS_KNOWLEDGE]), 500., Condition(function FilterEnemy))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)

            call UnitDamageTarget(Boss[BOSS_KNOWLEDGE], target, RMaxBJ(0, GetHeroInt(Boss[BOSS_KNOWLEDGE], true) - GetHeroInt(target, true)), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    else
        call ReleaseTimer(t)
    endif

    call DestroyGroup(ug)

    set ug = null
    set t = null
endfunction

/*/*/*

//Absolute Horror

*/*/*/
    
function ZeppelinKill takes nothing returns nothing
    local group ug = CreateGroup()
    local unit u
    local integer bossindex = 0
    local integer zepcount = 0

    loop
        exitwhen bossindex > BOSS_TOTAL
        if UnitAlive(Boss[bossindex]) and IsUnitInRangeLoc(Boss[bossindex], BossLoc[bossindex], 1500.) then
            call GroupEnumUnitsInRange(ug, GetUnitX(Boss[bossindex]), GetUnitY(Boss[bossindex]), 900., Condition(function iszeppelin))
            set zepcount = BlzGroupGetSize(ug)
            loop
                set u = FirstOfGroup(ug)
                exitwhen u == null
                call GroupRemoveUnit(ug, u)
                call ExpireUnit(u)
            endloop
            if zepcount > 0 then
                call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(Boss[bossindex]), GetUnitY(Boss[bossindex])))
                call SetUnitAnimation(Boss[bossindex], "attack slam")
            endif
        endif
        set bossindex = bossindex + 1
    endloop

    call DestroyGroup(ug)

    set u = null
    set ug = null
endfunction

function TrueStealth takes nothing returns nothing
    local PlayerTimer pt = TimerList[BOSS_ID].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null
    local real heal = 0.
        
    call MakeGroupInRange(BOSS_ID, ug, pt.x, pt.y, 400., Condition(function FilterEnemy))

    call UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], 'Amrf')
    call UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], 'A043')
    call UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], 'BOwk')
    call UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], 'Avul')
    call SetUnitXBounded(Boss[BOSS_ABSOLUTE_HORROR], pt.x)
    call SetUnitYBounded(Boss[BOSS_ABSOLUTE_HORROR], pt.y)
    call SetUnitAnimation(Boss[BOSS_ABSOLUTE_HORROR], "Attack Slam")
        
    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x, pt.y))
    set target = FirstOfGroup(ug)
    if target != null then
        set heal = GetWidgetLife(target)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "origin"))
        call UnitDamageTarget(Boss[BOSS_ABSOLUTE_HORROR], target, 80000. + BlzGetUnitMaxHP(target) * 0.3, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", Boss[BOSS_ABSOLUTE_HORROR], "chest"))
        set heal = RMaxBJ(0, heal - GetWidgetLife(target))
        call SetUnitState(Boss[BOSS_ABSOLUTE_HORROR], UNIT_STATE_LIFE, GetWidgetLife(Boss[BOSS_ABSOLUTE_HORROR]) + heal)
    endif
        
    call TimerList[BOSS_ID].removePlayerTimer(pt)
        
    call DestroyGroup(ug)
        
    set ug = null
    set target = null
endfunction

/*/*/*

Slaughter Queen

*/*/*/

function ResetSlaughterMS takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())

    call SetUnitMoveSpeed(Boss[BOSS_SLAUGHTER_QUEEN], 300)
endfunction

function SlaughterAvatar takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())

    call IssueImmediateOrder(Boss[BOSS_SLAUGHTER_QUEEN], "avatar")
    call SetUnitMoveSpeed(Boss[BOSS_SLAUGHTER_QUEEN], 270)
    call TimerStart(NewTimer(), 10., false, function ResetSlaughterMS)
    set BossSpellCD[1] = false
endfunction

/*/*/*

Dark Soul

*/*/*/

function DarkSoulAbility takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target = null

    set pt.dur = pt.dur - 1

    if not UnitAlive(pt.caster) or pt.dur < 0 or pt.agi == 0 then
        call TimerList[pid].removePlayerTimer(pt)
    elseif pt.dur == 0 then
        //freeze
        if pt.agi == 3 then
            call MakeGroupInRange(pid, ug, GetUnitX(pt.caster), GetUnitY(pt.caster), 300., Condition(function FilterEnemy))
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(pt.caster), GetUnitY(pt.caster)))

            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                set Stun.add(pt.caster, target).duration = 5.
            endloop
        //mortify
        elseif pt.agi == 1 then
            call BossPlusSpell(pt.caster, 1000000, 1, "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl")
        //terrify
        elseif pt.agi == 2 then
            call BossXSpell(pt.caster, 1000000,1, "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl")
        endif
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

/*/*/*

Satan

*/*/*/

function SatanFlameStrike takes real x, real y returns nothing
    local unit dummy = GetDummy(GetUnitX(Boss[BOSS_SATAN]), GetUnitY(Boss[BOSS_SATAN]), 'A0DN', 1, DUMMY_RECYCLE_TIME) 

    call SetUnitOwner(dummy, pboss, false)
    call SaveInteger(MiscHash, GetHandleId(dummy), 'sflm', 10)
    call IssuePointOrder(dummy, "flamestrike", x, y)

    set dummy = null
endfunction

/*/*/*

Thanatos

*/*/*/

function ThanatosAbility takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target = null
    local group ug = null

    if UnitAlive(pt.caster) then
        if pt.agi == 1 then
            set ug = CreateGroup()
            call GroupEnumUnitsInRange(ug, pt.x, pt.y, 200., Condition(function ishostileEnemy))

            call SetUnitXBounded(pt.caster, pt.x)
            call SetUnitYBounded(pt.caster, pt.y)
            call SetUnitAnimation(pt.caster, "attack")
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", target, "chest"))
                call UnitDamageTarget(pt.caster, target, 1500000, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            endloop

            call DestroyGroup(ug)
        elseif pt.agi == 2 then
            call BossBlastTaper(pt.caster, 1000000, 'A0A4', 750) 
        endif
    endif

    call TimerList[pid].removePlayerTimer(pt)

    set target = null
    set ug = null
endfunction

/*/*/*

Pure Existence

*/*/*/

function ExistenceAbility takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    set pt.dur = pt.dur - 1

    if pt.dur < 0 or not UnitAlive(pt.caster) then
        call TimerList[pid].removePlayerTimer(pt)
    elseif pt.dur == 3 then
        if pt.agi == 2 then
            call BossInnerRing(pt.caster, 1000111,2, 400, "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl")
        elseif pt.agi == 4 then
            call BossOuterRing(pt.caster, 500111,2, 450, 900, "war3mapImported\\NeutralExplosion.mdx")
        endif
    elseif pt.dur == 2 then
        if pt.agi == 1 then
            call BossXSpell(pt.caster, 500111,2, "Abilities\\Spells\\Undead\\ReplenishMana\\ReplenishManaCasterOverhead.mdl")
        endif
    elseif pt.dur == 1 then
        if pt.agi == 2 then
            call BossBlastTaper(pt.caster, 1500111,'A0AB', 800)
        endif
    elseif pt.dur == 0 then
        if pt.agi == 1 then
            call BossPlusSpell(pt.caster, 500111,2, "Abilities\\Spells\\Undead\\ReplenishMana\\ReplenishManaCasterOverhead.mdl")
        endif
    endif
endfunction

/*/*/*

Legion

*/*/*/

function SpawnLegionIllusions takes nothing returns nothing
    local integer i = 0

    call ReleaseTimer(GetExpiredTimer())

    if UnitAlive(Boss[BOSS_LEGION]) then
        loop
            exitwhen i >= 7
            
            call Item.assign(UnitAddItemById(Boss[BOSS_LEGION], 'I06V'))

            set i = i + 1
        endloop
    endif
endfunction

function PositionLegionIllusions takes nothing returns boolean
    local unit u = GetSummonedUnit()
    local real x = GetLocationX(BossLoc[BOSS_LEGION])
    local real y = GetLocationY(BossLoc[BOSS_LEGION])
    local unit target = null
    local real x2
    local real y2
    local integer i = GetRandomInt(0, 359)
    local integer i2 = 1

    if GetUnitTypeId(u) == 'H04R' and IsUnitIllusion(u) then
        call GroupAddUnit(legionillusions, u)
        call SetUnitPathing(u, false)
        call UnitAddAbility(u, 'Amrf')
        call RemoveItem(UnitItemInSlot(u, 0))
        call RemoveItem(UnitItemInSlot(u, 1))
        call RemoveItem(UnitItemInSlot(u, 2))
        call RemoveItem(UnitItemInSlot(u, 3))
        call RemoveItem(UnitItemInSlot(u, 4))
        call RemoveItem(UnitItemInSlot(u, 5))
    endif

    if BlzGroupGetSize(legionillusions) >= 7 then
        loop
            set x2 = x + 700 * Cos(bj_DEGTORAD * i)
            set y2 = y + 700 * Sin(bj_DEGTORAD * i)

            exitwhen IsTerrainWalkable(x2, y2) and RectContainsCoords(gg_rct_NoSin, x2, y2) == false

            set i = GetRandomInt(0, 359)
        endloop

        call SetUnitXBounded(Boss[BOSS_LEGION], x2)
        call SetUnitYBounded(Boss[BOSS_LEGION], y2)
        call SetUnitPathing(Boss[BOSS_LEGION], false)
        call SetUnitPathing(Boss[BOSS_LEGION], true)
        call BlzSetUnitFacingEx(Boss[BOSS_LEGION], bj_RADTODEG * Atan2(y2 - y, x2 - x))
        call IssuePointOrder(Boss[BOSS_LEGION], "attack", x, y)

        loop
            set target = FirstOfGroup(legionillusions)
            exitwhen target == null
            call GroupRemoveUnit(legionillusions, target)

            set x2 = x + 700 * Cos(bj_DEGTORAD * (i + i2 * 45))
            set y2 = y + 700 * Sin(bj_DEGTORAD * (i + i2 * 45))

            call SetUnitXBounded(target, x2)
            call SetUnitYBounded(target, y2)
            call BlzSetUnitFacingEx(target, bj_RADTODEG * Atan2(y2 - y, x2 - x))
            call IssuePointOrder(target, "attack", x, y)

            set i2 = i2 + 1
        endloop
    endif

    set u = null

    return false
endfunction

/*/*/*

Azazoth

*/*/*/

/*/*/*

Forgotten Leader

*/*/*/
    
function UnstoppableForceMovement takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local group ug = CreateGroup()
    local unit target
        
    if UnitAlive(Boss[BOSS_FORGOTTEN_LEADER]) == false then
        call TimerList[pid].removePlayerTimer(pt)
        call DestroyGroup(ug)
        set ug = null
        return
    endif

    call GroupEnumUnitsInRange(ug, GetUnitX(Boss[BOSS_FORGOTTEN_LEADER]), GetUnitY(Boss[BOSS_FORGOTTEN_LEADER]), 400., Condition(function isplayerunit))
        
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if IsUnitInGroup(target, pt.ug) == false then
            call GroupAddUnit(pt.ug, target)
            call UnitDamageTarget(Boss[BOSS_FORGOTTEN_LEADER], target, 50000000., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif
    endloop

    set pt.angle = Atan2(pt.y - GetUnitY(Boss[BOSS_FORGOTTEN_LEADER]), pt.x - GetUnitX(Boss[BOSS_FORGOTTEN_LEADER])) 
        
    if IsUnitInRangeXY(Boss[BOSS_FORGOTTEN_LEADER], pt.x, pt.y, 125.) or DistanceCoords(pt.x, pt.y, GetUnitX(Boss[BOSS_FORGOTTEN_LEADER]), GetUnitY(Boss[BOSS_FORGOTTEN_LEADER])) > 2500. then
        call SetUnitPathing(Boss[BOSS_FORGOTTEN_LEADER], true)
        call IssueImmediateOrder(Boss[BOSS_FORGOTTEN_LEADER], "stand")
        call PauseUnit(Boss[BOSS_FORGOTTEN_LEADER], false)
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x + 200, pt.y))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x - 200, pt.y))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x, pt.y + 200))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x, pt.y - 200))
        
        call TimerList[pid].removePlayerTimer(pt)
    else
        call SetUnitPathing(Boss[BOSS_FORGOTTEN_LEADER], false)
        call SetUnitXBounded(Boss[BOSS_FORGOTTEN_LEADER], GetUnitX(Boss[BOSS_FORGOTTEN_LEADER]) + 55 * Cos(pt.angle))
        call SetUnitYBounded(Boss[BOSS_FORGOTTEN_LEADER], GetUnitY(Boss[BOSS_FORGOTTEN_LEADER]) + 55 * Sin(pt.angle))
        call IssueImmediateOrder(Boss[BOSS_FORGOTTEN_LEADER], "stop")
    endif
    
    call DestroyGroup(ug)
        
    set ug = null
    set target = null
endfunction
    
function UnstoppableForce takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    call TimerStart(pt.timer, 0.03, true, function UnstoppableForceMovement)
endfunction

function XallaSummon takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    call UnitApplyTimedLife(CreateUnit(Player(pid - 1), 'o034', pt.x + 400 * Cos((pt.angle + 90) * bj_DEGTORAD), pt.y + 400 * Sin((pt.angle + 90) * bj_DEGTORAD), pt.angle), 'BTLF', 120.)
    call UnitApplyTimedLife(CreateUnit(Player(pid - 1), 'o034', pt.x + 400 * Cos((pt.angle - 90) * bj_DEGTORAD), pt.y + 400 * Sin((pt.angle - 90) * bj_DEGTORAD), pt.angle), 'BTLF', 120.)

    call TimerList[pid].removePlayerTimer(pt)
endfunction

/*


*/

function BossSpellCasting takes unit source, unit target returns nothing
    local PlayerTimer pt
    local integer i = 0
    local group ug = CreateGroup()
    local unit u = null
    local real angle = 0.

    //prechaos bosses
    //hellfire magi
    if not ChaosMode then
        if target == Boss[BOSS_HELLFIRE] and UnitAlive(Boss[BOSS_HELLFIRE]) then
            //frost armor
            if BlzGetUnitAbilityCooldownRemaining(target, 'A02M') <= 0 then
                call SpellCast(target, 'A02M', 1., 4)
                set FrostArmorBuff.add(target, target).duration = 10.
            //chain lightning
            elseif BlzGetUnitAbilityCooldownRemaining(target, 'A00G') <= 0 then 
                call IssueTargetOrder(target, "chainlightning", source)
            //flame strike
            elseif BlzGetUnitAbilityCooldownRemaining(target, 'A01T') <= 0 then
                call IssuePointOrder(target, "flamestrike", GetUnitX(source), GetUnitY(source))
            endif
        //lady vashj
        elseif target == Boss[BOSS_VASHJ] and UnitAlive(Boss[BOSS_VASHJ]) then
            //tornado storm
            if BlzGetUnitAbilityCooldownRemaining(target, 'A085') <= 0 then
                call SpellCast(target, 'A085', 1.5, 5)
                set bj_lastCreatedUnit = CreateUnit(Player(PLAYER_BOSS), 'n001', GetUnitX(target), GetUnitY(target), 0.)
                call IssuePointOrder(bj_lastCreatedUnit, "move", GetRandomReal(GetUnitX(target) - 250, GetUnitX(target) + 250), GetRandomReal(GetUnitY(target) - 250, GetUnitY(target) + 250))
                call RemoveUnitTimed(bj_lastCreatedUnit, 40.)
                set bj_lastCreatedUnit = CreateUnit(Player(PLAYER_BOSS), 'n001', GetUnitX(target), GetUnitY(target), 0.)
                call IssuePointOrder(bj_lastCreatedUnit, "move", GetRandomReal(GetUnitX(target) - 250, GetUnitX(target) + 250), GetRandomReal(GetUnitY(target) - 250, GetUnitY(target) + 250))
                call RemoveUnitTimed(bj_lastCreatedUnit, 40.)
            endif
        //tauren
        elseif target == Boss[BOSS_TAUREN] and UnitAlive(Boss[BOSS_TAUREN]) then
            //shockwave
            if BlzGetUnitAbilityCooldownRemaining(target, 'A02L') <= 0 and UnitDistance(source, target) < 600 then
                call IssuePointOrder(Boss[BOSS_TAUREN], "carrionswarm", GetUnitX(source), GetUnitY(source))
            //war stomp
            elseif BlzGetUnitAbilityCooldownRemaining(target, 'A09J') <= 0 and UnitDistance(source, target) < 300. then
                call DoFloatingTextUnit("War Stomp", Boss[BOSS_TAUREN], 2., 60., 0, 12, 255, 255, 255, 0)
                call SpellCast(target, 'A09J', 1., 4)
                set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
                set pt.dmg = 4000.
                set pt.caster = target
                set pt.dur = 8
                call TimerStart(pt.timer, 1., true, function StompPeriodic)
            endif
        //mystic
        elseif target == Boss[BOSS_MYSTIC] and UnitAlive(Boss[BOSS_MYSTIC]) then
            if UnitDistance(target, source) < 800. then
                //mana drain
                if BlzGetUnitAbilityCooldownRemaining(target, 'A05I') <= 0 then
                    call SpellCast(target, 'A05I', 0.5, 4)
                    call MakeGroupInRange(BOSS_ID, ug, GetUnitX(target), GetUnitY(target), 800., Condition(function FilterEnemy))
                    loop
                        set target = FirstOfGroup(ug)
                        exitwhen target == null
                        call GroupRemoveUnit(ug, target)

                    endloop
                endif
            endif

        //dwarf
        elseif target == Boss[BOSS_DWARF] and UnitAlive(Boss[BOSS_DWARF]) then
            if UnitDistance(target, source) < 300. then
                //avatar
                if BlzGetUnitAbilityCooldownRemaining(target, 'A0DV') <= 0 then
                    call IssueImmediateOrder(Boss[BOSS_DWARF], "avatar")
                //thunder clap
                elseif BlzGetUnitAbilityCooldownRemaining(target, 'A0A2') <= 0 then
                    call DoFloatingTextUnit("Thunder Clap", Boss[BOSS_DWARF], 2., 60., 0, 12, 0, 255, 255, 0)
                    call SpellCast(target, 'A0A2', 1., 4)
                    set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
                    set pt.dmg = 8000.
                    set pt.caster = target
                    set pt.dur = 8
                    call TimerStart(pt.timer, 1., true, function StompPeriodic)
                endif
            endif
        //death knight
        elseif target == Boss[BOSS_DEATH_KNIGHT] and UnitAlive(Boss[BOSS_DEATH_KNIGHT]) then
            if BlzGetUnitAbilityCooldownRemaining(target, 'A0AO') <= 0 and UnitDistance(source, target) > 250. then
                call BlzStartUnitAbilityCooldown(target, 'A0AO', 20.)
                call BossTeleport(source, 1.5)
            //death strikes
            elseif BlzGetUnitAbilityCooldownRemaining(target, 'A088') <= 0 then
                call SpellCast(target, 'A088', 0.7, 3)
                call MakeGroupInRange(BOSS_ID, ug, GetUnitX(target), GetUnitY(target), 1250., Condition(function FilterEnemy))
                call DoFloatingTextUnit("Death Strikes", Boss[BOSS_DEATH_KNIGHT], 2., 60., 0, 12, 255, 255, 255, 0)
                loop
                    set u = FirstOfGroup(ug)
                    exitwhen u == null
                    call GroupRemoveUnit(ug, u)
                    if BlzGroupGetSize(ug) < 4 then
                        set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
                        set pt.x = GetUnitX(u)
                        set pt.y = GetUnitY(u)
                        set pt.caster = GetDummy(pt.x, pt.y, 0, 0, DUMMY_RECYCLE_TIME) 
                        call SetUnitScale(pt.caster, 4., 4., 4.)
                        call BlzSetUnitSkin(pt.caster, 'e01F')
                        call TimerStart(pt.timer, 3., false, function DeathStrike)
                    endif
                endloop
            endif
        //vengeful test paladin
        elseif target == Boss[BOSS_PALADIN] and UnitAlive(Boss[BOSS_PALADIN]) then
            call IssueTargetOrder(target, "holybolt", target)
        //Goddesses
        elseif (target == Boss[BOSS_HATE] or target == Boss[BOSS_LOVE] or target == Boss[BOSS_KNOWLEDGE]) then
            //Love Holy Ward
            if UnitAlive(Boss[BOSS_LOVE]) and (GetWidgetLife(Boss[BOSS_LOVE]) / BlzGetUnitMaxHP(Boss[BOSS_LOVE])) <= 0.8 then
                if holywardcd == false then
                    set holywardcd = true
                    set holyward = CreateUnit(pboss, 'o009', GetRandomReal(GetRectMinX(gg_rct_Crystal_Spawn) - 500, GetRectMaxX(gg_rct_Crystal_Spawn) + 500), GetRandomReal(GetRectMinY(gg_rct_Crystal_Spawn) - 600, GetRectMaxY(gg_rct_Crystal_Spawn) + 600), 0)
                
                    call MakeGroupInRange(BOSS_ID, ug, GetUnitX(holyward), GetUnitY(holyward), 1250, Condition(function FilterEnemy))
                    call BlzSetUnitMaxHP(holyward, 10 * BlzGroupGetSize(ug))
                    
                    call TimerStart(NewTimer(), 10, false, function HolyWard)
                    call TimerStart(NewTimer(), 40, false, function HolyWardCD)

                    call GroupClear(ug)
                endif
            endif

            //knowledge
            if target == Boss[BOSS_KNOWLEDGE] and UnitAlive(Boss[BOSS_KNOWLEDGE]) and (GetWidgetLife(Boss[BOSS_KNOWLEDGE]) / BlzGetUnitMaxHP(Boss[BOSS_KNOWLEDGE])) <= 0.8 then
                call IssueTargetOrder(target, "silence", source)
                call IssueTargetOrder(target, "hex", source)

                //ghost shroud
                if BlzGetUnitAbilityCooldownRemaining(target, 'A0A8') <= 0 then
                    call BlzStartUnitAbilityCooldown(target, 'A0A8', 20.)
                    call DummyCastTarget(pboss, target, 'A08I', 1, GetUnitX(target), GetUnitY(target), "banish")
                    call TimerStart(NewTimer(), 1, true, function GhostShroud)
                endif
            endif
        //Life
        //sun strike
        elseif (target == Boss[BOSS_LIFE]) and UnitAlive(target) and (GetWidgetLife(target) / BlzGetUnitMaxHP(target)) <= 0.9 and BlzGetUnitAbilityCooldownRemaining(target, 'A08M') <= 0 then
            call BlzStartUnitAbilityCooldown(target, 'A08M', 20.)

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

                set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
                set pt.x = GetUnitX(u)
                set pt.y = GetUnitY(u)
                call TimerStart(pt.timer, 3., false, function SunStrike)

                set i = i + 1
            endloop
        endif
    else
    //chaos bosses
        //Demon Prince
        if target == Boss[BOSS_DEMON_PRINCE] and UnitAlive(Boss[BOSS_DEMON_PRINCE]) and (GetWidgetLife(Boss[BOSS_DEMON_PRINCE]) / BlzGetUnitMaxHP(Boss[BOSS_DEMON_PRINCE])) <= 0.5 then
            if BlzGetUnitAbilityCooldownRemaining(target, 'A0AX') <= 0 then
                call BlzStartUnitAbilityCooldown(target, 'A0AX', 60.)
                set DemonPrinceBloodlust.add(target, target).duration = 60.
                call DummyCastTarget(Player(PLAYER_BOSS), target, 'A041', 1, GetUnitX(target), GetUnitY(target), "bloodlust")
            endif
        //Absolute Horror
        elseif target == Boss[BOSS_ABSOLUTE_HORROR] and UnitAlive(Boss[BOSS_ABSOLUTE_HORROR]) and (GetWidgetLife(Boss[BOSS_ABSOLUTE_HORROR]) / BlzGetUnitMaxHP(Boss[BOSS_ABSOLUTE_HORROR])) <= 0.8 then
            set i = GetRandomInt(0, 99)
            if i < 10 and BlzGetUnitAbilityCooldownRemaining(target, 'A0AC') <= 0 then
                call BlzStartUnitAbilityCooldown(target, 'A0AC', 10.)

                call MakeGroupInRange(BOSS_ID, ug, GetUnitX(target), GetUnitY(target), 1500., Condition(function FilterEnemy))
                call DoFloatingTextUnit("True Stealth", Boss[BOSS_ABSOLUTE_HORROR], 1.75, 100, 0, 12, 90, 30, 150, 0)
                call UnitRemoveBuffs(Boss[BOSS_ABSOLUTE_HORROR], false, true)
                call UnitAddAbility(Boss[BOSS_ABSOLUTE_HORROR], 'Avul')
                call UnitAddAbility(Boss[BOSS_ABSOLUTE_HORROR], 'A043')
                call IssueImmediateOrder(Boss[BOSS_ABSOLUTE_HORROR], "windwalk")
                set u = FirstOfGroup(ug)
                if u != null then
                    set angle = Atan2(GetUnitY(u) - GetUnitY(Boss[BOSS_ABSOLUTE_HORROR]), GetUnitX(u) - GetUnitX(Boss[BOSS_ABSOLUTE_HORROR]))
                    call UnitAddAbility(Boss[BOSS_ABSOLUTE_HORROR], 'Amrf')
                    call IssuePointOrder(Boss[BOSS_ABSOLUTE_HORROR], "move", GetUnitX(u) + 300 * Cos(angle), GetUnitY(u) + 300 * Sin(angle))
                    set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
                    set pt.x = GetUnitX(u) + 150 * Cos(angle)
                    set pt.y = GetUnitY(u) + 150 * Sin(angle)
                    call TimerStart(pt.timer, 2., false, function TrueStealth)
                else
                    call UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], 'Avul')
                    call UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], 'A043')
                    call UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], 'BOwk')
                endif
                call GroupClear(ug)
            endif
        //Slaughter
        elseif target == Boss[BOSS_SLAUGHTER_QUEEN] then
            set i = GetRandomInt(1, 8)
            if HardMode > 0 then
                call SetUnitAbilityLevel(Boss[BOSS_SLAUGHTER_QUEEN], 'A064', 2)
            else
                call SetUnitAbilityLevel(Boss[BOSS_SLAUGHTER_QUEEN], 'A064', 1)
            endif

            if i == 1 and BlzGetUnitAbilityCooldownRemaining(Boss[BOSS_SLAUGHTER_QUEEN], 'A064') <= 0 and BossSpellCD[1] == false then
                set BossSpellCD[1] = true
                call DoFloatingTextUnit("Avatar", Boss[BOSS_SLAUGHTER_QUEEN], 3, 100, 0, 13, 255, 255, 255, 0)
                call TimerStart(NewTimer(), 2, false, function SlaughterAvatar)
            endif
        //Dark Soul
        elseif target == Boss[BOSS_DARK_SOUL] and UnitAlive(Boss[BOSS_DARK_SOUL]) then
            set i = GetRandomInt(1, 2)
            set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
            set pt.caster = target
            set pt.dur = 4
            set pt.agi = 0
            if BlzGetUnitAbilityCooldownRemaining(target, 'A03M') <= 0 then
                if i == 1 then
                    call DoFloatingTextUnit("+ MORTIFY +", target, 3, 70, 0, 11, 255, 255, 255, 0)
                    set pt.agi = 1
                else
                    call DoFloatingTextUnit("x TERRIFY x", target, 3, 70, 0, 11, 255, 255, 255, 0)
                    set pt.agi = 2
                endif
                call BlzStartUnitAbilityCooldown(target, 'A03M', 5.)
                call BlzStartUnitAbilityCooldown(target, 'A05U', 5.)
            elseif BlzGetUnitAbilityCooldownRemaining(target, 'A02Q') <= 0 then
                call DoFloatingTextUnit("||||| FREEZE |||||", target, 3, 70, 0, 11, 255, 255, 255, 0)
                set pt.agi = 3
                call BlzStartUnitAbilityCooldown(target, 'A02Q', 25.)
                call DelayAnimation(BOSS_ID, target, 2., 5, 0.75, true)
            endif
            call TimerStart(pt.timer, 0.5, true, function DarkSoulAbility)
        //Satan
        elseif target == Boss[BOSS_SATAN] and UnitAlive(Boss[BOSS_SATAN]) then
            if GetRandomInt(0, 99) < 10 then
                call SatanFlameStrike(GetUnitX(source), GetUnitY(source))
            endif
        //Legion
        elseif target == Boss[BOSS_LEGION] and UnitAlive(Boss[BOSS_LEGION]) then
            if BlzGetUnitAbilityCooldownRemaining(target, 'A05I') <= 0 and UnitDistance(source, target) > 250. then //shadow step
                call SpellCast(target, 'A05I', 0., 1)
                call BossTeleport(source, 1.5)
            elseif BlzGetUnitAbilityCooldownRemaining(target, 'A08C') <= 0 and TimerList[BOSS_ID].hasTimerWithTag('tpin') == false and UnitDistance(source, target) < 800 then
                call SpellCast(target, 'A08C', 0.5, 12)
                call DestroyEffectTimed(AddSpecialEffect("Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX(Boss[BOSS_LEGION]), GetUnitY(Boss[BOSS_LEGION])), 2)
                call RemoveLocation(BossLoc[BOSS_LEGION])
                set BossLoc[BOSS_LEGION] = Location(GetUnitX(source), GetUnitY(source))
                call TimerStart(NewTimer(), 0.5, false, function SpawnLegionIllusions)
            endif
        elseif target == Boss[BOSS_THANATOS] and UnitAlive(Boss[BOSS_THANATOS]) then //Thanatos Spells
            set i = GetRandomInt(0, 99)

            if i < 10 then
                set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
                set pt.x = GetUnitX(source)
                set pt.y = GetUnitY(source)
                set pt.caster = target

                if BlzGetUnitAbilityCooldownRemaining(target, 'A023') <= 0 and UnitDistance(source, target) > 250 then
                    call BlzStartUnitAbilityCooldown(target, 'A023', 10.)
                    call DoFloatingTextUnit("Swift Hunt", target, 1, 70, 0, 10, 255, 255, 255, 0)
                    set pt.agi = 1
                    call TimerStart(pt.timer, 1.5, true, function ThanatosAbility)
                elseif BlzGetUnitAbilityCooldownRemaining(target, 'A02P') <= 0 then
                    call SpellCast(target, 'A02P', 2., 12)
                    call DoFloatingTextUnit("Death Beckons", target, 2, 70, 0, 10, 255, 255, 255, 0)
                    set pt.agi = 2
                    call TimerStart(pt.timer, 2.5, true, function ThanatosAbility)
                endif
            endif
        //Existence
        elseif target == Boss[BOSS_EXISTENCE] then
            set i = GetRandomInt(0, 99)
            if BossSpellCD[4] == false and i < 50 then
                set BossSpellCD[4] = true
                set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
                set pt.caster = target
                set pt.dur = 5
                if i < 5 then
                    call TimerStart(NewTimerEx(4), 10., false, function BossCD)
                    set pt.agi = 1
                    call DoFloatingTextUnit("Devastation", u ,2, 70, 0, 12, 255, 40, 40, 0)
                elseif i < 10 then
                    call TimerStart(NewTimerEx(4), 10., false, function BossCD)
                    set pt.agi = 2
                    call DoFloatingTextUnit("Extermination", u, 3, 70, 0, 12, 255, 255, 255, 0)
                elseif i < 15 then
                    set pt.agi = 3
                    call TimerStart(NewTimerEx(4), 10., false, function BossCD)
                    call DoFloatingTextUnit("Implosion", u, 3, 70, 0, 12, 68, 68, 255, 0)
                elseif i < 20 then
                    set pt.agi = 4
                    call TimerStart(NewTimerEx(4), 10., false, function BossCD)
                    call DoFloatingTextUnit("Explosion", u, 3, 70, 0, 12, 255, 100, 50, 0)
                endif
                call TimerStart(pt.timer, 0.5, true, function ExistenceAbility)
            elseif BossSpellCD[6] == false then
                set BossSpellCD[6] = true
                call DoFloatingTextUnit("Protected Existence", u, 3, 70, 0, 12, 100, 255, 100, 0)
                set ProtectedExistenceBuff.add(u, u).duration = 10.
                call TimerStart(NewTimerEx(6), 30., false, function BossCD)
            endif

        //Forgotten Leader
        elseif target == Boss[BOSS_FORGOTTEN_LEADER] and UnitAlive(Boss[BOSS_FORGOTTEN_LEADER]) then
            set i = GetRandomInt(0, 99)
            if i < 6 and BossSpellCD[11] == false then
                call GroupEnumUnitsInRange(ug, GetUnitX(Boss[BOSS_FORGOTTEN_LEADER]), GetUnitY(Boss[BOSS_FORGOTTEN_LEADER]), 1500., Condition(function isplayerAlly))
                set u = FirstOfGroup(ug)
                if u != null then
                    call DoFloatingTextUnit("Unstoppable Force", Boss[BOSS_FORGOTTEN_LEADER], 1.75, 100, 0, 12, 255, 0, 0, 0)
                    call TimerStart(NewTimerEx(11), 11.00, false, function BossCD)
                    set BossSpellCD[11] = true
                    call PauseUnit(Boss[BOSS_FORGOTTEN_LEADER], true)
                    set bj_lastCreatedUnit = GetDummy(GetUnitX(u), GetUnitY(u), 0, 0, 3.)
                    call SetUnitScale(bj_lastCreatedUnit, 10., 10., 10.)
                    call BlzSetUnitFacingEx(bj_lastCreatedUnit, 270.)
                    call BlzSetUnitSkin(bj_lastCreatedUnit, 'e01F')
                    call SetUnitVertexColor(bj_lastCreatedUnit, 200, 200, 0, 255)
                    set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
                    set pt.x = GetUnitX(u)
                    set pt.y = GetUnitY(u)
                    set pt.ug = CreateGroup()
                    set pt.angle = Atan2(GetUnitY(u) - GetUnitY(Boss[BOSS_FORGOTTEN_LEADER]), GetUnitX(u) - GetUnitX(Boss[BOSS_FORGOTTEN_LEADER])) 
                    call BlzSetUnitFacingEx(Boss[BOSS_FORGOTTEN_LEADER], bj_RADTODEG * pt.angle)
                    call TimerStart(pt.timer, 2.5, false, function UnstoppableForce)
                endif
                call GroupClear(ug)
            elseif BossSpellCD[12] == false and GetWidgetLife(Boss[BOSS_FORGOTTEN_LEADER]) <= BlzGetUnitMaxHP(Boss[BOSS_FORGOTTEN_LEADER]) * 0.5 then
                call DoFloatingTextUnit("Reinforcements", Boss[BOSS_FORGOTTEN_LEADER], 1.75, 100, 0, 12, 255, 0, 0, 0)
                call TimerStart(NewTimerEx(12), 120.00, false, function BossCD)
                set BossSpellCD[12] = true
                set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
                set pt.angle = GetUnitFacing(Boss[BOSS_FORGOTTEN_LEADER]) 
                set pt.x = GetUnitX(Boss[BOSS_FORGOTTEN_LEADER])
                set pt.y = GetUnitY(Boss[BOSS_FORGOTTEN_LEADER])
                call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", pt.x + 400 * Cos((pt.angle + 90) * bj_DEGTORAD), pt.y + 400 * Sin((pt.angle + 90) * bj_DEGTORAD)))
                call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", pt.x + 400 * Cos((pt.angle - 90) * bj_DEGTORAD), pt.y + 400 * Sin((pt.angle - 90) * bj_DEGTORAD)))
                call TimerStart(pt.timer, 2., false, function XallaSummon)
            endif
        //Azazoth
        elseif target == Boss[BOSS_AZAZOTH] then
            set i = GetRandomInt(0, 99)

            if udg_Azazoth_Casting_Spell == false then
                if i < 15 and BossSpellCD[7] == false then
                    set BossSpellCD[7] = true
                    set udg_Azazoth_Casting_Spell = true
                    set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
                    set pt.dur = 4
                    set pt.dmg = 4000000
                    set pt.angle = GetUnitFacing(Boss[BOSS_AZAZOTH])
                    set pt.caster = target
                    call PauseUnit(target, true)
                    call TimerStart(pt.timer, IMinBJ(7, IMaxBJ(3, R2I(GetUnitLifePercent(Boss[BOSS_AZAZOTH]) * 0.1))) * 0.1, true, function AstralDevastation)
                    call TimerStart(NewTimerEx(7), 20 + GetUnitLifePercent(Boss[BOSS_AZAZOTH]) / 10., false, function BossCD)
                elseif i < 30 and BossSpellCD[9] == false then
                    set BossSpellCD[9] = true
                    set udg_Azazoth_Casting_Spell = true
                    set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
                    set pt.dur = 4
                    set pt.dmg = 2000000.
                    set pt.caster = target
                    call PauseUnit(target, true)
                    call TimerStart(pt.timer, IMinBJ(7, IMaxBJ(3, R2I(GetUnitLifePercent(Boss[BOSS_AZAZOTH]) * 0.1))) * 0.1, true, function AstralAnnihilation)
                    call TimerStart(NewTimerEx(9), GetRandomInt(35, 45) + GetUnitLifePercent(Boss[BOSS_AZAZOTH]) / 10., false, function BossCD)
                elseif i < 40 and BossSpellCD[8] == false then
                    set BossSpellCD[8] = true
                    call DoFloatingTextUnit("Astral Shield", Boss[BOSS_AZAZOTH], 3, 70, 0, 11, 102, 255, 102, 0)
                    set AstralShieldBuff.add(Boss[BOSS_AZAZOTH], Boss[BOSS_AZAZOTH]).duration = 13.
                    call TimerStart(NewTimerEx(8), GetRandomInt(25, 35) + GetUnitLifePercent(Boss[BOSS_AZAZOTH]) / 10., false, function BossCD)
                endif
            endif
        endif
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
endfunction

private function init takes nothing returns nothing
    local trigger t = CreateTrigger()

    call TriggerRegisterPlayerUnitEvent(t, pboss, EVENT_PLAYER_UNIT_SUMMON, null)
    call TriggerAddCondition(t, Filter(function PositionLegionIllusions))

    set t = null
endfunction

endlibrary
