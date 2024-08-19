--[[
    buffs.lua

    A module that contains most of the triggered buffs and debuffs in the game.
]]

OnInit.global("Buffs", function(Require)
    Require('BuffSystem')
    Require('UnitTable')

    PHASED_MOVEMENT = FourCC('I0OE')

    local mt = { __index = Buff }

    ---@class Disarm : Buff
    Disarm = setmetatable({}, mt)
    do
        local thistype = Disarm
        thistype.RAWCODE         = FourCC('Adar') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            UnitRemoveAbility(self.target, FourCC('ARal'))
            ToggleCommandCard(self.target, true)
            BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(self.target, FourCC("AInv")), ConvertAbilityIntegerLevelField(FourCC('inv5')), 0, 1)

            Unit[self.target].attack = true
        end

        function thistype:onApply()
            local angle = Atan2(GetUnitY(self.target) - GetUnitY(self.source), GetUnitX(self.target) - GetUnitX(self.source)) ---@type number 
            self.x = GetUnitX(self.target) + 2000. * Cos(angle)
            self.y = GetUnitY(self.target) + 2000. * Sin(angle)

            IssuePointOrder(self.target, "move", self.x, self.y)
            ToggleCommandCard(self.target, false)
            UnitAddAbility(self.target, FourCC('ARal'))
            BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(self.target, FourCC("AInv")), ConvertAbilityIntegerLevelField(FourCC('inv5')), 0, 0)
        end
    end

    ---@class Lava : Buff
    Lava = setmetatable({}, mt)
    do
        local thistype = Lava
        thistype.RAWCODE         = FourCC('Lava')
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        local function periodic(self)
            if not IsUnitInRegion(LAVA_REGION, self.target) then
                self:remove()
            else
                local dmg = BlzGetUnitMaxHP(self.target) / 40. + 1000.

                if BlzGetUnitZ(self.target) < 60. then
                    DamageTarget(DUMMY_UNIT, self.target, dmg, ATTACK_TYPE_NORMAL, PURE, "Lava")
                end

                self.timer:callDelayed(1.5, periodic, self)
            end
        end

        function thistype:onRemove()
            self.timer:destroy()
        end

        function thistype:onApply()
            self.timer = TimerQueue.create()
            self.timer:callDelayed(0.5, periodic, self)
        end
    end

    ---@class IgniteDebuff : Buff
    IgniteDebuff = setmetatable({}, mt)
    do
        local thistype = IgniteDebuff
        thistype.RAWCODE         = FourCC('Aign') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 
    end

    ---@class InfusedWaterBuff : Buff
    InfusedWaterBuff = setmetatable({}, mt)
    do
        local thistype = InfusedWaterBuff
        thistype.RAWCODE         = FourCC('Aiwa') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat - 150
        end

        function thistype:onApply()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat + 150
        end
    end

    ---@class EmpyreanSongBuff : Buff
    EmpyreanSongBuff = setmetatable({}, mt)
    do
        local thistype = EmpyreanSongBuff
        thistype.RAWCODE         = FourCC('Aeso') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat - 150
        end

        function thistype:onApply()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat + 150
        end
    end

    ---@class BloodHornBuff : Buff
    BloodHornBuff = setmetatable({}, mt)
    do
        local thistype = BloodHornBuff
        thistype.RAWCODE         = FourCC('A03G') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat - 75
        end

        function thistype:onApply()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat + 75
        end
    end

    ---@class ArcaneBarrageBuff : Buff
    ArcaneBarrageBuff = setmetatable({}, mt)
    do
        local thistype = ArcaneBarrageBuff
        thistype.RAWCODE         = FourCC('Aacb') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat - 150
        end

        function thistype:onApply()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat + 150
        end
    end

    ---@class OmnislashBuff : Buff
    OmnislashBuff = setmetatable({}, mt)
    do
        local thistype = OmnislashBuff
        thistype.RAWCODE         = FourCC('Aomn') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.ablev         = 0 ---@type integer 

        function thistype:strongest(new)
            if self.ablev < new then
                Unit[self.target].spellboost = Unit[self.target].spellboost - self.spellboost

                self.ablev = new
                self.spellboost = math.max(0.91 - 0.01 * self.ablev, 0.85)
                Unit[self.target].spellboost = Unit[self.target].spellboost + self.spellboost
            end
        end

        --mana cost per second
        local function periodic(self)
            local mana = GetUnitState(self.target, UNIT_STATE_MANA)
            local cost = BlzGetUnitMaxMana(self.target) * 0.02
            SetUnitState(self.target, UNIT_STATE_MANA, math.max(mana - cost, 0))
            if mana - cost > 0 then
                self.timer:callDelayed(1, periodic, self)
            else
                self:remove()
            end
        end

        function thistype:onRemove()
            Unit[self.target].spellboost = Unit[self.target].spellboost - self.spellboost

            if self.source == self.target then
                --unimmolation
                self.timer:destroy()
                IssueImmediateOrderById(self.source, ORDER_ID_UNIMMOLATION)
            end
        end

        function thistype:onApply()
            self.ablev = GetUnitAbilityLevel(self.source, INSPIRE.id)
            self.spellboost = (0.08 + 0.02 * self.ablev)
            Unit[self.target].spellboost = Unit[self.target].spellboost + self.spellboost

            if self.source == self.target then
                self.timer = TimerQueue.create()
                self.timer:callDelayed(1, periodic, self)
            end
        end
    end

    ---@class SongOfWarBuff : Buff
    SongOfWarBuff = setmetatable({}, mt)
    do
        local thistype = SongOfWarBuff
        thistype.RAWCODE         = FourCC('Aswb') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 
        thistype.attack      = 0. ---@type number 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_DAMAGE, -self.attack)
        end

        function thistype:onApply()
            self.attack = math.floor((BlzGetUnitBaseDamage(self.target, 0) + UnitGetBonus(self.target, BONUS_DAMAGE)) * 0.2)
            UnitAddBonus(self.target, BONUS_DAMAGE, self.attack)
        end
    end

    ---@class SongOfHarmonyBuff : Buff
    SongOfHarmonyBuff = setmetatable({}, mt)
    do
        local thistype = SongOfHarmonyBuff
        thistype.RAWCODE         = FourCC('Ashh') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].regen_max = Unit[self.target].regen_max - 1
        end

        function thistype:onApply()
            Unit[self.target].regen_max = Unit[self.target].regen_max + 1
        end
    end

    ---@class SongOfPeaceBuff : Buff
    SongOfPeaceBuff = setmetatable({}, mt)
    do
        local thistype = SongOfPeaceBuff
        thistype.RAWCODE         = FourCC('Aspm') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].mana_regen_max = Unit[self.target].mana_regen_max - 1
        end

        function thistype:onApply()
            Unit[self.target].mana_regen_max = Unit[self.target].mana_regen_max + 1
        end
    end

    ---@class SongOfPeaceEncoreBuff : Buff
    SongOfPeaceEncoreBuff = setmetatable({}, mt)
    do
        local thistype = SongOfPeaceEncoreBuff
        thistype.RAWCODE         = FourCC('Aspc') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 
        thistype.count         = 10 ---@type integer 
        thistype.dmg      = 0. ---@type number 

        local function onHit(source, target)
            local self = SongOfWarEncoreBuff:get(nil, source)

            if self then
                self.count = self.count - 1
                DamageTarget(self.source, target, self.dmg * BOOST[GetPlayerId(GetOwningPlayer(self.source)) + 1], ATTACK_TYPE_NORMAL, MAGIC, ENCORE.tag)

                if self.count <= 0 then
                    self:remove()
                end
            end
        end

        function thistype:onRemove()
            EVENT_ON_HIT:unregister_unit_action(self.target, onHit)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            EVENT_ON_HIT:register_unit_action(self.target, onHit)
            self.dmg = (.25 + .25 * GetUnitAbilityLevel(self.source, ENCORE.id)) * GetHeroStat(MainStat(self.target), self.target, true)

            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Items\\VampiricPotion\\VampPotionCaster.mdl", self.target, "origin")
        end
    end

    ---@class MagneticStanceBuff : Buff
    MagneticStanceBuff = setmetatable({}, mt)
    do
        local thistype = MagneticStanceBuff
        thistype.RAWCODE         = FourCC('Amag') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
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
                if GetUnitMoveSpeed(u) > 0 and (GetUnitCurrentOrder(u) == 0 or GetUnitCurrentOrder(u) == ORDER_ID_SMART) and IsTerrainWalkable(GetUnitX(u) + (3. * Cos(angle)), GetUnitY(u) + (3. * Sin(angle))) and UnitDistance(u, target) > 100. then
                    SetUnitXBounded(u, GetUnitX(u) + (3. * Cos(angle)))
                    SetUnitYBounded(u, GetUnitY(u) + (3. * Sin(angle)))
                end
            end

            DestroyGroup(ug)
        end

        function thistype:onRemove()
            SetUnitVertexColor(self.target, 255, 255, 255, 255)

            self.timer:destroy()
            Unit[self.target].dm = Unit[self.target].dm / self.dm
            Unit[self.target].dr = Unit[self.target].dr / self.dr
        end

        function thistype:onApply()
            self.timer = TimerQueue.create()

            SetUnitVertexColor(self.target, 255, 25, 25, 255)
            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Call of Dread Red.mdx", self.target, "chest"))

            self.timer:callPeriodically(3., nil, Taunt, self.target, self.tpid, 800., false, 500, 500)
            self.timer:callPeriodically(0.1, nil, pull, self.tpid, self.target)

            local ablev = GetUnitAbilityLevel(self.source, MAGNETICSTANCE.id)
            self.dr = (0.95 - 0.05 * ablev)
            self.dm = (0.45 + 0.05 * ablev)

            Unit[self.target].dm = Unit[self.target].dm * self.dm
            Unit[self.target].dr = Unit[self.target].dr * self.dr
        end
    end

    ---@class FlamingBowBuff : Buff
    FlamingBowBuff = setmetatable({}, mt)
    do
        local thistype = FlamingBowBuff
        thistype.RAWCODE         = FourCC('Afbo') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        local function onHit(source, target)
            local self = FlamingBowBuff:get(nil, source)
            local ablev = GetUnitAbilityLevel(self.target, FLAMINGBOW.id) ---@type integer 

            UnitAddBonus(self.target, BONUS_DAMAGE, -self.attack)

            if MULTISHOT.enabled[self.tpid] then
                self.count = math.min(self.count + 1. / (1 + GetUnitAbilityLevel(self.target, MULTISHOT.id)), 30. + 2. * ablev)
            else
                self.count = math.min(self.count + 1., 30. + 2. * ablev)
            end
            self.attack = math.floor((0.5 + 0.01 * self.count) * (GetHeroAgi(self.target, true) + UnitGetBonus(self.target, BONUS_DAMAGE)) * LBOOST[self.tpid])

            UnitAddBonus(self.target, BONUS_DAMAGE, self.attack)
        end

        function thistype:onRemove()
            Unit[self.target].armor_pen_percent = Unit[self.target].armor_pen_percent - self.pen
            EVENT_ON_HIT:unregister_unit_action(self.target, onHit)
            DestroyEffect(self.sfx)
            UnitRemoveAbility(self.target, FourCC('A08B'))
            UnitAddBonus(self.target, BONUS_DAMAGE, -self.attack)
        end

        function thistype:onApply()
            self.pen = FLAMINGBOW.pierce(self.tpid)
            Unit[self.target].armor_pen_percent = Unit[self.target].armor_pen_percent + self.pen
            EVENT_ON_HIT:register_unit_action(self.target, onHit)
            self.attack = math.floor(FLAMINGBOW.bonus(self.tpid))
            self.count = 0

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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
        end

        function thistype:onApply()
            self.ms = 0.75 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
        end
    end

    ---@class ArcanosphereBuff : Buff
    ArcanosphereBuff = setmetatable({}, mt)
    do
        local thistype = ArcanosphereBuff
        thistype.RAWCODE         = FourCC('Aaca') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].overmovespeed = nil
        end

        function thistype:onApply()
            Unit[self.target].overmovespeed = 1000
        end
    end

    ---@class MarkedForDeathDebuff : Buff
    MarkedForDeathDebuff = setmetatable({}, mt)
    do
        local thistype = MarkedForDeathDebuff
        thistype.RAWCODE         = FourCC('Amar') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            SetUnitPathing(self.target, true)

            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms

            BlzSetSpecialEffectScale(self.sfx, 0)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            SetUnitPathing(self.target, false)

            self.ms = 0.5 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms

            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\Banish\\BanishTarget.mdl", self.target, "chest")
        end
    end

    ---@class FightMeCasterBuff : Buff
    FightMeCasterBuff = setmetatable({}, mt)
    do
        local thistype = FightMeCasterBuff
        thistype.RAWCODE         = FourCC('Afmc') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
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

    ---@class ProvokeDebuff : Buff
    ProvokeDebuff = setmetatable({}, mt)
    do
        local thistype = ProvokeDebuff
        thistype.RAWCODE         = FourCC('Apvk') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].dm = Unit[self.target].dm / self.dm
        end

        function thistype:onApply()
            self.dm = (1. - 0.25)
            Unit[self.target].dm = Unit[self.target].dm * self.dm
        end
    end

    ---@class DemonicSacrificeBuff : Buff
    DemonicSacrificeBuff = setmetatable({}, mt)
    do
        local thistype = DemonicSacrificeBuff
        thistype.RAWCODE         = FourCC('Adsa') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].spellboost = Unit[self.target].spellboost - 0.15
        end

        function thistype:onApply()
            Unit[self.target].spellboost = Unit[self.target].spellboost + 0.15
        end
    end

    ---@class JusticeAuraBuff : Buff
    JusticeAuraBuff = setmetatable({}, mt)
    do
        local thistype = JusticeAuraBuff
        thistype.RAWCODE         = FourCC('Ajap') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.hp      = 0. ---@type number 
        thistype.mana      = 0. ---@type number 
        thistype.lfx           = nil ---@type lightning 
        thistype.timer = nil ---@type TimerQueue

        function thistype:onRemove()
            EVENT_ON_FATAL_DAMAGE:unregister_unit_action(self.target, SOULLINK.onHit)
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

            EVENT_ON_FATAL_DAMAGE:register_unit_action(self.target, SOULLINK.onHit)
            self.hp = GetWidgetLife(self.target)
            self.mana = GetUnitState(self.target, UNIT_STATE_MANA)

            BlzSetItemSkin(PATH_ITEM, BlzGetUnitSkin(self.target))
            self.sfx = AddSpecialEffect(BlzGetItemStringField(PATH_ITEM, ITEM_SF_MODEL_USED), x, y)
            self.lfx = AddLightningEx("HCHA", false, x, y, BlzGetUnitZ(self.target) + 75., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 75.)
            BlzSetItemSkin(PATH_ITEM, BlzGetUnitSkin(DUMMY_UNIT))

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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.regen      = 0. ---@type number 
        thistype.percent         = 0 ---@type integer 

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            Unit[self.target].regen_flat = Unit[self.target].regen_flat - self.regen
            Unit[self.target].regen_percent = Unit[self.target].regen_percent - self.percent * 0.01
        end

        function thistype:onApply()
            self.regen = LAWOFVALOR.regen(self.pid) * BOOST[self.pid]
            self.percent = R2I(LAWOFVALOR.amp(self.pid))

            Unit[self.target].regen_flat = Unit[self.target].regen_flat + self.regen
            Unit[self.target].regen_percent = Unit[self.target].regen_percent + self.percent * 0.01

            self.sfx = AddSpecialEffectTarget("war3mapImported\\RunicShield.mdx", self.target, "chest")
        end
    end

    ---@class LawOfResonanceBuff : Buff
    LawOfResonanceBuff = setmetatable({}, mt)
    do
        local thistype = LawOfResonanceBuff
        thistype.RAWCODE         = FourCC('Alre') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.multiplier      = 0. ---@type number 

        local function onHit(source, target, amount, amount_after_red, damage_type)
            local self = thistype:get(nil, source)

            if damage_type == PHYSICAL then
                DamageTarget(source, target, amount_after_red * self.multiplier, ATTACK_TYPE_NORMAL, PURE, LAWOFRESONANCE.tag)
            end
        end

        function thistype:onRemove()
            EVENT_ON_HIT_AFTER_REDUCTIONS:unregister_unit_action(self.target, onHit)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            EVENT_ON_HIT_AFTER_REDUCTIONS:register_unit_action(self.target, onHit)
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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        local function periodic(self)
            local mana = GetUnitState(self.target, UNIT_STATE_MANA) ---@type number 
            local maxmana = BlzGetUnitMaxMana(self.target) * 0.02 ---@type number 

            if UnitAlive(self.target) and mana >= maxmana then
                SetUnitState(self.target, UNIT_STATE_MANA, mana - maxmana)
            else
                self:remove()
            end
        end

        function thistype:onRemove()
            Unit[self.target].mm = Unit[self.target].mm / self.mm
            IssueImmediateOrder(self.target, "unimmolation")

            DestroyEffect(self.sfx)
            self.timer:destroy()
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Windwalk Blue Soul.mdx", self.target, "origin")

            self.timer = TimerQueue.create()
            self.timer:callPeriodically(1., nil, periodic, self)

            self.mm = OVERLOAD.mult(self.pid)
            Unit[self.target].mm = Unit[self.target].mm * self.mm
        end
    end

    ---@class BloodMistBuff : Buff
    BloodMistBuff = setmetatable({}, mt)
    do
        local thistype = BloodMistBuff
        thistype.RAWCODE         = FourCC('Abmi') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        local function periodic(self)
            local blood = BLOODBANK.get(self.tpid)

            if blood >= BLOODMIST.cost(self.tpid) then
                BLOODBANK.add(self.tpid, -BLOODMIST.cost(self.tpid))
                HP(self.target, self.target, BLOODMIST.heal(self.tpid) * BOOST[self.tpid], BLOODMIST.tag)
                if self.ms == 0 then
                    self.ms = 50 + 50 * GetUnitAbilityLevel(self.source, BLOODMIST.id)
                    Unit[self.target].ms_flat = Unit[self.target].ms_flat + self.ms
                    PlayerAddItemById(self.tpid, PHASED_MOVEMENT)
                    BlzSetSpecialEffectColor(self.sfx, 255, 255, 255)
                end
            else
                Unit[self.target].ms_flat = Unit[self.target].ms_flat - self.ms
                self.ms = 0
                UnitRemoveAbility(self.target, FourCC('B02Q'))
                BlzSetSpecialEffectColor(self.sfx, 0, 0, 0)
            end

            self.timer:callDelayed(1., periodic, self)
        end

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            Unit[self.target].ms_flat = Unit[self.target].ms_flat - self.ms
            UnitRemoveAbility(self.target, FourCC('B02Q'))

            self.timer:destroy()
        end

        function thistype:onApply()
            local ablev = GetUnitAbilityLevel(self.target, BLOODMIST.id)
            self.ms = 0

            if BLOODBANK.get(self.tpid) >= BLOODMIST.cost(self.tpid, ablev) then
                self.ms = 50 + 50 * GetUnitAbilityLevel(self.target, BLOODMIST.id)
                Unit[self.target].ms_flat = Unit[self.target].ms_flat + self.ms
            end

            self.sfx = AddSpecialEffectTarget("war3mapImported\\Chumpool.mdx", self.target, "origin")

            self.timer = TimerQueue.create()
            self.timer:callDelayed(0.5, periodic, self)
        end
    end

    ---@class BloodLordBuff : Buff
    BloodLordBuff = setmetatable({}, mt)
    do
        local thistype = BloodLordBuff
        thistype.RAWCODE         = FourCC('Ablr') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.agi      = 0. ---@type number 
        thistype.str      = 0. ---@type number 

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            DamageTarget(source, target, BLOODLORD.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, BLOODLORD.tag)
            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", target, "chest"))
        end

        local function periodic(self)
            local ug = CreateGroup()

            MakeGroupInRange(self.tpid, ug, GetUnitX(self.source), GetUnitY(self.source), 500. * LBOOST[self.tpid], Condition(FilterEnemy))

            if BlzGroupGetSize(ug) > 0 then
                DestroyEffect(AddSpecialEffectTarget("war3mapImported\\DarknessLeechTarget_Portrait.mdx", self.source, "origin"))
            end

            for target in each(ug) do
                BLOODBANK.add(self.tpid, BLOODLEECH.gain(self.tpid) / 3.)
                DamageTarget(self.source, target, BLOODLEECH.dmg(self.tpid) / 3. * BOOST[self.tpid], ATTACK_TYPE_NORMAL, MAGIC, BLOODLORD.tag)

                local dummy = Dummy.create(GetUnitX(target), GetUnitY(target), FourCC('A0A1'), 1)
                dummy:attack(self.source)
            end

            DestroyGroup(ug)

            self.timer:callDelayed(1, periodic, self)
        end

        function thistype:onRemove()
            EVENT_ON_HIT:unregister_unit_action(self.source, onHit)

            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat / 0.7
            Unit[self.source].bonus_agi = Unit[self.source].bonus_agi - self.agi
            Unit[self.source].bonus_str = Unit[self.source].bonus_str - self.str

            self.agi = 0.
            self.str = 0.

            if self.timer ~= nil then
                UnitDisableAbility(self.source, BLOODLEECH.id, false)
                UnitDisableAbility(self.source, BLOODDOMAIN.id, false)
                self.timer:destroy()
            end
        end

        function thistype:onApply()
            EVENT_ON_HIT:register_unit_action(self.source, onHit)

            if GetHeroAgi(self.source, true) > GetHeroStr(self.source, true) then
                UnitDisableAbility(self.source, BLOODLEECH.id, true)
                BlzUnitHideAbility(self.source, BLOODLEECH.id, false)
                UnitDisableAbility(self.source, BLOODDOMAIN.id, true)
                BlzUnitHideAbility(self.source, BLOODDOMAIN.id, false)

                --blood leech aoe
                self.timer = TimerQueue.create()
                self.timer:callDelayed(1., periodic, self)
                self.agi = BLOODLORD.bonus(self.pid)
                Unit[self.source].bonus_str = Unit[self.source].bonus_str + self.str
            else
                self.str = BLOODLORD.bonus(self.pid)
                Unit[self.source].bonus_str = Unit[self.source].bonus_str + self.str
            end

            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat * 0.7
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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        local function periodic(self)
            MoveLightningEx(self.lfx, false, GetUnitX(self.source), GetUnitY(self.source), BlzGetUnitZ(self.source) + 50., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 50.)
            self.timer:callDelayed(FPS_32, periodic, self)
        end

        local function drain(self, x, y)
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
                self.timer:callDelayed(1., drain, self, x, y)
            end
        end

        function thistype:onRemove()
            DestroyLightning(self.lfx)
            self.timer:destroy()
        end

        function thistype:onApply()
            self.lfx = AddLightningEx("DRAM", false, GetUnitX(self.source), GetUnitY(self.source), BlzGetUnitZ(self.source) + 50., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 50.)
            self.timer = TimerQueue.create()

            MoveLightningEx(self.lfx, false, GetUnitX(self.source), GetUnitY(self.source), BlzGetUnitZ(self.source) + 50., GetUnitX(self.target), GetUnitY(self.target), BlzGetUnitZ(self.target) + 50.)

            self.timer:callDelayed(1., drain, self, GetUnitX(self.source), GetUnitY(self.source))
            self.timer:callDelayed(FPS_32, periodic, self)
        end
    end

    ---@class SpinDashDebuff : Buff
    SpinDashDebuff = setmetatable({}, mt)
    do
        local thistype = SpinDashDebuff
        thistype.RAWCODE         = FourCC('Asda') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.as              = 1.25 ---@type number 

        function thistype:onRemove()
            DestroyEffect(self.sfx)
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat / self.as
        end

        function thistype:onApply()
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat * self.as

            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\StasisTrap\\StasisTotemTarget.mdl", self.target, "overhead")
        end
    end

    ---@class ParryBuff : Buff
    ParryBuff = setmetatable({}, mt)
    do
        local thistype = ParryBuff
        thistype.RAWCODE         = FourCC('Apar') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.soundPlayed         = false ---@type boolean 

        local function onHit(target, source, amount_ref)
            local self = ParryBuff:get(target, target)

            if self then
                local pid = GetPlayerId(GetOwningPlayer(target)) + 1
                amount_ref.value = 0.00
                self:playSound()

                DamageTarget(target, source, PARRY.dmg(pid) * (((LIMITBREAK.flag[pid] & 0x1) > 0 and 2.) or 1.), ATTACK_TYPE_NORMAL, MAGIC, PARRY.tag)
            end
        end

        function thistype:playSound()
            if not self.soundPlayed then
                self.soundPlayed = true

                SoundHandler("war3mapImported\\parry" .. GetRandomInt(1, 2) .. ".mp3", true, GetOwningPlayer(self.target), self.target)
            end
        end

        function thistype:onRemove()
            EVENT_ON_STRUCK_MULTIPLIER:unregister_unit_action(self.target, onHit)
            AddUnitAnimationProperties(self.target, "ready", false)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            EVENT_ON_STRUCK_MULTIPLIER:register_unit_action(self.target, onHit)
            AddUnitAnimationProperties(self.target, "ready", true)

            self.sfx = AddSpecialEffectTarget("war3mapImported\\Buff_Shield_Non.mdx", self.target, "chest")

            if LIMITBREAK.flag[self.tpid] & 0x1 > 0 then
                BlzSetSpecialEffectColor(self.sfx, 255, 255, 0)
            end
        end
    end

    ---@class IntimidatingShoutBuff : Buff
    IntimidatingShoutBuff = setmetatable({}, mt)
    do
        local thistype = IntimidatingShoutBuff
        thistype.RAWCODE         = FourCC('Ainb') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.dmg      = 0. ---@type number 

        function thistype:onRemove()
            Unit[self.target].mr = Unit[self.target].mr / self.mr
            DestroyEffect(self.sfx)

            UnitAddBonus(self.target, BONUS_DAMAGE, self.dmg)
        end

        function thistype:onApply()
            self.mr = (LIMITBREAK.flag[self.pid] & 0x4 > 0 and 1.4) or 1

            Unit[self.target].mr = Unit[self.target].mr * self.mr
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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.totalRegen      = 0. ---@type number 
        thistype.text         = nil ---@type texttag 
        thistype.timer      = nil ---@type TimerQueue

        ---@param dmg number
        function thistype:addRegen(dmg)
            self.totalRegen = MathClamp(self.totalRegen + dmg / BlzGetUnitMaxHP(self.target) * 100., -100., 100)
        end

        function thistype:onRemove()
            EVENT_ON_STRUCK_FINAL:unregister_unit_action(self.target, UNDYINGRAGE.onHit)
            self.timer:destroy()

            DestroyEffect(self.sfx)
            DestroyTextTag(self.text)

            if self.totalRegen >= 0 then
                HP(self.target, self.target, BlzGetUnitMaxHP(self.target) * 0.01 * self.totalRegen, UNDYINGRAGE.tag)
            else
                DamageTarget(self.target, self.target, BlzGetUnitMaxHP(self.target) * 0.01 * -self.totalRegen, ATTACK_TYPE_NORMAL, PURE, UNDYINGRAGE.tag)
            end

            Unit[self.target].hidehp = false
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
            EVENT_ON_STRUCK_FINAL:register_unit_action(self.target, UNDYINGRAGE.onHit)
            self.text = CreateTextTag()
            self.totalRegen = 0.
            SetTextTagText(self.text, (R2I(self.totalRegen)) .. "\x25", 0.025)
            SetTextTagColor(self.text, R2I(Pow(100 - self.totalRegen, 1.1)), R2I(SquareRoot(math.max(0, self.totalRegen) * 500)), 0, 255)

            Unit[self.target].hidehp = true

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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 
        thistype.timer        = nil ---@type TimerQueue

        function thistype:onRemove()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat - 100
            Unit[self.target].armor_pen_percent = Unit[self.target].armor_pen_percent - self.pen

            self.timer:destroy()
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.pen = RAMPAGE.pen(self.tpid)
            Unit[self.target].armor_pen_percent = Unit[self.target].armor_pen_percent + self.pen
            Unit[self.target].ms_flat = Unit[self.target].ms_flat + 100

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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat / 1.25
        end

        function thistype:onApply()
            self.ms = 0.25 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat * 1.25
        end
    end

    ---@class FrostArmorBuff : Buff
    FrostArmorBuff = setmetatable({}, mt)
    do
        local thistype = FrostArmorBuff
        thistype.RAWCODE         = FourCC('Afar') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        local function onHit(target, source)
            FrostArmorDebuff:add(target, source):duration(3.)
        end

        function thistype:onRemove()
            EVENT_ON_HIT:unregister_unit_action(self.target, onHit)
            UnitAddBonus(self.source, BONUS_ARMOR, -100.)

            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            EVENT_ON_HIT:register_unit_action(self.target, onHit)
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\FrostArmor\\FrostArmorTarget.mdl", self.source, "chest")

            UnitAddBonus(self.source, BONUS_ARMOR, 100.)
        end
    end

    ---@class MagneticStrikeDebuff : Buff
    MagneticStrikeDebuff = setmetatable({}, mt)
    do
        local thistype = MagneticStrikeDebuff
        thistype.RAWCODE         = FourCC('Amsd') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].dr = Unit[self.target].dr / 1.15
        end

        function thistype:onApply()
            Unit[self.target].dr = Unit[self.target].dr * 1.15
        end
    end

    ---@class MagneticStrikeBuff : Buff
    MagneticStrikeBuff = setmetatable({}, mt)
    do
        local thistype = MagneticStrikeBuff
        thistype.RAWCODE         = FourCC('Amst') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            BODYOFFIRE.charges[pid] = BODYOFFIRE.charges[pid] - 1

            if GetLocalPlayer() == Player(pid - 1) then
                BlzSetAbilityIcon(BODYOFFIRE.id, "ReplaceableTextures\\CommandButtons\\BTNBodyOfFire" .. (BODYOFFIRE.charges[pid]) .. ".blp")
            end

            --disable casting at 0 charges
            if BODYOFFIRE.charges[pid] <= 0 then
                UnitDisableAbility(source, MAGNETICSTRIKE.id, true)
                BlzUnitHideAbility(source, MAGNETICSTRIKE.id, false)
            end

            --refresh charge timer
            local pt = TimerList[pid]:get(BODYOFFIRE.id, source, nil)
            if not pt then
                pt = TimerList[pid]:add()
                pt.source = source
                pt.tag = BODYOFFIRE.id

                BlzStartUnitAbilityCooldown(source, BODYOFFIRE.id, 5.)
                pt.timer:callDelayed(5., BODYOFFIRE.cooldown, pt)
            end
            MagneticStrikeBuff:dispel(source, source)

            local ug = CreateGroup()
            MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), MAGNETICSTRIKE.aoe(pid) * LBOOST[pid], Condition(FilterEnemy))

            for u in each(ug) do
                MagneticStrikeDebuff:add(source, u):duration(MAGNETICSTRIKE.dur(pid) * LBOOST[pid])
            end

            DestroyGroup(ug)

            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", GetUnitX(target), GetUnitY(target)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))
        end

        function thistype:onRemove()
            EVENT_ON_HIT_MULTIPLIER:unregister_unit_action(self.target, onHit)
        end

        function thistype:onApply()
            EVENT_ON_HIT_MULTIPLIER:register_unit_action(self.target, onHit)
        end
    end

    ---@class InfernalStrikeBuff : Buff
    InfernalStrikeBuff = setmetatable({}, mt)
    do
        local thistype = InfernalStrikeBuff
        thistype.RAWCODE         = FourCC('Aist') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        local function onHit(source, target, amount_ref)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            BODYOFFIRE.charges[pid] = BODYOFFIRE.charges[pid] - 1

            if GetLocalPlayer() == Player(pid - 1) then
                BlzSetAbilityIcon(BODYOFFIRE.id, "ReplaceableTextures\\CommandButtons\\BTNBodyOfFire" .. (BODYOFFIRE.charges[pid]) .. ".blp")
            end

            --disable casting at 0 charges
            if BODYOFFIRE.charges[pid] <= 0 then
                UnitDisableAbility(source, INFERNALSTRIKE.id, true)
                BlzUnitHideAbility(source, INFERNALSTRIKE.id, false)
            end

            --refresh charge timer
            local pt = TimerList[pid]:get(BODYOFFIRE.id, source, nil)
            if not pt then
                pt = TimerList[pid]:add()
                pt.source = source
                pt.tag = BODYOFFIRE.id

                BlzStartUnitAbilityCooldown(source, BODYOFFIRE.id, 5.)
                pt.timer:callDelayed(5., BODYOFFIRE.cooldown, pt)
            end

            InfernalStrikeBuff:dispel(source, source)
            amount_ref.value = 0.00

            local ablev = GetUnitAbilityLevel(source, INFERNALSTRIKE.id)

            local ug = CreateGroup()
            MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 250. * LBOOST[pid], Condition(FilterEnemy))
            local count = BlzGroupGetSize(ug)

            for u in each(ug) do
                if IsUnitType(u, UNIT_TYPE_HERO) then
                    count = count + 4
                end
                local dtype = BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE)

                if dtype == 1 or dtype == 7 then --boss
                    DamageTarget(source, u, ((GetHeroStr(source, true) * ablev) + GetWidgetLife(u) * (0.25 + 0.05 * ablev)) * 0.5 * LBOOST[pid], ATTACK_TYPE_NORMAL, PHYSICAL, INFERNALSTRIKE.tag)
                else
                    DamageTarget(source, u, ((GetHeroStr(source, true) * ablev) + GetWidgetLife(u) * (0.25 + 0.05 * ablev)) * LBOOST[pid], ATTACK_TYPE_NORMAL, PHYSICAL, INFERNALSTRIKE.tag)
                end
            end

            DestroyGroup(ug)

            DestroyEffect(AddSpecialEffect("war3mapImported\\Lava_Slam.mdx", GetUnitX(target), GetUnitY(target)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))

            --6 percent max heal
            HP(source, source, BlzGetUnitMaxHP(source) * 0.01 * IMinBJ(6, count), INFERNALSTRIKE.tag)
        end

        function thistype:onRemove()
            EVENT_ON_HIT_MULTIPLIER:unregister_unit_action(self.target, onHit)
        end

        function thistype:onApply()
            EVENT_ON_HIT_MULTIPLIER:register_unit_action(self.target, onHit)
        end
    end

    ---@class PiercingStrikeBuff : Buff
    PiercingStrikeBuff = setmetatable({}, mt)
    do
        local thistype = PiercingStrikeBuff
        thistype.RAWCODE         = FourCC('Apie') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].armor_pen_percent = Unit[self.target].armor_pen_percent - self.pen
        end

        function thistype:onApply()
            self.pen = PIERCINGSTRIKE.pen(self.tpid)
            Unit[self.target].armor_pen_percent = Unit[self.target].armor_pen_percent + self.pen
        end
    end

    ---@class FightMeBuff : Buff
    FightMeBuff = setmetatable({}, mt)
    do
        local thistype = FightMeBuff
        thistype.RAWCODE         = FourCC('Aftm') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        local function onHit(target, source, amount_ref)
            local pid = GetPlayerId(GetOwningPlayer(target)) + 1

            if target == Hero[pid] then
                amount_ref.value = 0.
            end
        end

        function thistype:onRemove()
            EVENT_ON_STRUCK_MULTIPLIER:unregister_unit_action(self.target, onHit)
        end

        function thistype:onApply()
            EVENT_ON_STRUCK_MULTIPLIER:register_unit_action(self.target, onHit)
        end
    end

    ---@class RighteousMightBuff : Buff
    RighteousMightBuff = setmetatable({}, mt)
    do
        local thistype = RighteousMightBuff
        thistype.RAWCODE         = FourCC('Armi') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
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

            Unit[self.target].mr = Unit[self.target].mr * 0.2
        end
    end

    ---@class BloodFrenzyBuff : Buff
    BloodFrenzyBuff = setmetatable({}, mt)
    do
        local thistype = BloodFrenzyBuff
        thistype.RAWCODE         = FourCC('A07E') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat * 1.5
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Bloodlust\\BloodlustTarget.mdl", self.target, "chest")

            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat / 1.5
            DamageTarget(self.source, self.source, 0.15 * BlzGetUnitMaxHP(self.source), ATTACK_TYPE_NORMAL, PURE, BLOODFRENZY.tag)
        end
    end

    ---@class EarthDebuff : Buff
    EarthDebuff = setmetatable({}, mt)
    do
        local thistype = EarthDebuff
        thistype.RAWCODE         = FourCC('Aese') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:refresh()
            self:onRemove()
            self:onApply()
        end

        function thistype:onRemove()
            Unit[self.target].dr = Unit[self.target].dr / self.dr
        end

        function thistype:onApply()
            self.dr = (1. + 0.04 * GetUnitAbilityLevel(self.target, thistype.RAWCODE))
            Unit[self.target].dr = Unit[self.target].dr * self.dr
        end
    end

    ---@class SteedChargeBuff : Buff
    SteedChargeBuff = setmetatable({}, mt)
    do
        local thistype = SteedChargeBuff
        thistype.RAWCODE         = FourCC('Astc') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat - 100
        end

        function thistype:onApply()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat + 100
        end
    end

    ---@class SteedChargeStun : Buff
    SteedChargeStun = setmetatable({}, mt)
    do
        local thistype = SteedChargeStun
        thistype.RAWCODE         = FourCC('AIDK') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Cripple\\CrippleTarget.mdl", self.target, "chest")
            self.ms = 0.5 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
        end
    end

    ---@class FreezingBlastDebuff : Buff
    FreezingBlastDebuff = setmetatable({}, mt)
    do
        local thistype = FreezingBlastDebuff
        thistype.RAWCODE         = FourCC('A01O') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
        end

        function thistype:onApply()
            self.ms = 0.3 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
        end
    end

    ---@class ProtectedBuff : Buff
    ProtectedBuff = setmetatable({}, mt)
    do
        local thistype = ProtectedBuff
        thistype.RAWCODE         = FourCC('A09I') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].mr = Unit[self.target].mr / 0.333
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            Unit[self.target].mr = Unit[self.target].mr * 0.333
            self.sfx = AddSpecialEffectTarget("war3mapImported\\DemonShieldTarget3A.mdx", self.target, "origin")
        end
    end

    ---@class ProtectedExistenceBuff : Buff
    ProtectedExistenceBuff = setmetatable({}, mt)
    do
        local thistype = ProtectedExistenceBuff
        thistype.RAWCODE         = FourCC('Aexi') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].mr = Unit[self.target].mr / 0.666
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            Unit[self.target].mr = Unit[self.target].mr * 0.666
            self.sfx = AddSpecialEffectTarget("war3mapImported\\DemonShieldTarget3A.mdx", self.target, "origin")
        end
    end

    ---@class ProtectionBuff : Buff
    ProtectionBuff = setmetatable({}, mt)
    do
        local thistype = ProtectionBuff
        thistype.RAWCODE         = FourCC('Apro') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.as      = 1.1 ---@type number 

        function thistype:onRemove()
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat * self.as
        end

        function thistype:onApply()
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat / self.as
        end
    end

    ---@class SanctifiedGroundDebuff : Buff
    SanctifiedGroundDebuff = setmetatable({}, mt)
    do
        local thistype = SanctifiedGroundDebuff
        thistype.RAWCODE         = FourCC('Asan') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.regen      = 0. ---@type number 

        function thistype:onRemove()
            Unit[self.target].regen_percent = Unit[self.target].regen_percent + self.regen
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
        end

        function thistype:onApply()
            self.ms = SANCTIFIEDGROUND.ms * 0.01 * (math.min(1, Unit[self.target].ms_percent))
            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
            self.regen = (IsBoss(self.target) and 0.5) or 1
            Unit[self.target].regen_percent = Unit[self.target].regen_percent - self.regen
        end
    end

    ---@class DivineLightBuff : Buff
    DivineLightBuff = setmetatable({}, mt)
    do
        local thistype = DivineLightBuff
        thistype.RAWCODE         = FourCC('Adiv') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_flat = Unit[self.target].ms_flat - self.ms
        end

        function thistype:onApply()
            self.ms = 25 + 25 * GetUnitAbilityLevel(self.source, DIVINELIGHT.id)

            Unit[self.target].ms_flat = Unit[self.target].ms_flat + self.ms
        end
    end

    ---@class ResurgenceBuff : Buff
    ResurgenceBuff = setmetatable({}, mt)
    do
        local thistype = ResurgenceBuff
        thistype.RAWCODE         = FourCC('Ares') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        local function periodic(self)
            local max_hp = Unit[self.target].hp
            local hp = math.min(5, (((max_hp - GetWidgetLife(self.target)) / max_hp) * 100.) // 15.)

            Unit[self.target].regen_max = Unit[self.target].regen_max - self.regen
            self.regen = self.item:getValue(ITEM_ABILITY, 0) * hp
            Unit[self.target].regen_max = Unit[self.target].regen_max + self.regen
            self.timer:callDelayed(0.5, periodic, self)
        end

        function thistype:onRemove()
            Unit[self.target].regen_max = Unit[self.target].regen_max - (self.regen or 0)
            self.timer:destroy()
        end

        function thistype:onApply()
            self.regen = 0
            self.timer = TimerQueue.create()
            self.timer:callDelayed(0., periodic, self)
        end
    end

    ---@class SmokebombBuff : Buff
    SmokebombBuff = setmetatable({}, mt)
    do
        local thistype = SmokebombBuff
        thistype.RAWCODE         = FourCC('Asmk') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
        end

        function thistype:onApply()
            self.ms = (0.28 + 0.02 * GetUnitAbilityLevel(self.source, SMOKEBOMB.id)) * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
        end
    end

    ---@class AzazothHammerStomp : Buff
    AzazothHammerStomp = setmetatable({}, mt)
    do
        local thistype = AzazothHammerStomp
        thistype.RAWCODE         = FourCC('A00C') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.armor         = 0 ---@type integer 

        function thistype.periodic(self)
            local dmg = NERVEGAS.dmg(self.pid) * BOOST[self.pid] / (NERVEGAS.dur * LBOOST[self.pid] * 2.)

            DamageTarget(self.source, self.target, dmg, ATTACK_TYPE_NORMAL, MAGIC, "Nerve Gas")

            self.timer:callDelayed(0.5, thistype.periodic, self)
        end

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .3)
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
            UnitAddBonus(self.target, BONUS_ARMOR, self.armor)
            DestroyEffect(self.sfx)
            self.timer:destroy()
        end

        function thistype:onApply()
            self.ms = 0.3 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
            self.armor = R2I(BlzGetUnitArmor(self.target) * 0.2)
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\AcidBomb\\BottleImpact.mdl", self.target, "chest")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.3)
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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.75)
            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
        end

        function thistype:onApply()
            self.ms = 0.5 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .75)
        end
    end

    ---@class FireElementBuff : Buff
    FireElementBuff = setmetatable({}, mt)
    do
        local thistype = FireElementBuff
        thistype.RAWCODE         = FourCC('Aefr') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            masterElement[self.tpid] = 0
            DestroyEffect(self.sfx)
            DestroyEffect(self.sfx2)
            Unit[self.target].spellboost = Unit[self.target].spellboost - 0.15
        end

        function thistype:onApply()
            masterElement[self.tpid] = ELEMENTFIRE.value
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Fire Uber.mdx", self.target, "right hand")
            self.sfx2 = AddSpecialEffectTarget("war3mapImported\\Fire Uber.mdx", self.target, "left hand")
            Unit[self.target].spellboost = Unit[self.target].spellboost + 0.15
        end
    end

    ---@class IceElementBuff : Buff
    IceElementBuff = setmetatable({}, mt)
    do
        local thistype = IceElementBuff
        thistype.RAWCODE         = FourCC('Aeic') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            masterElement[self.tpid] = 0
            Unit[self.target].mana_regen_max = Unit[self.target].mana_regen_max - 1.5
            DestroyEffect(self.sfx)
            DestroyEffect(self.sfx2)
        end

        function thistype:onApply()
            masterElement[self.tpid] = ELEMENTICE.value
            Unit[self.target].mana_regen_max = Unit[self.target].mana_regen_max + 1.5
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Water High.mdx", self.target, "right hand")
            self.sfx2 = AddSpecialEffectTarget("war3mapImported\\Water High.mdx", self.target, "left hand")
        end
    end

    ---@class LightningElementBuff : Buff
    LightningElementBuff = setmetatable({}, mt)
    do
        local thistype = LightningElementBuff
        thistype.RAWCODE         = FourCC('Alig') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        local function onHit(source, target)
            DamageTarget(source, target, GetWidgetLife(target) * 0.005, ATTACK_TYPE_NORMAL, PURE, ELEMENTLIGHTNING.tag)
        end

        local function periodic(self)
            if UnitAlive(self.target) then
                local ug = CreateGroup()
                local x = GetUnitX(self.target)
                local y = GetUnitY(self.target)

                MakeGroupInRange(self.tpid, ug, x, y, 900., Condition(FilterEnemy))

                local target = FirstOfGroup(ug)
                if target then
                    local dummy = Dummy.create(x, y, FourCC('A09W'), 1, 1.)
                    dummy:attack(target, self.target, onHit)
                end

                DestroyGroup(ug)
            end

            self.timer:callDelayed(5., periodic, self)
        end

        function thistype:onRemove()
            masterElement[self.tpid] = 0
            DestroyEffect(self.sfx)
            DestroyEffect(self.sfx2)
            self.timer:destroy()
            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
        end

        function thistype:onApply()
            masterElement[self.tpid] = ELEMENTLIGHTNING.value
            self.sfx = AddSpecialEffectTarget("war3mapImported\\Storm Cast.mdx", self.target, "right hand")
            self.sfx2 = AddSpecialEffectTarget("war3mapImported\\Storm Cast.mdx", self.target, "left hand")

            self.timer = TimerQueue.create()
            self.timer:callDelayed(5., periodic, self)

            self.ms = 0.4 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
        end
    end

    ---@class EarthElementBuff : Buff
    EarthElementBuff = setmetatable({}, mt)
    do
        local thistype = EarthElementBuff
        thistype.RAWCODE         = FourCC('Aeea') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .25)
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = 0.35 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\FrostDamage\\FrostDamage.mdl", self.target, "chest")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.25)
        end
    end

    ---@class TidalWaveDebuff : Buff
    TidalWaveDebuff = setmetatable({}, mt)
    do
        local thistype = TidalWaveDebuff
        thistype.RAWCODE         = FourCC('Atdw') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
        thistype.percent         = .15 ---@type number 

        function thistype:onRemove()
            Unit[self.target].dr = Unit[self.target].dr / (1 + self.percent)
        end
        function thistype:onApply()
            Unit[self.target].dr = Unit[self.target].dr * (1 + self.percent)
        end

    end

    ---@class SoakedDebuff : Buff
    SoakedDebuff = setmetatable({}, mt)
    do
        local thistype = SoakedDebuff
        thistype.RAWCODE         = FourCC('A01G') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .3)
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = 0.5 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\FrostDamage\\FrostDamage.mdl", self.target, "chest")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.3)
        end
    end

    ---@class SongOfFatigueSlow : Buff
    SongOfFatigueSlow = setmetatable({}, mt)
    do
        local thistype = SongOfFatigueSlow
        thistype.RAWCODE         = FourCC('A00X') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .3)
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = 0.3 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\slow\\slowtarget.mdl", self.target, "origin")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.3)
        end
    end

    ---@class MeatGolemThunderClap : Buff
    MeatGolemThunderClap = setmetatable({}, mt)
    do
        local thistype = MeatGolemThunderClap
        thistype.RAWCODE         = FourCC('A00C') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .3)
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = 0.3 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\StasisTrap\\StasisTotemTarget.mdl", self.target, "overhead")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.3)
        end
    end

    ---@class SaviorThunderClap : Buff
    SaviorThunderClap = setmetatable({}, mt)
    do
        local thistype = SaviorThunderClap
        thistype.RAWCODE         = FourCC('A013') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, .35)
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            self.ms = 0.35 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\StasisTrap\\StasisTotemTarget.mdl", self.target, "overhead")

            UnitAddBonus(self.target, BONUS_ATTACK_SPEED, -.35)
        end
    end

    ---@class BlinkStrikeBuff : Buff
    BlinkStrikeBuff = setmetatable({}, mt)
    do
        local thistype = BlinkStrikeBuff
        thistype.RAWCODE         = FourCC('A03Y') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        local function onStruck(target, source, damage_type)
            if damage_type == PHYSICAL then
                DamageTarget(target, source, BlzGetUnitMaxHP(source) * 0.4, ATTACK_TYPE_NORMAL, MAGIC)
            end
        end

        function thistype:onRemove()
            EVENT_ON_STRUCK:unregister_unit_action(self.target, onStruck)
        end

        function thistype:onApply()
            EVENT_ON_STRUCK:register_unit_action(self.target, onStruck)

            TimerQueue:callDelayed(6.5, DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Undead\\ThornyShield\\ThornyShieldTargetChestLeft.mdl", self.target, "chest"))
            TimerQueue:callDelayed(2.5, DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\ThornsAura\\ThornsAura.mdl", self.target, "origin"))
        end
    end

    ---@class NagaBerserkBuff : Buff
    NagaBerserkBuff = setmetatable({}, mt)
    do
        local thistype = NagaBerserkBuff

        thistype.RAWCODE         = FourCC('A04L') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
        end

        function thistype:onApply()
            self.ms = 0.3 * (math.min(1, Unit[self.target].ms_percent))

            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
        end
    end

    ---@class LightSealBuff : Buff
    ---@field timer TimerQueue
    LightSealBuff = setmetatable({}, mt)
    do
        local thistype = LightSealBuff
        thistype.RAWCODE         = FourCC('Alse') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        ---@param i integer
        function thistype:addStack(i)
            Unit[self.source].bonus_str = Unit[self.source].bonus_str - self.strength
            UnitAddBonus(self.source, BONUS_ARMOR, -self.armor)

            self.stacks = IMinBJ(self.stacks + i, GetUnitAbilityLevel(self.source, LIGHTSEAL.id) * 10)
            self.strength = R2I(GetHeroStr(self.source, true) * 0.01 * self.stacks)
            self.armor = R2I(BlzGetUnitArmor(self.source) * 0.01 * self.stacks)

            Unit[self.source].bonus_str = Unit[self.source].bonus_str + self.strength
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


                Unit[self.source].bonus_str = Unit[self.source].bonus_str - self.strength
                UnitAddBonus(self.source, BONUS_ARMOR, -self.armor)

                self.strength = R2I(GetHeroStr(self.source, true) * 0.01 * self.stacks)
                self.armor = R2I(BlzGetUnitArmor(self.source) * 0.01 * self.stacks)

                Unit[self.source].bonus_str = Unit[self.source].bonus_str + self.strength
                UnitAddBonus(self.source, BONUS_ARMOR, self.armor)
                self.timer:callDelayed(5., LightSealStackExpire, self)
            end
        end

        function thistype:onApply()
            self.timer = TimerQueue.create()
            self.stacks = 0
            self.strength = 0
            self.armor = 0

            self.timer:callDelayed(5., LightSealStackExpire, self)
        end
    end

    ---@class DarkSealDebuff : Buff
    DarkSealDebuff = setmetatable({}, mt)
    do
        local thistype = DarkSealDebuff
        thistype.RAWCODE         = FourCC('A06W') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 
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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        local function periodic(self)
            MakeGroupInRange(self.tpid, self.ug, self.x, self.y, 450. * LBOOST[self.pid], Condition(FilterEnemy))

            --count units in seal
            self.count = 0.
            for target in each(self.ug) do
                self.count = self.count + ((IsUnitType(target, UNIT_TYPE_HERO) and 10) or 1)
                DarkSealDebuff:add(self.source, target):duration(1.)
            end
            self.count = math.min(5. + GetHeroLevel(self.source) // 100 * 10, self.count)

            self:refresh()
            self.timer:callDelayed(0.5, periodic, self)
        end

        --reapplies spellboost and bat bonus
        function thistype:refresh()
            Unit[self.target].spellboost = Unit[self.target].spellboost - self.spellboost
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat * self.bat

            self.spellboost = self.count * 0.01
            self.bat = (1. + self.count * 0.01)
            Unit[self.target].spellboost = Unit[self.target].spellboost + self.spellboost
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat / self.bat
        end

        function thistype:onRemove()
            Unit[self.target].spellboost = Unit[self.target].spellboost - self.spellboost
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat * self.bat

            Dummy[self.sfx]:recycle()

            DestroyGroup(self.ug)
            self.timer:destroy()
        end

        function thistype:onApply()
            self.spellboost = 0
            self.bat = 1
            self.ug = CreateGroup()
            self.count = 0.

            self.sfx = Dummy.create(0, 0, 0, 0, 0).unit

            BlzSetUnitSkin(self.sfx, FourCC('h03X'))
            UnitDisableAbility(self.sfx, FourCC('Amov'), true)
            SetUnitScale(self.sfx, 6.1, 6.1, 6.1)
            BlzSetUnitFacingEx(self.sfx, 270)
            SetUnitAnimation(self.sfx, "birth")
            SetUnitTimeScale(self.sfx, 0.8)
            DelayAnimation(self.tpid, self.sfx, 1., 0, 1., false)

            self.timer = TimerQueue:create()
            self.timer:callDelayed(0.01, periodic, self)
        end
    end

    ---@class MetamorphosisBuff : Buff
    MetamorphosisBuff = setmetatable({}, mt)
    do
        local thistype = MetamorphosisBuff
        thistype.RAWCODE         = FourCC('Amet') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NONE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            Unit[self.target].dm = Unit[self.target].dm / self.dm
            Unit[self.target].base_bat = 2.222
        end

        function thistype:onApply()
            local hp = GetWidgetLife(self.target) * 0.5 ---@type number 

            SetWidgetLife(self.target, hp)
            self.dm = 1 + math.max(0.01, hp / (BlzGetUnitMaxHP(self.target) * 1.))
            Unit[self.target].dm = Unit[self.target].dm * self.dm
            Unit[self.target].base_bat = 0.8
        end
    end

    ---@class KnockUp : Buff
    KnockUp = setmetatable({}, mt)
    do
        local thistype = KnockUp
        thistype.RAWCODE         = FourCC('Akno') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 
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

        local function periodic(self)
            self.time = self.time + FPS_32
            SetUnitFlyHeight(self.target, calcHeight(self.time), 0.)

            if self.time > thistype.DEBUFF_TIME then
                self:remove()
            else
                self.timer:callDelayed(FPS_32, periodic, self)
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
            self.timer:callDelayed(FPS_32, periodic, self)
        end
    end

    ---@class Freeze : Buff
    Freeze = setmetatable({}, mt)
    do
        local thistype = Freeze
        thistype.RAWCODE         = FourCC('A01D') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        function thistype:onRemove()
            BlzPauseUnitEx(self.target, false)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            BlzPauseUnitEx(self.target, true)
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\Thunderclap\\ThunderclapTarget.mdl", self.target, "overhead")
        end
    end

    ---@class InstillFearDebuff : Buff
    InstillFearDebuff = setmetatable({}, mt)
    do
        local thistype = InstillFearDebuff
        thistype.RAWCODE         = FourCC('Aisf') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NEGATIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        local function onStruck(target, source, amount, amount_after_red, damage_type)
            if thistype:has(source, target) then
                amount.value = amount.value * 1.15
            end
        end

        function thistype:onRemove()
            DestroyEffect(self.sfx)

            EVENT_ON_STRUCK_MULTIPLIER:unregister_unit_action(self.target, onStruck)
        end

        function thistype:onApply()
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\shadowstrike\\shadowstrike.mdl", self.target, "overhead")

            EVENT_ON_STRUCK_MULTIPLIER:register_unit_action(self.target, onStruck)
        end
    end

    ---@class DarkestOfDarknessBuff : Buff
    DarkestOfDarknessBuff = setmetatable({}, mt)
    do
        local thistype = DarkestOfDarknessBuff
        thistype.RAWCODE         = FourCC('A056') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

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
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_NONE ---@type integer 

        function thistype:onRemove()
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat * 2.
        end

        function thistype:onApply()
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat / 2.
        end
    end

    ---@class VampiricPotion : Buff
    VampiricPotion = setmetatable({}, mt)
    do
        local thistype = VampiricPotion
        thistype.RAWCODE         = FourCC('A05O') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

        local function onHit(source, target, amount, amount_after_red)
            HP(source, source, amount_after_red * 0.05, "Vampiric Potion")
            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\VampiricAuraTarget.mdx", source, "chest"))
        end

        function thistype:onRemove()
            EVENT_ON_HIT_AFTER_REDUCTIONS:unregister_unit_action(self.target, onHit)
            DestroyEffect(self.sfx)
        end

        function thistype:onApply()
            EVENT_ON_HIT_AFTER_REDUCTIONS:register_unit_action(self.target, onHit)
            self.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Items\\VampiricPotion\\VampPotionCaster.mdl", self.target, "origin")
        end
    end

    ---@class IntenseFocusBuff : Buff
    IntenseFocusBuff = setmetatable({}, mt)
    do
        local thistype = IntenseFocusBuff
        thistype.RAWCODE         = FourCC('Aifc') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_POSITIVE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

       local function periodic(self)
            if UnitAlive(self.target) and
                Unit[self.target].x == GetUnitX(self.target) and
                Unit[self.target].y == GetUnitY(self.target)
            then
                Unit[self.target].dm = Unit[self.target].dm / self.mult
                self.mult = math.min(1.1, self.mult + 0.01)
                Unit[self.target].dm = Unit[self.target].dm * self.mult
                self.timer:callDelayed(1, periodic, self)
            else
                self:remove()
            end
        end

        function thistype:onRemove()
            Unit[self.target].dm = Unit[self.target].dm / self.mult
            self.timer:destroy()
        end

        function thistype:onApply()
            self.mult = 1.
            self.timer = TimerQueue.create()
            self.timer:callDelayed(1, periodic, self)
        end
    end

    ---@class WeatherBuff : Buff
    WeatherBuff = setmetatable({}, mt)
    do
        local thistype = WeatherBuff
        thistype.RAWCODE         = FourCC('Weat') ---@type integer 
        thistype.DISPEL_TYPE     = BUFF_NONE ---@type integer 
        thistype.STACK_TYPE      = BUFF_STACK_PARTIAL ---@type integer 

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

            UnitRemoveAbility(self.target, WeatherTable[self.weather].abil)
            UnitRemoveAbility(self.target, WeatherTable[self.weather].buff)
            UnitAddBonus(self.target, BONUS_DAMAGE, -self.atk)
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat * self.as
            Unit[self.target].spellboost = Unit[self.target].spellboost - self.spellboost
            Unit[self.target].dr = Unit[self.target].dr / self.dr
            Unit[self.target].ms_percent = Unit[self.target].ms_percent + self.ms
        end

        function thistype:onApply()
            self.weather = CURRENT_WEATHER
            self.as = 1. - WeatherTable[self.weather].as * 0.01
            self.atk = (BlzGetUnitBaseDamage(self.target, 0) + UnitGetBonus(self.target, BONUS_DAMAGE)) * WeatherTable[self.weather].atk * 0.01
            self.spellboost = WeatherTable[self.weather].boost * 0.01
            self.dr = (1. - WeatherTable[self.weather].dr * 0.01)

            if GetLocalPlayer() == GetOwningPlayer(self.target) and WeatherTable[self.weather].fog > 0 and self.target == Hero[self.tpid] then
                player_fog[self.tpid] = true
                SetCineFilterTexture("ReplaceableTextures\\CameraMasks\\HazeAndFogFilter_Mask.blp")
                SetCineFilterStartColor(171, 174, WeatherTable[self.weather].blue, 0)
                SetCineFilterEndColor(171, 174, WeatherTable[self.weather].blue, WeatherTable[self.weather].fog)
                SetCineFilterBlendMode(BLEND_MODE_BLEND)
                SetCineFilterDuration(5.)
                DisplayCineFilter(true)
            end

            UnitAddAbility(self.target, WeatherTable[self.weather].abil)
            UnitMakeAbilityPermanent(self.target, true, WeatherTable[self.weather].abil)
            UnitAddAbility(self.target, WeatherTable[self.weather].buff)
            UnitAddBonus(self.target, BONUS_DAMAGE, self.atk)
            Unit[self.target].bonus_bat = Unit[self.target].bonus_bat / self.as
            Unit[self.target].spellboost = Unit[self.target].spellboost + self.spellboost
            Unit[self.target].dr = Unit[self.target].dr * self.dr

            self.ms = WeatherTable[self.weather].ms * 0.01 * (math.min(1, Unit[self.target].ms_percent))
            Unit[self.target].ms_percent = Unit[self.target].ms_percent - self.ms
        end
    end
end, Debug and Debug.getLine())
