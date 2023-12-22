native UnitAlive takes unit id returns boolean

//! inject main
    call SetCameraBounds(- 30208.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), - 30720.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM), 31232.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), 30720.0 - GetCameraMargin(CAMERA_MARGIN_TOP), - 30208.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), 30720.0 - GetCameraMargin(CAMERA_MARGIN_TOP), 31232.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), - 30720.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM))
    call SetDayNightModels("Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl", "Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl")
    call SetWaterBaseColor(40, 40, 255, 255)
    call NewSoundEnvironment("Default")
    call SetAmbientDaySound("IceCrownDay")
    call SetAmbientNightSound("IceCrownNight")
    call SetMapMusic("Music", true, 0)
    call InitSounds()
    call CreateRegions()
    call CreateCameras()
    call CreateAllDestructables()
    call CreateAllUnits()
    call InitBlizzard()

    //! dovjassinit

    call Preload("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdx")
    call Preload("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdx")
    call Preload("Abilities\\Weapons\\Bolt\\BoltImpact.mdx")
    call Preload("war3mapImported\\FrozenOrb.MDX")
    call Preload("war3mapImported\\Death Nova.mdx")
    call Preload("war3mapImported\\Lightnings Long.mdx")
    call Preload("war3mapImported\\NeutralExplosion.mdx")
    call Preload("war3mapImported\\NewMassiveEX.mdx")
    call Preload("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdx")
    call Preload("war3mapImported\\Call of Dread Red.mdx")
    call Preload("war3mapImported\\Lava_Slam.mdx")
    call Preload("war3mapImported\\AnnihilationTarget.mdx")
    call Preload("Units\\Demon\\Infernal\\InfernalBirth.mdx")
    call Preload("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdx")
    call Preload("Abilities\\Spells\\Human\\Thunderclap\\ThunderclapTarget.mdx")
    call Preload("Abilities\\Spells\\Human\\Blizzard\\BlizzardTarget.mdx")
    call Preload("Abilities\\Spells\\Other\\FrostBolt\\FrostBoltMissile.mdx")
    call Preload("Abilities\\Spells\\Human\\StormBolt\\StormBoltMissile.mdx")
    call Preload("war3mapImported\\Coup de Grace.mdx")
    call Preload("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdx")
    call Preload("units\\other\\FleshGolem\\FleshGolem.mdx")
    call Preload("units\\demon\\felhound\\felhound_V1.mdx")
    call Preload("war3mapImported\\MasterWarlock.mdx")
    
    call SetMapFlag(MAP_FOG_HIDE_TERRAIN, false)
    call SetMapFlag(MAP_FOG_MAP_EXPLORED, true)
    call SetMapFlag(MAP_FOG_ALWAYS_VISIBLE, false)

    call InitCustomTriggers()
//! endinject

function Initialize takes nothing returns nothing
    call DestroyTimer(GetExpiredTimer())
    call BlzChangeMinimapTerrainTex("MiniMap.dds")
    call SetCameraBoundsToRect(gg_rct_Tavern_Vision)
    call PanCameraToTimed(21645, 3430, 0)
    call FogMaskEnable(true)
    call FogEnable(true)

    call UnitIndexingSetup()
    call PlayerUtilsSetup()
    call GameStatusInit()
    call MapInit()
    call QuestInit()
    call HintInit()
    call SummonInit()
    call TrainInit()
    call CustomUISetup()
    call PlayerDataSetup() 
    call SpellsInit()
    call HeroSelectInit()
    call ItemInit()
    call UnitSetup()
    call CreateMB()
    call AshenVatInit()
    call DeathInit()
    call BaseInit()
    call OrdersInit()
    call LevelInit()
    call ConverterInit()
    call AttackedInit()
    call WeatherInit()
    call CheckDonators()
    call DamageInit()
    call VisibilityInit()
    call SpawnCreeps(0)
    call MouseInit()
    call KeyboardInit()
    call RegionsInit()
    call TimerInit()
    call CommandsInit()
    call CodelessSaveLoadInit()

    call TimerStart(WeatherTimer, 5.00, false, null)
endfunction

globals
    string MAP_NAME                             = "CoT Nevermore"
    integer SAVE_LOAD_VERSION                   = 1
    integer TIME                                = 0

    constant integer PLAYER_CAP                 = 6
    constant integer MAX_LEVEL                  = 400
    constant integer LEECH_CONSTANT             = 50
    constant real CALL_FOR_HELP_RANGE           = 800.
    constant real NEARBY_BOSS_RANGE             = 2500.
	constant integer PLAYER_TOWN                = 8
	constant integer PLAYER_BOSS                = 11
	constant integer FOE_ID                     = PLAYER_NEUTRAL_AGGRESSIVE + 1
	constant integer BOSS_ID                    = PLAYER_BOSS + 1
	constant integer TOWN_ID                    = PLAYER_TOWN + 1

    //units
    constant integer DUMMY                      = 'e011'
    constant integer GRAVE                      = 'H01G'
    constant integer BACKPACK                   = 'H05D'
    constant integer HERO_PHOENIX_RANGER        = 'E00X'
    constant integer HERO_ROYAL_GUARDIAN        = 'H04Z'
    constant integer HERO_ARCANE_WARRIOR        = 'H05B'
    constant integer HERO_MASTER_ROGUE          = 'E015'
    constant integer HERO_ELEMENTALIST          = 'E00W'
    constant integer HERO_HIGH_PRIEST           = 'E012'
    constant integer HERO_DARK_SUMMONER         = 'O02S'
    constant integer HERO_SAVIOR                = 'H01N'
    constant integer HERO_DARK_SAVIOR           = 'H01S'
    constant integer HERO_ASSASSIN              = 'E002'
    constant integer HERO_BARD                  = 'H00R'
    constant integer HERO_ARCANIST              = 'H029'
    constant integer HERO_OBLIVION_GUARD        = 'H02A'
    constant integer HERO_THUNDERBLADE          = 'O03J'
    constant integer HERO_BLOODZERKER           = 'H03N'
    constant integer HERO_MARKSMAN              = 'E008'
    constant integer HERO_HYDROMANCER           = 'E00G'
    constant integer HERO_WARRIOR               = 'H012'
    constant integer HERO_DRUID                 = 'O018'
    constant integer HERO_DARK_SAVIOR_DEMON     = 'E01M'
    constant integer HERO_MARKSMAN_SNIPER       = 'E00F' 
    constant integer HERO_VAMPIRE               = 'U003' 
    constant integer HERO_TOTAL                 = 19
    constant integer SUMMON_DESTROYER           = 'E014'
    constant integer SUMMON_HOUND               = 'H05F'
    constant integer SUMMON_GOLEM               = 'H05G'

    //proficiencies
    constant integer PROF_PLATE                 = 0x1
    constant integer PROF_FULLPLATE             = 0x2
    constant integer PROF_LEATHER               = 0x4
    constant integer PROF_CLOTH                 = 0x8
    constant integer PROF_SHIELD                = 0x10
    constant integer PROF_HEAVY                 = 0x20
    constant integer PROF_SWORD                 = 0x40
    constant integer PROF_DAGGER                = 0x80
    constant integer PROF_BOW                   = 0x100
    constant integer PROF_STAFF                 = 0x200

    //currency
    constant integer GOLD                       = 0
    constant integer LUMBER                     = 1
    constant integer PLATINUM                   = 2
    constant integer ARCADITE                   = 3
    constant integer CRYSTAL                    = 4
    constant integer CURRENCY_COUNT             = 5

    //bosses
    constant integer BOSS_TAUREN                = 0
    constant integer BOSS_DEMON_PRINCE          = 0
    constant integer BOSS_MYSTIC                = 1
    constant integer BOSS_ABSOLUTE_HORROR       = 1
    constant integer BOSS_HELLFIRE              = 2
    constant integer BOSS_SLAUGHTER_QUEEN       = 2
    constant integer BOSS_DWARF                 = 3
    constant integer BOSS_SATAN                 = 3
    constant integer BOSS_PALADIN               = 4
    constant integer BOSS_DARK_SOUL             = 4
    constant integer BOSS_DRAGOON               = 5
    constant integer BOSS_LEGION                = 5
    constant integer BOSS_DEATH_KNIGHT          = 6
    constant integer BOSS_THANATOS              = 6
    constant integer BOSS_VASHJ                 = 7
    constant integer BOSS_EXISTENCE             = 7
    constant integer BOSS_YETI                  = 8
    constant integer BOSS_AZAZOTH               = 8
    constant integer BOSS_OGRE                  = 9
    constant integer BOSS_FORGOTTEN_LEADER      = 9
    constant integer BOSS_NERUBIAN              = 10
    constant integer BOSS_POLAR_BEAR            = 11
    constant integer BOSS_LIFE                  = 12
    constant integer BOSS_HATE                  = 13
    constant integer BOSS_LOVE                  = 14
    constant integer BOSS_KNOWLEDGE             = 15
    constant integer BOSS_GODSLAYER             = 16
    integer BOSS_TOTAL                          = 16

    //items
    constant integer MAX_REINCARNATION_CHARGES  = 3
    constant integer BOUNDS_OFFSET              = 50 //leaves room for 50 different values per stat? (overkill?)
    constant integer ABILITY_OFFSET             = 100
    constant integer QUALITY_SAVED              = 7
    constant integer ITEM_TOOLTIP               = 0
    constant integer ITEM_TIER                  = 1
    constant integer ITEM_TYPE                  = 2
    constant integer ITEM_UPGRADE_MAX           = 3
    constant integer ITEM_LEVEL_REQUIREMENT     = 4
    constant integer ITEM_HEALTH                = 5
    constant integer ITEM_MANA                  = 6
    constant integer ITEM_DAMAGE                = 7
    constant integer ITEM_ARMOR                 = 8
    constant integer ITEM_STRENGTH              = 9
    constant integer ITEM_AGILITY               = 10
    constant integer ITEM_INTELLIGENCE          = 11
    constant integer ITEM_REGENERATION          = 12
    constant integer ITEM_DAMAGE_RESIST         = 13
    constant integer ITEM_MAGIC_RESIST          = 14
    constant integer ITEM_MOVESPEED             = 15
    constant integer ITEM_EVASION               = 16
    constant integer ITEM_SPELLBOOST            = 17
    constant integer ITEM_CRIT_CHANCE           = 18
    constant integer ITEM_CRIT_DAMAGE           = 19
    constant integer ITEM_BASE_ATTACK_SPEED     = 20
    constant integer ITEM_GOLD_GAIN             = 21
    constant integer ITEM_ABILITY               = 22
    constant integer ITEM_ABILITY2              = 23
    constant integer ITEM_STAT_TOTAL            = 23
    //hidden
    constant integer ITEM_LIMIT                 = 24
    constant integer ITEM_COST                  = 25
    constant integer ITEM_DISCOUNT              = 26

    //quests
    constant integer KILLQUEST_NAME             = 0
    constant integer KILLQUEST_COUNT            = 1
    constant integer KILLQUEST_GOAL             = 2
    constant integer KILLQUEST_MIN              = 3
    constant integer KILLQUEST_MAX              = 4
    constant integer KILLQUEST_REGION           = 5
    constant integer KILLQUEST_LAST             = 6
    constant integer KILLQUEST_STATUS           = 7

    //unit data
    constant integer UNITDATA_COUNT             = 0
    constant integer UNITDATA_SPAWN             = 1
endglobals
