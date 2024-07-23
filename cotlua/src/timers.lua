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
    Require('BossAI')
    Require('MapSetup')
    Require('Buffs')
    Require('Frames')

    HERO_GROUP   = {}
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

    ---@type fun(pt: PlayerTimer)
    function ReturnBoss(pt)
        if UnitAlive(BossTable[pt.id].unit) and not CHAOS_LOADING then
            if IsUnitInRangeLoc(BossTable[pt.id].unit, BossTable[pt.id].loc, 100.) then
                pt:destroy()
                Unit[BossTable[pt.id].unit].overmovespeed = nil
                SetUnitPathing(BossTable[pt.id].unit, true)
                UnitRemoveAbility(BossTable[pt.id].unit, FourCC('Amrf'))
                SetUnitTurnSpeed(BossTable[pt.id].unit, GetUnitDefaultTurnSpeed(BossTable[pt.id].unit))
            else
                IssuePointOrder(BossTable[pt.id].unit, "move", GetLocationX(BossTable[pt.id].loc), GetLocationY(BossTable[pt.id].loc))
                Buff.dispelAll(BossTable[pt.id].unit)
            end

            pt.timer:callDelayed(0.25, ReturnBoss, pt)
        else
            pt:destroy()
        end
    end

    local function Periodic()

        --camera lock
        do
            local pid = GetPlayerId(GetLocalPlayer()) + 1

            if IS_CAMERA_LOCKED[pid] and not SELECTING_HERO[pid] then
                SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, Zoom[pid], 0)
            end
        end

        --player loop
        local u = User.first ---@type User 
        local x, y

        while u do
            local pid = u.id

            if Backpack[pid] then

                --backpack move
                x = GetUnitX(Hero[pid]) + 50 * Cos((GetUnitFacing(Hero[pid]) - 45) * bj_DEGTORAD)
                y = GetUnitY(Hero[pid]) + 50 * Sin((GetUnitFacing(Hero[pid]) - 45) * bj_DEGTORAD)
                if IsUnitInRange(Hero[pid], Backpack[pid], 1000.) == false then
                    SetUnitXBounded(Backpack[pid], x)
                    SetUnitYBounded(Backpack[pid], y)
                    BlzUnitClearOrders(Backpack[pid], false)
                elseif not IS_BACKPACK_MOVING[pid] or IsUnitInRange(Hero[pid], Backpack[pid], 800.) == false then
                    if IsUnitInRange(Hero[pid], Backpack[pid], 50.) == false then
                        IssuePointOrderById(Backpack[pid], ORDER_ID_MOVE, x, y)
                    end
                end
            end

            u = u.next
        end
    end

    function CreateWell()
        local heal = 50 ---@type integer 
        local x    = 0 ---@type number 
        local y    = 0 ---@type number 
        local r ---@type rect 
        local rand = GetRandomInt(1, 14) ---@type integer 

        if rand == 14 then
            rand = 15 --exclude elder dragon
        end

        if wellcount < 7 then
            r = SelectGroupedRegion(rand)

            wellcount = wellcount + 1
            repeat
                x = GetRandomReal(GetRectMinX(r), GetRectMaxX(r))
                y = GetRandomReal(GetRectMinY(r), GetRectMaxY(r))
            until IsTerrainWalkable(x, y)
            --TODO rework into sfx? use ui for tooltip?
            well[wellcount] = Dummy.create(x, y, 0, 0, 0).unit
            BlzSetUnitFacingEx(well[wellcount], 270)
            UnitRemoveAbility(well[wellcount], FourCC('Aloc'))
            ShowUnit(well[wellcount], false)
            ShowUnit(well[wellcount], true)
            if GetRandomInt(0, 2) < 2 then
                BlzSetUnitSkin(well[wellcount], FourCC('h04W'))
                BlzSetUnitName(well[wellcount], "Health Well")
            else
                BlzSetUnitSkin(well[wellcount], FourCC('h05H'))
                BlzSetUnitName(well[wellcount], "Mana Well")
                heal = heal + 100 --mana
            end
            SetUnitScale(well[wellcount], 0.5, 0.5, 0.5)
            wellheal[wellcount] = heal
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
                        u = CreateUnit(pboss, Struggle_WaveU[Struggle_WaveN], GetRectCenterX(gg_rct_Infinite_Struggle), GetRectCenterY(gg_rct_Infinite_Struggle), bj_UNIT_FACING)
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
        if GetUnitTypeId(BossTable[id].unit) ~= 0 and UnitAlive(BossTable[id].unit) then
            repeat
                x = GetRandomReal(MAIN_MAP.minX, MAIN_MAP.maxX)
                y = GetRandomReal(MAIN_MAP.minY, MAIN_MAP.maxY)
                x2 = GetUnitX(BossTable[id].unit)
                y2 = GetUnitY(BossTable[id].unit)
                count = count + 1

            until LineContainsRect(x2, y2, x, y, -4000, -3000, 4000, 5000) == false and IsTerrainWalkable(x, y) and DistanceCoords(x, y, x2, y2) > 2500.

            IssuePointOrder(BossTable[id].unit, "patrol", x, y)
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
        local u = User.first ---@type User 

        AFK_TEXT = GenerateAFKString()
        BlzFrameSetText(AFK_FRAME, "Type -" .. AFK_TEXT)

        while u do
            local pid = u.id

            if HeroID[pid] > 0 then
                if afkTextVisible[pid] then
                    afkTextVisible[pid] = false
                    if GetLocalPlayer() == Player(pid - 1) then
                        BlzFrameSetVisible(AFK_FRAME_BG, false)
                    end
                    PanCameraToTimedLocForPlayer(u.player, TOWN_CENTER, 0)
                    DisplayTextToForce(FORCE_PLAYING, u.nameColored .. " was removed for being AFK.")
                    DisplayTextToPlayer(u.player, 0, 0, "You have lost the game. All of your structures and units will be removed from the game, however you may stay and watch or leave as you choose.")
                    PlayerCleanup(pid)
                elseif panCounter[pid] < 50 or moveCounter[pid] < 5000 or clickCounter[pid] < 200 then
                    afkTextVisible[pid] = true
                    if GetLocalPlayer() == Player(pid - 1) then
                        BlzFrameSetVisible(AFK_FRAME_BG, true)
                    end
                    SoundHandler("Sound\\Interface\\SecretFound.wav", false, Player(pid - 1), nil)
                end
            end

            moveCounter[pid] = 0
            panCounter[pid] = 0
            clickCounter[pid] = 0

            u = u.next
        end
    end

    local fountain_filter = Filter(function()
        local id = GetUnitTypeId(GetFilterUnit())

        return (id ~= BACKPACK)
    end)

    ---@type fun(i: integer)
    local function BossBonusLinger(i)
        if CHAOS_LOADING == false and UnitAlive(BossTable[i].unit) then
            local numplayers = 0

            for j = 1, #HERO_GROUP do
                if IsUnitInRange(HERO_GROUP[j], BossTable[i].unit, NEARBY_BOSS_RANGE) then
                    numplayers = numplayers + 1
                end
            end

            BossNearbyPlayers[i] = numplayers
        end
    end

    local function OneSecond()
        local hp = 0.
        local mp = 0.

        TIME = TIME + 1

        --clock frame
        BlzFrameSetText(CLOCK_FRAME_TEXT, IntegerToTime(TIME))

        --set space bar camera to town
        SetCameraQuickPositionLoc(TOWN_CENTER)

        --fountain regeneration
        local ug = CreateGroup()
        GroupEnumUnitsInRange(ug, -260., 350., 600., fountain_filter)

        for target in each(ug) do
            hp = GetWidgetLife(target)
            mp = GetUnitState(target, UNIT_STATE_MANA)

            if hp < BlzGetUnitMaxHP(target) * 0.99 then
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", target, "origin"))
                SetWidgetLife(target, hp + BlzGetUnitMaxHP(target))
            end

            if mp < BlzGetUnitMaxMana(target) * 0.99 and GetUnitTypeId(target) ~= HERO_VAMPIRE then
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIma\\AImaTarget.mdl", target, "origin"))
                SetUnitState(target, UNIT_STATE_MANA, GetUnitState(target, UNIT_STATE_MANA) + BlzGetUnitMaxMana(target))
            end
        end

        --boss regeneration / player scaling / reset
        for i = BOSS_OFFSET, #BossTable do
            if CHAOS_LOADING == false and UnitAlive(BossTable[i].unit) then

                --zeppelin kill
                if CHAOS_MODE and IsUnitInRangeLoc(BossTable[i].unit, BossTable[i].loc, 1500.) then
                    GroupEnumUnitsInRange(ug, GetUnitX(BossTable[i].unit), GetUnitY(BossTable[i].unit), 900., Condition(iszeppelin))

                    for target in each(ug) do
                        ExpireUnit(target)
                    end
                    if BlzGroupGetSize(ug) > 0 then
                        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(BossTable[i].unit), GetUnitY(BossTable[i].unit)))
                        SetUnitAnimation(BossTable[i].unit, "attack slam")
                    end
                end

                --death knight / legion exception
                if BossTable[i].id ~= FourCC('H04R') and BossTable[i].id ~= FourCC('H040') then
                    if IsUnitInRangeLoc(BossTable[i].unit, BossTable[i].loc, BossTable[i].leash) == false and GetUnitAbilityLevel(BossTable[i].unit, FourCC('Amrf')) == 0 then
                        hp = Unit[BossTable[i].unit].str * 25. * 0.16
                        if GetUnitAbilityLevel(BossTable[i].unit, FourCC('Asan')) > 0 then
                            hp = hp * 0.5
                        end
                        Unit[BossTable[i].unit].regen = hp
                        Unit[BossTable[i].unit].overmovespeed = 750
                        UnitAddAbility(BossTable[i].unit, FourCC('Amrf'))
                        SetUnitPathing(BossTable[i].unit, false)
                        SetUnitTurnSpeed(BossTable[i].unit, 1.)
                        local pt = TimerList[BOSS_ID]:add()
                        pt.id = i
                        pt.timer:callDelayed(0.25, ReturnBoss, pt)
                    end
                end

                --determine number of nearby heroes
                local numplayers = 0
                for j = 1, #HERO_GROUP do
                    if IsUnitInRange(HERO_GROUP[j], BossTable[i].unit, NEARBY_BOSS_RANGE) then
                        numplayers = numplayers + 1
                    end
                end

                BossNearbyPlayers[i] = math.max(BossNearbyPlayers[i], numplayers)

                if numplayers < BossNearbyPlayers[i] then
                    TimerQueue:callDelayed(5., BossBonusLinger, i)
                end

                hp = Unit[BossTable[i].unit].str * 25

                --calculate hp regeneration
                if GetWidgetLife(BossTable[i].unit) <= hp * 0.15 then -- 15 percent hp double regen
                    hp = hp * 2
                end

                if CHAOS_MODE then
                    hp = hp * (0.0001 + 0.0004 * BossNearbyPlayers[i]) --0.04 percent per player
                else
                    hp = hp * 0.002 * BossNearbyPlayers[i] --0.2 percent
                end

                if numplayers == 0 then --out of combat?
                    hp = Unit[BossTable[i].unit].str * 25. * 0.02 --2 percent
                else --bonus damage and health
                    if CHAOS_MODE then
                        UnitSetBonus(BossTable[i].unit, BONUS_DAMAGE, R2I(BlzGetUnitBaseDamage(BossTable[i].unit, 0) * 0.2 * (BossNearbyPlayers[i] - 1)))
                        UnitSetBonus(BossTable[i].unit, BONUS_HERO_STR, R2I(Unit[BossTable[i].unit].str * 0.2 * (BossNearbyPlayers[i] - 1)))
                    end
                end

                --sanctified ground debuff
                if SanctifiedGroundDebuff:has(nil, BossTable[i].unit) then
                    hp = hp * 0.5
                end

                --non-returning hp regeneration
                if GetUnitAbilityLevel(BossTable[i].unit, FourCC('Amrf')) == 0 then
                    Unit[BossTable[i].unit].regen = hp
                end
            end
        end

        --summon regeneration
        for i = 1, #SummonGroup do
            local summon = SummonGroup[i]

            if UnitAlive(summon) and GetUnitAbilityLevel(summon, FourCC('A06Q')) > 0 then
                if GetUnitTypeId(summon) == SUMMON_DESTROYER then
                    Unit[summon].regen = BlzGetUnitMaxHP(summon) * (0.02 + 0.0005 * GetUnitAbilityLevel(summon, FourCC('A06Q')))
                elseif GetUnitTypeId(summon) == SUMMON_HOUND and GetUnitAbilityLevel(summon, FourCC('A06Q')) > 9 then
                    Unit[summon].regen = BlzGetUnitMaxHP(summon) * (0.02 + 0.0005 * GetUnitAbilityLevel(summon, FourCC('A06Q')))
                else
                    Unit[summon].regen = BlzGetUnitMaxHP(summon) * (0.02 + 0.00025 * GetUnitAbilityLevel(summon, FourCC('A06Q')))
                end
            end
        end

        --Undespawn Units
        for i = 1, #despawnGroup do
            local creep = despawnGroup[i]

            if creep ~= nil then
                GroupEnumUnitsInRange(ug, GetUnitX(creep), GetUnitY(creep), 800., Condition(FilterDespawn))
                if BlzGroupGetSize(ug) == 0 then
                    TimerQueue:callDelayed(0.9, Undespawn, creep)
                    despawnGroup[i] = despawnGroup[#despawnGroup]
                    despawnGroup[#despawnGroup] = nil
                    i = i - 1
                end
            end
        end

        --refresh auras, mana costs, etc.
        RefreshHeroes()

        DestroyGroup(ug)
    end

    -- localizing here is great
    local framesetvisible = BlzFrameSetVisible
    local framesettexture = BlzFrameSetTexture
    local getmainselectedunit = GetMainSelectedUnit
    local unititeminslot = UnitItemInSlot

    local function Tick()
        local u = getmainselectedunit() ---@type unit 

        -- rarity item borders
        for i = 0, 5 do
            local itm = Item[unititeminslot(u, i)]

            if itm then
                framesettexture(INVENTORYBACKDROP[i], (SPRITE_RARITY[itm.level]), 0, true)
            end

            framesetvisible(INVENTORYBACKDROP[i], (itm and true) or false)
        end

        framesetvisible(PUNCHING_BAG_UI, u == PUNCHING_BAG)

        -- frame to hide health
        framesetvisible(HIDE_HEALTH_FRAME, (u and Unit[u].noregen))
    end

    TimerQueue:callPeriodically(FPS_64, nil, Tick)
    TimerQueue:callPeriodically(0.35, nil, Periodic)
    TimerQueue:callPeriodically(1.0, nil, OneSecond)
    TimerQueue:callPeriodically(15., nil, WanderingGuys)
    TimerQueue:callPeriodically(15., nil, ColosseumXPDecrease)
    TimerQueue:callPeriodically(60., nil, OneMinute)
    TimerQueue:callPeriodically(240., nil, DisplayHint)
    TimerQueue:callPeriodically(300., nil, CreateWell)
    TimerQueue:callPeriodically(1800., nil, AFKClock)

    WANDER_TIMER:callDelayed(2040. - (User.AmountPlaying * 240), ShadowStepExpire)
end, Debug and Debug.getLine())
