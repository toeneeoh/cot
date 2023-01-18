library PVP initializer PVPInit requires Functions

globals
    group array Arena
    integer array ArenaQueue
    integer ArenaMax = 3
endglobals

function ArenaUnpause takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    call PauseUnit(Hero[pid], false)
    call UnitRemoveAbility(Hero[pid], 'Avul')
endfunction

function DuelCountdown takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer pid = LoadInteger(MiscHash, 0, GetHandleId(t))
    local integer tpid = LoadInteger(MiscHash, 1, GetHandleId(t))
    local integer time = GetTimerData(t)
    
    call SetTimerData(t, time - 1)
    
    if time == 0 then
        //start!
        call PauseUnit(Hero[pid], false)
        call PauseUnit(Hero[tpid], false)
        call SoundHandler("Sound\\Interface\\GameFound.wav", Player(pid - 1))
        call SoundHandler("Sound\\Interface\\GameFound.wav", Player(tpid - 1))
        call DisplayTextToPlayer(Player(pid - 1), 0, 0, "FIGHT!")
        call DisplayTextToPlayer(Player(tpid - 1), 0, 0, "FIGHT!")
        
        call RemoveSavedInteger(MiscHash, 0, GetHandleId(t))
        call RemoveSavedInteger(MiscHash, 1, GetHandleId(t))
        call ReleaseTimer(t)
    else
        //tick
        call SoundHandler("Sound\\Interface\\BattleNetTick.wav", Player(pid - 1))
        call SoundHandler("Sound\\Interface\\BattleNetTick.wav", Player(tpid - 1))
        call DisplayTextToPlayer(Player(pid - 1), 0, 0, I2S(time + 1) + "...")
        call DisplayTextToPlayer(Player(tpid - 1), 0, 0, I2S(time + 1) + "...")
    endif
    
    set t = null
endfunction

function SetupDuel takes unit a, unit b, rect spawn1, rect spawn2, real face, real face2, integer arena, rect cam returns nothing
    local timer t = NewTimerEx(4)
    local integer pid = GetPlayerId(GetOwningPlayer(a)) + 1
    local integer tpid = GetPlayerId(GetOwningPlayer(b)) + 1
    local real x = GetRectCenterX(spawn1)
    local real y = GetRectCenterY(spawn1)
    local real x2 = GetRectCenterX(spawn2)
    local real y2 = GetRectCenterY(spawn2)
    local player p = GetOwningPlayer(a)
    local player p2 = GetOwningPlayer(b)

    set ArenaQueue[pid] = 0
    set ArenaQueue[tpid] = 0
    
    call CleanupSummons(p)
    call CleanupSummons(p2)

    call GroupAddUnit(Arena[arena], a)
    call GroupAddUnit(Arena[arena], b)

    call DisplayTextToPlayer(p, 0, 0, User.fromIndex(tpid - 1).nameColored + " has joined the arena.")
    call DisplayTextToPlayer(p2, 0, 0, User.fromIndex(pid - 1).nameColored + " has joined the arena.")

    if GetRandomInt(0, 1) == 1 then
        call SetUnitPosition(a, x, y)
        call BlzSetUnitFacingEx(a, face)
        call SetUnitPosition(b, x2, y2)
        call BlzSetUnitFacingEx(b, face2)
    else
        call SetUnitPosition(a, x2, y2)
        call BlzSetUnitFacingEx(a, face2)
        call SetUnitPosition(b, x, y)
        call BlzSetUnitFacingEx(b, face)
    endif
    
    call EnterWeather(a)
    call EnterWeather(b)
    
    call SetPlayerAllianceStateBJ(p, p2, bj_ALLIANCE_UNALLIED)
    call SetPlayerAllianceStateBJ(p2, p, bj_ALLIANCE_UNALLIED)

    if hero_panel_on[pid * 8 + (tpid - 1)] == true then
        call ShowHeroPanel(p, p2, true)
    endif

    if hero_panel_on[tpid * 8 + (pid - 1)] == true then
        call ShowHeroPanel(p2, p, true)
    endif
    
    call PauseUnit(a, true)
    call PauseUnit(b, true)

    call SetCameraBoundsRectForPlayerEx(p, cam)
    call SetCameraBoundsRectForPlayerEx(p2, cam)

    if GetLocalPlayer() == p then
        call PanCameraToTimed(GetUnitX(a), GetUnitY(a), 0)
    endif
    if GetLocalPlayer() == p2 then
        call PanCameraToTimed(GetUnitX(b), GetUnitY(b), 0)
    endif
    
    call SaveInteger(MiscHash, 0, GetHandleId(t), pid)
    call SaveInteger(MiscHash, 1, GetHandleId(t), tpid)
    call TimerStart(t, 1, true, function DuelCountdown)

    set t = null
    set p = null
    set p2 = null
endfunction

function ArenaCleanup takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer arena = GetTimerData(t)
    local unit killed = LoadUnitHandle(MiscHash, 0, GetHandleId(t))
    local unit u

    if arena != 2 then 
        loop
            set u = FirstOfGroup(Arena[arena])
            exitwhen u == null
            call GroupRemoveUnit(Arena[arena], u)
            call SetUnitAnimation(u, "stand")
            call SetUnitPositionLoc(u, TownCenter)
            call SetWidgetLife(u, BlzGetUnitMaxHP(u))
            call SetCameraBoundsRectForPlayerEx(GetOwningPlayer(u), gg_rct_Main_Map_Vision)
            call PanCameraToTimedForPlayer(GetOwningPlayer(u), GetUnitX(u), GetUnitY(u), 0)
            call EnterWeather(u)
            set ArenaQueue[GetPlayerId(GetOwningPlayer(u)) + 1] = 0
            call TimerStart(NewTimerEx(GetPlayerId(GetOwningPlayer(u)) + 1), 2, false, function ArenaUnpause)
        endloop
    else
        call GroupRemoveUnit(Arena[arena], killed)
        call SetUnitAnimation(killed, "stand")
        call SetUnitPositionLoc(killed, TownCenter)
        call SetWidgetLife(killed, BlzGetUnitMaxHP(killed))
        call SetCameraBoundsRectForPlayerEx(GetOwningPlayer(killed), gg_rct_Main_Map_Vision)
        call PanCameraToTimedForPlayer(GetOwningPlayer(killed), GetUnitX(killed), GetUnitY(killed), 0)
        call EnterWeather(killed)
        set ArenaQueue[GetPlayerId(GetOwningPlayer(killed)) + 1] = 0
        call TimerStart(NewTimerEx(GetPlayerId(GetOwningPlayer(killed)) + 1), 2, false, function ArenaUnpause)
    endif
    
    call RemoveSavedHandle(MiscHash, 0, GetHandleId(t))
    call ReleaseTimer(t)
    
    set t = null
    set killed = null
endfunction

function ArenaDeath takes unit u, unit u2, integer arena returns nothing
    local timer t = NewTimerEx(arena)
    local User U = User.first
    local player p = GetOwningPlayer(u)
    local player p2 = GetOwningPlayer(u2)
    local integer pid = GetPlayerId(p) + 1
    local integer tpid = GetPlayerId(p2) + 1
    
    if arena != 2 then
        call PauseUnit(u2, true)
        call UnitAddAbility(u2, 'Avul')
        call SetPlayerAllianceStateBJ(p, p2, bj_ALLIANCE_ALLIED_VISION)
        call SetPlayerAllianceStateBJ(p2, p, bj_ALLIANCE_ALLIED_VISION)
        if hero_panel_on[pid * 8 + (tpid - 1)] == true then
            call ShowHeroPanel(p, p2, true)
        endif
    
        if hero_panel_on[tpid * 8 + (pid - 1)] == true then
            call ShowHeroPanel(p2, p, true)
        endif
    else
        loop
            exitwhen U == User.NULL
            call SetPlayerAllianceStateBJ(U.toPlayer(), p, bj_ALLIANCE_ALLIED_VISION)
            call SetPlayerAllianceStateBJ(p, U.toPlayer(), bj_ALLIANCE_ALLIED_VISION)
            if hero_panel_on[pid * 8 + (tpid - 1)] == true then
                call ShowHeroPanel(p, p2, true)
            endif
        
            if hero_panel_on[tpid * 8 + (pid - 1)] == true then
                call ShowHeroPanel(p2, p, true)
            endif
            set U = U.next
        endloop
    endif
    
    call SaveUnitHandle(MiscHash, 0, GetHandleId(t), u)
    
    //timer, cleanup
    call TimerStart(t, 3, false, function ArenaCleanup)
    
    set t = null
    set p = null
    set p2 = null
endfunction

function FirstOfArena takes integer arena, integer pid returns integer
    local integer tpid = -1
    local User U = User.first
    
    loop
        exitwhen U == User.NULL
        set tpid = GetPlayerId(U.toPlayer()) + 1
        
        if pid != tpid and ArenaQueue[tpid] == arena then
            return tpid
        endif
        
        set U = U.next
    endloop
    
    return tpid
endfunction

function CountArenaQueue takes integer arena returns integer
    local integer pid
    local integer count = 0
    local User U = User.first
    
    loop
        exitwhen U == User.NULL
        set pid = GetPlayerId(U.toPlayer()) + 1
        
        if ArenaQueue[pid] == arena then
            set count = count + 1
        endif
        
        set U = U.next
    endloop
    
    return count
endfunction


function EnterPVP takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local button b = GetClickedButton()
    local integer pid = GetPlayerId(p) + 1
    local integer tpid
    local integer num = 0
    local real x
    local real y
    local integer i = 1
    local User U = User.first
    
    loop
        exitwhen b == PvpButton[pid * 8 + i] or i > ArenaMax
        set i = i + 1
    endloop

    set tpid = FirstOfArena(i, pid)
    
    if GetUnitArena(Hero[pid]) == 0 then
        if b == PvpButton[pid * 8 + 1] then
            set ArenaQueue[pid] = i
            set num = CountArenaQueue(i)
        
            if num == 1 then
                call DisplayTextToPlayer(p, 0, 0, "Waiting for an opponent to join...")
            elseif num == 2 then
                call SetupDuel(Hero[pid], Hero[tpid], gg_rct_Arena1Spawn1, gg_rct_Arena1Spawn2, 270, 90, i, gg_rct_Arena1Vision)
            else
                call DisplayTextToPlayer(p, 0, 0, "This arena is occupied already!")
                set ArenaQueue[pid] = 0
            endif
        elseif b == PvpButton[pid * 8 + 2] then
            //FFA
            set ArenaQueue[pid] = 0
            call GroupAddUnit(Arena[i], Hero[pid])
            
            call CleanupSummons(p)
            set x = GetRandomReal(GetRectMinX(gg_rct_Arena2), GetRectMaxX(gg_rct_Arena2))
            set y = GetRandomReal(GetRectMinY(gg_rct_Arena2), GetRectMaxY(gg_rct_Arena2))
            
            call SetUnitPosition(Hero[pid], x, y)
            call EnterWeather(Hero[pid])

            call SetCameraBoundsRectForPlayerEx(p, gg_rct_Arena2Vision)
            if GetLocalPlayer() == p then
                call PanCameraToTimed(x, y, 0)
            endif
            
            loop
                exitwhen U == User.NULL
                set tpid = GetPlayerId(U.toPlayer()) + 1

                call SetPlayerAllianceStateBJ(U.toPlayer(), p, bj_ALLIANCE_UNALLIED)
                call SetPlayerAllianceStateBJ(p, U.toPlayer(), bj_ALLIANCE_UNALLIED)

                if hero_panel_on[pid * 8 + (tpid - 1)] == true then
                    call ShowHeroPanel(p, U.toPlayer(), true)
                endif
            
                if hero_panel_on[tpid * 8 + (pid - 1)] == true then
                    call ShowHeroPanel(U.toPlayer(), p, true)
                endif
                set U = U.next
            endloop
            
            call DisplayTextToPlayer(p, 0, 0, "Type -flee to leave anytime.")
        elseif b == PvpButton[pid * 8 + 3] then
            set ArenaQueue[pid] = i
            set num = CountArenaQueue(i)
        
            if num == 1 then
                call DisplayTextToPlayer(p, 0, 0, "Waiting for an opponent to join...")
            elseif num == 2 then
                call SetupDuel(Hero[pid], Hero[tpid], gg_rct_Arena3Spawn1, gg_rct_Arena3Spawn2, 0, 180, i, gg_rct_Arena3Vision)
            else
                call DisplayTextToPlayer(p, 0, 0, "This arena is occupied already!")
                set ArenaQueue[pid] = 0
            endif
        else

        endif
    endif
    
    set p = null
    set b = null
endfunction

//===========================================================================
function PVPInit takes nothing returns nothing
    set Arena[1] = CreateGroup()
    set Arena[2] = CreateGroup()
    set Arena[3] = CreateGroup()
endfunction

endlibrary
