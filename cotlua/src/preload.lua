if Debug then Debug.beginFile 'Preload' end

OnInit.final("Preloader", function()
    --set preplaced unit globals
    Trig_map_preplaced_Actions()
    Trig_map_preplaced_Actions = nil
    DestroyTrigger(gg_trg_map_preplaced)
    gg_trg_map_preplaced = nil

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
    Preload("war3mapImported\\DustWindFaster3.mdx")
    Preload("war3mapImported\\SuperLightningBall.mdl")
    Preload("war3mapImported\\EMPBubble.mdx")

    if BlzLoadTOCFile("war3mapImported\\FDF.toc") then
        print("TOC loaded!")
    end

    SetMapFlag(MAP_FOG_HIDE_TERRAIN, false)
    SetMapFlag(MAP_FOG_MAP_EXPLORED, true)
    SetMapFlag(MAP_FOG_ALWAYS_VISIBLE, false)

    BlzSendSyncData("start", tostring(os.clock()))
end)

if Debug then Debug.endFile() end
