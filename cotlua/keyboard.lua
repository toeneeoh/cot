if Debug then Debug.beginFile 'Keyboard' end

OnInit.final("Keyboard", function(require)
    require 'Users'
    require 'Variables'
    require 'Items'

    function Tab_Down()
        local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local i         = 0 ---@type integer 
        local itm ---@type Item 

        if altModifier[pid] then
            altModifier[pid] = false

            UpdateSpellTooltips(pid)

            while i <= 5 do

                if GetLocalPlayer() == GetTriggerPlayer() then
                    itm = Item[UnitItemInSlot(GetMainSelectedUnitEx(), i)]

                    BlzSetItemExtendedTooltip(itm.obj, itm.tooltip)
                end

                i = i + 1
            end
        end
    end

    function Alt_Down()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local itm ---@type Item 

        if not altModifier[pid] then
            altModifier[pid] = true

            UpdateSpellTooltips(pid)

            for i = 0, 5 do
                if GetLocalPlayer() == GetTriggerPlayer() then
                    itm = Item[UnitItemInSlot(GetMainSelectedUnitEx(), i)]

                    if itm then
                        if itm.alt_tooltip then
                            BlzSetItemExtendedTooltip(itm.obj, itm.alt_tooltip)
                        end
                    end
                end
            end
        end
    end

    function Alt_Up()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local itm ---@type Item 

        if altModifier[pid] then
            altModifier[pid] = false

            UpdateSpellTooltips(pid)

            for i = 0, 5 do
                if GetLocalPlayer() == GetTriggerPlayer() then
                    itm = Item[UnitItemInSlot(GetMainSelectedUnitEx(), i)]

                    if itm then
                        if itm.tooltip then
                            BlzSetItemExtendedTooltip(itm.obj, itm.tooltip)
                        end
                    end
                end
            end
        end
    end

    function W_Down()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local pt = TimerList[pid]:get(FROZENORB.id, Hero[pid]) ---@class PlayerTimer 

        --shatter frozen orb early
        if pt then
            pt.dur = 0.
        end

        --cancel hidden guise early
        pt = TimerList[pid]:get(HIDDENGUISE.id)

        if pt then
            Item.create(UnitAddItemById(pt.source, FourCC('I0OW')))
            SetUnitVertexColor(pt.source, 255, 255, 255, 255)
            ToggleCommandCard(pt.source, true)
            UnitRemoveAbility(pt.source, FourCC('Avul'))
            Unit[pt.source]:attack(true)

            pt:destroy()
        end
    end

        local altDown         = CreateTrigger() ---@type trigger 
        local altUp         = CreateTrigger() ---@type trigger 
        local wDown         = CreateTrigger() ---@type trigger 
        local tabDown         = CreateTrigger() ---@type trigger 
        local u      = User.first ---@type User 

        while u do
            BlzTriggerRegisterPlayerKeyEvent(altDown, u.player, OSKEY_LALT, 4, true)
            BlzTriggerRegisterPlayerKeyEvent(altUp, u.player, OSKEY_LALT, 0, false)
            BlzTriggerRegisterPlayerKeyEvent(wDown, u.player, OSKEY_W, 0, true)
            BlzTriggerRegisterPlayerKeyEvent(tabDown, u.player, OSKEY_TAB, 0, true)
            u = u.next
        end

        TriggerAddCondition(altDown, Filter(Alt_Down))
        TriggerAddCondition(altUp, Filter(Alt_Up))
        TriggerAddCondition(wDown, Filter(W_Down))
        TriggerAddCondition(tabDown, Filter(Tab_Down))

end)

if Debug then Debug.endFile() end
