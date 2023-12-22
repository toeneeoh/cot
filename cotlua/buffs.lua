if Debug then Debug.beginFile 'Buffs' end

OnInit.global("Buffs", function(require)
    require 'BuffSystem'

    ---@class Disarm : Buff
    Disarm = {} --
    do
        local thistype = Disarm
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Adar') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target]:attack(true)
        end

        function thistype:onApply()
            Unit[self.target]:attack(false)
        end
    end

    ---@class Silence : Buff
    Silence = {} --
    do
        local thistype = Silence
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Asil') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 

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
    Fear = {} --
    do
        local thistype = Fear
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Afea') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            UnitRemoveAbility(self.target, FourCC('ARal'))
            ToggleCommandCard(self.target, true)

            Unit[self.target]:attack(true)
        end

        function thistype:onApply()
            local angle = Atan2(GetUnitY(self.target) - GetUnitY(self.source), GetUnitX(self.target) - GetUnitX(self.source)) ---@type number 

            IssuePointOrder(self.target, "move", GetUnitX(self.target) + 2000. * Cos(angle), GetUnitY(self.target) + 2000. * Sin(angle))
            UnitAddAbility(self.target, FourCC('ARal'))
            ToggleCommandCard(self.target, false)

            Unit[self.target]:attack(false)
        end
    end

    ---@class InspireBuff : Buff
    InspireBuff = {} --
    do
        local thistype = InspireBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Ains') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ablev         = 0 ---@type integer 

        function thistype:onApply()
            self.ablev = GetUnitAbilityLevel(self.source, INSPIRE.id)
        end
    end

    ---@class SongOfWarBuff : Buff
    SongOfWarBuff = {} --
    do
        local thistype = SongOfWarBuff
        setmetatable(thistype, { __index = Buff })
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
    SongOfPeaceEncoreBuff = {} --
    do
        local thistype = SongOfPeaceEncoreBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Aspc') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\DivineShield\\DivineShieldTarget.mdl", self.target, "origin")
        end
    end

    ---@class SongOfWarEncoreBuff : Buff
    SongOfWarEncoreBuff = {} --
    do
        local thistype = SongOfWarEncoreBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Aswa') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 
        thistype.sfx        = nil ---@type effect 
        thistype.count         = 10 ---@type integer 
        thistype.dmg      = 0. ---@type number 

        function thistype:onHit()
            self.count = self.count - 1

            if self.count <= 0 then
                self:dispel()
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
    MagneticStanceBuff = {} --
    do
        local thistype = MagneticStanceBuff
        setmetatable(thistype, { __index = Buff })
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
        end

        function thistype:onApply()
            self.timer = TimerQueue.create()

            SetUnitVertexColor(self.target, 255, 25, 25, 255)
            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Call of Dread Red.mdx", self.target, "origin"))

            self.timer:callPeriodically(3., nil, Taunt, self.tpid, 800., false, 500, 500)
            self.timer:callPeriodically(0.1, nil, pull, self.tpid, self.target)
        end
    end

    ---@class FlamingBowBuff : Buff
    FlamingBowBuff = {} --
    do
        local thistype = FlamingBowBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Afbo') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.count      = 0. ---@type number 
        thistype.attack      = 0. ---@type number 
        thistype.sfx        = nil ---@type effect 

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
    StasisFieldDebuff = {} --
    do
        local thistype = StasisFieldDebuff
        setmetatable(thistype, { __index = Buff })
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
    ArcanosphereDebuff = {} --
    do
        local thistype = ArcanosphereDebuff
        setmetatable(thistype, { __index = Buff })
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
    ControlTimeBuff = {} --
    do
        local thistype = ControlTimeBuff
        setmetatable(thistype, { __index = Buff })
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
    MarkedForDeathDebuff = {} --
    do
        local thistype = MarkedForDeathDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Amar') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 
        thistype.ms      = 0. ---@type number 

        function thistype:onRemove()
            SetUnitPathing(self.target, true)
            TimerQueue:callDelayed(0., DestroyEffect, self.sfx)

            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
        end

        function thistype:onApply()
            SetUnitPathing(self.target, false)

            self.ms = GetUnitMoveSpeed(self.target) * 0.5
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)

            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\Banish\\BanishTarget.mdl", self.target, "chest")
        end
    end

    ---@class FightMeCasterBuff : Buff
    FightMeCasterBuff = {} --
    do
        local thistype = FightMeCasterBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Afmc') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Voodoo\\VoodooAura.mdl", self.target, "origin")
        end
    end

    ---@class RoyalPlateBuff : Buff
    RoyalPlateBuff = {} --
    do
        local thistype = RoyalPlateBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Aroy') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.armor      = 0. ---@type number 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ARMOR, -self.armor)
        end

        function thistype:onApply()
            self.armor = ROYALPLATE.armor(tpid) * BOOST[tpid]

            if ShieldCount[tpid] > 0 then
                self.armor = self.armor * 1.3
            end

            UnitAddBonus(self.target, BONUS_ARMOR, armor)
        end
    end

    ---@class DemonicSacrificeBuff : Buff
    DemonicSacrificeBuff = {} --
    do
        local thistype = DemonicSacrificeBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Adsa') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
    end

    ---@class JusticeAuraBuff : Buff
    JusticeAuraBuff = {} --
    do
        local thistype = JusticeAuraBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Ajap') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ablev         = 0 ---@type integer 

        function thistype:onApply()
            self.ablev = GetUnitAbilityLevel(self.source, AURAOFJUSTICE.id)
        end
    end

    ---@class SoulLinkBuff : Buff
    SoulLinkBuff = {} --
    do
        local thistype = SoulLinkBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Asli') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.hp      = 0. ---@type number 
        thistype.mana      = 0. ---@type number 
        thistype.lfx           = nil ---@type lightning 
        thistype.sfx        = nil ---@type effect 
        thistype.timer = nil ---@type TimerQueue

        function thistype:onRemove()
            FadeSFX(self.sfx, true)
            TimerQueue:callDelayed(2., DestroyEffect, self.sfx)
            DestroyLightning(self.lfx)

            HP(self.target, math.max(0., self.hp - GetWidgetLife(self.target)))
            if GetUnitTypeId(self.target) ~= HERO_VAMPIRE then
                MP(self.target, math.max(0., self.mana - GetUnitState(self.target, UNIT_STATE_MANA)))
            end

            self.timer:destroy()
        end

        function thistype:onApply()
            local angle      = math.rad(GetUnitFacing(self.target) - 180) ---@type number 
            local x      = GetUnitX(self.target) + 75. * math.cos(angle) ---@type number 
            local y      = GetUnitY(self.target) + 75. * math.sin(angle) ---@type number 

            self.hp = GetWidgetLife(self.target)
            self.mana = GetUnitState(self.target, UNIT_STATE_MANA)

            BlzSetItemSkin(PathItem, BlzGetUnitSkin(self.target))
            self.sfx = AddSpecialEffect(BlzGetItemStringField(PathItem, ITEM_SF_MODEL_USED), x, y)
            self.lfx = AddLightningEx("HCHA", false, x, y, BlzGetUnitZ(self.target) + 75., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 75.)
            BlzSetItemSkin(PathItem, BlzGetUnitSkin(WeatherUnit))

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
    LawOfMightBuff = {} --
    do
        local thistype = LawOfMightBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Almi') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.main         = 0 ---@type integer 
        thistype.bonus         = 0 ---@type integer 
        thistype.sfx        = nil ---@type effect 

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
    LawOfValorBuff = {} --
    do
        local thistype = LawOfValorBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Alva') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.regen      = 0. ---@type number 
        thistype.percent         = 0 ---@type integer 
        thistype.sfx        = nil ---@type effect 

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            BuffRegen[self.tpid] = BuffRegen[self.tpid] - self.regen
            PercentHealBonus[self.tpid] = PercentHealBonus[self.tpid] - self.percent
        end

        function thistype:onApply()
            self.regen = LAWOFVALOR.regen(self.pid) * BOOST[self.pid]
            self.percent = R2I(LAWOFVALOR.amp(self.pid))

            BuffRegen[self.tpid] = BuffRegen[self.tpid] + self.regen
            PercentHealBonus[self.tpid] = PercentHealBonus[self.tpid] + self.percent

            self.sfx = AddSpecialEffectTarget("war3mapImported\\RunicShield.mdx", self.target, "chest")
        end
    end

    ---@class LawOfResonanceBuff : Buff
    LawOfResonanceBuff = {} --
    do
        local thistype = LawOfResonanceBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Alre') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.multiplier      = 0. ---@type number 
        thistype.sfx        = nil ---@type effect 

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
    OverloadBuff = {} --
    do
        local thistype = OverloadBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Aove') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 
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
    BloodMistBuff = {} --
    do
        local thistype = BloodMistBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Abmi') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms         = 0 ---@type integer 
        thistype.sfx        = nil ---@type effect 
        thistype.timer        = nil ---@type TimerQueue

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] - self.ms

            self.timer:destroy()
        end

        function thistype:onApply()
            local ablev = GetUnitAbilityLevel(self.target, BLOODMIST.id)

            if BloodBank[self.tpid] >= BLOODMIST.cost(self.tpid, ablev) then
                self.ms = 50 + 50 * GetUnitAbilityLevel(self.target, BLOODMIST.id)
                BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] + self.ms
            end

            self.sfx = AddSpecialEffectTarget("war3mapImported\\Chumpool.mdx", self.target, "origin")

            self.timer = TimerQueue.create()

            local periodic = function()
                if BloodBank[self.tpid] >= BLOODMIST.cost(self.tpid, ablev) then
                    if self.ms == 0 then
                        self.ms = 50 + 50 * GetUnitAbilityLevel(self.source, BLOODMIST.id)
                        BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] + self.ms
                    end
                else
                    BuffMovespeed[self.tpid] = BuffMovespeed[self.tpid] - self.ms
                    self.ms = 0
                end
            end

            self.timer:callPeriodically(0.5, nil, periodic)
        end
    end

    ---@class BloodLordBuff : Buff
    BloodLordBuff = {} --
    do
        local thistype = BloodLordBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Ablr') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.agi      = 0. ---@type number 
        thistype.str      = 0. ---@type number 
        thistype.timer      = nil ---@type TimerQueue

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

                local periodic = function()
                    local ug       = CreateGroup()

                    MakeGroupInRange(self.tpid, ug, GetUnitX(self.source), GetUnitY(self.source), 500 * LBOOST[self.tpid], Condition(FilterEnemy))

                    if BlzGroupGetSize(ug) > 0 then
                        DestroyEffect(AddSpecialEffectTarget("war3mapImported\\DarknessLeechTarget_Portrait.mdx", self.source, "origin"))
                    end

                    local u = FirstOfGroup(ug)
                    while u do
                        GroupRemoveUnit(ug, u)
                        BloodBank[self.tpid] = math.min(BloodBank[self.tpid] + BLOODLEECH.gain(self.tpid) / 3., 200 * GetHeroInt(self.source, true))
                        UnitDamageTarget(self.source, u, BLOODLEECH.dmg(self.tpid) / 3. * BOOST[self.tpid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)

                        u = GetDummy(GetUnitX(u), GetUnitY(u), FourCC('A0A1'), 1, DUMMY_RECYCLE_TIME)
                        BlzSetUnitFacingEx(u, bj_RADTODEG * Atan2(GetUnitY(self.source) - GetUnitY(u), GetUnitX(self.source) - GetUnitX(u)))
                        InstantAttack(u, self.source)
                        u = FirstOfGroup(ug)
                    end

                    DestroyGroup(ug)
                end

                --blood leech aoe
                self.timer = TimerQueue.create()
                self.timer:callPeriodically(1., nil, periodic)
                self.agi = BLOODLORD.bonus(self.pid)
                UnitAddBonus(self.source, BONUS_HERO_AGI, self.agi)
            else
                self.str = BLOODLORD.bonus(self.pid)
                UnitAddBonus(self.source, BONUS_HERO_STR, self.str)
            end

            BlzSetUnitAttackCooldown(self.source, BlzGetUnitAttackCooldown(self.source, 0) * 0.7, 0)
            TimerQueue:callDelayed(BLOODLORD.dur(self.pid) * LBOOST[self.pid], DestroyEffect, AddSpecialEffectTarget("war3mapImported\\Burning Rage Red.mdx", self.source, "overhead"))
            SetUnitAnimationByIndex(self.source, 3)
            SetUnitState(self.source, UNIT_STATE_MANA, 0.)

            BloodBank[self.tpid] = 0
        end
    end

    ---@class ManaDrainDebuff : Buff
    ManaDrainDebuff = {} --
    do
        local thistype = ManaDrainDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Amdr') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.lfx           = nil ---@type lightning 
        thistype.timer           = nil ---@type TimerQueue 

        function thistype:onRemove()
            DestroyLightning(self.lfx)
            self.timer:destroy()
        end

        function thistype:onApply()
            self.lfx = AddLightningEx("DRAM", false, GetUnitX(self.source), GetUnitY(self.source), BlzGetUnitZ(self.source) + 50., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 50.)

            timer = TimerQueue.create()

            local drain = function(x, y)
                local mana      = GetUnitState(self.target, UNIT_STATE_MANA) ---@type number 

                if mana > 0. then
                    mana = math.max(0., mana - 1000.)
                    SetUnitState(self.target, UNIT_STATE_MANA, mana)
                    SetUnitState(self.source, UNIT_STATE_MANA, GetUnitState(self.source, UNIT_STATE_MANA) + math.min(1000., mana))

                    UnitDamageTarget(self.source, self.target, math.min(1000., mana) * 2., true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\ManaBurn\\ManaBurnTarget.mdl", self.target, "chest"))
                end

                if DistanceCoords(x, y, GetUnitX(self.target), GetUnitY(self.target)) > 800. or not UnitAlive(self.source) then
                    self:remove()
                end
            end

            local move = function()
                MoveLightningEx(lfx, false, GetUnitX(self.source), GetUnitY(self.source), BlzGetUnitZ(self.source) + 50., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 50.)
            end

            timer:callPeriodically(1., nil, drain, GetUnitX(self.source), GetUnitY(self.source))
            timer:callPeriodically(FPS_32, nil, move)
        end
    end

    ---@class SpinDashDebuff : Buff
    SpinDashDebuff = {} --
    do
        local thistype = SpinDashDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Asda') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 
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
    ParryBuff = {} --
    do
        local thistype = ParryBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Apar') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 
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

            if limitBreak[self.tpid] & 0x10 then
                BlzSetSpecialEffectColor(self.sfx, 255, 255, 0)
            end
        end
    end

    ---@class IntimidatingShoutBuff : Buff
    IntimidatingShoutBuff = {} --
    do
        local thistype = IntimidatingShoutBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Ainb') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 
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
    IntimidatingShoutDebuff = {} --
    do
        local thistype = IntimidatingShoutDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Aint') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 
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
    UndyingRageBuff = {} --
    do
        local thistype = UndyingRageBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Arag') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 
        thistype.totalRegen      = 0. ---@type number 
        thistype.text         = nil ---@type texttag 
        thistype.bonusRegen      = 0. ---@type number 
        thistype.timer      = nil ---@type TimerQueue

        ---@param dmg number
        function thistype:addRegen(dmg)
            self.totalRegen = math.max(-200., math.min(200., self.totalRegen + dmg / BlzGetUnitMaxHP(self.source) * 100))
        end

        function thistype:onRemove()
            self.timer:destroy()
            BuffRegen[self.tpid] = BuffRegen[self.tpid] - self.bonusRegen
            UnitAddBonus(self.source, BONUS_DAMAGE, -undyingRageAttackBonus[self.tpid])
            undyingRageAttackBonus[self.tpid] = 0

            DestroyEffect(self.sfx)
            DestroyTextTag(self.text)

            if self.totalRegen >= 0 then
                HP(self.source, BlzGetUnitMaxHP(self.source) * 0.01 * self.totalRegen)
            else
                UnitDamageTarget(self.source, self.source, BlzGetUnitMaxHP(self.source) * 0.01 * -self.totalRegen, true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)
            end
        end

        function thistype:onApply()
            self.text = CreateTextTag()
            self.totalRegen = 0.
            SetTextTagText(self.text, (R2I(self.totalRegen)) .. "%", 0.025)
            SetTextTagColor(self.text, R2I(Pow(100 - self.totalRegen, 1.1)), R2I(SquareRoot(math.max(0, self.totalRegen) * 500)), 0, 255)

            self.sfx = AddSpecialEffectTarget("war3mapImported\\DemonicAdornment.mdx", self.source, "head")

            self.timer = TimerQueue.create()

            local periodic = function()
                SetTextTagText(self.text, (R2I(self.totalRegen)) .. "%", 0.025)
                SetTextTagColor(self.text, R2I(Pow(100. - math.min(100., self.totalRegen), 1.1)), R2I(SquareRoot(math.max(0, math.min(100., self.totalRegen)) * 500)), 0, 255)
                SetTextTagPosUnit(self.text, self.source, -200.)

                --percent
                self:addRegen(TotalRegen[self.pid] * 0.01)

                SetWidgetLife(self.source, math.max(10., BlzGetUnitMaxHP(self.source) * 0.0001))
            end

            self.timer:callPeriodically(FPS_32, not UnitAlive(self.source), periodic)
        end
    end

    ---@class RampageBuff : Buff
    RampageBuff = {} --
    do
        local thistype = RampageBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Aram') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 
        thistype.sfx        = nil ---@type effect 
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
                UnitDamageTarget(self.source, self.source, 0.08 * GetWidgetLife(self.source), true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)
            end

            periodic()
            self.timer:callPeriodically(1., nil, periodic)
        end
    end

    ---@class FrostArmorDebuff : Buff
    FrostArmorDebuff = {} --
    do
        local thistype = FrostArmorDebuff
        setmetatable(thistype, { __index = Buff })
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
    FrostArmorBuff = {} --
    do
        local thistype = FrostArmorBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Afar') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 
        thistype.sfx        = nil ---@type effect 

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
    MagneticStrikeDebuff = {} --
    do
        local thistype = MagneticStrikeDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Amsd') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
    end

    ---@class MagneticStrikeBuff : Buff
    MagneticStrikeBuff = {} --
    do
        local thistype = MagneticStrikeBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Amst') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
    end

    ---@class InfernalStrikeBuff : Buff
    InfernalStrikeBuff = {} --
    do
        local thistype = InfernalStrikeBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Aist') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
    end

    ---@class PiercingStrikeDebuff : Buff
    PiercingStrikeDebuff = {} --
    do
        local thistype = PiercingStrikeDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Apie') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 

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
    FightMeBuff = {} --
    do
        local thistype = FightMeBuff
        setmetatable(thistype, { __index = Buff })
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
    RighteousMightBuff = {} --
    do
        local thistype = RighteousMightBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Armi') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.dmg = 0. ---@type number 
        thistype.armor = 0. ---@type number 
        thistype.timer = nil ---@type TimerQueue

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_DAMAGE, -self.dmg)
            UnitAddBonus(self.target, BONUS_ARMOR, -self.armor)

            self.timer:destroy()
            SetUnitScale(self.target, BlzGetUnitRealField(self.target, UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(self.target, UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(self.target, UNIT_RF_SCALING_VALUE))
        end

        function thistype:onApply()
            local dur = 60
            local size = BlzGetUnitRealField(self.target, UNIT_RF_SCALING_VALUE)

            UnitAddBonus(self.target, BONUS_DAMAGE, self.dmg)
            UnitAddBonus(self.target, BONUS_ARMOR, self.armor)

            local grow = function()
                size = size + 0.008
                SetUnitScale(self.source, size, size, size)
                dur = dur - 1
            end

            self.timer = TimerQueue.create()
            self.timer:callPeriodically(FPS_32, dur <= 0, grow)
        end
    end

    ---@class BloodFrenzyBuff : Buff
    BloodFrenzyBuff = {} --
    do
        local thistype = BloodFrenzyBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A07E') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 

        function thistype:onRemove()
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) * 1.50, 0)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Bloodlust\\BloodlustTarget.mdl", self.target, "chest")

            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) / 1.50, 0)
            UnitDamageTarget(self.source, self.source, 0.15 * BlzGetUnitMaxHP(self.source), true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)
        end
    end

    ---@class EarthDebuff : Buff
    EarthDebuff = {} --
    do
        local thistype = EarthDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A04P') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
    end

    ---@class SteedChargeStun : Buff
    SteedChargeStun = {} --
    do
        local thistype = SteedChargeStun
        setmetatable(thistype, { __index = Buff })
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
    SingleShotDebuff = {} --
    do
        local thistype = SingleShotDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A950') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 
        thistype.sfx        = nil ---@type effect 

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
    FreezingBlastDebuff = {} --
    do
        local thistype = FreezingBlastDebuff
        setmetatable(thistype, { __index = Buff })
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
    ProtectedBuff = {} --
    do
        local thistype = ProtectedBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A09I') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
    end

    ---@class AstralShieldBuff : Buff
    AstralShieldBuff = {} --
    do
        local thistype = AstralShieldBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Azas') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("war3mapImported\\DemonShieldTarget3A.mdx", self.target, "origin")
        end
    end

    ---@class ProtectedExistenceBuff : Buff
    ProtectedExistenceBuff = {} --
    do
        local thistype = ProtectedExistenceBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Aexi') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("war3mapImported\\DemonShieldTarget3A.mdx", self.target, "origin")
        end
    end

    ---@class ProtectionBuff : Buff
    ProtectionBuff = {} --
    do
        local thistype = ProtectionBuff
        setmetatable(thistype, { __index = Buff })
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
    SanctifiedGroundDebuff = {} --
    do
        local thistype = SanctifiedGroundDebuff
        setmetatable(thistype, { __index = Buff })
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
    DivineLightBuff = {} --
    do
        local thistype = DivineLightBuff
        setmetatable(thistype, { __index = Buff })
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
    SmokebombBuff = {} --
    do
        local thistype = SmokebombBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Asmk') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
    end

    ---@class SmokebombDebuff : Buff
    SmokebombDebuff = {} --
    do
        local thistype = SmokebombDebuff
        setmetatable(thistype, { __index = Buff })
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
    AzazothHammerStomp = {} --
    do
        local thistype = AzazothHammerStomp
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A00C') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 

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
    BloodCurdlingScreamDebuff = {} --
    do
        local thistype = BloodCurdlingScreamDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Ascr') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.armor         = 0 ---@type integer 
        thistype.sfx        = nil ---@type effect 

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
    NerveGasDebuff = {} --
    do
        local thistype = NerveGasDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Agas') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 
        thistype.armor         = 0 ---@type integer 
        thistype.sfx        = nil ---@type effect 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .3)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) + self.ms)
            UnitAddBonus(self.target, BONUS_ARMOR, self.armor)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = GetUnitMoveSpeed(self.target) * 0.3
            self.armor = R2I(BlzGetUnitArmor(self.target) * 0.2)
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\AcidBomb\\BottleImpact.mdl", self.target, "chest")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.3)
            SetUnitMoveSpeed(self.target, GetUnitMoveSpeed(self.target) - self.ms)
            UnitAddBonus(self.target, BONUS_ARMOR, -self.armor)
        end
    end

    ---@class DemonPrinceBloodlust : Buff
    DemonPrinceBloodlust = {} --
    do
        local thistype = DemonPrinceBloodlust
        setmetatable(thistype, { __index = Buff })
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

    ---@class IceElementSlow : Buff
    IceElementSlow = {} --
    do
        local thistype = IceElementSlow
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Aice') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 
        thistype.sfx        = nil ---@type effect 

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
    TidalWaveDebuff = {} --
    do
        local thistype = TidalWaveDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('Atwa') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.percent      = .15 ---@type number 
    end

    ---@class SoakedDebuff : Buff
    SoakedDebuff = {} --
    do
        local thistype = SoakedDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A01G') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 
        thistype.sfx        = nil ---@type effect 

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
    SongOfFatigueSlow = {} --
    do
        local thistype = SongOfFatigueSlow
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A00X') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 
        thistype.sfx        = nil ---@type effect 

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
    MeatGolemThunderClap = {} --
    do
        local thistype = MeatGolemThunderClap
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A00C') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 
        thistype.sfx        = nil ---@type effect 

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
    SaviorThunderClap = {} --
    do
        local thistype = SaviorThunderClap
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A013') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 
        thistype.sfx        = nil ---@type effect 

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
    BlinkStrikeBuff = {} --
    do
        local thistype = BlinkStrikeBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A03Y') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Windwalk.mdx", self.target, "origin")
        end
    end

    ---@class NagaThorns : Buff
    NagaThorns = {} --
    do
        local thistype = NagaThorns
        setmetatable(thistype, { __index = Buff })

        thistype.RAWCODE         = FourCC('A04S') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onApply()
            TimerQueue:callDelayed(6.5, DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Undead\\ThornyShield\\ThornyShieldTargetChestLeft.mdl", self.target, "chest"))
            TimerQueue:callDelayed(2.5, DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\ThornsAura\\ThornsAura.mdl", self.target, "origin"))
        end
    end

    ---@class NagaEliteAtkSpeed : Buff
    NagaEliteAtkSpeed = {} --
    do
        local thistype = NagaEliteAtkSpeed
        setmetatable(thistype, { __index = Buff })

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
    SpiritCallSlow = {} --
    do
        local thistype = SpiritCallSlow
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A05M') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 
    end

    ---@class LightSealBuff : Buff
    LightSealBuff = {} --
    do
        local thistype = LightSealBuff
        setmetatable(thistype, { __index = Buff })
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

        function thistype:onApply()
            self.timer = TimerQueue.create()

            local LightSealStackExpire = function()
                self.stacks = IMaxBJ(0, self.stacks - 1)

                UnitAddBonus(self.source, BONUS_HERO_STR, -self.strength)
                UnitAddBonus(self.source, BONUS_ARMOR, -self.armor)

                self.strength = R2I(GetHeroStr(self.source, true) * 0.01 * self.stacks)
                self.armor = R2I(BlzGetUnitArmor(self.source) * 0.01 * self.stacks)

                UnitAddBonus(self.source, BONUS_HERO_STR, self.strength)
                UnitAddBonus(self.source, BONUS_ARMOR, self.armor)
            end

            self.timer:callPeriodically(5., self.stacks <= 0, LightSealStackExpire)
        end
    end

    ---@class DarkSealDebuff : Buff
    DarkSealDebuff = {} --
    do
        local thistype = DarkSealDebuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A06W') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            local pt = TimerList[self.pid]:get(DARKSEAL.id, self.source) ---@type PlayerTimer 

            GroupRemoveUnit(pt.ug, self.target)
        end
    end

    ---@class KnockUp : Buff
    KnockUp = {} --
    do
        local thistype = KnockUp
        setmetatable(thistype, { __index = Buff })
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

        function thistype:onRemove()
            --stack with stun?
            if Stun:has(nil, self.target) == false and Freeze:has(nil, self.target) == false then
                BlzPauseUnitEx(self.target, false)
            end
            SetUnitFlyHeight(self.target, 0., 0.)
        end

        function thistype:onApply()
            BlzPauseUnitEx(self.target, true)

            if UnitAddAbility(self.target, FourCC('Amrf')) then
                UnitRemoveAbility(self.target, FourCC('Amrf'))
            end

            local time = 0.
            local knockup = function()
                time = time + FPS_32
                SetUnitFlyHeight(self.target, calcHeight(time), 0.)
            end

            TimerQueue:callPeriodically(FPS_32, time > thistype.DEBUFF_TIME, knockup)
        end
    end

    ---@class Freeze : Buff
    Freeze = {} --
    do
        local thistype = Freeze
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A01D') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 

        function thistype:onRemove()
            --stack with stun?
            if Stun:has(nil, self.target) == false and KnockUp:has(nil, self.target) == false then
                BlzPauseUnitEx(self.target, false)
            end
            if GetUnitTypeId(self.source) == HERO_DARK_SAVIOR or GetUnitTypeId(self.source) == HERO_DARK_SAVIOR_DEMON then
                FreezingBlastDebuff:add(self.source, self.target).duration = FREEZINGBLAST.freeze * LBOOST[self.pid]
            end
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            BlzPauseUnitEx(self.target, true)
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\FreezingBreath\\FreezingBreathTargetArt.mdl", self.target, "chest")
        end
    end

    ---@class Stun : Buff
    Stun = {} --
    do
        local thistype = Stun
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A08J') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.sfx        = nil ---@type effect 

        function thistype:onRemove()
            if Freeze:has(nil, self.target) == false and KnockUp:has(nil, self.target) == false then
                BlzPauseUnitEx(self.target, false)
            end
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            BlzPauseUnitEx(self.target, true)
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\Thunderclap\\ThunderclapTarget.mdl", self.target, "overhead")
        end
    end

    ---@class DarkestOfDarkness : Buff
    DarkestOfDarkness = {} --
    do
        local thistype = DarkestOfDarkness
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A056') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onApply()
            TimerQueue:callDelayed(6., DestroyEffect, AddSpecialEffectTarget("war3mapImported\\SoulArmor.mdx", self.target, "chest"))
        end
    end

    ---@class HolyBlessing : Buff
    HolyBlessing = {} --
    do
        local thistype = HolyBlessing
        setmetatable(thistype, { __index = Buff })
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
    VampiricPotion = {} --
    do
        local thistype = VampiricPotion
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = FourCC('A05O') ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_NONE ---@type integer 

        function thistype:onApply()
            TimerQueue:callDelayed(9., DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Items\\VampiricPotion\\VampPotionCaster.mdl", self.target, "origin"))
        end
    end

    ---@class WeatherBuff : Buff
    WeatherBuff = {} --
    do
        local thistype = WeatherBuff
        setmetatable(thistype, { __index = Buff })
        thistype.RAWCODE         = 0 ---@type integer 
        thistype.DISPEL_TYPE         = BUFF_NONE ---@type integer 
        thistype.STACK_TYPE         =  BUFF_STACK_PARTIAL ---@type integer 
        thistype.ms      = 0. ---@type number 
        thistype.as      = 0. ---@type number 
        thistype.atk      = 0. ---@type number 
        thistype.weather         = 0 ---@type integer 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_DAMAGE, -self.atk)
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) * self.as, 0)

            --TODO entering dungeon check
            if GetLocalPlayer() == GetOwningPlayer(self.target) and not IsPlayerInForce(GetOwningPlayer(self.target), NAGA_GROUP) then
                DisplayCineFilter(false)
            end

            UnitRemoveAbility(self.target, WeatherTable[weather][WEATHER_BUFF])
        end

        function thistype:onApply()
            self.as = 1. - WeatherTable[CURRENT_WEATHER][WEATHER_AS_SLOW] * 0.01
            self.atk = (BlzGetUnitBaseDamage(self.target, 0) + UnitGetBonus(self.target, BONUS_DAMAGE)) * WeatherTable[CURRENT_WEATHER][WEATHER_ATK] * 0.01
            self.weather = CURRENT_WEATHER

            if GetLocalPlayer() == GetOwningPlayer(self.target) and WeatherTable[self.weather][WEATHER_FOG] > 0 then
                SetCineFilterTexture("ReplaceableTextures\\CameraMasks\\HazeAndFogFilter_Mask.blp")
                SetCineFilterStartColor(171, 174, WeatherTable[self.weather][WEATHER_BLUE], 0)
                SetCineFilterEndColor(171, 174, WeatherTable[self.weather][WEATHER_BLUE], WeatherTable[self.weather][WEATHER_FOG])
                SetCineFilterBlendMode(BLEND_MODE_BLEND)
                SetCineFilterDuration(7.)
                DisplayCineFilter(true)
            end

            UnitAddAbility(self.target, WeatherTable[self.weather][WEATHER_BUFF])

            UnitAddBonus(self.target, BONUS_DAMAGE, self.atk)
            BlzSetUnitAttackCooldown(self.target, BlzGetUnitAttackCooldown(self.target, 0) / self.as, 0)
        end
    end
end)

if Debug then Debug.endFile() end
