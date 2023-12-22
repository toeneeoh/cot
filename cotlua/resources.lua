if Debug then Debug.beginFile 'Resources' end

OnInit.final("Resources", function(require)
    require 'Users'

    ---@return boolean
    function ResourceConverter()
        local p        = GetTriggerPlayer() ---@type player 
        local pid         = GetPlayerId(p) + 1 ---@type integer 

        Currency[pid * CURRENCY_COUNT + GOLD] = GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD)
        Currency[pid * CURRENCY_COUNT + LUMBER] = GetPlayerState(p, PLAYER_STATE_RESOURCE_LUMBER)

        if PlatConverter[pid] and GetCurrency(pid, GOLD) > 1000000 then
            AddCurrency(pid, PLATINUM, 1)
            AddCurrency(pid, GOLD, -1000000)
            DisplayTimedTextToPlayer(p,0,0, 20, ("|cffe3e2e2Platinum Coins: " .. (GetCurrency(pid, PLATINUM))))
            Plat_Effect(p)
        end

        if ArcaConverter[pid] and GetCurrency(pid, LUMBER) > 1000000 then
            AddCurrency(pid, ARCADITE, 1)
            AddCurrency(pid, LUMBER, -1000000)
            DisplayTimedTextToPlayer(p,0,0, 20, (ArcTag + (GetCurrency(pid, ARCADITE))))
            Plat_Effect(p)
        end

        return false
    end

        local convert         = CreateTrigger() ---@type trigger 
        local u      = User.first ---@type User 

        while u do
            TriggerRegisterPlayerStateEvent(convert, u.player, PLAYER_STATE_RESOURCE_GOLD, GREATER_THAN_OR_EQUAL, 0.)
            TriggerRegisterPlayerStateEvent(convert, u.player, PLAYER_STATE_RESOURCE_LUMBER, GREATER_THAN_OR_EQUAL, 0.)
            u = u.next
        end

        TriggerAddCondition(convert, Filter(ResourceConverter))

end)

if Debug then Debug.endFile() end
