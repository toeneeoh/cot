library Map requires Functions

    globals
        location TownCenter = Location(-250., 160.)
        location ColosseumCenter = Location(21710., -4261.)
        location StruggleCenter = Location(28030., 4361.)
        boolean array InColo
        boolean array InStruggle
        texttag StruggleText = CreateTextTag()
        texttag ColoText = CreateTextTag()
        integer ColoWaveCount = 0
    endglobals

    function MapInit takes nothing returns nothing
        local integer i = 0
        local integer i2 = 0
        local User u = User.first

        set bj_useDawnDuskSounds = false
        call StopSound(bj_nightAmbientSound, true, false)
        call StopSound(bj_dayAmbientSound, true, false)
        call SetTextTagText(ColoText, "", 15.00)
        call SetTextTagPos(ColoText, 21710., -4261., 0)
        call SetTextTagColor(ColoText, 235, 235, 21, 255)
        call SetTextTagPermanent(ColoText, true)
        call SetTextTagText(StruggleText, "", 15.00)
        call SetTextTagPos(StruggleText, 28039., 4350., 0)
        call SetTextTagColor(StruggleText, 235, 235, 21, 255)
        call SetTextTagPermanent(StruggleText, true)
        call SetSkyModel("war3mapImported\\StarSphere.mdx")
        call DisplayTimedTextToForce(FORCE_PLAYING, 10, "Welcome to Curse of Time RPG: |c009966ffNevermore|r")
        call DisplayTextToForce(FORCE_PLAYING, " ")
        call DisplayTextToForce(FORCE_PLAYING, " ")
        call DisplayTimedTextToForce(FORCE_PLAYING, 45.00, "Official Site for updates, bug reports, and official non-hacked downloads:\n|c009ebef5https://curseoftime.wordpress.com/|r\nAlso, don't forget to join our |c000080c0Discord|r server:\n|c009ebef5https://discord.gg/peSTvTd|r")
        call DisplayTextToForce(FORCE_PLAYING, " ")
        call DisplayTextToForce(FORCE_PLAYING, " ")
        call DisplayTimedTextToForce(FORCE_PLAYING, 600.0, "\nType |c006969ff-new profile|r if you are completely new\nor |c00ff7f00-load|r if you want to load your hero or start a new one.")
        call DisplayTimedTextToForce(FORCE_PLAYING, 15.00, "Please read the Quests Menu for updates.")  
        call SetPlayerAllianceStateBJ(pboss, pfoe, bj_ALLIANCE_ALLIED)
        call SetPlayerAllianceStateBJ(pfoe, pboss, bj_ALLIANCE_ALLIED)

        loop
            exitwhen u == User.NULL
            call SetPlayerAllianceStateBJ(Player(PLAYER_TOWN), u.toPlayer(), bj_ALLIANCE_ALLIED)
            call SetPlayerAlliance(u.toPlayer(), Player(PLAYER_NEUTRAL_PASSIVE), ALLIANCE_SHARED_SPELLS, true)
            call SetPlayerTechMaxAllowed(u.toPlayer(), 'o03K', 1)
            call SetPlayerTechMaxAllowed(u.toPlayer(), 'e016', 15)
            call SetPlayerTechMaxAllowed(u.toPlayer(), 'e017', 8)
            call SetPlayerTechMaxAllowed(u.toPlayer(), 'e018', 3)
            call SetPlayerTechMaxAllowed(u.toPlayer(), 'u01H', 3)
            call SetPlayerTechMaxAllowed(u.toPlayer(), 'h06S', 15)
            call SetPlayerTechMaxAllowed(u.toPlayer(), 'h06U', 3)
            call SetPlayerTechMaxAllowed(u.toPlayer(), 'h06T', 8)
            call AddPlayerTechResearched(u.toPlayer(), 'R013', 1)
            call AddPlayerTechResearched(u.toPlayer(), 'R014', 1)
            call AddPlayerTechResearched(u.toPlayer(), 'R015', 1)
            call AddPlayerTechResearched(u.toPlayer(), 'R016', 1)
            call AddPlayerTechResearched(u.toPlayer(), 'R017', 1)
            call SetPlayerState(u.toPlayer(), PLAYER_STATE_RESOURCE_FOOD_USED, 0)
            set u = u.next
        endloop

        if GetPlayerController(pboss) == MAP_CONTROL_USER then
            call CustomDefeatBJ(pboss, "Unable to use Computers.")
        endif

        loop
            exitwhen i == bj_MAX_PLAYERS

            set i2 = 0
            loop
                exitwhen i2 == bj_MAX_PLAYERS
                if i != i2 and GetPlayerController(Player(i)) == MAP_CONTROL_USER then
                    call SetPlayerAlliance(Player(i), Player(i2), ALLIANCE_SHARED_VISION, true)
                    call SetPlayerAlliance(Player(i), Player(i2), ALLIANCE_SHARED_CONTROL, false)
                endif
                set i2 = i2 + 1
            endloop

            set i = i + 1
        endloop

        call SetPlayerState(pfoe, PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetMapFlag(MAP_LOCK_ALLIANCE_CHANGES, true)
    endfunction

endlibrary
