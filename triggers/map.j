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
    call ReleaseTimer(GetExpiredTimer())
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
    call UnitSetup()
    call CreateMB()
    call AshenVatInit()
    call ItemInit()
    call SpellsInit()
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
    call RegionsInit()
    call TimerInit()
    call SaveHelperInit()
    call HeroSelectInit()
    call CommandsInit()
    call CodelessSaveLoadInit()

    call TimerStart(WeatherTimer, 5.00, false, null)
endfunction

globals
    constant integer PLAYER_CAP                 = 6
    constant integer MAX_LEVEL                  = 400
    integer SAVE_LOAD_VERSION                   = 1
    constant integer LEECH_CONSTANT             = 50
    constant real CALL_FOR_HELP_RANGE           = 800.
    constant real NEARBY_BOSS_RANGE             = 2500.
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
    constant integer HERO_INFERNAL              = 'H02A'
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
    constant integer BOSS_SIREN                 = 7
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
    integer BOSS_TOTAL                          = 15
    constant string CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    constant integer BASE = StringLength(CHARS)
    integer TIME = 0
endglobals
