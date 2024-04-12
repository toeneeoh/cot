OnInit.final("Mouse", function(Require)
    Require('Users')
    Require('Variables')

    rightclickmovement = {} ---@type boolean[]
    rightclickdown     = {} ---@type boolean[]
    well               = {} ---@type unit[] 
    wellcount          = 0 ---@type integer 
    wellheal           = __jarray(0) ---@type integer[] 
    MouseX             = __jarray(0) ---@type number[] 
    MouseY             = __jarray(0) ---@type number[] 
    moveCounter        = __jarray(0) ---@type integer[] 
    panCounter         = __jarray(0) ---@type integer[] 
    clickCounter       = __jarray(0) ---@type integer[] 
    PlayerSelectedUnit = {} ---@type unit[] 

---@type fun(pid: integer)
function UnselectBP(pid)
    local p        = Player(pid - 1) ---@type player 

    if IsUnitSelected(Hero[pid], p) and IsUnitSelected(Backpack[pid], p) then
        if GetLocalPlayer() == p then
            SelectUnit(Backpack[pid], false)
        end
    end
end

---@return boolean
function MouseUp()
    local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local x   = BlzGetTriggerPlayerMouseX() ---@type number 
    local x2 ---@type number 
    local y   = BlzGetTriggerPlayerMouseY() ---@type number 
    local y2 ---@type number 
    local heal ---@type number 

    if BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_LEFT then
        if BP_DESELECT[pid] then
            TimerQueue:callDelayed(0., UnselectBP, pid)
        end
    end

    if BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_RIGHT then
        --Health / Mana Wells
        for i = 1, wellcount do
            x2 = GetUnitX(well[i])
            y2 = GetUnitY(well[i])
            if SquareRoot(Pow(x2 - x, 2) + Pow(y2 - y, 2)) < 110 and SquareRoot(Pow(x2 - GetUnitX(Hero[pid]), 2) + Pow(y2 - GetUnitY(Hero[pid]), 2)) < 250 then
                if wellheal[i] < 100 then --hp
                    heal = BlzGetUnitMaxHP(Hero[pid]) * wellheal[i] // 100
                    HP(well[i], Hero[pid], heal)
                else
                    heal = GetUnitState(Hero[pid], UNIT_STATE_MAX_MANA) * (wellheal[i] - 100) // 100
                    MP(Hero[pid], heal)
                end
                Fade(well[i], 1., true)
                TimerQueue:callDelayed(5, RemoveUnit, well[i])
                IndexWells(i)
                break
            end
        end

        rightclickdown[pid] = false
    end

    return false
end

---@return boolean
function MouseDown()
    local p   = GetTriggerPlayer() ---@type player 
    local pid = GetPlayerId(p) + 1 ---@type integer 

    clickCounter[pid] = clickCounter[pid] + 1

    --backpack ai
    if PlayerSelectedUnit[pid] == Backpack[pid] then
        bpmoving[pid] = true
        local pt = TimerList[pid]:get('bkpk', Backpack[pid])

        if not pt then
            pt = TimerList[pid]:add()
            pt.dur = 4.
            pt.tag = 'bkpk'
            pt.source = Backpack[pid]

            TimerQueue:callDelayed(1., MoveExpire, pt)
        else
            pt.dur = 4.
        end
    end

    if BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_RIGHT then
        rightclickdown[pid] = true
    end

    return false
end

---@return boolean
function MoveMouse()
    local p   = GetTriggerPlayer() ---@type player 
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

        if rightclickmovement[pid] and rightclickdown[pid] and IsUnitSelected(Hero[pid], p) then
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
function Select()
    local u   = GetTriggerUnit()
    local p   = GetTriggerPlayer() ---@type player 
    local pid = GetPlayerId(p) + 1 ---@type integer 

    PlayerSelectedUnit[pid] = u

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
end, Debug.getLine())
