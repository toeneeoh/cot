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
    ---@field owner player
    ---@field pid integer
    ---@field unit unit
    ---@field create function
    ---@field attackCount integer
    ---@field evasion integer
    ---@field regen number
    ---@field regen_percent number
    ---@field regen_max number
    ---@field mana_regen number
    ---@field mana_regen_percent number
    ---@field mana_regen_max number
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
    ---@field taunt function
    Unit = {}
    do
        local thistype = Unit

        setmetatable(Unit, {
            -- create a new unit object
            __index = function(tbl, key)
                if type(key) == "userdata" and not IsDummy(key) then
                    local new = Unit.create(key)

                    rawset(tbl, key, new)
                    return new
                end
            end,
            -- make keys weak for when units are removed
            __mode = 'k'
        })

        local function finish_cast(self)
            self.casting = false
        end

        -- dot method get operators
        local get_operators = {
            str = function(tbl, key)
                return GetHeroStr(tbl.unit, false)
            end,
            agi = function(tbl, key)
                return GetHeroAgi(tbl.unit, false)
            end,
            int = function(tbl, key)
                return GetHeroInt(tbl.unit, false)
            end,
            hp = function(tbl, key)
                return tbl.bonus_hp + tbl.base_hp + 25 * (tbl.str + tbl.bonus_str)
            end,
            mana = function(tbl, key)
                return tbl.bonus_mana + tbl.base_mana + 20 * (tbl.int + tbl.bonus_int)
            end,
            regen = function(tbl, key)
                return (tbl.noregen == true and 0) or (tbl.regen_flat + tbl.regen_max * tbl.hp * 0.01) * tbl.regen_percent
            end,
            mana_regen = function(tbl, key)
                return (tbl.nomanaregen == true and 0) or (tbl.mana_regen_flat + GetHeroInt(tbl.unit, true) * 0.05 + tbl.mana_regen_max * tbl.mana * 0.01) * tbl.mana_regen_percent
            end,
            bat = function(tbl, key)
                return tbl.base_bat * tbl.bonus_bat
            end,
        }

        -- dot method set operators
        local set_operators = {
            bonus_hp = function(tbl, val)
                BlzSetUnitMaxHP(tbl.unit, tbl.hp)
            end,
            bonus_mana = function(tbl, val)
                BlzSetUnitMaxMana(tbl.unit, tbl.mana)
            end,
            str = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_HERO_BASE_STR, val)
                BlzSetUnitMaxHP(tbl.unit, tbl.hp)
            end,
            agi = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_HERO_BASE_AGI, val)
            end,
            int = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_HERO_BASE_INT, val)
                BlzSetUnitMaxMana(tbl.unit, tbl.mana)
                UnitSetBonus(tbl.unit, BONUS_MANA_REGEN, tbl.mana_regen)
            end,
            bonus_str = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_HERO_STR, val)
                BlzSetUnitMaxHP(tbl.unit, tbl.hp)
            end,
            bonus_agi = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_HERO_AGI, val)
            end,
            bonus_int = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_HERO_INT, val)
                BlzSetUnitMaxMana(tbl.unit, tbl.mana)
                UnitSetBonus(tbl.unit, BONUS_MANA_REGEN, tbl.mana_regen)
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
            regen_flat = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_LIFE_REGEN, tbl.regen)
            end,
            regen_percent = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_LIFE_REGEN, tbl.regen)
            end,
            regen_max = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_LIFE_REGEN, tbl.regen)
            end,
            mana_regen_flat = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_MANA_REGEN, tbl.mana_regen)
            end,
            mana_regen_percent = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_MANA_REGEN, tbl.mana_regen)
            end,
            mana_regen_max = function(tbl, val)
                UnitSetBonus(tbl.unit, BONUS_MANA_REGEN, tbl.mana_regen)
            end,
            attack = function(tbl, val)
                rawset(tbl, "can_attack", val)

                if not IS_AUTO_ATTACK_OFF[tbl.pid] then
                    BlzSetUnitWeaponBooleanField(tbl.unit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, val)
                end
            end,
            cast_time = function(tbl, val)
                tbl.casting = true

                TimerQueue:callDelayed(val, finish_cast, tbl)
            end,
            base_bat = function(tbl, val)
                BlzSetUnitAttackCooldown(tbl.unit, tbl.bat, 0)
            end,
            bonus_bat = function(tbl, val)
                BlzSetUnitAttackCooldown(tbl.unit, tbl.bat, 0)
            end,
            hidehp = function(tbl, val)
                if GetMainSelectedUnit() == tbl.unit then
                    BlzFrameSetVisible(HIDE_HEALTH_FRAME, val)
                end
            end,
        }

        local mt = {
                __index = function(tbl, key)
                    if get_operators[key] then
                        return get_operators[key](tbl, key)
                    else
                        return (rawget(thistype, key) or rawget(tbl.proxy, key))
                    end
                end,
                __newindex = function(tbl, key, val)
                    rawset(tbl.proxy, key, val)
                    if set_operators[key] then
                        set_operators[key](tbl, val)
                    end

                    -- trigger stat change event
                    EVENT_STAT_CHANGE:trigger(tbl.unit)
                end,
            }

        ---@type fun(u: unit): Unit
        function thistype.create(u)
            local self = {}

            self.owner = GetOwningPlayer(u)
            self.pid = GetPlayerId(self.owner) + 1
            self.unit = u
            self.attackCount = 0
            self.casting = false
            self.can_attack = true
            self.base_hp = BlzGetUnitMaxHP(u)
            self.base_mana = BlzGetUnitMaxMana(u)
            self.proxy = { -- used for __newindex behavior
                bonus_hp = 0,
                bonus_mana = 0,
                evasion = 0,
                str = GetHeroStr(u, false),
                agi = GetHeroAgi(u, false),
                int = GetHeroInt(u, false),
                bonus_str = 0,
                bonus_agi = 0,
                bonus_int = 0,
                dr = 1., -- resists
                mr = 1.,
                pr = 1.,
                dm = 1., -- multipliers
                mm = 1.,
                pm = 1.,
                cc_flat = 0., -- crit
                cc_percent = 1.,
                cd_flat = 0.,
                cd_percent = 1.,
                cc = 0.,
                cd = 1.,
                regen_flat = BlzGetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE),
                regen_percent = 1.,
                regen_max = 0, -- percent of max health (0-100)
                noregen = false,
                hidehp = false,
                nomanaregen = false,
                mana_regen_flat = BlzGetUnitRealField(u, UNIT_RF_MANA_REGENERATION),
                mana_regen_percent = 1.,
                mana_regen_max = 0.,
                ms_flat = GetUnitMoveSpeed(u),
                ms_percent = 1.,
                movespeed = GetUnitMoveSpeed(u),
                base_bat = BlzGetUnitAttackCooldown(u, 0),
                bonus_bat = 1.,
                x = GetUnitX(u),
                y = GetUnitY(u),
                spellboost = 0.,
                armor_pen_percent = 0.,
            }
            self.original_x = self.proxy.x
            self.original_y = self.proxy.y
            self.orderX = self.proxy.x
            self.orderY = self.proxy.y

            setmetatable(self, mt)

            return self
        end

        function thistype:taunt(enemy)
            local boss = IsBoss(enemy.unit)
            enemy.target = self
            self.taunted = self.taunted or CreateGroup()
            self.aggro_timer = self.aggro_timer or TimerQueue.create()
            if not boss then -- bosses do not use standard deaggro behavior
                GroupAddUnit(self.taunted, enemy.unit)
                IssueTargetOrder(enemy.unit, "smart", self.unit)
            else
                boss:switch_target(self)
            end
            self.aggro_timer:reset()
            self.aggro_timer:callDelayed(3., DropAggro, self)
        end

        function thistype:destroy()
            if self.taunted then
                DestroyGroup(self.taunted)
            end

            if self.aggro_timer then
                self.aggro_timer:destroy()
            end
        end
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
