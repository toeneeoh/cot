library Units initializer SpawnSetup requires Functions

globals 
    unit array Boss
    location array BossLoc
    real array BossFacing
    string array BossName
    integer array BossID
    integer array BossItemType
    integer array BossLevel
    integer array BossNearbyPlayers
    timer array HeroGraveTimer
    constant integer REGION_GAP = 25
    trigger ShopkeeperTrackable = CreateTrigger()
    //group Sins = CreateGroup()
    Shop evilshop
endglobals

function ShopSetup takes nothing returns nothing
    local integer sword
    local integer heavy
    local integer dagger
    local integer bow
    local integer staff
    local integer plate
    local integer fullplate
    local integer leather
    local integer cloth
    local integer Shield
    local integer misc
    local integer sets
    local integer id = 'n02C' //town smith
    local integer id2 = 'n09D' //reclusive blacksmith
    local integer id3 = 'n01F' //evil shopkeeper

    //TODO setup prices beforehand
    set ItemPrices['I02B'][GOLD] = 20000
    set ItemPrices['I02C'][GOLD] = 20000
    set ItemPrices['I0EY'][GOLD] = 20000
    set ItemPrices['I074'][GOLD] = 20000
    set ItemPrices['I03U'][GOLD] = 20000
    set ItemPrices['I07F'][GOLD] = 20000
    set ItemPrices['I03P'][GOLD] = 20000
    set ItemPrices['I0F9'][GOLD] = 20000
    set ItemPrices['I079'][GOLD] = 20000
    set ItemPrices['I0FC'][GOLD] = 20000
    set ItemPrices['I00A'][GOLD] = 80000
    set ItemPrices['I0JR'][GOLD] = 100000
    set ItemPrices['I0JR'][LUMBER] = 100000
    set ItemPrices['I08K'][GOLD] = 100000
    set ItemPrices['I08K'][LUMBER] = 100000
    set ItemPrices['I0F4'][GOLD] = 100000
    set ItemPrices['I0F4'][LUMBER] = 100000
    set ItemPrices['I0F5'][GOLD] = 100000
    set ItemPrices['I0F5'][LUMBER] = 100000
    set ItemPrices['I012'][GOLD] = 150000
    set ItemPrices['I012'][LUMBER] = 150000
    set ItemPrices['I04J'][GOLD] = 400000
    set ItemPrices['I04J'][LUMBER] = 200000

    call CreateShop(id, 1000., 0.5)
    call CreateShop(id2, 1000., 0.5)
    set evilshop = CreateShop(id3, 1000., 0.5)

    set sword = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNThoriumMelee.blp", "Sword") 
    set heavy = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNImprovedStrengthOfTheMoon.tga", "Heavy") 
    set dagger = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNDaggerOfEscape.blp", "Dagger") 
    set bow = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNScoutsBow.blp", "Bow") 
    set staff = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNWitchDoctorAdept.blp", "Staff") 
    set plate = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNAdvancedMoonArmor.blp", "Plate") 
    set fullplate = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNArmorGolem.blp", "Fullplate") 
    set leather = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp", "Leather") 
    set cloth = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNMantleOfIntelligence.blp", "Cloth") 
    set Shield = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpTwo.blp", "Shield") 
    set misc = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Miscellaneous") 
    set sets = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNManaShield.blp", "Sets") 
    //reclusive blacksmith
    call ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNThoriumMelee.blp", "Sword") 
    call ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNImprovedStrengthOfTheMoon.tga", "Heavy") 
    call ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNDaggerOfEscape.blp", "Dagger") 
    call ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNScoutsBow.blp", "Bow") 
    call ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNWitchDoctorAdept.blp", "Staff") 
    call ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNAdvancedMoonArmor.blp", "Plate") 
    call ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNArmorGolem.blp", "Fullplate") 
    call ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp", "Leather") 
    call ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNMantleOfIntelligence.blp", "Cloth") 
    call ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpTwo.blp", "Shield") 
    call ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Miscellaneous")
    //evil shopkeeper
    call ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNThoriumMelee.blp", "Sword") 
    call ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNImprovedStrengthOfTheMoon.tga", "Heavy") 
    call ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNDaggerOfEscape.blp", "Dagger") 
    call ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNScoutsBow.blp", "Bow") 
    call ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNWitchDoctorAdept.blp", "Staff") 
    call ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNAdvancedMoonArmor.blp", "Plate") 
    call ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNArmorGolem.blp", "Fullplate") 
    call ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp", "Leather") 
    call ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNMantleOfIntelligence.blp", "Cloth") 
    call ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpTwo.blp", "Shield") 
    call ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Miscellaneous")

    //ursa components
    call ShopAddItem(id, 'I06T', sword)
    call ShopAddItem(id, 'I034', heavy)
    call ShopAddItem(id, 'I0FG', dagger)
    call ShopAddItem(id, 'I06R', bow)
    call ShopAddItem(id, 'I0FT', staff)
    call ShopAddItem(id, 'I035', plate)
    call ShopAddItem(id, 'I0FQ', fullplate)
    call ShopAddItem(id, 'I0FO', leather)
    call ShopAddItem(id, 'I07O', cloth)

    //ursa sets
    //sword
    set ItemPrices['I0H5'][GOLD] = 2000
    call ShopAddItem(id, 'I0H5', sets + sword + plate)
    call ItemAddComponents('I0H5', "I06T I06T I06T I035 I035 I034")
    //heavy
    set ItemPrices['I0H6'][GOLD] = 2000
    call ShopAddItem(id, 'I0H6', sets + heavy + fullplate)
    call ItemAddComponents('I0H6', "I0FQ I0FQ I0FQ I034 I034 I035")
    //dagger
    set ItemPrices['I0H7'][GOLD] = 2000
    call ShopAddItem(id, 'I0H7', sets + dagger + leather)
    call ItemAddComponents('I0H7', "I0FG I0FG I0FG I0FO I0FO I0FO")
    //bow
    set ItemPrices['I0H8'][GOLD] = 2000
    call ShopAddItem(id, 'I0H8', sets + bow + leather)
    call ItemAddComponents('I0H8', "I06R I06R I06R I0FO I0FO I0FO")
    //staff
    set ItemPrices['I0H9'][GOLD] = 2000
    call ShopAddItem(id, 'I0H9', sets + staff + cloth)
    call ItemAddComponents('I0H9', "I0FT I0FT I0FT I07O I07O I07O")

    //ogre components
    call ShopAddItem(id, 'I08B', sword)
    call ShopAddItem(id, 'I08R', heavy)
    call ShopAddItem(id, 'I08F', dagger)
    call ShopAddItem(id, 'I08E', bow)
    call ShopAddItem(id, 'I0FE', staff)
    call ShopAddItem(id, 'I0FD', plate)
    call ShopAddItem(id, 'I08I', fullplate)
    call ShopAddItem(id, 'I07Y', leather)
    call ShopAddItem(id, 'I07W', cloth)

    //ogre sets
    //sword
    set ItemPrices['I0HA'][GOLD] = 8000
    call ShopAddItem(id, 'I0HA', sets + sword + plate)
    call ItemAddComponents('I0HA', "I08B I08B I08B I0FD I0FD I08I")
	//heavy
    set ItemPrices['I0HB'][GOLD] = 8000
    call ShopAddItem(id, 'I0HB', sets + heavy + fullplate)
    call ItemAddComponents('I0HB', "I08R I08R I08R I08I I08I I0FD")
	//dagger
    set ItemPrices['I0HC'][GOLD] = 8000
    call ShopAddItem(id, 'I0HC', sets + dagger + leather)
    call ItemAddComponents('I0HC', "I08F I08F I08F I07Y I07Y I07Y")
	//bow
    set ItemPrices['I0HD'][GOLD] = 8000
    call ShopAddItem(id, 'I0HD', sets + bow + leather)
    call ItemAddComponents('I0HD', "I08E I08E I08E I07Y I07Y I07Y")
	//staff
    set ItemPrices['I0HE'][GOLD] = 8000
    call ShopAddItem(id, 'I0HE', sets + staff + cloth)
    call ItemAddComponents('I0HE', "I0FE I0FE I0FE I07W I07W I07W")

    //unbroken components
    call ShopAddItem(id, 'I02E', sword)
    call ShopAddItem(id, 'I023', heavy)
    call ShopAddItem(id, 'I011', dagger)
    call ShopAddItem(id, 'I00S', bow)
    call ShopAddItem(id, 'I00Z', staff)
    call ShopAddItem(id, 'I01W', plate)
    call ShopAddItem(id, 'I0FS', fullplate)
    call ShopAddItem(id, 'I0FY', leather)
    call ShopAddItem(id, 'I0FR', cloth)

    //unbroken sets
    //sword
    set ItemPrices['I0HF'][GOLD] = 32000
    call ShopAddItem(id, 'I0HF', sets + sword + plate)
    call ItemAddComponents('I0HF', "I02E I02E I02E I01W I01W I023")
    //heavy
    set ItemPrices['I0HG'][GOLD] = 32000
    call ShopAddItem(id, 'I0HG', sets + heavy + fullplate)
    call ItemAddComponents('I0HG', "I0FS I0FS I0FS I023 I023 I01W")
    //dagger
    set ItemPrices['I0HH'][GOLD] = 32000
    call ShopAddItem(id, 'I0HH', sets + dagger + leather)
    call ItemAddComponents('I0HH', "I011 I011 I011 I0FY I0FY I0FY")
	//bow
    set ItemPrices['I0HI'][GOLD] = 32000
    call ShopAddItem(id, 'I0HI', sets + bow + leather)
    call ItemAddComponents('I0HI', "I00S I00S I00S I0FY I0FY I0FY")
	//staff
    set ItemPrices['I0HJ'][GOLD] = 32000
    call ShopAddItem(id, 'I0HJ', sets + staff + cloth)
    call ItemAddComponents('I0HJ', "I00Z I00Z I00Z I0FR I0FR I0FR")

    //magnataur components
    call ShopAddItem(id, 'I06J', sword)
    call ShopAddItem(id, 'I06I', heavy)
    call ShopAddItem(id, 'I06L', dagger)
    call ShopAddItem(id, 'I06K', bow)
    call ShopAddItem(id, 'I07H', staff)
    call ShopAddItem(id, 'I01Q', plate)
    call ShopAddItem(id, 'I01N', fullplate)
    call ShopAddItem(id, 'I019', leather)
    call ShopAddItem(id, 'I015', cloth)

    //magnataur sets
    //sword
    set ItemPrices['I0HK'][GOLD] = 100000
    call ShopAddItem(id, 'I0HK', sets + sword + plate)
    call ItemAddComponents('I0HK', "I06J I06J I06J I01Q I01Q I06I")
    //heavy
    set ItemPrices['I0HL'][GOLD] = 100000
    call ShopAddItem(id, 'I0HL', sets + heavy + fullplate)
    call ItemAddComponents('I0HL', "I01N I01N I01N I06I I06I I01Q")
    //dagger
    set ItemPrices['I0HM'][GOLD] = 100000
    call ShopAddItem(id, 'I0HM', sets + dagger + leather)
    call ItemAddComponents('I0HM', "I06L I06L I06L I019 I019 I019")
	//bow
    set ItemPrices['I0HN'][GOLD] = 100000
    call ShopAddItem(id, 'I0HN', sets + bow + leather)
    call ItemAddComponents('I0HN', "I06K I06K I06K I019 I019 I019")
	//staff
    set ItemPrices['I0HO'][GOLD] = 100000
    call ShopAddItem(id, 'I0HO', sets + staff + cloth)
    call ItemAddComponents('I0HO', "I07H I07H I07H I015 I015 I015")

    //devourer components
    call ShopAddItem(id, 'I009', sword)
    call ShopAddItem(id, 'I006', heavy)
    call ShopAddItem(id, 'I00W', dagger)
    call ShopAddItem(id, 'I02W', bow)
    call ShopAddItem(id, 'I02V', staff)
    call ShopAddItem(id, 'I013', plate)
    call ShopAddItem(id, 'I017', fullplate)
    call ShopAddItem(id, 'I01P', leather)
    call ShopAddItem(id, 'I02I', cloth)

    //devourer sets
    //sword
    set ItemPrices['I04R'][GOLD] = 200000
    call ShopAddItem(id, 'I04R', sets + sword + plate)
    call ItemAddComponents('I04R', "I009 I009 I009 I013 I013 I017")
    //heavy
    set ItemPrices['I04K'][GOLD] = 200000
    call ShopAddItem(id, 'I04K', sets + heavy + fullplate)
    call ItemAddComponents('I04K', "I006 I006 I006 I017 I017 I013")
    //dagger
    set ItemPrices['I047'][GOLD] = 200000
    call ShopAddItem(id, 'I047', sets + dagger + leather)
    call ItemAddComponents('I047', "I00W I00W I00W I01P I01P I01P")
	//bow
    set ItemPrices['I02J'][GOLD] = 200000
    call ShopAddItem(id, 'I02J', sets + bow + leather)
    call ItemAddComponents('I02J', "I02W I02W I02W I01P I01P I01P")
	//staff
    set ItemPrices['I04P'][GOLD] = 200000
    call ShopAddItem(id, 'I04P', sets + staff + cloth)
    call ItemAddComponents('I04P', "I02V I02V I02V I02I I02I I02I")

    //shopkeeper components
    call ShopAddItem(id3, 'I02B', sword)
    call ShopAddItem(id3, 'I02C', plate)
    call ShopAddItem(id3, 'I0EY', bow)
    call ShopAddItem(id3, 'I074', dagger)
    call ShopAddItem(id3, 'I03U', staff)
    call ShopAddItem(id3, 'I07F', cloth)
    call ShopAddItem(id3, 'I03P', heavy)
    call ShopAddItem(id3, 'I0F9', misc)
    call ShopAddItem(id3, 'I079', heavy)
    call ShopAddItem(id3, 'I0FC', heavy)
    call ShopAddItem(id3, 'I00A', misc)

    //godslayer set
    call ShopAddItem(id, 'I0JR', sets + sword + plate)
    call ItemAddComponents('I0JR', "I02B I02C I02O")

    //dwarven set
    call ShopAddItem(id, 'I08K', sets + heavy + fullplate)
    call ItemAddComponents('I08K', "I079 I0FC I07B")

    //dragoon set
    call ShopAddItem(id, 'I0F4', sets + leather)
    call ItemAddComponents('I0F4', "I0EY I074 I04N I0EX")

    //forgotten mystic set
    call ShopAddItem(id, 'I0F5', sets + staff + cloth)
    call ItemAddComponents('I0F5', "I03U I07F I0F3")

    //paladin set
    call ShopAddItem(id, 'I012', sets + Shield)
    call ItemAddComponents('I012', "I03P I0FX I0C0 I0F9")

    //aura of gods
    call ShopAddItem(id, 'I04J', sets + misc)
    call ItemAddComponents('I04J', "I00A I030 I04I I031 I02Z")

    //demon components
    call ShopAddItem(id, 'I06S', sword)
    call ShopAddItem(id, 'I04T', heavy)
    call ShopAddItem(id, 'I06U', dagger)
    call ShopAddItem(id, 'I06O', bow)
    call ShopAddItem(id, 'I06Q', staff)
    call ShopAddItem(id, 'I073', plate)
    call ShopAddItem(id, 'I075', fullplate)
    call ShopAddItem(id, 'I06Z', leather)
    call ShopAddItem(id, 'I06W', cloth)

    //demon sets
    //sword
    set ItemPrices['I0CK'][GOLD] = 250000
    set ItemPrices['I0CK'][LUMBER] = 125000
    call ShopAddItem(id, 'I0CK', sets + sword + plate)
    call ItemAddComponents('I0CK', "I06S I06S I06S I073 I073 I04T")
    //heavy
    set ItemPrices['I0BN'][GOLD] = 250000
    set ItemPrices['I0BN'][LUMBER] = 125000
    call ShopAddItem(id, 'I0BN', sets + heavy + fullplate)
    call ItemAddComponents('I0BN', "I075 I075 I075 I04T I04T I073")
    //dagger
    set ItemPrices['I0BO'][GOLD] = 250000
    set ItemPrices['I0BO'][LUMBER] = 125000
    call ShopAddItem(id, 'I0BO', sets + dagger + leather)
    call ItemAddComponents('I0BO', "I06U I06U I06U I06Z I06Z I06Z")
	//bow
    set ItemPrices['I0CU'][GOLD] = 250000
    set ItemPrices['I0CU'][LUMBER] = 125000
    call ShopAddItem(id, 'I0CU', sets + bow + leather)
    call ItemAddComponents('I0CU', "I06O I06O I06O I06Z I06Z I06Z")
	//staff
    set ItemPrices['I0CT'][GOLD] = 250000
    set ItemPrices['I0CT'][LUMBER] = 125000
    call ShopAddItem(id, 'I0CT', sets + staff + cloth)
    call ItemAddComponents('I0CT', "I06Q I06Q I06Q I06W I06W I06W")

    //horror components
    call ShopAddItem(id, 'I07M', sword)
    call ShopAddItem(id, 'I07I', heavy)
    call ShopAddItem(id, 'I07L', dagger)
    call ShopAddItem(id, 'I07P', bow)
    call ShopAddItem(id, 'I077', staff)
    call ShopAddItem(id, 'I07E', plate)
    call ShopAddItem(id, 'I07A', fullplate)
    call ShopAddItem(id, 'I07G', leather)
    call ShopAddItem(id, 'I07C', cloth)
    call ShopAddItem(id, 'I07K', misc)
    call ShopAddItem(id, 'I05D', Shield)

    //horror sets
    //sword
    set ItemPrices['I0CV'][GOLD] = 500000
    set ItemPrices['I0CV'][LUMBER] = 250000
    call ShopAddItem(id, 'I0CV', sets + sword + plate)
    call ItemAddComponents('I0CV', "I07M I07M I07M I07E I07E I07A I07A")
    //heavy
    set ItemPrices['I0C2'][GOLD] = 500000
    set ItemPrices['I0C2'][LUMBER] = 250000
    call ShopAddItem(id, 'I0C2', sets + heavy + fullplate)
    call ItemAddComponents('I0C2', "I07I I07I I07I I07A I07A I07E I05D")
    //dagger
    set ItemPrices['I0C1'][GOLD] = 500000
    set ItemPrices['I0C1'][LUMBER] = 250000
    call ShopAddItem(id, 'I0C1', sets + dagger + leather)
    call ItemAddComponents('I0C1', "I07L I07L I07L I07G I07G I07G I07K")
	//bow
    set ItemPrices['I0CW'][GOLD] = 500000
    set ItemPrices['I0CW'][LUMBER] = 250000
    call ShopAddItem(id, 'I0CW', sets + bow + leather)
    call ItemAddComponents('I0CW', "I07P I07P I07P I07G I07G I07G I07K")
	//staff
    set ItemPrices['I0CX'][GOLD] = 500000
    set ItemPrices['I0CX'][LUMBER] = 250000
    call ShopAddItem(id, 'I0CX', sets + staff + cloth)
    call ItemAddComponents('I0CX', "I077 I077 I077 I07C I07C I07C I07K")

    //despair components
    call ShopAddItem(id, 'I07V', sword)
    call ShopAddItem(id, 'I07X', heavy)
    call ShopAddItem(id, 'I07Z', dagger)
    call ShopAddItem(id, 'I07R', bow)
    call ShopAddItem(id, 'I07T', staff)
    call ShopAddItem(id, 'I087', plate)
    call ShopAddItem(id, 'I089', fullplate)
    call ShopAddItem(id, 'I083', leather)
    call ShopAddItem(id, 'I081', cloth)

    //despair sets
    //sword
    set ItemPrices['I0CY'][GOLD] = 500000
    set ItemPrices['I0CY'][PLATINUM] = 1
    set ItemPrices['I0CY'][LUMBER] = 750000
    set ItemPrices['I0CY'][CRYSTAL] = 1
    call ShopAddItem(id, 'I0CY', sets + sword + plate)
    call ItemAddComponents('I0CY', "I07V I07V I07V I087 I087 I07X")
    //heavy
    set ItemPrices['I0BQ'][GOLD] = 500000
    set ItemPrices['I0BQ'][PLATINUM] = 1
    set ItemPrices['I0BQ'][LUMBER] = 750000
    set ItemPrices['I0BQ'][CRYSTAL] = 1
    call ShopAddItem(id, 'I0BQ', sets + heavy + fullplate)
    call ItemAddComponents('I0BQ', "I089 I089 I089 I07X I07X I087")
    //dagger
    set ItemPrices['I0BP'][GOLD] = 500000
    set ItemPrices['I0BP'][PLATINUM] = 1
    set ItemPrices['I0BP'][LUMBER] = 750000
    set ItemPrices['I0BP'][CRYSTAL] = 1
    call ShopAddItem(id, 'I0BP', sets + dagger + leather)
    call ItemAddComponents('I0BP', "I07Z I07Z I07Z I083 I083 I083")
	//bow
    set ItemPrices['I0CZ'][GOLD] = 500000
    set ItemPrices['I0CZ'][PLATINUM] = 1
    set ItemPrices['I0CZ'][LUMBER] = 750000
    set ItemPrices['I0CZ'][CRYSTAL] = 1
    call ShopAddItem(id, 'I0CZ', sets + bow + leather)
    call ItemAddComponents('I0CZ', "I07R I07R I07R I083 I083 I083")
	//staff
    set ItemPrices['I0D3'][GOLD] = 500000
    set ItemPrices['I0D3'][PLATINUM] = 1
    set ItemPrices['I0D3'][LUMBER] = 750000
    set ItemPrices['I0D3'][CRYSTAL] = 1
    call ShopAddItem(id, 'I0D3', sets + staff + cloth)
    call ItemAddComponents('I0D3', "I07T I07T I07T I081 I081 I081")

    //abyssal components
    call ShopAddItem(id, 'I06A', sword)
    call ShopAddItem(id, 'I0A0', heavy)
    call ShopAddItem(id, 'I06B', dagger)
    call ShopAddItem(id, 'I06C', bow)
    call ShopAddItem(id, 'I09N', staff)
    call ShopAddItem(id, 'I09X', plate)
    call ShopAddItem(id, 'I06D', fullplate)
    call ShopAddItem(id, 'I0A2', leather)
    call ShopAddItem(id, 'I0A5', cloth)

    //abyssal sets
    //sword
    set ItemPrices['I0C9'][PLATINUM] = 3
    set ItemPrices['I0C9'][ARCADITE] = 1
    set ItemPrices['I0C9'][LUMBER] = 500000
    set ItemPrices['I0C9'][CRYSTAL] = 2
    call ShopAddItem(id, 'I0C9', sets + sword + plate)
    call ItemAddComponents('I0C9', "I06A I06A I06A I09X I09X I06D")
    //heavy
    set ItemPrices['I0C8'][PLATINUM] = 3
    set ItemPrices['I0C8'][ARCADITE] = 1
    set ItemPrices['I0C8'][LUMBER] = 500000
    set ItemPrices['I0C8'][CRYSTAL] = 2
    call ShopAddItem(id, 'I0C8', sets + heavy + fullplate)
    call ItemAddComponents('I0C8', "I0A0 I0A0 I0A0 I06D I06D I09X")
    //dagger
    set ItemPrices['I0C7'][PLATINUM] = 3
    set ItemPrices['I0C7'][ARCADITE] = 1
    set ItemPrices['I0C7'][LUMBER] = 500000
    set ItemPrices['I0C7'][CRYSTAL] = 2
    call ShopAddItem(id, 'I0C7', sets + dagger + leather)
    call ItemAddComponents('I0C7', "I06B I06B I06B I0A2 I0A2 I0A2")
	//bow
    set ItemPrices['I0C6'][PLATINUM] = 3
    set ItemPrices['I0C6'][ARCADITE] = 1
    set ItemPrices['I0C6'][LUMBER] = 500000
    set ItemPrices['I0C6'][CRYSTAL] = 2
    call ShopAddItem(id, 'I0C6', sets + bow + leather)
    call ItemAddComponents('I0C6', "I06C I06C I06C I0A2 I0A2 I0A2")
	//staff
    set ItemPrices['I0C5'][PLATINUM] = 3
    set ItemPrices['I0C5'][ARCADITE] = 1
    set ItemPrices['I0C5'][LUMBER] = 500000
    set ItemPrices['I0C5'][CRYSTAL] = 2
    call ShopAddItem(id, 'I0C5', sets + staff + cloth)
    call ItemAddComponents('I0C5', "I09N I09N I09N I0A5 I0A5 I0A5")

    //void components
    call ShopAddItem(id, 'I08C', sword)
    call ShopAddItem(id, 'I08D', heavy)
    call ShopAddItem(id, 'I08J', dagger)
    call ShopAddItem(id, 'I08H', bow)
    call ShopAddItem(id, 'I08G', staff)
    call ShopAddItem(id, 'I08S', plate)
    call ShopAddItem(id, 'I08U', fullplate)
    call ShopAddItem(id, 'I08O', leather)
    call ShopAddItem(id, 'I08M', cloth)
    call ShopAddItem(id, 'I055', misc)
    call ShopAddItem(id, 'I04Y', misc)
    call ShopAddItem(id, 'I04W', Shield)

    //void sets
    //sword
    set ItemPrices['I0D7'][PLATINUM] = 6
    set ItemPrices['I0D7'][ARCADITE] = 3
    set ItemPrices['I0D7'][CRYSTAL] = 3
    call ShopAddItem(id, 'I0D7', sets + sword + plate)
    call ItemAddComponents('I0D7', "I08C I08C I08C I08S I08S I08D I055")
    //heavy
    set ItemPrices['I0C4'][PLATINUM] = 6
    set ItemPrices['I0C4'][ARCADITE] = 3
    set ItemPrices['I0C4'][CRYSTAL] = 3
    call ShopAddItem(id, 'I0C4', sets + heavy + fullplate)
    call ItemAddComponents('I0C4', "I08U I08U I08U I08D I08D I08S I04W")
    //dagger
    set ItemPrices['I0C3'][PLATINUM] = 6
    set ItemPrices['I0C3'][ARCADITE] = 3
    set ItemPrices['I0C3'][CRYSTAL] = 3
    call ShopAddItem(id, 'I0C3', sets + dagger + leather)
    call ItemAddComponents('I0C3', "I08J I08J I08J I08O I08O I08O I055")
	//bow
    set ItemPrices['I0D5'][PLATINUM] = 6
    set ItemPrices['I0D5'][ARCADITE] = 3
    set ItemPrices['I0D5'][CRYSTAL] = 3
    call ShopAddItem(id, 'I0D5', sets + bow + leather)
    call ItemAddComponents('I0D5', "I08H I08H I08H I08O I08O I08O I055")
	//staff
    set ItemPrices['I0D6'][PLATINUM] = 6
    set ItemPrices['I0D6'][ARCADITE] = 3
    set ItemPrices['I0D6'][CRYSTAL] = 3
    call ShopAddItem(id, 'I0D6', sets + staff + cloth)
    call ItemAddComponents('I0D6', "I08G I08G I08G I08M I08M I08M I04Y")

    //nightmare components
    call ShopAddItem(id, 'I09P', sword)
    call ShopAddItem(id, 'I0A9', heavy)
    call ShopAddItem(id, 'I09R', dagger)
    call ShopAddItem(id, 'I09S', bow)
    call ShopAddItem(id, 'I09T', staff)
    call ShopAddItem(id, 'I0A7', plate)
    call ShopAddItem(id, 'I09V', fullplate)
    call ShopAddItem(id, 'I0AC', leather)
    call ShopAddItem(id, 'I0AB', cloth)

    //nightmare sets
    //sword
    set ItemPrices['I0CB'][PLATINUM] = 10
    set ItemPrices['I0CB'][ARCADITE] = 6
    set ItemPrices['I0CB'][CRYSTAL] = 6
    call ShopAddItem(id, 'I0CB', sets + sword + plate)
    call ItemAddComponents('I0CB', "I09P I09P I09P I09P I0A7 I0A7 I09V")
    //heavy
    set ItemPrices['I0CA'][PLATINUM] = 10
    set ItemPrices['I0CA'][ARCADITE] = 6
    set ItemPrices['I0CA'][CRYSTAL] = 6
    call ShopAddItem(id, 'I0CA', sets + heavy + fullplate)
    call ItemAddComponents('I0CA', "I0A9 I0A9 I0A9 I09V I09V I09V I0A7")
    //dagger
    set ItemPrices['I0CD'][PLATINUM] = 10
    set ItemPrices['I0CD'][ARCADITE] = 6
    set ItemPrices['I0CD'][CRYSTAL] = 6
    call ShopAddItem(id, 'I0CD', sets + dagger + leather)
    call ItemAddComponents('I0CD', "I09R I09R I09R I09R I0AC I0AC I0AC")
	//bow
    set ItemPrices['I0CE'][PLATINUM] = 10
    set ItemPrices['I0CE'][ARCADITE] = 6
    set ItemPrices['I0CE'][CRYSTAL] = 6
    call ShopAddItem(id, 'I0CE', sets + bow + leather)
    call ItemAddComponents('I0CE', "I09S I09S I09S I09S I0AC I0AC I0AC")
	//staff
    set ItemPrices['I0CF'][PLATINUM] = 10
    set ItemPrices['I0CF'][ARCADITE] = 6
    set ItemPrices['I0CF'][CRYSTAL] = 6
    call ShopAddItem(id, 'I0CF', sets + staff + cloth)
    call ItemAddComponents('I0CF', "I09T I09T I09T I09T I0AB I0AB I0AB")

    //hell components
    call ShopAddItem(id, 'I05G', sword)
    call ShopAddItem(id, 'I05H', heavy)
    call ShopAddItem(id, 'I08Z', dagger)
    call ShopAddItem(id, 'I091', bow)
    call ShopAddItem(id, 'I093', staff)
    call ShopAddItem(id, 'I097', plate)
    call ShopAddItem(id, 'I08W', fullplate)
    call ShopAddItem(id, 'I098', leather)
    call ShopAddItem(id, 'I095', cloth)
    call ShopAddItem(id, 'I05I', misc)

    //hell sets
    //sword
    set ItemPrices['I0D8'][PLATINUM] = 15
    set ItemPrices['I0D8'][ARCADITE] = 10
    set ItemPrices['I0D8'][CRYSTAL] = 10
    call ShopAddItem(id, 'I0D8', sets + sword + plate)
    call ItemAddComponents('I0D8', "I05G I05G I05G I097 I097 I08W I05I")
    //heavy
    set ItemPrices['I0BW'][PLATINUM] = 15
    set ItemPrices['I0BW'][ARCADITE] = 10
    set ItemPrices['I0BW'][CRYSTAL] = 10
    call ShopAddItem(id, 'I0BW', sets + heavy + fullplate)
    call ItemAddComponents('I0BW', "I05H I05H I05H I08W I08W I08W I097")
    //dagger
    set ItemPrices['I0BU'][PLATINUM] = 15
    set ItemPrices['I0BU'][ARCADITE] = 10
    set ItemPrices['I0BU'][CRYSTAL] = 10
    call ShopAddItem(id, 'I0BU', sets + dagger + leather)
    call ItemAddComponents('I0BU', "I08Z I08Z I08Z I098 I098 I098 I05I")
	//bow
    set ItemPrices['I0DK'][PLATINUM] = 15
    set ItemPrices['I0DK'][ARCADITE] = 10
    set ItemPrices['I0DK'][CRYSTAL] = 10
    call ShopAddItem(id, 'I0DK', sets + bow + leather)
    call ItemAddComponents('I0DK', "I091 I091 I091 I098 I098 I098 I05I")
	//staff
    set ItemPrices['I0DJ'][PLATINUM] = 15
    set ItemPrices['I0DJ'][ARCADITE] = 10
    set ItemPrices['I0DJ'][CRYSTAL] = 10
    call ShopAddItem(id, 'I0DJ', sets + staff + cloth)
    call ItemAddComponents('I0DJ', "I093 I093 I093 I093 I095 I095 I095")

    //existence components
    call ShopAddItem(id, 'I09K', sword)
    call ShopAddItem(id, 'I09W', heavy)
    call ShopAddItem(id, 'I09I', dagger)
    call ShopAddItem(id, 'I09G', bow)
    call ShopAddItem(id, 'I09E', staff)
    call ShopAddItem(id, 'I09U', plate)
    call ShopAddItem(id, 'I09M', fullplate)
    call ShopAddItem(id, 'I09Q', leather)
    call ShopAddItem(id, 'I09O', cloth)

    //existence sets
    //sword
    set ItemPrices['I0DX'][PLATINUM] = 25
    set ItemPrices['I0DX'][ARCADITE] = 15
    set ItemPrices['I0DX'][CRYSTAL] = 15
    call ShopAddItem(id, 'I0DX', sets + sword + plate)
    call ItemAddComponents('I0DX', "I09K I09K I09K I09K I09U I09U I09M")
    //heavy
    set ItemPrices['I0BT'][PLATINUM] = 25
    set ItemPrices['I0BT'][ARCADITE] = 15
    set ItemPrices['I0BT'][CRYSTAL] = 15
    call ShopAddItem(id, 'I0BT', sets + heavy + fullplate)
    call ItemAddComponents('I0BT', "I09W I09W I09W I09M I09M I09M I09U")
    //dagger
    set ItemPrices['I0BR'][PLATINUM] = 25
    set ItemPrices['I0BR'][ARCADITE] = 15
    set ItemPrices['I0BR'][CRYSTAL] = 15
    call ShopAddItem(id, 'I0BR', sets + dagger + leather)
    call ItemAddComponents('I0BR', "I09I I09I I09I I09I I09Q I09Q I09Q")
	//bow
    set ItemPrices['I0DL'][PLATINUM] = 25
    set ItemPrices['I0DL'][ARCADITE] = 15
    set ItemPrices['I0DL'][CRYSTAL] = 15
    call ShopAddItem(id, 'I0DL', sets + bow + leather)
    call ItemAddComponents('I0DL', "I09G I09G I09G I09G I09Q I09Q I09Q")
	//staff
    set ItemPrices['I0DY'][PLATINUM] = 25
    set ItemPrices['I0DY'][ARCADITE] = 15
    set ItemPrices['I0DY'][CRYSTAL] = 15
    call ShopAddItem(id, 'I0DY', sets + staff + cloth)
    call ItemAddComponents('I0DY', "I09E I09E I09E I09E I09O I09O I09O")

    //astral components
    call ShopAddItem(id, 'I0A3', sword)
    call ShopAddItem(id, 'I0AN', heavy)
    call ShopAddItem(id, 'I0A1', dagger)
    call ShopAddItem(id, 'I0A4', bow)
    call ShopAddItem(id, 'I09Z', staff)
    call ShopAddItem(id, 'I0AL', plate)
    call ShopAddItem(id, 'I0A6', fullplate)
    call ShopAddItem(id, 'I0AA', leather)
    call ShopAddItem(id, 'I0A8', cloth)

    //astral sets
    //sword
    set ItemPrices['I0E0'][PLATINUM] = 45
    set ItemPrices['I0E0'][ARCADITE] = 30
    set ItemPrices['I0E0'][CRYSTAL] = 30
    call ShopAddItem(id, 'I0E0', sets + sword + plate)
    call ItemAddComponents('I0E0', "I0A3 I0A3 I0A3 I0A3 I0AL I0AL I0A6")
    //heavy
    set ItemPrices['I0BM'][PLATINUM] = 45
    set ItemPrices['I0BM'][ARCADITE] = 30
    set ItemPrices['I0BM'][CRYSTAL] = 30
    call ShopAddItem(id, 'I0BM', sets + heavy + fullplate)
    call ItemAddComponents('I0BM', "I0AN I0AN I0AN I0A6 I0A6 I0A6 I0AL")
    //dagger
    set ItemPrices['I0DZ'][PLATINUM] = 45
    set ItemPrices['I0DZ'][ARCADITE] = 30
    set ItemPrices['I0DZ'][CRYSTAL] = 30
    call ShopAddItem(id, 'I0DZ', sets + dagger + leather)
    call ItemAddComponents('I0DZ', "I0A1 I0A1 I0A1 I0A1 I0AA I0AA I0AA")
	//bow
    set ItemPrices['I059'][PLATINUM] = 45
    set ItemPrices['I059'][ARCADITE] = 30
    set ItemPrices['I059'][CRYSTAL] = 30
    call ShopAddItem(id, 'I059', sets + bow + leather)
    call ItemAddComponents('I059', "I0A4 I0A4 I0A4 I0A4 I0AA I0AA I0AA")
	//staff
    set ItemPrices['I0E1'][PLATINUM] = 45
    set ItemPrices['I0E1'][ARCADITE] = 30
    set ItemPrices['I0E1'][CRYSTAL] = 30
    call ShopAddItem(id, 'I0E1', sets + staff + cloth)
    call ItemAddComponents('I0E1', "I09Z I09Z I09Z I09Z I0A8 I0A8 I0A8")

    //dimensional components
    call ShopAddItem(id, 'I0AO', sword)
    call ShopAddItem(id, 'I0B0', heavy)
    call ShopAddItem(id, 'I0AT', dagger)
    call ShopAddItem(id, 'I0AR', bow)
    call ShopAddItem(id, 'I0AW', staff)
    call ShopAddItem(id, 'I0AY', plate)
    call ShopAddItem(id, 'I0AQ', fullplate)
    call ShopAddItem(id, 'I0B2', leather)
    call ShopAddItem(id, 'I0B3', cloth)

    //dimensional sets
    //sword
    set ItemPrices['I0CG'][PLATINUM] = 80
    set ItemPrices['I0CG'][ARCADITE] = 55
    set ItemPrices['I0CG'][CRYSTAL] = 55
    call ShopAddItem(id, 'I0CG', sets + sword + plate)
    call ItemAddComponents('I0CG', "I0AO I0AO I0AO I0AO I0AY I0AY I0AQ")
    //heavy
    set ItemPrices['I0FH'][PLATINUM] = 80
    set ItemPrices['I0FH'][ARCADITE] = 55
    set ItemPrices['I0FH'][CRYSTAL] = 55
    call ShopAddItem(id, 'I0FH', sets + heavy + fullplate)
    call ItemAddComponents('I0FH', "I0B0 I0B0 I0B0 I0AQ I0AQ I0AQ I0AY")
    //dagger
    set ItemPrices['I0CI'][PLATINUM] = 80
    set ItemPrices['I0CI'][ARCADITE] = 55
    set ItemPrices['I0CI'][CRYSTAL] = 55
    call ShopAddItem(id, 'I0CI', sets + dagger + leather)
    call ItemAddComponents('I0CI', "I0AT I0AT I0AT I0AT I0B2 I0B2 I0B2")
	//bow
    set ItemPrices['I0FI'][PLATINUM] = 80
    set ItemPrices['I0FI'][ARCADITE] = 55
    set ItemPrices['I0FI'][CRYSTAL] = 55
    call ShopAddItem(id, 'I0FI', sets + bow + leather)
    call ItemAddComponents('I0FI', "I0AR I0AR I0AR I0AR I0B2 I0B2 I0B2")
	//staff
    set ItemPrices['I0FZ'][PLATINUM] = 80
    set ItemPrices['I0FZ'][ARCADITE] = 55
    set ItemPrices['I0FZ'][CRYSTAL] = 55
    call ShopAddItem(id, 'I0FZ', sets + staff + cloth)
    call ItemAddComponents('I0FZ', "I0AW I0AW I0AW I0AW I0B3 I0B3 I0B3")
    //cheese shield
    //call ShopAddItem(id2, 'I01Y', misc)
    set ItemPrices['I038'][GOLD] = 100
    call ShopAddItem(id2, 'I038', misc)
    call ItemAddComponents('I038', "I01Y")

    //hydra weapons
    set ItemPrices['I02N'][GOLD] = 5000
    set ItemPrices['I072'][GOLD] = 5000
    set ItemPrices['I06Y'][GOLD] = 5000
    set ItemPrices['I070'][GOLD] = 5000
    set ItemPrices['I071'][GOLD] = 5000
    call ShopAddItem(id2, 'I02N', sword)
    call ShopAddItem(id2, 'I072', heavy)
    call ShopAddItem(id2, 'I06Y', dagger)
    call ShopAddItem(id2, 'I070', bow)
    call ShopAddItem(id2, 'I071', staff)

    call ItemAddComponents('I02N', "I07N")
    call ItemAddComponents('I072', "I07N")
    call ItemAddComponents('I06Y', "I07N")
    call ItemAddComponents('I070', "I07N")
    call ItemAddComponents('I071', "I07N")

    //iron golem fist
    //call ShopAddItem(id2, 'I02Q', misc)

    set ItemPrices['I046'][GOLD] = 75000
    call ShopAddItem(id2, 'I046', misc)
    call ItemAddComponents('I046', "I02Q I02Q I02Q I02Q I02Q I02Q")

    //dragon armor
    set ItemPrices['I048'][GOLD] = 10000
    set ItemPrices['I02U'][GOLD] = 10000
    set ItemPrices['I064'][GOLD] = 10000
    set ItemPrices['I02P'][GOLD] = 10000
    call ShopAddItem(id2, 'I048', plate)
    call ShopAddItem(id2, 'I02U', fullplate)
    call ShopAddItem(id2, 'I064', leather)
    call ShopAddItem(id2, 'I02P', cloth)

    call ItemAddComponents('I048', "I05Z I05Z I056")
    call ItemAddComponents('I02U', "I05Z I05Z I056")
    call ItemAddComponents('I064', "I05Z I05Z I056")
    call ItemAddComponents('I02P', "I05Z I05Z I056")

    //dragon weapons
    set ItemPrices['I033'][GOLD] = 10000
    set ItemPrices['I0BZ'][GOLD] = 10000
    set ItemPrices['I02S'][GOLD] = 10000
    set ItemPrices['I032'][GOLD] = 10000
    set ItemPrices['I065'][GOLD] = 10000
    call ShopAddItem(id2, 'I033', sword)
    call ShopAddItem(id2, 'I0BZ', heavy)
    call ShopAddItem(id2, 'I02S', dagger)
    call ShopAddItem(id2, 'I032', bow)
    call ShopAddItem(id2, 'I065', staff)

    call ItemAddComponents('I033', "I04X I04X I056")
    call ItemAddComponents('I0BZ', "I04X I04X I056")
    call ItemAddComponents('I02S', "I04X I04X I056")
    call ItemAddComponents('I032', "I04X I04X I056")
    call ItemAddComponents('I065', "I04X I04X I056")

    //bloody armor
    //call ShopAddItem(id2, 'I04Q', plate)

    set ItemPrices['I0N4'][CRYSTAL] = 1
    set ItemPrices['I00X'][CRYSTAL] = 1
    set ItemPrices['I0N5'][CRYSTAL] = 1
    set ItemPrices['I0N6'][CRYSTAL] = 1
    call ShopAddItem(id2, 'I0N4', plate)
    call ShopAddItem(id2, 'I00X', fullplate)
    call ShopAddItem(id2, 'I0N5', leather)
    call ShopAddItem(id2, 'I0N6', cloth)

    call ItemAddComponents('I0N4', "I04Q")
    call ItemAddComponents('I00X', "I04Q")
    call ItemAddComponents('I0N5', "I04Q")
    call ItemAddComponents('I0N6', "I04Q")

    //bloody weapons
    set ItemPrices['I03F'][CRYSTAL] = 1
    set ItemPrices['I04S'][CRYSTAL] = 1
    set ItemPrices['I020'][CRYSTAL] = 1
    set ItemPrices['I016'][CRYSTAL] = 1
    set ItemPrices['I0AK'][CRYSTAL] = 1
    call ShopAddItem(id2, 'I03F', sword)
    call ShopAddItem(id2, 'I04S', heavy)
    call ShopAddItem(id2, 'I020', dagger)
    call ShopAddItem(id2, 'I016', bow)
    call ShopAddItem(id2, 'I0AK', staff)

    call ItemAddComponents('I03F', "I04Q")
    call ItemAddComponents('I04S', "I04Q")
    call ItemAddComponents('I020', "I04Q")
    call ItemAddComponents('I016', "I04Q")
    call ItemAddComponents('I0AK', "I04Q")

    //chaotic necklace
    //call ShopAddItem(id2, 'I04Z', misc)

    set ItemPrices['I050'][PLATINUM] = 10
    set ItemPrices['I050'][CRYSTAL] = 10
    call ShopAddItem(id2, 'I050', misc)
    call ItemAddComponents('I050', "I04Z I04Z I04Z I04Z I04Z I04Z")
endfunction

function ShopkeeperClick takes nothing returns boolean
    local trackable track = GetTriggeringTrackable()
    local integer pid = LoadInteger(MiscHash, GetHandleId(track), 'evil')

    if hselection[pid] == false then
        if GetLocalPlayer() == Player(pid - 1) then
            call ClearSelection()
            call SelectUnit(gg_unit_n02S_0098, true)
        endif
    endif

    set track = null
    return false
endfunction

function SpawnSetup takes nothing returns nothing
    local integer id = 0

	set RegionCount[25]  = gg_rct_Troll_Demon_1
	set RegionCount[26]  = gg_rct_Troll_Demon_2
	set RegionCount[27]  = gg_rct_Troll_Demon_3
	set RegionCount[50]  = gg_rct_Tuskar_Horror_1
	set RegionCount[51]  = gg_rct_Tuskar_Horror_2
	set RegionCount[52]  = gg_rct_Tuskar_Horror_3
	set RegionCount[75]  = gg_rct_Spider_Horror_1
	set RegionCount[76]  = gg_rct_Spider_Horror_2
	set RegionCount[77]  = gg_rct_Spider_Horror_3
	set RegionCount[78]  = gg_rct_Spider_Horror_4
	set RegionCount[100] = gg_rct_Ursa_Abyssal_1
	set RegionCount[101] = gg_rct_Ursa_Abyssal_2
	set RegionCount[102] = gg_rct_Ursa_Abyssal_3
	set RegionCount[103] = gg_rct_Ursa_Abyssal_4
	set RegionCount[104] = gg_rct_Ursa_Abyssal_5
	set RegionCount[105] = gg_rct_Ursa_Abyssal_6
	set RegionCount[125] = gg_rct_Bear_1
	set RegionCount[126] = gg_rct_Bear_2
	set RegionCount[127] = gg_rct_Bear_3
	set RegionCount[128] = gg_rct_Bear_4
	set RegionCount[129] = gg_rct_Bear_5
	set RegionCount[150] = gg_rct_OgreTauren_Void_1
	set RegionCount[151] = gg_rct_OgreTauren_Void_2
	set RegionCount[152] = gg_rct_OgreTauren_Void_3
	set RegionCount[153] = gg_rct_OgreTauren_Void_4
	set RegionCount[154] = gg_rct_OgreTauren_Void_5
	set RegionCount[155] = gg_rct_OgreTauren_Void_6
	set RegionCount[156] = gg_rct_OgreTauren_Void_7
	set RegionCount[175] = gg_rct_Unbroken_Dimensional_1
	set RegionCount[176] = gg_rct_Unbroken_Dimensional_2
	set RegionCount[200] = gg_rct_Hell_1
	set RegionCount[201] = gg_rct_Hell_2
	set RegionCount[202] = gg_rct_Hell_3
	set RegionCount[203] = gg_rct_Hell_4
	set RegionCount[204] = gg_rct_Hell_5
	set RegionCount[225] = gg_rct_Centaur_Nightmare_1
	set RegionCount[226] = gg_rct_Centaur_Nightmare_2
	set RegionCount[227] = gg_rct_Centaur_Nightmare_3
	set RegionCount[228] = gg_rct_Centaur_Nightmare_4
	set RegionCount[229] = gg_rct_Centaur_Nightmare_5
	set RegionCount[250] = gg_rct_Magnataur_Despair_1
	set RegionCount[275] = gg_rct_Hydra_Spawn
	set RegionCount[300] = gg_rct_Dragon_Astral_1
	set RegionCount[301] = gg_rct_Dragon_Astral_2
	set RegionCount[302] = gg_rct_Dragon_Astral_3
	set RegionCount[303] = gg_rct_Dragon_Astral_4
	set RegionCount[304] = gg_rct_Dragon_Astral_5
	set RegionCount[305] = gg_rct_Dragon_Astral_6
	set RegionCount[306] = gg_rct_Dragon_Astral_7
	set RegionCount[307] = gg_rct_Dragon_Astral_8
	set RegionCount[325] = gg_rct_Devourer_Existence_1
	set RegionCount[326] = gg_rct_Devourer_Existence_2
	set RegionCount[350] = gg_rct_Azazoth_Circle_Spawn
	set RegionCount[375] = gg_rct_Tuskar_Horror_1
	set RegionCount[376] = gg_rct_Tuskar_Horror_2
	set RegionCount[377] = gg_rct_Tuskar_Horror_3
	set RegionCount[378] = gg_rct_Spider_Horror_1
	set RegionCount[379] = gg_rct_Spider_Horror_2
	set RegionCount[380] = gg_rct_Spider_Horror_3
	set RegionCount[381] = gg_rct_Spider_Horror_4
	set RegionCount[400] = gg_rct_Ursa_Abyssal_1
	set RegionCount[401] = gg_rct_Ursa_Abyssal_2
	set RegionCount[402] = gg_rct_Ursa_Abyssal_3
	set RegionCount[403] = gg_rct_Ursa_Abyssal_4
	set RegionCount[404] = gg_rct_Ursa_Abyssal_5
	set RegionCount[405] = gg_rct_Ursa_Abyssal_6
	set RegionCount[406] = gg_rct_Abyssal_Only
	set RegionCount[425] = gg_rct_OgreTauren_Void_1
	set RegionCount[426] = gg_rct_OgreTauren_Void_2
	set RegionCount[427] = gg_rct_OgreTauren_Void_3
	set RegionCount[428] = gg_rct_OgreTauren_Void_4
	set RegionCount[429] = gg_rct_OgreTauren_Void_5
	set RegionCount[430] = gg_rct_OgreTauren_Void_6
	set RegionCount[431] = gg_rct_OgreTauren_Void_7
	set RegionCount[432] = gg_rct_Void_Only
	set RegionCount[450] = gg_rct_Magnataur_Despair_1
	set RegionCount[451] = gg_rct_Magnataur_Despair_2

    //ice troll trapper
    set id = 'nitt'
    set UnitData[id][UNITDATA_COUNT] = 18 
    set UnitData[id][UNITDATA_SPAWN] = 1
    set UnitData[0][0] = id
    //ice troll berserker
    set id = 'nits'
    set UnitData[id][UNITDATA_COUNT] = 10 
    set UnitData[id][UNITDATA_SPAWN] = 1
    set UnitData[0][1] = id
    //tuskarr sorc
    set id = 'ntks'
    set UnitData[id][UNITDATA_COUNT] = 10 
    set UnitData[id][UNITDATA_SPAWN] = 2
    set UnitData[0][2] = id
    //tuskarr warrior
    set id = 'ntkw'
    set UnitData[id][UNITDATA_COUNT] = 11 
    set UnitData[id][UNITDATA_SPAWN] = 2
    set UnitData[0][3] = id
    //tuskarr chieftain
    set id = 'ntkc'
    set UnitData[id][UNITDATA_COUNT] = 9 
    set UnitData[id][UNITDATA_SPAWN] = 2
    set UnitData[0][4] = id
    //nerubian Seer
    set id = 'nnwr'
    set UnitData[id][UNITDATA_COUNT] = 18 
    set UnitData[id][UNITDATA_SPAWN] = 3
    set UnitData[0][5] = id
    //nerubian spider lord
    set id = 'nnws'
    set UnitData[id][UNITDATA_COUNT] = 18 
    set UnitData[id][UNITDATA_SPAWN] = 3
    set UnitData[0][6] = id
    //polar furbolg warrior 
    set id = 'nfpu'
    set UnitData[id][UNITDATA_COUNT] = 38 
    set UnitData[id][UNITDATA_SPAWN] = 4
    set UnitData[0][7] = id
    //polar furbolg elder shaman
    set id = 'nfpe'
    set UnitData[id][UNITDATA_COUNT] = 22 
    set UnitData[id][UNITDATA_SPAWN] = 4
    set UnitData[0][8] = id
    //giant polar bear
    set id = 'nplg'
    set UnitData[id][UNITDATA_COUNT] = 20 
    set UnitData[id][UNITDATA_SPAWN] = 5
    set UnitData[0][9] = id
    //dire mammoth
    set id = 'nmdr'
    set UnitData[id][UNITDATA_COUNT] = 16 
    set UnitData[id][UNITDATA_SPAWN] = 5
    set UnitData[0][10] = id
    //ogre overlord
    set id = 'n01G'
    set UnitData[id][UNITDATA_COUNT] = 55 
    set UnitData[id][UNITDATA_SPAWN] = 6
    set UnitData[0][11] = id
    //tauren
    set id = 'o01G'
    set UnitData[id][UNITDATA_COUNT] = 40 
    set UnitData[id][UNITDATA_SPAWN] = 6
    set UnitData[0][12] = id
    //unbroken deathbringer
    set id = 'nfod'
    set UnitData[id][UNITDATA_COUNT] = 18 
    set UnitData[id][UNITDATA_SPAWN] = 7
    set UnitData[0][13] = id
    //unbroken trickster
    set id = 'nfor'
    set UnitData[id][UNITDATA_COUNT] = 15 
    set UnitData[id][UNITDATA_SPAWN] = 7
    set UnitData[0][14] = id
    //unbroken darkweaver
    set id = 'nubw'
    set UnitData[id][UNITDATA_COUNT] = 12 
    set UnitData[id][UNITDATA_SPAWN] = 7
    set UnitData[0][15] = id
    //lesser hellfire
    set id = 'nvdl'
    set UnitData[id][UNITDATA_COUNT] = 25 
    set UnitData[id][UNITDATA_SPAWN] = 8
    set UnitData[0][16] = id
    //lesser hellhound
    set id = 'nvdw'
    set UnitData[id][UNITDATA_COUNT] = 30 
    set UnitData[id][UNITDATA_SPAWN] = 8
    set UnitData[0][17] = id
    //centaur lancer
    set id = 'n027'
    set UnitData[id][UNITDATA_COUNT] = 25 
    set UnitData[id][UNITDATA_SPAWN] = 9
    set UnitData[0][18] = id
    //centaur ranger
    set id = 'n024'
    set UnitData[id][UNITDATA_COUNT] = 20 
    set UnitData[id][UNITDATA_SPAWN] = 9
    set UnitData[0][19] = id
    //centaur mage
    set id = 'n028'
    set UnitData[id][UNITDATA_COUNT] = 15 
    set UnitData[id][UNITDATA_SPAWN] = 9
    set UnitData[0][20] = id
    //magnataur destroyer
    set id = 'n01M'
    set UnitData[id][UNITDATA_COUNT] = 45 
    set UnitData[id][UNITDATA_SPAWN] = 10
    set UnitData[0][21] = id
    //forgotten one
    set id = 'n08M'
    set UnitData[id][UNITDATA_COUNT] = 20 
    set UnitData[id][UNITDATA_SPAWN] = 10
    set UnitData[0][22] = id
    //ancient hydra
    set id = 'n01H'
    set UnitData[id][UNITDATA_COUNT] = 4 
    set UnitData[id][UNITDATA_SPAWN] = 11
    set UnitData[0][23] = id
    //frost dragon
    set id = 'n02P'
    set UnitData[id][UNITDATA_COUNT] = 18 
    set UnitData[id][UNITDATA_SPAWN] = 12
    set UnitData[0][24] = id
    //frost drake
    set id = 'n01R'
    set UnitData[id][UNITDATA_COUNT] = 18 
    set UnitData[id][UNITDATA_SPAWN] = 12
    set UnitData[0][25] = id
    //frost elder
    set id = 'n099'
    set UnitData[id][UNITDATA_COUNT] = 1 
    set UnitData[id][UNITDATA_SPAWN] = 14
    set UnitData[0][26] = id
    //medean berserker
    set id = 'n00C'
    set UnitData[id][UNITDATA_COUNT] = 7 
    set UnitData[id][UNITDATA_SPAWN] = 13
    set UnitData[0][27] = id
    //medean devourer
    set id = 'n02L'
    set UnitData[id][UNITDATA_COUNT] = 15 
    set UnitData[id][UNITDATA_SPAWN] = 13
    set UnitData[0][28] = id

    //demon
    set id = 'n033'
    set UnitData[id][UNITDATA_COUNT] = 20 
    set UnitData[id][UNITDATA_SPAWN] = 1
    set UnitData[1][0] = id
    //demon wizard
    set id = 'n034'
    set UnitData[id][UNITDATA_COUNT] = 11 
    set UnitData[id][UNITDATA_SPAWN] = 1
    set UnitData[1][1] = id
    //horror young
    set id = 'n03C'
    set UnitData[id][UNITDATA_COUNT] = 24 
    set UnitData[id][UNITDATA_SPAWN] = 15
    set UnitData[1][2] = id
    //horror mindless
    set id = 'n03A'
    set UnitData[id][UNITDATA_COUNT] = 46 
    set UnitData[id][UNITDATA_SPAWN] = 15
    set UnitData[1][3] = id
    //horror leader
    set id = 'n03B'
    set UnitData[id][UNITDATA_COUNT] = 11 
    set UnitData[id][UNITDATA_SPAWN] = 15
    set UnitData[1][4] = id
    //despair
    set id = 'n03F'
    set UnitData[id][UNITDATA_COUNT] = 62 
    set UnitData[id][UNITDATA_SPAWN] = 18
    set UnitData[1][5] = id
    //despair wizard
    set id = 'n01W'
    set UnitData[id][UNITDATA_COUNT] = 30 
    set UnitData[id][UNITDATA_SPAWN] = 18
    set UnitData[1][6] = id
    //abyssal beast
    set id = 'n00X'
    set UnitData[id][UNITDATA_COUNT] = 19 
    set UnitData[id][UNITDATA_SPAWN] = 16
    set UnitData[1][7] = id
    //abyssal guardian
    set id = 'n08N'
    set UnitData[id][UNITDATA_COUNT] = 34 
    set UnitData[id][UNITDATA_SPAWN] = 16
    set UnitData[1][8] = id
    //abyssal spirit
    set id = 'n00W'
    set UnitData[id][UNITDATA_COUNT] = 34 
    set UnitData[id][UNITDATA_SPAWN] = 16
    set UnitData[1][9] = id
    //void seeker
    set id = 'n030'
    set UnitData[id][UNITDATA_COUNT] = 30 
    set UnitData[id][UNITDATA_SPAWN] = 17
    set UnitData[1][10] = id
    //void keeper
    set id = 'n031'
    set UnitData[id][UNITDATA_COUNT] = 40 
    set UnitData[id][UNITDATA_SPAWN] = 17
    set UnitData[1][11] = id
    //void mother
    set id = 'n02Z'
    set UnitData[id][UNITDATA_COUNT] = 40 
    set UnitData[id][UNITDATA_SPAWN] = 17
    set UnitData[1][12] = id
    //nightmare creature
    set id = 'n020'
    set UnitData[id][UNITDATA_COUNT] = 22 
    set UnitData[id][UNITDATA_SPAWN] = 9
    set UnitData[1][13] = id
    //nightmare spirit
    set id = 'n02J'
    set UnitData[id][UNITDATA_COUNT] = 18 
    set UnitData[id][UNITDATA_SPAWN] = 9
    set UnitData[1][14] = id
    //spawn of hell
    set id = 'n03E'
    set UnitData[id][UNITDATA_COUNT] = 18 
    set UnitData[id][UNITDATA_SPAWN] = 8
    set UnitData[1][15] = id
    //death dealer
    set id = 'n03D'
    set UnitData[id][UNITDATA_COUNT] = 16 
    set UnitData[id][UNITDATA_SPAWN] = 8
    set UnitData[1][16] = id
    //lord of plague
    set id = 'n03G'
    set UnitData[id][UNITDATA_COUNT] = 6 
    set UnitData[id][UNITDATA_SPAWN] = 8
    set UnitData[1][17] = id
    //denied existence
    set id = 'n03J'
    set UnitData[id][UNITDATA_COUNT] = 24 
    set UnitData[id][UNITDATA_SPAWN] = 13
    set UnitData[1][18] = id
    //deprived existence
    set id = 'n01X'
    set UnitData[id][UNITDATA_COUNT] = 13 
    set UnitData[id][UNITDATA_SPAWN] = 13
    set UnitData[1][19] = id
    //astral being
    set id = 'n03M'
    set UnitData[id][UNITDATA_COUNT] = 24 
    set UnitData[id][UNITDATA_SPAWN] = 12
    set UnitData[1][20] = id
    //astral entity
    set id = 'n01V'
    set UnitData[id][UNITDATA_COUNT] = 13 
    set UnitData[id][UNITDATA_SPAWN] = 12
    set UnitData[1][21] = id
    //dimensional planewalker
    set id = 'n026'
    set UnitData[id][UNITDATA_COUNT] = 22 
    set UnitData[id][UNITDATA_SPAWN] = 7
    set UnitData[1][22] = id
    //dimensional planeshifter
    set id = 'n03T'
    set UnitData[id][UNITDATA_COUNT] = 18 
    set UnitData[id][UNITDATA_SPAWN] = 7
    set UnitData[1][23] = id

    //forgotten units
    set forgottenTypes[0] = 'o030' //corpse basher
    set forgottenTypes[1] = 'o033' //destroyer
    set forgottenTypes[2] = 'o036' //spirit
    set forgottenTypes[3] = 'o02W' //warrior
    set forgottenTypes[4] = 'o02Y' //monster
endfunction

function UnitSetup takes nothing returns nothing
    local integer i = 0
    local integer i2 = 0
    local integer i3 = 0
    local integer sid = 0
    local real angle = 0.
    local real x = 0.
    local real y = 0.
    local string s = ""
    local unit target
    local trackable track
    local ability abil

    set udg_PunchingBag[1] = gg_unit_h02D_0672
    set udg_PunchingBag[2] = gg_unit_h02E_0674
    
    set udg_TalkToMe13 = AddSpecialEffectTarget("Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl",gg_unit_n0A1_0164,"overhead")
	set udg_TalkToMe20 = AddSpecialEffectTarget("Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl",gg_unit_n02Q_0382,"overhead")

    call PauseUnit(gg_unit_O01A_0372, true)//Zeknen
    call UnitAddAbility(gg_unit_O01A_0372, 'Avul')
    call ShowUnit(gg_unit_n0A1_0164, false)//angel

    call ShopSetup()
    
    set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h00G', 0, 0, 180.00)
    set x = GetRectCenterX(gg_rct_ColoBanner1)
    set y = GetRectCenterY(gg_rct_ColoBanner1)
    call SetUnitPathing(target, false)
    call SetUnitPosition(target, x, y)
    set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h00G', 0, 0, 0)
    set x = GetRectCenterX(gg_rct_ColoBanner2)
    set y = GetRectCenterY(gg_rct_ColoBanner2)
    call SetUnitPathing(target, false)
    call SetUnitPosition(target, x, y)
    set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h00G', 0, 0, 180.00)
    set x = GetRectCenterX(gg_rct_ColoBanner3)
    set y = GetRectCenterY(gg_rct_ColoBanner3)
    call SetUnitPathing(target, false)
    call SetUnitPosition(target, x, y)
    set target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h00G', 0, 0, 0)
    set x = GetRectCenterX(gg_rct_ColoBanner4)
    set y = GetRectCenterY(gg_rct_ColoBanner4)
    call SetUnitPathing(target, false)
    call SetUnitPosition(target, x, y)

    //special prechaos "bosses"
    //pinky
    call UnitAddItem(gg_unit_O019_0375, Item.create('I02Y', 30000., 30000., 0).obj)
    //bryan
    call UnitAddItem(gg_unit_H043_0566, Item.create('I02X', 30000., 30000., 0).obj)
    //ice troll
    call UnitAddItem(gg_unit_O00T_0089, Item.create('I03Z', 30000., 30000., 0).obj)
    //kroresh
    call UnitAddItem(gg_unit_N01N_0050, Item.create('I0BZ', 30000., 30000., 0).obj)
    call UnitAddItem(gg_unit_N01N_0050, Item.create('I064', 30000., 30000., 0).obj)
    call UnitAddItem(gg_unit_N01N_0050, Item.create('I04B', 30000., 30000., 0).obj)
    //forest corruption
    call UnitAddItem(gg_unit_N00M_0495, Item.create('I03X', 30000., 30000., 0).obj)
    call UnitAddItem(gg_unit_N00M_0495, Item.create('I03Y', 30000., 30000., 0).obj)
    //zeknen
    call UnitAddItem(gg_unit_O01A_0372, Item.create('I036', 30000., 30000., 0).obj)
    call UnitAddItem(gg_unit_O01A_0372, Item.create('I03Y', 30000., 30000., 0).obj)

    set BossLoc[0] = Location(-11692., -12774.)
    set BossFacing[0] = 45.
    set BossID[0] = 'O002'
    set BossName[0] = "Minotaur"
    set BossLevel[0] = 75
    set BossItemType[0] = 'I03T'
    set BossItemType[1] = 'I0FW'
    set BossItemType[2] = 'I078'
    set BossItemType[3] = 'I076'
    set BossItemType[4] = 'I07U'

    set BossLoc[1] = Location(-15435., -14354.)
    set BossFacing[1] = 270.
    set BossID[1] = 'H045'
    set BossName[1] = "Forgotten Mystic"
    set BossLevel[1] = 100
    set BossItemType[6] = 'I03U'
    set BossItemType[7] = 'I07F'
    set BossItemType[8] = 'I0F3'
    set BossItemType[9] = 'I03Y'
    set BossItemType[10] = 'I02C'
    set BossItemType[11] = 'I065'

    set BossLoc[2] = GetRectCenter(gg_rct_Hell_Boss_Spawn)
    set BossFacing[2] = 315.
    set BossID[2] = 'U00G'
    set BossName[2] = "Hellfire Magi"
    set BossLevel[2] = 100
    set BossItemType[12] = 'I03Y'
    set BossItemType[13] = 'I0FA'
    set BossItemType[14] = 'I0FU'
    set BossItemType[15] = 'I00V'

    set BossLoc[3] = Location(11520., 15466.)
    set BossFacing[3] = 225.
    set BossID[3] = 'H01V'
    set BossName[3] = "Last Dwarf"
    set BossLevel[3] = 100
    set BossItemType[18] = 'I0FC'
    set BossItemType[19] = 'I079'
    set BossItemType[20] = 'I03Y'
    set BossItemType[21] = 'I07B'

    set BossLoc[4] = GetRectCenter(gg_rct_Dark_Soul_Boss_Spawn)
    set BossFacing[4] = 270.
    set BossID[4] = 'H02H'
    set BossName[4] = "Vengeful Test Paladin"
    set BossLevel[4] = 140
    set BossItemType[24] = 'I03P'
    set BossItemType[25] = 'I0FX'
    set BossItemType[26] = 'I0F9'
    set BossItemType[27] = 'I0C0'
    set BossItemType[28] = 'I03Y'
    set BossItemType[29] = 0

    set BossLoc[5] = GetRectCenter(gg_rct_Thanatos_Boss_Spawn)
    set BossFacing[5] = 320.
    set BossID[5] = 'O01B'
    set BossName[5] = "Dragoon"
    set BossLevel[5] = 100
    set BossItemType[30] = 'I0EY'
    set BossItemType[31] = 'I074'
    set BossItemType[32] = 'I04N'
    set BossItemType[33] = 'I0EX'
    set BossItemType[34] = 'I046'
    set BossItemType[35] = 'I03Y'

    set BossLoc[6] = Location(6932., -14177.)
    set BossFacing[6] = 0.
    set BossID[6] = 'H040'
    set BossName[6] = "Death Knight"
    set BossLevel[6] = 120
    set BossItemType[36] = 'I02B'
    set BossItemType[37] = 'I029'
    set BossItemType[38] = 'I02C'
    set BossItemType[39] = 'I02O'

    set BossLoc[7] = Location(-12375., -1181.)
    set BossFacing[7] = 0.
    set BossID[7] = 'H020'
    set BossName[7] = "Siren of the Tides"
    set BossLevel[7] = 75
    set BossItemType[42] = 'I09L'
    set BossItemType[43] = 'I09F'
    set BossItemType[44] = 'I03Y'

    set BossLoc[8] = Location(15816., 6250.)
    set BossFacing[8] = 180.
    set BossID[8] = 'n02H'
    set BossName[8] = "Super Fun Happy Yeti"

    set BossLoc[9] = Location(-5242., -15630.)
    set BossFacing[9] = 135.
    set BossID[9] = 'n03L'
    set BossName[9] = "King of Ogres"

    set BossLoc[10] = GetRectCenter(gg_rct_Demon_Prince_Boss_Spawn)
    set BossFacing[10] = 315.
    set BossID[10] = 'n02U'
    set BossName[10] = "Nerubian Empress"

    set BossLoc[11] = Location(-16040., 6579.)
    set BossFacing[11] = 45.
    set BossID[11] = 'nplb'
    set BossName[11] = "Giant Polar Bear"

    set BossLoc[12] = Location(-1840., -27400.)
    set BossFacing[12] = 230.
    set BossID[12] = 'H04Q'
    set BossName[12] = "The Goddesses"
    set BossLevel[12] = 180
    set BossItemType[72] = 'I04I'
    set BossItemType[73] = 'I030'
    set BossItemType[74] = 'I031'
    set BossItemType[75] = 'I02Z'
    set BossItemType[76] = 'I03Y'

    set BossLoc[13] = Location(-1977., -27116.) //hate
    set BossFacing[13] = 230.
    set BossID[13] = 'E00B'
    set BossLevel[13] = 180
    set BossItemType[78] = 'I02Z'
    set BossItemType[79] = 'I03Y'
    set BossItemType[80] = 'I02B'

    set BossLoc[14] = Location(-1560., -27486.) //love
    set BossFacing[14] = 230.
    set BossID[14] = 'E00D'
    set BossLevel[14] = 180
    set BossItemType[84] = 'I030'
    set BossItemType[85] = 'I03Y'
    set BossItemType[86] = 'I0EY'

    set BossLoc[15] = Location(-1689., -27210.) //knowledge
    set BossFacing[15] = 230.
    set BossID[15] = 'E00C'
    set BossLevel[15] = 180
    set BossItemType[90] = 'I03U'
    set BossItemType[91] = 'I03Y'
    set BossItemType[92] = 'I02B'

    set BossLoc[16] = Location(-1413., -15846.) //arkaden
    set BossFacing[16] = 90.
    set BossID[16] = 'H00O'
    set BossName[16] = "Arkaden"
    set BossLevel[16] = 140
    set BossItemType[96] = 'I02B'
    set BossItemType[97] = 'I02C'
    set BossItemType[98] = 'I02O'
    set BossItemType[99] = 0
    set BossItemType[100] = 0
    set BossItemType[101] = 0

    set i = 0
    loop
        exitwhen i > BOSS_TOTAL
        set Boss[i] = CreateUnitAtLoc(pboss, BossID[i], BossLoc[i], BossFacing[i])
        call SetHeroLevel(Boss[i], BossLevel[i], false)
        set i2 = 0
        loop
            exitwhen BossItemType[i * 6 + i2] == 0 or i2 > 5
            call UnitAddItem(Boss[i], Item.create(BossItemType[i * 6 + i2], 30000., 30000., 0).obj)
            set i2 = i2 + 1
        endloop
        set i = i + 1
    endloop

    //start death march cd
    call BlzStartUnitAbilityCooldown(Boss[BOSS_DEATH_KNIGHT], 'A0AU', 2040. - (User.AmountPlaying * 240))

    call ShowUnit(Boss[BOSS_LIFE], false) //gods
    call ShowUnit(Boss[BOSS_LOVE], false)
    call ShowUnit(Boss[BOSS_HATE], false)
    call ShowUnit(Boss[BOSS_KNOWLEDGE], false)

    //shopkeeper
    set i = 0
    loop
        exitwhen i >= PLAYER_CAP
        set s = "war3mapImported\\dummy.mdl"

        if GetLocalPlayer() == Player(i) then
            set s = "units\\undead\\Acolyte\\Acolyte.mdl"
        endif

        set track = CreateTrackable(s, GetUnitX(gg_unit_n02S_0098), GetUnitY(gg_unit_n02S_0098), 3 * bj_PI / 4.)
        call SaveInteger(MiscHash, GetHandleId(track), 'evil', i + 1)
        call TriggerRegisterTrackableHitEvent(ShopkeeperTrackable, track)

        set i = i + 1
    endloop

    call TriggerAddCondition(ShopkeeperTrackable, Condition(function ShopkeeperClick))
    
    //hero circle
    set i = 0
    loop
        exitwhen i > HERO_TOTAL
        set angle = bj_PI * (HERO_TOTAL - i) / (HERO_TOTAL * 0.5)

        call SetUnitPosition(hstarget[i], 21643 + 475 * Cos(angle), 3447 + 475 * Sin(angle))
        call SetUnitFacingTimed(hstarget[i], bj_RADTODEG * Atan2(3447 - GetUnitY(hstarget[i]), 21643 - GetUnitX(hstarget[i])), 0)

        set i2 = 0
        //store innate spell tooltip strings
        loop
            set abil = BlzGetUnitAbilityByIndex(hstarget[i], i2)
            exitwhen abil == null
            set sid = BlzGetAbilityId(abil)

            set i3 = 1
            loop
                exitwhen i3 > BlzGetAbilityIntegerField(abil, ABILITY_IF_LEVELS)

                if SpellTooltips[sid].string[i3] == null and LoadInteger(SAVE_TABLE, KEY_SPELLS, sid) != 0 then
                    set SpellTooltips[sid].string[i3] = BlzGetAbilityStringLevelField(abil, ABILITY_SLF_TOOLTIP_NORMAL_EXTENDED, i3 - 1)
                endif

                set i3 = i3 + 1
            endloop

            set i2 = i2 + 1
        endloop

        set i = i + 1
    endloop

    set track = null
endfunction

endlibrary
