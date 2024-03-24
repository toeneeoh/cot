--[[
    saveload.lua

    This module handles -save/load commands and determines how they behave
    depending on game status (singleplayer/multiplayer)

    Automatically loads players' profiles at map start.
]]

if Debug then Debug.beginFile 'SaveLoad' end

OnInit.final("SaveLoad", function(require)
    require 'Variables'
    require 'GameStatus'
    require 'FileIO'
    require 'PlayerData'

    SAVE_UNIT_TYPE[1] = HERO_ARCANIST
    SAVE_UNIT_TYPE[2] = HERO_ASSASSIN
    SAVE_UNIT_TYPE[3] = HERO_MARKSMAN
    SAVE_UNIT_TYPE[4] = HERO_HYDROMANCER
    SAVE_UNIT_TYPE[5] = HERO_PHOENIX_RANGER
    SAVE_UNIT_TYPE[6] = HERO_ELEMENTALIST
    SAVE_UNIT_TYPE[7] = HERO_HIGH_PRIEST
    SAVE_UNIT_TYPE[8] = HERO_MASTER_ROGUE
    SAVE_UNIT_TYPE[9] = HERO_SAVIOR
    SAVE_UNIT_TYPE[10] = HERO_BARD
    SAVE_UNIT_TYPE[11] = HERO_CRUSADER
    SAVE_UNIT_TYPE[12] = HERO_BLOODZERKER
    SAVE_UNIT_TYPE[13] = HERO_DARK_SAVIOR
    SAVE_UNIT_TYPE[14] = HERO_DARK_SUMMONER
    SAVE_UNIT_TYPE[15] = HERO_OBLIVION_GUARD
    SAVE_UNIT_TYPE[16] = HERO_ROYAL_GUARDIAN
    SAVE_UNIT_TYPE[17] = HERO_THUNDERBLADE
    SAVE_UNIT_TYPE[18] = HERO_WARRIOR
    SAVE_UNIT_TYPE[19] = FourCC('H00H')
    SAVE_UNIT_TYPE[20] = HERO_DRUID
    SAVE_UNIT_TYPE[21] = HERO_VAMPIRE

    for i, v in ipairs(SAVE_UNIT_TYPE) do
        SAVE_TABLE.KEY_UNITS[v] = i
    end

    ---@return boolean
    function onLoadCommand()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

        if CANNOT_LOAD[pid] then
            DisplayTimedTextToPlayer(GetTriggerPlayer(), 0, 0, 20, "You cannot -load anymore!")

            if DEV_ENABLED then
            else
                return false
            end
        end

        if not Profile[pid] or Profile[pid]:getSlotsUsed() == 0 then
            DisplayTimedTextToPlayer(GetTriggerPlayer(), 0, 0, 20, "You do not have any character data!")
            return false
        end

        if HeroID[pid] > 0 then
            DisplayTimedTextToPlayer(GetTriggerPlayer(), 0, 0, 20, "You need to repick before using -load again!")
            return false
        end

        newcharacter[pid] = false
        DisplayHeroSelectionDialog(pid)

        return false
    end

    ---@param whichPlayer player
    function ForceSave(whichPlayer)
        local pid         = GetPlayerId(whichPlayer) + 1 ---@type integer 

        if GetUnitTypeId(Hero[pid]) == 0 or HeroID[pid] == 0 or UnitAlive(Hero[pid]) == false then
            DisplayTextToPlayer(whichPlayer, 0, 0, "An error occured while attempting to save.")
            return
        end

        if DEV_ENABLED then
            GAME_STATE = 2
        end

        forceSaving[pid] = false

        --save profile and hero
        if newcharacter[pid] then
            newcharacter[pid] = false
            SetSaveSlot(pid)
        end

        Profile[pid]:saveCharacter()

        PlayerCleanup(pid)
    end

    ---@type fun(pt: PlayerTimer)
    local function ForceSaveTimed(pt)
        pt.time = pt.time + 1

        if pt.time < pt.dur and not forceSaving[pt.pid] then
            if (GetLocalPlayer() == Player(pt.pid - 1)) then
                ClearTextMessages()
            end
            DisplayTimedTextToPlayer(Player(pt.pid - 1), 0, 0, 60., "Force save aborted!")

            forceSaving[pt.pid] = false
            pt:destroy()
        elseif pt.time >= pt.dur and forceSaving[pt.pid] then
            ForceSave(Player(pt.pid - 1))

            forceSaving[pt.pid] = false
            pt:destroy()
        end
    end

    ---@param p player
    ---@return boolean
    function ActionSave(p)
        local pid         = GetPlayerId(p) + 1 ---@type integer 

        if CANNOT_LOAD[pid] == false then
            DisplayTextToPlayer(p, 0, 0, "You must leave the church to save.")
            return false
        end

        if GetUnitTypeId(Hero[pid]) == 0 or HeroID[pid] == 0 or UnitAlive(Hero[pid]) == false then
            DisplayTextToPlayer(p, 0, 0, "An error occured while attempting to save.")
            return false
        end

        if DEV_ENABLED then
            GAME_STATE = 2
        end

        if autosave[pid] or Hardcore[pid] then
            TimerStart(SaveTimer[pid], 1800, false, nil)
        end

        if GetLocalPlayer() == p then
            ClearTextMessages()
        end

        if newcharacter[pid] then
            newcharacter[pid] = false
            SetSaveSlot(pid)
        end

        Profile[pid]:saveCharacter()

        return true
    end

    ---@param p player
    ---@param timed boolean
    function ActionSaveForce(p, timed)
        local pid         = GetPlayerId(p) + 1 ---@type integer 
        local pt ---@type PlayerTimer 

        if CANNOT_LOAD[pid] == false then
            DisplayTextToPlayer(p, 0, 0, "You must leave the church to save.")
            return
        end

        if GetUnitTypeId(Hero[pid]) == 0 or HeroID[pid] == 0 or UnitAlive(Hero[pid]) == false then
            DisplayTextToPlayer(p, 0, 0, "An error occured while attempting to save.")
            return
        end

        if DEV_ENABLED then
            GAME_STATE = 2
        end

        if timed then
            forceSaving[pid] = true
            IS_TELEPORTING[pid] = true
            PauseUnit(Hero[pid], true)
            PauseUnit(Backpack[pid], true)
            UnitRemoveAbility(Hero[pid], FourCC('Binv'))
            DisplayTimedTextToPlayer(p, 0, 0, 120, "Please stay out of combat for 10 seconds.")
            DisplayTimedTextToPlayer(p, 0, 0, 120, "Type |cffffcc00Or|r -cancel |cffffcc00if you wish to abort.|r")
            pt = TimerList[pid]:add()
            pt.tag = FourCC('fsav')
            pt.dur = 20.
            pt.timer:callDelayed(0.5, ForceSaveTimed, pt)
        else
            ForceSave(p)
        end
    end

    ---@return boolean
    function onSaveCommand()
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
            elseif IS_TELEPORTING[pid] then
                DisplayTextToPlayer(p, 0, 0, "You cannot do this while teleporting!")
            elseif RectContainsCoords(gg_rct_Church, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) or RectContainsCoords(gg_rct_Tavern, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) then
                ActionSaveForce(p, false)
            else
                ActionSaveForce(p, true)
            end
        elseif (cmd == "-save") then
            if TimerGetRemaining(SaveTimer[pid]) > 1 and Hardcore[pid] then
                DisplayTimedTextToPlayer(p, 0, 0, 20, RemainingTimeString(SaveTimer[pid]) .. " until you can save again.")
            elseif RectContainsCoords(gg_rct_Church, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) == false and Hardcore[pid] then
                DisplayTimedTextToPlayer(p, 0, 0, 30, "|cffFF0000You're playing in hardcore mode, you may only save inside the church in town.|r")
            else
                ActionSave(p)
            end
        end

        return false
    end

    do
        local loadHeroTrigger = CreateTrigger()
        local saveHeroTrigger = CreateTrigger()
        local load = true ---@type boolean

        TriggerAddCondition(Profile.sync_event, Filter(Profile.LoadSync))
        TriggerAddCondition(loadHeroTrigger, Filter(onLoadCommand))
        TriggerAddCondition(saveHeroTrigger, Filter(onSaveCommand))

        --dev game state bypass
        if DEV_ENABLED then
            GAME_STATE = 2
        end

        --singleplayer
        if GAME_STATE == 0 then
            DisplayTimedTextToForce(FORCE_PLAYING, 600., "|cffff0000Save / Load is disabled in single player.|r")
        else
            local u = User.first

            --load all players
            while u do

                load = true

                for _, v in ipairs(funnyList) do
                    if StringHash(u.name) == v then
                        DisplayTimedTextToForce(FORCE_PLAYING, 120., BlzGetItemDescription(PathItem) .. u.nameColored .. BlzGetItemExtendedTooltip(PathItem))
                        load = false
                        break
                    end
                end

                if load then
                    TriggerRegisterPlayerChatEvent(loadHeroTrigger, u.player, "-load", true)
                    TriggerRegisterPlayerChatEvent(saveHeroTrigger, u.player, "-save", true)
                    TriggerRegisterPlayerChatEvent(saveHeroTrigger, u.player, "-forcesave", true)
                    BlzTriggerRegisterPlayerSyncEvent(Profile.sync_event, u.player, SYNC_PREFIX, false)

                    if GetLocalPlayer() == u.player then
                        local s = FileIO.Load(MAP_NAME .. "\\" .. u.name .. "\\profile.pld")

                        if s then
                            BlzSendSyncData(SYNC_PREFIX, GetLine(1, s))
                        end
                    end
                end

                u = u.next
            end
        end
    end
end)

if Debug then Debug.endFile() end
