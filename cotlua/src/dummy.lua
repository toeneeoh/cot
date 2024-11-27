--[[
    dummy.lua

    A module used to create and recycle dummies for spell casting and projectile effects.
    Includes globals / helpers for DPS testing.
]]

OnInit.final("Dummy", function(Require)
    Require("TimerQueue")
    Require("Events")
    Require("Units")
    Require('Frames')

    DUMMY_COUNT = 0
    DUMMY_STACK = {}
    DUMMY_RECYCLE_TIME = 5.

    DPS_TIMER          = TimerQueue.create()
    DPS_STOPWATCH      = Stopwatch.create(false) ---@type Stopwatch
    DPS_TOTAL_PHYSICAL = 0.
    DPS_TOTAL_MAGIC    = 0.
    DPS_TOTAL          = 0.
    DPS_LAST           = 0.
    DPS_CURRENT        = 0.
    DPS_PEAK           = 0.
    DPS_STORAGE        = CircularArrayList.create(30) ---@type CircularArrayList 

    PUNCHING_BAG       = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), FourCC('h02D'), GetRectCenterX(gg_rct_Punching_Bag), GetRectCenterY(gg_rct_Punching_Bag), 0.)

    ---@class Dummy
    ---@field unit unit
    ---@field abil integer
    ---@field recycle function
    ---@field create function
    ---@field cast function
    ---@field source unit
    ---@field attack function
    ---@field lightning function
    Dummy = {} ---@type Dummy|Dummy[]
    do
        local thistype = Dummy
        local mt = { __index = thistype }

        ---@type fun(self: Dummy, owner: player, order: string, a: any, b: any)
        function thistype:cast(owner, order, a, b)
            SetUnitOwner(self.unit, owner, true)

            -- self cast
            if a == nil then
                IssueImmediateOrder(self.unit, order)
            -- target cast
            elseif type(a == "userdata") then
                BlzSetUnitFacingEx(self.unit, bj_RADTODEG * Atan2(GetUnitY(a) - GetUnitY(self.unit), GetUnitX(a) - GetUnitX(self.unit)))
                IssueTargetOrder(self.unit, order, a)
            -- point cast
            elseif type(a == "number") then
                BlzSetUnitFacingEx(self.unit, bj_RADTODEG * Atan2(b - GetUnitY(self.unit), a - GetUnitX(self.unit)))
                IssuePointOrder(self.unit, order, a, b)
            end
        end

        function thistype:lightning(x, y)
            local dummy = thistype.create(x, y, 0, 0, 1.)
            UnitRemoveAbility(dummy.unit, FourCC('Avul'))
            UnitRemoveAbility(dummy.unit, FourCC('Aloc'))
            self:attack(dummy.unit)
        end

        ---@type fun(self: Dummy)
        function thistype:recycle()
            UnitRemoveAbility(self.unit, self.abil)
            self.abil = 0
            self.source = nil

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
            EVENT_DUMMY_ON_HIT:unregister_unit_action(self.unit)
        end

        local function onAggro(source, target)
            BlzSetUnitWeaponBooleanField(source, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
        end

        ---@type fun(x: number, y: number, abil: integer, ablev: integer, dur: any): Dummy
        function Dummy.create(x, y, abil, ablev, dur)
            local self = DUMMY_STACK[#DUMMY_STACK]

            -- available list is empty
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
                EVENT_ON_AGGRO:register_unit_action(self.unit, onAggro)

                Dummy[self.unit] = self

                setmetatable(self, mt)
            -- use an existing available dummy
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

            -- reset attack cooldown
            BlzSetUnitAttackCooldown(self.unit, 0.01, 0)
            UnitSetBonus(self.unit, BONUS_ATTACK_SPEED, 4.)

            SetUnitXBounded(self.unit, x)
            SetUnitYBounded(self.unit, y)

            return self
        end

        ---@type fun(self: Dummy, enemy: unit, source: unit, func: function)
        function thistype:attack(enemy, source, func)
            BlzSetUnitFacingEx(self.unit, bj_RADTODEG * Atan2(GetUnitY(enemy) - GetUnitY(self.unit), GetUnitX(enemy) - GetUnitX(self.unit)))
            UnitDisableAbility(self.unit, FourCC('Amov'), true)
            self.source = source or self.unit
            SetUnitOwner(self.unit, GetOwningPlayer(source), false)
            if func then
                EVENT_DUMMY_ON_HIT:register_unit_action(source, func)
            end
            InstantAttack(self.unit, enemy)
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

    local function calcPeakDps()
        local i = DPS_STORAGE.START ---@type integer 
        local output = 0.
        local dps = 0.
        local count = DPS_STORAGE.count

        while count > 0 and DPS_STORAGE.data[i] do
            dps = dps + DPS_STORAGE.data[i]
            i = ModuloInteger((i + 1), DPS_STORAGE.MAXSIZE)
            count = count - 1
        end

        if dps > output then
            output = dps
        end

        return output
    end

    function DPS_PEAK_UPDATE()
        local time = DPS_STOPWATCH:getElapsed()
        local calc = calcPeakDps()

        DPS_CURRENT = (DPS_TOTAL / math.ceil(time))
        if calc > DPS_PEAK then
            DPS_PEAK = calc
        end
        if DPS_CURRENT > DPS_PEAK then
            DPS_PEAK = DPS_CURRENT
        end
    end

    function DPS_UPDATE()
        local time = DPS_STOPWATCH:getElapsed()

        if DPS_TOTAL > 0 then
            BlzFrameSetText(DPS_FRAME_TEXTVALUE, RealToString(DPS_LAST) .. "\n" .. RealToString(DPS_TOTAL_PHYSICAL) .. "\n" .. RealToString(DPS_TOTAL_MAGIC) .. "\n" .. RealToString(DPS_TOTAL) .. "\n" .. RealToString(DPS_CURRENT) .. "\n" .. RealToString(DPS_PEAK) .. "\n" .. RealToString(time) .. "s")
        end
    end

    local dps_check = function()
        return DPS_TOTAL <= 0
    end

    local function DPS_ON_HIT(target, source, amount, amount_after_red, damage_type)
        local pid = GetPlayerId(GetOwningPlayer(source)) + 1

        if GetLocalPlayer() == Player(pid - 1) then
            BlzFrameSetVisible(DPS_FRAME, true)
        end
        local pt = TimerList[pid]:get('pbag')

        if pt then
            pt.dur = 10.
        else
            pt = TimerList[pid]:add()
            pt.dur = 10.
            pt.tag = 'pbag'
            pt.timer:callDelayed(1., DPS_HIDE_TEXT, pt)
        end

        if DPS_TOTAL <= 0 then
            DPS_STOPWATCH:start()
            TimerQueue:callPeriodically(0.2, dps_check, DPS_UPDATE)
            TimerQueue:callPeriodically(1., dps_check, DPS_PEAK_UPDATE)
        end

        DPS_LAST = amount_after_red

        if damage_type == PHYSICAL then
            DPS_TOTAL_PHYSICAL = (DPS_TOTAL_PHYSICAL + DPS_LAST)
        elseif damage_type == MAGIC then
            DPS_TOTAL_MAGIC = (DPS_TOTAL_MAGIC + DPS_LAST)
        end
        DPS_TOTAL = (DPS_TOTAL + DPS_LAST)

        DPS_STORAGE:add_timed(DPS_LAST, 1., 0.)
        DPS_TIMER:reset()
        DPS_TIMER:callDelayed(7.5, DPS_RESET)
        amount.value = 0.
        SetWidgetLife(target, BlzGetUnitMaxHP(target))
    end

    EVENT_ON_STRUCK_FINAL:register_unit_action(PUNCHING_BAG, DPS_ON_HIT)

end, Debug and Debug.getLine())
