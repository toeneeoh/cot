library Train requires Functions

globals
    integer array workerCount
    integer array smallwispCount
    integer array largewispCount
    integer array warriorCount
    integer array rangerCount
endglobals

function OnTrainCancel takes nothing returns nothing
    local integer id = GetTrainedUnitType()
    local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
    
    if id == 'h01P' or id == 'h03Y' or id == 'h04B' or id == 'n09E' or id == 'n00Q' or id == 'n023' or id == 'n09F' or id == 'h010' or id == 'h04U' or id == 'h053' then
        set workerCount[pid] = workerCount[pid] - 1
        call SetPlayerTechResearched(Player(pid - 1), 'R013', 1)
    elseif id == 'e00J' or id == 'e000' or id == 'e00H' or id == 'e00K' or id == 'e006' or id == 'e00I' or id == 'e00T' or id == 'e00Y' then
        set smallwispCount[pid] = smallwispCount[pid] - 1
        call SetPlayerTechResearched(Player(pid - 1), 'R014', 1)
    elseif id == 'e00Z' or id == 'e00R' or id == 'e00Q' or id == 'e01L' or id == 'e01E' or id == 'e010' then
        set largewispCount[pid] = largewispCount[pid] - 1
        call SetPlayerTechResearched(Player(pid - 1), 'R015', 1)
    elseif id == 'h00S' or id == 'h017' or id == 'h00I' or id == 'h016' or id == 'nwlg' or id == 'h004' or id == 'h04V' or id == 'o02P' then
        set warriorCount[pid] = warriorCount[pid] - 1
        call SetPlayerTechResearched(Player(pid - 1), 'R016', 1)
    elseif id == 'n00A' or id == 'n014' or id == 'n009' or id == 'n00D' or id == 'n002' or id == 'h005' or id == 'o02Q' then
        set rangerCount[pid] = rangerCount[pid] - 1
        call SetPlayerTechResearched(Player(pid - 1), 'R017', 1)
    endif
    
    call ExperienceControl(pid)
endfunction

function TrainInit takes nothing returns nothing
    local trigger cancel = CreateTrigger()
    local User u = User.first
    
    loop
        exitwhen u == User.NULL
        call TriggerRegisterPlayerUnitEvent(cancel, u.toPlayer(), EVENT_PLAYER_UNIT_TRAIN_CANCEL, null)
        set u = u.next
    endloop

    call TriggerAddAction(cancel, function OnTrainCancel)

    set cancel = null
endfunction

endlibrary
