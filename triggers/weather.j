library Weather initializer weathersetup requires Functions

globals
	timer WeatherTimer= CreateTimer()
    group AffectedByWeather = CreateGroup()
    integer prevweather = 0
    integer firestormrate = 4
    real donation = 1.
    unit WeatherUnit
    location array fsLoc
	integer array weatherability
	string array weathernames
	real array weatheratkspd
    integer weatheriterations = 0
    boolean firestormActive
    private boolean SETUP = true
endglobals

function FirestormDamage takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local group g = CreateGroup()
    local unit target
    
    call GroupEnumUnitsInRangeOfLoc(g, fsLoc[GetTimerData(t)], 300, function isplayerAlly)
    call DestroyTreesInRange(GetLocationX(fsLoc[GetTimerData(t)]), GetLocationY(fsLoc[GetTimerData(t)]), 300)
    
    loop
        set target = FirstOfGroup(g)
        exitwhen target == null
        call SetUnitState(target, UNIT_STATE_LIFE, GetUnitState(target, UNIT_STATE_LIFE) - BlzGetUnitMaxHP(target) * .1)
        call DoFloatingTextUnit( RealToString(BlzGetUnitMaxHP(target) * .1), target, 1.2, 50, 0, 10, 50, 50, 120, 0 )
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
            exitwhen i > firestormrate
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
    
    set weathernames[0] = "|c006666ff"
    set weatheratkspd[0] = 1
	set weathernames[i]  ="There is currently a Hurricane."
	set weatherability[i]='S008'
	set weatheratkspd[i] =0.55
    set i=2
	set weathernames[i]  ="It is snowing heavily."
	set weatherability[i]='S003'
	set weatheratkspd[i] =0.65
    set i=3
	set weathernames[i]  ="It is snowing."
	set weatherability[i]='S002'
	set weatheratkspd[i] =0.75
    set i=4
	set weathernames[i]  ="It is foggy."
	set weatherability[i]='S009'
	set weatheratkspd[i] =0.7
    set i=5
	set weathernames[i]  ="It is raining heavily."
	set weatherability[i]='S005'
	set weatheratkspd[i] =1.
    set i=6
	set weathernames[i]  ="It is raining."
	set weatherability[i]='S004'
	set weatheratkspd[i] =1.
    set i=7
	set weathernames[i]  ="It is currently clear."
	set weatherability[i]='S007'
	set weatheratkspd[i] =1
    set i=8
	set weathernames[i]  ="It is currently sunny."
	set weatherability[i]='S006'
	set weatheratkspd[i] =1.15
    set i=9
	set weathernames[i]  ="We are blessed with Divine Grace."
	set weatherability[i]='S00A'
	set weatheratkspd[i] =1.3
    set i=10
	set weathernames[i]  ="There is currently a Siphoning Mist." 
	set weatherability[i]='S00F' 
	set weatheratkspd[i] =1.5
    set i=11
	set weathernames[i]  ="There is currently a Chaotic Hurricane."
	set weatherability[i]='S00E'
	set weatheratkspd[i] =0.35
    set i=12
	set weathernames[i]  ="There is currently Chaotic Heavy Snow."
	set weatherability[i]='S00D'
	set weatheratkspd[i] =0.6
    set i=14
	set weathernames[i]  ="There is currently Chaotic Fog."
	set weatherability[i]='S00B'
	set weatheratkspd[i] =0.55
    set i=15
	set weathernames[i]  ="There is currently Chaotic Heavy Rain."
	set weatherability[i]='S00C'
	set weatheratkspd[i] = 1.
    set i=17
	set weathernames[i]  ="There is currently a Firestorm." 
	set weatherability[i]='S00J'
	set weatheratkspd[i] =1.
endfunction

function Trig_Weather_Actions takes nothing returns nothing
    local real dur= GetRandomInt(250, 500)
    local integer i = 1
    local integer maxlev = 1
    local integer min = 0
    local integer max = 1000
    local integer rand
    local unit target
    
    set firestormActive = false
    set weatheriterations = weatheriterations + 1

    loop
        set target = FirstOfGroup(AffectedByWeather)
        exitwhen target == null
        call GroupRemoveUnit(AffectedByWeather, target)
        call ClearWeather(target)
    endloop

    call GroupEnumUnitsInRect(AffectedByWeather, gg_rct_Main_Map, Filter(function isplayerunitRegion))
    call UnitRemoveAbility(WeatherUnit, weatherability[udg_Weather])

	if GetTimeOfDay() < 6 or GetTimeOfDay() > 16 then
		set max=819 //no sunny at night
	endif
	if prevweather > 0 then //no snow or worse twice in a row
		set min = 420
        set prevweather = 0
	endif
	set rand= GetRandomInt(min,max)
	if udg_Chaos_World_On then
		if rand < 30 * donation then //Chaotic Hurricane - 3%
            set udg_Weather= 11
			set dur= 40
		elseif rand < 80 * donation then //Chaotic Heavy Snow - 5%
            set udg_Weather= 12
			set dur= dur*.3
		elseif rand < 210 * donation then //Snow - 13%
            set udg_Weather= 3
			set dur= dur*.5
		elseif rand < 270 * donation then //Chaotic Fog - 6%
            set udg_Weather= 14
			set dur= dur*.4
		elseif rand < 350 * donation then //Chaotic Heavy Rain - 8%
            set udg_Weather= 15
			set dur= dur*.5
        elseif rand < 410 * donation then //Firestorm - 6%
            set udg_Weather= 17
            set dur= dur*.5
            set firestormActive = true
            call TimerStart(NewTimer(), 7., false, function FirestormStart)
        elseif rand < 470 * donation then //Siphoning Mist - 6%
            set udg_Weather= 10
			set dur= dur*.5
		elseif rand < 630 * donation then //Rain - 15%
            set udg_Weather= 6
		elseif rand < 880 then //Clear - 25%
            set udg_Weather= 7
            set dur = GetRandomInt(500, 1000)
		elseif rand < 970 then //Sunny - 10%
            set udg_Weather= 8
		elseif rand <= 1000 then //Divine Grace - 3%
            set udg_Weather= 9
		endif
	else
		loop
			exitwhen i > 8
			set maxlev= IMaxBJ(maxlev, GetHeroLevel(Hero[i]))
			set i = i + 1
		endloop
		if ( weatheriterations <4 or (weatheriterations < 11 and maxlev < 30) ) then
			set min=500
		endif
		set rand= GetRandomInt(min,max)
		if rand < 20 * donation then //Hurricane - 2%
            set udg_Weather= 1
			set dur= 40
		elseif rand < 60 * donation then //Heavy Snow - 4%
            set udg_Weather= 2
			set dur= dur*.5
		elseif rand < 180 * donation then //Snow - 12%
            set udg_Weather= 3
            set dur = dur*.7
		elseif rand < 230 * donation then //Fog - 5%
            set udg_Weather= 4
			set dur = dur*.5
        elseif rand < 280 * donation then //Siphoning Mist - 5%
            set udg_Weather= 10
			set dur= dur*.5
		elseif rand < 350 * donation then //Heavy Rain - 7%
            set udg_Weather= 5
			set dur= dur*.5
		elseif rand < 500 * donation then //Rain - 15%
            set udg_Weather= 6
        elseif rand < 850 then //Clear - 35%
            set udg_Weather= 7
            set dur = GetRandomInt(500, 1000)
		elseif rand < 970 then //Sunny - 12%
            set udg_Weather= 8
		elseif rand <= 1000 then //Divine Grace - 3%
            set udg_Weather= 9
		endif
	endif

	if rand < 350 then //to avoid repeating bad weather
		set prevweather = 1
	endif

    call TimerStart(WeatherTimer,dur,false,null)

    if SETUP then
        set SETUP = false
    else
	    call DisplayTimedTextToForce(FORCE_PLAYING, 30, weathernames[0] + weathernames[udg_Weather])
    endif

    call UnitAddAbility(WeatherUnit, weatherability[udg_Weather])

    set i = 0
    set max = BlzGroupGetSize(AffectedByWeather)
    
    if max > 0 then
        loop
            set target = BlzGroupUnitAt(AffectedByWeather, i)
            call ApplyWeather(target)

            set i = i + 1
            exitwhen i >= max
        endloop
    endif

    set target = null
endfunction

//===========================================================================
function WeatherInit takes nothing returns nothing
    local trigger weather = CreateTrigger()

	call TriggerRegisterTimerExpireEvent(weather, WeatherTimer)
	call TriggerAddAction(weather, function Trig_Weather_Actions)

    set weather = null
endfunction

endlibrary
