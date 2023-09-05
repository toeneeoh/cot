library Destructables initializer DestructableInit requires Functions

function DoBridge takes destructable d, destructable d2 returns nothing
    if GetDestructableLife(d) <= 0  then
        call DestructableRestoreLife(d, GetDestructableMaxLife(d), true)
        call SetDestructableAnimation(d, "birth")
    elseif GetDestructableLife(d) > 0 then
        call KillDestructable(d)
    endif
    call TriggerSleepAction(1.00)
    call DestructableRestoreLife(d2, GetDestructableMaxLife(d2), true)
endfunction

function DoWaygate takes unit u, unit u2, destructable d returns nothing
    if WaygateIsActive(u) and WaygateIsActive(u2) then
        call WaygateActivate(u, false)
        call WaygateActivate(u2, false)
    else
        call WaygateActivate(u, true)
        call WaygateActivate(u2, true)
    endif
    call TriggerSleepAction(1.00)
    call DestructableRestoreLife(d, GetDestructableMaxLife(d), true)
endfunction

function DoGate takes destructable d, destructable d2 returns nothing
    if GetDestructableLife(d) <= 0 then
        call DestructableRestoreLife(d, GetDestructableMaxLife(d), true)
        call SetDestructableAnimation(d, "stand")
    elseif GetDestructableLife(d) > 0 then
        call KillDestructable(d)
        call SetDestructableAnimation(d, "death alternate")
    endif
    call TriggerSleepAction(1.00)
    call DestructableRestoreLife(d2, GetDestructableMaxLife(d2), true)
endfunction

function Destructable takes nothing returns nothing
    local destructable d = GetTriggerDestructable()
    
    if d == gg_dest_DTlv_3795 then // gates
        call DoGate(gg_dest_ITg4_0445, d)
    elseif d == gg_dest_DTlv_3788 then
        call DoGate(gg_dest_LTg3_1074, d)
    elseif d == gg_dest_DTlv_11055 then
        call DoGate(gg_dest_ITtg_6978, d)
    elseif d == gg_dest_DTlv_8411 then
        call DoGate(gg_dest_ITg1_8348, d)
    elseif d == gg_dest_DTlv_3778 then
        call DoGate(gg_dest_LTe1_1075, d)
    elseif d == gg_dest_DTlv_3772 then
        call DoGate(gg_dest_ITtg_0892, d)
    elseif d == gg_dest_DTlv_3796 then // waygates
        call DoWaygate(gg_unit_nwgt_0024, gg_unit_nwgt_0023, d)
    elseif d == gg_dest_DTlv_3785 then
        call DoWaygate(gg_unit_nwgt_0003, gg_unit_nwgt_0017, d)
    elseif d == gg_dest_DTlv_3774 then
        call DoWaygate(gg_unit_nwgt_0010, gg_unit_nwgt_0010, d)
    elseif d == gg_dest_DTlv_3776 then // bridges
        call DoBridge(gg_dest_DTs2_1495, d)
    elseif d == gg_dest_DTlv_4001 then
        call DoBridge(gg_dest_DTs2_1073, d)
    elseif d == gg_dest_LTcr_4013 then //easter egg
        call Item.assign(CreateItem('Ipow', GetDestructableX(d), GetDestructableY(d)))
    elseif d == gg_dest_LTbs_4010 or d == gg_dest_LTbs_4009 or d == gg_dest_LTcr_4012 or d == gg_dest_LTba_4011 or d == gg_dest_LTbs_4008 then
        call Item.create(DropTable.pickItem(69), GetWidgetX(d), GetWidgetY(d), 600.)
    elseif d == gg_dest_B007_3861 then
        call Item.create('I042', GetWidgetX(d), GetWidgetY(d), 0.)
    endif
    
    set d = null
endfunction

//===========================================================================
function DestructableInit takes nothing returns nothing
    local trigger dest = CreateTrigger()
    
    call AddResourceAmount(gg_unit_ngol_0009, 49500000)
    call AddResourceAmount(gg_unit_ngol_0019, 49500000)
    call AddResourceAmount(gg_unit_ngol_0014, 49500000)
    call AddResourceAmount(gg_unit_ngol_0012, 49500000)
    call AddResourceAmount(gg_unit_ngol_0001, 49500000)
    call AddResourceAmount(gg_unit_ngol_0022, 49500000)
    call AddResourceAmount(gg_unit_ngol_0021, 49500000)
    call AddResourceAmount(gg_unit_ngol_0013, 49500000)
    
    call TriggerRegisterDeathEvent(dest, gg_dest_B007_3861)
    call TriggerRegisterDeathEvent(dest, gg_dest_LTbs_4010)
    call TriggerRegisterDeathEvent(dest, gg_dest_LTbs_4009)
    call TriggerRegisterDeathEvent(dest, gg_dest_LTcr_4012)
    call TriggerRegisterDeathEvent(dest, gg_dest_LTba_4011)
    call TriggerRegisterDeathEvent(dest, gg_dest_LTbs_4008)
    call TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3795)
    call TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3788)
    call TriggerRegisterDeathEvent(dest, gg_dest_DTlv_11055)
    call TriggerRegisterDeathEvent(dest, gg_dest_DTlv_8411)
    call TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3778)
    call TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3772)
    call TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3796)
    call TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3785)
    call TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3774)
    call TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3776)
    call TriggerRegisterDeathEvent(dest, gg_dest_DTlv_4001)
    call TriggerRegisterDeathEvent(dest, gg_dest_LTcr_4013)
    
    call TriggerAddAction(dest, function Destructable)

    set dest = null
endfunction

endlibrary
