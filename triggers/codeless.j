library CodelessSaveLoad uses FileIO, SaveHelperLib, Functions

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
            set c = SubString(s,i,i+1)
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

    private function ActionLoad takes nothing returns boolean
        local player p = GetTriggerPlayer()
        local integer pid = GetPlayerId(p) + 1
        local string s = ""
        local integer i = 0

        if Profiles[pid].profileHash > 0 then
			call DisplayTimedTextToPlayer(p, 0, 0, 20, "You cannot load anymore.")
			return false
        endif

        static if LIBRARY_dev then
            set GAME_STATE = 2
        endif
        
        if GAME_STATE == 0 then
            call DisplayTimedTextToPlayer(p, 0, 0, 20, "You cannot load a multiplayer character in singleplayer.")

            return false
        endif

        if LOAD_SAFE then
            set LOAD_SAFE = false
        else
            call DisplayTimedTextToPlayer(p, 0, 0, 20, "Please wait until a player is done loading!")
            set p = null
            return false
        endif

        if GetLocalPlayer() == p then
            set s = FileIO_Read(udg_MapName + "\\" + User[p].name + "\\profile.pld")

            if StringLength(s) > 1 then
                call BlzSendSyncData(PROFILE_PREFIX, getLine(1, s))
            else
                call DisplayTimedTextToPlayer(p, 0, 0, 30., "No profile data found!")
            endif
        endif 

        set LOAD_SAFE = true

        set p = null
        return true
    endfunction
    
    function ActionLoadHero takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local integer pid = GetPlayerId(p) + 1

        if LEFT_CHURCH[pid] then
            call DisplayTimedTextToPlayer(p, 0, 0, 20, "You cannot -loadh anymore!")
            set p = null
			return
        endif

        if Profiles[pid].profileHash == 0 then
            call DisplayTimedTextToPlayer(p, 0, 0, 20, "You must load your profile first.")
            set p = null
			return
        endif
        
        if HeroID[pid] > 0 then
            call DisplayTimedTextToPlayer(p, 0, 0, 20, "You already loaded!")
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
        
        if GetUnitTypeId(Hero[pid]) == 0 or HeroID[pid] == 0 or GetWidgetLife(Hero[pid]) < 0.406 then
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

        call Profiles[pid].saveCharacter()

        loop //not sure what this is for
			exitwhen i > 5
            set itm = UnitItemInSlot(Hero[pid], i)
			call UnitRemoveItem(Hero[pid], itm)
			call RemoveItem(itm)
			set i = i + 1
		endloop

        call SharedRepick(whichPlayer)
        
        set itm = null
    endfunction

    function ActionSave takes player p returns boolean
		local integer pid = GetPlayerId(p) + 1

        if LEFT_CHURCH[pid] == false then
            call DisplayTextToPlayer(p, 0, 0, "You must leave the church to save.")
            return false
        endif
        
        if GetUnitTypeId(Hero[pid]) == 0 or HeroID[pid] == 0 or GetWidgetLife(Hero[pid]) < 0.406 then
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

        call Profiles[pid].saveCharacter()

        return true
    endfunction
    
    function ActionSaveForce takes player p, boolean b returns nothing
		local integer pid = GetPlayerId(p) + 1

        if LEFT_CHURCH[pid] == false then
            call DisplayTextToPlayer(p, 0, 0, "You must leave the church to save.")
            return
        endif
        
        if GetUnitTypeId(Hero[pid]) == 0 or HeroID[pid] == 0 or GetWidgetLife(Hero[pid]) < 0.406 then
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
        local trigger loadTrigger = CreateTrigger()
        local trigger loadHeroTrigger = CreateTrigger()
        local User u = User.first
            
        loop
			exitwhen u == User.NULL
			call TriggerRegisterPlayerChatEvent(loadTrigger, u.toPlayer(), "-load", true)
            call TriggerRegisterPlayerChatEvent(loadHeroTrigger, u.toPlayer(), "-loadh", true)
			set u = u.next
        endloop
        
        call TriggerAddCondition(loadTrigger, Filter(function ActionLoad))
        call TriggerAddAction(loadHeroTrigger, function ActionLoadHero)
        
        set loadTrigger = null
        set loadHeroTrigger = null
    endfunction

endlibrary
