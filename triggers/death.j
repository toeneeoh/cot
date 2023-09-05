library Death requires Functions, Chaos, Order, Dungeons

globals
	timerdialog array RTimerBox
	trigger trg_Revive_Timer_done
    group despawnGroup = CreateGroup()
    effect array HeroReviveIndicator
    effect array HeroTimedLife
    boolean RESPAWN_DEBUG = false
    group StruggleWaveGroup = CreateGroup()
    group ColoWaveGroup = CreateGroup()

    integer FIRST_DROP = 0
endglobals

function RemoveCreep takes nothing returns nothing
    local integer uid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[PLAYER_NEUTRAL_AGGRESSIVE].getTimerFromHandle(GetExpiredTimer())
    local unit u2 = null
    local group ug = CreateGroup()
    local boolean valid = true

    call GroupEnumUnitsInRange(ug, pt.x, pt.y, 800., Condition(function Trig_Enemy_Of_Hostile))

    if ChaosMode and pt.agi != 1 then
        set valid = false
    endif

    if UnitData[uid][UNITDATA_COUNT] > 0 and valid then
        if FirstOfGroup(ug) == null then
            call CreateUnit(pfoe, uid, pt.x, pt.y, GetRandomInt(0,359))
        else
            set u2 = CreateUnit(pfoe, uid, pt.x, pt.y, GetRandomInt(0,359))
            call PauseUnit(u2, true)
            call UnitAddAbility(u2, 'Avul')
            call GroupAddUnit(despawnGroup, u2)
            call ShowUnit(u2, false)
            call BlzSetItemSkin(PathItem, BlzGetUnitSkin(u2))
            set bj_lastCreatedEffect = AddSpecialEffect(BlzGetItemStringField(PathItem, ITEM_SF_MODEL_USED), pt.x, pt.y)
            call BlzSetItemSkin(PathItem, BlzGetUnitSkin(WeatherUnit))
            call BlzSetSpecialEffectColorByPlayer(bj_lastCreatedEffect, pfoe)
            call BlzSetSpecialEffectColor(bj_lastCreatedEffect, 175, 175, 175)
            call BlzSetSpecialEffectAlpha(bj_lastCreatedEffect, 127)
            call BlzSetSpecialEffectScale(bj_lastCreatedEffect, BlzGetUnitRealField(u2, UNIT_RF_SCALING_VALUE))
            call BlzSetSpecialEffectYaw(bj_lastCreatedEffect, bj_DEGTORAD * GetUnitFacing(u2))
            call SaveEffectHandle(MiscHash, GetHandleId(u2), 'gost', bj_lastCreatedEffect)
        endif
    endif

    call TimerList[PLAYER_NEUTRAL_AGGRESSIVE].removePlayerTimer(pt)
    call DestroyGroup(ug)

    set ug = null
    set u2 = null
endfunction
            
function DeathHandler takes integer pid returns nothing
    local player p = Player(pid - 1)
    local real x = GetUnitX(HeroGrave[pid])
    local real y = GetUnitY(HeroGrave[pid])
    local group ug = CreateGroup()
    local unit target
    local integer i = 0

    set GodsParticipant[pid] = false

    call CleanupSummons(p)
    
    if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, x, y) then //Clear Training
        call GroupEnumUnitsInRect(ug, gg_rct_PrechaosTrainingSpawn, Condition(function isplayerAlly))
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if UnitAlive(target) and target == Hero[GetPlayerId(GetOwningPlayer(target)) + 1] then
                set i = 42
                call GroupClear(ug)
                exitwhen true
            endif
        endloop
        if i != 42 then
            call GroupEnumUnitsInRect(ug, gg_rct_PrechaosTrainingSpawn, Condition(function ishostile))
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call RemoveUnit(target)
            endloop
        endif
        
    elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, x, y) then //Clear Chaos Training
        call GroupEnumUnitsInRect(ug, gg_rct_ChaosTrainingSpawn, Condition(function isplayerAlly))
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if UnitAlive(target) and target == Hero[GetPlayerId(GetOwningPlayer(target)) + 1] then
                set i = 42
                call GroupClear(ug)
                exitwhen true
            endif
        endloop
        if i != 42 then
            call GroupEnumUnitsInRect(ug, gg_rct_ChaosTrainingSpawn, Condition(function ishostile))
            loop
                set target = FirstOfGroup(ug)
                exitwhen target == null
                call GroupRemoveUnit(ug, target)
                call RemoveUnit(target)
            endloop
        endif
        
    elseif InColo[pid] then //Colosseum
        set ColoPlayerCount = ColoPlayerCount - 1
        set InColo[pid] = false
        set udg_Fleeing[pid] = false
        call EnableItems(pid)
        call AwardGold(p, udg_GoldWon_Colo / 1.5, true)
        call SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
        call PanCameraToTimedLocForPlayer(p, TownCenter, 0)
        call ExperienceControl(pid)
        if ColoPlayerCount <= 0 then //clear colo
            call ClearColo()
        endif
            
    elseif InStruggle[pid] then //Struggle
        set udg_Struggle_Pcount = udg_Struggle_Pcount - 1
        set InStruggle[pid] = false
        set udg_Fleeing[pid] = false
        call EnableItems(pid)
        call SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map)
        call PanCameraToTimedLocForPlayer(p, TownCenter, 0)
        call ExperienceControl(pid)
        call AwardGold(p, udg_GoldWon_Struggle / 10, true)
        if udg_Struggle_Pcount <= 0 then //clear struggle
            call ClearStruggle()
        endif
            
    elseif IsUnitInGroup(Hero[pid], AzazothPlayers) then //Azazoth reset
        call GroupRemoveUnit(AzazothPlayers, Hero[pid])
        call DisplayTimedTextToForce(FORCE_PLAYING, 10.00, "|c00ff3333Azazoth: Mortal weakling, begone! Your flesh is not even worth for me to annihilate.")
        call SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
        call PanCameraToTimedLocForPlayer(p, TownCenter, 0)
        if BlzGroupGetSize(AzazothPlayers) == 0 then
            call UnitRemoveBuffsBJ(bj_REMOVEBUFFS_ALL, Boss[BOSS_AZAZOTH])
            call SetUnitLifePercentBJ(Boss[BOSS_AZAZOTH], 100)
            call SetUnitManaPercentBJ(Boss[BOSS_AZAZOTH], 100)
            set FightingAzazoth = false
            call SetUnitPosition(Boss[BOSS_AZAZOTH], GetRectCenterX(gg_rct_Azazoth_Boss_Spawn), GetRectCenterY(gg_rct_Azazoth_Boss_Spawn))
            call BlzSetUnitFacingEx(Boss[BOSS_AZAZOTH], 90.00)
        endif
    elseif IsPlayerInForce(p, NAGA_GROUP) then //Naga dungeon
        call ForceRemovePlayer(NAGA_GROUP, p)
        call EnableItems(pid)

        if CountPlayersInForceBJ(NAGA_GROUP) <= 0 then
            call PauseTimer(NAGA_TIMER)
            call TimerStart(NAGA_TIMER, 0.01, false, function NAGA_TIMER_END)
            loop
                set target = FirstOfGroup(NAGA_ENEMIES)
                exitwhen target == null
                call GroupRemoveUnit(NAGA_ENEMIES, target)
                call RemoveUnit(target)
            endloop
        endif
    endif
    
    call DestroyGroup(ug)

    set ug = null
    set target = null
    set p = null
endfunction
    
function HeroGraveExpire takes nothing returns nothing
    local player p = Player(0)
    local integer pid = 1
    local Item itm
    local integer i
    local real heal
    local real cost
    local string message = ""
    local PlayerTimer pt
    
    loop
        if pid > 8 then
            set p = null
            return
        endif
        exitwhen GetExpiredTimer() == HeroGraveTimer[pid]
        set p = Player(pid)
        set pid = pid + 1
    endloop

    call BlzSetSpecialEffectScale(HeroTimedLife[pid], 0)
    call DestroyEffect(HeroTimedLife[pid])

    set itm = GetResurrectionItem(pid, false)

    if IsUnitHidden(HeroGrave[pid]) == false then
        if ResurrectionRevival[pid] > 0 then //hp res
            set heal = 20 + 10 * GetUnitAbilityLevel(Hero[ResurrectionRevival[pid]], 'A048')
            call RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), heal, heal)
        elseif ReincarnationRevival[pid] then //pr passive
            call RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), 100, 100)
            call BlzStartUnitAbilityCooldown(Hero[pid], REINCARNATION.id, 300.)
        elseif itm != 0 then //reincarnation item
            set itm.charge = itm.charges - 1
            set heal = ItemData[itm.id][ITEM_ABILITY] * 0.01
            
            if ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == 'Anrv' and itm.charges <= 0 then //remove perishable resurrections
                call itm.destroy()
            endif
            
            call RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), heal, heal)
        elseif udg_Hardcore[pid] then //hardcore death
            call DisplayTextToPlayer(p, 0, 0, "You have died on Hardcore mode, you cannot revive.")
            call DeathHandler(pid)

            call PlayerCleanup(p)
        else //softcore death
            call ChargeNetworth(p, 0, 0.02, 50 * GetHeroLevel(Hero[pid]), "Dying has cost you")
            set pt = TimerList[pid].addTimer(pid)
            set pt.tag = 'dead'
            set RTimerBox[pid] = CreateTimerDialog(pt.timer)
            call TimerDialogSetTitle(RTimerBox[pid], User.fromIndex(pid - 1).nameColored)
            call TimerDialogDisplay(RTimerBox[pid], true)
            call TimerStart(pt.timer, IMinBJ(IMaxBJ(GetUnitLevel(Hero[pid]) - 10, 0), 30), false, function onRevive)
            call DeathHandler(pid)
        endif

        //cleanup
        set ReincarnationRevival[pid] = false
        set ResurrectionRevival[pid] = 0
        call UnitRemoveAbility(HeroGrave[pid], 'A042')
        call UnitRemoveAbility(HeroGrave[pid], 'A044')
        call UnitRemoveAbility(HeroGrave[pid], 'A045')

        call SetUnitPosition(HeroGrave[pid], 30000, 30000)
        call ShowUnit(HeroGrave[pid], false)
    endif
    
    set p = null
endfunction

function SpawnGrave takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local Item itm = GetResurrectionItem(pid, false)
    local real scale = 0
    
    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\RaiseSkeletonWarrior\\RaiseSkeleton.mdl", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid])))
    call SetUnitVertexColor(HeroGrave[pid], 175, 175, 175, 255)
    if GetHeroLevel(Hero[pid]) > 1 then
        call SuspendHeroXP(HeroGrave[pid], false)
        call SetHeroLevelBJ(HeroGrave[pid], GetHeroLevel(Hero[pid]), false)
        call SuspendHeroXP(HeroGrave[pid], true)
    endif
    call BlzSetHeroProperName(HeroGrave[pid], GetHeroProperName(Hero[pid]))
    call Fade(HeroGrave[pid], 1., true)
    if GetLocalPlayer() == Player(pid - 1) then
        call ClearSelection()
        call SelectUnit(HeroGrave[pid], true)
    endif
    
    if itm != 0 then
        call UnitAddAbility(HeroGrave[pid], 'A042')
    endif
    
    if ReincarnationRevival[pid] then
        call UnitAddAbility(HeroGrave[pid], 'A044')
    endif
    
    if itm != 0 or ReincarnationRevival[pid] then
        set HeroReviveIndicator[pid] = AddSpecialEffect("UI\\Feedback\\Target\\Target.mdx", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]))
        
        if GetLocalPlayer() == Player(pid - 1) then
            set scale = 15
        endif
        
        call BlzSetSpecialEffectTimeScale(HeroReviveIndicator[pid], 0)
        call BlzSetSpecialEffectScale(HeroReviveIndicator[pid], scale)
        call BlzSetSpecialEffectZ(HeroReviveIndicator[pid], BlzGetLocalSpecialEffectZ(HeroReviveIndicator[pid]) - 100)
        call DestroyEffectTimed(HeroReviveIndicator[pid], 12.5)
    endif

    set HeroTimedLife[pid] = AddSpecialEffect("war3mapImported\\Progressbar.mdl", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]))
    call BlzSetSpecialEffectZ(HeroTimedLife[pid], BlzGetUnitZ(HeroGrave[pid]) + 200.)
    call BlzSetSpecialEffectColorByPlayer(HeroTimedLife[pid], Player(pid - 1))
    call BlzPlaySpecialEffectWithTimeScale(HeroTimedLife[pid], ANIM_TYPE_BIRTH, 0.099)
    call BlzSetSpecialEffectScale(HeroTimedLife[pid], 1.25)

    call TimerStart(HeroGraveTimer[pid], 12.5, false, null)
    
    if sniperstance[pid] then //Reset Tri-Rocket
        set sniperstance[pid] = false
        call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 0, 6.)
        call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 1, 6.)
        call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 2, 6.)
        call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 3, 6.)
        call BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 4, 6.)
    endif
endfunction

function RewardXPGold takes unit u, unit u2, boolean awardGold returns nothing
    local integer i = 0
    local unit target
    local integer uid = GetUnitTypeId(u)
    local integer pid2 = GetPlayerId(GetOwningPlayer(u2)) + 1
    local real expbase = udg_Experience_Table[GetUnitLevel(u)] / 700.
    local real maingold = 0
    local real teamgold = 0
    local integer herocount
    local integer size = 0
    local group xpgroup = CreateGroup()
    local string s = ""
    local player p
    local User U = User.first

    if awardGold then
        set maingold = udg_RewardGold[GetUnitLevel(u)] * GetRandomReal(0.8, 1.2) 
    endif
    
    //boss bounty
	if IsUnitType(u, UNIT_TYPE_HERO) == true then
        set expbase = expbase * 15
        set maingold = expbase * 87.5
		if HardMode > 0 then
			set expbase = R2I(expbase * 1.3)
			set maingold = maingold * 1.3
		endif
	endif

    //nearby allies
    loop
        exitwhen U == User.NULL
        if IsUnitInRange(Hero[U.id], u, 1800.00) and UnitAlive(Hero[U.id]) and U.id != pid2 then
            if (GetHeroLevel(Hero[U.id]) >= (GetUnitLevel(u) - 20)) and (GetHeroLevel(Hero[U.id])) >= GetUnitLevel(Hero[pid2]) - LEECH_CONSTANT then
                call GroupAddUnit(xpgroup, Hero[U.id])
            endif
        endif
        set U = U.next
    endloop
    
    //killer
    if GetHeroLevel(Hero[pid2]) >= (GetUnitLevel(u) - 20) then
        call GroupAddUnit(xpgroup, Hero[pid2])
    endif
    
	set herocount = BlzGroupGetSize(xpgroup)
    
    if herocount > 0 then
        set expbase = expbase * (1.2 / herocount)
        set teamgold = maingold * (1. / herocount)
    endif
    
	loop
		set target = FirstOfGroup(xpgroup)
        exitwhen target == null
        call GroupRemoveUnit(xpgroup, target)
        set p = GetOwningPlayer(target)
        
        set udg_XP = R2I(expbase * udg_XP_Rate[GetConvertedPlayerId(p)])

        if maingold > 0 then
            if herocount > 1 then
                set i = AwardGold(p, teamgold, false)
                if GetLocalPlayer() == p then
                    set s = kgold(i)
                endif
                if BlzGroupGetSize(xpgroup) == 0 then
                    call DoFloatingTextUnit(s, u, 1.5, 75, -100, 8.5, 255, 255, 0, 0)
                endif
            else
                set i = AwardGold(p, maingold, false)
                call DoFloatingTextUnit(kgold(i), u, 1.5, 75, -100, 8.5, 255, 255, 0, 0)
            endif
        endif

        call SetHeroXP(target, GetHeroXP(target) + udg_XP, true)
        call ExperienceControl(GetPlayerId(p) + 1)
        call DoFloatingTextUnit("+" + I2S(udg_XP) + " XP", target, 2, 80, 0, 9.5, 204, 0, 204, 0)
	endloop
    
    call DestroyGroup(xpgroup)
    
    set target = null
    set xpgroup = null
    set p = null
endfunction

function ReviveGods takes nothing returns nothing
    local group ug = CreateGroup()
    local unit target
    local integer i = 0
    local integer i2 = BOSS_HATE

    call GroupEnumUnitsInRect(ug, gg_rct_Gods_Vision, function isplayerunit)
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        call SetUnitPositionLoc(target, TownCenter)
        if target == Hero[GetPlayerId(GetOwningPlayer(target)) + 1] then
            set GodsParticipant[GetPlayerId(GetOwningPlayer(target)) + 1] = false
            call SetCameraBoundsRectForPlayerEx(GetOwningPlayer(target), gg_rct_Main_Map_Vision)
            call PanCameraToTimedLocForPlayer(GetOwningPlayer(target), TownCenter, 0)
        endif
    endloop
    
    call RemoveUnit(powercrystal)
    
    set Boss[BOSS_LIFE] = CreateUnitAtLoc(pboss, BossID[BOSS_LIFE], BossLoc[BOSS_LIFE], 225)

    call PauseUnit(Boss[BOSS_LIFE], true)
    call ShowUnit(Boss[BOSS_LIFE], false)

    set Boss[BOSS_HATE] = CreateUnitAtLoc(pboss, 'E00B', BossLoc[BOSS_HATE], 225)
    set Boss[BOSS_LOVE] = CreateUnitAtLoc(pboss, 'E00D', BossLoc[BOSS_LOVE], 225)
    set Boss[BOSS_KNOWLEDGE] = CreateUnitAtLoc(pboss, 'E00C', BossLoc[BOSS_KNOWLEDGE], 225)
    
    loop //give back items
        exitwhen i2 > BOSS_KNOWLEDGE
        loop
            exitwhen i > 5
            call UnitAddItem(Boss[i2], Item.create(BossItemType[i2 * 6 + i], 30000., 30000., 0).obj)
            set i = i + 1
        endloop
        call SetHeroLevel(Boss[i2], BossLevel[i2], false)
        if HardMode > 0 then //reapply hardmode
            call SetHeroStr(Boss[i2], GetHeroStr(Boss[i2], true) * 2, true)
            call BlzSetUnitBaseDamage(Boss[i2], BlzGetUnitBaseDamage(Boss[i2], 0) * 2 + 1, 0)
        endif
        set i2 = i2 + 1
        set i = 0
    endloop
    
    set DeadGods = 0
    
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
endfunction

function BossRespawn takes nothing returns nothing
    local PlayerTimer pt = TimerList[BOSS_ID].getTimerFromHandle(GetExpiredTimer())
    local integer uid = pt.agi
    local integer i = 0
    local integer i2 = 0
    local group ug = CreateGroup()
    local Item itm

    //find boss index
    loop
        exitwhen BossID[i] == uid or i > BOSS_TOTAL
        set i = i + 1
    endloop

    if i <= BOSS_TOTAL then
        if uid == BossID[BOSS_LIFE] then //revive gods
            call ReviveGods()
            call DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00" + BossName[i] + " have revived.|r")
        else
            if uid == 'H040' or uid == 'H04R' then //death knight / legion
                loop
                    call RemoveLocation(BossLoc[i])
                    set BossLoc[i] = GetRandomLocInRect(gg_rct_Main_Map)
                    call GroupEnumUnitsInRangeOfLoc(ug, BossLoc[i], 4000., Condition(function isbase))
                    if IsTerrainWalkable(GetLocationX(BossLoc[i]), GetLocationY(BossLoc[i])) and BlzGroupGetSize(ug) == 0 and RectContainsLoc(gg_rct_Town_Boundry, BossLoc[i]) == false and RectContainsLoc(gg_rct_Top_of_Town, BossLoc[i]) == false then
                        exitwhen true
                    endif
                endloop
            endif

            set Boss[i] = CreateUnitAtLoc(pboss, uid, BossLoc[i], BossFacing[i])
            call DestroyEffect(AddSpecialEffectLoc("Abilities\\Spells\\Orc\\Reincarnation\\ReincarnationTarget.mdl", BossLoc[i]))
            set i2 = 0
            loop //give back items
                exitwhen i2 > 5
                set itm = Item.create(BossItemType[i * 6 + i2], 30000., 30000., 0)
                call UnitAddItem(Boss[i], itm.obj)
                set itm.lvl = ItemData[itm.id][ITEM_UPGRADE_MAX]
                set i2 = i2 + 1
            endloop
            call SetHeroLevel(Boss[i], BossLevel[i], false)
            if HardMode > 0 then //reapply hardmode
                call SetHeroStr(Boss[i], GetHeroStr(Boss[i],true) * 2, true)
                call BlzSetUnitBaseDamage(Boss[i], BlzGetUnitBaseDamage(Boss[i], 0) * 2 + 1, 0)
            endif
            call DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00" + BossName[i] + " has revived.|r")
        endif
    endif

    call TimerList[BOSS_ID].removePlayerTimer(pt)

    call DestroyGroup(ug)

    set ug = null
endfunction

function BossHandler takes integer uid returns nothing
    local real delay = 600. 
    local PlayerTimer pt

    if CWLoading then
        return
    endif

    if IsUnitIdType(uid, UNIT_TYPE_HERO) == false then
        set delay = 300.
    endif

    if uid == 'O02T' then
        call KillUnit(udg_Azazoth_Pre_Battle_Locust)
        call DisplayTimedTextToForce(FORCE_PLAYING, 50, "Type -flee to exit the area, or wait 60 seconds.")
        call TimerStart(NewTimer(), 60., false, function AzazothExit)
    elseif uid == 'E00B' or uid == 'E00D' or uid == 'E00C' then
        set DeadGods = DeadGods + 1
        
        if DeadGods == 3 then //spawn goddess of life
            if GodsRepeatFlag == false then
                set GodsRepeatFlag = true
                call DoTransmissionBasicsXYBJ(BossID[BOSS_LIFE], GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), GetUnitX(Boss[BOSS_LIFE]), GetUnitY(Boss[BOSS_LIFE]), null, "Goddess of Life", "This is your last chance.", 6)
            endif
        
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(Boss[BOSS_LIFE]), GetUnitY(Boss[BOSS_LIFE])))
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(Boss[BOSS_LIFE]), GetUnitY(Boss[BOSS_LIFE])))
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(Boss[BOSS_LIFE]), GetUnitY(Boss[BOSS_LIFE])))
            call ShowUnit(Boss[BOSS_LIFE], true)
            call PauseUnit(Boss[BOSS_LIFE], true)
            call UnitAddAbility(Boss[BOSS_LIFE], 'Avul')
            call UnitAddAbility(Boss[BOSS_LIFE], 'A08L') //life aura
            call TimerStart(NewTimer(), 6., false, function GoddessOfLife)
        endif

        return
    elseif uid == BossID[BOSS_LIFE] then
        set DeadGods = 4
        call DisplayTimedTextToForce(FORCE_PLAYING, 10, "You may now -flee if you wish.")
        call TimerStart(NewTimer(), 6., false, function PowerCrystal)
    elseif BANISH_FLAG and (uid == BossID[BOSS_DEATH_KNIGHT] or uid == BossID[BOSS_LEGION]) then
        //banish death knight / legion
        return
    endif

    set pt = TimerList[BOSS_ID].addTimer(BOSS_ID)
    set pt.agi = uid
    set pt.tag = 'boss'

    set delay = delay * BossDelay

    if RESPAWN_DEBUG then
        set delay = 5.
    endif
    
    call TimerStart(pt.timer, delay, false, function BossRespawn)
endfunction

function onDeath takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local unit u2 = GetKillingUnit()
    local real x = GetUnitX(u)
    local real y = GetUnitY(u)
    local integer uid = GetUnitTypeId(u)
    local player p = GetOwningPlayer(u)
    local player p2 = GetOwningPlayer(u2)
    local integer pid = GetPlayerId(p) + 1
    local integer kpid = GetPlayerId(p2) + 1
    local integer rand = GetRandomInt(0, 99)
    local group ug = CreateGroup()
    local integer i = 0
    local integer i2 = 0
    local integer UnitType = 0
    local item itm = null
    local unit target = null
    local boolean dropflag = false
    local boolean spawnflag = false
    local boolean goldflag = false
    local boolean xpflag = false
    local boolean trainingflag = false
    local User U = User.first
    local PlayerTimer pt

    //hero skills
    loop
        exitwhen U == User.NULL
        //dark savior soul steal
        if IsEnemy(pid) and IsUnitInRange(Hero[U.id], u, 1000. * LBOOST[U.id]) and UnitAlive(Hero[U.id]) and GetUnitAbilityLevel(Hero[U.id], 'A08Z') > 0 then
            call HP(Hero[U.id], BlzGetUnitMaxHP(Hero[U.id]) * 0.04)
            call MP(Hero[U.id], BlzGetUnitMaxMana(Hero[U.id]) * 0.04)
        endif
        set U = U.next
    endloop

    //determine flags based on area
    if IsEnemy(pid) and IsUnitEnemy(u, p2) then //Gold & XP
        if RectContainsCoords(gg_rct_Training_Chaos, x, y) then
            set trainingflag = true
            set goldflag = true
            set xpflag = true
            call RemoveUnit(u)
        elseif RectContainsCoords(gg_rct_Training_Prechaos, x, y) then
            set trainingflag = true
            set goldflag = true
            set xpflag = true
            call RemoveUnit(u)
        elseif IsUnitInGroup(u, ColoWaveGroup) then //Colo 
            set goldflag = false
            set xpflag = true
            call GroupRemoveUnit(ColoWaveGroup, u)

            set udg_GoldWon_Colo = udg_GoldWon_Colo + R2I(udg_RewardGold[GetUnitLevel(u)] / udg_Gold_Mod[ColoPlayerCount])
            set udg_Colosseum_Monster_Amount = udg_Colosseum_Monster_Amount - 1
            
            call RemoveUnitTimed(u, 1)
            call SetTextTagText(ColoText, "Gold won: " + I2S((udg_GoldWon_Colo)), 10 * 0.023 / 10)
            if BlzGroupGetSize(ColoWaveGroup) == 0 then
                call TimerStart(NewTimer(), 3., false, function AdvanceColo)
            endif
        elseif IsUnitInGroup(u, StruggleWaveGroup) then //struggle enemies
            set goldflag = true
            set xpflag = true
            call GroupRemoveUnit(StruggleWaveGroup, u)

            set udg_GoldWon_Struggle= udg_GoldWon_Struggle + R2I(udg_RewardGold[GetUnitLevel(u)]*.65 *udg_Gold_Mod[udg_Struggle_Pcount])

            call RemoveUnitTimed(u, 1)
            call SetTextTagText(StruggleText,"Gold won: " +I2S(udg_GoldWon_Struggle),0.023)
            if (udg_Struggle_WaveUCN == 0) and BlzGroupGetSize(StruggleWaveGroup) == 0 then
                call TimerStart(NewTimer(), 3., false, function AdvanceStruggle)
            endif
        elseif IsUnitInGroup(u, NAGA_ENEMIES) then //naga dungeon
            call GroupRemoveUnit(NAGA_ENEMIES, u)
            
            if BlzGroupGetSize(NAGA_ENEMIES) <= 0 then
                if NAGA_FLOOR < 3 then
                    set nagachest = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h002', -23000, -3750, 270)
                    set nagatp = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'n00O', -21894, -4667, 270)
                    call MoveForce(NAGA_GROUP, -24000, -4700, gg_rct_Naga_Dungeon_Reward_Vision)
                else //naga boss
                    set nagachest = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h002', -22141, -10500, 0)
                    set nagatp = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'n00O', -20865, -10500, 270)
                    call DisplayTextToForce(NAGA_GROUP, "You have vanquished the Ancient Nagas!")
                    call StartSound(bj_questCompletedSound)
                    call PauseTimer(NAGA_TIMER)
                    call TimerDialogDisplay(NAGA_TIMER_DISPLAY, false)
                    if not timerflag then //time restriction
                        call Item.create('I0NN', x, y, 0.) //token
                        if NAGA_PLAYERS > 3 and GetRandomInt(0, 99) < 50 then
                            call Item.create('I0NN', x, y, 0.)
                        endif
                    endif
                    set timerflag = false
                    loop
                        exitwhen i > 7
                        if IsPlayerInForce(Player(i), NAGA_GROUP) then
                            set udg_XP = R2I(udg_Experience_Table[500] / 700. * udg_XP_Rate[i + 1])
                            call SetHeroXP(Hero[i + 1], GetHeroXP(Hero[i + 1]) + udg_XP, true)
                            call ExperienceControl(i + 1)
                            call DoFloatingTextUnit("+" + I2S(udg_XP) + " XP", Hero[i + 1], 3.1, 80, 0, 12, 204, 0, 204, 0)
                            call EnableItems(i + 1)
                        endif
                        set i = i + 1
                    endloop
                endif
                call WaygateSetDestination(nagatp, -27637, -7440)
                call WaygateActivate(nagatp, true)
            endif
        elseif uid == 'h04S' then //power crystal
            set PathtoGodsisOpen = false
            set powercrystal = null
            call BeginChaos() //chaos
        else
            set dropflag = true
            set spawnflag = true
            set goldflag = true
            set xpflag = true
        endif
    endif

    if IsUnitIllusion(u) then
        set dropflag = false
        set spawnflag = false
        set goldflag = false
        set xpflag = false
    endif

    if xpflag then
        call RewardXPGold(u, u2, goldflag)
    endif
    
    //========================
    // Item Drops / Rewards
    //========================

    if dropflag and not trainingflag then
        set UnitType = DropTable.getType(uid)
        set i = IsBoss(UnitType)

        //special cases
        //forest corruption
        if UnitType == 'N00M' then
            call Item.create('I03X', x, y, 600.) //corrupted essence
        endif

        if i >= 0 then
            //TODO dont bit flip if boss count exceeds 31
            if BlzBitAnd(FIRST_DROP, POWERSOF2[i]) == 0 then
                set FIRST_DROP = FIRST_DROP + POWERSOF2[i]
                call BossDrop(UnitType, DropTable.Rates[UnitType] + 25, x, y)
            else
                call BossDrop(UnitType, DropTable.Rates[UnitType], x, y)
            endif

            call AwardCrystals(UnitType, x, y)
        else
            if rand < DropTable.Rates.integer[UnitType] then
                call Item.create(DropTable.pickItem(UnitType), x, y, 600.)
            endif

            //iron golem ore
            //chaotic ore

            if p == pfoe then
                set rand = GetRandomInt(0, 99)

                if GetUnitLevel(u) > 45 and GetUnitLevel(u) < 85 and rand < (0.05 * GetUnitLevel(u)) then
                    call Item.create('I02Q', GetUnitX(u), GetUnitY(u), 600.)
                elseif GetUnitLevel(u) > 265 and GetUnitLevel(u) < 305 and rand < (0.02 * GetUnitLevel(u)) then
                    call Item.create('I04Z', GetUnitX(u), GetUnitY(u), 600.)
                endif
            endif
        endif
    endif

    //========================
    // Quests
    //========================
    
    if UnitType > 0 and KillQuest[UnitType][KILLQUEST_STATUS] == 1 and GetHeroLevel(Hero[kpid]) <= KillQuest[UnitType][KILLQUEST_MAX] + LEECH_CONSTANT then
		set KillQuest[UnitType][KILLQUEST_COUNT] = KillQuest[UnitType][KILLQUEST_COUNT] + 1
		call DoFloatingTextUnit(KillQuest[UnitType].string[KILLQUEST_NAME] + " " + I2S(KillQuest[UnitType][KILLQUEST_COUNT]) + "/" + I2S(KillQuest[UnitType][KILLQUEST_GOAL]), u, 3.1 ,80, 90, 9, 125, 200, 200, 0)

		if KillQuest[UnitType][KILLQUEST_COUNT] >= KillQuest[UnitType][KILLQUEST_GOAL] then
			set KillQuest[UnitType][KILLQUEST_STATUS] = 2
            set KillQuest[UnitType][KILLQUEST_LAST] = uid
			call DisplayTimedTextToForce(FORCE_PLAYING, 12, KillQuest[UnitType].string[KILLQUEST_NAME] + " quest completed, talk to the Huntsman for your reward.")
		endif
	endif
    
    //the horde
    if IsQuestDiscovered(udg_Defeat_The_Horde_Quest) and IsQuestCompleted(udg_Defeat_The_Horde_Quest) == false and (uid == 'o01I' or uid == 'o008') then //Defeat the Horde
        call GroupEnumUnitsOfPlayer(ug, pboss, Filter(function isOrc))

        if BlzGroupGetSize(ug) == 0 and UnitAlive(gg_unit_N01N_0050) and GetUnitAbilityLevel(gg_unit_N01N_0050, 'Avul') > 0 then
            call UnitRemoveAbility(gg_unit_N01N_0050, 'Avul')
            if RectContainsUnit(gg_rct_Main_Map, gg_unit_N01N_0050) == false then
                call SetUnitPosition(gg_unit_N01N_0050, 14650, -15300)
            endif
            call DoTransmissionBasicsXYBJ(GetUnitTypeId(gg_unit_N01N_0050), GetPlayerColor(pboss), GetUnitX(gg_unit_N01N_0050), GetUnitY(gg_unit_N01N_0050), null, "Kroresh Foretooth", "You dare slaughter my men? Damn you!", 5)
        endif
        
        call GroupClear(ug)
    endif
    
    //kroresh
    if u == gg_unit_N01N_0050 then
        call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_COMPLETED, "|cffffcc00OPTIONAL QUEST COMPLETE|r\nThe Horde")
        call QuestSetCompleted(udg_Defeat_The_Horde_Quest, true)
        set udg_TalkToMe20 = AddSpecialEffectTarget("Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl",gg_unit_n02Q_0382,"overhead")
    
    //key quest
    elseif u == Boss[BOSS_GODSLAYER] and not ChaosMode and IsUnitHidden(gg_unit_n0A1_0164) then //arkaden
        call SetUnitAnimation(gg_unit_n0A1_0164, "birth")
        call ShowUnit(gg_unit_n0A1_0164, true)
        call DoTransmissionBasicsXYBJ(GetUnitTypeId(gg_unit_n0A1_0164), GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), GetUnitX(gg_unit_n0A1_0164), GetUnitY(gg_unit_n0A1_0164), null, "Angel", "Halt! Before proceeding you must bring me the 3 keys to unlock the seal and face the gods in their domain.", 7.5)
    
    //zeknen
    elseif u == gg_unit_O01A_0372 then
        call DoTransmissionBasicsXYBJ(BossID[BOSS_LIFE], GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), GetUnitX(Boss[BOSS_LIFE]), GetUnitY(Boss[BOSS_LIFE]), null, "Goddess of Life", "You are foolish to challenge us in our realm. Prepare yourself.", 7.5)
        
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(Boss[BOSS_HATE]), GetUnitY(Boss[BOSS_HATE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(Boss[BOSS_HATE]), GetUnitY(Boss[BOSS_HATE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(Boss[BOSS_HATE]), GetUnitY(Boss[BOSS_HATE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(Boss[BOSS_LOVE]), GetUnitY(Boss[BOSS_LOVE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(Boss[BOSS_LOVE]), GetUnitY(Boss[BOSS_LOVE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(Boss[BOSS_LOVE]), GetUnitY(Boss[BOSS_LOVE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(Boss[BOSS_KNOWLEDGE]), GetUnitY(Boss[BOSS_KNOWLEDGE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(Boss[BOSS_KNOWLEDGE]), GetUnitY(Boss[BOSS_KNOWLEDGE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(Boss[BOSS_KNOWLEDGE]), GetUnitY(Boss[BOSS_KNOWLEDGE])))
        call ShowUnit(Boss[BOSS_HATE], true)
        call ShowUnit(Boss[BOSS_LOVE], true)
        call ShowUnit(Boss[BOSS_KNOWLEDGE], true)
        call PauseUnit(Boss[BOSS_HATE], true)
        call PauseUnit(Boss[BOSS_LOVE], true)
        call PauseUnit(Boss[BOSS_KNOWLEDGE], true)
        call UnitAddAbility(Boss[BOSS_HATE], 'Avul')
        call UnitAddAbility(Boss[BOSS_LOVE], 'Avul')
        call UnitAddAbility(Boss[BOSS_KNOWLEDGE], 'Avul')
        call TimerStart(NewTimer(), 7., false, function SpawnGods)
    endif
    
    //========================
    //Homes
    //========================
    
    if u == mybase[pid] then
        if u2 != null then
            if GetPlayerId(p2) > 7 then
                call DisplayTimedTextToForce(FORCE_PLAYING, 45, User(pid - 1).nameColored + "'s base was destroyed by " + GetUnitName(u2) + ".")
            else
                call DisplayTimedTextToForce(FORCE_PLAYING, 45, User(pid - 1).nameColored + "'s base was destroyed by " + GetPlayerName(p2) + ".")
            endif
        else
            call DisplayTimedTextToForce(FORCE_PLAYING, 45, User(pid - 1).nameColored + "'s base has been destroyed.")
        endif

        set urhome[pid] = 0
        set mybase[pid] = null
		if destroyBaseFlag[pid] then
            set destroyBaseFlag[pid] = false
        else
            call DisplayTextToPlayer(p, 0, 0, "|cffff0000You must build another base within 2 minutes or be defeated. If you are defeated you will lose your character and be unable to save. If you think you are unable to build another base for some reason, then save now.")
            set pt = TimerList[pid].addTimer(pid)
            set pt.tag = 'bdie'

            call TimerStart(pt.timer, 120., false, function BaseDead)
            call DestroyTimerDialog(udg_Timer_Window_TUD[pid])
            set udg_Timer_Window_TUD[pid] = CreateTimerDialog(pt.timer)
            call TimerDialogSetTitle(udg_Timer_Window_TUD[pid], "Defeat In")
            call TimerDialogDisplay(udg_Timer_Window_TUD[pid], false)
            if p == GetLocalPlayer() then
                call TimerDialogDisplay(udg_Timer_Window_TUD[pid], true)
            endif
        endif
        call GroupEnumUnitsOfPlayer(ug, p, Condition(function nothero))

        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target) 
            call SetUnitExploded(target, true)
            call KillUnit(target)
        endloop
        
        //reset unit limits
        set workerCount[pid] = 0
        set smallwispCount[pid] = 0
        set largewispCount[pid] = 0
        set warriorCount[pid] = 0
        set rangerCount[pid] = 0
        call SetPlayerTechResearched(p, 'R013', 1)
        call SetPlayerTechResearched(p, 'R014', 1)
        call SetPlayerTechResearched(p, 'R015', 1)
        call SetPlayerTechResearched(p, 'R016', 1)
        call SetPlayerTechResearched(p, 'R017', 1)

        call ExperienceControl(pid)
        
        
    //========================
    //Other
    //========================
    
    //unit limits
    elseif uid == 'h01P' or uid == 'h03Y' or uid == 'h04B' or uid == 'n09E' or uid == 'n00Q' or uid == 'n023' or uid == 'n09F' or uid == 'h010' or uid == 'h04U' or uid == 'h053' then //worker
        set workerCount[pid] = workerCount[pid] - 1
        call SetPlayerTechResearched(p, 'R013', 1)
    elseif uid == 'e00J' or uid == 'e000' or uid == 'e00H' or uid == 'e00K' or uid == 'e006' or uid == 'e00I' or uid == 'e00T' or uid == 'e00Y' then //small wisp
        set smallwispCount[pid] = smallwispCount[pid] - 1
        call SetPlayerTechResearched(p, 'R014', 1)
    elseif uid == 'e00Z' or uid == 'e00R' or uid == 'e00Q' or uid == 'e01L' or uid == 'e01E' or uid == 'e010' then //large wisp
        set largewispCount[pid] = largewispCount[pid] - 1
        call SetPlayerTechResearched(p, 'R015', 1)
    elseif uid == 'h00S' or uid == 'h017' or uid == 'h00I' or uid == 'h016' or uid == 'nwlg' or uid == 'h004' or uid == 'h04V' or uid == 'o02P' then //warrior
        set warriorCount[pid] = warriorCount[pid] - 1
        call SetPlayerTechResearched(p, 'R016', 1)
    elseif uid == 'n00A' or uid == 'n014' or uid == 'n009' or uid == 'n00D' or uid == 'n002' or uid == 'h005' or uid == 'o02Q' then //ranger
        set rangerCount[pid] = rangerCount[pid] - 1
        call SetPlayerTechResearched(p, 'R017', 1)
    elseif uid == forgottenTypes[0] or uid == forgottenTypes[1] or uid == forgottenTypes[2] or uid == forgottenTypes[3] or uid == forgottenTypes[4] then 
        set forgottenCount = forgottenCount - 1
        
    //========================
    //Hero Death
    //========================
        
    elseif u == Hero[pid] then

        set udg_DashDistance[pid] = 0

        //pvp death
        if GetUnitArena(u) > 0 then //PVP DEATH
            call RevivePlayer(pid, x, y, 1, 1)
            call UnitRemoveBuffs(u, true, true)
            call DisplayTextToForce(FORCE_PLAYING, User.fromIndex(pid - 1).nameColored + " has been slain by " + User.fromIndex(kpid - 1).nameColored + "!")
            call UnitAddAbility(u, 'Avul')
            call SetUnitAnimation(u, "death")
            call PauseUnit(u, true)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", u2, "origin"))
            call ArenaDeath(u, u2, GetUnitArena(u))
        else
            //grave
            call UnitRemoveAbility(Hero[pid], 'BEme') //remove meta
            call TimerStart(NewTimerEx(pid), 1.5, false, function SpawnGrave)
            call ShowUnit(HeroGrave[pid], true)
            call SetUnitVertexColor(HeroGrave[pid], 175, 175, 175, 0)
            if IsTerrainWalkable(x, y) then
                call SetUnitPosition(HeroGrave[pid], x, y)
            else
                call SetUnitPosition(HeroGrave[pid], TERRAIN_X, TERRAIN_Y)
            endif
        endif
            
        //phoenix ranger reincarnation
        if BlzGetUnitAbilityCooldownRemaining(u, REINCARNATION.id) <= 0 and GetUnitAbilityLevel(u, REINCARNATION.id) > 0 then
            set ReincarnationRevival[pid] = true
        endif
    
        //town paladin
        if pallyENRAGE and u2 == gg_unit_H01T_0259 then
            call PaladinEnrage(false)
        endif
        
    //========================
    //Enemy Respawns
    //========================

    elseif IsBoss(uid) != -1 and p == pboss and IsUnitIllusion(u) == false then 
        set i = 0
        loop
            exitwhen BossID[i] == uid or BossID[i] == uid or i > BOSS_TOTAL
            set i = i + 1
        endloop

        //add up player boss damage
        set i2 = 0
        set U = User.first
        loop
            exitwhen U == User.NULL
            set i2 = i2 + BossDamage[BOSS_TOTAL * i + U.id]
            set U = U.next
        endloop

        set U = User.first
        //print percentage contribution
        loop
            exitwhen U == User.NULL
            if BossDamage[BOSS_TOTAL * i + U.id] >= 1. then
                call DisplayTimedTextToForce(FORCE_PLAYING, 20., U.nameColored + " contributed |cffffcc00" + R2S(BossDamage[BOSS_TOTAL * i + U.id] * 100. / RMaxBJ(i2 * 1., 1.)) + "%|r damage to " + GetUnitName(u) + ".")
            endif
            set U = U.next
        endloop

        call RemoveUnitTimed(u, 6.)
        call BossHandler(uid)

        //reset boss damage recorded
        set i2 = 0
        loop
            exitwhen i2 > PLAYER_CAP
            set BossDamage[BOSS_TOTAL * i + i2] = 0
            set i2 = i2 + 1
        endloop

    elseif IsCreep(u) and spawnflag then //Creep Respawn
        set pt = TimerList[PLAYER_NEUTRAL_AGGRESSIVE].addTimer(uid)
        set pt.x = x
        set pt.y = y
        set pt.agi = 0
        if ChaosMode then
            set pt.agi = 1
        endif
        call TimerStart(pt.timer, 20., false, function RemoveCreep)
        call RemoveUnitTimed(u, 30.0)
    endif
    
    call DestroyGroup(ug)

    set u = null
    set u2 = null
    set p = null
    set p2 = null
    set itm = null
    set ug = null
    set target = null
endfunction

//===========================================================================
function DeathInit takes nothing returns nothing
    local integer i = 0
    local trigger death = CreateTrigger()
    local trigger grave = CreateTrigger()
    local User u = User.first
    
    loop
        exitwhen u == User.NULL
        set i = GetPlayerId(u.toPlayer()) + 1
        set HeroGraveTimer[i] = CreateTimer()
        call TriggerRegisterPlayerUnitEvent(death, Player(i - 1), EVENT_PLAYER_UNIT_DEATH, null)
        call TriggerRegisterTimerExpireEvent(grave, HeroGraveTimer[i])
        set u = u.next
    endloop
    
    call TriggerRegisterPlayerUnitEvent(death, Player(PLAYER_TOWN), EVENT_PLAYER_UNIT_DEATH, null)
    call TriggerRegisterPlayerUnitEvent(death, pboss, EVENT_PLAYER_UNIT_DEATH, null)
    
    call TriggerRegisterPlayerUnitEvent(death, pfoe, EVENT_PLAYER_UNIT_DEATH, null)
    
	call TriggerAddAction(death, function onDeath)
    call TriggerAddAction(grave, function HeroGraveExpire)

    set death = null
    set grave = null
endfunction

endlibrary
