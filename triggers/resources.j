library Converter requires Functions

    function ResourceConverter takes nothing returns boolean
        local player p = GetTriggerPlayer()
        local integer pid = GetPlayerId(p) + 1

        set Currency[pid * CURRENCY_COUNT + GOLD] = GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD)
        set Currency[pid * CURRENCY_COUNT + LUMBER] = GetPlayerState(p, PLAYER_STATE_RESOURCE_LUMBER)

        if udg_PlatConverter[pid] and GetCurrency(pid, GOLD) > 1000000 then
            call AddCurrency(pid, PLATINUM, 1)
            call AddCurrency(pid, GOLD, -1000000)
            call DisplayTimedTextToPlayer(p,0,0, 20, ("|cffe3e2e2Platinum Coins: " + I2S(GetCurrency(pid, PLATINUM))))
            call Plat_Effect(p)
        endif

        if udg_ArcaConverter[pid] and GetCurrency(pid, LUMBER) > 1000000 then
            call AddCurrency(pid, ARCADITE, 1)
            call AddCurrency(pid, LUMBER, -1000000)
            call DisplayTimedTextToPlayer(p,0,0, 20, (ArcTag + I2S(GetCurrency(pid, ARCADITE))))
            call Plat_Effect(p)
        endif

        set p = null

        return false
    endfunction
    
    //===========================================================================
    function ConverterInit takes nothing returns nothing
        local trigger convert = CreateTrigger()
        local User u = User.first
    
        loop
            exitwhen u == User.NULL
            call TriggerRegisterPlayerStateEvent(convert, u.toPlayer(), PLAYER_STATE_RESOURCE_GOLD, GREATER_THAN_OR_EQUAL, 0.)
            call TriggerRegisterPlayerStateEvent(convert, u.toPlayer(), PLAYER_STATE_RESOURCE_LUMBER, GREATER_THAN_OR_EQUAL, 0.)
            set u = u.next
        endloop
        
        call TriggerAddCondition(convert, Filter(function ResourceConverter))

        set convert = null
    endfunction
    
endlibrary
    