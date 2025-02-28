--[[
    mapsetup.lua

    A library that executes any necessary map initialization after players have loaded in.
]]

OnInit.final("MapSetup", function(Require)
    Require('Users')
    Require('Variables')
    Require('Profile')

    local villagers = {
        {x = 181, y = 2353, model = "units\\critters\\VillagerMan\\VillagerMan"},
        {x = -80, y = 1938, model = "units\\critters\\VillagerKid\\VillagerKid"},
        {x = -538, y = 2388, model = "units\\critters\\VillagerKid\\VillagerKid"},
        {x = -727, y = 2041, model = "units\\critters\\VillagerMan\\VillagerMan"},
        {x = 1104, y = 1304, model = "war3mapImported\\Night Elf Villager.mdl"},
        {x = 243, y = 1064, model = "war3mapImported\\Blood Elf Villager.mdl"},
        {x = 314, y = 932, model = "war3mapImported\\blondeTC.mdl"},
        {x = 254, y = 265, model = "war3mapImported\\burnetteTC.mdl"},
        {x = 618, y = 324, model = "war3mapImported\\Blood Elf Villager.mdl"},
        {x = 1778, y = -234, model = "war3mapImported\\HighElfKid_ByEpsilon.mdl"},
        {x = 1342, y = 302, model = "war3mapImported\\GoblinKid.mdl"},
        {x = 711, y = -294, model = "war3mapImported\\BloodElfKid_ByEpsilon.mdl"},
        {x = 711, y = -294, model = "war3mapImported\\BloodElfKid_ByEpsilon.mdl"},
        {x = -920, y = 1034, model = "war3mapImported\\burnetteTC.mdl"},
        {x = -960, y = 1104, model = "war3mapImported\\Night Elf Villager.mdl"},
        {x = -2244, y = 480, model = "units\\critters\\VillagerWoman\\VillagerWoman"},
        {x = -1623, y = -669, model = "units\\critters\\VillagerWoman\\VillagerWoman"},
        {x = -1712, y = -756, model = "war3mapImported\\BloodElfKid_ByEpsilon.mdl"},
    }

    -- create town "villagers" (use special effects)
    for i = 1, #villagers do
        local v = villagers[i]
        v.unit = AddSpecialEffect(v.model, v.x, v.y)
        BlzSetSpecialEffectYaw(v.unit, GetRandomReal(0, 2 * bj_PI))
    end

    KILL_VILLAGERS = function()
        for i = 1, #villagers do
            local v = villagers[i]
            HideEffect(v.unit)
        end
        villagers = nil
    end

    -- create floating texttags
    SetTextTagText(ColoText, "", 15.00)
    SetTextTagPos(ColoText, 21710., -4261., 0)
    SetTextTagColor(ColoText, 235, 235, 21, 255)
    SetTextTagPermanent(ColoText, true)
    SetTextTagText(StruggleText, "", 15.00)
    SetTextTagPos(StruggleText, 28039., 4350., 0)
    SetTextTagColor(StruggleText, 235, 235, 21, 255)
    SetTextTagPermanent(StruggleText, true)

    -- ally enemies and bosses
    SetPlayerAllianceStateBJ(PLAYER_BOSS, PLAYER_CREEP, bj_ALLIANCE_ALLIED)
    SetPlayerAllianceStateBJ(PLAYER_CREEP, PLAYER_BOSS, bj_ALLIANCE_ALLIED)

    -- player loop
    local pos = 1
    local u = User.first
    while u do
        -- alliances / research / food state
        SetPlayerAllianceStateBJ(Player(PLAYER_TOWN), u.player, bj_ALLIANCE_ALLIED)
        SetPlayerAlliance(u.player, Player(PLAYER_NEUTRAL_PASSIVE), ALLIANCE_SHARED_SPELLS, true)
        SetPlayerState(u.player, PLAYER_STATE_RESOURCE_FOOD_USED, 0)

        -- player vision
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Tavern, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Church, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_InfiniteStruggleCameraBounds, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Town_Vision, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Town_Vision_2, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Colosseum, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Arena1, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Arena2, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Arena3, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Gods_Arena, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Training_Prechaos, false, false))
        FogModifierStart(CreateFogModifierRect(u.player, FOG_OF_WAR_VISIBLE, gg_rct_Training_Chaos, false, false))

        ForceAddPlayer(FORCE_HINT, u.player)

        pos = pos + 1
        u = u.next
    end

    -- neutral / enemy vision
    FogModifierStart(CreateFogModifierRect(Player(PLAYER_NEUTRAL_PASSIVE),FOG_OF_WAR_VISIBLE, WorldBounds.rect, false, false))
    FogModifierStart(CreateFogModifierRect(PLAYER_BOSS,FOG_OF_WAR_VISIBLE,gg_rct_Colosseum, false, false))
    FogModifierStart(CreateFogModifierRect(PLAYER_BOSS,FOG_OF_WAR_VISIBLE,gg_rct_Gods_Arena, false, false))
    FogModifierStart(CreateFogModifierRect(PLAYER_BOSS,FOG_OF_WAR_VISIBLE,gg_rct_InfiniteStruggleCameraBounds, false, false))

    -- player clean on leave
    TriggerAddCondition(LEAVE_TRIGGER, Filter(onPlayerLeave))

    -- setup alliances
    for i = 0, bj_MAX_PLAYERS do
        for i2 = 0, bj_MAX_PLAYERS do
            if i ~= i2 and GetPlayerController(Player(i)) == MAP_CONTROL_USER then
                SetPlayerAlliance(Player(i), Player(i2), ALLIANCE_SHARED_VISION, true)
                SetPlayerAlliance(Player(i), Player(i2), ALLIANCE_SHARED_CONTROL, false)
            end
        end
    end

    -- turn off gold bounty from PLAYER_CREEP
    SetPlayerState(PLAYER_CREEP, PLAYER_STATE_GIVES_BOUNTY, 0)

    -- not sure if needed
    SetMapFlag(MAP_LOCK_ALLIANCE_CHANGES, true)

    -- disable neutral building default marketplace behavior
    PauseTimer(bj_stockUpdateTimer)
    DestroyTimer(bj_stockUpdateTimer)
    DisableTrigger(bj_stockItemPurchased)

    -- final misc touches
    bj_useDawnDuskSounds = false
    StopSound(bj_nightAmbientSound, true, false)
    StopSound(bj_dayAmbientSound, true, false)
    BlzChangeMinimapTerrainTex("war3mapImported\\minimap_main.dds")
    SetSkyModel("war3mapImported\\StarSphere.mdx")
    SetCameraBoundsToRect(gg_rct_Tavern_Vision)
    PanCameraToTimed(21645, 3430, 0)

    FogMaskEnable(true)
    FogEnable(true)
    ShowInterface(true, 0)
    EnableUserControl(true)
	SetFloatGameState(GAME_STATE_TIME_OF_DAY, 6.)
    TimerQueue:callDelayed(0., DisplayCineFilter, false)
end, Debug and Debug.getLine())
