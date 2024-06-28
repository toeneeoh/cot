--[[
    itemspells.lua

    Defines any item spells (no dynamic tooltips)
]]

OnInit.final("ItemSpells", function(Require)
    Require("Spells")

    ITEM_EQUIP_SPELL = {
        [FourCC('Aarm')] = function(itm, id, index) -- armor aura
            BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, id), ABILITY_RLF_ARMOR_BONUS_HAD1, 0, itm:getValue(index, 0))
        end,

        [FourCC('Abas')] = function(itm, id, index) -- bash
            BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, id), ABILITY_RLF_CHANCE_TO_BASH, 0, itm:getValue(index, 0))
            BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, id), ABILITY_RLF_DURATION_NORMAL, 0, ItemData[itm.id][index * ABILITY_OFFSET + 1])
            BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, id), ABILITY_RLF_DURATION_HERO, 0, ItemData[itm.id][index * ABILITY_OFFSET + 1])
        end,

        [FourCC('A018')] = function(itm, id, index) -- blink
            BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, id), ABILITY_RLF_MAXIMUM_RANGE, 0, itm:getValue(index, 0))
        end,

        [FourCC('HPOT')] = function(itm, id, index) -- healing potion
            BlzSetAbilityIntegerLevelField(BlzGetItemAbility(itm.obj, id), ABILITY_ILF_HIT_POINTS_GAINED_IHPG, 0, itm:getValue(index, 0))
        end,
    }

    local SHIELD_BLOCK = Spell.define('Zs00', 'Zs01', 'Zs02', 'Zs03', 'Zs04', 'Zs05', 'Zs06')
    do
        local thistype = SHIELD_BLOCK
        local shield_variations = {}

        -- iterate over shared definitions
        for _, v in ipairs(thistype.shared) do
            shield_variations[v] = function(target, source, amount, damage_type)
                if damage_type == PHYSICAL and math.random(0, 99) < GetAbilityField(target, v, 0) then
                    amount.value = amount.value * (1. - GetAbilityField(target, v, 1) * 0.01)
                end
            end
        end

        function thistype.onUnequip(itm, id, abilid)
            EVENT_ON_STRUCK_MULTIPLIER:unregister_unit_action(itm.holder, shield_variations[abilid])
        end

        function thistype.onEquip(itm, id, abilid)
            EVENT_ON_STRUCK_MULTIPLIER:register_unit_action(itm.holder, shield_variations[abilid])
        end
    end

    local AZAZOTH_BLADE_STORM = Spell.define('A07G')
    do
        local thistype = AZAZOTH_BLADE_STORM

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - 0.05 --tick rate

            if pt.dur > 0. then
                --spawn effect
                local dummy = Dummy.create(GetUnitX(pt.source), GetUnitY(pt.source), 0, 0, 0.75).unit
                BlzSetUnitSkin(dummy, FourCC('h00D'))
                SetUnitTimeScale(dummy, GetRandomReal(0.8, 1.1))
                SetUnitScale(dummy, 1.30, 1.30, 1.30)
                SetUnitAnimationByIndex(dummy, 0)
                SetUnitFlyHeight(dummy, GetRandomReal(50., 100.), 0)
                BlzSetUnitFacingEx(dummy, GetRandomReal(0, 359.))

                dummy = Dummy.create(GetUnitX(pt.source), GetUnitY(pt.source), 0, 0, 0.75).unit
                BlzSetUnitSkin(dummy, FourCC('h00D'))
                SetUnitTimeScale(dummy, GetRandomReal(0.8, 1.1))
                SetUnitScale(dummy, 0.7, 0.7, 0.7)
                SetUnitAnimationByIndex(dummy, 0)
                SetUnitFlyHeight(dummy, GetRandomReal(50., 100.), 0)
                BlzSetUnitFacingEx(dummy, GetRandomReal(0, 359.))

                if pt.dur < 4.85 and ModuloReal(pt.dur, 0.25) < 0.05 then --do damage every 0.25 second
                    local ug = CreateGroup()

                    MakeGroupInRange(pt.pid, ug, GetUnitX(pt.source), GetUnitY(pt.source), 300., Condition(FilterEnemy))

                    for target in each(ug) do
                        DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Critters\\Albatross\\CritterBloodAlbatross.mdl", target, "chest"))
                        DamageTarget(pt.source, target, (UnitGetBonus(pt.source, BONUS_DAMAGE) + GetHeroStr(pt.source, true)) * 0.25 * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, "Blade Storm")
                    end

                    DestroyGroup(ug)
                end

                pt.timer:callDelayed(0.05, periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            if HasProficiency(self.pid, PROF_SWORD) then
                local pt = TimerList[self.pid]:add()
                pt.dur = 5.
                pt.source = self.caster
                pt.timer:callDelayed(0.05, periodic, pt)
            else
                DisplayTimedTextToPlayer(Player(self.pid - 1), 0, 0, 15., "You do not have the proficiency to use this spell!")
            end
        end
    end

    local RESURGENCE = Spell.define('Areg')
    do
        local thistype = RESURGENCE

        ---@type fun(itm: Item)
        local function regen(itm)
            if itm.equipped then
                local max_hp = BlzGetUnitMaxHP(itm.holder)
                local hp = math.min(5, math.floor((max_hp - GetWidgetLife(itm.holder)) / max_hp * 100. / 15.))

                Unit[itm.holder].regen = Unit[itm.holder].regen - (itm.regen or 0)
                itm.regen = math.floor(BlzGetUnitMaxHP(itm.holder) * 0.01 * (itm:getValue(ITEM_ABILITY, 0)) * hp)
                Unit[itm.holder].regen = Unit[itm.holder].regen + itm.regen
                TimerQueue:callDelayed(0.5, regen, itm)
            end
        end

        function thistype.onUnequip(itm, id, index)
            Unit[itm.holder].regen = Unit[itm.holder].regen - (itm.regen or 0)
            itm.regen = 0
        end

        function thistype.onEquip(itm, id, index)
            TimerQueue:callDelayed(0.5, regen, itm)
        end
    end

    local POWERFULSTRIKE = Spell.define('Abon')
    do
        local thistype = POWERFULSTRIKE

        local function onHit(source, target)
            DamageTarget(source, target, GetAbilityField(source, thistype.id, 0), ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
        end

        function thistype.onUnequip(itm, id, index)
            EVENT_ON_HIT:unregister_unit_action(itm.holder, onHit)
        end

        function thistype.onEquip(itm, id, index)
            EVENT_ON_HIT:register_unit_action(itm.holder, onHit)
        end
    end

    local SIPHONBLOOD = Spell.define('Ahrt')
    do
        local thistype = SIPHONBLOOD

        local function update_tooltip(itm)
            if itm.nocraft then
                local s = ""
                --heart of the demon prince
                if itm.blood >= 2000 then
                    itm.nocraft = false
                    s = "|c0000ff40"
                end

                local s2 = "|cffff5050Chaotic Quest|r\n|c00ff0000Level Requirement: |r190\n\n|cff0099ffBlood Accumulated:|r (" .. s .. (IMinBJ(2000, itm.blood)) .. "/2000|r)\n\n|cff808080Deal or take damage to fill the heart with blood (Level 170+ enemies).\n|cffff0000WARNING! This item does not save!\n|cff808080Limit: 1|r"

                itm.tooltip = s2
                itm.alt_tooltip = s2

                BlzSetItemDescription(itm.obj, itm.tooltip)
                BlzSetItemExtendedTooltip(itm.obj, itm.tooltip)
            end
        end

        local function onHit(source, target)
            if GetUnitLevel(target) >= 170 then
                local pid = GetPlayerId(GetOwningPlayer(source)) + 1
                local itm = Item[GetItemFromUnit(Hero[pid], FourCC('I04Q'))]

                itm.blood = (itm.blood or 0) + 1
                update_tooltip(itm)
            end
        end

        local function onStruck(target, source, amount)
            if amount.value > 0.00 and GetUnitLevel(source) >= 170 then
                local pid = GetPlayerId(GetOwningPlayer(target)) + 1
                local itm = Item[GetItemFromUnit(Hero[pid], FourCC('I04Q'))]

                itm.blood = (itm.blood or 0) + 1
                update_tooltip(itm)
            end
        end

        function thistype.onUnequip(itm, id, index)
            EVENT_ON_HIT:unregister_unit_action(itm.holder, onHit)
            EVENT_ON_STRUCK_MULTIPLIER:unregister_unit_action(itm.holder, onStruck)
            for _, v in ipairs(SummonGroup) do
                if itm.owner == GetOwningPlayer(v) then
                    EVENT_ON_HIT:unregister_unit_action(v, onHit)
                end
            end
        end

        function thistype.onEquip(itm, id, index)
            EVENT_ON_HIT:register_unit_action(itm.holder, onHit)
            EVENT_ON_STRUCK_MULTIPLIER:register_unit_action(itm.holder, onStruck)
            for _, v in ipairs(SummonGroup) do
                if itm.owner == GetOwningPlayer(v) then
                    EVENT_ON_HIT:register_unit_action(v, onHit)
                end
            end
        end
    end

    local THANATOS_WINGS = Spell.define('A00D')
    do
        local thistype = THANATOS_WINGS

        function thistype:onCast()
            local wings = Item[GetItemFromUnit(self.caster, FourCC('I04E'))]

            if wings then
                local max = wings:getValue(ITEM_ABILITY, 0)

                if wings.sfx_index then
                    wings.sfx_index = ((wings.sfx_index + 1) > max and 1) or wings.sfx_index + 1
                else
                    wings.sfx_index = 1
                end

                local tbl = ItemData[wings.id].sfx[wings.sfx_index]

                DestroyEffect(wings.sfx)
                wings.sfx = AddSpecialEffectTarget(tbl.path, self.caster, tbl.attach)
            end
        end

        function thistype.onUnequip(itm, index)
            DestroyEffect(itm.sfx)
        end

        function thistype.onEquip(itm, id, index)
            local sfx = ItemData[itm.id].sfx[itm.sfx_index or itm:getValue(index, 0)]

            itm.sfx = AddSpecialEffectTarget(sfx.path, itm.holder, sfx.attach)
        end
    end

    THANATOS_BOOTS = Spell.define('A01S')
    do
        local thistype = THANATOS_BOOTS

        function thistype.onUnequip(itm, id, index)
            DestroyEffect(itm.sfx)
            DestroyEffect(itm.sfx2)
        end

        function thistype.onEquip(itm, id, index)
            local tbl = ItemData[itm.id].sfx

            itm.sfx = AddSpecialEffectTarget(tbl[1].path, itm.holder, tbl[1].attach)
            itm.sfx2 = AddSpecialEffectTarget(tbl[2].path, itm.holder, tbl[2].attach)

            BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, id), ABILITY_RLF_MAXIMUM_RANGE, 0, itm:getValue(index, 0))

            return true
        end
    end

end, Debug and Debug.getLine())
