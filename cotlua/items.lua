if Debug then Debug.beginFile 'Items' end

--[[
    items.lua

    A library that handles item related events
        (EVENT_PLAYER_UNIT_PICKUP_ITEM
        EVENT_PLAYER_UNIT_DROP_ITEM
        EVENT_PLAYER_UNIT_USE_ITEM
        EVENT_PLAYER_UNIT_PAWN_ITEM
        EVENT_PLAYER_UNIT_SELL_ITEM)
    and also defines the Item struct for better OO item handling.

    Future consideration: Migrate unit drop tables elsewhere?
]]

OnInit.final("Items", function(require)
    require 'Users'
    require 'Variables'

    hordequest        = false
    CHURCH_DONATION   = {} ---@type boolean[] 
    rezretimer        = {} ---@type timer[] 
    ITEM_DROP_FLAG    = {} ---@type boolean[] 
    ItemsDisabled     = {} ---@type boolean[] 

    ItemDrops = array2d(0)
    Rates     = __jarray(0)

    MAX_ITEM_COUNT = 100
    ADJUST_RATE = 0.05 --percent
    DISCOUNT_RATE = 0.25

    POTIONS = {
        --hp potions
        [FourCC('A09C')] = {
            [FourCC("HPOT")] = function(pid, pot) ---@type fun(pid: integer, pot: Item)
                HP(Hero[pid], Hero[pid], pot:getValue(ITEM_ABILITY, 0), pot:name())
                pot:consumeCharge()
            end,
            [FourCC("DBPT")] = function(pid, pot)
                HP(Hero[pid], Hero[pid], pot:getValue(ITEM_ABILITY, 0) + BlzGetUnitMaxHP(Hero[pid]) * 0.01 * ItemData[pot.id][ITEM_ABILITY * ABILITY_OFFSET + 1], pot:name())
                MP(Hero[pid], BlzGetUnitMaxMana(Hero[pid]) * 0.01 * ItemData[pot.id][ITEM_ABILITY * ABILITY_OFFSET + 1])
                pot:consumeCharge()
            end,
        },
        --mana potions
        [FourCC('A0FS')] = {
            [FourCC("MPOT")] = function(pid, pot)
                MP(Hero[pid], pot:getValue(ITEM_ABILITY, 0))
                pot:consumeCharge()
            end,
            [FourCC("DBPT")] = function(pid, pot)
                HP(Hero[pid], Hero[pid], pot:getValue(ITEM_ABILITY, 0) + BlzGetUnitMaxHP(Hero[pid]) * 0.01 * ItemData[pot.id][ITEM_ABILITY * ABILITY_OFFSET + 1], pot:name())
                MP(Hero[pid], BlzGetUnitMaxMana(Hero[pid]) * 0.01 * ItemData[pot.id][ITEM_ABILITY * ABILITY_OFFSET + 1])
                pot:consumeCharge()
            end,
        },
        --unique potions
        [FourCC('A05N')] = {
            [FourCC('A002')] = function(pid, pot)
                VampiricPotion:add(Hero[pid], Hero[pid]):duration(10.)
                pot:consumeCharge()
            end,
            [FourCC('A00V')] = function(pid, pot)
                Dummy.create(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), FourCC('A05P'), 1):cast(Player(pid - 1), "invisibility", Hero[pid])
                pot:consumeCharge()
            end,
        },
    }

    ---@class Item
    ---@field obj item
    ---@field holder unit
    ---@field trig trigger
    ---@field lvl function
    ---@field level integer
    ---@field id integer
    ---@field charges integer
    ---@field x number
    ---@field y number
    ---@field quality integer[]
    ---@field eval conditionfunc
    ---@field consumeCharge function
    ---@field getValue function
    ---@field equip function
    ---@field unequip function
    ---@field update function
    ---@field encode function
    ---@field encode_id function
    ---@field decode function
    ---@field expire function
    ---@field onDeath function
    ---@field name string
    ---@field restricted boolean
    ---@field create function
    ---@field destroy function
    ---@field owner player
    ---@field sfx effect
    ---@field tooltip string
    ---@field alt_tooltip string
    ---@field stack function
    ---@field equipped boolean
    ---@field spawn integer
    Item = {} ---@type Item|Item[]
    do
        local thistype = Item
        thistype.eval = Condition(thistype.onDeath)

        setmetatable(Item, {
            --create new Item object for item if not available
            __index = function(tbl, key)
                if type(key) == "userdata" then
                    local self = Item.create(key)

                    return self
                end
            end,
            --weak table for item (userdata) keys
            __mode = 'k'
        })

        --object inheritance and method operators
        local mt = {
                __index = function(tbl, key)
                    return (rawget(Item, key) or rawget(tbl.proxy, key))
                end,
                __newindex = function(tbl, key, value)
                    if key == "restricted" then
                        tbl:restrict(value)
                        rawset(tbl.proxy, key, value)
                    elseif key == "charges" then
                        SetItemCharges(tbl.obj, value)
                        rawset(tbl.proxy, key, value)
                    else
                        rawset(tbl, key, value)
                    end
                end,
            }

        ---@type fun(itm: item, expire: number?): Item
        function thistype.create(itm, expire)
            local self = {
                obj = itm,
                id = GetItemTypeId(itm),
                level = 0,
                trig = CreateTrigger(),
                x = GetItemX(itm),
                y = GetItemY(itm),
                quality = __jarray(0),
                owner = nil,
                equipped = false,
                proxy = {
                    charges = math.max(1, GetItemCharges(itm)),
                    restricted = false,
                },
            }

            rawset(Item, itm, self)
            setmetatable(self, mt)

            --first time setup
            if ItemData[self.id][ITEM_TOOLTIP] == 0 then
                --if an item's description exists, use that for parsing (exception for default shops)
                ParseItemTooltip(self.obj, (StringLength(BlzGetItemDescription(self.obj)) > 1 and BlzGetItemDescription(self.obj)) or "")
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
                if ItemData[self.id][i .. "range"] ~= 0 then
                    self.quality[count] = GetRandomInt(0, 63)
                    count = count + 1
                end

                if count >= QUALITY_SAVED then break end
            end

            if ItemData[self.id][ITEM_TIER] ~= 0 then
                self:update()
            end

            Item[self.obj] = self

            return self
        end

        local backpack_allowed = {
            [FourCC('A0E2')] = 1, --sea ward
            [FourCC('A0D3')] = 1, --jewel of the horde
            [FourCC('AIcd')] = 1, --command aura (warsong battle drums)
            [FourCC('A03F')] = 1, --endurance aura (blood elf war drums)
            [FourCC('A018')] = 1, --drum of war
            [FourCC('A03H')] = 1, --blood shield (vampiric aura)
            [FourCC('A03G')] = 1, --blood horn (unholy aura)
        }

            ---@type fun(itm: Item)
        local function ItemAddSpellDelayed(itm)
            for index = ITEM_ABILITY, ITEM_ABILITY2 do
                local abilid = ItemData[itm.id][index * ABILITY_OFFSET]

                --don't add ability if backpack is not allowed
                if GetUnitTypeId(itm.holder) == BACKPACK and not backpack_allowed[abilid] then
                    abilid = 0
                end

                if abilid ~= 0 then --ability exists
                    BlzItemAddAbility(itm.obj, abilid)

                    if abilid == FourCC('Aarm') then --armor aura
                        BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_ARMOR_BONUS_HAD1, 0, itm:getValue(index, 0))
                    elseif abilid == FourCC('Abas') then --bash
                        BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_CHANCE_TO_BASH, 0, itm:getValue(index, 0))
                        BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_DURATION_NORMAL, 0, ItemData[itm.id][index * ABILITY_OFFSET + 1])
                        BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_DURATION_HERO, 0, ItemData[itm.id][index * ABILITY_OFFSET + 1])
                    elseif abilid == FourCC('A018') or abilid == FourCC('A01S') then --blink
                        BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_MAXIMUM_RANGE, 0, itm:getValue(index, 0))
                    elseif abilid == FourCC('A00D') then --thanatos wings
                        local tbl = ItemData[itm.id].sfx[itm:getValue(index, 0)]

                        DestroyEffect(itm.sfx)
                        itm.sfx = AddSpecialEffectTarget(tbl.path, itm.holder, tbl.attach)
                    elseif abilid == FourCC('HPOT') then --healing potion
                        BlzSetAbilityIntegerLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_ILF_HIT_POINTS_GAINED_IHPG, 0, itm:getValue(index, 0))
                    elseif abilid == FourCC('Areg') then --resurgence (chaos shield)
                        TimerQueue:callDelayed(0.5, ChaosShieldRegen, itm)
                    else --channel
                        BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), SPELL_FIELD[0], 0, itm:getValue(index, 0))

                        for i = 0, SPELL_FIELD_TOTAL do
                            local count = 1
                            local value = ItemData[itm.id][index * ABILITY_OFFSET + count]

                            if value ~= 0 then
                                BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), SPELL_FIELD[i], 0, value)
                                count = count + 1
                            end
                        end
                    end

                    IncUnitAbilityLevel(itm.holder, abilid)
                    DecUnitAbilityLevel(itm.holder, abilid)
                end
            end
        end

        --Called on equip to stack with an existing item if possible and applicable
        ---@type fun(self: Item, pid: integer, limit: integer): boolean
        function thistype:stack(pid, limit)
            local offset = (self.holder == Backpack[pid] and 6) or 0
            local range = (fullItemStacking[pid] == true and {0, MAX_INVENTORY_SLOTS - 1}) or {offset, offset + 5}

            for i = range[1], range[2] do
                local match = Profile[pid].hero.items[i]

                if match and match ~= self and match.id == self.id and match.charges < limit then
                    local total = match.charges + self.charges
                    local diff = limit - match.charges

                    if total <= limit then
                        match.charges = total
                        self:destroy()
                        self = match
                    else
                        match.charges = limit
                        self.charges = self.charges - diff
                    end
                    return true
                end
            end

            return false
        end

        --Adjusts name in tooltip if an item is useable or not
        ---@type fun(self: Item, flag: boolean)
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
        ---@type fun(self: Item):string
        function thistype:name()
            local s = GetObjectName(self.id)

            if self.level > 0 then
                s = LEVEL_PREFIX[self.level] .. " " .. s .. " +" .. self.level
            end

            return s
        end

        function thistype:lvl(lvl)
            if ItemData[self.id][ITEM_UPGRADE_MAX] > 0 then
                self:unequip()
                self.level = lvl
                self:update()
                self:equip()
            end
        end

        function thistype:consumeCharge()
            if self.charges > 1 then
                self.charges = self.charges - 1
            else
                self:destroy()
            end
        end

        ---@type fun(self: Item, STAT: integer, flag: integer):integer
        function thistype:getValue(STAT, flag)
            local unlockat = ItemData[self.id][STAT .. "unlock"] ---@type integer 

            if self.level < unlockat then
                return 0
            end

            local flatPerLevel  = ItemData[self.id][STAT .. "fpl"] ---@type integer 
            local flatPerRarity = ItemData[self.id][STAT .. "fpr"] ---@type integer 
            local percent       = ItemData[self.id][STAT .. "percent"] ---@type integer 
            local fixed         = ItemData[self.id][STAT .. "fixed"] ---@type integer 
            local lower         = ItemData[self.id][STAT]  ---@type number 
            local upper         = ItemData[self.id][STAT .. "range"]  ---@type number 
            local hasVariance   = (upper ~= 0) ---@type boolean 
            local pmult         = (percent ~= 0 and percent * 0.01) or 1 ---@type number

            --calculate values after applying affixes
            lower = lower + ((flatPerLevel * self.level + flatPerRarity * (IMaxBJ(self.level - 1, 0) // 4)) * pmult)
            upper = upper + ((flatPerLevel * self.level + flatPerRarity * (IMaxBJ(self.level - 1, 0) // 4)) * pmult)

            --values are not fixed
            if fixed == 0 then
                lower = lower + lower * ITEM_MULT[self.level] * pmult
                upper = upper + upper * ITEM_MULT[self.level] * pmult
            end

            if flag == 1 then
                return R2I(lower)
            elseif flag == 2 then
                return R2I(upper)
            else
                local final = 0

                if hasVariance then
                    local count = 0

                    --find the quality index
                    for index = 0, STAT - 1 do
                        if ItemData[self.id][index .. "range"] ~= 0 then
                            count = count + 1
                        end
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
            if self.holder == nil then
                return
            end

            local pid  = GetPlayerId(GetOwningPlayer(self.holder)) + 1 ---@type integer 
            local hp   = GetWidgetLife(self.holder) ---@type number 
            local mana = GetUnitState(self.holder, UNIT_STATE_MANA) ---@type number 
            local mod  = ItemProfMod(self.id, pid) ---@type number 

            --if item is stackable
            local stack = self:getValue(ITEM_STACK, 0)

            if stack > 1 then
                self:stack(pid, stack)
            end

            --add item abilities after a delay (required for each equip)
            TimerQueue:callDelayed(0., ItemAddSpellDelayed, self)

            if self.holder == Hero[pid] then --exclude backpack
                self.equipped = true

                UnitAddBonus(self.holder, BONUS_ARMOR, R2I(mod * self:getValue(ITEM_ARMOR, 0)))
                UnitAddBonus(self.holder, BONUS_DAMAGE, R2I(mod * self:getValue(ITEM_DAMAGE, 0)))
                UnitAddBonus(self.holder, BONUS_HERO_STR, R2I(mod * self:getValue(ITEM_STRENGTH, 0)))
                UnitAddBonus(self.holder, BONUS_HERO_AGI, R2I(mod * self:getValue(ITEM_AGILITY, 0)))
                UnitAddBonus(self.holder, BONUS_HERO_INT, R2I(mod * self:getValue(ITEM_INTELLIGENCE, 0)))
                BlzSetUnitMaxHP(self.holder, BlzGetUnitMaxHP(self.holder) + R2I(mod * self:getValue(ITEM_HEALTH, 0)))
                BlzSetUnitMaxMana(self.holder, BlzGetUnitMaxMana(self.holder) + R2I(mod * self:getValue(ITEM_MANA, 0)))
                SetWidgetLife(self.holder, hp)
                SetUnitState(self.holder, UNIT_STATE_MANA, mana)

                ItemMovespeed[pid] = ItemMovespeed[pid] + self:getValue(ITEM_MOVESPEED, 0)
                ItemGoldRate[pid] = ItemGoldRate[pid] + self:getValue(ITEM_GOLD_GAIN, 0)
                BoostValue[pid] = BoostValue[pid] + self:getValue(ITEM_SPELLBOOST, 0) * 0.01
                Unit[self.holder].regen = Unit[self.holder].regen + self:getValue(ITEM_REGENERATION, 0)
                Unit[self.holder].evasion = Unit[self.holder].evasion + self:getValue(ITEM_EVASION, 0)
                Unit[self.holder].mr = Unit[self.holder].mr * (1 - self:getValue(ITEM_MAGIC_RESIST, 0) * 0.01)
                Unit[self.holder].dr = Unit[self.holder].dr * (1 - self:getValue(ITEM_DAMAGE_RESIST, 0) * 0.01)
                BlzSetUnitAttackCooldown(self.holder, BlzGetUnitAttackCooldown(self.holder, 0) / (1. + self:getValue(ITEM_BASE_ATTACK_SPEED, 0) * 0.01), 0)

                --shield
                if ItemData[self.id][ITEM_TYPE] == 5 then
                    ShieldCount[pid] = ShieldCount[pid] + 1
                end

                --profiency warning
                if GetUnitLevel(self.holder) < 15 and mod < 1 then
                    DisplayTimedTextToPlayer(self.owner, 0, 0, 10, "You lack the proficiency (-pf) to use this item, it will only give 75\x25 of most stats.\n|cffFF0000You will stop getting this warning at level 15.|r")
                end
            end
        end

        function thistype:unequip()
            if self.holder == nil then
                return
            end

            local pid  = GetPlayerId(GetOwningPlayer(self.holder)) + 1 ---@type integer 
            local hp   = GetWidgetLife(self.holder) ---@type number 
            local mana = GetUnitState(self.holder, UNIT_STATE_MANA) ---@type number 
            local mod  = ItemProfMod(self.id, pid) ---@type number 

            --don't remove abilities from consumables (otherwise they stop working properly)
            if GetItemType(self.obj) ~= ITEM_TYPE_CHARGED then
                for index = ITEM_ABILITY, ITEM_ABILITY2 do
                    local abilid = ItemData[self.id][index * ABILITY_OFFSET]
                    BlzItemRemoveAbility(self.obj, abilid)
                end
            end

            if self.holder == Hero[pid] then --exclude backpack
                self.equipped = false

                UnitAddBonus(self.holder, BONUS_ARMOR, -R2I(mod * self:getValue(ITEM_ARMOR, 0)))
                UnitAddBonus(self.holder, BONUS_DAMAGE, -R2I(mod * self:getValue(ITEM_DAMAGE, 0)))
                UnitAddBonus(self.holder, BONUS_HERO_STR, -R2I(mod * self:getValue(ITEM_STRENGTH, 0)))
                UnitAddBonus(self.holder, BONUS_HERO_AGI, -R2I(mod * self:getValue(ITEM_AGILITY, 0)))
                UnitAddBonus(self.holder, BONUS_HERO_INT, -R2I(mod * self:getValue(ITEM_INTELLIGENCE, 0)))
                BlzSetUnitMaxHP(self.holder, BlzGetUnitMaxHP(self.holder) - R2I(mod * self:getValue(ITEM_HEALTH, 0)))
                BlzSetUnitMaxMana(self.holder, BlzGetUnitMaxMana(self.holder) - R2I(mod * self:getValue(ITEM_MANA, 0)))
                SetWidgetLife(self.holder, math.max(hp, 1))
                SetUnitState(self.holder, UNIT_STATE_MANA, mana)

                ItemMovespeed[pid] = ItemMovespeed[pid] - self:getValue(ITEM_MOVESPEED, 0)
                ItemGoldRate[pid] = ItemGoldRate[pid] - self:getValue(ITEM_GOLD_GAIN, 0)
                BoostValue[pid] = BoostValue[pid] - self:getValue(ITEM_SPELLBOOST, 0) * 0.01
                Unit[self.holder].regen = Unit[self.holder].regen - self:getValue(ITEM_REGENERATION, 0)
                Unit[self.holder].evasion = Unit[self.holder].evasion - self:getValue(ITEM_EVASION, 0)
                Unit[self.holder].mr = Unit[self.holder].mr / (1 - self:getValue(ITEM_MAGIC_RESIST, 0) * 0.01)
                Unit[self.holder].dr = Unit[self.holder].dr / (1 - self:getValue(ITEM_DAMAGE_RESIST, 0) * 0.01)
                BlzSetUnitAttackCooldown(self.holder, BlzGetUnitAttackCooldown(self.holder, 0) * (1. + self:getValue(ITEM_BASE_ATTACK_SPEED, 0) * 0.01), 0)

                --shield
                if ItemData[self.id][ITEM_TYPE] == 5 then
                    ShieldCount[pid] = ShieldCount[pid] - 1
                end

                --attached effect
                DestroyEffect(self.sfx)
            end
        end

        function thistype:update()
            local orig    = ItemData[self.id][ITEM_TOOLTIP] ---@type string 
            local s_new   = "" ---@type string 
            local alt_new = "" ---@type string 

            --first "header" lines: rarity, upg level, tier, type, req level
            if self.level > 0 then
                s_new = s_new .. LEVEL_PREFIX[self.level]

                BlzSetItemSkin(self.obj, ITEM_MODEL[self.level])

                s_new = s_new .. " +" .. self.level

                s_new = s_new .. "|n"
            end

            s_new = s_new .. TIER_NAME[ItemData[self.id][ITEM_TIER]] .. " " .. TYPE_NAME[ItemData[self.id][ITEM_TYPE]]

            if ItemData[self.id][ITEM_LEVEL_REQUIREMENT] > 0 then
                s_new = s_new .. "|n|cffff0000Level Requirement: |r" .. ItemData[self.id][ITEM_LEVEL_REQUIREMENT]
            end

            s_new = s_new .. "|n"
            alt_new = s_new

            --body lines
            for index = 1, ITEM_STAT_TOTAL do
                local value = self:getValue(index, 0)

                if value ~= 0 then
                --write line
                    local lower = self:getValue(index, 1)
                    local upper = self:getValue(index, 2)
                    local valuestr = tostring(value)
                    local posneg = "+ |cffffcc00"

                    --handle negative values
                    if value < 0 then
                        valuestr = tostring(-value)
                        posneg = "- |cffcc0000"
                    end

                    --alt tooltip
                    --stat has a range
                    if ItemData[self.id][index .. "range"] ~= 0 then
                        if index == ITEM_CRIT_CHANCE then
                            alt_new = alt_new .. "|n + |cffffcc00" .. lower .. "-" .. upper .. "\x25 " .. self:getValue(index + 1, 1) .. "-" .. self:getValue(index + 1, 2) .. "x|r |cffffcc00Critical Strike|r"
                        elseif index == ITEM_CRIT_DAMAGE then
                        elseif index == ITEM_ABILITY or index == ITEM_ABILITY2 then
                            local s = ParseItemAbilityTooltip(self, index, value, lower, upper)

                            if s:len() > 0 then
                                alt_new = alt_new .. "|n" .. s
                            end
                        else
                            alt_new = alt_new .. "|n + |cffffcc00" .. lower .. "-" .. upper .. STAT_NAME[index] .. ""
                        end
                    else
                        if index == ITEM_CRIT_CHANCE then
                            alt_new = alt_new .. "|n + |cffffcc00" .. valuestr .. "\x25 " .. self:getValue(index + 1, 0) .. "x|r |cffffcc00Critical Strike|r"
                        elseif index == ITEM_CRIT_DAMAGE then
                        elseif index == ITEM_ABILITY or index == ITEM_ABILITY2 then
                            local s = ParseItemAbilityTooltip(self, index, value, 0, 0)

                            if s:len() > 0 then
                                alt_new = alt_new .. "|n" .. s
                            end
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
                        local s = ParseItemAbilityTooltip(self, index, value, 0, 0)

                        if s:len() > 0 then
                            s_new = s_new .. "|n" .. s
                        end
                    else
                        s_new = s_new .. "|n " .. posneg .. valuestr .. STAT_NAME[index]
                    end
                end
            end

            --flavor text
            --remove bracket pairs, extra spaces, and extra newlines
            orig = "|n" .. orig:gsub("(\x25b[]\x25s*)", "")
            orig = (orig:len() > 5 and ("|n" .. orig)) or ""

            self.tooltip = s_new .. orig
            self.alt_tooltip = alt_new .. orig

            if ItemData[self.id][ITEM_LIMIT] > 0 then
                self.tooltip = self.tooltip .. "|cff808080|nLimit: 1"
                self.alt_tooltip = self.alt_tooltip .. "|cff808080|nLimit: 1"
            end

            BlzSetItemIconPath(self.obj, ItemData[self.id].path)
            BlzSetItemName(self.obj, ItemData[self.id].name)
            BlzSetItemDescription(self.obj, self.tooltip)
            BlzSetItemExtendedTooltip(self.obj, self.tooltip)
        end

        ---@type fun(self: Item, id: integer, stats: integer): Item|nil
        function thistype:decode(id, stats)
            if id == 0 then
                return nil
            end

            local itemid = id & (2 ^ 13 - 1) ---@type integer 
            local shift = 13 ---@type integer 
            local itm = thistype.create(CreateItem(CUSTOM_ITEM_OFFSET + itemid, 30000., 30000.))
            itm.level = BlzBitAnd(id, 2 ^ (shift + 5) + 2 ^ (shift + 4) + 2 ^ (shift + 3) + 2 ^ (shift + 2) + 2 ^ (shift + 1) + 2 ^ (shift)) // 2 ^ (shift)

            for i = 0, 1 do
                shift = shift + 6

                if id >= 2 ^ (shift) then
                    itm.quality[i] = BlzBitAnd(id, 2 ^ (shift + 5) + 2 ^ (shift + 4) + 2 ^ (shift + 3) + 2 ^ (shift + 2) + 2 ^ (shift + 1) + 2 ^ (shift)) / 2 ^ (shift)
                end
            end

            shift = 0
            local mask = 0x3F --111111

            for i = 2, QUALITY_SAVED - 1 do
                itm.quality[i] = (stats & mask) >> shift

                mask = mask << 6
                shift = shift + 6
            end

            itm:lvl(itm.level)

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

        ---@type fun(self: Item): integer
        function thistype:encode_id()
            local id = ItemToIndex(self.id)

            if id == nil then
                return 0
            end

            id = id + self.level * 2 ^ (13 + i * 6)

            for i = 0, 1 do
                id = id + self.quality[i] * 2 ^ (13 + (i + 1) * 6)
            end

            return id
        end

        function thistype:onDestroy()
            if self.sfx then
                DestroyEffect(self.sfx)
            end

            --proper removal
            DestroyTrigger(self.trig)
            SetWidgetLife(self.obj, 1.)
            RemoveItem(self.obj)
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

        local hash = InitHashtable()

        ---@return boolean
        function thistype.onDeath()
            --typecast widget to item
            SaveWidgetHandle(hash, 0, 0, GetTriggerWidget())

            TimerQueue:callDelayed(2., thistype.expire, Item[LoadItemHandle(hash, 0, 0)])

            RemoveSavedHandle(hash, 0, 0)
            return false
        end
    end

    ---@class DropTable
    ---@field adjustRate function
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
        ---@type fun(self: DropTable, id: integer):integer
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

        id = FourCC('nplb') -- giant polar bear
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I04A')

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

        --id = FourCC('O01A') -- zeknen
        --Rates[id] = 100
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


---@type fun(itm: Item)
function ChaosShieldRegen(itm)
    if itm.equipped then
        local hp = IMinBJ(5, R2I((BlzGetUnitMaxHP(itm.holder) - GetWidgetLife(itm.holder)) / BlzGetUnitMaxHP(itm.holder) * 100 / 15))

        Unit[itm.holder].regen = Unit[itm.holder].regen - (itm.regen or 0)
        itm.regen = BlzGetUnitMaxHP(itm.holder) * (0.0001 * itm:getValue(ITEM_ABILITY, 0)) * hp
        Unit[itm.holder].regen = Unit[itm.holder].regen + itm.regen

        TimerQueue:callDelayed(0.5, ChaosShieldRegen, itm)
    end
end


---@return boolean
function RechargeItem()
    local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw    = DialogWindow[pid] ---@type DialogWindow 
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 
    local itm

    if index ~= -1 then
        itm = GetResurrectionItem(pid, true) ---@type Item?

        if itm then
            itm.charges = itm.charges + 1

            ChargeNetworth(Player(pid - 1), ItemData[itm.id][ITEM_COST] * 3, (Hardcore[pid] and 0.03) or 0.01, 0, "Recharged " .. GetItemName(itm.obj) .. " for")
            TimerStart(rezretimer[pid], 180., false, nil)
        end

        dw:destroy()
    end

    return false
end

---@type fun(pid: integer, itm: Item)
function RechargeDialog(pid, itm)
    local percentage = (Hardcore[pid] and 0.03) or 0.01
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
            DisplayTimedTextToForce(FORCE_PLAYING, 20., "An additional " .. GetObjectName(KillQuest[index][KILLQUEST_LAST]) .. " has spawned in the area.")
        end
    end
end

---@return boolean
function RewardItem()
    local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw    = DialogWindow[pid] ---@type DialogWindow 
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        PlayerAddItemById(pid, dw.data[index])

        dw:destroy()
    end

    return false
end

---@return boolean
function BackpackUpgrades()
    local dw    = DialogWindow[GetPlayerId(GetTriggerPlayer()) + 1] ---@type DialogWindow 
    local id    = dw.data[0] ---@type integer 
    local price = dw.data[1] ---@type integer 
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 
    local ablev = 0 ---@type integer 

    if index ~= -1 then
        AddCurrency(dw.pid, GOLD, - ModuloInteger(price, 1000000))
        AddCurrency(dw.pid, PLATINUM, - (price // 1000000))

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
            goldCost = R2I(ModuloInteger(itm:getValue(ITEM_COST, 0) * DISCOUNT_RATE, 1000000))
            platCost = R2I(itm:getValue(ITEM_COST, 0) * DISCOUNT_RATE) // 1000000

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
    local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw    = DialogWindow[pid] ---@type DialogWindow 
    local itm   = dw.data[0] ---@type Item 
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

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
    local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw    = DialogWindow[pid] ---@type DialogWindow 
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        local itm = dw.data[index]

        dw:destroy()

        if itm then
            local goldCost = ModuloInteger(itm:getValue(ITEM_COST, 0), 1000000)
            local platCost = itm:getValue(ITEM_COST, 0) // 1000000
            local crystalCost = CRYSTAL_PRICE[itm.level]
            local s = "Upgrade cost: |n" ---@type string 

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
    local u    = GetTriggerUnit() ---@type unit 
    local p    = GetOwningPlayer(u) ---@type player 
    local pid  = GetPlayerId(p) + 1 ---@type integer 
    local itm  = Item[GetManipulatedItem()] ---@type Item 
    local slot = GetItemSlot(itm, u)
    local lvlreq = ItemData[itm.id][ITEM_LEVEL_REQUIREMENT] ---@type integer 

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
            if not ITEM_DROP_FLAG[pid] then
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
    --local itm = GetManipulatedItem() ---@type item 

    --Item[itm]:destroy()

    return false
end

--event handler function for buying items
function onBuy()
    local u      = GetTriggerUnit() ---@type unit 
    local b      = GetBuyingUnit() ---@type unit 
    local pid    = GetPlayerId(GetOwningPlayer(b)) + 1 ---@type integer 
    local itm    = Item[GetSoldItem()] ---@type Item 

    itm.owner = Player(pid - 1)

    if GetUnitTypeId(u) == FourCC('h002') then --naga chest
        TimerQueue:callDelayed(2.5, RemoveUnit, u)
        DestroyEffect(AddSpecialEffectTarget("UI\\Feedback\\GoldCredit\\GoldCredit.mdl", u, "origin"))
        Fade(u, 2., false)
    end
end

--event handler function for using items
function onUse()
    local u   = GetTriggerUnit() ---@type unit 
    local p   = GetOwningPlayer(u) ---@type player 
    local pid = GetPlayerId(p) + 1 ---@type integer 
    local itm = Item[GetManipulatedItem()] ---@type Item?

    if itm then
        local abil = ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET]

        --find pot spell
        for _, v in pairs(POTIONS) do --sync safe
            if v[abil] then
                v[abil](pid, itm)
                break
            end
        end
    end
end

--event handler function for dropping items
function onDrop()
    local u    = GetTriggerUnit() ---@type unit 
    local pid  = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
    local itm  = Item[GetManipulatedItem()] ---@type Item 
    local slot = GetItemSlot(itm, u) ---@type integer 

    if slot >= 0 then --safety
        BlzFrameSetVisible(INVENTORYBACKDROP[slot], false)

        --update hero inventory
        if GetUnitTypeId(u) == BACKPACK then
            slot = slot + 6
        end

        Profile[pid].hero.items[slot] = nil
    end

    if itm then
        if not itm.restricted and u == Hero[pid] and not ITEM_DROP_FLAG[pid] then
            itm:unequip()
        end

        TimerQueue:callDelayed(0., OnDropUpdate, itm)

        itm.holder = nil
    end
end

--event handler function for picking up items
function onPickup()
    local u = GetTriggerUnit() ---@type unit 
    local itm = Item[GetManipulatedItem()] ---@type Item
    local itemid = (itm and GetItemTypeId(itm.obj)) or 0
    local itemtype = (itm and GetItemType(itm.obj)) or 0
    local p = GetOwningPlayer(u) ---@type player 
    local pid = GetPlayerId(p) + 1 ---@type integer 
    local i = 0 ---@type integer 
    local i2 = 0 ---@type integer 
    local x ---@type number 
    local y ---@type number 
    local U = User.first ---@type User 

    --check item lookup table
    if ITEM_LOOKUP[itemid] then
        ITEM_LOOKUP[itemid](p, pid, u, itm)
    end

    --========================
    --Quests
    --========================

    --kill quests
    if KillQuest[itemid][0] ~= 0 and itemtype == ITEM_TYPE_CAMPAIGN then
        FlashQuestDialogButton()
        KillQuestHandler(pid, itemid)
    --shopkeeper gossip
    elseif itemid == FourCC('I0OV') then
        x = GetUnitX(evilshopkeeper)
        y = GetUnitY(evilshopkeeper)

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

                TimerQueue:callDelayed(30., SpawnOrcs)
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
    elseif HeadHunter[itemid] then

        if HeadHunter[itemid].Level <= GetHeroLevel(Hero[pid]) then
            local head = GetItemFromPlayer(pid, HeadHunter[itemid].Head)

            if head then
                head:destroy()

                local reward = HeadHunter[itemid].Reward

                if type(reward) == "table" then
                    local dw = DialogWindow.create(pid, "Choose a reward", RewardItem) ---@type DialogWindow
                    dw.cancellable = false

                    for _, v in ipairs(reward) do
                        if HasProficiency(pid, PROF[ItemData[v][ITEM_TYPE]]) then
                            dw.data[dw.ButtonCount] = v
                            dw:addButton(GetObjectName(v) .. " [" .. TYPE_NAME[ItemData[v][ITEM_TYPE]] .. "]")
                        end
                    end

                    dw:display()
                else
                    PlayerAddItemById(pid, reward)
                end

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

    elseif itemid == FourCC('I0JO') and CHAOS_MODE == false then --god portal
        if god_portal ~= nil and TableHas(GODS_GROUP, p) == false then
            GODS_GROUP[#GODS_GROUP + 1] = p

            BlzSetUnitFacingEx(Hero[pid], 45)
            MoveHero(pid, GetRectCenterX(gg_rct_GodsEntrance), GetRectCenterY(gg_rct_GodsEntrance))
            reselect(Hero[pid])

            if GodsEnterFlag == false then
                GodsEnterFlag = true
                DisplayTextToForce(FORCE_PLAYING, "This is your last chance to -flee.")

                SetCinematicScene(GetUnitTypeId(zeknen), GetPlayerColor(pboss), "Zeknen", "Explain yourself or be struck down from this heaven!", 9, 8)
                TimerQueue:callDelayed(10., ZeknenExpire)
            end
        end

    elseif itemid == FourCC('I0NO') and CHAOS_MODE == false then --rescind to darkness
        if GodsEnterFlag == false and CHAOS_MODE == false and GetHeroLevel(Hero[pid]) >= 240 then
            power_crystal = CreateUnitAtLoc(pfoe, FourCC('h04S'), Location(30000, -30000), bj_UNIT_FACING)
            KillUnit(power_crystal)
        end

    --========================
    --Buyables / Shops
    --========================

    elseif itemid == FourCC('I07Q') and not CHURCH_DONATION[pid] then --donation
        ChargeNetworth(p, 0, 0.01, 100, "")
        CHURCH_DONATION[pid] = true
        donation = donation - donationrate
        DisplayTextToPlayer(p, 0, 0, "|c00408080The Goddesses bestow their blessings.")
        DisplayTextToForce(FORCE_PLAYING, "Reduced bad weather chance: " .. (R2I((1 - donation) * 100)) .. "\x25")
    elseif itemid == FourCC('I0M9') then --prestige
        if UnitHasItemType(Hero[pid], FourCC('I0NN')) then
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
        local refund = 0
        if GetHeroStr(Hero[pid], false) - 50 > 20 then
            UnitAddBonus(Hero[pid], BONUS_HERO_BASE_STR, GetHeroStr(Hero[pid], false) - 50)
            refund = refund + 5000
        elseif GetHeroStr(Hero[pid], false) >= 20 then
            UnitSetBonus(Hero[pid], BONUS_HERO_BASE_STR, 20)
        end
        if GetHeroAgi(Hero[pid], false) - 50 > 20 then
            UnitAddBonus(Hero[pid], BONUS_HERO_BASE_AGI, GetHeroAgi(Hero[pid], false) - 50)
            refund = refund + 5000
        elseif GetHeroAgi(Hero[pid], false) >= 20 then
            UnitSetBonus(Hero[pid], BONUS_HERO_BASE_AGI, 20)
        end
        if GetHeroInt(Hero[pid], false) - 50 > 20 then
            UnitAddBonus(Hero[pid], BONUS_HERO_BASE_INT, GetHeroInt(Hero[pid], false) - 50)
            refund = refund + 5000
        elseif GetHeroInt(Hero[pid], false) >= 20 then
            UnitSetBonus(Hero[pid], BONUS_HERO_BASE_INT, 20)
        end
        if refund > 0 then
            AddCurrency(pid, GOLD, refund)
            DisplayTextToPlayer(p, 0, 0, "You have been refunded |cffffcc00" .. RealToString(refund) .. "|r gold.")
        end
    elseif itemid == FourCC('I0JN') then --tome of retraining
        UnitAddItemById(Hero[pid], FourCC('Iret'))
    elseif itemid == FourCC('I101') or itemid == FourCC('I102') then --upgrade teleports & reveal
        local lvl = (itemid == FourCC('I101') and GetUnitAbilityLevel(Backpack[pid], FourCC('A02J'))) or GetUnitAbilityLevel(Backpack[pid], FourCC('A0FK'))

        if lvl < 10 then --only 10 upgrades
            local dw ---@type DialogWindow
            local index = R2I(400. * Pow(5., lvl - 1.))

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

        for index = 0, MAX_INVENTORY_SLOTS - 1 do
            local it = Profile[pid].hero.items[index]

            if it and ItemData[it.id][ITEM_UPGRADE_MAX] > it.level then
                dw.data[dw.ButtonCount] = it
                dw:addButton(it:name())
            end
        end

        dw:display()
    --salvage (boss) items
    elseif itemid == FourCC('I01R') then
        local dw = DialogWindow.create(pid, "Choose an item to salvage.", SalvageItem) ---@type DialogWindow
        local index = 0

        while index < MAX_INVENTORY_SLOTS do
            local it = Profile[pid].hero.items[index]

            if it and ItemData[it.id][ITEM_COST] > 0 then
                dw.data[dw.ButtonCount] = it
                dw:addButton(it:name())
            end

            index = index + 1
        end

        dw:display()
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
        local it = GetResurrectionItem(pid, true)

        if it and GetItemCharges(it.obj) >= MAX_REINCARNATION_CHARGES then
            it = nil
        end

        if it == nil then
            DisplayTimedTextToPlayer(p, 0, 0, 15, "You have no item to recharge!")
        elseif TimerGetRemaining(rezretimer[pid]) > 1 then
            DisplayTimedTextToPlayer(p, 0, 0,15, (R2I(TimerGetRemaining(rezretimer[pid]))) .. " seconds until you can recharge your " .. GetItemName(it.obj))
        else
            RechargeDialog(pid, it)
        end

    --========================
    --Quest Rewards
    --========================

    elseif itemid == FourCC('I08L') then -- Shopkeeper necklace
        Recipe(FourCC('I045'), 1, FourCC('item'), 0, FourCC('item'), 0, FourCC('item'), 0, FourCC('item'), 0, FourCC('item'), 0, FourCC('I03E'), 0, u, 0, 0, 0, false)
    elseif itemid == FourCC('I09H') then -- Omega Pick
        Recipe(FourCC('I02Y'), 1, FourCC('I02X'), 1, FourCC('item'), 0, FourCC('item'), 0, FourCC('item'), 0, FourCC('item'), 0, FourCC('I043'), 0, u, 0, 0, 0, false)

    --========================
    --Recipes
    --========================

    --TODO rework
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
            DisplayTimedTextToPlayer(p, 0, 0, 5.00, "Colosseum is occupied!")
        else
            local ug = CreateGroup()
            GroupEnumUnitsInRect(ug, gg_rct_Colosseum_Enter, Condition(ischar))

            if (itemid == FourCC('I0EO')) or (itemid == FourCC('I0ES')) then
                if CHAOS_MODE then
                    Wave = 103
                else
                    Wave = 0
                end
            elseif (itemid == FourCC('I0EP')) or (itemid == FourCC('I0ET')) then
                if CHAOS_MODE then
                    Wave = 128
                else
                    Wave = 25
                end
            elseif (itemid == FourCC('I0EQ'))or(itemid == FourCC('I0EU')) then
                if CHAOS_MODE then
                    Wave = 153
                else
                    Wave = 49
                end
            elseif (itemid == FourCC('I0ER'))or(itemid == FourCC('I0EV')) then
                if CHAOS_MODE then
                    Wave = 182
                else
                    Wave = 73
                end
            end

            local index = 0

            if (itemid == FourCC('I0ER') or itemid == FourCC('I0EQ') or itemid == FourCC('I0EP') or itemid == FourCC('I0EO')) then -- solo
                index = 1
            elseif (itemid == FourCC('I0EV') or itemid == FourCC('I0EU') or itemid == FourCC('I0ET') or itemid == FourCC('I0ES')) then -- team
                if BlzGroupGetSize(ug) > 1 then
                    index = 2
                else
                    DisplayTextToPlayer(p, 0, 0, "Atleast 2 players is required to play team survival.")
                end
            end

            if (itemid == FourCC('I0ER') or itemid == FourCC('I0EV')) and CHAOS_MODE then
                i2 = 350
            end

            local levmin = 500
            local levmax = 0

            if index == 1 then
                --start colo solo
                if not IS_TELEPORTING[pid] then
                    ColoPlayerCount = 1
                    Colosseum_Monster_Amount = 0
                    ColoWaveCount = 0
                    InColo[pid] = true
                    GroupClear(ColoWaveGroup)
                    MoveHeroLoc(pid, ColosseumCenter)
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
                        if u == Hero[pid] and not IS_TELEPORTING[pid] then
                            InColo[pid] = true
                            ColoPlayerCount = ColoPlayerCount + 1
                            Fleeing[pid] = false
                            MoveHeroLoc(pid, ColosseumCenter)
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
        GroupEnumUnitsInRect(ug, gg_rct_Colosseum_Enter, Condition(ischar))

        if Struggle_Pcount > 0 then
            GroupClear(ug)
            DisplayTextToPlayer(Player(pid-1),0,0, "Struggle is occupied.")
        elseif BlzGroupGetSize(ug) > 0 then
            local levmin = 500
            local levmax = 0

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
                    if u == Hero[pid] and not IS_TELEPORTING[pid] then
                        InStruggle[pid] = true
                        Struggle_Pcount = Struggle_Pcount + 1
                        Fleeing[pid] = false
                        DisableItems(pid)
                        MoveHeroLoc(pid, StruggleCenter)
                        CreateUnitAtLoc(GetOwningPlayer(u), FourCC('h065'), StruggleCenter, bj_UNIT_FACING)
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
        if RectContainsCoords(MAIN_MAP.rect, GetUnitX(u), GetUnitY(u)) then
            if GetHeroLevel(Hero[pid]) < 160 then --prechaos
                x = GetRandomReal(GetRectMinX(gg_rct_PrechaosTraining_Vision), GetRectMaxX(gg_rct_PrechaosTraining_Vision))
                y = GetRandomReal(GetRectMinY(gg_rct_PrechaosTraining_Vision), GetRectMaxY(gg_rct_PrechaosTraining_Vision))
            else --chaos
                x = GetRandomReal(GetRectMinX(gg_rct_ChaosTraining_Vision), GetRectMaxX(gg_rct_ChaosTraining_Vision))
                y = GetRandomReal(GetRectMinY(gg_rct_ChaosTraining_Vision), GetRectMaxY(gg_rct_ChaosTraining_Vision))
            end

            MoveHero(pid, x, y)
            reselect(Hero[pid])
        end

    elseif itemid == FourCC('I0MW') then --Exit Training
        if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            local ug = CreateGroup()
            GroupEnumUnitsInRect(ug, gg_rct_PrechaosTrainingSpawn, Condition(ishostile))

            if not FirstOfGroup(ug) then
                MoveHero(pid, GetRectCenterX(gg_rct_Training_Exit), GetRectCenterY(gg_rct_Training_Exit))
                reselect(Hero[pid])
            else
                DisplayTextToPlayer(p, 0, 0, "You must kill all enemies before leaving!")
            end

            DestroyGroup(ug)
        elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            local ug = CreateGroup()
            GroupEnumUnitsInRect(ug, gg_rct_ChaosTrainingSpawn, Condition(ishostile))

            if not FirstOfGroup(ug) then
                MoveHero(pid, GetRectCenterX(gg_rct_Training_Exit), GetRectCenterY(gg_rct_Training_Exit))
                reselect(Hero[pid])
            else
                DisplayTextToPlayer(p, 0, 0, "You must kill all enemies before leaving!")
            end

            DestroyGroup(ug)
        end

    elseif itemid == FourCC('I0MS') then --Training Spawn Unit
        local flag = (RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) and 0) or 1
        local trainer = ((flag == 0) and prechaosTrainer) or chaosTrainer
        local trainerItem = Item[UnitItemInSlot(trainer, 0)]
        local r = ((flag == 0) and gg_rct_PrechaosTrainingSpawn) or gg_rct_ChaosTrainingSpawn
        CreateUnit(pfoe, UnitData[flag][trainerItem.spawn], GetRandomReal(GetRectMinX(r), GetRectMaxX(r)), GetRandomReal(GetRectMinY(r), GetRectMaxY(r)), GetRandomReal(0,359))

    elseif itemid == FourCC('I0MU') or itemid == FourCC('I0MV') then --Change Difficulty
        local increase = (itemid == FourCC('I0MU') and true) or false
        local flag = (RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) and 0) or 1
        local trainer = ((flag == 0) and prechaosTrainer) or chaosTrainer
        local trainerItem = Item[UnitItemInSlot(trainer, 0)]

        if increase == true then
            trainerItem.spawn = trainerItem.spawn + 1
            if UnitData[flag][trainerItem.spawn] == 0 then
                trainerItem.spawn = trainerItem.spawn - 1
            end
        else
            trainerItem.spawn = IMaxBJ(0, trainerItem.spawn - 1)
        end

        --update item info
        BlzSetItemName(trainerItem.obj, "|cffffcc00" .. GetObjectName(UnitData[flag][trainerItem.spawn]) .. "|r")
        --blzgetability icon works for units as well
        BlzSetItemIconPath(trainerItem.obj, BlzGetAbilityIcon(UnitData[flag][trainerItem.spawn]))
    elseif itemid == FourCC('PVPA') then --Enter PVP
        local dw = DialogWindow.create(pid, "Choose an arena.", EnterPVP) ---@type DialogWindow

        dw:addButton("Wastelands [FFA]")
        dw:addButton("Pandaren Forest [Duel]")
        dw:addButton("Ice Cavern [Duel]")

        dw:display()
    --item is present in inventory
    elseif itm then
        if not itm.restricted then
            if not ITEM_DROP_FLAG[pid] then
                itm:equip()
                if GetLocalPlayer() == p then
                    BlzFrameSetTexture(INVENTORYBACKDROP[GetEmptySlot(u)], SPRITE_RARITY[itm.level], 0, true)
                end
            end
        end
    end

    ITEM_DROP_FLAG[pid] = false
end

    local onpickup = CreateTrigger()
    local ondrop   = CreateTrigger()
    local useitem  = CreateTrigger()
    local onbuy    = CreateTrigger()
    local onsell   = CreateTrigger()
    local u        = User.first ---@type User 

    while u do
        rezretimer[u.id] = CreateTimer()
        TriggerRegisterPlayerUnitEvent(onpickup, u.player, EVENT_PLAYER_UNIT_PICKUP_ITEM, nil)
        TriggerRegisterPlayerUnitEvent(ondrop, u.player, EVENT_PLAYER_UNIT_DROP_ITEM, nil)
        TriggerRegisterPlayerUnitEvent(useitem, u.player, EVENT_PLAYER_UNIT_USE_ITEM, nil)
        TriggerRegisterPlayerUnitEvent(onsell, u.player, EVENT_PLAYER_UNIT_PAWN_ITEM, nil)
        u = u.next
    end

    --item preload
    local nerub = HeadHunter[NERUBIAN_QUEST].Reward ---@type table
    for _, v in ipairs(nerub) do
        Item.create(CreateItem(v, 30000., 30000.), 0.01)
    end

    local polarbear = HeadHunter[POLARBEAR_QUEST].Reward ---@type table
    for _, v in ipairs(polarbear) do
        Item.create(CreateItem(v, 30000., 30000.), 0.01)
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
