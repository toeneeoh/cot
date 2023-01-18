library Units initializer SpawnSetup requires Functions

globals 
    unit array PreChaosBoss
    unit array ChaosBoss
    location array PreChaosBossLoc
    real array PreChaosBossFacing
    string array PreChaosBossName
    integer array PreChaosBossID
    integer array BossItemType
    integer array BossLevel
    timer array HeroGraveTimer
    constant integer REGION_GAP = 25
    //group Sins = CreateGroup()
endglobals

function SpawnSetup takes nothing returns nothing
	set RegionCount[25]= gg_rct_Demon_Wiz_and_Norm_1
	set RegionCount[26]= gg_rct_Demon_Wiz_and_Norm_2
	set RegionCount[27]= gg_rct_Demon_Wiz_and_Norm_3
	set RegionCount[28]= gg_rct_Demon_Wiz_and_Norm_4
	set RegionCount[29]= gg_rct_Demon_Wiz_and_Norm_5
	set RegionCount[30]= gg_rct_Demon_Wiz_and_Norm_6
	set RegionCount[31]= gg_rct_Demon_Wiz_and_Norm_8
	set RegionCount[50]= gg_rct_Mindless_Beasts_Spawn_1
	set RegionCount[51]= gg_rct_Mindless_Beasts_Spawn_2
	set RegionCount[52]= gg_rct_Mindless_Beasts_Spawn_3
	set RegionCount[53]= gg_rct_Mindless_Beasts_Spawn_4
	set RegionCount[54]= gg_rct_Mindless_Beasts_Spawn_5
	set RegionCount[75]= gg_rct_Spider_1
	set RegionCount[76]= gg_rct_Spider_2
	set RegionCount[100]= gg_rct_Despair_Spawn_1
	set RegionCount[101]= gg_rct_Despair_Spawn_3
	set RegionCount[102]= gg_rct_Despair_Spawn_4
	set RegionCount[103]= gg_rct_Despair_Spawn_5
	set RegionCount[104]= gg_rct_Despair_Spawn_6
	set RegionCount[105]= gg_rct_Despair_Spawn_7
	set RegionCount[106]= gg_rct_Despair_Spawn_8
	set RegionCount[107]= gg_rct_Despair_Spawn_9
	set RegionCount[108]= gg_rct_Despair_Spawn_10
	set RegionCount[109]= gg_rct_Despair_Spawn_11
	set RegionCount[110]= gg_rct_Despair_Spawn_12
	set RegionCount[111]= gg_rct_Despair_Spawn_13
	set RegionCount[112]= gg_rct_Despair_Spawn_14
	set RegionCount[113]= gg_rct_Despair_Spawn_15
	set RegionCount[114]= gg_rct_Despair_Spawn_16
	set RegionCount[115]= gg_rct_Despair_Spawn_17
	set RegionCount[116]= gg_rct_Despair_Spawn_18
	set RegionCount[117]= gg_rct_Despair_Spawn_19
	set RegionCount[118]= gg_rct_Despair_Spawn_20
	set RegionCount[125] = gg_rct_Bear_1
	set RegionCount[126] = gg_rct_Bear_2
	set RegionCount[127] = gg_rct_Bear_3
	set RegionCount[150]= gg_rct_Unknown_Evil_Spawn_1
	set RegionCount[151]= gg_rct_Unknown_Evil_Spawn_2
	set RegionCount[152]= gg_rct_Unknown_Evil_Spawn_4
	set RegionCount[153]= gg_rct_Unknown_Evil_Spawn_10
	set RegionCount[154]= gg_rct_Unknown_Evil_Spawn_11
	set RegionCount[155]= gg_rct_Unknown_Evil_Spawn_12
	set RegionCount[175]= gg_rct_Unbroken_Spawn_1
	set RegionCount[176]= gg_rct_Unbroken_Spawn_2
	set RegionCount[177]= gg_rct_Unbroken_Spawn_3
	set RegionCount[178]= gg_rct_Unbroken_Spawn_4
	set RegionCount[200]= gg_rct_Hell_1
	set RegionCount[201]= gg_rct_Hell_2
	set RegionCount[202]= gg_rct_Hell_3
	set RegionCount[203]= gg_rct_Hell_4
	set RegionCount[225]= gg_rct_Unknown_Evil_Spawn_5
	set RegionCount[226]= gg_rct_Unknown_Evil_Spawn_6
	set RegionCount[227]= gg_rct_Unknown_Evil_Spawn_7
	set RegionCount[228]= gg_rct_Unknown_Evil_Spawn_8
	set RegionCount[229]= gg_rct_Unknown_Evil_Spawn_9
	set RegionCount[250] = gg_rct_Magnataur
	set RegionCount[275] = gg_rct_Hydra_Spawn
	set RegionCount[300]= gg_rct_Astral_Spawn_1
	set RegionCount[301]= gg_rct_Astral_Spawn_2
	set RegionCount[302]= gg_rct_Astral_Spawn_3
	set RegionCount[303]= gg_rct_Astral_Spawn_4
	set RegionCount[304]= gg_rct_Astral_Spawn_5
	set RegionCount[305]= gg_rct_Astral_Spawn_6
	set RegionCount[306]= gg_rct_Astral_Spawn_7
	set RegionCount[307]= gg_rct_Astral_Spawn_8
	set RegionCount[308]= gg_rct_Astral_Spawn_9
	set RegionCount[325] = gg_rct_Denied_Existence_Spawn_1
	set RegionCount[326] = gg_rct_Denied_Existence_Spawn_2
	set RegionCount[350] = gg_rct_Azazoth_Circle_Spawn
	set RegionCount[375]= gg_rct_Mindless_Beasts_Spawn_1
	set RegionCount[376]= gg_rct_Mindless_Beasts_Spawn_2
	set RegionCount[377]= gg_rct_Mindless_Beasts_Spawn_3
	set RegionCount[378]= gg_rct_Mindless_Beasts_Spawn_4
	set RegionCount[379]= gg_rct_Mindless_Beasts_Spawn_5
	set RegionCount[380]= gg_rct_Unbroken_Spawn_1
	set RegionCount[381]= gg_rct_Unbroken_Spawn_2
	set RegionCount[382]= gg_rct_Unbroken_Spawn_3
	set RegionCount[383]= gg_rct_Unbroken_Spawn_4

    call SetTableData(UnitData, 'nitt', "count 18 spawn 1") //ice troll trapper
    set UnitData[0][0]  = 'nitt'
    call SetTableData(UnitData, 'nits', "count 10 spawn 1") //ice troll berserker
    set UnitData[0][1]  = 'nits'
    call SetTableData(UnitData, 'ntks', "count 14 spawn 2") //tuskarr sorc
    set UnitData[0][2]  = 'ntks'
    call SetTableData(UnitData, 'ntkw', "count 16 spawn 2") //tuskarr warrior
    set UnitData[0][3]  = 'ntkw'
    call SetTableData(UnitData, 'ntkc', "count 11 spawn 2") //tuskarr chieftain
    set UnitData[0][4]  = 'ntkc'
    call SetTableData(UnitData, 'nnwr', "count 12 spawn 3") //nerubian Seer
    set UnitData[0][5]  = 'nnwr'
    call SetTableData(UnitData, 'nnws', "count 15 spawn 3") //nerubian spider lord
    set UnitData[0][6]  = 'nnws'
    call SetTableData(UnitData, 'nfpu', "count 38 spawn 4") //polar furbolg warrior 
    set UnitData[0][7]  = 'nfpu'
    call SetTableData(UnitData, 'nfpe', "count 22 spawn 4") //polar furbolg elder shaman
    set UnitData[0][8]  = 'nfpe'
    call SetTableData(UnitData, 'nplg', "count 20 spawn 5") //giant polar bear
    set UnitData[0][9]  = 'nplg'
    call SetTableData(UnitData, 'nmdr', "count 16 spawn 5") //dire mammoth
    set UnitData[0][10]  = 'nmdr'
    call SetTableData(UnitData, 'n01G', "count 55 spawn 6") //ogre overlord
    set UnitData[0][11]  = 'n01G'
    call SetTableData(UnitData, 'o01G', "count 40 spawn 6") //tauren
    set UnitData[0][12]  = 'o01G'
    call SetTableData(UnitData, 'nfod', "count 18 spawn 7") //unbroken deathbringer
    set UnitData[0][13]  = 'nfod'
    call SetTableData(UnitData, 'nfor', "count 15 spawn 7") //unbroken trickster
    set UnitData[0][14]  = 'nfor'
    call SetTableData(UnitData, 'nubw', "count 12 spawn 7") //unbroken darkweaver
    set UnitData[0][15]  = 'nubw'
    call SetTableData(UnitData, 'nvdl', "count 16 spawn 8") //lesser hellfire
    set UnitData[0][16]  = 'nvdl'
    call SetTableData(UnitData, 'nvdw', "count 20 spawn 8") //lesser hellhound
    set UnitData[0][17]  = 'nvdw'
    call SetTableData(UnitData, 'n027', "count 36 spawn 9") //centaur lancer
    set UnitData[0][18]  = 'n027'
    call SetTableData(UnitData, 'n024', "count 28 spawn 9") //centaur ranger
    set UnitData[0][19]  = 'n024'
    call SetTableData(UnitData, 'n028', "count 16 spawn 9") //centaur mage
    set UnitData[0][20]  = 'n028'
    call SetTableData(UnitData, 'n01M', "count 45 spawn 10") //magnataur destroyer
    set UnitData[0][21]  = 'n01M'
    call SetTableData(UnitData, 'n08M', "count 20 spawn 10") //forgotten one
    set UnitData[0][22]  = 'n08M'
    call SetTableData(UnitData, 'n01H', "count 4 spawn 11") //ancient hydra
    set UnitData[0][23]  = 'n01H'
    call SetTableData(UnitData, 'n02P', "count 18 spawn 12")//frost dragon
    set UnitData[0][24]  = 'n02P'
    call SetTableData(UnitData, 'n01R', "count 18 spawn 12")//frost drake
    set UnitData[0][25]  = 'n01R'
    call SetTableData(UnitData, 'n099', "count 1 spawn 14")//frost elder
    set UnitData[0][26]  = 'n099'
    call SetTableData(UnitData, 'nano', "count 7 spawn 13")//medean berserker
    set UnitData[0][27]  = 'nano'
    call SetTableData(UnitData, 'n02L', "count 15 spawn 13")//medean devourer
    set UnitData[0][28]  = 'n02L'
    set UnitData[10][0] = 28

	//chaotic units
    call SetTableData(UnitData, 'n033', "count 20 chaos 1 spawn 1") //demon
    set UnitData[1][0]  = 'n033'
    call SetTableData(UnitData, 'n034', "count 11 chaos 1 spawn 1") //demon wizard
    set UnitData[1][1]  = 'n034'
    call SetTableData(UnitData, 'n03C', "count 24 chaos 1 spawn 15") //horror young
    set UnitData[1][2]  = 'n03C'
    call SetTableData(UnitData, 'n03A', "count 46 chaos 1 spawn 15") //horror mindless
    set UnitData[1][3]  = 'n03A'
    call SetTableData(UnitData, 'n03B', "count 11 chaos 1 spawn 15") //horror leader
    set UnitData[1][4]  = 'n03B'
    call SetTableData(UnitData, 'n03F', "count 62 chaos 1 spawn 10") //despair
    set UnitData[1][5]  = 'n03F'
    call SetTableData(UnitData, 'n01W', "count 30 chaos 1 spawn 10") //despair wizard
    set UnitData[1][6]  = 'n01W'
    call SetTableData(UnitData, 'n00X', "count 15 chaos 1 spawn 4") //abyssal beast
    set UnitData[1][7]  = 'n00X'
    call SetTableData(UnitData, 'n08N', "count 30 chaos 1 spawn 4") //abyssal guardian
    set UnitData[1][8]  = 'n08N'
    call SetTableData(UnitData, 'n00W', "count 30 chaos 1 spawn 4") //abyssal spirit
    set UnitData[1][9]  = 'n00W'
    call SetTableData(UnitData, 'n030', "count 25 chaos 1 spawn 6") //void seeker
    set UnitData[1][10]  = 'n030'
    call SetTableData(UnitData, 'n031', "count 35 chaos 1 spawn 6") //void keeper
    set UnitData[1][11]  = 'n031'
    call SetTableData(UnitData, 'n02Z', "count 35 chaos 1 spawn 6") //void mother
    set UnitData[1][12]  = 'n02Z'
    call SetTableData(UnitData, 'n020', "count 22 chaos 1 spawn 9") //nightmare creature
    set UnitData[1][13]  = 'n020'
    call SetTableData(UnitData, 'n02J', "count 18 chaos 1 spawn 9") //nightmare spirit
    set UnitData[1][14]  = 'n02J'
    call SetTableData(UnitData, 'n03E', "count 18 chaos 1 spawn 8") //spawn of hell
    set UnitData[1][15]  = 'n03E'
    call SetTableData(UnitData, 'n03D', "count 16 chaos 1 spawn 8") //death dealer
    set UnitData[1][16]  = 'n03D'
    call SetTableData(UnitData, 'n03G', "count 6 chaos 1 spawn 8") //lord of plague
    set UnitData[1][17]  = 'n03G'
    call SetTableData(UnitData, 'n03J', "count 24 chaos 1 spawn 13") //denied existence
    set UnitData[1][18]  = 'n03J'
    call SetTableData(UnitData, 'n01X', "count 13 chaos 1 spawn 13") //deprived existence
    set UnitData[1][19]  = 'n01X'
    call SetTableData(UnitData, 'n03M', "count 24 chaos 1 spawn 12") //astral being
    set UnitData[1][20]  = 'n03M'
    call SetTableData(UnitData, 'n01V', "count 13 chaos 1 spawn 12") //astral entity
    set UnitData[1][21]  = 'n01V'
    call SetTableData(UnitData, 'n026', "count 22 chaos 1 spawn 3") //planeswalker
    set UnitData[1][22]  = 'n026'
    call SetTableData(UnitData, 'n03T', "count 18 chaos 1 spawn 3") //planeshifter
    set UnitData[1][23]  = 'n03T'
    set UnitData[11][0] = 23

    //forgotten units
    set forgottenTypes[0] = 'o030' //corpse basher
    set forgottenTypes[1] = 'o033' //destroyer
    set forgottenTypes[2] = 'o036' //spirit
    set forgottenTypes[3] = 'o02W' //warrior
    set forgottenTypes[4] = 'o02Y' //monster
endfunction

function UnitSetup takes nothing returns nothing
    local group ug = CreateGroup()
    local integer i = 0
    local integer i2 = 1
    local real angle
    local real x
    local real y
    local unit target
    
    set udg_PunchingBag[1] = gg_unit_h02D_0672
    set udg_PunchingBag[2] = gg_unit_h02E_0674
	set BagLoc[1] = GetUnitLoc(gg_unit_h02D_0672)
	set BagLoc[2] = GetUnitLoc(gg_unit_h02E_0674)
    
    set udg_TalkToMe13 = AddSpecialEffectTarget("Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl",gg_unit_n0A1_0164,"overhead")
	set udg_TalkToMe20 = AddSpecialEffectTarget("Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl",gg_unit_n02Q_0382,"overhead")

    call PauseUnit(gg_unit_O01A_0372, true)//Zeknen
    call UnitAddAbility(gg_unit_O01A_0372, 'Avul')
    call ShowUnit( gg_unit_n0A1_0164, false )//angel
    call ShowUnit( gg_unit_n02A_0007, false )//shops
    call ShowUnit( gg_unit_n03P_0047, false )//
    call ShowUnit( gg_unit_n029_0046, false )//
    call ShowUnit( gg_unit_n02B_0049, false )//
    call ShowUnit( gg_unit_n02C_0048, false )//
    
    call GroupEnumUnitsOfPlayer(ug, Player(PLAYER_NEUTRAL_PASSIVE), Condition(function isvillager))
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if target != gg_unit_H01Y_0099 and target != gg_unit_H01T_0259 then
            call IssueImmediateOrder(target, "metamorphosis")
            call UnitAddAbility(target, 'Aloc')
        endif
    endloop

    set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h00G', 0, 0, bj_UNIT_FACING )
    set x = GetRectCenterX(gg_rct_ColoBanner1)
    set y = GetRectCenterY(gg_rct_ColoBanner1)
    call SetUnitPathing( target, false )
    call SetUnitPosition(target, x, y)
    set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h00G', 0, 0, 90.00 )
    set x = GetRectCenterX(gg_rct_ColoBanner2)
    set y = GetRectCenterY(gg_rct_ColoBanner2)
    call SetUnitPathing(target, false )
    call SetUnitPosition(target, x, y)
    set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h00G', 0, 0, 90.00 )
    set x = GetRectCenterX(gg_rct_ColoBanner3)
    set y = GetRectCenterY(gg_rct_ColoBanner3)
    call SetUnitPathing(target, false )
    call SetUnitPosition(target, x, y)
    set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h00G', 0, 0, bj_UNIT_FACING )
    set x = GetRectCenterX(gg_rct_ColoBanner4)
    set y = GetRectCenterY(gg_rct_ColoBanner4)
    call SetUnitPathing(target, false )
    call SetUnitPosition(target, x, y)

    set PreChaosBossLoc[0] = Location(-11692., -12774.)
    set PreChaosBossFacing[0] = 45.
    set PreChaosBossID[0] = 'O002'
    set PreChaosBossName[0] = "Minotaur"
    set BossLevel[0] = 75
    set BossItemType[0] = 'I03T'
    set BossItemType[1] = 'I0FW'
    set BossItemType[2] = 'I078'
    set BossItemType[3] = 'I076'
    set BossItemType[4] = 'I07U'

    set PreChaosBossLoc[1] = Location(-15435., -14354.)
    set PreChaosBossFacing[1] = 270.
    set PreChaosBossID[1] = 'H045'
    set PreChaosBossName[1] = "Forgotten Mystic"
    set BossLevel[1] = 100
    set BossItemType[6] = 'I03U'
    set BossItemType[7] = 'I07F'
    set BossItemType[8] = 'I0F3'
    set BossItemType[9] = 'I03Y'
    set BossItemType[10] = 'I02C'
    set BossItemType[11] = 'I065'

    set PreChaosBossLoc[2] = GetRectCenter(gg_rct_Hell_Spawn_Boss)
    set PreChaosBossFacing[2] = 315.
    set PreChaosBossID[2] = 'U00G'
    set PreChaosBossName[2] = "Hellfire Magi"
    set BossLevel[2] = 120
    set BossItemType[12] = 'I03Y'
    set BossItemType[13] = 'I0FA'
    set BossItemType[14] = 'I0FU'
    set BossItemType[15] = 'I031'
    set BossItemType[16] = 'I02J'

    set PreChaosBossLoc[3] = Location(11520., 15466.)
    set PreChaosBossFacing[3] = 225.
    set PreChaosBossID[3] = 'H01V'
    set PreChaosBossName[3] = "Last Dwarf"
    set BossLevel[3] = 100
    set BossItemType[18] = 'I03Y'
    set BossItemType[19] = 'I079'
    set BossItemType[20] = 'I0FC'
    set BossItemType[21] = 'I033'
    set BossItemType[22] = 'I07B'

    set PreChaosBossLoc[4] = GetRectCenter(gg_rct_Dark_Soul_Boss_Spawn)
    set PreChaosBossFacing[4] = 270.
    set PreChaosBossID[4] = 'H02H'
    set PreChaosBossName[4] = "Vengeful Test Paladin"
    set BossLevel[4] = 140
    set BossItemType[24] = 'I03T'
    set BossItemType[25] = 'I03Y'
    set BossItemType[26] = 'I0F9'
    set BossItemType[27] = 'I03P'
    set BossItemType[28] = 'I0FX'
    set BossItemType[29] = 'I02Z'

    set PreChaosBossLoc[5] = GetRectCenter(gg_rct_Thanatos_Spawn)
    set PreChaosBossFacing[5] = 320.
    set PreChaosBossID[5] = 'O01B'
    set PreChaosBossName[5] = "Dragoon"
    set BossLevel[5] = 100
    set BossItemType[30] = 'I03V'
    set BossItemType[31] = 'I0EY'
    set BossItemType[32] = 'I04N'
    set BossItemType[33] = 'I0EX'
    set BossItemType[34] = 'I046'
    set BossItemType[35] = 'I03Y'

    set PreChaosBossLoc[6] = Location(6932., -14177.)
    set PreChaosBossFacing[6] = 0.
    set PreChaosBossID[6] = 'H040'
    set PreChaosBossName[6] = "Death Knight"
    set BossLevel[6] = 120
    set BossItemType[36] = 'I02B'
    set BossItemType[37] = 'I02J'
    set BossItemType[38] = 'I03Y'

    set PreChaosBossLoc[7] = Location(-12406., -1069.)
    set PreChaosBossFacing[7] = 0.
    set PreChaosBossID[7] = 'H020'
    set PreChaosBossName[7] = "Siren of the Tides"
    set BossLevel[7] = 75
    set BossItemType[42] = 'I09L'
    set BossItemType[43] = 'I09F'
    set BossItemType[44] = 'I03Y'

    set PreChaosBossLoc[8] = Location(15816., 6250.)
    set PreChaosBossFacing[8] = 180.
    set PreChaosBossID[8] = 'n02H'
    set PreChaosBossName[8] = "Super Fun Happy Yeti"

    set PreChaosBossLoc[9] = Location(-5242., -15630.)
    set PreChaosBossFacing[9] = 135.
    set PreChaosBossID[9] = 'n03L'
    set PreChaosBossName[9] = "King of Ogres"

    set PreChaosBossLoc[10] = Location(10606., -10340.)
    set PreChaosBossFacing[10] = 215.
    set PreChaosBossID[10] = 'n02U'
    set PreChaosBossName[10] = "Nerubian Empress"

    set PreChaosBossLoc[11] = Location(-16040., 6579.)
    set PreChaosBossFacing[11] = 45.
    set PreChaosBossID[11] = 'nplb'
    set PreChaosBossName[11] = "Giant Polar Bear"

    set PreChaosBossLoc[12] = Location(-1840., -27400.)
    set PreChaosBossFacing[12] = 230.
    set PreChaosBossID[12] = 'H04Q'
    set PreChaosBossName[12] = "The Goddesses"
    set BossLevel[12] = 180
    set BossItemType[72] = 'I04I'
    set BossItemType[73] = 'I030'
    set BossItemType[74] = 'I031'
    set BossItemType[75] = 'I02Z'
    set BossItemType[76] = 'I03Y'

    set PreChaosBossLoc[13] = Location(-1977., -27116.) //hate
    set PreChaosBossFacing[13] = 230.
    set PreChaosBossID[13] = 'E00B'
    set BossLevel[13] = 180
    set BossItemType[78] = 'I02Z'
    set BossItemType[79] = 'I03Y'
    set BossItemType[80] = 'I02B'

    set PreChaosBossLoc[14] = Location(-1560., -27486.) //love
    set PreChaosBossFacing[14] = 230.
    set PreChaosBossID[14] = 'E00D'
    set BossLevel[14] = 180
    set BossItemType[84] = 'I030'
    set BossItemType[85] = 'I03Y'
    set BossItemType[86] = 'I0EY'

    set PreChaosBossLoc[15] = Location(-1689., -27210.) //knowledge
    set PreChaosBossFacing[15] = 230.
    set PreChaosBossID[15] = 'E00C'
    set BossLevel[15] = 180
    set BossItemType[90] = 'I03U'
    set BossItemType[91] = 'I03Y'
    set BossItemType[92] = 'I02B'

    set i = 0
    loop
        exitwhen i > BOSS_TOTAL
        set PreChaosBoss[i] = CreateUnitAtLoc(pboss, PreChaosBossID[i], PreChaosBossLoc[i], PreChaosBossFacing[i])
        call SetHeroLevel(PreChaosBoss[i], BossLevel[i], false)
        set i2 = 0
        loop
            exitwhen BossItemType[i * 6 + i2] == 0 or i2 > 5
            call UnitAddItemById(PreChaosBoss[i], BossItemType[i * 6 + i2])
            set i2 = i2 + 1
        endloop
        set i = i + 1
    endloop

    call ShowUnit( PreChaosBoss[BOSS_LIFE], false )//gods
    call ShowUnit( PreChaosBoss[BOSS_LOVE], false )
    call ShowUnit( PreChaosBoss[BOSS_HATE], false )
    call ShowUnit( PreChaosBoss[BOSS_KNOWLEDGE], false )

    //hero circle
    
    set i = 475
    set angle = bj_PI * HERO_TOTAL / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_H02A_0568, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //oblivion
    call SetUnitFacingTimed(gg_unit_H02A_0568, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_H02A_0568), 21643 - GetUnitX(gg_unit_H02A_0568)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 1) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_H03N_0612, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //bloodzerker
    call SetUnitFacingTimed(gg_unit_H03N_0612, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_H03N_0612), 21643 - GetUnitX(gg_unit_H03N_0612)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 2) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_H04Z_0604, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //royal guardian
    call SetUnitFacingTimed(gg_unit_H04Z_0604, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_H04Z_0604), 21643 - GetUnitX(gg_unit_H04Z_0604)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 3) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_H012_0605, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //warrior
    call SetUnitFacingTimed(gg_unit_H012_0605, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_H012_0605), 21643 - GetUnitX(gg_unit_H012_0605)), 0)

    set angle = bj_PI * (HERO_TOTAL - 4) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_U003_0081, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //vampire
    call SetUnitFacingTimed(gg_unit_U003_0081, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_U003_0081), 21643 - GetUnitX(gg_unit_U003_0081)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 5) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_H01N_0606, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //savior
    call SetUnitFacingTimed(gg_unit_H01N_0606, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_H01N_0606), 21643 - GetUnitX(gg_unit_H01N_0606)), 0)

    set angle = bj_PI * (HERO_TOTAL - 6) / (HERO_TOTAL * 0.5)
   
    call SetUnitPosition(gg_unit_H01S_0607, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //dark savior
    call SetUnitFacingTimed(gg_unit_H01S_0607, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_H01S_0607), 21643 - GetUnitX(gg_unit_H01S_0607)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 7) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_H05B_0608, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //arcane warrior
    call SetUnitFacingTimed(gg_unit_H05B_0608, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_H05B_0608), 21643 - GetUnitX(gg_unit_H05B_0608)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 8) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_H029_0617, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //arcanist
    call SetUnitFacingTimed(gg_unit_H029_0617, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_H029_0617), 21643 - GetUnitX(gg_unit_H029_0617)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 9) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_O02S_0615, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //dark summoner
    call SetUnitFacingTimed(gg_unit_O02S_0615, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_O02S_0615), 21643 - GetUnitX(gg_unit_O02S_0615)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 10) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_H00R_0610, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //bard
    call SetUnitFacingTimed(gg_unit_H00R_0610, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_H00R_0610), 21643 - GetUnitX(gg_unit_H00R_0610)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 11) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_E00G_0616, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //hydromancer
    call SetUnitFacingTimed(gg_unit_E00G_0616, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_E00G_0616), 21643 - GetUnitX(gg_unit_E00G_0616)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 12) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_E012_0613, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //high priestess
    call SetUnitFacingTimed(gg_unit_E012_0613, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_E012_0613), 21643 - GetUnitX(gg_unit_E012_0613)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 13) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_E00W_0614, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //elementalist
    call SetUnitFacingTimed(gg_unit_E00W_0614, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_E00W_0614), 21643 - GetUnitX(gg_unit_E00W_0614)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 14) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_E002_0585, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //assassin
    call SetUnitFacingTimed(gg_unit_E002_0585, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_E002_0585), 21643 - GetUnitX(gg_unit_E002_0585)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 15) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_O03J_0609, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //thunder blade
    call SetUnitFacingTimed(gg_unit_O03J_0609, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_O03J_0609), 21643 - GetUnitX(gg_unit_O03J_0609)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 16) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_E015_0586, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //master rogue
    call SetUnitFacingTimed(gg_unit_E015_0586, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_E015_0586), 21643 - GetUnitX(gg_unit_E015_0586)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 17) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_E008_0587, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //elite marksman
    call SetUnitFacingTimed(gg_unit_E008_0587, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_E008_0587), 21643 - GetUnitX(gg_unit_E008_0587)), 0)
    
    set angle = bj_PI * (HERO_TOTAL - 18) / (HERO_TOTAL * 0.5)
    
    call SetUnitPosition(gg_unit_E00X_0611, 21643 + i * Cos(angle), 3447 + i * Sin(angle)) //phoenix ranger
    call SetUnitFacingTimed(gg_unit_E00X_0611, bj_RADTODEG * Atan2(3447 - GetUnitY(gg_unit_E00X_0611), 21643 - GetUnitX(gg_unit_E00X_0611)), 0)

    call DestroyGroup(ug)
    
    set ug = null
endfunction

endlibrary
