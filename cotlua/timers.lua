if Debug then Debug.beginFile 'Timers' end

--[[
    timers.lua

    A library that initializes game timers and functions that should run periodically.
    Notable functions:
    Tick() - executes roughly 64 times per second
    Periodic() - executes roughly 3 times per second

    Ideally we try to avoid as too much in periodic functions because performance
    is easily affected in wc3 as a single-threaded game.

    Makes use of the timerqueue library for more fluid callback functionality.
]]

OnInit.final("Timers", function(require)
    require 'Units'
    require 'BossAI'
    require 'MapSetup'
    require 'Buffs'
    require 'BuffSystem'
    require 'Multiboard'

    LAST_HERO_X    = __jarray(0) ---@type number[] 
    LAST_HERO_Y    = __jarray(0) ---@type number[] 
    HeroGroup      = CreateGroup()
    wanderingTimer = CreateTimer() ---@type timer 

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

        for hero in each(HeroGroup) do
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

            --movement speed

            --flat bonuses
            Movespeed[pid] = R2I(GetUnitDefaultMoveSpeed(Hero[pid])) + ItemMovespeed[pid]

            if GetUnitAbilityLevel(Hero[pid], FourCC('B02A')) > 0 then --barrage
                Movespeed[pid] = Movespeed[pid] + 150
            end
            if GetUnitAbilityLevel(Hero[pid], FourCC('B01I')) > 0 then --infused water
                Movespeed[pid] = Movespeed[pid] + 150
            end
            if GetUnitAbilityLevel(Hero[pid], FourCC('B02F')) > 0 then --drum of war
                Movespeed[pid] = Movespeed[pid] + 150
            end
            if GetUnitAbilityLevel(Hero[pid], FourCC('BUau')) > 0 then --blood horn
                Movespeed[pid] = Movespeed[pid] + 75
            end

            --multipliers
            if masterElement[pid] == ELEMENTLIGHTNING.value then --master of elements (lightning)
                Movespeed[pid] = R2I(Movespeed[pid] * 1.4)
            end

            --weather
            if WeatherBuff:has(Hero[pid], Hero[pid]) then
                Movespeed[pid] = R2I(Movespeed[pid] * (1. - WeatherTable[CURRENT_WEATHER].ms * 0.01))
            end

            Movespeed[pid] = Movespeed[pid] + BuffMovespeed[pid]

            if DEV_ENABLED and MS_OVERRIDE then
            elseif Movespeed[pid] > 600 then
                Movespeed[pid] = 600
            end

            --arcanosphere
            local pt = TimerList[pid]:get(ARCANOSPHERE.id)

            if pt and IsUnitInRangeXY(Hero[pid], pt.x, pt.y, 800.)then
                Movespeed[pid] = 1000
            end

            SetUnitMoveSpeed(Hero[pid], math.min(522, Movespeed[pid]))
            SetUnitMoveSpeed(Backpack[pid], Movespeed[pid])

            if sniperstance[pid] then
                Movespeed[pid] = 100
                SetUnitMoveSpeed(Hero[pid], 100)
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

    if UnitAlive(gg_unit_H01Y_0099) then
        x = GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 500, GetRectMaxX(gg_rct_Town_Boundry) - 500)
        y = GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 500, GetRectMaxY(gg_rct_Town_Boundry) - 500)

        IssuePointOrder(gg_unit_H01Y_0099, "move", x, y)
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

    return (id ~= DUMMY and id ~= BACKPACK)
end)

function OneSecond()
    local hp = 0.
    local mp = 0.

    TIME = TIME + 1

    --clock frame
    BlzFrameSetText(clockText, IntegerToTime(TIME))

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

            --death knight / legion exception
            if BossTable[i].id ~= FourCC('H04R') and BossTable[i].id ~= FourCC('H040') then
                if IsUnitInRangeLoc(BossTable[i].unit, BossTable[i].loc, BossTable[i].leash) == false and GetUnitAbilityLevel(BossTable[i].unit, FourCC('Amrf')) == 0 then
                    hp = GetHeroStr(BossTable[i].unit, false) * 25 * 0.16
                    if GetUnitAbilityLevel(BossTable[i].unit, FourCC('Asan')) > 0 then
                        hp = hp * 0.5
                    end
                    UnitSetBonus(BossTable[i].unit, BONUS_LIFE_REGEN, hp)
                    UnitAddAbility(BossTable[i].unit, FourCC('Amrf'))
                    SetUnitMoveSpeed(BossTable[i].unit, 522)
                    SetUnitPathing(BossTable[i].unit, false)
                    SetUnitTurnSpeed(BossTable[i].unit, 1.)
                    local pt = TimerList[BOSS_ID]:add()
                    pt.id = i
                    pt.timer:callDelayed(0.06, ReturnBoss, pt)
                end
            end

            --determine number of nearby heroes
            local numplayers = 0
            for hero in each(HeroGroup) do
                if IsUnitInRange(hero, BossTable[i].unit, NEARBY_BOSS_RANGE) then
                    numplayers = numplayers + 1
                end
            end

            BossNearbyPlayers[i] = IMaxBJ(BossNearbyPlayers[i], numplayers)

            if numplayers < BossNearbyPlayers[i] then
                TimerQueue:callDelayed(5., BossBonusLinger, i)
            end

            --calculate hp regeneration
            if GetWidgetLife(BossTable[i].unit) > GetHeroStr(BossTable[i].unit, false) * 25 * 0.15 then -- > 15 percent
                if CHAOS_MODE then
                    hp = GetHeroStr(BossTable[i].unit, false) * 25 * (0.0001 + 0.0004 * BossNearbyPlayers[i]) --0.04 percent per player
                else
                    hp = GetHeroStr(BossTable[i].unit, false) * 25 * 0.002 * BossNearbyPlayers[i] --0.2 percent
                end
            else
                if CHAOS_MODE then
                    hp = GetHeroStr(BossTable[i].unit, false) * 25 * (0.0002 + 0.0008 * BossNearbyPlayers[i]) --0.08 percent
                else
                    hp = GetHeroStr(BossTable[i].unit, false) * 25 * 0.004 * BossNearbyPlayers[i] --0.4 percent
                end
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

    --zeppelin kill
    if CHAOS_MODE then
        ZeppelinKill()
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

    --player loop
    local p = User.first

    while p do
        --update boost variance every second
        BOOST[p.id] = 1. + BoostValue[p.id] + GetRandomReal(-0.2, 0.2)
        LBOOST[p.id] = 1. + 0.5 * BoostValue[p.id]

        if DEV_ENABLED then
            if BOOST_OFF then
                BOOST[p.id] = (1. + BoostValue[p.id])
            end
        end

        --Cooldowns

        if HeroID[p.id] > 0 then
            UpdateManaCosts(p.id)

            --intense focus
            if (HasProficiency(p.id, PROF_BOW) and
                GetUnitAbilityLevel(Hero[p.id], FourCC('A0B9')) > 0 and
                UnitAlive(Hero[p.id]) and
                LAST_HERO_X[p.id] == GetUnitX(Hero[p.id]) and
                LAST_HERO_Y[p.id] == GetUnitY(Hero[p.id]))
            then
                IntenseFocus[p.id] = IMinBJ(10, IntenseFocus[p.id] + 1)
            else
                IntenseFocus[p.id] = 0
            end

            --keep track of hero positions
            LAST_HERO_X[p.id] = GetUnitX(Hero[p.id])
            LAST_HERO_Y[p.id] = GetUnitY(Hero[p.id])

            --PVP leave range
            if ArenaQueue[p.id] > 0 and IsUnitInRangeXY(Hero[p.id], -1311., 2905., 1000.) == false then
                ArenaQueue[p.id] = 0
                DisplayTimedTextToPlayer(p.player, 0, 0, 5.0, "You have been removed from the PvP queue.")
            end

            hp = GetWidgetLife(Hero[p.id]) / BlzGetUnitMaxHP(Hero[p.id]) * 100

            --backpack hp/mp percentage
            if hp >= 1 then
                hp = GetWidgetLife(Hero[p.id]) / BlzGetUnitMaxHP(Hero[p.id])
                SetUnitState(Backpack[p.id], UNIT_STATE_LIFE, BlzGetUnitMaxHP(Backpack[p.id]) * hp)
                mp = GetUnitState(Hero[p.id], UNIT_STATE_MANA) / GetUnitState(Hero[p.id], UNIT_STATE_MAX_MANA)
                SetUnitState(Backpack[p.id], UNIT_STATE_MANA, GetUnitState(Backpack[p.id], UNIT_STATE_MAX_MANA) * mp)
            end

            --tooltips
            UpdateSpellTooltips(p.id)

            --TODO for now use 900 as default aura range
            MakeGroupInRange(p.id, ug, GetUnitX(Hero[p.id]), GetUnitY(Hero[p.id]), 900. * LBOOST[p.id], Condition(isalive))

            for target in each(ug) do
                if IsUnitAlly(target, Player(p.id - 1)) then
                    if InspireBuff:has(Hero[p.id], Hero[p.id]) then
                        InspireBuff:add(Hero[p.id], target):duration(1.)
                        local b = InspireBuff:get(nil, target)
                        b:strongest(math.max(b.ablev, GetUnitAbilityLevel(Hero[p.id], INSPIRE.id)))
                    end
                    if BardSong[p.id] == SONG_WAR then
                        SongOfWarBuff:add(Hero[p.id], target)
                        SongOfWarBuff:refresh(Hero[p.id], target, 2.)
                    end
                    if GetUnitAbilityLevel(Hero[p.id], PROTECTOR.id) > 0 then
                        ProtectedBuff:add(Hero[p.id], target):duration(2.)
                    end
                    if FightMeCasterBuff:has(Hero[p.id], Hero[p.id]) and target ~= Hero[p.id] then
                        FightMeBuff:add(Hero[p.id], target):duration(2.)
                    end
                    if GetUnitAbilityLevel(Hero[p.id], AURAOFJUSTICE.id) > 0 then
                        JusticeAuraBuff:add(Hero[p.id], target):duration(2.)
                        local b = JusticeAuraBuff:get(nil, target)
                        b:strongest(math.max(b.ablev, GetUnitAbilityLevel(Hero[p.id], AURAOFJUSTICE.id)))
                    end
                elseif IsUnitAlly(target, Player(p.id - 1)) == false and UnitIsSleeping(target) == false then
                    if BardSong[p.id] == SONG_FATIGUE then
                        SongOfFatigueSlow:add(Hero[p.id], target):duration(2.)
                    elseif masterElement[p.id] == ELEMENTICE.value then
                        IceElementSlow:add(Hero[p.id], target):duration(2.)
                    end
                end
            end
        end

        p = p.next
    end

    DestroyGroup(ug)
end

function Tick()
    local u = GetMainSelectedUnit() ---@type unit 
    local id = GetPlayerId(GetLocalPlayer()) + 1
    local order = GetUnitCurrentOrder(Hero[id])

    --determine if a player hero is moving
    Moving[id] = (UnitAlive(Hero[id]) and not IsUnitStunned(Hero[id]) and GetUnitAbilityLevel(Hero[id], FourCC('BEer')) == 0)
    --stop, holdposition, or nil
    and (order ~= 851972 and order ~= 851993 and order ~= 0)
    --attack or smart
    if (order == 851983 or order == 851971) then
        if LAST_ORDER_TARGET[id] and UnitDistance(Hero[id], LAST_ORDER_TARGET[id]) - BlzGetUnitCollisionSize(LAST_ORDER_TARGET[id]) <= BlzGetUnitWeaponRealField(Hero[id], UNIT_WEAPON_RF_ATTACK_RANGE, 0) then
            Moving[id] = false
        end
    elseif DistanceCoords(clickedPoint[id][1], clickedPoint[id][2], GetUnitX(Hero[id]), GetUnitY(Hero[id])) <= 55. then
        Moving[id] = false
    end

    --movement above 522
    local U = User.first ---@type User 

    while U do
        local ms = Movespeed[U.id] - 522

        if Moving[U.id] and ms > 0 then
            local x = GetUnitX(Hero[U.id])
            local y = GetUnitY(Hero[U.id])
            local dist = DistanceCoords(x, y, clickedPoint[U.id][1], clickedPoint[U.id][2])
            local facing = GetUnitFacing(Hero[U.id])
            x = x + ((ms * 0.01) + 1) * Cos(bj_DEGTORAD * facing)
            y = y + ((ms * 0.01) + 1) * Sin(bj_DEGTORAD * facing)
            if dist > ms * 0.01 and IsTerrainWalkable(x, y) then
                SetUnitXBounded(Hero[U.id], x)
                SetUnitYBounded(Hero[U.id], y)
            end
        end

        U = U.next
    end

    --rarity item borders
    for i = 0, 5 do
        local itm = Item[UnitItemInSlot(u, i)]

        if itm then
            BlzFrameSetTexture(INVENTORYBACKDROP[i], SPRITE_RARITY[itm.level], 0, true)
            BlzFrameSetVisible(INVENTORYBACKDROP[i], true)
        else
            BlzFrameSetVisible(INVENTORYBACKDROP[i], false)
        end
    end

    BlzFrameSetVisible(PUNCHING_BAG_UI, u == PUNCHING_BAG)

    --frame to hide health
    BlzFrameSetVisible(hideHealth, (u and Unit[u].noregen))
end

    local wandering = CreateTrigger()

    TimerQueue:callPeriodically(FPS_64, nil, Tick)
    TimerQueue:callPeriodically(0.35, nil, Periodic)
    TimerQueue:callPeriodically(1.0, nil, OneSecond)
    TimerQueue:callPeriodically(15., nil, WanderingGuys)
    TimerQueue:callPeriodically(15., nil, ColosseumXPDecrease)
    TimerQueue:callPeriodically(60., nil, OneMinute)
    TimerQueue:callPeriodically(240., nil, DisplayHint)
    TimerQueue:callPeriodically(300., nil, CreateWell)
    TimerQueue:callPeriodically(1800., nil, AFKClock)

    TriggerRegisterTimerExpireEvent(wandering, wanderingTimer)
    TimerStart(wanderingTimer, 2040. - (User.AmountPlaying * 240), true, ShadowStepExpire)
end)

if Debug then Debug.endFile() end
