library Items requires Functions, Commands, Dungeons, PVP, Chaos

    globals
        integer array BuffMovespeed
        integer array ItemMovespeed
        integer array EvasionBonus
        integer array ItemEvasion
        real array ItemMagicRes
        real array ItemDamageRes
        real array ItemSpellboost
        integer array ItemGoldRate
        boolean array donated
        constant real donationrate = 0.1
        button array slotitem
        timer array rezretimer
        integer array ColoCount_main
        integer array ColoEnemyType_main
        integer array ColoCount_sec
        integer array ColoEnemyType_sec
        integer TrainerSpawn = 0
        integer TrainerSpawnChaos = 0
        boolean hordequest = false
        dialog array PvpDialog
        button array PvpButton
        boolean array dropflag
        boolean array ItemsDisabled
        string array TIER_NAME
        string array TYPE_NAME
        string array STAT_NAME
        string array LEVEL_PREFIX
        string array SPRITE_RARITY
        real array ITEM_MULT
        integer array CRYSTAL_PRICE
        integer array PROF
        string array LIMIT_STRING
    endglobals

    struct Item
        item obj            = null
        unit holder         = null
        player owner        = null
        trigger trig        = null
        integer level       = 0
        integer id          = 0
        integer charges     = 1
        string tooltip      = ""
        string alt_tooltip  = ""
        real x              = 0.
        real y              = 0.

        integer array quality[7]

        static boolexpr eval

        static method operator [] takes item itm returns thistype
            return Item(GetItemUserData(itm))
        endmethod

        method operator name takes nothing returns string
            local string s = ""

            if this.level > 0 then
                set s = s + LEVEL_PREFIX[this.level] + " "
            endif

            set s = s + GetObjectName(this.id)

            if ModuloInteger(IMaxBJ(this.level - 1, 0), 4) != 0 then
                set s = s + " +" + I2S(ModuloInteger(IMaxBJ(this.level - 1, 0), 4))
            endif

            return s
        endmethod

        method operator charge= takes integer num returns nothing
            set .charges = num
            call SetItemCharges(this.obj, num)
        endmethod

        method operator lvl= takes integer lvl returns nothing
            call .unequip()
            set this.level = lvl
            call .update()
            call .equip()
        endmethod

        method useInRecipe takes nothing returns nothing
            if charges > 1 then
                set charge = charges - 1
            else
                call destroy()
            endif
        endmethod

        method calcStat takes integer STAT, integer flag returns integer
            local integer flatPerLevel = ItemData[.id][STAT + BOUNDS_OFFSET * 2]
            local integer flatPerRarity = ItemData[.id][STAT + BOUNDS_OFFSET * 3]
            local real percent = ItemData[.id][STAT + BOUNDS_OFFSET * 4] * 0.01
            local integer unlockat = ItemData[.id][STAT + BOUNDS_OFFSET * 5]
            local integer fixed = ItemData[.id][STAT + BOUNDS_OFFSET * 6]
            local real lower = ItemData[.id][STAT] 
            local real upper = ItemData[.id][STAT + BOUNDS_OFFSET] 
            local boolean hasVariance = (upper != 0)
            local integer count = 0
            local integer index = 0
            local integer final = 0

            if .level < unlockat then
                return 0
            endif

            if percent > 0 then
                set lower = lower + ((flatPerLevel * .level + flatPerRarity * (IMaxBJ(.level - 1, 0) / 4)) * percent)
                set upper = upper + ((flatPerLevel * .level + flatPerRarity * (IMaxBJ(.level - 1, 0) / 4)) * percent)
            else
                set lower = lower + flatPerLevel * .level + flatPerRarity * (IMaxBJ(.level - 1, 0) / 4)
                set upper = upper + flatPerLevel * .level + flatPerRarity * (IMaxBJ(.level - 1, 0) / 4)
            endif

            if fixed == 0 then
                if percent > 0 then
                    set lower = lower + lower * ITEM_MULT[.level] * percent
                    set upper = upper + upper * ITEM_MULT[.level] * percent
                else
                    set lower = lower + lower * ITEM_MULT[.level]
                    set upper = upper + upper * ITEM_MULT[.level]
                endif
            endif

            if flag == 1 then
                return R2I(lower)
            elseif flag == 2 then
                return R2I(upper)
            else
                if hasVariance then
                    //find the quality index
                    loop
                        exitwhen index == STAT

                        if ItemData[this.id][index + BOUNDS_OFFSET] != 0 then
                            set count = count + 1
                        endif

                        set index = index + 1
                    endloop

                    set final = R2I(lower + (upper - lower) * 0.015625 * (1 + this.quality[count]))
                else
                    set final = R2I(lower)
                endif

                if ModuloInteger(final, 1000) == 999 or ModuloInteger(final, 100) == 99 then
                    set final = final + 1
                endif

                return final
            endif
        endmethod

        method equip takes nothing returns nothing
            local integer pid = GetPlayerId(GetOwningPlayer(this.holder)) + 1
            local real hp = GetWidgetLife(this.holder)
            local real mana = GetUnitState(this.holder, UNIT_STATE_MANA)
            local real mod = ItemProfMod(this.id, pid)
            local timer t

            if this.holder == null then
                return
            endif

            call UnitAddBonus(this.holder, BONUS_ARMOR, R2I(mod * .calcStat(ITEM_ARMOR, 0)))
            call UnitAddBonus(this.holder, BONUS_DAMAGE, R2I(mod * .calcStat(ITEM_DAMAGE, 0) * (1. + Dmg_mod[pid] * 0.01)))
            call UnitAddBonus(this.holder, BONUS_HERO_STR, R2I(mod * .calcStat(ITEM_STRENGTH, 0) * 1. + Str_mod[pid] * 0.01))
            call UnitAddBonus(this.holder, BONUS_HERO_AGI, R2I(mod * .calcStat(ITEM_AGILITY, 0) * (1. + Agi_mod[pid] * 0.01)))
            call UnitAddBonus(this.holder, BONUS_HERO_INT, R2I(mod * .calcStat(ITEM_INTELLIGENCE, 0) * (1. + Int_mod[pid] * 0.01)))
            call BlzSetUnitMaxHP(this.holder, BlzGetUnitMaxHP(this.holder) + R2I(mod * .calcStat(ITEM_HEALTH, 0)))
            call BlzSetUnitMaxMana(this.holder, BlzGetUnitMaxMana(this.holder) + R2I(mod * .calcStat(ITEM_MANA, 0)))
            call SetWidgetLife(this.holder, hp)
            call SetUnitState(this.holder, UNIT_STATE_MANA, mana)

            set ItemRegen[pid] = ItemRegen[pid] + .calcStat(ITEM_REGENERATION, 0)
            set ItemMagicRes[pid] = ItemMagicRes[pid] * (1 - .calcStat(ITEM_MAGIC_RESIST, 0) * 0.01)
            set ItemDamageRes[pid] = ItemDamageRes[pid] * (1 - .calcStat(ITEM_DAMAGE_RESIST, 0) * 0.01)
            set ItemEvasion[pid] = ItemEvasion[pid] + .calcStat(ITEM_EVASION, 0)
            set ItemMovespeed[pid] = ItemMovespeed[pid] + .calcStat(ITEM_MOVESPEED, 0)
            set ItemSpellboost[pid] = ItemSpellboost[pid] + .calcStat(ITEM_SPELLBOOST, 0) * 0.01
            set ItemGoldRate[pid] = ItemGoldRate[pid] + .calcStat(ITEM_GOLD_GAIN, 0)

            //shield
            if ItemData[.id][ITEM_TYPE] == 5 then
                set ShieldCount[pid] = ShieldCount[pid] + 1
            endif

            call BlzSetUnitAttackCooldown(this.holder, BlzGetUnitAttackCooldown(this.holder, 0) / (1 + .calcStat(ITEM_BASE_ATTACK_SPEED, 0) * 0.01), 0)
                    
            //profiency warning
            if GetUnitLevel(this.holder) < 15 and mod < 1 then
                call DisplayTimedTextToPlayer(this.owner, 0, 0, 10, "You lack the proficiency (-pf) to use this item, it will only give 75% of most stats.\n|cffFF0000You will stop getting this warning at level 15.|r")
            endif
        endmethod

        method unequip takes nothing returns nothing
            local integer pid = GetPlayerId(GetOwningPlayer(this.holder)) + 1
            local real hp = GetWidgetLife(this.holder)
            local real mana = GetUnitState(this.holder, UNIT_STATE_MANA)
            local real mod = ItemProfMod(this.id, pid)

            if this.holder == null then
                return
            endif

            call UnitAddBonus(this.holder, BONUS_ARMOR, -R2I(mod * .calcStat(ITEM_ARMOR, 0)))
            call UnitAddBonus(this.holder, BONUS_DAMAGE, -R2I(mod * .calcStat(ITEM_DAMAGE, 0) * (1. + Dmg_mod[pid] * 0.01)))
            call UnitAddBonus(this.holder, BONUS_HERO_STR, -R2I(mod * .calcStat(ITEM_STRENGTH, 0) * 1. + Str_mod[pid] * 0.01))
            call UnitAddBonus(this.holder, BONUS_HERO_AGI, -R2I(mod * .calcStat(ITEM_AGILITY, 0) * (1. + Agi_mod[pid] * 0.01)))
            call UnitAddBonus(this.holder, BONUS_HERO_INT, -R2I(mod * .calcStat(ITEM_INTELLIGENCE, 0) * (1. + Int_mod[pid] * 0.01)))
            call BlzSetUnitMaxHP(this.holder, BlzGetUnitMaxHP(this.holder) - R2I(mod * .calcStat(ITEM_HEALTH, 0)))
            call BlzSetUnitMaxMana(this.holder, BlzGetUnitMaxMana(this.holder) - R2I(mod * .calcStat(ITEM_MANA, 0)))
            call SetWidgetLife(this.holder, RMaxBJ(hp, 1))
            call SetUnitState(this.holder, UNIT_STATE_MANA, mana)

            set ItemRegen[pid] = ItemRegen[pid] - .calcStat(ITEM_REGENERATION, 0)
            set ItemMagicRes[pid] = ItemMagicRes[pid] / (1 - .calcStat(ITEM_MAGIC_RESIST, 0) * 0.01)
            set ItemDamageRes[pid] = ItemDamageRes[pid] / (1 - .calcStat(ITEM_DAMAGE_RESIST, 0) * 0.01)
            set ItemEvasion[pid] = ItemEvasion[pid] - .calcStat(ITEM_EVASION, 0)
            set ItemMovespeed[pid] = ItemMovespeed[pid] - .calcStat(ITEM_MOVESPEED, 0)
            set ItemSpellboost[pid] = ItemSpellboost[pid] - .calcStat(ITEM_SPELLBOOST, 0) * 0.01
            set ItemGoldRate[pid] = ItemGoldRate[pid] - .calcStat(ITEM_GOLD_GAIN, 0)

            //shield
            if ItemData[.id][ITEM_TYPE] == 5 then
                set ShieldCount[pid] = ShieldCount[pid] - 1
            endif

            call BlzSetUnitAttackCooldown(this.holder, BlzGetUnitAttackCooldown(this.holder, 0) * (1 + .calcStat(ITEM_BASE_ATTACK_SPEED, 0) * 0.01), 0)
        endmethod

        method toDud takes nothing returns nothing
            local unit held = this.holder

            set this.charge = GetItemCharges(this.obj)

            call DestroyTrigger(this.trig)
            call RemoveItem(this.obj)

            set this.obj = CreateItem('iDud', GetUnitX(this.holder), GetUnitY(this.holder))
            call SetItemUserData(this.obj, this)
            call UnitAddItem(held, this.obj)

            //reapply death event
            set this.trig = CreateTrigger()
            call TriggerRegisterDeathEvent(this.trig, this.obj)
            call TriggerAddCondition(this.trig, thistype.eval)

            call .update()

            set held = null
        endmethod

        method toItem takes nothing returns nothing
            local integer slot = GetItemSlot(this.obj, this.holder)
            local unit held = this.holder

            call DestroyTrigger(this.trig)
            call RemoveItem(this.obj)

            set this.obj = CreateItem(this.id, this.x, this.y)
            call SetItemUserData(this.obj, this)
            set this.charge = this.charges

            if held != null then
                call UnitAddItem(held, this.obj)
                call UnitDropItemSlot(held, this.obj, slot)
            endif

            //reapply death event
            set this.trig = CreateTrigger()
            call TriggerRegisterDeathEvent(this.trig, this.obj)
            call TriggerAddCondition(this.trig, thistype.eval)

            call .update()
        endmethod

        method update takes nothing returns nothing
            local string orig = ItemData[this.id].string[0]
            local string new = ""
            local string alt_new = ""
            local integer i = 0
            local integer i2 = 1
            local integer start = 0
            local integer index = ITEM_HEALTH - 1
            local integer count = 0
            local integer value = 0
            local integer lower = 0
            local integer upper = 0
            local integer newlines = 0
            local string posneg = ""
            local string valuestr = ""

            //first "header" lines: rarity, upg level, tier, type, req level
            if this.level > 0 then
                set new = new + LEVEL_PREFIX[this.level]

                //rarity level does not say +0
                if ModuloInteger(IMaxBJ(this.level - 1, 0), 4) != 0 then
                    set new = new + " +" + I2S(ModuloInteger(IMaxBJ(this.level - 1, 0), 4))
                endif

                set new = new + "\n"
            endif

            set new = new + TIER_NAME[ItemData[this.id][ITEM_TIER]] + " " + TYPE_NAME[ItemData[this.id][ITEM_TYPE]]

            if ItemData[this.id][ITEM_LEVEL_REQUIREMENT] > 0 then
                set new = new + "\n|cffff0000Level Requirement: |r" + I2S(ItemData[this.id][ITEM_LEVEL_REQUIREMENT])
            endif

            set new = new + "\n"

            set alt_new = new

            loop
                exitwhen i2 > StringLength(orig) + 1

                if SubString(orig, i, i2) == "\\" then
                    set newlines = newlines + 1
                    set start = i2

                elseif SubString(orig, i, i2) == "[" and newlines > 0 then

                    //find next non-zero stat
                    loop
                        set index = index + 1
                        set value = .calcStat(index, 0)
                        exitwhen value != 0 or index > ITEM_STAT_TOTAL
                    endloop

                    //safety
                    if index <= ITEM_STAT_TOTAL then
                        //prevent adding a tooltip if not yet unlocked
                        if this.level >= ItemData[this.id][index + BOUNDS_OFFSET * 5] then
                            set lower = .calcStat(index, 1)
                            set upper = .calcStat(index, 2)
                            set valuestr = I2S(value)
                            set posneg = "+ |cffffcc00"

                            //negative handling
                            if value < 0 then
                                set valuestr = I2S(-value)
                                set posneg = "- |cffcc0000"
                            endif

                            if newlines == 1 then
                                //alt tooltip
                                //stat has variance
                                if ItemData[this.id][index + BOUNDS_OFFSET] != 0 then
                                    if index == ITEM_CRIT_CHANCE then
                                        set alt_new = alt_new + "\n +|cffffcc00" + I2S(lower) + "-" + I2S(upper) + "% " + I2S(.calcStat(index + 1, 1)) + "-" + I2S(.calcStat(index + 1, 2)) + "x|r |cffffcc00Critical Strike|r"
                                    elseif index == ITEM_CRIT_DAMAGE then
                                    elseif index == ITEM_ABILITY or index == ITEM_ABILITY2 then
                                        set alt_new = alt_new + "\n" + ParseItemAbilityTooltip(this, index, value, lower, upper)
                                    else
                                        set alt_new = alt_new + "\n +|cffffcc00" + I2S(lower) + "-" + I2S(upper) + STAT_NAME[index] + ""
                                    endif

                                    set count = count + 1
                                else
                                    if index == ITEM_CRIT_CHANCE then
                                        set alt_new = alt_new + "\n +|cffffcc00" + valuestr + "% " + I2S(.calcStat(index + 1, 0)) + "x|r |cffffcc00Critical Strike|r" 
                                    elseif index == ITEM_CRIT_DAMAGE then
                                    elseif index == ITEM_ABILITY or index == ITEM_ABILITY2 then
                                        set alt_new = alt_new + "\n" + ParseItemAbilityTooltip(this, index, value, 0, 0)
                                    else
                                        set alt_new = alt_new + "\n " + posneg + valuestr + STAT_NAME[index]
                                    endif
                                endif

                                //normal tooltip
                                if index == ITEM_CRIT_CHANCE then
                                    set new = new + "\n +|cffffcc00" + valuestr + "% "
                                elseif index == ITEM_CRIT_DAMAGE then
                                    set new = new + valuestr + STAT_NAME[index]
                                elseif index == ITEM_ABILITY or index == ITEM_ABILITY2 then
                                    set new = new + "\n" + ParseItemAbilityTooltip(this, index, value, 0, 0)
                                else
                                    set new = new + "\n " + posneg + valuestr + STAT_NAME[index]
                                endif
                            elseif newlines > 1 then
                                set new = new + SubString(orig, start, i) + I2S(lower)
                                set alt_new = alt_new + SubString(orig, start, i) + I2S(lower)
                            endif
                        endif
                    endif
                elseif SubString(orig, i, i2) == "]" and newlines > 1 then
                    set start = i2
                endif
            
                set i = i + 1
                set i2 = i2 + 1
            endloop

            set this.tooltip = new + SubString(orig, start, StringLength(orig))
            set this.alt_tooltip = alt_new + SubString(orig, start, StringLength(orig))

            if ItemData[this.id][ITEM_LIMIT] > 0 then
                set this.tooltip = this.tooltip + "\nLimit: 1"
                set this.alt_tooltip = this.alt_tooltip + "\nLimit: 1"
            endif

            call BlzSetItemDescription(this.obj, this.tooltip)
            call BlzSetItemExtendedTooltip(this.obj, this.tooltip)
        endmethod

        method decode takes integer id returns nothing
            local integer shift = 0
            local integer i = 2

            loop
                exitwhen i >= QUALITY_SAVED
                if id >= POWERSOF2[shift + 5] then
                    set this.quality[i] = BlzBitAnd(id, POWERSOF2[shift + 5] + POWERSOF2[shift + 4] + POWERSOF2[shift + 3] + POWERSOF2[shift + 2] + POWERSOF2[shift + 1] + POWERSOF2[shift]) / POWERSOF2[shift]
                endif

                set shift = shift + 6
                set i = i + 1
            endloop

            set .lvl = .level
        endmethod

        static method decode_id takes integer id returns thistype
            local thistype itm
            local integer itemid = BlzBitAnd(id, POWERSOF2[13] - 1)
            local integer array quality
            local integer shift = 13
            local integer i = 0

            if id == 0 then
                return 0
            endif

            //call DEBUGMSG(Id2String(CUSTOM_ITEM_OFFSET + itemid))
            //call DEBUGMSG(GetObjectName(CUSTOM_ITEM_OFFSET + itemid))

            set itm = thistype.create(CUSTOM_ITEM_OFFSET + itemid, 30000., 30000., 0.)
            set itm.level = BlzBitAnd(id, POWERSOF2[shift + 5] + POWERSOF2[shift + 4] + POWERSOF2[shift + 3] + POWERSOF2[shift + 2] + POWERSOF2[shift + 1] + POWERSOF2[shift]) / POWERSOF2[shift]

            loop
                set shift = shift + 6
                exitwhen i > 1

                if id >= POWERSOF2[shift] then
                    set itm.quality[i] = BlzBitAnd(id, POWERSOF2[shift + 5] + POWERSOF2[shift + 4] + POWERSOF2[shift + 3] + POWERSOF2[shift + 2] + POWERSOF2[shift + 1] + POWERSOF2[shift]) / POWERSOF2[shift]
                endif

                set i = i + 1
            endloop

            return itm
        endmethod

        method encode takes nothing returns integer
            local integer i = 2
            local integer id = 0

            loop
                exitwhen i > 6
                set id = id + .quality[i] * POWERSOF2[(i - 2) * 6]

                set i = i + 1
            endloop

            return id
        endmethod

        method encode_id takes nothing returns integer
            local integer i = 0
            local integer id = ItemToIndex(this.id)

            if id == 0 then
                return 0
            endif

            set id = id + .level * POWERSOF2[13 + i * 6]

            loop
                exitwhen i > 1
                set id = id + .quality[i] * POWERSOF2[13 + (i + 1) * 6]

                set i = i + 1
            endloop

            return id
        endmethod

        static method assign takes item it returns thistype
            local thistype itm = thistype.allocate()

            if it == null then
                call itm.destroy()
                return 0
            endif

            set itm.obj = it
            set itm.id = GetItemTypeId(itm.obj)
            set itm.level = 0
            set itm.trig = CreateTrigger()
            set itm.charges = GetItemCharges(itm.obj)

            //first time setup
            if ItemData[itm.id].string[0] == null then
                //if description is already set use for parse (for buyable items with stats)
                if StringLength(BlzGetItemDescription(itm.obj)) > 1 then
                    call ParseItemTooltip(itm.obj, BlzGetItemDescription(itm.obj))
                else
                    call ParseItemTooltip(itm.obj, "")
                endif
            endif

            //determine saveable (misc category yields 7 instead of ITEM_TYPE_MISCELLANEOUS 's value of 6)
            if (GetHandleId(GetItemType(itm.obj)) == 7 or GetItemType(itm.obj) == ITEM_TYPE_PERMANENT) and itm.id > CUSTOM_ITEM_OFFSET then
                call SaveInteger(SAVE_TABLE, KEY_ITEMS, itm.id, itm.id - CUSTOM_ITEM_OFFSET)
            endif

            call SetItemUserData(itm.obj, itm)
            call TriggerRegisterDeathEvent(itm.trig, itm.obj)
            call TriggerAddCondition(itm.trig, eval)

            if ItemData[itm.id][ITEM_TIER] > 0 then
                call itm.update()
            endif

            return itm
        endmethod

        static method create takes integer id, real x, real y, real expire returns thistype
            local thistype itm = thistype.assign(CreateItem(id, x, y)) 
            local integer i = ITEM_HEALTH
            local integer count = 0

            set itm.x = x
            set itm.y = y

            if expire > 0 then
                call TimerStart(NewTimerEx(itm), expire, false, function thistype.expire)
            endif

            //randomize rolls
            loop
                exitwhen i > ITEM_STAT_TOTAL or count > 6

                if ItemData[id][i + BOUNDS_OFFSET] != 0 then
                    set itm.quality[count] = GetRandomInt(0, 63)
                    set count = count + 1
                endif

                set i = i + 1
            endloop

            if ItemData[id][ITEM_TIER] > 0 then
                call itm.update()
            endif

            return itm
        endmethod

        method onDestroy takes nothing returns nothing
            local integer i = 0

            //proper removal
            call DestroyTrigger(this.trig)
            call SetWidgetLife(this.obj, 1.)
            call RemoveItem(this.obj)

            //call DEBUGMSG("Item Removed!")
            loop
                exitwhen i >= QUALITY_SAVED

                set this.quality[i] = 0
                set i = i + 1
            endloop

            set this.obj = null
            set this.id = 0
            set this.level = 0
            set this.holder = null
            set this.owner = null
            set this.tooltip = ""
            set this.alt_tooltip = ""
            set this.trig = null
            set this.x = 0
            set this.y = 0
        endmethod

        static method expire takes nothing returns nothing
            local integer itm = ReleaseTimer(GetExpiredTimer())

            if Item(itm).holder == null and Item(itm).owner == null then
                call Item(itm).destroy()
            endif
        endmethod

        static method onDeath takes nothing returns boolean
            //typecast widget to item
            call SaveWidgetHandle(MiscHash, 0, 0, GetTriggerWidget())

            call TimerStart(NewTimerEx(Item[LoadItemHandle(MiscHash, 0, 0)]), 2., false, function thistype.expire)

            call RemoveSavedHandle(MiscHash, 0, 0)
            return false
        endmethod
        
        static method onInit takes nothing returns nothing
            set thistype.eval = Condition(function thistype.onDeath)
        endmethod
    endstruct

    struct DropTable
        private static integer MAX_ITEM_COUNT = 100
        private static real ADJUST_RATE = 0.05 //percent
        public static HashTable ItemDrops
        public static Table Rates

        public static method adjustRate takes integer id, integer itemid returns nothing
            local integer i = 0
            local real adjust = 0.
            local real balance = 0.

            if itemid == 0 or ItemDrops[id][MAX_ITEM_COUNT] <= 1 then
                return
            endif

            set adjust = 1. / ItemDrops[id][MAX_ITEM_COUNT] * ADJUST_RATE
            set balance = adjust / (ItemDrops[id][MAX_ITEM_COUNT] - 1.)

            loop
                exitwhen ItemDrops[id][i] == 0

                if ItemDrops[id][i] == itemid then
                    set ItemDrops[id].real[i] = ItemDrops[id].real[i] - adjust
                else
                    set ItemDrops[id].real[i] = ItemDrops[id].real[i] + balance
                endif

                set i = i + 1
            endloop
        endmethod

        private static method calcRates takes integer id returns nothing
            local integer i = 0
            local integer j = 0
            local integer k = 0
            local real rate = 0.

            loop
                exitwhen j == 2

                //count items in pool
                if j == 0 then
                    set k = k + 1
                //distribute rates
                elseif j == 1 then
                    set ItemDrops[id].real[i] = rate
                endif

                if ItemDrops[id][i] == 0 then
                    set ItemDrops[id][MAX_ITEM_COUNT] = k //store item count in pool
                    set rate = 1. / k
                    set j = j + 1
                    set i = 0
                else
                    set i = i + 1
                endif
            endloop
        endmethod

        public static method pickItem takes integer id returns integer
            local integer i = GetRandomInt(0, ItemDrops[id][MAX_ITEM_COUNT] - 1)
            local integer j = 0
            local integer myItem = 0

            loop
                exitwhen myItem != 0 or j == 64 //arbitrary iteration limit

                if GetRandomReal(0., 1.) < ItemDrops[id].real[i] then
                    set myItem = ItemDrops[id][i]
                    call adjustRate(id, myItem)
                endif

                if ItemDrops[id][i] == 0 then
                    set j = j + 1
                    set i = 0
                else
                    set i = i + 1
                endif
            endloop

            return myItem
        endmethod

        public static method getType takes integer id returns integer
            if id == 'nits' or id == 'nitt' then //Troll
                return 'nits'
            elseif id == 'ntks' or id == 'ntkw' or id == 'ntkc' then //Tuskarr
                return 'ntks'
            elseif id == 'nnwr' or id == 'nnws' then //Spider
                return 'nnwr'
            elseif id == 'nfpu' or id == 'nfpe' then //polar furbolg ursa
                return 'nfpu'
            elseif id == 'nplg' then // polar bear
                return 'nplg'
            elseif id == 'nmdr' then //dire mammoth
                return 'nmdr'
            elseif id == 'n01G' or id == 'o01G' then // ogre,tauren
                return 'n01G'
            elseif id == 'nubw' or id == 'nfor' or id == 'nfod' then //unbroken
                return 'nubw'
            elseif id == 'nvdl' or id == 'nvdw' then // Hellfire, hellhound
                return 'nvdl'
            elseif id == 'n024' or id == 'n027' or id == 'n028' then // Centaur
                return 'n024'
            elseif id == 'n01M' or id == 'n08M' then // magnataur,forgotten one
                return 'n01M'
            elseif id == 'n02P' or id == 'n01R' then // Frost dragon, frost drake
                return 'n02P'
            elseif id == 'n099' then // Frost Elder Dragon
                return 'n099'
            elseif id == 'n02L' or id == 'n00C' then // Devourers
                return 'n02L'
            elseif id == 'nplb' then // giant bear
                return 'nplb'
            elseif id == 'n01H' then // Ancient Hydra
                return 'n01H'
            elseif id == 'n02U' then // nerubian
                return 'n02U'
            elseif id == 'n03L' then // King of ogres
                return 'n03L'
            elseif id == 'n02H' then // Yeti
                return 'n02H'
            elseif id == 'H02H' then // paladin
                return 'H02H'
            elseif id == 'O002' then // minotaur
                return 'O002'
            elseif id == 'H020' then // lady vashj
                return 'H020'
            elseif id == 'H01V' then // dwarven
                return 'H01V'
            elseif id == 'H040' then // death knight
                return 'H040'
            elseif id == 'U00G' then // tri fire
                return 'U00G'
            elseif id == 'H045' then // mistic
                return 'H045'
            elseif id == 'O01B' or id == 'U001' then // dragoon
                return 'O01B'
            elseif id == 'E00B' then // goddess of hate
                return 'E00B'
            elseif id == 'E00D' then // goddess of love
                return 'E00D'
            elseif id == 'E00C' then // goddess of knowledge
                return 'E00C'
            elseif id == 'H04Q' then // goddess of life
                return 'H04Q'
            elseif id == 'H00O' then // arkaden
                return 'H00O'
            elseif id == 'n034' or id == 'n033' then //demons
                return 'n034'
            elseif id == 'n03A' or id == 'n03B' or id == 'n03C' then //horror
                return 'n03A'
            elseif id == 'n03F' or id == 'n01W' then //despair
                return 'n03F'
            elseif id == 'n08N' or id == 'n00W' or id == 'n00X' then //abyssal
                return 'n08N'
            elseif id == 'n031' or id == 'n030' or id == 'n02Z' then //void
                return 'n031'
            elseif id == 'n020' or id == 'n02J' then //nightmare
                return 'n020'
            elseif id == 'n03D' or id == 'n03E' or id == 'n03G' then //hell
                return 'n03D'
            elseif id == 'n03J' or id == 'n01X' then //existence
                return 'n03J'
            elseif id == 'n03M' or id == 'n01V' then //astral
                return 'n03M'
            elseif id == 'n026' or id == 'n03T' then //plainswalker
                return 'n026'
            elseif id == 'N038' then // Demon Prince
                return 'N038'
            elseif id == 'N017' then // Absolute Horror
                return 'N017'
            elseif id == 'O02B' then // Slaughter
                return 'O02B'
            elseif id == 'O02H' then // Dark Soul
                return 'O02H'
            elseif id == 'O02I' then //Satan
                return 'O02I'
            elseif id == 'O02K' then // Thanatos
                return 'O02K'
            elseif id == 'H04R' then //Legion
                return 'H04R'
            elseif id == 'O02M' then // Existence
                return 'O02M'
            elseif id == 'O03G' then //Forgotten Leader
                return 'O03G'
            elseif id == 'O02T' then //Azazoth
                return 'O02T'
            endif

            return id
        endmethod

        private static method onInit takes nothing returns nothing
            local integer id = 0

            set ItemDrops = HashTable.create()
            set Rates = Table.create()

            set id = 69 //destructable
            set ItemDrops[id][0] = 'I00O'
            set ItemDrops[id][1] = 'I00Q'
            set ItemDrops[id][2] = 'I00R'
            set ItemDrops[id][3] = 'I01C'
            set ItemDrops[id][4] = 'I01F'
            set ItemDrops[id][5] = 'I01G'
            set ItemDrops[id][6] = 'I01H'
            set ItemDrops[id][7] = 'I01I'
            set ItemDrops[id][8] = 'I01K'
            set ItemDrops[id][9] = 'I01V'
            set ItemDrops[id][10] = 'I021'
            set ItemDrops[id][11] = 'I02R'
            set ItemDrops[id][12] = 'I02T'
            set ItemDrops[id][13] = 'I04O'
            set ItemDrops[id][14] = 'I01X'
            set ItemDrops[id][15] = 'I06F'
            set ItemDrops[id][16] = 'I06G'
            set ItemDrops[id][17] = 'I06H'
            set ItemDrops[id][18] = 'I090'
            set ItemDrops[id][19] = 'I01Z'
            set ItemDrops[id][20] = 'I0FJ'

            call calcRates(id)

            set id = 'nits' //troll
            set Rates[id] = 40
            set ItemDrops[id][0] = 'I01Z' //claws of lightning
            set ItemDrops[id][1] = 'I01F' //iron broadsword
            set ItemDrops[id][2] = 'I01I' //iron sword
            set ItemDrops[id][3] = 'I01G' //iron dagger
            set ItemDrops[id][4] = 'I0FJ' //chipped shield
            set ItemDrops[id][5] = 'I02H' //short bow
            set ItemDrops[id][6] = 'I04O' //wooden staff
            set ItemDrops[id][7] = 'I01H' //iron shield
            set ItemDrops[id][8] = 'I00Q' //belt of the giant
            set ItemDrops[id][9] = 'I00R' //boots of the ranger
            set ItemDrops[id][10] = 'I02R' //sigil of magic
            set ItemDrops[id][11] = 'I01C' //gauntlets of strength
            set ItemDrops[id][12] = 'I02T' //slippers of agility
            set ItemDrops[id][13] = 'I01S' //seven league boots
            set ItemDrops[id][14] = 'I01K' //leather jacket
            set ItemDrops[id][15] = 'I01R' //mantle of intelligence
            set ItemDrops[id][16] = 'I01X' //sword of revival
            set ItemDrops[id][17] = 'I01V' //medallion of courage
            set ItemDrops[id][18] = 'I021' //medallion of vitality
            set ItemDrops[id][19] = 'I02D' //ring of regeneration
            set ItemDrops[id][20] = 'I062' //healing potion
            set ItemDrops[id][21] = 'I06E' //mana potion
            set ItemDrops[id][22] = 'I06F' //crystal ball
            set ItemDrops[id][23] = 'I06G' //talisman of evasion
            set ItemDrops[id][24] = 'I06H' //warsong battle drums
            set ItemDrops[id][25] = 'I090' //sparky orb
            set ItemDrops[id][26] = 'I04D' //tattered cloth

            call calcRates(id)

            set id = 'ntks' //tuskarr
            set Rates[id] = 40
            set ItemDrops[id][0] = 'I01Z'
            set ItemDrops[id][1] = 'I01X'
            set ItemDrops[id][2] = 'I01V'
            set ItemDrops[id][3] = 'I021'
            set ItemDrops[id][4] = 'I02D'
            set ItemDrops[id][5] = 'I062'
            set ItemDrops[id][6] = 'I06E'
            set ItemDrops[id][7] = 'I06F'
            set ItemDrops[id][8] = 'I06G'
            set ItemDrops[id][9] = 'I06H'
            set ItemDrops[id][10] = 'I090'
            set ItemDrops[id][11] = 'I01S'
            set ItemDrops[id][12] = 'I04D' 
            set ItemDrops[id][13] = 'I03A' //steel dagger
            set ItemDrops[id][14] = 'I03W' //steel sword
            set ItemDrops[id][15] = 'I00O' //arcane staff
            set ItemDrops[id][16] = 'I03S' //steel shield
            set ItemDrops[id][17] = 'I01L' //long bow
            set ItemDrops[id][18] = 'I03K' //steel lance
            set ItemDrops[id][19] = 'I08Y' //noble blade
            set ItemDrops[id][20] = 'I03Q' //horse boost

            call calcRates(id)

            set id = 'nnwr' //spider
            set Rates[id] = 35
            set ItemDrops[id][0] = 'I03A'
            set ItemDrops[id][1] = 'I03W'
            set ItemDrops[id][2] = 'I00O'
            set ItemDrops[id][3] = 'I03K'
            set ItemDrops[id][4] = 'I01L'
            set ItemDrops[id][5] = 'I03S'
            set ItemDrops[id][6] = 'I08Y'
            set ItemDrops[id][7] = 'I03Q'
            set ItemDrops[id][8] = 'I0FK' //mythril sword
            set ItemDrops[id][9] = 'I00F' //mythril spear
            set ItemDrops[id][10] = 'I010' //mythril dagger
            set ItemDrops[id][11] = 'I00N' //blood elven staff
            set ItemDrops[id][12] = 'I0FM' //blood elven bow
            set ItemDrops[id][13] = 'I0FL' //mythril shield
            set ItemDrops[id][14] = 'I028' //big health potion
            set ItemDrops[id][15] = 'I00D' //big mana potion
            set ItemDrops[id][16] = 'I025' //greater mask of death

            call calcRates(id)

            set id = 'nfpu' //ursa
            set Rates[id] = 30
            set ItemDrops[id][0] = 'I028'
            set ItemDrops[id][1] = 'I00D'
            set ItemDrops[id][2] = 'I025'
            set ItemDrops[id][3] = 'I02L' //great circlet
            set ItemDrops[id][4] = 'I06T' //sword
            set ItemDrops[id][5] = 'I034' //heavy
            set ItemDrops[id][6] = 'I0FG' //dagger
            set ItemDrops[id][7] = 'I06R' //bow
            set ItemDrops[id][8] = 'I0FT' //staff

            call calcRates(id)

            set id = 'nplg' //polar bear
            set Rates[id] = 30
            set ItemDrops[id][0] = 'I035' //plate
            set ItemDrops[id][1] = 'I0FO' //leather
            set ItemDrops[id][2] = 'I07O' //cloth

            call calcRates(id)

            set id = 'nmdr' //dire mammoth
            set Rates[id] = 30
            set ItemDrops[id][0] = 'I0FQ' //fullplate

            call calcRates(id)

            set id = 'n01G' // ogre tauren
            set Rates[id] = 25
            set ItemDrops[id][0] = 'I02L'
            set ItemDrops[id][1] = 'I08I'
            set ItemDrops[id][2] = 'I0FE'
            set ItemDrops[id][3] = 'I07W'
            set ItemDrops[id][4] = 'I08B'
            set ItemDrops[id][5] = 'I0FD'
            set ItemDrops[id][6] = 'I08R'
            set ItemDrops[id][7] = 'I08E'
            set ItemDrops[id][8] = 'I08F'
            set ItemDrops[id][9] = 'I07Y'
            set ItemDrops[id][10] = 'I00B' //axe of speed

            call calcRates(id)

            set id = 'nubw' //unbroken
            set Rates[id] = 25
            set ItemDrops[id][0] = 'I0FS'
            set ItemDrops[id][1] = 'I0FR'
            set ItemDrops[id][2] = 'I0FY'
            set ItemDrops[id][3] = 'I01W'
            set ItemDrops[id][4] = 'I0MB'

            call calcRates(id)

            set id = 'nvdl' // hellfire hellhound
            set Rates[id] = 25
            set ItemDrops[id][0] = 'I00Z'
            set ItemDrops[id][1] = 'I00S'
            set ItemDrops[id][2] = 'I011'
            set ItemDrops[id][3] = 'I02E'
            set ItemDrops[id][4] = 'I023'
            set ItemDrops[id][5] = 'I0MA'

            call calcRates(id)

            set id = 'n024' // centaur
            set Rates[id] = 25
            set ItemDrops[id][0] = 'I06J'
            set ItemDrops[id][1] = 'I06I'
            set ItemDrops[id][2] = 'I06L'
            set ItemDrops[id][3] = 'I06K'
            set ItemDrops[id][4] = 'I07H'

            call calcRates(id)

            set id = 'n01M' // magnataur forgotten one
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I01Q'
            set ItemDrops[id][1] = 'I01N'
            set ItemDrops[id][2] = 'I015'
            set ItemDrops[id][3] = 'I019'

            call calcRates(id)

            set id = 'n02P' // frost dragon frost drake
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I056'
            set ItemDrops[id][1] = 'I04X'
            set ItemDrops[id][2] = 'I05Z'

            call calcRates(id)

            set id = 'n099' // frost elder dragon
            set Rates[id] = 40
            set ItemDrops[id][0] = 'I056'
            set ItemDrops[id][1] = 'I04X'
            set ItemDrops[id][2] = 'I05Z'

            call calcRates(id)

            set id = 'n02L' // devourers
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I02W'
            set ItemDrops[id][1] = 'I00W'
            set ItemDrops[id][2] = 'I017'
            set ItemDrops[id][3] = 'I013'
            set ItemDrops[id][4] = 'I02I'
            set ItemDrops[id][5] = 'I01P'
            set ItemDrops[id][6] = 'I006'
            set ItemDrops[id][7] = 'I02V'
            set ItemDrops[id][8] = 'I009'

            call calcRates(id)

            set id = 'nplb' // giant bear
            set Rates[id] = 40
            set ItemDrops[id][0] = 'I0MC'
            set ItemDrops[id][1] = 'I0MD'
            set ItemDrops[id][2] = 'I0FB'

            call calcRates(id)

            set id = 'n01H' // ancient hydra
            set Rates[id] = 25
            set ItemDrops[id][0] = 'I07N'
            set ItemDrops[id][1] = 'I044'

            call calcRates(id)

            set id = 'n034' //demons
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I073'
            set ItemDrops[id][1] = 'I075'
            set ItemDrops[id][2] = 'I06Z'
            set ItemDrops[id][3] = 'I06W'
            set ItemDrops[id][4] = 'I04T'
            set ItemDrops[id][5] = 'I06S'
            set ItemDrops[id][6] = 'I06U'
            set ItemDrops[id][7] = 'I06O'
            set ItemDrops[id][8] = 'I06Q'

            call calcRates(id)

            set id = 'n03A' //horror
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I07K'
            set ItemDrops[id][1] = 'I05D'
            set ItemDrops[id][2] = 'I07E'
            set ItemDrops[id][3] = 'I07I'
            set ItemDrops[id][4] = 'I07G'
            set ItemDrops[id][5] = 'I07C'
            set ItemDrops[id][6] = 'I07A'
            set ItemDrops[id][7] = 'I07M'
            set ItemDrops[id][8] = 'I07L'
            set ItemDrops[id][9] = 'I07P'
            set ItemDrops[id][10] = 'I077'

            call calcRates(id)

            set id = 'n03F' //despair
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I05P'
            set ItemDrops[id][1] = 'I087'
            set ItemDrops[id][2] = 'I089'
            set ItemDrops[id][3] = 'I083'
            set ItemDrops[id][4] = 'I081'
            set ItemDrops[id][5] = 'I07X'
            set ItemDrops[id][6] = 'I07V'
            set ItemDrops[id][7] = 'I07Z'
            set ItemDrops[id][8] = 'I07R'
            set ItemDrops[id][9] = 'I07T'
            set ItemDrops[id][10] = 'I05O'

            call calcRates(id)

            set id = 'n08N' //abyssal
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I06C'
            set ItemDrops[id][1] = 'I06B'
            set ItemDrops[id][2] = 'I0A0'
            set ItemDrops[id][3] = 'I0A2'
            set ItemDrops[id][4] = 'I09X'
            set ItemDrops[id][5] = 'I0A5'
            set ItemDrops[id][6] = 'I09N'
            set ItemDrops[id][7] = 'I06D'
            set ItemDrops[id][8] = 'I06A'

            call calcRates(id)

            set id = 'n031' //void
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I04Y'
            set ItemDrops[id][1] = 'I08C'
            set ItemDrops[id][2] = 'I08D'
            set ItemDrops[id][3] = 'I08G'
            set ItemDrops[id][4] = 'I08H'
            set ItemDrops[id][5] = 'I08J'
            set ItemDrops[id][6] = 'I055'
            set ItemDrops[id][7] = 'I08M'
            set ItemDrops[id][8] = 'I08N'
            set ItemDrops[id][9] = 'I08O'
            set ItemDrops[id][10] = 'I08S'
            set ItemDrops[id][11] = 'I08U'
            set ItemDrops[id][12] = 'I04W'

            call calcRates(id)

            set id = 'n020' //nightmare
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I09S'
            set ItemDrops[id][1] = 'I0AB'
            set ItemDrops[id][2] = 'I09R'
            set ItemDrops[id][3] = 'I0A9'
            set ItemDrops[id][4] = 'I09V'
            set ItemDrops[id][5] = 'I0AC'
            set ItemDrops[id][6] = 'I0A7'
            set ItemDrops[id][7] = 'I09T'
            set ItemDrops[id][8] = 'I09P'
            set ItemDrops[id][9] = 'I04Z'

            call calcRates(id)

            set id = 'n03D' //hell
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I097'
            set ItemDrops[id][1] = 'I05H'
            set ItemDrops[id][2] = 'I098'
            set ItemDrops[id][3] = 'I095'
            set ItemDrops[id][4] = 'I08W'
            set ItemDrops[id][5] = 'I05G'
            set ItemDrops[id][6] = 'I08Z'
            set ItemDrops[id][7] = 'I091'
            set ItemDrops[id][8] = 'I093'
            set ItemDrops[id][9] = 'I05I'

            call calcRates(id)

            set id = 'n03J' //existence
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I09Y'
            set ItemDrops[id][1] = 'I09U'
            set ItemDrops[id][2] = 'I09W'
            set ItemDrops[id][3] = 'I09Q'
            set ItemDrops[id][4] = 'I09O'
            set ItemDrops[id][5] = 'I09M'
            set ItemDrops[id][6] = 'I09K'
            set ItemDrops[id][7] = 'I09I'
            set ItemDrops[id][8] = 'I09G'
            set ItemDrops[id][9] = 'I09E'

            call calcRates(id)

            set id = 'n03M' //astral
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I0AL'
            set ItemDrops[id][1] = 'I0AN'
            set ItemDrops[id][2] = 'I0AA'
            set ItemDrops[id][3] = 'I0A8'
            set ItemDrops[id][4] = 'I0A6'
            set ItemDrops[id][5] = 'I0A3'
            set ItemDrops[id][6] = 'I0A1'
            set ItemDrops[id][7] = 'I0A4'
            set ItemDrops[id][8] = 'I09Z'

            call calcRates(id)

            set id = 'n026' //plainswalker
            set Rates[id] = 20
            set ItemDrops[id][0] = 'I0AY'
            set ItemDrops[id][1] = 'I0B0'
            set ItemDrops[id][2] = 'I0B2'
            set ItemDrops[id][3] = 'I0B3'
            set ItemDrops[id][4] = 'I0AQ'
            set ItemDrops[id][5] = 'I0AO'
            set ItemDrops[id][6] = 'I0AT'
            set ItemDrops[id][7] = 'I0AR'
            set ItemDrops[id][8] = 'I0AW'

            call calcRates(id)

            set id = 'H01T' //town paladin
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I01Y'

            call calcRates(id)

            set id = 'n02U' // nerubian
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I01E'

            call calcRates(id)

            set id = 'n03L' // king of ogres
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I02M'

            call calcRates(id)

            set id = 'O019' // pinky
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I02Y'

            call calcRates(id)

            set id = 'H043' // bryan
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I02X'

            call calcRates(id)

            set id = 'N01N' // kroresh
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I04B'

            call calcRates(id)

            set id = 'O01A' // zeknen
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I036'

            call calcRates(id)

            set id = 'N00M' // forest corruption
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I07J'

            call calcRates(id)

            set id = 'O00T' // ice troll
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I03Z'

            call calcRates(id)

            set id = 'n02H' // yeti
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I05R'

            call calcRates(id)

            set id = 'H02H' // paladin
            set Rates[id] = 80
            set ItemDrops[id][0] = 'I0F9'
            set ItemDrops[id][1] = 'I03P'
            set ItemDrops[id][2] = 'I0C0'
            set ItemDrops[id][3] = 'I0FX'

            call calcRates(id)

            set id = 'O002' // minotaur
            set Rates[id] = 70
            set ItemDrops[id][0] = 'I03T'
            set ItemDrops[id][1] = 'I0FW'
            set ItemDrops[id][2] = 'I07U'
            set ItemDrops[id][3] = 'I076'
            set ItemDrops[id][4] = 'I078'

            call calcRates(id)

            set id = 'H020' // lady vashj
            set Rates[id] = 70
            set ItemDrops[id][0] = 'I09F' // sea wards
            set ItemDrops[id][1] = 'I09L' // serpent hide boots

            call calcRates(id)

            set id = 'H01V' // dwarven
            set Rates[id] = 70
            set ItemDrops[id][0] = 'I079'
            set ItemDrops[id][1] = 'I07B'
            set ItemDrops[id][2] = 'I0FC'

            call calcRates(id)

            set id = 'H040' // death knight
            set Rates[id] = 80
            set ItemDrops[id][0] = 'I02O'
            set ItemDrops[id][1] = 'I029'
            set ItemDrops[id][2] = 'I02C'
            set ItemDrops[id][3] = 'I02B'

            call calcRates(id)

            set id = 'U00G' // tri fire
            set Rates[id] = 70
            set ItemDrops[id][0] = 'I0FA'
            set ItemDrops[id][1] = 'I0FU'
            set ItemDrops[id][2] = 'I00V'
            set ItemDrops[id][3] = 'I03Y'

            call calcRates(id)

            set id = 'H045' // mystic
            set Rates[id] = 70
            set ItemDrops[id][0] = 'I03U'
            set ItemDrops[id][1] = 'I0F3'
            set ItemDrops[id][2] = 'I07F'

            call calcRates(id)

            set id = 'O01B' // dragoon
            set Rates[id] = 70
            set ItemDrops[id][0] = 'I0EX'
            set ItemDrops[id][1] = 'I0EY'
            set ItemDrops[id][2] = 'I074'
            set ItemDrops[id][3] = 'I04N'

            call calcRates(id)

            set id = 'E00B' // goddess of hate
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I02Z' //aura of hate

            call calcRates(id)

            set id = 'E00D' // goddess of love
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I030' //aura of love

            call calcRates(id)

            set id = 'E00C' // goddess of knowledge
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I031' //aura of knowledge

            call calcRates(id)

            set id = 'H04Q' // goddess of life
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I04I' //aura of life

            call calcRates(id)

            set id = 'H00O' // arkaden
            set Rates[id] = 80
            set ItemDrops[id][0] = 'I02O'
            set ItemDrops[id][1] = 'I02C'
            set ItemDrops[id][2] = 'I02B'

            call calcRates(id)

            set id = 'N038' // demon prince
            set Rates[id] = 100
            set ItemDrops[id][0] = 'I04Q' //heart

            call calcRates(id)

            set id = 'N017' // absolute horror
            set Rates[id] = 85
            set ItemDrops[id][0] = 'I0N7'
            set ItemDrops[id][1] = 'I0N8'
            set ItemDrops[id][2] = 'I0N9'

            call calcRates(id)

            set id = 'O02B' // slaughter
            set Rates[id] = 85
            set ItemDrops[id][0] = 'I0AE'
            set ItemDrops[id][1] = 'I04F'
            set ItemDrops[id][2] = 'I0AF'
            set ItemDrops[id][3] = 'I0AD'
            set ItemDrops[id][4] = 'I0AG'

            call calcRates(id)

            set id = 'O02H' // dark soul
            set Rates[id] = 70
            set ItemDrops[id][0] = 'I05A'
            set ItemDrops[id][1] = 'I0AH'
            set ItemDrops[id][2] = 'I0AP'
            set ItemDrops[id][3] = 'I0AI'

            call calcRates(id)

            set id = 'O02I' // satan
            set Rates[id] = 65
            set ItemDrops[id][0] = 'I0BX'
            set ItemDrops[id][1] = 'I05J'

            call calcRates(id)

            set id = 'O02K' // thanatos
            set Rates[id] = 65
            set ItemDrops[id][0] = 'I04E'
            set ItemDrops[id][1] = 'I0MR'

            call calcRates(id)

            set id = 'H04R' // legion
            set Rates[id] = 60
            set ItemDrops[id][0] = 'I0B5'
            set ItemDrops[id][1] = 'I0B7'
            set ItemDrops[id][2] = 'I0B1'
            set ItemDrops[id][3] = 'I0AU'
            set ItemDrops[id][4] = 'I04L'
            set ItemDrops[id][5] = 'I0AJ'
            set ItemDrops[id][6] = 'I0AZ'
            set ItemDrops[id][7] = 'I0AS'
            set ItemDrops[id][8] = 'I0AV'
            set ItemDrops[id][9] = 'I0AX'

            call calcRates(id)

            set id = 'O02M' // existence
            set Rates[id] = 60
            set ItemDrops[id][0] = 'I018'
            set ItemDrops[id][1] = 'I0BY'

            call calcRates(id)

            set id = 'O03G' // forgotten leader
            set Rates[id] = 30
            set ItemDrops[id][0] = 'I0OB'
            set ItemDrops[id][1] = 'I0O1'
            set ItemDrops[id][2] = 'I0CH'

            call calcRates(id)

            set id = 'O02T' // azazoth
            set Rates[id] = 60
            set ItemDrops[id][0] = 'I0BS'
            set ItemDrops[id][1] = 'I0BV'
            set ItemDrops[id][2] = 'I0BK'
            set ItemDrops[id][3] = 'I0BI'
            set ItemDrops[id][4] = 'I0BB'
            set ItemDrops[id][5] = 'I0BC'
            set ItemDrops[id][6] = 'I0BE'
            set ItemDrops[id][7] = 'I0B9'
            set ItemDrops[id][8] = 'I0BG'
            set ItemDrops[id][9] = 'I06M'

            call calcRates(id)
        endmethod
    endstruct
    
function RechargeDialog takes integer pid, Item itm, real percentage returns nothing
    local string message = GetObjectName(itm.id)
    local integer playerGold = GetCurrency(pid, GOLD)
    local integer playerLumber = GetCurrency(pid, LUMBER)
    local real goldCost = ItemData[itm.id][ITEM_COST] * 100 * percentage + playerGold * percentage
    local real lumberCost = ItemData[itm.id][ITEM_COST] * 100 * percentage + playerLumber * percentage
    local real platCost = GetCurrency(pid, PLATINUM) * percentage
    local real arcCost = GetCurrency(pid, ARCADITE) * percentage

    set goldCost = goldCost + (platCost - R2I(platCost)) * 1000000
    set lumberCost = lumberCost + (arcCost - R2I(arcCost)) * 1000000
    set platCost = R2I(platCost)
    set arcCost = R2I(arcCost)

    call DialogClear(dChooseReward[pid])

    if platCost > 0 then
        set message = message + "\nRecharge cost:\n|cffffffff" + RealToString(platCost) +"|r |cffe3e2e2Platinum|r, |cffffffff" + RealToString(goldCost) + "|r |cffffcc00Gold|r\n"
    else
        set message = message + "\nRecharge cost:\n|cffffffff" + RealToString(goldCost) + " |cffffcc00Gold|r\n"
    endif
    if arcCost > 0 then
        set message = message + "|cffffffff" + RealToString(arcCost) + "|r |cff66FF66Arcadite|r, |cffffffff" + RealToString(lumberCost) + "|r |cff472e2eLumber|r"
    else
        set message = message + "|cffffffff" + RealToString(lumberCost) + " |cff472e2eLumber|r"
    endif

    call DialogSetMessage(dChooseReward[pid], message)

    if GetCurrency(pid, GOLD) >= goldCost and GetCurrency(pid, LUMBER) >= lumberCost and GetCurrency(pid, PLATINUM) >= platCost and GetCurrency(pid, ARCADITE) >= arcCost then
        set slotitem[4000 + pid] = DialogAddButton(dChooseReward[pid], "Recharge", 'y')
    endif
    call DialogAddButton(dChooseReward[pid], "Cancel", 'c')

    call DialogDisplay(Player(pid - 1), dChooseReward[pid], true)
endfunction

function OnDropUpdate takes nothing returns nothing
    local Item itm = Item(ReleaseTimer(GetExpiredTimer()))

    set itm.x = GetItemX(itm.obj)
    set itm.y = GetItemY(itm.obj)

    if IsItemDud(itm) and (IsItemOwned(itm.obj) == false) and (IsItemVisible(itm.obj) == true) then
        call itm.toItem()
    endif
endfunction

function KillQuestHandler takes integer pid, integer itemid returns nothing
    local integer index = KillQuest[itemid][0]
    local integer min = KillQuest[index][KILLQUEST_MIN]
    local integer max = KillQuest[index][KILLQUEST_MAX]
    local integer goal = KillQuest[index][KILLQUEST_GOAL]
    local integer playercount = 0
    local User U = User.first
    local player p = Player(pid - 1)
    local integer avg = R2I((max + min) * 0.5)
    local real x
    local real y
    local rect myregion = null

    if GetUnitLevel(Hero[pid]) < min then
        call DisplayTimedTextToPlayer(p, 0,0, 10, "You must be level |cffffcc00" + I2S(min) + "|r to begin this quest.")
    elseif GetUnitLevel(Hero[pid]) > max then
        call DisplayTimedTextToPlayer(p, 0,0, 10, "You are too high level to do this quest.")
    elseif KillQuest[index][KILLQUEST_STATUS] == 1 then
        call DisplayTimedTextToPlayer(p, 0,0, 10, "Killed " + I2S(KillQuest[index][KILLQUEST_COUNT]) + "/" + I2S(goal) + " " + KillQuest[index].string[KILLQUEST_NAME])
        call PingMinimap(GetRectCenterX(KillQuest[index].rect[KILLQUEST_REGION]), GetRectCenterY(KillQuest[index].rect[KILLQUEST_REGION]), 3)
    elseif KillQuest[index][KILLQUEST_STATUS] == 0 then
        set KillQuest[index][KILLQUEST_STATUS] = 1
        call DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00QUEST:|r Kill " + I2S(goal) + " " + KillQuest[index].string[KILLQUEST_NAME] + " for a reward.")
        call PingMinimap(GetRectCenterX(KillQuest[index].rect[KILLQUEST_REGION]), GetRectCenterY(KillQuest[index].rect[KILLQUEST_REGION]), 5)
    elseif KillQuest[index][KILLQUEST_STATUS] == 2 then //reward
        loop
            exitwhen U == User.NULL
            set pid = GetPlayerId(U.toPlayer()) + 1

            if HeroID[pid] > 0 and GetUnitLevel(Hero[pid]) >= min and GetUnitLevel(Hero[pid]) <= max then
                set playercount = playercount + 1
            endif

            set U = U.next
        endloop

        set U = User.first

        loop
            exitwhen U == User.NULL
            set pid = GetPlayerId(U.toPlayer()) + 1

            if GetHeroLevel(Hero[pid]) >= min and GetHeroLevel(Hero[pid]) <= max then
                call DisplayTimedTextToPlayer(U.toPlayer(), 0, 0, 10, "|c00c0c0c0" + KillQuest[index].string[KILLQUEST_NAME] + " quest completed!|r")
                call AwardGold(U.toPlayer(), udg_RewardGold[avg] * goal / (0.5 + playercount * 0.5), true)
                set udg_XP = R2I(udg_Experience_Table[avg] * udg_XP_Rate[pid] * goal)
                set udg_XP = IMaxBJ(100, R2I(udg_XP / 1800.0))
                call SetHeroXP(Hero[pid], GetHeroXP(Hero[pid]) + udg_XP, true)
                call ExperienceControl(pid)
                call DoFloatingTextUnit("+" + I2S(udg_XP) + " XP", Hero[pid], 2, 80, 0, 10, 204, 0, 204, 0)
            endif

            set U = U.next
        endloop
            
        //reset
        set KillQuest[index][KILLQUEST_STATUS] = 1
        set KillQuest[index][KILLQUEST_COUNT] = 0
        set KillQuest[index][KILLQUEST_GOAL] = IMinBJ(goal + 3, 100)

        //increase max spawns by up to 50 based on last unit killed
        if (KillQuest[index][KILLQUEST_GOAL]) < 100 and ModuloInteger(KillQuest[index][KILLQUEST_GOAL], 2) == 0 then
			set myregion = SelectGroupedRegion(UnitData[KillQuest[index][KILLQUEST_LAST]][UNITDATA_SPAWN])
            loop
                set x = GetRandomReal(GetRectMinX(myregion), GetRectMaxX(myregion))
                set y = GetRandomReal(GetRectMinY(myregion), GetRectMaxY(myregion))
                exitwhen IsTerrainWalkable(x, y)
            endloop
            call CreateUnit(pfoe, KillQuest[index][KILLQUEST_LAST], x, y, GetRandomInt(0, 359))
            set myregion = null
        endif
    endif
    
    set p = null
endfunction

function StackItem takes unit u, item itm returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local integer i = 0
    local integer i2 = 0
    local integer slot = GetItemSlot(itm, u)
    local Item itm2

    if u == Backpack[pid] then
        set i2 = 6
    endif

    loop
        exitwhen i > 5
            set itm2 = Profile[pid].hero.items[i + i2]

            //TODO charge limit?
            if itm2.obj != itm and itm2.id == GetItemTypeId(itm) and itm2.charges < 10 then
                set itm2.charge = itm2.charges + 1
                set Profile[pid].hero.items[slot + i2] = 0
                call Item[itm].destroy()
                exitwhen true
            endif
        set i = i + 1
    endloop
endfunction

function CompleteDialog takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p) + 1
    local integer i = 0
    local Item itm

	loop
		exitwhen i > 11 //as far as we know
		if GetClickedButton() == slotitem[1000 + pid * 10 + i] then
            call PlayerAddItemById(pid, ItemRewards[udg_SlotIndex[pid]][i])
		endif
		set i = i + 1
	endloop

    if GetClickedButton() == slotitem[4000 + pid] then //recharge reincarnation
        set itm = GetResurrectionItem(pid, true)
        set itm.charge = itm.charges + 1

        if udg_Hardcore[pid] then
            call ChargeNetworth(p, ItemData[itm.id][ITEM_COST] * 3, 0.03, 0, "Recharged " + GetItemName(itm.obj) + " for")
        else
            call ChargeNetworth(p, ItemData[itm.id][ITEM_COST], 0.01, 0, "Recharged " + GetItemName(itm.obj) + " for")
        endif
        call TimerStart(rezretimer[pid], 180., false,null)
    endif

    set p = null
endfunction

function BackpackUpgrades takes nothing returns boolean
    local DialogWindow dw = DialogWindow[GetPlayerId(GetTriggerPlayer()) + 1]
    local integer id = dw.data[0]
    local integer price = dw.data[1]
    local integer index = dw.getClickedIndex(GetClickedButton())
    local integer ablev = 0

    if index != -1 then
        call AddCurrency(dw.pid, GOLD, - ModuloInteger(price, 1000000))
        call AddCurrency(dw.pid, PLATINUM, - (price / 1000000))

		if id == 'I101' then
            set ablev = GetUnitAbilityLevel(Backpack[dw.pid], 'A0FV')
			call SetUnitAbilityLevel(Backpack[dw.pid], 'A0FV', ablev + 1)
			call SetUnitAbilityLevel(Backpack[dw.pid], 'A02J', ablev + 1)
			call DisplayTimedTextToPlayer(Player(dw.pid - 1), 0, 0, 20, "You successfully upgraded to: Teleport [|cffffcc00Level " + I2S(ablev + 1) + "|r]")
		elseif id == 'I102' then
            set ablev = GetUnitAbilityLevel(Backpack[dw.pid], 'A0FK')
			call SetUnitAbilityLevel(Backpack[dw.pid], 'A0FK', ablev + 1)
			call DisplayTimedTextToPlayer(Player(dw.pid - 1), 0, 0, 20, "You successfully upgraded to: Reveal [|cffffcc00Level " + I2S(ablev + 1) + "|r]")
		endif

        call dw.destroy()
	endif

    return false
endfunction

function UpgradeItemConfirm takes nothing returns boolean
    local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
    local DialogWindow dw = DialogWindow[pid]
    local Item itm = Item(dw.data[0])
    local integer index = dw.getClickedIndex(GetClickedButton())

    if index != -1 then
        call AddCurrency(pid, GOLD, -dw.data[1])
        call AddCurrency(pid, PLATINUM, -dw.data[2])
        call AddCurrency(pid, CRYSTAL, -dw.data[3])

        set itm.lvl = itm.level + 1
        call DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 20, "You successfully upgraded to: " + itm.name)

        call dw.destroy()
    endif

    return false
endfunction

function UpgradeItem takes nothing returns boolean
    local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
    local DialogWindow dw = DialogWindow[pid]
    local integer index = dw.getClickedIndex(GetClickedButton())
    local integer goldCost = 0
    local integer platCost = 0
    local integer crystalCost = 0
    local string s = "Upgrade cost: \n"
    local Item itm

    if index != -1 then
        set itm = Item(dw.data[index])

        call dw.destroy()

        if itm != 0 then
            set goldCost = ModuloInteger(itm.calcStat(ITEM_COST, 0), 1000000)
            set platCost = itm.calcStat(ITEM_COST, 0) / 1000000
            set crystalCost = CRYSTAL_PRICE[itm.level]

            if platCost > 0 then
                set s = s + "|cffffffff" + I2S(platCost) + "|r |cffe3e2e2Platinum|r\n"
            endif

            if goldCost > 0 then
                set s = s + "|cffffffff" + I2S(goldCost) + "|r |cffffcc00Gold|r\n"
            endif

            if crystalCost > 0 then
                set s = s + "|cffffffff" + I2S(crystalCost) + "|r |cff6969FFCrystals|r\n"
            endif

            set dw = DialogWindow.create(pid, s, function UpgradeItemConfirm)
            set dw.data[0] = itm
            set dw.data[1] = goldCost
            set dw.data[2] = platCost
            set dw.data[3] = crystalCost

            if GetCurrency(pid, GOLD) >= goldCost and GetCurrency(pid, PLATINUM) >= platCost and GetCurrency(pid, CRYSTAL) >= crystalCost then
                call dw.addButton("Upgrade")
            endif

            call dw.display()
        endif
    endif

    return false
endfunction

function ItemFilter takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local player p = GetOwningPlayer(u)
    local integer pid = GetPlayerId(p) + 1
    local Item itm = Item[GetManipulatedItem()]
    local integer req = ItemData[itm.id][ITEM_LEVEL_REQUIREMENT]
    local integer i = GetItemSlot(itm.obj, u)

    set itm.holder = u

    //bind drop
    if IsItemBound(itm, pid) and (LoadInteger(SAVE_TABLE, KEY_ITEMS, itm.id) > 0 or IsBindItem(itm.id)) then
        set dropflag[pid] = true
        call DisplayTimedTextToPlayer(p, 0, 0, 30, "This item is bound to " + User[itm.owner].nameColored + ".")
    else
        if itm.holder == Hero[pid] then //hero
            //level drop
            if req > GetHeroLevel(itm.holder) then
                set dropflag[pid] = true
                call DisplayTimedTextToPlayer(p, 0, 0, 15., "This item requires at least level |c00FF5555" + I2S(req) + "|r to equip.")
            
            //restriction drop
            elseif IsItemRestricted(itm) then
                set dropflag[pid] = true
            endif

            //bind / dud pickup
            if dropflag[pid] == false then
                if IsItemDud(itm) then
                    call itm.toItem()
                elseif LoadInteger(SAVE_TABLE, KEY_ITEMS, itm.id) > 0 or IsBindItem(itm.id) then
                    set itm.owner = p
                endif
            endif

            call UpdateManaCosts(itm.holder)

        elseif itm.holder == Backpack[pid] then //backpack
            set i = i + 6 //item slot

            if IsItemDud(itm) == false and req > GetHeroLevel(Hero[pid]) + 20 then
                set dropflag[pid] = true
                call DisplayTimedTextToPlayer(p, 0, 0, 15., "This item requires at least level |c00FF5555" + I2S(req - 20) + "|r to pick up.")
            //make dud
            elseif IsItemDud(itm) == false and req > GetHeroLevel(Hero[pid]) then
                call itm.toDud()
            endif

            call BackpackLimit(itm.holder)
        endif
    endif

    if dropflag[pid] then
        call UnitRemoveItem(itm.holder, itm.obj)
    elseif BlzGetItemBooleanField(itm.obj, ITEM_BF_USE_AUTOMATICALLY_WHEN_ACQUIRED) == false then
        set Profile[pid].hero.items[i] = itm
    endif

    set u = null

    return true
endfunction

function onPawned takes nothing returns boolean
    local item itm = GetManipulatedItem()

    call Item[itm].destroy()

    set itm = null

    return false
endfunction

function onSell takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local unit b = GetBuyingUnit()
    local integer pid = GetPlayerId(GetOwningPlayer(b)) + 1
    local item myItem = GetSoldItem()
    local Item itm = Item.assign(myItem)

    set itm.owner = Player(pid - 1)
    
    if GetUnitTypeId(u) == 'h002' then //naga chest
        call RemoveUnitTimed(u, 2.5)
        call DestroyEffect(AddSpecialEffectTarget("UI\\Feedback\\GoldCredit\\GoldCredit.mdl", u, "origin"))
        call Fade(u, 2., false)
    endif
    
    set u = null
    set b = null
    set myItem = null
endfunction

function onUse takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local item itm = GetManipulatedItem()
    local player p = GetOwningPlayer(u)
    local integer itemid = GetItemTypeId(itm)
    local integer pid= GetPlayerId(p) + 1
    local timer t

    if u == Hero[pid] then //Potions (Hero)
		if itemid == 'I0BJ' then
			call HP(u, 10000)
		elseif itemid == 'I028' then
			call HP(u, 2000)
		elseif itemid == 'I062' then
			call HP(u, 500)
		elseif itemid == 'I0BL' then
			call MP(u, 10000)
		elseif itemid == 'I00D' then
			call MP(u, 2000)
		elseif itemid == 'I06E' then
			call MP(u, 500)
		elseif itemid == 'I0MP' then
			call HP(u, 50000 + BlzGetUnitMaxHP(u) * 0.08)
			call MP(u, BlzGetUnitMaxMana(u) * 0.08)
        elseif itemid == 'I0MQ' then
			call HP(u, BlzGetUnitMaxHP(u) * 0.15)
        elseif itemid == 'I02K' then //vampiric potion
            if UnitAlive(Hero[pid]) then
                set VampiricPotion.add(Hero[pid], Hero[pid]).duration = 10.
            endif
        endif
	endif
    
    set u = null
    set itm = null
    set p = null
    set t = null
endfunction

function onDrop takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local item myItem = GetManipulatedItem()
    local Item itm = Item[myItem]
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local integer slot = GetItemSlot(myItem, u)

    if slot >= 0 then //safety
        call BlzFrameSetVisible(INVENTORYBACKDROP[slot], false)

        //update hero inventory
        if GetUnitTypeId(u) == BACKPACK then
            set slot = slot + 6
        endif

        set Profile[pid].hero.items[slot] = 0
    endif

    if not IsItemDud(itm) and u == Hero[pid] and dropflag[pid] == false then
        call itm.unequip()
    endif

    call TimerStart(NewTimerEx(itm), 0.0, false, function OnDropUpdate)

    set itm.holder = null

    set u = null
    set myItem = null
endfunction

function onPickup takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local item itm = GetManipulatedItem()
    local integer itemid = GetItemTypeId(itm)
    local player p = GetOwningPlayer(u)
    local integer pid = GetPlayerId(p) + 1
    local integer iud = GetItemUserData(itm)
    local integer index = 0
    local integer i = 0
    local integer i2 = 0
    local integer levmin
    local integer levmax
    local real x
    local real y
    local group ug = CreateGroup()
    local User U = User.first
    local Item itm2 = Item(iud)

    //========================
    //Quests
    //========================

    if KillQuest[itemid][0] > 0 and GetItemType(itm) == ITEM_TYPE_CAMPAIGN then //Kill Quest
        call FlashQuestDialogButton()
        call KillQuestHandler(pid, itemid)
    elseif itemid == 'I0OV' then //Gossip
        set x = GetUnitX(gg_unit_n01F_0576)
        set y = GetUnitY(gg_unit_n01F_0576)

        if x > GetRectMaxX(gg_rct_Main_Map) then //in tavern
            call DisplayTextToForce(FORCE_PLAYING, "|cffffcc00Evil Shopkeeper's Brother:|r I don't know where he is.")
        else
            if x < GetRectCenterX(gg_rct_Main_Map) and y > GetRectCenterY(gg_rct_Main_Map) then
                set ShopkeeperDirection[0] = "|cffffcc00North West|r"
            elseif x > GetRectCenterX(gg_rct_Main_Map) and y > GetRectCenterY(gg_rct_Main_Map) then
                set ShopkeeperDirection[0] = "|cffffcc00North East|r"
            elseif x < GetRectCenterX(gg_rct_Main_Map) and y < GetRectCenterY(gg_rct_Main_Map) then
                set ShopkeeperDirection[0] = "|cffffcc00South West|r"
            else
                set ShopkeeperDirection[0] = "|cffffcc00South East|r"
            endif

            set ShopkeeperDirection[1] = "|cffffcc00Evil Shopkeeper's Brother:|r My brother is currently heading " + ShopkeeperDirection[0] + " to expand his business."
            set ShopkeeperDirection[2] = "|cffffcc00Evil Shopkeeper's Brother:|r I last heard that he was spotted traveling " + ShopkeeperDirection[0] + " to negotiate with some suppliers."
            set ShopkeeperDirection[3] = "|cffffcc00Evil Shopkeeper's Brother:|r My brother is rumored to have traveled " + ShopkeeperDirection[0] + " to seek new markets for his products."
            set ShopkeeperDirection[4] = "|cffffcc00Evil Shopkeeper's Brother:|r I haven't seen him for a while, but I suspect he might be up " + ShopkeeperDirection[0] + " hunting for rare items to sell."
            set ShopkeeperDirection[5] = "|cffffcc00Evil Shopkeeper's Brother:|r He is never in one place for too long. He's probably moved " + ShopkeeperDirection[0] + " by now."
            set ShopkeeperDirection[6] = "|cffffcc00Evil Shopkeeper's Brother:|r If I had to guess, I'd say he is currently located in the " + ShopkeeperDirection[0] + " part of the city."
            set ShopkeeperDirection[7] = "|cffffcc00Evil Shopkeeper's Brother:|r I'm not sure where he is, but he usually heads " + ShopkeeperDirection[0] + " when he wants to avoid trouble."
            set ShopkeeperDirection[8] = "|cffffcc00Evil Shopkeeper's Brother:|r I heard that my brother is hiding to the " + ShopkeeperDirection[0] + " of town."
            set ShopkeeperDirection[9] = "|cffffcc00Evil Shopkeeper's Brother:|r He often travels to the " + ShopkeeperDirection[0] + ", looking for new opportunities to make a profit."
            set ShopkeeperDirection[10] = "|cffffcc00Evil Shopkeeper's Brother:|r He is always on the move. He could be anywhere, but my guess is he's headed due " + ShopkeeperDirection[0] + "."

            call DisplayTextToForce(FORCE_PLAYING, ShopkeeperDirection[GetRandomInt(1, 10)])
        endif

    elseif itemid == 'I08L' then //Evil Shopkeeper
        if IsQuestDiscovered(udg_Evil_Shopkeeper_Quest_1) and IsQuestCompleted(udg_Evil_Shopkeeper_Quest_1) == false then
            loop
                exitwhen i > 5
                if GetItemTypeId(UnitItemInSlot(u, i)) == 'I045' then
                    call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_COMPLETED, "|cffffcc00OPTIONAL QUEST COMPLETED|r\nThe Evil Shopkeeper")
                    call QuestSetCompleted(udg_Evil_Shopkeeper_Quest_1, true)
                    call QuestItemSetCompleted(udg_Quest_Req[11], true)
                    exitwhen true
                endif
                set i = i + 1
            endloop
        elseif IsQuestDiscovered(udg_Evil_Shopkeeper_Quest_1) == false then
            if GetUnitLevel(Hero[pid]) >= 50 then
                call QuestSetDiscovered(udg_Evil_Shopkeeper_Quest_1, true)
                call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_DISCOVERED, "|cff322ce1OPTIONAL QUEST|r\nThe Evil Shopkeeper")
            else
                call DisplayTextToPlayer(p, 0, 0, "You must be at least level 50 to begin this quest.")
            endif
        endif
    elseif itemid == 'I00L' then //The Horde
        if GetUnitLevel(Hero[pid]) >= 100 then
            if IsQuestDiscovered(udg_Defeat_The_Horde_Quest) == false then
                call DestroyEffect(udg_TalkToMe20)
                call QuestSetDiscovered(udg_Defeat_The_Horde_Quest, true)
                call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_DISCOVERED, "|cff322ce1OPTIONAL QUEST|r\nThe Horde")
                call PingMinimap(12577, -15801, 4)
                call PingMinimap(15645, -12309, 4)
                
                //orc setup
                call SetUnitPosition(gg_unit_N01N_0050, 14665, -15352)
                call UnitAddAbility(gg_unit_N01N_0050, 'Avul')
                
                //bottom side
                call IssuePointOrder(CreateUnit(pboss, 'o01I', 12687, -15414, 45), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o01I', 12866, -15589, 45), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o008', 12539, -15589, 45), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o008', 12744, -15765, 45), "patrol", 668, -2146)
                //top side
                call IssuePointOrder(CreateUnit(pboss, 'o01I', 15048, -12603, 225), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o01I', 15307, -12843, 225), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o008', 15299, -12355, 225), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o008', 15543, -12630, 225), "patrol", 668, -2146)
                
                call TimerStart(NewTimer(), 30., true, function SpawnOrcs)
            elseif IsQuestCompleted(udg_Defeat_The_Horde_Quest) == false then
                call DisplayTextToPlayer(p, 0, 0, "Militia: The Orcs are still alive!")
            elseif IsQuestCompleted(udg_Defeat_The_Horde_Quest) == true and not hordequest then
                call DisplayTextToPlayer(p, 0, 0, "Militia: As promised, the Key of Valor.")
                call Item.assign(CreateItem('I041', -800, -865))
                set hordequest = true
                call DestroyEffect(udg_TalkToMe20)
            endif
        else
            call DisplayTextToPlayer(p, 0, 0, "You must be level |cffffcc00"+I2S(100)+"|r to begin this quest.")
        endif
    else
        
    //Headhunter
        
    loop
        exitwhen i > udg_PermanentInteger[10]
        if itemid == udg_HuntedRecipe[i] then
            if HuntedLevel[i] <= GetHeroLevel(Hero[pid]) then
                if PlayerHasItemType(pid, udg_HuntedHead[i]) then
                    call GetItemFromPlayer(pid, udg_HuntedHead[i]).destroy()
                    call PlayerAddItemById(pid, udg_HuntedItem[i])

                    set udg_XP = R2I(udg_HuntedExp[i] * udg_XP_Rate[pid] / 100.)
                    call SetHeroXP(Hero[pid], GetHeroXP(Hero[pid]) + udg_XP, true)
                    call ExperienceControl(pid)
                    call DoFloatingTextUnit("+" + I2S(udg_XP) + " XP", Hero[pid], 2, 80, 0, 10, 204, 0, 204, 0)
                else
                    call DisplayTextToPlayer(p, 0, 0, "You do not have the head.")
                endif
            else
                call DisplayTextToPlayer(p, 0, 0, "You must be level |cffffcc00"+I2S(HuntedLevel[i])+"|r to complete this quest.")
            endif
        endif
        set i = i + 1
    endloop

    endif

    set i = 0
    set index = 0
    
    //========================
    //Dungeons
    //========================
    
    if itemid == 'I0JU' then //naga
        if CountPlayersInForceBJ(NAGA_GROUP) > 0 then
            call DisplayTextToPlayer(p, 0, 0, "This dungeon is already in progress!")
        else
            if QUEUE_DUNGEON == 0 then
                call StartDungeon('I0JU', -12363, -1185)
            elseif QUEUE_DUNGEON == 1 then
                call ReadyCheck()
            else
                call DisplayTextToPlayer(p, 0, 0, "Please wait while another dungeon is queueing!")
            endif
        endif
        
    elseif itemid == 'I0NM' then //naga reward
        if RectContainsCoords(gg_rct_Naga_Dungeon_Reward, GetUnitX(u), GetUnitY(u)) or RectContainsCoords(gg_rct_Naga_Dungeon_Boss, GetUnitX(u), GetUnitY(u)) then
            call NagaReward()
        endif
        
    elseif itemid == 'I0JO' and ChaosMode == false then //portal to the gods
        if PathtoGodsisOpen and GodsParticipant[pid] == false then
            set GodsParticipant[pid] = true
        
            call SetCameraBoundsRectForPlayerEx(p, gg_rct_GodsCameraBounds)
            call PanCameraToTimedForPlayer(p, GetRectCenterX(gg_rct_GodsEntrance), GetRectCenterY(gg_rct_GodsEntrance), 0)
            call BlzSetUnitFacingEx(Hero[pid], 45)
            call SetUnitPosition(Hero[pid], GetRectCenterX(gg_rct_GodsEntrance), GetRectCenterY(gg_rct_GodsEntrance))
            call reselect(Hero[pid])
            
            if GodsEnterFlag == false then
                set GodsEnterFlag = true
                
                call DoTransmissionBasicsXYBJ(GetUnitTypeId(gg_unit_O01A_0372), GetPlayerColor(pboss), GetUnitX(gg_unit_O01A_0372), GetUnitY(gg_unit_O01A_0372), null, "Zeknen", "Explain yourself or be struck down from this heaven!", 10)
                call TimerStart(NewTimer(), 10, false, function ZeknenExpire)
            endif
        endif
        
    elseif itemid == 'I0NO' and ChaosMode == false then //rescind to darkness
        if GodsEnterFlag == false and ChaosMode == false and GetHeroLevel(Hero[pid]) >= 240 then
            set powercrystal = CreateUnitAtLoc(pfoe, 'h04S', Location(30000, -30000), bj_UNIT_FACING)
            call KillUnit(powercrystal)
        endif
        
    //========================
    //Buyables / Shops
    //========================
    
    elseif itemid == 'I07Q' and donated[pid] == false then //donation
        call ChargeNetworth(p, 0, 0.01, 100, "")
        set donated[pid] = true
        set donation = donation - donationrate
        call DisplayTextToPlayer(p, 0, 0, "|c00408080The Goddesses bestow their blessings.")
        call DisplayTextToForce(FORCE_PLAYING, "Reduced bad weather: " + I2S(R2I((1 - donation) * 100)) + "%")
    elseif itemid == 'I0M9' then //prestige
        if HasItemType(Hero[pid], 'I0NN') then
            if GetUnitLevel(Hero[pid]) == 400 then
                call ActivatePrestige(p)
            else
                call DisplayTextToPlayer(p, 0, 0, "You are not level 400!")
            endif
        else
            call DisplayTextToPlayer(p, 0, 0, "You do not have a |cffffcc00Prestige Token|r!")
        endif
    elseif itemid == 'I0TS' and GetCurrency(pid, GOLD) >= 10000 then //str tome
        call StatTome(pid, 10, 1, false)
    elseif itemid == 'I0TA' and GetCurrency(pid, GOLD) >= 10000 then //agi tome
        call StatTome(pid, 10, 2, false)
    elseif itemid == 'I0TI' and GetCurrency(pid, GOLD) >= 10000 then //int tome
        call StatTome(pid, 10, 3, false)
    elseif itemid == 'I0TT' and GetCurrency(pid, GOLD) >= 20000 then //all stats
        call StatTome(pid, 10, 4, false)
    elseif itemid == 'I0OH' and GetCurrency(pid, PLATINUM) >= 1 then //str plat tome
        call StatTome(pid, 1000, 1, true)
    elseif itemid == 'I0OI' and GetCurrency(pid, PLATINUM) >= 1 then //agi plat tome
        call StatTome(pid, 1000, 2, true)
    elseif itemid == 'I0OK' and GetCurrency(pid, PLATINUM) >= 1 then //int plat tome
        call StatTome(pid, 1000, 3, true)
    elseif itemid == 'I0OJ' and GetCurrency(pid, PLATINUM) >= 2 then //all stats plat tome
        call StatTome(pid, 1000, 4, true)
    elseif itemid == 'I0N0' then //grimoire of focus
        set i = 0
        if GetHeroStr(Hero[pid], false) - 50 > 20 then
            call SetHeroStr(Hero[pid], GetHeroStr(Hero[pid], false) - 50, true)
            set i = i + 5000
        elseif GetHeroStr(Hero[pid], false) >= 20 then
            call SetHeroStr(Hero[pid], 20, true)
        endif
        if GetHeroAgi(Hero[pid], false) - 50 > 20 then
            call SetHeroAgi(Hero[pid], GetHeroAgi(Hero[pid], false) - 50, true)
            set i = i + 5000
        elseif GetHeroAgi(Hero[pid], false) >= 20 then
            call SetHeroAgi(Hero[pid], 20, true)
        endif
        if GetHeroInt(Hero[pid], false) - 50 > 20 then
            call SetHeroInt(Hero[pid], GetHeroInt(Hero[pid], false) - 50, true)
            set i = i + 5000
        elseif GetHeroInt(Hero[pid], false) >= 20 then
            call SetHeroInt(Hero[pid], 20, true)
        endif
        if i > 0 then
            call AddCurrency(pid, GOLD, i)
            call DisplayTextToPlayer(p, 0, 0, "You have been refunded |cffffcc00" + RealToString(i) + "|r gold.")
        endif
    elseif itemid == 'I0JN' then //tome of retraining
        call Item.assign(UnitAddItemById(Hero[pid], 'Iret'))
    elseif itemid == 'I101' or itemid == 'I102' then //upgrade teleports & reveal
        if itemid == 'I101' then
            set i = GetUnitAbilityLevel(Backpack[pid], 'A02J')
        elseif itemid == 'I102' then
            set i = GetUnitAbilityLevel(Backpack[pid], 'A0FK')
        endif
        
        if i < 10 then //only 10 upgrades
            set index = R2I(400. * Pow(5., i - 1.))
            
            if index > 1000000 then
                set i = DialogWindow.create(pid, "Upgrade cost: \n|cffffffff" + I2S(index / 1000000) + " |cffe3e2e2Platinum|r |cffffffffand " + I2S(ModuloInteger(index, 1000000)) + " |cffffcc00Gold|r", function BackpackUpgrades)
            else
                set i = DialogWindow.create(pid, "Upgrade cost: \n|cffffffff" + I2S(index) + " |cffffcc00Gold|r", function BackpackUpgrades)
            endif
            
            if GetCurrency(pid, GOLD) >= ModuloInteger(index, 1000000) and GetCurrency(pid, PLATINUM) >= R2I(index / 1000000) then
                set DialogWindow(i).data[0] = itemid
                set DialogWindow(i).data[1] = index
                call DialogWindow(i).addButton("Upgrade")
            endif

            call DialogWindow(i).display()
        endif
    elseif itemid == 'I100' then //upgrade item
        set i = DialogWindow.create(pid, "Choose an item to upgrade.", function UpgradeItem)

        set index = 0
        loop
            exitwhen index >= MAX_INVENTORY_SLOTS
            set itm2 = Profile[pid].hero.items[index]

            if itm2 != 0 and ItemData[itm2.id].integer[ITEM_UPGRADE_MAX] > itm2.level then
                set DialogWindow(i).data[DialogWindow(i).ButtonCount] = itm2
                call DialogWindow(i).addButton(itm2.name)
            endif

            set index = index + 1
        endloop

        call DialogWindow(i).display()
    elseif itemid == 'I04G' then //item based conversions
		if GetCurrency(pid, GOLD) >= 1000000 then
            call AddCurrency(pid, PLATINUM, 1)
            call AddCurrency(pid, GOLD, -1000000)
			call Plat_Effect(p)
			call DisplayTimedTextToPlayer(p,0,0, 20, PlatTag + I2S(GetCurrency(pid, PLATINUM)))
		else
			call DisplayTimedTextToPlayer(p,0,0, 30, "|cffee0000You do not have a million gold to convert.")
		endif
	elseif itemid == 'I04H' then
		if GetCurrency(pid, LUMBER) >= 1000000 then
            call AddCurrency(pid, ARCADITE, 1)
            call AddCurrency(pid, LUMBER, -1000000)
			call Plat_Effect(p)
			call DisplayTimedTextToPlayer(p,0,0, 20, ArcTag + I2S(GetCurrency(pid, ARCADITE)))
		else
			call DisplayTimedTextToPlayer(p,0,0, 30, "|cffee0000You do not have a million lumber to convert.")
		endif
	elseif itemid == 'I054' then
		if GetCurrency(pid, ARCADITE) >0 then 
			call Plat_Effect(p)
            call AddCurrency(pid, PLATINUM, 1)
            call AddCurrency(pid, ARCADITE, -1)
            call AddCurrency(pid, GOLD, 200000)
			call DisplayTimedTextToPlayer(p,0,0, 20, ArcTag + I2S(GetCurrency(pid, ARCADITE)))
			call DisplayTimedTextToPlayer(p,0,0, 20, PlatTag + I2S(GetCurrency(pid, PLATINUM)))
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "|cff990000Unable to convert; not enough Arcadite Lumber.")
		endif
	elseif itemid == 'I053' then
		if GetCurrency(pid, PLATINUM) > 0 then
			call Plat_Effect(p)
            call AddCurrency(pid, PLATINUM, -1)
            call AddCurrency(pid, ARCADITE, 1)
			call DisplayTimedTextToPlayer(p,0,0, 20, ArcTag + I2S(GetCurrency(pid, ARCADITE)))
			call DisplayTimedTextToPlayer(p,0,0, 20, PlatTag + I2S(GetCurrency(pid, PLATINUM)))
		else
            call AddCurrency(pid, GOLD, 350000)
			call DisplayTimedTextToPlayer(p,0,0, 20, "|cff990000Unable to convert; not enough Platinum Coins.")
		endif
	elseif itemid == 'I0PA' then
		if GetCurrency(pid, PLATINUM) >= 4 then
			call Plat_Effect(p)
            call AddCurrency(pid, PLATINUM, -4)
            call AddCurrency(pid, ARCADITE, 3)
			call DisplayTimedTextToPlayer(p,0,0, 20, ArcTag + I2S(GetCurrency(pid, ARCADITE)))
			call DisplayTimedTextToPlayer(p,0,0, 20, PlatTag + I2S(GetCurrency(pid, PLATINUM)))
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "|cff990000Unable to convert; due to insufficient Platinum Coins.")
		endif
	elseif itemid == 'I051' then
		if GetCurrency(pid, ARCADITE) > 0 then
			call Plat_Effect(p)
            call AddCurrency(pid, ARCADITE, -1)
            call AddCurrency(pid, LUMBER, 1000000)
			call DisplayTimedTextToPlayer(p,0,0, 20, ArcTag + I2S(GetCurrency(pid, ARCADITE)))
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "|cff990000Unable to convert; not enough Arcadite Lumber.")
		endif
	elseif itemid == 'I052' then
		if GetCurrency(pid, PLATINUM) >0 then
			call Plat_Effect(p)
            call AddCurrency(pid, PLATINUM, -1)
            call AddCurrency(pid, GOLD, 1000000)
			call DisplayTimedTextToPlayer(p,0,0, 20, PlatTag + I2S(GetCurrency(pid, PLATINUM)))
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "|cff990000Unable to convert; not enough Platinum Coins.")
		endif
	elseif itemid == 'I03R' then
		if GetCurrency(pid, LUMBER) >= 25000 then
            call AddCurrency(pid, GOLD, 25000)
            call AddCurrency(pid, LUMBER, -25000)
			call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", u, "origin"))
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "You need at least 25,000 lumber to buy this.")
		endif
	elseif itemid == 'I05C' then
		if GetCurrency(pid, GOLD) >= 32000 then
            call AddCurrency(pid, LUMBER, 25000)
            call AddCurrency(pid, GOLD, -32000)
			call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", u, "origin"))
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "You need at least 32,000 gold to buy this.")
		endif
    elseif itemid == 'I05S' then //prestige token
        if GetHeroLevel(Hero[pid]) < 400 then
            call DisplayTimedTextToPlayer(p,0,0, 20, "You need level 400 to buy this.")
        else
            if GetCurrency(pid, CRYSTAL) >= 2500 then
                call AddCurrency(pid, CRYSTAL, -2500)
                call PlayerAddItemById(pid, 'I0NN')
            else
                call DisplayTimedTextToPlayer(p,0,0, 20, "You need 2500 crystals to buy this.")
            endif
        endif
    elseif itemid == 'I0ME' then //crystal to gold / platinum
		if GetCurrency(pid, CRYSTAL) >= 1 then
            call AddCurrency(pid, CRYSTAL, -1)
            call AddCurrency(pid, GOLD, 500000)
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "You need at least 1 crystal to buy this.")
		endif
    elseif itemid == 'I0MF' then //platinum to crystal
		if GetCurrency(pid, PLATINUM) >= 3 then
            call AddCurrency(pid, PLATINUM, -3)
            call AddCurrency(pid, CRYSTAL, 1)
            call DisplayTimedTextToPlayer(p,0,0, 20, CrystalTag + I2S(GetCurrency(pid, CRYSTAL)))
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "You need at least 3 platinum to buy this.")
		endif
    elseif itemid == 'I05T' then //Satans Abode
		if GetUnitLevel(Hero[pid]) < 250 then
			call DisplayTimedTextToPlayer(p,0,0, 15, "This item requires level 250 to use.")
        else
            call BuyHome(u, 2, 1, 'I001')
		endif
	elseif itemid == 'I069' then //Demon Nation
        if GetUnitLevel(Hero[pid]) < 280 then
			call DisplayTimedTextToPlayer(p,0,0, 15, "This item requires level 280 to use.")
        else
            call BuyHome(u, 4, 2, 'I068')
		endif
    elseif itemid == 'I0JS' then //Recharge Reincarnation
        set itm2 = GetResurrectionItem(pid, true)

        if GetItemCharges(itm2.obj) >= MAX_REINCARNATION_CHARGES then
            set itm2 = 0
        endif

        if itm2 == 0 then
            call DisplayTimedTextToPlayer(p, 0, 0, 15, "You have no item to recharge!")
        elseif TimerGetRemaining(rezretimer[pid]) > 1 then
            call DisplayTimedTextToPlayer(p,0,0,15, I2S(R2I(TimerGetRemaining(rezretimer[pid]))) + " seconds until you can recharge your " + GetItemName(itm2.obj))
        else
            if udg_Hardcore[pid] then
                call RechargeDialog(pid, itm2, 0.03)
            else
                call RechargeDialog(pid, itm2, 0.01)
            endif
        endif
        
    //========================
    //Quest Rewards
    //========================

	elseif itemid == 'I08L' then // Shopkeeper necklace
		call Recipe('I045', 1, 'item', 0, 'item', 0, 'item', 0, 'item', 0, 'item', 0, 'I03E', 0, u, 0, 0, 0, false)
	elseif itemid == 'I09H' then // Omega Pick
		call Recipe('I02Y', 1, 'I02X', 1, 'item', 0, 'item', 0, 'item', 0, 'item', 0, 'I043', 0, u, 0, 0, 0, false)
	elseif itemid == 'I04M' then //Spider armor
        if GetHeroLevel(Hero[pid]) < 15 then
            call DisplayTextToPlayer(p, 0, 0, "You must be level 15 to complete this quest.")
		elseif PlayerHasItemType(pid, 'I01E') then
            call GetItemFromPlayer(pid, 'I01E').destroy()
            call RewardDialog(pid, itemid)
		else
			call DisplayTextToPlayer(p, 0, 0, "Nerubian head must be on your hero")
		endif

    //========================
    //Item Stacking
    //========================
    
    //shop items
    elseif itemid == 'I062' or itemid == 'I028' or itemid == 'I0BJ' or itemid == 'I06E' or itemid == 'I0BL' or itemid == 'I00D' or itemid == 'I00K' then
        call StackItem(u, itm)
    //empty flask, dragon bone, dragon heart, dragon scale, dragon potion, blood potion
    elseif itemid == 'I0MO' or itemid == 'I04X' or itemid == 'I056' or itemid == 'I05Z' or itemid == 'I0MP' or itemid == 'I0MQ' then
        call StackItem(u, itm)
    //keys
    elseif itemid == 'I040' or itemid == 'I041' or itemid == 'I042' then
        if Recipe('I0M4',1,'I041',1,'item',0,'item',0,'item',0,'item',0,'I0M7',0,u,0,0,0, true) == true then
            call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_REQUIREMENT, "  - |cff808080Retrieve the Key of the Gods (Completed)|r")
        elseif Recipe('I0M5',1,'I042',1,'item',0,'item',0,'item',0,'item',0,'I0M7',0,u,0,0,0, true) == true then
            call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_REQUIREMENT, "  - |cff808080Retrieve the Key of the Gods (Completed)|r")
        elseif Recipe('I0M6',1,'I040',1,'item',0,'item',0,'item',0,'item',0,'I0M7',0,u,0,0,0, true) == true then
            call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_REQUIREMENT, "  - |cff808080Retrieve the Key of the Gods (Completed)|r")
        elseif Recipe('I040',1,'I041',1,'item',0,'item',0,'item',0,'item',0,'I0M5',0,u,0,0,0, true) == true then
        elseif Recipe('I041',1,'I042',1,'item',0,'item',0,'item',0,'item',0,'I0M6',0,u,0,0,0, true) == true then
        elseif Recipe('I042',1,'I040',1,'item',0,'item',0,'item',0,'item',0,'I0M4',0,u,0,0,0, true) == true then
        endif
        
    //=====================================
    //Colosseum / Struggle / Training / PVP
    //=====================================

    elseif itemid == 'I0EV' or itemid == 'I0EU' or itemid == 'I0ET' or itemid == 'I0ES' or itemid == 'I0ER' or itemid == 'I0EQ' or itemid == 'I0EP' or itemid == 'I0EO' then
        if ColoPlayerCount > 0 then
            call DisplayTimedTextToPlayer(p,0,0, 5.00, "Colloseum is occupied!")
        else
            call GroupEnumUnitsInRect(ug, gg_rct_Colloseum_Enter, Condition(function ischar))
            
            if (itemid == 'I0EO') or (itemid == 'I0ES') then
				if ChaosMode then
					set udg_Wave = 103
				else
					set udg_Wave = 0
				endif
			elseif (itemid == 'I0EP') or (itemid == 'I0ET') then
				if ChaosMode then
					set udg_Wave = 128
				else
					set udg_Wave = 25
				endif
			elseif (itemid == 'I0EQ')or(itemid == 'I0EU') then
				if ChaosMode then
					set udg_Wave = 153
				else
					set udg_Wave = 49
				endif
			elseif (itemid == 'I0ER')or(itemid == 'I0EV') then
				if ChaosMode then
					set udg_Wave = 182
				else
					set udg_Wave = 73
				endif
			endif
            
            set index = 0
            
            if (itemid == 'I0ER' or itemid == 'I0EQ' or itemid == 'I0EP' or itemid == 'I0EO') then // solo
                set index = 1
            elseif (itemid == 'I0EV' or itemid == 'I0EU' or itemid == 'I0ET' or itemid == 'I0ES') then // team
                if BlzGroupGetSize(ug) > 1 then
                    set index = 2
                else
                    call DisplayTextToPlayer(p,0,0, "Atleast 2 players is required to play team survival.")
                endif
            endif
            
            if (itemid == 'I0ER' or itemid == 'I0EV') and ChaosMode then
                set i2 = 350
            endif
            
            set levmin = 500
            set levmax = 0
            
            if index == 1 then
                //start colo solo
                if isteleporting[pid] == false then
                    set ColoPlayerCount = 1
                    set udg_Colosseum_Monster_Amount = 0
                    set ColoWaveCount = 0
                    set InColo[pid] = true
                    call GroupClear(ColoWaveGroup)
                    call SetUnitPositionLoc(Hero[pid], ColosseumCenter)
                    call SetCameraBoundsRectForPlayerEx(GetOwningPlayer(Hero[pid]), gg_rct_Colloseum_Camera_Bounds)
                    call PanCameraToTimedLocForPlayer(GetOwningPlayer(Hero[pid]), ColosseumCenter, 0)
                    call ExperienceControl(pid)
                    call DisableItems(pid)
                    call TimerStart(NewTimer(), 2., false, function AdvanceColo)
                endif
            elseif index == 2 then
                set i = 1
                loop
                    exitwhen i > 8
                    if IsUnitInGroup(Hero[i], ug) then
                        set levmin = IMinBJ(GetHeroLevel(Hero[i]), levmin)
                        set levmax = IMaxBJ(GetHeroLevel(Hero[i]), levmax)
                    endif
                    set i = i + 1
                endloop
                if levmin < i2 then
                    set i = 1
                    loop
                        exitwhen i > 8
                        if IsUnitInGroup(Hero[i], ug) then
                            call DisplayTextToPlayer(Player(i-1),0,0, "All players need level |cffffcc00"+I2S(i2)+"|r to enter.")
                        endif
                        set i = i + 1
                    endloop
                elseif levmax - levmin > LEECH_CONSTANT then
                    set i = 1
                    loop
                        exitwhen i > 8
                        if IsUnitInGroup(Hero[i], ug) then
                            call DisplayTextToPlayer(Player(i-1),0,0, "Maximum level difference is |cffffcc0050|r levels.")
                        endif
                        set i = i + 1
                    endloop
                else
                    //start colo team
                    set ColoPlayerCount = 0
                    set udg_Colosseum_Monster_Amount = 0
                    set ColoWaveCount = 0
                    call GroupClear(ColoWaveGroup)
                    loop
                        set u = FirstOfGroup(ug)
                        exitwhen u == null
                        set pid = GetPlayerId(GetOwningPlayer(u)) + 1
                        call GroupRemoveUnit(ug, u)
                        if u == Hero[pid] and isteleporting[pid] == false then
                            set InColo[pid] = true
                            set ColoPlayerCount = ColoPlayerCount + 1
                            set udg_Fleeing[pid] = false
                            call SetUnitPositionLoc(u, ColosseumCenter)
                            call SetCameraBoundsRectForPlayerEx(GetOwningPlayer(u), gg_rct_Colloseum_Camera_Bounds)
                            call PanCameraToTimedLocForPlayer(GetOwningPlayer(u), ColosseumCenter, 0)
                            call ExperienceControl(pid)
                            call DisableItems(pid)
                        endif
                    endloop
                    call TimerStart(NewTimer(), 2., false, function AdvanceColo)
                endif
            endif
        endif
        
    elseif itemid == 'I0EW' or itemid == 'I00U' then //Struggle
        call GroupEnumUnitsInRect(ug, gg_rct_Colloseum_Enter, Condition(function ischar))

        if udg_Struggle_Pcount > 0 then
            call GroupClear(ug)
            call DisplayTextToPlayer(Player(pid-1),0,0, "Struggle is occupied.")
        elseif BlzGroupGetSize(ug) > 0 then
            set levmin = 500
            set levmax = 0

            set i = 1
            loop
                exitwhen i > 8
                if IsUnitInGroup(Hero[i], ug) then
                    set levmin = IMinBJ(GetHeroLevel(Hero[i]), levmin)
                    set levmax = IMaxBJ(GetHeroLevel(Hero[i]), levmax)
                endif
                set i = i + 1
            endloop
            if levmax - levmin > 80 then
                set i = 1
                loop
                    exitwhen i > 8
                    if IsUnitInGroup(Hero[i], ug) then
                        call DisplayTextToPlayer(Player(i-1),0,0, "Maximum level difference is |cffffcc0080|r levels.")
                    endif
                    set i = i + 1
                endloop
            else
                set udg_Struggle_Pcount = 0
                set udg_GoldWon_Struggle = 0
                loop //start struggle
                    set u = FirstOfGroup(ug)
                    exitwhen u == null
                    set pid = GetPlayerId(GetOwningPlayer(u)) + 1
                    call GroupRemoveUnit(ug, u)
                    if u == Hero[pid] and isteleporting[pid] == false then
                        set InStruggle[pid] = true
                        set udg_Struggle_Pcount = udg_Struggle_Pcount + 1
                        set udg_Fleeing[pid] = false
                        call DisableItems(pid)
                        call SetUnitPositionLoc(u, StruggleCenter)
                        call CreateUnitAtLoc(GetOwningPlayer(u), 'h065', StruggleCenter, bj_UNIT_FACING)
                        call SetCameraBoundsRectForPlayerEx(GetOwningPlayer(u), gg_rct_InfiniteStruggleCameraBounds)
                        call PanCameraToTimedLocForPlayer(GetOwningPlayer(u), StruggleCenter, 0)
                        call ExperienceControl(pid)
                        call DisplayTimedTextToPlayer(GetOwningPlayer(u), 0, 0, 15., "You have 15 seconds to build before enemies spawn.")
                    endif
                endloop
                if itemid == 'I0EW' then //regular struggle
                    set udg_Struggle_WaveN = 0
                    if levmin > 120 then
                        set udg_Struggle_WaveN = 14
                    elseif levmin > 90 then
                        set udg_Struggle_WaveN = 11
                    elseif levmin > 60 then
                        set udg_Struggle_WaveN = 8
                    elseif levmin > 30 then
                        set udg_Struggle_WaveN = 5
                    endif
                    set udg_Struggle_WaveUCN = udg_Struggle_WaveUN[udg_Struggle_WaveN]
                else //chaos struggle
                    set udg_Struggle_WaveN = 28
                    set udg_Struggle_WaveUCN = udg_Struggle_WaveUN[udg_Struggle_WaveN]
                endif
                call GroupClear(StruggleWaveGroup)
                call TimerStart(NewTimerEx(1), 12., false, function AdvanceStruggle)
            endif
        endif
        
    elseif itemid == 'I0MT' then //Enter Training
        if GetHeroLevel(Hero[pid]) < 160 then //prechaos
            set x = GetRandomReal(GetRectMinX(gg_rct_PrechaosTraining), GetRectMaxX(gg_rct_PrechaosTraining))
            set y = GetRandomReal(GetRectMinY(gg_rct_PrechaosTraining), GetRectMaxY(gg_rct_PrechaosTraining))
            call SetCameraBoundsRectForPlayerEx(p, gg_rct_PrechaosTraining)
            
            if GetLocalPlayer() == p then
                call PanCameraToTimed(GetRectCenterX(gg_rct_PrechaosTraining), GetRectCenterY(gg_rct_PrechaosTraining), 0)
                call ClearSelection()
                call SelectUnit(Hero[pid], true)
            endif
        else //chaos
            set x = GetRandomReal(GetRectMinX(gg_rct_ChaosTraining), GetRectMaxX(gg_rct_ChaosTraining))
            set y = GetRandomReal(GetRectMinY(gg_rct_ChaosTraining), GetRectMaxY(gg_rct_ChaosTraining))
            call SetCameraBoundsRectForPlayerEx(p, gg_rct_ChaosTraining)
            
            if GetLocalPlayer() == p then
                call PanCameraToTimed(GetRectCenterX(gg_rct_ChaosTraining), GetRectCenterY(gg_rct_ChaosTraining), 0)
                call ClearSelection()
                call SelectUnit(Hero[pid], true)
            endif
        endif
            
        call SetUnitPosition(Hero[pid], x, y)
    
    elseif itemid == 'I0MW' then //Exit Training
        if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            call GroupEnumUnitsInRect(ug, gg_rct_PrechaosTrainingSpawn, Condition(function ishostile))
            
            if FirstOfGroup(ug) == null then
                if GetLocalPlayer() == p then
                    call SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
                    call PanCameraToTimed(500, -425, 0)
                    call ClearSelection()
                    call SelectUnit(Hero[pid], true)
                endif
                call SetUnitPosition(Hero[pid], 500, -425)
            else
                call DisplayTextToPlayer(p, 0, 0, "You must kill all enemies before leaving!")
            endif
        elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            call GroupEnumUnitsInRect(ug, gg_rct_ChaosTrainingSpawn, Condition(function ishostile))
            
            if FirstOfGroup(ug) == null then
                if GetLocalPlayer() == p then
                    call SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
                    call PanCameraToTimed(500, -425, 0)
                    call ClearSelection()
                    call SelectUnit(Hero[pid], true)
                endif
                call SetUnitPosition(Hero[pid], 500, -425)
            else
                call DisplayTextToPlayer(p, 0, 0, "You must kill all enemies before leaving!")
            endif
        endif
        
    elseif itemid == 'I0MS' then //Training Prechaos
        call CreateUnit(pfoe, UnitData[0][TrainerSpawn], GetRandomReal(GetRectMinX(gg_rct_PrechaosTraining), GetRectMaxX(gg_rct_PrechaosTraining)), GetRandomReal(GetRectMinY(gg_rct_PrechaosTraining), GetRectMaxY(gg_rct_PrechaosTraining)), GetRandomReal(0,359))
        
    elseif itemid == 'I0MX' then //Training Chaos
        call CreateUnit(pfoe, UnitData[1][TrainerSpawnChaos], GetRandomReal(GetRectMinX(gg_rct_ChaosTraining), GetRectMaxX(gg_rct_ChaosTraining)), GetRandomReal(GetRectMinY(gg_rct_ChaosTraining), GetRectMaxY(gg_rct_ChaosTraining)), GetRandomReal(0,359))
        
    elseif itemid == 'I0MU' then //Increase Difficulty
        if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            set itm = GetItemFromUnit(gg_unit_h001_0072, 'I0MY')
            set TrainerSpawn = TrainerSpawn + 1
            if UnitData[0][TrainerSpawn] == 0 then
                set TrainerSpawn = TrainerSpawn - 1
            endif
            call BlzSetItemIconPath(itm, "|cffffcc00" + GetObjectName(UnitData[0][TrainerSpawn]) + "|r")
        elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            set itm = GetItemFromUnit(gg_unit_h000_0120, 'I0MZ')
            set TrainerSpawnChaos = TrainerSpawnChaos + 1
            if UnitData[1][TrainerSpawnChaos] == 0 then
                set TrainerSpawnChaos = TrainerSpawnChaos - 1
            endif
            call BlzSetItemIconPath(itm, "|cffffcc00" + GetObjectName(UnitData[1][TrainerSpawnChaos]) + "|r")
        endif
        
    elseif itemid == 'I0MV' then //Decrease Difficulty
        if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            set itm = GetItemFromUnit(gg_unit_h001_0072, 'I0MY')
            set TrainerSpawn = IMaxBJ(0, TrainerSpawn - 1)
            call BlzSetItemIconPath(itm, "|cffffcc00" + GetObjectName(UnitData[0][TrainerSpawn]) + "|r")
        elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            set itm = GetItemFromUnit(gg_unit_h000_0120, 'I0MZ')
            set TrainerSpawnChaos = IMaxBJ(0, TrainerSpawnChaos - 1)
            call BlzSetItemIconPath(itm, "|cffffcc00" + GetObjectName(UnitData[1][TrainerSpawnChaos]) + "|r")
        endif
    elseif itemid == 'PVPA' then //Enter PVP
        call DialogClear(PvpDialog[pid])
        call DialogSetMessage(PvpDialog[pid], "Choose an arena.")

        set PvpButton[pid * 8 + 1] = DialogAddButton(PvpDialog[pid], "Pandaren Forest [Duel]", 0)
        set PvpButton[pid * 8 + 2] = DialogAddButton(PvpDialog[pid], "Wastelands [FFA]", 1)
        set PvpButton[pid * 8 + 3] = DialogAddButton(PvpDialog[pid], "Ice Cavern [Duel]", 2)

        call DialogAddButton(PvpDialog[pid], "Cancel", 'C')
        call DialogDisplay(p, PvpDialog[pid], true)
    
    elseif not IsItemDud(itm2) then
        if u == Hero[pid] and dropflag[pid] == false then //heroes
            call itm2.equip()
            if GetLocalPlayer() == p then
                call BlzFrameSetTexture(INVENTORYBACKDROP[GetEmptySlot(u)], SPRITE_RARITY[itm2.level], 0, true)
            endif
        endif

        //add spells and refresh (required for each equip)
        call TimerStart(NewTimerEx(itm2), 0.0, false, function ItemAddSpellDelayed)
    endif

    set dropflag[pid] = false
    
    call DestroyGroup(ug)
    
    set u = null
    set itm = null
    set p = null
    set ug = null
endfunction

//===========================================================================
function ItemInit takes nothing returns nothing
    local trigger onpickup = CreateTrigger()
    local trigger ondrop = CreateTrigger()
    local trigger useitem = CreateTrigger()
    local trigger reward = CreateTrigger()
    local trigger onsell = CreateTrigger()
    local trigger onpawn = CreateTrigger()
    local trigger onpvp = CreateTrigger()
    local integer i = 0 
    local User u = User.first

    loop
        exitwhen u == User.NULL
        set rezretimer[u.id] = CreateTimer()
        set dChooseReward[u.id] = DialogCreate()
        set PvpDialog[u.id] = DialogCreate()
        call TriggerRegisterDialogEvent(reward, dChooseReward[u.id])
        call TriggerRegisterDialogEvent(onpvp, PvpDialog[u.id])
        call TriggerRegisterPlayerUnitEvent(onpickup, u.toPlayer(), EVENT_PLAYER_UNIT_PICKUP_ITEM, null)
        call TriggerRegisterPlayerUnitEvent(ondrop, u.toPlayer(), EVENT_PLAYER_UNIT_DROP_ITEM, null)
        call TriggerRegisterPlayerUnitEvent(useitem, u.toPlayer(), EVENT_PLAYER_UNIT_USE_ITEM, null)
        call TriggerRegisterPlayerUnitEvent(onpawn, u.toPlayer(), EVENT_PLAYER_UNIT_PAWN_ITEM, null)
        set u = u.next
    endloop

    call TriggerRegisterUnitEvent(ondrop, ASHEN_VAT, EVENT_UNIT_DROP_ITEM)
    call TriggerRegisterPlayerUnitEvent(onsell, Player(PLAYER_NEUTRAL_PASSIVE), EVENT_PLAYER_UNIT_SELL_ITEM, null)
    
    call TriggerAddCondition(onpickup, Condition(function ItemFilter))
    call TriggerAddAction(onpickup, function onPickup)
    call TriggerAddAction(ondrop, function onDrop)
    call TriggerAddAction(useitem, function onUse)
    call TriggerAddAction(onsell, function onSell)
    call TriggerAddCondition(onpawn, function onPawned)
    call TriggerAddAction(reward, function CompleteDialog)
    
    call TriggerAddAction(onpvp, function EnterPVP)
    
    set onpickup = null
    set ondrop = null
    set useitem = null
    set reward = null
    set onsell = null
    set onpawn = null
    set onpvp = null
endfunction

endlibrary
