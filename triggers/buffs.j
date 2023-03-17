scope Buffs
    struct EarthDebuff extends Buff
        private static constant integer RAWCODE = 'A04P'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_FULL
        integer level = 0

        method onRemove takes nothing returns nothing

        endmethod

        method onApply takes nothing returns nothing
            set level = IMinBJ(level + 1, 10)
            call SetUnitAbilityLevel(this.target, 'Aear', level)
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

                call TimerStart(pt.getTimer(), 0.03, true, function SteedChargePush)
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

    struct Freeze extends Buff
        private static constant integer RAWCODE = 'A01D'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx
            
        method onRemove takes nothing returns nothing
            //stack with stun?
            if Buff.has(null, this.target, Stun.typeid) == false then
                call BlzPauseUnitEx(this.target, false)
            endif
            if GetUnitTypeId(this.source) == HERO_DARK_SAVIOR or GetUnitTypeId(this.source) == HERO_DARK_SAVIOR_DEMON then
                set FreezingBlastDebuff.add(this.source, this.target).duration = 3. * LBOOST(GetPlayerId(GetOwningPlayer(this.source)) + 1)
            endif
            call DestroyEffect(sfx)
        endmethod
            
        method onApply takes nothing returns nothing
            call BlzPauseUnitEx(this.target, true)
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\FreezingBreath\\FreezingBreathTargetArt.mdl", this.target, "chest") 
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

            if IsBoss(GetUnitTypeId(this.target)) == false then
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
        endmethod

        method onApply takes nothing returns nothing
            set ms = GetUnitMoveSpeed(this.target) * .35 
            set sfx = AddSpecialEffectTarget("Abilities\\Spells\\Other\\FrostDamage\\FrostDamage.mdl", this.target, "chest")

            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, -.25)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) - ms)
        endmethod

        implement BuffApply
    endstruct

    struct SoakedSlow extends Buff
        private static constant integer RAWCODE = 'A01G'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private real ms = 0.
        private effect sfx

        method onRemove takes nothing returns nothing
            call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, .3)
            call SetUnitMoveSpeed(this.target, GetUnitMoveSpeed(this.target) + ms)
            call DestroyEffect(sfx)
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

    struct DarkSealDebuff extends Buff
        private static constant integer RAWCODE = 'A06W'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_NONE

        method onRemove takes nothing returns nothing
            local PlayerTimer pt = TimerList[GetPlayerId(GetOwningPlayer(this.source)) + 1].getTimerWithTargetTag(this.source, 'Dksl')

            call GroupRemoveUnit(pt.ug, this.target)
        endmethod

        method onApply takes nothing returns nothing

        endmethod
            
        implement BuffApply
    endstruct

    struct Stun extends Buff
        private static constant integer RAWCODE = 'A08J'
        private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
        private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        private effect sfx
            
        method onRemove takes nothing returns nothing
            if Buff.has(null, this.target, Freeze.typeid) == false then
                call BlzPauseUnitEx(this.target, false)
            endif
            call DestroyEffect(sfx)
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

endscope
