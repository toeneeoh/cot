--[[
    root.lua

    defines some helper functions and then indicates what files the build tool should load into the map.
    (file dependencies determined by TotalInitialization.lua)
]]

do
    LOCAL_JOIN_TIME = 0
    PLAYER_JOIN_TIME = __jarray(0)
    PLAYER_START_TIME = __jarray(0)

    --functions to determine which player is the host based on lobby join time
    function OnStart()
        PLAYER_START_TIME[GetTriggerPlayer()] = tonumber(BlzGetTriggerSyncData())
    end

    function OnJoin()
        PLAYER_JOIN_TIME[GetTriggerPlayer()] = tonumber(BlzGetTriggerSyncData())
    end

    function DetectHost()
        local host = {p = nil, time = 0}

        for i = 0, bj_MAX_PLAYERS do
            local p = Player(i)

            if (GetPlayerController(p) == MAP_CONTROL_USER and GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING) then
                print(User[p].nameColored .. " start time: " .. PLAYER_START_TIME[p] .. " | join time: " .. PLAYER_JOIN_TIME[p])
                if PLAYER_START_TIME[p] - PLAYER_JOIN_TIME[p] > host.time then
                    host.time = PLAYER_START_TIME[p] - PLAYER_JOIN_TIME[p]
                    host.p = p
                end
            end
        end

        return host.p
    end

    --iterator for groups with counter
    ---@param ug group
    ---@return fun(): integer?, unit?
    function ieach(ug)
        local index = -1
        local length = BlzGroupGetSize(ug)

        return function()
            index = index + 1
            if index < length then
                return index, BlzGroupUnitAt(ug, index)
            end
        end
    end

    --iterator for groups
    ---@param ug group
    ---@return fun(): unit?
    function each(ug)
        local index = -1
        local length = BlzGroupGetSize(ug)

        return function()
            index = index + 1
            if index < length then
                return BlzGroupUnitAt(ug, index)
            end
        end
    end

    --credits: Bribe
    local mts = {}
    local weakKeys = {__mode="k"} --ensures tables with non-nilled objects as keys will be garbage collected.

    ---Re-define __jarray.
    ---@param default? any
    ---@param tab? table
    ---@return table
    __jarray = function(default, tab)
        local mt
        if default then
            mts[default]=mts[default] or {
                __index=function()
                    return default
                end,
                __mode="k"
            }
            mt=mts[default]
        else
            mt=weakKeys
        end
        return setmetatable(tab or {}, mt)
    end

    local nested_mts = {}

    --returns a 2d array with a default value
    ---@type fun(val: any): table
    function array2d(val)
        local key = val or "___"

        nested_mts[key] = nested_mts[key] or {
            __index = function(t, k)
                local new = (val and __jarray(val)) or {}

                rawset(t, k, new)
                return new
            end}

        return setmetatable({}, nested_mts[key])
    end
end

dofile('debugutils.lua')
dofile('stringwidth.lua')
dofile('ingameconsole.lua')
dofile('TotalInitialization.lua')
dofile('bignum.lua')
dofile('preload.lua')
dofile('helper.lua')
dofile('variables.lua')
dofile('users.lua')
dofile('dev.lua')
dofile('f9.lua')
dofile('mapsetup.lua')
dofile('timerqueue.lua')
dofile('worldbounds.lua')
dofile('gamestatus.lua')
dofile('events.lua')
dofile('missile.lua')
dofile('missileeffect.lua')
dofile('shop.lua')
dofile('shopcomponent.lua')
dofile('fileio.lua')
dofile('codegen.lua')
dofile('unitevent.lua')
dofile('spellview.lua')
dofile('pathing.lua')
--dofile('pathfinding.lua')
dofile('unittable.lua')
dofile('dummy.lua')
dofile('playerdata.lua')
dofile('buffsystem.lua')
dofile('buffs.lua')
dofile('saveload.lua')
dofile('bonus.lua')
dofile('units.lua')
dofile('items.lua')
dofile('spells.lua')
dofile('destructable.lua')
dofile('regions.lua')
dofile('bossai.lua')
dofile('chaos.lua')
dofile('pvp.lua')
dofile('dungeons.lua')
dofile('cosmetics.lua')
dofile('weather.lua')
dofile('heroselect.lua')
dofile('UI.lua')
dofile('multiboard.lua')
dofile('bases.lua')
dofile('threat.lua')
dofile('timers.lua')
dofile('attacked.lua')
dofile('damage.lua')
dofile('death.lua')
dofile('commands.lua')
dofile('orders.lua')
dofile('keyboard.lua')
dofile('mouse.lua')
dofile('summon.lua')
dofile('level.lua')
dofile('currency.lua')
dofile('train.lua')
dofile('movespeed.lua')