if Debug then Debug.beginFile 'Variables' end

OnInit.global("Variables", function(require)
    require 'Users'

    LIBRARY_dev = true
    MAP_NAME = "CoT Nevermore" ---@type string 
    SAVE_LOAD_VERSION                  = 1 ---@type integer 
    TIME = 0 ---@type integer 

    PLAYER_CAP                         = 6 ---@type integer 
    MAX_LEVEL                          = 400 ---@type integer 
    LEECH_CONSTANT                     = 50 ---@type integer 
    CALL_FOR_HELP_RANGE                = 800. ---@type number 
    NEARBY_BOSS_RANGE                  = 2500. ---@type number 
    MIN_LIFE                           = 0.406 ---@type number 
    PLAYER_TOWN                        = 8 ---@type integer 
    PLAYER_BOSS                        = 11 ---@type integer 
    FOE_ID                             = PLAYER_NEUTRAL_AGGRESSIVE + 1 ---@type integer 
    BOSS_ID                            = PLAYER_BOSS + 1 ---@type integer 
    TOWN_ID                            = PLAYER_TOWN + 1 ---@type integer 
    FPS_32                             = 0.03125 ---@type number 
    FPS_64                             = 0.015625 ---@type number 

    --units
    DUMMY                              = FourCC('e011') ---@type integer 
    GRAVE                              = FourCC('H01G') ---@type integer 
    BACKPACK                           = FourCC('H05D') ---@type integer 
    HERO_PHOENIX_RANGER                = FourCC('E00X') ---@type integer 
    HERO_ROYAL_GUARDIAN                = FourCC('H04Z') ---@type integer 
    HERO_ARCANE_WARRIOR                = FourCC('H05B') ---@type integer 
    HERO_MASTER_ROGUE                  = FourCC('E015') ---@type integer 
    HERO_ELEMENTALIST                  = FourCC('E00W') ---@type integer 
    HERO_HIGH_PRIEST                   = FourCC('E012') ---@type integer 
    HERO_DARK_SUMMONER                 = FourCC('O02S') ---@type integer 
    HERO_SAVIOR                        = FourCC('H01N') ---@type integer 
    HERO_DARK_SAVIOR                   = FourCC('H01S') ---@type integer 
    HERO_ASSASSIN                      = FourCC('E002') ---@type integer 
    HERO_BARD                          = FourCC('H00R') ---@type integer 
    HERO_ARCANIST                      = FourCC('H029') ---@type integer 
    HERO_OBLIVION_GUARD                = FourCC('H02A') ---@type integer 
    HERO_THUNDERBLADE                  = FourCC('O03J') ---@type integer 
    HERO_BLOODZERKER                   = FourCC('H03N') ---@type integer 
    HERO_MARKSMAN                      = FourCC('E008') ---@type integer 
    HERO_HYDROMANCER                   = FourCC('E00G') ---@type integer 
    HERO_WARRIOR                       = FourCC('H012') ---@type integer 
    HERO_DRUID                         = FourCC('O018') ---@type integer 
    HERO_DARK_SAVIOR_DEMON             = FourCC('E01M') ---@type integer 
    HERO_MARKSMAN_SNIPER               = FourCC('E00F')  ---@type integer 
    HERO_VAMPIRE                       = FourCC('U003')  ---@type integer 
    HERO_TOTAL                         = 19 ---@type integer 
    SUMMON_DESTROYER                   = FourCC('E014') ---@type integer 
    SUMMON_HOUND                       = FourCC('H05F') ---@type integer 
    SUMMON_GOLEM                       = FourCC('H05G') ---@type integer 

    --proficiencies
    PROF_PLATE                         = 0x1 ---@type integer 
    PROF_FULLPLATE                     = 0x2 ---@type integer 
    PROF_LEATHER                       = 0x4 ---@type integer 
    PROF_CLOTH                         = 0x8 ---@type integer 
    PROF_SHIELD                        = 0x10 ---@type integer 
    PROF_HEAVY                         = 0x20 ---@type integer 
    PROF_SWORD                         = 0x40 ---@type integer 
    PROF_DAGGER                        = 0x80 ---@type integer 
    PROF_BOW                           = 0x100 ---@type integer 
    PROF_STAFF                         = 0x200 ---@type integer 

    --currency
    GOLD                               = 0 ---@type integer 
    LUMBER                             = 1 ---@type integer 
    PLATINUM                           = 2 ---@type integer 
    ARCADITE                           = 3 ---@type integer 
    CRYSTAL                            = 4 ---@type integer 
    CURRENCY_COUNT                     = 5 ---@type integer 

    --bosses
    BOSS_TAUREN                        = 0 ---@type integer 
    BOSS_DEMON_PRINCE                  = 0 ---@type integer 
    BOSS_MYSTIC                        = 1 ---@type integer 
    BOSS_ABSOLUTE_HORROR               = 1 ---@type integer 
    BOSS_HELLFIRE                      = 2 ---@type integer 
    BOSS_ORSTED                        = 2 ---@type integer 
    BOSS_SLAUGHTER_QUEEN               = 3 ---@type integer 
    BOSS_DWARF                         = 3 ---@type integer 
    BOSS_SATAN                         = 4 ---@type integer 
    BOSS_PALADIN                       = 4 ---@type integer 
    BOSS_DARK_SOUL                     = 5 ---@type integer 
    BOSS_DRAGOON                       = 5 ---@type integer 
    BOSS_LEGION                        = 6 ---@type integer 
    BOSS_DEATH_KNIGHT                  = 6 ---@type integer 
    BOSS_THANATOS                      = 7 ---@type integer 
    BOSS_VASHJ                         = 7 ---@type integer 
    BOSS_EXISTENCE                     = 8 ---@type integer 
    BOSS_YETI                          = 8 ---@type integer 
    BOSS_AZAZOTH                       = 9 ---@type integer 
    BOSS_OGRE                          = 9 ---@type integer 
    BOSS_XALLARATH                     = 10 ---@type integer 
    BOSS_NERUBIAN                      = 10 ---@type integer 
    BOSS_POLAR_BEAR                    = 11 ---@type integer 
    BOSS_LIFE                          = 12 ---@type integer 
    BOSS_HATE                          = 13 ---@type integer 
    BOSS_LOVE                          = 14 ---@type integer 
    BOSS_KNOWLEDGE                     = 15 ---@type integer 
    BOSS_GODSLAYER                     = 16 ---@type integer 
    BOSS_TOTAL                         = 16 ---@type integer 

    --items
    MAX_REINCARNATION_CHARGES          = 3 ---@type integer 
    BOUNDS_OFFSET                      = 50  ---@type integer --leaves room for 50 different values per stat? (overkill?)
    ABILITY_OFFSET                     = 100 ---@type integer 
    QUALITY_SAVED                      = 7 ---@type integer 
    ITEM_TOOLTIP                       = 0 ---@type integer 
    ITEM_TIER                          = 1 ---@type integer 
    ITEM_TYPE                          = 2 ---@type integer 
    ITEM_UPGRADE_MAX                   = 3 ---@type integer 
    ITEM_LEVEL_REQUIREMENT             = 4 ---@type integer 
    ITEM_HEALTH                        = 5 ---@type integer 
    ITEM_MANA                          = 6 ---@type integer 
    ITEM_DAMAGE                        = 7 ---@type integer 
    ITEM_ARMOR                         = 8 ---@type integer 
    ITEM_STRENGTH                      = 9 ---@type integer 
    ITEM_AGILITY                       = 10 ---@type integer 
    ITEM_INTELLIGENCE                  = 11 ---@type integer 
    ITEM_REGENERATION                  = 12 ---@type integer 
    ITEM_DAMAGE_RESIST                 = 13 ---@type integer 
    ITEM_MAGIC_RESIST                  = 14 ---@type integer 
    ITEM_MOVESPEED                     = 15 ---@type integer 
    ITEM_EVASION                       = 16 ---@type integer 
    ITEM_SPELLBOOST                    = 17 ---@type integer 
    ITEM_CRIT_CHANCE                   = 18 ---@type integer 
    ITEM_CRIT_DAMAGE                   = 19 ---@type integer 
    ITEM_BASE_ATTACK_SPEED             = 20 ---@type integer 
    ITEM_GOLD_GAIN                     = 21 ---@type integer 
    ITEM_ABILITY                       = 22 ---@type integer 
    ITEM_ABILITY2                      = 23 ---@type integer 
    ITEM_STAT_TOTAL                    = 23 ---@type integer 

    --hidden
    ITEM_LIMIT                         = 24 ---@type integer 
    ITEM_COST                          = 25 ---@type integer 
    ITEM_DISCOUNT                      = 26 ---@type integer 

    --quests
    KILLQUEST_NAME                     = 0 ---@type integer 
    KILLQUEST_COUNT                    = 1 ---@type integer 
    KILLQUEST_GOAL                     = 2 ---@type integer 
    KILLQUEST_MIN                      = 3 ---@type integer 
    KILLQUEST_MAX                      = 4 ---@type integer 
    KILLQUEST_REGION                   = 5 ---@type integer 
    KILLQUEST_LAST                     = 6 ---@type integer 
    KILLQUEST_STATUS                   = 7 ---@type integer 

    --unit data
    UNITDATA_COUNT                     = 0 ---@type integer 
    UNITDATA_SPAWN                     = 1 ---@type integer 

    ASHEN_VAT = nil

    abc        = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" ---@type string 
    afkInt         = 0 ---@type integer 
    Hardcore = __jarray(false)
    HardMode         = 0 ---@type integer 
    MiscHash           = InitHashtable() ---@type hashtable 
    PlayerProf           = InitHashtable() ---@type hashtable 
    pfoe        = Player(PLAYER_NEUTRAL_AGGRESSIVE) ---@type player 
    pboss        = Player(11) ---@type player 
    ChaosMode         = false ---@type boolean 
    ForcedRevive         = false ---@type boolean 
    CWLoading         = false ---@type boolean 
    TimePlayed = __jarray(0) ---@type integer[]

    --tables
    infoString=__jarray("") ---@type string[] 
    ShopkeeperDirection=__jarray("") ---@type string[] 
    IS_HD=__jarray("") ---@type string[] 
    CURRENCY_ICON=__jarray("") ---@type string[] 
    XP_Rate=__jarray(0) ---@type number[]

    BaseExperience=__jarray(0) ---@type number[] 
    POWERSOF2=__jarray(0) ---@type integer[] 

    SpellTooltips = {} ---@type table 
    Threat = {} ---@type table
    KillQuest = {} ---@type table
    ItemData = {} ---@type table
    UnitData = {} ---@type table
    ItemRewards = {} ---@type table
    ItemPrices = {} ---@type table
    CosmeticTable = {} ---@type table
    PrestigeTable = {} ---@type table
    CrystalRewards = {} ---@type table
    HeroCircle = {}

    -- nil indexes are initialized as __jarray(0)
    local mt = {
        __index = function(tbl, key)
            if rawget(tbl, key) then
                return rawget(tbl, key)
            else
                local new = __jarray(0)
                rawset(tbl, key, new)
                return new
            end
        end
    }
    setmetatable(CosmeticTable, mt)
    setmetatable(Threat, mt)

    ColoCount_main=__jarray(0) ---@type integer[] 
    ColoEnemyType_main=__jarray(0) ---@type integer[] 
    ColoCount_sec=__jarray(0) ---@type integer[] 
    ColoEnemyType_sec=__jarray(0) ---@type integer[] 
    Colosseum_XP = __jarray(0) ---@type number[]

    Zoom = __jarray(0) ---@type integer[]

    selectingHero=__jarray(false) ---@type boolean[] 
    forgottenTypes=__jarray(0) ---@type integer[] 
    forgottenCount         = 0 ---@type integer 
    forgotten_spawner      = nil ---@type unit 
    hsdummy={} ---@type unit[] 
    hslook=__jarray(0) ---@type integer[] 
    hsstat=__jarray(0) ---@type integer[] 
    hssort=__jarray(false) ---@type boolean[] 
    dSkinName=__jarray("") ---@type string[] 
    ispublic=__jarray(false) ---@type boolean[] 

    funnyList=__jarray(0) ---@type integer[] 
    funnyList[0] = -894554765
    funnyList[1] = -1291321931

    altModifier = __jarray(false) ---@type boolean[]

    funnyListTotal = 1

    charLight={} ---@type effect[] 

    RollBoard=nil ---@type leaderboard 

    colospot={} ---@type location[] 

    Hero={} ---@type unit[] 
    HeroGrave={} ---@type unit[] 
    Backpack={} ---@type unit[] 

    HeroID=__jarray(0) ---@type integer[] 
    Currency=__jarray(0) ---@type integer[] 
    prMulti=__jarray(0) ---@type integer[] 
    PercentHealBonus=__jarray(0) ---@type integer[] 
    TotalEvasion=__jarray(0) ---@type integer[] 
    BonusEvasion=__jarray(0) ---@type integer[] 
    ItemRegen=__jarray(0) ---@type integer[] 
    ShieldCount=__jarray(0) ---@type integer[] 
    RollChecks=__jarray(0) ---@type integer[] 
    HuntedLevel=__jarray(0) ---@type integer[] 
    Movespeed=__jarray(0) ---@type integer[] 
    CustomLighting=__jarray(0) ---@type integer[] 

    TotalRegen=__jarray(0) ---@type number[] 
    BuffRegen=__jarray(0) ---@type number[] 
    BoostValue=__jarray(0) ---@type number[] 
    DealtDmgBase=__jarray(0) ---@type number[] 
    PhysicalTakenBase=__jarray(0) ---@type number[] 
    PhysicalTaken=__jarray(0) ---@type number[] 
    MagicTakenBase=__jarray(0) ---@type number[] 
    MagicTaken=__jarray(0) ---@type number[] 

    MultiShot=__jarray(false) ---@type boolean[] 
    CameraLock=__jarray(false) ---@type boolean[] 
    forceSaving=__jarray(false) ---@type boolean[] 

    BOOST=__jarray(0) ---@type number[] 
    LBOOST=__jarray(0) ---@type number[] 

    TownCenter          = Location(-250., 160.) ---@type location 
    ColosseumCenter          = Location(21710., -4261.) ---@type location 
    StruggleCenter          = Location(28030., 4361.) ---@type location 
    InColo=__jarray(false) ---@type boolean[] 
    InStruggle=__jarray(false) ---@type boolean[] 
    StruggleText         = CreateTextTag() ---@type texttag 
    ColoText         = CreateTextTag() ---@type texttag 
    ColoWaveCount         = 0 ---@type integer 

    DEFAULT_LIGHTING        = "Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx" ---@type string 

    BP_DESELECT=__jarray(false) ---@type boolean[] 

    Struggle_SpawnR = {} ---@type rect[]
    Struggle_WaveU = __jarray(0) ---@type integer[]
    Struggle_WaveUN = __jarray(0) ---@type integer[]
    Struggle_Wave_SR = __jarray(0) ---@type integer[]
    StruggleGoldPer = __jarray(0) ---@type integer[]

    SYNC_PREFIX        = "S" ---@type string 
    DUMMY_LIST={} ---@type unit[] 
    DUMMY_STACK       = CreateGroup()
    DUMMY_COUNT         = 0 ---@type integer 
    DUMMY_RECYCLE_TIME      = 5. ---@type number 
    TEMP_DUMMY = nil ---@type unit 
    QUEUE_BOARD = nil ---@type multiboard
    MULTI_BOARD = nil ---@type multiboard 
    MB_SPOT=__jarray(0) ---@type integer[] 
    ColoPlayerCount         = 0 ---@type integer 
    BOOST_OFF         = false ---@type boolean 
    callbackCount         = 0 ---@type integer 
    passedValue=__jarray(0) ---@type integer[] 

    GodsEnterFlag         = false ---@type boolean 
    GodsRepeatFlag         = false ---@type boolean 
    power_crystal      = nil ---@type unit 
    god_portal      = nil ---@type unit 
    DeadGods         = 4 ---@type integer 
    BANISH_FLAG         = false ---@type boolean 

    ACQUIRE_TRIGGER         = CreateTrigger() ---@type trigger 
    afkTextVisible=__jarray(false) ---@type boolean[] 
    hardcoreClicked=__jarray(false) ---@type boolean[] 
    votingSelectYes         = CreateTrigger() ---@type trigger 
    votingSelectNo         = CreateTrigger() ---@type trigger 
    hardcoreSelectYes         = CreateTrigger() ---@type trigger 
    hardcoreSelectNo         = CreateTrigger() ---@type trigger 
    afkTextBG=nil ---@type framehandle 
    afkText=nil ---@type framehandle 
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
    fh=nil ---@type framehandle 
    menuButton=nil ---@type framehandle 
    chatButton=nil ---@type framehandle 
    questButton=nil ---@type framehandle 
    allyButton=nil ---@type framehandle 
    imageTest=nil ---@type framehandle 
    clockText=nil ---@type framehandle 
    platText=nil ---@type framehandle 
    arcText=nil ---@type framehandle 
    showhidemenu=nil ---@type framehandle 
    upperbuttonBar=nil ---@type framehandle 
    dummyFrame=nil ---@type framehandle 
    dummyTextTitle=nil ---@type framehandle 
    dummyTextValue=nil ---@type framehandle 

    hideHealth=nil ---@type framehandle 

    shieldBackdrop=nil ---@type framehandle 
    shieldText=nil ---@type framehandle 

    INVENTORYBACKDROP={} ---@type framehandle[] 

    --for async frame changes
    containerFrame = BlzFrameGetChild(BlzFrameGetChild(BlzFrameGetChild(BlzGetFrameByName("ConsoleUI", 0), 1), 5), 0)
    MAIN_SELECT_GROUP = CreateGroup()
    frames={} ---@type framehandle[] 
    units={} ---@type unit[] 
    unitsCount         = 0 ---@type integer 

    --warrior limit break frames
    LimitBreakBackdrop             = nil  ---@type framehandle 
    LimitBreakButton1             = nil  ---@type framehandle 
    LimitBreakBackdrop1             = nil  ---@type framehandle 
    TriggerLimitBreakButton1         = nil  ---@type trigger 
    LimitBreakButton2             = nil  ---@type framehandle 
    LimitBreakBackdrop2             = nil  ---@type framehandle 
    TriggerLimitBreakButton2         = nil  ---@type trigger 
    LimitBreakButton3             = nil  ---@type framehandle 
    LimitBreakBackdrop3             = nil  ---@type framehandle 
    TriggerLimitBreakButton3         = nil  ---@type trigger 
    LimitBreakButton4             = nil  ---@type framehandle 
    LimitBreakBackdrop4             = nil  ---@type framehandle 
    TriggerLimitBreakButton4         = nil  ---@type trigger 
    LimitBreakButton5             = nil  ---@type framehandle 
    LimitBreakBackdrop5             = nil  ---@type framehandle 
    TriggerLimitBreakButton5         = nil  ---@type trigger 

    LimitBreakToolBox1             = nil ---@type framehandle 
    LimitBreakToolText1             = nil ---@type framehandle 
    LimitBreakToolBox2             = nil ---@type framehandle 
    LimitBreakToolText2             = nil ---@type framehandle 
    LimitBreakToolBox3             = nil ---@type framehandle 
    LimitBreakToolText3             = nil ---@type framehandle 
    LimitBreakToolBox4             = nil ---@type framehandle 
    LimitBreakToolText4             = nil ---@type framehandle 
    LimitBreakToolBox5             = nil ---@type framehandle 
    LimitBreakToolText5             = nil ---@type framehandle 

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

    --mb
    MultiBoard             = nil ---@type framehandle 

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

    HeadHunter = {
        --Hydra Head
        [FourCC('I03G')] = {
            Head = FourCC('I044'),
            Reward = FourCC('I0F8'),
            Level = 50,
            XP = 3000
        },
        --King of Ogres Head
        [FourCC('I049')] = {
            Head = FourCC('I02M'),
            Reward = FourCC('I04C'),
            Level = 50,
            XP = 4000
        },
        --Yeti Head
        [FourCC('I05N')] = {
            Head = FourCC('I05R'),
            Reward = FourCC('I03O'),
            Level = 60,
            XP = 5000
        },
        --Minotaur Horn
        [FourCC('I04A')] = {
            Head = FourCC('I084'),
            Reward = FourCC('I03T'),
            Level = 75,
            XP = 7500
        },
        --Corrupted Bark
        [FourCC('I057')] = {
            Head = FourCC('I07J'),
            Reward = FourCC('I01B'),
            Level = 100,
            XP = 10000
        },
    }

    KillQuest[0] = {}
    KillQuest[1] = {}
    --trolls
    local id         = FourCC('nits') ---@type integer 
    KillQuest[id] = {}
    KillQuest[0][0] = id
    KillQuest[FourCC('I07D')] = {}
    KillQuest[FourCC('I07D')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 15
    KillQuest[id][KILLQUEST_MIN] = 1
    KillQuest[id][KILLQUEST_MAX] = 8
    KillQuest[id][KILLQUEST_NAME] = "Trolls"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Troll_Demon_1
    --tuskarr
    id = FourCC('ntks')
    KillQuest[id] = {}
    KillQuest[0][1] = id
    KillQuest[FourCC('I058')] = {}
    KillQuest[FourCC('I058')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 3
    KillQuest[id][KILLQUEST_MAX] = 14
    KillQuest[id][KILLQUEST_NAME] = "Tuskarr"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Tuskar_Horror_1
    --spider
    id = FourCC('nnwr')
    KillQuest[id] = {}
    KillQuest[0][2] = id
    KillQuest[FourCC('I05F')] = {}
    KillQuest[FourCC('I05F')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 5
    KillQuest[id][KILLQUEST_MAX] = 24
    KillQuest[id][KILLQUEST_NAME] = "Spiders"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Spider_Horror_3
    --ursa
    id = FourCC('nfpu')
    KillQuest[id] = {}
    KillQuest[0][3] = id
    KillQuest[FourCC('I04U')] = {}
    KillQuest[FourCC('I04U')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 25
    KillQuest[id][KILLQUEST_MIN] = 8
    KillQuest[id][KILLQUEST_MAX] = 24
    KillQuest[id][KILLQUEST_NAME] = "Ursae"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Ursa_Abyssal_2
    --polar bears
    id = FourCC('nplg')
    KillQuest[id] = {}
    KillQuest[0][4] = id
    KillQuest[FourCC('I04V')] = {}
    KillQuest[FourCC('I04V')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 12
    KillQuest[id][KILLQUEST_MAX] = 46
    KillQuest[id][KILLQUEST_NAME] = "Polar Bears & Mammoths"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Bear_2
    --tauren/ogre
    id = FourCC('n01G')
    KillQuest[id] = {}
    KillQuest[0][5] = id
    KillQuest[FourCC('I05B')] = {}
    KillQuest[FourCC('I05B')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 25
    KillQuest[id][KILLQUEST_MIN] = 20
    KillQuest[id][KILLQUEST_MAX] = 62
    KillQuest[id][KILLQUEST_NAME] = "Taurens & Ogres"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_OgreTauren_Void_5
    --unbroken
    id = FourCC('nubw')
    KillQuest[id] = {}
    KillQuest[0][6] = id
    KillQuest[FourCC('I05L')] = {}
    KillQuest[FourCC('I05L')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 25
    KillQuest[id][KILLQUEST_MIN] = 29
    KillQuest[id][KILLQUEST_MAX] = 84
    KillQuest[id][KILLQUEST_NAME] = "Unbroken"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Unbroken_Dimensional_2
    --hellhounds
    id = FourCC('nvdl')
    KillQuest[id] = {}
    KillQuest[0][7] = id
    KillQuest[FourCC('I05E')] = {}
    KillQuest[FourCC('I05E')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 44
    KillQuest[id][KILLQUEST_MAX] = 110
    KillQuest[id][KILLQUEST_NAME] = "Hellspawn"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Hell_4
    --centaur
    id = FourCC('n024')
    KillQuest[id] = {}
    KillQuest[0][8] = id
    KillQuest[FourCC('I0GD')] = {}
    KillQuest[FourCC('I0GD')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 56
    KillQuest[id][KILLQUEST_MAX] = 134
    KillQuest[id][KILLQUEST_NAME] = "Centaurs"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Centaur_Nightmare_5
    --magnataur
    id = FourCC('n01M')
    KillQuest[id] = {}
    KillQuest[0][9] = id
    KillQuest[FourCC('I05K')] = {}
    KillQuest[FourCC('I05K')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 70
    KillQuest[id][KILLQUEST_MAX] = 162
    KillQuest[id][KILLQUEST_NAME] = "Magnataurs"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Magnataur_Despair_1
    --dragon
    id = FourCC('n02P')
    KillQuest[id] = {}
    KillQuest[0][10] = id
    KillQuest[FourCC('I05M')] = {}
    KillQuest[FourCC('I05M')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 92
    KillQuest[id][KILLQUEST_MAX] = 182
    KillQuest[id][KILLQUEST_NAME] = "Dragons"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Dragon_Astral_8
    --devourers
    id = FourCC('n02L')
    KillQuest[id] = {}
    KillQuest[0][11] = id
    KillQuest[FourCC('I022')] = {}
    KillQuest[FourCC('I022')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 110
    KillQuest[id][KILLQUEST_MAX] = 198
    KillQuest[id][KILLQUEST_NAME] = "Devourers"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Devourer_entry
    --demons
    id = FourCC('n034')
    KillQuest[id] = {}
    KillQuest[1][0] = id
    KillQuest[FourCC('I03H')] = {}
    KillQuest[FourCC('I03H')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 166
    KillQuest[id][KILLQUEST_MAX] = 256
    KillQuest[id][KILLQUEST_NAME] = "Demons"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Troll_Demon_1
    --horror beast
    id = FourCC('n03A')
    KillQuest[id] = {}
    KillQuest[1][1] = id
    KillQuest[FourCC('I09J')] = {}
    KillQuest[FourCC('I09J')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 190
    KillQuest[id][KILLQUEST_MAX] = 260
    KillQuest[id][KILLQUEST_NAME] = "Horror Beasts"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Tuskar_Horror_1
    --despair
    id = FourCC('n03F')
    KillQuest[id] = {}
    KillQuest[1][2] = id
    KillQuest[FourCC('I03C')] = {}
    KillQuest[FourCC('I03C')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 210
    KillQuest[id][KILLQUEST_MAX] = 280
    KillQuest[id][KILLQUEST_NAME] = "Despairs"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Magnataur_Despair_1
    --abyssal
    id = FourCC('n08N')
    KillQuest[id] = {}
    KillQuest[1][3] = id
    KillQuest[FourCC('I02A')] = {}
    KillQuest[FourCC('I02A')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 229
    KillQuest[id][KILLQUEST_MAX] = 299
    KillQuest[id][KILLQUEST_NAME] = "Abyssals"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Ursa_Abyssal_2
    --void
    id = FourCC('n031')
    KillQuest[id] = {}
    KillQuest[1][4] = id
    KillQuest[FourCC('I03I')] = {}
    KillQuest[FourCC('I03I')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 250
    KillQuest[id][KILLQUEST_MAX] = 320
    KillQuest[id][KILLQUEST_NAME] = "Voids"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_OgreTauren_Void_5
    --nightmares
    id = FourCC('n020')
    KillQuest[id] = {}
    KillQuest[1][5] = id
    KillQuest[FourCC('I0GE')] = {}
    KillQuest[FourCC('I0GE')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 270
    KillQuest[id][KILLQUEST_MAX] = 340
    KillQuest[id][KILLQUEST_NAME] = "Nightmares"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Centaur_Nightmare_5
    --hellspawn
    id = FourCC('n03D')
    KillQuest[id] = {}
    KillQuest[1][6] = id
    KillQuest[FourCC('I03J')] = {}
    KillQuest[FourCC('I03J')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 290
    KillQuest[id][KILLQUEST_MAX] = 360
    KillQuest[id][KILLQUEST_NAME] = "Hellspawn"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Hell_4
    --denied existence
    id = FourCC('n03J')
    KillQuest[id] = {}
    KillQuest[1][7] = id
    KillQuest[FourCC('I02G')] = {}
    KillQuest[FourCC('I02G')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 30
    KillQuest[id][KILLQUEST_MIN] = 310
    KillQuest[id][KILLQUEST_MAX] = 380
    KillQuest[id][KILLQUEST_NAME] = "Existences"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Devourer_entry
    --astral
    id = FourCC('n03M')
    KillQuest[id] = {}
    KillQuest[1][8] = id
    KillQuest[FourCC('I039')] = {}
    KillQuest[FourCC('I039')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 330
    KillQuest[id][KILLQUEST_MAX] = 400
    KillQuest[id][KILLQUEST_NAME] = "Astrals"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Dragon_Astral_8
    --dimensionals
    id = FourCC('n026')
    KillQuest[id] = {}
    KillQuest[1][9] = id
    KillQuest[FourCC('I0Q1')] = {}
    KillQuest[FourCC('I0Q1')][0] = id
    KillQuest[id][KILLQUEST_GOAL] = 20
    KillQuest[id][KILLQUEST_MIN] = 350
    KillQuest[id][KILLQUEST_MAX] = 420
    KillQuest[id][KILLQUEST_NAME] = "Dimensionals"
    KillQuest[id][KILLQUEST_REGION] = gg_rct_Unbroken_Dimensional_2

    BlzLoadTOCFile("graphicsmode.toc")
    IS_HD[GetPlayerId(GetLocalPlayer()) + 1] = GetLocalizedString("IS_HD")

    Experience_Table = {}
    RewardGold = {}
    for i = 1, 500 do
        Experience_Table[i] = R2I(13. * i * 1.4 ^ (i / 20) + 10)
        RewardGold[i] = Experience_Table[i] ^ 0.94 / 8.
    end

    --base experience rates per 5 levels

    for i = 1, 400, 5 do
        BaseExperience[i] = (i <= 10) and 425 or (BaseExperience[i - 5] - 17 / (i - 5)) * 0.919
    end

    Gold_Mod = {}
    Gold_Mod[1] = 1
    Gold_Mod[2] = Pow(0.55, 0.5)
    Gold_Mod[3] = Pow(0.50, 0.5)
    Gold_Mod[4] = Pow(0.45, 0.5)
    Gold_Mod[5] = Pow(0.40, 0.5)
    Gold_Mod[6] = Pow(0.35, 0.5)

    POWERSOF2[0] = 0x1
    POWERSOF2[1] = 0x2
    POWERSOF2[2] = 0x4
    POWERSOF2[3] = 0x8
    POWERSOF2[4] = 0x10
    POWERSOF2[5] = 0x20
    POWERSOF2[6] = 0x40
    POWERSOF2[7] = 0x80
    POWERSOF2[8] = 0x100
    POWERSOF2[9] = 0x200
    POWERSOF2[10] = 0x400
    POWERSOF2[11] = 0x800
    POWERSOF2[12] = 0x1000
    POWERSOF2[13] = 0x2000
    POWERSOF2[14] = 0x4000
    POWERSOF2[15] = 0x8000
    POWERSOF2[16] = 0x10000
    POWERSOF2[17] = 0x20000
    POWERSOF2[18] = 0x40000
    POWERSOF2[19] = 0x80000
    POWERSOF2[20] = 0x100000
    POWERSOF2[21] = 0x200000
    POWERSOF2[22] = 0x400000
    POWERSOF2[23] = 0x800000
    POWERSOF2[24] = 0x1000000
    POWERSOF2[25] = 0x2000000
    POWERSOF2[26] = 0x4000000
    POWERSOF2[27] = 0x8000000
    POWERSOF2[28] = 0x10000000
    POWERSOF2[29] = 0x20000000
    POWERSOF2[30] = 0x40000000

    infoString[0] = "Use -info # for see more info about your chosen catagory\n\n -info 1, Unit Respawning\n -info 2, Boss Respawning\n -info 3, Safezone\n -info 4, Hardcore\n -info 5, Hardmode\n -info 6, Prestige\n -info 7, Proficiency\n -info 8, Aggro System"
    infoString[1] = "Most units in this game (besides Bosses, Colosseum, Struggle) will attempt to revive where they died 30 seconds after death. If a player hero/unit is within 800 range they will spawn frozen and invulnerable until no players are around."
    infoString[2] = "Bosses respawn after 10 minutes and non-hero bosses respawn after 5 minutes, -hardmode speeds up respawns by 25%"
    infoString[3] = "The town is protected from enemy invasion and any entering enemy will be teleported back to their original spawn."
    infoString[4] = [[Hardcore players that die without a reincarnation item/spell will be removed from the game and cannot save/load or start a new character. 
    A hardcore hero can only save every 30 minutes- the timer starts upon saving OR upon loading your hardcore hero. 
    Hardcore heroes receive double the bonus from prestiging.
    If you need to save before the timer expires you can use -forcesave to save immediately, but this deletes your hero, leaving you unable to load again in the current game (same as if your hero died).]]
    infoString[5] = [[Hardmode doubles the health and damage of bosses, doubles their drop chance, increases their gold/xp/crystal rewards, and speeds up respawn time by 25%.
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

    SAVE_TABLE           = InitHashtable() ---@type hashtable 
    KEY_ITEMS         = 1 ---@type integer 
    KEY_UNITS         = 2 ---@type integer 
    CUSTOM_ITEM_OFFSET         = FourCC('I000') ---@type integer 
    MAX_SAVED_ITEMS         = 8191 ---@type integer 
    MAX_SAVED_HEROES         = 63  ---@type integer --6 bits
    SAVE_UNIT_TYPE = __jarray(0) ---@type integer[] 

    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("tier"), ITEM_TIER)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("type"), ITEM_TYPE)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("upg"), ITEM_UPGRADE_MAX)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("req"), ITEM_LEVEL_REQUIREMENT)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("health"), ITEM_HEALTH)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("mana"), ITEM_MANA)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("damage"), ITEM_DAMAGE)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("armor"), ITEM_ARMOR)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("str"), ITEM_STRENGTH)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("agi"), ITEM_AGILITY)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("int"), ITEM_INTELLIGENCE)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("regen"), ITEM_REGENERATION)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("dr"), ITEM_DAMAGE_RESIST)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("mr"), ITEM_MAGIC_RESIST)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("ms"), ITEM_MOVESPEED)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("evasion"), ITEM_EVASION)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("spellboost"), ITEM_SPELLBOOST)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("cc"), ITEM_CRIT_CHANCE)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("cd"), ITEM_CRIT_DAMAGE)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("bat"), ITEM_BASE_ATTACK_SPEED)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("abil"), ITEM_ABILITY)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("abil2"), ITEM_ABILITY2)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("cost"), ITEM_COST)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("limit"), ITEM_LIMIT)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("gold"), ITEM_GOLD_GAIN)
    SaveInteger(SAVE_TABLE, KEY_ITEMS, StringHash("discount"), ITEM_DISCOUNT)

    TIER_NAME= {} ---@type string[] 
    TYPE_NAME= {} ---@type string[] 
    STAT_NAME= {} ---@type string[] 
    ITEM_MODEL= {} ---@type string[] 
    LEVEL_PREFIX= {} ---@type string[] 
    SPRITE_RARITY= {} ---@type string[] 
    ITEM_MULT= {} ---@type number[] 
    CRYSTAL_PRICE= {} ---@type integer[] 
    PROF= {} ---@type integer[] 
    LIMIT_STRING= {} ---@type string[] 

    --TODO subject to change?
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
    TYPE_NAME[0] = ""
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
    ITEM_MODEL[1] = "Chest_Refined.mdx"
    ITEM_MODEL[2] = "Chest_Refined.mdx"
    ITEM_MODEL[3] = "Chest_Refined.mdx"
    ITEM_MODEL[4] = "Chest_Refined.mdx"
    ITEM_MODEL[5] = "Chest_Rare.mdx"
    ITEM_MODEL[6] = "Chest_Rare.mdx"
    ITEM_MODEL[7] = "Chest_Rare.mdx"
    ITEM_MODEL[8] = "Chest_Rare.mdx"
    ITEM_MODEL[9] = "Chest_Epic.mdx"
    ITEM_MODEL[10] = "Chest_Epic.mdx"
    ITEM_MODEL[11] = "Chest_Epic.mdx"
    ITEM_MODEL[12] = "Chest_Epic.mdx"
    ITEM_MODEL[13] = "Chest_Legendary.mdx"
    ITEM_MODEL[14] = "Chest_Legendary.mdx"
    ITEM_MODEL[15] = "Chest_Legendary.mdx"
    ITEM_MODEL[16] = "Chest_Legendary.mdx"
    ITEM_MODEL[17] = "Chest_Chaos.mdx"
    ITEM_MODEL[18] = "Chest_Chaos.mdx"
    ITEM_MODEL[19] = "Chest_Chaos.mdx"
    ITEM_MODEL[20] = "Chest_Chaos.mdx"
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
    PROF[1] = PROF_PLATE
    PROF[2] = PROF_FULLPLATE
    PROF[3] = PROF_LEATHER
    PROF[4] = PROF_CLOTH
    PROF[5] = PROF_SHIELD
    PROF[6] = PROF_HEAVY
    PROF[7] = PROF_SWORD
    PROF[8] = PROF_DAGGER
    PROF[9] = PROF_BOW
    PROF[10] = PROF_STAFF

    STAT_NAME[ITEM_HEALTH] = "|r |cffff0000Health|r"
    STAT_NAME[ITEM_MANA] = "|r |cff6699ffMana"
    STAT_NAME[ITEM_DAMAGE] = "|r |cffff6600Damage|r"
    STAT_NAME[ITEM_ARMOR] = "|r |cffa4a4feArmor|r"
    STAT_NAME[ITEM_STRENGTH] = "|r |cffbb0000Strength|r"
    STAT_NAME[ITEM_AGILITY] = "|r |cff008800Agility|r"
    STAT_NAME[ITEM_INTELLIGENCE] = "|r |cff2255ffIntelligence|r"
    STAT_NAME[ITEM_REGENERATION] = "|r |cffa00070Regeneration|r"
    STAT_NAME[ITEM_DAMAGE_RESIST] = "%|r |cffff8040Damage Resist|r"
    STAT_NAME[ITEM_MAGIC_RESIST] = "%|r |cff8000ffMagic Resist|r"
    STAT_NAME[ITEM_MOVESPEED] = "|r |cff888888Movespeed|r"
    STAT_NAME[ITEM_CRIT_CHANCE] = "x|r |cffffcc00Critical Strike|r"
    STAT_NAME[ITEM_CRIT_DAMAGE] = "x|r |cffffcc00Critical Strike|r"
    STAT_NAME[ITEM_EVASION] = "%|r |cff008080Evasion|r"
    STAT_NAME[ITEM_SPELLBOOST] = "%|r |cff80ffffSpellboost|r"
    STAT_NAME[ITEM_BASE_ATTACK_SPEED] = "%|r |cff446600Base Attack Speed|r"
    STAT_NAME[ITEM_GOLD_GAIN] = "%|r |cffffff00Gold Find|r"

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

    --quest rewards
    -- spider armors
    ItemRewards[FourCC('I04M')] = {}
    ItemRewards[FourCC('I04M')][0] = FourCC('I0B8')
    ItemRewards[FourCC('I04M')][1] = FourCC('I0BA')
    ItemRewards[FourCC('I04M')][2] = FourCC('I0B4')
    ItemRewards[FourCC('I04M')][3] = FourCC('I0B6')

    --hints
    HINT_TOOLTIP = { ---@type string[]
        "|cffc0c0c0Every 30 minutes the game will check for AFK players, so if you see a text box appear, type the number it displays after a hyphen (-####)|r",
        "|cffc0c0c0Did you know?|r |cff9966ffCoT RPG|r |cffc0c0c0has a discord!|r |cff9ebef5https://discord.gg/peSTvTd|r",
        "|cffc0c0c0If you find your experience rate dropping, try upgrading to a better home.|r",
        "|cffc0c0c0Game too easy for you? Select|r |cff9966ffHardcore|r |cffc0c0c0on character creation to increase difficulty & increase benefits.|r",
        "|cffc0c0c0Type|r |cff9966ff-info|r |cffc0c0c0or|r |cff9966ff-commands|r |cffc0c0c0to see a list of game options, especially if you are new.|r",
        "|cffc0c0c0After an item drops it will be removed after 10 minutes, but don’t worry if you’ve already picked it up or bound it with your hero as they will not delete.|r",
        "|cffc0c0c0Game too difficult? We recommend playing with 2+ players. If you are playing solo, consider playing online with friends or others.|r",
        "|cffc0c0c0Enemies that respawn will appear as ghosts if you are too close, however if you walk away they will return to normal.|r",
        "|cffc0c0c0There’s a few items in game with a significantly lower level requirement, though they are typically harder to acquire.|r",
        "|cffc0c0c0You can type|r |cff9966ff-hints|r or |cff9966ff-nohints|r |cffc0c0c0to toggle these messages on and off.|r",
        "|cffc0c0c0Once you challenge the gods you cannot flee.|r",
        "|cffc0c0c0Some artifacts remain frozen in ice, waiting to be recovered...|r",
        "|cffc0c0c0Your colosseum experience rate will drop the more you participate, recover it by gaining experience outside of colosseum.|r",
        "|cffc0c0c0Spellboost innately affects the damage of your spells by plus or minus 20%.|r",
        "|cffc0c0c0Critical strike items and spells can stack their effect, the multipliers are additive.|r",
        "|cffc0c0c0The Ashen Vat is a mysterious crafting device located in the north-west tower.|r",
        "|cffc0c0c0The actions menu (Z on your hero) provides many useful settings such as displaying allied hero portraits on the left.|r",
        "|cffc0c0c0Toggling off your auto attacks with -aa helps reduce the likelihood of drawing aggro, -info 8 for more information.|r",
        "|cffc0c0c0If you meant to load another hero and you haven't left the church, you can type|r |cff9966ff-repick|r |cffc0c0c0and then|r |cff9966ff-load|r |cffc0c0c0to load another hero.|r",
        "|cffc0c0c0Hold |cff9966ffLeft Alt|r |cffc0c0c0while viewing your abilites to see how they are affected by Spellboost.|r"
    }

    LAST_HINT = 0
    FORCE_HINT = CreateForce() ---@type force 

    local U = User.first

    while U do
        PrestigeTable[U.id] = __jarray(0)
        ForceAddPlayer(FORCE_HINT, U.player)
        U = U.next
    end

    PlatConverter = __jarray(false)
    ArcaConverter = __jarray(false)
    PlatConverterBought = __jarray(false)
    ArcaConverterBought = __jarray(false)
end)

if Debug then Debug.endFile() end
