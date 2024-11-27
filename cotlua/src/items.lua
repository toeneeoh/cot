--[[
    items.lua

    A library that defines an item interface and handles item related events
        (EVENT_PLAYER_UNIT_PICKUP_ITEM
        EVENT_PLAYER_UNIT_DROP_ITEM
        EVENT_PLAYER_UNIT_USE_ITEM
        EVENT_PLAYER_UNIT_PAWN_ITEM
        EVENT_PLAYER_UNIT_SELL_ITEM)
]]

OnInit.final("Items", function(Require)
    Require('Users')
    Require('Variables')
    Require('Frames')
    Require('Inventory')

    local floor = math.floor
    local log = math.log

    ON_BUY_LOOKUP     = {}
    ITEM_LOOKUP       = {}
    CHURCH_DONATION   = {} ---@type boolean[] 
    RECHARGE_COOLDOWN = {} ---@type timer[] 
    IS_ITEM_DROP = __jarray(true) ---@type boolean[]

    DISCOUNT_RATE = 0.25

    POTIONS = {
        --hp potions
        [FourCC('A09C')] = { -- hp hotkey
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
        [FourCC('A0FS')] = { -- mana hotkey
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
        [FourCC('A05N')] = { -- special hotkey
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
    ---@field drop function
    ---@field update function
    ---@field encode_id function
    ---@field encode_stats function
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
    ---@field nocraft boolean
    ---@field pid integer
    ---@field index integer
    ---@field validate_slot function
    Item = {} ---@type Item|Item[]
    do
        local thistype = Item
        local hash = InitHashtable()

        function thistype.onDeath()
            -- typecast widget to item
            SaveWidgetHandle(hash, 0, 0, GetTriggerWidget())
            TimerQueue:callDelayed(2., thistype.destroy, Item[LoadItemHandle(hash, 0, 0)])
            RemoveSavedHandle(hash, 0, 0)
            return false
        end
        thistype.eval = Condition(thistype.onDeath)

        -- object inheritance and method operators
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

        -- override createitem
        OldCreateItem = CreateItem

        ---@type fun(id: string|integer|item, x: number?, y: number?, expire: number?): Item
        function CreateItem(id, x, y, expire)
            local lvl = 0
            local itm = id

            -- parse "I000:00" notation, where level / variation is signified by numbers after a colon
            if type(id) == "string" then
                id = FourCC(string.sub(id, 1, 4))
                lvl = tonumber(string.sub(id, 6))
            end

            -- create the item if given an id rather than a handle
            if type(id) ~= "userdata" then
                itm = OldCreateItem(id, x or 30000., y or 30000.)
            end

            local self = setmetatable({ ---@type Item
                obj = itm,
                id = GetItemTypeId(itm),
                level = lvl,
                trig = CreateTrigger(),
                x = GetItemX(itm),
                y = GetItemY(itm),
                quality = __jarray(0),
                owner = nil,
                holder = nil,
                equipped = false,
                proxy = {
                    charges = math.max(1, GetItemCharges(itm)),
                    restricted = false,
                },
            }, mt)

            -- first time setup
            if ItemData[self.id][ITEM_TOOLTIP] == 0 then
                -- if an item's description exists, use that for parsing (exception for default shops)
                ParseItemTooltip(self.obj, ((BlzGetItemDescription(self.obj):len()) > 1 and BlzGetItemDescription(self.obj)) or "")
            end

            -- determine if immediately useable in recipes
            self.nocraft = ItemData[self.id][ITEM_NOCRAFT] ~= 0

            -- determine if saveable (ITEM_TYPE_MISCELLANEOUS yields 6 instead of proper value of 7)
            if (GetHandleId(GetItemType(self.obj)) == 7 or GetItemType(self.obj) == ITEM_TYPE_PERMANENT) and self.id > CUSTOM_ITEM_OFFSET then
                SAVE_TABLE.KEY_ITEMS[self.id] = self.id - CUSTOM_ITEM_OFFSET

                -- hide the item according to item drop settings
                if not IS_ITEM_DROP[GetPlayerId(GetLocalPlayer()) + 1] then
                    BlzSetItemSkin(self.obj, FourCC('rar0'))
                end
            end

            -- handle item death
            TriggerRegisterDeathEvent(self.trig, self.obj)
            TriggerAddCondition(self.trig, thistype.eval)

            -- timed life
            if expire then
                TimerQueue:callDelayed(expire, thistype.expire, self)
            end

            -- randomize rolls
            local count = 1
            for i = 1, ITEM_STAT_TOTAL do
                if ItemData[self.id][i .. "range"] ~= 0 then
                    self.quality[count] = GetRandomInt(0, 63)
                    count = count + 1
                end

                if count > QUALITY_SAVED then break end
            end

            if ItemData[self.id][ITEM_TIER] ~= 0 then
                self:update()
            end

            Item[self.obj] = self

            return self
        end

        local backpack_allowed = {
            [FourCC('A0E2')] = 1, -- sea ward
            [FourCC('A0D3')] = 1, -- jewel of the horde
            [FourCC('A04I')] = 1, -- drum of war aura
            [FourCC('A03G')] = 1, -- blood horn (unholy aura)
            [FourCC('Aarm')] = 1, -- armor of the gods (devotion aura)
        }

        ---@type fun(itm: Item)
        local function add_item_ability(itm)
            for index = ITEM_ABILITY, ITEM_ABILITY2 do
                local abilid = ItemData[itm.id][index * ABILITY_OFFSET]
                -- don't add ability if backpack is not allowed
                if GetUnitTypeId(itm.holder) == BACKPACK and not backpack_allowed[abilid] then
                    abilid = 0
                end
                -- ability exists and unlocked
                if abilid ~= 0 and itm.level >= ItemData[itm.id][index .. "unlock"] then
                    UnitAddAbility(itm.holder, abilid)
                    UnitMakeAbilityPermanent(itm.holder, true, abilid)
                    BlzUnitHideAbility(itm.holder, abilid, true)

                    -- defined item spells
                    if Spells[abilid] then
                        -- if onequip returns true, dont allocate real fields
                        if not Spells[abilid].onEquip(itm, abilid, index) then
                            local ab = BlzGetUnitAbility(itm.obj, abilid)
                            BlzSetAbilityRealLevelField(ab, SPELL_FIELD[0], 0, itm:getValue(index, 0))
                            for i = 1, SPELL_FIELD_TOTAL do
                                local v = ItemData[itm.id][index * ABILITY_OFFSET + i]
                                if v ~= 0 then
                                    BlzSetAbilityRealLevelField(ab, SPELL_FIELD[i], 0, v)
                                end
                            end
                        end
                    end

                    IncUnitAbilityLevel(itm.holder, abilid)
                    DecUnitAbilityLevel(itm.holder, abilid)
                end
            end
        end

        -- Called on equip to stack with an existing item if applicable
        ---@type fun(self: Item, pid: integer, limit: integer): boolean
        function thistype:stack(pid, limit)
            local offset = (self.holder == Backpack[pid] and 7) or 1

            for i = 1, MAX_INVENTORY_SLOTS do
                local match = Profile[pid].hero.items[i]

                if match and match ~= self and match.id == self.id and match.charges < limit and match.level == self.level then
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

        -- Adjusts name in tooltip if an item is useable or not
        ---@type fun(self: Item, flag: boolean)
        function thistype:restrict(flag)
            if flag then
                BlzSetItemName(self.obj, self:name() .. "\n|cffFFCC00You are too low level to use this item!|r")
            else
                BlzSetItemName(self.obj, self:name())
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

        local function apply_item_stats(self, mult)
            if not self.holder then
                return
            end

            local u = Hero[self.pid]
            local unit = Unit[u]
            local hp   = GetWidgetLife(u) ---@type number 
            local mana = GetUnitState(u, UNIT_STATE_MANA) ---@type number 
            local mod  = ItemProfMod(self.id, self.pid) ---@type number 

            UnitAddBonus(u, BONUS_ARMOR, mult * floor(mod * self:getValue(ITEM_ARMOR, 0)))
            UnitAddBonus(u, BONUS_DAMAGE, mult * floor(mod * self:getValue(ITEM_DAMAGE, 0)))
            unit.bonus_hp = unit.bonus_hp + mult * floor(mod * self:getValue(ITEM_HEALTH, 0))
            unit.bonus_mana = unit.bonus_mana + mult * floor(mod * self:getValue(ITEM_MANA, 0))
            unit.bonus_str = unit.bonus_str + mult * floor(mod * self:getValue(ITEM_STRENGTH, 0))
            unit.bonus_agi = unit.bonus_agi + mult * floor(mod * self:getValue(ITEM_AGILITY, 0))
            unit.bonus_int = unit.bonus_int + mult * floor(mod * self:getValue(ITEM_INTELLIGENCE, 0))

            SetWidgetLife(u, math.max(1, hp))
            SetUnitState(u, UNIT_STATE_MANA, mana)

            ItemGoldRate[self.pid] = ItemGoldRate[self.pid] + mult * self:getValue(ITEM_GOLD_GAIN, 0)
            unit.spellboost = unit.spellboost + mult * self:getValue(ITEM_SPELLBOOST, 0) * 0.01
            unit.ms_flat = unit.ms_flat + mult * self:getValue(ITEM_MOVESPEED, 0)
            unit.regen_flat = unit.regen_flat + mult * self:getValue(ITEM_REGENERATION, 0)
            unit.evasion = unit.evasion + mult * self:getValue(ITEM_EVASION, 0)
            unit.cc_flat = unit.cc_flat + mult * self:getValue(ITEM_CRIT_CHANCE, 0)
            unit.cd_flat = unit.cd_flat + mult * self:getValue(ITEM_CRIT_DAMAGE, 0)

            -- percent
            if mult > 0 then
                unit.mr = unit.mr * (1 - self:getValue(ITEM_MAGIC_RESIST, 0) * 0.01)
                unit.dr = unit.dr * (1 - self:getValue(ITEM_DAMAGE_RESIST, 0) * 0.01)
                unit.bonus_bat = unit.bonus_bat / (1. + self:getValue(ITEM_BASE_ATTACK_SPEED, 0) * 0.01)
            else
                unit.mr = unit.mr / (1 - self:getValue(ITEM_MAGIC_RESIST, 0) * 0.01)
                unit.dr = unit.dr / (1 - self:getValue(ITEM_DAMAGE_RESIST, 0) * 0.01)
                unit.bonus_bat = unit.bonus_bat * (1. + self:getValue(ITEM_BASE_ATTACK_SPEED, 0) * 0.01)
            end

            -- shield
            if ItemData[self.id][ITEM_TYPE] == 5 then
                ShieldCount[self.pid] = ShieldCount[self.pid] + mult * 1
            end

            -- profiency warning
            if GetHeroLevel(u) < 15 and mod < 1 then
                DisplayTimedTextToPlayer(self.owner, 0, 0, 10, "You lack the proficiency (-pf) to use this item, therefore it only gives 75\x25 of most stats.\n|cffFF0000You will stop getting this warning at level 15.|r")
            end

            UpdateManaCosts(self.pid)
        end

        function thistype:lvl(lvl)
            if ItemData[self.id][ITEM_UPGRADE_MAX] > 0 then
                apply_item_stats(self, -1)
                self.level = lvl
                self:update()
                apply_item_stats(self, 1)
            end
        end

        function thistype:consumeCharge()
            self.charges = self.charges - 1

            if self.charges == 0 then
                print("Consumed!!")
                self:destroy()
            end
        end

        ---@type fun(self: Item, STAT: integer, flag: integer): number
        function thistype:getValue(STAT, flag)
            local unlockat = ItemData[self.id][STAT .. "unlock"] ---@type number 

            if self.level < unlockat then
                return 0
            end

            local flatPerLevel  = ItemData[self.id][STAT .. "fpl"] ---@type number 
            local flatPerRarity = ItemData[self.id][STAT .. "fpr"] ---@type number 
            local percent       = ItemData[self.id][STAT .. "percent"] ---@type number 
            local fixed         = ItemData[self.id][STAT .. "fixed"] ---@type number 
            local lower         = ItemData[self.id][STAT]  ---@type number 
            local upper         = ItemData[self.id][STAT .. "range"]  ---@type number 
            local hasVariance   = (upper ~= 0) ---@type boolean 
            local pmult         = (percent ~= 0 and percent * 0.01) or 1 ---@type number

            --calculate values after applying affixes
            lower = lower + ((flatPerLevel * self.level + flatPerRarity * (math.max(self.level - 1, 0) // 4)) * pmult)
            upper = upper + ((flatPerLevel * self.level + flatPerRarity * (math.max(self.level - 1, 0) // 4)) * pmult)

            --values are not fixed
            if fixed == 0 then
                lower = lower + lower * ITEM_MULT[self.level] * pmult
                upper = upper + upper * ITEM_MULT[self.level] * pmult
            end

            if flag == 1 then
                return (lower < 1 and lower) or floor(lower)
            elseif flag == 2 then
                return (upper < 1 and upper) or floor(upper)
            else
                local final = 0

                if hasVariance then
                    local count = 1

                    --find the quality index
                    for index = 0, STAT - 1 do
                        if ItemData[self.id][index .. "range"] ~= 0 then
                            count = count + 1
                        end
                    end

                    final = lower + (upper - lower) * 0.015625 * (1 + self.quality[count])
                else
                    final = lower
                end

                --round to nearest 10s
                if final >= 1000 then
                    final = (final + 5) // 10 * 10
                end

                return (final < 1 and final) or floor(final)
            end
        end

        local function remove_item_ability(self, holder, abilid)
            if self and not self.holder or (GetUnitTypeId(self.holder) == BACKPACK and not backpack_allowed[abilid]) then
                UnitMakeAbilityPermanent(holder, false, abilid)
                UnitRemoveAbility(holder, abilid)
            end
        end

        ---@type fun(itm: Item, pid: integer): boolean
        local function is_item_bound(itm, pid)
            return (itm.owner ~= Player(pid - 1) and itm.owner ~= nil)
        end

        ---@param itm Item
        ---@return boolean, string?
        local function is_item_limited(itm)
            local limit = ItemData[itm.id][ITEM_LIMIT] ---@type integer 

            if limit == 0 then
                return false
            end

            local items = Profile[itm.pid].hero.items

            for i = 1, 6 do
                local itm2 = items[i]

                if itm2 and itm2 ~= itm then
                    if (limit == 1 and itm.id ~= itm2.id) then
                    -- safe case
                    elseif limit == ItemData[itm2.id][ITEM_LIMIT] then
                        return true, LIMIT_STRING[limit]
                    end
                end
            end

            return false
        end

        local function validate_slot(self, slot)
            local lvl = GetHeroLevel(Hero[self.pid])
            local lvlreq = ItemData[self.id][ITEM_LEVEL_REQUIREMENT] ---@type integer 

            if slot <= 6 then
                local limited, err = is_item_limited(self)

                if lvlreq > lvl then
                    DisplayTimedTextToPlayer(Player(self.pid - 1), 0, 0, 15., "This item requires at least level |c00FF5555" .. (lvlreq) .. "|r to equip.")
                    return false
                elseif limited then
                    DisplayTextToPlayer(Player(self.pid - 1), 0, 0, err)
                    return false
                end
            elseif slot > 6 and lvlreq > lvl + 20 then
                DisplayTimedTextToPlayer(Player(self.pid - 1), 0, 0, 15., "This item requires at least level |c00FF5555" .. (lvlreq - 20) .. "|r to pick up.")
                return false
            end

            return true
        end

        local function find_empty_slot(self, holder)
            -- Set starting slot to 7 if backpack picked up or fails limit check
            local slot = (((holder == Backpack[self.pid] or is_item_limited(self)) and 7) or 1)
            local items = Profile[self.pid].hero.items

            for i = slot, MAX_INVENTORY_SLOTS do
                if not items[i] then
                    return i
                end
            end

            return nil
        end

        function thistype:equip(slot, holder)
            -- check if item is bound
            if is_item_bound(self, self.pid) and SAVE_TABLE.KEY_ITEMS[self.id] then
                DisplayTimedTextToPlayer(Player(self.pid - 1), 0, 0, 30, "This item is bound to " .. User[self.owner].nameColored .. ".")
                return false
            end

            -- determine the slot
            slot = slot or find_empty_slot(self, holder)

            -- validate it (level check, limited check)
            if slot and validate_slot(self, slot) then
                self.holder = (slot <= 6 and Hero[self.pid]) or Backpack[self.pid]
            end

            if self.holder then
                local items = Profile[self.pid].hero.items

                -- if item is stackable
                local stack = self:getValue(ITEM_STACK, 0)
                if stack > 1 then
                    self:stack(self.pid, stack)
                end

                -- make sure item is not occupying previous space
                if self.index and items[self.index] == self then
                    items[self.index] = nil
                end

                -- determine whether to add or remove stats
                if not self.equipped and slot <= 6 then
                    self.equipped = true

                    apply_item_stats(self, 1)

                    -- bind item
                    if SAVE_TABLE.KEY_ITEMS[self.id] then
                        self.owner = Player(self.pid - 1)
                    end
                elseif self.equipped and slot > 6 then
                    self.equipped = false

                    apply_item_stats(self, -1)
                end

                -- add item abilities after a delay (required for each equip)
                TimerQueue:callDelayed(0., add_item_ability, self)

                -- set index
                items[slot] = self
                self.index = slot

                SetItemPosition(self.obj, 30000., 30000.)
                SetItemVisible(self.obj, false)

                return true
            end

            return false
        end

        function thistype:drop(x, y)
            if self.holder == nil or self.index == nil then
                return
            end

            for index = ITEM_ABILITY, ITEM_ABILITY2 do
                local abilid = ItemData[self.id][index * ABILITY_OFFSET]
                if abilid ~= 0 then
                    -- trigger unequip event
                    if Spells[abilid] and GetUnitAbilityLevel(self.holder, abilid) > 0 then
                        Spells[abilid].onUnequip(self, abilid)
                    end
                    -- remove ability after cooldown expires
                    TimerQueue:callDelayed(BlzGetUnitAbilityCooldownRemaining(self.holder, abilid), remove_item_ability, self, self.holder, abilid)
                end
            end

            if self.equipped then
                self.equipped = false

                apply_item_stats(self, -1)
            end

            SetItemPosition(self.obj, x or GetUnitX(self.holder), y or GetUnitY(self.holder))
            SetItemVisible(self.obj, true)
            SoundHandler("Sound\\Interface\\HeroDropItem1.flac", true, self.owner, self.holder)

            Profile[self.pid].hero.items[self.index] = nil
            self.holder = nil
            self.index = nil
        end

        ---@type fun(itm: Item, index: integer, value: integer): string
        local function ParseItemAbilityTooltip(itm, index, value)
            local data   = ItemData[itm.id][index * ABILITY_OFFSET .. "abil"] ---@type string 
            local id     = ItemData[itm.id][index * ABILITY_OFFSET] ---@type integer 
            local orig   = BlzGetAbilityExtendedTooltip(id, 0) ---@type string 
            local count  = 1
            local values = {} ---@type integer[] 

            values[0] = value

            -- parse ability data into array
            for v in data:gmatch("(\x25-?\x25d+)") do
                values[count] = v
                ItemData[itm.id][index * ABILITY_OFFSET + count] = v
                count = count + 1
            end

            -- parse ability tooltip and fill capture groups
            orig = orig:gsub("\x25$(\x25d+)", function(tag)
                return values[tonumber(tag) - 1] .. ""
            end)

            return orig
        end

        local parse_item_stat = {
            [ITEM_ABILITY] = function(self, index, value, lower, upper, valuestr, range)
                local s = ParseItemAbilityTooltip(self, index, value)

                return (s:len() > 0 and "|n" .. s) or ""
            end,

            default = function(self, index, value, lower, upper, valuestr, range, posneg)
                local suffix = STAT_TAG[index].item_suffix or STAT_TAG[index].suffix or "|r"

                if range ~= 0 then
                    return "|n + |cffffcc00" .. lower .. "-" .. upper .. suffix .. " " .. STAT_TAG[index].tag
                else
                    return "|n " .. posneg .. valuestr .. suffix .. " " .. STAT_TAG[index].tag
                end
            end
        }

        parse_item_stat[ITEM_ABILITY2] = parse_item_stat[ITEM_ABILITY]

        function thistype:update()
            local orig    = ItemData[self.id][ITEM_TOOLTIP] ---@type string 
            local norm_new   = "" ---@type string 
            local alt_new = "" ---@type string 

            --first "header" lines: rarity, upg level, tier, type, req level
            if self.level > 0 then
                norm_new = norm_new .. (LEVEL_PREFIX[self.level])

                BlzSetItemSkin(self.obj, ITEM_MODEL[self.level])

                norm_new = norm_new .. " +" .. self.level

                norm_new = norm_new .. "|n"
            end

            norm_new = norm_new .. TIER_NAME[ItemData[self.id][ITEM_TIER]] .. " " .. TYPE_NAME[ItemData[self.id][ITEM_TYPE]]

            if ItemData[self.id][ITEM_LEVEL_REQUIREMENT] > 0 then
                norm_new = norm_new .. "|n|cffff0000Level Requirement: |r" .. ItemData[self.id][ITEM_LEVEL_REQUIREMENT]
            end

            norm_new = norm_new .. "|n"
            alt_new = norm_new

            --body stats
            for index = 1, ITEM_STAT_TOTAL do
                local value = self:getValue(index, 0)

                --write non-zero stats
                if value ~= 0 then
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
                    local range = ItemData[self.id][index .. "range"]
                    if parse_item_stat[index] then
                        alt_new = alt_new .. parse_item_stat[index](self, index, value, lower, upper, valuestr, range)
                    else
                        alt_new = alt_new .. parse_item_stat.default(self, index, value, lower, upper, valuestr, range, posneg)
                    end

                    --normal tooltip
                    if index == ITEM_ABILITY or index == ITEM_ABILITY2 then
                        norm_new = norm_new .. parse_item_stat[index](self, index, value, 0, 0)
                    else
                        norm_new = norm_new .. "|n " .. posneg .. valuestr .. (STAT_TAG[index].item_suffix or STAT_TAG[index].suffix or "") .. " " .. STAT_TAG[index].tag
                    end
                end
            end

            --flavor text
            --remove bracket pairs, extra spaces, and extra newlines
            orig = "|n" .. orig:gsub("(\x25b[]\x25s*)", "")
            orig = (orig:len() > 5 and ("|n" .. orig)) or ""

            self.tooltip = norm_new .. orig
            self.alt_tooltip = alt_new .. orig

            if ItemData[self.id][ITEM_LIMIT] > 0 then
                self.tooltip = self.tooltip .. "|cff808080|nLimit: 1"
                self.alt_tooltip = self.alt_tooltip .. "|cff808080|nLimit: 1"
            end

            BlzSetItemIconPath(self.obj, ItemData[self.id].path)
            BlzSetItemName(self.obj, ItemData[self.id].name)
            BlzSetItemDescription(self.obj, self.tooltip)
            BlzSetItemExtendedTooltip(self.obj, self.tooltip)

            -- TODO: Update inventory frames here?
        end

        ---@type fun(id: integer, stats: integer): Item|nil
        function thistype.decode(id, stats)
            if id == 0 then
                return nil
            end

            local itemid = id & 0x1FFF
            local itm = CreateItem(CUSTOM_ITEM_OFFSET + itemid, 30000., 30000.)
            local mask = 0x7E000
            itm.level = (id & mask) >> 13

            for i = 1, 2 do
                mask = mask << 6
                itm.quality[i] = (id & mask)
            end

            local shift = 0
            mask = 0x3F

            for i = 3, QUALITY_SAVED do
                itm.quality[i] = (stats & mask) >> shift

                mask = (mask << 6)
                shift = shift + 6
            end

            itm:lvl(itm.level)

            return itm
        end

        --save 5 more quality integers, 6 bits for each
        ---@return integer
        function thistype:encode_stats()
            local id = 0

            for i = 3, 7 do
                id = id + self.quality[i] << ((i - 3) * 6)
            end

            return id
        end

        --from least to most significant: first 13 bits for id, next 6 for level, 6 for each quality
        ---@type fun(self: Item): integer
        function thistype:encode_id()
            local id = ItemToIndex(self.id)

            if id == nil then
                return 0
            end

            id = id + (self.level << 13)

            for i = 1, 2 do
                id = id + (self.quality[i] << (13 + i * 6))
            end

            return id
        end

        function thistype:onDestroy()
            if self.sfx then
                DestroyEffect(self.sfx)
            end

            -- proper removal
            DestroyTrigger(self.trig)
            SetWidgetLife(self.obj, 1.)
            RemoveItem(self.obj)
        end

        function thistype:destroy()
            self:onDestroy()

            self = nil
        end

        ---@type fun(itm: Item)
        function thistype.expire(itm)
            if not itm.holder and not itm.owner then
                itm:destroy()
            end
        end
    end

local function recharge_cd(pid)
    if RECHARGE_COOLDOWN[pid] > 0 then
        RECHARGE_COOLDOWN[pid] = RECHARGE_COOLDOWN[pid] - 1
        TimerQueue:callDelayed(1., recharge_cd, pid)
    end
end

---@return boolean
function RechargeItem()
    local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw    = DialogWindow[pid] ---@type DialogWindow 
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        local itm = GetResurrectionItem(pid, true) ---@type Item?
        local gold, plat = dw.data[index][1], dw.data[index][2]

        if itm then
            itm.charges = itm.charges + 1

            if GetCurrency(pid, GOLD) >= gold and GetCurrency(pid, PLATINUM) >= plat then
                AddCurrency(pid, GOLD, -gold)
                AddCurrency(pid, PLATINUM, -plat)

                local message

                if plat > 0 then
                    message = message .. "\nRecharged " .. GetItemName(itm.obj) .. " for " .. RealToString(plat) .. " Platinum and " .. RealToString(gold) .. " Gold."
                else
                    message = message .. "\nRecharged " .. GetItemName(itm.obj) .. " for " .. RealToString(gold) .. " Gold."
                end
                DisplayTextToPlayer(Player(pid - 1), 0, 0, message)
            end
            TimerQueue:callDelayed(1., recharge_cd, pid)
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
    local goldCost     = ItemData[itm.id][ITEM_COST] * 100 * percentage + playerGold * percentage ---@type number 
    local platCost     = GetCurrency(pid, PLATINUM) * percentage ---@type number 
    local dw           = DialogWindow.create(pid, "", RechargeItem) ---@type DialogWindow 

    goldCost = goldCost + (platCost - R2I(platCost)) * 1000000
    platCost = R2I(platCost)

    if platCost > 0 then
        message = message .. "\nRecharge cost:|n|cffffffff" .. RealToString(platCost) .. "|r |cffe3e2e2Platinum|r, |cffffffff" .. RealToString(goldCost) .. "|r |cffffcc00Gold|r|n"
    else
        message = message .. "\nRecharge cost:|n|cffffffff" .. RealToString(goldCost) .. " |cffffcc00Gold|r|n"
    end

    dw.title = message

    if GetCurrency(pid, GOLD) >= goldCost and GetCurrency(pid, PLATINUM) >= platCost then
        dw:addButton("Recharge", {goldCost, platCost})
    end

    dw:display()
end

---@param pid integer
---@param itemid integer
function KillQuestHandler(pid, itemid)
    local index         = KillQuest[itemid][0] ---@type integer 
    local min           = KillQuest[index].min ---@type integer 
    local max           = KillQuest[index].max ---@type integer 
    local avg           = (min + max) // 2
    local goal          = KillQuest[index].goal ---@type integer 
    local playercount   = 0 ---@type integer 
    local U             = User.first ---@type User 
    local p             = Player(pid - 1)
    local x             = 0.
    local y             = 0.
    local myregion      = nil ---@type rect 

    if GetUnitLevel(Hero[pid]) < min then
        DisplayTimedTextToPlayer(p, 0,0, 10, "You must be level |cffffcc00" .. (min) .. "|r to begin this quest.")
    elseif GetUnitLevel(Hero[pid]) > max then
        DisplayTimedTextToPlayer(p, 0,0, 10, "You are too high level to do this quest.")
    --Progress
    elseif KillQuest[index].status == 1 then
        DisplayTimedTextToPlayer(p, 0,0, 10, "Killed " .. (KillQuest[index].count) .. "/" .. (goal) .. " " .. KillQuest[index].name)
        PingMinimap(GetRectCenterX(KillQuest[index].region), GetRectCenterY(KillQuest[index].region), 3)
    --Start Quest
    elseif KillQuest[index].status == 0 then
        KillQuest[index].status = 1
        DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00QUEST:|r Kill " .. (goal) .. " " .. KillQuest[index].name .. " for a reward.")
        PingMinimap(GetRectCenterX(KillQuest[index].region), GetRectCenterY(KillQuest[index].region), 5)
    --Completion
    elseif KillQuest[index].status == 2 then
        while U do
            if Profile[U.id].playing and GetUnitLevel(Hero[U.id]) >= min and GetUnitLevel(Hero[U.id]) <= max then
                playercount = playercount + 1
            end

            U = U.next
        end

        U = User.first

        while U do
            if GetHeroLevel(Hero[U.id]) >= min and GetHeroLevel(Hero[U.id]) <= max then
                DisplayTimedTextToPlayer(U.player, 0, 0, 10, "|c00c0c0c0" .. KillQuest[index].name .. " quest completed!|r")
                local GOLD = GOLD_TABLE[avg] * goal * 0.5 / (0.5 + playercount * 0.5)
                AwardGold(U.id, GOLD, true)
                local XP = floor(EXPERIENCE_TABLE[max] * XP_Rate[U.id] * goal * 0.0008) / (0.5 + playercount * 0.5)
                AwardXP(U.id, XP)
            end

            U = U.next
        end

        --reset
        KillQuest[index].status = 1
        KillQuest[index].count = 0
        KillQuest[index].goal = IMinBJ(goal + 3, 100)

        --increase max spawns based on last unit killed (until max goal of 100 is reached)
        if (KillQuest[index].goal) < 100 and ModuloInteger(KillQuest[index].goal, 2) == 0 then
            myregion = SelectGroupedRegion(UnitData[KillQuest[index].last].spawn)
            repeat
                x = GetRandomReal(GetRectMinX(myregion), GetRectMaxX(myregion))
                y = GetRandomReal(GetRectMinY(myregion), GetRectMaxY(myregion))
            until IsTerrainWalkable(x, y)
            CreateUnit(PLAYER_CREEP, KillQuest[index].last, x, y, GetRandomInt(0, 359))
            DisplayTimedTextToForce(FORCE_PLAYING, 20., "An additional " .. GetObjectName(KillQuest[index].last) .. " has spawned in the area.")
        end
    end
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
            ablev = GetUnitAbilityLevel(Backpack[dw.pid], TELEPORT_HOME.id)
            SetUnitAbilityLevel(Backpack[dw.pid], TELEPORT_HOME.id, ablev + 1)
            SetUnitAbilityLevel(Backpack[dw.pid], TELEPORT.id, ablev + 1)
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
local function SalvageItem()
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
local function UpgradeItemConfirm()
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

local function BuyItem()
    local u   = GetTriggerUnit() ---@type unit 
    local b   = GetBuyingUnit() ---@type unit 
    local pid = GetPlayerId(GetOwningPlayer(b)) + 1 ---@type integer 
    local itm = CreateItem(GetSoldItem()) ---@type Item 

    itm.owner = Player(pid - 1)

    if ON_BUY_LOOKUP[itm.id] then
        ON_BUY_LOOKUP[itm.id](u, b, pid, itm)
    end

    return false
end

local function UseItem()
    local u   = GetTriggerUnit() ---@type unit 
    local p   = GetOwningPlayer(u)
    local pid = GetPlayerId(p) + 1 ---@type integer 
    local itm = Item[GetManipulatedItem()] ---@type Item?

    if itm then
        local abil = ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET]

        -- find pot spell
        for _, v in pairs(POTIONS) do -- sync safe
            if v[abil] then
                v[abil](pid, itm)
                break
            end
        end
    end

    return false
end

local stat_enum = {
    "|cff990000Strength|r",
    "|cff006600Agility|r",
    "|cff3333ffIntelligence|r",
    "All Stats",
}

---@type fun(pid: integer, bonus: number, type: integer)
local function StatTome(pid, bonus, type)
    if type == 1 then
        Unit[Hero[pid]].str = Unit[Hero[pid]].str + bonus
    elseif type == 2 then
        Unit[Hero[pid]].agi = Unit[Hero[pid]].agi + bonus
    elseif type == 3 then
        Unit[Hero[pid]].int = Unit[Hero[pid]].int + bonus
    elseif type == 4 then
        Unit[Hero[pid]].str = Unit[Hero[pid]].str + bonus
        Unit[Hero[pid]].agi = Unit[Hero[pid]].agi + bonus
        Unit[Hero[pid]].int = Unit[Hero[pid]].int + bonus
    end

    DisplayTextToPlayer(Player(pid - 1), 0, 0, "You have gained |cffffcc00" .. bonus .. "|r " .. stat_enum[type])

    DestroyEffect(AddSpecialEffectTarget("Objects\\InventoryItems\\tomeRed\\tomeRed.mdl", Hero[pid], "origin"))
    DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIam\\AIamTarget.mdl", Hero[pid], "origin"))
end

local function stat_purchase()
    local p   = GetTriggerPlayer()
    local pid = GetPlayerId(p) + 1 ---@type integer 
    local dw    = DialogWindow[pid] ---@type DialogWindow 
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        local count = dw.data[index]
        local currency = (count <= 20 and GOLD) or PLATINUM
        local cost = (currency == GOLD and count * 10000) or (count // 100)

        if GetCurrency(pid, currency) >= cost then
            AddCurrency(pid, currency, -cost)
            StatTome(pid, dw.data[10], dw.data[100])
        else
            DisplayTextToPlayer(p, 0., 0., "You do not have enough money!")
        end

        dw:destroy()
    end

    return false
end

local function stat_confirm()
    local p   = GetTriggerPlayer()
    local pid = GetPlayerId(p) + 1 ---@type integer 
    local dw    = DialogWindow[pid] ---@type DialogWindow 
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        local count = dw.data[index]
        local type = dw.data[100]
        local final_bonus = 0
        local total_stats = Unit[Hero[pid]].str + Unit[Hero[pid]].agi + Unit[Hero[pid]].int
        local tome_cap = TomeCap(GetHeroLevel(Hero[pid]))
        local name = stat_enum[type]

        dw:destroy()

        for _ = 1, count do
            final_bonus = final_bonus + 100 // ((total_stats + final_bonus) ^ 0.25) * (log(tome_cap / (total_stats + final_bonus) + 0.75, 2.71828) / 3.)
            if total_stats + final_bonus >= tome_cap then
                final_bonus = tome_cap - total_stats
                break
            end
        end

        final_bonus = floor(final_bonus)
        if final_bonus > 0 then
            dw = DialogWindow.create(pid, "Purchase " .. final_bonus .. " " .. name .. "?", stat_purchase)

            dw.data[10] = final_bonus
            dw.data[100] = type
            dw:addButton("Confirm", count)

            dw:display()
        else
            DisplayTextToPlayer(p, 0, 0, "You cannot gain any more stats.")
        end
    end

    return false
end

local function stat_dialog(pid, type)
    local name = stat_enum[type]
    local dw = DialogWindow.create(pid, "Purchase " .. name, stat_confirm)
    local prefix = (type == 4 and "2") or "1"
    local mult = (type == 4 and 2) or 1

    dw:addButton(prefix .. "0,000 Gold", 1 * mult)
    dw:addButton(prefix .. "00,000 Gold", 10 * mult)
    dw:addButton(prefix .. " Platinum", 100 * mult)
    dw:addButton(prefix .. "0 Platinum", 1000 * mult)
    dw:addButton(prefix .. "00 Platinum", 10000 * mult)
    dw.data[100] = type

    dw:display()
end

local function PickItem()
    local u = GetTriggerUnit() ---@type unit 
    local itm = Item[GetManipulatedItem()] ---@type Item
    local itemid = (itm and GetItemTypeId(itm.obj)) or 0
    local itemtype = (itm and GetItemType(itm.obj)) or 0
    local p = GetOwningPlayer(u)
    local pid = GetPlayerId(p) + 1 ---@type integer 
    local U = User.first ---@type User 

    -- ignore non-player inventories
    if pid > PLAYER_CAP then
        return false
    end

    -- items are always dropped now
    UnitRemoveItem(u, itm.obj)

    if BlzGetItemBooleanField(itm.obj, ITEM_BF_USE_AUTOMATICALLY_WHEN_ACQUIRED) == false then
        itm.pid = pid
        itm:equip(nil, u)
    end

    INVENTORY.refresh(pid)

    -- check item lookup table
    if ITEM_LOOKUP[itemid] then
        ITEM_LOOKUP[itemid](p, pid, u, itm)
    end

    -- kill quests
    if KillQuest[itemid][0] ~= 0 and itemtype == ITEM_TYPE_CAMPAIGN then
        KillQuestHandler(pid, itemid)

    -- Buyables / Shops
    -- church donation
    elseif itemid == FourCC('I07Q') and not CHURCH_DONATION[pid] then
        ChargeNetworth(p, 0, 0.01, 100, "")
        CHURCH_DONATION[pid] = true
        donation = donation - donationrate
        DisplayTextToPlayer(p, 0, 0, "|c00408080The Goddesses bestow their blessings.")
        DisplayTextToForce(FORCE_PLAYING, "Reduced bad weather chance: " .. (R2I((1 - donation) * 100)) .. "\x25")
    -- upgrade teleports & reveal
    elseif itemid == FourCC('I101') or itemid == FourCC('I102') then
        local lvl = (itemid == FourCC('I101') and GetUnitAbilityLevel(Backpack[pid], TELEPORT.id)) or GetUnitAbilityLevel(Backpack[pid], FourCC('A0FK'))

        if lvl < 10 then -- 10 upgrade limit
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
    -- upgrade (boss) items
    elseif itemid == FourCC('I100') then
        local dw = DialogWindow.create(pid, "Choose an item to upgrade.", UpgradeItem) ---@type DialogWindow

        for index = 1, MAX_INVENTORY_SLOTS do
            local it = Profile[pid].hero.items[index]

            if it and ItemData[it.id][ITEM_UPGRADE_MAX] > it.level then
                dw:addButton(it:name(), it)
            end
        end

        dw:display()
    -- salvage (boss) items
    elseif itemid == FourCC('I01R') then
        local dw = DialogWindow.create(pid, "Choose an item to salvage.", SalvageItem) ---@type DialogWindow

        for index = 1, MAX_INVENTORY_SLOTS do
            local it = Profile[pid].hero.items[index]

            if it and ItemData[it.id][ITEM_COST] > 0 then
                dw:addButton(it:name(), it)
            end

        end

        dw:display()
    -- recharge reincarnation
    elseif itemid == FourCC('I0JS') then
        local it = GetResurrectionItem(pid, true)

        if it and GetItemCharges(it.obj) >= MAX_REINCARNATION_CHARGES then
            it = nil
        end

        if it == nil then
            DisplayTimedTextToPlayer(p, 0, 0, 15, "You have no item to recharge!")
        elseif RECHARGE_COOLDOWN[pid] >= 1 then
            DisplayTimedTextToPlayer(p, 0, 0,15, (RECHARGE_COOLDOWN[pid]) .. " seconds until you can recharge your " .. GetItemName(it.obj))
        else
            RechargeDialog(pid, it)
        end

    --=====================================
    --Struggle / Training / PVP
    --=====================================
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
                for i = 1, PLAYER_CAP do
                    if IsUnitInGroup(Hero[i], ug) then
                        DisplayTextToPlayer(Player(i-1),0,0, "Maximum level difference is |cffffcc0080|r levels.")
                    end
                end
            else
                Struggle_Pcount = 0
                GoldWon_Struggle = 0
                while true do --start struggle
                    u = FirstOfGroup(ug)
                    if u == nil then break end
                    pid = GetPlayerId(GetOwningPlayer(u)) + 1
                    GroupRemoveUnit(ug, u)
                    if u == Hero[pid] and not Unit[Hero[pid]].busy then
                        IS_IN_STRUGGLE[pid] = true
                        Struggle_Pcount = Struggle_Pcount + 1
                        IS_FLEEING[pid] = false
                        DisableItems(pid, true)
                        MoveHeroLoc(pid, StruggleCenter)
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
    end

    return false
end

    -- tomes
    ITEM_LOOKUP[FourCC('I0TS')] = function(p, pid) -- str
        stat_dialog(pid, 1)
    end
    ITEM_LOOKUP[FourCC('I0TA')] = function(p, pid) -- agi
        stat_dialog(pid, 2)
    end
    ITEM_LOOKUP[FourCC('I0TI')] = function(p, pid) -- int
        stat_dialog(pid, 3)
    end
    ITEM_LOOKUP[FourCC('I0TT')] = function(p, pid) -- all
        stat_dialog(pid, 4)
    end

    ITEM_LOOKUP[FourCC('I0N0')] = function(p, pid) -- focus grimoire
        local refund = 0
        if Unit[Hero[pid]].str - 50 > 20 then
            Unit[Hero[pid]].str = Unit[Hero[pid]].str - 50
            refund = refund + 5000
        elseif Unit[Hero[pid]].str >= 20 then
            Unit[Hero[pid]].str = 20
        end
        if Unit[Hero[pid]].agi - 50 > 20 then
            Unit[Hero[pid]].agi = Unit[Hero[pid]].agi - 50
            refund = refund + 5000
        elseif Unit[Hero[pid]].agi >= 20 then
            Unit[Hero[pid]].agi = 20
        end
        if Unit[Hero[pid]].int - 50 > 20 then
            Unit[Hero[pid]].int = Unit[Hero[pid]].int - 50
            refund = refund + 5000
        elseif Unit[Hero[pid]].int >= 20 then
            Unit[Hero[pid]].int = 20
        end
        if refund > 0 then
            AddCurrency(pid, GOLD, refund)
            DisplayTextToPlayer(p, 0, 0, "You have been refunded |cffffcc00" .. RealToString(refund) .. "|r gold.")
        end
    end

    ITEM_LOOKUP[FourCC('I0JN')] = function(p, pid) -- retraining
        UnitAddItemById(Hero[pid], FourCC('Iret'))
    end

    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_USE_ITEM, UseItem)
    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, PickItem)
    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SELL_ITEM, BuyItem)
end, Debug and Debug.getLine())
