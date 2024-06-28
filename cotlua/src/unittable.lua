--[[
    unittable.lua

    A library that defines the Unit interface that registers newly
    created units for OO purposes.
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

        --dot method operators
        local operators = {
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

                if IS_AUTO_ATTACK_ON[tbl.pid] then
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
                    return (rawget(thistype, key) or rawget(tbl.proxy, key))
                end,
                __newindex = function(tbl, key, val)
                    rawset(tbl.proxy, key, val)
                    if operators[key] then
                        operators[key](tbl, val)
                    end

                    --update life regeneration
                    UnitSetBonus(tbl.unit, BONUS_LIFE_REGEN, (tbl.noregen == true and 0) or tbl.regen * tbl.healamp)
                end,
            }

        ---@type fun(u: unit):Unit
        function thistype.create(u)
            local self = {}

            self.pid = GetPlayerId(GetOwningPlayer(u)) + 1
            self.unit = u
            self.attackCount = 0
            self.casting = false
            self.can_attack = true
            self.threat = __jarray(0)
            self.proxy = { --used for __newindex behavior
                str = GetHeroStr(u, false),
                agi = GetHeroAgi(u, false),
                int = GetHeroInt(u, false),
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

    --TODO move this
    local function ursa_frost_nova(target, source)
        IssueTargetOrder(target, "frostnova", source)
    end

    local function forgotten_one_tentacle(target, source)
        if GetRandomInt(1, 5) == 1 then
            IssueImmediateOrder(target, "waterelemental")
        end
    end

    local function legion_reality_rip(source, target)
        local dmg = (IsUnitIllusion(source) and BlzGetUnitMaxHP(target) * 0.0025) or BlzGetUnitMaxHP(target) * 0.005
        DamageTarget(source, target, dmg, ATTACK_TYPE_NORMAL, MAGIC, "Reality Rip")
    end

    local function death_knight_decay(source, target)
        if GetRandomInt(0, 99) < 20 then
            DamageTarget(source, target, 2500., ATTACK_TYPE_NORMAL, MAGIC, "Decay")
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl", target, "origin"))
        end
    end

    local function hate_spell_reflect(target, source, amount)
        if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A00S')) <= 0 and amount.value > 10000. then
            local angle = Atan2(GetUnitY(source) - GetUnitY(target), GetUnitX(source) - GetUnitX(target))
            local sfx = AddSpecialEffect("war3mapImported\\BoneArmorCasterTC.mdx", GetUnitX(target) + 75. * Cos(angle), GetUnitY(target) + 75. * Sin(angle))

            BlzSetSpecialEffectZ(sfx, BlzGetUnitZ(target) + 80.)
            BlzSetSpecialEffectColorByPlayer(sfx, Player(0))
            BlzSetSpecialEffectYaw(sfx, angle)
            BlzSetSpecialEffectScale(sfx, 0.9)
            BlzSetSpecialEffectTimeScale(sfx, 3.)

            DestroyEffect(sfx)

            BlzStartUnitAbilityCooldown(target, FourCC('A00S'), 5.)
            --call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\ManaShield\\ManaShieldCaster.mdl", target, "origin"))
            DamageTarget(target, source, math.min(amount.value, 2500), ATTACK_TYPE_NORMAL, MAGIC, "Spell Reflect")

            amount.value = math.max(0, amount.value - 20000)
        end
    end

    local function mystic_mana_shield(target, source, amount, amount_after_red)
        dmg = GetUnitState(target, UNIT_STATE_MANA) - amount_after_red / 3.

        if dmg >= 0. then
            UnitAddAbility(target, FourCC('A058'))
            ArcingTextTag.create(RealToString(amount_after_red / 3.), target, 1, 2, 170, 50, 220, 0)
        else
            UnitRemoveAbility(target, FourCC('A058'))
        end

        SetUnitState(target, UNIT_STATE_MANA, math.max(0., dmg))

        amount.value = math.max(0., 0. - dmg * 3.)
    end

    ---@type fun(u: unit)
    function UnitIndex(u)
        if u and not IsDummy(u) and GetUnitAbilityLevel(u, DETECT_LEAVE_ABILITY) == 0 then
            UnitAddAbility(u, DETECT_LEAVE_ABILITY)
            UnitMakeAbilityPermanent(u, true, DETECT_LEAVE_ABILITY)

            --unit one-time initialization here
            --register ability stats
            --30% magic resist
            if GetUnitAbilityLevel(u, FourCC('A04A')) > 0 then
                Unit[u].mr = Unit[u].mr * 0.7
            end

            --ursa elder frost nova
            if GetUnitTypeId(u) == FourCC('nfpe') then
                EVENT_ON_STRUCK:register_unit_action(u, ursa_frost_nova)
            end

            --forgotten one tentacle
            if GetUnitTypeId(u) == FourCC('n08M') then
                EVENT_ON_STRUCK:register_unit_action(u, forgotten_one_tentacle)
            end

            --legion reality rip
            if GetUnitAbilityLevel(u, FourCC('A06M')) > 0 then
                EVENT_ON_HIT_NO_EVADE:register_unit_action(u, legion_reality_rip)
            end

            --death knight decay
            if GetUnitAbilityLevel(u, FourCC('A08N')) > 0 then
                EVENT_ON_HIT_NO_EVADE:register_unit_action(u, death_knight_decay)
            end

            --spell reflect (boss_hate) (before reductions)
            if GetUnitAbilityLevel(u, FourCC('A00S')) > 0 then
                EVENT_ON_STRUCK_MULTIPLIER:register_unit_action(u, hate_spell_reflect)
            end

            --mystic mana shield
            if GetUnitAbilityLevel(u, FourCC('A062')) > 0 then
                EVENT_ON_STRUCK_AFTER_REDUCTIONS:register_unit_action(u, mystic_mana_shield)
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
end, Debug and Debug.getLine())
