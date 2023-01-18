library Death requires Functions, Chaos, Order, Dungeons

globals
	timerdialog array RTimerBox
	trigger trg_Revive_Timer_done
    group despawnGroup = CreateGroup()
    effect array HeroReviveIndicator
    unit array HeroTimedLife
    boolean RESPAWN_DEBUG = false
    group StruggleWaveGroup = CreateGroup()
    group ColoWaveGroup = CreateGroup()
    boolean array firstTimeDrop
endglobals

function RemoveCreep takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer uid = GetTimerData(t)
    local real x = LoadReal(MiscHash, GetHandleId(t), 11)
    local real y = LoadReal(MiscHash, GetHandleId(t), 12)
    local unit u2
    local group ug = CreateGroup()
    local boolean valid = false

    call GroupEnumUnitsInRange(ug, x, y, 800., Condition(function Trig_Enemy_Of_Hostile))

    if udg_Chaos_World_On then
        if UnitData[uid][StringHash("chaos")] > 0 then
            set valid = true
        endif
    else
        if UnitData[uid][StringHash("count")] > 0 then
            set valid = true
        endif
    endif

    if valid then
        if FirstOfGroup(ug) == null then
            call CreateUnit(pfoe, uid, x, y, GetRandomInt(0,359))
        else
            set u2 = CreateUnit(pfoe, uid, x, y, GetRandomInt(0,359))
            call PauseUnit(u2, true)
            call UnitAddAbility(u2, 'Avul')
            call GroupAddUnit(despawnGroup, u2)
            call ShowUnit(u2, false)
            call BlzSetItemSkin(PathItem, BlzGetUnitSkin(u2))
            set bj_lastCreatedEffect = AddSpecialEffect(BlzGetItemStringField(PathItem, ITEM_SF_MODEL_USED), x, y)
            call BlzSetSpecialEffectColorByPlayer(bj_lastCreatedEffect, pfoe)
            call BlzSetSpecialEffectColor(bj_lastCreatedEffect, 175, 175, 175)
            call BlzSetSpecialEffectAlpha(bj_lastCreatedEffect, 127)
            call BlzSetSpecialEffectScale(bj_lastCreatedEffect, BlzGetUnitRealField(u2, UNIT_RF_SCALING_VALUE))
            call BlzSetSpecialEffectYaw(bj_lastCreatedEffect, bj_DEGTORAD * GetUnitFacing(u2))
            call SaveEffectHandle(MiscHash, GetHandleId(u2), 'gost', bj_lastCreatedEffect)
        endif
    endif

    call RemoveSavedReal(MiscHash, GetHandleId(t), 11)
    call RemoveSavedReal(MiscHash, GetHandleId(t), 12)
    call ReleaseTimer(t)
    call DestroyGroup(ug)

    set ug = null
    set u2 = null
    set t = null
endfunction
            
function DeathHandler takes integer pid returns nothing
    local player p = Player(pid - 1)
    local real x = GetUnitX(HeroGrave[pid])
    local real y = GetUnitY(HeroGrave[pid])
    local group ug = CreateGroup()
    local unit target
    local integer i = 0

    set GodsParticipant[pid] = false

    call CleanupGods()
    call CleanupSummons(p)
    
    if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, x, y) then //Clear Training
        call GroupEnumUnitsInRect(ug, gg_rct_PrechaosTrainingSpawn, Condition(function isplayerAlly))
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            if GetWidgetLife(target) >= 0.406 and target == Hero[GetPlayerId(GetOwningPlayer(target)) + 1] then
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
            if GetWidgetLife(target) >= 0.406 and target == Hero[GetPlayerId(GetOwningPlayer(target)) + 1] then
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
        call SetCameraBoundsRectForPlayerEx( p, gg_rct_Main_Map )
        call PanCameraToTimedLocForPlayer( p, TownCenter, 0 )
        call ExperienceControl(pid)
        call AwardGold(p, udg_GoldWon_Struggle / 10, true)
        if udg_Struggle_Pcount <= 0 then //clear struggle
            call ClearStruggle()
        endif
            
    elseif IsUnitInGroup(Hero[pid], AzazothPlayers) then //Azazoth reset
        call GroupRemoveUnit(AzazothPlayers, Hero[pid])
        call DisplayTimedTextToForce(FORCE_PLAYING, 10.00, "TRIGSTR_27632")
        call SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
        call PanCameraToTimedLocForPlayer(p, TownCenter, 0)
        if BlzGroupGetSize(AzazothPlayers) == 0 then
            call UnitRemoveBuffsBJ(bj_REMOVEBUFFS_ALL, ChaosBoss[BOSS_AZAZOTH])
            call SetUnitLifePercentBJ(ChaosBoss[BOSS_AZAZOTH], 100)
            call SetUnitManaPercentBJ(ChaosBoss[BOSS_AZAZOTH], 100)
            set FightingAzazoth = false
            call SetUnitPosition(ChaosBoss[BOSS_AZAZOTH], GetRectCenterX(gg_rct_Azazoth_Spawn_AGD), GetRectCenterY(gg_rct_Azazoth_Spawn_AGD))
            call BlzSetUnitFacingEx(ChaosBoss[BOSS_AZAZOTH], 90.00)
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
    local item itm
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

    if HeroTimedLife[pid] != null then
        call RecycleDummy(HeroTimedLife[pid])
        set HeroTimedLife[pid] = null
    endif

    set itm = GetResurrectionItem(pid, false)

    if IsUnitHidden(HeroGrave[pid]) == false then
        if ResurrectionRevival[pid] > 0 then //hp res
            set heal = 20 + 10 * GetUnitAbilityLevel(Hero[ResurrectionRevival[pid]], 'A048')
            call RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), heal, heal)
            set ResurrectionCD[ResurrectionRevival[pid]] = 600 - 100 * GetUnitAbilityLevel(Hero[ResurrectionRevival[pid]], 'A048')
        elseif ReincarnationRevival[pid] then //pr passive
            call RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), 100, 100)
            call BlzUnitHideAbility(Hero[pid], 'A04A', true)
            call UnitDisableAbility(Hero[pid], 'A047', false)

            call IssueImmediateOrder(Hero[pid], "avatar")
            set ReincarnationPRCD[pid] = 299
        elseif itm != null then //reincarnation item
            call SetItemCharges(itm, GetItemCharges(itm) - 1)
            set heal = ItemData[GetItemTypeId(itm)][StringHash("res")] * 0.01
            
            if ItemData[GetItemTypeId(itm)][StringHash("recharge")] == 0 and GetItemCharges(itm) == 0 then //remove perishable resurrections
                call UnitRemoveItem(Hero[pid], itm)
                call RemoveItem(itm)
            endif
            
            call RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), heal, heal)
        elseif udg_Hardcore[pid] then //hardcore death
            call DisplayTextToPlayer(p, 0, 0, "TRIGSTR_292")
            call DeathHandler(pid)

            call SharedRepick(p)
        else //softcore death
            call ChargeNetworth(p, 0, 0.02, 50 * GetHeroLevel(Hero[pid]), "Dying has cost you")
            set pt = TimerList[pid].addTimer(pid)
            set pt.tag = 'dead'
            set RTimerBox[pid] = CreateTimerDialog(pt.getTimer())
            call TimerDialogSetTitle(RTimerBox[pid], User.fromIndex(pid - 1).nameColored)
            call TimerDialogDisplay(RTimerBox[pid], true)
            call TimerStart(pt.getTimer(), IMinBJ(IMaxBJ(GetUnitLevel(Hero[pid]) - 10, 0), 30), false, function onRevive)
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
    
    set itm = null
    set p = null
endfunction

function SpawnGrave takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local item itm = GetResurrectionItem(pid, false)
    local real scale = 0
    
    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\RaiseSkeletonWarrior\\RaiseSkeleton.mdl", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid])))
    call SetUnitVertexColor(HeroGrave[pid], 175, 175, 175, 255)
    if GetHeroLevel(Hero[pid]) > 1 then
        call SuspendHeroXP(HeroGrave[pid], false)
        call SetHeroLevelBJ(HeroGrave[pid], GetHeroLevel(Hero[pid]), false)
        call SuspendHeroXP(HeroGrave[pid], true)
    endif
    call BlzSetHeroProperName(HeroGrave[pid], GetHeroProperName(Hero[pid]))
    call Fade(HeroGrave[pid], 33, 0.03, -1)
    if GetLocalPlayer() == Player(pid - 1) then
        call ClearSelection()
        call SelectUnit(HeroGrave[pid], true)
    endif
    
    if itm != null then
        call UnitAddAbility(HeroGrave[pid], 'A042')
    endif
    
    if ReincarnationRevival[pid] then
        call UnitAddAbility(HeroGrave[pid], 'A044')
    endif
    
    if itm != null or ReincarnationRevival[pid] then
        set HeroReviveIndicator[pid] = AddSpecialEffect("UI\\Feedback\\Target\\Target.mdx", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]))
        
        if GetLocalPlayer() == Player(pid - 1) then
            set scale = 15
        endif
        
        call BlzSetSpecialEffectTimeScale(HeroReviveIndicator[pid], 0)
        call BlzSetSpecialEffectScale(HeroReviveIndicator[pid], scale)
        call BlzSetSpecialEffectZ(HeroReviveIndicator[pid], BlzGetLocalSpecialEffectZ(HeroReviveIndicator[pid]) - 100)
        call DestroyEffectTimed(HeroReviveIndicator[pid], 12.5)
    endif

    set HeroTimedLife[pid] = GetDummy(GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), 0, 0, 0) 
    call BlzSetUnitSkin(HeroTimedLife[pid], 'h00H')
    call SetUnitFlyHeight(HeroTimedLife[pid], 200., 0.)
    call SetUnitTimeScale(HeroTimedLife[pid], 0.099)
    call SetUnitAnimation(HeroTimedLife[pid], "birth")
    call SetUnitColor(HeroTimedLife[pid], GetPlayerColor(Player(pid - 1)))

    call TimerStart(HeroGraveTimer[pid], 12.5, false, null)
    
    if sniperstance[pid] then //Reset Tri-Rocket
        set sniperstance[pid] = false
        call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 0, 6.)
        call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 1, 6.)
        call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 2, 6.)
        call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 3, 6.)
        call BlzSetUnitAbilityCooldown(Hero[pid], 'A06I', 4, 6.)

        call UpdateTooltips()
    endif
    
    set itm = null
endfunction

function AssignGoldXp takes unit u, unit u2 returns nothing
    local integer i = 0
    local unit target
    local integer uid = GetUnitTypeId(u)
    local integer pid2 = GetPlayerId(GetOwningPlayer(u2)) + 1
    local real maingold = 0
    local real teamgold = 0
    local real expbase = 0
    local integer xplevel = 0
    local integer herocount
    local integer pid
    local integer size = 0
    local group xpgroup = CreateGroup()
    local string s = ""
    local player p
    local User U = User.first
    
	if IsUnitType(u, UNIT_TYPE_HERO) == true then
		loop
			exitwhen i>udg_PermanentInteger[12]
			if BossUnit[i]==uid then
				set maingold = BossGold[i] *GetRandomReal(0.8, 1.2)
				set xplevel = BossXplvl[i]
				exitwhen true
			endif
			set i = i + 1
		endloop
		if HardMode > 0 then
			set xplevel = R2I(xplevel * 1.3)
			set maingold = maingold * 2
		endif
	else
		loop
			exitwhen i>udg_PermanentInteger[6]
			if udg_RewardUnits[i]==uid then
				set maingold = udg_RewardGold[GetUnitLevel(u)] * GetRandomReal(0.8, 1.2)
				exitwhen true
			endif
			set i = i + 1
		endloop
	endif
    
	set xplevel = IMaxBJ(xplevel, GetUnitLevel(u))
	if xplevel > 1200 then
		set expbase = xplevel * xplevel / 280.
	else
		set expbase = udg_Experience_Table[xplevel] / 700.
	endif

    //nearby allies
    loop
        exitwhen U == User.NULL
        set pid = GetPlayerId(U.toPlayer()) + 1
        //dark savior soul steal
        if IsUnitInRange(Hero[pid], u, 1000.00) and GetWidgetLife(Hero[pid]) >= 0.406 and GetUnitAbilityLevel(Hero[pid], 'A08Z') > 0 then
            call HP(Hero[pid], BlzGetUnitMaxHP(Hero[pid]) * 0.04)
        endif
        if IsUnitInRange(Hero[pid], u, 1800.00) and GetWidgetLife(Hero[pid]) >= 0.406 and pid != pid2 then
            if (GetHeroLevel(Hero[pid]) >= (GetUnitLevel(u) - 20)) and (GetHeroLevel(Hero[pid])) >= GetUnitLevel(Hero[pid2]) - LEECH_CONSTANT then
                call GroupAddUnit(xpgroup, Hero[pid])
            endif
        endif
        set U = U.next
    endloop
    
    //killer
    if GetHeroLevel(Hero[pid2]) >= (GetUnitLevel(u) - 20) then
        call GroupAddUnit(xpgroup, Hero[pid2])
    endif
    
	set herocount = BlzGroupGetSize(xpgroup)
    
    if herocount > 1 then
		set expbase = expbase * (1.5 / herocount)
        set teamgold = maingold * (1. / herocount)
    else
        set expbase = expbase * 1.2
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
    local integer i2 = 13

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
            call EnterWeather(target)
        endif
    endloop
    
    call RemoveUnit(powercrystal)
    
    set PreChaosBoss[BOSS_LIFE] = CreateUnitAtLoc(pboss, PreChaosBossID[BOSS_LIFE], PreChaosBossLoc[12], 225)

    call PauseUnit(PreChaosBoss[BOSS_LIFE], true)
    call ShowUnit(PreChaosBoss[BOSS_LIFE], false)

    set PreChaosBoss[BOSS_HATE] = CreateUnitAtLoc(pboss, 'E00B', PreChaosBossLoc[13], 225)
    set PreChaosBoss[BOSS_LOVE] = CreateUnitAtLoc(pboss, 'E00D', PreChaosBossLoc[14], 225)
    set PreChaosBoss[BOSS_KNOWLEDGE] = CreateUnitAtLoc(pboss, 'E00C', PreChaosBossLoc[15], 225)
    
    loop //give back items
        exitwhen i2 > 16
        loop
            exitwhen i > 5
            call UnitAddItemById(PreChaosBoss[i2], BossItemType[i2 * 6 + i])
            set i = i + 1
        endloop
        call SetHeroLevel(PreChaosBoss[i2], BossLevel[i2], false)
        if HardMode > 0 then //reapply hardmode
            call SetHeroStr(PreChaosBoss[i2], GetHeroStr(PreChaosBoss[i2],true) * 2, true)
            call BlzSetUnitBaseDamage(PreChaosBoss[i2], BlzGetUnitBaseDamage(PreChaosBoss[i2], 0) * 2, 0)
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
    local timer t = GetExpiredTimer()
    local integer uid = GetTimerData(t)
    local integer i = 0
    local integer i2 = 0
    local boolean flag = false
    local real facing
    local group ug = CreateGroup()

    loop
        exitwhen ChaosBossID[i] == uid or i > CHAOS_BOSS_TOTAL
        set i = i + 1
    endloop

    if i > CHAOS_BOSS_TOTAL then
        set flag = true
        set i = 0
        loop
            exitwhen PreChaosBossID[i] == uid or i > BOSS_TOTAL
            set i = i + 1
        endloop
    endif

    if flag then //prechaos
        set uid = PreChaosBossID[i]
    
        if udg_Chaos_World_On then
            call ReleaseTimer(t)
            call DestroyGroup(ug)
            set ug = null
            set t = null
            return
        endif

        set facing = PreChaosBossFacing[i]
        if uid == PreChaosBossID[BOSS_LIFE] then //revive gods
            call ReviveGods()
            call DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00" + PreChaosBossName[i] + " have revived.|r")
        else
            if uid == 'H040' then //death knight
                loop
                    call RemoveLocation(PreChaosBossLoc[i])
                    set PreChaosBossLoc[i] = GetRandomLocInRect(gg_rct_Main_Map)
                    call GroupEnumUnitsInRangeOfLoc(ug, PreChaosBossLoc[i], 4000., Condition(function isbase))
                    if IsTerrainWalkable(GetLocationX(PreChaosBossLoc[i]), GetLocationY(PreChaosBossLoc[i])) and BlzGroupGetSize(ug) == 0 and RectContainsLoc(gg_rct_Town_Boundry, PreChaosBossLoc[i]) == false and RectContainsLoc(gg_rct_Top_of_Town, PreChaosBossLoc[i]) == false then
                        exitwhen true
                    endif
                endloop
            endif
            set PreChaosBoss[i] = CreateUnitAtLoc(pboss, uid, PreChaosBossLoc[i], facing)
            call DestroyEffect(AddSpecialEffectLoc("Abilities\\Spells\\Orc\\Reincarnation\\ReincarnationTarget.mdl", PreChaosBossLoc[i]))
            loop //give back items
                exitwhen i2 > 5
                call UnitAddItemById(PreChaosBoss[i], BossItemType[i * 6 + i2])
                set i2 = i2 + 1
            endloop
            call SetHeroLevel(PreChaosBoss[i], BossLevel[i], false)
            if HardMode > 0 then //reapply hardmode
                call SetHeroStr(PreChaosBoss[i], GetHeroStr(PreChaosBoss[i],true) * 2, true)
                call BlzSetUnitBaseDamage(PreChaosBoss[i], BlzGetUnitBaseDamage(PreChaosBoss[i], 0) * 2, 0)
            endif
            call DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00" + PreChaosBossName[i] + " has revived.|r")
        endif
    else //chaos
        set uid = ChaosBossID[i]
        set facing = GetRandomReal(0, 359)
        if i == BOSS_LEGION then //legion
            loop
                call RemoveLocation(ChaosBossLoc[i])
                set ChaosBossLoc[i] = GetRandomLocInRect(gg_rct_Main_Map)
                call GroupEnumUnitsInRangeOfLoc(ug, ChaosBossLoc[i], 4000., Condition(function isbase))
                if IsTerrainWalkable(GetLocationX(ChaosBossLoc[i]), GetLocationY(ChaosBossLoc[i])) and BlzGroupGetSize(ug) == 0 and RectContainsLoc(gg_rct_Town_Boundry, ChaosBossLoc[i]) == false and RectContainsLoc(gg_rct_Top_of_Town, ChaosBossLoc[i]) == false then
                    exitwhen true
                endif
            endloop
        endif
        set ChaosBoss[i] = CreateUnitAtLoc(pboss, uid, ChaosBossLoc[i], facing)
        call DestroyEffect(AddSpecialEffectLoc("Abilities\\Spells\\Orc\\Reincarnation\\ReincarnationTarget.mdl", ChaosBossLoc[i]))
        call SetHeroLevel(ChaosBoss[i], BossLevel[i], false)
        if HardMode > 0 then //reapply hardmode
            call SetHeroStr(ChaosBoss[i], GetHeroStr(ChaosBoss[i], true) * 2, true)
            call BlzSetUnitBaseDamage(ChaosBoss[i], BlzGetUnitBaseDamage(ChaosBoss[i], 0) * 2, 0)
        endif
        set i2 = 0
        loop //give items
            exitwhen ChaosBossItem[i * CHAOS_BOSS_TOTAL + i2] == 0
            call UnitAddItem(ChaosBoss[i], CreateItem(ChaosBossItem[i * CHAOS_BOSS_TOTAL + i2], 30000, 30000))
            set i2 = i2 + 1
        endloop
        call DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00" + ChaosBossName[i] + " has revived.|r")
    endif

    call DestroyGroup(ug)
    call ReleaseTimer(t)

    set t = null
    set ug = null
endfunction

function BossHandler takes integer uid returns nothing
    local real delay = 600. 

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
                call DoTransmissionBasicsXYBJ(PreChaosBossID[BOSS_LIFE], GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), GetUnitX(PreChaosBoss[BOSS_LIFE]), GetUnitY(PreChaosBoss[BOSS_LIFE]), null, "Goddess of Life", "This is your last chance.", 6 )
            endif
        
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(PreChaosBoss[BOSS_LIFE]), GetUnitY(PreChaosBoss[BOSS_LIFE])))
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(PreChaosBoss[BOSS_LIFE]), GetUnitY(PreChaosBoss[BOSS_LIFE])))
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(PreChaosBoss[BOSS_LIFE]), GetUnitY(PreChaosBoss[BOSS_LIFE])))
            call ShowUnit(PreChaosBoss[BOSS_LIFE], true)
            call PauseUnit(PreChaosBoss[BOSS_LIFE], true)
            call UnitAddAbility(PreChaosBoss[BOSS_LIFE], 'Avul')
            call UnitAddAbility(PreChaosBoss[BOSS_LIFE], 'A08L')
            call TimerStart(NewTimer(), 6., false, function GoddessOfLife)
        endif

        return
    elseif uid == PreChaosBossID[BOSS_LIFE] then
        set DeadGods = 4
        call DisplayTimedTextToForce(FORCE_PLAYING, 10, "You may now -flee if you wish.")
        call TimerStart(NewTimer(), 6., false, function PowerCrystal)
    endif

    set delay = delay * BossDelay

    if RESPAWN_DEBUG then
        set delay = 5.
    endif
    
    call TimerStart(NewTimerEx(uid), delay, false, function BossRespawn)
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
    local location loc
    local integer rand = GetRandomInt(0, 99)
    local group ug = CreateGroup()
    local integer i = 0
    local integer i2 = 0
    local integer ic = 0
    local integer myquest = 0
    local item itm
    local unit target
    local timer t
    local boolean dropflag = true
    local boolean spawnflag = true
    local boolean training = false
    local BossItemList il = BossItemList.create()

    //determine gold, xp, and spawn
    
    if IsUnitIllusion(u) then
        set dropflag = false
        set spawnflag = false
    endif

    if IsEnemy(pid) and IsUnitEnemy(u, p2) then //Gold & XP
        if RectContainsCoords(gg_rct_Training_Chaos, x, y) then
            set dropflag = false
            set spawnflag = false
            set training = true
            call RemoveUnit(u)
        elseif RectContainsCoords(gg_rct_Training_Prechaos, x, y) then
            set spawnflag = false
            set training = true
            call AssignGoldXp(u, u2)
            call RemoveUnit(u)
        elseif IsUnitInGroup(u, ColoWaveGroup) then //Colo 
            set dropflag = false
            set spawnflag = false
            call AssignGoldXp(u, u2)
            call GroupRemoveUnit(ColoWaveGroup, u)

            set udg_GoldWon_Colo = udg_GoldWon_Colo + R2I(udg_RewardGold[GetUnitLevel(u)] / udg_Gold_Mod[ColoPlayerCount])
            set udg_Colosseum_Monster_Amount = udg_Colosseum_Monster_Amount - 1
            
            call RemoveUnitTimed(u, 1)
            call SetTextTagText(ColoText, "Gold won: " + I2S(( udg_GoldWon_Colo )), 10 * 0.023 / 10 )
            if BlzGroupGetSize(ColoWaveGroup) == 0 then
                call TimerStart(NewTimer(), 3., false, function AdvanceColo)
            endif
        elseif IsUnitInGroup(u, StruggleWaveGroup) then //struggle enemies
            set dropflag = false
            set spawnflag = false
            call AssignGoldXp(u, u2)
            call GroupRemoveUnit( StruggleWaveGroup, u )

            set udg_GoldWon_Struggle= udg_GoldWon_Struggle + R2I( udg_RewardGold[GetUnitLevel(u)]*.65 *udg_Gold_Mod[udg_Struggle_Pcount] )

            call RemoveUnitTimed(u, 1)
            call SetTextTagText(StruggleText,"Gold won: " +I2S(udg_GoldWon_Struggle),0.023)
            if (udg_Struggle_WaveUCN == 0) and BlzGroupGetSize(StruggleWaveGroup) == 0 then
                call TimerStart(NewTimer(), 3., false, function AdvanceStruggle)
            endif
        elseif IsUnitInGroup(u, NAGA_ENEMIES) then //naga dungeon
            set dropflag = false
            set spawnflag = false
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
                        call CreateItemEx('I0NN', x, y, false) //token
                        if NAGA_PLAYERS > 4 and GetRandomInt(0, 99) < 50 then
                            call CreateItemEx('I0NN', x, y, false)
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
            call AssignGoldXp(u, u2)
        endif
    else
        set dropflag = false
        set spawnflag = false
    endif
    
    //========================
    //Drops
    //========================

    if dropflag then
        if uid == 'nits' or uid == 'nitt' then //troll
            set myquest = 1
            if rand < 40 then
                call il.addItem('ratc')
                call il.addItem('cnob')
                call il.addItem('gcel')
                call il.addItem('I0FJ')
                call il.addItem('rat6')
                call il.addItem('hval')
                call il.addItem('rde1')
                call il.addItem('bgst')
                call il.addItem('belv')
                call il.addItem('ciri')
                call il.addItem('rst1')
                call il.addItem('rinl')
                call il.addItem('rag1')
                call il.addItem('clsd')
                call il.addItem('rat9')
                call il.addItem('rin1')
                call il.addItem('I01X')
                call il.addItem('mcou')
                call il.addItem('prvt')
                call il.addItem('rlif')
                call il.addItem('pghe')
                call il.addItem('pgma')
                call il.addItem('crys')
                call il.addItem('evtl')
                call il.addItem('ward')
                call il.addItem('sor1')
                call il.addItem('I01Z')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif

        elseif uid == 'ntks' or uid == 'ntkw' or uid == 'ntkc' then //Tuskarr
            set myquest = 2
            if rand < 40 then
                call il.addItem('odef')
                call il.addItem('brac')
                call il.addItem('kpin')
                call il.addItem('hcun')
                call il.addItem('rhth')
                call il.addItem('ratf')
                call il.addItem('ratc')
                call il.addItem('cnob')
                call il.addItem('gcel')
                call il.addItem('hval')
                call il.addItem('rat6')
                call il.addItem('rde1')
                call il.addItem('rat9')
                call il.addItem('rin1')
                call il.addItem('I01X')
                call il.addItem('mcou')
                call il.addItem('prvt')
                call il.addItem('rlif')
                call il.addItem('ciri')
                call il.addItem('rag1')
                call il.addItem('sor2')
                call il.addItem('pghe')
                call il.addItem('pgma')
                call il.addItem('crys')
                call il.addItem('evtl')
                call il.addItem('ward')
                call il.addItem('sora')
                call il.addItem('sor1')
                call il.addItem('I03Q')
                call il.addItem('I01Z')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid == 'nnwr' or uid == 'nnws' then //Spider
            set myquest = 3
            if rand < 35 then
                call il.addItem('odef') //steel dagger
                call il.addItem('brac') //steel sword
                call il.addItem('kpin') //arcane staff
                call il.addItem('ratf') //steel lance
                call il.addItem('rhth') //long bow
                call il.addItem('hcun') //steel shield
                call il.addItem('I0FK') //mythril sword
                call il.addItem('I00F') //mythril spear
                call il.addItem('I010') //mythril dagger
                call il.addItem('ofro') //blood elven staff
                call il.addItem('I0FM') //blood elven bow
                call il.addItem('I0FL') //mythril shield
                call il.addItem('sor2') //tattered cloth
                call il.addItem('I028') //big health potion
                call il.addItem('I00D') //big mana potion
                call il.addItem('sora') //noble blade
                call il.addItem('I03Q') //horse boost

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid == 'nfpu' or uid == 'nfpe' then //polar furbolg ursa
            set myquest = 4
            if rand < 30 then
                call il.addItem('I0FG')
                call il.addItem('I0FT')
                call il.addItem('I06R')
                call il.addItem('I06T')
                call il.addItem('I034')
                call il.addItem('I028') //big health potion
                call il.addItem('I00D') //big mana potion
                call il.addItem('I02L') //great circlet

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif (uid == 'nplg') then // polar bear boss
            set myquest = 5
            if rand < 60 then
                call il.addItem('I0FO')
                call il.addItem('I035')
                call il.addItem('I07O')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif (uid == 'nmdr') then //dire mammoth
            set myquest = 5
            if (rand < 30) then
                call CreateItemEx('I0FQ', x, y, true)
            endif
        elseif uid == 'n01G' or uid == 'o01G' then // ogre,tauren
            set myquest = 6
            if rand < 25 then
                call il.addItem('I08I')
                call il.addItem('I0FE')
                call il.addItem('I07W')
                call il.addItem('I08B')
                call il.addItem('I0FD')
                call il.addItem('I08R')
                call il.addItem('I08E')
                call il.addItem('I08F')
                call il.addItem('I07Y')
                call il.addItem('I02L') //great circlet

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid == 'nubw' or uid == 'nfor' or uid == 'nfod' then //unbroken
            set myquest = 7
            if rand < 25 then
                call il.addItem('I0FS')
                call il.addItem('I0FR')
                call il.addItem('I0FY')
                call il.addItem('I01W')
                call il.addItem('I0MB')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid == 'nvdl' or uid == 'nvdw' then // Hellfire, hellhound
            set myquest = 8
            if rand < 25 then
                call il.addItem('ram4')
                call il.addItem('ram2')
                call il.addItem('horl')
                call il.addItem('srbd')
                call il.addItem('ram1')
                call il.addItem('I0MA')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid == 'n024' or uid == 'n027' or uid == 'n028' then // Centaur
            set myquest = 9
            if rand < 25 then
                call il.addItem('phlt')
                call il.addItem('dthb')
                call il.addItem('engs')
                call il.addItem('kygh')
                call il.addItem('bzbf')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid == 'n01M' or uid == 'n08M' then // magnataur,forgotten one
            set myquest = 10
            if rand < 20 then
                call il.addItem('sor9')
                call il.addItem('shcw')
                call il.addItem('sor4')
                call il.addItem('shrs')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid == 'n02P' or uid == 'n01R' then // Frost dragon, frost drake
            set myquest = 11
            if rand < 20 then
                call il.addItem('frhg')
                call il.addItem('fwss')
                call il.addItem('drph')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid == 'n099' then // Frost Elder Dragon
            set i = 11
            if rand < 40 then
                call il.addItem('frhg')
                call il.addItem('fwss')
                call il.addItem('drph')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid == 'n02L' or uid == 'n098' then // Devourers
            set myquest = 12
        elseif uid == 'nplb' then // giant bear
            if rand < 40 then
                call il.addItem('I0MC')
                call il.addItem('I0MD')
                call il.addItem('I0FB')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid == 'n01H' then // Ancient Hydra
            if not training then
                if rand < 10 then
                    call CreateItemEx('bzbe', x, y, true)
                elseif rand < 15 then
                    call CreateItemEx('I044', x, y, true)
                endif
            endif
        elseif uid== 'n034' or uid== 'n033' then //demons
            set myquest = 13
            if rand < 20 then
                call il.addItem('I073')
                call il.addItem('I075')
                call il.addItem('I06Z')
                call il.addItem('I06W')
                call il.addItem('I04T')
                call il.addItem('I06S')
                call il.addItem('I06U')
                call il.addItem('I06O')
                call il.addItem('I06Q')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid== 'n03A' or uid== 'n03B' or uid== 'n03C' then //horror
            set myquest = 14
            if rand < 20 then
                call il.addItem('I07K')
                call il.addItem('I05D')
                call il.addItem('I07E')
                call il.addItem('I07I')
                call il.addItem('I07G')
                call il.addItem('I07C')
                call il.addItem('I07A')
                call il.addItem('I07M')
                call il.addItem('I07L')
                call il.addItem('I07P')
                call il.addItem('I077')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid== 'n03F' or uid== 'n01W' then //despair
            set myquest = 15
            if rand < 20 then
                call il.addItem('I05P')
                call il.addItem('I087')
                call il.addItem('I089')
                call il.addItem('I083')
                call il.addItem('I081')
                call il.addItem('I07X')
                call il.addItem('I07V')
                call il.addItem('I07Z')
                call il.addItem('I07R')
                call il.addItem('I07T')
                call il.addItem('I05O')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid== 'n08N' or uid== 'n00W' or uid== 'n00X' then //abyssal
            set myquest = 16
            if rand < 20 then
                call il.addItem('I06C')
                call il.addItem('I06B')
                call il.addItem('I0A0')
                call il.addItem('I0A2')
                call il.addItem('I09X')
                call il.addItem('I0A5')
                call il.addItem('I09N')
                call il.addItem('I06D')
                call il.addItem('I06A')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid== 'n031' or uid== 'n030' or uid== 'n02Z' then //void
            set myquest = 17
            if rand < 20 then
                call il.addItem('I04Y')
                call il.addItem('I08C')
                call il.addItem('I08D')
                call il.addItem('I08G')
                call il.addItem('I08H')
                call il.addItem('I08J')
                call il.addItem('I055')
                call il.addItem('I08M')
                call il.addItem('I08N')
                call il.addItem('I08O')
                call il.addItem('I08S')
                call il.addItem('I08U')
                call il.addItem('I04W')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid== 'n020' or uid== 'n02J' then //nightmare
            set myquest = 18
            if rand < 20 then
                call il.addItem('I09S')
                call il.addItem('I0AB')
                call il.addItem('I09R')
                call il.addItem('I0A9')
                call il.addItem('I09V')
                call il.addItem('I0AC')
                call il.addItem('I0A7')
                call il.addItem('I09T')
                call il.addItem('I09P')
                call il.addItem('I04Z')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid== 'n03D' or uid== 'n03E' or uid== 'n03G' then //hell
            set myquest = 19
            if rand < 20 then
                call il.addItem('I097')
                call il.addItem('I05H')
                call il.addItem('I098')
                call il.addItem('I095')
                call il.addItem('I08W')
                call il.addItem('I05G')
                call il.addItem('I08Z')
                call il.addItem('I091')
                call il.addItem('I093')
                call il.addItem('I05I')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid== 'n03J' or uid== 'n01X' then //existence
            set myquest = 20
            if rand < 20 then
                call il.addItem('I09Y')
                call il.addItem('I09U')
                call il.addItem('I09W')
                call il.addItem('I09Q')
                call il.addItem('I09O')
                call il.addItem('I09M')
                call il.addItem('I09K')
                call il.addItem('I09I')
                call il.addItem('I09G')
                call il.addItem('I09E')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid== 'n03M' or uid== 'n01V' then //astral
            set myquest = 21
            if rand < 20 then
                call il.addItem('I0AL')
                call il.addItem('I0AN')
                call il.addItem('I0AA')
                call il.addItem('I0A8')
                call il.addItem('I0A6')
                call il.addItem('I0A3')
                call il.addItem('I0A1')
                call il.addItem('I0A4')
                call il.addItem('I09Z')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid== 'n026' or uid== 'n03T' then //plainswalker
            set myquest = 22
            if rand < 20 then
                call il.addItem('I0AY')
                call il.addItem('I0B0')
                call il.addItem('I0B2')
                call il.addItem('I0B3')
                call il.addItem('I0AQ')
                call il.addItem('I0AO')
                call il.addItem('I0AT')
                call il.addItem('I0AR')
                call il.addItem('I0AW')

                call CreateItemEx(il.pickItem(), x, y, true)
            endif
        elseif uid == 'n02U' then // nerubian
            call CreateItemEx('I01E', x, y, true)
        elseif uid == 'n03L' then // King of ogres
            call CreateItemEx('I02M', x, y, true)
        elseif uid == 'n02H' then // Yeti
            call CreateItemEx('I05R', x, y, true)
        elseif uid == 'H02H' then // paladin
            call il.addItem('I0F9')
            call il.addItem('I03P')
            call il.addItem('I0C0')
            call il.addItem('I0FX')

            call BossDrop(il, 1 + HardMode, 70, x, y)
        elseif uid == 'O002' then // minotaur
            call il.addItem('I03T')
            call il.addItem('I0FW')
            call il.addItem('I07U')
            call il.addItem('I076')
            call il.addItem('I078')

            call BossDrop(il, 1 + HardMode, 70, x, y)
        elseif uid == 'H020' then // lady vashj
            if rand < 20 then
                call CreateItemEx('I09F', x, y, true) // sea ward
            elseif rand < 40 then
                call CreateItemEx('I09L', x, y, true) // serpent hide boots
            endif
        elseif uid == 'H01V' then // dwarven
            call il.addItem('I079')
            call il.addItem('I07B')
            call il.addItem('I0FC')
            
            call BossDrop(il, 1 + HardMode, 70, x, y)
        elseif uid == 'H040' then // death knight
            call il.addItem('I02O')
            call il.addItem('I029')
            call il.addItem('I02C')
            call il.addItem('I02B')

            call BossDrop(il, 1 + HardMode, 90, x, y)
        elseif uid == 'U00G' then // tri fire
            call il.addItem('I0FA')
            call il.addItem('I0FU')
            call il.addItem('I03Y')

            call BossDrop(il, 1 + HardMode, 70, x, y)
        elseif uid == 'H045' then // mistic
            call il.addItem('I03U')
            call il.addItem('I0F3')
            call il.addItem('I07F')

            call BossDrop(il, 1 + HardMode, 70, x, y)
        elseif uid == 'O01B' or uid == 'U001' then // dragoon
            call il.addItem('I0EX')
            call il.addItem('I0EY')
            call il.addItem('I04N')

            call BossDrop(il, 1 + HardMode, 70, x, y)
        elseif uid == 'E00B' then // goddess of hate
            call CreateItemEx('I02Z', x, y, true) // 
        elseif uid == 'E00D' then // goddess of love
            call CreateItemEx('I030', x, y, true) // 
        elseif uid == 'E00C' then // goddess of knowledge
            call CreateItemEx('I031', x, y, true) // 
        elseif uid == PreChaosBossID[BOSS_LIFE] then // goddess of life
            call CreateItemEx('I04I', x, y, true) // 
        elseif uid == 'N038' then // Demon Prince
            call CreateItemEx('I04Q', x, y, true) //heart
            call MakeCrystals(1, HardMode, x, y)
        elseif uid == 'N017' then // Absolute Horror
            call il.addItem('I0N7')
            call il.addItem('I0N8')
            call il.addItem('I0N9')

            if firstTimeDrop[BOSS_ABSOLUTE_HORROR] == false then
                set firstTimeDrop[BOSS_ABSOLUTE_HORROR] = true
                call BossDrop(il, 2 + HardMode, 100, x, y)
            else
                call BossDrop(il, 1 + HardMode, 85, x, y)
            endif
            call MakeCrystals(2, HardMode, x, y)
        elseif uid == 'O02B' then // Slaughter
            call il.addItem('I0AE')
            call il.addItem('I04F')
            call il.addItem('I0AF')
            call il.addItem('I0AD')
            call il.addItem('I0AG')

            if firstTimeDrop[BOSS_SLAUGHTER_QUEEN] == false then
                set firstTimeDrop[BOSS_SLAUGHTER_QUEEN] = true
                call BossDrop(il, 1 + HardMode, 100, x, y)
            else
                call BossDrop(il, 1 + HardMode, 85, x, y)
            endif
            call MakeCrystals(3, HardMode, x, y)
        elseif uid == 'O02H' then // Dark Soul
            call il.addItem('I05A')

            if GetRandomInt(0, 99) < 25 then
                call il.addItem('I0AH')
            endif
            if GetRandomInt(0, 99) < 25 then
                call il.addItem('I0AP')
            endif
            if GetRandomInt(0, 99) < 25 then
                call il.addItem('I0AI')
            endif
            if rand < 10 then
                call il.addItem('I06K')
            endif

            if firstTimeDrop[BOSS_DARK_SOUL] == false then
                set firstTimeDrop[BOSS_DARK_SOUL] = true
                call BossDrop(il, 1 + HardMode, 100, x, y)
            else
                call BossDrop(il, 1 + HardMode, 70, x, y)
            endif
            call MakeCrystals(3, HardMode, x, y)
        elseif uid == 'O02I' then //Satan
            call il.addItem('I0BX')
            call il.addItem('I05J')

            if rand < 10 then
                call il.addItem('I00R')
            endif

            if firstTimeDrop[BOSS_SATAN] == false then
                set firstTimeDrop[BOSS_SATAN] = true
                call BossDrop(il, 1 + HardMode, 100, x, y)
            else
                call BossDrop(il, 1 + HardMode, 65, x, y)
            endif
            call MakeCrystals(5, HardMode, x, y)
        elseif uid == 'O02K' then // Thanatos
            call il.addItem('I04E')
            call il.addItem('I0MR')

            if rand < 10 then
                call il.addItem('I00P')
            endif

            if firstTimeDrop[BOSS_THANATOS] == false then
                set firstTimeDrop[BOSS_THANATOS] = true
                call BossDrop(il, 1 + HardMode, 100, x, y)
            else
                call BossDrop(il, 1 + HardMode, 65, x, y)
            endif
            call MakeCrystals(5, HardMode, x, y)
        elseif uid == 'H04R' then //Legion
            call il.addItem('I0B5')
            call il.addItem('I0B7')
            call il.addItem('I0B1')
            call il.addItem('I0AU')
            call il.addItem('I04L')
            call il.addItem('I0AJ')
            call il.addItem('I0AZ')
            call il.addItem('I0AS')
            call il.addItem('I0AV')
            call il.addItem('I0AX')

            if firstTimeDrop[BOSS_LEGION] == false then
                set firstTimeDrop[BOSS_LEGION] = true
                call BossDrop(il, 1 + HardMode, 80, x, y)
            else
                call BossDrop(il, 1 + HardMode, 60, x, y)
            endif
            call MakeCrystals(8, HardMode, x, y)
        elseif uid == 'O02M' then // Existence
            call il.addItem('I018')
            call il.addItem('I0BY')

            if rand < 10 then
                call il.addItem('I06I')
            endif

            if firstTimeDrop[BOSS_EXISTENCE] == false then
                set firstTimeDrop[BOSS_EXISTENCE] = true
                call BossDrop(il, 1 + HardMode, 80, x, y)
            else
                call BossDrop(il, 1 + HardMode, 60, x, y)
            endif
            call MakeCrystals(8, HardMode, x, y)
        elseif uid == 'O03G' then //Forgotten Leader
            call il.addItem('I0OB')
            call il.addItem('I0O1')
            call il.addItem('I0CH')

            if firstTimeDrop[BOSS_FORGOTTEN_LEADER] == false then
                set firstTimeDrop[BOSS_FORGOTTEN_LEADER] = true
                call BossDrop(il, 1 + HardMode, 50, x, y)
            else
                call BossDrop(il, 1 + HardMode, 30, x, y)
            endif
            call MakeCrystals(12, HardMode, x, y)
        elseif uid == 'O02T' then //Azazoth
            call il.addItem('I0BS')
            call il.addItem('I0BV')
            call il.addItem('I0BK')
            call il.addItem('I0BI')
            call il.addItem('I0BB')
            call il.addItem('I0BC')
            call il.addItem('I0BE')
            call il.addItem('I0B9')
            call il.addItem('I0BG')
            call il.addItem('I06M')

            if firstTimeDrop[BOSS_AZAZOTH] == false then
                set firstTimeDrop[BOSS_AZAZOTH] = true
                call BossDrop(il, 1 + HardMode, 80, x, y)
            else
                call BossDrop(il, 1 + HardMode, 60, x, y)
            endif
            call MakeCrystals(12, HardMode, x, y)
        endif
        
        set i = 0
        
        //iron golem ore
        //chaotic ore

        if p == pfoe then
            set rand = GetRandomInt(0, 99)

            if GetUnitLevel(u) > 45 and GetUnitLevel(u) < 85 and rand < (0.05 * GetUnitLevel(u)) then
                set itm = CreateItemEx('I02Q', GetUnitX(u), GetUnitY(u), true)
            elseif GetUnitLevel(u) > 265 and GetUnitLevel(u) < 305 and rand < (0.02 * GetUnitLevel(u)) then
                set itm = CreateItemEx('I04Z', GetUnitX(u), GetUnitY(u), true)
            endif
        endif
    endif

    call il.destroy()

    //========================
    //Quests
    //========================
    
    if myquest > 0 and udg_KillQuest_Status[myquest] == 1 and GetHeroLevel(Hero[kpid]) <= KillQuest[myquest][StringHash("Max")] + LEECH_CONSTANT then
		set KillQuest[myquest][StringHash("Count")] = KillQuest[myquest][StringHash("Count")] + 1
		call DoFloatingTextUnit(KillQuest[myquest].string[StringHash("Name")] + " " + I2S(KillQuest[myquest][StringHash("Count")]) + "/" + I2S(KillQuest[myquest][StringHash("Goal")]), u, 3.1 ,80 , 90, 9, 125, 200, 200, 0)

		if KillQuest[myquest][StringHash("Count")] >= KillQuest[myquest][StringHash("Goal")] then
			set udg_KillQuest_Status[myquest] = 2
			call DisplayTimedTextToForce(FORCE_PLAYING, 12, KillQuest[myquest].string[StringHash("Name")] + " quest completed, talk to the Huntsman for your reward.")
		endif
	endif
    
    //the horde
    if IsQuestDiscovered(udg_Defeat_The_Horde_Quest) and IsQuestCompleted(udg_Defeat_The_Horde_Quest) == false and (uid == 'o01I' or uid == 'o008') then //Defeat the Horde
        call GroupEnumUnitsOfPlayer(ug, pboss, Filter(function isOrc))

        if BlzGroupGetSize(ug) == 0 and GetWidgetLife(gg_unit_N01N_0050) >= 0.406 and GetUnitAbilityLevel(gg_unit_N01N_0050, 'Avul') > 0 then
            call UnitRemoveAbility(gg_unit_N01N_0050, 'Avul')
            if RectContainsUnit(gg_rct_Main_Map, gg_unit_N01N_0050) == false then
                call SetUnitPosition(gg_unit_N01N_0050, 14650, -15300)
            endif
            call DoTransmissionBasicsXYBJ(GetUnitTypeId(gg_unit_N01N_0050), GetPlayerColor(pboss), GetUnitX(gg_unit_N01N_0050), GetUnitY(gg_unit_N01N_0050), null, "Kroresh Foretooth", "You dare slaughter my men? Damn you!", 5 )
        endif
        
        call GroupClear(ug)
    endif
    
    //kroresh
    if u == gg_unit_N01N_0050 then
        call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_COMPLETED, "TRIGSTR_27384")
        call QuestSetCompleted(udg_Defeat_The_Horde_Quest, true)
        set udg_TalkToMe20=AddSpecialEffectTarget("Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl",gg_unit_n02Q_0382,"overhead")
    
    //key quest
    elseif u == gg_unit_H00O_0309 then //arkaden
        call CreateItemEx('I02B', x, y, true)
        if GetRandomInt(0, 99) < 50 then
            call CreateItemEx('I02C', x, y, true)
        endif
        if GetRandomInt(0, 99) < 50 then
            call CreateItemEx('I02O', x, y, true)
        endif

        call SetUnitAnimation(gg_unit_n0A1_0164, "birth")
        call ShowUnit( gg_unit_n0A1_0164, true )
        call DoTransmissionBasicsXYBJ(GetUnitTypeId(gg_unit_n0A1_0164), GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), GetUnitX(gg_unit_n0A1_0164), GetUnitY(gg_unit_n0A1_0164), null, "Angel", "Halt! Before proceeding you must bring me the 3 keys to unlock the seal and face the gods in their domain.", 7.5 )
    
    //zeknen
    elseif u == gg_unit_O01A_0372 then
        call DoTransmissionBasicsXYBJ(PreChaosBossID[BOSS_LIFE], GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), GetUnitX(PreChaosBoss[BOSS_LIFE]), GetUnitY(PreChaosBoss[BOSS_LIFE]), null, "Goddess of Life", "You are foolish to challenge us in our realm. Prepare yourself.", 7.5 )
        
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(PreChaosBoss[BOSS_HATE]), GetUnitY(PreChaosBoss[BOSS_HATE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(PreChaosBoss[BOSS_HATE]), GetUnitY(PreChaosBoss[BOSS_HATE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(PreChaosBoss[BOSS_HATE]), GetUnitY(PreChaosBoss[BOSS_HATE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(PreChaosBoss[BOSS_LOVE]), GetUnitY(PreChaosBoss[BOSS_LOVE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(PreChaosBoss[BOSS_LOVE]), GetUnitY(PreChaosBoss[BOSS_LOVE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(PreChaosBoss[BOSS_LOVE]), GetUnitY(PreChaosBoss[BOSS_LOVE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(PreChaosBoss[BOSS_KNOWLEDGE]), GetUnitY(PreChaosBoss[BOSS_KNOWLEDGE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(PreChaosBoss[BOSS_KNOWLEDGE]), GetUnitY(PreChaosBoss[BOSS_KNOWLEDGE])))
        call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(PreChaosBoss[BOSS_KNOWLEDGE]), GetUnitY(PreChaosBoss[BOSS_KNOWLEDGE])))
        call ShowUnit(PreChaosBoss[BOSS_HATE], true)
        call ShowUnit(PreChaosBoss[BOSS_LOVE], true)
        call ShowUnit(PreChaosBoss[BOSS_KNOWLEDGE], true)
        call PauseUnit(PreChaosBoss[BOSS_HATE], true)
        call PauseUnit(PreChaosBoss[BOSS_LOVE], true)
        call PauseUnit(PreChaosBoss[BOSS_KNOWLEDGE], true)
        call UnitAddAbility(PreChaosBoss[BOSS_HATE], 'Avul')
        call UnitAddAbility(PreChaosBoss[BOSS_LOVE], 'Avul')
        call UnitAddAbility(PreChaosBoss[BOSS_KNOWLEDGE], 'Avul')
        call TimerStart(NewTimer(), 7., false, function SpawnGods)
    endif
    
    set i = 0
    
    //========================
    //Homes
    //========================
    
    if u == mybase[pid] then
        if u2 != null then
            if GetPlayerId(p2) > 7 then
                call DisplayTimedTextToForce(FORCE_PLAYING, 45, GetPlayerName(p) + "'s base was destroyed by " + GetUnitName(u2) + ".")
            else
                call DisplayTimedTextToForce(FORCE_PLAYING, 45, GetPlayerName(p) + "'s base was destroyed by " + GetPlayerName(p2) + ".")
            endif
        else
            call DisplayTimedTextToForce(FORCE_PLAYING, 45, GetPlayerName(p) + "'s base has been destroyed.")
        endif

        set urhome[pid] = 0
        set mybase[pid] = null
		if destroyBaseFlag[pid] then
            set destroyBaseFlag[pid] = false
        else
            call DisplayTextToPlayer(p, 0, 0, "|cffff0000You must build another base within 2 minutes or be defeated. If you are defeated you will lose your character and be unable to save. If you think you are unable to build another base for some reason, then save now.")
            set t = NewTimerEx(pid)
            call TimerStart(t, 120.00, false, function BaseDead)
            call DestroyTimerDialog(udg_Timer_Window_TUD[pid])
            set udg_Timer_Window_TUD[pid] = CreateTimerDialog(t)
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
        call SetPlayerTechResearched(p, 'R018', 1)

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
                call SetUnitPosition(HeroGrave[pid], TerrainPathability_X, TerrainPathability_Y)
            endif
        endif
            
        //phoenix ranger reincarnation
        if ReincarnationPRCD[pid] <= 0 and GetUnitAbilityLevel(u, 'A047') > 0 then
            set ReincarnationRevival[pid] = true
        endif
    
        //town paladin
        if pallyENRAGE and u2 == gg_unit_H01T_0259 then
            call PaladinEnrage(false)
        endif
        
    //========================
    //Enemy Respawns
    //========================

    elseif IsBoss(uid) and p == pboss and IsUnitIllusion(u) == false then 
        call RemoveUnitTimed(u, 6.)
        call BossHandler(uid)

    elseif IsCreep(u) and spawnflag then //Creep Respawn
        set t = NewTimerEx(uid)
        call SaveReal(MiscHash, GetHandleId(t), 11, x)
        call SaveReal(MiscHash, GetHandleId(t), 12, y)
        call TimerStart(t, 20., false, function RemoveCreep)
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
    set t = null
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
    
    call TriggerRegisterPlayerUnitEvent(death, Player(8), EVENT_PLAYER_UNIT_DEATH, null)
    call TriggerRegisterPlayerUnitEvent(death, pboss, EVENT_PLAYER_UNIT_DEATH, null)
    
    call TriggerRegisterPlayerUnitEvent(death, pfoe, EVENT_PLAYER_UNIT_DEATH, null)
    
	call TriggerAddAction(death, function onDeath)
    call TriggerAddAction(grave, function HeroGraveExpire)

    set death = null
    set grave = null
endfunction

endlibrary
