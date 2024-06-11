--[[
    keyboard.lua

    A module that handles keyboard events outside of text boxes

    Future considerations: Custom hotkey system for spells and other GUI
]]

OnInit.final("Keyboard", function(Require)
    Require('Users')
    Require('Variables')
    Require('Items')

    local function Forward_Slash()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

        MULTIBOARD.next(pid)

        return false
    end

    local function Period()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

        MULTIBOARD.minimize(pid)

        return false
    end

    local function F5_Key()
        return false
    end

    local function Arrow_Key()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

        panCounter[pid] = panCounter[pid] + 1

        return false
    end

    local function Escape()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

        STAT_WINDOW.close(pid)

        return false
    end

    local function Tab_Down()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local itm ---@type Item 

        if altModifier[pid] then
            altModifier[pid] = false

            UpdateSpellTooltips(pid)

            for i = 0, 5 do
                if GetLocalPlayer() == GetTriggerPlayer() then
                    itm = Item[UnitItemInSlot(GetMainSelectedUnit(), i)]

                    if itm and itm.tooltip then
                        BlzSetItemExtendedTooltip(itm.obj, itm.tooltip)
                    end
                end
            end
        end

        return false
    end

    local function Alt_Down()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

        if not altModifier[pid] then
            altModifier[pid] = true

            UpdateSpellTooltips(pid)
            UpdateItemTooltips(pid)
        end

        return false
    end

    local function Alt_Up()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

        if altModifier[pid] then
            altModifier[pid] = false

            UpdateSpellTooltips(pid)
            UpdateItemTooltips(pid)
        end

        return false
    end

    local function W_Down()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1

        --shatter frozen orb early
        local missile = FROZENORB.missile[pid] ---@type Missiles

        if missile then
            missile:onFinish()
            missile:terminate()
        end

        --cancel hidden guise early
        local pt = TimerList[pid]:get(HIDDENGUISE.id)

        if pt then
            HIDDENGUISE.expire(pt)
        end

        return false
    end

        local altDown = CreateTrigger()
        local altUp   = CreateTrigger()
        local wDown   = CreateTrigger()
        local tabDown = CreateTrigger()
        local arrow   = CreateTrigger()
        local esc     = CreateTrigger()
        local forwardslash = CreateTrigger()
        local period = CreateTrigger()
        local u       = User.first ---@type User 

        while u do
            BlzTriggerRegisterPlayerKeyEvent(altDown, u.player, OSKEY_LALT, 4, true)
            BlzTriggerRegisterPlayerKeyEvent(altUp, u.player, OSKEY_LALT, 0, false)
            BlzTriggerRegisterPlayerKeyEvent(wDown, u.player, OSKEY_W, 0, true)
            BlzTriggerRegisterPlayerKeyEvent(tabDown, u.player, OSKEY_TAB, 0, true)
            BlzTriggerRegisterPlayerKeyEvent(arrow, u.player, OSKEY_LEFT, 0, false)
            BlzTriggerRegisterPlayerKeyEvent(arrow, u.player, OSKEY_RIGHT, 0, false)
            BlzTriggerRegisterPlayerKeyEvent(arrow, u.player, OSKEY_UP, 0, false)
            BlzTriggerRegisterPlayerKeyEvent(arrow, u.player, OSKEY_DOWN, 0, false)
            BlzTriggerRegisterPlayerKeyEvent(esc, u.player, OSKEY_ESCAPE, 0, false)
            BlzTriggerRegisterPlayerKeyEvent(forwardslash, u.player, OSKEY_OEM_2, 0, false)
            BlzTriggerRegisterPlayerKeyEvent(period, u.player, OSKEY_OEM_PERIOD, 0, false)
            u = u.next
        end

        TriggerAddCondition(altDown, Filter(Alt_Down))
        TriggerAddCondition(altUp, Filter(Alt_Up))
        TriggerAddCondition(wDown, Filter(W_Down))
        TriggerAddCondition(tabDown, Filter(Tab_Down))
        TriggerAddCondition(arrow, Filter(Arrow_Key))
        TriggerAddCondition(esc, Filter(Escape))
        TriggerAddCondition(forwardslash, Filter(Forward_Slash))
        TriggerAddCondition(period, Filter(Period))
end, Debug.getLine())
