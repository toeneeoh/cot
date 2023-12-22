if Debug then Debug.beginFile 'MapSetup' end

OnInit.final("MapSetup", function(require)
    require 'Users'
    require 'Variables'
    require 'Helper'
    require 'PlayerData'

    --create floating texttags
    SetTextTagText(ColoText, "", 15.00)
    SetTextTagPos(ColoText, 21710., -4261., 0)
    SetTextTagColor(ColoText, 235, 235, 21, 255)
    SetTextTagPermanent(ColoText, true)
    SetTextTagText(StruggleText, "", 15.00)
    SetTextTagPos(StruggleText, 28039., 4350., 0)
    SetTextTagColor(StruggleText, 235, 235, 21, 255)
    SetTextTagPermanent(StruggleText, true)

    --welcome message
    DisplayTimedTextToForce(FORCE_PLAYING, 15.00, "Welcome to Curse of Time RPG: |c009966ffNevermore|r")
    DisplayTextToForce(FORCE_PLAYING, " ")
    DisplayTextToForce(FORCE_PLAYING, " ")
    DisplayTimedTextToForce(FORCE_PLAYING, 45.00, "Official Site for updates, bug reports, and official non-hacked downloads:\n|c009ebef5https://curseoftime.wordpress.com/|r\nAlso, don't forget to join our |c000080c0Discord|r server:\n|c009ebef5https://discord.gg/peSTvTd|r")
    DisplayTextToForce(FORCE_PLAYING, " ")
    DisplayTextToForce(FORCE_PLAYING, " ")
    DisplayTimedTextToForce(FORCE_PLAYING, 600.0, "\nType |c006969ff-new profile|r if you are completely new\nor |c00ff7f00-load|r if you want to load your hero or start a new one.")
    DisplayTimedTextToForce(FORCE_PLAYING, 15.00, "Please read the Quests Menu for updates.")

    --create multiboards
    QUEUE_BOARD = CreateMultiboard()
    MULTI_BOARD = CreateMultiboard()
    MultiboardSetRowCount(MULTI_BOARD, User.AmountPlaying + 1)
    MultiboardSetColumnCount(MULTI_BOARD, 6)
    MultiboardSetTitleText(MULTI_BOARD, "Curse of Time RPG: |cff9966ffNevermore|r")
    MultiboardSetTitleTextColor(MULTI_BOARD, 180, 180, 180, 255)

    local mbitem = MultiboardGetItem(MULTI_BOARD, 0, 0)
    MultiboardSetItemValue(mbitem, "Player")
    MultiboardSetItemStyle(mbitem, true, false)
    MultiboardSetItemValueColor(mbitem, 255, 204, 0, 255)
    MultiboardSetItemWidth(mbitem, 0.1)
    MultiboardReleaseItem(mbitem)
    mbitem = MultiboardGetItem(MULTI_BOARD, 0, 1)
    MultiboardSetItemStyle(mbitem, false, false)
    MultiboardSetItemWidth(mbitem, 0.015)
    MultiboardReleaseItem(mbitem)
    mbitem = MultiboardGetItem(MULTI_BOARD, 0, 2)
    MultiboardSetItemStyle(mbitem, false, false)
    MultiboardSetItemWidth(mbitem, 0.015)
    MultiboardReleaseItem(mbitem)
    mbitem = MultiboardGetItem(MULTI_BOARD, 0, 3)
    MultiboardSetItemValue(mbitem, "Hero")
    MultiboardSetItemStyle(mbitem, true, false)
    MultiboardSetItemValueColor(mbitem, 255, 204, 0, 255)
    MultiboardSetItemWidth(mbitem, 0.1)
    MultiboardReleaseItem(mbitem)
    mbitem = MultiboardGetItem(MULTI_BOARD, 0, 4)
    MultiboardSetItemValue(mbitem, "LVL")
    MultiboardSetItemStyle(mbitem, true, false)
    MultiboardSetItemValueColor(mbitem, 255, 204, 0, 255)
    MultiboardSetItemWidth(mbitem, 0.03)
    MultiboardReleaseItem(mbitem)
    mbitem = MultiboardGetItem(MULTI_BOARD, 0, 5)
    MultiboardSetItemValue(mbitem, "HP")
    MultiboardSetItemStyle(mbitem, true, false)
    MultiboardSetItemValueColor(mbitem, 255, 204, 0, 255)
    MultiboardSetItemWidth(mbitem, 0.03)
    MultiboardReleaseItem(mbitem)

    local i = 1

    --ally enemies and bosses
    SetPlayerAllianceStateBJ(pboss, pfoe, bj_ALLIANCE_ALLIED)
    SetPlayerAllianceStateBJ(pfoe, pboss, bj_ALLIANCE_ALLIED)

    --player loop
    local u = User.first
    while u do
        --alliances / research / food state
        SetPlayerAllianceStateBJ(Player(PLAYER_TOWN), u.player, bj_ALLIANCE_ALLIED)
        SetPlayerAlliance(u.player, Player(PLAYER_NEUTRAL_PASSIVE), ALLIANCE_SHARED_SPELLS, true)
        SetPlayerTechMaxAllowed(u.player, FourCC('o03K'), 1)
        SetPlayerTechMaxAllowed(u.player, FourCC('e016'), 15)
        SetPlayerTechMaxAllowed(u.player, FourCC('e017'), 8)
        SetPlayerTechMaxAllowed(u.player, FourCC('e018'), 3)
        SetPlayerTechMaxAllowed(u.player, FourCC('u01H'), 3)
        SetPlayerTechMaxAllowed(u.player, FourCC('h06S'), 15)
        SetPlayerTechMaxAllowed(u.player, FourCC('h06U'), 3)
        SetPlayerTechMaxAllowed(u.player, FourCC('h06T'), 8)
        AddPlayerTechResearched(u.player, FourCC('R013'), 1)
        AddPlayerTechResearched(u.player, FourCC('R014'), 1)
        AddPlayerTechResearched(u.player, FourCC('R015'), 1)
        AddPlayerTechResearched(u.player, FourCC('R016'), 1)
        AddPlayerTechResearched(u.player, FourCC('R017'), 1)
        SetPlayerState(u.player, PLAYER_STATE_RESOURCE_FOOD_USED, 0)

        --player vision
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Tavern, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Church, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_InfiniteStruggleCameraBounds, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Town_Vision, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Town_Vision_2, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Colosseum, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Arena1, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Arena2, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Arena3, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Gods_Vision, false, false))

        --player multiboard tuples
        MB_SPOT[u.id] = i

        mbitem = MultiboardGetItem(MULTI_BOARD, i, 0)
        MultiboardSetItemValue(mbitem, u.nameColored)
        MultiboardSetItemStyle(mbitem, true, false)
        MultiboardSetItemWidth(mbitem, 0.1)
        MultiboardReleaseItem(mbitem)

        mbitem = MultiboardGetItem(MULTI_BOARD, i, 1)
        MultiboardSetItemStyle(mbitem, false, false)
        MultiboardSetItemWidth(mbitem, 0.015)
        MultiboardReleaseItem(mbitem)

        mbitem = MultiboardGetItem(MULTI_BOARD, i, 2)
        MultiboardSetItemStyle(mbitem, false, false)
        MultiboardSetItemWidth(mbitem, 0.015)
        MultiboardReleaseItem(mbitem)

        mbitem = MultiboardGetItem(MULTI_BOARD, i, 3)
        MultiboardSetItemStyle(mbitem, true, false)
        MultiboardSetItemWidth(mbitem, 0.1)
        MultiboardReleaseItem(mbitem)

        mbitem = MultiboardGetItem(MULTI_BOARD, i, 4)
        MultiboardSetItemStyle(mbitem, true, false)
        MultiboardSetItemWidth(mbitem, 0.03)
        MultiboardReleaseItem(mbitem)

        mbitem = MultiboardGetItem(MULTI_BOARD, i, 5)
        MultiboardSetItemStyle(mbitem, true, false)
        MultiboardSetItemWidth(mbitem, 0.03)
        MultiboardReleaseItem(mbitem)

        i = i + 1
        u = u.next
    end

    --neutral / enemy vision
    FogModifierStart(CreateFogModifierRect(Player(PLAYER_NEUTRAL_PASSIVE),FOG_OF_WAR_VISIBLE,bj_mapInitialPlayableArea, false, false))
    FogModifierStart(CreateFogModifierRect(pboss,FOG_OF_WAR_VISIBLE,gg_rct_Colosseum, false, false))
    FogModifierStart(CreateFogModifierRect(pboss,FOG_OF_WAR_VISIBLE,gg_rct_Gods_Vision, false, false))
    FogModifierStart(CreateFogModifierRect(pboss,FOG_OF_WAR_VISIBLE,gg_rct_InfiniteStruggleCameraBounds, false, false))

    --player clean on leave
    TriggerAddCondition(LEAVE_TRIGGER, Filter(onPlayerLeave))

    --setup alliances
    for i = 0, bj_MAX_PLAYERS do
        for i2 = 0, bj_MAX_PLAYERS do
            if i ~= i2 and GetPlayerController(Player(i)) == MAP_CONTROL_USER then
                SetPlayerAlliance(Player(i), Player(i2), ALLIANCE_SHARED_VISION, true)
                SetPlayerAlliance(Player(i), Player(i2), ALLIANCE_SHARED_CONTROL, false)
            end
        end
    end

    --turn off gold bounty from pfoe
    SetPlayerState(pfoe, PLAYER_STATE_GIVES_BOUNTY, 0)

    --not sure if needed
    SetMapFlag(MAP_LOCK_ALLIANCE_CHANGES, true)

    --disable neutral building default marketplace behavior
    PauseTimer(bj_stockUpdateTimer)
    DestroyTimer(bj_stockUpdateTimer)
    bj_stockUpdateTimer = nil
    DisableTrigger(bj_stockItemPurchased)

    --display multiboard and grab frame
    MultiboardDisplay(MULTI_BOARD, true)
    MultiBoard = BlzGetFrameByName("Multiboard", 0)

    i = 0
    -- give these frames a handleId
    while not (i >= BlzFrameGetChildrenCount(containerFrame) - 1) do
        frames[i] = BlzFrameGetChild(BlzFrameGetChild(containerFrame, i), 0)
        i = i + 1
    end

    --final misc touches
    bj_useDawnDuskSounds = false
    StopSound(bj_nightAmbientSound, true, false)
    StopSound(bj_dayAmbientSound, true, false)
    BlzChangeMinimapTerrainTex("MiniMap.dds")
    SetSkyModel("war3mapImported\\StarSphere.mdx")
    SetCameraBoundsToRect(gg_rct_Tavern_Vision)
    PanCameraToTimed(21645, 3430, 0)
    FogMaskEnable(true)
    FogEnable(true)
end)

if Debug then Debug.endFile() end
