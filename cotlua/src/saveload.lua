--[[
    saveload.lua

    This module handles -save/load commands and determines how they behave
    depending on game status (singleplayer/multiplayer)

    Automatically loads players' profiles and characters at map start.
]]

OnInit.final("SaveLoad", function(Require)
    Require('Variables')
    Require('GameStatus')
    Require('FileIO')
    Require('Profile')

    --[[ profile load order
            slot code hash checksums
            total time played
    ]]

    SYNC_PROFILE = "P"
    SYNC_CHARACTER = "C"

    SAVE_TABLE = {
        KEY_ITEMS = {},
        KEY_UNITS = {}
    }

    SAVE_UNIT_TYPE = {
        HERO_ARCANIST,
        HERO_ASSASSIN,
        HERO_MARKSMAN,
        HERO_HYDROMANCER,
        HERO_PHOENIX_RANGER,
        HERO_ELEMENTALIST,
        HERO_HIGH_PRIEST,
        HERO_MASTER_ROGUE,
        HERO_SAVIOR,
        HERO_BARD,
        HERO_CRUSADER,
        HERO_BLOODZERKER,
        HERO_DARK_SAVIOR,
        HERO_DARK_SUMMONER,
        HERO_OBLIVION_GUARD,
        HERO_ROYAL_GUARDIAN,
        HERO_THUNDERBLADE,
        HERO_WARRIOR,
        FourCC('H00H'),
        HERO_DRUID,
        HERO_VAMPIRE,
    }

    for i = 1, #SAVE_UNIT_TYPE do
        SAVE_TABLE.KEY_UNITS[SAVE_UNIT_TYPE[i]] = i
    end

    local list = {
        [-894554765] = 1,
        [-1291321931] = 1,
    }

    ---@return boolean
    local function on_load()
        local p = GetTriggerPlayer()
        local pid = GetPlayerId(p) + 1 ---@type integer 
        local profile = Profile[pid]

        if not profile or profile:getSlotsUsed() == 0 then
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You do not have any character data!")
            return false
        end

        if profile.cannot_load and not DEV_ENABLED then
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You cannot -load anymore!")
        end

        if profile.playing then
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need to repick before using -load again!")
            return false
        end

        profile:open_dialog()

        return false
    end

    ---@param p player
    local function force_save(p)
        local pid = GetPlayerId(p) + 1 ---@type integer 

        if not Profile[pid].playing or GetUnitTypeId(Hero[pid]) == 0 or UnitAlive(Hero[pid]) == false then
            DisplayTextToPlayer(p, 0, 0, "An error occured while attempting to save.")
            return
        end

        IS_FORCE_SAVING[pid] = false

        Profile[pid]:save_character()

        PlayerCleanup(pid)
    end

    ---@type fun(pt: PlayerTimer)
    local function force_save_periodic(pt)
        pt.time = pt.time + 1

        if pt.time < pt.dur and not IS_FORCE_SAVING[pt.pid] then
            if (GetLocalPlayer() == Player(pt.pid - 1)) then
                ClearTextMessages()
            end
            DisplayTimedTextToPlayer(Player(pt.pid - 1), 0, 0, 60., "Force save aborted!")

            IS_FORCE_SAVING[pt.pid] = false
            pt:destroy()
        elseif pt.time >= pt.dur and IS_FORCE_SAVING[pt.pid] then
            force_save(Player(pt.pid - 1))

            IS_FORCE_SAVING[pt.pid] = false
            pt:destroy()
        end
    end

    ---@param p player
    ---@param timed boolean
    local function start_force_save(p, timed)
        local pid = GetPlayerId(p) + 1 ---@type integer 
        local pt ---@type PlayerTimer 
        local profile = Profile[pid]

        if not profile.cannot_load then
            DisplayTextToPlayer(p, 0, 0, "You must leave the church to save.")
            return
        end

        if not profile.playing or GetUnitTypeId(Hero[pid]) == 0 or UnitAlive(Hero[pid]) == false then
            DisplayTextToPlayer(p, 0, 0, "An error occured while attempting to save.")
            return
        end

        if timed then
            IS_FORCE_SAVING[pid] = true
            Unit[Hero[pid]].busy = true
            PauseUnit(Hero[pid], true)
            PauseUnit(Backpack[pid], true)
            UnitRemoveAbility(Hero[pid], FourCC('Binv'))
            DisplayTimedTextToPlayer(p, 0, 0, 120, "Please stay out of combat for 10 seconds.")
            DisplayTimedTextToPlayer(p, 0, 0, 120, "Type |cffffcc00Or|r -cancel |cffffcc00if you wish to abort.|r")
            pt = TimerList[pid]:add()
            pt.tag = FourCC('fsav')
            pt.dur = 20.
            pt.timer:callDelayed(0.5, force_save_periodic, pt)
        else
            force_save(p)
        end
    end

    ---@return boolean
    local function on_save()
        local cmd = GetEventPlayerChatStringMatched()
        local p = GetTriggerPlayer()
        local pid = GetPlayerId(p) + 1

        if UnitAlive(Hero[pid]) == false then
            DisplayTextToPlayer(p, 0, 0, "You cannot do this while dead!")
            return false
        end

        if (cmd == "-forcesave") then
            if InCombat(Hero[pid]) then
                DisplayTextToPlayer(p, 0, 0, "You cannot do this while in combat!")
            elseif Unit[Hero[pid]].busy then
                DisplayTextToPlayer(p, 0, 0, "You cannot do this right now!")
            elseif RectContainsCoords(gg_rct_Church, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) or RectContainsCoords(gg_rct_Tavern, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) then
                start_force_save(p, false)
            else
                start_force_save(p, true)
            end
        elseif (cmd == "-save") then
            if TimerGetRemaining(Profile[pid].save_timer.timer) > 1 and Hardcore[pid] then
                DisplayTimedTextToPlayer(p, 0, 0, 20, RemainingTimeString(Profile[pid].save_timer.timer) .. " until you can save again.")
            elseif RectContainsCoords(gg_rct_Church, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) == false and Hardcore[pid] then
                DisplayTimedTextToPlayer(p, 0, 0, 30, "|cffFF0000You're playing in hardcore mode, you may only save inside the church in town.|r")
            else
                Save(p)
            end
        end

        return false
    end

    ---@param p player
    ---@return boolean
    function Save(p)
        local pid = GetPlayerId(p) + 1 ---@type integer 
        local profile = Profile[pid]

        if not profile.cannot_load then
            DisplayTextToPlayer(p, 0, 0, "You must leave the church to save.")
            return false
        end

        if not profile.playing or GetUnitTypeId(Hero[pid]) == 0 or UnitAlive(Hero[pid]) == false then
            DisplayTextToPlayer(p, 0, 0, "An error occured while attempting to save.")
            return false
        end

        if GetLocalPlayer() == p then
            ClearTextMessages()
        end

        profile:save_character()

        return true
    end

    local threads = {} -- use coroutines to "concurrently" load player profile and character codes
    local slot_index = __jarray(0) -- keep track of character slots

    ---@return boolean
    local function sync_profile()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1
        local code = BlzGetTriggerSyncData()
        local valid = code:len() > 1

        if valid then
            valid = Profile.load(code, pid)
        end

        coroutine.resume(threads[pid], valid)

        return false
    end

    ---@return boolean
    local function sync_character()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1
        local code = BlzGetTriggerSyncData()

        if code:len() > 1 then
            slot_index[pid] = slot_index[pid] + 1
            Profile[pid]:preload_character(code, slot_index[pid])
        end

        return false
    end

    local loadHeroTrigger = CreateTrigger()
    local saveHeroTrigger = CreateTrigger()
    local syncProfile = CreateTrigger()
    local syncCharacter = CreateTrigger()

    TriggerAddCondition(syncProfile, Filter(sync_profile))
    TriggerAddCondition(syncCharacter, Filter(sync_character))
    TriggerAddCondition(loadHeroTrigger, Filter(on_load))
    TriggerAddCondition(saveHeroTrigger, Filter(on_save))

    -- singleplayer
    if GAME_STATE == 0 then
        DisplayTimedTextToForce(FORCE_PLAYING, 600., "|cffff0000Save / Load is disabled in single player.|r")
    else
        local u = User.first

        -- load all players
        while u do
            local load = true

            if list[StringHash(u.name)] then
                DisplayTimedTextToForce(FORCE_PLAYING, 120., BlzGetItemDescription(PATH_ITEM) .. u.nameColored .. BlzGetItemExtendedTooltip(PATH_ITEM))
                load = false
                break
            end

            if load then
                BlzTriggerRegisterPlayerSyncEvent(syncProfile, u.player, SYNC_PROFILE, false)
                BlzTriggerRegisterPlayerSyncEvent(syncCharacter, u.player, SYNC_CHARACTER, false)

                threads[u.id] = coroutine.create(function(user) ---@param user User
                    local path = GetProfilePath(user.id)

                    if GetLocalPlayer() == user.player then
                        BlzSendSyncData(SYNC_PROFILE, GetLine(0, FileIO.Load(path)))
                    end

                    -- wait for profile to create
                    local success = coroutine.yield()

                    if success then
                        -- load all characters
                        for i = 1, MAX_SLOTS do
                            path = GetCharacterPath(user.id, i)
                            if GetLocalPlayer() == user.player then
                                BlzSendSyncData(SYNC_CHARACTER, GetLine(1, FileIO.Load(path)))
                            end
                        end
                    end

                    TriggerRegisterPlayerChatEvent(loadHeroTrigger, user.player, "-load", true)
                    TriggerRegisterPlayerChatEvent(saveHeroTrigger, user.player, "-save", true)
                    TriggerRegisterPlayerChatEvent(saveHeroTrigger, user.player, "-forcesave", true)
                    threads[user.id] = nil
                end)

                coroutine.resume(threads[u.id], u)
            end

            u = u.next
        end
    end
end, Debug and Debug.getLine())
