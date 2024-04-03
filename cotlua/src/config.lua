if Debug then Debug.beginFile 'Config' end

function DetectHost()
    local host = {id = -1, time = 0}

    for i = 0, PLAYER_CAP - 1 do
        if (GetPlayerController(Player(i)) == MAP_CONTROL_USER and GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING) then
            print(User[Player(i)].nameColored .. " start time: " .. PLAYER_START_TIME[i] .. " | join time: " .. PLAYER_JOIN_TIME[i])
            if PLAYER_START_TIME[i] - PLAYER_JOIN_TIME[i] > host.time then
                host.time = PLAYER_START_TIME[i] - PLAYER_JOIN_TIME[i]
                host.id = i
            end
        end
    end

    return host.id
end

function OnStart()
    local pid = GetPlayerId(GetTriggerPlayer())

    PLAYER_START_TIME[pid] = tonumber(BlzGetTriggerSyncData())

    return false
end

function OnJoin()
    local pid = GetPlayerId(GetTriggerPlayer())

    PLAYER_JOIN_TIME[pid] = tonumber(BlzGetTriggerSyncData())

    return false
end

ON_JOIN = CreateTrigger()
ON_START = CreateTrigger()
PLAYER_JOIN_TIME = __jarray(0)
PLAYER_START_TIME = __jarray(0)

for i = 0, bj_MAX_PLAYER_SLOTS do
    BlzTriggerRegisterPlayerSyncEvent(ON_JOIN, Player(i), "join", false)
    BlzTriggerRegisterPlayerSyncEvent(ON_START, Player(i), "start", false)
end
TriggerAddCondition(ON_JOIN, Condition(OnJoin))
TriggerAddCondition(ON_START, Condition(OnStart))

BlzSendSyncData("join", tostring(os.clock()))

if Debug then Debug.endFile() end
