if Debug then Debug.beginFile 'Weather' end

OnInit.final("Weather", function(require)
    require 'Variables'

    WeatherTable = {}---@type table 

    WEATHER_TEXT         = 0 ---@type integer 
    WEATHER_ABIL         = 1 ---@type integer 
    WEATHER_DUR         = 2 ---@type integer 
    WEATHER_AS_SLOW         = 3 ---@type integer 
    WEATHER_MS_SLOW         = 4 ---@type integer 
    WEATHER_CHANCE         = 5 ---@type integer 
    WEATHER_CHAOS         = 6 ---@type integer 
    WEATHER_BOOST         = 7 ---@type integer 
    WEATHER_DR         = 8 ---@type integer 
    WEATHER_ATK         = 9 ---@type integer 
    WEATHER_BAD         = 10 ---@type integer 
    WEATHER_FOG         = 11 ---@type integer 
    WEATHER_RED         = 12 ---@type integer 
    WEATHER_GREEN         = 13 ---@type integer 
    WEATHER_BLUE         = 14 ---@type integer 
    WEATHER_BUFF         = 15 ---@type integer 
    WEATHER_ALL         = 16 ---@type integer 

    WEATHER_CLEAR         = 9 ---@type integer 
    WEATHER_SUNNY         = 10 ---@type integer 
    WEATHER_FIRESTORM         = 13 ---@type integer 

    donationrate      = 0.1 ---@type number 
    donation      = 1. ---@type number 
    WEATHER_MAX         = 0 ---@type integer 

    WeatherTimer       = CreateTimer() ---@type timer 
    WeatherUnit      = nil ---@type unit 
    CURRENT_WEATHER         = 9 ---@type integer 
    firestormRate         = 4 ---@type integer 
    weatherIterations         = 0 ---@type integer 

    local FIRSTTIME         = true ---@type boolean 

---@type fun(x: number, y: number)
function FirestormDamage(x, y)
    local ug = CreateGroup()

    GroupEnumUnitsInRange(ug, x, y, 300, isplayerAlly)
    DestroyTreesInRange(x, y, 300)

    local target = FirstOfGroup(ug)
    while target do
        GroupRemoveUnit(ug, target)
        UnitDamageTarget(WeatherUnit, target, BlzGetUnitMaxHP(target) * .1, true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)
        target = FirstOfGroup(ug)
    end

    DestroyGroup(ug)
end

---@type fun(pt: PlayerTimer)
function FirestormEffect(pt)
    local ug       = CreateGroup()
    local x      = 0. ---@type number 
    local y      = 0. ---@type number 

    pt.dur = pt.dur - 3

    if dur > 0 then
        for i = 0, firestormRate do
            repeat
                x = GetRandomReal(GetRectMinX(gg_rct_Main_Map), GetRectMaxX(gg_rct_Main_Map))
                y = GetRandomReal(GetRectMinY(gg_rct_Main_Map), GetRectMaxY(gg_rct_Main_Map))
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

---@type fun(i: integer)
function GracePeriod(i)
    CURRENT_WEATHER = i

    UnitAddAbility(WeatherUnit, WeatherTable[i][WEATHER_ABIL])
    TimerStart(WeatherTimer, WeatherTable[i][WEATHER_DUR], false, nil)

    if CURRENT_WEATHER == WEATHER_FIRESTORM then
        local pt = TimerList[0]:add()
        pt.dur = WeatherTable[i][WEATHER_DUR]
        TimerQueue:callPeriodically(3., FirestormEffect, pt)
    end
end

function WeatherPeriodic()
    local i         = 1 ---@type integer 
    local i2         = 0 ---@type integer 
    local valid         = false ---@type boolean 
    local choice         = 0 ---@type integer 
    local time      = GetTimeOfDay() ---@type number 
    local pool=__jarray(0) ---@type integer[]
    local chance      = 0. ---@type number 

    weatherIterations = weatherIterations + 1

    UnitRemoveAbility(WeatherUnit, WeatherTable[CURRENT_WEATHER][WEATHER_ABIL])

    --setup weather pool
    while i <= WEATHER_MAX do

        valid = true

        --restrict weather types
        if (ChaosMode and WeatherTable[i][WEATHER_CHAOS] == -1) or (not ChaosMode and WeatherTable[i][WEATHER_CHAOS] == 1) then
            valid = false
        --no sunny weather at night
        elseif i == WEATHER_SUNNY and (time < 6 or time > 15) then
            valid = false
        --do not repeat bad weather
        elseif WeatherTable[CURRENT_WEATHER][WEATHER_BAD] == 1 and WeatherTable[i][WEATHER_BAD] == 1 then
            valid = false
        --prevent bad weather for first 5 iterations of lobby
        elseif weatherIterations <= 5 and WeatherTable[i][WEATHER_BAD] == 1 then
            valid = false
        end

        if valid then
            i2 = i2 + 1
            pool[i2] = i
        end

        i = i + 1
    end

    i = 0

    --select weather based on chance
    while choice <= 0 do

        choice = pool[GetRandomInt(1, i2)]
        chance = WeatherTable[choice][WEATHER_CHANCE]

        if WeatherTable[choice][WEATHER_BAD] == 1 then
            chance = chance * donation
        end

        if GetRandomInt(0, 99) >= chance then
            choice = 0
        end

        i = i + 1
    end

    if LIBRARY_dev then
        if WEATHER_OVERRIDE > 0 then
            choice = WEATHER_OVERRIDE
            WEATHER_OVERRIDE = 0
        end
    end

    if FIRSTTIME then
        FIRSTTIME = false
        choice = WEATHER_CLEAR
    else
        DisplayTimedTextToForce(FORCE_PLAYING, 30, "|cff6666ff" .. WeatherTable[choice][WEATHER_TEXT])
    end

    TimerQueue:callDelayed(5., GracePeriod, choice)
end

    local weather         = CreateTrigger() ---@type trigger 
    local i         = 1 ---@type integer 

    TriggerRegisterTimerExpireEvent(weather, WeatherTimer)
    TriggerAddAction(weather, WeatherPeriodic)

    WeatherUnit = gg_unit_h05E_0717

    --hurricane
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "The winds begin to pick up..."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S008')
    WeatherTable[i][WEATHER_DUR] = 120
    WeatherTable[i][WEATHER_AS_SLOW] = 20
    WeatherTable[i][WEATHER_MS_SLOW] = 20
    WeatherTable[i][WEATHER_CHANCE] = 5
    WeatherTable[i][WEATHER_CHAOS] = -1
    WeatherTable[i][WEATHER_BAD] = 1
    WeatherTable[i][WEATHER_FOG] = 50
    WeatherTable[i][WEATHER_RED] = 170
    WeatherTable[i][WEATHER_GREEN] = 170
    WeatherTable[i][WEATHER_BLUE] = 210
    --chaotic hurricane
    i = 2
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "The winds begin to pick up..."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S00E')
    WeatherTable[i][WEATHER_DUR] = 120
    WeatherTable[i][WEATHER_AS_SLOW] = 25
    WeatherTable[i][WEATHER_MS_SLOW] = 25
    WeatherTable[i][WEATHER_CHANCE] = 5
    WeatherTable[i][WEATHER_CHAOS] = 1
    WeatherTable[i][WEATHER_BAD] = 1
    WeatherTable[i][WEATHER_FOG] = 50
    WeatherTable[i][WEATHER_RED] = 255
    WeatherTable[i][WEATHER_GREEN] = 100
    WeatherTable[i][WEATHER_BLUE] = 100
    --snow
    i = 3
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "It is snowing."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S002')
    WeatherTable[i][WEATHER_DUR] = 180
    WeatherTable[i][WEATHER_AS_SLOW] = 15
    WeatherTable[i][WEATHER_MS_SLOW] = 15
    WeatherTable[i][WEATHER_CHANCE] = 20
    WeatherTable[i][WEATHER_CHAOS] = -1
    WeatherTable[i][WEATHER_BAD] = 1
    WeatherTable[i][WEATHER_FOG] = 75
    WeatherTable[i][WEATHER_RED] = 255
    WeatherTable[i][WEATHER_GREEN] = 255
    WeatherTable[i][WEATHER_BLUE] = 255
    --chaotic snow
    i = 4
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "It is snowing."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S00G')
    WeatherTable[i][WEATHER_DUR] = 180
    WeatherTable[i][WEATHER_AS_SLOW] = 20
    WeatherTable[i][WEATHER_MS_SLOW] = 20
    WeatherTable[i][WEATHER_CHANCE] = 20
    WeatherTable[i][WEATHER_CHAOS] = 1
    WeatherTable[i][WEATHER_BAD] = 1
    WeatherTable[i][WEATHER_FOG] = 75
    WeatherTable[i][WEATHER_RED] = 255
    WeatherTable[i][WEATHER_GREEN] = 50
    WeatherTable[i][WEATHER_BLUE] = 50
    --fog
    i = 5
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "It is getting foggy."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S009')
    WeatherTable[i][WEATHER_DUR] = 180
    WeatherTable[i][WEATHER_CHANCE] = 20
    WeatherTable[i][WEATHER_CHAOS] = -1
    WeatherTable[i][WEATHER_BAD] = 1
    WeatherTable[i][WEATHER_FOG] = 100
    WeatherTable[i][WEATHER_RED] = 200
    WeatherTable[i][WEATHER_GREEN] = 200
    WeatherTable[i][WEATHER_BLUE] = 200
    WeatherTable[i][WEATHER_BUFF] = FourCC('ASig')
    --chaotic fog
    i = 6
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "It is getting foggy."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S00B')
    WeatherTable[i][WEATHER_DUR] = 180
    WeatherTable[i][WEATHER_CHANCE] = 20
    WeatherTable[i][WEATHER_CHAOS] = 1
    WeatherTable[i][WEATHER_BAD] = 1
    WeatherTable[i][WEATHER_FOG] = 100
    WeatherTable[i][WEATHER_RED] = 255
    WeatherTable[i][WEATHER_GREEN] = 50
    WeatherTable[i][WEATHER_BLUE] = 50
    WeatherTable[i][WEATHER_BUFF] = FourCC('ASig')
    --rain
    i = 7
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "It is raining."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S004')
    WeatherTable[i][WEATHER_DUR] = 180
    WeatherTable[i][WEATHER_CHANCE] = 20
    WeatherTable[i][WEATHER_CHAOS] = -1
    WeatherTable[i][WEATHER_BAD] = 1
    WeatherTable[i][WEATHER_BOOST] = -5
    WeatherTable[i][WEATHER_FOG] = 50
    WeatherTable[i][WEATHER_RED] = 150
    WeatherTable[i][WEATHER_GREEN] = 150
    WeatherTable[i][WEATHER_BLUE] = 255
    --chaotic rain
    i = 8
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "It is raining."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S00C')
    WeatherTable[i][WEATHER_DUR] = 180
    WeatherTable[i][WEATHER_CHANCE] = 20
    WeatherTable[i][WEATHER_CHAOS] = 1
    WeatherTable[i][WEATHER_BAD] = 1
    WeatherTable[i][WEATHER_BOOST] = -10
    WeatherTable[i][WEATHER_FOG] = 50
    WeatherTable[i][WEATHER_RED] = 255
    WeatherTable[i][WEATHER_GREEN] = 30
    WeatherTable[i][WEATHER_BLUE] = 120
    --clear
    i = WEATHER_CLEAR
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "The skies are clear."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S007')
    WeatherTable[i][WEATHER_DUR] = 600
    WeatherTable[i][WEATHER_CHANCE] = 40
    --sunny
    i = WEATHER_SUNNY
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "It is a sunny day."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S006')
    WeatherTable[i][WEATHER_DUR] = 300
    WeatherTable[i][WEATHER_MS_SLOW] = -50
    WeatherTable[i][WEATHER_AS_SLOW] = -15
    WeatherTable[i][WEATHER_CHANCE] = 20
    WeatherTable[i][WEATHER_FOG] = 10
    WeatherTable[i][WEATHER_RED] = 230
    WeatherTable[i][WEATHER_GREEN] = 255
    WeatherTable[i][WEATHER_BLUE] = 0
    --divine grace
    i = 11
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "It is a blessed day."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S00A')
    WeatherTable[i][WEATHER_DUR] = 300
    WeatherTable[i][WEATHER_MS_SLOW] = -50
    WeatherTable[i][WEATHER_AS_SLOW] = -30
    WeatherTable[i][WEATHER_CHANCE] = 5
    WeatherTable[i][WEATHER_FOG] = 35
    WeatherTable[i][WEATHER_RED] = 230
    WeatherTable[i][WEATHER_GREEN] = 255
    WeatherTable[i][WEATHER_BLUE] = 0
    --siphoning mist
    i = 12
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "A mist rolls in..."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S00F')
    WeatherTable[i][WEATHER_DUR] = 300
    WeatherTable[i][WEATHER_AS_SLOW] = -50
    WeatherTable[i][WEATHER_CHANCE] = 10
    WeatherTable[i][WEATHER_BOOST] = -20
    WeatherTable[i][WEATHER_FOG] = 50
    WeatherTable[i][WEATHER_RED] = 50
    WeatherTable[i][WEATHER_GREEN] = 255
    WeatherTable[i][WEATHER_BLUE] = 255
    --firestorm
    i = WEATHER_FIRESTORM
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "Fire rains from the sky..."
    WeatherTable[i][WEATHER_ABIL] = FourCC('S00J')
    WeatherTable[i][WEATHER_DUR] = 300
    WeatherTable[i][WEATHER_CHANCE] = 10
    WeatherTable[i][WEATHER_BOOST] = 30
    WeatherTable[i][WEATHER_CHAOS] = 1
    WeatherTable[i][WEATHER_DR] = -25
    WeatherTable[i][WEATHER_FOG] = 35
    WeatherTable[i][WEATHER_RED] = 255
    WeatherTable[i][WEATHER_GREEN] = 150
    WeatherTable[i][WEATHER_BLUE] = 0
    --solar flare
    i = 14
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "Flares cross the horizon..."
    WeatherTable[i][WEATHER_ABIL] = FourCC('A01K')
    WeatherTable[i][WEATHER_DUR] = 300
    WeatherTable[i][WEATHER_CHANCE] = 10
    WeatherTable[i][WEATHER_ATK] = 20
    WeatherTable[i][WEATHER_FOG] = 35
    WeatherTable[i][WEATHER_RED] = 255
    WeatherTable[i][WEATHER_GREEN] = 50
    WeatherTable[i][WEATHER_BLUE] = 50
    --sand storm
    i = 15
    WeatherTable[i] = {}
    WeatherTable[i][WEATHER_TEXT] = "Dust accumulates in the air..."
    WeatherTable[i][WEATHER_ABIL] = FourCC('A01M')
    WeatherTable[i][WEATHER_DUR] = 300
    WeatherTable[i][WEATHER_CHANCE] = 10
    WeatherTable[i][WEATHER_DR] = -20
    WeatherTable[i][WEATHER_FOG] = 40
    WeatherTable[i][WEATHER_RED] = 150
    WeatherTable[i][WEATHER_GREEN] = 75
    WeatherTable[i][WEATHER_BLUE] = 0
    WeatherTable[i][WEATHER_ALL] = 1

    WEATHER_MAX = i

    TimerStart(WeatherTimer, 5.00, false, nil)
end)

if Debug then Debug.endFile() end
