library JassVariables initializer JassVariablesInit requires Functions

globals
	HashTable KillQuest
	HashTable ItemData
	HashTable UnitData
	TableArray RestrictedItems
    unit array Hero
    unit array HeroGrave
	unit array Backpack
    integer array HeroID
	integer array priceindex
	string array infostring
	location array BagLoc
    location temploc
    group tempgroup = CreateGroup()
	dialog array dChooseReward
	dialog array dUpgradeSpell
	button array SpellButton
	hashtable RewardItems = InitHashtable()
	integer array prMulti
	boolean array MultiShot
    integer array UpItem
    integer array UpDiscountItem
    integer array UpItemBecomes
    integer array UpItemCostPlat
    integer array UpItemCostArc
    integer array UpItemCostCrys
    real array UpgradeCostFactor
    integer array upPcost
    integer array upLcost
    integer array upCcost
    integer cfactor = 2
    hashtable PrestigeRank = InitHashtable()
	integer array Dmg_mod
	real array DR_mod
	integer array Str_mod
	integer array Agi_mod
	integer array Int_mod
	integer array Spl_mod
	integer array Gld_mod
	integer array Reg_mod
    string abc= "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    integer array BossUnit
	integer array BossXplvl
	integer array BossGold
    rect array shopreg
	string array restricted_string
    location array colospot
    integer foe = PLAYER_NEUTRAL_AGGRESSIVE
	integer boss = 11
	integer foeid = foe + 1
	integer bossid = boss + 1
    player pfoe = Player(PLAYER_NEUTRAL_AGGRESSIVE)
	player pboss = Player(11)
    group tg
    integer array Plevel
    integer array Plevelgap
    integer array Pstr
    integer array Pagi
    integer array Pint
    integer array Ptime
    integer array Ptimeh
    integer array TotalEvasion
    real array BoostValue
    real array DealtDmgBase
    real array DmgBase
    real array DmgTaken
    real array SpellTakenBase
    real array SpellTaken
    integer array HasShield
    unit DamageSource
    rect TempRect = Rect(-400, 13000, 400, 13800) //used for tree kill trigger
    hashtable MiscHash = InitHashtable()
    hashtable PlayerProf = InitHashtable()
    integer HardMode = 0
    boolean array BossSpellCD
    location array ChaosBossLoc
    boolean ForcedRevive = false
    leaderboard RollBoard
    integer array RollChecks
    boolean array nocd
	boolean array nocost
    boolean CWLoading = false
    integer array statpoints
    boolean array CameraLock
    integer afkInt = 1000
    timer strugglespawn = CreateTimer()
    effect array charLight
    integer array charLightId	
	integer array CustomLighting
    string array forceString
    boolean array forceSaving
    integer array HuntedLevel
    group SummonGroup = CreateGroup()
    integer array Movespeed
    integer array HealthBonus

	integer RESTRICTED_ITEMS_MAX
	integer RESTRICTED_ERROR
endglobals

function ExperienceTableInit takes nothing returns nothing
	local integer level = 1
	
	loop
		exitwhen level > 1250
		set udg_Experience_Table[level] = R2I(13 * level * Pow(1.4, level / 20.) + 10)
		set udg_RewardGold[level] = Pow(udg_Experience_Table[level], .94) / 8.
		set level = level + 1
	endloop
endfunction

function StruggleSetup takes nothing returns nothing
    set udg_Struggle_WaveN = 0
    set udg_Struggle_WaveUCN = 0
    set udg_Struggle_SpawnR[1] = gg_rct_InfiniteStruggleSpawn1
    set udg_Struggle_SpawnR[2] = gg_rct_InfiniteStruggleSpawn2
    set udg_Struggle_SpawnR[3] = gg_rct_InfiniteStruggleSpawn3
    set udg_Struggle_SpawnR[4] = gg_rct_InfiniteStruggleSpawn4
	// start setting up units
	// WaveU = Unit type of the wave
	// WaveUN = Number of units in the wave
	// WaveSR = How many units spawn per second during the wave
	set udg_Struggle_WaveU[0] = 'n03Y' //slave
	set udg_Struggle_WaveUN[0] = 140
	set udg_Struggle_Wave_SR[0] = 8
	set udg_StruggleGoldPer[0] = 10
	set udg_Struggle_WaveU[1] = 'n08Q' //lightning revenant
	set udg_Struggle_WaveUN[1] = 170
	set udg_Struggle_Wave_SR[1] = 12
	set udg_StruggleGoldPer[1] = 15
	set udg_Struggle_WaveU[2] = 'n044' //scorpion
	set udg_Struggle_WaveUN[2] = 480
	set udg_Struggle_Wave_SR[2] = 16
	set udg_StruggleGoldPer[2] = 20
	set udg_Struggle_WaveU[3] = 'n08R' //brood mother
	set udg_Struggle_WaveUN[3] = 130
	set udg_Struggle_Wave_SR[3] = 8
	set udg_StruggleGoldPer[3] = 30
	set udg_Struggle_WaveU[4] = 'n08U'
	set udg_Struggle_WaveUN[4] = 300
	set udg_Struggle_Wave_SR[4] = 12
	set udg_StruggleGoldPer[4] = 40
	set udg_Struggle_WaveU[5] = 'n04B'
	set udg_Struggle_WaveUN[5] = 300
	set udg_Struggle_Wave_SR[5] = 12
	set udg_StruggleGoldPer[5] = 40
	set udg_Struggle_WaveU[6] = 'n04C' //monter wolf 7, lvl 21
	set udg_Struggle_WaveUN[6] = 320
	set udg_Struggle_Wave_SR[6] = 16
	set udg_StruggleGoldPer[6] = 50
	set udg_Struggle_WaveU[7] = 'n08P'
	set udg_Struggle_WaveUN[7] = 300
	set udg_Struggle_Wave_SR[7] = 24
	set udg_StruggleGoldPer[7] = 50
	set udg_Struggle_WaveU[8] = 'n061'
	set udg_Struggle_WaveUN[8] = 140
	set udg_Struggle_Wave_SR[8] = 9
	set udg_StruggleGoldPer[8] = 60
	set udg_Struggle_WaveU[9] = 'n064' //green murloc
	set udg_Struggle_WaveUN[9] = 200
	set udg_Struggle_Wave_SR[9] = 12
	set udg_StruggleGoldPer[9] = 80
	set udg_Struggle_WaveU[10] = 'n04U'
	set udg_Struggle_WaveUN[10] = 100
	set udg_Struggle_Wave_SR[10] = 8
	set udg_StruggleGoldPer[10] = 140
	set udg_Struggle_WaveU[11] = 'n058'
	set udg_Struggle_WaveUN[11] = 200
	set udg_Struggle_Wave_SR[11] = 12
	set udg_StruggleGoldPer[11] = 200
	set udg_Struggle_WaveU[12] = 'n059' //blood skeleton
	set udg_Struggle_WaveUN[12] = 200
	set udg_Struggle_Wave_SR[12] = 16
	set udg_StruggleGoldPer[12] = 250
	set udg_Struggle_WaveU[13] = 'n08Y' //ogre overlord 14, lev 52
	set udg_Struggle_WaveUN[13] = 300
	set udg_Struggle_Wave_SR[13] = 16
	set udg_StruggleGoldPer[13] = 700
	set udg_Struggle_WaveU[14] = 'n066' //murlock titan
	set udg_Struggle_WaveUN[14] = 9
	set udg_Struggle_Wave_SR[14] = 3
	set udg_StruggleGoldPer[14] = 600
	set udg_Struggle_WaveU[15] = 'o03H' //tauren
	set udg_Struggle_WaveUN[15] = 120
	set udg_Struggle_Wave_SR[15] = 6
	set udg_StruggleGoldPer[15] = 800
	set udg_Struggle_WaveU[16] = 'n05X' //doom beast 17
	set udg_Struggle_WaveUN[16] = 300
	set udg_Struggle_Wave_SR[16] = 16
	set udg_StruggleGoldPer[16] = 400
	set udg_Struggle_WaveU[17] = 'n05Z' //death beast
	set udg_Struggle_WaveUN[17] = 50
	set udg_Struggle_Wave_SR[17] = 4
	set udg_StruggleGoldPer[17] = 650
	set udg_Struggle_WaveU[18] = 'n04J' //Dragon King 
	set udg_Struggle_WaveUN[18] = 16
	set udg_Struggle_Wave_SR[18] = 4
	set udg_StruggleGoldPer[18] = 1200
	set udg_Struggle_WaveU[19] = 'n066'
	set udg_Struggle_WaveUN[19] = 400
	set udg_Struggle_Wave_SR[19] = 28
	set udg_StruggleGoldPer[19] = 600
	set udg_Struggle_WaveU[20] = 'n05A' //death skeleton 21
	set udg_Struggle_WaveUN[20] = 300
	set udg_Struggle_Wave_SR[20] = 16
	set udg_StruggleGoldPer[20] = 800
	set udg_Struggle_WaveU[21] = 'n093'//nerubian empress 22
	set udg_Struggle_WaveUN[21] = 15
	set udg_Struggle_Wave_SR[21] = 3
	set udg_StruggleGoldPer[21] = 2000
	set udg_Struggle_WaveU[22] = 'n04M' //soul of lightning
	set udg_Struggle_WaveUN[22] = 70
	set udg_Struggle_Wave_SR[22] = 7
	set udg_StruggleGoldPer[22] = 700
	set udg_Struggle_WaveU[23] = 'n093' //nerubian empress
	set udg_Struggle_WaveUN[23] = 70
	set udg_Struggle_Wave_SR[23] = 6
	set udg_StruggleGoldPer[23] = 2000
	set udg_Struggle_WaveU[24] = 'n08Z' //king of ogres
	set udg_Struggle_WaveUN[24] = 40
	set udg_Struggle_Wave_SR[24] = 3
	set udg_StruggleGoldPer[24] = 2000
	set udg_Struggle_WaveU[25] = 'n04O' //soul of death
	set udg_Struggle_WaveUN[25] = 20
	set udg_Struggle_Wave_SR[25] = 4
	set udg_StruggleGoldPer[25] = 2000
	set udg_Struggle_WaveU[26] = 'n08Z' //king of ogres
	set udg_Struggle_WaveUN[26] = 160
	set udg_Struggle_Wave_SR[26] = 8
	set udg_StruggleGoldPer[26] = 4000
    //skipped enemy type makes struggle end
	set udg_Struggle_WaveU[28] = 'n04O' //soul of death
	set udg_Struggle_WaveUN[28] = 100
	set udg_Struggle_Wave_SR[28] = 12
	set udg_StruggleGoldPer[28] = 2000
	set udg_Struggle_WaveU[29] = 'n06G' //poss god
	set udg_Struggle_WaveUN[29] = 120
	set udg_Struggle_Wave_SR[29] = 10
	set udg_StruggleGoldPer[29] = 4000
	set udg_Struggle_WaveU[30] = 'n00R'
	set udg_Struggle_WaveUN[30] = 130
	set udg_Struggle_Wave_SR[30] = 6
	set udg_StruggleGoldPer[30] = 4500
	set udg_Struggle_WaveU[31] = 'n00T' //tormentress ranged
	set udg_Struggle_WaveUN[31] = 130
	set udg_Struggle_Wave_SR[31] = 6
	set udg_StruggleGoldPer[31] = 5000
	set udg_Struggle_WaveU[32] = 'n09H'
	set udg_Struggle_WaveUN[32] = 100
	set udg_Struggle_Wave_SR[32] = 6
	set udg_StruggleGoldPer[32] = 5500
	set udg_Struggle_WaveU[33] = 'n09I'
	set udg_Struggle_WaveUN[33] = 200
	set udg_Struggle_Wave_SR[33] = 10
	set udg_StruggleGoldPer[33] = 11000
	set udg_Struggle_WaveU[34] = 'n09J'
	set udg_Struggle_WaveUN[34] = 150
	set udg_Struggle_Wave_SR[34] = 10
	set udg_StruggleGoldPer[34] = 9000
	set udg_Struggle_WaveU[35] = 'n09K'
	set udg_Struggle_WaveUN[35] = 200
	set udg_Struggle_Wave_SR[35] = 10
	set udg_StruggleGoldPer[35] = 20000
	set udg_Struggle_WaveU[36] = 'n09L'
	set udg_Struggle_WaveUN[36] = 100
	set udg_Struggle_Wave_SR[36] = 5
	set udg_StruggleGoldPer[36] = 40000
	set udg_Struggle_WaveU[37] = 'n091'  //angel
	set udg_Struggle_WaveUN[37] = 10
	set udg_Struggle_Wave_SR[37] = 2
	set udg_StruggleGoldPer[37] = 30000
	set udg_Struggle_WaveU[38] = 'n09L'
	set udg_Struggle_WaveUN[38] = 100
	set udg_Struggle_Wave_SR[38] = 10
	set udg_StruggleGoldPer[38] = 40000
	set udg_Struggle_WaveU[39] = 'n091'  //angel
	set udg_Struggle_WaveUN[39] = 20
	set udg_Struggle_Wave_SR[39] = 4
	set udg_StruggleGoldPer[39] = 30000
	set udg_Struggle_WaveU[40] = 'n090'
	set udg_Struggle_WaveUN[40] = 12
	set udg_Struggle_Wave_SR[40] = 4
	set udg_StruggleGoldPer[40] = 50000 //god
	set udg_Struggle_WaveU[41] = 'n092'
	set udg_Struggle_WaveUN[41] = 10
	set udg_Struggle_Wave_SR[41] = 1
	set udg_StruggleGoldPer[41] = 300000 //omniscient
endfunction

function ColosseumSetup takes nothing returns nothing
	set colospot[1]=GetRectCenter(gg_rct_Colloseum_Monster_Spawn)
	set colospot[2]=GetRectCenter(gg_rct_Colloseum_Monster_Spawn_2)
	set colospot[3]=GetRectCenter(gg_rct_Colloseum_Monster_Spawn_3)
	set ColoCount_main[0]=4
	set ColoEnemyType_main[0]='n046'
	set ColoCount_main[1]=3
	set ColoEnemyType_main[1]='n045'
	set ColoCount_main[2]=3
	set ColoEnemyType_main[2]='n046'
	set ColoCount_sec[2]=2
	set ColoEnemyType_sec[2]='n047'
	set ColoCount_main[3]=4
	set ColoEnemyType_main[3]='n045'
	set ColoCount_sec[3]=2
	set ColoEnemyType_sec[3]='n047'
	set ColoCount_main[4]=6
	set ColoEnemyType_main[4]='n047'
	set ColoCount_main[5]=5
	set ColoEnemyType_main[5]='n045'
	set ColoCount_sec[5]=5
	set ColoEnemyType_sec[5]='n047'
	set ColoCount_main[6]=6
	set ColoEnemyType_main[6]='n047'
	set ColoCount_sec[6]=1
	set ColoEnemyType_sec[6]='n048'
	set ColoCount_main[7]=3
	set ColoEnemyType_main[7]='n048'
	set ColoCount_main[8]=11
	set ColoEnemyType_main[8]='n047'
	set ColoCount_sec[8]=2
	set ColoEnemyType_sec[8]='n048'
	set ColoCount_main[9]=8
	set ColoEnemyType_main[9]='n048'
	set ColoCount_main[10]=5
	set ColoEnemyType_main[10]='n048'
	set ColoCount_sec[10]=1
	set ColoEnemyType_sec[10]='n049'
	set ColoCount_main[11]=7
	set ColoEnemyType_main[11]='n05L'
	set ColoCount_main[12]=10
	set ColoEnemyType_main[12]='n05L'
	set ColoCount_main[13]=8
	set ColoEnemyType_main[13]='n05M'
	set ColoCount_main[14]=10
	set ColoEnemyType_main[14]='n05N'
	set ColoCount_main[15]=4
	set ColoEnemyType_main[15]='n05O'
	set ColoCount_sec[15]=3
	set ColoEnemyType_sec[15]='n05M'
	set ColoCount_main[16]=10
	set ColoEnemyType_main[16]='n05L'
	set ColoCount_main[17]=6
	set ColoEnemyType_main[17]='n05N'
	set ColoCount_sec[17]=6
	set ColoEnemyType_sec[17]='n05L'
	set ColoCount_main[18]=6
	set ColoEnemyType_main[18]='n05M'
	set ColoCount_sec[18]=6
	set ColoEnemyType_sec[18]='n05O'
	set ColoCount_main[19]=6
	set ColoEnemyType_main[19]='n05N'
	set ColoCount_sec[19]=6
	set ColoEnemyType_sec[19]='n05L'
	set ColoCount_main[20]=10
	set ColoEnemyType_main[20]='n05O'
	set ColoCount_main[21]=10
	set ColoEnemyType_main[21]='n05O'
	set ColoCount_sec[21]=1
	set ColoEnemyType_sec[21]='n05P'
	set ColoCount_main[22]=4
	set ColoEnemyType_main[22]='n049'
	set ColoCount_sec[22]=2
	set ColoEnemyType_sec[22]='n05P'
	set ColoCount_main[25]=3
	set ColoEnemyType_main[25]='n04A'
	set ColoCount_main[26]=6
	set ColoEnemyType_main[26]='n04A'
	set ColoCount_main[27]=3
	set ColoEnemyType_main[27]='n04B'
	set ColoCount_sec[27]=2
	set ColoEnemyType_sec[27]='n04A'
	set ColoCount_main[28]=8
	set ColoEnemyType_main[28]='n04B'
	set ColoCount_main[29]=10
	set ColoEnemyType_main[29]='n04A'
	set ColoCount_main[30]=4
	set ColoEnemyType_main[30]='n04C'
	set ColoCount_sec[30]=4
	set ColoEnemyType_sec[30]='n04B'
	set ColoCount_main[31]=8
	set ColoEnemyType_main[31]='n04C'
	set ColoCount_main[32]=9
	set ColoEnemyType_main[32]='n04C'
	set ColoCount_sec[32]=2
	set ColoEnemyType_sec[32]='n04D'
	set ColoCount_main[33]=8
	set ColoEnemyType_main[33]='n04D'
	set ColoCount_main[34]=5
	set ColoEnemyType_main[34]='n04D'
	set ColoCount_sec[34]=1
	set ColoEnemyType_sec[34]='n04E'
	set ColoCount_main[35]=6
	set ColoEnemyType_main[35]='n061'
	set ColoCount_main[36]=10
	set ColoEnemyType_main[36]='n061'
	set ColoCount_main[37]=7
	set ColoEnemyType_main[37]='n062'
	set ColoCount_main[38]=7
	set ColoEnemyType_main[38]='n063'
	set ColoCount_main[39]=7
	set ColoEnemyType_main[39]='n064'
	set ColoCount_main[40]=4
	set ColoEnemyType_main[40]='n065'
	set ColoCount_main[41]=8
	set ColoEnemyType_main[41]='n065'
	set ColoCount_main[42]=10
	set ColoEnemyType_main[42]='n063'
	set ColoCount_main[43]=6
	set ColoEnemyType_main[43]='n061'
	set ColoCount_sec[43]=6
	set ColoEnemyType_sec[43]='n062'
	set ColoCount_main[44]=6
	set ColoEnemyType_main[44]='n064'
	set ColoCount_sec[44]=6
	set ColoEnemyType_sec[44]='n065'
	set ColoCount_main[45]=8
	set ColoEnemyType_main[45]='n065'
	set ColoCount_sec[45]=1
	set ColoEnemyType_sec[45]='n066'
	set ColoCount_main[46]=4
	set ColoEnemyType_main[46]='n04E'
	set ColoCount_sec[46]=2
	set ColoEnemyType_sec[46]='n066'
	set ColoCount_main[49]=3
	set ColoEnemyType_main[49]='n04F'
	set ColoCount_main[50]=4
	set ColoEnemyType_main[50]='n04G'
	set ColoCount_main[51]=8
	set ColoEnemyType_main[51]='n04F'
	set ColoCount_main[52]=6
	set ColoEnemyType_main[52]='n04G'
	set ColoCount_main[53]=6
	set ColoEnemyType_main[53]='n04H'
	set ColoCount_main[54]=5
	set ColoEnemyType_main[54]='n04H'
	set ColoCount_sec[54]=5
	set ColoEnemyType_sec[54]='n04G'
	set ColoCount_main[55]=4
	set ColoEnemyType_main[55]='n04I'
	set ColoCount_main[56]=11
	set ColoEnemyType_main[56]='n04I'
	set ColoCount_main[57]=5
	set ColoEnemyType_main[57]='n04F'
	set ColoCount_sec[57]=5
	set ColoEnemyType_sec[57]='n04G'
	set ColoCount_main[58]=6
	set ColoEnemyType_main[58]='n04H'
	set ColoCount_sec[58]=6
	set ColoEnemyType_sec[58]='n04I'
	set ColoCount_main[59]=5
	set ColoEnemyType_main[59]='n04I'
	set ColoCount_sec[59]=1
	set ColoEnemyType_sec[59]='n04J'
	set ColoCount_main[60]=6
	set ColoEnemyType_main[60]='n067'
	set ColoCount_main[61]=10
	set ColoEnemyType_main[61]='n067'
	set ColoCount_main[62]=10
	set ColoEnemyType_main[62]='n067'
	set ColoCount_main[63]=5
	set ColoEnemyType_main[63]='n068'
	set ColoCount_main[64]=9
	set ColoEnemyType_main[64]='n068'
	set ColoCount_main[65]=5
	set ColoEnemyType_main[65]='n069'
	set ColoCount_main[66]=5
	set ColoEnemyType_main[66]='n068'
	set ColoCount_sec[66]=5
	set ColoEnemyType_sec[66]='n069'
	set ColoCount_main[67]=10
	set ColoEnemyType_main[67]='n069'
	set ColoCount_main[68]=10
	set ColoEnemyType_main[68]='n06A'
	set ColoCount_main[69]=10
	set ColoEnemyType_main[69]='n06A'
	set ColoCount_sec[69]=1
	set ColoEnemyType_sec[69]='n06B'
	set ColoCount_main[70]=4
	set ColoEnemyType_main[70]='n04J'
	set ColoCount_sec[70]=2
	set ColoEnemyType_sec[70]='n06B'
	set ColoCount_main[73]=5
	set ColoEnemyType_main[73]='n04K'
	set ColoCount_main[74]=4
	set ColoEnemyType_main[74]='n06C'
	set ColoCount_main[75]=4
	set ColoEnemyType_main[75]='n04K'
	set ColoCount_sec[75]=4
	set ColoEnemyType_sec[75]='n06C'
	set ColoCount_main[76]=6
	set ColoEnemyType_main[76]='n04L'
	set ColoCount_main[77]=5
	set ColoEnemyType_main[77]='n06D'
	set ColoCount_main[78]=4
	set ColoEnemyType_main[78]='n04L'
	set ColoCount_sec[78]=4
	set ColoEnemyType_sec[78]='n06C'
	set ColoCount_main[79]=4
	set ColoEnemyType_main[79]='n04K'
	set ColoCount_sec[79]=4
	set ColoEnemyType_sec[79]='n06D'
	set ColoCount_main[80]=4
	set ColoEnemyType_main[80]='n04L'
	set ColoCount_sec[80]=4
	set ColoEnemyType_sec[80]='n06D'
	set ColoCount_main[81]=10
	set ColoEnemyType_main[81]='n04M'
	set ColoCount_main[82]=6
	set ColoEnemyType_main[82]='n04M'
	set ColoCount_sec[82]=6
	set ColoEnemyType_sec[82]='n06C'
	set ColoCount_main[83]=6
	set ColoEnemyType_main[83]='n04M'
	set ColoCount_sec[83]=6
	set ColoEnemyType_sec[83]='n06D'
	set ColoCount_main[84]=6
	set ColoEnemyType_main[84]='n06E'
	set ColoCount_main[85]=7
	set ColoEnemyType_main[85]='n04K'
	set ColoCount_sec[85]=5
	set ColoEnemyType_sec[85]='n06E'
	set ColoCount_main[86]=6
	set ColoEnemyType_main[86]='n04L'
	set ColoCount_sec[86]=5
	set ColoEnemyType_sec[86]='n06E'
	set ColoCount_main[87]=5
	set ColoEnemyType_main[87]='n04M'
	set ColoCount_sec[87]=6
	set ColoEnemyType_sec[87]='n06E'
	set ColoCount_main[88]=5
	set ColoEnemyType_main[88]='n04N'
	set ColoCount_main[89]=6
	set ColoEnemyType_main[89]='n04N'
	set ColoCount_sec[89]=5
	set ColoEnemyType_sec[89]='n06D'
	set ColoCount_main[90]=11
	set ColoEnemyType_main[90]='n04N'
	set ColoCount_main[91]=6
	set ColoEnemyType_main[91]='n04N'
	set ColoCount_sec[91]=5
	set ColoEnemyType_sec[91]='n06E'
	set ColoCount_main[92]=6
	set ColoEnemyType_main[92]='n06F'
	set ColoCount_main[93]=6
	set ColoEnemyType_main[93]='n04L'
	set ColoCount_sec[93]=4
	set ColoEnemyType_sec[93]='n06F'
	set ColoCount_main[94]=5
	set ColoEnemyType_main[94]='n04N'
	set ColoCount_sec[94]=5
	set ColoEnemyType_sec[94]='n06F'
	set ColoCount_main[95]=2
	set ColoEnemyType_main[95]='n04O'
	set ColoCount_sec[95]=5
	set ColoEnemyType_sec[95]='n06C'
	set ColoCount_main[96]=5
	set ColoEnemyType_main[96]='n04K'
	set ColoCount_sec[96]=2
	set ColoEnemyType_sec[96]='n06G'
	set ColoCount_main[97]=4
	set ColoEnemyType_main[97]='n04O'
	set ColoCount_sec[97]=6
	set ColoEnemyType_sec[97]='n06F'
	set ColoCount_main[98]=5
	set ColoEnemyType_main[98]='n04N'
	set ColoCount_sec[98]=2
	set ColoEnemyType_sec[98]='n06G'
	set ColoCount_main[99]=4
	set ColoEnemyType_main[99]='n04O'
	set ColoCount_sec[99]=3
	set ColoEnemyType_sec[99]='n06G'
	set ColoCount_main[100]=5
	set ColoEnemyType_main[100]='n04O'
	set ColoCount_sec[100]=5
	set ColoEnemyType_sec[100]='n06G'
	set ColoCount_main[103]=5
	set ColoEnemyType_main[103]='n06M'
	set ColoCount_main[104]=8
	set ColoEnemyType_main[104]='n06M'
	set ColoCount_main[105]=5
	set ColoEnemyType_main[105]='n06P'
	set ColoCount_main[106]=4
	set ColoEnemyType_main[106]='n06M'
	set ColoCount_sec[106]=3
	set ColoEnemyType_sec[106]='n06P'
	set ColoCount_main[107]=8
	set ColoEnemyType_main[107]='n06P'
	set ColoCount_main[108]=6
	set ColoEnemyType_main[108]='n06M'
	set ColoCount_sec[108]=6
	set ColoEnemyType_sec[108]='n06P'
	set ColoCount_main[109]=6
	set ColoEnemyType_main[109]='n06N'
	set ColoCount_sec[109]=6
	set ColoEnemyType_sec[109]='n06P'
	set ColoCount_main[110]=8
	set ColoEnemyType_main[110]='n06Q'
	set ColoCount_main[111]=8
	set ColoEnemyType_main[111]='n05G'
	set ColoCount_main[112]=5
	set ColoEnemyType_main[112]='n06Q'
	set ColoCount_sec[112]=5
	set ColoEnemyType_sec[112]='n05G'
	set ColoCount_main[113]=6
	set ColoEnemyType_main[113]='n06Q'
	set ColoCount_sec[113]=6
	set ColoEnemyType_sec[113]='n06P'
	set ColoCount_main[114]=6
	set ColoEnemyType_main[114]='n05G'
	set ColoCount_sec[114]=6
	set ColoEnemyType_sec[114]='n06P'
	set ColoCount_main[115]=8
	set ColoEnemyType_main[115]='n05H'
	set ColoCount_main[116]=6
	set ColoEnemyType_main[116]='n05H'
	set ColoCount_sec[116]=6
	set ColoEnemyType_sec[116]='n06P'
	set ColoCount_main[117]=8
	set ColoEnemyType_main[117]='n05I'
	set ColoCount_main[118]=6
	set ColoEnemyType_main[118]='n05I'
	set ColoCount_sec[118]=6
	set ColoEnemyType_sec[118]='n06P'
	set ColoCount_main[119]=8
	set ColoEnemyType_main[119]='n06O'
	set ColoCount_main[120]=6
	set ColoEnemyType_main[120]='n05H'
	set ColoCount_sec[120]=6
	set ColoEnemyType_sec[120]='n06O'
	set ColoCount_main[121]=6
	set ColoEnemyType_main[121]='n05I'
	set ColoCount_sec[121]=6
	set ColoEnemyType_sec[121]='n06O'
	set ColoCount_main[122]=8
	set ColoEnemyType_main[122]='n05J'
	set ColoCount_main[123]=6
	set ColoEnemyType_main[123]='n05J'
	set ColoCount_sec[123]=6
	set ColoEnemyType_sec[123]='n06O'
	set ColoCount_main[124]=8
	set ColoEnemyType_main[124]='n05K'
	set ColoCount_main[125]=6
	set ColoEnemyType_main[125]='n05K'
	set ColoCount_sec[125]=6
	set ColoEnemyType_sec[125]='n06O'
	set ColoCount_main[128]=4
	set ColoEnemyType_main[128]='n04Q'
	set ColoCount_main[129]=8
	set ColoEnemyType_main[129]='n04Q'
	set ColoCount_main[130]=6
	set ColoEnemyType_main[130]='n06W'
	set ColoCount_main[131]=6
	set ColoEnemyType_main[131]='n04Q'
	set ColoCount_sec[131]=4
	set ColoEnemyType_sec[131]='n06W'
	set ColoCount_main[132]=6
	set ColoEnemyType_main[132]='n06X'
	set ColoCount_main[133]=5
	set ColoEnemyType_main[133]='n04Q'
	set ColoCount_sec[133]=4
	set ColoEnemyType_sec[133]='n06X'
	set ColoCount_main[134]=4
	set ColoEnemyType_main[134]='n04R'
	set ColoCount_main[135]=5
	set ColoEnemyType_main[135]='n04R'
	set ColoCount_sec[135]=4
	set ColoEnemyType_sec[135]='n06X'
	set ColoCount_main[136]=5
	set ColoEnemyType_main[136]='n04R'
	set ColoCount_sec[136]=4
	set ColoEnemyType_sec[136]='n06W'
	set ColoCount_main[137]=6
	set ColoEnemyType_main[137]='n06Y'
	set ColoCount_main[138]=5
	set ColoEnemyType_main[138]='n04R'
	set ColoCount_sec[138]=4
	set ColoEnemyType_sec[138]='n06Y'
	set ColoCount_main[139]=6
	set ColoEnemyType_main[139]='n06Z'
	set ColoCount_main[140]=5
	set ColoEnemyType_main[140]='n04R'
	set ColoCount_sec[140]=4
	set ColoEnemyType_sec[140]='n06Z'
	set ColoCount_main[141]=6
	set ColoEnemyType_main[141]='n04S'
	set ColoCount_main[142]=5
	set ColoEnemyType_main[142]='n04S'
	set ColoCount_sec[142]=4
	set ColoEnemyType_sec[142]='n06Z'
	set ColoCount_main[143]=5
	set ColoEnemyType_main[143]='n04S'
	set ColoCount_sec[143]=4
	set ColoEnemyType_sec[143]='n06Y'
	set ColoCount_main[144]=6
	set ColoEnemyType_main[144]='n070'
	set ColoCount_main[145]=5
	set ColoEnemyType_main[145]='n04S'
	set ColoCount_sec[145]=4
	set ColoEnemyType_sec[145]='n070'
	set ColoCount_main[146]=6
	set ColoEnemyType_main[146]='n04T'
	set ColoCount_main[147]=5
	set ColoEnemyType_main[147]='n04T'
	set ColoCount_sec[147]=4
	set ColoEnemyType_sec[147]='n070'
	set ColoCount_main[148]=6
	set ColoEnemyType_main[148]='n071'
	set ColoCount_main[149]=5
	set ColoEnemyType_main[149]='n04S'
	set ColoCount_sec[149]=4
	set ColoEnemyType_sec[149]='n071'
	set ColoCount_main[150]=5
	set ColoEnemyType_main[150]='n04T'
	set ColoCount_sec[150]=5
	set ColoEnemyType_sec[150]='n071'
	set ColoCount_main[153]=3
	set ColoEnemyType_main[153]='n07L'
	set ColoCount_main[154]=6
	set ColoEnemyType_main[154]='n07L'
	set ColoCount_main[155]=5
	set ColoEnemyType_main[155]='n076'
	set ColoCount_main[156]=3
	set ColoEnemyType_main[156]='n076'
	set ColoCount_sec[156]=3
	set ColoEnemyType_sec[156]='n07L'
	set ColoCount_main[157]=8
	set ColoEnemyType_main[157]='n076'
	set ColoCount_main[158]=5
	set ColoEnemyType_main[158]='n07M'
	set ColoCount_main[159]=6
	set ColoEnemyType_main[159]='n077'
	set ColoCount_main[160]=6
	set ColoEnemyType_main[160]='n07M'
	set ColoCount_sec[160]=3
	set ColoEnemyType_sec[160]='n076'
	set ColoCount_main[161]=6
	set ColoEnemyType_main[161]='n07L'
	set ColoCount_sec[161]=3
	set ColoEnemyType_sec[161]='n077'
	set ColoCount_main[162]=6
	set ColoEnemyType_main[162]='n07M'
	set ColoCount_sec[162]=5
	set ColoEnemyType_sec[162]='n077'
	set ColoCount_main[163]=6
	set ColoEnemyType_main[163]='n07O'
	set ColoCount_main[164]=6
	set ColoEnemyType_main[164]='n078'
	set ColoCount_main[165]=5
	set ColoEnemyType_main[165]='n07O'
	set ColoCount_sec[165]=5
	set ColoEnemyType_sec[165]='n077'
	set ColoCount_main[166]=5
	set ColoEnemyType_main[166]='n07M'
	set ColoCount_sec[166]=5
	set ColoEnemyType_sec[166]='n078'
	set ColoCount_main[167]=5
	set ColoEnemyType_main[167]='n07O'
	set ColoCount_sec[167]=5
	set ColoEnemyType_sec[167]='n078'
	set ColoCount_main[168]=6
	set ColoEnemyType_main[168]='n07P'
	set ColoCount_main[169]=6
	set ColoEnemyType_main[169]='n079'
	set ColoCount_main[170]=6
	set ColoEnemyType_main[170]='n07P'
	set ColoCount_sec[170]=2
	set ColoEnemyType_sec[170]='n078'
	set ColoCount_main[171]=6
	set ColoEnemyType_main[171]='n07P'
	set ColoCount_sec[171]=5
	set ColoEnemyType_sec[171]='n078'
	set ColoCount_main[172]=6
	set ColoEnemyType_main[172]='n07O'
	set ColoCount_sec[172]=5
	set ColoEnemyType_sec[172]='n079'
	set ColoCount_main[173]=5
	set ColoEnemyType_main[173]='n07P'
	set ColoCount_sec[173]=5
	set ColoEnemyType_sec[173]='n079'
	set ColoCount_main[174]=6
	set ColoEnemyType_main[174]='n07A'
	set ColoCount_main[175]=6
	set ColoEnemyType_main[175]='n07P'
	set ColoCount_sec[175]=2
	set ColoEnemyType_sec[175]='n07A'
	set ColoCount_main[176]=5
	set ColoEnemyType_main[176]='n07P'
	set ColoCount_sec[176]=5
	set ColoEnemyType_sec[176]='n07A'
	set ColoCount_main[177]=6
	set ColoEnemyType_main[177]='n07Q'
	set ColoCount_main[178]=5
	set ColoEnemyType_main[178]='n07Q'
	set ColoCount_sec[178]=5
	set ColoEnemyType_sec[178]='n079'
	set ColoCount_main[179]=6
	set ColoEnemyType_main[179]='n07Q'
	set ColoCount_sec[179]=5
	set ColoEnemyType_sec[179]='n07A'
	set ColoCount_main[182]=6
	set ColoEnemyType_main[182]='n07G'
	set ColoCount_main[183]=6
	set ColoEnemyType_main[183]='n07N'
	set ColoCount_main[184]=4
	set ColoEnemyType_main[184]='n07G'
	set ColoCount_sec[184]=4
	set ColoEnemyType_sec[184]='n07N'
	set ColoCount_main[185]=6
	set ColoEnemyType_main[185]='n07H'
	set ColoCount_main[186]=4
	set ColoEnemyType_main[186]='n07H'
	set ColoCount_sec[186]=4
	set ColoEnemyType_sec[186]='n07N'
	set ColoCount_main[187]=6
	set ColoEnemyType_main[187]='n09U'
	set ColoCount_main[188]=4
	set ColoEnemyType_main[188]='n07G'
	set ColoCount_sec[188]=4
	set ColoEnemyType_sec[188]='n09U'
	set ColoCount_main[189]=4
	set ColoEnemyType_main[189]='n07H'
	set ColoCount_sec[189]=4
	set ColoEnemyType_sec[189]='n09U'
	set ColoCount_main[190]=7
	set ColoEnemyType_main[190]='n07I'
	set ColoCount_main[191]=5
	set ColoEnemyType_main[191]='n07I'
	set ColoCount_sec[191]=4
	set ColoEnemyType_sec[191]='n09U'
	set ColoCount_main[192]=7
	set ColoEnemyType_main[192]='n09V'
	set ColoCount_main[193]=5
	set ColoEnemyType_main[193]='n07I'
	set ColoCount_sec[193]=4
	set ColoEnemyType_sec[193]='n09V'
	set ColoCount_main[194]=7
	set ColoEnemyType_main[194]='n07J'
	set ColoCount_main[195]=5
	set ColoEnemyType_main[195]='n07J'
	set ColoCount_sec[195]=5
	set ColoEnemyType_sec[195]='n09V'
	set ColoCount_main[196]=7
	set ColoEnemyType_main[196]='n09W'
	set ColoCount_main[197]=6
	set ColoEnemyType_main[197]='n07J'
	set ColoCount_sec[197]=5
	set ColoEnemyType_sec[197]='n09W'
	set ColoCount_main[198]=7
	set ColoEnemyType_main[198]='n09X'
	set ColoCount_main[199]=6
	set ColoEnemyType_main[199]='n07J'
	set ColoCount_sec[199]=6
	set ColoEnemyType_sec[199]='n09X'
	set ColoCount_main[200]=7
	set ColoEnemyType_main[200]='n07K'
	set ColoCount_main[201]=6
	set ColoEnemyType_main[201]='n07K'
	set ColoCount_sec[201]=6
	set ColoEnemyType_sec[201]='n09W'
	set ColoCount_main[202]=6
	set ColoEnemyType_main[202]='n07K'
	set ColoCount_sec[202]=6
	set ColoEnemyType_sec[202]='n09X'
	set ColoCount_main[203]=7
	set ColoEnemyType_main[203]='n09Y'
	set ColoCount_main[204]=6
	set ColoEnemyType_main[204]='n07J'
	set ColoCount_sec[204]=6
	set ColoEnemyType_sec[204]='n09Y'
	set ColoCount_main[205]=6
	set ColoEnemyType_main[205]='n07K'
	set ColoCount_sec[205]=6
	set ColoEnemyType_sec[205]='n09Y'
	set ColoCount_main[206]=5
	set ColoEnemyType_main[206]='n07R'
	set ColoCount_main[207]=3
	set ColoEnemyType_main[207]='n07R'
	set ColoCount_sec[207]=6
	set ColoEnemyType_sec[207]='n09X'
	set ColoCount_main[208]=5
	set ColoEnemyType_main[208]='n07R'
	set ColoCount_sec[208]=6
	set ColoEnemyType_sec[208]='n09Y'
	set ColoCount_main[209]=6
	set ColoEnemyType_main[209]='n09Y'
	set ColoCount_main[210]=6
	set ColoEnemyType_main[210]='n07K'
	set ColoCount_sec[210]=6
	set ColoEnemyType_sec[210]='n09Y'
	set ColoCount_main[211]=6
	set ColoEnemyType_main[211]='n07R'
	set ColoCount_sec[211]=6
	set ColoEnemyType_sec[211]='n09Y'
endfunction

function HeadhunterQuestSetup takes nothing returns nothing
    set udg_HuntedRecipe[0] = 'I057'
    set udg_HuntedHead[0] = 'gmfr'
    set udg_HuntedItem[0] = 'I01B'
    set HuntedLevel[0] = 100
    set udg_HuntedExp[0] = 5000
    set udg_HuntedRecipe[1] = 'I049'
    set udg_HuntedHead[1] = 'I02M'
    set udg_HuntedItem[1] = 'I04C'
    set HuntedLevel[1] = 50
    set udg_HuntedExp[1] = 4000
    set udg_HuntedRecipe[2] = 'I04A'
    set udg_HuntedHead[2] = 'kybl'
    set udg_HuntedItem[2] = 'I03T'
    set HuntedLevel[2] = 75
    set udg_HuntedExp[2] = 5000
    set udg_HuntedRecipe[3] = 'I03G'
    set udg_HuntedHead[3] = 'I044'
    set udg_HuntedItem[3] = 'I0F8'
    set HuntedLevel[3] = 50
    set udg_HuntedExp[3] = 3000
    set udg_HuntedRecipe[4] = 'I05N'
    set udg_HuntedHead[4] = 'I05R'
    set udg_HuntedItem[4] = 'I03O'
    set HuntedLevel[4] = 60
    set udg_HuntedExp[4] = 5000

    set udg_PermanentInteger[10] = 4
endfunction

function ShieldTypes takes nothing returns nothing
    set udg_ShieldType[0] = 'I038'
    set udg_ShieldType[1] = 'frgd'
    set udg_ShieldType[2] = 'I0FL'
    set udg_ShieldType[3] = 'I03Y'
    set udg_ShieldType[4] = 'I05D'
    set udg_ShieldType[5] = 'I04W'
    set udg_ShieldType[6] = 'I0C2'
    set udg_ShieldType[7] = 'I0C4'
    set udg_ShieldType[8] = 'I0MC'
    set udg_ShieldType[9] = 'I0MB'
    set udg_ShieldType[10] = 'I0BY'
    set udg_ShieldType[11] = 'I0AP'
    set udg_ShieldType[12] = 'I021'
    set udg_ShieldType[13] = 'I03K'
    set udg_ShieldType[14] = 'I01J'
    set udg_ShieldType[15] = 'I02R'
    set udg_ShieldType[16] = 'I01C'

    set udg_PermanentInteger[11] = 16
endfunction

function ItemRestrictions takes nothing returns nothing
	call IndexIdsToArray(RestrictedItems[0], "I05A I05Z I0D4 I06K I0EH I0EI I06L I0EJ I0EK ")
	set restricted_string[0] = "You can only hold one Dark Soul"

	call IndexIdsToArray(RestrictedItems[1], "I0AP I021 I03K")
	set restricted_string[1] = "You can only hold one Dark Bulwark"

	call IndexIdsToArray(RestrictedItems[2], "I05J I04O I07H I00R I00N I00O I00S I07J I07N")
    set restricted_string[2] = "You can only hold one Satan's Ace"

	call IndexIdsToArray(RestrictedItems[3], "I0BX I0OC I0OD")
    set restricted_string[3] = "You can only hold one Satan's Heart"

	call IndexIdsToArray(RestrictedItems[4], "I04E I062 I0EL I00P I0EM I0EN I00Q I06E I06F I06G I06H")
	set restricted_string[4] = "A second set of wings won't help you fly better"
	
	call IndexIdsToArray(RestrictedItems[5], "I018 I0F0 I0EZ I06I I0F1 I0F2 I06J I0G1 I0G2")
	set restricted_string[5] = "You can only wear one Ring of Existence"

	call IndexIdsToArray(RestrictedItems[6], "I0NG I0NA I0NH I0NI")
	set restricted_string[6] = "You can only wear one Absolute Horror armor"

	call IndexIdsToArray(RestrictedItems[7], "I0NB I0NF I0ND I0NC I0NE")
	set restricted_string[7] = "You can only wear one Absolute Horror weapon"

	call IndexIdsToArray(RestrictedItems[8], "I0B5 I0JF I0JG I0JH I0JI I0JJ I0JK I0JL I0JM I0B7 I0HV I0HW I0HX I0HY I0HZ I0I0 
	I0I1 I0I2 I0B1 I0IZ I0J0 I0J1 I0J2 I0J3 I0J4 I0J5 I0J6 I0AZ I0I3 I0I4 I0I5 I0I6 I0I7 I0I8 I0I9 I0IA")
	set restricted_string[8] = "You can only wear one Legion armor"

	call IndexIdsToArray(RestrictedItems[9], "I0AS I0D9 I0DA I0HP I0HQ I0HR I0HS I0HT I0HU I04L I0J7 I0J8 I0J9 I0JA I0JB I0JC I0JD 
	I0JE I0AJ I0IJ I0IK I0IL I0IM I0IN I0IO I0IP I0IQ I0AV I0IB I0IC I0ID I0IE I0IF I0IG I0IH I0II I0AX I0IR I0IS I0IT I0IU I0IV I0IW I0IX I0IY")
	set restricted_string[9] = "You can only wield one Legion weapon"

	call IndexIdsToArray(RestrictedItems[10], "I0BS I0BV I0BK I0BI I0JW I0JX I0JY I0JZ I0K0 I0K1 I0K2 I0K3 I0K4 I0K5 I0K6 I0K7 I0K8 
	I0K9 I0KA I0KB I0KC I0KD I0KE I0KF I0KG I0KH I0KI I0KJ I0KK I0KL I0KM I0KN I0KO I0KP I0KQ I0KR")
	set restricted_string[10] = "You can only wear one Azazoth armor"

	call IndexIdsToArray(RestrictedItems[11], "I0BC I0BE I0BB I0B9 I0BG I0KS I0KT I0KU I0KV I0KW I0KX I0KY I0KZ I0L0 I0L1 I0L2 I0L3 I0L4 I0L5 
	I0L6 I0L7 I0L8 I0L9 I0LA I0LB I0LC I0LD I0LE I0LF I0LG I0LH I0LI I0LJ I0LK I0LL I0LM I0LN I0LO I0LP I0LQ I0LR I0LS I0LT I0LU I0LV")
	set restricted_string[11] = "You can only wield one Azazoth weapon"

	call IndexIdsToArray(RestrictedItems[12], "I06M I0LW I0LX")
    set restricted_string[12] = "You can only equip one Azazoth sphere"

	call IndexIdsToArray(RestrictedItems[13], "I0AE I04F I0AF I0AD I04X I056 I0AG I04X I056 I08X I08Y I090 I092 I094 I096 I099 I09A I02T I0OL I01R I0ON I0OO I0OM 
	I0AM I0BH I0BF I0OP I0OQ I0BD I0OT I0OS I0OR")
	set restricted_string[13] = "You can only wield one Slaughterer weapon"

	call IndexIdsToArray(RestrictedItems[14], "I0CH I01L I01N I0NT I0NP I0NQ I0NR I0NS I019 I0O1 I0O0 I0NZ I0NY I0O2 I0NX I0NV I0NU I0NW I0OB I0O9 I0O8 I0OA I0O4 I0O5 I0O7 I0O6 I0O3") 
	set restricted_string[14] = "You can only hold one Forgotten item"

	call IndexIdsToArray(RestrictedItems[15], "I033 I0BZ I02S I032 I065")
	set restricted_string[15] = "You can only wield one Draconic weapon"

	call IndexIdsToArray(RestrictedItems[16], "I02U I048 I064 I02P")
	set restricted_string[16] = "You can only wear one Draconic armor"

	call IndexIdsToArray(RestrictedItems[17], "I02N I072 I06Y I070 I071")
	set restricted_string[17] = "You can only wield one Hydra weapon"

	call IndexIdsToArray(RestrictedItems[18], "I0BN I0CT I0CK I0BO I0CU")
	set restricted_string[18] = "You can only wear one Demonic Set"

	call IndexIdsToArray(RestrictedItems[19], "I0CW I0C1 I0C2 I0CX I0CV")
	set restricted_string[19] = "You can only wear one Horror Set"

	call IndexIdsToArray(RestrictedItems[20], "I0CZ I0BP I0BQ I0D3 I0CY")
	set restricted_string[20] = "You can only wear one Despair Set"

	call IndexIdsToArray(RestrictedItems[21], "I0C9 I0C8 I0C7 I0C6 I0C5")
	set restricted_string[21] = "You can only wear one Abyssal Set"

	call IndexIdsToArray(RestrictedItems[22], "I0D7 I0C4 I0C3 I0D5 I0D6")
	set restricted_string[22] = "You can only wear one Void Set"

	call IndexIdsToArray(RestrictedItems[23], "I0CB I0CA I0CD I0CE I0CF")
	set restricted_string[23] = "You can only wear one Nightmare Set"

	call IndexIdsToArray(RestrictedItems[24], "I0D8 I0BW I0BU I0DK I0DJ")
	set restricted_string[24] = "You can only wear one Hell Set"

	call IndexIdsToArray(RestrictedItems[25], "I0DX I0BT I0BR I0DL I0DY")
	set restricted_string[25] = "You can only wear one Existence Set"

	call IndexIdsToArray(RestrictedItems[26], "I0E0 I0BM I0DZ I059 I0E1")
	set restricted_string[26] = "You can only wear one Astral Set"

	call IndexIdsToArray(RestrictedItems[27], "I0CG I0FH I0CI I0FI I0FZ")
	set restricted_string[27] = "You can only wear one Dimensional Set"

	call IndexIdsToArray(RestrictedItems[28], "I0H5 I0H6 I0H7 I0H8 I0H9")
	set restricted_string[28] = "You can only wear one Ursine Set"

	call IndexIdsToArray(RestrictedItems[29], "I0HA I0HB I0HC I0HD I0HE")
	set restricted_string[29] = "You can only wear one Ogre Set"

	call IndexIdsToArray(RestrictedItems[30], "I0HF I0HG I0HH I0HI I0HJ")
	set restricted_string[30] = "You can only wear one Unbroken Set"

	call IndexIdsToArray(RestrictedItems[31], "I0HK I0HL I0HM I0HN I0HO")
	set restricted_string[31] = "You can only wear one Magnataur Set"

	call IndexIdsToArray(RestrictedItems[32], "I0MR I0JT I023")
	set restricted_string[32] = "You only have two feet"

	call IndexIdsToArray(RestrictedItems[33], "I01J I02R I01C")
	set restricted_string[33] = "You can only wear one Chaos Shield"

	call IndexIdsToArray(RestrictedItems[34], "rnsp I0FB I03E I02I I036 I02C I02B I02O I0JR I02J I04B I029 I03P I0F9 I0C0 I0FX I03O I00B I01M I04C oli2 I043 
    I03X I03T I03Z I03Y I0FA I0FU I09D I046 I01T I0F8 I09F I074 I0EY I04N I0EX I0F4 I03U I0F3 I07F I0F5 I07B I0FC I079 I08K I00A I038 I02Z I031 I04I I030 
    I04J I00T I0D0 I03F I04S I020 I016 I0AK I050 I0AU I05X I061 I05Y I060 rde2 rde3 I0B8 I0B6 I0B4 I0BA pgin frgd I04Q I0NJ I01D I09L I03N
    I01S I0FB I0BY I0OF I01X I03Q I0AI I0AH")
	set restricted_string[34] = "You can only wear one of this item."

    set RESTRICTED_ITEMS_MAX = 34
endfunction

function SetItemStats takes nothing returns nothing
	//chaotic boss items

    //prince heart
	call SetTableData(ItemData, 'I04Q', "level 190")

	//slaughter queen
	call SetTableData(ItemData, 'I0AE', "level 270 damage 55000 str 11000 prof 6")
	call SetTableData(ItemData, 'I090', "level 280 damage 68000 str 14000 prof 6")
	call SetTableData(ItemData, 'I092', "level 290 damage 82000 str 16000 prof 6")
	call SetTableData(ItemData, 'I0BF', "level 300 damage 82000 str 16000 prof 6")
	call SetTableData(ItemData, 'I0AM', "level 310 damage 82000 str 16000 prof 6")
	call SetTableData(ItemData, 'I0BH', "level 320 damage 82000 str 16000 prof 6")

	call SetTableData(ItemData, 'I04F', "level 270 damage 100000 prof 7")
	call SetTableData(ItemData, 'I099', "level 280 damage 125000 prof 7")
	call SetTableData(ItemData, 'I09A', "level 290 damage 150000 prof 7")
	call SetTableData(ItemData, 'I0OR', "level 300 damage 150000 prof 7")
	call SetTableData(ItemData, 'I0OS', "level 310 damage 150000 prof 7")
	call SetTableData(ItemData, 'I0OT', "level 320 damage 150000 prof 7")

	call SetTableData(ItemData, 'I0AF', "level 270 damage 46000 agi 18000 prof 8")
	call SetTableData(ItemData, 'I08X', "level 280 damage 57000 agi 23000 prof 8")
	call SetTableData(ItemData, 'I08Y', "level 290 damage 68000 agi 27000 prof 8")
	call SetTableData(ItemData, 'I0OM', "level 300 damage 68000 agi 27000 prof 8")
	call SetTableData(ItemData, 'I0ON', "level 310 damage 68000 agi 27000 prof 8")
	call SetTableData(ItemData, 'I0OO', "level 320 damage 68000 agi 27000 prof 8")

	call SetTableData(ItemData, 'I0AD', "level 270 damage 95000 agi 5000 prof 9")
	call SetTableData(ItemData, 'I04X', "level 280 damage 119000 agi 7000 prof 9")
	call SetTableData(ItemData, 'I056', "level 290 damage 142000 agi 8000 prof 9")
	call SetTableData(ItemData, 'I01R', "level 300 damage 142000 agi 8000 prof 9")
	call SetTableData(ItemData, 'I02T', "level 310 damage 142000 agi 8000 prof 9")
	call SetTableData(ItemData, 'I0OL', "level 320 damage 142000 agi 8000 prof 9")

	call SetTableData(ItemData, 'I0AG', "level 270 damage 23000 int 20000 prof 10")
	call SetTableData(ItemData, 'I094', "level 280 damage 29000 int 25000 prof 10")
	call SetTableData(ItemData, 'I096', "level 290 damage 34000 int 30000 prof 10")
	call SetTableData(ItemData, 'I0BD', "level 300 damage 34000 int 30000 prof 10")
	call SetTableData(ItemData, 'I0OS', "level 310 damage 34000 int 30000 prof 10")
	call SetTableData(ItemData, 'I0OT', "level 320 damage 34000 int 30000 prof 10")

	//soul
	call SetTableData(ItemData, 'I05A', "level 300 stats 9000 spellboost 3")
	call SetTableData(ItemData, 'I05Z', "level 308 stats 11300 spellboost 4")
	call SetTableData(ItemData, 'I0D4', "level 316 stats 13500 spellboost 5")
	call SetTableData(ItemData, 'I06K', "level 324 stats 15600 spellboost 1 res 100 recharge 1 cost 500000")
	call SetTableData(ItemData, 'I0EH', "level 332 stats 19400 spellboost 4 res 100 recharge 1 cost 600000")
	call SetTableData(ItemData, 'I0EI', "level 340 stats 23400 spellboost 7 res 100 recharge 1 cost 700000")
	call SetTableData(ItemData, 'I06L', "level 348 stats 27000 spellboost 9 res 100 recharge 1 cost 1000000")
	call SetTableData(ItemData, 'I0EJ', "level 356 stats 33800 spellboost 10 res 100 recharge 1 cost 1500000")
	call SetTableData(ItemData, 'I0EK', "level 364 stats 40500 spellboost 12 res 100 recharge 1 cost 2000000")

	//dark soul
	call SetTableData(ItemData, 'I0AH', "level 300 health 1000000")
	call SetTableData(ItemData, 'I0AP', "level 300 armor 3000 evasion 10")
	call SetTableData(ItemData, 'I021', "level 320 armor 5000 evasion 15")
	call SetTableData(ItemData, 'I03K', "level 340 armor 7000 evasion 20")
	call SetTableData(ItemData, 'I0AI', "level 308 regen 11000")

	//thanatos wings
	call SetTableData(ItemData, 'I04E', "level 320 movespeed 300 damage 80000 stats 6000")
	call SetTableData(ItemData, 'I062', "level 328 movespeed 320 damage 100000 stats 7500")
	call SetTableData(ItemData, 'I0EL', "level 336 movespeed 340 damage 120000 stats 9000")
	call SetTableData(ItemData, 'I00P', "level 344 movespeed 360 damage 138000 stats 10400")
	call SetTableData(ItemData, 'I0EM', "level 352 movespeed 380 damage 172000 stats 12900")
	call SetTableData(ItemData, 'I0EN', "level 360 movespeed 400 damage 208000 stats 15600 spellboost 8")
	call SetTableData(ItemData, 'I00Q', "level 368 movespeed 420 damage 240000 stats 18000 spellboost 9")
	call SetTableData(ItemData, 'I06E', "level 376 movespeed 440 damage 300000 stats 22500 spellboost 10")
	call SetTableData(ItemData, 'I06F', "level 384 movespeed 460 damage 360000 stats 27000 spellboost 12")
	call SetTableData(ItemData, 'I06G', "level 392 movespeed 480 damage 420000 stats 32000 spellboost 14")
	call SetTableData(ItemData, 'I06H', "level 400 movespeed 500 damage 480000 stats 36000 spellboost 16")

	//thanatos boots
	call SetTableData(ItemData, 'I0MR', "level 320 movespeed 300 int 12000 stats 3000 spellboost 5")
	call SetTableData(ItemData, 'I0JT', "level 344 movespeed 400 int 32800 stats 10000 spellboost 10")
	call SetTableData(ItemData, 'I023', "level 368 movespeed 500 int 50000 stats 20000 spellboost 15")

	//satan
	call SetTableData(ItemData, 'I0BX', "level 318 regen 20000")
	call SetTableData(ItemData, 'I0OC', "level 326 regen 25000")
	call SetTableData(ItemData, 'I0OD', "level 334 regen 30000")
	call SetTableData(ItemData, 'I05J', "level 310 damage 50000 armor 1000 crit 10 chance 20")
	call SetTableData(ItemData, 'I04O', "level 318 damage 63000 armor 1300 crit 10 chance 20")
	call SetTableData(ItemData, 'I07H', "level 326 damage 75000 armor 1500 crit 10 chance 20")
	call SetTableData(ItemData, 'I00R', "level 326 damage 87000 armor 1700 spellboost 5 crit 10 chance 30")
	call SetTableData(ItemData, 'I00N', "level 334 damage 108000 armor 2200 spellboost 6 crit 10 chance 30")
	call SetTableData(ItemData, 'I00O', "level 342 damage 130000 armor 2600 spellboost 7 crit 10 chance 30")
	call SetTableData(ItemData, 'I00S', "level 350 damage 150000 armor 3000 spellboost 8 crit 10 chance 40")
	call SetTableData(ItemData, 'I07J', "level 358 damage 188000 armor 3800 spellboost 9 crit 10 chance 40")
	call SetTableData(ItemData, 'I07N', "level 366 damage 225000 armor 4500 spellboost 10 crit 10 chance 40")

	//legion
	//plate
	call SetTableData(ItemData, 'I0B5', "level 340 armor 3500 str 7400 regen 2000 mr 10 prof 1")
	call SetTableData(ItemData, 'I0JF', "level 348 armor 4400 str 9300 regen 2500 mr 10 prof 1")
	call SetTableData(ItemData, 'I0JG', "level 356 armor 5300 str 11100 regen 3000 mr 10 prof 1")
	call SetTableData(ItemData, 'I0JH', "level 356 armor 6100 str 12800 regen 3500 mr 10 prof 1")
	call SetTableData(ItemData, 'I0JI', "level 364 armor 7500 str 15900 regen 4300 mr 10 prof 1")
	call SetTableData(ItemData, 'I0JJ', "level 372 armor 9100 str 19200 regen 5200 mr 10 prof 1")
	call SetTableData(ItemData, 'I0JK', "level 380 armor 10500 str 22200 regen 6000 mr 10 prof 1")
	call SetTableData(ItemData, 'I0JL', "level 388 armor 13100 str 27800 regen 7500 mr 10 prof 1")
	call SetTableData(ItemData, 'I0JM', "level 396 armor 18400 str 38900 regen 10500 mr 10 prof 1")

	//fullplate
	call SetTableData(ItemData, 'I0B7', "level 340 movespeed -25 armor 5600 str 500 regen 2500 mr 10 prof 2")
	call SetTableData(ItemData, 'I0HV', "level 348 movespeed -25 armor 7000 str 620 regen 3100 mr 10 prof 2")
	call SetTableData(ItemData, 'I0HW', "level 356 movespeed -25 armor 8400 str 760 regen 3800 mr 10 prof 2")
	call SetTableData(ItemData, 'I0HX', "level 356 movespeed -25 armor 9700 str 860 regen 4300 mr 10 prof 2")
	call SetTableData(ItemData, 'I0HY', "level 364 movespeed -25 armor 12000 str 1080 regen 6500 mr 10 prof 2")
	call SetTableData(ItemData, 'I0HZ', "level 372 movespeed -25 armor 14600 str 1300 regen 7800 mr 10 prof 2")
	call SetTableData(ItemData, 'I0I0', "level 380 movespeed -25 armor 16800 str 1500 regen 9000 mr 10 prof 2")
	call SetTableData(ItemData, 'I0I1', "level 388 movespeed -25 armor 21000 str 1880 regen 11300 mr 10 prof 2")
	call SetTableData(ItemData, 'I0I2', "level 396 movespeed -25 armor 29400 str 2620 regen 15800 mr 10 prof 2")

	//leather
	call SetTableData(ItemData, 'I0B1', "level 340 armor 3500 agi 12400 regen 1500 mr 20 prof 3")
	call SetTableData(ItemData, 'I0IZ', "level 348 armor 4400 agi 15500 regen 2000 mr 20 prof 3")
	call SetTableData(ItemData, 'I0J0', "level 356 armor 5300 agi 18600 regen 2500 mr 20 prof 3")
	call SetTableData(ItemData, 'I0J1', "level 356 armor 6100 agi 21500 regen 3000 mr 20 prof 3")
	call SetTableData(ItemData, 'I0J2', "level 364 armor 7500 agi 26700 regen 3500 mr 20 prof 3")
	call SetTableData(ItemData, 'I0J3', "level 372 armor 9100 agi 32200 regen 4000 mr 20 prof 3")
	call SetTableData(ItemData, 'I0J4', "level 380 armor 10500 agi 37200 regen 4500 mr 20 prof 3")
	call SetTableData(ItemData, 'I0J5', "level 388 armor 13100 agi 46500 regen 5000 mr 20 prof 3")
	call SetTableData(ItemData, 'I0J6', "level 396 armor 18400 agi 65100 regen 5500 mr 20 prof 3")

	//robe
	call SetTableData(ItemData, 'I0AZ', "level 340 armor 2800 int 14300 mr 20 prof 4")
	call SetTableData(ItemData, 'I0I3', "level 348 armor 3500 int 17900 mr 20 prof 4")
	call SetTableData(ItemData, 'I0I4', "level 356 armor 4200 int 21500 mr 20 prof 4")
	call SetTableData(ItemData, 'I0I5', "level 356 armor 4900 int 24800 mr 20 prof 4")
	call SetTableData(ItemData, 'I0I6', "level 364 armor 6000 int 30700 mr 20 prof 4")
	call SetTableData(ItemData, 'I0I7', "level 372 armor 7300 int 37200 mr 20 prof 4")
	call SetTableData(ItemData, 'I0I8', "level 380 armor 8400 int 42900 mr 20 prof 4")
	call SetTableData(ItemData, 'I0I9', "level 388 armor 10500 int 53600 mr 20 prof 4")
	call SetTableData(ItemData, 'I0IA', "level 396 armor 14700 int 75100 mr 20 prof 4")

	//heavy
	call SetTableData(ItemData, 'I0AS', "level 340 damage 60000 str 14900 crit 4 chance 20 prof 6")
	call SetTableData(ItemData, 'I0D9', "level 348 damage 75000 str 18600 crit 4 chance 20 prof 6")
	call SetTableData(ItemData, 'I0DA', "level 356 damage 90000 str 22400 crit 4 chance 20 prof 6")
	call SetTableData(ItemData, 'I0HP', "level 356 damage 104000 str 25800 crit 7 chance 20 prof 6")
	call SetTableData(ItemData, 'I0HQ', "level 364 damage 129000 str 32000 crit 7 chance 20 prof 6")
	call SetTableData(ItemData, 'I0HR', "level 372 damage 156000 str 38700 crit 7 chance 20 prof 6")
	call SetTableData(ItemData, 'I0HS', "level 380 damage 180000 str 44700 crit 10 chance 20 prof 6")
	call SetTableData(ItemData, 'I0HT', "level 386 damage 225000 str 55900 crit 10 chance 20 prof 6")
	call SetTableData(ItemData, 'I0HU', "level 394 damage 315000 str 78200 crit 10 chance 20 prof 6")

	//sword
	call SetTableData(ItemData, 'I04L', "level 340 damage 109000 crit 4 chance 20 prof 7")
	call SetTableData(ItemData, 'I0J7', "level 348 damage 136000 crit 4 chance 20 prof 7")
	call SetTableData(ItemData, 'I0J8', "level 356 damage 164000 crit 4 chance 20 prof 7")
	call SetTableData(ItemData, 'I0J9', "level 356 damage 189000 crit 7 chance 20 prof 7")
	call SetTableData(ItemData, 'I0JA', "level 364 damage 234000 crit 7 chance 20 prof 7")
	call SetTableData(ItemData, 'I0JB', "level 372 damage 283000 crit 7 chance 20 prof 7")
	call SetTableData(ItemData, 'I0JC', "level 380 damage 327000 crit 10 chance 20 prof 7")
	call SetTableData(ItemData, 'I0JD', "level 388 damage 409000 crit 10 chance 20 prof 7")
	call SetTableData(ItemData, 'I0JE', "level 396 damage 572000 crit 10 chance 20 prof 7")

	//dagger
	call SetTableData(ItemData, 'I0AJ', "level 340 damage 50000 agi 24800 crit 4 chance 20 prof 8")
	call SetTableData(ItemData, 'I0IJ', "level 348 damage 63000 agi 31000 crit 4 chance 20 prof 8")
	call SetTableData(ItemData, 'I0IK', "level 356 damage 75000 agi 37200 crit 4 chance 20 prof 8")
	call SetTableData(ItemData, 'I0IL', "level 356 damage 87000 agi 43000 crit 7 chance 20 prof 8")
	call SetTableData(ItemData, 'I0IM', "level 364 damage 108000 agi 53000 crit 7 chance 20 prof 8")
	call SetTableData(ItemData, 'I0IN', "level 372 damage 130000 agi 64000 crit 7 chance 20 prof 8")
	call SetTableData(ItemData, 'I0IO', "level 380 damage 150000 agi 74000 crit 10 chance 20 prof 8")
	call SetTableData(ItemData, 'I0IP', "level 388 damage 188000 agi 93000 crit 10 chance 20 prof 8")
	call SetTableData(ItemData, 'I0IQ', "level 396 damage 263000 agi 130000 crit 10 chance 20 prof 8")

	//bow
	call SetTableData(ItemData, 'I0AV', "level 340 damage 103000 agi 7400 crit 4 chance 20 prof 9")
	call SetTableData(ItemData, 'I0IB', "level 348 damage 129000 agi 9300 crit 4 chance 20 prof 9")
	call SetTableData(ItemData, 'I0IC', "level 356 damage 155000 agi 11100 crit 4 chance 20 prof 9")
	call SetTableData(ItemData, 'I0ID', "level 356 damage 178000 agi 12800 crit 7 chance 20 prof 9")
	call SetTableData(ItemData, 'I0IE', "level 364 damage 221000 agi 15900 crit 7 chance 20 prof 9")
	call SetTableData(ItemData, 'I0IF', "level 372 damage 268000 agi 19200 crit 7 chance 20 prof 9")
	call SetTableData(ItemData, 'I0IG', "level 380 damage 309000 agi 22200 crit 10 chance 20 prof 9")
	call SetTableData(ItemData, 'I0IH', "level 388 damage 386000 agi 27800 crit 10 chance 20 prof 9")
	call SetTableData(ItemData, 'I0II', "level 396 damage 541000 agi 38900 crit 10 chance 20 prof 9")

	//staff
	call SetTableData(ItemData, 'I0AX', "level 340 damage 25000 int 27300 spellboost 1 prof 10")
	call SetTableData(ItemData, 'I0IR', "level 348 damage 31300 int 34100 spellboost 2 prof 10")
	call SetTableData(ItemData, 'I0IS', "level 356 damage 37500 int 41000 spellboost 3 prof 10")
	call SetTableData(ItemData, 'I0IT', "level 356 damage 43300 int 47300 spellboost 6 prof 10")
	call SetTableData(ItemData, 'I0IU', "level 364 damage 54000 int 59000 spellboost 7 prof 10")
	call SetTableData(ItemData, 'I0IV', "level 372 damage 65000 int 71000 spellboost 8 prof 10")
	call SetTableData(ItemData, 'I0IW', "level 380 damage 75000 int 82000 spellboost 9 prof 10")
	call SetTableData(ItemData, 'I0IX', "level 388 damage 94000 int 102000 spellboost 10 prof 10")
	call SetTableData(ItemData, 'I0IY', "level 396 damage 131000 int 143000 spellboost 11 prof 10")

	//ring
	call SetTableData(ItemData, 'I0AU', "level 340 stats 7100")

	//existence
	//ring
	call SetTableData(ItemData, 'I018', "level 340 stats 17000")
	call SetTableData(ItemData, 'I0F0', "level 348 stats 21300")
	call SetTableData(ItemData, 'I0EZ', "level 356 stats 25500")
	call SetTableData(ItemData, 'I06I', "level 356 stats 29400")
	call SetTableData(ItemData, 'I0F1', "level 364 stats 36600")
	call SetTableData(ItemData, 'I0F2', "level 372 stats 44200 spellboost 10")
	call SetTableData(ItemData, 'I06J', "level 380 stats 51000 spellboost 11")
	call SetTableData(ItemData, 'I0G1', "level 388 stats 63800 spellboost 12")
	call SetTableData(ItemData, 'I0G2', "level 396 stats 76500 spellboost 14")

	//soul
	call SetTableData(ItemData, 'I0BY', "level 340 health 2000000 armor 2500 regen 5000")

	//chaos shield
	call SetTableData(ItemData, 'I01J', "level 340 health 1000000 regen 30000")
	call SetTableData(ItemData, 'I02R', "level 350 health 1500000 regen 45000")
	call SetTableData(ItemData, 'I01C', "level 360 health 2000000 regen 60000")

	//azazoth
	//plate
	call SetTableData(ItemData, 'I0BS', "level 380 armor 5000 str 10000 regen 4800 mr 5 prof 1")
	call SetTableData(ItemData, 'I0JW', "level 384 armor 6250 str 12500 regen 6000 mr 5 prof 1")
	call SetTableData(ItemData, 'I0JX', "level 388 armor 7500 str 15000 regen 7200 mr 5 prof 1")
	call SetTableData(ItemData, 'I0JY', "level 392 armor 10000 str 20000 regen 9200 mr 10 prof 1")
	call SetTableData(ItemData, 'I0JZ', "level 396 armor 12500 str 25000 regen 11000 mr 10 prof 1")
	call SetTableData(ItemData, 'I0K0', "level 400 armor 15000 str 30000 regen 12800 mr 10 prof 1")
	call SetTableData(ItemData, 'I0K1', "level 400 armor 20000 str 40000 regen 14000 mr 15 prof 1")
	call SetTableData(ItemData, 'I0K2', "level 400 armor 25000 str 50000 regen 16500 mr 15 prof 1")
	call SetTableData(ItemData, 'I0K3', "level 400 armor 30000 str 60000 regen 19000 mr 15 prof 1")

	//full plate
	call SetTableData(ItemData, 'I0BV', "level 380 armor 8000 str 2000 regen 6000 mr 5 prof 2")
	call SetTableData(ItemData, 'I0K4', "level 384 armor 10000 str 2500 regen 7500 mr 5 prof 2")
	call SetTableData(ItemData, 'I0K5', "level 388 armor 12000 str 3000 regen 9000 mr 5 prof 2")
	call SetTableData(ItemData, 'I0K6', "level 392 armor 16000 str 4000 regen 11000 mr 10 prof 2")
	call SetTableData(ItemData, 'I0K7', "level 396 armor 20000 str 5000 regen 13000 mr 10 prof 2")
	call SetTableData(ItemData, 'I0K8', "level 400 armor 24000 str 6000 regen 15000 mr 10 prof 2")
	call SetTableData(ItemData, 'I0K9', "level 400 armor 32000 str 8000 regen 17000 mr 15 prof 2")
	call SetTableData(ItemData, 'I0KA', "level 400 armor 40000 str 10000 regen 19000 mr 15 prof 2")
	call SetTableData(ItemData, 'I0KB', "level 400 armor 48000 str 12000 regen 22000 mr 15 prof 2")

	//leather
	call SetTableData(ItemData, 'I0BK', "level 380 armor 4000 agi 20000 mr 10 prof 3")
	call SetTableData(ItemData, 'I0KC', "level 384 armor 5000 agi 25000 mr 10 prof 3")
	call SetTableData(ItemData, 'I0KD', "level 388 armor 6000 agi 30000 mr 10 prof 3")
	call SetTableData(ItemData, 'I0KE', "level 392 armor 8000 agi 40000 mr 20 prof 3")
	call SetTableData(ItemData, 'I0KF', "level 396 armor 10000 agi 50000 mr 20 prof 3")
	call SetTableData(ItemData, 'I0KG', "level 400 armor 12000 agi 60000 mr 20 prof 3")
	call SetTableData(ItemData, 'I0KH', "level 400 armor 16000 agi 80000 mr 30 prof 3")
	call SetTableData(ItemData, 'I0KI', "level 400 armor 20000 agi 100000 mr 30 prof 3")
	call SetTableData(ItemData, 'I0KJ', "level 400 armor 24000 agi 120000 mr 30 prof 3")

	//robe
	call SetTableData(ItemData, 'I0BI', "level 380 armor 4000 int 25000 mr 10 prof 4")
	call SetTableData(ItemData, 'I0KK', "level 384 armor 4800 int 30000 mr 10 prof 4")
	call SetTableData(ItemData, 'I0KL', "level 388 armor 5600 int 35000 mr 10 prof 4")
	call SetTableData(ItemData, 'I0KM', "level 392 armor 7200 int 45000 mr 20 prof 4")
	call SetTableData(ItemData, 'I0KN', "level 396 armor 8800 int 55000 mr 20 prof 4")
	call SetTableData(ItemData, 'I0KO', "level 400 armor 10400 int 65000 mr 20 prof 4")
	call SetTableData(ItemData, 'I0KP', "level 400 armor 13600 int 85000 mr 30 prof 4")
	call SetTableData(ItemData, 'I0KQ', "level 400 armor 16800 int 105000 mr 30 prof 4")
	call SetTableData(ItemData, 'I0KR', "level 400 armor 20000 int 125000 mr 30 prof 4")

	//hammer
	call SetTableData(ItemData, 'I0BB', "level 380 damage 70000 str 20000 spellboost 7 crit 4 chance 30 prof 6")
	call SetTableData(ItemData, 'I0KS', "level 384 damage 87500 str 25000 spellboost 8 crit 4 chance 30 prof 6")
	call SetTableData(ItemData, 'I0KT', "level 388 damage 105000 str 30000 spellboost 9 crit 4 chance 30 prof 6")
	call SetTableData(ItemData, 'I0KU', "level 392 damage 140000 str 40000 spellboost 10 crit 7 chance 30 prof 6")
	call SetTableData(ItemData, 'I0KV', "level 396 damage 175000 str 50000 spellboost 11 crit 7 chance 30 prof 6")
	call SetTableData(ItemData, 'I0KW', "level 400 damage 210000 str 60000 spellboost 12 crit 7 chance 30 prof 6")
	call SetTableData(ItemData, 'I0KX', "level 400 damage 280000 str 80000 spellboost 13 crit 10 chance 30 prof 6")
	call SetTableData(ItemData, 'I0KY', "level 400 damage 350000 str 100000 spellboost 14 crit 10 chance 30 prof 6")
	call SetTableData(ItemData, 'I0KZ', "level 400 damage 420000 str 120000 spellboost 15 crit 10 chance 30 prof 6")

	//annihilation sword
	call SetTableData(ItemData, 'I0BC', "level 380 damage 125000 str 10000 spellboost 7 crit 4 chance 30 prof 7")
	call SetTableData(ItemData, 'I0L0', "level 384 damage 150000 str 12500 spellboost 8 crit 4 chance 30 prof 7")
	call SetTableData(ItemData, 'I0L1', "level 388 damage 175000 str 15000 spellboost 9 crit 4 chance 30 prof 7")
	call SetTableData(ItemData, 'I0L2', "level 392 damage 225000 str 20000 spellboost 10 crit 7 chance 30 prof 7")
	call SetTableData(ItemData, 'I0L3', "level 396 damage 275000 str 25000 spellboost 11 crit 7 chance 30 prof 7")
	call SetTableData(ItemData, 'I0L4', "level 400 damage 325000 str 30000 spellboost 12 crit 7 chance 30 prof 7")
	call SetTableData(ItemData, 'I0L5', "level 400 damage 425000 str 40000 spellboost 13 crit 10 chance 30 prof 7")
	call SetTableData(ItemData, 'I0L6', "level 400 damage 525000 str 50000 spellboost 14 crit 10 chance 30 prof 7")
	call SetTableData(ItemData, 'I0L7', "level 400 damage 625000 str 60000 spellboost 15 crit 10 chance 30 prof 7")

	//dagger
	call SetTableData(ItemData, 'I0BE', "level 380 damage 60000 agi 30000 spellboost 7 crit 4 chance 30 prof 8")
	call SetTableData(ItemData, 'I0L8', "level 384 damage 76500 agi 38250 spellboost 8 crit 4 chance 30 prof 8")
	call SetTableData(ItemData, 'I0L9', "level 388 damage 93000 agi 46500 spellboost 9 crit 4 chance 30 prof 8")
	call SetTableData(ItemData, 'I0LA', "level 392 damage 126000 agi 63000 spellboost 10 crit 7 chance 30 prof 8")
	call SetTableData(ItemData, 'I0LB', "level 396 damage 159000 agi 79500 spellboost 11 crit 7 chance 30 prof 8")
	call SetTableData(ItemData, 'I0LC', "level 400 damage 192000 agi 96000 spellboost 12 crit 7 chance 30 prof 8")
	call SetTableData(ItemData, 'I0LD', "level 400 damage 258000 agi 129000 spellboost 13 crit 10 chance 30 prof 8")
	call SetTableData(ItemData, 'I0LE', "level 400 damage 324000 agi 162000 spellboost 14 crit 10 chance 30 prof 8")
	call SetTableData(ItemData, 'I0LF', "level 400 damage 390000 agi 195000 spellboost 15 crit 10 chance 30 prof 8")

	//spirit bow
	call SetTableData(ItemData, 'I0B9', "level 380 damage 100000 agi 20000 spellboost 7 crit 4 chance 30 prof 9")
	call SetTableData(ItemData, 'I0LG', "level 384 damage 125000 agi 24000 spellboost 8 crit 4 chance 30 prof 9")
	call SetTableData(ItemData, 'I0LH', "level 388 damage 150000 agi 28000 spellboost 9 crit 4 chance 30 prof 9")
	call SetTableData(ItemData, 'I0LI', "level 392 damage 200000 agi 36000 spellboost 10 crit 7 chance 30 prof 9")
	call SetTableData(ItemData, 'I0LJ', "level 396 damage 250000 agi 44000 spellboost 11 crit 7 chance 30 prof 9")
	call SetTableData(ItemData, 'I0LK', "level 400 damage 300000 agi 52000 spellboost 12 crit 7 chance 30 prof 9")
	call SetTableData(ItemData, 'I0LL', "level 400 damage 400000 agi 68000 spellboost 13 crit 10 chance 30 prof 9")
	call SetTableData(ItemData, 'I0LM', "level 400 damage 500000 agi 84000 spellboost 14 crit 10 chance 30 prof 9")
	call SetTableData(ItemData, 'I0LN', "level 400 damage 600000 agi 100000 spellboost 15 crit 10 chance 30 prof 9")

	//staff
	call SetTableData(ItemData, 'I0BG', "level 380 damage 50000 int 50000 spellboost 9 prof 10")
	call SetTableData(ItemData, 'I0LO', "level 384 damage 60000 int 57500 spellboost 11 prof 10")
	call SetTableData(ItemData, 'I0LP', "level 388 damage 70000 int 65000 spellboost 13 prof 10")
	call SetTableData(ItemData, 'I0LQ', "level 392 damage 90000 int 80000 spellboost 15 prof 10")
	call SetTableData(ItemData, 'I0LR', "level 396 damage 110000 int 95000 spellboost 17 prof 10")
	call SetTableData(ItemData, 'I0LS', "level 400 damage 130000 int 110000 spellboost 19 prof 10")
	call SetTableData(ItemData, 'I0LT', "level 400 damage 170000 int 140000 spellboost 21 prof 10")
	call SetTableData(ItemData, 'I0LU', "level 400 damage 210000 int 170000 spellboost 23 prof 10")
	call SetTableData(ItemData, 'I0LV', "level 400 damage 250000 int 200000 spellboost 25 prof 10")

	//sphere
	call SetTableData(ItemData, 'I06M', "level 380 health 2000000 stats 20000 regen 5000")
	call SetTableData(ItemData, 'I0LW', "level 384 health 2000000 stats 30000 regen 7000")
	call SetTableData(ItemData, 'I0LX', "level 388 health 2000000 stats 40000 regen 9000")

   	//Lexium Crystal
	call SetTableData(ItemData, 'I0CH', "level 360 movespeed 200 int 20000 spellboost 2 gold 60")
	call SetTableData(ItemData, 'I01L', "level 365 movespeed 250 int 30000 spellboost 4 gold 65")
    call SetTableData(ItemData, 'I01N', "level 370 movespeed 300 int 40000 spellboost 6 gold 70")
    call SetTableData(ItemData, 'I0NT', "level 375 movespeed 350 int 50000 spellboost 8 gold 75")
    call SetTableData(ItemData, 'I0NP', "level 380 movespeed 400 int 60000 spellboost 10 gold 80")
    call SetTableData(ItemData, 'I0NQ', "level 385 movespeed 450 int 70000 spellboost 12 gold 85")
    call SetTableData(ItemData, 'I0NR', "level 390 movespeed 500 int 80000 spellboost 14 gold 90")
    call SetTableData(ItemData, 'I0NS', "level 395 movespeed 500 int 90000 spellboost 16 gold 95")
    call SetTableData(ItemData, 'I019', "level 400 movespeed 500 int 100000 spellboost 20 gold 100")

	//Vigor Gem
    call SetTableData(ItemData, 'I0O1', "level 360 str 20000 dr 10 regen 5000 gold 60")
    call SetTableData(ItemData, 'I0O0', "level 365 str 30000 dr 11 regen 10000 gold 65")
    call SetTableData(ItemData, 'I0NZ', "level 370 str 40000 dr 12 regen 15000 gold 70")
    call SetTableData(ItemData, 'I0NY', "level 375 str 50000 dr 13 regen 20000 gold 75")
    call SetTableData(ItemData, 'I0O2', "level 380 str 60000 dr 14 regen 25000 gold 80")
    call SetTableData(ItemData, 'I0NX', "level 385 str 70000 dr 15 regen 30000 gold 85")
    call SetTableData(ItemData, 'I0NV', "level 390 str 80000 dr 16 regen 35000 gold 90")
    call SetTableData(ItemData, 'I0NU', "level 395 str 90000 dr 17 regen 40000 gold 95")
    call SetTableData(ItemData, 'I0NW', "level 400 str 100000 dr 20 regen 50000 gold 100")
	
    //Torture Jewel
    call SetTableData(ItemData, 'I0OB', "level 360 agi 20000 mr 10 bat 10 spellboost 2 gold 60")
    call SetTableData(ItemData, 'I0O9', "level 365 agi 30000 mr 11 bat 11 spellboost 3 gold 65")
    call SetTableData(ItemData, 'I0O8', "level 370 agi 40000 mr 12 bat 12 spellboost 4 gold 70")
    call SetTableData(ItemData, 'I0OA', "level 375 agi 50000 mr 13 bat 13 spellboost 5 gold 75")
    call SetTableData(ItemData, 'I0O4', "level 380 agi 60000 mr 14 bat 14 spellboost 6 gold 80")
    call SetTableData(ItemData, 'I0O5', "level 385 agi 70000 mr 15 bat 15 spellboost 7 gold 85")
    call SetTableData(ItemData, 'I0O7', "level 390 agi 80000 mr 16 bat 16 spellboost 8 gold 90")
    call SetTableData(ItemData, 'I0O6', "level 395 agi 90000 mr 17 bat 17 spellboost 9 gold 95")
    call SetTableData(ItemData, 'I0O3', "level 400 agi 100000 mr 20 bat 20 spellboost 10 gold 100")

	//misc
	call SetTableData(ItemData, 'I0D0', "level 240 damage 40000 stats 5000 regen 1200 spellboost 10 gold 20") //struggle ring
	call SetTableData(ItemData, 'I04Z', "level 270 damage 47000 armor 800 regen 800") //ore
	call SetTableData(ItemData, 'I050', "level 275 damage 140000 armor 2000 stats 10000 regen 2000 spellboost 3") //necklace
	call SetTableData(ItemData, 'I05U', "level 1337 armor 420000 regen 82000") //armor of sin
	call SetTableData(ItemData, 'I014', "level 1337 damage 15000000") //weapon of sin
	call SetTableData(ItemData, 'I0NN', "level 400") //prestige token

	//demons
	call SetTableData(ItemData, 'I073', "level 175 armor 350 str 600 regen 280 prof 1")
	call SetTableData(ItemData, 'I075', "level 175 armor 560 str 40 regen 200 prof 2")
	call SetTableData(ItemData, 'I06Z', "level 175 armor 350 agi 1000 prof 3")
	call SetTableData(ItemData, 'I06W', "level 175 armor 280 int 1150 prof 4")
	call SetTableData(ItemData, 'I04T', "level 175 damage 6000 str 1200 prof 6")
	call SetTableData(ItemData, 'I06S', "level 175 damage 11000 prof 7")
	call SetTableData(ItemData, 'I06U', "level 175 damage 5000 agi 2000 prof 8")
	call SetTableData(ItemData, 'I06O', "level 175 damage 10400 agi 600 prof 9")
	call SetTableData(ItemData, 'I06Q', "level 175 damage 2500 int 2200 prof 10")

    //demon prince
	call SetTableData(ItemData, 'I03F', "level 190 damage 15800 str 4900 prof 6")
	call SetTableData(ItemData, 'I04S', "level 190 damage 43000 prof 7")
	call SetTableData(ItemData, 'I020', "level 190 damage 15400 agi 9200 prof 8")
	call SetTableData(ItemData, 'I016', "level 190 damage 32200 agi 4900 prof 9")
	call SetTableData(ItemData, 'I0AK', "level 190 int 10300 spellboost 5 prof 10")
	call SetTableData(ItemData, 'I0N4', "level 190 armor 1000 str 2000 prof 5")
	call SetTableData(ItemData, 'I0N5', "level 190 armor 800 str 750 agi 1500 prof 3")
	call SetTableData(ItemData, 'I0N6', "level 190 armor 750 str 500 int 2500 prof 4")
	call SetTableData(ItemData, 'I0OF', "level 190 damage 7000 armor 200 stats 1200 crit 4 chance 30" ) //demon golem fist

	//horror
	call SetTableData(ItemData, 'I07E', "level 200 armor 470 str 810 regen 380 prof 1")
	call SetTableData(ItemData, 'I07I', "level 200 armor 760 str 50 regen 270 prof 2")
	call SetTableData(ItemData, 'I07G', "level 200 armor 470 agi 1350 prof 3")
	call SetTableData(ItemData, 'I07C', "level 200 armor 380 int 1550 prof 4")
	call SetTableData(ItemData, 'I07A', "level 200 damage 8100 str 1620 prof 6")
	call SetTableData(ItemData, 'I07M', "level 200 damage 14850 prof 7")
	call SetTableData(ItemData, 'I07L', "level 200 damage 6750 agi 2700 prof 8")
	call SetTableData(ItemData, 'I07P', "level 200 damage 14040 agi 810 prof 9")
	call SetTableData(ItemData, 'I077', "level 200 damage 3380 int 2970 prof 10")

	call SetTableData(ItemData, 'I07K', "level 200 regen 700")
	call SetTableData(ItemData, 'I05D', "level 200 armor 470")

	//despair
	call SetTableData(ItemData, 'I087', "level 220 armor 640 str 1090 regen 510 prof 1")
	call SetTableData(ItemData, 'I089', "level 220 armor 1020 str 70 regen 360 prof 2")
	call SetTableData(ItemData, 'I083', "level 220 armor 640 agi 1820 prof 3")
	call SetTableData(ItemData, 'I081', "level 220 armor 510 int 2100 prof 4")
	call SetTableData(ItemData, 'I07X', "level 220 damage 10940 str 2190 prof 6")
	call SetTableData(ItemData, 'I07V', "level 220 damage 20050 prof 7")
	call SetTableData(ItemData, 'I07Z', "level 220 damage 9110 agi 3650 prof 8")
	call SetTableData(ItemData, 'I07R', "level 220 damage 18950 agi 1090 prof 9")
	call SetTableData(ItemData, 'I07T', "level 220 damage 4560 int 4010 prof 10")

	call SetTableData(ItemData, 'I05O', "level 220 stats 2000")
	call SetTableData(ItemData, 'I05P', "level 220 regen 1000")

	//absolute horror
	call SetTableData(ItemData, 'I0NG', "level 230 armor 2200 str 5200 prof 1")
	call SetTableData(ItemData, 'I0NA', "level 230 movespeed -25 armor 4700 str 6000 prof 2")
	call SetTableData(ItemData, 'I0NH', "level 230 armor 1900 agi 14000 prof 3")
	call SetTableData(ItemData, 'I0NI', "level 230 armor 1800 int 26000 prof 4")
	call SetTableData(ItemData, 'I0NB', "level 230 damage 38000 str 8500 prof 6")
	call SetTableData(ItemData, 'I0NF', "level 230 damage 95000 str 5000 prof 7")
	call SetTableData(ItemData, 'I0ND', "level 230 damage 36000 agi 24000 prof 8")
	call SetTableData(ItemData, 'I0NC', "level 230 damage 78000 agi 11500 prof 9")
	call SetTableData(ItemData, 'I0NE', "level 230 damage 26000 int 24000 prof 10")

	//abyss
	call SetTableData(ItemData, 'I09X', "level 240 armor 860 str 1480 regen 690 prof 1")
	call SetTableData(ItemData, 'I0A0', "level 240 armor 1380 str 100 regen 490 prof 2")
	call SetTableData(ItemData, 'I0A2', "level 240 armor 860 agi 2460 prof 3")
	call SetTableData(ItemData, 'I0A5', "level 240 armor 690 int 2830 prof 4")
	call SetTableData(ItemData, 'I06D', "level 240 damage 14760 str 2950 prof 6")
	call SetTableData(ItemData, 'I06A', "level 240 damage 27060 prof 7")
	call SetTableData(ItemData, 'I06B', "level 240 damage 12300 agi 4920 prof 8")
	call SetTableData(ItemData, 'I06C', "level 240 damage 25590 agi 1480 prof 9")
	call SetTableData(ItemData, 'I09N', "level 240 damage 6150 int 5410 prof 10")

	//void
	call SetTableData(ItemData, 'I08S', "level 260 armor 1160 str 1990 regen 930 prof 1")
	call SetTableData(ItemData, 'I08U', "level 260 armor 1860 str 130 regen 660 prof 2")
	call SetTableData(ItemData, 'I08O', "level 260 armor 1160 agi 3320 prof 3")
	call SetTableData(ItemData, 'I08M', "level 260 armor 930 int 3820 prof 4")
	call SetTableData(ItemData, 'I08D', "level 260 damage 19930 str 3990 prof 6")
	call SetTableData(ItemData, 'I08C', "level 260 damage 36540 prof 7")
	call SetTableData(ItemData, 'I08J', "level 260 damage 16610 agi 6640 prof 8")
	call SetTableData(ItemData, 'I08H', "level 260 damage 34540 agi 1990 prof 9")
	call SetTableData(ItemData, 'I08G', "level 260 damage 8300 int 7310 prof 10")

	call SetTableData(ItemData, 'I04Y', "level 260 stats 3320")
	call SetTableData(ItemData, 'I04W', "level 260 armor 1160")
	call SetTableData(ItemData, 'I08N', "level 260 regen 2000")
	call SetTableData(ItemData, 'I055', "level 260 damage 10000 stats 400 crit 4 chance 30")

	//nightmare
	call SetTableData(ItemData, 'I0A7', "level 280 armor 1570 str 2690 regen 1260 prof 1")
	call SetTableData(ItemData, 'I0A9', "level 280 armor 2510 str 180 regen 900 prof 2")
	call SetTableData(ItemData, 'I0AC', "level 280 armor 1570 agi 4480 prof 3")
	call SetTableData(ItemData, 'I0AB', "level 280 armor 1260 int 5160 prof 4")
	call SetTableData(ItemData, 'I09V', "level 280 damage 26900 str 5400 prof 6")
	call SetTableData(ItemData, 'I09P', "level 280 damage 49300 prof 7")
	call SetTableData(ItemData, 'I09R', "level 280 damage 22400 agi 9000 prof 8")
	call SetTableData(ItemData, 'I09S', "level 280 damage 46600 agi 2700 prof 9")
	call SetTableData(ItemData, 'I09T', "level 280 damage 11200 int 9900 prof 10")

	//hell
	call SetTableData(ItemData, 'I097', "level 300 armor 2100 str 3600 regen 1700 prof 1")
	call SetTableData(ItemData, 'I05H', "level 300 armor 3400 str 240 regen 1200 prof 2")
	call SetTableData(ItemData, 'I098', "level 300 armor 2100 agi 6100 prof 3")
	call SetTableData(ItemData, 'I095', "level 300 armor 1700 int 7000 prof 4")
	call SetTableData(ItemData, 'I08W', "level 300 damage 36300 str 7300 prof 6")
	call SetTableData(ItemData, 'I05G', "level 300 damage 66600 prof 7")
	call SetTableData(ItemData, 'I08Z', "level 300 damage 30300 agi 12100 prof 8")
	call SetTableData(ItemData, 'I091', "level 300 damage 63000 agi 3600 prof 9")
	call SetTableData(ItemData, 'I093', "level 300 damage 15100 int 13300 prof 10")

	call SetTableData(ItemData, 'I05I', "level 300 stats 6300 crit 5 chance 30")

	//existence
	call SetTableData(ItemData, 'I09U', "level 320 armor 2900 str 4900 regen 2300 prof 1")
	call SetTableData(ItemData, 'I09W', "level 320 armor 4600 str 320 regen 1600 prof 2")
	call SetTableData(ItemData, 'I09Q', "level 320 armor 2900 agi 8200 prof 3")
	call SetTableData(ItemData, 'I09O', "level 320 armor 2300 int 9400 prof 4")
	call SetTableData(ItemData, 'I09M', "level 320 damage 49000 str 9800 prof 6")
	call SetTableData(ItemData, 'I09K', "level 320 damage 89900 prof 7")
	call SetTableData(ItemData, 'I09I', "level 320 damage 40900 agi 16300 prof 8")
	call SetTableData(ItemData, 'I09G', "level 320 damage 85000 agi 4900 prof 9")
	call SetTableData(ItemData, 'I09E', "level 320 damage 20400 int 18000 prof 10")

	call SetTableData(ItemData, 'I09Y', "level 320 health 500000")

	//astral
	call SetTableData(ItemData, 'I0AL', "level 340 armor 3900 str 6600 regen 3100 prof 1")
	call SetTableData(ItemData, 'I0AN', "level 340 armor 6200 str 440 regen 2200 prof 2")
	call SetTableData(ItemData, 'I0AA', "level 340 armor 3900 agi 11000 prof 3")
	call SetTableData(ItemData, 'I0A8', "level 340 armor 3100 int 12700 prof 4")
	call SetTableData(ItemData, 'I0A6', "level 340 damage 66200 str 13200 prof 6")
	call SetTableData(ItemData, 'I0A3', "level 340 damage 121400 prof 7")
	call SetTableData(ItemData, 'I0A1', "level 340 damage 55200 agi 22100 prof 8")
	call SetTableData(ItemData, 'I0A4', "level 340 damage 114700 agi 6600 prof 9")
	call SetTableData(ItemData, 'I09Z', "level 340 damage 27600 int 24300 prof 10")

	//dimensional
	call SetTableData(ItemData, 'I0AY', "level 360 armor 5600 str 9500 regen 3200 prof 1")
	call SetTableData(ItemData, 'I0B0', "level 360 armor 8900 str 640 regen 3200 prof 2")
	call SetTableData(ItemData, 'I0B2', "level 360 armor 5600 agi 15900 prof 3")
	call SetTableData(ItemData, 'I0B3', "level 360 armor 4400 int 18300 prof 4")
	call SetTableData(ItemData, 'I0AQ', "level 360 damage 95300 str 19100 prof 6")
	call SetTableData(ItemData, 'I0AO', "level 360 damage 174800 prof 7")
	call SetTableData(ItemData, 'I0AT', "level 360 damage 79400 agi 31800 prof 8")
	call SetTableData(ItemData, 'I0AR', "level 360 damage 165200 agi 9500 prof 9")
	call SetTableData(ItemData, 'I0AW', "level 360 damage 39700 int 35000 prof 10")

	//demon (set)
	call SetTableData(ItemData, 'I0BN', "level 190 movespeed -25 damage 8700 armor 1100 str 1200 stats 600 regen 400 spellboost 2 prof 6")
	call SetTableData(ItemData, 'I0CK', "level 190 damage 22000 armor 500 str 600 stats 600 regen 300 spellboost 2 prof 7")
	call SetTableData(ItemData, 'I0BO', "level 190 damage 8500 armor 500 agi 4500 stats 600 regen 150 spellboost 2 prof 8")
	call SetTableData(ItemData, 'I0CU', "level 190 damage 17600 armor 500 agi 2100 stats 600 regen 150 spellboost 2 prof 9")
	call SetTableData(ItemData, 'I0CT', "level 190 damage 4200 armor 400 int 5000 stats 600 spellboost 2 prof 10")

	//horror (set)
	call SetTableData(ItemData, 'I0C2', "level 210 movespeed -25 damage 11700 armor 1500 str 1600 stats 800 regen 500 spellboost 2 prof 6")
	call SetTableData(ItemData, 'I0CV', "level 210 damage 29700 armor 700 str 800 stats 800 regen 400 spellboost 2 prof 7")
	call SetTableData(ItemData, 'I0C1', "level 210 damage 11400 armor 700 agi 6000 stats 800 regen 200 spellboost 2 prof 8")
	call SetTableData(ItemData, 'I0CW', "level 210 damage 23800 armor 700 agi 2800 stats 800 regen 200 spellboost 2 prof 9")
	call SetTableData(ItemData, 'I0CX', "level 210 damage 5700 armor 600 int 6800 stats 800 regen 160 spellboost 2 prof 10")

	//despair (set)
	call SetTableData(ItemData, 'I0BQ', "level 230 movespeed -25 damage 15800 armor 2000 str 2150 stats 1050 regen 700 spellboost 3 prof 6")
	call SetTableData(ItemData, 'I0CY', "level 230 damage 40100 armor 900 str 1050 stats 1050 regen 600 spellboost 3 prof 7")
	call SetTableData(ItemData, 'I0BP', "level 230 damage 15400 armor 1000 agi 8150 stats 1050 regen 300 spellboost 3 prof 8")
	call SetTableData(ItemData, 'I0CZ', "level 230 damage 32200 armor 1000 agi 3850 stats 1050 regen 300 spellboost 3 prof 9")
	call SetTableData(ItemData, 'I0D3', "level 230 damage 7700 armor 800 int 9250 stats 1050 regen 240 spellboost 3 prof 10")

	//abyss
	call SetTableData(ItemData, 'I0C8', "level 250 movespeed -25 damage 21000 armor 2700 str 2900 stats 1500 regen 1000 spellboost 3 prof 6")
	call SetTableData(ItemData, 'I0C9', "level 250 damage 54000 armor 1200 str 1400 stats 1500 regen 800 spellboost 3 prof 7")
	call SetTableData(ItemData, 'I0C7', "level 250 damage 20000 armor 1400 agi 11000 stats 1500 regen 400 spellboost 3 prof 8")
	call SetTableData(ItemData, 'I0C6', "level 250 damage 43000 armor 1400 agi 5100 stats 1500 regen 400 spellboost 3 prof 9")
	call SetTableData(ItemData, 'I0C5', "level 250 damage 10400 armor 1100 int 12500 stats 1500 regen 320 spellboost 3 prof 10")

	//void
	call SetTableData(ItemData, 'I0C4', "level 270 movespeed -25 damage 28000 armor 3700 str 3900 stats 2000 regen 1300 spellboost 4 prof 6")
	call SetTableData(ItemData, 'I0D7', "level 270 damage 73000 armor 1700 str 1900 stats 2000 regen 1100 spellboost 4 crit 4 chance 20 prof 7")
	call SetTableData(ItemData, 'I0C3', "level 270 damage 25000 armor 1700 agi 13000 stats 2000 regen 500 spellboost 4 crit 4 chance 20 prof 8")
	call SetTableData(ItemData, 'I0D5', "level 270 damage 53000 armor 1700 agi 6000 stats 2000 regen 500 spellboost 4 crit 4 chance 20 prof 9")
	call SetTableData(ItemData, 'I0D6', "level 270 damage 14100 armor 1500 int 16900 stats 2000 regen 440 spellboost 4 prof 10")

	//nightmare
	call SetTableData(ItemData, 'I0CA', "level 290 movespeed -25 damage 39000 armor 5000 str 5500 stats 2600 regen 1800 spellboost 4 prof 6")
	call SetTableData(ItemData, 'I0CB', "level 290 damage 98000 armor 2300 str 2700 stats 2600 regen 1500 spellboost 4 crit 4 chance 20 prof 7")
	call SetTableData(ItemData, 'I0CD', "level 290 damage 38000 armor 2600 agi 20300 stats 2600 regen 750 spellboost 4 crit 4 chance 20 prof 8")
	call SetTableData(ItemData, 'I0CE', "level 290 damage 79000 armor 2600 agi 9600 stats 2600 regen 750 spellboost 4 crit 4 chance 20 prof 9")
	call SetTableData(ItemData, 'I0CF', "level 290 damage 19000 armor 2100 int 23000 stats 2600 regen 600 spellboost 4 prof 10")

	//hell
	call SetTableData(ItemData, 'I0BW', "level 310 movespeed -25 damage 45000 armor 6200 str 6500 stats 3300 regen 2200 spellboost 5 prof 6")
	call SetTableData(ItemData, 'I0D8', "level 310 damage 115000 armor 2600 str 3000 stats 3000 regen 1700 spellboost 5 crit 5 chance 20 prof 7")
	call SetTableData(ItemData, 'I0BU', "level 310 damage 45000 armor 3000 agi 22700 stats 3300 regen 1000 spellboost 5 crit 5 chance 20 prof 8")
	call SetTableData(ItemData, 'I0DK', "level 310 damage 90000 armor 3000 agi 11200 stats 3300 regen 1000 spellboost 5 crit 5 chance 20 prof 9")
	call SetTableData(ItemData, 'I0DJ', "level 310 damage 22000 armor 2500 int 27700 stats 3300 regen 800 spellboost 5 prof 10")

	//existence
	call SetTableData(ItemData, 'I0BT', "level 330 movespeed -25 damage 71000 armor 9200 str 9800 stats 4900 regen 3400 spellboost 5 prof 6")
	call SetTableData(ItemData, 'I0DX', "level 330 damage 179000 armor 4300 str 4900 stats 4900 regen 2700 spellboost 5 crit 6 chance 20 prof 7")
	call SetTableData(ItemData, 'I0BR', "level 330 damage 69000 armor 4900 agi 36700 stats 4900 regen 1350 spellboost 5 crit 6 chance 20 prof 8")
	call SetTableData(ItemData, 'I0DL', "level 330 damage 144000 armor 4900 agi 17300 stats 4900 regen 1350 spellboost 5 crit 6 chance 20 prof 9")
	call SetTableData(ItemData, 'I0DY', "level 330 damage 34600 armor 3900 int 41600 stats 4900 regen 1080 spellboost 5 prof 10")

	//astral
	call SetTableData(ItemData, 'I0BM', "level 350 movespeed -25 damage 95000 armor 12400 str 13200 stats 6600 regen 4400 spellboost 6 prof 6")
	call SetTableData(ItemData, 'I0E0', "level 350 damage 242000 armor 5800 str 6600 stats 6600 regen 3700 spellboost 6 crit 7 chance 20 prof 7")
	call SetTableData(ItemData, 'I0DZ', "level 350 damage 93000 armor 6600 agi 49600 stats 6600 regen 1850 spellboost 6 crit 7 chance 20 prof 8")
	call SetTableData(ItemData, 'I059', "level 350 damage 194000 armor 6600 agi 23300 stats 6600 regen 1850 spellboost 6 crit 7 chance 20 prof 9")
	call SetTableData(ItemData, 'I0E1', "level 350 damage 46900 armor 5200 int 56300 stats 6600 regen 1480 spellboost 6 prof 10")

	//dimensional
	call SetTableData(ItemData, 'I0FH', "level 370 movespeed -25 damage 129000 armor 16600 str 17900 stats 8900 regen 6100 spellboost 6 prof 6")
	call SetTableData(ItemData, 'I0CG', "level 370 damage 349000 armor 8400 str 9500 stats 9500 regen 5400 spellboost 6 crit 8 chance 20 prof 7")
	call SetTableData(ItemData, 'I0CI', "level 370 damage 126000 armor 8800 agi 67100 stats 8900 regen 2550 spellboost 6 crit 8 chance 20 prof 8")
	call SetTableData(ItemData, 'I0FI', "level 370 damage 263000 armor 8800 agi 31500 stats 8900 regen 2550 spellboost 6 crit 8 chance 20 prof 9")
	call SetTableData(ItemData, 'I0FZ', "level 370 damage 63200 armor 7100 int 75900 stats 8900 regen 2040 spellboost 6 prof 10")

	//prechaos
	call SetTableData(ItemData, 'I01D', "movespeed 150") //good shoes
	call SetTableData(ItemData, 'I03O', "level 60 evasion 8 crit 8 chance 8") //sassy brawler
	call SetTableData(ItemData, 'I03E', "level 50 movespeed 250 spellboost 10") //shopkeeper necklace
	call SetTableData(ItemData, 'I01Z', "damage 10") //claws of lightning
	call SetTableData(ItemData, 'I00T', "level 130 damage 2500 stats 500 regen 190 spellboost 10") //lesser ring of struggle
	call SetTableData(ItemData, 'oli2', "level 50 damage 1110") //nerubian orb
	call SetTableData(ItemData, 'I043', "level 75 damage 850 crit 2 chance 25") //omega p's pick
	call SetTableData(ItemData, 'I02X', "level 75 damage 100 crit 2 chance 20") //brian's pick
	call SetTableData(ItemData, 'I02Y', "level 75 damage 100") //pinky's pick

	call SetTableData(ItemData, 'I04N', "level 100 armor 150 agi 250 prof 3") //hooded hide hiding cloak
	call SetTableData(ItemData, 'I074', "level 100 damage 1110 crit 3 chance 30 prof 8") //runic white blade
	call SetTableData(ItemData, 'I0EY', "level 100 damage 1110 crit 3 chance 30 prof 9") //runic white bow
	call SetTableData(ItemData, 'I0EX', "level 100 movespeed 120 agi 600 crit 4 chance 30") //dragoon wings
	call SetTableData(ItemData, 'I0F4', "level 130 movespeed 150 damage 1000 armor 150 agi 1000 spellboost 10 prof 3") //dragoon set

	call SetTableData(ItemData, 'I0FC', "level 100 damage 750 str 480 prof 6") //dwarven warhammer
	call SetTableData(ItemData, 'I07B', "level 100 armor 230 regen 190 prof 5") //dwarven woven chainmail
	call SetTableData(ItemData, 'I079', "level 100 damage 1350 str 240 prof 7") //dwarven axe
	call SetTableData(ItemData, 'I08K', "level 130 damage 1100 str 860 armor 230 regen 280 spellboost 10 prof 5") //dwarven set

	call SetTableData(ItemData, 'I07F', "level 100 armor 120 int 420 prof 4") //mysterious cloak
	call SetTableData(ItemData, 'I0F3', "level 100 int 630 prof 10") //orb of mist
	call SetTableData(ItemData, 'I03U', "level 100 int 420 spellboost 5") //pendant of the forgotten
	call SetTableData(ItemData, 'I0F5', "level 130 int 1930 armor 120 mr 20 spellboost 10 prof 4") //forgotten mystic set

	call SetTableData(ItemData, 'I0FA', "level 120 damage 520 int 900 prof 10") //hellfire staff
	call SetTableData(ItemData, 'I0FU', "level 120 armor 120 int 760 prof 4") //hellfire robe
	call SetTableData(ItemData, 'I03Y', "level 120 armor 220 mr 40") //hellfire shield

	call SetTableData(ItemData, 'I0C0', "level 140 armor 200 agi 800") //paladin's greaves
	call SetTableData(ItemData, 'I0F9', "level 140 int 1050") //paladin's holy book
	call SetTableData(ItemData, 'I0FX', "level 140 armor 370 str 490") //paladin's holy plate
	call SetTableData(ItemData, 'I03P', "level 130 damage 740 str 480") //paladin's hammer

	call SetTableData(ItemData, 'I01B', "level 100 armor 180 regen 190 evasion 10") //ancient bark
	call SetTableData(ItemData, 'I03Z', "level 100 damage 1160") //da's dingo
	call SetTableData(ItemData, 'I038', "regen 800") //cheese shield
	call SetTableData(ItemData, 'I03X', "level 100 damage 1160 regen 190") //corrupted essence
	call SetTableData(ItemData, 'I09F', "level 75") //sea wards

	call SetTableData(ItemData, 'I078', "level 75 armor 160 str 150 prof 1") //minotaur's armor
	call SetTableData(ItemData, 'I07U', "level 75 armor 150 agi 250 prof 3") //minotaur's leather
	call SetTableData(ItemData, 'I076', "level 75 armor 130 int 300 prof 4") //minotaur's cloth
	call SetTableData(ItemData, 'I03T', "level 75 damage 1160") //minotaur's axe
	call SetTableData(ItemData, 'I0FW', "level 75 str 420") //ring of the minotaur

	call SetTableData(ItemData, 'I00A', "level 120 damage 370 stats 370") //old broken god's scepter

	call SetTableData(ItemData, 'I02Z', "level 130 armor 430 str 510") //aura of hate
	call SetTableData(ItemData, 'I031', "level 130 int 1000") //aura of knowledge
	call SetTableData(ItemData, 'I030', "level 130 agi 740 damage 500") //aura of love
	call SetTableData(ItemData, 'I04I', "level 130 stats 777 regen 220") //aura of life
	call SetTableData(ItemData, 'I04J', "level 160 damage 700 armor 430 stats 1350 regen 220") //aura of gods
	call SetTableData(ItemData, 'I0NJ', "level 160") //drum of war

	call SetTableData(ItemData, 'I02O', "level 120 regen 190 res 100 recharge 1 cost 1000") //godslayer's cloak
	call SetTableData(ItemData, 'I02B', "level 120 damage 1160 str 250 crit 1 chance 20 prof 7") //savior's sword
	call SetTableData(ItemData, 'I02C', "level 120 armor 310 str 190") //savior's armor
	call SetTableData(ItemData, 'I029', "level 120 damage 740 agi 550 crit 2 chance 25") //savior's dagger
	call SetTableData(ItemData, 'I0JR', "level 130 damage 1150 armor 310 regen 190 str 440 res 100 recharge 1 cost 15000 crit 1 chance 25") //godslayer set

	call SetTableData(ItemData, 'I04B', "level 100") //jewel of the horde
	call SetTableData(ItemData, 'I09L', "level 75 movespeed 200 evasion 10") //serpent hide boots

	//blacksmith quests

	call SetTableData(ItemData, 'I0B8', "level 15 armor 39 str 47 prof 1") //chitin plate armor
	call SetTableData(ItemData, 'I0BA', "level 15 armor 84 prof 2") //chitin heavy plate
	call SetTableData(ItemData, 'I0B4', "level 15 armor 39 agi 74 prof 3") //stretchy spider silk suit
	call SetTableData(ItemData, 'I0B6', "level 15 armor 31 int 84 prof 4") //spidersilk robe

	call SetTableData(ItemData, 'I0F8', "level 50 armor 110 regen 100") //hydra scale armor
	call SetTableData(ItemData, 'I02N', "level 50 damage 260 str 170 prof 6") //hydra spear
	call SetTableData(ItemData, 'I072', "level 50 damage 770 prof 7") //hydra sword
	call SetTableData(ItemData, 'I06Y', "level 50 damage 260 agi 260 prof 8") //hydra dagger
	call SetTableData(ItemData, 'I070', "level 50 damage 570 agi 130 prof 9") //hydra bow
	call SetTableData(ItemData, 'I071', "level 50 damage 180 int 290 prof 10") //hydra talisman

	call SetTableData(ItemData, 'I048', "level 100 armor 250 str 300 prof 1") //dragonhide plate
	call SetTableData(ItemData, 'I02U', "level 100 armor 400 prof 2") //dragonbone full plate
	call SetTableData(ItemData, 'I064', "level 100 armor 200 agi 400 prof 3") //dragonhide swift armor
	call SetTableData(ItemData, 'I02P', "level 100 armor 150 int 550 prof 4") //dragonhide cloak
	call SetTableData(ItemData, 'I033', "level 100 damage 400 str 400 prof 6") //dragonbone greatsword

	call SetTableData(ItemData, 'I0BZ', "level 100 damage 1110 str 180 prof 7") //dragonfire sword
	call SetTableData(ItemData, 'I02S', "level 100 damage 400 agi 400 prof 8") //dragonfire dagger
	call SetTableData(ItemData, 'I032', "level 100 damage 1100 agi 180 prof 9") //dragonfire bow
	call SetTableData(ItemData, 'I065', "level 100 damage 260 int 700 prof 10") //dragonfire orb

	//magnataur
	call SetTableData(ItemData, 'sor9', "level 70 armor 120 str 110 prof 1") //magnataur hide plate
	call SetTableData(ItemData, 'shcw', "level 70 armor 240 prof 2") //magnataur hide full plate
	call SetTableData(ItemData, 'shrs', "level 70 armor 120 agi 190 prof 3") //forgotten one's leather jacket
	call SetTableData(ItemData, 'sor4', "level 70 armor 90 int 220 prof 4") //forgotten one's cloth
	call SetTableData(ItemData, 'sor7', "level 70 armor 130") //magnataur shield

	//centaur
	call SetTableData(ItemData, 'dthb', "level 60 damage 220 str 140 prof 6") //centaur axe
	call SetTableData(ItemData, 'phlt', "level 60 damage 655 prof 7") //centaur blade
	call SetTableData(ItemData, 'engs', "level 60 damage 220 agi 220 prof 8") //centaur dagegr
	call SetTableData(ItemData, 'kygh', "level 60 damage 490 agi 110 prof 9") //centaur bow (shitty id)
	call SetTableData(ItemData, 'bzbf', "level 60 damage 155 int 250 prof 10") //centaur wand

	//hellhound
	call SetTableData(ItemData, 'ram1', "level 50 damage 168 str 109 prof 6") //molten hammer
	call SetTableData(ItemData, 'srbd', "level 50 damage 500 prof 7") //searing blade (shitty id)
	call SetTableData(ItemData, 'horl', "level 50 damage 170 agi 170 prof 8") //flaming dagger
	call SetTableData(ItemData, 'ram2', "level 50 damage 380 agi 84 prof 9") //fiery bow (shitty id)
	call SetTableData(ItemData, 'ram4', "level 50 damage 118 int 193 prof 10") //fire orb
	call SetTableData(ItemData, 'I0MA', "level 50 damage 160 crit 2 chance 25") //flame sigil

	//unbroken
	call SetTableData(ItemData, 'I0MB', "level 40 armor 60") //unbroken shield
	call SetTableData(ItemData, 'I01W', "level 40 armor 60 str 55 prof 1") //unbroken plate
	call SetTableData(ItemData, 'I0FS', "level 40 armor 115 prof 2") //unbroken full plate
	call SetTableData(ItemData, 'I0FY', "level 40 armor 60 agi 95 prof 3") //unbroken leather
	call SetTableData(ItemData, 'I0FR', "level 40 armor 45 int 105 prof 4") //unbroken cloth

	//ogre
	call SetTableData(ItemData, 'I0FD', "level 25 armor 39 str 37 prof 1") //ogre's armor
	call SetTableData(ItemData, 'I08R', "level 25 armor 80 prof 2") //ogre's heavy armor
	call SetTableData(ItemData, 'I07Y', "level 25 armor 39 agi 60 prof 3") //tauren's leather
	call SetTableData(ItemData, 'I07W', "level 25 armor 31 int 70 prof 4") //ogre's cloth
	call SetTableData(ItemData, 'I08I', "level 25 damage 95 str 60 prof 6") //ogre's club
	call SetTableData(ItemData, 'I08B', "level 25 damage 280 prof 7") //ogre's blade
	call SetTableData(ItemData, 'I08F', "level 25 damage 95 agi 95 prof 8") //tauren's dagger
	call SetTableData(ItemData, 'I08E', "level 25 damage 210 agi 47 prof 9") //tauren's arrows
	call SetTableData(ItemData, 'I0FE', "level 25 damage 65 int 105 prof 10") //ogre's staff

	//mammoth
	call SetTableData(ItemData, 'I035', "level 15 armor 21 str 22 prof 1") //bear hide armor
	call SetTableData(ItemData, 'I0FQ', "level 15 armor 43 prof 2") //mammoth hide armor
	call SetTableData(ItemData, 'I0FO', "level 15 armor 21 agi 33 prof 3") //bear skin coat
	call SetTableData(ItemData, 'I07O', "level 15 armor 16 int 39 prof 4") //bear fur robe
	call SetTableData(ItemData, 'I06V', "level 15 damage 52 str 34 prof 6") //mammoth bone club
	call SetTableData(ItemData, 'I00X', "level 15 damage 156 prof 7") //mammoth bone sword
	call SetTableData(ItemData, 'I013', "level 15 damage 52 agi 52 prof 8") //bear claws
	call SetTableData(ItemData, 'I0FP', "level 15 damage 117 agi 26 prof 9") //mammoth tusk bow
	call SetTableData(ItemData, 'I017', "level 15 damage 36 int 60 prof 10") //bear bone wand
	
	call SetTableData(ItemData, 'I0MC', "level 25 armor 40") //polar shield
	call SetTableData(ItemData, 'I0MD', "level 20 damage 120 crit 2 chance 20") //polar fang

	//ursa
	call SetTableData(ItemData, 'I0FF', "level 7 armor 21") //ursa fur coat
	call SetTableData(ItemData, 'I034', "level 7 damage 26 str 17 prof 6") //ursa bone club
	call SetTableData(ItemData, 'I06T', "level 7 damage 78 prof 7") //ursa bone sword
	call SetTableData(ItemData, 'I0FG', "level 7 damage 26 agi 26 prof 8") //ursa claws
	call SetTableData(ItemData, 'I06R', "level 7 damage 58 agi 13 prof 9") //ursa razor arrows
	call SetTableData(ItemData, 'I0FT', "level 7 damage 18 int 30 prof 10") //ursa shamanic rod

	//stuff
	call SetTableData(ItemData, 'I036', "level 100 stats 600") //chronos stone
	call SetTableData(ItemData, 'I04C', "level 50 damage 1100") //king's club
	call SetTableData(ItemData, 'I02Q', "level 50 damage 280 armor 18") //iron golem ore
	call SetTableData(ItemData, 'I046', "level 75 damage 1000 armor 100 stats 350 crit 3 chance 30") //iron golem fist
	call SetTableData(ItemData, 'I02J', "level 50") //white flames
	call SetTableData(ItemData, 'I01T', "level 50 armor 120") //armor of the gods
	call SetTableData(ItemData, 'rnsp', "level 20 armor 18 stats 40 regen 18") //waug's ring
	call SetTableData(ItemData, 'I025', "level 15 armor 9") //greater mask of death
	call SetTableData(ItemData, 'I02L', "level 15 stats 40") //great circlet
	call SetTableData(ItemData, 'I01M', "level 20 damage 280") //axe of smiting
	call SetTableData(ItemData, 'I00B', "level 25 damage 336 agi 50") //axe of speed
	call SetTableData(ItemData, 'I0FL', "level 7 armor 18") //mythril shield
	call SetTableData(ItemData, 'I00F', "level 6 damage 22 str 14 prof 6") //mythril spear
	call SetTableData(ItemData, 'I0FK', "level 7 damage 65 prof 7") //mythril sword
	call SetTableData(ItemData, 'I010', "level 7 damage 22 agi 22 prof 8") //mythril dagger
	call SetTableData(ItemData, 'I03Q', "level 4 movespeed 100") //horse boost

	call SetTableData(ItemData, 'I0FM', "level 7 damage 49 agi 11 prof 9") //blood elven bow
	call SetTableData(ItemData, 'I00C', "level 10 armor 25 int 35") //armour of the battlemage
	call SetTableData(ItemData, 'sora', "level 6 damage 30 stats 6") //noble blade
	call SetTableData(ItemData, 'I03L', "level 40") //castle of the gods
	call SetTableData(ItemData, 'I0FB', "level 20 movespeed 175 armor 20") //arctic treads
	call SetTableData(ItemData, 'rlif', "level 3 regen 10") //ring of regeneration
	call SetTableData(ItemData, 'rde2', "level 3 health 500 regen 3") //ring of health
	call SetTableData(ItemData, 'ofro', "level 7 damage 15 int 25 prof 10") //orb of the omni
	call SetTableData(ItemData, 'I00Y', "level 15") //ring of health

	//homes
	call SetTableData(ItemData, 'I03L', "level 40") //castle of the gods
	call SetTableData(ItemData, 'I086', "level 150") //lounge

	//level 0
	call SetTableData(ItemData, 'sor1', "int 24") //sparky orb
	call SetTableData(ItemData, 'frgd', "dr 15") //leech shield (shitty id)
	call SetTableData(ItemData, 'mcou', "stats 10") //medallion of courage
	call SetTableData(ItemData, 'rag1', "agi 8") //slipper of agility
	call SetTableData(ItemData, 'rin1', "int 8") //mantle of intelligence
	call SetTableData(ItemData, 'rst1', "str 5") //gaunlets of strength
	call SetTableData(ItemData, 'I01U', "armor 6") //footman's helm
	call SetTableData(ItemData, 'I0FJ', "armor 3") //wooden shield
	call SetTableData(ItemData, 'I03N', "res 10") //extra lives
	call SetTableData(ItemData, 'I01X', "stats 5 res 10 recharge 1 cost 75") //sword of revival

	call SetTableData(ItemData, 'I01S', "movespeed 100 armor 5") //seven league boots
	call SetTableData(ItemData, 'ratf', "damage 12 str 8 prof 6") //steel lance
	call SetTableData(ItemData, 'brac', "damage 36 prof 7") //steel sword
	call SetTableData(ItemData, 'odef', "damage 12 agi 12 prof 8") //steel dagger
	call SetTableData(ItemData, 'rhth', "damage 27 agi 6 prof 9") //long bow

	call SetTableData(ItemData, 'rat9', "armor 5 agi 8 prof 3") //leather jacket (shitty id)
	call SetTableData(ItemData, 'prvt', "health 1000") //leather jacket (shitty id)
	call SetTableData(ItemData, 'sor2', "armor 5 int 10 prof 4") //tattered cloth
	call SetTableData(ItemData, 'I004', "armor 5 str 5 prof 5") //steel plate
	call SetTableData(ItemData, 'ratc', "damage 8 str 5 prof 6") //iron broadsword
	call SetTableData(ItemData, 'cnob', "damage 24 prof 7") //iron sword
	call SetTableData(ItemData, 'gcel', "damage 8 agi 8 prof 8") //iron dagger
	call SetTableData(ItemData, 'rat6', "damage 18 agi 4 prof 9") //short bow
	call SetTableData(ItemData, 'hcun', "armor 10") //steel shield
	call SetTableData(ItemData, 'rde1', "armor 6") //iron shield
	call SetTableData(ItemData, 'kpin', "damage 8 int 14 prof 10") //arcane staff
	call SetTableData(ItemData, 'hval', "damage 6 int 9 prof 10") //wooden staff
	call SetTableData(ItemData, 'belv', "agi 12") //boots of the ranger
	call SetTableData(ItemData, 'ciri', "int 12") //sigil of magic
	call SetTableData(ItemData, 'bgst', "str 8") //belt of the giant
	call SetTableData(ItemData, 'evtl', "evasion 10") //talisman of evasion

	//sets
	//ursine
	call SetTableData(ItemData, 'I0H6', "level 20 movespeed -25 damage 40 armor 70 str 15 stats 15 prof 6")
	call SetTableData(ItemData, 'I0H5', "level 20 damage 140 armor 40 str 30 stats 15 prof 7")
	call SetTableData(ItemData, 'I0H7', "level 20 damage 40 armor 40 agi 95 stats 15 prof 8")
	call SetTableData(ItemData, 'I0H8', "level 20 damage 100 armor 40 agi 65 stats 15 prof 9")
	call SetTableData(ItemData, 'I0H9', "level 20 damage 40 armor 30 int 105 stats 15 prof 10")

	//ogre
	call SetTableData(ItemData, 'I0HA', "level 30 damage 480 armor 65 str 50 stats 30 prof 7")
	call SetTableData(ItemData, 'I0HB', "level 30 movespeed -25 damage 160 armor 140 str 100 stats 30 prof 6")
	call SetTableData(ItemData, 'I0HC', "level 30 damage 160 armor 65 agi 240 stats 30 prof 8")
	call SetTableData(ItemData, 'I0HD', "level 30 damage 360 armor 65 agi 160 stats 30 prof 9")
	call SetTableData(ItemData, 'I0HE', "level 30 damage 130 armor 55 int 270 stats 30 prof 10")

	//unbroken
	call SetTableData(ItemData, 'I0HF', "level 50 damage 870 armor 105 str 60 stats 60 prof 7")
	call SetTableData(ItemData, 'I0HG', "level 50 movespeed -25 damage 290 armor 200 str 180 stats 60 prof 6")
	call SetTableData(ItemData, 'I0HH', "level 50 damage 290 armor 105 agi 400 stats 60 prof 8")
	call SetTableData(ItemData, 'I0HI', "level 50 damage 660 armor 105 agi 250 stats 60 prof 9")
	call SetTableData(ItemData, 'I0HJ', "level 50 damage 240 armor 80 int 460 stats 60 prof 10")

	//magnataur
	call SetTableData(ItemData, 'I0HK', "level 70 damage 1130 armor 210 str 155 stats 95 prof 7")
	call SetTableData(ItemData, 'I0HL', "level 70 movespeed -25 damage 380 armor 410 str 205 stats 95 prof 6")
	call SetTableData(ItemData, 'I0HM', "level 70 damage 380 armor 210 agi 615 stats 95 prof 8")
	call SetTableData(ItemData, 'I0HN', "level 70 damage 850 armor 210 agi 425 stats 95 prof 9")
	call SetTableData(ItemData, 'I0HO', "level 70 damage 310 armor 165 int 715 stats 95 prof 10")
endfunction

function GoldReward takes nothing returns nothing
	set udg_RewardUnits[0] = 'nitt' // Ice Troll Trapper
	set udg_RewardUnits[1] = 'nits' // Ice Troll Berserker, 4
	set udg_RewardUnits[2] = 'ntkw' // Tuskar Warrior
	set udg_RewardUnits[3] = 'ntks' // Tuskar sorc
	set udg_RewardUnits[4] = 'ntkc' // Tuskar Chieftain
	set udg_RewardUnits[5] = 'nnwr' // Nerub Seer
	set udg_RewardUnits[6] = 'nnws' // Nerub spider lord
	set udg_RewardUnits[7] = 'nfpu' // Polar Furbolg Warrior
	set udg_RewardUnits[8] = 'nfpe' // Polar Furbolg shaman
	set udg_RewardUnits[9] = 'nmdr' // Dire Mammoth
	set udg_RewardUnits[10] = 'nplg' // Giant Polar Bear
	set udg_RewardUnits[11] = 'nfor' // Unbroken Trickster
	set udg_RewardUnits[12] = 'nubw' // Unbroken Darkweaver
	set udg_RewardUnits[13] = 'nfod' // Unbroken Deathbringer
	set udg_RewardUnits[14] = 'n01G' // Ogre Overlord
	set udg_RewardUnits[15] = 'o01G' // Tauren
	set udg_RewardUnits[16] = 'nvdl' // Hellfire Spawn
	set udg_RewardUnits[17] = 'nvdw' // Hellhound
	set udg_RewardUnits[18] = 'n024' // Centaur Ranger
	set udg_RewardUnits[19] = 'n027' // Centaur Lancer
	set udg_RewardUnits[20] = 'n028' // Centaur Mage
	set udg_RewardUnits[21] = 'n01H' // hydra
	set udg_RewardUnits[22] = 'n01M' // Magnataur destroyer
	set udg_RewardUnits[23] = 'n08M' // Forgotten One
	set udg_RewardUnits[24] = 'n01R' // Frost Drake
	set udg_RewardUnits[25] = 'n02P' // Frost Dragon
	set udg_RewardUnits[26] = 'n02L' // Medean Devourer
	set udg_RewardUnits[27] = 'n02M' // Devourling
	set udg_RewardUnits[28] = 'n033' // Demon
	set udg_RewardUnits[29] = 'n034' // Demon Wizard
	set udg_RewardUnits[30] = 'n03C' // Horror Young
	set udg_RewardUnits[31] = 'n03A' // Horror Mindless
	set udg_RewardUnits[32] = 'n03B' // Horror Leader
	set udg_RewardUnits[33] = 'n03F' // Despair
	set udg_RewardUnits[34] = 'n01W' // Despair Wizard
	set udg_RewardUnits[35] = 'n00X' // Abyssal Beast
	set udg_RewardUnits[36] = 'n08N' // Abyssal Guardian
	set udg_RewardUnits[37] = 'n00W' // Abyssal Siren
	set udg_RewardUnits[38] = 'n031' // void keeper
	set udg_RewardUnits[39] = 'n02Z' // void mother
	set udg_RewardUnits[40] = 'n030' // Void seeker
	set udg_RewardUnits[41] = 'n020' // Nightmare Creature
	set udg_RewardUnits[42] = 'n02J' // Nightmare Spirit
	set udg_RewardUnits[43] = 'n03E' // Spawn of Hell
	set udg_RewardUnits[44] = 'n03D' // spawn of death
	set udg_RewardUnits[45] = 'n03G' // Lord of Plague
	set udg_RewardUnits[46] = 'n03J' // Denied Existence
	set udg_RewardUnits[47] = 'n01X' // Deprived Existence
	set udg_RewardUnits[48] = 'n03M' // Astral Being
	set udg_RewardUnits[49] = 'n01V' // Astral Entity
    set udg_RewardUnits[50] = 'n026' // Planeswalker
	set udg_RewardUnits[51] = 'n03T' // Planeshifter
	set udg_RewardUnits[52] = 'n03I' // Sin
	set udg_PermanentInteger[6] = 52

	set BossUnit[0] = 'H02H' //paladin
	set BossGold[0] = 9000
	set BossXplvl[0] = 220
	set BossUnit[1] = 'O002' //tauren
	set BossGold[1] = 6100
	set BossXplvl[1] = 165
	set BossUnit[2] = 'U00G' //trifire
	set BossGold[2] = 10100
	set BossXplvl[2] = 220
	set BossUnit[3] = 'H045' //mistic
	set BossGold[3] = 6100
	set BossXplvl[3] = 180
	set BossUnit[4] = 'O01B' //dragoon
	set BossGold[4] = 7100
	set BossXplvl[4] = 200
	set BossUnit[5] = 'n098' //med queen
	set BossGold[5] = 2100
	set BossXplvl[5] = 150
	set BossUnit[6] = 'H020' //naga
	set BossGold[6] = 3100
	set BossXplvl[6] = 165
	set BossUnit[7] = 'H01V' //mountain king
	set BossGold[7] = 7100
	set BossXplvl[7] = 220
	set BossUnit[8] = 'H040' //death knight
	set BossGold[8] = 9100
	set BossXplvl[8] = 220
    set BossUnit[9] = 'N038' //demon prince
	set BossGold[9] = 40100
	set BossXplvl[9] = 250
    set BossUnit[10] = 'N017' //absolute horror
	set BossGold[10] = 90100
	set BossXplvl[10] = 300
	set BossUnit[11] = 'O02B' //slaughter queen
	set BossGold[11] = 150100
	set BossXplvl[11] = 390
	set BossUnit[12] = 'O02H' //essence of darkness
	set BossGold[12] = 250100
	set BossXplvl[12] = 405
	set BossUnit[13] = 'O02I' //Satan
	set BossGold[13] = 500100
	set BossXplvl[13] = 425
	set BossUnit[14] = 'O02K' // Thanatos
	set BossGold[14] = 600100
	set BossXplvl[14] = 440
	set BossUnit[15] = 'H04R' // Legion
	set BossGold[15] = 600100
	set BossXplvl[15] = 455
	set BossUnit[16] = 'O02M' // Existence
	set BossGold[16] = 800100
	set BossXplvl[16] = 480
    set BossUnit[17] = 'O03G' // Forgotten Leader
    set BossGold[17] = 1000100
	set BossXplvl[17] = 500
    set BossUnit[18] = 'O02T' // Azazoth
    set BossGold[18] = 1200100
	set BossXplvl[18] = 510
	
	set udg_PermanentInteger[12] = 18

	set udg_Gold_Mod[1] = 1
	set udg_Gold_Mod[2] = Pow(0.55, 0.5)
	set udg_Gold_Mod[3] = Pow(0.50, 0.5)
	set udg_Gold_Mod[4] = Pow(0.45, 0.5)
	set udg_Gold_Mod[5] = Pow(0.40, 0.5)
	set udg_Gold_Mod[6] = Pow(0.35, 0.5)
endfunction

function StringSetup takes nothing returns nothing
	set infostring[0]="Use -info # for see more info about your chosen catagory\n\n -info 1, Unit Respawning\n -info 2, Boss Respawning\n -info 3, Safezone\n -info 4, Hardcore\n -info 5, Hardmode\n -info 6, Prestige\n -info 7, Proficiency\n -info 8, Boss Item Discounts"
	set infostring[1]="Most units in this game (besides Bosses, Colosseum, Struggle) will attempt to revive where they died 30 seconds after death. If a player hero/unit is within 800 range they will spawn frozen and invulnerable until no players are around."
	set infostring[2]="Bosses respawn after 10 minutes and non-hero bosses respawn after 5 minutes, -hardmode speeds up respawns by 25%" 
	set infostring[3]="The town is protected from enemy invasion and any entering enemy will be teleported back to their original spawn."
	set infostring[4]="Hardcore players that die without an ankh of reincarnation will be removed from the game and cannot save/load or start a new character. 
    A hardcore hero can only save every 30 minutes- the timer starts upon saving OR upon loading your hardcore hero. 
    Hardcore heroes receive double the bonus from prestiging.
    If you need to save before the timer expires you can use -forcesave to save immediately, but this deletes your hero, leaving you unable to load again in the current game (same as if your hero died)."
	set infostring[5]="Hardmode doubles the health and damage of bosses, doubles their drop chance, increases their gold/xp/crystal rewards, and speeds up respawn time by 25%.
    Does not apply to Dungeons.
    Automatically turns off when entering Chaos, but can be re-activated."
	set infostring[6]="You need a |cffffcc00Prestige Token|r to activate a class prestige bonus.\nPrestige bonuses apply to all your existing characters and any new ones.\n|cffffcc00BONUSES:|r\nAttack Damage(+8%): Bloodzerker, Phoenix Ranger, Elite Marksman\nStrength(+6%): Oblivion Guardian, Savior, Warrior\nAgility(+7%): Master Rogue, Assassin, Vampire Lord\nIntelligence(+7%): Dark Summoner, Bard, Dark Savior\nDamage Reduction(+5%): Royal Guardian, Arcane Warrior\nRegeneration(+8%): Priest\nSpellboost(+4%): Elementalist, Arcanist, Thunderblade, Hydromancer\n|cffffcc00ALL:|r Experience Rate(+4%), Gold Find(+2%)"
	set infostring[7]="Most items in this game have a proficiency requirement in their description.
    While any hero can equip them regardless of proficiency, those lacking proficiency only recieve half stats from the item.
    Check your hero's proficiency with -pf."
	set infostring[8]="Many Boss items can now be upgraded at a discount if you have the correct item in your hero/backpack while upgrading.
    The item is sacrificed to obtain this discount and you can tell if an item qualifies for a discount under Item Info."
	set infostring[9]=""
	set infostring[10]="You lack the proficiency (-pf) to use this item, it will only give half of the stats.\n|cffFF0000You will stop getting this warning at level 15.|r"
	set infostring[69]="Nice"
endfunction

function SetupCosts takes integer i,integer spot returns nothing
	set UpItemCostPlat[i]    = upPcost[spot]
	set UpItemCostArc[i]     = upLcost[spot]
	set UpItemCostCrys[i]    = upCcost[spot]
	set UpgradeCostFactor[i] = cfactor
endfunction

function ItemUpgrades takes nothing returns nothing
	local integer i = 0

	//boss item upgrades
	//set cfactor to adjust discount (default 2)

	//Slaughter Queen Weapons (go to rare?)
	set upPcost[0] = 2 //+1
	set upLcost[0] = 1
	set upCcost[0] = 0
	set upPcost[1] = 5 //+2
	set upLcost[1] = 3
	set upCcost[1] = 1
	set upPcost[2] = 8 //rare
	set upLcost[2] = 5
	set upCcost[2] = 2
	set upPcost[3] = 11 //+1
	set upLcost[3] = 7
	set upCcost[3] = 3
	set upPcost[4] = 14 //+2
	set upLcost[4] = 9
	set upCcost[4] = 4

	set UpItem[i] = 'I0AE'
	set UpItemBecomes[i] = 'I090'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0AE'
	set i = i + 1
	set UpItem[i] = 'I090'
	set UpItemBecomes[i] = 'I092'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0AE'
	set i = i + 1
	set UpItem[i] = 'I092'
	set UpItemBecomes[i] = 'I0BF'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0AE'
	set i = i + 1
	set UpItem[i] = 'I0BF'
	set UpItemBecomes[i] = 'I0AM'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0AE'
	set i = i + 1
	set UpItem[i] = 'I0AM'
	set UpItemBecomes[i] = 'I0BH'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0AE'
	set i = i + 1
	set UpItem[i] = 'I04F'
	set UpItemBecomes[i] = 'I099'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I04F'
	set i = i + 1
	set UpItem[i] = 'I099'
	set UpItemBecomes[i] = 'I09A'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I04F'
	set i = i + 1
	set UpItem[i] = 'I09A'
	set UpItemBecomes[i] = 'I0OR'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I04F'
	set i = i + 1
	set UpItem[i] = 'I0OR'
	set UpItemBecomes[i] = 'I0OS'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I04F'
	set i = i + 1
	set UpItem[i] = 'I0OS'
	set UpItemBecomes[i] = 'I0OT'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I04F'
	set i = i + 1
	set UpItem[i] = 'I0AF'
	set UpItemBecomes[i] = 'I08X'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0AF'
	set i = i + 1
	set UpItem[i] = 'I08X'
	set UpItemBecomes[i] = 'I08Y'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0AF'
	set i = i + 1
	set UpItem[i] = 'I08Y'
	set UpItemBecomes[i] = 'I0OM'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0AF'
	set i = i + 1
	set UpItem[i] = 'I0OM'
	set UpItemBecomes[i] = 'I0OS'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0AF'
	set i = i + 1
	set UpItem[i] = 'I0OS'
	set UpItemBecomes[i] = 'I0OT'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0AF'
	set i = i + 1
	set UpItem[i] = 'I0AD'
	set UpItemBecomes[i] = 'I04X'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0AD'
	set i = i + 1
	set UpItem[i] = 'I04X'
	set UpItemBecomes[i] = 'I056'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0AD'
	set i = i + 1
	set UpItem[i] = 'I056'
	set UpItemBecomes[i] = 'I01R'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0AD'
	set i = i + 1
	set UpItem[i] = 'I01R'
	set UpItemBecomes[i] = 'I02T'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0AD'
	set i = i + 1
	set UpItem[i] = 'I02T'
	set UpItemBecomes[i] = 'I0OL'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0AD'
	set i = i + 1
	set UpItem[i] = 'I0AG'
	set UpItemBecomes[i] = 'I094'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0AG'
	set i = i + 1
	set UpItem[i] = 'I094'
	set UpItemBecomes[i] = 'I096'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0AG'
	set i = i + 1
	set UpItem[i] = 'I096'
	set UpItemBecomes[i] = 'I0BD'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0AG'
	set i = i + 1
	set UpItem[i] = 'I0BD'
	set UpItemBecomes[i] = 'I0OS'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0AG'
	set i = i + 1
	set UpItem[i] = 'I0OS'
	set UpItemBecomes[i] = 'I0OT'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0AG'
	set i = i + 1

    //Dark Bulwark
	set upPcost[0] = 16 //+1
	set upLcost[0] = 18
	set upCcost[0] = 4
	set upPcost[1] = 32 //+2
	set upLcost[1] = 16
	set upCcost[1] = 8

	set UpItem[i] = 'I0AP'
	set UpItemBecomes[i] = 'I021'
	call SetupCosts(i, 0)
	set UpDiscountItem[i] = 'I0AP'
	set i = i + 1
    set UpItem[i] = 'I021'
	set UpItemBecomes[i] = 'I03K'
	call SetupCosts(i, 1)
	set UpDiscountItem[i] = 'I0AP'
	set i = i + 1

	//Dark Soul
	set upPcost[0] = 4 //+1
	set upLcost[0] = 2
	set upCcost[0] = 1
	set upPcost[1] = 6 //+2
	set upLcost[1] = 3
	set upCcost[1] = 1
	set upPcost[2] = 14 //rare
	set upLcost[2] = 12
	set upCcost[2] = 6
	set upPcost[3] = 16 //+1
	set upLcost[3] = 10
	set upCcost[3] = 7
	set upPcost[4] = 24 //+2
	set upLcost[4] = 14
	set upCcost[4] = 12
	set upPcost[5] = 30 //legendary
	set upLcost[5] = 14
	set upCcost[5] = 14
    set upPcost[6] = 50 //+1
	set upLcost[6] = 20
	set upCcost[6] = 30
    set upPcost[7] = 60 //+2
	set upLcost[7] = 30
	set upCcost[7] = 50

	set UpItem[i] = 'I05A'
	set UpItemBecomes[i] = 'I05Z'
	call SetupCosts(i, 0)
	set UpDiscountItem[i] = 'I05A'
	set i = i + 1
	set UpItem[i] = 'I05Z'
	set UpItemBecomes[i] = 'I0D4'
	call SetupCosts(i, 1)
	set UpDiscountItem[i] = 'I05A'
	set i = i + 1
	set UpItem[i] = 'I0D4'
	set UpItemBecomes[i] = 'I06K'
	call SetupCosts(i, 2)
	set UpDiscountItem[i] = 'I05A'
	set i = i + 1
	set UpItem[i] = 'I06K'
	set UpItemBecomes[i] = 'I0EH'
	call SetupCosts(i, 3)
	set UpDiscountItem[i] = 'I06K'
	set i = i + 1
	set UpItem[i] = 'I0EH'
	set UpItemBecomes[i] = 'I0EI'
	call SetupCosts(i, 4)
	set UpDiscountItem[i] = 'I06K'
	set i = i + 1
	set UpItem[i] = 'I0EI'
	set UpItemBecomes[i] = 'I06L'
	call SetupCosts(i, 5)
	set UpDiscountItem[i] = 'I06K'
	set i = i + 1
	set UpItem[i] = 'I06L'
	set UpItemBecomes[i] = 'I0EJ'
	call SetupCosts(i, 6)
	set UpDiscountItem[i] = 'I06K'
	set i = i + 1
	set UpItem[i] = 'I0EJ'
	set UpItemBecomes[i] = 'I0EK'
	call SetupCosts(i, 7)
	set UpDiscountItem[i] = 'I06K'
	set i = i + 1

	//Thanatos Wings
	set upPcost[0] = 24 //+1
	set upLcost[0] = 16
	set upCcost[0] = 8
	set upPcost[1] = 32 //+2
	set upLcost[1] = 22
	set upCcost[1] = 12
	set upPcost[2] = 40 //rare
	set upLcost[2] = 28
	set upCcost[2] = 16
	set upPcost[3] = 48 //+1
	set upLcost[3] = 34
	set upCcost[3] = 20
	set upPcost[4] = 56 //+2
	set upLcost[4] = 40
	set upCcost[4] = 24
	set upPcost[5] = 64 //legendary
	set upLcost[5] = 46
	set upCcost[5] = 28
    set upPcost[6] = 72 //+1
	set upLcost[6] = 52
	set upCcost[6] = 32
    set upPcost[7] = 80 //+2
	set upLcost[7] = 58
	set upCcost[7] = 36
    set upPcost[8] = 88 //+3
	set upLcost[8] = 64
	set upCcost[8] = 40
    set upPcost[9] = 104 //+4
	set upLcost[9] = 76
	set upCcost[9] = 48

	set UpItem[i] = 'I04E'
	set UpItemBecomes[i] = 'I062'
	call SetupCosts(i, 0)
	set UpDiscountItem[i] = 'I04E'
	set i = i + 1
	set UpItem[i] = 'I062'
	set UpItemBecomes[i] = 'I0EL'
	call SetupCosts(i, 1)
	set UpDiscountItem[i] = 'I04E'
	set i = i + 1
	set UpItem[i] = 'I0EL'
	set UpItemBecomes[i] = 'I00P'
	call SetupCosts(i, 2)
	set UpDiscountItem[i] = 'I04E'
	set i = i + 1
	set UpItem[i] = 'I00P'
	set UpItemBecomes[i] = 'I0EM'
	call SetupCosts(i, 3)
	set UpDiscountItem[i] = 'I00P'
	set i = i + 1
	set UpItem[i] = 'I0EM'
	set UpItemBecomes[i] = 'I0EN'
	call SetupCosts(i, 4)
	set UpDiscountItem[i] = 'I00P'
	set i = i + 1
	set UpItem[i] = 'I0EN'
	set UpItemBecomes[i] = 'I00Q'
	call SetupCosts(i, 5)
	set UpDiscountItem[i] = 'I00P'
	set i = i + 1
	set UpItem[i] = 'I00Q'
	set UpItemBecomes[i] = 'I06E'
	call SetupCosts(i, 6)
	set UpDiscountItem[i] = 'I00P'
	set i = i + 1
	set UpItem[i] = 'I06E'
	set UpItemBecomes[i] = 'I06F'
	call SetupCosts(i, 7)
	set UpDiscountItem[i] = 'I00P'
	set i = i + 1
	set UpItem[i] = 'I06F'
	set UpItemBecomes[i] = 'I06G'
	call SetupCosts(i, 8)
	set UpDiscountItem[i] = 'I00P'
	set i = i + 1
	set UpItem[i] = 'I06G'
	set UpItemBecomes[i] = 'I06H'
	call SetupCosts(i, 9)
	set UpDiscountItem[i] = 'I00P'
	set i = i + 1

	//Satan's Heart
	set upPcost[0] = 9 //+1
	set upLcost[0] = 6
	set upCcost[0] = 3
	set upPcost[1] = 18 //+2
	set upLcost[1] = 12
	set upCcost[1] = 6

	set UpItem[i] = 'I0BX'
	set UpItemBecomes[i] = 'I0OC'
	call SetupCosts(i, 0)
	set UpDiscountItem[i] = 'I0BX'
	set i = i + 1
	set UpItem[i] = 'I0OC'
	set UpItemBecomes[i] = 'I0OD'
	call SetupCosts(i, 1)
	set UpDiscountItem[i] = 'I0BX'
	set i = i + 1

	//Satan's Ace
	set upPcost[0] = 4 //+1
	set upLcost[0] = 2
	set upCcost[0] = 1
	set upPcost[1] = 6 //+2
	set upLcost[1] = 3
	set upCcost[1] = 2
	set upPcost[2] = 12 //rare
	set upLcost[2] = 3
	set upCcost[2] = 12
	set upPcost[3] = 20 //+1
	set upLcost[3] = 12
	set upCcost[3] = 8
	set upPcost[4] = 27 //+2
	set upLcost[4] = 14
	set upCcost[4] = 14
	set upPcost[5] = 96 //legendary
	set upLcost[5] = 22
	set upCcost[5] = 112
    set upPcost[6] = 90 //+1
	set upLcost[6] = 37
	set upCcost[6] = 30
    set upPcost[7] = 120 //+2
	set upLcost[7] = 50
	set upCcost[7] = 50

	set UpItem[i] = 'I05J'
	set UpItemBecomes[i] = 'I04O'
	call SetupCosts(i, 0)
	set UpDiscountItem[i] = 'I05J'
	set i = i + 1
	set UpItem[i] = 'I04O'
	set UpItemBecomes[i] = 'I07H'
	call SetupCosts(i, 1)
	set UpDiscountItem[i] = 'I05J'
	set i = i + 1
	set UpItem[i] = 'I07H'
	set UpItemBecomes[i] = 'I00R'
	call SetupCosts(i, 2)
	set UpDiscountItem[i] = 'I05J'
	set i = i + 1
	set UpItem[i] = 'I00R'
	set UpItemBecomes[i] = 'I00N'
	call SetupCosts(i, 3)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1
	set UpItem[i] = 'I00N'
	set UpItemBecomes[i] = 'I00O'
	call SetupCosts(i, 4)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1
	set UpItem[i] = 'I00O'
	set UpItemBecomes[i] = 'I00S'
	call SetupCosts(i, 5)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1
	set UpItem[i] = 'I00S'
	set UpItemBecomes[i] = 'I07J'
	call SetupCosts(i, 6)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1
	set UpItem[i] = 'I07J'
	set UpItemBecomes[i] = 'I07N'
	call SetupCosts(i, 7)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1

	//Chaos Shield
	set upPcost[0] = 60 //+1
	set upLcost[0] = 40
	set upCcost[0] = 20
	set upPcost[1] = 90 //+2
	set upLcost[1] = 60
	set upCcost[1] = 30

	set UpItem[i] = 'I01J'
	set UpItemBecomes[i] = 'I02R'
	call SetupCosts(i, 0)
	set i = i + 1
	set UpItem[i] = 'I02R'
	set UpItemBecomes[i] = 'I01C'
	call SetupCosts(i, 1)
	set i = i + 1

	//Legion
	set upPcost[0] = 6 //+1
	set upLcost[0] = 2
	set upCcost[0] = 1
	set upPcost[1] = 8 //+2
	set upLcost[1] = 4
	set upCcost[1] = 2
	set upPcost[2] = 26 //rare
	set upLcost[2] = 8
	set upCcost[2] = 16
	set upPcost[3] = 20 //+1
	set upLcost[3] = 10
	set upCcost[3] = 10
	set upPcost[4] = 24 //+2
	set upLcost[4] = 10
	set upCcost[4] = 12
	set upPcost[5] = 36 //legendary
	set upLcost[5] = 16
	set upCcost[5] = 16
    set upPcost[6] = 48 //+1
	set upLcost[6] = 25
	set upCcost[6] = 25
    set upPcost[7] = 60 //+2
	set upLcost[7] = 35
	set upCcost[7] = 35

	set UpItem[i] = 'I0B5'
	set UpItemBecomes[i] = 'I0JF'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0B5'
	set i = i + 1
	set UpItem[i] = 'I0JF'
	set UpItemBecomes[i] = 'I0JG'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0B5'
	set i = i + 1
	set UpItem[i] = 'I0JG'
	set UpItemBecomes[i] = 'I0JH'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0B5'
	set i = i + 1
	set UpItem[i] = 'I0JH'
	set UpItemBecomes[i] = 'I0JI'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0B5'
	set i = i + 1
	set UpItem[i] = 'I0JI'
	set UpItemBecomes[i] = 'I0JJ'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0B5'
	set i = i + 1
	set UpItem[i] = 'I0JJ'
	set UpItemBecomes[i] = 'I0JK'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0B5'
	set i = i + 1
	set UpItem[i] = 'I0JK'
	set UpItemBecomes[i] = 'I0JL'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0B5'
	set i = i + 1
	set UpItem[i] = 'I0JL'
	set UpItemBecomes[i] = 'I0JM'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0B5'
	set i = i + 1
	set UpItem[i] = 'I0B7'
	set UpItemBecomes[i] = 'I0HV'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0B7'
	set i = i + 1
	set UpItem[i] = 'I0HV'
	set UpItemBecomes[i] = 'I0HW'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0B7'
	set i = i + 1
	set UpItem[i] = 'I0HW'
	set UpItemBecomes[i] = 'I0HX'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0B7'
	set i = i + 1
	set UpItem[i] = 'I0HX'
	set UpItemBecomes[i] = 'I0HY'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0B7'
	set i = i + 1
	set UpItem[i] = 'I0HY'
	set UpItemBecomes[i] = 'I0HZ'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0B7'
	set i = i + 1
	set UpItem[i] = 'I0HZ'
	set UpItemBecomes[i] = 'I0I0'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0B7'
	set i = i + 1
	set UpItem[i] = 'I0I0'
	set UpItemBecomes[i] = 'I0I1'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0B7'
	set i = i + 1
	set UpItem[i] = 'I0I1'
	set UpItemBecomes[i] = 'I0I2'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0B7'
	set i = i + 1
	set UpItem[i] = 'I0B1'
	set UpItemBecomes[i] = 'I0IZ'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0B1'
	set i = i + 1
	set UpItem[i] = 'I0IZ'
	set UpItemBecomes[i] = 'I0J0'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0B1'
	set i = i + 1
	set UpItem[i] = 'I0J0'
	set UpItemBecomes[i] = 'I0J1'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0B1'
	set i = i + 1
	set UpItem[i] = 'I0J1'
	set UpItemBecomes[i] = 'I0J2'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0B1'
	set i = i + 1
	set UpItem[i] = 'I0J2'
	set UpItemBecomes[i] = 'I0J3'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0B1'
	set i = i + 1
	set UpItem[i] = 'I0J3'
	set UpItemBecomes[i] = 'I0J4'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0B1'
	set i = i + 1
	set UpItem[i] = 'I0J4'
	set UpItemBecomes[i] = 'I0J5'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0B1'
	set i = i + 1
	set UpItem[i] = 'I0J5'
	set UpItemBecomes[i] = 'I0J6'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0B1'
	set i = i + 1
	set UpItem[i] = 'I0AZ'
	set UpItemBecomes[i] = 'I0I3'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0AZ'
	set i = i + 1
	set UpItem[i] = 'I0I3'
	set UpItemBecomes[i] = 'I0I4'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0AZ'
	set i = i + 1
	set UpItem[i] = 'I0I4'
	set UpItemBecomes[i] = 'I0I5'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0AZ'
	set i = i + 1
	set UpItem[i] = 'I0I5'
	set UpItemBecomes[i] = 'I0I6'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0AZ'
	set i = i + 1
	set UpItem[i] = 'I0I6'
	set UpItemBecomes[i] = 'I0I7'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0AZ'
	set i = i + 1
	set UpItem[i] = 'I0I7'
	set UpItemBecomes[i] = 'I0I8'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0AZ'
	set i = i + 1
	set UpItem[i] = 'I0I8'
	set UpItemBecomes[i] = 'I0I9'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0AZ'
	set i = i + 1
	set UpItem[i] = 'I0I9'
	set UpItemBecomes[i] = 'I0IA'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0AZ'
	set i = i + 1
	set UpItem[i] = 'I0AS' //claymore
	set UpItemBecomes[i] = 'I0D9'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0AS'
	set i = i + 1
	set UpItem[i] = 'I0D9'
	set UpItemBecomes[i] = 'I0DA'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0AS'
	set i = i + 1
	set UpItem[i] = 'I0DA'
	set UpItemBecomes[i] = 'I0HP'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1
	set UpItem[i] = 'I0HP'
	set UpItemBecomes[i] = 'I0HQ'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0AS'
	set i = i + 1
	set UpItem[i] = 'I0HQ'
	set UpItemBecomes[i] = 'I0HR'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0AS'
	set i = i + 1
	set UpItem[i] = 'I0HR'
	set UpItemBecomes[i] = 'I0HS'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1
	set UpItem[i] = 'I0HS'
	set UpItemBecomes[i] = 'I0HT'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0AS'
	set i = i + 1
	set UpItem[i] = 'I0HT'
	set UpItemBecomes[i] = 'I0HU'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0AS'
	set i = i + 1
	set UpItem[i] = 'I04L'
	set UpItemBecomes[i] = 'I0J7'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I04L'
	set i = i + 1
	set UpItem[i] = 'I0J7'
	set UpItemBecomes[i] = 'I0J8'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I04L'
	set i = i + 1
	set UpItem[i] = 'I0J8'
	set UpItemBecomes[i] = 'I0J9'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1
	set UpItem[i] = 'I0J9'
	set UpItemBecomes[i] = 'I0JA'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I04L'
	set i = i + 1
	set UpItem[i] = 'I0JA'
	set UpItemBecomes[i] = 'I0JB'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I04L'
	set i = i + 1
	set UpItem[i] = 'I0JB'
	set UpItemBecomes[i] = 'I0JC'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1
	set UpItem[i] = 'I0JC'
	set UpItemBecomes[i] = 'I0JD'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I04L'
	set i = i + 1
	set UpItem[i] = 'I0JD'
	set UpItemBecomes[i] = 'I0JE'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I04L'
	set i = i + 1
	set UpItem[i] = 'I0AJ'
	set UpItemBecomes[i] = 'I0IJ'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0AJ'
	set i = i + 1
	set UpItem[i] = 'I0IJ'
	set UpItemBecomes[i] = 'I0IK'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0AJ'
	set i = i + 1
	set UpItem[i] = 'I0IK'
	set UpItemBecomes[i] = 'I0IL'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1
	set UpItem[i] = 'I0IL'
	set UpItemBecomes[i] = 'I0IM'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0AJ'
	set i = i + 1
	set UpItem[i] = 'I0IM'
	set UpItemBecomes[i] = 'I0IN'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0AJ'
	set i = i + 1
	set UpItem[i] = 'I0IN'
	set UpItemBecomes[i] = 'I0IO'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1
	set UpItem[i] = 'I0IO'
	set UpItemBecomes[i] = 'I0IP'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0AJ'
	set i = i + 1
	set UpItem[i] = 'I0IP'
	set UpItemBecomes[i] = 'I0IQ'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0AJ'
	set i = i + 1
	set UpItem[i] = 'I0AV'
	set UpItemBecomes[i] = 'I0IB'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0AV'
	set i = i + 1
	set UpItem[i] = 'I0IB'
	set UpItemBecomes[i] = 'I0IC'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0AV'
	set i = i + 1
	set UpItem[i] = 'I0IC'
	set UpItemBecomes[i] = 'I0ID'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I00R'
	set i = i + 1
	set UpItem[i] = 'I0ID'
	set UpItemBecomes[i] = 'I0IE'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0AV'
	set i = i + 1
	set UpItem[i] = 'I0IE'
	set UpItemBecomes[i] = 'I0IF'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0AV'
	set i = i + 1
	set UpItem[i] = 'I0IF'
	set UpItemBecomes[i] = 'I0IG'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0AV'
	set i = i + 1
	set UpItem[i] = 'I0IG'
	set UpItemBecomes[i] = 'I0IH'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0AV'
	set i = i + 1
	set UpItem[i] = 'I0IH'
	set UpItemBecomes[i] = 'I0II'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0AV'
	set i = i + 1
	set UpItem[i] = 'I0AX'
	set UpItemBecomes[i] = 'I0IR'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0AX'
	set i = i + 1
	set UpItem[i] = 'I0IR'
	set UpItemBecomes[i] = 'I0IS'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0AX'
	set i = i + 1
	set UpItem[i] = 'I0IS'
	set UpItemBecomes[i] = 'I0IT'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0AX'
	set i = i + 1
	set UpItem[i] = 'I0IT'
	set UpItemBecomes[i] = 'I0IU'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0AX'
	set i = i + 1
	set UpItem[i] = 'I0IU'
	set UpItemBecomes[i] = 'I0IV'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0AX'
	set i = i + 1
	set UpItem[i] = 'I0IV'
	set UpItemBecomes[i] = 'I0IW'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0AX'
	set i = i + 1
	set UpItem[i] = 'I0IW'
	set UpItemBecomes[i] = 'I0IX'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0AX'
	set i = i + 1
	set UpItem[i] = 'I0IX'
	set UpItemBecomes[i] = 'I0IY'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0AX'
	set i = i + 1
    
	//Azazoth
	set upPcost[0] = 30 //+1
	set upLcost[0] = 15
	set upCcost[0] = 0
	set upPcost[1] = 50 //+2
	set upLcost[1] = 30
	set upCcost[1] = 10
	set upPcost[2] = 70 //rare
	set upLcost[2] = 45
	set upCcost[2] = 20
	set upPcost[3] = 90 //+1
	set upLcost[3] = 60
	set upCcost[3] = 30
	set upPcost[4] = 110 //+2
	set upLcost[4] = 75
	set upCcost[4] = 40
	set upPcost[5] = 130 //legendary
	set upLcost[5] = 90
	set upCcost[5] = 50
    set upPcost[6] = 150 //+1
	set upLcost[6] = 105
	set upCcost[6] = 60
    set upPcost[7] = 190 //+2
	set upLcost[7] = 135
	set upCcost[7] = 80

	set UpItem[i] = 'I0BS' //Plate
	set UpItemBecomes[i] = 'I0JW'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0BS'
	set i = i + 1
	set UpItem[i] = 'I0JW'
	set UpItemBecomes[i] = 'I0JX'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0BS'
	set i = i + 1
	set UpItem[i] = 'I0JX'
	set UpItemBecomes[i] = 'I0JY'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0BS'
	set i = i + 1
	set UpItem[i] = 'I0JY'
	set UpItemBecomes[i] = 'I0JZ'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0BS'
	set i = i + 1
	set UpItem[i] = 'I0JZ'
	set UpItemBecomes[i] = 'I0K0'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0BS'
	set i = i + 1
	set UpItem[i] = 'I0K0'
	set UpItemBecomes[i] = 'I0K1'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0BS'
	set i = i + 1
	set UpItem[i] = 'I0K1'
	set UpItemBecomes[i] = 'I0K2'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0BS'
	set i = i + 1
	set UpItem[i] = 'I0K2'
	set UpItemBecomes[i] = 'I0K3'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0BS'
	set i = i + 1
	set UpItem[i] = 'I0BV' //fullplate
	set UpItemBecomes[i] = 'I0K4'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0BV'
	set i = i + 1
	set UpItem[i] = 'I0K4'
	set UpItemBecomes[i] = 'I0K5'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0BV'
	set i = i + 1
	set UpItem[i] = 'I0K5'
	set UpItemBecomes[i] = 'I0K6'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0BV'
	set i = i + 1
	set UpItem[i] = 'I0K6'
	set UpItemBecomes[i] = 'I0K7'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0BV'
	set i = i + 1
	set UpItem[i] = 'I0K7'
	set UpItemBecomes[i] = 'I0K8'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0BV'
	set i = i + 1
	set UpItem[i] = 'I0K8'
	set UpItemBecomes[i] = 'I0K9'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0BV'
	set i = i + 1
	set UpItem[i] = 'I0K9'
	set UpItemBecomes[i] = 'I0KA'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0BV'
	set i = i + 1
	set UpItem[i] = 'I0KA'
	set UpItemBecomes[i] = 'I0KB'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0BV'
	set i = i + 1
	set UpItem[i] = 'I0BK' //leather
	set UpItemBecomes[i] = 'I0KC'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0BK'
	set i = i + 1
	set UpItem[i] = 'I0KC'
	set UpItemBecomes[i] = 'I0KD'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0BK'
	set i = i + 1
	set UpItem[i] = 'I0KD'
	set UpItemBecomes[i] = 'I0KE'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0BK'
	set i = i + 1
	set UpItem[i] = 'I0KE'
	set UpItemBecomes[i] = 'I0KF'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0BK'
	set i = i + 1
	set UpItem[i] = 'I0KF'
	set UpItemBecomes[i] = 'I0KG'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0BK'
	set i = i + 1
	set UpItem[i] = 'I0KG'
	set UpItemBecomes[i] = 'I0KH'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0BK'
	set i = i + 1
	set UpItem[i] = 'I0KH'
	set UpItemBecomes[i] = 'I0KI'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0BK'
	set i = i + 1
	set UpItem[i] = 'I0KI'
	set UpItemBecomes[i] = 'I0KJ'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0BK'
	set i = i + 1
	set UpItem[i] = 'I0BI' //Robe
	set UpItemBecomes[i] = 'I0KK'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0BI'
	set i = i + 1
	set UpItem[i] = 'I0KK'
	set UpItemBecomes[i] = 'I0KL'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0BI'
	set i = i + 1
	set UpItem[i] = 'I0KL'
	set UpItemBecomes[i] = 'I0KM'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0BI'
	set i = i + 1
	set UpItem[i] = 'I0KM'
	set UpItemBecomes[i] = 'I0KN'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0BI'
	set i = i + 1
	set UpItem[i] = 'I0KN'
	set UpItemBecomes[i] = 'I0KO'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0BI'
	set i = i + 1
	set UpItem[i] = 'I0KO'
	set UpItemBecomes[i] = 'I0KP'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0BI'
	set i = i + 1
	set UpItem[i] = 'I0KP'
	set UpItemBecomes[i] = 'I0KQ'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0BI'
	set i = i + 1
	set UpItem[i] = 'I0KQ'
	set UpItemBecomes[i] = 'I0KR'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0BI'
	set i = i + 1
	set UpItem[i] = 'I0BB' //hammer
	set UpItemBecomes[i] = 'I0KS'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0BB'
	set i = i + 1
	set UpItem[i] = 'I0KS'
	set UpItemBecomes[i] = 'I0KT'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0BB'
	set i = i + 1
	set UpItem[i] = 'I0KT'
	set UpItemBecomes[i] = 'I0KU'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0BB'
	set i = i + 1
	set UpItem[i] = 'I0KU'
	set UpItemBecomes[i] = 'I0KV'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0BB'
	set i = i + 1
	set UpItem[i] = 'I0KV'
	set UpItemBecomes[i] = 'I0KW'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0BB'
	set i = i + 1
	set UpItem[i] = 'I0KW'
	set UpItemBecomes[i] = 'I0KX'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0BB'
	set i = i + 1
	set UpItem[i] = 'I0KX'
	set UpItemBecomes[i] = 'I0KY'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0BB'
	set i = i + 1
	set UpItem[i] = 'I0KY'
	set UpItemBecomes[i] = 'I0KZ'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0BB'
	set i = i + 1
	set UpItem[i] = 'I0BC' //sword
	set UpItemBecomes[i] = 'I0L0'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0BC'
	set i = i + 1
	set UpItem[i] = 'I0L0'
	set UpItemBecomes[i] = 'I0L1'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0BC'
	set i = i + 1
	set UpItem[i] = 'I0L1'
	set UpItemBecomes[i] = 'I0L2'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0BC'
	set i = i + 1
	set UpItem[i] = 'I0L2'
	set UpItemBecomes[i] = 'I0L3'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0BC'
	set i = i + 1
	set UpItem[i] = 'I0L3'
	set UpItemBecomes[i] = 'I0L4'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0BC'
	set i = i + 1
	set UpItem[i] = 'I0L4'
	set UpItemBecomes[i] = 'I0L5'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0BC'
	set i = i + 1
	set UpItem[i] = 'I0L5'
	set UpItemBecomes[i] = 'I0L6'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0BC'
	set i = i + 1
	set UpItem[i] = 'I0L6'
	set UpItemBecomes[i] = 'I0L7'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0BC'
	set i = i + 1
	set UpItem[i] = 'I0BE' //dagger
	set UpItemBecomes[i] = 'I0L8'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0BE'
	set i = i + 1
	set UpItem[i] = 'I0L8'
	set UpItemBecomes[i] = 'I0L9'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0BE'
	set i = i + 1
	set UpItem[i] = 'I0L9'
	set UpItemBecomes[i] = 'I0LA'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0BE'
	set i = i + 1
	set UpItem[i] = 'I0LA'
	set UpItemBecomes[i] = 'I0LB'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0BE'
	set i = i + 1
	set UpItem[i] = 'I0LB'
	set UpItemBecomes[i] = 'I0LC'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0BE'
	set i = i + 1
	set UpItem[i] = 'I0LC'
	set UpItemBecomes[i] = 'I0LD'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0BE'
	set i = i + 1
	set UpItem[i] = 'I0LD'
	set UpItemBecomes[i] = 'I0LE'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0BE'
	set i = i + 1
	set UpItem[i] = 'I0LE'
	set UpItemBecomes[i] = 'I0LF'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0BE'
	set i = i + 1
	set UpItem[i] = 'I0B9' //bow
	set UpItemBecomes[i] = 'I0LG'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0B9'
	set i = i + 1
	set UpItem[i] = 'I0LG'
	set UpItemBecomes[i] = 'I0LH'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0B9'
	set i = i + 1
	set UpItem[i] = 'I0LH'
	set UpItemBecomes[i] = 'I0LI'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0B9'
	set i = i + 1
	set UpItem[i] = 'I0LI'
	set UpItemBecomes[i] = 'I0LJ'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0B9'
	set i = i + 1
	set UpItem[i] = 'I0LJ'
	set UpItemBecomes[i] = 'I0LK'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0B9'
	set i = i + 1
	set UpItem[i] = 'I0LK'
	set UpItemBecomes[i] = 'I0LL'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0B9'
	set i = i + 1
	set UpItem[i] = 'I0LL'
	set UpItemBecomes[i] = 'I0LM'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0B9'
	set i = i + 1
	set UpItem[i] = 'I0LM'
	set UpItemBecomes[i] = 'I0LN'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0B9'
	set i = i + 1
	set UpItem[i] = 'I0BG' //staff
	set UpItemBecomes[i] = 'I0LO'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I0BG'
	set i = i + 1
	set UpItem[i] = 'I0LO'
	set UpItemBecomes[i] = 'I0LP'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I0BG'
	set i = i + 1
	set UpItem[i] = 'I0LP'
	set UpItemBecomes[i] = 'I0LQ'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I0BG'
	set i = i + 1
	set UpItem[i] = 'I0LQ'
	set UpItemBecomes[i] = 'I0LR'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I0BG'
	set i = i + 1
	set UpItem[i] = 'I0LR'
	set UpItemBecomes[i] = 'I0LS'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I0BG'
	set i = i + 1
	set UpItem[i] = 'I0LS'
	set UpItemBecomes[i] = 'I0LT'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I0BG'
	set i = i + 1
	set UpItem[i] = 'I0LT'
	set UpItemBecomes[i] = 'I0LU'
	call SetupCosts(i,6)
	set UpDiscountItem[i] = 'I0BG'
	set i = i + 1
	set UpItem[i] = 'I0LU'
	set UpItemBecomes[i] = 'I0LV'
	call SetupCosts(i,7)
	set UpDiscountItem[i] = 'I0BG'
	set i = i + 1
    set UpItem[i] = 'I06M' //sphere
    set UpItemBecomes[i] = 'I0LW'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I06M'
	set i = i + 1
    set UpItem[i] = 'I0LW'
    set UpItemBecomes[i] = 'I0LX'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I06M'
	set i = i + 1

	//Ring of Existence
	set upPcost[0] = 36 //+1
	set upLcost[0] = 24
	set upCcost[0] = 12
	set upPcost[1] = 48 //+2
	set upLcost[1] = 33
	set upCcost[1] = 18
	set upPcost[2] = 60 //rare
	set upLcost[2] = 42
	set upCcost[2] = 24
	set upPcost[3] = 72 //+1
	set upLcost[3] = 51
	set upCcost[3] = 30
	set upPcost[4] = 84 //+2
	set upLcost[4] = 60
	set upCcost[4] = 36
	set upPcost[5] = 96 //legendary
	set upLcost[5] = 69
	set upCcost[5] = 42
    set upPcost[6] = 108 //+1
	set upLcost[6] = 78
	set upCcost[6] = 48
    set upPcost[7] = 132 //+2
	set upLcost[7] = 96
	set upCcost[7] = 60

	set UpItem[i] = 'I018'
	set UpItemBecomes[i] = 'I0F0'
	call SetupCosts(i,0)
	set UpDiscountItem[i] = 'I018'
	set i = i + 1
	set UpItem[i] = 'I0F0'
	set UpItemBecomes[i] = 'I0EZ'
	call SetupCosts(i,1)
	set UpDiscountItem[i] = 'I018'
	set i = i + 1
	set UpItem[i] = 'I0EZ'
	set UpItemBecomes[i] = 'I06I'
	call SetupCosts(i,2)
	set UpDiscountItem[i] = 'I018'
	set i = i + 1
	set UpItem[i] = 'I06I'
	set UpItemBecomes[i] = 'I0F1'
	call SetupCosts(i,3)
	set UpDiscountItem[i] = 'I06I'
	set i = i + 1
	set UpItem[i] = 'I0F1'
	set UpItemBecomes[i] = 'I0F2'
	call SetupCosts(i,4)
	set UpDiscountItem[i] = 'I06I'
	set i = i + 1
	set UpItem[i] = 'I0F2'
	set UpItemBecomes[i] = 'I06J'
	call SetupCosts(i,5)
	set UpDiscountItem[i] = 'I06I'
	set i = i + 1
	set UpItem[i] = 'I06J'
	set UpItemBecomes[i] = 'I0G1'
	call SetupCosts(i,6)
    set UpDiscountItem[i] = 'I06I'
	set i = i + 1
	set UpItem[i] = 'I0G1'
	set UpItemBecomes[i] = 'I0G2'
	call SetupCosts(i,7)
    set UpDiscountItem[i] = 'I06I'
	set i = i + 1

	//Forgotten Jewels
	set upPcost[0] = 60 //+1
	set upLcost[0] = 40
	set upCcost[0] = 20
	set upPcost[1] = 80 //+2
	set upLcost[1] = 55
	set upCcost[1] = 30
	set upPcost[2] = 100 //rare
	set upLcost[2] = 70
	set upCcost[2] = 40
	set upPcost[3] = 120 //+1
	set upLcost[3] = 85
	set upCcost[3] = 50
	set upPcost[4] = 140 //+2
	set upLcost[4] = 100
	set upCcost[4] = 60
	set upPcost[5] = 160 //legendary
	set upLcost[5] = 115
	set upCcost[5] = 70
    set upPcost[6] = 180 //+1
	set upLcost[6] = 130
	set upCcost[6] = 80
    set upPcost[7] = 220 //+2
	set upLcost[7] = 160
	set upCcost[7] = 100

	//lexium
	set UpItem[i] = 'I0CH'
	set UpItemBecomes[i] = 'I01L'
	call SetupCosts(i, 0)
	set UpDiscountItem[i] = 'I0CH'
	set i = i + 1
	set UpItem[i] = 'I01L'
	set UpItemBecomes[i] = 'I01N'
	call SetupCosts(i, 1)
	set UpDiscountItem[i] = 'I0CH'
	set i = i + 1
	set UpItem[i] = 'I01N'
	set UpItemBecomes[i] = 'I0NT'
	call SetupCosts(i, 2)
	set UpDiscountItem[i] = 'I0CH'
	set i = i + 1
	set UpItem[i] = 'I0NT'
	set UpItemBecomes[i] = 'I0NP'
	call SetupCosts(i, 3)
	set UpDiscountItem[i] = 'I0CH'
	set i = i + 1
	set UpItem[i] = 'I0NP'
	set UpItemBecomes[i] = 'I0NQ'
	call SetupCosts(i, 4)
	set UpDiscountItem[i] = 'I0CH'
	set i = i + 1
	set UpItem[i] = 'I0NQ'
	set UpItemBecomes[i] = 'I0NR'
	call SetupCosts(i, 5)
	set UpDiscountItem[i] = 'I0CH'
	set i = i + 1
	set UpItem[i] = 'I0NR'
	set UpItemBecomes[i] = 'I0NS'
	call SetupCosts(i, 6)
	set UpDiscountItem[i] = 'I0CH'
	set i = i + 1
	set UpItem[i] = 'I0NS'
	set UpItemBecomes[i] = 'I019'
	call SetupCosts(i, 7)
	set UpDiscountItem[i] = 'I0CH'
	set i = i + 1
	//vigor
	set UpItem[i] = 'I0O1'
	set UpItemBecomes[i] = 'I0O0'
	call SetupCosts(i, 0)
	set UpDiscountItem[i] = 'I0O1'
	set i = i + 1
	set UpItem[i] = 'I0O0'
	set UpItemBecomes[i] = 'I0NZ'
	call SetupCosts(i, 1)
	set UpDiscountItem[i] = 'I0O1'
	set i = i + 1
	set UpItem[i] = 'I0NZ'
	set UpItemBecomes[i] = 'I0NY'
	call SetupCosts(i, 2)
	set UpDiscountItem[i] = 'I0O1'
	set i = i + 1
	set UpItem[i] = 'I0NY'
	set UpItemBecomes[i] = 'I0O2'
	call SetupCosts(i, 3)
	set UpDiscountItem[i] = 'I0O1'
	set i = i + 1
	set UpItem[i] = 'I0O2'
	set UpItemBecomes[i] = 'I0NX'
	call SetupCosts(i, 4)
	set UpDiscountItem[i] = 'I0O1'
	set i = i + 1
	set UpItem[i] = 'I0NX'
	set UpItemBecomes[i] = 'I0NV'
	call SetupCosts(i, 5)
	set UpDiscountItem[i] = 'I0O1'
	set i = i + 1
	set UpItem[i] = 'I0NV'
	set UpItemBecomes[i] = 'I0NU'
	call SetupCosts(i, 6)
	set UpDiscountItem[i] = 'I0O1'
	set i = i + 1
	set UpItem[i] = 'I0NU'
	set UpItemBecomes[i] = 'I0NW'
	call SetupCosts(i, 7)
	set UpDiscountItem[i] = 'I0O1'
	set i = i + 1
	//torture
	set UpItem[i] = 'I0OB'
	set UpItemBecomes[i] = 'I0O9'
	call SetupCosts(i, 0)
	set UpDiscountItem[i] = 'I0OB'
	set i = i + 1
	set UpItem[i] = 'I0O9'
	set UpItemBecomes[i] = 'I0O8'
	call SetupCosts(i, 1)
	set UpDiscountItem[i] = 'I0OB'
	set i = i + 1
	set UpItem[i] = 'I0O8'
	set UpItemBecomes[i] = 'I0OA'
	call SetupCosts(i, 2)
	set UpDiscountItem[i] = 'I0OB'
	set i = i + 1
	set UpItem[i] = 'I0OA'
	set UpItemBecomes[i] = 'I0O4'
	call SetupCosts(i, 3)
	set UpDiscountItem[i] = 'I0OB'
	set i = i + 1
	set UpItem[i] = 'I0O4'
	set UpItemBecomes[i] = 'I0O5'
	call SetupCosts(i, 4)
	set UpDiscountItem[i] = 'I0OB'
	set i = i + 1
	set UpItem[i] = 'I0O5'
	set UpItemBecomes[i] = 'I0O7'
	call SetupCosts(i, 5)
	set UpDiscountItem[i] = 'I0OB'
	set i = i + 1
	set UpItem[i] = 'I0O7'
	set UpItemBecomes[i] = 'I0O6'
	call SetupCosts(i, 6)
	set UpDiscountItem[i] = 'I0OB'
	set i = i + 1
	set UpItem[i] = 'I0O6'
	set UpItemBecomes[i] = 'I0O3'
	call SetupCosts(i, 7)
	set UpDiscountItem[i] = 'I0OB'
	
	set udg_PermanentInteger[2] = i
endfunction

function killquestsetup takes nothing returns nothing
	//trolls
	set KillQuest['I07D'][StringHash("Index")] = 1
	set KillQuest[1][StringHash("Goal")] = 15
	set KillQuest[1][StringHash("Min")] = 1
	set KillQuest[1][StringHash("Max")] = 8
	set KillQuest[1].string[StringHash("Name")] = "Trolls"
	set KillQuest[1].rect[StringHash("Region")] = gg_rct_Demon_Wiz_and_Norm_2
	//tuskar
	set KillQuest['I058'][StringHash("Index")] = 2
	set KillQuest[2][StringHash("Goal")] = 20
	set KillQuest[2][StringHash("Min")] = 3
	set KillQuest[2][StringHash("Max")] = 14
	set KillQuest[2].string[StringHash("Name")] = "Tuskar"
	set KillQuest[2].rect[StringHash("Region")] = gg_rct_Mindless_Beasts_Spawn_2
	//spider
	set KillQuest['I05F'][StringHash("Index")] = 3
	set KillQuest[3][StringHash("Goal")] = 20
	set KillQuest[3][StringHash("Min")] = 5
	set KillQuest[3][StringHash("Max")] = 24
	set KillQuest[3].string[StringHash("Name")] = "Spider"
	set KillQuest[3].rect[StringHash("Region")] = gg_rct_Spider_1
	//ursa
	set KillQuest['I04U'][StringHash("Index")] = 4
	set KillQuest[4][StringHash("Goal")] = 25
	set KillQuest[4][StringHash("Min")] = 8
	set KillQuest[4][StringHash("Max")] = 34
	set KillQuest[4].string[StringHash("Name")] = "Ursa"
	set KillQuest[4].rect[StringHash("Region")] = gg_rct_Despair_Spawn_9
	//polar bears
	set KillQuest['I04V'][StringHash("Index")] = 5
	set KillQuest[5][StringHash("Goal")] = 20
	set KillQuest[5][StringHash("Min")] = 12
	set KillQuest[5][StringHash("Max")] = 46
	set KillQuest[5].string[StringHash("Name")] = "Polar Bears"
	set KillQuest[5].rect[StringHash("Region")] = gg_rct_Bear_2
	//tauren/ogre
	set KillQuest['I05B'][StringHash("Index")] = 6
	set KillQuest[6][StringHash("Goal")] = 25
	set KillQuest[6][StringHash("Min")] = 20
	set KillQuest[6][StringHash("Max")] = 62
	set KillQuest[6].string[StringHash("Name")] = "Tauren/Ogre"
	set KillQuest[6].rect[StringHash("Region")] = gg_rct_Unknown_Evil_Spawn_1
	//unbroken
	set KillQuest['I05L'][StringHash("Index")] = 7
	set KillQuest[7][StringHash("Goal")] = 25
	set KillQuest[7][StringHash("Min")] = 29
	set KillQuest[7][StringHash("Max")] = 84
	set KillQuest[7].string[StringHash("Name")] = "Unbroken"
	set KillQuest[7].rect[StringHash("Region")] = gg_rct_Unbroken_Spawn_2
	//hellhounds
	set KillQuest['I05E'][StringHash("Index")] = 8
	set KillQuest[8][StringHash("Goal")] = 20
	set KillQuest[8][StringHash("Min")] = 44
	set KillQuest[8][StringHash("Max")] = 110
	set KillQuest[8].string[StringHash("Name")] = "Hellhounds"
	set KillQuest[8].rect[StringHash("Region")] = gg_rct_Hell_4
	//centaur
	set KillQuest['I0GD'][StringHash("Index")] = 9
	set KillQuest[9][StringHash("Goal")] = 20
	set KillQuest[9][StringHash("Min")] = 56
	set KillQuest[9][StringHash("Max")] = 134
	set KillQuest[9].string[StringHash("Name")] = "Centaur"
	set KillQuest[9].rect[StringHash("Region")] = gg_rct_Unknown_Evil_Spawn_5
	//magnataur
	set KillQuest['I05K'][StringHash("Index")] = 10
	set KillQuest[10][StringHash("Goal")] = 20
	set KillQuest[10][StringHash("Min")] = 70
	set KillQuest[10][StringHash("Max")] = 162
	set KillQuest[10].string[StringHash("Name")] = "Magnataur"
	set KillQuest[10].rect[StringHash("Region")] = gg_rct_Magnataur
	//dragon
	set KillQuest['I05M'][StringHash("Index")] = 11
	set KillQuest[11][StringHash("Goal")] = 20
	set KillQuest[11][StringHash("Min")] = 92
	set KillQuest[11][StringHash("Max")] = 182
	set KillQuest[11].string[StringHash("Name")] = "Dragons"
	set KillQuest[11].rect[StringHash("Region")] = gg_rct_Astral_Spawn_3
	//devourers
	set KillQuest['I022'][StringHash("Index")] = 12
	set KillQuest[12][StringHash("Goal")] = 20
	set KillQuest[12][StringHash("Min")] = 108
	set KillQuest[12][StringHash("Max")] = 198
	set KillQuest[12].string[StringHash("Name")] = "Devourers"
	set KillQuest[12].rect[StringHash("Region")] = gg_rct_Devourer_entry
	//demons
	set KillQuest['I03H'][StringHash("Index")] = 13
	set KillQuest[13][StringHash("Goal")] = 20
	set KillQuest[13][StringHash("Min")] = 166
	set KillQuest[13][StringHash("Max")] = 256
	set KillQuest[13].string[StringHash("Name")] = "Demons"
	set KillQuest[13].rect[StringHash("Region")] = gg_rct_Demon_Wiz_and_Norm_1
	//horror beast
	set KillQuest['I09J'][StringHash("Index")] = 14
	set KillQuest[14][StringHash("Goal")] = 20
	set KillQuest[14][StringHash("Min")] = 190
	set KillQuest[14][StringHash("Max")] = 260
	set KillQuest[14].string[StringHash("Name")] = "Horror Beasts"
	set KillQuest[14].rect[StringHash("Region")] = gg_rct_Mindless_Beasts_Spawn_1
	//despair
	set KillQuest['I03C'][StringHash("Index")] = 15
	set KillQuest[15][StringHash("Goal")] = 20
	set KillQuest[15][StringHash("Min")] = 210
	set KillQuest[15][StringHash("Max")] = 280
	set KillQuest[15].string[StringHash("Name")] = "Despair"
	set KillQuest[15].rect[StringHash("Region")] = gg_rct_Magnataur
	//abyssal
	set KillQuest['I02A'][StringHash("Index")] = 16
	set KillQuest[16][StringHash("Goal")] = 20
	set KillQuest[16][StringHash("Min")] = 229
	set KillQuest[16][StringHash("Max")] = 299
	set KillQuest[16].string[StringHash("Name")] = "Abyssal"
	set KillQuest[16].rect[StringHash("Region")] = gg_rct_Despair_Spawn_9
	//void
	set KillQuest['I03I'][StringHash("Index")] = 17
	set KillQuest[17][StringHash("Goal")] = 20
	set KillQuest[17][StringHash("Min")] = 250
	set KillQuest[17][StringHash("Max")] = 320
	set KillQuest[17].string[StringHash("Name")] = "Void"
	set KillQuest[17].rect[StringHash("Region")] = gg_rct_Unknown_Evil_Spawn_1
	//nightmares
	set KillQuest['I0GE'][StringHash("Index")] = 18
	set KillQuest[18][StringHash("Goal")] = 20
	set KillQuest[18][StringHash("Min")] = 270
	set KillQuest[18][StringHash("Max")] = 340
	set KillQuest[18].string[StringHash("Name")] = "Nightmares"
	set KillQuest[18].rect[StringHash("Region")] = gg_rct_Unknown_Evil_Spawn_5
	//hellspawn
	set KillQuest['I03J'][StringHash("Index")] = 19
	set KillQuest[19][StringHash("Goal")] = 20
	set KillQuest[19][StringHash("Min")] = 290
	set KillQuest[19][StringHash("Max")] = 360
	set KillQuest[19].string[StringHash("Name")] = "Hellspawn"
	set KillQuest[19].rect[StringHash("Region")] = gg_rct_Hell_4
	//denied existence
	set KillQuest['I02G'][StringHash("Index")] = 20
	set KillQuest[20][StringHash("Goal")] = 30
	set KillQuest[20][StringHash("Min")] = 310
	set KillQuest[20][StringHash("Max")] = 380
	set KillQuest[20].string[StringHash("Name")] = "Denied Existence"
	set KillQuest[20].rect[StringHash("Region")] = gg_rct_Devourer_entry
	//astral
	set KillQuest['I039'][StringHash("Index")] = 21
	set KillQuest[21][StringHash("Goal")] = 20
	set KillQuest[21][StringHash("Min")] = 330
	set KillQuest[21][StringHash("Max")] = 400
	set KillQuest[21].string[StringHash("Name")] = "Astral"
	set KillQuest[21].rect[StringHash("Region")] = gg_rct_Astral_Spawn_3
	//planeswalker
	set KillQuest['I0Q1'][StringHash("Index")] = 22
	set KillQuest[22][StringHash("Goal")] = 20
	set KillQuest[22][StringHash("Min")] = 350
	set KillQuest[22][StringHash("Max")] = 420
	set KillQuest[22].string[StringHash("Name")] = "Planeswalker"
	set KillQuest[22].rect[StringHash("Region")] = gg_rct_Spider_1
endfunction

function Reward_Tables_Setup takes nothing returns nothing
	local integer i=1
	local integer index=1
// dragon armor
	call SaveInteger(RewardItems,1,0, 4) //the 0 lists how many values stored, 4 for armor, 10 for weapons or both
	call SaveInteger(RewardItems,1,1, 'I048')
	call SaveInteger(RewardItems,1,2, 'I02U')
	call SaveInteger(RewardItems,1,3, 'I064')
	call SaveInteger(RewardItems,1,4, 'I02P')
// dragon weapons
	call SaveInteger(RewardItems,2,0, 10)
	call SaveInteger(RewardItems,2,6, 'I033')
	call SaveInteger(RewardItems,2,7, 'I0BZ')
	call SaveInteger(RewardItems,2,8, 'I02S')
	call SaveInteger(RewardItems,2,9, 'I032')
	call SaveInteger(RewardItems,2,10, 'I065')
// hydra weapons
	call SaveInteger(RewardItems,3,0, 10)
	call SaveInteger(RewardItems,3,6, 'I02N')
	call SaveInteger(RewardItems,3,7, 'I072')
	call SaveInteger(RewardItems,3,8, 'I06Y')
	call SaveInteger(RewardItems,3,9, 'I070')
	call SaveInteger(RewardItems,3,10, 'I071')
// Spider Armors
	call SaveInteger(RewardItems,4,0, 10) 
	call SaveInteger(RewardItems,4,1, 'I0B8')
	call SaveInteger(RewardItems,4,2, 'I0BA')
	call SaveInteger(RewardItems,4,3, 'I0B4')
	call SaveInteger(RewardItems,4,4, 'I0B6')
// blood weapons
	call SaveInteger(RewardItems,5,0, 10)
	call SaveInteger(RewardItems,5,6, 'I03F')
	call SaveInteger(RewardItems,5,7, 'I04S')
	call SaveInteger(RewardItems,5,8, 'I020')
	call SaveInteger(RewardItems,5,9, 'I016')
	call SaveInteger(RewardItems,5,10, 'I0AK')
// blood armor
    call SaveInteger(RewardItems,6,0, 4)
    call SaveInteger(RewardItems,6,1, 'I0N4')
    call SaveInteger(RewardItems,6,2, 'I0N4')
    call SaveInteger(RewardItems,6,3, 'I0N5')
    call SaveInteger(RewardItems,6,4, 'I0N6')
// blood both
    call SaveInteger(RewardItems,7,0, 10)
    call SaveInteger(RewardItems,7,1, 'I0N4')
    call SaveInteger(RewardItems,7,2, 'I0N4')
    call SaveInteger(RewardItems,7,3, 'I0N5')
    call SaveInteger(RewardItems,7,4, 'I0N6')
    call SaveInteger(RewardItems,7,6, 'I03F')
	call SaveInteger(RewardItems,7,7, 'I04S')
	call SaveInteger(RewardItems,7,8, 'I020')
	call SaveInteger(RewardItems,7,9, 'I016')
	call SaveInteger(RewardItems,7,10, 'I0AK')
endfunction

function JassVariablesInit takes nothing returns nothing
    //startup
    local integer i = 0

	call GoldReward()
    call ItemUpgrades()

	set prMulti[1] = 'A0A3'
	set prMulti[2] = 'A0IW'
	set prMulti[3] = 'A0IX'
	set prMulti[4] = 'A0IY'
	set prMulti[5] = 'A0IZ'
 
    call ExperienceTableInit()
    call SetItemStats()
    call killquestsetup()
    call HeadhunterQuestSetup()
	call Reward_Tables_Setup()
    call ColosseumSetup()
    call StruggleSetup()
    call StringSetup()
    call ItemRestrictions()
    call ShieldTypes()
endfunction

endlibrary
