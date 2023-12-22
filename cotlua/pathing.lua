if Debug then Debug.beginFile 'Pathing' end

OnInit.global("Pathing", function()

    PathItem = CreateItem(FourCC('wolg'), 30000., 30000.)
    TERRAIN_X      = 0. ---@type number 
    TERRAIN_Y      = 0. ---@type number 

    local MAX_RANGE             = 8. ---@type number 
    local Count         = 0 ---@type integer 
    local Find = Rect(0., 0., 8., 8.) ---@type rect 

---@param x number
---@param y number
---@return boolean
function IsTerrainDeepWater(x, y)
    return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) and IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY)
end

---@param x number
---@param y number
---@return boolean
function IsTerrainShallowWater(x, y)
    return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) and IsTerrainPathable(x, y, PATHING_TYPE_BUILDABILITY)
end

---@param x number
---@param y number
---@return boolean
function IsTerrainLand(x, y)
    return IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY)
end

---@param x number
---@param y number
---@return boolean
function IsTerrainPlatform(x, y)
    return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) and not IsTerrainPathable(x, y, PATHING_TYPE_BUILDABILITY)
end

local function CountItems()
    Count = Count + 1
    TERRAIN_X = GetItemX(GetEnumItem())
    TERRAIN_Y = GetItemY(GetEnumItem())
end

---@param x number
---@param y number
---@return boolean
function IsTerrainWalkable(x, y)
    MoveRectTo(Find, x, y)
    EnumItemsInRect(Find, nil, CountItems)

    if Count == 0 then
        SetItemPosition(PathItem, x, y)

        TERRAIN_X = GetItemX(PathItem)
        TERRAIN_Y = GetItemY(PathItem)

        SetItemPosition(PathItem, 30000., 30000.)
    end

    Count = 0

    return SquareRoot(Pow(x - TERRAIN_X, 2) + Pow(y - TERRAIN_Y, 2)) <= MAX_RANGE and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY)
end

end)

if Debug then Debug.endFile() end
