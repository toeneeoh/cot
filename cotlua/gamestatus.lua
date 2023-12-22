if Debug then Debug.beginFile 'GameStatus' end

OnInit.final("GameStatus", function(require)
    require 'Users'

    GAME_STATE = 0 ---@type integer 
    local DUMMY_UNIT_ID = FourCC('eRez')
    local firstPlayer = User.first.player

    -- find an actual player
    -- force the player to select a dummy unit
    local u = CreateUnit(firstPlayer, DUMMY_UNIT_ID, 0, 0, 0)
    SelectUnit(u, true)
    local selected = IsUnitSelected(u, firstPlayer)
    RemoveUnit(u)

    if (selected) then
        -- detect if replay or offline game
        if (ReloadGameCachesFromDisk()) then
            GAME_STATE = 0 --single player
        else
            GAME_STATE = 1 --replay
        end
    else
        -- if the unit wasn't selected instantly, the game is online
        GAME_STATE = 2
    end

end)

if Debug then Debug.endFile() end
