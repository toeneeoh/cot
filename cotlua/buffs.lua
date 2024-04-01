if Debug then Debug.beginFile 'Buffs' end

--[[
    buffs.lua

    A module that contains most of the triggered buffs and debuffs in the game.
]]

OnInit.global("Buffs", function(require)
    require 'BuffSystem'
    require 'UnitTable'

    local mt = { __index = Buff }

    ---@class Disarm : Buff
    Disarm = setmetatable({}, mt)
    do
        local thistype = Disarm
        thistype.RAWCODE         = FourCC('Adar') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].attack = true
        end

        function thistype:onApply()
            Unit[self.target].attack = false
        end
    end

    ---@class Silence : Buff
    Silence = setmetatable({}, mt)
    do
        local thistype = Silence
        thistype.RAWCODE         = FourCC('Asil') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
            ToggleCommandCard(self.target, true)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\Silence\\SilenceTarget.mdl", self.target, "overhead")
            ToggleCommandCard(self.target, false)
        end
    end

    ---@class Fear : Buff
    Fear = setmetatable({}, mt)
    do
        local thistype = Fear
        thistype.RAWCODE         = FourCC('Afea') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            UnitRemoveAbility(self.target, FourCC('ARal'))
            ToggleCommandCard(self.target, true)

            Unit[self.target].attack = true
        end

        function thistype:onApply()
            local angle = Atan2(GetUnitY(self.target) - GetUnitY(self.source), GetUnitX(self.target) - GetUnitX(self.source)) ---@type number 

            IssuePointOrder(self.target, "move", GetUnitX(self.target) + 2000. * Cos(angle), GetUnitY(self.target) + 2000. * Sin(angle))
            ToggleCommandCard(self.target, false)
            UnitAddAbility(self.target, FourCC('ARal'))

            Unit[self.target].attack = false
        end
    end

    ---@class Lava : Buff
    Lava = setmetatable({}, mt)
    do
        local thistype = Lava
        thistype.RAWCODE         = 0
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:periodic()
            if not IsUnitInRegion(LAVA_REGION, self.target) then
                self:remove()
            else
                local dmg = BlzGetUnitMaxHP(self.target) / 40. + 1000.

                if BlzGetUnitZ(self.target) < 60. then
                    DamageTarget(DummyUnit, self.target, dmg, ATTACK_TYPE_NORMAL, PURE, "Lava")
                end

                self.timer:callDelayed(1.5, thistype.periodic, self)
            end
        end

        function thistype:onRemove()
            self.timer:destroy()
        end

        function thistype:onApply()
            self.timer = TimerQueue.create()
            self.timer:callDelayed(0.5, thistype.periodic, self)
        end
    end

    ---@class OmnislashBuff : Buff
    OmnislashBuff = setmetatable({}, mt)
    do
        local thistype = OmnislashBuff
        thistype.RAWCODE         = FourCC('Aomn') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            Unit[self.target].dr = Unit[self.target].dr / 0.2
        end

        function thistype:onApply()
            Unit[self.target].dr = Unit[self.target].dr * 0.2
        end
    end

    ---@class InspireBuff : Buff
    InspireBuff = setmetatable({}, mt)
    do
        local thistype = InspireBuff
        thistype.RAWCODE         = FourCC('Ains') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ablev         = 0 ---@type integer 

        function thistype:strongest(new)
            if self.ablev < new then
                BoostValue[self.tpid] = BoostValue[self.tpid] - self.spellboost

                self.ablev = new
                self.spellboost = math.max(0.91 - 0.01 * self.ablev, 0.85)
                BoostValue[self.tpid] = BoostValue[self.tpid] + self.spellboost
            end
        end

        --mana cost per second
        ---@type fun(self: InspireBuff)
        function thistype:periodic()
            local mana = GetUnitState(self.target, UNIT_STATE_MANA)
            local cost = BlzGetUnitMaxMana(self.target) * 0.02
            SetUnitState(self.target, UNIT_STATE_MANA, math.max(mana - cost, 0))
            if mana - cost > 0 then
                self.timer:callDelayed(1, thistype.periodic, self)
            else
                self:remove()
            end
        end

        function thistype:onRemove()
            BoostValue[self.tpid] = BoostValue[self.tpid] - self.spellboost

            if self.source == self.target then
                --unimmolation
                self.timer:destroy()
                IssueImmediateOrderById(self.source, 852178)
            end
        end

        function thistype:onApply()
            self.ablev = GetUnitAbilityLevel(self.source, INSPIRE.id)
            self.spellboost = (0.08 + 0.02 * self.ablev)
            BoostValue[self.tpid] = BoostValue[self.tpid] + self.spellboost

            if self.source == self.target then
                self.timer = TimerQueue.create()
                self.timer:callDelayed(1, thistype.periodic, self)
            end
        end
    end

    ---@class SongOfWarBuff : Buff
    SongOfWarBuff = setmetatable({}, mt)
    do
        local thistype = SongOfWarBuff
        thistype.RAWCODE         = FourCC('Aswb') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 
        thistype.attack      = 0. ---@type number 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_DAMAGE, -self.attack)
        end

        function thistype:onApply()
            self.attack = (BlzGetUnitBaseDamage(self.target, 0) + UnitGetBonus(self.target, BONUS_DAMAGE)) * 0.2
            UnitAddBonus(self.target, BONUS_DAMAGE, self.attack)
        end
    end

    ---@class SongOfPeaceEncoreBuff : Buff
    SongOfPeaceEncoreBuff = setmetatable({}, mt)
    do
        local thistype = SongOfPeaceEncoreBuff
        thistype.RAWCODE         = FourCC('Aspc') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            Unit[self.target].dr = Unit[self.target].dr / 0.8
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\DivineShield\\DivineShieldTarget.mdl", self.target, "origin")

            Unit[self.target].dr = Unit[self.target].dr * 0.8
        end
    end

    ---@class SongOfWarEncoreBuff : Buff
    SongOfWarEncoreBuff = setmetatable({}, mt)
    do
        local thistype = SongOfWarEncoreBuff
        thistype.RAWCODE         = FourCC('Aswa') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 
        thistype.count         = 10 ---@type integer 
        thistype.dmg      = 0. ---@type number 

        function thistype:onHit()
            self.count = self.count - 1

            if self.count <= 0 then
                self:remove()
            end
        end

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.dmg = (.25 + .25 * GetUnitAbilityLevel(self.source, ENCORE.id)) * GetHeroStat(MainStat(self.target), self.target, true)

            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Items\\VampiricPotion\\VampPotionCaster.mdl", self.target, "origin")
        end
    end

    ---@class MagneticStanceBuff : Buff
    MagneticStanceBuff = setmetatable({}, mt)
    do
        local thistype = MagneticStanceBuff
        thistype.RAWCODE         = FourCC('Amag') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.timer = nil ---@type TimerQueue

        ---@param pid integer
        ---@param target unit
        local function pull(pid, target)
            local ug = CreateGroup()

            MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 500. * LBOOST[pid], Condition(FilterEnemy))

            for i = 0, BlzGroupGetSize(ug) - 1 do
                local u = BlzGroupUnitAt(ug, i)
                local angle = Atan2(GetUnitY(target) - GetUnitY(u), GetUnitX(target) - GetUnitX(u))
                UnitWakeUp(u)
                if GetUnitMoveSpeed(u) > 0 and (GetUnitCurrentOrder(u) == 0 or GetUnitCurrentOrder(u) == 851971) and IsTerrainWalkable(GetUnitX(u) + (3. * Cos(angle)), GetUnitY(u) + (3. * Sin(angle))) and UnitDistance(u, target) > 100. then
                    SetUnitXBounded(u, GetUnitX(u) + (3. * Cos(angle)))
                    SetUnitYBounded(u, GetUnitY(u) + (3. * Sin(angle)))
                end
            end

            DestroyGroup(ug)
        end

        function thistype:onRemove()
            SetUnitVertexColor(self.target, 255, 255, 255, 255)

            self.timer:destroy()
            Unit[self.target].dr = Unit[self.target].dr / self.dr
        end

        function thistype:onApply()
            self.timer = TimerQueue.create()

            SetUnitVertexColor(self.target, 255, 25, 25, 255)
            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Call of Dread Red.mdx", self.target, "chest"))

            self.timer:callPeriodically(3., nil, Taunt, self.target, self.tpid, 800., false, 500, 500)
            self.timer:callPeriodically(0.1, nil, pull, self.tpid, self.target)

            self.dr = (0.95 - 0.05 * GetUnitAbilityLevel(self.source, MAGNETICSTANCE.id))

            Unit[self.target].dr = Unit[self.target].dr * self.dr
        end
    end

    ---@class FlamingBowBuff : Buff
    FlamingBowBuff = setmetatable({}, mt)
    do
        local thistype = FlamingBowBuff
        thistype.RAWCODE         = FourCC('Afbo') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.count      = 0. ---@type number 
        thistype.attack      = 0. ---@type number 

        function thistype:onHit()
            local ablev = GetUnitAbilityLevel(self.target, FLAMINGBOW.id) ---@type integer 

            UnitAddBonus(self.target, BONUS_DAMAGE, -self.attack)

            if MultiShot[self.tpid] then
                self.count = math.min(self.count + 1. // (2 + IMinBJ(GetHeroLevel(self.target), 200) // 50), 30. + 2. * ablev)
            else
                self.count = math.min(self.count + 1., 30. + 2. * ablev)
            end
            self.attack = (0.5 + 0.01 * self.count) * (GetHeroAgi(self.target, true) + UnitGetBonus(self.target, BONUS_DAMAGE)) * LBOOST[self.tpid]

            UnitAddBonus(self.target, BONUS_DAMAGE, self.attack)
        end

        function thistype:onRemove()
            DestroyEffect(self.sfx)
            UnitRemoveAbility(self.target, FourCC('A08B'))
            UnitAddBonus(self.target, BONUS_DAMAGE, -self.attack)
        end

        function thistype:onApply()
            self.attack = FLAMINGBOW.bonus(self.tpid)

            self.sfx = AddSpecialEffectTarget("Environment\\SmallBuildingspeffect\\SmallBuildingspeffect2.mdl", self.target, "weapon")
            UnitAddAbility(self.target, FourCC('A08B'))
            UnitAddBonus(self.target, BONUS_DAMAGE, self.attack)
        end
    end

    ---@class StasisFieldDebuff : Buff
    StasisFieldDebuff = setmetatable({}, mt)
    do
        local thistype = StasisFieldDebuff
        thistype.RAWCODE         = FourCC('Asfi') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            SetUnitPropWindow(self.target, bj_DEGTORAD * 60.)
            SetUnitPathing(self.target, true)
        end

        function thistype:onApply()
            SetUnitPropWindow(self.target, 0)
        end
    end

    ---@class ArcanosphereDebuff : Buff
    ArcanosphereDebuff = setmetatable({}, mt)
    do
        local thistype = ArcanosphereDebuff
        thistype.RAWCODE         = FourCC('Aarc') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * 0.75

            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
        end
    end

    ---@class ControlTimeBuff : Buff
    ControlTimeBuff = setmetatable({}, mt)
    do
        local thistype = ControlTimeBuff
        thistype.RAWCODE         = FourCC('Acti') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) / 0.5, 0)
        end

        function thistype:onApply()
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) * 0.5, 0)
        end
    end

    ---@class MarkedForDeathDebuff : Buff
    MarkedForDeathDebuff = setmetatable({}, mt)
    do
        local thistype = MarkedForDeathDebuff
        thistype.RAWCODE         = FourCC('Amar') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            SetUnitPathing(self.target, true)

            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)

            BlzSetSpecialEffectScale(self.sfx, 0)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            SetUnitPathing(self.target, false)

            self.ms = GetUnitMoveSpeed(self.target) * 0.5
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)

            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\Banish\\BanishTarget.mdl", self.target, "chest")
        end
    end

    ---@class FightMeCasterBuff : Buff
    FightMeCasterBuff = setmetatable({}, mt)
    do
        local thistype = FightMeCasterBuff
        thistype.RAWCODE         = FourCC('Afmc') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Voodoo\\VoodooAura.mdl", self.target, "origin")
        end
    end

    ---@class RoyalPlateBuff : Buff
    RoyalPlateBuff = setmetatable({}, mt)
    do
        local thistype = RoyalPlateBuff
        thistype.RAWCODE         = FourCC('Aroy') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.armor      = 0. ---@type number 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ARMOR, -self.armor)
        end

        function thistype:onApply()
            self.armor = ROYALPLATE.armor(self.tpid) * BOOST[self.tpid]

            if ShieldCount[self.tpid] > 0 then
                self.armor = self.armor * 1.3
            end

            UnitAddBonus(self.target, BONUS_ARMOR, self.armor)
        end
    end

    ---@class DemonicSacrificeBuff : Buff
    DemonicSacrificeBuff = setmetatable({}, mt)
    do
        local thistype = DemonicSacrificeBuff
        thistype.RAWCODE         = FourCC('Adsa') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            BoostValue[self.tpid] = BoostValue[self.tpid] - 0.15
        end

        function thistype:onApply()
            BoostValue[self.tpid] = BoostValue[self.tpid] + 0.15
        end
    end

    ---@class JusticeAuraBuff : Buff
    JusticeAuraBuff = setmetatable({}, mt)
    do
        local thistype = JusticeAuraBuff
        thistype.RAWCODE         = FourCC('Ajap') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ablev         = 0 ---@type integer 

        function thistype:strongest(new)
            if self.ablev < new then
                Unit[self.target].pr = Unit[self.target].pr / self.pr

                self.ablev = new
                self.pr = math.max(0.91 - 0.01 * self.ablev, 0.85)
                Unit[self.target].pr = Unit[self.target].pr * self.pr
            end
        end

        function thistype:onRemove()
            Unit[self.target].pr = Unit[self.target].pr / self.pr
        end

        function thistype:onApply()
            self.ablev = GetUnitAbilityLevel(self.source, AURAOFJUSTICE.id)
            self.pr = math.max(0.91 - 0.01 * self.ablev, 0.85)

            Unit[self.target].pr = Unit[self.target].pr * self.pr
        end
    end

    ---@class SoulLinkBuff : Buff
    SoulLinkBuff = setmetatable({}, mt)
    do
        local thistype = SoulLinkBuff
        thistype.RAWCODE         = FourCC('Asli') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.hp      = 0. ---@type number 
        thistype.mana      = 0. ---@type number 
        thistype.lfx           = nil ---@type lightning 
        thistype.timer = nil ---@type TimerQueue

        function thistype:onRemove()
            FadeSFX(self.sfx, true)
            TimerQueue:callDelayed(2., HideEffect, self.sfx)
            DestroyLightning(self.lfx)

            HP(self.source, self.target, math.max(0., self.hp - GetWidgetLife(self.target)), SOULLINK.tag)
            if GetUnitTypeId(self.target) ~= HERO_VAMPIRE then
                MP(self.target, math.max(0., self.mana - GetUnitState(self.target, UNIT_STATE_MANA)))
            end

            self.timer:destroy()
        end

        function thistype:onApply()
            local angle  = math.rad(GetUnitFacing(self.target) - 180) ---@type number 
            local x      = GetUnitX(self.target) + 75. * math.cos(angle) ---@type number 
            local y      = GetUnitY(self.target) + 75. * math.sin(angle) ---@type number 

            self.hp = GetWidgetLife(self.target)
            self.mana = GetUnitState(self.target, UNIT_STATE_MANA)

            BlzSetItemSkin(PathItem, BlzGetUnitSkin(self.target))
            self.sfx = AddSpecialEffect(BlzGetItemStringField(PathItem, ITEM_SF_MODEL_USED), x, y)
            self.lfx = AddLightningEx("HCHA", false, x, y, BlzGetUnitZ(self.target) + 75., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 75.)
            BlzSetItemSkin(PathItem, BlzGetUnitSkin(DummyUnit))

            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\AIil\\AIilTarget.mdl", x, y))

            BlzSetSpecialEffectYaw(self.sfx, angle + bj_PI)
            BlzSetSpecialEffectColorByPlayer(self.sfx, GetOwningPlayer(self.target))
            BlzSetSpecialEffectColor(self.sfx, 255, 255, 0)
            BlzSetSpecialEffectAlpha(self.sfx, 100)

            self.timer = TimerQueue.create()

            local periodic = function()
                MoveLightningEx(self.lfx, false, x, y, BlzGetUnitZ(self.target) + 75., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 75.)
            end

            self.timer:callPeriodically(FPS_32, nil, periodic)
        end
    end

    ---@class LawOfMightBuff : Buff
    LawOfMightBuff = setmetatable({}, mt)
    do
        local thistype = LawOfMightBuff
        thistype.RAWCODE         = FourCC('Almi') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.main         = 0 ---@type integer 
        thistype.bonus         = 0 ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            UnitAddBonus(self.target, self.main + 2, -self.bonus)
        end

        function thistype:onApply()
            self.main = HighestStat(self.target)

            self.bonus = R2I(GetHeroStat(self.main, self.target, true) * LAWOFMIGHT.pbonus(self.pid) * 0.01 * LBOOST[self.pid] + LAWOFMIGHT.fbonus(self.pid) * BOOST[self.pid])
            UnitAddBonus(self.target, self.main + 2, self.bonus)

            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\InnerFire\\InnerFireTarget.mdl", self.target, "overhead")
        end
    end

    ---@class LawOfValorBuff : Buff
    LawOfValorBuff = setmetatable({}, mt)
    do
        local thistype = LawOfValorBuff
        thistype.RAWCODE         = FourCC('Alva') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.regen      = 0. ---@type number 
        thistype.percent         = 0 ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            Unit[self.target].regen = Unit[self.target].regen - self.regen
            Unit[self.target].healamp = Unit[self.target].healamp - self.percent * 0.01
        end

        function thistype:onApply()
            self.regen = LAWOFVALOR.regen(self.pid) * BOOST[self.pid]
            self.percent = R2I(LAWOFVALOR.amp(self.pid))

            Unit[self.target].regen = Unit[self.target].regen + self.regen
            Unit[self.target].healamp = Unit[self.target].healamp + self.percent * 0.01

            self.sfx = AddSpecialEffectTarget("war3mapImported\\RunicShield.mdx", self.target, "chest")
        end
    end

    ---@class LawOfResonanceBuff : Buff
    LawOfResonanceBuff = setmetatable({}, mt)
    do
        local thistype = LawOfResonanceBuff
        thistype.RAWCODE         = FourCC('Alre') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.multiplier      = 0. ---@type number 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.multiplier = LAWOFRESONANCE.echo(self.pid) * 0.01

            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\Parasite\\ParasiteTarget.mdl", self.target, "overhead")
            BlzSetSpecialEffectColor(self.sfx, 60, 60, 255)
            BlzSetSpecialEffectTimeScale(self.sfx, 2.)
        end
    end

    ---@class OverloadBuff : Buff
    OverloadBuff = setmetatable({}, mt)
    do
        local thistype = OverloadBuff
        thistype.RAWCODE         = FourCC('Aove') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.timer = nil ---@type TimerQueue

        function thistype:onRemove()
            IssueImmediateOrder(self.target, "unimmolation")

            DestroyEffect(self.sfx)
            self.timer:destroy()
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Windwalk Blue Soul.mdx", self.target, "origin")

            local periodic = function()
                local mana = GetUnitState(self.target, UNIT_STATE_MANA) ---@type number 
                local maxmana = BlzGetUnitMaxMana(self.target) * 0.02 ---@type number 

                if UnitAlive(self.target) and mana >= maxmana then
                    SetUnitState(self.target, UNIT_STATE_MANA, mana - maxmana)
                else
                    self:remove()
                end
            end

            self.timer = TimerQueue.create()
            self.timer:callPeriodically(1., nil, periodic)
        end
    end

    ---@class BloodMistBuff : Buff
    BloodMistBuff = setmetatable({}, mt)
    do
        local thistype = BloodMistBuff
        thistype.RAWCODE         = FourCC('Abmi') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms = 0

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] - self.ms
            UnitRemoveAbility(self.target, FourCC('B02Q'))

            self.timer:destroy()
        end

        function thistype:periodic()
            local blood = BLOODBANK.get(self.tpid)

            if blood >= BLOODMIST.cost(self.tpid) then
                BLOODBANK.add(self.tpid, -BLOODMIST.cost(self.tpid))
                HP(self.target, self.target, BLOODMIST.heal(self.tpid) * BOOST[self.tpid], BLOODMIST.tag)
                if self.ms == 0 then
                    self.ms = 50 + 50 * GetUnitAbilityLevel(self.source, BLOODMIST.id)
                    BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] + self.ms
                    PlayerAddItemById(self.tpid, FourCC('I0OE'))
                    BlzSetSpecialEffectColor(self.sfx, 255, 255, 255)
                end
            else
                BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] - self.ms
                self.ms = 0
                UnitRemoveAbility(self.target, FourCC('B02Q'))
                BlzSetSpecialEffectColor(self.sfx, 0, 0, 0)
            end

            self.timer:callDelayed(1., thistype.periodic, self)
        end

        function thistype:onApply()
            local ablev = GetUnitAbilityLevel(self.target, BLOODMIST.id)

            if BLOODBANK.get(self.tpid) >= BLOODMIST.cost(self.tpid, ablev) then
                self.ms = 50 + 50 * GetUnitAbilityLevel(self.target, BLOODMIST.id)
                BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] + self.ms
            end

            self.sfx = AddSpecialEffectTarget("war3mapImported\\Chumpool.mdx", self.target, "origin")

            self.timer = TimerQueue.create()
            self.timer:callDelayed(0.5, thistype.periodic, self)
        end
    end

    ---@class BloodLordBuff : Buff
    BloodLordBuff = setmetatable({}, mt)
    do
        local thistype = BloodLordBuff
        thistype.RAWCODE         = FourCC('Ablr') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.agi      = 0. ---@type number 
        thistype.str      = 0. ---@type number 

        function thistype.periodic(self)
            local ug = CreateGroup()

            MakeGroupInRange(self.tpid, ug, GetUnitX(self.source), GetUnitY(self.source), 500. * LBOOST[self.tpid], Condition(FilterEnemy))

            if BlzGroupGetSize(ug) > 0 then
                DestroyEffect(AddSpecialEffectTarget("war3mapImported\\DarknessLeechTarget_Portrait.mdx", self.source, "origin"))
            end

            for target in each(ug) do
                BLOODBANK.add(self.tpid, BLOODLEECH.gain(self.tpid) / 3.)
                DamageTarget(self.source, target, BLOODLEECH.dmg(self.tpid) / 3. * BOOST[self.tpid], ATTACK_TYPE_NORMAL, MAGIC, BLOODLORD.tag)

                local dummy = Dummy.create(GetUnitX(target), GetUnitY(target), FourCC('A0A1'), 1).unit
                BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(GetUnitY(self.source) - GetUnitY(dummy), GetUnitX(self.source) - GetUnitX(dummy)))
                InstantAttack(dummy, self.source)
            end

            DestroyGroup(ug)

            self.timer:callDelayed(1, thistype.periodic, self)
        end

        function thistype:onRemove()
            BlzSetUnitAttackCooldown(self.source, BlzGetUnitAttackCooldown(self.source, 0) / 0.7, 0)
            UnitAddBonus(self.source, BONUS_HERO_AGI, -self.agi)
            UnitAddBonus(self.source, BONUS_HERO_STR, -self.str)

            self.agi = 0.
            self.str = 0.

            if self.timer ~= nil then
                UnitDisableAbility(self.source, BLOODLEECH.id, false)
                UnitDisableAbility(self.source, BLOODDOMAIN.id, false)
                self.timer:destroy()
            end
        end

        function thistype:onApply()
            if GetHeroAgi(self.source, true) > GetHeroStr(self.source, true) then
                UnitDisableAbility(self.source, BLOODLEECH.id, true)
                BlzUnitHideAbility(self.source, BLOODLEECH.id, false)
                UnitDisableAbility(self.source, BLOODDOMAIN.id, true)
                BlzUnitHideAbility(self.source, BLOODDOMAIN.id, false)

                --blood leech aoe
                self.timer = TimerQueue.create()
                self.timer:callDelayed(1., thistype.periodic, self)
                self.agi = BLOODLORD.bonus(self.pid)
                UnitAddBonus(self.source, BONUS_HERO_AGI, self.agi)
            else
                self.str = BLOODLORD.bonus(self.pid)
                UnitAddBonus(self.source, BONUS_HERO_STR, self.str)
            end

            BlzSetUnitAttackCooldown(self.source, BlzGetUnitAttackCooldown(self.source, 0) * 0.7, 0)
            TimerQueue:callDelayed(BLOODLORD.dur(self.pid) * LBOOST[self.pid], DestroyEffect, AddSpecialEffectTarget("war3mapImported\\Burning Rage Red.mdx", self.source, "overhead"))
            SetUnitAnimationByIndex(self.source, 3)

            BLOODBANK.set(self.tpid, 0)
        end
    end

    ---@class ManaDrainDebuff : Buff
    ManaDrainDebuff = setmetatable({}, mt)
    do
        local thistype = ManaDrainDebuff
        thistype.RAWCODE         = FourCC('Amdr') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype.drain(self, x, y)
            local mana = GetUnitState(self.target, UNIT_STATE_MANA) ---@type number 

            if mana > 0. then
                mana = math.max(0., mana - 1000.)
                SetUnitState(self.target, UNIT_STATE_MANA, mana)
                SetUnitState(self.source, UNIT_STATE_MANA, GetUnitState(self.source, UNIT_STATE_MANA) + math.min(1000., mana))

                DamageTarget(self.source, self.target, math.min(1000., mana) * 2., ATTACK_TYPE_NORMAL, MAGIC, "Mana Drain")
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\ManaBurn\\ManaBurnTarget.mdl", self.target, "chest"))
            end

            if DistanceCoords(x, y, GetUnitX(self.target), GetUnitY(self.target)) > 800. or not UnitAlive(self.source) then
                self:remove()
            else
                self.timer:callDelayed(FPS_32, thistype.periodic, self, x, y)
            end
        end

        function thistype.periodic(self)
            MoveLightningEx(self.lfx, false, GetUnitX(self.source), GetUnitY(self.source), BlzGetUnitZ(self.source) + 50., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 50.)
            self.timer:callDelayed(FPS_32, thistype.periodic, self)
        end

        function thistype:onRemove()
            DestroyLightning(self.lfx)
            self.timer:destroy()
        end

        function thistype:onApply()
            self.lfx = AddLightningEx("DRAM", false, GetUnitX(self.source), GetUnitY(self.source), BlzGetUnitZ(self.source) + 50., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 50.)
            self.timer = TimerQueue.create()

            MoveLightningEx(self.lfx, false, GetUnitX(self.source), GetUnitY(self.source), BlzGetUnitZ(self.source) + 50., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 50.)

            self.timer:callDelayed(1., thistype.drain, self, GetUnitX(self.source), GetUnitY(self.source))
            self.timer:callDelayed(FPS_32, thistype.periodic, self)
        end
    end

    ---@class SpinDashDebuff : Buff
    SpinDashDebuff = setmetatable({}, mt)
    do
        local thistype = SpinDashDebuff
        thistype.RAWCODE         = FourCC('Asda') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.as      = 1.25 ---@type number 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) / self.as, 0)
        end

        function thistype:onApply()
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) * self.as, 0)

            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\StasisTrap\\StasisTotemTarget.mdl", self.target, "overhead")
        end
    end

    ---@class ParryBuff : Buff
    ParryBuff = setmetatable({}, mt)
    do
        local thistype = ParryBuff
        thistype.RAWCODE         = FourCC('Apar') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.soundPlayed         = false ---@type boolean 

        function thistype:playSound()
            if not self.soundPlayed then
                self.soundPlayed = true

                SoundHandler("war3mapImported\\parry" .. GetRandomInt(1, 2) .. ".mp3", true, GetOwningPlayer(self.target), self.target)
            end
        end

        function thistype:onRemove()
            AddUnitAnimationProperties(self.target, "ready", false)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            AddUnitAnimationProperties(self.target, "ready", true)

            self.sfx = AddSpecialEffectTarget("war3mapImported\\Buff_Shield_Non.mdx", self.target, "chest")

            if limitBreak[self.tpid] & 0x1 > 0 then
                BlzSetSpecialEffectColor(self.sfx, 255, 255, 0)
            end
        end
    end

    ---@class IntimidatingShoutBuff : Buff
    IntimidatingShoutBuff = setmetatable({}, mt)
    do
        local thistype = IntimidatingShoutBuff
        thistype.RAWCODE         = FourCC('Ainb') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.dmg      = 0. ---@type number 

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            UnitAddBonus(self.target, BONUS_DAMAGE, -self.dmg)
        end

        function thistype:onApply()
            local stat = GetHeroStat(MainStat(self.target), self.target, true) ---@type integer 

            if stat > 0 then
                self.dmg = math.max(0., (stat + UnitGetBonus(self.target, BONUS_DAMAGE)) * 0.4)
            else
                self.dmg = math.max(0., (BlzGetUnitBaseDamage(self.target, 0) + UnitGetBonus(self.target, BONUS_DAMAGE)) * 0.4)
            end

            self.sfx = AddSpecialEffectTarget("war3mapImported\\BattleCryTarget.mdx", self.target, "overhead")

            UnitAddBonus(self.target, BONUS_DAMAGE, self.dmg)
        end
    end

    ---@class IntimidatingShoutDebuff : Buff
    IntimidatingShoutDebuff = setmetatable({}, mt)
    do
        local thistype = IntimidatingShoutDebuff
        thistype.RAWCODE         = FourCC('Aint') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.dmg      = 0. ---@type number 

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            UnitAddBonus(self.target, BONUS_DAMAGE, self.dmg)
        end

        function thistype:onApply()
            self.dmg = math.max(0., (BlzGetUnitBaseDamage(self.target, 0) + UnitGetBonus(self.target, BONUS_DAMAGE)) * 0.4)

            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\HowlOfTerror\\HowlTarget.mdl", self.target, "overhead")

            UnitAddBonus(self.target, BONUS_DAMAGE, -self.dmg)
        end
    end

    ---@class UndyingRageBuff : Buff
    UndyingRageBuff = setmetatable({}, mt)
    do
        local thistype = UndyingRageBuff
        thistype.RAWCODE         = FourCC('Arag') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.totalRegen      = 0. ---@type number 
        thistype.text         = nil ---@type texttag 
        thistype.bonusRegen      = 0. ---@type number 
        thistype.timer      = nil ---@type TimerQueue

        ---@param dmg number
        function thistype:addRegen(dmg)
            self.totalRegen = math.max(-200., math.min(200., self.totalRegen + dmg / BlzGetUnitMaxHP(self.target) * 100))
        end

        function thistype:onRemove()
            self.timer:destroy()
            Unit[self.target].regen = Unit[self.target].regen - self.bonusRegen

            DestroyEffect(self.sfx)
            DestroyTextTag(self.text)

            if self.totalRegen >= 0 then
                HP(self.target, self.target, BlzGetUnitMaxHP(self.target) * 0.01 * self.totalRegen, UNDYINGRAGE.tag)
            else
                DamageTarget(self.target, self.target, BlzGetUnitMaxHP(self.target) * 0.01 * -self.totalRegen, ATTACK_TYPE_NORMAL, PURE, UNDYINGRAGE.tag)
            end

            Unit[self.target].noregen = false
            UnitSetBonus(self.target, BONUS_LIFE_REGEN, Unit[self.target].regen * Unit[self.target].healamp)
        end

        local periodic = function(self)
            SetTextTagText(self.text, (R2I(self.totalRegen)) .. "\x25", 0.025)
            local red, green, blue = HealthGradient(self.totalRegen, false) ---@type integer, integer, integer
            SetTextTagColor(self.text, red, green, blue, 255)
            SetTextTagPosUnit(self.text, self.target, -200.)

            --percent
            self:addRegen(Unit[self.target].regen * FPS_32)

            SetWidgetLife(self.target, math.max(10., BlzGetUnitMaxHP(self.target) * 0.0001))
        end

        function thistype:onApply()
            self.text = CreateTextTag()
            self.totalRegen = 0.
            SetTextTagText(self.text, (R2I(self.totalRegen)) .. "\x25", 0.025)
            SetTextTagColor(self.text, R2I(Pow(100 - self.totalRegen, 1.1)), R2I(SquareRoot(math.max(0, self.totalRegen) * 500)), 0, 255)

            Unit[self.target].noregen = true
            UnitSetBonus(self.target, BONUS_LIFE_REGEN, 0)

            self.sfx = AddSpecialEffectTarget("war3mapImported\\DemonicAdornment.mdx", self.target, "head")

            self.timer = TimerQueue.create()
            self.timer:callPeriodically(FPS_32, nil, periodic, self)
        end
    end

    ---@class RampageBuff : Buff
    RampageBuff = setmetatable({}, mt)
    do
        local thistype = RampageBuff
        thistype.RAWCODE         = FourCC('Aram') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 
        thistype.timer        = nil ---@type TimerQueue

        function thistype:onRemove()
            BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] - 100

            self.timer:destroy()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] + 100

            self.sfx = AddSpecialEffectTarget("war3mapImported\\Windwalk Blood.mdx", self.source, "origin")

            self.timer = TimerQueue.create()

            local periodic = function()
                DamageTarget(self.source, self.source, 0.08 * GetWidgetLife(self.source), ATTACK_TYPE_NORMAL, PURE, "Rampage")
            end

            periodic()
            self.timer:callPeriodically(1., nil, periodic)
        end
    end

    ---@class FrostArmorDebuff : Buff
    FrostArmorDebuff = setmetatable({}, mt)
    do
        local thistype = FrostArmorDebuff
        thistype.RAWCODE         = FourCC('Afde') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms = 0 ---@type integer 

        function thistype:onRemove()
            BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] + self.ms
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) / 1.25, 0)
        end

        function thistype:onApply()
            self.ms = R2I(Movespeed[self.tpid] * 0.25)

            BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] - self.ms
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) * 1.25, 0)
        end
    end

    ---@class FrostArmorBuff : Buff
    FrostArmorBuff = setmetatable({}, mt)
    do
        local thistype = FrostArmorBuff
        thistype.RAWCODE         = FourCC('Afar') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            UnitAddBonus(self.source, BONUS_ARMOR, -100.)

            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\FrostArmor\\FrostArmorTarget.mdl", self.source, "chest")

            UnitAddBonus(self.source, BONUS_ARMOR, 100.)
        end
    end

    ---@class MagneticStrikeDebuff : Buff
    MagneticStrikeDebuff = setmetatable({}, mt)
    do
        local thistype = MagneticStrikeDebuff
        thistype.RAWCODE         = FourCC('Amsd') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
    end

    ---@class MagneticStrikeBuff : Buff
    MagneticStrikeBuff = setmetatable({}, mt)
    do
        local thistype = MagneticStrikeBuff
        thistype.RAWCODE         = FourCC('Amst') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
    end

    ---@class InfernalStrikeBuff : Buff
    InfernalStrikeBuff = setmetatable({}, mt)
    do
        local thistype = InfernalStrikeBuff
        thistype.RAWCODE         = FourCC('Aist') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
    end

    ---@class PiercingStrikeDebuff : Buff
    PiercingStrikeDebuff = setmetatable({}, mt)
    do
        local thistype = PiercingStrikeDebuff
        thistype.RAWCODE         = FourCC('Apie') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Armor Penetration Orange.mdx", self.target, "overhead")

            BlzSetSpecialEffectScale(self.sfx, 0)
            if GetLocalPlayer() == GetOwningPlayer(self.source) then
                BlzSetSpecialEffectScale(self.sfx, 1)
            end
        end
    end

    ---@class FightMeBuff : Buff
    FightMeBuff = setmetatable({}, mt)
    do
        local thistype = FightMeBuff
        thistype.RAWCODE         = FourCC('Aftm') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            HeroInvul[self.pid] = false
        end

        function thistype:onApply()
            HeroInvul[self.pid] = true
        end
    end

    ---@class RighteousMightBuff : Buff
    RighteousMightBuff = setmetatable({}, mt)
    do
        local thistype = RighteousMightBuff
        thistype.RAWCODE         = FourCC('Armi') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.dmg = 0. ---@type number 
        thistype.armor = 0. ---@type number 
        thistype.timer = nil ---@type TimerQueue

        local function grow(timer, source, size, dur)
            size = size + 0.008
            SetUnitScale(source, size, size, size)
            dur = dur - 1

            if dur > 0 then
                timer:callDelayed(FPS_32, grow, timer, source, size, dur)
            end
        end

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_DAMAGE, -self.dmg)
            UnitAddBonus(self.target, BONUS_ARMOR, -self.armor)

            self.timer:destroy()
            SetUnitScale(self.target, BlzGetUnitRealField(self.target, UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(self.target, UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(self.target, UNIT_RF_SCALING_VALUE))
            Unit[self.target].mr = Unit[self.target].mr / 0.2
        end

        function thistype:onApply()
            local size = BlzGetUnitRealField(self.target, UNIT_RF_SCALING_VALUE)

            UnitAddBonus(self.target, BONUS_DAMAGE, self.dmg)
            UnitAddBonus(self.target, BONUS_ARMOR, self.armor)

            self.timer = TimerQueue.create()
            self.timer:callDelayed(FPS_32, grow, self.timer, self.target, size, 60)

            --80% magic resist
            Unit[self.target].mr = Unit[self.target].mr * 0.2
        end
    end

    ---@class BloodFrenzyBuff : Buff
    BloodFrenzyBuff = setmetatable({}, mt)
    do
        local thistype = BloodFrenzyBuff
        thistype.RAWCODE         = FourCC('A07E') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) * 1.50, 0)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Bloodlust\\BloodlustTarget.mdl", self.target, "chest")

            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) / 1.50, 0)
            DamageTarget(self.source, self.source, 0.15 * BlzGetUnitMaxHP(self.source), ATTACK_TYPE_NORMAL, PURE, BLOODFRENZY.tag)
        end
    end

    ---@class EarthDebuff : Buff
    EarthDebuff = setmetatable({}, mt)
    do
        local thistype = EarthDebuff
        thistype.RAWCODE         = FourCC('A04P') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
    end

    ---@class SteedChargeStun : Buff
    SteedChargeStun = setmetatable({}, mt)
    do
        local thistype = SteedChargeStun
        thistype.RAWCODE         = FourCC('AIDK') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.timer         =  nil ---@type TimerQueue

        function thistype:onRemove()
            self.timer:destroy()
        end

        function thistype:onApply()
            if IsUnitType(self.target, UNIT_TYPE_HERO) == false then
                local startangle = GetUnitFacing(self.source) * bj_DEGTORAD
                local enemyangle = Atan2(GetUnitY(self.target) - GetUnitY(self.source), GetUnitX(self.target) - GetUnitX(self.source))
                local endangle = startangle - bj_PI
                local angle = GetUnitFacing(self.source) * bj_DEGTORAD - bj_PI * 0.5

                if endangle < 0 then
                    endangle = endangle + 2. * bj_PI
                end
                if endangle > startangle then
                    if enemyangle > startangle and enemyangle < endangle then
                        angle = GetUnitFacing(self.source) * bj_DEGTORAD + bj_PI * 0.5
                    end
                else
                    if enemyangle < endangle or enemyangle > startangle then
                        angle = GetUnitFacing(self.source) * bj_DEGTORAD + bj_PI * 0.5
                    end
                end

                local dur = 33
                local x = GetUnitX(self.target) + 200. * Cos(angle)
                local y = GetUnitY(self.target) + 200. * Sin(angle)
                local dist = DistanceCoords(x, y, GetUnitX(self.target), GetUnitY(self.target)) ---@type number 

                local cond = function() return dur <= 0 or dist >= 250. end
                local periodic = function()
                    x = GetUnitX(self.target) + 200. * Cos(angle)
                    y = GetUnitY(self.target) + 200. * Sin(angle)
                    dist = DistanceCoords(x, y, GetUnitX(self.target), GetUnitY(self.target)) ---@type number 
                    dur = dur - 1

                    if GetUnitMoveSpeed(self.target) > 0 then
                        SetUnitXBounded(self.target, GetUnitX(self.target) + (5 + dist) * 0.1 * Cos(angle))
                        SetUnitYBounded(self.target, GetUnitY(self.target) + (5 + dist) * 0.1 * Sin(angle))
                    end
                end

                self.timer = TimerQueue.create()
                self.timer:callPeriodically(FPS_32, cond, periodic)
            end
        end
    end

    ---@class SingleShotDebuff : Buff
    SingleShotDebuff = setmetatable({}, mt)
    do
        local thistype = SingleShotDebuff
        thistype.RAWCODE         = FourCC('A950') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * 0.5
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Cripple\\CrippleTarget.mdl", self.target, "chest")

            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
        end
    end

    ---@class FreezingBlastDebuff : Buff
    FreezingBlastDebuff = setmetatable({}, mt)
    do
        local thistype = FreezingBlastDebuff
        thistype.RAWCODE         = FourCC('A01O') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms = 0. ---@type number 

        function thistype:onRemove()
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * 0.3

            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
        end
    end

    ---@class ProtectedBuff : Buff
    ProtectedBuff = setmetatable({}, mt)
    do
        local thistype = ProtectedBuff
        thistype.RAWCODE         = FourCC('A09I') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].dr = Unit[self.target].dr / self.dr
        end

        function thistype:onApply()
            self.dr = (0.93 - 0.02 * GetUnitAbilityLevel(self.source, PROTECTOR.id))

            Unit[self.target].dr = Unit[self.target].dr * self.dr
        end
    end

    ---@class AstralShieldBuff : Buff
    AstralShieldBuff = setmetatable({}, mt)
    do
        local thistype = AstralShieldBuff
        thistype.RAWCODE         = FourCC('Azas') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("war3mapImported\\DemonShieldTarget3A.mdx", self.target, "origin")
        end
    end

    ---@class ProtectedExistenceBuff : Buff
    ProtectedExistenceBuff = setmetatable({}, mt)
    do
        local thistype = ProtectedExistenceBuff
        thistype.RAWCODE         = FourCC('Aexi') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("war3mapImported\\DemonShieldTarget3A.mdx", self.target, "origin")
        end
    end

    ---@class ProtectionBuff : Buff
    ProtectionBuff = setmetatable({}, mt)
    do
        local thistype = ProtectionBuff
        thistype.RAWCODE         = FourCC('Apro') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.as      = 1.1 ---@type number 

        function thistype:onRemove()
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) * self.as, 0)
        end

        function thistype:onApply()
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) / self.as, 0)
        end
    end

    ---@class SanctifiedGroundDebuff : Buff
    SanctifiedGroundDebuff = setmetatable({}, mt)
    do
        local thistype = SanctifiedGroundDebuff
        thistype.RAWCODE         = FourCC('Asan') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.regen      = 0. ---@type number 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_LIFE_REGEN, self.regen)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * SANCTIFIEDGROUND.ms * 0.01

            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)

            if IsBoss(self.target) < 0 then
                self.regen = UnitGetBonus(self.target, BONUS_LIFE_REGEN)
                UnitAddBonus(self.target, BONUS_LIFE_REGEN, -self.regen)
            end
        end
    end

    ---@class DivineLightBuff : Buff
    DivineLightBuff = setmetatable({}, mt)
    do
        local thistype = DivineLightBuff
        thistype.RAWCODE         = FourCC('Adiv') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms         = 0 ---@type integer 

        function thistype:onRemove()
            BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] - self.ms
        end

        function thistype:onApply()
            self.ms = 25 + 25 * GetUnitAbilityLevel(self.source, DIVINELIGHT.id)

            BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] + self.ms
        end
    end

    ---@class SmokebombBuff : Buff
    SmokebombBuff = setmetatable({}, mt)
    do
        local thistype = SmokebombBuff
        thistype.RAWCODE         = FourCC('Asmk') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.evasion = 0.

        function thistype:onRemove()
            Unit[self.target].evasion = Unit[self.target].evasion - self.evasion
        end

        function thistype:onApply()
            if self.source == self.target then
                self.evasion = self.evasion + (9 + GetUnitAbilityLevel(self.source, SMOKEBOMB.id)) * 2
            else
                self.evasion = self.evasion + 9 + GetUnitAbilityLevel(self.source, SMOKEBOMB.id)
            end

            Unit[self.target].evasion = Unit[self.target].evasion + self.evasion
        end
    end

    ---@class SmokebombDebuff : Buff
    SmokebombDebuff = setmetatable({}, mt)
    do
        local thistype = SmokebombDebuff
        thistype.RAWCODE         = FourCC('A03S') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * (0.28 + 0.02 * GetUnitAbilityLevel(self.source, SMOKEBOMB.id))

            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
        end
    end

    ---@class AzazothHammerStomp : Buff
    AzazothHammerStomp = setmetatable({}, mt)
    do
        local thistype = AzazothHammerStomp
        thistype.RAWCODE         = FourCC('A00C') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .35)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\StasisTrap\\StasisTotemTarget.mdl", self.target, "overhead")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.35)
        end
    end

    ---@class BloodCurdlingScreamDebuff : Buff
    BloodCurdlingScreamDebuff = setmetatable({}, mt)
    do
        local thistype = BloodCurdlingScreamDebuff
        thistype.RAWCODE         = FourCC('Ascr') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.armor         = 0 ---@type integer 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ARMOR, self.armor)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.armor = IMaxBJ(0, R2I(BlzGetUnitArmor(self.target) * (0.12 + 0.02 * GetUnitAbilityLevel(self.source, FourCC('A06H'))) + 0.5))
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\HowlOfTerror\\HowlTarget.mdl", self.target, "chest")

            UnitAddBonus(self.target, BONUS_ARMOR, -self.armor)
        end
    end

    ---@class NerveGasDebuff : Buff
    NerveGasDebuff = setmetatable({}, mt)
    do
        local thistype = NerveGasDebuff
        thistype.RAWCODE         = FourCC('Agas') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 
        thistype.armor         = 0 ---@type integer 

        function thistype.periodic(self)
            local dmg = NERVEGAS.dmg(self.pid) * BOOST[self.pid] / (NERVEGAS.dur * LBOOST[self.pid] * 0.5)

            DamageTarget(self.source, self.target, dmg, ATTACK_TYPE_NORMAL, MAGIC, "Nerve Gas")

            self.timer:callDelayed(0.5, thistype.periodic, self)
        end

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .3)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
            UnitAddBonus(self.target, BONUS_ARMOR, self.armor)
            DestroyEffect(self.sfx)
            self.timer:destroy()
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * 0.3
            self.armor = R2I(BlzGetUnitArmor(self.target) * 0.2)
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\AcidBomb\\BottleImpact.mdl", self.target, "chest")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.3)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
            UnitAddBonus(self.target, BONUS_ARMOR, -self.armor)

            self.timer = TimerQueue.create()
            self.timer:callDelayed(0.25, thistype.periodic, self)
        end
    end

    ---@class DemonPrinceBloodlust : Buff
    DemonPrinceBloodlust = setmetatable({}, mt)
    do
        local thistype = DemonPrinceBloodlust
        thistype.RAWCODE         = FourCC('Ablo') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.75)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * .5

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .75)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
        end
    end

    ---@class FireElementBuff : Buff
    FireElementBuff = setmetatable({}, mt)
    do
        local thistype = FireElementBuff
        thistype.RAWCODE         = FourCC('Aefr') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            masterElement[self.tpid] = 0
            DestroyEffect(self.sfx)
            DestroyEffect(self.sfx2)
            BoostValue[self.tpid] = BoostValue[self.tpid] - 0.15
        end

        function thistype:onApply()
            masterElement[self.tpid] = ELEMENTFIRE.value
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Fire Uber.mdx", self.target, "right hand")
            self.sfx2 = AddSpecialEffectTarget("war3mapImported\\Fire Uber.mdx", self.target, "left hand")
            BoostValue[self.tpid] = BoostValue[self.tpid] + 0.15
        end
    end

    ---@class IceElementBuff : Buff
    IceElementBuff = setmetatable({}, mt)
    do
        local thistype = IceElementBuff
        thistype.RAWCODE         = FourCC('Aeic') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            masterElement[self.tpid] = 0
            DestroyEffect(self.sfx)
            DestroyEffect(self.sfx2)
        end

        function thistype:onApply()
            masterElement[self.tpid] = ELEMENTICE.value
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Water High.mdx", self.target, "right hand")
            self.sfx2 = AddSpecialEffectTarget("war3mapImported\\Water High.mdx", self.target, "left hand")
        end
    end

    ---@class LightningElementBuff : Buff
    LightningElementBuff = setmetatable({}, mt)
    do
        local thistype = LightningElementBuff
        thistype.RAWCODE         = FourCC('Alig') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        ---@type fun(self: LightningElementBuff)
        function thistype:periodic()
            if UnitAlive(self.target) then
                local ug = CreateGroup()
                local x = GetUnitX(self.target)
                local y = GetUnitY(self.target)

                MakeGroupInRange(self.tpid, ug, x, y, 900., Condition(FilterEnemy))

                local target = FirstOfGroup(ug)
                if target then
                    local dummy = Dummy.create(x, y, FourCC('A09W'), 1, 1.).unit
                    SetUnitOwner(dummy, Player(self.tpid - 1), false)
                    BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(GetUnitY(target) - y, GetUnitX(target) - x))
                    InstantAttack(dummy, target)
                end

                DestroyGroup(ug)
            end

            self.timer:callDelayed(5., self.periodic, self)
        end

        function thistype:onRemove()
            masterElement[self.tpid] = 0
            DestroyEffect(self.sfx)
            DestroyEffect(self.sfx2)
            self.timer:destroy()
        end

        function thistype:onApply()
            masterElement[self.tpid] = ELEMENTLIGHTNING.value
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Storm Cast.mdx", self.target, "right hand")
            self.sfx2 = AddSpecialEffectTarget("war3mapImported\\Storm Cast.mdx", self.target, "left hand")

            self.timer = TimerQueue.create()
            self.timer:callDelayed(5., self.periodic, self)
        end
    end

    ---@class EarthElementBuff : Buff
    EarthElementBuff = setmetatable({}, mt)
    do
        local thistype = EarthElementBuff
        thistype.RAWCODE         = FourCC('Aeea') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            masterElement[self.tpid] = 0
            DestroyEffect(self.sfx)
            DestroyEffect(self.sfx2)
            Unit[self.target].dr = Unit[self.target].dr / 0.75
        end

        function thistype:onApply()
            masterElement[self.tpid] = ELEMENTEARTH.value
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Earth High.mdx", self.target, "right hand")
            self.sfx2 = AddSpecialEffectTarget("war3mapImported\\Earth High.mdx", self.target, "left hand")
            Unit[self.target].dr = Unit[self.target].dr * 0.75
        end
    end

    ---@class IceElementSlow : Buff
    IceElementSlow = setmetatable({}, mt)
    do
        local thistype = IceElementSlow
        thistype.RAWCODE         = FourCC('Aice') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .25)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * .35
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\FrostDamage\\FrostDamage.mdl", self.target, "chest")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.25)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
        end
    end

    ---@class TidalWaveDebuff : Buff
    TidalWaveDebuff = setmetatable({}, mt)
    do
        local thistype = TidalWaveDebuff
        thistype.RAWCODE         = FourCC('Atwa') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.percent      = .15 ---@type number 
    end

    ---@class SoakedDebuff : Buff
    SoakedDebuff = setmetatable({}, mt)
    do
        local thistype = SoakedDebuff
        thistype.RAWCODE         = FourCC('A01G') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .3)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * .5
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\FrostDamage\\FrostDamage.mdl", self.target, "chest")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.3)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
        end
    end

    ---@class SongOfFatigueSlow : Buff
    SongOfFatigueSlow = setmetatable({}, mt)
    do
        local thistype = SongOfFatigueSlow
        thistype.RAWCODE         = FourCC('A00X') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .3)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * 0.3
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\slow\\slowtarget.mdl", self.target, "origin")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.3)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
        end
    end

    ---@class MeatGolemThunderClap : Buff
    MeatGolemThunderClap = setmetatable({}, mt)
    do
        local thistype = MeatGolemThunderClap
        thistype.RAWCODE         = FourCC('A00C') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .3)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * 0.3
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\StasisTrap\\StasisTotemTarget.mdl", self.target, "overhead")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.3)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
        end
    end

    ---@class SaviorThunderClap : Buff
    SaviorThunderClap = setmetatable({}, mt)
    do
        local thistype = SaviorThunderClap
        thistype.RAWCODE         = FourCC('A013') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .35)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * 0.35
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\StasisTrap\\StasisTotemTarget.mdl", self.target, "overhead")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.35)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
        end
    end

    ---@class BlinkStrikeBuff : Buff
    BlinkStrikeBuff = setmetatable({}, mt)
    do
        local thistype = BlinkStrikeBuff
        thistype.RAWCODE         = FourCC('A03Y') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Windwalk.mdx", self.target, "origin")
        end
    end

    ---@class NagaThorns : Buff
    NagaThorns = setmetatable({}, mt)
    do
        local thistype = NagaThorns

        thistype.RAWCODE         = FourCC('A04S') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onApply()
            TimerQueue:callDelayed(6.5, DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Undead\\ThornyShield\\ThornyShieldTargetChestLeft.mdl", self.target, "chest"))
            TimerQueue:callDelayed(2.5, DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\ThornsAura\\ThornsAura.mdl", self.target, "origin"))
        end
    end

    ---@class NagaEliteAtkSpeed : Buff
    NagaEliteAtkSpeed = setmetatable({}, mt)
    do
        local thistype = NagaEliteAtkSpeed

        thistype.RAWCODE         = FourCC('A04L') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -8.)
        end

        function thistype:onApply()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, 8.)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", self.target, "chest"))
        end
    end

    ---@class SpiritCallSlow : Buff
    SpiritCallSlow = setmetatable({}, mt)
    do
        local thistype = SpiritCallSlow
        thistype.RAWCODE         = FourCC('A05M') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] + self.ms
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * 0.3

            BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] - self.ms
        end
    end

    ---@class LightSealBuff : Buff
    LightSealBuff = setmetatable({}, mt)
    do
        local thistype = LightSealBuff
        thistype.RAWCODE         = FourCC('Alse') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.strength         = 0 ---@type integer 
        thistype.armor         = 0 ---@type integer 
        thistype.stacks         = 0 ---@type integer 
        thistype.timer         = nil ---@type TimerQueue

        ---@param i integer
        function thistype:addStack(i)
            UnitAddBonus(self.source, BONUS_HERO_STR, -self.strength)
            UnitAddBonus(self.source, BONUS_ARMOR, -self.armor)

            self.stacks = IMinBJ(self.stacks + i, GetUnitAbilityLevel(self.source, LIGHTSEAL.id) * 10)
            self.strength = R2I(GetHeroStr(self.source, true) * 0.01 * self.stacks)
            self.armor = R2I(BlzGetUnitArmor(self.source) * 0.01 * self.stacks)

            UnitAddBonus(self.source, BONUS_HERO_STR, self.strength)
            UnitAddBonus(self.source, BONUS_ARMOR, self.armor)
        end

        function thistype:onRemove()
            self.timer:destroy()
        end

        ---@type fun(self: LightSealBuff)
        local function LightSealStackExpire(self)
            if self.stacks <= 0 then
                self:remove()
            else
                self.stacks = IMaxBJ(0, self.stacks - 1)

                UnitAddBonus(self.source, BONUS_HERO_STR, -self.strength)
                UnitAddBonus(self.source, BONUS_ARMOR, -self.armor)

                self.strength = R2I(GetHeroStr(self.source, true) * 0.01 * self.stacks)
                self.armor = R2I(BlzGetUnitArmor(self.source) * 0.01 * self.stacks)

                UnitAddBonus(self.source, BONUS_HERO_STR, self.strength)
                UnitAddBonus(self.source, BONUS_ARMOR, self.armor)
            end
        end

        function thistype:onApply()
            self.timer = TimerQueue.create()

            self.timer:callDelayed(5., LightSealStackExpire, self)
        end
    end

    ---@class DarkSealDebuff : Buff
    DarkSealDebuff = setmetatable({}, mt)
    do
        local thistype = DarkSealDebuff
        thistype.RAWCODE         = FourCC('A06W') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 
    end

    ---@class DarkSealBuff : Buff
    ---@field x number
    ---@field y number
    ---@field count number
    ---@field sfx unit
    DarkSealBuff = setmetatable({}, mt)
    do
        local thistype = DarkSealBuff
        thistype.RAWCODE         = FourCC('Adsb') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        ---@type fun(self: DarkSealBuff)
        function thistype:periodic()
            MakeGroupInRange(self.tpid, self.ug, self.x, self.y, 450. * LBOOST[self.pid], Condition(FilterEnemy))

            --count units in seal
            self.count = 0.
            for target in each(self.ug) do
                if IsUnitType(target, UNIT_TYPE_HERO) then
                    self.count = self.count + 10.
                else
                    self.count = self.count + 1.
                end
                DarkSealDebuff:add(self.source, target):duration(1.)
            end
            self.count = math.min(5. + GetHeroLevel(self.source) // 100 * 10, self.count)

            self:refresh()
            self.timer:callDelayed(0.5, self.periodic, self)
        end

        --reapplies spellboost and bat bonus
        function thistype:refresh()
            BoostValue[self.tpid] = BoostValue[self.tpid] - self.spellboost
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) * self.bat, 0)

            self.spellboost = self.count * 0.01
            self.bat = (1. + self.count * 0.01)
            BoostValue[self.tpid] = BoostValue[self.tpid] + self.spellboost
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) / self.bat, 0)
        end

        function thistype:onRemove()
            BoostValue[self.tpid] = BoostValue[self.tpid] - self.spellboost
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) * self.bat, 0)

            Dummy[self.sfx]:recycle()

            DestroyGroup(self.ug)
            self.timer:destroy()
        end

        function thistype:onApply()
            self.spellboost = 0
            self.bat = 1
            self.ug = CreateGroup()
            self.count = 0.
            self.timer = TimerQueue:create()
            self.timer:callDelayed(0.01, thistype.refresh, self)
        end
    end

    ---@class KnockUp : Buff
    KnockUp = setmetatable({}, mt)
    do
        local thistype = KnockUp
        thistype.RAWCODE         = FourCC('Akno') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.SPEED      = 1500. ---@type number 
        thistype.DEBUFF_TIME      = 1. ---@type number 
        thistype.time      = 0. ---@type number 

        ---@param deltaTime number
        ---@return number
        local function calcHeight(deltaTime)
            local g = 9.81 ---@type number 
            local h = 0. ---@type number 

            deltaTime = deltaTime * 1.2

            if deltaTime <= thistype.DEBUFF_TIME * 0.5 then
                h = thistype.SPEED * deltaTime - 0.5 * g * deltaTime * deltaTime
            else
                deltaTime = deltaTime * 1.2
                h = thistype.SPEED * (thistype.DEBUFF_TIME - deltaTime) - 0.5 * g * (thistype.DEBUFF_TIME - deltaTime) * (thistype.DEBUFF_TIME - deltaTime)
            end

            return math.max(0, h)
        end

        function thistype:periodic()
            self.time = self.time + FPS_32
            SetUnitFlyHeight(self.target, calcHeight(self.time), 0.)

            if self.time > thistype.DEBUFF_TIME then
                self:remove()
            else
                self.timer:callDelayed(FPS_32, thistype.periodic, self)
            end
        end

        function thistype:onRemove()
            BlzPauseUnitEx(self.target, false)
            SetUnitFlyHeight(self.target, 0., 0.)
            self.timer:destroy()
        end

        function thistype:onApply()
            BlzPauseUnitEx(self.target, true)

            if UnitAddAbility(self.target, FourCC('Amrf')) then
                UnitRemoveAbility(self.target, FourCC('Amrf'))
            end

            self.timer = TimerQueue.create()
            self.time = 0
            self.timer:callDelayed(FPS_32, thistype.periodic, self)
        end
    end

    ---@class Freeze : Buff
    Freeze = setmetatable({}, mt)
    do
        local thistype = Freeze
        thistype.RAWCODE         = FourCC('A01D') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            BlzPauseUnitEx(self.target, false)
            if GetUnitTypeId(self.source) == HERO_DARK_SAVIOR or GetUnitTypeId(self.source) == HERO_DARK_SAVIOR_DEMON then
                FreezingBlastDebuff:add(self.source, self.target):duration(FREEZINGBLAST.freeze * LBOOST[self.pid])
            end
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            BlzPauseUnitEx(self.target, true)
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\FreezingBreath\\FreezingBreathTargetArt.mdl", self.target, "chest")
        end
    end

    ---@class Stun : Buff
    Stun = setmetatable({}, mt)
    do
        local thistype = Stun
        thistype.RAWCODE         = FourCC('A08J') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            BlzPauseUnitEx(self.target, false)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            BlzPauseUnitEx(self.target, true)
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\Thunderclap\\ThunderclapTarget.mdl", self.target, "overhead")
        end
    end

    ---@class DarkestOfDarknessBuff : Buff
    DarkestOfDarknessBuff = setmetatable({}, mt)
    do
        local thistype = DarkestOfDarknessBuff
        thistype.RAWCODE         = FourCC('A056') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            Unit[self.target].dr = Unit[self.target].dr / 0.7
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("war3mapImported\\SoulArmor.mdx", self.target, "chest")

            Unit[self.target].dr = Unit[self.target].dr * 0.7
        end
    end

    ---@class HolyBlessing : Buff
    HolyBlessing = setmetatable({}, mt)
    do
        local thistype = HolyBlessing
        thistype.RAWCODE         = FourCC('A08K') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) * 2, 0)
        end

        function thistype:onApply()
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) / 2, 0)
        end
    end

    ---@class VampiricPotion : Buff
    VampiricPotion = setmetatable({}, mt)
    do
        local thistype = VampiricPotion
        thistype.RAWCODE         = FourCC('A05O') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Items\\VampiricPotion\\VampPotionCaster.mdl", self.target, "origin")
        end
    end

    ---@class WeatherBuff : Buff
    WeatherBuff = setmetatable({}, mt)
    do
        local thistype = WeatherBuff
        thistype.RAWCODE         = FourCC('Wcle') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NONE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 
        thistype.as      = 0. ---@type number 
        thistype.atk      = 0. ---@type number 
        thistype.weather         = 0 ---@type integer 

        function thistype:onRemove()
            if player_fog[self.tpid] and GetLocalPlayer() == GetOwningPlayer(self.target) and self.target == Hero[self.tpid] then
                player_fog[self.tpid] = false
                SetCineFilterTexture("ReplaceableTextures\\CameraMasks\\HazeAndFogFilter_Mask.blp")
                SetCineFilterStartColor(171, 174, WeatherTable[self.weather].blue, WeatherTable[self.weather].fog)
                SetCineFilterEndColor(171, 174, WeatherTable[self.weather].blue, 0)
                SetCineFilterBlendMode(BLEND_MODE_BLEND)
                SetCineFilterDuration(4.)
                DisplayCineFilter(true)
            end

            UnitRemoveAbility(self.target, WeatherTable[self.weather].buff)
            UnitAddBonus(self.target, BONUS_DAMAGE, -self.atk)
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) * self.as, 0)
            BoostValue[self.tpid] = BoostValue[self.tpid] - self.spellboost
            Unit[self.target].dr = Unit[self.target].dr / self.dr
        end

        function thistype:onApply()
            self.as = 1. - WeatherTable[CURRENT_WEATHER].as * 0.01
            self.atk = (BlzGetUnitBaseDamage(self.target, 0) + UnitGetBonus(self.target, BONUS_DAMAGE)) * WeatherTable[CURRENT_WEATHER].atk * 0.01
            self.weather = CURRENT_WEATHER
            self.spellboost = WeatherTable[CURRENT_WEATHER].boost * 0.01
            self.dr = (1. - WeatherTable[CURRENT_WEATHER].dr * 0.01)

            if GetLocalPlayer() == GetOwningPlayer(self.target) and WeatherTable[self.weather].fog > 0 and self.target == Hero[self.tpid] then
                player_fog[self.tpid] = true
                SetCineFilterTexture("ReplaceableTextures\\CameraMasks\\HazeAndFogFilter_Mask.blp")
                SetCineFilterStartColor(171, 174, WeatherTable[self.weather].blue, 0)
                SetCineFilterEndColor(171, 174, WeatherTable[self.weather].blue, WeatherTable[self.weather].fog)
                SetCineFilterBlendMode(BLEND_MODE_BLEND)
                SetCineFilterDuration(5.)
                DisplayCineFilter(true)
            end

            UnitAddAbility(self.target, WeatherTable[self.weather].buff)
            UnitAddBonus(self.target, BONUS_DAMAGE, self.atk)
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) / self.as, 0)
            BoostValue[self.tpid] = BoostValue[self.tpid] + self.spellboost
            Unit[self.target].dr = Unit[self.target].dr * self.dr
        end
    end
end)

if Debug then Debug.endFile() end
