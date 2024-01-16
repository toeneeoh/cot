if Debug then Debug.beginFile 'Items' end

OnInit.final("Items", function(require)
    require 'Users'
    require 'Variables'

    Rates = __jarray(0)

    BuffMovespeed=__jarray(0) ---@type integer[] 
    ItemMovespeed=__jarray(0) ---@type integer[] 
    EvasionBonus=__jarray(0) ---@type integer[] 
    ItemEvasion=__jarray(0) ---@type integer[] 
    ItemMagicRes=__jarray(0) ---@type number[] 
    ItemDamageRes=__jarray(0) ---@type number[] 
    ItemSpellboost=__jarray(0) ---@type number[] 
    ItemGoldRate=__jarray(0) ---@type integer[] 
    donated=__jarray(false) ---@type boolean[] 
    slotitem={} ---@type button[] 
    rezretimer={} ---@type timer[] 
    TrainerSpawn         = 0 ---@type integer 
    TrainerSpawnChaos         = 0 ---@type integer 
    hordequest         = false ---@type boolean 
    ITEM_DROP_FLAG = __jarray(false) ---@type boolean[] 
    ItemsDisabled=__jarray(false) ---@type boolean[] 

    MAX_ITEM_COUNT = 100
    ADJUST_RATE = 0.05 --percent
    DISCOUNT_RATE = 0.25 ---@type number 

    ItemDrops = array2d(0)

    ---@class Item
    ---@field obj item
    ---@field holder unit
    ---@field trig trigger
    ---@field lvl function
    ---@field level integer
    ---@field id integer
    ---@field charge function
    ---@field charges integer
    ---@field x number
    ---@field y number
    ---@field quality integer[]
    ---@field eval conditionfunc
    ---@field useInRecipe function
    ---@field calcStat function
    ---@field equip function
    ---@field unequip function
    ---@field update function
    ---@field encode function
    ---@field encode_id function
    ---@field decode function
    ---@field decode_id function
    ---@field expire function
    ---@field onDeath function
    ---@field name string
    ---@field restricted boolean
    ---@field create function
    ---@field destroy function
    ---@field owner unit
    Item = {}
    do
        local thistype = Item
        thistype.eval = Condition(thistype.onDeath)

        -- Create a metatable for assignments
        setmetatable(Item, { __newindex = function(tbl, key, value)
            if key == "restricted" then
                tbl:restrict(value)
            end
            rawset(tbl, key, value)
        end})

        ---@type fun(itm: item, expire: number?):Item
        function thistype.create(itm, expire)
            local self = {
                obj = itm,
                id = GetItemTypeId(itm),
                level = 0,
                trig = CreateTrigger(),
                charges = GetItemCharges(itm),
                x = GetItemX(itm),
                y = GetItemY(itm),
                quality = __jarray(0)
            }

            setmetatable(self, { __index = Item })

            --first time setup
            if ItemData[self.id] == nil then
                ItemData[self.id] = __jarray(0)
                --use description for parse (for buyable items with stats)
                if StringLength(BlzGetItemDescription(self.obj)) > 1 then
                    ParseItemTooltip(self.obj, BlzGetItemDescription(self.obj))
                else
                    ParseItemTooltip(self.obj, "")
                end
            end

            --determine if saveable (misc category yields 7 instead of ITEM_TYPE_MISCELLANEOUS 's value of 6)
            if (GetHandleId(GetItemType(self.obj)) == 7 or GetItemType(self.obj) == ITEM_TYPE_PERMANENT) and self.id > CUSTOM_ITEM_OFFSET then
                SAVE_TABLE.KEY_ITEMS[self.id] = self.id - CUSTOM_ITEM_OFFSET
            end

            TriggerRegisterDeathEvent(self.trig, self.obj)
            TriggerAddCondition(self.trig, thistype.eval)

            if expire then
                TimerQueue:callDelayed(expire, thistype.expire, self)
            end

            --randomize rolls
            local count = 0
            for i = ITEM_HEALTH, ITEM_STAT_TOTAL do
                if ItemData[self.id][i + BOUNDS_OFFSET] ~= 0 then
                    self.quality[count] = GetRandomInt(0, 63)
                    count = count + 1
                end

                if count > 6 then break end
            end

            if ItemData[self.id][ITEM_TIER] ~= 0 then
                self:update()
            end

            Item[self.obj] = self

            return self
        end

        --Adjusts name in tooltip if an item is useable or not
        ---@type fun(flag: boolean)
        function thistype:restrict(flag)
            if flag then
                BlzSetItemName(self.obj, self:name() .. "\n|cffFFCC00You are too low level to use this item!|r")
            else
                BlzSetItemName(self.obj, self:name())
                --for backpack auras and useable abilities
                ItemAddSpellDelayed(self)
            end
        end

        --Generates a proper name string
        ---@type fun():string
        function thistype:name()
            local s = GetObjectName(self.id)

            if self.level > 0 then
                s = LEVEL_PREFIX[self.level] .. " " .. s .. " +" .. self.level
            end

            return s
        end

        function thistype:charge(num)
            self.charges = num
            SetItemCharges(self.obj, num)
        end

        function thistype:lvl(lvl)
            self:unequip()
            self.level = lvl
            self:update()
            self:equip()
        end

        function thistype:useInRecipe()
            if self.charges > 1 then
                self:charge(self.charges - 1)
            else
                self:destroy()
            end
        end

        ---@type fun(STAT: integer, flag: integer):integer
        function thistype:calcStat(STAT, flag)
            local flatPerLevel         = ItemData[self.id][STAT + BOUNDS_OFFSET * 2] ---@type integer 
            local flatPerRarity         = ItemData[self.id][STAT + BOUNDS_OFFSET * 3] ---@type integer 
            local percent      = ItemData[self.id][STAT + BOUNDS_OFFSET * 4] * 0.01 ---@type number 
            local unlockat         = ItemData[self.id][STAT + BOUNDS_OFFSET * 5] ---@type integer 
            local fixed         = ItemData[self.id][STAT + BOUNDS_OFFSET * 6] ---@type integer 
            local lower      = ItemData[self.id][STAT]  ---@type number 
            local upper      = ItemData[self.id][STAT + BOUNDS_OFFSET]  ---@type number 
            local hasVariance         = (upper ~= 0) ---@type boolean 
            local count         = 0 ---@type integer 
            local index         = 0 ---@type integer 
            local final         = 0 ---@type integer 

            if self.level < unlockat then
                return 0
            end

            if percent > 0 then
                lower = lower + ((flatPerLevel * self.level + flatPerRarity * (IMaxBJ(self.level - 1, 0) // 4)) * percent)
                upper = upper + ((flatPerLevel * self.level + flatPerRarity * (IMaxBJ(self.level - 1, 0) // 4)) * percent)
            else
                lower = lower + flatPerLevel * self.level + flatPerRarity * (IMaxBJ(self.level - 1, 0) // 4)
                upper = upper + flatPerLevel * self.level + flatPerRarity * (IMaxBJ(self.level - 1, 0) // 4)
            end

            if fixed == 0 then
                if percent > 0 then
                    lower = lower + lower * ITEM_MULT[self.level] * percent
                    upper = upper + upper * ITEM_MULT[self.level] * percent
                else
                    lower = lower + lower * ITEM_MULT[self.level]
                    upper = upper + upper * ITEM_MULT[self.level]
                end
            end

            if flag == 1 then
                return R2I(lower)
            elseif flag == 2 then
                return R2I(upper)
            else
                if hasVariance then
                    --find the quality index
                    while index ~= STAT do

                        if ItemData[self.id][index + BOUNDS_OFFSET] ~= 0 then
                            count = count + 1
                        end

                        index = index + 1
                    end

                    final = R2I(lower + (upper - lower) * 0.015625 * (1 + self.quality[count]))
                else
                    final = R2I(lower)
                end

                --round to nearest 10s
                if final >= 1000 then
                    final = (final + 5) // 10 * 10
                end

                return final
            end
        end

        function thistype:equip()
            local pid         = GetPlayerId(GetOwningPlayer(self.holder)) + 1 ---@type integer 
            local hp      = GetWidgetLife(self.holder) ---@type number 
            local mana      = GetUnitState(self.holder, UNIT_STATE_MANA) ---@type number 
            local mod      = ItemProfMod(self.id, pid) ---@type number 

            if self.holder == nil then
                return
            end

            UnitAddBonus(self.holder, BONUS_ARMOR, R2I(mod * self:calcStat(ITEM_ARMOR, 0)))
            UnitAddBonus(self.holder, BONUS_DAMAGE, R2I(mod * self:calcStat(ITEM_DAMAGE, 0)))
            UnitAddBonus(self.holder, BONUS_HERO_STR, R2I(mod * self:calcStat(ITEM_STRENGTH, 0)))
            UnitAddBonus(self.holder, BONUS_HERO_AGI, R2I(mod * self:calcStat(ITEM_AGILITY, 0)))
            UnitAddBonus(self.holder, BONUS_HERO_INT, R2I(mod * self:calcStat(ITEM_INTELLIGENCE, 0)))
            BlzSetUnitMaxHP(self.holder, BlzGetUnitMaxHP(self.holder) + R2I(mod * self:calcStat(ITEM_HEALTH, 0)))
            BlzSetUnitMaxMana(self.holder, BlzGetUnitMaxMana(self.holder) + R2I(mod * self:calcStat(ITEM_MANA, 0)))
            SetWidgetLife(self.holder, hp)
            SetUnitState(self.holder, UNIT_STATE_MANA, mana)

            ItemRegen[pid] = ItemRegen[pid] + self:calcStat(ITEM_REGENERATION, 0)
            ItemMagicRes[pid] = ItemMagicRes[pid] * (1 - self:calcStat(ITEM_MAGIC_RESIST, 0) * 0.01)
            ItemDamageRes[pid] = ItemDamageRes[pid] * (1 - self:calcStat(ITEM_DAMAGE_RESIST, 0) * 0.01)
            ItemEvasion[pid] = ItemEvasion[pid] + self:calcStat(ITEM_EVASION, 0)
            ItemMovespeed[pid] = ItemMovespeed[pid] + self:calcStat(ITEM_MOVESPEED, 0)
            ItemSpellboost[pid] = ItemSpellboost[pid] + self:calcStat(ITEM_SPELLBOOST, 0) * 0.01
            ItemGoldRate[pid] = ItemGoldRate[pid] + self:calcStat(ITEM_GOLD_GAIN, 0)

            --shield
            if ItemData[self.id][ITEM_TYPE] == 5 then
                ShieldCount[pid] = ShieldCount[pid] + 1
            end

            BlzSetUnitAttackCooldown(self.holder, BlzGetUnitAttackCooldown(self.holder, 0) / (1. + self:calcStat(ITEM_BASE_ATTACK_SPEED, 0) * 0.01), 0)

            --profiency warning
            if GetUnitLevel(self.holder) < 15 and mod < 1 then
                DisplayTimedTextToPlayer(self.owner, 0, 0, 10, "You lack the proficiency (-pf) to use this item, it will only give 75\x25 of most stats.\n|cffFF0000You will stop getting this warning at level 15.|r")
            end
        end

        function thistype:unequip()
            local pid         = GetPlayerId(GetOwningPlayer(self.holder)) + 1 ---@type integer 
            local hp      = GetWidgetLife(self.holder) ---@type number 
            local mana      = GetUnitState(self.holder, UNIT_STATE_MANA) ---@type number 
            local mod      = ItemProfMod(self.id, pid) ---@type number 

            if self.holder == nil then
                return
            end

            UnitAddBonus(self.holder, BONUS_ARMOR, -R2I(mod * self:calcStat(ITEM_ARMOR, 0)))
            UnitAddBonus(self.holder, BONUS_DAMAGE, -R2I(mod * self:calcStat(ITEM_DAMAGE, 0)))
            UnitAddBonus(self.holder, BONUS_HERO_STR, -R2I(mod * self:calcStat(ITEM_STRENGTH, 0)))
            UnitAddBonus(self.holder, BONUS_HERO_AGI, -R2I(mod * self:calcStat(ITEM_AGILITY, 0)))
            UnitAddBonus(self.holder, BONUS_HERO_INT, -R2I(mod * self:calcStat(ITEM_INTELLIGENCE, 0)))
            BlzSetUnitMaxHP(self.holder, BlzGetUnitMaxHP(self.holder) - R2I(mod * self:calcStat(ITEM_HEALTH, 0)))
            BlzSetUnitMaxMana(self.holder, BlzGetUnitMaxMana(self.holder) - R2I(mod * self:calcStat(ITEM_MANA, 0)))
            SetWidgetLife(self.holder, math.max(hp, 1))
            SetUnitState(self.holder, UNIT_STATE_MANA, mana)

            ItemRegen[pid] = ItemRegen[pid] - self:calcStat(ITEM_REGENERATION, 0)
            ItemMagicRes[pid] = ItemMagicRes[pid] / (1 - self:calcStat(ITEM_MAGIC_RESIST, 0) * 0.01)
            ItemDamageRes[pid] = ItemDamageRes[pid] / (1 - self:calcStat(ITEM_DAMAGE_RESIST, 0) * 0.01)
            ItemEvasion[pid] = ItemEvasion[pid] - self:calcStat(ITEM_EVASION, 0)
            ItemMovespeed[pid] = ItemMovespeed[pid] - self:calcStat(ITEM_MOVESPEED, 0)
            ItemSpellboost[pid] = ItemSpellboost[pid] - self:calcStat(ITEM_SPELLBOOST, 0) * 0.01
            ItemGoldRate[pid] = ItemGoldRate[pid] - self:calcStat(ITEM_GOLD_GAIN, 0)

            --shield
            if ItemData[self.id][ITEM_TYPE] == 5 then
                ShieldCount[pid] = ShieldCount[pid] - 1
            end

            if self.level > 0 then
                BlzSetItemStringField(self.obj, ITEM_SF_MODEL_USED, ITEM_MODEL[self.level])
            end

            BlzSetUnitAttackCooldown(self.holder, BlzGetUnitAttackCooldown(self.holder, 0) * (1. + self:calcStat(ITEM_BASE_ATTACK_SPEED, 0) * 0.01), 0)
        end

        function thistype:update()
            local orig        = ItemData[self.id][0] ---@type string 
            local s_new        = "" ---@type string 
            local alt_new        = "" ---@type string 
            local i         = 0 ---@type integer 
            local start         = 0 ---@type integer 
            local index         = ITEM_HEALTH - 1 ---@type integer 
            local count         = 0 ---@type integer 
            local value         = 0 ---@type integer 
            local lower         = 0 ---@type integer 
            local upper         = 0 ---@type integer 
            local newlines         = 0 ---@type integer 
            local posneg        = "" ---@type string 
            local valuestr        = "" ---@type string 

            --first "header" lines: rarity, upg level, tier, type, req level
            if self.level > 0 then
                s_new = s_new .. LEVEL_PREFIX[self.level]

                BlzSetItemStringField(self.obj, ITEM_SF_MODEL_USED, ITEM_MODEL[self.level])

                s_new = s_new .. " +" .. self.level

                s_new = s_new .. "|n"
            end

            s_new = s_new .. TIER_NAME[ItemData[self.id][ITEM_TIER]] .. " " .. TYPE_NAME[ItemData[self.id][ITEM_TYPE]]

            if ItemData[self.id][ITEM_LEVEL_REQUIREMENT] > 0 then
                s_new = s_new .. "|n|cffff0000Level Requirement: |r" .. ItemData[self.id][ITEM_LEVEL_REQUIREMENT]
            end

            s_new = s_new .. "|n"

            alt_new = s_new

            for i2 = 1, StringLength(orig) + 1 do
                if SubString(orig, i, i2) == "\\" then
                    newlines = newlines + 1
                    start = i2

                elseif SubString(orig, i, i2) == "[" and newlines > 0 then

                    --find next non-zero stat
                    repeat
                        index = index + 1
                        value = self:calcStat(index, 0)
                    until value ~= 0 or index > ITEM_STAT_TOTAL

                    --safety
                    if index <= ITEM_STAT_TOTAL then
                        --prevent adding a tooltip if not yet unlocked
                        if self.level >= ItemData[self.id][index + BOUNDS_OFFSET * 5] then
                            lower = self:calcStat(index, 1)
                            upper = self:calcStat(index, 2)
                            valuestr = tostring(value)
                            posneg = "+ |cffffcc00"

                            --negative handling
                            if value < 0 then
                                valuestr = tostring(-value)
                                posneg = "- |cffcc0000"
                            end

                            if newlines == 1 then
                                --alt tooltip
                                --stat has variance
                                if ItemData[self.id][index + BOUNDS_OFFSET] ~= 0 then
                                    if index == ITEM_CRIT_CHANCE then
                                        alt_new = alt_new .. "|n + |cffffcc00" .. lower .. "-" .. upper .. "\x25 " .. self:calcStat(index + 1, 1) .. "-" .. self:calcStat(index + 1, 2) .. "x|r |cffffcc00Critical Strike|r"
                                    elseif index == ITEM_CRIT_DAMAGE then
                                    elseif index == ITEM_ABILITY or index == ITEM_ABILITY2 then
                                        alt_new = alt_new .. "|n" .. ParseItemAbilityTooltip(self, index, value, lower, upper)
                                    else
                                        alt_new = alt_new .. "|n + |cffffcc00" .. lower .. "-" .. upper .. STAT_NAME[index] .. ""
                                    end

                                    count = count + 1
                                else
                                    if index == ITEM_CRIT_CHANCE then
                                        alt_new = alt_new .. "|n + |cffffcc00" .. valuestr .. "\x25 " .. self:calcStat(index + 1, 0) .. "x|r |cffffcc00Critical Strike|r"
                                    elseif index == ITEM_CRIT_DAMAGE then
                                    elseif index == ITEM_ABILITY or index == ITEM_ABILITY2 then
                                        alt_new = alt_new .. "|n" .. ParseItemAbilityTooltip(self, index, value, 0, 0)
                                    else
                                        alt_new = alt_new .. "|n " .. posneg .. valuestr .. STAT_NAME[index]
                                    end
                                end

                                --normal tooltip
                                if index == ITEM_CRIT_CHANCE then
                                    s_new = s_new .. "|n + |cffffcc00" .. valuestr .. "\x25 "
                                elseif index == ITEM_CRIT_DAMAGE then
                                    s_new = s_new .. valuestr .. STAT_NAME[index]
                                elseif index == ITEM_ABILITY or index == ITEM_ABILITY2 then
                                    s_new = s_new .. "|n" .. ParseItemAbilityTooltip(self, index, value, 0, 0)
                                else
                                    s_new = s_new .. "|n " .. posneg .. valuestr .. STAT_NAME[index]
                                end
                            elseif newlines > 1 then
                                s_new = s_new .. SubString(orig, start, i) .. lower
                                alt_new = alt_new .. SubString(orig, start, i) .. lower
                            end
                        end
                    end
                elseif SubString(orig, i, i2) == "]" and newlines > 1 then
                    start = i2
                end

                i = i + 1
            end

            self.tooltip = s_new .. SubString(orig, start, StringLength(orig))
            self.alt_tooltip = alt_new .. SubString(orig, start, StringLength(orig))

            if ItemData[self.id][ITEM_LIMIT] > 0 then
                self.tooltip = self.tooltip .. "|nLimit: 1"
                self.alt_tooltip = self.alt_tooltip .. "|nLimit: 1"
            end

            BlzSetItemDescription(self.obj, self.tooltip)
            BlzSetItemExtendedTooltip(self.obj, self.tooltip)
        end

        ---@type fun(id: integer)
        function thistype:decode(id)
            local shift = 0
            local mask = 0x3F --111111

            for i = 2, QUALITY_SAVED - 1 do
                self.quality[i] = (id & mask) >> shift

                mask = mask << 6
                shift = shift + 6
            end

            self:lvl(self.level)
        end

        ---@type fun(id: integer):Item
        function thistype.decode_id(id)
            local itemid = id & (2 ^ 13 - 1) ---@type integer 
            local shift = 13 ---@type integer 

            if id == 0 then
                return nil
            end

            --call DEBUGMSG(IntToFourCC(CUSTOM_ITEM_OFFSET + itemid))
            --call DEBUGMSG(GetObjectName(CUSTOM_ITEM_OFFSET + itemid))

            local itm = thistype.create(CreateItem(CUSTOM_ITEM_OFFSET + itemid, 30000., 30000.))
            itm.level = BlzBitAnd(id, 2 ^ (shift + 5) + 2 ^ (shift + 4) + 2 ^ (shift + 3) + 2 ^ (shift + 2) + 2 ^ (shift + 1) + 2 ^ (shift)) // 2 ^ (shift)

            for i = 0, 1 do
                shift = shift + 6

                if id >= 2 ^ (shift) then
                    itm.quality[i] = BlzBitAnd(id, 2 ^ (shift + 5) + 2 ^ (shift + 4) + 2 ^ (shift + 3) + 2 ^ (shift + 2) + 2 ^ (shift + 1) + 2 ^ (shift)) / 2 ^ (shift)
                end
            end

            return itm
        end

        ---@return integer
        function thistype:encode()
            local id = 0

            for i = 2, 6 do
                id = id + self.quality[i] * 2 ^ ((i - 2) * 6)
            end

            return id
        end

        ---@type fun():integer
        function thistype:encode_id()
            local id = ItemToIndex(self.id)

            if id == 0 then
                return 0
            end

            id = id + self.level * 2 ^ (13 + i * 6)

            for i = 0, 1 do
                id = id + self.quality[i] * 2 ^ (13 + (i + 1) * 6)
            end

            return id
        end

        function thistype:onDestroy()
            --proper removal
            DestroyTrigger(self.trig)
            SetWidgetLife(self.obj, 1.)
            RemoveItem(self.obj)

            --call DEBUGMSG("Item Removed!")
        end

        function thistype:destroy()
            self:onDestroy()

            thistype[self] = nil
            self = nil
        end

        ---@type fun(itm: Item)
        function thistype.expire(itm)
            if itm.holder == nil and itm.owner == nil then
                itm:destroy()
            end
        end

        ---@return boolean
        function thistype.onDeath()
            --typecast widget to item
            SaveWidgetHandle(MiscHash, 0, 0, GetTriggerWidget())

            TimerQueue:callDelayed(2., thistype.expire, Item[LoadItemHandle(MiscHash, 0, 0)])

            RemoveSavedHandle(MiscHash, 0, 0)
            return false
        end
    end

    ---@class DropTable
    ---@field adjustRate function
    ---@field getType function
    ---@field pickItem function
    DropTable = {}
    do
        local thistype = DropTable

        --adjusts the drop rates of all items in a pool after a drop
        ---@type fun(id: integer, i: integer)
        local function adjustRate(id, index)
            local max = ItemDrops[id][MAX_ITEM_COUNT]

            if ItemDrops[id] == nil or max <= 1 then
                return
            end

            local adjust = 1. / max * ADJUST_RATE
            local balance = adjust / (max - 1.)

            for i = 0, max - 1 do
                if ItemDrops[id][i] == ItemDrops[id][index] then
                    ItemDrops[id][i .. "\x25"] = ItemDrops[id][i .. "\x25"] - adjust
                else
                    ItemDrops[id][i .. "\x25"] = ItemDrops[id][i .. "\x25"] + balance
                end
            end
        end

        --[[selects an item from a unit type item pool
            starts at a random index and increments by 1]]
        ---@type fun(id: integer):integer
        function thistype:pickItem(id)
            local max = ItemDrops[id][MAX_ITEM_COUNT] - 1
            local i = GetRandomInt(0, max)

            while true do
                if GetRandomReal(0., 1.) < ItemDrops[id][i .. "\x25"] then
                    adjustRate(id, i)
                    break
                end

                if i >= max then
                    i = 0
                else
                    i = i + 1
                end
            end

            return ItemDrops[id][i]
        end

        --[[unifies different unit types into one to reference an item pool]]
        ---@type fun(id: integer):integer
        function thistype:getType(id)
            if id == FourCC('nits') or id == FourCC('nitt') then --Troll
                return FourCC('nits')
            elseif id == FourCC('ntks') or id == FourCC('ntkw') or id == FourCC('ntkc') then --Tuskarr
                return FourCC('ntks')
            elseif id == FourCC('nnwr') or id == FourCC('nnws') then --Spider
                return FourCC('nnwr')
            elseif id == FourCC('nfpu') or id == FourCC('nfpe') then --polar furbolg ursa
                return FourCC('nfpu')
            elseif id == FourCC('nplg') then -- polar bear
                return FourCC('nplg')
            elseif id == FourCC('nmdr') then --dire mammoth
                return FourCC('nmdr')
            elseif id == FourCC('n01G') or id == FourCC('o01G') then -- ogre, tauren
                return FourCC('n01G')
            elseif id == FourCC('nubw') or id == FourCC('nfor') or id == FourCC('nfod') then --unbroken
                return FourCC('nubw')
            elseif id == FourCC('nvdl') or id == FourCC('nvdw') then -- hellfire, hellhound
                return FourCC('nvdl')
            elseif id == FourCC('n024') or id == FourCC('n027') or id == FourCC('n028') then -- Centaur
                return FourCC('n024')
            elseif id == FourCC('n01M') or id == FourCC('n08M') then -- magnataur, forgotten one
                return FourCC('n01M')
            elseif id == FourCC('n02P') or id == FourCC('n01R') then -- drost dragon, frost drake
                return FourCC('n02P')
            elseif id == FourCC('n099') then -- frost elder dragon
                return FourCC('n099')
            elseif id == FourCC('n02L') or id == FourCC('n00C') then -- devourers
                return FourCC('n02L')
            elseif id == FourCC('nplb') then -- giant bear
                return FourCC('nplb')
            elseif id == FourCC('n01H') then -- ancient hydra
                return FourCC('n01H')
            elseif id == FourCC('n02U') then -- nerubian
                return FourCC('n02U')
            elseif id == FourCC('n03L') then -- king of ogres
                return FourCC('n03L')
            elseif id == FourCC('n02H') then -- yeti
                return FourCC('n02H')
            elseif id == FourCC('H02H') then -- paladin
                return FourCC('H02H')
            elseif id == FourCC('O002') then -- minotaur
                return FourCC('O002')
            elseif id == FourCC('H020') then -- lady vashj
                return FourCC('H020')
            elseif id == FourCC('H01V') then -- last dwarf
                return FourCC('H01V')
            elseif id == FourCC('H040') then -- death knight
                return FourCC('H040')
            elseif id == FourCC('U00G') then -- hellfire magi
                return FourCC('U00G')
            elseif id == FourCC('H045') then -- mystic
                return FourCC('H045')
            elseif id == FourCC('O01B') then -- dragoon
                return FourCC('O01B')
            elseif id == FourCC('E00B') then -- goddess of hate
                return FourCC('E00B')
            elseif id == FourCC('E00D') then -- goddess of love
                return FourCC('E00D')
            elseif id == FourCC('E00C') then -- goddess of knowledge
                return FourCC('E00C')
            elseif id == FourCC('H04Q') then -- goddess of life
                return FourCC('H04Q')
            elseif id == FourCC('H00O') or id == FourCC('E007') then -- arkaden
                return FourCC('H00O')
            elseif id == FourCC('n034') or id == FourCC('n033') then --demons
                return FourCC('n034')
            elseif id == FourCC('n03A') or id == FourCC('n03B') or id == FourCC('n03C') then --horror
                return FourCC('n03A')
            elseif id == FourCC('n03F') or id == FourCC('n01W') then --despair
                return FourCC('n03F')
            elseif id == FourCC('n08N') or id == FourCC('n00W') or id == FourCC('n00X') then --abyssal
                return FourCC('n08N')
            elseif id == FourCC('n031') or id == FourCC('n030') or id == FourCC('n02Z') then --void
                return FourCC('n031')
            elseif id == FourCC('n020') or id == FourCC('n02J') then --nightmare
                return FourCC('n020')
            elseif id == FourCC('n03D') or id == FourCC('n03E') or id == FourCC('n03G') then --hell
                return FourCC('n03D')
            elseif id == FourCC('n03J') or id == FourCC('n01X') then --existence
                return FourCC('n03J')
            elseif id == FourCC('n03M') or id == FourCC('n01V') then --astral
                return FourCC('n03M')
            elseif id == FourCC('n026') or id == FourCC('n03T') then --plainswalker
                return FourCC('n026')
            elseif id == FourCC('N038') then -- Demon Prince
                return FourCC('N038')
            elseif id == FourCC('N017') then -- Absolute Horror
                return FourCC('N017')
            elseif id == FourCC('O02B') then -- Slaughter
                return FourCC('O02B')
            elseif id == FourCC('O02H') then -- Dark Soul
                return FourCC('O02H')
            elseif id == FourCC('O02I') then --Satan
                return FourCC('O02I')
            elseif id == FourCC('O02K') then -- Thanatos
                return FourCC('O02K')
            elseif id == FourCC('H04R') then --Legion
                return FourCC('H04R')
            elseif id == FourCC('O02M') then -- Existence
                return FourCC('O02M')
            elseif id == FourCC('O03G') then --Xallarath
                return FourCC('O03G')
            elseif id == FourCC('O02T') then --Azazoth
                return FourCC('O02T')
            end

            return id
        end

        ---@type fun(id: integer, max: integer)
        local function setupRates(id, max)
            ItemDrops[id][MAX_ITEM_COUNT] = (max + 1)

            for i = 0, max do
                ItemDrops[id][i .. "\x25"] = 1. / (max + 1)
            end
        end

        local id = 69 --destructable
        ItemDrops[id][0] = FourCC('I00O')
        ItemDrops[id][1] = FourCC('I00Q')
        ItemDrops[id][2] = FourCC('I00R')
        ItemDrops[id][3] = FourCC('I01C')
        ItemDrops[id][4] = FourCC('I01F')
        ItemDrops[id][5] = FourCC('I01G')
        ItemDrops[id][6] = FourCC('I01H')
        ItemDrops[id][7] = FourCC('I01I')
        ItemDrops[id][8] = FourCC('I01K')
        ItemDrops[id][9] = FourCC('I01V')
        ItemDrops[id][10] = FourCC('I021')
        ItemDrops[id][11] = FourCC('I02R')
        ItemDrops[id][12] = FourCC('I02T')
        ItemDrops[id][13] = FourCC('I04O')
        ItemDrops[id][14] = FourCC('I01X')
        ItemDrops[id][15] = FourCC('I06F')
        ItemDrops[id][16] = FourCC('I06G')
        ItemDrops[id][17] = FourCC('I06H')
        ItemDrops[id][18] = FourCC('I090')
        ItemDrops[id][19] = FourCC('I01Z')
        ItemDrops[id][20] = FourCC('I0FJ')

        setupRates(id, 20)

        --evil shopkeeper
        id = FourCC('n01F')
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I045') --bloodstained cloak

        setupRates(id, 0)

        id = FourCC('nits') --troll
        Rates[id] = 40
        ItemDrops[id][0] = FourCC('I01Z') --claws of lightning
        ItemDrops[id][1] = FourCC('I01F') --iron broadsword
        ItemDrops[id][2] = FourCC('I01I') --iron sword
        ItemDrops[id][3] = FourCC('I01G') --iron dagger
        ItemDrops[id][4] = FourCC('I0FJ') --chipped shield
        ItemDrops[id][5] = FourCC('I02H') --short bow
        ItemDrops[id][6] = FourCC('I04O') --wooden staff
        ItemDrops[id][7] = FourCC('I01H') --iron shield
        ItemDrops[id][8] = FourCC('I00Q') --belt of the giant
        ItemDrops[id][9] = FourCC('I00R') --boots of the ranger
        ItemDrops[id][10] = FourCC('I02R') --sigil of magic
        ItemDrops[id][11] = FourCC('I01C') --gauntlets of strength
        ItemDrops[id][12] = FourCC('I02T') --slippers of agility
        ItemDrops[id][13] = FourCC('I01S') --seven league boots
        ItemDrops[id][14] = FourCC('I01K') --leather jacket
        ItemDrops[id][15] = FourCC('I01X') --sword of revival
        ItemDrops[id][16] = FourCC('I01V') --medallion of courage
        ItemDrops[id][17] = FourCC('I021') --medallion of vitality
        ItemDrops[id][18] = FourCC('I02D') --ring of regeneration
        ItemDrops[id][19] = FourCC('I062') --healing potion
        ItemDrops[id][20] = FourCC('I06E') --mana potion
        ItemDrops[id][21] = FourCC('I06F') --crystal ball
        ItemDrops[id][22] = FourCC('I06G') --talisman of evasion
        ItemDrops[id][23] = FourCC('I06H') --warsong battle drums
        ItemDrops[id][24] = FourCC('I090') --sparky orb
        ItemDrops[id][25] = FourCC('I04D') --tattered cloth

        setupRates(id, 25)

        id = FourCC('ntks') --tuskarr
        Rates[id] = 40
        ItemDrops[id][0] = FourCC('I01Z')
        ItemDrops[id][1] = FourCC('I01X')
        ItemDrops[id][2] = FourCC('I01V')
        ItemDrops[id][3] = FourCC('I021')
        ItemDrops[id][4] = FourCC('I02D')
        ItemDrops[id][5] = FourCC('I062')
        ItemDrops[id][6] = FourCC('I06E')
        ItemDrops[id][7] = FourCC('I06F')
        ItemDrops[id][8] = FourCC('I06G')
        ItemDrops[id][9] = FourCC('I06H')
        ItemDrops[id][10] = FourCC('I090')
        ItemDrops[id][11] = FourCC('I01S')
        ItemDrops[id][12] = FourCC('I04D')
        ItemDrops[id][13] = FourCC('I03A') --steel dagger
        ItemDrops[id][14] = FourCC('I03W') --steel sword
        ItemDrops[id][15] = FourCC('I00O') --arcane staff
        ItemDrops[id][16] = FourCC('I03S') --steel shield
        ItemDrops[id][17] = FourCC('I01L') --long bow
        ItemDrops[id][18] = FourCC('I03K') --steel lance
        ItemDrops[id][19] = FourCC('I08Y') --noble blade
        ItemDrops[id][20] = FourCC('I03Q') --horse boost

        setupRates(id, 20)

        id = FourCC('nnwr') --spider
        Rates[id] = 35
        ItemDrops[id][0] = FourCC('I03A')
        ItemDrops[id][1] = FourCC('I03W')
        ItemDrops[id][2] = FourCC('I00O')
        ItemDrops[id][3] = FourCC('I03K')
        ItemDrops[id][4] = FourCC('I01L')
        ItemDrops[id][5] = FourCC('I03S')
        ItemDrops[id][6] = FourCC('I08Y')
        ItemDrops[id][7] = FourCC('I03Q')
        ItemDrops[id][8] = FourCC('I0FK') --mythril sword
        ItemDrops[id][9] = FourCC('I00F') --mythril spear
        ItemDrops[id][10] = FourCC('I010') --mythril dagger
        ItemDrops[id][11] = FourCC('I00N') --blood elven staff
        ItemDrops[id][12] = FourCC('I0FM') --blood elven bow
        ItemDrops[id][13] = FourCC('I0FL') --mythril shield
        ItemDrops[id][14] = FourCC('I028') --big health potion
        ItemDrops[id][15] = FourCC('I00D') --big mana potion
        ItemDrops[id][16] = FourCC('I025') --greater mask of death

        setupRates(id, 16)

        id = FourCC('nfpu') --ursa
        Rates[id] = 30
        ItemDrops[id][0] = FourCC('I028')
        ItemDrops[id][1] = FourCC('I00D')
        ItemDrops[id][2] = FourCC('I025')
        ItemDrops[id][3] = FourCC('I02L') --great circlet
        ItemDrops[id][4] = FourCC('I06T') --sword
        ItemDrops[id][5] = FourCC('I034') --heavy
        ItemDrops[id][6] = FourCC('I0FG') --dagger
        ItemDrops[id][7] = FourCC('I06R') --bow
        ItemDrops[id][8] = FourCC('I0FT') --staff

        setupRates(id, 8)

        id = FourCC('nplg') --polar bear
        Rates[id] = 30
        ItemDrops[id][0] = FourCC('I035') --plate
        ItemDrops[id][1] = FourCC('I0FO') --leather
        ItemDrops[id][2] = FourCC('I07O') --cloth

        setupRates(id, 2)

        id = FourCC('nmdr') --dire mammoth
        Rates[id] = 30
        ItemDrops[id][0] = FourCC('I0FQ') --fullplate

        setupRates(id, 0)

        id = FourCC('n01G') -- ogre tauren
        Rates[id] = 25
        ItemDrops[id][0] = FourCC('I02L')
        ItemDrops[id][1] = FourCC('I08I')
        ItemDrops[id][2] = FourCC('I0FE')
        ItemDrops[id][3] = FourCC('I07W')
        ItemDrops[id][4] = FourCC('I08B')
        ItemDrops[id][5] = FourCC('I0FD')
        ItemDrops[id][6] = FourCC('I08R')
        ItemDrops[id][7] = FourCC('I08E')
        ItemDrops[id][8] = FourCC('I08F')
        ItemDrops[id][9] = FourCC('I07Y')
        ItemDrops[id][10] = FourCC('I00B') --axe of speed

        setupRates(id, 10)

        id = FourCC('nubw') --unbroken
        Rates[id] = 25
        ItemDrops[id][0] = FourCC('I0FS')
        ItemDrops[id][1] = FourCC('I0FR')
        ItemDrops[id][2] = FourCC('I0FY')
        ItemDrops[id][3] = FourCC('I01W')
        ItemDrops[id][4] = FourCC('I0MB')

        setupRates(id, 4)

        id = FourCC('nvdl') -- hellfire hellhound
        Rates[id] = 25
        ItemDrops[id][0] = FourCC('I00Z')
        ItemDrops[id][1] = FourCC('I00S')
        ItemDrops[id][2] = FourCC('I011')
        ItemDrops[id][3] = FourCC('I02E')
        ItemDrops[id][4] = FourCC('I023')
        ItemDrops[id][5] = FourCC('I0MA')

        setupRates(id, 5)

        id = FourCC('n024') -- centaur
        Rates[id] = 25
        ItemDrops[id][0] = FourCC('I06J')
        ItemDrops[id][1] = FourCC('I06I')
        ItemDrops[id][2] = FourCC('I06L')
        ItemDrops[id][3] = FourCC('I06K')
        ItemDrops[id][4] = FourCC('I07H')

        setupRates(id, 4)

        id = FourCC('n01M') -- magnataur forgotten one
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I01Q')
        ItemDrops[id][1] = FourCC('I01N')
        ItemDrops[id][2] = FourCC('I015')
        ItemDrops[id][3] = FourCC('I019')

        setupRates(id, 3)

        id = FourCC('n02P') -- frost dragon frost drake
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I056')
        ItemDrops[id][1] = FourCC('I04X')
        ItemDrops[id][2] = FourCC('I05Z')

        setupRates(id, 2)

        id = FourCC('n099') -- frost elder dragon
        Rates[id] = 40
        ItemDrops[id][0] = FourCC('I056')
        ItemDrops[id][1] = FourCC('I04X')
        ItemDrops[id][2] = FourCC('I05Z')

        setupRates(id, 2)

        id = FourCC('n02L') -- devourers
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I02W')
        ItemDrops[id][1] = FourCC('I00W')
        ItemDrops[id][2] = FourCC('I017')
        ItemDrops[id][3] = FourCC('I013')
        ItemDrops[id][4] = FourCC('I02I')
        ItemDrops[id][5] = FourCC('I01P')
        ItemDrops[id][6] = FourCC('I006')
        ItemDrops[id][7] = FourCC('I02V')
        ItemDrops[id][8] = FourCC('I009')

        setupRates(id, 8)

        id = FourCC('nplb') -- giant bear
        Rates[id] = 40
        ItemDrops[id][0] = FourCC('I0MC')
        ItemDrops[id][1] = FourCC('I0MD')
        ItemDrops[id][2] = FourCC('I0FB')

        setupRates(id, 2)

        id = FourCC('n01H') -- ancient hydra
        Rates[id] = 25
        ItemDrops[id][0] = FourCC('I07N')
        ItemDrops[id][1] = FourCC('I044')

        setupRates(id, 1)

        id = FourCC('n034') --demons
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I073')
        ItemDrops[id][1] = FourCC('I075')
        ItemDrops[id][2] = FourCC('I06Z')
        ItemDrops[id][3] = FourCC('I06W')
        ItemDrops[id][4] = FourCC('I04T')
        ItemDrops[id][5] = FourCC('I06S')
        ItemDrops[id][6] = FourCC('I06U')
        ItemDrops[id][7] = FourCC('I06O')
        ItemDrops[id][8] = FourCC('I06Q')

        setupRates(id, 8)

        id = FourCC('n03A') --horror
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I07K')
        ItemDrops[id][1] = FourCC('I05D')
        ItemDrops[id][2] = FourCC('I07E')
        ItemDrops[id][3] = FourCC('I07I')
        ItemDrops[id][4] = FourCC('I07G')
        ItemDrops[id][5] = FourCC('I07C')
        ItemDrops[id][6] = FourCC('I07A')
        ItemDrops[id][7] = FourCC('I07M')
        ItemDrops[id][8] = FourCC('I07L')
        ItemDrops[id][9] = FourCC('I07P')
        ItemDrops[id][10] = FourCC('I077')

        setupRates(id, 10)

        id = FourCC('n03F') --despair
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I05P')
        ItemDrops[id][1] = FourCC('I087')
        ItemDrops[id][2] = FourCC('I089')
        ItemDrops[id][3] = FourCC('I083')
        ItemDrops[id][4] = FourCC('I081')
        ItemDrops[id][5] = FourCC('I07X')
        ItemDrops[id][6] = FourCC('I07V')
        ItemDrops[id][7] = FourCC('I07Z')
        ItemDrops[id][8] = FourCC('I07R')
        ItemDrops[id][9] = FourCC('I07T')
        ItemDrops[id][10] = FourCC('I05O')

        setupRates(id, 10)

        id = FourCC('n08N') --abyssal
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I06C')
        ItemDrops[id][1] = FourCC('I06B')
        ItemDrops[id][2] = FourCC('I0A0')
        ItemDrops[id][3] = FourCC('I0A2')
        ItemDrops[id][4] = FourCC('I09X')
        ItemDrops[id][5] = FourCC('I0A5')
        ItemDrops[id][6] = FourCC('I09N')
        ItemDrops[id][7] = FourCC('I06D')
        ItemDrops[id][8] = FourCC('I06A')

        setupRates(id, 8)

        id = FourCC('n031') --void
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I04Y')
        ItemDrops[id][1] = FourCC('I08C')
        ItemDrops[id][2] = FourCC('I08D')
        ItemDrops[id][3] = FourCC('I08G')
        ItemDrops[id][4] = FourCC('I08H')
        ItemDrops[id][5] = FourCC('I08J')
        ItemDrops[id][6] = FourCC('I055')
        ItemDrops[id][7] = FourCC('I08M')
        ItemDrops[id][8] = FourCC('I08N')
        ItemDrops[id][9] = FourCC('I08O')
        ItemDrops[id][10] = FourCC('I08S')
        ItemDrops[id][11] = FourCC('I08U')
        ItemDrops[id][12] = FourCC('I04W')

        setupRates(id, 12)

        id = FourCC('n020') --nightmare
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I09S')
        ItemDrops[id][1] = FourCC('I0AB')
        ItemDrops[id][2] = FourCC('I09R')
        ItemDrops[id][3] = FourCC('I0A9')
        ItemDrops[id][4] = FourCC('I09V')
        ItemDrops[id][5] = FourCC('I0AC')
        ItemDrops[id][6] = FourCC('I0A7')
        ItemDrops[id][7] = FourCC('I09T')
        ItemDrops[id][8] = FourCC('I09P')
        ItemDrops[id][9] = FourCC('I04Z')

        setupRates(id, 9)

        id = FourCC('n03D') --hell
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I097')
        ItemDrops[id][1] = FourCC('I05H')
        ItemDrops[id][2] = FourCC('I098')
        ItemDrops[id][3] = FourCC('I095')
        ItemDrops[id][4] = FourCC('I08W')
        ItemDrops[id][5] = FourCC('I05G')
        ItemDrops[id][6] = FourCC('I08Z')
        ItemDrops[id][7] = FourCC('I091')
        ItemDrops[id][8] = FourCC('I093')
        ItemDrops[id][9] = FourCC('I05I')

        setupRates(id, 9)

        id = FourCC('n03J') --existence
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I09Y')
        ItemDrops[id][1] = FourCC('I09U')
        ItemDrops[id][2] = FourCC('I09W')
        ItemDrops[id][3] = FourCC('I09Q')
        ItemDrops[id][4] = FourCC('I09O')
        ItemDrops[id][5] = FourCC('I09M')
        ItemDrops[id][6] = FourCC('I09K')
        ItemDrops[id][7] = FourCC('I09I')
        ItemDrops[id][8] = FourCC('I09G')
        ItemDrops[id][9] = FourCC('I09E')

        setupRates(id, 9)

        id = FourCC('n03M') --astral
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I0AL')
        ItemDrops[id][1] = FourCC('I0AN')
        ItemDrops[id][2] = FourCC('I0AA')
        ItemDrops[id][3] = FourCC('I0A8')
        ItemDrops[id][4] = FourCC('I0A6')
        ItemDrops[id][5] = FourCC('I0A3')
        ItemDrops[id][6] = FourCC('I0A1')
        ItemDrops[id][7] = FourCC('I0A4')
        ItemDrops[id][8] = FourCC('I09Z')

        setupRates(id, 8)

        id = FourCC('n026') --plainswalker
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I0AY')
        ItemDrops[id][1] = FourCC('I0B0')
        ItemDrops[id][2] = FourCC('I0B2')
        ItemDrops[id][3] = FourCC('I0B3')
        ItemDrops[id][4] = FourCC('I0AQ')
        ItemDrops[id][5] = FourCC('I0AO')
        ItemDrops[id][6] = FourCC('I0AT')
        ItemDrops[id][7] = FourCC('I0AR')
        ItemDrops[id][8] = FourCC('I0AW')

        setupRates(id, 8)

        id = FourCC('H01T') --town paladin
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I01Y')

        setupRates(id, 0)

        id = FourCC('n02U') -- nerubian
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I01E')

        setupRates(id, 0)

        id = FourCC('n03L') -- king of ogres
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I02M')

        setupRates(id, 0)

        id = FourCC('O019') -- pinky
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I02Y')

        setupRates(id, 0)

        id = FourCC('H043') -- bryan
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I02X')

        setupRates(id, 0)

        id = FourCC('N01N') -- kroresh
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I04B')

        setupRates(id, 0)

        id = FourCC('O01A') -- zeknen
        Rates[id] = 100
        --no items

        id = FourCC('N00M') -- forest corruption
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I07J')

        setupRates(id, 0)

        id = FourCC('O00T') -- ice troll
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I03Z')

        setupRates(id, 0)

        id = FourCC('n02H') -- yeti
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I05R')

        setupRates(id, 0)

        id = FourCC('H02H') -- paladin
        Rates[id] = 80
        ItemDrops[id][0] = FourCC('I0F9')
        ItemDrops[id][1] = FourCC('I03P')
        ItemDrops[id][2] = FourCC('I0C0')
        ItemDrops[id][3] = FourCC('I0FX')

        setupRates(id, 3)

        id = FourCC('O002') -- minotaur
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I03T')
        ItemDrops[id][1] = FourCC('I0FW')
        ItemDrops[id][2] = FourCC('I07U')
        ItemDrops[id][3] = FourCC('I076')
        ItemDrops[id][4] = FourCC('I078')

        setupRates(id, 4)

        id = FourCC('H020') -- lady vashj
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I09F') -- sea wards
        ItemDrops[id][1] = FourCC('I09L') -- serpent hide boots

        setupRates(id, 1)

        id = FourCC('H01V') -- dwarven
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I079')
        ItemDrops[id][1] = FourCC('I07B')
        ItemDrops[id][2] = FourCC('I0FC')

        setupRates(id, 2)

        id = FourCC('H040') -- death knight
        Rates[id] = 80
        ItemDrops[id][0] = FourCC('I02O')
        ItemDrops[id][1] = FourCC('I029')
        ItemDrops[id][2] = FourCC('I02C')
        ItemDrops[id][3] = FourCC('I02B')

        setupRates(id, 3)

        id = FourCC('U00G') -- tri fire
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I0FA')
        ItemDrops[id][1] = FourCC('I0FU')
        ItemDrops[id][2] = FourCC('I00V')
        ItemDrops[id][3] = FourCC('I03Y')

        setupRates(id, 3)

        id = FourCC('H045') -- mystic
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I03U')
        ItemDrops[id][1] = FourCC('I0F3')
        ItemDrops[id][2] = FourCC('I07F')

        setupRates(id, 2)

        id = FourCC('O01B') -- dragoon
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I0EX')
        ItemDrops[id][1] = FourCC('I0EY')
        ItemDrops[id][2] = FourCC('I074')
        ItemDrops[id][3] = FourCC('I04N')

        setupRates(id, 3)

        id = FourCC('E00B') -- goddess of hate
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I02Z') --aura of hate

        setupRates(id, 0)

        id = FourCC('E00D') -- goddess of love
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I030') --aura of love

        setupRates(id, 0)

        id = FourCC('E00C') -- goddess of knowledge
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I031') --aura of knowledge

        setupRates(id, 0)

        id = FourCC('H04Q') -- goddess of life
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I04I') --aura of life

        setupRates(id, 0)

        id = FourCC('H00O') -- arkaden
        Rates[id] = 80
        ItemDrops[id][0] = FourCC('I02O')
        ItemDrops[id][1] = FourCC('I02C')
        ItemDrops[id][2] = FourCC('I02B')
        ItemDrops[id][3] = FourCC('I036')

        setupRates(id, 3)

        id = FourCC('N038') -- demon prince
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I04Q') --heart

        setupRates(id, 0)

        id = FourCC('N017') -- absolute horror
        Rates[id] = 85
        ItemDrops[id][0] = FourCC('I0N7')
        ItemDrops[id][1] = FourCC('I0N8')
        ItemDrops[id][2] = FourCC('I0N9')

        setupRates(id, 2)

        id = FourCC('O02B') -- slaughter
        Rates[id] = 85
        ItemDrops[id][0] = FourCC('I0AE')
        ItemDrops[id][1] = FourCC('I04F')
        ItemDrops[id][2] = FourCC('I0AF')
        ItemDrops[id][3] = FourCC('I0AD')
        ItemDrops[id][4] = FourCC('I0AG')

        setupRates(id, 4)

        id = FourCC('O02H') -- dark soul
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I05A')
        ItemDrops[id][1] = FourCC('I0AH')
        ItemDrops[id][2] = FourCC('I0AP')
        ItemDrops[id][3] = FourCC('I0AI')

        setupRates(id, 3)

        id = FourCC('O02I') -- satan
        Rates[id] = 65
        ItemDrops[id][0] = FourCC('I0BX')
        ItemDrops[id][1] = FourCC('I05J')

        setupRates(id, 1)

        id = FourCC('O02K') -- thanatos
        Rates[id] = 65
        ItemDrops[id][0] = FourCC('I04E')
        ItemDrops[id][1] = FourCC('I0MR')

        setupRates(id, 1)

        id = FourCC('H04R') -- legion
        Rates[id] = 60
        ItemDrops[id][0] = FourCC('I0B5')
        ItemDrops[id][1] = FourCC('I0B7')
        ItemDrops[id][2] = FourCC('I0B1')
        ItemDrops[id][3] = FourCC('I0AU')
        ItemDrops[id][4] = FourCC('I04L')
        ItemDrops[id][5] = FourCC('I0AJ')
        ItemDrops[id][6] = FourCC('I0AZ')
        ItemDrops[id][7] = FourCC('I0AS')
        ItemDrops[id][8] = FourCC('I0AV')
        ItemDrops[id][9] = FourCC('I0AX')

        setupRates(id, 9)

        id = FourCC('O02M') -- existence
        Rates[id] = 60
        ItemDrops[id][0] = FourCC('I018')
        ItemDrops[id][1] = FourCC('I0BY')

        setupRates(id, 1)

        id = FourCC('O03G') -- Xallarath
        Rates[id] = 30
        ItemDrops[id][0] = FourCC('I0OB')
        ItemDrops[id][1] = FourCC('I0O1')
        ItemDrops[id][2] = FourCC('I0CH')

        setupRates(id, 2)

        id = FourCC('O02T') -- azazoth
        Rates[id] = 60
        ItemDrops[id][0] = FourCC('I0BS')
        ItemDrops[id][1] = FourCC('I0BV')
        ItemDrops[id][2] = FourCC('I0BK')
        ItemDrops[id][3] = FourCC('I0BI')
        ItemDrops[id][4] = FourCC('I0BB')
        ItemDrops[id][5] = FourCC('I0BC')
        ItemDrops[id][6] = FourCC('I0BE')
        ItemDrops[id][7] = FourCC('I0B9')
        ItemDrops[id][8] = FourCC('I0BG')
        ItemDrops[id][9] = FourCC('I06M')

        setupRates(id, 9)
    end

---@return boolean
function RechargeItem()
    local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw              = DialogWindow[pid] ---@type DialogWindow 
    local index         = dw:getClickedIndex(GetClickedButton()) ---@type integer 
    local itm ---@type Item?

    if index ~= -1 then
        itm = GetResurrectionItem(pid, true)

        if itm then
            itm:charge(itm.charges + 1)

            if Hardcore[pid] then
                ChargeNetworth(Player(pid - 1), ItemData[itm.id][ITEM_COST] * 3, 0.03, 0, "Recharged " .. GetItemName(itm.obj) .. " for")
            else
                ChargeNetworth(Player(pid - 1), ItemData[itm.id][ITEM_COST], 0.01, 0, "Recharged " .. GetItemName(itm.obj) .. " for")
            end
            TimerStart(rezretimer[pid], 180., false, nil)
        end

        dw:destroy()
    end

    return false
end

---@type fun(pid: integer, itm: Item)
function RechargeDialog(pid, itm)
    local percentage = 0.01
    if Hardcore[pid] then
        percentage = 0.03
    end

    local message      = GetObjectName(itm.id) ---@type string 
    local playerGold   = GetCurrency(pid, GOLD) ---@type integer 
    local playerLumber = GetCurrency(pid, LUMBER) ---@type integer 
    local goldCost     = ItemData[itm.id][ITEM_COST] * 100 * percentage + playerGold * percentage ---@type number 
    local lumberCost   = ItemData[itm.id][ITEM_COST] * 100 * percentage + playerLumber * percentage ---@type number 
    local platCost     = GetCurrency(pid, PLATINUM) * percentage ---@type number 
    local arcCost      = GetCurrency(pid, ARCADITE) * percentage ---@type number 
    local dw           = DialogWindow.create(pid, "", RechargeItem) ---@type DialogWindow 

    goldCost = goldCost + (platCost - R2I(platCost)) * 1000000
    lumberCost = lumberCost + (arcCost - R2I(arcCost)) * 1000000
    platCost = R2I(platCost)
    arcCost = R2I(arcCost)

    if platCost > 0 then
        message = message .. "\nRecharge cost:|n|cffffffff" .. RealToString(platCost) .. "|r |cffe3e2e2Platinum|r, |cffffffff" .. RealToString(goldCost) .. "|r |cffffcc00Gold|r|n"
    else
        message = message .. "\nRecharge cost:|n|cffffffff" .. RealToString(goldCost) .. " |cffffcc00Gold|r|n"
    end
    if arcCost > 0 then
        message = message .. "|cffffffff" .. RealToString(arcCost) .. "|r |cff66FF66Arcadite|r, |cffffffff" .. RealToString(lumberCost) .. "|r |cff472e2eLumber|r"
    else
        message = message .. "|cffffffff" .. RealToString(lumberCost) .. " |cff472e2eLumber|r"
    end

    dw.title = message

    if GetCurrency(pid, GOLD) >= goldCost and GetCurrency(pid, LUMBER) >= lumberCost and GetCurrency(pid, PLATINUM) >= platCost and GetCurrency(pid, ARCADITE) >= arcCost then
        dw:addButton("Recharge")
    end

    dw:display()
end

---@type fun(itm: Item)
function OnDropUpdate(itm)
    itm.x = GetItemX(itm.obj)
    itm.y = GetItemY(itm.obj)

    if itm.restricted and (IsItemOwned(itm.obj) == false) and (IsItemVisible(itm.obj) == true) then
        itm.restricted = false
    end
end

---@param pid integer
---@param itemid integer
function KillQuestHandler(pid, itemid)
    local index         = KillQuest[itemid][0] ---@type integer 
    local min           = KillQuest[index][KILLQUEST_MIN] ---@type integer 
    local max           = KillQuest[index][KILLQUEST_MAX] ---@type integer 
    local goal          = KillQuest[index][KILLQUEST_GOAL] ---@type integer 
    local playercount   = 0 ---@type integer 
    local U             = User.first ---@type User 
    local p             = Player(pid - 1) ---@type player 
    local avg           = R2I((max + min) * 0.5) ---@type integer 
    local x             = 0.
    local y             = 0.
    local myregion      = nil ---@type rect 

    if GetUnitLevel(Hero[pid]) < min then
        DisplayTimedTextToPlayer(p, 0,0, 10, "You must be level |cffffcc00" .. (min) .. "|r to begin this quest.")
    elseif GetUnitLevel(Hero[pid]) > max then
        DisplayTimedTextToPlayer(p, 0,0, 10, "You are too high level to do this quest.")
    --Progress
    elseif KillQuest[index][KILLQUEST_STATUS] == 1 then
        DisplayTimedTextToPlayer(p, 0,0, 10, "Killed " .. (KillQuest[index][KILLQUEST_COUNT]) .. "/" .. (goal) .. " " .. KillQuest[index][KILLQUEST_NAME])
        PingMinimap(GetRectCenterX(KillQuest[index][KILLQUEST_REGION]), GetRectCenterY(KillQuest[index][KILLQUEST_REGION]), 3)
    --Start Quest
    elseif KillQuest[index][KILLQUEST_STATUS] == 0 then
        KillQuest[index][KILLQUEST_STATUS] = 1
        DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00QUEST:|r Kill " .. (goal) .. " " .. KillQuest[index][KILLQUEST_NAME] .. " for a reward.")
        PingMinimap(GetRectCenterX(KillQuest[index][KILLQUEST_REGION]), GetRectCenterY(KillQuest[index][KILLQUEST_REGION]), 5)
    --Completion
    elseif KillQuest[index][KILLQUEST_STATUS] == 2 then
        while U do
            if HeroID[U.id] > 0 and GetUnitLevel(Hero[U.id]) >= min and GetUnitLevel(Hero[U.id]) <= max then
                playercount = playercount + 1
            end

            U = U.next
        end

        U = User.first

        while U do
            if GetHeroLevel(Hero[U.id]) >= min and GetHeroLevel(Hero[U.id]) <= max then
                DisplayTimedTextToPlayer(U.player, 0, 0, 10, "|c00c0c0c0" .. KillQuest[index][KILLQUEST_NAME] .. " quest completed!|r")
                local GOLD = RewardGold[avg] * goal / (0.5 + playercount * 0.5)
                AwardGold(U.id, GOLD, true)
                local XP = math.max(100, math.floor(Experience_Table[avg] * XP_Rate[U.id] * goal / 1800.))
                AwardXP(U.id, XP)
            end

            U = U.next
        end

        --reset
        KillQuest[index][KILLQUEST_STATUS] = 1
        KillQuest[index][KILLQUEST_COUNT] = 0
        KillQuest[index][KILLQUEST_GOAL] = IMinBJ(goal + 3, 100)

        --increase max spawns based on last unit killed (until max goal of 100 is reached)
        if (KillQuest[index][KILLQUEST_GOAL]) < 100 and ModuloInteger(KillQuest[index][KILLQUEST_GOAL], 2) == 0 then
            myregion = SelectGroupedRegion(UnitData[KillQuest[index][KILLQUEST_LAST]][UNITDATA_SPAWN])
            repeat
                x = GetRandomReal(GetRectMinX(myregion), GetRectMaxX(myregion))
                y = GetRandomReal(GetRectMinY(myregion), GetRectMaxY(myregion))
            until IsTerrainWalkable(x, y)
            CreateUnit(pfoe, KillQuest[index][KILLQUEST_LAST], x, y, GetRandomInt(0, 359))
            DisplayTimedTextToForce(FORCE_PLAYING, 20., "An additional " + GetObjectName(KillQuest[index][KILLQUEST_LAST]) + " has spawned in the area.")
        end
    end
end

---@type fun(u: unit, itm: item, limit: integer)
function StackItem(u, itm, limit)
    local pid    = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
    local slot   = GetItemSlot(itm, u) ---@type integer 

    local offset = (u == Backpack[pid]) and 6 or 0

    for i = 0, 5 do
        local itm2 = Profile[pid].hero.items[i + offset]

        if itm2.obj ~= itm and itm2.id == GetItemTypeId(itm) and itm2.charges < limit then
            itm2:charge(itm2.charges + 1)
            Profile[pid].hero.items[slot + offset] = nil
            Item[itm]:destroy()
            break
        end
    end
end

---@return boolean
function RewardItem()
    local pid    = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw     = DialogWindow[pid] ---@type DialogWindow 
    local index  = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        PlayerAddItemById(pid, dw.data[index])

        dw:destroy()
    end

    return false
end

---@return boolean
function BackpackUpgrades()
    local dw              = DialogWindow[GetPlayerId(GetTriggerPlayer()) + 1] ---@type DialogWindow 
    local id         = dw.data[0] ---@type integer 
    local price         = dw.data[1] ---@type integer 
    local index         = dw:getClickedIndex(GetClickedButton()) ---@type integer 
    local ablev         = 0 ---@type integer 

    if index ~= -1 then
        AddCurrency(dw.pid, GOLD, - ModuloInteger(price,1000000))
        AddCurrency(dw.pid, PLATINUM, - (price / 1000000))

        if id == FourCC('I101') then
            ablev = GetUnitAbilityLevel(Backpack[dw.pid], FourCC('A0FV'))
            SetUnitAbilityLevel(Backpack[dw.pid], FourCC('A0FV'), ablev + 1)
            SetUnitAbilityLevel(Backpack[dw.pid], FourCC('A02J'), ablev + 1)
            DisplayTimedTextToPlayer(Player(dw.pid - 1), 0, 0, 20, "You successfully upgraded to: Teleport [|cffffcc00Level " .. (ablev + 1) .. "|r]")
        elseif id == FourCC('I102') then
            ablev = GetUnitAbilityLevel(Backpack[dw.pid], FourCC('A0FK'))
            SetUnitAbilityLevel(Backpack[dw.pid], FourCC('A0FK'), ablev + 1)
            DisplayTimedTextToPlayer(Player(dw.pid - 1), 0, 0, 20, "You successfully upgraded to: Reveal [|cffffcc00Level " .. (ablev + 1) .. "|r]")
        end

        dw:destroy()
    end

    return false
end

---@return boolean
function SalvageItemConfirm()
    local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw              = DialogWindow[pid] ---@type DialogWindow 
    local itm      = dw.data[0] ---@type Item 
    local index         = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        AddCurrency(pid, GOLD, dw.data[1])
        AddCurrency(pid, PLATINUM, dw.data[2])

        DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 20, itm:name() .. " was successfully salvaged.")
        itm:destroy()

        dw:destroy()
    end

    return false
end

---@return boolean
function SalvageItem()
    local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw              = DialogWindow[pid] ---@type DialogWindow 
    local index         = dw:getClickedIndex(GetClickedButton()) ---@type integer 
    local goldCost         = 0 ---@type integer 
    local platCost         = 0 ---@type integer 
    local s        = "Salvaging yields: |n" ---@type string 
    local itm ---@type Item 

    if index ~= -1 then
        itm = dw.data[index]

        dw:destroy()

        if itm then
            goldCost = R2I(ModuloInteger(itm:calcStat(ITEM_COST, 0) * DISCOUNT_RATE, 1000000))
            platCost = R2I(itm:calcStat(ITEM_COST, 0) * DISCOUNT_RATE) // 1000000

            if platCost > 0 then
                s = s .. "|cffffffff" .. (platCost) .. "|r |cffe3e2e2Platinum|r|n"
            end

            if goldCost > 0 then
                s = s .. "|cffffffff" .. (goldCost) .. "|r |cffffcc00Gold|r|n"
            end

            dw = DialogWindow.create(pid, s, SalvageItemConfirm)
            dw.data[0] = itm
            dw.data[1] = goldCost
            dw.data[2] = platCost

            dw:addButton("Salvage")

            dw:display()
        end
    end

    return false
end

---@return boolean
function UpgradeItemConfirm()
    local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw              = DialogWindow[pid] ---@type DialogWindow 
    local itm      = Item(dw.data[0]) ---@type Item 
    local index         = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        AddCurrency(pid, GOLD, -dw.data[1])
        AddCurrency(pid, PLATINUM, -dw.data[2])
        AddCurrency(pid, CRYSTAL, -dw.data[3])

        itm:lvl(itm.level + 1)
        DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 20, "You successfully upgraded to: " .. itm:name())

        dw:destroy()
    end

    return false
end

---@return boolean
function UpgradeItem()
    local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw              = DialogWindow[pid] ---@type DialogWindow 
    local index         = dw:getClickedIndex(GetClickedButton()) ---@type integer 
    local goldCost         = 0 ---@type integer 
    local platCost         = 0 ---@type integer 
    local crystalCost         = 0 ---@type integer 
    local s        = "Upgrade cost: |n" ---@type string 
    local itm ---@type Item 

    if index ~= -1 then
        itm = dw.data[index]

        dw:destroy()

        if itm then
            goldCost = ModuloInteger(itm:calcStat(ITEM_COST, 0), 1000000)
            platCost = itm:calcStat(ITEM_COST, 0) // 1000000
            crystalCost = CRYSTAL_PRICE[itm.level]

            if platCost > 0 then
                s = s .. "|cffffffff" .. (platCost) .. "|r |cffe3e2e2Platinum|r|n"
            end

            if goldCost > 0 then
                s = s .. "|cffffffff" .. (goldCost) .. "|r |cffffcc00Gold|r|n"
            end

            if crystalCost > 0 then
                s = s .. "|cffffffff" .. (crystalCost) .. "|r |cff6969FFCrystals|r|n"
            end

            dw = DialogWindow.create(pid, s, UpgradeItemConfirm)
            dw.data[0] = itm
            dw.data[1] = goldCost
            dw.data[2] = platCost
            dw.data[3] = crystalCost

            if GetCurrency(pid, GOLD) >= goldCost and GetCurrency(pid, PLATINUM) >= platCost and GetCurrency(pid, CRYSTAL) >= crystalCost then
                dw:addButton("Upgrade")
            end

            dw:display()
        end
    end

    return false
end

---@return boolean
function PickupFilter()
    local u      = GetTriggerUnit() ---@type unit 
    local p      = GetOwningPlayer(u) ---@type player 
    local pid    = GetPlayerId(p) + 1 ---@type integer 
    local itm    = Item[GetManipulatedItem()] ---@type Item 
    local lvlreq = ItemData[itm.id][ITEM_LEVEL_REQUIREMENT] ---@type integer 
    local slot   = GetItemSlot(itm.obj, u)

    itm.holder = u

    --bind drop
    if IsItemBound(itm, pid) and (SAVE_TABLE.KEY_ITEMS[itm.id] or IsBindItem(itm.id)) then
        ITEM_DROP_FLAG[pid] = true
        DisplayTimedTextToPlayer(p, 0, 0, 30, "This item is bound to " .. User[itm.owner].nameColored .. ".")
    else
        if itm.holder == Hero[pid] then --hero
            --level requirements
            if lvlreq > GetHeroLevel(itm.holder) then
                ITEM_DROP_FLAG[pid] = true
                DisplayTimedTextToPlayer(p, 0, 0, 15., "This item requires at least level |c00FF5555" .. (lvlreq) .. "|r to equip.")

            --item limit restrictions
            elseif IsItemLimited(itm) then
                ITEM_DROP_FLAG[pid] = true
            end

            --bind on pickup
            if ITEM_DROP_FLAG[pid] == false then
                if SAVE_TABLE.KEY_ITEMS[itm.id] or IsBindItem(itm.id) then
                    itm.owner = p
                end
            end

            UpdateManaCosts(pid)

        elseif itm.holder == Backpack[pid] then --backpack
            --level requirements
            if lvlreq > GetHeroLevel(Hero[pid]) + 20 then
                ITEM_DROP_FLAG[pid] = true
                DisplayTimedTextToPlayer(p, 0, 0, 15., "This item requires at least level |c00FF5555" .. (lvlreq - 20) .. "|r to pick up.")
                itm.restricted = true
            elseif lvlreq > GetHeroLevel(Hero[pid]) then
                itm.restricted = true
            end

            BackpackLimit(itm.holder)

            slot = slot + 6
        end
    end

    if ITEM_DROP_FLAG[pid] then
        UnitRemoveItem(itm.holder, itm.obj)
    elseif BlzGetItemBooleanField(itm.obj, ITEM_BF_USE_AUTOMATICALLY_WHEN_ACQUIRED) == false then
        Profile[pid].hero.items[slot] = itm
    end

    return true
end

--event handler function for selling items
---@return boolean
function onSell()
    local itm      = GetManipulatedItem() ---@type item 

    Item[itm]:destroy()

    return false
end

--event handler function for buying items
function onBuy()
    local u      = GetTriggerUnit() ---@type unit 
    local b      = GetBuyingUnit() ---@type unit 
    local pid    = GetPlayerId(GetOwningPlayer(b)) + 1 ---@type integer 
    local myItem = GetSoldItem() ---@type item 
    local itm    = Item.create(myItem) ---@type Item 

    itm.owner = Player(pid - 1)

    if GetUnitTypeId(u) == FourCC('h002') then --naga chest
        TimerQueue:callDelayed(2.5, RemoveUnit, u)
        DestroyEffect(AddSpecialEffectTarget("UI\\Feedback\\GoldCredit\\GoldCredit.mdl", u, "origin"))
        Fade(u, 2., false)
    end
end

--event handler function for using items
function onUse()
    local u      = GetTriggerUnit() ---@type unit 
    local itm    = GetManipulatedItem() ---@type item 
    local p      = GetOwningPlayer(u) ---@type player 
    local itemid = GetItemTypeId(itm) ---@type integer 
    local pid    = GetPlayerId(p) + 1 ---@type integer 

    if u == Hero[pid] then --Potions (Hero)
        if itemid == FourCC('I0BJ') then
            HP(u, 10000)
        elseif itemid == FourCC('I028') then
            HP(u, 2000)
        elseif itemid == FourCC('I062') then
            HP(u, 500)
        elseif itemid == FourCC('I0BL') then
            MP(u, 10000)
        elseif itemid == FourCC('I00D') then
            MP(u, 2000)
        elseif itemid == FourCC('I06E') then
            MP(u, 500)
        elseif itemid == FourCC('I0MP') then
            HP(u, 50000 + BlzGetUnitMaxHP(u) * 0.08)
            MP(u, BlzGetUnitMaxMana(u) * 0.08)
        elseif itemid == FourCC('I0MQ') then
            HP(u, BlzGetUnitMaxHP(u) * 0.15)
        elseif itemid == FourCC('I02K') then --vampiric potion
            VampiricPotion:add(Hero[pid], Hero[pid]):duration(10.)
        end
    end
end

--event handler function for dropping items
function onDrop()
    local u      = GetTriggerUnit() ---@type unit 
    local myItem = GetManipulatedItem() ---@type item 
    local itm    = Item[myItem] ---@type Item 
    local pid    = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
    local slot   = GetItemSlot(myItem, u) ---@type integer 

    if slot >= 0 then --safety
        BlzFrameSetVisible(INVENTORYBACKDROP[slot], false)

        --update hero inventory
        if GetUnitTypeId(u) == BACKPACK then
            slot = slot + 6
        end

        Profile[pid].hero.items[slot] = nil
    end

    if not itm.restricted and u == Hero[pid] and ITEM_DROP_FLAG[pid] == false then
        itm:unequip()
    end

    TimerQueue:callDelayed(0., OnDropUpdate, itm)

    itm.holder = nil
end

--event handler function for picking up items
function onPickup()
    local u = GetTriggerUnit() ---@type unit 
    local itm = GetManipulatedItem() ---@type item? 
    local itemid = GetItemTypeId(itm) ---@type integer 
    local p = GetOwningPlayer(u) ---@type player 
    local pid = GetPlayerId(p) + 1 ---@type integer 
    local index = 0 ---@type integer 
    local i = 0 ---@type integer 
    local i2 = 0 ---@type integer 
    local levmin ---@type integer 
    local levmax ---@type integer 
    local x ---@type number 
    local y ---@type number 
    local U = User.first ---@type User 
    local itm2 = Item[itm] ---@type Item?

    --========================
    --Quests
    --========================

    --kill quests
    if KillQuest[itemid] and GetItemType(itm) == ITEM_TYPE_CAMPAIGN then
        FlashQuestDialogButton()
        KillQuestHandler(pid, itemid)
    --shopkeeper gossip
    elseif itemid == FourCC('I0OV') then
        x = GetUnitX(gg_unit_n01F_0576)
        y = GetUnitY(gg_unit_n01F_0576)

        if x > MAIN_MAP.maxX then --in tavern
            DisplayTextToForce(FORCE_PLAYING, "|cffffcc00Evil Shopkeeper's Brother:|r I don't know where he is.")
        else
            if x < MAIN_MAP.centerX and y > MAIN_MAP.centerY then
                ShopkeeperDirection[0] = "|cffffcc00North West|r"
            elseif x > MAIN_MAP.centerX and y > MAIN_MAP.centerY then
                ShopkeeperDirection[0] = "|cffffcc00North East|r"
            elseif x < MAIN_MAP.centerX and y < MAIN_MAP.centerY then
                ShopkeeperDirection[0] = "|cffffcc00South West|r"
            else
                ShopkeeperDirection[0] = "|cffffcc00South East|r"
            end

            ShopkeeperDirection[1] = "|cffffcc00Evil Shopkeeper's Brother:|r My brother is currently heading " .. ShopkeeperDirection[0] .. " to expand his business."
            ShopkeeperDirection[2] = "|cffffcc00Evil Shopkeeper's Brother:|r I last heard that he was spotted traveling " .. ShopkeeperDirection[0] .. " to negotiate with some suppliers."
            ShopkeeperDirection[3] = "|cffffcc00Evil Shopkeeper's Brother:|r My brother is rumored to have traveled " .. ShopkeeperDirection[0] .. " to seek new markets for his products."
            ShopkeeperDirection[4] = "|cffffcc00Evil Shopkeeper's Brother:|r I haven't seen him for a while, but I suspect he might be up " .. ShopkeeperDirection[0] .. " hunting for rare items to sell."
            ShopkeeperDirection[5] = "|cffffcc00Evil Shopkeeper's Brother:|r He is never in one place for too long. He's probably moved " .. ShopkeeperDirection[0] .. " by now."
            ShopkeeperDirection[6] = "|cffffcc00Evil Shopkeeper's Brother:|r If I had to guess, I'd say he is currently located in the " .. ShopkeeperDirection[0] .. " part of the city."
            ShopkeeperDirection[7] = "|cffffcc00Evil Shopkeeper's Brother:|r I'm not sure where he is, but he usually heads " .. ShopkeeperDirection[0] .. " when he wants to avoid trouble."
            ShopkeeperDirection[8] = "|cffffcc00Evil Shopkeeper's Brother:|r I heard that my brother is hiding to the " .. ShopkeeperDirection[0] .. " of town."
            ShopkeeperDirection[9] = "|cffffcc00Evil Shopkeeper's Brother:|r He often travels to the " .. ShopkeeperDirection[0] .. ", looking for new opportunities to make a profit."
            ShopkeeperDirection[10] = "|cffffcc00Evil Shopkeeper's Brother:|r He is always on the move. He could be anywhere, but my guess is he's headed due " .. ShopkeeperDirection[0] .. "."

            DisplayTextToForce(FORCE_PLAYING, ShopkeeperDirection[GetRandomInt(1, 10)])
        end
    --shopkeeper quest
    elseif itemid == FourCC('I08L') then
        if IsQuestDiscovered(Evil_Shopkeeper_Quest_1) == false then
            if GetUnitLevel(Hero[pid]) >= 50 then
                QuestSetDiscovered(Evil_Shopkeeper_Quest_1, true)
                QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_DISCOVERED, "|cff322ce1OPTIONAL QUEST|r|nThe Evil Shopkeeper")
            else
                DisplayTextToPlayer(p, 0, 0, "You must be at least level 50 to begin this quest.")
            end
        end
    --the horde quest
    elseif itemid == FourCC('I00L') then
        if GetUnitLevel(Hero[pid]) >= 100 then
            if IsQuestDiscovered(Defeat_The_Horde_Quest) == false then
                DestroyEffect(TalkToMe20)
                QuestSetDiscovered(Defeat_The_Horde_Quest, true)
                QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_DISCOVERED, "|cff322ce1OPTIONAL QUEST|r|nThe Horde")
                PingMinimap(12577, -15801, 4)
                PingMinimap(15645, -12309, 4)

                --orc setup
                SetUnitPosition(kroresh, 14665, -15352)
                UnitAddAbility(kroresh, FourCC('Avul'))

                --bottom side
                IssuePointOrder(CreateUnit(pboss, FourCC('o01I'), 12687, -15414, 45), "patrol", 668, -2146)
                IssuePointOrder(CreateUnit(pboss, FourCC('o01I'), 12866, -15589, 45), "patrol", 668, -2146)
                IssuePointOrder(CreateUnit(pboss, FourCC('o008'), 12539, -15589, 45), "patrol", 668, -2146)
                IssuePointOrder(CreateUnit(pboss, FourCC('o008'), 12744, -15765, 45), "patrol", 668, -2146)
                --top side
                IssuePointOrder(CreateUnit(pboss, FourCC('o01I'), 15048, -12603, 225), "patrol", 668, -2146)
                IssuePointOrder(CreateUnit(pboss, FourCC('o01I'), 15307, -12843, 225), "patrol", 668, -2146)
                IssuePointOrder(CreateUnit(pboss, FourCC('o008'), 15299, -12355, 225), "patrol", 668, -2146)
                IssuePointOrder(CreateUnit(pboss, FourCC('o008'), 15543, -12630, 225), "patrol", 668, -2146)

                TimerQueue:callPeriodically(30., IsQuestCompleted(Defeat_The_Horde_Quest), SpawnOrcs)
            elseif IsQuestCompleted(Defeat_The_Horde_Quest) == false then
                DisplayTextToPlayer(p, 0, 0, "Militia: The Orcs are still alive!")
            elseif IsQuestCompleted(Defeat_The_Horde_Quest) == true and not hordequest then
                DisplayTextToPlayer(p, 0, 0, "Militia: As promised, the Key of Valor.")
                Item.create(CreateItem(FourCC('I041'), -800, -865))
                hordequest = true
                DestroyEffect(TalkToMe20)
            end
        else
            DisplayTextToPlayer(p, 0, 0, "You must be level |cffffcc00" .. 100 .. "|r to begin this quest.")
        end
    --Headhunter
    --TODO rework head hunter?
    elseif HeadHunter[itemid] then

        if HeadHunter[itemid].Level <= GetHeroLevel(Hero[pid]) then
            local head = GetItemFromPlayer(pid, HeadHunter[itemid].Head):destroy()

            if head then
                head:destroy()
                PlayerAddItemById(pid, HeadHunter[itemid].Reward)

                local XP = HeadHunter[itemid].XP * XP_Rate[pid] * 0.01
                AwardXP(pid, XP)
            else
                DisplayTextToPlayer(p, 0, 0, "You do not have the head.")
            end
        else
            DisplayTextToPlayer(p, 0, 0, "You must be level |cffffcc00" .. (HeadHunter[itemid].Level) .. "|r to complete this quest.")
        end

    --========================
    --Dungeons
    --========================

    elseif itemid == DUNGEON_NAGA or itemid == DUNGEON_AZAZOTH then --queue dungeons
        QueueDungeon(pid, itemid)

    elseif itemid == FourCC('I0NM') then --naga reward
        if RectContainsCoords(gg_rct_Naga_Dungeon_Reward, GetUnitX(u), GetUnitY(u)) or RectContainsCoords(gg_rct_Naga_Dungeon_Boss, GetUnitX(u), GetUnitY(u)) then
            NagaReward()
        end

    elseif itemid == FourCC('I0JO') and ChaosMode == false then --god portal
        if god_portal ~= nil and TableHas(AZAZOTH_GROUP, p) == false then
            TableRemove(AZAZOTH_GROUP, p)

            BlzSetUnitFacingEx(Hero[pid], 45)
            SetUnitPosition(Hero[pid], GetRectCenterX(gg_rct_GodsEntrance), GetRectCenterY(gg_rct_GodsEntrance))
            reselect(Hero[pid])
            SetCameraBoundsRectForPlayerEx(p, gg_rct_GodsCameraBounds)
            PanCameraToTimedForPlayer(p, GetRectCenterX(gg_rct_GodsEntrance), GetRectCenterY(gg_rct_GodsEntrance), 0)

            if GodsEnterFlag == false then
                GodsEnterFlag = true
                DisplayTextToForce(FORCE_PLAYING, "This is your last chance to -flee.")

                DoTransmissionBasicsXYBJ(GetUnitTypeId(zeknen), GetPlayerColor(pboss), GetUnitX(zeknen), GetUnitY(zeknen), nil, "Zeknen", "Explain yourself or be struck down from this heaven!", 10)
                TimerQueue:callDelayed(10., ZeknenExpire)
            end
        end

    elseif itemid == FourCC('I0NO') and ChaosMode == false then --rescind to darkness
        if GodsEnterFlag == false and ChaosMode == false and GetHeroLevel(Hero[pid]) >= 240 then
            power_crystal = CreateUnitAtLoc(pfoe, FourCC('h04S'), Location(30000, -30000), bj_UNIT_FACING)
            KillUnit(power_crystal)
        end

    --========================
    --Buyables / Shops
    --========================

    elseif itemid == FourCC('I07Q') and donated[pid] == false then --donation
        ChargeNetworth(p, 0, 0.01, 100, "")
        donated[pid] = true
        donation = donation - donationrate
        DisplayTextToPlayer(p, 0, 0, "|c00408080The Goddesses bestow their blessings.")
        DisplayTextToForce(FORCE_PLAYING, "Reduced bad weather chance: " .. (R2I((1 - donation) * 100)) .. "\x25")
    elseif itemid == FourCC('I0M9') then --prestige
        if HasItemType(Hero[pid], FourCC('I0NN')) then
            if GetUnitLevel(Hero[pid]) >= 400 then
                ActivatePrestige(p)
            else
                DisplayTextToPlayer(p, 0, 0, "You are not level 400!")
            end
        else
            DisplayTextToPlayer(p, 0, 0, "You do not have a |cffffcc00Prestige Token|r!")
        end
    elseif itemid == FourCC('I0TS') and GetCurrency(pid, GOLD) >= 10000 then --str tome
        StatTome(pid, 10, 1, false)
    elseif itemid == FourCC('I0TA') and GetCurrency(pid, GOLD) >= 10000 then --agi tome
        StatTome(pid, 10, 2, false)
    elseif itemid == FourCC('I0TI') and GetCurrency(pid, GOLD) >= 10000 then --int tome
        StatTome(pid, 10, 3, false)
    elseif itemid == FourCC('I0TT') and GetCurrency(pid, GOLD) >= 20000 then --all stats
        StatTome(pid, 10, 4, false)
    elseif itemid == FourCC('I0OH') and GetCurrency(pid, PLATINUM) >= 1 then --str plat tome
        StatTome(pid, 1000, 1, true)
    elseif itemid == FourCC('I0OI') and GetCurrency(pid, PLATINUM) >= 1 then --agi plat tome
        StatTome(pid, 1000, 2, true)
    elseif itemid == FourCC('I0OK') and GetCurrency(pid, PLATINUM) >= 1 then --int plat tome
        StatTome(pid, 1000, 3, true)
    elseif itemid == FourCC('I0OJ') and GetCurrency(pid, PLATINUM) >= 2 then --all stats plat tome
        StatTome(pid, 1000, 4, true)
    elseif itemid == FourCC('I0N0') then --grimoire of focus
        i = 0
        if GetHeroStr(Hero[pid], false) - 50 > 20 then
            SetHeroStr(Hero[pid], GetHeroStr(Hero[pid], false) - 50, true)
            i = i + 5000
        elseif GetHeroStr(Hero[pid], false) >= 20 then
            SetHeroStr(Hero[pid], 20, true)
        end
        if GetHeroAgi(Hero[pid], false) - 50 > 20 then
            SetHeroAgi(Hero[pid], GetHeroAgi(Hero[pid], false) - 50, true)
            i = i + 5000
        elseif GetHeroAgi(Hero[pid], false) >= 20 then
            SetHeroAgi(Hero[pid], 20, true)
        end
        if GetHeroInt(Hero[pid], false) - 50 > 20 then
            SetHeroInt(Hero[pid], GetHeroInt(Hero[pid], false) - 50, true)
            i = i + 5000
        elseif GetHeroInt(Hero[pid], false) >= 20 then
            SetHeroInt(Hero[pid], 20, true)
        end
        if i > 0 then
            AddCurrency(pid, GOLD, i)
            DisplayTextToPlayer(p, 0, 0, "You have been refunded |cffffcc00" .. RealToString(i) .. "|r gold.")
        end
    elseif itemid == FourCC('I0JN') then --tome of retraining
        Item.create(UnitAddItemById(Hero[pid], FourCC('Iret')))
    elseif itemid == FourCC('I101') or itemid == FourCC('I102') then --upgrade teleports & reveal
        if itemid == FourCC('I101') then
            i = GetUnitAbilityLevel(Backpack[pid], FourCC('A02J'))
        elseif itemid == FourCC('I102') then
            i = GetUnitAbilityLevel(Backpack[pid], FourCC('A0FK'))
        end

        if i < 10 then --only 10 upgrades
            local dw ---@type DialogWindow
            index = R2I(400. * Pow(5., i - 1.))

            if index > 1000000 then
                dw = DialogWindow.create(pid, "Upgrade cost: |n|cffffffff" .. (index // 1000000) .. " |cffe3e2e2Platinum|r |cffffffffand " .. ModuloInteger(index, 1000000) .. " |cffffcc00Gold|r", BackpackUpgrades)
            else
                dw = DialogWindow.create(pid, "Upgrade cost: |n|cffffffff" .. (index) .. " |cffffcc00Gold|r", BackpackUpgrades)
            end

            if GetCurrency(pid, GOLD) >= ModuloInteger(index, 1000000) and GetCurrency(pid, PLATINUM) >= R2I(index / 1000000) then
                dw.data[0] = itemid
                dw.data[1] = index
                dw:addButton("Upgrade")
            end

            dw:display()
        end
    --upgrade (boss) items
    elseif itemid == FourCC('I100') then
        local dw = DialogWindow.create(pid, "Choose an item to upgrade.", UpgradeItem) ---@type DialogWindow

        index = 0
        while index < MAX_INVENTORY_SLOTS do
            itm2 = Profile[pid].hero.items[index]

            if itm2 and ItemData[itm2.id][ITEM_UPGRADE_MAX] > itm2.level then
                dw.data[dw.ButtonCount] = itm2
                dw:addButton(itm2:name())
            end

            index = index + 1
        end

        dw:display()
    --salvage (boss) items
    elseif itemid == FourCC('I01R') then
        local dw = DialogWindow.create(pid, "Choose an item to salvage.", SalvageItem) ---@type DialogWindow

        index = 0
        while index < MAX_INVENTORY_SLOTS do
            itm2 = Profile[pid].hero.items[index]

            if itm2 and ItemData[itm2.id][ITEM_COST] > 0 then
                dw.data[dw.ButtonCount] = itm2
                dw:addButton(itm2:name())
            end

            index = index + 1
        end

        dw:display()
    --currency exchange
    elseif itemid == FourCC('I04G') then
        if GetCurrency(pid, GOLD) >= 1000000 then
            AddCurrency(pid, PLATINUM, 1)
            AddCurrency(pid, GOLD, -1000000)
            ConversionEffect(pid)
            DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag + (GetCurrency(pid, PLATINUM)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 30, "|cffee0000You do not have a million gold to convert.")
        end
    elseif itemid == FourCC('I04H') then
        if GetCurrency(pid, LUMBER) >= 1000000 then
            AddCurrency(pid, ARCADITE, 1)
            AddCurrency(pid, LUMBER, -1000000)
            ConversionEffect(pid)
            DisplayTimedTextToPlayer(p, 0, 0, 20, ArcTag + (GetCurrency(pid, ARCADITE)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 30, "|cffee0000You do not have a million lumber to convert.")
        end
    elseif itemid == FourCC('I054') then
        if GetCurrency(pid, ARCADITE) >0 then
            ConversionEffect(pid)
            AddCurrency(pid, PLATINUM, 1)
            AddCurrency(pid, ARCADITE, -1)
            AddCurrency(pid, GOLD, 200000)
            DisplayTimedTextToPlayer(p, 0, 0, 20, ArcTag + (GetCurrency(pid, ARCADITE)))
            DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag + (GetCurrency(pid, PLATINUM)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff990000Unable to convert; not enough Arcadite Lumber.")
        end
    elseif itemid == FourCC('I053') then
        if GetCurrency(pid, PLATINUM) > 0 then
            ConversionEffect(pid)
            AddCurrency(pid, PLATINUM, -1)
            AddCurrency(pid, ARCADITE, 1)
            DisplayTimedTextToPlayer(p, 0, 0, 20, ArcTag + (GetCurrency(pid, ARCADITE)))
            DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag + (GetCurrency(pid, PLATINUM)))
        else
            AddCurrency(pid, GOLD, 350000)
            DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff990000Unable to convert; not enough Platinum Coins.")
        end
    elseif itemid == FourCC('I0PA') then
        if GetCurrency(pid, PLATINUM) >= 4 then
            ConversionEffect(pid)
            AddCurrency(pid, PLATINUM, -4)
            AddCurrency(pid, ARCADITE, 3)
            DisplayTimedTextToPlayer(p, 0, 0, 20, ArcTag + (GetCurrency(pid, ARCADITE)))
            DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag + (GetCurrency(pid, PLATINUM)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff990000Unable to convert; due to insufficient Platinum Coins.")
        end
    elseif itemid == FourCC('I051') then
        if GetCurrency(pid, ARCADITE) > 0 then
            ConversionEffect(pid)
            AddCurrency(pid, ARCADITE, -1)
            AddCurrency(pid, LUMBER, 1000000)
            DisplayTimedTextToPlayer(p, 0, 0, 20, ArcTag + (GetCurrency(pid, ARCADITE)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff990000Unable to convert; not enough Arcadite Lumber.")
        end
    elseif itemid == FourCC('I052') then
        if GetCurrency(pid, PLATINUM) >0 then
            ConversionEffect(pid)
            AddCurrency(pid, PLATINUM, -1)
            AddCurrency(pid, GOLD, 1000000)
            DisplayTimedTextToPlayer(p, 0, 0, 20, PlatTag + (GetCurrency(pid, PLATINUM)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "|cff990000Unable to convert; not enough Platinum Coins.")
        end
    elseif itemid == FourCC('I03R') then
        if GetCurrency(pid, LUMBER) >= 25000 then
            AddCurrency(pid, GOLD, 25000)
            AddCurrency(pid, LUMBER, -25000)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", u, "origin"))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need at least 25,000 lumber to buy this.")
        end
    elseif itemid == FourCC('I05C') then
        if GetCurrency(pid, GOLD) >= 32000 then
            AddCurrency(pid, LUMBER, 25000)
            AddCurrency(pid, GOLD, -32000)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", u, "origin"))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need at least 32,000 gold to buy this.")
        end
    --prestige token
    elseif itemid == FourCC('I05S') then
        if GetHeroLevel(Hero[pid]) < 400 then
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need level 400 to buy this.")
        else
            if GetCurrency(pid, CRYSTAL) >= 2500 then
                AddCurrency(pid, CRYSTAL, -2500)
                PlayerAddItemById(pid, FourCC('I0NN'))
            else
                DisplayTimedTextToPlayer(p, 0, 0, 20, "You need 2500 crystals to buy this.")
            end
        end
    --crystal to gold / platinum
    elseif itemid == FourCC('I0ME') then
        if GetCurrency(pid, CRYSTAL) >= 1 then
            AddCurrency(pid, CRYSTAL, -1)
            AddCurrency(pid, GOLD, 500000)
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need at least 1 crystal to buy this.")
        end
    --platinum to crystal
    elseif itemid == FourCC('I0MF') then
        if GetCurrency(pid, PLATINUM) >= 3 then
            AddCurrency(pid, PLATINUM, -3)
            AddCurrency(pid, CRYSTAL, 1)
            DisplayTimedTextToPlayer(p, 0, 0, 20, CrystalTag + (GetCurrency(pid, CRYSTAL)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 20, "You need at least 3 platinum to buy this.")
        end
    --chaos bases
    elseif itemid == FourCC('I05T') then --Satans Abode
        if GetUnitLevel(Hero[pid]) < 250 then
            DisplayTimedTextToPlayer(p, 0, 0, 15, "This item requires level 250 to use.")
        else
            BuyHome(u, 2, 1, FourCC('I001'))
        end
    elseif itemid == FourCC('I069') then --Demon Nation
        if GetUnitLevel(Hero[pid]) < 280 then
            DisplayTimedTextToPlayer(p, 0, 0, 15, "This item requires level 280 to use.")
        else
            BuyHome(u, 4, 2, FourCC('I068'))
        end
    --recharge reincarnation
    elseif itemid == FourCC('I0JS') then
        itm2 = GetResurrectionItem(pid, true)

        if itm2 and GetItemCharges(itm2.obj) >= MAX_REINCARNATION_CHARGES then
            itm2 = nil
        end

        if itm2 == nil then
            DisplayTimedTextToPlayer(p, 0, 0, 15, "You have no item to recharge!")
        elseif TimerGetRemaining(rezretimer[pid]) > 1 then
            DisplayTimedTextToPlayer(p, 0, 0,15, (R2I(TimerGetRemaining(rezretimer[pid]))) .. " seconds until you can recharge your " .. GetItemName(itm2.obj))
        else
            RechargeDialog(pid, itm2)
        end

    --========================
    --Quest Rewards
    --========================

    elseif itemid == FourCC('I08L') then -- Shopkeeper necklace
        Recipe(FourCC('I045'), 1, FourCC('item'), 0, FourCC('item'), 0, FourCC('item'), 0, FourCC('item'), 0, FourCC('item'), 0, FourCC('I03E'), 0, u, 0, 0, 0, false)
    elseif itemid == FourCC('I09H') then -- Omega Pick
        Recipe(FourCC('I02Y'), 1, FourCC('I02X'), 1, FourCC('item'), 0, FourCC('item'), 0, FourCC('item'), 0, FourCC('item'), 0, FourCC('I043'), 0, u, 0, 0, 0, false)
    elseif itemid == FourCC('I04M') then --Spider armor
        if GetHeroLevel(Hero[pid]) < 15 then
            DisplayTextToPlayer(p, 0, 0, "You must be level 15 to complete this quest.")
        elseif PlayerHasItemType(pid, FourCC('I01E')) then
            GetItemFromPlayer(pid, FourCC('I01E')):destroy()
            local dw = DialogWindow.create(pid, "Choose a reward", RewardItem) ---@type DialogWindow
            i2 = 0
            dw.cancellable = false

            while true do
                index = ItemRewards[FourCC('I04M')][i2]
                if index == 0  then break end
                Item.create(CreateItem(index, 30000., 30000.), 0.01) --load item data

                if HasProficiency(pid, PROF[ItemData[index][ITEM_TYPE]]) then
                    dw.data[dw.ButtonCount] = index
                    dw:addButton(GetObjectName(index) .. " [" .. TYPE_NAME[ItemData[index][ITEM_TYPE]] .. "]")
                end

                i2 = i2 + 1
            end

            dw:display()
        else
            DisplayTextToPlayer(p, 0, 0, "Nerubian head must be on your hero")
        end

    --========================
    --Item Stacking
    --========================

    --shop items
    elseif itemid == FourCC('I062') or itemid == FourCC('I028') or itemid == FourCC('I0BJ') or itemid == FourCC('I06E') or itemid == FourCC('I0BL') or itemid == FourCC('I00D') or itemid == FourCC('I00K') then
        StackItem(u, itm, 10)
    --empty flask, dragon bone, dragon heart, dragon scale, dragon potion, blood potion
    elseif itemid == FourCC('I0MO') or itemid == FourCC('I04X') or itemid == FourCC('I056') or itemid == FourCC('I05Z') or itemid == FourCC('I0MP') or itemid == FourCC('I0MQ') then
        StackItem(u, itm, 10)
    --vampiric potion
    elseif itemid == FourCC('I02K') then
        StackItem(u, itm, 3)
    --keys
    elseif itemid == FourCC('I040') or itemid == FourCC('I041') or itemid == FourCC('I042') then
        if Recipe(FourCC('I0M4'),1,FourCC('I041'),1,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('I0M7'),0,u,0,0,0, true) == true then
            QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_REQUIREMENT, "  - |cff808080Retrieve the Key of the Gods (Completed)|r")
        elseif Recipe(FourCC('I0M5'),1,FourCC('I042'),1,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('I0M7'),0,u,0,0,0, true) == true then
            QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_REQUIREMENT, "  - |cff808080Retrieve the Key of the Gods (Completed)|r")
        elseif Recipe(FourCC('I0M6'),1,FourCC('I040'),1,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('I0M7'),0,u,0,0,0, true) == true then
            QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_REQUIREMENT, "  - |cff808080Retrieve the Key of the Gods (Completed)|r")
        elseif Recipe(FourCC('I040'),1,FourCC('I041'),1,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('I0M5'),0,u,0,0,0, true) == true then
        elseif Recipe(FourCC('I041'),1,FourCC('I042'),1,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('I0M6'),0,u,0,0,0, true) == true then
        elseif Recipe(FourCC('I042'),1,FourCC('I040'),1,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('item'),0,FourCC('I0M4'),0,u,0,0,0, true) == true then
        end

    --=====================================
    --Colosseum / Struggle / Training / PVP
    --=====================================

    elseif itemid == FourCC('I0EV') or itemid == FourCC('I0EU') or itemid == FourCC('I0ET') or itemid == FourCC('I0ES') or itemid == FourCC('I0ER') or itemid == FourCC('I0EQ') or itemid == FourCC('I0EP') or itemid == FourCC('I0EO') then
        if ColoPlayerCount > 0 then
            DisplayTimedTextToPlayer(p, 0, 0, 5.00, "Colloseum is occupied!")
        else
            local ug = CreateGroup()
            GroupEnumUnitsInRect(ug, gg_rct_Colloseum_Enter, Condition(ischar))

            if (itemid == FourCC('I0EO')) or (itemid == FourCC('I0ES')) then
                if ChaosMode then
                    Wave = 103
                else
                    Wave = 0
                end
            elseif (itemid == FourCC('I0EP')) or (itemid == FourCC('I0ET')) then
                if ChaosMode then
                    Wave = 128
                else
                    Wave = 25
                end
            elseif (itemid == FourCC('I0EQ'))or(itemid == FourCC('I0EU')) then
                if ChaosMode then
                    Wave = 153
                else
                    Wave = 49
                end
            elseif (itemid == FourCC('I0ER'))or(itemid == FourCC('I0EV')) then
                if ChaosMode then
                    Wave = 182
                else
                    Wave = 73
                end
            end

            index = 0

            if (itemid == FourCC('I0ER') or itemid == FourCC('I0EQ') or itemid == FourCC('I0EP') or itemid == FourCC('I0EO')) then -- solo
                index = 1
            elseif (itemid == FourCC('I0EV') or itemid == FourCC('I0EU') or itemid == FourCC('I0ET') or itemid == FourCC('I0ES')) then -- team
                if BlzGroupGetSize(ug) > 1 then
                    index = 2
                else
                    DisplayTextToPlayer(p, 0, 0, "Atleast 2 players is required to play team survival.")
                end
            end

            if (itemid == FourCC('I0ER') or itemid == FourCC('I0EV')) and ChaosMode then
                i2 = 350
            end

            levmin = 500
            levmax = 0

            if index == 1 then
                --start colo solo
                if isteleporting[pid] == false then
                    ColoPlayerCount = 1
                    Colosseum_Monster_Amount = 0
                    ColoWaveCount = 0
                    InColo[pid] = true
                    GroupClear(ColoWaveGroup)
                    SetUnitPositionLoc(Hero[pid], ColosseumCenter)
                    SetCameraBoundsRectForPlayerEx(GetOwningPlayer(Hero[pid]), gg_rct_Colloseum_Camera_Bounds)
                    PanCameraToTimedLocForPlayer(GetOwningPlayer(Hero[pid]), ColosseumCenter, 0)
                    ExperienceControl(pid)
                    DisableItems(pid)
                    TimerQueue:callDelayed(2., AdvanceColo)
                end
            elseif index == 2 then
                i = 1
                while i <= 8 do
                    if IsUnitInGroup(Hero[i], ug) then
                        levmin = IMinBJ(GetHeroLevel(Hero[i]), levmin)
                        levmax = IMaxBJ(GetHeroLevel(Hero[i]), levmax)
                    end
                    i = i + 1
                end
                if levmin < i2 then
                    i = 1
                    while i <= 8 do
                        if IsUnitInGroup(Hero[i], ug) then
                            DisplayTextToPlayer(Player(i-1),0,0, "All players need level |cffffcc00" .. (i2) .. "|r to enter.")
                        end
                        i = i + 1
                    end
                elseif levmax - levmin > LEECH_CONSTANT then
                    i = 1
                    while i <= 8 do
                        if IsUnitInGroup(Hero[i], ug) then
                            DisplayTextToPlayer(Player(i-1),0,0, "Maximum level difference is |cffffcc0050|r levels.")
                        end
                        i = i + 1
                    end
                else
                    --start colo team
                    ColoPlayerCount = 0
                    Colosseum_Monster_Amount = 0
                    ColoWaveCount = 0
                    GroupClear(ColoWaveGroup)
                    while true do
                        u = FirstOfGroup(ug)
                        if u == nil then break end
                        pid = GetPlayerId(GetOwningPlayer(u)) + 1
                        GroupRemoveUnit(ug, u)
                        if u == Hero[pid] and isteleporting[pid] == false then
                            InColo[pid] = true
                            ColoPlayerCount = ColoPlayerCount + 1
                            Fleeing[pid] = false
                            SetUnitPositionLoc(u, ColosseumCenter)
                            SetCameraBoundsRectForPlayerEx(GetOwningPlayer(u), gg_rct_Colloseum_Camera_Bounds)
                            PanCameraToTimedLocForPlayer(GetOwningPlayer(u), ColosseumCenter, 0)
                            ExperienceControl(pid)
                            DisableItems(pid)
                        end
                    end
                    TimerQueue:callDelayed(2., AdvanceColo)
                end
            end

            DestroyGroup(ug)
        end

    elseif itemid == FourCC('I0EW') or itemid == FourCC('I00U') then --Struggle
        local ug = CreateGroup()
        GroupEnumUnitsInRect(ug, gg_rct_Colloseum_Enter, Condition(ischar))

        if Struggle_Pcount > 0 then
            GroupClear(ug)
            DisplayTextToPlayer(Player(pid-1),0,0, "Struggle is occupied.")
        elseif BlzGroupGetSize(ug) > 0 then
            levmin = 500
            levmax = 0

            while U do
                if IsUnitInGroup(Hero[U.id], ug) then
                    levmin = IMinBJ(GetHeroLevel(Hero[U.id]), levmin)
                    levmax = IMaxBJ(GetHeroLevel(Hero[U.id]), levmax)
                end
                U = U.next
            end
            if levmax - levmin > 80 then
                i = 1
                while i <= 8 do
                    if IsUnitInGroup(Hero[i], ug) then
                        DisplayTextToPlayer(Player(i-1),0,0, "Maximum level difference is |cffffcc0080|r levels.")
                    end
                    i = i + 1
                end
            else
                Struggle_Pcount = 0
                GoldWon_Struggle = 0
                while true do --start struggle
                    u = FirstOfGroup(ug)
                    if u == nil then break end
                    pid = GetPlayerId(GetOwningPlayer(u)) + 1
                    GroupRemoveUnit(ug, u)
                    if u == Hero[pid] and isteleporting[pid] == false then
                        InStruggle[pid] = true
                        Struggle_Pcount = Struggle_Pcount + 1
                        Fleeing[pid] = false
                        DisableItems(pid)
                        SetUnitPositionLoc(u, StruggleCenter)
                        CreateUnitAtLoc(GetOwningPlayer(u), FourCC('h065'), StruggleCenter, bj_UNIT_FACING)
                        SetCameraBoundsRectForPlayerEx(GetOwningPlayer(u), gg_rct_InfiniteStruggleCameraBounds)
                        PanCameraToTimedLocForPlayer(GetOwningPlayer(u), StruggleCenter, 0)
                        ExperienceControl(pid)
                        DisplayTimedTextToPlayer(GetOwningPlayer(u), 0, 0, 15., "You have 15 seconds to build before enemies spawn.")
                    end
                end
                if itemid == FourCC('I0EW') then --regular struggle
                    Struggle_WaveN = 0
                    if levmin > 120 then
                        Struggle_WaveN = 14
                    elseif levmin > 90 then
                        Struggle_WaveN = 11
                    elseif levmin > 60 then
                        Struggle_WaveN = 8
                    elseif levmin > 30 then
                        Struggle_WaveN = 5
                    end
                    Struggle_WaveUCN = Struggle_WaveUN[Struggle_WaveN]
                else --chaos struggle
                    Struggle_WaveN = 28
                    Struggle_WaveUCN = Struggle_WaveUN[Struggle_WaveN]
                end
                GroupClear(StruggleWaveGroup)
                TimerQueue:callDelayed(12., AdvanceStruggle, 1)
            end
        end

        DestroyGroup(ug)
    elseif itemid == FourCC('I0MT') then --Enter Training
        if GetHeroLevel(Hero[pid]) < 160 then --prechaos
            x = GetRandomReal(GetRectMinX(gg_rct_PrechaosTraining), GetRectMaxX(gg_rct_PrechaosTraining))
            y = GetRandomReal(GetRectMinY(gg_rct_PrechaosTraining), GetRectMaxY(gg_rct_PrechaosTraining))
            SetCameraBoundsRectForPlayerEx(p, gg_rct_PrechaosTraining)

            if GetLocalPlayer() == p then
                PanCameraToTimed(GetRectCenterX(gg_rct_PrechaosTraining), GetRectCenterY(gg_rct_PrechaosTraining), 0)
                ClearSelection()
                SelectUnit(Hero[pid], true)
            end
        else --chaos
            x = GetRandomReal(GetRectMinX(gg_rct_ChaosTraining), GetRectMaxX(gg_rct_ChaosTraining))
            y = GetRandomReal(GetRectMinY(gg_rct_ChaosTraining), GetRectMaxY(gg_rct_ChaosTraining))
            SetCameraBoundsRectForPlayerEx(p, gg_rct_ChaosTraining)

            if GetLocalPlayer() == p then
                PanCameraToTimed(GetRectCenterX(gg_rct_ChaosTraining), GetRectCenterY(gg_rct_ChaosTraining), 0)
                ClearSelection()
                SelectUnit(Hero[pid], true)
            end
        end

        SetUnitPosition(Hero[pid], x, y)

    elseif itemid == FourCC('I0MW') then --Exit Training
        if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            local ug = CreateGroup()
            GroupEnumUnitsInRect(ug, gg_rct_PrechaosTrainingSpawn, Condition(ishostile))

            if FirstOfGroup(ug) == nil then
                SetUnitPosition(Hero[pid], -1332, 2918)
                if GetLocalPlayer() == p then
                    SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
                    PanCameraToTimed(-1332, 2918, 0)
                    ClearSelection()
                    SelectUnit(Hero[pid], true)
                end
            else
                DisplayTextToPlayer(p, 0, 0, "You must kill all enemies before leaving!")
            end

            DestroyGroup(ug)
        elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            local ug = CreateGroup()
            GroupEnumUnitsInRect(ug, gg_rct_ChaosTrainingSpawn, Condition(ishostile))

            if FirstOfGroup(ug) == nil then
                SetUnitPosition(Hero[pid], -1332, 2918)
                if GetLocalPlayer() == p then
                    SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
                    PanCameraToTimed(-1332, 2918, 0)
                    ClearSelection()
                    SelectUnit(Hero[pid], true)
                end
            else
                DisplayTextToPlayer(p, 0, 0, "You must kill all enemies before leaving!")
            end

            DestroyGroup(ug)
        end

    elseif itemid == FourCC('I0MS') then --Training Prechaos
        CreateUnit(pfoe, UnitData[0][TrainerSpawn], GetRandomReal(GetRectMinX(gg_rct_PrechaosTraining), GetRectMaxX(gg_rct_PrechaosTraining)), GetRandomReal(GetRectMinY(gg_rct_PrechaosTraining), GetRectMaxY(gg_rct_PrechaosTraining)), GetRandomReal(0,359))

    elseif itemid == FourCC('I0MX') then --Training Chaos
        CreateUnit(pfoe, UnitData[1][TrainerSpawnChaos], GetRandomReal(GetRectMinX(gg_rct_ChaosTraining), GetRectMaxX(gg_rct_ChaosTraining)), GetRandomReal(GetRectMinY(gg_rct_ChaosTraining), GetRectMaxY(gg_rct_ChaosTraining)), GetRandomReal(0,359))

    elseif itemid == FourCC('I0MU') then --Increase Difficulty
        if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            itm = GetItemFromUnit(gg_unit_h001_0072, FourCC('I0MY'))
            TrainerSpawn = TrainerSpawn + 1
            if UnitData[0][TrainerSpawn] == 0 then
                TrainerSpawn = TrainerSpawn - 1
            end
            BlzSetItemIconPath(itm, "|cffffcc00" .. GetObjectName(UnitData[0][TrainerSpawn]) .. "|r")
        elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            itm = GetItemFromUnit(gg_unit_h000_0120, FourCC('I0MZ'))
            TrainerSpawnChaos = TrainerSpawnChaos + 1
            if UnitData[1][TrainerSpawnChaos] == 0 then
                TrainerSpawnChaos = TrainerSpawnChaos - 1
            end
            BlzSetItemIconPath(itm, "|cffffcc00" .. GetObjectName(UnitData[1][TrainerSpawnChaos]) .. "|r")
        end

    elseif itemid == FourCC('I0MV') then --Decrease Difficulty
        if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            itm = GetItemFromUnit(gg_unit_h001_0072, FourCC('I0MY'))
            TrainerSpawn = IMaxBJ(0, TrainerSpawn - 1)
            BlzSetItemIconPath(itm, "|cffffcc00" .. GetObjectName(UnitData[0][TrainerSpawn]) .. "|r")
        elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            itm = GetItemFromUnit(gg_unit_h000_0120, FourCC('I0MZ'))
            TrainerSpawnChaos = IMaxBJ(0, TrainerSpawnChaos - 1)
            BlzSetItemIconPath(itm, "|cffffcc00" .. GetObjectName(UnitData[1][TrainerSpawnChaos]) .. "|r")
        end
    elseif itemid == FourCC('PVPA') then --Enter PVP
        local dw = DialogWindow.create(pid, "Choose an arena.", EnterPVP) ---@type DialogWindow

        dw:addButton("Wastelands [FFA]")
        dw:addButton("Pandaren Forest [Duel]")
        dw:addButton("Ice Cavern [Duel]")

        dw:display()
    --item is present in inventory
    elseif itm2 then
        if not itm2.restricted then
            if u == Hero[pid] and ITEM_DROP_FLAG[pid] == false then --heroes
                itm2:equip()
                if GetLocalPlayer() == p then
                    BlzFrameSetTexture(INVENTORYBACKDROP[GetEmptySlot(u)], SPRITE_RARITY[itm2.level], 0, true)
                end
            end

            --add item spells after a delay (required for each equip)
            TimerQueue:callDelayed(0., ItemAddSpellDelayed, itm2)
        end
    end

    ITEM_DROP_FLAG[pid] = false
end

    local onpickup  = CreateTrigger() ---@type trigger 
    local ondrop    = CreateTrigger() ---@type trigger 
    local useitem   = CreateTrigger() ---@type trigger 
    local onbuy     = CreateTrigger() ---@type trigger 
    local onsell    = CreateTrigger() ---@type trigger 
    local u         = User.first ---@type User 

    while u do
        rezretimer[u.id] = CreateTimer()
        TriggerRegisterPlayerUnitEvent(onpickup, u.player, EVENT_PLAYER_UNIT_PICKUP_ITEM, nil)
        TriggerRegisterPlayerUnitEvent(ondrop, u.player, EVENT_PLAYER_UNIT_DROP_ITEM, nil)
        TriggerRegisterPlayerUnitEvent(useitem, u.player, EVENT_PLAYER_UNIT_USE_ITEM, nil)
        TriggerRegisterPlayerUnitEvent(onsell, u.player, EVENT_PLAYER_UNIT_PAWN_ITEM, nil)
        u = u.next
    end

    --TODO ashenvat
    --TriggerRegisterUnitEvent(ondrop, ASHEN_VAT, EVENT_UNIT_DROP_ITEM)
    TriggerRegisterPlayerUnitEvent(onbuy, Player(PLAYER_NEUTRAL_PASSIVE), EVENT_PLAYER_UNIT_SELL_ITEM, nil)

    TriggerAddCondition(onpickup, Condition(PickupFilter))
    TriggerAddAction(onpickup, onPickup)
    TriggerAddAction(ondrop, onDrop)
    TriggerAddAction(useitem, onUse)
    TriggerAddAction(onbuy, onBuy)
    TriggerAddCondition(onsell, Condition(onSell))
end)

if Debug then Debug.endFile() end
