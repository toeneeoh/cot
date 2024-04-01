if Debug then Debug.beginFile 'Pathing' end

OnInit.global("Pathing", function()

    PathItem        = CreateItem(FourCC('wolg'), 30000., 30000.)
    TERRAIN_X       = 0.
    TERRAIN_Y       = 0.

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

---@type fun(x: number, y: number):boolean
function IsTerrainWalkable(x, y)
    MoveRectTo(Find, x, y)
    EnumItemsInRect(Find, nil, HideItems)

    SetItemPosition(PathItem, x, y)

    TERRAIN_X = GetItemX(PathItem)
    TERRAIN_Y = GetItemY(PathItem)

    SetItemPosition(PathItem, 30000., 30000.)

    for i, v in ipairs(HiddenItems) do
        SetItemVisible(v, true)
        HiddenItems[i] = nil
    end

    return (TERRAIN_X - x) ^ 2 + (TERRAIN_Y - y) ^ 2 <= MAX_RANGE ^ 2 and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY)
end

end)

if Debug then Debug.endFile() end
