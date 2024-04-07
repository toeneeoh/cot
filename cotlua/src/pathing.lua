if Debug then Debug.beginFile 'Pathing' end

--[[
    pathing.lua

    This module provides utilities for determining what kind of
    pathing an (x, y) coordinate on the map has.
]]

OnInit.global("Pathing", function()

    local PATH_UNIT = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('u001'), 30000., 30000., 0)
    PATH_ITEM = CreateItem(FourCC('wolg'), 30000., 30000.)
    TERRAIN_X = 0.
    TERRAIN_Y = 0.

    local MAX_RANGE     = 10.
    local Find          = Rect(0., 0., 128., 128.)
    local HiddenItems   = {}

---@type fun(x: number, y: number):boolean
function IsTerrainDeepWater(x, y)
    return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) and IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY)
end

---@type fun(x: number, y: number):boolean
function IsTerrainShallowWater(x, y)
    return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) and IsTerrainPathable(x, y, PATHING_TYPE_BUILDABILITY)
end

---@type fun(x: number, y: number):boolean
function IsTerrainLand(x, y)
    return IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY)
end

---@type fun(x: number, y: number):boolean
function IsTerrainPlatform(x, y)
    return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) and not IsTerrainPathable(x, y, PATHING_TYPE_BUILDABILITY)
end

local function HideItems()
    local itm = GetEnumItem()

    if IsItemVisible(itm) then
        SetItemVisible(itm, false)
        HiddenItems[#HiddenItems + 1] = itm
    end
end

local function IsCoordWalkable(x, y)
    MoveRectTo(Find, x, y)
    EnumItemsInRect(Find, nil, HideItems)

    SetItemPosition(PATH_ITEM, x, y)

    TERRAIN_X = GetItemX(PATH_ITEM)
    TERRAIN_Y = GetItemY(PATH_ITEM)

    SetItemPosition(PATH_ITEM, 30000., 30000.)

    for i, v in ipairs(HiddenItems) do
        SetItemVisible(v, true)
        HiddenItems[i] = nil
    end

    return (TERRAIN_X - x) ^ 2 + (TERRAIN_Y - y) ^ 2 <= MAX_RANGE ^ 2 and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY)
end

---@type fun(x: number, y: number, collision: number?):boolean
function IsTerrainWalkable(x, y, collision)
    local walkable = true

    if collision then
        --ShowUnit(PATH_UNIT, true)
        if GetUnitAbilityLevel(PATH_UNIT, FourCC('B02Q')) == 0 then
            UnitAddItemById(PATH_UNIT, PHASED_MOVEMENT)
        end
        SetUnitPosition(PATH_UNIT, x, y)
        local x2, y2 = GetUnitX(PATH_UNIT), GetUnitY(PATH_UNIT)
        print("(" .. x .. ", " .. y .. ") (" .. x2 .. ", " .. y2 .. ")")
        --ShowUnit(PATH_UNIT, false)
        walkable = math.abs(x - x2) < 2. and math.abs(y - y2) < 2.
        SetUnitPosition(PATH_UNIT, 30000., 30000.)
    end
    return IsCoordWalkable(x, y) and walkable
end

end)

if Debug then Debug.endFile() end
