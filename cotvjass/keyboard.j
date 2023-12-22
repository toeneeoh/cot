library keyboard requires Functions

    function Tab_Down takes nothing returns nothing
        local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
        local integer i = 0
        local Item itm

        if altModifier[pid] then
            set altModifier[pid] = false

            call UpdateSpellTooltips(pid)

            loop
                exitwhen i > 5

                loop
                    exitwhen i > 5

                    if GetLocalPlayer() == GetTriggerPlayer() then
                        set itm = Item[UnitItemInSlot(GetMainSelectedUnitEx(), i)]

                        call BlzSetItemExtendedTooltip(itm.obj, itm.tooltip)
                    endif

                    set i = i + 1
                endloop

                set i = i + 1
            endloop
        endif
    endfunction

    function Alt_Down takes nothing returns nothing
        local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
        local integer i = 0
        local Item itm

        if not altModifier[pid] then
            set altModifier[pid] = true

            call UpdateSpellTooltips(pid)

            loop
                exitwhen i > 5

                if GetLocalPlayer() == GetTriggerPlayer() then
                    set itm = Item[UnitItemInSlot(GetMainSelectedUnitEx(), i)]

                    call BlzSetItemExtendedTooltip(itm.obj, itm.alt_tooltip)
                endif

                set i = i + 1
            endloop
        endif
    endfunction

    function Alt_Up takes nothing returns nothing
        local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
        local integer i = 0
        local Item itm

        if altModifier[pid] then
            set altModifier[pid] = false

            call UpdateSpellTooltips(pid)

            loop
                exitwhen i > 5

                if GetLocalPlayer() == GetTriggerPlayer() then
                    set itm = Item[UnitItemInSlot(GetMainSelectedUnitEx(), i)]

                    call BlzSetItemExtendedTooltip(itm.obj, itm.tooltip)
                endif

                set i = i + 1
            endloop
        endif
    endfunction

    function W_Down takes nothing returns nothing
        local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
        local PlayerTimer pt = TimerList[pid].get(null, Hero[pid], 'forb')

        if pt != 0 then
            set pt.dur = 0
        endif
    endfunction

    function KeyboardInit takes nothing returns nothing
        local trigger altDown = CreateTrigger()
        local trigger altUp = CreateTrigger()
        local trigger wDown = CreateTrigger()
        local trigger tabDown = CreateTrigger()
        local User u = User.first
        
        loop
            exitwhen u == User.NULL
            call BlzTriggerRegisterPlayerKeyEvent(altDown, u.toPlayer(), OSKEY_LALT, 4, true)
            call BlzTriggerRegisterPlayerKeyEvent(altUp, u.toPlayer(), OSKEY_LALT, 0, false)
            call BlzTriggerRegisterPlayerKeyEvent(wDown, u.toPlayer(), OSKEY_W, 0, true)
            call BlzTriggerRegisterPlayerKeyEvent(tabDown, u.toPlayer(), OSKEY_TAB, 0, true)
            set u = u.next
        endloop

        call TriggerAddCondition(altDown, Filter(function Alt_Down))
        call TriggerAddCondition(altUp, Filter(function Alt_Up))
        call TriggerAddCondition(wDown, Filter(function W_Down))
        call TriggerAddCondition(tabDown, Filter(function Tab_Down))
    
        set altDown = null
        set altUp = null
        set wDown = null
        set tabDown = null
    endfunction

endlibrary
