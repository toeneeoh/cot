--[[
    unitindex.lua

    A library that defines the Unit interface that registers newly
    created units for OO purposes.
]]

if Debug then Debug.beginFile 'UnitIndex' end

OnInit.final("UnitIndex", function(require)
    require 'TimerQueue'
    require 'WorldBounds'

    DETECT_LEAVE_ABILITY = FourCC('uDex') ---@type integer 

    ---@class Unit
    ---@field pid integer
    ---@field unit unit
    ---@field create function
    ---@field attackCount integer
    ---@field castFinish function
    ---@field evasion integer
    Unit = {}
    do
        local thistype = Unit

        --create a new instance if nil
        setmetatable(Unit, { __index = function(tbl, key)
            if type(key) == "userdata" then
                local new = Unit.create(key)

                rawset(tbl, key, new)
                return new
            end
        end})

        function thistype:castFinish()
            self.casting = false
            PauseUnit(self.unit, false)
        end

        --dot method operators
        local operators = {
            attack = function(tbl, val)
                rawset(tbl, "canAttack", val)

                if not autoAttackDisabled[rawget(tbl, "pid")] then
                    BlzSetUnitWeaponBooleanField(rawget(tbl, "unit"), UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, val)
                end
            end,

            castTime = function(tbl, val)
                rawset(tbl, "casting", true)
                PauseUnit(rawget(tbl, "unit"), true)

                TimerQueue:callDelayed(val, tbl.castFinish, tbl)
            end
        }

        ---@type fun(u: unit):Unit
        function thistype.create(u)
            local self = {}

            self.pid = GetPlayerId(GetOwningPlayer(u)) + 1
            self.unit = u
            self.attackCount = 0
            self.casting = false
            self.canAttack = true
            self.evasion = 0

            setmetatable(self, {
                __index = thistype,
                __newindex = function(tbl, key, val)
                if operators[key] then
                    operators[key](tbl, val)
                else
                    rawset(tbl, key, val)
                end
            end})

            return self
        end
    end

    ---@type fun(u: unit): unit?
    function GetUnitTarget(u)
        if Threat[u].target == 0 then
            return nil
        else
            return Threat[u].target
        end
    end

    ---@type fun(u: unit)
    function UnitDeindex(u)
        if DEV_ENABLED then
            if EXTRA_DEBUG then
                DisplayTimedTextToForce(FORCE_PLAYING, 30., "UNREG " .. GetUnitName(u))
            end
        end

        TableRemove(SummonGroup, u)

        Threat[u] = nil
        Unit[u] = nil
    end

    ---@return boolean
    local function IndexUnit()
        local u = GetFilterUnit()

        if u and GetUnitTypeId(u) ~= DUMMY and GetUnitAbilityLevel(u, DETECT_LEAVE_ABILITY) == 0 then
            UnitAddAbility(u, DETECT_LEAVE_ABILITY)
            UnitMakeAbilityPermanent(u, true, DETECT_LEAVE_ABILITY)

            TriggerRegisterUnitEvent(ACQUIRE_TRIGGER, u, EVENT_UNIT_ACQUIRED_TARGET)

            if DEV_ENABLED then
                if EXTRA_DEBUG then
                    print("REG " .. GetUnitName(u))
                end
            end
        end

        return false
    end

    local ug = CreateGroup()
    local onEnter = CreateTrigger()

    GroupEnumUnitsOfPlayer(ug, Player(PLAYER_NEUTRAL_AGGRESSIVE), Filter(IndexUnit)) --punching bag
    TriggerRegisterEnterRegion(onEnter, WorldBounds.region, Filter(IndexUnit))

    DestroyGroup(ug)
end)

if Debug then Debug.endFile() end
