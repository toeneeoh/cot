--[[
    orders.lua

    This library handles order events
        (EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER,
        EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER,
        EVENT_PLAYER_UNIT_ISSUED_ORDER)
]]

OnInit.final("Orders", function(Require)
    Require('HeroSpells')
    Require('Frames')

    -- define frequently used ids
    ORDER_ID_MOVE          = 851986
    ORDER_ID_HOLD_POSITION = 851972
    ORDER_ID_STOP          = 851993
    ORDER_ID_SMART         = 851971
    ORDER_ID_ATTACK        = 851983
    ORDER_ID_UNDEFEND      = 852056
    ORDER_ID_MANA_SHIELD   = 852589
    ORDER_ID_IMMOLATION    = 852177
    ORDER_ID_UNIMMOLATION  = 852178

    local OrderTable = {
        [ORDER_ID_SMART] = function(id, source, p, pid, target)
            local b = Fear:get(nil, source)

            -- reissue movement order to feared units
            if b then
                IssuePointOrder(source, "move", b.x, b.y)
            end
        end,

        [ORDER_ID_UNDEFEND] = function(id, source, p, pid)
            -- if unit is removed
            if GetUnitAbilityLevel(source, DETECT_LEAVE_ABILITY) == 0 then
                Unit[source]:destroy()
            end
        end,

        -- issued faeriefire on order (devour)
        [852150] = function(id, source, p, pid)
            if TableHas(SummonGroup, source) then
                local pt = TimerList[pid]:get('blif', nil, source)
                if pt then
                    pt:destroy()
                end
                pt = TimerList[pid]:add()
                pt.tag = 'dvou'
                pt.target = source
                pt.timer:callDelayed(1., DEVOUR.autocast, pt, "faeriefire")
            end
        end,

        -- issued faeriefire off order (devour)
        [852151] = function(id, source, p, pid)
            TimerList[pid]:stopAllTimers('dvou')
        end,

        -- issued bloodlust on order (borrowed life)
        [852102] = function(id, source, p, pid)
            if TableHas(SummonGroup, source) then
                local pt = TimerList[pid]:get('dvou', nil, source)
                if pt then
                    pt:destroy()
                end
                pt = TimerList[pid]:add()
                pt.tag = 'blif'
                pt.target = source
                pt.timer:callDelayed(1., DEVOUR.autocast, pt, "bloodlust")
            end
        end,

        -- issued bloodlust off order (borrowed life)
        [852103] = function(id, source, p, pid)
            TimerList[pid]:stopAllTimers('blif')
        end,

        -- issued mana shield on order
        [ORDER_ID_MANA_SHIELD] = function(id, source, p, pid)
            -- warrior parry
            if GetUnitAbilityLevel(source, PARRY.id) > 0 then
                UnitDisableAbility(source, PARRY.id, true)
                UnitDisableAbility(source, PARRY.id, false)
                BlzStartUnitAbilityCooldown(source, PARRY.id, 4.)
                lastCast[pid] = PARRY.id

                local pt = TimerList[pid]:get(ADAPTIVESTRIKE.id)
                UnitDisableAbility(source, ADAPTIVESTRIKE.id, false)

                if LIMITBREAK.flag[pid] & 0x10 > 0 and not pt then
                    ADAPTIVESTRIKE.effect(source, GetUnitX(source), GetUnitY(source))
                    UnitDisableAbility(source, ADAPTIVESTRIKE.id, true)
                    BlzUnitHideAbility(source, ADAPTIVESTRIKE.id, false)
                elseif pt then
                    BlzStartUnitAbilityCooldown(source, ADAPTIVESTRIKE.id, TimerGetRemaining(pt.timer.timer))
                end

                if LIMITBREAK.flag[pid] & 0x1 > 0 then
                    ParryBuff:add(source, source):duration(1.)
                else
                    ParryBuff:add(source, source):duration(0.5)
                end

            -- assassin bladespin
            elseif GetUnitAbilityLevel(source, BLADESPIN.id) > 0 then
                if GetUnitState(source, UNIT_STATE_MANA) >= BlzGetUnitMaxMana(source) * 0.05 then
                    SetUnitState(source, UNIT_STATE_MANA, GetUnitState(source, UNIT_STATE_MANA) - BlzGetUnitMaxMana(source) * 0.05)

                    UnitRemoveAbility(source, BLADESPIN.id)
                    UnitDisableAbility(source, BLADESPIN.id2, false)
                    BLADESPIN.spin(source, true)
                else
                    UnitRemoveAbility(source, BLADESPIN.id)
                    UnitAddAbility(source, BLADESPIN.id)
                end
            end
        end,

        -- issued immolation on order
        [ORDER_ID_IMMOLATION] = function(id, source, p, pid)
            -- phoenix ranger multishot
            if not MULTISHOT.enabled[pid] and GetUnitTypeId(source) == HERO_PHOENIX_RANGER and not Unit[Hero[pid]].busy then
                SetPlayerAbilityAvailable(p, prMulti[IMinBJ(5, GetHeroLevel(source) // 50)], true)
                MULTISHOT.enabled[pid] = true
                Unit[source].pm = Unit[source].pm * 0.6

            -- assassin phantomslash
            elseif GetUnitAbilityLevel(source, PHANTOMSLASH.id) > 0 and not IsUnitStunned(source) then
                local x, y = GetMouseX(pid), GetMouseY(pid)

                if x ~= 0 and y ~= 0 and not PHANTOMSLASH.slashing[pid] then
                    local spell = PHANTOMSLASH:create(source)
                    spell.caster = source
                    spell.targetX = x
                    spell.targetY = y
                    spell.x = GetUnitX(source)
                    spell.y = GetUnitY(source)

                    spell:onCast()
                end

            -- vampire blood mist
            elseif GetUnitAbilityLevel(source, BLOODMIST.id) > 0 then
                BloodMistBuff:add(source, source)
            end
        end,

        -- issued immolation off order
        [852178] = function(id, source, p, pid)
            -- phoenix ranger multishot
            if MULTISHOT.enabled[pid] and GetUnitTypeId(source) == HERO_PHOENIX_RANGER and not Unit[source].busy then
                SetPlayerAbilityAvailable(p, prMulti[0], false)
                SetPlayerAbilityAvailable(p, prMulti[1], false)
                SetPlayerAbilityAvailable(p, prMulti[2], false)
                SetPlayerAbilityAvailable(p, prMulti[3], false)
                SetPlayerAbilityAvailable(p, prMulti[4], false)
                SetPlayerAbilityAvailable(p, prMulti[5], false)
                MULTISHOT.enabled[pid] = false
                Unit[source].pm = Unit[source].pm / 0.6
            end

            -- bard inspire
            if GetUnitAbilityLevel(source, INSPIRE.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
                InspireBuff:dispel(source, source)
            end

            -- bloodzerker rampage
            if GetUnitAbilityLevel(source, RAMPAGE.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
                RampageBuff:dispel(source, source)
            end

            -- thunderblade overload
            if GetUnitAbilityLevel(source, OVERLOAD.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
                OverloadBuff:dispel(source, source)
            end

            -- oblivion guard magnetic stance
            if GetUnitAbilityLevel(source, MAGNETICSTANCE.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
                MagneticStanceBuff:dispel(source, source)
            end

            -- vmapire blood mist
            if GetUnitAbilityLevel(source, BLOODMIST.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
                BloodMistBuff:dispel(source, source)
            end
        end,
    }

    function OnOrder()
        local source = GetTriggerUnit() ---@type unit 
        local p      = GetTriggerPlayer()
        local pid    = GetPlayerId(p) + 1 ---@type integer 
        local id     = GetIssuedOrderId() ---@type integer 
        local itm    = Item[GetOrderTargetItem()]
        local x      = GetOrderPointX()
        local y      = GetOrderPointY()
        local target = GetOrderTargetUnit() ---@type unit 
        local targetX = target and GetUnitX(target)
        local targetY = target and GetUnitY(target)

        -- lookup table
        if OrderTable[id] then
            OrderTable[id](id, source, p, pid, target)
        end

        -- cache issued point / target
        local u = Unit[source]
        if u then
            if target or (x ~= 0 and y ~= 0) then
                u.orderX = targetX or x
                u.orderY = targetY or y
            end

            if pid <= PLAYER_CAP and target and IsUnitEnemy(target, p) then
                u.target = target
            end
        end

        EVENT_ON_ORDER:trigger(source, target, id, x, y)

        -- item target
        if itm then
            -- prevent other units from attacking a bound item
            if id == ORDER_ID_ATTACK and (itm.owner and itm.owner ~= Player(pid - 1)) then
                IssueImmediateOrderById(source, ORDER_ID_HOLD_POSITION)
            end
        end
    end

    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, OnOrder)
    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, OnOrder)
    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, OnOrder)
end, Debug and Debug.getLine())
