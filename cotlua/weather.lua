--[[
    weather.lua

    A module that defines random weather behavior and effects.
]]

if Debug then Debug.beginFile 'Weather' end

OnInit.global("Weather", function(require)
    require 'Helper'
    require 'Variables'
    require 'TimerQueue'
    require 'Buffs'

    WeatherTimer = TimerQueue.create()
    WeatherTable = {}
    WeatherGroup = {}

    WEATHER_HURRICANE           = 1
    WEATHER_CHAOTIC_HURRICANE   = 2
    WEATHER_SNOW                = 3
    WEATHER_CHAOTIC_SNOW        = 4
    WEATHER_FOG                 = 5
    WEATHER_CHAOTIC_FOG         = 6
    WEATHER_RAIN                = 7
    WEATHER_CHAOTIC_RAIN        = 8
    WEATHER_CLEAR               = 9
    WEATHER_SUNNY               = 10
    WEATHER_DIVINE_GRACE        = 11
    WEATHER_SIPHONING_MIST      = 12
    WEATHER_FIRESTORM           = 13
    WEATHER_SOLAR_FLARE         = 14
    WEATHER_SAND_STORM          = 15
    WEATHER_MAX                 = 15

    donationrate  = 0.1
    donation      = 1.

    CURRENT_WEATHER     = WEATHER_CLEAR
    firestormRate       = 4
    weatherIterations   = 0

---@type fun(x: number, y: number)
function FirestormDamage(x, y)
    local ug = CreateGroup()

    GroupEnumUnitsInRange(ug, x, y, 300, Condition(isplayerAlly))
    DestroyTreesInRange(x, y, 300)

    for target in each(ug) do
        DamageTarget(DummyUnit, target, BlzGetUnitMaxHP(target) * .1, ATTACK_TYPE_NORMAL, PURE, "Firestorm")
    end

    DestroyGroup(ug)
end

---@type fun(pt: PlayerTimer)
function FirestormEffect(pt)
    local ug = CreateGroup()
    local x  = 0. ---@type number 
    local y  = 0. ---@type number 

    pt.dur = pt.dur - 3

    if pt.dur > 0 then
        for _ = 0, firestormRate do
            repeat
                x = GetRandomReal(MAIN_MAP.minX, MAIN_MAP.maxX)
                y = GetRandomReal(MAIN_MAP.minY, MAIN_MAP.maxY)
                GroupEnumUnitsInRange(ug, x, y, 4000., Condition(isbase))
            until RectContainsCoords(gg_rct_NoSin, x, y) == false and BlzGroupGetSize(ug) == 0
            TimerQueue:callDelayed(1.5, FirestormDamage, x, y)
            DestroyEffect(AddSpecialEffect("Units\\Demon\\Infernal\\InfernalBirth.mdl", x, y))
        end
    else
        pt:destroy()
    end

    DestroyGroup(ug)
end

---@type fun(weather: integer)
function GracePeriod(weather)
    CURRENT_WEATHER = weather

    WeatherBuff.RAWCODE = WeatherTable[weather].abil
    WeatherTimer:callDelayed(WeatherTable[weather].dur, WeatherPeriodic)

    for i = 1, #WeatherGroup do
        if GetPlayerId(GetOwningPlayer(WeatherGroup[i])) < PLAYER_CAP or WeatherTable[CURRENT_WEATHER].all == 1 then
            WeatherBuff:add(WeatherGroup[i], WeatherGroup[i]):duration(WeatherTable[weather].dur)
        end
    end

    if CURRENT_WEATHER == WEATHER_FIRESTORM then
        local pt = TimerList[0]:add() ---@type PlayerTimer
        pt.dur = WeatherTable[weather].dur
        pt.timer:callPeriodically(3., nil, FirestormEffect, pt)
    end
end

function WeatherPeriodic()
    local time = GetTimeOfDay()

    weatherIterations = weatherIterations + 1

    --setup weather pool
    local pool = {}
    for i = 1, WEATHER_MAX do
        local valid = true

        --restrict weather types
        if (CHAOS_MODE and WeatherTable[i].chaos == -1) or (not CHAOS_MODE and WeatherTable[i].chaos == 1) then
            valid = false
        --no sunny weather at night
        elseif i == WEATHER_SUNNY and (time < 6 or time > 15) then
            valid = false
        --do not repeat bad weather
        elseif WeatherTable[CURRENT_WEATHER].bad == 1 and WeatherTable[i].bad == 1 then
            valid = false
        --prevent bad weather for first 5 iterations of lobby
        elseif weatherIterations <= 5 and WeatherTable[i].bad == 1 then
            valid = false
        end

        if valid then
            pool[#pool + 1] = i
        end
    end

    --select weather based on chance
    local choice = 0
    repeat
        choice = pool[GetRandomInt(1, #pool)]
        local chance = WeatherTable[choice].chance

        if WeatherTable[choice].bad == 1 then
            chance = chance * donation
        end

        if GetRandomInt(0, 99) <= chance then
            choice = 0
        end
    until choice > 0

    if DEV_ENABLED then
        if WEATHER_OVERRIDE > 0 then
            choice = WEATHER_OVERRIDE
            WEATHER_OVERRIDE = 0
        end
    end

    DisplayTimedTextToForce(FORCE_PLAYING, 30, "|cff6666ff" .. WeatherTable[choice].text .. "|r")

    WeatherBuff:removeAll()
    WeatherTimer:callDelayed(4., GracePeriod, choice)
end

local function WeatherFilter()
    local u = GetFilterUnit()

    if u and GetUnitTypeId(u) ~= DUMMY then
        if RectContainsUnit(MAIN_MAP.rect, u) then
            if not TableHas(WeatherGroup, u) then
                if GetPlayerId(GetOwningPlayer(u)) < PLAYER_CAP or WeatherTable[CURRENT_WEATHER].all == 1 then
                    WeatherBuff:add(u, u):duration(TimerGetRemaining(WeatherTimer.timer))
                end
                WeatherGroup[#WeatherGroup + 1] = u
            end
        else
            WeatherBuff:dispel(u, u)
            TableRemove(WeatherGroup, u)
        end
    end

    return false
end

    -- Hurricane
    WeatherTable[WEATHER_HURRICANE] = {
        text = "The winds begin to pick up...",
        abil = FourCC('Whur'),
        dur = 120,
        as = 20,
        ms = 20,
        chance = 5,
        chaos = -1,
        bad = 1,
        fog = 50,
        red = 170,
        green = 170,
        blue = 210,
    }
    -- Chaotic Hurricane
    WeatherTable[WEATHER_CHAOTIC_HURRICANE] = {
        text = "The winds begin to pick up...",
        abil = FourCC('WChu'),
        dur = 120,
        as = 25,
        ms = 25,
        chance = 5,
        chaos = 1,
        bad = 1,
        fog = 50,
        red = 255,
        green = 100,
        blue = 100,
    }
    -- Snow
    WeatherTable[WEATHER_SNOW] = {
        text = "It is snowing.",
        abil = FourCC('Wsno'),
        dur = 180,
        as = 15,
        ms = 15,
        chance = 20,
        chaos = -1,
        bad = 1,
        fog = 75,
        red = 255,
        green = 255,
        blue = 255,
    }
    -- Chaotic Snow
    WeatherTable[WEATHER_CHAOTIC_SNOW] = {
        text = "It is snowing.",
        abil = FourCC('WCsn'),
        dur = 180,
        as = 20,
        ms = 20,
        chance = 20,
        chaos = 1,
        bad = 1,
        fog = 75,
        red = 255,
        green = 50,
        blue = 50,
    }
    -- Fog
    WeatherTable[WEATHER_FOG] = {
        text = "It is getting foggy.",
        abil = FourCC('Wfog'),
        dur = 180,
        chance = 20,
        chaos = -1,
        bad = 1,
        fog = 100,
        red = 200,
        green = 200,
        blue = 200,
        buff = FourCC('ASig'),
    }
    -- Chaotic Fog
    WeatherTable[WEATHER_CHAOTIC_FOG] = {
        text = "It is getting foggy.",
        abil = FourCC('WCfo'),
        dur = 180,
        chance = 20,
        chaos = 1,
        bad = 1,
        fog = 100,
        red = 255,
        green = 50,
        blue = 50,
        buff = FourCC('ASig'),
    }
    -- Rain
    WeatherTable[WEATHER_RAIN] = {
        text = "It is raining.",
        abil = FourCC('Wrai'),
        dur = 180,
        chance = 20,
        chaos = -1,
        bad = 1,
        boost = -5,
        fog = 50,
        red = 150,
        green = 150,
        blue = 255,
    }
    -- Chaotic Rain
    WeatherTable[WEATHER_CHAOTIC_RAIN] = {
        text = "It is raining.",
        abil = FourCC('WCra'),
        dur = 180,
        chance = 20,
        chaos = 1,
        bad = 1,
        boost = -10,
        fog = 50,
        red = 255,
        green = 30,
        blue = 120,
    }
    -- Clear
    WeatherTable[WEATHER_CLEAR] = {
        text = "The skies are clear.",
        abil = FourCC('Wcle'),
        dur = 600,
        chance = 40,
    }
    -- Sunny
    WeatherTable[WEATHER_SUNNY] = {
        text = "It is a sunny day.",
        abil = FourCC('Wsun'),
        dur = 300,
        ms = -50,
        as = -15,
        chance = 20,
        fog = 10,
        red = 230,
        green = 255,
        blue = 0,
    }
    -- Divine Grace
    WeatherTable[WEATHER_DIVINE_GRACE] = {
        text = "It is a blessed day.",
        abil = FourCC('Wdiv'),
        dur = 300,
        ms = -50,
        as = -30,
        chance = 5,
        fog = 35,
        red = 230,
        green = 255,
        blue = 0,
    }
    -- Siphoning Mist
    WeatherTable[WEATHER_SIPHONING_MIST] = {
        text = "A mist rolls in...",
        abil = FourCC('Wmis'),
        dur = 300,
        as = -50,
        chance = 10,
        boost = -20,
        fog = 50,
        red = 50,
        green = 255,
        blue = 255,
    }
    -- Firestorm
    WeatherTable[WEATHER_FIRESTORM] = {
        text = "Fire rains from the sky...",
        abil = FourCC('Wfir'),
        dur = 300,
        chance = 10,
        boost = 30,
        chaos = 1,
        dr = -25,
        fog = 35,
        red = 255,
        green = 150,
        blue = 0,
    }
    -- Solar Flare
    WeatherTable[WEATHER_SOLAR_FLARE] = {
        text = "Flares cross the horizon...",
        abil = FourCC('Wsol'),
        dur = 300,
        chance = 10,
        atk = 20,
        fog = 35,
        red = 255,
        green = 50,
        blue = 50,
    }
    -- Sand Storm
    WeatherTable[WEATHER_SAND_STORM] = {
        text = "Dust accumulates in the air...",
        abil = FourCC('Wsan'),
        dur = 300,
        chance = 10,
        dr = -20,
        fog = 40,
        red = 150,
        green = 75,
        blue = 0,
        all = 1,
    }

    for i = 1, WEATHER_MAX do
        setmetatable(WeatherTable[i], { __index = function(tbl, key) return 0 end})
    end

    WeatherTimer:callDelayed(WeatherTable[CURRENT_WEATHER].dur, WeatherPeriodic)

    local ug = CreateGroup()
    local onEnter = CreateTrigger()

    TriggerRegisterEnterRegion(onEnter, MAIN_MAP.region, Filter(WeatherFilter))
    TriggerRegisterLeaveRegion(onEnter, MAIN_MAP.region, Filter(WeatherFilter))

    DestroyGroup(ug)
end)

if Debug then Debug.endFile() end
