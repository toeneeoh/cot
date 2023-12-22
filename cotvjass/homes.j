library Homes requires Functions, Level

globals
    integer array urhome
    unit array mybase
endglobals

function OnResearch takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local player p = GetOwningPlayer(u)
    local integer uid = GetUnitTypeId(u)
    local integer pid = GetPlayerId(p) + 1
    
    if urhome[pid] != 4 and (uid == 'h01K' or uid == 'h01L' or uid == 'h01H' or uid == 'h01J') then //grand nations
        set urhome[pid] = 4
        
		call DisplayTextToForce(FORCE_PLAYING, (User.fromIndex(pid - 1).nameColored + " has upgraded to a grand nation!"))
        call DisplayTextToPlayer(p, 0, 0, "Your grand nation allows you to gain experience faster than a regular nation.")
	elseif uid == 'h047' then //medean court
		call SetUnitAbilityLevel(u, 'A0A5', 2)
		call SetUnitAbilityLevel(u, 'A0A7', 2)
		call SetUnitAbilityLevel(u, 'A0A9', 2)
    endif
    
    set u = null
    set p = null
endfunction

function BaseDead takes nothing returns nothing
    local timer t = GetExpiredTimer()
	local integer pid = GetTimerData(t)
	local player p = Player(pid - 1)

	if urhome[pid] == 0 then
		call PanCameraToTimedLocForPlayer(p, TownCenter, 0)
		call DisplayTextToForce(FORCE_PLAYING, User.fromIndex(pid - 1).nameColored + " was defeated from losing their base.")
		call DisplayTextToPlayer(p, 0, 0, "You have lost the game. All of your structures and units will be removed from the game, however you may stay and watch or leave as you choose.")
        call PlayerCleanup(p)
	else
		call DisplayTextToPlayer(p, 0, 0, "You have narrowly avoided death this time. Be careful or next time you may not be so lucky...")
	endif	
    
	call TimerDialogDisplay(udg_Timer_Window_TUD[pid], false)
	call DestroyTimerDialog(udg_Timer_Window_TUD[pid])

	call ReleaseTimer(t)
    
    set t = null
	set p = null
endfunction

function BuildBase takes nothing returns nothing
    local unit u = GetConstructedStructure()
    local integer i = GetUnitTypeId(u)
    local integer pid= GetPlayerId(GetOwningPlayer(u)) + 1
    local integer htype= 0
    local real x = GetUnitX(u)
    local real y = GetUnitY(u)
    
    if RectContainsCoords(gg_rct_NoSin, x, y) then
        call KillUnit(u)
        call DisplayTextToPlayer(Player(pid - 1),0,0, "|cffff0000You can not build in town.|r")
        set u = null
        return
    endif
    
	if i == 'h01U' or i == 'h038' or i == 'h030' or i == 'h02T' then //nation
		set htype = 1
	elseif i == 'h008' or i == 'h00E' then //home
		set htype = 2
	elseif i == 'h00K' or i == 'h047' then //grand home
        set htype = 3
    //elseif i == 'h047' then //grand nation
		//set htype = 4
	elseif i == 'h03K' then //spirit lounge
		set htype = 5
	elseif i == 'h04T' then //satan
		set htype = 6
	elseif i == 'h050' then //Dnation
		set htype = 7
	else
        set u = null
		return
	endif

	if RectContainsCoords(gg_rct_Main_Map, x, y) == false then
		call KillUnit(u)
		call DisplayTextToPlayer(Player(pid - 1),0,0, "|cffff0000You can only build your home on the main map.|r")
        set u = null
        return
	endif

	if htype > 0 and urhome[pid] > 0 then
        call KillUnit(u)
        call DisplayTextToPlayer(Player(pid - 1),0,0, "|cfff0000fOnly one base is allowed per player.|r")
        set u = null
		return
	endif
	
    set mybase[pid] = u
    
	if htype == 1 then
		call DisplayTextToForce(FORCE_PLAYING, (User.fromIndex(pid - 1).nameColored + " has built a nation and is not a bum anymore."))
		call DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your nation gives you slight experience gain and allows you to build a mighty army.")
		set urhome[pid] = htype
	elseif htype == 2 then
		call DisplayTextToForce(FORCE_PLAYING, (User.fromIndex(pid - 1).nameColored + " has built a home and is not a bum anymore."))
		call DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your home allows you to gain experience faster than a nation.")
		set urhome[pid] = htype
	elseif htype == 3 then
		call DisplayTextToForce(FORCE_PLAYING, (User.fromIndex(pid - 1).nameColored + " has built a grand home and is not a bum anymore."))
        call DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your grand home allows you to gain experience faster than a nation or home.")
		set urhome[pid] = htype
    elseif htype == 4 then
		call DisplayTextToForce(FORCE_PLAYING, (User.fromIndex(pid - 1).nameColored + " has built a grand nation and is not a bum anymore."))
        call DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your grand nation allows you to gain experience faster than a regular nation.")
        set urhome[pid] = htype
	elseif htype == 5 then
		call DisplayTextToForce(FORCE_PLAYING, (User.fromIndex(pid - 1).nameColored + " has built a chaotic home and is not a bum anymore."))
		call DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your chaotic home allows you to gain experience faster than non-chaos homes.")
		set urhome[pid] = htype
	elseif htype == 6 then
		call DisplayTextToForce(FORCE_PLAYING, (User.fromIndex(pid - 1).nameColored + " has built a chaotic home and is not a bum anymore."))
		call DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your chaotic home allows you to gain 60% more experience than a lounge.")
		set urhome[pid] = htype
	elseif htype == 7 then
		call DisplayTextToForce(FORCE_PLAYING, (User.fromIndex(pid - 1).nameColored + " has built a chaotic nation and is not a bum anymore."))
		call DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your chaotic nation allows you to gain 30% more experience than a lounge and can create powerful chaotic units.")
		set urhome[pid] = htype
	endif

	call TimerDialogDisplay(udg_Timer_Window_TUD[pid], false)
	call QuestSetCompletedBJ(udg_Bum_Stage, true)
	call ExperienceControl(pid)
    set u = null
endfunction

//===========================================================================
function BaseInit takes nothing returns nothing
    local trigger base = CreateTrigger()
    local trigger research = CreateTrigger()
    local User u = User.first
    
    loop
        exitwhen u == User.NULL
        call TriggerRegisterPlayerUnitEvent(base, u.toPlayer(), EVENT_PLAYER_UNIT_CONSTRUCT_FINISH, function boolexp)
        call TriggerRegisterPlayerUnitEvent(research, u.toPlayer(), EVENT_PLAYER_UNIT_UPGRADE_FINISH, function boolexp)
        set u = u.next
    endloop
    
	call TriggerAddAction(base,function BuildBase)
    call TriggerAddAction(research, function OnResearch)
    
    set base = null
    set research = null
endfunction

endlibrary
