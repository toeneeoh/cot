library Dungeons requires Functions
    globals
        integer QUEUE_DUNGEON = 0
        force QUEUE_GROUP = CreateForce()
        real QUEUE_X = 0.
        real QUEUE_Y = 0.
        integer QUEUE_LEVEL = 0
        multiboard QUEUE_BOARD
        boolean array QUEUE_READY
        
        force NAGA_GROUP = CreateForce()
        integer NAGA_PLAYERS = 0
        integer NAGA_FLOOR = 0
        timer NAGA_TIMER = CreateTimer()
        timerdialog NAGA_TIMER_DISPLAY = CreateTimerDialog(NAGA_TIMER)
        group NAGA_ENEMIES = CreateGroup()
        unit nagatp
        unit nagachest
        unit nagaboss
        boolean nagawaterstrikecd = false
        boolean timerflag = false
    endglobals
    
    function DungeonCreateUnit takes integer id, real x, real y, real facing, integer dmgr, group g returns unit
        set bj_lastCreatedUnit = CreateUnit(pfoe, id, x, y, facing)
        call GroupAddUnit(g, bj_lastCreatedUnit)
        call SaveInteger(MiscHash, GetHandleId(bj_lastCreatedUnit), 'dmgr', dmgr)
        return bj_lastCreatedUnit
    endfunction
    
    function DungeonMoveExpire takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local force f = LoadForceHandle(MiscHash, GetHandleId(t), 0)
        local rect cam = LoadRectHandle(MiscHash, GetHandleId(t), 1)
        local real x = LoadReal(MiscHash, GetHandleId(t), 2)
        local real y = LoadReal(MiscHash, GetHandleId(t), 3)
        local integer pid
        local User U = User.first

        loop
            exitwhen U == User.NULL
            set pid = GetPlayerId(U.toPlayer()) + 1
            
            if IsPlayerInForce(U.toPlayer(), f) then
                call ShowUnit(HeroGrave[pid], true)
                call SetUnitPosition(HeroGrave[pid], x, y)
                call ShowUnit(HeroGrave[pid], false)
                call SetUnitXBounded(Hero[pid], x)
                call SetUnitYBounded(Hero[pid], y)
                call SetCameraBoundsRectForPlayerEx(U.toPlayer(), cam)
                call PanCameraToTimedForPlayer(U.toPlayer(), x, y, 0)
            endif
            
            set U = U.next
        endloop

        call RemoveSavedHandle(MiscHash, GetHandleId(t), 0)
        call RemoveSavedHandle(MiscHash, GetHandleId(t), 1)
        call RemoveSavedReal(MiscHash, GetHandleId(t), 2)
        call RemoveSavedReal(MiscHash, GetHandleId(t), 3)
        call ReleaseTimer(t)
        
        set t = null
        set f = null
        set cam = null
    endfunction
    
    function DungeonMove takes force f, real x, real y, integer delay, rect cam returns nothing
        local timer t = NewTimer()
        
        call SaveForceHandle(MiscHash, GetHandleId(t), 0, f)
        call SaveRectHandle(MiscHash, GetHandleId(t), 1, cam)
        call SaveReal(MiscHash, GetHandleId(t), 2, x)
        call SaveReal(MiscHash, GetHandleId(t), 3, y)
    
        call TimerStart(t, delay, false, function DungeonMoveExpire)
        
        set t = null
    endfunction
    
    //naga dungeon
    
    function NagaReward takes nothing returns nothing
        local User U = User.first
        local integer plat = GetRandomInt(12, 15) + NAGA_PLAYERS * 3
        local integer arc = GetRandomInt(12, 15) + NAGA_PLAYERS * 3
        local integer crys = GetRandomInt(12, 15) + NAGA_PLAYERS * 3
        local integer pid

        call DisplayTimedTextToForce(NAGA_GROUP, 7.5, "|cffffcc00You have been rewarded:|r")
        call DisplayTimedTextToForce(NAGA_GROUP, 7.5, "|cffe3e2e2" + I2S(plat) + " Platinum|r")
        call DisplayTimedTextToForce(NAGA_GROUP, 7.5, "|cff66FF66" + I2S(arc) + " Arcadite|r")
        call DisplayTimedTextToForce(NAGA_GROUP, 7.5, "|cff6969FF" + I2S(crys) + " Crystals|r")

        loop
            exitwhen U == User.NULL
            set pid = GetPlayerId(U.toPlayer()) + 1
            if IsPlayerInForce(U.toPlayer(), NAGA_GROUP) then
                call AddPlatinumCoin(pid, plat)
                call AddArcaditeLumber(pid, arc)
                call AddCrystals(pid, crys)
                call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", GetUnitX(Hero[pid]), GetUnitY(Hero[pid])))
            endif
        
            set U = U.next
        endloop
        
    endfunction
    
    function NAGA_TIMER_END takes nothing returns nothing
        call TimerDialogDisplay(NAGA_TIMER_DISPLAY, false)
        set timerflag = true
        call DisplayTextToForce(NAGA_GROUP, "Special token is no longer available.")
    endfunction
    
    function NagaSpawnFloor takes integer floor returns nothing
        local integer i = 0
        local unit u
        
        set NAGA_FLOOR = floor
        
        if NAGA_FLOOR == 1 then
            call DungeonCreateUnit('n01L', -20607, -3733, 335, NAGA_PLAYERS, NAGA_ENEMIES)
            call DungeonCreateUnit('n01L', -22973, -2513, 0, NAGA_PLAYERS, NAGA_ENEMIES)
            call DungeonCreateUnit('n01L', -25340, -4218, 45, NAGA_PLAYERS, NAGA_ENEMIES)
            call DungeonCreateUnit('n01L', -24980, -6070, 335, NAGA_PLAYERS, NAGA_ENEMIES)
            call DungeonCreateUnit('n01L', -23087, -6656, 0, NAGA_PLAYERS, NAGA_ENEMIES)
            call DungeonCreateUnit('n01L', -20567, -5402, 45, NAGA_PLAYERS, NAGA_ENEMIES)
        elseif NAGA_FLOOR == 2 then
            call UnitAddBonus(DungeonCreateUnit('n005', -20607, -3733, 335, NAGA_PLAYERS, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * NAGA_PLAYERS)
            call UnitAddBonus(DungeonCreateUnit('n005', -22973, -2513, 0, NAGA_PLAYERS, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * NAGA_PLAYERS)
            call UnitAddBonus(DungeonCreateUnit('n005', -25340, -4218, 45, NAGA_PLAYERS, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * NAGA_PLAYERS)
            call UnitAddBonus(DungeonCreateUnit('n005', -24980, -6070, 335, NAGA_PLAYERS, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * NAGA_PLAYERS)
            call UnitAddBonus(DungeonCreateUnit('n005', -23087, -6656, 0, NAGA_PLAYERS, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * NAGA_PLAYERS)
            call UnitAddBonus(DungeonCreateUnit('n005', -20567, -5402, 45, NAGA_PLAYERS, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * NAGA_PLAYERS)
        elseif NAGA_FLOOR == 3 then
            set nagaboss = DungeonCreateUnit('O006', -20828, -10500, 180, NAGA_PLAYERS, NAGA_ENEMIES)
            call AddSpecialEffectTarget("LightYellow30.mdl", nagaboss, "origin")
            call SetHeroLevel(nagaboss, 500, false)
        endif
        
        set u = null
    endfunction
    
    function NagaAutoAttack takes unit source, real dmg, real x, real y, real aoe, boolexpr filter returns nothing
        local unit target
        local group ug = CreateGroup()
        
        call GroupEnumUnitsInRange(ug, x, y, aoe, filter)
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call UnitDamageTarget(source, target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        endloop
        
        call DestroyGroup(ug)
        
        set ug = null
    endfunction
    
    //end naga dungeon

    function ResetDungeonMB takes nothing returns nothing
        local User u = User.first
        local integer i = 0
        
        loop
            exitwhen u == User.NULL
            set QUEUE_READY[GetPlayerId(u.toPlayer()) + 1] = false
            
            if IsPlayerInForce(u.toPlayer(), QUEUE_GROUP) then
                call MultiboardSetItemStyleBJ( QUEUE_BOARD, 1, i, true, false )
                call MultiboardSetItemStyleBJ( QUEUE_BOARD, 2, i, false, true )

                call MultiboardSetItemValueBJ( QUEUE_BOARD, 1, i, u.nameColored )
                call MultiboardSetItemIconBJ( QUEUE_BOARD, 2, i, "ReplaceableTextures\\CommandButtons\\BTNCancel.blp")
                
                call MultiboardSetItemWidthBJ( QUEUE_BOARD, 1, i, 10.00 )
                call MultiboardSetItemWidthBJ( QUEUE_BOARD, 2, i, 1.00 )
                set i = i + 1
            endif

            set u = u.next
        endloop
        
        set u = User.first
        
        loop
            exitwhen u == User.NULL
            if IsPlayerInForce(u.toPlayer(), QUEUE_GROUP) then
                if GetLocalPlayer() == u.toPlayer() then
                    call MultiboardDisplay(QUEUE_BOARD, true)
                endif
            endif
            
            set u = u.next
        endloop
    endfunction

    function StartDungeon takes integer id, real x, real y returns nothing
        local integer pid = 0
        local User u = User.first
        
        set QUEUE_X = x
        set QUEUE_Y = y
        
        call ForceClear(QUEUE_GROUP)

        if id == 'I0JU' then
            set QUEUE_DUNGEON = 1
            set QUEUE_LEVEL = 400
            call MultiboardSetTitleText(QUEUE_BOARD, "Naga Dungeon")
        endif
        
        loop
            exitwhen u == User.NULL
            set pid = GetPlayerId(u.toPlayer()) + 1
            if isteleporting[pid] == false and IsUnitInRangeXY(Hero[pid], x, y, 500.) and GetHeroLevel(Hero[pid]) >= QUEUE_LEVEL then
                call ForceAddPlayer(QUEUE_GROUP, u.toPlayer())
            endif
            
            set u = u.next
        endloop
        
        call ResetDungeonMB()
    endfunction

    function DungeonStarter takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local integer time = GetTimerData(t)
        local integer pid
        local User u = User.first
        
        call SetTimerData(t, time - 1)
        
        if time - 1 == 0 then
            call ReleaseTimer(t)
            set NAGA_PLAYERS = 0
            
            loop
                exitwhen u == User.NULL
                set pid = GetPlayerId(u.toPlayer()) + 1
                if IsPlayerInForce(u.toPlayer(), QUEUE_GROUP) and QUEUE_READY[pid] then
                    if QUEUE_DUNGEON == 1 then //once dungeon begins
                        call SetUnitPosition(Hero[pid], -20000, -4600)
                        call ForceAddPlayer(NAGA_GROUP, u.toPlayer())
                        call SetCameraBoundsRectForPlayerEx(u.toPlayer(), gg_rct_Naga_Dungeon_Vision)
                        call PanCameraToTimedForPlayer(u.toPlayer(), -20000, -4600, 0)
                        call DisableItems(pid)
                        set NAGA_PLAYERS = NAGA_PLAYERS + 1
                    elseif QUEUE_DUNGEON == 2 then
                        
                    endif
                    
                    call ForceRemovePlayer(QUEUE_GROUP, u.toPlayer())
                endif
                
                set QUEUE_READY[pid] = false
                set u = u.next
            endloop
            
            if QUEUE_DUNGEON == 1 then
                call NagaSpawnFloor(1)

                call TimerStart(NAGA_TIMER, 1800., false, function NAGA_TIMER_END)
                call TimerDialogSetTitle(NAGA_TIMER_DISPLAY, "Ruin Collapse")
                call TimerDialogDisplay(NAGA_TIMER_DISPLAY, true)
            endif
            
            set QUEUE_DUNGEON = 0
            set QUEUE_LEVEL = 0
            call MultiboardDisplay(MULTI_BOARD, true)
        endif

        set t = null
    endfunction

    function ReadyCheck takes nothing returns nothing
        local User u = User.first
        local boolean allReady = true
        
        loop
            exitwhen u == User.NULL
            if not QUEUE_READY[GetPlayerId(u.toPlayer()) + 1] and IsPlayerInForce(u.toPlayer(), QUEUE_GROUP) then
                set allReady = false
            endif
            set u = u.next
        endloop

        if allReady then
            call BlackMask(QUEUE_GROUP, 2, 2)
            call TimerStart(NewTimerEx(2), 1., true, function DungeonStarter)
        else
            call DisplayTextToForce(QUEUE_GROUP, "Not all players are ready to start the dungeon!")
        endif
    endfunction

endlibrary
