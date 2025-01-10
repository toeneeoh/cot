--[[
    timers.lua

    A library that initializes game timers and functions that should run periodically.
    Notable functions:
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
    local gpi, glp = GetPlayerId, GetLocalPlayer

    local is_camera_locked = {} ---@type boolean[] 
    local selecting_hero, zoom = SELECTING_HERO, ZOOM

    function SetCameraLocked(pid, lock)
        if not is_camera_locked[pid] then
            is_camera_locked[pid] = lock
        end
    end

    local function Periodic()
        local pid = gpi(glp()) + 1

        -- camera lock
        if is_camera_locked[pid] and not selecting_hero[pid] then
            setcamerafield(CAMERA_FIELD_TARGET_DISTANCE, zoom[pid], 0)
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
            if not TimerList[0]:has('pala') or (DistanceCoords(GetUnitX(townpaladin), GetUnitY(townpaladin), GetRectCenterX(gg_rct_Town_Main), GetRectCenterY(gg_rct_Town_Main)) > 3000.) then
                x = GetRandomReal(GetRectMinX(gg_rct_Town_Main) + 500, GetRectMaxX(gg_rct_Town_Main) - 500)
                y = GetRandomReal(GetRectMinY(gg_rct_Town_Main) + 500, GetRectMaxY(gg_rct_Town_Main) - 500)

                IssuePointOrder(townpaladin, "move", x, y)
            end
        end

        if UnitAlive(udg_SPONSOR) then
            x = GetRandomReal(GetRectMinX(gg_rct_Town_Main) + 500, GetRectMaxX(gg_rct_Town_Main) - 500)
            y = GetRandomReal(GetRectMinY(gg_rct_Town_Main) + 500, GetRectMaxY(gg_rct_Town_Main) - 500)

            IssuePointOrder(udg_SPONSOR, "move", x, y)
        end
    end

    function OneMinute()
        local id = GetPlayerId(GetLocalPlayer()) + 1
        local profile = Profile[id]

        if profile.playing then
            profile.hero.time = profile.hero.time + 1
            profile.total_time = profile.total_time + 1

            ExperienceControl(id)
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

    local function RefreshHeroes()
        local U = User.first

        while U do
            if Profile[U.id].playing then
                local hero = Hero[U.id]
                local x, y = GetUnitX(hero), GetUnitY(hero)

                -- update boost variance every second
                BOOST[U.id] = 1. + Unit[hero].spellboost + GetRandomReal(-0.2, 0.2)
                LBOOST[U.id] = 1. + 0.5 * Unit[hero].spellboost

                if DEV_ENABLED then
                    if BOOST_OFF then
                        BOOST[U.id] = (1. + Unit[hero].spellboost)
                    end
                end

                -- cooldowns
                UpdateManaCosts(U.id)

                -- keep track of hero positions
                Unit[hero].proxy.x = x
                Unit[hero].proxy.y = y

                -- PVP leave range
                if ArenaQueue[U.id] > 0 and IsUnitInRangeXY(hero, -1311., 2905., 1000.) == false then
                    ArenaQueue[U.id] = 0
                    DisplayTimedTextToPlayer(U.player, 0, 0, 5.0, "You have been removed from the PvP queue.")
                end

                local hp = GetWidgetLife(hero) / BlzGetUnitMaxHP(hero)

                -- backpack hp/mp percentage and movespeed
                if hp >= 0.01 then
                    SetWidgetLife(Backpack[U.id], BlzGetUnitMaxHP(Backpack[U.id]) * hp)
                    local mp = GetUnitState(hero, UNIT_STATE_MANA) / GetUnitState(hero, UNIT_STATE_MAX_MANA)
                    SetUnitState(Backpack[U.id], UNIT_STATE_MANA, GetUnitState(Backpack[U.id], UNIT_STATE_MAX_MANA) * mp)
                    --SetUnitMoveSpeed(Backpack[U.id], Unit[hero].ms_flat * Unit[hero].ms_percent)
                end

                -- tooltips
                UpdateSpellTooltips(U.id)

                -- TODO: move these to individual spells
                local ug = CreateGroup()
                MakeGroupInRange(U.id, ug, x, y, 900. * LBOOST[U.id], Condition(FilterAlly))

                for target in each(ug) do
                    if InspireBuff:has(hero, hero) then
                        InspireBuff:add(hero, target):duration(1.)
                        local b = InspireBuff:get(nil, target)
                        b:strongest(math.max(b.ablev, GetUnitAbilityLevel(hero, INSPIRE.id)))
                    end
                    if GetUnitAbilityLevel(hero, PROTECTOR.id) > 0 then
                        ProtectedBuff:add(hero, target):duration(2.)
                    end
                    if FightMeCasterBuff:has(hero, hero) and target ~= hero then
                        FightMeBuff:add(hero, target):duration(2.)
                    end
                    if GetUnitAbilityLevel(hero, AURAOFJUSTICE.id) > 0 then
                        JusticeAuraBuff:add(hero, target):duration(2.)
                        local b = JusticeAuraBuff:get(nil, target)
                        b:strongest(math.max(b.ablev, GetUnitAbilityLevel(hero, AURAOFJUSTICE.id)))
                    end
                end

                DestroyGroup(ug)
            end

            U = U.next
        end
    end

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

    TimerQueue:callPeriodically(0.35, nil, Periodic)
    TimerQueue:callPeriodically(1.0, nil, OneSecond)
    TimerQueue:callPeriodically(15., nil, WanderingGuys)
    TimerQueue:callPeriodically(60., nil, OneMinute)
    TimerQueue:callPeriodically(240., nil, DisplayHint)

    HUNT_TIMER = TimerQueue:callDelayed(2040. - (User.AmountPlaying * 240), ShadowStepExpire)
end, Debug and Debug.getLine())
