--[[
    unittable.lua

    A library that defines a Unit interface that indexes newly
    created units.
]]

OnInit.final("UnitTable", function(Require)
    Require('TimerQueue')
    Require('WorldBounds')
    Require('Events')

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
    ---@field overmovespeed number
    ---@field ms_flat number
    ---@field ms_percent number
    ---@field armor_pen_percent number
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

        --dot method get operators
        local get_operators = {
            str = function(tbl)
                return GetHeroStr(tbl.unit, false)
            end,
            agi = function(tbl)
                return GetHeroAgi(tbl.unit, false)
            end,
            int = function(tbl)
                return GetHeroInt(tbl.unit, false)
            end,
        }

        --dot method set operators
        local set_operators = {
            str = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_HERO_BASE_STR, val)
            end,
            agi = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_HERO_BASE_AGI, val)
            end,
            int = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_HERO_BASE_INT, val)
            end,
            x = function(tbl, val)
                SetUnitXBounded(tbl.unit, val)
            end,
            y = function(tbl, val)
                SetUnitYBounded(tbl.unit, val)
            end,
            cc_flat = function(tbl, val)
                tbl.cc = val * tbl.proxy.cc_percent
            end,
            cd_flat = function(tbl, val)
                tbl.cd = val * tbl.proxy.cd_percent
            end,
            cc_percent = function(tbl, val)
                tbl.cc = tbl.proxy.cc_flat * val
            end,
            cd_percent = function(tbl, val)
                tbl.cd = tbl.proxy.cd_flat * val
            end,
            ms_flat = function(tbl, val)
                tbl.movespeed = val * tbl.proxy.ms_percent
            end,
            ms_percent = function(tbl, val)
                tbl.movespeed = tbl.proxy.ms_flat * val
            end,
            overmovespeed = function(tbl, val)
                tbl.movespeed = val or tbl.proxy.ms_flat * tbl.proxy.ms_percent
            end,
            movespeed = function(tbl, val)
                tbl.proxy.movespeed = tbl.proxy.overmovespeed or math.min(MOVESPEED.SOFTCAP, math.ceil(val))
                UnitSetBonus(tbl.unit, BONUS_MOVE_SPEED, tbl.proxy.movespeed)
            end,
            regen = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_LIFE_REGEN, val)
            end,
            attack = function(tbl, val)
                rawset(tbl, "can_attack", val)

                if not IS_AUTO_ATTACK_OFF[tbl.pid] then
                    BlzSetUnitWeaponBooleanField(tbl.unit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, val)
                end
            end,
            cast_time = function(tbl, val)
                tbl.casting = true
                PauseUnit(tbl.unit, true)

                TimerQueue:callDelayed(val, thistype.castFinish, tbl)
            end
        }

        local mt = {
                __index = function(tbl, key)
                    if get_operators[key] then
                        return get_operators[key](tbl)
                    else
                        return (rawget(thistype, key) or rawget(tbl.proxy, key))
                    end
                end,
                __newindex = function(tbl, key, val)
                    rawset(tbl.proxy, key, val)
                    if set_operators[key] then
                        set_operators[key](tbl, val)
                    end

                    --update life regeneration
                    UnitSetBonus(tbl.unit, BONUS_LIFE_REGEN, (tbl.noregen == true and 0) or tbl.regen * tbl.healamp)
                end,
            }

        ---@type fun(u: unit): Unit
        function thistype.create(u)
            local self = {}

            self.pid = GetPlayerId(GetOwningPlayer(u)) + 1
            self.unit = u
            self.attackCount = 0
            self.casting = false
            self.can_attack = true
            self.threat = __jarray(0)
            self.proxy = { --used for __newindex behavior
                evasion = 0,
                dr = 1., --resists
                mr = 1.,
                pr = 1.,
                dm = 1., --multipliers
                mm = 1.,
                pm = 1.,
                cc_flat = 0., --crit
                cc_percent = 1.,
                cd_flat = 0.,
                cd_percent = 1.,
                cc = 0.,
                cd = 1.,
                regen = BlzGetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE),
                noregen = false,
                healamp = 1.,
                ms_flat = GetUnitMoveSpeed(u),
                ms_percent = 1.,
                movespeed = GetUnitMoveSpeed(u),
                x = GetUnitX(u),
                y = GetUnitY(u),
                spellboost = 0.,
                armor_pen_percent = 0.,
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

    ---@type fun(u: unit)
    function UnitDeindex(u)
        TableRemove(SummonGroup, u)

        --redundant?
        Threat[u] = nil
        Unit[u] = nil
    end

    ---@type fun(u: unit)
    function UnitIndex(u)
        if u and not IsDummy(u) and GetUnitAbilityLevel(u, DETECT_LEAVE_ABILITY) == 0 then
            -- first time setup for abilities
            local index = 0
            local abil = BlzGetUnitAbilityByIndex(u, index)

            while abil do
                local id = BlzGetAbilityId(abil)
                if Spells[id] then
                    Spells[id]:setup(u)
                end

                index = index + 1
                abil = BlzGetUnitAbilityByIndex(u, index)
            end

            UnitAddAbility(u, DETECT_LEAVE_ABILITY)
            UnitMakeAbilityPermanent(u, true, DETECT_LEAVE_ABILITY)
        end
    end

    ---@return boolean
    local function onIndex()
        UnitIndex(GetFilterUnit())

        return false
    end

    local onEnter = CreateTrigger()

    TriggerRegisterEnterRegion(onEnter, WorldBounds.region, Filter(onIndex))
end, Debug and Debug.getLine())
