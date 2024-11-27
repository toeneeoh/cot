OnInit.final("Inventory", function(Require)
    Require('Users')
    Require('Frames')

    local INVENTORY_WIDTH   = 0.1981
    local INVENTORY_GAPY    = 0.0312
    local INVENTORY_GAPX    = 0.0333
    local INVENTORY_TEXTURE = "inventory_row.tga"
    local min_x     = 0.612
    local min_y     = 0.214
    local icon_size = 0.0266
    local FPS_32    = FPS_32

    local inventory_slots = {
        {0.0000, 0.1248},
        {0.0333, 0.1248},
        {0.0666, 0.1248},
        {0.0999, 0.1248},
        {0.1332, 0.1248},
        {0.1665, 0.1248},
        {0.0000, 0.0624},
        {0.0333, 0.0624},
        {0.0666, 0.0624},
        {0.0999, 0.0624},
        {0.1332, 0.0624},
        {0.1665, 0.0624},
        {0.0000, 0.0312},
        {0.0333, 0.0312},
        {0.0666, 0.0312},
        {0.0999, 0.0312},
        {0.1332, 0.0312},
        {0.1665, 0.0312},
        {0.0000, 0.0},
        {0.0333, 0.0},
        {0.0666, 0.0},
        {0.0999, 0.0},
        {0.1332, 0.0},
        {0.1665, 0.0},
    }

    INVENTORY = {}
    do
        local thistype = INVENTORY
        local context, selected, slots = {}, {}, {} ---@type Button[]
        local is_inventory_open, move_item_cooldown = {}, {}
        local on_m1_down, on_m2_down, on_m1_up, on_m2_up, open_context_menu

        -- determines what item slot a user has their cursor over
        ---@return number, Button?
        local get_hovered_slot = function()
            local mouse_x = GetMouseFrameXStable() - min_x
            local mouse_y = GetMouseFrameYStable() - min_y
            local closest_slot = 0
            local closest_distance = 1000

            -- Loop through each slot's position and calculate the distance to the mouse
            for i, pos in ipairs(inventory_slots) do
                local dx = mouse_x - pos[1]
                local dy = mouse_y - pos[2]
                local distance = math.sqrt(dx * dx + dy * dy)  -- Euclidean distance

                -- Check if this slot is the closest
                if distance < closest_distance then
                    closest_distance = distance
                    closest_slot = i
                end
            end

            -- Define a threshold distance to ensure the mouse is reasonably close to a slot
            local threshold_distance = 0.025

            if closest_distance > threshold_distance then
                return mouse_x, nil  -- Mouse is too far from any slot
            end

            return mouse_x, slots[closest_slot] -- Return the closest slot
        end

        -- frame setup
        local frame = BlzCreateFrame("ListBoxWar3", BlzGetFrameByName("ConsoleUIBackdrop", 0), 0, 0)
        BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, 0.575, 0.41)
        BlzFrameSetSize(frame, INVENTORY_WIDTH + 0.04, 0.232)
        BlzFrameSetEnable(frame, false)

        local title = BlzCreateFrame("TitleText", frame, 0, 0)
        BlzFrameSetPoint(title, FRAMEPOINT_TOP, frame, FRAMEPOINT_TOP, 0., -0.013)
        BlzFrameSetEnable(title, false)
        BlzFrameSetText(title, "Inventory")

        local inv = {}
        local inv_main = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
        BlzFrameSetPoint(inv_main, FRAMEPOINT_TOPLEFT, frame, FRAMEPOINT_TOPLEFT, 0.02, -0.06)
        BlzFrameSetSize(inv_main, INVENTORY_WIDTH, INVENTORY_GAPY)
        BlzFrameSetTexture(inv_main, INVENTORY_TEXTURE, 0, false)
        BlzFrameSetEnable(inv_main, true)
        inv[0] = inv_main

        for i = 1, 3 do
            inv[i] = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
            BlzFrameSetPoint(inv[i], FRAMEPOINT_TOPLEFT, inv[i - 1], FRAMEPOINT_BOTTOMLEFT, 0., (i == 1 and -icon_size) or 0.)
            BlzFrameSetSize(inv[i], INVENTORY_WIDTH, INVENTORY_GAPY)
            BlzFrameSetTexture(inv[i], INVENTORY_TEXTURE, 0, false)
            BlzFrameSetEnable(inv[i], true)
        end

        BlzFrameSetVisible(frame, false)

        -- context menu setup
        local context_menu_backdrop = BlzCreateFrameByType("FRAME", "", frame, "", 0)
        BlzFrameSetTexture(context_menu_backdrop, "trans32.blp", 0, true)
        BlzFrameSetSize(context_menu_backdrop, 0.001, 0.001)
        BlzFrameSetEnable(context_menu_backdrop, false)
        BlzFrameSetVisible(context_menu_backdrop, false)
        local context_buttons = {}
        for i = 1, 5 do
            context_buttons[i] = SimpleButton.create(context_menu_backdrop, "inventorymenubuttons.dds", 0.055, 0.016, FRAMEPOINT_TOPLEFT, FRAMEPOINT_TOPLEFT, 0, (i - 1) * -0.016)
        end
        local context_functions = {
            ["Equip"] = function(pid)

            end,
            ["Unequip"] = function(pid) end,
            ["Drop"] = function(pid)
                if context[pid] then
                    local itm = Profile[pid].hero.items[context[pid].index]
                    itm:drop(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))
                    INVENTORY.refresh(pid)
                    open_context_menu(pid, true)
                end
            end,
            ["Sell"] = function(pid) end,
        }
        local on_context_push = function()
            local p = GetTriggerPlayer()
            local pid = GetPlayerId(p) + 1
            local f = BlzGetTriggerFrame()

            BlzFrameSetEnable(f, false)
            BlzFrameSetEnable(f, true)

            for i = 1, 5 do
                local button = context_buttons[i]

                if button.frame == f then
                    local text = BlzFrameGetText(f)
                    context_functions[text](pid)
                    break
                end
            end

            return false
        end

        for i = 1, 5 do
            context_buttons[i]:onClick(on_context_push)
        end

        local setabspoint = BlzFrameSetAbsPoint

        -- frame that follows the mouse (for item dragging)
        local tracker = BlzCreateFrameByType("BACKDROP", "", BlzGetFrameByName("ConsoleUIBackdrop", 0), "", 0)
        BlzFrameSetEnable(tracker, false)
        BlzFrameSetSize(tracker, icon_size, icon_size)
        BlzFrameSetTexture(tracker, "trans32.blp", 0, true)
        BlzFrameSetLevel(tracker, 5)

        local count = 0
        local check_tracker = function()
            return count == 0
        end
        local update_tracker = function()
            setabspoint(tracker, FRAMEPOINT_CENTER, GetMouseFrameXStable(), GetMouseFrameYStable())
        end
        local hide_tracker = function(pid)
            if GetLocalPlayer() == Player(pid - 1) then
                BlzFrameSetTexture(tracker, "trans32.blp", 0, true)
            end
        end

        thistype.open = function(pid)
            if GetLocalPlayer() == Player(pid - 1) then
                BlzFrameSetVisible(frame, true)
            end
            is_inventory_open[pid] = true
            EVENT_ON_M1_DOWN:register_action(pid, on_m1_down)
            EVENT_ON_M1_UP:register_action(pid, on_m1_up)
            EVENT_ON_M2_DOWN:register_action(pid, on_m2_down)
            EVENT_ON_M2_UP:register_action(pid, on_m2_up)
            thistype.refresh(pid)

            count = count + 1
            if count == 1 then
                TimerQueue:callPeriodically(FPS_32, check_tracker, update_tracker)
            end
        end

        thistype.close = function(pid)
            if is_inventory_open[pid] then
                if GetLocalPlayer() == Player(pid - 1) then
                    BlzFrameSetVisible(frame, false)
                end
                is_inventory_open[pid] = false
                EVENT_ON_M1_DOWN:unregister_action(pid, on_m1_down)
                EVENT_ON_M1_UP:unregister_action(pid, on_m1_up)
                EVENT_ON_M2_DOWN:unregister_action(pid, on_m2_down)
                EVENT_ON_M2_UP:unregister_action(pid, on_m2_up)

                count = count - 1
                selected[pid] = nil
                hide_tracker(pid)
                PauseMouseTracker(pid)
            end
        end

        thistype.display = function(pid)
            if Profile[pid].playing then
                if is_inventory_open[pid] then
                    thistype.close(pid)
                else
                    thistype.open(pid)
                end
            end
        end

        thistype.refresh = function(pid)
            for i = 1, MAX_INVENTORY_SLOTS do
                local itm = Profile[pid].hero.items[i]

                if itm then
                    if GetLocalPlayer() == Player(pid - 1) then
                        slots[i]:icon(BlzGetItemIconPath(itm.obj))
                        slots[i].tooltip:icon(BlzGetItemIconPath(itm.obj))
                        slots[i].tooltip:name(GetItemName(itm.obj))
                        slots[i].tooltip:text(BlzGetItemExtendedTooltip(itm.obj))
                        slots[i].tooltip:text(BlzGetItemExtendedTooltip(itm.obj))
                        slots[i]:visible(true)
                    end
                else
                    if GetLocalPlayer() == Player(pid - 1) then
                        slots[i]:visible(false)
                    end
                end
            end
        end

        local onClose = function()
            local f = BlzGetTriggerFrame()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            if GetLocalPlayer() == Player(pid - 1) then
                BlzFrameSetEnable(f, false)
                BlzFrameSetEnable(f, true)
            end

            thistype.close(pid)

            return false
        end

        -- escape button
        local esc_button = SimpleButton.create(frame, "ReplaceableTextures\\CommandButtons\\BTNCancel.blp", 0.015, 0.015, FRAMEPOINT_TOPRIGHT, FRAMEPOINT_TOPRIGHT, -0.02, -0.02, onClose, "Close 'I'", FRAMEPOINT_BOTTOM, FRAMEPOINT_TOP, 0., 0.01)
        RegisterHotkeyTooltip(esc_button, 4)

        -- determines what item slot a user is highlighting
        ---@return Button?
        local get_highlighted_slot = function()
            for i = 1, MAX_INVENTORY_SLOTS do
                if BlzFrameIsVisible(slots[i].tooltip.iconFrame) then
                    return slots[i]
                end
            end

            return nil
        end

        local pick_item = function(pid)
            local new_slot = get_highlighted_slot()

            if new_slot then
                if GetLocalPlayer() == Player(pid - 1) then
                    new_slot:visible(false)
                    BlzFrameSetTexture(tracker, new_slot.texture, 0, true)
                end

                local xPos = min_x - 0.4 + inventory_slots[new_slot.index][1]
                local yPos = min_y - 0.3 + inventory_slots[new_slot.index][2]
                StartMouseTracker(pid, xPos, yPos)
                selected[pid] = new_slot
            end
        end

        local reset_cooldown = function(pid)
            move_item_cooldown[pid] = false
        end

        local function update_context_buttons(pid, slot)
            local names = {
                "Equip",
                "Drop",
            }

            if slot.index <= 6 then
                names[1] = "Unequip"
            end

            if RectContainsUnit(gg_rct_Town_Main, Hero[pid]) then
                names[3] = "Sell"
            end

            for i, v in ipairs(context_buttons) do
                if GetLocalPlayer() == Player(pid - 1) then
                    if names[i] then
                        v:text(names[i])
                        v:visible(true)
                    else
                        v:visible(false)
                    end
                end
            end
        end

        open_context_menu = function(pid, close)
            local new_slot = get_highlighted_slot()

            -- open the menu
            if new_slot and not close then
                local visible = not BlzFrameIsVisible(context_menu_backdrop)
                update_context_buttons(pid, new_slot)

                if GetLocalPlayer() == Player(pid - 1) then
                    BlzFrameSetVisible(context_menu_backdrop, visible)
                    BlzFrameClearAllPoints(context_menu_backdrop)
                    BlzFrameSetPoint(context_menu_backdrop, FRAMEPOINT_TOPLEFT, new_slot.frame, FRAMEPOINT_TOPRIGHT, 0.005, 0.)
                    for _, v in ipairs(slots) do
                        v.tooltip:visible(not visible)
                    end
                end
                context[pid] = new_slot
            else
                if GetLocalPlayer() == Player(pid - 1) then
                    BlzFrameSetVisible(context_menu_backdrop, false)
                    for _, v in ipairs(slots) do
                        v.tooltip:visible(true)
                    end
                end
                context[pid] = nil
            end
        end

        local confirm_item = function(pid)
            if not selected[pid] then
                return
            end

            local highlighted_slot = get_highlighted_slot()
            local mouse_x, hovered_slot = get_hovered_slot()
            local new_slot = highlighted_slot or hovered_slot or selected[pid]

            local prev_show, new_show = false, false
            local prev_texture, new_texture = selected[pid].texture, new_slot.texture

            local items = Profile[pid].hero.items
            local itm1, itm2 = items[selected[pid].index], items[new_slot.index]

            -- drop item if dragged to the left of inventory
            if mouse_x < -0.025 then
                Profile[pid].hero.item_to_drop = selected[pid]
                -- cast the drop item spell
                IssuePointOrder(Hero[pid], "robogoblin", GetMouseX(pid), GetMouseY(pid))
            else
                -- if move is successful
                if itm1:equip(new_slot.index) then
                    if itm2 and itm1 ~= itm2 then -- if another item is there
                        itm2:equip(selected[pid].index)
                        prev_show = true
                    end
                    prev_texture, new_texture = new_slot.texture, prev_texture
                    new_show = true
                else
                    prev_show = true
                end
            end

            if GetLocalPlayer() == Player(pid - 1) then
                selected[pid]:icon(prev_texture)
                selected[pid]:visible(prev_show)
                new_slot:icon(new_texture)
                new_slot:visible(new_show)
            end

            hide_tracker(pid)
            PauseMouseTracker(pid)

            selected[pid] = nil
            thistype.refresh(pid)

            move_item_cooldown[pid] = true
            TimerQueue:callDelayed(0.2, reset_cooldown, pid)
        end

        -- mouse events
        on_m2_up = function()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            open_context_menu(pid)
        end

        on_m2_down = function()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1
        end
        on_m1_down = function()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            if not move_item_cooldown[pid] then
                pick_item(pid)
            end
        end

        on_m1_up = function()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            confirm_item(pid)
        end

        -- initialize inventory slot buttons
        for i = 1, MAX_INVENTORY_SLOTS do
            local x = math.fmod(i - 1, 6)
            local y = (i - 1) // 6
            slots[i] = Button.create(inv[y], icon_size, icon_size, 0.0032 + INVENTORY_GAPX * x, -0.0033, false)
            slots[i]:visible(false)
            slots[i].index = i
            if x > 2 then
                slots[i].tooltip:point(FRAMEPOINT_TOPRIGHT)
            end
        end
    end
end, Debug and Debug.getLine())
