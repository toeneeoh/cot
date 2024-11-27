--[[
    hotkeys.lua

    A library that implements custom hotkeys for functions as well hotkey customization.
]]

OnInit.final("Hotkeys", function(Require)
    Require('Users')
    Require('Variables')

    local hotkey_functions
    local changing_keybinds = {}
    local key_state = array2d(false) ---@type boolean[][]
    local key_bindings = {} ---@type table<integer, table<string, table<function>>>

    local function get_key_for_function(pid, target_func)
        if not key_bindings[pid] then
            return nil
        end

        for key_string, bound_functions in pairs(key_bindings[pid]) do
            for _, func in ipairs(bound_functions) do
                if func == target_func then
                    return key_string
                end
            end
        end

        return nil
    end

    local function update_state(pid, key_string, is_down)
        if key_state[pid][key_string] == is_down then
            return true
        end
        key_state[pid][key_string] = is_down

        return false
    end

    local function update_action_tooltip(pid, key_string, action)
        local func

        -- find action table
        for _, v in ipairs(hotkey_functions) do
            if v.func == action then
                func = v
                break
            end
        end

        if func and func.frame then
            local text = BlzFrameGetText(func.frame)

            text = string.gsub(text, "('.-')", function()
                return "'" .. key_string .. "'"
            end)

            if GetLocalPlayer() == Player(pid - 1) then
                BlzFrameSetText(func.frame, text)
            end
        end
    end

    local function register_key_binding(pid, key_string, action)
        if not key_bindings[pid] then
            key_bindings[pid] = {}
        end
        if not key_bindings[pid][key_string] then
            key_bindings[pid][key_string] = {}
        end
        table.insert(key_bindings[pid][key_string], action)
        update_action_tooltip(pid, key_string, action)
    end

    local function unregister_key_binding(pid, key_string, action)
        if key_bindings[pid] and key_bindings[pid][key_string] then
            for i, bound_action in ipairs(key_bindings[pid][key_string]) do
                if bound_action == action then
                    table.remove(key_bindings[pid][key_string], i)
                    break
                end
            end
        end
    end

    local function select_delay()
        local u = GetMainSelectedUnit()
        BlzFrameSetVisible(HIDE_HEALTH_FRAME, (u and Unit[u] and Unit[u].hidehp))
        BlzFrameSetVisible(PUNCHING_BAG_UI, u == PUNCHING_BAG)
    end

    local function update_ui()
        TimerQueue:callDelayed(0., select_delay)
    end

    local function on_rebind()
        local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local dw    = DialogWindow[pid] ---@type DialogWindow 
        local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

        if index ~= -1 then
            local key = dw.data[index]
            DisplayTextToPlayer(Player(pid - 1), 0, 0, "Press a key to rebind " .. hotkey_functions[index + 1].name)
            changing_keybinds[pid] = {key = key, func = hotkey_functions[index + 1].func}

            dw:destroy()
        end

        return false
    end

    local function open_hotkey_dialog(pid)
        if DialogWindow[pid] then
            return
        end

        local dw = DialogWindow.create(pid, "Re-assign hotkeys", on_rebind)

        for _, v in ipairs(hotkey_functions) do
            local key = get_key_for_function(pid, v.func)
            dw:addButton("|cffffffff" .. v.name .. ": " .. (key or "") .. "|r", key)
        end

        dw:display()
    end

    local function open_inventory(pid, is_down)
        if is_down then
            INVENTORY.display(pid)
        end
    end

    local function open_stats(pid, is_down)
        if is_down then
            if BlzFrameIsVisible(STAT_WINDOW.frame) then
                STAT_WINDOW.close(pid)
            else
                DisplayStatWindow(Hero[pid], pid)
            end
        end
    end

    local function extended_spell_tooltip(pid, is_down)
        if IS_ALT_DOWN[pid] ~= is_down then
            IS_ALT_DOWN[pid] = is_down
            UpdateSpellTooltips(pid)
            UpdateItemTooltips(pid)
        end
    end

    local function toggle_auto_attack(pid, is_down)
        if is_down then
            ToggleAutoAttack(pid)
        end
    end

    local function next_multiboard(pid, is_down)
        if is_down then
            MULTIBOARD.next(pid)
        end
    end

    local function minimize_multiboard(pid, is_down)
        if is_down then
            MULTIBOARD.minimize(pid)
        end
    end

    local function clear_text(pid, is_down)
        if is_down then
            if Player(pid - 1) == GetLocalPlayer() then
                ClearTextMessages()
            end
        end
    end

    local function close_all_windows(pid, is_down)
        if is_down then
            Shop.onEsc(pid)
            STAT_WINDOW.close(pid)
            INVENTORY.close(pid)
        end
    end

    local function second_spell_special_cast(pid, is_down)
        if is_down then
            -- shatter frozen orb early
            local missile = FROZENORB.missile[pid] ---@type Missiles

            if missile then
                missile:onFinish()
                missile:terminate()
            end

            -- cancel hidden guise early
            local pt = TimerList[pid]:get(HIDDENGUISE.id)

            if pt then
                HIDDENGUISE.expire(pt)
            end
        end
    end

    local key_mapper = {
        [0x08] = 'BACKSPACE',
        [0x1B] = 'ESC',
        [0xBC] = ',',
        [0xBE] = '.',
        [0xBF] = '/',
        [0xBA] = ';',
        [0xDE] = '\'',
        [0xDB] = '[',
        [0xDD] = ']',
        [0xBD] = '-',
        [0xBB] = '=',
        [0x70] = 'F1',
        [0x71] = 'F2',
        [0x72] = 'F3',
        [0x73] = 'F4',
        [0x75] = 'F6',
        [0x76] = 'F7',
        [0x77] = 'F8',
    }

    local meta_keys = {
        [0xA0] = 'SHIFT',
        [0xA2] = 'CTRL',
        [0xA4] = 'ALT',
    }

    local meta_shift = 1 << 0
    local meta_ctrl = 1 << 1
    local meta_alt = 1 << 2

    local function on_key_input()
        local key = GetHandleId(BlzGetTriggerPlayerKey())
        local meta = BlzGetTriggerPlayerMetaKey()
        local is_down = BlzGetTriggerPlayerIsKeyDown()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer
        local to_char = string.char(key)
        local key_string = key_mapper[key] or meta_keys[key] or to_char
        local invalid_char = not key_mapper[key] and (key < 0x30 or key > 0x77)

        if 0 ~= meta & meta_shift then
            key_string = "SHIFT+" .. key_string
        elseif 0 ~= meta & meta_ctrl then
            key_string = "CTRL+" .. key_string
        elseif 0 ~= meta & meta_alt then
            key_string = "ALT+" .. key_string
        end

        -- prevent multiple triggers
        if not meta_keys[key] and update_state(pid, key_string, is_down) then
            return
        end

        if changing_keybinds[pid] and not meta_keys[key] then -- prevent binding to only meta keys
            if invalid_char then
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Invalid character!")
            else
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Successfully rebound to \'" .. key_string .. "\'")
                unregister_key_binding(pid, changing_keybinds[pid].key, changing_keybinds[pid].func)
                register_key_binding(pid, key_string, changing_keybinds[pid].func)
            end
            changing_keybinds[pid] = nil
            return false
        end

        -- Check for a binding and execute the bound function if it exists
        local bound_functions = key_bindings[pid] and key_bindings[pid][key_string]
        if bound_functions then
            for _, key_function in ipairs(bound_functions) do
                key_function(pid, is_down)
            end
        end

        return false
    end

    hotkey_functions = {
        {
            name = "Close Windows",
            func = close_all_windows,
        },
        {
            name = "Clear Text",
            func = clear_text,
        },
        {
            name = "Toggle Auto Attack",
            func = toggle_auto_attack,
        },
        {
            name = "View Inventory",
            func = open_inventory,
        },
        {
            name = "View Stats",
            func = open_stats,
        },
        {
            name = "Next Multiboard",
            func = next_multiboard,
        },
        {
            name = "Minimize Multiboard",
            func = minimize_multiboard,
        },
        {
            name = "Spell 2 Second Cast",
            func = second_spell_special_cast,
        },
    }

    function ChangeHotkeys(pid)
        open_hotkey_dialog(pid)
    end

    -- associates an external frame with a hotkey action
    function RegisterHotkeyTooltip(table, index)
        local frame = table.tooltip

        while type(frame) == "table" do
            frame = frame.tooltip
        end

        hotkey_functions[index].frame = frame
    end

    local t = CreateTrigger()
    TriggerAddCondition(t, Condition(on_key_input))

    local U = User.first

    while U do
        -- Default keybindings
        register_key_binding(U.id, 'ALT', extended_spell_tooltip)
        register_key_binding(U.id, 'ALT+ALT', extended_spell_tooltip)
        register_key_binding(U.id, 'I', open_inventory)
        register_key_binding(U.id, 'B', open_stats)
        register_key_binding(U.id, '/', next_multiboard)
        register_key_binding(U.id, '.', minimize_multiboard)
        register_key_binding(U.id, 'ESC', close_all_windows)
        register_key_binding(U.id, 'ESC', clear_text)
        register_key_binding(U.id, 'W', second_spell_special_cast)
        register_key_binding(U.id, 'CTRL+A', toggle_auto_attack)
        for i = 0, 9 do
            register_key_binding(U.id, tostring(i), update_ui)
        end
        register_key_binding(U.id, 'F1', update_ui)
        register_key_binding(U.id, 'F2', update_ui)
        register_key_binding(U.id, 'F3', update_ui)
        register_key_binding(U.id, 'F4', update_ui)

        for k = 0x00, 0xFF do
            local key = ConvertOsKeyType(k)
            for meta = 0, 15 do
                BlzTriggerRegisterPlayerKeyEvent(t, U.player, key, meta, true)
                BlzTriggerRegisterPlayerKeyEvent(t, U.player, key, meta, false)
            end
        end
        U = U.next
    end
end, Debug and Debug.getLine())
