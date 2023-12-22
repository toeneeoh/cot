if Debug then Debug.beginFile 'Dungeons' end

OnInit.final("Dungeons", function(require)
        require 'Helper'
        require 'Variables'

        DungeonTable = {} ---@type table 
        QUEUE_DUNGEON         = 0 ---@type integer 
        QUEUE_GROUP       = CreateForce() ---@type force 
        QUEUE_X      = 0. ---@type number 
        QUEUE_Y      = 0. ---@type number 
        QUEUE_LEVEL         = 0 ---@type integer 
        QUEUE_READY=__jarray(false) ---@type boolean[] 

        NAGA_FLOOR         = 0 ---@type integer 
        NAGA_TIMER       = CreateTimer() ---@type timer 
        NAGA_TIMER_DISPLAY             = CreateTimerDialog(NAGA_TIMER) ---@type timerdialog 
        NAGA_ENEMIES       = CreateGroup()
        nagatp      = nil ---@type unit 
        nagachest      = nil ---@type unit 
        nagaboss      = nil ---@type unit 
        nagawaterstrikecd         = false ---@type boolean 
        timerflag         = false ---@type boolean 

        NAGA_GROUP       = CreateForce() ---@type force 
        AZAZOTH_GROUP       = CreateForce() ---@type force 

        DUNGEON_AZAZOTH         = FourCC('I08T') ---@type integer 
        DUNGEON_NAGA         = FourCC('I0JU') ---@type integer 

        DUNGEON_LEVEL         = 0 ---@type integer 
        DUNGEON_QUEUE         = 1 ---@type integer 
        DUNGEON_GROUP         = 2 ---@type integer 
        DUNGEON_NAME         = 3 ---@type integer 
        DUNGEON_QUEUE_LOC         = 4 ---@type integer 
        DUNGEON_ENTRANCE_LOC         = 5 ---@type integer 
        DUNGEON_PLAYER_COUNT         = 6 ---@type integer 
        DUNGEON_VISION         = 7 ---@type integer 


    ---@param id integer
    ---@param x number
    ---@param y number
    ---@param facing number
    ---@param dmgr integer
    ---@param g group
    ---@return unit
    function DungeonCreateUnit(id, x, y, facing, dmgr, g)
        bj_lastCreatedUnit = CreateUnit(pfoe, id, x, y, facing)
        GroupAddUnit(g, bj_lastCreatedUnit)
        SaveInteger(MiscHash, GetHandleId(bj_lastCreatedUnit), FourCC('dmgr'), dmgr)
        return bj_lastCreatedUnit
    end

    ---@type fun(f: force, cam: rect, x: number, y: number)
    function DungeonMoveExpire()
        local U      = User.first ---@type User 

        while U do
            if IsPlayerInForce(U.player, f) then
                ShowUnit(HeroGrave[U.id], true)
                SetUnitPosition(HeroGrave[U.id], x, y)
                ShowUnit(HeroGrave[U.id], false)
                SetUnitXBounded(Hero[U.id], x)
                SetUnitYBounded(Hero[U.id], y)
                SetCameraBoundsRectForPlayerEx(U.player, cam)
                PanCameraToTimedForPlayer(U.player, x, y, 0)
            end

            U = U.next
        end
    end

    ---@type fun(f: force, x: number, y:number, delay: number, cam: rect)
    function DungeonMove(f, x, y, delay, cam)
        TimerQueue:callDelayed(delay, DungeonMoveExpire, f, cam, x, y)
    end

    --naga dungeon

    function NagaReward()
        local U      = User.first ---@type User 
        local pcount         = DungeonTable[DUNGEON_NAGA][DUNGEON_PLAYER_COUNT] ---@type integer 
        local plat         = GetRandomInt(12, 15) + pcount * 3 ---@type integer 
        local arc         = GetRandomInt(12, 15) + pcount * 3 ---@type integer 
        local crystal         = GetRandomInt(12, 15) + pcount * 3 ---@type integer 

        DisplayTimedTextToForce(NAGA_GROUP, 7.5, "|cffffcc00You have been rewarded:|r|n|cffe3e2e2" .. (plat) .. " Platinum|r|n|cff66FF66" .. (arc) .. " Arcadite|r|n|cff6969FF" .. (crystal) .. " Crystals|r")

        while U do
            if IsPlayerInForce(U.player, NAGA_GROUP) then
                AddCurrency(U.id, PLATINUM, plat)
                AddCurrency(U.id, ARCADITE, arc)
                AddCurrency(U.id, CRYSTAL, crystal)
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", GetUnitX(Hero[U.id]), GetUnitY(Hero[U.id])))
            end

            U = U.next
        end

    end

    function NAGA_TIMER_END()
        TimerDialogDisplay(NAGA_TIMER_DISPLAY, false)
        timerflag = true
        DisplayTextToForce(NAGA_GROUP, "Special token is no longer available.")
    end

    ---@param floor integer
    function NagaSpawnFloor(floor)
        local i         = 0 ---@type integer 
        local pcount         = DungeonTable[DUNGEON_NAGA][DUNGEON_PLAYER_COUNT] ---@type integer 

        NAGA_FLOOR = floor

        if NAGA_FLOOR == 1 then
            DungeonCreateUnit(FourCC('n01L'), -20607, -3733, 335, pcount, NAGA_ENEMIES)
            DungeonCreateUnit(FourCC('n01L'), -22973, -2513, 0, pcount, NAGA_ENEMIES)
            DungeonCreateUnit(FourCC('n01L'), -25340, -4218, 45, pcount, NAGA_ENEMIES)
            DungeonCreateUnit(FourCC('n01L'), -24980, -6070, 335, pcount, NAGA_ENEMIES)
            DungeonCreateUnit(FourCC('n01L'), -23087, -6656, 0, pcount, NAGA_ENEMIES)
            DungeonCreateUnit(FourCC('n01L'), -20567, -5402, 45, pcount, NAGA_ENEMIES)
        elseif NAGA_FLOOR == 2 then
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -20607, -3733, 335, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -22973, -2513, 0, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -25340, -4218, 45, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -24980, -6070, 335, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -23087, -6656, 0, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -20567, -5402, 45, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
        elseif NAGA_FLOOR == 3 then
            nagaboss = DungeonCreateUnit(FourCC('O006'), -20828, -10500, 180, pcount, NAGA_ENEMIES)
            AddSpecialEffectTarget("LightYellow30.mdl", nagaboss, "origin")
            SetHeroLevel(nagaboss, 500, false)
        end
    end

    ---@param source unit
    ---@param dmg number
    ---@param x number
    ---@param y number
    ---@param aoe number
    ---@param filter boolexpr
    function NagaAutoAttack(source, dmg, x, y, aoe, filter)
        local ug       = CreateGroup()

        GroupEnumUnitsInRange(ug, x, y, aoe, filter)

        local target = FirstOfGroup(ug)
        while target do
            GroupRemoveUnit(ug, target)
            UnitDamageTarget(source, target, dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            target = FirstOfGroup(ug)
        end

        DestroyGroup(ug)
    end

    ---@param amount number
    ---@param source unit
    ---@param target unit
    ---@param damageType damagetype
    ---@return number
    function DungeonOnDamage(amount, source, target, damageType)
        local uid         = GetUnitTypeId(source) ---@type integer 
        local tuid         = GetUnitTypeId(target) ---@type integer 

        --target
        if tuid == FourCC('n01L') then --naga defender
            amount = amount * (1 - LoadInteger(MiscHash, GetHandleId(target), FourCC('dmgr')) * 0.1)
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A04K')) == 0 and GetUnitLifePercent(target) < 90. then
                IssueImmediateOrder(target, "berserk")
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A04R')) == 0 and GetUnitLifePercent(target) < 80. then
                IssueImmediateOrder(target, "battleroar")
            end

            if damageType == PHYSICAL and GetUnitAbilityLevel(target, FourCC('B04S')) > 0 then
                UnitDamageTarget(target, source, BlzGetUnitMaxHP(source) * 0.2, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            end
        elseif tuid == FourCC('n005') then --naga elite
            amount = amount * (1 - LoadInteger(MiscHash, GetHandleId(target), FourCC('dmgr')) * 0.1)
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A04V')) == 0 and GetUnitLifePercent(target) < 90. then
                IssueImmediateOrder(target, "battleroar")
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A04W')) == 0 and GetUnitLifePercent(target) < 80. then
                IssueImmediateOrder(target, "berserk")
            end
        elseif tuid == FourCC('O006') then --naga boss
            amount = amount * (1 - LoadInteger(MiscHash, GetHandleId(target), FourCC('dmgr')) * 0.1)
            if nagawaterstrikecd == false then
                nagawaterstrikecd = true
                TimerQueue:callDelayed(5., NagaWaterStrike)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A05C')) == 0 and GetUnitLifePercent(target) < 90. then
                IssueImmediateOrder(target, "berserk")
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A05K')) == 0 and GetUnitLifePercent(target) < 80. then
                IssueImmediateOrder(target, "battleroar")
            end
        elseif tuid == FourCC('u002') then --beetle
            if damageType == MAGIC then
                amount = 0.00
            end
        end

        --source
        if uid == FourCC('n01L') then --naga defender
            if damageType == PHYSICAL then
                amount = 0.00

                SaveInteger(MiscHash, GetHandleId(source), FourCC('hits'), LoadInteger(MiscHash, GetHandleId(source), FourCC('hits')) + 1)
                FloatingTextUnit((LoadInteger(MiscHash, GetHandleId(source), FourCC('hits'))), target, 1.5, 50, 150., 14.5, 255, 255, 255, 0, true)

                if LoadUnitHandle(MiscHash, GetHandleId(source), FourCC('targ')) ~= target then
                    SaveInteger(MiscHash, GetHandleId(source), FourCC('hits'), 1)
                    SaveUnitHandle(MiscHash, GetHandleId(source), FourCC('targ'), target)
                elseif LoadInteger(MiscHash, GetHandleId(source), FourCC('hits')) > 2 then
                    NagaAutoAttack(source, BlzGetUnitMaxHP(target) * 0.7, GetUnitX(target), GetUnitY(target), 120., Condition(isplayerunit))
                    DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", target, "origin"))
                    SaveInteger(MiscHash, GetHandleId(source), FourCC('hits'), 0)
                    SaveUnitHandle(MiscHash, GetHandleId(source), FourCC('targ'), nil)
                end
            end
        elseif uid == FourCC('n005') then --naga elite

        elseif uid == FourCC('u002') then --beetle
            Stun:add(source, target):duration(8.)
            KillUnit(source)
        elseif uid == FourCC('h003') then --naga water strike
            amount = 0.00
            if UnitAlive(nagaboss) then
                UnitDamageTarget(nagaboss, target, BlzGetUnitMaxHP(target) * 0.075, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            end
            RemoveUnit(source)
        end

        return amount
    end

    --end naga dungeon

    function DungeonStarter()
        local U      = User.first ---@type User 

        while U do
            if IsPlayerInForce(U.player, QUEUE_GROUP) and QUEUE_READY[U.id] then
                MoveHeroLoc(U.id, DungeonTable[QUEUE_DUNGEON][DUNGEON_ENTRANCE_LOC])
                ForceAddPlayer(DungeonTable[QUEUE_DUNGEON][DUNGEON_GROUP], U.player)
                SetCameraBoundsRectForPlayerEx(U.player, DungeonTable[QUEUE_DUNGEON][DUNGEON_VISION])
                PanCameraToTimedLocForPlayer(U.player, DungeonTable[QUEUE_DUNGEON][DUNGEON_ENTRANCE_LOC], 0.)
                DungeonTable[QUEUE_DUNGEON][DUNGEON_PLAYER_COUNT] = DungeonTable[QUEUE_DUNGEON][DUNGEON_PLAYER_COUNT] + 1

                --dungeon disables items?
                DisableItems(U.id)

                ForceRemovePlayer(QUEUE_GROUP, U.player)
            end

            QUEUE_READY[U.id] = false
            U = U.next
        end

        if QUEUE_DUNGEON == DUNGEON_NAGA then
            NagaSpawnFloor(1)

            TimerStart(NAGA_TIMER, 1800., false, NAGA_TIMER_END)
            TimerDialogSetTitle(NAGA_TIMER_DISPLAY, "Ruin Collapse")
            TimerDialogDisplay(NAGA_TIMER_DISPLAY, true)
        end

        QUEUE_DUNGEON = 0
        QUEUE_LEVEL = 0
        MultiboardDisplay(MULTI_BOARD, true)
    end

    ---@param id integer
    function ReadyCheck(id)
        local U      = User.first ---@type User 
        local allReady         = true ---@type boolean 

        while U do
            if not QUEUE_READY[U.id] and IsPlayerInForce(U.player, QUEUE_GROUP) then
                allReady = false
            end
            U = U.next
        end

        if allReady then
            BlackMask(QUEUE_GROUP, 2, 2)

            DungeonTable[id][DUNGEON_PLAYER_COUNT] = 0

            TimerQueue:callDelayed(2., DungeonStarter)
        else
            DisplayTextToForce(QUEUE_GROUP, "Not all players are ready to start the dungeon!")
        end
    end

    ---@param pid integer
    ---@param id integer
    function QueueDungeon(pid, id)
        if CountPlayersInForceBJ(DungeonTable[id][DUNGEON_GROUP]) > 0 then
            DisplayTextToPlayer(Player(pid - 1), 0, 0, "This dungeon is already in progress!")
        else
            if QUEUE_DUNGEON == 0 then
                QUEUE_X = GetLocationX(DungeonTable[id][DUNGEON_QUEUE_LOC])
                QUEUE_Y = GetLocationY(DungeonTable[id][DUNGEON_QUEUE_LOC])
                QUEUE_LEVEL = DungeonTable[id][DUNGEON_LEVEL]
                QUEUE_DUNGEON = id

                ForceClear(QUEUE_GROUP)
                MultiboardSetTitleText(QUEUE_BOARD, DungeonTable[id][DUNGEON_NAME])
            elseif QUEUE_DUNGEON == id then
                ReadyCheck(id)
            else
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Please wait while another dungeon is queueing!")
            end
        end
    end

    DungeonTable[DUNGEON_AZAZOTH] = {}
    DungeonTable[DUNGEON_AZAZOTH][DUNGEON_LEVEL] = 360
    DungeonTable[DUNGEON_AZAZOTH][DUNGEON_QUEUE] = 0
    DungeonTable[DUNGEON_AZAZOTH][DUNGEON_PLAYER_COUNT] = 0
    DungeonTable[DUNGEON_AZAZOTH][DUNGEON_GROUP] = AZAZOTH_GROUP
    DungeonTable[DUNGEON_AZAZOTH][DUNGEON_NAME] = "Azazoth's Lair"
    DungeonTable[DUNGEON_AZAZOTH][DUNGEON_QUEUE_LOC] = Location(-1408., -15246.)
    DungeonTable[DUNGEON_AZAZOTH][DUNGEON_ENTRANCE_LOC] = Location(-2036., -28236.)
    DungeonTable[DUNGEON_AZAZOTH][DUNGEON_VISION] = gg_rct_GodsCameraBounds

    DungeonTable[DUNGEON_NAGA] = {}
    DungeonTable[DUNGEON_NAGA][DUNGEON_LEVEL] = 400
    DungeonTable[DUNGEON_NAGA][DUNGEON_QUEUE] = 0
    DungeonTable[DUNGEON_NAGA][DUNGEON_PLAYER_COUNT] = 0
    DungeonTable[DUNGEON_NAGA][DUNGEON_GROUP] = NAGA_GROUP
    DungeonTable[DUNGEON_NAGA][DUNGEON_NAME] = "Naga Dungeon"
    DungeonTable[DUNGEON_NAGA][DUNGEON_QUEUE_LOC] = Location(-12363., -1185.)
    DungeonTable[DUNGEON_NAGA][DUNGEON_ENTRANCE_LOC] = Location(-20000., -4600.)
    DungeonTable[DUNGEON_NAGA][DUNGEON_VISION] = gg_rct_Naga_Dungeon_Vision

end)

if Debug then Debug.endFile() end
