--[[
    threat.lua

    This library handles now hostile units acquire and switch targets according to a threat level
    system.
]]

OnInit.final("Threat", function()

    ACQUIRE_TRIGGER = CreateTrigger()
    Threat = array2d(0)

    ---@return boolean
    function OnAcquire()
        local target = GetEventTargetUnit() ---@type unit 
        local attacker = GetTriggerUnit() ---@type unit 
        local pid = GetPlayerId(GetOwningPlayer(attacker)) + 1

        if IsDummy(attacker) then
            BlzSetUnitWeaponBooleanField(attacker, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
        elseif GetPlayerController(Player(pid - 1)) ~= MAP_CONTROL_USER then
            Unit[attacker].target = AcquireProximity(attacker, target, 800.)
            TimerQueue:callDelayed(FPS_32, SwitchAggro, attacker, target)
        elseif Unit[attacker] then
            Unit[attacker].target = target
            
            if Unit[attacker].movespeed > MOVESPEED.MAX then
                BlzSetUnitFacingEx(attacker, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(attacker), GetUnitX(target) - GetUnitX(attacker)))
            end
        end

        return false
    end

    TriggerAddCondition(ACQUIRE_TRIGGER, Filter(OnAcquire))

end, Debug.getLine())
