if Debug then Debug.beginFile 'UnitIndex' end

OnInit.final("UnitIndex", function(require)
    require 'TimerQueue'
    require 'WorldBounds'

    DETECT_LEAVE_ABILITY = FourCC('uDex') ---@type integer 

    ---@class Unit
    ---@field pid integer
    ---@field unit unit
    ---@field create function
    ---@field list Unit[]
    ---@field attackCount integer
    Unit = {}
    do
        local thistype = Unit
        thistype.list = {}

        ---@type fun(u: unit):Unit
        function thistype.create(u)
            local self = {}

            self.pid = GetPlayerId(GetOwningPlayer(u)) + 1
            self.unit = u
            self.attackCount = 0
            self.casting = false
            self.canAttack = true

            Unit[u] = self
            thistype.list[#thistype.list + 1] = self

            setmetatable(self, { __index = Unit, __newindex = function(tbl, key, val)
                if key == "attack" then --method operator for .attack
                    tbl.canAttack = val

                    if not autoAttackDisabled[tbl.pid] then
                        BlzSetUnitWeaponBooleanField(tbl.unit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, val)
                    end
                end
                rawset(tbl, key, val)
            end})

            return self
        end

        function thistype:destroy()
            for i, v in ipairs(thistype.list) do
                if v == self then
                    thistype.list[i] = thistype.list[#thistype.list]
                    thistype.list[#thistype.list] = nil
                    break
                end
            end

            self = nil
        end

        ---@param this Unit
        local function castFinish(this)
            if this then
                this.casting = false
                PauseUnit(this.unit, false)
            end
        end

        function thistype:castTime(dur)
            self.casting = true
            PauseUnit(self.unit, true)

            TimerQueue:callDelayed(dur, castFinish, self)
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
        if Unit[u] then
            if LIBRARY_dev then
                if EXTRA_DEBUG then
                    DisplayTimedTextToForce(FORCE_PLAYING, 30., "UNREG " .. GetUnitName(u))
                end
            end

            TableRemove(SummonGroup, u)

            Threat[u] = nil
            Unit[u]:destroy()
        end
    end

    ---@return boolean
    local function IndexUnit()
        local u = GetFilterUnit()

        if u and GetUnitTypeId(u) ~= DUMMY and not Unit[u] then
            UnitAddAbility(u, DETECT_LEAVE_ABILITY)
            UnitMakeAbilityPermanent(u, true, DETECT_LEAVE_ABILITY)

            Unit.create(u)

            TriggerRegisterUnitEvent(ACQUIRE_TRIGGER, u, EVENT_UNIT_ACQUIRED_TARGET)

            if LIBRARY_dev then
                if EXTRA_DEBUG then
                    DisplayTimedTextToForce(FORCE_PLAYING, 30., "REG " .. GetUnitName(u))
                end
            end
        end

        return false
    end

    local ug = CreateGroup()
    local onEnter = CreateTrigger()

    GroupEnumUnitsOfPlayer(ug, Player(PLAYER_NEUTRAL_AGGRESSIVE), Filter(IndexUnit)) --punching bags
    TriggerRegisterEnterRegion(onEnter, WorldBounds.region, Filter(IndexUnit))

    DestroyGroup(ug)
end)

if Debug then Debug.endFile() end
