library JassVariables requires Functions, Table

globals
    string abc = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    string array forceString
	string array infoString
	string array ShopkeeperDirection
	string array IS_HD
	string array CURRENCY_ICON

	HashTable KillQuest
	HashTable ItemData
	HashTable UnitData
	HashTable ItemRewards
	HashTable ItemPrices
	HashTable PrestigeTable

    Table CrystalRewards

    hashtable MiscHash = InitHashtable()
    hashtable PlayerProf = InitHashtable()

    timer strugglespawn = CreateTimer()

    player pfoe = Player(PLAYER_NEUTRAL_AGGRESSIVE)
	player pboss = Player(11)

    effect array charLight

    leaderboard RollBoard

	dialog array dChooseReward

	button array SpellButton

    location array colospot

    unit array Hero
    unit array HeroGrave
	unit array Backpack

    integer afkInt = 0
    integer HardMode = 0
    integer cfactor = 2
    integer array HeroID
	integer array Currency
	integer array prMulti
	integer array Dmg_mod
	integer array Str_mod
	integer array Agi_mod
	integer array Int_mod
	integer array Spl_mod
	integer array Gld_mod
	integer array Reg_mod
    integer array TotalEvasion
    integer array BonusEvasion
    integer array ItemRegen
    integer array ShieldCount
    integer array RollChecks
    integer array HuntedLevel
    integer array Movespeed
    integer array charLightId	
	integer array CustomLighting

	real array DR_mod
    real array TotalRegen
    real array SpellRegen
    real array BoostValue
    real array DealtDmgBase
    real array DmgBase
    real array DmgTaken
    real array SpellTakenBase
    real array SpellTaken

	boolean ChaosMode = false
    boolean ForcedRevive = false
    boolean CWLoading = false
	boolean array MultiShot
    boolean array BossSpellCD
    boolean array CameraLock
    boolean array forceSaving

	real array BOOST
	real array LBOOST
endglobals

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
	set udg_Struggle_WaveU[27] = 0 //skipped enemy type makes struggle end 
	set udg_Struggle_WaveUN[27] = 0
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
	set udg_Struggle_WaveU[42] = 0
	set udg_Struggle_WaveUN[42] = 0
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
    set udg_HuntedHead[0] = 'I07J'
    set udg_HuntedItem[0] = 'I01B'
    set HuntedLevel[0] = 100
    set udg_HuntedExp[0] = 5000
    set udg_HuntedRecipe[1] = 'I049'
    set udg_HuntedHead[1] = 'I02M'
    set udg_HuntedItem[1] = 'I04C'
    set HuntedLevel[1] = 50
    set udg_HuntedExp[1] = 4000
    set udg_HuntedRecipe[2] = 'I04A'
    set udg_HuntedHead[2] = 'I084'
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

function SetItemStats takes nothing returns nothing
	//chaotic boss items

	//slaughter queen
	/*call SetTableData(ItemData, 'I0AE', "level 270 damage 40000 str 10000 prof 6")
	call SetTableData(ItemData, 'I090', "level 280 damage 48000 str 11875 prof 6")
	call SetTableData(ItemData, 'I092', "level 290 damage 56000 str 13750 prof 6")
	call SetTableData(ItemData, 'I0BF', "level 300 damage 72000 str 17500 prof 6")
	call SetTableData(ItemData, 'I0AM', "level 310 damage 88000 str 21250 prof 6")
	call SetTableData(ItemData, 'I0BH', "level 320 damage 104000 str 25000 prof 6")

	call SetTableData(ItemData, 'I04F', "level 270 damage 75000 str 5000 prof 7")
	call SetTableData(ItemData, 'I099', "level 280 damage 90000 str 6000 prof 7")
	call SetTableData(ItemData, 'I09A', "level 290 damage 105000 str 7000 prof 7")
	call SetTableData(ItemData, 'I0OR', "level 300 damage 135000 str 9000 prof 7")
	call SetTableData(ItemData, 'I0OS', "level 310 damage 165000 str 11000 prof 7")
	call SetTableData(ItemData, 'I0OT', "level 320 damage 195000 str 13000 prof 7")

	call SetTableData(ItemData, 'I0AF', "level 270 damage 35000 agi 14000 prof 8")
	call SetTableData(ItemData, 'I08X', "level 280 damage 42000 agi 16625 prof 8")
	call SetTableData(ItemData, 'I08Y', "level 290 damage 49000 agi 19250 prof 8")
	call SetTableData(ItemData, 'I0OM', "level 300 damage 63000 agi 24500 prof 8")
	call SetTableData(ItemData, 'I0ON', "level 310 damage 77000 agi 29750 prof 8")
	call SetTableData(ItemData, 'I0OO', "level 320 damage 91000 agi 35000 prof 8")

	call SetTableData(ItemData, 'I0AD', "level 270 damage 70000 agi 8000 prof 9")
	call SetTableData(ItemData, 'I04X', "level 280 damage 84000 agi 9500 prof 9")
	call SetTableData(ItemData, 'I056', "level 290 damage 98000 agi 11000 prof 9")
	call SetTableData(ItemData, 'I01R', "level 300 damage 126000 agi 14000 prof 9")
	call SetTableData(ItemData, 'I02T', "level 310 damage 154000 agi 17000 prof 9")
	call SetTableData(ItemData, 'I0OL', "level 320 damage 182000 agi 20000 prof 9")

	call SetTableData(ItemData, 'I0AG', "level 270 damage 20000 int 16000 prof 10")
	call SetTableData(ItemData, 'I094', "level 280 damage 24000 int 19000 prof 10")
	call SetTableData(ItemData, 'I096', "level 290 damage 28000 int 22000 prof 10")
	call SetTableData(ItemData, 'I0BD', "level 300 damage 36000 int 28000 prof 10")
	call SetTableData(ItemData, 'I0OP', "level 310 damage 44000 int 34000 prof 10")
	call SetTableData(ItemData, 'I0OQ', "level 320 damage 52000 int 40000 prof 10")

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
	call SetTableData(ItemData, 'I0AU', "level 340 stats 7500")
	call SetTableData(ItemData, 'I0NK', "level 340 stats 15000 spellboost 10 gold 25")
	call SetTableData(ItemData, 'I0NL', "level 356 stats 30000 spellboost 15 gold 30")

	//existence
	//ring
	call SetTableData(ItemData, 'I018', "level 340 stats 17000")
	call SetTableData(ItemData, 'I0F0', "level 348 stats 21300")
	call SetTableData(ItemData, 'I0EZ', "level 356 stats 25500")
	call SetTableData(ItemData, 'I06I', "level 356 stats 29400 spellboost 10")
	call SetTableData(ItemData, 'I0F1', "level 364 stats 36600 spellboost 11")
	call SetTableData(ItemData, 'I0F2', "level 372 stats 44200 spellboost 12")
	call SetTableData(ItemData, 'I06J', "level 380 stats 51000 spellboost 13")
	call SetTableData(ItemData, 'I0G1', "level 388 stats 63800 spellboost 14")
	call SetTableData(ItemData, 'I0G2', "level 396 stats 76500 spellboost 15")

	//soul
	call SetTableData(ItemData, 'I0BY', "level 340 health 2000000 armor 2500 regen 5000")

	//chaos shield
	call SetTableData(ItemData, 'I01J', "level 340 health 1000000 regen 35000")
	call SetTableData(ItemData, 'I02R', "level 350 health 1500000 regen 40000")
	call SetTableData(ItemData, 'I01C', "level 360 health 2000000 regen 45000")

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

	//Fullplate
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
    call SetTableData(ItemData, 'I0NW', "level 400 str 100000 dr 15 regen 50000 gold 100")
	
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

    //demon prince
	call SetTableData(ItemData, 'I03F', "level 190 damage 15800 str 4900 prof 6")
	call SetTableData(ItemData, 'I04S', "level 190 damage 43000 prof 7")
	call SetTableData(ItemData, 'I020', "level 190 damage 15400 agi 9200 prof 8")
	call SetTableData(ItemData, 'I016', "level 190 damage 32200 agi 4900 prof 9")
	call SetTableData(ItemData, 'I0AK', "level 190 int 10300 spellboost 5 prof 10")
	call SetTableData(ItemData, 'I0N4', "level 190 armor 1000 str 2000 prof 5")
	call SetTableData(ItemData, 'I0N5', "level 190 armor 800 str 750 agi 1500 prof 3")
	call SetTableData(ItemData, 'I0N6', "level 190 armor 750 str 500 int 2500 prof 4")
	call SetTableData(ItemData, 'I0OF', "level 190 damage 7000 armor 200 stats 1200 crit 4 chance 30") //demon golem fist

	//absolute horror
	call SetTableData(ItemData, 'I0NG', "level 230 armor 2200 str 5200 prof 1")
	call SetTableData(ItemData, 'I0NA', "level 230 movespeed -25 armor 4700 str 6000 prof 2")
	call SetTableData(ItemData, 'I0NH', "level 230 armor 1900 agi 14000 prof 3")
	call SetTableData(ItemData, 'I0NI', "level 230 armor 1800 int 26000 prof 4")
	call SetTableData(ItemData, 'I0NB', "level 230 damage 38000 str 8500 prof 6")
	call SetTableData(ItemData, 'I0NF', "level 230 damage 95000 str 5000 prof 7")
	call SetTableData(ItemData, 'I0ND', "level 230 damage 36000 agi 24000 prof 8")
	call SetTableData(ItemData, 'I0NC', "level 230 damage 78000 agi 11500 prof 9")
	call SetTableData(ItemData, 'I0NE', "level 230 damage 26000 int 24000 prof 10")*/
endfunction

function killquestsetup takes nothing returns nothing
	//trolls
	local integer id = 'nits'
	set KillQuest[0][0] = id
	set KillQuest['I07D'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 15
	set KillQuest[id][KILLQUEST_MIN] = 1 
	set KillQuest[id][KILLQUEST_MAX] = 8
	set KillQuest[id].string[KILLQUEST_NAME] = "Trolls"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Troll_Demon_1
	//tuskarr
	set id = 'ntks'
	set KillQuest[0][1] = id
	set KillQuest['I058'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 3 
	set KillQuest[id][KILLQUEST_MAX] = 14
	set KillQuest[id].string[KILLQUEST_NAME] = "Tuskarr"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Tuskar_Horror_1
	//spider
	set id = 'nnwr'
	set KillQuest[0][2] = id
	set KillQuest['I05F'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 5 
	set KillQuest[id][KILLQUEST_MAX] = 24
	set KillQuest[id].string[KILLQUEST_NAME] = "Spiders"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Spider_Horror_3
	//ursa
	set id = 'nfpu'
	set KillQuest[0][3] = id
	set KillQuest['I04U'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 25
	set KillQuest[id][KILLQUEST_MIN] = 8 
	set KillQuest[id][KILLQUEST_MAX] = 24
	set KillQuest[id].string[KILLQUEST_NAME] = "Ursae"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Ursa_Abyssal_2
	//polar bears
	set id = 'nplg'
	set KillQuest[0][4] = id
	set KillQuest['I04V'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 12 
	set KillQuest[id][KILLQUEST_MAX] = 46
	set KillQuest[id].string[KILLQUEST_NAME] = "Polar Bears & Mammoths"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Bear_2
	//tauren/ogre
	set id = 'n01G'
	set KillQuest[0][5] = id
	set KillQuest['I05B'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 25
	set KillQuest[id][KILLQUEST_MIN] = 20 
	set KillQuest[id][KILLQUEST_MAX] = 62
	set KillQuest[id].string[KILLQUEST_NAME] = "Taurens & Ogres"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_OgreTauren_Void_5
	//unbroken
	set id = 'nubw'
	set KillQuest[0][6] = id
	set KillQuest['I05L'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 25
	set KillQuest[id][KILLQUEST_MIN] = 29 
	set KillQuest[id][KILLQUEST_MAX] = 84
	set KillQuest[id].string[KILLQUEST_NAME] = "Unbroken"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Unbroken_Dimensional_2
	//hellhounds
	set id = 'nvdl'
	set KillQuest[0][7] = id
	set KillQuest['I05E'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 44 
	set KillQuest[id][KILLQUEST_MAX] = 110
	set KillQuest[id].string[KILLQUEST_NAME] = "Hellspawn"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Hell_4
	//centaur
	set id = 'n024'
	set KillQuest[0][8] = id
	set KillQuest['I0GD'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 56 
	set KillQuest[id][KILLQUEST_MAX] = 134
	set KillQuest[id].string[KILLQUEST_NAME] = "Centaurs"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Centaur_Nightmare_5
	//magnataur
	set id = 'n01M'
	set KillQuest[0][9] = id
	set KillQuest['I05K'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 70 
	set KillQuest[id][KILLQUEST_MAX] = 162
	set KillQuest[id].string[KILLQUEST_NAME] = "Magnataurs"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Magnataur_Despair_1
	//dragon
	set id = 'n02P'
	set KillQuest[0][10] = id
	set KillQuest['I05M'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 92 
	set KillQuest[id][KILLQUEST_MAX] = 182
	set KillQuest[id].string[KILLQUEST_NAME] = "Dragons"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Dragon_Astral_8
	//devourers
	set id = 'n02L'
	set KillQuest[0][11] = id
	set KillQuest['I022'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 110 
	set KillQuest[id][KILLQUEST_MAX] = 198
	set KillQuest[id].string[KILLQUEST_NAME] = "Devourers"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Devourer_entry
	//demons
	set id = 'n034'
	set KillQuest[1][0] = id
	set KillQuest['I03H'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 166 
	set KillQuest[id][KILLQUEST_MAX] = 256
	set KillQuest[id].string[KILLQUEST_NAME] = "Demons"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Troll_Demon_1
	//horror beast
	set id = 'n03A'
	set KillQuest[1][1] = id
	set KillQuest['I09J'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 190 
	set KillQuest[id][KILLQUEST_MAX] = 260
	set KillQuest[id].string[KILLQUEST_NAME] = "Horror Beasts"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Tuskar_Horror_1
	//despair
	set id = 'n03F'
	set KillQuest[1][2] = id
	set KillQuest['I03C'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 210 
	set KillQuest[id][KILLQUEST_MAX] = 280
	set KillQuest[id].string[KILLQUEST_NAME] = "Despairs"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Magnataur_Despair_1
	//abyssal
	set id = 'n08N'
	set KillQuest[1][3] = id
	set KillQuest['I02A'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 229 
	set KillQuest[id][KILLQUEST_MAX] = 299
	set KillQuest[id].string[KILLQUEST_NAME] = "Abyssals"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Ursa_Abyssal_2
	//void
	set id = 'n031'
	set KillQuest[1][4] = id
	set KillQuest['I03I'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 250 
	set KillQuest[id][KILLQUEST_MAX] = 320
	set KillQuest[id].string[KILLQUEST_NAME] = "Voids"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_OgreTauren_Void_5
	//nightmares
	set id = 'n020'
	set KillQuest[1][5] = id
	set KillQuest['I0GE'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 270 
	set KillQuest[id][KILLQUEST_MAX] = 340
	set KillQuest[id].string[KILLQUEST_NAME] = "Nightmares"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Centaur_Nightmare_5
	//hellspawn
	set id = 'n03D'
	set KillQuest[1][6] = id
	set KillQuest['I03J'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 290 
	set KillQuest[id][KILLQUEST_MAX] = 360
	set KillQuest[id].string[KILLQUEST_NAME] = "Hellspawn"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Hell_4
	//denied existence
	set id = 'n03J'
	set KillQuest[1][7] = id
	set KillQuest['I02G'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 30
	set KillQuest[id][KILLQUEST_MIN] = 310 
	set KillQuest[id][KILLQUEST_MAX] = 380
	set KillQuest[id].string[KILLQUEST_NAME] = "Existences"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Devourer_entry
	//astral
	set id = 'n03M'
	set KillQuest[1][8] = id
	set KillQuest['I039'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 330 
	set KillQuest[id][KILLQUEST_MAX] = 400
	set KillQuest[id].string[KILLQUEST_NAME] = "Astrals"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Dragon_Astral_8
	//dimensionals
	set id = 'n026'
	set KillQuest[1][9] = id
	set KillQuest['I0Q1'][0] = id
	set KillQuest[id][KILLQUEST_GOAL] = 20
	set KillQuest[id][KILLQUEST_MIN] = 350 
	set KillQuest[id][KILLQUEST_MAX] = 420
	set KillQuest[id].string[KILLQUEST_NAME] = "Dimensionals"
	set KillQuest[id].rect[KILLQUEST_REGION] = gg_rct_Unbroken_Dimensional_2
endfunction

private struct JVInit
	private static method onInit takes nothing returns nothing
		local integer i = 0

		set ItemData = HashTable.create()
		set UnitData = HashTable.create()
		set KillQuest = HashTable.create()
		set SpellTooltips = HashTable.create()
		set ItemRewards = HashTable.create()
		set ItemPrices = HashTable.create()
		set PrestigeTable = HashTable.create()

		set CrystalRewards = Table.create()
		
		call BlzLoadTOCFile("graphicsmode.toc")
		set IS_HD[GetPlayerId(GetLocalPlayer()) + 1] = GetLocalizedString("IS_HD")
		
		loop
			exitwhen i > 500
			set udg_Experience_Table[i] = R2I(13 * i * Pow(1.4, i / 20.) + 10)
			set udg_RewardGold[i] = Pow(udg_Experience_Table[i], .94) / 8.
			set i = i + 1
		endloop

		set i = 0

		//base experience rates per 5 levels
		loop
			exitwhen i > 400
			if i <= 10 then
				set BaseExperience[i] = 425
			else
				set BaseExperience[i] = (BaseExperience[i - 5] - 17. / (i - 5)) * 0.919
			endif

			set i = i + 5
		endloop

		set udg_Gold_Mod[1] = 1
		set udg_Gold_Mod[2] = Pow(0.55, 0.5)
		set udg_Gold_Mod[3] = Pow(0.50, 0.5)
		set udg_Gold_Mod[4] = Pow(0.45, 0.5)
		set udg_Gold_Mod[5] = Pow(0.40, 0.5)
		set udg_Gold_Mod[6] = Pow(0.35, 0.5)

		set POWERSOF2[0] = 0x1
		set POWERSOF2[1] = 0x2
		set POWERSOF2[2] = 0x4
		set POWERSOF2[3] = 0x8
		set POWERSOF2[4] = 0x10
		set POWERSOF2[5] = 0x20
		set POWERSOF2[6] = 0x40
		set POWERSOF2[7] = 0x80
		set POWERSOF2[8] = 0x100
		set POWERSOF2[9] = 0x200
		set POWERSOF2[10] = 0x400
		set POWERSOF2[11] = 0x800
		set POWERSOF2[12] = 0x1000
		set POWERSOF2[13] = 0x2000
		set POWERSOF2[14] = 0x4000
		set POWERSOF2[15] = 0x8000
		set POWERSOF2[16] = 0x10000
		set POWERSOF2[17] = 0x20000
		set POWERSOF2[18] = 0x40000
		set POWERSOF2[19] = 0x80000
		set POWERSOF2[20] = 0x100000
		set POWERSOF2[21] = 0x200000
		set POWERSOF2[22] = 0x400000
		set POWERSOF2[23] = 0x800000
		set POWERSOF2[24] = 0x1000000
		set POWERSOF2[25] = 0x2000000
		set POWERSOF2[26] = 0x4000000
		set POWERSOF2[27] = 0x8000000
		set POWERSOF2[28] = 0x10000000
		set POWERSOF2[29] = 0x20000000
		set POWERSOF2[30] = 0x40000000

		set infoString[0] = "Use -info # for see more info about your chosen catagory\n\n -info 1, Unit Respawning\n -info 2, Boss Respawning\n -info 3, Safezone\n -info 4, Hardcore\n -info 5, Hardmode\n -info 6, Prestige\n -info 7, Proficiency\n -info 8, Aggro System"
		set infoString[1] = "Most units in this game (besides Bosses, Colosseum, Struggle) will attempt to revive where they died 30 seconds after death. If a player hero/unit is within 800 range they will spawn frozen and invulnerable until no players are around."
		set infoString[2] = "Bosses respawn after 10 minutes and non-hero bosses respawn after 5 minutes, -hardmode speeds up respawns by 25%" 
		set infoString[3] = "The town is protected from enemy invasion and any entering enemy will be teleported back to their original spawn."
		set infoString[4] = "Hardcore players that die without a reincarnation item/spell will be removed from the game and cannot save/load or start a new character. 
		A hardcore hero can only save every 30 minutes- the timer starts upon saving OR upon loading your hardcore hero. 
		Hardcore heroes receive double the bonus from prestiging.
		If you need to save before the timer expires you can use -forcesave to save immediately, but this deletes your hero, leaving you unable to load again in the current game (same as if your hero died)."
		set infoString[5] = "Hardmode doubles the health and damage of bosses, doubles their drop chance, increases their gold/xp/crystal rewards, and speeds up respawn time by 25%.
		Does not apply to Dungeons.
		Automatically turns off when entering Chaos, but can be re-activated."
		set infoString[6] = "You need a |cffffcc00Prestige Token|r to activate a class prestige bonus.\nPrestige bonuses apply to all your existing characters and any new ones.\n|cffffcc00BONUSES:|r\nAttack Damage(+8%): Bloodzerker, Phoenix Ranger, Elite Marksman\nStrength(+6%): Oblivion Guardian, Savior, Warrior\nAgility(+7%): Master Rogue, Assassin, Vampire Lord\nIntelligence(+7%): Dark Summoner, Bard, Dark Savior\nDamage Reduction(+5%): Royal Guardian, Arcane Warrior\nRegeneration(+8%): Priest\nSpellboost(+4%): Elementalist, Arcanist, Thunderblade, Hydromancer\n|cffffcc00ALL:|r Experience Rate(+4%), Gold Find(+2%)"
		set infoString[7] = "Most items in this game have a proficiency requirement in their description.
		While any hero can equip them regardless of proficiency, those lacking proficiency only recieve half stats from the item.
		Check your hero's proficiency with -pf."
		set infoString[8] = "Bosses use a threat meter system for each player that increases when attacked or by casting spells. Distance from the boss reduces the threat you 
		generate significantly when attacking, so melee characters will draw aggro much more quickly-- especially with taunt abilities."
		set infoString[69] = "Nice"

		set prMulti[0] = 'A0A3'
		set prMulti[1] = 'A0IW'
		set prMulti[2] = 'A0IX'
		set prMulti[3] = 'A0IY'
		set prMulti[4] = 'A0IZ'

		//currencies
        set CURRENCY_ICON[0] = "gold.dds"
        set CURRENCY_ICON[1] = "wood.dds"
        set CURRENCY_ICON[2] = "plat.dds"
        set CURRENCY_ICON[3] = "arc.dds"
        set CURRENCY_ICON[4] = "crystal.dds"
	
		//TODO
		set SPELL_FIELD[0] = ABILITY_RLF_ART_DURATION
		set SPELL_FIELD[1] = ABILITY_RLF_AREA_OF_EFFECT
		set SPELL_FIELD[2] = ABILITY_RLF_CAST_RANGE
		set SPELL_FIELD[3] = ABILITY_RLF_CASTING_TIME
		set SPELL_FIELD[4] = ABILITY_RLF_COOLDOWN
		set SPELL_FIELD[5] = ABILITY_RLF_DURATION_HERO
		set SPELL_FIELD[6] = ABILITY_RLF_DURATION_NORMAL

		//might as well use this hashtable
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, LIGHTSEAL.id, LIGHTSEAL.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, DIVINEJUDGEMENT.id, DIVINEJUDGEMENT.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, SAVIORSGUIDANCE.id, SAVIORSGUIDANCE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, HOLYBASH.id, HOLYBASH.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, THUNDERCLAP.id, THUNDERCLAP.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, RIGHTEOUSMIGHT.id, RIGHTEOUSMIGHT.typeid)

		call SaveInteger(SAVE_TABLE, KEY_SPELLS, SNIPERSTANCE.id, SNIPERSTANCE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, TRIROCKET.id, TRIROCKET.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, ASSAULTHELICOPTER.id, ASSAULTHELICOPTER.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, SINGLESHOT.id, SINGLESHOT.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, HANDGRENADE.id, HANDGRENADE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, U235SHELL.id, U235SHELL.typeid)

		call SaveInteger(SAVE_TABLE, KEY_SPELLS, THUNDERDASH.id, THUNDERDASH.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, MONSOON.id, MONSOON.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, BLADESTORM.id, BLADESTORM.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, OMNISLASH.id, OMNISLASH.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, OVERLOAD.id, OVERLOAD.typeid)

		call SaveInteger(SAVE_TABLE, KEY_SPELLS, INSTANTDEATH.id, INSTANTDEATH.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, DEATHSTRIKE.id, DEATHSTRIKE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, HIDDENGUISE.id, HIDDENGUISE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, NERVEGAS.id, NERVEGAS.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, BACKSTAB.id, BACKSTAB.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, PIERCINGSTRIKE.id, PIERCINGSTRIKE.typeid)

		call SaveInteger(SAVE_TABLE, KEY_SPELLS, BODYOFFIRE.id, BODYOFFIRE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, METEOR.id, METEOR.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, MAGNETICSTANCE.id, MAGNETICSTANCE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, INFERNALSTRIKE.id, INFERNALSTRIKE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, MAGNETICSTRIKE.id, MAGNETICSTRIKE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, GATEKEEPERSPACT.id, GATEKEEPERSPACT.typeid)

		call SaveInteger(SAVE_TABLE, KEY_SPELLS, BLOODFRENZY.id, BLOODFRENZY.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, BLOODLEAP.id, BLOODLEAP.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, BLOODCURDLINGSCREAM.id, BLOODCURDLINGSCREAM.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, BLOODCLEAVE.id, BLOODCLEAVE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, RAMPAGE.id, RAMPAGE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, UNDYINGRAGE.id, UNDYINGRAGE.typeid)

		call SaveInteger(SAVE_TABLE, KEY_SPELLS, PARRY.id, PARRY.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, SPINDASH.id, SPINDASH.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, SPINDASH.id2, SPINDASH.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, INTIMIDATINGSHOUT.id, INTIMIDATINGSHOUT.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, WINDSCAR.id, WINDSCAR.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, ADAPTIVESTRIKE.id, ADAPTIVESTRIKE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, ADAPTIVESTRIKE.id2, ADAPTIVESTRIKE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, LIMITBREAK.id, LIMITBREAK.typeid)
		
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, FROSTBLAST.id, FROSTBLAST.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, WHIRLPOOL.id, WHIRLPOOL.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, TIDALWAVE.id, TIDALWAVE.typeid)
		call SaveInteger(SAVE_TABLE, KEY_SPELLS, ICEBARRAGE.id, ICEBARRAGE.typeid)

		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("tier"), ITEM_TIER)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("type"), ITEM_TYPE)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("upg"), ITEM_UPGRADE_MAX)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("req"), ITEM_LEVEL_REQUIREMENT)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("health"), ITEM_HEALTH)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("mana"), ITEM_MANA)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("damage"), ITEM_DAMAGE)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("armor"), ITEM_ARMOR)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("str"), ITEM_STRENGTH)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("agi"), ITEM_AGILITY)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("int"), ITEM_INTELLIGENCE)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("regen"), ITEM_REGENERATION)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("dr"), ITEM_DAMAGE_RESIST)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("mr"), ITEM_MAGIC_RESIST)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("ms"), ITEM_MOVESPEED)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("evasion"), ITEM_EVASION)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("spellboost"), ITEM_SPELLBOOST)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("cc"), ITEM_CRIT_CHANCE)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("cd"), ITEM_CRIT_DAMAGE)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("bat"), ITEM_BASE_ATTACK_SPEED)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("abil"), ITEM_ABILITY)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("abil2"), ITEM_ABILITY2)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("cost"), ITEM_COST)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("limit"), ITEM_LIMIT)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("gold"), ITEM_GOLD_GAIN)
		call SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("discount"), ITEM_DISCOUNT)

		//TODO subject to change?
		set TIER_NAME[0] = ""
		set TIER_NAME[1] = "Common"
		set TIER_NAME[2] = "|cffbbbbbbUncommon|r"
		set TIER_NAME[3] = "|cffffff00Quest|r"
		set TIER_NAME[4] = "|cff999999Ursa|r"
		set TIER_NAME[5] = "|cff999999Ogre|r"
		set TIER_NAME[6] = "|cff999999Unbroken|r"
		set TIER_NAME[7] = "|cff999999Magnataur|r"
		set TIER_NAME[8] = "|cff55ff44Set|r"
		set TIER_NAME[9] = "|cffba0505Boss|r"
		set TIER_NAME[10] = "|cff01b9f5Divine|r"
		set TIER_NAME[11] = "|cffff5050Chaotic Quest|r"
		set TIER_NAME[12] = "Demon"
		set TIER_NAME[13] = "Horror"
		set TIER_NAME[14] = "Despair"
		set TIER_NAME[15] = "Abyssal"
		set TIER_NAME[16] = "Void"
		set TIER_NAME[17] = "Nightmare"
		set TIER_NAME[18] = "Hell"
		set TIER_NAME[19] = "Existence"
		set TIER_NAME[20] = "Astral"
		set TIER_NAME[21] = "Dimensional"
		set TIER_NAME[22] = "|cff05aa05Chaotic Set|r"
		set TIER_NAME[23] = "|cff700909Chaotic Boss|r"
		set TIER_NAME[24] = "|cffa0a0a0Forgotten|r"
		set TIER_NAME[25] = "|cff999999Devourer|r"
		//...
		set TYPE_NAME[0] = ""
		set TYPE_NAME[1] = "Plate"
		set TYPE_NAME[2] = "Fullplate"
		set TYPE_NAME[3] = "Leather"
		set TYPE_NAME[4] = "Cloth"
		set TYPE_NAME[5] = "Shield"
		set TYPE_NAME[6] = "Heavy"
		set TYPE_NAME[7] = "Sword"
		set TYPE_NAME[8] = "Dagger"
		set TYPE_NAME[9] = "Bow"
		set TYPE_NAME[10] = "Staff"
		//...
		set LEVEL_PREFIX[1] = "|cff40bf5fRefined|r"
		set LEVEL_PREFIX[2] = "|cff40bf5fRefined|r"
		set LEVEL_PREFIX[3] = "|cff40bf5fRefined|r"
		set LEVEL_PREFIX[4] = "|cff40bf5fRefined|r"
		set LEVEL_PREFIX[5] = "|cff4087bfRare|r"
		set LEVEL_PREFIX[6] = "|cff4087bfRare|r"
		set LEVEL_PREFIX[7] = "|cff4087bfRare|r"
		set LEVEL_PREFIX[8] = "|cff4087bfRare|r"
		set LEVEL_PREFIX[9] = "|cff7040bfEpic|r"
		set LEVEL_PREFIX[10] = "|cff7040bfEpic|r"
		set LEVEL_PREFIX[11] = "|cff7040bfEpic|r"
		set LEVEL_PREFIX[12] = "|cff7040bfEpic|r"
		set LEVEL_PREFIX[13] = "|cffbf6b40Legendary|r"
		set LEVEL_PREFIX[14] = "|cffbf6b40Legendary|r"
		set LEVEL_PREFIX[15] = "|cffbf6b40Legendary|r"
		set LEVEL_PREFIX[16] = "|cffbf6b40Legendary|r"
		set LEVEL_PREFIX[17] = "|cffc41919Chaos|r"
		set LEVEL_PREFIX[18] = "|cffc41919Chaos|r"
		set LEVEL_PREFIX[19] = "|cffc41919Chaos|r"
		set LEVEL_PREFIX[20] = "|cffc41919Chaos|r"
		//...
		set SPRITE_RARITY[0] = "war3mapImported\\CommonBorder.dds"
		set SPRITE_RARITY[1] = "war3mapImported\\RefinedBorder.dds"
		set SPRITE_RARITY[2] = "war3mapImported\\RefinedBorder.dds"
		set SPRITE_RARITY[3] = "war3mapImported\\RefinedBorder.dds"
		set SPRITE_RARITY[4] = "war3mapImported\\RefinedBorder.dds"
		set SPRITE_RARITY[5] = "war3mapImported\\RareBorder.dds"
		set SPRITE_RARITY[6] = "war3mapImported\\RareBorder.dds"
		set SPRITE_RARITY[7] = "war3mapImported\\RareBorder.dds"
		set SPRITE_RARITY[8] = "war3mapImported\\RareBorder.dds"
		set SPRITE_RARITY[9] = "war3mapImported\\EpicBorder.dds"
		set SPRITE_RARITY[10] = "war3mapImported\\EpicBorder.dds"
		set SPRITE_RARITY[11] = "war3mapImported\\EpicBorder.dds"
		set SPRITE_RARITY[12] = "war3mapImported\\EpicBorder.dds"
		set SPRITE_RARITY[13] = "war3mapImported\\LegendaryBorder.dds"
		set SPRITE_RARITY[14] = "war3mapImported\\LegendaryBorder.dds"
		set SPRITE_RARITY[15] = "war3mapImported\\LegendaryBorder.dds"
		set SPRITE_RARITY[16] = "war3mapImported\\LegendaryBorder.dds"
		set SPRITE_RARITY[17] = "war3mapImported\\ChaosBorder.dds"
		set SPRITE_RARITY[18] = "war3mapImported\\ChaosBorder.dds"
		set SPRITE_RARITY[19] = "war3mapImported\\ChaosBorder.dds"
		set SPRITE_RARITY[20] = "war3mapImported\\ChaosBorder.dds"
		//...
		set ITEM_MULT[0] = 0
		set ITEM_MULT[1] = 0.2
		set ITEM_MULT[2] = 0.4
		set ITEM_MULT[3] = 0.6
		set ITEM_MULT[4] = 0.8
		set ITEM_MULT[5] = 1.2
		set ITEM_MULT[6] = 1.6
		set ITEM_MULT[7] = 2.
		set ITEM_MULT[8] = 2.4
		set ITEM_MULT[9] = 3.2
		set ITEM_MULT[10] = 4.
		set ITEM_MULT[11] = 4.8
		set ITEM_MULT[12] = 5.6
		set ITEM_MULT[13] = 7.
		set ITEM_MULT[14] = 8.4
		set ITEM_MULT[15] = 9.8
		set ITEM_MULT[16] = 11.2
		set ITEM_MULT[17] = 13.4
		set ITEM_MULT[18] = 15.6
		set ITEM_MULT[19] = 17.8
		//...
		set CRYSTAL_PRICE[0] = 1
		set CRYSTAL_PRICE[1] = 1 
		set CRYSTAL_PRICE[2] = 2
		set CRYSTAL_PRICE[3] = 2
		set CRYSTAL_PRICE[4] = 3
		set CRYSTAL_PRICE[5] = 3
		set CRYSTAL_PRICE[6] = 4
		set CRYSTAL_PRICE[7] = 5
		set CRYSTAL_PRICE[8] = 6
		set CRYSTAL_PRICE[9] = 8
		set CRYSTAL_PRICE[10] = 12
		set CRYSTAL_PRICE[11] = 16
		set CRYSTAL_PRICE[12] = 24
		set CRYSTAL_PRICE[13] = 32
		set CRYSTAL_PRICE[14] = 48
		set CRYSTAL_PRICE[15] = 64
		set CRYSTAL_PRICE[16] = 80
		set CRYSTAL_PRICE[17] = 96
		set CRYSTAL_PRICE[18] = 128
		set CRYSTAL_PRICE[19] = 160
		//...
		set PROF[1] = PROF_PLATE
		set PROF[2] = PROF_FULLPLATE
		set PROF[3] = PROF_LEATHER
		set PROF[4] = PROF_CLOTH
		set PROF[5] = PROF_SHIELD
		set PROF[6] = PROF_HEAVY
		set PROF[7] = PROF_SWORD
		set PROF[8] = PROF_DAGGER
		set PROF[9] = PROF_BOW
		set PROF[10] = PROF_STAFF

		set STAT_NAME[ITEM_HEALTH] = "|r |cffff0000Health|r"
		set STAT_NAME[ITEM_MANA] = "|r |cff6699ffMana"
		set STAT_NAME[ITEM_DAMAGE] = "|r |cffff6600Damage|r"
		set STAT_NAME[ITEM_ARMOR] = "|r |cffa4a4feArmor|r"
		set STAT_NAME[ITEM_STRENGTH] = "|r |cffbb0000Strength|r"
		set STAT_NAME[ITEM_AGILITY] = "|r |cff008800Agility|r"
		set STAT_NAME[ITEM_INTELLIGENCE] = "|r |cff2255ffIntelligence|r"
		set STAT_NAME[ITEM_REGENERATION] = "|r |cffa00070Regeneration|r"
		set STAT_NAME[ITEM_DAMAGE_RESIST] = "%|r |cffff8040Damage Resist|r"
		set STAT_NAME[ITEM_MAGIC_RESIST] = "%|r |cff8000ffMagic Resist|r"
		set STAT_NAME[ITEM_MOVESPEED] = "|r |cff888888Movespeed|r"
		set STAT_NAME[ITEM_CRIT_CHANCE] = "x|r |cffffcc00Critical Strike|r"
		set STAT_NAME[ITEM_CRIT_DAMAGE] = "x|r |cffffcc00Critical Strike|r"
		set STAT_NAME[ITEM_EVASION] = "%|r |cff008080Evasion|r"
		set STAT_NAME[ITEM_SPELLBOOST] = "%|r |cff80ffffSpellboost|r"
		set STAT_NAME[ITEM_BASE_ATTACK_SPEED] = "%|r |cff446600Base Attack Speed|r"
		set STAT_NAME[ITEM_GOLD_GAIN] = "%|r |cffffff00Gold Find|r"

		set LIMIT_STRING[1] = "You can only wear one of this item."
		set LIMIT_STRING[2] = "You only have two feet"
		set LIMIT_STRING[3] = "A second set of wings won't help you fly better"
		set LIMIT_STRING[4] = "You can only wear one Bloody armor"
		set LIMIT_STRING[5] = "You can only use one Bloody weapon"
		set LIMIT_STRING[6] = "You can only wear one Absolute Horror armor"
		set LIMIT_STRING[7] = "You can only use one Absolute Horror weapon"
		set LIMIT_STRING[8] = "You can only wear one Legion armor"
		set LIMIT_STRING[9] = "You can only use one Legion weapon"
		set LIMIT_STRING[10] = "You can only wear one Azazoth armor"
		set LIMIT_STRING[11] = "You can only use one Azazoth weapon"
		set LIMIT_STRING[12] = "You can only use one Slaughterer weapon"
		set LIMIT_STRING[13] = "You can only hold one Forgotten gem"
		set LIMIT_STRING[14] = "You can only wear one Ursine Set"
		set LIMIT_STRING[15] = "You can only wear one Ogre Set"
		set LIMIT_STRING[16] = "You can only wear one Unbroken Set"
		set LIMIT_STRING[17] = "You can only wear one Magnataur Set"
		set LIMIT_STRING[18] = "You can only wear one Demon Set"
		set LIMIT_STRING[19] = "You can only wear one Horror Set"
		set LIMIT_STRING[20] = "You can only wear one Despair Set"
		set LIMIT_STRING[21] = "You can only wear one Abyssal Set"
		set LIMIT_STRING[22] = "You can only wear one Void Set"
		set LIMIT_STRING[23] = "You can only wear one Nightmare Set"
		set LIMIT_STRING[24] = "You can only wear one Hell Set"
		set LIMIT_STRING[25] = "You can only wear one Existence Set"
		set LIMIT_STRING[26] = "You can only wear one Astral Set"
		set LIMIT_STRING[27] = "You can only wear one Dimensional Set"
		set LIMIT_STRING[28] = "You can only wear one Devourer Set"

		//quest rewards
		// spider armors
		set ItemRewards['I04M'][0] = 'I0B8'
		set ItemRewards['I04M'][1] = 'I0BA'
		set ItemRewards['I04M'][2] = 'I0B4'
		set ItemRewards['I04M'][3] = 'I0B6'

		set i = 0

		set hstarget[i] = gg_unit_H02A_0568 //oblivion guard
		set hsskinid[i] = 'H02A'
		set hsselectid[i] = 'A07S'
		set hspassiveid[i] = 'A0HQ'
		set i = i + 1
		set hstarget[i] = gg_unit_H03N_0612 //bloodzerker
		set hsskinid[i] = 'H03N'
		set hsselectid[i] = 'A07T'
		set hspassiveid[i] = 'A06N'
		set i = i + 1
		set hstarget[i] = gg_unit_H04Z_0604 //royal guardian
		set hsskinid[i] = 'H04Z'
		set hsselectid[i] = 'A07U'
		set hspassiveid[i] = 'A0I5'
		set i = i + 1
		set hstarget[i] = gg_unit_H012_0605 //warrior
		set hsskinid[i] = 'H012'
		set hsselectid[i] = 'A07V'
		set hspassiveid[i] = 'A0IE'
		set i = i + 1
		set hstarget[i] = gg_unit_U003_0081 //vampire
		set hsskinid[i] = 'U003'
		set hsselectid[i] = 'A029'
		set hspassiveid[i] = 'A05E'
		set i = i + 1
		set hstarget[i] = gg_unit_H01N_0606 //savior
		set hsskinid[i] = 'H01N'
		set hsselectid[i] = 'A07W'
		set hspassiveid[i] = 'A0HW'
		set i = i + 1
		set hstarget[i] = gg_unit_H01S_0607 //dark savior
		set hsskinid[i] = 'H01S'
		set hsselectid[i] = 'A07Z'
		set hspassiveid[i] = 'A0DL'
		set i = i + 1
		set hstarget[i] = gg_unit_H05B_0608 //arcane warrior
		set hsskinid[i] = 'H05B'
		set hsselectid[i] = 'A080'
		set hspassiveid[i] = 'A0I4'
		set i = i + 1
		set hstarget[i] = gg_unit_H029_0617 //arcanist
		set hsskinid[i] = 'H029'
		set hsselectid[i] = 'A081'
		set hspassiveid[i] = 'A0EY'
		set i = i + 1
		set hstarget[i] = gg_unit_O02S_0615 //dark summoner
		set hsskinid[i] = 'O02S'
		set hsselectid[i] = 'A082'
		set hspassiveid[i] = 'A0I0'
		set i = i + 1
		set hstarget[i] = gg_unit_H00R_0610 //bard
		set hsskinid[i] = 'H00R'
		set hsselectid[i] = 'A084'
		set hspassiveid[i] = 'A0HV'
		set i = i + 1
		set hstarget[i] = gg_unit_E00G_0616 //hydromancer
		set hsskinid[i] = 'E00G'
		set hsselectid[i] = 'A086'
		set hspassiveid[i] = 'A0EC'
		set i = i + 1
		set hstarget[i] = gg_unit_E012_0613 //high priestess
		set hsskinid[i] = 'E012'
		set hsselectid[i] = 'A087'
		set hspassiveid[i] = 'A0I2'
		set i = i + 1
		set hstarget[i] = gg_unit_E00W_0614 //elementalist
		set hsskinid[i] = 'E00W'
		set hsselectid[i] = 'A089'
		set hspassiveid[i] = 'A0I3'
		set i = i + 1
		set hstarget[i] = gg_unit_E002_0585 //assassin
		set hsskinid[i] = 'E002'
		set hsselectid[i] = 'A07J'
		set hspassiveid[i] = 'A01N'
		set i = i + 1
		set hstarget[i] = gg_unit_O03J_0609 //thunder blade
		set hsskinid[i] = 'O03J'
		set hsselectid[i] = 'A01P'
		set hspassiveid[i] = 'A039'
		set i = i + 1
		set hstarget[i] = gg_unit_E015_0586 //master rogue
		set hsskinid[i] = 'E015'
		set hsselectid[i] = 'A07L'
		set hspassiveid[i] = 'A0I1'
		set i = i + 1
		set hstarget[i] = gg_unit_E008_0587 //elite marksman
		set hsskinid[i] = 'E008'
		set hsselectid[i] = 'A07M'
		set hspassiveid[i] = 'A070'
		set i = i + 1
		set hstarget[i] = gg_unit_E00X_0611 //phoenix ranger
		set hsskinid[i] = 'E00X'
		set hsselectid[i] = 'A07N'
		set hspassiveid[i] = 'A0I6'

		//call SetItemStats()
		call killquestsetup()
		call HeadhunterQuestSetup()
		call ColosseumSetup()
		call StruggleSetup()
	endmethod
endstruct

endlibrary
