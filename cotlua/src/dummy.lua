--[[
    dummy.lua

    A module used to create and recycle dummies for spell casting and projectile effects.
]]

OnInit.final("Dummy", function()

    DUMMY_COUNT = 0
    DUMMY_STACK = {}
    DUMMY_RECYCLE_TIME = 5.

    ---@class Dummy
    ---@field unit unit
    ---@field abil integer
    ---@field recycle function
    ---@field create function
    ---@field cast function
    Dummy = {} ---@type Dummy|Dummy[]
    do
        local thistype = Dummy
        local mt = { __index = thistype }

        ---@type fun(self: Dummy, owner: player, order: string, a: any, b: any)
        function thistype:cast(owner, order, a, b)
            SetUnitOwner(self.unit, owner, true)

            --self cast
            if a == nil then
                IssueImmediateOrder(self.unit, order)
            --target cast
            elseif type(a == "userdata") then
                BlzSetUnitFacingEx(self.unit, bj_RADTODEG * Atan2(GetUnitY(a) - GetUnitY(self.unit), GetUnitX(a) - GetUnitX(self.unit)))
                IssueTargetOrder(self.unit, order, a)
            --point cast
            elseif type(a == "number") then
                BlzSetUnitFacingEx(self.unit, bj_RADTODEG * Atan2(b - GetUnitY(self.unit), a - GetUnitX(self.unit)))
                IssuePointOrder(self.unit, order, a, b)
            end
        end

        ---@type fun(self: Dummy)
        function thistype:recycle()
            UnitRemoveAbility(self.unit, self.abil)
            self.abil = 0

            SetUnitAnimation(self.unit, "stand")
            SetUnitPropWindow(self.unit, bj_DEGTORAD * 180.)
            BlzSetUnitName(self.unit, " ")
            BlzSetUnitWeaponBooleanField(self.unit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
            SetUnitOwner(self.unit, Player(PLAYER_NEUTRAL_PASSIVE), true)
            BlzSetUnitSkin(self.unit, DUMMY_CASTER)
            SetUnitXBounded(self.unit, 30000.)
            SetUnitYBounded(self.unit, 30000.)
            UnitAddAbility(self.unit, FourCC('Aloc'))
            UnitAddAbility(self.unit, FourCC('Avul'))
            SetUnitFlyHeight(self.unit, GetUnitDefaultFlyHeight(self.unit), 0)
            SetUnitScale(self.unit, 1, 1, 1)
            SetUnitVertexColor(self.unit, 255, 255, 255, 255)
            SetUnitTimeScale(self.unit, 1.)
            BlzUnitClearOrders(self.unit, false)
            BlzUnitDisableAbility(self.unit, FourCC('Amov'), false, false)
            PauseUnit(self.unit, true)
            BlzSetUnitAttackCooldown(self.unit, 0.01, 0)
            UnitAddBonus(self.unit, BONUS_ATTACK_SPEED, 4.)
            ShowUnit(self.unit, false)
            DUMMY_STACK[#DUMMY_STACK + 1] = self
        end

        ---@type fun(x: number, y: number, abil: integer, ablev: integer, dur: any): Dummy
        function thistype.create(x, y, abil, ablev, dur)
            local self = DUMMY_STACK[#DUMMY_STACK]

            --available list is empty
            if self == nil then
                DUMMY_COUNT = DUMMY_COUNT + 1
                self = {
                    unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), DUMMY_CASTER, x, y, 0),
                    abil = 0,
                }
                UnitAddAbility(self.unit, FourCC('Amrf'))
                UnitRemoveAbility(self.unit, FourCC('Amrf'))
                UnitAddAbility(self.unit, FourCC('Aloc'))
                SetUnitPathing(self.unit, false)
                TriggerRegisterUnitEvent(ACQUIRE_TRIGGER, self.unit, EVENT_UNIT_ACQUIRED_TARGET)

                Dummy[self.unit] = self

                setmetatable(self, mt)
            --use an existing available dummy
            else
                DUMMY_STACK[#DUMMY_STACK] = nil
                ShowUnit(self.unit, true)
                PauseUnit(self.unit, false)
            end

            if UnitAddAbility(self.unit, abil) then
                SetUnitAbilityLevel(self.unit, abil, ablev)
                self.abil = abil
            end

            if type(dur) == "number" then
                if dur > 0 then
                    TimerQueue:callDelayed(dur, thistype.recycle, self)
                end
            else
                TimerQueue:callDelayed(DUMMY_RECYCLE_TIME, thistype.recycle, self)
            end

            --reset attack cooldown
            BlzSetUnitAttackCooldown(self.unit, 5., 0)
            UnitSetBonus(self.unit, BONUS_ATTACK_SPEED, 0.)

            SetUnitXBounded(self.unit, x)
            SetUnitYBounded(self.unit, y)

            return self
        end
    end
end, Debug.getLine())
