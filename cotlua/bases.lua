if Debug then Debug.beginFile 'Bases' end

OnInit.final("Bases", function(require)
    require 'Users'

    urhome=__jarray(0) ---@type integer[] 
    mybase={} ---@type unit[] 

function OnResearch()
    local u      = GetTriggerUnit() ---@type unit 
    local p        = GetOwningPlayer(u) ---@type player 
    local uid         = GetUnitTypeId(u) ---@type integer 
    local pid         = GetPlayerId(p) + 1 ---@type integer 

    if urhome[pid] ~= 4 and (uid == FourCC('h01K') or uid == FourCC('h01L') or uid == FourCC('h01H') or uid == FourCC('h01J')) then --grand nations
        urhome[pid] = 4

        DisplayTextToForce(FORCE_PLAYING, (User[pid - 1].nameColored .. " has upgraded to a grand nation!"))
        DisplayTextToPlayer(p, 0, 0, "Your grand nation allows you to gain experience faster than a regular nation.")
    elseif uid == FourCC('h047') then --medean court
        SetUnitAbilityLevel(u, FourCC('A0A5'), 2)
        SetUnitAbilityLevel(u, FourCC('A0A7'), 2)
        SetUnitAbilityLevel(u, FourCC('A0A9'), 2)
    end
end

---@type fun(pt: PlayerTimer)
function BaseDead(pt)
    local p        = Player(pt.pid - 1) ---@type player 

    if urhome[pt.pid] == 0 then
        PanCameraToTimedLocForPlayer(p, TownCenter, 0)
        DisplayTextToForce(FORCE_PLAYING, User[pt.pid - 1].nameColored .. " was defeated from losing their base.")
        DisplayTextToPlayer(p, 0, 0, "You have lost the game. All of your structures and units will be removed from the game, however you may stay and watch or leave as you choose.")
        PlayerCleanup(p)
    else
        DisplayTextToPlayer(p, 0, 0, "You have narrowly avoided death this time. Be careful or next time you may not be so lucky...")
    end

    TimerDialogDisplay(Timer_Window_TUD[pid], false)
    DestroyTimerDialog(Timer_Window_TUD[pid])

    pt:destroy()
end

function BuildBase()
    local u      = GetConstructedStructure() ---@type unit 
    local i         = GetUnitTypeId(u) ---@type integer 
    local pid        = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
    local htype        = 0 ---@type integer 
    local x      = GetUnitX(u) ---@type number 
    local y      = GetUnitY(u) ---@type number 

    if RectContainsCoords(gg_rct_NoSin, x, y) then
        KillUnit(u)
        DisplayTextToPlayer(Player(pid - 1),0,0, "|cffff0000You can not build in town.|r")
        return
    end

    if i == FourCC('h01U') or i == FourCC('h038') or i == FourCC('h030') or i == FourCC('h02T') then --nation
        htype = 1
    elseif i == FourCC('h008') or i == FourCC('h00E') then --home
        htype = 2
    elseif i == FourCC('h00K') or i == FourCC('h047') then --grand home
        htype = 3
    --elseif i == FourCC('h047') then //grand nation
        --set htype = 4
    elseif i == FourCC('h03K') then --spirit lounge
        htype = 5
    elseif i == FourCC('h04T') then --satan
        htype = 6
    elseif i == FourCC('h050') then --Dnation
        htype = 7
    else
        return
    end

    if RectContainsCoords(gg_rct_Main_Map, x, y) == false then
        KillUnit(u)
        DisplayTextToPlayer(Player(pid - 1),0,0, "|cffff0000You can only build your home on the main map.|r")
        return
    end

    if htype > 0 and urhome[pid] > 0 then
        KillUnit(u)
        DisplayTextToPlayer(Player(pid - 1),0,0, "|cfff0000fOnly one base is allowed per player.|r")
        return
    end

    mybase[pid] = u

    if htype == 1 then
        DisplayTextToForce(FORCE_PLAYING, (User[pid - 1].nameColored .. " has built a nation and is not a bum anymore."))
        DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your nation gives you slight experience gain and allows you to build a mighty army.")
        urhome[pid] = htype
    elseif htype == 2 then
        DisplayTextToForce(FORCE_PLAYING, (User[pid - 1].nameColored .. " has built a home and is not a bum anymore."))
        DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your home allows you to gain experience faster than a nation.")
        urhome[pid] = htype
    elseif htype == 3 then
        DisplayTextToForce(FORCE_PLAYING, (User[pid - 1].nameColored .. " has built a grand home and is not a bum anymore."))
        DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your grand home allows you to gain experience faster than a nation or home.")
        urhome[pid] = htype
    elseif htype == 4 then
        DisplayTextToForce(FORCE_PLAYING, (User[pid - 1].nameColored .. " has built a grand nation and is not a bum anymore."))
        DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your grand nation allows you to gain experience faster than a regular nation.")
        urhome[pid] = htype
    elseif htype == 5 then
        DisplayTextToForce(FORCE_PLAYING, (User[pid - 1].nameColored .. " has built a chaotic home and is not a bum anymore."))
        DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your chaotic home allows you to gain experience faster than non-chaos homes.")
        urhome[pid] = htype
    elseif htype == 6 then
        DisplayTextToForce(FORCE_PLAYING, (User[pid - 1].nameColored .. " has built a chaotic home and is not a bum anymore."))
        DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your chaotic home allows you to gain 60% more experience than a lounge.")
        urhome[pid] = htype
    elseif htype == 7 then
        DisplayTextToForce(FORCE_PLAYING, (User[pid - 1].nameColored .. " has built a chaotic nation and is not a bum anymore."))
        DisplayTextToPlayer(GetOwningPlayer(u),0,0, "Your chaotic nation allows you to gain 30% more experience than a lounge and can create powerful chaotic units.")
        urhome[pid] = htype
    end

    TimerDialogDisplay(Timer_Window_TUD[pid], false)
    QuestSetCompletedBJ(Bum_Stage, true)
    ExperienceControl(pid)
end

    local base         = CreateTrigger() ---@type trigger 
    local research         = CreateTrigger() ---@type trigger 
    local u      = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(base, u.player, EVENT_PLAYER_UNIT_CONSTRUCT_FINISH, nil)
        TriggerRegisterPlayerUnitEvent(research, u.player, EVENT_PLAYER_UNIT_UPGRADE_FINISH, nil)
        u = u.next
    end

    TriggerAddAction(base,BuildBase)
    TriggerAddAction(research, OnResearch)

end)

if Debug then Debug.endFile() end
