library Mouse requires Functions

globals
    force rightclickactivator = CreateForce()
    force rightclicked = CreateForce()
    real array clickedpointX
    real array clickedpointY
    unit array well
    integer wellcount = 0
    integer array wellheal
    real array MouseX
    real array MouseY
    integer array moveCounter
    integer array panCounter
    unit array PlayerSelectedUnit
endglobals

function UnselectBP takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    local player p = Player(pid - 1)

    if IsUnitSelected(Hero[pid], p) and IsUnitSelected(Backpack[pid], p) then
        if GetLocalPlayer() == p then
            call SelectUnit(Backpack[pid], false)
        endif
    endif
    
    set p = null
endfunction

function RightClickUp takes nothing returns nothing
    local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
    local integer i = 1
    local real x = BlzGetTriggerPlayerMouseX()
    local real x2
    local real y = BlzGetTriggerPlayerMouseY()
    local real y2
    local real heal

    if BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_LEFT then
        if BP_DESELECT[pid] then
            call TimerStart(NewTimerEx(pid), 0.01, false, function UnselectBP)
        endif

        if hselection[pid] then
            if GetLocalPlayer() == GetTriggerPlayer() then
                call ClearSelection()
                call SelectUnit(hsdummy[pid], true)
            endif
        endif
    endif

    if BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_RIGHT then
        loop //Health / Mana Wells
            exitwhen i > wellcount
            set x2 = GetUnitX(well[i])
            set y2 = GetUnitY(well[i])
            if SquareRoot(Pow(x2 - x, 2) + Pow(y2 - y, 2)) < 110 and SquareRoot(Pow(x2 - GetUnitX(Hero[pid]), 2) + Pow(y2 - GetUnitY(Hero[pid]), 2)) < 250 then
                if wellheal[i] < 100 then //hp
                    set heal = BlzGetUnitMaxHP(Hero[pid]) * wellheal[i] / 100
                    call HP(Hero[pid], heal)
                else
                    set heal = GetUnitState(Hero[pid], UNIT_STATE_MAX_MANA) * (wellheal[i] - 100) / 100
                    call MP(Hero[pid], heal)
                endif
                call Fade(well[i], 35, 0.03, 1)
                call RemoveUnitTimed(well[i], 5)
                call IndexWells(i)
                exitwhen true
            endif
            set i = i + 1
        endloop
    
        call ForceRemovePlayer(rightclicked, GetTriggerPlayer())
    endif
endfunction

function RightClickDown takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p) + 1
    
    if BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_RIGHT then   
        //backpack ai
    
        if PlayerSelectedUnit[pid] == Backpack[pid] and bpmoving[pid] == false then
            set bpmoving[pid] = true
            call SaveInteger(MiscHash, 0, GetHandleId(bpmove[pid]), pid)
            call PauseTimer(bpmove[pid])
            call TimerStart(bpmove[pid], 4., true, function MoveExpire)
        endif
    
        call ForceAddPlayer(rightclicked, p)
    endif
endfunction

function MoveMouse takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p) + 1
    local real x = BlzGetTriggerPlayerMouseX()
    local real y = BlzGetTriggerPlayerMouseY()
    local real dist = SquareRoot(Pow(MouseX[pid] - x, 2) + Pow(MouseY[pid] - y, 2))
    local group ug
    local unit target

    if x == 0 and y == 0 then
    elseif dist < 50 then
        set moveCounter[pid] = moveCounter[pid] + 1
    elseif dist > 2000 then
        set panCounter[pid] = panCounter[pid] + 1
    endif
    
    if HeroID[pid] > 0 then
        if IsPlayerInForce(p, rightclickactivator) and IsPlayerInForce(p, rightclicked) and IsUnitSelected(Hero[pid], p) then
            if x == 0 and y == 0 then
            elseif dist < 3 then
            else
                set ug = CreateGroup()
                call GroupEnumUnitsInRange(ug, x, y, 15.0, Condition(function ishostile))
                set target = FirstOfGroup(ug)
                if target == null then
                    call IssuePointOrder(Hero[pid], "smart", x, y)
                elseif GetUnitCurrentOrder(Hero[pid]) != OrderId("attack") then
                    call IssueTargetOrder(Hero[pid], "attack", target)
                endif
                call DestroyGroup(ug)
            endif
        endif
    endif
    
    set MouseX[pid] = x
    set MouseY[pid] = y
    
    set p = null
    set ug = null
    set target = null
endfunction

function Select takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p) + 1
    
    set PlayerSelectedUnit[pid] = GetTriggerUnit()

    set p = null
endfunction

function MouseInit takes nothing returns nothing
    local trigger click = CreateTrigger()
    local trigger move = CreateTrigger()
    local trigger rightclickdown = CreateTrigger()
    local trigger rightclickup = CreateTrigger()
    local User u = User.first
    
    loop
        exitwhen u == User.NULL
        call TriggerRegisterPlayerUnitEvent(click, u.toPlayer(), EVENT_PLAYER_UNIT_SELECTED, null)
        call TriggerRegisterPlayerEvent(move, u.toPlayer(), EVENT_PLAYER_MOUSE_MOVE)
        call TriggerRegisterPlayerEvent(rightclickdown, u.toPlayer(), EVENT_PLAYER_MOUSE_DOWN)
        call TriggerRegisterPlayerEvent(rightclickup, u.toPlayer(), EVENT_PLAYER_MOUSE_UP)
        set u = u.next
    endloop
    
    call TriggerAddAction(click, function Select)
    call TriggerAddAction(move, function MoveMouse)
    call TriggerAddAction(rightclickdown, function RightClickDown)
    call TriggerAddAction(rightclickup, function RightClickUp)
    
    set click = null
    set move = null
    set rightclickdown = null
    set rightclickup = null
endfunction

endlibrary
