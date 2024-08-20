--[[
    timers.lua

    A library that initializes game timers and functions that should run periodically.
    Notable functions:
    Tick() - executes roughly 64 times per second
    Periodic() - executes roughly 3 times per second

    Ideally we try to avoid doing too much in periodic functions because performance
    is easily affected in wc3 as a single-threaded game.

    Makes use of the timerqueue library for more fluid callback functionality and timer recycling.
]]

OnInit.final("Timers", function(Require)
    Require('Units')
    Require('Boss')
    Require('MapSetup')
    Require('Buffs')
    Require('Frames')

    WANDER_TIMER = TimerQueue.create()

    function DisplayHint()
        local rand = GetRandomInt(2, #HINT_TOOLTIP) ---@type integer 

        if LAST_HINT < 2 then
            LAST_HINT = LAST_HINT + 1
        else
            LAST_HINT = rand
        end

        DisplayTimedTextToForce(FORCE_HINT, 15, HINT_TOOLTIP[LAST_HINT])
        if rand ~= LAST_HINT then
            LAST_HINT = rand
        else
            LAST_HINT = LAST_HINT + 1
        end
        if LAST_HINT > #HINT_TOOLTIP then
            LAST_HINT = 1
        end
    end

    local setcamerafield = SetCameraField

    local function Periodic()
        -- camera lock
        local pid = GetPlayerId(GetLocalPlayer()) + 1

        if IS_CAMERA_LOCKED[pid] and not SELECTING_HERO[pid] then
            setcamerafield(CAMERA_FIELD_TARGET_DISTANCE, ZOOM[pid], 0)
        end
    end

    function SpawnStruggleUnits()
        local end_ = R2I(Struggle_Wave_SR[Struggle_WaveN]) ---@type integer 
        local rand = GetRandomInt(1,4) ---@type integer 
        local u ---@type unit 

        if Struggle_Pcount > 0 and Struggle_WaveU[Struggle_WaveN] > 0 then
            for i = 0, end_ do
                if Struggle_WaveUCN > 0 then
                    if BlzGroupGetSize(StruggleWaveGroup) < 70 then
                        Struggle_WaveUCN = Struggle_WaveUCN - 1
                        u = CreateUnit(PLAYER_BOSS, Struggle_WaveU[Struggle_WaveN], GetRectCenterX(gg_rct_Infinite_Struggle), GetRectCenterY(gg_rct_Infinite_Struggle), bj_UNIT_FACING)
                        SetUnitXBounded(u, GetRandomReal(GetRectMinX(Struggle_SpawnR[rand]), GetRectMaxX(Struggle_SpawnR[rand])))
                        SetUnitYBounded(u, GetRandomReal(GetRectMinY(Struggle_SpawnR[rand]), GetRectMaxY(Struggle_SpawnR[rand])))
                        GroupAddUnit(StruggleWaveGroup, u)
                        SetUnitCreepGuard(u, false)
                        SetUnitAcquireRange(u, 3000.)
                    end
                end
            end
            TimerQueue:callDelayed(3., SpawnStruggleUnits)
        end
    end

    local function ColosseumXPDecrease()
        local u = User.first ---@type User 

        while u do
            if HeroID[u.id] ~= 0 then
                if IS_IN_COLO[u.id] and Colosseum_XP[u.id] > 0.05 then
                    Colosseum_XP[u.id] = Colosseum_XP[u.id] - 0.005
                end
                if Colosseum_XP[u.id] < 0.05 then
                    Colosseum_XP[u.id] = 0.05
                end
                ExperienceControl(u.id)
            end
            u = u.next
        end
    end

    local function WanderingGuys()
        local x ---@type number 
        local y ---@type number 
        local x2 ---@type number 
        local y2 ---@type number 
        local count = 0 ---@type integer 
        local id    = (CHAOS_MODE and BOSS_LEGION) or BOSS_DEATH_KNIGHT

        if CHAOS_LOADING then
            return
        end

        --dk / legion
        if GetUnitTypeId(Boss[id].unit) ~= 0 and UnitAlive(Boss[id].unit) then
            repeat
                x = GetRandomReal(MAIN_MAP.minX, MAIN_MAP.maxX)
                y = GetRandomReal(MAIN_MAP.minY, MAIN_MAP.maxY)
                x2 = GetUnitX(Boss[id].unit)
                y2 = GetUnitY(Boss[id].unit)
                count = count + 1

            until LineContainsRect(x2, y2, x, y, -4000, -3000, 4000, 5000) == false and IsTerrainWalkable(x, y) and DistanceCoords(x, y, x2, y2) > 2500.

            IssuePointOrder(Boss[id].unit, "patrol", x, y)
        end

        if UnitAlive(townpaladin) then
            if not TimerList[0]:has('pala') or (DistanceCoords(GetUnitX(townpaladin), GetUnitY(townpaladin), GetRectCenterX(gg_rct_Town_Boundry), GetRectCenterY(gg_rct_Town_Boundry)) > 3000.) then
                x = GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 500, GetRectMaxX(gg_rct_Town_Boundry) - 500)
                y = GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 500, GetRectMaxY(gg_rct_Town_Boundry) - 500)

                IssuePointOrder(townpaladin, "move", x, y)
            end
        end

        if UnitAlive(udg_SPONSOR) then
            x = GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 500, GetRectMaxX(gg_rct_Town_Boundry) - 500)
            y = GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 500, GetRectMaxY(gg_rct_Town_Boundry) - 500)

            IssuePointOrder(udg_SPONSOR, "move", x, y)
        end
    end

    function OneMinute()
        local id = GetPlayerId(GetLocalPlayer()) + 1

        if HeroID[id] > 0 then
            Profile[id].hero.time = Profile[id].hero.time + 1
            Profile[id].total_time = Profile[id].total_time + 1

            --colosseum xp decrease
            if not IS_IN_COLO[id] and Colosseum_XP[id] < 1.30 then
                if Colosseum_XP[id] < 0.75 then
                    Colosseum_XP[id] = Colosseum_XP[id] + 0.02
                else
                    Colosseum_XP[id] = Colosseum_XP[id] + 0.01
                end
                if Colosseum_XP[id] > 1.30 then
                    Colosseum_XP[id] = 1.30
                end
                ExperienceControl(id)
            end
        end
    end

    ---@type fun(): string
    local function GenerateAFKString()
        local alphanumeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        local str = ""

        for _ = 1, 4 do
            local index = GetRandomInt(1, #alphanumeric)
            str = str .. alphanumeric:sub(index, index)
        end

        return str
    end

    function AFKClock()
        local U = User.first ---@type User 

        AFK_TEXT = GenerateAFKString()
        BlzFrameSetText(AFK_FRAME, "Type -" .. AFK_TEXT)

        while U do
            if HeroID[U.id] > 0 then
                if afkTextVisible[U.id] then
                    afkTextVisible[U.id] = false
                    if GetLocalPlayer() == U.player then
                        BlzFrameSetVisible(AFK_FRAME_BG, false)
                    end
                    PanCameraToTimedLocForPlayer(U.player, TOWN_CENTER, 0)
                    DisplayTextToForce(FORCE_PLAYING, U.nameColored .. " was removed for being AFK.")
                    DisplayTextToPlayer(U.player, 0, 0, "You have lost the game. All of your structures and units will be removed from the game, however you may stay and watch or leave as you choose.")
                    PlayerCleanup(U.id)
                elseif panCounter[U.id] < 50 or moveCounter[U.id] < 5000 or clickCounter[U.id] < 200 then
                    afkTextVisible[U.id] = true
                    if GetLocalPlayer() == U.player then
                        BlzFrameSetVisible(AFK_FRAME_BG, true)
                    end
                    SoundHandler("Sound\\Interface\\SecretFound.wav", false, U.player, nil)
                end
            end

            moveCounter[U.id] = 0
            panCounter[U.id] = 0
            clickCounter[U.id] = 0

            U = U.next
        end
    end

    local fountain_filter = Filter(function()
        local u = GetFilterUnit()
        local id = GetUnitTypeId(u)

        if id ~= BACKPACK then
            local hp, mp = GetWidgetLife(u), GetUnitState(u, UNIT_STATE_MANA)

            if hp < BlzGetUnitMaxHP(u) * 0.99 then
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", u, "origin"))
                SetWidgetLife(u, hp + BlzGetUnitMaxHP(u))
            end

            if mp < BlzGetUnitMaxMana(u) * 0.99 and GetUnitTypeId(u) ~= HERO_VAMPIRE then
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIma\\AImaTarget.mdl", u, "origin"))
                SetUnitState(u, UNIT_STATE_MANA, mp + BlzGetUnitMaxMana(u))
            end
        end
    end)

    local function OneSecond()
        -- set space bar camera to town
        SetCameraQuickPositionLoc(TOWN_CENTER)

        -- fountain regeneration
        local ug = CreateGroup()
        GroupEnumUnitsInRange(ug, -260., 350., 600., fountain_filter)
        DestroyGroup(ug)

        -- refresh auras, mana costs, etc.
        RefreshHeroes()
    end

    -- localizing here is great
    local framesetvisible = BlzFrameSetVisible
    local framesettexture = BlzFrameSetTexture
    local getmainselectedunit = GetMainSelectedUnit
    local unititeminslot = UnitItemInSlot

    local function Tick()
        local u = getmainselectedunit() ---@type unit 

        -- rarity item borders
        for i = 1, 6 do
            local itm = Item[unititeminslot(u, i - 1)]

            if itm then
                framesettexture(INVENTORYBACKDROP[i], (SPRITE_RARITY[itm.level]), 0, true)
            end

            framesetvisible(INVENTORYBACKDROP[i], (itm and true) or false)
        end

        framesetvisible(PUNCHING_BAG_UI, u == PUNCHING_BAG)

        -- frame to hide health
        framesetvisible(HIDE_HEALTH_FRAME, (u and Unit[u].hidehp))
    end

    TimerQueue:callPeriodically(FPS_64, nil, Tick)
    TimerQueue:callPeriodically(0.35, nil, Periodic)
    TimerQueue:callPeriodically(1.0, nil, OneSecond)
    TimerQueue:callPeriodically(15., nil, WanderingGuys)
    TimerQueue:callPeriodically(15., nil, ColosseumXPDecrease)
    TimerQueue:callPeriodically(60., nil, OneMinute)
    TimerQueue:callPeriodically(240., nil, DisplayHint)
    TimerQueue:callPeriodically(1800., nil, AFKClock)

    WANDER_TIMER:callDelayed(2040. - (User.AmountPlaying * 240), ShadowStepExpire)
end, Debug and Debug.getLine())
