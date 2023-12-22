library CodelessSaveLoad uses FileIO, Functions

	globals
        hashtable SAVE_TABLE = InitHashtable()
        integer KEY_ITEMS = 1
        integer KEY_UNITS = 2
        integer KEY_SPELLS = 3
		integer CUSTOM_ITEM_OFFSET = 'I000'
        integer array SAVE_UNIT_TYPE

		constant integer MAX_SAVED_ITEMS = 8191
		constant integer MAX_SAVED_HEROES = 63 //6 bits
	endglobals

    private function uppercolor takes nothing returns string
        return "|cffff0000"
    endfunction

    private function lowercolor takes nothing returns string
        return "|cff00ff00"
    endfunction

    private function numcolor takes nothing returns string
        return "|cff0000ff"
    endfunction

    private function chartype takes string c returns integer
        if S2I(c) == 0 and c != "0" then
            if c == StringCase(c, true) then
                return 0
            else
                return 1
            endif
        else
            return 2
        endif
    endfunction

    private function colorize takes string s returns string
        local string out = ""
        local integer i = 0
        local integer len = StringLength(s)
        local integer ctype
        local string c
        loop
            exitwhen i >= len
            set c = SubString(s,i,i + 1)
            set ctype = chartype(c)
            if ctype == 0 then
                set out = out + uppercolor()+c+"|r"
            elseif ctype == 1 then
                set out = out + lowercolor()+c+"|r"
            else
                set out = out + numcolor()+c+"|r"
            endif
            set i = i + 1
        endloop
        return out
    endfunction

    private function ForceText takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local integer pid = GetTimerData(t)
        local string s = ""
        local integer i = 0
        local integer rand
        
        loop
            exitwhen i > 29
            set rand = GetRandomInt(0, StringLength(abc))
            set s = s + SubString(abc, rand - 1, rand)
            set i = i + 1
        endloop
        
        set forceSaving[pid] = true
        set forceString[pid] = s
        call DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 120, "|cffffcc00Type|r -" + colorize(s))
        call DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 120, "|cffffcc00Or|r -cancel |cffffcc00if you wish to abort.|r")
    
        call ReleaseTimer(t)
        
        set t = null
    endfunction

    function ActionLoadHero takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local integer pid = GetPlayerId(p) + 1

        if LEFT_CHURCH[pid] then
            call DisplayTimedTextToPlayer(p, 0, 0, 20, "You cannot -load anymore!")
            set p = null

            static if LIBRARY_dev then
            else
                return
            endif
        endif

        if Profile[pid] == 0 or Profile[pid].getSlotsUsed() == 0 then
            call DisplayTimedTextToPlayer(p, 0, 0, 20, "You do not have any character data!")
            set p = null
			return
        endif
        
        if HeroID[pid] > 0 then
            call DisplayTimedTextToPlayer(p, 0, 0, 20, "You need to repick before using -load again!")
            set p = null
			return
        endif

        set newcharacter[pid] = false
        call DisplayHeroSelectionDialog(pid)

        set p = null
    endfunction
    
    function SaveForceRemove takes player whichPlayer returns nothing
        local integer pid = GetPlayerId(whichPlayer) + 1
        local integer i = 0
        local item itm
        
        if GetUnitTypeId(Hero[pid]) == 0 or HeroID[pid] == 0 or UnitAlive(Hero[pid]) == false then
            call DisplayTextToPlayer(whichPlayer, 0, 0, "An error occured while attempting to save.")
            return
        endif
        
        static if LIBRARY_dev then
            set GAME_STATE = 2
        endif
        
        if GAME_STATE <= 1 then
            return
        endif
        
        set forceSaving[pid] = false
        
        //save profile and hero
        if newcharacter[pid] then
            set newcharacter[pid] = false
            call SetSaveSlot(pid)
        endif

        call Profile[pid].saveCharacter()

        call PlayerCleanup(whichPlayer)
        
        set itm = null
    endfunction

    function ActionSave takes player p returns boolean
		local integer pid = GetPlayerId(p) + 1

        if LEFT_CHURCH[pid] == false then
            call DisplayTextToPlayer(p, 0, 0, "You must leave the church to save.")
            return false
        endif
        
        if GetUnitTypeId(Hero[pid]) == 0 or HeroID[pid] == 0 or UnitAlive(Hero[pid]) == false then
            call DisplayTextToPlayer(p, 0, 0, "An error occured while attempting to save.")
            return false
        endif

        static if LIBRARY_dev then
            set GAME_STATE = 2
        endif
        
        if GAME_STATE <= 1 then
            return false
        endif

		if autosave[pid] or udg_Hardcore[pid] then
            call TimerStart(SaveTimer[pid], 1800, false, null)
		endif

        if GetLocalPlayer() == p then
            call ClearTextMessages()
        endif

        if newcharacter[pid] then
            set newcharacter[pid] = false
            call SetSaveSlot(pid)
        endif

        call Profile[pid].saveCharacter()

        return true
    endfunction
    
    function ActionSaveForce takes player p, boolean b returns nothing
		local integer pid = GetPlayerId(p) + 1

        if LEFT_CHURCH[pid] == false then
            call DisplayTextToPlayer(p, 0, 0, "You must leave the church to save.")
            return
        endif
        
        if GetUnitTypeId(Hero[pid]) == 0 or HeroID[pid] == 0 or UnitAlive(Hero[pid]) == false then
            call DisplayTextToPlayer(p, 0, 0, "An error occured while attempting to save.")
            return
        endif

        static if LIBRARY_dev then
            set GAME_STATE = 2
        endif
    
        if GAME_STATE <= 1 then
            return
        endif
        
        if b then
            set isteleporting[pid] = true
            call PauseUnit(Hero[pid], true)
            call PauseUnit(Backpack[pid], true)
            call UnitRemoveAbility(Hero[pid], 'Binv')
            call DisplayTextToPlayer(p, 0, 0, "Please wait 5 seconds.")
            call TimerStart(NewTimerEx(pid), 5, false, function ForceText)
        else
            call SaveForceRemove(p)
        endif
    endfunction

    function CodelessSaveLoadInit takes nothing returns nothing
        local trigger loadHeroTrigger = CreateTrigger()
        local User u = User.first
        local integer i = 0
        local string s = ""
        local boolean load = true

		set SAVE_UNIT_TYPE[0] = 0
		set SAVE_UNIT_TYPE[1] = HERO_ARCANIST
		set SAVE_UNIT_TYPE[2] = HERO_ASSASSIN
		set SAVE_UNIT_TYPE[3] = HERO_MARKSMAN
		set SAVE_UNIT_TYPE[4] = HERO_HYDROMANCER
		set SAVE_UNIT_TYPE[5] = HERO_PHOENIX_RANGER
		set SAVE_UNIT_TYPE[6] = HERO_ELEMENTALIST
		set SAVE_UNIT_TYPE[7] = HERO_HIGH_PRIEST
		set SAVE_UNIT_TYPE[8] = HERO_MASTER_ROGUE
		set SAVE_UNIT_TYPE[9] = HERO_SAVIOR
		set SAVE_UNIT_TYPE[10] = HERO_BARD
		set SAVE_UNIT_TYPE[11] = HERO_ARCANE_WARRIOR
		set SAVE_UNIT_TYPE[12] = HERO_BLOODZERKER
		set SAVE_UNIT_TYPE[13] = HERO_DARK_SAVIOR
		set SAVE_UNIT_TYPE[14] = HERO_DARK_SUMMONER
		set SAVE_UNIT_TYPE[15] = HERO_OBLIVION_GUARD
		set SAVE_UNIT_TYPE[16] = HERO_ROYAL_GUARDIAN
		set SAVE_UNIT_TYPE[17] = HERO_THUNDERBLADE
		set SAVE_UNIT_TYPE[18] = HERO_WARRIOR
		set SAVE_UNIT_TYPE[19] = 'H00H'
		set SAVE_UNIT_TYPE[20] = HERO_DRUID
		set SAVE_UNIT_TYPE[21] = HERO_VAMPIRE

        call TriggerAddCondition(Profile.sync_event, function Profile.LoadSync)
        call TriggerAddCondition(loadHeroTrigger, Filter(function ActionLoadHero))

        loop
            exitwhen i > 21

            call SaveInteger(SAVE_TABLE, KEY_UNITS, SAVE_UNIT_TYPE[i], i)

            set i = i + 1
        endloop
            
        //dev game state bypass
        static if LIBRARY_dev then
            set GAME_STATE = 2
        endif

        //singleplayer
        if GAME_STATE == 0 then
            call DisplayTimedTextToForce(FORCE_PLAYING, 600., "|cffff0000Save / Load is disabled in single player.|r")
        else
            //load all players
            loop
                exitwhen u == User.NULL

                set i = 0
                set load = true

                loop
                    exitwhen i > funnyListTotal
                    if StringHash(u.name) == funnyList[i] then
                        call DisplayTimedTextToForce(FORCE_PLAYING, 120., BlzGetItemDescription(PathItem) + u.nameColored + BlzGetItemExtendedTooltip(PathItem))
                        set load = false
                        exitwhen true
                    endif
                    set i = i + 1
                endloop

                if load then
                    set s = ""

                    call TriggerRegisterPlayerChatEvent(loadHeroTrigger, u.toPlayer(), "-load", true)
                    call BlzTriggerRegisterPlayerSyncEvent(Profile.sync_event, u.toPlayer(), SYNC_PREFIX, false)

                    if GetLocalPlayer() == u.toPlayer() then
                        set s = FileIO_Read(MAP_NAME + "\\" + u.name + "\\profile.pld")

                        if StringLength(s) > 1 then
                            call BlzSendSyncData(SYNC_PREFIX, getLine(1, s))
                        endif
                    endif 
                endif

                set u = u.next
            endloop
        endif

        set loadHeroTrigger = null
    endfunction

endlibrary
