library Save initializer SaveSetup requires Functions

	globals
        hashtable SAVE_TABLE = InitHashtable()
        integer KEY_ITEMS = 1
        integer KEY_UNITS = 2
	endglobals

function SaveSetup takes nothing returns nothing
    // This will be the directory the save codes will be saved to.
    set udg_MapName = "CoT Nevermore 1.33.19"
    set udg_SaveUnitType[0] = 0
    set udg_SaveUnitType[1] = 'H029'
    set udg_SaveUnitType[2] = 'E002'
    set udg_SaveUnitType[3] = 'E008'
    set udg_SaveUnitType[4] = 'E00G'
    set udg_SaveUnitType[5] = 'E00X'
    set udg_SaveUnitType[6] = 'E00W'
    set udg_SaveUnitType[7] = 'E012'
    set udg_SaveUnitType[8] = 'E015'
    set udg_SaveUnitType[9] = 'H01N'
    set udg_SaveUnitType[10] = 'H00R'
    set udg_SaveUnitType[11] = 'H05B'
    set udg_SaveUnitType[12] = 'H03N'
    set udg_SaveUnitType[13] = 'H01S'
    set udg_SaveUnitType[14] = 'O02S'
    set udg_SaveUnitType[15] = 'H02A'
    set udg_SaveUnitType[16] = 'H04Z'
    set udg_SaveUnitType[17] = 'O03J'
    set udg_SaveUnitType[18] = 'H012'
	set udg_SaveUnitType[19] = 'H00H'
	set udg_SaveUnitType[20] = 'O018'
	set udg_SaveUnitType[21] = 'U003'
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[1], 1)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[2], 2)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[3], 3)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[4], 4)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[5], 5)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[6], 6)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[7], 7)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[8], 8)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[9], 9)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[10], 10)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[11], 11)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[12], 12)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[13], 13)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[14], 14)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[15], 15)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[16], 16)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[17], 17)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[18], 18)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[19], 19)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[20], 20)
	call SaveInteger(SAVE_TABLE, KEY_UNITS, udg_SaveUnitType[21], 21)
    set udg_SaveUnitTypeMax = 25

    set udg_SaveItemType[0] = 0
	set udg_SaveItemType[1]='I073'
	set udg_SaveItemType[2]='I075'
	set udg_SaveItemType[3]='I06Z'
	set udg_SaveItemType[4]='I06W'
	set udg_SaveItemType[5]='I04T'
	set udg_SaveItemType[6]='I06S'
	set udg_SaveItemType[7]='I06U'
	set udg_SaveItemType[8]='I06O'
	set udg_SaveItemType[9]='I06Q'
	set udg_SaveItemType[10]='I0CK'
	set udg_SaveItemType[11]='I0CU'
	set udg_SaveItemType[12]='I0CT'
	set udg_SaveItemType[13]='I0BN'
	set udg_SaveItemType[14]='I0BO'
	set udg_SaveItemType[15]='I07E'
	set udg_SaveItemType[16]='I07I'
	set udg_SaveItemType[17]='I07G'
	set udg_SaveItemType[18]='I07C'
	set udg_SaveItemType[19]='I07A'
	set udg_SaveItemType[20]='I07M'
	set udg_SaveItemType[21]='I07L'
	set udg_SaveItemType[22]='I07P'
	set udg_SaveItemType[23]='I077'
	set udg_SaveItemType[24]='I07K'
	set udg_SaveItemType[25]='I05D'
	set udg_SaveItemType[26]='I0CV'
	set udg_SaveItemType[27]='I0CW'
	set udg_SaveItemType[28]='I0CX'
	set udg_SaveItemType[29]='I0C2'
	set udg_SaveItemType[30]='I0C1'
	set udg_SaveItemType[31]='I087'
	set udg_SaveItemType[32]='I089'
	set udg_SaveItemType[33]='I083'
	set udg_SaveItemType[34]='I081'
	set udg_SaveItemType[35]='I07X'
	set udg_SaveItemType[36]='I07V'
	set udg_SaveItemType[37]='I07Z'
	set udg_SaveItemType[38]='I07R'
	set udg_SaveItemType[39]='I07T'
	set udg_SaveItemType[40]='I05O'
	set udg_SaveItemType[41]='I05P'
	set udg_SaveItemType[42]='I0CY'
	set udg_SaveItemType[43]='I0CZ'
	set udg_SaveItemType[44]='I0D3'
	set udg_SaveItemType[45]='I0BQ'
	set udg_SaveItemType[46]='I0BP'
	set udg_SaveItemType[47]='I09X'
	set udg_SaveItemType[48]='I0A0'
	set udg_SaveItemType[49]='I0A2'
	set udg_SaveItemType[50]='I0A5'
	set udg_SaveItemType[51]='I06D'
	set udg_SaveItemType[52]='I06A'
	set udg_SaveItemType[53]='I06B'
	set udg_SaveItemType[54]='I06C'
	set udg_SaveItemType[55]='I09N'
	set udg_SaveItemType[56]='I0C9'
	set udg_SaveItemType[57]='I0C8'
	set udg_SaveItemType[58]='I0C7'
	set udg_SaveItemType[59]='I0C6'
	set udg_SaveItemType[60]='I0C5'
	set udg_SaveItemType[61]='I08S'
	set udg_SaveItemType[62]='I08U'
	set udg_SaveItemType[63]='I08O'
	set udg_SaveItemType[64]='I08M'
	set udg_SaveItemType[65]='I08D'
	set udg_SaveItemType[66]='I08C'
	set udg_SaveItemType[67]='I08J'
	set udg_SaveItemType[68]='I08H'
	set udg_SaveItemType[69]='I08G'
	set udg_SaveItemType[70]='I04Y'
	set udg_SaveItemType[71]='I04W'
	set udg_SaveItemType[72]='I08N'
	set udg_SaveItemType[73]='I055'
	set udg_SaveItemType[74]='I0D7'
	set udg_SaveItemType[75]='I0D5'
	set udg_SaveItemType[76]='I0D6'
	set udg_SaveItemType[77]='I0C4'
	set udg_SaveItemType[78]='I0C3'
	set udg_SaveItemType[79]='I0A7'
	set udg_SaveItemType[80]='I0A9'
	set udg_SaveItemType[81]='I0AC'
	set udg_SaveItemType[82]='I0AB'
	set udg_SaveItemType[83]='I09V'
	set udg_SaveItemType[84]='I09P'
	set udg_SaveItemType[85]='I09R'
	set udg_SaveItemType[86]='I09S'
	set udg_SaveItemType[87]='I09T'
	set udg_SaveItemType[88]='I0CB'
	set udg_SaveItemType[89]='I0CA'
	set udg_SaveItemType[90]='I0CD'
	set udg_SaveItemType[91]='I0CE'
	set udg_SaveItemType[92]='I0CF'
	set udg_SaveItemType[93]='I097'
	set udg_SaveItemType[94]='I05H'
	set udg_SaveItemType[95]='I098'
	set udg_SaveItemType[96]='I095'
	set udg_SaveItemType[97]='I08W'
	set udg_SaveItemType[98]='I05G'
	set udg_SaveItemType[99]='I08Z'
	set udg_SaveItemType[100]='I091'
	set udg_SaveItemType[101]='I093'
	set udg_SaveItemType[102]='I05I'
	set udg_SaveItemType[103]='I0D8'
	set udg_SaveItemType[104]='I0DK'
	set udg_SaveItemType[105]='I0DJ'
	set udg_SaveItemType[106]='I0BW'
	set udg_SaveItemType[107]='I0BU'
	set udg_SaveItemType[108]='I09U'
	set udg_SaveItemType[109]='I09W'
	set udg_SaveItemType[110]='I09Q'
	set udg_SaveItemType[111]='I09O'
	set udg_SaveItemType[112]='I09M'
	set udg_SaveItemType[113]='I09K'
	set udg_SaveItemType[114]='I09I'
	set udg_SaveItemType[115]='I09G'
	set udg_SaveItemType[116]='I09E'
	set udg_SaveItemType[117]='I09Y'
	set udg_SaveItemType[118]='I0DX'
	set udg_SaveItemType[119]='I0DL'
	set udg_SaveItemType[120]='I0DY'
	set udg_SaveItemType[121]='I0BT'
	set udg_SaveItemType[122]='I0BR'
	set udg_SaveItemType[123]='I0AL'
	set udg_SaveItemType[124]='I0AN'
	set udg_SaveItemType[125]='I0AA'
	set udg_SaveItemType[126]='I0A8'
	set udg_SaveItemType[127]='I0A6'
	set udg_SaveItemType[128]='I0A3'
	set udg_SaveItemType[129]='I0A1'
	set udg_SaveItemType[130]='I0A4'
	set udg_SaveItemType[131]='I09Z'
	set udg_SaveItemType[132]='I0E0'
	set udg_SaveItemType[133]='I0DZ'
	set udg_SaveItemType[134]='I0E1'
	set udg_SaveItemType[135]='I0BM'
	set udg_SaveItemType[136]='I059'
	set udg_SaveItemType[137]='I0AY'
	set udg_SaveItemType[138]='I0B0'
	set udg_SaveItemType[139]='I0B2'
	set udg_SaveItemType[140]='I0B3'
	set udg_SaveItemType[141]='I0AQ'
	set udg_SaveItemType[142]='I0AO'
	set udg_SaveItemType[143]='I0AT'
	set udg_SaveItemType[144]='I0AR'
	set udg_SaveItemType[145]='I0AW'
	set udg_SaveItemType[146]='I0CG'
	set udg_SaveItemType[147]='I0FH'
	set udg_SaveItemType[148]='I0CI'
	set udg_SaveItemType[149]='I0FI'
	set udg_SaveItemType[150]='I0FZ'
	set udg_SaveItemType[151]='I0AE'
	set udg_SaveItemType[152]='I04F'
	set udg_SaveItemType[153]='I0AF'
	set udg_SaveItemType[154]='I0AD'
	set udg_SaveItemType[155]='I04X'
	set udg_SaveItemType[156]='I056'
	set udg_SaveItemType[157]='I0AG'
	set udg_SaveItemType[158]='I04X'
	set udg_SaveItemType[159]='I056'
	set udg_SaveItemType[160]='I08X'
	set udg_SaveItemType[161]='I08Y'
	set udg_SaveItemType[162]='I090'
	set udg_SaveItemType[163]='I092'
	set udg_SaveItemType[164]='I094'
	set udg_SaveItemType[165]='I096'
	set udg_SaveItemType[166]='I099'
	set udg_SaveItemType[167]='I09A'
	set udg_SaveItemType[168]='I05A'
	set udg_SaveItemType[169]='I05Z'
	set udg_SaveItemType[170]='I0D4'
	set udg_SaveItemType[171]='I06K'
	set udg_SaveItemType[172]='I0EH'
	set udg_SaveItemType[173]='I0EI'
	set udg_SaveItemType[174]='I06L'
	set udg_SaveItemType[175]='I0EJ'
	set udg_SaveItemType[176]='I0EK'
	set udg_SaveItemType[177]='I0AH'
	set udg_SaveItemType[178]='I0AP'
	set udg_SaveItemType[179]='I0AI'
	set udg_SaveItemType[180]='I0BY' // exist soul
	set udg_SaveItemType[181]='I04E'
	set udg_SaveItemType[182]='I062'
	set udg_SaveItemType[183]='I0EL'
	set udg_SaveItemType[184]='I00P'
	set udg_SaveItemType[185]='I0EM'
	set udg_SaveItemType[186]='I0EN'
	set udg_SaveItemType[187]='I00Q'
	set udg_SaveItemType[188]='I06E'
	set udg_SaveItemType[189]='I06F'
	set udg_SaveItemType[190]='I06G'
	set udg_SaveItemType[191]='I06H'
	set udg_SaveItemType[192]='I0BX' //satan's heart
	set udg_SaveItemType[193]='I0OC' 
	set udg_SaveItemType[194]='I0OD' 
	set udg_SaveItemType[195]='I05J' //satan's Ace
	set udg_SaveItemType[196]='I04O'
	set udg_SaveItemType[197]='I07H'
	set udg_SaveItemType[198]='I00R' //rare ace
	set udg_SaveItemType[199]='I00N'
	set udg_SaveItemType[200]='I00O'
	set udg_SaveItemType[201]='I00S' //legendary ace
	set udg_SaveItemType[202]='I07J'
	set udg_SaveItemType[203]='I07N'
	set udg_SaveItemType[204]='I0B5' // legion's plate
	set udg_SaveItemType[205]='I0JF'
	set udg_SaveItemType[206]='I0JG'
	set udg_SaveItemType[207]='I0JH'
	set udg_SaveItemType[208]='I0JI'
	set udg_SaveItemType[209]='I0JJ'
	set udg_SaveItemType[210]='I0JK'
	set udg_SaveItemType[211]='I0JL'
	set udg_SaveItemType[212]='I0JM'
	set udg_SaveItemType[213]='I0B7' //fullplate
	set udg_SaveItemType[214]='I0HV'
	set udg_SaveItemType[215]='I0HW'
	set udg_SaveItemType[216]='I0HX'
	set udg_SaveItemType[217]='I0HY'
	set udg_SaveItemType[218]='I0HZ'
	set udg_SaveItemType[219]='I0I0'
	set udg_SaveItemType[220]='I0I1'
	set udg_SaveItemType[221]='I0I2'
	set udg_SaveItemType[222]='I0B1' //suit
	set udg_SaveItemType[223]='I0IZ'
	set udg_SaveItemType[224]='I0J0'
	set udg_SaveItemType[225]='I0J1'
	set udg_SaveItemType[226]='I0J2'
	set udg_SaveItemType[227]='I0J3'
	set udg_SaveItemType[228]='I0J4'
	set udg_SaveItemType[229]='I0J5'
	set udg_SaveItemType[230]='I0J6'
	set udg_SaveItemType[231]='I0AZ' //robe
	set udg_SaveItemType[232]='I0I3'
	set udg_SaveItemType[233]='I0I4'
	set udg_SaveItemType[234]='I0I5'
	set udg_SaveItemType[235]='I0I6'
	set udg_SaveItemType[236]='I0I7'
	set udg_SaveItemType[237]='I0I8'
	set udg_SaveItemType[238]='I0I9'
	set udg_SaveItemType[239]='I0IA'
	set udg_SaveItemType[240]='I0AS' //claymore
	set udg_SaveItemType[241]='I0D9'
	set udg_SaveItemType[242]='I0DA'
	set udg_SaveItemType[243]='I0HP'
	set udg_SaveItemType[244]='I0HQ'
	set udg_SaveItemType[245]='I0HR'
	set udg_SaveItemType[246]='I0HS'
	set udg_SaveItemType[247]='I0HT'
	set udg_SaveItemType[248]='I0HU'
	set udg_SaveItemType[249]='I04L' //sword
	set udg_SaveItemType[250]='I0J7'
	set udg_SaveItemType[251]='I0J8'
	set udg_SaveItemType[252]='I0J9'
	set udg_SaveItemType[253]='I0JA'
	set udg_SaveItemType[254]='I0JB'
	set udg_SaveItemType[255]='I0JC'
	set udg_SaveItemType[256]='I0JD'
	set udg_SaveItemType[257]='I0JE'
	set udg_SaveItemType[258]='I0AJ' //small blade
	set udg_SaveItemType[259]='I0IJ'
	set udg_SaveItemType[260]='I0IK'
	set udg_SaveItemType[261]='I0IL'
	set udg_SaveItemType[262]='I0IM'
	set udg_SaveItemType[263]='I0IN'
	set udg_SaveItemType[264]='I0IO'
	set udg_SaveItemType[265]='I0IP'
	set udg_SaveItemType[266]='I0IQ'
	set udg_SaveItemType[267]='I0AV' //short bow
	set udg_SaveItemType[268]='I0IB'
	set udg_SaveItemType[269]='I0IC'
	set udg_SaveItemType[270]='I0ID'
	set udg_SaveItemType[271]='I0IE'
	set udg_SaveItemType[272]='I0IF'
	set udg_SaveItemType[273]='I0IG'
	set udg_SaveItemType[274]='I0IH'
	set udg_SaveItemType[275]='I0II'
	set udg_SaveItemType[276]='I0AX' //staff
	set udg_SaveItemType[277]='I0IR'
	set udg_SaveItemType[278]='I0IS'
	set udg_SaveItemType[279]='I0IT'
	set udg_SaveItemType[280]='I0IU'
	set udg_SaveItemType[281]='I0IV'
	set udg_SaveItemType[282]='I0IW'
	set udg_SaveItemType[283]='I0IX'
	set udg_SaveItemType[284]='I0IY'
	set udg_SaveItemType[285]='I0AU' // legion's ring
	set udg_SaveItemType[286]='I018' // Ring of Existence
	set udg_SaveItemType[287]='I0F0'
	set udg_SaveItemType[288]='I0EZ'
	set udg_SaveItemType[289]='I06I'
	set udg_SaveItemType[290]='I0F1'
	set udg_SaveItemType[291]='I0F2'
	set udg_SaveItemType[292]='I06J'
	set udg_SaveItemType[293]='I0G1'
	set udg_SaveItemType[294]='I0G2'
	set udg_SaveItemType[295]='I0BS'
	set udg_SaveItemType[296]='I0BV'
	set udg_SaveItemType[297]='I0BK'
	set udg_SaveItemType[298]='I0BI'
	set udg_SaveItemType[299]='I0BB'
	set udg_SaveItemType[300]='I0BC'
	set udg_SaveItemType[301]='I0BE'
	set udg_SaveItemType[302]='I0B9'
	set udg_SaveItemType[303]='I0BG'
	set udg_SaveItemType[304]='I06M' //sphere
	set udg_SaveItemType[305]='I0LW' //azazoth sphere +1
    set udg_SaveItemType[306]='I0LX' //azazoth sphere +2
	set udg_SaveItemType[307]='I0CH'
	set udg_SaveItemType[308]='I01L'
	set udg_SaveItemType[309]='I01N'
	set udg_SaveItemType[310]='I0D0' // ring of struggle
	set udg_SaveItemType[311]='I04Z' // Chaotic ore
	set udg_SaveItemType[312]='I050' // Chaotic Necklace
	set udg_SaveItemType[313]='I03F' // blood axe
	set udg_SaveItemType[314]='I04S' // blade of blood
	set udg_SaveItemType[315]='I020' // blood dagger
	set udg_SaveItemType[316]='I016' // blood bow
	set udg_SaveItemType[317]='I0AK' // blood wand
	set udg_SaveItemType[318]='I00T' // Lesser ring of struggle
	set udg_SaveItemType[319]='oli2' // Nerubian Orb
	set udg_SaveItemType[320]='I0F4' // Dragoon's Set
	set udg_SaveItemType[321]='I0EX' // Dragoon's Wings
	set udg_SaveItemType[322]='I0FC' // Dwarven Warhammer
	set udg_SaveItemType[323]='I07B' // Dwarven Chainmail
	set udg_SaveItemType[324]='I079' // Dwarven Axe
	set udg_SaveItemType[325]='I04N' // Hooded Hide Hiding Cloak
	set udg_SaveItemType[326]='I074' // Runic White Blade
	set udg_SaveItemType[327]='I0EY' // Runic White Bow
	set udg_SaveItemType[328]='I0F5' // Forgotten Mistic Set
	set udg_SaveItemType[329]='I07F' // Mysterious Coak
	set udg_SaveItemType[330]='I0F3' // Orb of Mist
	set udg_SaveItemType[331]='I03U' // Pendant of Forgotten?
	set udg_SaveItemType[332]='I0FA' // Hellfire Staff
	set udg_SaveItemType[333]='I0FU' // Hellfire Robe
	set udg_SaveItemType[334]='I03Y' // Hellfire Shield
	set udg_SaveItemType[335]='I0F8' // Hydra Scale Armor
	set udg_SaveItemType[336]='I0C0' // Paladin's Treads
	set udg_SaveItemType[337]='I0F9' // Paladin's Holy Book
	set udg_SaveItemType[338]='I0FX' // Paladin's Holy Plate
	set udg_SaveItemType[339]='I03P' // Paladin's Hammer
	set udg_SaveItemType[340]='I01B' // Worm Skin
	set udg_SaveItemType[341]='I076' // Minotaur cloth
	set udg_SaveItemType[342]='I078' // Minotaur plate
	set udg_SaveItemType[343]='I07U' // Minotaur leather
	set udg_SaveItemType[344]='I03T' // Minotaur Axe
	set udg_SaveItemType[345]='I0FW' // Ring of the Minotaur
	set udg_SaveItemType[346]='I029' // Savior Dagger
	set udg_SaveItemType[347]='I00A' // Broken Gods Scepter
	set udg_SaveItemType[348]='I02Z' // Aura of Hate
	set udg_SaveItemType[349]='I031' // Aura of Knowledge
	set udg_SaveItemType[350]='I030' // Aura of Love
	set udg_SaveItemType[351]='I04I' // Aura of Life 
	set udg_SaveItemType[352]='I04J' // Aura of gods 
	set udg_SaveItemType[353]='I0JR' // Godslayer Set
	set udg_SaveItemType[354]='I02O' // Savior's Cloak
	set udg_SaveItemType[355]='I02B' // Savior Sword
	set udg_SaveItemType[356]='I02C' // Savior Armor
	set udg_SaveItemType[357]='I04B' // Jewel of the Horde
	set udg_SaveItemType[358]='I03V' // Medean Curse
	set udg_SaveItemType[359]='I03X' // Book of the Pig Gods
	set udg_SaveItemType[360]='I03Z' // Da's Dingo
	set udg_SaveItemType[361]='I043' // Omega pick
	set udg_SaveItemType[362]='I03E' // Evil Shopkeeper's Necklace
	set udg_SaveItemType[363]='I046' // Iron Golem Fist
	set udg_SaveItemType[364]='I02N' // Ultimate Hydra's Spear
	set udg_SaveItemType[365]='I072' // Hydra Sword
	set udg_SaveItemType[366]='I06Y' // Hydra Dagger
	set udg_SaveItemType[367]='I070' // Hydra Bow
	set udg_SaveItemType[368]='I071' // Hydra Talisman
	set udg_SaveItemType[369]='I048' // Dragonhide Plate
	set udg_SaveItemType[370]='I02U' // Dragonbone Plate
	set udg_SaveItemType[371]='I064' // Dragonhide Swift Armor
	set udg_SaveItemType[372]='I02P' // Dragonhide Cloak
	set udg_SaveItemType[373]='I033' // Dragonbone Greatsword
	set udg_SaveItemType[374]='I0BZ' // Dragonfire Sword
	set udg_SaveItemType[375]='I02S' // Dragonfire Dagger
	set udg_SaveItemType[376]='I032' // Dragonfire Bow
	set udg_SaveItemType[377]='I065' // Dragonfire Orb
	set udg_SaveItemType[378]='sor9'
	set udg_SaveItemType[379]='shcw'
	set udg_SaveItemType[380]='shrs'
	set udg_SaveItemType[381]='sor4'
	set udg_SaveItemType[382]='sor7'
	set udg_SaveItemType[383]='I0HK'
	set udg_SaveItemType[384]='I0HL'
	set udg_SaveItemType[385]='I0HM'
	set udg_SaveItemType[386]='I0HN'
	set udg_SaveItemType[387]='I0HO'
	set udg_SaveItemType[388]='ram1'
	set udg_SaveItemType[389]='srbd'
	set udg_SaveItemType[390]='horl'
	set udg_SaveItemType[391]='ram2'
	set udg_SaveItemType[392]='ram4'
	set udg_SaveItemType[393]='I0HF'
	set udg_SaveItemType[394]='I0HG'
	set udg_SaveItemType[395]='I0HH'
	set udg_SaveItemType[396]='I0HI'
	set udg_SaveItemType[397]='I0HJ'
	set udg_SaveItemType[398]='I0FD'
	set udg_SaveItemType[399]='I08R'
	set udg_SaveItemType[400]='I07Y'
	set udg_SaveItemType[401]='I07W'
	set udg_SaveItemType[402]='I08I'
	set udg_SaveItemType[403]='I08B'
	set udg_SaveItemType[404]='I08F'
	set udg_SaveItemType[405]='I08E'
	set udg_SaveItemType[406]='I0FE'
	set udg_SaveItemType[407]='I0HA'
	set udg_SaveItemType[408]='I0HB'
	set udg_SaveItemType[409]='I0HC'
	set udg_SaveItemType[410]='I0HD'
	set udg_SaveItemType[411]='I0HE'
	set udg_SaveItemType[412]='I0B8'
	set udg_SaveItemType[413]='I0BA'
	set udg_SaveItemType[414]='I0B4'
	set udg_SaveItemType[415]='I0B6'
	set udg_SaveItemType[416]='I0FS'
	set udg_SaveItemType[417]='I01W'
	set udg_SaveItemType[418]='I0FY'
	set udg_SaveItemType[419]='I0FR'
	set udg_SaveItemType[420]='I035'
	set udg_SaveItemType[421]='I0FQ'
	set udg_SaveItemType[422]='I0FO'
	set udg_SaveItemType[423]='I07O'
	set udg_SaveItemType[424]='I0H5'
	set udg_SaveItemType[425]='I0H6'
	set udg_SaveItemType[426]='I0H7'
	set udg_SaveItemType[427]='I0H8'
	set udg_SaveItemType[428]='I0H9'
	set udg_SaveItemType[429]='I034'
	set udg_SaveItemType[430]='I06T'
	set udg_SaveItemType[431]='I0FG'
	set udg_SaveItemType[432]='I06R'
	set udg_SaveItemType[433]='I0FT'
	set udg_SaveItemType[434]='I036' // Chronos stone
	set udg_SaveItemType[435]='I04C' // clubba
	set udg_SaveItemType[436]='I02Q' // Iron golem ore
	set udg_SaveItemType[437]='I02J' // white flames?
	set udg_SaveItemType[438]='I038' //cheese shield
    set udg_SaveItemType[439]='I08K' // Dwarven set
	set udg_SaveItemType[440]='I07S' // King's Crown
	set udg_SaveItemType[441]='I08L' // King's Armor
	set udg_SaveItemType[442]='I09F' // Sea Ward
	set udg_SaveItemType[443]='dthb' // centaur axe
	set udg_SaveItemType[444]='phlt' // centaur blade
	set udg_SaveItemType[445]='engs' // centaur dagger
	set udg_SaveItemType[446]='kygh' // centaur bow
	set udg_SaveItemType[447]='bzbf' // centaur wand
	set udg_SaveItemType[448]='I0JW' // Plate
	set udg_SaveItemType[449]='I0JX'
	set udg_SaveItemType[450]='I0JY'
	set udg_SaveItemType[451]='I0JZ'
	set udg_SaveItemType[452]='I0K0'
	set udg_SaveItemType[453]='I0K1'
	set udg_SaveItemType[454]='I0K2'
	set udg_SaveItemType[455]='I0K3'
	set udg_SaveItemType[456]='I0K4' //Fullplate
	set udg_SaveItemType[457]='I0K5'
	set udg_SaveItemType[458]='I0K6'
	set udg_SaveItemType[459]='I0K7'
	set udg_SaveItemType[460]='I0K8'
	set udg_SaveItemType[461]='I0K9'
	set udg_SaveItemType[462]='I0KA'
	set udg_SaveItemType[463]='I0KB'
	set udg_SaveItemType[464]='I0KC' //Leather
	set udg_SaveItemType[465]='I0KD'
	set udg_SaveItemType[466]='I0KE'
	set udg_SaveItemType[467]='I0KF'
	set udg_SaveItemType[468]='I0KG'
	set udg_SaveItemType[469]='I0KH'
	set udg_SaveItemType[470]='I0KI'
	set udg_SaveItemType[471]='I0KJ'
	set udg_SaveItemType[472]='I0KK' //Robe
	set udg_SaveItemType[473]='I0KL'
	set udg_SaveItemType[474]='I0KM'
	set udg_SaveItemType[475]='I0KN'
	set udg_SaveItemType[476]='I0KO'
	set udg_SaveItemType[477]='I0KP'
	set udg_SaveItemType[478]='I0KQ'
	set udg_SaveItemType[479]='I0KR'
	set udg_SaveItemType[480]='I0KS' //Hammer
	set udg_SaveItemType[481]='I0KT'
	set udg_SaveItemType[482]='I0KU'
	set udg_SaveItemType[483]='I0KV'
	set udg_SaveItemType[484]='I0KW'
	set udg_SaveItemType[485]='I0KX'
	set udg_SaveItemType[486]='I0KY'
	set udg_SaveItemType[487]='I0KZ'
	set udg_SaveItemType[488]='I0L0' //sword
	set udg_SaveItemType[489]='I0L1'
	set udg_SaveItemType[490]='I0L2'
	set udg_SaveItemType[491]='I0L3'
	set udg_SaveItemType[492]='I0L4'
	set udg_SaveItemType[493]='I0L5'
	set udg_SaveItemType[494]='I0L6'
	set udg_SaveItemType[495]='I0L7'
	set udg_SaveItemType[496]='I0L8' //Dagger
	set udg_SaveItemType[497]='I0L9'
	set udg_SaveItemType[498]='I0LA'
	set udg_SaveItemType[499]='I0LB'
	set udg_SaveItemType[500]='I0LC'
	set udg_SaveItemType[501]='I0LD'
	set udg_SaveItemType[502]='I0LE'
	set udg_SaveItemType[503]='I0LF'
	set udg_SaveItemType[504]='I0LG' //Bow
	set udg_SaveItemType[505]='I0LH'
	set udg_SaveItemType[506]='I0LI'
	set udg_SaveItemType[507]='I0LJ'
	set udg_SaveItemType[508]='I0LK'
	set udg_SaveItemType[509]='I0LL'
	set udg_SaveItemType[510]='I0LM'
	set udg_SaveItemType[511]='I0LN'
	set udg_SaveItemType[512]='I0LO' //Staff
	set udg_SaveItemType[513]='I0LP'
	set udg_SaveItemType[514]='I0LQ'
	set udg_SaveItemType[515]='I0LR'
	set udg_SaveItemType[516]='I0LS'
	set udg_SaveItemType[517]='I0LT'
	set udg_SaveItemType[518]='I0LU'
	set udg_SaveItemType[519]='I0LV'
	set udg_SaveItemType[520]='I01T' //god armor
    set udg_SaveItemType[521]='I09L' //serpent boots
	set udg_SaveItemType[522]='I0MA' //flame sigil
	set udg_SaveItemType[523]='I0MB' //unbroken shield
	set udg_SaveItemType[524]='I0MC' //polar shield
	set udg_SaveItemType[525]='I0MD' //polar fang
    set udg_SaveItemType[526]='I0MR' //than boots
    set udg_SaveItemType[527]='I0JT' //than boots rare
    set udg_SaveItemType[528]='I02X' //bryan pick
    set udg_SaveItemType[529]='I02Y' //pinky pick
    set udg_SaveItemType[530]='I00B' //axe of speed
    set udg_SaveItemType[531]='I03O' //sassy brawler
    set udg_SaveItemType[532]='I0N4' //bloody chainmail
    set udg_SaveItemType[533]='I0N5' //bloody tunic
    set udg_SaveItemType[534]='I0N6' //bloody mantle
    set udg_SaveItemType[535]='I0NI' //absolute cape
    set udg_SaveItemType[536]='I0NG' //absolute cuirass
    set udg_SaveItemType[537]='I0NA' //absolute fullplate
    set udg_SaveItemType[538]='I0NH' //absolute gambeson
    set udg_SaveItemType[539]='I0NB' //absolute greatsword
    set udg_SaveItemType[540]='I0NC' //absolute longbow
    set udg_SaveItemType[541]='I0NE' //absolute orb
    set udg_SaveItemType[542]='I0ND' //absolute scimitar
    set udg_SaveItemType[543]='I0NF' //absolute spatha
    set udg_SaveItemType[544]='I0NJ' //drum of war
    set udg_SaveItemType[545]='I021' //bulwark + 1
    set udg_SaveItemType[546]='I03K' //bulwark + 2
    set udg_SaveItemType[547]='I0FB' //arctic treads
	set udg_SaveItemType[548] = 'sora'
	set udg_SaveItemType[549] = 'cnob'
	set udg_SaveItemType[550] = 'ratc'
	set udg_SaveItemType[551] = 'brac'
	set udg_SaveItemType[552] = 'ratf'
	set udg_SaveItemType[553] = 'I0FK'
	set udg_SaveItemType[554] = 'I00F'
	set udg_SaveItemType[555] = 'I01M'
	set udg_SaveItemType[556] = 'I01D'
	set udg_SaveItemType[557] = 'rnsp'
	set udg_SaveItemType[558] = 'gcel'
	set udg_SaveItemType[559] = 'odef'
	set udg_SaveItemType[560] = 'I010'
	set udg_SaveItemType[561] = 'rat6'
	set udg_SaveItemType[562] = 'rhth'
	set udg_SaveItemType[563] = 'I0FM'
	set udg_SaveItemType[564] = 'bgst'
	set udg_SaveItemType[565] = 'rat9'
	set udg_SaveItemType[566] = 'I01U'
	set udg_SaveItemType[567] = 'sor2'
	set udg_SaveItemType[568] = 'I004'
	set udg_SaveItemType[569] = 'I01S'
	set udg_SaveItemType[570] = 'rde1'
	set udg_SaveItemType[571] = 'frgd'
	set udg_SaveItemType[572] = 'hcun'
	set udg_SaveItemType[573] = 'I0FL'
	set udg_SaveItemType[574] = 'ward'
	set udg_SaveItemType[575] = 'rde2'
	set udg_SaveItemType[576] = 'rde3'
	set udg_SaveItemType[577] = 'I00H'
	set udg_SaveItemType[578] = 'I00I'
	set udg_SaveItemType[579] = 'I00G'
	set udg_SaveItemType[580] = 'I00V'
	set udg_SaveItemType[581] = 'crys'
	set udg_SaveItemType[582] = 'gemt'
	set udg_SaveItemType[583] = 'I01A'
	set udg_SaveItemType[584] = 'hval'
	set udg_SaveItemType[585] = 'kpin'
	set udg_SaveItemType[586] = 'ofro'
	set udg_SaveItemType[587] = 'I02F' // prestige token 12/22 -- no longer saves
	set udg_SaveItemType[588] = 'I0N7' //absolute claw
	set udg_SaveItemType[589] = 'I0N8' //absolute fang
	set udg_SaveItemType[590] = 'I0N9' //absolute hide
	set udg_SaveItemType[591] = 'I0NT' //lexium crystal rare
	set udg_SaveItemType[592] = 'I0NP' //lexium crystal rare +1
	set udg_SaveItemType[593] = 'I0NQ' //lexium crystal rare +2
	set udg_SaveItemType[594] = 'I0NR' //lexium crystal legendary
	set udg_SaveItemType[595] = 'I0NS' //lexium crystal legendary +1
	set udg_SaveItemType[596] = 'I019' //lexium crystal legendary +2
	set udg_SaveItemType[597] = 'I0O1' //vigor gem
	set udg_SaveItemType[598] = 'I0O0' //vigor gem +1
	set udg_SaveItemType[599] = 'I0NZ' //vigor gem +2
	set udg_SaveItemType[600] = 'I0NY' //vigor gem rare
	set udg_SaveItemType[601] = 'I0O2' //vigor gem rare +1
	set udg_SaveItemType[602] = 'I0NX' //vigor gem rare +2
	set udg_SaveItemType[603] = 'I0NV' //vigor gem legendary
	set udg_SaveItemType[604] = 'I0NU' //vigor gem legendary +1
	set udg_SaveItemType[605] = 'I0NW' //vigor gem legendary +2
	set udg_SaveItemType[606] = 'I0OB' //torture jewel
	set udg_SaveItemType[607] = 'I0O9' //torture jewel +1
	set udg_SaveItemType[608] = 'I0O8' //torture jewel +2
	set udg_SaveItemType[609] = 'I0OA' //torture jewel rare
	set udg_SaveItemType[610] = 'I0O4' //torture jewel rare +1
	set udg_SaveItemType[611] = 'I0O5' //torture jewel rare +2
	set udg_SaveItemType[612] = 'I0O7' //torture jewel legendary
	set udg_SaveItemType[613] = 'I0O6' //torture jewel legendary +1
	set udg_SaveItemType[614] = 'I0O3' //torture jewel legendary +2
	set udg_SaveItemType[615] = 'I0OF' //demon golem fist
	set udg_SaveItemType[616] = 'I025' //greater mask of death
	set udg_SaveItemType[617] = 'I01X' //sword of revival
	set udg_SaveItemType[618] = 'I03Q' //horse boost
    set udg_SaveItemType[619] = 'I023' //than boots leg
    set udg_SaveItemType[620] = 'I01J' //chaos shield
    set udg_SaveItemType[621] = 'I02R' //chaos shield +1
    set udg_SaveItemType[622] = 'I01C' //chaos shield +2
    set udg_SaveItemType[623] = 'I0BF' //slaughterer hammer rare
    set udg_SaveItemType[624] = 'I0AM' //slaughterer hammer rare +1
    set udg_SaveItemType[625] = 'I0BH' //slaughterer hammer rare +2
    set udg_SaveItemType[626] = 'I0OR' //slaughterer sword rare
    set udg_SaveItemType[627] = 'I0OS' //slaughterer sword rare +1
    set udg_SaveItemType[628] = 'I0OT' //slaughterer sword rare +2
    set udg_SaveItemType[629] = 'I0OM' //slaughterer dagger rare
    set udg_SaveItemType[630] = 'I0ON' //slaughterer dagger rare +1
    set udg_SaveItemType[631] = 'I0OO' //slaughterer dagger rare +2
    set udg_SaveItemType[632] = 'I01R' //slaughterer bow rare
    set udg_SaveItemType[633] = 'I02T' //slaughterer bow rare +1
    set udg_SaveItemType[634] = 'I0OL' //slaughterer bow rare +2
    set udg_SaveItemType[635] = 'I0BD' //slaughterer rod rare
    set udg_SaveItemType[636] = 'I0OS' //slaughterer rod rare +1
    set udg_SaveItemType[637] = 'I0OT' //slaughterer rod rare +2
    set udg_SaveItemType[638] = 'I0NK' //legion ring rare
    set udg_SaveItemType[639] = 'I0NL' //legion ring legendary
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[1], 1)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[2], 2)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[3], 3)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[4], 4)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[5], 5)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[6], 6)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[7], 7)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[8], 8)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[9], 9)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[10], 10)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[11], 11)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[12], 12)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[13], 13)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[14], 14)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[15], 15)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[16], 16)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[17], 17)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[18], 18)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[19], 19)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[20], 20)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[21], 21)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[22], 22)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[23], 23)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[24], 24)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[25], 25)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[26], 26)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[27], 27)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[28], 28)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[29], 29)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[30], 30)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[31], 31)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[32], 32)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[33], 33)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[34], 34)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[35], 35)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[36], 36)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[37], 37)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[38], 38)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[39], 39)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[40], 40)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[41], 41)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[42], 42)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[43], 43)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[44], 44)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[45], 45)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[46], 46)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[47], 47)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[48], 48)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[49], 49)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[50], 50)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[51], 51)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[52], 52)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[53], 53)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[54], 54)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[55], 55)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[56], 56)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[57], 57)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[58], 58)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[59], 59)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[60], 60)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[61], 61)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[62], 62)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[63], 63)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[64], 64)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[65], 65)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[66], 66)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[67], 67)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[68], 68)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[69], 69)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[70], 70)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[71], 71)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[72], 72)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[73], 73)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[74], 74)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[75], 75)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[76], 76)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[77], 77)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[78], 78)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[79], 79)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[80], 80)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[81], 81)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[82], 82)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[83], 83)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[84], 84)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[85], 85)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[86], 86)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[87], 87)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[88], 88)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[89], 89)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[90], 90)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[91], 91)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[92], 92)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[93], 93)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[94], 94)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[95], 95)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[96], 96)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[97], 97)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[98], 98)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[99], 99)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[100], 100)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[101], 101)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[102], 102)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[103], 103)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[104], 104)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[105], 105)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[106], 106)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[107], 107)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[108], 108)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[109], 109)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[110], 110)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[111], 111)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[112], 112)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[113], 113)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[114], 114)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[115], 115)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[116], 116)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[117], 117)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[118], 118)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[119], 119)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[120], 120)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[121], 121)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[122], 122)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[123], 123)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[124], 124)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[125], 125)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[126], 126)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[127], 127)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[128], 128)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[129], 129)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[130], 130)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[131], 131)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[132], 132)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[133], 133)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[134], 134)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[135], 135)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[136], 136)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[137], 137)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[138], 138)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[139], 139)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[140], 140)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[141], 141)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[142], 142)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[143], 143)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[144], 144)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[145], 145)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[146], 146)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[147], 147)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[148], 148)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[149], 149)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[150], 150)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[151], 151)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[152], 152)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[153], 153)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[154], 154)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[155], 155)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[156], 156)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[157], 157)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[158], 158)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[159], 159)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[160], 160)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[161], 161)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[162], 162)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[163], 163)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[164], 164)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[165], 165)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[166], 166)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[167], 167)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[168], 168)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[169], 169)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[170], 170)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[171], 171)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[172], 172)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[173], 173)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[174], 174)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[175], 175)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[176], 176)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[177], 177)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[178], 178)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[179], 179)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[180], 180)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[181], 181)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[182], 182)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[183], 183)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[184], 184)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[185], 185)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[186], 186)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[187], 187)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[188], 188)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[189], 189)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[190], 190)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[191], 191)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[192], 192)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[193], 193)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[194], 194)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[195], 195)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[196], 196)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[197], 197)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[198], 198)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[199], 199)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[200], 200)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[201], 201)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[202], 202)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[203], 203)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[204], 204)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[205], 205)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[206], 206)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[207], 207)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[208], 208)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[209], 209)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[210], 210)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[211], 211)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[212], 212)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[213], 213)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[214], 214)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[215], 215)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[216], 216)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[217], 217)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[218], 218)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[219], 219)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[220], 220)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[221], 221)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[222], 222)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[223], 223)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[224], 224)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[225], 225)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[226], 226)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[227], 227)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[228], 228)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[229], 229)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[230], 230)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[231], 231)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[232], 232)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[233], 233)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[234], 234)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[235], 235)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[236], 236)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[237], 237)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[238], 238)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[239], 239)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[240], 240)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[241], 241)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[242], 242)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[243], 243)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[244], 244)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[245], 245)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[246], 246)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[247], 247)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[248], 248)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[249], 249)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[250], 250)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[251], 251)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[252], 252)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[253], 253)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[254], 254)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[255], 255)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[256], 256)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[257], 257)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[258], 258)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[259], 259)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[260], 260)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[261], 261)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[262], 262)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[263], 263)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[264], 264)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[265], 265)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[266], 266)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[267], 267)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[268], 268)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[269], 269)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[270], 270)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[271], 271)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[272], 272)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[273], 273)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[274], 274)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[275], 275)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[276], 276)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[277], 277)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[278], 278)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[279], 279)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[280], 280)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[281], 281)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[282], 282)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[283], 283)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[284], 284)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[285], 285)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[286], 286)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[287], 287)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[288], 288)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[289], 289)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[290], 290)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[291], 291)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[292], 292)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[293], 293)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[294], 294)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[295], 295)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[296], 296)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[297], 297)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[298], 298)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[299], 299)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[300], 300)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[301], 301)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[302], 302)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[303], 303)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[304], 304)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[305], 305)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[306], 306)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[307], 307)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[308], 308)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[309], 309)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[310], 310)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[311], 311)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[312], 312)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[313], 313)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[314], 314)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[315], 315)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[316], 316)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[317], 317)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[318], 318)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[319], 319)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[320], 320)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[321], 321)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[322], 322)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[323], 323)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[324], 324)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[325], 325)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[326], 326)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[327], 327)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[328], 328)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[329], 329)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[330], 330)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[331], 331)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[332], 332)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[333], 333)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[334], 334)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[335], 335)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[336], 336)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[337], 337)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[338], 338)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[339], 339)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[340], 340)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[341], 341)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[342], 342)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[343], 343)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[344], 344)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[345], 345)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[346], 346)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[347], 347)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[348], 348)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[349], 349)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[350], 350)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[351], 351)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[352], 352)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[353], 353)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[354], 354)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[355], 355)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[356], 356)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[357], 357)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[358], 358)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[359], 359)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[360], 360)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[361], 361)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[362], 362)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[363], 363)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[364], 364)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[365], 365)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[366], 366)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[367], 367)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[368], 368)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[369], 369)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[370], 370)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[371], 371)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[372], 372)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[373], 373)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[374], 374)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[375], 375)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[376], 376)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[377], 377)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[378], 378)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[379], 379)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[380], 380)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[381], 381)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[382], 382)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[383], 383)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[384], 384)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[385], 385)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[386], 386)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[387], 387)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[388], 388)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[389], 389)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[390], 390)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[391], 391)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[392], 392)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[393], 393)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[394], 394)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[395], 395)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[396], 396)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[397], 397)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[398], 398)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[399], 399)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[400], 400)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[401], 401)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[402], 402)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[403], 403)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[404], 404)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[405], 405)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[406], 406)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[407], 407)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[408], 408)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[409], 409)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[410], 410)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[411], 411)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[412], 412)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[413], 413)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[414], 414)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[415], 415)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[416], 416)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[417], 417)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[418], 418)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[419], 419)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[420], 420)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[421], 421)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[422], 422)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[423], 423)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[424], 424)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[425], 425)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[426], 426)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[427], 427)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[428], 428)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[429], 429)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[430], 430)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[431], 431)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[432], 432)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[433], 433)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[434], 434)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[435], 435)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[436], 436)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[437], 437)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[438], 438)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[439], 439)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[440], 440)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[441], 441)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[442], 442)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[443], 443)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[444], 444)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[445], 445)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[446], 446)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[447], 447)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[448], 448)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[449], 449)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[450], 450)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[451], 451)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[452], 452)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[453], 453)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[454], 454)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[455], 455)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[456], 456)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[457], 457)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[458], 458)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[459], 459)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[460], 460)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[461], 461)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[462], 462)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[463], 463)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[464], 464)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[465], 465)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[466], 466)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[467], 467)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[468], 468)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[469], 469)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[470], 470)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[471], 471)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[472], 472)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[473], 473)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[474], 474)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[475], 475)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[476], 476)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[477], 477)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[478], 478)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[479], 479)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[480], 480)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[481], 481)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[482], 482)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[483], 483)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[484], 484)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[485], 485)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[486], 486)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[487], 487)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[488], 488)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[489], 489)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[490], 490)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[491], 491)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[492], 492)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[493], 493)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[494], 494)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[495], 495)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[496], 496)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[497], 497)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[498], 498)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[499], 499)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[500], 500)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[501], 501)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[502], 502)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[503], 503)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[504], 504)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[505], 505)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[506], 506)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[507], 507)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[508], 508)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[509], 509)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[510], 510)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[511], 511)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[512], 512)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[513], 513)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[514], 514)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[515], 515)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[516], 516)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[517], 517)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[518], 518)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[519], 519)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[520], 520)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[521], 521)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[522], 522)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[523], 523)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[524], 524)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[525], 525)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[526], 526)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[527], 527)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[528], 528)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[529], 529)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[530], 530)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[531], 531)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[532], 532)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[533], 533)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[534], 534)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[535], 535)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[536], 536)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[537], 537)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[538], 538)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[539], 539)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[540], 540)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[541], 541)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[542], 542)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[543], 543)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[544], 544)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[545], 545)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[546], 546)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[547], 547)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[548], 548)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[549], 549)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[550], 550)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[551], 551)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[552], 552)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[553], 553)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[554], 554)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[555], 555)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[556], 556)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[557], 557)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[558], 558)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[559], 559)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[560], 560)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[561], 561)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[562], 562)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[563], 563)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[564], 564)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[565], 565)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[566], 566)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[567], 567)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[568], 568)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[569], 569)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[570], 570)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[571], 571)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[572], 572)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[573], 573)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[574], 574)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[575], 575)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[576], 576)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[577], 577)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[578], 578)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[579], 579)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[580], 580)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[581], 581)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[582], 582)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[583], 583)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[584], 584)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[585], 585)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[586], 586)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[587], 587)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[588], 588)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[589], 589)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[590], 590)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[591], 591)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[592], 592)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[593], 593)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[594], 594)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[595], 595)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[596], 596)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[597], 597)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[598], 598)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[599], 599)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[600], 600)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[601], 601)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[602], 602)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[603], 603)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[604], 604)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[605], 605)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[606], 606)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[607], 607)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[608], 608)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[609], 609)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[610], 610)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[611], 611)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[612], 612)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[613], 613)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[614], 614)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[615], 615)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[616], 616)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[617], 617)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[618], 618)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[619], 619)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[620], 620)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[621], 621)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[622], 622)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[623], 623)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[624], 624)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[625], 625)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[626], 626)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[627], 627)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[628], 628)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[629], 629)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[630], 630)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[631], 631)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[632], 632)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[633], 633)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[634], 634)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[635], 635)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[636], 636)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[637], 637)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[638], 638)
	call SaveInteger(SAVE_TABLE, KEY_ITEMS, udg_SaveItemType[639], 639)
    set udg_SaveItemTypeMax = 639 
endfunction

endlibrary
