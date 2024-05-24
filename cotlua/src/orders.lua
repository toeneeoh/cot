--[[
    orders.lua

    This library handles order events
        (EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER,
        EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER,
        EVENT_PLAYER_UNIT_ISSUED_ORDER)
]]

OnInit.final("Orders", function(Require)
    Require('Users')
    Require('Units')
    Require('Movespeed')

    --define frequently used ids
    ORDER_ID_MOVE           = 851986
    ORDER_ID_HOLD_POSITION  = 851972
    ORDER_ID_STOP           = 851993
    ORDER_ID_SMART          = 851971
    ORDER_ID_ATTACK         = 851983
    ORDER_ID_UNDEFEND       = 852056
    ORDER_ID_MANA_SHIELD    = 852589
    ORDER_ID_IMMOLATION     = 852177
    ORDER_ID_UNIMMOLATION   = 852178

    local OrderTable = {
        [ORDER_ID_HOLD_POSITION] = function(id, source, p, pid)
        end,
        [ORDER_ID_STOP] = function(id, source, p, pid)
        end,
        [ORDER_ID_SMART] = function(id, source, p, pid, target)
            local pt = TimerList[pid]:get('aggr', source)
            --after 3 seconds drop aggro from nearby enemies and redirect to allies if possible
            if not pt then
                pt = TimerList[pid]:add()
                pt.source = source
                pt.tag = 'aggr'
                TimerQueue:callDelayed(3., RunDropAggro, pt)
            end

            local b = Fear:get(nil, source)

            --reissue movement order to feared units
            if b then
                IssuePointOrder(source, "move", b.x, b.y)
            end
        end,

        [ORDER_ID_UNDEFEND] = function(id, source, p, pid)
            if GetPlayerController(GetOwningPlayer(source)) ~= MAP_CONTROL_USER then
                --if unit is removed
                if GetUnitAbilityLevel(source, DETECT_LEAVE_ABILITY) == 0 then
                    UnitDeindex(source)
                end
            end
        end,

        --issued faeriefire on order (devour)
        [852150] = function(id, source, p, pid)
            local pt = TimerList[pid]:get('blif', nil, source)
            if pt then
                pt:destroy()
            end
            pt = TimerList[pid]:add()
            pt.tag = 'dvou'
            pt.target = source
            pt.timer:callDelayed(1., DevourAutocast, pt)
        end,

        --issued faeriefire off order (devour)
        [852151] = function(id, source, p, pid)
            TimerList[pid]:stopAllTimers('dvou')
        end,

        --issued bloodlust on order (borrowed life)
        [852102] = function(id, source, p, pid)
            local pt = TimerList[pid]:get('dvou', nil, source)
            if pt then
                pt:destroy()
            end
            pt = TimerList[pid]:add()
            pt.tag = 'blif'
            pt.target = source
            pt.timer:callDelayed(1., BorrowedLifeAutocast, pt)
        end,

        --issued bloodlust off order (borrowed life)
        [852103] = function(id, source, p, pid)
            TimerList[pid]:stopAllTimers('blif')
        end,

        --issued mana shield on order
        [ORDER_ID_MANA_SHIELD] = function(id, source, p, pid)
            --warrior parry
            if GetUnitAbilityLevel(source, PARRY.id) > 0 then
                UnitDisableAbility(source, PARRY.id, true)
                UnitDisableAbility(source, PARRY.id, false)
                BlzStartUnitAbilityCooldown(source, PARRY.id, 4.)
                lastCast[pid] = PARRY.id

                local pt = TimerList[pid]:get(ADAPTIVESTRIKE.id)
                UnitDisableAbility(source, ADAPTIVESTRIKE.id, false)

                if limitBreak[pid] & 0x10 > 0 and not pt then
                    ADAPTIVESTRIKE.effect(source, GetUnitX(source), GetUnitY(source))
                    UnitDisableAbility(source, ADAPTIVESTRIKE.id, true)
                    BlzUnitHideAbility(source, ADAPTIVESTRIKE.id, false)
                elseif pt then
                    BlzStartUnitAbilityCooldown(source, ADAPTIVESTRIKE.id, TimerGetRemaining(pt.timer.timer))
                end

                if limitBreak[pid] & 0x1 > 0 then
                    ParryBuff:add(source, source):duration(1.)
                else
                    ParryBuff:add(source, source):duration(0.5)
                end

            --assassin bladespin
            elseif GetUnitAbilityLevel(source, BLADESPIN.id) > 0 then
                if GetUnitState(source, UNIT_STATE_MANA) >= BlzGetUnitMaxMana(source) * 0.05 then
                    SetUnitState(source, UNIT_STATE_MANA, GetUnitState(source, UNIT_STATE_MANA) - BlzGetUnitMaxMana(source) * 0.05)

                    UnitRemoveAbility(source, BLADESPIN.id)
                    UnitDisableAbility(source, BLADESPINPASSIVE.id, false)
                    BLADESPIN.spin(source, true)
                else
                    UnitRemoveAbility(source, BLADESPIN.id)
                    UnitAddAbility(source, BLADESPIN.id)
                end
            end
        end,

        --issued immolation on order
        [ORDER_ID_IMMOLATION] = function(id, source, p, pid)
            --phoenix ranger multishot
            if GetUnitTypeId(source) == HERO_PHOENIX_RANGER and not IS_TELEPORTING[pid] then
                SetPlayerAbilityAvailable(p, prMulti[IMinBJ(4, GetHeroLevel(source) // 50)], true)
                MultiShot[pid] = true

            --assassin phantomslash
            elseif GetUnitAbilityLevel(source, PHANTOMSLASH.id) > 0 and not IsUnitStunned(source) then
                if MouseX[pid] ~= 0 and MouseY[pid] ~= 0 and not PhantomSlashing[pid] then
                    local spell = PHANTOMSLASH:create(pid) ---@type PHANTOMSLASH
                    spell.caster = source
                    spell.targetX = MouseX[pid]
                    spell.targetY = MouseY[pid]
                    spell.x = GetUnitX(source)
                    spell.y = GetUnitY(source)

                    spell:onCast()
                end

            --vampire blood mist
            elseif GetUnitAbilityLevel(source, BLOODMIST.id) > 0 then
                BloodMistBuff:add(source, source)
            end
        end,

        --issued immolation off order
        [852178] = function(id, source, p, pid)
            --phoenix ranger multishot
            if GetUnitTypeId(source) == HERO_PHOENIX_RANGER and not IS_TELEPORTING[pid] then
                SetPlayerAbilityAvailable(p, prMulti[0], false)
                SetPlayerAbilityAvailable(p, prMulti[1], false)
                SetPlayerAbilityAvailable(p, prMulti[2], false)
                SetPlayerAbilityAvailable(p, prMulti[3], false)
                SetPlayerAbilityAvailable(p, prMulti[4], false)
                MultiShot[pid] = false
            end

            --bard inspire
            if GetUnitAbilityLevel(source, INSPIRE.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
                InspireBuff:dispel(source, source)
            end

            --bloodzerker rampage
            if GetUnitAbilityLevel(source, RAMPAGE.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
                RampageBuff:dispel(source, source)
            end

            --thunderblade overload
            if GetUnitAbilityLevel(source, OVERLOAD.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
                OverloadBuff:dispel(source, source)
            end

            --oblivion guard magnetic stance
            if GetUnitAbilityLevel(source, MAGNETICSTANCE.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
                MagneticStanceBuff:dispel(source, source)
            end

            --vmapire blood mist
            if GetUnitAbilityLevel(source, BLOODMIST.id) > 0 and IsUnitPaused(source) == false and IsUnitLoaded(source) == false then
                BloodMistBuff:dispel(source, source)
            end
        end,
    }

function OnOrder()
    local source = GetTriggerUnit() ---@type unit 
    local p      = GetTriggerPlayer() ---@type player 
    local pid    = GetPlayerId(p) + 1 ---@type integer 
    local id     = GetIssuedOrderId() ---@type integer 
    local itm    = Item[GetOrderTargetItem()]
    local x      = GetOrderPointX()
    local y      = GetOrderPointY()
    local target = GetOrderTargetUnit() ---@type unit 
    local targetX = target and GetUnitX(target)
    local targetY = target and GetUnitY(target)

    --lookup table
    if OrderTable[id] then
        OrderTable[id](id, source, p, pid, target)
    end

    --backpack ai
    if source == Backpack[pid] and id ~= ORDER_ID_MOVE and id ~= ORDER_ID_STOP and id ~= ORDER_ID_HOLD_POSITION then
        bpmoving[pid] = true
        local pt = TimerList[pid]:get('bkpk')

        if not pt then
            pt = TimerList[pid]:add()
            pt.dur = 4.
            pt.tag = 'bkpk'

            pt.timer:callDelayed(1., MoveExpire, pt)
        else
            pt.dur = 4.
        end
    end

    --unit limits
    if id == FourCC('h01P') or id == FourCC('h03Y') or id == FourCC('h04B') or id == FourCC('n09E') or id == FourCC('n00Q') or id == FourCC('n023') or id == FourCC('n09F') or id == FourCC('h010') or id == FourCC('h04U') or id == FourCC('h053') then --worker
        if workerCount[pid] < 5 or (workerCount[pid] < 15 and id == FourCC('h053')) or (workerCount[pid] < 30 and id == FourCC('n00Q')) then
            workerCount[pid] = workerCount[pid] + 1
        else
            SetPlayerTechResearched(p, FourCC('R013'), 0)
        end
    elseif id == FourCC('e00J') or id == FourCC('e000') or id == FourCC('e00H') or id == FourCC('e00K') or id == FourCC('e006') or id == FourCC('e00I') or id == FourCC('e00T') or id == FourCC('e00Y') then --small lumber
        if smallwispCount[pid] < 1 or (smallwispCount[pid] < 6 and id ~= FourCC('e00I') and id ~= FourCC('e00T') and id ~= FourCC('e00Y')) or (smallwispCount[pid] < 12 and id ~= FourCC('e006') and id ~= FourCC('e00I') and id ~= FourCC('e00T') and id ~= FourCC('e00Y')) then
            smallwispCount[pid] = smallwispCount[pid] + 1
        else
            SetPlayerTechResearched(p, FourCC('R014'), 0)
        end
    elseif id == FourCC('e00Z') or id == FourCC('e00R') or id == FourCC('e00Q') or id == FourCC('e01L') or id == FourCC('e01E') or id == FourCC('e010') then --large lumber
        if largewispCount[pid] < 1 or (largewispCount[pid] < 2 and id ~= FourCC('e010')) or (largewispCount[pid] < 3 and id ~= FourCC('e00R') and id ~= FourCC('e010')) or (largewispCount[pid] < 6 and id ~= FourCC('e00R') and id ~= FourCC('e01E') and id ~= FourCC('e010')) then
            largewispCount[pid] = largewispCount[pid] + 1
        else
            SetPlayerTechResearched(p, FourCC('R015'), 0)
        end
    elseif id == FourCC('h00S') or id == FourCC('h017') or id == FourCC('h00I') or id == FourCC('h016') or id == FourCC('nwlg') or id == FourCC('h004') or id == FourCC('h04V') or id == FourCC('o02P') then --warrior
        if warriorCount[pid] < 6 or (warriorCount[pid] < 12 and id ~= FourCC('nwlg') and id ~= FourCC('h04V')) then
            warriorCount[pid] = warriorCount[pid] + 1
            ExperienceControl(pid)
        else
            SetPlayerTechResearched(p, FourCC('R016'), 0)
        end
    elseif id == FourCC('n00A') or id == FourCC('n014') or id == FourCC('n009') or id == FourCC('n00D') or id == FourCC('n002') or id == FourCC('h005') or id == FourCC('o02Q') then --ranger
        if rangerCount[pid] < 6 or (rangerCount[pid] < 12 and id ~= FourCC('n002')) then
            rangerCount[pid] = rangerCount[pid] + 1
            ExperienceControl(pid)
        else
            SetPlayerTechResearched(p, FourCC('R017'), 0)
        end
    end

    --cache issued point / target
    if Unit[source] then
        if target or (x ~= 0 and y ~= 0) then
            Unit[source].orderX = targetX or x
            Unit[source].orderY = targetY or y

            if Unit[source].movespeed > MOVESPEED.MAX then
                BlzSetUnitFacingEx(source, bj_RADTODEG * Atan2(Unit[source].orderY - GetUnitY(source), Unit[source].orderX - GetUnitX(source)))
            end
        end

        if IsUnitEnemy(target, Player(pid - 1)) then
            Unit[source].target = target
        end
    end

    --item target
    if itm then
        local oldSlot = GetItemSlot(itm, source) ---@type integer 

        -- prevent other units from attacking a bound item
        if id == ORDER_ID_ATTACK and itm.owner ~= Player(pid - 1) then
            TimerQueue:callDelayed(0., IssueImmediateOrderById, source, ORDER_ID_HOLD_POSITION)
        end

        --move item slot
        if id >= 852002 and id <= 852007 and oldSlot >= 0 then
            local swappedItem = UnitItemInSlot(source, id - 852002)

            if GetLocalPlayer() == Player(pid - 1) then
                if swappedItem then
                    BlzFrameSetTexture(INVENTORYBACKDROP[oldSlot], SPRITE_RARITY[Item[swappedItem].level], 0, true)
                end
                BlzFrameSetTexture(INVENTORYBACKDROP[id - 852002], SPRITE_RARITY[itm.level], 0, true)
            end

            if id - 852002 ~= oldSlot then --order slot not equal to old slot
                local offset = 0

                if GetUnitTypeId(source) == BACKPACK then
                    oldSlot = oldSlot + 6
                    offset = offset + 6
                end

                Profile[pid].hero.items[id - 852002 + offset] = itm --move slot = current item

                if Item[UnitItemInSlot(source, id - 852002)] then
                    Profile[pid].hero.items[oldSlot] = Item[UnitItemInSlot(source, id - 852002)] --item that was swapped = previous item slot
                else
                    Profile[pid].hero.items[oldSlot] = nil
                end
            end
        end
    end

    --debug
    if DEV_ENABLED then
        if EXTRA_DEBUG then
            if DEBUG_HERO and source == Hero[pid] then
                print(GetUnitName(source) .. " " .. OrderId2String(id) .. " " .. id)
            elseif not DEBUG_HERO then
                print(GetUnitName(source) .. " " .. OrderId2String(id) .. " " .. id)
            end
        end

        --[[local x2, y2 = GetUnitX(source), GetUnitY(source)

        if source == Hero[pid] then
            if (id == ORDER_ID_SMART or id == ORDER_ID_ATTACK) and CoordinateQueue[pid] then
                CoordinateQueue[pid]:clear()
                TurnQueue[pid] = {}
            end

            if A_STAR_PATHING and (id == ORDER_ID_SMART or id == ORDER_ID_ATTACK) and x ~= 0 and y ~= 0 then
                QueuePathing(source, x2, y2, x, y)
            end
        end]]

        if nocd[pid] then
            TimerQueue:callDelayed(0.1, ResetCD, pid)
        end

        if nocost[pid] and HeroID[pid] ~= HERO_VAMPIRE then
            SetUnitState(Hero[pid], UNIT_STATE_MANA, GetUnitState(Hero[pid], UNIT_STATE_MAX_MANA))
        end
    end
end

    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, OnOrder)
    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, OnOrder)
    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, OnOrder)
end, Debug.getLine())
