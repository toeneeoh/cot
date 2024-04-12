--[[
    unittable.lua

    A library that defines the Unit interface that registers newly
    created units for OO purposes.
]]

OnInit.final("UnitTable", function(Require)
    Require('TimerQueue')
    Require('WorldBounds')

    DETECT_LEAVE_ABILITY = FourCC('uDex') ---@type integer 

    ---@class Unit
    ---@field pid integer
    ---@field unit unit
    ---@field create function
    ---@field attackCount integer
    ---@field castFinish function
    ---@field evasion integer
    ---@field regen number
    ---@field healamp number
    ---@field noregen boolean
    ---@field dr number
    ---@field pr number
    ---@field mr number
    ---@field movespeed number
    ---@field flatMS number
    ---@field percentMS number
    ---@field x number
    ---@field y number
    ---@field orderX number
    ---@field orderY number
    Unit = {}
    do
        local thistype = Unit

        setmetatable(Unit, {
            --create a new unit object
            __index = function(tbl, key)
                if type(key) == "userdata" and not IsDummy(key) then
                    local new = Unit.create(key)

                    rawset(tbl, key, new)
                    return new
                end
            end,
            --make keys weak for when units are removed
            __mode = 'k'
        })

        --dot method operators
        local operators = {
            x = function(tbl, val)
                SetUnitXBounded(tbl.unit, val)
                tbl.proxy.x = val
            end,
            y = function(tbl, val)
                SetUnitYBounded(tbl.unit, val)
                tbl.proxy.y = val
            end,
            flatMS = function(tbl, val)
                tbl.proxy.flatMS = val
                tbl.movespeed = val * tbl.proxy.percentMS
            end,
            percentMS = function(tbl, val)
                tbl.proxy.percentMS = val
                tbl.movespeed = tbl.proxy.flatMS * val
            end,
            overmovespeed = function(tbl, val)
                tbl.proxy.overmovespeed = val
                tbl.movespeed = val or tbl.proxy.flatMS * tbl.proxy.percentMS
            end,
            movespeed = function(tbl, val)
                tbl.proxy.movespeed = tbl.overmovespeed or math.min(600, val)
                UnitSetBonus(tbl.unit, BONUS_MOVE_SPEED, val)
            end,
            attack = function(tbl, val)
                rawset(tbl, "canAttack", val)

                if not autoAttackDisabled[tbl.pid] then
                    BlzSetUnitWeaponBooleanField(tbl.unit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, val)
                end
            end,

            castTime = function(tbl, val)
                rawset(tbl, "casting", true)
                PauseUnit(rawget(tbl, "unit"), true)

                TimerQueue:callDelayed(val, tbl.castFinish, tbl)
            end
        }

        local mt = {
                __index = function(tbl, key)
                    return (rawget(thistype, key) or rawget(tbl.proxy, key))
                end,
                __newindex = function(tbl, key, val)
                    if operators[key] then
                        operators[key](tbl, val)
                    else
                        rawset(tbl, key, val)
                    end
                end,
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
            self.dr = 1.
            self.mr = 1.
            self.pr = 1.
            self.regen = BlzGetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE)
            self.healamp = 1.
            self.noregen = false
            self.threat = __jarray(0)
            self.proxy = { --used for __newindex behavior
                flatMS = GetUnitMoveSpeed(u),
                percentMS = 1.,
                movespeed = GetUnitMoveSpeed(u),
                x = GetUnitX(u),
                y = GetUnitY(u),
            }
            self.target = nil
            self.orderX = self.proxy.x
            self.orderY = self.proxy.y

            setmetatable(self, mt)

            return self
        end

        function thistype:castFinish()
            self.casting = false
            PauseUnit(self.unit, false)
        end
    end

    ---@type fun(u: unit): unit?
    function GetUnitTarget(u)
        return (Threat[u].target ~= 0 and Threat[u].target) or nil
    end

    ---@type fun(u: unit)
    function UnitDeindex(u)
        if DEV_ENABLED then
            if EXTRA_DEBUG then
                DisplayTimedTextToForce(FORCE_PLAYING, 30., "UNREG " .. GetUnitName(u))
            end
        end

        TableRemove(SummonGroup, u)

        --redundant?
        Threat[u] = nil
        Unit[u] = nil
    end

    ---@type fun(u: unit)
    function UnitIndex(u)
        if u and not IsDummy(u) and GetUnitAbilityLevel(u, DETECT_LEAVE_ABILITY) == 0 then
            UnitAddAbility(u, DETECT_LEAVE_ABILITY)
            UnitMakeAbilityPermanent(u, true, DETECT_LEAVE_ABILITY)

            TriggerRegisterUnitEvent(ACQUIRE_TRIGGER, u, EVENT_UNIT_ACQUIRED_TARGET)

            if DEV_ENABLED then
                if EXTRA_DEBUG then
                    print("REG " .. GetUnitName(u))
                end
            end
        end
    end

    ---@return boolean
    local function onIndex()
        UnitIndex(GetFilterUnit())

        return false
    end

    local onEnter = CreateTrigger()

    TriggerRegisterEnterRegion(onEnter, WorldBounds.region, Filter(onIndex))
end, Debug.getLine())
