if Debug then Debug.beginFile 'BuffSystem' end

OnInit.global("BuffSystem", function(require)
    require 'TimerQueue'
    require 'UnitEvent'

    -------------------------------//
    ----------- BUFF TYPES --------//
    -------------------------------//
    BUFF_NONE         = 0   ---@type integer 
    BUFF_POSITIVE     = 1     ---@type integer 
    BUFF_NEGATIVE     = 2 ---@type integer 

    -------------------------------//
    -------- BUFF STACK TYPES -----//
    -------------------------------//
    --Applying the same buff only refreshes the duration
    --If the buff is reapplied but from a different source, the Buff unit source gets replaced.
    BUFF_STACK_NONE   = 0 ---@type integer 

    --Each buff from different source stacks.
    --Re-applying the same buff from the same source only refreshes the duration
    BUFF_STACK_PARTIAL= 1 ---@type integer 

    --Each buff applied fully stacks.
    BUFF_STACK_FULL   = 2 ---@type integer 

    --Determines the automatic Buff rawcode based on the Ability rawcode
    --If BUFF_OFFSET = 0x01000000, then Ability rawcode of FourCC('AXXX') will have Buff rawcode of FourCC('BXXX')
    local BUFF_OFFSET = 0x01000000 ---@type integer 
    local buffs = {}
    local count = array2d(0)

    ---@class Buff
    ---@field pid integer
    ---@field tpid integer
    ---@field target unit
    ---@field source unit
    ---@field RAWCODE integer
    ---@field buffId integer
    ---@field STACK_TYPE integer
    ---@field DISPEL_TYPE integer
    ---@field onApply function
    ---@field onRemove function
    ---@field buffs table
    ---@field get function
    ---@field has function
    ---@field remove function
    ---@field removeAll function
    ---@field check function
    ---@field dispel function
    ---@field dispelBoth function
    ---@field dispelAll function
    ---@field add function
    ---@field create function
    ---@field duration function
    Buff = {}
    do
        local thistype = Buff
        --Buff properties
        thistype.pid = 0 ---@type integer
        thistype.tpid = 0 ---@type integer
        thistype.target = nil ---@type unit 
        thistype.source = nil ---@type unit 
        thistype.RAWCODE = 0 ---@type integer 
        thistype.STACK_TYPE = 0 ---@type integer 
        thistype.DISPEL_TYPE = 0 ---@type integer 

        thistype.onApply = DoNothing ---@type function
        thistype.onRemove = DoNothing ---@type function

        --===============================================================
        --======================== BUFF CORE ============================
        --===============================================================    
        ---@type fun(source: unit, target: unit):Buff
        function thistype:get(source, target)
            for i = 1, #buffs do
                if buffs[i].RAWCODE == self.RAWCODE and target == buffs[i].target and (source == nil or source == buffs[i].source) then
                    return buffs[i]
                end
            end

            return nil
        end

        ---@type fun(source: unit, target: unit):boolean
        function thistype:has(source, target)
            return self:get(source, target) ~= nil
        end

        function thistype:remove()
            local remove = false

            if self.STACK_TYPE == BUFF_STACK_FULL or self.STACK_TYPE == BUFF_STACK_PARTIAL then
                --Update Buff count
                count[self.RAWCODE][self.target] = count[self.RAWCODE][self.target] - 1

                if count[self.RAWCODE][self.target] == 0 then
                    remove = true
                end
            elseif self.STACK_TYPE == BUFF_STACK_NONE then
                remove = true
            end

            if remove then
                UnitRemoveAbility(self.target, self.RAWCODE)
                UnitRemoveAbility(self.target, self.RAWCODE + BUFF_OFFSET)
            end

            --remove TimerQueue
            self.t:destroy()
            self.t = nil

            --remove from buffs
            for i = 1, #buffs do
                if buffs[i] == self then
                    buffs[i] = buffs[#buffs]
                    buffs[#buffs] = nil
                    break
                end
            end

            self:onRemove()

            self = nil
        end

        ---@type fun(dur: number):number
        function thistype:duration(dur)
            if dur then
                self.t:reset()
                self.t:callDelayed(dur, self.remove, self)
            else
                return TimerGetRemaining(self.t.timer)
            end

            return 0.0
        end

        ---@type fun(source: unit, target:unit):Buff
        function thistype:check(source, target)
            local apply = false ---@type boolean 
            local similar = self:get(source, target) ---@type Buff

            if self.STACK_TYPE == BUFF_STACK_FULL then
                --Update target buff count
                count[self.RAWCODE][target] = count[self.RAWCODE][target] + 1
                apply = true

            elseif self.STACK_TYPE == BUFF_STACK_PARTIAL then
                if not similar then
                    --Update target buff count
                    count[self.RAWCODE][target] = count[self.RAWCODE][target] + 1
                    apply = true
                else
                    self = similar
                end

            elseif self.STACK_TYPE == BUFF_STACK_NONE then
                if not similar then
                    apply = true
                else
                    self = similar
                end
            end

            self.source = source
            self.target = target

            if apply then
                --Append to buffs
                buffs[#buffs + 1] = self

                if GetUnitAbilityLevel(target, self.RAWCODE) == 0 then
                    UnitAddAbility(target, self.RAWCODE)
                    UnitMakeAbilityPermanent(target, true, self.RAWCODE)
                end

                self:onApply()
            end

            return self
        end

        --===============================================================
        --======================= BUFF DISPEL ===========================
        --===============================================================
        ---@param u unit
        ---@param dispelType integer
        function thistype.dispelType(u, dispelType)
            local i = 1
            while i <= #buffs do
                if buffs[i].target == u and buffs[i].DISPEL_TYPE == dispelType then
                    buffs[i]:remove()
                else
                    i = i + 1
                end
            end
        end

        ---@param u unit
        function thistype.dispelBoth(u)
            local i = 1
            while i <= #buffs do
                if buffs[i].target == u and (buffs[i].DISPEL_TYPE == BUFF_POSITIVE or buffs[i].DISPEL_TYPE == BUFF_NEGATIVE) then
                    buffs[i]:remove()
                else
                    i = i + 1
                end
            end
        end

        ---@param u unit
        function thistype.dispelAll(u)
            local i = 1
            while i <= #buffs do
                if buffs[i].target == u then
                    buffs[i]:remove()
                else
                    i = i + 1
                end
            end
        end

        ---@type fun(source: unit, target: unit)
        function thistype:dispel(source, target)
            for i = 1, #buffs do
                if buffs[i].RAWCODE == self.RAWCODE and target == buffs[i].target and (source == nil or source == buffs[i].source) then
                    buffs[i]:remove()
                    break
                end
            end
        end

        ---@type fun()
        function thistype:removeAll()
            if #buffs > 0 then
                repeat
                    buffs[1]:remove()
                until not buffs[1]
            end
        end

        ---@type fun():Buff
        function thistype:create()
            local b = {}

            b.t = TimerQueue.create()
            setmetatable(b, { __index = self })

            return b
        end

        ---@type fun(source: unit, target: unit):Buff
        function thistype:add(source, target)
            local b = self:create()

            b.pid = GetPlayerId(GetOwningPlayer(source)) + 1
            b.tpid = GetPlayerId(GetOwningPlayer(target)) + 1

            b = b:check(source, target)

            return b
        end

        RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH,
        function()
            thistype.dispelAll(GetTriggerUnit())
        end)
    end
end)

if Debug then Debug.endFile() end
