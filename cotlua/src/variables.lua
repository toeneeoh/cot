--[[
    variables.lua

    A big bucket of defined globals.
]]

OnInit.global("Variables", function(Require)
    Require('Users')

    DEV_ENABLED         = false
    MAP_NAME            = "CoT Nevermore"
    SAVE_LOAD_VERSION   = 1
    TIME                = 0

    PLAYER_CAP                         = 6
    MAX_LEVEL                          = 400
    LEECH_CONSTANT                     = 50
    CALL_FOR_HELP_RANGE                = 800.
    NEARBY_BOSS_RANGE                  = 2500.
    BOSS_RESPAWN_TIME                  = 600
    MIN_LIFE                           = 0.406
    PLAYER_TOWN                        = 8
    PLAYER_BOSS                        = 11
    FOE_ID                             = PLAYER_NEUTRAL_AGGRESSIVE + 1
    BOSS_ID                            = PLAYER_BOSS + 1
    TOWN_ID                            = PLAYER_TOWN + 1
    FPS_32                             = 0.03125
    FPS_64                             = 0.015625
    DETECT_LEAVE_ABILITY               = FourCC('uDex') ---@type integer 
    INT_32_LIMIT                       = 2147483647

    --units
    DUMMY_CASTER                       = FourCC('e011')
    DUMMY_VISION                       = FourCC('eRez')
    GRAVE                              = FourCC('H01G')
    BACKPACK                           = FourCC('H05D')
    HERO_PHOENIX_RANGER                = FourCC('E00X')
    HERO_ROYAL_GUARDIAN                = FourCC('H04Z')
    HERO_CRUSADER                      = FourCC('H05B')
    HERO_MASTER_ROGUE                  = FourCC('E015')
    HERO_ELEMENTALIST                  = FourCC('E00W')
    HERO_HIGH_PRIEST                   = FourCC('E012')
    HERO_DARK_SUMMONER                 = FourCC('O02S')
    HERO_SAVIOR                        = FourCC('H01N')
    HERO_DARK_SAVIOR                   = FourCC('H01S')
    HERO_ASSASSIN                      = FourCC('E002')
    HERO_BARD                          = FourCC('H00R')
    HERO_ARCANIST                      = FourCC('H029')
    HERO_OBLIVION_GUARD                = FourCC('H02A')
    HERO_THUNDERBLADE                  = FourCC('O03J')
    HERO_BLOODZERKER                   = FourCC('H03N')
    HERO_MARKSMAN                      = FourCC('E008')
    HERO_HYDROMANCER                   = FourCC('E00G')
    HERO_WARRIOR                       = FourCC('H012')
    HERO_DRUID                         = FourCC('O018')
    HERO_DARK_SAVIOR_DEMON             = FourCC('E01M')
    HERO_MARKSMAN_SNIPER               = FourCC('E00F')
    HERO_VAMPIRE                       = FourCC('U003')
    HERO_TOTAL                         = 19
    SUMMON_DESTROYER                   = FourCC('E014')
    SUMMON_HOUND                       = FourCC('H05F')
    SUMMON_GOLEM                       = FourCC('H05G')

    --proficiencies
    PROF_PLATE                         = 0x1
    PROF_FULLPLATE                     = 0x2
    PROF_LEATHER                       = 0x4
    PROF_CLOTH                         = 0x8
    PROF_SHIELD                        = 0x10
    PROF_HEAVY                         = 0x20
    PROF_SWORD                         = 0x40
    PROF_DAGGER                        = 0x80
    PROF_BOW                           = 0x100
    PROF_STAFF                         = 0x200

    HeroStats = {
        [HERO_PHOENIX_RANGER]   = { prof = PROF_BOW + PROF_LEATHER,
                                    phys_resist = 2.0, magic_resist = 1.8, phys_damage = 1.3, crit_chance = 5., crit_damage = 100. },
        [HERO_MARKSMAN]         = { prof = PROF_BOW + PROF_LEATHER,
                                    phys_resist = 2.0, magic_resist = 1.8, phys_damage = 1.3, crit_chance = 5., crit_damage = 100. },
        [HERO_MARKSMAN_SNIPER]  = { prof = PROF_BOW + PROF_LEATHER,
                                    phys_resist = 2.0, magic_resist = 1.8, phys_damage = 1.3, crit_chance = 5., crit_damage = 100. },
        [HERO_MASTER_ROGUE]     = { prof = PROF_DAGGER + PROF_LEATHER,
                                    phys_resist = 1.6, magic_resist = 1.8, phys_damage = 1.25, crit_chance = 5., crit_damage = 100. },
        [HERO_THUNDERBLADE]     = { prof = PROF_DAGGER + PROF_LEATHER,
                                    phys_resist = 1.6, magic_resist = 1.8, phys_damage = 1.25, crit_chance = 5., crit_damage = 100. },
        [HERO_ASSASSIN]         = { prof = PROF_DAGGER + PROF_LEATHER,
                                    phys_resist = 1.6, magic_resist = 1.8, phys_damage = 1.25, crit_chance = 5., crit_damage = 100. },
        [HERO_VAMPIRE]          = { prof = PROF_HEAVY + PROF_PLATE + PROF_DAGGER + PROF_LEATHER,
                                    phys_resist = 1.5, magic_resist = 1.5, phys_damage = 1.25, crit_chance = 5., crit_damage = 100. },
        [HERO_BLOODZERKER]      = { prof = PROF_HEAVY + PROF_SWORD + PROF_PLATE,
                                    phys_resist = 1.6, magic_resist = 1.8, phys_damage = 1.2, crit_chance = 5., crit_damage = 100. },
        [HERO_WARRIOR]          = { prof = PROF_HEAVY + PROF_SWORD + PROF_PLATE,
                                    phys_resist = 1.1, magic_resist = 1.5, phys_damage = 1.2, crit_chance = 5., crit_damage = 100. },
        [HERO_ROYAL_GUARDIAN]   = { prof = PROF_HEAVY + PROF_SWORD + PROF_PLATE + PROF_FULLPLATE,
                                    phys_resist = 0.9, magic_resist = 1.5, phys_damage = 1.2, crit_chance = 5., crit_damage = 100. },
        [HERO_OBLIVION_GUARD]   = { prof = PROF_HEAVY + PROF_PLATE + PROF_FULLPLATE,
                                    phys_resist = 1.0, magic_resist = 1.3, phys_damage = 1.2, crit_chance = 5., crit_damage = 100. },
        [HERO_CRUSADER]         = { prof = PROF_HEAVY + PROF_FULLPLATE + PROF_STAFF + PROF_CLOTH,
                                    phys_resist = 1.1, magic_resist = 1.1, phys_damage = 1.2, crit_chance = 5., crit_damage = 100. },
        [HERO_DARK_SAVIOR]      = { prof = PROF_SWORD + PROF_PLATE + PROF_STAFF + PROF_CLOTH,
                                    phys_resist = 1.6, magic_resist = 1.0, phys_damage = 1.2, crit_chance = 5., crit_damage = 100. },
        [HERO_DARK_SAVIOR_DEMON]= { prof = PROF_SWORD + PROF_PLATE + PROF_STAFF + PROF_CLOTH,
                                    phys_resist = 1.6, magic_resist = 1.0, phys_damage = 1.2, crit_chance = 5., crit_damage = 100. },
        [HERO_SAVIOR]           = { prof = PROF_SWORD + PROF_PLATE + PROF_HEAVY + PROF_FULLPLATE,
                                    phys_resist = 1.2, magic_resist = 1.3, phys_damage = 1.2, crit_chance = 5., crit_damage = 100. },
        [HERO_DARK_SUMMONER]    = { prof = PROF_STAFF + PROF_CLOTH,
                                    phys_resist = 1.8, magic_resist = 1.6, phys_damage = 1.0, crit_chance = 5., crit_damage = 100. },
        [HERO_BARD]             = { prof = PROF_STAFF + PROF_CLOTH,
                                    phys_resist = 1.8, magic_resist = 1.6, phys_damage = 1.0, crit_chance = 5., crit_damage = 100. },
        [HERO_ARCANIST]         = { prof = PROF_STAFF + PROF_CLOTH,
                                    phys_resist = 1.8, magic_resist = 1.6, phys_damage = 1.0, crit_chance = 5., crit_damage = 100. },
        [HERO_HYDROMANCER]      = { prof = PROF_STAFF + PROF_CLOTH,
                                    phys_resist = 1.8, magic_resist = 1.6, phys_damage = 1.0, crit_chance = 5., crit_damage = 100. },
        [HERO_HIGH_PRIEST]      = { prof = PROF_STAFF + PROF_CLOTH,
                                    phys_resist = 1.8, magic_resist = 1.6, phys_damage = 1.0, crit_chance = 5., crit_damage = 100. },
        [HERO_ELEMENTALIST]     = { prof = PROF_STAFF + PROF_CLOTH,
                                    phys_resist = 1.8, magic_resist = 1.6, phys_damage = 1.0, crit_chance = 5., crit_damage = 100. },
    }

    --default stats return 1.
    local default_stats = {phys_resist = 1., magic_resist = 1., phys_damage = 1.}
    setmetatable(HeroStats, { __index = function(tbl, key)
        return default_stats
    end})

    --currency
    GOLD                               = 0
    LUMBER                             = 1
    PLATINUM                           = 2
    ARCADITE                           = 3
    CRYSTAL                            = 4
    CURRENCY_COUNT                     = 5

    --bosses
    BOSS_TAUREN                        = 1
    BOSS_MYSTIC                        = 2
    BOSS_HELLFIRE                      = 3
    BOSS_DWARF                         = 4
    BOSS_PALADIN                       = 5
    BOSS_DRAGOON                       = 6
    BOSS_DEATH_KNIGHT                  = 7
    BOSS_VASHJ                         = 8
    BOSS_YETI                          = 9
    BOSS_OGRE                          = 10
    BOSS_NERUBIAN                      = 11
    BOSS_POLAR_BEAR                    = 12
    BOSS_LIFE                          = 13
    BOSS_HATE                          = 14
    BOSS_LOVE                          = 15
    BOSS_KNOWLEDGE                     = 16
    BOSS_ARKADEN                       = 17

    BOSS_DEMON_PRINCE                  = 18
    BOSS_ABSOLUTE_HORROR               = 19
    BOSS_ORSTED                        = 20
    BOSS_SLAUGHTER_QUEEN               = 21
    BOSS_SATAN                         = 22
    BOSS_DARK_SOUL                     = 23
    BOSS_LEGION                        = 24
    BOSS_THANATOS                      = 25
    BOSS_EXISTENCE                     = 26
    BOSS_AZAZOTH                       = 27
    BOSS_XALLARATH                     = 28

    BOSS_OFFSET = 1

    --items
    MAX_REINCARNATION_CHARGES          = 3
    ITEM_MIN_LEVEL_VARIANCE            = 8
    ITEM_MAX_LEVEL_VARIANCE            = 11
    ABILITY_OFFSET                     = 500 --big enough
    QUALITY_SAVED                      = 7

    --auto generated tooltips
    ITEM_HEALTH                        = 1
    ITEM_MANA                          = 2
    ITEM_DAMAGE                        = 3
    ITEM_ARMOR                         = 4
    ITEM_STRENGTH                      = 5
    ITEM_AGILITY                       = 6
    ITEM_INTELLIGENCE                  = 7
    ITEM_REGENERATION                  = 8
    ITEM_DAMAGE_RESIST                 = 9
    ITEM_MAGIC_RESIST                  = 10
    ITEM_DAMAGE_MULT                   = 11
    ITEM_MAGIC_MULT                    = 12
    ITEM_MOVESPEED                     = 13
    ITEM_EVASION                       = 14
    ITEM_SPELLBOOST                    = 15
    ITEM_CRIT_CHANCE                   = 16
    ITEM_CRIT_DAMAGE                   = 17
    ITEM_CRIT_CHANCE_MULT              = 18
    ITEM_CRIT_DAMAGE_MULT              = 19
    ITEM_BASE_ATTACK_SPEED             = 20
    ITEM_GOLD_GAIN                     = 21
    ITEM_ABILITY                       = 22
    ITEM_ABILITY2                      = 23
    ITEM_STAT_TOTAL                    = 23

    --not auto generated
    ITEM_TOOLTIP                       = 24
    ITEM_NOCRAFT                       = 25
    ITEM_TIER                          = 26
    ITEM_TYPE                          = 27
    ITEM_UPGRADE_MAX                   = 28
    ITEM_LEVEL_REQUIREMENT             = 29
    ITEM_LIMIT                         = 30
    ITEM_COST                          = 31
    ITEM_DISCOUNT                      = 32
    ITEM_STACK                         = 33

    CUSTOM_ITEM_OFFSET = FourCC('I000') ---@type integer 
    MAX_SAVED_ITEMS    = 8191 ---@type integer 
    MAX_SAVED_HEROES   = 63  ---@type integer --6 bits
    SAVE_UNIT_TYPE     = {} ---@type integer[] 

    SAVE_TABLE = {
        KEY_ITEMS = {},
        KEY_UNITS = {}
    }

    MAIN_MAP = {
        rect = gg_rct_Main_Map,
        vision = gg_rct_Main_Map_Vision,
        minX = GetRectMinX(gg_rct_Main_Map),
        minY = GetRectMinY(gg_rct_Main_Map),
        maxX = GetRectMaxX(gg_rct_Main_Map),
        maxY = GetRectMaxY(gg_rct_Main_Map),
        region = CreateRegion()
    }

    RegionAddRect(MAIN_MAP.region, MAIN_MAP.rect)

    MAIN_MAP.centerX = (MAIN_MAP.minX + MAIN_MAP.maxX) / 2.00
    MAIN_MAP.centerY = (MAIN_MAP.minY + MAIN_MAP.maxY) / 2.00

    ItemMagicRes = __jarray(0) ---@type number[] 
    ItemGoldRate = __jarray(0) ---@type integer[] 

    SummonGroup = {} ---@type unit[]
    IS_BACKPACK_MOVING = {} ---@type boolean[] 
    DAMAGE_TAG = {}
    IS_FLEEING = {} ---@type boolean[]
    ArcTag     = "|cff66FF66Arcadite Lumber|r: " ---@type string 
    PlatTag    = "|cffccccccPlatinum Coins|r: " ---@type string 
    CrystalTag = "|cff6969FFCrystals: |r" ---@type string 
    Hardcore = {} ---@type boolean[]
    HARD_MODE = 0 ---@type integer 
    pfoe = Player(PLAYER_NEUTRAL_AGGRESSIVE)
    pboss = Player(PLAYER_BOSS)
    CHAOS_MODE = false ---@type boolean 
    CHAOS_LOADING = false ---@type boolean 
    DummyUnit = gg_unit_h05E_0717

    --tables
    infoString=__jarray("") ---@type string[] 
    ShopkeeperDirection=__jarray("") ---@type string[] 
    CURRENCY_ICON=__jarray("") ---@type string[] 
    XP_Rate=__jarray(0) ---@type number[]
    player_fog = {} ---@type boolean[]

    SpellTooltips = array2d("") ---@type string[][] 
    KillQuest = array2d(0) ---@type table
    ItemData = array2d(0) ---@type table
    UnitData = array2d(0) ---@type table
    ItemPrices = array2d(0) ---@type table
    CosmeticTable = array2d(0) ---@type table
    HeroCircle = {}

    ColoGoldWon = 0
    ColoCount_main=__jarray(0) ---@type integer[] 
    ColoEnemyType_main=__jarray(0) ---@type integer[] 
    ColoCount_sec=__jarray(0) ---@type integer[] 
    ColoEnemyType_sec=__jarray(0) ---@type integer[] 
    Colosseum_XP = __jarray(0) ---@type number[]

    Zoom = __jarray(0) ---@type integer[]

    SELECTING_HERO = {} ---@type boolean[] 
    forgottenTypes = __jarray(0) ---@type integer[] 
    forgottenCount         = 0 ---@type integer 
    forgotten_spawner      = nil ---@type unit 
    funnyList = {
        -894554765,
        -1291321931,
    }

    IS_ALT_DOWN = {} ---@type boolean[]
    charLight={} ---@type effect[] 

    RollBoard=nil ---@type leaderboard 

    colospot={} ---@type location[] 

    Hero={} ---@type unit[] 
    HeroGrave={} ---@type unit[] 
    Backpack={} ---@type unit[] 

    HeroID=__jarray(0) ---@type integer[] 
    Currency=__jarray(0) ---@type integer[] 
    prMulti=__jarray(0) ---@type integer[] 
    ShieldCount=__jarray(0) ---@type integer[] 
    RollChecks=__jarray(0) ---@type integer[] 
    HuntedLevel=__jarray(0) ---@type integer[] 
    CustomLighting=__jarray(0) ---@type integer[] 

    MultiShot = {} ---@type boolean[] 
    IS_CAMERA_LOCKED = {} ---@type boolean[] 
    IS_FORCE_SAVING = {} ---@type boolean[] 

    BOOST=__jarray(1) ---@type number[] 
    LBOOST=__jarray(1) ---@type number[] 

    TownCenter = Location(-250., 160.) ---@type location 
    ColosseumCenter = Location(21710., -4261.) ---@type location 
    StruggleCenter = Location(28030., 4361.) ---@type location 
    IS_IN_COLO = {} ---@type boolean[] 
    IS_IN_STRUGGLE = {} ---@type boolean[] 
    StruggleText = CreateTextTag() ---@type texttag 
    ColoText = CreateTextTag() ---@type texttag 
    ColoWaveCount = 0 ---@type integer 

    DEFAULT_LIGHTING        = "Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx" ---@type string 

    BP_DESELECT = {} ---@type boolean[] 

    Struggle_SpawnR = {} ---@type rect[]
    Struggle_WaveU = __jarray(0) ---@type integer[]
    Struggle_WaveUN = __jarray(0) ---@type integer[]
    Struggle_Wave_SR = __jarray(0) ---@type integer[]
    StruggleGoldPer = __jarray(0) ---@type integer[]

    SYNC_PREFIX        = "S" ---@type string 
    ColoPlayerCount         = 0 ---@type integer 
    BOOST_OFF         = false ---@type boolean 

    GodsEnterFlag         = false ---@type boolean 
    GodsRepeatFlag         = false ---@type boolean 
    power_crystal      = nil ---@type unit 
    god_portal      = nil ---@type unit 
    DeadGods         = 4 ---@type integer 
    BANISH_FLAG         = false ---@type boolean 
    GODS_GROUP = {} ---@type player[]

    afkTextVisible = {} ---@type boolean[] 
    hardcoreClicked = {} ---@type boolean[] 
    votingSelectYes = CreateTrigger()
    votingSelectNo = CreateTrigger()
    hardcoreSelectYes = CreateTrigger()
    hardcoreSelectNo = CreateTrigger()
    AFK_TEXT = ""
    hardcoreBG=nil ---@type framehandle 
    hardcoreButtonFrame=nil ---@type framehandle 
    hardcoreButtonFrame2=nil ---@type framehandle 
    hardcoreButtonIcon=nil ---@type framehandle 
    hardcoreButtonIcon2=nil ---@type framehandle 
    votingBG=nil ---@type framehandle 
    votingButtonFrame=nil ---@type framehandle 
    votingButtonFrame2=nil ---@type framehandle 
    votingButtonIconNo=nil ---@type framehandle 
    votingButtonIconYes=nil ---@type framehandle 
    menuButton=nil ---@type framehandle 
    chatButton=nil ---@type framehandle 
    questButton=nil ---@type framehandle 
    allyButton=nil ---@type framehandle 
    upperbuttonBar=nil ---@type framehandle 
    DPS_FRAME=nil ---@type framehandle 
    DPS_FRAME_TITLE=nil ---@type framehandle 
    DPS_FRAME_TEXTVALUE=nil ---@type framehandle 

    INVENTORYBACKDROP={} ---@type framehandle[] 
    IS_HERO_PANEL_ON = {} ---@type boolean[] 

    LimitBreakBackdrop = nil  ---@type framehandle 

    --prestige talent window frames
    TalentMainFrame             = nil  ---@type framehandle 
    TreeLeft             = nil  ---@type framehandle 
    TreeMiddle             = nil  ---@type framehandle 
    TreeRight             = nil  ---@type framehandle 
    ConfirmTalentsButton             = nil  ---@type framehandle 
    CancelTalentsButton             = nil  ---@type framehandle 
    CloseTalentViewButton             = nil  ---@type framehandle 
    TreeBackgroundLeft             = nil  ---@type framehandle 
    TitleBackgroundLeft             = nil  ---@type framehandle 
    TreeBackgroundMiddle             = nil  ---@type framehandle 
    TitleBackgroundMiddle             = nil  ---@type framehandle 
    TreeBackgroundRight             = nil  ---@type framehandle 
    TitleBackgroundRight             = nil  ---@type framehandle 
    TitleLeft             = nil  ---@type framehandle 
    TitleMiddle             = nil  ---@type framehandle 
    TitleRight             = nil  ---@type framehandle 

    TitleBackgroundStatus             = nil  ---@type framehandle 
    TreeStatus             = nil  ---@type framehandle 
    StatusPoints             = nil  ---@type framehandle 
    TitleStatus             = nil  ---@type framehandle 

    Struggle_Pcount = 0
    Struggle_WaveN = 0
    Struggle_WaveUCN = 0
    Struggle_SpawnR[1] = gg_rct_InfiniteStruggleSpawn1
    Struggle_SpawnR[2] = gg_rct_InfiniteStruggleSpawn2
    Struggle_SpawnR[3] = gg_rct_InfiniteStruggleSpawn3
    Struggle_SpawnR[4] = gg_rct_InfiniteStruggleSpawn4
    -- start setting up units
    -- WaveU = Unit type of the wave
    -- WaveUN = Number of units in the wave
    -- WaveSR = How many units spawn per second during the wave
    Struggle_WaveU[0] = FourCC('n03Y') --slave
    Struggle_WaveUN[0] = 140
    Struggle_Wave_SR[0] = 8
    StruggleGoldPer[0] = 10
    Struggle_WaveU[1] = FourCC('n08Q') --lightning revenant
    Struggle_WaveUN[1] = 170
    Struggle_Wave_SR[1] = 12
    StruggleGoldPer[1] = 15
    Struggle_WaveU[2] = FourCC('n044') --scorpion
    Struggle_WaveUN[2] = 480
    Struggle_Wave_SR[2] = 16
    StruggleGoldPer[2] = 20
    Struggle_WaveU[3] = FourCC('n08R') --brood mother
    Struggle_WaveUN[3] = 130
    Struggle_Wave_SR[3] = 8
    StruggleGoldPer[3] = 30
    Struggle_WaveU[4] = FourCC('n08U')
    Struggle_WaveUN[4] = 300
    Struggle_Wave_SR[4] = 12
    StruggleGoldPer[4] = 40
    Struggle_WaveU[5] = FourCC('n04B')
    Struggle_WaveUN[5] = 300
    Struggle_Wave_SR[5] = 12
    StruggleGoldPer[5] = 40
    Struggle_WaveU[6] = FourCC('n04C') --monter wolf 7, lvl 21
    Struggle_WaveUN[6] = 320
    Struggle_Wave_SR[6] = 16
    StruggleGoldPer[6] = 50
    Struggle_WaveU[7] = FourCC('n08P')
    Struggle_WaveUN[7] = 300
    Struggle_Wave_SR[7] = 24
    StruggleGoldPer[7] = 50
    Struggle_WaveU[8] = FourCC('n061')
    Struggle_WaveUN[8] = 140
    Struggle_Wave_SR[8] = 9
    StruggleGoldPer[8] = 60
    Struggle_WaveU[9] = FourCC('n064') --green murloc
    Struggle_WaveUN[9] = 200
    Struggle_Wave_SR[9] = 12
    StruggleGoldPer[9] = 80
    Struggle_WaveU[10] = FourCC('n04U')
    Struggle_WaveUN[10] = 100
    Struggle_Wave_SR[10] = 8
    StruggleGoldPer[10] = 140
    Struggle_WaveU[11] = FourCC('n058')
    Struggle_WaveUN[11] = 200
    Struggle_Wave_SR[11] = 12
    StruggleGoldPer[11] = 200
    Struggle_WaveU[12] = FourCC('n059') --blood skeleton
    Struggle_WaveUN[12] = 200
    Struggle_Wave_SR[12] = 16
    StruggleGoldPer[12] = 250
    Struggle_WaveU[13] = FourCC('n08Y') --ogre overlord 14, lev 52
    Struggle_WaveUN[13] = 300
    Struggle_Wave_SR[13] = 16
    StruggleGoldPer[13] = 700
    Struggle_WaveU[14] = FourCC('n066') --murlock titan
    Struggle_WaveUN[14] = 9
    Struggle_Wave_SR[14] = 3
    StruggleGoldPer[14] = 600
    Struggle_WaveU[15] = FourCC('o03H') --tauren
    Struggle_WaveUN[15] = 120
    Struggle_Wave_SR[15] = 6
    StruggleGoldPer[15] = 800
    Struggle_WaveU[16] = FourCC('n05X') --doom beast 17
    Struggle_WaveUN[16] = 300
    Struggle_Wave_SR[16] = 16
    StruggleGoldPer[16] = 400
    Struggle_WaveU[17] = FourCC('n05Z') --death beast
    Struggle_WaveUN[17] = 50
    Struggle_Wave_SR[17] = 4
    StruggleGoldPer[17] = 650
    Struggle_WaveU[18] = FourCC('n04J') --Dragon King 
    Struggle_WaveUN[18] = 16
    Struggle_Wave_SR[18] = 4
    StruggleGoldPer[18] = 1200
    Struggle_WaveU[19] = FourCC('n066')
    Struggle_WaveUN[19] = 400
    Struggle_Wave_SR[19] = 28
    StruggleGoldPer[19] = 600
    Struggle_WaveU[20] = FourCC('n05A') --death skeleton 21
    Struggle_WaveUN[20] = 300
    Struggle_Wave_SR[20] = 16
    StruggleGoldPer[20] = 800
    Struggle_WaveU[21] = FourCC('n093')--nerubian empress 22
    Struggle_WaveUN[21] = 15
    Struggle_Wave_SR[21] = 3
    StruggleGoldPer[21] = 2000
    Struggle_WaveU[22] = FourCC('n04M') --soul of lightning
    Struggle_WaveUN[22] = 70
    Struggle_Wave_SR[22] = 7
    StruggleGoldPer[22] = 700
    Struggle_WaveU[23] = FourCC('n093') --nerubian empress
    Struggle_WaveUN[23] = 70
    Struggle_Wave_SR[23] = 6
    StruggleGoldPer[23] = 2000
    Struggle_WaveU[24] = FourCC('n08Z') --king of ogres
    Struggle_WaveUN[24] = 40
    Struggle_Wave_SR[24] = 3
    StruggleGoldPer[24] = 2000
    Struggle_WaveU[25] = FourCC('n04O') --soul of death
    Struggle_WaveUN[25] = 20
    Struggle_Wave_SR[25] = 4
    StruggleGoldPer[25] = 2000
    Struggle_WaveU[26] = FourCC('n08Z') --king of ogres
    Struggle_WaveUN[26] = 160
    Struggle_Wave_SR[26] = 8
    StruggleGoldPer[26] = 4000
    Struggle_WaveU[27] = 0 --skipped enemy type makes struggle end 
    Struggle_WaveUN[27] = 0
    Struggle_WaveU[28] = FourCC('n04O') --soul of death
    Struggle_WaveUN[28] = 100
    Struggle_Wave_SR[28] = 12
    StruggleGoldPer[28] = 2000
    Struggle_WaveU[29] = FourCC('n06G') --poss god
    Struggle_WaveUN[29] = 120
    Struggle_Wave_SR[29] = 10
    StruggleGoldPer[29] = 4000
    Struggle_WaveU[30] = FourCC('n00R')
    Struggle_WaveUN[30] = 130
    Struggle_Wave_SR[30] = 6
    StruggleGoldPer[30] = 4500
    Struggle_WaveU[31] = FourCC('n00T') --tormentress ranged
    Struggle_WaveUN[31] = 130
    Struggle_Wave_SR[31] = 6
    StruggleGoldPer[31] = 5000
    Struggle_WaveU[32] = FourCC('n09H')
    Struggle_WaveUN[32] = 100
    Struggle_Wave_SR[32] = 6
    StruggleGoldPer[32] = 5500
    Struggle_WaveU[33] = FourCC('n09I')
    Struggle_WaveUN[33] = 200
    Struggle_Wave_SR[33] = 10
    StruggleGoldPer[33] = 11000
    Struggle_WaveU[34] = FourCC('n09J')
    Struggle_WaveUN[34] = 150
    Struggle_Wave_SR[34] = 10
    StruggleGoldPer[34] = 9000
    Struggle_WaveU[35] = FourCC('n09K')
    Struggle_WaveUN[35] = 200
    Struggle_Wave_SR[35] = 10
    StruggleGoldPer[35] = 20000
    Struggle_WaveU[36] = FourCC('n09L')
    Struggle_WaveUN[36] = 100
    Struggle_Wave_SR[36] = 5
    StruggleGoldPer[36] = 40000
    Struggle_WaveU[37] = FourCC('n091')  --angel
    Struggle_WaveUN[37] = 10
    Struggle_Wave_SR[37] = 2
    StruggleGoldPer[37] = 30000
    Struggle_WaveU[38] = FourCC('n09L')
    Struggle_WaveUN[38] = 100
    Struggle_Wave_SR[38] = 10
    StruggleGoldPer[38] = 40000
    Struggle_WaveU[39] = FourCC('n091')  --angel
    Struggle_WaveUN[39] = 20
    Struggle_Wave_SR[39] = 4
    StruggleGoldPer[39] = 30000
    Struggle_WaveU[40] = FourCC('n090')
    Struggle_WaveUN[40] = 12
    Struggle_Wave_SR[40] = 4
    StruggleGoldPer[40] = 50000 --god
    Struggle_WaveU[41] = FourCC('n092')
    Struggle_WaveUN[41] = 10
    Struggle_Wave_SR[41] = 1
    StruggleGoldPer[41] = 300000 --omniscient
    Struggle_WaveU[42] = 0
    Struggle_WaveUN[42] = 0

    ColoCount_main[0]=4
    ColoEnemyType_main[0]=FourCC('n046')
    ColoCount_main[1]=3
    ColoEnemyType_main[1]=FourCC('n045')
    ColoCount_main[2]=3
    ColoEnemyType_main[2]=FourCC('n046')
    ColoCount_sec[2]=2
    ColoEnemyType_sec[2]=FourCC('n047')
    ColoCount_main[3]=4
    ColoEnemyType_main[3]=FourCC('n045')
    ColoCount_sec[3]=2
    ColoEnemyType_sec[3]=FourCC('n047')
    ColoCount_main[4]=6
    ColoEnemyType_main[4]=FourCC('n047')
    ColoCount_main[5]=5
    ColoEnemyType_main[5]=FourCC('n045')
    ColoCount_sec[5]=5
    ColoEnemyType_sec[5]=FourCC('n047')
    ColoCount_main[6]=6
    ColoEnemyType_main[6]=FourCC('n047')
    ColoCount_sec[6]=1
    ColoEnemyType_sec[6]=FourCC('n048')
    ColoCount_main[7]=3
    ColoEnemyType_main[7]=FourCC('n048')
    ColoCount_main[8]=11
    ColoEnemyType_main[8]=FourCC('n047')
    ColoCount_sec[8]=2
    ColoEnemyType_sec[8]=FourCC('n048')
    ColoCount_main[9]=8
    ColoEnemyType_main[9]=FourCC('n048')
    ColoCount_main[10]=5
    ColoEnemyType_main[10]=FourCC('n048')
    ColoCount_sec[10]=1
    ColoEnemyType_sec[10]=FourCC('n049')
    ColoCount_main[11]=7
    ColoEnemyType_main[11]=FourCC('n05L')
    ColoCount_main[12]=10
    ColoEnemyType_main[12]=FourCC('n05L')
    ColoCount_main[13]=8
    ColoEnemyType_main[13]=FourCC('n05M')
    ColoCount_main[14]=10
    ColoEnemyType_main[14]=FourCC('n05N')
    ColoCount_main[15]=4
    ColoEnemyType_main[15]=FourCC('n05O')
    ColoCount_sec[15]=3
    ColoEnemyType_sec[15]=FourCC('n05M')
    ColoCount_main[16]=10
    ColoEnemyType_main[16]=FourCC('n05L')
    ColoCount_main[17]=6
    ColoEnemyType_main[17]=FourCC('n05N')
    ColoCount_sec[17]=6
    ColoEnemyType_sec[17]=FourCC('n05L')
    ColoCount_main[18]=6
    ColoEnemyType_main[18]=FourCC('n05M')
    ColoCount_sec[18]=6
    ColoEnemyType_sec[18]=FourCC('n05O')
    ColoCount_main[19]=6
    ColoEnemyType_main[19]=FourCC('n05N')
    ColoCount_sec[19]=6
    ColoEnemyType_sec[19]=FourCC('n05L')
    ColoCount_main[20]=10
    ColoEnemyType_main[20]=FourCC('n05O')
    ColoCount_main[21]=10
    ColoEnemyType_main[21]=FourCC('n05O')
    ColoCount_sec[21]=1
    ColoEnemyType_sec[21]=FourCC('n05P')
    ColoCount_main[22]=4
    ColoEnemyType_main[22]=FourCC('n049')
    ColoCount_sec[22]=2
    ColoEnemyType_sec[22]=FourCC('n05P')
    ColoCount_main[25]=3
    ColoEnemyType_main[25]=FourCC('n04A')
    ColoCount_main[26]=6
    ColoEnemyType_main[26]=FourCC('n04A')
    ColoCount_main[27]=3
    ColoEnemyType_main[27]=FourCC('n04B')
    ColoCount_sec[27]=2
    ColoEnemyType_sec[27]=FourCC('n04A')
    ColoCount_main[28]=8
    ColoEnemyType_main[28]=FourCC('n04B')
    ColoCount_main[29]=10
    ColoEnemyType_main[29]=FourCC('n04A')
    ColoCount_main[30]=4
    ColoEnemyType_main[30]=FourCC('n04C')
    ColoCount_sec[30]=4
    ColoEnemyType_sec[30]=FourCC('n04B')
    ColoCount_main[31]=8
    ColoEnemyType_main[31]=FourCC('n04C')
    ColoCount_main[32]=9
    ColoEnemyType_main[32]=FourCC('n04C')
    ColoCount_sec[32]=2
    ColoEnemyType_sec[32]=FourCC('n04D')
    ColoCount_main[33]=8
    ColoEnemyType_main[33]=FourCC('n04D')
    ColoCount_main[34]=5
    ColoEnemyType_main[34]=FourCC('n04D')
    ColoCount_sec[34]=1
    ColoEnemyType_sec[34]=FourCC('n04E')
    ColoCount_main[35]=6
    ColoEnemyType_main[35]=FourCC('n061')
    ColoCount_main[36]=10
    ColoEnemyType_main[36]=FourCC('n061')
    ColoCount_main[37]=7
    ColoEnemyType_main[37]=FourCC('n062')
    ColoCount_main[38]=7
    ColoEnemyType_main[38]=FourCC('n063')
    ColoCount_main[39]=7
    ColoEnemyType_main[39]=FourCC('n064')
    ColoCount_main[40]=4
    ColoEnemyType_main[40]=FourCC('n065')
    ColoCount_main[41]=8
    ColoEnemyType_main[41]=FourCC('n065')
    ColoCount_main[42]=10
    ColoEnemyType_main[42]=FourCC('n063')
    ColoCount_main[43]=6
    ColoEnemyType_main[43]=FourCC('n061')
    ColoCount_sec[43]=6
    ColoEnemyType_sec[43]=FourCC('n062')
    ColoCount_main[44]=6
    ColoEnemyType_main[44]=FourCC('n064')
    ColoCount_sec[44]=6
    ColoEnemyType_sec[44]=FourCC('n065')
    ColoCount_main[45]=8
    ColoEnemyType_main[45]=FourCC('n065')
    ColoCount_sec[45]=1
    ColoEnemyType_sec[45]=FourCC('n066')
    ColoCount_main[46]=4
    ColoEnemyType_main[46]=FourCC('n04E')
    ColoCount_sec[46]=2
    ColoEnemyType_sec[46]=FourCC('n066')
    ColoCount_main[49]=3
    ColoEnemyType_main[49]=FourCC('n04F')
    ColoCount_main[50]=4
    ColoEnemyType_main[50]=FourCC('n04G')
    ColoCount_main[51]=8
    ColoEnemyType_main[51]=FourCC('n04F')
    ColoCount_main[52]=6
    ColoEnemyType_main[52]=FourCC('n04G')
    ColoCount_main[53]=6
    ColoEnemyType_main[53]=FourCC('n04H')
    ColoCount_main[54]=5
    ColoEnemyType_main[54]=FourCC('n04H')
    ColoCount_sec[54]=5
    ColoEnemyType_sec[54]=FourCC('n04G')
    ColoCount_main[55]=4
    ColoEnemyType_main[55]=FourCC('n04I')
    ColoCount_main[56]=11
    ColoEnemyType_main[56]=FourCC('n04I')
    ColoCount_main[57]=5
    ColoEnemyType_main[57]=FourCC('n04F')
    ColoCount_sec[57]=5
    ColoEnemyType_sec[57]=FourCC('n04G')
    ColoCount_main[58]=6
    ColoEnemyType_main[58]=FourCC('n04H')
    ColoCount_sec[58]=6
    ColoEnemyType_sec[58]=FourCC('n04I')
    ColoCount_main[59]=5
    ColoEnemyType_main[59]=FourCC('n04I')
    ColoCount_sec[59]=1
    ColoEnemyType_sec[59]=FourCC('n04J')
    ColoCount_main[60]=6
    ColoEnemyType_main[60]=FourCC('n067')
    ColoCount_main[61]=10
    ColoEnemyType_main[61]=FourCC('n067')
    ColoCount_main[62]=10
    ColoEnemyType_main[62]=FourCC('n067')
    ColoCount_main[63]=5
    ColoEnemyType_main[63]=FourCC('n068')
    ColoCount_main[64]=9
    ColoEnemyType_main[64]=FourCC('n068')
    ColoCount_main[65]=5
    ColoEnemyType_main[65]=FourCC('n069')
    ColoCount_main[66]=5
    ColoEnemyType_main[66]=FourCC('n068')
    ColoCount_sec[66]=5
    ColoEnemyType_sec[66]=FourCC('n069')
    ColoCount_main[67]=10
    ColoEnemyType_main[67]=FourCC('n069')
    ColoCount_main[68]=10
    ColoEnemyType_main[68]=FourCC('n06A')
    ColoCount_main[69]=10
    ColoEnemyType_main[69]=FourCC('n06A')
    ColoCount_sec[69]=1
    ColoEnemyType_sec[69]=FourCC('n06B')
    ColoCount_main[70]=4
    ColoEnemyType_main[70]=FourCC('n04J')
    ColoCount_sec[70]=2
    ColoEnemyType_sec[70]=FourCC('n06B')
    ColoCount_main[73]=5
    ColoEnemyType_main[73]=FourCC('n04K')
    ColoCount_main[74]=4
    ColoEnemyType_main[74]=FourCC('n06C')
    ColoCount_main[75]=4
    ColoEnemyType_main[75]=FourCC('n04K')
    ColoCount_sec[75]=4
    ColoEnemyType_sec[75]=FourCC('n06C')
    ColoCount_main[76]=6
    ColoEnemyType_main[76]=FourCC('n04L')
    ColoCount_main[77]=5
    ColoEnemyType_main[77]=FourCC('n06D')
    ColoCount_main[78]=4
    ColoEnemyType_main[78]=FourCC('n04L')
    ColoCount_sec[78]=4
    ColoEnemyType_sec[78]=FourCC('n06C')
    ColoCount_main[79]=4
    ColoEnemyType_main[79]=FourCC('n04K')
    ColoCount_sec[79]=4
    ColoEnemyType_sec[79]=FourCC('n06D')
    ColoCount_main[80]=4
    ColoEnemyType_main[80]=FourCC('n04L')
    ColoCount_sec[80]=4
    ColoEnemyType_sec[80]=FourCC('n06D')
    ColoCount_main[81]=10
    ColoEnemyType_main[81]=FourCC('n04M')
    ColoCount_main[82]=6
    ColoEnemyType_main[82]=FourCC('n04M')
    ColoCount_sec[82]=6
    ColoEnemyType_sec[82]=FourCC('n06C')
    ColoCount_main[83]=6
    ColoEnemyType_main[83]=FourCC('n04M')
    ColoCount_sec[83]=6
    ColoEnemyType_sec[83]=FourCC('n06D')
    ColoCount_main[84]=6
    ColoEnemyType_main[84]=FourCC('n06E')
    ColoCount_main[85]=7
    ColoEnemyType_main[85]=FourCC('n04K')
    ColoCount_sec[85]=5
    ColoEnemyType_sec[85]=FourCC('n06E')
    ColoCount_main[86]=6
    ColoEnemyType_main[86]=FourCC('n04L')
    ColoCount_sec[86]=5
    ColoEnemyType_sec[86]=FourCC('n06E')
    ColoCount_main[87]=5
    ColoEnemyType_main[87]=FourCC('n04M')
    ColoCount_sec[87]=6
    ColoEnemyType_sec[87]=FourCC('n06E')
    ColoCount_main[88]=5
    ColoEnemyType_main[88]=FourCC('n04N')
    ColoCount_main[89]=6
    ColoEnemyType_main[89]=FourCC('n04N')
    ColoCount_sec[89]=5
    ColoEnemyType_sec[89]=FourCC('n06D')
    ColoCount_main[90]=11
    ColoEnemyType_main[90]=FourCC('n04N')
    ColoCount_main[91]=6
    ColoEnemyType_main[91]=FourCC('n04N')
    ColoCount_sec[91]=5
    ColoEnemyType_sec[91]=FourCC('n06E')
    ColoCount_main[92]=6
    ColoEnemyType_main[92]=FourCC('n06F')
    ColoCount_main[93]=6
    ColoEnemyType_main[93]=FourCC('n04L')
    ColoCount_sec[93]=4
    ColoEnemyType_sec[93]=FourCC('n06F')
    ColoCount_main[94]=5
    ColoEnemyType_main[94]=FourCC('n04N')
    ColoCount_sec[94]=5
    ColoEnemyType_sec[94]=FourCC('n06F')
    ColoCount_main[95]=2
    ColoEnemyType_main[95]=FourCC('n04O')
    ColoCount_sec[95]=5
    ColoEnemyType_sec[95]=FourCC('n06C')
    ColoCount_main[96]=5
    ColoEnemyType_main[96]=FourCC('n04K')
    ColoCount_sec[96]=2
    ColoEnemyType_sec[96]=FourCC('n06G')
    ColoCount_main[97]=4
    ColoEnemyType_main[97]=FourCC('n04O')
    ColoCount_sec[97]=6
    ColoEnemyType_sec[97]=FourCC('n06F')
    ColoCount_main[98]=5
    ColoEnemyType_main[98]=FourCC('n04N')
    ColoCount_sec[98]=2
    ColoEnemyType_sec[98]=FourCC('n06G')
    ColoCount_main[99]=4
    ColoEnemyType_main[99]=FourCC('n04O')
    ColoCount_sec[99]=3
    ColoEnemyType_sec[99]=FourCC('n06G')
    ColoCount_main[100]=5
    ColoEnemyType_main[100]=FourCC('n04O')
    ColoCount_sec[100]=5
    ColoEnemyType_sec[100]=FourCC('n06G')
    ColoCount_main[103]=5
    ColoEnemyType_main[103]=FourCC('n06M')
    ColoCount_main[104]=8
    ColoEnemyType_main[104]=FourCC('n06M')
    ColoCount_main[105]=5
    ColoEnemyType_main[105]=FourCC('n06P')
    ColoCount_main[106]=4
    ColoEnemyType_main[106]=FourCC('n06M')
    ColoCount_sec[106]=3
    ColoEnemyType_sec[106]=FourCC('n06P')
    ColoCount_main[107]=8
    ColoEnemyType_main[107]=FourCC('n06P')
    ColoCount_main[108]=6
    ColoEnemyType_main[108]=FourCC('n06M')
    ColoCount_sec[108]=6
    ColoEnemyType_sec[108]=FourCC('n06P')
    ColoCount_main[109]=6
    ColoEnemyType_main[109]=FourCC('n06N')
    ColoCount_sec[109]=6
    ColoEnemyType_sec[109]=FourCC('n06P')
    ColoCount_main[110]=8
    ColoEnemyType_main[110]=FourCC('n06Q')
    ColoCount_main[111]=8
    ColoEnemyType_main[111]=FourCC('n05G')
    ColoCount_main[112]=5
    ColoEnemyType_main[112]=FourCC('n06Q')
    ColoCount_sec[112]=5
    ColoEnemyType_sec[112]=FourCC('n05G')
    ColoCount_main[113]=6
    ColoEnemyType_main[113]=FourCC('n06Q')
    ColoCount_sec[113]=6
    ColoEnemyType_sec[113]=FourCC('n06P')
    ColoCount_main[114]=6
    ColoEnemyType_main[114]=FourCC('n05G')
    ColoCount_sec[114]=6
    ColoEnemyType_sec[114]=FourCC('n06P')
    ColoCount_main[115]=8
    ColoEnemyType_main[115]=FourCC('n05H')
    ColoCount_main[116]=6
    ColoEnemyType_main[116]=FourCC('n05H')
    ColoCount_sec[116]=6
    ColoEnemyType_sec[116]=FourCC('n06P')
    ColoCount_main[117]=8
    ColoEnemyType_main[117]=FourCC('n05I')
    ColoCount_main[118]=6
    ColoEnemyType_main[118]=FourCC('n05I')
    ColoCount_sec[118]=6
    ColoEnemyType_sec[118]=FourCC('n06P')
    ColoCount_main[119]=8
    ColoEnemyType_main[119]=FourCC('n06O')
    ColoCount_main[120]=6
    ColoEnemyType_main[120]=FourCC('n05H')
    ColoCount_sec[120]=6
    ColoEnemyType_sec[120]=FourCC('n06O')
    ColoCount_main[121]=6
    ColoEnemyType_main[121]=FourCC('n05I')
    ColoCount_sec[121]=6
    ColoEnemyType_sec[121]=FourCC('n06O')
    ColoCount_main[122]=8
    ColoEnemyType_main[122]=FourCC('n05J')
    ColoCount_main[123]=6
    ColoEnemyType_main[123]=FourCC('n05J')
    ColoCount_sec[123]=6
    ColoEnemyType_sec[123]=FourCC('n06O')
    ColoCount_main[124]=8
    ColoEnemyType_main[124]=FourCC('n05K')
    ColoCount_main[125]=6
    ColoEnemyType_main[125]=FourCC('n05K')
    ColoCount_sec[125]=6
    ColoEnemyType_sec[125]=FourCC('n06O')
    ColoCount_main[128]=4
    ColoEnemyType_main[128]=FourCC('n04Q')
    ColoCount_main[129]=8
    ColoEnemyType_main[129]=FourCC('n04Q')
    ColoCount_main[130]=6
    ColoEnemyType_main[130]=FourCC('n06W')
    ColoCount_main[131]=6
    ColoEnemyType_main[131]=FourCC('n04Q')
    ColoCount_sec[131]=4
    ColoEnemyType_sec[131]=FourCC('n06W')
    ColoCount_main[132]=6
    ColoEnemyType_main[132]=FourCC('n06X')
    ColoCount_main[133]=5
    ColoEnemyType_main[133]=FourCC('n04Q')
    ColoCount_sec[133]=4
    ColoEnemyType_sec[133]=FourCC('n06X')
    ColoCount_main[134]=4
    ColoEnemyType_main[134]=FourCC('n04R')
    ColoCount_main[135]=5
    ColoEnemyType_main[135]=FourCC('n04R')
    ColoCount_sec[135]=4
    ColoEnemyType_sec[135]=FourCC('n06X')
    ColoCount_main[136]=5
    ColoEnemyType_main[136]=FourCC('n04R')
    ColoCount_sec[136]=4
    ColoEnemyType_sec[136]=FourCC('n06W')
    ColoCount_main[137]=6
    ColoEnemyType_main[137]=FourCC('n06Y')
    ColoCount_main[138]=5
    ColoEnemyType_main[138]=FourCC('n04R')
    ColoCount_sec[138]=4
    ColoEnemyType_sec[138]=FourCC('n06Y')
    ColoCount_main[139]=6
    ColoEnemyType_main[139]=FourCC('n06Z')
    ColoCount_main[140]=5
    ColoEnemyType_main[140]=FourCC('n04R')
    ColoCount_sec[140]=4
    ColoEnemyType_sec[140]=FourCC('n06Z')
    ColoCount_main[141]=6
    ColoEnemyType_main[141]=FourCC('n04S')
    ColoCount_main[142]=5
    ColoEnemyType_main[142]=FourCC('n04S')
    ColoCount_sec[142]=4
    ColoEnemyType_sec[142]=FourCC('n06Z')
    ColoCount_main[143]=5
    ColoEnemyType_main[143]=FourCC('n04S')
    ColoCount_sec[143]=4
    ColoEnemyType_sec[143]=FourCC('n06Y')
    ColoCount_main[144]=6
    ColoEnemyType_main[144]=FourCC('n070')
    ColoCount_main[145]=5
    ColoEnemyType_main[145]=FourCC('n04S')
    ColoCount_sec[145]=4
    ColoEnemyType_sec[145]=FourCC('n070')
    ColoCount_main[146]=6
    ColoEnemyType_main[146]=FourCC('n04T')
    ColoCount_main[147]=5
    ColoEnemyType_main[147]=FourCC('n04T')
    ColoCount_sec[147]=4
    ColoEnemyType_sec[147]=FourCC('n070')
    ColoCount_main[148]=6
    ColoEnemyType_main[148]=FourCC('n071')
    ColoCount_main[149]=5
    ColoEnemyType_main[149]=FourCC('n04S')
    ColoCount_sec[149]=4
    ColoEnemyType_sec[149]=FourCC('n071')
    ColoCount_main[150]=5
    ColoEnemyType_main[150]=FourCC('n04T')
    ColoCount_sec[150]=5
    ColoEnemyType_sec[150]=FourCC('n071')
    ColoCount_main[153]=3
    ColoEnemyType_main[153]=FourCC('n07L')
    ColoCount_main[154]=6
    ColoEnemyType_main[154]=FourCC('n07L')
    ColoCount_main[155]=5
    ColoEnemyType_main[155]=FourCC('n076')
    ColoCount_main[156]=3
    ColoEnemyType_main[156]=FourCC('n076')
    ColoCount_sec[156]=3
    ColoEnemyType_sec[156]=FourCC('n07L')
    ColoCount_main[157]=8
    ColoEnemyType_main[157]=FourCC('n076')
    ColoCount_main[158]=5
    ColoEnemyType_main[158]=FourCC('n07M')
    ColoCount_main[159]=6
    ColoEnemyType_main[159]=FourCC('n077')
    ColoCount_main[160]=6
    ColoEnemyType_main[160]=FourCC('n07M')
    ColoCount_sec[160]=3
    ColoEnemyType_sec[160]=FourCC('n076')
    ColoCount_main[161]=6
    ColoEnemyType_main[161]=FourCC('n07L')
    ColoCount_sec[161]=3
    ColoEnemyType_sec[161]=FourCC('n077')
    ColoCount_main[162]=6
    ColoEnemyType_main[162]=FourCC('n07M')
    ColoCount_sec[162]=5
    ColoEnemyType_sec[162]=FourCC('n077')
    ColoCount_main[163]=6
    ColoEnemyType_main[163]=FourCC('n07O')
    ColoCount_main[164]=6
    ColoEnemyType_main[164]=FourCC('n078')
    ColoCount_main[165]=5
    ColoEnemyType_main[165]=FourCC('n07O')
    ColoCount_sec[165]=5
    ColoEnemyType_sec[165]=FourCC('n077')
    ColoCount_main[166]=5
    ColoEnemyType_main[166]=FourCC('n07M')
    ColoCount_sec[166]=5
    ColoEnemyType_sec[166]=FourCC('n078')
    ColoCount_main[167]=5
    ColoEnemyType_main[167]=FourCC('n07O')
    ColoCount_sec[167]=5
    ColoEnemyType_sec[167]=FourCC('n078')
    ColoCount_main[168]=6
    ColoEnemyType_main[168]=FourCC('n07P')
    ColoCount_main[169]=6
    ColoEnemyType_main[169]=FourCC('n079')
    ColoCount_main[170]=6
    ColoEnemyType_main[170]=FourCC('n07P')
    ColoCount_sec[170]=2
    ColoEnemyType_sec[170]=FourCC('n078')
    ColoCount_main[171]=6
    ColoEnemyType_main[171]=FourCC('n07P')
    ColoCount_sec[171]=5
    ColoEnemyType_sec[171]=FourCC('n078')
    ColoCount_main[172]=6
    ColoEnemyType_main[172]=FourCC('n07O')
    ColoCount_sec[172]=5
    ColoEnemyType_sec[172]=FourCC('n079')
    ColoCount_main[173]=5
    ColoEnemyType_main[173]=FourCC('n07P')
    ColoCount_sec[173]=5
    ColoEnemyType_sec[173]=FourCC('n079')
    ColoCount_main[174]=6
    ColoEnemyType_main[174]=FourCC('n07A')
    ColoCount_main[175]=6
    ColoEnemyType_main[175]=FourCC('n07P')
    ColoCount_sec[175]=2
    ColoEnemyType_sec[175]=FourCC('n07A')
    ColoCount_main[176]=5
    ColoEnemyType_main[176]=FourCC('n07P')
    ColoCount_sec[176]=5
    ColoEnemyType_sec[176]=FourCC('n07A')
    ColoCount_main[177]=6
    ColoEnemyType_main[177]=FourCC('n07Q')
    ColoCount_main[178]=5
    ColoEnemyType_main[178]=FourCC('n07Q')
    ColoCount_sec[178]=5
    ColoEnemyType_sec[178]=FourCC('n079')
    ColoCount_main[179]=6
    ColoEnemyType_main[179]=FourCC('n07Q')
    ColoCount_sec[179]=5
    ColoEnemyType_sec[179]=FourCC('n07A')
    ColoCount_main[182]=6
    ColoEnemyType_main[182]=FourCC('n07G')
    ColoCount_main[183]=6
    ColoEnemyType_main[183]=FourCC('n07N')
    ColoCount_main[184]=4
    ColoEnemyType_main[184]=FourCC('n07G')
    ColoCount_sec[184]=4
    ColoEnemyType_sec[184]=FourCC('n07N')
    ColoCount_main[185]=6
    ColoEnemyType_main[185]=FourCC('n07H')
    ColoCount_main[186]=4
    ColoEnemyType_main[186]=FourCC('n07H')
    ColoCount_sec[186]=4
    ColoEnemyType_sec[186]=FourCC('n07N')
    ColoCount_main[187]=6
    ColoEnemyType_main[187]=FourCC('n09U')
    ColoCount_main[188]=4
    ColoEnemyType_main[188]=FourCC('n07G')
    ColoCount_sec[188]=4
    ColoEnemyType_sec[188]=FourCC('n09U')
    ColoCount_main[189]=4
    ColoEnemyType_main[189]=FourCC('n07H')
    ColoCount_sec[189]=4
    ColoEnemyType_sec[189]=FourCC('n09U')
    ColoCount_main[190]=7
    ColoEnemyType_main[190]=FourCC('n07I')
    ColoCount_main[191]=5
    ColoEnemyType_main[191]=FourCC('n07I')
    ColoCount_sec[191]=4
    ColoEnemyType_sec[191]=FourCC('n09U')
    ColoCount_main[192]=7
    ColoEnemyType_main[192]=FourCC('n09V')
    ColoCount_main[193]=5
    ColoEnemyType_main[193]=FourCC('n07I')
    ColoCount_sec[193]=4
    ColoEnemyType_sec[193]=FourCC('n09V')
    ColoCount_main[194]=7
    ColoEnemyType_main[194]=FourCC('n07J')
    ColoCount_main[195]=5
    ColoEnemyType_main[195]=FourCC('n07J')
    ColoCount_sec[195]=5
    ColoEnemyType_sec[195]=FourCC('n09V')
    ColoCount_main[196]=7
    ColoEnemyType_main[196]=FourCC('n09W')
    ColoCount_main[197]=6
    ColoEnemyType_main[197]=FourCC('n07J')
    ColoCount_sec[197]=5
    ColoEnemyType_sec[197]=FourCC('n09W')
    ColoCount_main[198]=7
    ColoEnemyType_main[198]=FourCC('n09X')
    ColoCount_main[199]=6
    ColoEnemyType_main[199]=FourCC('n07J')
    ColoCount_sec[199]=6
    ColoEnemyType_sec[199]=FourCC('n09X')
    ColoCount_main[200]=7
    ColoEnemyType_main[200]=FourCC('n07K')
    ColoCount_main[201]=6
    ColoEnemyType_main[201]=FourCC('n07K')
    ColoCount_sec[201]=6
    ColoEnemyType_sec[201]=FourCC('n09W')
    ColoCount_main[202]=6
    ColoEnemyType_main[202]=FourCC('n07K')
    ColoCount_sec[202]=6
    ColoEnemyType_sec[202]=FourCC('n09X')
    ColoCount_main[203]=7
    ColoEnemyType_main[203]=FourCC('n09Y')
    ColoCount_main[204]=6
    ColoEnemyType_main[204]=FourCC('n07J')
    ColoCount_sec[204]=6
    ColoEnemyType_sec[204]=FourCC('n09Y')
    ColoCount_main[205]=6
    ColoEnemyType_main[205]=FourCC('n07K')
    ColoCount_sec[205]=6
    ColoEnemyType_sec[205]=FourCC('n09Y')
    ColoCount_main[206]=5
    ColoEnemyType_main[206]=FourCC('n07R')
    ColoCount_main[207]=3
    ColoEnemyType_main[207]=FourCC('n07R')
    ColoCount_sec[207]=6
    ColoEnemyType_sec[207]=FourCC('n09X')
    ColoCount_main[208]=5
    ColoEnemyType_main[208]=FourCC('n07R')
    ColoCount_sec[208]=6
    ColoEnemyType_sec[208]=FourCC('n09Y')
    ColoCount_main[209]=6
    ColoEnemyType_main[209]=FourCC('n09Y')
    ColoCount_main[210]=6
    ColoEnemyType_main[210]=FourCC('n07K')
    ColoCount_sec[210]=6
    ColoEnemyType_sec[210]=FourCC('n09Y')
    ColoCount_main[211]=6
    ColoEnemyType_main[211]=FourCC('n07R')
    ColoCount_sec[211]=6
    ColoEnemyType_sec[211]=FourCC('n09Y')

    NERUBIAN_QUEST = FourCC('I04M')
    POLARBEAR_QUEST = FourCC('I092')

    --quest rewards
    HeadHunter = {
        --spider armors
        [NERUBIAN_QUEST] = {
            Head = FourCC('I01E'),
            Reward = {
                FourCC('I0B8'),
                FourCC('I0BA'),
                FourCC('I0B4'),
                FourCC('I0B6'),
            },
            Level = 15,
            XP = 2000,
        },
        --polar bear items
        [POLARBEAR_QUEST] = {
            Head = FourCC('I04A'),
            Reward = {
                FourCC('I0MC'),
                FourCC('I0MD'),
                FourCC('I0FB'),
                FourCC('I05Q'),
            },
            Level = 25,
            XP = 4000,
        },
        --Hydra Head
        [FourCC('I03G')] = {
            Head = FourCC('I044'),
            Reward = FourCC('I0F8'),
            Level = 50,
            XP = 6000
        },
        --King of Ogres Head
        [FourCC('I049')] = {
            Head = FourCC('I02M'),
            Reward = FourCC('I04C'),
            Level = 50,
            XP = 6000
        },
        --Yeti Head
        [FourCC('I05N')] = {
            Head = FourCC('I05R'),
            Reward = FourCC('I03O'),
            Level = 60,
            XP = 8000
        },
        --Corrupted Bark
        [FourCC('I057')] = {
            Head = FourCC('I07J'),
            Reward = FourCC('I01B'),
            Level = 100,
            XP = 10000
        },
    }

    --trolls
    local id         = FourCC('nits') ---@type integer 
    KillQuest[0][0] = id
    KillQuest[FourCC('I07D')][0] = id
    KillQuest[id].goal = 15
    KillQuest[id].min = 1
    KillQuest[id].max = 8
    KillQuest[id].name = "Trolls"
    KillQuest[id].region = gg_rct_Troll_Demon_1
    --tuskarr
    id = FourCC('ntks')
    KillQuest[0][1] = id
    KillQuest[FourCC('I058')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 3
    KillQuest[id].max = 14
    KillQuest[id].name = "Tuskarr"
    KillQuest[id].region = gg_rct_Tuskar_Horror_1
    --spider
    id = FourCC('nnwr')
    KillQuest[0][2] = id
    KillQuest[FourCC('I05F')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 5
    KillQuest[id].max = 24
    KillQuest[id].name = "Spiders"
    KillQuest[id].region = gg_rct_Spider_Horror_3
    --ursa
    id = FourCC('nfpu')
    KillQuest[0][3] = id
    KillQuest[FourCC('I04U')][0] = id
    KillQuest[id].goal = 25
    KillQuest[id].min = 8
    KillQuest[id].max = 24
    KillQuest[id].name = "Ursae"
    KillQuest[id].region = gg_rct_Ursa_Abyssal_2
    --polar bears
    id = FourCC('nplg')
    KillQuest[0][4] = id
    KillQuest[FourCC('I04V')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 12
    KillQuest[id].max = 46
    KillQuest[id].name = "Polar Bears & Mammoths"
    KillQuest[id].region = gg_rct_Bear_2
    --tauren/ogre
    id = FourCC('n01G')
    KillQuest[0][5] = id
    KillQuest[FourCC('I05B')][0] = id
    KillQuest[id].goal = 25
    KillQuest[id].min = 20
    KillQuest[id].max = 62
    KillQuest[id].name = "Taurens & Ogres"
    KillQuest[id].region = gg_rct_OgreTauren_Void_5
    --unbroken
    id = FourCC('nubw')
    KillQuest[0][6] = id
    KillQuest[FourCC('I05L')][0] = id
    KillQuest[id].goal = 25
    KillQuest[id].min = 29
    KillQuest[id].max = 84
    KillQuest[id].name = "Unbroken"
    KillQuest[id].region = gg_rct_Unbroken_Dimensional_2
    --hellhounds
    id = FourCC('nvdl')
    KillQuest[0][7] = id
    KillQuest[FourCC('I05E')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 44
    KillQuest[id].max = 110
    KillQuest[id].name = "Hellspawn"
    KillQuest[id].region = gg_rct_Hell_4
    --centaur
    id = FourCC('n024')
    KillQuest[0][8] = id
    KillQuest[FourCC('I0GD')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 56
    KillQuest[id].max = 134
    KillQuest[id].name = "Centaurs"
    KillQuest[id].region = gg_rct_Centaur_Nightmare_5
    --magnataur
    id = FourCC('n01M')
    KillQuest[0][9] = id
    KillQuest[FourCC('I05K')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 70
    KillQuest[id].max = 162
    KillQuest[id].name = "Magnataurs"
    KillQuest[id].region = gg_rct_Magnataur_Despair_1
    --dragon
    id = FourCC('n02P')
    KillQuest[0][10] = id
    KillQuest[FourCC('I05M')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 92
    KillQuest[id].max = 182
    KillQuest[id].name = "Dragons"
    KillQuest[id].region = gg_rct_Dragon_Astral_8
    --devourers
    id = FourCC('n02L')
    KillQuest[0][11] = id
    KillQuest[FourCC('I022')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 110
    KillQuest[id].max = 198
    KillQuest[id].name = "Devourers"
    KillQuest[id].region = gg_rct_Devourer_entry
    --demons
    id = FourCC('n034')
    KillQuest[1][0] = id
    KillQuest[FourCC('I03H')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 166
    KillQuest[id].max = 256
    KillQuest[id].name = "Demons"
    KillQuest[id].region = gg_rct_Troll_Demon_1
    --horror beast
    id = FourCC('n03A')
    KillQuest[1][1] = id
    KillQuest[FourCC('I09J')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 190
    KillQuest[id].max = 260
    KillQuest[id].name = "Horror Beasts"
    KillQuest[id].region = gg_rct_Tuskar_Horror_1
    --despair
    id = FourCC('n03F')
    KillQuest[1][2] = id
    KillQuest[FourCC('I03C')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 210
    KillQuest[id].max = 280
    KillQuest[id].name = "Despairs"
    KillQuest[id].region = gg_rct_Magnataur_Despair_1
    --abyssal
    id = FourCC('n08N')
    KillQuest[1][3] = id
    KillQuest[FourCC('I02A')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 229
    KillQuest[id].max = 299
    KillQuest[id].name = "Abyssals"
    KillQuest[id].region = gg_rct_Ursa_Abyssal_2
    --void
    id = FourCC('n031')
    KillQuest[1][4] = id
    KillQuest[FourCC('I03I')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 250
    KillQuest[id].max = 320
    KillQuest[id].name = "Voids"
    KillQuest[id].region = gg_rct_OgreTauren_Void_5
    --nightmares
    id = FourCC('n020')
    KillQuest[1][5] = id
    KillQuest[FourCC('I0GE')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 270
    KillQuest[id].max = 340
    KillQuest[id].name = "Nightmares"
    KillQuest[id].region = gg_rct_Centaur_Nightmare_5
    --hellspawn
    id = FourCC('n03D')
    KillQuest[1][6] = id
    KillQuest[FourCC('I03J')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 290
    KillQuest[id].max = 360
    KillQuest[id].name = "Hellspawn"
    KillQuest[id].region = gg_rct_Hell_4
    --denied existence
    id = FourCC('n03J')
    KillQuest[1][7] = id
    KillQuest[FourCC('I02G')][0] = id
    KillQuest[id].goal = 30
    KillQuest[id].min = 310
    KillQuest[id].max = 380
    KillQuest[id].name = "Existences"
    KillQuest[id].region = gg_rct_Devourer_entry
    --astral
    id = FourCC('n03M')
    KillQuest[1][8] = id
    KillQuest[FourCC('I039')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 330
    KillQuest[id].max = 400
    KillQuest[id].name = "Astrals"
    KillQuest[id].region = gg_rct_Dragon_Astral_8
    --dimensionals
    id = FourCC('n026')
    KillQuest[1][9] = id
    KillQuest[FourCC('I0Q1')][0] = id
    KillQuest[id].goal = 20
    KillQuest[id].min = 350
    KillQuest[id].max = 420
    KillQuest[id].name = "Dimensionals"
    KillQuest[id].region = gg_rct_Unbroken_Dimensional_2

    Experience_Table = {}
    RewardGold = {}

    for i = 1, 500 do
        Experience_Table[i] = R2I(13. * i * 1.4 ^ (i / 20) + 10)
        RewardGold[i] = Experience_Table[i] ^ 0.94 / 8.
    end

    --base experience rates per 5 levels

    BaseExperience = __jarray(0) ---@type number[]
    for i = 0, 400, 5 do
        BaseExperience[i] = (i <= 10) and 425 or (BaseExperience[i - 5] - 17 / (i - 5)) * 0.919
    end

    Gold_Mod = {
        1,
        0.55 ^ 0.5,
        0.50 ^ 0.5,
        0.45 ^ 0.5,
        0.40 ^ 0.5,
        0.35 ^ 0.5,
    }

    infoString[0] = "Use -info # for see more info about your chosen catagory\n\n -info 1, Unit Respawning\n -info 2, Boss Respawning\n -info 3, Safezone\n -info 4, Hardcore\n -info 5, Hardmode\n -info 6, Prestige\n -info 7, Proficiency\n -info 8, Aggro System"
    infoString[1] = "Most units in this game (besides Bosses, Colosseum, Struggle) will attempt to revive where they died 30 seconds after death. If a player hero/unit is within 800 range they will spawn frozen and invulnerable until no players are around."
    infoString[2] = "Bosses respawn after 10 minutes and non-hero bosses respawn after 5 minutes, -hardmode speeds up respawns by 25\x25"
    infoString[3] = "The town is protected from enemy invasion and any entering enemy will be teleported back to their original spawn."
    infoString[4] = [[Hardcore players that die without a reincarnation item/spell will be removed from the game and cannot save/load or start a new character. 
    A hardcore hero can only save every 30 minutes- the timer starts upon saving OR upon loading your hardcore hero. 
    Hardcore heroes receive double the bonus from prestiging.
    If you need to save before the timer expires you can use -forcesave to save immediately, but this deletes your hero, leaving you unable to load again in the current game (same as if your hero died).]]
    infoString[5] = [[Hardmode doubles the health and damage of bosses, doubles their drop chance, increases their gold/xp/crystal rewards, and speeds up respawn time by 25\x25.
    Does not apply to Dungeons.
    Automatically turns off when entering Chaos, but can be re-activated.]]
    infoString[6] = "You need a |cffffcc00Prestige Token|r to prestige your hero from the church.\nPrestige Talent points are awarded and can be accessed with -prestige.\nPrestige bonuses apply to all of your characters and any new ones."
    infoString[7] = [[Most items in this game have a proficiency requirement in their description.
    While any hero can equip them regardless of proficiency, those lacking proficiency only recieve half stats from the item.
    Check your hero's proficiency with -pf.]]
    infoString[8] = [[Bosses use a threat meter system for each player that increases when attacked or by casting spells. Distance from the boss reduces the threat you 
    generate significantly when attacking, so melee characters will draw aggro much more quickly-- especially with taunt abilities.]]
    infoString[69] = "Nice"

    prMulti[0] = FourCC('A0A3')
    prMulti[1] = FourCC('A0IW')
    prMulti[2] = FourCC('A0IX')
    prMulti[3] = FourCC('A0IY')
    prMulti[4] = FourCC('A0IZ')

    --currencies
    CURRENCY_ICON[0] = "gold.dds"
    CURRENCY_ICON[1] = "wood.dds"
    CURRENCY_ICON[2] = "plat.dds"
    CURRENCY_ICON[3] = "arc.dds"
    CURRENCY_ICON[4] = "crystal.dds"

    --TODO expand channel fields?

    SPELL_FIELD = {} ---@type abilityreallevelfield[] 
    SPELL_FIELD[0] = ABILITY_RLF_ART_DURATION
    SPELL_FIELD[1] = ABILITY_RLF_AREA_OF_EFFECT
    SPELL_FIELD[2] = ABILITY_RLF_CAST_RANGE
    SPELL_FIELD[3] = ABILITY_RLF_CASTING_TIME
    SPELL_FIELD[4] = ABILITY_RLF_COOLDOWN
    SPELL_FIELD[5] = ABILITY_RLF_DURATION_HERO
    SPELL_FIELD[6] = ABILITY_RLF_DURATION_NORMAL
    SPELL_FIELD_TOTAL = 6 ---@type integer 

    TIER_NAME= {} ---@type string[] 
    TYPE_NAME= {} ---@type string[] 
    ITEM_MODEL= {} ---@type integer[] 
    LEVEL_PREFIX= {} ---@type string[] 
    SPRITE_RARITY= {} ---@type string[] 
    ITEM_MULT= {} ---@type number[] 
    CRYSTAL_PRICE= {} ---@type integer[] 
    LIMIT_STRING= {} ---@type string[] 

    TIER_NAME[0] = ""
    TIER_NAME[1] = "Common"
    TIER_NAME[2] = "|cffbbbbbbUncommon|r"
    TIER_NAME[3] = "|cffffff00Quest|r"
    TIER_NAME[4] = "|cff999999Ursa|r"
    TIER_NAME[5] = "|cff999999Ogre|r"
    TIER_NAME[6] = "|cff999999Unbroken|r"
    TIER_NAME[7] = "|cff999999Magnataur|r"
    TIER_NAME[8] = "|cff55ff44Set|r"
    TIER_NAME[9] = "|cffba0505Boss|r"
    TIER_NAME[10] = "|cff01b9f5Divine|r"
    TIER_NAME[11] = "|cffff5050Chaotic Quest|r"
    TIER_NAME[12] = "Demon"
    TIER_NAME[13] = "Horror"
    TIER_NAME[14] = "Despair"
    TIER_NAME[15] = "Abyssal"
    TIER_NAME[16] = "Void"
    TIER_NAME[17] = "Nightmare"
    TIER_NAME[18] = "Hell"
    TIER_NAME[19] = "Existence"
    TIER_NAME[20] = "Astral"
    TIER_NAME[21] = "Dimensional"
    TIER_NAME[22] = "|cff05aa05Chaotic Set|r"
    TIER_NAME[23] = "|cff700909Chaotic Boss|r"
    TIER_NAME[24] = "|cffa0a0a0Forgotten|r"
    TIER_NAME[25] = "|cff999999Devourer|r"
    --...
    TYPE_NAME[0] = "All"
    TYPE_NAME[1] = "Plate"
    TYPE_NAME[2] = "Fullplate"
    TYPE_NAME[3] = "Leather"
    TYPE_NAME[4] = "Cloth"
    TYPE_NAME[5] = "Shield"
    TYPE_NAME[6] = "Heavy"
    TYPE_NAME[7] = "Sword"
    TYPE_NAME[8] = "Dagger"
    TYPE_NAME[9] = "Bow"
    TYPE_NAME[10] = "Staff"
    --...
    ITEM_MODEL[1] = FourCC('rar1')
    ITEM_MODEL[2] = FourCC('rar1')
    ITEM_MODEL[3] = FourCC('rar1')
    ITEM_MODEL[4] = FourCC('rar1')
    ITEM_MODEL[5] = FourCC('rar2')
    ITEM_MODEL[6] = FourCC('rar2')
    ITEM_MODEL[7] = FourCC('rar2')
    ITEM_MODEL[8] = FourCC('rar2')
    ITEM_MODEL[9] = FourCC('rar3')
    ITEM_MODEL[10] = FourCC('rar3')
    ITEM_MODEL[11] = FourCC('rar3')
    ITEM_MODEL[12] = FourCC('rar3')
    ITEM_MODEL[13] = FourCC('rar4')
    ITEM_MODEL[14] = FourCC('rar4')
    ITEM_MODEL[15] = FourCC('rar4')
    ITEM_MODEL[16] = FourCC('rar4')
    ITEM_MODEL[17] = FourCC('rar5')
    ITEM_MODEL[18] = FourCC('rar5')
    ITEM_MODEL[19] = FourCC('rar5')
    ITEM_MODEL[20] = FourCC('rar5')
    --...
    LEVEL_PREFIX[1] = "|cff40bf5fRefined|r"
    LEVEL_PREFIX[2] = "|cff40bf5fRefined|r"
    LEVEL_PREFIX[3] = "|cff40bf5fRefined|r"
    LEVEL_PREFIX[4] = "|cff40bf5fRefined|r"
    LEVEL_PREFIX[5] = "|cff4087bfRare|r"
    LEVEL_PREFIX[6] = "|cff4087bfRare|r"
    LEVEL_PREFIX[7] = "|cff4087bfRare|r"
    LEVEL_PREFIX[8] = "|cff4087bfRare|r"
    LEVEL_PREFIX[9] = "|cff7040bfEpic|r"
    LEVEL_PREFIX[10] = "|cff7040bfEpic|r"
    LEVEL_PREFIX[11] = "|cff7040bfEpic|r"
    LEVEL_PREFIX[12] = "|cff7040bfEpic|r"
    LEVEL_PREFIX[13] = "|cffbf6b40Legendary|r"
    LEVEL_PREFIX[14] = "|cffbf6b40Legendary|r"
    LEVEL_PREFIX[15] = "|cffbf6b40Legendary|r"
    LEVEL_PREFIX[16] = "|cffbf6b40Legendary|r"
    LEVEL_PREFIX[17] = "|cffc41919Chaos|r"
    LEVEL_PREFIX[18] = "|cffc41919Chaos|r"
    LEVEL_PREFIX[19] = "|cffc41919Chaos|r"
    LEVEL_PREFIX[20] = "|cffc41919Chaos|r"
    --...
    SPRITE_RARITY[0] = "war3mapImported\\CommonBorder.dds"
    SPRITE_RARITY[1] = "war3mapImported\\RefinedBorder.dds"
    SPRITE_RARITY[2] = "war3mapImported\\RefinedBorder.dds"
    SPRITE_RARITY[3] = "war3mapImported\\RefinedBorder.dds"
    SPRITE_RARITY[4] = "war3mapImported\\RefinedBorder.dds"
    SPRITE_RARITY[5] = "war3mapImported\\RareBorder.dds"
    SPRITE_RARITY[6] = "war3mapImported\\RareBorder.dds"
    SPRITE_RARITY[7] = "war3mapImported\\RareBorder.dds"
    SPRITE_RARITY[8] = "war3mapImported\\RareBorder.dds"
    SPRITE_RARITY[9] = "war3mapImported\\EpicBorder.dds"
    SPRITE_RARITY[10] = "war3mapImported\\EpicBorder.dds"
    SPRITE_RARITY[11] = "war3mapImported\\EpicBorder.dds"
    SPRITE_RARITY[12] = "war3mapImported\\EpicBorder.dds"
    SPRITE_RARITY[13] = "war3mapImported\\LegendaryBorder.dds"
    SPRITE_RARITY[14] = "war3mapImported\\LegendaryBorder.dds"
    SPRITE_RARITY[15] = "war3mapImported\\LegendaryBorder.dds"
    SPRITE_RARITY[16] = "war3mapImported\\LegendaryBorder.dds"
    SPRITE_RARITY[17] = "war3mapImported\\ChaosBorder.dds"
    SPRITE_RARITY[18] = "war3mapImported\\ChaosBorder.dds"
    SPRITE_RARITY[19] = "war3mapImported\\ChaosBorder.dds"
    SPRITE_RARITY[20] = "war3mapImported\\ChaosBorder.dds"
    --...
    ITEM_MULT[0] = 0
    ITEM_MULT[1] = 0.2
    ITEM_MULT[2] = 0.4
    ITEM_MULT[3] = 0.6
    ITEM_MULT[4] = 0.8
    ITEM_MULT[5] = 1.2
    ITEM_MULT[6] = 1.6
    ITEM_MULT[7] = 2.
    ITEM_MULT[8] = 2.4
    ITEM_MULT[9] = 3.2
    ITEM_MULT[10] = 4.
    ITEM_MULT[11] = 4.8
    ITEM_MULT[12] = 5.6
    ITEM_MULT[13] = 7.
    ITEM_MULT[14] = 8.4
    ITEM_MULT[15] = 9.8
    ITEM_MULT[16] = 11.2
    ITEM_MULT[17] = 13.4
    ITEM_MULT[18] = 15.6
    ITEM_MULT[19] = 17.8
    --...
    CRYSTAL_PRICE[0] = 1
    CRYSTAL_PRICE[1] = 1
    CRYSTAL_PRICE[2] = 2
    CRYSTAL_PRICE[3] = 2
    CRYSTAL_PRICE[4] = 3
    CRYSTAL_PRICE[5] = 3
    CRYSTAL_PRICE[6] = 4
    CRYSTAL_PRICE[7] = 5
    CRYSTAL_PRICE[8] = 6
    CRYSTAL_PRICE[9] = 8
    CRYSTAL_PRICE[10] = 12
    CRYSTAL_PRICE[11] = 16
    CRYSTAL_PRICE[12] = 24
    CRYSTAL_PRICE[13] = 32
    CRYSTAL_PRICE[14] = 48
    CRYSTAL_PRICE[15] = 64
    CRYSTAL_PRICE[16] = 80
    CRYSTAL_PRICE[17] = 96
    CRYSTAL_PRICE[18] = 128
    CRYSTAL_PRICE[19] = 160
    --...
    PROF = {
        PROF_PLATE,
        PROF_FULLPLATE,
        PROF_LEATHER,
        PROF_CLOTH,
        PROF_SHIELD,
        PROF_HEAVY,
        PROF_SWORD,
        PROF_DAGGER,
        PROF_BOW,
        PROF_STAFF,
    }
    PROF[0] = 0

    --types: 1 - power, 2 - utility, 3 - player only, 4 - hidden
    STAT_TAG = {
        [ITEM_HEALTH]            = {
            tag = "|cffff0000Health|r", type = 1, syntax = "health",
            getter = function(u) return RealToString(GetWidgetLife(u)) .. " / " .. RealToString(BlzGetUnitMaxHP(u)) end},
        [ITEM_MANA]              = {
            tag = "|cff6699ffMana|r", type = 1, syntax = "mana",
            getter = function(u) return RealToString(GetUnitState(u, UNIT_STATE_MANA)) .. " / " .. RealToString(GetUnitState(u, UNIT_STATE_MAX_MANA)) end},
        [ITEM_DAMAGE]            = {
            tag = "|cffff6600Damage|r", type = 1, syntax = "damage",
            getter = function(u) return RealToString(BlzGetUnitBaseDamage(u, 0) + UnitGetBonus(u, BONUS_DAMAGE)) end},
        [ITEM_ARMOR]             = {
            tag = "|cffa4a4feArmor|r", type = 1, syntax = "armor",
            getter = function(u) return RealToString(BlzGetUnitArmor(u)) end},
        [ITEM_STRENGTH]          = {
            tag = "|cffbb0000Strength|r", type = 1, syntax = "str",
            getter = function(u) return RealToString(GetHeroStr(u, true)) end},
        [ITEM_AGILITY]           = {
            tag = "|cff008800Agility|r", type = 1, syntax = "agi",
            getter = function(u) return RealToString(GetHeroAgi(u, true)) end},
        [ITEM_INTELLIGENCE]      = {
            tag = "|cff2255ffIntelligence|r", type = 1, syntax = "int",
            getter = function(u) return RealToString(GetHeroInt(u, true)) end},
        [ITEM_REGENERATION]      = {
            tag = "|cffa00070Regeneration|r", type = 1, syntax = "regen",
            getter = function(u) return RealToString(Unit[u].regen) end},
        [ITEM_DAMAGE_RESIST]     = {
            tag = "|cffff8040Damage Resist|r", alternate = "|cffff8040Physical Taken|r", type = 1, suffix = "\x25", syntax = "dr",
            breakdown = function(u)
                local dtype = BlzGetUnitIntegerField(u, UNIT_IF_DEFENSE_TYPE)
                local chaos_reduc = (dtype == ARMOR_CHAOS or dtype == ARMOR_CHAOS_BOSS) and 0.03 or 1.
                local chaos = (chaos_reduc == 0.03 and "\n|cffffcc00Chaos Reduction:|r " .. R2S((1. - chaos_reduc) * 100) .. "\x25" or "")

                return "|cffffcc00Base Reduction:|r " .. R2S(100. - (HeroStats[GetUnitTypeId(u)].phys_resist) * 100.)  .. "\x25" ..
                "\n|cffffcc00Spell/Item Reduction:|r " .. R2S(100. - (Unit[u].dr * Unit[u].pr) * 100. / HeroStats[GetUnitTypeId(u)].phys_resist)  .. "\x25" ..
                "\n|cffffcc00Armor Reduction:|r " .. R2S(((0.05 * BlzGetUnitArmor(u)) / (1. + 0.05 * BlzGetUnitArmor(u))) * 100.)  .. "\x25" ..
                chaos ..
                "\n|cffffcc00Total Reduction:|r " .. R2S(100. - (Unit[u].dr * Unit[u].pr) * 100. * (1. - ((0.05 * BlzGetUnitArmor(u)) / (1. + 0.05 * BlzGetUnitArmor(u)))) * chaos_reduc) .. "\x25"
            end,
            getter = function(u)
                local dtype = BlzGetUnitIntegerField(u, UNIT_IF_DEFENSE_TYPE)
                local chaos_reduc = (dtype == ARMOR_CHAOS or dtype == ARMOR_CHAOS_BOSS) and 0.03 or 1.

                return R2S((Unit[u].dr * Unit[u].pr) * 100. * (1. - ((0.05 * BlzGetUnitArmor(u)) / (1. + 0.05 * BlzGetUnitArmor(u)))) * chaos_reduc)
            end},
        [ITEM_MAGIC_RESIST]      = {
            tag = "|cff8000ffMagic Resist|r", alternate = "|cff8000ffMagical Taken|r", type = 1, suffix = "\x25", syntax = "mr",
            breakdown = function(u)
                local dtype = BlzGetUnitIntegerField(u, UNIT_IF_DEFENSE_TYPE)
                local chaos_reduc = (dtype == ARMOR_CHAOS or dtype == ARMOR_CHAOS_BOSS) and 0.03 or 1.
                local chaos = (chaos_reduc == 0.03 and "\n|cffffcc00Chaos Reduction:|r " .. R2S((1. - chaos_reduc) * 100) .. "\x25" or "")

                return "|cffffcc00Base Reduction:|r " .. R2S(100. - (HeroStats[GetUnitTypeId(u)].magic_resist) * 100.)  .. "\x25" ..
                "\n|cffffcc00Spell/Item Reduction:|r " .. R2S(100. - (Unit[u].dr * Unit[u].mr) * 100. / HeroStats[GetUnitTypeId(u)].magic_resist)  .. "\x25" ..
                chaos ..
                "\n|cffffcc00Total Reduction:|r " .. R2S(100. - (Unit[u].dr * Unit[u].mr) * 100. * chaos_reduc) .. "\x25"
            end,
            getter = function(u)
                local dtype = BlzGetUnitIntegerField(u, UNIT_IF_DEFENSE_TYPE)
                local chaos_reduc = (dtype == ARMOR_CHAOS or dtype == ARMOR_CHAOS_BOSS) and 0.03 or 1.

                return R2S((Unit[u].dr * Unit[u].mr) * 100. * chaos_reduc) end},
        [ITEM_DAMAGE_MULT]       = {
            tag = "|cffff8040Physical Dealt|r", type = 1, suffix = "\x25", syntax = "dm",
            getter = function(u) return R2S((Unit[u].dm * Unit[u].pm) * 100.) end},
        [ITEM_MAGIC_MULT]        = {
            tag = "|cff8000ffMagic Dealt|r", type = 1, suffix = "\x25", syntax = "mm",
            getter = function(u) return R2S((Unit[u].dm * Unit[u].mm) * 100.) end},
        [ITEM_MOVESPEED]         = {
            tag = "|cff888888Movespeed|r", type = 2, syntax = "ms",
            getter = function(u) return RealToString(Unit[u].movespeed) end},
        [ITEM_EVASION]           = {
            tag = "|cff008080Evasion|r", type = 2, suffix = "\x25", syntax = "evasion",
            getter = function(u) return math.min(100, (Unit[u].evasion)) end},
        [ITEM_SPELLBOOST]        = {
            tag = "|cff80ffffSpellboost|r", type = 1, suffix = "\x25", syntax = "spellboost",
            getter = function(u) local pid = GetPlayerId(GetOwningPlayer(u)) + 1 return R2S(Unit[u].spellboost * 100.) end},
        [ITEM_CRIT_CHANCE]       = {
            tag = "|cffffcc00Critical Chance|r", type = 1, suffix = "\x25", syntax = "cc",
            getter = function(u) return R2S(Unit[u].cc) end},
        [ITEM_CRIT_DAMAGE]       = {
            tag = "|cffffcc00Critical Damage|r", type = 1, suffix = "\x25", syntax = "cd",
            getter = function(u) return R2S(Unit[u].cd) end},
        [ITEM_CRIT_CHANCE_MULT]  = {
            tag = "|cffffcc00Critical Chance Multiplier|r", type = 4, suffix = "\x25", syntax = "cc_percent",
            getter = function(u) return R2S(Unit[u].cc) end},
        [ITEM_CRIT_DAMAGE_MULT]  = {
            tag = "|cffffcc00Critical Damage Multiplier|r", type = 4, suffix = "\x25", syntax = "cd_percent",
            getter = function(u) return R2S(Unit[u].cd * 100.) end},
        [ITEM_BASE_ATTACK_SPEED] = {
            tag = "|cff446600Base Attack Speed|r", type = 1, item_suffix = "\x25", syntax = "bat",
            getter = function(u) local as = 1 / BlzGetUnitAttackCooldown(u, 0) return R2S(as) .. " attacks per second" end},
        [ITEM_GOLD_GAIN]         = {
            tag = "|cffffff00Gold Find|r", type = 3, suffix = "\x25", syntax = "gold",
            getter = function(u) local pid = GetPlayerId(GetOwningPlayer(u)) + 1 return ItemGoldRate[pid] end},
        [ITEM_ABILITY]           = {
            type = 4, syntax = "abil"},
        [ITEM_ABILITY2]          = {
            type = 4, syntax = "abiltwo"},
        [ITEM_TOOLTIP]           = {
            type = 4, syntax = ""},
        [ITEM_NOCRAFT]           = {
            type = 4, syntax = "nocraft"},
        [ITEM_TIER]              = {
            type = 4, syntax = "tier"},
        [ITEM_TYPE]              = {
            type = 4, syntax = "type"},
        [ITEM_UPGRADE_MAX]       = {
            type = 4, syntax = "upg"},
        [ITEM_LEVEL_REQUIREMENT] = {
            type = 4, syntax = "req"},
        [ITEM_LIMIT]             = {
            type = 4, syntax = "limit"},
        [ITEM_COST]              = {
            type = 4, syntax = "cost"},
        [ITEM_DISCOUNT]          = {
            type = 4, syntax = "discount"},
        [ITEM_STACK]             = {
            type = 4, syntax = "stack"},
        [ITEM_STACK + 1]     = {
            tag = "|cff446600Total Attack Speed|r", type = 1,
            getter = function(u) local as = (1 / BlzGetUnitAttackCooldown(u, 0)) * (1 + math.min(GetHeroAgi(u, true), 400) * 0.01) return R2S(as) .. " attacks per second" end},
        [ITEM_STACK + 2]     = {
            tag = "|cff808080Experience Rate|r", type = 3,
            getter = function(u) local pid = GetPlayerId(GetOwningPlayer(u)) + 1 return R2S(XP_Rate[pid]) end},
        [ITEM_STACK + 3]     = {
            tag = "|cff808080Colosseum XP Rate|r", type = 3, suffix = "\x25",
            getter = function(u) local pid = GetPlayerId(GetOwningPlayer(u)) + 1 return R2S(Colosseum_XP[pid] * 100.) end},
        [ITEM_STACK + 4]     = {
            tag = "|cff808000Hero Time Played|r", type = 3,
            getter = function(u) local pid = GetPlayerId(GetOwningPlayer(u)) + 1 return (Profile[pid].hero.time // 60) .. " hours and " .. ModuloInteger(Profile[pid].hero.time, 60) .. " minutes" end},
        [ITEM_STACK + 5]     = {
            tag = "|cff808000Total Time Played|r", type = 3,
            getter = function(u) local pid = GetPlayerId(GetOwningPlayer(u)) + 1 return (Profile[pid].hero.time // 60) .. " hours and " .. ModuloInteger(Profile[pid].hero.time, 60) .. " minutes" end},
    }

    LIMIT_STRING[1] = "You can only wear one of this item."
    LIMIT_STRING[2] = "You only have two feet"
    LIMIT_STRING[3] = "A second set of wings won't help you fly better"
    LIMIT_STRING[4] = "You can only wear one Bloody armor"
    LIMIT_STRING[5] = "You can only use one Bloody weapon"
    LIMIT_STRING[6] = "You can only wear one Absolute Horror armor"
    LIMIT_STRING[7] = "You can only use one Absolute Horror weapon"
    LIMIT_STRING[8] = "You can only wear one Legion armor"
    LIMIT_STRING[9] = "You can only use one Legion weapon"
    LIMIT_STRING[10] = "You can only wear one Azazoth armor"
    LIMIT_STRING[11] = "You can only use one Azazoth weapon"
    LIMIT_STRING[12] = "You can only use one Slaughterer weapon"
    LIMIT_STRING[13] = "You can only hold one Forgotten gem"
    LIMIT_STRING[14] = "You can only wear one Ursine Set"
    LIMIT_STRING[15] = "You can only wear one Ogre Set"
    LIMIT_STRING[16] = "You can only wear one Unbroken Set"
    LIMIT_STRING[17] = "You can only wear one Magnataur Set"
    LIMIT_STRING[18] = "You can only wear one Demon Set"
    LIMIT_STRING[19] = "You can only wear one Horror Set"
    LIMIT_STRING[20] = "You can only wear one Despair Set"
    LIMIT_STRING[21] = "You can only wear one Abyssal Set"
    LIMIT_STRING[22] = "You can only wear one Void Set"
    LIMIT_STRING[23] = "You can only wear one Nightmare Set"
    LIMIT_STRING[24] = "You can only wear one Hell Set"
    LIMIT_STRING[25] = "You can only wear one Existence Set"
    LIMIT_STRING[26] = "You can only wear one Astral Set"
    LIMIT_STRING[27] = "You can only wear one Dimensional Set"
    LIMIT_STRING[28] = "You can only wear one Devourer Set"

    --hints
    HINT_TOOLTIP = { ---@type string[]
        "|cffc0c0c0Every 30 minutes the game will check for AFK players, so if you see a text box appear, type the characters it displays after a hyphen (-????)|r",
        "|cffc0c0c0Did you know?|r |cff9966ffCoT RPG|r |cffc0c0c0has a discord!|r |cff9ebef5https://discord.gg/peSTvTd|r",
        "|cffc0c0c0If you find your experience rate dropping, try upgrading to a better home.|r",
        "|cffc0c0c0Game too easy for you? Select|r |cff9966ffHardcore|r |cffc0c0c0on character creation to increase difficulty & increase benefits.|r",
        "|cffc0c0c0Type|r |cff9966ff-info|r |cffc0c0c0or|r check |cff9966ffF9|r |cffc0c0c0to for important game information, especially if you are new.|r",
        "|cffc0c0c0After an item drops it will be removed after 10 minutes, but don’t worry if you’ve already picked it up or bound it with your hero as they will not delete.|r",
        "|cffc0c0c0Game too difficult? We recommend playing with 2+ players. If you are playing solo, consider playing online with friends or others.|r",
        "|cffc0c0c0Enemies that respawn will appear as ghosts if you are too close, however if you walk away they will return to normal.|r",
        "|cffc0c0c0There’s a few items in game with a significantly lower level requirement, though they are typically harder to acquire.|r",
        "|cffc0c0c0You can type|r |cff9966ff-hints|r or |cff9966ff-nohints|r |cffc0c0c0to toggle these messages on and off.|r",
        "|cffc0c0c0Once you challenge the gods you cannot flee.|r",
        "|cffc0c0c0Some artifacts remain frozen in ice, waiting to be recovered...|r",
        "|cffc0c0c0Your colosseum experience rate will drop the more you participate, recover it by gaining experience outside of colosseum.|r",
        "|cffc0c0c0Spellboost innately affects the damage of your spells by plus or minus 20\x25.|r",
        "|cffc0c0c0Critical strike items and spells can stack their effect, the multipliers are additive.|r",
        "|cffc0c0c0The Ashen Vat is a mysterious crafting device located in the north-west tower.|r",
        "|cffc0c0c0The actions menu (Z on your hero) provides many useful settings such as displaying allied hero portraits on the left.|r",
        "|cffc0c0c0Toggling off your auto attacks with -aa helps reduce the likelihood of drawing aggro, -info 8 for more information.|r",
        "|cffc0c0c0If you meant to load another hero and you haven't left the church, you can type|r |cff9966ff-repick|r |cffc0c0c0and then|r |cff9966ff-load|r |cffc0c0c0to load another hero.|r",
        "|cffc0c0c0Hold |cff9966ffLeft Alt|r |cffc0c0c0while viewing your abilites to see how they are affected by Spellboost.|r"
    }

    LAST_HINT = 0
    FORCE_HINT = CreateForce() ---@type force 

    PrestigeTable = array2d(0) ---@type table

    local U = User.first

    while U do
        ForceAddPlayer(FORCE_HINT, U.player)
        U = U.next
    end
end, Debug and Debug.getLine())
