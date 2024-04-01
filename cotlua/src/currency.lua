if Debug then Debug.beginFile 'Currency' end

--[[
    currency.lua

    This library provides general purpose money related functions for use elsewhere.
]]

OnInit.final("Currency", function(require)
    require 'Users'
    require 'UI'

    PlatConverter = {} ---@type boolean[]
    ArcaConverter = {} ---@type boolean[]
    ConverterBought = {} ---@type boolean[]

    --ORIGIN_FRAME_UBERTOOLTIP

    BlzFrameSetVisible(CONVERTER_FRAME, false)

    --map item currency exchange purchases to functions

    --purchase auto converter
    local function BuyConverter()
        local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local dw    = DialogWindow[pid]
        local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

        --converter
        if index == 0 then
            if GetCurrency(pid, PLATINUM) >= 2 and GetCurrency(pid, ARCADITE) >= 2 then
                ConverterBought[pid] = true
                AddCurrency(pid, PLATINUM, -2)
                AddCurrency(pid, ARCADITE, -2)
                if GetLocalPlayer() == GetTriggerPlayer() then
                    BlzFrameSetVisible(CONVERTER_FRAME, true)
                end
            else
                DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 10, "You cannot afford this!")
            end

            dw:destroy()
        end

        return false
    end

    ITEM_LOOKUP[FourCC('I084')] = function(p, pid)
        if not ConverterBought[pid] then
            local dw = DialogWindow.create(pid, "Purchase cost: |n|cffffffff2 |cffe3e2e2Platinum|r|nand |cffffffff2 |cff66FF66Arcadite|r", BuyConverter)

            dw:addButton("Purchase")

            dw:display()
        end
    end

    --crystal to gold & platinum
    ITEM_LOOKUP[FourCC('I0ME')] = function(p, pid)
        if GetCurrency(pid, CRYSTAL) >= 1 then
            AddCurrency(pid, CRYSTAL, -1)
            AddCurrency(pid, GOLD, 500000)
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need at least 1 crystal to buy this.")
        end
    end

    --platinum to crystal
    ITEM_LOOKUP[FourCC('I0MF')] = function(p, pid)
        if GetCurrency(pid, PLATINUM) >= 3 then
            AddCurrency(pid, PLATINUM, -3)
            AddCurrency(pid, CRYSTAL, 1)
            DisplayTimedTextToPlayer(p, 0, 0, 20, CrystalTag + (GetCurrency(pid, CRYSTAL)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need at least 3 platinum to buy this.")
        end
    end

    ITEM_LOOKUP[FourCC('I04G')] = function(p, pid)
        if GetCurrency(pid, GOLD) >= 1000000 then
            AddCurrency(pid, PLATINUM, 1)
            AddCurrency(pid, GOLD, -1000000)
            ConversionEffect(pid)
            DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag .. (GetCurrency(pid, PLATINUM)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 30, "|cffee0000You do not have a million gold to convert.")
        end
    end

    ITEM_LOOKUP[FourCC('I04H')] = function(p, pid)
        if GetCurrency(pid, LUMBER) >= 1000000 then
            AddCurrency(pid, ARCADITE, 1)
            AddCurrency(pid, LUMBER, -1000000)
            ConversionEffect(pid)
            DisplayTimedTextToPlayer(p, 0, 0, 20, ArcTag .. (GetCurrency(pid, ARCADITE)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 30, "|cffee0000You do not have a million lumber to convert.")
        end
    end

    ITEM_LOOKUP[FourCC('I054')] = function(p, pid)
        if GetCurrency(pid, ARCADITE) >0 then
            ConversionEffect(pid)
            AddCurrency(pid, PLATINUM, 1)
            AddCurrency(pid, ARCADITE, -1)
            AddCurrency(pid, GOLD, 200000)
            DisplayTimedTextToPlayer(p, 0, 0, 20, ArcTag .. (GetCurrency(pid, ARCADITE)))
            DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag .. (GetCurrency(pid, PLATINUM)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff990000Unable to convert; not enough Arcadite Lumber.")
        end
    end

    ITEM_LOOKUP[FourCC('I053')] = function(p, pid)
        if GetCurrency(pid, PLATINUM) > 0 then
            ConversionEffect(pid)
            AddCurrency(pid, PLATINUM, -1)
            AddCurrency(pid, ARCADITE, 1)
            DisplayTimedTextToPlayer(p, 0, 0, 20, ArcTag .. (GetCurrency(pid, ARCADITE)))
            DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag .. (GetCurrency(pid, PLATINUM)))
        else
            AddCurrency(pid, GOLD, 350000)
            DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff990000Unable to convert; not enough Platinum Coins.")
        end
    end

    ITEM_LOOKUP[FourCC('I0PA')] = function(p, pid)
        if GetCurrency(pid, PLATINUM) >= 4 then
            ConversionEffect(pid)
            AddCurrency(pid, PLATINUM, -4)
            AddCurrency(pid, ARCADITE, 3)
            DisplayTimedTextToPlayer(p, 0, 0, 20, ArcTag .. (GetCurrency(pid, ARCADITE)))
            DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag .. (GetCurrency(pid, PLATINUM)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff990000Unable to convert; not enough Platinum Coins.")
        end
    end

    ITEM_LOOKUP[FourCC('I051')] = function(p, pid)
        if GetCurrency(pid, ARCADITE) > 0 then
            ConversionEffect(pid)
            AddCurrency(pid, ARCADITE, -1)
            AddCurrency(pid, LUMBER, 1000000)
            DisplayTimedTextToPlayer(p, 0, 0, 20, ArcTag .. (GetCurrency(pid, ARCADITE)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff990000Unable to convert; not enough Arcadite Lumber.")
        end
    end

    ITEM_LOOKUP[FourCC('I052')] = function(p, pid)
        if GetCurrency(pid, PLATINUM) >0 then
            ConversionEffect(pid)
            AddCurrency(pid, PLATINUM, -1)
            AddCurrency(pid, GOLD, 1000000)
            DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag .. (GetCurrency(pid, PLATINUM)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff990000Unable to convert; not enough Platinum Coins.")
        end
    end

    ITEM_LOOKUP[FourCC('I03R')] = function(p, pid)
        if GetCurrency(pid, LUMBER) >= 25000 then
            AddCurrency(pid, GOLD, 25000)
            AddCurrency(pid, LUMBER, -25000)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", u, "origin"))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need at least 25,000 lumber to buy this.")
        end
    end

    ITEM_LOOKUP[FourCC('I05C')] = function(p, pid)
        if GetCurrency(pid, GOLD) >= 32000 then
            AddCurrency(pid, LUMBER, 25000)
            AddCurrency(pid, GOLD, -32000)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", u, "origin"))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need at least 32,000 gold to buy this.")
        end
    end

    ---@type fun(pid: integer, index: integer, amount: integer)
    function SetCurrency(pid, index, amount)
        Currency[pid * CURRENCY_COUNT + index] = IMaxBJ(0, amount)

        if index == GOLD then
            SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_GOLD, Currency[pid * CURRENCY_COUNT + index])
        elseif index == LUMBER then
            SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_LUMBER, Currency[pid * CURRENCY_COUNT + index])
        elseif index == PLATINUM then
            if GetLocalPlayer() == Player(pid - 1) then
                BlzFrameSetText(PLAT_TEXT, tostring(Currency[pid * CURRENCY_COUNT + index]))
            end
        elseif index == ARCADITE then
            if GetLocalPlayer() == Player(pid - 1) then
                BlzFrameSetText(ARC_TEXT, tostring(Currency[pid * CURRENCY_COUNT + index]))
            end
        elseif index == CRYSTAL then
            SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_FOOD_USED, Currency[pid * CURRENCY_COUNT + index])
        end
    end

    ---@type fun(pid: integer, index: integer):integer
    function GetCurrency(pid, index)
        return Currency[pid * CURRENCY_COUNT + index]
    end

    ---@type fun(pid: integer, index: integer, amount: integer)
    function AddCurrency(pid, index, amount)
        SetCurrency(pid, index, GetCurrency(pid, index) + amount)
    end

    ---@type fun(pid: integer, goldawarded:number, displaymessage: boolean)
    function AwardGold(pid, goldawarded, displaymessage)
        local p = Player(pid - 1)
        local goldWon ---@type integer 
        local platWon ---@type integer 

        goldWon = math.floor(goldawarded * GetRandomReal(0.9,1.1))
        goldWon = math.floor(goldWon * (1 + (ItemGoldRate[pid] * 0.01)))

        platWon = goldWon // 1000000
        goldWon = goldWon - platWon * 1000000

        AddCurrency(pid, PLATINUM, platWon)
        AddCurrency(pid, GOLD, goldWon)

        if displaymessage then
            if platWon > 0 then
                DisplayTimedTextToPlayer(p, 0, 0, 10, "|c00ebeb15You have gained " .. (goldWon) .. " gold and " .. (platWon) .. " platinum coins.|r")
                DisplayTimedTextToPlayer(p, 0, 0, 10, PlatTag .. (GetCurrency(pid, PLATINUM)))
            else
                DisplayTimedTextToPlayer(p, 0, 0, 10, "|c00ebeb15You have gained " .. (goldWon) .. " gold.|r")
            end
        end

        local s = "+" .. goldWon

        if goldWon >= 100000 then
            s = "+" .. (goldWon // 1000) .. "K"
        end

        if platWon > 0 then
            s = "|cffcccccc+" .. platWon .. "|r |cffffcc00" .. s .. "|r"
            FloatingTextUnit(s, Hero[pid], 1.5, 75, -100, 9., 255, 255, 255, 0, false)
        else
            FloatingTextUnit(s, Hero[pid], 1.5, 75, -100, 8.5, 255, 255, 0, 0, false)
        end
    end

    ---@type fun(id: integer, x: number, y: number)
    function AwardCrystals(id, x, y)
        local count = BossTable[id].crystal ---@type integer 

        if count == 0 then
            return
        end

        if HARD_MODE > 0 then
            count = count * 2
        end

        local u = User.first

        while u do
            if IsUnitInRangeXY(Hero[u.id], x, y, NEARBY_BOSS_RANGE) and GetHeroLevel(Hero[u.id]) >= BossTable[id].level then
                AddCurrency(u.id, CRYSTAL, count)
                FloatingTextUnit("+" .. (count) .. (count == 1 and " Crystal" or " Crystals"), Hero[u.id], 2.1, 80, 90, 9, 70, 150, 230, 0, false)
            end

            u = u.next
        end
    end

    ---@type fun(p: player, flat: integer, percent: number, minimum: integer, message: string)
    function ChargeNetworth(p, flat, percent, minimum, message)
        local pid          = GetPlayerId(p) + 1
        local playerGold   = GetCurrency(pid, GOLD)
        local playerLumber = GetCurrency(pid, LUMBER)
        local platCost     = R2I(GetCurrency(pid, PLATINUM) * percent)
        local arcCost      = R2I(GetCurrency(pid, ARCADITE) * percent)

        local cost = flat + R2I(playerGold * percent)
        if cost < minimum then
            cost = minimum
        end

        AddCurrency(pid, GOLD, -cost)
        AddCurrency(pid, PLATINUM, -platCost)

        if message ~= "" then
            if platCost > 0 then
                message = message .. " " .. RealToString(platCost) .. " platinum, " .. RealToString(cost) .. " gold"
            else
                message = message .. " " .. RealToString(cost) .. " gold"
            end
        end

        cost = flat + R2I(playerLumber * percent)
        if cost < minimum then
            cost = minimum
        end

        AddCurrency(pid, LUMBER, -cost)
        AddCurrency(pid, ARCADITE, -arcCost)

        if message ~= "" then
            if arcCost > 0 then
                message = message .. ", " .. RealToString(arcCost) .. " arcadite, and " .. RealToString(cost) .. " lumber."
            else
                message = message .. " and " .. RealToString(cost) .. " lumber."
            end
            DisplayTextToPlayer(p, 0, 0, message)
        end
    end

    ---@return boolean
    function CurrencyConverter()
        local p   = GetTriggerPlayer() ---@type player 
        local pid = GetPlayerId(p) + 1 ---@type integer 

        Currency[pid * CURRENCY_COUNT + GOLD] = GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD)
        Currency[pid * CURRENCY_COUNT + LUMBER] = GetPlayerState(p, PLAYER_STATE_RESOURCE_LUMBER)

        if PlatConverter[pid] then
            local plat = Currency[pid * CURRENCY_COUNT + GOLD] // 1000000

            if plat > 0 then
                AddCurrency(pid, PLATINUM, plat)
                AddCurrency(pid, GOLD, -1000000 * plat)
                ConversionEffect(pid)
            end
        end

        if ArcaConverter[pid] then
            local arc = Currency[pid * CURRENCY_COUNT + LUMBER] // 1000000

            if arc > 0 then
                AddCurrency(pid, ARCADITE, arc)
                AddCurrency(pid, LUMBER, -1000000 * arc)
                ConversionEffect(pid)
            end
        end

        return false
    end

    local convert = CreateTrigger()
    local u = User.first ---@type User 

    while u do
        TriggerRegisterPlayerStateEvent(convert, u.player, PLAYER_STATE_RESOURCE_GOLD, GREATER_THAN_OR_EQUAL, 0.)
        TriggerRegisterPlayerStateEvent(convert, u.player, PLAYER_STATE_RESOURCE_LUMBER, GREATER_THAN_OR_EQUAL, 0.)
        u = u.next
    end

    TriggerAddCondition(convert, Filter(CurrencyConverter))

end)

if Debug then Debug.endFile() end
