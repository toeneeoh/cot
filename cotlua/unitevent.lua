if Debug then Debug.beginFile 'UnitEvent' end

OnInit.global("UnitEvent", function()

--[[*************************************************************
*
*   RegisterPlayerUnitEvent
*   v5.1.0.1
*   By Magtheridon96
*
*   I would like to give a special thanks to Bribe, azlier
*   and BBQ for improving this library. For modularity, it only 
*   supports player unit events.
*
*   Functions passed to RegisterPlayerUnitEvent must either
*   return a boolean (false) or nothing. (Which is a Pro)
*
*   Warning:
*   --------
*
*       - Don't use TriggerSleepAction inside registered code.
*       - Don't destroy a trigger unless you really know what you're doing.
*
*   API:
*   ----
*
*       - function RegisterPlayerUnitEvent takes playerunitevent whichEvent, code whichFunction returns nothing
*           - Registers code that will execute when an event fires.
*       - function RegisterPlayerUnitEventForPlayer takes playerunitevent whichEvent, code whichFunction, player whichPlayer returns nothing
*           - Registers code that will execute when an event fires for a certain player.
*       - function GetPlayerUnitEventTrigger takes playerunitevent whichEvent returns trigger
*           - Returns the trigger corresponding to ALL functions of a playerunitevent.
*
*************************************************************]]
    local t={} ---@type trigger[] 

    ---@param p playerunitevent
    ---@param c function
    function RegisterPlayerUnitEvent(p, c)
        local i         = GetHandleId(p) ---@type integer 
        if t[i] == nil then
            t[i] = CreateTrigger()
            for k = 15, 0, -1 do
                TriggerRegisterPlayerUnitEvent(t[i], Player(k), p, nil)
            end
        end
        TriggerAddCondition(t[i], Filter(c))
    end

    ---@param p playerunitevent
    ---@param c function
    ---@param pl player
    function RegisterPlayerUnitEventForPlayer(p, c, pl)
        local i         = 16 * GetHandleId(p) + GetPlayerId(pl) ---@type integer 
        if t[i] == nil then
            t[i] = CreateTrigger()
            TriggerRegisterPlayerUnitEvent(t[i], pl, p, nil)
        end
        TriggerAddCondition(t[i], Filter(c))
    end

    ---@param p playerunitevent
    ---@return trigger
    function GetPlayerUnitEventTrigger(p)
        return t[GetHandleId(p)]
    end

end)

if Debug then Debug.endFile() end
