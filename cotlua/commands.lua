if Debug then Debug.beginFile 'Commands' end

OnInit.final("Commands", function(require)
    require 'Users'

    autosave            = __jarray(false) ---@type boolean[] 
    VoteYay             = 0
    VoteNay             = 0
    autoAttackDisabled  = __jarray(false) ---@type boolean[] 
    bossResMod          = 1.
    destroyBaseFlag     = __jarray(false) ---@type boolean[] 
    votekickPlayer      = 0
    votekickingPlayer   = 0

    ArcTag     = "|cff66FF66Arcadite Lumber|r: " ---@type string 
    PlatTag    = "|cffccccccPlatinum Coins|r: " ---@type string 
    CrystalTag = "|cff6969FFCrystals: |r" ---@type string 

    VOTING_TYPE = 0 
    I_VOTED     =__jarray(false) ---@type boolean[] 

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

---@type fun(pid: integer, bonus: number, type: integer, plat: boolean)
function StatTome(pid, bonus, type, plat)
    local p              = Player(pid - 1)
    local totalStats     = 0
    local trueBonus      = 0
    local msg            = "You gained |cffffcc00"
    local hlev           = GetHeroLevel(Hero[pid])
    local levelMax       = TomeCap(hlev)

    if hlev > 25 then
        totalStats = IMaxBJ(250, GetHeroStr(Hero[pid],false) + GetHeroAgi(Hero[pid],false) + GetHeroInt(Hero[pid],false))
    else
        totalStats = IMaxBJ(50, GetHeroStr(Hero[pid],false) + GetHeroAgi(Hero[pid],false) + GetHeroInt(Hero[pid],false))
    end

    trueBonus = R2I(bonus * 17.2 // Pow(totalStats, 0.35))

    if totalStats > levelMax then
        DisplayTextToPlayer(p, 0, 0, "You cannot buy any more tomes until you level up further, no gold has been charged.")
        return
    elseif not plat then
        if type == 4 then
            AddCurrency(pid, GOLD, -20000)
        else
            AddCurrency(pid, GOLD, -10000)
        end
    elseif plat then
        if hlev < 100 then
            return
        end

        if type == 4 then
            AddCurrency(pid, PLATINUM, -2)
        else
            AddCurrency(pid, PLATINUM, -1)
        end
    end

    local statText = {
        "|r Strength.",
        "|r Agility.",
        "|r Intelligence.",
        "|r All Stats.",
    }

    if type == 1 then
        SetHeroStr(Hero[pid], GetHeroStr(Hero[pid], false) + trueBonus, true)
    elseif type == 2 then
        SetHeroAgi(Hero[pid], GetHeroAgi(Hero[pid], false) + trueBonus, true)
    elseif type == 3 then
        SetHeroInt(Hero[pid], GetHeroInt(Hero[pid], false) + trueBonus, true)
    elseif type == 4 then
        SetHeroStr(Hero[pid], GetHeroStr(Hero[pid], false) + trueBonus, true)
        SetHeroAgi(Hero[pid], GetHeroAgi(Hero[pid], false) + trueBonus, true)
        SetHeroInt(Hero[pid], GetHeroInt(Hero[pid], false) + trueBonus, true)
    end

    DisplayTextToPlayer(p, 0, 0, msg .. trueBonus .. statText[type])

    DestroyEffect(AddSpecialEffectTarget("Objects\\InventoryItems\\tomeRed\\tomeRed.mdl", Hero[pid], "chest"))
    DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIam\\AIamTarget.mdl", Hero[pid], "chest"))
end

---@type fun(p: player, flat: integer, percent: number, minimum: integer, message: string)
function ChargeNetworth(p, flat, percent, minimum, message)
    local pid          = GetPlayerId(p) + 1
    local playerGold   = GetCurrency(pid, GOLD)
    local playerLumber = GetCurrency(pid, LUMBER)
    local platCost     = R2I(GetCurrency(pid, PLATINUM) * percent)
    local arcCost      = R2I(GetCurrency(pid, ARCADITE) * percent)

    local cost = flat + R2I(playerGold * percent)
    if cost < minimum then
        cost = minimum
    end

    AddCurrency(pid, GOLD, -cost)
    AddCurrency(pid, PLATINUM, -platCost)

    if message ~= "" then
        if platCost > 0 then
            message = message .. " " .. RealToString(platCost) .. " platinum, " .. RealToString(cost) .. " gold"
        else
            message = message .. " " .. RealToString(cost) .. " gold"
        end
    end

    cost = flat + R2I(playerLumber * percent)
    if cost < minimum then
        cost = minimum
    end

    AddCurrency(pid, LUMBER, -cost)
    AddCurrency(pid, ARCADITE, -arcCost)

    if message ~= "" then
        if arcCost > 0 then
            message = message .. ", " .. RealToString(arcCost) .. " arcadite, and " .. RealToString(cost) .. " lumber."
        else
            message = message .. " and " .. RealToString(cost) .. " lumber."
        end
        DisplayTextToPlayer(p, 0, 0, message)
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

---@type fun(user: player, pid: integer)
function StatsInfo(user, pid)
    if pid == 0 then
        pid = GetPlayerId(user) + 1
    end

    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cffFB4915Health: |r" .. RealToString(GetUnitState(Hero[pid],UNIT_STATE_LIFE)) .. " / " .. RealToString(BlzGetUnitMaxHP(Hero[pid])) .. " |cff6584edMana: |r" .. RealToString(GetUnitState(Hero[pid],UNIT_STATE_MANA)) .. " / " .. RealToString(GetUnitState(Hero[pid],UNIT_STATE_MAX_MANA)))
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cffff0b11Strength: |r" .. RealToString(GetHeroStr(Hero[pid], true)) .. "|cff00ff40 Agility: |r" .. RealToString(GetHeroAgi(Hero[pid], true)) .. "|cff0080ff Intelligence: |r" .. RealToString(GetHeroInt(Hero[pid], true)))
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cff800040Regeneration: |r" .. RealToString(UnitGetBonus(PlayerSelectedUnit[pid], BONUS_LIFE_REGEN)) .. " health per second")
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cff008080Evasion: |r" .. (TotalEvasion[pid]) .. "\x25")
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cffff8040Physical Damage Taken: |r" .. R2S(PhysicalTaken[pid] * 100) .. "\x25")
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cff8000ffMagic Damage Taken: |r" .. R2S(MagicTaken[pid] * 100) .. "\x25")
    if ShieldCount[pid] > 0 and HeroID[pid] == HERO_ROYAL_GUARDIAN then
        DisplayTimedTextToPlayer(user, 0, 0, 30, "Shield: " .. (ShieldCount[pid]))
    end
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cff00ffffSpellboost: |r" .. R2S(BoostValue[pid] * 100) .. "\x25")
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cffffcc00Gold Rate:|r +" .. (ItemGoldRate[pid]) .. "\x25")
    ShowExpRate(user, pid)
    DisplayTimedTextToPlayer(user, 0, 0, 30, "|cff808000Time Played: |r" .. (R2I(TimePlayed[pid] / 60.)) .. " hours and " .. ModuloInteger(TimePlayed[pid], 60) .. " minutes")
end

function ApplyHardmode()
    BlzFrameSetVisible(votingBG, false)

    if CHAOS_LOADING then
        return
    end

    HARD_MODE = 1
    bossResMod = math.min(bossResMod, 0.75)

    DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00The game is now in hard mode: bosses are stronger, respawn faster, and have increased drop rates.|r")

    for i = 0, BOSS_TOTAL do
        if UnitAlive(Boss[i]) then
            SetHeroStr(Boss[i], GetHeroStr(Boss[i], true) * 2, true)
            BlzSetUnitBaseDamage(Boss[i], BlzGetUnitBaseDamage(Boss[i], 0) * 2 + 1, 0)
            SetWidgetLife(Boss[i], GetWidgetLife(Boss[i]) + BlzGetUnitMaxHP(Boss[i]) * 0.5) --heal
        end
    end
end

---@return boolean
function VotingMenu()
    local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

    if I_VOTED[pid] == false then
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
    BlzFrameSetTexture(votingBG, "war4mapImported\\hardmode.dds", 0, true)

    TimerQueue:callDelayed(30., HardmodeVoteExpire)
end

---@param currentPlayer player
function FleeCommand(currentPlayer)
    local pid = GetPlayerId(currentPlayer) + 1 ---@type integer 
    local U = User.first ---@type User 

    if InStruggle[pid] or InColo[pid] then
        Fleeing[pid] = true
        DisplayTimedTextToPlayer(currentPlayer, 0, 0, 10, "You will escape once the current wave is complete.")
    elseif IsPlayerInForce(currentPlayer, AZAZOTH_GROUP) then
        if (not ChaosMode and DeadGods == 4) or (ChaosMode and not UnitAlive(Boss[BOSS_AZAZOTH])) then
            ForceRemovePlayer(AZAZOTH_GROUP, currentPlayer)
            MoveHeroLoc(pid, TownCenter)
            SetCameraBoundsRectForPlayerEx(currentPlayer, gg_rct_Main_Map_Vision)
            PanCameraToTimedLocForPlayer(currentPlayer, TownCenter, 0)
        else
            DisplayTimedTextToPlayer(currentPlayer, 0, 0, 10, "You cannot escape.")
        end
    elseif IsUnitInGroup(Hero[pid], Arena[0]) then
        GroupRemoveUnit(Arena[0], Hero[pid])
        MoveHeroLoc(pid, TownCenter)
        SetCameraBoundsRectForPlayerEx(currentPlayer, gg_rct_Main_Map_Vision)
        PanCameraToTimedLocForPlayer(currentPlayer, TownCenter, 0)
        ArenaQueue[pid] = 0

        while U do
                SetPlayerAllianceStateBJ(U.player, Player(pid - 1), bj_ALLIANCE_ALLIED_VISION)
                SetPlayerAllianceStateBJ(Player(pid - 1), U.player, bj_ALLIANCE_ALLIED_VISION)

                if hero_panel_on[pid * PLAYER_CAP + U.id] == true then
                    ShowHeroPanel(Player(pid - 1), U.player, true)
                end

                if hero_panel_on[U.id * PLAYER_CAP + pid] == true then
                    ShowHeroPanel(U.player, Player(pid - 1), true)
                end
            U = U.next
        end
    end
end

---@param p player
function DisplayQuestProgress(p)
    local i = 0 ---@type integer 
    local flag = (ChaosMode and 1) or 0
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
    --cancel if in hero selection or have not created a profile yet
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

    TimerStart(SaveTimer[pid], 1, false, nil)
    PlayerCleanup(pid)
    SpawnWispSelector(pid)
end

---@param p player
---@param pid integer
function PrestigeInfo(p, pid)
    if pid == 0 then
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
    local U = User.first ---@type User 

    if (cmd == "-cc") or (cmd == "-commands") then
        DisplayTimedTextToPlayer(p, 0, 0, 30, "|cffffcc00Commands are located in F9.|r")

    elseif (SubString(cmd,0,6) == "-stats") then
        StatsInfo(p, S2I(SubString(cmd,7,8)))

    elseif (cmd=="-clear") or (cmd=="-cl") or (cmd=="-clr") then
        if p == GetLocalPlayer() then
            ClearTextMessages()
        end

    elseif (cmd == "-suicide base") or (cmd == "-destroy base") or (cmd == "-db") then
        if PlayerBase[pid] ~= nil then
            destroyBaseFlag[pid] = true
            SetUnitExploded(PlayerBase[pid], true)
            KillUnit(PlayerBase[pid])
        end

    elseif (cmd == "-suicide") then
        reselect(Hero[pid])
        KillUnit(Hero[pid])

    elseif (cmd == "-revive") or (cmd == "-rv") then
        if IsUnitHidden(HeroGrave[pid]) == false or UnitAlive(Hero[pid]) then
            DisplayTimedTextToPlayer(p, 0, 0, 10, "Unable to revive because your hero isn't dead.")
        else
            TimerList[pid]:stopAllTimers(FourCC('dead'))
            RevivePlayer(pid, GetLocationX(TownCenter), GetLocationY(TownCenter), 1, 1)
            SetCameraBoundsRectForPlayerEx(p, MAIN_MAP.rect)
            PanCameraToTimedLocForPlayer(p, TownCenter, 0)
            DestroyTimerDialog(RTimerBox[pid])

            ChargeNetworth(p, 0, 0.01, 50 * GetHeroLevel(Hero[pid]), "Revived instantly for")
        end

    elseif (cmd == "-proficiency") or (cmd == "-pf") then
        for i = 1, 10 do
            if BlzBitAnd(HERO_PROF[pid], PROF[i]) == 0 then
                DisplayTimedTextToPlayer(p, 0, 0, 30, TYPE_NAME[i] .. " - |cffFF0909X|r")
            else
                DisplayTimedTextToPlayer(p, 0, 0, 30, TYPE_NAME[i] .. " - |cff00ff33Y|r")
            end
        end

    elseif (SubString(cmd,0,6) == "-stats") then
        StatsInfo(p, S2I(SubString(cmd,7,8)))

    elseif (SubString(cmd,0,5) == "-tome") then
        local stats = GetHeroStr(Hero[pid],false) + GetHeroAgi(Hero[pid],false) + GetHeroInt(Hero[pid],false)

        DisplayTextToPlayer(p, 0, 0, "|cffffcc00Total Stats:|r " .. stats)
        DisplayTextToPlayer(p, 0, 0, "|cffffcc00Tome Cap:|r " .. TomeCap(GetHeroLevel(Hero[pid])))

    elseif (cmd == "-r") or (cmd == "-ready") then
        if TableHas(QUEUE_GROUP, p) then
            QUEUE_READY[pid] = true
        end

    elseif (SubString(cmd, 0, 6) == "-color") and S2I(SubString(cmd, 7, StringLength(cmd))) > 0 and S2I(SubString(cmd, 7, StringLength(cmd))) < 26 then
        local id = S2I(SubString(cmd, 7, StringLength(cmd))) - 1

        User[p].color = ConvertPlayerColor(id)
        User[p].hex = OriginalHex[id]
        User[p]:colorUnits()
        User[p].nameColored = OriginalHex[id] .. GetPlayerName(p) .. "|r"
        SetPlayerColor(p, ConvertPlayerColor(id))

    elseif (cmd == "-roll") then
        myRoll(pid)

    elseif (cmd == "-estats") then
        local atkspeed = 1. / BlzGetUnitAttackCooldown(PlayerSelectedUnit[pid], 0)
        if IsUnitType(PlayerSelectedUnit[pid], UNIT_TYPE_HERO) then
            atkspeed = atkspeed * (1 + IMinBJ(GetHeroAgi(PlayerSelectedUnit[pid], true) + R2I(UnitGetBonus(PlayerSelectedUnit[pid], BONUS_ATTACK_SPEED) * 100), 400) * 0.01)
        else
            atkspeed = atkspeed * (1 + IMinBJ(R2I(UnitGetBonus(PlayerSelectedUnit[pid], BONUS_ATTACK_SPEED) * 100), 400) * 0.01)
        end

        DisplayTimedTextToPlayer(p, 0, 0, 20, GetUnitName(PlayerSelectedUnit[pid]))
        DisplayTimedTextToPlayer(p, 0, 0, 20, "Level: " .. (GetUnitLevel(PlayerSelectedUnit[pid])))
        DisplayTimedTextToPlayer(p, 0, 0, 20, "Health: " .. RealToString(GetWidgetLife(PlayerSelectedUnit[pid]))+ " / " .. RealToString(BlzGetUnitMaxHP(PlayerSelectedUnit[pid])))
        DisplayTimedTextToPlayer(p, 0, 0, 20, "|cffffcc00Attack Speed: |r" .. R2S(atkspeed) .. " attacks per second")
        DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff800040Regeneration: |r" .. R2S(UnitGetBonus(PlayerSelectedUnit[pid], BONUS_LIFE_REGEN)) .. " health per second")
        DisplayTimedTextToPlayer(p, 0, 0, 20, "Movespeed: " .. RealToString(GetUnitMoveSpeed(PlayerSelectedUnit[pid])))

    elseif (cmd == "-pcoins") then
        DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag + (GetCurrency(pid, PLATINUM)))

    elseif (cmd == "-awood") then
        DisplayTimedTextToPlayer(p, 0, 0, 20, ArcTag + (GetCurrency(pid, ARCADITE)))

    elseif (cmd == "-p") then
        if GetCurrency(pid, PLATINUM) > 0 then
            AddCurrency(pid, PLATINUM, -1)
            AddCurrency(pid, GOLD, 1000000)
            DisplayTimedTextToPlayer(p, 0, 0, 10, PlatTag + (GetCurrency(pid, PLATINUM)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need 1 Platinum Coin to buy this")
        end

    elseif (cmd == "-a") then
        if GetCurrency(pid, ARCADITE) > 0 then
            AddCurrency(pid, ARCADITE, -1)
            AddCurrency(pid, LUMBER, 1000000)
            DisplayTimedTextToPlayer(p, 0, 0, 10, ArcTag + (GetCurrency(pid, ARCADITE)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need 1 Arcadite Lumber to buy this")
        end

    elseif (cmd == "-bppc") then
        if PlatConverterBought[pid] then
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You already purchased this.")
        elseif GetCurrency(pid, PLATINUM) < 2 then
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need 2 Platinum Coins to buy this")
        else
            AddCurrency(pid, PLATINUM, -2)
            DisplayTimedTextToPlayer(p, 0, 0, 20, "Bought Portable Platinum Coin Converter.")
            PlatConverter[pid]= true
            PlatConverterBought[pid]= true
        end

    elseif (cmd == "-bpac") then
        if ArcaConverterBought[pid] then
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You already purchased this.")
        elseif GetCurrency(pid, ARCADITE)<2 then
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need 2 Arcadite Lumber to buy this")
        else
            AddCurrency(pid, ARCADITE, -2)
            DisplayTimedTextToPlayer(p, 0, 0, 20, "Bought Arcadite Lumber Converter.")
            ArcaConverter[pid]= true
            ArcaConverterBought[pid]= true
        end

    elseif SubString(cmd,0,3)=="-pa" or cmd=="-cash" then
        local id = S2I(SubString(cmd, StringLength(cmd) - 1, StringLength(cmd)))
        if id > 0 then
            DisplayTimedTextToPlayer(p, 0, 0, 30, PlatTag + (GetCurrency(id, PLATINUM)))
            DisplayTimedTextToPlayer(p, 0, 0, 30, ArcTag + (GetCurrency(id, ARCADITE)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 30, PlatTag + (GetCurrency(pid, PLATINUM)))
            DisplayTimedTextToPlayer(p, 0, 0, 30, ArcTag + (GetCurrency(pid, ARCADITE)))
        end

    elseif (cmd == "-xp") then
        ShowExpRate(p, pid)

    elseif (cmd == "-ms") then
        DisplayTimedTextToPlayer(p, 0, 0, 10, "Movespeed: " .. (Movespeed[pid]))

    elseif (cmd == "-as") then
        local atkspeed = 1 / BlzGetUnitAttackCooldown(Hero[pid], 0)
        DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00Base Attack Speed: |r" .. R2S(atkspeed) .. " attacks per second")

        atkspeed = atkspeed * (1 + IMinBJ(GetHeroAgi(Hero[pid], true), 400) * 0.01)
        DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00Total Attack Speed: |r" .. R2S(atkspeed) .. " attacks per second.")
    elseif (cmd == "-speed") then
        DisplayTimedTextToPlayer(p, 0, 0, 10, "Movespeed: " .. (Movespeed[pid]))
        local atkspeed = 1. / BlzGetUnitAttackCooldown(Hero[pid], 0)
        DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00Base Attack Speed: |r" .. R2S(atkspeed) .. " attacks per second")

        atkspeed = atkspeed * (1 + IMinBJ(GetHeroAgi(Hero[pid], true), 400) * 0.01)
        DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00Total Attack Speed: |r" .. R2S(atkspeed) .. " attacks per second.")
    elseif (cmd == "-actions") then
        UnitRemoveAbility(Hero[pid], FourCC('A03C'))
        UnitAddAbility(Hero[pid], FourCC('A03C'))

    elseif (cmd == "-flee") then
        FleeCommand(p)

    elseif (SubString(cmd,0,4) == "-cam") then
        local zoom = 0

        if SubString(cmd, StringLength(cmd) - 1, StringLength(cmd)) == "l" or SubString(cmd, StringLength(cmd) - 1, StringLength(cmd)) == "L" then
            CameraLock[pid] = true
            zoom = S2I(SubString(cmd,5, StringLength(cmd) - 1))
        else
            zoom = S2I(SubString(cmd,5, StringLength(cmd)))
        end

        MathClamp(zoom, 100, 3000)

        SetCameraFieldForPlayer(p, CAMERA_FIELD_TARGET_DISTANCE, zoom, 0)
        Zoom[pid] = zoom

    elseif (SubString(cmd,0,3) == "-aa") or SubString(cmd, 0, 11) == "-autoattack" then
        ToggleAutoAttack(pid)
    elseif (SubString(cmd,0,3) == "-zm") then
        SetCameraFieldForPlayer(p, CAMERA_FIELD_TARGET_DISTANCE, 2500, 0)
        Zoom[pid] = 2500
        if SubString(cmd, StringLength(cmd) - 1, StringLength(cmd)) == "l" or SubString(cmd, StringLength(cmd) - 1, StringLength(cmd)) == "L" then
            CameraLock[pid] = true
        end

    elseif (cmd == "-lock") then
        CameraLock[pid] = true

    elseif (cmd == "-unlock") then
        CameraLock[pid] = false

    elseif (SubString(cmd,0,6) == "-price") then
        DisplayTimedTextToPlayer(p, 0, 0,30, "Upgrade item prices have been moved to \"Item Info\" (hotkey Z + E on your hero).")

    elseif (SubString(cmd,0,5) == "-info") then
        DisplayTimedTextToPlayer(p, 0, 0, 30, infoString[S2I(SubString(cmd,6,8))])

    elseif (cmd == "-unstuck") then
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

    elseif (cmd=="-st") or (cmd=="-savetime") then
        if autosave[pid] then
            DisplayTimedTextToPlayer(p, 0, 0, 20, "Your next autosave is in " .. RemainingTimeString(SaveTimer[pid]) .. ".")
        elseif Hardcore[pid] then
            DisplayTimedTextToPlayer(p, 0, 0, 20, RemainingTimeString(SaveTimer[pid]) .. " until you can save again.")
        end

    elseif (cmd=="-rt") or (cmd == "-restime") then
        if TimerGetRemaining(rezretimer[pid]) <= 0.1 then
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You can recharge.")
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, (R2I(TimerGetRemaining(rezretimer[pid]))) .. " seconds until you can recharge again.")
        end

    elseif (SubString(cmd, 0, 5) == "-save") then
        if UnitAlive(Hero[pid]) == false then
            DisplayTextToPlayer(p, 0, 0, "You cannot do this while dead!")
        elseif TimerGetRemaining(SaveTimer[pid]) > 1 and Hardcore[pid] then
            DisplayTimedTextToPlayer(p, 0, 0, 20, RemainingTimeString(SaveTimer[pid]) .. " until you can save again.")
        elseif RectContainsCoords(gg_rct_Church, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) == false and Hardcore[pid] then
            DisplayTimedTextToPlayer(p, 0, 0, 30, "|cffFF0000You're playing in hardcore mode, you may only save inside the church in town.|r")
        else
            ActionSave(p)
        end

    elseif (SubString(cmd, 0, 9) == "-autosave") then
        if not autosave[pid] then
            autosave[pid] = true
            DisplayTextToPlayer(p, 0, 0, "|cffffcc00Autosave is now enabled -- you will save every 30 minutes or when your next save is available as Hardcore.|r")
            TimerStart(SaveTimer[pid], 1800, false, nil)
        else
            autosave[pid] = false
            DisplayTextToPlayer(p, 0, 0, "|cffffcc00Autosave disabled.|r")
        end

    elseif (cmd == "-forcesave") or (cmd == "-saveforce") then
        if UnitAlive(Hero[pid]) == false then
            DisplayTextToPlayer(p, 0, 0, "You cannot do this while dead!")
        elseif InCombat(Hero[pid]) then
            DisplayTextToPlayer(p, 0, 0, "You cannot do this while in combat!")
        elseif isteleporting[pid] then
            DisplayTextToPlayer(p, 0, 0, "You cannot do this while teleporting!")
        elseif RectContainsCoords(gg_rct_Church, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) or RectContainsCoords(gg_rct_Tavern, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) then
            ActionSaveForce(p, false)
        else
            ActionSaveForce(p, true)
        end

    elseif (cmd == "-cancel") and forceSaving[pid] then
        forceSaving[pid] = false
        isteleporting[pid] = false
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
    elseif (SubString(cmd, 0, 9) == "-HardMode") or (SubString(cmd, 0, 9) == "-hardmode") then
        if HARD_MODE > 0 then
            DisplayTimedTextToPlayer(GetTriggerPlayer(), 0, 0, 5, "|cffffcc00Hard mode is already active.|r")
        else
            if VOTING_TYPE == 0 then
                Hardmode()
            end
        end

    elseif (SubString(cmd, 0, 9) == "-votekick") then
        if VOTING_TYPE == 0 and User.AmountPlaying > 2 then
            local dw = DialogWindow.create(pid, "", VotekickPanelClick) ---@type DialogWindow

            while U do

                if pid ~= U.id then
                    dw.data[dw.ButtonCount] = U.id
                    dw:addButton(U.nameColored)
                end

                U = U.next
            end
        end

    elseif (cmd == "-repick") then
        if Profile[pid] then
            if Profile[pid]:getSlotsUsed() >= 30 then
                DisplayTimedTextToPlayer(p, 0, 0, 30.0, "You cannot save more than 30 heroes!")
            else
                MainRepick(pid)
            end
        end

    elseif (SubString(cmd, 0, 9) == "-prestige") then
        if GetLocalPlayer() == p then
            MultiboardMinimize(MULTI_BOARD, true)
        end
        PrestigeInfo(p, S2I(SubString(cmd, 10, 12)))

    elseif (cmd == "-pcoff") or (cmd == "-platinum converter off") then
        if PlatConverterBought[pid] then
            PlatConverter[pid]= false
            DisplayTimedTextToPlayer(p, 0, 0, 10, "Platinum converter off.")
        else
            DisplayTimedTextToPlayer(p, 0, 0, 10, "You have not bought a Platinum Converter.")
        end

    elseif cmd == "-newprofile" or cmd == "-new profile" then
        NewProfile(pid)

    elseif (cmd == "-pcon") or (cmd == "-platinum converter on") then
        if PlatConverterBought[pid] then
            PlatConverter[pid]= true
            DisplayTimedTextToPlayer(p, 0, 0, 10, "Platinum converter on.")
        else
            DisplayTimedTextToPlayer(p, 0, 0, 10, "You have not bought a Platinum Converter.")
        end

    elseif (cmd == "-acoff") or (cmd == "-arcadite converter off") then
        if ArcaConverterBought[pid] then
            ArcaConverter[pid]= false
            DisplayTimedTextToPlayer(p, 0, 0, 10, "arcadite converter off.")
        else
            DisplayTimedTextToPlayer(p, 0, 0, 10, "You have not bought an Arcadite Converter.")
        end

    elseif (cmd == "-acon") or (cmd == "-arcadite converter on") then
        if ArcaConverterBought[pid] then
            ArcaConverter[pid]= true
            DisplayTimedTextToPlayer(p, 0, 0, 10, "arcadite converter on.")
        else
            DisplayTimedTextToPlayer(p, 0, 0, 10, "You have not bought an Arcadite Converter.")
        end

    elseif (cmd == "-q") or (cmd == "-quests") then
        DisplayQuestProgress(p)

    elseif S2I(SubString(cmd, 1, 5)) > 999 then
        if afkTextVisible[pid] then
            if S2I(SubString(cmd, 1, 5)) == afkInt then
                afkTextVisible[pid] = false
                if GetLocalPlayer() == p then
                    BlzFrameSetVisible(afkTextBG, false)
                end
                SoundHandler("Sound\\Interface\\GoodJob.wav", false, p, nil)
            else
                DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffff0000ERROR: Incorrect|r")
            end
        end

    elseif (cmd == "-nohints") or (cmd == "-hints") then
        if IsPlayerInForce(p, HINT_PLAYERS) then
            ForceRemovePlayer(HINT_PLAYERS, p)
            DisplayTimedTextToPlayer(p, 0, 0, 10, "Hints turned off.")
        else
            ForceAddPlayer(HINT_PLAYERS, p)
            DisplayTimedTextToPlayer(p, 0, 0, 10, "Hints turned on.")
        end
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
