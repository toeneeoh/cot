OnInit.final("PVP", function(Require)
    Require('Users')

    ARENA_FFA = 1

    ArenaQueue = __jarray(0) ---@type integer[] 
    Arena = {
        {}, {}, {}
    }

    local ArenaSpawn = {
        --spawn location and associated facing angle
        [2] = {gg_rct_Arena1Spawn1, gg_rct_Arena1Spawn2, 270, 90},
        [3] = {gg_rct_Arena3Spawn1, gg_rct_Arena3Spawn2, 0, 180},
    }

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

---@param spawn1 rect
---@param spawn2 rect
---@param face number
---@param face2 number
---@param arena integer
function SetupDuel(pid, tpid, spawn1, spawn2, face, face2, arena)
    local x  = GetRectCenterX(spawn1) ---@type number 
    local y  = GetRectCenterY(spawn1) ---@type number 
    local x2 = GetRectCenterX(spawn2) ---@type number 
    local y2 = GetRectCenterY(spawn2) ---@type number 
    local p  = GetOwningPlayer(a)
    local p2 = GetOwningPlayer(b)

    ArenaQueue[pid] = 0
    ArenaQueue[tpid] = 0

    CleanupSummons(p)
    CleanupSummons(p2)

    Arena[arena][#Arena[arena] + 1] = Player(pid - 1)
    Arena[arena][#Arena[arena] + 1] = Player(tpid - 1)

    DisplayTextToPlayer(p, 0, 0, User[tpid - 1].nameColored .. " has joined the arena.")
    DisplayTextToPlayer(p2, 0, 0, User[pid - 1].nameColored .. " has joined the arena.")

    --randomize start location
    if GetRandomInt(0, 1) == 1 then
        local tempX = x
        local tempY = y
        local tempFace = face

        x = x2
        y = y2
        face = face2

        x2 = tempX
        y2 = tempY
        face2 = tempFace
    end

    MoveHero(pid, x, y)
    MoveHero(tpid, x2, y2)
    BlzSetUnitFacingEx(Hero[pid], face)
    BlzSetUnitFacingEx(Hero[tpid], face2)

    SetPlayerAllianceStateBJ(p, p2, bj_ALLIANCE_UNALLIED)
    SetPlayerAllianceStateBJ(p2, p, bj_ALLIANCE_UNALLIED)

    if IS_HERO_PANEL_ON[pid * PLAYER_CAP + tpid] then
        ShowHeroPanel(p, p2, true)
    end

    if IS_HERO_PANEL_ON[tpid * PLAYER_CAP + pid] then
        ShowHeroPanel(p2, p, true)
    end

    PauseUnit(a, true)
    PauseUnit(b, true)

    TimerQueue:callDelayed(1., DuelCountdown, pid, tpid, 3)
end

---@type fun(arena: integer, killed: unit)
function ArenaCleanup(arena, killed)

    if arena == ARENA_FFA then
        local pid = GetPlayerId(GetOwningPlayer(killed)) + 1
        TableRemove(Arena[arena], pid)
        SetUnitAnimation(killed, "stand")
        MoveHeroLoc(pid, TownCenter)
        SetWidgetLife(killed, BlzGetUnitMaxHP(killed))
        ArenaQueue[pid] = 0
        TimerQueue:callDelayed(2., ArenaUnpause, pid)
    else
        for _, pid in ipairs(Arena[arena]) do
            SetUnitAnimation(Hero[pid], "stand")
            SetWidgetLife(Hero[pid], BlzGetUnitMaxHP(Hero[pid]))
            MoveHeroLoc(pid, TownCenter)
            ArenaQueue[pid] = 0
            TimerQueue:callDelayed(2., ArenaUnpause, pid)
        end
        Arena[arena] = {}
    end
end

---@param killed unit
---@param killer unit
---@param arena integer
function ArenaDeath(killed, killer, arena)
    local U    = User.first ---@type User 
    local p    = GetOwningPlayer(killed)
    local p2   = GetOwningPlayer(killer)
    local pid  = GetPlayerId(p) + 1 ---@type integer 
    local tpid = GetPlayerId(p2) + 1 ---@type integer 

    if arena == ARENA_FFA then
        while U do
            SetPlayerAllianceStateBJ(U.player, p, bj_ALLIANCE_ALLIED_VISION)
            SetPlayerAllianceStateBJ(p, U.player, bj_ALLIANCE_ALLIED_VISION)
            if IS_HERO_PANEL_ON[pid * PLAYER_CAP + (tpid - 1)] then
                ShowHeroPanel(p, p2, true)
            end

            if IS_HERO_PANEL_ON[tpid * PLAYER_CAP + (pid - 1)] then
                ShowHeroPanel(p2, p, true)
            end
            U = U.next
        end
    else
        PauseUnit(killer, true)
        UnitAddAbility(killer, FourCC('Avul'))
        SetPlayerAllianceStateBJ(p, p2, bj_ALLIANCE_ALLIED_VISION)
        SetPlayerAllianceStateBJ(p2, p, bj_ALLIANCE_ALLIED_VISION)
        if IS_HERO_PANEL_ON[pid * PLAYER_CAP + (tpid - 1)] then
            ShowHeroPanel(p, p2, true)
        end

        if IS_HERO_PANEL_ON[tpid * PLAYER_CAP + (pid - 1)] then
            ShowHeroPanel(p2, p, true)
        end
    end

    --timer, cleanup
    TimerQueue:callDelayed(3., ArenaCleanup, arena, killed)
end

---@type fun(arena: integer, pid: integer): integer?
function FirstOfArena(arena, pid)
    local U = User.first ---@type User 

    while U do
        local tpid = GetPlayerId(U.player) + 1

        if pid ~= tpid and ArenaQueue[tpid] == arena then
            return tpid
        end

        U = U.next
    end

    return nil
end

---@type fun(arena: integer): integer
function InArenaQueue(arena)
    local U = User.first ---@type User 
    local count = 0

    while U do
        if ArenaQueue[U.id] == arena then
            count = count + 1
        end

        U = U.next
    end

    return count
end

function EnterPVP()
    local p     = GetTriggerPlayer()
    local pid   = GetPlayerId(p) + 1 ---@type integer 
    local dw    = DialogWindow[pid] ---@type DialogWindow 
    local arena = dw:getClickedIndex(GetClickedButton()) + 1 ---@type integer 

    if arena > 0 then

        local tpid = FirstOfArena(arena, pid)
        local num = InArenaQueue(arena)

        if not GetArena(pid) then
            if arena == ARENA_FFA then
                Arena[arena][#Arena[arena] + 1] = pid

                CleanupSummons(p)
                local x, y
                repeat
                    x = GetRandomReal(GetRectMinX(gg_rct_Arena2), GetRectMaxX(gg_rct_Arena2))
                    y = GetRandomReal(GetRectMinY(gg_rct_Arena2), GetRectMaxY(gg_rct_Arena2))
                until IsTerrainWalkable(x, y)

                MoveHero(pid, x, y)

                local U = User.first

                while U do
                    SetPlayerAllianceStateBJ(U.player, p, bj_ALLIANCE_UNALLIED)
                    SetPlayerAllianceStateBJ(p, U.player, bj_ALLIANCE_UNALLIED)

                    if IS_HERO_PANEL_ON[pid * PLAYER_CAP + (U.id - 1)] then
                        ShowHeroPanel(p, U.player, true)
                    end

                    if IS_HERO_PANEL_ON[U.id * PLAYER_CAP + (pid - 1)] then
                        ShowHeroPanel(U.player, p, true)
                    end
                    U = U.next
                end

                DisplayTextToPlayer(p, 0, 0, "Type -flee to leave anytime.")
            else
                ArenaQueue[pid] = arena

                if #Arena[arena] > 0 then
                    DisplayTextToPlayer(p, 0, 0, "This arena is occupied already!")
                    ArenaQueue[pid] = 0
                elseif num == 1 then
                    DisplayTextToPlayer(p, 0, 0, "Waiting for an opponent to join...")
                elseif num == 2 then
                    SetupDuel(pid, tpid, ArenaSpawn[arena][1], ArenaSpawn[arena][2], ArenaSpawn[arena][3], ArenaSpawn[arena][4], arena)
                end
            end
        end

        dw:destroy()
    end
end

end, Debug and Debug.getLine())
