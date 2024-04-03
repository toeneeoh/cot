if Debug then Debug.beginFile 'Commands' end

--[[
    commands.lua

    A library to handle player chat commands with related functions.
]]

OnInit.final("Commands", function(require)
    require 'Users'

    VoteYay            = 0
    VoteNay            = 0
    autoAttackDisabled = {} ---@type boolean[] 
    fullItemStacking   = __jarray(true) ---@type boolean[] 
    bossResMod         = 1.
    destroyBaseFlag    = {} ---@type boolean[] 
    votekickPlayer     = 0
    votekickingPlayer  = 0

    VOTING_TYPE = 0
    I_VOTED     = {} ---@type boolean[] 

    CMD_LIST = {
        ["-commands"] = function(p, pid, args)
            DisplayTimedTextToPlayer(p, 0, 0, 30, "|cffffcc00Commands are located in F9.|r")
        end,
        ["-stats"] = function(p, pid, args)
            StatsInfo(p, tonumber(args[2]))
        end,
        ["-clear"] = function(p, pid, args)
            if p == GetLocalPlayer() then
                ClearTextMessages()
            end
        end,
        ["-destroybase"] = function(p, pid, args)
            if PlayerBase[pid] ~= nil then
                destroyBaseFlag[pid] = true
                SetUnitExploded(PlayerBase[pid], true)
                KillUnit(PlayerBase[pid])
            end
        end,
        ["-suicide"] = function(p, pid, args)
            reselect(Hero[pid])
            KillUnit(Hero[pid])
        end,
        ["-proficiency"] = function(p, pid, args)
            for i, _ in ipairs(PROF) do
                DisplayTimedTextToPlayer(p, 0, 0, 30, TYPE_NAME[i] .. ((HasProficiency(pid, PROF[i]) and " - |cffFF0909Y|r") or " - |cff00ff33X|r"))
            end
        end,
        ["-tome"] = function(p, pid, args)
            local stats = GetHeroStr(Hero[pid], false) + GetHeroAgi(Hero[pid], false) + GetHeroInt(Hero[pid], false)

            DisplayTextToPlayer(p, 0, 0, "|cffffcc00Total Stats:|r " .. stats)
            DisplayTextToPlayer(p, 0, 0, "|cffffcc00Tome Cap:|r " .. TomeCap(GetHeroLevel(Hero[pid])))
        end,
        ["-ready"] = function(p, pid, args)
            if TableHas(QUEUE_GROUP, p) then
                QUEUE_READY[pid] = true
            end
        end,
        ["-color"] = function(p, pid, args)
            local num = tonumber(args[2])

            if num and num > 0 and num < 26 then
                User[p].color = ConvertPlayerColor(num)
                User[p].hex = OriginalHex[num]
                User[p]:colorUnits()
                User[p].nameColored = OriginalHex[num] .. GetPlayerName(p) .. "|r"
                SetPlayerColor(p, ConvertPlayerColor(num))
            end
        end,
        ["-roll"] = function(p, pid, args)
            myRoll(pid)
        end,
        ["-estats"] = function(p, pid, args)
            if PlayerSelectedUnit[pid] then
                local atkspeed = 1. / BlzGetUnitAttackCooldown(PlayerSelectedUnit[pid], 0)
                if IsUnitType(PlayerSelectedUnit[pid], UNIT_TYPE_HERO) then
                    atkspeed = atkspeed * (1 + IMinBJ(GetHeroAgi(PlayerSelectedUnit[pid], true) + R2I(UnitGetBonus(PlayerSelectedUnit[pid], BONUS_ATTACK_SPEED) * 100), 400) * 0.01)
                else
                    atkspeed = atkspeed * (1 + IMinBJ(R2I(UnitGetBonus(PlayerSelectedUnit[pid], BONUS_ATTACK_SPEED) * 100), 400) * 0.01)
                end

                DisplayTimedTextToPlayer(p, 0, 0, 20, GetUnitName(PlayerSelectedUnit[pid]))
                DisplayTimedTextToPlayer(p, 0, 0, 20, "Level: " .. (GetUnitLevel(PlayerSelectedUnit[pid])))
                DisplayTimedTextToPlayer(p, 0, 0, 20, "Health: " .. RealToString(GetWidgetLife(PlayerSelectedUnit[pid])) .. " / " .. RealToString(BlzGetUnitMaxHP(PlayerSelectedUnit[pid])))
                DisplayTimedTextToPlayer(p, 0, 0, 20, "|cffffcc00Attack Speed: |r" .. R2S(atkspeed) .. " attacks per second")
                DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff800040Regeneration: |r" .. R2S(UnitGetBonus(PlayerSelectedUnit[pid], BONUS_LIFE_REGEN)) .. " health per second")
                DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff008080Evasion: |r" .. IMinBJ(100, (Unit[PlayerSelectedUnit[pid]].evasion)) .. "\x25")
                DisplayTimedTextToPlayer(p, 0, 0, 20, "Movespeed: " .. RealToString(GetUnitMoveSpeed(PlayerSelectedUnit[pid])))
            else
                DisplayTimedTextToPlayer(p, 0, 0, 20, "Please click a valid unit!")
            end
        end,
        ["-p"] = function(p, pid, args)
            if GetCurrency(pid, PLATINUM) > 0 then
                AddCurrency(pid, PLATINUM, -1)
                AddCurrency(pid, GOLD, 1000000)
                DisplayTimedTextToPlayer(p, 0, 0, 10, PlatTag .. (GetCurrency(pid, PLATINUM)))
            else
                DisplayTimedTextToPlayer(p, 0, 0, 20, "You need 1 Platinum Coin to buy this")
            end
        end,
        ["-a"] = function(p, pid, args)
            if GetCurrency(pid, ARCADITE) > 0 then
                AddCurrency(pid, ARCADITE, -1)
                AddCurrency(pid, LUMBER, 1000000)
                DisplayTimedTextToPlayer(p, 0, 0, 10, ArcTag .. (GetCurrency(pid, ARCADITE)))
            else
                DisplayTimedTextToPlayer(p, 0, 0, 20, "You need 1 Arcadite Lumber to buy this")
            end
        end,
        ["-pa"] = function(p, pid, args)
            local num = tonumber(args[2])
            if num and num <= PLAYER_CAP then
                DisplayTimedTextToPlayer(p, 0, 0, 30, PlatTag .. (GetCurrency(num, PLATINUM)))
                DisplayTimedTextToPlayer(p, 0, 0, 30, ArcTag .. (GetCurrency(num, ARCADITE)))
            else
                DisplayTimedTextToPlayer(p, 0, 0, 30, PlatTag .. (GetCurrency(num, PLATINUM)))
                DisplayTimedTextToPlayer(p, 0, 0, 30, ArcTag .. (GetCurrency(num, ARCADITE)))
            end
        end,
        ["-xp"] = function(p, pid, args)
            ShowExpRate(p, pid)
        end,
        ["-ms"] = function(p, pid, args)
            DisplayTimedTextToPlayer(p, 0, 0, 10, "Movespeed: " .. (Movespeed[pid]))
        end,
        ["-as"] = function(p, pid, args)
            local atkspeed = 1 / BlzGetUnitAttackCooldown(Hero[pid], 0)
            DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00Base Attack Speed: |r" .. R2S(atkspeed) .. " attacks per second")

            atkspeed = atkspeed * (1 + IMinBJ(GetHeroAgi(Hero[pid], true), 400) * 0.01)
            DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00Total Attack Speed: |r" .. R2S(atkspeed) .. " attacks per second.")
        end,
        ["-speed"] = function(p, pid, args)
            DisplayTimedTextToPlayer(p, 0, 0, 10, "Movespeed: " .. (Movespeed[pid]))
            local atkspeed = 1. / BlzGetUnitAttackCooldown(Hero[pid], 0)
            DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00Base Attack Speed: |r" .. R2S(atkspeed) .. " attacks per second")

            atkspeed = atkspeed * (1 + IMinBJ(GetHeroAgi(Hero[pid], true), 400) * 0.01)
            DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00Total Attack Speed: |r" .. R2S(atkspeed) .. " attacks per second.")
        end,
        ["-actions"] = function(p, pid, args)
            UnitRemoveAbility(Hero[pid], FourCC('A03C'))
            UnitAddAbility(Hero[pid], FourCC('A03C'))
        end,
        ["-flee"] = function(p, pid, args)
            FleeCommand(p)
        end,
        ["-cam"] = function(p, pid, args)
            if args[2] then
                local _, _, zoom, lock = args[2]:find("(\x25d+)\x25s.([lL])")

                if zoom then
                    CameraLock[pid] = (lock == "l") or CameraLock[pid]
                    Zoom[pid] = MathClamp(tonumber(zoom), 100, 3000)

                    if not selectingHero[pid] then
                        SetCameraFieldForPlayer(p, CAMERA_FIELD_TARGET_DISTANCE, zoom, 0)
                    end
                end
            end
        end,
        ["-aa"] = function(p, pid, args)
            ToggleAutoAttack(pid)
        end,
        ["-zml"] = function(p, pid, args, cmd)
            local _, _, lock = cmd:find("[lL]$")
            CameraLock[pid] = (lock == "l") or CameraLock[pid]
            Zoom[pid] = 2500

            if not selectingHero[pid] then
                SetCameraFieldForPlayer(p, CAMERA_FIELD_TARGET_DISTANCE, 2500, 0)
            end
        end,
        ["-lock"] = function(p, pid, args)
            CameraLock[pid] = true
        end,
        ["-unlock"] = function(p, pid, args)
            CameraLock[pid] = false
        end,
        ["-new"] = function(p, pid, args)
            NewProfile(pid)
        end,
        ["-info"] = function(p, pid, args)
            DisplayTimedTextToPlayer(p, 0, 0, 30, infoString[S2I(SubString(cmd,6,8))])
        end,
        ["-unstuck"] = function(p, pid, args)
            if GetLocalPlayer() == p then
                ShowInterface(false, 0)
                EnableUserControl(false)
                EnableOcclusion(false)
            end
            TimerQueue:callDelayed(0.5, function()
                if GetLocalPlayer() == p then
                    ShowInterface(true, 0)
                    EnableUserControl(true)
                    EnableOcclusion(true)
                end
            end)
        end,
        ["-st"] = function(p, pid, args)
            if Profile[pid] then
                Profile[pid]:saveCooldown()
            end
        end,
        ["-restime"] = function(p, pid, args)
            if TimerGetRemaining(rezretimer[pid]) <= 0.1 then
                DisplayTimedTextToPlayer(p, 0, 0, 20, "You can recharge.")
            else
                DisplayTimedTextToPlayer(p, 0, 0, 20, (R2I(TimerGetRemaining(rezretimer[pid]))) .. " seconds until you can recharge again.")
            end
        end,
        ["-autosave"] = function(p, pid, args)
            if Profile[pid] then
                Profile[pid]:toggleAutoSave()
            end
        end,
        ["-cancel"] = function(p, pid, args)
            if forceSaving[pid] then
                forceSaving[pid] = false
                IS_TELEPORTING[pid] = false
                PauseUnit(Hero[pid], false)
                PauseUnit(Backpack[pid], false)
                if (GetLocalPlayer() == p) then
                    ClearTextMessages()
                end
                DisplayTimedTextToPlayer(p, 0, 0, 60., "Force save aborted!")
                local pt = TimerList[pid]:get(FourCC('fsav'))

                if pt then
                    pt:destroy()
                end
            end
        end,
        ["-hardmode"] = function(p, pid, args)
            if HARD_MODE > 0 then
                DisplayTimedTextToPlayer(GetTriggerPlayer(), 0, 0, 5, "|cffffcc00Hard mode is already active.|r")
            else
                if VOTING_TYPE == 0 then
                    Hardmode()
                end
            end
        end,
        ["-votekick"] = function(p, pid, args)
            if VOTING_TYPE == 0 and User.AmountPlaying > 2 then
                local dw = DialogWindow.create(pid, "", VotekickPanelClick) ---@type DialogWindow
                local U = User.first

                while U do

                    if pid ~= U.id then
                        dw.data[dw.ButtonCount] = U.id
                        dw:addButton(U.nameColored)
                    end

                    U = U.next
                end
            end
        end,
        ["-repick"] = function(p, pid, args)
            if Profile[pid] then
                --TODO 30?
                if Profile[pid]:getSlotsUsed() >= 30 then
                    DisplayTimedTextToPlayer(p, 0, 0, 30.0, "You cannot save more than 30 heroes!")
                else
                    MainRepick(pid)
                end
            end
        end,
        ["-prestige"] = function(p, pid, args)
            PrestigeInfo(p, args[2])
        end,
        ["-quests"] = function(p, pid, args)
            DisplayQuestProgress(p)
        end,
        ["-hints"] = function(p, pid, args)
            if IsPlayerInForce(p, HINT_PLAYERS) then
                ForceRemovePlayer(HINT_PLAYERS, p)
                DisplayTimedTextToPlayer(p, 0, 0, 10, "Hints turned off.")
            else
                ForceAddPlayer(HINT_PLAYERS, p)
                DisplayTimedTextToPlayer(p, 0, 0, 10, "Hints turned on.")
            end
        end,
    }

    --alternate syntax
    CMD_LIST["-cl"] = CMD_LIST["-clear"]
    CMD_LIST["-clr"] = CMD_LIST["-clear"]

    CMD_LIST["-db"] = CMD_LIST["-destroybase"]

    CMD_LIST["-pf"] = CMD_LIST["-proficiency"]
    CMD_LIST["-prof"] = CMD_LIST["-proficiency"]

    CMD_LIST["-r"] = CMD_LIST["-ready"]

    CMD_LIST["-cash"] = CMD_LIST["-pa"]

    CMD_LIST["-autoattack"] = CMD_LIST["-aa"]

    CMD_LIST["-zm"] = CMD_LIST["-zml"]

    CMD_LIST["-newprofile"] = CMD_LIST["-new"]

    CMD_LIST["-savetime"] = CMD_LIST["-st"]

    CMD_LIST["-rt"] = CMD_LIST["-restime"]

    CMD_LIST["-q"] = CMD_LIST["-quests"]

    CMD_LIST["-nohints"] = CMD_LIST["-hints"]

---@return boolean
function NewProfileClick()
    local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw    = DialogWindow[pid] ---@type DialogWindow 
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        Profile[pid] = Profile.create(pid)
        SpawnWispSelector(pid)

        dw:destroy()
    end

    return false
end

---@param pid integer
function NewProfile(pid)
    if Profile[pid] then
        DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 30, "You already have a profile!")
    else
        local dw = DialogWindow.create(pid, "Start a new profile?\n|cFFFF0000Any existing profile will be\noverwritten.|r", NewProfileClick) ---@type DialogWindow

        dw:addButton("Yes")

        dw:display()
    end
end

---@type fun(user: player, pid: integer)
function ShowExpRate(user, pid)
    if InColo[pid] then
        DisplayTimedTextToPlayer(user,0,0, 30, "|cff808080Experience Rate: |r" .. R2S(XP_Rate[pid]) .. "\x25")
    else
        DisplayTimedTextToPlayer(user,0,0, 30, "|cff808080Experience Rate: |r" .. R2S(XP_Rate[pid]) .. "\x25")
        DisplayTimedTextToPlayer(user,0,0, 30, "|cff808080Colosseum Experience Multiplier: |r" .. R2S(Colosseum_XP[pid]*100.) .. "\x25")
    end
end

---@type fun(user: player, pid: integer?)
function StatsInfo(user, pid)
    pid = pid or GetPlayerId(user) + 1

    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cffFB4915Health: |r" .. RealToString(GetWidgetLife(Hero[pid])) .. " / " .. RealToString(BlzGetUnitMaxHP(Hero[pid])) .. " |cff6584edMana: |r" .. RealToString(GetUnitState(Hero[pid],UNIT_STATE_MANA)) .. " / " .. RealToString(GetUnitState(Hero[pid],UNIT_STATE_MAX_MANA)))
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cffff0b11Strength: |r" .. RealToString(GetHeroStr(Hero[pid], true)) .. "|cff00ff40 Agility: |r" .. RealToString(GetHeroAgi(Hero[pid], true)) .. "|cff0080ff Intelligence: |r" .. RealToString(GetHeroInt(Hero[pid], true)))
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cff800040Regeneration: |r" .. RealToString(UnitGetBonus(PlayerSelectedUnit[pid], BONUS_LIFE_REGEN)) .. " health per second")
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cff008080Evasion: |r" .. IMinBJ(100, (Unit[Hero[pid]].evasion)) .. "\x25")
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cffff8040Physical Damage Taken: |r" .. (Unit[Hero[pid]].dr * Unit[Hero[pid]].pr * 100) .. "\x25")
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cff8000ffMagic Damage Taken: |r" .. (Unit[Hero[pid]].dr * Unit[Hero[pid]].mr * 100) .. "\x25")
    if ShieldCount[pid] > 0 and HeroID[pid] == HERO_ROYAL_GUARDIAN then
        DisplayTimedTextToPlayer(user, 0, 0, 30, "Shield: " .. (ShieldCount[pid]))
    end
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cff00ffffSpellboost: |r" .. R2S(BoostValue[pid] * 100) .. "\x25")
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cffffcc00Gold Rate:|r +" .. (ItemGoldRate[pid]) .. "\x25")
    ShowExpRate(user, pid)
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cff808000Time Played: |r" .. (Profile[pid].hero.time // 60) .. " hours and " .. ModuloInteger(Profile[pid].hero.time, 60) .. " minutes")
end

function ApplyHardmode()
    BlzFrameSetVisible(votingBG, false)

    if CHAOS_LOADING then
        return
    end

    HARD_MODE = 1
    bossResMod = math.min(bossResMod, 0.75)

    DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00The game is now in hard mode: bosses are stronger, respawn faster, and have increased drop rates.|r")

    for i = BOSS_OFFSET, #BossTable do
        if UnitAlive(BossTable[i].unit) then
            SetHeroStr(BossTable[i].unit, GetHeroStr(BossTable[i].unit, true) * 2, true)
            BlzSetUnitBaseDamage(BossTable[i].unit, BlzGetUnitBaseDamage(BossTable[i].unit, 0) * 2 + 1, 0)
            SetWidgetLife(BossTable[i].unit, GetWidgetLife(BossTable[i].unit) + BlzGetUnitMaxHP(BossTable[i].unit) * 0.5) --heal
        end
    end
end

---@return boolean
function VotingMenu()
    local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

    if not I_VOTED[pid] then
        I_VOTED[pid] = true
        return true
    end

    return false
end

function CheckVote()
    if VOTING_TYPE == 1 then
        if (VoteYay + VoteNay) >= User.AmountPlaying then
            VOTING_TYPE = 0

            if VoteYay > VoteNay then
                ApplyHardmode()
            else
                DisplayTextToForce(FORCE_PLAYING, "Hardmode vote failed.")
            end
        end
    elseif VOTING_TYPE == 2 then
        if (VoteYay + VoteNay) >= User.AmountPlaying then
            VOTING_TYPE = 0

            if VoteYay > VoteNay then
                DisplayTextToForce(FORCE_PLAYING, User[votekickPlayer - 1].nameColored .. " has been kicked from the game.")
                CustomDefeatBJ(Player(votekickPlayer - 1), "You were vote kicked.")
            else
                DisplayTextToForce(FORCE_PLAYING, "Votekick vote failed.")
            end
        end
    end
end

function VoteYes()
    VoteYay = VoteYay + 1

    CheckVote()

    if GetLocalPlayer() == GetTriggerPlayer() then
        BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        BlzFrameSetVisible(votingBG, false)
    end
end

function VoteNo()
    VoteNay = VoteNay + 1

    CheckVote()

    if GetLocalPlayer() == GetTriggerPlayer() then
        BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        BlzFrameSetVisible(votingBG, false)
    end
end

function HardmodeVoteExpire()
    if VOTING_TYPE == 1 then
        BlzFrameSetVisible(votingBG, false)
        VOTING_TYPE = 0

        if VoteYay > VoteNay then
            ApplyHardmode()
        end
    end
end

function Hardmode()
    VOTING_TYPE = 1
    ResetVote()
    DisplayTimedTextToForce(FORCE_PLAYING, 30, "Voting for Hardmode has begun and will conclude in 30 seconds.")
    BlzFrameSetVisible(votingBG, true)
    BlzFrameSetTexture(votingBG, "war3mapImported\\hardmode.dds", 0, true)

    TimerQueue:callDelayed(30., HardmodeVoteExpire)
end

---@type fun(p: player)
function FleeCommand(p)
    local pid = GetPlayerId(p) + 1 ---@type integer 
    local U = User.first ---@type User 

    if InStruggle[pid] or InColo[pid] then
        Fleeing[pid] = true
        DisplayTimedTextToPlayer(p, 0, 0, 10, "You will escape once the current wave is complete.")
    elseif TableHas(GODS_GROUP, p) then
        if DeadGods == 4 then
            TableRemove(GODS_GROUP, p)
            MoveHeroLoc(pid, TownCenter)
        else
            DisplayTimedTextToPlayer(p, 0, 0, 10, "You cannot escape.")
        end
    elseif TableHas(Arena[ARENA_FFA], pid) then
        MoveHeroLoc(pid, TownCenter)
        ArenaQueue[pid] = 0
        TableRemove(Arena[ARENA_FFA], pid)

        while U do
                SetPlayerAllianceStateBJ(U.player, Player(pid - 1), bj_ALLIANCE_ALLIED_VISION)
                SetPlayerAllianceStateBJ(Player(pid - 1), U.player, bj_ALLIANCE_ALLIED_VISION)

                if hero_panel_on[pid * PLAYER_CAP + U.id] then
                    ShowHeroPanel(Player(pid - 1), U.player, true)
                end

                if hero_panel_on[U.id * PLAYER_CAP + pid] then
                    ShowHeroPanel(U.player, Player(pid - 1), true)
                end
            U = U.next
        end
    end
end

---@param p player
function DisplayQuestProgress(p)
    local i = 0 ---@type integer 
    local flag = (CHAOS_MODE and 1) or 0
    local index = KillQuest[flag][i]

    while index ~= 0 do
        local s = ""

        if KillQuest[index][KILLQUEST_COUNT] == KillQuest[index][KILLQUEST_GOAL] then
            s = "|cff40ff40"
        end

        DisplayTimedTextToPlayer(p, 0, 0, 10, KillQuest[index][KILLQUEST_NAME] .. ": " .. s .. (KillQuest[index][KILLQUEST_COUNT]) .. "/" .. (KillQuest[index][KILLQUEST_GOAL]) .. "|r |cffffcc01LVL " .. (KillQuest[index][KILLQUEST_MIN]) .. "-" .. (KillQuest[index][KILLQUEST_MAX]))
        i = i + 1
        index = KillQuest[flag][i]
    end
end

---@type fun(pid: integer)
function MainRepick(pid)
    --return if in hero selection or have not created a profile yet
    if selectingHero[pid] or not Profile[pid] then
        return
    end

    local p = Player(pid - 1)

    --allow repicking after hardcore death
    if HeroID[pid] ~= 0 then
        if IsUnitPaused(Hero[pid]) or not UnitAlive(Hero[pid]) then
            DisplayTextToPlayer(p, 0, 0, "You can't repick right now.")
            return
        elseif RectContainsUnit(gg_rct_Tavern, Hero[pid]) or RectContainsUnit(gg_rct_NoSin, Hero[pid]) or RectContainsUnit(gg_rct_Church, Hero[pid]) then
            ShowHeroCircle(p, true)
        else
            DisplayTextToPlayer(p, 0, 0, "You can only repick in church, town or tavern.")
            return
        end
    end

    Profile[pid].save_timer:reset()
    PlayerCleanup(pid)
    SpawnWispSelector(pid)
end

---@param p player
---@param pid integer
function PrestigeInfo(p, pid)
    if not pid then
        pid = GetPlayerId(p) + 1
    end

    if Hero[pid] == nil then
        return
    end
end

function DestroyRB()
    DestroyLeaderboard(RollBoard)
    RollChecks[30] = 0
end

---@param pid integer
function myRoll(pid)
    local i = 0 ---@type integer 
    if RollChecks[30] == 0 then
        RollChecks[30] = 1
        RollBoard = CreateLeaderboardBJ(FORCE_PLAYING, "Rolls")
        while i <= 8 do
            RollChecks[i] = 0
            i = i + 1
        end
        LeaderboardSetStyle(RollBoard, true, true, true, false)
        LeaderboardDisplayBJ(true, RollBoard)
        TimerQueue:callDelayed(20., DestroyRB)
    end

    if (RollChecks[30] > 0) and (RollChecks[pid] == 0) then
        RollChecks[pid] = 1
        LeaderboardAddItemBJ(Player(pid - 1), RollBoard, GetPlayerName(Player(pid - 1)), GetRandomInt(i, 100))
        LeaderboardSortItemsBJ(RollBoard, 0, false)
    end
end

---@type fun(): boolean
function CustomCommands()
    local cmd = GetEventPlayerChatString() ---@type string 
    local p = GetTriggerPlayer() ---@type player 
    local pid = GetPlayerId(p) + 1 ---@type integer 
    local args = {}

    --propogate args table
    for arg in cmd:gmatch("\x25S+") do
        args[#args + 1] = arg
    end

    if CMD_LIST[args[1]] then
        CMD_LIST[args[1]](p, pid, args, cmd)
    end

    --afk text
    if cmd:sub(2, #cmd) == AFK_TEXT and afkTextVisible[pid] then
        if GetLocalPlayer() == p then
            BlzFrameSetVisible(AFK_FRAME_BG, false)
        end

        afkTextVisible[pid] = false
        SoundHandler("Sound\\Interface\\GoodJob.wav", false, p)
    end

    return false
end

    local commands = CreateTrigger()
    local u = User.first

    while u do
        TriggerRegisterPlayerChatEvent(commands, u.player, "-", false)
        u = u.next
    end

    TriggerAddCondition(commands, Condition(CustomCommands))
end)

if Debug then Debug.endFile() end
