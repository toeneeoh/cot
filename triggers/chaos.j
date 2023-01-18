library Chaos requires Functions, Bosses

globals
    boolean PathtoGodsisOpen = false
    boolean GodsEnterFlag = false
    boolean GodsRepeatFlag = false
    boolean array GodsParticipant
    unit powercrystal = null
    unit godsportal = null
    integer DeadGods = 0

    integer array BossItem
    integer array ChaosBossID
    string array ChaosBossName
    integer array ChaosBossItem
    integer forgottenCount = 0
    integer array forgottenTypes
    unit forgottenSpawner
endglobals

function OpenGodsPortal takes nothing returns nothing
    set bj_lastCreatedUnit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'n01P', -1409, -15255, 270)
    call SetUnitPathing(bj_lastCreatedUnit, false)
    call SetUnitPosition(bj_lastCreatedUnit, -1420, -15270)
    call SetUnitAnimation(bj_lastCreatedUnit, "birth")
    call UnitAddAbility(bj_lastCreatedUnit, 'Aloc')
    set godsportal = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'n01O', -1409, -15255, 270)
    call SetUnitPathing(godsportal, false)
    call SetUnitPosition(godsportal, -1445, -15260)
    set PathtoGodsisOpen = true
endfunction

function CleanupGods takes nothing returns nothing
    local integer i = 1
    
    loop
        exitwhen i > 8
        if GodsParticipant[i] then
            set i = -1
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    //heal gods
    if i != -1 then
        call SetWidgetLife(PreChaosBoss[BOSS_LIFE], BlzGetUnitMaxHP(PreChaosBoss[BOSS_LIFE]))
        call SetWidgetLife(PreChaosBoss[BOSS_HATE], BlzGetUnitMaxHP(PreChaosBoss[BOSS_HATE]))
        call SetWidgetLife(PreChaosBoss[BOSS_LOVE], BlzGetUnitMaxHP(PreChaosBoss[BOSS_LOVE]))
        call SetWidgetLife(PreChaosBoss[BOSS_KNOWLEDGE], BlzGetUnitMaxHP(PreChaosBoss[BOSS_KNOWLEDGE]))
    endif
endfunction

function PowerCrystal takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
    
    set powercrystal = CreateUnit(pfoe, 'h04S', GetRectCenterX(gg_rct_Crystal_Spawn), GetRectCenterY(gg_rct_Crystal_Spawn), bj_UNIT_FACING)
endfunction

function GoddessOfLife takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())

    call PauseUnit(PreChaosBoss[BOSS_LIFE], false)
    call UnitRemoveAbility(PreChaosBoss[BOSS_LIFE], 'Avul')
endfunction

function SpawnGods takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
    
    call PauseUnit(PreChaosBoss[BOSS_HATE], false)
    call UnitRemoveAbility(PreChaosBoss[BOSS_HATE], 'Avul')
    call PauseUnit(PreChaosBoss[BOSS_LOVE], false)
    call UnitRemoveAbility(PreChaosBoss[BOSS_LOVE], 'Avul')
    call PauseUnit(PreChaosBoss[BOSS_KNOWLEDGE], false)
    call UnitRemoveAbility(PreChaosBoss[BOSS_KNOWLEDGE], 'Avul')
endfunction

function ZeknenExpire takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
    
    call UnitRemoveAbility(gg_unit_O01A_0372, 'Avul')
    call PauseUnit(gg_unit_O01A_0372, false)
    call DoTransmissionBasicsXYBJ(GetUnitTypeId(gg_unit_O01A_0372), GetPlayerColor(pboss), GetUnitX(gg_unit_O01A_0372), GetUnitY(gg_unit_O01A_0372), null, "Zeknen", "Very well.", 4 )
endfunction

function HideItems takes nothing returns nothing
    local item itm = GetEnumItem()
    local integer itid = GetItemTypeId(itm)
	if itid != 'I04I' and itid != 'I031' and itid != 'I030' and itid != 'I02Z' and itid != 'wolg' and itm != PathItem then
        call RemoveItem(itm)
	endif
    set itm = null
endfunction

function BeginChaos takes nothing returns nothing
	local integer i = 0
    local integer i2 = 0
	local unit target
	local group ug = CreateGroup()
    local group g = CreateGroup()
	local location loc
    local item itm
    local real r
    local User u = User.first
    
    set CWLoading = true
    set udg_Chaos_World_On = true

    if powercrystal != null then
        call RemoveUnit(powercrystal)
        set powercrystal = null
        call UnitAddAbility(godsportal, 'Aloc')
    endif
    
	call DisplayTimedTextToForce(FORCE_PLAYING, 100, "|cff500707Without the Goddess of Life, unspeakable chaos walks the land and wreaks havoc on all life. Chaos spreads across the land and thus the chaotic world is born." )
	call DestroyQuest( udg_Bounty_Quest )
	call DestroyQuest( udg_Dark_Savior_Quest )
	call DestroyQuest( udg_Defeat_The_Horde_Quest )
	call DestroyQuest( udg_Evil_Shopkeeper_Quest_1 )
	call DestroyQuest( udg_Evil_Shopkeeper_Quest_2 )
	call DestroyQuest( udg_Icetroll_Quest )
	call DestroyQuest( udg_Iron_Golem_Fist_Quest )
	call DestroyQuest( udg_Key_Quest )
	call DestroyQuest( udg_Mink_Quest )
	call DestroyQuest( udg_Mist_Quest )
	call DestroyQuest( udg_Mountain_King_Quest )
	call DestroyQuest( udg_Paladin_Quest )
	call DestroyQuest( udg_Sasquatch_Quest )
	call DestroyQuest( udg_Tauren_Cheiftan_Quest )
	call DestroyQuest( udg_Trifire_Mage_Quest )
	
	call TriggerSleepAction(3.00)
    call DisplayTimedTextToForce(FORCE_PLAYING, 30, "Please be patient... the chaotic world is setting up.")
	call CinematicFadeBJ( bj_CINEFADETYPE_FADEOUT, 2.00, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0 )
	call TriggerSleepAction(3.00)
	
	// ------------------
	// remove units
	// ------------------
    
    call SetDoodadAnimation(545, -663, 30.0, 'D0CT', true, "death", false)

    call DestroyEffect(udg_TalkToMe13)
    call DestroyEffect(udg_TalkToMe20)
    call RemoveUnit( gg_unit_O01A_0372 ) //zeknen
	call RemoveUnit( gg_unit_h03A_0060 )
	call RemoveUnit( gg_unit_n01Q_0045 )
	call RemoveUnit( gg_unit_n00Z_0004 )
    call RemoveUnit( gg_unit_n0A1_0164 )
    call RemoveUnit( gg_unit_n02Q_0382 )
    call RemoveUnit( gg_unit_N01N_0050 )
    
    //show units

    call ShowUnit( gg_unit_n02A_0007, true )//
    call ShowUnit( gg_unit_n03P_0047, true )//
    call ShowUnit( gg_unit_n029_0046, true )//
    call ShowUnit( gg_unit_n02B_0049, true )//
    call ShowUnit( gg_unit_n02C_0048, true )//

    set r = GetUnitFacing(gg_unit_h036_0059)
    set loc = Location(GetUnitX(gg_unit_h036_0059), GetUnitY(gg_unit_h036_0059))
    call RemoveUnit(gg_unit_h036_0059)
    call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'h009', loc, r)
    call RemoveLocation(loc)
    set r = GetUnitFacing(gg_unit_h059_0714)
    set loc = Location(GetUnitX(gg_unit_h059_0714), GetUnitY(gg_unit_h059_0714))
    call RemoveUnit(gg_unit_h059_0714)
    call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'h05A', loc, r)
    call RemoveLocation(loc)
    set r = GetUnitFacing(gg_unit_n02A_0200)
    set loc = Location(GetUnitX(gg_unit_n02A_0200), GetUnitY(gg_unit_n02A_0200))
    call RemoveUnit(gg_unit_n02A_0200)
    call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n095', loc, r)
    call RemoveLocation(loc)
    set r = GetUnitFacing(gg_unit_n03P_0198)
    set loc = Location(GetUnitX(gg_unit_n03P_0198), GetUnitY(gg_unit_n03P_0198))
    call RemoveUnit(gg_unit_n03P_0198)
    call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n096', loc, r)
    call RemoveLocation(loc)
    set r = GetUnitFacing(gg_unit_n02C_0197)
    set loc = Location(GetUnitX(gg_unit_n02C_0197), GetUnitY(gg_unit_n02C_0197))
    call RemoveUnit(gg_unit_n02C_0197)
    call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n00F', loc, r)
    call RemoveLocation(loc)
    set r = GetUnitFacing(gg_unit_n02B_0008)
    set loc = Location(GetUnitX(gg_unit_n02B_0008), GetUnitY(gg_unit_n02B_0008))
    call RemoveUnit(gg_unit_n02B_0008)
    call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n00E', loc, r)
    call RemoveLocation(loc)
    set r = GetUnitFacing(gg_unit_n029_0199)
    set loc = Location(GetUnitX(gg_unit_n029_0199), GetUnitY(gg_unit_n029_0199))
    call RemoveUnit(gg_unit_n029_0199)
    call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n097', loc, r)
    call RemoveLocation(loc)
    set r = GetUnitFacing(gg_unit_n00Z_0004)
    set loc = Location(GetUnitX(gg_unit_n00Z_0004), GetUnitY(gg_unit_n00Z_0004))
    call RemoveUnit(gg_unit_n00Z_0004)
	call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n03H', loc, r)
    call RemoveLocation(loc)
    set r = GetUnitFacing(gg_unit_n01Q_0045)
    set loc = Location(GetUnitX(gg_unit_n01Q_0045), GetUnitY(gg_unit_n01Q_0045))
    call RemoveUnit(gg_unit_n01Q_0045)
    call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n03V', loc, r)
    call RemoveLocation(loc)

    set i = 0
	
    loop
        exitwhen i > BOSS_TOTAL
        call RemoveUnit(PreChaosBoss[i])
        call RemoveLocation(PreChaosBossLoc[i])
        set PreChaosBoss[i] = null
        set i = i + 1
    endloop

	call GroupEnumUnitsInRect(ug, bj_mapInitialPlayableArea, Condition(function ChaosTransition)) //need exception for struggle / colo
    call GroupEnumUnitsOfPlayer(g, Player(PLAYER_NEUTRAL_PASSIVE), Condition(function isvillager))
    call BlzGroupAddGroupFast(despawnGroup, ug)
    call BlzGroupAddGroupFast(g, ug)
	
	loop
		set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if target != gg_unit_H01Y_0099 then
            call RemoveUnit(target)
        endif
	endloop

    set r = GetUnitFacing(udg_PunchingBag[1])
    set loc = Location(GetUnitX(udg_PunchingBag[1]), GetUnitY(udg_PunchingBag[1]))
    call RemoveUnit(udg_PunchingBag[1])
    set udg_PunchingBag[1] = CreateUnitAtLoc(pfoe, 'h02F', loc, r)
    call RemoveLocation(loc)
    set r = GetUnitFacing(udg_PunchingBag[2])
    set loc = Location(GetUnitX(udg_PunchingBag[2]), GetUnitY(udg_PunchingBag[2]))
    call RemoveUnit(udg_PunchingBag[2])
    set udg_PunchingBag[2] = CreateUnitAtLoc(pfoe, 'h02G', loc, r)
    call RemoveLocation(loc)
    
    call CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'n0A2', 1571, -200, 180) // chaos merchant
    call CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'n01K', -12363, -1185, 0) // naga npc
    //call CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'ngol', 15957, -15953, 175) // gold mine

	// ------------------
	// remove items
	// ------------------
	
	//call EnumItemsInRect(bj_mapInitialPlayableArea, null, function HideItems)
	
	// ------------------
	// town
	// ------------------

    loop
		exitwhen u == User.NULL
            set i = GetPlayerId(u.toPlayer()) + 1
            if RectContainsCoords(gg_rct_Colosseum, GetUnitX(Hero[i]), GetUnitY(Hero[i])) == false and RectContainsCoords(gg_rct_Infinite_Struggle, GetUnitX(Hero[i]), GetUnitY(Hero[i])) == false then
                set loc = GetRectCenter(gg_rct_Town_Boundry)
                set GodsParticipant[i] = false
                call SetCameraBoundsRectForPlayerEx( u.toPlayer(), gg_rct_Main_Map_Vision )
                call SetUnitPositionLoc(Hero[i], loc)
                call PanCameraToTimedLocForPlayer( u.toPlayer(), loc, 0 )
                call RemoveLocation(loc)
                call EnterWeather(Hero[i])
            endif
		set u = u.next
	endloop
    
	set i = 1

	loop
		exitwhen i > 15
		set loc = Location(GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 300.00, GetRectMaxX(gg_rct_Town_Boundry) - 300.00), GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 300.0, GetRectMaxY(gg_rct_Town_Boundry) - 300.0))
        
		if i < 6 then
			set target = CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n036', loc, GetRandomReal(0, 360.00) )
            call IssueImmediateOrder(target, "metamorphosis")
            call UnitAddAbility(target, 'Aloc')
		elseif i < 11 then
			set target = CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n035', loc, GetRandomReal(0, 360.00) )
            call IssueImmediateOrder(target, "metamorphosis")
            call UnitAddAbility(target, 'Aloc')
		elseif i < 16 then
			set target = CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n037', loc, GetRandomReal(0, 360.00) )
            call IssueImmediateOrder(target, "metamorphosis")
            call UnitAddAbility(target, 'Aloc')
		endif
		
		call RemoveLocation(loc)
		set i = i + 1
	endloop
	
	call SetWaterBaseColorBJ( 150.00, 0.00, 0.00, 0 )
    
	set HardMode = 0
	
	// ------------------
	// bosses
	// ------------------

    set ChaosBossLoc[BOSS_DEMON_PRINCE] = GetRectCenter(gg_rct_Demon_Wiz_and_Norm_Boss) //demon prince
	set ChaosBoss[BOSS_DEMON_PRINCE] = CreateUnitAtLoc( pboss, 'N038', ChaosBossLoc[BOSS_DEMON_PRINCE], 315.00 )
    set ChaosBossID[BOSS_DEMON_PRINCE] = 'N038'
    set ChaosBossName[BOSS_DEMON_PRINCE] = "Demon Prince"
	call SetHeroLevel( ChaosBoss[BOSS_DEMON_PRINCE], 200, false )
    set BossLevel[BOSS_DEMON_PRINCE] = 200
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_DEMON_PRINCE] = 'I04R'
    
    set ChaosBossLoc[BOSS_ABSOLUTE_HORROR] = GetRectCenter(gg_rct_Absolute_Horror_Spawn) //absolute horror
	set ChaosBoss[BOSS_ABSOLUTE_HORROR] = CreateUnitAtLoc( pboss, 'N017', ChaosBossLoc[BOSS_ABSOLUTE_HORROR], 270.00 )
    set ChaosBossID[BOSS_ABSOLUTE_HORROR] = 'N017'
    set ChaosBossName[BOSS_ABSOLUTE_HORROR] = "Absolute Horror"
	call SetHeroLevel( ChaosBoss[BOSS_ABSOLUTE_HORROR], 230, false )
    set BossLevel[BOSS_ABSOLUTE_HORROR] = 230
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_ABSOLUTE_HORROR] = 'I0ND'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_ABSOLUTE_HORROR + 1] = 'I0NH'
    
	set ChaosBossLoc[BOSS_SLAUGHTER_QUEEN] = Location(-5400, -15470) //slaughter queen
	set ChaosBoss[BOSS_SLAUGHTER_QUEEN] = CreateUnitAtLoc( pboss, 'O02B', ChaosBossLoc[BOSS_SLAUGHTER_QUEEN], 135.00 )
    set ChaosBossID[BOSS_SLAUGHTER_QUEEN] = 'O02B'
    set ChaosBossName[BOSS_SLAUGHTER_QUEEN] = "Slaughter Queen"
	call SetHeroLevel( ChaosBoss[BOSS_SLAUGHTER_QUEEN], 290, false )
    set BossLevel[BOSS_SLAUGHTER_QUEEN] = 290 
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_SLAUGHTER_QUEEN] = 'I0OT'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_SLAUGHTER_QUEEN + 1] = 'I0BH'
    
	set ChaosBossLoc[BOSS_SATAN] = GetRectCenter(gg_rct_Hell_Spawn_Boss) //satan
	set ChaosBoss[BOSS_SATAN] = CreateUnitAtLoc( pboss, 'O02I', ChaosBossLoc[BOSS_SATAN], 315.00 )
    set ChaosBossID[BOSS_SATAN] = 'O02I'
    set ChaosBossName[BOSS_SATAN] = "Satan"
	call SetHeroLevel( ChaosBoss[BOSS_SATAN], 310, false )
    set BossLevel[BOSS_SATAN] = 310
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_SATAN] = 'I07N'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_SATAN + 1] = 'I0OD'
    
	set ChaosBossLoc[BOSS_DARK_SOUL] = GetRectCenter(gg_rct_Dark_Soul_Boss_Spawn) //dark soul
	set ChaosBoss[BOSS_DARK_SOUL] = CreateUnitAtLoc( pboss, 'O02H', ChaosBossLoc[BOSS_DARK_SOUL], bj_UNIT_FACING )
    set ChaosBossID[BOSS_DARK_SOUL] = 'O02H'
    set ChaosBossName[BOSS_DARK_SOUL] = "Essence of Darkness"
	call SetHeroLevel( ChaosBoss[BOSS_DARK_SOUL], 300, false )
    set BossLevel[BOSS_DARK_SOUL] = 300
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_DARK_SOUL] = 'I0EK'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_DARK_SOUL + 1] = 'I03K'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_DARK_SOUL + 2] = 'I0AH'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_DARK_SOUL + 3] = 'I0AI'
    
	set ChaosBossLoc[BOSS_LEGION] = GetRectCenter(gg_rct_To_The_Forrest) //legion
	set ChaosBoss[BOSS_LEGION] = CreateUnitAtLoc( pboss, 'H04R', ChaosBossLoc[BOSS_LEGION], bj_UNIT_FACING )
    set ChaosBossID[BOSS_LEGION] = 'H04R'
    set ChaosBossName[BOSS_LEGION] = "Legion"
	call SetHeroLevel( ChaosBoss[BOSS_LEGION], 340, false )
	call SelectHeroSkill( ChaosBoss[BOSS_LEGION], 'A0F0' )
    set BossLevel[BOSS_LEGION] = 340
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_LEGION] = 'I0IQ'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_LEGION + 1] = 'I0J6'
    
	set ChaosBossLoc[BOSS_THANATOS] = GetRandomLocInRect(gg_rct_Thanatos_Spawn) //thanatos
	set ChaosBoss[BOSS_THANATOS] = CreateUnitAtLoc( pboss, 'O02K', ChaosBossLoc[BOSS_THANATOS], bj_UNIT_FACING )
    set ChaosBossID[BOSS_THANATOS] = 'O02K'
    set ChaosBossName[BOSS_THANATOS] = "Thanatos"
	call SetHeroLevel( ChaosBoss[BOSS_THANATOS], 320, false )
    set BossLevel[BOSS_THANATOS] = 320
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_THANATOS] = 'I06H'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_THANATOS + 1] = 'I023'
    
    set ChaosBossLoc[BOSS_EXISTENCE] = GetRandomLocInRect(gg_rct_Existence_Boss) //existence
	set ChaosBoss[BOSS_EXISTENCE] = CreateUnitAtLoc( pboss, 'O02M', ChaosBossLoc[BOSS_EXISTENCE], bj_UNIT_FACING )
    set ChaosBossID[BOSS_EXISTENCE] = 'O02M'
    set ChaosBossName[BOSS_EXISTENCE] = "Pure Existence"
	call SetHeroLevel( ChaosBoss[BOSS_EXISTENCE], 340, false )
    set BossLevel[BOSS_EXISTENCE] = 340
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_EXISTENCE] = 'I09E'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_EXISTENCE + 1] = 'I09O'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_EXISTENCE + 2] = 'I0G2'

	set ChaosBossLoc[BOSS_AZAZOTH] = GetRectCenter(gg_rct_Azazoth_Spawn_AGD) //azazoth
    set ChaosBoss[BOSS_AZAZOTH] = CreateUnitAtLoc( pboss, 'O02T', ChaosBossLoc[BOSS_AZAZOTH], 270.00 )
    set ChaosBossID[BOSS_AZAZOTH] = 'O02T'
    set ChaosBossName[BOSS_AZAZOTH] = "Azazoth"
	call SetHeroLevel( ChaosBoss[BOSS_AZAZOTH], 380, false )
    set BossLevel[BOSS_AZAZOTH] = 380
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_AZAZOTH] = 'I0LV'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_AZAZOTH + 1] = 'I0KR'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_AZAZOTH + 2] = 'I0LX'
    
	set ChaosBossLoc[BOSS_FORGOTTEN_LEADER] = GetRectCenter(gg_rct_Forgotten_Leader) //forgotten leader
	set ChaosBoss[BOSS_FORGOTTEN_LEADER] = CreateUnitAtLoc( pboss, 'O03G', ChaosBossLoc[BOSS_FORGOTTEN_LEADER], 135.00 )
    set ChaosBossID[BOSS_FORGOTTEN_LEADER] = 'O03G'
    set ChaosBossName[BOSS_FORGOTTEN_LEADER] = "The Forgotten Leader"
	call SetHeroLevel( ChaosBoss[BOSS_FORGOTTEN_LEADER], 370, false )
    set BossLevel[BOSS_FORGOTTEN_LEADER] = 370
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_FORGOTTEN_LEADER] = 'I0NW'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_FORGOTTEN_LEADER + 1] = 'I0O3'
    set ChaosBossItem[CHAOS_BOSS_TOTAL * BOSS_FORGOTTEN_LEADER + 2] = 'I019'
	
	call CreateUnit( Player(PLAYER_NEUTRAL_PASSIVE), 'n04P', GetRectCenterX(gg_rct_Azazoth_Circle_Spawn), GetRectCenterY(gg_rct_Azazoth_Circle_Spawn), 270.00 )
	set udg_Azazoth_Pre_Battle_Locust = CreateUnit( Player(PLAYER_NEUTRAL_PASSIVE), 'O02U', GetRectCenterX(gg_rct_Azazoth_Circle_Spawn), GetRectCenterY(gg_rct_Azazoth_Circle_Spawn), 228.00 )
	call SetUnitVertexColorBJ( udg_Azazoth_Pre_Battle_Locust, 38.82, 66.67, 100, 50.00 )

    // ------------------
    // chaos boss items
    // ------------------
	
    set i = 0

    loop
        exitwhen i > CHAOS_BOSS_TOTAL
        set i2 = 0

        set firstTimeDrop[i] = false
        loop
            exitwhen ChaosBossItem[i * CHAOS_BOSS_TOTAL + i2] == 0 or i2 > 5
            set itm = CreateItem(ChaosBossItem[i * CHAOS_BOSS_TOTAL + i2], 30000, 30000)
            call UnitAddItem(ChaosBoss[i], itm)
            call SetUnitCreepGuard(ChaosBoss[i], true)
            set i2 = i2 + 1
        endloop

        set i = i + 1
    endloop

	// ------------------
	// chaotic enemies
	// ------------------

	set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h01M', GetRectCenterX(gg_rct_ColoBanner1), GetRectCenterY(gg_rct_ColoBanner1), bj_UNIT_FACING )
	call SetUnitPathing( target, false )
    call SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner1), GetRectCenterY(gg_rct_ColoBanner1))
    
	set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h01M', GetRectCenterX(gg_rct_ColoBanner2), GetRectCenterY(gg_rct_ColoBanner2), 90.00 )
	call SetUnitPathing( target, false )
    call SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner2), GetRectCenterY(gg_rct_ColoBanner2))
    
	set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h01M', GetRectCenterX(gg_rct_ColoBanner3), GetRectCenterY(gg_rct_ColoBanner3), 90.00 )
	call SetUnitPathing( target, false )
    call SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner3), GetRectCenterY(gg_rct_ColoBanner3))

	set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h01M', GetRectCenterX(gg_rct_ColoBanner4), GetRectCenterY(gg_rct_ColoBanner4) , bj_UNIT_FACING )
	call SetUnitPathing( target, false )
    call SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner4), GetRectCenterY(gg_rct_ColoBanner4) )
    
    call TriggerSleepAction(1.00)

	call ChaosSpawn()

    call TriggerSleepAction(1.00)

    set forgottenSpawner = CreateUnit(pboss, 'o02E', 15241, -12600, bj_UNIT_FACING)
    call SetUnitAnimation(forgottenSpawner, "Stand Work")
    call SpawnForgotten()
    call SpawnForgotten()
    call SpawnForgotten()
    call SpawnForgotten()
    call SpawnForgotten()
	
	call TriggerSleepAction(1.00)
    call ClearTextMessages()
	call CinematicFadeBJ( bj_CINEFADETYPE_FADEIN, 2.00, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0 )
    
    set CWLoading = false
    
	call DestroyGroup(ug)
    call DestroyGroup(g)

	set loc = null
	set target = null
	set ug = null
    set g = null
    set itm = null
endfunction

endlibrary
