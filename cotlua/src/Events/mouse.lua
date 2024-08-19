OnInit.final("Mouse", function(Require)
    Require('Users')
    Require('Variables')

    IS_M2_MOVEMENT     = {} ---@type boolean[]
    IS_M1_DOWN         = {} ---@type boolean[]
    IS_M2_DOWN         = {} ---@type boolean[]
    MouseX             = __jarray(0) ---@type number[] 
    MouseY             = __jarray(0) ---@type number[] 
    moveCounter        = __jarray(0) ---@type integer[] 
    panCounter         = __jarray(0) ---@type integer[] 
    clickCounter       = __jarray(0) ---@type integer[] 
    PlayerSelectedUnit = {} ---@type unit[] 

    ---@type fun(pid: integer)
    local function UnselectBP(pid)
        local p = Player(pid - 1)

        if IsUnitSelected(Hero[pid], p) and IsUnitSelected(Backpack[pid], p) then
            if GetLocalPlayer() == p then
                SelectUnit(Backpack[pid], false)
            end
        end
    end

    ---@return boolean
    local function MouseUp()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local mouse = BlzGetTriggerPlayerMouseButton()

        if mouse == MOUSE_BUTTON_TYPE_LEFT then
            if BP_DESELECT[pid] then
                TimerQueue:callDelayed(0., UnselectBP, pid)
            end

            IS_M1_DOWN[pid] = false
        elseif mouse == MOUSE_BUTTON_TYPE_RIGHT then
            IS_M2_DOWN[pid] = false
        end

        return false
    end

    ---@return boolean
    local function MouseDown()
        local p   = GetTriggerPlayer()
        local pid = GetPlayerId(p) + 1 ---@type integer 
        local mouse = BlzGetTriggerPlayerMouseButton()

        clickCounter[pid] = clickCounter[pid] + 1

        if mouse == MOUSE_BUTTON_TYPE_RIGHT then
            IS_M2_DOWN[pid] = true
        elseif mouse == MOUSE_BUTTON_TYPE_LEFT then
            IS_M1_DOWN[pid] = true
        end

        return false
    end

    ---@return boolean
    local function MoveMouse()
        local p   = GetTriggerPlayer()
        local pid = GetPlayerId(p) + 1 ---@type integer 
        local x   = BlzGetTriggerPlayerMouseX() ---@type number 
        local y   = BlzGetTriggerPlayerMouseY() ---@type number 

        if x == 0 and y == 0 then
            return false
        end

        if HeroID[pid] > 0 then
            local dist = DistanceCoords(x, y, MouseX[pid], MouseY[pid])

            if dist < 100 then
                moveCounter[pid] = moveCounter[pid] + 1
            elseif dist > 1000 then
                panCounter[pid] = panCounter[pid] + 1
            end

            if IS_M2_MOVEMENT[pid] and IS_M2_DOWN[pid] and IsUnitSelected(Hero[pid], p) then
                if dist >= 3 then
                    local ug = CreateGroup()
                    GroupEnumUnitsInRange(ug, x, y, 15.0, Condition(ishostile))

                    local target = FirstOfGroup(ug)
                    if target == nil then
                        IssuePointOrder(Hero[pid], "smart", x, y)
                    elseif GetUnitCurrentOrder(Hero[pid]) ~= OrderId("attack") then
                        IssueTargetOrder(Hero[pid], "attack", target)
                    end

                    DestroyGroup(ug)
                end
            end
        end

        MouseX[pid] = x
        MouseY[pid] = y

        return false
    end

    ---@return boolean
    local function Select()
        local u   = GetTriggerUnit()
        local p   = GetTriggerPlayer()
        local pid = GetPlayerId(p) + 1 ---@type integer 

        PlayerSelectedUnit[pid] = u
        EVENT_ON_CLICK:trigger(u, pid)

        return false
    end

    local click     = CreateTrigger()
    local move      = CreateTrigger()
    local mousedown = CreateTrigger()
    local mouseup   = CreateTrigger()
    local u         = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(click, u.player, EVENT_PLAYER_UNIT_SELECTED, nil)
        TriggerRegisterPlayerEvent(move, u.player, EVENT_PLAYER_MOUSE_MOVE)
        TriggerRegisterPlayerEvent(mousedown, u.player, EVENT_PLAYER_MOUSE_DOWN)
        TriggerRegisterPlayerEvent(mouseup, u.player, EVENT_PLAYER_MOUSE_UP)
        u = u.next
    end

    TriggerAddCondition(click, Filter(Select))
    TriggerAddCondition(move, Filter(MoveMouse))
    TriggerAddCondition(mousedown, Filter(MouseDown))
    TriggerAddCondition(mouseup, Filter(MouseUp))
end, Debug and Debug.getLine())
