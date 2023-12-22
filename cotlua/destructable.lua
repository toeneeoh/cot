if Debug then Debug.beginFile 'Destructables' end

OnInit.final("Destructables", function()

---@param d destructable
---@param d2 destructable
function DoBridge(d, d2)
    if GetDestructableLife(d) <= 0  then
        DestructableRestoreLife(d, GetDestructableMaxLife(d), true)
        SetDestructableAnimation(d, "birth")
    elseif GetDestructableLife(d) > 0 then
        KillDestructable(d)
    end
    TriggerSleepAction(1.00)
    DestructableRestoreLife(d2, GetDestructableMaxLife(d2), true)
end

---@param u unit
---@param u2 unit
---@param d destructable
function DoWaygate(u, u2, d)
    if WaygateIsActive(u) and WaygateIsActive(u2) then
        WaygateActivate(u, false)
        WaygateActivate(u2, false)
    else
        WaygateActivate(u, true)
        WaygateActivate(u2, true)
    end
    TriggerSleepAction(1.00)
    DestructableRestoreLife(d, GetDestructableMaxLife(d), true)
end

---@param d destructable
---@param d2 destructable
function DoGate(d, d2)
    if GetDestructableLife(d) <= 0 then
        DestructableRestoreLife(d, GetDestructableMaxLife(d), true)
        SetDestructableAnimation(d, "stand")
    elseif GetDestructableLife(d) > 0 then
        KillDestructable(d)
        SetDestructableAnimation(d, "death alternate")
    end
    TriggerSleepAction(1.00)
    DestructableRestoreLife(d2, GetDestructableMaxLife(d2), true)
end

function Destructable()
    local d              = GetTriggerDestructable() ---@type destructable 

    if d == gg_dest_DTlv_3795 then -- gates
        DoGate(gg_dest_ITg4_0445, d)
    elseif d == gg_dest_DTlv_3788 then
        DoGate(gg_dest_LTg3_1074, d)
    elseif d == gg_dest_DTlv_11055 then
        DoGate(gg_dest_ITtg_6978, d)
    elseif d == gg_dest_DTlv_8411 then
        DoGate(gg_dest_ITg1_8348, d)
    elseif d == gg_dest_DTlv_3778 then
        DoGate(gg_dest_LTe1_1075, d)
    elseif d == gg_dest_DTlv_3772 then
        DoGate(gg_dest_ITtg_0892, d)
    elseif d == gg_dest_DTlv_3796 then -- waygates
        DoWaygate(gg_unit_nwgt_0024, gg_unit_nwgt_0023, d)
    elseif d == gg_dest_DTlv_3785 then
        DoWaygate(gg_unit_nwgt_0003, gg_unit_nwgt_0017, d)
    elseif d == gg_dest_DTlv_3774 then
        DoWaygate(gg_unit_nwgt_0010, gg_unit_nwgt_0010, d)
    elseif d == gg_dest_DTlv_3776 then -- bridges
        DoBridge(gg_dest_DTs2_1495, d)
    elseif d == gg_dest_DTlv_4001 then
        DoBridge(gg_dest_DTs2_1073, d)
    elseif d == gg_dest_LTcr_9593 then --easter egg
        Item.create(CreateItem(FourCC('Ipow'), GetDestructableX(d), GetDestructableY(d)))
    elseif d == gg_dest_LTbs_4010 or d == gg_dest_LTbs_4009 or d == gg_dest_LTcr_4012 or d == gg_dest_LTba_9594 or d == gg_dest_LTbs_4008 then
        Item.create(CreateItem(DropTable:pickItem(69), GetWidgetX(d), GetWidgetY(d)), 600.)
    elseif d == gg_dest_B007_3861 then
        Item.create(CreateItem(FourCC('I042'), GetWidgetX(d), GetWidgetY(d)))
    end
end

    local dest         = CreateTrigger() ---@type trigger 

    AddResourceAmount(gg_unit_ngol_0009, 49500000)
    AddResourceAmount(gg_unit_ngol_0019, 49500000)
    AddResourceAmount(gg_unit_ngol_0014, 49500000)
    AddResourceAmount(gg_unit_ngol_0012, 49500000)
    AddResourceAmount(gg_unit_ngol_0001, 49500000)
    AddResourceAmount(gg_unit_ngol_0022, 49500000)
    AddResourceAmount(gg_unit_ngol_0021, 49500000)
    AddResourceAmount(gg_unit_ngol_0013, 49500000)

    TriggerRegisterDeathEvent(dest, gg_dest_B007_3861)
    TriggerRegisterDeathEvent(dest, gg_dest_LTbs_4010)
    TriggerRegisterDeathEvent(dest, gg_dest_LTbs_4009)
    TriggerRegisterDeathEvent(dest, gg_dest_LTcr_4012)
    TriggerRegisterDeathEvent(dest, gg_dest_LTba_9594)
    TriggerRegisterDeathEvent(dest, gg_dest_LTbs_4008)
    TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3795)
    TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3788)
    TriggerRegisterDeathEvent(dest, gg_dest_DTlv_11055)
    TriggerRegisterDeathEvent(dest, gg_dest_DTlv_8411)
    TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3778)
    TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3772)
    TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3796)
    TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3785)
    TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3774)
    TriggerRegisterDeathEvent(dest, gg_dest_DTlv_3776)
    TriggerRegisterDeathEvent(dest, gg_dest_DTlv_4001)
    TriggerRegisterDeathEvent(dest, gg_dest_LTcr_9593)

    TriggerAddAction(dest, Destructable)

end)

if Debug then Debug.endFile() end
