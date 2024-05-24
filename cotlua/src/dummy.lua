--[[
    dummy.lua

    A module used to create and recycle dummies for spell casting and projectile effects.
    Includes globals / helpers for DPS testing.
]]

OnInit.final("Dummy", function()

    DUMMY_COUNT = 0
    DUMMY_STACK = {}
    DUMMY_RECYCLE_TIME = 5.

    DPS_TIMER          = CreateTimer() ---@type timer 
    DPS_TOTAL_PHYSICAL = 0. ---@type number 
    DPS_TOTAL_MAGIC    = 0. ---@type number 
    DPS_TOTAL          = 0. ---@type number 
    DPS_LAST           = 0. ---@type number 
    DPS_CURRENT        = 0. ---@type number 
    DPS_PEAK           = 0. ---@type number 
    DPS_STORAGE        = CircularArrayList.create() ---@type CircularArrayList 

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

    --Punching Bag helper functions
    ---@type fun(pt: PlayerTimer)
    function DPS_HIDE_TEXT(pt)
        pt.dur = pt.dur - 1

        if pt.dur <= 0 then
            if GetLocalPlayer() == Player(pt.pid - 1) then
                BlzFrameSetVisible(DPS_FRAME, false)
            end

            pt:destroy()
        end

        pt.timer:callDelayed(1., DPS_HIDE_TEXT, pt)
    end

    function DPS_RESET()
        DPS_TOTAL_PHYSICAL = 0.
        DPS_TOTAL_MAGIC = 0.
        DPS_TOTAL = 0.
        DPS_LAST = 0.
        DPS_CURRENT = 0.
        DPS_PEAK = 0.
        DPS_STORAGE:wipe()
        BlzFrameSetText(DPS_FRAME_TEXTVALUE, "0\n0\n0\n0\n0\n0\n0s")
    end

    ---@type fun(pt: PlayerTimer)
    function DPS_UPDATE(pt)
        pt.time = pt.time + 0.1

        if DPS_TOTAL <= 0 or DPS_TOTAL > 2000000000 then
            DPS_RESET()
            pt:destroy()
        else
            DPS_STORAGE:add(DPS_TOTAL)
            if pt.time >= 1. then
                DPS_PEAK = math.max(math.max(DPS_STORAGE:calcPeakDps(10), DPS_PEAK), DPS_CURRENT)
                DPS_CURRENT = DPS_TOTAL / pt.time
            end

            BlzFrameSetText(DPS_FRAME_TEXTVALUE, RealToString(DPS_LAST) .. "\n" .. RealToString(DPS_TOTAL_PHYSICAL) .. "\n" .. RealToString(DPS_TOTAL_MAGIC) .. "\n" .. RealToString(DPS_TOTAL) .. "\n" .. RealToString(DPS_CURRENT) .. "\n" .. RealToString(DPS_PEAK) .. "\n" .. RealToString(pt.time) .. "s")
            pt.timer:callDelayed(0.1, DPS_UPDATE, pt)
        end
    end
end, Debug.getLine())
