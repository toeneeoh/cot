scope Buffs
    struct SpinDashDebuff extends Buff
        private static constant integer RAWCODE = 'Asda'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx = null
        private real as = 1.25

        method onRemove takes nothing returns nothing
            call DestroyEffect(sfx)
            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) / as, 0)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) * as, 0)

            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\StasisTrap\\StasisTotemTarget.mdl", this.target, "overhead")
        endmethod

        implement BuffApply
    endstruct

    struct LimitBreakBuff extends Buff
        private static constant integer RAWCODE = 'Albr'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx = null

        method onRemove takes nothing returns nothing
            call DestroyEffect(sfx)

            call BlzSetUnitAbilityCooldown(this.target, ADAPTIVESTRIKE.id, 0, 4.)
            call BlzSetUnitAbilityCooldown(this.target, ADAPTIVESTRIKE.id, 1, 4.)
            call BlzSetUnitAbilityCooldown(this.target, ADAPTIVESTRIKE.id, 2, 4.)
            call BlzSetUnitAbilityCooldown(this.target, ADAPTIVESTRIKE.id, 3, 4.)
            call BlzSetUnitAbilityCooldown(this.target, ADAPTIVESTRIKE.id, 4, 4.)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set sfx = AddSpecialEffectTarget("war3mapImported\\Super_Saiyan_Aura_opt.mdx", this.target, "origin")
        endmethod

        implement BuffApply
    endstruct

    struct ParryBuff extends Buff
        private static constant integer RAWCODE = 'Apar'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx = null
        private boolean soundPlayed = false

        method playSound takes nothing returns nothing
            if not soundPlayed then
                set soundPlayed = true

                call SoundHandler("war3mapImported\\parry" + I2S(GetRandomInt(1, 2)) + ".mp3", true, GetOwningPlayer(this.target), this.target)
            endif
        endmethod

        method onRemove takes nothing returns nothing
            call AddUnitAnimationProperties(this.target, "ready", false)
            call DestroyEffect(sfx)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            local integer pid = GetPlayerId(GetOwningPlayer(this.target)) + 1
            call AddUnitAnimationProperties(this.target, "ready", true)

            set sfx = AddSpecialEffectTarget("war3mapImported\\Buff_Shield_Non.mdx", this.target, "chest")

            if limitBreak[pid] == 1 then
                call BlzSetSpecialEffectColor(sfx, 255, 255, 0)
            endif
        endmethod

        implement BuffApply
    endstruct

    struct IntimidatingShoutBuff extends Buff
        private static constant integer RAWCODE = 'Ainb'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx
        private real dmg

        method onRemove takes nothing returns nothing
            call DestroyEffect(sfx)

            call UnitAddBonus(this.target, BONUS_DAMAGE, -dmg)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            local integer stat = GetHeroStat(MainStat(this.target), this.target, true)

            if stat > 0 then
                set dmg = RMaxBJ(0., (stat + UnitGetBonus(this.target, BONUS_DAMAGE)) * 0.4)
            else
                set dmg = RMaxBJ(0., (BlzGetUnitBaseDamage(this.target, 0) + UnitGetBonus(this.target, BONUS_DAMAGE)) * 0.4)
            endif

            set sfx = AddSpecialEffectTarget("war3mapImported\\BattleCryTarget.mdx", this.target, "overhead")

            call UnitAddBonus(this.target, BONUS_DAMAGE, dmg)
        endmethod

        implement BuffApply
    endstruct

    struct IntimidatingShoutDebuff extends Buff
        private static constant integer RAWCODE = 'Aint'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx = null
        private real dmg = 0.
        integer pid = 0

        method onRemove takes nothing returns nothing
            call DestroyEffect(sfx)

            call UnitAddBonus(this.target, BONUS_DAMAGE, dmg)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set pid = GetPlayerId(GetOwningPlayer(this.source)) + 1

            set dmg = RMaxBJ(0., (BlzGetUnitBaseDamage(this.target, 0) + UnitGetBonus(this.target, BONUS_DAMAGE)) * 0.4)

            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\HowlOfTerror\\HowlTarget.mdl", this.target, "overhead")

            call UnitAddBonus(this.target, BONUS_DAMAGE, -dmg)
        endmethod

        implement BuffApply
    endstruct

    struct UndyingRageBuff extends Buff
        private static constant integer RAWCODE = 'Arag'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx
        private real totalRegen = 0.
        private texttag text

        method addRegen takes real dmg returns nothing
            set totalRegen = RMaxBJ(-200., RMinBJ(200., totalRegen + dmg / BlzGetUnitMaxHP(this.source) * 100))
        endmethod

        static method undyingRagePeriodic takes nothing returns nothing
            local integer pid = GetTimerData(GetExpiredTimer())
            local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
            local thistype this = thistype.get(pt.caster, pt.caster, thistype.typeid)

            if UnitAlive(pt.caster) then
                call SetTextTagText(text, I2S(R2I(totalRegen)) + "%", 0.025)
                call SetTextTagColor(text, R2I(Pow(100. - RMinBJ(100., totalRegen), 1.1)), R2I(SquareRoot(RMaxBJ(0, RMinBJ(100., totalRegen)) * 500)), 0, 255)
                call SetTextTagPosUnit(text, source, -200.)

                //percent
                call this.addRegen(TotalRegen[pid] * 0.01)

                call SetWidgetLife(this.source, RMaxBJ(10., BlzGetUnitMaxHP(this.source) * 0.0001))
            else
                call TimerList[pid].removePlayerTimer(pt)
            endif
        endmethod

        method onRemove takes nothing returns nothing
            local integer pid = GetPlayerId(GetOwningPlayer(this.source)) + 1
            local PlayerTimer pt = TimerList[pid].get(this.source, null, thistype.typeid)

            if pt != 0 then
                call TimerList[pid].removePlayerTimer(pt)
            endif

            call DestroyEffect(sfx)
            call DestroyTextTag(text)

            call HP(this.source, BlzGetUnitMaxHP(this.source) * 0.01 * totalRegen)

            set sfx = null
            set text = null
        endmethod

        method onApply takes nothing returns nothing
            local integer pid = GetPlayerId(GetOwningPlayer(this.source)) + 1
            local PlayerTimer pt = TimerList[pid].addTimer(pid)

            set text = CreateTextTag()
            call SetTextTagText(text, I2S(R2I(totalRegen)) + "%", 0.025)
            call SetTextTagColor(text, R2I(Pow(100 - totalRegen, 1.1)), R2I(SquareRoot(RMaxBJ(0, totalRegen) * 500)), 0, 255)

            set pt.caster = this.source
            set pt.tag = thistype.typeid

            set totalRegen = 0.

            set sfx = AddSpecialEffectTarget("war3mapImported\\DemonicAdornment.mdx", this.source, "head")

            call TimerStart(pt.timer, 0.01, true, function thistype.undyingRagePeriodic)
        endmethod

        implement BuffApply
    endstruct

    struct RampageBuff extends Buff
        private static constant integer RAWCODE = 'Aram'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_NONE
        private effect sfx

        static method rampagePeriodic takes nothing returns nothing
            local integer pid = GetTimerData(GetExpiredTimer())
            local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

            call UnitDamageTarget(pt.caster, pt.caster, 0.08 * GetWidgetLife(pt.caster), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_DIVINE, WEAPON_TYPE_WHOKNOWS)
        endmethod

        method onRemove takes nothing returns nothing
            local integer pid = GetPlayerId(GetOwningPlayer(this.source)) + 1
            local PlayerTimer pt = TimerList[pid].get(this.source, null, thistype.typeid)

            call TimerList[pid].removePlayerTimer(pt)
            call DestroyEffect(sfx)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            local integer pid = GetPlayerId(GetOwningPlayer(this.source)) + 1
            local PlayerTimer pt = TimerList[pid].addTimer(pid)

            set pt.caster = this.source
            set pt.tag = thistype.typeid

            set sfx = AddSpecialEffectTarget("war3mapImported\\Windwalk Blood.mdx", this.source, "origin")
            call UnitDamageTarget(this.source, this.source, 0.08 * GetWidgetLife(this.source), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_DIVINE, WEAPON_TYPE_WHOKNOWS)

            call TimerStart(pt.timer, 1., true, function thistype.rampagePeriodic)
        endmethod

        implement BuffApply
    endstruct

    struct FrostArmorDebuff extends Buff
        private static constant integer RAWCODE = 'Afde'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private integer ms

        method onRemove takes nothing returns nothing
            local integer pid = GetPlayerId(GetOwningPlayer(this.target)) + 1

            set BuffMovespeed[pid] = BuffMovespeed[pid] + ms
            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) / 1.25, 0)

        endmethod

        method onApply takes nothing returns nothing
            local integer pid = GetPlayerId(GetOwningPlayer(this.target)) + 1

            set ms = R2I(Movespeed[pid] * 0.25)

            set BuffMovespeed[pid] = BuffMovespeed[pid] - ms
            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) * 1.25, 0)
        endmethod

        implement BuffApply
    endstruct

    struct FrostArmorBuff extends Buff
        private static constant integer RAWCODE = 'Afar'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_NONE
        private effect sfx

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.source, BONUS_ARMOR, -100.)

            call DestroyEffect(sfx)            
            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\FrostArmor\\FrostArmorTarget.mdl", this.source, "chest")

            call UnitAddBonus(this.source, BONUS_ARMOR, 100.)
        endmethod

        implement BuffApply
    endstruct

    struct MagneticStrikeDebuff extends Buff
        private static constant integer RAWCODE = 'Amsd'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL

        method onRemove takes nothing returns nothing
        endmethod

        method onApply takes nothing returns nothing
        endmethod

        implement BuffApply
    endstruct

    struct MagneticStrikeBuff extends Buff
        private static constant integer RAWCODE = 'Amst'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL

        method onRemove takes nothing returns nothing
        endmethod

        method onApply takes nothing returns nothing
        endmethod

        implement BuffApply
    endstruct

    struct InfernalStrikeBuff extends Buff
        private static constant integer RAWCODE = 'Aist'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL

        method onRemove takes nothing returns nothing
        endmethod

        method onApply takes nothing returns nothing
        endmethod

        implement BuffApply
    endstruct

    struct PiercingStrikeDebuff extends Buff
        private static constant integer RAWCODE = 'Apie'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx

        method onRemove takes nothing returns nothing
            call DestroyEffect(sfx)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set sfx = AddSpecialEffectTarget("war3mapImported\\Armor Penetration Orange.mdx", this.target, "overhead") 

            call BlzSetSpecialEffectScale(sfx, 0)
            if GetLocalPlayer() == GetOwningPlayer(this.source) then
                call BlzSetSpecialEffectScale(sfx, 1)
            endif
        endmethod

        implement BuffApply
    endstruct

    struct FightMeBuff extends Buff
        private static constant integer RAWCODE = 'Aftm'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL

        method onRemove takes nothing returns nothing
            set HeroInvul[GetPlayerId(GetOwningPlayer(this.source)) + 1] = false
        endmethod

        method onApply takes nothing returns nothing
            set HeroInvul[GetPlayerId(GetOwningPlayer(this.source)) + 1] = true
        endmethod

        implement BuffApply
    endstruct

    struct RighteousMightBuff extends Buff
        private static constant integer RAWCODE = 'Armi'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        real dmg
        real armor

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_DAMAGE, -dmg)
            call UnitAddBonus(this.target, BONUS_ARMOR, -armor)

            call SetUnitScale(this.target, BlzGetUnitRealField(this.target, UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(this.target, UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(this.target, UNIT_RF_SCALING_VALUE))
        endmethod

        method onApply takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_DAMAGE, dmg)
            call UnitAddBonus(this.target, BONUS_ARMOR, armor)
        endmethod

        implement BuffApply
    endstruct

    struct BloodFrenzyBuff extends Buff
        private static constant integer RAWCODE = 'A07E'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx

        method onRemove takes nothing returns nothing
            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) * 1.50, 0)
            call DestroyEffect(sfx)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Bloodlust\\BloodlustTarget.mdl", this.target, "chest")

            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) / 1.50, 0)
            call UnitDamageTarget(this.source, this.source, 0.15 * BlzGetUnitMaxHP(this.source), true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_DIVINE, WEAPON_TYPE_WHOKNOWS)
        endmethod

        implement BuffApply
    endstruct

    struct EarthDebuff extends Buff
        private static constant integer RAWCODE = 'A04P'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL

        method onRemove takes nothing returns nothing

        endmethod

        method onApply takes nothing returns nothing

        endmethod

        implement BuffApply
    endstruct

    struct SteedChargeStun extends Buff
        private static constant integer RAWCODE = 'AIDK'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real startangle
        private real endangle
        private real enemyangle
        private integer tpid
        private PlayerTimer pt
            
        method onRemove takes nothing returns nothing

        endmethod
            
        method onApply takes nothing returns nothing
            if IsUnitType(this.target, UNIT_TYPE_HERO) == false then
                set tpid = GetPlayerId(GetOwningPlayer(this.target)) + 1
                set pt = TimerList[tpid].addTimer(tpid)
                set pt.target = this.target
                set startangle = GetUnitFacing(this.source) * bj_DEGTORAD
                set enemyangle = Atan2(GetUnitY(this.target) - GetUnitY(this.source), GetUnitX(this.target) - GetUnitX(this.source))
                set endangle = startangle - bj_PI
                if endangle < 0 then
                    set endangle = endangle + 2. * bj_PI
                endif
                set pt.angle = GetUnitFacing(this.source) * bj_DEGTORAD - bj_PI * 0.5
                if endangle > startangle then
                    if enemyangle > startangle and enemyangle < endangle then
                        set pt.angle = GetUnitFacing(this.source) * bj_DEGTORAD + bj_PI * 0.5
                    endif
                else
                    if enemyangle < endangle or enemyangle > startangle then
                        set pt.angle = GetUnitFacing(this.source) * bj_DEGTORAD + bj_PI * 0.5
                    endif
                endif
                set pt.x = GetUnitX(pt.target) + 200. * Cos(pt.angle)
                set pt.y = GetUnitY(pt.target) + 200. * Sin(pt.angle)
                set pt.dur = 33.

                call TimerStart(pt.timer, 0.03, true, function SteedChargePush)
            endif
        endmethod
            
        implement BuffApply
    endstruct

    struct SingleShotDebuff extends Buff
        private static constant integer RAWCODE = 'A950'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms
        private effect sfx
            
        method onRemove takes nothing returns nothing
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
            call DestroyEffect(sfx)

             set sfx = null
        endmethod
            
        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * 0.5
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Cripple\\CrippleTarget.mdl", this.target, "chest")

            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)
        endmethod
            
        implement BuffApply
    endstruct

    struct FreezingBlastDebuff extends Buff
        private static constant integer RAWCODE = 'A01O'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms
            
        method onRemove takes nothing returns nothing
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
        endmethod
            
        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * 0.3

            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)
        endmethod
            
        implement BuffApply
    endstruct

    struct ProtectedBuff extends Buff
        private static constant integer RAWCODE = 'A09I'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL

        method onRemove takes nothing returns nothing

        endmethod

        method onApply takes nothing returns nothing

        endmethod

        implement BuffApply
    endstruct

    struct AstralShieldBuff extends Buff
        private static constant integer RAWCODE = 'Azas'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx

        method onRemove takes nothing returns nothing
            call DestroyEffect(sfx)

             set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set sfx = AddSpecialEffectTarget("war3mapImported\\DemonShieldTarget3A.mdx", this.target, "origin")
        endmethod

        implement BuffApply
    endstruct

    struct ProtectedExistenceBuff extends Buff
        private static constant integer RAWCODE = 'Aexi'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx

        method onRemove takes nothing returns nothing
            call DestroyEffect(sfx)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set sfx = AddSpecialEffectTarget("war3mapImported\\DemonShieldTarget3A.mdx", this.target, "origin")
        endmethod

        implement BuffApply
    endstruct

    struct ProtectionBuff extends Buff
        private static constant integer RAWCODE = 'Apro'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real as = 1.1

        method onRemove takes nothing returns nothing
            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) * as, 0)
        endmethod

        method onApply takes nothing returns nothing
            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) / as, 0)
        endmethod

        implement BuffApply
    endstruct

    struct SanctifiedGroundDebuff extends Buff
        private static constant integer RAWCODE = 'Asan'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real regen = 0.
        private real ms = 0.

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_LIFE_REGEN, regen)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
        endmethod

        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * 0.2

            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)

            if IsBoss(GetUnitTypeId(this.target)) < 0 then
                set regen = UnitGetBonus(this.target, BONUS_LIFE_REGEN)
                call UnitAddBonus(this.target, BONUS_LIFE_REGEN, -regen)
            endif
        endmethod

        implement BuffApply
    endstruct

    struct DivineLightBuff extends Buff
        private static constant integer RAWCODE = 'Adiv'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL

        method onRemove takes nothing returns nothing

        endmethod

        method onApply takes nothing returns nothing
            
        endmethod

        implement BuffApply
    endstruct

    struct SmokebombBuff extends Buff
        private static constant integer RAWCODE = 'Asmk'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL

        method onRemove takes nothing returns nothing

        endmethod

        method onApply takes nothing returns nothing

        endmethod

        implement BuffApply
    endstruct

    struct SmokebombDebuff extends Buff
        private static constant integer RAWCODE = 'A03S'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms = 0.

        method onRemove takes nothing returns nothing
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
        endmethod

        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * (0.28 + 0.02 * GetUnitAbilityLevel(this.source, 'A01E'))

            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)
        endmethod

        implement BuffApply
    endstruct

    struct AzazothHammerStomp extends Buff
        private static constant integer RAWCODE = 'A00C'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, .35)
            call DestroyEffect(sfx)

             set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\StasisTrap\\StasisTotemTarget.mdl", this.target, "overhead")

            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, -.35)
        endmethod

        implement BuffApply
    endstruct

    struct BloodCurdlingScreamDebuff extends Buff
        private static constant integer RAWCODE = 'Ascr'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private integer armor = 0
        private effect sfx

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ARMOR, armor)
            call DestroyEffect(sfx)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set armor = IMaxBJ(0, R2I(BlzGetUnitArmor(this.target) * (0.12 + 0.02 * GetUnitAbilityLevel(this.source, 'A06H')) + 0.5)) 
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\HowlOfTerror\\HowlTarget.mdl", this.target, "chest")

            call UnitAddBonus(this.target, BONUS_ARMOR, -armor)
        endmethod

        implement BuffApply
    endstruct

    struct NerveGasDebuff extends Buff
        private static constant integer RAWCODE = 'Agas'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms = 0.
        private integer armor = 0
        private effect sfx

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, .3)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
            call UnitAddBonus(this.target, BONUS_ARMOR, armor)
            call DestroyEffect(sfx)

             set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * 0.3
            set armor = R2I(BlzGetUnitArmor(this.target) * 0.2)
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\AcidBomb\\BottleImpact.mdl", this.target, "chest")

            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, -.3)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)
            call UnitAddBonus(this.target, BONUS_ARMOR, -armor)
        endmethod

        implement BuffApply
    endstruct

    struct DemonPrinceBloodlust extends Buff
        private static constant integer RAWCODE = 'Ablo'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms = 0.

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, -.75)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)
        endmethod

        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * .5

            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, .75)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
        endmethod

        implement BuffApply
    endstruct

    struct IceElementSlow extends Buff
        private static constant integer RAWCODE = 'Aice'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms = 0.
        private effect sfx

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, .25)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
            call DestroyEffect(sfx)

             set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * .35 
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\FrostDamage\\FrostDamage.mdl", this.target, "chest")

            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, -.25)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)
        endmethod

        implement BuffApply
    endstruct

    struct TidalWaveDebuff extends Buff
        private static constant integer RAWCODE = 'Atwa'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        real percent = .15

        method onRemove takes nothing returns nothing
        endmethod

        method onApply takes nothing returns nothing
        endmethod

        implement BuffApply
    endstruct

    struct SoakedDebuff extends Buff
        private static constant integer RAWCODE = 'A01G'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms = 0.
        private effect sfx

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, .3)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
            call DestroyEffect(sfx)

             set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * .5 
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\FrostDamage\\FrostDamage.mdl", this.target, "chest")

            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, -.3)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)
        endmethod

        implement BuffApply
    endstruct

    struct SongOfFatigueSlow extends Buff
        private static constant integer RAWCODE = 'A00X'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms = 0.
        private effect sfx

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, .3)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
            call DestroyEffect(sfx)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * 0.3
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\slow\\slowtarget.mdl", this.target, "origin")

            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, -.3)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)
        endmethod

        implement BuffApply
    endstruct

    struct MeatGolemThunderClap extends Buff
        private static constant integer RAWCODE = 'A00C'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms = 0.
        private effect sfx

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, .3)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
            call DestroyEffect(sfx)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * 0.3
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\StasisTrap\\StasisTotemTarget.mdl", this.target, "overhead")

            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, -.3)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)
        endmethod

        implement BuffApply
    endstruct

    struct SaviorThunderClap extends Buff
        private static constant integer RAWCODE = 'A013'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms = 0.
        private effect sfx

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, .35)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
            call DestroyEffect(sfx)

            set sfx = null
        endmethod

        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * 0.35
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\StasisTrap\\StasisTotemTarget.mdl", this.target, "overhead")

            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, -.35)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)
        endmethod

        implement BuffApply
    endstruct

    struct BlinkStrike extends Buff
        private static constant integer RAWCODE = 'A03Y'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx

        method onRemove takes nothing returns nothing
            call DestroyEffect(sfx)
            set sfx = null
        endmethod
            
        method onApply takes nothing returns nothing
            set sfx = AddSpecialEffectTarget("war3mapImported\\Windwalk.mdx", this.target, "origin")
        endmethod

        implement BuffApply
    endstruct

    struct NagaThorns extends Buff

        private static constant integer RAWCODE = 'A04S'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_NONE
            
        method onRemove takes nothing returns nothing
            //
        endmethod
            
        method onApply takes nothing returns nothing
            call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\ThornyShield\\ThornyShieldTargetChestLeft.mdl", this.target, "chest"), 6.5)
            call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\ThornsAura\\ThornsAura.mdl", this.target, "origin"), 2.5)
        endmethod
            
        implement BuffApply
    endstruct

    struct NagaEliteAtkSpeed extends Buff

        private static constant integer RAWCODE = 'A04L'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_NONE
            
        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, -8.)
        endmethod
            
        method onApply takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, 8.)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", this.target, "chest"))
        endmethod
            
        implement BuffApply
    endstruct

    struct SpiritCallSlow extends Buff
        private static constant integer RAWCODE = 'A05M'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_NONE
            
        method onRemove takes nothing returns nothing

        endmethod
            
        method onApply takes nothing returns nothing
            
        endmethod
            
        implement BuffApply
    endstruct

    struct LightSealBuff extends Buff
        private static constant integer RAWCODE = 'Alse'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private integer pid
        private PlayerTimer pt
        real strength = 0.
        real armor = 0.
        integer stacks = 0

        method addStack takes integer i returns nothing
            call UnitAddBonus(this.source, BONUS_HERO_STR, -this.strength)
            call UnitAddBonus(this.source, BONUS_ARMOR, -this.armor)

            set this.stacks = IMinBJ(this.stacks + i, GetUnitAbilityLevel(this.source, LIGHTSEAL.id) * 10)
            set this.strength = GetHeroStr(this.source, true) * 0.01 * this.stacks
            set this.armor = BlzGetUnitArmor(this.source) * 0.01 * this.stacks

            call UnitAddBonus(this.source, BONUS_HERO_STR, this.strength)
            call UnitAddBonus(this.source, BONUS_ARMOR, this.armor)
        endmethod

        static method LightSealStackExpire takes nothing returns nothing
            local integer pid = GetTimerData(GetExpiredTimer())
            local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
            local thistype myBuff = thistype.get(pt.caster, pt.caster, thistype.typeid)
            set myBuff.stacks = IMaxBJ(0, myBuff.stacks - 1)

            call UnitAddBonus(myBuff.source, BONUS_HERO_STR, -myBuff.strength)
            call UnitAddBonus(myBuff.source, BONUS_ARMOR, -myBuff.armor)

            if myBuff.stacks <= 0 then
                call TimerList[pid].removePlayerTimer(pt)
                set myBuff.duration = 0.
            else
                set myBuff.duration = 20.
                set myBuff.strength = GetHeroStr(myBuff.source, true) * 0.01 * myBuff.stacks
                set myBuff.armor = BlzGetUnitArmor(myBuff.source) * 0.01 * myBuff.stacks

                call UnitAddBonus(myBuff.source, BONUS_HERO_STR, myBuff.strength)
                call UnitAddBonus(myBuff.source, BONUS_ARMOR, myBuff.armor)
            endif
        endmethod

        method onRemove takes nothing returns nothing

        endmethod

        method onApply takes nothing returns nothing
            set pid = GetPlayerId(GetOwningPlayer(this.source)) + 1
            set pt = TimerList[pid].addTimer(pid)
            set pt.caster = this.source

            call TimerStart(pt.timer, 5., true, function thistype.LightSealStackExpire)
        endmethod
            
        implement BuffApply
    endstruct

    struct DarkSealDebuff extends Buff
        private static constant integer RAWCODE = 'A06W'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_NONE

        method onRemove takes nothing returns nothing
            local PlayerTimer pt = TimerList[GetPlayerId(GetOwningPlayer(this.source)) + 1].get(null, this.source, 'Dksl')

            call GroupRemoveUnit(pt.ug, this.target)
        endmethod

        method onApply takes nothing returns nothing

        endmethod
            
        implement BuffApply
    endstruct

    struct KnockUp extends Buff
        private static constant integer RAWCODE = 'Akno'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private static constant real SPEED = 1500.
        private static constant real DEBUFF_TIME = 1.
        private real time = 0.

        static method calcHeight takes real deltaTime returns real
            local real g = 9.81
            local real h = 0.

            set deltaTime = deltaTime * 1.2

            if deltaTime <= DEBUFF_TIME * 0.5 then
                set h = SPEED * deltaTime - 0.5 * g * deltaTime * deltaTime
            else
                set deltaTime = deltaTime * 1.2
                set h = SPEED * (DEBUFF_TIME - deltaTime) - 0.5 * g * (DEBUFF_TIME - deltaTime) * (DEBUFF_TIME - deltaTime)
            endif

            return RMaxBJ(0, h)
        endmethod

        static method knockUp takes nothing returns nothing
            local thistype this = thistype(GetTimerData(GetExpiredTimer()))
            set time = time + TimerGetElapsed(GetExpiredTimer())

            if time >= DEBUFF_TIME then
                call ReleaseTimer(GetExpiredTimer())
            else
                call SetUnitFlyHeight(this.target, calcHeight(time), 0.)
            endif
        endmethod
            
        method onRemove takes nothing returns nothing
            //stack with stun?
            if Buff.has(null, this.target, Stun.typeid) == false and Buff.has(null, this.target, Freeze.typeid) == false then
                call BlzPauseUnitEx(this.target, false)
            endif
            call SetUnitFlyHeight(this.target, 0., 0.)
        endmethod
            
        method onApply takes nothing returns nothing
            call BlzPauseUnitEx(this.target, true)

            if UnitAddAbility(this.target, 'Amrf') then
                call UnitRemoveAbility(this.target, 'Amrf')
            endif

            call TimerStart(NewTimerEx(this), 0.01, true, function thistype.knockUp)
        endmethod
            
        implement BuffApply
    endstruct

    struct Freeze extends Buff
        private static constant integer RAWCODE = 'A01D'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx
            
        method onRemove takes nothing returns nothing
            //stack with stun?
            if Buff.has(null, this.target, Stun.typeid) == false and Buff.has(null, this.target, KnockUp.typeid) == false then
                call BlzPauseUnitEx(this.target, false)
            endif
            if GetUnitTypeId(this.source) == HERO_DARK_SAVIOR or GetUnitTypeId(this.source) == HERO_DARK_SAVIOR_DEMON then
                set FreezingBlastDebuff.add(this.source, this.target).duration = 3. * LBOOST[GetPlayerId(GetOwningPlayer(this.source)) + 1]
            endif
            call DestroyEffect(sfx)

            set sfx = null
        endmethod
            
        method onApply takes nothing returns nothing
            call BlzPauseUnitEx(this.target, true)
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\FreezingBreath\\FreezingBreathTargetArt.mdl", this.target, "chest") 
        endmethod
            
        implement BuffApply
    endstruct

    struct Stun extends Buff
        private static constant integer RAWCODE = 'A08J'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx
            
        method onRemove takes nothing returns nothing
            if Buff.has(null, this.target, Freeze.typeid) == false and Buff.has(null, this.target, KnockUp.typeid) == false then
                call BlzPauseUnitEx(this.target, false)
            endif
            call DestroyEffect(sfx)
            set sfx = null
        endmethod
            
        method onApply takes nothing returns nothing
            call BlzPauseUnitEx(this.target, true)
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Human\\Thunderclap\\ThunderclapTarget.mdl", this.target, "overhead") 
        endmethod
            
        implement BuffApply
    endstruct

    struct DarkestOfDarkness extends Buff
        private static constant integer RAWCODE = 'A056'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_NONE
            
        method onRemove takes nothing returns nothing
            
        endmethod
            
        method onApply takes nothing returns nothing
            call DestroyEffectTimed(AddSpecialEffectTarget("war3mapImported\\SoulArmor.mdx", this.target, "chest"), 6.)
        endmethod
            
        implement BuffApply
    endstruct

    struct HolyBlessing extends Buff
        private static constant integer RAWCODE = 'A08K'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_NONE
            
        method onRemove takes nothing returns nothing
            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) * 2, 0)
        endmethod
            
        method onApply takes nothing returns nothing
            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) / 2, 0)
        endmethod
            
        implement BuffApply
    endstruct

    struct VampiricPotion extends Buff
        private static constant integer RAWCODE = 'A05O'
        private static constant integer DISPEL_TYPE = BUFF_POSITIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_NONE
            
        method onRemove takes nothing returns nothing
            
        endmethod
            
        method onApply takes nothing returns nothing
            call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Items\\VampiricPotion\\VampPotionCaster.mdl", this.target, "origin"), 9)
        endmethod
            
        implement BuffApply
    endstruct

    struct WeatherBuff extends Buff
        private static constant integer RAWCODE = 0
        private static constant integer DISPEL_TYPE = BUFF_NONE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms = 0.
        private real as = 0.
        public integer weather = 0
            
        method onRemove takes nothing returns nothing
            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) * as, 0)
        endmethod
            
        method onApply takes nothing returns nothing
            set as = weatherAS[currentWeather]
            set weather = currentWeather

            call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) / as, 0)
        endmethod
            
        implement BuffApply
    endstruct
endscope
