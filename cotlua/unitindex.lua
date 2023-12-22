if Debug then Debug.beginFile 'UnitIndex' end

OnInit.final("UnitIndex", function(require)
    require 'TimerQueue'
    require 'WorldBounds'

    DETECT_LEAVE_ABILITY         = FourCC('uDex') ---@type integer 

    ---@class Unit
    ---@field unit unit
    ---@field create function
    ---@field list Unit[]
    ---@field attackCount integer
    Unit = {}
    do
        local thistype = Unit
        thistype.unit                 = nil ---@type unit 
        thistype.pid                  = 0 ---@type integer 
        thistype.attackCount          = 0 ---@type integer 
        thistype.casting              = false ---@type boolean 
        thistype.canAttack            = true ---@type boolean 
        thistype.list = {}

        -- metatable to handle indices (Unit[unit])
        local mt = {
            __index = function(tbl, key)
                if rawget(tbl, key) then
                    return rawget(tbl, key)
                else
                    local new = __jarray(0)
                    rawset(tbl, key, new)
                    return new
                end
            end
        }

        -- Set metatable for the Unit table
        setmetatable(thistype, mt)

        ---@type fun(u: unit):Unit
        function thistype.create(u)
            local self = {
                pid = GetPlayerId(GetOwningPlayer(u)) + 1,
                unit = u,
                canAttack = true,
                casting = false,
                attackCount = 0
            }

            table.insert(thistype.list, self)
            setmetatable(self, { __index = Unit })

            return self
        end

        function thistype:destroy()
            thistype[self] = nil

            for i, v in ipairs(thistype.list) do
                if v == self then
                    thistype.list[i] = nil
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

        function thistype:attack(b)
            self.canAttack = b

            if not autoAttackDisabled[self.pid] then
                BlzSetUnitWeaponBooleanField(self.unit, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, b)
            end
        end

        function thistype:castTime(dur)
            self.casting = true
            PauseUnit(self.unit, true)

            TimerQueue:callDelayed(dur, castFinish, self)
        end
    end

    ---@param u unit
    ---@return unit
    function GetUnitTarget(u)
        return Threat[u][UNIT_TARGET]
    end

    ---@param whichUnit unit
    function UnitDeindex(whichUnit)
        if Unit[whichUnit] then
            if LIBRARY_dev then
                if EXTRA_DEBUG then
                    DisplayTimedTextToForce(FORCE_PLAYING, 30., "UNREG " .. GetUnitName(whichUnit))
                end
            end

            if Threat[whichUnit] then
                Threat[whichUnit] = nil
            end

            Unit[whichUnit]:destroy()
        end
    end

    ---@return boolean
    local function IndexUnit()
        local u = GetFilterUnit()

        if u and GetUnitTypeId(u) ~= DUMMY then
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

    GroupEnumUnitsOfPlayer(ug, pboss, Filter(IndexUnit)) --index preplaced bosses
    GroupEnumUnitsOfPlayer(ug, Player(PLAYER_NEUTRAL_AGGRESSIVE), Filter(IndexUnit)) --punching bags
    TriggerRegisterEnterRegion(CreateTrigger(), WorldBounds.worldRegion, Filter(IndexUnit))

    DestroyGroup(ug)
end)

if Debug then Debug.endFile() end
