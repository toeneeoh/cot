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
    Require('Multiboard')
    Require('UI')

    HERO_GROUP     = {}
    WANDER_TIMER   = TimerQueue.create()

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

---@type fun(i: integer)
function BossBonusLinger(i)
    if CHAOS_LOADING == false and UnitAlive(BossTable[i].unit) then
        local numplayers = 0

        for _, hero in ipairs(HERO_GROUP) do
            if IsUnitInRange(hero, BossTable[i].unit, NEARBY_BOSS_RANGE) then
                numplayers = numplayers + 1
            end
        end

        BossNearbyPlayers[i] = numplayers
    end
end

---@type fun(pt: PlayerTimer)
function ReturnBoss(pt)
    if UnitAlive(BossTable[pt.id].unit) and not CHAOS_LOADING then
        local angle = Atan2(GetLocationY(BossTable[pt.id].loc) - GetUnitY(BossTable[pt.id].unit), GetLocationX(BossTable[pt.id].loc) - GetUnitX(BossTable[pt.id].unit))
        if IsUnitInRangeLoc(BossTable[pt.id].unit, BossTable[pt.id].loc, 100.) then
            pt:destroy()
            SetUnitMoveSpeed(BossTable[pt.id].unit, GetUnitDefaultMoveSpeed(BossTable[pt.id].unit))
            SetUnitPathing(BossTable[pt.id].unit, true)
            UnitRemoveAbility(BossTable[pt.id].unit, FourCC('Amrf'))
            SetUnitTurnSpeed(BossTable[pt.id].unit, GetUnitDefaultTurnSpeed(BossTable[pt.id].unit))
        else
            SetUnitXBounded(BossTable[pt.id].unit, GetUnitX(BossTable[pt.id].unit) + 20. * Cos(angle))
            SetUnitYBounded(BossTable[pt.id].unit, GetUnitY(BossTable[pt.id].unit) + 20. * Sin(angle))
            IssuePointOrder(BossTable[pt.id].unit, "move", GetUnitX(BossTable[pt.id].unit) + 70. * Cos(angle), GetUnitY(BossTable[pt.id].unit) + 70. * Sin(angle))
            UnitRemoveBuffs(BossTable[pt.id].unit, false, true)
        end

        pt.timer:callDelayed(0.06, ReturnBoss, pt)
    else
        pt:destroy()
    end
end

function Periodic()

    --camera lock
    do
        local pid = GetPlayerId(GetLocalPlayer()) + 1

        if CameraLock[pid] and not selectingHero[pid] then
            SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, Zoom[pid], 0)
        end
    end

    --player loop
    local u = User.first ---@type User 
    local x, y

    while u do
        local pid = u.id

        if HeroID[pid] > 0 then

            --backpack move
            if not IS_TELEPORTING[pid] then
                x = GetUnitX(Hero[pid]) + 50 * Cos((GetUnitFacing(Hero[pid]) - 45) * bj_DEGTORAD)
                y = GetUnitY(Hero[pid]) + 50 * Sin((GetUnitFacing(Hero[pid]) - 45) * bj_DEGTORAD)
                if IsUnitInRange(Hero[pid], Backpack[pid], 1000.) == false then
                    SetUnitXBounded(Backpack[pid], x)
                    SetUnitYBounded(Backpack[pid], y)
                elseif not bpmoving[pid] or IsUnitInRange(Hero[pid], Backpack[pid], 800.) == false then
                    if IsUnitInRange(Hero[pid], Backpack[pid], 50.) == false then
                        IssuePointOrder(Backpack[pid], "move", x, y)
                    end
                end
            end

            --update life regeneration
            UnitSetBonus(Hero[pid], BONUS_LIFE_REGEN, (Unit[Hero[pid]].noregen == true and 0) or Unit[Hero[pid]].regen * Unit[Hero[pid]].healamp)
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

function ColosseumXPDecrease()
    local u = User.first ---@type User 

    while u do
        if HeroID[u.id] ~= 0 then
            if InColo[u.id] and Colosseum_XP[u.id] > 0.05 then
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

function WanderingGuys()
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
        if not InColo[id] and Colosseum_XP[id] < 1.30 then
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
function GenerateAFKString()
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
                PanCameraToTimedLocForPlayer(u.player, TownCenter, 0)
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

function OneSecond()
    local hp = 0.
    local mp = 0.

    TIME = TIME + 1

    --clock frame
    BlzFrameSetText(CLOCK_FRAME_TEXT, IntegerToTime(TIME))

    --set space bar camera to town
    SetCameraQuickPositionLoc(TownCenter)

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
                    hp = GetHeroStr(BossTable[i].unit, false) * 25 * 0.16
                    if GetUnitAbilityLevel(BossTable[i].unit, FourCC('Asan')) > 0 then
                        hp = hp * 0.5
                    end
                    UnitSetBonus(BossTable[i].unit, BONUS_LIFE_REGEN, hp)
                    UnitAddAbility(BossTable[i].unit, FourCC('Amrf'))
                    SetUnitMoveSpeed(BossTable[i].unit, MOVESPEED.MAX)
                    SetUnitPathing(BossTable[i].unit, false)
                    SetUnitTurnSpeed(BossTable[i].unit, 1.)
                    local pt = TimerList[BOSS_ID]:add()
                    pt.id = i
                    pt.timer:callDelayed(0.06, ReturnBoss, pt)
                end
            end

            --determine number of nearby heroes
            local numplayers = 0
            for _, hero in ipairs(HERO_GROUP) do
                if IsUnitInRange(hero, BossTable[i].unit, NEARBY_BOSS_RANGE) then
                    numplayers = numplayers + 1
                end
            end

            BossNearbyPlayers[i] = IMaxBJ(BossNearbyPlayers[i], numplayers)

            if numplayers < BossNearbyPlayers[i] then
                TimerQueue:callDelayed(5., BossBonusLinger, i)
            end

            hp = GetHeroStr(BossTable[i].unit, false) * 25

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
                hp = GetHeroStr(BossTable[i].unit, false) * 25 * 0.02 --2 percent
            else --bonus damage and health
                if CHAOS_MODE then
                    UnitSetBonus(BossTable[i].unit, BONUS_DAMAGE, R2I(BlzGetUnitBaseDamage(BossTable[i].unit, 0) * 0.2 * (BossNearbyPlayers[i] - 1)))
                    UnitSetBonus(BossTable[i].unit, BONUS_HERO_STR, R2I(GetHeroStr(BossTable[i].unit, false) * 0.2 * (BossNearbyPlayers[i] - 1)))
                end
            end

            --sanctified ground debuff
            if SanctifiedGroundDebuff:has(nil, BossTable[i].unit) then
                hp = hp * 0.5
            end

            --non-returning hp regeneration
            if GetUnitAbilityLevel(BossTable[i].unit, FourCC('Amrf')) == 0 then
                UnitSetBonus(BossTable[i].unit, BONUS_LIFE_REGEN, hp)
            end
        end
    end

    --summon regeneration
    for _, target in ipairs(SummonGroup) do
        if UnitAlive(target) and GetUnitAbilityLevel(target, FourCC('A06Q')) > 0 then
            if GetUnitTypeId(target) == SUMMON_DESTROYER then
                UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.0005 * GetUnitAbilityLevel(target, FourCC('A06Q'))))
            elseif GetUnitTypeId(target) == SUMMON_HOUND and GetUnitAbilityLevel(target, FourCC('A06Q')) > 9 then
                UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.0005 * GetUnitAbilityLevel(target, FourCC('A06Q'))))
            else
                UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.00025 * GetUnitAbilityLevel(target, FourCC('A06Q'))))
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

    --add & remove players in dungeon queue
    if QUEUE_DUNGEON > 0 then
        local p = User.first
        local mb = MULTIBOARD.QUEUE

        while p do
            if IsUnitInRangeXY(Hero[p.id], QUEUE_X, QUEUE_Y, 750.) and UnitAlive(Hero[p.id]) and not IS_TELEPORTING[p.id] then
                if TableHas(QUEUE_GROUP, p.player) == false and GetHeroLevel(Hero[p.id]) >= QUEUE_LEVEL then
                    QUEUE_GROUP[#QUEUE_GROUP + 1] = p.player
                    mb:addRows(1)
                    mb:get(mb.rowCount, 1).text = {0.02, 0, 0.09, 0.011}
                    mb:get(mb.rowCount, 2).icon = {0.26, 0, 0.011, 0.011}
                    mb.available[p.id] = true
                    mb:display(p.id)
                end
            elseif TableHas(QUEUE_GROUP, p.player) then
                TableRemove(QUEUE_GROUP, p.player)
                QUEUE_READY[p.id] = false
                mb:delRows(1)
                mb.available[p.id] = false
                MULTIBOARD.MAIN:display(p.id)

                if #QUEUE_GROUP <= 0 then
                    QUEUE_DUNGEON = 0
                end
            end

            p = p.next
        end

        --Refresh dungeon queue multiboard
        if #QUEUE_GROUP == 0 then
            QUEUE_DUNGEON = 0
        end
    end

    --refresh multiboard bodies
    RefreshMB()

    --refresh auras, mana costs, etc.
    RefreshHeroes()

    DestroyGroup(ug)
end

function Tick()
    local u = GetMainSelectedUnit() ---@type unit 

    --rarity item borders
    for i = 0, 5 do
        local itm = Item[UnitItemInSlot(u, i)]

        if itm then
            BlzFrameSetTexture(INVENTORYBACKDROP[i], SPRITE_RARITY[itm.level], 0, true)
        end

        BlzFrameSetVisible(INVENTORYBACKDROP[i], (itm and true) or false)
    end

    BlzFrameSetVisible(PUNCHING_BAG_UI, u == PUNCHING_BAG)

    --frame to hide health
    BlzFrameSetVisible(HIDE_HEALTH_FRAME, (u and Unit[u].noregen))
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
end, Debug.getLine())
