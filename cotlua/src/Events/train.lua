--[[
    train.lua

    Handles actions related to training units
]]

OnInit.final("Train", function(Require)
    Require('Users')

    workerCount=__jarray(0) ---@type integer[] 
    smallwispCount=__jarray(0) ---@type integer[] 
    largewispCount=__jarray(0) ---@type integer[] 
    warriorCount=__jarray(0) ---@type integer[] 
    rangerCount=__jarray(0) ---@type integer[] 

function OnTrainCancel()
    local id         = GetTrainedUnitType() ---@type integer 
    local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

    if id == FourCC('h01P') or id == FourCC('h03Y') or id == FourCC('h04B') or id == FourCC('n09E') or id == FourCC('n00Q') or id == FourCC('n023') or id == FourCC('n09F') or id == FourCC('h010') or id == FourCC('h04U') or id == FourCC('h053') then
        workerCount[pid] = workerCount[pid] - 1
        SetPlayerTechResearched(Player(pid - 1), FourCC('R013'), 1)
    elseif id == FourCC('e00J') or id == FourCC('e000') or id == FourCC('e00H') or id == FourCC('e00K') or id == FourCC('e006') or id == FourCC('e00I') or id == FourCC('e00T') or id == FourCC('e00Y') then
        smallwispCount[pid] = smallwispCount[pid] - 1
        SetPlayerTechResearched(Player(pid - 1), FourCC('R014'), 1)
    elseif id == FourCC('e00Z') or id == FourCC('e00R') or id == FourCC('e00Q') or id == FourCC('e01L') or id == FourCC('e01E') or id == FourCC('e010') then
        largewispCount[pid] = largewispCount[pid] - 1
        SetPlayerTechResearched(Player(pid - 1), FourCC('R015'), 1)
    elseif id == FourCC('h00S') or id == FourCC('h017') or id == FourCC('h00I') or id == FourCC('h016') or id == FourCC('nwlg') or id == FourCC('h004') or id == FourCC('h04V') or id == FourCC('o02P') then
        warriorCount[pid] = warriorCount[pid] - 1
        SetPlayerTechResearched(Player(pid - 1), FourCC('R016'), 1)
    elseif id == FourCC('n00A') or id == FourCC('n014') or id == FourCC('n009') or id == FourCC('n00D') or id == FourCC('n002') or id == FourCC('h005') or id == FourCC('o02Q') then
        rangerCount[pid] = rangerCount[pid] - 1
        SetPlayerTechResearched(Player(pid - 1), FourCC('R017'), 1)
    end

    ExperienceControl(pid)
end

    local cancel = CreateTrigger()
    local u = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(cancel, u.player, EVENT_PLAYER_UNIT_TRAIN_CANCEL, nil)
        u = u.next
    end

    TriggerAddAction(cancel, OnTrainCancel)

end, Debug and Debug.getLine())
