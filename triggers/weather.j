library Weather initializer weathersetup requires Functions

globals
	timer WeatherTimer = CreateTimer()
    integer currentWeather = 0
    integer prevWeather = 0
    integer firestormRate = 4
    real donation = 1.
    unit WeatherUnit = null
    location array fsLoc
	integer array weatherAbil
	string array weatherName
	real array weatherAS
    integer weatherIterations = 0
    boolean firestormActive
    private boolean SETUP = true
endglobals

function FirestormDamage takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local group g = CreateGroup()
    local unit target = null
    
    call GroupEnumUnitsInRangeOfLoc(g, fsLoc[GetTimerData(t)], 300, function isplayerAlly)
    call DestroyTreesInRange(GetLocationX(fsLoc[GetTimerData(t)]), GetLocationY(fsLoc[GetTimerData(t)]), 300)
    
    loop
        set target = FirstOfGroup(g)
        exitwhen target == null
        call UnitDamageTarget(WeatherUnit, target, BlzGetUnitMaxHP(target) * .1, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_DIVINE, WEAPON_TYPE_WHOKNOWS)
        call GroupRemoveUnit(g, target)
    endloop
    
    call DestroyGroup(g)
    call ReleaseTimer(t)
    
    set t = null
    set g = null
    set target = null
endfunction

function FirestormEffect takes nothing returns nothing
    local integer i = 0
    local group ug = CreateGroup()

    if firestormActive then
        loop
            exitwhen i > firestormRate
            loop
                set fsLoc[i] = Location(GetRandomReal(GetRectMinX(gg_rct_Main_Map), GetRectMaxX(gg_rct_Main_Map)), GetRandomReal(GetRectMinY(gg_rct_Main_Map), GetRectMaxY(gg_rct_Main_Map)))
                call GroupEnumUnitsInRangeOfLoc(ug, fsLoc[i], 4000., Condition(function isbase))
                exitwhen RectContainsCoords(gg_rct_NoSin, GetLocationX(fsLoc[i]), GetLocationY(fsLoc[i])) == false and BlzGroupGetSize(ug) == 0
                call RemoveLocation(fsLoc[i])
            endloop
            call TimerStart(NewTimerEx(i), 1.5, false, function FirestormDamage)
            call DestroyEffect(AddSpecialEffectLoc("Units\\Demon\\Infernal\\InfernalBirth.mdl", fsLoc[i]))
            set i = i + 1
        endloop
    else
        call ReleaseTimer(GetExpiredTimer())
    endif

    call DestroyGroup(ug)

    set ug = null
endfunction

function FirestormStart takes nothing returns nothing
    call ReleaseTimer(GetExpiredTimer())
    call TimerStart(NewTimer(), 3.00, true, function FirestormEffect)
endfunction

function weathersetup takes nothing returns nothing
    local integer i = 1
    
    set WeatherUnit = gg_unit_h05E_0717
    
    set weatherName[0] = "|c006666ff"
    set weatherAS[0] = 1
	set weatherName[i]  ="There is currently a Hurricane."
	set weatherAbil[i]='S008'
	set weatherAS[i] =0.55
    set i =2
	set weatherName[i]  ="It is snowing heavily."
	set weatherAbil[i]='S003'
	set weatherAS[i] =0.65
    set i =3
	set weatherName[i]  ="It is snowing."
	set weatherAbil[i]='S002'
	set weatherAS[i] =0.75
    set i =4
	set weatherName[i]  ="It is foggy."
	set weatherAbil[i]='S009'
	set weatherAS[i] =0.7
    set i =5
	set weatherName[i]  ="It is raining heavily."
	set weatherAbil[i]='S005'
	set weatherAS[i] =1.
    set i =6
	set weatherName[i]  ="It is raining."
	set weatherAbil[i]='S004'
	set weatherAS[i] =1.
    set i =7
	set weatherName[i]  ="It is currently clear."
	set weatherAbil[i]='S007'
	set weatherAS[i] =1
    set i =8
	set weatherName[i]  ="It is currently sunny."
	set weatherAbil[i]='S006'
	set weatherAS[i] =1.15
    set i =9
	set weatherName[i]  ="We are blessed with Divine Grace."
	set weatherAbil[i]='S00A'
	set weatherAS[i] =1.3
    set i =10
	set weatherName[i]  ="There is currently a Siphoning Mist." 
	set weatherAbil[i]='S00F' 
	set weatherAS[i] =1.5
    set i =11
	set weatherName[i]  ="There is currently a Chaotic Hurricane."
	set weatherAbil[i]='S00E'
	set weatherAS[i] =0.35
    set i =12
	set weatherName[i]  ="There is currently Chaotic Heavy Snow."
	set weatherAbil[i]='S00D'
	set weatherAS[i] =0.6
    set i =14
	set weatherName[i]  ="There is currently Chaotic Fog."
	set weatherAbil[i]='S00B'
	set weatherAS[i] =0.55
    set i =15
	set weatherName[i]  ="There is currently Chaotic Heavy Rain."
	set weatherAbil[i]='S00C'
	set weatherAS[i] = 1.
    set i =17
	set weatherName[i]  ="There is currently a Firestorm." 
	set weatherAbil[i]='S00J'
	set weatherAS[i] =1.
endfunction

function WeatherPeriodic takes nothing returns nothing
    local real dur = GetRandomInt(250, 500)
    local integer i = 0
    local integer maxlev = 1
    local integer min = 0
    local integer max = 1000
    local integer rand
    
    set firestormActive = false
    set weatherIterations = weatherIterations + 1

    call UnitRemoveAbility(WeatherUnit, weatherAbil[currentWeather])

	if GetTimeOfDay() < 6 or GetTimeOfDay() > 16 then
		set max = 819 //no sunny at night
	endif
	if prevWeather > 0 then //no snow or worse twice in a row
		set min = 420
        set prevWeather = 0
	endif
	set rand= GetRandomInt(min,max)
	if ChaosMode then
		if rand < 30 * donation then //Chaotic Hurricane - 3%
            set currentWeather= 11
			set dur= 40
		elseif rand < 80 * donation then //Chaotic Heavy Snow - 5%
            set currentWeather= 12
			set dur= dur*.3
		elseif rand < 210 * donation then //Snow - 13%
            set currentWeather= 3
			set dur= dur*.5
		elseif rand < 270 * donation then //Chaotic Fog - 6%
            set currentWeather= 14
			set dur= dur*.4
		elseif rand < 350 * donation then //Chaotic Heavy Rain - 8%
            set currentWeather= 15
			set dur= dur*.5
        elseif rand < 410 * donation then //Firestorm - 6%
            set currentWeather= 17
            set dur= dur*.5
            set firestormActive = true
            call TimerStart(NewTimer(), 7., false, function FirestormStart)
        elseif rand < 470 * donation then //Siphoning Mist - 6%
            set currentWeather= 10
			set dur= dur*.5
		elseif rand < 630 * donation then //Rain - 15%
            set currentWeather= 6
		elseif rand < 880 then //Clear - 25%
            set currentWeather= 7
            set dur = GetRandomInt(500, 1000)
		elseif rand < 970 then //Sunny - 10%
            set currentWeather= 8
		elseif rand <= 1000 then //Divine Grace - 3%
            set currentWeather= 9
		endif
	else
		loop
			exitwhen i > 8
			set maxlev= IMaxBJ(maxlev, GetHeroLevel(Hero[i]))
			set i = i + 1
		endloop
		if (weatherIterations < 4 or (weatherIterations < 11 and maxlev < 30)) then
			set min = 500
		endif
		set rand= GetRandomInt(min,max)
		if rand < 20 * donation then //Hurricane - 2%
            set currentWeather= 1
			set dur= 40
		elseif rand < 60 * donation then //Heavy Snow - 4%
            set currentWeather= 2
			set dur= dur*.5
		elseif rand < 180 * donation then //Snow - 12%
            set currentWeather= 3
            set dur = dur*.7
		elseif rand < 230 * donation then //Fog - 5%
            set currentWeather= 4
			set dur = dur*.5
        elseif rand < 280 * donation then //Siphoning Mist - 5%
            set currentWeather= 10
			set dur= dur*.5
		elseif rand < 350 * donation then //Heavy Rain - 7%
            set currentWeather= 5
			set dur= dur*.5
		elseif rand < 500 * donation then //Rain - 15%
            set currentWeather= 6
        elseif rand < 850 then //Clear - 35%
            set currentWeather= 7
            set dur = GetRandomInt(500, 1000)
		elseif rand < 970 then //Sunny - 12%
            set currentWeather= 8
		elseif rand <= 1000 then //Divine Grace - 3%
            set currentWeather= 9
		endif
	endif

	if rand < 350 then //to avoid repeating bad weather
		set prevWeather = 1
	endif

    call TimerStart(WeatherTimer,dur,false,null)

    if SETUP then
        set SETUP = false
    else
	    call DisplayTimedTextToForce(FORCE_PLAYING, 30, weatherName[0] + weatherName[currentWeather])
    endif

    call UnitAddAbility(WeatherUnit, weatherAbil[currentWeather])
endfunction

//===========================================================================
function WeatherInit takes nothing returns nothing
    local trigger weather = CreateTrigger()

	call TriggerRegisterTimerExpireEvent(weather, WeatherTimer)
	call TriggerAddAction(weather, function WeatherPeriodic)

    set weather = null
endfunction

endlibrary
