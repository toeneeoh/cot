library GameStatus 
/***************************************************************
*
*   v1.0.0 by TriggerHappy
*   _________________________________________________________________________
*   Simple API for detecting if the game is online, offline, or a replay.
*   _________________________________________________________________________
*   1. Installation
*   _________________________________________________________________________
*   Copy the script to your map and save it (requires JassHelper *or* JNGP)
*   _________________________________________________________________________
*   2. API
*   _________________________________________________________________________
*   This library provides one function
*
*       function GetGameStatus takes nothing returns integer
*
*   It returns one of the following constants
*
*       - GAME_STATUS_OFFLINE
*       - GAME_STATUS_ONLINE
*       - GAME_STATUS_REPLAY
*
***************************************************************/

// Configuration:
globals
    // The dummy unit is only created once, and removed directly after.
    private constant integer DUMMY_UNIT_ID = 'hfoo'
endglobals
// (end)

globals
    private integer status = 0
    integer GAME_STATE = 0
endglobals

function GetGameStatus takes nothing returns integer
    return status
endfunction

function GameStatusInit takes nothing returns nothing
    local player firstPlayer = User.first.toPlayer()
    local unit u
    local boolean selected

    // find an actual player
    // force the player to select a dummy unit
    set u = CreateUnit(firstPlayer, DUMMY_UNIT_ID, 0, 0, 0)
    call SelectUnit(u, true)
    set selected = IsUnitSelected(u, firstPlayer)
    call RemoveUnit(u)
    set u = null

    if (selected) then
        // detect if replay or offline game
        if (ReloadGameCachesFromDisk()) then
            set GAME_STATE = 0 //single player
        else
            set GAME_STATE = 1 //replay
        endif
    else
        // if the unit wasn't selected instantly, the game is online
        set GAME_STATE = 2
    endif
endfunction

endlibrary
