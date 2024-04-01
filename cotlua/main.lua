if Debug then Debug.beginFile 'Main' end

ON_JOIN = CreateTrigger()
ON_START = CreateTrigger()
PLAYER_JOIN_TIME = __jarray(0)
PLAYER_START_TIME = __jarray(0)

function DetectHost()
    local host = {id = -1, time = 0}

    for i = 0, PLAYER_CAP - 1 do
        if (GetPlayerController(Player(i)) == MAP_CONTROL_USER and GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING) then
            print(User[Player(i)].nameColored .. " start time: " .. PLAYER_START_TIME[i] .. " | join time: " .. PLAYER_JOIN_TIME[i])
            if PLAYER_START_TIME[i] - PLAYER_JOIN_TIME[i] > host.time then
                host.time = PLAYER_START_TIME[i] - PLAYER_JOIN_TIME[i]
                host.id = i
            end
        end
    end

    return host.id
end

function OnStart()
    local pid = GetPlayerId(GetTriggerPlayer())

    PLAYER_START_TIME[pid] = tonumber(BlzGetTriggerSyncData())

    return false
end

function OnJoin()
    local pid = GetPlayerId(GetTriggerPlayer())

    PLAYER_JOIN_TIME[pid] = tonumber(BlzGetTriggerSyncData())

    return false
end

for i = 0, bj_MAX_PLAYER_SLOTS do
    BlzTriggerRegisterPlayerSyncEvent(ON_JOIN, Player(i), "join", false)
    BlzTriggerRegisterPlayerSyncEvent(ON_START, Player(i), "start", false)
end
TriggerAddCondition(ON_JOIN, Condition(OnJoin))
TriggerAddCondition(ON_START, Condition(OnStart))

OnInit.main(function()
    Preload("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdx")
    Preload("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdx")
    Preload("Abilities\\Weapons\\Bolt\\BoltImpact.mdx")
    Preload("war3mapImported\\FrozenOrb.MDX")
    Preload("war3mapImported\\Death Nova.mdx")
    Preload("war3mapImported\\Lightnings Long.mdx")
    Preload("war3mapImported\\NeutralExplosion.mdx")
    Preload("war3mapImported\\NewMassiveEX.mdx")
    Preload("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdx")
    Preload("war3mapImported\\Call of Dread Red.mdx")
    Preload("war3mapImported\\Lava_Slam.mdx")
    Preload("war3mapImported\\AnnihilationTarget.mdx")
    Preload("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdx")
    Preload("Abilities\\Spells\\Human\\Thunderclap\\ThunderclapTarget.mdx")
    Preload("Abilities\\Spells\\Human\\Blizzard\\BlizzardTarget.mdx")
    Preload("Abilities\\Spells\\Other\\FrostBolt\\FrostBoltMissile.mdl")
    Preload("Abilities\\Spells\\Human\\StormBolt\\StormBoltMissile.mdx")
    Preload("war3mapImported\\Coup de Grace.mdx")
    Preload("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdx")
    Preload("units\\other\\FleshGolem\\FleshGolem.mdx")
    Preload("units\\demon\\felhound\\felhound_V1.mdx")
    Preload("war3mapImported\\MasterWarlock.mdx")
    Preload("Abilities\\Weapons\\GyroCopter\\GyroCopterMissile.mdl")
    Preload("war3mapImported\\HighSpeedProjectile_ByEpsilon.mdx")
    Preload("Abilities\\Spells\\Other\\AcidBomb\\BottleMissile.mdl")
    Preload("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl")
    Preload("war3mapImported\\Armor Penetration Orange.mdx")
    Preload("Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl")
    Preload("Abilities\\Weapons\\GlaiveMissile\\GlaiveMissile.mdl")
    Preload("Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl")
    Preload("Abilities\\Spells\\Other\\HowlOfTerror\\HowlTarget.mdl")
    Preload("war3mapImported\\Buff_Shield_Non.mdx")
    Preload("Units\\Demon\\Infernal\\InfernalBirth.mdl")
    Preload("war3mapImported\\Reapers Claws Red.mdx")
    Preload("Abilities\\Spells\\Orc\\Devour\\DevourEffectArt.mdl")

    BlzLoadTOCFile("war3mapImported\\FDF.toc")

    SetMapFlag(MAP_FOG_HIDE_TERRAIN, false)
    SetMapFlag(MAP_FOG_MAP_EXPLORED, true)
    SetMapFlag(MAP_FOG_ALWAYS_VISIBLE, false)

    BlzSendSyncData("start", tostring(os.clock()))
end)

OnInit.config(function()
    BlzSendSyncData("join", tostring(os.clock()))
end)

if Debug then Debug.endFile() end
