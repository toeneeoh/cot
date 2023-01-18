library Converter requires Functions

    function Trig_Portable_converters_Actions takes nothing returns nothing
    local player p=GetTriggerPlayer()
    local integer pid=GetPlayerId(p)+1
        if udg_PlatConverter[pid] and GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD)>1000000 then
            call AddPlatinumCoin(pid, 1)
            call SetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD)-1000000 )
            call DisplayTimedTextToPlayer(p,0,0, 20, ( "|cffe3e2e2Platinum Coins: " + I2S(udg_Plat_Gold[pid]) ) )
            call Plat_Effect(p)
        endif
        if udg_ArcaConverter[pid] and GetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER)>1000000 then
            call AddArcaditeLumber(pid, 1)
            call SetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER)-1000000 )
            call DisplayTimedTextToPlayer(p,0,0, 20, ( ArcTag + I2S(udg_Arca_Wood[pid]) ) )
            call Plat_Effect(p)
        endif
    set p=null
    endfunction
    
    //===========================================================================
    function ConverterInit takes nothing returns nothing
        local trigger convert = CreateTrigger()
        local User u = User.first
    
        loop
            exitwhen u == User.NULL
            call TriggerRegisterPlayerStateEvent( convert, u.toPlayer(), PLAYER_STATE_RESOURCE_GOLD, GREATER_THAN, 2000000. )
            call TriggerRegisterPlayerStateEvent( convert, u.toPlayer(), PLAYER_STATE_RESOURCE_LUMBER, GREATER_THAN, 2000000.)
            set u = u.next
        endloop
        
        call TriggerAddAction( convert, function Trig_Portable_converters_Actions )

        set convert = null
    endfunction
    
endlibrary
    