--[[
    attacked.lua

    This library handles instances of EVENT_PLAYER_UNIT_ATTACKED,
    where a unit is about to begin attacking a target.
]]

OnInit.final("Attacked", function(Require)
    Require('Variables')
    Require('UnitEvent')

    ---@return boolean
    function OnAttack()
        local source  = GetAttacker() ---@type unit 
        local target  = GetTriggerUnit() ---@type unit 
        local uid     = GetUnitTypeId(source) ---@type integer 
        local pid     = GetPlayerId(GetOwningPlayer(source)) + 1 ---@type integer 
        local tpid    = GetPlayerId(GetOwningPlayer(target)) + 1 ---@type integer 
        local x       = GetUnitX(source) ---@type number 
        local y       = GetUnitY(source) ---@type number 
        local targetX = GetUnitX(target) ---@type number 
        local targetY = GetUnitY(target) ---@type number 

        -- prevent team killing
        if (pid <= PLAYER_CAP and tpid <= PLAYER_CAP and pid ~= tpid and IsUnitAlly(source, GetOwningPlayer(target))) then
            IssueImmediateOrder(source, "stop")
        end

        -- assassin blade spin
        if uid == HERO_ASSASSIN then
            if BLADESPIN.count[pid] >= BLADESPIN.times(pid) - 1 then
                BLADESPIN.count[pid] = 0

                BLADESPIN.spin(source, false)
            end
        end

        -- savior holy bash
        if uid == HERO_SAVIOR and GetUnitAbilityLevel(source, HOLYBASH.id) > 0 and HOLYBASH.count[pid] == 9 then
            local pt = TimerList[pid]:get(LIGHTSEAL.id, source)
            local sfx

            if pt then
                sfx = AddSpecialEffect("war3mapImported\\Judgement NoHive.mdx", pt.x, pt.y)
                BlzSetSpecialEffectScale(sfx, 1.8)
            else
                sfx = AddSpecialEffect("war3mapImported\\Judgement NoHive.mdx", targetX, targetY)
                BlzSetSpecialEffectScale(sfx, 0.8)
            end

            HOLYBASH.count[pid] = 10
            BlzSetSpecialEffectTimeScale(sfx, 1.5)
            BlzSetSpecialEffectTime(sfx, 0.7)
            TimerQueue:callDelayed(1.5, DestroyEffect, sfx)
        end

        -- dark summoner destroyer
        if uid == SUMMON_DESTROYER then
            local pt = TimerList[pid]:get('datk')

            if not pt or pt.target ~= target then
                TimerList[pid]:stopAllTimers('datk')
                pt = TimerList[pid]:add()
                pt.x = x
                pt.y = y
                pt.target = target
                pt.tag = 'datk'

                SetHeroAgi(source, 0, true)
                if Unit[source].devour_stacks == 5 then
                    SetHeroAgi(source, 400, true)
                elseif Unit[source].devour_stacks >= 3 then
                    SetHeroAgi(source, 200, true)
                end

                pt.timer:callDelayed(1., SUMMONDESTROYER.periodic, pt)
            end
        end

        return false
    end

    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ATTACKED, OnAttack)
end, Debug and Debug.getLine())
