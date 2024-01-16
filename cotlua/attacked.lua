if Debug then Debug.beginFile 'Attacked' end

OnInit.final("Attacked", function(require)
    require 'Users'
    require 'Variables'

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

        --turn off moving flag
        if source == Hero[pid] and Moving[pid] then
            Moving[pid] = false
        end

        --prevent team killing
        if (pid <= PLAYER_CAP and tpid <= PLAYER_CAP and pid ~= tpid and IsUnitAlly(source, GetOwningPlayer(target))) then
            IssueImmediateOrder(source, "stop")
        end

        --assassin blade spin
        if uid == HERO_ASSASSIN then
            if BladeSpinCount[pid] >= BLADESPIN.times(pid) - 1 then
                BladeSpinCount[pid] = 0

                BLADESPIN.spin(source, false)
            end
        end

        --savior holy bash
        if uid == HERO_SAVIOR and GetUnitAbilityLevel(source, HOLYBASH.id) > 0 and saviorBashCount[pid] == 9 then
            local pt = TimerList[pid]:get(LIGHTSEAL.id, source)
            local sfx

            if pt then
                sfx = AddSpecialEffect("war3mapImported\\Judgement NoHive.mdx", pt.x, pt.y)
                BlzSetSpecialEffectScale(sfx, 1.8)
            else
                sfx = AddSpecialEffect("war3mapImported\\Judgement NoHive.mdx", targetX, targetY)
                BlzSetSpecialEffectScale(sfx, 0.8)
            end

            saviorBashCount[pid] = 10
            BlzSetSpecialEffectTimeScale(sfx, 1.5)
            BlzSetSpecialEffectTime(sfx, 0.7)
            TimerQueue:callDelayed(1.5, DestroyEffect, sfx)
        end

        --dark summoner destroyer
        if uid == SUMMON_DESTROYER then
            local pt = TimerList[pid]:get('datk', nil, target)

            if pt then
                TimerList[pid]:stopAllTimers('datk')
                pt = TimerList[pid]:add()
                pt.x = x
                pt.y = y
                pt.target = target
                pt.tag = FourCC('datk')

                SetHeroAgi(source, 0, true)
                if destroyerDevourStacks[pid] == 5 then
                    SetHeroAgi(source, 400, true)
                elseif destroyerDevourStacks[pid] >= 3 then
                    SetHeroAgi(source, 200, true)
                end

                pt.timer:callDelayed(1., SUMMONDESTROYER.periodic, pt)
            end
        end

        return false
    end

    local attacked = CreateTrigger() ---@type trigger 
    local U = User.first ---@type User 

    while U do
        TriggerRegisterPlayerUnitEvent(attacked, U.player, EVENT_PLAYER_UNIT_ATTACKED, nil)
        U = U.next
    end

    TriggerRegisterPlayerUnitEvent(attacked, Player(PLAYER_TOWN), EVENT_PLAYER_UNIT_ATTACKED, nil)
    TriggerRegisterPlayerUnitEvent(attacked, pboss, EVENT_PLAYER_UNIT_ATTACKED, nil)
    TriggerRegisterPlayerUnitEvent(attacked, pfoe, EVENT_PLAYER_UNIT_ATTACKED, nil)

    TriggerAddCondition(attacked, Condition(OnAttack))
end)

if Debug then Debug.endFile() end
