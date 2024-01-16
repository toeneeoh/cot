if Debug then Debug.beginFile 'PVP' end

OnInit.final("PVP", function(require)
    require 'Users'

    Arena       = {} ---@type group[] 
    ArenaQueue  = __jarray(0) ---@type integer[] 
    ArenaMax    = 3 ---@type integer 

---@type fun(pid: integer)
function ArenaUnpause(pid)
    PauseUnit(Hero[pid], false)
    UnitRemoveAbility(Hero[pid], FourCC('Avul'))
end

---@type fun(pid: integer, tpid: integer, time: integer)
function DuelCountdown(pid, tpid, time)
    time = time - 1

    if time == 0 then
        --start!
        PauseUnit(Hero[pid], false)
        PauseUnit(Hero[tpid], false)
        SoundHandler("Sound\\Interface\\GameFound.wav", false, Player(pid - 1), nil)
        SoundHandler("Sound\\Interface\\GameFound.wav", false, Player(tpid - 1), nil)
        DisplayTextToPlayer(Player(pid - 1), 0, 0, "FIGHT!")
        DisplayTextToPlayer(Player(tpid - 1), 0, 0, "FIGHT!")
    else
        --tick sound
        SoundHandler("Sound\\Interface\\BattleNetTick.wav", false, Player(pid - 1), nil)
        SoundHandler("Sound\\Interface\\BattleNetTick.wav", false, Player(tpid - 1), nil)
        DisplayTextToPlayer(Player(pid - 1), 0, 0, (time + 1) .. "...")
        DisplayTextToPlayer(Player(tpid - 1), 0, 0, (time + 1) .. "...")
        TimerQueue:callDelayed(1., DuelCountdown, pid, tpid, time)
    end
end

---@param a unit
---@param b unit
---@param spawn1 rect
---@param spawn2 rect
---@param face number
---@param face2 number
---@param arena integer
---@param cam rect
function SetupDuel(a, b, spawn1, spawn2, face, face2, arena, cam)
    local pid  = GetPlayerId(GetOwningPlayer(a)) + 1 ---@type integer 
    local tpid = GetPlayerId(GetOwningPlayer(b)) + 1 ---@type integer 
    local x    = GetRectCenterX(spawn1) ---@type number 
    local y    = GetRectCenterY(spawn1) ---@type number 
    local x2   = GetRectCenterX(spawn2) ---@type number 
    local y2   = GetRectCenterY(spawn2) ---@type number 
    local p    = GetOwningPlayer(a) ---@type player 
    local p2   = GetOwningPlayer(b) ---@type player 

    ArenaQueue[pid] = 0
    ArenaQueue[tpid] = 0

    CleanupSummons(p)
    CleanupSummons(p2)

    GroupAddUnit(Arena[arena], a)
    GroupAddUnit(Arena[arena], b)

    DisplayTextToPlayer(p, 0, 0, User[tpid - 1].nameColored .. " has joined the arena.")
    DisplayTextToPlayer(p2, 0, 0, User[pid - 1].nameColored .. " has joined the arena.")

    if GetRandomInt(0, 1) == 1 then
        SetUnitPosition(a, x, y)
        BlzSetUnitFacingEx(a, face)
        SetUnitPosition(b, x2, y2)
        BlzSetUnitFacingEx(b, face2)
    else
        SetUnitPosition(a, x2, y2)
        BlzSetUnitFacingEx(a, face2)
        SetUnitPosition(b, x, y)
        BlzSetUnitFacingEx(b, face)
    end

    SetPlayerAllianceStateBJ(p, p2, bj_ALLIANCE_UNALLIED)
    SetPlayerAllianceStateBJ(p2, p, bj_ALLIANCE_UNALLIED)

    if hero_panel_on[pid * PLAYER_CAP + tpid] == true then
        ShowHeroPanel(p, p2, true)
    end

    if hero_panel_on[tpid * PLAYER_CAP + pid] == true then
        ShowHeroPanel(p2, p, true)
    end

    PauseUnit(a, true)
    PauseUnit(b, true)

    SetCameraBoundsRectForPlayerEx(p, cam)
    SetCameraBoundsRectForPlayerEx(p2, cam)

    if GetLocalPlayer() == p then
        PanCameraToTimed(GetUnitX(a), GetUnitY(a), 0)
    end
    if GetLocalPlayer() == p2 then
        PanCameraToTimed(GetUnitX(b), GetUnitY(b), 0)
    end

    TimerQueue:callDelayed(1., DuelCountdown, pid, tpid, 3)
end

---@type fun(arena: integer, killed: unit)
function ArenaCleanup(arena, killed)

    --FFA
    if arena ~= 0 then
        local u = FirstOfGroup(Arena[arena])
        while u do
            GroupRemoveUnit(Arena[arena], u)
            SetUnitAnimation(u, "stand")
            SetUnitPositionLoc(u, TownCenter)
            SetWidgetLife(u, BlzGetUnitMaxHP(u))
            SetCameraBoundsRectForPlayerEx(GetOwningPlayer(u), gg_rct_Main_Map_Vision)
            PanCameraToTimedForPlayer(GetOwningPlayer(u), GetUnitX(u), GetUnitY(u), 0)
            ArenaQueue[GetPlayerId(GetOwningPlayer(u)) + 1] = 0
            TimerQueue:callDelayed(2., ArenaUnpause, GetPlayerId(GetOwningPlayer(u)) + 1)
            u = FirstOfGroup(Arena[arena])
        end
    else
        GroupRemoveUnit(Arena[arena], killed)
        SetUnitAnimation(killed, "stand")
        SetUnitPositionLoc(killed, TownCenter)
        SetWidgetLife(killed, BlzGetUnitMaxHP(killed))
        SetCameraBoundsRectForPlayerEx(GetOwningPlayer(killed), gg_rct_Main_Map_Vision)
        PanCameraToTimedForPlayer(GetOwningPlayer(killed), GetUnitX(killed), GetUnitY(killed), 0)
        ArenaQueue[GetPlayerId(GetOwningPlayer(killed)) + 1] = 0
        TimerQueue:callDelayed(2., ArenaUnpause, GetPlayerId(GetOwningPlayer(killed)) + 1)
    end
end

---@param u unit
---@param u2 unit
---@param arena integer
function ArenaDeath(u, u2, arena)
    local U    = User.first ---@type User 
    local p    = GetOwningPlayer(u) ---@type player 
    local p2   = GetOwningPlayer(u2) ---@type player 
    local pid  = GetPlayerId(p) + 1 ---@type integer 
    local tpid = GetPlayerId(p2) + 1 ---@type integer 

    ---FFA
    if arena ~= 0 then
        PauseUnit(u2, true)
        UnitAddAbility(u2, FourCC('Avul'))
        SetPlayerAllianceStateBJ(p, p2, bj_ALLIANCE_ALLIED_VISION)
        SetPlayerAllianceStateBJ(p2, p, bj_ALLIANCE_ALLIED_VISION)
        if hero_panel_on[pid * PLAYER_CAP + (tpid - 1)] then
            ShowHeroPanel(p, p2, true)
        end

        if hero_panel_on[tpid * PLAYER_CAP + (pid - 1)] then
            ShowHeroPanel(p2, p, true)
        end
    else
        while U do
            SetPlayerAllianceStateBJ(U.player, p, bj_ALLIANCE_ALLIED_VISION)
            SetPlayerAllianceStateBJ(p, U.player, bj_ALLIANCE_ALLIED_VISION)
            if hero_panel_on[pid * PLAYER_CAP + (tpid - 1)] then
                ShowHeroPanel(p, p2, true)
            end

            if hero_panel_on[tpid * PLAYER_CAP + (pid - 1)] then
                ShowHeroPanel(p2, p, true)
            end
            U = U.next
        end
    end

    --timer, cleanup
    TimerQueue:callDelayed(3., ArenaCleanup, arena, u)
end

---@param arena integer
---@param pid integer
---@return integer
function FirstOfArena(arena, pid)
    local tpid         = -1 ---@type integer 
    local U      = User.first ---@type User 

    while U do
        tpid = GetPlayerId(U.player) + 1

        if pid ~= tpid and ArenaQueue[tpid] == arena then
            return tpid
        end

        U = U.next
    end

    return tpid
end

---@param arena integer
---@return integer
function CountArenaQueue(arena)
    local pid ---@type integer 
    local count         = 0 ---@type integer 
    local U      = User.first ---@type User 

    while U do
        pid = GetPlayerId(U.player) + 1

        if ArenaQueue[pid] == arena then
            count = count + 1
        end

        U = U.next
    end

    return count
end

function EnterPVP()
    local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw    = DialogWindow[pid] ---@type DialogWindow 
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 
    local tpid  = FirstOfArena(index, pid) ---@type integer 
    local num   = 0 ---@type integer 
    local x     = 0. ---@type number 
    local y     = 0. ---@type number 
    local U     = User.first ---@type User 
    local p     = Player(pid - 1) ---@type player 

    if index ~= -1 then
        tpid = FirstOfArena(index, pid)
        ArenaQueue[pid] = index
        num = CountArenaQueue(index)

        if GetArena(pid) == 0 then
            if index == 0 then
                --FFA
                GroupAddUnit(Arena[index], Hero[pid])

                CleanupSummons(p)
                x = GetRandomReal(GetRectMinX(gg_rct_Arena2), GetRectMaxX(gg_rct_Arena2))
                y = GetRandomReal(GetRectMinY(gg_rct_Arena2), GetRectMaxY(gg_rct_Arena2))

                SetUnitPosition(Hero[pid], x, y)

                SetCameraBoundsRectForPlayerEx(p, gg_rct_Arena2Vision)
                if GetLocalPlayer() == p then
                    PanCameraToTimed(x, y, 0)
                end

                while U do
                    tpid = GetPlayerId(U.player) + 1

                    SetPlayerAllianceStateBJ(U.player, p, bj_ALLIANCE_UNALLIED)
                    SetPlayerAllianceStateBJ(p, U.player, bj_ALLIANCE_UNALLIED)

                    if hero_panel_on[pid * PLAYER_CAP + (tpid - 1)] == true then
                        ShowHeroPanel(p, U.player, true)
                    end

                    if hero_panel_on[tpid * PLAYER_CAP + (pid - 1)] == true then
                        ShowHeroPanel(U.player, p, true)
                    end
                    U = U.next
                end

                DisplayTextToPlayer(p, 0, 0, "Type -flee to leave anytime.")
            elseif index == 1 then
                if num == 1 then
                    DisplayTextToPlayer(p, 0, 0, "Waiting for an opponent to join...")
                elseif num == 2 then
                    SetupDuel(Hero[pid], Hero[tpid], gg_rct_Arena1Spawn1, gg_rct_Arena1Spawn2, 270, 90, index, gg_rct_Arena1Vision)
                else
                    DisplayTextToPlayer(p, 0, 0, "This arena is occupied already!")
                    ArenaQueue[pid] = 0
                end
            elseif index == 2 then
                if num == 1 then
                    DisplayTextToPlayer(p, 0, 0, "Waiting for an opponent to join...")
                elseif num == 2 then
                    SetupDuel(Hero[pid], Hero[tpid], gg_rct_Arena3Spawn1, gg_rct_Arena3Spawn2, 0, 180, index, gg_rct_Arena3Vision)
                else
                    DisplayTextToPlayer(p, 0, 0, "This arena is occupied already!")
                    ArenaQueue[pid] = 0
                end
            end
        end
    end
end

    Arena[0] = CreateGroup()
    Arena[1] = CreateGroup()
    Arena[2] = CreateGroup()

end)

if Debug then Debug.endFile() end
