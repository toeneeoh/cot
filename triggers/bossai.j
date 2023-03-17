library Bosses initializer init requires Functions

globals
    boolean trifirecd = false
    boolean taurencd = false
    boolean dwarfcd = false
    boolean deathstrikecd = false
    boolean truestealthcd = false
    boolean legionillusioncd = false
    boolean holywardcd = false
    boolean ghostshroudcd = false
    boolean spellreflectcd = false
    boolean sunstrikecd = false
    unit holyward
    group deathstriketargets = CreateGroup()
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

/*/*/*

Minotaur

*/*/*/

function TaurenStompCD takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
        
    set taurencd = false
endfunction
    
function TaurenStomp takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer time = GetTimerData(t)
    local group ug = CreateGroup()
    local unit target
        
    call SetTimerData(t, time + 1)
        
    if time + 1 > 8 or IsUnitType(Boss[BOSS_TAUREN], UNIT_TYPE_DEAD) or GetWidgetLife(Boss[BOSS_TAUREN]) < 0.406 then
        call ReleaseTimer(t)
    else
        call GroupEnumUnitsInRange(ug, GetUnitX(Boss[BOSS_TAUREN]), GetUnitY(Boss[BOSS_TAUREN]), 300.00, Condition(function ishostileEnemy))
        
        call DestroyEffect(AddSpecialEffect( "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(Boss[BOSS_TAUREN]), GetUnitY(Boss[BOSS_TAUREN])) )

        loop
            set target=FirstOfGroup(ug)
            exitwhen target==null
            call GroupRemoveUnit(ug, target)
            call UnitDamageTarget(Boss[BOSS_TAUREN],target,HMscale(4000),true,false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
        endloop
    endif
        
    call DestroyGroup(ug)
        
    set t = null
    set ug = null
    set target = null
endfunction

/*/*/*

Hellfire Magi

*/*/*/

function TrifireCD takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
        
    set trifirecd = false
endfunction

/*/*/*

Dwarf

*/*/*/

function DwarfStompCD takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
        
    set dwarfcd = false
endfunction
    
function DwarfStomp takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer time = GetTimerData(t)
    local group ug = CreateGroup()
    local unit target
        
    call SetTimerData(t, time + 1)
        
    if time + 1 > 8 or IsUnitType(Boss[BOSS_DWARF], UNIT_TYPE_DEAD) or GetWidgetLife(Boss[BOSS_DWARF]) < 0.406 then
        call ReleaseTimer(t)
    else
        call GroupEnumUnitsInRange(ug, GetUnitX(Boss[BOSS_DWARF]), GetUnitY(Boss[BOSS_DWARF]), 300.00, Condition(function ishostileEnemy))
            
        call DestroyEffect(AddSpecialEffect( "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(Boss[BOSS_DWARF]), GetUnitY(Boss[BOSS_DWARF])) )
        loop
            set target=FirstOfGroup(ug)
            exitwhen target==null
            call GroupRemoveUnit(ug, target)
            call DummyCastTarget(pboss, target, 'A04G', 1, GetUnitX(Boss[BOSS_DWARF]), GetUnitY(Boss[BOSS_DWARF]), "slow")
            call UnitDamageTarget(Boss[BOSS_DWARF],target,HMscale(8000),true,false,ATTACK_TYPE_NORMAL,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
        endloop
    endif
        
    call DestroyGroup(ug)
        
    set t = null
    set ug = null
    set target = null
endfunction

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

function ShadowStep takes unit target, real speed returns nothing
    local integer i = 0
    local PlayerTimer pt
    local unit guy
    local string msg = ""
    local integer pid = GetPlayerId(GetOwningPlayer(target)) + 1

    if udg_Chaos_World_On then
        set guy = Boss[BOSS_LEGION]
        set msg = "Shadow Step"
    else
        set guy = Boss[BOSS_DEATH_KNIGHT]
        set msg = "Death March"
    endif

    if GetWidgetLife(guy) >= 0.406 then
        call DoFloatingTextUnit( msg, guy , 1.75 , 100 , 0 , 12 , 154 , 38 , 158 , 0)
        call PauseUnit(guy, true)
        call Fade(guy, 30, 0.02 * speed, 1)
        set pt = TimerList[bossid].addTimer(bossid)
        set pt.x = GetUnitX(target)
        set pt.y = GetUnitY(target)
        set pt.tag = 'tpin'
        set pt.target = guy 
        set bj_lastCreatedUnit = GetDummy(pt.x, pt.y, 0, 0, speed)
        call BlzSetUnitSkin(bj_lastCreatedUnit, GetUnitTypeId(guy))
        call SetUnitVertexColor(bj_lastCreatedUnit, BlzGetUnitIntegerField(bj_lastCreatedUnit, UNIT_IF_TINTING_COLOR_RED), BlzGetUnitIntegerField(bj_lastCreatedUnit, UNIT_IF_TINTING_COLOR_GREEN), BlzGetUnitIntegerField(bj_lastCreatedUnit, UNIT_IF_TINTING_COLOR_BLUE), 0)
        call Fade(bj_lastCreatedUnit, 30, 0.02 * speed, -1)
        call BlzSetUnitFacingEx(bj_lastCreatedUnit, 270.)
        call PauseUnit(bj_lastCreatedUnit, true)
        call TimerStart(pt.getTimer(), speed, false, function ShadowStepTeleport)
        if speed >= 4 then
           call PlaySound("Sound\\Interface\\CreepAggroWhat1.flac")
            if udg_Chaos_World_On then
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

    if udg_Chaos_World_On then
        set guy = Boss[BOSS_LEGION]
    else
        set guy = Boss[BOSS_DEATH_KNIGHT]
    endif

    call GroupEnumUnitsInRect(ug, gg_rct_Main_Map, Condition(function ischar))
    call GroupEnumUnitsInRect(g, gg_rct_NoSin, Condition(function ischar))

    loop
        exitwhen i > BOSS_TOTAL
        call GroupEnumUnitsInRangeEx(bossid, g, GetLocationX(BossLoc[i]), GetLocationY(BossLoc[i]), 2000., Condition(function ischar))
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

            call ShadowStep(guy, 4)
        endif
    endif

    call DestroyGroup(ug)
    call DestroyGroup(g)

    set ug = null
    set g = null
    set guy = null

    return false
endfunction

function DeathStrikeCD takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
    
    set deathstrikecd = false
endfunction
    
function DeathStrike takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local group ug = CreateGroup()
    local real x = LoadReal(MiscHash, GetHandleId(t), 0)
    local real y = LoadReal(MiscHash, GetHandleId(t), 1)
    local unit dummy = LoadUnitHandle(MiscHash, GetHandleId(t), 2)
    local unit target

    call SetUnitAnimation(dummy, "death")
        
    call GroupEnumUnitsInRange(ug, x, y, 180., Condition(function isplayerunit))
    call DestroyEffect(AddSpecialEffect("NecroticBlast.mdx", x, y))
    call RemoveSavedReal(MiscHash, GetHandleId(t), 0)
    call RemoveSavedReal(MiscHash, GetHandleId(t), 1)
    call RemoveSavedHandle(MiscHash, GetHandleId(t), 2)
        
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call UnitDamageTarget(Boss[BOSS_DEATH_KNIGHT], target, 10000., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop
        
    call ReleaseTimer(t)
    call DestroyGroup(ug)

    set t = null
    set ug = null
    set target = null
    set dummy = null
endfunction

/*/*/*

//Goddesses

*/*/*/

function SunStrikeCD takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())

    set sunstrikecd = false
endfunction

function SunStrike takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local real x = LoadReal(MiscHash, 0, GetHandleId(t))
    local real y = LoadReal(MiscHash, 1, GetHandleId(t))
    local group ug = CreateGroup()
    local unit target

    call MakeGroupInRange(bossid, ug, x, y, 150., Condition(function FilterEnemy))

    call DestroyEffect(AddSpecialEffect("war3mapImported\\OrbitalRay.mdx", x, y))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)

        call UnitDamageTarget(Boss[BOSS_LIFE], target, HMscale(25000.), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
    endloop

    call RemoveSavedReal(MiscHash, 0, GetHandleId(t))
    call RemoveSavedReal(MiscHash, 1, GetHandleId(t))
    call ReleaseTimer(t)

    call DestroyGroup(ug)

    set ug = null
    set t = null
endfunction

function SpellReflectCD takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())

    set spellreflectcd = false
endfunction

function HolyWardCD takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())

    set holywardcd = false
endfunction

function HolyWard takes nothing returns nothing
    local group ug = CreateGroup()
    local unit target

    call ReleaseTimer(GetExpiredTimer())

    if GetWidgetLife(holyward) >= 0.406 then
        call KillUnit(holyward)
        call MakeGroupInRange(bossid, ug, GetUnitX(holyward), GetUnitY(holyward), 2500., Condition(function FilterAllyHero))

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

function GhostShroudCD takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())

    set ghostshroudcd = false
endfunction

function GhostShroud takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local group ug = CreateGroup()
    local unit target
    
    if IsUnitType(Boss[BOSS_KNOWLEDGE], UNIT_TYPE_ETHEREAL) then
        call MakeGroupInRange(bossid, ug, GetUnitX(Boss[BOSS_KNOWLEDGE]), GetUnitY(Boss[BOSS_KNOWLEDGE]), 500., Condition(function FilterEnemy))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)

            call UnitDamageTarget(Boss[BOSS_KNOWLEDGE], target, RMaxBJ(0, GetHeroInt(Boss[BOSS_KNOWLEDGE], true) - GetHeroInt(target, true)), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    else
        call UnitRemoveAbility(Boss[BOSS_KNOWLEDGE], 'A08M')
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
        if GetWidgetLife(Boss[bossindex]) >= 0.406 and IsUnitInRangeLoc(Boss[bossindex], BossLoc[bossindex], 1500.) then
            call GroupEnumUnitsInRange(ug, GetUnitX(Boss[bossindex]), GetUnitY(Boss[bossindex]), 900., Condition(function iszeppelin))
            set zepcount = BlzGroupGetSize(ug)
            loop
                set u = FirstOfGroup(ug)
                exitwhen u == null
                call GroupRemoveUnit(ug, u)
                call ExpireUnit(u)
            endloop
            if zepcount > 0 then
                call DestroyEffect(AddSpecialEffect( "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(Boss[bossindex]), GetUnitY(Boss[bossindex])) )
                call SetUnitAnimation(Boss[bossindex], "attack slam")
            endif
        endif
        set bossindex = bossindex + 1
    endloop

    call DestroyGroup(ug)

    set u = null
    set ug = null
endfunction

function TrueStealthCD takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
    
    set truestealthcd = false
endfunction

function TrueStealth takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local real x = LoadReal(MiscHash, 0, GetHandleId(t))
    local real y = LoadReal(MiscHash, 1, GetHandleId(t))
    local group ug = CreateGroup()
    local unit target
    local real heal = 0.
        
    call GroupEnumUnitsInRange(ug, x, y, 400., Condition(function isplayerAlly))

    call UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], 'Amrf')
    call UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], 'A043')
    call UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], 'BOwk')
    call UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], 'Avul')
    call SetUnitXBounded(Boss[BOSS_ABSOLUTE_HORROR], x)
    call SetUnitYBounded(Boss[BOSS_ABSOLUTE_HORROR], y)
    call PauseUnit(Boss[BOSS_ABSOLUTE_HORROR], true)
    call SetUnitAnimation(Boss[BOSS_ABSOLUTE_HORROR], "attack slam")
    call TimerStart(NewTimerEx(BOSS_ABSOLUTE_HORROR), 0.4, false, function BossUnpause)
        
    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x, y))
    set target = FirstOfGroup(ug)
    if target != null then
        set heal = GetWidgetLife(target)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "origin"))
        call UnitDamageTarget(Boss[BOSS_ABSOLUTE_HORROR], target, HMscale(80000) + BlzGetUnitMaxHP(target) * 0.3, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", Boss[BOSS_ABSOLUTE_HORROR], "chest"))
        set heal = RMaxBJ(0, heal - GetWidgetLife(target))
        call SetUnitState(Boss[BOSS_ABSOLUTE_HORROR], UNIT_STATE_LIFE, GetWidgetLife(Boss[BOSS_ABSOLUTE_HORROR]) + heal)
    endif
        
    call RemoveSavedReal(MiscHash, 0, GetHandleId(t))
    call RemoveSavedReal(MiscHash, 1, GetHandleId(t))
    call ReleaseTimer(t)
        
    call DestroyGroup(ug)
        
    set t = null
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

function ThanatosSwiftHunt takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target = null
    local group ug = CreateGroup()

    if GetWidgetLife(Boss[BOSS_THANATOS]) >= 0.406 then
        call GroupEnumUnitsInRange(ug, pt.x, pt.y, 200., Condition(function ishostileEnemy))

        call SetUnitXBounded(Boss[BOSS_THANATOS], pt.x)
        call SetUnitYBounded(Boss[BOSS_THANATOS], pt.y)
        call SetUnitAnimation(Boss[BOSS_THANATOS], "attack")
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", target, "chest"))
            call UnitDamageTarget(Boss[BOSS_THANATOS], target, HMscale(1500000), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
    endif

    call TimerList[pid].removePlayerTimer(pt)

    call DestroyGroup(ug)

    set target = null
    set ug = null
endfunction

/*/*/*

Pure Existence

*/*/*/

/*/*/*

Legion

*/*/*/

function LegionIllusionCD takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
    
    call UnitRemoveAbility(Boss[BOSS_LEGION], 'A08C')

    set legionillusioncd = false
endfunction

function GroupLegionIllusions takes nothing returns nothing
    local unit u = GetSummonedUnit()

    if GetUnitTypeId(u) == 'H04R' and IsUnitIllusion(u) then
        call GroupAddUnit(legionillusions, u)
        call SetUnitPathing(u, false)
    endif

    set u = null
endfunction

function PositionLegionIllusions takes nothing returns nothing
    local unit target
    local timer t = GetExpiredTimer()
    local real x = LoadReal(MiscHash, 0, GetHandleId(t))
    local real y = LoadReal(MiscHash, 1, GetHandleId(t))
    local real x2 = LoadReal(MiscHash, 2, GetHandleId(t))
    local real y2 = LoadReal(MiscHash, 3, GetHandleId(t))
    local integer degree = LoadInteger(MiscHash, 4, GetHandleId(t))
    local integer i = 1

    if BlzGroupGetSize(legionillusions) >= 7 then
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

            set x2 = x + 700 * Cos(bj_DEGTORAD * (degree + i * 45))
            set y2 = y + 700 * Sin(bj_DEGTORAD * (degree + i * 45))

            call SetUnitXBounded(target, x2)
            call SetUnitYBounded(target, y2)
            call BlzSetUnitFacingEx(target, bj_RADTODEG * Atan2(y2 - y, x2 - x))
            call IssuePointOrder(target, "attack", x, y)

            set i = i + 1
        endloop

        call RemoveSavedReal(MiscHash, 0, GetHandleId(t))
        call RemoveSavedReal(MiscHash, 1, GetHandleId(t))
        call RemoveSavedReal(MiscHash, 2, GetHandleId(t))
        call RemoveSavedReal(MiscHash, 3, GetHandleId(t))
        call RemoveSavedInteger(MiscHash, 4, GetHandleId(t))
        call ReleaseTimer(t)
    endif

    set t = null
endfunction

function LegionIllusion takes nothing returns nothing
    local group ug = CreateGroup()
    local unit target
    local real x
    local real y
    local real x2
    local real y2
    local integer i = 0
    local integer i2 = 0
    local timer t

    call GroupEnumUnitsInRange(ug, GetUnitX(Boss[BOSS_LEGION]), GetUnitY(Boss[BOSS_LEGION]), 1000., Condition(function isplayerAlly))
    set target = FirstOfGroup(ug)

    if target != null then
        set x = GetUnitX(target)
        set y = GetUnitY(target)
    else
        set x = GetUnitX(Boss[BOSS_LEGION])
        set y = GetUnitY(Boss[BOSS_LEGION])
    endif

    loop
        set x2 = x + 700 * Cos(bj_DEGTORAD * i)
        set y2 = y + 700 * Sin(bj_DEGTORAD * i)

        exitwhen IsTerrainWalkable(x2, y2)

        set i = i + 1
        if i > 359 then
            set x2 = x
            set y2 = y
            exitwhen true
        endif
    endloop

    call DestroyEffectTimed(AddSpecialEffect("Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX(Boss[BOSS_LEGION]), GetUnitY(Boss[BOSS_LEGION])), 2)

    call UnitAddAbility(Boss[BOSS_LEGION], 'A08C')
    call IssueImmediateOrder(Boss[BOSS_LEGION], "mirrorimage")

    set t = NewTimer()
    call SaveReal(MiscHash, 0, GetHandleId(t), x)
    call SaveReal(MiscHash, 1, GetHandleId(t), y)
    call SaveReal(MiscHash, 2, GetHandleId(t), x2)
    call SaveReal(MiscHash, 3, GetHandleId(t), y2)
    call SaveInteger(MiscHash, 4, GetHandleId(t), i)

    call TimerStart(t, 0.05, true, function PositionLegionIllusions)

    call DestroyGroup(ug)

    set target = null
    set ug = null
    set t = null
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
        
    if GetWidgetLife(Boss[BOSS_FORGOTTEN_LEADER]) < 0.406 then
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
            call UnitDamageTarget(Boss[BOSS_FORGOTTEN_LEADER], target, HMscale(50000000.), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endif
    endloop
        
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

    call TimerStart(pt.getTimer(), 0.03, true, function UnstoppableForceMovement)
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

private function init takes nothing returns nothing
    local trigger t = CreateTrigger()

    call TriggerRegisterPlayerUnitEvent(t, pboss, EVENT_PLAYER_UNIT_SUMMON, function boolexp)
    call TriggerAddAction(t, function GroupLegionIllusions)

    set t = null
endfunction

endlibrary
