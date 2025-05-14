--[[
    currency.lua

    This library provides general purpose money related functions for use elsewhere.
]]

OnInit.final("Currency", function(Require)
    local CURRENCY = __jarray(0) ---@type integer[] 
    GOLD           = 0
    PLATINUM       = 1
    CRYSTAL        = 2
    HONOR          = 3
    FACTION        = 4
    CURRENCY_COUNT = 5

    --currencies
    CURRENCY_ICON = {
        "gold.dds",
        "plat.dds",
        "crystal.dds",
        "ShopHonorPoints.dds",
        "ShopFactionPoints.dds",
    }

    Require('Users')
    Require('Frames')
    Require('Items')

    IS_CONVERTING_PLAT = {} ---@type boolean[]
    IS_CONVERTER_PURCHASED = {} ---@type boolean[]

    -- purchase auto converter
    local function BuyConverter()
        local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local dw    = DialogWindow[pid]
        local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

        -- converter
        if index == 0 then
            if GetCurrency(pid, PLATINUM) >= 4 then
                IS_CONVERTER_PURCHASED[pid] = true
                AddCurrency(pid, PLATINUM, -4)
                if GetLocalPlayer() == GetTriggerPlayer() then
                    PLAT_CONVERT_FRAME.tooltip:text("Convert gold to platinum automatically")
                end
            else
                DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 10, "You cannot afford this!")
            end

            dw:destroy()
        end

        return false
    end

    -- map item currency exchange purchases to functions
    ITEM_LOOKUP[FourCC('I084')] = function(p, pid)
        if not IS_CONVERTER_PURCHASED[pid] then
            local dw = DialogWindow.create(pid, "Purchase cost: |n|cffffffff4 |cffe3e2e2Platinum|r", BuyConverter)

            dw:addButton("Purchase")

            dw:display()
        end
    end

    -- crystal to gold & platinum
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
        AddCurrency(pid, CRYSTAL, 1)
        DisplayTimedTextToPlayer(p, 0, 0, 20, CrystalTag .. (GetCurrency(pid, CRYSTAL)))
    end

    ITEM_LOOKUP[FourCC('I04G')] = function(p, pid)
        AddCurrency(pid, PLATINUM, 1)
        ConversionEffect(pid)
        DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag .. (GetCurrency(pid, PLATINUM)))
    end

    ITEM_LOOKUP[FourCC('I052')] = function(p, pid)
        ConversionEffect(pid)
        AddCurrency(pid, GOLD, 1000000)
        DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag .. (GetCurrency(pid, PLATINUM)))
    end

    local setter = {
        [GOLD] = function(pid, amount) SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_GOLD, amount) end,
        [PLATINUM] = function(pid, amount) SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_LUMBER, amount) end,
        [CRYSTAL] = function(pid, amount) SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_FOOD_USED, amount) end,
        [HONOR] = function (pid, amount)
            if GetLocalPlayer() == Player(pid - 1) then
                BlzFrameSetText(HONOR_TEXT, amount)
            end
        end,
        [FACTION] = function(pid, amount)
            if GetLocalPlayer() == Player(pid - 1) then
                BlzFrameSetText(FACTION_TEXT, amount)
            end
        end,
    }

    ---@type fun(pid: integer, index: integer, amount: integer)
    function SetCurrency(pid, index, amount)
        amount = math.max(0, amount)
        CURRENCY[pid * CURRENCY_COUNT + index] = amount
        setter[index](pid, amount)
    end

    ---@type fun(pid: integer, index: integer):integer
    function GetCurrency(pid, index)
        return CURRENCY[pid * CURRENCY_COUNT + index]
    end

    ---@type fun(pid: integer, index: integer, amount: integer)
    function AddCurrency(pid, index, amount)
        SetCurrency(pid, index, GetCurrency(pid, index) + amount)
        Shop.refresh(pid)
    end

    ---@type fun(pid: integer, goldawarded: number, displaymessage: boolean)
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
            FloatingTextUnit(s, Hero[pid], 1.5, 75, -100, 9., 255, 255, 0, 0, false)
        end
    end

    ---@type fun(pid: integer, price: number, successMsg: string): boolean
    function ChargePlayer(pid, price, successMsg)
        local g = GetCurrency(pid, GOLD)
        local p = GetCurrency(pid, PLATINUM)
        local total = g + p * 1000000

        if total < price then
            DisplayTextToPlayer(Player(pid-1), 0., 0., "You do not have enough funds!")
            return false
        end

        local newTotal = total - price
        local newP = newTotal // 1000000
        local newG = math.fmod(newTotal, 1000000)

        AddCurrency(pid, PLATINUM, newP - p)
        AddCurrency(pid, GOLD,     newG - g)

        DisplayTextToPlayer(Player(pid - 1), 0., 0., successMsg)
        return true
    end

    ---@type fun(p: player, flat: integer, percent: number, minimum: integer, message: string)
    function ChargeNetworth(p, flat, percent, minimum, message)
        local pid          = GetPlayerId(p) + 1
        local playerGold   = GetCurrency(pid, GOLD)
        local platCost     = R2I(GetCurrency(pid, PLATINUM) * percent)

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

        if message ~= "" then
            DisplayTextToPlayer(p, 0, 0, message)
        end
    end

    ---@return boolean
    local function CurrencyConverter()
        local p   = GetTriggerPlayer()
        local pid = GetPlayerId(p) + 1 ---@type integer 

        Shop.refresh(pid)
        CURRENCY[pid * CURRENCY_COUNT + GOLD] = GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD)

        if IS_CONVERTING_PLAT[pid] then
            -- prevent stack overflow
            IS_CONVERTING_PLAT[pid] = false
            local plat = CURRENCY[pid * CURRENCY_COUNT + GOLD] // 1000000

            if plat > 0 then
                AddCurrency(pid, PLATINUM, plat)
                AddCurrency(pid, GOLD, -1000000 * plat)
                ConversionEffect(pid)
            end
            IS_CONVERTING_PLAT[pid] = true
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

end, Debug and Debug.getLine())
