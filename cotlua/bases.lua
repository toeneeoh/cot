if Debug then Debug.beginFile 'Bases' end

OnInit.final("Bases", function(require)
    require 'Users'

    BaseID = __jarray(0) ---@type integer[] 
    PlayerBase = {} ---@type unit[] 

    HomeTable = {
        { rate = 0.6, notification = " has built a nation and is not a bum anymore." },
        { rate = 1.0, notification = " has built a home and is not a bum anymore." },
        { rate = 1.1, notification = " has built a grand home." },
        { rate = 0.9, notification = " has upgraded to a grand nation." },
        { rate = 1.0, notification = " has built a spirit lounge." },
        { rate = 1.6, notification = " has built a satanic abode." },
        { rate = 1.3, notification = " has built a demonic nation." },
        [FourCC('h01U')] = 1, --nation
        [FourCC('h038')] = 1, --
        [FourCC('h030')] = 1, --
        [FourCC('h02T')] = 1, --
        [FourCC('h008')] = 2, --home
        [FourCC('h00E')] = 2, --
        [FourCC('h00K')] = 3, --grand home
        [FourCC('h047')] = 3,
        [FourCC('h01K')] = 4, --grand nation
        [FourCC('h01L')] = 4, --
        [FourCC('h01H')] = 4, --
        [FourCC('h01J')] = 4, --
        [FourCC('h03K')] = 5, --spirit lounge
        [FourCC('h04T')] = 6, --satan's abode
        [FourCC('h050')] = 7, --demon nation
    }

function OnResearch()
    local u = GetTriggerUnit() ---@type unit 
    local p = GetOwningPlayer(u) ---@type player 
    local uid = GetUnitTypeId(u) ---@type integer 
    local pid = GetPlayerId(p) + 1 ---@type integer 

    --grand nations
    if HomeTable[uid] == 4 then
        BaseID[pid] = 4

        DisplayTextToForce(FORCE_PLAYING, (User[p].nameColored .. HomeTable[BaseID[pid]].notification))
        DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 60., GetObjectName(uid) .. " experience modifier: " .. HomeTable[homeType].rate .. "x")
    --medean court
    elseif uid == FourCC('h047') then
        SetUnitAbilityLevel(u, FourCC('A0A5'), 2)
        SetUnitAbilityLevel(u, FourCC('A0A7'), 2)
        SetUnitAbilityLevel(u, FourCC('A0A9'), 2)
    end
end

---@type fun(pt: PlayerTimer)
function BaseDeath(pt)
    local p = Player(pt.pid - 1) ---@type player 

    if BaseID[pt.pid] == 0 then
        PanCameraToTimedLocForPlayer(p, TownCenter, 0)
        DisplayTextToForce(FORCE_PLAYING, User[pt.pid - 1].nameColored .. " was defeated by losing their base.")
        DisplayTimedTextToPlayer(p, 0, 0, 240., "You have lost the game. All of your structures and units have been removed from the game, however you may -repick to begin a new character in a new character save slot.")
        PlayerCleanup(pt.pid)
    else
        DisplayTextToPlayer(p, 0, 0, "You have narrowly avoided death this time. Be careful or next time you may not be so lucky...")
    end

    TimerDialogDisplay(Timer_Window_TUD[pid], false)
    DestroyTimerDialog(Timer_Window_TUD[pid])

    pt:destroy()
end

function OnBuild()
    local u   = GetConstructedStructure() ---@type unit 
    local id  = GetUnitTypeId(u) ---@type integer 
    local pid = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
    local x   = GetUnitX(u) ---@type number 
    local y   = GetUnitY(u) ---@type number 

    if RectContainsCoords(gg_rct_NoSin, x, y) then
        KillUnit(u)
        DisplayTextToPlayer(Player(pid - 1),0,0, "|cffff0000You can not build in town.|r")
        return
    end

    local homeType = HomeTable[id] ---@type integer

    if not homeType then
        return
    end

    if RectContainsCoords(MAIN_MAP.rect, x, y) == false then
        KillUnit(u)
        DisplayTextToPlayer(Player(pid - 1),0,0, "|cffff0000You can only build your home on the main map.|r")
        return
    end

    if homeType > 0 and BaseID[pid] > 0 then
        KillUnit(u)
        DisplayTextToPlayer(Player(pid - 1),0,0, "|cfff0000fOnly one base is allowed per player.|r")
        return
    end

    PlayerBase[pid] = u
    BaseID[pid] = homeType

    DisplayTextToForce(FORCE_PLAYING, (User[pid - 1].nameColored .. HomeTable[homeType].notification))
    DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 60., GetObjectName(id) .. " experience modifier: " .. HomeTable[homeType].rate .. "x")

    TimerDialogDisplay(Timer_Window_TUD[pid], false)
    QuestSetCompletedBJ(Bum_Stage, true)
    ExperienceControl(pid)
end

    local base = CreateTrigger() ---@type trigger 
    local research = CreateTrigger() ---@type trigger 
    local u = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(base, u.player, EVENT_PLAYER_UNIT_CONSTRUCT_FINISH, nil)
        TriggerRegisterPlayerUnitEvent(research, u.player, EVENT_PLAYER_UNIT_UPGRADE_FINISH, nil)
        u = u.next
    end

    TriggerAddAction(base, OnBuild)
    TriggerAddAction(research, OnResearch)
end)

if Debug then Debug.endFile() end
