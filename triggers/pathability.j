library TerrainPathability initializer Init
//******************************************************************************
//* BY: Rising_Dusk
//* 
//* This script can be used to detect the type of pathing at a specific point.
//* It is valuable to do it this way because the IsTerrainPathable is very
//* counterintuitive and returns in odd ways and aren't always as you would
//* expect. This library, however, facilitates detecting those things reliably
//* and easily.
//* 
//******************************************************************************
//* 
//*    > function IsTerrainDeepWater    takes real x, real y returns boolean
//*    > function IsTerrainShallowWater takes real x, real y returns boolean
//*    > function IsTerrainLand         takes real x, real y returns boolean
//*    > function IsTerrainPlatform     takes real x, real y returns boolean
//*    > function IsTerrainWalkable     takes real x, real y returns boolean
//* 
//* These functions return true if the given point is of the type specified
//* in the function's name and false if it is not. For the IsTerrainWalkable
//* function, the MAX_RANGE constant below is the maximum deviation range from
//* the supplied coordinates that will still return true.
//* 
//* The IsTerrainPlatform works for any preplaced walkable destructable. It will
//* return true over bridges, destructable ramps, elevators, and invisible
//* platforms. Walkable destructables created at runtime do not create the same
//* pathing hole as preplaced ones do, so this will return false for them. All
//* other functions except IsTerrainWalkable return false for platforms, because
//* the platform itself erases their pathing when the map is saved.
//* 
//* After calling IsTerrainWalkable(x, y), the following two global variables
//* gain meaning. They return the X and Y coordinates of the nearest walkable
//* point to the specified coordinates. These will only deviate from the
//* IsTerrainWalkable function arguments if the function returned false.
//* 
//* Variables that can be used from the library:
//*     [real]    TERRAIN_X
//*     [real]    TERRAIN_Y
//* 
globals
    private constant real    MAX_RANGE     = 8.
endglobals

globals    
    item PathItem = null
    real TERRAIN_X = 0.
    real TERRAIN_Y = 0.
    private integer Count = 0
    private rect Find
endglobals

function IsTerrainDeepWater takes real x, real y returns boolean
    return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) and IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY)
endfunction

function IsTerrainShallowWater takes real x, real y returns boolean
    return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) and IsTerrainPathable(x, y, PATHING_TYPE_BUILDABILITY)
endfunction

function IsTerrainLand takes real x, real y returns boolean
    return IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY)
endfunction

function IsTerrainPlatform takes real x, real y returns boolean
    return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) and not IsTerrainPathable(x, y, PATHING_TYPE_BUILDABILITY)
endfunction

private function CountItems takes nothing returns nothing
    set Count = Count + 1
    set TERRAIN_X = GetItemX(GetEnumItem())
    set TERRAIN_Y = GetItemY(GetEnumItem())
endfunction

function IsTerrainWalkable takes real x, real y returns boolean
    call MoveRectTo(Find, x, y)
    call EnumItemsInRect(Find, null, function CountItems)

    if Count == 0 then
        call SetItemPosition(PathItem, x, y)

        set TERRAIN_X = GetItemX(PathItem)
        set TERRAIN_Y = GetItemY(PathItem)

        call SetItemPosition(PathItem, 30000., 30000.)
    endif
    
    set Count = 0

    return SquareRoot(Pow(x - TERRAIN_X, 2) + Pow(y - TERRAIN_Y, 2)) <= MAX_RANGE and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY)
endfunction

private function Init takes nothing returns nothing
    set Find = Rect(0., 0., 8., 8.)
    set PathItem = CreateItem('wolg', 30000., 30000.)
endfunction

endlibrary
