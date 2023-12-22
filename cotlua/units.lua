if Debug then Debug.beginFile 'Units' end

OnInit.final("Units", function(require)
    require 'Helper'
    require 'Regions'
    require 'Users'
    require 'Shop'
    require 'Items'
    require 'Spells'

    Boss={} ---@type unit[] 
    BossLoc={} ---@type location[] 
    BossLeash=__jarray(0) ---@type number[] 
    BossFacing=__jarray(0) ---@type number[] 
    BossName=__jarray("") ---@type string[] 
    BossID=__jarray(0) ---@type integer[] 
    BossItemType=__jarray(0) ---@type integer[] 
    BossLevel=__jarray(0) ---@type integer[] 
    BossNearbyPlayers=__jarray(0) ---@type integer[] 
    REGION_GAP         = 25 ---@type integer 
    ShopkeeperTrackable         = CreateTrigger() ---@type trigger 
    --group Sins = CreateGroup()

function ShopSetup()
    local sword ---@type integer 
    local heavy ---@type integer 
    local dagger ---@type integer 
    local bow ---@type integer 
    local staff ---@type integer 
    local plate ---@type integer 
    local fullplate ---@type integer 
    local leather ---@type integer 
    local cloth ---@type integer 
    local Shield ---@type integer 
    local misc ---@type integer 
    local sets ---@type integer 
    local id         = FourCC('n02C')  ---@type integer --town smith
    local id2         = FourCC('n09D')  ---@type integer --reclusive blacksmith
    local id3         = FourCC('n01F')  ---@type integer --evil shopkeeper

    --TODO setup prices beforehand
    ItemPrices[FourCC('I02B')] = __jarray(0)
    ItemPrices[FourCC('I02B')][GOLD] = 20000
    ItemPrices[FourCC('I02C')] = __jarray(0)
    ItemPrices[FourCC('I02C')][GOLD] = 20000
    ItemPrices[FourCC('I0EY')] = __jarray(0)
    ItemPrices[FourCC('I0EY')][GOLD] = 20000
    ItemPrices[FourCC('I074')] = __jarray(0)
    ItemPrices[FourCC('I074')][GOLD] = 20000
    ItemPrices[FourCC('I03U')] = __jarray(0)
    ItemPrices[FourCC('I03U')][GOLD] = 20000
    ItemPrices[FourCC('I07F')] = __jarray(0)
    ItemPrices[FourCC('I07F')][GOLD] = 20000
    ItemPrices[FourCC('I03P')] = __jarray(0)
    ItemPrices[FourCC('I03P')][GOLD] = 20000
    ItemPrices[FourCC('I0F9')] = __jarray(0)
    ItemPrices[FourCC('I0F9')][GOLD] = 20000
    ItemPrices[FourCC('I079')] = __jarray(0)
    ItemPrices[FourCC('I079')][GOLD] = 20000
    ItemPrices[FourCC('I0FC')] = __jarray(0)
    ItemPrices[FourCC('I0FC')][GOLD] = 20000
    ItemPrices[FourCC('I00A')] = __jarray(0)
    ItemPrices[FourCC('I00A')][GOLD] = 80000
    ItemPrices[FourCC('I0JR')] = __jarray(0)
    ItemPrices[FourCC('I0JR')][GOLD] = 100000
    ItemPrices[FourCC('I0JR')][LUMBER] = 100000
    ItemPrices[FourCC('I08K')] = __jarray(0)
    ItemPrices[FourCC('I08K')][GOLD] = 100000
    ItemPrices[FourCC('I08K')][LUMBER] = 100000
    ItemPrices[FourCC('I0F4')] = __jarray(0)
    ItemPrices[FourCC('I0F4')][GOLD] = 100000
    ItemPrices[FourCC('I0F4')][LUMBER] = 100000
    ItemPrices[FourCC('I0F5')] = __jarray(0)
    ItemPrices[FourCC('I0F5')][GOLD] = 100000
    ItemPrices[FourCC('I0F5')][LUMBER] = 100000
    ItemPrices[FourCC('I012')] = __jarray(0)
    ItemPrices[FourCC('I012')][GOLD] = 150000
    ItemPrices[FourCC('I012')][LUMBER] = 150000
    ItemPrices[FourCC('I04J')] = __jarray(0)
    ItemPrices[FourCC('I04J')][GOLD] = 400000
    ItemPrices[FourCC('I04J')][LUMBER] = 200000

    CreateShop(id, 1000., 0.5)
    CreateShop(id2, 1000., 0.5)
    evilshop = CreateShop(id3, 1000., 0.5)

    sword = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNThoriumMelee.blp", "Sword")
    heavy = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNImprovedStrengthOfTheMoon.tga", "Heavy")
    dagger = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNDaggerOfEscape.blp", "Dagger")
    bow = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNScoutsBow.blp", "Bow")
    staff = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNWitchDoctorAdept.blp", "Staff")
    plate = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNAdvancedMoonArmor.blp", "Plate")
    fullplate = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNArmorGolem.blp", "Fullplate")
    leather = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp", "Leather")
    cloth = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNMantleOfIntelligence.blp", "Cloth")
    Shield = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpTwo.blp", "Shield")
    misc = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Miscellaneous")
    sets = ShopAddCategory(id, "ReplaceableTextures\\CommandButtons\\BTNManaShield.blp", "Sets")
    --reclusive blacksmith
    ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNThoriumMelee.blp", "Sword")
    ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNImprovedStrengthOfTheMoon.tga", "Heavy")
    ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNDaggerOfEscape.blp", "Dagger")
    ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNScoutsBow.blp", "Bow")
    ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNWitchDoctorAdept.blp", "Staff")
    ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNAdvancedMoonArmor.blp", "Plate")
    ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNArmorGolem.blp", "Fullplate")
    ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp", "Leather")
    ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNMantleOfIntelligence.blp", "Cloth")
    ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpTwo.blp", "Shield")
    ShopAddCategory(id2, "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Miscellaneous")
    --evil shopkeeper
    ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNThoriumMelee.blp", "Sword")
    ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNImprovedStrengthOfTheMoon.tga", "Heavy")
    ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNDaggerOfEscape.blp", "Dagger")
    ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNScoutsBow.blp", "Bow")
    ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNWitchDoctorAdept.blp", "Staff")
    ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNAdvancedMoonArmor.blp", "Plate")
    ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNArmorGolem.blp", "Fullplate")
    ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNLeatherUpgradeOne.blp", "Leather")
    ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNMantleOfIntelligence.blp", "Cloth")
    ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpTwo.blp", "Shield")
    ShopAddCategory(id3, "ReplaceableTextures\\CommandButtons\\BTNCrystalBall.blp", "Miscellaneous")

    --ursa components
    ShopAddItem(id, FourCC('I06T'), sword)
    ShopAddItem(id, FourCC('I034'), heavy)
    ShopAddItem(id, FourCC('I0FG'), dagger)
    ShopAddItem(id, FourCC('I06R'), bow)
    ShopAddItem(id, FourCC('I0FT'), staff)
    ShopAddItem(id, FourCC('I035'), plate)
    ShopAddItem(id, FourCC('I0FQ'), fullplate)
    ShopAddItem(id, FourCC('I0FO'), leather)
    ShopAddItem(id, FourCC('I07O'), cloth)

    --ursa sets
    --sword
    ItemPrices[FourCC('I0H5')] = __jarray(0)
    ItemPrices[FourCC('I0H5')][GOLD] = 2000
    ShopAddItem(id, FourCC('I0H5'), sets + sword + plate)
    ItemAddComponents(FourCC('I0H5'), "I06T I06T I06T I035 I035 I034")
    --heavy
    ItemPrices[FourCC('I0H6')] = __jarray(0)
    ItemPrices[FourCC('I0H6')][GOLD] = 2000
    ShopAddItem(id, FourCC('I0H6'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0H6'), "I0FQ I0FQ I0FQ I034 I034 I035")
    --dagger
    ItemPrices[FourCC('I0H7')] = __jarray(0)
    ItemPrices[FourCC('I0H7')][GOLD] = 2000
    ShopAddItem(id, FourCC('I0H7'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0H7'), "I0FG I0FG I0FG I0FO I0FO I0FO")
    --bow
    ItemPrices[FourCC('I0H8')] = __jarray(0)
    ItemPrices[FourCC('I0H8')][GOLD] = 2000
    ShopAddItem(id, FourCC('I0H8'), sets + bow + leather)
    ItemAddComponents(FourCC('I0H8'), "I06R I06R I06R I0FO I0FO I0FO")
    --staff
    ItemPrices[FourCC('I0H9')] = __jarray(0)
    ItemPrices[FourCC('I0H9')][GOLD] = 2000
    ShopAddItem(id, FourCC('I0H9'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0H9'), "I0FT I0FT I0FT I07O I07O I07O")

    --ogre components
    ShopAddItem(id, FourCC('I08B'), sword)
    ShopAddItem(id, FourCC('I08I'), heavy)
    ShopAddItem(id, FourCC('I08F'), dagger)
    ShopAddItem(id, FourCC('I08E'), bow)
    ShopAddItem(id, FourCC('I0FE'), staff)
    ShopAddItem(id, FourCC('I0FD'), plate)
    ShopAddItem(id, FourCC('I08R'), fullplate)
    ShopAddItem(id, FourCC('I07Y'), leather)
    ShopAddItem(id, FourCC('I07W'), cloth)

    --ogre sets
    --sword
    ItemPrices[FourCC('I0HA')] = __jarray(0)
    ItemPrices[FourCC('I0HA')][GOLD] = 8000
    ShopAddItem(id, FourCC('I0HA'), sets + sword + plate)
    ItemAddComponents(FourCC('I0HA'), "I08B I08B I08B I0FD I0FD I08I")
    --heavy
    ItemPrices[FourCC('I0HB')] = __jarray(0)
    ItemPrices[FourCC('I0HB')][GOLD] = 8000
    ShopAddItem(id, FourCC('I0HB'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0HB'), "I08R I08R I08R I08I I08I I0FD")
    --dagger
    ItemPrices[FourCC('I0HC')] = __jarray(0)
    ItemPrices[FourCC('I0HC')][GOLD] = 8000
    ShopAddItem(id, FourCC('I0HC'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0HC'), "I08F I08F I08F I07Y I07Y I07Y")
    --bow
    ItemPrices[FourCC('I0HD')] = __jarray(0)
    ItemPrices[FourCC('I0HD')][GOLD] = 8000
    ShopAddItem(id, FourCC('I0HD'), sets + bow + leather)
    ItemAddComponents(FourCC('I0HD'), "I08E I08E I08E I07Y I07Y I07Y")
    --staff
    ItemPrices[FourCC('I0HE')] = __jarray(0)
    ItemPrices[FourCC('I0HE')][GOLD] = 8000
    ShopAddItem(id, FourCC('I0HE'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0HE'), "I0FE I0FE I0FE I07W I07W I07W")

    --unbroken components
    ShopAddItem(id, FourCC('I02E'), sword)
    ShopAddItem(id, FourCC('I023'), heavy)
    ShopAddItem(id, FourCC('I011'), dagger)
    ShopAddItem(id, FourCC('I00S'), bow)
    ShopAddItem(id, FourCC('I00Z'), staff)
    ShopAddItem(id, FourCC('I01W'), plate)
    ShopAddItem(id, FourCC('I0FS'), fullplate)
    ShopAddItem(id, FourCC('I0FY'), leather)
    ShopAddItem(id, FourCC('I0FR'), cloth)

    --unbroken sets
    --sword
    ItemPrices[FourCC('I0HF')] = __jarray(0)
    ItemPrices[FourCC('I0HF')][GOLD] = 32000
    ShopAddItem(id, FourCC('I0HF'), sets + sword + plate)
    ItemAddComponents(FourCC('I0HF'), "I02E I02E I02E I01W I01W I023")
    --heavy
    ItemPrices[FourCC('I0HG')] = __jarray(0)
    ItemPrices[FourCC('I0HG')][GOLD] = 32000
    ShopAddItem(id, FourCC('I0HG'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0HG'), "I0FS I0FS I0FS I023 I023 I01W")
    --dagger
    ItemPrices[FourCC('I0HH')] = __jarray(0)
    ItemPrices[FourCC('I0HH')][GOLD] = 32000
    ShopAddItem(id, FourCC('I0HH'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0HH'), "I011 I011 I011 I0FY I0FY I0FY")
    --bow
    ItemPrices[FourCC('I0HI')] = __jarray(0)
    ItemPrices[FourCC('I0HI')][GOLD] = 32000
    ShopAddItem(id, FourCC('I0HI'), sets + bow + leather)
    ItemAddComponents(FourCC('I0HI'), "I00S I00S I00S I0FY I0FY I0FY")
    --staff
    ItemPrices[FourCC('I0HJ')] = __jarray(0)
    ItemPrices[FourCC('I0HJ')][GOLD] = 32000
    ShopAddItem(id, FourCC('I0HJ'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0HJ'), "I00Z I00Z I00Z I0FR I0FR I0FR")

    --magnataur components
    ShopAddItem(id, FourCC('I06J'), sword)
    ShopAddItem(id, FourCC('I06I'), heavy)
    ShopAddItem(id, FourCC('I06L'), dagger)
    ShopAddItem(id, FourCC('I06K'), bow)
    ShopAddItem(id, FourCC('I07H'), staff)
    ShopAddItem(id, FourCC('I01Q'), plate)
    ShopAddItem(id, FourCC('I01N'), fullplate)
    ShopAddItem(id, FourCC('I019'), leather)
    ShopAddItem(id, FourCC('I015'), cloth)

    --magnataur sets
    --sword
    ItemPrices[FourCC('I0HK')] = __jarray(0)
    ItemPrices[FourCC('I0HK')][GOLD] = 100000
    ShopAddItem(id, FourCC('I0HK'), sets + sword + plate)
    ItemAddComponents(FourCC('I0HK'), "I06J I06J I06J I01Q I01Q I06I")
    --heavy
    ItemPrices[FourCC('I0HL')] = __jarray(0)
    ItemPrices[FourCC('I0HL')][GOLD] = 100000
    ShopAddItem(id, FourCC('I0HL'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0HL'), "I01N I01N I01N I06I I06I I01Q")
    --dagger
    ItemPrices[FourCC('I0HM')] = __jarray(0)
    ItemPrices[FourCC('I0HM')][GOLD] = 100000
    ShopAddItem(id, FourCC('I0HM'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0HM'), "I06L I06L I06L I019 I019 I019")
    --bow
    ItemPrices[FourCC('I0HN')] = __jarray(0)
    ItemPrices[FourCC('I0HN')][GOLD] = 100000
    ShopAddItem(id, FourCC('I0HN'), sets + bow + leather)
    ItemAddComponents(FourCC('I0HN'), "I06K I06K I06K I019 I019 I019")
    --staff
    ItemPrices[FourCC('I0HO')] = __jarray(0)
    ItemPrices[FourCC('I0HO')][GOLD] = 100000
    ShopAddItem(id, FourCC('I0HO'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0HO'), "I07H I07H I07H I015 I015 I015")

    --devourer components
    ShopAddItem(id, FourCC('I009'), sword)
    ShopAddItem(id, FourCC('I006'), heavy)
    ShopAddItem(id, FourCC('I00W'), dagger)
    ShopAddItem(id, FourCC('I02W'), bow)
    ShopAddItem(id, FourCC('I02V'), staff)
    ShopAddItem(id, FourCC('I013'), plate)
    ShopAddItem(id, FourCC('I017'), fullplate)
    ShopAddItem(id, FourCC('I01P'), leather)
    ShopAddItem(id, FourCC('I02I'), cloth)

    --devourer sets
    --sword
    ItemPrices[FourCC('I04R')] = __jarray(0)
    ItemPrices[FourCC('I04R')][GOLD] = 200000
    ShopAddItem(id, FourCC('I04R'), sets + sword + plate)
    ItemAddComponents(FourCC('I04R'), "I009 I009 I009 I013 I013 I017")
    --heavy
    ItemPrices[FourCC('I04K')] = __jarray(0)
    ItemPrices[FourCC('I04K')][GOLD] = 200000
    ShopAddItem(id, FourCC('I04K'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I04K'), "I006 I006 I006 I017 I017 I013")
    --dagger
    ItemPrices[FourCC('I047')] = __jarray(0)
    ItemPrices[FourCC('I047')][GOLD] = 200000
    ShopAddItem(id, FourCC('I047'), sets + dagger + leather)
    ItemAddComponents(FourCC('I047'), "I00W I00W I00W I01P I01P I01P")
    --bow
    ItemPrices[FourCC('I02J')] = __jarray(0)
    ItemPrices[FourCC('I02J')][GOLD] = 200000
    ShopAddItem(id, FourCC('I02J'), sets + bow + leather)
    ItemAddComponents(FourCC('I02J'), "I02W I02W I02W I01P I01P I01P")
    --staff
    ItemPrices[FourCC('I04P')] = __jarray(0)
    ItemPrices[FourCC('I04P')][GOLD] = 200000
    ShopAddItem(id, FourCC('I04P'), sets + staff + cloth)
    ItemAddComponents(FourCC('I04P'), "I02V I02V I02V I02I I02I I02I")

    --shopkeeper components
    ShopAddItem(id3, FourCC('I02B'), sword)
    ShopAddItem(id3, FourCC('I02C'), plate)
    ShopAddItem(id3, FourCC('I0EY'), bow)
    ShopAddItem(id3, FourCC('I074'), dagger)
    ShopAddItem(id3, FourCC('I03U'), staff)
    ShopAddItem(id3, FourCC('I07F'), cloth)
    ShopAddItem(id3, FourCC('I03P'), heavy)
    ShopAddItem(id3, FourCC('I0F9'), misc)
    ShopAddItem(id3, FourCC('I079'), heavy)
    ShopAddItem(id3, FourCC('I0FC'), heavy)
    ShopAddItem(id3, FourCC('I00A'), misc)

    --godslayer set
    ShopAddItem(id, FourCC('I0JR'), sets + sword + plate)
    ItemAddComponents(FourCC('I0JR'), "I02B I02C I02O")

    --dwarven set
    ShopAddItem(id, FourCC('I08K'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I08K'), "I079 I0FC I07B")

    --dragoon set
    ShopAddItem(id, FourCC('I0F4'), sets + leather)
    ItemAddComponents(FourCC('I0F4'), "I0EY I074 I04N I0EX")

    --forgotten mystic set
    ShopAddItem(id, FourCC('I0F5'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0F5'), "I03U I07F I0F3")

    --paladin set
    ShopAddItem(id, FourCC('I012'), sets + Shield)
    ItemAddComponents(FourCC('I012'), "I03P I0FX I0C0 I0F9")

    --aura of gods
    ShopAddItem(id, FourCC('I04J'), sets + misc)
    ItemAddComponents(FourCC('I04J'), "I00A I030 I04I I031 I02Z")

    --demon components
    ShopAddItem(id, FourCC('I06S'), sword)
    ShopAddItem(id, FourCC('I04T'), heavy)
    ShopAddItem(id, FourCC('I06U'), dagger)
    ShopAddItem(id, FourCC('I06O'), bow)
    ShopAddItem(id, FourCC('I06Q'), staff)
    ShopAddItem(id, FourCC('I073'), plate)
    ShopAddItem(id, FourCC('I075'), fullplate)
    ShopAddItem(id, FourCC('I06Z'), leather)
    ShopAddItem(id, FourCC('I06W'), cloth)

    --demon sets
    --sword
    ItemPrices[FourCC('I0CK')] = __jarray(0)
    ItemPrices[FourCC('I0CK')][GOLD] = 250000
    ItemPrices[FourCC('I0CK')][LUMBER] = 125000
    ShopAddItem(id, FourCC('I0CK'), sets + sword + plate)
    ItemAddComponents(FourCC('I0CK'), "I06S I06S I06S I073 I073 I04T")
    --heavy
    ItemPrices[FourCC('I0BN')] = __jarray(0)
    ItemPrices[FourCC('I0BN')][GOLD] = 250000
    ItemPrices[FourCC('I0BN')][LUMBER] = 125000
    ShopAddItem(id, FourCC('I0BN'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0BN'), "I075 I075 I075 I04T I04T I073")
    --dagger
    ItemPrices[FourCC('I0BO')] = __jarray(0)
    ItemPrices[FourCC('I0BO')][GOLD] = 250000
    ItemPrices[FourCC('I0BO')][LUMBER] = 125000
    ShopAddItem(id, FourCC('I0BO'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0BO'), "I06U I06U I06U I06Z I06Z I06Z")
    --bow
    ItemPrices[FourCC('I0CU')] = __jarray(0)
    ItemPrices[FourCC('I0CU')][GOLD] = 250000
    ItemPrices[FourCC('I0CU')][LUMBER] = 125000
    ShopAddItem(id, FourCC('I0CU'), sets + bow + leather)
    ItemAddComponents(FourCC('I0CU'), "I06O I06O I06O I06Z I06Z I06Z")
    --staff
    ItemPrices[FourCC('I0CT')] = __jarray(0)
    ItemPrices[FourCC('I0CT')][GOLD] = 250000
    ItemPrices[FourCC('I0CT')][LUMBER] = 125000
    ShopAddItem(id, FourCC('I0CT'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0CT'), "I06Q I06Q I06Q I06W I06W I06W")

    --horror components
    ShopAddItem(id, FourCC('I07M'), sword)
    ShopAddItem(id, FourCC('I07A'), heavy)
    ShopAddItem(id, FourCC('I07L'), dagger)
    ShopAddItem(id, FourCC('I07P'), bow)
    ShopAddItem(id, FourCC('I077'), staff)
    ShopAddItem(id, FourCC('I07E'), plate)
    ShopAddItem(id, FourCC('I07I'), fullplate)
    ShopAddItem(id, FourCC('I07G'), leather)
    ShopAddItem(id, FourCC('I07C'), cloth)
    ShopAddItem(id, FourCC('I07K'), misc)
    ShopAddItem(id, FourCC('I05D'), Shield)

    --horror sets
    --sword
    ItemPrices[FourCC('I0CV')] = __jarray(0)
    ItemPrices[FourCC('I0CV')][GOLD] = 500000
    ItemPrices[FourCC('I0CV')][LUMBER] = 250000
    ShopAddItem(id, FourCC('I0CV'), sets + sword + plate)
    ItemAddComponents(FourCC('I0CV'), "I07M I07M I07M I07E I07E I07A I07A")
    --heavy
    ItemPrices[FourCC('I0C2')] = __jarray(0)
    ItemPrices[FourCC('I0C2')][GOLD] = 500000
    ItemPrices[FourCC('I0C2')][LUMBER] = 250000
    ShopAddItem(id, FourCC('I0C2'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0C2'), "I07I I07I I07I I07A I07A I07E I05D")
    --dagger
    ItemPrices[FourCC('I0C1')] = __jarray(0)
    ItemPrices[FourCC('I0C1')][GOLD] = 500000
    ItemPrices[FourCC('I0C1')][LUMBER] = 250000
    ShopAddItem(id, FourCC('I0C1'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0C1'), "I07L I07L I07L I07G I07G I07G I07K")
    --bow
    ItemPrices[FourCC('I0CW')] = __jarray(0)
    ItemPrices[FourCC('I0CW')][GOLD] = 500000
    ItemPrices[FourCC('I0CW')][LUMBER] = 250000
    ShopAddItem(id, FourCC('I0CW'), sets + bow + leather)
    ItemAddComponents(FourCC('I0CW'), "I07P I07P I07P I07G I07G I07G I07K")
    --staff
    ItemPrices[FourCC('I0CX')] = __jarray(0)
    ItemPrices[FourCC('I0CX')][GOLD] = 500000
    ItemPrices[FourCC('I0CX')][LUMBER] = 250000
    ShopAddItem(id, FourCC('I0CX'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0CX'), "I077 I077 I077 I07C I07C I07C I07K")

    --despair components
    ShopAddItem(id, FourCC('I07V'), sword)
    ShopAddItem(id, FourCC('I07X'), heavy)
    ShopAddItem(id, FourCC('I07Z'), dagger)
    ShopAddItem(id, FourCC('I07R'), bow)
    ShopAddItem(id, FourCC('I07T'), staff)
    ShopAddItem(id, FourCC('I087'), plate)
    ShopAddItem(id, FourCC('I089'), fullplate)
    ShopAddItem(id, FourCC('I083'), leather)
    ShopAddItem(id, FourCC('I081'), cloth)
    ShopAddItem(id, FourCC('I05P'), misc)

    --despair sets
    --sword
    ItemPrices[FourCC('I0CY')] = __jarray(0)
    ItemPrices[FourCC('I0CY')][GOLD] = 500000
    ItemPrices[FourCC('I0CY')][PLATINUM] = 1
    ItemPrices[FourCC('I0CY')][LUMBER] = 750000
    ItemPrices[FourCC('I0CY')][CRYSTAL] = 1
    ShopAddItem(id, FourCC('I0CY'), sets + sword + plate)
    ItemAddComponents(FourCC('I0CY'), "I07V I07V I07V I087 I087 I07X")
    --heavy
    ItemPrices[FourCC('I0BQ')] = __jarray(0)
    ItemPrices[FourCC('I0BQ')][GOLD] = 500000
    ItemPrices[FourCC('I0BQ')][PLATINUM] = 1
    ItemPrices[FourCC('I0BQ')][LUMBER] = 750000
    ItemPrices[FourCC('I0BQ')][CRYSTAL] = 1
    ShopAddItem(id, FourCC('I0BQ'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0BQ'), "I089 I089 I089 I07X I07X I087")
    --dagger
    ItemPrices[FourCC('I0BP')] = __jarray(0)
    ItemPrices[FourCC('I0BP')][GOLD] = 500000
    ItemPrices[FourCC('I0BP')][PLATINUM] = 1
    ItemPrices[FourCC('I0BP')][LUMBER] = 750000
    ItemPrices[FourCC('I0BP')][CRYSTAL] = 1
    ShopAddItem(id, FourCC('I0BP'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0BP'), "I07Z I07Z I07Z I083 I083 I083")
    --bow
    ItemPrices[FourCC('I0CZ')] = __jarray(0)
    ItemPrices[FourCC('I0CZ')][GOLD] = 500000
    ItemPrices[FourCC('I0CZ')][PLATINUM] = 1
    ItemPrices[FourCC('I0CZ')][LUMBER] = 750000
    ItemPrices[FourCC('I0CZ')][CRYSTAL] = 1
    ShopAddItem(id, FourCC('I0CZ'), sets + bow + leather)
    ItemAddComponents(FourCC('I0CZ'), "I07R I07R I07R I083 I083 I083")
    --staff
    ItemPrices[FourCC('I0D3')] = __jarray(0)
    ItemPrices[FourCC('I0D3')][GOLD] = 500000
    ItemPrices[FourCC('I0D3')][PLATINUM] = 1
    ItemPrices[FourCC('I0D3')][LUMBER] = 750000
    ItemPrices[FourCC('I0D3')][CRYSTAL] = 1
    ShopAddItem(id, FourCC('I0D3'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0D3'), "I07T I07T I07T I081 I081 I081")

    --abyssal components
    ShopAddItem(id, FourCC('I06A'), sword)
    ShopAddItem(id, FourCC('I06D'), heavy)
    ShopAddItem(id, FourCC('I06B'), dagger)
    ShopAddItem(id, FourCC('I06C'), bow)
    ShopAddItem(id, FourCC('I09N'), staff)
    ShopAddItem(id, FourCC('I09X'), plate)
    ShopAddItem(id, FourCC('I0A0'), fullplate)
    ShopAddItem(id, FourCC('I0A2'), leather)
    ShopAddItem(id, FourCC('I0A5'), cloth)

    --abyssal sets
    --sword
    ItemPrices[FourCC('I0C9')] = __jarray(0)
    ItemPrices[FourCC('I0C9')][PLATINUM] = 3
    ItemPrices[FourCC('I0C9')][ARCADITE] = 1
    ItemPrices[FourCC('I0C9')][LUMBER] = 500000
    ItemPrices[FourCC('I0C9')][CRYSTAL] = 2
    ShopAddItem(id, FourCC('I0C9'), sets + sword + plate)
    ItemAddComponents(FourCC('I0C9'), "I06A I06A I06A I09X I09X I06D")
    --heavy
    ItemPrices[FourCC('I0C8')] = __jarray(0)
    ItemPrices[FourCC('I0C8')][PLATINUM] = 3
    ItemPrices[FourCC('I0C8')][ARCADITE] = 1
    ItemPrices[FourCC('I0C8')][LUMBER] = 500000
    ItemPrices[FourCC('I0C8')][CRYSTAL] = 2
    ShopAddItem(id, FourCC('I0C8'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0C8'), "I0A0 I0A0 I0A0 I06D I06D I09X")
    --dagger
    ItemPrices[FourCC('I0C7')] = __jarray(0)
    ItemPrices[FourCC('I0C7')][PLATINUM] = 3
    ItemPrices[FourCC('I0C7')][ARCADITE] = 1
    ItemPrices[FourCC('I0C7')][LUMBER] = 500000
    ItemPrices[FourCC('I0C7')][CRYSTAL] = 2
    ShopAddItem(id, FourCC('I0C7'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0C7'), "I06B I06B I06B I0A2 I0A2 I0A2")
    --bow
    ItemPrices[FourCC('I0C6')] = __jarray(0)
    ItemPrices[FourCC('I0C6')][PLATINUM] = 3
    ItemPrices[FourCC('I0C6')][ARCADITE] = 1
    ItemPrices[FourCC('I0C6')][LUMBER] = 500000
    ItemPrices[FourCC('I0C6')][CRYSTAL] = 2
    ShopAddItem(id, FourCC('I0C6'), sets + bow + leather)
    ItemAddComponents(FourCC('I0C6'), "I06C I06C I06C I0A2 I0A2 I0A2")
    --staff
    ItemPrices[FourCC('I0C5')] = __jarray(0)
    ItemPrices[FourCC('I0C5')][PLATINUM] = 3
    ItemPrices[FourCC('I0C5')][ARCADITE] = 1
    ItemPrices[FourCC('I0C5')][LUMBER] = 500000
    ItemPrices[FourCC('I0C5')][CRYSTAL] = 2
    ShopAddItem(id, FourCC('I0C5'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0C5'), "I09N I09N I09N I0A5 I0A5 I0A5")

    --void components
    ShopAddItem(id, FourCC('I08C'), sword)
    ShopAddItem(id, FourCC('I08D'), heavy)
    ShopAddItem(id, FourCC('I08J'), dagger)
    ShopAddItem(id, FourCC('I08H'), bow)
    ShopAddItem(id, FourCC('I08G'), staff)
    ShopAddItem(id, FourCC('I08S'), plate)
    ShopAddItem(id, FourCC('I08U'), fullplate)
    ShopAddItem(id, FourCC('I08O'), leather)
    ShopAddItem(id, FourCC('I08M'), cloth)
    ShopAddItem(id, FourCC('I055'), misc)
    ShopAddItem(id, FourCC('I04Y'), misc)
    ShopAddItem(id, FourCC('I08N'), misc)
    ShopAddItem(id, FourCC('I04W'), Shield)

    --void sets
    --sword
    ItemPrices[FourCC('I0D7')] = __jarray(0)
    ItemPrices[FourCC('I0D7')][PLATINUM] = 6
    ItemPrices[FourCC('I0D7')][ARCADITE] = 3
    ItemPrices[FourCC('I0D7')][CRYSTAL] = 3
    ShopAddItem(id, FourCC('I0D7'), sets + sword + plate)
    ItemAddComponents(FourCC('I0D7'), "I08C I08C I08C I08S I08S I08D I055")
    --heavy
    ItemPrices[FourCC('I0C4')] = __jarray(0)
    ItemPrices[FourCC('I0C4')][PLATINUM] = 6
    ItemPrices[FourCC('I0C4')][ARCADITE] = 3
    ItemPrices[FourCC('I0C4')][CRYSTAL] = 3
    ShopAddItem(id, FourCC('I0C4'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0C4'), "I08U I08U I08U I08D I08D I08S I04W")
    --dagger
    ItemPrices[FourCC('I0C3')] = __jarray(0)
    ItemPrices[FourCC('I0C3')][PLATINUM] = 6
    ItemPrices[FourCC('I0C3')][ARCADITE] = 3
    ItemPrices[FourCC('I0C3')][CRYSTAL] = 3
    ShopAddItem(id, FourCC('I0C3'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0C3'), "I08J I08J I08J I08O I08O I08O I055")
    --bow
    ItemPrices[FourCC('I0D5')] = __jarray(0)
    ItemPrices[FourCC('I0D5')][PLATINUM] = 6
    ItemPrices[FourCC('I0D5')][ARCADITE] = 3
    ItemPrices[FourCC('I0D5')][CRYSTAL] = 3
    ShopAddItem(id, FourCC('I0D5'), sets + bow + leather)
    ItemAddComponents(FourCC('I0D5'), "I08H I08H I08H I08O I08O I08O I055")
    --staff
    ItemPrices[FourCC('I0D6')] = __jarray(0)
    ItemPrices[FourCC('I0D6')][PLATINUM] = 6
    ItemPrices[FourCC('I0D6')][ARCADITE] = 3
    ItemPrices[FourCC('I0D6')][CRYSTAL] = 3
    ShopAddItem(id, FourCC('I0D6'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0D6'), "I08G I08G I08G I08M I08M I08M I04Y")

    --nightmare components
    ShopAddItem(id, FourCC('I09P'), sword)
    ShopAddItem(id, FourCC('I09V'), heavy)
    ShopAddItem(id, FourCC('I09R'), dagger)
    ShopAddItem(id, FourCC('I09S'), bow)
    ShopAddItem(id, FourCC('I09T'), staff)
    ShopAddItem(id, FourCC('I0A7'), plate)
    ShopAddItem(id, FourCC('I0A9'), fullplate)
    ShopAddItem(id, FourCC('I0AC'), leather)
    ShopAddItem(id, FourCC('I0AB'), cloth)

    --nightmare sets
    --sword
    ItemPrices[FourCC('I0CB')] = __jarray(0)
    ItemPrices[FourCC('I0CB')][PLATINUM] = 10
    ItemPrices[FourCC('I0CB')][ARCADITE] = 6
    ItemPrices[FourCC('I0CB')][CRYSTAL] = 6
    ShopAddItem(id, FourCC('I0CB'), sets + sword + plate)
    ItemAddComponents(FourCC('I0CB'), "I09P I09P I09P I09P I0A7 I0A7 I09V")
    --heavy
    ItemPrices[FourCC('I0CA')] = __jarray(0)
    ItemPrices[FourCC('I0CA')][PLATINUM] = 10
    ItemPrices[FourCC('I0CA')][ARCADITE] = 6
    ItemPrices[FourCC('I0CA')][CRYSTAL] = 6
    ShopAddItem(id, FourCC('I0CA'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0CA'), "I0A9 I0A9 I0A9 I09V I09V I09V I0A7")
    --dagger
    ItemPrices[FourCC('I0CD')] = __jarray(0)
    ItemPrices[FourCC('I0CD')][PLATINUM] = 10
    ItemPrices[FourCC('I0CD')][ARCADITE] = 6
    ItemPrices[FourCC('I0CD')][CRYSTAL] = 6
    ShopAddItem(id, FourCC('I0CD'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0CD'), "I09R I09R I09R I09R I0AC I0AC I0AC")
    --bow
    ItemPrices[FourCC('I0CE')] = __jarray(0)
    ItemPrices[FourCC('I0CE')][PLATINUM] = 10
    ItemPrices[FourCC('I0CE')][ARCADITE] = 6
    ItemPrices[FourCC('I0CE')][CRYSTAL] = 6
    ShopAddItem(id, FourCC('I0CE'), sets + bow + leather)
    ItemAddComponents(FourCC('I0CE'), "I09S I09S I09S I09S I0AC I0AC I0AC")
    --staff
    ItemPrices[FourCC('I0CF')] = __jarray(0)
    ItemPrices[FourCC('I0CF')][PLATINUM] = 10
    ItemPrices[FourCC('I0CF')][ARCADITE] = 6
    ItemPrices[FourCC('I0CF')][CRYSTAL] = 6
    ShopAddItem(id, FourCC('I0CF'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0CF'), "I09T I09T I09T I09T I0AB I0AB I0AB")

    --hell components
    ShopAddItem(id, FourCC('I05G'), sword)
    ShopAddItem(id, FourCC('I08W'), heavy)
    ShopAddItem(id, FourCC('I08Z'), dagger)
    ShopAddItem(id, FourCC('I091'), bow)
    ShopAddItem(id, FourCC('I093'), staff)
    ShopAddItem(id, FourCC('I097'), plate)
    ShopAddItem(id, FourCC('I098'), leather)
    ShopAddItem(id, FourCC('I05H'), fullplate)
    ShopAddItem(id, FourCC('I095'), cloth)
    ShopAddItem(id, FourCC('I05I'), misc)

    --hell sets
    --sword
    ItemPrices[FourCC('I0D8')] = __jarray(0)
    ItemPrices[FourCC('I0D8')][PLATINUM] = 15
    ItemPrices[FourCC('I0D8')][ARCADITE] = 10
    ItemPrices[FourCC('I0D8')][CRYSTAL] = 10
    ShopAddItem(id, FourCC('I0D8'), sets + sword + plate)
    ItemAddComponents(FourCC('I0D8'), "I05G I05G I05G I097 I097 I08W I05I")
    --heavy
    ItemPrices[FourCC('I0BW')] = __jarray(0)
    ItemPrices[FourCC('I0BW')][PLATINUM] = 15
    ItemPrices[FourCC('I0BW')][ARCADITE] = 10
    ItemPrices[FourCC('I0BW')][CRYSTAL] = 10
    ShopAddItem(id, FourCC('I0BW'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0BW'), "I05H I05H I05H I08W I08W I08W I097")
    --dagger
    ItemPrices[FourCC('I0BU')] = __jarray(0)
    ItemPrices[FourCC('I0BU')][PLATINUM] = 15
    ItemPrices[FourCC('I0BU')][ARCADITE] = 10
    ItemPrices[FourCC('I0BU')][CRYSTAL] = 10
    ShopAddItem(id, FourCC('I0BU'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0BU'), "I08Z I08Z I08Z I098 I098 I098 I05I")
    --bow
    ItemPrices[FourCC('I0DK')] = __jarray(0)
    ItemPrices[FourCC('I0DK')][PLATINUM] = 15
    ItemPrices[FourCC('I0DK')][ARCADITE] = 10
    ItemPrices[FourCC('I0DK')][CRYSTAL] = 10
    ShopAddItem(id, FourCC('I0DK'), sets + bow + leather)
    ItemAddComponents(FourCC('I0DK'), "I091 I091 I091 I098 I098 I098 I05I")
    --staff
    ItemPrices[FourCC('I0DJ')] = __jarray(0)
    ItemPrices[FourCC('I0DJ')][PLATINUM] = 15
    ItemPrices[FourCC('I0DJ')][ARCADITE] = 10
    ItemPrices[FourCC('I0DJ')][CRYSTAL] = 10
    ShopAddItem(id, FourCC('I0DJ'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0DJ'), "I093 I093 I093 I093 I095 I095 I095")

    --existence components
    ShopAddItem(id, FourCC('I09K'), sword)
    ShopAddItem(id, FourCC('I09M'), heavy)
    ShopAddItem(id, FourCC('I09I'), dagger)
    ShopAddItem(id, FourCC('I09G'), bow)
    ShopAddItem(id, FourCC('I09E'), staff)
    ShopAddItem(id, FourCC('I09U'), plate)
    ShopAddItem(id, FourCC('I09W'), fullplate)
    ShopAddItem(id, FourCC('I09Q'), leather)
    ShopAddItem(id, FourCC('I09O'), cloth)

    --existence sets
    --sword
    ItemPrices[FourCC('I0DX')] = __jarray(0)
    ItemPrices[FourCC('I0DX')][PLATINUM] = 25
    ItemPrices[FourCC('I0DX')][ARCADITE] = 15
    ItemPrices[FourCC('I0DX')][CRYSTAL] = 15
    ShopAddItem(id, FourCC('I0DX'), sets + sword + plate)
    ItemAddComponents(FourCC('I0DX'), "I09K I09K I09K I09K I09U I09U I09M")
    --heavy
    ItemPrices[FourCC('I0BT')] = __jarray(0)
    ItemPrices[FourCC('I0BT')][PLATINUM] = 25
    ItemPrices[FourCC('I0BT')][ARCADITE] = 15
    ItemPrices[FourCC('I0BT')][CRYSTAL] = 15
    ShopAddItem(id, FourCC('I0BT'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0BT'), "I09W I09W I09W I09M I09M I09M I09U")
    --dagger
    ItemPrices[FourCC('I0BR')] = __jarray(0)
    ItemPrices[FourCC('I0BR')][PLATINUM] = 25
    ItemPrices[FourCC('I0BR')][ARCADITE] = 15
    ItemPrices[FourCC('I0BR')][CRYSTAL] = 15
    ShopAddItem(id, FourCC('I0BR'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0BR'), "I09I I09I I09I I09I I09Q I09Q I09Q")
    --bow
    ItemPrices[FourCC('I0DL')] = __jarray(0)
    ItemPrices[FourCC('I0DL')][PLATINUM] = 25
    ItemPrices[FourCC('I0DL')][ARCADITE] = 15
    ItemPrices[FourCC('I0DL')][CRYSTAL] = 15
    ShopAddItem(id, FourCC('I0DL'), sets + bow + leather)
    ItemAddComponents(FourCC('I0DL'), "I09G I09G I09G I09G I09Q I09Q I09Q")
    --staff
    ItemPrices[FourCC('I0DY')] = __jarray(0)
    ItemPrices[FourCC('I0DY')][PLATINUM] = 25
    ItemPrices[FourCC('I0DY')][ARCADITE] = 15
    ItemPrices[FourCC('I0DY')][CRYSTAL] = 15
    ShopAddItem(id, FourCC('I0DY'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0DY'), "I09E I09E I09E I09E I09O I09O I09O")

    --astral components
    ShopAddItem(id, FourCC('I0A3'), sword)
    ShopAddItem(id, FourCC('I0A6'), heavy)
    ShopAddItem(id, FourCC('I0A1'), dagger)
    ShopAddItem(id, FourCC('I0A4'), bow)
    ShopAddItem(id, FourCC('I09Z'), staff)
    ShopAddItem(id, FourCC('I0AL'), plate)
    ShopAddItem(id, FourCC('I0AN'), fullplate)
    ShopAddItem(id, FourCC('I0AA'), leather)
    ShopAddItem(id, FourCC('I0A8'), cloth)

    --astral sets
    --sword
    ItemPrices[FourCC('I0E0')] = __jarray(0)
    ItemPrices[FourCC('I0E0')][PLATINUM] = 45
    ItemPrices[FourCC('I0E0')][ARCADITE] = 30
    ItemPrices[FourCC('I0E0')][CRYSTAL] = 30
    ShopAddItem(id, FourCC('I0E0'), sets + sword + plate)
    ItemAddComponents(FourCC('I0E0'), "I0A3 I0A3 I0A3 I0A3 I0AL I0AL I0A6")
    --heavy
    ItemPrices[FourCC('I0BM')] = __jarray(0)
    ItemPrices[FourCC('I0BM')][PLATINUM] = 45
    ItemPrices[FourCC('I0BM')][ARCADITE] = 30
    ItemPrices[FourCC('I0BM')][CRYSTAL] = 30
    ShopAddItem(id, FourCC('I0BM'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0BM'), "I0AN I0AN I0AN I0A6 I0A6 I0A6 I0AL")
    --dagger
    ItemPrices[FourCC('I0DZ')] = __jarray(0)
    ItemPrices[FourCC('I0DZ')][PLATINUM] = 45
    ItemPrices[FourCC('I0DZ')][ARCADITE] = 30
    ItemPrices[FourCC('I0DZ')][CRYSTAL] = 30
    ShopAddItem(id, FourCC('I0DZ'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0DZ'), "I0A1 I0A1 I0A1 I0A1 I0AA I0AA I0AA")
    --bow
    ItemPrices[FourCC('I059')] = __jarray(0)
    ItemPrices[FourCC('I059')][PLATINUM] = 45
    ItemPrices[FourCC('I059')][ARCADITE] = 30
    ItemPrices[FourCC('I059')][CRYSTAL] = 30
    ShopAddItem(id, FourCC('I059'), sets + bow + leather)
    ItemAddComponents(FourCC('I059'), "I0A4 I0A4 I0A4 I0A4 I0AA I0AA I0AA")
    --staff
    ItemPrices[FourCC('I0E1')] = __jarray(0)
    ItemPrices[FourCC('I0E1')][PLATINUM] = 45
    ItemPrices[FourCC('I0E1')][ARCADITE] = 30
    ItemPrices[FourCC('I0E1')][CRYSTAL] = 30
    ShopAddItem(id, FourCC('I0E1'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0E1'), "I09Z I09Z I09Z I09Z I0A8 I0A8 I0A8")

    --dimensional components
    ShopAddItem(id, FourCC('I0AO'), sword)
    ShopAddItem(id, FourCC('I0AQ'), heavy)
    ShopAddItem(id, FourCC('I0AT'), dagger)
    ShopAddItem(id, FourCC('I0AR'), bow)
    ShopAddItem(id, FourCC('I0AW'), staff)
    ShopAddItem(id, FourCC('I0AY'), plate)
    ShopAddItem(id, FourCC('I0B0'), fullplate)
    ShopAddItem(id, FourCC('I0B2'), leather)
    ShopAddItem(id, FourCC('I0B3'), cloth)

    --dimensional sets
    --sword
    ItemPrices[FourCC('I0CG')] = __jarray(0)
    ItemPrices[FourCC('I0CG')][PLATINUM] = 80
    ItemPrices[FourCC('I0CG')][ARCADITE] = 55
    ItemPrices[FourCC('I0CG')][CRYSTAL] = 55
    ShopAddItem(id, FourCC('I0CG'), sets + sword + plate)
    ItemAddComponents(FourCC('I0CG'), "I0AO I0AO I0AO I0AO I0AY I0AY I0AQ")
    --heavy
    ItemPrices[FourCC('I0FH')] = __jarray(0)
    ItemPrices[FourCC('I0FH')][PLATINUM] = 80
    ItemPrices[FourCC('I0FH')][ARCADITE] = 55
    ItemPrices[FourCC('I0FH')][CRYSTAL] = 55
    ShopAddItem(id, FourCC('I0FH'), sets + heavy + fullplate)
    ItemAddComponents(FourCC('I0FH'), "I0B0 I0B0 I0B0 I0AQ I0AQ I0AQ I0AY")
    --dagger
    ItemPrices[FourCC('I0CI')] = __jarray(0)
    ItemPrices[FourCC('I0CI')][PLATINUM] = 80
    ItemPrices[FourCC('I0CI')][ARCADITE] = 55
    ItemPrices[FourCC('I0CI')][CRYSTAL] = 55
    ShopAddItem(id, FourCC('I0CI'), sets + dagger + leather)
    ItemAddComponents(FourCC('I0CI'), "I0AT I0AT I0AT I0AT I0B2 I0B2 I0B2")
    --bow
    ItemPrices[FourCC('I0FI')] = __jarray(0)
    ItemPrices[FourCC('I0FI')][PLATINUM] = 80
    ItemPrices[FourCC('I0FI')][ARCADITE] = 55
    ItemPrices[FourCC('I0FI')][CRYSTAL] = 55
    ShopAddItem(id, FourCC('I0FI'), sets + bow + leather)
    ItemAddComponents(FourCC('I0FI'), "I0AR I0AR I0AR I0AR I0B2 I0B2 I0B2")
    --staff
    ItemPrices[FourCC('I0FZ')] = __jarray(0)
    ItemPrices[FourCC('I0FZ')][PLATINUM] = 80
    ItemPrices[FourCC('I0FZ')][ARCADITE] = 55
    ItemPrices[FourCC('I0FZ')][CRYSTAL] = 55
    ShopAddItem(id, FourCC('I0FZ'), sets + staff + cloth)
    ItemAddComponents(FourCC('I0FZ'), "I0AW I0AW I0AW I0AW I0B3 I0B3 I0B3")
    --cheese shield
    --call ShopAddItem(id2, FourCC('I01Y'), misc)
    ItemPrices[FourCC('I038')] = __jarray(0)
    ItemPrices[FourCC('I038')][GOLD] = 100
    ShopAddItem(id2, FourCC('I038'), misc)
    ItemAddComponents(FourCC('I038'), "I01Y")

    --hydra weapons
    ItemPrices[FourCC('I02N')] = __jarray(0)
    ItemPrices[FourCC('I02N')][GOLD] = 5000
    ItemPrices[FourCC('I072')] = __jarray(0)
    ItemPrices[FourCC('I072')][GOLD] = 5000
    ItemPrices[FourCC('I06Y')] = __jarray(0)
    ItemPrices[FourCC('I06Y')][GOLD] = 5000
    ItemPrices[FourCC('I070')] = __jarray(0)
    ItemPrices[FourCC('I070')][GOLD] = 5000
    ItemPrices[FourCC('I071')] = __jarray(0)
    ItemPrices[FourCC('I071')][GOLD] = 5000
    ShopAddItem(id2, FourCC('I02N'), sword)
    ShopAddItem(id2, FourCC('I072'), heavy)
    ShopAddItem(id2, FourCC('I06Y'), dagger)
    ShopAddItem(id2, FourCC('I070'), bow)
    ShopAddItem(id2, FourCC('I071'), staff)

    ItemAddComponents(FourCC('I02N'), "I07N")
    ItemAddComponents(FourCC('I072'), "I07N")
    ItemAddComponents(FourCC('I06Y'), "I07N")
    ItemAddComponents(FourCC('I070'), "I07N")
    ItemAddComponents(FourCC('I071'), "I07N")

    --iron golem fist
    --call ShopAddItem(id2, FourCC('I02Q'), misc)

    ItemPrices[FourCC('I046')] = __jarray(0)
    ItemPrices[FourCC('I046')][GOLD] = 75000
    ShopAddItem(id2, FourCC('I046'), misc)
    ItemAddComponents(FourCC('I046'), "I02Q I02Q I02Q I02Q I02Q I02Q")

    --dragon armor
    ItemPrices[FourCC('I048')] = __jarray(0)
    ItemPrices[FourCC('I048')][GOLD] = 10000
    ItemPrices[FourCC('I02U')] = __jarray(0)
    ItemPrices[FourCC('I02U')][GOLD] = 10000
    ItemPrices[FourCC('I064')] = __jarray(0)
    ItemPrices[FourCC('I064')][GOLD] = 10000
    ItemPrices[FourCC('I02P')] = __jarray(0)
    ItemPrices[FourCC('I02P')][GOLD] = 10000
    ShopAddItem(id2, FourCC('I048'), plate)
    ShopAddItem(id2, FourCC('I02U'), fullplate)
    ShopAddItem(id2, FourCC('I064'), leather)
    ShopAddItem(id2, FourCC('I02P'), cloth)

    ItemAddComponents(FourCC('I048'), "I05Z I05Z I056")
    ItemAddComponents(FourCC('I02U'), "I05Z I05Z I056")
    ItemAddComponents(FourCC('I064'), "I05Z I05Z I056")
    ItemAddComponents(FourCC('I02P'), "I05Z I05Z I056")

    --dragon weapons
    ItemPrices[FourCC('I033')] = __jarray(0)
    ItemPrices[FourCC('I033')][GOLD] = 10000
    ItemPrices[FourCC('I0BZ')] = __jarray(0)
    ItemPrices[FourCC('I0BZ')][GOLD] = 10000
    ItemPrices[FourCC('I02S')] = __jarray(0)
    ItemPrices[FourCC('I02S')][GOLD] = 10000
    ItemPrices[FourCC('I032')] = __jarray(0)
    ItemPrices[FourCC('I032')][GOLD] = 10000
    ItemPrices[FourCC('I065')] = __jarray(0)
    ItemPrices[FourCC('I065')][GOLD] = 10000
    ShopAddItem(id2, FourCC('I033'), sword)
    ShopAddItem(id2, FourCC('I0BZ'), heavy)
    ShopAddItem(id2, FourCC('I02S'), dagger)
    ShopAddItem(id2, FourCC('I032'), bow)
    ShopAddItem(id2, FourCC('I065'), staff)

    ItemAddComponents(FourCC('I033'), "I04X I04X I056")
    ItemAddComponents(FourCC('I0BZ'), "I04X I04X I056")
    ItemAddComponents(FourCC('I02S'), "I04X I04X I056")
    ItemAddComponents(FourCC('I032'), "I04X I04X I056")
    ItemAddComponents(FourCC('I065'), "I04X I04X I056")

    --bloody armor
    --call ShopAddItem(id2, FourCC('I04Q'), plate)

    ItemPrices[FourCC('I0N4')] = __jarray(0)
    ItemPrices[FourCC('I0N4')][CRYSTAL] = 1
    ItemPrices[FourCC('I00X')] = __jarray(0)
    ItemPrices[FourCC('I00X')][CRYSTAL] = 1
    ItemPrices[FourCC('I0N5')] = __jarray(0)
    ItemPrices[FourCC('I0N5')][CRYSTAL] = 1
    ItemPrices[FourCC('I0N6')] = __jarray(0)
    ItemPrices[FourCC('I0N6')][CRYSTAL] = 1
    ShopAddItem(id2, FourCC('I0N4'), plate)
    ShopAddItem(id2, FourCC('I00X'), fullplate)
    ShopAddItem(id2, FourCC('I0N5'), leather)
    ShopAddItem(id2, FourCC('I0N6'), cloth)

    ItemAddComponents(FourCC('I0N4'), "I04Q")
    ItemAddComponents(FourCC('I00X'), "I04Q")
    ItemAddComponents(FourCC('I0N5'), "I04Q")
    ItemAddComponents(FourCC('I0N6'), "I04Q")

    --bloody weapons
    ItemPrices[FourCC('I03F')] = __jarray(0)
    ItemPrices[FourCC('I03F')][CRYSTAL] = 1
    ItemPrices[FourCC('I04S')] = __jarray(0)
    ItemPrices[FourCC('I04S')][CRYSTAL] = 1
    ItemPrices[FourCC('I020')] = __jarray(0)
    ItemPrices[FourCC('I020')][CRYSTAL] = 1
    ItemPrices[FourCC('I016')] = __jarray(0)
    ItemPrices[FourCC('I016')][CRYSTAL] = 1
    ItemPrices[FourCC('I0AK')] = __jarray(0)
    ItemPrices[FourCC('I0AK')][CRYSTAL] = 1
    ShopAddItem(id2, FourCC('I03F'), sword)
    ShopAddItem(id2, FourCC('I04S'), heavy)
    ShopAddItem(id2, FourCC('I020'), dagger)
    ShopAddItem(id2, FourCC('I016'), bow)
    ShopAddItem(id2, FourCC('I0AK'), staff)

    ItemAddComponents(FourCC('I03F'), "I04Q")
    ItemAddComponents(FourCC('I04S'), "I04Q")
    ItemAddComponents(FourCC('I020'), "I04Q")
    ItemAddComponents(FourCC('I016'), "I04Q")
    ItemAddComponents(FourCC('I0AK'), "I04Q")

    --chaotic necklace
    --call ShopAddItem(id2, FourCC('I04Z'), misc)

    ItemPrices[FourCC('I050')] = __jarray(0)
    ItemPrices[FourCC('I050')][PLATINUM] = 10
    ItemPrices[FourCC('I050')] = __jarray(0)
    ItemPrices[FourCC('I050')][CRYSTAL] = 10
    ShopAddItem(id2, FourCC('I050'), misc)
    ItemAddComponents(FourCC('I050'), "I04Z I04Z I04Z I04Z I04Z I04Z")
end

---@return boolean
function ShopkeeperClick()
    local track           = GetTriggeringTrackable() ---@type trackable 
    local pid         = LoadInteger(MiscHash, GetHandleId(track), FourCC('evil')) ---@type integer 

    if selectingHero[pid] == false then
        if GetLocalPlayer() == Player(pid - 1) then
            ClearSelection()
            SelectUnit(gg_unit_n02S_0098, true)
        end
    end

    return false
end

    --ice troll trapper
    local id = FourCC('nitt')
    UnitData[0] = {}
    UnitData[1] = {}
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 18
    UnitData[id][UNITDATA_SPAWN] = 1
    UnitData[0][0] = id
    --ice troll berserker
    id = FourCC('nits')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 10
    UnitData[id][UNITDATA_SPAWN] = 1
    UnitData[0][1] = id
    --tuskarr sorc
    id = FourCC('ntks')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 10
    UnitData[id][UNITDATA_SPAWN] = 2
    UnitData[0][2] = id
    --tuskarr warrior
    id = FourCC('ntkw')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 11
    UnitData[id][UNITDATA_SPAWN] = 2
    UnitData[0][3] = id
    --tuskarr chieftain
    id = FourCC('ntkc')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 9
    UnitData[id][UNITDATA_SPAWN] = 2
    UnitData[0][4] = id
    --nerubian Seer
    id = FourCC('nnwr')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 18
    UnitData[id][UNITDATA_SPAWN] = 3
    UnitData[0][5] = id
    --nerubian spider lord
    id = FourCC('nnws')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 18
    UnitData[id][UNITDATA_SPAWN] = 3
    UnitData[0][6] = id
    --polar furbolg warrior 
    id = FourCC('nfpu')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 38
    UnitData[id][UNITDATA_SPAWN] = 4
    UnitData[0][7] = id
    --polar furbolg elder shaman
    id = FourCC('nfpe')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 22
    UnitData[id][UNITDATA_SPAWN] = 4
    UnitData[0][8] = id
    --giant polar bear
    id = FourCC('nplg')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 20
    UnitData[id][UNITDATA_SPAWN] = 5
    UnitData[0][9] = id
    --dire mammoth
    id = FourCC('nmdr')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 16
    UnitData[id][UNITDATA_SPAWN] = 5
    UnitData[0][10] = id
    --ogre overlord
    id = FourCC('n01G')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 55
    UnitData[id][UNITDATA_SPAWN] = 6
    UnitData[0][11] = id
    --tauren
    id = FourCC('o01G')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 40
    UnitData[id][UNITDATA_SPAWN] = 6
    UnitData[0][12] = id
    --unbroken deathbringer
    id = FourCC('nfod')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 18
    UnitData[id][UNITDATA_SPAWN] = 7
    UnitData[0][13] = id
    --unbroken trickster
    id = FourCC('nfor')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 15
    UnitData[id][UNITDATA_SPAWN] = 7
    UnitData[0][14] = id
    --unbroken darkweaver
    id = FourCC('nubw')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 12
    UnitData[id][UNITDATA_SPAWN] = 7
    UnitData[0][15] = id
    --lesser hellfire
    id = FourCC('nvdl')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 25
    UnitData[id][UNITDATA_SPAWN] = 8
    UnitData[0][16] = id
    --lesser hellhound
    id = FourCC('nvdw')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 30
    UnitData[id][UNITDATA_SPAWN] = 8
    UnitData[0][17] = id
    --centaur lancer
    id = FourCC('n027')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 25
    UnitData[id][UNITDATA_SPAWN] = 9
    UnitData[0][18] = id
    --centaur ranger
    id = FourCC('n024')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 20
    UnitData[id][UNITDATA_SPAWN] = 9
    UnitData[0][19] = id
    --centaur mage
    id = FourCC('n028')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 15
    UnitData[id][UNITDATA_SPAWN] = 9
    UnitData[0][20] = id
    --magnataur destroyer
    id = FourCC('n01M')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 45
    UnitData[id][UNITDATA_SPAWN] = 10
    UnitData[0][21] = id
    --forgotten one
    id = FourCC('n08M')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 20
    UnitData[id][UNITDATA_SPAWN] = 10
    UnitData[0][22] = id
    --ancient hydra
    id = FourCC('n01H')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 4
    UnitData[id][UNITDATA_SPAWN] = 11
    UnitData[0][23] = id
    --frost dragon
    id = FourCC('n02P')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 18
    UnitData[id][UNITDATA_SPAWN] = 12
    UnitData[0][24] = id
    --frost drake
    id = FourCC('n01R')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 18
    UnitData[id][UNITDATA_SPAWN] = 12
    UnitData[0][25] = id
    --frost elder
    id = FourCC('n099')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 1
    UnitData[id][UNITDATA_SPAWN] = 14
    UnitData[0][26] = id
    --medean berserker
    id = FourCC('n00C')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 7
    UnitData[id][UNITDATA_SPAWN] = 13
    UnitData[0][27] = id
    --medean devourer
    id = FourCC('n02L')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 15
    UnitData[id][UNITDATA_SPAWN] = 13
    UnitData[0][28] = id

    --demon
    id = FourCC('n033')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 20
    UnitData[id][UNITDATA_SPAWN] = 1
    UnitData[1][0] = id
    --demon wizard
    id = FourCC('n034')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 11
    UnitData[id][UNITDATA_SPAWN] = 1
    UnitData[1][1] = id
    --horror young
    id = FourCC('n03C')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 24
    UnitData[id][UNITDATA_SPAWN] = 15
    UnitData[1][2] = id
    --horror mindless
    id = FourCC('n03A')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 46
    UnitData[id][UNITDATA_SPAWN] = 15
    UnitData[1][3] = id
    --horror leader
    id = FourCC('n03B')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 11
    UnitData[id][UNITDATA_SPAWN] = 15
    UnitData[1][4] = id
    --despair
    id = FourCC('n03F')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 62
    UnitData[id][UNITDATA_SPAWN] = 18
    UnitData[1][5] = id
    --despair wizard
    id = FourCC('n01W')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 30
    UnitData[id][UNITDATA_SPAWN] = 18
    UnitData[1][6] = id
    --abyssal beast
    id = FourCC('n00X')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 19
    UnitData[id][UNITDATA_SPAWN] = 16
    UnitData[1][7] = id
    --abyssal guardian
    id = FourCC('n08N')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 34
    UnitData[id][UNITDATA_SPAWN] = 16
    UnitData[1][8] = id
    --abyssal spirit
    id = FourCC('n00W')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 34
    UnitData[id][UNITDATA_SPAWN] = 16
    UnitData[1][9] = id
    --void seeker
    id = FourCC('n030')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 30
    UnitData[id][UNITDATA_SPAWN] = 17
    UnitData[1][10] = id
    --void keeper
    id = FourCC('n031')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 40
    UnitData[id][UNITDATA_SPAWN] = 17
    UnitData[1][11] = id
    --void mother
    id = FourCC('n02Z')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 40
    UnitData[id][UNITDATA_SPAWN] = 17
    UnitData[1][12] = id
    --nightmare creature
    id = FourCC('n020')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 22
    UnitData[id][UNITDATA_SPAWN] = 9
    UnitData[1][13] = id
    --nightmare spirit
    id = FourCC('n02J')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 18
    UnitData[id][UNITDATA_SPAWN] = 9
    UnitData[1][14] = id
    --spawn of hell
    id = FourCC('n03E')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 18
    UnitData[id][UNITDATA_SPAWN] = 8
    UnitData[1][15] = id
    --death dealer
    id = FourCC('n03D')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 16
    UnitData[id][UNITDATA_SPAWN] = 8
    UnitData[1][16] = id
    --lord of plague
    id = FourCC('n03G')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 6
    UnitData[id][UNITDATA_SPAWN] = 8
    UnitData[1][17] = id
    --denied existence
    id = FourCC('n03J')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 24
    UnitData[id][UNITDATA_SPAWN] = 13
    UnitData[1][18] = id
    --deprived existence
    id = FourCC('n01X')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 13
    UnitData[id][UNITDATA_SPAWN] = 13
    UnitData[1][19] = id
    --astral being
    id = FourCC('n03M')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 24
    UnitData[id][UNITDATA_SPAWN] = 12
    UnitData[1][20] = id
    --astral entity
    id = FourCC('n01V')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 13
    UnitData[id][UNITDATA_SPAWN] = 12
    UnitData[1][21] = id
    --dimensional planewalker
    id = FourCC('n026')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 22
    UnitData[id][UNITDATA_SPAWN] = 7
    UnitData[1][22] = id
    --dimensional planeshifter
    id = FourCC('n03T')
    UnitData[id] = {}
    UnitData[id][UNITDATA_COUNT] = 18
    UnitData[id][UNITDATA_SPAWN] = 7
    UnitData[1][23] = id

    --forgotten units
    forgottenTypes[0] = FourCC('o030') --corpse basher
    forgottenTypes[1] = FourCC('o033') --destroyer
    forgottenTypes[2] = FourCC('o036') --spirit
    forgottenTypes[3] = FourCC('o02W') --warrior
    forgottenTypes[4] = FourCC('o02Y') --monster

    local sid         = 0 ---@type integer 
    local x      = 0. ---@type number 
    local y      = 0. ---@type number 
    local s        = "" ---@type string 
    local target ---@type unit 
    local track ---@type trackable 

    --angel
    god_angel = gg_unit_n0A1_0164
    ShowUnit(god_angel, false)

    --punching bags
    PunchingBag = {}
    PunchingBag[1] = gg_unit_h02D_0672
    PunchingBag[2] = gg_unit_h02E_0674

    --quest marker effect
    TalkToMe13 = AddSpecialEffectTarget("Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl",god_angel,"overhead")
    TalkToMe20 = AddSpecialEffectTarget("Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl",gg_unit_n02Q_0382,"overhead")

    --zeknen
    PauseUnit(gg_unit_O01A_0372, true)
    UnitAddAbility(gg_unit_O01A_0372, FourCC('Avul'))

    --sponsor
    BlzSetUnitMaxHP(gg_unit_H01Y_0099, 1)
    BlzSetUnitMaxMana(gg_unit_H01Y_0099, 0)
    --paladin
    BlzSetUnitMaxMana(gg_unit_H01T_0259, 0)

    --colo banners
    target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h00G'), 0, 0, 180.00)
    x = GetRectCenterX(gg_rct_ColoBanner1)
    y = GetRectCenterY(gg_rct_ColoBanner1)
    SetUnitPathing(target, false)
    SetUnitPosition(target, x, y)
    target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h00G'), 0, 0, 0)
    x = GetRectCenterX(gg_rct_ColoBanner2)
    y = GetRectCenterY(gg_rct_ColoBanner2)
    SetUnitPathing(target, false)
    SetUnitPosition(target, x, y)
    target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h00G'), 0, 0, 180.00)
    x = GetRectCenterX(gg_rct_ColoBanner3)
    y = GetRectCenterY(gg_rct_ColoBanner3)
    SetUnitPathing(target, false)
    SetUnitPosition(target, x, y)
    target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h00G'), 0, 0, 0)
    x = GetRectCenterX(gg_rct_ColoBanner4)
    y = GetRectCenterY(gg_rct_ColoBanner4)
    SetUnitPathing(target, false)
    SetUnitPosition(target, x, y)

    --special prechaos "bosses"
    --pinky
    UnitAddItem(gg_unit_O019_0375, Item.create(CreateItem(FourCC('I02Y'), 30000., 30000.)).obj)
    --bryan
    UnitAddItem(gg_unit_H043_0566, Item.create(CreateItem(FourCC('I02X'), 30000., 30000.)).obj)
    --ice troll
    UnitAddItem(gg_unit_O00T_0089, Item.create(CreateItem(FourCC('I03Z'), 30000., 30000.)).obj)
    --kroresh
    UnitAddItem(gg_unit_N01N_0050, Item.create(CreateItem(FourCC('I0BZ'), 30000., 30000.)).obj)
    UnitAddItem(gg_unit_N01N_0050, Item.create(CreateItem(FourCC('I064'), 30000., 30000.)).obj)
    UnitAddItem(gg_unit_N01N_0050, Item.create(CreateItem(FourCC('I04B'), 30000., 30000.)).obj)
    --forest corruption
    UnitAddItem(gg_unit_N00M_0495, Item.create(CreateItem(FourCC('I03X'), 30000., 30000.)).obj)
    UnitAddItem(gg_unit_N00M_0495, Item.create(CreateItem(FourCC('I03Y'), 30000., 30000.)).obj)
    --zeknen
    UnitAddItem(gg_unit_O01A_0372, Item.create(CreateItem(FourCC('I03Y'), 30000., 30000.)).obj)

    --prechaos bosses
    BossLoc[0] = Location(-11692., -12774.)
    BossFacing[0] = 45.
    BossID[0] = FourCC('O002')
    BossName[0] = "Minotaur"
    BossLevel[0] = 75
    BossItemType[0] = FourCC('I03T')
    BossItemType[1] = FourCC('I0FW')
    BossItemType[2] = FourCC('I078')
    BossItemType[3] = FourCC('I076')
    BossItemType[4] = FourCC('I07U')
    BossLeash[0] = 2000.

    BossLoc[1] = Location(-15435., -14354.)
    BossFacing[1] = 270.
    BossID[1] = FourCC('H045')
    BossName[1] = "Forgotten Mystic"
    BossLevel[1] = 100
    BossItemType[6] = FourCC('I03U')
    BossItemType[7] = FourCC('I07F')
    BossItemType[8] = FourCC('I0F3')
    BossItemType[9] = FourCC('I03Y')
    BossItemType[10] = 0
    BossItemType[11] = 0
    BossLeash[1] = 2000.

    BossLoc[2] = GetRectCenter(gg_rct_Hell_Boss_Spawn)
    BossFacing[2] = 315.
    BossID[2] = FourCC('U00G')
    BossName[2] = "Hellfire Magi"
    BossLevel[2] = 100
    BossItemType[12] = FourCC('I03Y')
    BossItemType[13] = FourCC('I0FA')
    BossItemType[14] = FourCC('I0FU')
    BossItemType[15] = FourCC('I00V')
    BossLeash[2] = 2000.

    BossLoc[3] = Location(11520., 15466.)
    BossFacing[3] = 225.
    BossID[3] = FourCC('H01V')
    BossName[3] = "Last Dwarf"
    BossLevel[3] = 100
    BossItemType[18] = FourCC('I0FC')
    BossItemType[19] = FourCC('I079')
    BossItemType[20] = FourCC('I03Y')
    BossItemType[21] = FourCC('I07B')
    BossLeash[3] = 2000.

    BossLoc[4] = GetRectCenter(gg_rct_Dark_Soul_Boss_Spawn)
    BossFacing[4] = 270.
    BossID[4] = FourCC('H02H')
    BossName[4] = "Vengeful Test Paladin"
    BossLevel[4] = 140
    BossItemType[24] = FourCC('I03P')
    BossItemType[25] = FourCC('I0FX')
    BossItemType[26] = FourCC('I0F9')
    BossItemType[27] = FourCC('I0C0')
    BossItemType[28] = FourCC('I03Y')
    BossItemType[29] = 0
    BossLeash[4] = 2000.

    BossLoc[5] = GetRectCenter(gg_rct_Thanatos_Boss_Spawn)
    BossFacing[5] = 320.
    BossID[5] = FourCC('O01B')
    BossName[5] = "Dragoon"
    BossLevel[5] = 100
    BossItemType[30] = FourCC('I0EY')
    BossItemType[31] = FourCC('I074')
    BossItemType[32] = FourCC('I04N')
    BossItemType[33] = FourCC('I0EX')
    BossItemType[34] = FourCC('I046')
    BossItemType[35] = FourCC('I03Y')
    BossLeash[5] = 2000.

    BossLoc[6] = Location(6932., -14177.)
    BossFacing[6] = 0.
    BossID[6] = FourCC('H040')
    BossName[6] = "Death Knight"
    BossLevel[6] = 120
    BossItemType[36] = FourCC('I02B')
    BossItemType[37] = FourCC('I029')
    BossItemType[38] = FourCC('I02C')
    BossItemType[39] = FourCC('I02O')
    BossLeash[6] = 2000.

    BossLoc[7] = Location(-12375., -1181.)
    BossFacing[7] = 0.
    BossID[7] = FourCC('H020')
    BossName[7] = "Siren of the Tides"
    BossLevel[7] = 75
    BossItemType[42] = FourCC('I09L')
    BossItemType[43] = FourCC('I09F')
    BossItemType[44] = FourCC('I03Y')
    BossLeash[7] = 2000.

    BossLoc[8] = Location(15816., 6250.)
    BossFacing[8] = 180.
    BossID[8] = FourCC('n02H')
    BossName[8] = "Super Fun Happy Yeti"
    BossLeash[8] = 2000.

    BossLoc[9] = Location(-5242., -15630.)
    BossFacing[9] = 135.
    BossID[9] = FourCC('n03L')
    BossName[9] = "King of Ogres"
    BossLeash[9] = 2000.

    BossLoc[10] = GetRectCenter(gg_rct_Demon_Prince_Boss_Spawn)
    BossFacing[10] = 315.
    BossID[10] = FourCC('n02U')
    BossName[10] = "Nerubian Empress"
    BossLeash[10] = 2000.

    BossLoc[11] = Location(-16040., 6579.)
    BossFacing[11] = 45.
    BossID[11] = FourCC('nplb')
    BossName[11] = "Giant Polar Bear"
    BossLeash[11] = 2000.

    BossLoc[12] = Location(-1840., -27400.)
    BossFacing[12] = 230.
    BossID[12] = FourCC('H04Q')
    BossName[12] = "The Goddesses"
    BossLevel[12] = 180
    BossItemType[72] = FourCC('I04I')
    BossItemType[73] = FourCC('I030')
    BossItemType[74] = FourCC('I031')
    BossItemType[75] = FourCC('I02Z')
    BossItemType[76] = FourCC('I03Y')
    BossLeash[12] = 2000.

    BossLoc[13] = Location(-1977., -27116.) --hate
    BossFacing[13] = 230.
    BossID[13] = FourCC('E00B')
    BossLevel[13] = 180
    BossItemType[78] = FourCC('I02Z')
    BossItemType[79] = FourCC('I03Y')
    BossItemType[80] = FourCC('I02B')
    BossLeash[13] = 2000.

    BossLoc[14] = Location(-1560., -27486.) --love
    BossFacing[14] = 230.
    BossID[14] = FourCC('E00D')
    BossLevel[14] = 180
    BossItemType[84] = FourCC('I030')
    BossItemType[85] = FourCC('I03Y')
    BossItemType[86] = FourCC('I0EY')
    BossLeash[14] = 2000.

    BossLoc[15] = Location(-1689., -27210.) --knowledge
    BossFacing[15] = 230.
    BossID[15] = FourCC('E00C')
    BossLevel[15] = 180
    BossItemType[90] = FourCC('I031')
    BossItemType[91] = FourCC('I03Y')
    BossItemType[92] = FourCC('I03U')
    BossLeash[15] = 2000.

    BossLoc[16] = Location(-1413., -15846.) --arkaden
    BossFacing[16] = 90.
    BossID[16] = FourCC('H00O')
    BossName[16] = "Arkaden"
    BossLevel[16] = 140
    BossItemType[96] = FourCC('I02B')
    BossItemType[97] = FourCC('I02C')
    BossItemType[98] = FourCC('I02O')
    BossItemType[99] = FourCC('I03Y')
    BossItemType[100] = FourCC('I036')
    BossItemType[101] = 0
    BossLeash[16] = 2000.

    for i = 0, BOSS_TOTAL do
        Boss[i] = CreateUnitAtLoc(pboss, BossID[i], BossLoc[i], BossFacing[i])
        SetHeroLevel(Boss[i], BossLevel[i], false)
        local j = 0
        while not (BossItemType[i * 6 + j] == 0 or j > 5) do
            UnitAddItem(Boss[i], Item.create(CreateItem(BossItemType[i * 6 + j], 30000., 30000.)).obj)
            j = j + 1
        end
    end

    --start death march cd
    BlzStartUnitAbilityCooldown(Boss[BOSS_DEATH_KNIGHT], FourCC('A0AU'), 2040. - (User.AmountPlaying * 240))

    ShowUnit(Boss[BOSS_LIFE], false) --gods
    ShowUnit(Boss[BOSS_LOVE], false)
    ShowUnit(Boss[BOSS_HATE], false)
    ShowUnit(Boss[BOSS_KNOWLEDGE], false)

    --shopkeeper
    for i = 0, PLAYER_CAP - 1 do
        s = "war3mapImported\\dummy.mdl"

        if GetLocalPlayer() == Player(i) then
            s = "units\\undead\\Acolyte\\Acolyte.mdl"
        end

        track = CreateTrackable(s, GetUnitX(gg_unit_n02S_0098), GetUnitY(gg_unit_n02S_0098), 3 * bj_PI / 4.)
        SaveInteger(MiscHash, GetHandleId(track), FourCC('evil'), i + 1)
        TriggerRegisterTrackableHitEvent(ShopkeeperTrackable, track)
    end

    TriggerAddCondition(ShopkeeperTrackable, Condition(ShopkeeperClick))

    --hero circle
    HeroCircle[0] = {
        unit = gg_unit_H02A_0568, --oblivion guard
        skin = FourCC('H02A'),
        select = FourCC('A07S'),
        passive = FourCC('A0HQ')
    }
    HeroCircle[1] = {
        unit = gg_unit_H03N_0612, --bloodzerker
        skin = FourCC('H03N'),
        select = FourCC('A07T'),
        passive = FourCC('A06N')
    }
    HeroCircle[2] = {
        unit = gg_unit_H04Z_0604, --royal guardian
        skin = FourCC('H04Z'),
        select = FourCC('A07U'),
        passive = FourCC('A0I5')
    }
    HeroCircle[3] = {
        unit = gg_unit_H012_0605, --warrior
        skin = FourCC('H012'),
        select = FourCC('A07V'),
        passive = FourCC('A0IE')
    }
    HeroCircle[4] = {
        unit = gg_unit_U003_0081, --vampire
        skin = FourCC('U003'),
        select = FourCC('A029'),
        passive = FourCC('A05E')
    }
    HeroCircle[5] = {
        unit = gg_unit_H01N_0606, --savior
        skin = FourCC('H01N'),
        select = FourCC('A07W'),
        passive = FourCC('A0HW')
    }
    HeroCircle[6] = {
        unit = gg_unit_H01S_0607, --dark savior
        skin = FourCC('H01S'),
        select = FourCC('A07Z'),
        passive = FourCC('A0DL')
    }
    HeroCircle[7] = {
        unit = gg_unit_H05B_0608, --Crusader
        skin = FourCC('H05B'),
        select = FourCC('A080'),
        passive = FourCC('A0I4')
    }
    HeroCircle[8] = {
        unit = gg_unit_H029_0617, --arcanist
        skin = FourCC('H029'),
        select = FourCC('A081'),
        passive = FourCC('A0EY')
    }
    HeroCircle[9] = {
        unit = gg_unit_O02S_0615, --dark summoner
        skin = FourCC('O02S'),
        select = FourCC('A082'),
        passive = FourCC('A0I0')
    }
    HeroCircle[10] = {
        unit = gg_unit_H00R_0610, --bard
        skin = FourCC('H00R'),
        select = FourCC('A084'),
        passive = FourCC('A0HV')
    }
    HeroCircle[11] = {
        unit = gg_unit_E00G_0616, --hydromancer
        skin = FourCC('E00G'),
        select = FourCC('A086'),
        passive = FourCC('A0EC')
    }
    HeroCircle[12] = {
        unit = gg_unit_E012_0613, --high priestess
        skin = FourCC('E012'),
        select = FourCC('A087'),
        passive = FourCC('A0I2')
    }
    HeroCircle[13] = {
        unit = gg_unit_E00W_0614, --elementalist
        skin = FourCC('E00W'),
        select = FourCC('A089'),
        passive = FourCC('A0I3')
    }
    HeroCircle[14] = {
        unit = gg_unit_E002_0585, --assassin
        skin = FourCC('E002'),
        select = FourCC('A07J'),
        passive = FourCC('A01N')
    }
    HeroCircle[15] = {
        unit = gg_unit_O03J_0609, --thunder blade
        skin = FourCC('O03J'),
        select = FourCC('A01P'),
        passive = FourCC('A039')
    }
    HeroCircle[16] = {
        unit = gg_unit_E015_0586, --master rogue
        skin = FourCC('E015'),
        select = FourCC('A07L'),
        passive = FourCC('A0I1')
    }
    HeroCircle[17] = {
        unit = gg_unit_E008_0587, --elite marksman
        skin = FourCC('E008'),
        select = FourCC('A07M'),
        passive = FourCC('A070')
    }
    HeroCircle[18] = {
        unit = gg_unit_E00X_0611, --phoenix ranger
        skin = FourCC('E00X'),
        select = FourCC('A07N'),
        passive = FourCC('A0I6')
    }

    for i = 0, HERO_TOTAL do
        if HeroCircle[i] then
            UnitAddAbility(HeroCircle[i].unit, FourCC('Aloc'))
            local angle = bj_PI * (HERO_TOTAL - i) / (HERO_TOTAL * 0.5)

            SetUnitPosition(HeroCircle[i].unit, 21643. + 475. * Cos(angle), 3447. + 475. * Sin(angle))
            SetUnitFacingTimed(HeroCircle[i].unit, bj_RADTODEG * Atan2(3447. - GetUnitY(HeroCircle[i].unit), 21643. - GetUnitX(HeroCircle[i].unit)), 0)

            local j = 0
            --store innate spell tooltip strings
            local abil = BlzGetUnitAbilityByIndex(HeroCircle[i].unit, j)
            while abil do
                sid = BlzGetAbilityId(abil)

                if Spells[sid] then
                    local ablev = 1
                    while not (ablev > BlzGetAbilityIntegerField(abil, ABILITY_IF_LEVELS)) do

                        if not SpellTooltips[sid] then
                            SpellTooltips[sid] = {}
                        end

                        SpellTooltips[sid][ablev] = BlzGetAbilityStringLevelField(abil, ABILITY_SLF_TOOLTIP_NORMAL_EXTENDED, ablev - 1)

                        ablev = ablev + 1
                    end
                end

                j = j + 1
                abil = BlzGetUnitAbilityByIndex(HeroCircle[i].unit, j)
            end
        end
    end

    --spawn prechaos enemies
    SpawnCreeps(0)

    --shops
    ShopSetup()

    --ashen vat
    ASHEN_VAT = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h05J'), 20485., -20227., 270.)
end)

if Debug then Debug.endFile() end
