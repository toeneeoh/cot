--[[
    unitspells.lua

    Defines any spells used by units and summons that don't have dynamic tooltips
]]

OnInit.final("UnitSpells", function(Require)
    Require("Spells")

    ---@return boolean
    local function HeroPanelClick()
        local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local dw    = DialogWindow[pid] ---@type DialogWindow 
        local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

        if index ~= -1 then
            local id = pid * PLAYER_CAP + dw.data[index] ---@type integer 

            IS_HERO_PANEL_ON[id] = (not IS_HERO_PANEL_ON[id])
            ShowHeroPanel(GetTriggerPlayer(), Player(dw.data[index] - 1), IS_HERO_PANEL_ON[id])

            dw:destroy()
        end

        return false
    end

    ---@param pid integer
    local function DisplayHeroPanel(pid)
        local dw = DialogWindow.create(pid, "", HeroPanelClick) ---@type DialogWindow 
        local U  = User.first ---@type User 

        while U do
            if pid ~= U.id and HeroID[U.id] ~= 0 then
                dw.data[dw.ButtonCount] = U.id
                dw:addButton(U.nameColored)
            end

            U = U.next
        end

        dw:display()
    end

    ---@type fun(pt: PlayerTimer)
    function AstralDevastation(pt)
        local i         = 1 ---@type integer 
        local i2         = 0 ---@type integer 
        local ug       = CreateGroup()
        local playerBonus         = 0 ---@type integer 
        local x      = 0. ---@type number 
        local y      = 0. ---@type number 

        pt.time = pt.time + 1

        if pt.time < 4 then --azazoth cast
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", pt.source, "origin"))
            pt.timer:callDelayed(pt.dur, AstralDevastation, pt)
        else
            if pt.pid ~= BOSS_ID then
                playerBonus = 20
            else
                PauseUnit(pt.source, false)
            end

            while i <= 8 do
                i2 = -1
                while i2 <= 1 do
                    x = GetUnitX(pt.source) + (150 * i) * Cos(bj_DEGTORAD * (pt.angle + 40 * i2))
                    y = GetUnitY(pt.source) + (150 * i) * Sin(bj_DEGTORAD * (pt.angle + 40 * i2))
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", x, y))
                    if i2 == 0 and playerBonus > 0 then
                        GroupEnumUnitsInRangeEx(pt.pid, ug, x, y, 130. + playerBonus, Condition(FilterEnemy))
                        playerBonus = playerBonus + 40
                    else
                        GroupEnumUnitsInRangeEx(pt.pid, ug, x, y, 130., Condition(FilterEnemy))
                    end
                    i2 = i2 + 1
                end
                i = i + 1
            end

            for target in each(ug) do
                DamageTarget(pt.source, target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, pt.tag)
            end

            pt:destroy()
        end

        DestroyGroup(ug)
    end

    ---@type fun(pt: PlayerTimer)
    function AstralAnnihilation(pt)
        pt.time = pt.time + 1

        if pt.time < 4 then --azazoth cast
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", pt.source, "origin"))
            pt.timer:callDelayed(pt.dur, AstralAnnihilation, pt)
        else
            local x = GetUnitX(pt.source)
            local y = GetUnitY(pt.source)

            for i = 1, 9 do
                for j = 0, 11 do
                    local angle = 2 * bj_PI * i / 12.
                    DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x + 100 * j * Cos(angle), y + 100 * j * Sin(angle)))
                end
            end

            local ug = CreateGroup()
            MakeGroupInRange(pt.pid, ug, x, y, 900., Filter(FilterEnemy))

            for target in each(ug) do
                DamageTarget(pt.source, target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, pt.tag)
            end

            DestroyGroup(ug)

            pt:destroy()
        end
    end


    ---@type fun(boss: unit, baseDamage: integer, effectability: integer, AOE: number, tag: string)
    function BossBlastTaper(boss, baseDamage, effectability, AOE, tag)
        local castx = GetUnitX(boss) ---@type number 
        local casty = GetUnitY(boss) ---@type number 
        local dx    = 0. ---@type number 
        local dy    = 0. ---@type number 
        local ug    = CreateGroup()

        for i = 1, 18 do
            local angle = bj_PI * i /9.
            local dummy = Dummy.create(castx, casty, effectability, 1).unit
            SetUnitFlyHeight(dummy, 150., 0)
            IssuePointOrder(dummy, "breathoffire", castx + 40 * Cos(angle), casty + 40 * Sin(angle))
        end
        GroupEnumUnitsInRange(ug, castx, casty, AOE, Condition(ishostileEnemy))
        for target in each(ug) do
            --call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
            dx= GetUnitX(target) - castx
            dy= GetUnitY(target) - casty
            local dist = SquareRoot(dx * dx +dy * dy)
            if dist < 150 then
                DamageTarget(boss,target, baseDamage, ATTACK_TYPE_NORMAL, MAGIC, tag)
            else
                DamageTarget(boss,target, baseDamage / (dist / 200.), ATTACK_TYPE_NORMAL, MAGIC, tag)
            end
        end

        DestroyGroup(ug)
        PauseUnit(boss, false)
    end

    ---@type fun(boss: unit, baseDamage: integer, hgroup: integer, speffect: string, tag: string)
    function BossPlusSpell(boss, baseDamage, hgroup, speffect, tag)
        local castx = GetUnitX(boss) ---@type number 
        local casty = GetUnitY(boss) ---@type number 
        local dx ---@type number 
        local dy ---@type number 

        if UnitAlive(boss) then
            for i = -8, 8 do
                DestroyEffect(AddSpecialEffect(speffect, castx + 80 * i, casty - 75))
                DestroyEffect(AddSpecialEffect(speffect, castx + 80 * i, casty + 75))
                DestroyEffect(AddSpecialEffect(speffect, castx - 75, casty + 80 * i))
                DestroyEffect(AddSpecialEffect(speffect, castx + 75, casty + 80 * i))
            end

            local ug = CreateGroup()

            GroupEnumUnitsInRange(ug, castx, casty, 750, Condition(ishostileEnemy))

            for target in each(ug) do
                --call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
                dx = RAbsBJ(GetUnitX(target) - castx)
                dy = RAbsBJ(GetUnitY(target) - casty)
                if dx < 150 and dy < 700 then
                    DamageTarget(boss, target, baseDamage, ATTACK_TYPE_NORMAL, MAGIC, tag)
                elseif dx < 700 and dy < 150 then
                    DamageTarget(boss, target, baseDamage, ATTACK_TYPE_NORMAL, MAGIC, tag)
                end
            end

            DestroyGroup(ug)
        end
    end

    ---@type fun(boss: unit, baseDamage: integer, hgroup: integer, speffect: string, tag: string)
    function BossXSpell(boss, baseDamage, hgroup, speffect, tag)
        local castx      = GetUnitX(boss) ---@type number 
        local casty      = GetUnitY(boss) ---@type number 
        local dx ---@type number 
        local dy ---@type number 

        if UnitAlive(boss) then
            for i = -8, 8 do
                DestroyEffect(AddSpecialEffect(speffect, castx + 75 * i, casty + 75 * i))
                DestroyEffect(AddSpecialEffect(speffect, castx + 75 * i, casty - 75 * i))
            end

            local ug = CreateGroup()
            GroupEnumUnitsInRange(ug, castx, casty, 750, Condition(ishostileEnemy))

            for target in each(ug) do
                dx = RAbsBJ(GetUnitX(target) - castx)
                dy = RAbsBJ(GetUnitY(target) - casty)
                if RAbsBJ(dx - dy) < 200 then
                    DamageTarget(boss, target, baseDamage, ATTACK_TYPE_NORMAL, MAGIC, tag)
                end
            end

            DestroyGroup(ug)
        end
    end

    ---@type fun(boss: unit, baseDamage: integer, hgroup: integer, AOE: number, speffect: string, tag: string)
    function BossInnerRing(boss, baseDamage, hgroup, AOE, speffect, tag)
        local castx = GetUnitX(boss) ---@type number 
        local casty = GetUnitY(boss) ---@type number 
        local angle ---@type number 

        for i = 0, 6 do
            angle= bj_PI *i /3.
            DestroyEffect(AddSpecialEffect(speffect, castx +AOE*.4 * Cos(angle), casty +AOE*.4 * Sin(angle)))
            DestroyEffect(AddSpecialEffect(speffect, castx +AOE*.8 * Cos(angle), casty +AOE*.8 * Sin(angle)))
        end

        local ug = CreateGroup()
        GroupEnumUnitsInRange(ug, castx, casty, AOE, Condition(ishostileEnemy))

        for target in each(ug) do
            --call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
            DamageTarget(boss, target, baseDamage, ATTACK_TYPE_NORMAL, MAGIC, tag)
        end

        DestroyGroup(ug)
    end

    ---@type fun(boss: unit, baseDamage: integer, hgroup: integer, innerRadius: number, outerRadius: number, speffect: string, tag: string)
    function BossOuterRing(boss, baseDamage, hgroup, innerRadius, outerRadius, speffect, tag)
        local castx = GetUnitX(boss) ---@type number 
        local casty = GetUnitY(boss) ---@type number 
        local dx    = 0. ---@type number 
        local dy    = 0. ---@type number 
        local angle = 0. ---@type number 
        local distance = outerRadius - innerRadius ---@type number 

        for i = 0, 10 do
            angle = bj_PI * i / 5.
            DestroyEffect(AddSpecialEffect(speffect, castx + (innerRadius + distance / 6.) * Cos(angle), casty + (innerRadius + distance / 6.) * Sin(angle)))
            DestroyEffect(AddSpecialEffect(speffect, castx + (outerRadius - distance / 6.) * Cos(angle), casty + (outerRadius - distance / 6.) * Sin(angle)))
        end

        local ug = CreateGroup()
        GroupEnumUnitsInRange(ug, castx, casty, outerRadius, Condition(ishostileEnemy))

        for target in each(ug) do
            dx = GetUnitX(target) - castx
            dy = GetUnitY(target) - casty
            distance = SquareRoot(dx * dx + dy * dy)
            if distance > innerRadius then
                DamageTarget(boss, target, baseDamage, ATTACK_TYPE_NORMAL, MAGIC, tag)
            end
        end

        DestroyGroup(ug)
    end

    --Runs upon selecting a backpack
    ---@return boolean
    function BackpackSkinClick()
        local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local dw    = DialogWindow[pid] ---@type DialogWindow 
        local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

        if index ~= -1 then
            if CosmeticTable[User[pid - 1].name][dw.data[index]] == 0 then
                DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, CosmeticTable.skins[dw.data[index]].error)
            else
                Profile[pid]:skin(dw.data[index])
            end

            dw:destroy()
        end

        return false
    end

    --Displays backpack selection dialog
    ---@param pid integer
    function BackpackSkin(pid)
        local name = User[pid - 1].name
        local dw   = DialogWindow.create(pid, "Select Appearance", BackpackSkinClick) ---@type DialogWindow 

        for i, v in ipairs(CosmeticTable.skins) do
            local text = ((v.req and CosmeticTable[name][i] > 0) and "|cff00ff00" .. v.name .. "|r") or v.name

            if CosmeticTable[name][i] > 0 or v.public == true then
                dw.data[dw.ButtonCount] = i
                dw:addButton(text)
            end
        end

        dw:display()
    end

    --Runs upon selecting a cosmetic
    ---@return boolean
    function CosmeticButtonClick()
        local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local dw    = DialogWindow[pid] ---@type DialogWindow 
        local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

        if index ~= -1 then
            CosmeticTable.cosmetics[dw.data[index]]:effect(pid)

            dw:destroy()
        end

        return false
    end

    --Displays cosmetic selection dialog
    ---@param pid integer
    function DisplaySpecialEffects(pid)
        local name = User[pid - 1].name
        local dw   = DialogWindow.create(pid, "", CosmeticButtonClick) ---@type DialogWindow 

        for i, v in ipairs(CosmeticTable.cosmetics) do
            if CosmeticTable[name][i + DONATOR_AURA_OFFSET] > 0 then
                dw.data[dw.ButtonCount] = i
                dw:addButton(v.name)
            end
        end

        dw:display()
    end

    function EnemySpells()
        local caster = GetTriggerUnit() ---@type unit 
        local sid    = GetSpellAbilityId() ---@type integer 

        if sid == FourCC('A04K') then --naga dungeon thorns
            FloatingTextUnit("Thorns", caster, 2, 50, 0, 13.5, 255, 255, 125, 0, true)
            TimerQueue:callDelayed(2., ApplyNagaThorns, caster)
            TimerQueue:callDelayed(8.5, DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Orc\\SpikeBarrier\\SpikeBarrier.mdl", caster, "origin"))
        elseif sid == FourCC('A04R') then --naga dungeon swarm beetle
            FloatingTextUnit("Swarm", caster, 2, 50, 0, 13.5, 155, 255, 255, 0, true)
            local ug = CreateGroup()
            GroupEnumUnitsInRange(ug, GetUnitX(caster), GetUnitY(caster), 1250., Condition(isplayerunit))

            local target = FirstOfGroup(ug)
            local count = 0
            local rand = GetRandomInt(0, 359)
            while target do
                if GetRandomReal(0, 1.) <= 0.75 then
                    GroupRemoveUnit(ug, target)
                end
                local beetle = CreateUnit(GetOwningPlayer(caster), FourCC('u002'), GetUnitX(caster) + GetRandomInt(125, 250) * Cos(bj_DEGTORAD * (rand + i * 30)), GetUnitY(caster) + GetRandomInt(125, 250) * Sin(bj_DEGTORAD * (rand + i * 30)), 0)
                BlzSetUnitFacingEx(beetle, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(beetle), GetUnitX(target) - GetUnitX(beetle)))
                PauseUnit(beetle, true)
                UnitAddAbility(beetle, FourCC('Avul'))
                SetUnitAnimation(beetle, "birth")
                TimerQueue:callDelayed(GetRandomReal(0.75, 1.), SwarmBeetle, beetle, target)
                count = count + 1
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)
        elseif sid == FourCC('A04V') then --naga atk speed
            FloatingTextUnit("Enrage", caster, 2, 50, 0, 13.5, 255, 255, 125, 0, true)
            TimerQueue:callDelayed(2., ApplyNagaAtkSpeed, caster)
        elseif sid == FourCC('A04W') then --naga massive aoe
            FloatingTextUnit("Miasma", caster, 2, 50, 0, 13.5, 255, 255, 125, 0, true)
            SetUnitAnimation(caster, "channel")
            TimerQueue:callDelayed(2., NagaMiasmaDamage, caster, 41)
            for i = 0, 3 do
                local sfx = AddSpecialEffect("Abilities\\Spells\\Undead\\PlagueCloud\\PlagueCloudCaster.mdl", GetUnitX(caster) + 175 * Cos(bj_PI * i / 2 + (bj_PI / 4.)), GetUnitY(caster) + 175 * Sin(bj_PI * i / 2 + (bj_PI / 4.)))
                BlzSetSpecialEffectScale(sfx, 2.)
                TimerQueue:callDelayed(21., DestroyEffect, sfx)
            end
        elseif sid == FourCC('A05C') then --naga wisp thing?
            FloatingTextUnit("Spirit Call", caster, 2, 50, 0, 13.5, 255, 255, 125, 0, true)
            SpiritCall()
        elseif sid == FourCC('A05K') then --naga boss rock fall
            FloatingTextUnit("Collapse", caster, 2, 50, 0, 13.5, 255, 255, 125, 0, true)
            NagaCollapse()
        end
    end



    --Simple spells
    UNIT_SPELLS = {
        [FourCC('A0KI')] = function(caster, pid) --meat golem taunt
            Taunt(caster, pid, 800., true, 2000, 0)
        end,

        [FourCC('A03V')] = function(caster, pid, _, itm) --Move Item (Hero)
            if itm and not IS_INVENTORY_DISABLED[pid] then
                UnitRemoveItem(caster, itm)
                UnitAddItem(Backpack[pid], itm)
            end
        end,

        [FourCC('A0L0')] = function(_, pid) --Hero Info
            DisplayStatWindow(Hero[pid], pid)
        end,

        [FourCC('A0GD')] = function(_, pid, _, itm) --Item Info
            ItemInfo(pid, Item[itm])
        end,

        [FourCC('A06X')] = function(_, pid) --Quest Progress
            DisplayQuestProgress(pid)
        end,

        [FourCC('A08Y')] = function(_, pid) --Auto Attack Toggle
            ToggleAutoAttack(pid)
        end,

        [FourCC('A00I')] = function(_, pid) --Item stacking Toggle
            ToggleItemStacking(pid)
        end,

        [FourCC('A00B')] = function(_, pid) --Movement Toggle
            IS_M2_MOVEMENT[pid] = not IS_M2_MOVEMENT[pid]
            if IS_M2_MOVEMENT[pid] then
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Movement Toggle enabled.")
            else
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Movement Toggle disabled.")
            end
        end,

        [FourCC('A02T')] = function(_, pid) --Hero Panels
            DisplayHeroPanel(pid)
        end,

        [FourCC('A031')] = function(_, pid) --Damage Numbers
            if DMG_NUMBERS[pid] == 0 then
                DMG_NUMBERS[pid] = 1
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Damage Numbers for allied damage received disabled.")
            elseif DMG_NUMBERS[pid] == 1 then
                DMG_NUMBERS[pid] = 2
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Damage Numbers for all damage disabled.")
            else
                DMG_NUMBERS[pid] = 0
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Damage Numbers enabled.")
            end
        end,

        [FourCC('A067')] = function(_, pid) --Deselect Backpack
            if BP_DESELECT[pid] then
                BP_DESELECT[pid] = false
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Deselect Backpack disabled.")
            else
                BP_DESELECT[pid] = true
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Deselect Backpack enabled.")
            end
        end,

        [FourCC('A0DT')] = function(caster, pid, _, itm) --Move Item (Backpack)
            if itm and not IS_INVENTORY_DISABLED[pid] then
                UnitRemoveItem(caster, itm)
                UnitAddItem(Hero[pid], itm)
            end
        end,
        [FourCC('A0KX')] = function(_, pid) --Change Skin
            BackpackSkin(pid)
        end,

        [FourCC('A04N')] = function(_, pid) --Special Effects
            DisplaySpecialEffects(pid)
        end,

        [FourCC('A00R')] = function(_, pid) --Backpack Next Page
            local itm

            for i = MAX_INVENTORY_SLOTS + 5, 12, -1 do --iterate through hidden slots back to front
                Profile[pid].hero.items[i] = Profile[pid].hero.items[i - 6]
            end

            for i = 0, 5 do
                itm = UnitItemInSlot(Backpack[pid], i)
                UnitRemoveItem(Backpack[pid], itm)
                SetItemPosition(itm, 30000., 30000.)
                SetItemVisible(itm, false)
            end

            for i = 0, 5 do
                if Profile[pid].hero.items[MAX_INVENTORY_SLOTS + i] then
                    itm = Profile[pid].hero.items[MAX_INVENTORY_SLOTS + i].obj
                    SetItemVisible(itm, true)
                    UnitAddItem(Backpack[pid], itm)
                    UnitDropItemSlot(Backpack[pid], itm, i)
                    Profile[pid].hero.items[MAX_INVENTORY_SLOTS + i] = nil
                end
            end
        end,


    }

    --Not simple spells
    BORROWEDLIFE = Spell.define('A071')
    do
        local thistype = BORROWEDLIFE

        function thistype:onCast()
            if GetUnitTypeId(self.target) == SUMMON_HOUND and GetOwningPlayer(self.target) == p then
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", self.target, "chest"))
                SummonExpire(self.target)

                local time = 120

                if self.ablev > 1 then
                    time = time / ((self.ablev - 1) * 2) --60, 30, 20, 15
                end

                Unit[self.target].borrowed_life = time
            end
        end
    end

    DEVOUR_GOLEM = Spell.define('A06C')
    do
        local thistype = DEVOUR_GOLEM

        function thistype:onCast()
            local golem = Unit[self.caster]
            if GetUnitTypeId(self.target) == SUMMON_HOUND and GetOwningPlayer(self.target) == p and golem.devour_stacks < GetUnitAbilityLevel(Hero[self.pid], DEVOUR.id) + 1 then
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", self.target, "chest"))
                SummonExpire(self.target)

                local missile = Missiles:create(self.targetX, self.targetY, 30., 0, 0, 100.) ---@type Missiles
                missile:model("war3mapImported\\Haunt_v2_Portrait.mdl")

                missile:scale(1.1)
                missile:speed(1000)
                missile:arc(5)
                missile.source = self.caster
                missile.target = self.caster
                missile.collideZ = true
                missile.owner = p
                missile:vision(400)

                missile.onFinish = function()
                    golem.borrowed_life = 0
                    UnitAddBonus(missile.source, BONUS_HERO_STR, - R2I(golem.str * 0.1 * golem.devour_stacks))
                    if golem.devour_stacks > 0 then
                        golem.mr = golem.mr / (0.75 - golem.devour_stacks * 0.1)
                    end
                    golem.devour_stacks = golem.devour_stacks + 1
                    BlzSetHeroProperName(missile.source, "Meat Golem (" .. (golem.devour_stacks) .. ")")
                    FloatingTextUnit(tostring(golem.devour_stacks), missile.source, 1, 60, 50, 13.5, 255, 255, 255, 0, true)
                    UnitAddBonus(missile.source, BONUS_HERO_STR, R2I(golem.str * 0.1 * golem.devour_stacks))
                    SetUnitScale(missile.source, 1 + golem.devour_stacks * 0.07, 1 + golem.devour_stacks * 0.07, 1 + golem.devour_stacks * 0.07)
                    --magnetic
                    if golem.devour_stacks == 1 then
                        UnitAddAbility(missile.source, BORROWEDLIFE.id)
                    elseif golem.devour_stacks == 2 then
                        UnitAddAbility(missile.source, MAGNETIC_FORCE.id)
                    --thunder clap
                    elseif golem.devour_stacks == 3 then
                        UnitAddAbility(missile.source, THUNDER_CLAP_GOLEM.id)
                    elseif golem.devour_stacks == 5 then
                        UnitAddBonus(missile.source, BONUS_ARMOR, R2I(BlzGetUnitArmor(missile.source) * 0.25 + 0.5))
                    end
                    if golem.devour_stacks >= GetUnitAbilityLevel(Hero[self.pid], DEVOUR.id) + 1 then
                        UnitDisableAbility(missile.source, thistype.id, true)
                    end
                    SetUnitAbilityLevel(missile.source, BORROWEDLIFE.id, golem.devour_stacks)

                    --magic resist -(25-30) percent
                    Unit[missile.source].mr = Unit[missile.source].mr * (0.75 - golem.devour_stacks * 0.1)

                    return true
                end

                missile:launch()
            end
        end
    end

    DEVOUR_DESTROYER = Spell.define('A04Z')
    do
        local thistype = DEVOUR_DESTROYER

        function thistype:onCast()
            local destroyer = Unit[self.caster]
            if GetUnitTypeId(self.target) == SUMMON_HOUND and GetOwningPlayer(self.target) == p and destroyer.devour_stacks < GetUnitAbilityLevel(Hero[self.pid], DEVOUR.id) + 1 then
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", self.target, "chest"))
                SummonExpire(self.target)

                local missile = Missiles:create(self.targetX, self.targetY, 30., 0, 0, 100.) ---@type Missiles
                missile:model("war3mapImported\\Haunt_v2_Portrait.mdl")

                missile:scale(1.1)
                missile:speed(1000)
                missile:arc(5)
                missile.source = self.caster
                missile.target = self.caster
                missile.collideZ = true
                missile.owner = p
                missile:vision(400)

                missile.onFinish = function()
                    destroyer.borrowed_life = 0
                    UnitAddBonus(missile.source, BONUS_HERO_INT, - R2I(GetHeroInt(missile.source, false) * 0.15 * destroyer.devour_stacks))
                    destroyer.devour_stacks = destroyer.devour_stacks + 1
                    UnitAddBonus(missile.source, BONUS_HERO_INT, R2I(GetHeroInt(missile.source, false) * 0.15 * destroyer.devour_stacks))
                    BlzSetHeroProperName(missile.source, "Destroyer (" .. (destroyer.devour_stacks) .. ")")
                    FloatingTextUnit(tostring(destroyer.devour_stacks), missile.source, 1, 60, 50, 13.5, 255, 255, 255, 0, true)
                    if destroyer.devour_stacks == 1 then
                        UnitAddAbility(missile.source, BORROWEDLIFE.id)
                        UnitAddAbility(missile.source, FourCC('A061')) --blink
                    elseif destroyer.devour_stacks == 2 then
                        UnitAddAbility(missile.source, FourCC('A03B')) --crit
                        destroyer.cc_flat = destroyer.cc_flat + 25
                        destroyer.cd_flat = destroyer.cd_flat + 200
                    elseif destroyer.devour_stacks == 3 then
                        SetHeroAgi(missile.source, 200, true)
                    elseif destroyer.devour_stacks == 4 then
                        SetUnitAbilityLevel(missile.source, FourCC('A02D'), 2)
                    elseif destroyer.devour_stacks == 5 then
                        SetHeroAgi(missile.source, 400, true)
                        UnitAddBonus(missile.source, BONUS_HERO_INT, R2I(GetHeroInt(missile.source, false) * 0.25))
                    end
                    if destroyer.devour_stacks >= GetUnitAbilityLevel(Hero[self.pid], DEVOUR.id) + 1 then
                        UnitDisableAbility(missile.source, thistype.id, true)
                    end
                    SetUnitAbilityLevel(missile.source, BORROWEDLIFE.id, destroyer.devour_stacks)

                    return true
                end

                missile:launch()
            end
        end
    end

    MAGNETIC_FORCE = Spell.define('A06O')
    do
        local thistype = MAGNETIC_FORCE

        ---@type fun(pid: integer, dur: number)
        local function pull(pid, dur)
            dur = dur - 0.05

            if dur > 0 then
                local ug = CreateGroup()

                MakeGroupInRange(pid, ug, GetUnitX(meatgolem[pid]), GetUnitY(meatgolem[pid]), 600. * LBOOST[pid], Condition(FilterEnemy))

                for target in each(ug) do
                    local angle = Atan2(GetUnitY(meatgolem[pid]) - GetUnitY(target), GetUnitX(meatgolem[pid]) - GetUnitX(target))
                    if GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(GetUnitX(target) + (7. * Cos(angle)), GetUnitY(target) + (7. * Sin(angle))) then
                        SetUnitXBounded(target, GetUnitX(target) + (7. * Cos(angle)))
                        SetUnitYBounded(target, GetUnitY(target) + (7. * Sin(angle)))
                    end
                end

                TimerQueue:callDelayed(0.05, pull, pid, dur)

                DestroyGroup(ug)
            end
        end

        function thistype:onCast()
            TimerQueue:callDelayed(0.05, pull, self.pid, 10)
        end
    end

    THUNDER_CLAP_GOLEM = Spell.define('A0B0')
    do
        local thistype = THUNDER_CLAP_GOLEM

        function thistype:onCast()
            local ug = CreateGroup()
            MakeGroupInRange(self.pid, ug, self.x, self.y, 300., Condition(FilterEnemy))

            for target in each(ug) do
                MeatGolemThunderClap:add(self.caster, target):duration(3.)
            end

            DestroyGroup(ug)
        end
    end

    TELEPORT = Spell.define('A02J')
    do
        local thistype = TELEPORT

        ---@type fun(pid: integer, u: unit, dur: number)
        local function teleport(pid, u, dur)
            local pt = TimerList[pid]:add()
            local x, y = GetUnitX(u), GetUnitY(u)

            Unit[Hero[pid]].teleporting = true
            BlzPauseUnitEx(Backpack[pid], true)
            TimerQueue:callDelayed(dur, DestroyEffect, AddSpecialEffect("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportTo.mdl", x, y))
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", Backpack[pid], "origin"))
            pt.onRemove = function()
                Unit[Hero[pid]].teleporting = false
                BlzPauseUnitEx(Backpack[pid], false)

                if UnitAlive(Hero[pid]) and GetRectFromCoords(GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) == GetRectFromCoords(x, y) then
                    SetUnitPosition(Hero[pid], x, y)
                    SetUnitPosition(Backpack[pid], x, y)
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportTarget.mdl", GetUnitX(Hero[pid]), GetUnitY(Hero[pid])))
                end
            end

            pt.timer:callDelayed(dur, PlayerTimer.destroy, pt)
        end

        function thistype:onCast()
            if self.ablev > 1 then
                teleport(self.pid, self.target, 3 - self.ablev * .25)
            else
                teleport(self.pid, self.target, 3)
            end
        end
    end

    TELEPORT_HOME = Spell.define('A0FV')
    do
        local thistype = TELEPORT_HOME

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - 0.05

            BlzSetSpecialEffectTime(pt.sfx, math.max(0, 1. - pt.dur / pt.time))

            if pt.dur < 0 then
                pt:destroy()
            else
                pt.timer:callDelayed(0.05, periodic, pt)
            end
        end

        ---@param pid integer
        ---@param dur integer
        local function teleport(pid, dur)
            local pt  = TimerList[pid]:add()

            Unit[Hero[pid]].teleporting = true
            PauseUnit(Backpack[pid], true)
            PauseUnit(Hero[pid], true)
            UnitAddAbility(Hero[pid], FourCC('A050'))
            BlzUnitHideAbility(Hero[pid], FourCC('A050'), true)

            pt.dur = dur
            pt.time = dur
            pt.sfx = AddSpecialEffect("war3mapImported\\Progressbar.mdl", GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 125.0)
            pt.onRemove = function()
                Unit[Hero[pid]].teleporting = false
                UnitRemoveAbility(Hero[pid], FourCC('A050'))
                PauseUnit(Hero[pid], false)
                PauseUnit(Backpack[pid], false)

                MoveHeroLoc(pid, TownCenter)

                BlzSetSpecialEffectTimeScale(pt.sfx, 5.)
                BlzPlaySpecialEffect(pt.sfx, ANIM_TYPE_DEATH)
            end

            BlzSetSpecialEffectZ(pt.sfx, 500.0)
            BlzSetSpecialEffectTimeScale(pt.sfx, 0.001)
            BlzSetSpecialEffectColorByPlayer(pt.sfx, Player(4))
            pt.timer:callDelayed(0.05, periodic, pt)
        end

        function thistype:onCast()
            if self.ablev > 1 then
                teleport(self.pid, 11 - self.ablev)
            else
                teleport(self.pid, 12)
            end
        end
    end

    local onenemyspell = CreateTrigger()
    TriggerRegisterPlayerUnitEvent(onenemyspell, pfoe, EVENT_PLAYER_UNIT_SPELL_EFFECT, nil)
    TriggerAddAction(onenemyspell, EnemySpells)

end, Debug and Debug.getLine())
