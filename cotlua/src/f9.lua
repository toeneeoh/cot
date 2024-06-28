--[[
    F9.lua

    Defines all the quests in the quest log (F9)
]]

OnInit.final("F9", function()

    CreateQuestBJ(bj_QUESTTYPE_REQ_DISCOVERED, "|c008000ffNevermore|r", [[The Nevermore Series is developed by: Mayday & lcm.

Thanks to previous contributors:
Waugriff
darkchaos
Hotwer
afis
CanFight]], "ReplaceableTextures\\CommandButtons\\BTNTheCaptain.blp")
    CreateQuestBJ(bj_QUESTTYPE_REQ_DISCOVERED, "|c00ff0000Beta Testers|r", [[Special thanks to the Nevermore Beta Testers:
|cff0b6623Kristian
Bud-Bus-|r
|cff7c0a02Ash
Sagmariasus
Aru_Azif
Orion
AgentCody
Anna Kendrick
Charles Barkley's Tulpa
Peacee'
ReefyPuffs
Saken
Samaki1000
Triggis
Maiev|r]], "ReplaceableTextures\\CommandButtons\\BTNJaina.blp")

    CreateQuestBJ(bj_QUESTTYPE_REQ_DISCOVERED, "Commands", [[-info (displays submenu info list)
    -stats # (displays your current characters stats)
    -estats (show enemy level, HP, and attack speed)
    -cam # (L to lock, i.e. -cam 3000L)
    -zm (L to lock, i.e. -zml will set your camera to 2500, locked distance)
    -lock (locks camera distance)
    -unlock (unlock camera distance so that it can be reset by scroll wheel)
    -roll (rolls a number 1-100 for an item)
    -suicide (kills your hero if you get stuck)
    -db (destroy base)
    -clear (clears text on screen)
    -pf (proficiencies)
    -save (saves your character, this game uses a codeless save system)
    -load (loads your profile/heroes to be selected from in your current game)
    -forcesave (after a timer/prompt, your character will be removed & saved)
    -autosave (automatically saves your hero every 30 minutes)
    -savetime (time until you can save again)
    -restime (time until you can recharge your ankh again)]], "ReplaceableTextures\\PassiveButtons\\PASBTNStatUp.blp")
    CreateQuestBJ(bj_QUESTTYPE_REQ_DISCOVERED, "Commands 2", [[-st (show time until next save)
    -xp (displays current xp values)
    -flee (leave an instance)
    -hardmode (enables increased boss difficulty)
    -prestige # (displays prestige talent screen)
    -hints (enables hint messages)
    -nohints (disables)
    -ms/-speed (displays your current move speed)
    -as (displays your current attack speed)
    -actions (refresh actions menu)
    -color # (changes your player color)
    -unstuck (uhh)
    -tome (displays how many tomes can be bought)
    -aa (toggles auto attacking)]], "ReplaceableTextures\\PassiveButtons\\PASBTNStatUp.blp")

    CreateQuestBJ(bj_QUESTTYPE_REQ_DISCOVERED, "Colors", [[1 |c00FF0303Red|r
2 |c000042FFBlue|r
3 |c001CE6B9Teal|r
4 |c00540081Purple|r
5 |c00FFFC01Yellow|r
6 |c00fEBA0EOrange|r
7 |c0020C000Green|r
8 |c00E55BB0Pink|r
9 |c00959697Gray|r
10 |c007EBFF1Light Blue|r
11 |c00106246Dark Green|r
12 |c004E2A04Brown|r
13 |cff9B0000Maroon|r
14 |cff0000C3Navy|r
15 |cff00EAFFTurquoise|r
16 |cffBE00FEViolet|r
17 |cffEBCD87Wheat|r
18 |cffF8A48BPeach|r
19 |cffBFFF80Mint|r
20 |cffDCB9EBLavender|r
21 |cff282828Coal|r
22 |cffEBF0FFSnow|r
23 |cff00781EEmerald|r
24 |cffA46F33Peanut|r
25 Black]], "ReplaceableTextures\\PassiveButtons\\PASBTNScatterRockets.blp")

    -- optional quests
    Bum_Stage               = CreateQuestBJ(bj_QUESTTYPE_OPT_DISCOVERED, "Bum Stage", "After you’ve picked a hero of your choice, you should buy a house or a nation sold by the salesmen located in a corner of the town. Place your nation/house near one of the goldmines located around the map. A house has higher XP rate then a nation, while a nation has better resource gathering and units.", "ReplaceableTextures\\CommandButtons\\BTNTaurenHut.blp")
    Dark_Savior_Quest       = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Dark Savior", "The Dark Savior has Found his way to Medea and now he is prepared to slaughter all in his way.  Kill him and bring back peace to the land before he destroys all in his path.", "ReplaceableTextures\\CommandButtons\\BTNTheCaptain.tga")
    Ogre_King_Quest         = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The King of Ogres", "The Ogres and Taurens have taken control of the forest to the south of town. Slay their King and bring his head to the Huntsman for your reward.", "ReplaceableTextures\\CommandButtons\\BTNOneHeadedOgre.tga")
    Nerubian_Quest          = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Nerubian Empress", "The Nerubian Empress control the lesser spiders, forcing them to viciously attack wanderers. Although she can't use swords and shields, there's a collection of them in her lair. Nerubians like shiny things. Defeat her and bring her head for your reward.", "ReplaceableTextures\\CommandButtons\\BTNOneHeadedOgre.tga")
    Paladin_Quest           = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "Vengeful Test Paladin", "Over a thousand of my fellow paladins have been slain by your evil testing ambitions!!!  And you dare drink my whiskey and swing my hammer?!  -One Test Paladin remained on the map and he turned hostile after the evil Map Maker Waugriff set all the Creeps AI's. Now he is sworn to destroy any players that cross his path!", "ReplaceableTextures\\CommandButtons\\BTNHeroPaladin.tga")
    Sasquatch_Quest         = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Yeti", "The mighty happy Yeti of Medea is known to harrass local hunting parties. Though usually no one is slain they all return home naked, with sore behinds and empty bottles of ale screaming about soap and not dropping it. Though nobody knows exactly what these foul Yeti have done to these men, one could only imagine. Slay the beast and bring its head to the Huntsman for your reward.", "ReplaceableTextures\\CommandButtons\\BTNWendigo.tga")
    Mist_Quest              = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Forgotten Mystic", "In the Great War against the Goddesses, only one Medean escaped. He lived his life devoted to studying the mystic arts, with the sole purpose of avenging his fallen brethren only to later be corrupted by the very feeling of hate that fueled his desire.  In his madness he was an easy target for the Goddesses to control. He now hides somewhere in Medea, constantly growing in power.", "ReplaceableTextures\\CommandButtons\\BTNBloodMage2.tga")
    Tauren_Cheiftan_Quest   = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Minotaur", "The Tauran are a proud and rather gentle race.  The spent thier time training and learning to be one with nature.  Respecting all those around them and making sure never to upset the delicate balance of life.  But as time passed and the Orcs began to abuse thier ways the few tauran that escaped grew bitter and violent.", "ReplaceableTextures\\CommandButtons\\BTNHeroTaurenChieftain.tga")
    Devourer_Quest          = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Medean Devourer", "Many species of creatures were mutated during the Great War to be used as weapons, but none as feared as the Devourer. The Great Medean Devourer was known for its resiliance to the cold and could easily multiply to overwhelm enemys. Its body is coated in acid that is highly corrosive to anything but its thick carapace and its venom is lethal even to divine beings. No sightings of these creatures are reported in Medea in decades.", "ReplaceableTextures\\CommandButtons\\BTNArachnathid.tga")
    Mountain_King_Quest     = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Last Dwarf", "The great warrior Omni is the last known living dwarf in Medea. He fought in the Great War long ago, against the oppression of the Goddesses, and was presumed dead until recently, when the Savior discovered he was kept alive by and turned into a mindless puppet at the service of the Goddesses.", "ReplaceableTextures\\CommandButtons\\BTNHeroMountainKing.tga")
    Evil_Shopkeeper_Quest_1 = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Evil Shopkeeper", "The greedy Evil Shopkeeper finally has a bounty on his head! After mercilessly selling stolen n' smuggled items at outrageous prices and double-crossing everyone that simply crossed his path he has finally got the people angry enough to want him dead. Kill him, and put his evil deeds to and end. But be warned! He is tricky.", "ReplaceableTextures\\CommandButtons\\BTNAcolyte.tga")
    Key_Quest               = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Goddesses' Keys", "A strange temple of water lays to the south of town with a odd spirit and runes that seem to hide something. You read on the walls the strange writing and murals begin to speak to you about sealing away the great powers. Three words come up to your mind immediately: Devotion, Valor and Redemption.", "ReplaceableTextures\\CommandButtons\\BTNShade.tga")
    Mink_Quest              = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Dragoon, Mink", "Mink is once again plaguing the land (and the IT) with her horendous luck.  Seek revenge for the Poor IT and free him of his headache.", "ReplaceableTextures\\CommandButtons\\BTNSylvanusWindrunner.tga")
    Icetroll_Quest          = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Ice Troll Cheiftan", "Da's Dingo!  The Ice trolls are begining to get pissed for all the coments on their troll accent and now want to scalp anything that moves.  Defeat them and prove to them it is indeed a jamacian accent!", "ReplaceableTextures\\CommandButtons\\BTNHeadHunterBerserker.tga")
    Iron_Golem_Fist_Quest   = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Blacksmith's Ore", "A blacksmith has asked that you bring 6 Iron Golem Ores to him. He seeks to create a weapon before his old age finally forces him to retire. He has agreed that you can keep the Item he creates with the Ores.", "ReplaceableTextures\\CommandButtons\\BTNDeathPact.blp")
    Defeat_The_Horde_Quest  = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Horde", "The Horde has spread and began to grow in numbers by the second.  They lie in wait, patiently waiting unitl their number are enough to take over the land.  Defeat them before they can organize a full scale attack and desimate the nations of your comrades.", "ReplaceableTextures\\CommandButtons\\BTNThrall.tga")
    Evil_Shopkeeper_Quest_2 = CreateQuestBJ(bj_QUESTTYPE_OPT_UNDISCOVERED, "The Omega P's Pick", "The Leaders of Team P must be stopped, destroy them and bring back both thier picks as proof to recive the ultimate pick of the Team P hordes.", "ReplaceableTextures\\CommandButtons\\BTNPeon.tga")
end, Debug and Debug.getLine())
