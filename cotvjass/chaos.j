library Chaos requires Functions, Bosses

globals
    boolean PathtoGodsisOpen = false
    boolean GodsEnterFlag = false
    boolean GodsRepeatFlag = false
    boolean array GodsParticipant
    unit powercrystal = null
    unit godsportal = null
    integer DeadGods = 0

    integer forgottenCount = 0
    integer array forgottenTypes
    unit forgottenSpawner
    boolean BANISH_FLAG = false
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

function PowerCrystal takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
    
    set powercrystal = CreateUnit(pfoe, 'h04S', GetRectCenterX(gg_rct_Crystal_Spawn), GetRectCenterY(gg_rct_Crystal_Spawn), bj_UNIT_FACING)
endfunction

function GoddessOfLife takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())

    call PauseUnit(Boss[BOSS_LIFE], false)
    call UnitRemoveAbility(Boss[BOSS_LIFE], 'Avul')
endfunction

function SpawnGods takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
    
    call PauseUnit(Boss[BOSS_HATE], false)
    call UnitRemoveAbility(Boss[BOSS_HATE], 'Avul')
    call PauseUnit(Boss[BOSS_LOVE], false)
    call UnitRemoveAbility(Boss[BOSS_LOVE], 'Avul')
    call PauseUnit(Boss[BOSS_KNOWLEDGE], false)
    call UnitRemoveAbility(Boss[BOSS_KNOWLEDGE], 'Avul')
endfunction

function ZeknenExpire takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
    
    call UnitRemoveAbility(gg_unit_O01A_0372, 'Avul')
    call PauseUnit(gg_unit_O01A_0372, false)
    call DoTransmissionBasicsXYBJ(GetUnitTypeId(gg_unit_O01A_0372), GetPlayerColor(pboss), GetUnitX(gg_unit_O01A_0372), GetUnitY(gg_unit_O01A_0372), null, "Zeknen", "Very well.", 4)
endfunction

function HideItems takes nothing returns nothing
    local item itm = GetEnumItem()
    local integer itid = GetItemTypeId(itm)

	if itid != 'I04I' and itid != 'I031' and itid != 'I030' and itid != 'I02Z' and itid != 'wolg' and itm != PathItem then
        call Item[itm].destroy()
	endif

    set itm = null
endfunction

function SetupChaos takes nothing returns nothing
	local integer i = 0
    local integer i2 = 0
	local unit target
	local group ug = CreateGroup()
    local group g = CreateGroup()
    local real x = 0.
    local real y = 0.
	local location loc
    local item myItem
    local real r
    local User u = User.first
    local Item itm

    call SoundHandler("Sound\\Interface\\BattleNetWooshStereo1.flac", false, null, null)

	call DestroyQuest(udg_Bounty_Quest)
	call DestroyQuest(udg_Dark_Savior_Quest)
	call DestroyQuest(udg_Defeat_The_Horde_Quest)
	call DestroyQuest(udg_Evil_Shopkeeper_Quest_1)
	call DestroyQuest(udg_Evil_Shopkeeper_Quest_2)
	call DestroyQuest(udg_Icetroll_Quest)
	call DestroyQuest(udg_Iron_Golem_Fist_Quest)
	call DestroyQuest(udg_Key_Quest)
	call DestroyQuest(udg_Mink_Quest)
	call DestroyQuest(udg_Mist_Quest)
	call DestroyQuest(udg_Mountain_King_Quest)
	call DestroyQuest(udg_Paladin_Quest)
	call DestroyQuest(udg_Sasquatch_Quest)
	call DestroyQuest(udg_Tauren_Cheiftan_Quest)
	
	// ------------------
	// remove units
	// ------------------
    
    call SetDoodadAnimation(545, -663, 30.0, 'D0CT', true, "death", false)

    call DestroyEffect(udg_TalkToMe13)
    call DestroyEffect(udg_TalkToMe20)
    call RemoveUnit(gg_unit_O01A_0372) //zeknen
	call RemoveUnit(gg_unit_h03A_0005) //headhunter
    call RemoveUnit(gg_unit_n0A1_0164)
    call RemoveUnit(gg_unit_n02Q_0382)
    call RemoveUnit(gg_unit_N01N_0050)

    //huntsman
    set r = GetUnitFacing(gg_unit_h036_0002)
    set loc = Location(GetUnitX(gg_unit_h036_0002), GetUnitY(gg_unit_h036_0002))
	call RemoveUnit(gg_unit_h036_0002) //huntsman
    call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'h009', loc, r)

    //home salesmen
    set r = GetUnitFacing(gg_unit_n01Q_0045)
    set loc = Location(GetUnitX(gg_unit_n01Q_0045), GetUnitY(gg_unit_n01Q_0045))
	call RemoveUnit(gg_unit_n01Q_0045)
    call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n03V', loc, r)
    set r = GetUnitFacing(gg_unit_n00Z_0004)
    set loc = Location(GetUnitX(gg_unit_n00Z_0004), GetUnitY(gg_unit_n00Z_0004))
	call RemoveUnit(gg_unit_n00Z_0004)
    call CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n03H', loc, r)

    //clean up bosses
    set i = 0
	
    loop
        exitwhen i > BOSS_TOTAL
        call RemoveUnit(Boss[i])
        call RemoveLocation(BossLoc[i])
        set Boss[i] = null
        set BossID[i] = 0
        set i = i + 1
    endloop

    set BOSS_TOTAL = 9

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
    
    call CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'n0A2', 1344., 1472., 270.) // chaos merchant
    call CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'n01K', -12363, -1185, 0) // naga npc
    //call CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'ngol', 15957, -15953, 175) // gold mine
	
	// ------------------
	// town
	// ------------------

    loop
		exitwhen u == User.NULL
            set i = GetPlayerId(u.toPlayer()) + 1
            set x = GetUnitX(Hero[i])
            set y = GetUnitY(Hero[i])
            if not hselection[i] and RectContainsCoords(gg_rct_Colosseum, x, y) == false and RectContainsCoords(gg_rct_Infinite_Struggle, x, y) == false and RectContainsCoords(gg_rct_Church, x, y) == false then
                set GodsParticipant[i] = false
                call SetCameraBoundsRectForPlayerEx(u.toPlayer(), gg_rct_Main_Map_Vision)
                call SetUnitPositionLoc(Hero[i], TownCenter)
                call PanCameraToTimedForPlayer(u.toPlayer(), GetUnitX(Hero[i]), GetUnitY(Hero[i]), 0.)
            endif
		set u = u.next
	endloop
    
	set i = 1

	loop
		exitwhen i > 15
		set loc = Location(GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 300.00, GetRectMaxX(gg_rct_Town_Boundry) - 300.00), GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 300.0, GetRectMaxY(gg_rct_Town_Boundry) - 300.0))
        
		if i < 6 then
			set target = CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n036', loc, GetRandomReal(0, 360.00))
		elseif i < 11 then
			set target = CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n035', loc, GetRandomReal(0, 360.00))
		elseif i < 16 then
			set target = CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), 'n037', loc, GetRandomReal(0, 360.00))
		endif
		
		call RemoveLocation(loc)
		set i = i + 1
	endloop
	
	call SetWaterBaseColorBJ(150.00, 0.00, 0.00, 0)
    
	set HardMode = 0
    set BANISH_FLAG = false
	
	// ------------------
	// bosses
	// ------------------

    set FIRST_DROP = 0

    set BossLoc[0] = GetRectCenter(gg_rct_Demon_Prince_Boss_Spawn) //demon prince
    call SetDoodadAnimation(7810., 1203., 1000., 'D05Q', false, "death", false)
    set BossFacing[0] = 315.00
	set Boss[0] = CreateUnitAtLoc(pboss, 'N038', BossLoc[0], BossFacing[0])
    set BossID[0] = 'N038'
    set BossName[0] = "Demon Prince"
    set BossLevel[0] = 190
    set BossItemType[0] = 'I03F'
    set BossItemType[1] = 'I00X'
    set BossItemType[2] = 0
    set BossItemType[3] = 0
    set BossItemType[4] = 0
    set BossItemType[5] = 0
    set CrystalRewards[BossID[0]] = 1
    
    set BossLoc[1] = GetRectCenter(gg_rct_Absolute_Horror_Spawn) //absolute horror
    set BossFacing[1] = 270.00
	set Boss[1] = CreateUnitAtLoc(pboss, 'N017', BossLoc[1], BossFacing[1])
    set BossID[1] = 'N017'
    set BossName[1] = "Absolute Horror"
    set BossLevel[1] = 230
    set BossItemType[6] = 'I0ND'
    set BossItemType[7] = 'I0NH'
    set BossItemType[8] = 0
    set BossItemType[9] = 0
    set BossItemType[10] = 0
    set BossItemType[11] = 0
    set CrystalRewards[BossID[1]] = 2
    
	set BossLoc[2] = Location(-5400, -15470) //slaughter queen
    set BossFacing[2] = 135.00
	set Boss[2] = CreateUnitAtLoc(pboss, 'O02B', BossLoc[2], BossFacing[2])
    set BossID[2] = 'O02B'
    set BossName[2] = "Slaughter Queen"
    set BossLevel[2] = 270 
    set BossItemType[12] = 'I0AE'
    set BossItemType[13] = 'I04F'
    set BossItemType[14] = 0
    set BossItemType[15] = 0
    set BossItemType[16] = 0
    set BossItemType[17] = 0
    set CrystalRewards[BossID[2]] = 3
    
	set BossLoc[3] = GetRectCenter(gg_rct_Hell_Boss_Spawn) //satan
    set BossFacing[3] = 315.00
	set Boss[3] = CreateUnitAtLoc(pboss, 'O02I', BossLoc[3], BossFacing[3])
    set BossID[3] = 'O02I'
    set BossName[3] = "Satan"
    set BossLevel[3] = 310
    set BossItemType[18] = 'I05J'
    set BossItemType[19] = 'I0BX'
    set BossItemType[20] = 0
    set BossItemType[21] = 0
    set BossItemType[22] = 0
    set BossItemType[23] = 0
    set CrystalRewards[BossID[3]] = 5
    
	set BossLoc[4] = GetRectCenter(gg_rct_Dark_Soul_Boss_Spawn) //dark soul
    set BossFacing[4] = bj_UNIT_FACING
	set Boss[4] = CreateUnitAtLoc(pboss, 'O02H', BossLoc[4], BossFacing[4])
    set BossID[4] = 'O02H'
    set BossName[4] = "Essence of Darkness"
    set BossLevel[4] = 300
    set BossItemType[24] = 'I05A'
    set BossItemType[25] = 'I0AP'
    set BossItemType[26] = 'I0AH'
    set BossItemType[27] = 'I0AI'
    set BossItemType[28] = 0
    set BossItemType[29] = 0
    set CrystalRewards[BossID[4]] = 3
    
	set BossLoc[5] = GetRectCenter(gg_rct_To_The_Forrest) //legion
    set BossFacing[5] = bj_UNIT_FACING
	set Boss[5] = CreateUnitAtLoc(pboss, 'H04R', BossLoc[5], BossFacing[5])
    set BossID[5] = 'H04R'
    set BossName[5] = "Legion"
    set BossLevel[5] = 340
    set BossItemType[30] = 'I0AJ'
    set BossItemType[31] = 'I0B1'
    set BossItemType[32] = 'I0AU'
    set BossItemType[33] = 0
    set BossItemType[34] = 0
    set BossItemType[35] = 0
    set CrystalRewards[BossID[5]] = 8
    
	set BossLoc[6] = GetRandomLocInRect(gg_rct_Thanatos_Boss_Spawn) //thanatos
    set BossFacing[6] = bj_UNIT_FACING
	set Boss[6] = CreateUnitAtLoc(pboss, 'O02K', BossLoc[6], BossFacing[6])
    set BossID[6] = 'O02K'
    set BossName[6] = "Thanatos"
    set BossLevel[6] = 320
    set BossItemType[36] = 'I04E'
    set BossItemType[37] = 'I0MR'
    set BossItemType[38] = 0
    set BossItemType[39] = 0
    set BossItemType[40] = 0
    set BossItemType[41] = 0
    set CrystalRewards[BossID[6]] = 5
    
    set BossLoc[7] = GetRandomLocInRect(gg_rct_Existence_Boss_Spawn) //existence
    set BossFacing[7] = bj_UNIT_FACING
	set Boss[7] = CreateUnitAtLoc(pboss, 'O02M', BossLoc[7], BossFacing[7])
    set BossID[7] = 'O02M'
    set BossName[7] = "Pure Existence"
    set BossLevel[7] = 320
    set BossItemType[42] = 'I09E'
    set BossItemType[43] = 'I09O'
    set BossItemType[44] = 'I018'
    set BossItemType[45] = 'I0BY'
    set BossItemType[46] = 0
    set BossItemType[47] = 0
    set CrystalRewards[BossID[7]] = 8

	set BossLoc[8] = GetRectCenter(gg_rct_Azazoth_Boss_Spawn) //azazoth
    set BossFacing[8] = 270.00
    set Boss[8] = CreateUnitAtLoc(pboss, 'O02T', BossLoc[8], BossFacing[8])
    set BossID[8] = 'O02T'
    set BossName[8] = "Azazoth"
    set BossLevel[8] = 380
    set BossItemType[48] = 'I0BG'
    set BossItemType[49] = 'I0BI'
    set BossItemType[50] = 'I06M'
    set BossItemType[51] = 0
    set BossItemType[52] = 0
    set BossItemType[53] = 0
    set CrystalRewards[BossID[8]] = 12
    
	set BossLoc[9] = GetRectCenter(gg_rct_Forgotten_Leader_Boss_Spawn) //forgotten leader
    set BossFacing[9] = 135.00
	set Boss[9] = CreateUnitAtLoc(pboss, 'O03G', BossLoc[9], BossFacing[9])
    set BossID[9] = 'O03G'
    set BossName[9] = "The Forgotten Leader"
    set BossLevel[9] = 360
    set BossItemType[54] = 'I0O1'
    set BossItemType[55] = 'I0OB'
    set BossItemType[56] = 'I0CH'
    set BossItemType[57] = 0
    set BossItemType[58] = 0
    set BossItemType[59] = 0
    set CrystalRewards[BossID[9]] = 12
	
	call CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'n04P', GetRectCenterX(gg_rct_Azazoth_Circle_Spawn), GetRectCenterY(gg_rct_Azazoth_Circle_Spawn), 270.00)
	set udg_Azazoth_Pre_Battle_Locust = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'O02U', GetRectCenterX(gg_rct_Azazoth_Circle_Spawn), GetRectCenterY(gg_rct_Azazoth_Circle_Spawn), 228.00)
	call SetUnitVertexColorBJ(udg_Azazoth_Pre_Battle_Locust, 38.82, 66.67, 100, 50.00)

    // ------------------
    // chaos boss items
    // ------------------
	
    set i = 0

    loop
        exitwhen i > BOSS_TOTAL
        set i2 = 0

        call SetHeroLevel(Boss[i], BossLevel[i], false)
        loop
            exitwhen BossItemType[i * 6 + i2] == 0 or i2 > 5
            set BossNearbyPlayers[i] = 0
            set itm = Item.create(BossItemType[i * 6 + i2], 30000., 30000., 0)
            call UnitAddItem(Boss[i], itm.obj)
            set itm.lvl = ItemData[itm.id][ITEM_UPGRADE_MAX]
            set i2 = i2 + 1
        endloop
        call SetUnitCreepGuard(Boss[i], true)

        set i = i + 1
    endloop

	set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h01M', GetRectCenterX(gg_rct_ColoBanner1), GetRectCenterY(gg_rct_ColoBanner1), 180.00)
	call SetUnitPathing(target, false)
    call SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner1), GetRectCenterY(gg_rct_ColoBanner1))
    
	set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h01M', GetRectCenterX(gg_rct_ColoBanner2), GetRectCenterY(gg_rct_ColoBanner2), 0)
	call SetUnitPathing(target, false)
    call SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner2), GetRectCenterY(gg_rct_ColoBanner2))
    
	set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h01M', GetRectCenterX(gg_rct_ColoBanner3), GetRectCenterY(gg_rct_ColoBanner3), 180.00)
	call SetUnitPathing(target, false)
    call SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner3), GetRectCenterY(gg_rct_ColoBanner3))

	set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h01M', GetRectCenterX(gg_rct_ColoBanner4), GetRectCenterY(gg_rct_ColoBanner4), 0)
	call SetUnitPathing(target, false)
    call SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner4), GetRectCenterY(gg_rct_ColoBanner4))

	// ------------------
	// chaotic enemies
	// ------------------

	call SpawnCreeps(1)

    set forgottenSpawner = CreateUnit(pboss, 'o02E', 15100., -12650., bj_UNIT_FACING)
    call SetUnitAnimation(forgottenSpawner, "Stand Work")
    call SpawnForgotten()
    call SpawnForgotten()
    call SpawnForgotten()
    call SpawnForgotten()
    call SpawnForgotten()
	
	call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, 2.5, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
    
    set CWLoading = false
    
	call DestroyGroup(ug)
    call DestroyGroup(g)

	set loc = null
	set target = null
	set ug = null
    set g = null
endfunction

function BeginChaos takes nothing returns nothing
    //stop prechaos boss respawns
    call TimerList[BOSS_ID].stopAllTimersWithTag('boss')

    //reset legion jump timer
    call PauseTimer(wanderingTimer)
    call TimerStart(wanderingTimer, 2040. - (User.AmountPlaying * 240), true, function ShadowStepExpire)

    set CWLoading = true
    set ChaosMode = true

    if powercrystal != null then
        call RemoveUnit(powercrystal)
        set powercrystal = null
        call UnitAddAbility(godsportal, 'Aloc')
    endif
    
	call DisplayTimedTextToForce(FORCE_PLAYING, 100, "|cff800807Without the Goddess of Life, unspeakable chaos walks the land and wreaks havoc on all life. Chaos spreads across the land and thus the chaotic world is born.")
    call SoundHandler("Sound\\Interface\\GlueScreenEarthquake1.flac", false, null, null)

    call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, 3.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)

    call TimerStart(NewTimer(), 3.0, false, function SetupChaos)
endfunction

endlibrary
