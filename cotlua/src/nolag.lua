OnInit.final("NoLag", function()
    local NO_LAG_MODE = false
    local SYNC_CAMERA = "CAM"
    local unit_list = {}
    local cam_x, cam_y = {}, {}
    local regions = {
        Rect(27000., 27000., 30000., 30000.),
        Rect(27000., 27000., 30000., 30000.),
        Rect(27000., 27000., 30000., 30000.),
        Rect(27000., 27000., 30000., 30000.),
        Rect(27000., 27000., 30000., 30000.),
        Rect(27000., 27000., 30000., 30000.),
    }
    local cam_regions = {
        Rect(28000., 28000., 30000., 30000.),
        Rect(28000., 28000., 30000., 30000.),
        Rect(28000., 28000., 30000., 30000.),
        Rect(28000., 28000., 30000., 30000.),
        Rect(28000., 28000., 30000., 30000.),
        Rect(28000., 28000., 30000., 30000.),
    }

    function RemoveAntiLag(u)
        TableRemove(unit_list, u)
    end

    function AntiLagUnit(u)
        unit_list[#unit_list + 1] = u
    end

    local function anti_lag()
        local big_region = CreateRegion()

        BlzSendSyncData(SYNC_CAMERA, tostring(GetCameraEyePositionX()) .. " " .. tostring(GetCameraEyePositionY() + 1000.))

        local U = User.first
        while U do
            local hero = Hero[U.id]
            if hero then
                MoveRectTo(regions[U.id], GetUnitX(hero), GetUnitY(hero))
                RegionAddRect(big_region, regions[U.id])
            end
            if cam_x[U.id] then
                MoveRectTo(cam_regions[U.id], cam_x[U.id], cam_y[U.id])
                RegionAddRect(big_region, cam_regions[U.id])
            end
            U = U.next
        end

        for i = 1, #unit_list do
            local u = unit_list[i]
            if IsUnitInRegion(big_region, u) then
                ShowUnit(u, true)
                PauseUnit(u, false)
            else
                ShowUnit(u, false)
                PauseUnit(u, true)
            end
        end

        RemoveRegion(big_region)
    end

    -- camera sync setup
    do
        local t = CreateTrigger()

        for i = 0, PLAYER_CAP - 1 do
            BlzTriggerRegisterPlayerSyncEvent(t, Player(i), SYNC_CAMERA, false)
        end

        local function on_camera_sync()
            local p = GetTriggerPlayer()
            local pid = GetPlayerId(p) + 1
            local data = BlzGetTriggerSyncData()
            local x, y = data:match("(\x25S+) (\x25S+)")

            cam_x[pid] = tonumber(x) or 0
            cam_y[pid] = tonumber(y) or 0

            return false
        end

        TriggerAddCondition(t, Filter(on_camera_sync))
    end

    local function is_on()
        return not NO_LAG_MODE
    end

    --TimerQueue:callPeriodically(1.0, nil, anti_lag)

end, Debug and Debug.getLine())
