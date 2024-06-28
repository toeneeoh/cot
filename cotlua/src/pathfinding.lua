--[[
    pathfinding.lua

    Experimental custom pathfinding
]]

OnInit.global("PathFinding", function(Require)
    Require('Pathing')

    A_STAR_PATHING = false ---@type boolean 
    CoordinateQueue = {} ---@type PriorityQueue[]
    TurnQueue = {}
    local GRID = array2d()
    local INFINITY = 2^30

    local function PrintCoordinates(coordinates)
        if coordinates then
            local printed = {}
            for i, coord in ipairs(coordinates) do
                if ModuloInteger(i, 2) == 1 or i == #coordinates then
                    local x, y = coord[1], coord[2]
                    table.insert(printed, string.format("(\x25d, \x25d)", x, y))
                end
            end
            print(table.concat(printed, " "))
        end
    end

    ---@type fun(start: table, turn: table, finish: table): boolean
    local function IsTurn(start, turn, finish)
        local one = Atan2(start.y - turn.y, start.x - turn.x)
        local two = Atan2(turn.y - finish.y, turn.x - finish.x)

        return math.abs(one - two) > 0.03
    end

    --take a unit with start/end points and queue the movement
    ---@type fun(u: unit, x: number, y: number, x2: number, y2: number)
    function QueuePathing(u, x, y, x2, y2)
        local pid = GetPlayerId(GetOwningPlayer(u)) + 1

        if not CoordinateQueue[pid] then
            CoordinateQueue[pid] = PriorityQueue.create()
            TurnQueue[pid] = {}
        end

        if CoordinateQueue[pid]:isEmpty() then
            local coordinates = A_STAR(x, y, x2, y2) ---@type table[]

            if coordinates then
                BlzUnitClearOrders(u, false)
                BlzQueuePointOrderById(u, ORDER_ID_MOVE, x2, y2) --final point
                for i, coord in ipairs(coordinates) do
                    if i > 1 and i < #coordinates then
                        if IsTurn(coordinates[i - 1], coord, coordinates[i + 1]) then
                            TurnQueue[pid][#TurnQueue[pid] + 1] = coord
                            BlzQueuePointOrderById(u, ORDER_ID_MOVE, coord.x, coord.y)
                        end
                    end
                end
            end
        end
    end

    local function heuristicEstimate(startX, startY, endX, endY)
        -- Simple Euclidean distance heuristic
        --return math.sqrt((endX - startX)^2 + (endY - startY)^2)
        -- Manhattan distance heuristic
        return math.abs(endX - startX) + math.abs(endY - startY)
    end

    local offset = 16

    -- Path reconstruction function (reverse order because BlzQueuePointOrderById puts orders in front of the queue)
    local function reconstructPath(cameFrom, current)
        local path = {}
        while current do
            path[#path + 1] = {x = offset * (current.x + 0.5), y = offset * (current.y + 0.5)}
            current = cameFrom[current.y][current.x]
        end
        --PrintCoordinates(path)
        return path
    end

    function A_STAR(startX, startY, endX, endY)
        startX = startX // offset
        startY = startY // offset
        endX = endX // offset
        endY = endY // offset

        local minX = math.min(startX, endX) - 6
        local minY = math.min(startY, endY) - 6
        local maxX = math.max(startX, endX) + 6
        local maxY = math.max(startY, endY) + 6

        local gScore = array2d(INFINITY)
        local fScore = array2d(INFINITY)
        local openSet = PriorityQueue.create()
        local cameFrom = array2d()

        gScore[startY][startX] = 0
        fScore[startY][startX] = heuristicEstimate(startX, startY, endX, endY)
        openSet:push({x = startX, y = startY}, fScore[startY][startX])

        while not openSet:isEmpty() do
            local current = openSet:pop()

            if current.x == endX and current.y == endY then
                return reconstructPath(cameFrom, current)
            end

            local tentativeGScore = gScore[current.y][current.x] + 1

            for dx = -1, 1 do
                for dy = -1, 1 do
                    if dx ~= 0 or dy ~= 0 then
                        local x, y = current.x + dx, current.y + dy

                        -- Check if the neighbor is within the grid boundaries and walkable
                        if x >= minX and x <= maxX and y >= minY and y <= maxY then
                            if GRID[y][x] == nil then
                                GRID[y][x] = IsTerrainWalkable(offset * (x + 0.5), offset * (y + 0.5))
                            end

                            if GRID[y][x] then
                                if tentativeGScore < gScore[y][x] then
                                    cameFrom[y][x] = {x = current.x, y = current.y}
                                    gScore[y][x] = tentativeGScore
                                    fScore[y][x] = tentativeGScore + heuristicEstimate(x, y, endX, endY)
                                    openSet:push({x = x, y = y}, fScore[y][x])
                                end
                            end
                        end
                    end
                end
            end
        end

        return nil
    end
end, Debug and Debug.getLine())
